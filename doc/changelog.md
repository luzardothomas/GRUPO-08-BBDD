# Changelog

En este documento se va a documentar todos los cambios realizados al modelo a partir de las revisiones que haga el cliente.
Al principio siempre va a estar la fecha más actual, y en la misma está la observación del cliente y la solución que se utilizó para resolver el problema.

---

## [13-11-2026]

### Documentación de las políticas de backup (Entrega 8)

#### Observación del cliente

El cliente indicó que tiene que haber un documento con formato
pdf en el cuál se detalle la estrategía adoptada para los backups.

#### Solución adoptada

Se agregó `doc/politica_backup.pdf`, un documento de 10 páginas que define la política sin incluir código, porque el TP solo pide definirla y documentarla. Establece:

- **Objetivos:** pérdida máxima de datos (RPO) de 5 minutos durante la ventana de partidos y de 15 minutos fuera de ella; tiempo máximo de recuperación (RTO) de 30 minutos y de 2 horas respectivamente.
- **Respaldos:** backup del log de transacciones cada 5 o 15 minutos según la ventana. Cuando termina el último partido del día se hace un último backup del log y un diferencial, que pasa a ser un full los domingos. Cada respaldo se verifica con `VERIFYONLY`.
- **Resguardo y seguridad:** copias con la regla 3-2-1, backups cifrados con AES_256 mediante certificado y resguardo de la clave en un lugar separado.
- **Restauración:** procedimiento paso a paso, incluida la restauración a un punto en el tiempo (`STOPAT`) y el error 4330 que aparece después, además de la verificación y las reglas de uso.

Las decisiones quedaron registradas en `domain/entrega8.md`.

### Mapa físico para ver la asistencia de los estadios (Entrega 9)

#### Observación del cliente

El cliente indicó que tiene que haber un mapa físico para poder
observar los datos en el Power BI.

#### Solución adoptada

Se agregaron las columnas `latitud` y `longitud` a `torneo.sede` (`1_entrega9_sede_coordenadas.sql`) y se expusieron en `bi.vw_sedes`. El dashboard se reorganizó en tres páginas, todas en español:

- **goles:** goles por equipo (los 16 con más goles), promedio de goles por partido en cada fase y suma total de goles por tipo.
- **asistencia:** mapa de burbujas por sede, con zoom automático y un color por país; asistencia total por sede con los mismos colores que el mapa; partidos jugados en cada estadio; y asistencia del público por fecha.
- **ingresos:** ingresos publicitarios facturados y estimados por sede.

Los números van dentro de las barras, centrados y grandes, con punto como separador de miles, y los ejes muestran números completos en lugar de abreviaturas como "1.0M". `GUIA.md` describe las tres páginas.

### Goles, asistencia y pauta en los partidos importados (Entrega 6)

#### Observación del cliente

El cliente indicó que no tiene sentido que la final y el tercer puesto figuren sin goles, y que los datos del dashboard tienen que salir de la importación y no de datos programados.

#### Solución adoptada

Los goles reales ya venían en `worldcup.json`; lo que mostraba ceros eran los datos programados de la carga de la Entrega 7, donde la final y el tercer puesto quedaban sin jugar. Al importar el archivo real aparecieron los goles (la final tiene 1 de promedio y el tercer puesto 10), pero la asistencia y los ingresos quedaban en cero porque el archivo no trae público ni pauta.

Se agregó `importacion.cerrar_partido` en `1_entrega6_importacion.sql`, que `torneo.importar_fixture` usa para cerrar cada partido importado:

- Asigna los espacios publicitarios, solo si ya hay piezas de campañas vigentes ese día.
- Estima la asistencia entre el 88 % y el 99 % de la capacidad de la sede, con la misma regla de la carga de la Entrega 7.
- Registra el resultado con `torneo.registrar_resultado`.
- Factura la pauta exhibida, salvo en las semifinales, que quedan pendientes de facturar.

No se modificó ningún archivo de `imports/`. Con esto la importación deja 104 partidos con asistencia total de 6.378.006 y 416 espacios publicitarios, 408 de ellos facturados, y el test de la Entrega 6 sigue en 25 OK y 0 FALLO.

## [6-11-2026]

