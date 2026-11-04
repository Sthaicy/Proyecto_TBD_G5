-- Esquema transcrito del modelo preliminar Modelo_Preliminar_TBD_Grupo#5.pdf.
-- El asterisco rojo del diagrama se interpreta como NOT NULL; sin asterisco = NULL.
-- P = PK; F = FK; U = UNIQUE; PF = PK y FK; UF = UNIQUE y FK.
-- El modelo no especifica secuencias ni identidad automática para sus NUMBER.
SET ECHO ON
SET FEEDBACK ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

CREATE TABLE unidad_medida (
  id_unidad NUMBER CONSTRAINT pk_unidad PRIMARY KEY,
  nombre VARCHAR2(30) NOT NULL,
  simbolo VARCHAR2(10) NOT NULL,
  CONSTRAINT uk_unidad_nombre UNIQUE (nombre)
);
    
CREATE TABLE entidad (
  id_entidad NUMBER CONSTRAINT pk_entidad PRIMARY KEY,
  nombre VARCHAR2(80) NOT NULL,
  tipo VARCHAR2(20),
  CONSTRAINT uk_entidad_nombre UNIQUE (nombre)
);

CREATE TABLE marca (
  id_marca NUMBER CONSTRAINT pk_marca PRIMARY KEY,
  nombre VARCHAR2(60) NOT NULL,
  CONSTRAINT uk_marca_nombre UNIQUE (nombre)
);

CREATE TABLE departamento (
  id_departamento NUMBER CONSTRAINT pk_departamento PRIMARY KEY,
  nombre VARCHAR2(40) NOT NULL,
  CONSTRAINT uk_departamento_nombre UNIQUE (nombre)
);

CREATE TABLE tipo_periodo (
  id_tipo_periodo NUMBER CONSTRAINT pk_tipo_periodo PRIMARY KEY,
  nombre VARCHAR2(20) NOT NULL,
  dias NUMBER(3) NOT NULL,
  CONSTRAINT uk_tipo_periodo_nombre UNIQUE (nombre)
);

CREATE TABLE tipo_regla (
  id_tipo_regla NUMBER CONSTRAINT pk_tipo_regla PRIMARY KEY,
  codigo VARCHAR2(30) NOT NULL,
  categoria VARCHAR2(10) NOT NULL,
  unidad_valor VARCHAR2(15) NOT NULL,
  descripcion VARCHAR2(250),
  CONSTRAINT uk_tipo_regla_codigo UNIQUE (codigo)
);

CREATE TABLE tipo_tarifa (
  id_tipo_tarifa NUMBER CONSTRAINT pk_tipo_tarifa PRIMARY KEY,
  codigo VARCHAR2(20) NOT NULL,
  descripcion VARCHAR2(100),
  CONSTRAINT uk_tipo_tarifa_codigo UNIQUE (codigo)
);

CREATE TABLE tipo_vehiculo (
  id_tipo_vehiculo NUMBER CONSTRAINT pk_tipo_vehiculo PRIMARY KEY,
  nombre VARCHAR2(40) NOT NULL,
  CONSTRAINT uk_tipo_vehiculo_nombre UNIQUE (nombre)
);

CREATE TABLE tipo_uso (
  id_tipo_uso NUMBER CONSTRAINT pk_tipo_uso PRIMARY KEY,
  nombre VARCHAR2(40) NOT NULL,
  CONSTRAINT uk_tipo_uso_nombre UNIQUE (nombre)
);

CREATE TABLE rol (
  id_rol NUMBER CONSTRAINT pk_rol PRIMARY KEY,
  nombre VARCHAR2(40) NOT NULL,
  descripcion VARCHAR2(200),
  CONSTRAINT uk_rol_nombre UNIQUE (nombre)
);

