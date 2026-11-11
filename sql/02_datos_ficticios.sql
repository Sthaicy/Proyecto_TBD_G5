SET ECHO ON
SET FEEDBACK ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

INSERT INTO unidad_medida (
    id_unidad,
    nombre,
    simbolo
) VALUES (
    1,
    'Litro',
    'L'
);

INSERT INTO unidad_medida (
    id_unidad,
    nombre,
    simbolo
) VALUES (
    2,
    'Metro cubico',
    'm3'
);


-- =========================================================
-- ENTIDADES EXTERNAS
-- =========================================================

INSERT INTO entidad (id_entidad, nombre, tipo)
VALUES (1, 'ANH', 'REGULADOR');

INSERT INTO entidad (id_entidad, nombre, tipo)
VALUES (2, 'YPFB', 'PROVEEDOR');

INSERT INTO entidad (id_entidad, nombre, tipo)
VALUES (3, 'RUAT', 'DATOS');

INSERT INTO entidad (id_entidad, nombre, tipo)
VALUES (4, 'ADUANA NACIONAL', 'DATOS');

INSERT INTO entidad (id_entidad, nombre, tipo)
VALUES (5, 'BCB', 'DATOS');


-- =========================================================
-- DEPARTAMENTOS
-- =========================================================

INSERT INTO departamento (id_departamento, nombre)
VALUES (1, 'Cochabamba');

INSERT INTO departamento (id_departamento, nombre)
VALUES (2, 'Santa Cruz');

INSERT INTO departamento (id_departamento, nombre)
VALUES (3, 'La Paz');


-- =========================================================
-- MUNICIPIOS
-- =========================================================

INSERT INTO municipio (
    id_municipio, id_departamento, nombre,
    latitud, longitud, zona
) VALUES (
    1, 1, 'Cochabamba',
    -17.389500, -66.156800, 'URBANA'
);

INSERT INTO municipio (
    id_municipio, id_departamento, nombre,
    latitud, longitud, zona
) VALUES (
    2, 1, 'Quillacollo',
    -17.392300, -66.278400, 'URBANA'
);

INSERT INTO municipio (
    id_municipio, id_departamento, nombre,
    latitud, longitud, zona
) VALUES (
    3, 1, 'Sacaba',
    -17.404200, -66.040000, 'URBANA'
);

INSERT INTO municipio (
    id_municipio, id_departamento, nombre,
    latitud, longitud, zona
) VALUES (
    4, 2, 'Santa Cruz de la Sierra',
    -17.783300, -63.182100, 'URBANA'
);

INSERT INTO municipio (
    id_municipio, id_departamento, nombre,
    latitud, longitud, zona
) VALUES (
    5, 3, 'La Paz',
    -16.500000, -68.150000, 'URBANA'
);


-- =========================================================
-- MARCAS
-- =========================================================

INSERT INTO marca (id_marca, nombre)
VALUES (1, 'Toyota');

INSERT INTO marca (id_marca, nombre)
VALUES (2, 'Nissan');

INSERT INTO marca (id_marca, nombre)
VALUES (3, 'Suzuki');

INSERT INTO marca (id_marca, nombre)
VALUES (4, 'Volvo');

INSERT INTO marca (id_marca, nombre)
VALUES (5, 'King Long');


-- =========================================================
-- TIPOS DE PERIODO
-- =========================================================

INSERT INTO tipo_periodo (id_tipo_periodo, nombre, dias)
VALUES (1, 'DIARIO', 1);

INSERT INTO tipo_periodo (id_tipo_periodo, nombre, dias)
VALUES (2, 'SEMANAL', 7);

INSERT INTO tipo_periodo (id_tipo_periodo, nombre, dias)
VALUES (3, 'MENSUAL', 30);


-- =========================================================
-- TIPOS DE TARIFA
-- =========================================================

INSERT INTO tipo_tarifa (id_tipo_tarifa, codigo, descripcion)
VALUES (1, 'SUBVENCIONADO', 'Precio regulado por el Estado');

INSERT INTO tipo_tarifa (id_tipo_tarifa, codigo, descripcion)
VALUES (2, 'INTERNACIONAL', 'Precio sin subvencion');


-- =========================================================
-- TIPOS DE VEHICULO
-- =========================================================

INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre)
VALUES (1, 'MOTO');

INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre)
VALUES (2, 'AUTOMOVIL');

INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre)
VALUES (3, 'CAMIONETA');

INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre)
VALUES (4, 'CAMION');

INSERT INTO tipo_vehiculo (id_tipo_vehiculo, nombre)
VALUES (5, 'MINIBUS');


-- =========================================================
-- TIPOS DE USO
-- =========================================================

INSERT INTO tipo_uso (id_tipo_uso, nombre)
VALUES (1, 'PARTICULAR');

INSERT INTO tipo_uso (id_tipo_uso, nombre)
VALUES (2, 'TRANSPORTE PUBLICO');

INSERT INTO tipo_uso (id_tipo_uso, nombre)
VALUES (3, 'TRANSPORTE DE CARGA');


-- =========================================================
-- ROLES
-- =========================================================

INSERT INTO rol (id_rol, nombre, descripcion)
VALUES (1, 'ADMINISTRADOR', 'Gestion general del sistema');

INSERT INTO rol (id_rol, nombre, descripcion)
VALUES (2, 'OPERADOR_ESTACION', 'Registra cargas de combustible');

INSERT INTO rol (id_rol, nombre, descripcion)
VALUES (3, 'AUDITOR', 'Revisa transacciones y alertas');


-- =========================================================
-- TIPOS DE REGLA
-- =========================================================

INSERT INTO tipo_regla (
    id_tipo_regla, codigo, categoria,
    unidad_valor, descripcion
) VALUES (
    1, 'LIMITE_VOLUMEN', 'OPERACION',
    'LITROS', 'Limite de combustible por periodo'
);

INSERT INTO tipo_regla (
    id_tipo_regla, codigo, categoria,
    unidad_valor, descripcion
) VALUES (
    2, 'LIMITE_FRECUENCIA', 'ANOMALIA',
    'CARGAS', 'Cantidad maxima de cargas por periodo'
);

INSERT INTO tipo_regla (
    id_tipo_regla, codigo, categoria,
    unidad_valor, descripcion
) VALUES (
    3, 'CAPACIDAD_TANQUE', 'OPERACION',
    'PORCENTAJE', 'Control de capacidad del tanque'
);

INSERT INTO tipo_regla (
    id_tipo_regla, codigo, categoria,
    unidad_valor, descripcion
) VALUES (
    4, 'GEOLOCALIZACION', 'ANOMALIA',
    'FACTOR', 'Cargas en lugares distantes en tiempo imposible'
);

INSERT INTO tipo_regla (
    id_tipo_regla, codigo, categoria,
    unidad_valor, descripcion
) VALUES (
    5, 'MAX_VEHICULOS', 'OPERACION',
    'VEHICULOS', 'Cantidad maxima de vehiculos por persona'
);

-- =========================================================
-- COMBUSTIBLES
-- capacidad_lt y origen son valores provisionales porque
-- su ubicación definitiva debe ser confirmada por el grupo.
-- =========================================================

INSERT INTO combustible (
    id_combustible, id_unidad, nombre,
    capacidad_lt, origen
) VALUES (
    1, 1, 'GASOLINA',
    1, 'PRUEBA'
);

INSERT INTO combustible (
    id_combustible, id_unidad, nombre,
    capacidad_lt, origen
) VALUES (
    2, 1, 'DIESEL',
    1, 'PRUEBA'
);

INSERT INTO combustible (
    id_combustible, id_unidad, nombre,
    capacidad_lt, origen
) VALUES (
    3, 2, 'GNV',
    1, 'PRUEBA'
);


-- =========================================================
-- ESTACIONES DE SERVICIO
-- =========================================================

INSERT INTO estacion_servicio (
    id_estacion, id_municipio, nombre,
    direccion, latitud, longitud, estado
) VALUES (
    1, 1, 'Estacion Central Cochabamba',
    'Av. Blanco Galindo km 2',
    -17.394000, -66.178000, 'ACTIVA'
);

INSERT INTO estacion_servicio (
    id_estacion, id_municipio, nombre,
    direccion, latitud, longitud, estado
) VALUES (
    2, 2, 'Estacion Quillacollo',
    'Av. Blanco Galindo km 11',
    -17.392500, -66.276000, 'ACTIVA'
);

INSERT INTO estacion_servicio (
    id_estacion, id_municipio, nombre,
    direccion, latitud, longitud, estado
) VALUES (
    3, 3, 'Estacion Sacaba',
    'Av. Villazon km 8',
    -17.403000, -66.043000, 'ACTIVA'
);


