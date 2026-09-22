# Análisis general del TP — Sistema de Registro y Gestión del Mundial de Fútbol

## 1. Objeto de estudio

El TP pide modelar y construir, con herramientas de base de datos relacional, el sistema de información de un
Comité Organizador de un Mundial de fútbol. El foco de la cátedra (Bases de Datos Aplicada) es el **diseño y la
implementación relacional**: modelo entidad-relación, normalización, integridad declarativa (constraints),
programabilidad del lado del servidor (procedimientos almacenados, transacciones, vistas) y explotación de datos
(reportes, BI). El dominio de "Mundial de fútbol" es solo el vehículo para aplicar esos conceptos; no hay que
sobre-diseñar la parte deportiva más allá de lo que el enunciado explicita.

Aunque el enunciado exige que la implementación final corra en **MS SQL Server / T-SQL** (Entregas 5 en
adelante), el diseño conceptual y lógico —DER, normalización, definición de claves y restricciones, lógica de
transacciones— debe pensarse en términos de **SQL estándar (ANSI-SQL)**, de modo que sea trasladable a
cualquier motor (PostgreSQL, MySQL, Oracle, etc.). Solo al bajar a la capa de implementación entran las
particularidades de T-SQL (`IDENTITY`, `DATETIMEOFFSET`, `THROW`, `FOR XML`, cursores `T-SQL`, roles y
cifrado propios del motor). Cada documento de entrega distingue explícitamente qué es diseño (motor-agnóstico) y
qué es implementación obligada por el enunciado (SQL Server).

## 2. AS-IS vs TO-BE

El enunciado describe un escenario típico de **integración de silos**: cada sede, selección y comité arbitral
lleva su información en planillas o PDF independientes. El sistema TO-BE debe centralizar y normalizar esos datos
en un único esquema relacional, con trazabilidad completa de cada partido. Esto justifica, desde el punto de vista
académico, por qué el TP insiste tanto en:

- **Formas normales (1FN–3FN)**: los datos de origen (planillas) suelen violar 1FN (campos multivaluados como
  "convocados" o "idiomas del árbitro") y 2FN/3FN (dependencias parciales o transitivas, p. ej. mezclar datos de
  país dentro de la tabla de sede o selección). El ejercicio de normalizar es, en sí mismo, el ejercicio de pasar de
  la planilla al modelo relacional.
- **Procedimientos almacenados como única puerta de entrada a los datos**: refleja el requisito de negocio de que
  toda la lógica de validación (dorsales, cupos de convocatoria, ventanas de cambio, conflictos de nacionalidad
  arbitral, etc.) quede centralizada y no dependa de que cada aplicación cliente la reimplemente.
- **Transacciones multi-tabla**: casi todo evento de partido (un gol, una sustitución, una tarjeta con eventual
  suspensión) afecta a más de una tabla y debe ser atómico.

## 3. Entidades y módulos del dominio

El enunciado organiza el alcance en 9 módulos (A a I) más un módulo de análisis (J). Cada uno se traduce en un
subconjunto de entidades y responsabilidades:

| Módulo | Entidades núcleo | Complejidad relacional destacada |
|---|---|---|
| A. Sedes y Partidos | `sede`, `partido` | UTC vs. hora local, fases del torneo, filtros de fixture |
| B. Selecciones y Convocatoria | `pais`, `confederacion`, `seleccion`, `jugador`, `convocatoria`, `cuerpo_tecnico` | historización de altas/bajas (SCD tipo 2 simplificado) |
| C. Formaciones | `formacion`, `formacion_jugador` | titular/suplente por partido, reconstrucción histórica |
| D. Cambios | `sustitucion` | reglas de máximo de ventanas/cambios, reconstrucción del XI en un minuto dado |
| E. Goles | `gol` | tipos y períodos de juego, exclusión de penales de definición |
| F. Amonestaciones | `tarjeta`, `criterio_suspension`, `suspension` | acumulación parametrizable, cálculo derivado de sanción |
| G. Árbitros | `arbitro`, `arbitro_idioma`, `designacion_arbitral`, `informe_arbitral` | regla de exclusión por nacionalidad, historial |
| H. Publicidad | `anunciante`, `campania`, `pieza_publicitaria`, `espacio_publicitario` | asignación priorizada de 4 espacios, simulación de prime time, historial de facturación |
| I. Importación | (transversal) | upsert, manejo de errores, trazabilidad de origen |

El repositorio ya cuenta con un primer esquema (`doc/db_definition.sql`) que cubre razonablemente estos módulos.
Sirve como base de trabajo para las Entregas 3 y 5, pero conviene revisarlo con esta grilla como checklist de
cobertura antes de avanzar (ver `entrega3_4.md`).

## 4. Reglas de negocio no triviales (a resolver con SQL, no solo con constraints)

Estas son las reglas que exceden lo que una `CHECK` simple puede expresar y que requieren procedimientos
almacenados, triggers o lógica de aplicación —el corazón académico del TP—:

1. **Cupos de convocatoria** (mínimo/máximo de jugadores según reglamento) — validación agregada sobre
   `convocatoria`.
2. **Ventanas y cantidad máxima de cambios por partido**, incluyendo el cambio extra en alargue — validación
   agregada sobre `sustitucion`, condicionada por si el partido tuvo tiempo suplementario.