CREATE TABLE persona (
  id_persona NUMBER CONSTRAINT pk_persona PRIMARY KEY,
  ci VARCHAR2(20) NOT NULL,
  nombres VARCHAR2(100) NOT NULL,
  apellidos VARCHAR2(100) NOT NULL,
  telefono VARCHAR2(20),
  email VARCHAR2(120),
  CONSTRAINT uk_persona_ci UNIQUE (ci)
);

CREATE TABLE municipio (
  id_municipio NUMBER CONSTRAINT pk_municipio PRIMARY KEY,
  id_departamento NUMBER NOT NULL,
  nombre VARCHAR2(60) NOT NULL,
  latitud NUMBER(9,6) NOT NULL,
  longitud NUMBER(9,6) NOT NULL,
  zona VARCHAR2(10) NOT NULL,
  CONSTRAINT fk_municipio_depto FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento)
);

CREATE TABLE combustible (
  id_combustible NUMBER CONSTRAINT pk_combustible PRIMARY KEY,
  id_unidad NUMBER NOT NULL,
  nombre VARCHAR2(30) NOT NULL,
  capacidad_lt NUMBER(6,2) NOT NULL,
  origen VARCHAR2(10) NOT NULL,
  CONSTRAINT uk_combustible_nombre UNIQUE (nombre),
  CONSTRAINT fk_combustible_unidad FOREIGN KEY (id_unidad) REFERENCES unidad_medida(id_unidad)
);

CREATE TABLE estacion_servicio (
  id_estacion NUMBER CONSTRAINT pk_estacion PRIMARY KEY,
  id_municipio NUMBER NOT NULL,
  nombre VARCHAR2(100) NOT NULL,
  direccion VARCHAR2(200),
  latitud NUMBER(9,6),
  longitud NUMBER(9,6),
  estado VARCHAR2(10) NOT NULL,
  CONSTRAINT fk_estacion_municipio FOREIGN KEY (id_municipio) REFERENCES municipio(id_municipio)
);

CREATE TABLE surtidor (
  id_surtidor NUMBER CONSTRAINT pk_surtidor PRIMARY KEY,
  id_estacion NUMBER NOT NULL,
  id_combustible NUMBER NOT NULL,
  codigo VARCHAR2(20) NOT NULL,
  estado VARCHAR2(10) NOT NULL,
  CONSTRAINT uk_surtidor_codigo UNIQUE (id_estacion, codigo),
  CONSTRAINT fk_surtidor_comb FOREIGN KEY (id_combustible) REFERENCES combustible(id_combustible),
  CONSTRAINT fk_surtidor_estacion FOREIGN KEY (id_estacion) REFERENCES estacion_servicio(id_estacion)
);

CREATE TABLE ficha_aduana (
  id_ficha NUMBER CONSTRAINT pk_ficha PRIMARY KEY,
  id_marca NUMBER NOT NULL,
  id_tipo_vehiculo NUMBER NOT NULL,
  id_combustible NUMBER NOT NULL,
  modelo VARCHAR2(80) NOT NULL,
  anio_modelo NUMBER(4),
  cilindrada_cc NUMBER(6),
  traccion VARCHAR2(20),
  capacidad_tanque_lt NUMBER(6,2) NOT NULL,
  CONSTRAINT fk_ficha_comb FOREIGN KEY (id_combustible) REFERENCES combustible(id_combustible),
  CONSTRAINT fk_ficha_marca FOREIGN KEY (id_marca) REFERENCES marca(id_marca),
  CONSTRAINT fk_ficha_tipo FOREIGN KEY (id_tipo_vehiculo) REFERENCES tipo_vehiculo(id_tipo_vehiculo)
);

