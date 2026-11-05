-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 5: Base de Datos - LOTES DE PRUEBA: CASOS EXITOSOS
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Pruebas de lo que los SP de entrega5_sp_ABM.sql y entrega5_sp_logica_negocio.sql deben ACEPTAR.
--   Las validaciones que deben rechazarse están en entrega5_test_fallidos.sql.
--     PARTE 1: SP de ABM sobre un escenario encadenado (Argentina, Francia, México y Japón; partidos P1 a P4).
--     PARTE 2: SP de lógica de negocio sobre el mismo escenario, incluidos los casos obligatorios de la sección IV.
--     PARTE 3: casos detallados por SP (bordes y variantes válidas), con sus propios datos de prueba.
--
-- IDENTIFICACIÓN DE LOS CASOS:
--   No es un reporte: cada caso ejecuta la operación y nada más (no hay tablas de control ni resumen final).
--   Si un SP rechazara una operación válida, el error se ve en Mensajes, en el caso que lo provocó.
--   Cada caso es un bloque propio que termina en GO:
--     -- E-3.13.14 publicidad.campania_eliminar: Baja valida => se acepta     (comentario de identificación)
--     PRINT '--- E-3.13.14 ...';                                               (identifica el caso en Mensajes)
--     DECLARE ...                                                              (solo las variables que usa)
--     EXEC publicidad.campania_eliminar @e;                                    (la operación que se prueba)
--     -- DECLARE @e_r1 INT = IDENT_CURRENT('publicidad.campania');             (variables del SELECT, comentadas)
--     -- SELECT * FROM publicidad.campania WHERE campania_id = @e_r1;          (resultado del ABM, comentado)
--     GO
--   Después de cada ABM exitoso (insertar, modificar, eliminar y los SP de lógica de negocio que escriben) hay
--   un SELECT COMENTADO que demuestra el efecto que causó: por ejemplo, si se agregó una fila, el SELECT de
--   abajo la muestra. Arriba de cada SELECT hay sus DECLARE comentados (variables con sufijo _r1, _r2...,
--   que buscan el registro por su id o su clave), así que se puede ejecutar SOLO: ejecutar el bloque del
--   caso, seleccionar esas líneas, descomentarlas (Ctrl+K, Ctrl+U) y ejecutar la selección; el resultado
--   aparece en Resultados. Si el ABM fue una baja, el SELECT no devuelve filas (el registro ya no existe).
--   Los SP *_validar no escriben: muestran con PRINT @e los errores que encuentran (en estos casos, ninguno).
--     Lote 0       crea el esquema prueba y la tabla prueba.id (ids del escenario de las Partes 1 y 2)
--     E-x.y.nn     caso exitoso de la sección x.y
--     P-x.y.nn     preparación de datos (no es un caso de prueba)
--
-- ÍNDICE (sección, ids):
--   1.1   torneo.parametro                                               E-1.1.01
--   1.2   torneo.pais y torneo.confederacion                             E-1.2.01 a E-1.2.02
--   1.3   torneo.sede                                                    E-1.3.01
--   1.4   torneo.seleccion                                               E-1.4.01
--   1.5   torneo.partido                                                 E-1.5.01
--   1.6   plantel.persona, plantel.cuerpo_tecnico y plantel.jugador      E-1.6.01 a E-1.6.03
--   1.7   plantel.convocatoria                                           E-1.7.01 a E-1.7.02
--   1.8   plantel.formacion y plantel.formacion_jugador                  P-1.8.01; E-1.8.01 a E-1.8.02
--   1.9   evento.sustitucion                                             E-1.9.01
--   1.10  evento.gol                                                     E-1.10.01 a E-1.10.02
--   1.11  evento.tarjeta, evento.criterio_suspension y evento.suspension E-1.11.01 a E-1.11.03
--   1.12  arbitraje: arbitro, arbitro_idioma, designacion_arbitral e inf E-1.12.01 a E-1.12.02
--   1.13  publicidad: anunciante, campania, campania_pais_interes, pieza E-1.13.01 a E-1.13.02
--   2.1   plantel.reemplazar_convocado                                   E-2.1.01
--   2.2   plantel.cargar_formacion                                       E-2.2.01
--   2.3   evento.registrar_sustitucion                                   E-2.3.01 a E-2.3.02
--   2.4   evento.registrar_gol                                           E-2.4.01
--   2.5   evento.registrar_tarjeta                                       E-2.5.01 a E-2.5.03
--   2.6   publicidad.asignar_espacios_partido                            E-2.6.01 a E-2.6.02
--   2.7   torneo.registrar_resultado                                     E-2.7.01
--   2.8   Acumulación de amarillas, doble amarilla y jugador suspendido  E-2.8.01 a E-2.8.04
--   2.9   arbitraje.designar_arbitros                                    E-2.9.01
--   2.10  Partido de eliminación directa completo                        E-2.10.01 a E-2.10.04
--   2.11  Transaccionalidad: todo o nada en operaciones que afectan vari E-2.11.01
--   3.0   Preparación de los datos de la Parte 3                         P-3.01 a P-3.16
--   3.1   torneo.parametro                                               E-3.1.01 a E-3.1.14
--   3.2   torneo.pais y torneo.confederacion                             E-3.2.01 a E-3.2.24
--   3.3   torneo.sede                                                    E-3.3.01 a E-3.3.06
--   3.4   torneo.seleccion                                               E-3.4.01 a E-3.4.06
--   3.5   torneo.partido                                                 E-3.5.01 a E-3.5.10
--   3.6   plantel.persona, plantel.cuerpo_tecnico y plantel.jugador      E-3.6.01 a E-3.6.37
--   3.7   plantel.convocatoria                                           E-3.7.01 a E-3.7.28
--   3.8   plantel.formacion y plantel.formacion_jugador                  E-3.8.01 a E-3.8.25
--   3.9   evento.sustitucion                                             E-3.9.01 a E-3.9.13
--   3.10  evento.gol                                                     E-3.10.01 a E-3.10.39
--   3.11  evento.tarjeta, evento.criterio_suspension y evento.suspension P-3.17; E-3.11.01 a E-3.11.39
--   3.12  arbitraje: arbitro, arbitro_idioma, designacion_arbitral e inf P-3.18; E-3.12.01 a E-3.12.35
--   3.13  publicidad: anunciante, campania, campania_pais_interes, pieza P-3.19 a P-3.25; E-3.13.01 a E-3.13.46
--
-- CÓMO EJECUTARLO:
--   Todo junto: con la base recién creada (entrega5_db_definition.sql, entrega5_sp_ABM.sql y entrega5_sp_logica_negocio.sql) ejecutar este archivo
--   completo, de una vez. Al final tiene el bloque RESET, que vuelve la base al estado inicial.
--   De a un caso: seleccionar el bloque del caso (desde su comentario de identificación hasta su GO, buscar el
--   id con Ctrl+F) y ejecutar la selección. Cada bloque declara sus propias variables y toma los ids de la base
--   (de las tablas del modelo o de prueba.id y prueba.test_*), así que no depende de la ventana de consulta.
--   Sí importa el ORDEN: las Partes 1 y 2 son un escenario encadenado (cada caso va después de los anteriores,
--   ver su línea "Requiere") y los casos de la Parte 3 usan los datos de las preparaciones P-3.xx y se aplican
--   en orden. Para volver al estado inicial: ejecutar el bloque RESET del final de este archivo.
--   Los datos se cargan a través de los SP. Las únicas sentencias directas son las de algunas
--   preparaciones de la Parte 3, que dejan partidos de prueba en estado 'finalizado'.
-- ============================================================


USE mundial_2026;
GO

SET NOCOUNT ON;
GO

PRINT '--- Control de la ejecución completa: la base tiene que estar recién creada';
-- Al ejecutar el archivo completo sobre una base con datos, avisa y no ejecuta nada más.
-- (Al ejecutar casos sueltos se puede omitir este lote.)
IF EXISTS (SELECT 1 FROM torneo.pais)
BEGIN
    RAISERROR('La base ya tiene datos: ejecutar primero el bloque RESET del final del test para dejarla en estado inicial. No se ejecuta ninguna prueba.', 16, 1);
    SET NOEXEC ON;
END;
GO

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

-- E-1.1.01 Alta, modificación y baja de un parámetro
PRINT '--- E-1.1.01 Alta, modificación y baja de un parámetro';
-- Resultado esperado: el parámetro de prueba se crea con valor 7, pasa a 9 y se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
EXEC torneo.parametro_insertar 'parametro_de_prueba', 7, 'Parámetro creado por el test';
EXEC torneo.parametro_modificar 'parametro_de_prueba', 9;
-- SELECT clave, valor, descripcion FROM torneo.parametro WHERE clave = 'parametro_de_prueba';
EXEC torneo.parametro_eliminar 'parametro_de_prueba';
-- SELECT clave, valor, descripcion FROM torneo.parametro WHERE clave = 'parametro_de_prueba';   -- después de la baja: sin filas
GO

-- ============================================================
-- 1.2 torneo.pais y torneo.confederacion
-- ============================================================

-- E-1.2.01 Alta de países y confederaciones
PRINT '--- E-1.2.01 Alta de países y confederaciones';
-- Resultado esperado: 11 países (uno temporal) y 6 confederaciones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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

-- SELECT pais_id, codigo_iso, nombre, huso_horario, pbi_per_capita FROM torneo.pais ORDER BY pais_id;
-- SELECT confederacion_id, nombre FROM torneo.confederacion ORDER BY confederacion_id;
GO

-- E-1.2.02 Modificación y baja de país; modificación y baja de confederación
PRINT '--- E-1.2.02 Modificación y baja de país; modificación y baja de confederación';
-- Resultado esperado: Argentina queda con PBI 14000; el país temporal y la confederación OFC se eliminan.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ARG'), @zzz INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ZZZ'),
        @ofc INT = (SELECT valor FROM prueba.id WHERE clave = 'conf_OFC');
EXEC torneo.pais_modificar @arg, 'ARG', 'Argentina', 'UTC-03', 14000;
EXEC torneo.pais_eliminar @zzz;
EXEC torneo.confederacion_modificar @ofc, 'OFC';
EXEC torneo.confederacion_eliminar @ofc;
-- SELECT codigo_iso, nombre, pbi_per_capita FROM torneo.pais WHERE codigo_iso IN ('ARG', 'ZZZ');
-- SELECT confederacion_id, nombre FROM torneo.confederacion ORDER BY confederacion_id;
GO

-- ============================================================
-- 1.3 torneo.sede
-- ============================================================

-- E-1.3.01 Alta, modificación y baja de sedes
PRINT '--- E-1.3.01 Alta, modificación y baja de sedes';
-- Resultado esperado: quedan 3 sedes (husos UTC-04 y UTC-06); MetLife pasa a capacidad 82500; la temporal se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT, @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_USA'),
        @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_MEX'), @can INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_CAN');
EXEC torneo.sede_insertar 'MetLife Stadium', 'East Rutherford', @usa, 82000, 'UTC-04', @id OUTPUT; INSERT INTO prueba.id VALUES ('sede_NY', @id);
EXEC torneo.sede_insertar 'Estadio Azteca', 'Ciudad de México', @mex, 83000, 'UTC-06', @id OUTPUT; INSERT INTO prueba.id VALUES ('sede_MX', @id);
EXEC torneo.sede_insertar 'BMO Field', 'Toronto', @can, 45000, 'UTC-04', @id OUTPUT;              INSERT INTO prueba.id VALUES ('sede_TO', @id);
EXEC torneo.sede_insertar 'Estadio temporal', 'Ciudad temporal', @can, 100, 'UTC-04', @id OUTPUT;
EXEC torneo.sede_eliminar @id;
SET @id = (SELECT valor FROM prueba.id WHERE clave = 'sede_NY');
EXEC torneo.sede_modificar @id, 'MetLife Stadium', 'East Rutherford', @usa, 82500, 'UTC-04';
-- SELECT sede_id, nombre, ciudad, capacidad, huso_horario FROM torneo.sede ORDER BY sede_id;
GO

-- ============================================================
-- 1.4 torneo.seleccion
-- ============================================================

-- E-1.4.01 Alta, modificación y baja de selecciones
PRINT '--- E-1.4.01 Alta, modificación y baja de selecciones';
-- Resultado esperado: 4 selecciones en el grupo A y Brasil en el B; la de España (temporal) se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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
-- SELECT s.seleccion_id, p.nombre AS pais, c.nombre AS confederacion, s.grupo
-- FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id JOIN torneo.confederacion c ON c.confederacion_id = s.confederacion_id
-- ORDER BY s.seleccion_id;
GO

-- ============================================================
-- 1.5 torneo.partido
-- ============================================================

-- E-1.5.01 Alta, modificación y baja de partidos
PRINT '--- E-1.5.01 Alta, modificación y baja de partidos';
-- Resultado esperado: 4 partidos programados, con la hora UTC derivada de la hora local
-- (P1 20:00 UTC-04 = 00:00 UTC del día siguiente). P3 se reprograma a las 16:00. El partido temporal se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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
-- SELECT partido_id, fase, fecha_hora_local, fecha_hora_utc, seleccion_local_id, seleccion_visitante_id, estado FROM torneo.partido ORDER BY partido_id;
GO

-- ============================================================
-- 1.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================

-- E-1.6.01 Alta, modificación y baja de cuerpo técnico (crea y borra su persona)
PRINT '--- E-1.6.01 Alta, modificación y baja de cuerpo técnico (crea y borra su persona)';
-- Resultado esperado: 3 integrantes (DT y ayudante de Argentina, DT de Francia), cada uno con su persona 'cuerpo_tecnico'.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT, @persona INT, @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'), @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'FRA');
EXEC plantel.cuerpo_tecnico_insertar @arg, 'Lionel', 'Scaloni', 'director_tecnico', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @arg, 'Pablo', 'Aimar', 'otro', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_modificar @id, @arg, 'Pablo', 'Aimar', 'ayudante_tecnico';
EXEC plantel.cuerpo_tecnico_insertar @fra, 'Didier', 'Deschamps', 'director_tecnico', @id OUTPUT, @persona OUTPUT;
INSERT INTO prueba.id VALUES ('persona_DT_FRA', @persona);
EXEC plantel.cuerpo_tecnico_insertar @fra, 'Temporal', 'Temporal', 'otro', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_eliminar @id;
-- SELECT ct.staff_id, ct.persona_id, pe.tipo_persona, ct.seleccion_id, ct.nombre, ct.apellido, ct.rol
-- FROM plantel.cuerpo_tecnico ct JOIN plantel.persona pe ON pe.persona_id = ct.persona_id ORDER BY ct.staff_id;
GO

-- E-1.6.02 Alta masiva de jugadores (por SP, uno por uno)
PRINT '--- E-1.6.02 Alta masiva de jugadores (por SP, uno por uno)';
-- Resultado esperado: 97 jugadores (27 de ARG, 23 de FRA, 23 de MEX y 24 de JPN), cada uno con su persona 'jugador'.
-- Convención de los datos de prueba: nombre = código del país, apellido = 'Jugador NN' (NN será su dorsal).
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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
-- SELECT nombre AS seleccion, COUNT(*) AS jugadores, MIN(fecha_nacimiento) AS mayor, MAX(fecha_nacimiento) AS menor
-- FROM plantel.jugador GROUP BY nombre ORDER BY nombre;
GO

-- E-1.6.03 Modificación y baja de jugador; ABM de persona
PRINT '--- E-1.6.03 Modificación y baja de jugador; ABM de persona';
-- Resultado esperado: ARG Jugador 10 cambia de club; el jugador temporal se elimina junto con su persona;
-- la persona suelta se crea, se modifica y se elimina. Quedan 97 jugadores y 100 personas.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT, @persona INT;
SELECT @id = jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 10';
EXEC plantel.jugador_modificar @id, 'ARG', 'Jugador 10', '1996-04-04', 'delantero', 'Inter Miami CF';
EXEC plantel.jugador_insertar 'Temporal', 'Temporal', '2000-01-01', 'defensor', NULL, @id OUTPUT, @persona OUTPUT;
EXEC plantel.jugador_eliminar @id;
EXEC plantel.persona_insertar 'jugador', @persona OUTPUT;
EXEC plantel.persona_modificar @persona, 'cuerpo_tecnico';
EXEC plantel.persona_eliminar @persona;
-- SELECT jugador_id, nombre, apellido, fecha_nacimiento, club_origen, posicion_habitual FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 10';
-- DECLARE @persona_r1 INT = IDENT_CURRENT('plantel.persona');
-- SELECT * FROM plantel.persona WHERE persona_id = @persona_r1;
GO

-- ============================================================
-- 1.7 plantel.convocatoria
-- ============================================================

-- E-1.7.01 Alta de convocatorias
PRINT '--- E-1.7.01 Alta de convocatorias';
-- Resultado esperado: ARG 26 convocados (el máximo), FRA 23, MEX 23 y JPN 24, con dorsal = NN del apellido.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @lista TABLE (fila INT IDENTITY(1, 1) PRIMARY KEY, seleccion_id INT, jugador_id INT, dorsal INT);
INSERT INTO @lista (seleccion_id, jugador_id, dorsal)
SELECT s.seleccion_id, j.jugador_id, CAST(RIGHT(j.apellido, 2) AS INT)
FROM plantel.jugador j
JOIN torneo.pais p      ON p.codigo_iso = j.nombre
JOIN torneo.seleccion s ON s.pais_id = p.pais_id
WHERE NOT (j.nombre = 'ARG' AND j.apellido = 'Jugador 27')          -- el 27 de ARG queda sin convocar
ORDER BY s.seleccion_id, j.jugador_id;
DECLARE @i INT = 1, @total INT = (SELECT COUNT(*) FROM @lista), @sel INT, @jug INT, @dorsal INT;
WHILE @i <= @total
BEGIN
    SELECT @sel = seleccion_id, @jug = jugador_id, @dorsal = dorsal FROM @lista WHERE fila = @i;
    EXEC plantel.convocatoria_insertar @sel, @jug, @dorsal, '2026-06-01', 'Lista inicial';
    SET @i += 1;
END;
-- SELECT p.codigo_iso, COUNT(*) AS convocados_vigentes, MIN(c.dorsal) AS dorsal_min, MAX(c.dorsal) AS dorsal_max
-- FROM plantel.convocatoria c JOIN torneo.seleccion s ON s.seleccion_id = c.seleccion_id JOIN torneo.pais p ON p.pais_id = s.pais_id
-- WHERE c.fecha_baja IS NULL GROUP BY p.codigo_iso ORDER BY p.codigo_iso;
GO

-- E-1.7.02 Modificación y baja física de convocatoria
PRINT '--- E-1.7.02 Modificación y baja física de convocatoria';
-- Resultado esperado: el convocado 26 de ARG pasa al dorsal 99; la convocatoria del jugador 24 de JPN se elimina (quedan 23).
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @conv INT;
SELECT @conv = c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE j.nombre = 'ARG' AND j.apellido = 'Jugador 26';
EXEC plantel.convocatoria_modificar @conv, 99, '2026-06-01', 'Lista inicial';
SELECT @conv = c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE j.nombre = 'JPN' AND j.apellido = 'Jugador 24';
EXEC plantel.convocatoria_eliminar @conv;
-- SELECT j.nombre, j.apellido, c.dorsal, c.fecha_alta, c.fecha_baja FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
-- WHERE j.apellido IN ('Jugador 24', 'Jugador 26') AND j.nombre IN ('ARG', 'JPN') ORDER BY j.nombre, j.apellido;
GO

-- ============================================================
-- 1.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================

-- E-1.8.01 Alta y modificación de formación y de sus jugadores
PRINT '--- E-1.8.01 Alta y modificación de formación y de sus jugadores';
-- Resultado esperado: formación visitante (Japón) de P3 con esquema 3-5-2 y 2 jugadores: dorsal 1 titular
-- y dorsal 12 suplente. El dorsal lo completa el SP desde la convocatoria.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'JPN'), @form INT, @j INT;
EXEC plantel.formacion_insertar @p3, 'visitante', '4-4-2', @form OUTPUT;
INSERT INTO prueba.id VALUES ('form_tmp', @form);
EXEC plantel.formacion_modificar @form, '3-5-2';
SELECT @j = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @jpn AND dorsal = 1 AND fecha_baja IS NULL;
EXEC plantel.formacion_jugador_insertar @form, @j, 'arquero', 1;
SELECT @j = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @jpn AND dorsal = 12 AND fecha_baja IS NULL;
EXEC plantel.formacion_jugador_insertar @form, @j, 'arquero', 1;
EXEC plantel.formacion_jugador_modificar @form, @j, 'arquero suplente', 0;
-- DECLARE @form_r1 INT = IDENT_CURRENT('plantel.formacion');
-- SELECT f.formacion_id, f.partido_id, f.condicion, f.esquema_tactico, fj.jugador_id, fj.dorsal, fj.posicion, fj.titular
-- FROM plantel.formacion f JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.formacion_id = @form_r1;
GO

-- E-1.8.02 Baja de jugadores de la formación y de la formación
PRINT '--- E-1.8.02 Baja de jugadores de la formación y de la formación';
-- Resultado esperado: P3 vuelve a quedar sin formaciones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @form INT = (SELECT valor FROM prueba.id WHERE clave = 'form_tmp'), @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @j INT;
SELECT @j = MIN(jugador_id) FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC plantel.formacion_jugador_eliminar @form, @j;
SELECT @j = MIN(jugador_id) FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC plantel.formacion_jugador_eliminar @form, @j;
EXEC plantel.formacion_eliminar @form;
-- DECLARE @p3_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3');
-- SELECT f.formacion_id, f.condicion, fj.jugador_id, fj.dorsal FROM plantel.formacion f
-- LEFT JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.partido_id = @p3_r1;
GO

-- ============================================================
-- PREPARACIÓN: formaciones de P1 (Argentina vs Francia), necesarias para probar el ABM de los
-- eventos. Se cargan con plantel.cargar_formacion, cuyas pruebas propias están en 2.2.
-- Titulares: dorsales 1 a 11. Suplentes: 12 a 23.
-- ============================================================

-- P-1.8.01 Preparación: formaciones de P1 (Argentina vs Francia), necesarias para probar el ABM de los
PRINT '--- P-1.8.01 Preparación: formaciones de P1 (Argentina vs Francia), necesarias para probar el ABM de los';
-- Sin verificaciones: carga las formaciones de P1 con plantel.cargar_formacion (sus pruebas están en 2.2).
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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
-- DECLARE @p1_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT f.formacion_id, f.condicion, f.esquema_tactico, fj.jugador_id, fj.dorsal, fj.posicion, fj.titular FROM plantel.formacion f LEFT JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.partido_id = @p1_r1 ORDER BY f.formacion_id, fj.titular DESC, fj.dorsal;
GO

-- ============================================================
-- 1.9 evento.sustitucion
-- ============================================================

-- E-1.9.01 Alta, modificación y baja de sustitución
PRINT '--- E-1.9.01 Alta, modificación y baja de sustitución';
-- Resultado esperado: queda un cambio de Argentina (sale el 9, entra el 14) en el minuto 62 del ST, ventana 1.
-- El segundo cambio (sale 8, entra 15, ventana 2) se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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
-- SELECT sustitucion_id, formacion_id, jugador_sale_id, jugador_entra_id, minuto, periodo, numero_ventana, motivo FROM evento.sustitucion;
GO

-- ============================================================
-- 1.10 evento.gol (cada operación actualiza el marcador del partido en la misma transacción)
-- ============================================================

-- E-1.10.01 Alta, modificación y baja de gol
PRINT '--- E-1.10.01 Alta, modificación y baja de gol';
-- Resultado esperado: gol del 10 de Argentina con asistencia del 11 (queda como 'cabezazo', minuto 24) => 1 a 0.
-- Un gol en contra del 2 de Francia lleva el marcador a 2 a 0; al eliminarlo vuelve a 1 a 0.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @local INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_local'),
        @visitante INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_visitante'), @gol INT, @tmp INT, @j10 INT, @j11 INT, @f2 INT, @marcador VARCHAR(10);