### Tablas temporales en la importación (Entrega 6)

#### Observación del cliente

El cliente indicó que el script de importación (`1_entrega6_importacion.sql`) no usaba tablas temporales para importar como sí lo hacía el de APIs (`2_entrega6_apis.sql`), que es la forma más eficiente de resolverlo, y que esas tablas tienen que dejar de existir cuando la importación termina.

#### Solución adoptada

Se tomó como modelo `torneo.consultar_api_banco_mundial`, que crea sus tablas temporales con `CREATE TABLE` y numera las filas con una clave primaria (`#datos`). Los importadores ya volcaban el archivo a tablas temporales, pero las armaban con `SELECT ... INTO`. Esas tablas quedaban sin índice, y cada vuelta del `WHILE` recorría la tabla entera para encontrar su fila.

En `1_entrega6_importacion.sql` se aplicó el mismo patrón a los siete importadores (`teams.csv`, `players.csv`, `worldcup.json`, `tarifas_publicidad.xml` y los tres JSON del scraping):

- Cada tabla temporal se crea con `CREATE TABLE` explícito y se carga con `INSERT INTO ... SELECT`. Las tablas que recorre el `WHILE` tienen la fila como clave primaria (`fila INT PRIMARY KEY`), así que cada fila se busca directamente por esa clave.
- Las columnas de texto se declaran con `COLLATE DATABASE_DEFAULT`, como en el archivo de APIs, para no tener conflictos de intercalación con las tablas del modelo.
- Al terminar, cada SP borra sus tablas temporales con `DROP TABLE`. Si el lote se rechaza antes, SQL Server las borra al salir del SP.
- En el tarifario, la tabla con los países de interés de la campaña se crea una sola vez y se vacía en cada pieza. Antes se creaba y se borraba dentro de la transacción de cada pieza.
- En planteles, la columna `formato_ok` se declara al crear la tabla, en lugar de agregarla después con `ALTER TABLE`.
- `importacion.archivo_leer_texto`, que lee los archivos JSON, también borra su tabla temporal (`#contenido`) al terminar.

En `2_entrega6_apis.sql` se agregó el mismo `DROP TABLE` al terminar de usar las tablas temporales: `#respuesta` y `#datos` en Banco Mundial, y `#cotizaciones` en Frankfurter.

### Reiniciar los ids crecientes en la Entrega 5

#### Observación del cliente

El cliente sugirió que los ids una vez que se resetean tienen que volver a empezar desde el inicio como cuando es creado el campo e inicializado por primera vez.

#### Solución adoptada

Al script de limpieza de las pruebas (`6_entrega5_test_limpieza.sql`) se le agregó, al final, el reinicio de los contadores `IDENTITY`. Primero se borran los datos de prueba, de las tablas hijas a las tablas padre. Después se recorre, con un `WHILE`, la lista de las 22 tablas que limpia el script. Para cada una:

- Se busca su columna `IDENTITY` en `sys.identity_columns`.
- Se calcula el mayor id que queda después de la limpieza, o 0 si la tabla quedó vacía. Como el nombre de la tabla y de la columna cambian en cada vuelta, la consulta se arma con `sp_executesql`.
- Se reinicia el contador en ese valor con `DBCC CHECKIDENT (tabla, RESEED, valor)`.

Así, el próximo alta de una tabla vacía vuelve a recibir el id 1, como cuando la tabla se creó. Si la tabla conserva datos que no son de prueba, el próximo alta recibe el id siguiente al último que quedó, sin dejar el hueco que dejaban los ids de prueba borrados.

No se reinician las tablas sin columna `IDENTITY` (`plantel.formacion_jugador`, `publicidad.campania_pais_interes` y `arbitraje.arbitro_idioma`) ni `torneo.parametro`, que el script no limpia.

## [23-10-2026]

### ABM Fallidos y validaciones en sus SPs

El cliente señaló que los SPs tienen que corregirse sus validaciones, además hay que utilizar caminos incorrectos para mostrar el correcto funcionamiento de los SPs.

#### Solución adoptada

Se procedió a revisar todos y cada uno de los SPs para corregir las validaciones y se eligió dividir en dos archivos .sql las pruebas, uno para mostrar el camino correcto y otro que muestre los fallos según el error que proporcione el input que se haya insertado.