CREATE TABLE vehiculo (
  id_vehiculo NUMBER CONSTRAINT pk_vehiculo PRIMARY KEY,
  id_ficha NUMBER NOT NULL,
  id_tipo_uso NUMBER NOT NULL,
  placa VARCHAR2(15) NOT NULL,
  nro_chasis VARCHAR2(30) NOT NULL,
  nro_motor VARCHAR2(30) NOT NULL,
  color VARCHAR2(30),
  anio NUMBER(4),
  tag_rfid VARCHAR2(40),
  estado VARCHAR2(10) NOT NULL,
  CONSTRAINT uk_vehiculo_placa UNIQUE (placa),
  CONSTRAINT uk_vehiculo_chasis UNIQUE (nro_chasis),
  CONSTRAINT uk_vehiculo_rfid UNIQUE (tag_rfid),
  CONSTRAINT fk_vehiculo_ficha FOREIGN KEY (id_ficha) REFERENCES ficha_aduana(id_ficha),
  CONSTRAINT fk_vehiculo_uso FOREIGN KEY (id_tipo_uso) REFERENCES tipo_uso(id_tipo_uso)
);

CREATE TABLE vehiculo_combustible (
  id_vehiculo NUMBER NOT NULL,
  id_combustible NUMBER NOT NULL,
  capacidad_lt NUMBER(6,2) NOT NULL,
  origen VARCHAR2(10) NOT NULL,
  CONSTRAINT pk_vehiculo_comb PRIMARY KEY (id_vehiculo, id_combustible),
  CONSTRAINT fk_vc_comb FOREIGN KEY (id_combustible) REFERENCES combustible(id_combustible),
  CONSTRAINT fk_vc_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
);

CREATE TABLE registro_ruat (
  id_registro_ruat NUMBER CONSTRAINT pk_registro_ruat PRIMARY KEY,
  id_persona NUMBER NOT NULL,
  id_vehiculo NUMBER NOT NULL,
  nro_inscripcion VARCHAR2(30),
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE,
  CONSTRAINT fk_rr_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona),
  CONSTRAINT fk_rr_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
);

CREATE TABLE registro_beneficio (
  id_beneficio NUMBER CONSTRAINT pk_beneficio PRIMARY KEY,
  id_registro_ruat NUMBER NOT NULL,
  estado VARCHAR2(12) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE,
  motivo VARCHAR2(200),
  CONSTRAINT fk_ben_rr FOREIGN KEY (id_registro_ruat) REFERENCES registro_ruat(id_registro_ruat)
);

CREATE TABLE huella_digital (
  id_huella NUMBER CONSTRAINT pk_huella PRIMARY KEY,
  id_persona NUMBER NOT NULL,
  plantilla_hash VARCHAR2(256) NOT NULL,
  fecha_registro DATE NOT NULL,
  estado VARCHAR2(10) NOT NULL,
  fecha_bloqueo DATE,
  motivo_bloqueo VARCHAR2(200),
  CONSTRAINT uk_huella_persona UNIQUE (id_persona),
  CONSTRAINT fk_huella_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona)
);

CREATE TABLE usuario_sistema (
  id_usuario NUMBER CONSTRAINT pk_usuario PRIMARY KEY,
  id_persona NUMBER NOT NULL,
  id_rol NUMBER NOT NULL,
  id_estacion NUMBER,
  username VARCHAR2(40) NOT NULL,
  password_hash VARCHAR2(256) NOT NULL,
  estado VARCHAR2(10) NOT NULL,
  fecha_creacion DATE NOT NULL,
  CONSTRAINT uk_usuario_username UNIQUE (username),
  CONSTRAINT fk_usuario_estacion FOREIGN KEY (id_estacion) REFERENCES estacion_servicio(id_estacion),
  CONSTRAINT fk_usuario_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona),
  CONSTRAINT fk_usuario_rol FOREIGN KEY (id_rol) REFERENCES rol(id_rol)
);

