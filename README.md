# Proyecto TBD G5

Sistema de control y monitoreo de combustible para Taller de Base de Datos.

- Arrosquipa Arnez Alba Jhessica
- Bustamante Escobar Jhosselin Sthaicy
- Cortez Ramirez Rogelio Jose

## Estado y alcance

La configuracion utiliza la imagen oficial completa
`container-registry.oracle.com/database/free:23.26.3.0`, el contenedor
`fuel-oracle-oficial`, el volumen `fuel-oracle-oficial-data` y el servicio Oracle
`FREEPDB1`. El puerto publicado en Debian es `127.0.0.1:1522`.

El esquema actualizado contiene **38 tablas**, dos vistas de inventario,
identificadores automaticos y restricciones de integridad. Los datos iniciales
incluyen dos transacciones, una alerta manual, cinco tanques y un ejemplo de
recepcion, merma y medicion. Son datos de demostracion: todavia no cumplen el
volumen final de 50.000 operaciones ni generan alertas automaticamente.

Estos scripts son para una **base nueva**. No ejecutar `01_schema.sql` sobre las
35 tablas anteriores. No hay una migracion automatica de datos existentes:
antes de modificar un entorno ya poblado se necesita respaldo y una migracion
especifica. No borrar volumenes para resolver un error.

## Verificacion del 18 de noviembre de 2026

Revision estatica correcta: 38 tablas, 81 inserciones, 73 FK, siete triggers y dos
vistas. Se revisaron columnas, claves candidatas, correspondencia de los datos de
prueba y referencias. Esto **no sustituye compilar y ejecutar los scripts en Oracle**.
La descarga de la imagen oficial comenzo correctamente, pero no habia terminado
al cerrar esta revision (aproximadamente 3,45 GiB comprimidos y conexion lenta).
La validacion real de los triggers y las pruebas queda pendiente hasta el arranque.

## 1 Preparar Debian

Abre el proyecto con Visual Studio Code y utiliza su terminal integrada.
Todos los comandos de terminal se ejecutan desde la carpeta que contiene
`docker-compose.yml`:

```bash
cd "/home/sthaicy/Documentos/PROYECTO TBD-GASOLINA/Proyecto_TBD_G5"
docker --version
docker compose version
```

Necesitas espacio para imagen y datos (al menos 13 GB libres, preferiblemente
mas) y memoria disponible para Oracle (al menos 2 GB, ademas del sistema).

Crea `.env` solo si no existe:

```bash
if [ ! -f .env ]; then cp .env.example .env; fi
chmod 600 .env
code .env
```

Define `ORACLE_PWD` con una clave propia y conserva `DB_PORT=1522`.
Si viene de la imagen comunitaria, sustituye el nombre `ORACLE_PASSWORD` por
`ORACLE_PWD`. `APP_USER` y `APP_USER_PASSWORD` no crean usuarios en esta imagen.
No publiques `.env`. Cambiarlo no cambia las claves de una base ya inicializada.

## 2 Descargar y arrancar Oracle

```bash
docker compose config --quiet
docker compose pull oracle
docker compose up -d oracle
docker compose ps
docker compose logs -f oracle
```

Espera `DATABASE IS READY TO USE!` y estado `healthy`. `Ctrl+C` sale del visor
de registros sin detener la base. El primer inicio puede tardar varios minutos.

Si falla la descarga, conserva el mensaje exacto:

- `unauthorized` o `denied`: revisa el acceso y los terminos del repositorio
  oficial; si corresponde, ejecuta `docker login container-registry.oracle.com`
  y repite la descarga. No compartas tokens ni contrasenas.
- `no such host`, `timeout` o errores TLS: comprobar DNS, conexion, proxy y hora
  del equipo; no desactivar la validacion TLS.
- `manifest unknown`: comprobar la etiqueta; no cambiar silenciosamente a `latest`.
- `no matching manifest`: comprobar arquitectura con `uname -m` y las etiquetas
  compatibles del registro.
- `no space left on device`: revisar `df -h` y `docker system df`; no borrar
  volumenes de bases para liberar espacio.

