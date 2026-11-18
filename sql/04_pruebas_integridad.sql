SET SERVEROUTPUT ON
SET FEEDBACK ON
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
-- Conexion nueva como FUEL_APP. Se revierten los datos de prueba.
-- Las identidades consumidas no se revierten; los saltos son normales.
DECLARE
  n NUMBER; v_id NUMBER; saldo NUMBER; diferencia NUMBER; pruebas NUMBER := 0;
  PROCEDURE comprobar(ok BOOLEAN, mensaje VARCHAR2) IS
  BEGIN
    IF ok IS NULL OR NOT ok THEN RAISE_APPLICATION_ERROR(-20900,mensaje); END IF;
    pruebas:=pruebas+1; DBMS_OUTPUT.PUT_LINE('CORRECTO: '||mensaje);
  END;
  PROCEDURE rechazar(sentencia VARCHAR2, codigo NUMBER, restriccion VARCHAR2 DEFAULT NULL) IS
  BEGIN
    EXECUTE IMMEDIATE sentencia;
    RAISE_APPLICATION_ERROR(-20901,'Se acepto una operacion invalida: '||sentencia);
  EXCEPTION WHEN OTHERS THEN
    IF SQLCODE<>codigo OR (restriccion IS NOT NULL AND INSTR(UPPER(SQLERRM),UPPER(restriccion))=0) THEN RAISE; END IF;
    pruebas:=pruebas+1; DBMS_OUTPUT.PUT_LINE('CORRECTO: rechazo '||NVL(restriccion,TO_CHAR(codigo)));
  END;
