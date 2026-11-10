# Análisis — Entrega 8 (Seguridad y Respaldo)

Estado: **cifrado y roles implementados y probados** en `src/entrega8/`, en SQL Server 2025 para Linux y en
SQL Server 2025 Express sobre Windows. Falta el **documento de la política de backup**.

## Qué pide el enunciado y dónde está resuelto

| # | Requisito | Dónde |
|---|---|---|
| 1 | Cifrar datos sensibles (por ejemplo, datos personales de jugadores, cuerpos técnicos y árbitros), como script de modificación sobre tablas, SP y consultas existentes | `1_entrega8_cifrado.sql`. Ver "Cifrado" |
| 2 | Las pruebas de entregas anteriores pueden dejar de pasar después del cifrado | Ver "Impacto en las pruebas de entregas anteriores": falla 1 de 115 en la Entrega 5 |
| 3 | Al menos tres roles con permisos granulares | Seis roles (`2_entrega8_roles.sql`) |
| 4 | Cuadro con los permisos de cada rol | Sección "Cuadro de permisos"; generado desde la base con `seguridad.vw_cuadro_permisos` |
| 5 | Un script de test por usuario, que muestre lo que puede y lo que no | `5_entrega8_test_usuarios.sql`: una parte por usuario (inicio de sesión, lo que puede, lo que no puede); cada lote se puede ejecutar solo después del Lote 0 |
| 6 | Política de respaldo (RPO), considerando el pico de escritura en días de partido | Pendiente: documento en `doc/` |
| 7 | Cifrado y roles implementados con SP | Cifrado: `seguridad.cifrar_columna`, `seguridad.cifrar_texto`, `seguridad.fn_descifrar`. Roles: `seguridad.crear_roles`, `seguridad.crear_usuario`... |

## Organización de los scripts

| Archivo | Orden | Contenido |
|---|---|---|
| `1_entrega8_cifrado.sql` | 1° | Claves, utilidades de cifrado, columnas cifradas (`ALTER TABLE`), los diez SP afectados (`ALTER PROCEDURE`) y cuatro SP de consulta nuevos |
| `2_entrega8_roles.sql` | 2° | Modificación del reporte con SQL dinámico (`ALTER PROCEDURE`) y esquema `seguridad`: cuadro de permisos, SP de roles y usuarios, control de permisos efectivos y vistas |
| `3_entrega8_usuarios.sql` | 3° | Un usuario de prueba por rol (`usr_<rol>`) |
| `4_entrega8_test_cifrado.sql` | 4° | Test del cifrado (cinco pruebas) |
| `5_entrega8_test_usuarios.sql` | 5° | Test de usuarios y roles: una parte por usuario, de mayor a menor privilegio, y una comparación final |

**Criterio del enunciado:** el cifrado y la seguridad se aplican "como script de modificación sobre los componentes
existentes afectados". No se tocan los scripts que crean los componentes en las Entregas 5 a 7: la Entrega 8 los
modifica una vez creados (`ALTER TABLE`, `ALTER PROCEDURE`, `GRANT`/`DENY` sobre lo que ya existe). Los objetos
nuevos de esta entrega (claves, esquema `seguridad`, SP de consulta, roles y usuarios) sí se crean acá.

Se ejecutan en orden con un login `sysadmin` (el DBA), después de las Entregas 5, 6 y 7 (el cifrado modifica SP de
las tres). Son reejecutables: las columnas ya cifradas no se vuelven a tocar. Si se vuelve a ejecutar un script de
una entrega anterior, pisa las modificaciones: hay que volver a ejecutar la Entrega 8.

## Cifrado

### Qué se cifra

Ley 25.326 (Unidad 6): **datos sensibles** son los que revelan origen racial, opiniones políticas, convicciones
religiosas, afiliación sindical, salud o vida sexual; los demás datos de una persona son **datos personales**.
Criterio: se cifra lo que es sensible o no es público. Lo que FIFA publica (nombre de jugadores, DT y árbitros, fecha
de nacimiento de los jugadores, club, posición) no se cifra: lo usan los reportes y es la clave natural con la que la
Entrega 6 busca a cada jugador.

