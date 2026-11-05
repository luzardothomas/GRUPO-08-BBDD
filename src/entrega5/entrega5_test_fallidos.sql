-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 5: Base de Datos - LOTES DE PRUEBA: CASOS FALLIDOS (VALIDACIONES)
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Entradas inválidas para los SP de entrega5_sp_ABM.sql y entrega5_sp_logica_negocio.sql. Cada prueba
--   ejecuta el SP con esa entrada y muestra en Mensajes el mensaje con el que el SP la rechaza (todas las
--   condiciones incumplidas juntas, una por línea). Los casos válidos están en entrega5_test_exitosos.sql.
--     PARTE 1: SP de ABM sobre un escenario encadenado (mismos datos que exitosos, cargados por SP).
--     PARTE 2: SP de lógica de negocio sobre el mismo escenario, incluidos los casos obligatorios de la sección IV.
--     PARTE 3: casos detallados por SP (cada condición de error y sus combinaciones), con sus propios datos.
--
-- CÓMO LEER CADA PRUEBA:
--   No es un reporte: cada caso ejecuta el SP con la entrada inválida y muestra en Mensajes el mensaje con el
--   que el SP la rechaza (no hay tablas de control ni resumen final). Cada caso es un bloque propio que
--   termina en GO:
--     -- F-x.y.nn <SP>: <qué entrada inválida se prueba> => <cantidad de errores que debe informar el SP>
--     PRINT '--- F-x.y.nn <SP>: <descripción>';                    (identifica la prueba en Mensajes)
--     DECLARE ...                                                   (solo las variables que usa)
--     BEGIN TRY EXEC <SP> <entrada inválida>; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
--     GO
--   Lo que importa en estos casos es el mensaje: si el SP rechaza la operación es porque entró al IF de cada
--   condición incumplida y las agrupa todas en un único mensaje (la cantidad de errores es la que se declara
--   en el comentario del caso). Por eso los casos fallidos no llevan SELECT: la tabla no cambia.
--   Los SP *_validar devuelven los errores en un parámetro OUTPUT: la prueba lo muestra con PRINT @e.
--   Los lotes P-... son preparaciones (no son pruebas): cargan los datos que necesitan los rechazos siguientes.
--
-- ÍNDICE (sección, ids):
--   1.1   torneo.parametro                                      F-1.1.01 a F-1.1.02
--   1.2   torneo.pais y torneo.confederacion                    F-1.2.01 a F-1.2.03
--   1.3   torneo.sede                                           F-1.3.01
--   1.4   torneo.seleccion                                      F-1.4.01 a F-1.4.02
--   1.5   torneo.partido                                        F-1.5.01 a F-1.5.03
--   1.6   plantel.persona, cuerpo_tecnico y jugador             F-1.6.01 a F-1.6.04
--   1.7   plantel.convocatoria                                  F-1.7.01 a F-1.7.02
--   1.8   plantel.formacion y formacion_jugador                 F-1.8.01 a F-1.8.03
--   1.9   evento.sustitucion                                    F-1.9.01
--   1.10  evento.gol                                            F-1.10.01
--   1.11  evento.tarjeta, criterio_suspension y suspension      F-1.11.01 a F-1.11.05
--   1.12  arbitraje: arbitro, idioma, designación e informe     F-1.12.01 a F-1.12.04
--   1.13  publicidad: anunciante, campaña, pieza y espacio      F-1.13.01 a F-1.13.06
--   2.1   plantel.reemplazar_convocado                          F-2.1.01
--   2.2   plantel.cargar_formacion                              F-2.2.01
--   2.3   evento.registrar_sustitucion                          F-2.3.01 a F-2.3.04
--   2.4   evento.registrar_gol                                  F-2.4.01 a F-2.4.02
--   2.5   evento.registrar_tarjeta                              F-2.5.01 a F-2.5.02
--   2.6   publicidad.asignar_espacios_partido y facturación     F-2.6.01 a F-2.6.03
--   2.7   torneo.registrar_resultado                            F-2.7.01 a F-2.7.05
--   2.8   jugador suspendido fuera de la formación              F-2.8.01 a F-2.8.02
--   2.9   arbitraje.designar_arbitros                           F-2.9.01 a F-2.9.02
--   2.10  partido de eliminación directa completo               F-2.10.01 a F-2.10.05
--   2.11  transaccionalidad                                     F-2.11.01
--   3.0   preparación de los datos de la Parte 3                P-3.01 a P-3.25
--   3.1   torneo.parametro                                      F-3.1.01 a F-3.1.45
--   3.2   torneo.pais y torneo.confederacion                    F-3.2.01 a F-3.2.115
--   3.3   torneo.sede                                           F-3.3.01 a F-3.3.58
--   3.4   torneo.seleccion                                      F-3.4.01 a F-3.4.45
--   3.5   torneo.partido                                        F-3.5.01 a F-3.5.61
--   3.6   plantel.persona, cuerpo_tecnico y jugador             F-3.6.01 a F-3.6.110
--   3.7   plantel.convocatoria                                  F-3.7.01 a F-3.7.33
--   3.8   plantel.formacion y formacion_jugador                 F-3.8.01 a F-3.8.96
--   3.9   evento.sustitucion                                    F-3.9.01 a F-3.9.76
--   3.10  evento.gol                                            F-3.10.01 a F-3.10.93
--   3.11  evento.tarjeta, criterio_suspension y suspension      F-3.11.01 a F-3.11.164
--   3.12  arbitraje: arbitro, idioma, designación e informe     F-3.12.01 a F-3.12.118
--   3.13  publicidad: anunciante, campaña, pieza y espacio      F-3.13.01 a F-3.13.161
--
-- CÓMO EJECUTARLO:
--   Todo junto: con la base recién creada (entrega5_db_definition.sql, entrega5_sp_ABM.sql y entrega5_sp_logica_negocio.sql) ejecutar este archivo
--   completo. Exige una base recién creada (sin datos de pruebas previas) y no depende de haber ejecutado
--   entrega5_test_exitosos.sql. Al final tiene el bloque RESET, que vuelve la base al estado inicial.--   De a un caso: seleccionar el bloque del caso (desde su comentario de identificación hasta su GO, buscar el
--   id con Ctrl+F) y ejecutar la selección. Cada bloque declara sus propias variables y toma los ids de la base
--   (de las tablas del modelo o de prueba.id y prueba.test_*), así que no depende de la ventana de consulta.
--   Las Partes 1 y 2 son un escenario encadenado: cada rechazo depende del estado que dejan los lotes previos
--   (ejecutar antes el Lote 0 y los lotes anteriores). Los casos de la Parte 3 no modifican la base (el SP
--   rechaza la entrada antes de escribir; los que necesitan una operación válida previa la hacen en una
--   transacción que se deshace), así que se pueden repetir en cualquier orden una vez ejecutadas las
--   preparaciones P-3.xx. Para volver al estado inicial: ejecutar el bloque RESET del final de este archivo.
-- ============================================================


USE mundial_2026;
GO

SET NOCOUNT ON;
GO

-- Control de la ejecución completa: la base tiene que estar recién creada
PRINT '--- Control de la ejecución completa: la base tiene que estar recién creada';
-- Al ejecutar el archivo completo sobre una base con datos, avisa y no ejecuta nada más.
-- (Al ejecutar casos sueltos se puede omitir este lote.)
IF EXISTS (SELECT 1 FROM torneo.pais)
BEGIN
    RAISERROR('La base ya tiene datos: ejecutar primero el bloque RESET del final del test para dejarla en estado inicial. No se ejecuta ninguna prueba.', 16, 1);
    SET NOEXEC ON;
END;
GO

-- Lote 0: tablas auxiliares de las pruebas
PRINT '--- Lote 0: tablas auxiliares de las pruebas (esquema prueba)';
-- Ejecutar una vez antes de los casos (se puede repetir: no borra nada). La tabla prueba.id guarda los ids que
-- genera el escenario de las Partes 1 y 2, y las preparaciones P-3.xx crean sus propias tablas prueba.test_*.
-- Son tablas de la base (no temporales): cada caso se puede ejecutar solo, desde cualquier ventana de consulta.
IF SCHEMA_ID('prueba') IS NULL
    EXEC('CREATE SCHEMA prueba');
GO

IF OBJECT_ID('prueba.id', 'U') IS NULL
    CREATE TABLE prueba.id (clave VARCHAR(20) PRIMARY KEY, valor INT);   -- ids generados por el escenario
GO

PRINT '################ PARTE 1: PROCEDIMIENTOS DE ABM (escenario) ################';
GO

-- ============================================================
-- 1.1 torneo.parametro
-- ============================================================

-- P-1.1.01 Preparación: alta, modificación y baja de un parámetro
PRINT '--- P-1.1.01 Preparación: alta, modificación y baja de un parámetro';
EXEC torneo.parametro_insertar 'parametro_de_prueba', 7, 'Parámetro creado por el test';
EXEC torneo.parametro_modificar 'parametro_de_prueba', 9;
EXEC torneo.parametro_eliminar 'parametro_de_prueba';
-- SELECT * FROM torneo.parametro ORDER BY clave;
GO

-- F-1.1.01 Alta de parámetro con clave vacía, valor negativo y descripción vacía => 3 errores
PRINT '--- F-1.1.01 torneo.parametro_insertar: alta inválida';
BEGIN TRY EXEC torneo.parametro_insertar '', -1, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.1.02 Baja de un parámetro que usan los SP (cambios_max_reglamentarios) => 1 error
PRINT '--- F-1.1.02 torneo.parametro_eliminar: parámetro requerido';
BEGIN TRY EXEC torneo.parametro_eliminar 'cambios_max_reglamentarios'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.2 torneo.pais y torneo.confederacion
-- ============================================================

-- P-1.2.01 Preparación: alta de países y confederaciones
PRINT '--- P-1.2.01 Preparación: alta de países y confederaciones';
DECLARE @id INT;
EXEC torneo.pais_insertar 'ARG', 'Argentina',      'UTC-03', 13700, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_ARG', @id);
EXEC torneo.pais_insertar 'BRA', 'Brasil',         'UTC-03', 10300, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_BRA', @id);
EXEC torneo.pais_insertar 'URY', 'Uruguay',        'UTC-03', 22000, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_URY', @id);
EXEC torneo.pais_insertar 'USA', 'Estados Unidos', 'UTC-05', 82700, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_USA', @id);
EXEC torneo.pais_insertar 'CAN', 'Canadá',         'UTC-05', 53400, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_CAN', @id);
EXEC torneo.pais_insertar 'MEX', 'México',         'UTC-06', 13800, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_MEX', @id);
EXEC torneo.pais_insertar 'FRA', 'Francia',        'UTC+01', 44700, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_FRA', @id);
EXEC torneo.pais_insertar 'DEU', 'Alemania',       'UTC+01', 52700, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_DEU', @id);
EXEC torneo.pais_insertar 'ESP', 'España',         'UTC+01', 33500, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_ESP', @id);
EXEC torneo.pais_insertar 'JPN', 'Japón',          'UTC+09', 33800, @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_JPN', @id);
EXEC torneo.pais_insertar 'zzz', 'País temporal',  'UTC+00', NULL,  @id OUTPUT; INSERT INTO prueba.id VALUES ('pais_ZZZ', @id);

EXEC torneo.confederacion_insertar 'CONMEBOL', @id OUTPUT; INSERT INTO prueba.id VALUES ('conf_CONMEBOL', @id);
EXEC torneo.confederacion_insertar 'UEFA',     @id OUTPUT; INSERT INTO prueba.id VALUES ('conf_UEFA', @id);
EXEC torneo.confederacion_insertar 'CONCACAF', @id OUTPUT; INSERT INTO prueba.id VALUES ('conf_CONCACAF', @id);
EXEC torneo.confederacion_insertar 'AFC',      @id OUTPUT; INSERT INTO prueba.id VALUES ('conf_AFC', @id);
EXEC torneo.confederacion_insertar 'CAF',      @id OUTPUT; INSERT INTO prueba.id VALUES ('conf_CAF', @id);
EXEC torneo.confederacion_insertar 'OFC',      @id OUTPUT; INSERT INTO prueba.id VALUES ('conf_OFC', @id);
-- SELECT * FROM torneo.pais ORDER BY pais_id;
-- SELECT * FROM torneo.confederacion ORDER BY confederacion_id;
GO

-- P-1.2.02 Preparación: modificación y baja de país y de confederación
PRINT '--- P-1.2.02 Preparación: modificación y baja de país y de confederación';
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ARG'), @zzz INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ZZZ'),
        @ofc INT = (SELECT valor FROM prueba.id WHERE clave = 'conf_OFC');
EXEC torneo.pais_modificar @arg, 'ARG', 'Argentina', 'UTC-03', 14000;
EXEC torneo.pais_eliminar @zzz;
EXEC torneo.confederacion_modificar @ofc, 'OFC';
EXEC torneo.confederacion_eliminar @ofc;
-- SELECT * FROM torneo.pais ORDER BY pais_id;
-- SELECT * FROM torneo.confederacion ORDER BY confederacion_id;
GO

-- F-1.2.01 Alta de país con código ISO, nombre, huso horario y PBI inválidos => 4 errores
PRINT '--- F-1.2.01 torneo.pais_insertar: alta inválida';
BEGIN TRY EXEC torneo.pais_insertar 'AR1X', '   ', 'GMT-3', -5; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.2.02 Alta de país con un código ISO que ya existe ('arg', se compara en mayúsculas) => 1 error
PRINT '--- F-1.2.02 torneo.pais_insertar: código duplicado';
BEGIN TRY EXEC torneo.pais_insertar 'arg', 'Argentina bis', 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.2.03 Alta de una confederación fuera del dominio ('FIFA') => 1 error
PRINT '--- F-1.2.03 torneo.confederacion_insertar: fuera de dominio';
BEGIN TRY EXEC torneo.confederacion_insertar 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.3 torneo.sede
-- ============================================================

-- P-1.3.01 Preparación: alta, modificación y baja de sedes
PRINT '--- P-1.3.01 Preparación: alta, modificación y baja de sedes';
DECLARE @id INT, @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_USA'),
        @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_MEX'), @can INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_CAN');
EXEC torneo.sede_insertar 'MetLife Stadium', 'East Rutherford', @usa, 82000, 'UTC-04', @id OUTPUT; INSERT INTO prueba.id VALUES ('sede_NY', @id);
EXEC torneo.sede_insertar 'Estadio Azteca', 'Ciudad de México', @mex, 83000, 'UTC-06', @id OUTPUT; INSERT INTO prueba.id VALUES ('sede_MX', @id);
EXEC torneo.sede_insertar 'BMO Field', 'Toronto', @can, 45000, 'UTC-04', @id OUTPUT;              INSERT INTO prueba.id VALUES ('sede_TO', @id);
EXEC torneo.sede_insertar 'Estadio temporal', 'Ciudad temporal', @can, 100, 'UTC-04', @id OUTPUT;
EXEC torneo.sede_eliminar @id;
SET @id = (SELECT valor FROM prueba.id WHERE clave = 'sede_NY');
EXEC torneo.sede_modificar @id, 'MetLife Stadium', 'East Rutherford', @usa, 82500, 'UTC-04';
-- SELECT * FROM torneo.sede ORDER BY sede_id;
GO

-- F-1.3.01 Alta de sede con nombre y ciudad vacíos, país inexistente, capacidad 0 y huso mal escrito => 5 errores
PRINT '--- F-1.3.01 torneo.sede_insertar: alta inválida';
BEGIN TRY EXEC torneo.sede_insertar '', '', 9999, 0, 'UTC-4'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.4 torneo.seleccion
-- ============================================================

-- P-1.4.01 Preparación: alta, modificación y baja de selecciones
PRINT '--- P-1.4.01 Preparación: alta, modificación y baja de selecciones';
DECLARE @id INT, @conmebol INT = (SELECT valor FROM prueba.id WHERE clave = 'conf_CONMEBOL'), @uefa INT = (SELECT valor FROM prueba.id WHERE clave = 'conf_UEFA'),
        @concacaf INT = (SELECT valor FROM prueba.id WHERE clave = 'conf_CONCACAF'), @afc INT = (SELECT valor FROM prueba.id WHERE clave = 'conf_AFC'), @pais INT;
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_ARG'); EXEC torneo.seleccion_insertar @pais, @conmebol, 'A', @id OUTPUT; INSERT INTO prueba.id VALUES ('ARG', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_FRA'); EXEC torneo.seleccion_insertar @pais, @uefa, 'A', @id OUTPUT;     INSERT INTO prueba.id VALUES ('FRA', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_MEX'); EXEC torneo.seleccion_insertar @pais, @concacaf, 'A', @id OUTPUT; INSERT INTO prueba.id VALUES ('MEX', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_JPN'); EXEC torneo.seleccion_insertar @pais, @afc, 'A', @id OUTPUT;      INSERT INTO prueba.id VALUES ('JPN', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_BRA'); EXEC torneo.seleccion_insertar @pais, @conmebol, 'C', @id OUTPUT; INSERT INTO prueba.id VALUES ('BRA', @id);
EXEC torneo.seleccion_modificar @id, @pais, @conmebol, 'b';
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_ESP'); EXEC torneo.seleccion_insertar @pais, @uefa, 'B', @id OUTPUT;
EXEC torneo.seleccion_eliminar @id;
-- SELECT * FROM torneo.seleccion ORDER BY seleccion_id;
GO

-- F-1.4.01 Alta de selección con país y confederación inexistentes y grupo 'Z' => 3 errores
PRINT '--- F-1.4.01 torneo.seleccion_insertar: alta inválida';
BEGIN TRY EXEC torneo.seleccion_insertar 9999, 9999, 'Z'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.4.02 Alta de una segunda selección para Argentina => 1 error
PRINT '--- F-1.4.02 torneo.seleccion_insertar: país repetido';
DECLARE @pais INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ARG'), @conf INT = (SELECT valor FROM prueba.id WHERE clave = 'conf_UEFA');
BEGIN TRY EXEC torneo.seleccion_insertar @pais, @conf, 'D'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.5 torneo.partido
-- ============================================================

-- P-1.5.01 Preparación: alta, modificación y baja de partidos (P1 a P4)
PRINT '--- P-1.5.01 Preparación: alta, modificación y baja de partidos (P1 a P4)';
DECLARE @id INT, @ny INT = (SELECT valor FROM prueba.id WHERE clave = 'sede_NY'), @mx INT = (SELECT valor FROM prueba.id WHERE clave = 'sede_MX'),
        @to INT = (SELECT valor FROM prueba.id WHERE clave = 'sede_TO'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'FRA'), @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'MEX'),
        @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'JPN');
EXEC torneo.partido_insertar @ny, '2026-06-12T20:00:00-04:00', 'grupos', @arg, @fra, NULL, @id OUTPUT;        INSERT INTO prueba.id VALUES ('P1', @id);
EXEC torneo.partido_insertar @mx, '2026-06-17T18:00:00-06:00', 'grupos', @arg, @mex, NULL, @id OUTPUT;        INSERT INTO prueba.id VALUES ('P2', @id);
EXEC torneo.partido_insertar @to, '2026-06-22T13:00:00-04:00', 'grupos', @arg, @jpn, NULL, @id OUTPUT;        INSERT INTO prueba.id VALUES ('P3', @id);
EXEC torneo.partido_modificar @id, @to, '2026-06-22T16:00:00-04:00', 'grupos', @arg, @jpn;
EXEC torneo.partido_insertar @ny, '2026-06-29T18:00:00-04:00', 'dieciseisavos', @fra, @jpn, NULL, @id OUTPUT; INSERT INTO prueba.id VALUES ('P4', @id);
EXEC torneo.partido_insertar @mx, '2026-06-25T18:00:00-06:00', 'grupos', @mex, @jpn, NULL, @id OUTPUT;
EXEC torneo.partido_eliminar @id;
-- SELECT * FROM torneo.partido ORDER BY partido_id;
GO

-- F-1.5.01 Alta de partido con sede inexistente, hora UTC sin offset +00:00 y distinta de la local, fase inválida,
--          la misma selección como local y visitante, y una selección con otro partido a menos de 24 horas => 6 errores
PRINT '--- F-1.5.01 torneo.partido_insertar: alta inválida';
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG');
BEGIN TRY EXEC torneo.partido_insertar 9999, '2026-06-13T10:00:00-04:00', 'amistoso', @arg, @arg, '2026-06-13T10:00:00-03:00'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.5.02 Argentina vs Brasil en "grupos", en MetLife el mismo día que P1 y con offset -03:00: hora fuera del huso de la
--          sede, selecciones de distinto grupo, sede ocupada ese día y selección que juega a menos de 24 horas => 4 errores
PRINT '--- F-1.5.02 torneo.partido_insertar: reglas de fixture';
DECLARE @ny INT = (SELECT valor FROM prueba.id WHERE clave = 'sede_NY'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @bra INT = (SELECT valor FROM prueba.id WHERE clave = 'BRA');
BEGIN TRY EXEC torneo.partido_insertar @ny, '2026-06-12T15:00:00-03:00', 'grupos', @arg, @bra; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.5.03 Francia vs Argentina en grupos, cruce que ya existe con la localía invertida (P1) => 1 error
PRINT '--- F-1.5.03 torneo.partido_insertar: cruce repetido';
DECLARE @ny INT = (SELECT valor FROM prueba.id WHERE clave = 'sede_NY'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'FRA');
BEGIN TRY EXEC torneo.partido_insertar @ny, '2026-07-05T15:00:00-04:00', 'grupos', @fra, @arg; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================

-- P-1.6.01 Preparación: alta, modificación y baja de cuerpo técnico (crea y borra su persona)
PRINT '--- P-1.6.01 Preparación: alta, modificación y baja de cuerpo técnico';
DECLARE @id INT, @persona INT, @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'), @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'FRA');
EXEC plantel.cuerpo_tecnico_insertar @arg, 'Lionel', 'Scaloni', 'director_tecnico', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @arg, 'Pablo', 'Aimar', 'otro', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_modificar @id, @arg, 'Pablo', 'Aimar', 'ayudante_tecnico';
EXEC plantel.cuerpo_tecnico_insertar @fra, 'Didier', 'Deschamps', 'director_tecnico', @id OUTPUT, @persona OUTPUT;
INSERT INTO prueba.id VALUES ('persona_DT_FRA', @persona);
EXEC plantel.cuerpo_tecnico_insertar @fra, 'Temporal', 'Temporal', 'otro', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_eliminar @id;
-- SELECT * FROM plantel.cuerpo_tecnico ORDER BY staff_id;
GO

-- F-1.6.01 Alta de cuerpo técnico con selección inexistente, nombre vacío y rol inválido ('utilero') => 3 errores
PRINT '--- F-1.6.01 plantel.cuerpo_tecnico_insertar: alta inválida';
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar 9999, '', 'Pérez', 'utilero'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.6.02 Alta de un segundo director técnico para Argentina => 1 error
PRINT '--- F-1.6.02 plantel.cuerpo_tecnico_insertar: segundo director técnico';
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @arg, 'Otro', 'Técnico', 'director_tecnico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.6.02 Preparación: alta de los jugadores de ARG, FRA, MEX y JPN (por SP, uno por uno)
PRINT '--- P-1.6.02 Preparación: alta de jugadores';
DECLARE @plantel TABLE (codigo CHAR(3), cantidad INT);
INSERT INTO @plantel VALUES ('ARG', 27), ('FRA', 23), ('MEX', 23), ('JPN', 24);
DECLARE @codigo CHAR(3) = '', @cantidad INT, @n INT, @apellido VARCHAR(100), @nacimiento DATE, @posicion VARCHAR(20);
WHILE 1 = 1
BEGIN
    SELECT TOP (1) @codigo = codigo, @cantidad = cantidad FROM @plantel WHERE codigo > @codigo ORDER BY codigo;
    IF @@ROWCOUNT = 0 BREAK;
    SET @n = 1;
    WHILE @n <= @cantidad
    BEGIN
        SELECT @apellido = 'Jugador ' + RIGHT('0' + CAST(@n AS VARCHAR(2)), 2),
               @nacimiento = DATEADD(DAY, @n * 40, '1995-03-01'),
               @posicion = CASE WHEN @n IN (1, 12, 23) THEN 'arquero' WHEN @n % 3 = 0 THEN 'delantero'
                                WHEN @n % 3 = 1 THEN 'mediocampista' ELSE 'defensor' END;
        EXEC plantel.jugador_insertar @nombre = @codigo, @apellido = @apellido, @fecha_nacimiento = @nacimiento,
             @posicion_habitual = @posicion, @club_origen = 'Club de prueba';
        SET @n += 1;
    END;
END;
-- SELECT * FROM plantel.jugador ORDER BY jugador_id;
GO

-- P-1.6.03 Preparación: modificación y baja de jugador; alta, modificación y baja de persona
PRINT '--- P-1.6.03 Preparación: modificación y baja de jugador; ABM de persona';
DECLARE @id INT, @persona INT;
SELECT @id = jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 10';
EXEC plantel.jugador_modificar @id, 'ARG', 'Jugador 10', '1996-04-04', 'delantero', 'Inter Miami CF';
EXEC plantel.jugador_insertar 'Temporal', 'Temporal', '2000-01-01', 'defensor', NULL, @id OUTPUT, @persona OUTPUT;
EXEC plantel.jugador_eliminar @id;
EXEC plantel.persona_insertar 'jugador', @persona OUTPUT;
EXEC plantel.persona_modificar @persona, 'cuerpo_tecnico';
EXEC plantel.persona_eliminar @persona;
-- SELECT * FROM plantel.jugador ORDER BY jugador_id;
-- SELECT * FROM plantel.persona ORDER BY persona_id;
GO

-- F-1.6.03 Alta de jugador con nombre vacío, nacimiento en 2030 y posición inválida ('lateral') => 3 errores
PRINT '--- F-1.6.03 plantel.jugador_insertar: alta inválida';
BEGIN TRY EXEC plantel.jugador_insertar '', 'Pérez', '2030-01-01', 'lateral'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.6.04 Pasar a cuerpo técnico la persona de un jugador registrado => 1 error
PRINT '--- F-1.6.04 plantel.persona_modificar: cambio de tipo inválido';
DECLARE @persona INT = (SELECT persona_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 10');
BEGIN TRY EXEC plantel.persona_modificar @persona, 'cuerpo_tecnico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.7 plantel.convocatoria
-- ============================================================

-- P-1.7.01 Preparación: convocatorias de las cuatro selecciones (el jugador 27 de ARG queda sin convocar)
PRINT '--- P-1.7.01 Preparación: alta de convocatorias';
DECLARE @lista TABLE (fila INT IDENTITY(1, 1) PRIMARY KEY, seleccion_id INT, jugador_id INT, dorsal INT);
INSERT INTO @lista (seleccion_id, jugador_id, dorsal)
SELECT s.seleccion_id, j.jugador_id, CAST(RIGHT(j.apellido, 2) AS INT)
FROM plantel.jugador j
JOIN torneo.pais p      ON p.codigo_iso = j.nombre
JOIN torneo.seleccion s ON s.pais_id = p.pais_id
WHERE NOT (j.nombre = 'ARG' AND j.apellido = 'Jugador 27')
ORDER BY s.seleccion_id, j.jugador_id;
DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @lista), @sel INT, @jug INT, @dorsal INT;
WHILE @i <= @total
BEGIN
    SELECT @sel = seleccion_id, @jug = jugador_id, @dorsal = dorsal FROM @lista WHERE fila = @i;
    EXEC plantel.convocatoria_insertar @sel, @jug, @dorsal, '2026-06-01', 'Lista inicial';
    SET @i += 1;
END;
-- SELECT * FROM plantel.convocatoria ORDER BY convocatoria_id;
GO

-- F-1.7.01 Convocar al jugador 27 de ARG con el dorsal 10: dorsal en uso y cupo de 26 convocados completo => 2 errores
PRINT '--- F-1.7.01 plantel.convocatoria_insertar: cupo máximo y dorsal repetido';
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @j27 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27');
BEGIN TRY EXEC plantel.convocatoria_insertar @arg, @j27, 10, '2026-06-02'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.7.02 Convocar a ARG un jugador de Francia con dorsal 150 y sin fecha de alta: dorsal fuera de rango, fecha
--          obligatoria, jugador convocado por otra selección y cupo completo => 4 errores
PRINT '--- F-1.7.02 plantel.convocatoria_insertar: alta inválida';
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @fra1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'FRA' AND apellido = 'Jugador 01');
BEGIN TRY EXEC plantel.convocatoria_insertar @arg, @fra1, 150, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.7.02 Preparación: modificación y baja física de convocatoria
PRINT '--- P-1.7.02 Preparación: modificación y baja de convocatoria';
DECLARE @conv INT;
SELECT @conv = c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE j.nombre = 'ARG' AND j.apellido = 'Jugador 26';
EXEC plantel.convocatoria_modificar @conv, 99, '2026-06-01', 'Lista inicial';
SELECT @conv = c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE j.nombre = 'JPN' AND j.apellido = 'Jugador 24';
EXEC plantel.convocatoria_eliminar @conv;
-- SELECT * FROM plantel.convocatoria ORDER BY convocatoria_id;
GO

-- ============================================================
-- 1.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================

-- P-1.8.01 Preparación: formación temporal de Japón en P3, con dos jugadores
PRINT '--- P-1.8.01 Preparación: alta y modificación de formación y de sus jugadores';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'JPN'), @form INT, @j INT;
EXEC plantel.formacion_insertar @p3, 'visitante', '4-4-2', @form OUTPUT;
INSERT INTO prueba.id VALUES ('form_tmp', @form);
EXEC plantel.formacion_modificar @form, '3-5-2';
SELECT @j = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @jpn AND dorsal = 1 AND fecha_baja IS NULL;
EXEC plantel.formacion_jugador_insertar @form, @j, 'arquero', 1;
SELECT @j = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @jpn AND dorsal = 12 AND fecha_baja IS NULL;
EXEC plantel.formacion_jugador_insertar @form, @j, 'arquero', 1;
EXEC plantel.formacion_jugador_modificar @form, @j, 'arquero suplente', 0;
-- SELECT * FROM plantel.formacion ORDER BY formacion_id;
-- SELECT * FROM plantel.formacion_jugador ORDER BY formacion_id, jugador_id;
GO

-- F-1.8.01 Alta de formación con partido inexistente, condición 'neutral' y esquema que no suma 10 => 3 errores
PRINT '--- F-1.8.01 plantel.formacion_insertar: alta inválida';
BEGIN TRY EXEC plantel.formacion_insertar 9999, 'neutral', '4-4-3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.8.02 Agregar a la formación de Japón un jugador de Francia (no convocado) y sin posición => 2 errores
PRINT '--- F-1.8.02 plantel.formacion_jugador_insertar: no convocado y sin posición';
DECLARE @form INT = (SELECT valor FROM prueba.id WHERE clave = 'form_tmp'),
        @fra1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'FRA' AND apellido = 'Jugador 01');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @form, @fra1, '', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.8.03 Baja de una formación que todavía tiene jugadores => 1 error
PRINT '--- F-1.8.03 plantel.formacion_eliminar: formación con jugadores';
DECLARE @form INT = (SELECT valor FROM prueba.id WHERE clave = 'form_tmp');
BEGIN TRY EXEC plantel.formacion_eliminar @form; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.8.02 Preparación: baja de los jugadores de la formación temporal y de la formación
PRINT '--- P-1.8.02 Preparación: baja de jugadores de la formación y de la formación';
DECLARE @form INT = (SELECT valor FROM prueba.id WHERE clave = 'form_tmp'), @j INT;
SELECT @j = MIN(jugador_id) FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC plantel.formacion_jugador_eliminar @form, @j;
SELECT @j = MIN(jugador_id) FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC plantel.formacion_jugador_eliminar @form, @j;
EXEC plantel.formacion_eliminar @form;
-- SELECT * FROM plantel.formacion_jugador ORDER BY formacion_id, jugador_id;
-- SELECT * FROM plantel.formacion ORDER BY formacion_id;
GO

-- P-1.8.03 Preparación: formaciones de P1 (Argentina vs Francia), con plantel.cargar_formacion.
--          Titulares: dorsales 1 a 11. Suplentes: 12 a 23.
PRINT '--- P-1.8.03 Preparación: formaciones de P1 (Argentina vs Francia)';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'FRA'), @form INT;
DECLARE @local plantel.tt_formacion_jugador, @visitante plantel.tt_formacion_jugador;
INSERT INTO @local (jugador_id, posicion, titular)
SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23;
INSERT INTO @visitante (jugador_id, posicion, titular)
SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL AND c.dorsal <= 23;
EXEC plantel.cargar_formacion @p1, 'local', '4-3-3', @local, @form OUTPUT;         INSERT INTO prueba.id VALUES ('P1_local', @form);
EXEC plantel.cargar_formacion @p1, 'visitante', '4-4-2', @visitante, @form OUTPUT; INSERT INTO prueba.id VALUES ('P1_visitante', @form);
-- SELECT * FROM plantel.formacion ORDER BY formacion_id;
GO

-- ============================================================
-- 1.9 evento.sustitucion
-- ============================================================

-- P-1.9.01 Preparación: alta, modificación y baja de sustitución (Argentina en P1: sale el 9, entra el 14)
PRINT '--- P-1.9.01 Preparación: alta, modificación y baja de sustitución';
DECLARE @form INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_local'), @sust INT, @tmp INT,
        @j8 INT, @j9 INT, @j14 INT, @j15 INT;
SELECT @j8  = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 8;
SELECT @j9  = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 9;
SELECT @j14 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 14;
SELECT @j15 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 15;
EXEC evento.sustitucion_insertar @form, @j9, @j14, 60, 'ST', 1, 'tactico', @sust OUTPUT;
EXEC evento.sustitucion_modificar @sust, 62, 'ST', 1, 'precaucion';
EXEC evento.sustitucion_insertar @form, @j8, @j15, 75, 'ST', 2, 'tactico', @tmp OUTPUT;
EXEC evento.sustitucion_eliminar @tmp;
-- SELECT * FROM evento.sustitucion ORDER BY sustitucion_id;
GO

-- F-1.9.01 Sustitución en tiempo suplementario de fase de grupos, motivo inválido, ventana 0 (y fuera de orden), sale el 9
--          (ya no está en cancha) y entra el 3 (es titular) => 6 errores
PRINT '--- F-1.9.01 evento.sustitucion_insertar: alta inválida';
DECLARE @form INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_local'), @j3 INT, @j9 INT;
SELECT @j3 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 3;
SELECT @j9 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 9;
BEGIN TRY EXEC evento.sustitucion_insertar @form, @j9, @j3, 95, 'alargue_1', 0, 'cansancio'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.10 evento.gol
-- ============================================================

-- P-1.10.01 Preparación: alta, modificación y baja de gol (Argentina 1 - Francia 0 en P1)
PRINT '--- P-1.10.01 Preparación: alta, modificación y baja de gol';
DECLARE @local INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_local'), @visitante INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_visitante'),
        @gol INT, @tmp INT, @j10 INT, @j11 INT, @f2 INT;
SELECT @j10 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 10;
SELECT @j11 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 11;
SELECT @f2 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @visitante AND dorsal = 2;
EXEC evento.gol_insertar @local, @j10, 23, 'jugada', 'PT', @j11, @gol OUTPUT;
EXEC evento.gol_modificar @gol, 24, 'cabezazo', 'PT', @j11;
EXEC evento.gol_insertar @visitante, @f2, 35, 'en_contra', 'PT', NULL, @tmp OUTPUT;
EXEC evento.gol_eliminar @tmp;
-- SELECT * FROM evento.gol ORDER BY gol_id;
GO

-- F-1.10.01 Gol de tipo inválido ('chilena'), minuto 70 en el PT, autor suplente (20) que no ingresó, asistente igual al
--           autor y asistente que no ingresó => 5 errores
PRINT '--- F-1.10.01 evento.gol_insertar: alta inválida';
DECLARE @local INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_local'), @j20 INT;
SELECT @j20 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 20;
BEGIN TRY EXEC evento.gol_insertar @local, @j20, 70, 'chilena', 'PT', @j20; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================

-- P-1.11.01 Preparación: alta, modificación y baja de tarjeta (amarilla al 6 de Francia en P1)
PRINT '--- P-1.11.01 Preparación: alta, modificación y baja de tarjeta';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @visitante INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_visitante'),
        @pers6 INT, @pers7 INT, @tarjeta INT, @tmp INT;
SELECT @pers6 = j.persona_id FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
WHERE fj.formacion_id = @visitante AND fj.dorsal = 6;
SELECT @pers7 = j.persona_id FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
WHERE fj.formacion_id = @visitante AND fj.dorsal = 7;
EXEC evento.tarjeta_insertar @p1, @pers6, 30, 'PT', 'amarilla', 'Juego brusco', NULL, @tarjeta OUTPUT;
INSERT INTO prueba.id VALUES ('tarjeta_FRA6', @tarjeta);
EXEC evento.tarjeta_modificar @tarjeta, 31, 'PT', 'Juego brusco grave';
EXEC evento.tarjeta_insertar @p1, @pers7, 40, 'PT', 'amarilla', 'Protesta', NULL, @tmp OUTPUT;
EXEC evento.tarjeta_eliminar @tmp;
-- SELECT * FROM evento.tarjeta ORDER BY tarjeta_id;
GO

-- F-1.11.01 Roja en tiempo suplementario de fase de grupos, minuto 10 fuera del período, a un jugador de México (no juega
--           P1) y sin tipo de expulsión => 4 errores
PRINT '--- F-1.11.01 evento.tarjeta_insertar: alta inválida';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'),
        @mex INT = (SELECT persona_id FROM plantel.jugador WHERE nombre = 'MEX' AND apellido = 'Jugador 05');
BEGIN TRY EXEC evento.tarjeta_insertar @p1, @mex, 10, 'alargue_1', 'roja'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.11.02 Segunda fila 'amarilla' para el 6 de Francia en el mismo partido (la doble amarilla es una roja) => 1 error
PRINT '--- F-1.11.02 evento.tarjeta_insertar: segunda amarilla como fila amarilla';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @visitante INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_visitante'),
        @pers6 INT;
SELECT @pers6 = j.persona_id FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
WHERE fj.formacion_id = @visitante AND fj.dorsal = 6;
BEGIN TRY EXEC evento.tarjeta_insertar @p1, @pers6, 50, 'ST', 'amarilla'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.11.02 Preparación: criterios de suspensión general (2 amarillas => 1 partido) y de cuerpo técnico (3 amarillas
--           => 1 partido); uno de semifinal se modifica y se elimina
PRINT '--- P-1.11.02 Preparación: ABM de criterios de suspensión';
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 2, 1, NULL, NULL, 1, @id OUTPUT;             INSERT INTO prueba.id VALUES ('criterio_general', @id);
EXEC evento.criterio_suspension_insertar 3, 1, NULL, 'cuerpo_tecnico', 1, @id OUTPUT;
EXEC evento.criterio_suspension_insertar 1, 1, 'semifinal', NULL, 1, @id OUTPUT;
EXEC evento.criterio_suspension_modificar @id, 1, 2, 'semifinal', NULL, 0;
EXEC evento.criterio_suspension_eliminar @id;
-- SELECT * FROM evento.criterio_suspension ORDER BY criterio_id;
GO

-- F-1.11.03 Criterio con fase, tipo de persona, cantidad de amarillas y partidos inválidos => 4 errores
PRINT '--- F-1.11.03 evento.criterio_suspension_insertar: alta inválida';
BEGIN TRY EXEC evento.criterio_suspension_insertar 0, -1, 'amistoso', 'hincha'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.11.04 Criterio general de 2 amarillas que ya existe => 1 error
PRINT '--- F-1.11.04 evento.criterio_suspension_insertar: duplicado';
BEGIN TRY EXEC evento.criterio_suspension_insertar 2, 3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.11.03 Preparación: suspensión manual del 6 de Francia para P4: alta, corrección del motivo y baja
PRINT '--- P-1.11.03 Preparación: ABM de suspensión (carga manual)';
DECLARE @tarjeta INT = (SELECT valor FROM prueba.id WHERE clave = 'tarjeta_FRA6'), @criterio INT = (SELECT valor FROM prueba.id WHERE clave = 'criterio_general'),
        @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'), @susp INT;
EXEC evento.suspension_insertar @tarjeta, 'Sanción de oficio', @criterio, @p4, @susp OUTPUT;
EXEC evento.suspension_modificar @susp, 'Sanción de oficio del comité disciplinario', @p4;
EXEC evento.suspension_eliminar @susp;
-- SELECT * FROM evento.suspension ORDER BY suspension_id;
GO

-- F-1.11.05 Suspensión por una amarilla sin criterio, con motivo vacío y para P2, que Francia no juega => 3 errores
PRINT '--- F-1.11.05 evento.suspension_insertar: alta inválida';
DECLARE @tarjeta INT = (SELECT valor FROM prueba.id WHERE clave = 'tarjeta_FRA6'), @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2');
BEGIN TRY EXEC evento.suspension_insertar @tarjeta, '', NULL, @p2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 1.12 arbitraje: arbitro, arbitro_idioma, designacion_arbitral e informe_arbitral
-- ============================================================

-- P-1.12.01 Preparación: alta, modificación y baja de árbitros e idiomas
PRINT '--- P-1.12.01 Preparación: ABM de árbitros e idiomas';
DECLARE @id INT, @pais INT;
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_URY');
EXEC arbitraje.arbitro_insertar 'Andrés', 'Matonte', @pais, 'FIFA', NULL, @id OUTPUT;          INSERT INTO prueba.id VALUES ('arb_URY1', @id);
EXEC arbitraje.arbitro_idioma_insertar @id, 'Espanol';
EXEC arbitraje.arbitro_idioma_insertar @id, 'frances';
EXEC arbitraje.arbitro_idioma_modificar @id, 'frances', 'ingles';
EXEC arbitraje.arbitro_idioma_insertar @id, 'portugues';
EXEC arbitraje.arbitro_idioma_eliminar @id, 'portugues';
EXEC arbitraje.arbitro_insertar 'Nicolás', 'Tarán', @pais, 'confederacion', NULL, @id OUTPUT;  INSERT INTO prueba.id VALUES ('arb_URY2', @id);
EXEC arbitraje.arbitro_modificar @id, 'Nicolás', 'Tarán', @pais, 'FIFA', '1980-12-25';
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_DEU');
EXEC arbitraje.arbitro_insertar 'Felix', 'Zwayer', @pais, 'FIFA', NULL, @id OUTPUT;            INSERT INTO prueba.id VALUES ('arb_DEU1', @id);
EXEC arbitraje.arbitro_insertar 'Jan', 'Seidel', @pais, 'FIFA', NULL, @id OUTPUT;              INSERT INTO prueba.id VALUES ('arb_DEU2', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_USA');
EXEC arbitraje.arbitro_insertar 'Ismail', 'Elfath', @pais, 'FIFA', NULL, @id OUTPUT;           INSERT INTO prueba.id VALUES ('arb_USA', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_CAN');
EXEC arbitraje.arbitro_insertar 'Drew', 'Fischer', @pais, 'FIFA', NULL, @id OUTPUT;            INSERT INTO prueba.id VALUES ('arb_CAN', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_MEX');
EXEC arbitraje.arbitro_insertar 'César', 'Ramos', @pais, 'FIFA', NULL, @id OUTPUT;             INSERT INTO prueba.id VALUES ('arb_MEX', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_ARG');
EXEC arbitraje.arbitro_insertar 'Facundo', 'Tello', @pais, 'FIFA', NULL, @id OUTPUT;           INSERT INTO prueba.id VALUES ('arb_ARG', @id);
SET @pais = (SELECT valor FROM prueba.id WHERE clave = 'pais_BRA');
EXEC arbitraje.arbitro_insertar 'Wilton', 'Sampaio', @pais, 'FIFA', NULL, @id OUTPUT;          INSERT INTO prueba.id VALUES ('arb_BRA', @id);
EXEC arbitraje.arbitro_insertar 'Temporal', 'Temporal', @pais, 'confederacion', NULL, @id OUTPUT;
EXEC arbitraje.arbitro_idioma_insertar @id, 'portugues';
EXEC arbitraje.arbitro_eliminar @id;
-- SELECT * FROM arbitraje.arbitro ORDER BY arbitro_id;
-- SELECT * FROM arbitraje.arbitro_idioma ORDER BY arbitro_id;
GO

-- F-1.12.01 Alta de árbitro con apellido vacío, nacido en 2015, país inexistente y categoría 'regional' => 4 errores
PRINT '--- F-1.12.01 arbitraje.arbitro_insertar: alta inválida';
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Juan', '', 9999, 'regional', '2015-01-01'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.12.02 Idioma que el árbitro ya tiene ('ESPANOL', con otra capitalización) => 1 error
PRINT '--- F-1.12.02 arbitraje.arbitro_idioma_insertar: idioma repetido';
DECLARE @arb INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY1');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @arb, 'ESPANOL'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.12.02 Preparación: en P2 se designa a Matonte como principal, se lo reemplaza por Elfath y se carga y modifica el informe
PRINT '--- P-1.12.02 Preparación: designación arbitral e informe en P2';
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2'), @ury INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY1'),
        @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_USA'), @desig INT, @informe INT;
EXEC arbitraje.designacion_arbitral_insertar @p2, @ury, 'principal', @desig OUTPUT;   INSERT INTO prueba.id VALUES ('desig_P2', @desig);
EXEC arbitraje.designacion_arbitral_modificar @desig, @usa, 'principal';
EXEC arbitraje.informe_arbitral_insertar @desig, '2026-06-18T03:00:00+00:00', 'Partido sin incidentes.', NULL, @informe OUTPUT;
INSERT INTO prueba.id VALUES ('informe_P2', @informe);
EXEC arbitraje.informe_arbitral_modificar @informe, '2026-06-18T04:00:00+00:00', 'Partido con un incidente menor en el banco visitante.', 'Apercibimiento';
-- SELECT * FROM arbitraje.designacion_arbitral ORDER BY designacion_id;
-- SELECT * FROM arbitraje.informe_arbitral ORDER BY informe_id;
GO

-- F-1.12.03 Informe con fecha anterior al partido y contenido vacío => 2 errores
PRINT '--- F-1.12.03 arbitraje.informe_arbitral_insertar: alta inválida';
DECLARE @desig INT = (SELECT valor FROM prueba.id WHERE clave = 'desig_P2');
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @desig, '2026-06-01T00:00:00+00:00', '  '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.12.04 Cambiar la designación por el árbitro argentino en un partido de Argentina (conflicto de nacionalidad), con rol
--           inválido y en una designación que ya tiene informe (no admite cambio de árbitro) => 3 errores
PRINT '--- F-1.12.04 arbitraje.designacion_arbitral_modificar: modificación inválida';
DECLARE @desig INT = (SELECT valor FROM prueba.id WHERE clave = 'desig_P2'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_ARG');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @desig, @arg, 'juez de línea'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.12.03 Preparación: baja del informe y de la designación (P2 queda sin designaciones)
PRINT '--- P-1.12.03 Preparación: baja del informe y de la designación de P2';
DECLARE @desig INT = (SELECT valor FROM prueba.id WHERE clave = 'desig_P2'), @informe INT = (SELECT valor FROM prueba.id WHERE clave = 'informe_P2');
EXEC arbitraje.informe_arbitral_eliminar @informe;
EXEC arbitraje.designacion_arbitral_eliminar @desig;
-- SELECT * FROM arbitraje.informe_arbitral ORDER BY informe_id;
-- SELECT * FROM arbitraje.designacion_arbitral ORDER BY designacion_id;
GO

-- ============================================================
-- 1.13 publicidad: anunciante, campania, campania_pais_interes, pieza_publicitaria y espacio_publicitario
-- ============================================================

-- P-1.13.01 Preparación: anunciantes, campañas, países de interés y piezas
PRINT '--- P-1.13.01 Preparación: alta de anunciantes, campañas, países de interés y piezas';
DECLARE @anun INT, @camp INT, @pieza INT;
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ARG'), @bra INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_BRA'),
        @ury INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_URY'), @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_USA'),
        @can INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_CAN'), @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_MEX'),
        @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_FRA'), @deu INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_DEU'),
        @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_JPN'), @esp INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ESP');

EXEC publicidad.anunciante_insertar 'Mate Pampa', 'Mate Pampa S.A.', 'ventas@matepampa.com', @anun OUTPUT;
EXEC publicidad.campania_insertar @anun, 'Mundial en casa', '2026-06-01', '2026-07-19', @camp OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @camp, @arg;
EXEC publicidad.campania_pais_interes_insertar @camp, @ury;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'espanol', @arg, 50000, @pieza OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'espanol', @ury, 20000, @pieza OUTPUT;

EXEC publicidad.anunciante_insertar 'Banque Lumière', 'Banque Lumière S.A.S.', NULL, @anun OUTPUT;
EXEC publicidad.campania_insertar @anun, 'Allez', '2026-06-01', '2026-07-19', @camp OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @camp, @fra;
EXEC publicidad.campania_pais_interes_insertar @camp, @deu;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'frances', @fra, 90000, @pieza OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'aleman', @deu, 80000, @pieza OUTPUT;

EXEC publicidad.anunciante_insertar 'NorthStar Motors', 'NorthStar Motors Inc.', NULL, @anun OUTPUT;
EXEC publicidad.campania_insertar @anun, 'Drive the Cup', '2026-06-01', '2026-07-19', @camp OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @camp, @usa;
EXEC publicidad.campania_pais_interes_insertar @camp, @can;
EXEC publicidad.campania_pais_interes_insertar @camp, @mex;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'ingles', @usa, 120000, @pieza OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'ingles', @can, 70000, @pieza OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'espanol', @mex, 40000, @pieza OUTPUT;

EXEC publicidad.anunciante_insertar 'Sakura Tech', 'Sakura Tech K.K.', NULL, @anun OUTPUT;
EXEC publicidad.campania_insertar @anun, 'Next Goal', '2026-06-01', '2026-07-19', @camp OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @camp, @jpn;
EXEC publicidad.campania_pais_interes_insertar @camp, @usa;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'japones', @jpn, 60000, @pieza OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'ingles', @usa, 100000, @pieza OUTPUT;

EXEC publicidad.anunciante_insertar 'Cerveza Tropical', 'Cervejaria Tropical Ltda.', NULL, @anun OUTPUT;
EXEC publicidad.campania_insertar @anun, 'Verano mundialista', '2026-06-01', '2026-07-19', @camp OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @camp, @bra;
EXEC publicidad.campania_pais_interes_insertar @camp, @arg;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'portugues', @bra, 45000, @pieza OUTPUT;

EXEC publicidad.anunciante_insertar 'Maple Air', 'Maple Air Ltd.', NULL, @anun OUTPUT;
EXEC publicidad.campania_insertar @anun, 'Fly to the final', '2026-06-01', '2026-07-19', @camp OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @camp, @can;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'ingles', @can, 30000, @pieza OUTPUT;
INSERT INTO prueba.id VALUES ('pieza_CAN', @pieza);

EXEC publicidad.anunciante_insertar 'Tequila Sol', NULL, NULL, @anun OUTPUT;
EXEC publicidad.anunciante_modificar @anun, 'Tequila Sol', 'Tequila Sol S.A. de C.V.', 'contacto@tequilasol.example';
EXEC publicidad.campania_insertar @anun, 'Brindis', '2026-06-01', '2026-06-30', @camp OUTPUT;
EXEC publicidad.campania_modificar @camp, @anun, 'Brindis mundialista', '2026-06-01', '2026-07-19';
EXEC publicidad.campania_pais_interes_insertar @camp, @mex;
EXEC publicidad.campania_pais_interes_insertar @camp, @esp;
EXEC publicidad.campania_pais_interes_modificar @camp, @esp, @usa;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'ingles', @mex, 99999, @pieza OUTPUT;
EXEC publicidad.pieza_publicitaria_modificar @pieza, @camp, 'espanol', @mex, 35000;

-- Temporales: se crean y se eliminan (pieza, país de interés, campaña y anunciante).
EXEC publicidad.anunciante_insertar 'Anunciante temporal', NULL, NULL, @anun OUTPUT;
EXEC publicidad.campania_insertar @anun, 'Campaña temporal', '2026-06-01', '2026-06-02', @camp OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @camp, @esp;
EXEC publicidad.campania_pais_interes_insertar @camp, @deu;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'espanol', @esp, 1, @pieza OUTPUT;
EXEC publicidad.pieza_publicitaria_eliminar @pieza;
EXEC publicidad.campania_pais_interes_eliminar @camp, @deu;
EXEC publicidad.campania_eliminar @camp;
EXEC publicidad.anunciante_eliminar @anun;
-- SELECT * FROM publicidad.anunciante ORDER BY anunciante_id;
-- SELECT * FROM publicidad.campania ORDER BY campania_id;
-- SELECT * FROM publicidad.campania_pais_interes ORDER BY campania_id;
-- SELECT * FROM publicidad.pieza_publicitaria ORDER BY pieza_id;
GO

-- F-1.13.01 Campaña con anunciante inexistente, nombre vacío y fin anterior al inicio => 3 errores
PRINT '--- F-1.13.01 publicidad.campania_insertar: alta inválida';
BEGIN TRY EXEC publicidad.campania_insertar 9999, '', '2026-07-01', '2026-06-01'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.13.02 Pieza con idioma inválido, mercado (Japón) que no es país de interés de la campaña y tarifa negativa => 3 errores
PRINT '--- F-1.13.02 publicidad.pieza_publicitaria_insertar: alta inválida';
DECLARE @camp INT = (SELECT c.campania_id FROM publicidad.campania c JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id WHERE a.nombre = 'Maple Air'),
        @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_JPN');
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @camp, 'japonés 2', @jpn, -100; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.13.03 Anunciante con un nombre que ya existe ('MAPLE AIR', con otra capitalización) => 1 error
PRINT '--- F-1.13.03 publicidad.anunciante_insertar: nombre repetido';
BEGIN TRY EXEC publicidad.anunciante_insertar 'MAPLE AIR'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.13.04 Baja de un anunciante que tiene campañas => 1 error
PRINT '--- F-1.13.04 publicidad.anunciante_eliminar: anunciante con campañas';
DECLARE @anun INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'Maple Air');
BEGIN TRY EXEC publicidad.anunciante_eliminar @anun; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.13.02 Preparación: en P3 se crea el espacio 1 vacío y se le asigna la pieza de Maple Air
PRINT '--- P-1.13.02 Preparación: espacio publicitario 1 de P3';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @pieza INT = (SELECT valor FROM prueba.id WHERE clave = 'pieza_CAN'), @esp INT;
EXEC publicidad.espacio_publicitario_insertar @p3, 1, NULL, NULL, @esp OUTPUT;   INSERT INTO prueba.id VALUES ('esp_P3', @esp);
EXEC publicidad.espacio_publicitario_modificar @esp, @pieza, 4;
-- SELECT * FROM publicidad.espacio_publicitario ORDER BY espacio_id;
GO

-- F-1.13.05 Espacio 7 (fuera de rango) con pieza inexistente y prioridad 9 (fuera de rango) => 3 errores
PRINT '--- F-1.13.05 publicidad.espacio_publicitario_insertar: alta inválida';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3');
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @p3, 7, 9999, 9; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-1.13.06 Espacio 1 de P3, que ya existe, con una pieza que ya ocupa otro espacio del partido => 2 errores
PRINT '--- F-1.13.06 publicidad.espacio_publicitario_insertar: espacio y pieza repetidos';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @pieza INT = (SELECT valor FROM prueba.id WHERE clave = 'pieza_CAN');
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @p3, 1, @pieza; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-1.13.03 Preparación: baja del espacio 1 de P3
PRINT '--- P-1.13.03 Preparación: baja del espacio publicitario de P3';
DECLARE @esp INT = (SELECT valor FROM prueba.id WHERE clave = 'esp_P3');
EXEC publicidad.espacio_publicitario_eliminar @esp;
-- SELECT * FROM publicidad.espacio_publicitario ORDER BY espacio_id;
GO

PRINT '################ PARTE 2: PROCEDIMIENTOS DE LÓGICA DE NEGOCIO (escenario) ################';
GO

-- ============================================================
-- 2.1 plantel.reemplazar_convocado (baja + alta de último momento, en una transacción)
-- ============================================================

-- P-2.1.01 Preparación: reemplazo por lesión del 26 de Argentina por el 27
PRINT '--- P-2.1.01 Preparación: reemplazo por lesión';
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @sale INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 26'),
        @entra INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27');
EXEC plantel.reemplazar_convocado @arg, @sale, @entra, '2026-06-14', 'Lesión muscular en el entrenamiento';
-- SELECT * FROM plantel.convocatoria ORDER BY convocatoria_id;
GO

-- F-2.1.01 Reemplazar al 26 (ya no está vigente) por un jugador de Francia (ya convocado) y sin motivo => 3 errores
PRINT '--- F-2.1.01 plantel.reemplazar_convocado: reemplazo inválido';
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @sale INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 26'),
        @entra INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'FRA' AND apellido = 'Jugador 01');
BEGIN TRY EXEC plantel.reemplazar_convocado @arg, @sale, @entra, '2026-06-15', ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.2 plantel.cargar_formacion (cabecera + titulares + banco, todo o nada)
-- ============================================================

-- P-2.2.01 Preparación: formaciones de P2 (Argentina vs México)
PRINT '--- P-2.2.01 Preparación: formaciones de P2 (Argentina vs México)';
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'MEX'), @form INT;
DECLARE @local plantel.tt_formacion_jugador, @visitante plantel.tt_formacion_jugador;
INSERT INTO @local SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23;
INSERT INTO @visitante SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @mex AND c.fecha_baja IS NULL AND c.dorsal <= 23;
EXEC plantel.cargar_formacion @p2, 'local', '4-4-2', @local, @form OUTPUT;         INSERT INTO prueba.id VALUES ('P2_local', @form);
EXEC plantel.cargar_formacion @p2, 'visitante', '5-3-2', @visitante, @form OUTPUT; INSERT INTO prueba.id VALUES ('P2_visitante', @form);
-- SELECT * FROM plantel.formacion ORDER BY formacion_id;
GO

-- F-2.2.01 Volver a cargar la formación de México en P2 con esquema '4-4', 10 titulares, un jugador repetido y uno de
--          Francia: formación ya cargada, esquema, titulares, repetido y no convocado => 5 errores (no se inserta nada)
PRINT '--- F-2.2.01 plantel.cargar_formacion: formación inválida';
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2'), @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'MEX');
DECLARE @lista plantel.tt_formacion_jugador;
INSERT INTO @lista SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 10, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @mex AND c.fecha_baja IS NULL AND c.dorsal <= 20;
INSERT INTO @lista SELECT jugador_id, 'defensor', 0 FROM plantel.jugador WHERE nombre = 'MEX' AND apellido = 'Jugador 15';
INSERT INTO @lista SELECT jugador_id, 'defensor', 0 FROM plantel.jugador WHERE nombre = 'FRA' AND apellido = 'Jugador 15';
BEGIN TRY EXEC plantel.cargar_formacion @p2, 'visitante', '4-4', @lista; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.3 evento.registrar_sustitucion (por dorsales; ventana automática; reglamento de cambios)
-- ============================================================

-- P-2.3.01 Preparación: cuatro cambios de Francia en P1 (minutos 15, 46, 46 y 70: ventanas 1, 2, 2 y 3)
PRINT '--- P-2.3.01 Preparación: cambios de Francia en P1 (3 ventanas)';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC evento.registrar_sustitucion @p1, 'visitante', 3, 13, 15, 'PT', 'lesion';
EXEC evento.registrar_sustitucion @p1, 'visitante', 7, 14, 46, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p1, 'visitante', 8, 15, 46, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p1, 'visitante', 9, 16, 70, 'ST', 'precaucion';
-- SELECT * FROM evento.sustitucion ORDER BY sustitucion_id;
GO

-- F-2.3.01 Cambio en el minuto 80, que sería una cuarta ventana en el tiempo reglamentario => 1 error
PRINT '--- F-2.3.01 evento.registrar_sustitucion: cuarta ventana';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_sustitucion @p1, 'visitante', 10, 17, 80, 'ST', 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.3.02 Preparación: el mismo cambio en el minuto 70 comparte la ventana 3 y es el 5.º de Francia
PRINT '--- P-2.3.02 Preparación: quinto cambio de Francia en P1';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC evento.registrar_sustitucion @p1, 'visitante', 10, 17, 70, 'ST', 'tactico';
-- SELECT * FROM evento.sustitucion ORDER BY sustitucion_id;
GO

-- F-2.3.02 Sexto cambio en el tiempo reglamentario => 1 error
PRINT '--- F-2.3.02 evento.registrar_sustitucion: sexto cambio';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_sustitucion @p1, 'visitante', 11, 18, 70, 'ST', 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-2.3.03 Cambio con dorsales que no están en la formación (77 y 88) => 2 errores
PRINT '--- F-2.3.03 evento.registrar_sustitucion: dorsales inexistentes';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_sustitucion @p1, 'visitante', 77, 88, 50, 'ST', 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-2.3.04 Sale el 3 (ya salió) y entra el 13 (ya ingresó), con los 5 cambios ya hechos => 3 errores
PRINT '--- F-2.3.04 evento.registrar_sustitucion: jugadores no disponibles';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_sustitucion @p1, 'visitante', 3, 13, 70, 'ST', 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.4 evento.registrar_gol (por dorsales; actualiza el marcador)
-- ============================================================

-- P-2.4.01 Preparación: goles de P1 (Argentina 2 - Francia 1)
PRINT '--- P-2.4.01 Preparación: goles de P1';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC evento.registrar_gol @p1, 'visitante', 9, 55, 'jugada', 'ST', 14;
EXEC evento.registrar_gol @p1, 'local', 10, 88, 'penal', 'ST';
-- SELECT * FROM evento.gol ORDER BY gol_id;
GO

-- F-2.4.01 Gol con dorsales de autor (77) y asistente (88) que no están en la formación => 2 errores
PRINT '--- F-2.4.01 evento.registrar_gol: dorsales inexistentes';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_gol @p1, 'local', 77, 60, 'jugada', 'ST', 88; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-2.4.02 Gol de un suplente (dorsal 20) que no ingresó => 1 error
PRINT '--- F-2.4.02 evento.registrar_gol: suplente que no ingresó';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_gol @p1, 'local', 20, 60, 'jugada', 'ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.5 evento.registrar_tarjeta (tarjeta + cálculo de suspensión en una transacción)
-- ============================================================

-- P-2.5.01 Preparación: tarjetas de P1 (amarilla al 5 de Argentina, roja directa al 4 de Francia y amarilla al DT de Francia)
PRINT '--- P-2.5.01 Preparación: tarjetas de P1';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @dt INT = (SELECT valor FROM prueba.id WHERE clave = 'persona_DT_FRA');
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 40, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Mano intencional',
     @condicion = 'local', @dorsal = 5;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 75, @periodo = 'ST', @tipo = 'roja', @motivo = 'Agresión a un rival',
     @condicion = 'visitante', @dorsal = 4;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 76, @periodo = 'ST', @tipo = 'amarilla', @motivo = 'Protesta',
     @persona_id = @dt;
-- SELECT * FROM evento.tarjeta ORDER BY tarjeta_id;
GO

-- F-2.5.01 Tarjeta a un dorsal (77) que no identifica a ninguna persona del partido => 1 error
PRINT '--- F-2.5.01 evento.registrar_tarjeta: persona no identificada';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 80, @periodo = 'ST', @tipo = 'amarilla', @condicion = 'local', @dorsal = 77; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-2.5.02 Roja al 4 de Francia, ya expulsado en este partido, en el minuto 20 del ST (fuera del período) => 2 errores
PRINT '--- F-2.5.02 evento.registrar_tarjeta: jugador ya expulsado';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 20, @periodo = 'ST', @tipo = 'roja', @condicion = 'visitante', @dorsal = 4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.6 publicidad.asignar_espacios_partido y facturar_espacios_partido
-- ============================================================

-- P-2.6.01 Preparación: asignación de los cuatro espacios de P1
PRINT '--- P-2.6.01 Preparación: asignación de espacios de P1';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC publicidad.asignar_espacios_partido @p1;
-- SELECT * FROM publicidad.espacio_publicitario ORDER BY espacio_id;
GO

-- F-2.6.01 Asignar espacios a P1, que ya los tiene (sin @reemplazar = 1) => 1 error
PRINT '--- F-2.6.01 publicidad.asignar_espacios_partido: espacios ya asignados';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC publicidad.asignar_espacios_partido @p1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.6.02 Preparación: reasignación de los espacios de P1 con @reemplazar = 1
PRINT '--- P-2.6.02 Preparación: reasignación de espacios de P1';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC publicidad.asignar_espacios_partido @p1, @reemplazar = 1, @mostrar_detalle = 0;
-- SELECT * FROM publicidad.espacio_publicitario ORDER BY espacio_id;
GO

-- F-2.6.02 Asignar espacios a un partido inexistente => 1 error
PRINT '--- F-2.6.02 publicidad.asignar_espacios_partido: partido inexistente';
BEGIN TRY EXEC publicidad.asignar_espacios_partido 9999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-2.6.03 Facturar los espacios de P1, que todavía no está finalizado => 1 error
PRINT '--- F-2.6.03 publicidad.facturar_espacios_partido: partido no finalizado';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC publicidad.facturar_espacios_partido @p1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.7 torneo.registrar_resultado (cierre del partido + pauta exhibida) y facturación
-- ============================================================

-- F-2.7.01 Cerrar P1 con 3 a 0 (los goles registrados son 2 a 1), penales en fase de grupos y sin empate, y asistencia
--          mayor a la capacidad => 4 errores
PRINT '--- F-2.7.01 torneo.registrar_resultado: resultado inválido';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC torneo.registrar_resultado @p1, 3, 0, 5, 4, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.7.01 Preparación: cierre de P1 y facturación de su pauta
PRINT '--- P-2.7.01 Preparación: cierre de P1 y facturación';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC torneo.registrar_resultado @partido_id = @p1, @asistencia_publico = 80000;
EXEC publicidad.facturar_espacios_partido @p1;
-- SELECT * FROM torneo.partido ORDER BY partido_id;
-- SELECT * FROM publicidad.espacio_publicitario ORDER BY espacio_id;
GO

-- F-2.7.02 Volver a cerrar P1, ya finalizado => 1 error
PRINT '--- F-2.7.02 torneo.registrar_resultado: partido ya finalizado';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC torneo.registrar_resultado @p1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-2.7.03 Registrar un gol en P1, ya finalizado => 1 error
PRINT '--- F-2.7.03 evento.registrar_gol: partido finalizado';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC evento.registrar_gol @p1, 'local', 10, 89, 'jugada', 'ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-2.7.04 Volver a facturar los espacios de P1 => 1 error
PRINT '--- F-2.7.04 publicidad.facturar_espacios_partido: ya facturado';
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
BEGIN TRY EXEC publicidad.facturar_espacios_partido @p1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-2.7.05 Baja de un espacio publicitario ya facturado => 1 error
PRINT '--- F-2.7.05 publicidad.espacio_publicitario_eliminar: espacio facturado';
DECLARE @esp INT = (SELECT MIN(espacio_id) FROM publicidad.espacio_publicitario WHERE partido_id = (SELECT valor FROM prueba.id WHERE clave = 'P1'));
BEGIN TRY EXEC publicidad.espacio_publicitario_eliminar @esp; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.8 Acumulación de amarillas, doble amarilla y jugador suspendido fuera de la formación
-- ============================================================

-- P-2.8.01 Preparación: segunda amarilla del 5 de Argentina (en P2): queda suspendido para P3
PRINT '--- P-2.8.01 Preparación: suspensión por acumulación de amarillas';
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2');
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 20, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Falta táctica',
     @condicion = 'local', @dorsal = 5;
-- SELECT * FROM evento.tarjeta ORDER BY tarjeta_id;
GO

-- P-2.8.02 Preparación: expulsión por doble amonestación del 8 de México en P2
PRINT '--- P-2.8.02 Preparación: expulsión por doble amonestación';
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2');
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 30, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Juego brusco',
     @condicion = 'visitante', @dorsal = 8;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 60, @periodo = 'ST', @tipo = 'amarilla', @motivo = 'Reiteración de faltas',
     @condicion = 'visitante', @dorsal = 8;
-- SELECT * FROM evento.tarjeta ORDER BY tarjeta_id;
GO

-- P-2.8.03 Preparación: cierre de P2 sin goles (resultado tomado del detalle: 0 a 0)
PRINT '--- P-2.8.03 Preparación: cierre de P2';
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2');
EXEC torneo.registrar_resultado @partido_id = @p2, @asistencia_publico = 83000;
-- SELECT * FROM torneo.partido ORDER BY partido_id;
GO

-- F-2.8.01 CASO OBLIGATORIO: formación de Argentina para P3 con el 5 (suspendido) de titular => 1 error
PRINT '--- F-2.8.01 plantel.cargar_formacion: jugador suspendido';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG');
DECLARE @con5 plantel.tt_formacion_jugador;
INSERT INTO @con5 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23;
BEGIN TRY EXEC plantel.cargar_formacion @p3, 'local', '4-3-3', @con5; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.8.04 Preparación: la misma formación con el 12 en lugar del 5
PRINT '--- P-2.8.04 Preparación: formación de Argentina para P3 sin el suspendido';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'), @form INT;
DECLARE @sin5 plantel.tt_formacion_jugador;
INSERT INTO @sin5 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 12, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23 AND c.dorsal <> 5;
EXEC plantel.cargar_formacion @p3, 'local', '4-3-3', @sin5, @form OUTPUT;   INSERT INTO prueba.id VALUES ('P3_local', @form);
-- SELECT * FROM plantel.formacion ORDER BY formacion_id;
GO

-- F-2.8.02 CASO OBLIGATORIO: agregar el 5 (suspendido) a esa formación con el ABM de a un jugador => 1 error
PRINT '--- F-2.8.02 plantel.formacion_jugador_insertar: jugador suspendido';
DECLARE @form INT = (SELECT valor FROM prueba.id WHERE clave = 'P3_local'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'), @j5 INT;
SELECT @j5 = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @arg AND dorsal = 5 AND fecha_baja IS NULL;
BEGIN TRY EXEC plantel.formacion_jugador_insertar @form, @j5, 'defensor', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.9 arbitraje.designar_arbitros (terna completa, con validación de conflicto de nacionalidad)
-- ============================================================

-- F-2.9.01 CASO OBLIGATORIO: terna para P3 (Argentina vs Japón) sin VAR, con un árbitro en dos roles y con el árbitro
--          argentino Facundo Tello (conflicto de nacionalidad) => 3 errores
PRINT '--- F-2.9.01 arbitraje.designar_arbitros: conflicto de nacionalidad';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_ARG'),
        @ury2 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY2'), @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_USA');
BEGIN TRY EXEC arbitraje.designar_arbitros @p3, @arg, @ury2, @ury2, @usa, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.9.01 Preparación: designación válida en P3 (grupos) y en P4 (eliminación directa)
PRINT '--- P-2.9.01 Preparación: designación de árbitros de P3 y P4';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'),
        @ury1 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY1'), @ury2 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY2'),
        @deu1 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_DEU1'), @deu2 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_DEU2'),
        @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_USA'), @can INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_CAN'),
        @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_MEX'), @bra INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_BRA'),
        @adv VARCHAR(1000);
EXEC arbitraje.designar_arbitros @p3, @ury1, @ury2, @deu2, @usa, @deu1, @adv OUTPUT;
EXEC arbitraje.designar_arbitros @p4, @deu1, @deu2, @can, @mex, @bra, @adv OUTPUT;
-- SELECT * FROM arbitraje.designacion_arbitral ORDER BY designacion_id;
GO

-- F-2.9.02 Designar una terna en P3, que ya tiene árbitros designados => 1 error
PRINT '--- F-2.9.02 arbitraje.designar_arbitros: terna ya designada';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @ury1 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY1'),
        @ury2 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY2'), @deu1 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_DEU1'),
        @deu2 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_DEU2'), @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_USA');
BEGIN TRY EXEC arbitraje.designar_arbitros @p3, @ury1, @ury2, @deu2, @usa, @deu1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 2.10 Partido de eliminación directa completo (P4: Francia vs Japón, dieciseisavos)
-- ============================================================

-- F-2.10.01 Formación de Francia para P4 con el 4, suspendido por la roja directa de P1 => 1 error
PRINT '--- F-2.10.01 plantel.cargar_formacion: expulsado en el partido anterior';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'), @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'FRA');
DECLARE @con4 plantel.tt_formacion_jugador;
INSERT INTO @con4 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL;
BEGIN TRY EXEC plantel.cargar_formacion @p4, 'local', '4-2-3-1', @con4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.10.01 Preparación: formaciones de P4 (Francia sin el 4, Japón completa)
PRINT '--- P-2.10.01 Preparación: formaciones de P4';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'), @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'FRA'),
        @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'JPN'), @form INT;
DECLARE @sin4 plantel.tt_formacion_jugador, @japon plantel.tt_formacion_jugador;
INSERT INTO @sin4 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 12, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL AND c.dorsal <> 4;
INSERT INTO @japon SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @jpn AND c.fecha_baja IS NULL;
EXEC plantel.cargar_formacion @p4, 'local', '4-2-3-1', @sin4, @form OUTPUT;   INSERT INTO prueba.id VALUES ('P4_local', @form);
EXEC plantel.cargar_formacion @p4, 'visitante', '3-4-3', @japon, @form OUTPUT; INSERT INTO prueba.id VALUES ('P4_visitante', @form);
-- SELECT * FROM plantel.formacion ORDER BY formacion_id;
GO

-- P-2.10.02 Preparación: Japón hace 5 cambios en 3 ventanas del ST
PRINT '--- P-2.10.02 Preparación: cinco cambios de Japón en P4';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
EXEC evento.registrar_sustitucion @p4, 'visitante', 2, 12, 50, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 3, 13, 50, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 4, 14, 65, 'ST', 'lesion';
EXEC evento.registrar_sustitucion @p4, 'visitante', 5, 15, 65, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 6, 16, 80, 'ST', 'precaucion';
-- SELECT * FROM evento.sustitucion ORDER BY sustitucion_id;
GO

-- F-2.10.02 Sexto cambio de Japón en el ST: supera el máximo de cambios y de ventanas reglamentarios => 2 errores
PRINT '--- F-2.10.02 evento.registrar_sustitucion: sexto cambio en el tiempo reglamentario';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
BEGIN TRY EXEC evento.registrar_sustitucion @p4, 'visitante', 7, 17, 85, 'ST', 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.10.03 Preparación: en el alargue se acepta el 6.º cambio (cambio y ventana adicionales)
PRINT '--- P-2.10.03 Preparación: cambio adicional de Japón en el alargue';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
EXEC evento.registrar_sustitucion @p4, 'visitante', 7, 17, 95, 'alargue_1', 'tactico';
-- SELECT * FROM evento.sustitucion ORDER BY sustitucion_id;
GO

-- F-2.10.03 Séptimo cambio de Japón, en el segundo alargue: supera el máximo de cambios y de ventanas => 2 errores
PRINT '--- F-2.10.03 evento.registrar_sustitucion: séptimo cambio';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
BEGIN TRY EXEC evento.registrar_sustitucion @p4, 'visitante', 8, 18, 110, 'alargue_2', 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.10.04 Preparación: P4 termina 1 a 1 en los 120 minutos
PRINT '--- P-2.10.04 Preparación: goles de P4 (1 a 1)';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
EXEC evento.registrar_gol @p4, 'local', 9, 30, 'tiro_libre', 'PT';
EXEC evento.registrar_gol @p4, 'visitante', 10, 77, 'jugada', 'ST', 12;
-- SELECT * FROM evento.gol ORDER BY gol_id;
GO

-- F-2.10.04 Cerrar P4 empatado sin definición por penales (eliminación directa) => 1 error
PRINT '--- F-2.10.04 torneo.registrar_resultado: empate sin penales en eliminación directa';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
BEGIN TRY EXEC torneo.registrar_resultado @partido_id = @p4, @asistencia_publico = 70000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.10.05 Preparación: tanda de penales (Francia 2, Japón 1) y cierre de P4
PRINT '--- P-2.10.05 Preparación: penales y cierre de P4';
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
EXEC evento.registrar_gol @p4, 'local', 9, 120, 'penal', 'penales';
EXEC evento.registrar_gol @p4, 'visitante', 10, 120, 'penal', 'penales';
EXEC evento.registrar_gol @p4, 'local', 10, 120, 'penal', 'penales';
EXEC torneo.registrar_resultado @partido_id = @p4, @asistencia_publico = 70000;
-- SELECT * FROM evento.gol ORDER BY gol_id;
-- SELECT * FROM torneo.partido ORDER BY partido_id;
GO

-- P-2.10.06 Preparación: partido de grupos sin formaciones (México vs Japón), como llegaría de una importación
PRINT '--- P-2.10.06 Preparación: partido P5 sin detalle';
DECLARE @mx INT = (SELECT valor FROM prueba.id WHERE clave = 'sede_MX'), @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'MEX'),
        @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'JPN'), @p5 INT;
EXEC torneo.partido_insertar @mx, '2026-06-25T18:00:00-06:00', 'grupos', @mex, @jpn, NULL, @p5 OUTPUT;   INSERT INTO prueba.id VALUES ('P5', @p5);
-- SELECT * FROM torneo.partido ORDER BY partido_id;
GO

-- F-2.10.05 Cerrar P5, que no tiene detalle, sin informar los goles => 1 error
PRINT '--- F-2.10.05 torneo.registrar_resultado: partido sin detalle y sin goles';
DECLARE @p5 INT = (SELECT valor FROM prueba.id WHERE clave = 'P5');
BEGIN TRY EXEC torneo.registrar_resultado @partido_id = @p5; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- P-2.10.07 Preparación: cierre de P5 informando 2 a 0
PRINT '--- P-2.10.07 Preparación: cierre de P5';
DECLARE @p5 INT = (SELECT valor FROM prueba.id WHERE clave = 'P5');
EXEC torneo.registrar_resultado @p5, 2, 0, NULL, NULL, 60000;
-- SELECT * FROM torneo.partido ORDER BY partido_id;
GO

-- ============================================================
-- 2.11 Transaccionalidad: todo o nada en operaciones que afectan varias tablas
-- ============================================================

-- F-2.11.01 En una transacción, un gol válido de Argentina en P3 y uno inválido (minuto 200): el segundo falla y la
--           transacción se deshace completa (tampoco queda el primer gol) => 1 error
PRINT '--- F-2.11.01 evento.registrar_gol: un error revierte el gol válido previo';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @mensaje VARCHAR(2100);
BEGIN TRY
    BEGIN TRANSACTION;
        EXEC evento.registrar_gol @p3, 'local', 9, 12, 'jugada', 'PT';
        EXEC evento.registrar_gol @p3, 'local', 9, 200, 'jugada', 'PT';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    SET @mensaje = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT @mensaje;
END CATCH;
GO

PRINT '################ PARTE 3: CASOS DETALLADOS POR SP ################';
GO

-- ============================================================
-- 3.0 Preparación de los datos de la Parte 3
-- ============================================================

PRINT '--- P-3.01 Preparación de torneo.parametro_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @h INT = (SELECT valor FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta'),
        @d INT = (SELECT valor FROM torneo.parametro WHERE clave = 'prime_time_hora_desde');
EXEC torneo.parametro_insertar 'tst_ins', 1, 'Base de insertar (para duplicados)';
EXEC torneo.parametro_insertar 'tst_mod', 10, 'Base de modificar';
EXEC torneo.parametro_insertar 'tst_elim', 5, 'Base de eliminar';
EXEC torneo.parametro_insertar 'tst_backup_hasta', @h, 'Respaldo de prime_time_hora_hasta';
EXEC torneo.parametro_insertar 'tst_backup_desde', @d, 'Respaldo de prime_time_hora_desde';
GO

PRINT '--- P-3.02 Preparación de torneo.pais_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
IF @conf IS NULL THROW 50000, 'No hay confederaciones en torneo.confederacion: cargar al menos una con torneo.confederacion_insertar.', 1; 
    -- SI TIRA EL SIGUIENTE  ERROR, HAY QUE EJECUTAR LA PREPARACION DE CONFEDERACIONES DE FORMA PREVIA PARA PODER CONTINUAR
DECLARE @pS INT, @pL INT, @pR INT, @pC INT, @pP INT, @pT INT, @anun INT, @camp INT, @x INT;
EXEC torneo.pais_insertar 'ZZI', 'Test Base Insertar', 'UTC-03', 1000;
EXEC torneo.pais_insertar 'ZZM', 'Test Modificar',      'UTC-03', 2000;
EXEC torneo.pais_insertar 'ZZN', 'Test Modificar Otro', 'UTC+01', 3000;
EXEC torneo.pais_insertar 'ZZE', 'Test Eliminar',       'UTC-03', 0;
EXEC torneo.pais_insertar 'ZZS', 'Test Con Sede',       'UTC-03', 0, @pS OUTPUT;
EXEC torneo.pais_insertar 'ZZL', 'Test Con Seleccion',  'UTC-03', 0, @pL OUTPUT;
EXEC torneo.pais_insertar 'ZZR', 'Test Con Arbitro',    'UTC-03', 0, @pR OUTPUT;
EXEC torneo.pais_insertar 'ZZC', 'Test Con Interes',    'UTC-03', 0, @pC OUTPUT;
EXEC torneo.pais_insertar 'ZZP', 'Test Con Pieza',      'UTC-03', 0, @pP OUTPUT;
EXEC torneo.pais_insertar 'ZZT', 'Test Con Todo',       'UTC-03', 0, @pT OUTPUT;
EXEC torneo.sede_insertar 'Estadio Test S', 'Ciudad Test', @pS, 50000, 'UTC-03', @x OUTPUT;
EXEC torneo.sede_insertar 'Estadio Test T', 'Ciudad Test', @pT, 50000, 'UTC-03', @x OUTPUT;

EXEC torneo.seleccion_insertar @pL, @conf, 'A', @x OUTPUT;
EXEC torneo.seleccion_insertar @pT, @conf, 'A', @x OUTPUT;

EXEC arbitraje.arbitro_insertar 'Test', 'PaisArbitroR', @pR, 'FIFA';
EXEC arbitraje.arbitro_insertar 'Test', 'PaisArbitroT', @pT, 'FIFA';

EXEC publicidad.anunciante_insertar 'PAIS_ANUN', NULL, NULL, @anun OUTPUT;
EXEC publicidad.campania_insertar @anun, 'PAIS_CAMP', '2026-06-01', '2026-07-19', @camp OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @camp, @pC;
EXEC publicidad.campania_pais_interes_insertar @camp, @pP;
EXEC publicidad.campania_pais_interes_insertar @camp, @pT;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'espanol', @pP, 1000, @x OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @camp, 'espanol', @pT, 1000, @x OUTPUT;
GO

PRINT '--- P-3.03 Preparación de torneo.confederacion_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @id INT, @x INT, @conmebol INT;
SET @id = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CAF');      IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE confederacion_id = @id) EXEC torneo.confederacion_eliminar @id;
SET @id = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CONCACAF'); IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE confederacion_id = @id) EXEC torneo.confederacion_eliminar @id;
SET @id = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'OFC');      IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE confederacion_id = @id) EXEC torneo.confederacion_eliminar @id;
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'CONMEBOL') EXEC torneo.confederacion_insertar 'CONMEBOL';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'UEFA')     EXEC torneo.confederacion_insertar 'UEFA';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'AFC')      EXEC torneo.confederacion_insertar 'AFC';
SET @conmebol = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CONMEBOL');
IF NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE confederacion_id = @conmebol)
BEGIN
    EXEC torneo.pais_insertar 'ZYC', 'Test Confederacion', 'UTC-03', 0, @id OUTPUT;
    EXEC torneo.seleccion_insertar @id, @conmebol, 'A', @x OUTPUT;
END;
GO

PRINT '--- P-3.04 Preparación de torneo.sede_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
IF @conf IS NULL THROW 50000, 'No hay confederaciones en torneo.confederacion: cargar al menos una con torneo.confederacion_insertar.', 1;
DECLARE @pa INT, @pb INT, @pc INT, @x INT, @s1 INT, @s2 INT, @sp INT, @part INT,
        @f DATETIMEOFFSET = '2026-06-15 15:00:00 -03:00';
EXEC torneo.pais_insertar 'ZSA', 'Test Sede Pais A', 'UTC-03', 0, @pa OUTPUT;
EXEC torneo.pais_insertar 'ZSB', 'Test Sede Pais B', 'UTC-03', 0, @pb OUTPUT;
EXEC torneo.pais_insertar 'ZSC', 'Test Sede Pais C', 'UTC-03', 0, @pc OUTPUT;
EXEC torneo.sede_insertar 'Test Sede Base',    'Ciudad Test',    @pa, 50000, 'UTC-03', @x  OUTPUT;
EXEC torneo.sede_insertar 'Test Sede Mod',     'Ciudad Mod',     @pa, 40000, 'UTC-03', @x  OUTPUT;
EXEC torneo.sede_insertar 'Test Sede Otra',    'Ciudad Mod',     @pa, 30000, 'UTC-03', @x  OUTPUT;
EXEC torneo.sede_insertar 'Test Sede Partido', 'Ciudad Partido', @pa, 50000, 'UTC-03', @sp OUTPUT;
EXEC torneo.sede_insertar 'Test Sede Elim',    'Ciudad Elim',    @pa, 20000, 'UTC-03', @x  OUTPUT;
EXEC torneo.seleccion_insertar @pa, @conf, 'A', @s1 OUTPUT;
EXEC torneo.seleccion_insertar @pb, @conf, 'A', @s2 OUTPUT;
EXEC torneo.partido_insertar @sp, @f, 'grupos', @s1, @s2, NULL, @part OUTPUT;
UPDATE torneo.partido SET asistencia_publico = 40000 WHERE partido_id = @part;
GO

PRINT '--- P-3.05 Preparación de torneo.seleccion_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
IF @c1 IS NULL THROW 50000, 'No hay confederaciones en torneo.confederacion: cargar al menos una con torneo.confederacion_insertar.', 1;
DECLARE @c2 INT = ISNULL((SELECT TOP 1 confederacion_id FROM torneo.confederacion WHERE confederacion_id > @c1 ORDER BY confederacion_id), @c1);
DECLARE @x INT, @pa INT, @pm INT, @po INT, @pp INT, @pr INT, @px INT, @pv INT, @pt INT, @pk INT,
        @sp INT, @sr INT, @sk INT, @sede INT, @part INT,
        @f1 DATETIMEOFFSET = '2026-06-15 15:00:00 -03:00',
        @f2 DATETIMEOFFSET = '2026-06-16 15:00:00 -03:00';

EXEC torneo.pais_insertar 'ZQA', 'Test Sel Pais A', 'UTC-03', 0, @pa OUTPUT;   -- selección Base
EXEC torneo.pais_insertar 'ZQM', 'Test Sel Pais M', 'UTC-03', 0, @pm OUTPUT;   -- selección Mod
EXEC torneo.pais_insertar 'ZQO', 'Test Sel Pais O', 'UTC-03', 0, @po OUTPUT;   -- selección Otra
EXEC torneo.pais_insertar 'ZQP', 'Test Sel Pais P', 'UTC-03', 0, @pp OUTPUT;   -- selección con partido
EXEC torneo.pais_insertar 'ZQR', 'Test Sel Pais R', 'UTC-03', 0, @pr OUTPUT;   -- rival de los partidos
EXEC torneo.pais_insertar 'ZQX', 'Test Sel Pais X', 'UTC-03', 0, @px OUTPUT;   -- selección a eliminar (sin dependencias)
EXEC torneo.pais_insertar 'ZQV', 'Test Sel Pais V', 'UTC-03', 0, @pv OUTPUT;   -- selección con convocatoria
EXEC torneo.pais_insertar 'ZQT', 'Test Sel Pais T', 'UTC-03', 0, @pt OUTPUT;   -- selección con cuerpo técnico
EXEC torneo.pais_insertar 'ZQK', 'Test Sel Pais K', 'UTC-03', 0, @pk OUTPUT;   -- selección con partido + convocatoria + cuerpo técnico
EXEC torneo.pais_insertar 'ZQB', 'Test Sel Pais B', 'UTC-03', 0, @x OUTPUT;    -- alta válida 1
EXEC torneo.pais_insertar 'ZQC', 'Test Sel Pais C', 'UTC-03', 0, @x OUTPUT;    -- alta válida 2
EXEC torneo.pais_insertar 'ZQD', 'Test Sel Pais D', 'UTC-03', 0, @x OUTPUT;    -- alta válida 3
EXEC torneo.pais_insertar 'ZQE', 'Test Sel Pais E', 'UTC-03', 0, @x OUTPUT;    -- alta válida 4
EXEC torneo.pais_insertar 'ZQL', 'Test Sel Pais L', 'UTC-03', 0, @x OUTPUT;    -- libre: NUNCA se usa en un caso válido (sirve para aislar errores)
EXEC torneo.pais_insertar 'ZQN', 'Test Sel Pais N', 'UTC-03', 0, @x OUTPUT;    -- destino libre para cambio de país en modificar

EXEC torneo.seleccion_insertar @pa, @c1, 'A', @x  OUTPUT;   -- Base
EXEC torneo.seleccion_insertar @pm, @c1, 'B', @x  OUTPUT;   -- Mod (sin partidos)
EXEC torneo.seleccion_insertar @po, @c1, 'C', @x  OUTPUT;   -- Otra
EXEC torneo.seleccion_insertar @pp, @c1, 'D', @sp OUTPUT;   -- con partido de grupos
EXEC torneo.seleccion_insertar @pr, @c1, 'D', @sr OUTPUT;   -- rival
EXEC torneo.seleccion_insertar @px, @c1, 'E', @x  OUTPUT;   -- Elim
EXEC torneo.seleccion_insertar @pv, @c1, 'F', @x  OUTPUT;   -- Convocatoria
EXEC torneo.seleccion_insertar @pt, @c1, 'G', @x  OUTPUT;   -- Cuerpo técnico
EXEC torneo.seleccion_insertar @pk, @c1, 'D', @sk OUTPUT;   -- Todo (partido + convocatoria + cuerpo técnico)
EXEC torneo.sede_insertar 'Test Sel Sede', 'Ciudad Sel', @pa, 50000, 'UTC-03', @sede OUTPUT;
EXEC torneo.partido_insertar @sede, @f1, 'grupos', @sp, @sr, NULL, @part OUTPUT;   -- Partido vs Rival
EXEC torneo.partido_insertar @sede, @f2, 'grupos', @sk, @sr, NULL, @part OUTPUT;   -- Todo vs Rival
DECLARE @jv INT, @jk INT, @sv INT = (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id = @pv),
        @st INT = (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id = @pt);
EXEC plantel.jugador_insertar 'Test SEL', 'Convocado V', '1995-03-15', 'delantero', NULL, @jv OUTPUT;
EXEC plantel.jugador_insertar 'Test SEL', 'Convocado K', '1995-03-15', 'delantero', NULL, @jk OUTPUT;
EXEC plantel.convocatoria_insertar @sv, @jv, 10, '2026-06-01', NULL;   -- selección con convocatoria
EXEC plantel.convocatoria_insertar @sk, @jk, 10, '2026-06-01', NULL;   -- selección con partido + convocatoria + cuerpo técnico
EXEC plantel.cuerpo_tecnico_insertar @st, 'Test SEL', 'CT T', 'otro';   -- selección con cuerpo técnico
EXEC plantel.cuerpo_tecnico_insertar @sk, 'Test SEL', 'CT K', 'otro';
GO

PRINT '--- P-3.06 Preparación de torneo.partido* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Ciertas validaciones de esta seccion necesitan que se ejecute la preparacion de convocatoria, tarjetas, etc
-- De lo contrario, no funcionaran de forma correta.
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
IF @conf IS NULL THROW 50000, 'No hay confederaciones en torneo.confederacion: cargar al menos una con torneo.confederacion_insertar.', 1;
DECLARE @pa INT, @pb INT, @pc INT, @pd INT, @pe INT,
        @a1 INT, @a2 INT, @a3 INT, @a4 INT, @b1 INT,
        @sb INT, @sm INT, @s5 INT, @sl INT, @x INT,
        @p_base INT, @p_mod INT, @p_fin INT, @p_form INT, @p_tarj INT,
        @p_susp INT, @p_arb INT, @p_pub INT, @p_all INT, @p_elim INT;
EXEC torneo.pais_insertar 'ZPA', 'Test Partido Pais A', 'UTC-03', 0, @pa OUTPUT;
EXEC torneo.pais_insertar 'ZPB', 'Test Partido Pais B', 'UTC-03', 0, @pb OUTPUT;
EXEC torneo.pais_insertar 'ZPC', 'Test Partido Pais C', 'UTC-03', 0, @pc OUTPUT;
EXEC torneo.pais_insertar 'ZPD', 'Test Partido Pais D', 'UTC-03', 0, @pd OUTPUT;
EXEC torneo.pais_insertar 'ZPE', 'Test Partido Pais E', 'UTC-03', 0, @pe OUTPUT;
EXEC torneo.sede_insertar 'Test Partido Sede Base',  'Ciudad Base',  @pa, 50000, 'UTC-03', @sb OUTPUT;
EXEC torneo.sede_insertar 'Test Partido Sede Mod',   'Ciudad Mod',   @pa, 50000, 'UTC-03', @sm OUTPUT;
EXEC torneo.sede_insertar 'Test Partido Sede Cinco', 'Ciudad Cinco', @pa, 50000, 'UTC-05', @s5 OUTPUT;
EXEC torneo.sede_insertar 'Test Partido Sede Libre', 'Ciudad Libre', @pa, 50000, 'UTC-03', @sl OUTPUT;

EXEC torneo.seleccion_insertar @pa, @conf, 'A', @a1 OUTPUT;
EXEC torneo.seleccion_insertar @pb, @conf, 'A', @a2 OUTPUT;
EXEC torneo.seleccion_insertar @pc, @conf, 'A', @a3 OUTPUT;
EXEC torneo.seleccion_insertar @pd, @conf, 'A', @a4 OUTPUT;
EXEC torneo.seleccion_insertar @pe, @conf, 'B', @b1 OUTPUT;

EXEC torneo.partido_insertar @sb, '2026-06-15 15:00:00 -03:00', 'grupos',        @a1, @a2, NULL, @p_base OUTPUT;  -- base para duplicados / sede ocupada / 24 h
EXEC torneo.partido_insertar @sm, '2026-06-20 15:00:00 -03:00', 'grupos',        @a3, @a4, NULL, @p_mod  OUTPUT;  -- partido a modificar
EXEC torneo.partido_insertar @sb, '2026-06-25 15:00:00 -03:00', 'octavos',       @a1, @a3, NULL, @p_fin  OUTPUT;  -- finalizado
EXEC torneo.partido_insertar @sb, '2026-06-30 15:00:00 -03:00', 'cuartos',       @a1, @a4, NULL, @p_form OUTPUT;  -- con formaciones
EXEC torneo.partido_insertar @sb, '2026-07-05 15:00:00 -03:00', 'cuartos',       @a2, @a3, NULL, @p_tarj OUTPUT;  -- con tarjetas
EXEC torneo.partido_insertar @sb, '2026-07-10 15:00:00 -03:00', 'semifinal',     @a1, @a2, NULL, @p_susp OUTPUT;  -- afectado por suspensiones
EXEC torneo.partido_insertar @sb, '2026-07-15 15:00:00 -03:00', 'tercer_puesto', @a1, @a2, NULL, @p_arb  OUTPUT;  -- con árbitros
EXEC torneo.partido_insertar @sb, '2026-07-20 15:00:00 -03:00', 'final',         @a1, @a2, NULL, @p_pub  OUTPUT;  -- con espacios publicitarios
EXEC torneo.partido_insertar @sb, '2026-07-25 15:00:00 -03:00', 'dieciseisavos', @a1, @a2, NULL, @p_all  OUTPUT;  -- finalizado + todas las dependencias
EXEC torneo.partido_insertar @sb, '2026-07-30 15:00:00 -03:00', 'dieciseisavos', @a3, @a4, NULL, @p_elim OUTPUT;  -- sin dependencias (baja válida)
-- Dependencias de los partidos de prueba (p_form, p_tarj, p_susp, p_arb, p_pub y p_all con todas)
DECLARE @arb INT, @ct1 INT, @ct2 INT, @ct3 INT, @p_src INT, @t INT, @f INT;
EXEC arbitraje.arbitro_insertar 'Test', 'Arbitro Partido', @pe, 'FIFA', NULL, @arb OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @a1, 'Test PA', 'CT A1', 'otro', @x OUTPUT, @ct1 OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @a2, 'Test PA', 'CT A2', 'otro', @x OUTPUT, @ct2 OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @a3, 'Test PA', 'CT A3', 'otro', @x OUTPUT, @ct3 OUTPUT;
EXEC torneo.partido_insertar @sl, '2026-07-02 15:00:00 -03:00', 'octavos', @a1, @a2, NULL, @p_src OUTPUT;  -- origen de las rojas
EXEC plantel.formacion_insertar @p_form, 'local', '4-4-2', @f OUTPUT;
EXEC plantel.formacion_insertar @p_all,  'local', '4-4-2', @f OUTPUT;
EXEC evento.tarjeta_insertar @p_tarj, @ct3, 10, 'PT', 'amarilla', 'Protesta', NULL, @tarjeta_id = @t OUTPUT;
EXEC evento.tarjeta_insertar @p_all,  @ct1, 10, 'PT', 'amarilla', 'Protesta', NULL, @tarjeta_id = @t OUTPUT;
EXEC evento.tarjeta_insertar @p_src,  @ct2, 20, 'PT', 'roja', 'Insultos', 'roja_directa', @tarjeta_id = @t OUTPUT;
EXEC evento.suspension_insertar @t, 'Roja directa', NULL, @p_susp;
EXEC evento.tarjeta_insertar @p_src,  @ct1, 30, 'PT', 'roja', 'Insultos', 'roja_directa', @tarjeta_id = @t OUTPUT;
EXEC evento.suspension_insertar @t, 'Roja directa', NULL, @p_all;
EXEC arbitraje.designacion_arbitral_insertar @p_arb, @arb, 'principal';
EXEC arbitraje.designacion_arbitral_insertar @p_all, @arb, 'principal';
EXEC publicidad.espacio_publicitario_insertar @p_pub, 1, NULL, NULL;
EXEC publicidad.espacio_publicitario_insertar @p_all, 1, NULL, NULL;
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id IN (@p_fin, @p_all);
GO

PRINT '--- P-3.07 Preparación de plantel.cuerpo_tecnico_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
IF @conf IS NULL THROW 50000, 'No hay confederaciones en torneo.confederacion: cargar al menos una con torneo.confederacion_insertar.', 1;
DECLARE @pa INT, @pb INT, @pc INT, @s1 INT, @s2 INT, @s3 INT, @x INT, @pt INT;
EXEC torneo.pais_insertar 'ZCA', 'Test CT Pais A', 'UTC-03', 0, @pa OUTPUT;
EXEC torneo.pais_insertar 'ZCB', 'Test CT Pais B', 'UTC-03', 0, @pb OUTPUT;
EXEC torneo.pais_insertar 'ZCC', 'Test CT Pais C', 'UTC-03', 0, @pc OUTPUT;
EXEC torneo.seleccion_insertar @pa, @conf, 'A', @s1 OUTPUT;
EXEC torneo.seleccion_insertar @pb, @conf, 'A', @s2 OUTPUT;
EXEC torneo.seleccion_insertar @pc, @conf, 'A', @s3 OUTPUT;

EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Director',  'director_tecnico',  @x OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Ayudante',  'ayudante_tecnico',  @x OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Mod',       'otro',              @x OUTPUT;  
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Otra',      'preparador_fisico', @x OUTPUT;  
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Elim',      'otro',              @x OUTPUT;  
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Elim Tran', 'otro',              @x OUTPUT;  
EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test CT', 'Tarjeta',   'otro',              @x OUTPUT, @pt OUTPUT;  
GO

PRINT '--- P-3.08 Preparación de plantel.jugador_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @x INT;
EXEC plantel.jugador_insertar 'Test JU', 'Base',      '1995-03-15', 'delantero',     'Club Test', @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Mod',       '1995-03-15', 'defensor',      'Club Mod',  @x OUTPUT; 
EXEC plantel.jugador_insertar 'Test JU', 'Otro',      '1995-03-15', 'arquero',       NULL,        @x OUTPUT; 
EXEC plantel.jugador_insertar 'Test JU', 'Elim',      '1995-03-15', 'mediocampista', NULL,        @x OUTPUT; 
EXEC plantel.jugador_insertar 'Test JU', 'Elim Tran', '1995-03-15', 'mediocampista', NULL,        @x OUTPUT; 
EXEC plantel.jugador_insertar 'Test JU', 'Convocado', '1995-03-15', 'delantero',     NULL,        @x OUTPUT; 
EXEC plantel.jugador_insertar 'Test JU', 'Formacion', '1995-03-15', 'defensor',      NULL,        @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Tarjeta',   '1995-03-15', 'arquero',       NULL,        @x OUTPUT;
GO

PRINT '--- P-3.09 Preparación de plantel.persona_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
IF OBJECT_ID('prueba.test_persona', 'U') IS NULL
    CREATE TABLE prueba.test_persona (persona_id INT NOT NULL PRIMARY KEY, clave VARCHAR(10) NOT NULL);
DECLARE @id INT;
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO prueba.test_persona VALUES (@id, 'mod');      -- persona a modificar (sin registros asociados)
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO prueba.test_persona VALUES (@id, 'elim');     -- baja valida (tipo jugador, sin registros)
EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT; INSERT INTO prueba.test_persona VALUES (@id, 'elim_ct'); -- baja valida (tipo cuerpo_tecnico, sin registros)
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO prueba.test_persona VALUES (@id, 'jug');      -- registrada en plantel.jugador
EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT; INSERT INTO prueba.test_persona VALUES (@id, 'ct');      -- registrada en plantel.cuerpo_tecnico
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO prueba.test_persona VALUES (@id, 'tarj');     -- con tarjetas
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO prueba.test_persona VALUES (@id, 'todo');     -- jugador + cuerpo tecnico + tarjetas
GO

PRINT '--- P-3.10 Preparación de plantel.convocatoria_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes las preparaciones de plantel.cuerpo_tecnico_* (selecciones ZCA/ZCB/ZCC) y plantel.jugador_* (jugadores 'Test JU').
-- Datos fijos para las futuras preparaciones (formacion_jugador, etc.): s1 = ZCA: 'Convocado' (dorsal 10) y 'Formacion' (dorsal 3) quedan convocados vigentes.
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @x INT, @c INT, @j INT, @i INT = 1, @ap VARCHAR(100);

IF @s1 IS NULL OR @s2 IS NULL OR @s3 IS NULL
    THROW 50000, 'Faltan las selecciones de prueba (ZCA/ZCB/ZCC): ejecutar antes la preparación de plantel.cuerpo_tecnico_*.', 1;
IF (SELECT COUNT(*) FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Convocado', 'Formacion')) < 2
    THROW 50000, 'Faltan los jugadores Test JU Convocado y Formacion: ejecutar antes la preparación de plantel.jugador_*.', 1;
IF NOT EXISTS (SELECT 1 FROM torneo.parametro WHERE clave = 'convocatoria_max_jugadores')
    THROW 50000, 'Falta el parámetro convocatoria_max_jugadores en torneo.parametro.', 1;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Mod',      '1995-03-15', 'delantero', NULL, @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Baja Mod', '1995-03-15', 'delantero', NULL, @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Otro',     '1995-03-15', 'delantero', NULL, @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Baja',     '1995-03-15', 'delantero', NULL, @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Baja 2',   '1995-03-15', 'delantero', NULL, @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Otra Sel', '1995-03-15', 'delantero', NULL, @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Elim',      '1995-03-15', 'delantero', NULL, @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Elim Baja', '1995-03-15', 'delantero', NULL, @x OUTPUT;
EXEC plantel.jugador_insertar 'Test JU', 'Conv Libre Err', '1995-03-15', 'delantero', NULL, @x OUTPUT;  
WHILE @i <= 10  
BEGIN
    SET @ap = 'Conv Libre ' + CAST(@i AS VARCHAR(2));
    EXEC plantel.jugador_insertar 'Test JU', @ap, '1995-03-15', 'delantero', NULL, @x OUTPUT;
    SET @i += 1;
END;
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Convocado');
EXEC plantel.convocatoria_insertar @s1, @j, 10, '2026-06-01', 'Convocatoria inicial', @c OUTPUT;
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Formacion');
EXEC plantel.convocatoria_insertar @s1, @j, 3, '2026-06-01', 'Convocatoria inicial', @c OUTPUT;
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Mod');
EXEC plantel.convocatoria_insertar @s1, @j, 7, '2026-06-01', 'Motivo inicial', @c OUTPUT;
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Baja Mod');
EXEC plantel.convocatoria_insertar @s1, @j, 9, '2026-06-01', 'Motivo inicial', @c OUTPUT;
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Otro');
EXEC plantel.convocatoria_insertar @s1, @j, 8, '2026-06-01', 'Motivo inicial', @c OUTPUT;
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Elim');
EXEC plantel.convocatoria_insertar @s1, @j, 13, '2026-06-01', NULL, @c OUTPUT;
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Baja');
EXEC plantel.convocatoria_insertar @s1, @j, 5, '2026-05-01', 'Convocatoria inicial', @c OUTPUT;
EXEC plantel.convocatoria_modificar @c, 5, '2026-05-01', 'Convocatoria inicial', '2026-05-20', 'Lesion';
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Baja 2');
EXEC plantel.convocatoria_insertar @s1, @j, 4, '2026-05-01', 'Convocatoria inicial', @c OUTPUT;
EXEC plantel.convocatoria_modificar @c, 4, '2026-05-01', 'Convocatoria inicial', '2026-05-20', 'Lesion';
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Elim Baja');
EXEC plantel.convocatoria_insertar @s1, @j, 15, '2026-05-01', NULL, @c OUTPUT;
EXEC plantel.convocatoria_modificar @c, 15, '2026-05-01', NULL, '2026-05-20', 'Lesion';
SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Otra Sel');
EXEC plantel.convocatoria_insertar @s2, @j, 11, '2026-06-01', 'Motivo inicial', @c OUTPUT;
GO

PRINT '--- P-3.11 Preparación de plantel.formacion_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes la preparación de plantel.cuerpo_tecnico_* (selecciones ZCA/ZCB/ZCC, todas del grupo 'A') y al menos una sede en torneo.sede.
IF OBJECT_ID('prueba.test_formacion', 'U') IS NULL
    CREATE TABLE prueba.test_formacion (clave VARCHAR(10) NOT NULL PRIMARY KEY, partido_id INT NOT NULL, formacion_id INT NULL);
GO
IF EXISTS (SELECT 1 FROM prueba.test_formacion)
    THROW 50000, 'La preparación de plantel.formacion_* ya fue ejecutada en esta base (ver prueba.test_formacion).', 1;
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @sede INT = (SELECT TOP 1 sede_id FROM torneo.sede ORDER BY sede_id),
        @huso CHAR(6),
        @min INT,
        @base DATETIME2 = '2030-06-10 18:00',  -- cambiar si choca con partidos existentes en la sede
        @t DATETIMEOFFSET,
        @pm INT, @pe INT, @pa INT, @pb INT, @pc INT, @pf INT, @f INT;
IF @s1 IS NULL OR @s2 IS NULL OR @s3 IS NULL
    THROW 50000, 'Faltan las selecciones de prueba (ZCA/ZCB/ZCC): ejecutar antes la preparación de plantel.cuerpo_tecnico_*.', 1;
IF @sede IS NULL
    THROW 50000, 'No hay sedes en torneo.sede: cargar al menos una.', 1;
SELECT @huso = huso_horario FROM torneo.sede WHERE sede_id = @sede;
SET @min = CAST(SUBSTRING(@huso, 4, 3) AS INT) * 60;
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 0,  @base), @min); EXEC torneo.partido_insertar @sede, @t, 'grupos',    @s2, @s1, @partido_id = @pm OUTPUT;  -- mod/jug (ZCA visitante)
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 3,  @base), @min); EXEC torneo.partido_insertar @sede, @t, 'grupos',    @s1, @s3, @partido_id = @pe OUTPUT;  -- elim/elim2
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 6,  @base), @min); EXEC torneo.partido_insertar @sede, @t, 'grupos',    @s2, @s3, @partido_id = @pa OUTPUT;  -- ins_a
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 9,  @base), @min); EXEC torneo.partido_insertar @sede, @t, 'octavos',   @s1, @s2, @partido_id = @pb OUTPUT;  -- ins_b
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 12, @base), @min); EXEC torneo.partido_insertar @sede, @t, 'cuartos',   @s1, @s3, @partido_id = @pc OUTPUT;  -- ins_c
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 15, @base), @min); EXEC torneo.partido_insertar @sede, @t, 'semifinal', @s2, @s3, @partido_id = @pf OUTPUT;  -- fin
INSERT INTO prueba.test_formacion (clave, partido_id) VALUES ('ins_a', @pa), ('ins_b', @pb), ('ins_c', @pc);
EXEC plantel.formacion_insertar @pm, 'local',     '4-4-2', @f OUTPUT; INSERT INTO prueba.test_formacion VALUES ('mod',   @pm, @f);  -- a modificar / ya tiene formacion local
EXEC plantel.formacion_insertar @pm, 'visitante', '4-3-3', @f OUTPUT; INSERT INTO prueba.test_formacion VALUES ('jug',   @pm, @f);  -- ZCA, reservada para formacion_jugador (con jugadores)
EXEC plantel.formacion_insertar @pe, 'local',     '4-4-2', @f OUTPUT; INSERT INTO prueba.test_formacion VALUES ('elim',  @pe, @f);  -- baja valida
EXEC plantel.formacion_insertar @pe, 'visitante', '4-3-3', @f OUTPUT; INSERT INTO prueba.test_formacion VALUES ('elim2', @pe, @f);  -- baja valida
EXEC plantel.formacion_insertar @pf, 'local', '4-4-2', @f OUTPUT; INSERT INTO prueba.test_formacion VALUES ('fin', @pf, @f);
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pf;
GO

PRINT '--- P-3.12 Preparación de plantel.formacion_jugador_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes, en esta misma ventana: plantel.cuerpo_tecnico_* (ZCA/ZCB/ZCC), plantel.jugador_* (Test JU),
-- plantel.convocatoria_* ('Convocado' y 'Formacion' convocados en ZCA) y plantel.formacion_* (prueba.test_formacion).
IF OBJECT_ID('prueba.test_formacion', 'U') IS NULL
    THROW 50000, 'Falta prueba.test_formacion: ejecutar antes la preparación de plantel.formacion_*.', 1;
IF NOT EXISTS (SELECT 1 FROM prueba.test_formacion WHERE clave = 'jug')
    THROW 50000, 'Falta la formación jug en prueba.test_formacion: ejecutar antes la preparación de plantel.formacion_*.', 1;

IF OBJECT_ID('prueba.test_fjugador', 'U') IS NULL
    CREATE TABLE prueba.test_fjugador (clave VARCHAR(12) NOT NULL PRIMARY KEY, formacion_id INT NULL, jugador_id INT NOT NULL);
IF EXISTS (SELECT 1 FROM prueba.test_fjugador)
    THROW 50000, 'La preparación de plantel.formacion_jugador_* ya fue ejecutada en esta base (ver prueba.test_fjugador).', 1;

DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @sede INT = (SELECT TOP 1 sede_id FROM torneo.sede ORDER BY sede_id),
        @huso CHAR(6), @min INT, @base DATETIME2, @t DATETIMEOFFSET,
        @maxT INT, @maxS INT, @maxC INT,
        @pl INT, @pf INT, @fl INT, @fs INT, @ff INT, @dia DATE,
        @i INT, @n INT, @j INT, @c INT, @x INT, @ap VARCHAR(100),
        @sel INT, @d INT, @a DATE, @b DATE, @pos VARCHAR(30), @tit BIT, @fid INT, @cargar BIT;

IF @s1 IS NULL OR @s2 IS NULL OR @s3 IS NULL
    THROW 50000, 'Faltan las selecciones de prueba (ZCA/ZCB/ZCC): ejecutar antes la preparación de plantel.cuerpo_tecnico_*.', 1;
IF @sede IS NULL
    THROW 50000, 'No hay sedes en torneo.sede: cargar al menos una.', 1;
IF (SELECT COUNT(*) FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
    WHERE c.seleccion_id = @s1 AND c.fecha_baja IS NULL AND j.nombre = 'Test JU' AND j.apellido IN ('Convocado', 'Formacion')) < 2
    THROW 50000, 'Convocado y Formacion no están convocados vigentes en ZCA: ejecutar antes la preparación de plantel.convocatoria_*.', 1;

SELECT @maxT = valor FROM torneo.parametro WHERE clave = 'formacion_titulares';
SELECT @maxS = valor FROM torneo.parametro WHERE clave = 'formacion_max_suplentes';
SELECT @maxC = valor FROM torneo.parametro WHERE clave = 'convocatoria_max_jugadores';
IF @maxT IS NULL OR @maxS IS NULL OR @maxC IS NULL
    THROW 50000, 'Faltan los parámetros formacion_titulares, formacion_max_suplentes y/o convocatoria_max_jugadores en torneo.parametro.', 1;
IF @maxT < 9 OR @maxS < 7
    THROW 50000, 'Esta preparación necesita formacion_titulares >= 9 y formacion_max_suplentes >= 7.', 1;

-- Cupo de convocatorias vigentes
IF (SELECT COUNT(*) FROM plantel.convocatoria WHERE seleccion_id = @s1 AND fecha_baja IS NULL) + 14 > @maxC
    THROW 50000, 'ZCA no tiene cupo en convocatoria_max_jugadores para los 14 jugadores de prueba: dar de baja convocatorias de prueba o subir el parámetro.', 1;
IF (SELECT COUNT(*) FROM plantel.convocatoria WHERE seleccion_id = @s2 AND fecha_baja IS NULL) + @maxT + 8 > @maxC
    THROW 50000, 'ZCB no tiene cupo en convocatoria_max_jugadores para los jugadores de prueba: dar de baja convocatorias de prueba o subir el parámetro.', 1;
IF (SELECT COUNT(*) FROM plantel.convocatoria WHERE seleccion_id = @s3 AND fecha_baja IS NULL) + @maxS + 3 > @maxC
    THROW 50000, 'ZCC no tiene cupo en convocatoria_max_jugadores para los jugadores de prueba: dar de baja convocatorias de prueba o subir el parámetro.', 1;

-- Partidos nuevos (después de los de la preparación de formacion_*, un dia distinto cada uno)
SELECT @huso = huso_horario FROM torneo.sede WHERE sede_id = @sede;
SET @min = CAST(SUBSTRING(@huso, 4, 3) AS INT) * 60;
SET @base = DATEADD(DAY, 3, (SELECT CAST(MAX(p.fecha_hora_local) AS DATETIME2) FROM torneo.partido p JOIN prueba.test_formacion t ON t.partido_id = p.partido_id));
SET @t = TODATETIMEOFFSET(@base, @min);                    EXEC torneo.partido_insertar @sede, @t, 'dieciseisavos', @s2, @s3, @partido_id = @pl OUTPUT;  -- ZCB local vs ZCC visitante
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 3, @base), @min);   EXEC torneo.partido_insertar @sede, @t, 'dieciseisavos', @s1, @s2, @partido_id = @pf OUTPUT;  -- ZCA local vs ZCB (se finaliza al final)
SET @dia = (SELECT CAST(fecha_hora_utc AS DATE) FROM torneo.partido WHERE partido_id = @pl);  -- fecha que usa el SP para validar la convocatoria
EXEC plantel.formacion_insertar @pl, 'local',     '4-4-2', @fl OUTPUT;  -- ZCB
EXEC plantel.formacion_insertar @pl, 'visitante', '4-3-3', @fs OUTPUT;  -- ZCC
EXEC plantel.formacion_insertar @pf, 'local',     '4-4-2', @ff OUTPUT;  -- ZCA (partido a finalizar)
INSERT INTO prueba.test_formacion VALUES ('fl_tit', @pl, @fl), ('fl_sup', @pl, @fs), ('fj_fin', @pf, @ff);
-- Jugadores nuevos
DECLARE @nuevos TABLE (n INT IDENTITY(1,1), clave VARCHAR(12), apellido VARCHAR(100), seleccion_id INT, dorsal INT,
                       fecha_alta DATE, fecha_baja DATE, destino VARCHAR(10), cargar BIT, titular BIT, posicion VARCHAR(30));
INSERT INTO @nuevos (clave, apellido, seleccion_id, dorsal, fecha_alta, fecha_baja, destino, cargar, titular, posicion) VALUES
 ('sust_sale',  'FJ Sust Sale',  @s1, 31, '2026-06-01', NULL, 'jug',    1, 1,    'Defensor'),
 ('sust_entra', 'FJ Sust Entra', @s1, 32, '2026-06-01', NULL, 'jug',    1, 0,    'Mediocampista'),
 ('gol',        'FJ Gol',        @s1, 33, '2026-06-01', NULL, 'jug',    1, 1,    'Delantero'),
 ('asis',       'FJ Asis',       @s1, 34, '2026-06-01', NULL, 'jug',    1, 1,    'Mediocampista'),
 ('tarj',       'FJ Tarjeta',    @s1, 35, '2026-06-01', NULL, 'jug',    1, 1,    'Defensor'),
 ('elim',       'FJ Elim',       @s1, 36, '2026-06-01', NULL, 'jug',    1, 0,    'Arquero'),
 ('susp',       'FJ Suspendido', @s1, 37, '2026-06-01', NULL, 'jug',    0, NULL, NULL),
 ('fin',        'FJ Fin',        @s1, 39, '2026-06-01', NULL, 'fj_fin', 1, 1,    'Delantero'),
 ('q1',         'FJ Dorsal Q1',  @s1, 40, '2026-06-01', NULL, 'jug',    1, 1,    'Delantero'),
 ('q2',         'FJ Dorsal Q2',  @s1, 41, '2026-06-01', NULL, 'jug',    1, 0,    'Defensor'),
 ('r',          'FJ Dorsal R',   @s1, 42, '2026-06-01', NULL, 'jug',    1, 0,    'Defensor'),
 ('s',          'FJ Dorsal S',   @s1, 43, '2026-06-01', NULL, 'jug',    1, 1,    'Defensor'),
 ('z_baja',     'FJ Conv Baja',  @s1, 48, '2026-06-01', NULL, 'jug',    1, 0,    'Defensor'),
 ('p',          'FJ Dorsal P',   NULL, NULL, NULL,      NULL, 'jug',    0, NULL, NULL),   -- su convocatoria (dorsal 40) se crea despues de mover la de q1
 ('sin_conv',   'FJ Sin Conv',   NULL, NULL, NULL,      NULL, 'jug',    0, NULL, NULL);   -- nunca tiene convocatoria
-- ZCB: titulares completos + 1 suplente cargado; libres para altas y casos de fechas de convocatoria
INSERT INTO @nuevos (clave, apellido, seleccion_id, dorsal, fecha_alta, fecha_baja, destino, cargar, titular, posicion)
SELECT 'tit_' + CAST(v.n AS VARCHAR(3)), 'FJ Tit ' + CAST(v.n AS VARCHAR(3)), @s2, 30 + v.n, '2026-06-01', NULL, 'fl_tit', 1, 1, 'Defensor'
FROM (SELECT TOP (@maxT) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) v
ORDER BY v.n;
INSERT INTO @nuevos (clave, apellido, seleccion_id, dorsal, fecha_alta, fecha_baja, destino, cargar, titular, posicion) VALUES
 ('tit_sup',   'FJ Tit Sup',    @s2, 30 + @maxT + 1, '2026-06-01', NULL,                    'fl_tit', 1, 0,    'Defensor'),
 ('tit_extra', 'FJ Tit Extra',  @s2, 30 + @maxT + 2, '2026-06-01', NULL,                    'fl_tit', 0, NULL, NULL),
 ('lib_1',     'FJ Libre 1',    @s2, 30 + @maxT + 3, '2026-06-01', NULL,                    'fl_tit', 0, NULL, NULL),
 ('lib_2',     'FJ Libre 2',    @s2, 30 + @maxT + 4, '2026-06-01', NULL,                    'fl_tit', 0, NULL, NULL),
 ('lib_3',     'FJ Libre 3',    @s2, 30 + @maxT + 5, '2026-06-01', NULL,                    'fl_tit', 0, NULL, NULL),
 ('alta_dia',  'FJ Alta Dia',   @s2, 30 + @maxT + 6, @dia,         NULL,                    'fl_tit', 0, NULL, NULL),
 ('futuro',    'FJ Futuro',     @s2, 30 + @maxT + 7, DATEADD(DAY, 1, @dia), NULL,           'fl_tit', 0, NULL, NULL),
 ('hist',      'FJ Historico',  @s2, 30 + @maxT + 8, '2026-05-01', '2026-05-20',            'fl_tit', 0, NULL, NULL),
 ('baja_dia',  'FJ Baja Dia',   @s2, 30 + @maxT + 9, '2026-05-01', @dia,                    'fl_tit', 0, NULL, NULL);
-- ZCC: banco de suplentes completo + 1 titular cargado; libres para altas
INSERT INTO @nuevos (clave, apellido, seleccion_id, dorsal, fecha_alta, fecha_baja, destino, cargar, titular, posicion)
SELECT 'sup_' + CAST(v.n AS VARCHAR(3)), 'FJ Sup ' + CAST(v.n AS VARCHAR(3)), @s3, 30 + v.n, '2026-06-01', NULL, 'fl_sup', 1, 0, 'Mediocampista'
FROM (SELECT TOP (@maxS) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM sys.all_objects) v
ORDER BY v.n;
INSERT INTO @nuevos (clave, apellido, seleccion_id, dorsal, fecha_alta, fecha_baja, destino, cargar, titular, posicion) VALUES
 ('sup_tit',   'FJ Sup Tit',    @s3, 30 + @maxS + 1, '2026-06-01', NULL, 'fl_sup', 1, 1,    'Delantero'),
 ('sup_extra', 'FJ Sup Extra',  @s3, 30 + @maxS + 2, '2026-06-01', NULL, 'fl_sup', 0, NULL, NULL),
 ('sup_nuevo', 'FJ Sup Nuevo',  @s3, 30 + @maxS + 3, '2026-06-01', NULL, 'fl_sup', 0, NULL, NULL);

SET @i = 1; SET @n = (SELECT COUNT(*) FROM @nuevos);
WHILE @i <= @n
BEGIN
    SELECT @ap = apellido, @sel = seleccion_id, @d = dorsal, @a = fecha_alta, @b = fecha_baja FROM @nuevos WHERE n = @i;
    EXEC plantel.jugador_insertar 'Test JU', @ap, '1995-03-15', 'delantero', NULL, @x OUTPUT;
    IF @sel IS NOT NULL
    BEGIN
        SET @j = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = @ap);
        EXEC plantel.convocatoria_insertar @sel, @j, @d, @a, 'Convocatoria FJ', @c OUTPUT;
        IF @b IS NOT NULL
            EXEC plantel.convocatoria_modificar @c, @d, @a, 'Convocatoria FJ', @b, 'Baja FJ';
    END;
    SET @i += 1;
END;
-- Claves para las verificaciones y para las futuras preparaciones
INSERT INTO prueba.test_fjugador (clave, formacion_id, jugador_id)
SELECT n.clave, CASE n.destino WHEN 'jug' THEN @fj WHEN 'fl_tit' THEN @fl WHEN 'fl_sup' THEN @fs WHEN 'fj_fin' THEN @ff END, j.jugador_id
FROM @nuevos n JOIN plantel.jugador j ON j.nombre = 'Test JU' AND j.apellido = n.apellido;
INSERT INTO prueba.test_fjugador (clave, formacion_id, jugador_id)
SELECT 'base', @fj, jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Convocado';
INSERT INTO prueba.test_fjugador (clave, formacion_id, jugador_id)
SELECT 'ins', @fj, jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Formacion';
-- Formaciones
SET @j = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
EXEC plantel.formacion_jugador_insertar @fj, @j, 'Delantero', 1;   -- Convocado (dorsal 10), titular
SET @i = 1;
WHILE @i <= @n
BEGIN
    SELECT @j = j.jugador_id, @pos = n.posicion, @tit = n.titular, @cargar = n.cargar,
           @fid = CASE n.destino WHEN 'jug' THEN @fj WHEN 'fl_tit' THEN @fl WHEN 'fl_sup' THEN @fs WHEN 'fj_fin' THEN @ff END
    FROM @nuevos n JOIN plantel.jugador j ON j.nombre = 'Test JU' AND j.apellido = n.apellido
    WHERE n.n = @i;
    IF @cargar = 1 EXEC plantel.formacion_jugador_insertar @fid, @j, @pos, @tit;
    SET @i += 1;
END;
-- Dorsales:
SET @j = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'q1');   -- stored 40 -> convocatoria pasa a 50
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 50, '2026-06-01', 'Convocatoria FJ', NULL, NULL;
SET @j = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'q2');   -- stored 41 -> convocatoria pasa a 51
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 51, '2026-06-01', 'Convocatoria FJ', NULL, NULL;
SET @j = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 's');    -- stored 43 -> convocatoria pasa a 52 (sincronizacion de dorsal en modificar)
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 52, '2026-06-01', 'Convocatoria FJ', NULL, NULL;
SET @j = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'r');    -- stored 42 -> convocatoria pasa a 41 (el que conserva q2 en la formacion)
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 41, '2026-06-01', 'Convocatoria FJ', NULL, NULL;
SET @j = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'p');    -- convocatoria nueva con el dorsal 40 (el que conserva q1 en la formacion)
EXEC plantel.convocatoria_insertar @s1, @j, 40, '2026-06-01', 'Convocatoria FJ', @c OUTPUT;
SET @j = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'z_baja');  -- queda en la formacion con la convocatoria dada de baja antes del partido
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 48, '2026-06-01', 'Convocatoria FJ', '2026-07-01', 'Baja FJ';
-- Partido finalizado: se carga primero (el SP rechaza partidos finalizados) y luego se finaliza
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pf;
GO

PRINT '--- P-3.13 Preparación de evento.sustitucion_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes, en esta misma ventana: plantel.cuerpo_tecnico_* (ZCA/ZCB/ZCC), plantel.jugador_*, plantel.convocatoria_*,
-- plantel.formacion_* (prueba.test_formacion) y plantel.formacion_jugador_* (prueba.test_fjugador).
-- No crea jugadores ni convocatorias nuevos: reutiliza los jugadores de ZCB y ZCC (convocados vigentes)
-- Parámetros necesarios en torneo.parametro: cambios_max_reglamentarios (>= 5), ventanas_max_reglamentarias (>= 2 y menor que cambios_max_reglamentarios),
IF OBJECT_ID('prueba.test_fjugador', 'U') IS NULL
    THROW 50000, 'Falta prueba.test_fjugador: ejecutar antes la preparación de plantel.formacion_jugador_*.', 1;
IF OBJECT_ID('prueba.test_sustitucion', 'U') IS NULL
    CREATE TABLE prueba.test_sustitucion (clave VARCHAR(12) NOT NULL PRIMARY KEY, formacion_id INT NULL, jugador_id INT NULL, sustitucion_id INT NULL);
GO
IF EXISTS (SELECT 1 FROM prueba.test_sustitucion)
    THROW 50000, 'La preparación de evento.sustitucion_* ya fue ejecutada en esta base (ver prueba.test_sustitucion).', 1;
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @sede INT = (SELECT TOP 1 sede_id FROM torneo.sede ORDER BY sede_id),
        @huso CHAR(6), @off INT, @base DATETIME2, @t DATETIMEOFFSET,
        @C INT, @V INT, @X INT, @W INT, @maxT INT, @maxS INT,
        @p1 INT, @p2 INT, @p3 INT, @p4 INT, @p5 INT,
        @f_ok INT, @f_gen INT, @f_eli INT, @f_alg INT, @f_lim INT, @f_fin INT,
        @nb INT, @nc INT, @i INT, @k INT, @n INT, @j INT, @fid INT, @tit BIT, @pos VARCHAR(30),
        @pref VARCHAR(6), @nreg INT, @nalg INT, @per VARCHAR(15), @mn INT, @ven INT, @mot VARCHAR(15),
        @sale INT, @entra INT, @sid INT;
IF @s1 IS NULL OR @s2 IS NULL OR @s3 IS NULL
    THROW 50000, 'Faltan las selecciones de prueba (ZCA/ZCB/ZCC): ejecutar antes la preparación de plantel.cuerpo_tecnico_*.', 1;
IF @sede IS NULL
    THROW 50000, 'No hay sedes en torneo.sede: cargar al menos una.', 1;
IF OBJECT_ID('prueba.test_formacion', 'U') IS NULL OR NOT EXISTS (SELECT 1 FROM prueba.test_fjugador WHERE clave = 'sust_sale')
    THROW 50000, 'Faltan prueba.test_formacion/prueba.test_fjugador completos: ejecutar antes las preparaciones de plantel.formacion_* y plantel.formacion_jugador_*.', 1;
SELECT @C    = valor FROM torneo.parametro WHERE clave = 'cambios_max_reglamentarios';
SELECT @V    = valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias';
SELECT @X    = valor FROM torneo.parametro WHERE clave = 'cambios_extra_alargue';
SELECT @W    = valor FROM torneo.parametro WHERE clave = 'ventanas_extra_alargue';
SELECT @maxT = valor FROM torneo.parametro WHERE clave = 'formacion_titulares';
SELECT @maxS = valor FROM torneo.parametro WHERE clave = 'formacion_max_suplentes';
IF @C IS NULL OR @V IS NULL OR @X IS NULL OR @W IS NULL OR @maxT IS NULL OR @maxS IS NULL
    THROW 50000, 'Faltan parámetros en torneo.parametro (cambios_max_reglamentarios, ventanas_max_reglamentarias, cambios_extra_alargue, ventanas_extra_alargue, formacion_titulares, formacion_max_suplentes).', 1;
IF @C < 5 OR @V < 2 OR @V >= @C OR @X < 1 OR @W < 1
    THROW 50000, 'Esta preparación necesita cambios_max_reglamentarios >= 5, 2 <= ventanas_max_reglamentarias < cambios_max_reglamentarios y los extras de alargue >= 1.', 1;
IF @maxT < @C + @X + 2 OR @maxS < @C + @X + 2
    THROW 50000, 'Esta preparación necesita formacion_titulares y formacion_max_suplentes >= cambios_max_reglamentarios + cambios_extra_alargue + 2.', 1;
    -- Partidos nuevos (después de los de la preparación de formacion_jugador_*, un día distinto cada uno)
SELECT @huso = huso_horario FROM torneo.sede WHERE sede_id = @sede;
SET @off = CAST(SUBSTRING(@huso, 4, 3) AS INT) * 60;
SET @base = DATEADD(DAY, 3, (SELECT MAX(CAST(p.fecha_hora_local AS DATETIME2))
                             FROM torneo.partido p
                             JOIN plantel.vw_formacion v ON v.partido_id = p.partido_id
                             JOIN prueba.test_fjugador t ON t.formacion_id = v.formacion_id));
IF @base IS NULL
    THROW 50000, 'No se pudo calcular la fecha base de los partidos (revisar prueba.test_fjugador).', 1;
SET @t = TODATETIMEOFFSET(@base, @off);                  EXEC torneo.partido_insertar @sede, @t, 'octavos',   @s2, @s3, @partido_id = @p1 OUTPUT;  -- ok (ZCB local) / eli (ZCC visitante)
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 3,  @base), @off); EXEC torneo.partido_insertar @sede, @t, 'cuartos',   @s2, @s1, @partido_id = @p2 OUTPUT;  -- gen (ZCB local)
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 6,  @base), @off); EXEC torneo.partido_insertar @sede, @t, 'semifinal', @s1, @s2, @partido_id = @p3 OUTPUT;  -- alg (ZCB visitante)
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 9,  @base), @off); EXEC torneo.partido_insertar @sede, @t, 'cuartos',   @s2, @s3, @partido_id = @p4 OUTPUT;  -- lim (ZCB local)
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 12, @base), @off); EXEC torneo.partido_insertar @sede, @t, 'octavos',   @s1, @s3, @partido_id = @p5 OUTPUT;  -- fin (ZCC visitante)
EXEC plantel.formacion_insertar @p1, 'local',     '4-4-2', @f_ok  OUTPUT;
EXEC plantel.formacion_insertar @p1, 'visitante', '4-3-3', @f_eli OUTPUT;
EXEC plantel.formacion_insertar @p2, 'local',     '4-4-2', @f_gen OUTPUT;
EXEC plantel.formacion_insertar @p3, 'visitante', '4-3-3', @f_alg OUTPUT;
EXEC plantel.formacion_insertar @p4, 'local',     '4-4-2', @f_lim OUTPUT;
EXEC plantel.formacion_insertar @p5, 'visitante', '4-3-3', @f_fin OUTPUT;
    -- Jugadores disponibles
DECLARE @pool TABLE (equipo CHAR(1) NOT NULL, n INT NOT NULL, jugador_id INT NOT NULL, PRIMARY KEY (equipo, n));
INSERT INTO @pool (equipo, n, jugador_id)
SELECT CASE c.seleccion_id WHEN @s2 THEN 'B' ELSE 'C' END,
       ROW_NUMBER() OVER (PARTITION BY c.seleccion_id ORDER BY j.jugador_id),
       j.jugador_id
FROM plantel.convocatoria c
JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id IN (@s2, @s3) AND c.fecha_baja IS NULL AND c.fecha_alta <= CAST(@base AS DATE)
  AND j.nombre = 'Test JU' AND j.apellido LIKE 'FJ %';
SELECT @nb = COUNT(*) FROM @pool WHERE equipo = 'B';
SELECT @nc = COUNT(*) FROM @pool WHERE equipo = 'C';
IF @nb < 2 * (@C + @X + 2)
    THROW 50000, 'ZCB no tiene suficientes jugadores FJ convocados vigentes: revisar la preparación de plantel.formacion_jugador_*.', 1;
IF @nc < 9
    THROW 50000, 'ZCC no tiene suficientes jugadores FJ convocados vigentes (se necesitan 9): revisar la preparación de plantel.formacion_jugador_*.', 1;
    -- Plantel de cada formación
DECLARE @spec TABLE (n INT IDENTITY(1,1), pref VARCHAR(6), formacion_id INT, equipo CHAR(1), nt INT, ns INT);
INSERT INTO @spec (pref, formacion_id, equipo, nt, ns) VALUES
 ('ok',  @f_ok,  'B', 3, 4),
 ('gen', @f_gen, 'B', @V, @V),
 ('alg', @f_alg, 'B', @C, @C),
 ('lim', @f_lim, 'B', @C + @X, @C + @X),
 ('eli', @f_eli, 'C', 2, 3),
 ('fin', @f_fin, 'C', 1, 1);
DECLARE @num TABLE (n INT PRIMARY KEY);
INSERT INTO @num SELECT TOP (60) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM sys.all_objects;
DECLARE @r TABLE (orden INT IDENTITY(1,1), clave VARCHAR(12), formacion_id INT, jugador_id INT, titular BIT);
INSERT INTO @r (clave, formacion_id, jugador_id, titular)
SELECT s.pref + '_' + k.suf, s.formacion_id, p.jugador_id, k.titular
FROM @spec s
CROSS APPLY (
    SELECT 't' + CAST(n.n AS VARCHAR(3)) AS suf, 1 AS titular, n.n AS pos FROM @num n WHERE n.n <= s.nt
    UNION ALL SELECT 'tl',  1, s.nt + 1
    UNION ALL SELECT 'tl2', 1, s.nt + 2
    UNION ALL SELECT 's' + CAST(n.n AS VARCHAR(3)), 0, s.nt + 2 + n.n FROM @num n WHERE n.n <= s.ns
    UNION ALL SELECT 'sl',  0, s.nt + 2 + s.ns + 1
    UNION ALL SELECT 'sl2', 0, s.nt + 2 + s.ns + 2
) k
JOIN @pool p ON p.equipo = s.equipo AND p.n = k.pos
ORDER BY s.n, k.pos;

SET @i = 1; SET @n = (SELECT COUNT(*) FROM @r);
WHILE @i <= @n
BEGIN
    SELECT @fid = formacion_id, @j = jugador_id, @tit = titular FROM @r WHERE orden = @i;
    SET @pos = IIF(@tit = 1, 'Defensor', 'Mediocampista');
    EXEC plantel.formacion_jugador_insertar @fid, @j, @pos, @tit;
    SET @i += 1;
END;
    -- Claves para las verificaciones y para las futuras preparaciones
INSERT INTO prueba.test_sustitucion (clave, formacion_id) VALUES
 ('f_ok', @f_ok), ('f_gen', @f_gen), ('f_eli', @f_eli), ('f_alg', @f_alg), ('f_lim', @f_lim), ('f_fin', @f_fin);
INSERT INTO prueba.test_sustitucion (clave, formacion_id, jugador_id) SELECT clave, formacion_id, jugador_id FROM @r;
INSERT INTO prueba.test_sustitucion (clave, formacion_id, jugador_id)
SELECT 'fuera', NULL, jugador_id FROM @pool WHERE equipo = 'B' AND n = @nb;   -- convocado en ZCB pero que no integra ok ni gen
    -- Cambios cargados: gen (1 por ventana), alg (máximo reglamentario), lim (máximo reglamentario + alargue), fin (1)
    -- i-ésimo cambio: el 1º en PT (ventana 1), el resto en ST (ventana = min(i, ventanas reglamentarias)); los de alargue en alargue_1 (ventana V + 1 ...)
DECLARE @pre TABLE (n INT IDENTITY(1,1), pref VARCHAR(6), formacion_id INT, nreg INT, nalg INT);
INSERT INTO @pre (pref, formacion_id, nreg, nalg) VALUES
 ('gen', @f_gen, @V, 0), ('alg', @f_alg, @C, 0), ('lim', @f_lim, @C, @X), ('fin', @f_fin, 1, 0);
SET @k = 1;
WHILE @k <= (SELECT COUNT(*) FROM @pre)
BEGIN
    SELECT @pref = pref, @fid = formacion_id, @nreg = nreg, @nalg = nalg FROM @pre WHERE n = @k;
    SET @i = 1;
    WHILE @i <= @nreg + @nalg
    BEGIN
        SET @per = CASE WHEN @i > @nreg THEN 'alargue_1' WHEN @i = 1 THEN 'PT' ELSE 'ST' END;
        SET @mn  = CASE WHEN @i > @nreg THEN 95 WHEN @i = 1 THEN 20 ELSE 45 + @i END;
        SET @ven = CASE WHEN @i > @nreg THEN @V + CASE WHEN @i - @nreg < @W THEN @i - @nreg ELSE @W END
                        WHEN @i < @V THEN @i ELSE @V END;
        SET @mot = CHOOSE(@i % 3 + 1, 'tactico', 'lesion', 'precaucion');
        SET @sale  = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = @pref + '_t' + CAST(@i AS VARCHAR(3)));
        SET @entra = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = @pref + '_s' + CAST(@i AS VARCHAR(3)));
        EXEC evento.sustitucion_insertar @fid, @sale, @entra, @mn, @per, @ven, @mot, @sid OUTPUT;
        INSERT INTO prueba.test_sustitucion (clave, formacion_id, sustitucion_id) VALUES (@pref + '_x' + CAST(@i AS VARCHAR(3)), @fid, @sid);
        SET @i += 1;
    END;
    SET @k += 1;
END;
SET @sale  = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'eli_t1');
SET @entra = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'eli_s1');
EXEC evento.sustitucion_insertar @f_eli, @sale, @entra, 25, 'PT', 1, 'tactico', @sid OUTPUT;
INSERT INTO prueba.test_sustitucion (clave, formacion_id, sustitucion_id) VALUES ('eli_x1', @f_eli, @sid);
SET @sale  = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'eli_t2');
SET @entra = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'eli_s2');
EXEC evento.sustitucion_insertar @f_eli, @sale, @entra, 60, 'ST', 2, 'lesion', @sid OUTPUT;
INSERT INTO prueba.test_sustitucion (clave, formacion_id, sustitucion_id) VALUES ('eli_x2', @f_eli, @sid);
SET @sale  = @entra;
SET @entra = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'eli_s3');
EXEC evento.sustitucion_insertar @f_eli, @sale, @entra, 80, 'ST', 2, 'precaucion', @sid OUTPUT;
INSERT INTO prueba.test_sustitucion (clave, formacion_id, sustitucion_id) VALUES ('eli_x3', @f_eli, @sid);  
    -- Partido finalizado: se carga primero (el SP rechaza partidos finalizados) y luego se finaliza
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @p5;
GO

PRINT '--- P-3.14 Preparación de evento.gol_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes, en esta misma ventana: plantel.cuerpo_tecnico_* (ZCA/ZCB/ZCC), plantel.jugador_*, plantel.convocatoria_*,
-- plantel.formacion_* (prueba.test_formacion) y plantel.formacion_jugador_* (prueba.test_fjugador).
-- Usa evento.sustitucion_insertar (para tener un suplente que ingresó), pero NO requiere la preparación de evento.sustitucion_*.
IF OBJECT_ID('prueba.test_fjugador', 'U') IS NULL OR OBJECT_ID('prueba.test_formacion', 'U') IS NULL
    THROW 50000, 'Faltan prueba.test_fjugador/prueba.test_formacion: ejecutar antes las preparaciones de plantel.formacion_* y plantel.formacion_jugador_*.', 1;
IF OBJECT_ID('prueba.test_gol', 'U') IS NULL
    CREATE TABLE prueba.test_gol (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY,   -- FIX: misma collation que la base
                             partido_id INT NULL, formacion_id INT NULL, jugador_id INT NULL, gol_id INT NULL);
GO
IF EXISTS (SELECT 1 FROM prueba.test_gol)
    THROW 50000, 'La preparación de evento.gol_* ya fue ejecutada en esta base (ver prueba.test_gol).', 1;
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @sede INT = (SELECT TOP 1 sede_id FROM torneo.sede ORDER BY sede_id),
        @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @huso CHAR(6), @off INT, @base DATETIME2, @t DATETIMEOFFSET,
        @pf INT, @pz INT, @fl INT, @fv INT, @zl INT, @zv INT,
        @i INT, @n INT, @j INT, @fid INT, @tit BIT, @pos VARCHAR(30), @g INT, @sid INT,
        @sale INT, @entra INT, @aut INT, @asi INT, @min INT, @tg VARCHAR(15), @per VARCHAR(20), @cl VARCHAR(12);
IF @s1 IS NULL OR @s2 IS NULL OR @s3 IS NULL
    THROW 50000, 'Faltan las selecciones de prueba (ZCA/ZCB/ZCC): ejecutar antes la preparación de plantel.cuerpo_tecnico_*.', 1;
IF @sede IS NULL
    THROW 50000, 'No hay sedes en torneo.sede: cargar al menos una.', 1;
IF @fj IS NULL
    THROW 50000, 'Falta la formación jug en prueba.test_formacion: ejecutar antes la preparación de plantel.formacion_*.', 1;
IF (SELECT COUNT(*) FROM prueba.test_fjugador
    WHERE clave IN ('gol', 'asis', 'tit_1', 'tit_2', 'tit_3', 'tit_4', 'tit_5', 'tit_sup', 'lib_1', 'lib_3', 'sup_tit', 'sup_1', 'sup_2', 'sup_3')) < 14
    THROW 50000, 'Faltan jugadores en prueba.test_fjugador: ejecutar antes la preparación de plantel.formacion_jugador_*.', 1;
IF (SELECT COUNT(*) FROM plantel.formacion_jugador fj JOIN prueba.test_fjugador t ON t.jugador_id = fj.jugador_id
    WHERE fj.formacion_id = @fj AND fj.titular = 1 AND t.clave IN ('gol', 'asis')) < 2
    THROW 50000, 'Los jugadores gol y asis no son titulares de la formación jug: revisar la preparación de plantel.formacion_jugador_*.', 1;
    -- Partidos nuevos
SELECT @huso = huso_horario FROM torneo.sede WHERE sede_id = @sede;
SET @off = CAST(SUBSTRING(@huso, 4, 3) AS INT) * 60;
SET @base = DATEADD(DAY, 3, (SELECT MAX(CAST(fecha_hora_local AS DATETIME2)) FROM torneo.partido
                             WHERE seleccion_local_id IN (@s1, @s2, @s3) OR seleccion_visitante_id IN (@s1, @s2, @s3)));
IF @base IS NULL
    THROW 50000, 'No se pudo calcular la fecha base de los partidos.', 1;
SET @t = TODATETIMEOFFSET(@base, @off);                   EXEC torneo.partido_insertar @sede, @t, 'final',         @s2, @s3, @partido_id = @pf OUTPUT;  -- p_gol (ZCB local vs ZCC visitante)
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 3, @base), @off);  EXEC torneo.partido_insertar @sede, @t, 'tercer_puesto', @s2, @s3, @partido_id = @pz OUTPUT;  -- p_z (se finaliza al final)

EXEC plantel.formacion_insertar @pf, 'local',     '4-4-2', @fl OUTPUT;  -- ZCB
EXEC plantel.formacion_insertar @pf, 'visitante', '4-3-3', @fv OUTPUT;  -- ZCC
EXEC plantel.formacion_insertar @pz, 'local',     '4-4-2', @zl OUTPUT;  -- ZCB (partido a finalizar)
EXEC plantel.formacion_insertar @pz, 'visitante', '4-3-3', @zv OUTPUT;  -- ZCC (partido a finalizar)
INSERT INTO prueba.test_gol (clave, partido_id, formacion_id) VALUES
 ('p_gol', @pf, NULL), ('p_z', @pz, NULL),
 ('f_loc', @pf, @fl), ('f_vis', @pf, @fv), ('z_loc', @pz, @zl), ('z_vis', @pz, @zv), ('f_jug', @pm, @fj);
    -- Plantel de las formaciones (jugadores FJ de ZCB y ZCC, convocados vigentes)
DECLARE @plantel TABLE (n INT IDENTITY(1,1), clave VARCHAR(12), fj_clave VARCHAR(12), formacion_id INT, titular BIT);
INSERT INTO @plantel (clave, fj_clave, formacion_id, titular) VALUES
 ('loc_t1',    'tit_1',   @fl, 1), ('loc_t2', 'tit_2', @fl, 1), ('loc_t3', 'tit_3', @fl, 1), ('loc_t4', 'tit_4', @fl, 1), ('loc_t5', 'tit_5', @fl, 1),
 ('loc_s_in',  'tit_sup', @fl, 0),   -- ingresa por loc_t5
 ('loc_s_out', 'lib_1',   @fl, 0),   -- suplente que no ingresa
 ('vis_t1',    'sup_tit', @fv, 1), ('vis_t2', 'sup_1', @fv, 1), ('vis_t3', 'sup_2', @fv, 1),
 ('vis_s',     'sup_3',   @fv, 0),   -- suplente que no ingresa
 ('z_t1',      'tit_1',   @zl, 1),
 ('zv_t1',     'sup_tit', @zv, 1);
SET @i = 1; SET @n = (SELECT COUNT(*) FROM @plantel);
WHILE @i <= @n
BEGIN
    SELECT @j = t.jugador_id, @fid = p.formacion_id, @tit = p.titular
    FROM @plantel p
    JOIN prueba.test_fjugador t ON t.clave COLLATE DATABASE_DEFAULT = p.fj_clave COLLATE DATABASE_DEFAULT   -- FIX
    WHERE p.n = @i;
    SET @pos = IIF(@tit = 1, 'Defensor', 'Mediocampista');
    EXEC plantel.formacion_jugador_insertar @fid, @j, @pos, @tit;
    SET @i += 1;
END;
INSERT INTO prueba.test_gol (clave, formacion_id, jugador_id)
SELECT p.clave, p.formacion_id, t.jugador_id
FROM @plantel p
JOIN prueba.test_fjugador t ON t.clave COLLATE DATABASE_DEFAULT = p.fj_clave COLLATE DATABASE_DEFAULT;   -- FIX
INSERT INTO prueba.test_gol (clave, formacion_id, jugador_id)
SELECT 'loc_fuera', NULL, jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_3';       -- convocado en ZCB, no integra f_loc ni z_loc
INSERT INTO prueba.test_gol (clave, formacion_id, jugador_id)
SELECT 'jug_gol',  @fj, jugador_id FROM prueba.test_fjugador WHERE clave = 'gol';
INSERT INTO prueba.test_gol (clave, formacion_id, jugador_id)
SELECT 'jug_asis', @fj, jugador_id FROM prueba.test_fjugador WHERE clave = 'asis';
    -- Sustitución: loc_t5 sale, loc_s_in ingresa (para que el suplente pueda ser autor/asistente)
SET @sale  = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t5');
SET @entra = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_s_in');
EXEC evento.sustitucion_insertar @fl, @sale, @entra, 20, 'PT', 1, 'tactico', @sid OUTPUT;
    -- Goles
DECLARE @goles TABLE (n INT IDENTITY(1,1), clave VARCHAR(12), form VARCHAR(12), autor VARCHAR(12), asist VARCHAR(12),
                      minuto INT, tipo_gol VARCHAR(15), periodo VARCHAR(20));
INSERT INTO @goles (clave, form, autor, asist, minuto, tipo_gol, periodo) VALUES
 ('g_mod',   'f_loc', 'loc_t1',   'loc_t2',   10,  'jugada',    'PT'),
 ('g_sup',   'f_loc', 'loc_s_in', NULL,       70,  'jugada',    'ST'),
 ('g_pen',   'f_loc', 'loc_t3',   NULL,       120, 'penal',     'penales'),
 ('g_elim',  'f_loc', 'loc_t4',   'loc_t1',   30,  'jugada',    'PT'),
 ('g_elim2', 'f_loc', 'loc_t3',   NULL,       55,  'cabezazo',  'ST'),
 ('g_vis',   'f_vis', 'vis_t1',   'vis_t2',   25,  'jugada',    'PT'),
 ('g_ec',    'f_vis', 'vis_t3',   NULL,       40,  'en_contra', 'PT'),
 ('g_elim3', 'f_vis', 'vis_t2',   NULL,       80,  'en_contra', 'ST'),
 ('g_penv',  'f_vis', 'vis_t1',   NULL,       121, 'penal',     'penales'),
 ('g_elim4', 'f_vis', 'vis_t2',   NULL,       122, 'penal',     'penales'),
 ('g_fin',   'z_loc', 'z_t1',     NULL,       10,  'jugada',    'PT'),
 ('g_jug',   'f_jug', 'jug_gol',  'jug_asis', 30,  'jugada',    'PT');
SET @i = 1; SET @n = (SELECT COUNT(*) FROM @goles);
WHILE @i <= @n
BEGIN
    SELECT @cl = g.clave, @fid = f.formacion_id, @aut = a.jugador_id, @asi = s.jugador_id,
           @min = g.minuto, @tg = g.tipo_gol, @per = g.periodo
    FROM @goles g
    JOIN prueba.test_gol f ON f.clave COLLATE DATABASE_DEFAULT = g.form  COLLATE DATABASE_DEFAULT          -- FIX
    JOIN prueba.test_gol a ON a.clave COLLATE DATABASE_DEFAULT = g.autor COLLATE DATABASE_DEFAULT          -- FIX
    LEFT JOIN prueba.test_gol s ON s.clave COLLATE DATABASE_DEFAULT = g.asist COLLATE DATABASE_DEFAULT     -- FIX
    WHERE g.n = @i;
    EXEC evento.gol_insertar @fid, @aut, @min, @tg, @per, @asi, @g OUTPUT;
    INSERT INTO prueba.test_gol (clave, formacion_id, gol_id) VALUES (@cl, @fid, @g);
    SET @i += 1;
END;
    -- Partido finalizado: se carga primero (el SP rechaza partidos finalizados) y luego se finaliza
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pz;
GO

PRINT '--- P-3.15 Preparación de evento.tarjeta_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes, en esta misma ventana: plantel.cuerpo_tecnico_* (ZCA/ZCB/ZCC), plantel.jugador_*, plantel.convocatoria_*,
-- plantel.formacion_* (prueba.test_formacion) y plantel.formacion_jugador_* (prueba.test_fjugador). NO requiere las preparaciones de evento.sustitucion_* ni evento.gol_*.
IF OBJECT_ID('prueba.test_fjugador', 'U') IS NULL OR OBJECT_ID('prueba.test_formacion', 'U') IS NULL
    THROW 50000, 'Faltan prueba.test_fjugador/prueba.test_formacion: ejecutar antes las preparaciones de plantel.formacion_* y plantel.formacion_jugador_*.', 1;
IF OBJECT_ID('prueba.test_tarjeta', 'U') IS NULL
    CREATE TABLE prueba.test_tarjeta (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY,
                                 partido_id INT NULL, formacion_id INT NULL, persona_id INT NULL, tarjeta_id INT NULL);
GO
IF EXISTS (SELECT 1 FROM prueba.test_tarjeta)
    THROW 50000, 'La preparación de evento.tarjeta_* ya fue ejecutada en esta base (ver prueba.test_tarjeta).', 1;
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @sede INT = (SELECT TOP 1 sede_id FROM torneo.sede ORDER BY sede_id),
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @huso CHAR(6), @off INT, @base DATETIME2, @t DATETIMEOFFSET,
        @pt INT, @pz INT, @fl INT, @fv INT, @zl INT,
        @i INT, @n INT, @j INT, @fid INT, @tit BIT, @pos VARCHAR(30), @x INT, @pe INT, @tid INT, @ap VARCHAR(100);
IF @s1 IS NULL OR @s2 IS NULL OR @s3 IS NULL
    THROW 50000, 'Faltan las selecciones de prueba (ZCA/ZCB/ZCC): ejecutar antes la preparación de plantel.cuerpo_tecnico_*.', 1;
IF @sede IS NULL
    THROW 50000, 'No hay sedes en torneo.sede: cargar al menos una.', 1;
IF @fj IS NULL
    THROW 50000, 'Falta la formación jug en prueba.test_formacion: ejecutar antes la preparación de plantel.formacion_*.', 1;
IF (SELECT COUNT(*) FROM prueba.test_fjugador
    WHERE clave IN ('tit_1', 'tit_2', 'tit_3', 'tit_4', 'tit_5', 'tit_6', 'tit_7', 'tit_8', 'tit_sup',
                    'q1', 'susp', 'fin', 'sust_sale', 'tarj', 'base', 'gol')) < 16
    THROW 50000, 'Faltan jugadores en prueba.test_fjugador: ejecutar antes la preparación de plantel.formacion_jugador_*.', 1;
IF (SELECT COUNT(*) FROM plantel.formacion_jugador fj JOIN prueba.test_fjugador t ON t.jugador_id = fj.jugador_id
    WHERE fj.formacion_id = @fj AND t.clave IN ('tarj', 'base', 'gol')) < 3
    THROW 50000, 'Los jugadores tarj, base y gol deben integrar la formación jug: revisar la preparación de plantel.formacion_jugador_*.', 1;
IF NOT EXISTS (SELECT 1 FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Base')
    THROW 50000, 'Falta el jugador Test JU Base: ejecutar antes la preparación de plantel.jugador_*.', 1;
    -- Partidos nuevos (después de cualquier partido de prueba existente, un día distinto cada uno)
SELECT @huso = huso_horario FROM torneo.sede WHERE sede_id = @sede;
SET @off = CAST(SUBSTRING(@huso, 4, 3) AS INT) * 60;
SET @base = DATEADD(DAY, 3, (SELECT MAX(CAST(fecha_hora_local AS DATETIME2)) FROM torneo.partido
                             WHERE seleccion_local_id IN (@s1, @s2, @s3) OR seleccion_visitante_id IN (@s1, @s2, @s3)));
IF @base IS NULL
    THROW 50000, 'No se pudo calcular la fecha base de los partidos.', 1;
SET @t = TODATETIMEOFFSET(@base, @off);                   EXEC torneo.partido_insertar @sede, @t, 'final',     @s2, @s1, @partido_id = @pt OUTPUT;  -- pt_tar (ZCB local vs ZCA visitante)
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 3, @base), @off);  EXEC torneo.partido_insertar @sede, @t, 'semifinal', @s1, @s3, @partido_id = @pz OUTPUT;  -- pt_z (se finaliza al final)
EXEC plantel.formacion_insertar @pt, 'local',     '4-4-2', @fl OUTPUT;  -- ZCB
EXEC plantel.formacion_insertar @pt, 'visitante', '4-3-3', @fv OUTPUT;  -- ZCA
EXEC plantel.formacion_insertar @pz, 'local',     '4-4-2', @zl OUTPUT;  -- ZCA (partido a finalizar)
INSERT INTO prueba.test_tarjeta (clave, partido_id, formacion_id) VALUES
 ('pt_tar', @pt, NULL), ('pt_z', @pz, NULL), ('f_loc', @pt, @fl), ('f_vis', @pt, @fv), ('z_loc', @pz, @zl);
    -- Plantel de las formaciones (jugadores FJ convocados vigentes)
DECLARE @plantel TABLE (n INT IDENTITY(1,1), fj_clave VARCHAR(12), formacion_id INT, titular BIT);
INSERT INTO @plantel (fj_clave, formacion_id, titular) VALUES
 ('tit_1', @fl, 1), ('tit_2', @fl, 1), ('tit_3', @fl, 1), ('tit_4', @fl, 1),
 ('tit_5', @fl, 1), ('tit_6', @fl, 1), ('tit_7', @fl, 1), ('tit_8', @fl, 1),
 ('tit_sup', @fl, 0),
 ('q1', @fv, 1), ('susp', @fv, 1),
 ('fin', @zl, 1), ('sust_sale', @zl, 1);
SET @i = 1; SET @n = (SELECT COUNT(*) FROM @plantel);
WHILE @i <= @n
BEGIN
    SELECT @j = t.jugador_id, @fid = p.formacion_id, @tit = p.titular
    FROM @plantel p
    JOIN prueba.test_fjugador t ON t.clave COLLATE DATABASE_DEFAULT = p.fj_clave COLLATE DATABASE_DEFAULT
    WHERE p.n = @i;
    SET @pos = IIF(@tit = 1, 'Defensor', 'Mediocampista');
    EXEC plantel.formacion_jugador_insertar @fid, @j, @pos, @tit;
    SET @i += 1;
END;
    -- Personas de los jugadores
INSERT INTO prueba.test_tarjeta (clave, persona_id)
SELECT m.k, j.persona_id
FROM (VALUES ('u_m', 'tit_1'), ('u_mr', 'tit_2'), ('u_e', 'tit_3'), ('u_e2', 'tit_4'), ('u_dob', 'tit_5'),
             ('u_a1', 'tit_6'), ('u_a2', 'tit_7'), ('u_titu', 'tit_8'), ('u_supl', 'tit_sup'),
             ('u_vis', 'q1'), ('u_susp', 'susp'), ('u_fin', 'fin'), ('u_zlim', 'sust_sale'),
             ('u_tarj', 'tarj'), ('u_conv', 'base'), ('u_gol', 'gol')) AS m (k, fk)
JOIN prueba.test_fjugador t ON t.clave COLLATE DATABASE_DEFAULT = m.fk COLLATE DATABASE_DEFAULT
JOIN plantel.jugador j ON j.jugador_id = t.jugador_id;
INSERT INTO prueba.test_tarjeta (clave, persona_id)
SELECT 'u_np', persona_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Base';   -- existe, no participa de ningún partido
    -- Cuerpo técnico de ZCB (participa de los partidos de ZCB) como personas libres, y uno de ZCA
SET @i = 1;
WHILE @i <= 26
BEGIN
    SET @ap = 'CT ' + CAST(@i AS VARCHAR(2));
    EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test TJ', @ap, 'otro', @x OUTPUT, @pe OUTPUT;
    INSERT INTO prueba.test_tarjeta (clave, persona_id) VALUES ('l_' + CAST(@i AS VARCHAR(2)), @pe);
    SET @i += 1;
END;
EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test TJ', 'CT Err',  'otro', @x OUTPUT, @pe OUTPUT; INSERT INTO prueba.test_tarjeta (clave, persona_id) VALUES ('u_err', @pe);  -- solo errores
EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test TJ', 'CT Amar', 'otro', @x OUTPUT, @pe OUTPUT; INSERT INTO prueba.test_tarjeta (clave, persona_id) VALUES ('u_ea',  @pe);  -- con una amarilla, solo errores
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test TJ', 'CT Vis',  'otro', @x OUTPUT, @pe OUTPUT; INSERT INTO prueba.test_tarjeta (clave, persona_id) VALUES ('u_ctv', @pe);  -- cuerpo técnico visitante
    -- Tarjetas
DECLARE @u_m INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_m'),
        @u_mr INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_mr'),
        @u_e INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_e'),
        @u_e2 INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_e2'),
        @u_dob INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_dob'),
        @u_a1 INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_a1'),
        @u_a2 INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_a2'),
        @u_ea INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_ea'),
        @u_susp INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_susp'),
        @u_tarj INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_tarj'),
        @u_fin INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_fin');
EXEC evento.tarjeta_insertar @pt, @u_m,    10, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_mod',   @tid);  -- a modificar
EXEC evento.tarjeta_insertar @pt, @u_mr,   70, 'ST', 'roja',     'Agresion',         'roja_directa',   @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_modr',  @tid);  -- roja a modificar (persona expulsada)
EXEC evento.tarjeta_insertar @pt, @u_e,    30, 'PT', 'amarilla', NULL,               NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_elim',  @tid);  -- baja valida
EXEC evento.tarjeta_insertar @pt, @u_e2,   80, 'ST', 'roja',     'Agresion',         'roja_directa',   @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_elim2', @tid);  -- baja valida (roja)
EXEC evento.tarjeta_insertar @pt, @u_dob,  20, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_dob_a', @tid);  -- primera amarilla de la doble
EXEC evento.tarjeta_insertar @pt, @u_dob,  70, 'ST', 'roja',     'Segunda amarilla', 'doble_amarilla', @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_dob_r', @tid);  -- roja por doble amarilla
EXEC evento.tarjeta_insertar @pt, @u_a1,   15, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_a1',    @tid);  -- para la doble amarilla valida
EXEC evento.tarjeta_insertar @pt, @u_a2,   25, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_a2',    @tid);  -- para la roja directa valida tras amarilla
EXEC evento.tarjeta_insertar @pt, @u_ea,   15, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_ea',    @tid);  -- para casos de error
EXEC evento.tarjeta_insertar @pt, @u_susp, 85, 'ST', 'roja',     'Agresion',         'roja_directa',   @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_susp',  @tid);  -- RESERVADA para evento.suspension_*
EXEC evento.tarjeta_insertar @pm, @u_tarj, 30, 'PT', 'amarilla', NULL,               NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_jug',   @tid);  -- partido 'mod' (grupos), jugador 'tarj'
EXEC evento.tarjeta_insertar @pz, @u_fin,  10, 'PT', 'amarilla', NULL,               NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO prueba.test_tarjeta (clave, tarjeta_id) VALUES ('t_fin',   @tid);  -- partido a finalizar
    -- Partido finalizado: se carga primero (el SP rechaza partidos finalizados) y luego se finaliza
DECLARE @ctt INT = (SELECT persona_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Tarjeta'),
        @jut INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Tarjeta');
DECLARE @put INT = (SELECT persona_id FROM plantel.jugador WHERE jugador_id = @jut);
EXEC evento.tarjeta_insertar @pt, @ctt, 50, 'ST', 'amarilla', 'Protesta', NULL, @tarjeta_id = @tid OUTPUT;
EXEC plantel.convocatoria_insertar @s2, @jut, 95, '2026-06-01', NULL;
EXEC plantel.formacion_jugador_insertar @fl, @jut, 'Arquero', 0;
EXEC evento.tarjeta_insertar @pt, @put, 55, 'ST', 'amarilla', 'Demora', NULL, @tarjeta_id = @tid OUTPUT;
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pz;
GO

PRINT '--- P-3.16 Preparación de evento.criterio_suspension_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- No requiere ninguna otra preparación. Todos los criterios de prueba usan cantidad_amarillas entre 70 y 99 (nunca se alcanzan en un partido real).
IF OBJECT_ID('prueba.test_criterio', 'U') IS NULL
    CREATE TABLE prueba.test_criterio (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY, criterio_id INT NOT NULL);
GO
IF EXISTS (SELECT 1 FROM prueba.test_criterio)
    THROW 50000, 'La preparación de evento.criterio_suspension_* ya fue ejecutada en esta base (ver prueba.test_criterio).', 1;
IF EXISTS (SELECT 1 FROM evento.criterio_suspension WHERE cantidad_amarillas BETWEEN 70 AND 99)
    THROW 50000, 'Ya hay criterios con cantidad_amarillas entre 70 y 99 (rango reservado para las pruebas): ejecutar antes la limpieza de evento.criterio_suspension_*.', 1;
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 90, 1, 'grupos',        'jugador',        1, @id OUTPUT; INSERT INTO prueba.test_criterio VALUES ('mod',       @id);  -- a modificar
EXEC evento.criterio_suspension_insertar 90, 1, 'octavos',       NULL,             1, @id OUTPUT; INSERT INTO prueba.test_criterio VALUES ('mod2',      @id);  -- destino de duplicados
EXEC evento.criterio_suspension_insertar 90, 1, 'semifinal',     'jugador',        1, @id OUTPUT; INSERT INTO prueba.test_criterio VALUES ('dup',       @id);  -- destino de duplicados
EXEC evento.criterio_suspension_insertar 90, 1, NULL,            NULL,             1, @id OUTPUT; INSERT INTO prueba.test_criterio VALUES ('base_null', @id);  -- destino de duplicados (todas las fases, ambos tipos)
EXEC evento.criterio_suspension_insertar 90, 1, 'cuartos',       'cuerpo_tecnico', 1, @id OUTPUT; INSERT INTO prueba.test_criterio VALUES ('elim',      @id);  -- baja valida
EXEC evento.criterio_suspension_insertar 91, 1, NULL,            NULL,             0, @id OUTPUT; INSERT INTO prueba.test_criterio VALUES ('elim2',     @id);  -- baja valida (inactivo)
EXEC evento.criterio_suspension_insertar 90, 1, 'tercer_puesto', 'jugador',        1, @id OUTPUT; INSERT INTO prueba.test_criterio VALUES ('usado',     @id);  -- RESERVADO para evento.suspension_*
GO

















-- =======================================================================================================
--                                          VALIDACION
-- =======================================================================================================

-- ============================================================
GO

-- ============================================================
-- 3.1 torneo.parametro
-- ============================================================

-- -------------------------------------------------------------------------------------
-- torneo.parametro_insertar: F-3.1.01 a F-3.1.19
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.1.01 torneo.parametro_insertar: Clave vacia => 1 error
PRINT '--- F-3.1.01 torneo.parametro_insertar: Clave vacia';
BEGIN TRY EXEC torneo.parametro_insertar '', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.02 torneo.parametro_insertar: Clave nula => 1 error
PRINT '--- F-3.1.02 torneo.parametro_insertar: Clave nula';
BEGIN TRY EXEC torneo.parametro_insertar NULL, 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.03 torneo.parametro_insertar: Clave solo espacios => 1 error
PRINT '--- F-3.1.03 torneo.parametro_insertar: Clave solo espacios';
BEGIN TRY EXEC torneo.parametro_insertar '   ', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.04 torneo.parametro_insertar: Clave de 41 caracteres (mas de 40) => 1 error
PRINT '--- F-3.1.04 torneo.parametro_insertar: Clave de 41 caracteres (mas de 40)';
BEGIN TRY EXEC torneo.parametro_insertar 'tst_abcdefghijklmnopqrstuvwxyz0123456789x', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.05 torneo.parametro_insertar: Clave con espacio => 1 error
PRINT '--- F-3.1.05 torneo.parametro_insertar: Clave con espacio';
BEGIN TRY EXEC torneo.parametro_insertar 'tst bad', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.06 torneo.parametro_insertar: Clave con espacio al inicio, tira error de tipo de caracteres => 1 error
PRINT '--- F-3.1.06 torneo.parametro_insertar: Clave con espacio al inicio, tira error de tipo de caracteres';
BEGIN TRY EXEC torneo.parametro_insertar ' tst_bad', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.07 torneo.parametro_insertar: Clave con guion medio => 1 error
PRINT '--- F-3.1.07 torneo.parametro_insertar: Clave con guion medio';
BEGIN TRY EXEC torneo.parametro_insertar 'tst-bad', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.08 torneo.parametro_insertar: Clave con punto => 1 error
PRINT '--- F-3.1.08 torneo.parametro_insertar: Clave con punto';
BEGIN TRY EXEC torneo.parametro_insertar 'tst.bad', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.09 torneo.parametro_insertar: Valor nulo => 1 error
PRINT '--- F-3.1.09 torneo.parametro_insertar: Valor nulo';
BEGIN TRY EXEC torneo.parametro_insertar 'tst_bad', NULL, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.10 torneo.parametro_insertar: Valor negativo => 1 error
PRINT '--- F-3.1.10 torneo.parametro_insertar: Valor negativo';
BEGIN TRY EXEC torneo.parametro_insertar 'tst_bad', -1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.11 torneo.parametro_insertar: Descripcion vacia => 1 error
PRINT '--- F-3.1.11 torneo.parametro_insertar: Descripcion vacia';
BEGIN TRY EXEC torneo.parametro_insertar 'tst_bad', 1, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.12 torneo.parametro_insertar: Descripcion nula => 1 error
PRINT '--- F-3.1.12 torneo.parametro_insertar: Descripcion nula';
BEGIN TRY EXEC torneo.parametro_insertar 'tst_bad', 1, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.13 torneo.parametro_insertar: Descripcion solo espacios => 1 error
PRINT '--- F-3.1.13 torneo.parametro_insertar: Descripcion solo espacios';
BEGIN TRY EXEC torneo.parametro_insertar 'tst_bad', 1, '   '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.14 torneo.parametro_insertar: Clave duplicada => 1 error
PRINT '--- F-3.1.14 torneo.parametro_insertar: Clave duplicada';
BEGIN TRY EXEC torneo.parametro_insertar 'tst_ins', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.15 torneo.parametro_insertar: Duplicada con otra capitalizacion => 1 error
PRINT '--- F-3.1.15 torneo.parametro_insertar: Duplicada con otra capitalizacion';
BEGIN TRY EXEC torneo.parametro_insertar 'TST_INS', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.16 torneo.parametro_insertar: Duplicada con un parametro real => 1 error
PRINT '--- F-3.1.16 torneo.parametro_insertar: Duplicada con un parametro real';
BEGIN TRY EXEC torneo.parametro_insertar 'formacion_titulares', 1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.17 torneo.parametro_insertar: clave obligatoria y valor negativo => 2 errores
PRINT '--- F-3.1.17 torneo.parametro_insertar: 2 errores: clave obligatoria y valor negativo';
BEGIN TRY EXEC torneo.parametro_insertar '', -1, 'Desc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.18 torneo.parametro_insertar: clave obligatoria, valor obligatorio y descripcion obligatoria => 3 errores
PRINT '--- F-3.1.18 torneo.parametro_insertar: 3 errores: clave obligatoria, valor obligatorio y descripcion obligatoria';
BEGIN TRY EXEC torneo.parametro_insertar NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.19 torneo.parametro_insertar: formato de clave, valor negativo, descripcion vacia y clave duplicada => 4 errores
PRINT '--- F-3.1.19 torneo.parametro_insertar: 4 errores: formato de clave, valor negativo, descripcion vacia y clave duplicada';
BEGIN TRY EXEC torneo.parametro_insertar 'tst_ins ', -1, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.parametro_modificar: F-3.1.20 a F-3.1.30
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.1.20 torneo.parametro_modificar: Parametro inexistente => 1 error
PRINT '--- F-3.1.20 torneo.parametro_modificar: Parametro inexistente';
BEGIN TRY EXEC torneo.parametro_modificar 'no_existe_xx', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.21 torneo.parametro_modificar: Clave nula => 1 error
PRINT '--- F-3.1.21 torneo.parametro_modificar: Clave nula';
BEGIN TRY EXEC torneo.parametro_modificar NULL, 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.22 torneo.parametro_modificar: Clave vacia => 1 error
PRINT '--- F-3.1.22 torneo.parametro_modificar: Clave vacia';
BEGIN TRY EXEC torneo.parametro_modificar '', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.23 torneo.parametro_modificar: Valor nulo => 1 error
PRINT '--- F-3.1.23 torneo.parametro_modificar: Valor nulo';
BEGIN TRY EXEC torneo.parametro_modificar 'tst_mod', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.24 torneo.parametro_modificar: Valor negativo => 1 error
PRINT '--- F-3.1.24 torneo.parametro_modificar: Valor negativo';
BEGIN TRY EXEC torneo.parametro_modificar 'tst_mod', -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.25 torneo.parametro_modificar: Descripcion vacia => 1 error
PRINT '--- F-3.1.25 torneo.parametro_modificar: Descripcion vacia';
BEGIN TRY EXEC torneo.parametro_modificar 'tst_mod', 1, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.26 torneo.parametro_modificar: Descripcion solo espacios => 1 error
PRINT '--- F-3.1.26 torneo.parametro_modificar: Descripcion solo espacios';
BEGIN TRY EXEC torneo.parametro_modificar 'tst_mod', 1, '   '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.27 torneo.parametro_modificar: Hora de fin fuera de rango (mayor a 24) => 1 error
PRINT '--- F-3.1.27 torneo.parametro_modificar: Hora de fin fuera de rango (mayor a 24)';
BEGIN TRY EXEC torneo.parametro_modificar 'prime_time_hora_hasta', 25; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.28 torneo.parametro_modificar: Hora de inicio fuera de rango (mayor a 23) => 1 error
PRINT '--- F-3.1.28 torneo.parametro_modificar: Hora de inicio fuera de rango (mayor a 23)';
BEGIN TRY EXEC torneo.parametro_modificar 'prime_time_hora_desde', 24; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.29 torneo.parametro_modificar: parametro inexistente y descripcion vacia => 2 errores
PRINT '--- F-3.1.29 torneo.parametro_modificar: 2 errores: parametro inexistente y descripcion vacia';
BEGIN TRY EXEC torneo.parametro_modificar 'no_existe_xx', 1, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.30 torneo.parametro_modificar: parametro inexistente, valor negativo y descripcion vacia => 3 errores
PRINT '--- F-3.1.30 torneo.parametro_modificar: 3 errores: parametro inexistente, valor negativo y descripcion vacia';
BEGIN TRY EXEC torneo.parametro_modificar 'no_existe_xx', -1, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.parametro_eliminar: F-3.1.31 a F-3.1.45
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.1.31 torneo.parametro_eliminar: Parametro inexistente (ya dado de baja) => 1 error (antes, la baja válida, que se deshace al final)
PRINT '--- F-3.1.31 torneo.parametro_eliminar: Parametro inexistente (ya dado de baja)';
BEGIN TRAN;
BEGIN TRY
    EXEC torneo.parametro_eliminar 'tst_elim';
    EXEC torneo.parametro_eliminar 'tst_elim';
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.1.32 torneo.parametro_eliminar: Parametro inexistente => 1 error
PRINT '--- F-3.1.32 torneo.parametro_eliminar: Parametro inexistente';
BEGIN TRY EXEC torneo.parametro_eliminar 'no_existe_xx'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.33 torneo.parametro_eliminar: Clave nula => 1 error
PRINT '--- F-3.1.33 torneo.parametro_eliminar: Clave nula';
BEGIN TRY EXEC torneo.parametro_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.34 torneo.parametro_eliminar: Clave vacia (no existe) => 1 error
PRINT '--- F-3.1.34 torneo.parametro_eliminar: Clave vacia (no existe)';
BEGIN TRY EXEC torneo.parametro_eliminar ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.35 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.35 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'convocatoria_min_jugadores'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.36 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.36 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'convocatoria_max_jugadores'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.37 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.37 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'formacion_titulares'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.38 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.38 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'formacion_max_suplentes'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.39 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.39 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'cambios_max_reglamentarios'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.40 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.40 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'ventanas_max_reglamentarias'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.41 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.41 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'cambios_extra_alargue'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.42 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.42 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'ventanas_extra_alargue'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.43 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.43 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'suspension_partidos_roja'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.44 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.44 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'prime_time_hora_desde'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.1.45 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio => 1 error
PRINT '--- F-3.1.45 torneo.parametro_eliminar: Parámetro requerido por la lógica de negocio';
BEGIN TRY EXEC torneo.parametro_eliminar 'prime_time_hora_hasta'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.2 torneo.pais y torneo.confederacion
-- ============================================================

-- -------------------------------------------------------------------------------------
-- torneo.pais_validar: F-3.2.01 a F-3.2.30
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.2.01 torneo.pais_validar: Pais inexistente (1 error) => 1 error
PRINT '--- F-3.2.01 torneo.pais_validar: Pais inexistente (1 error)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar 999999, 'ZZV', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.02 torneo.pais_validar: ISO nulo => 1 error
PRINT '--- F-3.2.02 torneo.pais_validar: ISO nulo';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, NULL, 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.03 torneo.pais_validar: ISO vacio => 1 error
PRINT '--- F-3.2.03 torneo.pais_validar: ISO vacio';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, '', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.04 torneo.pais_validar: ISO de 2 letras => 1 error
PRINT '--- F-3.2.04 torneo.pais_validar: ISO de 2 letras';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.05 torneo.pais_validar: ISO de 4 letras => 1 error
PRINT '--- F-3.2.05 torneo.pais_validar: ISO de 4 letras';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.06 torneo.pais_validar: ISO con numero => 1 error
PRINT '--- F-3.2.06 torneo.pais_validar: ISO con numero';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ1', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.07 torneo.pais_validar: ISO con simbolo => 1 error
PRINT '--- F-3.2.07 torneo.pais_validar: ISO con simbolo';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ-', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.08 torneo.pais_validar: ISO con espacio al inicio => 1 error
PRINT '--- F-3.2.08 torneo.pais_validar: ISO con espacio al inicio';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, ' ZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.09 torneo.pais_validar: ISO con espacio al final => 1 error
PRINT '--- F-3.2.09 torneo.pais_validar: ISO con espacio al final';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ ', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.10 torneo.pais_validar: ISO duplicado => 1 error
PRINT '--- F-3.2.10 torneo.pais_validar: ISO duplicado';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZI', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.11 torneo.pais_validar: ISO duplicado con otra capitalizacion => 1 error
PRINT '--- F-3.2.11 torneo.pais_validar: ISO duplicado con otra capitalizacion';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'zzi', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.12 torneo.pais_validar: ISO duplicado => 1 error
PRINT '--- F-3.2.12 torneo.pais_validar: ISO duplicado';
DECLARE @e VARCHAR(2000),
        @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZM');
SET @e = ''; EXEC torneo.pais_validar @m, 'ZZN', 'Test Modificar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.13 torneo.pais_validar: Nombre nulo => 1 error
PRINT '--- F-3.2.13 torneo.pais_validar: Nombre nulo';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', NULL, 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.14 torneo.pais_validar: Nombre vacio => 1 error
PRINT '--- F-3.2.14 torneo.pais_validar: Nombre vacio';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', '', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.15 torneo.pais_validar: Nombre solo espacios => 1 error
PRINT '--- F-3.2.15 torneo.pais_validar: Nombre solo espacios';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', '   ', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.16 torneo.pais_validar: Huso nulo => 1 error
PRINT '--- F-3.2.16 torneo.pais_validar: Huso nulo';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', NULL, 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.17 torneo.pais_validar: Huso vacio => 1 error
PRINT '--- F-3.2.17 torneo.pais_validar: Huso vacio';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', '', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.18 torneo.pais_validar: Huso con 1 digito (longitud 5) => 1 error
PRINT '--- F-3.2.18 torneo.pais_validar: Huso con 1 digito (longitud 5)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-3', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.19 torneo.pais_validar: Huso con 3 digitos (longitud 7) => 1 error
PRINT '--- F-3.2.19 torneo.pais_validar: Huso con 3 digitos (longitud 7)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-003', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.20 torneo.pais_validar: Huso con prefijo incorrecto => 1 error
PRINT '--- F-3.2.20 torneo.pais_validar: Huso con prefijo incorrecto';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'GMT-03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.21 torneo.pais_validar: Huso sin signo (espacio en su lugar) => 1 error
PRINT '--- F-3.2.21 torneo.pais_validar: Huso sin signo (espacio en su lugar)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC 03', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.22 torneo.pais_validar: Huso con letra en los digitos => 1 error
PRINT '--- F-3.2.22 torneo.pais_validar: Huso con letra en los digitos';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-0A', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.23 torneo.pais_validar: Huso con espacio final (formato) => 1 error
PRINT '--- F-3.2.23 torneo.pais_validar: Huso con espacio final (formato)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03 ', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.24 torneo.pais_validar: Huso fuera de rango (mayor a +14) => 1 error
PRINT '--- F-3.2.24 torneo.pais_validar: Huso fuera de rango (mayor a +14)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC+15', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.25 torneo.pais_validar: Huso fuera de rango (menor a -12) => 1 error
PRINT '--- F-3.2.25 torneo.pais_validar: Huso fuera de rango (menor a -12)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-13', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.26 torneo.pais_validar: Huso fuera de rango (+99) => 1 error
PRINT '--- F-3.2.26 torneo.pais_validar: Huso fuera de rango (+99)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC+99', 100, @e OUTPUT; PRINT @e;
GO

-- F-3.2.27 torneo.pais_validar: PBI negativo => 1 error
PRINT '--- F-3.2.27 torneo.pais_validar: PBI negativo';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', -0.01, @e OUTPUT; PRINT @e;
GO

-- F-3.2.28 torneo.pais_validar: pais inexistente, ISO, nombre, huso y PBI => 5 errores
PRINT '--- F-3.2.28 torneo.pais_validar: 5 errores: pais inexistente, ISO, nombre, huso y PBI';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar 999999, 'AB', '', 'UTC3', -1, @e OUTPUT; PRINT @e;
GO

-- F-3.2.29 torneo.pais_validar: ISO, nombre, huso y PBI => 4 errores
PRINT '--- F-3.2.29 torneo.pais_validar: 4 errores: ISO, nombre, huso y PBI';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'AB', '', 'UTC3', -1, @e OUTPUT; PRINT @e;
GO

-- F-3.2.30 torneo.pais_validar: ISO, nombre y huso => 3 errores
PRINT '--- F-3.2.30 torneo.pais_validar: 3 errores: ISO, nombre y huso';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, NULL, NULL, NULL, NULL, @e OUTPUT; PRINT @e;
GO

-- -------------------------------------------------------------------------------------
-- torneo.pais_insertar: F-3.2.31 a F-3.2.55
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.2.31 torneo.pais_insertar: ISO nulo => 1 error
PRINT '--- F-3.2.31 torneo.pais_insertar: ISO nulo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar NULL, 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.32 torneo.pais_insertar: ISO vacio => 1 error
PRINT '--- F-3.2.32 torneo.pais_insertar: ISO vacio';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar '', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.33 torneo.pais_insertar: ISO de 2 letras => 1 error
PRINT '--- F-3.2.33 torneo.pais_insertar: ISO de 2 letras';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZ', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.34 torneo.pais_insertar: ISO de 4 letras => 1 error
PRINT '--- F-3.2.34 torneo.pais_insertar: ISO de 4 letras';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZZZ', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.35 torneo.pais_insertar: ISO con numero => 1 error
PRINT '--- F-3.2.35 torneo.pais_insertar: ISO con numero';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZ1', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.36 torneo.pais_insertar: ISO con simbolo => 1 error
PRINT '--- F-3.2.36 torneo.pais_insertar: ISO con simbolo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZ-', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.37 torneo.pais_insertar: ISO con espacio al inicio => 1 error
PRINT '--- F-3.2.37 torneo.pais_insertar: ISO con espacio al inicio';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar ' ZZ', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.38 torneo.pais_insertar: ISO con espacio al final => 1 error
PRINT '--- F-3.2.38 torneo.pais_insertar: ISO con espacio al final';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZ ', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.39 torneo.pais_insertar: ISO duplicado => 1 error
PRINT '--- F-3.2.39 torneo.pais_insertar: ISO duplicado';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZI', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.40 torneo.pais_insertar: ISO duplicado con otra capitalizacion => 1 error
PRINT '--- F-3.2.40 torneo.pais_insertar: ISO duplicado con otra capitalizacion';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'zzi', 'Test', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.41 torneo.pais_insertar: Nombre nulo => 1 error
PRINT '--- F-3.2.41 torneo.pais_insertar: Nombre nulo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', NULL, 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.42 torneo.pais_insertar: Nombre vacio => 1 error
PRINT '--- F-3.2.42 torneo.pais_insertar: Nombre vacio';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', '', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.43 torneo.pais_insertar: Nombre solo espacios => 1 error
PRINT '--- F-3.2.43 torneo.pais_insertar: Nombre solo espacios';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', '   ', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.44 torneo.pais_insertar: Huso nulo => 1 error
PRINT '--- F-3.2.44 torneo.pais_insertar: Huso nulo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', NULL, 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.45 torneo.pais_insertar: Huso vacio => 1 error
PRINT '--- F-3.2.45 torneo.pais_insertar: Huso vacio';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', '', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.46 torneo.pais_insertar: Huso con 1 digito => 1 error
PRINT '--- F-3.2.46 torneo.pais_insertar: Huso con 1 digito';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC-3', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.47 torneo.pais_insertar: Huso con prefijo incorrecto => 1 error
PRINT '--- F-3.2.47 torneo.pais_insertar: Huso con prefijo incorrecto';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', 'GMT-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.48 torneo.pais_insertar: Huso sin signo => 1 error
PRINT '--- F-3.2.48 torneo.pais_insertar: Huso sin signo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC 03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.49 torneo.pais_insertar: Huso con letra => 1 error
PRINT '--- F-3.2.49 torneo.pais_insertar: Huso con letra';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC-0A', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.50 torneo.pais_insertar: Huso fuera de rango (mayor a +14) => 1 error
PRINT '--- F-3.2.50 torneo.pais_insertar: Huso fuera de rango (mayor a +14)';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC+15', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.51 torneo.pais_insertar: Huso fuera de rango (menor a -12) => 1 error
PRINT '--- F-3.2.51 torneo.pais_insertar: Huso fuera de rango (menor a -12)';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC-13', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.52 torneo.pais_insertar: PBI negativo => 1 error
PRINT '--- F-3.2.52 torneo.pais_insertar: PBI negativo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC-03', -0.01, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.53 torneo.pais_insertar: ISO y nombre => 2 errores
PRINT '--- F-3.2.53 torneo.pais_insertar: 2 errores: ISO y nombre';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'ZZ', '', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.54 torneo.pais_insertar: ISO, nombre y huso => 3 errores
PRINT '--- F-3.2.54 torneo.pais_insertar: 3 errores: ISO, nombre y huso';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar NULL, NULL, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.55 torneo.pais_insertar: ISO, nombre, huso y PBI => 4 errores
PRINT '--- F-3.2.55 torneo.pais_insertar: 4 errores: ISO, nombre, huso y PBI';
DECLARE @id INT;
BEGIN TRY EXEC torneo.pais_insertar 'AB', '', 'UTC3', -1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.pais_modificar: F-3.2.56 a F-3.2.81
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.2.56 torneo.pais_modificar: Pais inexistente => 1 error
PRINT '--- F-3.2.56 torneo.pais_modificar: Pais inexistente';
BEGIN TRY EXEC torneo.pais_modificar 999999, 'ZZY', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.57 torneo.pais_modificar: Id nulo => 1 error
PRINT '--- F-3.2.57 torneo.pais_modificar: Id nulo';
BEGIN TRY EXEC torneo.pais_modificar NULL, 'ZZY', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.58 torneo.pais_modificar: id obligatorio y ISO duplicado => 2 errores
PRINT '--- F-3.2.58 torneo.pais_modificar: 2 errores: id obligatorio y ISO duplicado';
BEGIN TRY EXEC torneo.pais_modificar NULL, 'ZZM', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.59 torneo.pais_modificar: ISO nulo => 1 error
PRINT '--- F-3.2.59 torneo.pais_modificar: ISO nulo';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, NULL, 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.60 torneo.pais_modificar: ISO vacio => 1 error
PRINT '--- F-3.2.60 torneo.pais_modificar: ISO vacio';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, '', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.61 torneo.pais_modificar: ISO de 2 letras => 1 error
PRINT '--- F-3.2.61 torneo.pais_modificar: ISO de 2 letras';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZ', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.62 torneo.pais_modificar: ISO de 4 letras => 1 error
PRINT '--- F-3.2.62 torneo.pais_modificar: ISO de 4 letras';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZZZ', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.63 torneo.pais_modificar: ISO con numero => 1 error
PRINT '--- F-3.2.63 torneo.pais_modificar: ISO con numero';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZ1', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.64 torneo.pais_modificar: ISO con espacio al final => 1 error
PRINT '--- F-3.2.64 torneo.pais_modificar: ISO con espacio al final';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZ ', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.65 torneo.pais_modificar: ISO duplicado => 1 error
PRINT '--- F-3.2.65 torneo.pais_modificar: ISO duplicado';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZN', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.66 torneo.pais_modificar: ISO duplicado con otra capitalizacion => 1 error
PRINT '--- F-3.2.66 torneo.pais_modificar: ISO duplicado con otra capitalizacion';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'zzn', 'Test', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.67 torneo.pais_modificar: Nombre nulo => 1 error
PRINT '--- F-3.2.67 torneo.pais_modificar: Nombre nulo';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', NULL, 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.68 torneo.pais_modificar: Nombre vacio => 1 error
PRINT '--- F-3.2.68 torneo.pais_modificar: Nombre vacio';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', '', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.69 torneo.pais_modificar: Nombre solo espacios => 1 error
PRINT '--- F-3.2.69 torneo.pais_modificar: Nombre solo espacios';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', '   ', 'UTC-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.70 torneo.pais_modificar: Huso nulo => 1 error
PRINT '--- F-3.2.70 torneo.pais_modificar: Huso nulo';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test', NULL, 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.71 torneo.pais_modificar: Huso vacio => 1 error
PRINT '--- F-3.2.71 torneo.pais_modificar: Huso vacio';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test', '', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.72 torneo.pais_modificar: Huso con 1 digito => 1 error
PRINT '--- F-3.2.72 torneo.pais_modificar: Huso con 1 digito';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC-3', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.73 torneo.pais_modificar: Huso con prefijo incorrecto => 1 error
PRINT '--- F-3.2.73 torneo.pais_modificar: Huso con prefijo incorrecto';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'GMT-03', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.74 torneo.pais_modificar: Huso con letra => 1 error
PRINT '--- F-3.2.74 torneo.pais_modificar: Huso con letra';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC-0A', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.75 torneo.pais_modificar: Huso fuera de rango (mayor a +14) => 1 error
PRINT '--- F-3.2.75 torneo.pais_modificar: Huso fuera de rango (mayor a +14)';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC+15', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.76 torneo.pais_modificar: Huso fuera de rango (menor a -12) => 1 error
PRINT '--- F-3.2.76 torneo.pais_modificar: Huso fuera de rango (menor a -12)';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC-13', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.77 torneo.pais_modificar: PBI negativo => 1 error
PRINT '--- F-3.2.77 torneo.pais_modificar: PBI negativo';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC-03', -0.01; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.78 torneo.pais_modificar: ISO duplicado y huso fuera de rango => 2 errores
PRINT '--- F-3.2.78 torneo.pais_modificar: 2 errores: ISO duplicado y huso fuera de rango';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZN', 'Test', 'UTC+15', 10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.79 torneo.pais_modificar: pais inexistente, nombre y PBI => 3 errores
PRINT '--- F-3.2.79 torneo.pais_modificar: 3 errores: pais inexistente, nombre y PBI';
BEGIN TRY EXEC torneo.pais_modificar 999999, 'ZZY', '', 'UTC-03', -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.80 torneo.pais_modificar: ISO duplicado, nombre, huso fuera de rango y PBI => 4 errores
PRINT '--- F-3.2.80 torneo.pais_modificar: 4 errores: ISO duplicado, nombre, huso fuera de rango y PBI';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZN', '', 'UTC+15', -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.81 torneo.pais_modificar: pais inexistente, ISO, nombre, huso y PBI => 5 errores
PRINT '--- F-3.2.81 torneo.pais_modificar: 5 errores: pais inexistente, ISO, nombre, huso y PBI';
BEGIN TRY EXEC torneo.pais_modificar 999999, 'AB', '', 'UTC3', -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.pais_eliminar: F-3.2.82 a F-3.2.89
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.2.82 torneo.pais_eliminar: Pais inexistente => 1 error
PRINT '--- F-3.2.82 torneo.pais_eliminar: Pais inexistente';
BEGIN TRY EXEC torneo.pais_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.83 torneo.pais_eliminar: Id nulo (el mensaje dice (nulo)) => 1 error
PRINT '--- F-3.2.83 torneo.pais_eliminar: Id nulo (el mensaje dice (nulo))';
BEGIN TRY EXEC torneo.pais_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.84 torneo.pais_eliminar: Tiene sedes asociadas => 1 error
PRINT '--- F-3.2.84 torneo.pais_eliminar: Tiene sedes asociadas';
DECLARE @s INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZS');
BEGIN TRY EXEC torneo.pais_eliminar @s; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.85 torneo.pais_eliminar: Tiene una seleccion participante => 1 error
PRINT '--- F-3.2.85 torneo.pais_eliminar: Tiene una seleccion participante';
DECLARE @l INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZL');
BEGIN TRY EXEC torneo.pais_eliminar @l; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.86 torneo.pais_eliminar: Tiene arbitros registrados => 1 error
PRINT '--- F-3.2.86 torneo.pais_eliminar: Tiene arbitros registrados';
DECLARE @r INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZR');
BEGIN TRY EXEC torneo.pais_eliminar @r; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.87 torneo.pais_eliminar: Es pais de interes de campañas publicitarias => 1 error
PRINT '--- F-3.2.87 torneo.pais_eliminar: Es pais de interes de campañas publicitarias';
DECLARE @c INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZC');
BEGIN TRY EXEC torneo.pais_eliminar @c; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.88 torneo.pais_eliminar: pais de interes y mercado de piezas => 2 errores
PRINT '--- F-3.2.88 torneo.pais_eliminar: 2 errores: pais de interes y mercado de piezas';
DECLARE @p INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZP');
BEGIN TRY EXEC torneo.pais_eliminar @p; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.89 torneo.pais_eliminar: sedes, seleccion, arbitros, interes de campañas y mercado de piezas => 5 errores
PRINT '--- F-3.2.89 torneo.pais_eliminar: 5 errores: sedes, seleccion, arbitros, interes de campañas y mercado de piezas';
DECLARE @t INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZT');
BEGIN TRY EXEC torneo.pais_eliminar @t; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.confederacion_modificar: F-3.2.90 a F-3.2.99
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.2.90 torneo.confederacion_modificar: Confederacion inexistente => 1 error
PRINT '--- F-3.2.90 torneo.confederacion_modificar: Confederacion inexistente';
BEGIN TRY EXEC torneo.confederacion_modificar 999999, 'OFC'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.91 torneo.confederacion_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.2.91 torneo.confederacion_modificar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC torneo.confederacion_modificar NULL, 'OFC'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.92 torneo.confederacion_modificar: Nombre nulo => 1 error
PRINT '--- F-3.2.92 torneo.confederacion_modificar: Nombre nulo';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
BEGIN TRY EXEC torneo.confederacion_modificar @u, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.93 torneo.confederacion_modificar: Nombre vacio => 1 error
PRINT '--- F-3.2.93 torneo.confederacion_modificar: Nombre vacio';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
BEGIN TRY EXEC torneo.confederacion_modificar @u, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.94 torneo.confederacion_modificar: Nombre fuera de la lista => 1 error
PRINT '--- F-3.2.94 torneo.confederacion_modificar: Nombre fuera de la lista';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
BEGIN TRY EXEC torneo.confederacion_modificar @u, 'XYZ'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.95 torneo.confederacion_modificar: Espacio al inicio: no coincide con la lista => 1 error
PRINT '--- F-3.2.95 torneo.confederacion_modificar: Espacio al inicio: no coincide con la lista';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
BEGIN TRY EXEC torneo.confederacion_modificar @u, ' UEFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.96 torneo.confederacion_modificar: Duplicada: AFC pertenece a otra confederacion => 1 error
PRINT '--- F-3.2.96 torneo.confederacion_modificar: Duplicada: AFC pertenece a otra confederacion';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
BEGIN TRY EXEC torneo.confederacion_modificar @u, 'AFC'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.97 torneo.confederacion_modificar: Duplicada: CONMEBOL pertenece a otra confederacion => 1 error
PRINT '--- F-3.2.97 torneo.confederacion_modificar: Duplicada: CONMEBOL pertenece a otra confederacion';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
BEGIN TRY EXEC torneo.confederacion_modificar @u, 'CONMEBOL'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.98 torneo.confederacion_modificar: Duplicada con otra capitalizacion => 1 error
PRINT '--- F-3.2.98 torneo.confederacion_modificar: Duplicada con otra capitalizacion';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
BEGIN TRY EXEC torneo.confederacion_modificar @u, 'afc'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.99 torneo.confederacion_modificar: confederacion inexistente y nombre duplicado (AFC es de otro id) => 2 errores
PRINT '--- F-3.2.99 torneo.confederacion_modificar: 2 errores: confederacion inexistente y nombre duplicado (AFC es de otro id)';
BEGIN TRY EXEC torneo.confederacion_modificar 999999, 'AFC'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.confederacion_insertar: F-3.2.100 a F-3.2.112
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.2.100 torneo.confederacion_insertar: Duplicada: CONCACAF (la mas larga de la lista) ya esta registrada por el escenario (Mexico) => 1 error
PRINT '--- F-3.2.100 torneo.confederacion_insertar: Duplicada: CONCACAF (la mas larga de la lista) ya esta registrada por el escenario (Mexico)';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'CONCACAF', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.101 torneo.confederacion_insertar: Nombre nulo => 1 error
PRINT '--- F-3.2.101 torneo.confederacion_insertar: Nombre nulo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.102 torneo.confederacion_insertar: Nombre vacio => 1 error
PRINT '--- F-3.2.102 torneo.confederacion_insertar: Nombre vacio';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar '', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.103 torneo.confederacion_insertar: Nombre solo espacios => 1 error
PRINT '--- F-3.2.103 torneo.confederacion_insertar: Nombre solo espacios';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar '   ', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.104 torneo.confederacion_insertar: Nombre fuera de la lista => 1 error
PRINT '--- F-3.2.104 torneo.confederacion_insertar: Nombre fuera de la lista';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'XYZ', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.105 torneo.confederacion_insertar: Nombre fuera de la lista (FIFA no es confederacion) => 1 error
PRINT '--- F-3.2.105 torneo.confederacion_insertar: Nombre fuera de la lista (FIFA no es confederacion)';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'FIFA', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.106 torneo.confederacion_insertar: Nombre incompleto => 1 error
PRINT '--- F-3.2.106 torneo.confederacion_insertar: Nombre incompleto';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'UEF', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.107 torneo.confederacion_insertar: Nombre con letra de mas => 1 error
PRINT '--- F-3.2.107 torneo.confederacion_insertar: Nombre con letra de mas';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'UEFAA', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.108 torneo.confederacion_insertar: Espacio al inicio: no coincide con la lista => 1 error
PRINT '--- F-3.2.108 torneo.confederacion_insertar: Espacio al inicio: no coincide con la lista';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar ' OFC', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.109 torneo.confederacion_insertar: Duplicada => 1 error
PRINT '--- F-3.2.109 torneo.confederacion_insertar: Duplicada';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'AFC', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.110 torneo.confederacion_insertar: Duplicada (CONMEBOL ya esta registrada) => 1 error
PRINT '--- F-3.2.110 torneo.confederacion_insertar: Duplicada (CONMEBOL ya esta registrada)';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'CONMEBOL', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.111 torneo.confederacion_insertar: Duplicada con otra capitalizacion => 1 error
PRINT '--- F-3.2.111 torneo.confederacion_insertar: Duplicada con otra capitalizacion';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'afc', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.112 torneo.confederacion_insertar: Duplicada con espacio al final => 1 error
PRINT '--- F-3.2.112 torneo.confederacion_insertar: Duplicada con espacio al final';
DECLARE @id INT;
BEGIN TRY EXEC torneo.confederacion_insertar 'AFC ', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.confederacion_eliminar: F-3.2.113 a F-3.2.115
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.2.113 torneo.confederacion_eliminar: Confederacion inexistente => 1 error
PRINT '--- F-3.2.113 torneo.confederacion_eliminar: Confederacion inexistente';
BEGIN TRY EXEC torneo.confederacion_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.114 torneo.confederacion_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.2.114 torneo.confederacion_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC torneo.confederacion_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.2.115 torneo.confederacion_eliminar: Tiene selecciones afiliadas => 1 error
PRINT '--- F-3.2.115 torneo.confederacion_eliminar: Tiene selecciones afiliadas';
DECLARE @c INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CONMEBOL');
BEGIN TRY EXEC torneo.confederacion_eliminar @c; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.3 torneo.sede
-- ============================================================

-- -------------------------------------------------------------------------------------
-- torneo.sede_insertar: F-3.3.01 a F-3.3.24
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.3.01 torneo.sede_insertar: Nombre nulo => 1 error
PRINT '--- F-3.3.01 torneo.sede_insertar: Nombre nulo';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar NULL, 'Ciudad X', @pa, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.02 torneo.sede_insertar: Nombre vacio => 1 error
PRINT '--- F-3.3.02 torneo.sede_insertar: Nombre vacio';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar '', 'Ciudad X', @pa, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.03 torneo.sede_insertar: Nombre solo espacios => 1 error
PRINT '--- F-3.3.03 torneo.sede_insertar: Nombre solo espacios';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar '   ', 'Ciudad X', @pa, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.04 torneo.sede_insertar: Ciudad nula => 1 error
PRINT '--- F-3.3.04 torneo.sede_insertar: Ciudad nula';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', NULL, @pa, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.05 torneo.sede_insertar: Ciudad vacia => 1 error
PRINT '--- F-3.3.05 torneo.sede_insertar: Ciudad vacia';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', '', @pa, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.06 torneo.sede_insertar: Ciudad solo espacios => 1 error
PRINT '--- F-3.3.06 torneo.sede_insertar: Ciudad solo espacios';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', '   ', @pa, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.07 torneo.sede_insertar: Pais inexistente => 1 error
PRINT '--- F-3.3.07 torneo.sede_insertar: Pais inexistente';
DECLARE @id INT;
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', 999999, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.08 torneo.sede_insertar: Pais nulo => 1 error
PRINT '--- F-3.3.08 torneo.sede_insertar: Pais nulo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', NULL, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.09 torneo.sede_insertar: Capacidad nula => 1 error
PRINT '--- F-3.3.09 torneo.sede_insertar: Capacidad nula';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, NULL, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.10 torneo.sede_insertar: Capacidad 0 => 1 error
PRINT '--- F-3.3.10 torneo.sede_insertar: Capacidad 0';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 0, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.11 torneo.sede_insertar: Capacidad negativa => 1 error
PRINT '--- F-3.3.11 torneo.sede_insertar: Capacidad negativa';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, -1, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.12 torneo.sede_insertar: Huso nulo => 1 error
PRINT '--- F-3.3.12 torneo.sede_insertar: Huso nulo';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.13 torneo.sede_insertar: Huso vacio => 1 error
PRINT '--- F-3.3.13 torneo.sede_insertar: Huso vacio';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, '', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.14 torneo.sede_insertar: Huso con 1 digito => 1 error
PRINT '--- F-3.3.14 torneo.sede_insertar: Huso con 1 digito';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.15 torneo.sede_insertar: Huso con prefijo incorrecto => 1 error
PRINT '--- F-3.3.15 torneo.sede_insertar: Huso con prefijo incorrecto';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'GMT-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.16 torneo.sede_insertar: Huso sin signo => 1 error
PRINT '--- F-3.3.16 torneo.sede_insertar: Huso sin signo';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC 03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.17 torneo.sede_insertar: Huso con letra => 1 error
PRINT '--- F-3.3.17 torneo.sede_insertar: Huso con letra';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC-0A', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.18 torneo.sede_insertar: Huso fuera de rango (mayor a +14) => 1 error
PRINT '--- F-3.3.18 torneo.sede_insertar: Huso fuera de rango (mayor a +14)';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC+15', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.19 torneo.sede_insertar: Huso fuera de rango (menor a -12) => 1 error
PRINT '--- F-3.3.19 torneo.sede_insertar: Huso fuera de rango (menor a -12)';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC-13', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.20 torneo.sede_insertar: Duplicado: mismo nombre y ciudad que la base => 1 error
PRINT '--- F-3.3.20 torneo.sede_insertar: Duplicado: mismo nombre y ciudad que la base';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede Base', 'Ciudad Test', @pa, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.21 torneo.sede_insertar: nombre y ciudad => 2 errores
PRINT '--- F-3.3.21 torneo.sede_insertar: 2 errores: nombre y ciudad';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_insertar '', '', @pa, 10, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.22 torneo.sede_insertar: pais inexistente y capacidad => 2 errores
PRINT '--- F-3.3.22 torneo.sede_insertar: 2 errores: pais inexistente y capacidad';
DECLARE @id INT;
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', 999999, 0, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.23 torneo.sede_insertar: pais, capacidad, huso (formato) y duplicado => 4 errores
PRINT '--- F-3.3.23 torneo.sede_insertar: 4 errores: pais, capacidad, huso (formato) y duplicado';
DECLARE @id INT;
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede Base', 'Ciudad Test', 999999, -1, 'UTC3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.24 torneo.sede_insertar: 5 errores (maximo): nombre, ciudad, pais, capacidad y huso => 5 errores
PRINT '--- F-3.3.24 torneo.sede_insertar: 5 errores (maximo): nombre, ciudad, pais, capacidad y huso';
DECLARE @id INT;
BEGIN TRY EXEC torneo.sede_insertar NULL, NULL, NULL, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.sede_modificar: F-3.3.25 a F-3.3.55
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.3.25 torneo.sede_modificar: Sede inexistente => 1 error
PRINT '--- F-3.3.25 torneo.sede_modificar: Sede inexistente';
DECLARE @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar 999999, 'Test Sede Nueva', 'Ciudad Nueva', @pa, 10, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.26 torneo.sede_modificar: Id nulo => 1 error
PRINT '--- F-3.3.26 torneo.sede_modificar: Id nulo';
DECLARE @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar NULL, 'Test Sede Nueva', 'Ciudad Nueva', @pa, 10, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.27 torneo.sede_modificar: Nombre nulo => 1 error
PRINT '--- F-3.3.27 torneo.sede_modificar: Nombre nulo';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, NULL, 'Ciudad Mod', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.28 torneo.sede_modificar: Nombre vacio => 1 error
PRINT '--- F-3.3.28 torneo.sede_modificar: Nombre vacio';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, '', 'Ciudad Mod', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.29 torneo.sede_modificar: Nombre solo espacios => 1 error
PRINT '--- F-3.3.29 torneo.sede_modificar: Nombre solo espacios';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, '   ', 'Ciudad Mod', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.30 torneo.sede_modificar: Ciudad nula => 1 error
PRINT '--- F-3.3.30 torneo.sede_modificar: Ciudad nula';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', NULL, @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.31 torneo.sede_modificar: Ciudad vacia => 1 error
PRINT '--- F-3.3.31 torneo.sede_modificar: Ciudad vacia';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', '', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.32 torneo.sede_modificar: Ciudad solo espacios => 1 error
PRINT '--- F-3.3.32 torneo.sede_modificar: Ciudad solo espacios';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', '   ', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.33 torneo.sede_modificar: Pais inexistente => 1 error
PRINT '--- F-3.3.33 torneo.sede_modificar: Pais inexistente';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', 999999, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.34 torneo.sede_modificar: Pais nulo => 1 error
PRINT '--- F-3.3.34 torneo.sede_modificar: Pais nulo';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', NULL, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.35 torneo.sede_modificar: Capacidad nula => 1 error
PRINT '--- F-3.3.35 torneo.sede_modificar: Capacidad nula';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, NULL, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.36 torneo.sede_modificar: Capacidad 0 => 1 error
PRINT '--- F-3.3.36 torneo.sede_modificar: Capacidad 0';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 0, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.37 torneo.sede_modificar: Capacidad negativa => 1 error
PRINT '--- F-3.3.37 torneo.sede_modificar: Capacidad negativa';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, -1, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.38 torneo.sede_modificar: Huso nulo => 1 error
PRINT '--- F-3.3.38 torneo.sede_modificar: Huso nulo';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.39 torneo.sede_modificar: Huso vacio => 1 error
PRINT '--- F-3.3.39 torneo.sede_modificar: Huso vacio';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.40 torneo.sede_modificar: Huso con 1 digito => 1 error
PRINT '--- F-3.3.40 torneo.sede_modificar: Huso con 1 digito';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'UTC-3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.41 torneo.sede_modificar: Huso con prefijo incorrecto => 1 error
PRINT '--- F-3.3.41 torneo.sede_modificar: Huso con prefijo incorrecto';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'GMT-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.42 torneo.sede_modificar: Huso con letra => 1 error
PRINT '--- F-3.3.42 torneo.sede_modificar: Huso con letra';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'UTC-0A'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.43 torneo.sede_modificar: Huso fuera de rango (mayor a +14) => 1 error
PRINT '--- F-3.3.43 torneo.sede_modificar: Huso fuera de rango (mayor a +14)';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'UTC+15'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.44 torneo.sede_modificar: Huso fuera de rango (menor a -12) => 1 error
PRINT '--- F-3.3.44 torneo.sede_modificar: Huso fuera de rango (menor a -12)';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'UTC-13'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.45 torneo.sede_modificar: Duplicado: nombre y ciudad de otra sede => 1 error
PRINT '--- F-3.3.45 torneo.sede_modificar: Duplicado: nombre y ciudad de otra sede';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Otra', 'Ciudad Mod', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.46 torneo.sede_modificar: Duplicado con otra capitalizacion => 1 error
PRINT '--- F-3.3.46 torneo.sede_modificar: Duplicado con otra capitalizacion';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'TEST SEDE OTRA', 'CIUDAD MOD', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.47 torneo.sede_modificar: Duplicado con espacios al final => 1 error
PRINT '--- F-3.3.47 torneo.sede_modificar: Duplicado con espacios al final';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Otra  ', 'Ciudad Mod  ', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.48 torneo.sede_modificar: Con partidos: no se puede cambiar el huso => 1 error
PRINT '--- F-3.3.48 torneo.sede_modificar: Con partidos: no se puede cambiar el huso';
DECLARE @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @p, 'Test Sede Partido', 'Ciudad Partido', @pa, 40000, 'UTC-04'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.49 torneo.sede_modificar: Capacidad menor a la asistencia registrada => 1 error
PRINT '--- F-3.3.49 torneo.sede_modificar: Capacidad menor a la asistencia registrada';
DECLARE @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @p, 'Test Sede Partido', 'Ciudad Partido', @pa, 39999, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.50 torneo.sede_modificar: 1 error: capacidad nula (el control contra la asistencia no se dispara con NULL) => 1 error
PRINT '--- F-3.3.50 torneo.sede_modificar: 1 error: capacidad nula (el control contra la asistencia no se dispara con NULL)';
DECLARE @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @p, 'Test Sede Partido', 'Ciudad Partido', @pa, NULL, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.51 torneo.sede_modificar: sede inexistente y duplicado => 2 errores
PRINT '--- F-3.3.51 torneo.sede_modificar: 2 errores: sede inexistente y duplicado';
DECLARE @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar 999999, 'Test Sede Otra', 'Ciudad Mod', @pa, 10, 'UTC-03'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.52 torneo.sede_modificar: duplicado, capacidad y huso fuera de rango => 3 errores
PRINT '--- F-3.3.52 torneo.sede_modificar: 3 errores: duplicado, capacidad y huso fuera de rango';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Otra', 'Ciudad Mod', @pa, 0, 'UTC+15'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.53 torneo.sede_modificar: id obligatorio, nombre, ciudad, pais, capacidad y huso => 6 errores
PRINT '--- F-3.3.53 torneo.sede_modificar: 6 errores: id obligatorio, nombre, ciudad, pais, capacidad y huso';
BEGIN TRY EXEC torneo.sede_modificar NULL, NULL, NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.54 torneo.sede_modificar: nombre, ciudad, pais, capacidad y huso (formato); sin partidos no hay controles extra => 5 errores
PRINT '--- F-3.3.54 torneo.sede_modificar: 5 errores: nombre, ciudad, pais, capacidad y huso (formato); sin partidos no hay controles extra';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%');
BEGIN TRY EXEC torneo.sede_modificar @m, '', '', 999999, -1, 'UTC3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.55 torneo.sede_modificar: 7 errores (maximo): nombre, ciudad, pais, capacidad, huso (formato), cambio de huso con partidos y capacidad menor a la asistencia => 7 errores
PRINT '--- F-3.3.55 torneo.sede_modificar: 7 errores (maximo): nombre, ciudad, pais, capacidad, huso (formato), cambio de huso con partidos y capacidad menor a la asistencia';
DECLARE @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido');
BEGIN TRY EXEC torneo.sede_modificar @p, '', '', 999999, -1, 'UTC3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.sede_eliminar: F-3.3.56 a F-3.3.58
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.3.56 torneo.sede_eliminar: Sede inexistente => 1 error
PRINT '--- F-3.3.56 torneo.sede_eliminar: Sede inexistente';
BEGIN TRY EXEC torneo.sede_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.57 torneo.sede_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.3.57 torneo.sede_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC torneo.sede_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.3.58 torneo.sede_eliminar: Tiene partidos asociados => 1 error
PRINT '--- F-3.3.58 torneo.sede_eliminar: Tiene partidos asociados';
DECLARE @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido');
BEGIN TRY EXEC torneo.sede_eliminar @p; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.4 torneo.seleccion
-- ============================================================

-- -------------------------------------------------------------------------------------
-- torneo.seleccion_insertar: F-3.4.01 a F-3.4.18
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.4.01 torneo.seleccion_insertar: Pais nulo => 1 error
PRINT '--- F-3.4.01 torneo.seleccion_insertar: Pais nulo';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
BEGIN TRY EXEC torneo.seleccion_insertar NULL, @c1, 'A', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.02 torneo.seleccion_insertar: Pais inexistente => 1 error
PRINT '--- F-3.4.02 torneo.seleccion_insertar: Pais inexistente';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
BEGIN TRY EXEC torneo.seleccion_insertar 999999, @c1, 'A', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.03 torneo.seleccion_insertar: Pais ya tiene seleccion => 1 error
PRINT '--- F-3.4.03 torneo.seleccion_insertar: Pais ya tiene seleccion';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQA');
BEGIN TRY EXEC torneo.seleccion_insertar @pa, @c1, 'A', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.04 torneo.seleccion_insertar: Confederacion nula => 1 error
PRINT '--- F-3.4.04 torneo.seleccion_insertar: Confederacion nula';
DECLARE @id INT,
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, NULL, 'A', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.05 torneo.seleccion_insertar: Confederacion inexistente => 1 error
PRINT '--- F-3.4.05 torneo.seleccion_insertar: Confederacion inexistente';
DECLARE @id INT,
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, 999999, 'A', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.06 torneo.seleccion_insertar: Grupo nulo => 1 error
PRINT '--- F-3.4.06 torneo.seleccion_insertar: Grupo nulo';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.07 torneo.seleccion_insertar: Grupo vacio => 1 error
PRINT '--- F-3.4.07 torneo.seleccion_insertar: Grupo vacio';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, '', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.08 torneo.seleccion_insertar: Grupo solo espacio => 1 error
PRINT '--- F-3.4.08 torneo.seleccion_insertar: Grupo solo espacio';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, ' ', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.09 torneo.seleccion_insertar: Grupo fuera de rango (despues de L) => 1 error
PRINT '--- F-3.4.09 torneo.seleccion_insertar: Grupo fuera de rango (despues de L)';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, 'M', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.10 torneo.seleccion_insertar: Grupo fuera de rango en minuscula => 1 error
PRINT '--- F-3.4.10 torneo.seleccion_insertar: Grupo fuera de rango en minuscula';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, 'm', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.11 torneo.seleccion_insertar: Grupo fuera de rango (antes de A) => 1 error
PRINT '--- F-3.4.11 torneo.seleccion_insertar: Grupo fuera de rango (antes de A)';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, '@', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.12 torneo.seleccion_insertar: Grupo numerico => 1 error
PRINT '--- F-3.4.12 torneo.seleccion_insertar: Grupo numerico';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, '1', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.13 torneo.seleccion_insertar: Grupo con 2 letras => 1 error
PRINT '--- F-3.4.13 torneo.seleccion_insertar: Grupo con 2 letras';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, 'AB', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.14 torneo.seleccion_insertar: Grupo con espacio al inicio => 1 error
PRINT '--- F-3.4.14 torneo.seleccion_insertar: Grupo con espacio al inicio';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, ' A', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.15 torneo.seleccion_insertar: Grupo con espacio al final => 1 error
PRINT '--- F-3.4.15 torneo.seleccion_insertar: Grupo con espacio al final';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
BEGIN TRY EXEC torneo.seleccion_insertar @pl, @c1, 'A ', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.16 torneo.seleccion_insertar: pais duplicado, confederacion y grupo => 3 errores
PRINT '--- F-3.4.16 torneo.seleccion_insertar: 3 errores: pais duplicado, confederacion y grupo';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQA');
BEGIN TRY EXEC torneo.seleccion_insertar @pa, 999999, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.17 torneo.seleccion_insertar: 3 errores (maximo): pais, confederacion y grupo => 3 errores
PRINT '--- F-3.4.17 torneo.seleccion_insertar: 3 errores (maximo): pais, confederacion y grupo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.seleccion_insertar NULL, NULL, '', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.18 torneo.seleccion_insertar: 3 errores (maximo): pais inexistente, confederacion y grupo => 3 errores
PRINT '--- F-3.4.18 torneo.seleccion_insertar: 3 errores (maximo): pais inexistente, confederacion y grupo';
DECLARE @id INT;
BEGIN TRY EXEC torneo.seleccion_insertar 999999, 999999, 'Z', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.seleccion_modificar: F-3.4.19 a F-3.4.40
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.4.19 torneo.seleccion_modificar: Seleccion inexistente => 1 error
PRINT '--- F-3.4.19 torneo.seleccion_modificar: Seleccion inexistente';
DECLARE @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pn INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQN');
BEGIN TRY EXEC torneo.seleccion_modificar 999999, @pn, @c1, 'B'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.20 torneo.seleccion_modificar: Id nulo (id obligatorio) => 1 error
PRINT '--- F-3.4.20 torneo.seleccion_modificar: Id nulo (id obligatorio)';
DECLARE @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pn INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQN');
BEGIN TRY EXEC torneo.seleccion_modificar NULL, @pn, @c1, 'B'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.21 torneo.seleccion_modificar: Pais nulo => 1 error
PRINT '--- F-3.4.21 torneo.seleccion_modificar: Pais nulo';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
BEGIN TRY EXEC torneo.seleccion_modificar @m, NULL, @c1, 'B'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.22 torneo.seleccion_modificar: Pais inexistente => 1 error
PRINT '--- F-3.4.22 torneo.seleccion_modificar: Pais inexistente';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
BEGIN TRY EXEC torneo.seleccion_modificar @m, 999999, @c1, 'B'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.23 torneo.seleccion_modificar: Pais ya tiene otra seleccion => 1 error
PRINT '--- F-3.4.23 torneo.seleccion_modificar: Pais ya tiene otra seleccion';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @po INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQO');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @po, @c1, 'B'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.24 torneo.seleccion_modificar: Confederacion nula => 1 error
PRINT '--- F-3.4.24 torneo.seleccion_modificar: Confederacion nula';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, NULL, 'B'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.25 torneo.seleccion_modificar: Confederacion inexistente => 1 error
PRINT '--- F-3.4.25 torneo.seleccion_modificar: Confederacion inexistente';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, 999999, 'B'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.26 torneo.seleccion_modificar: Grupo nulo => 1 error
PRINT '--- F-3.4.26 torneo.seleccion_modificar: Grupo nulo';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.27 torneo.seleccion_modificar: Grupo vacio => 1 error
PRINT '--- F-3.4.27 torneo.seleccion_modificar: Grupo vacio';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.28 torneo.seleccion_modificar: Grupo solo espacio => 1 error
PRINT '--- F-3.4.28 torneo.seleccion_modificar: Grupo solo espacio';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, ' '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.29 torneo.seleccion_modificar: Grupo fuera de rango (despues de L) => 1 error
PRINT '--- F-3.4.29 torneo.seleccion_modificar: Grupo fuera de rango (despues de L)';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, 'M'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.30 torneo.seleccion_modificar: Grupo fuera de rango en minuscula => 1 error
PRINT '--- F-3.4.30 torneo.seleccion_modificar: Grupo fuera de rango en minuscula';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, 'm'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.31 torneo.seleccion_modificar: Grupo fuera de rango (antes de A) => 1 error
PRINT '--- F-3.4.31 torneo.seleccion_modificar: Grupo fuera de rango (antes de A)';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, '@'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.32 torneo.seleccion_modificar: Grupo numerico => 1 error
PRINT '--- F-3.4.32 torneo.seleccion_modificar: Grupo numerico';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, '1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.33 torneo.seleccion_modificar: Grupo con 2 letras => 1 error
PRINT '--- F-3.4.33 torneo.seleccion_modificar: Grupo con 2 letras';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, 'AB'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.34 torneo.seleccion_modificar: Grupo con espacio al inicio => 1 error
PRINT '--- F-3.4.34 torneo.seleccion_modificar: Grupo con espacio al inicio';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, ' A'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.35 torneo.seleccion_modificar: Grupo con espacio al final => 1 error
PRINT '--- F-3.4.35 torneo.seleccion_modificar: Grupo con espacio al final';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM');
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pm, @c1, 'A '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.36 torneo.seleccion_modificar: Con partidos de grupos: no se puede cambiar el grupo => 1 error
PRINT '--- F-3.4.36 torneo.seleccion_modificar: Con partidos de grupos: no se puede cambiar el grupo';
DECLARE @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP'),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pp INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQP');
BEGIN TRY EXEC torneo.seleccion_modificar @p, @pp, @c1, 'E'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.37 torneo.seleccion_modificar: Con partidos de grupos: cambio de grupo en minuscula => 1 error
PRINT '--- F-3.4.37 torneo.seleccion_modificar: Con partidos de grupos: cambio de grupo en minuscula';
DECLARE @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP'),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pp INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQP');
BEGIN TRY EXEC torneo.seleccion_modificar @p, @pp, @c1, 'e'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.38 torneo.seleccion_modificar: 1 error: grupo nulo => 1 error
PRINT '--- F-3.4.38 torneo.seleccion_modificar: 1 error: grupo nulo';
DECLARE @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP'),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pp INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQP');
BEGIN TRY EXEC torneo.seleccion_modificar @p, @pp, @c1, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.39 torneo.seleccion_modificar: grupo invalido y cambio de grupo con partidos => 2 errores
PRINT '--- F-3.4.39 torneo.seleccion_modificar: 2 errores: grupo invalido y cambio de grupo con partidos';
DECLARE @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP'),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pp INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQP');
BEGIN TRY EXEC torneo.seleccion_modificar @p, @pp, @c1, 'M'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.40 torneo.seleccion_modificar: 4 errores (maximo): pais, confederacion, grupo y cambio de grupo con partidos => 4 errores
PRINT '--- F-3.4.40 torneo.seleccion_modificar: 4 errores (maximo): pais, confederacion, grupo y cambio de grupo con partidos';
DECLARE @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP');
BEGIN TRY EXEC torneo.seleccion_modificar @p, 999999, 999999, 'Z'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.seleccion_eliminar: F-3.4.41 a F-3.4.45
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.4.41 torneo.seleccion_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.4.41 torneo.seleccion_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC torneo.seleccion_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.42 torneo.seleccion_eliminar: Tiene partidos asociados => 1 error
PRINT '--- F-3.4.42 torneo.seleccion_eliminar: Tiene partidos asociados';
DECLARE @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP');
BEGIN TRY EXEC torneo.seleccion_eliminar @p; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.43 torneo.seleccion_eliminar: Tiene jugadores convocados => 1 error
PRINT '--- F-3.4.43 torneo.seleccion_eliminar: Tiene jugadores convocados';
DECLARE @cv INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQV');
BEGIN TRY EXEC torneo.seleccion_eliminar @cv; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.44 torneo.seleccion_eliminar: Tiene cuerpo tecnico registrado => 1 error
PRINT '--- F-3.4.44 torneo.seleccion_eliminar: Tiene cuerpo tecnico registrado';
DECLARE @ct INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQT');
BEGIN TRY EXEC torneo.seleccion_eliminar @ct; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.4.45 torneo.seleccion_eliminar: 3 errores (maximo): partidos, convocados y cuerpo tecnico => 3 errores
PRINT '--- F-3.4.45 torneo.seleccion_eliminar: 3 errores (maximo): partidos, convocados y cuerpo tecnico';
DECLARE @k INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQK');
BEGIN TRY EXEC torneo.seleccion_eliminar @k; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.5 torneo.partido
-- ============================================================

-- -------------------------------------------------------------------------------------
-- torneo.partido_insertar: F-3.5.01 a F-3.5.25
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.5.01 torneo.partido_insertar: Sede nula => 1 error
PRINT '--- F-3.5.01 torneo.partido_insertar: Sede nula';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
BEGIN TRY EXEC torneo.partido_insertar NULL, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.02 torneo.partido_insertar: Sede inexistente => 1 error
PRINT '--- F-3.5.02 torneo.partido_insertar: Sede inexistente';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
BEGIN TRY EXEC torneo.partido_insertar 999999, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.03 torneo.partido_insertar: Fecha local nula (el UTC derivado tambien queda nulo, un solo error) => 1 error
PRINT '--- F-3.5.03 torneo.partido_insertar: Fecha local nula (el UTC derivado tambien queda nulo, un solo error)';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, NULL, 'grupos', @a1, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.04 torneo.partido_insertar: Hora local en otro huso => 1 error
PRINT '--- F-3.5.04 torneo.partido_insertar: Hora local en otro huso';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -05:00', 'grupos', @a1, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.05 torneo.partido_insertar: Hora local expresada en UTC => 1 error
PRINT '--- F-3.5.05 torneo.partido_insertar: Hora local expresada en UTC';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 18:00:00 +00:00', 'grupos', @a1, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.06 torneo.partido_insertar: UTC informado con desplazamiento distinto de +00:00 => 1 error
PRINT '--- F-3.5.06 torneo.partido_insertar: UTC informado con desplazamiento distinto de +00:00';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3, '2026-08-10 15:00:00 -03:00', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.07 torneo.partido_insertar: UTC informado que no coincide con la hora local => 1 error
PRINT '--- F-3.5.07 torneo.partido_insertar: UTC informado que no coincide con la hora local';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3, '2026-08-10 19:00:00 +00:00', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.08 torneo.partido_insertar: Fase nula => 1 error
PRINT '--- F-3.5.08 torneo.partido_insertar: Fase nula';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', NULL, @a1, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.09 torneo.partido_insertar: Fase vacia => 1 error
PRINT '--- F-3.5.09 torneo.partido_insertar: Fase vacia';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', '', @a1, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.10 torneo.partido_insertar: Fase inexistente => 1 error
PRINT '--- F-3.5.10 torneo.partido_insertar: Fase inexistente';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'amistoso', @a1, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.11 torneo.partido_insertar: Seleccion local nula => 1 error
PRINT '--- F-3.5.11 torneo.partido_insertar: Seleccion local nula';
DECLARE @id INT,
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', NULL, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.12 torneo.partido_insertar: Seleccion local inexistente => 1 error
PRINT '--- F-3.5.12 torneo.partido_insertar: Seleccion local inexistente';
DECLARE @id INT,
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', 999999, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.13 torneo.partido_insertar: Seleccion visitante nula => 1 error
PRINT '--- F-3.5.13 torneo.partido_insertar: Seleccion visitante nula';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.14 torneo.partido_insertar: Seleccion visitante inexistente => 1 error
PRINT '--- F-3.5.14 torneo.partido_insertar: Seleccion visitante inexistente';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, 999999, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.15 torneo.partido_insertar: Local y visitante iguales => 1 error
PRINT '--- F-3.5.15 torneo.partido_insertar: Local y visitante iguales';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a1, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.16 torneo.partido_insertar: Fase de grupos con selecciones de distinto grupo => 1 error
PRINT '--- F-3.5.16 torneo.partido_insertar: Fase de grupos con selecciones de distinto grupo';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @b1, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.17 torneo.partido_insertar: Duplicado: misma pareja y fase que el partido base => 1 error
PRINT '--- F-3.5.17 torneo.partido_insertar: Duplicado: misma pareja y fase que el partido base';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a2, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.18 torneo.partido_insertar: Duplicado con local y visitante invertidos => 1 error
PRINT '--- F-3.5.18 torneo.partido_insertar: Duplicado con local y visitante invertidos';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a2, @a1, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.19 torneo.partido_insertar: Sede ya tiene partido ese dia => 1 error
PRINT '--- F-3.5.19 torneo.partido_insertar: Sede ya tiene partido ese dia';
DECLARE @id INT,
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base');
BEGIN TRY EXEC torneo.partido_insertar @sb, '2026-06-15 20:00:00 -03:00', 'octavos', @a3, @b1, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.20 torneo.partido_insertar: Seleccion juega a menos de 24 h => 1 error
PRINT '--- F-3.5.20 torneo.partido_insertar: Seleccion juega a menos de 24 h';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-06-16 14:00:00 -03:00', 'octavos', @a1, @b1, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.21 torneo.partido_insertar: fase inexistente y selecciones iguales => 2 errores
PRINT '--- F-3.5.21 torneo.partido_insertar: 2 errores: fase inexistente y selecciones iguales';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'amistoso', @a1, @a1, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.22 torneo.partido_insertar: duplicado, sede ocupada y 24 h (copia exacta del partido base) => 3 errores
PRINT '--- F-3.5.22 torneo.partido_insertar: 3 errores: duplicado, sede ocupada y 24 h (copia exacta del partido base)';
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base');
BEGIN TRY EXEC torneo.partido_insertar @sb, '2026-06-15 15:00:00 -03:00', 'grupos', @a1, @a2, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.23 torneo.partido_insertar: sede, fecha, fase y seleccion local => 4 errores
PRINT '--- F-3.5.23 torneo.partido_insertar: 4 errores: sede, fecha, fase y seleccion local';
DECLARE @id INT,
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
BEGIN TRY EXEC torneo.partido_insertar 999999, NULL, 'amistoso', 999999, @a3, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.24 torneo.partido_insertar: sede, fecha, fase, local y visitante => 5 errores
PRINT '--- F-3.5.24 torneo.partido_insertar: 5 errores: sede, fecha, fase, local y visitante';
DECLARE @id INT;
BEGIN TRY EXEC torneo.partido_insertar NULL, NULL, NULL, NULL, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.25 torneo.partido_insertar: 8 errores (maximo): huso local, UTC con desplazamiento, distinto instante, fase, local, visitante, iguales y sede ocupada => 8 errores
PRINT '--- F-3.5.25 torneo.partido_insertar: 8 errores (maximo): huso local, UTC con desplazamiento, distinto instante, fase, local, visitante, iguales y sede ocupada';
DECLARE @id INT,
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base');
BEGIN TRY EXEC torneo.partido_insertar @sb, '2026-06-15 20:00:00 -05:00', 'amistoso', 999999, 999999, '2026-06-15 17:00:00 -02:00', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.partido_modificar: F-3.5.26 a F-3.5.52
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.5.26 torneo.partido_modificar: Partido inexistente => 1 error
PRINT '--- F-3.5.26 torneo.partido_modificar: Partido inexistente';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_modificar 999999, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.27 torneo.partido_modificar: Id nulo => 1 error
PRINT '--- F-3.5.27 torneo.partido_modificar: Id nulo';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_modificar NULL, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.28 torneo.partido_modificar: Sede nula => 1 error
PRINT '--- F-3.5.28 torneo.partido_modificar: Sede nula';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, NULL, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.29 torneo.partido_modificar: Sede inexistente => 1 error
PRINT '--- F-3.5.29 torneo.partido_modificar: Sede inexistente';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, 999999, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.30 torneo.partido_modificar: Fecha local nula => 1 error
PRINT '--- F-3.5.30 torneo.partido_modificar: Fecha local nula';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, NULL, 'grupos', @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.31 torneo.partido_modificar: Hora local en otro huso => 1 error
PRINT '--- F-3.5.31 torneo.partido_modificar: Hora local en otro huso';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -05:00', 'grupos', @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.32 torneo.partido_modificar: UTC informado con desplazamiento distinto de +00:00 => 1 error
PRINT '--- F-3.5.32 torneo.partido_modificar: UTC informado con desplazamiento distinto de +00:00';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, 'programado', '2026-08-10 15:00:00 -03:00'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.33 torneo.partido_modificar: UTC informado que no coincide con la hora local => 1 error
PRINT '--- F-3.5.33 torneo.partido_modificar: UTC informado que no coincide con la hora local';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, 'programado', '2026-08-10 19:00:00 +00:00'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.34 torneo.partido_modificar: Fase nula => 1 error
PRINT '--- F-3.5.34 torneo.partido_modificar: Fase nula';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', NULL, @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.35 torneo.partido_modificar: Fase inexistente => 1 error
PRINT '--- F-3.5.35 torneo.partido_modificar: Fase inexistente';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'amistoso', @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.36 torneo.partido_modificar: Seleccion local nula => 1 error
PRINT '--- F-3.5.36 torneo.partido_modificar: Seleccion local nula';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', NULL, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.37 torneo.partido_modificar: Seleccion local inexistente => 1 error
PRINT '--- F-3.5.37 torneo.partido_modificar: Seleccion local inexistente';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', 999999, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.38 torneo.partido_modificar: Seleccion visitante nula => 1 error
PRINT '--- F-3.5.38 torneo.partido_modificar: Seleccion visitante nula';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.39 torneo.partido_modificar: Seleccion visitante inexistente => 1 error
PRINT '--- F-3.5.39 torneo.partido_modificar: Seleccion visitante inexistente';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.40 torneo.partido_modificar: Local y visitante iguales => 1 error
PRINT '--- F-3.5.40 torneo.partido_modificar: Local y visitante iguales';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.41 torneo.partido_modificar: Fase de grupos con selecciones de distinto grupo => 1 error
PRINT '--- F-3.5.41 torneo.partido_modificar: Fase de grupos con selecciones de distinto grupo';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @b1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.42 torneo.partido_modificar: Duplicado: misma pareja y fase que el partido a eliminar => 1 error
PRINT '--- F-3.5.42 torneo.partido_modificar: Duplicado: misma pareja y fase que el partido a eliminar';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'dieciseisavos', @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.43 torneo.partido_modificar: Sede ya tiene partido ese dia => 1 error
PRINT '--- F-3.5.43 torneo.partido_modificar: Sede ya tiene partido ese dia';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sb, '2026-06-15 20:00:00 -03:00', 'grupos', @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.44 torneo.partido_modificar: Seleccion juega a menos de 24 h => 1 error
PRINT '--- F-3.5.44 torneo.partido_modificar: Seleccion juega a menos de 24 h';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-06-26 14:00:00 -03:00', 'grupos', @a3, @a4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.45 torneo.partido_modificar: Estado nulo => 1 error
PRINT '--- F-3.5.45 torneo.partido_modificar: Estado nulo';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.46 torneo.partido_modificar: Estado finalizado => 1 error
PRINT '--- F-3.5.46 torneo.partido_modificar: Estado finalizado';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, 'finalizado'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.47 torneo.partido_modificar: Estado inexistente => 1 error
PRINT '--- F-3.5.47 torneo.partido_modificar: Estado inexistente';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, 'cancelado'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.48 torneo.partido_modificar: Partido finalizado: no se puede reprogramar => 1 error
PRINT '--- F-3.5.48 torneo.partido_modificar: Partido finalizado: no se puede reprogramar';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base');
DECLARE @fin  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'octavos'       AND seleccion_local_id IN (@a1, @a3) AND seleccion_visitante_id IN (@a1, @a3));
BEGIN TRY EXEC torneo.partido_modificar @fin, @sb, '2026-06-25 15:00:00 -03:00', 'octavos', @a1, @a3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.49 torneo.partido_modificar: finalizado y formaciones (1 si no hay formaciones cargadas) => 2 errores
PRINT '--- F-3.5.49 torneo.partido_modificar: 2 errores: finalizado y formaciones (1 si no hay formaciones cargadas)';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base');
DECLARE @all  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));
BEGIN TRY EXEC torneo.partido_modificar @all, @sb, '2026-07-25 15:00:00 -03:00', 'dieciseisavos', @a1, @a3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.50 torneo.partido_modificar: id obligatorio, fase y estado => 3 errores
PRINT '--- F-3.5.50 torneo.partido_modificar: 3 errores: id obligatorio, fase y estado';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
BEGIN TRY EXEC torneo.partido_modificar NULL, @sl, '2026-08-10 15:00:00 -03:00', 'amistoso', @a3, @a4, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.51 torneo.partido_modificar: id, sede, fecha, fase, local, visitante y estado => 7 errores
PRINT '--- F-3.5.51 torneo.partido_modificar: 7 errores: id, sede, fecha, fase, local, visitante y estado';
BEGIN TRY EXEC torneo.partido_modificar NULL, NULL, NULL, NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.52 torneo.partido_modificar: 11 errores (maximo): huso local, UTC con desplazamiento, distinto instante, fase, local, visitante, iguales, sede ocupada, estado, finalizado y formaciones (10 si no hay formaciones cargadas) => 11 errores
PRINT '--- F-3.5.52 torneo.partido_modificar: 11 errores (maximo): huso local, UTC con desplazamiento, distinto instante, fase, local, visitante, iguales, sede ocupada, estado, finalizado y formaciones (10 si no hay formaciones cargadas)';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base');
DECLARE @all  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));
BEGIN TRY EXEC torneo.partido_modificar @all, @sb, '2026-06-15 20:00:00 -05:00', 'amistoso', 999999, 999999, 'cancelado', '2026-06-15 17:00:00 -02:00'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- torneo.partido_eliminar: F-3.5.53 a F-3.5.61
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.5.53 torneo.partido_eliminar: Partido inexistente => 1 error
PRINT '--- F-3.5.53 torneo.partido_eliminar: Partido inexistente';
BEGIN TRY EXEC torneo.partido_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.54 torneo.partido_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.5.54 torneo.partido_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC torneo.partido_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.55 torneo.partido_eliminar: Partido finalizado => 1 error
PRINT '--- F-3.5.55 torneo.partido_eliminar: Partido finalizado';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
DECLARE @fin  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'octavos'       AND seleccion_local_id IN (@a1, @a3) AND seleccion_visitante_id IN (@a1, @a3));
BEGIN TRY EXEC torneo.partido_eliminar @fin; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.56 torneo.partido_eliminar: Tiene formaciones cargadas => 1 error
PRINT '--- F-3.5.56 torneo.partido_eliminar: Tiene formaciones cargadas';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
DECLARE @form INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a1, @a4) AND seleccion_visitante_id IN (@a1, @a4));
BEGIN TRY EXEC torneo.partido_eliminar @form; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.57 torneo.partido_eliminar: Tiene tarjetas registradas => 1 error
PRINT '--- F-3.5.57 torneo.partido_eliminar: Tiene tarjetas registradas';
DECLARE @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
DECLARE @tarj INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a2, @a3) AND seleccion_visitante_id IN (@a2, @a3));
BEGIN TRY EXEC torneo.partido_eliminar @tarj; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.58 torneo.partido_eliminar: Es el partido afectado por suspensiones vigentes => 1 error
PRINT '--- F-3.5.58 torneo.partido_eliminar: Es el partido afectado por suspensiones vigentes';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB');
DECLARE @susp INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'semifinal'     AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));
BEGIN TRY EXEC torneo.partido_eliminar @susp; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.59 torneo.partido_eliminar: Tiene arbitros designados => 1 error
PRINT '--- F-3.5.59 torneo.partido_eliminar: Tiene arbitros designados';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB');
DECLARE @arb  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'tercer_puesto' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));
BEGIN TRY EXEC torneo.partido_eliminar @arb; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.60 torneo.partido_eliminar: Tiene espacios publicitarios asignados => 1 error
PRINT '--- F-3.5.60 torneo.partido_eliminar: Tiene espacios publicitarios asignados';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB');
DECLARE @pub  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'final'         AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));
BEGIN TRY EXEC torneo.partido_eliminar @pub; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.5.61 torneo.partido_eliminar: 6 errores (maximo): finalizado, formaciones, tarjetas, suspensiones, arbitros y publicidad (menos si falta cargar alguna dependencia) => 6 errores
PRINT '--- F-3.5.61 torneo.partido_eliminar: 6 errores (maximo): finalizado, formaciones, tarjetas, suspensiones, arbitros y publicidad (menos si falta cargar alguna dependencia)';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB');
DECLARE @all  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));
BEGIN TRY EXEC torneo.partido_eliminar @all; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================

-- -------------------------------------------------------------------------------------
-- plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): F-3.6.01 a F-3.6.07
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.01 plantel.persona_insertar (el SP solo valida el tipo: Tipo nulo => 1 error
PRINT '--- F-3.6.01 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Tipo nulo';
DECLARE @id INT;
BEGIN TRY EXEC plantel.persona_insertar NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.02 plantel.persona_insertar (el SP solo valida el tipo: Tipo vacio => 1 error
PRINT '--- F-3.6.02 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Tipo vacio';
DECLARE @id INT;
BEGIN TRY EXEC plantel.persona_insertar '', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.03 plantel.persona_insertar (el SP solo valida el tipo: Tipo solo espacios => 1 error
PRINT '--- F-3.6.03 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Tipo solo espacios';
DECLARE @id INT;
BEGIN TRY EXEC plantel.persona_insertar '   ', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.04 plantel.persona_insertar (el SP solo valida el tipo: Tipo inexistente => 1 error
PRINT '--- F-3.6.04 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Tipo inexistente';
DECLARE @id INT;
BEGIN TRY EXEC plantel.persona_insertar 'arbitro', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.05 plantel.persona_insertar (el SP solo valida el tipo: Tipo parecido pero incorrecto => 1 error
PRINT '--- F-3.6.05 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Tipo parecido pero incorrecto';
DECLARE @id INT;
BEGIN TRY EXEC plantel.persona_insertar 'jugadores', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.06 plantel.persona_insertar (el SP solo valida el tipo: Tipo sin guion bajo => 1 error
PRINT '--- F-3.6.06 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Tipo sin guion bajo';
DECLARE @id INT;
BEGIN TRY EXEC plantel.persona_insertar 'cuerpo tecnico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.07 plantel.persona_insertar (el SP solo valida el tipo: Tipo demasiado largo (se trunca al pasar el parametro VARCHAR(20) y queda invalido) => 1 error
PRINT '--- F-3.6.07 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Tipo demasiado largo (se trunca al pasar el parametro VARCHAR(20) y queda invalido)';
DECLARE @id INT;
BEGIN TRY EXEC plantel.persona_insertar 'jugador_con_un_nombre_demasiado_largo', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.persona_modificar: F-3.6.08 a F-3.6.15
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.08 plantel.persona_modificar: Persona inexistente => 1 error
PRINT '--- F-3.6.08 plantel.persona_modificar: Persona inexistente';
BEGIN TRY EXEC plantel.persona_modificar 999999, 'jugador'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.09 plantel.persona_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.6.09 plantel.persona_modificar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC plantel.persona_modificar NULL, 'jugador'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.10 plantel.persona_modificar: Tipo nulo => 1 error
PRINT '--- F-3.6.10 plantel.persona_modificar: Tipo nulo';
DECLARE @mod  INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
BEGIN TRY EXEC plantel.persona_modificar @mod, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.11 plantel.persona_modificar: Tipo vacio => 1 error
PRINT '--- F-3.6.11 plantel.persona_modificar: Tipo vacio';
DECLARE @mod  INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
BEGIN TRY EXEC plantel.persona_modificar @mod, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.12 plantel.persona_modificar: Tipo solo espacios => 1 error
PRINT '--- F-3.6.12 plantel.persona_modificar: Tipo solo espacios';
DECLARE @mod  INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
BEGIN TRY EXEC plantel.persona_modificar @mod, '   '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.13 plantel.persona_modificar: Tipo inexistente => 1 error
PRINT '--- F-3.6.13 plantel.persona_modificar: Tipo inexistente';
DECLARE @mod  INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
BEGIN TRY EXEC plantel.persona_modificar @mod, 'arbitro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.14 plantel.persona_modificar: 2 errores (maximo): persona inexistente y tipo invalido => 2 errores
PRINT '--- F-3.6.14 plantel.persona_modificar: 2 errores (maximo): persona inexistente y tipo invalido';
BEGIN TRY EXEC plantel.persona_modificar 999999, 'arbitro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.15 plantel.persona_modificar: 1 error: inexistente (los controles de registros no aplican a un id que no existe) => 1 error
PRINT '--- F-3.6.15 plantel.persona_modificar: 1 error: inexistente (los controles de registros no aplican a un id que no existe)';
BEGIN TRY EXEC plantel.persona_modificar 999999, 'cuerpo_tecnico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.persona_eliminar: F-3.6.16 a F-3.6.21
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.16 plantel.persona_eliminar: Persona inexistente (ya dada de baja) => 1 error (antes, la baja válida, que se deshace al final)
PRINT '--- F-3.6.16 plantel.persona_eliminar: Persona inexistente (ya dada de baja)';
DECLARE @elim    INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'elim');
BEGIN TRAN;
BEGIN TRY
    EXEC plantel.persona_eliminar @elim;
    EXEC plantel.persona_eliminar @elim;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.6.17 plantel.persona_eliminar: Persona inexistente => 1 error
PRINT '--- F-3.6.17 plantel.persona_eliminar: Persona inexistente';
BEGIN TRY EXEC plantel.persona_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.18 plantel.persona_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.6.18 plantel.persona_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC plantel.persona_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.19 plantel.persona_eliminar: Registrada como jugador => 1 error
PRINT '--- F-3.6.19 plantel.persona_eliminar: Registrada como jugador';
DECLARE @jug     INT = (SELECT persona_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27');  -- jugador sin tarjetas
BEGIN TRY EXEC plantel.persona_eliminar @jug; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.20 plantel.persona_eliminar: Registrada como cuerpo tecnico => 1 error
PRINT '--- F-3.6.20 plantel.persona_eliminar: Registrada como cuerpo tecnico';
DECLARE @ct      INT = (SELECT persona_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Ayudante');  -- cuerpo técnico sin tarjetas
BEGIN TRY EXEC plantel.persona_eliminar @ct; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.21 plantel.persona_eliminar: registrada como jugador y con tarjetas (toda persona con tarjeta es jugador o cuerpo tecnico) => 2 errores
PRINT '--- F-3.6.21 plantel.persona_eliminar: 2 errores: registrada como jugador y con tarjetas (toda persona con tarjeta es jugador o cuerpo tecnico)';
DECLARE @tarj    INT = (SELECT persona_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 05');  -- jugador con amarillas
BEGIN TRY EXEC plantel.persona_eliminar @tarj; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.cuerpo_tecnico_insertar: F-3.6.22 a F-3.6.38
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.22 plantel.cuerpo_tecnico_insertar: Seleccion inexistente => 1 error
PRINT '--- F-3.6.22 plantel.cuerpo_tecnico_insertar: Seleccion inexistente';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar 999999, 'Test CT', 'X', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.23 plantel.cuerpo_tecnico_insertar: Seleccion nula => 1 error
PRINT '--- F-3.6.23 plantel.cuerpo_tecnico_insertar: Seleccion nula';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar NULL, 'Test CT', 'X', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.24 plantel.cuerpo_tecnico_insertar: Nombre nulo => 1 error
PRINT '--- F-3.6.24 plantel.cuerpo_tecnico_insertar: Nombre nulo';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, NULL, 'X', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.25 plantel.cuerpo_tecnico_insertar: Nombre vacio => 1 error
PRINT '--- F-3.6.25 plantel.cuerpo_tecnico_insertar: Nombre vacio';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, '', 'X', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.26 plantel.cuerpo_tecnico_insertar: Nombre solo espacios => 1 error
PRINT '--- F-3.6.26 plantel.cuerpo_tecnico_insertar: Nombre solo espacios';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, '   ', 'X', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.27 plantel.cuerpo_tecnico_insertar: Apellido nulo => 1 error
PRINT '--- F-3.6.27 plantel.cuerpo_tecnico_insertar: Apellido nulo';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', NULL, 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.28 plantel.cuerpo_tecnico_insertar: Apellido vacio => 1 error
PRINT '--- F-3.6.28 plantel.cuerpo_tecnico_insertar: Apellido vacio';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', '', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.29 plantel.cuerpo_tecnico_insertar: Apellido solo espacios => 1 error
PRINT '--- F-3.6.29 plantel.cuerpo_tecnico_insertar: Apellido solo espacios';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', '   ', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.30 plantel.cuerpo_tecnico_insertar: Rol nulo => 1 error
PRINT '--- F-3.6.30 plantel.cuerpo_tecnico_insertar: Rol nulo';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'X', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.31 plantel.cuerpo_tecnico_insertar: Rol vacio => 1 error
PRINT '--- F-3.6.31 plantel.cuerpo_tecnico_insertar: Rol vacio';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'X', '', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.32 plantel.cuerpo_tecnico_insertar: Rol invalido => 1 error
PRINT '--- F-3.6.32 plantel.cuerpo_tecnico_insertar: Rol invalido';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'X', 'masajista', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.33 plantel.cuerpo_tecnico_insertar: 2do director tecnico en la misma seleccion => 1 error
PRINT '--- F-3.6.33 plantel.cuerpo_tecnico_insertar: 2do director tecnico en la misma seleccion';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Otro DT', 'director_tecnico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.34 plantel.cuerpo_tecnico_insertar: Duplicado: misma seleccion, nombre, apellido y rol => 1 error
PRINT '--- F-3.6.34 plantel.cuerpo_tecnico_insertar: Duplicado: misma seleccion, nombre, apellido y rol';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Ayudante', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.35 plantel.cuerpo_tecnico_insertar: Duplicado con espacios al final => 1 error
PRINT '--- F-3.6.35 plantel.cuerpo_tecnico_insertar: Duplicado con espacios al final';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT  ', 'Ayudante  ', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.36 plantel.cuerpo_tecnico_insertar: Espacios al inicio: antes no se detectaba, se modifico el validar para que salte el error => 1 error
PRINT '--- F-3.6.36 plantel.cuerpo_tecnico_insertar: Espacios al inicio: antes no se detectaba, se modifico el validar para que salte el error';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, '  Test CT', '  Ayudante', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.37 plantel.cuerpo_tecnico_insertar: ya tiene DT y duplicado => 2 errores
PRINT '--- F-3.6.37 plantel.cuerpo_tecnico_insertar: 2 errores: ya tiene DT y duplicado';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Director', 'director_tecnico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.38 plantel.cuerpo_tecnico_insertar: 4 errores (maximo): seleccion, nombre, apellido y rol => 4 errores
PRINT '--- F-3.6.38 plantel.cuerpo_tecnico_insertar: 4 errores (maximo): seleccion, nombre, apellido y rol';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar 999999, '', '', 'x', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.cuerpo_tecnico_modificar: F-3.6.39 a F-3.6.59
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.39 plantel.cuerpo_tecnico_modificar: Id nulo => 1 error
PRINT '--- F-3.6.39 plantel.cuerpo_tecnico_modificar: Id nulo';
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar NULL, @s1, 'Test CT', 'Inexistente', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.40 plantel.cuerpo_tecnico_modificar: Integrante inexistente => 1 error
PRINT '--- F-3.6.40 plantel.cuerpo_tecnico_modificar: Integrante inexistente';
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar 999999, @s1, 'Test CT', 'Inexistente', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.41 plantel.cuerpo_tecnico_modificar: Seleccion inexistente => 1 error
PRINT '--- F-3.6.41 plantel.cuerpo_tecnico_modificar: Seleccion inexistente';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, 999999, 'Test CT', 'Mod', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.42 plantel.cuerpo_tecnico_modificar: Seleccion nula => 1 error
PRINT '--- F-3.6.42 plantel.cuerpo_tecnico_modificar: Seleccion nula';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, NULL, 'Test CT', 'Mod', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.43 plantel.cuerpo_tecnico_modificar: Nombre nulo => 1 error
PRINT '--- F-3.6.43 plantel.cuerpo_tecnico_modificar: Nombre nulo';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, NULL, 'Mod', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.44 plantel.cuerpo_tecnico_modificar: Nombre vacio => 1 error
PRINT '--- F-3.6.44 plantel.cuerpo_tecnico_modificar: Nombre vacio';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '', 'Mod', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.45 plantel.cuerpo_tecnico_modificar: Nombre solo espacios => 1 error
PRINT '--- F-3.6.45 plantel.cuerpo_tecnico_modificar: Nombre solo espacios';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '   ', 'Mod', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.46 plantel.cuerpo_tecnico_modificar: Apellido nulo => 1 error
PRINT '--- F-3.6.46 plantel.cuerpo_tecnico_modificar: Apellido nulo';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', NULL, 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.47 plantel.cuerpo_tecnico_modificar: Apellido vacio => 1 error
PRINT '--- F-3.6.47 plantel.cuerpo_tecnico_modificar: Apellido vacio';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', '', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.48 plantel.cuerpo_tecnico_modificar: Apellido solo espacios => 1 error
PRINT '--- F-3.6.48 plantel.cuerpo_tecnico_modificar: Apellido solo espacios';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', '   ', 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.49 plantel.cuerpo_tecnico_modificar: Rol nulo => 1 error
PRINT '--- F-3.6.49 plantel.cuerpo_tecnico_modificar: Rol nulo';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Mod', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.50 plantel.cuerpo_tecnico_modificar: Rol vacio => 1 error
PRINT '--- F-3.6.50 plantel.cuerpo_tecnico_modificar: Rol vacio';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Mod', ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.51 plantel.cuerpo_tecnico_modificar: Rol invalido => 1 error
PRINT '--- F-3.6.51 plantel.cuerpo_tecnico_modificar: Rol invalido';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Mod', 'masajista'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.52 plantel.cuerpo_tecnico_modificar: Selecciona un DT en seleccion que ya tiene otro DT => 1 error
PRINT '--- F-3.6.52 plantel.cuerpo_tecnico_modificar: Selecciona un DT en seleccion que ya tiene otro DT';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Mod', 'director_tecnico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.53 plantel.cuerpo_tecnico_modificar: Duplicado: coincide con otro integrante => 1 error
PRINT '--- F-3.6.53 plantel.cuerpo_tecnico_modificar: Duplicado: coincide con otro integrante';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Otra', 'preparador_fisico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.54 plantel.cuerpo_tecnico_modificar: Duplicado con otra capitalizacion (CI) => 1 error
PRINT '--- F-3.6.54 plantel.cuerpo_tecnico_modificar: Duplicado con otra capitalizacion (CI)';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'TEST CT', 'OTRA', 'preparador_fisico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.55 plantel.cuerpo_tecnico_modificar: Duplicado con espacios al final => 1 error
PRINT '--- F-3.6.55 plantel.cuerpo_tecnico_modificar: Duplicado con espacios al final';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT  ', 'Otra  ', 'preparador_fisico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.56 plantel.cuerpo_tecnico_modificar: Espacios al inicio => 1 error
PRINT '--- F-3.6.56 plantel.cuerpo_tecnico_modificar: Espacios al inicio';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '  Test CT', '  Otra', 'preparador_fisico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.57 plantel.cuerpo_tecnico_modificar: integrante inexistente y duplicado => 2 errores
PRINT '--- F-3.6.57 plantel.cuerpo_tecnico_modificar: 2 errores: integrante inexistente y duplicado';
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar 999999, @s1, 'Test CT', 'Otra', 'preparador_fisico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.58 plantel.cuerpo_tecnico_modificar: ya tiene DT, duplicado y cambio de seleccion con tarjetas => 3 errores
PRINT '--- F-3.6.58 plantel.cuerpo_tecnico_modificar: 3 errores: ya tiene DT, duplicado y cambio de seleccion con tarjetas';
DECLARE @t  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Tarjeta', 'Tarjeta Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @t, @s1, 'Test CT', 'Director', 'director_tecnico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.59 plantel.cuerpo_tecnico_modificar: 5 errores (maximo): seleccion, nombre, apellido, rol y cambio de seleccion con tarjetas => 5 errores
PRINT '--- F-3.6.59 plantel.cuerpo_tecnico_modificar: 5 errores (maximo): seleccion, nombre, apellido, rol y cambio de seleccion con tarjetas';
DECLARE @t  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Tarjeta', 'Tarjeta Nuevo'));
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @t, 999999, '', '', 'x'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.cuerpo_tecnico_eliminar: F-3.6.60 a F-3.6.63
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.60 plantel.cuerpo_tecnico_eliminar: Integrante inexistente (ya dado de baja) => 1 error (antes, la baja válida, que se deshace al final)
PRINT '--- F-3.6.60 plantel.cuerpo_tecnico_eliminar: Integrante inexistente (ya dado de baja)';
DECLARE @e  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim');
BEGIN TRAN;
BEGIN TRY
    EXEC plantel.cuerpo_tecnico_eliminar @e;
    EXEC plantel.cuerpo_tecnico_eliminar @e;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.6.61 plantel.cuerpo_tecnico_eliminar: Integrante inexistente => 1 error
PRINT '--- F-3.6.61 plantel.cuerpo_tecnico_eliminar: Integrante inexistente';
BEGIN TRY EXEC plantel.cuerpo_tecnico_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.62 plantel.cuerpo_tecnico_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.6.62 plantel.cuerpo_tecnico_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC plantel.cuerpo_tecnico_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.63 plantel.cuerpo_tecnico_eliminar: Tiene tarjetas registradas => 1 error
PRINT '--- F-3.6.63 plantel.cuerpo_tecnico_eliminar: Tiene tarjetas registradas';
DECLARE @t  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Tarjeta', 'Tarjeta Nuevo'));
BEGIN TRY EXEC plantel.cuerpo_tecnico_eliminar @t; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.jugador_insertar: F-3.6.64 a F-3.6.82
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.64 plantel.jugador_insertar: Nombre nulo => 1 error
PRINT '--- F-3.6.64 plantel.jugador_insertar: Nombre nulo';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar NULL, 'Alta X', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.65 plantel.jugador_insertar: Nombre vacio => 1 error
PRINT '--- F-3.6.65 plantel.jugador_insertar: Nombre vacio';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar '', 'Alta X', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.66 plantel.jugador_insertar: Nombre solo espacios => 1 error
PRINT '--- F-3.6.66 plantel.jugador_insertar: Nombre solo espacios';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar '   ', 'Alta X', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.67 plantel.jugador_insertar: Apellido nulo => 1 error
PRINT '--- F-3.6.67 plantel.jugador_insertar: Apellido nulo';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', NULL, '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.68 plantel.jugador_insertar: Apellido vacio => 1 error
PRINT '--- F-3.6.68 plantel.jugador_insertar: Apellido vacio';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', '', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.69 plantel.jugador_insertar: Apellido solo espacios => 1 error
PRINT '--- F-3.6.69 plantel.jugador_insertar: Apellido solo espacios';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', '   ', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.70 plantel.jugador_insertar: Fecha de nacimiento nula => 1 error
PRINT '--- F-3.6.70 plantel.jugador_insertar: Fecha de nacimiento nula';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta X', NULL, 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.71 plantel.jugador_insertar: Menor de 15 anios (borde: un dia menos) => 1 error
PRINT '--- F-3.6.71 plantel.jugador_insertar: Menor de 15 anios (borde: un dia menos)';
DECLARE @id INT,
        @pid INT,
        @f15_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta X', @f15_menos, 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.72 plantel.jugador_insertar: Mayor de 50 anios (borde: un dia mas) => 1 error
PRINT '--- F-3.6.72 plantel.jugador_insertar: Mayor de 50 anios (borde: un dia mas)';
DECLARE @id INT,
        @pid INT,
        @f50_mas DATE = DATEADD(DAY, -1, DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta X', @f50_mas, 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.73 plantel.jugador_insertar: Fecha futura => 1 error
PRINT '--- F-3.6.73 plantel.jugador_insertar: Fecha futura';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '2999-01-01', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.74 plantel.jugador_insertar: Fecha muy antigua => 1 error
PRINT '--- F-3.6.74 plantel.jugador_insertar: Fecha muy antigua';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '1900-01-01', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.75 plantel.jugador_insertar: Posicion nula => 1 error
PRINT '--- F-3.6.75 plantel.jugador_insertar: Posicion nula';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '1995-03-15', NULL, NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.76 plantel.jugador_insertar: Posicion vacia => 1 error
PRINT '--- F-3.6.76 plantel.jugador_insertar: Posicion vacia';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '1995-03-15', '', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.77 plantel.jugador_insertar: Posicion invalida => 1 error
PRINT '--- F-3.6.77 plantel.jugador_insertar: Posicion invalida';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '1995-03-15', 'portero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.78 plantel.jugador_insertar: Duplicado: mismo nombre, apellido y fecha que la base => 1 error
PRINT '--- F-3.6.78 plantel.jugador_insertar: Duplicado: mismo nombre, apellido y fecha que la base';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Base', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.79 plantel.jugador_insertar: Duplicado con espacios al final => 1 error
PRINT '--- F-3.6.79 plantel.jugador_insertar: Duplicado con espacios al final';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU  ', 'Base  ', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.80 plantel.jugador_insertar: Espacios al inicio: ya se detecta => 1 error
PRINT '--- F-3.6.80 plantel.jugador_insertar: Espacios al inicio: ya se detecta';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar '  Test JU', '  Base', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.81 plantel.jugador_insertar: nombre y apellido => 2 errores
PRINT '--- F-3.6.81 plantel.jugador_insertar: 2 errores: nombre y apellido';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar '', '', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.82 plantel.jugador_insertar: nombre, apellido, fecha y posicion (todos nulos) => 4 errores
PRINT '--- F-3.6.82 plantel.jugador_insertar: 4 errores: nombre, apellido, fecha y posicion (todos nulos)';
DECLARE @id INT,
        @pid INT;
BEGIN TRY EXEC plantel.jugador_insertar NULL, NULL, NULL, NULL, NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.jugador_modificar: F-3.6.83 a F-3.6.104
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.83 plantel.jugador_modificar: Id nulo => 1 error
PRINT '--- F-3.6.83 plantel.jugador_modificar: Id nulo';
BEGIN TRY EXEC plantel.jugador_modificar NULL, 'Test JU', 'Inexistente', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.84 plantel.jugador_modificar: Jugador inexistente => 1 error
PRINT '--- F-3.6.84 plantel.jugador_modificar: Jugador inexistente';
BEGIN TRY EXEC plantel.jugador_modificar 999999, 'Test JU', 'Inexistente', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.85 plantel.jugador_modificar: Nombre nulo => 1 error
PRINT '--- F-3.6.85 plantel.jugador_modificar: Nombre nulo';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, NULL, 'Mod', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.86 plantel.jugador_modificar: Nombre vacio => 1 error
PRINT '--- F-3.6.86 plantel.jugador_modificar: Nombre vacio';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, '', 'Mod', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.87 plantel.jugador_modificar: Nombre solo espacios => 1 error
PRINT '--- F-3.6.87 plantel.jugador_modificar: Nombre solo espacios';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, '   ', 'Mod', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.88 plantel.jugador_modificar: Apellido nulo => 1 error
PRINT '--- F-3.6.88 plantel.jugador_modificar: Apellido nulo';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', NULL, '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.89 plantel.jugador_modificar: Apellido vacio => 1 error
PRINT '--- F-3.6.89 plantel.jugador_modificar: Apellido vacio';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', '', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.90 plantel.jugador_modificar: Apellido solo espacios => 1 error
PRINT '--- F-3.6.90 plantel.jugador_modificar: Apellido solo espacios';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', '   ', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.91 plantel.jugador_modificar: Fecha de nacimiento nula => 1 error
PRINT '--- F-3.6.91 plantel.jugador_modificar: Fecha de nacimiento nula';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', NULL, 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.92 plantel.jugador_modificar: Menor de 15 anios (borde: un dia menos) => 1 error
PRINT '--- F-3.6.92 plantel.jugador_modificar: Menor de 15 anios (borde: un dia menos)';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo')),
        @f15_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', @f15_menos, 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.93 plantel.jugador_modificar: Mayor de 50 anios (borde: un dia mas) => 1 error
PRINT '--- F-3.6.93 plantel.jugador_modificar: Mayor de 50 anios (borde: un dia mas)';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo')),
        @f50_mas DATE = DATEADD(DAY, -1, DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', @f50_mas, 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.94 plantel.jugador_modificar: Fecha futura => 1 error
PRINT '--- F-3.6.94 plantel.jugador_modificar: Fecha futura';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '2999-01-01', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.95 plantel.jugador_modificar: Fecha muy antigua => 1 error
PRINT '--- F-3.6.95 plantel.jugador_modificar: Fecha muy antigua';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1900-01-01', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.96 plantel.jugador_modificar: Posicion nula => 1 error
PRINT '--- F-3.6.96 plantel.jugador_modificar: Posicion nula';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.97 plantel.jugador_modificar: Posicion vacia => 1 error
PRINT '--- F-3.6.97 plantel.jugador_modificar: Posicion vacia';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', '', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.98 plantel.jugador_modificar: Posicion invalida => 1 error
PRINT '--- F-3.6.98 plantel.jugador_modificar: Posicion invalida';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'portero', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.99 plantel.jugador_modificar: Duplicado: coincide con otro jugador (nombre, apellido y fecha) => 1 error
PRINT '--- F-3.6.99 plantel.jugador_modificar: Duplicado: coincide con otro jugador (nombre, apellido y fecha)';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Otro', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.100 plantel.jugador_modificar: Duplicado con espacios al final => 1 error
PRINT '--- F-3.6.100 plantel.jugador_modificar: Duplicado con espacios al final';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU  ', 'Otro  ', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.101 plantel.jugador_modificar: Espacios al inicio: antes no se detectaba, ahora si => 1 error
PRINT '--- F-3.6.101 plantel.jugador_modificar: Espacios al inicio: antes no se detectaba, ahora si';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
BEGIN TRY EXEC plantel.jugador_modificar @m, '  Test JU', '  Otro', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.102 plantel.jugador_modificar: jugador inexistente y duplicado => 2 errores
PRINT '--- F-3.6.102 plantel.jugador_modificar: 2 errores: jugador inexistente y duplicado';
BEGIN TRY EXEC plantel.jugador_modificar 999999, 'Test JU', 'Otro', '1995-03-15', 'defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.103 plantel.jugador_modificar: jugador inexistente, posicion y duplicado => 3 errores
PRINT '--- F-3.6.103 plantel.jugador_modificar: 3 errores: jugador inexistente, posicion y duplicado';
BEGIN TRY EXEC plantel.jugador_modificar 999999, 'Test JU', 'Otro', '1995-03-15', 'portero', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.104 plantel.jugador_modificar: id obligatorio, nombre, apellido, fecha y posicion => 5 errores
PRINT '--- F-3.6.104 plantel.jugador_modificar: 5 errores: id obligatorio, nombre, apellido, fecha y posicion';
BEGIN TRY EXEC plantel.jugador_modificar NULL, NULL, NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.jugador_eliminar: F-3.6.105 a F-3.6.110
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.6.105 plantel.jugador_eliminar: Jugador inexistente (ya dado de baja) => 1 error (antes, la baja válida, que se deshace al final)
PRINT '--- F-3.6.105 plantel.jugador_eliminar: Jugador inexistente (ya dado de baja)';
DECLARE @e INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Elim');
BEGIN TRAN;
BEGIN TRY
    EXEC plantel.jugador_eliminar @e;
    EXEC plantel.jugador_eliminar @e;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.6.106 plantel.jugador_eliminar: Jugador inexistente => 1 error
PRINT '--- F-3.6.106 plantel.jugador_eliminar: Jugador inexistente';
BEGIN TRY EXEC plantel.jugador_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.107 plantel.jugador_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.6.107 plantel.jugador_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC plantel.jugador_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.108 plantel.jugador_eliminar: Tiene convocatorias registradas => 1 error
PRINT '--- F-3.6.108 plantel.jugador_eliminar: Tiene convocatorias registradas';
DECLARE @conv INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Otro');
BEGIN TRY EXEC plantel.jugador_eliminar @conv; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.109 plantel.jugador_eliminar: convocatorias y formaciones (todo jugador de una formacion esta convocado) => 2 errores
PRINT '--- F-3.6.109 plantel.jugador_eliminar: 2 errores: convocatorias y formaciones (todo jugador de una formacion esta convocado)';
DECLARE @form INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Convocado');
BEGIN TRY EXEC plantel.jugador_eliminar @form; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.6.110 plantel.jugador_eliminar: convocatorias, formaciones y tarjetas (un jugador con tarjeta integra una formacion) => 3 errores
PRINT '--- F-3.6.110 plantel.jugador_eliminar: 3 errores: convocatorias, formaciones y tarjetas (un jugador con tarjeta integra una formacion)';
DECLARE @tar INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Tarjeta');
BEGIN TRY EXEC plantel.jugador_eliminar @tar; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.7 plantel.convocatoria
-- ============================================================

-- -------------------------------------------------------------------------------------
-- plantel.convocatoria_insertar: F-3.7.01 a F-3.7.14
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.7.01 plantel.convocatoria_insertar: Seleccion inexistente => 1 error
PRINT '--- F-3.7.01 plantel.convocatoria_insertar: Seleccion inexistente';
DECLARE @id INT,
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err');
BEGIN TRY EXEC plantel.convocatoria_insertar 999999, @jl, 60, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.02 plantel.convocatoria_insertar: Seleccion nula => 1 error
PRINT '--- F-3.7.02 plantel.convocatoria_insertar: Seleccion nula';
DECLARE @id INT,
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err');
BEGIN TRY EXEC plantel.convocatoria_insertar NULL, @jl, 60, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.03 plantel.convocatoria_insertar: Jugador inexistente => 1 error
PRINT '--- F-3.7.03 plantel.convocatoria_insertar: Jugador inexistente';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC');
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, 999999, 60, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.04 plantel.convocatoria_insertar: Jugador nulo => 1 error
PRINT '--- F-3.7.04 plantel.convocatoria_insertar: Jugador nulo';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC');
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, NULL, 60, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.05 plantel.convocatoria_insertar: Dorsal nulo => 1 error
PRINT '--- F-3.7.05 plantel.convocatoria_insertar: Dorsal nulo';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err');
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @jl, NULL, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.06 plantel.convocatoria_insertar: Dorsal 0 (borde) => 1 error
PRINT '--- F-3.7.06 plantel.convocatoria_insertar: Dorsal 0 (borde)';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err');
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @jl, 0, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.07 plantel.convocatoria_insertar: Dorsal negativo => 1 error
PRINT '--- F-3.7.07 plantel.convocatoria_insertar: Dorsal negativo';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err');
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @jl, -1, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.08 plantel.convocatoria_insertar: Dorsal 100 (borde) => 1 error
PRINT '--- F-3.7.08 plantel.convocatoria_insertar: Dorsal 100 (borde)';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err');
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @jl, 100, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.09 plantel.convocatoria_insertar: Fecha de alta nula => 1 error
PRINT '--- F-3.7.09 plantel.convocatoria_insertar: Fecha de alta nula';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err');
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @jl, 60, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.10 plantel.convocatoria_insertar: Dorsal en uso por una convocatoria vigente de la seleccion => 1 error
PRINT '--- F-3.7.10 plantel.convocatoria_insertar: Dorsal en uso por una convocatoria vigente de la seleccion';
DECLARE @id INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err');
BEGIN TRY EXEC plantel.convocatoria_insertar @s1, @jl, 8, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.11 plantel.convocatoria_insertar: El jugador ya integra la convocatoria vigente de la seleccion => 1 error
PRINT '--- F-3.7.11 plantel.convocatoria_insertar: El jugador ya integra la convocatoria vigente de la seleccion';
DECLARE @id INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @jm  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Mod');
BEGIN TRY EXEC plantel.convocatoria_insertar @s1, @jm, 20, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.12 plantel.convocatoria_insertar: El jugador esta convocado por otra seleccion => 1 error
PRINT '--- F-3.7.12 plantel.convocatoria_insertar: El jugador esta convocado por otra seleccion';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @jm  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Mod');
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @jm, 20, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.13 plantel.convocatoria_insertar: dorsal en uso y jugador ya integra la convocatoria => 2 errores
PRINT '--- F-3.7.13 plantel.convocatoria_insertar: 2 errores: dorsal en uso y jugador ya integra la convocatoria';
DECLARE @id INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @jm  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Mod');
BEGIN TRY EXEC plantel.convocatoria_insertar @s1, @jm, 7, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.14 plantel.convocatoria_insertar: seleccion, jugador, dorsal y fecha de alta (todo nulo) => 4 errores
PRINT '--- F-3.7.14 plantel.convocatoria_insertar: 4 errores: seleccion, jugador, dorsal y fecha de alta (todo nulo)';
DECLARE @id INT;
BEGIN TRY EXEC plantel.convocatoria_insertar NULL, NULL, NULL, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.convocatoria_modificar: F-3.7.15 a F-3.7.31
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.7.15 plantel.convocatoria_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.7.15 plantel.convocatoria_modificar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC plantel.convocatoria_modificar NULL, 7, '2026-06-01'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.16 plantel.convocatoria_modificar: Convocatoria inexistente => 1 error
PRINT '--- F-3.7.16 plantel.convocatoria_modificar: Convocatoria inexistente';
BEGIN TRY EXEC plantel.convocatoria_modificar 999999, 7, '2026-06-01'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.17 plantel.convocatoria_modificar: Dorsal nulo => 1 error
PRINT '--- F-3.7.17 plantel.convocatoria_modificar: Dorsal nulo';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, NULL, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.18 plantel.convocatoria_modificar: Dorsal 0 (borde) => 1 error
PRINT '--- F-3.7.18 plantel.convocatoria_modificar: Dorsal 0 (borde)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 0, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.19 plantel.convocatoria_modificar: Dorsal negativo => 1 error
PRINT '--- F-3.7.19 plantel.convocatoria_modificar: Dorsal negativo';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, -1, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.20 plantel.convocatoria_modificar: Dorsal 100 (borde) => 1 error
PRINT '--- F-3.7.20 plantel.convocatoria_modificar: Dorsal 100 (borde)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 100, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.21 plantel.convocatoria_modificar: Fecha de alta nula => 1 error
PRINT '--- F-3.7.21 plantel.convocatoria_modificar: Fecha de alta nula';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.22 plantel.convocatoria_modificar: Baja anterior al alta (borde: un dia antes) => 1 error
PRINT '--- F-3.7.22 plantel.convocatoria_modificar: Baja anterior al alta (borde: un dia antes)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, '2026-05-31', 'Lesion'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.23 plantel.convocatoria_modificar: Motivo de baja sin fecha de baja => 1 error
PRINT '--- F-3.7.23 plantel.convocatoria_modificar: Motivo de baja sin fecha de baja';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, NULL, 'Lesion'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.24 plantel.convocatoria_modificar: Motivo de baja vacio sin fecha de baja (vacio no es NULL) => 1 error
PRINT '--- F-3.7.24 plantel.convocatoria_modificar: Motivo de baja vacio sin fecha de baja (vacio no es NULL)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, NULL, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.25 plantel.convocatoria_modificar: Baja sin motivo (nulo) => 1 error
PRINT '--- F-3.7.25 plantel.convocatoria_modificar: Baja sin motivo (nulo)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, '2026-06-10', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.26 plantel.convocatoria_modificar: Baja con motivo vacio => 1 error
PRINT '--- F-3.7.26 plantel.convocatoria_modificar: Baja con motivo vacio';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, '2026-06-10', ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.27 plantel.convocatoria_modificar: Baja con motivo solo espacios => 1 error
PRINT '--- F-3.7.27 plantel.convocatoria_modificar: Baja con motivo solo espacios';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, '2026-06-10', '   '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.28 plantel.convocatoria_modificar: Dorsal en uso: lo tiene otra convocatoria vigente de la seleccion => 1 error
PRINT '--- F-3.7.28 plantel.convocatoria_modificar: Dorsal en uso: lo tiene otra convocatoria vigente de la seleccion';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 8, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.29 plantel.convocatoria_modificar: Reactivar una baja con un dorsal que usa otra vigente => 1 error
PRINT '--- F-3.7.29 plantel.convocatoria_modificar: Reactivar una baja con un dorsal que usa otra vigente';
DECLARE @cb INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cb  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja'     AND c.seleccion_id = @s1 AND c.fecha_baja IS NOT NULL);
BEGIN TRY EXEC plantel.convocatoria_modificar @cb, 8, '2026-05-01', NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.30 plantel.convocatoria_modificar: motivo sin fecha de baja y dorsal en uso => 2 errores
PRINT '--- F-3.7.30 plantel.convocatoria_modificar: 2 errores: motivo sin fecha de baja y dorsal en uso';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 8, '2026-06-01', NULL, NULL, 'Lesion'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.31 plantel.convocatoria_modificar: dorsal, baja anterior al alta y baja sin motivo => 3 errores
PRINT '--- F-3.7.31 plantel.convocatoria_modificar: 3 errores: dorsal, baja anterior al alta y baja sin motivo';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 0, '2026-06-01', NULL, '2026-05-01', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.convocatoria_eliminar: F-3.7.32 a F-3.7.33
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.7.32 plantel.convocatoria_eliminar: Convocatoria inexistente => 1 error
PRINT '--- F-3.7.32 plantel.convocatoria_eliminar: Convocatoria inexistente';
BEGIN TRY EXEC plantel.convocatoria_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.7.33 plantel.convocatoria_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.7.33 plantel.convocatoria_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC plantel.convocatoria_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================

-- -------------------------------------------------------------------------------------
-- plantel.formacion_insertar: F-3.8.01 a F-3.8.26
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.8.01 plantel.formacion_insertar: Duplicado: el visitante de @pc ya tiene formacion => 1 error (antes, el alta válida del visitante de @pc, que se deshace al final)
PRINT '--- F-3.8.01 plantel.formacion_insertar: Duplicado: el visitante de @pc ya tiene formacion';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRAN;
BEGIN TRY
    EXEC plantel.formacion_insertar @pc, 'visitante', '1-1-8', @id OUTPUT;
    EXEC plantel.formacion_insertar @pc, 'visitante', '4-3-3', @formacion_id = @id OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.8.02 plantel.formacion_insertar: Partido inexistente => 1 error
PRINT '--- F-3.8.02 plantel.formacion_insertar: Partido inexistente';
DECLARE @id INT;
BEGIN TRY EXEC plantel.formacion_insertar 999999, 'local', '4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.03 plantel.formacion_insertar: Partido nulo => 1 error
PRINT '--- F-3.8.03 plantel.formacion_insertar: Partido nulo';
DECLARE @id INT;
BEGIN TRY EXEC plantel.formacion_insertar NULL, 'local', '4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.04 plantel.formacion_insertar: Partido finalizado => 1 error
PRINT '--- F-3.8.04 plantel.formacion_insertar: Partido finalizado';
DECLARE @id INT,
        @pf INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'fin');
BEGIN TRY EXEC plantel.formacion_insertar @pf, 'visitante', '4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.05 plantel.formacion_insertar: Condicion nula => 1 error
PRINT '--- F-3.8.05 plantel.formacion_insertar: Condicion nula';
DECLARE @id INT,
        @pa INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_a');
BEGIN TRY EXEC plantel.formacion_insertar @pa, NULL, '4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.06 plantel.formacion_insertar: Condicion vacia => 1 error
PRINT '--- F-3.8.06 plantel.formacion_insertar: Condicion vacia';
DECLARE @id INT,
        @pa INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_a');
BEGIN TRY EXEC plantel.formacion_insertar @pa, '', '4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.07 plantel.formacion_insertar: Condicion invalida => 1 error
PRINT '--- F-3.8.07 plantel.formacion_insertar: Condicion invalida';
DECLARE @id INT,
        @pa INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_a');
BEGIN TRY EXEC plantel.formacion_insertar @pa, 'otro', '4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.08 plantel.formacion_insertar: El equipo local ya tiene formacion cargada => 1 error
PRINT '--- F-3.8.08 plantel.formacion_insertar: El equipo local ya tiene formacion cargada';
DECLARE @id INT,
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_insertar @pm, 'local', '4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.09 plantel.formacion_insertar: El equipo visitante ya tiene formacion cargada => 1 error
PRINT '--- F-3.8.09 plantel.formacion_insertar: El equipo visitante ya tiene formacion cargada';
DECLARE @id INT,
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_insertar @pm, 'visitante', '4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.10 plantel.formacion_insertar: Esquema nulo => 1 error
PRINT '--- F-3.8.10 plantel.formacion_insertar: Esquema nulo';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.11 plantel.formacion_insertar: Esquema vacio => 1 error
PRINT '--- F-3.8.11 plantel.formacion_insertar: Esquema vacio';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.12 plantel.formacion_insertar: Esquema sin guiones (1 linea) => 1 error
PRINT '--- F-3.8.12 plantel.formacion_insertar: Esquema sin guiones (1 linea)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '433', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.13 plantel.formacion_insertar: Esquema con 2 lineas (borde: una menos que el minimo) => 1 error
PRINT '--- F-3.8.13 plantel.formacion_insertar: Esquema con 2 lineas (borde: una menos que el minimo)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '5-5', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.14 plantel.formacion_insertar: Esquema con 6 lineas y mas de 9 caracteres => 1 error
PRINT '--- F-3.8.14 plantel.formacion_insertar: Esquema con 6 lineas y mas de 9 caracteres';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '1-1-1-1-1-5', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.15 plantel.formacion_insertar: Suma 9 (borde: uno menos) => 1 error
PRINT '--- F-3.8.15 plantel.formacion_insertar: Suma 9 (borde: uno menos)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '4-3-2', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.16 plantel.formacion_insertar: Suma 11 (borde: uno mas) => 1 error
PRINT '--- F-3.8.16 plantel.formacion_insertar: Suma 11 (borde: uno mas)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '4-4-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.17 plantel.formacion_insertar: Linea con 0 jugadores => 1 error
PRINT '--- F-3.8.17 plantel.formacion_insertar: Linea con 0 jugadores';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '4-0-6', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.18 plantel.formacion_insertar: Linea de 2 digitos => 1 error
PRINT '--- F-3.8.18 plantel.formacion_insertar: Linea de 2 digitos';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '10-0-0', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.19 plantel.formacion_insertar: Guion final (linea vacia) => 1 error
PRINT '--- F-3.8.19 plantel.formacion_insertar: Guion final (linea vacia)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '4-3-3-', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.20 plantel.formacion_insertar: Guion inicial (linea vacia) => 1 error
PRINT '--- F-3.8.20 plantel.formacion_insertar: Guion inicial (linea vacia)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '-4-3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.21 plantel.formacion_insertar: Guiones consecutivos (linea vacia) => 1 error
PRINT '--- F-3.8.21 plantel.formacion_insertar: Guiones consecutivos (linea vacia)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '4--3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.22 plantel.formacion_insertar: Linea no numerica => 1 error
PRINT '--- F-3.8.22 plantel.formacion_insertar: Linea no numerica';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '4-a-6', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.23 plantel.formacion_insertar: Esquema con espacios => 1 error
PRINT '--- F-3.8.23 plantel.formacion_insertar: Esquema con espacios';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '4 -3-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.24 plantel.formacion_insertar: 4 lineas pero una en 0 => 1 error
PRINT '--- F-3.8.24 plantel.formacion_insertar: 4 lineas pero una en 0';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '4-3-3-0', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.25 plantel.formacion_insertar: partido inexistente, condicion y esquema => 3 errores
PRINT '--- F-3.8.25 plantel.formacion_insertar: 3 errores: partido inexistente, condicion y esquema';
DECLARE @id INT;
BEGIN TRY EXEC plantel.formacion_insertar 999999, 'otro', '433', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.26 plantel.formacion_insertar: partido finalizado, formacion duplicada y esquema => 3 errores
PRINT '--- F-3.8.26 plantel.formacion_insertar: 3 errores: partido finalizado, formacion duplicada y esquema';
DECLARE @id INT,
        @pf INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'fin');
BEGIN TRY EXEC plantel.formacion_insertar @pf, 'local', '4-4-3', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.formacion_modificar: F-3.8.27 a F-3.8.45
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.8.27 plantel.formacion_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.8.27 plantel.formacion_modificar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC plantel.formacion_modificar NULL, '4-3-3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.28 plantel.formacion_modificar: Formacion inexistente => 1 error
PRINT '--- F-3.8.28 plantel.formacion_modificar: Formacion inexistente';
BEGIN TRY EXEC plantel.formacion_modificar 999999, '4-3-3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.29 plantel.formacion_modificar: Partido finalizado => 1 error
PRINT '--- F-3.8.29 plantel.formacion_modificar: Partido finalizado';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fin');
BEGIN TRY EXEC plantel.formacion_modificar @ff, '4-3-3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.30 plantel.formacion_modificar: Esquema nulo => 1 error
PRINT '--- F-3.8.30 plantel.formacion_modificar: Esquema nulo';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.31 plantel.formacion_modificar: Esquema vacio => 1 error
PRINT '--- F-3.8.31 plantel.formacion_modificar: Esquema vacio';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.32 plantel.formacion_modificar: Esquema sin guiones (1 linea) => 1 error
PRINT '--- F-3.8.32 plantel.formacion_modificar: Esquema sin guiones (1 linea)';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '433'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.33 plantel.formacion_modificar: Esquema con 2 lineas (borde: una menos que el minimo) => 1 error
PRINT '--- F-3.8.33 plantel.formacion_modificar: Esquema con 2 lineas (borde: una menos que el minimo)';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '5-5'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.34 plantel.formacion_modificar: Esquema con 6 lineas y mas de 9 caracteres => 1 error
PRINT '--- F-3.8.34 plantel.formacion_modificar: Esquema con 6 lineas y mas de 9 caracteres';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '1-1-1-1-1-5'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.35 plantel.formacion_modificar: Suma 9 (borde: uno menos) => 1 error
PRINT '--- F-3.8.35 plantel.formacion_modificar: Suma 9 (borde: uno menos)';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '4-3-2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.36 plantel.formacion_modificar: Suma 11 (borde: uno mas) => 1 error
PRINT '--- F-3.8.36 plantel.formacion_modificar: Suma 11 (borde: uno mas)';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '4-4-3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.37 plantel.formacion_modificar: Linea con 0 jugadores => 1 error
PRINT '--- F-3.8.37 plantel.formacion_modificar: Linea con 0 jugadores';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '4-0-6'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.38 plantel.formacion_modificar: Linea de 2 digitos => 1 error
PRINT '--- F-3.8.38 plantel.formacion_modificar: Linea de 2 digitos';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '10-0-0'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.39 plantel.formacion_modificar: Guion final (linea vacia) => 1 error
PRINT '--- F-3.8.39 plantel.formacion_modificar: Guion final (linea vacia)';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '4-3-3-'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.40 plantel.formacion_modificar: Linea no numerica => 1 error
PRINT '--- F-3.8.40 plantel.formacion_modificar: Linea no numerica';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '4-a-6'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.41 plantel.formacion_modificar: Esquema con espacios => 1 error
PRINT '--- F-3.8.41 plantel.formacion_modificar: Esquema con espacios';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
BEGIN TRY EXEC plantel.formacion_modificar @fm, '4 -3-3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.42 plantel.formacion_modificar: formacion inexistente y esquema nulo => 2 errores
PRINT '--- F-3.8.42 plantel.formacion_modificar: 2 errores: formacion inexistente y esquema nulo';
BEGIN TRY EXEC plantel.formacion_modificar 999999, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.43 plantel.formacion_modificar: id nulo y esquema invalido => 2 errores
PRINT '--- F-3.8.43 plantel.formacion_modificar: 2 errores: id nulo y esquema invalido';
BEGIN TRY EXEC plantel.formacion_modificar NULL, '433'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.44 plantel.formacion_modificar: partido finalizado y esquema invalido => 2 errores
PRINT '--- F-3.8.44 plantel.formacion_modificar: 2 errores: partido finalizado y esquema invalido';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fin');
BEGIN TRY EXEC plantel.formacion_modificar @ff, '4-4-3'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.45 plantel.formacion_modificar: partido finalizado y esquema nulo => 2 errores
PRINT '--- F-3.8.45 plantel.formacion_modificar: 2 errores: partido finalizado y esquema nulo';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fin');
BEGIN TRY EXEC plantel.formacion_modificar @ff, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.formacion_eliminar: F-3.8.46 a F-3.8.48
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.8.46 plantel.formacion_eliminar: Formacion inexistente => 1 error
PRINT '--- F-3.8.46 plantel.formacion_eliminar: Formacion inexistente';
BEGIN TRY EXEC plantel.formacion_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.47 plantel.formacion_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.8.47 plantel.formacion_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC plantel.formacion_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.48 plantel.formacion_eliminar: Partido finalizado => 1 error
PRINT '--- F-3.8.48 plantel.formacion_eliminar: Partido finalizado';
DECLARE @ff  INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fin');
BEGIN TRY EXEC plantel.formacion_eliminar @ff; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.formacion_jugador_insertar: F-3.8.49 a F-3.8.70
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.8.49 plantel.formacion_jugador_insertar: Formacion inexistente => 1 error
PRINT '--- F-3.8.49 plantel.formacion_jugador_insertar: Formacion inexistente';
DECLARE @ins  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'ins');
BEGIN TRY EXEC plantel.formacion_jugador_insertar 999999, @ins, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.50 plantel.formacion_jugador_insertar: Formacion nula => 1 error
PRINT '--- F-3.8.50 plantel.formacion_jugador_insertar: Formacion nula';
DECLARE @ins  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'ins');
BEGIN TRY EXEC plantel.formacion_jugador_insertar NULL, @ins, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.51 plantel.formacion_jugador_insertar: Partido finalizado => 1 error
PRINT '--- F-3.8.51 plantel.formacion_jugador_insertar: Partido finalizado';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fj_fin'),
        @ins  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'ins');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @ff, @ins, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.52 plantel.formacion_jugador_insertar: Jugador inexistente => 1 error
PRINT '--- F-3.8.52 plantel.formacion_jugador_insertar: Jugador inexistente';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, 999999, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.53 plantel.formacion_jugador_insertar: Jugador nulo => 1 error
PRINT '--- F-3.8.53 plantel.formacion_jugador_insertar: Jugador nulo';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, NULL, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.54 plantel.formacion_jugador_insertar: El jugador ya integra esa formacion => 1 error
PRINT '--- F-3.8.54 plantel.formacion_jugador_insertar: El jugador ya integra esa formacion';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, @base, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.55 plantel.formacion_jugador_insertar: Posicion nula => 1 error
PRINT '--- F-3.8.55 plantel.formacion_jugador_insertar: Posicion nula';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @l3   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_3');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @l3, NULL, 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.56 plantel.formacion_jugador_insertar: Posicion vacia => 1 error
PRINT '--- F-3.8.56 plantel.formacion_jugador_insertar: Posicion vacia';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @l3   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_3');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @l3, '', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.57 plantel.formacion_jugador_insertar: Posicion solo espacios => 1 error
PRINT '--- F-3.8.57 plantel.formacion_jugador_insertar: Posicion solo espacios';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @l3   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_3');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @l3, '   ', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.58 plantel.formacion_jugador_insertar: Titular nulo => 1 error
PRINT '--- F-3.8.58 plantel.formacion_jugador_insertar: Titular nulo';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @l3   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_3');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @l3, 'Defensor', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.59 plantel.formacion_jugador_insertar: Jugador sin convocatoria => 1 error
PRINT '--- F-3.8.59 plantel.formacion_jugador_insertar: Jugador sin convocatoria';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @sc   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sin_conv');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, @sc, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.60 plantel.formacion_jugador_insertar: Jugador convocado solo por otra seleccion (ZCB) => 1 error
PRINT '--- F-3.8.60 plantel.formacion_jugador_insertar: Jugador convocado solo por otra seleccion (ZCB)';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @t1   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'tit_1');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, @t1, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.61 plantel.formacion_jugador_insertar: Convocatoria historica: baja anterior al partido => 1 error
PRINT '--- F-3.8.61 plantel.formacion_jugador_insertar: Convocatoria historica: baja anterior al partido';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @hist INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'hist');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @hist, 'Defensor', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.62 plantel.formacion_jugador_insertar: Convocatoria con alta un dia despues del partido (borde) => 1 error
PRINT '--- F-3.8.62 plantel.formacion_jugador_insertar: Convocatoria con alta un dia despues del partido (borde)';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @fut  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'futuro');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @fut, 'Defensor', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.63 plantel.formacion_jugador_insertar: Dorsal 40 ya usado en la formacion (lo conserva q1 aunque su convocatoria ahora tiene el 50) => 1 error
PRINT '--- F-3.8.63 plantel.formacion_jugador_insertar: Dorsal 40 ya usado en la formacion (lo conserva q1 aunque su convocatoria ahora tiene el 50)';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @p    INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'p');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, @p, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.64 plantel.formacion_jugador_insertar: La formacion ya tiene el maximo de titulares (borde) => 1 error
PRINT '--- F-3.8.64 plantel.formacion_jugador_insertar: La formacion ya tiene el maximo de titulares (borde)';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @tx   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'tit_extra');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @tx, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.65 plantel.formacion_jugador_insertar: El banco ya tiene el maximo de suplentes (borde) => 1 error
PRINT '--- F-3.8.65 plantel.formacion_jugador_insertar: El banco ya tiene el maximo de suplentes (borde)';
DECLARE @fs INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_sup'),
        @sx   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sup_extra');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fs, @sx, 'Delantero', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.66 plantel.formacion_jugador_insertar: Jugador suspendido para ese partido (ARG Jugador 05 en P3, del escenario) => 1 error (antes, se ubica la formación de Argentina en P3 y a su jugador 05, suspendido por acumulación (2.8), que se deshace al final)
PRINT '--- F-3.8.66 plantel.formacion_jugador_insertar: Jugador suspendido para ese partido (ARG Jugador 05 en P3, del escenario)';
BEGIN TRAN;
BEGIN TRY
    DECLARE @j05 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 05'),
            @f_p3 INT = (SELECT f.formacion_id FROM plantel.formacion f JOIN torneo.partido p ON p.partido_id = f.partido_id
                         JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id JOIN torneo.pais pl ON pl.pais_id = sl.pais_id
                         JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id JOIN torneo.pais pv ON pv.pais_id = sv.pais_id
                         WHERE pl.codigo_iso = 'ARG' AND pv.codigo_iso = 'JPN' AND f.condicion = 'local');
    EXEC plantel.formacion_jugador_insertar @f_p3, @j05, 'Defensor', 0;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.8.67 plantel.formacion_jugador_insertar: formacion, jugador, posicion y titular (todo nulo) => 4 errores
PRINT '--- F-3.8.67 plantel.formacion_jugador_insertar: 4 errores: formacion, jugador, posicion y titular (todo nulo)';
BEGIN TRY EXEC plantel.formacion_jugador_insertar NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.68 plantel.formacion_jugador_insertar: partido finalizado, posicion vacia y sin convocatoria => 3 errores
PRINT '--- F-3.8.68 plantel.formacion_jugador_insertar: 3 errores: partido finalizado, posicion vacia y sin convocatoria';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fj_fin'),
        @sc   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sin_conv');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @ff, @sc, '', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.69 plantel.formacion_jugador_insertar: ya integra, posicion y titular => 3 errores
PRINT '--- F-3.8.69 plantel.formacion_jugador_insertar: 3 errores: ya integra, posicion y titular';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, @base, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.70 plantel.formacion_jugador_insertar: posicion vacia y dorsal en uso => 2 errores
PRINT '--- F-3.8.70 plantel.formacion_jugador_insertar: 2 errores: posicion vacia y dorsal en uso';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @p    INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'p');
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, @p, '', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.formacion_jugador_modificar: F-3.8.71 a F-3.8.84
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.8.71 plantel.formacion_jugador_modificar: Formacion nula => 1 error
PRINT '--- F-3.8.71 plantel.formacion_jugador_modificar: Formacion nula';
DECLARE @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_modificar NULL, @base, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.72 plantel.formacion_jugador_modificar: Formacion inexistente => 1 error
PRINT '--- F-3.8.72 plantel.formacion_jugador_modificar: Formacion inexistente';
DECLARE @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_modificar 999999, @base, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.73 plantel.formacion_jugador_modificar: Partido finalizado => 1 error
PRINT '--- F-3.8.73 plantel.formacion_jugador_modificar: Partido finalizado';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fj_fin'),
        @fin  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'fin');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @ff, @fin, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.74 plantel.formacion_jugador_modificar: jugador inexistente y no integra la formacion => 2 errores
PRINT '--- F-3.8.74 plantel.formacion_jugador_modificar: 2 errores: jugador inexistente y no integra la formacion';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, 999999, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.75 plantel.formacion_jugador_modificar: jugador nulo y no integra la formacion => 2 errores
PRINT '--- F-3.8.75 plantel.formacion_jugador_modificar: 2 errores: jugador nulo y no integra la formacion';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, NULL, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.76 plantel.formacion_jugador_modificar: El jugador no integra esa formacion => 1 error
PRINT '--- F-3.8.76 plantel.formacion_jugador_modificar: El jugador no integra esa formacion';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @l3   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_3');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fl, @l3, 'Defensor', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.77 plantel.formacion_jugador_modificar: Posicion nula => 1 error
PRINT '--- F-3.8.77 plantel.formacion_jugador_modificar: Posicion nula';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, NULL, 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.78 plantel.formacion_jugador_modificar: Posicion vacia => 1 error
PRINT '--- F-3.8.78 plantel.formacion_jugador_modificar: Posicion vacia';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, '', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.79 plantel.formacion_jugador_modificar: Posicion solo espacios => 1 error
PRINT '--- F-3.8.79 plantel.formacion_jugador_modificar: Posicion solo espacios';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, '   ', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.80 plantel.formacion_jugador_modificar: Titular nulo => 1 error
PRINT '--- F-3.8.80 plantel.formacion_jugador_modificar: Titular nulo';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.81 plantel.formacion_jugador_modificar: Su convocatoria ya no esta vigente a la fecha del partido (tiene baja) => 1 error
PRINT '--- F-3.8.81 plantel.formacion_jugador_modificar: Su convocatoria ya no esta vigente a la fecha del partido (tiene baja)';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @zb   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'z_baja');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @zb, 'Defensor', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.82 plantel.formacion_jugador_modificar: formacion, jugador, posicion y titular (todo nulo) => 4 errores
PRINT '--- F-3.8.82 plantel.formacion_jugador_modificar: 4 errores: formacion, jugador, posicion y titular (todo nulo)';
BEGIN TRY EXEC plantel.formacion_jugador_modificar NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.83 plantel.formacion_jugador_modificar: partido finalizado, no integra la formacion y sin convocatoria vigente => 3 errores
PRINT '--- F-3.8.83 plantel.formacion_jugador_modificar: 3 errores: partido finalizado, no integra la formacion y sin convocatoria vigente';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fj_fin'),
        @sc   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sin_conv');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @ff, @sc, 'Delantero', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.84 plantel.formacion_jugador_modificar: posicion, titular y dorsal en uso => 3 errores
PRINT '--- F-3.8.84 plantel.formacion_jugador_modificar: 3 errores: posicion, titular y dorsal en uso';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @r    INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'r');
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @r, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- plantel.formacion_jugador_eliminar: F-3.8.85 a F-3.8.96
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.8.85 plantel.formacion_jugador_eliminar: El jugador no integra esa formacion => 1 error
PRINT '--- F-3.8.85 plantel.formacion_jugador_eliminar: El jugador no integra esa formacion';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @l3   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_3');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @fl, @l3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.86 plantel.formacion_jugador_eliminar: Formacion inexistente => 1 error
PRINT '--- F-3.8.86 plantel.formacion_jugador_eliminar: Formacion inexistente';
DECLARE @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar 999999, @base; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.87 plantel.formacion_jugador_eliminar: Formacion nula (idem) => 1 error
PRINT '--- F-3.8.87 plantel.formacion_jugador_eliminar: Formacion nula (idem)';
DECLARE @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar NULL, @base; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.88 plantel.formacion_jugador_eliminar: Jugador inexistente => 1 error
PRINT '--- F-3.8.88 plantel.formacion_jugador_eliminar: Jugador inexistente';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @fj, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.89 plantel.formacion_jugador_eliminar: Jugador nulo (idem) => 1 error
PRINT '--- F-3.8.89 plantel.formacion_jugador_eliminar: Jugador nulo (idem)';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @fj, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.90 plantel.formacion_jugador_eliminar: Partido finalizado => 1 error
PRINT '--- F-3.8.90 plantel.formacion_jugador_eliminar: Partido finalizado';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fj_fin'),
        @fin  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'fin');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @ff, @fin; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.91 plantel.formacion_jugador_eliminar: no integra la formacion y partido finalizado => 2 errores
PRINT '--- F-3.8.91 plantel.formacion_jugador_eliminar: 2 errores: no integra la formacion y partido finalizado';
DECLARE @ff INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fj_fin'),
        @sc   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sin_conv');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @ff, @sc; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.92 plantel.formacion_jugador_eliminar: Participa de sustituciones, como el que sale => 1 error (antes, un cambio en la formación jug, que se deshace al final)
PRINT '--- F-3.8.92 plantel.formacion_jugador_eliminar: Participa de sustituciones, como el que sale';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @ssale INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sust_sale'),
        @sent  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sust_entra');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.sustitucion_insertar @fj, @ssale, @sent, 60, 'ST', 1, 'tactico';
    EXEC plantel.formacion_jugador_eliminar @fj, @ssale;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.8.93 plantel.formacion_jugador_eliminar: Participa de sustituciones, como el que entra => 1 error (antes, un cambio en la formación jug, que se deshace al final)
PRINT '--- F-3.8.93 plantel.formacion_jugador_eliminar: Participa de sustituciones, como el que entra';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @ssale INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sust_sale'),
        @sent  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sust_entra');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.sustitucion_insertar @fj, @ssale, @sent, 60, 'ST', 1, 'tactico';
    EXEC plantel.formacion_jugador_eliminar @fj, @sent;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.8.94 plantel.formacion_jugador_eliminar: Tiene goles registrados => 1 error
PRINT '--- F-3.8.94 plantel.formacion_jugador_eliminar: Tiene goles registrados';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @gol   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'gol');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @fj, @gol; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.95 plantel.formacion_jugador_eliminar: Tiene asistencias registradas => 1 error
PRINT '--- F-3.8.95 plantel.formacion_jugador_eliminar: Tiene asistencias registradas';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @asis  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'asis');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @fj, @asis; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.8.96 plantel.formacion_jugador_eliminar: Tiene tarjetas registradas en el partido => 1 error
PRINT '--- F-3.8.96 plantel.formacion_jugador_eliminar: Tiene tarjetas registradas en el partido';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @tarj  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'tarj');
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @fj, @tarj; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.9 evento.sustitucion
-- ============================================================

-- -------------------------------------------------------------------------------------
-- evento.sustitucion_insertar: F-3.9.01 a F-3.9.43
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.9.01 evento.sustitucion_insertar: Minuto de ST en PT => 1 error
PRINT '--- F-3.9.01 evento.sustitucion_insertar: Minuto de ST en PT';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @otl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_tl'),
        @osl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @otl, @osl, 70, 'PT', 1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.02 evento.sustitucion_insertar: Jugador que sale nulo (no integra la formación) => 1 error
PRINT '--- F-3.9.02 evento.sustitucion_insertar: Jugador que sale nulo (no integra la formación)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @osl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fo, NULL, @osl, 30, 'PT', 1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.03 evento.sustitucion_insertar: Jugador que entra nulo (no integra la formación) => 1 error
PRINT '--- F-3.9.03 evento.sustitucion_insertar: Jugador que entra nulo (no integra la formación)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @otl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_tl');
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @otl, NULL, 30, 'PT', 1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.04 evento.sustitucion_insertar: El que sale no integra la formación (convocado pero no cargado) => 1 error
PRINT '--- F-3.9.04 evento.sustitucion_insertar: El que sale no integra la formación (convocado pero no cargado)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @fu INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'fuera'),
        @osl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @fu, @osl, 30, 'PT', 1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.05 evento.sustitucion_insertar: El que sale es suplente y todavía no ingresó (no está en cancha) => 1 error
PRINT '--- F-3.9.05 evento.sustitucion_insertar: El que sale es suplente y todavía no ingresó (no está en cancha)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1'),
        @osl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @osl, @os1, 30, 'PT', 1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.06 evento.sustitucion_insertar: El que entra es titular (no está disponible en el banco) => 1 error
PRINT '--- F-3.9.06 evento.sustitucion_insertar: El que entra es titular (no está disponible en el banco)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t1'),
        @ot2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t2');
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @ot1, @ot2, 30, 'PT', 1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.07 evento.sustitucion_insertar: El que sale ya había sido reemplazado (no está en cancha) => 1 error (antes, los cambios válidos de f_ok, como en exitosos, que se deshace al final)
PRINT '--- F-3.9.07 evento.sustitucion_insertar: El que sale ya había sido reemplazado (no está en cancha)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t1'),
        @ot2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t2'),
        @ot3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t3'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1'),
        @os2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s2'),
        @os3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s3'),
        @os4 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s4'),
        @osl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_sl');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion';
    EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion';
    EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @ot1, @osl, 80, 'ST', 2, 'tactico', @id OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.9.08 evento.sustitucion_insertar: El que sale ingresó y después fue reemplazado (no está en cancha) => 1 error (antes, los cambios válidos de f_ok, como en exitosos, que se deshace al final)
PRINT '--- F-3.9.08 evento.sustitucion_insertar: El que sale ingresó y después fue reemplazado (no está en cancha)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t1'),
        @ot2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t2'),
        @ot3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t3'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1'),
        @os2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s2'),
        @os3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s3'),
        @os4 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s4'),
        @osl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_sl');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion';
    EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion';
    EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @os1, @osl, 80, 'ST', 2, 'tactico', @id OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.9.09 evento.sustitucion_insertar: El que entra ya había ingresado (no disponible en el banco) => 1 error (antes, los cambios válidos de f_ok, como en exitosos, que se deshace al final)
PRINT '--- F-3.9.09 evento.sustitucion_insertar: El que entra ya había ingresado (no disponible en el banco)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t1'),
        @ot2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t2'),
        @ot3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t3'),
        @otl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_tl'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1'),
        @os2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s2'),
        @os3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s3'),
        @os4 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s4');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion';
    EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion';
    EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @otl, @os2, 80, 'ST', 2, 'tactico', @id OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.9.10 evento.sustitucion_insertar: El que entra es un titular que ya salió (no disponible en el banco) => 1 error (antes, los cambios válidos de f_ok, como en exitosos, que se deshace al final)
PRINT '--- F-3.9.10 evento.sustitucion_insertar: El que entra es un titular que ya salió (no disponible en el banco)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t1'),
        @ot2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t2'),
        @ot3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t3'),
        @otl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_tl'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1'),
        @os2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s2'),
        @os3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s3'),
        @os4 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s4');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion';
    EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion';
    EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @otl, @ot1, 80, 'ST', 2, 'tactico', @id OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.9.11 evento.sustitucion_insertar: Ventana 2 ya usada en otro período (ST) => 1 error (antes, los cambios válidos de f_ok, como en exitosos, que se deshace al final)
PRINT '--- F-3.9.11 evento.sustitucion_insertar: Ventana 2 ya usada en otro período (ST)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t1'),
        @ot2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t2'),
        @ot3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t3'),
        @otl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_tl'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1'),
        @os2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s2'),
        @os3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s3'),
        @os4 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s4'),
        @osl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_sl');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion';
    EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion';
    EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @otl, @osl, 30, 'PT', 2, 'tactico', @id OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.9.12 evento.sustitucion_insertar: ventana anterior a la última y ventana 1 ya usada en otro período (PT) => 2 errores (antes, los cambios válidos de f_ok, como en exitosos, que se deshace al final)
PRINT '--- F-3.9.12 evento.sustitucion_insertar: 2 errores: ventana anterior a la última y ventana 1 ya usada en otro período (PT)';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t1'),
        @ot2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t2'),
        @ot3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t3'),
        @otl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_tl'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1'),
        @os2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s2'),
        @os3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s3'),
        @os4 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s4'),
        @osl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_sl');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion';
    EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion';
    EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico';
    EXEC evento.sustitucion_insertar @fo, @otl, @osl, 50, 'ST', 1, 'tactico', @id OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.9.13 evento.sustitucion_insertar: Formación nula (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.9.13 evento.sustitucion_insertar: Formación nula (el mensaje dice "(nulo)")';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar NULL, @gtl, @gsl, 80, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.14 evento.sustitucion_insertar: Formación inexistente => 1 error
PRINT '--- F-3.9.14 evento.sustitucion_insertar: Formación inexistente';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar 999999, @gtl, @gsl, 80, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.15 evento.sustitucion_insertar: El partido ya está finalizado => 1 error
PRINT '--- F-3.9.15 evento.sustitucion_insertar: El partido ya está finalizado';
DECLARE @id INT,
        @ff INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_fin'),
        @xtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'fin_tl'),
        @xsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'fin_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @ff, @xtl, @xsl, 70, 'ST', 2, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.16 evento.sustitucion_insertar: Motivo nulo => 1 error
PRINT '--- F-3.9.16 evento.sustitucion_insertar: Motivo nulo';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.17 evento.sustitucion_insertar: Motivo inválido => 1 error
PRINT '--- F-3.9.17 evento.sustitucion_insertar: Motivo inválido';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V, 'otro', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.18 evento.sustitucion_insertar: Motivo vacio => 1 error
PRINT '--- F-3.9.18 evento.sustitucion_insertar: Motivo vacio';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V, '', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.19 evento.sustitucion_insertar: Período nulo => 1 error
PRINT '--- F-3.9.19 evento.sustitucion_insertar: Período nulo';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, NULL, @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.20 evento.sustitucion_insertar: Período inválido => 1 error
PRINT '--- F-3.9.20 evento.sustitucion_insertar: Período inválido';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'XX', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.21 evento.sustitucion_insertar: Minuto nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.9.21 evento.sustitucion_insertar: Minuto nulo (el mensaje dice "(nulo)")';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, NULL, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.22 evento.sustitucion_insertar: Minuto 44 en ST (borde) => 1 error
PRINT '--- F-3.9.22 evento.sustitucion_insertar: Minuto 44 en ST (borde)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 44,  'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.23 evento.sustitucion_insertar: Minuto 111 en ST (borde) => 1 error
PRINT '--- F-3.9.23 evento.sustitucion_insertar: Minuto 111 en ST (borde)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 111, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.24 evento.sustitucion_insertar: Minuto 89 en alargue_1 (borde) => 1 error
PRINT '--- F-3.9.24 evento.sustitucion_insertar: Minuto 89 en alargue_1 (borde)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @V1 INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
SET @V1  = @V + 1;
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 89,  'alargue_1', @V1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.25 evento.sustitucion_insertar: Minuto 116 en alargue_1 (borde) => 1 error
PRINT '--- F-3.9.25 evento.sustitucion_insertar: Minuto 116 en alargue_1 (borde)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @V1 INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
SET @V1  = @V + 1;
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 116, 'alargue_1', @V1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.26 evento.sustitucion_insertar: Minuto 104 en alargue_2 (borde) => 1 error
PRINT '--- F-3.9.26 evento.sustitucion_insertar: Minuto 104 en alargue_2 (borde)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @V1 INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
SET @V1  = @V + 1;
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 104, 'alargue_2', @V1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.27 evento.sustitucion_insertar: Minuto 136 en alargue_2 (borde) => 1 error
PRINT '--- F-3.9.27 evento.sustitucion_insertar: Minuto 136 en alargue_2 (borde)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @V1 INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
SET @V1  = @V + 1;
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 136, 'alargue_2', @V1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.28 evento.sustitucion_insertar: Ventana nula => 1 error
PRINT '--- F-3.9.28 evento.sustitucion_insertar: Ventana nula';
DECLARE @id INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', NULL, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.29 evento.sustitucion_insertar: ventana 0 y orden de ventanas (anterior a la última) => 2 errores
PRINT '--- F-3.9.29 evento.sustitucion_insertar: 2 errores: ventana 0 y orden de ventanas (anterior a la última)';
DECLARE @id INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', 0, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.30 evento.sustitucion_insertar: Se superan las ventanas reglamentarias (la siguiente a la última, pero fuera de las permitidas) => 1 error
PRINT '--- F-3.9.30 evento.sustitucion_insertar: Se superan las ventanas reglamentarias (la siguiente a la última, pero fuera de las permitidas)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @V1 INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
SET @V1  = @V + 1;
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.31 evento.sustitucion_insertar: salto de ventana y se superan las reglamentarias => 2 errores
PRINT '--- F-3.9.31 evento.sustitucion_insertar: 2 errores: salto de ventana y se superan las reglamentarias';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @V2 INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
SET @V2  = @V + 2;
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V2, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.32 evento.sustitucion_insertar: Ventana anterior a la última (el mensaje dice "corresponde la V o la V+1") => 1 error
PRINT '--- F-3.9.32 evento.sustitucion_insertar: Ventana anterior a la última (el mensaje dice "corresponde la V o la V+1")';
DECLARE @id INT,
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 30, 'PT', 1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.33 evento.sustitucion_insertar: Ventana V ya usada en otro período (ST) => 1 error
PRINT '--- F-3.9.33 evento.sustitucion_insertar: Ventana V ya usada en otro período (ST)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 30, 'PT', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.34 evento.sustitucion_insertar: El que sale ya había sido reemplazado (no está en cancha) => 1 error
PRINT '--- F-3.9.34 evento.sustitucion_insertar: El que sale ya había sido reemplazado (no está en cancha)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gt1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_t1'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gt1, @gsl, 80, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.35 evento.sustitucion_insertar: El que sale es suplente y no ingresó (no está en cancha) => 1 error
PRINT '--- F-3.9.35 evento.sustitucion_insertar: El que sale es suplente y no ingresó (no está en cancha)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl'),
        @gsl2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_sl2');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gsl, @gsl2, 80, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.36 evento.sustitucion_insertar: El que entra es titular (no está disponible en el banco) => 1 error
PRINT '--- F-3.9.36 evento.sustitucion_insertar: El que entra es titular (no está disponible en el banco)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl'),
        @gtl2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl2');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gtl2, 80, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.37 evento.sustitucion_insertar: El que entra ya había ingresado (no disponible en el banco) => 1 error
PRINT '--- F-3.9.37 evento.sustitucion_insertar: El que entra ya había ingresado (no disponible en el banco)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gs1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_s1'),
        @gtl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_tl');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gtl, @gs1, 80, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.38 evento.sustitucion_insertar: motivo, minuto, sale ya reemplazado y entra ya ingresado => 4 errores
PRINT '--- F-3.9.38 evento.sustitucion_insertar: 4 errores: motivo, minuto, sale ya reemplazado y entra ya ingresado';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fg INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_gen'),
        @gt1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_t1'),
        @gs1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'gen_s1');
BEGIN TRY EXEC evento.sustitucion_insertar @fg, @gt1, @gs1, 44, 'ST', @V, 'otro', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.39 evento.sustitucion_insertar: Se alcanzó el máximo de cambios en tiempo reglamentario => 1 error
PRINT '--- F-3.9.39 evento.sustitucion_insertar: Se alcanzó el máximo de cambios en tiempo reglamentario';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fa INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_alg'),
        @atl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'alg_tl'),
        @asl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'alg_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fa, @atl, @asl, 80, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.40 evento.sustitucion_insertar: se superan las ventanas con el adicional del alargue y salto de ventana => 2 errores
PRINT '--- F-3.9.40 evento.sustitucion_insertar: 2 errores: se superan las ventanas con el adicional del alargue y salto de ventana';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @W INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_extra_alargue'),
        @VW1 INT,
        @fa INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_alg'),
        @atl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'alg_tl'),
        @asl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'alg_sl');
SET @VW1 = @V + @W + 1;
BEGIN TRY EXEC evento.sustitucion_insertar @fa, @atl, @asl, 100, 'alargue_1', @VW1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.41 evento.sustitucion_insertar: Se alcanzó el máximo de cambios incluyendo el adicional del alargue => 1 error
PRINT '--- F-3.9.41 evento.sustitucion_insertar: Se alcanzó el máximo de cambios incluyendo el adicional del alargue';
DECLARE @id INT,
        @ul INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_lim'),
        @ltl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'lim_tl'),
        @lsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'lim_sl');
SET @ul  = (SELECT MAX(numero_ventana) FROM evento.sustitucion WHERE formacion_id = @fl);   -- última ventana usada en lim (la del alargue)
BEGIN TRY EXEC evento.sustitucion_insertar @fl, @ltl, @lsl, 100, 'alargue_1', @ul, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.42 evento.sustitucion_insertar: máximo de cambios con alargue y ventana ya usada en otro período (alargue_1) => 2 errores
PRINT '--- F-3.9.42 evento.sustitucion_insertar: 2 errores: máximo de cambios con alargue y ventana ya usada en otro período (alargue_1)';
DECLARE @id INT,
        @ul INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_lim'),
        @ltl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'lim_tl'),
        @lsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'lim_sl');
SET @ul  = (SELECT MAX(numero_ventana) FROM evento.sustitucion WHERE formacion_id = @fl);   -- última ventana usada en lim (la del alargue)
BEGIN TRY EXEC evento.sustitucion_insertar @fl, @ltl, @lsl, 110, 'alargue_2', @ul, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.43 evento.sustitucion_insertar: máximo de cambios reglamentarios y ventana anterior a la última => 2 errores
PRINT '--- F-3.9.43 evento.sustitucion_insertar: 2 errores: máximo de cambios reglamentarios y ventana anterior a la última';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @fl INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_lim'),
        @ltl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'lim_tl'),
        @lsl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'lim_sl');
BEGIN TRY EXEC evento.sustitucion_insertar @fl, @ltl, @lsl, 80, 'ST', @V, 'tactico', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.sustitucion_modificar: F-3.9.44 a F-3.9.71
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.9.44 evento.sustitucion_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.9.44 evento.sustitucion_modificar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC evento.sustitucion_modificar NULL, 30, 'PT', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.45 evento.sustitucion_modificar: Sustitución inexistente => 1 error
PRINT '--- F-3.9.45 evento.sustitucion_modificar: Sustitución inexistente';
BEGIN TRY EXEC evento.sustitucion_modificar 999999, 30, 'PT', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.46 evento.sustitucion_modificar: El partido ya está finalizado => 1 error
PRINT '--- F-3.9.46 evento.sustitucion_modificar: El partido ya está finalizado';
DECLARE @mf INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'fin_x1');  -- partido finalizado
BEGIN TRY EXEC evento.sustitucion_modificar @mf, 30, 'PT', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.47 evento.sustitucion_modificar: Motivo nulo => 1 error
PRINT '--- F-3.9.47 evento.sustitucion_modificar: Motivo nulo';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, 'PT', 1, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.48 evento.sustitucion_modificar: Motivo inválido => 1 error
PRINT '--- F-3.9.48 evento.sustitucion_modificar: Motivo inválido';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, 'PT', 1, 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.49 evento.sustitucion_modificar: Motivo vacio => 1 error
PRINT '--- F-3.9.49 evento.sustitucion_modificar: Motivo vacio';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, 'PT', 1, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.50 evento.sustitucion_modificar: Período nulo => 1 error
PRINT '--- F-3.9.50 evento.sustitucion_modificar: Período nulo';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, NULL, 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.51 evento.sustitucion_modificar: Período inválido => 1 error
PRINT '--- F-3.9.51 evento.sustitucion_modificar: Período inválido';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, 'XX', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.52 evento.sustitucion_modificar: Minuto nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.9.52 evento.sustitucion_modificar: Minuto nulo (el mensaje dice "(nulo)")';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, NULL, 'PT', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.53 evento.sustitucion_modificar: Minuto 0 en PT (borde) => 1 error
PRINT '--- F-3.9.53 evento.sustitucion_modificar: Minuto 0 en PT (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 0,   'PT', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.54 evento.sustitucion_modificar: Minuto 61 en PT (borde) => 1 error
PRINT '--- F-3.9.54 evento.sustitucion_modificar: Minuto 61 en PT (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 61,  'PT', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.55 evento.sustitucion_modificar: Minuto 44 en ST (borde) => 1 error
PRINT '--- F-3.9.55 evento.sustitucion_modificar: Minuto 44 en ST (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 44,  'ST', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.56 evento.sustitucion_modificar: Minuto 111 en ST (borde) => 1 error
PRINT '--- F-3.9.56 evento.sustitucion_modificar: Minuto 111 en ST (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 111, 'ST', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.57 evento.sustitucion_modificar: Minuto 89 en alargue_1 (borde) => 1 error
PRINT '--- F-3.9.57 evento.sustitucion_modificar: Minuto 89 en alargue_1 (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 89,  'alargue_1', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.58 evento.sustitucion_modificar: Minuto 116 en alargue_1 (borde) => 1 error
PRINT '--- F-3.9.58 evento.sustitucion_modificar: Minuto 116 en alargue_1 (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 116, 'alargue_1', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.59 evento.sustitucion_modificar: Minuto 104 en alargue_2 (borde) => 1 error
PRINT '--- F-3.9.59 evento.sustitucion_modificar: Minuto 104 en alargue_2 (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 104, 'alargue_2', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.60 evento.sustitucion_modificar: Minuto 136 en alargue_2 (borde) => 1 error
PRINT '--- F-3.9.60 evento.sustitucion_modificar: Minuto 136 en alargue_2 (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 136, 'alargue_2', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.61 evento.sustitucion_modificar: Ventana nula => 1 error
PRINT '--- F-3.9.61 evento.sustitucion_modificar: Ventana nula';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, 'PT', NULL, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.62 evento.sustitucion_modificar: Ventana 0 (borde) => 1 error
PRINT '--- F-3.9.62 evento.sustitucion_modificar: Ventana 0 (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, 'PT', 0, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.63 evento.sustitucion_modificar: Ventana negativa => 1 error
PRINT '--- F-3.9.63 evento.sustitucion_modificar: Ventana negativa';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, 'PT', -1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.64 evento.sustitucion_modificar: Se superan las ventanas reglamentarias => 1 error
PRINT '--- F-3.9.64 evento.sustitucion_modificar: Se superan las ventanas reglamentarias';
DECLARE @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @V1 INT,
        @m2 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x2');  -- ST, ventana 2
SET @V1  = @V + 1;
BEGIN TRY EXEC evento.sustitucion_modificar @m2, 60, 'ST', @V1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.65 evento.sustitucion_modificar: Se superan las ventanas incluyendo la adicional del alargue => 1 error
PRINT '--- F-3.9.65 evento.sustitucion_modificar: Se superan las ventanas incluyendo la adicional del alargue';
DECLARE @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @W INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_extra_alargue'),
        @VW1 INT,
        @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
SET @VW1 = @V + @W + 1;
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 100, 'alargue_1', @VW1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.66 evento.sustitucion_modificar: Ventana 2 ya usada en otro período (ST) => 1 error
PRINT '--- F-3.9.66 evento.sustitucion_modificar: Ventana 2 ya usada en otro período (ST)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 20, 'PT', 2, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.67 evento.sustitucion_modificar: Ventana 1 ya usada en otro período (PT) => 1 error
PRINT '--- F-3.9.67 evento.sustitucion_modificar: Ventana 1 ya usada en otro período (PT)';
DECLARE @m2 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x2');  -- ST, ventana 2
BEGIN TRY EXEC evento.sustitucion_modificar @m2, 60, 'ST', 1, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.68 evento.sustitucion_modificar: Pasar un cambio de alargue a reglamentario cuando ya está el máximo reglamentario => 1 error
PRINT '--- F-3.9.68 evento.sustitucion_modificar: Pasar un cambio de alargue a reglamentario cuando ya está el máximo reglamentario';
DECLARE @C INT = (SELECT valor FROM torneo.parametro WHERE clave = 'cambios_max_reglamentarios'),
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @mA INT;
SET @mA  = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'lim_x' + CAST(@C + 1 AS VARCHAR(3)));   -- el cambio de alargue de lim
BEGIN TRY EXEC evento.sustitucion_modificar @mA, 80, 'ST', @V, 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.69 evento.sustitucion_modificar: minuto y motivo => 2 errores
PRINT '--- F-3.9.69 evento.sustitucion_modificar: 2 errores: minuto y motivo';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 0, 'PT', 1, 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.70 evento.sustitucion_modificar: minuto, motivo y ventana => 3 errores
PRINT '--- F-3.9.70 evento.sustitucion_modificar: 3 errores: minuto, motivo y ventana';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 0, 'PT', 0, 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.71 evento.sustitucion_modificar: En fase de grupos no hay tiempo suplementario => 1 error (antes, un cambio en la formación jug, que se deshace al final)
PRINT '--- F-3.9.71 evento.sustitucion_modificar: En fase de grupos no hay tiempo suplementario';
DECLARE @mg INT,
        @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @ss INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sust_sale');
SET @mg  = (SELECT sustitucion_id FROM evento.sustitucion WHERE formacion_id = @fj AND jugador_sale_id = @ss);   -- NULL hasta registrar el cambio en la formación jug (ver más abajo)
BEGIN TRAN;
BEGIN TRY
    DECLARE @se_mg INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sust_entra');
    EXEC evento.sustitucion_insertar @fj, @ss, @se_mg, 60, 'ST', 1, 'tactico', @mg OUTPUT;
    EXEC evento.sustitucion_modificar @mg, 95, 'alargue_1', 1, 'tactico';
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- -------------------------------------------------------------------------------------
-- evento.sustitucion_eliminar: F-3.9.72 a F-3.9.76
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.9.72 evento.sustitucion_eliminar: El jugador que ingresó fue reemplazado después (x3) => 1 error
PRINT '--- F-3.9.72 evento.sustitucion_eliminar: El jugador que ingresó fue reemplazado después (x3)';
DECLARE @e2 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'eli_x2');
BEGIN TRY EXEC evento.sustitucion_eliminar @e2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.73 evento.sustitucion_eliminar: El partido ya está finalizado => 1 error
PRINT '--- F-3.9.73 evento.sustitucion_eliminar: El partido ya está finalizado';
DECLARE @ef INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'fin_x1');
BEGIN TRY EXEC evento.sustitucion_eliminar @ef; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.74 evento.sustitucion_eliminar: Sustitución inexistente => 1 error
PRINT '--- F-3.9.74 evento.sustitucion_eliminar: Sustitución inexistente';
BEGIN TRY EXEC evento.sustitucion_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.75 evento.sustitucion_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.9.75 evento.sustitucion_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC evento.sustitucion_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.9.76 evento.sustitucion_eliminar: El jugador que ingresó tiene goles o asistencias en el partido => 1 error (antes, un gol del jugador que ingresó en el cambio gen_x1, que se deshace al final)
PRINT '--- F-3.9.76 evento.sustitucion_eliminar: El jugador que ingresó tiene goles o asistencias en el partido';
DECLARE @eg INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');
BEGIN TRAN;
BEGIN TRY
    DECLARE @g_ent INT = (SELECT jugador_entra_id FROM evento.sustitucion WHERE sustitucion_id = @eg),
            @g_for INT = (SELECT formacion_id FROM evento.sustitucion WHERE sustitucion_id = @eg);
    EXEC evento.gol_insertar @g_for, @g_ent, 85, 'jugada', 'ST';
    EXEC evento.sustitucion_eliminar @eg;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- ============================================================
-- 3.10 evento.gol (cada operación actualiza el marcador del partido en la misma transacción)
-- ============================================================

-- -------------------------------------------------------------------------------------
-- evento.gol_insertar: F-3.10.01 a F-3.10.46
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.10.01 evento.gol_insertar: Formacion inexistente => 1 error
PRINT '--- F-3.10.01 evento.gol_insertar: Formacion inexistente';
DECLARE @id INT,
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar 999999, @t1, 15, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.02 evento.gol_insertar: Formacion nula => 1 error
PRINT '--- F-3.10.02 evento.gol_insertar: Formacion nula';
DECLARE @id INT,
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar NULL, @t1, 15, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.03 evento.gol_insertar: Partido finalizado => 1 error
PRINT '--- F-3.10.03 evento.gol_insertar: Partido finalizado';
DECLARE @id INT,
        @fz INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'z_loc'),
        @zt INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'z_t1');
BEGIN TRY EXEC evento.gol_insertar @fz, @zt, 15, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.04 evento.gol_insertar: Jugador inexistente (el autor no integra la formacion) => 1 error
PRINT '--- F-3.10.04 evento.gol_insertar: Jugador inexistente (el autor no integra la formacion)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc');
BEGIN TRY EXEC evento.gol_insertar @fl, 999999, 15, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.05 evento.gol_insertar: Jugador nulo (el autor no integra la formacion) => 1 error
PRINT '--- F-3.10.05 evento.gol_insertar: Jugador nulo (el autor no integra la formacion)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc');
BEGIN TRY EXEC evento.gol_insertar @fl, NULL, 15, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.06 evento.gol_insertar: Autor convocado pero que no integra la formacion => 1 error
PRINT '--- F-3.10.06 evento.gol_insertar: Autor convocado pero que no integra la formacion';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @lf INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_fuera');
BEGIN TRY EXEC evento.gol_insertar @fl, @lf, 15, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.07 evento.gol_insertar: Autor que integra la formacion del rival => 1 error
PRINT '--- F-3.10.07 evento.gol_insertar: Autor que integra la formacion del rival';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @v1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'vis_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @v1, 15, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.08 evento.gol_insertar: Autor suplente sin sustitucion registrada (no ingreso) => 1 error
PRINT '--- F-3.10.08 evento.gol_insertar: Autor suplente sin sustitucion registrada (no ingreso)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @so INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_s_out');
BEGIN TRY EXEC evento.gol_insertar @fl, @so, 15, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.09 evento.gol_insertar: Tipo de gol nulo => 1 error
PRINT '--- F-3.10.09 evento.gol_insertar: Tipo de gol nulo';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, NULL, 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.10 evento.gol_insertar: Tipo de gol vacio => 1 error
PRINT '--- F-3.10.10 evento.gol_insertar: Tipo de gol vacio';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, '', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.11 evento.gol_insertar: Tipo de gol invalido => 1 error
PRINT '--- F-3.10.11 evento.gol_insertar: Tipo de gol invalido';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'otro_tipo', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.12 evento.gol_insertar: Periodo nulo => 1 error
PRINT '--- F-3.10.12 evento.gol_insertar: Periodo nulo';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.13 evento.gol_insertar: Periodo vacio => 1 error
PRINT '--- F-3.10.13 evento.gol_insertar: Periodo vacio';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', '', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.14 evento.gol_insertar: Periodo invalido (no se valida el minuto) => 1 error
PRINT '--- F-3.10.14 evento.gol_insertar: Periodo invalido (no se valida el minuto)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT2', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.15 evento.gol_insertar: Minuto nulo => 1 error
PRINT '--- F-3.10.15 evento.gol_insertar: Minuto nulo';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, NULL, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.16 evento.gol_insertar: Minuto negativo => 1 error
PRINT '--- F-3.10.16 evento.gol_insertar: Minuto negativo';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, -1, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.17 evento.gol_insertar: PT minuto 0 (borde) => 1 error
PRINT '--- F-3.10.17 evento.gol_insertar: PT minuto 0 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 0, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.18 evento.gol_insertar: PT minuto 46 (borde) => 1 error
PRINT '--- F-3.10.18 evento.gol_insertar: PT minuto 46 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 46, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.19 evento.gol_insertar: adicional_PT minuto 45 (borde) => 1 error
PRINT '--- F-3.10.19 evento.gol_insertar: adicional_PT minuto 45 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 45, 'jugada', 'adicional_PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.20 evento.gol_insertar: adicional_PT minuto 61 (borde) => 1 error
PRINT '--- F-3.10.20 evento.gol_insertar: adicional_PT minuto 61 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 61, 'jugada', 'adicional_PT', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.21 evento.gol_insertar: ST minuto 45 (borde) => 1 error
PRINT '--- F-3.10.21 evento.gol_insertar: ST minuto 45 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 45, 'jugada', 'ST', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.22 evento.gol_insertar: ST minuto 91 (borde) => 1 error
PRINT '--- F-3.10.22 evento.gol_insertar: ST minuto 91 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 91, 'jugada', 'ST', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.23 evento.gol_insertar: adicional_ST minuto 90 (borde) => 1 error
PRINT '--- F-3.10.23 evento.gol_insertar: adicional_ST minuto 90 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 90, 'jugada', 'adicional_ST', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.24 evento.gol_insertar: adicional_ST minuto 111 (borde) => 1 error
PRINT '--- F-3.10.24 evento.gol_insertar: adicional_ST minuto 111 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 111, 'jugada', 'adicional_ST', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.25 evento.gol_insertar: alargue_1 minuto 90 (borde) => 1 error
PRINT '--- F-3.10.25 evento.gol_insertar: alargue_1 minuto 90 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 90, 'jugada', 'alargue_1', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.26 evento.gol_insertar: alargue_1 minuto 106 (borde) => 1 error
PRINT '--- F-3.10.26 evento.gol_insertar: alargue_1 minuto 106 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 106, 'jugada', 'alargue_1', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.27 evento.gol_insertar: alargue_2 minuto 105 (borde) => 1 error
PRINT '--- F-3.10.27 evento.gol_insertar: alargue_2 minuto 105 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 105, 'jugada', 'alargue_2', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.28 evento.gol_insertar: alargue_2 minuto 121 (borde) => 1 error
PRINT '--- F-3.10.28 evento.gol_insertar: alargue_2 minuto 121 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 121, 'jugada', 'alargue_2', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.29 evento.gol_insertar: adicional_alargue minuto 105 (borde) => 1 error
PRINT '--- F-3.10.29 evento.gol_insertar: adicional_alargue minuto 105 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 105, 'jugada', 'adicional_alargue', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.30 evento.gol_insertar: adicional_alargue minuto 136 (borde) => 1 error
PRINT '--- F-3.10.30 evento.gol_insertar: adicional_alargue minuto 136 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 136, 'jugada', 'adicional_alargue', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.31 evento.gol_insertar: penales minuto 119 (borde) => 1 error
PRINT '--- F-3.10.31 evento.gol_insertar: penales minuto 119 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 119, 'penal', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.32 evento.gol_insertar: penales minuto 136 (borde) => 1 error
PRINT '--- F-3.10.32 evento.gol_insertar: penales minuto 136 (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 136, 'penal', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.33 evento.gol_insertar: El asistente es el mismo autor => 1 error
PRINT '--- F-3.10.33 evento.gol_insertar: El asistente es el mismo autor';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @t1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.34 evento.gol_insertar: Asistente inexistente (no integra la formacion) => 1 error
PRINT '--- F-3.10.34 evento.gol_insertar: Asistente inexistente (no integra la formacion)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', 999999, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.35 evento.gol_insertar: Asistente que no integra la formacion => 1 error
PRINT '--- F-3.10.35 evento.gol_insertar: Asistente que no integra la formacion';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @lf INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_fuera');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @lf, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.36 evento.gol_insertar: Asistente de la formacion rival => 1 error
PRINT '--- F-3.10.36 evento.gol_insertar: Asistente de la formacion rival';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @v1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'vis_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @v1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.37 evento.gol_insertar: Asistente suplente que no ingreso => 1 error
PRINT '--- F-3.10.37 evento.gol_insertar: Asistente suplente que no ingreso';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @so INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_s_out');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @so, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.38 evento.gol_insertar: Gol en contra con asistencia => 1 error
PRINT '--- F-3.10.38 evento.gol_insertar: Gol en contra con asistencia';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @t2 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t2');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'en_contra', 'PT', @t2, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.39 evento.gol_insertar: Gol de la tanda de penales con asistencia => 1 error
PRINT '--- F-3.10.39 evento.gol_insertar: Gol de la tanda de penales con asistencia';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @t2 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t2');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 120, 'penal', 'penales', @t2, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.40 evento.gol_insertar: Tanda de penales con tipo distinto de penal => 1 error
PRINT '--- F-3.10.40 evento.gol_insertar: Tanda de penales con tipo distinto de penal';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 120, 'jugada', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.41 evento.gol_insertar: Tanda de penales con gol en contra => 1 error
PRINT '--- F-3.10.41 evento.gol_insertar: Tanda de penales con gol en contra';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 120, 'en_contra', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.42 evento.gol_insertar: Fase de grupos: tanda de penales => 1 error
PRINT '--- F-3.10.42 evento.gol_insertar: Fase de grupos: tanda de penales';
DECLARE @id INT,
        @fj INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_jug'),
        @jg INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'jug_gol');
BEGIN TRY EXEC evento.gol_insertar @fj, @jg, 120, 'penal', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.43 evento.gol_insertar: tipo de gol y periodo invalidos => 2 errores
PRINT '--- F-3.10.43 evento.gol_insertar: 2 errores: tipo de gol y periodo invalidos';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'otro_tipo', 'PT2', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.44 evento.gol_insertar: fase de grupos con penales, minuto y tipo distinto de penal => 3 errores
PRINT '--- F-3.10.44 evento.gol_insertar: 3 errores: fase de grupos con penales, minuto y tipo distinto de penal';
DECLARE @id INT,
        @fj INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_jug'),
        @jg INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'jug_gol');
BEGIN TRY EXEC evento.gol_insertar @fj, @jg, 100, 'jugada', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.45 evento.gol_insertar: autor sin ingresar, asistente = autor, asistente sin ingresar y gol en contra con asistencia => 4 errores
PRINT '--- F-3.10.45 evento.gol_insertar: 4 errores: autor sin ingresar, asistente = autor, asistente sin ingresar y gol en contra con asistencia';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @so INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_s_out');
BEGIN TRY EXEC evento.gol_insertar @fl, @so, 20, 'en_contra', 'PT', @so, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.46 evento.gol_insertar: finalizado, tipo, minuto, autor no integra, asistente = autor y asistente no integra => 6 errores
PRINT '--- F-3.10.46 evento.gol_insertar: 6 errores: finalizado, tipo, minuto, autor no integra, asistente = autor y asistente no integra';
DECLARE @id INT,
        @fz INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'z_loc'),
        @lf INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_fuera');
BEGIN TRY EXEC evento.gol_insertar @fz, @lf, 0, 'otro_tipo', 'PT', @lf, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.gol_modificar: F-3.10.47 a F-3.10.90
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.10.47 evento.gol_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.10.47 evento.gol_modificar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC evento.gol_modificar NULL, 10, 'jugada', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.48 evento.gol_modificar: Gol inexistente => 1 error
PRINT '--- F-3.10.48 evento.gol_modificar: Gol inexistente';
BEGIN TRY EXEC evento.gol_modificar 999999, 10, 'jugada', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.49 evento.gol_modificar: Partido finalizado => 1 error
PRINT '--- F-3.10.49 evento.gol_modificar: Partido finalizado';
DECLARE @gf INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_fin');
BEGIN TRY EXEC evento.gol_modificar @gf, 12, 'jugada', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.50 evento.gol_modificar: Tipo de gol nulo => 1 error
PRINT '--- F-3.10.50 evento.gol_modificar: Tipo de gol nulo';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, NULL, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.51 evento.gol_modificar: Tipo de gol vacio => 1 error
PRINT '--- F-3.10.51 evento.gol_modificar: Tipo de gol vacio';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, '', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.52 evento.gol_modificar: Tipo de gol invalido => 1 error
PRINT '--- F-3.10.52 evento.gol_modificar: Tipo de gol invalido';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'otro_tipo', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.53 evento.gol_modificar: Periodo nulo => 1 error
PRINT '--- F-3.10.53 evento.gol_modificar: Periodo nulo';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.54 evento.gol_modificar: Periodo vacio => 1 error
PRINT '--- F-3.10.54 evento.gol_modificar: Periodo vacio';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.55 evento.gol_modificar: Periodo invalido (no se valida el minuto) => 1 error
PRINT '--- F-3.10.55 evento.gol_modificar: Periodo invalido (no se valida el minuto)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.56 evento.gol_modificar: Minuto nulo => 1 error
PRINT '--- F-3.10.56 evento.gol_modificar: Minuto nulo';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, NULL, 'jugada', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.57 evento.gol_modificar: Minuto negativo => 1 error
PRINT '--- F-3.10.57 evento.gol_modificar: Minuto negativo';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, -1, 'jugada', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.58 evento.gol_modificar: PT minuto 0 (borde) => 1 error
PRINT '--- F-3.10.58 evento.gol_modificar: PT minuto 0 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 0, 'jugada', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.59 evento.gol_modificar: PT minuto 46 (borde) => 1 error
PRINT '--- F-3.10.59 evento.gol_modificar: PT minuto 46 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 46, 'jugada', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.60 evento.gol_modificar: adicional_PT minuto 45 (borde) => 1 error
PRINT '--- F-3.10.60 evento.gol_modificar: adicional_PT minuto 45 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 45, 'jugada', 'adicional_PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.61 evento.gol_modificar: adicional_PT minuto 61 (borde) => 1 error
PRINT '--- F-3.10.61 evento.gol_modificar: adicional_PT minuto 61 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 61, 'jugada', 'adicional_PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.62 evento.gol_modificar: ST minuto 45 (borde) => 1 error
PRINT '--- F-3.10.62 evento.gol_modificar: ST minuto 45 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 45, 'jugada', 'ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.63 evento.gol_modificar: ST minuto 91 (borde) => 1 error
PRINT '--- F-3.10.63 evento.gol_modificar: ST minuto 91 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 91, 'jugada', 'ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.64 evento.gol_modificar: adicional_ST minuto 90 (borde) => 1 error
PRINT '--- F-3.10.64 evento.gol_modificar: adicional_ST minuto 90 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 90, 'jugada', 'adicional_ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.65 evento.gol_modificar: adicional_ST minuto 111 (borde) => 1 error
PRINT '--- F-3.10.65 evento.gol_modificar: adicional_ST minuto 111 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 111, 'jugada', 'adicional_ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.66 evento.gol_modificar: alargue_1 minuto 90 (borde) => 1 error
PRINT '--- F-3.10.66 evento.gol_modificar: alargue_1 minuto 90 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 90, 'jugada', 'alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.67 evento.gol_modificar: alargue_1 minuto 106 (borde) => 1 error
PRINT '--- F-3.10.67 evento.gol_modificar: alargue_1 minuto 106 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 106, 'jugada', 'alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.68 evento.gol_modificar: alargue_2 minuto 105 (borde) => 1 error
PRINT '--- F-3.10.68 evento.gol_modificar: alargue_2 minuto 105 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 105, 'jugada', 'alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.69 evento.gol_modificar: alargue_2 minuto 121 (borde) => 1 error
PRINT '--- F-3.10.69 evento.gol_modificar: alargue_2 minuto 121 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 121, 'jugada', 'alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.70 evento.gol_modificar: adicional_alargue minuto 105 (borde) => 1 error
PRINT '--- F-3.10.70 evento.gol_modificar: adicional_alargue minuto 105 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 105, 'jugada', 'adicional_alargue'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.71 evento.gol_modificar: adicional_alargue minuto 136 (borde) => 1 error
PRINT '--- F-3.10.71 evento.gol_modificar: adicional_alargue minuto 136 (borde)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 136, 'jugada', 'adicional_alargue'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.72 evento.gol_modificar: penales minuto 119 (borde) => 1 error
PRINT '--- F-3.10.72 evento.gol_modificar: penales minuto 119 (borde)';
DECLARE @gp INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_pen');
BEGIN TRY EXEC evento.gol_modificar @gp, 119, 'penal', 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.73 evento.gol_modificar: penales minuto 136 (borde) => 1 error
PRINT '--- F-3.10.73 evento.gol_modificar: penales minuto 136 (borde)';
DECLARE @gp INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_pen');
BEGIN TRY EXEC evento.gol_modificar @gp, 136, 'penal', 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.74 evento.gol_modificar: El asistente es el mismo autor => 1 error
PRINT '--- F-3.10.74 evento.gol_modificar: El asistente es el mismo autor';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @t1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.75 evento.gol_modificar: Asistente inexistente (no integra la formacion) => 1 error
PRINT '--- F-3.10.75 evento.gol_modificar: Asistente inexistente (no integra la formacion)';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.76 evento.gol_modificar: Asistente que no integra la formacion => 1 error
PRINT '--- F-3.10.76 evento.gol_modificar: Asistente que no integra la formacion';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @lf INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_fuera');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @lf; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.77 evento.gol_modificar: Asistente de la formacion rival => 1 error
PRINT '--- F-3.10.77 evento.gol_modificar: Asistente de la formacion rival';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @v1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'vis_t1');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @v1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.78 evento.gol_modificar: Asistente suplente que no ingreso => 1 error
PRINT '--- F-3.10.78 evento.gol_modificar: Asistente suplente que no ingreso';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @so INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_s_out');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @so; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.79 evento.gol_modificar: Gol en contra con asistencia => 1 error
PRINT '--- F-3.10.79 evento.gol_modificar: Gol en contra con asistencia';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @t2 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t2');
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'en_contra', 'PT', @t2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.80 evento.gol_modificar: Gol de la tanda de penales con asistencia => 1 error
PRINT '--- F-3.10.80 evento.gol_modificar: Gol de la tanda de penales con asistencia';
DECLARE @gp INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_pen'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_modificar @gp, 125, 'penal', 'penales', @t1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.81 evento.gol_modificar: Tanda de penales con tipo distinto de penal => 1 error
PRINT '--- F-3.10.81 evento.gol_modificar: Tanda de penales con tipo distinto de penal';
DECLARE @gp INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_pen');
BEGIN TRY EXEC evento.gol_modificar @gp, 125, 'jugada', 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.82 evento.gol_modificar: Tanda de penales con gol en contra => 1 error
PRINT '--- F-3.10.82 evento.gol_modificar: Tanda de penales con gol en contra';
DECLARE @gp INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_pen');
BEGIN TRY EXEC evento.gol_modificar @gp, 125, 'en_contra', 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.83 evento.gol_modificar: Fase de grupos: alargue_1 => 1 error
PRINT '--- F-3.10.83 evento.gol_modificar: Fase de grupos: alargue_1';
DECLARE @gj INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_jug');
BEGIN TRY EXEC evento.gol_modificar @gj, 100, 'jugada', 'alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.84 evento.gol_modificar: Fase de grupos: alargue_2 => 1 error
PRINT '--- F-3.10.84 evento.gol_modificar: Fase de grupos: alargue_2';
DECLARE @gj INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_jug');
BEGIN TRY EXEC evento.gol_modificar @gj, 110, 'jugada', 'alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.85 evento.gol_modificar: Fase de grupos: adicional_alargue => 1 error
PRINT '--- F-3.10.85 evento.gol_modificar: Fase de grupos: adicional_alargue';
DECLARE @gj INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_jug');
BEGIN TRY EXEC evento.gol_modificar @gj, 110, 'jugada', 'adicional_alargue'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.86 evento.gol_modificar: Fase de grupos: tanda de penales => 1 error
PRINT '--- F-3.10.86 evento.gol_modificar: Fase de grupos: tanda de penales';
DECLARE @gj INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_jug');
BEGIN TRY EXEC evento.gol_modificar @gj, 120, 'penal', 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.87 evento.gol_modificar: tipo de gol, periodo y minuto nulos => 3 errores
PRINT '--- F-3.10.87 evento.gol_modificar: 3 errores: tipo de gol, periodo y minuto nulos';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
BEGIN TRY EXEC evento.gol_modificar @gm, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.88 evento.gol_modificar: tipo, minuto y asistente = autor => 3 errores
PRINT '--- F-3.10.88 evento.gol_modificar: 3 errores: tipo, minuto y asistente = autor';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_modificar @gm, 0, 'otro_tipo', 'PT', @t1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.89 evento.gol_modificar: fase de grupos con penales, minuto y tipo distinto de penal => 3 errores
PRINT '--- F-3.10.89 evento.gol_modificar: 3 errores: fase de grupos con penales, minuto y tipo distinto de penal';
DECLARE @gj INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_jug');
BEGIN TRY EXEC evento.gol_modificar @gj, 100, 'jugada', 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.90 evento.gol_modificar: minuto, asistente = autor, gol en contra con asistencia, penales con asistencia y tipo distinto de penal => 5 errores
PRINT '--- F-3.10.90 evento.gol_modificar: 5 errores: minuto, asistente = autor, gol en contra con asistencia, penales con asistencia y tipo distinto de penal';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
BEGIN TRY EXEC evento.gol_modificar @gm, 50, 'en_contra', 'penales', @t1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.gol_eliminar: F-3.10.91 a F-3.10.93
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.10.91 evento.gol_eliminar: Gol inexistente => 1 error
PRINT '--- F-3.10.91 evento.gol_eliminar: Gol inexistente';
BEGIN TRY EXEC evento.gol_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.92 evento.gol_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.10.92 evento.gol_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC evento.gol_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.10.93 evento.gol_eliminar: Partido finalizado => 1 error
PRINT '--- F-3.10.93 evento.gol_eliminar: Partido finalizado';
DECLARE @gf  INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_fin');
BEGIN TRY EXEC evento.gol_eliminar @gf; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================

-- -------------------------------------------------------------------------------------
-- evento.tarjeta_insertar: F-3.11.01 a F-3.11.52
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.01 evento.tarjeta_insertar: partido inexistente y la persona no participa del partido => 2 errores
PRINT '--- F-3.11.01 evento.tarjeta_insertar: 2 errores: partido inexistente y la persona no participa del partido';
DECLARE @id INT,
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar 999999, @le, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.02 evento.tarjeta_insertar: partido nulo y la persona no participa del partido => 2 errores
PRINT '--- F-3.11.02 evento.tarjeta_insertar: 2 errores: partido nulo y la persona no participa del partido';
DECLARE @id INT,
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar NULL, @le, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.03 evento.tarjeta_insertar: Partido finalizado => 1 error
PRINT '--- F-3.11.03 evento.tarjeta_insertar: Partido finalizado';
DECLARE @id INT,
        @pz INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_z'),
        @zl  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_zlim');
BEGIN TRY EXEC evento.tarjeta_insertar @pz, @zl, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.04 evento.tarjeta_insertar: Persona inexistente => 1 error
PRINT '--- F-3.11.04 evento.tarjeta_insertar: Persona inexistente';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar');
BEGIN TRY EXEC evento.tarjeta_insertar @pt, 999999, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.05 evento.tarjeta_insertar: Persona nula => 1 error
PRINT '--- F-3.11.05 evento.tarjeta_insertar: Persona nula';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar');
BEGIN TRY EXEC evento.tarjeta_insertar @pt, NULL, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.06 evento.tarjeta_insertar: Persona que existe pero no participa del partido => 1 error
PRINT '--- F-3.11.06 evento.tarjeta_insertar: Persona que existe pero no participa del partido';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @np  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_np');
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @np, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.07 evento.tarjeta_insertar: Persona que participa de otro partido (formacion jug del partido mod) pero no de este => 1 error
PRINT '--- F-3.11.07 evento.tarjeta_insertar: Persona que participa de otro partido (formacion jug del partido mod) pero no de este';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @cn  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_conv');  -- solo para casos de error (partido de grupos)
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @cn, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.08 evento.tarjeta_insertar: Tipo nulo => 1 error
PRINT '--- F-3.11.08 evento.tarjeta_insertar: Tipo nulo';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', NULL, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.09 evento.tarjeta_insertar: Tipo vacio => 1 error
PRINT '--- F-3.11.09 evento.tarjeta_insertar: Tipo vacio';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', '', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.10 evento.tarjeta_insertar: Tipo invalido => 1 error
PRINT '--- F-3.11.10 evento.tarjeta_insertar: Tipo invalido';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'verde', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.11 evento.tarjeta_insertar: Amarilla con tipo de expulsion => 1 error
PRINT '--- F-3.11.11 evento.tarjeta_insertar: Amarilla con tipo de expulsion';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'amarilla', NULL, 'roja_directa', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.12 evento.tarjeta_insertar: Amarilla con tipo de expulsion (doble_amarilla) => 1 error
PRINT '--- F-3.11.12 evento.tarjeta_insertar: Amarilla con tipo de expulsion (doble_amarilla)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'amarilla', NULL, 'doble_amarilla', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.13 evento.tarjeta_insertar: Roja sin tipo de expulsion (nulo) => 1 error
PRINT '--- F-3.11.13 evento.tarjeta_insertar: Roja sin tipo de expulsion (nulo)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'roja', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.14 evento.tarjeta_insertar: Roja con tipo de expulsion vacio => 1 error
PRINT '--- F-3.11.14 evento.tarjeta_insertar: Roja con tipo de expulsion vacio';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'roja', NULL, '', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.15 evento.tarjeta_insertar: Roja con tipo de expulsion invalido => 1 error
PRINT '--- F-3.11.15 evento.tarjeta_insertar: Roja con tipo de expulsion invalido';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'roja', NULL, 'otra', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.16 evento.tarjeta_insertar: Doble amarilla sin amarilla previa => 1 error
PRINT '--- F-3.11.16 evento.tarjeta_insertar: Doble amarilla sin amarilla previa';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'roja', NULL, 'doble_amarilla', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.17 evento.tarjeta_insertar: La persona ya tiene una amarilla en el partido => 1 error
PRINT '--- F-3.11.17 evento.tarjeta_insertar: La persona ya tiene una amarilla en el partido';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @ea  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_ea');  -- solo para casos de error: ya tiene una amarilla
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @ea, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.18 evento.tarjeta_insertar: La persona ya fue expulsada (roja directa) => 1 error
PRINT '--- F-3.11.18 evento.tarjeta_insertar: La persona ya fue expulsada (roja directa)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @rj  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_mr');
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @rj, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.19 evento.tarjeta_insertar: La persona ya fue expulsada: nueva roja => 1 error
PRINT '--- F-3.11.19 evento.tarjeta_insertar: La persona ya fue expulsada: nueva roja';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @rj  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_mr');
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @rj, 15, 'PT', 'roja', NULL, 'roja_directa', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.20 evento.tarjeta_insertar: La persona ya fue expulsada por doble amarilla (tiene la amarilla previa) => 1 error
PRINT '--- F-3.11.20 evento.tarjeta_insertar: La persona ya fue expulsada por doble amarilla (tiene la amarilla previa)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @dob INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_dob');
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @dob, 15, 'PT', 'roja', NULL, 'doble_amarilla', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.21 evento.tarjeta_insertar: La persona ya fue expulsada (tenia amarilla y roja) => 1 error
PRINT '--- F-3.11.21 evento.tarjeta_insertar: La persona ya fue expulsada (tenia amarilla y roja)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @dob INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_dob');
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @dob, 15, 'PT', 'roja', NULL, 'roja_directa', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.22 evento.tarjeta_insertar: Periodo nulo => 1 error
PRINT '--- F-3.11.22 evento.tarjeta_insertar: Periodo nulo';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, NULL, 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.23 evento.tarjeta_insertar: Periodo vacio => 1 error
PRINT '--- F-3.11.23 evento.tarjeta_insertar: Periodo vacio';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, '', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.24 evento.tarjeta_insertar: Periodo invalido (no se valida el minuto) => 1 error
PRINT '--- F-3.11.24 evento.tarjeta_insertar: Periodo invalido (no se valida el minuto)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT2', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.25 evento.tarjeta_insertar: Minuto nulo => 1 error
PRINT '--- F-3.11.25 evento.tarjeta_insertar: Minuto nulo';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, NULL, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.26 evento.tarjeta_insertar: Minuto negativo => 1 error
PRINT '--- F-3.11.26 evento.tarjeta_insertar: Minuto negativo';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, -1, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.27 evento.tarjeta_insertar: PT minuto 0 (borde) => 1 error
PRINT '--- F-3.11.27 evento.tarjeta_insertar: PT minuto 0 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 0, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.28 evento.tarjeta_insertar: PT minuto 46 (borde) => 1 error
PRINT '--- F-3.11.28 evento.tarjeta_insertar: PT minuto 46 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 46, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.29 evento.tarjeta_insertar: adicional_PT minuto 45 (borde) => 1 error
PRINT '--- F-3.11.29 evento.tarjeta_insertar: adicional_PT minuto 45 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 45, 'adicional_PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.30 evento.tarjeta_insertar: adicional_PT minuto 61 (borde) => 1 error
PRINT '--- F-3.11.30 evento.tarjeta_insertar: adicional_PT minuto 61 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 61, 'adicional_PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.31 evento.tarjeta_insertar: ST minuto 45 (borde) => 1 error
PRINT '--- F-3.11.31 evento.tarjeta_insertar: ST minuto 45 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 45, 'ST', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.32 evento.tarjeta_insertar: ST minuto 91 (borde) => 1 error
PRINT '--- F-3.11.32 evento.tarjeta_insertar: ST minuto 91 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 91, 'ST', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.33 evento.tarjeta_insertar: adicional_ST minuto 90 (borde) => 1 error
PRINT '--- F-3.11.33 evento.tarjeta_insertar: adicional_ST minuto 90 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 90, 'adicional_ST', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.34 evento.tarjeta_insertar: adicional_ST minuto 111 (borde) => 1 error
PRINT '--- F-3.11.34 evento.tarjeta_insertar: adicional_ST minuto 111 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 111, 'adicional_ST', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.35 evento.tarjeta_insertar: alargue_1 minuto 90 (borde) => 1 error
PRINT '--- F-3.11.35 evento.tarjeta_insertar: alargue_1 minuto 90 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 90, 'alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.36 evento.tarjeta_insertar: alargue_1 minuto 106 (borde) => 1 error
PRINT '--- F-3.11.36 evento.tarjeta_insertar: alargue_1 minuto 106 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 106, 'alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.37 evento.tarjeta_insertar: adicional_alargue_1 minuto 105 (borde) => 1 error
PRINT '--- F-3.11.37 evento.tarjeta_insertar: adicional_alargue_1 minuto 105 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 105, 'adicional_alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.38 evento.tarjeta_insertar: adicional_alargue_1 minuto 116 (borde) => 1 error
PRINT '--- F-3.11.38 evento.tarjeta_insertar: adicional_alargue_1 minuto 116 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 116, 'adicional_alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.39 evento.tarjeta_insertar: alargue_2 minuto 105 (borde) => 1 error
PRINT '--- F-3.11.39 evento.tarjeta_insertar: alargue_2 minuto 105 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 105, 'alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.40 evento.tarjeta_insertar: alargue_2 minuto 121 (borde) => 1 error
PRINT '--- F-3.11.40 evento.tarjeta_insertar: alargue_2 minuto 121 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 121, 'alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.41 evento.tarjeta_insertar: adicional_alargue_2 minuto 120 (borde) => 1 error
PRINT '--- F-3.11.41 evento.tarjeta_insertar: adicional_alargue_2 minuto 120 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 120, 'adicional_alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.42 evento.tarjeta_insertar: adicional_alargue_2 minuto 136 (borde) => 1 error
PRINT '--- F-3.11.42 evento.tarjeta_insertar: adicional_alargue_2 minuto 136 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 136, 'adicional_alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.43 evento.tarjeta_insertar: penales minuto 119 (borde) => 1 error
PRINT '--- F-3.11.43 evento.tarjeta_insertar: penales minuto 119 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 119, 'penales', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.44 evento.tarjeta_insertar: penales minuto 136 (borde) => 1 error
PRINT '--- F-3.11.44 evento.tarjeta_insertar: penales minuto 136 (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @le  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_err');  -- solo para casos de error: no darlo de alta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @le, 136, 'penales', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.45 evento.tarjeta_insertar: Fase de grupos: alargue_1 => 1 error
PRINT '--- F-3.11.45 evento.tarjeta_insertar: Fase de grupos: alargue_1';
DECLARE @id INT,
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'mod'),
        @cn  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_conv');  -- solo para casos de error (partido de grupos)
BEGIN TRY EXEC evento.tarjeta_insertar @pm, @cn, 100, 'alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.46 evento.tarjeta_insertar: Fase de grupos: adicional_alargue_1 => 1 error
PRINT '--- F-3.11.46 evento.tarjeta_insertar: Fase de grupos: adicional_alargue_1';
DECLARE @id INT,
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'mod'),
        @cn  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_conv');  -- solo para casos de error (partido de grupos)
BEGIN TRY EXEC evento.tarjeta_insertar @pm, @cn, 110, 'adicional_alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.47 evento.tarjeta_insertar: Fase de grupos: alargue_2 => 1 error
PRINT '--- F-3.11.47 evento.tarjeta_insertar: Fase de grupos: alargue_2';
DECLARE @id INT,
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'mod'),
        @cn  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_conv');  -- solo para casos de error (partido de grupos)
BEGIN TRY EXEC evento.tarjeta_insertar @pm, @cn, 110, 'alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.48 evento.tarjeta_insertar: Fase de grupos: adicional_alargue_2 => 1 error
PRINT '--- F-3.11.48 evento.tarjeta_insertar: Fase de grupos: adicional_alargue_2';
DECLARE @id INT,
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'mod'),
        @cn  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_conv');  -- solo para casos de error (partido de grupos)
BEGIN TRY EXEC evento.tarjeta_insertar @pm, @cn, 125, 'adicional_alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.49 evento.tarjeta_insertar: Fase de grupos: tanda de penales => 1 error
PRINT '--- F-3.11.49 evento.tarjeta_insertar: Fase de grupos: tanda de penales';
DECLARE @id INT,
        @pm INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'mod'),
        @cn  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_conv');  -- solo para casos de error (partido de grupos)
BEGIN TRY EXEC evento.tarjeta_insertar @pm, @cn, 125, 'penales', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.50 evento.tarjeta_insertar: partido, periodo, minuto, persona y tipo (todo nulo) => 5 errores
PRINT '--- F-3.11.50 evento.tarjeta_insertar: 5 errores: partido, periodo, minuto, persona y tipo (todo nulo)';
DECLARE @id INT;
BEGIN TRY EXEC evento.tarjeta_insertar NULL, NULL, NULL, NULL, NULL, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.51 evento.tarjeta_insertar: partido finalizado y minuto => 2 errores
PRINT '--- F-3.11.51 evento.tarjeta_insertar: 2 errores: partido finalizado y minuto';
DECLARE @id INT,
        @pz INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_z'),
        @zl  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_zlim');
BEGIN TRY EXEC evento.tarjeta_insertar @pz, @zl, 0, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.52 evento.tarjeta_insertar: amarilla con tipo de expulsion, persona ya expulsada y ya tiene una amarilla => 3 errores
PRINT '--- F-3.11.52 evento.tarjeta_insertar: 3 errores: amarilla con tipo de expulsion, persona ya expulsada y ya tiene una amarilla';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @dob INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_dob');
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @dob, 15, 'PT', 'amarilla', NULL, 'doble_amarilla', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.tarjeta_modificar: F-3.11.53 a F-3.11.85
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.53 evento.tarjeta_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.11.53 evento.tarjeta_modificar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC evento.tarjeta_modificar NULL, 10, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.54 evento.tarjeta_modificar: Tarjeta inexistente => 1 error
PRINT '--- F-3.11.54 evento.tarjeta_modificar: Tarjeta inexistente';
BEGIN TRY EXEC evento.tarjeta_modificar 999999, 10, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.55 evento.tarjeta_modificar: Partido finalizado => 1 error
PRINT '--- F-3.11.55 evento.tarjeta_modificar: Partido finalizado';
DECLARE @tf  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_fin');
BEGIN TRY EXEC evento.tarjeta_modificar @tf, 12, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.56 evento.tarjeta_modificar: Periodo nulo => 1 error
PRINT '--- F-3.11.56 evento.tarjeta_modificar: Periodo nulo';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 10, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.57 evento.tarjeta_modificar: Periodo vacio => 1 error
PRINT '--- F-3.11.57 evento.tarjeta_modificar: Periodo vacio';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 10, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.58 evento.tarjeta_modificar: Periodo invalido (no se valida el minuto) => 1 error
PRINT '--- F-3.11.58 evento.tarjeta_modificar: Periodo invalido (no se valida el minuto)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 10, 'PT2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.59 evento.tarjeta_modificar: Minuto nulo => 1 error
PRINT '--- F-3.11.59 evento.tarjeta_modificar: Minuto nulo';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, NULL, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.60 evento.tarjeta_modificar: Minuto negativo => 1 error
PRINT '--- F-3.11.60 evento.tarjeta_modificar: Minuto negativo';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, -1, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.61 evento.tarjeta_modificar: PT minuto 0 (borde) => 1 error
PRINT '--- F-3.11.61 evento.tarjeta_modificar: PT minuto 0 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 0, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.62 evento.tarjeta_modificar: PT minuto 46 (borde) => 1 error
PRINT '--- F-3.11.62 evento.tarjeta_modificar: PT minuto 46 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 46, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.63 evento.tarjeta_modificar: adicional_PT minuto 45 (borde) => 1 error
PRINT '--- F-3.11.63 evento.tarjeta_modificar: adicional_PT minuto 45 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 45, 'adicional_PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.64 evento.tarjeta_modificar: adicional_PT minuto 61 (borde) => 1 error
PRINT '--- F-3.11.64 evento.tarjeta_modificar: adicional_PT minuto 61 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 61, 'adicional_PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.65 evento.tarjeta_modificar: ST minuto 45 (borde) => 1 error
PRINT '--- F-3.11.65 evento.tarjeta_modificar: ST minuto 45 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 45, 'ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.66 evento.tarjeta_modificar: ST minuto 91 (borde) => 1 error
PRINT '--- F-3.11.66 evento.tarjeta_modificar: ST minuto 91 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 91, 'ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.67 evento.tarjeta_modificar: adicional_ST minuto 90 (borde) => 1 error
PRINT '--- F-3.11.67 evento.tarjeta_modificar: adicional_ST minuto 90 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 90, 'adicional_ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.68 evento.tarjeta_modificar: adicional_ST minuto 111 (borde) => 1 error
PRINT '--- F-3.11.68 evento.tarjeta_modificar: adicional_ST minuto 111 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 111, 'adicional_ST'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.69 evento.tarjeta_modificar: alargue_1 minuto 90 (borde) => 1 error
PRINT '--- F-3.11.69 evento.tarjeta_modificar: alargue_1 minuto 90 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 90, 'alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.70 evento.tarjeta_modificar: alargue_1 minuto 106 (borde) => 1 error
PRINT '--- F-3.11.70 evento.tarjeta_modificar: alargue_1 minuto 106 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 106, 'alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.71 evento.tarjeta_modificar: adicional_alargue_1 minuto 105 (borde) => 1 error
PRINT '--- F-3.11.71 evento.tarjeta_modificar: adicional_alargue_1 minuto 105 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 105, 'adicional_alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.72 evento.tarjeta_modificar: adicional_alargue_1 minuto 116 (borde) => 1 error
PRINT '--- F-3.11.72 evento.tarjeta_modificar: adicional_alargue_1 minuto 116 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 116, 'adicional_alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.73 evento.tarjeta_modificar: alargue_2 minuto 105 (borde) => 1 error
PRINT '--- F-3.11.73 evento.tarjeta_modificar: alargue_2 minuto 105 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 105, 'alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.74 evento.tarjeta_modificar: alargue_2 minuto 121 (borde) => 1 error
PRINT '--- F-3.11.74 evento.tarjeta_modificar: alargue_2 minuto 121 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 121, 'alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.75 evento.tarjeta_modificar: adicional_alargue_2 minuto 120 (borde) => 1 error
PRINT '--- F-3.11.75 evento.tarjeta_modificar: adicional_alargue_2 minuto 120 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 120, 'adicional_alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.76 evento.tarjeta_modificar: adicional_alargue_2 minuto 136 (borde) => 1 error
PRINT '--- F-3.11.76 evento.tarjeta_modificar: adicional_alargue_2 minuto 136 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 136, 'adicional_alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.77 evento.tarjeta_modificar: penales minuto 119 (borde) => 1 error
PRINT '--- F-3.11.77 evento.tarjeta_modificar: penales minuto 119 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 119, 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.78 evento.tarjeta_modificar: penales minuto 136 (borde) => 1 error
PRINT '--- F-3.11.78 evento.tarjeta_modificar: penales minuto 136 (borde)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 136, 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.79 evento.tarjeta_modificar: Fase de grupos: alargue_1 => 1 error
PRINT '--- F-3.11.79 evento.tarjeta_modificar: Fase de grupos: alargue_1';
DECLARE @tj  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_jug');
BEGIN TRY EXEC evento.tarjeta_modificar @tj, 100, 'alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.80 evento.tarjeta_modificar: Fase de grupos: adicional_alargue_1 => 1 error
PRINT '--- F-3.11.80 evento.tarjeta_modificar: Fase de grupos: adicional_alargue_1';
DECLARE @tj  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_jug');
BEGIN TRY EXEC evento.tarjeta_modificar @tj, 110, 'adicional_alargue_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.81 evento.tarjeta_modificar: Fase de grupos: alargue_2 => 1 error
PRINT '--- F-3.11.81 evento.tarjeta_modificar: Fase de grupos: alargue_2';
DECLARE @tj  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_jug');
BEGIN TRY EXEC evento.tarjeta_modificar @tj, 110, 'alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.82 evento.tarjeta_modificar: Fase de grupos: adicional_alargue_2 => 1 error
PRINT '--- F-3.11.82 evento.tarjeta_modificar: Fase de grupos: adicional_alargue_2';
DECLARE @tj  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_jug');
BEGIN TRY EXEC evento.tarjeta_modificar @tj, 125, 'adicional_alargue_2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.83 evento.tarjeta_modificar: Fase de grupos: tanda de penales => 1 error
PRINT '--- F-3.11.83 evento.tarjeta_modificar: Fase de grupos: tanda de penales';
DECLARE @tj  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_jug');
BEGIN TRY EXEC evento.tarjeta_modificar @tj, 125, 'penales'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.84 evento.tarjeta_modificar: partido finalizado y minuto => 2 errores
PRINT '--- F-3.11.84 evento.tarjeta_modificar: 2 errores: partido finalizado y minuto';
DECLARE @tf  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_fin');
BEGIN TRY EXEC evento.tarjeta_modificar @tf, 0, 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.85 evento.tarjeta_modificar: partido finalizado, periodo y minuto nulos => 3 errores
PRINT '--- F-3.11.85 evento.tarjeta_modificar: 3 errores: partido finalizado, periodo y minuto nulos';
DECLARE @tf  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_fin');
BEGIN TRY EXEC evento.tarjeta_modificar @tf, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.tarjeta_eliminar: F-3.11.86 a F-3.11.89
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.86 evento.tarjeta_eliminar: Es la primera amarilla de una expulsion por doble amarilla => 1 error
PRINT '--- F-3.11.86 evento.tarjeta_eliminar: Es la primera amarilla de una expulsion por doble amarilla';
DECLARE @tda INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_dob_a');
BEGIN TRY EXEC evento.tarjeta_eliminar @tda; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.87 evento.tarjeta_eliminar: Tarjeta inexistente => 1 error
PRINT '--- F-3.11.87 evento.tarjeta_eliminar: Tarjeta inexistente';
BEGIN TRY EXEC evento.tarjeta_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.88 evento.tarjeta_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.11.88 evento.tarjeta_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC evento.tarjeta_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.89 evento.tarjeta_eliminar: Partido finalizado => 1 error
PRINT '--- F-3.11.89 evento.tarjeta_eliminar: Partido finalizado';
DECLARE @tf  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_fin');
BEGIN TRY EXEC evento.tarjeta_eliminar @tf; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.criterio_suspension_insertar: F-3.11.90 a F-3.11.104
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.90 evento.criterio_suspension_insertar: Fase invalida => 1 error
PRINT '--- F-3.11.90 evento.criterio_suspension_insertar: Fase invalida';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 98, 1, 'preliminar', NULL, 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.91 evento.criterio_suspension_insertar: Fase vacia (vacio no es NULL: es invalida) => 1 error
PRINT '--- F-3.11.91 evento.criterio_suspension_insertar: Fase vacia (vacio no es NULL: es invalida)';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 98, 1, '', NULL, 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.92 evento.criterio_suspension_insertar: Tipo de persona invalido => 1 error
PRINT '--- F-3.11.92 evento.criterio_suspension_insertar: Tipo de persona invalido';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 98, 1, 'grupos', 'arbitro', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.93 evento.criterio_suspension_insertar: Tipo de persona invalido (plural) => 1 error
PRINT '--- F-3.11.93 evento.criterio_suspension_insertar: Tipo de persona invalido (plural)';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 98, 1, 'grupos', 'jugadores', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.94 evento.criterio_suspension_insertar: Cantidad de amarillas nula => 1 error
PRINT '--- F-3.11.94 evento.criterio_suspension_insertar: Cantidad de amarillas nula';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar NULL, 1, 'grupos', 'jugador', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.95 evento.criterio_suspension_insertar: Cantidad de amarillas 0 (borde) => 1 error
PRINT '--- F-3.11.95 evento.criterio_suspension_insertar: Cantidad de amarillas 0 (borde)';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 0, 1, 'grupos', 'jugador', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.96 evento.criterio_suspension_insertar: Cantidad de amarillas negativa => 1 error
PRINT '--- F-3.11.96 evento.criterio_suspension_insertar: Cantidad de amarillas negativa';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar -1, 1, 'grupos', 'jugador', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.97 evento.criterio_suspension_insertar: Partidos de suspension nulos => 1 error
PRINT '--- F-3.11.97 evento.criterio_suspension_insertar: Partidos de suspension nulos';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 98, NULL, 'grupos', 'jugador', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.98 evento.criterio_suspension_insertar: Partidos de suspension negativos => 1 error
PRINT '--- F-3.11.98 evento.criterio_suspension_insertar: Partidos de suspension negativos';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 98, -1, 'grupos', 'jugador', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.99 evento.criterio_suspension_insertar: Duplicado de 'dup' => 1 error
PRINT '--- F-3.11.99 evento.criterio_suspension_insertar: Duplicado de ''dup''';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 90, 1, 'semifinal', 'jugador', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.100 evento.criterio_suspension_insertar: Duplicado de 'base_null' (fase y tipo NULL) => 1 error
PRINT '--- F-3.11.100 evento.criterio_suspension_insertar: Duplicado de ''base_null'' (fase y tipo NULL)';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 90, 1, NULL, NULL, 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.101 evento.criterio_suspension_insertar: fase, tipo, cantidad y partidos => 4 errores
PRINT '--- F-3.11.101 evento.criterio_suspension_insertar: 4 errores: fase, tipo, cantidad y partidos';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 0, 0, 'preliminar', 'arbitro', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.102 evento.criterio_suspension_insertar: partidos de suspension y duplicado de 'dup' => 2 errores
PRINT '--- F-3.11.102 evento.criterio_suspension_insertar: 2 errores: partidos de suspension y duplicado de ''dup''';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 90, 0, 'semifinal', 'jugador', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.103 evento.criterio_suspension_insertar: fase invalida, partidos y duplicado de 'base_null' => 3 errores
PRINT '--- F-3.11.103 evento.criterio_suspension_insertar: 3 errores: fase invalida, partidos y duplicado de ''base_null''';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 90, 0, '', NULL, 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.104 evento.criterio_suspension_insertar: fase, tipo, partidos y duplicado de 'base_null' => 4 errores
PRINT '--- F-3.11.104 evento.criterio_suspension_insertar: 4 errores: fase, tipo, partidos y duplicado de ''base_null''';
DECLARE @id INT;
BEGIN TRY EXEC evento.criterio_suspension_insertar 90, 0, '', '', 1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.criterio_suspension_modificar: F-3.11.105 a F-3.11.120
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.105 evento.criterio_suspension_modificar: Id nulo => 1 error
PRINT '--- F-3.11.105 evento.criterio_suspension_modificar: Id nulo';
BEGIN TRY EXEC evento.criterio_suspension_modificar NULL, 85, 1, 'grupos', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.106 evento.criterio_suspension_modificar: Criterio inexistente => 1 error
PRINT '--- F-3.11.106 evento.criterio_suspension_modificar: Criterio inexistente';
BEGIN TRY EXEC evento.criterio_suspension_modificar 999999, 85, 1, 'grupos', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.107 evento.criterio_suspension_modificar: Fase invalida => 1 error
PRINT '--- F-3.11.107 evento.criterio_suspension_modificar: Fase invalida';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'preliminar', NULL, 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.108 evento.criterio_suspension_modificar: Fase vacia (vacio no es NULL: es invalida) => 1 error
PRINT '--- F-3.11.108 evento.criterio_suspension_modificar: Fase vacia (vacio no es NULL: es invalida)';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 80, 1, '', NULL, 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.109 evento.criterio_suspension_modificar: Tipo de persona invalido => 1 error
PRINT '--- F-3.11.109 evento.criterio_suspension_modificar: Tipo de persona invalido';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'grupos', 'arbitro', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.110 evento.criterio_suspension_modificar: Cantidad de amarillas nula => 1 error
PRINT '--- F-3.11.110 evento.criterio_suspension_modificar: Cantidad de amarillas nula';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, NULL, 1, 'grupos', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.111 evento.criterio_suspension_modificar: Cantidad de amarillas 0 (borde) => 1 error
PRINT '--- F-3.11.111 evento.criterio_suspension_modificar: Cantidad de amarillas 0 (borde)';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 0, 1, 'grupos', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.112 evento.criterio_suspension_modificar: Cantidad de amarillas negativa => 1 error
PRINT '--- F-3.11.112 evento.criterio_suspension_modificar: Cantidad de amarillas negativa';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, -1, 1, 'grupos', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.113 evento.criterio_suspension_modificar: Partidos de suspension nulos => 1 error
PRINT '--- F-3.11.113 evento.criterio_suspension_modificar: Partidos de suspension nulos';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 80, NULL, 'grupos', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.114 evento.criterio_suspension_modificar: Partidos de suspension 0 (borde) => 1 error
PRINT '--- F-3.11.114 evento.criterio_suspension_modificar: Partidos de suspension 0 (borde)';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 80, 0, 'grupos', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.115 evento.criterio_suspension_modificar: Partidos de suspension negativos => 1 error
PRINT '--- F-3.11.115 evento.criterio_suspension_modificar: Partidos de suspension negativos';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 80, -1, 'grupos', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.116 evento.criterio_suspension_modificar: Duplicado de 'dup' (distintos partidos y activo no evitan el duplicado) => 1 error
PRINT '--- F-3.11.116 evento.criterio_suspension_modificar: Duplicado de ''dup'' (distintos partidos y activo no evitan el duplicado)';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 90, 5, 'semifinal', 'jugador', 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.117 evento.criterio_suspension_modificar: id nulo, cantidad y partidos (todo nulo) => 3 errores
PRINT '--- F-3.11.117 evento.criterio_suspension_modificar: 3 errores: id nulo, cantidad y partidos (todo nulo)';
BEGIN TRY EXEC evento.criterio_suspension_modificar NULL, NULL, NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.118 evento.criterio_suspension_modificar: criterio inexistente, fase, tipo, cantidad y partidos => 5 errores
PRINT '--- F-3.11.118 evento.criterio_suspension_modificar: 5 errores: criterio inexistente, fase, tipo, cantidad y partidos';
BEGIN TRY EXEC evento.criterio_suspension_modificar 999999, 0, 0, 'preliminar', 'arbitro', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.119 evento.criterio_suspension_modificar: partidos y duplicado de 'dup' => 2 errores
PRINT '--- F-3.11.119 evento.criterio_suspension_modificar: 2 errores: partidos y duplicado de ''dup''';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 90, 0, 'semifinal', 'jugador', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.120 evento.criterio_suspension_modificar: fase, tipo, partidos y duplicado de 'base_null' => 4 errores
PRINT '--- F-3.11.120 evento.criterio_suspension_modificar: 4 errores: fase, tipo, partidos y duplicado de ''base_null''';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 90, 0, '', '', 1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.criterio_suspension_eliminar: F-3.11.121 a F-3.11.123
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.121 evento.criterio_suspension_eliminar: Criterio inexistente (ya dado de baja) => 1 error (antes, la baja válida, que se deshace al final)
PRINT '--- F-3.11.121 evento.criterio_suspension_eliminar: Criterio inexistente (ya dado de baja)';
DECLARE @ce  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'elim');
BEGIN TRAN;
BEGIN TRY
    EXEC evento.criterio_suspension_eliminar @ce;
    EXEC evento.criterio_suspension_eliminar @ce;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.11.122 evento.criterio_suspension_eliminar: Criterio inexistente => 1 error
PRINT '--- F-3.11.122 evento.criterio_suspension_eliminar: Criterio inexistente';
BEGIN TRY EXEC evento.criterio_suspension_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.123 evento.criterio_suspension_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.11.123 evento.criterio_suspension_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC evento.criterio_suspension_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

PRINT '--- P-3.17 Preparación de evento.suspension_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere las preparaciones de plantel.formacion_* (partido 'jug', anterior), evento.tarjeta_* (partido pt_tar) y
-- evento.criterio_suspension_* (criterio 'usado'). Crea tres integrantes del cuerpo técnico de ZCA con tarjetas en pt_tar,
-- una selección rival (ZDA) y cuatro partidos posteriores; el partido 'fin' queda finalizado.
IF OBJECT_ID('prueba.test_suspension', 'U') IS NULL
    CREATE TABLE prueba.test_suspension (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY, id INT NOT NULL);
GO
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @pant INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @cu INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'usado'),
        @sede INT = (SELECT TOP 1 sede_id FROM torneo.sede ORDER BY sede_id),
        @huso CHAR(6), @off INT, @base DATETIME2, @t DATETIMEOFFSET,
        @pr INT, @sr INT, @pa1 INT, @pa2 INT, @pb INT, @pf INT, @x INT,
        @ctr INT, @cta INT, @ctm INT, @tr INT, @ta INT, @tm INT, @id INT;
SELECT @huso = huso_horario FROM torneo.sede WHERE sede_id = @sede;
SET @off = CAST(SUBSTRING(@huso, 4, 3) AS INT) * 60;
SET @base = DATEADD(DAY, 3, (SELECT MAX(CAST(fecha_hora_local AS DATETIME2)) FROM torneo.partido
                             WHERE seleccion_local_id IN (@s1, @s2, @s3) OR seleccion_visitante_id IN (@s1, @s2, @s3)));
EXEC torneo.pais_insertar 'ZDA', 'Test Susp Rival', 'UTC-03', 0, @pr OUTPUT;
EXEC torneo.seleccion_insertar @pr, @conf, 'A', @sr OUTPUT;
SET @t = TODATETIMEOFFSET(@base, @off);                  EXEC torneo.partido_insertar @sede, @t, 'grupos',    @s1, @sr, @partido_id = @pa1 OUTPUT;  -- afectado principal
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 3, @base), @off); EXEC torneo.partido_insertar @sede, @t, 'octavos',   @sr, @s1, @partido_id = @pa2 OUTPUT;  -- afectado alternativo
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 6, @base), @off); EXEC torneo.partido_insertar @sede, @t, 'cuartos',   @s2, @sr, @partido_id = @pb  OUTPUT;  -- ZCA no lo juega
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 9, @base), @off); EXEC torneo.partido_insertar @sede, @t, 'semifinal', @s1, @sr, @partido_id = @pf  OUTPUT;  -- se finaliza al final
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test SU', 'CT Roja',     'otro', @x OUTPUT, @ctr OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test SU', 'CT Amarilla', 'otro', @x OUTPUT, @cta OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test SU', 'CT Mod',      'otro', @x OUTPUT, @ctm OUTPUT;
EXEC evento.tarjeta_insertar @pt, @ctr, 60, 'ST', 'roja',     'Insultos', 'roja_directa', @tarjeta_id = @tr OUTPUT;
EXEC evento.tarjeta_insertar @pt, @cta, 61, 'ST', 'amarilla', 'Protesta', NULL,           @tarjeta_id = @ta OUTPUT;
EXEC evento.tarjeta_insertar @pt, @ctm, 62, 'ST', 'roja',     'Insultos', 'roja_directa', @tarjeta_id = @tm OUTPUT;
INSERT INTO prueba.test_suspension (clave, id) VALUES
 ('pa1', @pa1), ('pa2', @pa2), ('pb', @pb), ('pf', @pf), ('pant', @pant), ('t_roja', @tr), ('t_amar', @ta), ('t_mod', @tm);
EXEC evento.suspension_insertar @tm, 'Roja directa', NULL, @pa1, @id OUTPUT;                 INSERT INTO prueba.test_suspension VALUES ('mod',  @id);  -- a modificar
EXEC evento.suspension_insertar @tm, 'Roja directa (segunda fecha)', NULL, @pa2, @id OUTPUT; INSERT INTO prueba.test_suspension VALUES ('otra', @id);  -- destino de duplicados
EXEC evento.suspension_insertar @tr, 'Roja directa', NULL, @pa2, @id OUTPUT;                 INSERT INTO prueba.test_suspension VALUES ('elim', @id);  -- baja válida
EXEC evento.suspension_insertar @tm, 'Roja directa (cumplida)', NULL, @pf, @id OUTPUT;       INSERT INTO prueba.test_suspension VALUES ('fin',  @id);  -- partido finalizado
EXEC evento.suspension_insertar @ta, 'Acumulacion de amarillas', @cu, @pa2, @id OUTPUT;     INSERT INTO prueba.test_suspension VALUES ('crit', @id);  -- usa el criterio 'usado'
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pf;
GO

-- -------------------------------------------------------------------------------------
-- evento.criterio_suspension_eliminar: F-3.11.124
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.124 evento.criterio_suspension_eliminar: Ya origino suspensiones (criterio 'usado') => 1 error
PRINT '--- F-3.11.124 evento.criterio_suspension_eliminar: Ya origino suspensiones (criterio ''usado'')';
DECLARE @cu INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'usado');
BEGIN TRY EXEC evento.criterio_suspension_eliminar @cu; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.suspension_insertar: F-3.11.125 a F-3.11.140
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.125 evento.suspension_insertar: Tarjeta inexistente => 1 error
PRINT '--- F-3.11.125 evento.suspension_insertar: Tarjeta inexistente';
DECLARE @id INT,
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_insertar 999999, 'Motivo', NULL, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.126 evento.suspension_insertar: Tarjeta nula => 1 error
PRINT '--- F-3.11.126 evento.suspension_insertar: Tarjeta nula';
DECLARE @id INT,
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_insertar NULL, 'Motivo', NULL, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.127 evento.suspension_insertar: Criterio inexistente => 1 error
PRINT '--- F-3.11.127 evento.suspension_insertar: Criterio inexistente';
DECLARE @id INT,
        @ta INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_amar'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_insertar @ta, 'Motivo', 999999, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.128 evento.suspension_insertar: Amarilla sin criterio de acumulacion => 1 error
PRINT '--- F-3.11.128 evento.suspension_insertar: Amarilla sin criterio de acumulacion';
DECLARE @id INT,
        @ta INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_amar'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_insertar @ta, 'Motivo', NULL, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.129 evento.suspension_insertar: Expulsion con criterio de acumulacion => 1 error
PRINT '--- F-3.11.129 evento.suspension_insertar: Expulsion con criterio de acumulacion';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1'),
        @cu INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'usado');
BEGIN TRY EXEC evento.suspension_insertar @tr, 'Motivo', @cu, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.130 evento.suspension_insertar: Motivo nulo => 1 error
PRINT '--- F-3.11.130 evento.suspension_insertar: Motivo nulo';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_insertar @tr, NULL, NULL, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.131 evento.suspension_insertar: Motivo vacio => 1 error
PRINT '--- F-3.11.131 evento.suspension_insertar: Motivo vacio';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_insertar @tr, '', NULL, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.132 evento.suspension_insertar: Motivo solo espacios => 1 error
PRINT '--- F-3.11.132 evento.suspension_insertar: Motivo solo espacios';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_insertar @tr, '   ', NULL, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.133 evento.suspension_insertar: Partido afectado inexistente => 1 error
PRINT '--- F-3.11.133 evento.suspension_insertar: Partido afectado inexistente';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja');
BEGIN TRY EXEC evento.suspension_insertar @tr, 'Motivo', NULL, 999999, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.134 evento.suspension_insertar: La seleccion de la persona no juega el partido afectado => 1 error
PRINT '--- F-3.11.134 evento.suspension_insertar: La seleccion de la persona no juega el partido afectado';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja'),
        @pb INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pb');
BEGIN TRY EXEC evento.suspension_insertar @tr, 'Motivo', NULL, @pb, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.135 evento.suspension_insertar: Partido afectado anterior al de la tarjeta => 1 error
PRINT '--- F-3.11.135 evento.suspension_insertar: Partido afectado anterior al de la tarjeta';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja'),
        @pant INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pant');
BEGIN TRY EXEC evento.suspension_insertar @tr, 'Motivo', NULL, @pant, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.136 evento.suspension_insertar: La persona ya tiene una suspension para ese partido => 1 error
PRINT '--- F-3.11.136 evento.suspension_insertar: La persona ya tiene una suspension para ese partido';
DECLARE @id INT,
        @tm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_mod'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_insertar @tm, 'Motivo', NULL, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.137 evento.suspension_insertar: tarjeta, criterio, motivo y partido inexistente => 4 errores
PRINT '--- F-3.11.137 evento.suspension_insertar: 4 errores: tarjeta, criterio, motivo y partido inexistente';
DECLARE @id INT;
BEGIN TRY EXEC evento.suspension_insertar 999999, '', 999999, 999999, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.138 evento.suspension_insertar: amarilla sin criterio, motivo y seleccion que no juega => 3 errores
PRINT '--- F-3.11.138 evento.suspension_insertar: 3 errores: amarilla sin criterio, motivo y seleccion que no juega';
DECLARE @id INT,
        @ta INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_amar'),
        @pb INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pb');
BEGIN TRY EXEC evento.suspension_insertar @ta, '', NULL, @pb, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.139 evento.suspension_insertar: expulsion con criterio, motivo y partido anterior => 3 errores
PRINT '--- F-3.11.139 evento.suspension_insertar: 3 errores: expulsion con criterio, motivo y partido anterior';
DECLARE @id INT,
        @tm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_mod'),
        @pant INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pant'),
        @cu INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'usado');
BEGIN TRY EXEC evento.suspension_insertar @tm, '  ', @cu, @pant, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.140 evento.suspension_insertar: expulsion con criterio, motivo y suspension duplicada => 3 errores
PRINT '--- F-3.11.140 evento.suspension_insertar: 3 errores: expulsion con criterio, motivo y suspension duplicada';
DECLARE @id INT,
        @tm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_mod'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1'),
        @cu INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'usado');
BEGIN TRY EXEC evento.suspension_insertar @tm, '', @cu, @pa1, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.suspension_modificar: F-3.11.141 a F-3.11.151
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.141 evento.suspension_modificar: Suspension inexistente => 1 error
PRINT '--- F-3.11.141 evento.suspension_modificar: Suspension inexistente';
DECLARE @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_modificar 999999, 'Motivo', @pa1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.142 evento.suspension_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.11.142 evento.suspension_modificar: Id nulo (el mensaje dice "(nulo)")';
DECLARE @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_modificar NULL, 'Motivo', @pa1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.143 evento.suspension_modificar: Motivo nulo => 1 error
PRINT '--- F-3.11.143 evento.suspension_modificar: Motivo nulo';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_modificar @sm, NULL, @pa1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.144 evento.suspension_modificar: Motivo vacio => 1 error
PRINT '--- F-3.11.144 evento.suspension_modificar: Motivo vacio';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_modificar @sm, '', @pa1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.145 evento.suspension_modificar: Motivo solo espacios => 1 error
PRINT '--- F-3.11.145 evento.suspension_modificar: Motivo solo espacios';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
BEGIN TRY EXEC evento.suspension_modificar @sm, '   ', @pa1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.146 evento.suspension_modificar: Partido afectado inexistente => 1 error
PRINT '--- F-3.11.146 evento.suspension_modificar: Partido afectado inexistente';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod');
BEGIN TRY EXEC evento.suspension_modificar @sm, 'Motivo', 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.147 evento.suspension_modificar: La seleccion de la persona no juega el partido afectado => 1 error
PRINT '--- F-3.11.147 evento.suspension_modificar: La seleccion de la persona no juega el partido afectado';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pb INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pb');
BEGIN TRY EXEC evento.suspension_modificar @sm, 'Motivo', @pb; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.148 evento.suspension_modificar: Partido afectado anterior al de la tarjeta => 1 error
PRINT '--- F-3.11.148 evento.suspension_modificar: Partido afectado anterior al de la tarjeta';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pant INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pant');
BEGIN TRY EXEC evento.suspension_modificar @sm, 'Motivo', @pant; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.149 evento.suspension_modificar: La persona ya tiene otra suspension para ese partido => 1 error
PRINT '--- F-3.11.149 evento.suspension_modificar: La persona ya tiene otra suspension para ese partido';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pa2 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa2');
BEGIN TRY EXEC evento.suspension_modificar @sm, 'Motivo', @pa2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.150 evento.suspension_modificar: motivo y suspension duplicada => 2 errores
PRINT '--- F-3.11.150 evento.suspension_modificar: 2 errores: motivo y suspension duplicada';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pa2 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa2');
BEGIN TRY EXEC evento.suspension_modificar @sm, '', @pa2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.151 evento.suspension_modificar: suspension inexistente, motivo y partido afectado inexistente (se validan los datos aunque no exista) => 3 errores
PRINT '--- F-3.11.151 evento.suspension_modificar: 3 errores: suspension inexistente, motivo y partido afectado inexistente (se validan los datos aunque no exista)';
BEGIN TRY EXEC evento.suspension_modificar 999999, '', 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.suspension_eliminar: F-3.11.152 a F-3.11.155
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.152 evento.suspension_eliminar: Suspension inexistente (el caso la da de baja antes) => 1 error
PRINT '--- F-3.11.152 evento.suspension_eliminar: Suspension inexistente (el caso la da de baja antes)';
DECLARE @se INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'elim');
BEGIN TRY EXEC evento.suspension_eliminar @se; EXEC evento.suspension_eliminar @se; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.153 evento.suspension_eliminar: Suspension inexistente => 1 error
PRINT '--- F-3.11.153 evento.suspension_eliminar: Suspension inexistente';
BEGIN TRY EXEC evento.suspension_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.154 evento.suspension_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.11.154 evento.suspension_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC evento.suspension_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.155 evento.suspension_eliminar: La suspension ya se cumplio (partido afectado finalizado) => 1 error
PRINT '--- F-3.11.155 evento.suspension_eliminar: La suspension ya se cumplio (partido afectado finalizado)';
DECLARE @sf INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'fin');
BEGIN TRY EXEC evento.suspension_eliminar @sf; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.registrar_sustitucion: F-3.11.156 a F-3.11.157
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.156 evento.registrar_sustitucion: dorsal que sale, dorsal que entra y motivo => 3 errores
PRINT '--- F-3.11.156 evento.registrar_sustitucion: 3 errores: dorsal que sale, dorsal que entra y motivo';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3');
BEGIN TRY EXEC evento.registrar_sustitucion @p3, 'local', 77, 88, 50, 'ST', 'cansancio'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.157 evento.registrar_sustitucion: equipo sin formacion, periodo y minuto => 3 errores
PRINT '--- F-3.11.157 evento.registrar_sustitucion: 3 errores: equipo sin formacion, periodo y minuto';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3');
BEGIN TRY EXEC evento.registrar_sustitucion @p3, 'neutral', 3, 13, NULL, 'alargue_9', 'tactico'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.registrar_gol: F-3.11.158
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.158 evento.registrar_gol: dorsal del autor, tipo de gol y minuto fuera del periodo => 3 errores
PRINT '--- F-3.11.158 evento.registrar_gol: 3 errores: dorsal del autor, tipo de gol y minuto fuera del periodo';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3');
BEGIN TRY EXEC evento.registrar_gol @p3, 'local', 77, 200, 'chilena', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- evento.registrar_tarjeta: F-3.11.159
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.159 evento.registrar_tarjeta: persona no identificada, periodo, minuto y tipo => 4 errores
PRINT '--- F-3.11.159 evento.registrar_tarjeta: 4 errores: persona no identificada, periodo, minuto y tipo';
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3');
BEGIN TRY EXEC evento.registrar_tarjeta @partido_id = @p3, @minuto = NULL, @periodo = 'XX', @tipo = 'verde', @condicion = 'local', @dorsal = 77; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- modificar un registro inexistente informa tambien los errores de los datos: F-3.11.160 a F-3.11.164
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- F-3.11.160 modificar un registro inexistente informa tambien los errores de los datos: convocatoria inexistente, dorsal y fecha de alta => 3 errores
PRINT '--- F-3.11.160 modificar un registro inexistente informa tambien los errores de los datos: 3 errores: convocatoria inexistente, dorsal y fecha de alta';
BEGIN TRY EXEC plantel.convocatoria_modificar 999999, 150, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.161 modificar un registro inexistente informa tambien los errores de los datos: sustitucion inexistente, minuto, ventana y motivo => 4 errores
PRINT '--- F-3.11.161 modificar un registro inexistente informa tambien los errores de los datos: 4 errores: sustitucion inexistente, minuto, ventana y motivo';
BEGIN TRY EXEC evento.sustitucion_modificar 999999, 200, 'PT', 0, 'otro'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.162 modificar un registro inexistente informa tambien los errores de los datos: gol inexistente y tipo de gol => 2 errores
PRINT '--- F-3.11.162 modificar un registro inexistente informa tambien los errores de los datos: 2 errores: gol inexistente y tipo de gol';
BEGIN TRY EXEC evento.gol_modificar 999999, 10, 'chilena', 'PT'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.163 modificar un registro inexistente informa tambien los errores de los datos: tarjeta nula, periodo y minuto => 3 errores
PRINT '--- F-3.11.163 modificar un registro inexistente informa tambien los errores de los datos: 3 errores: tarjeta nula, periodo y minuto';
BEGIN TRY EXEC evento.tarjeta_modificar NULL, NULL, 'XX'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.11.164 modificar un registro inexistente informa tambien los errores de los datos: designacion, arbitro y rol => 3 errores
PRINT '--- F-3.11.164 modificar un registro inexistente informa tambien los errores de los datos: 3 errores: designacion, arbitro y rol';
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar 999999, 999999, 'linea'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.12 arbitraje: arbitro, arbitro_idioma, designacion_arbitral e informe_arbitral
-- ============================================================

PRINT '--- P-3.18 Preparación de arbitraje.* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- No requiere otras preparaciones. Países ZAA/ZAB sin selección (árbitros) y ZAL, ZAV, ZAX, ZAY con selección;
-- partidos en 2031: pg (ZAL vs ZAV, grupos), pc (ZAX vs ZAY, 3 horas después), pfin (cuartos, se finaliza) y
-- pd (dieciseisavos). Designaciones e informes de base en pg, pc y pfin.
IF OBJECT_ID('prueba.test_arbitraje', 'U') IS NULL
    CREATE TABLE prueba.test_arbitraje (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY, id INT NOT NULL);
GO
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pa INT, @pb INT, @pl INT, @pv INT, @px INT, @py INT, @sl INT, @sv INT, @sx INT, @sy INT,
        @sede1 INT, @sede2 INT, @pg INT, @pc INT, @pd INT, @pfin INT, @id INT, @d INT;
EXEC torneo.pais_insertar 'ZAA', 'Test Arb Pais A',    'UTC-03', 0, @pa OUTPUT;
EXEC torneo.pais_insertar 'ZAB', 'Test Arb Pais B',    'UTC-03', 0, @pb OUTPUT;
EXEC torneo.pais_insertar 'ZAL', 'Test Arb Local',     'UTC-03', 0, @pl OUTPUT;
EXEC torneo.pais_insertar 'ZAV', 'Test Arb Visitante', 'UTC-03', 0, @pv OUTPUT;
EXEC torneo.pais_insertar 'ZAX', 'Test Arb X',         'UTC-03', 0, @px OUTPUT;
EXEC torneo.pais_insertar 'ZAY', 'Test Arb Y',         'UTC-03', 0, @py OUTPUT;
EXEC torneo.seleccion_insertar @pl, @conf, 'K', @sl OUTPUT;
EXEC torneo.seleccion_insertar @pv, @conf, 'K', @sv OUTPUT;
EXEC torneo.seleccion_insertar @px, @conf, 'L', @sx OUTPUT;
EXEC torneo.seleccion_insertar @py, @conf, 'L', @sy OUTPUT;
EXEC torneo.sede_insertar 'Test Arb Sede 1', 'Ciudad Arb', @pa, 50000, 'UTC-03', @sede1 OUTPUT;
EXEC torneo.sede_insertar 'Test Arb Sede 2', 'Ciudad Arb', @pa, 50000, 'UTC-03', @sede2 OUTPUT;
EXEC torneo.partido_insertar @sede1, '2031-01-10 15:00:00 -03:00', 'grupos',        @sl, @sv, NULL, @pg   OUTPUT;
EXEC torneo.partido_insertar @sede2, '2031-01-10 18:00:00 -03:00', 'grupos',        @sx, @sy, NULL, @pc   OUTPUT;
EXEC torneo.partido_insertar @sede1, '2031-01-30 15:00:00 -03:00', 'cuartos',       @sl, @sv, NULL, @pfin OUTPUT;
EXEC torneo.partido_insertar @sede1, '2031-02-10 15:00:00 -03:00', 'dieciseisavos', @sl, @sv, NULL, @pd   OUTPUT;
INSERT INTO prueba.test_arbitraje (clave, id) VALUES ('pg', @pg), ('pc', @pc), ('pfin', @pfin), ('pd', @pd);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Base',      @pa, 'FIFA', '1985-05-10', @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_base', @id);   -- designado en pg y pfin
EXEC arbitraje.arbitro_idioma_insertar @id, 'espanol';
EXEC arbitraje.arbitro_idioma_insertar @id, 'ingles';
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Mod',       @pa, 'confederacion', '1980-01-01', @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_mod', @id);
EXEC arbitraje.arbitro_idioma_insertar @id, 'aleman';
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Otro',      @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_otro', @id);    -- destino de duplicados
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Elim',      @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_elim', @id);    -- baja válida (con un idioma)
EXEC arbitraje.arbitro_idioma_insertar @id, 'italiano';
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Conflicto', @pl, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_conf', @id);    -- país de una selección de pg
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Libre',     @pb, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_libre', @id);   -- sin designaciones
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Libre Dos', @pb, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_libre2', @id);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Adv',       @px, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_adv', @id);     -- país con selección en competencia
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Inf',       @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_inf', @id);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'DMod',      @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_dmod', @id);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'DElim',     @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_delim', @id);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'PC',        @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('a_pc', @id);
DECLARE @a_base INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base'),
        @a_inf INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_inf'),
        @a_dmod INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_dmod'),
        @a_delim INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_delim'),
        @a_pc INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_pc');
EXEC arbitraje.designacion_arbitral_insertar @pg,   @a_base,  'principal',   @d OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('d_base', @d);
EXEC arbitraje.designacion_arbitral_insertar @pg,   @a_inf,   'asistente_1', @d OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('d_inf', @d);    -- con informes
EXEC arbitraje.designacion_arbitral_insertar @pg,   @a_dmod,  'cuarto',      @d OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('d_mod', @d);    -- a modificar
EXEC arbitraje.designacion_arbitral_insertar @pg,   @a_delim, 'var',         @d OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('d_elim', @d);   -- baja válida
EXEC arbitraje.designacion_arbitral_insertar @pc,   @a_pc,    'principal',   @d OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('d_pc', @d);
EXEC arbitraje.designacion_arbitral_insertar @pfin, @a_base,  'principal',   @d OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('d_fin', @d);    -- finalizado, con informe
EXEC arbitraje.informe_arbitral_insertar @d, '2031-01-30 20:00:00 +00:00', 'Informe del partido finalizado', NULL, @id OUTPUT;
EXEC arbitraje.designacion_arbitral_insertar @pfin, @a_dmod,  'var',         @d OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('d_fin2', @d);   -- finalizado, sin informe
SET @d = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_inf');
EXEC arbitraje.informe_arbitral_insertar @d, '2031-01-10 20:00:00 +00:00', 'Informe base', NULL, @id OUTPUT;       INSERT INTO prueba.test_arbitraje VALUES ('i_base', @id);
EXEC arbitraje.informe_arbitral_insertar @d, '2031-01-10 21:00:00 +00:00', 'Informe a eliminar', NULL, @id OUTPUT; INSERT INTO prueba.test_arbitraje VALUES ('i_elim', @id);
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pfin;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.arbitro_insertar: F-3.12.01 a F-3.12.21
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.01 arbitraje.arbitro_insertar: Nombre nulo => 1 error
PRINT '--- F-3.12.01 arbitraje.arbitro_insertar: Nombre nulo';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar NULL, 'Alta X', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.02 arbitraje.arbitro_insertar: Nombre vacio => 1 error
PRINT '--- F-3.12.02 arbitraje.arbitro_insertar: Nombre vacio';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar '', 'Alta X', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.03 arbitraje.arbitro_insertar: Nombre solo espacios => 1 error
PRINT '--- F-3.12.03 arbitraje.arbitro_insertar: Nombre solo espacios';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar '   ', 'Alta X', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.04 arbitraje.arbitro_insertar: Apellido nulo => 1 error
PRINT '--- F-3.12.04 arbitraje.arbitro_insertar: Apellido nulo';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', NULL, @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.05 arbitraje.arbitro_insertar: Apellido vacio => 1 error
PRINT '--- F-3.12.05 arbitraje.arbitro_insertar: Apellido vacio';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', '', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.06 arbitraje.arbitro_insertar: Apellido solo espacios => 1 error
PRINT '--- F-3.12.06 arbitraje.arbitro_insertar: Apellido solo espacios';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', '   ', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.07 arbitraje.arbitro_insertar: Menor de 18 anios (borde: un dia menos) => 1 error
PRINT '--- F-3.12.07 arbitraje.arbitro_insertar: Menor de 18 anios (borde: un dia menos)';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @f18_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -18, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta X', @pa, 'FIFA', @f18_menos, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.08 arbitraje.arbitro_insertar: Mayor de 70 anios (borde: un dia mas) => 1 error
PRINT '--- F-3.12.08 arbitraje.arbitro_insertar: Mayor de 70 anios (borde: un dia mas)';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @f70_mas DATE = DATEADD(DAY, -1, DATEADD(YEAR, -70, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta X', @pa, 'FIFA', @f70_mas, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.09 arbitraje.arbitro_insertar: Fecha de nacimiento futura => 1 error
PRINT '--- F-3.12.09 arbitraje.arbitro_insertar: Fecha de nacimiento futura';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta X', @pa, 'FIFA', '2999-01-01', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.10 arbitraje.arbitro_insertar: Pais inexistente => 1 error
PRINT '--- F-3.12.10 arbitraje.arbitro_insertar: Pais inexistente';
DECLARE @id INT;
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta X', 999999, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.11 arbitraje.arbitro_insertar: Pais nulo => 1 error
PRINT '--- F-3.12.11 arbitraje.arbitro_insertar: Pais nulo';
DECLARE @id INT;
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta X', NULL, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.12 arbitraje.arbitro_insertar: Categoria invalida => 1 error
PRINT '--- F-3.12.12 arbitraje.arbitro_insertar: Categoria invalida';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta X', @pa, 'regional', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.13 arbitraje.arbitro_insertar: Categoria incompleta => 1 error
PRINT '--- F-3.12.13 arbitraje.arbitro_insertar: Categoria incompleta';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta X', @pa, 'FIF', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.14 arbitraje.arbitro_insertar: Categoria nula => 1 error
PRINT '--- F-3.12.14 arbitraje.arbitro_insertar: Categoria nula';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta X', @pa, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.15 arbitraje.arbitro_insertar: Duplicado: mismo nombre, apellido y pais que la base => 1 error
PRINT '--- F-3.12.15 arbitraje.arbitro_insertar: Duplicado: mismo nombre, apellido y pais que la base';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Base', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.16 arbitraje.arbitro_insertar: Duplicado con otra capitalizacion => 1 error
PRINT '--- F-3.12.16 arbitraje.arbitro_insertar: Duplicado con otra capitalizacion';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'TEST ARB', 'BASE', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.17 arbitraje.arbitro_insertar: Duplicado con espacios al final => 1 error
PRINT '--- F-3.12.17 arbitraje.arbitro_insertar: Duplicado con espacios al final';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb ', 'Base ', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.18 arbitraje.arbitro_insertar: Duplicado con espacios al inicio => 1 error
PRINT '--- F-3.12.18 arbitraje.arbitro_insertar: Duplicado con espacios al inicio';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar '  Test Arb', '  Base', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.19 arbitraje.arbitro_insertar: nombre y apellido => 2 errores
PRINT '--- F-3.12.19 arbitraje.arbitro_insertar: 2 errores: nombre y apellido';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_insertar '', '', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.20 arbitraje.arbitro_insertar: nombre, apellido, pais y categoria => 4 errores
PRINT '--- F-3.12.20 arbitraje.arbitro_insertar: 4 errores: nombre, apellido, pais y categoria';
DECLARE @id INT;
BEGIN TRY EXEC arbitraje.arbitro_insertar NULL, NULL, NULL, NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.21 arbitraje.arbitro_insertar: 5 errores (maximo): nombre, apellido, edad, pais y categoria => 5 errores
PRINT '--- F-3.12.21 arbitraje.arbitro_insertar: 5 errores (maximo): nombre, apellido, edad, pais y categoria';
DECLARE @id INT,
        @f18_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -18, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC arbitraje.arbitro_insertar '', '', 999999, 'regional', @f18_menos, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.arbitro_modificar: F-3.12.22 a F-3.12.37
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.22 arbitraje.arbitro_modificar: Id nulo => 1 error
PRINT '--- F-3.12.22 arbitraje.arbitro_modificar: Id nulo';
DECLARE @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_modificar NULL, 'Test Arb', 'Inexistente', @pa, 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.23 arbitraje.arbitro_modificar: Arbitro inexistente => 1 error
PRINT '--- F-3.12.23 arbitraje.arbitro_modificar: Arbitro inexistente';
DECLARE @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_modificar 999999, 'Test Arb', 'Inexistente', @pa, 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.24 arbitraje.arbitro_modificar: Nombre nulo => 1 error
PRINT '--- F-3.12.24 arbitraje.arbitro_modificar: Nombre nulo';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, NULL, 'Mod', @pa, 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.25 arbitraje.arbitro_modificar: Nombre solo espacios => 1 error
PRINT '--- F-3.12.25 arbitraje.arbitro_modificar: Nombre solo espacios';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, '   ', 'Mod', @pa, 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.26 arbitraje.arbitro_modificar: Apellido vacio => 1 error
PRINT '--- F-3.12.26 arbitraje.arbitro_modificar: Apellido vacio';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', '', @pa, 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.27 arbitraje.arbitro_modificar: Menor de 18 anios (borde: un dia menos) => 1 error
PRINT '--- F-3.12.27 arbitraje.arbitro_modificar: Menor de 18 anios (borde: un dia menos)';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @f18_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -18, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pa, 'FIFA', @f18_menos; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.28 arbitraje.arbitro_modificar: Mayor de 70 anios (borde: un dia mas) => 1 error
PRINT '--- F-3.12.28 arbitraje.arbitro_modificar: Mayor de 70 anios (borde: un dia mas)';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @f70_mas DATE = DATEADD(DAY, -1, DATEADD(YEAR, -70, CAST(SYSDATETIME() AS DATE)));
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pa, 'FIFA', @f70_mas; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.29 arbitraje.arbitro_modificar: Pais inexistente => 1 error
PRINT '--- F-3.12.29 arbitraje.arbitro_modificar: Pais inexistente';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', 999999, 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.30 arbitraje.arbitro_modificar: Pais nulo => 1 error
PRINT '--- F-3.12.30 arbitraje.arbitro_modificar: Pais nulo';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', NULL, 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.31 arbitraje.arbitro_modificar: Categoria invalida => 1 error
PRINT '--- F-3.12.31 arbitraje.arbitro_modificar: Categoria invalida';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pa, 'regional'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.32 arbitraje.arbitro_modificar: Categoria nula => 1 error
PRINT '--- F-3.12.32 arbitraje.arbitro_modificar: Categoria nula';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pa, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.33 arbitraje.arbitro_modificar: Duplicado: nombre, apellido y pais de otro arbitro => 1 error
PRINT '--- F-3.12.33 arbitraje.arbitro_modificar: Duplicado: nombre, apellido y pais de otro arbitro';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Otro', @pa, 'FIFA'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.34 arbitraje.arbitro_modificar: El nuevo pais coincide con una seleccion de un partido en el que esta designado => 1 error
PRINT '--- F-3.12.34 arbitraje.arbitro_modificar: El nuevo pais coincide con una seleccion de un partido en el que esta designado';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base'),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAL');
BEGIN TRY EXEC arbitraje.arbitro_modificar @b, 'Test Arb', 'Base', @pl, 'FIFA', '1985-05-10'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.35 arbitraje.arbitro_modificar: categoria y pais en conflicto con una designacion => 2 errores
PRINT '--- F-3.12.35 arbitraje.arbitro_modificar: 2 errores: categoria y pais en conflicto con una designacion';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base'),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAL');
BEGIN TRY EXEC arbitraje.arbitro_modificar @b, 'Test Arb', 'Base', @pl, 'regional', '1985-05-10'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.36 arbitraje.arbitro_modificar: arbitro, nombre, apellido, pais y categoria => 5 errores
PRINT '--- F-3.12.36 arbitraje.arbitro_modificar: 5 errores: arbitro, nombre, apellido, pais y categoria';
BEGIN TRY EXEC arbitraje.arbitro_modificar 999999, '', '', 999999, 'regional'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.37 arbitraje.arbitro_modificar: id, nombre, apellido, pais y categoria (todo nulo) => 5 errores
PRINT '--- F-3.12.37 arbitraje.arbitro_modificar: 5 errores: id, nombre, apellido, pais y categoria (todo nulo)';
BEGIN TRY EXEC arbitraje.arbitro_modificar NULL, NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.arbitro_eliminar: F-3.12.38 a F-3.12.41
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.38 arbitraje.arbitro_eliminar: Arbitro inexistente (el caso lo da de baja antes) => 1 error
PRINT '--- F-3.12.38 arbitraje.arbitro_eliminar: Arbitro inexistente (el caso lo da de baja antes)';
DECLARE @e INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_elim');
BEGIN TRY EXEC arbitraje.arbitro_eliminar @e; EXEC arbitraje.arbitro_eliminar @e; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.39 arbitraje.arbitro_eliminar: Arbitro inexistente => 1 error
PRINT '--- F-3.12.39 arbitraje.arbitro_eliminar: Arbitro inexistente';
BEGIN TRY EXEC arbitraje.arbitro_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.40 arbitraje.arbitro_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.12.40 arbitraje.arbitro_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC arbitraje.arbitro_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.41 arbitraje.arbitro_eliminar: Tiene designaciones en partidos => 1 error
PRINT '--- F-3.12.41 arbitraje.arbitro_eliminar: Tiene designaciones en partidos';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_eliminar @b; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.arbitro_idioma_insertar: F-3.12.42 a F-3.12.52
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.42 arbitraje.arbitro_idioma_insertar: Idioma de 11 letras (mas de 10) => 1 error
PRINT '--- F-3.12.42 arbitraje.arbitro_idioma_insertar: Idioma de 11 letras (mas de 10)';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, 'portuguesas'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.43 arbitraje.arbitro_idioma_insertar: Idioma con espacio => 1 error
PRINT '--- F-3.12.43 arbitraje.arbitro_idioma_insertar: Idioma con espacio';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, 'ingles uk'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.44 arbitraje.arbitro_idioma_insertar: Idioma con numero => 1 error
PRINT '--- F-3.12.44 arbitraje.arbitro_idioma_insertar: Idioma con numero';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, 'ingles2'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.45 arbitraje.arbitro_idioma_insertar: Idioma nulo => 1 error
PRINT '--- F-3.12.45 arbitraje.arbitro_idioma_insertar: Idioma nulo';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.46 arbitraje.arbitro_idioma_insertar: Idioma vacio => 1 error
PRINT '--- F-3.12.46 arbitraje.arbitro_idioma_insertar: Idioma vacio';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.47 arbitraje.arbitro_idioma_insertar: Idioma solo espacios => 1 error
PRINT '--- F-3.12.47 arbitraje.arbitro_idioma_insertar: Idioma solo espacios';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, '   '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.48 arbitraje.arbitro_idioma_insertar: Arbitro inexistente => 1 error
PRINT '--- F-3.12.48 arbitraje.arbitro_idioma_insertar: Arbitro inexistente';
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar 999999, 'ruso'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.49 arbitraje.arbitro_idioma_insertar: Arbitro nulo => 1 error
PRINT '--- F-3.12.49 arbitraje.arbitro_idioma_insertar: Arbitro nulo';
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar NULL, 'ruso'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.50 arbitraje.arbitro_idioma_insertar: Idioma ya registrado para el arbitro => 1 error
PRINT '--- F-3.12.50 arbitraje.arbitro_idioma_insertar: Idioma ya registrado para el arbitro';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @b, 'espanol'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.51 arbitraje.arbitro_idioma_insertar: Idioma ya registrado, con otra capitalizacion => 1 error
PRINT '--- F-3.12.51 arbitraje.arbitro_idioma_insertar: Idioma ya registrado, con otra capitalizacion';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @b, 'ESPANOL'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.52 arbitraje.arbitro_idioma_insertar: arbitro inexistente e idioma vacio => 2 errores
PRINT '--- F-3.12.52 arbitraje.arbitro_idioma_insertar: 2 errores: arbitro inexistente e idioma vacio';
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar 999999, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.arbitro_idioma_modificar: F-3.12.53 a F-3.12.63
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.53 arbitraje.arbitro_idioma_modificar: El arbitro no tiene el idioma a reemplazar => 1 error
PRINT '--- F-3.12.53 arbitraje.arbitro_idioma_modificar: El arbitro no tiene el idioma a reemplazar';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'aleman', 'ruso'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.54 arbitraje.arbitro_idioma_modificar: Arbitro inexistente (no tiene el idioma) => 1 error
PRINT '--- F-3.12.54 arbitraje.arbitro_idioma_modificar: Arbitro inexistente (no tiene el idioma)';
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar 999999, 'ingles', 'ruso'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.55 arbitraje.arbitro_idioma_modificar: Arbitro nulo => 1 error
PRINT '--- F-3.12.55 arbitraje.arbitro_idioma_modificar: Arbitro nulo';
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar NULL, 'ingles', 'ruso'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.56 arbitraje.arbitro_idioma_modificar: Idioma nuevo nulo => 1 error
PRINT '--- F-3.12.56 arbitraje.arbitro_idioma_modificar: Idioma nuevo nulo';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.57 arbitraje.arbitro_idioma_modificar: Idioma nuevo vacio => 1 error
PRINT '--- F-3.12.57 arbitraje.arbitro_idioma_modificar: Idioma nuevo vacio';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.58 arbitraje.arbitro_idioma_modificar: Idioma nuevo de 11 letras => 1 error
PRINT '--- F-3.12.58 arbitraje.arbitro_idioma_modificar: Idioma nuevo de 11 letras';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', 'portuguesas'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.59 arbitraje.arbitro_idioma_modificar: Idioma nuevo con espacio => 1 error
PRINT '--- F-3.12.59 arbitraje.arbitro_idioma_modificar: Idioma nuevo con espacio';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', 'ingles uk'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.60 arbitraje.arbitro_idioma_modificar: El arbitro ya tiene el idioma nuevo => 1 error
PRINT '--- F-3.12.60 arbitraje.arbitro_idioma_modificar: El arbitro ya tiene el idioma nuevo';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', 'espanol'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.61 arbitraje.arbitro_idioma_modificar: Ya tiene el idioma nuevo, con otra capitalizacion => 1 error
PRINT '--- F-3.12.61 arbitraje.arbitro_idioma_modificar: Ya tiene el idioma nuevo, con otra capitalizacion';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', 'ESPANOL'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.62 arbitraje.arbitro_idioma_modificar: idioma a reemplazar y nuevo vacio => 2 errores
PRINT '--- F-3.12.62 arbitraje.arbitro_idioma_modificar: 2 errores: idioma a reemplazar y nuevo vacio';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'aleman', ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.63 arbitraje.arbitro_idioma_modificar: no tiene el idioma a reemplazar y ya tiene el nuevo => 2 errores
PRINT '--- F-3.12.63 arbitraje.arbitro_idioma_modificar: 2 errores: no tiene el idioma a reemplazar y ya tiene el nuevo';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'aleman', 'espanol'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.arbitro_idioma_eliminar: F-3.12.64 a F-3.12.67
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.64 arbitraje.arbitro_idioma_eliminar: Idioma no registrado (el caso lo da de baja antes) => 1 error
PRINT '--- F-3.12.64 arbitraje.arbitro_idioma_eliminar: Idioma no registrado (el caso lo da de baja antes)';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
BEGIN TRY EXEC arbitraje.arbitro_idioma_eliminar @m, 'aleman'; EXEC arbitraje.arbitro_idioma_eliminar @m, 'aleman'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.65 arbitraje.arbitro_idioma_eliminar: El arbitro no tiene ese idioma => 1 error
PRINT '--- F-3.12.65 arbitraje.arbitro_idioma_eliminar: El arbitro no tiene ese idioma';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.arbitro_idioma_eliminar @b, 'ruso'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.66 arbitraje.arbitro_idioma_eliminar: Arbitro inexistente => 1 error
PRINT '--- F-3.12.66 arbitraje.arbitro_idioma_eliminar: Arbitro inexistente';
BEGIN TRY EXEC arbitraje.arbitro_idioma_eliminar 999999, 'espanol'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.67 arbitraje.arbitro_idioma_eliminar: Arbitro e idioma nulos => 1 error
PRINT '--- F-3.12.67 arbitraje.arbitro_idioma_eliminar: Arbitro e idioma nulos';
BEGIN TRY EXEC arbitraje.arbitro_idioma_eliminar NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.designacion_arbitral_insertar: F-3.12.68 a F-3.12.81
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.68 arbitraje.designacion_arbitral_insertar: Partido inexistente => 1 error
PRINT '--- F-3.12.68 arbitraje.designacion_arbitral_insertar: Partido inexistente';
DECLARE @id INT,
        @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar 999999, @l, 'cuarto', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.69 arbitraje.designacion_arbitral_insertar: Partido nulo => 1 error
PRINT '--- F-3.12.69 arbitraje.designacion_arbitral_insertar: Partido nulo';
DECLARE @id INT,
        @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar NULL, @l, 'cuarto', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.70 arbitraje.designacion_arbitral_insertar: Partido finalizado => 1 error
PRINT '--- F-3.12.70 arbitraje.designacion_arbitral_insertar: Partido finalizado';
DECLARE @id INT,
        @pf INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pfin'),
        @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pf, @l, 'asistente_1', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.71 arbitraje.designacion_arbitral_insertar: Arbitro inexistente => 1 error
PRINT '--- F-3.12.71 arbitraje.designacion_arbitral_insertar: Arbitro inexistente';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, 999999, 'asistente_2', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.72 arbitraje.designacion_arbitral_insertar: Arbitro nulo => 1 error
PRINT '--- F-3.12.72 arbitraje.designacion_arbitral_insertar: Arbitro nulo';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, NULL, 'asistente_2', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.73 arbitraje.designacion_arbitral_insertar: Rol invalido => 1 error
PRINT '--- F-3.12.73 arbitraje.designacion_arbitral_insertar: Rol invalido';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'),
        @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, @l, 'linea', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.74 arbitraje.designacion_arbitral_insertar: Rol nulo => 1 error
PRINT '--- F-3.12.74 arbitraje.designacion_arbitral_insertar: Rol nulo';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'),
        @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, @l, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.75 arbitraje.designacion_arbitral_insertar: El partido ya tiene designado ese rol => 1 error
PRINT '--- F-3.12.75 arbitraje.designacion_arbitral_insertar: El partido ya tiene designado ese rol';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'),
        @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, @l, 'principal', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.76 arbitraje.designacion_arbitral_insertar: El arbitro ya esta designado en el partido con otro rol => 1 error
PRINT '--- F-3.12.76 arbitraje.designacion_arbitral_insertar: El arbitro ya esta designado en el partido con otro rol';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'),
        @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, @b, 'asistente_2', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.77 arbitraje.designacion_arbitral_insertar: Conflicto de nacionalidad => 1 error
PRINT '--- F-3.12.77 arbitraje.designacion_arbitral_insertar: Conflicto de nacionalidad';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'),
        @cf INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_conf');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, @cf, 'asistente_2', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.78 arbitraje.designacion_arbitral_insertar: Arbitro designado en otro partido a menos de 24 horas => 1 error
PRINT '--- F-3.12.78 arbitraje.designacion_arbitral_insertar: Arbitro designado en otro partido a menos de 24 horas';
DECLARE @id INT,
        @pc INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pc'),
        @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pc, @b, 'cuarto', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.79 arbitraje.designacion_arbitral_insertar: partido, arbitro y rol => 3 errores
PRINT '--- F-3.12.79 arbitraje.designacion_arbitral_insertar: 3 errores: partido, arbitro y rol';
DECLARE @id INT;
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar 999999, 999999, 'linea', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.80 arbitraje.designacion_arbitral_insertar: rol ocupado y arbitro ya designado => 2 errores
PRINT '--- F-3.12.80 arbitraje.designacion_arbitral_insertar: 2 errores: rol ocupado y arbitro ya designado';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'),
        @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, @b, 'principal', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.81 arbitraje.designacion_arbitral_insertar: partido finalizado, rol ocupado y conflicto de nacionalidad => 3 errores
PRINT '--- F-3.12.81 arbitraje.designacion_arbitral_insertar: 3 errores: partido finalizado, rol ocupado y conflicto de nacionalidad';
DECLARE @id INT,
        @pf INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pfin'),
        @cf INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_conf');
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pf, @cf, 'principal', @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.designacion_arbitral_modificar: F-3.12.82 a F-3.12.92
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.82 arbitraje.designacion_arbitral_modificar: Designacion inexistente => 1 error
PRINT '--- F-3.12.82 arbitraje.designacion_arbitral_modificar: Designacion inexistente';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar 999999, @l, 'cuarto'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.83 arbitraje.designacion_arbitral_modificar: Designacion nula => 1 error
PRINT '--- F-3.12.83 arbitraje.designacion_arbitral_modificar: Designacion nula';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar NULL, @l, 'cuarto'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.84 arbitraje.designacion_arbitral_modificar: Arbitro inexistente => 1 error
PRINT '--- F-3.12.84 arbitraje.designacion_arbitral_modificar: Arbitro inexistente';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, 999999, 'cuarto'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.85 arbitraje.designacion_arbitral_modificar: Rol invalido => 1 error
PRINT '--- F-3.12.85 arbitraje.designacion_arbitral_modificar: Rol invalido';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @adm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_dmod');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @adm, 'linea'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.86 arbitraje.designacion_arbitral_modificar: El partido ya tiene designado ese rol => 1 error
PRINT '--- F-3.12.86 arbitraje.designacion_arbitral_modificar: El partido ya tiene designado ese rol';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @adm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_dmod');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @adm, 'principal'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.87 arbitraje.designacion_arbitral_modificar: El arbitro ya esta designado en el partido con otro rol => 1 error
PRINT '--- F-3.12.87 arbitraje.designacion_arbitral_modificar: El arbitro ya esta designado en el partido con otro rol';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @b, 'cuarto'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.88 arbitraje.designacion_arbitral_modificar: Conflicto de nacionalidad => 1 error
PRINT '--- F-3.12.88 arbitraje.designacion_arbitral_modificar: Conflicto de nacionalidad';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @cf INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_conf');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @cf, 'cuarto'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.89 arbitraje.designacion_arbitral_modificar: Arbitro designado en otro partido a menos de 24 horas => 1 error
PRINT '--- F-3.12.89 arbitraje.designacion_arbitral_modificar: Arbitro designado en otro partido a menos de 24 horas';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @apc INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_pc');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @apc, 'cuarto'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.90 arbitraje.designacion_arbitral_modificar: No se puede cambiar el arbitro: la designacion tiene informes => 1 error
PRINT '--- F-3.12.90 arbitraje.designacion_arbitral_modificar: No se puede cambiar el arbitro: la designacion tiene informes';
DECLARE @di INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_inf'),
        @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @di, @l, 'asistente_1'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.91 arbitraje.designacion_arbitral_modificar: rol, conflicto de nacionalidad e informes cargados => 3 errores
PRINT '--- F-3.12.91 arbitraje.designacion_arbitral_modificar: 3 errores: rol, conflicto de nacionalidad e informes cargados';
DECLARE @di INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_inf'),
        @cf INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_conf');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @di, @cf, 'linea'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.92 arbitraje.designacion_arbitral_modificar: rol ocupado y arbitro ya designado => 2 errores
PRINT '--- F-3.12.92 arbitraje.designacion_arbitral_modificar: 2 errores: rol ocupado y arbitro ya designado';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @b, 'principal'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.designacion_arbitral_eliminar: F-3.12.93 a F-3.12.98
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.93 arbitraje.designacion_arbitral_eliminar: Designacion inexistente (el caso la da de baja antes) => 1 error
PRINT '--- F-3.12.93 arbitraje.designacion_arbitral_eliminar: Designacion inexistente (el caso la da de baja antes)';
DECLARE @de INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_elim');
BEGIN TRY EXEC arbitraje.designacion_arbitral_eliminar @de; EXEC arbitraje.designacion_arbitral_eliminar @de; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.94 arbitraje.designacion_arbitral_eliminar: Designacion inexistente => 1 error
PRINT '--- F-3.12.94 arbitraje.designacion_arbitral_eliminar: Designacion inexistente';
BEGIN TRY EXEC arbitraje.designacion_arbitral_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.95 arbitraje.designacion_arbitral_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.12.95 arbitraje.designacion_arbitral_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC arbitraje.designacion_arbitral_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.96 arbitraje.designacion_arbitral_eliminar: Tiene informes arbitrales cargados => 1 error
PRINT '--- F-3.12.96 arbitraje.designacion_arbitral_eliminar: Tiene informes arbitrales cargados';
DECLARE @di INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_inf');
BEGIN TRY EXEC arbitraje.designacion_arbitral_eliminar @di; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.97 arbitraje.designacion_arbitral_eliminar: El partido ya esta finalizado => 1 error
PRINT '--- F-3.12.97 arbitraje.designacion_arbitral_eliminar: El partido ya esta finalizado';
DECLARE @df2 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_fin2');
BEGIN TRY EXEC arbitraje.designacion_arbitral_eliminar @df2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.98 arbitraje.designacion_arbitral_eliminar: partido finalizado e informes cargados => 2 errores
PRINT '--- F-3.12.98 arbitraje.designacion_arbitral_eliminar: 2 errores: partido finalizado e informes cargados';
DECLARE @df INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_fin');
BEGIN TRY EXEC arbitraje.designacion_arbitral_eliminar @df; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.informe_arbitral_insertar: F-3.12.99 a F-3.12.107
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.99 arbitraje.informe_arbitral_insertar: Designacion inexistente => 1 error
PRINT '--- F-3.12.99 arbitraje.informe_arbitral_insertar: Designacion inexistente';
DECLARE @id INT;
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar 999999, '2031-01-10 20:00:00 +00:00', 'Informe', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.100 arbitraje.informe_arbitral_insertar: Designacion nula => 1 error
PRINT '--- F-3.12.100 arbitraje.informe_arbitral_insertar: Designacion nula';
DECLARE @id INT;
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar NULL, '2031-01-10 20:00:00 +00:00', 'Informe', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.101 arbitraje.informe_arbitral_insertar: Fecha nula => 1 error
PRINT '--- F-3.12.101 arbitraje.informe_arbitral_insertar: Fecha nula';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base');
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, NULL, 'Informe', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.102 arbitraje.informe_arbitral_insertar: Fecha anterior al inicio del partido (borde: un minuto antes) => 1 error
PRINT '--- F-3.12.102 arbitraje.informe_arbitral_insertar: Fecha anterior al inicio del partido (borde: un minuto antes)';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base'),
        @antes DATETIMEOFFSET = DATEADD(MINUTE, -1, (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg')));
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, @antes, 'Informe', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.103 arbitraje.informe_arbitral_insertar: Contenido nulo => 1 error
PRINT '--- F-3.12.103 arbitraje.informe_arbitral_insertar: Contenido nulo';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base');
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, '2031-01-10 20:00:00 +00:00', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.104 arbitraje.informe_arbitral_insertar: Contenido vacio => 1 error
PRINT '--- F-3.12.104 arbitraje.informe_arbitral_insertar: Contenido vacio';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base');
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, '2031-01-10 20:00:00 +00:00', '', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.105 arbitraje.informe_arbitral_insertar: Contenido solo espacios => 1 error
PRINT '--- F-3.12.105 arbitraje.informe_arbitral_insertar: Contenido solo espacios';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base');
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, '2031-01-10 20:00:00 +00:00', '   ', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.106 arbitraje.informe_arbitral_insertar: designacion, fecha y contenido => 3 errores
PRINT '--- F-3.12.106 arbitraje.informe_arbitral_insertar: 3 errores: designacion, fecha y contenido';
DECLARE @id INT;
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar 999999, NULL, '', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.107 arbitraje.informe_arbitral_insertar: fecha anterior al partido y contenido vacio => 2 errores
PRINT '--- F-3.12.107 arbitraje.informe_arbitral_insertar: 2 errores: fecha anterior al partido y contenido vacio';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base'),
        @antes DATETIMEOFFSET = DATEADD(MINUTE, -1, (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg')));
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, @antes, '  ', NULL, @id OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.informe_arbitral_modificar: F-3.12.108 a F-3.12.115
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.108 arbitraje.informe_arbitral_modificar: Informe inexistente => 1 error
PRINT '--- F-3.12.108 arbitraje.informe_arbitral_modificar: Informe inexistente';
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar 999999, '2031-01-10 20:00:00 +00:00', 'Informe'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.109 arbitraje.informe_arbitral_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.12.109 arbitraje.informe_arbitral_modificar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar NULL, '2031-01-10 20:00:00 +00:00', 'Informe'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.110 arbitraje.informe_arbitral_modificar: Fecha nula => 1 error
PRINT '--- F-3.12.110 arbitraje.informe_arbitral_modificar: Fecha nula';
DECLARE @ib INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base');
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar @ib, NULL, 'Informe'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.111 arbitraje.informe_arbitral_modificar: Fecha anterior al inicio del partido (borde: un minuto antes) => 1 error
PRINT '--- F-3.12.111 arbitraje.informe_arbitral_modificar: Fecha anterior al inicio del partido (borde: un minuto antes)';
DECLARE @ib INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base'),
        @antes DATETIMEOFFSET = DATEADD(MINUTE, -1, (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg')));
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar @ib, @antes, 'Informe'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.112 arbitraje.informe_arbitral_modificar: Contenido nulo => 1 error
PRINT '--- F-3.12.112 arbitraje.informe_arbitral_modificar: Contenido nulo';
DECLARE @ib INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base');
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar @ib, '2031-01-10 20:00:00 +00:00', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.113 arbitraje.informe_arbitral_modificar: Contenido solo espacios => 1 error
PRINT '--- F-3.12.113 arbitraje.informe_arbitral_modificar: Contenido solo espacios';
DECLARE @ib INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base');
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar @ib, '2031-01-10 20:00:00 +00:00', '   '; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.114 arbitraje.informe_arbitral_modificar: fecha anterior al partido y contenido vacio => 2 errores
PRINT '--- F-3.12.114 arbitraje.informe_arbitral_modificar: 2 errores: fecha anterior al partido y contenido vacio';
DECLARE @ib INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base'),
        @antes DATETIMEOFFSET = DATEADD(MINUTE, -1, (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg')));
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar @ib, @antes, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.115 arbitraje.informe_arbitral_modificar: informe inexistente, fecha y contenido (se validan los datos aunque no exista) => 3 errores
PRINT '--- F-3.12.115 arbitraje.informe_arbitral_modificar: 3 errores: informe inexistente, fecha y contenido (se validan los datos aunque no exista)';
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar 999999, NULL, ''; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- arbitraje.informe_arbitral_eliminar: F-3.12.116 a F-3.12.118
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.12.116 arbitraje.informe_arbitral_eliminar: Informe inexistente (el caso lo da de baja antes) => 1 error
PRINT '--- F-3.12.116 arbitraje.informe_arbitral_eliminar: Informe inexistente (el caso lo da de baja antes)';
DECLARE @ie INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_elim');
BEGIN TRY EXEC arbitraje.informe_arbitral_eliminar @ie; EXEC arbitraje.informe_arbitral_eliminar @ie; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.117 arbitraje.informe_arbitral_eliminar: Informe inexistente => 1 error
PRINT '--- F-3.12.117 arbitraje.informe_arbitral_eliminar: Informe inexistente';
BEGIN TRY EXEC arbitraje.informe_arbitral_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.12.118 arbitraje.informe_arbitral_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.12.118 arbitraje.informe_arbitral_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC arbitraje.informe_arbitral_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- ============================================================
-- 3.13 publicidad: anunciante, campania, campania_pais_interes, pieza_publicitaria y espacio_publicitario
-- ============================================================

-- -------------------------------------------------------------------------------------
-- publicidad.anunciante_insertar: F-3.13.01 a F-3.13.07
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.01 publicidad.anunciante_insertar: Nombre vacio => 1 error
PRINT '--- F-3.13.01 publicidad.anunciante_insertar: Nombre vacio';
DECLARE @anun INT;
BEGIN TRY EXEC publicidad.anunciante_insertar '', 'Empresa S.A.', 'ventas@gmail.com', @anun OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.02 publicidad.anunciante_insertar: Nombre duplicado => 1 error (antes, el alta válida de TEST01, que se deshace al final)
PRINT '--- F-3.13.02 publicidad.anunciante_insertar: Nombre duplicado';
DECLARE @anun INT;
BEGIN TRAN;
BEGIN TRY
    EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventas@gmail.com';
    EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventas@gmail.com', @anun OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.13.03 publicidad.anunciante_insertar: Correo sin @ => 1 error
PRINT '--- F-3.13.03 publicidad.anunciante_insertar: Correo sin @';
DECLARE @anun INT;
BEGIN TRY EXEC publicidad.anunciante_insertar 'TEST02', 'Empresa S.A.', 'ventasgmail.com', @anun OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.04 publicidad.anunciante_insertar: Dos @ => 1 error
PRINT '--- F-3.13.04 publicidad.anunciante_insertar: Dos @';
DECLARE @anun INT;
BEGIN TRY EXEC publicidad.anunciante_insertar 'TEST03', 'Empresa S.A.', 'ventas@@gmail.com', @anun OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.05 publicidad.anunciante_insertar: +100 caracteres => 1 error
PRINT '--- F-3.13.05 publicidad.anunciante_insertar: +100 caracteres';
DECLARE @anun INT;
BEGIN TRY EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventas@gmail.com', @anun OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.06 publicidad.anunciante_insertar: Sin dominio => 1 error
PRINT '--- F-3.13.06 publicidad.anunciante_insertar: Sin dominio';
DECLARE @anun INT;
BEGIN TRY EXEC publicidad.anunciante_insertar 'TEST04', 'Empresa S.A.', 'ventas@gmail', @anun OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.07 publicidad.anunciante_insertar: Con espacios => 1 error
PRINT '--- F-3.13.07 publicidad.anunciante_insertar: Con espacios';
DECLARE @anun INT;
BEGIN TRY EXEC publicidad.anunciante_insertar 'TEST05', 'Empresa S.A.', 'ventas @gmail.com', @anun OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.anunciante_modificar: F-3.13.08 a F-3.13.14
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.08 publicidad.anunciante_modificar: Nombre vacio => 1 error
PRINT '--- F-3.13.08 publicidad.anunciante_modificar: Nombre vacio';
BEGIN TRY EXEC publicidad.anunciante_modificar 1, '', 'Empresa S.A.', 'ventas@gmail.com'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.09 publicidad.anunciante_modificar: Nombre duplicado => 1 error (antes, el alta válida de TEST01, que se deshace al final)
PRINT '--- F-3.13.09 publicidad.anunciante_modificar: Nombre duplicado';
BEGIN TRAN;
BEGIN TRY
    EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventas@gmail.com';
    EXEC publicidad.anunciante_modificar 1, 'TEST01', 'Empresa S.A.', 'ventas@gmail.com';
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.13.10 publicidad.anunciante_modificar: Correo sin @ => 1 error
PRINT '--- F-3.13.10 publicidad.anunciante_modificar: Correo sin @';
BEGIN TRY EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventasgmail.com'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.11 publicidad.anunciante_modificar: Dos @ => 1 error
PRINT '--- F-3.13.11 publicidad.anunciante_modificar: Dos @';
BEGIN TRY EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas@@gmail.com'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.12 publicidad.anunciante_modificar: Sin dominio => 1 error
PRINT '--- F-3.13.12 publicidad.anunciante_modificar: Sin dominio';
BEGIN TRY EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas@gmail'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.13 publicidad.anunciante_modificar: Con espacios => 1 error
PRINT '--- F-3.13.13 publicidad.anunciante_modificar: Con espacios';
BEGIN TRY EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas @gmail.com'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.14 publicidad.anunciante_modificar: ID inexistente y ya existe otro anunciante con ese nombre => 2 errores (antes, un anunciante TEST_MOD (en exitosos lo crea la modificación válida), que se deshace al final)
PRINT '--- F-3.13.14 publicidad.anunciante_modificar: 2 errores: ID inexistente y ya existe otro anunciante con ese nombre';
BEGIN TRAN;
BEGIN TRY
    EXEC publicidad.anunciante_insertar 'TEST_MOD', NULL, NULL;
    EXEC publicidad.anunciante_modificar 999999, 'TEST_MOD', 'Empresa S.A.', 'ventas@gmail.com';
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

PRINT '--- P-3.19 Preparación de publicidad.anunciante_eliminar (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @a INT;
EXEC publicidad.anunciante_insertar 'ELIM_OK', NULL, NULL;
EXEC publicidad.anunciante_insertar 'ELIM_CON_CAMP', NULL, NULL, @a OUTPUT;
EXEC publicidad.campania_insertar @a, 'Camp de prueba', '2026-06-01', '2026-06-30';
GO

-- -------------------------------------------------------------------------------------
-- publicidad.anunciante_eliminar: F-3.13.15 a F-3.13.17
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.19 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.15 publicidad.anunciante_eliminar: ID inexistente => 1 error
PRINT '--- F-3.13.15 publicidad.anunciante_eliminar: ID inexistente';
BEGIN TRY EXEC publicidad.anunciante_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.16 publicidad.anunciante_eliminar: ID nulo => 1 error
PRINT '--- F-3.13.16 publicidad.anunciante_eliminar: ID nulo';
BEGIN TRY EXEC publicidad.anunciante_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.17 publicidad.anunciante_eliminar: Tiene campañas registradas => 1 error
PRINT '--- F-3.13.17 publicidad.anunciante_eliminar: Tiene campañas registradas';
DECLARE @elim_con INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'ELIM_CON_CAMP');
BEGIN TRY EXEC publicidad.anunciante_eliminar @elim_con; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

PRINT '--- P-3.20 Preparación de publicidad.campania_insertar (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
EXEC publicidad.anunciante_insertar 'CAMP_A', NULL, NULL;
EXEC publicidad.anunciante_insertar 'CAMP_B', NULL, NULL;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.campania_insertar: F-3.13.18 a F-3.13.32
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.20 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.18 publicidad.campania_insertar: Anunciante inexistente => 1 error
PRINT '--- F-3.13.18 publicidad.campania_insertar: Anunciante inexistente';
DECLARE @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar 999999, 'X1', '2026-06-01', '2026-07-19', @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.19 publicidad.campania_insertar: Anunciante nulo => 1 error
PRINT '--- F-3.13.19 publicidad.campania_insertar: Anunciante nulo';
DECLARE @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar NULL, 'X2', '2026-06-01', '2026-07-19', @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.20 publicidad.campania_insertar: Nombre vacio => 1 error
PRINT '--- F-3.13.20 publicidad.campania_insertar: Nombre vacio';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar @a, '', '2026-06-01', '2026-07-19', @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.21 publicidad.campania_insertar: Nombre nulo => 1 error
PRINT '--- F-3.13.21 publicidad.campania_insertar: Nombre nulo';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar @a, NULL, '2026-06-01', '2026-07-19', @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.22 publicidad.campania_insertar: Nombre solo espacios => 1 error
PRINT '--- F-3.13.22 publicidad.campania_insertar: Nombre solo espacios';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar @a, '   ', '2026-06-01', '2026-07-19', @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.23 publicidad.campania_insertar: Fecha inicio nula => 1 error
PRINT '--- F-3.13.23 publicidad.campania_insertar: Fecha inicio nula';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar @a, 'X3', NULL, '2026-07-19', @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.24 publicidad.campania_insertar: Fecha fin nula => 1 error
PRINT '--- F-3.13.24 publicidad.campania_insertar: Fecha fin nula';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar @a, 'X4', '2026-06-01', NULL, @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.25 publicidad.campania_insertar: Ambas fechas nulas (un solo mensaje) => 1 error
PRINT '--- F-3.13.25 publicidad.campania_insertar: Ambas fechas nulas (un solo mensaje)';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar @a, 'X5', NULL, NULL, @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.26 publicidad.campania_insertar: Fin anterior al inicio => 1 error
PRINT '--- F-3.13.26 publicidad.campania_insertar: Fin anterior al inicio';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar @a, 'X6', '2026-07-01', '2026-06-01', @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.27 publicidad.campania_insertar: Nombre duplicado (mismo anunciante) => 1 error (antes, el alta válida de 'Camp Test', que se deshace al final)
PRINT '--- F-3.13.27 publicidad.campania_insertar: Nombre duplicado (mismo anunciante)';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRAN;
BEGIN TRY
    EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19';
    EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19', @camp OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.13.28 publicidad.campania_insertar: Nombre duplicado con otra capitalizacion => 1 error (antes, el alta válida de 'Camp Test', que se deshace al final)
PRINT '--- F-3.13.28 publicidad.campania_insertar: Nombre duplicado con otra capitalizacion';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRAN;
BEGIN TRY
    EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19';
    EXEC publicidad.campania_insertar @a, 'CAMP TEST', '2026-06-01', '2026-07-19', @camp OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.13.29 publicidad.campania_insertar: Nombre duplicado con espacios al final => 1 error (antes, el alta válida de 'Camp Test', que se deshace al final)
PRINT '--- F-3.13.29 publicidad.campania_insertar: Nombre duplicado con espacios al final';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRAN;
BEGIN TRY
    EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19';
    EXEC publicidad.campania_insertar @a, 'Camp Test   ', '2026-06-01', '2026-07-19', @camp OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.13.30 publicidad.campania_insertar: anunciante inexistente, nombre vacio, fin anterior al inicio => 3 errores
PRINT '--- F-3.13.30 publicidad.campania_insertar: 3 errores: anunciante inexistente, nombre vacio, fin anterior al inicio';
DECLARE @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar 999999, '', '2026-07-01', '2026-06-01', @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.31 publicidad.campania_insertar: nombre duplicado y fin anterior al inicio => 2 errores (antes, el alta válida de 'Camp Test', que se deshace al final)
PRINT '--- F-3.13.31 publicidad.campania_insertar: 2 errores: nombre duplicado y fin anterior al inicio';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
BEGIN TRAN;
BEGIN TRY
    EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19';
    EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-07-01', '2026-06-01', @camp OUTPUT;
END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
IF @@TRANCOUNT > 0 ROLLBACK;
GO

-- F-3.13.32 publicidad.campania_insertar: anunciante, nombre y fechas => 3 errores
PRINT '--- F-3.13.32 publicidad.campania_insertar: 3 errores: anunciante, nombre y fechas';
DECLARE @camp INT;
BEGIN TRY EXEC publicidad.campania_insertar NULL, NULL, NULL, NULL, @camp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

PRINT '--- P-3.21 Preparación de publicidad.campania_modificar (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
EXEC publicidad.anunciante_insertar 'CMOD_A', NULL, NULL;
EXEC publicidad.anunciante_insertar 'CMOD_B', NULL, NULL;
GO
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @pais INT = (SELECT TOP 1 pais_id FROM torneo.pais ORDER BY pais_id),
        @part INT = (SELECT TOP 1 p.partido_id FROM torneo.partido p
                     WHERE NOT EXISTS (SELECT 1 FROM publicidad.espacio_publicitario e WHERE e.partido_id = p.partido_id)
                     ORDER BY p.partido_id),
        @f DATE, @ini DATE, @fin DATE, @c INT, @pz INT, @esp INT;
SELECT @f = CAST(fecha_hora_utc AS DATE) FROM torneo.partido WHERE partido_id = @part;
SET @ini = DATEADD(DAY, -1, @f);
SET @fin = DATEADD(DAY, 1, @f);

EXEC publicidad.campania_insertar @a, 'Camp Mod', '2026-06-01', '2026-07-19', @c OUTPUT;
EXEC publicidad.campania_insertar @a, 'Camp Otra', '2026-06-01', '2026-07-19', @c OUTPUT;
EXEC publicidad.campania_insertar @a, 'Camp Con Espacio', @ini, @fin, @c OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @c, @pais;
EXEC publicidad.pieza_publicitaria_insertar @c, 'espanol', @pais, 1000, @pz OUTPUT;
EXEC publicidad.espacio_publicitario_insertar @part, 1, @pz, NULL, @esp OUTPUT;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.campania_modificar: F-3.13.33 a F-3.13.52
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.21 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.33 publicidad.campania_modificar: Campaña inexistente => 1 error
PRINT '--- F-3.13.33 publicidad.campania_modificar: Campaña inexistente';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A');
BEGIN TRY EXEC publicidad.campania_modificar 999999, @a, 'X1', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.34 publicidad.campania_modificar: Id nulo (1 condicion: el id es obligatorio) => 1 error
PRINT '--- F-3.13.34 publicidad.campania_modificar: Id nulo (1 condicion: el id es obligatorio)';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A');
BEGIN TRY EXEC publicidad.campania_modificar NULL, @a, 'X2', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.35 publicidad.campania_modificar: Anunciante inexistente => 1 error
PRINT '--- F-3.13.35 publicidad.campania_modificar: Anunciante inexistente';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, 999999, 'Camp Mod', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.36 publicidad.campania_modificar: Anunciante nulo => 1 error
PRINT '--- F-3.13.36 publicidad.campania_modificar: Anunciante nulo';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, NULL, 'Camp Mod', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.37 publicidad.campania_modificar: Nombre vacio => 1 error
PRINT '--- F-3.13.37 publicidad.campania_modificar: Nombre vacio';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, '', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.38 publicidad.campania_modificar: Nombre nulo => 1 error
PRINT '--- F-3.13.38 publicidad.campania_modificar: Nombre nulo';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, NULL, '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.39 publicidad.campania_modificar: Nombre solo espacios => 1 error
PRINT '--- F-3.13.39 publicidad.campania_modificar: Nombre solo espacios';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, '   ', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.40 publicidad.campania_modificar: Fecha inicio nula => 1 error
PRINT '--- F-3.13.40 publicidad.campania_modificar: Fecha inicio nula';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', NULL, '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.41 publicidad.campania_modificar: Fecha fin nula => 1 error
PRINT '--- F-3.13.41 publicidad.campania_modificar: Fecha fin nula';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', '2026-06-01', NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.42 publicidad.campania_modificar: Ambas fechas nulas (un solo mensaje) => 1 error
PRINT '--- F-3.13.42 publicidad.campania_modificar: Ambas fechas nulas (un solo mensaje)';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.43 publicidad.campania_modificar: Fin anterior al inicio => 1 error
PRINT '--- F-3.13.43 publicidad.campania_modificar: Fin anterior al inicio';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', '2026-07-01', '2026-06-01'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.44 publicidad.campania_modificar: Nombre duplicado (otra campaña del mismo anunciante) => 1 error
PRINT '--- F-3.13.44 publicidad.campania_modificar: Nombre duplicado (otra campaña del mismo anunciante)';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'Camp Otra', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.45 publicidad.campania_modificar: Duplicado con otra capitalizacion => 1 error
PRINT '--- F-3.13.45 publicidad.campania_modificar: Duplicado con otra capitalizacion';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'CAMP OTRA', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.46 publicidad.campania_modificar: Duplicado con espacios al final => 1 error
PRINT '--- F-3.13.46 publicidad.campania_modificar: Duplicado con espacios al final';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'Camp Otra   ', '2026-06-01', '2026-07-19'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.47 publicidad.campania_modificar: Vigencia deja afuera el partido con pieza asignada (inicio posterior al partido) => 1 error
PRINT '--- F-3.13.47 publicidad.campania_modificar: Vigencia deja afuera el partido con pieza asignada (inicio posterior al partido)';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c3 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'),
        @f DATE = (SELECT TOP 1 CAST(p.fecha_hora_utc AS DATE) FROM publicidad.espacio_publicitario e JOIN torneo.partido p ON p.partido_id = e.partido_id
                   JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
                   WHERE pz.campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'));
DECLARE @f_p1  DATE = DATEADD(DAY, 1, @f),
        @f_p10 DATE = DATEADD(DAY, 10, @f);
BEGIN TRY EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_p1, @f_p10; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.48 publicidad.campania_modificar: Vigencia deja afuera el partido con pieza asignada (fin anterior al partido) => 1 error
PRINT '--- F-3.13.48 publicidad.campania_modificar: Vigencia deja afuera el partido con pieza asignada (fin anterior al partido)';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c3 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'),
        @f DATE = (SELECT TOP 1 CAST(p.fecha_hora_utc AS DATE) FROM publicidad.espacio_publicitario e JOIN torneo.partido p ON p.partido_id = e.partido_id
                   JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
                   WHERE pz.campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'));
DECLARE @f_m10 DATE = DATEADD(DAY, -10, @f),
        @f_m1 DATE = DATEADD(DAY, -1, @f);
BEGIN TRY EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_m10, @f_m1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.49 publicidad.campania_modificar: fin anterior al inicio y vigencia que deja afuera el partido => 2 errores
PRINT '--- F-3.13.49 publicidad.campania_modificar: 2 errores: fin anterior al inicio y vigencia que deja afuera el partido';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c3 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'),
        @f DATE = (SELECT TOP 1 CAST(p.fecha_hora_utc AS DATE) FROM publicidad.espacio_publicitario e JOIN torneo.partido p ON p.partido_id = e.partido_id
                   JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
                   WHERE pz.campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'));
DECLARE @f_m1 DATE = DATEADD(DAY, -1, @f),
        @f_p1  DATE = DATEADD(DAY, 1, @f);
BEGIN TRY EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_p1, @f_m1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.50 publicidad.campania_modificar: campaña inexistente, anunciante inexistente, nombre vacio, fin anterior al inicio => 4 errores
PRINT '--- F-3.13.50 publicidad.campania_modificar: 4 errores: campaña inexistente, anunciante inexistente, nombre vacio, fin anterior al inicio';
BEGIN TRY EXEC publicidad.campania_modificar 999999, 999999, '', '2026-07-01', '2026-06-01'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.51 publicidad.campania_modificar: id obligatorio, anunciante inexistente, nombre vacio, fechas obligatorias => 4 errores
PRINT '--- F-3.13.51 publicidad.campania_modificar: 4 errores: id obligatorio, anunciante inexistente, nombre vacio, fechas obligatorias';
BEGIN TRY EXEC publicidad.campania_modificar NULL, NULL, NULL, NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.52 publicidad.campania_modificar: nombre duplicado y fin anterior al inicio => 2 errores
PRINT '--- F-3.13.52 publicidad.campania_modificar: 2 errores: nombre duplicado y fin anterior al inicio';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'Camp Otra', '2026-07-01', '2026-06-01'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

PRINT '--- P-3.22 Preparación de publicidad.campania_eliminar (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
EXEC publicidad.anunciante_insertar 'CELIM', NULL, NULL;
GO
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CELIM'),
        @pais INT = (SELECT TOP 1 pais_id FROM torneo.pais ORDER BY pais_id),
        @c INT, @pz INT;
EXEC publicidad.campania_insertar @a, 'Elim OK', '2026-06-01', '2026-07-19', @c OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @c, @pais;
EXEC publicidad.campania_insertar @a, 'Elim Con Pieza', '2026-06-01', '2026-07-19', @c OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @c, @pais;
EXEC publicidad.pieza_publicitaria_insertar @c, 'espanol', @pais, 1000, @pz OUTPUT;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.campania_eliminar: F-3.13.53 a F-3.13.55
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.22 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.53 publicidad.campania_eliminar: Campaña inexistente => 1 error
PRINT '--- F-3.13.53 publicidad.campania_eliminar: Campaña inexistente';
BEGIN TRY EXEC publicidad.campania_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.54 publicidad.campania_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.13.54 publicidad.campania_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC publicidad.campania_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.55 publicidad.campania_eliminar: Tiene piezas publicitarias registradas => 1 error
PRINT '--- F-3.13.55 publicidad.campania_eliminar: Tiene piezas publicitarias registradas';
DECLARE @con INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim Con Pieza');
BEGIN TRY EXEC publicidad.campania_eliminar @con; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

PRINT '--- P-3.23 Preparación de campania_pais_interes_* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
EXEC publicidad.anunciante_insertar 'CPI', NULL, NULL;
GO
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CPI'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
        @c INT, @pz INT;

EXEC publicidad.campania_insertar @a, 'CPI_INS', '2026-06-01', '2026-07-19', @c OUTPUT;   -- insertar: arranca con p1
EXEC publicidad.campania_pais_interes_insertar @c, @p1;

EXEC publicidad.campania_insertar @a, 'CPI_OTRA', '2026-06-01', '2026-07-19', @c OUTPUT;  -- insertar: campaña vacía

EXEC publicidad.campania_insertar @a, 'CPI_MOD', '2026-06-01', '2026-07-19', @c OUTPUT;   -- modificar: p1 (con pieza), p2, p3
EXEC publicidad.campania_pais_interes_insertar @c, @p1;
EXEC publicidad.campania_pais_interes_insertar @c, @p2;
EXEC publicidad.campania_pais_interes_insertar @c, @p3;
EXEC publicidad.pieza_publicitaria_insertar @c, 'espanol', @p1, 1000, @pz OUTPUT;

EXEC publicidad.campania_insertar @a, 'CPI_ELIM', '2026-06-01', '2026-07-19', @c OUTPUT;  -- eliminar: p1 (con pieza), p2, p3
EXEC publicidad.campania_pais_interes_insertar @c, @p1;
EXEC publicidad.campania_pais_interes_insertar @c, @p2;
EXEC publicidad.campania_pais_interes_insertar @c, @p3;
EXEC publicidad.pieza_publicitaria_insertar @c, 'espanol', @p1, 1000, @pz OUTPUT;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.campania_pais_interes_insertar: F-3.13.56 a F-3.13.62
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.56 publicidad.campania_pais_interes_insertar: Campaña inexistente => 1 error
PRINT '--- F-3.13.56 publicidad.campania_pais_interes_insertar: Campaña inexistente';
DECLARE @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar 999999, @p2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.57 publicidad.campania_pais_interes_insertar: Campaña nula => 1 error
PRINT '--- F-3.13.57 publicidad.campania_pais_interes_insertar: Campaña nula';
DECLARE @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar NULL, @p2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.58 publicidad.campania_pais_interes_insertar: Pais inexistente => 1 error
PRINT '--- F-3.13.58 publicidad.campania_pais_interes_insertar: Pais inexistente';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_INS');
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar @ci, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.59 publicidad.campania_pais_interes_insertar: Pais nulo => 1 error
PRINT '--- F-3.13.59 publicidad.campania_pais_interes_insertar: Pais nulo';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_INS');
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar @ci, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.60 publicidad.campania_pais_interes_insertar: Ya figura => 1 error
PRINT '--- F-3.13.60 publicidad.campania_pais_interes_insertar: Ya figura';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar @ci, @p1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.61 publicidad.campania_pais_interes_insertar: campaña inexistente y pais => 2 errores
PRINT '--- F-3.13.61 publicidad.campania_pais_interes_insertar: 2 errores: campaña inexistente y pais';
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar 999999, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.62 publicidad.campania_pais_interes_insertar: campaña nula y pais nulo => 2 errores
PRINT '--- F-3.13.62 publicidad.campania_pais_interes_insertar: 2 errores: campaña nula y pais nulo';
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar NULL, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.campania_pais_interes_modificar: F-3.13.63 a F-3.13.74
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.63 publicidad.campania_pais_interes_modificar: Campaña inexistente => 1 error
PRINT '--- F-3.13.63 publicidad.campania_pais_interes_modificar: Campaña inexistente';
DECLARE @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar 999999, @p2, @p4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.64 publicidad.campania_pais_interes_modificar: Campaña nula => 1 error
PRINT '--- F-3.13.64 publicidad.campania_pais_interes_modificar: Campaña nula';
DECLARE @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar NULL, @p2, @p4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.65 publicidad.campania_pais_interes_modificar: Pais a reemplazar inexistente (el par no figura) => 1 error
PRINT '--- F-3.13.65 publicidad.campania_pais_interes_modificar: Pais a reemplazar inexistente (el par no figura)';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, 999999, @p4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.66 publicidad.campania_pais_interes_modificar: Pais a reemplazar nulo => 1 error
PRINT '--- F-3.13.66 publicidad.campania_pais_interes_modificar: Pais a reemplazar nulo';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, NULL, @p4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.67 publicidad.campania_pais_interes_modificar: El pais a reemplazar existe pero no figura en la campaña => 1 error
PRINT '--- F-3.13.67 publicidad.campania_pais_interes_modificar: El pais a reemplazar existe pero no figura en la campaña';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @p5 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p4, @p5; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.68 publicidad.campania_pais_interes_modificar: Pais nuevo inexistente => 1 error
PRINT '--- F-3.13.68 publicidad.campania_pais_interes_modificar: Pais nuevo inexistente';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p2, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.69 publicidad.campania_pais_interes_modificar: Pais nuevo nulo => 1 error
PRINT '--- F-3.13.69 publicidad.campania_pais_interes_modificar: Pais nuevo nulo';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p2, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.70 publicidad.campania_pais_interes_modificar: Pais nuevo ya figura en la campaña => 1 error
PRINT '--- F-3.13.70 publicidad.campania_pais_interes_modificar: Pais nuevo ya figura en la campaña';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p2, @p3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.71 publicidad.campania_pais_interes_modificar: La campaña tiene piezas dirigidas al pais a reemplazar (p1) => 1 error
PRINT '--- F-3.13.71 publicidad.campania_pais_interes_modificar: La campaña tiene piezas dirigidas al pais a reemplazar (p1)';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p1, @p4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.72 publicidad.campania_pais_interes_modificar: pais nuevo ya figura y hay piezas dirigidas a p1 => 2 errores
PRINT '--- F-3.13.72 publicidad.campania_pais_interes_modificar: 2 errores: pais nuevo ya figura y hay piezas dirigidas a p1';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p1, @p3; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.73 publicidad.campania_pais_interes_modificar: el par no figura y pais nuevo inexistente => 2 errores
PRINT '--- F-3.13.73 publicidad.campania_pais_interes_modificar: 2 errores: el par no figura y pais nuevo inexistente';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p4, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.74 publicidad.campania_pais_interes_modificar: el par no figura y pais nuevo nulo => 2 errores
PRINT '--- F-3.13.74 publicidad.campania_pais_interes_modificar: 2 errores: el par no figura y pais nuevo nulo';
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar 999999, 999999, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.campania_pais_interes_eliminar: F-3.13.75 a F-3.13.81
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.75 publicidad.campania_pais_interes_eliminar: El pais no figura en la campaña => 1 error
PRINT '--- F-3.13.75 publicidad.campania_pais_interes_eliminar: El pais no figura en la campaña';
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_ELIM'),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_eliminar @ce, @p4; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.76 publicidad.campania_pais_interes_eliminar: Campaña inexistente (el par no figura) => 1 error
PRINT '--- F-3.13.76 publicidad.campania_pais_interes_eliminar: Campaña inexistente (el par no figura)';
DECLARE @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_eliminar 999999, @p2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.77 publicidad.campania_pais_interes_eliminar: Campaña nula => 1 error
PRINT '--- F-3.13.77 publicidad.campania_pais_interes_eliminar: Campaña nula';
DECLARE @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_eliminar NULL, @p2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.78 publicidad.campania_pais_interes_eliminar: Pais inexistente (el par no figura) => 1 error
PRINT '--- F-3.13.78 publicidad.campania_pais_interes_eliminar: Pais inexistente (el par no figura)';
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_ELIM');
BEGIN TRY EXEC publicidad.campania_pais_interes_eliminar @ce, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.79 publicidad.campania_pais_interes_eliminar: Pais nulo => 1 error
PRINT '--- F-3.13.79 publicidad.campania_pais_interes_eliminar: Pais nulo';
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_ELIM');
BEGIN TRY EXEC publicidad.campania_pais_interes_eliminar @ce, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.80 publicidad.campania_pais_interes_eliminar: La campaña tiene piezas dirigidas a ese pais => 1 error
PRINT '--- F-3.13.80 publicidad.campania_pais_interes_eliminar: La campaña tiene piezas dirigidas a ese pais';
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_ELIM'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.campania_pais_interes_eliminar @ce, @p1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.81 publicidad.campania_pais_interes_eliminar: 1 error: el par no figura (las dos condiciones son excluyentes) => 1 error
PRINT '--- F-3.13.81 publicidad.campania_pais_interes_eliminar: 1 error: el par no figura (las dos condiciones son excluyentes)';
BEGIN TRY EXEC publicidad.campania_pais_interes_eliminar 999999, 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

PRINT '--- P-3.24 Preparación de pieza_publicitaria* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
EXEC publicidad.anunciante_insertar 'PZ', NULL, NULL;
GO
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'PZ'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
        @part INT = (SELECT TOP 1 p.partido_id FROM torneo.partido p
                     WHERE NOT EXISTS (SELECT 1 FROM publicidad.espacio_publicitario e WHERE e.partido_id = p.partido_id)
                     ORDER BY p.partido_id),
        @f DATE, @ini DATE, @fin DATE, @c INT, @pz INT, @esp INT;
SELECT @f = CAST(fecha_hora_utc AS DATE) FROM torneo.partido WHERE partido_id = @part;
SET @ini = DATEADD(DAY, -1, @f);
SET @fin = DATEADD(DAY, 1, @f);

EXEC publicidad.campania_insertar @a, 'PZ_INS', '2026-06-01', '2026-07-19', @c OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @c, @p1;
EXEC publicidad.campania_pais_interes_insertar @c, @p2;
EXEC publicidad.campania_pais_interes_insertar @c, @p3;
EXEC publicidad.pieza_publicitaria_insertar @c, 'espanol', @p1, 1000, @pz OUTPUT;

EXEC publicidad.campania_insertar @a, 'PZ_OTRA', '2026-06-01', '2026-07-19', @c OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @c, @p1;

EXEC publicidad.campania_insertar @a, 'PZ_MOD', @ini, @fin, @c OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @c, @p1;
EXEC publicidad.campania_pais_interes_insertar @c, @p2;
EXEC publicidad.campania_pais_interes_insertar @c, @p3;
EXEC publicidad.pieza_publicitaria_insertar @c, 'ingles',  @p1, 1000, @pz OUTPUT;   -- m1
EXEC publicidad.pieza_publicitaria_insertar @c, 'frances', @p2, 2000, @pz OUTPUT;   -- m2
EXEC publicidad.pieza_publicitaria_insertar @c, 'aleman',  @p3, 3000, @pz OUTPUT;   -- m3 (con espacio)
EXEC publicidad.espacio_publicitario_insertar @part, 1, @pz, NULL, @esp OUTPUT;

EXEC publicidad.campania_insertar @a, 'PZ_DEST', '2026-06-01', '2026-07-19', @c OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @c, @p1;
EXEC publicidad.campania_pais_interes_insertar @c, @p3;

EXEC publicidad.campania_insertar @a, 'PZ_ELIM', @ini, @fin, @c OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @c, @p1;
EXEC publicidad.campania_pais_interes_insertar @c, @p2;
EXEC publicidad.pieza_publicitaria_insertar @c, 'espanol', @p1, 1000, @pz OUTPUT;   -- e1 (libre)
EXEC publicidad.pieza_publicitaria_insertar @c, 'ingles',  @p2, 2000, @pz OUTPUT;   -- e2 (con espacio)
EXEC publicidad.espacio_publicitario_insertar @part, 2, @pz, NULL, @esp OUTPUT;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.pieza_publicitaria_insertar: F-3.13.82 a F-3.13.98
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.82 publicidad.pieza_publicitaria_insertar: Campaña inexistente => 1 error
PRINT '--- F-3.13.82 publicidad.pieza_publicitaria_insertar: Campaña inexistente';
DECLARE @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar 999999, 'ingles', @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.83 publicidad.pieza_publicitaria_insertar: Campaña nula => 1 error
PRINT '--- F-3.13.83 publicidad.pieza_publicitaria_insertar: Campaña nula';
DECLARE @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar NULL, 'ingles', @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.84 publicidad.pieza_publicitaria_insertar: Idioma vacio => 1 error
PRINT '--- F-3.13.84 publicidad.pieza_publicitaria_insertar: Idioma vacio';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, '', @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.85 publicidad.pieza_publicitaria_insertar: Idioma nulo => 1 error
PRINT '--- F-3.13.85 publicidad.pieza_publicitaria_insertar: Idioma nulo';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, NULL, @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.86 publicidad.pieza_publicitaria_insertar: Idioma solo espacios => 1 error
PRINT '--- F-3.13.86 publicidad.pieza_publicitaria_insertar: Idioma solo espacios';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, '   ', @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.87 publicidad.pieza_publicitaria_insertar: Idioma con numero => 1 error
PRINT '--- F-3.13.87 publicidad.pieza_publicitaria_insertar: Idioma con numero';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingl3s', @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.88 publicidad.pieza_publicitaria_insertar: Idioma con espacio => 1 error
PRINT '--- F-3.13.88 publicidad.pieza_publicitaria_insertar: Idioma con espacio';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles uk', @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.89 publicidad.pieza_publicitaria_insertar: Idioma de 11 letras => 1 error
PRINT '--- F-3.13.89 publicidad.pieza_publicitaria_insertar: Idioma de 11 letras';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'abcdefghijk', @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.90 publicidad.pieza_publicitaria_insertar: Pais mercado inexistente => 1 error
PRINT '--- F-3.13.90 publicidad.pieza_publicitaria_insertar: Pais mercado inexistente';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', 999999, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.91 publicidad.pieza_publicitaria_insertar: Pais mercado nulo => 1 error
PRINT '--- F-3.13.91 publicidad.pieza_publicitaria_insertar: Pais mercado nulo';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', NULL, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.92 publicidad.pieza_publicitaria_insertar: Pais mercado que no es de interes de la campaña => 1 error
PRINT '--- F-3.13.92 publicidad.pieza_publicitaria_insertar: Pais mercado que no es de interes de la campaña';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p4, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.93 publicidad.pieza_publicitaria_insertar: Pais mercado de interes de OTRA campaña, no de esta => 1 error
PRINT '--- F-3.13.93 publicidad.pieza_publicitaria_insertar: Pais mercado de interes de OTRA campaña, no de esta';
DECLARE @co INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_OTRA'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @co, 'ingles', @p2, 500, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.94 publicidad.pieza_publicitaria_insertar: Tarifa nula => 1 error
PRINT '--- F-3.13.94 publicidad.pieza_publicitaria_insertar: Tarifa nula';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p2, NULL, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.95 publicidad.pieza_publicitaria_insertar: Tarifa negativa => 1 error
PRINT '--- F-3.13.95 publicidad.pieza_publicitaria_insertar: Tarifa negativa';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p2, -1, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.96 publicidad.pieza_publicitaria_insertar: Duplicado: la campaña ya tiene 'espanol' para ese mercado => 1 error
PRINT '--- F-3.13.96 publicidad.pieza_publicitaria_insertar: Duplicado: la campaña ya tiene ''espanol'' para ese mercado';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'espanol', @p1, 1000, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.97 publicidad.pieza_publicitaria_insertar: campaña inexistente, idioma vacio, tarifa negativa => 3 errores
PRINT '--- F-3.13.97 publicidad.pieza_publicitaria_insertar: 3 errores: campaña inexistente, idioma vacio, tarifa negativa';
DECLARE @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar 999999, '', @p1, -1, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.98 publicidad.pieza_publicitaria_insertar: campaña nula, idioma nulo, pais nulo, tarifa nula => 4 errores
PRINT '--- F-3.13.98 publicidad.pieza_publicitaria_insertar: 4 errores: campaña nula, idioma nulo, pais nulo, tarifa nula';
DECLARE @pz INT;
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar NULL, NULL, NULL, NULL, @pz OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.pieza_publicitaria_modificar: F-3.13.99 a F-3.13.121
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.99 publicidad.pieza_publicitaria_modificar: Pieza inexistente => 1 error
PRINT '--- F-3.13.99 publicidad.pieza_publicitaria_modificar: Pieza inexistente';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar 999999, @c1, 'italiano', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.100 publicidad.pieza_publicitaria_modificar: Id nulo => 1 error
PRINT '--- F-3.13.100 publicidad.pieza_publicitaria_modificar: Id nulo';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar NULL, @c1, 'italiano', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.101 publicidad.pieza_publicitaria_modificar: Campaña inexistente => 1 error
PRINT '--- F-3.13.101 publicidad.pieza_publicitaria_modificar: Campaña inexistente';
DECLARE @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, 999999, 'ingles', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.102 publicidad.pieza_publicitaria_modificar: Campaña nula => 1 error
PRINT '--- F-3.13.102 publicidad.pieza_publicitaria_modificar: Campaña nula';
DECLARE @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, NULL, 'ingles', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.103 publicidad.pieza_publicitaria_modificar: Idioma vacio => 1 error
PRINT '--- F-3.13.103 publicidad.pieza_publicitaria_modificar: Idioma vacio';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, '', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.104 publicidad.pieza_publicitaria_modificar: Idioma nulo => 1 error
PRINT '--- F-3.13.104 publicidad.pieza_publicitaria_modificar: Idioma nulo';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, NULL, @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.105 publicidad.pieza_publicitaria_modificar: Idioma solo espacios => 1 error
PRINT '--- F-3.13.105 publicidad.pieza_publicitaria_modificar: Idioma solo espacios';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, '   ', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.106 publicidad.pieza_publicitaria_modificar: Idioma con numero => 1 error
PRINT '--- F-3.13.106 publicidad.pieza_publicitaria_modificar: Idioma con numero';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingl3s', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.107 publicidad.pieza_publicitaria_modificar: Idioma con espacio => 1 error
PRINT '--- F-3.13.107 publicidad.pieza_publicitaria_modificar: Idioma con espacio';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles uk', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.108 publicidad.pieza_publicitaria_modificar: Idioma de 11 letras => 1 error
PRINT '--- F-3.13.108 publicidad.pieza_publicitaria_modificar: Idioma de 11 letras';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'abcdefghijk', @p1, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.109 publicidad.pieza_publicitaria_modificar: Pais mercado inexistente => 1 error
PRINT '--- F-3.13.109 publicidad.pieza_publicitaria_modificar: Pais mercado inexistente';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', 999999, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.110 publicidad.pieza_publicitaria_modificar: Pais mercado nulo => 1 error
PRINT '--- F-3.13.110 publicidad.pieza_publicitaria_modificar: Pais mercado nulo';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', NULL, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.111 publicidad.pieza_publicitaria_modificar: Pais mercado que no es de interes de la campaña => 1 error
PRINT '--- F-3.13.111 publicidad.pieza_publicitaria_modificar: Pais mercado que no es de interes de la campaña';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p4, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.112 publicidad.pieza_publicitaria_modificar: Mercado @p2 no es de interes de la campaña destino => 1 error
PRINT '--- F-3.13.112 publicidad.pieza_publicitaria_modificar: Mercado @p2 no es de interes de la campaña destino';
DECLARE @cd INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_DEST'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @cd, 'ingles', @p2, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.113 publicidad.pieza_publicitaria_modificar: Tarifa nula => 1 error
PRINT '--- F-3.13.113 publicidad.pieza_publicitaria_modificar: Tarifa nula';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.114 publicidad.pieza_publicitaria_modificar: Tarifa negativa => 1 error
PRINT '--- F-3.13.114 publicidad.pieza_publicitaria_modificar: Tarifa negativa';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.115 publicidad.pieza_publicitaria_modificar: Duplicado: m2 ya es 'frances' en ese mercado => 1 error
PRINT '--- F-3.13.115 publicidad.pieza_publicitaria_modificar: Duplicado: m2 ya es ''frances'' en ese mercado';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'frances', @p2, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.116 publicidad.pieza_publicitaria_modificar: Duplicado con otra capitalizacion => 1 error
PRINT '--- F-3.13.116 publicidad.pieza_publicitaria_modificar: Duplicado con otra capitalizacion';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'FRANCES', @p2, 1000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.117 publicidad.pieza_publicitaria_modificar: Pieza con espacio: no puede cambiar de mercado => 1 error
PRINT '--- F-3.13.117 publicidad.pieza_publicitaria_modificar: Pieza con espacio: no puede cambiar de mercado';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @m3 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m3, @c1, 'aleman', @p2, 3000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.118 publicidad.pieza_publicitaria_modificar: Pieza con espacio: no puede cambiar de campaña => 1 error
PRINT '--- F-3.13.118 publicidad.pieza_publicitaria_modificar: Pieza con espacio: no puede cambiar de campaña';
DECLARE @cd INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_DEST'),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
        @m3 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m3, @cd, 'aleman', @p3, 3000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.119 publicidad.pieza_publicitaria_modificar: pieza con espacio cambia de campaña y tarifa negativa => 2 errores
PRINT '--- F-3.13.119 publicidad.pieza_publicitaria_modificar: 2 errores: pieza con espacio cambia de campaña y tarifa negativa';
DECLARE @cd INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_DEST'),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
        @m3 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m3, @cd, 'aleman', @p3, -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.120 publicidad.pieza_publicitaria_modificar: idioma invalido, mercado que no es de interes, tarifa negativa => 3 errores
PRINT '--- F-3.13.120 publicidad.pieza_publicitaria_modificar: 3 errores: idioma invalido, mercado que no es de interes, tarifa negativa';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingl3s', @p4, -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.121 publicidad.pieza_publicitaria_modificar: pieza, campaña, idioma, pais inexistentes y tarifa negativa => 5 errores
PRINT '--- F-3.13.121 publicidad.pieza_publicitaria_modificar: 5 errores: pieza, campaña, idioma, pais inexistentes y tarifa negativa';
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar 999999, 999999, '', 999999, -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.pieza_publicitaria_eliminar: F-3.13.122 a F-3.13.124
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.122 publicidad.pieza_publicitaria_eliminar: Pieza inexistente => 1 error
PRINT '--- F-3.13.122 publicidad.pieza_publicitaria_eliminar: Pieza inexistente';
BEGIN TRY EXEC publicidad.pieza_publicitaria_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.123 publicidad.pieza_publicitaria_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.13.123 publicidad.pieza_publicitaria_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC publicidad.pieza_publicitaria_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.124 publicidad.pieza_publicitaria_eliminar: Esta asignada a espacios publicitarios de partidos => 1 error
PRINT '--- F-3.13.124 publicidad.pieza_publicitaria_eliminar: Esta asignada a espacios publicitarios de partidos';
DECLARE @e2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM') AND idioma = 'ingles');
BEGIN TRY EXEC publicidad.pieza_publicitaria_eliminar @e2; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

PRINT '--- P-3.25 Preparación de espacio_publicitario* (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
EXEC publicidad.anunciante_insertar 'ESP', NULL, NULL;
GO
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'ESP'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pa INT = (SELECT p.partido_id FROM torneo.partido p
                   WHERE NOT EXISTS (SELECT 1 FROM publicidad.espacio_publicitario e WHERE e.partido_id = p.partido_id)
                   ORDER BY p.partido_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pb INT = (SELECT p.partido_id FROM torneo.partido p
                   WHERE NOT EXISTS (SELECT 1 FROM publicidad.espacio_publicitario e WHERE e.partido_id = p.partido_id)
                   ORDER BY p.partido_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @pc INT = (SELECT p.partido_id FROM torneo.partido p
                   WHERE NOT EXISTS (SELECT 1 FROM publicidad.espacio_publicitario e WHERE e.partido_id = p.partido_id)
                   ORDER BY p.partido_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
IF @pc IS NULL THROW 50000, 'Se necesitan al menos 3 partidos sin espacios publicitarios.', 1;

DECLARE @ini DATE, @fin DATE, @fi DATE, @ff DATE, @fx DATETIMEOFFSET, @v INT, @fu INT, @esp INT,
        @z1 INT, @z2 INT, @z3 INT, @z4 INT, @z5 INT, @z6 INT, @z7 INT, @zf INT;
SELECT @ini = DATEADD(DAY, -1, MIN(CAST(fecha_hora_utc AS DATE))),
       @fin = DATEADD(DAY, 1, MAX(CAST(fecha_hora_utc AS DATE)))
FROM torneo.partido WHERE partido_id IN (@pa, @pb, @pc);
SET @fi = DATEADD(DAY, 30, @fin);
SET @ff = DATEADD(DAY, 40, @fin);
SELECT @fx = fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc;

EXEC publicidad.campania_insertar @a, 'ESP_VIG', @ini, @fin, @v OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @v, @p1;
EXEC publicidad.pieza_publicitaria_insertar @v, 'espanol',   @p1, 1000, @z1 OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @v, 'ingles',    @p1, 1000, @z2 OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @v, 'frances',   @p1, 1000, @z3 OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @v, 'aleman',    @p1, 1000, @z4 OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @v, 'japones',   @p1, 1000, @z5 OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @v, 'italiano',  @p1, 1000, @z6 OUTPUT;
EXEC publicidad.pieza_publicitaria_insertar @v, 'portugues', @p1, 1000, @z7 OUTPUT;

EXEC publicidad.campania_insertar @a, 'ESP_FUERA', @fi, @ff, @fu OUTPUT;
EXEC publicidad.campania_pais_interes_insertar @fu, @p1;
EXEC publicidad.pieza_publicitaria_insertar @fu, 'espanol', @p1, 1000, @zf OUTPUT;

EXEC publicidad.espacio_publicitario_insertar @pa, 1, @z1, NULL, @esp OUTPUT;
EXEC publicidad.espacio_publicitario_insertar @pb, 4, @z6, NULL, @esp OUTPUT;
EXEC publicidad.espacio_publicitario_insertar @pc, 1, @z2, NULL, @esp OUTPUT;
EXEC publicidad.espacio_publicitario_insertar @pc, 2, @z3, NULL, @esp OUTPUT;
EXEC publicidad.espacio_publicitario_modificar @esp, @z3, NULL, @fx, 1, 10000;   
EXEC publicidad.espacio_publicitario_insertar @pc, 3, @z4, NULL, @esp OUTPUT;
EXEC publicidad.espacio_publicitario_insertar @pc, 4, @z5, NULL, @esp OUTPUT;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.espacio_publicitario_insertar: F-3.13.125 a F-3.13.138
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.125 publicidad.espacio_publicitario_insertar: Partido inexistente => 1 error
PRINT '--- F-3.13.125 publicidad.espacio_publicitario_insertar: Partido inexistente';
DECLARE @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar 999999, 1, NULL, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.126 publicidad.espacio_publicitario_insertar: Partido nulo => 1 error
PRINT '--- F-3.13.126 publicidad.espacio_publicitario_insertar: Partido nulo';
DECLARE @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar NULL, 1, NULL, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.127 publicidad.espacio_publicitario_insertar: Numero de espacio 0 (fuera de rango) => 1 error
PRINT '--- F-3.13.127 publicidad.espacio_publicitario_insertar: Numero de espacio 0 (fuera de rango)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 0, NULL, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.128 publicidad.espacio_publicitario_insertar: Numero de espacio 5 (fuera de rango) => 1 error
PRINT '--- F-3.13.128 publicidad.espacio_publicitario_insertar: Numero de espacio 5 (fuera de rango)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 5, NULL, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.129 publicidad.espacio_publicitario_insertar: Numero de espacio nulo => 1 error
PRINT '--- F-3.13.129 publicidad.espacio_publicitario_insertar: Numero de espacio nulo';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, NULL, NULL, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.130 publicidad.espacio_publicitario_insertar: Espacio duplicado => 1 error
PRINT '--- F-3.13.130 publicidad.espacio_publicitario_insertar: Espacio duplicado';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 1, NULL, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.131 publicidad.espacio_publicitario_insertar: Prioridad 0 (fuera de rango) => 1 error
PRINT '--- F-3.13.131 publicidad.espacio_publicitario_insertar: Prioridad 0 (fuera de rango)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 2, NULL, 0, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.132 publicidad.espacio_publicitario_insertar: Prioridad 5 (fuera de rango) => 1 error
PRINT '--- F-3.13.132 publicidad.espacio_publicitario_insertar: Prioridad 5 (fuera de rango)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 2, NULL, 5, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.133 publicidad.espacio_publicitario_insertar: Pieza inexistente => 1 error
PRINT '--- F-3.13.133 publicidad.espacio_publicitario_insertar: Pieza inexistente';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 2, 999999, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.134 publicidad.espacio_publicitario_insertar: Campaña de la pieza no vigente en la fecha del partido => 1 error
PRINT '--- F-3.13.134 publicidad.espacio_publicitario_insertar: Campaña de la pieza no vigente en la fecha del partido';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG'),
        @fuera INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_FUERA');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol'),
        @zf INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @fuera);
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 2, @zf, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.135 publicidad.espacio_publicitario_insertar: La pieza ya ocupa otro espacio del mismo partido => 1 error
PRINT '--- F-3.13.135 publicidad.espacio_publicitario_insertar: La pieza ya ocupa otro espacio del mismo partido';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 2, @z1, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.136 publicidad.espacio_publicitario_insertar: espacio duplicado y pieza ya ocupa otro espacio => 2 errores
PRINT '--- F-3.13.136 publicidad.espacio_publicitario_insertar: 2 errores: espacio duplicado y pieza ya ocupa otro espacio';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 1, @z1, NULL, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.137 publicidad.espacio_publicitario_insertar: numero fuera de rango, prioridad fuera de rango y pieza inexistente => 3 errores
PRINT '--- F-3.13.137 publicidad.espacio_publicitario_insertar: 3 errores: numero fuera de rango, prioridad fuera de rango y pieza inexistente';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol');
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pa, 0, 999999, 9, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.138 publicidad.espacio_publicitario_insertar: partido inexistente, numero, prioridad y pieza inexistente => 4 errores
PRINT '--- F-3.13.138 publicidad.espacio_publicitario_insertar: 4 errores: partido inexistente, numero, prioridad y pieza inexistente';
DECLARE @esp INT;
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar 999999, 7, 999999, 9, @esp OUTPUT; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.espacio_publicitario_modificar: F-3.13.139 a F-3.13.158
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.139 publicidad.espacio_publicitario_modificar: Espacio inexistente => 1 error
PRINT '--- F-3.13.139 publicidad.espacio_publicitario_modificar: Espacio inexistente';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles');
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar 999999, @z2, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.140 publicidad.espacio_publicitario_modificar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.13.140 publicidad.espacio_publicitario_modificar: Id nulo (el mensaje dice "(nulo)")';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles');
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar NULL, @z2, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.141 publicidad.espacio_publicitario_modificar: Pieza inexistente => 1 error
PRINT '--- F-3.13.141 publicidad.espacio_publicitario_modificar: Pieza inexistente';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, 999999, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.142 publicidad.espacio_publicitario_modificar: Campaña de la pieza no vigente en la fecha del partido => 1 error
PRINT '--- F-3.13.142 publicidad.espacio_publicitario_modificar: Campaña de la pieza no vigente en la fecha del partido';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG'),
        @fuera INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_FUERA');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances'),
        @zf INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @fuera);
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @zf, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.143 publicidad.espacio_publicitario_modificar: La pieza ya ocupa otro espacio del partido => 1 error
PRINT '--- F-3.13.143 publicidad.espacio_publicitario_modificar: La pieza ya ocupa otro espacio del partido';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z3, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.144 publicidad.espacio_publicitario_modificar: Prioridad 0 (fuera de rango) => 1 error
PRINT '--- F-3.13.144 publicidad.espacio_publicitario_modificar: Prioridad 0 (fuera de rango)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.145 publicidad.espacio_publicitario_modificar: Prioridad 5 (fuera de rango) => 1 error
PRINT '--- F-3.13.145 publicidad.espacio_publicitario_modificar: Prioridad 5 (fuera de rango)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 5; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.146 publicidad.espacio_publicitario_modificar: Espacio ya facturado: no se puede cambiar la pieza => 1 error
PRINT '--- F-3.13.146 publicidad.espacio_publicitario_modificar: Espacio ya facturado: no se puede cambiar la pieza';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances'),
        @z7 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'portugues');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @ef INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 2),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @ef, @z7, NULL, @fx, 1, 10000; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.147 publicidad.espacio_publicitario_modificar: Facturado sin pieza, fecha ni monto (un solo mensaje) => 1 error
PRINT '--- F-3.13.147 publicidad.espacio_publicitario_modificar: Facturado sin pieza, fecha ni monto (un solo mensaje)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, NULL, NULL, NULL, 1, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.148 publicidad.espacio_publicitario_modificar: Facturado sin fecha de exhibicion => 1 error
PRINT '--- F-3.13.148 publicidad.espacio_publicitario_modificar: Facturado sin fecha de exhibicion';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, 1, 100; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.149 publicidad.espacio_publicitario_modificar: Facturado sin monto => 1 error
PRINT '--- F-3.13.149 publicidad.espacio_publicitario_modificar: Facturado sin monto';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, @fx, 1, NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.150 publicidad.espacio_publicitario_modificar: Monto informado con facturado = 0 => 1 error
PRINT '--- F-3.13.150 publicidad.espacio_publicitario_modificar: Monto informado con facturado = 0';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, @fx, 0, 100; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.151 publicidad.espacio_publicitario_modificar: Monto informado con facturado NULL => 1 error
PRINT '--- F-3.13.151 publicidad.espacio_publicitario_modificar: Monto informado con facturado NULL';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, NULL, 100; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.152 publicidad.espacio_publicitario_modificar: Monto negativo (con facturado completo) => 1 error
PRINT '--- F-3.13.152 publicidad.espacio_publicitario_modificar: Monto negativo (con facturado completo)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, @fx, 1, -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.153 publicidad.espacio_publicitario_modificar: Fecha de exhibicion en un espacio sin pieza => 1 error
PRINT '--- F-3.13.153 publicidad.espacio_publicitario_modificar: Fecha de exhibicion en un espacio sin pieza';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, NULL, NULL, @fx; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.154 publicidad.espacio_publicitario_modificar: espacio inexistente, prioridad fuera de rango y fecha sin pieza => 3 errores
PRINT '--- F-3.13.154 publicidad.espacio_publicitario_modificar: 3 errores: espacio inexistente, prioridad fuera de rango y fecha sin pieza';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar 999999, NULL, 9, @fx; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.155 publicidad.espacio_publicitario_modificar: pieza ya ocupa otro espacio y prioridad fuera de rango => 2 errores
PRINT '--- F-3.13.155 publicidad.espacio_publicitario_modificar: 2 errores: pieza ya ocupa otro espacio y prioridad fuera de rango';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z3, 0; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.156 publicidad.espacio_publicitario_modificar: monto con facturado = 0 y monto negativo => 2 errores
PRINT '--- F-3.13.156 publicidad.espacio_publicitario_modificar: 2 errores: monto con facturado = 0 y monto negativo';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, @fx, 0, -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.157 publicidad.espacio_publicitario_modificar: pieza inexistente, prioridad fuera de rango y monto negativo => 3 errores
PRINT '--- F-3.13.157 publicidad.espacio_publicitario_modificar: 3 errores: pieza inexistente, prioridad fuera de rango y monto negativo';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, 999999, 0, @fx, 1, -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.158 publicidad.espacio_publicitario_modificar: prioridad, facturado sin pieza, monto negativo y fecha sin pieza => 4 errores
PRINT '--- F-3.13.158 publicidad.espacio_publicitario_modificar: 4 errores: prioridad, facturado sin pieza, monto negativo y fecha sin pieza';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, NULL, 9, @fx, 1, -1; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- -------------------------------------------------------------------------------------
-- publicidad.espacio_publicitario_eliminar: F-3.13.159 a F-3.13.161
-- -------------------------------------------------------------------------------------
-- Cada caso muestra el mensaje con el que el SP rechaza la entrada.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).

-- F-3.13.159 publicidad.espacio_publicitario_eliminar: Espacio inexistente => 1 error
PRINT '--- F-3.13.159 publicidad.espacio_publicitario_eliminar: Espacio inexistente';
BEGIN TRY EXEC publicidad.espacio_publicitario_eliminar 999999; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.160 publicidad.espacio_publicitario_eliminar: Id nulo (el mensaje dice "(nulo)") => 1 error
PRINT '--- F-3.13.160 publicidad.espacio_publicitario_eliminar: Id nulo (el mensaje dice "(nulo)")';
BEGIN TRY EXEC publicidad.espacio_publicitario_eliminar NULL; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

-- F-3.13.161 publicidad.espacio_publicitario_eliminar: Espacio ya facturado (historial de facturacion) => 1 error
PRINT '--- F-3.13.161 publicidad.espacio_publicitario_eliminar: Espacio ya facturado (historial de facturacion)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @ef INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 2);
BEGIN TRY EXEC publicidad.espacio_publicitario_eliminar @ef; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;
GO

SET NOEXEC OFF;
GO

-- =====================================================================================
-- RESET: VOLVER LA BASE AL ESTADO INICIAL (ejecutar al terminar todos los casos)
-- Borra todos los datos que dejaron las pruebas (primero las tablas hijas), reinicia los
-- contadores de identidad, elimina las tablas auxiliares del esquema prueba y vuelve a
-- cargar torneo.parametro desde el archivo entrega5_datos_iniciales.csv (es lo unico que
-- trae la base recien creada). Deja la base lista para repetir las pruebas.
-- No requiere el Modo SQLCMD. La ruta del CSV (paso 4/4) es absoluta: editarla si el proyecto
-- esta en otra carpeta.
-- =====================================================================================
PRINT '--- RESET 1/4: borrado de los datos de las pruebas (hijas primero)';
DELETE FROM evento.gol;
DELETE FROM evento.sustitucion;
DELETE FROM arbitraje.informe_arbitral;
DELETE FROM evento.suspension;
DELETE FROM plantel.formacion_jugador;
DELETE FROM arbitraje.designacion_arbitral;
DELETE FROM evento.tarjeta;
DELETE FROM plantel.formacion;
DELETE FROM publicidad.espacio_publicitario;
DELETE FROM arbitraje.arbitro_idioma;
DELETE FROM plantel.convocatoria;
DELETE FROM plantel.cuerpo_tecnico;
DELETE FROM publicidad.campania_pais_interes;
DELETE FROM publicidad.pieza_publicitaria;
DELETE FROM torneo.partido;
DELETE FROM arbitraje.arbitro;
DELETE FROM plantel.jugador;
DELETE FROM publicidad.campania;
DELETE FROM torneo.sede;
DELETE FROM torneo.seleccion;
DELETE FROM evento.criterio_suspension;
DELETE FROM plantel.persona;
DELETE FROM publicidad.anunciante;
DELETE FROM torneo.confederacion;
DELETE FROM torneo.pais;
GO

PRINT '--- RESET 2/4: reinicio de los contadores de identidad (el proximo id vuelve a ser 1)';
-- Solo se reinician las tablas que ya generaron algun id (last_value no nulo).
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('evento.gol')) IS NOT NULL DBCC CHECKIDENT ('evento.gol', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('evento.sustitucion')) IS NOT NULL DBCC CHECKIDENT ('evento.sustitucion', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('arbitraje.informe_arbitral')) IS NOT NULL DBCC CHECKIDENT ('arbitraje.informe_arbitral', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('evento.suspension')) IS NOT NULL DBCC CHECKIDENT ('evento.suspension', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('arbitraje.designacion_arbitral')) IS NOT NULL DBCC CHECKIDENT ('arbitraje.designacion_arbitral', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('evento.tarjeta')) IS NOT NULL DBCC CHECKIDENT ('evento.tarjeta', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('plantel.formacion')) IS NOT NULL DBCC CHECKIDENT ('plantel.formacion', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('publicidad.espacio_publicitario')) IS NOT NULL DBCC CHECKIDENT ('publicidad.espacio_publicitario', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('plantel.convocatoria')) IS NOT NULL DBCC CHECKIDENT ('plantel.convocatoria', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('plantel.cuerpo_tecnico')) IS NOT NULL DBCC CHECKIDENT ('plantel.cuerpo_tecnico', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('publicidad.pieza_publicitaria')) IS NOT NULL DBCC CHECKIDENT ('publicidad.pieza_publicitaria', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('torneo.partido')) IS NOT NULL DBCC CHECKIDENT ('torneo.partido', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('arbitraje.arbitro')) IS NOT NULL DBCC CHECKIDENT ('arbitraje.arbitro', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('plantel.jugador')) IS NOT NULL DBCC CHECKIDENT ('plantel.jugador', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('publicidad.campania')) IS NOT NULL DBCC CHECKIDENT ('publicidad.campania', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('torneo.sede')) IS NOT NULL DBCC CHECKIDENT ('torneo.sede', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('torneo.seleccion')) IS NOT NULL DBCC CHECKIDENT ('torneo.seleccion', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('evento.criterio_suspension')) IS NOT NULL DBCC CHECKIDENT ('evento.criterio_suspension', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('plantel.persona')) IS NOT NULL DBCC CHECKIDENT ('plantel.persona', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('publicidad.anunciante')) IS NOT NULL DBCC CHECKIDENT ('publicidad.anunciante', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('torneo.confederacion')) IS NOT NULL DBCC CHECKIDENT ('torneo.confederacion', RESEED, 0) WITH NO_INFOMSGS;
IF (SELECT last_value FROM sys.identity_columns WHERE object_id = OBJECT_ID('torneo.pais')) IS NOT NULL DBCC CHECKIDENT ('torneo.pais', RESEED, 0) WITH NO_INFOMSGS;
GO

PRINT '--- RESET 3/4: eliminacion de las tablas auxiliares de las pruebas (esquema prueba)';
DROP TABLE IF EXISTS prueba.test_arbitraje;
DROP TABLE IF EXISTS prueba.test_criterio;
DROP TABLE IF EXISTS prueba.test_fjugador;
DROP TABLE IF EXISTS prueba.test_formacion;
DROP TABLE IF EXISTS prueba.test_gol;
DROP TABLE IF EXISTS prueba.test_persona;
DROP TABLE IF EXISTS prueba.test_suspension;
DROP TABLE IF EXISTS prueba.test_sustitucion;
DROP TABLE IF EXISTS prueba.test_tarjeta;
DROP TABLE IF EXISTS prueba.id;
DROP SCHEMA IF EXISTS prueba;
GO

PRINT '--- RESET 4/4: torneo.parametro vuelve a cargarse desde el CSV';
DELETE FROM torneo.parametro;
BULK INSERT torneo.parametro FROM 'C:\Users\luzar\Desktop\GRUPO-08-BBDD\src\entrega5\entrega5_datos_iniciales.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ';', ROWTERMINATOR = '0x0d0a', CODEPAGE = '65001');  -- el CSV tiene fin de línea CRLF
-- SELECT clave, valor, descripcion FROM torneo.parametro ORDER BY clave;   -- 11 filas
GO

PRINT 'mundial_2026 en estado inicial.';
GO