CREATE TABLE regla (
  id_regla NUMBER CONSTRAINT pk_regla PRIMARY KEY,
  id_tipo_regla NUMBER NOT NULL,
  id_tipo_periodo NUMBER,
  id_tipo_vehiculo NUMBER,
  id_tipo_uso NUMBER,
  id_departamento NUMBER,
  zona VARCHAR2(10),
  valor_limite NUMBER(10,2) NOT NULL,
  tipo_limite VARCHAR2(10) NOT NULL,
  accion VARCHAR2(25) NOT NULL,
  descripcion VARCHAR2(250),
  vigente_desde DATE NOT NULL,
  vigente_hasta DATE,
  id_usuario_crea NUMBER,
  CONSTRAINT fk_regla_depto FOREIGN KEY (id_departamento) REFERENCES departamento(id_departamento),
  CONSTRAINT fk_regla_periodo FOREIGN KEY (id_tipo_periodo) REFERENCES tipo_periodo(id_tipo_periodo),
  CONSTRAINT fk_regla_tipo FOREIGN KEY (id_tipo_regla) REFERENCES tipo_regla(id_tipo_regla),
  CONSTRAINT fk_regla_tvehiculo FOREIGN KEY (id_tipo_vehiculo) REFERENCES tipo_vehiculo(id_tipo_vehiculo),
  CONSTRAINT fk_regla_uso FOREIGN KEY (id_tipo_uso) REFERENCES tipo_uso(id_tipo_uso),
  CONSTRAINT fk_regla_usuario FOREIGN KEY (id_usuario_crea) REFERENCES usuario_sistema(id_usuario)
);

CREATE TABLE regla_combustible (
  id_regla NUMBER NOT NULL,
  id_combustible NUMBER NOT NULL,
  CONSTRAINT pk_regla_comb PRIMARY KEY (id_regla, id_combustible),
  CONSTRAINT fk_rc_comb FOREIGN KEY (id_combustible) REFERENCES combustible(id_combustible),
  CONSTRAINT fk_rc_regla FOREIGN KEY (id_regla) REFERENCES regla(id_regla)
);

CREATE TABLE tipo_cambio (
  id_tipo_cambio NUMBER CONSTRAINT pk_tipo_cambio PRIMARY KEY,
  id_entidad NUMBER NOT NULL,
  fecha DATE NOT NULL,
  valor_bs_usd NUMBER(8,4) NOT NULL,
  CONSTRAINT uk_tipo_cambio_fecha UNIQUE (fecha),
  CONSTRAINT fk_tc_entidad FOREIGN KEY (id_entidad) REFERENCES entidad(id_entidad)
);

CREATE TABLE precio_combustible (
  id_precio NUMBER CONSTRAINT pk_precio PRIMARY KEY,
  id_combustible NUMBER NOT NULL,
  id_tipo_tarifa NUMBER NOT NULL,
  precio_bs NUMBER(10,4),
  precio_usd NUMBER(10,4),
  vigente_desde DATE NOT NULL,
  vigente_hasta DATE,
  CONSTRAINT fk_precio_comb FOREIGN KEY (id_combustible) REFERENCES combustible(id_combustible),
  CONSTRAINT fk_precio_tarifa FOREIGN KEY (id_tipo_tarifa) REFERENCES tipo_tarifa(id_tipo_tarifa)
);

CREATE TABLE transaccion (
  id_transaccion NUMBER CONSTRAINT pk_transaccion PRIMARY KEY,
  id_surtidor NUMBER NOT NULL,
  id_persona NUMBER NOT NULL,
  id_usuario NUMBER NOT NULL,
  tipo_transaccion VARCHAR2(20) NOT NULL,
  fecha_hora TIMESTAMP NOT NULL,
  estado VARCHAR2(10) NOT NULL,
  CONSTRAINT fk_tx_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona),
  CONSTRAINT fk_tx_surtidor FOREIGN KEY (id_surtidor) REFERENCES surtidor(id_surtidor),
  CONSTRAINT fk_tx_usuario FOREIGN KEY (id_usuario) REFERENCES usuario_sistema(id_usuario)
);
CREATE INDEX ix_tx_persona_fecha ON transaccion(id_persona, fecha_hora);
CREATE INDEX ix_tx_surtidor_fecha ON transaccion(id_surtidor, fecha_hora);

