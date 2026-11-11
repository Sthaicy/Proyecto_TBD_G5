SET ECHO ON
SET FEEDBACK ON
SET SERVEROUTPUT ON
SET LINESIZE 200

-- =========================================================
-- PRUEBA 1: LA PLACA NO PUEDE REPETIRSE
-- Resultado esperado: Oracle rechaza el registro.
-- =========================================================

BEGIN
    INSERT INTO vehiculo (
        id_vehiculo, id_ficha, id_tipo_uso,
        placa, nro_chasis, nro_motor,
        color, anio, tag_rfid, estado
    ) VALUES (
        99, 1, 1,
        '1234ABC', 'CHASIS-PRUEBA-099', 'MOTOR-PRUEBA-099',
        'NEGRO', 2022, 'RFID-PRUEBA-099', 'ACTIVO'
    );

    DBMS_OUTPUT.PUT_LINE(
        'ERROR: Oracle permitió una placa duplicada.'
    );

    ROLLBACK;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE(
            'CORRECTO: Oracle rechazó la placa duplicada.'
        );
END;
/


-- =========================================================
-- PRUEBA 2: NO SE PUEDE RELACIONAR UN VEHICULO INEXISTENTE
-- Resultado esperado: Oracle rechaza la clave foránea.
-- =========================================================

BEGIN
    INSERT INTO vehiculo_combustible (
        id_vehiculo, id_combustible,
        capacidad_lt, origen
    ) VALUES (
        999, 1,
        40, 'FABRICA'
    );

    DBMS_OUTPUT.PUT_LINE(
        'ERROR: Oracle permitió un vehículo inexistente.'
    );

    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2291 THEN
            DBMS_OUTPUT.PUT_LINE(
                'CORRECTO: Oracle rechazó la clave foránea inexistente.'
            );
        ELSE
            RAISE;
        END IF;
END;
/


-- =========================================================
-- PRUEBA 3: CANTIDAD NEGATIVA
-- Actualmente no existe una restricción CHECK.
-- La fila se elimina inmediatamente con ROLLBACK.
-- =========================================================

SAVEPOINT antes_cantidad_negativa;

INSERT INTO detalle_transaccion (
    id_detalle, id_transaccion, id_combustible,
    id_tipo_tarifa, id_precio,
    id_tipo_cambio, id_regla,
    cantidad, precio_unitario_bs, monto_bs
) VALUES (
    999, 1, 1,
    1, 1,
    NULL, NULL,
    -5, 3.7400, -18.70
);

SELECT
    id_detalle,
    cantidad,
    monto_bs
FROM detalle_transaccion
WHERE id_detalle = 999;

PROMPT ATENCION: Oracle aceptó una cantidad negativa.
PROMPT Esto demuestra que falta una restricción CHECK (cantidad > 0).

ROLLBACK TO antes_cantidad_negativa;

SELECT COUNT(*) AS registros_negativos_restantes
FROM detalle_transaccion
WHERE id_detalle = 999;

COMMIT;
