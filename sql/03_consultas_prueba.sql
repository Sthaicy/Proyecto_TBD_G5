SET ECHO ON
SET FEEDBACK ON
SET LINESIZE 200
SET PAGESIZE 100

-- =========================================================
-- CONSULTA 1: HISTORIAL DE CARGAS POR VEHICULO
-- =========================================================

SELECT
    v.placa,
    p.nombres || ' ' || p.apellidos AS propietario,
    t.fecha_hora,
    d.cantidad AS litros,
    d.monto_bs,
    t.estado
FROM persona p
JOIN registro_ruat rr
    ON rr.id_persona = p.id_persona
JOIN vehiculo v
    ON v.id_vehiculo = rr.id_vehiculo
JOIN carga_vehicular cv
    ON cv.id_vehiculo = v.id_vehiculo
JOIN transaccion t
    ON t.id_transaccion = cv.id_transaccion
JOIN detalle_transaccion d
    ON d.id_transaccion = t.id_transaccion
ORDER BY t.fecha_hora;


-- =========================================================
-- CONSULTA 2: TOTAL CARGADO POR VEHICULO
-- =========================================================

SELECT
    v.placa,
    COUNT(DISTINCT t.id_transaccion) AS cantidad_cargas,
    SUM(d.cantidad) AS total_litros,
    SUM(d.monto_bs) AS total_pagado_bs
FROM vehiculo v
JOIN carga_vehicular cv
    ON cv.id_vehiculo = v.id_vehiculo
JOIN transaccion t
    ON t.id_transaccion = cv.id_transaccion
JOIN detalle_transaccion d
    ON d.id_transaccion = t.id_transaccion
GROUP BY v.placa;


-- =========================================================
-- CONSULTA 3: VENTAS POR ESTACION
-- =========================================================

SELECT
    e.nombre AS estacion,
    COUNT(DISTINCT t.id_transaccion) AS transacciones,
    SUM(d.cantidad) AS total_combustible,
    SUM(d.monto_bs) AS total_recaudado_bs
FROM estacion_servicio e
JOIN surtidor s
    ON s.id_estacion = e.id_estacion
JOIN transaccion t
    ON t.id_surtidor = s.id_surtidor
JOIN detalle_transaccion d
    ON d.id_transaccion = t.id_transaccion
GROUP BY e.nombre
ORDER BY total_combustible DESC;


-- =========================================================
-- CONSULTA 4: CARGAS MAYORES A LA CAPACIDAD DECLARADA
-- =========================================================

SELECT
    v.placa,
    t.id_transaccion,
    t.fecha_hora,
    d.cantidad AS cantidad_cargada,
    vc.capacidad_lt AS capacidad_declarada,
    d.cantidad - vc.capacidad_lt AS exceso_litros
FROM vehiculo v
JOIN vehiculo_combustible vc
    ON vc.id_vehiculo = v.id_vehiculo
JOIN carga_vehicular cv
    ON cv.id_vehiculo = v.id_vehiculo
JOIN transaccion t
    ON t.id_transaccion = cv.id_transaccion
JOIN detalle_transaccion d
    ON d.id_transaccion = t.id_transaccion
   AND d.id_combustible = vc.id_combustible
WHERE d.cantidad > vc.capacidad_lt
ORDER BY t.fecha_hora;


-- =========================================================
-- CONSULTA 5: ALERTAS PENDIENTES
-- =========================================================

SELECT
    a.id_alerta,
    v.placa,
    tr.codigo AS tipo_regla,
    a.fecha,
    a.nivel,
    a.estado,
    a.detalle
FROM alerta a
JOIN regla r
    ON r.id_regla = a.id_regla
JOIN tipo_regla tr
    ON tr.id_tipo_regla = r.id_tipo_regla
LEFT JOIN vehiculo v
    ON v.id_vehiculo = a.id_vehiculo
WHERE a.estado = 'PENDIENTE'
ORDER BY a.fecha;


-- =========================================================
-- CONSULTA 6: PROPIETARIO Y BENEFICIO VIGENTE
-- =========================================================

SELECT
    p.ci,
    p.nombres || ' ' || p.apellidos AS propietario,
    v.placa,
    rb.estado AS estado_beneficio,
    rb.fecha_inicio,
    rb.fecha_fin
FROM persona p
JOIN registro_ruat rr
    ON rr.id_persona = p.id_persona
JOIN vehiculo v
    ON v.id_vehiculo = rr.id_vehiculo
JOIN registro_beneficio rb
    ON rb.id_registro_ruat = rr.id_registro_ruat
WHERE rr.fecha_fin IS NULL
  AND rb.fecha_fin IS NULL;
  