SELECT @j10 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 10;
SELECT @j11 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 11;
SELECT @f2 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @visitante AND dorsal = 2;
EXEC evento.gol_insertar @local, @j10, 23, 'jugada', 'PT', @j11, @gol OUTPUT;
EXEC evento.gol_modificar @gol, 24, 'cabezazo', 'PT', @j11;
EXEC evento.gol_insertar @visitante, @f2, 35, 'en_contra', 'PT', NULL, @tmp OUTPUT;
SELECT @marcador = CAST(goles_local AS VARCHAR(2)) + '-' + CAST(goles_visitante AS VARCHAR(2)) FROM torneo.partido WHERE partido_id = @p1;
PRINT 'Marcador con el gol en contra: ' + @marcador;
EXEC evento.gol_eliminar @tmp;
-- SELECT g.gol_id, g.formacion_id, g.jugador_id, g.asistencia_jugador_id, g.minuto, g.tipo_gol, g.periodo FROM evento.gol g;
-- DECLARE @p1_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT partido_id, goles_local, goles_visitante, penales_local, penales_visitante, estado FROM torneo.partido WHERE partido_id = @p1_r1;
GO

-- E-1.10.02 Alta de gol inválida
PRINT '--- E-1.10.02 Alta de gol inválida';
-- autor (20) suplente que no ingresó, asistente igual al autor y asistente que no ingresó.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @local INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_local'), @j20 INT;
SELECT @j20 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 20;
-- DECLARE @p1_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT partido_id, goles_local, goles_visitante FROM torneo.partido WHERE partido_id = @p1_r1;   -- el marcador sigue 1 a 0
GO

-- ============================================================
-- 1.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================

-- E-1.11.01 Alta, modificación y baja de tarjeta
PRINT '--- E-1.11.01 Alta, modificación y baja de tarjeta';
-- Resultado esperado: queda una amarilla al 6 de Francia (minuto 31 del PT). La amarilla temporal al 7 se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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
-- SELECT tarjeta_id, partido_id, persona_id, minuto, periodo, tipo, motivo, tipo_expulsion FROM evento.tarjeta;
GO

-- E-1.11.02 ABM de criterios de suspensión
PRINT '--- E-1.11.02 ABM de criterios de suspensión';
-- Resultado esperado: quedan 2 criterios activos: general (2 amarillas => 1 partido) y cuerpo técnico (3 amarillas => 1 partido).
-- El criterio temporal de semifinal se modifica y se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 2, 1, NULL, NULL, 1, @id OUTPUT;             INSERT INTO prueba.id VALUES ('criterio_general', @id);
EXEC evento.criterio_suspension_insertar 3, 1, NULL, 'cuerpo_tecnico', 1, @id OUTPUT;
EXEC evento.criterio_suspension_insertar 1, 1, 'semifinal', NULL, 1, @id OUTPUT;
EXEC evento.criterio_suspension_modificar @id, 1, 2, 'semifinal', NULL, 0;
EXEC evento.criterio_suspension_eliminar @id;
-- SELECT criterio_id, fase_aplicable, tipo_persona_aplicable, cantidad_amarillas, partidos_suspension, activo FROM evento.criterio_suspension;
GO

-- E-1.11.03 ABM de suspensión (carga manual)
PRINT '--- E-1.11.03 ABM de suspensión (carga manual)';
-- Resultado esperado: se carga a mano una suspensión del 6 de Francia para P4, se le corrige el motivo y se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @tarjeta INT = (SELECT valor FROM prueba.id WHERE clave = 'tarjeta_FRA6'), @criterio INT = (SELECT valor FROM prueba.id WHERE clave = 'criterio_general'),
        @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2'), @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'), @susp INT;
EXEC evento.suspension_insertar @tarjeta, 'Sanción de oficio', @criterio, @p4, @susp OUTPUT;
EXEC evento.suspension_modificar @susp, 'Sanción de oficio del comité disciplinario', @p4;
-- SELECT suspension_id, criterio_id, tarjeta_id, partido_afectado_id, motivo FROM evento.suspension;
EXEC evento.suspension_eliminar @susp;
-- DECLARE @susp_r1 INT = IDENT_CURRENT('evento.suspension');
-- SELECT * FROM evento.suspension WHERE suspension_id = @susp_r1;   -- después de la baja: sin filas
GO

-- ============================================================
-- 1.12 arbitraje: arbitro, arbitro_idioma, designacion_arbitral e informe_arbitral
-- ============================================================

-- E-1.12.01 Alta, modificación y baja de árbitros e idiomas
PRINT '--- E-1.12.01 Alta, modificación y baja de árbitros e idiomas';
-- Resultado esperado: 9 árbitros de 7 países; Matonte con 2 idiomas (espanol, ingles). El árbitro temporal se elimina con sus idiomas.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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
-- SELECT a.arbitro_id, a.nombre, a.apellido, p.codigo_iso, a.categoria, a.fecha_nacimiento,
--        (SELECT STRING_AGG(i.idioma, ', ') FROM arbitraje.arbitro_idioma i WHERE i.arbitro_id = a.arbitro_id) AS idiomas
-- FROM arbitraje.arbitro a JOIN torneo.pais p ON p.pais_id = a.pais_id ORDER BY a.arbitro_id;
GO

-- E-1.12.02 ABM de designación arbitral (de a una) y de informe arbitral
PRINT '--- E-1.12.02 ABM de designación arbitral (de a una) y de informe arbitral';
-- Resultado esperado: en P2 se designa a Matonte como principal y luego se lo reemplaza por Elfath; el informe se
-- carga, se modifica y se elimina; finalmente se elimina la designación. P2 queda sin designaciones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2'), @ury INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY1'),
        @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_USA'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_ARG'),
        @desig INT, @informe INT;
EXEC arbitraje.designacion_arbitral_insertar @p2, @ury, 'principal', @desig OUTPUT;
EXEC arbitraje.designacion_arbitral_modificar @desig, @usa, 'principal';
EXEC arbitraje.informe_arbitral_insertar @desig, '2026-06-18T03:00:00+00:00', 'Partido sin incidentes.', NULL, @informe OUTPUT;
EXEC arbitraje.informe_arbitral_modificar @informe, '2026-06-18T04:00:00+00:00', 'Partido con un incidente menor en el banco visitante.', 'Apercibimiento';
-- SELECT d.designacion_id, d.partido_id, a.apellido AS arbitro, d.rol, i.informe_id, i.fecha, i.contenido, i.sancion
-- FROM arbitraje.designacion_arbitral d JOIN arbitraje.arbitro a ON a.arbitro_id = d.arbitro_id
-- LEFT JOIN arbitraje.informe_arbitral i ON i.designacion_id = d.designacion_id;
EXEC arbitraje.informe_arbitral_eliminar @informe;
EXEC arbitraje.designacion_arbitral_eliminar @desig;
-- DECLARE @p2_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE partido_id = @p2_r1;   -- después de las bajas: sin filas
GO

-- ============================================================
-- 1.13 publicidad: anunciante, campania, campania_pais_interes, pieza_publicitaria y espacio_publicitario
-- ============================================================

-- E-1.13.01 Alta de anunciantes, campañas, países de interés y piezas
PRINT '--- E-1.13.01 Alta de anunciantes, campañas, países de interés y piezas';
-- Resultado esperado: 7 anunciantes con una campaña cada uno (vigentes del 01/06 al 19/07/2026), con mercados
-- en 9 países y 12 piezas. El anunciante, la campaña, el país de interés y la pieza temporales se eliminan.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @anun INT, @camp INT, @pieza INT, @p INT, @p2 INT, @p3 INT;
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ARG'), @bra INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_BRA'),
        @ury INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_URY'), @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_USA'),
        @can INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_CAN'), @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_MEX'),
        @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_FRA'), @deu INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_DEU'),
        @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_JPN'), @esp INT = (SELECT valor FROM prueba.id WHERE clave = 'pais_ESP')

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

-- SELECT a.nombre AS anunciante, c.nombre AS campania, c.fecha_inicio, c.fecha_fin,
--        (SELECT STRING_AGG(p.codigo_iso, ', ') FROM publicidad.campania_pais_interes i JOIN torneo.pais p ON p.pais_id = i.pais_id
--         WHERE i.campania_id = c.campania_id) AS paises_interes,
--        (SELECT STRING_AGG(p.codigo_iso + ' ' + pz.idioma + ' ' + CAST(pz.costo_tarifa AS VARCHAR(12)), ' | ')
--         FROM publicidad.pieza_publicitaria pz JOIN torneo.pais p ON p.pais_id = pz.pais_mercado_id
--         WHERE pz.campania_id = c.campania_id) AS piezas
-- FROM publicidad.anunciante a JOIN publicidad.campania c ON c.anunciante_id = a.anunciante_id ORDER BY a.anunciante_id;
GO

-- E-1.13.02 ABM de espacio publicitario (de a uno)
PRINT '--- E-1.13.02 ABM de espacio publicitario (de a uno)';
-- Resultado esperado: en P3 se crea el espacio 1 vacío, se le asigna la pieza de Maple Air y se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @pieza INT = (SELECT valor FROM prueba.id WHERE clave = 'pieza_CAN'), @esp INT;
EXEC publicidad.espacio_publicitario_insertar @p3, 1, NULL, NULL, @esp OUTPUT;
EXEC publicidad.espacio_publicitario_modificar @esp, @pieza, 4;
-- SELECT espacio_id, partido_id, numero_espacio, pieza_id, orden_prioridad, fecha_exhibicion, facturado, monto_facturado FROM publicidad.espacio_publicitario;
EXEC publicidad.espacio_publicitario_eliminar @esp;
-- DECLARE @esp_r1 INT = IDENT_CURRENT('publicidad.espacio_publicitario');
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @esp_r1;   -- después de la baja: sin filas
GO

PRINT '################ PARTE 2: PROCEDIMIENTOS DE LÓGICA DE NEGOCIO (escenario) ################';
GO

-- ============================================================
-- 2.1 plantel.reemplazar_convocado (baja + alta de último momento, en una transacción)
-- ============================================================

-- E-2.1.01 Reemplazo por lesión
PRINT '--- E-2.1.01 Reemplazo por lesión';
-- Resultado esperado: el jugador 26 de ARG queda con fecha y motivo de baja; el 27 entra con el mismo dorsal (99)
-- y motivo de alta "Reemplaza a Jugador 26: ...". Argentina sigue con 26 convocados vigentes.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'),
        @sale INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 26'),
        @entra INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27');
EXEC plantel.reemplazar_convocado @arg, @sale, @entra, '2026-06-14', 'Lesión muscular en el entrenamiento';
-- DECLARE @arg_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG');
-- DECLARE @sale_r1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 26');
-- DECLARE @entra_r1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27');
-- SELECT j.apellido, c.dorsal, c.fecha_alta, c.motivo_alta, c.fecha_baja, c.motivo_baja
-- FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
-- WHERE c.seleccion_id = @arg_r1 AND j.jugador_id IN (@sale_r1, @entra_r1) ORDER BY c.convocatoria_id;
GO

-- ============================================================
-- 2.2 plantel.cargar_formacion (cabecera + titulares + banco, todo o nada)
-- ============================================================

-- E-2.2.01 Carga de las formaciones de P2 (Argentina vs México)
PRINT '--- E-2.2.01 Carga de las formaciones de P2 (Argentina vs México)';
-- Resultado esperado: 2 formaciones con 11 titulares y 12 suplentes cada una; el dorsal sale de la convocatoria.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
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
-- DECLARE @p2_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2');
-- SELECT f.formacion_id, f.condicion, f.esquema_tactico, SUM(CAST(fj.titular AS INT)) AS titulares, SUM(1 - CAST(fj.titular AS INT)) AS suplentes,
--        MIN(fj.dorsal) AS dorsal_min, MAX(fj.dorsal) AS dorsal_max
-- FROM plantel.formacion f JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id
-- WHERE f.partido_id = @p2_r1 GROUP BY f.formacion_id, f.condicion, f.esquema_tactico;
GO

-- ============================================================
-- 2.3 evento.registrar_sustitucion (por dorsales; ventana automática; reglamento de cambios)
-- ============================================================

-- E-2.3.01 CASO OBLIGATORIO: cambio por lesión dentro de los primeros 20 minutos
PRINT '--- E-2.3.01 CASO OBLIGATORIO: cambio por lesión dentro de los primeros 20 minutos';
-- Resultado esperado: Francia (visitante de P1) cambia al 3 por el 13 en el minuto 15 del PT, motivo lesión, ventana 1.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @form INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_visitante');
EXEC evento.registrar_sustitucion @p1, 'visitante', 3, 13, 15, 'PT', 'lesion';
-- DECLARE @form_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_visitante');
-- SELECT s.minuto, s.periodo, s.numero_ventana, s.motivo, sale.dorsal AS dorsal_sale, entra.dorsal AS dorsal_entra
-- FROM evento.sustitucion s
-- JOIN plantel.formacion_jugador sale  ON sale.formacion_id = s.formacion_id AND sale.jugador_id = s.jugador_sale_id
-- JOIN plantel.formacion_jugador entra ON entra.formacion_id = s.formacion_id AND entra.jugador_id = s.jugador_entra_id
-- WHERE s.formacion_id = @form_r1;
GO

-- E-2.3.02 Ventanas automáticas y máximo de cambios
PRINT '--- E-2.3.02 Ventanas automáticas y máximo de cambios';
-- Resultado esperado: dos cambios en el minuto 46 comparten la ventana 2; el del minuto 70 abre la ventana 3.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @form INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_visitante');
EXEC evento.registrar_sustitucion @p1, 'visitante', 7, 14, 46, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p1, 'visitante', 8, 15, 46, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p1, 'visitante', 9, 16, 70, 'ST', 'precaucion';
EXEC evento.registrar_sustitucion @p1, 'visitante', 10, 17, 70, 'ST', 'tactico';
-- DECLARE @form_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1_visitante');
-- SELECT s.numero_ventana, s.minuto, s.periodo, s.motivo, sale.dorsal AS dorsal_sale, entra.dorsal AS dorsal_entra
-- FROM evento.sustitucion s
-- JOIN plantel.formacion_jugador sale  ON sale.formacion_id = s.formacion_id AND sale.jugador_id = s.jugador_sale_id
-- JOIN plantel.formacion_jugador entra ON entra.formacion_id = s.formacion_id AND entra.jugador_id = s.jugador_entra_id
-- WHERE s.formacion_id = @form_r1 ORDER BY s.numero_ventana, sale.dorsal;
GO

-- ============================================================
-- 2.4 evento.registrar_gol (por dorsales; actualiza el marcador)
-- ============================================================

-- E-2.4.01 Goles de P1
PRINT '--- E-2.4.01 Goles de P1';
-- Resultado esperado: empata Francia (gol del 9 con asistencia del 14, que ingresó en el minuto 46) y desnivela
-- Argentina de penal (el 10). Marcador de P1: 2 a 1.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC evento.registrar_gol @p1, 'visitante', 9, 55, 'jugada', 'ST', 14;
EXEC evento.registrar_gol @p1, 'local', 10, 88, 'penal', 'ST';
-- DECLARE @p1_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT f.condicion, fj.dorsal AS autor, a.dorsal AS asistente, g.minuto, g.periodo, g.tipo_gol
-- FROM evento.gol g JOIN plantel.formacion f ON f.formacion_id = g.formacion_id
-- JOIN plantel.formacion_jugador fj ON fj.formacion_id = g.formacion_id AND fj.jugador_id = g.jugador_id
-- LEFT JOIN plantel.formacion_jugador a ON a.formacion_id = g.formacion_id AND a.jugador_id = g.asistencia_jugador_id
-- WHERE f.partido_id = @p1_r1 ORDER BY g.minuto;
-- DECLARE @p1_r2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT partido_id, goles_local, goles_visitante, estado FROM torneo.partido WHERE partido_id = @p1_r2;
GO

-- ============================================================
-- 2.5 evento.registrar_tarjeta (tarjeta + cálculo de suspensión en una transacción)
-- ============================================================

-- E-2.5.01 Primera amarilla: todavía no hay suspensión
PRINT '--- E-2.5.01 Primera amarilla: todavía no hay suspensión';
-- Resultado esperado: amarilla al 5 de Argentina en P1; lleva 1 de las 2 del criterio general => 0 suspensiones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 40, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Mano intencional',
     @condicion = 'local', @dorsal = 5, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
-- DECLARE @tarjeta_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT tarjeta_id, partido_id, persona_id, minuto, periodo, tipo, motivo FROM evento.tarjeta WHERE tarjeta_id = @tarjeta_r1;
GO

-- E-2.5.02 CASO OBLIGATORIO: roja directa
PRINT '--- E-2.5.02 CASO OBLIGATORIO: roja directa';
-- Resultado esperado: roja directa al 4 de Francia en P1 => 1 suspensión sin criterio (no es por acumulación)
-- para el próximo partido programado de Francia: P4.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 75, @periodo = 'ST', @tipo = 'roja', @motivo = 'Agresión a un rival',
     @condicion = 'visitante', @dorsal = 4, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
-- DECLARE @tarjeta_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT t.tarjeta_id, t.tipo, t.tipo_expulsion, t.minuto, s.suspension_id, s.criterio_id, s.partido_afectado_id, s.motivo
-- FROM evento.tarjeta t LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id WHERE t.tarjeta_id = @tarjeta_r1;
GO

-- E-2.5.03 Tarjeta a un integrante del cuerpo técnico
PRINT '--- E-2.5.03 Tarjeta a un integrante del cuerpo técnico';
-- Resultado esperado: amarilla al DT de Francia (identificado por persona_id). Le aplica el criterio específico de
-- cuerpo técnico (3 amarillas), no el general (2) => 0 suspensiones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @dt INT = (SELECT valor FROM prueba.id WHERE clave = 'persona_DT_FRA'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 76, @periodo = 'ST', @tipo = 'amarilla', @motivo = 'Protesta',
     @persona_id = @dt, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
-- DECLARE @tarjeta_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT t.tarjeta_id, pe.tipo_persona, ct.apellido, t.tipo, t.minuto
-- FROM evento.tarjeta t JOIN plantel.persona pe ON pe.persona_id = t.persona_id JOIN plantel.cuerpo_tecnico ct ON ct.persona_id = t.persona_id
-- WHERE t.tarjeta_id = @tarjeta_r1;
GO

-- ============================================================
-- 2.6 publicidad.asignar_espacios_partido (los cuatro espacios según los criterios de la sección H)
-- ============================================================

-- E-2.6.01 CASO OBLIGATORIO: partido en prime time en más de cuatro mercados candidatos
PRINT '--- E-2.6.01 CASO OBLIGATORIO: partido en prime time en más de cuatro mercados candidatos';
-- P1 (Argentina vs Francia) se juega a las 00:00 UTC: es prime time (19 a 23 h) en 5 mercados con piezas candidatas:
-- Argentina, Brasil y Uruguay (21 h), Estados Unidos y Canadá (19 h). No lo es en México (18 h), Francia y Alemania (1 h) ni Japón (9 h).
-- Resultado esperado (ver el ranking que devuelve el SP): se eligen 4 de las 7 campañas candidatas:
--   espacio 1: Mate Pampa / Argentina        (país de una selección + prime time)                      prioridad 1
--   espacio 2: Banque Lumière / Francia      (país de una selección)                                   prioridad 1
--   espacio 3: NorthStar Motors / EE.UU.     (mercado de mayor PBI de su campaña + prime time, tarifa 120000)  prioridad 2
--   espacio 4: Sakura Tech / EE.UU.          (ídem, tarifa 100000)                                     prioridad 2
-- Quedan afuera Maple Air (Canadá), Cerveza Tropical (Brasil) y Tequila Sol (México), aun estando las dos primeras en prime time.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC publicidad.asignar_espacios_partido @p1;
-- DECLARE @p1_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT e.numero_espacio, a.nombre AS anunciante, m.nombre AS mercado, e.orden_prioridad, pz.costo_tarifa, e.fecha_exhibicion, e.facturado
-- FROM publicidad.espacio_publicitario e
-- JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id JOIN publicidad.campania c ON c.campania_id = pz.campania_id
-- JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id JOIN torneo.pais m ON m.pais_id = pz.pais_mercado_id
-- WHERE e.partido_id = @p1_r1 ORDER BY e.numero_espacio;
GO

-- E-2.6.02 Reasignación y rechazos
PRINT '--- E-2.6.02 Reasignación y rechazos';
-- Resultado esperado: (1) rechazo (50002): P1 ya tiene espacios asignados. (2) con @reemplazar = 1 se recalcula y
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
EXEC publicidad.asignar_espacios_partido @p1, @reemplazar = 1, @mostrar_detalle = 0;
-- DECLARE @p1_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT * FROM publicidad.espacio_publicitario WHERE partido_id = @p1_r1 ORDER BY numero_espacio;
GO

-- ============================================================
-- 2.7 torneo.registrar_resultado (cierre del partido + pauta exhibida) y facturación
-- ============================================================

-- E-2.7.01 Cierre de P1 y facturación de su pauta
PRINT '--- E-2.7.01 Cierre de P1 y facturación de su pauta';
-- Resultado esperado: P1 queda 'finalizado' 2 a 1 (tomado del detalle de goles) con 80000 espectadores; sus 4 espacios
-- quedan con fecha de exhibición. Al facturar, cada espacio guarda la tarifa de su pieza: total 360000.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1'), @total NUMERIC(14,2);
EXEC torneo.registrar_resultado @partido_id = @p1, @asistencia_publico = 80000;
-- DECLARE @p1_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT partido_id, estado, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p1_r1;
EXEC publicidad.facturar_espacios_partido @p1, @total OUTPUT;
-- DECLARE @p1_r2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P1');
-- SELECT numero_espacio, pieza_id, orden_prioridad, fecha_exhibicion, facturado, monto_facturado FROM publicidad.espacio_publicitario WHERE partido_id = @p1_r2 ORDER BY numero_espacio;
PRINT 'Total facturado de P1: ' + CAST(@total AS VARCHAR(20));
GO

-- ============================================================
-- 2.8 Acumulación de amarillas, doble amarilla y jugador suspendido fuera de la formación
-- ============================================================

-- E-2.8.01 CASO OBLIGATORIO: suspensión por acumulación de amarillas
PRINT '--- E-2.8.01 CASO OBLIGATORIO: suspensión por acumulación de amarillas';
-- Resultado esperado: el 5 de Argentina recibe en P2 su segunda amarilla en partidos distintos (P1 y P2) => 1 suspensión
-- con el criterio general, para el próximo partido de Argentina: P3.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2'), @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'),
        @criterio INT = (SELECT valor FROM prueba.id WHERE clave = 'criterio_general'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 20, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Falta táctica',
     @condicion = 'local', @dorsal = 5, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
-- SELECT j.apellido, t.partido_id, t.minuto, t.tipo, s.suspension_id, s.criterio_id, s.partido_afectado_id, s.motivo
-- FROM evento.tarjeta t JOIN plantel.jugador j ON j.persona_id = t.persona_id LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id
-- WHERE j.nombre = 'ARG' AND j.apellido = 'Jugador 05' ORDER BY t.tarjeta_id;
GO

-- E-2.8.02 CASO OBLIGATORIO: expulsión por doble amonestación
PRINT '--- E-2.8.02 CASO OBLIGATORIO: expulsión por doble amonestación';
-- Resultado esperado: el 8 de México recibe dos amarillas en P2; la segunda se registra sola como roja por doble amarilla
-- y genera 1 suspensión. México no tiene otro partido programado: queda con partido NULL ("a definir").
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 30, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Juego brusco',
     @condicion = 'visitante', @dorsal = 8;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 60, @periodo = 'ST', @tipo = 'amarilla', @motivo = 'Reiteración de faltas',
     @condicion = 'visitante', @dorsal = 8, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
-- SELECT j.apellido, t.minuto, t.periodo, t.tipo, t.tipo_expulsion, s.criterio_id, s.partido_afectado_id, s.motivo
-- FROM evento.tarjeta t JOIN plantel.jugador j ON j.persona_id = t.persona_id LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id
-- WHERE j.nombre = 'MEX' AND j.apellido = 'Jugador 08' ORDER BY t.tarjeta_id;
GO

-- E-2.8.03 Cierre de P2 sin goles (resultado tomado del detalle: 0 a 0)
PRINT '--- E-2.8.03 Cierre de P2 sin goles (resultado tomado del detalle: 0 a 0)';
-- Resultado esperado: P2 finalizado 0 a 0 sin informar goles.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2');
EXEC torneo.registrar_resultado @partido_id = @p2, @asistencia_publico = 83000;
-- DECLARE @p2_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P2');
-- SELECT partido_id, estado, goles_local, goles_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p2_r1;
GO

-- E-2.8.04 CASO OBLIGATORIO: el suspendido queda afuera de la formación del siguiente partido
PRINT '--- E-2.8.04 CASO OBLIGATORIO: el suspendido queda afuera de la formación del siguiente partido';
-- (3) la misma formación con el 12 en lugar del 5 se carga bien.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @arg INT = (SELECT valor FROM prueba.id WHERE clave = 'ARG'), @form INT, @j5 INT;
DECLARE @con5 plantel.tt_formacion_jugador, @sin5 plantel.tt_formacion_jugador;
INSERT INTO @con5 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23;
INSERT INTO @sin5 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 12, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23 AND c.dorsal <> 5;
SELECT @j5 = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @arg AND dorsal = 5 AND fecha_baja IS NULL;
EXEC plantel.cargar_formacion @p3, 'local', '4-3-3', @sin5, @form OUTPUT;
-- DECLARE @form_r1 INT = IDENT_CURRENT('plantel.formacion_jugador');
-- SELECT fj.dorsal, j.apellido, fj.posicion, fj.titular FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
-- WHERE fj.formacion_id = @form_r1 AND fj.titular = 1 ORDER BY fj.dorsal;
GO

-- ============================================================
-- 2.9 arbitraje.designar_arbitros (terna completa, con validación de conflicto de nacionalidad)
-- ============================================================

-- E-2.9.01 Designación válida en fase de grupos y con advertencia en eliminación directa
PRINT '--- E-2.9.01 Designación válida en fase de grupos y con advertencia en eliminación directa';
-- Resultado esperado: P3 queda con sus 5 roles y sin advertencia (fase de grupos). P4 (dieciseisavos, Francia vs Japón)
-- queda con sus 5 roles y devuelve una ADVERTENCIA por César Ramos (México) y Wilton Sampaio (Brasil): sus países tienen
-- selección en competencia. No es un bloqueo.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'),
        @ury1 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY1'), @ury2 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_URY2'),
        @deu1 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_DEU1'), @deu2 INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_DEU2'),
        @usa INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_USA'), @can INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_CAN'),
        @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_MEX'), @bra INT = (SELECT valor FROM prueba.id WHERE clave = 'arb_BRA'),
        @adv3 VARCHAR(1000), @adv4 VARCHAR(1000);