BEGIN
  SAVEPOINT pruebas_inicio;
  comprobar(USER='FUEL_APP' AND SYS_CONTEXT('USERENV','CON_NAME')='FREEPDB1','Usuario y PDB');
  SELECT COUNT(*) INTO n FROM user_tables;
  comprobar(n=38,'38 tablas');
  SELECT COUNT(*) INTO n FROM user_objects WHERE status='INVALID';
  comprobar(n=0,'Sin objetos invalidos');
  SELECT COUNT(*) INTO n FROM user_constraints WHERE status<>'ENABLED' OR validated<>'VALIDATED';
  comprobar(n=0,'Restricciones habilitadas y validadas');
  SELECT COUNT(*) INTO n FROM transaccion;
  comprobar(n=2,'Dos transacciones iniciales');
  SELECT SUM(cantidad) INTO saldo FROM detalle_transaccion;
  comprobar(saldo=85,'85 litros en las dos operaciones de ejemplo');
  SELECT saldo_teorico INTO saldo FROM v_balance_tanque WHERE id_tanque=1;
  comprobar(saldo=1468,'Balance 1000 + 500 - 30 - 2 = 1468');
  SELECT c.diferencia INTO diferencia FROM v_conciliacion_tanque c WHERE id_tanque=1;
  comprobar(diferencia=0,'Medicion fisica coincide a la fecha de corte');

  rechazar(q'~INSERT INTO vehiculo(id_vehiculo,id_ficha,id_tipo_uso,placa,nro_chasis,nro_motor,estado) VALUES(900001,1,1,'1234ABC','CHASIS-TEST','MOTOR-TEST','ACTIVO')~',-1,'UK_VEHICULO_PLACA');
  rechazar(q'~INSERT INTO vehiculo_combustible(id_vehiculo,id_combustible,capacidad_lt,origen_instalacion) VALUES(900001,1,40,'FABRICA')~',-2291,'FK_VC_VEHICULO');
  rechazar(q'~UPDATE detalle_transaccion SET cantidad=-5,monto_bs=-18.70 WHERE id_detalle=1~',-2290);
  rechazar(q'~UPDATE detalle_transaccion SET cantidad=0,monto_bs=0 WHERE id_detalle=1~',-2290);
  rechazar(q'~UPDATE detalle_transaccion SET id_transaccion=NULL WHERE id_detalle=1~',-1407);
  rechazar(q'~UPDATE detalle_transaccion SET precio_unitario_bs=4,monto_bs=120 WHERE id_detalle=1~',-2291,'FK_DET_CONTEXTO');
  rechazar(q'~UPDATE detalle_transaccion SET id_tipo_tarifa=2 WHERE id_detalle=1~',-2291,'FK_DET_CONTEXTO');
  rechazar(q'~UPDATE detalle_transaccion SET id_combustible=2 WHERE id_detalle=1~',-2291);
  rechazar(q'~UPDATE detalle_transaccion SET monto_bs=1 WHERE id_detalle=1~',-2290,'CK_DET_MONTO');
  rechazar(q'~UPDATE precio_combustible SET precio_bs=0 WHERE id_precio=1~',-2290,'CK_PRECIO_BS');
  rechazar(q'~UPDATE vehiculo_combustible SET capacidad_lt=0 WHERE id_vehiculo=1~',-2290,'CK_VC_CAPACIDAD');
  rechazar(q'~UPDATE estacion_servicio SET codigo_anh='ANH-FICT-001' WHERE id_estacion=2~',-1,'UK_ESTACION_ANH');
  rechazar(q'~UPDATE recepcion_combustible SET cantidad=-1 WHERE id_recepcion=1~',-2290,'CK_RECEP_CANTIDAD');
  rechazar(q'~UPDATE recepcion_combustible SET id_tanque=2 WHERE id_recepcion=1~',-2291,'FK_RECEP_TANQUE');
  rechazar(q'~UPDATE ajuste_inventario SET cantidad=0 WHERE id_ajuste=1~',-2290,'CK_AJ_CANTIDAD');
  rechazar(q'~UPDATE medicion_tanque SET cantidad=-1 WHERE id_medicion=1~',-2290,'CK_MED_CANTIDAD');
  rechazar(q'~UPDATE medicion_tanque SET cantidad=10001 WHERE id_medicion=1~',-20013);
  rechazar(q'~UPDATE transaccion SET tipo_transaccion='OTRA' WHERE id_transaccion=1~',-2290);
  rechazar(q'~UPDATE carga_vehicular SET tipo_transaccion='COMPRA_BIDON' WHERE id_transaccion=1~',-2290,'CK_CV_TIPO');
  rechazar(q'~UPDATE transaccion SET fecha_hora=TIMESTAMP '2025-01-01 00:00:00' WHERE id_transaccion=1~',-20012);
  rechazar(q'~UPDATE precio_combustible SET vigente_desde=DATE '2026-12-01' WHERE id_precio=1~',-20011);
  rechazar(q'~UPDATE surtidor SET id_tanque=3,id_estacion=2 WHERE id_surtidor=1~',-20014);
  rechazar(q'~UPDATE tanque SET stock_inicial=2000 WHERE id_tanque=1~',-20016);

  UPDATE carga_vehicular SET id_beneficio=NULL WHERE id_transaccion=1;
  comprobar(SQL%ROWCOUNT=1,'Carga sin beneficio permitida');
  INSERT INTO marca(nombre) VALUES('MARCA-IDENTIDAD-TEST') RETURNING id_marca INTO v_id;
  comprobar(v_id>=1000000,'ID automatico sin introducir identificador');

  SAVEPOINT subtipo;
  DELETE FROM carga_vehicular WHERE id_transaccion=1;
  rechazar('SET CONSTRAINTS ALL IMMEDIATE',-2291,'FK_TX_CARGA');
  ROLLBACK TO subtipo;
  EXECUTE IMMEDIATE 'SET CONSTRAINTS ALL DEFERRED';

  INSERT INTO permiso_bidon(id_permiso,id_persona,id_combustible,id_entidad,id_tipo_periodo,motivo,cantidad_maxima,fecha_inicio,estado)
  VALUES(900001,1,1,1,1,'PRUEBA',40,DATE '2026-01-01','ACTIVO');
  rechazar(q'~INSERT INTO compra_bidon(id_transaccion,id_permiso,nro_bidones,capacidad_bidon_lt) VALUES(1,900001,1,20)~',-2291,'FK_CB_TIPO');
  INSERT INTO transaccion(id_transaccion,id_surtidor,id_persona,id_usuario,tipo_transaccion,fecha_hora,estado)
  VALUES(900001,1,1,1,'COMPRA_BIDON',TIMESTAMP '2026-11-10 12:00:00','APROBADA');
  rechazar(q'~INSERT INTO compra_bidon(id_transaccion,id_permiso,nro_bidones,capacidad_bidon_lt) VALUES(900001,900001,0,20)~',-2290,'CK_CB_NUM');
  INSERT INTO compra_bidon(id_transaccion,id_permiso,nro_bidones,capacidad_bidon_lt) VALUES(900001,900001,2,20);
  EXECUTE IMMEDIATE 'SET CONSTRAINTS ALL IMMEDIATE';
  comprobar(TRUE,'Compra de bidon con subtipo correcto');
  EXECUTE IMMEDIATE 'SET CONSTRAINTS ALL DEFERRED';

  SAVEPOINT sin_subtipo;
  INSERT INTO transaccion(id_transaccion,id_surtidor,id_persona,id_usuario,tipo_transaccion,fecha_hora,estado)
  VALUES(900002,1,1,1,'CARGA_VEHICULAR',TIMESTAMP '2026-11-10 12:00:00','APROBADA');
  rechazar('SET CONSTRAINTS ALL IMMEDIATE',-2291,'FK_TX_CARGA');
  ROLLBACK TO sin_subtipo;
  EXECUTE IMMEDIATE 'SET CONSTRAINTS ALL DEFERRED';

  -- Precio coherente con diesel pero incompatible con el surtidor de gasolina.
  INSERT INTO precio_combustible(id_precio,id_combustible,id_tipo_tarifa,precio_bs,vigente_desde)
  VALUES(900001,2,1,3.74,DATE '2026-01-01');
  rechazar('UPDATE detalle_transaccion SET id_combustible=2,id_precio=900001 WHERE id_detalle=1',-2291,'FK_DET_TX_COMB');
  INSERT INTO precio_combustible(id_precio,id_combustible,id_tipo_tarifa,precio_bs,vigente_desde)
  VALUES(900002,1,1,3.74,DATE '2026-12-01');
  rechazar('UPDATE detalle_transaccion SET id_precio=900002 WHERE id_detalle=1',-20010);

  -- Una lectura antigua no se compara con recepciones posteriores.
  INSERT INTO recepcion_combustible(id_tanque,id_estacion,id_entidad,id_combustible,id_tipo_tarifa,cantidad,fecha_hora)
  VALUES(1,1,2,1,1,100,TIMESTAMP '2026-11-11 08:00:00');
  SELECT c.diferencia INTO diferencia FROM v_conciliacion_tanque c WHERE id_tanque=1;
  comprobar(diferencia=0,'Conciliacion conserva la misma fecha de corte');

  ROLLBACK TO pruebas_inicio;
  EXECUTE IMMEDIATE 'SET CONSTRAINTS ALL IMMEDIATE';
  EXECUTE IMMEDIATE 'SET CONSTRAINTS ALL DEFERRED';
  SELECT COUNT(*) INTO n FROM transaccion;
  comprobar(n=2,'Sin transacciones temporales');
  SELECT saldo_teorico INTO saldo FROM v_balance_tanque WHERE id_tanque=1;
  comprobar(saldo=1468,'Sin movimientos temporales');
  DBMS_OUTPUT.PUT_LINE('TOTAL: '||pruebas||' comprobaciones correctas.');
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  RAISE;
END;
/