-- =========================================================
-- SURTIDORES
-- =========================================================

INSERT INTO surtidor (
    id_surtidor, id_estacion,
    id_combustible, codigo, estado
) VALUES (
    1, 1, 1, 'CBBA-GAS-01', 'ACTIVO'
);

INSERT INTO surtidor (
    id_surtidor, id_estacion,
    id_combustible, codigo, estado
) VALUES (
    2, 1, 2, 'CBBA-DIE-01', 'ACTIVO'
);

INSERT INTO surtidor (
    id_surtidor, id_estacion,
    id_combustible, codigo, estado
) VALUES (
    3, 2, 1, 'QUI-GAS-01', 'ACTIVO'
);

INSERT INTO surtidor (
    id_surtidor, id_estacion,
    id_combustible, codigo, estado
) VALUES (
    4, 2, 2, 'QUI-DIE-01', 'ACTIVO'
);

INSERT INTO surtidor (
    id_surtidor, id_estacion,
    id_combustible, codigo, estado
) VALUES (
    5, 3, 1, 'SAC-GAS-01', 'ACTIVO'
);


-- =========================================================
-- FICHAS TÉCNICAS DE ADUANA
-- =========================================================

INSERT INTO ficha_aduana (
    id_ficha, id_marca, id_tipo_vehiculo,
    id_combustible, modelo, anio_modelo,
    cilindrada_cc, traccion, capacidad_tanque_lt
) VALUES (
    1, 1, 2,
    1, 'Corolla', 2020,
    1800, '4X2', 50
);

INSERT INTO ficha_aduana (
    id_ficha, id_marca, id_tipo_vehiculo,
    id_combustible, modelo, anio_modelo,
    cilindrada_cc, traccion, capacidad_tanque_lt
) VALUES (
    2, 2, 3,
    2, 'Frontier', 2021,
    2500, '4X4', 80
);

INSERT INTO ficha_aduana (
    id_ficha, id_marca, id_tipo_vehiculo,
    id_combustible, modelo, anio_modelo,
    cilindrada_cc, traccion, capacidad_tanque_lt
) VALUES (
    3, 3, 1,
    1, 'GN 125', 2022,
    125, 'CADENA', 12
);

INSERT INTO ficha_aduana (
    id_ficha, id_marca, id_tipo_vehiculo,
    id_combustible, modelo, anio_modelo,
    cilindrada_cc, traccion, capacidad_tanque_lt
) VALUES (
    4, 5, 5,
    2, 'Minibus XMQ', 2019,
    3000, '4X2', 100
);

-- =========================================================
-- PERSONAS
-- =========================================================

-- Propietario del vehículo
INSERT INTO persona (
    id_persona, ci, nombres, apellidos,
    telefono, email
) VALUES (
    1, '8765432', 'Carlos', 'Mendoza Rojas',
    '70701010', 'carlos.ficticio@email.com'
);

-- Operador de la estación
INSERT INTO persona (
    id_persona, ci, nombres, apellidos,
    telefono, email
) VALUES (
    2, '7654321', 'Maria', 'Flores Vargas',
    '70702020', 'maria.ficticia@email.com'
);


-- =========================================================
-- USUARIO DEL OPERADOR
-- La contraseña es un valor ficticio no utilizable.
-- =========================================================

INSERT INTO usuario_sistema (
    id_usuario, id_persona, id_rol,
    id_estacion, username, password_hash,
    estado, fecha_creacion
) VALUES (
    1, 2, 2,
    1, 'operador.cbba',
    'HASH_FICTICIO_NO_UTILIZABLE',
    'ACTIVO', DATE '2026-01-01'
);


-- =========================================================
-- VEHÍCULO
-- =========================================================

INSERT INTO vehiculo (
    id_vehiculo, id_ficha, id_tipo_uso,
    placa, nro_chasis, nro_motor,
    color, anio, tag_rfid, estado
) VALUES (
    1, 1, 1,
    '1234ABC', 'CHASIS-FICTICIO-001', 'MOTOR-FICTICIO-001',
    'BLANCO', 2020, 'RFID-BSISA-001', 'ACTIVO'
);

INSERT INTO vehiculo_combustible (
    id_vehiculo, id_combustible,
    capacidad_lt, origen
) VALUES (
    1, 1,
    50, 'FABRICA'
);


-- =========================================================
-- REGISTRO RUAT Y BENEFICIO
-- =========================================================

