# Base de datos aplicadas Com 02-5600
## Integrantes

- LUZARDO THOMAS GASTON
- EKSZTEIN ROLON JEREMIAS OCTAVIO
- REPRESAS PANOZZO GERÓNIMO
- LARAN JEAN PIERRE

## Orden de ejecución de las entregas:

### Entrega 5 (`src/entrega5/`)
1. `entrega5_db_definition.sql`
2. `entrega5_sp_ABM.sql`
3. `entrega5_sp_logica_negocio.sql`
4. `entrega5_test_exitosos.sql` (sobre la base recién creada)
5. `entrega5_test_fallidos.sql` (sobre la base recién creada: repetir antes los pasos 1 a 3)

Con Docker (carpeta local `sqlserver-docker/`, no versionada): `./sqlserver-docker/entrega5.sh`.

### Entrega 6 (`src/entrega6/`)
0. `python3 src/entrega6/entrega6_scraping.py` (scraping de Wikipedia → `imports/scraping/*.json`)
1. `entrega6_importacion.sql`
2. `entrega6_apis.sql`
3. `entrega6_test.sql`

### Entrega 7 (`src/entrega7/`)
Sobre la base recién creada con los pasos 1 a 3 de la Entrega 5 (sin ejecutar sus tests):
1. `entrega7_carga_datos.sql` (juego de datos de la sección IV, cargado con los SP de la Entrega 5)
2. `entrega7_reportes.sql`
3. `entrega7_test_reportes.sql` (todas las pruebas deben imprimir `OK`)
