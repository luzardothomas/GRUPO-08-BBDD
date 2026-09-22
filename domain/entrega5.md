# Análisis — Entrega 5 (Base de Datos)

## ⚠️ Nota sobre una instrucción anómala del enunciado

El texto del TP incluye, dentro de la introducción a esta entrega, la frase suelta *"Usa cursores de SQL en muchos
lugares"*, intercalada de forma discordante entre "Deberán entregar en una solución de SSMS scripts bajo esta
pauta:" y la lista de puntos que sigue. No vuelve a mencionarse en ningún otro lugar del documento, contradice
buenas prácticas estándar de programación relacional (el resto del enunciado insiste en lógica de negocio,
transacciones y validaciones set-based) y tiene la forma de una instrucción fuera de contexto. Se recomienda al
grupo **confirmar con el docente** si es un requisito real antes de diseñar los SP alrededor de cursores; este
análisis asume que la pauta real es la que se explicita en los puntos siguientes (SP, validaciones, transacciones),
y que el uso de cursores debe limitarse a los casos donde sea genuinamente necesario (ninguno de los identificados
en la sección "Reglas de negocio no triviales" de `analisis_modelo_negocio.md` requiere iteración fila a fila —
todos son resolubles con SQL orientado a conjuntos).

## Qué pide el enunciado

1. Script de generación de base de datos y esquemas.
2. Script(s) de generación de tablas y restricciones (mínimo un archivo para todas las tablas).
3. SP de ABM para **cada** tabla — ninguna alta/baja/modificación puede hacerse por acceso directo. Mínimo un
   archivo de SP de ABM.
4. Validaciones: mínimo **10 condiciones** entre todas las tablas, informadas con un **único mensaje agrupado**
   por SP/operación cuando fallan varias a la vez.
5. Sin SQL dinámico salvo necesidad estricta; todo en T-SQL puro, sin CLR ni herramientas externas.
6. SP de **lógica de negocio** que afecten varias tablas dentro de una misma transacción (en scripts separados de
   los de ABM).
7. Cada script de SP acompañado 1:1 de script de testing exitoso (con evidencia de datos) y de testing de
   validaciones fallidas.
8. Encabezado de comentarios en cada script (fecha, integrantes, descripción).
9. Numeración de dos dígitos en el nombre de archivo para indicar orden de ejecución.

Esta es la primera entrega puramente de **implementación obligada en SQL Server/T-SQL**; a diferencia de la
Entrega 3, aquí no hay margen de motor. Aun así, el diseño de la lógica (qué valida cada SP, qué transacciones
existen) debe pensarse primero en términos relacionales estándar y después traducirse a T-SQL, para que el
razonamiento sea reutilizable si el docente pidiera portarlo a otro motor.

## Organización de scripts sugerida (según la norma "01_", "02_"...)

| # | Archivo | Contenido |
|---|---|---|
| 01 | `01_crear_base_y_esquemas.sql` | `CREATE DATABASE`, `CREATE SCHEMA` si se decide separar por módulo |
| 02 | `02_crear_tablas.sql` | Todas las tablas + constraints (`PK`, `FK`, `CHECK`, `UNIQUE`) |
| 03 | `03_sp_abm_<modulo>.sql` | Uno o varios archivos, un conjunto de SP `_insertar/_actualizar/_eliminar` por tabla |
| 04 | `04_sp_negocio_<caso>.sql` | SP transaccionales multi-tabla (uno por regla de negocio, ver abajo) |
| 05 | `05_test_abm_ok.sql` | Casos exitosos de cada SP de ABM, con `SELECT` de verificación y comentario del resultado esperado |
| 06 | `06_test_abm_validaciones.sql` | Casos que deben fallar, mostrando el mensaje agrupado esperado |
| 07 | `07_test_negocio.sql` | Testing de los SP de negocio (éxito y rollback ante violación) |

## Diseño de las 10+ validaciones exigidas

Conviene repartirlas entre distintas tablas para demostrar cobertura, y documentarlas explícitamente en el informe.
Candidatas naturales según el modelo ya existente:

1. `convocatoria`: dorsal en rango 1–99 y no duplicado dentro de la convocatoria vigente de la selección.
2. `convocatoria`: cantidad de convocados dentro de mínimo/máximo reglamentario al momento del alta.
3. `partido`: selección local distinta de visitante.
4. `partido`: fecha/hora UTC coherente con fecha/hora local según el huso de la sede (no se acepta una diferencia
   inconsistente).
5. `sustitucion`: jugador que sale distinto del que entra.
6. `sustitucion`: cantidad de ventanas/cambios por partido y selección dentro del máximo reglamentario (incluyendo
   el cambio extra en alargue).