EXEC arbitraje.designar_arbitros @p3, @ury1, @ury2, @deu2, @usa, @deu1, @adv3 OUTPUT;
EXEC arbitraje.designar_arbitros @p4, @deu1, @deu2, @can, @mex, @bra, @adv4 OUTPUT;
-- SELECT d.partido_id, d.rol, a.nombre + ' ' + a.apellido AS arbitro, p.codigo_iso AS pais
-- FROM arbitraje.designacion_arbitral d JOIN arbitraje.arbitro a ON a.arbitro_id = d.arbitro_id JOIN torneo.pais p ON p.pais_id = a.pais_id
-- ORDER BY d.partido_id, d.designacion_id;
GO

-- ============================================================
-- 2.10 Partido de eliminación directa completo (P4: Francia vs Japón, dieciseisavos)
-- ============================================================

-- E-2.10.01 Formaciones de P4: el expulsado por roja directa en P1 no puede jugar
PRINT '--- E-2.10.01 Formaciones de P4: el expulsado por roja directa en P1 no puede jugar';
-- sin el 4 se carga bien. La de Japón se carga completa.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'), @fra INT = (SELECT valor FROM prueba.id WHERE clave = 'FRA'),
        @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'JPN'), @form INT;
DECLARE @con4 plantel.tt_formacion_jugador, @sin4 plantel.tt_formacion_jugador, @japon plantel.tt_formacion_jugador;
INSERT INTO @con4 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL;
INSERT INTO @sin4 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 12, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL AND c.dorsal <> 4;
INSERT INTO @japon SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @jpn AND c.fecha_baja IS NULL;
EXEC plantel.cargar_formacion @p4, 'local', '4-2-3-1', @sin4, @form OUTPUT;   INSERT INTO prueba.id VALUES ('P4_local', @form);
EXEC plantel.cargar_formacion @p4, 'visitante', '3-4-3', @japon, @form OUTPUT; INSERT INTO prueba.id VALUES ('P4_visitante', @form);
-- DECLARE @p4_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
-- SELECT f.formacion_id, f.condicion, f.esquema_tactico, fj.jugador_id, fj.dorsal, fj.posicion, fj.titular FROM plantel.formacion f LEFT JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.partido_id = @p4_r1 ORDER BY f.formacion_id, fj.titular DESC, fj.dorsal;
GO

-- E-2.10.02 Cambio adicional del tiempo suplementario
PRINT '--- E-2.10.02 Cambio adicional del tiempo suplementario';
-- Resultado esperado: Japón hace 5 cambios en 3 ventanas del ST. El 6.º en el ST se rechaza con 2 condiciones (máximo de
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4'), @form INT = (SELECT valor FROM prueba.id WHERE clave = 'P4_visitante');
EXEC evento.registrar_sustitucion @p4, 'visitante', 2, 12, 50, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 3, 13, 50, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 4, 14, 65, 'ST', 'lesion';
EXEC evento.registrar_sustitucion @p4, 'visitante', 5, 15, 65, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 6, 16, 80, 'ST', 'precaucion';
EXEC evento.registrar_sustitucion @p4, 'visitante', 7, 17, 95, 'alargue_1', 'tactico';
-- DECLARE @form_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4_visitante');
-- SELECT numero_ventana, periodo, minuto, COUNT(*) AS cambios FROM evento.sustitucion WHERE formacion_id = @form_r1
-- GROUP BY numero_ventana, periodo, minuto ORDER BY numero_ventana;
GO

-- E-2.10.03 Empate, definición por penales y cierre
PRINT '--- E-2.10.03 Empate, definición por penales y cierre';
-- Con la tanda registrada (Francia 2, Japón 1) se cierra: goles 1-1, penales 2-1. Los goles de la tanda no suman al marcador.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p4 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
EXEC evento.registrar_gol @p4, 'local', 9, 30, 'tiro_libre', 'PT';
EXEC evento.registrar_gol @p4, 'visitante', 10, 77, 'jugada', 'ST', 12;
EXEC evento.registrar_gol @p4, 'local', 9, 120, 'penal', 'penales';
EXEC evento.registrar_gol @p4, 'visitante', 10, 120, 'penal', 'penales';
EXEC evento.registrar_gol @p4, 'local', 10, 120, 'penal', 'penales';
EXEC torneo.registrar_resultado @partido_id = @p4, @asistencia_publico = 70000;
-- DECLARE @p4_r1 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
-- SELECT partido_id, fase, estado, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p4_r1;
-- DECLARE @p4_r2 INT = (SELECT valor FROM prueba.id WHERE clave = 'P4');
-- SELECT g.* FROM evento.gol g JOIN plantel.formacion f ON f.formacion_id = g.formacion_id WHERE f.partido_id = @p4_r2 ORDER BY g.gol_id;
GO

-- E-2.10.04 Resultado sin detalle (como llegaría de una importación) y sus validaciones
PRINT '--- E-2.10.04 Resultado sin detalle (como llegaría de una importación) y sus validaciones';
-- Resultado esperado: se programa un partido de grupos sin formaciones (México vs Japón). Cerrarlo sin informar goles se
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @mx INT = (SELECT valor FROM prueba.id WHERE clave = 'sede_MX'), @mex INT = (SELECT valor FROM prueba.id WHERE clave = 'MEX'),
        @jpn INT = (SELECT valor FROM prueba.id WHERE clave = 'JPN'), @p5 INT;
EXEC torneo.partido_insertar @mx, '2026-06-25T18:00:00-06:00', 'grupos', @mex, @jpn, NULL, @p5 OUTPUT;
EXEC torneo.registrar_resultado @p5, 2, 0, NULL, NULL, 60000;
-- DECLARE @p5_r1 INT = IDENT_CURRENT('torneo.partido');
-- SELECT partido_id, fase, estado, goles_local, goles_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p5_r1;
GO

-- ============================================================
-- 2.11 Transaccionalidad: todo o nada en operaciones que afectan varias tablas
-- ============================================================

-- E-2.11.01 Una operación multi-tabla se deshace completa
PRINT '--- E-2.11.01 Una operación multi-tabla se deshace completa';
-- Una roja genera 1 tarjeta (evento.tarjeta) y 1 suspensión (evento.suspension). Se la ejecuta dentro de una
-- transacción abierta por quien llama y se hace ROLLBACK.
-- Resultado esperado: dentro de la transacción hay +1 tarjeta y +1 suspensión; después del ROLLBACK no queda
-- ninguna de las dos (el SP no confirma por su cuenta lo que no abrió).
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM prueba.id WHERE clave = 'P3'), @t0 INT = (SELECT COUNT(*) FROM evento.tarjeta),
        @s0 INT = (SELECT COUNT(*) FROM evento.suspension), @t1 INT, @s1 INT;
BEGIN TRANSACTION;
    EXEC evento.registrar_tarjeta @partido_id = @p3, @minuto = 10, @periodo = 'PT', @tipo = 'roja', @motivo = 'Prueba de rollback',
         @condicion = 'local', @dorsal = 7;
    SELECT @t1 = COUNT(*) FROM evento.tarjeta;
    SELECT @s1 = COUNT(*) FROM evento.suspension;
ROLLBACK TRANSACTION;
-- DECLARE @t0_r1 INT = (SELECT COUNT(*) FROM evento.tarjeta);
-- DECLARE @t1_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- DECLARE @s0_r1 INT = (SELECT COUNT(*) FROM evento.suspension);
-- DECLARE @s1_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT @t0_r1 AS tarjetas_antes, @t1_r1 AS tarjetas_durante, (SELECT COUNT(*) FROM evento.tarjeta) AS tarjetas_despues,
--        @s0_r1 AS suspensiones_antes, @s1_r1 AS suspensiones_durante, (SELECT COUNT(*) FROM evento.suspension) AS suspensiones_despues;
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
-- E-3.1.01 a E-3.1.06 torneo.parametro_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.1.01 torneo.parametro_insertar: Valido => se acepta
PRINT '--- E-3.1.01 torneo.parametro_insertar: Valido';
EXEC torneo.parametro_insertar 'tst_ins_ok', 10, 'Alta valida';
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_ins_ok';
GO

-- E-3.1.02 torneo.parametro_insertar: Valido: valor 0 (borde) => se acepta
PRINT '--- E-3.1.02 torneo.parametro_insertar: Valido: valor 0 (borde)';
EXEC torneo.parametro_insertar 'tst_cero', 0, 'Valor cero';
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_cero';
GO

-- E-3.1.03 torneo.parametro_insertar: borde => se acepta
PRINT '--- E-3.1.03 torneo.parametro_insertar: borde';
EXEC torneo.parametro_insertar 'tst_valor_max', 2147483647, 'Valor maximo';
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_valor_max';
GO

-- E-3.1.04 torneo.parametro_insertar: Valido: clave de 40 caracteres (borde) => se acepta
PRINT '--- E-3.1.04 torneo.parametro_insertar: Valido: clave de 40 caracteres (borde)';
EXEC torneo.parametro_insertar 'tst_abcdefghijklmnopqrstuvwxyz0123456789', 1, 'Clave de 40';
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_abcdefghijklmnopqrstuvwxyz0123456789';
GO

-- E-3.1.05 torneo.parametro_insertar: Valido: la descripcion se guarda tal cual, sin recortar => se acepta
PRINT '--- E-3.1.05 torneo.parametro_insertar: Valido: la descripcion se guarda tal cual, sin recortar';
EXEC torneo.parametro_insertar 'tst_desc_esp', 1, '  Descripcion con espacios  ';
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_desc_esp';
GO

-- E-3.1.06 torneo.parametro_insertar: Valido: permite mayus la collation => se acepta
PRINT '--- E-3.1.06 torneo.parametro_insertar: Valido: permite mayus la collation';
EXEC torneo.parametro_insertar 'TST_MAYUS', 1, 'Clave en mayusculas';
-- SELECT * FROM torneo.parametro WHERE clave = 'TST_MAYUS';
GO

-- -------------------------------------------------------------------------------------
-- E-3.1.07 a E-3.1.13 torneo.parametro_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.1.07 torneo.parametro_modificar: Valido: cambia valor y descripcion => se acepta
PRINT '--- E-3.1.07 torneo.parametro_modificar: Valido: cambia valor y descripcion';
EXEC torneo.parametro_modificar 'tst_mod', 20, 'Descripcion nueva';
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_mod';
GO

-- E-3.1.08 torneo.parametro_modificar: Valido: sin descripcion, conserva 'Descripcion nueva' => se acepta
PRINT '--- E-3.1.08 torneo.parametro_modificar: Valido: sin descripcion, conserva ''Descripcion nueva''';
EXEC torneo.parametro_modificar 'tst_mod', 30;
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_mod';
GO

-- E-3.1.09 torneo.parametro_modificar: Valido: borde => se acepta
PRINT '--- E-3.1.09 torneo.parametro_modificar: Valido: borde';
EXEC torneo.parametro_modificar 'tst_mod', 0, NULL;
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_mod';
GO

-- E-3.1.10 torneo.parametro_modificar: Valido: hora de fin 24 (borde superior) => se acepta
PRINT '--- E-3.1.10 torneo.parametro_modificar: Valido: hora de fin 24 (borde superior)';
EXEC torneo.parametro_modificar 'prime_time_hora_hasta', 24;
-- SELECT * FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta';
GO

-- E-3.1.11 torneo.parametro_modificar: Valido: hora de fin 0 (borde inferior) => se acepta
PRINT '--- E-3.1.11 torneo.parametro_modificar: Valido: hora de fin 0 (borde inferior)';
EXEC torneo.parametro_modificar 'prime_time_hora_hasta', 0;
-- SELECT * FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta';
GO

-- E-3.1.12 torneo.parametro_modificar: Restaurar prime_time_hora_hasta => se acepta
PRINT '--- E-3.1.12 torneo.parametro_modificar: Restaurar prime_time_hora_hasta';
DECLARE @bk_hasta INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_hasta');
EXEC torneo.parametro_modificar 'prime_time_hora_hasta', @bk_hasta;
-- SELECT * FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta';
GO

-- E-3.1.13 torneo.parametro_modificar: Restaurar prime_time_hora_desde => se acepta
PRINT '--- E-3.1.13 torneo.parametro_modificar: Restaurar prime_time_hora_desde';
DECLARE @bk_desde INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_desde');
EXEC torneo.parametro_modificar 'prime_time_hora_desde', @bk_desde;
-- SELECT * FROM torneo.parametro WHERE clave = 'prime_time_hora_desde';
GO

-- -------------------------------------------------------------------------------------
-- E-3.1.14 torneo.parametro_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.1.14 torneo.parametro_eliminar: Baja valida => se acepta
PRINT '--- E-3.1.14 torneo.parametro_eliminar: Baja valida';
EXEC torneo.parametro_eliminar 'tst_elim';
-- SELECT * FROM torneo.parametro WHERE clave = 'tst_elim';
GO

-- ============================================================
-- 3.2 torneo.pais y torneo.confederacion
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.2.01 a E-3.2.08 torneo.pais_validar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.2.01 torneo.pais_validar: Valido => se acepta
PRINT '--- E-3.2.01 torneo.pais_validar: Valido';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- E-3.2.02 torneo.pais_validar: Valido => se acepta
PRINT '--- E-3.2.02 torneo.pais_validar: Valido';
DECLARE @e VARCHAR(2000),
        @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZM');
SET @e = ''; EXEC torneo.pais_validar @m, 'ZZM', 'Test Modificar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- E-3.2.03 torneo.pais_validar: Valido: PBI nulo => se acepta
PRINT '--- E-3.2.03 torneo.pais_validar: Valido: PBI nulo';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', NULL, @e OUTPUT; PRINT @e;
GO

-- E-3.2.04 torneo.pais_validar: Valido: PBI 0 => se acepta
PRINT '--- E-3.2.04 torneo.pais_validar: Valido: PBI 0';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', 0, @e OUTPUT; PRINT @e;
GO

-- E-3.2.05 torneo.pais_validar: Valido: ISO en minusculas => se acepta
PRINT '--- E-3.2.05 torneo.pais_validar: Valido: ISO en minusculas';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'zzv', 'Test Validar', 'UTC-03', 100, @e OUTPUT; PRINT @e;
GO

-- E-3.2.06 torneo.pais_validar: Valido: nombre de 80 caracteres y huso UTC+14 (bordes) => se acepta
PRINT '--- E-3.2.06 torneo.pais_validar: Valido: nombre de 80 caracteres y huso UTC+14 (bordes)';
DECLARE @e VARCHAR(2000),
        @n80 VARCHAR(80) = REPLICATE('N', 80);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', @n80, 'UTC+14', 100, @e OUTPUT; PRINT @e;
GO

-- E-3.2.07 torneo.pais_validar: Valido: huso UTC-12 (borde) => se acepta
PRINT '--- E-3.2.07 torneo.pais_validar: Valido: huso UTC-12 (borde)';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-12', 100, @e OUTPUT; PRINT @e;
GO

-- E-3.2.08 torneo.pais_validar: Valido: huso UTC+00 => se acepta
PRINT '--- E-3.2.08 torneo.pais_validar: Valido: huso UTC+00';
DECLARE @e VARCHAR(2000);
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC+00', 100, @e OUTPUT; PRINT @e;
GO

-- -------------------------------------------------------------------------------------
-- E-3.2.09 a E-3.2.13 torneo.pais_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.2.09 torneo.pais_insertar: Valido: devuelve el id generado => se acepta
PRINT '--- E-3.2.09 torneo.pais_insertar: Valido: devuelve el id generado';
DECLARE @id INT;
EXEC torneo.pais_insertar 'ZZA', 'Test Alta', 'UTC-03', 1500.75, @id OUTPUT; SELECT @id AS pais_id_generado;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.pais');
-- SELECT * FROM torneo.pais WHERE pais_id = @id_r1;
GO

-- E-3.2.10 torneo.pais_insertar: Valido: PBI 0 => se acepta
PRINT '--- E-3.2.10 torneo.pais_insertar: Valido: PBI 0';
DECLARE @id INT;
EXEC torneo.pais_insertar 'ZZD', 'Test PBI Cero', 'UTC-03', 0, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.pais');
-- SELECT * FROM torneo.pais WHERE pais_id = @id_r1;
GO

-- E-3.2.11 torneo.pais_insertar: Valido: el nombre se guarda recortado => se acepta
PRINT '--- E-3.2.11 torneo.pais_insertar: Valido: el nombre se guarda recortado';
DECLARE @id INT;
EXEC torneo.pais_insertar 'ZZG', '  Test Espacios  ', 'UTC-03', 10, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.pais');
-- SELECT * FROM torneo.pais WHERE pais_id = @id_r1;
GO

-- E-3.2.12 torneo.pais_insertar: Valido: huso UTC+14 (borde superior) => se acepta
PRINT '--- E-3.2.12 torneo.pais_insertar: Valido: huso UTC+14 (borde superior)';
DECLARE @id INT;
EXEC torneo.pais_insertar 'ZZH', 'Test Huso Max', 'UTC+14', 10, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.pais');
-- SELECT * FROM torneo.pais WHERE pais_id = @id_r1;
GO

-- E-3.2.13 torneo.pais_insertar: Valido: nombre de 80 caracteres (borde) => se acepta
PRINT '--- E-3.2.13 torneo.pais_insertar: Valido: nombre de 80 caracteres (borde)';
DECLARE @id INT,
        @n80 VARCHAR(80) = REPLICATE('N', 80);
EXEC torneo.pais_insertar 'ZZJ', @n80, 'UTC-03', 10, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.pais');
-- SELECT * FROM torneo.pais WHERE pais_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.2.14 a E-3.2.18 torneo.pais_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.2.14 torneo.pais_modificar: Valido => se acepta
PRINT '--- E-3.2.14 torneo.pais_modificar: Valido';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificado', 'UTC-04', 2500;
-- DECLARE @m_r1 INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
-- SELECT * FROM torneo.pais WHERE pais_id = @m_r1;
GO

-- E-3.2.15 torneo.pais_modificar: Valido: nombre de 80 caracteres (borde) => se acepta
PRINT '--- E-3.2.15 torneo.pais_modificar: Valido: nombre de 80 caracteres (borde)';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX')),
        @n80 VARCHAR(80) = REPLICATE('N', 80);
EXEC torneo.pais_modificar @m, 'ZZM', @n80, 'UTC-03', 2000;
-- DECLARE @m_r1 INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
-- SELECT * FROM torneo.pais WHERE pais_id = @m_r1;
GO

-- E-3.2.16 torneo.pais_modificar: Valido: huso UTC+14 y PBI 0 (bordes) => se acepta
PRINT '--- E-3.2.16 torneo.pais_modificar: Valido: huso UTC+14 y PBI 0 (bordes)';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC+14', 0;
-- DECLARE @m_r1 INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
-- SELECT * FROM torneo.pais WHERE pais_id = @m_r1;
GO

-- E-3.2.17 torneo.pais_modificar: Valido: sin PBI, lo deja en NULL => se acepta
PRINT '--- E-3.2.17 torneo.pais_modificar: Valido: sin PBI, lo deja en NULL';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC-03';
-- DECLARE @m_r1 INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
-- SELECT * FROM torneo.pais WHERE pais_id = @m_r1;
GO

-- E-3.2.18 torneo.pais_modificar: Restaurar: deja ZZM como estaba => se acepta
PRINT '--- E-3.2.18 torneo.pais_modificar: Restaurar: deja ZZM como estaba';
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC-03', 2000;
-- DECLARE @m_r1 INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX'));
-- SELECT * FROM torneo.pais WHERE pais_id = @m_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.2.19 torneo.pais_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.2.19 torneo.pais_eliminar: Baja valida => se acepta
PRINT '--- E-3.2.19 torneo.pais_eliminar: Baja valida';
DECLARE @e INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZE');
EXEC torneo.pais_eliminar @e;
-- DECLARE @e_r1 INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZE');
-- SELECT * FROM torneo.pais WHERE pais_id = @e_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.2.20 a E-3.2.21 torneo.confederacion_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.2.20 torneo.confederacion_modificar: Valido: UEFA pasa a OFC => se acepta
PRINT '--- E-3.2.20 torneo.confederacion_modificar: Valido: UEFA pasa a OFC';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
EXEC torneo.confederacion_modificar @u, 'OFC';
-- DECLARE @u_r1 INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
-- SELECT * FROM torneo.confederacion WHERE confederacion_id = @u_r1;
GO

-- E-3.2.21 torneo.confederacion_modificar: Restaurar: deja la base como estaba => se acepta
PRINT '--- E-3.2.21 torneo.confederacion_modificar: Restaurar: deja la base como estaba';
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
EXEC torneo.confederacion_modificar @u, 'UEFA';
-- DECLARE @u_r1 INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));
-- SELECT * FROM torneo.confederacion WHERE confederacion_id = @u_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.2.22 a E-3.2.23 torneo.confederacion_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.2.22 torneo.confederacion_insertar: Valido: devuelve el id generado => se acepta
PRINT '--- E-3.2.22 torneo.confederacion_insertar: Valido: devuelve el id generado';
DECLARE @id INT;
EXEC torneo.confederacion_insertar 'OFC', @id OUTPUT; SELECT @id AS confederacion_id_generado;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.confederacion');
-- SELECT * FROM torneo.confederacion WHERE confederacion_id = @id_r1;
GO

-- E-3.2.23 torneo.confederacion_insertar: Valido: otra confederacion libre => se acepta
PRINT '--- E-3.2.23 torneo.confederacion_insertar: Valido: otra confederacion libre';
DECLARE @id INT;
EXEC torneo.confederacion_insertar 'CAF', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.confederacion');
-- SELECT * FROM torneo.confederacion WHERE confederacion_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.2.24 torneo.confederacion_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.2.24 torneo.confederacion_eliminar: Baja valida (sin selecciones) => se acepta
PRINT '--- E-3.2.24 torneo.confederacion_eliminar: Baja valida (sin selecciones)';
DECLARE @a INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CAF');
EXEC torneo.confederacion_eliminar @a;
-- DECLARE @a_r1 INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CAF');
-- SELECT * FROM torneo.confederacion WHERE confederacion_id = @a_r1;
GO

-- ============================================================
-- 3.3 torneo.sede
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.3.01 a E-3.3.03 torneo.sede_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.3.01 torneo.sede_insertar: Valido: mismo nombre en otra ciudad => se acepta
PRINT '--- E-3.3.01 torneo.sede_insertar: Valido: mismo nombre en otra ciudad';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
EXEC torneo.sede_insertar 'Test Sede Alta', 'Ciudad Otra', @pa, 60000, 'UTC-03', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.sede');
-- SELECT * FROM torneo.sede WHERE sede_id = @id_r1;
GO

