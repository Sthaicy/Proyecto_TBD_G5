# Proyecto_TBD_G5

## Integrantes

- Arrosquipa Arnez Alba Jhessica
- Bustamante Escobar Jhosselin Sthaicy
- Cortez Ramírez Rogelio José

## Entorno Oracle oficial

Base de datos para monitoreo de transacciones de combustible. Se utiliza la imagen
completa **Oracle AI Database 26ai Free 23.26.3.0**, publicada por Oracle en
`container-registry.oracle.com/database/free:23.26.3.0`.
La etiqueta contempla las arquitecturas amd64 y arm64 disponibles en el registro.
Se conserva la versión identificada en los registros del entorno anterior.

Fuentes oficiales:

- [Imagen, etiquetas, licencia y requisitos](https://container-registry.oracle.com/ords/ocr/ba/database/free).
- [Ejecución con Docker o Podman](https://docs.oracle.com/es/database/oracle/agent-memory/26.8/guide/run-locally.html).
- [Scripts de contenedores de Oracle](https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance).

Se elige la imagen completa porque Lite excluye herramientas como Data Pump y
RMAN. El software está sujeto a Oracle Free Use Terms and Conditions; revisar los
términos publicados por Oracle antes de descargarlo.

La nueva configuración utiliza el proyecto Compose `fuel-oracle-oficial`, el
contenedor `fuel-oracle-oficial` y el volumen `fuel-oracle-oficial-data`. No reutiliza
el contenedor comunitario `fuel-monitoring-oracle` ni su volumen
`proyecto_tbd_g5_oracle-data`. No importa automáticamente los datos anteriores.

## 1. Preparar el equipo y las contraseñas

Se necesita Docker Engine con Docker Compose, conexión al registro de Oracle,
al menos 13 GB libres en el almacenamiento de Docker y al menos 2 GB de memoria
disponibles para el contenedor. La descarga y los datos persistidos consumen disco.

Todos los comandos `docker compose` se ejecutan en la **terminal de Debian**, desde
la raíz del repositorio, donde está `docker-compose.yml`.

```bash
docker --version
docker compose version
```

Si todavía no tienes `.env`, créalo copiando `.env.example`:

```bash
if [ ! -f .env ]; then
  cp .env.example .env
fi
chmod 600 .env
code .env
```

Configura estas dos variables, sustituyendo la contraseña de ejemplo por una propia:

```dotenv
ORACLE_PWD=CAMBIA_ESTE_VALOR_POR_UNA_CLAVE_FUERTE
DB_PORT=1522
```

**Si ya tenías el `.env` anterior:** cambia el nombre `ORACLE_PASSWORD` por
`ORACLE_PWD` y el puerto a `1522`. Las variables `APP_USER` y `APP_USER_PASSWORD`
ya no se utilizan y puedes retirarlas de ese archivo. La imagen oficial no crea
`FUEL_APP` mediante esas variables: se creará en el paso 3.

`ORACLE_PWD` configura las cuentas administrativas de la nueva base; no es la
contraseña de `FUEL_APP`. Usa contraseñas diferentes. Para evitar interpretaciones
especiales de Compose puedes usar una clave larga aleatoria con letras y números.
No subas `.env` a Git. Cambiar esta variable no sustituye la contraseña de una base
que ya fue inicializada.

## 2. Descargar e iniciar la nueva base

En la **terminal de Debian**:

```bash
docker compose config --quiet
docker compose pull oracle
docker compose up -d oracle
docker compose ps
```

`config --quiet` valida la configuración sin imprimir las contraseñas. `pull`
descarga la imagen oficial. `up` crea el contenedor y su nuevo volumen persistente.
Si el registro solicita autenticación, completa el acceso y la aceptación de
los términos en Oracle Container Registry y autentica el cliente con:

```bash
docker login container-registry.oracle.com
```

Después repite `docker compose pull oracle`. No compartas credenciales ni tokens.

Espera a que el contenedor muestre `healthy`; el primer inicio puede tardar varios
minutos. El chequeo de salud consulta Oracle y verifica que `FREEPDB1` esté abierta
en modo lectura/escritura.
Para observar el arranque:

```bash
docker compose logs -f oracle
```

Espera `DATABASE IS READY TO USE!`. Pulsa `Ctrl+C` para salir de los registros;
Oracle seguirá ejecutándose. El servicio de trabajo es `FREEPDB1`.

## 3. Crear el usuario FUEL_APP una sola vez

En la **terminal de Debian**, abre SQL*Plus como administrador local del contenedor:

```bash
docker compose exec oracle sqlplus -L / as sysdba
```

Cuando aparezca `SQL>`, estás en la **consola SQL de Oracle**. Ejecuta:

```sql
WHENEVER SQLERROR EXIT FAILURE ROLLBACK
ALTER SESSION SET CONTAINER = FREEPDB1;
SHOW CON_NAME
SELECT banner_full FROM v$version;

SET ECHO OFF
SET VERIFY OFF
ACCEPT clave_app CHAR PROMPT 'Nueva contrasena para FUEL_APP: ' HIDE
```

Introduce la contraseña cuando se solicite y pulsa Enter. Espera a que reaparezca
`SQL>` antes de pegar este segundo bloque:

```sql
CREATE USER FUEL_APP IDENTIFIED BY "&clave_app"
  DEFAULT TABLESPACE USERS
  TEMPORARY TABLESPACE TEMP
  QUOTA 100M ON USERS;

UNDEFINE clave_app
GRANT CREATE SESSION, CREATE TABLE TO FUEL_APP;
EXIT;
```

SQL*Plus solicita una contraseña nueva sin mostrarla. Para este comando utiliza una
clave larga con letras y números; evita comillas dobles y `&`. Guarda la contraseña
para las conexiones siguientes. Se conceden permisos para conectarse, crear las
tablas e índices propios y almacenar hasta 100 MB en `USERS`. No se concede `DBA`.
Los permisos para futuros objetos PL/SQL se añadirán cuando se necesiten.

Este paso se ejecuta solo una vez por base. Si `FUEL_APP` ya existe, no lo borres:
continúa con la conexión del siguiente paso y revisa qué objetos contiene.

## 4. Crear las tablas una sola vez

En la **terminal de Debian**, abre una conexión como usuario del proyecto:

```bash
docker compose exec oracle sqlplus -L FUEL_APP@//localhost:1521/FREEPDB1
```

Introduce la contraseña de `FUEL_APP`. Dentro del contenedor se usa siempre el
puerto `1521`; `1522` es el puerto publicado en Debian.

En la **consola SQL de Oracle**:

```sql
SHOW USER
SHOW CON_NAME
@/workspace/sql/01_schema.sql
SELECT COUNT(*) AS total_tablas FROM user_tables;
SELECT object_name, object_type FROM user_objects WHERE status = 'INVALID';
```

El resultado esperado es **35 tablas y ningún objeto inválido**. El script protege
contra su ejecución accidental como administrador o en otra PDB. Si aparece un
error, detente y revisa su causa antes de continuar; SQL*Plus saldrá con error.

El esquema no es idempotente: no vuelvas a ejecutarlo sobre tablas existentes.
Oracle confirma cada operación DDL; un error intermedio puede dejar parte del
esquema creada. Un reinicio del contenedor no borra esas tablas.

## 5. Agregar los datos ficticios una sola vez

En la misma **consola SQL de FUEL_APP**, después de crear las tablas:

```sql
@/workspace/sql/02_datos_ficticios.sql
SELECT COUNT(*) AS transacciones FROM transaccion;
SELECT COUNT(*) AS alertas FROM alerta;
EXIT;
```

Se esperan **2 transacciones y 1 alerta**. El script contiene 73 inserciones en 28
tablas, utiliza identificadores fijos y hace `COMMIT` al terminar. Si falla, revierte
las inserciones pendientes. No lo repitas si ya se cargó: fallará por duplicados.
No mezcles su ejecución con otros cambios pendientes de confirmar.

Se conservan los datos ficticios del compañero: catálogos, tres estaciones, cinco
surtidores, un vehículo con tanque de 50 litros y dos cargas en una estación.
La alerta se inserta manualmente; todavía no existe un trigger o procedimiento que
la genere. Los valores provisionales de `combustible.capacidad_lt` y `origen`
siguen pendientes de revisión del modelo y no se usan para calcular la capacidad.

## 6. Consultar y ejecutar las pruebas

Abre una **conexión nueva desde Debian**:

```bash
docker compose exec oracle sqlplus -L FUEL_APP@//localhost:1521/FREEPDB1
```

En **SQL*Plus**:

```sql
@/workspace/sql/03_consultas_prueba.sql
@/workspace/sql/04_pruebas_integridad.sql
EXIT;
```

Resultados esperados con los datos iniciales:

| Comprobación | Resultado |
|---|---|
| Historial de `1234ABC` | Dos cargas, de 30 y 55 litros |
| Total por vehículo/estación, estado `APROBADA` | 30 litros y Bs 112,20 |
| Total por vehículo/estación, estado `OBSERVADA` | 55 litros y Bs 205,70 |
| Total de ambas operaciones | 85 litros y Bs 317,90; no implica que ambas estén aprobadas |
| Exceso sobre el tanque de 50 litros | Transacción 2, exceso de 5 litros |
| Alertas pendientes | Una alerta insertada manualmente |
| Propietario con beneficio | Carlos Mendoza Rojas, si la fecha actual cae dentro de la vigencia |
| Placa duplicada | Rechazada por `UK_VEHICULO_PLACA` |
| Vehículo inexistente | Rechazado por `FK_VC_VEHICULO` |
| Cantidad negativa | Limitación confirmada: el esquema aún la permite |
| Registros temporales de las pruebas | Ninguno conservado |

Las pruebas comprueban esquema y datos, lanzan error si un resultado esperado no se
cumple y revierten sus registros temporales mediante un savepoint. No hacen
`COMMIT`. Ejecútalas en una conexión nueva sin trabajo pendiente. El mensaje
`LIMITACION CONFIRMADA` no representa una protección: falta acordar e implementar
el `CHECK`. Si se añade, habrá que actualizar esa prueba para esperar el rechazo.

Las consultas separan combustible, unidad y estado. El historial selecciona al
propietario por la fecha de la operación, usando intervalos de vigencia
`[fecha_inicio, fecha_fin)`. El modelo todavía no impide solapamientos históricos.
La comparación con capacidad en litros solo contempla combustibles medidos en
litros; no convierte GNV en m3 a litros.

## 7. Conexión desde DBeaver o SQL Developer

- Host: `127.0.0.1`.
- Puerto: `1522`, o el valor que hayas configurado en `DB_PORT`.
- Tipo de conexión: nombre de servicio, no SID.
- Servicio: `FREEPDB1`.
- Usuario: `FUEL_APP`.
- Contraseña: la elegida en el paso 3.

El puerto solo se publica en localhost. Esta configuración es para trabajo local.

## 8. Detener, volver a iniciar y verificar persistencia

Desde la **terminal de Debian**:

```bash
docker compose stop oracle
docker compose start oracle
docker compose ps
```

Espera nuevamente `healthy`, conecta como `FUEL_APP` y verifica en **SQL*Plus**:

```sql
SELECT COUNT(*) AS total_tablas FROM user_tables;
SELECT COUNT(*) AS transacciones FROM transaccion;
SELECT COUNT(*) AS alertas FROM alerta;
```

Deben mantenerse los conteos 35, 2 y 1. No repitas la creación del usuario ni la
carga del esquema o los datos después de un reinicio. El volumen mantiene la base,
pero no sustituye una copia de seguridad. No utilices `docker compose down -v`:
eliminaría el volumen de esta base.

## Problemas frecuentes

- **Falta ORACLE_PWD:** actualiza el `.env` antiguo como indica el paso 1.
- **ORA-01017:** comprueba qué cuenta estás usando y su contraseña; administrador
  y `FUEL_APP` tienen claves distintas.
- **ORA-01920 / ORA-00955 / ORA-00001:** pueden indicar que ya se creó el usuario,
  un objeto o los datos. Revisa el estado; no borres la base para reintentar.
- **Permiso denegado al hacer git pull en sql/:** comprueba `ls -ld sql`. Si esa
  carpeta pertenece a `nobody`, desde la raíz del proyecto ejecuta
  `sudo chown "$(id -un):$(id -gn)" sql`. El contenedor solo necesita leerla.
- **Error de descarga o conexión al registro:** revisa red, autenticación y términos
  de Oracle; no sustituyas la imagen por otra sin verificar su procedencia.

Los PDF de `Diagramas/` e `Informes/` conservan los antecedentes. Las modificaciones
al modelo propuestas por el compañero siguen sujetas a revisión del equipo.

## Validación de este cambio (11/11/2026)

Se validaron Compose y los cuatro scripts en un contenedor temporal aislado con
Oracle AI Database 26ai Free 23.26.3.0.0, utilizando la imagen comunitaria ya
instalada y los privilegios mínimos documentados. Se comprobaron la creación de
35 tablas, las 73 inserciones, las seis consultas, la repetición de las pruebas
sin residuos, los errores esperados y el chequeo de PDB abierta/cerrada. También
se probaron cambios de propietario, estaciones homónimas, cargas divididas y
beneficios bloqueados. El contenedor temporal se retiró al finalizar.

Queda pendiente descargar y arrancar la imagen oficial: la consulta directa al
registro no respondió desde el entorno de validación. La etiqueta y su procedencia
se verificaron en la documentación oficial de Oracle enlazada al principio.