INSERT INTO registro_ruat (
    id_registro_ruat, id_persona, id_vehiculo,
    nro_inscripcion, fecha_inicio, fecha_fin
) VALUES (
    1, 1, 1,
    'RUAT-FICTICIO-001', DATE '2025-01-01', NULL
);

INSERT INTO registro_beneficio (
    id_beneficio, id_registro_ruat, estado,
    fecha_inicio, fecha_fin, motivo
) VALUES (
    1, 1, 'HABILITADO',
    DATE '2026-01-01', NULL, 'Beneficio ficticio para pruebas'
);


-- =========================================================
-- PRECIO SUBVENCIONADO
-- =========================================================

INSERT INTO precio_combustible (
    id_precio, id_combustible, id_tipo_tarifa,
    precio_bs, precio_usd,
    vigente_desde, vigente_hasta
) VALUES (
    1, 1, 1,
    3.7400, NULL,
    DATE '2026-01-01', NULL
);


-- =========================================================
-- REGLA DE CAPACIDAD
-- El volumen no debe superar el 100 % del tanque.
-- =========================================================

INSERT INTO regla (
    id_regla, id_tipo_regla, id_tipo_periodo,
    id_tipo_vehiculo, id_tipo_uso, id_departamento,
    zona, valor_limite, tipo_limite,
    accion, descripcion,
    vigente_desde, vigente_hasta, id_usuario_crea
) VALUES (
    1, 3, NULL,
    2, 1, 1,
    'URBANA', 100, 'INDIVIDUAL',
    'GENERAR_ALERTA', 'La carga no debe superar la capacidad del tanque',
    DATE '2026-01-01', NULL, 1
);

INSERT INTO regla_combustible (
    id_regla, id_combustible
) VALUES (
    1, 1
);


-- =========================================================
-- TRANSACCIÓN 1: CARGA NORMAL DE 30 LITROS
-- =========================================================

INSERT INTO transaccion (
    id_transaccion, id_surtidor, id_persona,
    id_usuario, tipo_transaccion,
    fecha_hora, estado
) VALUES (
    1, 1, 1,
    1, 'CARGA_VEHICULAR',
    TIMESTAMP '2026-11-10 10:00:00', 'APROBADA'
);

INSERT INTO detalle_transaccion (
    id_detalle, id_transaccion, id_combustible,
    id_tipo_tarifa, id_precio,
    id_tipo_cambio, id_regla,
    cantidad, precio_unitario_bs, monto_bs
) VALUES (
    1, 1, 1,
    1, 1,
    NULL, NULL,
    30, 3.7400, 112.20
);

INSERT INTO carga_vehicular (
    id_transaccion, id_vehiculo, id_beneficio
) VALUES (
    1, 1, 1
);


-- =========================================================
-- TRANSACCIÓN 2: CARGA OBSERVADA DE 55 LITROS
-- El vehículo tiene capacidad declarada de 50 litros.
-- =========================================================

INSERT INTO transaccion (
    id_transaccion, id_surtidor, id_persona,
    id_usuario, tipo_transaccion,
    fecha_hora, estado
) VALUES (
    2, 1, 1,
    1, 'CARGA_VEHICULAR',
    TIMESTAMP '2026-11-10 17:00:00', 'OBSERVADA'
);

INSERT INTO detalle_transaccion (
    id_detalle, id_transaccion, id_combustible,
    id_tipo_tarifa, id_precio,
    id_tipo_cambio, id_regla,
    cantidad, precio_unitario_bs, monto_bs
) VALUES (
    2, 2, 1,
    1, 1,
    NULL, 1,
    55, 3.7400, 205.70
);

INSERT INTO carga_vehicular (
    id_transaccion, id_vehiculo, id_beneficio
) VALUES (
    2, 1, 1
);


-- =========================================================
-- ALERTA GENERADA PARA LA SEGUNDA CARGA
-- =========================================================

INSERT INTO alerta (
    id_alerta, id_regla, id_transaccion,
    id_vehiculo, id_usuario_revisor,
    fecha, nivel, detalle,
    estado, fecha_revision
) VALUES (
    1, 1, 2,
    1, NULL,
    TIMESTAMP '2026-11-10 17:01:00',
    'ALTA',
    'Carga de 55 litros en vehículo con capacidad declarada de 50 litros',
    'PENDIENTE', NULL
);

COMMIT;