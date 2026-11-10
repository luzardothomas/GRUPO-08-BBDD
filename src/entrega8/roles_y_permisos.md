# Entrega 8 — Roles y permisos

Roles de seguridad de la base `mundial_2026`, creados por `2_entrega8_roles.sql` y probados por
`5_entrega8_test_usuarios.sql`. El criterio es el **principio del mínimo privilegio**: cada usuario recibe
sólo los permisos que su función requiere, y nada más.

## Reglas comunes a todos los roles

- Los permisos se otorgan al **rol**, nunca al usuario. Cada usuario pertenece a un solo rol.
- Sólo se otorga `EXECUTE` sobre los SP que el usuario llama directamente, **SP por SP** (no sobre el esquema entero).
- **Nadie accede a las tablas**: cada rol tiene `DENY SELECT, INSERT, UPDATE, DELETE` sobre los siete esquemas
  (`torneo`, `plantel`, `evento`, `arbitraje`, `publicidad`, `importacion` y `seguridad`). Los datos se leen y se
  modifican sólo a través de los SP, por encadenamiento de propiedad.
- Los SP auxiliares (`_validar`, utilidades de `importacion` y de `seguridad`), las funciones y las vistas no
  reciben permiso: los usan los SP internamente.
- **Nadie tiene permiso sobre la clave de cifrado**, ni siquiera el administrador. Los datos cifrados se ven sólo
  con los SP de consulta que corresponden a cada rol.
- Ningún rol pertenece a roles fijos (`db_owner`, `db_datareader`, `sysadmin`...). Crear usuarios y asignar roles es
  tarea del DBA, no de estos roles.

## Los roles

| Rol | Quién es | Qué puede hacer | Datos cifrados que ve |
|---|---|---|---|
| `rol_administrador` | Comité Organizador | Ejecutar todos los SP de alta, baja, modificación, lógica de negocio, reportes, consultas e importación (archivos CSV, JSON, XML, scraping y APIs) de los cinco módulos (109 SP); para importar tiene además `EXECUTE ANY EXTERNAL ENDPOINT` en la base y `ADMINISTER BULK OPERATIONS` en el servidor | Todos: motivos de convocatoria, ficha e informes de árbitros, contacto de anunciantes |
| `rol_comite_arbitral` | Comité arbitral | Dar de alta, modificar y borrar árbitros e idiomas; designar los árbitros de cada partido (incluido el VAR); cargar, modificar y borrar informes arbitrales; consultar fichas e informes; ver el reporte de designaciones (16 SP) | Fecha de nacimiento de los árbitros; contenido y sanción de los informes |
| `rol_planillero` | Oficial de partido en la sede | Cargar la formación, los goles, las tarjetas, los cambios y el resultado de un partido; ver los reportes de goleadores, tarjetas, resultados y plantillas (9 SP y el tipo `plantel.tt_formacion_jugador`) | — |
| `rol_var` | Árbitro de VAR | Anular o corregir goles; corregir o anular tarjetas; registrar una tarjeta que no se vio en cancha; cargar el informe de la revisión; ver los reportes de partido y de designaciones (11 SP) | — |
| `rol_gestor_publicidad` | Área comercial | Dar de alta, modificar y borrar anunciantes, campañas, países de interés, piezas y espacios; asignar y facturar los espacios de un partido; consultar anunciantes; ver los reportes de ocupación y de prime time (20 SP) | Contacto de los anunciantes |
| `rol_consulta` | Prensa o público | Ver los siete reportes de la Entrega 7 (7 SP) | — |

**Planillero y VAR** separan funciones: el planillero carga el partido y el VAR corrige lo que revisa. Los dos
registran tarjetas, porque una roja puede salir de la cancha o de la revisión del VAR.

## Cuadro de permisos

✅ = el rol puede ejecutar esa operación. Lo que no está marcado, no lo puede hacer: el motor devuelve el error 229
(permiso denegado).