| Columna | Por qué |
|---|---|
| `plantel.convocatoria.motivo_alta`, `motivo_baja` | Texto libre que registra bajas por lesión: dato de **salud** (sensible) |
| `arbitraje.informe_arbitral.contenido`, `sancion` | Informes y sanciones que recibe un árbitro: información disciplinaria, no pública |
| `arbitraje.arbitro.fecha_nacimiento` | Dato personal que no figura en las fuentes públicas |
| `publicidad.anunciante.contacto` | Dato de contacto de una persona |

Fuera del cifrado: `evento.sustitucion.motivo` ('lesion' es un valor de una lista que se ve en la transmisión, y su
`CHECK` dejaría de funcionar).

### Cómo se implementó (`1_entrega8_cifrado.sql`)

1. **Claves (nuevas):** `MASTER KEY` de la base, certificado `cert_datos_sensibles` y clave simétrica
   `clave_datos_sensibles` (AES_256) protegida por el certificado.
2. **Utilidades (esquema `seguridad`, `WITH EXECUTE AS OWNER`):**
   - `seguridad.cifrar_texto`: abre la clave, cifra con `ENCRYPTBYKEY` y la cierra.
   - `seguridad.fn_descifrar`: descifra con `DECRYPTBYKEYAUTOCERT` (en una función no se admite `OPEN SYMMETRIC KEY`).
   - `seguridad.cifrar_columna`: pasa una columna existente a `VARBINARY` sin perder datos ni el nombre (agrega la
     columna cifrada, cifra lo cargado, borra la plana, la renombra y recrea los `CHECK` que la nombraban, como
     `chk_convocatoria_baja`). Una fecha se cifra como texto `aaaa-mm-dd`.
3. **`ALTER TABLE`:** `seguridad.cifrar_columna` sobre las seis columnas.
4. **`ALTER PROCEDURE` sobre los diez SP afectados**, con el mismo cuerpo y cada cambio marcado `[Entrega 8: cifrado]`:
   - escriben (cifran antes de guardar): `convocatoria_insertar`, `convocatoria_modificar`, `arbitro_insertar`,
     `arbitro_modificar`, `informe_arbitral_insertar`, `informe_arbitral_modificar`, `anunciante_insertar`,
     `anunciante_modificar` (Entrega 5);
   - leen (descifran): `plantel.reemplazar_convocado` (Entrega 5) y `plantel.importar_planteles` (Entrega 6).

   Las validaciones no cambian: trabajan sobre los parámetros, que llegan en claro.
5. **SP de consulta nuevos**, que devuelven el dato descifrado: `plantel.consultar_convocatoria`,
   `arbitraje.consultar_arbitro`, `arbitraje.consultar_informes` y `publicidad.consultar_anunciante`.

### Quién ve el dato en claro

**Nadie tiene permiso sobre la clave ni el certificado**, tampoco el administrador. Sólo las dos utilidades la usan,
como su dueño, y los SP las llaman por encadenamiento de propiedad. Quién ve el dato lo decide el permiso `EXECUTE`
sobre los SP de consulta:

| SP de consulta | Admin | Comité arbitral | Gestor de publicidad | Demás roles |
|---|:-:|:-:|:-:|:-:|
| `plantel.consultar_convocatoria` (motivos de alta y baja) | ✅ | | | |
| `arbitraje.consultar_arbitro` (fecha de nacimiento) | ✅ | ✅ | | |
| `arbitraje.consultar_informes` (contenido y sanción) | ✅ | ✅ | | |
| `publicidad.consultar_anunciante` (contacto) | ✅ | | ✅ | |

El administrador ve todo, pero a través de los SP: con un valor cifrado en la mano no puede descifrarlo (prueba 1.4).
Administrar las claves (rotarlas, respaldarlas) es tarea del DBA.