-- E-3.3.02 torneo.sede_insertar: Valido: misma ciudad con otro nombre, otro pais => se acepta
PRINT '--- E-3.3.02 torneo.sede_insertar: Valido: misma ciudad con otro nombre, otro pais';
DECLARE @id INT,
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSB');
EXEC torneo.sede_insertar 'Test Sede Otro', 'Ciudad Alta', @pb, 60000, 'UTC-05', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.sede');
-- SELECT * FROM torneo.sede WHERE sede_id = @id_r1;
GO

-- E-3.3.03 torneo.sede_insertar: Valido: capacidad maxima INT (borde) => se acepta
PRINT '--- E-3.3.03 torneo.sede_insertar: Valido: capacidad maxima INT (borde)';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
EXEC torneo.sede_insertar 'Test Sede Max', 'Ciudad Max', @pa, 2147483647, 'UTC-03', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.sede');
-- SELECT * FROM torneo.sede WHERE sede_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.3.04 a E-3.3.05 torneo.sede_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.3.04 torneo.sede_modificar: Valido => se acepta
PRINT '--- E-3.3.04 torneo.sede_modificar: Valido';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSB');
EXEC torneo.sede_modificar @m, 'Test Sede Mod Nuevo', 'Ciudad Mod Nueva', @pb, 45000, 'UTC-05';
-- DECLARE @m_r1 INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%');
-- SELECT * FROM torneo.sede WHERE sede_id = @m_r1;
GO

-- E-3.3.05 torneo.sede_modificar: Valido: se guarda recortado => se acepta
PRINT '--- E-3.3.05 torneo.sede_modificar: Valido: se guarda recortado';
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');
EXEC torneo.sede_modificar @m, '  Test Sede Mod  ', '  Ciudad Mod  ', @pa, 40000, 'UTC-03';
-- DECLARE @m_r1 INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%');
-- SELECT * FROM torneo.sede WHERE sede_id = @m_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.3.06 torneo.sede_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.3.06 torneo.sede_eliminar: Baja valida (sin partidos) => se acepta
PRINT '--- E-3.3.06 torneo.sede_eliminar: Baja valida (sin partidos)';
DECLARE @e INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Elim' AND ciudad = 'Ciudad Elim');
EXEC torneo.sede_eliminar @e;
-- DECLARE @e_r1 INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Elim' AND ciudad = 'Ciudad Elim');
-- SELECT * FROM torneo.sede WHERE sede_id = @e_r1;
GO

-- ============================================================
-- 3.4 torneo.seleccion
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.4.01 a E-3.4.04 torneo.seleccion_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.4.01 torneo.seleccion_insertar: Valido: grupo borde A (cada alta valida usa un pais distinto: ZQB, ZQC, ZQD, ZQE) => se acepta
PRINT '--- E-3.4.01 torneo.seleccion_insertar: Valido: grupo borde A (cada alta valida usa un pais distinto: ZQB, ZQC, ZQD, ZQE)';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQB');
EXEC torneo.seleccion_insertar @pb, @c1, 'A', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.seleccion');
-- SELECT * FROM torneo.seleccion WHERE seleccion_id = @id_r1;
GO

-- E-3.4.02 torneo.seleccion_insertar: Valido: grupo en minuscula (se guarda 'B') => se acepta
PRINT '--- E-3.4.02 torneo.seleccion_insertar: Valido: grupo en minuscula (se guarda ''B'')';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pc INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQC');
DECLARE @c2 INT = ISNULL((SELECT TOP 1 confederacion_id FROM torneo.confederacion WHERE confederacion_id > @c1 ORDER BY confederacion_id), @c1);
EXEC torneo.seleccion_insertar @pc, @c2, 'b', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.seleccion');
-- SELECT * FROM torneo.seleccion WHERE seleccion_id = @id_r1;
GO

-- E-3.4.03 torneo.seleccion_insertar: Valido: grupo borde L => se acepta
PRINT '--- E-3.4.03 torneo.seleccion_insertar: Valido: grupo borde L';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pd INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQD');
EXEC torneo.seleccion_insertar @pd, @c1, 'L', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.seleccion');
-- SELECT * FROM torneo.seleccion WHERE seleccion_id = @id_r1;
GO

-- E-3.4.04 torneo.seleccion_insertar: Valido: grupo borde L en minuscula (se guarda 'L') => se acepta
PRINT '--- E-3.4.04 torneo.seleccion_insertar: Valido: grupo borde L en minuscula (se guarda ''L'')';
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pe INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQE');
EXEC torneo.seleccion_insertar @pe, @c1, 'l', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.seleccion');
-- SELECT * FROM torneo.seleccion WHERE seleccion_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.4.05 torneo.seleccion_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.4.05 torneo.seleccion_modificar: Valido: cambia pais (a uno libre), confederacion y grupo (sin partidos) => se acepta
PRINT '--- E-3.4.05 torneo.seleccion_modificar: Valido: cambia pais (a uno libre), confederacion y grupo (sin partidos)';
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pn INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQN');
DECLARE @c2 INT = ISNULL((SELECT TOP 1 confederacion_id FROM torneo.confederacion WHERE confederacion_id > @c1 ORDER BY confederacion_id), @c1);
EXEC torneo.seleccion_modificar @m, @pn, @c2, 'H';
-- DECLARE @m_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN'));
-- SELECT * FROM torneo.seleccion WHERE seleccion_id = @m_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.4.06 torneo.seleccion_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.4.06 torneo.seleccion_eliminar: Baja valida => se acepta
PRINT '--- E-3.4.06 torneo.seleccion_eliminar: Baja valida';
DECLARE @e INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQX');
EXEC torneo.seleccion_eliminar @e;
-- DECLARE @e_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQX');
-- SELECT * FROM torneo.seleccion WHERE seleccion_id = @e_r1;
GO

-- ============================================================
-- 3.5 torneo.partido
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.5.01 a E-3.5.04 torneo.partido_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.5.01 torneo.partido_insertar: Valido: UTC se deriva de la hora local (verificar con SELECT) => se acepta
PRINT '--- E-3.5.01 torneo.partido_insertar: Valido: UTC se deriva de la hora local (verificar con SELECT)';
DECLARE @id INT,
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
EXEC torneo.partido_insertar @sl, '2026-09-10 15:00:00 -03:00', 'dieciseisavos', @a4, @b1, NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.partido');
-- SELECT * FROM torneo.partido WHERE partido_id = @id_r1;
GO

-- E-3.5.02 torneo.partido_insertar: Valido: UTC informado y consistente => se acepta
PRINT '--- E-3.5.02 torneo.partido_insertar: Valido: UTC informado y consistente';
DECLARE @id INT,
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
EXEC torneo.partido_insertar @sl, '2026-09-15 15:00:00 -03:00', 'octavos', @a4, @b1, '2026-09-15 18:00:00 +00:00', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.partido');
-- SELECT * FROM torneo.partido WHERE partido_id = @id_r1;
GO

-- E-3.5.03 torneo.partido_insertar: Valido: sede con huso UTC-05 (UTC derivado = 20:00 +00:00) => se acepta
PRINT '--- E-3.5.03 torneo.partido_insertar: Valido: sede con huso UTC-05 (UTC derivado = 20:00 +00:00)';
DECLARE @id INT,
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @s5 INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Cinco');
EXEC torneo.partido_insertar @s5, '2026-09-20 15:00:00 -05:00', 'cuartos', @a3, @b1, NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.partido');
-- SELECT * FROM torneo.partido WHERE partido_id = @id_r1;
GO

-- E-3.5.04 torneo.partido_insertar: Valido: fase de grupos, mismo grupo => se acepta
PRINT '--- E-3.5.04 torneo.partido_insertar: Valido: fase de grupos, mismo grupo';
DECLARE @id INT,
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
EXEC torneo.partido_insertar @sl, '2026-09-25 15:00:00 -03:00', 'grupos', @a2, @a4, NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('torneo.partido');
-- SELECT * FROM torneo.partido WHERE partido_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.5.05 a E-3.5.09 torneo.partido_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.5.05 torneo.partido_modificar: Valido: cambia sede y fecha => se acepta
PRINT '--- E-3.5.05 torneo.partido_modificar: Valido: cambia sede y fecha';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
EXEC torneo.partido_modificar @m, @sl, '2026-06-22 15:00:00 -03:00', 'grupos', @a3, @a4;
-- DECLARE @a3_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
-- DECLARE @a4_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
-- DECLARE @m_r1 INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3_r1, @a4_r1) AND seleccion_visitante_id IN (@a3_r1, @a4_r1));
-- SELECT * FROM torneo.partido WHERE partido_id = @m_r1;
GO

-- E-3.5.06 torneo.partido_modificar: Valido: sin cambios => se acepta
PRINT '--- E-3.5.06 torneo.partido_modificar: Valido: sin cambios';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sm INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Mod');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4;
-- DECLARE @a3_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
-- DECLARE @a4_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
-- DECLARE @m_r1 INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3_r1, @a4_r1) AND seleccion_visitante_id IN (@a3_r1, @a4_r1));
-- SELECT * FROM torneo.partido WHERE partido_id = @m_r1;
GO

-- E-3.5.07 torneo.partido_modificar: Valido: se invierten local y visitante => se acepta
PRINT '--- E-3.5.07 torneo.partido_modificar: Valido: se invierten local y visitante';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sm INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Mod');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a4, @a3;
-- DECLARE @a3_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
-- DECLARE @a4_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
-- DECLARE @m_r1 INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3_r1, @a4_r1) AND seleccion_visitante_id IN (@a3_r1, @a4_r1));
-- SELECT * FROM torneo.partido WHERE partido_id = @m_r1;
GO

-- E-3.5.08 torneo.partido_modificar: Valido: pasa a suspendido => se acepta
PRINT '--- E-3.5.08 torneo.partido_modificar: Valido: pasa a suspendido';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sm INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Mod');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4, 'suspendido';
-- DECLARE @a3_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
-- DECLARE @a4_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
-- DECLARE @m_r1 INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3_r1, @a4_r1) AND seleccion_visitante_id IN (@a3_r1, @a4_r1));
-- SELECT * FROM torneo.partido WHERE partido_id = @m_r1;
GO

-- E-3.5.09 torneo.partido_modificar: Valido: se reprograma un partido con formaciones sin cambiar las selecciones => se acepta
PRINT '--- E-3.5.09 torneo.partido_modificar: Valido: se reprograma un partido con formaciones sin cambiar las selecciones';
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base');
DECLARE @form INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a1, @a4) AND seleccion_visitante_id IN (@a1, @a4));
EXEC torneo.partido_modificar @form, @sb, '2026-07-01 15:00:00 -03:00', 'cuartos', @a1, @a4;
-- DECLARE @a1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA');
-- DECLARE @a4_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
-- DECLARE @form_r1 INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a1_r1, @a4_r1) AND seleccion_visitante_id IN (@a1_r1, @a4_r1));
-- SELECT * FROM torneo.partido WHERE partido_id = @form_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.5.10 torneo.partido_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.5.10 torneo.partido_eliminar: Baja valida => se acepta
PRINT '--- E-3.5.10 torneo.partido_eliminar: Baja valida';
DECLARE @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
DECLARE @elim INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4));
EXEC torneo.partido_eliminar @elim;
-- DECLARE @a3_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC');
-- DECLARE @a4_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
-- DECLARE @elim_r1 INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a3_r1, @a4_r1) AND seleccion_visitante_id IN (@a3_r1, @a4_r1));
-- SELECT * FROM torneo.partido WHERE partido_id = @elim_r1;
GO

-- ============================================================
-- 3.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.6.01 a E-3.6.02 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error)
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.01 plantel.persona_insertar (el SP solo valida el tipo: Valido: jugador => se acepta
PRINT '--- E-3.6.01 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Valido: jugador';
DECLARE @id INT;
EXEC plantel.persona_insertar 'jugador', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.persona');
-- SELECT * FROM plantel.persona WHERE persona_id = @id_r1;
GO

-- E-3.6.02 plantel.persona_insertar (el SP solo valida el tipo: Valido => se acepta
PRINT '--- E-3.6.02 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Valido';
DECLARE @id INT;
EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.persona');
-- SELECT * FROM plantel.persona WHERE persona_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.6.03 a E-3.6.06 plantel.persona_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.03 plantel.persona_modificar: Valido => se acepta
PRINT '--- E-3.6.03 plantel.persona_modificar: Valido';
DECLARE @mod  INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
EXEC plantel.persona_modificar @mod, 'cuerpo_tecnico';
-- DECLARE @mod_r1 INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
-- SELECT * FROM plantel.persona WHERE persona_id = @mod_r1;
GO

-- E-3.6.04 plantel.persona_modificar: Valido: vuelve a jugador => se acepta
PRINT '--- E-3.6.04 plantel.persona_modificar: Valido: vuelve a jugador';
DECLARE @mod  INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
EXEC plantel.persona_modificar @mod, 'jugador';
-- DECLARE @mod_r1 INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
-- SELECT * FROM plantel.persona WHERE persona_id = @mod_r1;
GO

-- E-3.6.05 plantel.persona_modificar: Valido: sin cambios (mismo tipo) => se acepta
PRINT '--- E-3.6.05 plantel.persona_modificar: Valido: sin cambios (mismo tipo)';
DECLARE @mod  INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
EXEC plantel.persona_modificar @mod, 'jugador';
-- DECLARE @mod_r1 INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'mod');
-- SELECT * FROM plantel.persona WHERE persona_id = @mod_r1;
GO

-- E-3.6.06 plantel.persona_modificar: Valido: jugador registrado, mismo tipo => se acepta
PRINT '--- E-3.6.06 plantel.persona_modificar: Valido: jugador registrado, mismo tipo';
DECLARE @jug  INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'jug');
EXEC plantel.persona_modificar @jug, 'jugador';
-- DECLARE @jug_r1 INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'jug');
-- SELECT * FROM plantel.persona WHERE persona_id = @jug_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.6.07 a E-3.6.08 plantel.persona_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.07 plantel.persona_eliminar: Baja valida => se acepta
PRINT '--- E-3.6.07 plantel.persona_eliminar: Baja valida';
DECLARE @elim    INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'elim');
EXEC plantel.persona_eliminar @elim;
-- DECLARE @elim_r1 INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'elim');
-- SELECT * FROM plantel.persona WHERE persona_id = @elim_r1;
GO

-- E-3.6.08 plantel.persona_eliminar: Baja valida (tipo cuerpo tecnico, sin registros) => se acepta
PRINT '--- E-3.6.08 plantel.persona_eliminar: Baja valida (tipo cuerpo tecnico, sin registros)';
DECLARE @elim_ct INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'elim_ct');
EXEC plantel.persona_eliminar @elim_ct;
-- DECLARE @elim_ct_r1 INT = (SELECT persona_id FROM prueba.test_persona WHERE clave = 'elim_ct');
-- SELECT * FROM plantel.persona WHERE persona_id = @elim_ct_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.6.09 a E-3.6.15 plantel.cuerpo_tecnico_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.09 plantel.cuerpo_tecnico_insertar: Valido => se acepta
PRINT '--- E-3.6.09 plantel.cuerpo_tecnico_insertar: Valido';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Alta', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.cuerpo_tecnico');
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @id_r1;
GO

-- E-3.6.10 plantel.cuerpo_tecnico_insertar: Valido: se guarda recortado => se acepta
PRINT '--- E-3.6.10 plantel.cuerpo_tecnico_insertar: Valido: se guarda recortado';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
EXEC plantel.cuerpo_tecnico_insertar @s1, '  Test CT  ', '  Recortado  ', 'otro', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.cuerpo_tecnico');
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @id_r1;
GO

-- E-3.6.11 plantel.cuerpo_tecnico_insertar: Valido: DT en seleccion sin DT => se acepta
PRINT '--- E-3.6.11 plantel.cuerpo_tecnico_insertar: Valido: DT en seleccion sin DT';
DECLARE @id INT,
        @pid INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC');
EXEC plantel.cuerpo_tecnico_insertar @s3, 'Test CT', 'Alta DT', 'director_tecnico', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.cuerpo_tecnico');
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @id_r1;
GO

-- E-3.6.12 plantel.cuerpo_tecnico_insertar: Valido: misma persona con otro rol en la misma seleccion => se acepta
PRINT '--- E-3.6.12 plantel.cuerpo_tecnico_insertar: Valido: misma persona con otro rol en la misma seleccion';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Alta', 'preparador_fisico', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.cuerpo_tecnico');
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @id_r1;
GO

-- E-3.6.13 plantel.cuerpo_tecnico_insertar: Valido: misma persona y rol en otra seleccion => se acepta
PRINT '--- E-3.6.13 plantel.cuerpo_tecnico_insertar: Valido: misma persona y rol en otra seleccion';
DECLARE @id INT,
        @pid INT,
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB');
EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test CT', 'Alta', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.cuerpo_tecnico');
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @id_r1;
GO

-- E-3.6.14 plantel.cuerpo_tecnico_insertar: Valido: rol "otro" => se acepta
PRINT '--- E-3.6.14 plantel.cuerpo_tecnico_insertar: Valido: rol "otro"';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Rol Otro', 'otro', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.cuerpo_tecnico');
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @id_r1;
GO

-- E-3.6.15 plantel.cuerpo_tecnico_insertar: Valido: nombre de 100 caracteres (borde; ajustar si la columna es mas corta) => se acepta
PRINT '--- E-3.6.15 plantel.cuerpo_tecnico_insertar: Valido: nombre de 100 caracteres (borde; ajustar si la columna es mas corta)';
DECLARE @id INT,
        @pid INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @n100 VARCHAR(100) = 'Test CT' + REPLICATE('N', 93);
EXEC plantel.cuerpo_tecnico_insertar @s1, @n100, 'Largo', 'otro', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.cuerpo_tecnico');
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.6.16 a E-3.6.17 plantel.cuerpo_tecnico_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.16 plantel.cuerpo_tecnico_modificar: Valido: cambia seleccion, apellido y rol => se acepta
PRINT '--- E-3.6.16 plantel.cuerpo_tecnico_modificar: Valido: cambia seleccion, apellido y rol';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB');
EXEC plantel.cuerpo_tecnico_modificar @m, @s2, 'Test CT', 'Mod Nuevo', 'ayudante_tecnico';
-- DECLARE @m_r1 INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo'));
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @m_r1;
GO

-- E-3.6.17 plantel.cuerpo_tecnico_modificar: Valido: se guarda recortado => se acepta
PRINT '--- E-3.6.17 plantel.cuerpo_tecnico_modificar: Valido: se guarda recortado';
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '  Test CT  ', '  Mod  ', 'otro';
-- DECLARE @m_r1 INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo'));
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @m_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.6.18 plantel.cuerpo_tecnico_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.18 plantel.cuerpo_tecnico_eliminar: Baja valida (sin tarjetas): ambos 0 => se acepta
PRINT '--- E-3.6.18 plantel.cuerpo_tecnico_eliminar: Baja valida (sin tarjetas): ambos 0';
DECLARE @e  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim');
EXEC plantel.cuerpo_tecnico_eliminar @e;
-- DECLARE @e_r1 INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim');
-- SELECT * FROM plantel.cuerpo_tecnico WHERE staff_id = @e_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.6.19 a E-3.6.31 plantel.jugador_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.19 plantel.jugador_insertar: Valido => se acepta
PRINT '--- E-3.6.19 plantel.jugador_insertar: Valido';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar 'Test JU', 'Alta', '1995-03-15', 'delantero', 'Club Alta', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.20 plantel.jugador_insertar: Valido: se guarda recortado => se acepta
PRINT '--- E-3.6.20 plantel.jugador_insertar: Valido: se guarda recortado';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar '  Test JU  ', '  Recortado  ', '1995-03-15', 'defensor', '  Club Recortado  ', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.21 plantel.jugador_insertar: Valido: club nulo => se acepta
PRINT '--- E-3.6.21 plantel.jugador_insertar: Valido: club nulo';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar 'Test JU', 'Sin Club', '1995-03-15', 'arquero', NULL, @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.22 plantel.jugador_insertar: Valido: club vacio se guarda como NULL => se acepta
PRINT '--- E-3.6.22 plantel.jugador_insertar: Valido: club vacio se guarda como NULL';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar 'Test JU', 'Club Vacio', '1995-03-15', 'arquero', '', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.23 plantel.jugador_insertar: Valido: club solo espacios se guarda como NULL => se acepta
PRINT '--- E-3.6.23 plantel.jugador_insertar: Valido: club solo espacios se guarda como NULL';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar 'Test JU', 'Club Espacios', '1995-03-15', 'arquero', '   ', @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.24 plantel.jugador_insertar: Valido: sin pasar club (valor por defecto) => se acepta
PRINT '--- E-3.6.24 plantel.jugador_insertar: Valido: sin pasar club (valor por defecto)';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar 'Test JU', 'Sin Param Club', '1995-03-15', 'mediocampista', @jugador_id = @id OUTPUT, @persona_id = @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.25 plantel.jugador_insertar: Valido: club de 120 caracteres (borde) => se acepta
PRINT '--- E-3.6.25 plantel.jugador_insertar: Valido: club de 120 caracteres (borde)';
DECLARE @id INT,
        @pid INT,
        @c120 VARCHAR(120) = REPLICATE('C', 120);
EXEC plantel.jugador_insertar 'Test JU', 'Club Largo', '1995-03-15', 'delantero', @c120, @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.26 plantel.jugador_insertar: Valido: nombre de 100 caracteres (borde) => se acepta
PRINT '--- E-3.6.26 plantel.jugador_insertar: Valido: nombre de 100 caracteres (borde)';
DECLARE @id INT,
        @pid INT,
        @n100 VARCHAR(100) = 'Test JU' + REPLICATE('N', 93);
EXEC plantel.jugador_insertar @n100, 'Nombre Largo', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.27 plantel.jugador_insertar: Valido: posicion mediocampista => se acepta
PRINT '--- E-3.6.27 plantel.jugador_insertar: Valido: posicion mediocampista';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar 'Test JU', 'Mediocampista', '1995-03-15', 'mediocampista', NULL, @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.28 plantel.jugador_insertar: Valido: justo 15 anios (borde) => se acepta
PRINT '--- E-3.6.28 plantel.jugador_insertar: Valido: justo 15 anios (borde)';
DECLARE @id INT,
        @pid INT,
        @f15 DATE = DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE));
EXEC plantel.jugador_insertar 'Test JU', 'Borde 15', @f15, 'delantero', NULL, @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.29 plantel.jugador_insertar: Valido: justo 50 anios (borde) => se acepta
PRINT '--- E-3.6.29 plantel.jugador_insertar: Valido: justo 50 anios (borde)';
DECLARE @id INT,
        @pid INT,
        @f50 DATE = DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE));
EXEC plantel.jugador_insertar 'Test JU', 'Borde 50', @f50, 'delantero', NULL, @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.30 plantel.jugador_insertar: Valido: mismo nombre y apellido con otra fecha => se acepta
PRINT '--- E-3.6.30 plantel.jugador_insertar: Valido: mismo nombre y apellido con otra fecha';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar 'Test JU', 'Base', '1996-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- E-3.6.31 plantel.jugador_insertar: Valido: misma fecha que otros jugadores con otro apellido => se acepta
PRINT '--- E-3.6.31 plantel.jugador_insertar: Valido: misma fecha que otros jugadores con otro apellido';
DECLARE @id INT,
        @pid INT;
EXEC plantel.jugador_insertar 'Test JU', 'Otra Fecha Igual', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.jugador');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.6.32 a E-3.6.36 plantel.jugador_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.32 plantel.jugador_modificar: Valido: cambia apellido, fecha, posicion y club => se acepta
PRINT '--- E-3.6.32 plantel.jugador_modificar: Valido: cambia apellido, fecha, posicion y club';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod Nuevo', '1996-06-20', 'delantero', 'Club Nuevo';
-- DECLARE @m_r1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
-- SELECT * FROM plantel.jugador WHERE jugador_id = @m_r1;
GO

-- E-3.6.33 plantel.jugador_modificar: Valido: club vacio se guarda como NULL => se acepta
PRINT '--- E-3.6.33 plantel.jugador_modificar: Valido: club vacio se guarda como NULL';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor', '';
-- DECLARE @m_r1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
-- SELECT * FROM plantel.jugador WHERE jugador_id = @m_r1;
GO

