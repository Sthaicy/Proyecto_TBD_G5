SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON
SET LINESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

-- Ejecutar en una conexion nueva, despues de 01_schema.sql y 02_datos_ficticios.sql.
-- No cambia el modelo ni confirma datos. Los registros de prueba se revierten.
DECLARE
    v_total NUMBER;
    v_litros NUMBER;
    v_monto NUMBER;
    v_id_vehiculo NUMBER;
    v_id_inexistente NUMBER;
    v_id_detalle NUMBER;

    PROCEDURE comprobar(p_condicion BOOLEAN, p_mensaje VARCHAR2) IS
    BEGIN
        IF p_condicion IS NULL OR NOT p_condicion THEN
            RAISE_APPLICATION_ERROR(-20001, p_mensaje);
        END IF;
    END;
BEGIN
    SAVEPOINT inicio_pruebas;
    comprobar(USER = 'FUEL_APP'
        AND SYS_CONTEXT('USERENV', 'CON_NAME') = 'FREEPDB1',
        'Conectate como FUEL_APP a FREEPDB1.');

    SELECT COUNT(*) INTO v_total FROM user_tables;
    comprobar(v_total = 35, 'Se esperaban las 35 tablas del proyecto.');
    SELECT COUNT(*) INTO v_total FROM user_objects WHERE status = 'INVALID';
    comprobar(v_total = 0, 'Existen objetos invalidos.');
    SELECT COUNT(*) INTO v_total FROM user_constraints WHERE status <> 'ENABLED';
    comprobar(v_total = 0, 'Existen restricciones deshabilitadas.');

    SELECT COUNT(*) INTO v_total FROM vehiculo
    WHERE id_vehiculo = 1 AND placa = '1234ABC';
    comprobar(v_total = 1, 'Falta el vehiculo ficticio de 02_datos_ficticios.sql.');
    SELECT COUNT(DISTINCT id_transaccion), SUM(cantidad), SUM(monto_bs)
      INTO v_total, v_litros, v_monto
      FROM detalle_transaccion WHERE id_transaccion IN (1, 2);
    comprobar(v_total = 2 AND v_litros = 85 AND v_monto = 317.90,
        'Las dos cargas ficticias deben sumar 85 litros y Bs 317.90.');
    SELECT COUNT(*) INTO v_total FROM alerta
    WHERE id_alerta = 1 AND id_transaccion = 2 AND estado = 'PENDIENTE';
    comprobar(v_total = 1, 'Falta la alerta ficticia pendiente.');
    DBMS_OUTPUT.PUT_LINE('CORRECTO: esquema y datos ficticios verificados.');

    SELECT MIN(id_vehiculo) - 1, MAX(id_vehiculo) + 1
      INTO v_id_vehiculo, v_id_inexistente FROM vehiculo;
    SELECT MIN(id_detalle) - 1 INTO v_id_detalle FROM detalle_transaccion;

    -- PRUEBA 1: debe fallar especificamente la restriccion de placa.
    BEGIN
        INSERT INTO vehiculo (
            id_vehiculo, id_ficha, id_tipo_uso, placa, nro_chasis, nro_motor,
            color, anio, tag_rfid, estado
        ) VALUES (
            v_id_vehiculo, 1, 1, '1234ABC',
            SUBSTR(RAWTOHEX(SYS_GUID()), 1, 30),
            SUBSTR(RAWTOHEX(SYS_GUID()), 1, 30),
            'NEGRO', 2022, RAWTOHEX(SYS_GUID()), 'ACTIVO'
        );
        RAISE_APPLICATION_ERROR(-20002, 'Oracle permitio una placa duplicada.');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            IF INSTR(UPPER(SQLERRM), 'UK_VEHICULO_PLACA') = 0 THEN
                RAISE;
            END IF;
            DBMS_OUTPUT.PUT_LINE('CORRECTO: placa duplicada rechazada.');
    END;

    -- PRUEBA 2: debe fallar la FK del vehiculo, no otra restriccion.
    BEGIN
        INSERT INTO vehiculo_combustible (
            id_vehiculo, id_combustible, capacidad_lt, origen
        ) VALUES (v_id_inexistente, 1, 40, 'FABRICA');
        RAISE_APPLICATION_ERROR(-20003, 'Oracle permitio un vehiculo inexistente.');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -2291 OR INSTR(UPPER(SQLERRM), 'FK_VC_VEHICULO') = 0 THEN
                RAISE;
            END IF;
            DBMS_OUTPUT.PUT_LINE('CORRECTO: vehiculo inexistente rechazado.');
    END;

    -- PRUEBA 3: documenta una limitacion del esquema actual, no una proteccion.
    -- Si el equipo incorpora el CHECK, esta prueba debera esperar su rechazo.
    INSERT INTO detalle_transaccion (
        id_detalle, id_transaccion, id_combustible, id_tipo_tarifa, id_precio,
        id_tipo_cambio, id_regla, cantidad, precio_unitario_bs, monto_bs
    ) SELECT
        v_id_detalle, id_transaccion, id_combustible, id_tipo_tarifa, id_precio,
        id_tipo_cambio, id_regla, -5, precio_unitario_bs,
        ROUND(-5 * precio_unitario_bs, 2)
      FROM detalle_transaccion WHERE id_detalle = 1;
    comprobar(SQL%ROWCOUNT = 1, 'No se pudo preparar la prueba de cantidad negativa.');
    DBMS_OUTPUT.PUT_LINE('LIMITACION CONFIRMADA: el esquema permite cantidades negativas.');

    ROLLBACK TO inicio_pruebas;
    SELECT COUNT(*) INTO v_total FROM detalle_transaccion WHERE id_detalle = v_id_detalle;
    comprobar(v_total = 0, 'Quedo un detalle temporal despues del rollback.');
    SELECT COUNT(*) INTO v_total FROM vehiculo WHERE id_vehiculo = v_id_vehiculo;
    comprobar(v_total = 0, 'Quedo un vehiculo temporal despues del rollback.');
    SELECT COUNT(*) INTO v_total FROM vehiculo_combustible
    WHERE id_vehiculo = v_id_inexistente;
    comprobar(v_total = 0, 'Quedo una relacion temporal despues del rollback.');
    DBMS_OUTPUT.PUT_LINE('CORRECTO: pruebas terminadas sin conservar registros temporales.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO inicio_pruebas;
        RAISE;
END;
/