Decisiones:
- **Sin autenticador** (el tercer y cuarto parámetro de `ENCRYPTBYKEY`, que ata el valor a su fila): copiar un valor
  cifrado de una fila a otra exigiría escribir en las tablas, y ningún rol puede (`DENY`).
- `ENCRYPTBYKEY` cifra hasta 8000 bytes: un informe no puede superarlos (`seguridad.cifrar_texto` lo rechaza).
- La contraseña de la master key del script es de prueba. En producción la carga el DBA y se guarda con el respaldo
  del certificado, separada de los datos.

Cifrado (`ENCRYPTBYKEY`, reversible con la clave) no es lo mismo que hash (`HASHBYTES`, irreversible). Las
contraseñas de los usuarios no se cifran: SQL Server las guarda con hash y salt en `master`, y nadie puede
descifrarlas, ni el administrador ni el DBA.

### Impacto en las pruebas de entregas anteriores

Verificado el 10/11/2026 en el contenedor, con cada base preparada como pide el test de su entrega:

| Test | Antes del cifrado | Después | Diferencia |
|---|---|---|---|
| `7_entrega5_test.sql` (base recién creada) | 115 OK | 114 OK, 1 FALLO | La prueba 1.12.c lee `informe_arbitral.sancion = 'Apercibimiento'` directamente de la tabla; ahora la columna es `VARBINARY`. El SP funciona: lo que cambia es la comparación del test. Es el caso que anticipa el enunciado |
| `3_entrega6_test.sql` | 25 OK | 25 OK | `importar_planteles` se modificó para descifrar el motivo de alta |
| `3_entrega7_test_reportes.sql` (base con la carga de la Entrega 7) | 25 OK | 25 OK | Los reportes no usan las columnas cifradas |

## Roles

### Criterio: principio del mínimo privilegio (Unidad 5)

Cada usuario recibe acceso sólo a los datos y operaciones que su función requiere. Reglas aplicadas:

| Regla de la teoría | Cómo se aplica |
|---|---|
| Permisos a roles, no a usuarios | Los `GRANT` van al rol; cada usuario se agrega con `ALTER ROLE ... ADD MEMBER`, y pertenece a un solo rol |
| El `GRANT` de menor alcance que resuelva la necesidad | `GRANT EXECUTE ON OBJECT::` SP por SP. Un `GRANT` sobre el esquema daría también los `_eliminar` y los SP que se creen después |
| Acceso sólo por SP (encadenamiento de propiedad) | Ningún rol tiene permisos sobre tablas. El SP accede a las tablas porque tiene el mismo dueño (`dbo`) |
| `DENY` tiene prioridad sobre cualquier `GRANT` | `DENY SELECT, INSERT, UPDATE, DELETE` sobre los siete esquemas a todos los roles. El encadenamiento no revisa ese `DENY` (verificado) |
| No usar `db_owner`, `sysadmin` ni roles fijos para resolver permisos | Ningún rol del sistema pertenece a roles fijos de base o de servidor; nada se otorga a `public` |
| `securityadmin` equivale casi a `sysadmin` | Crear inicios de sesión y asignar roles lo hace el DBA con los SP de `seguridad`; `rol_administrador` no puede |
| Directivas de contraseña | Inicios de sesión con `CHECK_POLICY = ON`, `CHECK_EXPIRATION = ON` y `MUST_CHANGE` |
| Las claves de cifrado son críticas | Ningún rol tiene permiso sobre la clave ni el certificado |

Sólo reciben permiso los SP que el usuario llama directamente. Los auxiliares (`_validar`, utilidades de
`importacion` y de `seguridad`), las funciones (`fn_pais_id`, `fn_descifrar`...) y las vistas (`plantel.vw_formacion`...)
los usan los SP por encadenamiento de propiedad.

### Los seis roles