-- E-3.6.34 plantel.jugador_modificar: Valido: club solo espacios se guarda como NULL => se acepta
PRINT '--- E-3.6.34 plantel.jugador_modificar: Valido: club solo espacios se guarda como NULL';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor', '   ';
-- DECLARE @m_r1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
-- SELECT * FROM plantel.jugador WHERE jugador_id = @m_r1;
GO

-- E-3.6.35 plantel.jugador_modificar: Valido: sin pasar club (valor por defecto) => se acepta
PRINT '--- E-3.6.35 plantel.jugador_modificar: Valido: sin pasar club (valor por defecto)';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor';
-- DECLARE @m_r1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
-- SELECT * FROM plantel.jugador WHERE jugador_id = @m_r1;
GO

-- E-3.6.36 plantel.jugador_modificar: Valido: posicion mediocampista => se acepta
PRINT '--- E-3.6.36 plantel.jugador_modificar: Valido: posicion mediocampista';
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'mediocampista', 'Club Mod';
-- DECLARE @m_r1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo'));
-- SELECT * FROM plantel.jugador WHERE jugador_id = @m_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.6.37 plantel.jugador_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.6.37 plantel.jugador_eliminar: Baja valida (sin convocatorias, formaciones ni tarjetas) => se acepta
PRINT '--- E-3.6.37 plantel.jugador_eliminar: Baja valida (sin convocatorias, formaciones ni tarjetas)';
DECLARE @e INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Elim');
EXEC plantel.jugador_eliminar @e;
-- DECLARE @e_r1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Elim');
-- SELECT * FROM plantel.jugador WHERE jugador_id = @e_r1;
GO

-- ============================================================
-- 3.7 plantel.convocatoria
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.7.01 a E-3.7.12 plantel.convocatoria_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.7.01 plantel.convocatoria_insertar: Valido => se acepta
PRINT '--- E-3.7.01 plantel.convocatoria_insertar: Valido';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @l1  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 1');
EXEC plantel.convocatoria_insertar @s3, @l1, 1, '2026-06-01', 'Convocatoria inicial', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.02 plantel.convocatoria_insertar: Valido: motivo se guarda recortado => se acepta
PRINT '--- E-3.7.02 plantel.convocatoria_insertar: Valido: motivo se guarda recortado';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @l2  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 2');
EXEC plantel.convocatoria_insertar @s3, @l2, 2, '2026-06-01', '  Motivo con espacios  ', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.03 plantel.convocatoria_insertar: Valido: motivo nulo => se acepta
PRINT '--- E-3.7.03 plantel.convocatoria_insertar: Valido: motivo nulo';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @l3  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 3');
EXEC plantel.convocatoria_insertar @s3, @l3, 3, '2026-06-01', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.04 plantel.convocatoria_insertar: Valido: motivo vacio se guarda como NULL => se acepta
PRINT '--- E-3.7.04 plantel.convocatoria_insertar: Valido: motivo vacio se guarda como NULL';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @l4  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 4');
EXEC plantel.convocatoria_insertar @s3, @l4, 4, '2026-06-01', '', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.05 plantel.convocatoria_insertar: Valido: motivo solo espacios se guarda como NULL => se acepta
PRINT '--- E-3.7.05 plantel.convocatoria_insertar: Valido: motivo solo espacios se guarda como NULL';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @l5  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 5');
EXEC plantel.convocatoria_insertar @s3, @l5, 5, '2026-06-01', '   ', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.06 plantel.convocatoria_insertar: Valido: sin pasar motivo (valor por defecto) => se acepta
PRINT '--- E-3.7.06 plantel.convocatoria_insertar: Valido: sin pasar motivo (valor por defecto)';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @l6  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 6');
EXEC plantel.convocatoria_insertar @s3, @l6, 6, '2026-06-01', @convocatoria_id = @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.07 plantel.convocatoria_insertar: Valido: dorsal minimo (borde) => se acepta
PRINT '--- E-3.7.07 plantel.convocatoria_insertar: Valido: dorsal minimo (borde)';
DECLARE @id INT,
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @l7  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 7');
EXEC plantel.convocatoria_insertar @s2, @l7, 1, '2026-06-01', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.08 plantel.convocatoria_insertar: Valido: dorsal maximo (borde) => se acepta
PRINT '--- E-3.7.08 plantel.convocatoria_insertar: Valido: dorsal maximo (borde)';
DECLARE @id INT,
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @l8  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 8');
EXEC plantel.convocatoria_insertar @s2, @l8, 99, '2026-06-01', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.09 plantel.convocatoria_insertar: Valido: dorsal 5 usado solo por una convocatoria historica => se acepta
PRINT '--- E-3.7.09 plantel.convocatoria_insertar: Valido: dorsal 5 usado solo por una convocatoria historica';
DECLARE @id INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @l9  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 9');
EXEC plantel.convocatoria_insertar @s1, @l9, 5, '2026-06-01', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.10 plantel.convocatoria_insertar: Valido: mismo dorsal que usa s1, pero en otra seleccion => se acepta
PRINT '--- E-3.7.10 plantel.convocatoria_insertar: Valido: mismo dorsal que usa s1, pero en otra seleccion';
DECLARE @id INT,
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @l10 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 10');
EXEC plantel.convocatoria_insertar @s3, @l10, 7, '2026-06-01', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.11 plantel.convocatoria_insertar: Valido: jugador con convocatoria historica vuelve a ser convocado en la misma seleccion => se acepta
PRINT '--- E-3.7.11 plantel.convocatoria_insertar: Valido: jugador con convocatoria historica vuelve a ser convocado en la misma seleccion';
DECLARE @id INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @jb  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Baja');
EXEC plantel.convocatoria_insertar @s1, @jb, 6, '2026-06-01', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- E-3.7.12 plantel.convocatoria_insertar: Valido: jugador con convocatoria historica convocado por otra seleccion => se acepta
PRINT '--- E-3.7.12 plantel.convocatoria_insertar: Valido: jugador con convocatoria historica convocado por otra seleccion';
DECLARE @id INT,
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @jb2 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Baja 2');
EXEC plantel.convocatoria_insertar @s2, @jb2, 6, '2026-06-01', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.convocatoria');
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.7.13 a E-3.7.26 plantel.convocatoria_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.7.13 plantel.convocatoria_modificar: Valido: cambia dorsal, fecha y motivo de alta => se acepta
PRINT '--- E-3.7.13 plantel.convocatoria_modificar: Valido: cambia dorsal, fecha y motivo de alta';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 12, '2026-06-02', 'Motivo nuevo', NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.14 plantel.convocatoria_modificar: Valido: sin cambios (no choca consigo misma) => se acepta
PRINT '--- E-3.7.14 plantel.convocatoria_modificar: Valido: sin cambios (no choca consigo misma)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', 'Motivo inicial', NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.15 plantel.convocatoria_modificar: Valido: motivo de alta se guarda recortado => se acepta
PRINT '--- E-3.7.15 plantel.convocatoria_modificar: Valido: motivo de alta se guarda recortado';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '  Motivo  ', NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.16 plantel.convocatoria_modificar: Valido: motivo de alta nulo => se acepta
PRINT '--- E-3.7.16 plantel.convocatoria_modificar: Valido: motivo de alta nulo';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.17 plantel.convocatoria_modificar: Valido: motivo de alta vacio se guarda como NULL => se acepta
PRINT '--- E-3.7.17 plantel.convocatoria_modificar: Valido: motivo de alta vacio se guarda como NULL';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '', NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.18 plantel.convocatoria_modificar: Valido: motivo de alta solo espacios se guarda como NULL => se acepta
PRINT '--- E-3.7.18 plantel.convocatoria_modificar: Valido: motivo de alta solo espacios se guarda como NULL';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '   ', NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.19 plantel.convocatoria_modificar: Valido: sin pasar motivo ni baja (valores por defecto) => se acepta
PRINT '--- E-3.7.19 plantel.convocatoria_modificar: Valido: sin pasar motivo ni baja (valores por defecto)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01';
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.20 plantel.convocatoria_modificar: Valido: dorsal minimo (borde) => se acepta
PRINT '--- E-3.7.20 plantel.convocatoria_modificar: Valido: dorsal minimo (borde)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 1, '2026-06-01', NULL, NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.21 plantel.convocatoria_modificar: Valido: dorsal maximo (borde) => se acepta
PRINT '--- E-3.7.21 plantel.convocatoria_modificar: Valido: dorsal maximo (borde)';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 99, '2026-06-01', NULL, NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.22 plantel.convocatoria_modificar: Valido: dorsal 4 usado solo por una convocatoria historica => se acepta
PRINT '--- E-3.7.22 plantel.convocatoria_modificar: Valido: dorsal 4 usado solo por una convocatoria historica';
DECLARE @cm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cm, 4, '2026-06-01', NULL, NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cm_r1;
GO

-- E-3.7.23 plantel.convocatoria_modificar: Valido: registrar la baja (queda historica) => se acepta
PRINT '--- E-3.7.23 plantel.convocatoria_modificar: Valido: registrar la baja (queda historica)';
DECLARE @cbm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cbm = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja Mod' AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, '2026-06-20', 'Lesion';
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cbm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja Mod' AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cbm_r1;
GO

-- E-3.7.24 plantel.convocatoria_modificar: Valido: baja el mismo dia del alta (borde) => se acepta
PRINT '--- E-3.7.24 plantel.convocatoria_modificar: Valido: baja el mismo dia del alta (borde)';
DECLARE @cbm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cbm = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja Mod' AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, '2026-06-01', 'Reemplazo';
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cbm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja Mod' AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cbm_r1;
GO

-- E-3.7.25 plantel.convocatoria_modificar: Valido: reactivar la baja (vuelve a ser vigente; ejecutar despues de registrar la baja) => se acepta
PRINT '--- E-3.7.25 plantel.convocatoria_modificar: Valido: reactivar la baja (vuelve a ser vigente; ejecutar despues de registrar la baja)';
DECLARE @cbm INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cbm = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja Mod' AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, NULL, NULL;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cbm_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja Mod' AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cbm_r1;
GO

-- E-3.7.26 plantel.convocatoria_modificar: Valido: corregir fecha y motivo de baja de una historica => se acepta
PRINT '--- E-3.7.26 plantel.convocatoria_modificar: Valido: corregir fecha y motivo de baja de una historica';
DECLARE @cb INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cb  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja'     AND c.seleccion_id = @s1 AND c.fecha_baja IS NOT NULL);
EXEC plantel.convocatoria_modificar @cb, 5, '2026-05-01', NULL, '2026-05-25', 'Reemplazo';
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @cb_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja'     AND c.seleccion_id = @s1_r1 AND c.fecha_baja IS NOT NULL);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @cb_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.7.27 a E-3.7.28 plantel.convocatoria_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.7.27 plantel.convocatoria_eliminar: Baja valida: convocatoria vigente sin formaciones => se acepta
PRINT '--- E-3.7.27 plantel.convocatoria_eliminar: Baja valida: convocatoria vigente sin formaciones';
DECLARE @ce INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @ce  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Elim'      AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_eliminar @ce;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @ce_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Elim'      AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @ce_r1;
GO

-- E-3.7.28 plantel.convocatoria_eliminar: Baja valida: convocatoria historica (con baja) sin formaciones => se acepta
PRINT '--- E-3.7.28 plantel.convocatoria_eliminar: Baja valida: convocatoria historica (con baja) sin formaciones';
DECLARE @ceb INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @ceb = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Elim Baja' AND c.seleccion_id = @s1);
EXEC plantel.convocatoria_eliminar @ceb;
-- DECLARE @s1_r1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
-- DECLARE @ceb_r1 INT = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Elim Baja' AND c.seleccion_id = @s1_r1);
-- SELECT * FROM plantel.convocatoria WHERE convocatoria_id = @ceb_r1;
GO

-- ============================================================
-- 3.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.8.01 a E-3.8.06 plantel.formacion_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.8.01 plantel.formacion_insertar: Valido => se acepta
PRINT '--- E-3.8.01 plantel.formacion_insertar: Valido';
DECLARE @id INT,
        @pa INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_a');
EXEC plantel.formacion_insertar @pa, 'local', '4-3-3', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.formacion');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @id_r1;
GO

-- E-3.8.02 plantel.formacion_insertar: Valido: mismo partido, la otra condicion => se acepta
PRINT '--- E-3.8.02 plantel.formacion_insertar: Valido: mismo partido, la otra condicion';
DECLARE @id INT,
        @pa INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_a');
EXEC plantel.formacion_insertar @pa, 'visitante', '4-4-2', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.formacion');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @id_r1;
GO

-- E-3.8.03 plantel.formacion_insertar: Valido: otro esquema de 3 lineas => se acepta
PRINT '--- E-3.8.03 plantel.formacion_insertar: Valido: otro esquema de 3 lineas';
DECLARE @id INT,
        @pb INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_b');
EXEC plantel.formacion_insertar @pb, 'local', '3-5-2', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.formacion');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @id_r1;
GO

-- E-3.8.04 plantel.formacion_insertar: Valido: esquema de 4 lineas => se acepta
PRINT '--- E-3.8.04 plantel.formacion_insertar: Valido: esquema de 4 lineas';
DECLARE @id INT,
        @pb INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_b');
EXEC plantel.formacion_insertar @pb, 'visitante', '4-2-3-1', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.formacion');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @id_r1;
GO

-- E-3.8.05 plantel.formacion_insertar: Valido: 5 lineas y 9 caracteres (borde maximo) => se acepta
PRINT '--- E-3.8.05 plantel.formacion_insertar: Valido: 5 lineas y 9 caracteres (borde maximo)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
EXEC plantel.formacion_insertar @pc, 'local', '1-1-1-1-6', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.formacion');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @id_r1;
GO

-- E-3.8.06 plantel.formacion_insertar: Valido: 3 lineas (borde minimo) => se acepta
PRINT '--- E-3.8.06 plantel.formacion_insertar: Valido: 3 lineas (borde minimo)';
DECLARE @id INT,
        @pc INT = (SELECT partido_id FROM prueba.test_formacion WHERE clave = 'ins_c');
EXEC plantel.formacion_insertar @pc, 'visitante', '1-1-8', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('plantel.formacion');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.8.07 a E-3.8.11 plantel.formacion_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.8.07 plantel.formacion_modificar: Valido: cambia el esquema => se acepta
PRINT '--- E-3.8.07 plantel.formacion_modificar: Valido: cambia el esquema';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
EXEC plantel.formacion_modificar @fm, '4-3-3';
-- DECLARE @fm_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @fm_r1;
GO

-- E-3.8.08 plantel.formacion_modificar: Valido: otro esquema de 3 lineas => se acepta
PRINT '--- E-3.8.08 plantel.formacion_modificar: Valido: otro esquema de 3 lineas';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
EXEC plantel.formacion_modificar @fm, '3-5-2';
-- DECLARE @fm_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @fm_r1;
GO

-- E-3.8.09 plantel.formacion_modificar: Valido: 5 lineas y 9 caracteres (borde maximo) => se acepta
PRINT '--- E-3.8.09 plantel.formacion_modificar: Valido: 5 lineas y 9 caracteres (borde maximo)';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
EXEC plantel.formacion_modificar @fm, '1-1-1-1-6';
-- DECLARE @fm_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @fm_r1;
GO

-- E-3.8.10 plantel.formacion_modificar: Valido: 3 lineas (borde minimo) => se acepta
PRINT '--- E-3.8.10 plantel.formacion_modificar: Valido: 3 lineas (borde minimo)';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
EXEC plantel.formacion_modificar @fm, '1-1-8';
-- DECLARE @fm_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @fm_r1;
GO

-- E-3.8.11 plantel.formacion_modificar: Valido: deja la formacion como en la preparacion => se acepta
PRINT '--- E-3.8.11 plantel.formacion_modificar: Valido: deja la formacion como en la preparacion';
DECLARE @fm INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
EXEC plantel.formacion_modificar @fm, '4-4-2';
-- DECLARE @fm_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'mod');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @fm_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.8.12 a E-3.8.13 plantel.formacion_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.8.12 plantel.formacion_eliminar: Baja valida: formacion sin jugadores de partido no finalizado => se acepta
PRINT '--- E-3.8.12 plantel.formacion_eliminar: Baja valida: formacion sin jugadores de partido no finalizado';
DECLARE @fe  INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'elim');
EXEC plantel.formacion_eliminar @fe;
-- DECLARE @fe_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'elim');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @fe_r1;
GO

-- E-3.8.13 plantel.formacion_eliminar: Baja valida: la otra condicion del mismo partido => se acepta
PRINT '--- E-3.8.13 plantel.formacion_eliminar: Baja valida: la otra condicion del mismo partido';
DECLARE @fe2 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'elim2');
EXEC plantel.formacion_eliminar @fe2;
-- DECLARE @fe2_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'elim2');
-- SELECT * FROM plantel.formacion WHERE formacion_id = @fe2_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.8.14 a E-3.8.18 plantel.formacion_jugador_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.8.14 plantel.formacion_jugador_insertar: Valido: titular (toma el dorsal 3 de su convocatoria) => se acepta
PRINT '--- E-3.8.14 plantel.formacion_jugador_insertar: Valido: titular (toma el dorsal 3 de su convocatoria)';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @ins  INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'ins');
EXEC plantel.formacion_jugador_insertar @fj, @ins, 'Delantero', 1;
-- DECLARE @fj_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
-- DECLARE @ins_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'ins');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fj_r1 AND jugador_id = @ins_r1;
GO

-- E-3.8.15 plantel.formacion_jugador_insertar: Valido: suplente en una formacion con los titulares completos => se acepta
PRINT '--- E-3.8.15 plantel.formacion_jugador_insertar: Valido: suplente en una formacion con los titulares completos';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @l1   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_1');
EXEC plantel.formacion_jugador_insertar @fl, @l1, 'Lateral', 0;
-- DECLARE @fl_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit');
-- DECLARE @l1_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_1');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fl_r1 AND jugador_id = @l1_r1;
GO

-- E-3.8.16 plantel.formacion_jugador_insertar: Valido: la posicion se guarda recortada => se acepta
PRINT '--- E-3.8.16 plantel.formacion_jugador_insertar: Valido: la posicion se guarda recortada';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @l2   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_2');
EXEC plantel.formacion_jugador_insertar @fl, @l2, '  Lateral  ', 0;
-- DECLARE @fl_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit');
-- DECLARE @l2_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'lib_2');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fl_r1 AND jugador_id = @l2_r1;
GO

-- E-3.8.17 plantel.formacion_jugador_insertar: Valido: convocatoria con alta el mismo dia del partido (borde) => se acepta
PRINT '--- E-3.8.17 plantel.formacion_jugador_insertar: Valido: convocatoria con alta el mismo dia del partido (borde)';
DECLARE @fl INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit'),
        @adia INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'alta_dia');
EXEC plantel.formacion_jugador_insertar @fl, @adia, 'Lateral', 0;
-- DECLARE @fl_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_tit');
-- DECLARE @adia_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'alta_dia');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fl_r1 AND jugador_id = @adia_r1;
GO

-- E-3.8.18 plantel.formacion_jugador_insertar: Valido: titular en una formacion con el banco de suplentes completo => se acepta
PRINT '--- E-3.8.18 plantel.formacion_jugador_insertar: Valido: titular en una formacion con el banco de suplentes completo';
DECLARE @fs INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_sup'),
        @sn   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sup_nuevo');
EXEC plantel.formacion_jugador_insertar @fs, @sn, 'Delantero', 1;
-- DECLARE @fs_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'fl_sup');
-- DECLARE @sn_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'sup_nuevo');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fs_r1 AND jugador_id = @sn_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.8.19 a E-3.8.23 plantel.formacion_jugador_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.8.19 plantel.formacion_jugador_modificar: Valido: cambia la posicion => se acepta
PRINT '--- E-3.8.19 plantel.formacion_jugador_modificar: Valido: cambia la posicion';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
EXEC plantel.formacion_jugador_modificar @fj, @base, 'Extremo', 1;
-- DECLARE @fj_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
-- DECLARE @base_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fj_r1 AND jugador_id = @base_r1;
GO

-- E-3.8.20 plantel.formacion_jugador_modificar: Valido: sin cambios (deja al jugador como en la preparacion) => se acepta
PRINT '--- E-3.8.20 plantel.formacion_jugador_modificar: Valido: sin cambios (deja al jugador como en la preparacion)';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 1;
-- DECLARE @fj_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
-- DECLARE @base_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fj_r1 AND jugador_id = @base_r1;
GO

-- E-3.8.21 plantel.formacion_jugador_modificar: Valido: la posicion se guarda recortada => se acepta
PRINT '--- E-3.8.21 plantel.formacion_jugador_modificar: Valido: la posicion se guarda recortada';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
EXEC plantel.formacion_jugador_modificar @fj, @base, '  Extremo  ', 1;
-- DECLARE @fj_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
-- DECLARE @base_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fj_r1 AND jugador_id = @base_r1;
GO

-- E-3.8.22 plantel.formacion_jugador_modificar: Valido: titular pasa a suplente (sin sustituciones); restaurar con el caso siguiente => se acepta
PRINT '--- E-3.8.22 plantel.formacion_jugador_modificar: Valido: titular pasa a suplente (sin sustituciones); restaurar con el caso siguiente';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 0;
-- DECLARE @fj_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
-- DECLARE @base_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fj_r1 AND jugador_id = @base_r1;
GO

-- E-3.8.23 plantel.formacion_jugador_modificar: Valido: suplente vuelve a titular => se acepta
PRINT '--- E-3.8.23 plantel.formacion_jugador_modificar: Valido: suplente vuelve a titular';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @base INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 1;
-- DECLARE @fj_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
-- DECLARE @base_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'base');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fj_r1 AND jugador_id = @base_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.8.24 a E-3.8.25 plantel.formacion_jugador_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.8.24 plantel.formacion_jugador_eliminar: Baja valida: jugador sin sustituciones, goles ni tarjetas => se acepta
PRINT '--- E-3.8.24 plantel.formacion_jugador_eliminar: Baja valida: jugador sin sustituciones, goles ni tarjetas';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @elim INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'elim');
EXEC plantel.formacion_jugador_eliminar @fj, @elim;
-- DECLARE @fj_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
-- DECLARE @elim_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'elim');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fj_r1 AND jugador_id = @elim_r1;
GO

-- E-3.8.25 plantel.formacion_jugador_eliminar: Baja valida: jugador cuya convocatoria ya no esta vigente => se acepta
PRINT '--- E-3.8.25 plantel.formacion_jugador_eliminar: Baja valida: jugador cuya convocatoria ya no esta vigente';
DECLARE @fj INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug'),
        @zb   INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'z_baja');
EXEC plantel.formacion_jugador_eliminar @fj, @zb;
-- DECLARE @fj_r1 INT = (SELECT formacion_id FROM prueba.test_formacion WHERE clave = 'jug');
-- DECLARE @zb_r1 INT = (SELECT jugador_id FROM prueba.test_fjugador WHERE clave = 'z_baja');
-- SELECT * FROM plantel.formacion_jugador WHERE formacion_id = @fj_r1 AND jugador_id = @zb_r1;
GO

-- ============================================================
-- 3.9 evento.sustitucion
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.9.01 a E-3.9.05 evento.sustitucion_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.9.01 evento.sustitucion_insertar: Valido: minuto minimo de PT (borde), primera ventana => se acepta
PRINT '--- E-3.9.01 evento.sustitucion_insertar: Valido: minuto minimo de PT (borde), primera ventana';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t1'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1');
EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico',    @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.sustitucion');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @id_r1;
GO

-- E-3.9.02 evento.sustitucion_insertar: Valido: minuto maximo de PT (borde), misma ventana que el cambio anterior => se acepta
PRINT '--- E-3.9.02 evento.sustitucion_insertar: Valido: minuto maximo de PT (borde), misma ventana que el cambio anterior';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t2'),
        @os2 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s2');
EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion',     @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.sustitucion');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @id_r1;
GO

-- E-3.9.03 evento.sustitucion_insertar: Valido: reemplaza a quien ingresó antes (ejecutar despues del primero), minuto minimo de ST, ventana siguiente => se acepta
PRINT '--- E-3.9.03 evento.sustitucion_insertar: Valido: reemplaza a quien ingresó antes (ejecutar despues del primero), minuto minimo de ST, ventana siguiente';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @os1 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s1'),
        @os3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s3');
EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.sustitucion');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @id_r1;
GO

-- E-3.9.04 evento.sustitucion_insertar: Valido: minuto maximo de ST (borde), misma ventana => se acepta
PRINT '--- E-3.9.04 evento.sustitucion_insertar: Valido: minuto maximo de ST (borde), misma ventana';
DECLARE @id INT,
        @fo INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_ok'),
        @ot3 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_t3'),
        @os4 INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'ok_s4');
EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico',    @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.sustitucion');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @id_r1;
GO

-- E-3.9.05 evento.sustitucion_insertar: Valido: primer cambio adicional del alargue, primera ventana adicional, minuto minimo de alargue_1 (borde) => se acepta
PRINT '--- E-3.9.05 evento.sustitucion_insertar: Valido: primer cambio adicional del alargue, primera ventana adicional, minuto minimo de alargue_1 (borde)';
DECLARE @id INT,
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @V1 INT,
        @fa INT = (SELECT formacion_id FROM prueba.test_sustitucion WHERE clave = 'f_alg'),
        @atl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'alg_tl'),
        @asl INT = (SELECT jugador_id FROM prueba.test_sustitucion WHERE clave = 'alg_sl');
SET @V1  = @V + 1;
EXEC evento.sustitucion_insertar @fa, @atl, @asl, 90, 'alargue_1', @V1, 'tactico', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.sustitucion');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.9.06 a E-3.9.10 evento.sustitucion_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.9.06 evento.sustitucion_modificar: Valido: cambia minuto y motivo => se acepta
PRINT '--- E-3.9.06 evento.sustitucion_modificar: Valido: cambia minuto y motivo';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
EXEC evento.sustitucion_modificar @m1, 25, 'PT', 1, 'lesion';
-- DECLARE @m1_r1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @m1_r1;
GO

-- E-3.9.07 evento.sustitucion_modificar: Valido: minuto minimo de PT (borde) => se acepta
PRINT '--- E-3.9.07 evento.sustitucion_modificar: Valido: minuto minimo de PT (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
EXEC evento.sustitucion_modificar @m1, 1,  'PT', 1, 'tactico';
-- DECLARE @m1_r1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @m1_r1;
GO

-- E-3.9.08 evento.sustitucion_modificar: Valido: minuto maximo de PT (borde) => se acepta
PRINT '--- E-3.9.08 evento.sustitucion_modificar: Valido: minuto maximo de PT (borde)';
DECLARE @m1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');  -- PT, ventana 1
EXEC evento.sustitucion_modificar @m1, 60, 'PT', 1, 'precaucion';
-- DECLARE @m1_r1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x1');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @m1_r1;
GO

-- E-3.9.09 evento.sustitucion_modificar: Valido: minuto minimo de ST (borde) => se acepta
PRINT '--- E-3.9.09 evento.sustitucion_modificar: Valido: minuto minimo de ST (borde)';
DECLARE @m2 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x2');  -- ST, ventana 2
EXEC evento.sustitucion_modificar @m2, 45,  'ST', 2, 'tactico';
-- DECLARE @m2_r1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x2');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @m2_r1;
GO

-- E-3.9.10 evento.sustitucion_modificar: Valido: minuto maximo de ST (borde) => se acepta
PRINT '--- E-3.9.10 evento.sustitucion_modificar: Valido: minuto maximo de ST (borde)';
DECLARE @m2 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x2');  -- ST, ventana 2
EXEC evento.sustitucion_modificar @m2, 110, 'ST', 2, 'lesion';
-- DECLARE @m2_r1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'gen_x2');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @m2_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.9.11 a E-3.9.13 evento.sustitucion_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.9.11 evento.sustitucion_eliminar: Baja valida: el que ingresó no fue reemplazado ni tiene goles => se acepta
PRINT '--- E-3.9.11 evento.sustitucion_eliminar: Baja valida: el que ingresó no fue reemplazado ni tiene goles';
DECLARE @e1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'eli_x1');
EXEC evento.sustitucion_eliminar @e1;
-- DECLARE @e1_r1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'eli_x1');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @e1_r1;
GO

-- E-3.9.12 evento.sustitucion_eliminar: Baja valida: cambio posterior sin consecuencias => se acepta
PRINT '--- E-3.9.12 evento.sustitucion_eliminar: Baja valida: cambio posterior sin consecuencias';
DECLARE @e3 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'eli_x3');
EXEC evento.sustitucion_eliminar @e3;
-- DECLARE @e3_r1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'eli_x3');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @e3_r1;
GO

-- E-3.9.13 evento.sustitucion_eliminar: Baja valida: ejecutar DESPUES de eliminar x3 => se acepta
PRINT '--- E-3.9.13 evento.sustitucion_eliminar: Baja valida: ejecutar DESPUES de eliminar x3';
DECLARE @e2 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'eli_x2');
EXEC evento.sustitucion_eliminar @e2;
-- DECLARE @e2_r1 INT = (SELECT sustitucion_id FROM prueba.test_sustitucion WHERE clave = 'eli_x2');
-- SELECT * FROM evento.sustitucion WHERE sustitucion_id = @e2_r1;
GO

-- ============================================================
-- 3.10 evento.gol (cada operación actualiza el marcador del partido en la misma transacción)
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.10.01 a E-3.10.30 evento.gol_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.10.01 evento.gol_insertar: Valido: con asistencia => se acepta
PRINT '--- E-3.10.01 evento.gol_insertar: Valido: con asistencia';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @t2 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t2');
EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @t2, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.02 evento.gol_insertar: Valido: sin asistencia => se acepta
PRINT '--- E-3.10.02 evento.gol_insertar: Valido: sin asistencia';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 16, 'jugada', 'PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.03 evento.gol_insertar: Valido: tipo penal => se acepta
PRINT '--- E-3.10.03 evento.gol_insertar: Valido: tipo penal';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 18, 'penal', 'PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.04 evento.gol_insertar: Valido: tipo tiro_libre => se acepta
PRINT '--- E-3.10.04 evento.gol_insertar: Valido: tipo tiro_libre';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 19, 'tiro_libre', 'PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.05 evento.gol_insertar: Valido: tipo cabezazo => se acepta
PRINT '--- E-3.10.05 evento.gol_insertar: Valido: tipo cabezazo';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @t2 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t2');
EXEC evento.gol_insertar @fl, @t1, 20, 'cabezazo', 'PT', @t2, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.06 evento.gol_insertar: Valido: tipo otro => se acepta
PRINT '--- E-3.10.06 evento.gol_insertar: Valido: tipo otro';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 21, 'otro', 'PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.07 evento.gol_insertar: Valido: gol en contra sin asistencia (suma al rival) => se acepta
PRINT '--- E-3.10.07 evento.gol_insertar: Valido: gol en contra sin asistencia (suma al rival)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 22, 'en_contra', 'PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.08 evento.gol_insertar: Valido: PT minuto minimo (borde) => se acepta
PRINT '--- E-3.10.08 evento.gol_insertar: Valido: PT minuto minimo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 1, 'jugada', 'PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.09 evento.gol_insertar: Valido: PT minuto maximo (borde) => se acepta
PRINT '--- E-3.10.09 evento.gol_insertar: Valido: PT minuto maximo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 45, 'jugada', 'PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.10 evento.gol_insertar: Valido: adicional_PT minimo (borde) => se acepta
PRINT '--- E-3.10.10 evento.gol_insertar: Valido: adicional_PT minimo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 46, 'jugada', 'adicional_PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.11 evento.gol_insertar: Valido: adicional_PT maximo (borde) => se acepta
PRINT '--- E-3.10.11 evento.gol_insertar: Valido: adicional_PT maximo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 60, 'jugada', 'adicional_PT', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.12 evento.gol_insertar: Valido: ST minimo (borde) => se acepta
PRINT '--- E-3.10.12 evento.gol_insertar: Valido: ST minimo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 46, 'jugada', 'ST', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.13 evento.gol_insertar: Valido: ST maximo (borde) => se acepta
PRINT '--- E-3.10.13 evento.gol_insertar: Valido: ST maximo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 90, 'jugada', 'ST', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.14 evento.gol_insertar: Valido: adicional_ST minimo (borde) => se acepta
PRINT '--- E-3.10.14 evento.gol_insertar: Valido: adicional_ST minimo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 91, 'jugada', 'adicional_ST', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.15 evento.gol_insertar: Valido: adicional_ST maximo (borde) => se acepta
PRINT '--- E-3.10.15 evento.gol_insertar: Valido: adicional_ST maximo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 110, 'jugada', 'adicional_ST', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.16 evento.gol_insertar: Valido: alargue_1 minimo (borde; partido de fase final) => se acepta
PRINT '--- E-3.10.16 evento.gol_insertar: Valido: alargue_1 minimo (borde; partido de fase final)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 91, 'jugada', 'alargue_1', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.17 evento.gol_insertar: Valido: alargue_1 maximo (borde) => se acepta
PRINT '--- E-3.10.17 evento.gol_insertar: Valido: alargue_1 maximo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 105, 'jugada', 'alargue_1', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.18 evento.gol_insertar: Valido: alargue_2 minimo (borde) => se acepta
PRINT '--- E-3.10.18 evento.gol_insertar: Valido: alargue_2 minimo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 106, 'jugada', 'alargue_2', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.19 evento.gol_insertar: Valido: alargue_2 maximo (borde) => se acepta
PRINT '--- E-3.10.19 evento.gol_insertar: Valido: alargue_2 maximo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 120, 'jugada', 'alargue_2', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.20 evento.gol_insertar: Valido: adicional_alargue minimo (borde) => se acepta
PRINT '--- E-3.10.20 evento.gol_insertar: Valido: adicional_alargue minimo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 106, 'jugada', 'adicional_alargue', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.21 evento.gol_insertar: Valido: adicional_alargue maximo (borde) => se acepta
PRINT '--- E-3.10.21 evento.gol_insertar: Valido: adicional_alargue maximo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 135, 'jugada', 'adicional_alargue', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.22 evento.gol_insertar: Valido: tanda de penales minimo (borde) => se acepta
PRINT '--- E-3.10.22 evento.gol_insertar: Valido: tanda de penales minimo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 120, 'penal', 'penales', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.23 evento.gol_insertar: Valido: tanda de penales maximo (borde) => se acepta
PRINT '--- E-3.10.23 evento.gol_insertar: Valido: tanda de penales maximo (borde)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1');
EXEC evento.gol_insertar @fl, @t1, 135, 'penal', 'penales', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.24 evento.gol_insertar: Valido: gol del visitante con asistencia => se acepta
PRINT '--- E-3.10.24 evento.gol_insertar: Valido: gol del visitante con asistencia';
DECLARE @id INT,
        @fv INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_vis'),
        @v1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'vis_t1'),
        @v2 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'vis_t2');
EXEC evento.gol_insertar @fv, @v1, 30, 'jugada', 'PT', @v2, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.25 evento.gol_insertar: Valido: penal del visitante en la tanda => se acepta
PRINT '--- E-3.10.25 evento.gol_insertar: Valido: penal del visitante en la tanda';
DECLARE @id INT,
        @fv INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_vis'),
        @v1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'vis_t1');
EXEC evento.gol_insertar @fv, @v1, 125, 'penal', 'penales', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.26 evento.gol_insertar: Valido: autor suplente que ingreso por sustitucion => se acepta
PRINT '--- E-3.10.26 evento.gol_insertar: Valido: autor suplente que ingreso por sustitucion';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @si INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_s_in');
EXEC evento.gol_insertar @fl, @si, 75, 'jugada', 'ST', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.27 evento.gol_insertar: Valido: asistente suplente que ingreso => se acepta
PRINT '--- E-3.10.27 evento.gol_insertar: Valido: asistente suplente que ingreso';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @si INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_s_in');
EXEC evento.gol_insertar @fl, @t1, 76, 'jugada', 'ST', @si, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.28 evento.gol_insertar: Valido: autor titular (que luego sale por sustitucion) => se acepta
PRINT '--- E-3.10.28 evento.gol_insertar: Valido: autor titular (que luego sale por sustitucion)';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t2 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t2'),
        @t5 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t5');
EXEC evento.gol_insertar @fl, @t5, 12, 'jugada', 'PT', @t2, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.29 evento.gol_insertar: Valido: asistente titular que sale por sustitucion => se acepta
PRINT '--- E-3.10.29 evento.gol_insertar: Valido: asistente titular que sale por sustitucion';
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_loc'),
        @t1 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t1'),
        @t5 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t5');
EXEC evento.gol_insertar @fl, @t1, 13, 'jugada', 'PT', @t5, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- E-3.10.30 evento.gol_insertar: Valido: partido de fase de grupos con periodo regular => se acepta
PRINT '--- E-3.10.30 evento.gol_insertar: Valido: partido de fase de grupos con periodo regular';
DECLARE @id INT,
        @fj INT = (SELECT formacion_id FROM prueba.test_gol WHERE clave = 'f_jug'),
        @jg INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'jug_gol'),
        @ja INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'jug_asis');
EXEC evento.gol_insertar @fj, @jg, 40, 'jugada', 'PT', @ja, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.gol');
-- SELECT * FROM evento.gol WHERE gol_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.10.31 a E-3.10.35 evento.gol_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.10.31 evento.gol_modificar: Valido: cambia minuto y tipo => se acepta
PRINT '--- E-3.10.31 evento.gol_modificar: Valido: cambia minuto y tipo';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @t2 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t2');
EXEC evento.gol_modificar @gm, 12, 'cabezazo', 'PT', @t2;
-- DECLARE @gm_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
-- SELECT * FROM evento.gol WHERE gol_id = @gm_r1;
GO

-- E-3.10.32 evento.gol_modificar: Valido: cambia el asistente => se acepta
PRINT '--- E-3.10.32 evento.gol_modificar: Valido: cambia el asistente';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @t3 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t3');
EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @t3;
-- DECLARE @gm_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
-- SELECT * FROM evento.gol WHERE gol_id = @gm_r1;
GO

-- E-3.10.33 evento.gol_modificar: Valido: asistente suplente que ingreso por sustitucion => se acepta
PRINT '--- E-3.10.33 evento.gol_modificar: Valido: asistente suplente que ingreso por sustitucion';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @si INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_s_in');
EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @si;
-- DECLARE @gm_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
-- SELECT * FROM evento.gol WHERE gol_id = @gm_r1;
GO

-- E-3.10.34 evento.gol_modificar: Valido: asistente titular que sale por sustitucion => se acepta
PRINT '--- E-3.10.34 evento.gol_modificar: Valido: asistente titular que sale por sustitucion';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod'),
        @t5 INT = (SELECT jugador_id FROM prueba.test_gol WHERE clave = 'loc_t5');
EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @t5;
-- DECLARE @gm_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
-- SELECT * FROM evento.gol WHERE gol_id = @gm_r1;
GO

-- E-3.10.35 evento.gol_modificar: Valido: quita la asistencia => se acepta
PRINT '--- E-3.10.35 evento.gol_modificar: Valido: quita la asistencia';
DECLARE @gm INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', NULL;
-- DECLARE @gm_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_mod');
-- SELECT * FROM evento.gol WHERE gol_id = @gm_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.10.36 a E-3.10.39 evento.gol_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.10.36 evento.gol_eliminar: Baja valida: gol con asistencia de un partido no finalizado (baja el marcador local) => se acepta
PRINT '--- E-3.10.36 evento.gol_eliminar: Baja valida: gol con asistencia de un partido no finalizado (baja el marcador local)';
DECLARE @ge1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_elim');
EXEC evento.gol_eliminar @ge1;
-- DECLARE @ge1_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_elim');
-- SELECT * FROM evento.gol WHERE gol_id = @ge1_r1;
GO

-- E-3.10.37 evento.gol_eliminar: Baja valida: gol sin asistencia (cabezazo) => se acepta
PRINT '--- E-3.10.37 evento.gol_eliminar: Baja valida: gol sin asistencia (cabezazo)';
DECLARE @ge2 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_elim2');
EXEC evento.gol_eliminar @ge2;
-- DECLARE @ge2_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_elim2');
-- SELECT * FROM evento.gol WHERE gol_id = @ge2_r1;
GO

-- E-3.10.38 evento.gol_eliminar: Baja valida: gol en contra (baja el marcador del rival) => se acepta
PRINT '--- E-3.10.38 evento.gol_eliminar: Baja valida: gol en contra (baja el marcador del rival)';
DECLARE @ge3 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_elim3');
EXEC evento.gol_eliminar @ge3;
-- DECLARE @ge3_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_elim3');
-- SELECT * FROM evento.gol WHERE gol_id = @ge3_r1;
GO

-- E-3.10.39 evento.gol_eliminar: Baja valida: gol de la tanda de penales (baja los penales del visitante) => se acepta
PRINT '--- E-3.10.39 evento.gol_eliminar: Baja valida: gol de la tanda de penales (baja los penales del visitante)';
DECLARE @ge4 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_elim4');
EXEC evento.gol_eliminar @ge4;
-- DECLARE @ge4_r1 INT = (SELECT gol_id FROM prueba.test_gol WHERE clave = 'g_elim4');
-- SELECT * FROM evento.gol WHERE gol_id = @ge4_r1;
GO

-- ============================================================
-- 3.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.11.01 a E-3.11.12 evento.tarjeta_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.01 evento.tarjeta_insertar: Valido: amarilla con motivo => se acepta
PRINT '--- E-3.11.01 evento.tarjeta_insertar: Valido: amarilla con motivo';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l1  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_1');
EXEC evento.tarjeta_insertar @pt, @l1, 15, 'PT', 'amarilla', 'Falta', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.02 evento.tarjeta_insertar: Valido: motivo se guarda recortado => se acepta
PRINT '--- E-3.11.02 evento.tarjeta_insertar: Valido: motivo se guarda recortado';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l2  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_2');
EXEC evento.tarjeta_insertar @pt, @l2, 16, 'PT', 'amarilla', '  Motivo con espacios  ', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.03 evento.tarjeta_insertar: Valido: motivo nulo => se acepta
PRINT '--- E-3.11.03 evento.tarjeta_insertar: Valido: motivo nulo';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l3  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_3');
EXEC evento.tarjeta_insertar @pt, @l3, 17, 'PT', 'amarilla', NULL, NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.04 evento.tarjeta_insertar: Valido: motivo vacio se guarda como NULL => se acepta
PRINT '--- E-3.11.04 evento.tarjeta_insertar: Valido: motivo vacio se guarda como NULL';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l4  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_4');
EXEC evento.tarjeta_insertar @pt, @l4, 18, 'PT', 'amarilla', '', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.05 evento.tarjeta_insertar: Valido: motivo solo espacios se guarda como NULL => se acepta
PRINT '--- E-3.11.05 evento.tarjeta_insertar: Valido: motivo solo espacios se guarda como NULL';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l5  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_5');
EXEC evento.tarjeta_insertar @pt, @l5, 19, 'PT', 'amarilla', '   ', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.06 evento.tarjeta_insertar: Valido: sin pasar motivo ni tipo de expulsion (valores por defecto) => se acepta
PRINT '--- E-3.11.06 evento.tarjeta_insertar: Valido: sin pasar motivo ni tipo de expulsion (valores por defecto)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l6  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_6');
EXEC evento.tarjeta_insertar @pt, @l6, 20, 'PT', 'amarilla', @tarjeta_id = @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.07 evento.tarjeta_insertar: Valido: roja directa con motivo => se acepta
PRINT '--- E-3.11.07 evento.tarjeta_insertar: Valido: roja directa con motivo';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l7  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_7');
EXEC evento.tarjeta_insertar @pt, @l7, 50, 'ST', 'roja', 'Agresion', 'roja_directa', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.08 evento.tarjeta_insertar: Valido: roja directa sin motivo => se acepta
PRINT '--- E-3.11.08 evento.tarjeta_insertar: Valido: roja directa sin motivo';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l8  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_8');
EXEC evento.tarjeta_insertar @pt, @l8, 51, 'ST', 'roja', NULL, 'roja_directa', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.09 evento.tarjeta_insertar: Valido: segunda amarilla registrada como roja (la persona tiene una amarilla previa) => se acepta
PRINT '--- E-3.11.09 evento.tarjeta_insertar: Valido: segunda amarilla registrada como roja (la persona tiene una amarilla previa)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @a1  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_a1');
EXEC evento.tarjeta_insertar @pt, @a1, 70, 'ST', 'roja', 'Segunda amarilla', 'doble_amarilla', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.10 evento.tarjeta_insertar: Valido: roja directa a quien ya tenia una amarilla => se acepta
PRINT '--- E-3.11.10 evento.tarjeta_insertar: Valido: roja directa a quien ya tenia una amarilla';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @a2  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'u_a2');
EXEC evento.tarjeta_insertar @pt, @a2, 71, 'ST', 'roja', 'Agresion', 'roja_directa', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.11 evento.tarjeta_insertar: Valido: PT minuto minimo (borde) => se acepta
PRINT '--- E-3.11.11 evento.tarjeta_insertar: Valido: PT minuto minimo (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l9  INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_9');
EXEC evento.tarjeta_insertar @pt, @l9, 1, 'PT', 'amarilla', NULL, NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- E-3.11.12 evento.tarjeta_insertar: Valido: PT minuto maximo (borde) => se acepta
PRINT '--- E-3.11.12 evento.tarjeta_insertar: Valido: PT minuto maximo (borde)';
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM prueba.test_tarjeta WHERE clave = 'pt_tar'),
        @l10 INT = (SELECT persona_id FROM prueba.test_tarjeta WHERE clave = 'l_10');
EXEC evento.tarjeta_insertar @pt, @l10, 45, 'PT', 'amarilla', NULL, NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.tarjeta');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.11.13 a E-3.11.16 evento.tarjeta_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.13 evento.tarjeta_modificar: Valido: cambia minuto y motivo => se acepta
PRINT '--- E-3.11.13 evento.tarjeta_modificar: Valido: cambia minuto y motivo';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
EXEC evento.tarjeta_modificar @tm, 12, 'PT', 'Falta tactica';
-- DECLARE @tm_r1 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @tm_r1;
GO

-- E-3.11.14 evento.tarjeta_modificar: Valido: sin cambios (deja la tarjeta como en la preparacion) => se acepta
PRINT '--- E-3.11.14 evento.tarjeta_modificar: Valido: sin cambios (deja la tarjeta como en la preparacion)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
EXEC evento.tarjeta_modificar @tm, 10, 'PT', 'Falta';
-- DECLARE @tm_r1 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @tm_r1;
GO

-- E-3.11.15 evento.tarjeta_modificar: Valido: cambia el periodo (restaurar con el caso anterior) => se acepta
PRINT '--- E-3.11.15 evento.tarjeta_modificar: Valido: cambia el periodo (restaurar con el caso anterior)';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
EXEC evento.tarjeta_modificar @tm, 50, 'ST', 'Falta';
-- DECLARE @tm_r1 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @tm_r1;
GO

-- E-3.11.16 evento.tarjeta_modificar: Valido: motivo se guarda recortado => se acepta
PRINT '--- E-3.11.16 evento.tarjeta_modificar: Valido: motivo se guarda recortado';
DECLARE @tm  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
EXEC evento.tarjeta_modificar @tm, 10, 'PT', '  Motivo  ';
-- DECLARE @tm_r1 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_mod');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @tm_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.11.17 a E-3.11.20 evento.tarjeta_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.17 evento.tarjeta_eliminar: Baja valida: amarilla de un partido no finalizado, sin suspensiones => se acepta
PRINT '--- E-3.11.17 evento.tarjeta_eliminar: Baja valida: amarilla de un partido no finalizado, sin suspensiones';
DECLARE @te  INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_elim');
EXEC evento.tarjeta_eliminar @te;
-- DECLARE @te_r1 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_elim');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @te_r1;
GO

-- E-3.11.18 evento.tarjeta_eliminar: Baja valida: roja directa sin suspensiones => se acepta
PRINT '--- E-3.11.18 evento.tarjeta_eliminar: Baja valida: roja directa sin suspensiones';
DECLARE @te2 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_elim2');
EXEC evento.tarjeta_eliminar @te2;
-- DECLARE @te2_r1 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_elim2');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @te2_r1;
GO