| Operación | Admin | Comité arbitral | Planillero | VAR | Publicidad | Consulta |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| ABM de sedes, países, confederaciones, selecciones, partidos y parámetros | ✅ | | | | | |
| ABM de personas, jugadores, convocatorias y cuerpo técnico; reemplazo de convocado | ✅ | | | | | |
| `cargar_formacion` (y el tipo `plantel.tt_formacion_jugador`) | ✅ | | ✅ | | | |
| `registrar_gol`, `registrar_sustitucion`, `registrar_resultado` | ✅ | | ✅ | | | |
| `registrar_tarjeta` | ✅ | | ✅ | ✅ | | |
| `gol_modificar`, `gol_eliminar`, `tarjeta_modificar`, `tarjeta_eliminar` | ✅ | | | ✅ | | |
| Criterios de suspensión y demás ABM de eventos | ✅ | | | | | |
| ABM de árbitros e idiomas, `designar_arbitros`, ABM de designaciones | ✅ | ✅ | | | | |
| `informe_arbitral_insertar` | ✅ | ✅ | | ✅ | | |
| `informe_arbitral_modificar`, `informe_arbitral_eliminar` | ✅ | ✅ | | | | |
| `consultar_arbitro`, `consultar_informes` (datos cifrados) | ✅ | ✅ | | | | |
| `consultar_convocatoria` (datos cifrados) | ✅ | | | | | |
| ABM de publicidad, `asignar_espacios_partido`, `facturar_espacios_partido` | ✅ | | | | ✅ | |
| `consultar_anunciante` (datos cifrados) | ✅ | | | | ✅ | |
| Reportes de goleadores, tarjetas, resultados y plantillas | ✅ | | ✅ | ✅ | | ✅ |
| Reporte de designaciones arbitrales | ✅ | ✅ | | ✅ | | ✅ |
| Reportes de ocupación publicitaria y matriz de prime time | ✅ | | | | ✅ | ✅ |
| Importaciones y APIs (9 SP) y `EXECUTE ANY EXTERNAL ENDPOINT` | ✅ | | | | | |
| `ADMINISTER BULK OPERATIONS` (permiso de servidor, en su inicio de sesión) | ✅ | | | | | |

## Casos especiales

| Caso | Por qué no alcanza con `EXECUTE` sobre el SP | Cómo se resolvió |
|---|---|---|
| `publicidad.reporte_matriz_prime_time` | Arma la consulta con SQL dinámico, y ahí el motor revisa los permisos sobre las tablas | `2_entrega8_roles.sql` modifica el SP para que se ejecute como su dueño (`WITH EXECUTE AS OWNER`) |
| `plantel.cargar_formacion` | Recibe un parámetro de tipo tabla | Permiso `EXECUTE` sobre el tipo `plantel.tt_formacion_jugador` |
| Importaciones | Usan `BULK INSERT`, `OPENROWSET` y la API REST | `EXECUTE ANY EXTERNAL ENDPOINT` y `ADMINISTER BULK OPERATIONS` sólo para el administrador |
| SP que cifran o descifran | Abrir la clave exige permiso sobre ella | Lo hacen dos utilidades que se ejecutan como su dueño; los roles no tienen permiso sobre la clave |

## Usuarios de prueba

`3_entrega8_usuarios.sql` crea un usuario por rol: `usr_administrador`, `usr_comite_arbitral`, `usr_planillero`,
`usr_var`, `usr_gestor_publicidad` y `usr_consulta`. Se crean con las directivas de contraseña
activas y deben cambiar la contraseña en el primer ingreso.

## Cómo verificarlo

- `SELECT * FROM seguridad.vw_cuadro_permisos;` muestra el cuadro tal como está cargado en la base.
- `SELECT * FROM seguridad.vw_permisos_otorgados;` muestra lo que el motor tiene otorgado y denegado a cada rol.
- `5_entrega8_test_usuarios.sql` simula el ingreso de cada usuario, de mayor a menor privilegio: muestra todo lo que
  puede hacer, después intenta lo mismo que hizo el usuario anterior (error 229), y al final compara a los seis en
  un cuadro y verifica que los permisos efectivos de cada uno sean exactamente los del cuadro (0 diferencias).