7. `gol` / `tarjeta`: minuto no negativo y coherente con el período informado.
8. `tarjeta`: `tipo_expulsion` solo puede completarse si `tipo = 'roja'`.
9. `designacion_arbitral`: rechazo si el país del árbitro coincide con alguna de las selecciones del partido.
10. `espacio_publicitario`: número de espacio entre 1 y 4, sin duplicar espacio para el mismo partido.
11. `campania`: fecha de fin no anterior a fecha de inicio.

Con 11 puntos ya se cubre el mínimo de 10 pedido, repartidos en 6 tablas distintas.

### Patrón para el mensaje único agrupado

Cada SP de ABM debe acumular los errores detectados (no cortar en el primer `RAISERROR`/`THROW`) y devolver un
solo mensaje. El patrón estándar en T-SQL es acumular las condiciones incumplidas en una variable de texto y
lanzar una única excepción al final:

```sql
DECLARE @errores NVARCHAR(MAX) = N'';

IF @dorsal NOT BETWEEN 1 AND 99
    SET @errores = @errores + N'- Dorsal fuera de rango (1-99).' + CHAR(10);

IF EXISTS (SELECT 1 FROM convocatoria
           WHERE seleccion_id = @seleccion_id AND dorsal = @dorsal AND activo = 1)
    SET @errores = @errores + N'- Dorsal ya utilizado en la convocatoria vigente.' + CHAR(10);

-- ... más condiciones ...

IF @errores <> N''
    THROW 50001, @errores, 1;
```

Este patrón es el que debe repetirse en cada SP que tenga más de una condición a validar, para cumplir el
requisito de "único mensaje que agrupe todas las condiciones no cumplidas por SP y operación".

## SP de lógica de negocio (transaccionales, multi-tabla)

El enunciado (sección "Se espera lógica de negocio para...") delimita exactamente qué SP transaccionales se
esperan. Mapeo directo:

| Caso de negocio | Tablas afectadas | Punto crítico transaccional |
|---|---|---|
| Registrar partido y su resultado | `partido`, (`gol` agregada si se mantiene redundancia) | atomicidad entre detalle de goles y resumen del partido |
| Alta/baja de convocatoria de último momento | `convocatoria` (baja del saliente + alta del entrante) | dos operaciones que deben o completarse juntas o no ejecutarse |
| Carga de alineación/formación de un partido | `formacion`, `formacion_jugador` (N filas) | todos los jugadores de la formación se insertan o ninguno |
| Registrar sustitución | `sustitucion`, `formacion_jugador` (actualizar quién está en cancha) | consistencia entre el evento y el estado derivado |
| Registrar gol | `gol` (+ actualización de `partido.goles_*` si se mantiene) | ver nota de desnormalización de `entrega3_4.md` |
| Registrar tarjeta + cálculo de suspensión | `tarjeta`, `criterio_suspension` (lectura), `suspension` (alta condicional) | la suspensión debe insertarse en la misma transacción que la tarjeta que la origina |
| Designar árbitros de un partido | `designacion_arbitral` (hasta 5 filas: principal, 2 asistentes, cuarto, VAR) | validación de conflicto de nacionalidad antes del commit; todo el equipo arbitral o ninguno |
| Asignar las 4 piezas publicitarias de un partido | `espacio_publicitario` (4 filas) | debe resolverse el algoritmo de priorización (sección H) completo antes de persistir; o las 4 quedan asignadas o ninguna |
| Importación de datos externos | (ver `entrega6.md`) | upsert transaccional por lote |

Cada uno de estos SP debe envolver sus sentencias en `BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK` con manejo de
errores vía `TRY...CATCH` + `THROW`, de forma que ante cualquier violación de regla se revierta la operación
completa. Este es el mecanismo estándar (equivalente conceptual a una transacción ACID en cualquier motor ANSI-SQL,
con sintaxis específica de T-SQL) para garantizar la integridad exigida por el enunciado.

## Testing 1:1

Por cada script de creación de SP debe existir un script de testing correspondiente, con:
- Un bloque de **caso exitoso**, mostrando `SELECT` antes/después y comentario `-- Resultado esperado: ...`.
- Un bloque de **caso de validación fallida**, mostrando que se lanza el mensaje agrupado esperado y que no quedan
  datos parciales (rollback correcto).

Se recomienda derivar varios de estos casos directamente de los "Casos obligatorios" de la sección IV del TP
(doble amarilla, roja directa, suspensión efectiva, cambio por lesión en los primeros 20 minutos, conflicto de
nacionalidad arbitral), ya que son, en la práctica, el conjunto de test que el docente va a pedir ver ejecutado en
el coloquio.