-- E-3.11.19 evento.tarjeta_eliminar: Baja valida: roja por doble amarilla => se acepta
PRINT '--- E-3.11.19 evento.tarjeta_eliminar: Baja valida: roja por doble amarilla';
DECLARE @tdr INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_dob_r');
EXEC evento.tarjeta_eliminar @tdr;
-- DECLARE @tdr_r1 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_dob_r');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @tdr_r1;
GO

-- E-3.11.20 evento.tarjeta_eliminar: Baja valida: la amarilla ya no tiene la roja por doble amarilla (ejecutar DESPUES de dar de baja la roja) => se acepta
PRINT '--- E-3.11.20 evento.tarjeta_eliminar: Baja valida: la amarilla ya no tiene la roja por doble amarilla (ejecutar DESPUES de dar de baja la roja)';
DECLARE @tda INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_dob_a');
EXEC evento.tarjeta_eliminar @tda;
-- DECLARE @tda_r1 INT = (SELECT tarjeta_id FROM prueba.test_tarjeta WHERE clave = 't_dob_a');
-- SELECT * FROM evento.tarjeta WHERE tarjeta_id = @tda_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.11.21 a E-3.11.26 evento.criterio_suspension_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.21 evento.criterio_suspension_insertar: Valido: criterio con fase y tipo de persona => se acepta
PRINT '--- E-3.11.21 evento.criterio_suspension_insertar: Valido: criterio con fase y tipo de persona';
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 92, 1, 'grupos', 'jugador', 1, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.criterio_suspension');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @id_r1;
GO

-- E-3.11.22 evento.criterio_suspension_insertar: Valido: fase grupos => se acepta
PRINT '--- E-3.11.22 evento.criterio_suspension_insertar: Valido: fase grupos';
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 95, 1, 'grupos', NULL, 1, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.criterio_suspension');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @id_r1;
GO

-- E-3.11.23 evento.criterio_suspension_insertar: Valido: fase dieciseisavos => se acepta
PRINT '--- E-3.11.23 evento.criterio_suspension_insertar: Valido: fase dieciseisavos';
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 95, 1, 'dieciseisavos', NULL, 1, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.criterio_suspension');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @id_r1;
GO

-- E-3.11.24 evento.criterio_suspension_insertar: Valido: fase semifinal => se acepta
PRINT '--- E-3.11.24 evento.criterio_suspension_insertar: Valido: fase semifinal';
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 95, 1, 'semifinal', NULL, 1, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.criterio_suspension');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @id_r1;
GO

-- E-3.11.25 evento.criterio_suspension_insertar: Valido: fase tercer_puesto => se acepta
PRINT '--- E-3.11.25 evento.criterio_suspension_insertar: Valido: fase tercer_puesto';
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 95, 1, 'tercer_puesto', NULL, 1, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.criterio_suspension');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @id_r1;
GO

-- E-3.11.26 evento.criterio_suspension_insertar: Valido: fase final => se acepta
PRINT '--- E-3.11.26 evento.criterio_suspension_insertar: Valido: fase final';
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 95, 1, 'final', NULL, 1, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.criterio_suspension');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.11.27 a E-3.11.30 evento.criterio_suspension_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.27 evento.criterio_suspension_modificar: Valido: cambia los partidos de suspension => se acepta
PRINT '--- E-3.11.27 evento.criterio_suspension_modificar: Valido: cambia los partidos de suspension';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
EXEC evento.criterio_suspension_modificar @cm, 90, 3, 'grupos', 'jugador', 1;
-- DECLARE @cm_r1 INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @cm_r1;
GO

-- E-3.11.28 evento.criterio_suspension_modificar: Valido: sin cambios (no choca consigo mismo; deja el criterio como en la preparacion) => se acepta
PRINT '--- E-3.11.28 evento.criterio_suspension_modificar: Valido: sin cambios (no choca consigo mismo; deja el criterio como en la preparacion)';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
EXEC evento.criterio_suspension_modificar @cm, 90, 1, 'grupos', 'jugador', 1;
-- DECLARE @cm_r1 INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @cm_r1;
GO

-- E-3.11.29 evento.criterio_suspension_modificar: Valido: cambia la cantidad de amarillas => se acepta
PRINT '--- E-3.11.29 evento.criterio_suspension_modificar: Valido: cambia la cantidad de amarillas';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'grupos', 'jugador', 1;
-- DECLARE @cm_r1 INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @cm_r1;
GO

-- E-3.11.30 evento.criterio_suspension_modificar: Valido: cambia la fase => se acepta
PRINT '--- E-3.11.30 evento.criterio_suspension_modificar: Valido: cambia la fase';
DECLARE @cm  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'octavos', 'jugador', 1;
-- DECLARE @cm_r1 INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'mod');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @cm_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.11.31 a E-3.11.32 evento.criterio_suspension_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.31 evento.criterio_suspension_eliminar: Baja valida: criterio activo sin suspensiones => se acepta
PRINT '--- E-3.11.31 evento.criterio_suspension_eliminar: Baja valida: criterio activo sin suspensiones';
DECLARE @ce  INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'elim');
EXEC evento.criterio_suspension_eliminar @ce;
-- DECLARE @ce_r1 INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'elim');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @ce_r1;
GO

-- E-3.11.32 evento.criterio_suspension_eliminar: Baja valida: criterio inactivo sin suspensiones => se acepta
PRINT '--- E-3.11.32 evento.criterio_suspension_eliminar: Baja valida: criterio inactivo sin suspensiones';
DECLARE @ce2 INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'elim2');
EXEC evento.criterio_suspension_eliminar @ce2;
-- DECLARE @ce2_r1 INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'elim2');
-- SELECT * FROM evento.criterio_suspension WHERE criterio_id = @ce2_r1;
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
-- E-3.11.33 a E-3.11.35 evento.suspension_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.33 evento.suspension_insertar: Valido: expulsion sin criterio, con partido afectado => se acepta
PRINT '--- E-3.11.33 evento.suspension_insertar: Valido: expulsion sin criterio, con partido afectado';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
EXEC evento.suspension_insertar @tr, 'Roja directa', NULL, @pa1, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.suspension');
-- SELECT * FROM evento.suspension WHERE suspension_id = @id_r1;
GO

-- E-3.11.34 evento.suspension_insertar: Valido: amarilla con criterio y partido a definir (NULL) => se acepta
PRINT '--- E-3.11.34 evento.suspension_insertar: Valido: amarilla con criterio y partido a definir (NULL)';
DECLARE @id INT,
        @ta INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_amar'),
        @cu INT = (SELECT criterio_id FROM prueba.test_criterio WHERE clave = 'usado');
EXEC evento.suspension_insertar @ta, 'Acumulacion de amarillas', @cu, NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.suspension');
-- SELECT * FROM evento.suspension WHERE suspension_id = @id_r1;
GO

-- E-3.11.35 evento.suspension_insertar: Valido: el motivo se guarda recortado => se acepta
PRINT '--- E-3.11.35 evento.suspension_insertar: Valido: el motivo se guarda recortado';
DECLARE @id INT,
        @tr INT = (SELECT id FROM prueba.test_suspension WHERE clave = 't_roja');
EXEC evento.suspension_insertar @tr, '  Motivo con espacios  ', NULL, NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('evento.suspension');
-- SELECT * FROM evento.suspension WHERE suspension_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.11.36 a E-3.11.38 evento.suspension_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.36 evento.suspension_modificar: Valido: cambia el motivo (el mismo partido no choca consigo misma) => se acepta
PRINT '--- E-3.11.36 evento.suspension_modificar: Valido: cambia el motivo (el mismo partido no choca consigo misma)';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
EXEC evento.suspension_modificar @sm, 'Roja directa: sancion de oficio', @pa1;
-- DECLARE @sm_r1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod');
-- SELECT * FROM evento.suspension WHERE suspension_id = @sm_r1;
GO

-- E-3.11.37 evento.suspension_modificar: Valido: partido afectado a definir (NULL) => se acepta
PRINT '--- E-3.11.37 evento.suspension_modificar: Valido: partido afectado a definir (NULL)';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod');
EXEC evento.suspension_modificar @sm, 'Roja directa', NULL;
-- DECLARE @sm_r1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod');
-- SELECT * FROM evento.suspension WHERE suspension_id = @sm_r1;
GO

-- E-3.11.38 evento.suspension_modificar: Restaurar: vuelve a pa1 (el motivo se guarda recortado) => se acepta
PRINT '--- E-3.11.38 evento.suspension_modificar: Restaurar: vuelve a pa1 (el motivo se guarda recortado)';
DECLARE @sm INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod'),
        @pa1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'pa1');
EXEC evento.suspension_modificar @sm, '  Roja directa  ', @pa1;
-- DECLARE @sm_r1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'mod');
-- SELECT * FROM evento.suspension WHERE suspension_id = @sm_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.11.39 evento.suspension_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).

-- E-3.11.39 evento.suspension_eliminar: Baja valida: el partido afectado no se jugo => se acepta
PRINT '--- E-3.11.39 evento.suspension_eliminar: Baja valida: el partido afectado no se jugo';
DECLARE @se INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'elim');
EXEC evento.suspension_eliminar @se;
-- DECLARE @se_r1 INT = (SELECT id FROM prueba.test_suspension WHERE clave = 'elim');
-- SELECT * FROM evento.suspension WHERE suspension_id = @se_r1;
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
-- E-3.12.01 a E-3.12.07 arbitraje.arbitro_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.01 arbitraje.arbitro_insertar: Valido => se acepta
PRINT '--- E-3.12.01 arbitraje.arbitro_insertar: Valido';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta', @pa, 'FIFA', '1985-01-01', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.arbitro');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @id_r1;
GO

-- E-3.12.02 arbitraje.arbitro_insertar: Valido: categoria confederacion y sin fecha de nacimiento => se acepta
PRINT '--- E-3.12.02 arbitraje.arbitro_insertar: Valido: categoria confederacion y sin fecha de nacimiento';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Confederacion', @pa, 'confederacion', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.arbitro');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @id_r1;
GO

-- E-3.12.03 arbitraje.arbitro_insertar: Valido: nombre y apellido se guardan recortados => se acepta
PRINT '--- E-3.12.03 arbitraje.arbitro_insertar: Valido: nombre y apellido se guardan recortados';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
EXEC arbitraje.arbitro_insertar '  Test Arb  ', '  Recortado  ', @pa, 'FIFA', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.arbitro');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @id_r1;
GO

-- E-3.12.04 arbitraje.arbitro_insertar: Valido: justo 18 anios (borde) => se acepta
PRINT '--- E-3.12.04 arbitraje.arbitro_insertar: Valido: justo 18 anios (borde)';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @f18 DATE = DATEADD(YEAR, -18, CAST(SYSDATETIME() AS DATE));
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Borde 18', @pa, 'FIFA', @f18, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.arbitro');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @id_r1;
GO

-- E-3.12.05 arbitraje.arbitro_insertar: Valido: justo 70 anios (borde) => se acepta
PRINT '--- E-3.12.05 arbitraje.arbitro_insertar: Valido: justo 70 anios (borde)';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @f70 DATE = DATEADD(YEAR, -70, CAST(SYSDATETIME() AS DATE));
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Borde 70', @pa, 'FIFA', @f70, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.arbitro');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @id_r1;
GO

-- E-3.12.06 arbitraje.arbitro_insertar: Valido: mismo nombre y apellido en otro pais => se acepta
PRINT '--- E-3.12.06 arbitraje.arbitro_insertar: Valido: mismo nombre y apellido en otro pais';
DECLARE @id INT,
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAB');
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Base', @pb, 'FIFA', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.arbitro');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @id_r1;
GO

-- E-3.12.07 arbitraje.arbitro_insertar: Valido: nombre de 100 caracteres (borde) => se acepta
PRINT '--- E-3.12.07 arbitraje.arbitro_insertar: Valido: nombre de 100 caracteres (borde)';
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @n100 VARCHAR(100) = 'Test Arb' + REPLICATE('N', 92);
EXEC arbitraje.arbitro_insertar @n100, 'Nombre Largo', @pa, 'FIFA', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.arbitro');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.08 a E-3.12.11 arbitraje.arbitro_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.08 arbitraje.arbitro_modificar: Valido: cambia apellido, pais, categoria y fecha => se acepta
PRINT '--- E-3.12.08 arbitraje.arbitro_modificar: Valido: cambia apellido, pais, categoria y fecha';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAB');
EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod Nuevo', @pb, 'FIFA', '1990-02-02';
-- DECLARE @m_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @m_r1;
GO

-- E-3.12.09 arbitraje.arbitro_modificar: Valido: pais con seleccion, sin designaciones en sus partidos => se acepta
PRINT '--- E-3.12.09 arbitraje.arbitro_modificar: Valido: pais con seleccion, sin designaciones en sus partidos';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAL');
EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pl, 'confederacion', '1980-01-01';
-- DECLARE @m_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @m_r1;
GO

-- E-3.12.10 arbitraje.arbitro_modificar: Valido: sin fecha de nacimiento => se acepta
PRINT '--- E-3.12.10 arbitraje.arbitro_modificar: Valido: sin fecha de nacimiento';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pa, 'confederacion', NULL;
-- DECLARE @m_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @m_r1;
GO

-- E-3.12.11 arbitraje.arbitro_modificar: Restaurar: deja Mod como estaba => se acepta
PRINT '--- E-3.12.11 arbitraje.arbitro_modificar: Restaurar: deja Mod como estaba';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA');
EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pa, 'confederacion', '1980-01-01';
-- DECLARE @m_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @m_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.12 arbitraje.arbitro_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.12 arbitraje.arbitro_eliminar: Baja valida: arbitro sin designaciones (se eliminan tambien sus idiomas) => se acepta
PRINT '--- E-3.12.12 arbitraje.arbitro_eliminar: Baja valida: arbitro sin designaciones (se eliminan tambien sus idiomas)';
DECLARE @e INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_elim');
EXEC arbitraje.arbitro_eliminar @e;
-- DECLARE @e_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_elim');
-- SELECT * FROM arbitraje.arbitro WHERE arbitro_id = @e_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.13 a E-3.12.15 arbitraje.arbitro_idioma_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.13 arbitraje.arbitro_idioma_insertar: Valido => se acepta
PRINT '--- E-3.12.13 arbitraje.arbitro_idioma_insertar: Valido';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
EXEC arbitraje.arbitro_idioma_insertar @l, 'aleman';
-- DECLARE @l_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
-- SELECT * FROM arbitraje.arbitro_idioma WHERE arbitro_id = @l_r1;
GO

-- E-3.12.14 arbitraje.arbitro_idioma_insertar: Valido: se guarda en minusculas => se acepta
PRINT '--- E-3.12.14 arbitraje.arbitro_idioma_insertar: Valido: se guarda en minusculas';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
EXEC arbitraje.arbitro_idioma_insertar @l, 'FRANCES';
-- DECLARE @l_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
-- SELECT * FROM arbitraje.arbitro_idioma WHERE arbitro_id = @l_r1;
GO

-- E-3.12.15 arbitraje.arbitro_idioma_insertar: Valido: idioma de 10 letras (borde) => se acepta
PRINT '--- E-3.12.15 arbitraje.arbitro_idioma_insertar: Valido: idioma de 10 letras (borde)';
DECLARE @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
EXEC arbitraje.arbitro_idioma_insertar @l, 'portuguesa';
-- DECLARE @l_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
-- SELECT * FROM arbitraje.arbitro_idioma WHERE arbitro_id = @l_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.16 a E-3.12.18 arbitraje.arbitro_idioma_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.16 arbitraje.arbitro_idioma_modificar: Valido: reemplaza ingles por frances => se acepta
PRINT '--- E-3.12.16 arbitraje.arbitro_idioma_modificar: Valido: reemplaza ingles por frances';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', 'frances';
-- DECLARE @b_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
-- SELECT * FROM arbitraje.arbitro_idioma WHERE arbitro_id = @b_r1;
GO

-- E-3.12.17 arbitraje.arbitro_idioma_modificar: Restaurar: vuelve a ingles => se acepta
PRINT '--- E-3.12.17 arbitraje.arbitro_idioma_modificar: Restaurar: vuelve a ingles';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
EXEC arbitraje.arbitro_idioma_modificar @b, 'frances', 'ingles';
-- DECLARE @b_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
-- SELECT * FROM arbitraje.arbitro_idioma WHERE arbitro_id = @b_r1;
GO

-- E-3.12.18 arbitraje.arbitro_idioma_modificar: Valido: el mismo idioma (no choca consigo mismo) => se acepta
PRINT '--- E-3.12.18 arbitraje.arbitro_idioma_modificar: Valido: el mismo idioma (no choca consigo mismo)';
DECLARE @b INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', 'INGLES';
-- DECLARE @b_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_base');
-- SELECT * FROM arbitraje.arbitro_idioma WHERE arbitro_id = @b_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.19 arbitraje.arbitro_idioma_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.19 arbitraje.arbitro_idioma_eliminar: Baja valida => se acepta
PRINT '--- E-3.12.19 arbitraje.arbitro_idioma_eliminar: Baja valida';
DECLARE @m INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
EXEC arbitraje.arbitro_idioma_eliminar @m, 'aleman';
-- DECLARE @m_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_mod');
-- SELECT * FROM arbitraje.arbitro_idioma WHERE arbitro_id = @m_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.20 a E-3.12.22 arbitraje.designacion_arbitral_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.20 arbitraje.designacion_arbitral_insertar: Valido => se acepta
PRINT '--- E-3.12.20 arbitraje.designacion_arbitral_insertar: Valido';
DECLARE @id INT,
        @pg INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'),
        @l INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre');
EXEC arbitraje.designacion_arbitral_insertar @pg, @l, 'asistente_2', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.designacion_arbitral');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @id_r1;
GO

-- E-3.12.21 arbitraje.designacion_arbitral_insertar: Valido: con ADVERTENCIA (pais del arbitro con seleccion en competencia, desde dieciseisavos) => se acepta
PRINT '--- E-3.12.21 arbitraje.designacion_arbitral_insertar: Valido: con ADVERTENCIA (pais del arbitro con seleccion en competencia, desde dieciseisavos)';
DECLARE @id INT,
        @adv VARCHAR(500),
        @pd INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pd'),
        @ad INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_adv');
EXEC arbitraje.designacion_arbitral_insertar @pd, @ad, 'principal', @id OUTPUT, @adv OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.designacion_arbitral');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @id_r1;
GO

-- E-3.12.22 arbitraje.designacion_arbitral_insertar: Valido: eliminacion directa sin advertencia (pais sin seleccion) => se acepta
PRINT '--- E-3.12.22 arbitraje.designacion_arbitral_insertar: Valido: eliminacion directa sin advertencia (pais sin seleccion)';
DECLARE @id INT,
        @pd INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pd'),
        @l2 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre2');
EXEC arbitraje.designacion_arbitral_insertar @pd, @l2, 'var', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.designacion_arbitral');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.23 a E-3.12.27 arbitraje.designacion_arbitral_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.23 arbitraje.designacion_arbitral_modificar: Valido: sin cambios (no choca consigo misma) => se acepta
PRINT '--- E-3.12.23 arbitraje.designacion_arbitral_modificar: Valido: sin cambios (no choca consigo misma)';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @adm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_dmod');
EXEC arbitraje.designacion_arbitral_modificar @dm, @adm, 'cuarto';
-- DECLARE @dm_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @dm_r1;
GO

-- E-3.12.24 arbitraje.designacion_arbitral_modificar: Valido: reemplaza al arbitro (la designacion no tiene informes) => se acepta
PRINT '--- E-3.12.24 arbitraje.designacion_arbitral_modificar: Valido: reemplaza al arbitro (la designacion no tiene informes)';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @l2 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_libre2');
EXEC arbitraje.designacion_arbitral_modificar @dm, @l2, 'cuarto';
-- DECLARE @dm_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @dm_r1;
GO

-- E-3.12.25 arbitraje.designacion_arbitral_modificar: Restaurar: vuelve el arbitro original => se acepta
PRINT '--- E-3.12.25 arbitraje.designacion_arbitral_modificar: Restaurar: vuelve el arbitro original';
DECLARE @dm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod'),
        @adm INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_dmod');
EXEC arbitraje.designacion_arbitral_modificar @dm, @adm, 'cuarto';
-- DECLARE @dm_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_mod');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @dm_r1;
GO

-- E-3.12.26 arbitraje.designacion_arbitral_modificar: Valido: cambia el rol => se acepta
PRINT '--- E-3.12.26 arbitraje.designacion_arbitral_modificar: Valido: cambia el rol';
DECLARE @dpc INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_pc'),
        @apc INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_pc');
EXEC arbitraje.designacion_arbitral_modificar @dpc, @apc, 'cuarto';
-- DECLARE @dpc_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_pc');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @dpc_r1;
GO

-- E-3.12.27 arbitraje.designacion_arbitral_modificar: Restaurar: vuelve el rol original => se acepta
PRINT '--- E-3.12.27 arbitraje.designacion_arbitral_modificar: Restaurar: vuelve el rol original';
DECLARE @dpc INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_pc'),
        @apc INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'a_pc');
EXEC arbitraje.designacion_arbitral_modificar @dpc, @apc, 'principal';
-- DECLARE @dpc_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_pc');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @dpc_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.28 arbitraje.designacion_arbitral_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.28 arbitraje.designacion_arbitral_eliminar: Baja valida: sin informes y con el partido sin jugar => se acepta
PRINT '--- E-3.12.28 arbitraje.designacion_arbitral_eliminar: Baja valida: sin informes y con el partido sin jugar';
DECLARE @de INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_elim');
EXEC arbitraje.designacion_arbitral_eliminar @de;
-- DECLARE @de_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_elim');
-- SELECT * FROM arbitraje.designacion_arbitral WHERE designacion_id = @de_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.29 a E-3.12.31 arbitraje.informe_arbitral_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.29 arbitraje.informe_arbitral_insertar: Valido: con sancion => se acepta
PRINT '--- E-3.12.29 arbitraje.informe_arbitral_insertar: Valido: con sancion';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base');
EXEC arbitraje.informe_arbitral_insertar @db, '2031-01-10 20:00:00 +00:00', 'Partido sin incidentes', 'Apercibimiento', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.informe_arbitral');
-- SELECT * FROM arbitraje.informe_arbitral WHERE informe_id = @id_r1;
GO

-- E-3.12.30 arbitraje.informe_arbitral_insertar: Valido: sin sancion => se acepta
PRINT '--- E-3.12.30 arbitraje.informe_arbitral_insertar: Valido: sin sancion';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base');
EXEC arbitraje.informe_arbitral_insertar @db, '2031-01-10 20:30:00 +00:00', 'Segundo informe', NULL, @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.informe_arbitral');
-- SELECT * FROM arbitraje.informe_arbitral WHERE informe_id = @id_r1;
GO

-- E-3.12.31 arbitraje.informe_arbitral_insertar: Valido: fecha igual al inicio del partido (borde); la sancion vacia se guarda NULL => se acepta
PRINT '--- E-3.12.31 arbitraje.informe_arbitral_insertar: Valido: fecha igual al inicio del partido (borde); la sancion vacia se guarda NULL';
DECLARE @id INT,
        @db INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'd_base'),
        @ini DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'));
EXEC arbitraje.informe_arbitral_insertar @db, @ini, 'Informe al inicio del partido', '', @id OUTPUT;
-- DECLARE @id_r1 INT = IDENT_CURRENT('arbitraje.informe_arbitral');
-- SELECT * FROM arbitraje.informe_arbitral WHERE informe_id = @id_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.32 a E-3.12.34 arbitraje.informe_arbitral_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.32 arbitraje.informe_arbitral_modificar: Valido: cambia fecha, contenido y sancion => se acepta
PRINT '--- E-3.12.32 arbitraje.informe_arbitral_modificar: Valido: cambia fecha, contenido y sancion';
DECLARE @ib INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base');
EXEC arbitraje.informe_arbitral_modificar @ib, '2031-01-10 22:00:00 +00:00', 'Informe corregido', 'Multa';
-- DECLARE @ib_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base');
-- SELECT * FROM arbitraje.informe_arbitral WHERE informe_id = @ib_r1;
GO

-- E-3.12.33 arbitraje.informe_arbitral_modificar: Valido: fecha igual al inicio (borde); la sancion en blanco se guarda NULL => se acepta
PRINT '--- E-3.12.33 arbitraje.informe_arbitral_modificar: Valido: fecha igual al inicio (borde); la sancion en blanco se guarda NULL';
DECLARE @ib INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base'),
        @ini DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'pg'));