| Rol | Quién es (según el enunciado) | Función |
|---|---|---|
| `rol_administrador` | Comité Organizador | Administra todos los datos con los SP, importa (archivos, scraping y APIs) y ve los datos cifrados con los SP de consulta. No crea usuarios ni modifica la estructura |
| `rol_comite_arbitral` | Comité arbitral (módulo G) | Árbitros, idiomas, designaciones (incluido el VAR) e informes; ve la ficha y los informes de los árbitros |
| `rol_planillero` | Oficial de partido en la sede (módulos C a F) | Carga la formación, los goles, las tarjetas, los cambios y el resultado |
| `rol_var` | Árbitro de VAR | Corrige lo que revisa: anula o corrige goles, corrige o anula tarjetas, agrega una tarjeta que no se vio, y deja el informe |
| `rol_gestor_publicidad` | Área comercial (módulo H) | Anunciantes (con su contacto), campañas, piezas, espacios, asignación y facturación |
| `rol_consulta` | Prensa o público | Sólo los siete reportes de la Entrega 7 |

El VAR del DER (`designacion_arbitral.rol = 'var'`) es la función del árbitro en un partido; `rol_var` es el usuario
que opera el sistema desde la sala de VAR. Planillero y VAR separan funciones: quien carga no puede borrar lo que
cargó, y quien corrige no puede cargar el partido. Los dos registran tarjetas, porque una roja puede salir de la
cancha o de la revisión. `tarjeta_modificar` no cambia el tipo: una amarilla que pasa a roja se registra como
tarjeta nueva.

### Cuadro de permisos

Generado desde `seguridad.vw_cuadro_permisos`. ✅ = puede (`GRANT`). Lo demás no lo puede hacer (error 229).

| Operación | Admin | Comité arbitral | Planillero | VAR | Publicidad | Consulta |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| ABM de sedes, países, confederaciones, selecciones, partidos y parámetros | ✅ | | | | | |
| ABM de personas, jugadores, convocatorias, cuerpo técnico; reemplazo de convocado | ✅ | | | | | |
| `cargar_formacion` (+ `EXECUTE` sobre el tipo `plantel.tt_formacion_jugador`) | ✅ | | ✅ | | | |
| `registrar_gol`, `registrar_sustitucion`, `registrar_resultado` | ✅ | | ✅ | | | |
| `registrar_tarjeta` | ✅ | | ✅ | ✅ | | |
| `gol_modificar`, `gol_eliminar`, `tarjeta_modificar`, `tarjeta_eliminar` | ✅ | | | ✅ | | |
| Criterios de suspensión y demás ABM de eventos | ✅ | | | | | |
| ABM de árbitros e idiomas, `designar_arbitros`, ABM de designaciones | ✅ | ✅ | | | | |
| `informe_arbitral_insertar` | ✅ | ✅ | | ✅ | | |
| `informe_arbitral_modificar`, `informe_arbitral_eliminar` | ✅ | ✅ | | | | |
| `consultar_arbitro`, `consultar_informes` (datos cifrados) | ✅ | ✅ | | | | |
| `consultar_convocatoria` (datos cifrados) | ✅ | | | | | |
| ABM de publicidad, `asignar_espacios_partido`, `facturar_espacios_partido`, `consultar_anunciante` | ✅ | | | | ✅ | |
| Reportes de partido: goleadores, tarjetas, resultados, plantillas | ✅ | | ✅ | ✅ | | ✅ |
| Reporte de designaciones arbitrales | ✅ | ✅ | | ✅ | | ✅ |
| Reportes de publicidad: ocupación y matriz de prime time | ✅ | | | | ✅ | ✅ |
| Importaciones y APIs (9 SP) + `EXECUTE ANY EXTERNAL ENDPOINT` | ✅ | | | | | |
| `ADMINISTER BULK OPERATIONS` (permiso de servidor, al inicio de sesión) | ✅ | | | | | |
| SP auxiliares (`_validar`, `importacion.*`, `seguridad.*`) y permiso sobre la clave | | | | | | |
| Crear roles y usuarios (`seguridad.*`) | Sólo el DBA | | | | | |
| `SELECT`, `INSERT`, `UPDATE`, `DELETE` sobre tablas | `DENY` | `DENY` | `DENY` | `DENY` | `DENY` | `DENY` |

