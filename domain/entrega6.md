# Análisis — Entrega 6 (Procesos de Importación)

## Qué pide el enunciado

- Importar información masiva **mediante Stored Procedures**, reutilizando los SP de ABM de la Entrega 5 (no
  reimplementar el alta/baja dentro del proceso de importación).
- Procesar los archivos **tal cual se proveen** (CSV, XML, Excel) — sin transformarlos con herramientas externas
  antes de importar, salvo lo obtenido por scraping.
- Lógica de **upsert** (insertar si es nuevo, actualizar si existe), sin necesariamente usar `MERGE`, evitando
  duplicados.
- Si el archivo trae montos en otra moneda, la conversión se resuelve en T-SQL dentro del SP (puede apoyarse en
  otro SP o en una API).
- Manejo robusto de errores: debe poder importar los registros válidos y **reportar** los inválidos sin abortar
  todo el lote (importación parcial).
- El **nombre del archivo** debe ser un parámetro del módulo de importación.
- Durante la defensa, deberán poder **descargar o scrapear en vivo** un archivo/página e importarlo en el momento.

## Enfoque conceptual (motor-agnóstico) antes de la implementación T-SQL

El patrón de importación masiva es el mismo en cualquier RDBMS y conviene documentarlo así, aunque la
implementación final use mecanismos propios de SQL Server (`BULK INSERT`, `OPENROWSET`, `OPENXML`):

1. **Staging**: los datos crudos del archivo se cargan primero en una tabla temporal/de staging con tipos laxos
   (mayormente `VARCHAR`), sin aplicar todavía las reglas de negocio. Esto separa el problema de "leer el archivo"
   del problema de "validar e insertar en el modelo de negocio", que es exactamente el rol de los SP de la
   Entrega 5.
2. **Validación fila a fila (o por lote) contra el staging**: se identifican las filas que no cumplen los
   `CHECK`/reglas de negocio y se separan en una tabla o resultado de errores, sin frenar el procesamiento del
   resto — esto es lo que exige la "importación parcial".
3. **Upsert desde staging hacia destino**: por cada fila válida, se determina si la clave de negocio (no
   necesariamente la PK interna) ya existe (`EXISTS` sobre una clave natural — p. ej. código FIFA del árbitro, o
   combinación selección+jugador) y se dirige a `UPDATE` o `INSERT`, delegando en los SP de ABM de la Entrega 5
   para no duplicar lógica de validación.
4. **Trazabilidad de origen**: cada fila importada debería quedar asociada al dataset/archivo de origen y a la
   fecha de importación, para poder auditar reimportaciones del mismo dataset sin generar duplicados (requisito
   explícito de "evitar duplicados en importaciones reiteradas").

## Patrón de upsert sin `MERGE`

El enunciado aclara que no es necesario usar `MERGE` (de hecho, `MERGE` tiene *edge cases* de concurrencia
conocidos en SQL Server, así que evitarlo es razonable). El patrón recomendado es la forma clásica ANSI-compatible
de upsert, resoluble con dos sentencias:

```sql
IF EXISTS (SELECT 1 FROM arbitro WHERE nombre = @nombre AND apellido = @apellido AND pais_id = @pais_id)
BEGIN
    EXEC arbitro_actualizar @arbitro_id = ..., @categoria = @categoria, ...;
END
ELSE
BEGIN
    EXEC arbitro_insertar @nombre = @nombre, @apellido = @apellido, @pais_id = @pais_id, @categoria = @categoria;
END
```

Este patrón (`EXISTS` + rama condicional) es portable a cualquier motor con soporte de procedimientos (el estándar
SQL/PSM lo contempla igual); solo cambia la sintaxis de control de flujo.

## Manejo de errores

- Requisito explícito: **usar `THROW`**, no `RAISERROR` heredado. Cada SP de importación debe envolver el
  procesamiento de cada fila (o lote) en `TRY...CATCH`, capturar el error con `ERROR_MESSAGE()`/`ERROR_NUMBER()`
  y registrarlo en una tabla de errores de importación (fila de origen, motivo, timestamp) en lugar de detener el
  proceso completo.
- Distinguir dos niveles de error:
  - **Error de formato** (fila del CSV/XML mal formada, columna faltante): se detecta al parsear el staging,
    antes de invocar los SP de negocio.
  - **Error de regla de negocio** (dorsal duplicado, fechas inconsistentes): se detecta porque el SP de ABM de la
    Entrega 5 lanza el `THROW` agrupado; el SP de importación debe capturarlo y continuar con la siguiente fila.

## Transformación de moneda

Si el dataset importado (p. ej. tarifas publicitarias de un anunciante extranjero) trae montos en otra moneda, la
conversión debe resolverse **dentro del SP**, en T-SQL, pudiendo apoyarse en:
- Un SP auxiliar de conversión que consulte una tabla de tipos de cambio previamente cargada (por ejemplo, vía la
  API de tipo de cambio mencionada en el punto I del enunciado — Frankfurter u otra sin necesidad de clave).
- Documentar claramente en el informe si la tabla de tipo de cambio se actualiza por importación separada o si el
  SP de conversión llama a un componente externo (en SQL Server, típicamente un SP que a su vez invoca un
  ensamblado o servicio externo estaría limitado por la prohibición de CLR de la Entrega 5; **para esta entrega
  no rige esa restricción**, ya que el enunciado explícitamente permite apoyarse en "otro SP, una API, etc." para
  las conversiones de moneda). Conviene, de todos modos, que la tabla de tipo de cambio se alimente por un proceso
  de importación propio (batch) en vez de hacer la llamada HTTP en cada fila, por una cuestión de performance y de
  mantener el corazón del SP en T-SQL puro.

## Datasets y APIs a elegir (recordatorio de cobertura)

Del listado del enunciado, conviene fijar temprano (y documentarlo con sus límites de uso — rate limit, necesidad
de clave):
- Un dataset CSV (ej. `github.com/jfjelstul/worldcup` o `datahub.io/football/worldcup`).
- Un dataset que requiera **scraping** (ej. Wikipedia "List of FIFA World Cup referees", o la sección de sedes de
  Wikipedia del torneo) — documentar la técnica (parsing de HTML, selectores usados) y la página de origen.
- Al menos dos APIs (ej. Frankfurter para tipo de cambio + Banco Mundial `NY.GDP.PCAP.CD` para PBI per cápita, que
  alimenta directamente `pais.pbi_per_capita` del modelo ya existente).

La obtención de estos datos (llamado HTTP, parsing de HTML) necesariamente ocurre **fuera** de T-SQL puro (script
de PowerShell, Python o similar que deposite el archivo/CSV intermedio), pero la carga a la base — el upsert en
sí — debe hacerse por SP, cumpliendo la restricción de "todo en el motor SQL Server" que aplica a la lógica de
persistencia, no a la obtención del archivo.

## Requisito de defensa en vivo

Como en el coloquio deberán scrapear/descargar un archivo en el momento, conviene que el proceso de importación
esté parametrizado por **ruta/nombre de archivo** (tal como exige el enunciado) y no por contenido hardcodeado,
para poder ejecutarlo con un archivo nuevo sin modificar el SP.
