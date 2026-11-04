# Proyecto_TBD_G5

## Integrantes
- Arrosquipa Arnez Alba Jhessica
- Bustamante Escobar Jhosselin Sthaicy
- Cortez Ramírez Rogelio José

Nota: El archivo pdf debe descargarse para poder visualizarse con mayor calidad

# Oracle Free: monitoreo de combustible

Pasos para iniciar Oracle, crear las tablas y hacer consultas.

## 1. Clonar el repositorio

En una terminal, ve a la carpeta donde quieres guardar el proyecto y ejecuta:

```bash
git clone https://github.com/USUARIO/REPOSITORIO.git
cd REPOSITORIO
code .
```

Cambia la URL por la dirección real del repositorio. Si `code .` no funciona, abre VS Code y selecciona la carpeta clonada con **File > Open Folder**.

## 2. Configurar las contraseñas

En la terminal integrada de VS Code, confirma que estás dentro de la carpeta del proyecto y ejecuta:

```bash
cp .env.example .env
code .env
```

En `.env`, cambia los valores de contraseña y guarda el archivo:

```text
ORACLE_PASSWORD=pon_una_contrasena_administrativa
APP_USER=FUEL_APP
APP_USER_PASSWORD=pon_una_contrasena_para_el_usuario
DB_PORT=1521
```

`ORACLE_PASSWORD` es para el usuario administrador `SYSTEM`. `APP_USER_PASSWORD` es para `FUEL_APP`, el usuario que tendrá las tablas. Escribe tus propias contraseñas, sin comillas ni espacios alrededor de `=`. No compartas `.env`.

## 3. Iniciar Oracle

Desde la carpeta del proyecto, ejecuta:

```bash
docker compose up -d
docker compose ps
```

La primera descarga puede tardar. Antes de continuar, espera hasta que el estado del contenedor muestre `healthy`. Si necesitas revisar el inicio:

```bash
docker compose logs -f oracle
```

Pulsa `Ctrl+C` para salir de los mensajes; Oracle seguirá ejecutándose.

## 4. Crear las tablas

Cuando Oracle esté saludable, ejecuta este comando una sola vez para crear las tablas del modelo:

```bash
docker compose exec -T oracle bash -lc 'sqlplus -s "$APP_USER/$APP_USER_PASSWORD@//localhost:1521/FREEPDB1" @/workspace/sql/01_schema.sql'
```

El script `sql/01_schema.sql` crea las tablas y relaciones. No inserta datos de ejemplo.

## 5. Consultar las tablas

Conéctate al usuario de la aplicación:

```bash
docker compose exec oracle bash -lc 'sqlplus "$APP_USER/$APP_USER_PASSWORD@//localhost:1521/FREEPDB1"'
```

Cuando aparezca `SQL>`, puedes listar las tablas y contar cuántas se crearon:

```sql
SELECT table_name FROM user_tables ORDER BY table_name;
SELECT COUNT(*) AS total_tablas FROM user_tables;
```

El script contiene 35 tablas, así que el total esperado es `35`. Para ver las claves primarias, foráneas y únicas:

```sql
SELECT table_name, constraint_name, constraint_type, status
FROM user_constraints
WHERE constraint_type IN ('P', 'R', 'U')
ORDER BY table_name, constraint_type;
```

Para salir de SQL*Plus:

```sql
EXIT;
```

Si SQL*Plus pide `Enter user-name:`, escribe `FUEL_APP`. En `Enter password:`, escribe el valor de `APP_USER_PASSWORD` en `.env`; no verás los caracteres mientras los escribes.