## [02-10-2026]

### 1. Bucles de relaciones entre entidades

#### Observación del cliente

El cliente indicó que el modelo tenía relaciones que formaban bucles: una selección juega un partido (de local o de visitante) y ese partido tiene formaciones, pero la selección también estaba relacionada directamente con la formación. Al poder llegar al mismo dato por dos caminos distintos, el modelo permitía registrar información contradictoria, como una formación de una selección que no juega ese partido. Lo mismo ocurría con los goles, las sustituciones y las tarjetas, que se relacionaban a la vez con el partido, con la selección y con el jugador.

#### Solución adoptada

Se eliminaron las relaciones redundantes, dejando un único camino para llegar a cada dato:

- **Formación**: ya no se relaciona con la selección. Se agregó el atributo **condicion**, que indica si corresponde al equipo `local` o al `visitante` del partido; la selección se obtiene a partir del partido.
- **Sustitución** y **Gol**: ya no se relacionan directamente con el partido, la selección ni el jugador. Pasan a relacionarse con el jugador dentro de la formación de ese partido (**Formación Jugador**), de donde se obtienen el partido y la selección. Un gol en contra se registra en la formación de su autor y cuenta para la selección rival.
- **Tarjeta**: ya no se relaciona con la selección, que se obtiene a partir de la persona que la recibe. Mantiene su relación con el partido porque el cuerpo técnico no forma parte de la formación.

Se eligió esta alternativa, en lugar de conservar ambas relaciones y validar su coincidencia en cada carga, para que la inconsistencia no pueda existir en el modelo. Además, queda garantizado que quien convierte, asiste, entra o sale en un partido figura en la formación de ese partido.

Los bucles restantes se conservaron porque cada camino representa un dato distinto: por ejemplo, el partido en el que se muestra una tarjeta y el partido que se pierde por la suspensión, o el país de la sede y el país de la selección.

---

## [25-09-2026]

### 1. Sanciones al cuerpo técnico

#### Observación del cliente

El cliente indicó que los integrantes del cuerpo técnico también tienen la posibilidad de llegar a recibir algún tipo de sanción, y por lo tanto ser suspendidos.

#### Solución adoptada

Se incorporó la entidad **Persona**, que agrupa a jugadores e integrantes del cuerpo técnico bajo un mismo identificador. Las sanciones pasan a asignarse a una persona, independientemente de su rol.
Se eligió esta alternativa, en lugar de agregar a la tarjeta una segunda referencia opcional al cuerpo técnico, para que cada tarjeta tenga siempre un único destinatario obligatorio y la acumulación de amarillas se calcule de la misma forma para todos.

### 2. Tiempo del partido en que se muestra una tarjeta

#### Observación del cliente

El cliente indicó que con el minuto de la tarjeta no se podía determinar en qué tiempo del partido fue mostrada: si en el primer tiempo o su tiempo adicional, en el segundo tiempo o su tiempo adicional, o en alguno de los dos tiempos de 15 minutos del alargue o sus respectivos tiempos adicionales. También debía contemplarse que se puedan mostrar tarjetas durante la tanda de penales.

#### Solución adoptada

Se agregó a la entidad **Tarjeta** el atributo **periodo**, obligatorio, que indica en qué tiempo del partido se mostró la tarjeta. Solo admite los siguientes valores:

| Valor | Tiempo del partido |
|---|---|
| `PT` | Primer tiempo |
| `adicional_PT` | Tiempo adicional del primer tiempo |
| `ST` | Segundo tiempo |
| `adicional_ST` | Tiempo adicional del segundo tiempo |
| `alargue_1` | Primer tiempo del alargue |
| `adicional_alargue_1` | Tiempo adicional del primer tiempo del alargue |
| `alargue_2` | Segundo tiempo del alargue |
| `adicional_alargue_2` | Tiempo adicional del segundo tiempo del alargue |
| `penales` | Tanda de penales |

El minuto se conserva y se interpreta junto con el período, lo que permite distinguir por ejemplo, una tarjeta en el minuto 45 del primer tiempo de otra en el tiempo adicional de ese mismo tiempo.