Fuentes oficiales: [Oracle Container Registry](https://container-registry.oracle.com/ords/ocr/ba/database/free),
[Oracle Free](https://www.oracle.com/database/free/),
[scripts de Oracle](https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance).
El software se distribuye bajo los terminos publicados por Oracle.

## 3 Crear el usuario una sola vez

Desde la terminal de Debian:

```bash
docker compose exec oracle sqlplus -L / as sysdba @/workspace/sql/00_crear_usuario.sql
```

Escribe una clave para `FUEL_APP` cuando se solicite. Usa una clave diferente de
la administrativa, con al menos 16 letras y numeros, sin `&` ni comillas dobles.
No se muestra al escribirla. Este usuario crea objetos de su esquema y dispone
de 100 MB de cuota, sin recibir `DBA`. La cuota debe revisarse para la carga final.

Si el usuario ya existe, no lo borres ni repitas los pasos a ciegas: inspecciona
sus tablas. Para una cuenta nueva son necesarios los permisos de tablas,
vistas, triggers y secuencias concedidos por este script.

## 4 Crear esquema y cargar ejemplos

Desde la terminal:

```bash
docker compose exec oracle sqlplus -L FUEL_APP@//localhost:1521/FREEPDB1
```

Escribe la clave de `FUEL_APP`. Cuando aparezca `SQL>`, ejecuta:

```sql
SHOW USER
SHOW CON_NAME
SELECT COUNT(*) FROM user_tables;
```

Debe ser `FUEL_APP`, `FREEPDB1` y **0 tablas** para una instalacion nueva.
Luego, en esa misma consola SQL:

```sql
@/workspace/sql/01_schema.sql
SELECT COUNT(*) AS total_tablas FROM user_tables;
SELECT object_name, object_type FROM user_objects WHERE status = 'INVALID';
@/workspace/sql/02_datos_ficticios.sql
EXIT;
```

Se esperan **38 tablas**, cero objetos invalidos, dos transacciones y una alerta.
Si un script falla, detente: SQL*Plus sale con error. Oracle confirma el DDL de
forma implicita, por lo que un fallo al crear objetos puede dejar un esquema
parcial. No repetir el esquema sobre objetos existentes.

## 5 Consultar y comprobar las mejoras

Abre una conexion nueva:

```bash
docker compose exec oracle sqlplus -L FUEL_APP@//localhost:1521/FREEPDB1
```

Dentro de SQL*Plus:

```sql
@/workspace/sql/03_consultas_prueba.sql
@/workspace/sql/04_pruebas_integridad.sql
SELECT * FROM v_balance_tanque;
SELECT * FROM v_conciliacion_tanque;
EXIT;
```

Las pruebas deben terminar con `TOTAL: ... comprobaciones correctas.` y sin
errores. Comprueban valores invalidos, coherencia de combustible/precio/surtidor,
subtipos, identidades y conciliacion. Revierten sus registros de prueba. Las
identidades consumidas dejan saltos normales; las pruebas pueden repetirse.

Para el tanque 1 se esperan: inicial 1000, recibido 500, vendido 30, ajuste -2,
saldo teorico **1468** y diferencia fisica **0**. La carga `OBSERVADA` de 55 litros
no se descuenta: esta version solo considera `APROBADA` como venta contabilizada.
El equipo debe confirmar esa interpretacion de estados antes del uso final.

## 6 Conexion grafica

En DBeaver o SQL Developer: host `127.0.0.1`, puerto `1522`, nombre de servicio
`FREEPDB1`, usuario `FUEL_APP` y su clave. Dentro del contenedor se utiliza el
puerto `1521`. Esta configuracion solo publica Oracle en el propio equipo.

## 7 Detener e iniciar conservando datos

```bash
docker compose stop oracle
docker compose start oracle
docker compose ps
```

No recrees el usuario ni vuelvas a cargar los scripts tras un reinicio. Comprueba:

```sql
SELECT COUNT(*) FROM user_tables;
SELECT COUNT(*) FROM transaccion;
SELECT COUNT(*) FROM alerta;
```

Deben conservarse 38, 2 y 1. El volumen no sustituye un respaldo. No ejecutar
`docker compose down -v`. La migracion de datos del contenedor comunitario,
backups/restauracion, acceso Cloud y seguridad avanzada son tareas posteriores.

## Reglas para desarrollo

- `combustible.origen` indica procedencia; `DESCONOCIDO` no afirma nacionalidad.
  Es un atributo de catalogo; si la procedencia cambia por entrega se debera
  modelar por lote/recepcion. `vehiculo_combustible.origen_instalacion` indica
  si el equipo es de fabrica o convertido. Se retiro `combustible.capacidad_lt`.
- Precios canonicos en Bs: `precio_bs` es obligatorio y el detalle conserva la
  tarifa y el precio exacto mediante FK compuesta. `precio_usd` es informativo;
  esta version no hace conversion monetaria automatica. Para cambiar precio,
  crear una nueva version; no reescribir los precios referenciados.
- Tanques, recepciones, mediciones y ajustes usan la unidad del combustible.
  No sumar litros con m3. Los ajustes pueden ser positivos o negativos, pero
  nunca cero. Una medicion puede ser cero. Las distancias dentro del mismo
  municipio pueden ser cero; entre municipios distintos deben ser positivas.
- El trigger completa el combustible y la referencia al subtipo de una
  transaccion. Insertar transaccion y subtipo en **la misma transaccion SQL**;
  hacer `COMMIT` solo al terminar ambos. Las FK diferidas impiden confirmar
  una transaccion sin su subtipo. No usar autocommit entre esos pasos.
- Cada ID simple admite generacion automatica al omitirlo o pasar NULL.
  Las identidades comienzan en 1.000.000 para separar los ejemplos manuales.
  Reservar IDs explicitos inferiores a ese valor; las importaciones con IDs
  mayores requieren sincronizar la identidad. Los subtipos reutilizan el ID
  de la transaccion y las claves compuestas no generan un ID independiente.
- Se agregaron indices que cubren prefijos de FK; su rendimiento debe medirse
  con la carga final y los planes de ejecucion, no inferirse del numero de indices.
- La conciliacion compara a la fecha de la ultima medicion; el saldo operativo
  incluye todos los movimientos registrados desde el inicio del tanque.
  Son reportes de control; no hay bloqueo automatico por existencias negativas.
