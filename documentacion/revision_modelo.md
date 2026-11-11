# Revisión del modelo de datos

## Proyecto

Sistema Nacional de Control y Monitoreo de Combustible.

## Responsable de la revisión

Rogelio José Cortez Ramírez.

## Objetivo

Revisar el modelo entidad-relación y su implementación en Oracle, verificando
las tablas, claves primarias, claves foráneas, restricciones, índices y
relaciones necesarias para registrar operaciones de combustible y detectar
posibles irregularidades.

## Estado actual

El modelo fue desplegado en Oracle Free mediante Docker. La ejecución del
archivo `01_schema.sql` creó correctamente 35 tablas.

Las siguientes comprobaciones fueron realizadas:

- Oracle se encuentra en estado `healthy`.
- Se crearon 35 tablas.
- No existen objetos con estado inválido.
- Las claves primarias y foráneas fueron creadas correctamente.
- El almacenamiento de Oracle utiliza persistencia mediante Docker.
- El esquema de trabajo corresponde al usuario `FUEL_APP`.

## Funcionamiento general

El sistema registra personas, vehículos, estaciones de servicio, surtidores,
combustibles, precios y transacciones.

Cada carga vehicular se relaciona con una persona, un vehículo, una estación,
un surtidor y un operador. El sistema también contempla registros del RUAT,
beneficios de subvención, permisos para compras en bidón, reglas de control y
alertas.

Las reglas pueden utilizar datos como la cantidad cargada, frecuencia de
cargas, capacidad del tanque y distancia entre municipios. Cuando una
operación presenta un comportamiento sospechoso, se genera una alerta para
que sea revisada por un auditor.

Una alerta representa un indicio y no una confirmación automática de
contrabando.

## Aspectos correctos del modelo

1. El modelo conserva el historial de propietarios mediante `registro_ruat`.
2. La tabla `registro_beneficio` permite registrar la vigencia de la
   subvención.
3. Las tablas `transaccion`, `carga_vehicular` y `compra_bidon` separan los
   diferentes tipos de venta.
4. Las reglas son configurables mediante `tipo_regla`, `tipo_periodo` y
   `regla`.
5. La tabla `alerta` permite revisar casos sospechosos sin eliminar las
   transacciones originales.
6. Los precios conservan fechas de vigencia.
7. La tabla `auditoria` permite registrar cambios sobre información crítica.
8. Existen índices para búsquedas frecuentes de transacciones y alertas.

## Mejoras propuestas

### 1. Revisar atributos repetidos de combustible

La tabla `combustible` contiene los atributos `capacidad_lt` y `origen`.
Estos atributos también aparecen en `vehiculo_combustible`.

La capacidad no es una característica general de la gasolina, diésel o GNV,
sino del depósito utilizado por un vehículo. Se recomienda mantener estos
atributos solamente en `vehiculo_combustible`.

Esta modificación debe aprobarse con el grupo antes de aplicarse.

### 2. Hacer obligatoria la transacción del detalle

En `detalle_transaccion`, la columna `id_transaccion` permite valores nulos.
Un detalle no debería existir sin una transacción principal.

Se propone:

```sql
id_transaccion NUMBER NOT NULL

3. Permitir cargas sin beneficio
En carga_vehicular, la columna id_beneficio es obligatoria. Esto impide
registrar vehículos que no reciben subvención y pagan una tarifa
internacional.

Se recomienda permitir que id_beneficio sea nulo cuando no se utilice
subvención.
4. Añadir restricciones para cantidades
Se recomienda impedir valores negativos o iguales a cero en:
- Cantidad de combustible.
- Capacidad del tanque.
- Precio.
- Número de bidones.
- Capacidad de los bidones.
- Distancias.
- Tiempo de viaje.
Ejemplo: CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0)

5. Evitar contradicciones en el detalle
detalle_transaccion almacena simultáneamente:
- Combustible.
- Tarifa.
- Precio.
- Precio unitario.
El registro de precio_combustible ya determina un combustible y una tarifa.
Podrían registrarse identificadores que no correspondan entre sí.

Se recomienda simplificar la relación o implementar una validación que
garantice la coincidencia de estos datos.

6. Añadir código oficial de estación
Actualmente las estaciones se identifican principalmente por su nombre.

Se propone agregar un código oficial único, por ejemplo:
codigo_anh VARCHAR2(30) UNIQUE

Esto evitaría depender del nombre comercial de la estación.

7. Incorporar control físico de tanques
La tabla recepcion_combustible registra el combustible recibido, pero no
existe una tabla que represente los tanques físicos de almacenamiento.

Se propone evaluar las tablas:
- tanque
- medicion_tanque
- ajuste_inventario
Esto permitiría comparar el combustible recibido, vendido y almacenado.

8. Revisar índices de claves foráneas
Existen índices para algunas consultas importantes, pero no para todas las
claves foráneas.

Se recomienda analizar los campos utilizados frecuentemente en consultas,
como:
- id_estacion
- id_vehiculo
- id_combustible
- id_usuario
- id_regla
No se recomienda crear índices en todas las columnas sin analizar primero
las consultas.

9. Generación de identificadores
Los identificadores deben introducirse manualmente en la versión actual.

Se podría utilizar IDENTITY o secuencias de Oracle para reducir errores y
evitar colisiones de identificadores. Esta modificación no es obligatoria
para las pruebas actuales.

Recomendación
No se recomienda modificar inmediatamente todas las tablas. Primero deben
aprobarse las mejoras con el grupo y comprobar cuáles son necesarias para el
alcance académico del proyecto.

Para las pruebas iniciales se utilizará el esquema actual. Los datos
ficticios y consultas permitirán comprobar si las relaciones existentes
funcionan correctamente.
Conclusión
El modelo actual puede ejecutarse correctamente en Oracle y contiene las
entidades principales para registrar ventas de combustible, vehículos,
personas, estaciones y reglas de control.

Las principales oportunidades de mejora se relacionan con la normalización
de atributos, restricciones de integridad, control de inventario y
validación de operaciones. Estas propuestas permitirían reducir datos
inconsistentes y mejorar la detección de operaciones sospechosas.



### Decisión provisional para las pruebas

Debido a que no se pudo confirmar inmediatamente cuál versión es la
definitiva, las pruebas se realizarán utilizando el esquema disponible en
la rama `prueba`.

Los campos `capacidad_lt` y `origen` de `combustible` recibirán valores
técnicos provisionales para satisfacer las restricciones `NOT NULL`. Estos
valores no serán utilizados en las consultas ni considerados información
válida del negocio.

La ubicación definitiva de estos atributos deberá ser confirmada por el
grupo antes de integrar cambios al modelo.

## Pruebas realizadas

### Creación del esquema

El archivo `01_schema.sql` fue ejecutado en Oracle Free mediante Docker.

Resultados:

- 35 tablas creadas.
- Cero objetos inválidos.
- Contenedor Oracle en estado saludable.

### Datos ficticios

Se registró un caso ficticio compuesto por:

- Un propietario.
- Un operador.
- Un vehículo.
- Un registro RUAT.
- Un beneficio de subvención.
- Una estación y un surtidor.
- Una carga normal de 30 litros.
- Una carga observada de 55 litros.
- Una alerta por superar la capacidad declarada de 50 litros.

### Consultas

Las consultas permitieron comprobar:

- Historial de cargas por vehículo.
- Total consumido y pagado.
- Ventas agrupadas por estación.
- Cargas superiores a la capacidad.
- Alertas pendientes.
- Propietarios con beneficio vigente.

### Pruebas de integridad

Se comprobó que Oracle:

1. Rechaza placas duplicadas mediante una restricción única.
2. Rechaza vehículos inexistentes mediante una clave foránea.
3. Actualmente permite cantidades negativas en `detalle_transaccion`.

La tercera prueba confirma la necesidad de implementar:

```sql
CONSTRAINT ck_detalle_cantidad
CHECK (cantidad > 0)
