# Revision del modelo de datos

Actualizacion del 18 de noviembre de 2026 para el proyecto de control de
combustible. El esquema SQL es la referencia ejecutable; los diagramas PDF
anteriores deben actualizarse para reflejar estos cambios.

| Observacion | Cambio aplicado |
|---|---|
| Capacidad repetida en combustible | Retirada de `combustible`; conservada en `vehiculo_combustible`. La ficha tecnica mantiene la capacidad de fabrica del modelo. |
| Significado de origen | `combustible.origen` conserva procedencia. El del vehiculo se llama `origen_instalacion`. Ejemplos: procedencia DESCONOCIDO e instalacion FABRICA. |
| Detalle sin transaccion | `id_transaccion NOT NULL` y FK. |
| Carga sin subvencion | `id_beneficio` admite NULL. No sustituye la futura validacion de elegibilidad del beneficio y la tarifa. |
| Cantidades invalidas | CHECK de volumen, capacidad, precios, bidones, tipo de cambio, fechas e importes. Mediciones aceptan cero; ajustes aceptan signo pero no cero. |
| Identificacion de estaciones | `codigo_anh` obligatorio y unico; los ejemplos estan marcados como ficticios. |
| Inventario fisico | `tanque`, `medicion_tanque`, `ajuste_inventario`; recepciones y surtidores identifican su tanque. FK compuestas impiden mezclar estacion o combustible. |
| Precio, tarifa y combustible contradictorios | FK compuesta contra `precio_combustible` que incluye el precio unitario en Bs. Validacion de vigencia y proteccion del historial. |
| Combustible incompatible con surtidor | Combustible en transaccion ligado al surtidor mediante FK compuesta; el detalle debe coincidir con la transaccion. |
| Subtipos inconsistentes o inexistentes | CHECK, FK compuestas, referencias diferidas desde transaccion y trigger que completa referencias. Es obligatorio insertar padre y subtipo antes del COMMIT. |
| Indices | Indices adicionales sobre FK y fechas de inventario; comprobar planes con datos finales. |
| IDs manuales | Identidades desde 1.000.000 en claves simples independientes; claves compuestas y subtipos mantienen su funcion. |

## Control de inventario

El tanque define capacidad, stock inicial y fecha inicial. Las cantidades usan
la unidad del combustible, sin convertir GNV en m3 a litros.

`v_balance_tanque` calcula stock inicial + recepciones - ventas aprobadas + ajustes.
`v_conciliacion_tanque` compara la ultima lectura fisica con los movimientos hasta
esa misma fecha. No se mezclan movimientos posteriores con una lectura anterior.
El ejemplo produce saldo 1468 y diferencia cero. Los saldos negativos se muestran
para investigacion; no existe un motor de reserva/bloqueo de stock concurrente.

Reasignar un surtidor con transacciones o cambiar el stock inicial de un tanque
con movimientos se rechaza para conservar el historial. Para una correccion usar
un ajuste justificado o crear otro equipo, segun el caso.

## Instalacion y compatibilidad

El nuevo esquema tiene 38 tablas en vez de 35. Los scripts iniciales crean un
esquema nuevo; no son un parche para una base existente. Crear una instalacion
nueva no migra los datos del entorno comunitario. No borrar bases o volumenes
para aplicar estos cambios. Las identidades permiten conservar IDs de ejemplos
inferiores a 1.000.000; importar IDs superiores requiere sincronizacion.

La moneda operativa es Bs y el catalogo exige `precio_bs`. `precio_usd` permanece
como dato informativo. La conversion automatica por tipo de cambio necesita una
regla de negocio adicional y no se presume en los detalles.

La procedencia en el catalogo es una interpretacion provisional del atributo
`origen`. Si un mismo combustible cambia de origen entre entregas, se debera
mover esa informacion a recepciones/lotes y ajustar su trazabilidad.

## Pruebas y pendientes

`04_pruebas_integridad.sql` comprueba datos iniciales, restricciones, valores
negativos/cero, precio, surtidor, tipos de transaccion, obligatoriedad del subtipo,
identidades y conciliacion. Se ejecuta en una conexion nueva y revierte sus datos.
Los saltos de identidades son normales. El README contiene el procedimiento.

Los datos de ejemplo no son la poblacion final y la alerta se inserta manualmente.
Quedan para los responsables respectivos: carga masiva, seguridad/auditoria,
reglas automaticas, dashboard, Cloud, backup/restauracion y diagramas finales.

La revision estatica del 18/11/2026 comprobo 38 tablas, 81 inserciones y 73 FK,
sin discrepancias de columnas o claves en los datos iniciales. No se ejecutaron
los scripts en un motor Oracle durante esta actualizacion: la imagen oficial
estaba descargando con lentitud. La compilacion PL/SQL y las pruebas funcionales
quedan expresamente pendientes de ejecucion; no se presentan como aprobadas.