SP ejecutables por rol (prueba n.2 del test): administrador 109, publicidad 20, comité arbitral 16, VAR 11,
planillero 9, consulta 7. Cada rol tiene además 28 `DENY` (cuatro operaciones sobre siete esquemas).

### Casos donde no alcanza con `EXECUTE` sobre el SP (verificados en el motor)

| Caso | Qué pasa | Solución |
|---|---|---|
| SQL dinámico (`publicidad.reporte_matriz_prime_time`) | Con `sp_executesql` se revisan los permisos de quien llama sobre las tablas: error 229 | La sección 0 de `2_entrega8_roles.sql` modifica el SP ya creado (`ALTER PROCEDURE ... WITH EXECUTE AS OWNER`, mismo cuerpo). Es seguro: los valores viajan como parámetros |
| Parámetro de tipo tabla (`plantel.cargar_formacion`) | Hace falta permiso sobre el tipo: error 229 | `GRANT EXECUTE ON TYPE::plantel.tt_formacion_jugador` |
| API REST (`sp_invoke_external_rest_endpoint`) | Es un SP del sistema (otro dueño): no hay encadenamiento | `GRANT EXECUTE ANY EXTERNAL ENDPOINT` sólo al administrador |
| `BULK INSERT` / `OPENROWSET(BULK)` | Permiso de servidor | `GRANT ADMINISTER BULK OPERATIONS` sólo al inicio de sesión del administrador |
| Abrir la clave de cifrado dentro de un SP | El encadenamiento no cubre claves ni certificados: error 15151 | `seguridad.cifrar_texto` y `seguridad.fn_descifrar` con `WITH EXECUTE AS OWNER` |

Se descartó firmar el reporte dinámico con un certificado: el `DENY` sobre el esquema le gana al permiso del
certificado.

**SQL Server para Linux** no admite `ADMINISTER BULK OPERATIONS` ni `bulkadmin` para inicios de sesión que no son
`sysadmin` (documentación de Microsoft, "Server-level roles"): ahí el administrador no puede leer archivos. En Windows,
donde se entrega el TP, sí.

## Testing

Dos scripts con el formato de la Entrega 5: lotes separados por `GO`, cada uno con su título (`PRINT '--- n.m ...'`),
un comentario "Resultado esperado", la evidencia (los `SELECT`) y su registro en `#resultado`; al final, un lote
RESUMEN. Se ejecutan completos, o el Lote 0 y después cada lote por separado. Ningún lote deja cambios en la base.

### `4_entrega8_test_cifrado.sql`

| Prueba | Qué demuestra |
|---|---|
| 1.1 | Las seis columnas sensibles son `VARBINARY` |
| 1.2 | Los datos que ya estaban cargados quedaron cifrados y se descifran (muestra el binario y el texto descifrado) |
| 1.3 | Un alta nueva (con su SP) se guarda cifrada (dentro de una transacción que se deshace) |
| 1.4 | Nadie descifra por fuera de los SP, ni el administrador: `DECRYPTBYKEYAUTOCERT` da NULL, `OPEN SYMMETRIC KEY` el error 15151 y `fn_descifrar` el 229 |
| 1.5 | Cada rol ve el dato en claro sólo con sus SP de consulta; los demás reciben el error 229 |

### `5_entrega8_test_usuarios.sql`

Simula el ingreso de cada usuario (`EXECUTE AS LOGIN`) y muestra, primero, todo lo que puede hacer y, después, lo que
no puede. Los usuarios van de mayor a menor privilegio y cada uno intenta lo mismo que hizo el anterior, que tenía
más permisos: así se ve la diferencia entre roles. Cada intento se informa en la pestaña Mensajes como `PUEDE` o
`NO PUEDE`.