CREATE TABLE detalle_transaccion (
  id_detalle NUMBER CONSTRAINT pk_detalle PRIMARY KEY,
  id_transaccion NUMBER,
  id_combustible NUMBER NOT NULL,
  id_tipo_tarifa NUMBER NOT NULL,
  id_precio NUMBER NOT NULL,
  id_tipo_cambio NUMBER,
  id_regla NUMBER,
  cantidad NUMBER(10,2) NOT NULL,
  precio_unitario_bs NUMBER(10,4) NOT NULL,
  monto_bs NUMBER(12,2) NOT NULL,
  CONSTRAINT fk_det_comb FOREIGN KEY (id_combustible) REFERENCES combustible(id_combustible),
  CONSTRAINT fk_det_precio FOREIGN KEY (id_precio) REFERENCES precio_combustible(id_precio),
  CONSTRAINT fk_det_regla FOREIGN KEY (id_regla) REFERENCES regla(id_regla),
  CONSTRAINT fk_det_tarifa FOREIGN KEY (id_tipo_tarifa) REFERENCES tipo_tarifa(id_tipo_tarifa),
  CONSTRAINT fk_det_tc FOREIGN KEY (id_tipo_cambio) REFERENCES tipo_cambio(id_tipo_cambio),
  CONSTRAINT fk_det_tx FOREIGN KEY (id_transaccion) REFERENCES transaccion(id_transaccion)
);
CREATE INDEX ix_det_tx ON detalle_transaccion(id_transaccion);

CREATE TABLE permiso_bidon (
  id_permiso NUMBER CONSTRAINT pk_permiso_bidon PRIMARY KEY,
  id_persona NUMBER NOT NULL,
  id_combustible NUMBER NOT NULL,
  id_entidad NUMBER NOT NULL,
  id_tipo_periodo NUMBER NOT NULL,
  motivo VARCHAR2(100) NOT NULL,
  cantidad_maxima NUMBER(10,2) NOT NULL,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE,
  estado VARCHAR2(10) NOT NULL,
  CONSTRAINT fk_pb_comb FOREIGN KEY (id_combustible) REFERENCES combustible(id_combustible),
  CONSTRAINT fk_pb_entidad FOREIGN KEY (id_entidad) REFERENCES entidad(id_entidad),
  CONSTRAINT fk_pb_periodo FOREIGN KEY (id_tipo_periodo) REFERENCES tipo_periodo(id_tipo_periodo),
  CONSTRAINT fk_pb_persona FOREIGN KEY (id_persona) REFERENCES persona(id_persona)
);

CREATE TABLE recepcion_combustible (
  id_recepcion NUMBER CONSTRAINT pk_recepcion PRIMARY KEY,
  id_estacion NUMBER NOT NULL,
  id_entidad NUMBER NOT NULL,
  id_combustible NUMBER NOT NULL,
  id_tipo_tarifa NUMBER NOT NULL,
  cantidad NUMBER(12,2) NOT NULL,
  fecha_hora TIMESTAMP NOT NULL,
  nro_documento VARCHAR2(30),
  CONSTRAINT fk_recep_comb FOREIGN KEY (id_combustible) REFERENCES combustible(id_combustible),
  CONSTRAINT fk_recep_entidad FOREIGN KEY (id_entidad) REFERENCES entidad(id_entidad),
  CONSTRAINT fk_recep_estacion FOREIGN KEY (id_estacion) REFERENCES estacion_servicio(id_estacion),
  CONSTRAINT fk_recep_tarifa FOREIGN KEY (id_tipo_tarifa) REFERENCES tipo_tarifa(id_tipo_tarifa)
);

