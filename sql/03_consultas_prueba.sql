SET ECHO ON
SET FEEDBACK ON
SET LINESIZE 240
SET PAGESIZE 100
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

-- CONSULTA 1: HISTORIAL Y PROPIETARIO EN LA FECHA DE LA CARGA
-- La persona que realiza la transaccion puede ser distinta del propietario.
SELECT
    v.placa,
    p.nombres || ' ' || p.apellidos AS propietario,
    t.fecha_hora,
    c.nombre AS combustible,
    d.cantidad,
    um.simbolo AS unidad,
    d.monto_bs,
    t.estado
FROM carga_vehicular cv
JOIN vehiculo v ON v.id_vehiculo = cv.id_vehiculo
JOIN transaccion t ON t.id_transaccion = cv.id_transaccion
JOIN detalle_transaccion d ON d.id_transaccion = t.id_transaccion
JOIN combustible c ON c.id_combustible = d.id_combustible
JOIN unidad_medida um ON um.id_unidad = c.id_unidad
LEFT JOIN registro_ruat rr
    ON rr.id_vehiculo = v.id_vehiculo
   AND t.fecha_hora >= CAST(rr.fecha_inicio AS TIMESTAMP)
   AND (rr.fecha_fin IS NULL OR t.fecha_hora < CAST(rr.fecha_fin AS TIMESTAMP))
LEFT JOIN persona p ON p.id_persona = rr.id_persona
ORDER BY t.fecha_hora, t.id_transaccion, d.id_detalle;

-- CONSULTA 2: TOTALES POR VEHICULO, COMBUSTIBLE Y ESTADO
-- Se separan los estados para no presentar toda operacion como venta aprobada.
SELECT
    v.placa,
    c.nombre AS combustible,
    um.simbolo AS unidad,
    t.estado,
    COUNT(DISTINCT t.id_transaccion) AS cantidad_cargas,
    SUM(d.cantidad) AS cantidad_total,
    SUM(d.monto_bs) AS monto_total_bs
FROM vehiculo v
JOIN carga_vehicular cv ON cv.id_vehiculo = v.id_vehiculo
JOIN transaccion t ON t.id_transaccion = cv.id_transaccion
JOIN detalle_transaccion d ON d.id_transaccion = t.id_transaccion
JOIN combustible c ON c.id_combustible = d.id_combustible
JOIN unidad_medida um ON um.id_unidad = c.id_unidad
GROUP BY v.id_vehiculo, v.placa, c.id_combustible, c.nombre, um.simbolo, t.estado
ORDER BY v.placa, c.nombre, t.estado;

-- CONSULTA 3: OPERACIONES POR ESTACION, COMBUSTIBLE Y ESTADO
-- El identificador evita mezclar estaciones que tengan el mismo nombre.
SELECT
    e.id_estacion,
    e.nombre AS estacion,
    c.nombre AS combustible,
    um.simbolo AS unidad,
    t.estado,
    COUNT(DISTINCT t.id_transaccion) AS transacciones,
    SUM(d.cantidad) AS cantidad_total,
    SUM(d.monto_bs) AS monto_total_bs
FROM estacion_servicio e
JOIN surtidor s ON s.id_estacion = e.id_estacion
JOIN transaccion t ON t.id_surtidor = s.id_surtidor
JOIN detalle_transaccion d ON d.id_transaccion = t.id_transaccion
JOIN combustible c ON c.id_combustible = d.id_combustible
JOIN unidad_medida um ON um.id_unidad = c.id_unidad
GROUP BY e.id_estacion, e.nombre, c.id_combustible, c.nombre, um.simbolo, t.estado
ORDER BY e.id_estacion, c.nombre, t.estado;

-- CONSULTA 4: CARGAS MAYORES A LA CAPACIDAD DECLARADA EN LITROS
-- Se suman todos los detalles del mismo combustible en la transaccion.
-- GNV en m3 requiere una regla de conversion que aun no esta definida.
SELECT
    v.placa,
    t.id_transaccion,
    t.fecha_hora,
    c.nombre AS combustible,
    SUM(d.cantidad) AS cantidad_cargada,
    vc.capacidad_lt AS capacidad_declarada,
    SUM(d.cantidad) - vc.capacidad_lt AS exceso_litros
FROM carga_vehicular cv
JOIN vehiculo v ON v.id_vehiculo = cv.id_vehiculo
JOIN transaccion t ON t.id_transaccion = cv.id_transaccion
JOIN detalle_transaccion d ON d.id_transaccion = t.id_transaccion
JOIN vehiculo_combustible vc
    ON vc.id_vehiculo = v.id_vehiculo
   AND vc.id_combustible = d.id_combustible
JOIN combustible c ON c.id_combustible = d.id_combustible
JOIN unidad_medida um ON um.id_unidad = c.id_unidad
WHERE um.simbolo = 'L'
GROUP BY v.id_vehiculo, v.placa, t.id_transaccion, t.fecha_hora,
         c.id_combustible, c.nombre, vc.capacidad_lt
HAVING SUM(d.cantidad) > vc.capacidad_lt
ORDER BY t.fecha_hora, t.id_transaccion;

-- CONSULTA 5: ALERTAS PENDIENTES
SELECT
    a.id_alerta,
    v.placa,
    tr.codigo AS tipo_regla,
    a.fecha,
    a.nivel,
    a.estado,
    a.detalle
FROM alerta a
JOIN regla r ON r.id_regla = a.id_regla
JOIN tipo_regla tr ON tr.id_tipo_regla = r.id_tipo_regla
LEFT JOIN vehiculo v ON v.id_vehiculo = a.id_vehiculo
WHERE a.estado = 'PENDIENTE'
ORDER BY a.fecha;

-- CONSULTA 6: PROPIETARIO Y BENEFICIO HABILITADO A LA FECHA ACTUAL
-- Las vigencias se interpretan como [fecha_inicio, fecha_fin).
SELECT
    p.ci,
    p.nombres || ' ' || p.apellidos AS propietario,
    v.placa,
    rb.estado AS estado_beneficio,
    rb.fecha_inicio,
    rb.fecha_fin
FROM persona p
JOIN registro_ruat rr ON rr.id_persona = p.id_persona
JOIN vehiculo v ON v.id_vehiculo = rr.id_vehiculo
JOIN registro_beneficio rb ON rb.id_registro_ruat = rr.id_registro_ruat
WHERE rr.fecha_inicio <= SYSDATE
  AND (rr.fecha_fin IS NULL OR rr.fecha_fin > SYSDATE)
  AND rb.fecha_inicio <= SYSDATE
  AND (rb.fecha_fin IS NULL OR rb.fecha_fin > SYSDATE)
  AND rb.estado = 'HABILITADO';

-- INVENTARIO: no mezcla litros con m3; solo descuenta ventas APROBADAS.
SELECT * FROM v_balance_tanque ORDER BY id_tanque;
SELECT * FROM v_conciliacion_tanque ORDER BY id_tanque;