| Parte | Usuario | n.2 Lo que puede hacer | n.3 Lo que no puede hacer |
|---|---|---|---|
| 1 | `usr_administrador` (109 SP) | Alta y baja de una sede, convocatoria con los motivos descifrados, reportes (uno con SQL dinámico), API de cambio e importación de `sedes.json` | Crear usuarios (DBA), SP auxiliares, tablas |
| 2 | `usr_gestor_publicidad` (20 SP) | Alta de un anunciante, su contacto descifrado y su baja; reportes de publicidad; asignación de espacios | Lo que hizo el administrador: alta de sede, convocatoria, reporte de resultados, API; tablas |
| 3 | `usr_comite_arbitral` (16 SP) | Alta de un árbitro con idioma, su fecha de nacimiento descifrada y su baja; reporte de designaciones; designación | Lo que hizo el gestor de publicidad: anunciantes, contacto, reportes y asignación; tablas |
| 4 | `usr_var` (11 SP) | Reportes; anular o corregir goles, corregir o anular tarjetas, registrar una tarjeta, cargar un informe | Lo que hizo el comité arbitral: árbitros, su ficha, designar, borrar informes; tablas |
| 5 | `usr_planillero` (9 SP) | Reportes; cargar formación, gol, tarjeta, cambio y resultado | Lo que hizo el VAR: anular o corregir goles y tarjetas, informes, reporte de designaciones; tablas |
| 6 | `usr_consulta` (7 SP) | Los siete reportes | Lo que hizo el planillero: toda la carga del partido; tablas |

Cada parte empieza con el inicio de sesión (n.1): con qué usuario y en qué rol queda la sesión. Las altas, consultas y
reportes se ejecutan de verdad, y lo que se da de alta se borra en el mismo lote. Los SP que necesitan un partido en
juego se llaman con un partido inexistente: se ejecutan (hay permiso) y los rechaza su validación, sin cambios.

La parte 7 compara a los seis usuarios:

| Prueba | Qué demuestra |
|---|---|
| 7.1 | Cuadro comparativo: 16 operaciones representativas por 6 usuarios, preguntándole al motor con la sesión de cada uno; coincide con el cuadro de permisos |
| 7.2 | `seguridad.comprobar_permisos`: los permisos efectivos de cada usuario sobre todos los SP, tipos y tablas son exactamente los de su rol (0 diferencias, 0 tablas accesibles) |
| 7.3 | Sólo `usr_administrador` tiene `ADMINISTER BULK OPERATIONS` |

Verificado el 10/11/2026 en SQL Server 2025 para Linux (contenedor), con las Entregas 5, 6 y 7 cargadas:
`4_entrega8_test_cifrado.sql` **5 OK, 0 FALLO** y `5_entrega8_test_usuarios.sql` **21 OK, 0 FALLO**. En Linux la
importación de archivos de la prueba 1.2 no se ejecuta (no admite `ADMINISTER BULK OPERATIONS` para logins no
`sysadmin`). Falta correr estos dos scripts en SQL Server 2025 Express sobre Windows.

## Política de backup (RPO) — pendiente

El documento tiene que cubrir (Unidad 5):
- Modelo de recuperación `FULL` (ya configurado en `1_entrega5_db_definition.sql`), necesario para los backups de log.
- **RPO y RTO**, diferenciando días con partido (más escritura: log cada 5 a 15 minutos) y sin partido.
- Completo semanal, diferencial diario y log; respaldo del final del log (tail log) ante una falla.
- Retención y ubicación: regla 3-2-1, fuera del disco de los datos.
- **Respaldo de la master key y del certificado `cert_datos_sensibles`**, separados de los datos: sin ellos los
  datos cifrados son irrecuperables.
- Prueba de restauración periódica con `DBCC CHECKDB` sobre la base restaurada.

## Pendientes

- Escribir el documento de la política de backup.