CREATE TABLE alerta (
  id_alerta NUMBER CONSTRAINT pk_alerta PRIMARY KEY,
  id_regla NUMBER NOT NULL,
  id_transaccion NUMBER,
  id_vehiculo NUMBER,
  id_usuario_revisor NUMBER,
  fecha TIMESTAMP NOT NULL,
  nivel VARCHAR2(10) NOT NULL,
  detalle VARCHAR2(400),
  estado VARCHAR2(12) NOT NULL,
  fecha_revision TIMESTAMP,
  CONSTRAINT fk_alerta_regla FOREIGN KEY (id_regla) REFERENCES regla(id_regla),
  CONSTRAINT fk_alerta_revisor FOREIGN KEY (id_usuario_revisor) REFERENCES usuario_sistema(id_usuario),
  CONSTRAINT fk_alerta_tx FOREIGN KEY (id_transaccion) REFERENCES transaccion(id_transaccion),
  CONSTRAINT fk_alerta_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
);
CREATE INDEX ix_alerta_estado ON alerta(estado, fecha);

CREATE TABLE carga_vehicular (
  id_transaccion NUMBER CONSTRAINT pk_carga_vehicular PRIMARY KEY,
  id_vehiculo NUMBER NOT NULL,
  id_beneficio NUMBER NOT NULL,
  CONSTRAINT fk_cv_beneficio FOREIGN KEY (id_beneficio) REFERENCES registro_beneficio(id_beneficio),
  CONSTRAINT fk_cv_tx FOREIGN KEY (id_transaccion) REFERENCES transaccion(id_transaccion),
  CONSTRAINT fk_cv_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)
);
CREATE INDEX ix_cv_vehiculo ON carga_vehicular(id_vehiculo);

CREATE TABLE compra_bidon (
  id_transaccion NUMBER CONSTRAINT pk_compra_bidon PRIMARY KEY,
  id_permiso NUMBER NOT NULL,
  nro_bidones NUMBER(3) NOT NULL,
  capacidad_bidon_lt NUMBER(6,2) NOT NULL,
  CONSTRAINT fk_cb_permiso FOREIGN KEY (id_permiso) REFERENCES permiso_bidon(id_permiso),
  CONSTRAINT fk_cb_tx FOREIGN KEY (id_transaccion) REFERENCES transaccion(id_transaccion)
);

CREATE TABLE auditoria (
  id_auditoria NUMBER CONSTRAINT pk_auditoria PRIMARY KEY,
  id_usuario NUMBER,
  tabla VARCHAR2(40) NOT NULL,
  operacion VARCHAR2(10) NOT NULL,
  id_registro VARCHAR2(40) NOT NULL,
  valor_anterior VARCHAR2(4000),
  valor_nuevo VARCHAR2(4000),
  fecha_hora TIMESTAMP NOT NULL,
  CONSTRAINT fk_audit_usuario FOREIGN KEY (id_usuario) REFERENCES usuario_sistema(id_usuario)
);

CREATE TABLE tiempo_viaje (
  id_origen NUMBER NOT NULL,
  id_destino NUMBER NOT NULL,
  distancia_km NUMBER(8,2) NOT NULL,
  tiempo_min_minutos NUMBER(8) NOT NULL,
  fecha_actualizacion DATE NOT NULL,
  CONSTRAINT pk_tiempo_viaje PRIMARY KEY (id_origen, id_destino),
  CONSTRAINT fk_tv_destino FOREIGN KEY (id_destino) REFERENCES municipio(id_municipio),
  CONSTRAINT fk_tv_origen FOREIGN KEY (id_origen) REFERENCES municipio(id_municipio)
);

-- Índices únicos de vigencia representados como expresiones CASE en el modelo.
CREATE UNIQUE INDEX uk_ben_vigente ON registro_beneficio
  (CASE WHEN fecha_fin IS NULL THEN id_registro_ruat END);
CREATE UNIQUE INDEX uk_rr_vigente ON registro_ruat
  (CASE WHEN fecha_fin IS NULL THEN id_vehiculo END);