EXEC arbitraje.informe_arbitral_modificar @ib, @ini, 'Informe base', '   ';
-- DECLARE @ib_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base');
-- SELECT * FROM arbitraje.informe_arbitral WHERE informe_id = @ib_r1;
GO

-- E-3.12.34 arbitraje.informe_arbitral_modificar: Restaurar: deja el informe como estaba => se acepta
PRINT '--- E-3.12.34 arbitraje.informe_arbitral_modificar: Restaurar: deja el informe como estaba';
DECLARE @ib INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base');
EXEC arbitraje.informe_arbitral_modificar @ib, '2031-01-10 20:00:00 +00:00', 'Informe base', NULL;
-- DECLARE @ib_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_base');
-- SELECT * FROM arbitraje.informe_arbitral WHERE informe_id = @ib_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.12.35 arbitraje.informe_arbitral_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.12.35 arbitraje.informe_arbitral_eliminar: Baja valida => se acepta
PRINT '--- E-3.12.35 arbitraje.informe_arbitral_eliminar: Baja valida';
DECLARE @ie INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_elim');
EXEC arbitraje.informe_arbitral_eliminar @ie;
-- DECLARE @ie_r1 INT = (SELECT id FROM prueba.test_arbitraje WHERE clave = 'i_elim');
-- SELECT * FROM arbitraje.informe_arbitral WHERE informe_id = @ie_r1;
GO

-- ============================================================
-- 3.13 publicidad: anunciante, campania, campania_pais_interes, pieza_publicitaria y espacio_publicitario
-- ============================================================

-- -------------------------------------------------------------------------------------
-- E-3.13.01 a E-3.13.02 publicidad.anunciante_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.01 publicidad.anunciante_insertar: Valido => se acepta
PRINT '--- E-3.13.01 publicidad.anunciante_insertar: Valido';
DECLARE @anun INT;
EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventas@gmail.com', @anun OUTPUT;
-- DECLARE @anun_r1 INT = IDENT_CURRENT('publicidad.anunciante');
-- SELECT * FROM publicidad.anunciante WHERE anunciante_id = @anun_r1;
GO

-- E-3.13.02 publicidad.anunciante_insertar: Valido: sin contacto (es opcional) => se acepta
PRINT '--- E-3.13.02 publicidad.anunciante_insertar: Valido: sin contacto (es opcional)';
DECLARE @anun INT;
EXEC publicidad.anunciante_insertar 'TEST06', 'Empresa S.A.', NULL, @anun OUTPUT;
-- DECLARE @anun_r1 INT = IDENT_CURRENT('publicidad.anunciante');
-- SELECT * FROM publicidad.anunciante WHERE anunciante_id = @anun_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.13.03 a E-3.13.04 publicidad.anunciante_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.03 publicidad.anunciante_modificar: Modificacion valida => se acepta
PRINT '--- E-3.13.03 publicidad.anunciante_modificar: Modificacion valida';
EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas@gmail.com';
-- SELECT * FROM publicidad.anunciante WHERE anunciante_id = 1;
GO

-- E-3.13.04 publicidad.anunciante_modificar: Valido: sin contacto (es opcional) => se acepta
PRINT '--- E-3.13.04 publicidad.anunciante_modificar: Valido: sin contacto (es opcional)';
EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', NULL;
-- SELECT * FROM publicidad.anunciante WHERE anunciante_id = 1;
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
-- E-3.13.05 publicidad.anunciante_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.19 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.05 publicidad.anunciante_eliminar: Baja valida (SI LE DAS DOS VECES TE DICE ID inexistente *ya se elimino*) => se acepta
PRINT '--- E-3.13.05 publicidad.anunciante_eliminar: Baja valida (SI LE DAS DOS VECES TE DICE ID inexistente *ya se elimino*)';
DECLARE @elim_ok INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'ELIM_OK');
EXEC publicidad.anunciante_eliminar @elim_ok;
-- DECLARE @elim_ok_r1 INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'ELIM_OK');
-- SELECT * FROM publicidad.anunciante WHERE anunciante_id = @elim_ok_r1;
GO

PRINT '--- P-3.20 Preparación de publicidad.campania_insertar (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
EXEC publicidad.anunciante_insertar 'CAMP_A', NULL, NULL;
EXEC publicidad.anunciante_insertar 'CAMP_B', NULL, NULL;
GO

-- -------------------------------------------------------------------------------------
-- E-3.13.06 a E-3.13.09 publicidad.campania_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.20 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.06 publicidad.campania_insertar: Valido => se acepta
PRINT '--- E-3.13.06 publicidad.campania_insertar: Valido';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19', @camp OUTPUT;
-- DECLARE @camp_r1 INT = IDENT_CURRENT('publicidad.campania');
-- SELECT * FROM publicidad.campania WHERE campania_id = @camp_r1;
GO

-- E-3.13.07 publicidad.campania_insertar: Valido: fecha fin = fecha inicio => se acepta
PRINT '--- E-3.13.07 publicidad.campania_insertar: Valido: fecha fin = fecha inicio';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
EXEC publicidad.campania_insertar @a, 'Camp Un Dia', '2026-06-10', '2026-06-10', @camp OUTPUT;
-- DECLARE @camp_r1 INT = IDENT_CURRENT('publicidad.campania');
-- SELECT * FROM publicidad.campania WHERE campania_id = @camp_r1;
GO

-- E-3.13.08 publicidad.campania_insertar: Valido: mismo nombre en otro anunciante => se acepta
PRINT '--- E-3.13.08 publicidad.campania_insertar: Valido: mismo nombre en otro anunciante';
DECLARE @b INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_B'),
        @camp INT;
EXEC publicidad.campania_insertar @b, 'Camp Test', '2026-06-01', '2026-07-19', @camp OUTPUT;
-- DECLARE @camp_r1 INT = IDENT_CURRENT('publicidad.campania');
-- SELECT * FROM publicidad.campania WHERE campania_id = @camp_r1;
GO

-- E-3.13.09 publicidad.campania_insertar: Valido: se guarda sin espacios => se acepta
PRINT '--- E-3.13.09 publicidad.campania_insertar: Valido: se guarda sin espacios';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @camp INT;
EXEC publicidad.campania_insertar @a, '  Camp Espacios  ', '2026-06-01', '2026-06-30', @camp OUTPUT;
-- DECLARE @camp_r1 INT = IDENT_CURRENT('publicidad.campania');
-- SELECT * FROM publicidad.campania WHERE campania_id = @camp_r1;
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
-- E-3.13.10 a E-3.13.13 publicidad.campania_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.21 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.10 publicidad.campania_modificar: Valido: cambia fechas, mismo nombre propio (no es duplicado) => se acepta
PRINT '--- E-3.13.10 publicidad.campania_modificar: Valido: cambia fechas, mismo nombre propio (no es duplicado)';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', '2026-06-05', '2026-07-10';
-- DECLARE @c1_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
-- SELECT * FROM publicidad.campania WHERE campania_id = @c1_r1;
GO

-- E-3.13.11 publicidad.campania_modificar: Valido: cambia de anunciante (despues volver a @a) => se acepta
PRINT '--- E-3.13.11 publicidad.campania_modificar: Valido: cambia de anunciante (despues volver a @a)';
DECLARE @b INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_B'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
EXEC publicidad.campania_modificar @c1, @b, 'Camp Mod', '2026-06-05', '2026-07-10';
-- DECLARE @c1_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
-- SELECT * FROM publicidad.campania WHERE campania_id = @c1_r1;
GO

-- E-3.13.12 publicidad.campania_modificar: Valido: nombre con espacios (se guarda recortado) y fin = inicio => se acepta
PRINT '--- E-3.13.12 publicidad.campania_modificar: Valido: nombre con espacios (se guarda recortado) y fin = inicio';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
EXEC publicidad.campania_modificar @c1, @a, '  Camp Mod  ', '2026-06-10', '2026-06-10';
-- DECLARE @c1_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod');
-- SELECT * FROM publicidad.campania WHERE campania_id = @c1_r1;
GO

-- E-3.13.13 publicidad.campania_modificar: Valido: amplia la vigencia, el partido sigue cubierto => se acepta
PRINT '--- E-3.13.13 publicidad.campania_modificar: Valido: amplia la vigencia, el partido sigue cubierto';
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @c3 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'),
        @f DATE = (SELECT TOP 1 CAST(p.fecha_hora_utc AS DATE) FROM publicidad.espacio_publicitario e JOIN torneo.partido p ON p.partido_id = e.partido_id
                   JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
                   WHERE pz.campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'));
DECLARE @f_m10 DATE = DATEADD(DAY, -10, @f),
        @f_p10 DATE = DATEADD(DAY, 10, @f);
EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_m10, @f_p10;
-- DECLARE @c3_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio');
-- SELECT * FROM publicidad.campania WHERE campania_id = @c3_r1;
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
-- E-3.13.14 publicidad.campania_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.22 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.14 publicidad.campania_eliminar: Baja valida: elimina la campaña y sus paises de interes, si se ejecuta dos veces seguidas tira error de inexistente => se acepta
PRINT '--- E-3.13.14 publicidad.campania_eliminar: Baja valida: elimina la campaña y sus paises de interes, si se ejecuta dos veces seguidas tira error de inexistente';
DECLARE @ok INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim OK');
EXEC publicidad.campania_eliminar @ok;
-- DECLARE @ok_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim OK');
-- SELECT * FROM publicidad.campania WHERE campania_id = @ok_r1;
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
-- E-3.13.15 a E-3.13.16 publicidad.campania_pais_interes_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.15 publicidad.campania_pais_interes_insertar: Valido => se acepta
PRINT '--- E-3.13.15 publicidad.campania_pais_interes_insertar: Valido';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_INS'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.campania_pais_interes_insertar @ci, @p2;
-- DECLARE @ci_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_INS');
-- SELECT * FROM publicidad.campania_pais_interes WHERE campania_id = @ci_r1;
GO

-- E-3.13.16 publicidad.campania_pais_interes_insertar: Valido: el mismo pais en otra campaña => se acepta
PRINT '--- E-3.13.16 publicidad.campania_pais_interes_insertar: Valido: el mismo pais en otra campaña';
DECLARE @co INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_OTRA'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.campania_pais_interes_insertar @co, @p1;
-- DECLARE @co_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_OTRA');
-- SELECT * FROM publicidad.campania_pais_interes WHERE campania_id = @co_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.13.17 a E-3.13.19 publicidad.campania_pais_interes_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.17 publicidad.campania_pais_interes_modificar: Valido: reemplaza p2 por p4 => se acepta
PRINT '--- E-3.13.17 publicidad.campania_pais_interes_modificar: Valido: reemplaza p2 por p4';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.campania_pais_interes_modificar @cm, @p2, @p4;
-- DECLARE @cm_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD');
-- SELECT * FROM publicidad.campania_pais_interes WHERE campania_id = @cm_r1;
GO

-- E-3.13.18 publicidad.campania_pais_interes_modificar: Restaurar: volver p4 a p2 => se acepta
PRINT '--- E-3.13.18 publicidad.campania_pais_interes_modificar: Restaurar: volver p4 a p2';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.campania_pais_interes_modificar @cm, @p4, @p2;
-- DECLARE @cm_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD');
-- SELECT * FROM publicidad.campania_pais_interes WHERE campania_id = @cm_r1;
GO

-- E-3.13.19 publicidad.campania_pais_interes_modificar: Valido: mismo pais => se acepta
PRINT '--- E-3.13.19 publicidad.campania_pais_interes_modificar: Valido: mismo pais';
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.campania_pais_interes_modificar @cm, @p3, @p3;
-- DECLARE @cm_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD');
-- SELECT * FROM publicidad.campania_pais_interes WHERE campania_id = @cm_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.13.20 publicidad.campania_pais_interes_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.20 publicidad.campania_pais_interes_eliminar: Baja valida (si se ejecuta 2 veces tira error) => se acepta
PRINT '--- E-3.13.20 publicidad.campania_pais_interes_eliminar: Baja valida (si se ejecuta 2 veces tira error)';
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_ELIM'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.campania_pais_interes_eliminar @ce, @p2;
-- DECLARE @ce_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_ELIM');
-- SELECT * FROM publicidad.campania_pais_interes WHERE campania_id = @ce_r1;
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
-- E-3.13.21 a E-3.13.26 publicidad.pieza_publicitaria_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.21 publicidad.pieza_publicitaria_insertar: Valido => se acepta
PRINT '--- E-3.13.21 publicidad.pieza_publicitaria_insertar: Valido';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p1, 500, @pz OUTPUT;
-- DECLARE @pz_r1 INT = IDENT_CURRENT('publicidad.pieza_publicitaria');
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @pz_r1;
GO

-- E-3.13.22 publicidad.pieza_publicitaria_insertar: Valido: mismo idioma, otro mercado => se acepta
PRINT '--- E-3.13.22 publicidad.pieza_publicitaria_insertar: Valido: mismo idioma, otro mercado';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
EXEC publicidad.pieza_publicitaria_insertar @ci, 'espanol', @p2, 800, @pz OUTPUT;
-- DECLARE @pz_r1 INT = IDENT_CURRENT('publicidad.pieza_publicitaria');
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @pz_r1;
GO

-- E-3.13.23 publicidad.pieza_publicitaria_insertar: Valido: tarifa 0 => se acepta
PRINT '--- E-3.13.23 publicidad.pieza_publicitaria_insertar: Valido: tarifa 0';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
EXEC publicidad.pieza_publicitaria_insertar @ci, 'frances', @p1, 0, @pz OUTPUT;
-- DECLARE @pz_r1 INT = IDENT_CURRENT('publicidad.pieza_publicitaria');
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @pz_r1;
GO

-- E-3.13.24 publicidad.pieza_publicitaria_insertar: Valido: se guarda en minusculas => se acepta
PRINT '--- E-3.13.24 publicidad.pieza_publicitaria_insertar: Valido: se guarda en minusculas';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
EXEC publicidad.pieza_publicitaria_insertar @ci, 'ALEMAN', @p1, 700, @pz OUTPUT;
-- DECLARE @pz_r1 INT = IDENT_CURRENT('publicidad.pieza_publicitaria');
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @pz_r1;
GO

-- E-3.13.25 publicidad.pieza_publicitaria_insertar: Valido: idioma de 10 letras => se acepta
PRINT '--- E-3.13.25 publicidad.pieza_publicitaria_insertar: Valido: idioma de 10 letras';
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
EXEC publicidad.pieza_publicitaria_insertar @ci, 'abcdefghij', @p2, 100, @pz OUTPUT;
-- DECLARE @pz_r1 INT = IDENT_CURRENT('publicidad.pieza_publicitaria');
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @pz_r1;
GO

-- E-3.13.26 publicidad.pieza_publicitaria_insertar: Valido: mismo idioma y mercado que la base, en otra campaña => se acepta
PRINT '--- E-3.13.26 publicidad.pieza_publicitaria_insertar: Valido: mismo idioma y mercado que la base, en otra campaña';
DECLARE @co INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_OTRA'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;
EXEC publicidad.pieza_publicitaria_insertar @co, 'espanol', @p1, 1000, @pz OUTPUT;
-- DECLARE @pz_r1 INT = IDENT_CURRENT('publicidad.pieza_publicitaria');
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @pz_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.13.27 a E-3.13.33 publicidad.pieza_publicitaria_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.27 publicidad.pieza_publicitaria_modificar: Valido: cambia la tarifa (no es duplicado de si misma) => se acepta
PRINT '--- E-3.13.27 publicidad.pieza_publicitaria_modificar: Valido: cambia la tarifa (no es duplicado de si misma)';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, 1500;
-- DECLARE @m1_r1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @m1_r1;
GO

-- E-3.13.28 publicidad.pieza_publicitaria_modificar: Valido: idioma en mayusculas, se guarda en minusculas => se acepta
PRINT '--- E-3.13.28 publicidad.pieza_publicitaria_modificar: Valido: idioma en mayusculas, se guarda en minusculas';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'INGLES', @p1, 1000;
-- DECLARE @m1_r1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @m1_r1;
GO

-- E-3.13.29 publicidad.pieza_publicitaria_modificar: Valido: cambia el idioma => se acepta
PRINT '--- E-3.13.29 publicidad.pieza_publicitaria_modificar: Valido: cambia el idioma';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'italiano', @p1, 1000;
-- DECLARE @m1_r1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @m1_r1;
GO

-- E-3.13.30 publicidad.pieza_publicitaria_modificar: Valido: cambia el mercado, sin espacios asignados => se acepta
PRINT '--- E-3.13.30 publicidad.pieza_publicitaria_modificar: Valido: cambia el mercado, sin espacios asignados';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p2, 1000;
-- DECLARE @m1_r1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @m1_r1;
GO

-- E-3.13.31 publicidad.pieza_publicitaria_modificar: Valido: cambia de campaña, sin espacios asignados => se acepta
PRINT '--- E-3.13.31 publicidad.pieza_publicitaria_modificar: Valido: cambia de campaña, sin espacios asignados';
DECLARE @cd INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_DEST'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.pieza_publicitaria_modificar @m1, @cd, 'ingles', @p1, 1000;
-- DECLARE @m1_r1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @m1_r1;
GO

-- E-3.13.32 publicidad.pieza_publicitaria_modificar: Valido: pieza con espacio, solo cambia la tarifa => se acepta
PRINT '--- E-3.13.32 publicidad.pieza_publicitaria_modificar: Valido: pieza con espacio, solo cambia la tarifa';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
        @m3 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.pieza_publicitaria_modificar @m3, @c1, 'aleman', @p3, 3500;
-- DECLARE @m3_r1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @m3_r1;
GO

-- E-3.13.33 publicidad.pieza_publicitaria_modificar: Restaurar: deja m1 como estaba => se acepta
PRINT '--- E-3.13.33 publicidad.pieza_publicitaria_modificar: Restaurar: deja m1 como estaba';
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, 1000;
-- DECLARE @m1_r1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY);
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @m1_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.13.34 publicidad.pieza_publicitaria_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.34 publicidad.pieza_publicitaria_eliminar: Baja valida (si se ejecuta 2 veces seguidas tira error) => se acepta
PRINT '--- E-3.13.34 publicidad.pieza_publicitaria_eliminar: Baja valida (si se ejecuta 2 veces seguidas tira error)';
DECLARE @e1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM') AND idioma = 'espanol');
EXEC publicidad.pieza_publicitaria_eliminar @e1;
-- DECLARE @e1_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM') AND idioma = 'espanol');
-- SELECT * FROM publicidad.pieza_publicitaria WHERE pieza_id = @e1_r1;
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
-- E-3.13.35 a E-3.13.37 publicidad.espacio_publicitario_insertar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.35 publicidad.espacio_publicitario_insertar: Valido: con pieza y prioridad 1 => se acepta
PRINT '--- E-3.13.35 publicidad.espacio_publicitario_insertar: Valido: con pieza y prioridad 1';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z6 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'italiano'),
        @z7 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'portugues');
DECLARE @pb INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z6 AND numero_espacio = 4),
        @esp INT;
EXEC publicidad.espacio_publicitario_insertar @pb, 1, @z7, 1, @esp OUTPUT;
-- DECLARE @esp_r1 INT = IDENT_CURRENT('publicidad.espacio_publicitario');
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @esp_r1;
GO

-- E-3.13.36 publicidad.espacio_publicitario_insertar: Valido: pieza que ya esta en otro partido (PA), prioridad 4 (borde) => se acepta
PRINT '--- E-3.13.36 publicidad.espacio_publicitario_insertar: Valido: pieza que ya esta en otro partido (PA), prioridad 4 (borde)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol'),
        @z6 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'italiano');
DECLARE @pb INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z6 AND numero_espacio = 4),
        @esp INT;
EXEC publicidad.espacio_publicitario_insertar @pb, 2, @z1, 4, @esp OUTPUT;
-- DECLARE @esp_r1 INT = IDENT_CURRENT('publicidad.espacio_publicitario');
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @esp_r1;
GO

-- E-3.13.37 publicidad.espacio_publicitario_insertar: Valido: espacio vacio (sin pieza ni prioridad) => se acepta
PRINT '--- E-3.13.37 publicidad.espacio_publicitario_insertar: Valido: espacio vacio (sin pieza ni prioridad)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z6 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'italiano');
DECLARE @pb INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z6 AND numero_espacio = 4),
        @esp INT;
EXEC publicidad.espacio_publicitario_insertar @pb, 3, NULL, NULL, @esp OUTPUT;
-- DECLARE @esp_r1 INT = IDENT_CURRENT('publicidad.espacio_publicitario');
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @esp_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.13.38 a E-3.13.45 publicidad.espacio_publicitario_modificar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.38 publicidad.espacio_publicitario_modificar: Valido: cambia la prioridad y conserva la pieza => se acepta
PRINT '--- E-3.13.38 publicidad.espacio_publicitario_modificar: Valido: cambia la prioridad y conserva la pieza';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 3;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @m1_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 1);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @m1_r1;
GO

-- E-3.13.39 publicidad.espacio_publicitario_modificar: Valido: cambia la pieza (despues restaurar) => se acepta
PRINT '--- E-3.13.39 publicidad.espacio_publicitario_modificar: Valido: cambia la pieza (despues restaurar)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances'),
        @z7 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'portugues');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
EXEC publicidad.espacio_publicitario_modificar @m1, @z7, 1;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @m1_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 1);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @m1_r1;
GO

-- E-3.13.40 publicidad.espacio_publicitario_modificar: Valido: deja el espacio vacio (despues restaurar) => se acepta
PRINT '--- E-3.13.40 publicidad.espacio_publicitario_modificar: Valido: deja el espacio vacio (despues restaurar)';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
EXEC publicidad.espacio_publicitario_modificar @m1, NULL, NULL;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @m1_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 1);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @m1_r1;
GO

-- E-3.13.41 publicidad.espacio_publicitario_modificar: Valido: informa fecha de exhibicion sin facturar => se acepta
PRINT '--- E-3.13.41 publicidad.espacio_publicitario_modificar: Valido: informa fecha de exhibicion sin facturar';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 2, @fx;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @m1_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 1);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @m1_r1;
GO

-- E-3.13.42 publicidad.espacio_publicitario_modificar: Valido: facturado NULL se toma como 0 => se acepta
PRINT '--- E-3.13.42 publicidad.espacio_publicitario_modificar: Valido: facturado NULL se toma como 0';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, NULL;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @m1_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 1);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @m1_r1;
GO

-- E-3.13.43 publicidad.espacio_publicitario_modificar: Valido: espacio ya facturado, misma pieza, cambia el monto => se acepta
PRINT '--- E-3.13.43 publicidad.espacio_publicitario_modificar: Valido: espacio ya facturado, misma pieza, cambia el monto';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @ef INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 2),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
EXEC publicidad.espacio_publicitario_modificar @ef, @z3, NULL, @fx, 1, 20000;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @ef_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 2);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @ef_r1;
GO

-- E-3.13.44 publicidad.espacio_publicitario_modificar: Restaurar: deja m1 como estaba => se acepta
PRINT '--- E-3.13.44 publicidad.espacio_publicitario_modificar: Restaurar: deja m1 como estaba';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1);
EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, 0, NULL;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @m1_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 1);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @m1_r1;
GO

-- E-3.13.45 publicidad.espacio_publicitario_modificar: Valido: marca facturado. => se acepta
PRINT '--- E-3.13.45 publicidad.espacio_publicitario_modificar: Valido: marca facturado.';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances'),
        @z4 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'aleman');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @mf INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 3),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);
EXEC publicidad.espacio_publicitario_modificar @mf, @z4, 1, @fx, 1, 5000;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @mf_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 3);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @mf_r1;
GO

-- -------------------------------------------------------------------------------------
-- E-3.13.46 publicidad.espacio_publicitario_eliminar
-- -------------------------------------------------------------------------------------
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).

-- E-3.13.46 publicidad.espacio_publicitario_eliminar: Baja valida (espacio no facturado) SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR => se acepta
PRINT '--- E-3.13.46 publicidad.espacio_publicitario_eliminar: Baja valida (espacio no facturado) SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR';
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @e1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 4);
EXEC publicidad.espacio_publicitario_eliminar @e1;
-- DECLARE @vig_r1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
-- DECLARE @z3_r1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig_r1 AND idioma = 'frances');
-- DECLARE @pc_r1 INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3_r1);
-- DECLARE @e1_r1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc_r1 AND numero_espacio = 4);
-- SELECT * FROM publicidad.espacio_publicitario WHERE espacio_id = @e1_r1;
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
