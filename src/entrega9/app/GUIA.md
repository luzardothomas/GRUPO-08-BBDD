# Entrega 9 - Aplicación (JavaScript)

Esta carpeta tiene la aplicación de la Entrega 9: ABM de anunciantes, importación de archivos (Entrega 6) y reportes XML
(Entrega 7), sobre la base `mundial_2026`. El dashboard de Power BI está en [../power_bi/](../power_bi/GUIA.md) y tiene su
propia guía: son dos entregables independientes que no se llaman entre sí; lo único que comparten es la base.

| Entregable | Tecnología elegida | Usuario SQL | Qué usa de la base |
|---|---|---|---|
| Dashboard de BI | **Power BI Desktop** (carpeta `power_bi/`) | `usr_bi` (rol `bi_lector`) | Las cuatro vistas del esquema `bi` (sólo lectura) |
| Aplicación de ABM (esta carpeta) | **JavaScript: Node.js + Express** (servidor) y HTML + JavaScript (navegador) | `usr_gestor_publicidad` y `usr_administrador` (Entrega 8) | Los procedimientos almacenados de las Entregas 5 a 8 |

## Preparar la base

La aplicación lee la base `mundial_2026`, así que primero hay que crearla. Hace falta SQL Server
(Express alcanza) y SSMS. Conectarse como administrador del servidor y ejecutar, en este orden:

1. `entrega5/1_entrega5_db_definition.sql`, `2_entrega5_sp_ABM.sql`, `3_entrega5_sp_logica_negocio.sql`
2. `entrega6/1_entrega6_importacion.sql`, `2_entrega6_apis.sql` (la segunda consulta cotizaciones por internet)
3. `entrega7/1_entrega7_carga_datos.sql` (datos de ejemplo) y `2_entrega7_reportes.sql`
4. `entrega8/1_entrega8_cifrado.sql`, `2_entrega8_roles.sql`, `3_entrega8_usuarios.sql`
5. `entrega9/1_entrega9_sede_coordenadas.sql`, `2_entrega9_vistas_bi.sql`

Resultado: la base con los datos de ejemplo de la Entrega 7, las cuatro vistas del esquema `bi` y los usuarios. La aplicación pide además un último
script (`preparar_usuario.sql`, en esta carpeta; ver el paso 2 del tutorial).

La aplicación necesita que SQL Server acepte **autenticación mixta** (Windows y SQL Server): en SSMS, clic derecho
sobre el servidor > *Propiedades > Seguridad > Modo de autenticación de SQL Server y Windows*, y reiniciar el servicio
*SQL Server (SQLEXPRESS)*.

## Tutorial: configurar y abrir la aplicación

**Necesita:** la base preparada (sección anterior) y Node.js 20 o superior (`node -v` para comprobarlo; incluye
`npm`).

**1. Habilitar la conexión desde Node.js (una sola vez).** Node se conecta por TCP/IP y SQL Server Express lo trae
deshabilitado:

1. Abrir *SQL Server Configuration Manager > Configuración de red de SQL Server > Protocolos de SQLEXPRESS*.
2. Poner **TCP/IP** en *Habilitado*.
3. En *TCP/IP > Propiedades > Direcciones IP*, bajar hasta **IPAll**: dejar vacío "Puertos dinámicos TCP" y escribir
   `1433` en "Puerto TCP".
4. Reiniciar el servicio *SQL Server (SQLEXPRESS)* (desde el mismo Configuration Manager o desde `services.msc`).

**2. Definir las contraseñas de los usuarios de la aplicación.** Los inicios de sesión de la Entrega 8 nacen con
`MUST_CHANGE` y no pueden conectarse hasta que se les define la contraseña: abrir `preparar_usuario.sql` (en esta carpeta) en
SSMS, cambiar las dos contraseñas por las definitivas y ejecutarlo.

**3. Configurar la aplicación.** Desde esta carpeta (`entrega9/app`):

```powershell
copy config.ejemplo.json config.local.json
notepad config.local.json
```