3. **Acumulación de amarillas y cálculo de suspensión** — regla parametrizable (tabla `criterio_suspension`),
   disparada al insertar una tarjeta, que debe determinar el "próximo partido" de la selección para marcar al
   jugador como no disponible.
4. **Conflicto de nacionalidad arbitral** — impedir (no solo advertir) que el árbitro designado comparta
   país con alguna de las selecciones que disputan el partido; a partir de dieciseisavos, advertencia (no bloqueo)
   si el país del árbitro puede cruzarse en instancias posteriores.
5. **Priorización de 4 piezas publicitarias por partido** — algoritmo de scoring/orden con criterios definidos por
   el grupo (país de las selecciones, PBI per cápita, prime time), documentado y parametrizable.
6. **Simulación de prime time** — conversión de huso horario UTC del partido al huso de cada país mercado,
   determinando si cae en la franja horaria configurada (ej. 19–23h local).
7. **Reconstrucción del XI en cualquier minuto** — se resuelve por consulta (no por tabla nueva): titulares menos
   salidas más entradas de `sustitucion` con `minuto <= X`.

Estas siete reglas son, en la práctica, la columna vertebral de las Entregas 5 a 7 y conviene que el grupo las tenga
identificadas y priorizadas desde ahora, ya que son las que un docente evaluará con más detenimiento en el
coloquio.

## 5. Fuentes de datos externas

El TP pide combinar datos de **al menos 2 datasets en 2 formatos distintos**, **al menos 1 obtenido por scraping**
(no archivo empaquetado) y **al menos 2 APIs**. Conviene planificar esto temprano porque condiciona el diseño de
`pais.pbi_per_capita`, husos horarios, y la tabla de tipo de cambio/feriados que probablemente haya que agregar al
modelo para dar soporte a la Entrega 6 (importación) y al criterio de priorización publicitaria de la Entrega 7. Una
recomendación académica: modelar estas fuentes externas como **tablas de staging** separadas de las tablas de
negocio, y que los SP de importación hagan el `upsert` desde el staging hacia el modelo definitivo — esto es
estándar en cualquier motor y no depende de sintaxis propietaria.

## 6. Norma de nomenclatura (requisito documental transversal)

El enunciado pide definir y documentar una norma de nombres de tablas, SP y variables, aplicable a todo el
proyecto. El esquema actual ya sigue una convención razonable y motor-agnóstica:

- Tablas y columnas en **snake_case**, en español, singular (`sede`, `partido`, `jugador_id`). Los nombres de
  objetos permanecen en español; lo que se configura en inglés es el motor (collation e idioma de instancia).
- Esquemas por módulo del enunciado: `torneo`, `plantel`, `evento`, `arbitraje`, `publicidad`. Además de ordenar
  el modelo, son la unidad sobre la que se otorgan permisos granulares en la Entrega 8.
- Claves primarias: `<tabla>_id`.
- Claves foráneas: mismo nombre que la PK referenciada.
- Constraints con prefijo por tipo: `pk_`, `fk_`, `chk_`, `uq_`, `idx_`.
- Se recomienda extender esta norma a SP (`sp_<modulo>_<accion>`, evitando el prefijo `sp_` de sistema en SQL
  Server si se quiere evitar el overhead de resolución de nombres — mejor `usp_` o `<modulo>_<accion>`) y a
  variables (`@nombre_variable` en T-SQL). Esto debe quedar escrito en el documento de la Entrega 3/4.

## 7. Riesgos y puntos de atención para el grupo

- El TP exige que **todo** el ABM pase por SP (no acceso directo a tabla): esto implica revisar permisos a nivel de
  esquema desde la Entrega 8, pero conviene diseñarlo desde la Entrega 5.
- El criterio de suspensión y el de prime time son **parametrizables**: no hardcodear umbrales en el código de los
  SP, sino en tablas de configuración (`criterio_suspension` ya cumple esto; falta una tabla equivalente para
  prime time si se quiere parametrizar el rango horario por mercado).
- El juego de datos obligatorio (sección IV del TP) incluye casos límite (doble amarilla, roja directa, suspensión
  efectiva, cambio por lesión temprano, empate de prime time en más de 4 mercados, conflicto arbitral, importación
  con errores parciales). Conviene derivar de esta lista los *casos de test* de cada SP desde la Entrega 5, no dejarlo
  para el final.
- Cualquier fragmento del enunciado que parezca fuera de estilo o contradiga buenas prácticas (como la mención a
  "usar cursores en muchos lugares" en la Entrega 5) debería confirmarse con el docente antes de aplicarse
  literalmente, en lugar de darse por válido sin más.

## 8. Relación con el resto de los documentos de análisis

- `entrega3_4.md`: normalización del modelo actual y documento de instalación/configuración.
- `entrega5.md`: script de base, tablas, SP de ABM con validaciones y SP transaccionales de negocio.
- `entrega6.md`: importación masiva con upsert desde archivos y scraping.
- `entrega7.md`: reportes (incluye salida XML y matriz pivot).
- `entrega8.md`: cifrado, roles y política de backup.
- `entrega9.md`: BI, mapa, gráficos y aplicación ABM simple.