Completar `DB_PASSWORD` (contraseña de `usr_gestor_publicidad`) y `DB_ADMIN_PASSWORD` (contraseña de
`usr_administrador`) con las del paso anterior. Si SQL Server está en otra máquina o usa otro puerto, ajustar
`DB_SERVER` y `DB_PORT`. `config.local.json` no se versiona. Todas las variables están en
[Variables de configuración](#variables-de-configuración).

**4. Instalar y arrancar:**

```powershell
npm install      # sólo la primera vez
npm start
```

Debe aparecer `Aplicación en http://localhost:3000`. Abrir esa dirección en el navegador. Para detenerla: `Ctrl+C` en la
consola.

**5. Qué probar:**

- *Anunciantes (ABM)*: crear, modificar y eliminar. Un anunciante con campañas no se puede eliminar (la baja se rechaza
  por una regla de la Entrega 5); uno recién creado, sí.
- *Importación y reportes*: elegir el formato, el dato a importar y un archivo de `imports/` (para la importación
  parcial, `imports/con_errores/`). Con *Goleadores del torneo* y *Plantillas de las selecciones* se ejecuta el reporte,
  se muestra el XML y queda guardado en `reportes/`.

La importación lee el archivo desde el disco de la máquina donde corre SQL Server, así que la aplicación tiene que
ejecutarse en esa misma máquina (o apuntar `IMPORT_DIR` a una carpeta compartida que el servicio de SQL Server pueda
leer).

**Problemas frecuentes**

| Síntoma | Causa y solución |
|---|---|
| `Failed to connect ... in 15000ms` | TCP/IP deshabilitado o sin puerto 1433: repetir el paso 1 y reiniciar el servicio |
| `Login failed for user ...` (estado 58 en el log de SQL Server) | El servidor sólo acepta autenticación de Windows: habilitar la autenticación mixta |
| `Login failed for user ...` (otro estado) | Contraseña incorrecta en `config.local.json`, o falta ejecutar `preparar_usuario.sql` |
| La importación dice que no puede leer el archivo | Archivo del formato equivocado (por ejemplo, un CSV de jugadores elegido como estadísticas de equipos) o carpeta `IMPORT_DIR` sin permiso de lectura para el servicio de SQL Server |

---

## Cómo está hecha

El enunciado pide una aplicación simple, en el lenguaje que elija el grupo, con ABM sobre al menos una tabla, y permite
una pantalla de importación de archivos que use la lógica de la Entrega 6 y muestre algún reporte de la Entrega 7
(guardando como mínimo el XML). La aplicación cubre las dos cosas. Se eligió:

- **Servidor: Node.js + Express**, con el paquete `mssql` para hablar con SQL Server. Hace falta un servidor porque
  un navegador no puede conectarse directo a SQL Server ni dejarle archivos para importar.
- **Interfaz: HTML, CSS y JavaScript sin framework**, servida por el mismo servidor, con dos pestañas.

La aplicación no tiene lógica de negocio ni validaciones propias. Cada operación ejecuta un procedimiento almacenado
y, si éste rechaza el pedido (`THROW`), muestra su mensaje tal cual. Usa dos usuarios de la Entrega 8, cada uno con su
rol. No usa `sa`, y si se intenta algo fuera del rol, el motor lo rechaza.

### Pestaña "Anunciantes (ABM)"

ABM sobre `publicidad.anunciante` (pocas dependencias, sirve para mostrar alta, modificación y baja en vivo; su
contacto se guarda cifrado y la aplicación lo ve descifrado porque el rol tiene permiso). Usuario: `usr_gestor_publicidad`
(`rol_gestor_publicidad`, área comercial).

| Operación | Procedimiento |
|---|---|
| Listar (con contacto descifrado) | `publicidad.consultar_anunciante` |
| Alta | `publicidad.anunciante_insertar` |
| Modificación | `publicidad.anunciante_modificar` |
| Baja | `publicidad.anunciante_eliminar` |

### Pestaña "Importación y reportes"

Usuario: `usr_administrador` (`rol_administrador`), el único con permiso para importar (Entrega 8).

- **Importación de un archivo.** Se elige el formato del archivo (JSON, CSV o XML), después qué datos importar (la lista se filtra por el formato) y se sube el archivo; entonces se ejecuta el procedimiento de importación de la
  Entrega 6. La pantalla muestra el resumen del lote que devuelve el procedimiento (leídos, insertados, actualizados, sin
  cambios, rechazados y estado: completo, parcial o rechazado). Las filas con error se rechazan y el resto se importa; el
  detalle de cada fila rechazada queda en `importacion.error`. Para probar la importación parcial sirven los archivos de
  `imports/con_errores/`.

  | Datos | Procedimiento | Formato |
  |---|---|---|
  | Sedes | `torneo.importar_sedes` | JSON |
  | Selecciones | `torneo.importar_selecciones` | JSON |
  | Planteles | `plantel.importar_planteles` | JSON |
  | Fixture | `torneo.importar_fixture` | JSON |
  | Estadísticas de equipos | `torneo.importar_estadisticas_equipos_kaggle_2026` | CSV |
  | Estadísticas de jugadores | `plantel.importar_estadisticas_jugadores_kaggle_2026` | CSV |
  | Tarifas publicitarias | `publicidad.importar_tarifas` | XML |

  Los procedimientos leen el archivo desde el disco de SQL Server (`BULK` / `OPENROWSET`), no desde el navegador. Por eso
  la aplicación guarda el archivo subido en una carpeta de la máquina de SQL Server (`IMPORT_DIR`), le pasa la ruta al
  procedimiento y lo borra al terminar. En Windows la carpeta por defecto es `C:\Users\Public\mundial_importaciones`
  (la crea la aplicación); el servicio de SQL Server tiene que poder leerla.
- **Reportes XML (Entrega 7).** Ejecuta `evento.reporte_goleadores` o `plantel.reporte_plantillas`, muestra el XML y lo
  guarda en un archivo en `reportes/` (enlace para abrirlo o descargarlo).

### Variables de configuración

La configuración sale de `config.local.json` o de variables de entorno (tienen prioridad), todas opcionales salvo las
contraseñas:

| Variable | Valor por defecto |
|---|---|
| `DB_SERVER` | `localhost` |
| `DB_INSTANCE` | (vacío; para SQL Server Express, `SQLEXPRESS`) |
| `DB_PORT` | `1433` (no se usa si hay `DB_INSTANCE`) |
| `DB_NAME` | `mundial_2026` |
| `DB_USER` / `DB_PASSWORD` | `usr_gestor_publicidad` / (obligatoria) |
| `DB_ADMIN_USER` / `DB_ADMIN_PASSWORD` | `usr_administrador` / (necesaria para la segunda pestaña) |
| `IMPORT_DIR` | `C:\Users\Public\mundial_importaciones` en Windows |
| `IMPORT_SQL_DIR` | igual a `IMPORT_DIR` (si SQL Server ve esa carpeta con otra ruta) |
| `REPORT_DIR` | `app/reportes` |
| `PORT` | `3000` |

Alternativa al puerto 1433: iniciar el servicio SQL Server Browser y usar `DB_INSTANCE` = `SQLEXPRESS` en lugar de `DB_PORT`.
Las contraseñas no se guardan en el repositorio.
