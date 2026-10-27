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
--   Pruebas de lo que los SP de entrega5_sp_ABM.sql y entrega5_sp_logica_negocio.sql deben ACEPTAR,
--   con evidencia (consulta del resultado + verificación OK/FALLO). Las validaciones que deben
--   rechazarse están en entrega5_test_fallidos.sql.
--     PARTE 1: SP de ABM sobre un escenario encadenado (Argentina, Francia, México y Japón; partidos P1 a P4).
--     PARTE 2: SP de lógica de negocio sobre el mismo escenario, incluidos los casos obligatorios de la sección IV.
--     PARTE 3: casos detallados por SP (bordes y variantes válidas), con sus propios datos de prueba.
--
-- IDENTIFICACIÓN DE LOS LOTES:
--   Cada lote empieza con PRINT '--- <id> <descripción>', seguido de "-- Resultado esperado" y "-- Requiere".
--     Lote 0       preparación de la sesión: tablas #resultado e #id y el procedimiento #registrar
--     E-x.y.nn     prueba exitosa de la sección x.y (en la Parte 3, un lote por SP agrupa sus casos)
--     P-x.y.nn     preparación de datos (sin verificaciones)
--     RESUMEN      listado final: cantidad de OK y FALLO, y el detalle de cada prueba
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
--   Todo junto: recrear la base (entrega5_db_definition.sql, entrega5_sp_ABM.sql y
--   entrega5_sp_logica_negocio.sql) y ejecutar este archivo completo, de una vez.
--   Con Docker: ./sqlserver-docker/entrega5.sh exitosos  (recrea la base y lo ejecuta).
--   Un lote puntual: sobre la base recién creada y en una misma ventana de consulta, ejecutar el
--   Lote 0, luego los lotes que indica su línea "Requiere" y por último el lote buscado (buscar
--   su id con Ctrl+F). En la Parte 3 hay un lote por SP: cada caso son dos o tres líneas que empiezan
--   con "-- <id>"; para ejecutar uno solo, seleccionar el DECLARE del lote y las líneas del caso. Cada prueba informa OK o FALLO en Mensajes y queda en #resultado;
--   el lote RESUMEN las lista. Las Partes 1 y 2 son un escenario encadenado: cada lote va
--   después de los anteriores. Los casos válidos de la Parte 3 también se aplican en orden.
--   Los datos se cargan a través de los SP. Las únicas sentencias directas son las de algunas
--   preparaciones de la Parte 3, que dejan partidos de prueba en estado 'finalizado'.
-- ============================================================


USE mundial_2026;
GO

SET NOCOUNT ON;
GO

PRINT '--- Control de la ejecución completa: la base tiene que estar recién creada';
-- Al ejecutar el archivo completo sobre una base con datos, avisa y no ejecuta nada más.
-- (Al ejecutar lotes sueltos se puede omitir este lote.)
IF EXISTS (SELECT 1 FROM torneo.pais)
BEGIN
    RAISERROR('La base ya tiene datos: ejecutar primero entrega5_db_definition.sql, entrega5_sp_ABM.sql y entrega5_sp_logica_negocio.sql para recrearla. No se ejecuta ninguna prueba.', 16, 1);
    SET NOEXEC ON;
END;
GO

PRINT '--- Lote 0: preparación de la sesión';
-- Ejecutar primero, en la misma ventana de consulta que el resto de los lotes. Se puede volver a ejecutar:
-- recrea las tablas temporales y los procedimientos de registro de resultados.

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
IF OBJECT_ID('tempdb..#id') IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.pais) DROP TABLE #id;   -- se conserva si ya hay escenario
CREATE TABLE #resultado (orden INT IDENTITY(1, 1), prueba VARCHAR(12) COLLATE DATABASE_DEFAULT,
                         descripcion VARCHAR(300) COLLATE DATABASE_DEFAULT, resultado VARCHAR(5) COLLATE DATABASE_DEFAULT,
                         detalle VARCHAR(2100) COLLATE DATABASE_DEFAULT);
IF OBJECT_ID('tempdb..#id') IS NULL
    CREATE TABLE #id (clave VARCHAR(20) PRIMARY KEY, valor INT);   -- ids generados por el escenario, para los lotes siguientes
GO

IF OBJECT_ID('tempdb..#registrar') IS NOT NULL DROP PROCEDURE #registrar;
GO

-- Registra el resultado de una prueba en #resultado y lo informa en Mensajes con OK o FALLO al comienzo de la línea.
--   @esperado = 0: la operación debe aceptarse.  @esperado = N > 0: debe rechazarse con N condiciones.
--   El error a evaluar (50001 validación o 50002 lógica de negocio) es el que se pasa en @numero y @mensaje,
--   el que está capturando el CATCH desde el que se lo llama o el que guardó #capturar. Con @errores evalúa la
--   salida de un SP *_validar. Sin error ni @errores, la operación terminó sin error.
--   (Las variables de un procedimiento temporal usan la intercalación de tempdb: por eso los COLLATE.)
CREATE PROCEDURE #registrar
    @prueba      VARCHAR(12),
    @descripcion VARCHAR(300),
    @esperado    INT,
    @errores     VARCHAR(2000) = NULL,
    @numero      INT = NULL,
    @mensaje     VARCHAR(2100) = NULL
AS
BEGIN
    DECLARE @condiciones INT, @resultado VARCHAR(5), @detalle VARCHAR(2100);
    IF @numero IS NULL SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
    IF @numero IS NULL   -- error guardado por #capturar (sobrevive al ROLLBACK de la prueba)
        SELECT @numero = CAST(SESSION_CONTEXT(N'prueba_error_numero') AS INT),
               @mensaje = CAST(SESSION_CONTEXT(N'prueba_error_mensaje') AS VARCHAR(2100));
    EXEC sp_set_session_context N'prueba_error_numero', NULL;
    EXEC sp_set_session_context N'prueba_error_mensaje', NULL;
    IF @numero IS NULL SET @mensaje = @errores;
    SET @mensaje = ISNULL(@mensaje, '') COLLATE DATABASE_DEFAULT;
    SET @condiciones = LEN(CHAR(10) + @mensaje COLLATE DATABASE_DEFAULT)
                     - LEN(REPLACE(CHAR(10) + @mensaje COLLATE DATABASE_DEFAULT, CHAR(10) + '-', CHAR(10)));

    IF @numero IS NOT NULL
        SELECT @resultado = IIF(@esperado > 0 AND @numero IN (50001, 50002) AND @condiciones = @esperado, 'OK', 'FALLO'),
               @detalle = CONCAT('Error ', @numero, ' con ', @condiciones, ' condición(es): ', @mensaje COLLATE DATABASE_DEFAULT);
    ELSE IF @errores IS NOT NULL
        SELECT @resultado = IIF(@condiciones = @esperado, 'OK', 'FALLO'),
               @detalle = IIF(LEN(@mensaje) = 0, IIF(@esperado = 0, '', 'El SP *_validar no informó ninguna condición'),
                              CONCAT(@condiciones, ' condición(es): ', @mensaje COLLATE DATABASE_DEFAULT));
    ELSE
        SELECT @resultado = IIF(@esperado = 0, 'OK', 'FALLO'), @detalle = IIF(@esperado = 0, '', 'No se rechazó');

    INSERT INTO #resultado (prueba, descripcion, resultado, detalle) VALUES (@prueba, @descripcion, @resultado, @detalle);
    PRINT CONCAT(LEFT(@resultado COLLATE DATABASE_DEFAULT + '      ', 6), @prueba COLLATE DATABASE_DEFAULT, ' ', @descripcion COLLATE DATABASE_DEFAULT);
    IF LEN(@detalle) > 0 PRINT CONCAT('      ', @detalle COLLATE DATABASE_DEFAULT);
END;
GO

IF OBJECT_ID('tempdb..#capturar') IS NOT NULL DROP PROCEDURE #capturar;
GO

-- Llamado desde un CATCH, guarda el error en el contexto de la sesión para que #registrar lo evalúe después
-- del ROLLBACK de la prueba (una tabla temporal se desharía junto con la transacción).
CREATE PROCEDURE #capturar
AS
BEGIN
    DECLARE @numero INT = ERROR_NUMBER(), @mensaje NVARCHAR(2100) = ERROR_MESSAGE();
    EXEC sp_set_session_context N'prueba_error_numero', @numero;
    EXEC sp_set_session_context N'prueba_error_mensaje', @mensaje;
END;
GO

EXEC sp_set_session_context N'prueba_error_numero', NULL;
EXEC sp_set_session_context N'prueba_error_mensaje', NULL;
GO

IF OBJECT_ID('tempdb..#informar') IS NOT NULL DROP PROCEDURE #informar;
GO

-- Informa con OK o FALLO las verificaciones que un lote del escenario registró en #resultado.
CREATE PROCEDURE #informar
    @prueba VARCHAR(12)
AS
BEGIN
    DECLARE @linea VARCHAR(2500), @orden INT = 0;
    WHILE 1 = 1
    BEGIN
        SELECT TOP (1) @orden = orden,
               @linea = CONCAT(LEFT(resultado + '      ', 6), prueba, ' ', descripcion, IIF(resultado = 'OK' OR detalle = '', '', CHAR(13) + CHAR(10) + '      ' + detalle))
        FROM #resultado WHERE prueba = @prueba COLLATE DATABASE_DEFAULT AND orden > @orden ORDER BY orden;
        IF @@ROWCOUNT = 0 BREAK;
        PRINT @linea;
    END;
    IF NOT EXISTS (SELECT 1 FROM #resultado WHERE prueba = @prueba COLLATE DATABASE_DEFAULT)
        PRINT CONCAT('FALLO ', @prueba COLLATE DATABASE_DEFAULT, ' no registró ningún resultado');
END;
GO

PRINT '################ PARTE 1: PROCEDIMIENTOS DE ABM (escenario) ################';
GO

-- ============================================================
-- 1.1 torneo.parametro
-- ============================================================

PRINT '--- E-1.1.01 Alta, modificación y baja de un parámetro';
-- Resultado esperado: el parámetro de prueba se crea con valor 7, pasa a 9 y se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
EXEC torneo.parametro_insertar 'parametro_de_prueba', 7, 'Parámetro creado por el test';
EXEC torneo.parametro_modificar 'parametro_de_prueba', 9;
SELECT clave, valor, descripcion FROM torneo.parametro WHERE clave = 'parametro_de_prueba';
INSERT INTO #resultado SELECT 'E-1.1.01', 'parametro: alta y modificación', IIF(COUNT(*) = 1 AND MAX(valor) = 9, 'OK', 'FALLO'), ''
FROM torneo.parametro WHERE clave = 'parametro_de_prueba';
EXEC torneo.parametro_eliminar 'parametro_de_prueba';
INSERT INTO #resultado SELECT 'E-1.1.01', 'parametro: baja', IIF(COUNT(*) = 0, 'OK', 'FALLO'), ''
FROM torneo.parametro WHERE clave = 'parametro_de_prueba';
EXEC #informar 'E-1.1.01';
GO

-- ============================================================
-- 1.2 torneo.pais y torneo.confederacion
-- ============================================================

PRINT '--- E-1.2.01 Alta de países y confederaciones';
-- Resultado esperado: 11 países (uno temporal) y 6 confederaciones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT;
EXEC torneo.pais_insertar 'ARG', 'Argentina',      'UTC-03', 13700, @id OUTPUT; INSERT INTO #id VALUES ('pais_ARG', @id);
EXEC torneo.pais_insertar 'BRA', 'Brasil',         'UTC-03', 10300, @id OUTPUT; INSERT INTO #id VALUES ('pais_BRA', @id);
EXEC torneo.pais_insertar 'URY', 'Uruguay',        'UTC-03', 22000, @id OUTPUT; INSERT INTO #id VALUES ('pais_URY', @id);
EXEC torneo.pais_insertar 'USA', 'Estados Unidos', 'UTC-05', 82700, @id OUTPUT; INSERT INTO #id VALUES ('pais_USA', @id);
EXEC torneo.pais_insertar 'CAN', 'Canadá',         'UTC-05', 53400, @id OUTPUT; INSERT INTO #id VALUES ('pais_CAN', @id);
EXEC torneo.pais_insertar 'MEX', 'México',         'UTC-06', 13800, @id OUTPUT; INSERT INTO #id VALUES ('pais_MEX', @id);
EXEC torneo.pais_insertar 'FRA', 'Francia',        'UTC+01', 44700, @id OUTPUT; INSERT INTO #id VALUES ('pais_FRA', @id);
EXEC torneo.pais_insertar 'DEU', 'Alemania',       'UTC+01', 52700, @id OUTPUT; INSERT INTO #id VALUES ('pais_DEU', @id);
EXEC torneo.pais_insertar 'ESP', 'España',         'UTC+01', 33500, @id OUTPUT; INSERT INTO #id VALUES ('pais_ESP', @id);
EXEC torneo.pais_insertar 'JPN', 'Japón',          'UTC+09', 33800, @id OUTPUT; INSERT INTO #id VALUES ('pais_JPN', @id);
EXEC torneo.pais_insertar 'zzz', 'País temporal',  'UTC+00', NULL,  @id OUTPUT; INSERT INTO #id VALUES ('pais_ZZZ', @id);

EXEC torneo.confederacion_insertar 'CONMEBOL', @id OUTPUT; INSERT INTO #id VALUES ('conf_CONMEBOL', @id);
EXEC torneo.confederacion_insertar 'UEFA',     @id OUTPUT; INSERT INTO #id VALUES ('conf_UEFA', @id);
EXEC torneo.confederacion_insertar 'CONCACAF', @id OUTPUT; INSERT INTO #id VALUES ('conf_CONCACAF', @id);
EXEC torneo.confederacion_insertar 'AFC',      @id OUTPUT; INSERT INTO #id VALUES ('conf_AFC', @id);
EXEC torneo.confederacion_insertar 'CAF',      @id OUTPUT; INSERT INTO #id VALUES ('conf_CAF', @id);
EXEC torneo.confederacion_insertar 'OFC',      @id OUTPUT; INSERT INTO #id VALUES ('conf_OFC', @id);

SELECT pais_id, codigo_iso, nombre, huso_horario, pbi_per_capita FROM torneo.pais ORDER BY pais_id;
SELECT confederacion_id, nombre FROM torneo.confederacion ORDER BY confederacion_id;
INSERT INTO #resultado SELECT 'E-1.2.01', 'pais: alta (el código se guarda en mayúsculas)',
       IIF(COUNT(*) = 11 AND SUM(CASE WHEN codigo_iso = 'ZZZ' COLLATE Latin1_General_CS_AS THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM torneo.pais;
INSERT INTO #resultado SELECT 'E-1.2.01', 'confederacion: alta', IIF(COUNT(*) = 6, 'OK', 'FALLO'), '' FROM torneo.confederacion;
EXEC #informar 'E-1.2.01';
GO

PRINT '--- E-1.2.02 Modificación y baja de país; modificación y baja de confederación';
-- Resultado esperado: Argentina queda con PBI 14000; el país temporal y la confederación OFC se eliminan.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'pais_ARG'), @zzz INT = (SELECT valor FROM #id WHERE clave = 'pais_ZZZ'),
        @ofc INT = (SELECT valor FROM #id WHERE clave = 'conf_OFC');
EXEC torneo.pais_modificar @arg, 'ARG', 'Argentina', 'UTC-03', 14000;
EXEC torneo.pais_eliminar @zzz;
EXEC torneo.confederacion_modificar @ofc, 'OFC';
EXEC torneo.confederacion_eliminar @ofc;
SELECT codigo_iso, nombre, pbi_per_capita FROM torneo.pais WHERE codigo_iso IN ('ARG', 'ZZZ');
INSERT INTO #resultado SELECT 'E-1.2.02', 'pais: modificación y baja',
       IIF(SUM(CASE WHEN codigo_iso = 'ARG' AND pbi_per_capita = 14000 THEN 1 ELSE 0 END) = 1
           AND SUM(CASE WHEN codigo_iso = 'ZZZ' THEN 1 ELSE 0 END) = 0, 'OK', 'FALLO'), '' FROM torneo.pais;
INSERT INTO #resultado SELECT 'E-1.2.02', 'confederacion: baja', IIF(COUNT(*) = 5, 'OK', 'FALLO'), '' FROM torneo.confederacion;
EXEC #informar 'E-1.2.02';
GO

-- ============================================================
-- 1.3 torneo.sede
-- ============================================================

PRINT '--- E-1.3.01 Alta, modificación y baja de sedes';
-- Resultado esperado: quedan 3 sedes (husos UTC-04 y UTC-06); MetLife pasa a capacidad 82500; la temporal se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT, @usa INT = (SELECT valor FROM #id WHERE clave = 'pais_USA'),
        @mex INT = (SELECT valor FROM #id WHERE clave = 'pais_MEX'), @can INT = (SELECT valor FROM #id WHERE clave = 'pais_CAN');
EXEC torneo.sede_insertar 'MetLife Stadium', 'East Rutherford', @usa, 82000, 'UTC-04', @id OUTPUT; INSERT INTO #id VALUES ('sede_NY', @id);
EXEC torneo.sede_insertar 'Estadio Azteca', 'Ciudad de México', @mex, 83000, 'UTC-06', @id OUTPUT; INSERT INTO #id VALUES ('sede_MX', @id);
EXEC torneo.sede_insertar 'BMO Field', 'Toronto', @can, 45000, 'UTC-04', @id OUTPUT;              INSERT INTO #id VALUES ('sede_TO', @id);
EXEC torneo.sede_insertar 'Estadio temporal', 'Ciudad temporal', @can, 100, 'UTC-04', @id OUTPUT;
EXEC torneo.sede_eliminar @id;
SET @id = (SELECT valor FROM #id WHERE clave = 'sede_NY');
EXEC torneo.sede_modificar @id, 'MetLife Stadium', 'East Rutherford', @usa, 82500, 'UTC-04';
SELECT sede_id, nombre, ciudad, capacidad, huso_horario FROM torneo.sede ORDER BY sede_id;
INSERT INTO #resultado SELECT 'E-1.3.01', 'sede: alta, modificación y baja',
       IIF(COUNT(*) = 3 AND MAX(capacidad) = 83000 AND SUM(CASE WHEN capacidad = 82500 THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), '' FROM torneo.sede;
EXEC #informar 'E-1.3.01';
GO

-- ============================================================
-- 1.4 torneo.seleccion
-- ============================================================

PRINT '--- E-1.4.01 Alta, modificación y baja de selecciones';
-- Resultado esperado: 4 selecciones en el grupo A y Brasil en el B; la de España (temporal) se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT, @conmebol INT = (SELECT valor FROM #id WHERE clave = 'conf_CONMEBOL'), @uefa INT = (SELECT valor FROM #id WHERE clave = 'conf_UEFA'),
        @concacaf INT = (SELECT valor FROM #id WHERE clave = 'conf_CONCACAF'), @afc INT = (SELECT valor FROM #id WHERE clave = 'conf_AFC'), @pais INT;
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_ARG'); EXEC torneo.seleccion_insertar @pais, @conmebol, 'A', @id OUTPUT; INSERT INTO #id VALUES ('ARG', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_FRA'); EXEC torneo.seleccion_insertar @pais, @uefa, 'A', @id OUTPUT;     INSERT INTO #id VALUES ('FRA', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_MEX'); EXEC torneo.seleccion_insertar @pais, @concacaf, 'A', @id OUTPUT; INSERT INTO #id VALUES ('MEX', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_JPN'); EXEC torneo.seleccion_insertar @pais, @afc, 'A', @id OUTPUT;      INSERT INTO #id VALUES ('JPN', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_BRA'); EXEC torneo.seleccion_insertar @pais, @conmebol, 'C', @id OUTPUT; INSERT INTO #id VALUES ('BRA', @id);
EXEC torneo.seleccion_modificar @id, @pais, @conmebol, 'b';
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_ESP'); EXEC torneo.seleccion_insertar @pais, @uefa, 'B', @id OUTPUT;
EXEC torneo.seleccion_eliminar @id;
SELECT s.seleccion_id, p.nombre AS pais, c.nombre AS confederacion, s.grupo
FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id JOIN torneo.confederacion c ON c.confederacion_id = s.confederacion_id
ORDER BY s.seleccion_id;
INSERT INTO #resultado SELECT 'E-1.4.01', 'seleccion: alta, modificación y baja',
       IIF(COUNT(*) = 5 AND SUM(CASE WHEN grupo = 'A' THEN 1 ELSE 0 END) = 4 AND SUM(CASE WHEN grupo = 'B' THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM torneo.seleccion;
EXEC #informar 'E-1.4.01';
GO

-- ============================================================
-- 1.5 torneo.partido
-- ============================================================

PRINT '--- E-1.5.01 Alta, modificación y baja de partidos';
-- Resultado esperado: 4 partidos programados, con la hora UTC derivada de la hora local
-- (P1 20:00 UTC-04 = 00:00 UTC del día siguiente). P3 se reprograma a las 16:00. El partido temporal se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT, @ny INT = (SELECT valor FROM #id WHERE clave = 'sede_NY'), @mx INT = (SELECT valor FROM #id WHERE clave = 'sede_MX'),
        @to INT = (SELECT valor FROM #id WHERE clave = 'sede_TO'), @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'),
        @fra INT = (SELECT valor FROM #id WHERE clave = 'FRA'), @mex INT = (SELECT valor FROM #id WHERE clave = 'MEX'),
        @jpn INT = (SELECT valor FROM #id WHERE clave = 'JPN');
EXEC torneo.partido_insertar @ny, '2026-06-12T20:00:00-04:00', 'grupos', @arg, @fra, NULL, @id OUTPUT;        INSERT INTO #id VALUES ('P1', @id);
EXEC torneo.partido_insertar @mx, '2026-06-17T18:00:00-06:00', 'grupos', @arg, @mex, NULL, @id OUTPUT;        INSERT INTO #id VALUES ('P2', @id);
EXEC torneo.partido_insertar @to, '2026-06-22T13:00:00-04:00', 'grupos', @arg, @jpn, NULL, @id OUTPUT;        INSERT INTO #id VALUES ('P3', @id);
EXEC torneo.partido_modificar @id, @to, '2026-06-22T16:00:00-04:00', 'grupos', @arg, @jpn;
EXEC torneo.partido_insertar @ny, '2026-06-29T18:00:00-04:00', 'dieciseisavos', @fra, @jpn, NULL, @id OUTPUT; INSERT INTO #id VALUES ('P4', @id);
EXEC torneo.partido_insertar @mx, '2026-06-25T18:00:00-06:00', 'grupos', @mex, @jpn, NULL, @id OUTPUT;
EXEC torneo.partido_eliminar @id;
SELECT partido_id, fase, fecha_hora_local, fecha_hora_utc, seleccion_local_id, seleccion_visitante_id, estado FROM torneo.partido ORDER BY partido_id;
INSERT INTO #resultado SELECT 'E-1.5.01', 'partido: alta (UTC derivada), modificación y baja',
       IIF(COUNT(*) = 4
           AND SUM(CASE WHEN fecha_hora_utc = '2026-06-13T00:00:00+00:00' AND DATEPART(TZOFFSET, fecha_hora_utc) = 0 THEN 1 ELSE 0 END) = 1
           AND SUM(CASE WHEN fecha_hora_local = '2026-06-22T16:00:00-04:00' THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM torneo.partido;
EXEC #informar 'E-1.5.01';
GO

-- ============================================================
-- 1.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================

PRINT '--- E-1.6.01 Alta, modificación y baja de cuerpo técnico (crea y borra su persona)';
-- Resultado esperado: 3 integrantes (DT y ayudante de Argentina, DT de Francia), cada uno con su persona 'cuerpo_tecnico'.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT, @persona INT, @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'), @fra INT = (SELECT valor FROM #id WHERE clave = 'FRA');
EXEC plantel.cuerpo_tecnico_insertar @arg, 'Lionel', 'Scaloni', 'director_tecnico', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_insertar @arg, 'Pablo', 'Aimar', 'otro', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_modificar @id, @arg, 'Pablo', 'Aimar', 'ayudante_tecnico';
EXEC plantel.cuerpo_tecnico_insertar @fra, 'Didier', 'Deschamps', 'director_tecnico', @id OUTPUT, @persona OUTPUT;
INSERT INTO #id VALUES ('persona_DT_FRA', @persona);
EXEC plantel.cuerpo_tecnico_insertar @fra, 'Temporal', 'Temporal', 'otro', @id OUTPUT, @persona OUTPUT;
EXEC plantel.cuerpo_tecnico_eliminar @id;
SELECT ct.staff_id, ct.persona_id, pe.tipo_persona, ct.seleccion_id, ct.nombre, ct.apellido, ct.rol
FROM plantel.cuerpo_tecnico ct JOIN plantel.persona pe ON pe.persona_id = ct.persona_id ORDER BY ct.staff_id;
INSERT INTO #resultado SELECT 'E-1.6.01', 'cuerpo_tecnico: alta, modificación y baja (con su persona)',
       IIF((SELECT COUNT(*) FROM plantel.cuerpo_tecnico) = 3 AND (SELECT COUNT(*) FROM plantel.persona) = 3
           AND EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico WHERE apellido = 'Aimar' AND rol = 'ayudante_tecnico'), 'OK', 'FALLO'), '';
EXEC #informar 'E-1.6.01';
GO

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
SELECT nombre AS seleccion, COUNT(*) AS jugadores, MIN(fecha_nacimiento) AS mayor, MAX(fecha_nacimiento) AS menor
FROM plantel.jugador GROUP BY nombre ORDER BY nombre;
INSERT INTO #resultado SELECT 'E-1.6.02', 'jugador: alta masiva (con su persona)',
       IIF((SELECT COUNT(*) FROM plantel.jugador) = 97
           AND (SELECT COUNT(*) FROM plantel.persona WHERE tipo_persona = 'jugador') = 97, 'OK', 'FALLO'), '';
EXEC #informar 'E-1.6.02';
GO

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
SELECT jugador_id, nombre, apellido, fecha_nacimiento, club_origen, posicion_habitual FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 10';
INSERT INTO #resultado SELECT 'E-1.6.03', 'jugador y persona: modificación y baja',
       IIF((SELECT COUNT(*) FROM plantel.jugador) = 97 AND (SELECT COUNT(*) FROM plantel.persona) = 100
           AND EXISTS (SELECT 1 FROM plantel.jugador WHERE club_origen = 'Inter Miami CF'), 'OK', 'FALLO'), '';
EXEC #informar 'E-1.6.03';
GO

-- ============================================================
-- 1.7 plantel.convocatoria
-- ============================================================

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
SELECT p.codigo_iso, COUNT(*) AS convocados_vigentes, MIN(c.dorsal) AS dorsal_min, MAX(c.dorsal) AS dorsal_max
FROM plantel.convocatoria c JOIN torneo.seleccion s ON s.seleccion_id = c.seleccion_id JOIN torneo.pais p ON p.pais_id = s.pais_id
WHERE c.fecha_baja IS NULL GROUP BY p.codigo_iso ORDER BY p.codigo_iso;
INSERT INTO #resultado SELECT 'E-1.7.01', 'convocatoria: alta', IIF(COUNT(*) = 96, 'OK', 'FALLO'), '' FROM plantel.convocatoria;
EXEC #informar 'E-1.7.01';
GO

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
SELECT j.nombre, j.apellido, c.dorsal, c.fecha_alta, c.fecha_baja FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE j.apellido IN ('Jugador 24', 'Jugador 26') AND j.nombre IN ('ARG', 'JPN') ORDER BY j.nombre, j.apellido;
INSERT INTO #resultado SELECT 'E-1.7.02', 'convocatoria: modificación y baja',
       IIF(COUNT(*) = 95 AND SUM(CASE WHEN dorsal = 99 THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), '' FROM plantel.convocatoria;
EXEC #informar 'E-1.7.02';
GO

-- ============================================================
-- 1.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================

PRINT '--- E-1.8.01 Alta y modificación de formación y de sus jugadores';
-- Resultado esperado: formación visitante (Japón) de P3 con esquema 3-5-2 y 2 jugadores: dorsal 1 titular
-- y dorsal 12 suplente. El dorsal lo completa el SP desde la convocatoria.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @jpn INT = (SELECT valor FROM #id WHERE clave = 'JPN'), @form INT, @j INT;
EXEC plantel.formacion_insertar @p3, 'visitante', '4-4-2', @form OUTPUT;
INSERT INTO #id VALUES ('form_tmp', @form);
EXEC plantel.formacion_modificar @form, '3-5-2';
SELECT @j = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @jpn AND dorsal = 1 AND fecha_baja IS NULL;
EXEC plantel.formacion_jugador_insertar @form, @j, 'arquero', 1;
SELECT @j = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @jpn AND dorsal = 12 AND fecha_baja IS NULL;
EXEC plantel.formacion_jugador_insertar @form, @j, 'arquero', 1;
EXEC plantel.formacion_jugador_modificar @form, @j, 'arquero suplente', 0;
SELECT f.formacion_id, f.partido_id, f.condicion, f.esquema_tactico, fj.jugador_id, fj.dorsal, fj.posicion, fj.titular
FROM plantel.formacion f JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.formacion_id = @form;
INSERT INTO #resultado SELECT 'E-1.8.01', 'formacion y formacion_jugador: alta y modificación',
       IIF(COUNT(*) = 2 AND SUM(CASE WHEN dorsal = 12 AND titular = 0 THEN 1 ELSE 0 END) = 1
           AND (SELECT esquema_tactico FROM plantel.formacion WHERE formacion_id = @form) = '3-5-2', 'OK', 'FALLO'), ''
FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC #informar 'E-1.8.01';
GO

PRINT '--- E-1.8.02 Baja de jugadores de la formación y de la formación';
-- Resultado esperado: P3 vuelve a quedar sin formaciones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @form INT = (SELECT valor FROM #id WHERE clave = 'form_tmp'), @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @j INT;
SELECT @j = MIN(jugador_id) FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC plantel.formacion_jugador_eliminar @form, @j;
SELECT @j = MIN(jugador_id) FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC plantel.formacion_jugador_eliminar @form, @j;
EXEC plantel.formacion_eliminar @form;
INSERT INTO #resultado SELECT 'E-1.8.02', 'formacion y formacion_jugador: baja', IIF(COUNT(*) = 0, 'OK', 'FALLO'), ''
FROM plantel.formacion WHERE partido_id = @p3;
EXEC #informar 'E-1.8.02';
GO

-- ============================================================
-- PREPARACIÓN: formaciones de P1 (Argentina vs Francia), necesarias para probar el ABM de los
-- eventos. Se cargan con plantel.cargar_formacion, cuyas pruebas propias están en 2.2.
-- Titulares: dorsales 1 a 11. Suplentes: 12 a 23.
-- ============================================================

PRINT '--- P-1.8.01 Preparación: formaciones de P1 (Argentina vs Francia), necesarias para probar el ABM de los';
-- Sin verificaciones: carga las formaciones de P1 con plantel.cargar_formacion (sus pruebas están en 2.2).
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'),
        @fra INT = (SELECT valor FROM #id WHERE clave = 'FRA'), @form INT;
DECLARE @local plantel.tt_formacion_jugador, @visitante plantel.tt_formacion_jugador;
INSERT INTO @local (jugador_id, posicion, titular)
SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23;
INSERT INTO @visitante (jugador_id, posicion, titular)
SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL AND c.dorsal <= 23;
EXEC plantel.cargar_formacion @p1, 'local', '4-3-3', @local, @form OUTPUT;         INSERT INTO #id VALUES ('P1_local', @form);
EXEC plantel.cargar_formacion @p1, 'visitante', '4-4-2', @visitante, @form OUTPUT; INSERT INTO #id VALUES ('P1_visitante', @form);
GO

-- ============================================================
-- 1.9 evento.sustitucion
-- ============================================================

PRINT '--- E-1.9.01 Alta, modificación y baja de sustitución';
-- Resultado esperado: queda un cambio de Argentina (sale el 9, entra el 14) en el minuto 62 del ST, ventana 1.
-- El segundo cambio (sale 8, entra 15, ventana 2) se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @form INT = (SELECT valor FROM #id WHERE clave = 'P1_local'), @sust INT, @tmp INT,
        @j8 INT, @j9 INT, @j14 INT, @j15 INT;
SELECT @j8  = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 8;
SELECT @j9  = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 9;
SELECT @j14 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 14;
SELECT @j15 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 15;
EXEC evento.sustitucion_insertar @form, @j9, @j14, 60, 'ST', 1, 'tactico', @sust OUTPUT;
EXEC evento.sustitucion_modificar @sust, 62, 'ST', 1, 'precaucion';
EXEC evento.sustitucion_insertar @form, @j8, @j15, 75, 'ST', 2, 'tactico', @tmp OUTPUT;
EXEC evento.sustitucion_eliminar @tmp;
SELECT sustitucion_id, formacion_id, jugador_sale_id, jugador_entra_id, minuto, periodo, numero_ventana, motivo FROM evento.sustitucion;
INSERT INTO #resultado SELECT 'E-1.9.01', 'sustitucion: alta, modificación y baja',
       IIF(COUNT(*) = 1 AND MAX(minuto) = 62 AND MAX(motivo) = 'precaucion', 'OK', 'FALLO'), '' FROM evento.sustitucion;
EXEC #informar 'E-1.9.01';
GO

-- ============================================================
-- 1.10 evento.gol (cada operación actualiza el marcador del partido en la misma transacción)
-- ============================================================

PRINT '--- E-1.10.01 Alta, modificación y baja de gol';
-- Resultado esperado: gol del 10 de Argentina con asistencia del 11 (queda como 'cabezazo', minuto 24) => 1 a 0.
-- Un gol en contra del 2 de Francia lleva el marcador a 2 a 0; al eliminarlo vuelve a 1 a 0.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @local INT = (SELECT valor FROM #id WHERE clave = 'P1_local'),
        @visitante INT = (SELECT valor FROM #id WHERE clave = 'P1_visitante'), @gol INT, @tmp INT, @j10 INT, @j11 INT, @f2 INT, @marcador VARCHAR(10);
SELECT @j10 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 10;
SELECT @j11 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 11;
SELECT @f2 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @visitante AND dorsal = 2;
EXEC evento.gol_insertar @local, @j10, 23, 'jugada', 'PT', @j11, @gol OUTPUT;
EXEC evento.gol_modificar @gol, 24, 'cabezazo', 'PT', @j11;
EXEC evento.gol_insertar @visitante, @f2, 35, 'en_contra', 'PT', NULL, @tmp OUTPUT;
SELECT @marcador = CAST(goles_local AS VARCHAR(2)) + '-' + CAST(goles_visitante AS VARCHAR(2)) FROM torneo.partido WHERE partido_id = @p1;
PRINT 'Marcador con el gol en contra: ' + @marcador;
INSERT INTO #resultado VALUES ('E-1.10.01', 'gol: el gol en contra suma al rival (2-0)', IIF(@marcador = '2-0', 'OK', 'FALLO'), @marcador);
EXEC evento.gol_eliminar @tmp;
SELECT g.gol_id, g.formacion_id, g.jugador_id, g.asistencia_jugador_id, g.minuto, g.tipo_gol, g.periodo FROM evento.gol g;
SELECT partido_id, goles_local, goles_visitante, penales_local, penales_visitante, estado FROM torneo.partido WHERE partido_id = @p1;
INSERT INTO #resultado SELECT 'E-1.10.01', 'gol: alta, modificación y baja con marcador sincronizado (1-0)',
       IIF(goles_local = 1 AND goles_visitante = 0 AND penales_local IS NULL
           AND (SELECT COUNT(*) FROM evento.gol WHERE tipo_gol = 'cabezazo' AND minuto = 24) = 1, 'OK', 'FALLO'), ''
FROM torneo.partido WHERE partido_id = @p1;
EXEC #informar 'E-1.10.01';
GO

PRINT '--- E-1.10.02 Alta de gol inválida';
-- autor (20) suplente que no ingresó, asistente igual al autor y asistente que no ingresó.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @local INT = (SELECT valor FROM #id WHERE clave = 'P1_local'), @j20 INT;
SELECT @j20 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 20;
INSERT INTO #resultado SELECT 'E-1.10.02', 'gol: el rechazo no altera el marcador', IIF(goles_local = 1 AND goles_visitante = 0, 'OK', 'FALLO'), ''
FROM torneo.partido WHERE partido_id = @p1;
EXEC #informar 'E-1.10.02';
GO

-- ============================================================
-- 1.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================

PRINT '--- E-1.11.01 Alta, modificación y baja de tarjeta';
-- Resultado esperado: queda una amarilla al 6 de Francia (minuto 31 del PT). La amarilla temporal al 7 se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @visitante INT = (SELECT valor FROM #id WHERE clave = 'P1_visitante'),
        @pers6 INT, @pers7 INT, @tarjeta INT, @tmp INT;
SELECT @pers6 = j.persona_id FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
WHERE fj.formacion_id = @visitante AND fj.dorsal = 6;
SELECT @pers7 = j.persona_id FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
WHERE fj.formacion_id = @visitante AND fj.dorsal = 7;
EXEC evento.tarjeta_insertar @p1, @pers6, 30, 'PT', 'amarilla', 'Juego brusco', NULL, @tarjeta OUTPUT;
INSERT INTO #id VALUES ('tarjeta_FRA6', @tarjeta);
EXEC evento.tarjeta_modificar @tarjeta, 31, 'PT', 'Juego brusco grave';
EXEC evento.tarjeta_insertar @p1, @pers7, 40, 'PT', 'amarilla', 'Protesta', NULL, @tmp OUTPUT;
EXEC evento.tarjeta_eliminar @tmp;
SELECT tarjeta_id, partido_id, persona_id, minuto, periodo, tipo, motivo, tipo_expulsion FROM evento.tarjeta;
INSERT INTO #resultado SELECT 'E-1.11.01', 'tarjeta: alta, modificación y baja',
       IIF(COUNT(*) = 1 AND MAX(minuto) = 31, 'OK', 'FALLO'), '' FROM evento.tarjeta;
EXEC #informar 'E-1.11.01';
GO

PRINT '--- E-1.11.02 ABM de criterios de suspensión';
-- Resultado esperado: quedan 2 criterios activos: general (2 amarillas => 1 partido) y cuerpo técnico (3 amarillas => 1 partido).
-- El criterio temporal de semifinal se modifica y se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 2, 1, NULL, NULL, 1, @id OUTPUT;             INSERT INTO #id VALUES ('criterio_general', @id);
EXEC evento.criterio_suspension_insertar 3, 1, NULL, 'cuerpo_tecnico', 1, @id OUTPUT;
EXEC evento.criterio_suspension_insertar 1, 1, 'semifinal', NULL, 1, @id OUTPUT;
EXEC evento.criterio_suspension_modificar @id, 1, 2, 'semifinal', NULL, 0;
EXEC evento.criterio_suspension_eliminar @id;
SELECT criterio_id, fase_aplicable, tipo_persona_aplicable, cantidad_amarillas, partidos_suspension, activo FROM evento.criterio_suspension;
INSERT INTO #resultado SELECT 'E-1.11.02', 'criterio_suspension: alta, modificación y baja', IIF(COUNT(*) = 2, 'OK', 'FALLO'), '' FROM evento.criterio_suspension;
EXEC #informar 'E-1.11.02';
GO

PRINT '--- E-1.11.03 ABM de suspensión (carga manual)';
-- Resultado esperado: se carga a mano una suspensión del 6 de Francia para P4, se le corrige el motivo y se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @tarjeta INT = (SELECT valor FROM #id WHERE clave = 'tarjeta_FRA6'), @criterio INT = (SELECT valor FROM #id WHERE clave = 'criterio_general'),
        @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'), @susp INT, @antes INT;
EXEC evento.suspension_insertar @tarjeta, 'Sanción de oficio', @criterio, @p4, @susp OUTPUT;
EXEC evento.suspension_modificar @susp, 'Sanción de oficio del comité disciplinario', @p4;
SELECT suspension_id, criterio_id, tarjeta_id, partido_afectado_id, motivo FROM evento.suspension;
SELECT @antes = COUNT(*) FROM evento.suspension WHERE motivo LIKE '%comité%';
EXEC evento.suspension_eliminar @susp;
INSERT INTO #resultado SELECT 'E-1.11.03', 'suspension: alta, modificación y baja', IIF(@antes = 1 AND COUNT(*) = 0, 'OK', 'FALLO'), '' FROM evento.suspension;
EXEC #informar 'E-1.11.03';
GO

-- ============================================================
-- 1.12 arbitraje: arbitro, arbitro_idioma, designacion_arbitral e informe_arbitral
-- ============================================================

PRINT '--- E-1.12.01 Alta, modificación y baja de árbitros e idiomas';
-- Resultado esperado: 9 árbitros de 7 países; Matonte con 2 idiomas (espanol, ingles). El árbitro temporal se elimina con sus idiomas.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @id INT, @pais INT;
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_URY');
EXEC arbitraje.arbitro_insertar 'Andrés', 'Matonte', @pais, 'FIFA', NULL, @id OUTPUT;          INSERT INTO #id VALUES ('arb_URY1', @id);
EXEC arbitraje.arbitro_idioma_insertar @id, 'Espanol';
EXEC arbitraje.arbitro_idioma_insertar @id, 'frances';
EXEC arbitraje.arbitro_idioma_modificar @id, 'frances', 'ingles';
EXEC arbitraje.arbitro_idioma_insertar @id, 'portugues';
EXEC arbitraje.arbitro_idioma_eliminar @id, 'portugues';
EXEC arbitraje.arbitro_insertar 'Nicolás', 'Tarán', @pais, 'confederacion', NULL, @id OUTPUT;  INSERT INTO #id VALUES ('arb_URY2', @id);
EXEC arbitraje.arbitro_modificar @id, 'Nicolás', 'Tarán', @pais, 'FIFA', '1980-12-25';
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_DEU');
EXEC arbitraje.arbitro_insertar 'Felix', 'Zwayer', @pais, 'FIFA', NULL, @id OUTPUT;            INSERT INTO #id VALUES ('arb_DEU1', @id);
EXEC arbitraje.arbitro_insertar 'Jan', 'Seidel', @pais, 'FIFA', NULL, @id OUTPUT;              INSERT INTO #id VALUES ('arb_DEU2', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_USA');
EXEC arbitraje.arbitro_insertar 'Ismail', 'Elfath', @pais, 'FIFA', NULL, @id OUTPUT;           INSERT INTO #id VALUES ('arb_USA', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_CAN');
EXEC arbitraje.arbitro_insertar 'Drew', 'Fischer', @pais, 'FIFA', NULL, @id OUTPUT;            INSERT INTO #id VALUES ('arb_CAN', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_MEX');
EXEC arbitraje.arbitro_insertar 'César', 'Ramos', @pais, 'FIFA', NULL, @id OUTPUT;             INSERT INTO #id VALUES ('arb_MEX', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_ARG');
EXEC arbitraje.arbitro_insertar 'Facundo', 'Tello', @pais, 'FIFA', NULL, @id OUTPUT;           INSERT INTO #id VALUES ('arb_ARG', @id);
SET @pais = (SELECT valor FROM #id WHERE clave = 'pais_BRA');
EXEC arbitraje.arbitro_insertar 'Wilton', 'Sampaio', @pais, 'FIFA', NULL, @id OUTPUT;          INSERT INTO #id VALUES ('arb_BRA', @id);
EXEC arbitraje.arbitro_insertar 'Temporal', 'Temporal', @pais, 'confederacion', NULL, @id OUTPUT;
EXEC arbitraje.arbitro_idioma_insertar @id, 'portugues';
EXEC arbitraje.arbitro_eliminar @id;
SELECT a.arbitro_id, a.nombre, a.apellido, p.codigo_iso, a.categoria, a.fecha_nacimiento,
       (SELECT STRING_AGG(i.idioma, ', ') FROM arbitraje.arbitro_idioma i WHERE i.arbitro_id = a.arbitro_id) AS idiomas
FROM arbitraje.arbitro a JOIN torneo.pais p ON p.pais_id = a.pais_id ORDER BY a.arbitro_id;
INSERT INTO #resultado SELECT 'E-1.12.01', 'arbitro y arbitro_idioma: alta, modificación y baja',
       IIF((SELECT COUNT(*) FROM arbitraje.arbitro) = 9 AND (SELECT COUNT(*) FROM arbitraje.arbitro_idioma) = 2
           AND EXISTS (SELECT 1 FROM arbitraje.arbitro_idioma WHERE idioma = 'ingles'), 'OK', 'FALLO'), '';
EXEC #informar 'E-1.12.01';
GO

PRINT '--- E-1.12.02 ABM de designación arbitral (de a una) y de informe arbitral';
-- Resultado esperado: en P2 se designa a Matonte como principal y luego se lo reemplaza por Elfath; el informe se
-- carga, se modifica y se elimina; finalmente se elimina la designación. P2 queda sin designaciones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @ury INT = (SELECT valor FROM #id WHERE clave = 'arb_URY1'),
        @usa INT = (SELECT valor FROM #id WHERE clave = 'arb_USA'), @arg INT = (SELECT valor FROM #id WHERE clave = 'arb_ARG'),
        @desig INT, @informe INT, @ok INT;
EXEC arbitraje.designacion_arbitral_insertar @p2, @ury, 'principal', @desig OUTPUT;
EXEC arbitraje.designacion_arbitral_modificar @desig, @usa, 'principal';
EXEC arbitraje.informe_arbitral_insertar @desig, '2026-06-18T03:00:00+00:00', 'Partido sin incidentes.', NULL, @informe OUTPUT;
EXEC arbitraje.informe_arbitral_modificar @informe, '2026-06-18T04:00:00+00:00', 'Partido con un incidente menor en el banco visitante.', 'Apercibimiento';
SELECT d.designacion_id, d.partido_id, a.apellido AS arbitro, d.rol, i.informe_id, i.fecha, i.contenido, i.sancion
FROM arbitraje.designacion_arbitral d JOIN arbitraje.arbitro a ON a.arbitro_id = d.arbitro_id
LEFT JOIN arbitraje.informe_arbitral i ON i.designacion_id = d.designacion_id;
SELECT @ok = COUNT(*) FROM arbitraje.designacion_arbitral d JOIN arbitraje.informe_arbitral i ON i.designacion_id = d.designacion_id
WHERE d.arbitro_id = @usa AND i.sancion = 'Apercibimiento';
EXEC arbitraje.informe_arbitral_eliminar @informe;
EXEC arbitraje.designacion_arbitral_eliminar @desig;
INSERT INTO #resultado SELECT 'E-1.12.02', 'designacion_arbitral e informe_arbitral: alta, modificación y baja',
       IIF(@ok = 1 AND (SELECT COUNT(*) FROM arbitraje.designacion_arbitral) = 0
           AND (SELECT COUNT(*) FROM arbitraje.informe_arbitral) = 0, 'OK', 'FALLO'), '';
EXEC #informar 'E-1.12.02';
GO

-- ============================================================
-- 1.13 publicidad: anunciante, campania, campania_pais_interes, pieza_publicitaria y espacio_publicitario
-- ============================================================

PRINT '--- E-1.13.01 Alta de anunciantes, campañas, países de interés y piezas';
-- Resultado esperado: 7 anunciantes con una campaña cada uno (vigentes del 01/06 al 19/07/2026), con mercados
-- en 9 países y 12 piezas. El anunciante, la campaña, el país de interés y la pieza temporales se eliminan.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @anun INT, @camp INT, @pieza INT, @p INT, @p2 INT, @p3 INT;
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'pais_ARG'), @bra INT = (SELECT valor FROM #id WHERE clave = 'pais_BRA'),
        @ury INT = (SELECT valor FROM #id WHERE clave = 'pais_URY'), @usa INT = (SELECT valor FROM #id WHERE clave = 'pais_USA'),
        @can INT = (SELECT valor FROM #id WHERE clave = 'pais_CAN'), @mex INT = (SELECT valor FROM #id WHERE clave = 'pais_MEX'),
        @fra INT = (SELECT valor FROM #id WHERE clave = 'pais_FRA'), @deu INT = (SELECT valor FROM #id WHERE clave = 'pais_DEU'),
        @jpn INT = (SELECT valor FROM #id WHERE clave = 'pais_JPN'), @esp INT = (SELECT valor FROM #id WHERE clave = 'pais_ESP')

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
INSERT INTO #id VALUES ('pieza_CAN', @pieza);

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

SELECT a.nombre AS anunciante, c.nombre AS campania, c.fecha_inicio, c.fecha_fin,
       (SELECT STRING_AGG(p.codigo_iso, ', ') FROM publicidad.campania_pais_interes i JOIN torneo.pais p ON p.pais_id = i.pais_id
        WHERE i.campania_id = c.campania_id) AS paises_interes,
       (SELECT STRING_AGG(p.codigo_iso + ' ' + pz.idioma + ' ' + CAST(pz.costo_tarifa AS VARCHAR(12)), ' | ')
        FROM publicidad.pieza_publicitaria pz JOIN torneo.pais p ON p.pais_id = pz.pais_mercado_id
        WHERE pz.campania_id = c.campania_id) AS piezas
FROM publicidad.anunciante a JOIN publicidad.campania c ON c.anunciante_id = a.anunciante_id ORDER BY a.anunciante_id;
INSERT INTO #resultado SELECT 'E-1.13.01', 'anunciante, campania, pais_interes y pieza: alta, modificación y baja',
       IIF((SELECT COUNT(*) FROM publicidad.anunciante) = 7 AND (SELECT COUNT(*) FROM publicidad.campania) = 7
           AND (SELECT COUNT(*) FROM publicidad.campania_pais_interes) = 14 AND (SELECT COUNT(*) FROM publicidad.pieza_publicitaria) = 12
           AND (SELECT COUNT(DISTINCT pais_id) FROM publicidad.campania_pais_interes) = 9
           AND EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria WHERE costo_tarifa = 35000 AND idioma = 'espanol'), 'OK', 'FALLO'), '';
EXEC #informar 'E-1.13.01';
GO

PRINT '--- E-1.13.02 ABM de espacio publicitario (de a uno)';
-- Resultado esperado: en P3 se crea el espacio 1 vacío, se le asigna la pieza de Maple Air y se elimina.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @pieza INT = (SELECT valor FROM #id WHERE clave = 'pieza_CAN'), @esp INT, @ok INT;
EXEC publicidad.espacio_publicitario_insertar @p3, 1, NULL, NULL, @esp OUTPUT;
EXEC publicidad.espacio_publicitario_modificar @esp, @pieza, 4;
SELECT espacio_id, partido_id, numero_espacio, pieza_id, orden_prioridad, fecha_exhibicion, facturado, monto_facturado FROM publicidad.espacio_publicitario;
SELECT @ok = COUNT(*) FROM publicidad.espacio_publicitario WHERE espacio_id = @esp AND pieza_id = @pieza AND orden_prioridad = 4;
EXEC publicidad.espacio_publicitario_eliminar @esp;
INSERT INTO #resultado SELECT 'E-1.13.02', 'espacio_publicitario: alta, modificación y baja', IIF(@ok = 1 AND COUNT(*) = 0, 'OK', 'FALLO'), ''
FROM publicidad.espacio_publicitario;
EXEC #informar 'E-1.13.02';
GO

PRINT '################ PARTE 2: PROCEDIMIENTOS DE LÓGICA DE NEGOCIO (escenario) ################';
GO

-- ============================================================
-- 2.1 plantel.reemplazar_convocado (baja + alta de último momento, en una transacción)
-- ============================================================

PRINT '--- E-2.1.01 Reemplazo por lesión';
-- Resultado esperado: el jugador 26 de ARG queda con fecha y motivo de baja; el 27 entra con el mismo dorsal (99)
-- y motivo de alta "Reemplaza a Jugador 26: ...". Argentina sigue con 26 convocados vigentes.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'),
        @sale INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 26'),
        @entra INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27');
EXEC plantel.reemplazar_convocado @arg, @sale, @entra, '2026-06-14', 'Lesión muscular en el entrenamiento';
SELECT j.apellido, c.dorsal, c.fecha_alta, c.motivo_alta, c.fecha_baja, c.motivo_baja
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND j.jugador_id IN (@sale, @entra) ORDER BY c.convocatoria_id;
INSERT INTO #resultado SELECT 'E-2.1.01', 'reemplazar_convocado: baja y alta en la misma transacción',
       IIF(SUM(CASE WHEN fecha_baja IS NULL THEN 1 ELSE 0 END) = 26
           AND SUM(CASE WHEN jugador_id = @sale AND fecha_baja = '2026-06-14' AND motivo_baja IS NOT NULL THEN 1 ELSE 0 END) = 1
           AND SUM(CASE WHEN jugador_id = @entra AND fecha_baja IS NULL AND dorsal = 99 THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM plantel.convocatoria WHERE seleccion_id = @arg;
EXEC #informar 'E-2.1.01';
GO

-- ============================================================
-- 2.2 plantel.cargar_formacion (cabecera + titulares + banco, todo o nada)
-- ============================================================

PRINT '--- E-2.2.01 Carga de las formaciones de P2 (Argentina vs México)';
-- Resultado esperado: 2 formaciones con 11 titulares y 12 suplentes cada una; el dorsal sale de la convocatoria.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'),
        @mex INT = (SELECT valor FROM #id WHERE clave = 'MEX'), @form INT;
DECLARE @local plantel.tt_formacion_jugador, @visitante plantel.tt_formacion_jugador;
INSERT INTO @local SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23;
INSERT INTO @visitante SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @mex AND c.fecha_baja IS NULL AND c.dorsal <= 23;
EXEC plantel.cargar_formacion @p2, 'local', '4-4-2', @local, @form OUTPUT;         INSERT INTO #id VALUES ('P2_local', @form);
EXEC plantel.cargar_formacion @p2, 'visitante', '5-3-2', @visitante, @form OUTPUT; INSERT INTO #id VALUES ('P2_visitante', @form);
SELECT f.formacion_id, f.condicion, f.esquema_tactico, SUM(CAST(fj.titular AS INT)) AS titulares, SUM(1 - CAST(fj.titular AS INT)) AS suplentes,
       MIN(fj.dorsal) AS dorsal_min, MAX(fj.dorsal) AS dorsal_max
FROM plantel.formacion f JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id
WHERE f.partido_id = @p2 GROUP BY f.formacion_id, f.condicion, f.esquema_tactico;
INSERT INTO #resultado SELECT 'E-2.2.01', 'cargar_formacion: 11 titulares y 12 suplentes por equipo',
       IIF(COUNT(*) = 46 AND SUM(CAST(fj.titular AS INT)) = 22, 'OK', 'FALLO'), ''
FROM plantel.formacion f JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.partido_id = @p2;
EXEC #informar 'E-2.2.01';
GO

-- ============================================================
-- 2.3 evento.registrar_sustitucion (por dorsales; ventana automática; reglamento de cambios)
-- ============================================================

PRINT '--- E-2.3.01 CASO OBLIGATORIO: cambio por lesión dentro de los primeros 20 minutos';
-- Resultado esperado: Francia (visitante de P1) cambia al 3 por el 13 en el minuto 15 del PT, motivo lesión, ventana 1.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @form INT = (SELECT valor FROM #id WHERE clave = 'P1_visitante');
EXEC evento.registrar_sustitucion @p1, 'visitante', 3, 13, 15, 'PT', 'lesion';
SELECT s.minuto, s.periodo, s.numero_ventana, s.motivo, sale.dorsal AS dorsal_sale, entra.dorsal AS dorsal_entra
FROM evento.sustitucion s
JOIN plantel.formacion_jugador sale  ON sale.formacion_id = s.formacion_id AND sale.jugador_id = s.jugador_sale_id
JOIN plantel.formacion_jugador entra ON entra.formacion_id = s.formacion_id AND entra.jugador_id = s.jugador_entra_id
WHERE s.formacion_id = @form;
INSERT INTO #resultado SELECT 'E-2.3.01', 'OBLIGATORIO: cambio por lesión antes del minuto 20',
       IIF(COUNT(*) = 1 AND MAX(minuto) = 15 AND MAX(motivo) = 'lesion' AND MAX(numero_ventana) = 1, 'OK', 'FALLO'), ''
FROM evento.sustitucion WHERE formacion_id = @form;
EXEC #informar 'E-2.3.01';
GO

PRINT '--- E-2.3.02 Ventanas automáticas y máximo de cambios';
-- Resultado esperado: dos cambios en el minuto 46 comparten la ventana 2; el del minuto 70 abre la ventana 3.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @form INT = (SELECT valor FROM #id WHERE clave = 'P1_visitante');
EXEC evento.registrar_sustitucion @p1, 'visitante', 7, 14, 46, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p1, 'visitante', 8, 15, 46, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p1, 'visitante', 9, 16, 70, 'ST', 'precaucion';
EXEC evento.registrar_sustitucion @p1, 'visitante', 10, 17, 70, 'ST', 'tactico';
SELECT s.numero_ventana, s.minuto, s.periodo, s.motivo, sale.dorsal AS dorsal_sale, entra.dorsal AS dorsal_entra
FROM evento.sustitucion s
JOIN plantel.formacion_jugador sale  ON sale.formacion_id = s.formacion_id AND sale.jugador_id = s.jugador_sale_id
JOIN plantel.formacion_jugador entra ON entra.formacion_id = s.formacion_id AND entra.jugador_id = s.jugador_entra_id
WHERE s.formacion_id = @form ORDER BY s.numero_ventana, sale.dorsal;
INSERT INTO #resultado SELECT 'E-2.3.02', 'registrar_sustitucion: 5 cambios en 3 ventanas',
       IIF(COUNT(*) = 5 AND COUNT(DISTINCT numero_ventana) = 3 AND SUM(CASE WHEN numero_ventana = 2 THEN 1 ELSE 0 END) = 2, 'OK', 'FALLO'), ''
FROM evento.sustitucion WHERE formacion_id = @form;
EXEC #informar 'E-2.3.02';
GO

-- ============================================================
-- 2.4 evento.registrar_gol (por dorsales; actualiza el marcador)
-- ============================================================

PRINT '--- E-2.4.01 Goles de P1';
-- Resultado esperado: empata Francia (gol del 9 con asistencia del 14, que ingresó en el minuto 46) y desnivela
-- Argentina de penal (el 10). Marcador de P1: 2 a 1.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
EXEC evento.registrar_gol @p1, 'visitante', 9, 55, 'jugada', 'ST', 14;
EXEC evento.registrar_gol @p1, 'local', 10, 88, 'penal', 'ST';
SELECT f.condicion, fj.dorsal AS autor, a.dorsal AS asistente, g.minuto, g.periodo, g.tipo_gol
FROM evento.gol g JOIN plantel.formacion f ON f.formacion_id = g.formacion_id
JOIN plantel.formacion_jugador fj ON fj.formacion_id = g.formacion_id AND fj.jugador_id = g.jugador_id
LEFT JOIN plantel.formacion_jugador a ON a.formacion_id = g.formacion_id AND a.jugador_id = g.asistencia_jugador_id
WHERE f.partido_id = @p1 ORDER BY g.minuto;
SELECT partido_id, goles_local, goles_visitante, estado FROM torneo.partido WHERE partido_id = @p1;
INSERT INTO #resultado SELECT 'E-2.4.01', 'registrar_gol: marcador 2-1', IIF(goles_local = 2 AND goles_visitante = 1, 'OK', 'FALLO'), ''
FROM torneo.partido WHERE partido_id = @p1;
EXEC #informar 'E-2.4.01';
GO

-- ============================================================
-- 2.5 evento.registrar_tarjeta (tarjeta + cálculo de suspensión en una transacción)
-- ============================================================

PRINT '--- E-2.5.01 Primera amarilla: todavía no hay suspensión';
-- Resultado esperado: amarilla al 5 de Argentina en P1; lleva 1 de las 2 del criterio general => 0 suspensiones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 40, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Mano intencional',
     @condicion = 'local', @dorsal = 5, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT tarjeta_id, partido_id, persona_id, minuto, periodo, tipo, motivo FROM evento.tarjeta WHERE tarjeta_id = @tarjeta;
INSERT INTO #resultado VALUES ('E-2.5.01', 'registrar_tarjeta: primera amarilla sin suspensión',
       IIF(@susp = 0 AND NOT EXISTS (SELECT 1 FROM evento.suspension WHERE tarjeta_id = @tarjeta), 'OK', 'FALLO'), '');
EXEC #informar 'E-2.5.01';
GO

PRINT '--- E-2.5.02 CASO OBLIGATORIO: roja directa';
-- Resultado esperado: roja directa al 4 de Francia en P1 => 1 suspensión sin criterio (no es por acumulación)
-- para el próximo partido programado de Francia: P4.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 75, @periodo = 'ST', @tipo = 'roja', @motivo = 'Agresión a un rival',
     @condicion = 'visitante', @dorsal = 4, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT t.tarjeta_id, t.tipo, t.tipo_expulsion, t.minuto, s.suspension_id, s.criterio_id, s.partido_afectado_id, s.motivo
FROM evento.tarjeta t LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id WHERE t.tarjeta_id = @tarjeta;
INSERT INTO #resultado SELECT 'E-2.5.02', 'OBLIGATORIO: roja directa con suspensión para el próximo partido',
       IIF(@susp = 1 AND COUNT(*) = 1 AND SUM(CASE WHEN partido_afectado_id = @p4 AND criterio_id IS NULL THEN 1 ELSE 0 END) = 1
           AND (SELECT tipo_expulsion FROM evento.tarjeta WHERE tarjeta_id = @tarjeta) = 'roja_directa', 'OK', 'FALLO'), ''
FROM evento.suspension WHERE tarjeta_id = @tarjeta;
EXEC #informar 'E-2.5.02';
GO

PRINT '--- E-2.5.03 Tarjeta a un integrante del cuerpo técnico';
-- Resultado esperado: amarilla al DT de Francia (identificado por persona_id). Le aplica el criterio específico de
-- cuerpo técnico (3 amarillas), no el general (2) => 0 suspensiones.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @dt INT = (SELECT valor FROM #id WHERE clave = 'persona_DT_FRA'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 76, @periodo = 'ST', @tipo = 'amarilla', @motivo = 'Protesta',
     @persona_id = @dt, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT t.tarjeta_id, pe.tipo_persona, ct.apellido, t.tipo, t.minuto
FROM evento.tarjeta t JOIN plantel.persona pe ON pe.persona_id = t.persona_id JOIN plantel.cuerpo_tecnico ct ON ct.persona_id = t.persona_id
WHERE t.tarjeta_id = @tarjeta;
INSERT INTO #resultado VALUES ('E-2.5.03', 'registrar_tarjeta: cuerpo técnico', IIF(@tarjeta IS NOT NULL AND @susp = 0, 'OK', 'FALLO'), '');
EXEC #informar 'E-2.5.03';
GO

-- ============================================================
-- 2.6 publicidad.asignar_espacios_partido (los cuatro espacios según los criterios de la sección H)
-- ============================================================

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
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
EXEC publicidad.asignar_espacios_partido @p1;
SELECT e.numero_espacio, a.nombre AS anunciante, m.nombre AS mercado, e.orden_prioridad, pz.costo_tarifa, e.fecha_exhibicion, e.facturado
FROM publicidad.espacio_publicitario e
JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id JOIN publicidad.campania c ON c.campania_id = pz.campania_id
JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id JOIN torneo.pais m ON m.pais_id = pz.pais_mercado_id
WHERE e.partido_id = @p1 ORDER BY e.numero_espacio;
INSERT INTO #resultado SELECT 'E-2.6.01', 'OBLIGATORIO: priorización de 4 piezas con más de 4 mercados en prime time',
       IIF(COUNT(*) = 4
           AND SUM(CASE WHEN (e.numero_espacio = 1 AND a.nombre = 'Mate Pampa')
                          OR (e.numero_espacio = 2 AND a.nombre = 'Banque Lumière')
                          OR (e.numero_espacio = 3 AND a.nombre = 'NorthStar Motors')
                          OR (e.numero_espacio = 4 AND a.nombre = 'Sakura Tech') THEN 1 ELSE 0 END) = 4, 'OK', 'FALLO'), ''
FROM publicidad.espacio_publicitario e
JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id JOIN publicidad.campania c ON c.campania_id = pz.campania_id
JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id
WHERE e.partido_id = @p1;
EXEC #informar 'E-2.6.01';
GO

PRINT '--- E-2.6.02 Reasignación y rechazos';
-- Resultado esperado: (1) rechazo (50002): P1 ya tiene espacios asignados. (2) con @reemplazar = 1 se recalcula y
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
EXEC publicidad.asignar_espacios_partido @p1, @reemplazar = 1, @mostrar_detalle = 0;
INSERT INTO #resultado SELECT 'E-2.6.02', 'asignar_espacios_partido: reemplazo', IIF(COUNT(*) = 4 AND COUNT(pieza_id) = 4, 'OK', 'FALLO'), ''
FROM publicidad.espacio_publicitario WHERE partido_id = @p1;
EXEC #informar 'E-2.6.02';
GO

-- ============================================================
-- 2.7 torneo.registrar_resultado (cierre del partido + pauta exhibida) y facturación
-- ============================================================

PRINT '--- E-2.7.01 Cierre de P1 y facturación de su pauta';
-- Resultado esperado: P1 queda 'finalizado' 2 a 1 (tomado del detalle de goles) con 80000 espectadores; sus 4 espacios
-- quedan con fecha de exhibición. Al facturar, cada espacio guarda la tarifa de su pieza: total 360000.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @total NUMERIC(14,2);
EXEC torneo.registrar_resultado @partido_id = @p1, @asistencia_publico = 80000;
SELECT partido_id, estado, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p1;
INSERT INTO #resultado SELECT 'E-2.7.01', 'registrar_resultado: finalizado 2-1 y pauta exhibida',
       IIF(p.estado = 'finalizado' AND p.goles_local = 2 AND p.goles_visitante = 1 AND p.asistencia_publico = 80000
           AND (SELECT COUNT(*) FROM publicidad.espacio_publicitario e WHERE e.partido_id = p.partido_id AND e.fecha_exhibicion = p.fecha_hora_utc) = 4, 'OK', 'FALLO'), ''
FROM torneo.partido p WHERE p.partido_id = @p1;
EXEC publicidad.facturar_espacios_partido @p1, @total OUTPUT;
SELECT numero_espacio, pieza_id, orden_prioridad, fecha_exhibicion, facturado, monto_facturado FROM publicidad.espacio_publicitario WHERE partido_id = @p1 ORDER BY numero_espacio;
PRINT 'Total facturado de P1: ' + CAST(@total AS VARCHAR(20));
INSERT INTO #resultado VALUES ('E-2.7.01', 'facturar_espacios_partido: total 360000', IIF(@total = 360000, 'OK', 'FALLO'), CAST(@total AS VARCHAR(20)));
EXEC #informar 'E-2.7.01';
GO

-- ============================================================
-- 2.8 Acumulación de amarillas, doble amarilla y jugador suspendido fuera de la formación
-- ============================================================

PRINT '--- E-2.8.01 CASO OBLIGATORIO: suspensión por acumulación de amarillas';
-- Resultado esperado: el 5 de Argentina recibe en P2 su segunda amarilla en partidos distintos (P1 y P2) => 1 suspensión
-- con el criterio general, para el próximo partido de Argentina: P3.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'),
        @criterio INT = (SELECT valor FROM #id WHERE clave = 'criterio_general'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 20, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Falta táctica',
     @condicion = 'local', @dorsal = 5, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT j.apellido, t.partido_id, t.minuto, t.tipo, s.suspension_id, s.criterio_id, s.partido_afectado_id, s.motivo
FROM evento.tarjeta t JOIN plantel.jugador j ON j.persona_id = t.persona_id LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id
WHERE j.nombre = 'ARG' AND j.apellido = 'Jugador 05' ORDER BY t.tarjeta_id;
INSERT INTO #resultado SELECT 'E-2.8.01', 'OBLIGATORIO: suspensión por acumulación de amarillas',
       IIF(@susp = 1 AND COUNT(*) = 1 AND SUM(CASE WHEN partido_afectado_id = @p3 AND criterio_id = @criterio THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM evento.suspension WHERE tarjeta_id = @tarjeta;
EXEC #informar 'E-2.8.01';
GO

PRINT '--- E-2.8.02 CASO OBLIGATORIO: expulsión por doble amonestación';
-- Resultado esperado: el 8 de México recibe dos amarillas en P2; la segunda se registra sola como roja por doble amarilla
-- y genera 1 suspensión. México no tiene otro partido programado: queda con partido NULL ("a definir").
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 30, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Juego brusco',
     @condicion = 'visitante', @dorsal = 8;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 60, @periodo = 'ST', @tipo = 'amarilla', @motivo = 'Reiteración de faltas',
     @condicion = 'visitante', @dorsal = 8, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT j.apellido, t.minuto, t.periodo, t.tipo, t.tipo_expulsion, s.criterio_id, s.partido_afectado_id, s.motivo
FROM evento.tarjeta t JOIN plantel.jugador j ON j.persona_id = t.persona_id LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id
WHERE j.nombre = 'MEX' AND j.apellido = 'Jugador 08' ORDER BY t.tarjeta_id;
INSERT INTO #resultado SELECT 'E-2.8.02', 'OBLIGATORIO: expulsión por doble amarilla',
       IIF(@susp = 1 AND t.tipo = 'roja' AND t.tipo_expulsion = 'doble_amarilla'
           AND (SELECT COUNT(*) FROM evento.suspension s WHERE s.tarjeta_id = t.tarjeta_id AND s.partido_afectado_id IS NULL AND s.criterio_id IS NULL) = 1, 'OK', 'FALLO'), ''
FROM evento.tarjeta t WHERE t.tarjeta_id = @tarjeta;
EXEC #informar 'E-2.8.02';
GO

PRINT '--- E-2.8.03 Cierre de P2 sin goles (resultado tomado del detalle: 0 a 0)';
-- Resultado esperado: P2 finalizado 0 a 0 sin informar goles.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2');
EXEC torneo.registrar_resultado @partido_id = @p2, @asistencia_publico = 83000;
SELECT partido_id, estado, goles_local, goles_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p2;
INSERT INTO #resultado SELECT 'E-2.8.03', 'registrar_resultado: 0-0 desde el detalle',
       IIF(estado = 'finalizado' AND goles_local = 0 AND goles_visitante = 0, 'OK', 'FALLO'), '' FROM torneo.partido WHERE partido_id = @p2;
EXEC #informar 'E-2.8.03';
GO

PRINT '--- E-2.8.04 CASO OBLIGATORIO: el suspendido queda afuera de la formación del siguiente partido';
-- (3) la misma formación con el 12 en lugar del 5 se carga bien.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'), @form INT, @j5 INT;
DECLARE @con5 plantel.tt_formacion_jugador, @sin5 plantel.tt_formacion_jugador;
INSERT INTO @con5 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23;
INSERT INTO @sin5 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 12, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23 AND c.dorsal <> 5;
SELECT @j5 = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @arg AND dorsal = 5 AND fecha_baja IS NULL;
EXEC plantel.cargar_formacion @p3, 'local', '4-3-3', @sin5, @form OUTPUT;
SELECT fj.dorsal, j.apellido, fj.posicion, fj.titular FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
WHERE fj.formacion_id = @form AND fj.titular = 1 ORDER BY fj.dorsal;
INSERT INTO #resultado SELECT 'E-2.8.04', 'OBLIGATORIO: formación sin el suspendido cargada',
       IIF(COUNT(*) = 22 AND SUM(CAST(titular AS INT)) = 11 AND SUM(CASE WHEN dorsal = 5 THEN 1 ELSE 0 END) = 0, 'OK', 'FALLO'), ''
FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC #informar 'E-2.8.04';
GO

-- ============================================================
-- 2.9 arbitraje.designar_arbitros (terna completa, con validación de conflicto de nacionalidad)
-- ============================================================

PRINT '--- E-2.9.01 Designación válida en fase de grupos y con advertencia en eliminación directa';
-- Resultado esperado: P3 queda con sus 5 roles y sin advertencia (fase de grupos). P4 (dieciseisavos, Francia vs Japón)
-- queda con sus 5 roles y devuelve una ADVERTENCIA por César Ramos (México) y Wilton Sampaio (Brasil): sus países tienen
-- selección en competencia. No es un bloqueo.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'),
        @ury1 INT = (SELECT valor FROM #id WHERE clave = 'arb_URY1'), @ury2 INT = (SELECT valor FROM #id WHERE clave = 'arb_URY2'),
        @deu1 INT = (SELECT valor FROM #id WHERE clave = 'arb_DEU1'), @deu2 INT = (SELECT valor FROM #id WHERE clave = 'arb_DEU2'),
        @usa INT = (SELECT valor FROM #id WHERE clave = 'arb_USA'), @can INT = (SELECT valor FROM #id WHERE clave = 'arb_CAN'),
        @mex INT = (SELECT valor FROM #id WHERE clave = 'arb_MEX'), @bra INT = (SELECT valor FROM #id WHERE clave = 'arb_BRA'),
        @adv3 VARCHAR(1000), @adv4 VARCHAR(1000);
EXEC arbitraje.designar_arbitros @p3, @ury1, @ury2, @deu2, @usa, @deu1, @adv3 OUTPUT;
EXEC arbitraje.designar_arbitros @p4, @deu1, @deu2, @can, @mex, @bra, @adv4 OUTPUT;
SELECT d.partido_id, d.rol, a.nombre + ' ' + a.apellido AS arbitro, p.codigo_iso AS pais
FROM arbitraje.designacion_arbitral d JOIN arbitraje.arbitro a ON a.arbitro_id = d.arbitro_id JOIN torneo.pais p ON p.pais_id = a.pais_id
ORDER BY d.partido_id, d.designacion_id;
INSERT INTO #resultado VALUES ('E-2.9.01', 'designar_arbitros: terna completa sin advertencia en grupos',
       IIF(@adv3 IS NULL AND (SELECT COUNT(*) FROM arbitraje.designacion_arbitral WHERE partido_id = @p3) = 5, 'OK', 'FALLO'), ISNULL(@adv3, ''));
INSERT INTO #resultado VALUES ('E-2.9.01', 'designar_arbitros: advertencia desde dieciseisavos (no bloquea)',
       IIF(@adv4 LIKE 'ADVERTENCIA%' AND @adv4 LIKE '%Ramos%' AND @adv4 LIKE '%Sampaio%' AND (SELECT COUNT(*) FROM arbitraje.designacion_arbitral WHERE partido_id = @p4) = 5, 'OK', 'FALLO'), ISNULL(@adv4, ''));
EXEC #informar 'E-2.9.01';
GO

-- ============================================================
-- 2.10 Partido de eliminación directa completo (P4: Francia vs Japón, dieciseisavos)
-- ============================================================

PRINT '--- E-2.10.01 Formaciones de P4: el expulsado por roja directa en P1 no puede jugar';
-- sin el 4 se carga bien. La de Japón se carga completa.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'), @fra INT = (SELECT valor FROM #id WHERE clave = 'FRA'),
        @jpn INT = (SELECT valor FROM #id WHERE clave = 'JPN'), @form INT;
DECLARE @con4 plantel.tt_formacion_jugador, @sin4 plantel.tt_formacion_jugador, @japon plantel.tt_formacion_jugador;
INSERT INTO @con4 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL;
INSERT INTO @sin4 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 12, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL AND c.dorsal <> 4;
INSERT INTO @japon SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @jpn AND c.fecha_baja IS NULL;
EXEC plantel.cargar_formacion @p4, 'local', '4-2-3-1', @sin4, @form OUTPUT;   INSERT INTO #id VALUES ('P4_local', @form);
EXEC plantel.cargar_formacion @p4, 'visitante', '3-4-3', @japon, @form OUTPUT; INSERT INTO #id VALUES ('P4_visitante', @form);
INSERT INTO #resultado SELECT 'E-2.10.01', 'cargar_formacion: formaciones de P4', IIF(COUNT(*) = 45, 'OK', 'FALLO'), ''
FROM plantel.formacion f JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.partido_id = @p4;
EXEC #informar 'E-2.10.01';
GO

PRINT '--- E-2.10.02 Cambio adicional del tiempo suplementario';
-- Resultado esperado: Japón hace 5 cambios en 3 ventanas del ST. El 6.º en el ST se rechaza con 2 condiciones (máximo de
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'), @form INT = (SELECT valor FROM #id WHERE clave = 'P4_visitante');
EXEC evento.registrar_sustitucion @p4, 'visitante', 2, 12, 50, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 3, 13, 50, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 4, 14, 65, 'ST', 'lesion';
EXEC evento.registrar_sustitucion @p4, 'visitante', 5, 15, 65, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 6, 16, 80, 'ST', 'precaucion';
EXEC evento.registrar_sustitucion @p4, 'visitante', 7, 17, 95, 'alargue_1', 'tactico';
SELECT numero_ventana, periodo, minuto, COUNT(*) AS cambios FROM evento.sustitucion WHERE formacion_id = @form
GROUP BY numero_ventana, periodo, minuto ORDER BY numero_ventana;
INSERT INTO #resultado SELECT 'E-2.10.02', 'registrar_sustitucion: cambio adicional en el alargue (6 cambios, 4 ventanas)',
       IIF(COUNT(*) = 6 AND MAX(numero_ventana) = 4 AND SUM(CASE WHEN periodo = 'alargue_1' THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM evento.sustitucion WHERE formacion_id = @form;
EXEC #informar 'E-2.10.02';
GO

PRINT '--- E-2.10.03 Empate, definición por penales y cierre';
-- Con la tanda registrada (Francia 2, Japón 1) se cierra: goles 1-1, penales 2-1. Los goles de la tanda no suman al marcador.
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4');
EXEC evento.registrar_gol @p4, 'local', 9, 30, 'tiro_libre', 'PT';
EXEC evento.registrar_gol @p4, 'visitante', 10, 77, 'jugada', 'ST', 12;
EXEC evento.registrar_gol @p4, 'local', 9, 120, 'penal', 'penales';
EXEC evento.registrar_gol @p4, 'visitante', 10, 120, 'penal', 'penales';
EXEC evento.registrar_gol @p4, 'local', 10, 120, 'penal', 'penales';
EXEC torneo.registrar_resultado @partido_id = @p4, @asistencia_publico = 70000;
SELECT partido_id, fase, estado, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p4;
INSERT INTO #resultado SELECT 'E-2.10.03', 'registrar_resultado: 1-1 con penales 2-1',
       IIF(estado = 'finalizado' AND goles_local = 1 AND goles_visitante = 1 AND penales_local = 2 AND penales_visitante = 1, 'OK', 'FALLO'), ''
FROM torneo.partido WHERE partido_id = @p4;
EXEC #informar 'E-2.10.03';
GO

PRINT '--- E-2.10.04 Resultado sin detalle (como llegaría de una importación) y sus validaciones';
-- Resultado esperado: se programa un partido de grupos sin formaciones (México vs Japón). Cerrarlo sin informar goles se
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @mx INT = (SELECT valor FROM #id WHERE clave = 'sede_MX'), @mex INT = (SELECT valor FROM #id WHERE clave = 'MEX'),
        @jpn INT = (SELECT valor FROM #id WHERE clave = 'JPN'), @p5 INT;
EXEC torneo.partido_insertar @mx, '2026-06-25T18:00:00-06:00', 'grupos', @mex, @jpn, NULL, @p5 OUTPUT;
EXEC torneo.registrar_resultado @p5, 2, 0, NULL, NULL, 60000;
SELECT partido_id, fase, estado, goles_local, goles_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p5;
INSERT INTO #resultado SELECT 'E-2.10.04', 'registrar_resultado: resultado informado sin detalle',
       IIF(estado = 'finalizado' AND goles_local = 2 AND goles_visitante = 0, 'OK', 'FALLO'), '' FROM torneo.partido WHERE partido_id = @p5;
EXEC #informar 'E-2.10.04';
GO

-- ============================================================
-- 2.11 Transaccionalidad: todo o nada en operaciones que afectan varias tablas
-- ============================================================

PRINT '--- E-2.11.01 Una operación multi-tabla se deshace completa';
-- Una roja genera 1 tarjeta (evento.tarjeta) y 1 suspensión (evento.suspension). Se la ejecuta dentro de una
-- transacción abierta por quien llama y se hace ROLLBACK.
-- Resultado esperado: dentro de la transacción hay +1 tarjeta y +1 suspensión; después del ROLLBACK no queda
-- ninguna de las dos (el SP no confirma por su cuenta lo que no abrió).
-- Requiere: Lote 0 y todos los lotes anteriores de las Partes 1 y 2 (escenario encadenado: va en su lugar de la secuencia).
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @t0 INT = (SELECT COUNT(*) FROM evento.tarjeta),
        @s0 INT = (SELECT COUNT(*) FROM evento.suspension), @t1 INT, @s1 INT;
BEGIN TRANSACTION;
    EXEC evento.registrar_tarjeta @partido_id = @p3, @minuto = 10, @periodo = 'PT', @tipo = 'roja', @motivo = 'Prueba de rollback',
         @condicion = 'local', @dorsal = 7;
    SELECT @t1 = COUNT(*) FROM evento.tarjeta;
    SELECT @s1 = COUNT(*) FROM evento.suspension;
ROLLBACK TRANSACTION;
SELECT @t0 AS tarjetas_antes, @t1 AS tarjetas_durante, (SELECT COUNT(*) FROM evento.tarjeta) AS tarjetas_despues,
       @s0 AS suspensiones_antes, @s1 AS suspensiones_durante, (SELECT COUNT(*) FROM evento.suspension) AS suspensiones_despues;
INSERT INTO #resultado VALUES ('E-2.11.01', 'transacción: tarjeta + suspensión se deshacen juntas',
       IIF(@t1 = @t0 + 1 AND @s1 = @s0 + 1 AND (SELECT COUNT(*) FROM evento.tarjeta) = @t0
           AND (SELECT COUNT(*) FROM evento.suspension) = @s0, 'OK', 'FALLO'), '');
EXEC #informar 'E-2.11.01';
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

PRINT '--- P-3.09 Preparación de plantel.persona_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
IF OBJECT_ID('tempdb..##test_persona') IS NULL
    CREATE TABLE ##test_persona (persona_id INT NOT NULL PRIMARY KEY, clave VARCHAR(10) NOT NULL);
DECLARE @id INT;
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'mod');      -- persona a modificar (sin registros asociados)
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'elim');     -- baja valida (tipo jugador, sin registros)
EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'elim_ct'); -- baja valida (tipo cuerpo_tecnico, sin registros)
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'jug');      -- registrada en plantel.jugador
EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'ct');      -- registrada en plantel.cuerpo_tecnico
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'tarj');     -- con tarjetas
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'todo');     -- jugador + cuerpo tecnico + tarjetas
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

PRINT '--- P-3.11 Preparación de plantel.formacion_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes la preparación de plantel.cuerpo_tecnico_* (selecciones ZCA/ZCB/ZCC, todas del grupo 'A') y al menos una sede en torneo.sede.
IF OBJECT_ID('tempdb..##test_formacion') IS NULL
    CREATE TABLE ##test_formacion (clave VARCHAR(10) NOT NULL PRIMARY KEY, partido_id INT NOT NULL, formacion_id INT NULL);
GO
IF EXISTS (SELECT 1 FROM ##test_formacion)
    THROW 50000, 'La preparación de plantel.formacion_* ya fue ejecutada en esta sesión (ver ##test_formacion).', 1;
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
INSERT INTO ##test_formacion (clave, partido_id) VALUES ('ins_a', @pa), ('ins_b', @pb), ('ins_c', @pc);
EXEC plantel.formacion_insertar @pm, 'local',     '4-4-2', @f OUTPUT; INSERT INTO ##test_formacion VALUES ('mod',   @pm, @f);  -- a modificar / ya tiene formacion local
EXEC plantel.formacion_insertar @pm, 'visitante', '4-3-3', @f OUTPUT; INSERT INTO ##test_formacion VALUES ('jug',   @pm, @f);  -- ZCA, reservada para formacion_jugador (con jugadores)
EXEC plantel.formacion_insertar @pe, 'local',     '4-4-2', @f OUTPUT; INSERT INTO ##test_formacion VALUES ('elim',  @pe, @f);  -- baja valida
EXEC plantel.formacion_insertar @pe, 'visitante', '4-3-3', @f OUTPUT; INSERT INTO ##test_formacion VALUES ('elim2', @pe, @f);  -- baja valida
EXEC plantel.formacion_insertar @pf, 'local', '4-4-2', @f OUTPUT; INSERT INTO ##test_formacion VALUES ('fin', @pf, @f);
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pf;
GO

PRINT '--- P-3.12 Preparación de plantel.formacion_jugador_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes, en esta misma ventana: plantel.cuerpo_tecnico_* (ZCA/ZCB/ZCC), plantel.jugador_* (Test JU),
-- plantel.convocatoria_* ('Convocado' y 'Formacion' convocados en ZCA) y plantel.formacion_* (##test_formacion).
IF OBJECT_ID('tempdb..##test_formacion') IS NULL
    THROW 50000, 'Falta ##test_formacion: ejecutar antes la preparación de plantel.formacion_* en esta misma ventana.', 1;
IF NOT EXISTS (SELECT 1 FROM ##test_formacion WHERE clave = 'jug')
    THROW 50000, 'Falta la formación jug en ##test_formacion: ejecutar antes la preparación de plantel.formacion_*.', 1;

IF OBJECT_ID('tempdb..##test_fjugador') IS NULL
    CREATE TABLE ##test_fjugador (clave VARCHAR(12) NOT NULL PRIMARY KEY, formacion_id INT NULL, jugador_id INT NOT NULL);
IF EXISTS (SELECT 1 FROM ##test_fjugador)
    THROW 50000, 'La preparación de plantel.formacion_jugador_* ya fue ejecutada en esta sesión (ver ##test_fjugador).', 1;

DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @fj INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug'),
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
SET @base = DATEADD(DAY, 3, (SELECT CAST(MAX(p.fecha_hora_local) AS DATETIME2) FROM torneo.partido p JOIN ##test_formacion t ON t.partido_id = p.partido_id));
SET @t = TODATETIMEOFFSET(@base, @min);                    EXEC torneo.partido_insertar @sede, @t, 'dieciseisavos', @s2, @s3, @partido_id = @pl OUTPUT;  -- ZCB local vs ZCC visitante
SET @t = TODATETIMEOFFSET(DATEADD(DAY, 3, @base), @min);   EXEC torneo.partido_insertar @sede, @t, 'dieciseisavos', @s1, @s2, @partido_id = @pf OUTPUT;  -- ZCA local vs ZCB (se finaliza al final)
SET @dia = (SELECT CAST(fecha_hora_utc AS DATE) FROM torneo.partido WHERE partido_id = @pl);  -- fecha que usa el SP para validar la convocatoria
EXEC plantel.formacion_insertar @pl, 'local',     '4-4-2', @fl OUTPUT;  -- ZCB
EXEC plantel.formacion_insertar @pl, 'visitante', '4-3-3', @fs OUTPUT;  -- ZCC
EXEC plantel.formacion_insertar @pf, 'local',     '4-4-2', @ff OUTPUT;  -- ZCA (partido a finalizar)
INSERT INTO ##test_formacion VALUES ('fl_tit', @pl, @fl), ('fl_sup', @pl, @fs), ('fj_fin', @pf, @ff);
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
INSERT INTO ##test_fjugador (clave, formacion_id, jugador_id)
SELECT n.clave, CASE n.destino WHEN 'jug' THEN @fj WHEN 'fl_tit' THEN @fl WHEN 'fl_sup' THEN @fs WHEN 'fj_fin' THEN @ff END, j.jugador_id
FROM @nuevos n JOIN plantel.jugador j ON j.nombre = 'Test JU' AND j.apellido = n.apellido;
INSERT INTO ##test_fjugador (clave, formacion_id, jugador_id)
SELECT 'base', @fj, jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Convocado';
INSERT INTO ##test_fjugador (clave, formacion_id, jugador_id)
SELECT 'ins', @fj, jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Formacion';
-- Formaciones
SET @j = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'base');
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
SET @j = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'q1');   -- stored 40 -> convocatoria pasa a 50
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 50, '2026-06-01', 'Convocatoria FJ', NULL, NULL;
SET @j = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'q2');   -- stored 41 -> convocatoria pasa a 51
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 51, '2026-06-01', 'Convocatoria FJ', NULL, NULL;
SET @j = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 's');    -- stored 43 -> convocatoria pasa a 52 (sincronizacion de dorsal en modificar)
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 52, '2026-06-01', 'Convocatoria FJ', NULL, NULL;
SET @j = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'r');    -- stored 42 -> convocatoria pasa a 41 (el que conserva q2 en la formacion)
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 41, '2026-06-01', 'Convocatoria FJ', NULL, NULL;
SET @j = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'p');    -- convocatoria nueva con el dorsal 40 (el que conserva q1 en la formacion)
EXEC plantel.convocatoria_insertar @s1, @j, 40, '2026-06-01', 'Convocatoria FJ', @c OUTPUT;
SET @j = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'z_baja');  -- queda en la formacion con la convocatoria dada de baja antes del partido
SET @c = (SELECT convocatoria_id FROM plantel.convocatoria WHERE seleccion_id = @s1 AND jugador_id = @j AND fecha_baja IS NULL);
EXEC plantel.convocatoria_modificar @c, 48, '2026-06-01', 'Convocatoria FJ', '2026-07-01', 'Baja FJ';
-- Partido finalizado: se carga primero (el SP rechaza partidos finalizados) y luego se finaliza
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pf;
GO

PRINT '--- P-3.13 Preparación de evento.sustitucion_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes, en esta misma ventana: plantel.cuerpo_tecnico_* (ZCA/ZCB/ZCC), plantel.jugador_*, plantel.convocatoria_*,
-- plantel.formacion_* (##test_formacion) y plantel.formacion_jugador_* (##test_fjugador).
-- No crea jugadores ni convocatorias nuevos: reutiliza los jugadores de ZCB y ZCC (convocados vigentes)
-- Parámetros necesarios en torneo.parametro: cambios_max_reglamentarios (>= 5), ventanas_max_reglamentarias (>= 2 y menor que cambios_max_reglamentarios),
IF OBJECT_ID('tempdb..##test_fjugador') IS NULL
    THROW 50000, 'Falta ##test_fjugador: ejecutar antes la preparación de plantel.formacion_jugador_* en esta misma ventana.', 1;
IF OBJECT_ID('tempdb..##test_sustitucion') IS NULL
    CREATE TABLE ##test_sustitucion (clave VARCHAR(12) NOT NULL PRIMARY KEY, formacion_id INT NULL, jugador_id INT NULL, sustitucion_id INT NULL);
GO
IF EXISTS (SELECT 1 FROM ##test_sustitucion)
    THROW 50000, 'La preparación de evento.sustitucion_* ya fue ejecutada en esta sesión (ver ##test_sustitucion).', 1;
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
IF OBJECT_ID('tempdb..##test_formacion') IS NULL OR NOT EXISTS (SELECT 1 FROM ##test_fjugador WHERE clave = 'sust_sale')
    THROW 50000, 'Faltan ##test_formacion/##test_fjugador completos: ejecutar antes las preparaciones de plantel.formacion_* y plantel.formacion_jugador_*.', 1;
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
                             JOIN ##test_fjugador t ON t.formacion_id = v.formacion_id));
IF @base IS NULL
    THROW 50000, 'No se pudo calcular la fecha base de los partidos (revisar ##test_fjugador).', 1;
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
INSERT INTO ##test_sustitucion (clave, formacion_id) VALUES
 ('f_ok', @f_ok), ('f_gen', @f_gen), ('f_eli', @f_eli), ('f_alg', @f_alg), ('f_lim', @f_lim), ('f_fin', @f_fin);
INSERT INTO ##test_sustitucion (clave, formacion_id, jugador_id) SELECT clave, formacion_id, jugador_id FROM @r;
INSERT INTO ##test_sustitucion (clave, formacion_id, jugador_id)
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
        SET @sale  = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = @pref + '_t' + CAST(@i AS VARCHAR(3)));
        SET @entra = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = @pref + '_s' + CAST(@i AS VARCHAR(3)));
        EXEC evento.sustitucion_insertar @fid, @sale, @entra, @mn, @per, @ven, @mot, @sid OUTPUT;
        INSERT INTO ##test_sustitucion (clave, formacion_id, sustitucion_id) VALUES (@pref + '_x' + CAST(@i AS VARCHAR(3)), @fid, @sid);
        SET @i += 1;
    END;
    SET @k += 1;
END;
SET @sale  = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'eli_t1');
SET @entra = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'eli_s1');
EXEC evento.sustitucion_insertar @f_eli, @sale, @entra, 25, 'PT', 1, 'tactico', @sid OUTPUT;
INSERT INTO ##test_sustitucion (clave, formacion_id, sustitucion_id) VALUES ('eli_x1', @f_eli, @sid);
SET @sale  = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'eli_t2');
SET @entra = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'eli_s2');
EXEC evento.sustitucion_insertar @f_eli, @sale, @entra, 60, 'ST', 2, 'lesion', @sid OUTPUT;
INSERT INTO ##test_sustitucion (clave, formacion_id, sustitucion_id) VALUES ('eli_x2', @f_eli, @sid);
SET @sale  = @entra;
SET @entra = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'eli_s3');
EXEC evento.sustitucion_insertar @f_eli, @sale, @entra, 80, 'ST', 2, 'precaucion', @sid OUTPUT;
INSERT INTO ##test_sustitucion (clave, formacion_id, sustitucion_id) VALUES ('eli_x3', @f_eli, @sid);  
    -- Partido finalizado: se carga primero (el SP rechaza partidos finalizados) y luego se finaliza
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @p5;
GO

PRINT '--- P-3.14 Preparación de evento.gol_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes, en esta misma ventana: plantel.cuerpo_tecnico_* (ZCA/ZCB/ZCC), plantel.jugador_*, plantel.convocatoria_*,
-- plantel.formacion_* (##test_formacion) y plantel.formacion_jugador_* (##test_fjugador).
-- Usa evento.sustitucion_insertar (para tener un suplente que ingresó), pero NO requiere la preparación de evento.sustitucion_*.
IF OBJECT_ID('tempdb..##test_fjugador') IS NULL OR OBJECT_ID('tempdb..##test_formacion') IS NULL
    THROW 50000, 'Faltan ##test_fjugador/##test_formacion: ejecutar antes las preparaciones de plantel.formacion_* y plantel.formacion_jugador_* en esta misma ventana.', 1;
IF OBJECT_ID('tempdb..##test_gol') IS NULL
    CREATE TABLE ##test_gol (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY,   -- FIX: misma collation que la base
                             partido_id INT NULL, formacion_id INT NULL, jugador_id INT NULL, gol_id INT NULL);
GO
IF EXISTS (SELECT 1 FROM ##test_gol)
    THROW 50000, 'La preparación de evento.gol_* ya fue ejecutada en esta sesión (ver ##test_gol).', 1;
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @sede INT = (SELECT TOP 1 sede_id FROM torneo.sede ORDER BY sede_id),
        @fj INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug'),
        @pm INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'jug'),
        @huso CHAR(6), @off INT, @base DATETIME2, @t DATETIMEOFFSET,
        @pf INT, @pz INT, @fl INT, @fv INT, @zl INT, @zv INT,
        @i INT, @n INT, @j INT, @fid INT, @tit BIT, @pos VARCHAR(30), @g INT, @sid INT,
        @sale INT, @entra INT, @aut INT, @asi INT, @min INT, @tg VARCHAR(15), @per VARCHAR(20), @cl VARCHAR(12);
IF @s1 IS NULL OR @s2 IS NULL OR @s3 IS NULL
    THROW 50000, 'Faltan las selecciones de prueba (ZCA/ZCB/ZCC): ejecutar antes la preparación de plantel.cuerpo_tecnico_*.', 1;
IF @sede IS NULL
    THROW 50000, 'No hay sedes en torneo.sede: cargar al menos una.', 1;
IF @fj IS NULL
    THROW 50000, 'Falta la formación jug en ##test_formacion: ejecutar antes la preparación de plantel.formacion_*.', 1;
IF (SELECT COUNT(*) FROM ##test_fjugador
    WHERE clave IN ('gol', 'asis', 'tit_1', 'tit_2', 'tit_3', 'tit_4', 'tit_5', 'tit_sup', 'lib_1', 'lib_3', 'sup_tit', 'sup_1', 'sup_2', 'sup_3')) < 14
    THROW 50000, 'Faltan jugadores en ##test_fjugador: ejecutar antes la preparación de plantel.formacion_jugador_*.', 1;
IF (SELECT COUNT(*) FROM plantel.formacion_jugador fj JOIN ##test_fjugador t ON t.jugador_id = fj.jugador_id
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
INSERT INTO ##test_gol (clave, partido_id, formacion_id) VALUES
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
    JOIN ##test_fjugador t ON t.clave COLLATE DATABASE_DEFAULT = p.fj_clave COLLATE DATABASE_DEFAULT   -- FIX
    WHERE p.n = @i;
    SET @pos = IIF(@tit = 1, 'Defensor', 'Mediocampista');
    EXEC plantel.formacion_jugador_insertar @fid, @j, @pos, @tit;
    SET @i += 1;
END;
INSERT INTO ##test_gol (clave, formacion_id, jugador_id)
SELECT p.clave, p.formacion_id, t.jugador_id
FROM @plantel p
JOIN ##test_fjugador t ON t.clave COLLATE DATABASE_DEFAULT = p.fj_clave COLLATE DATABASE_DEFAULT;   -- FIX
INSERT INTO ##test_gol (clave, formacion_id, jugador_id)
SELECT 'loc_fuera', NULL, jugador_id FROM ##test_fjugador WHERE clave = 'lib_3';       -- convocado en ZCB, no integra f_loc ni z_loc
INSERT INTO ##test_gol (clave, formacion_id, jugador_id)
SELECT 'jug_gol',  @fj, jugador_id FROM ##test_fjugador WHERE clave = 'gol';
INSERT INTO ##test_gol (clave, formacion_id, jugador_id)
SELECT 'jug_asis', @fj, jugador_id FROM ##test_fjugador WHERE clave = 'asis';
    -- Sustitución: loc_t5 sale, loc_s_in ingresa (para que el suplente pueda ser autor/asistente)
SET @sale  = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_t5');
SET @entra = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_s_in');
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
    JOIN ##test_gol f ON f.clave COLLATE DATABASE_DEFAULT = g.form  COLLATE DATABASE_DEFAULT          -- FIX
    JOIN ##test_gol a ON a.clave COLLATE DATABASE_DEFAULT = g.autor COLLATE DATABASE_DEFAULT          -- FIX
    LEFT JOIN ##test_gol s ON s.clave COLLATE DATABASE_DEFAULT = g.asist COLLATE DATABASE_DEFAULT     -- FIX
    WHERE g.n = @i;
    EXEC evento.gol_insertar @fid, @aut, @min, @tg, @per, @asi, @g OUTPUT;
    INSERT INTO ##test_gol (clave, formacion_id, gol_id) VALUES (@cl, @fid, @g);
    SET @i += 1;
END;
    -- Partido finalizado: se carga primero (el SP rechaza partidos finalizados) y luego se finaliza
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pz;
GO

PRINT '--- P-3.15 Preparación de evento.tarjeta_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere haber ejecutado antes, en esta misma ventana: plantel.cuerpo_tecnico_* (ZCA/ZCB/ZCC), plantel.jugador_*, plantel.convocatoria_*,
-- plantel.formacion_* (##test_formacion) y plantel.formacion_jugador_* (##test_fjugador). NO requiere las preparaciones de evento.sustitucion_* ni evento.gol_*.
IF OBJECT_ID('tempdb..##test_fjugador') IS NULL OR OBJECT_ID('tempdb..##test_formacion') IS NULL
    THROW 50000, 'Faltan ##test_fjugador/##test_formacion: ejecutar antes las preparaciones de plantel.formacion_* y plantel.formacion_jugador_* en esta misma ventana.', 1;
IF OBJECT_ID('tempdb..##test_tarjeta') IS NULL
    CREATE TABLE ##test_tarjeta (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY,
                                 partido_id INT NULL, formacion_id INT NULL, persona_id INT NULL, tarjeta_id INT NULL);
GO
IF EXISTS (SELECT 1 FROM ##test_tarjeta)
    THROW 50000, 'La preparación de evento.tarjeta_* ya fue ejecutada en esta sesión (ver ##test_tarjeta).', 1;
DECLARE @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @sede INT = (SELECT TOP 1 sede_id FROM torneo.sede ORDER BY sede_id),
        @pm INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'jug'),
        @fj INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug'),
        @huso CHAR(6), @off INT, @base DATETIME2, @t DATETIMEOFFSET,
        @pt INT, @pz INT, @fl INT, @fv INT, @zl INT,
        @i INT, @n INT, @j INT, @fid INT, @tit BIT, @pos VARCHAR(30), @x INT, @pe INT, @tid INT, @ap VARCHAR(100);
IF @s1 IS NULL OR @s2 IS NULL OR @s3 IS NULL
    THROW 50000, 'Faltan las selecciones de prueba (ZCA/ZCB/ZCC): ejecutar antes la preparación de plantel.cuerpo_tecnico_*.', 1;
IF @sede IS NULL
    THROW 50000, 'No hay sedes en torneo.sede: cargar al menos una.', 1;
IF @fj IS NULL
    THROW 50000, 'Falta la formación jug en ##test_formacion: ejecutar antes la preparación de plantel.formacion_*.', 1;
IF (SELECT COUNT(*) FROM ##test_fjugador
    WHERE clave IN ('tit_1', 'tit_2', 'tit_3', 'tit_4', 'tit_5', 'tit_6', 'tit_7', 'tit_8', 'tit_sup',
                    'q1', 'susp', 'fin', 'sust_sale', 'tarj', 'base', 'gol')) < 16
    THROW 50000, 'Faltan jugadores en ##test_fjugador: ejecutar antes la preparación de plantel.formacion_jugador_*.', 1;
IF (SELECT COUNT(*) FROM plantel.formacion_jugador fj JOIN ##test_fjugador t ON t.jugador_id = fj.jugador_id
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
INSERT INTO ##test_tarjeta (clave, partido_id, formacion_id) VALUES
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
    JOIN ##test_fjugador t ON t.clave COLLATE DATABASE_DEFAULT = p.fj_clave COLLATE DATABASE_DEFAULT
    WHERE p.n = @i;
    SET @pos = IIF(@tit = 1, 'Defensor', 'Mediocampista');
    EXEC plantel.formacion_jugador_insertar @fid, @j, @pos, @tit;
    SET @i += 1;
END;
    -- Personas de los jugadores
INSERT INTO ##test_tarjeta (clave, persona_id)
SELECT m.k, j.persona_id
FROM (VALUES ('u_m', 'tit_1'), ('u_mr', 'tit_2'), ('u_e', 'tit_3'), ('u_e2', 'tit_4'), ('u_dob', 'tit_5'),
             ('u_a1', 'tit_6'), ('u_a2', 'tit_7'), ('u_titu', 'tit_8'), ('u_supl', 'tit_sup'),
             ('u_vis', 'q1'), ('u_susp', 'susp'), ('u_fin', 'fin'), ('u_zlim', 'sust_sale'),
             ('u_tarj', 'tarj'), ('u_conv', 'base'), ('u_gol', 'gol')) AS m (k, fk)
JOIN ##test_fjugador t ON t.clave COLLATE DATABASE_DEFAULT = m.fk COLLATE DATABASE_DEFAULT
JOIN plantel.jugador j ON j.jugador_id = t.jugador_id;
INSERT INTO ##test_tarjeta (clave, persona_id)
SELECT 'u_np', persona_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Base';   -- existe, no participa de ningún partido
    -- Cuerpo técnico de ZCB (participa de los partidos de ZCB) como personas libres, y uno de ZCA
SET @i = 1;
WHILE @i <= 26
BEGIN
    SET @ap = 'CT ' + CAST(@i AS VARCHAR(2));
    EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test TJ', @ap, 'otro', @x OUTPUT, @pe OUTPUT;
    INSERT INTO ##test_tarjeta (clave, persona_id) VALUES ('l_' + CAST(@i AS VARCHAR(2)), @pe);
    SET @i += 1;
END;
EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test TJ', 'CT Err',  'otro', @x OUTPUT, @pe OUTPUT; INSERT INTO ##test_tarjeta (clave, persona_id) VALUES ('u_err', @pe);  -- solo errores
EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test TJ', 'CT Amar', 'otro', @x OUTPUT, @pe OUTPUT; INSERT INTO ##test_tarjeta (clave, persona_id) VALUES ('u_ea',  @pe);  -- con una amarilla, solo errores
EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test TJ', 'CT Vis',  'otro', @x OUTPUT, @pe OUTPUT; INSERT INTO ##test_tarjeta (clave, persona_id) VALUES ('u_ctv', @pe);  -- cuerpo técnico visitante
    -- Tarjetas
DECLARE @u_m INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_m'),
        @u_mr INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_mr'),
        @u_e INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_e'),
        @u_e2 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_e2'),
        @u_dob INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_dob'),
        @u_a1 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_a1'),
        @u_a2 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_a2'),
        @u_ea INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_ea'),
        @u_susp INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_susp'),
        @u_tarj INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_tarj'),
        @u_fin INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_fin');
EXEC evento.tarjeta_insertar @pt, @u_m,    10, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_mod',   @tid);  -- a modificar
EXEC evento.tarjeta_insertar @pt, @u_mr,   70, 'ST', 'roja',     'Agresion',         'roja_directa',   @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_modr',  @tid);  -- roja a modificar (persona expulsada)
EXEC evento.tarjeta_insertar @pt, @u_e,    30, 'PT', 'amarilla', NULL,               NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_elim',  @tid);  -- baja valida
EXEC evento.tarjeta_insertar @pt, @u_e2,   80, 'ST', 'roja',     'Agresion',         'roja_directa',   @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_elim2', @tid);  -- baja valida (roja)
EXEC evento.tarjeta_insertar @pt, @u_dob,  20, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_dob_a', @tid);  -- primera amarilla de la doble
EXEC evento.tarjeta_insertar @pt, @u_dob,  70, 'ST', 'roja',     'Segunda amarilla', 'doble_amarilla', @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_dob_r', @tid);  -- roja por doble amarilla
EXEC evento.tarjeta_insertar @pt, @u_a1,   15, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_a1',    @tid);  -- para la doble amarilla valida
EXEC evento.tarjeta_insertar @pt, @u_a2,   25, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_a2',    @tid);  -- para la roja directa valida tras amarilla
EXEC evento.tarjeta_insertar @pt, @u_ea,   15, 'PT', 'amarilla', 'Falta',            NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_ea',    @tid);  -- para casos de error
EXEC evento.tarjeta_insertar @pt, @u_susp, 85, 'ST', 'roja',     'Agresion',         'roja_directa',   @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_susp',  @tid);  -- RESERVADA para evento.suspension_*
EXEC evento.tarjeta_insertar @pm, @u_tarj, 30, 'PT', 'amarilla', NULL,               NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_jug',   @tid);  -- partido 'mod' (grupos), jugador 'tarj'
EXEC evento.tarjeta_insertar @pz, @u_fin,  10, 'PT', 'amarilla', NULL,               NULL,             @tarjeta_id = @tid OUTPUT; INSERT INTO ##test_tarjeta (clave, tarjeta_id) VALUES ('t_fin',   @tid);  -- partido a finalizar
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

PRINT '--- P-3.16 Preparación de evento.criterio_suspension_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- No requiere ninguna otra preparación. Todos los criterios de prueba usan cantidad_amarillas entre 70 y 99 (nunca se alcanzan en un partido real).
IF OBJECT_ID('tempdb..##test_criterio') IS NULL
    CREATE TABLE ##test_criterio (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY, criterio_id INT NOT NULL);
GO
IF EXISTS (SELECT 1 FROM ##test_criterio)
    THROW 50000, 'La preparación de evento.criterio_suspension_* ya fue ejecutada en esta sesión (ver ##test_criterio).', 1;
IF EXISTS (SELECT 1 FROM evento.criterio_suspension WHERE cantidad_amarillas BETWEEN 70 AND 99)
    THROW 50000, 'Ya hay criterios con cantidad_amarillas entre 70 y 99 (rango reservado para las pruebas): ejecutar antes la limpieza de evento.criterio_suspension_*.', 1;
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 90, 1, 'grupos',        'jugador',        1, @id OUTPUT; INSERT INTO ##test_criterio VALUES ('mod',       @id);  -- a modificar
EXEC evento.criterio_suspension_insertar 90, 1, 'octavos',       NULL,             1, @id OUTPUT; INSERT INTO ##test_criterio VALUES ('mod2',      @id);  -- destino de duplicados
EXEC evento.criterio_suspension_insertar 90, 1, 'semifinal',     'jugador',        1, @id OUTPUT; INSERT INTO ##test_criterio VALUES ('dup',       @id);  -- destino de duplicados
EXEC evento.criterio_suspension_insertar 90, 1, NULL,            NULL,             1, @id OUTPUT; INSERT INTO ##test_criterio VALUES ('base_null', @id);  -- destino de duplicados (todas las fases, ambos tipos)
EXEC evento.criterio_suspension_insertar 90, 1, 'cuartos',       'cuerpo_tecnico', 1, @id OUTPUT; INSERT INTO ##test_criterio VALUES ('elim',      @id);  -- baja valida
EXEC evento.criterio_suspension_insertar 91, 1, NULL,            NULL,             0, @id OUTPUT; INSERT INTO ##test_criterio VALUES ('elim2',     @id);  -- baja valida (inactivo)
EXEC evento.criterio_suspension_insertar 90, 1, 'tercer_puesto', 'jugador',        1, @id OUTPUT; INSERT INTO ##test_criterio VALUES ('usado',     @id);  -- RESERVADO para evento.suspension_*
GO

















-- =======================================================================================================
--                                          VALIDACION
-- =======================================================================================================

-- ============================================================
GO

-- ============================================================
-- 3.1 torneo.parametro
-- ============================================================

PRINT '--- E-3.1.01 a E-3.1.06 torneo.parametro_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.

-- E-3.1.01 Valido => se acepta
BEGIN TRY EXEC torneo.parametro_insertar 'tst_ins_ok', 10, 'Alta valida'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.01', 'torneo.parametro_insertar: Valido', 0;
-- E-3.1.02 Valido: valor 0 (borde) => se acepta
BEGIN TRY EXEC torneo.parametro_insertar 'tst_cero', 0, 'Valor cero'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.02', 'torneo.parametro_insertar: Valido: valor 0 (borde)', 0;
-- E-3.1.03 borde => se acepta
BEGIN TRY EXEC torneo.parametro_insertar 'tst_valor_max', 2147483647, 'Valor maximo'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.03', 'torneo.parametro_insertar: borde', 0;
-- E-3.1.04 Valido: clave de 40 caracteres (borde) => se acepta
BEGIN TRY EXEC torneo.parametro_insertar 'tst_abcdefghijklmnopqrstuvwxyz0123456789', 1, 'Clave de 40'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.04', 'torneo.parametro_insertar: Valido: clave de 40 caracteres (borde)', 0;
-- E-3.1.05 Valido: la descripcion se guarda tal cual, sin recortar => se acepta
BEGIN TRY EXEC torneo.parametro_insertar 'tst_desc_esp', 1, '  Descripcion con espacios  '; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.05', 'torneo.parametro_insertar: Valido: la descripcion se guarda tal cual, sin recortar', 0;
-- E-3.1.06 Valido: permite mayus la collation => se acepta
BEGIN TRY EXEC torneo.parametro_insertar 'TST_MAYUS', 1, 'Clave en mayusculas'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.06', 'torneo.parametro_insertar: Valido: permite mayus la collation', 0;
GO

PRINT '--- E-3.1.07 a E-3.1.13 torneo.parametro_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @bk_hasta INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_hasta'),
        @bk_desde INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_desde');

-- E-3.1.07 Valido: cambia valor y descripcion => se acepta
BEGIN TRY EXEC torneo.parametro_modificar 'tst_mod', 20, 'Descripcion nueva'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.07', 'torneo.parametro_modificar: Valido: cambia valor y descripcion', 0;
-- E-3.1.08 Valido: sin descripcion, conserva 'Descripcion nueva' => se acepta
BEGIN TRY EXEC torneo.parametro_modificar 'tst_mod', 30; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.08', 'torneo.parametro_modificar: Valido: sin descripcion, conserva ''Descripcion nueva''', 0;
-- E-3.1.09 Valido: borde => se acepta
BEGIN TRY EXEC torneo.parametro_modificar 'tst_mod', 0, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.09', 'torneo.parametro_modificar: Valido: borde', 0;
-- E-3.1.10 Valido: hora de fin 24 (borde superior) => se acepta
BEGIN TRY EXEC torneo.parametro_modificar 'prime_time_hora_hasta', 24; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.10', 'torneo.parametro_modificar: Valido: hora de fin 24 (borde superior)', 0;
-- E-3.1.11 Valido: hora de fin 0 (borde inferior) => se acepta
BEGIN TRY EXEC torneo.parametro_modificar 'prime_time_hora_hasta', 0; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.11', 'torneo.parametro_modificar: Valido: hora de fin 0 (borde inferior)', 0;
-- E-3.1.12 Restaurar prime_time_hora_hasta => se acepta
BEGIN TRY EXEC torneo.parametro_modificar 'prime_time_hora_hasta', @bk_hasta; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.12', 'torneo.parametro_modificar: Restaurar prime_time_hora_hasta', 0;
-- E-3.1.13 Restaurar prime_time_hora_desde => se acepta
BEGIN TRY EXEC torneo.parametro_modificar 'prime_time_hora_desde', @bk_desde; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.13', 'torneo.parametro_modificar: Restaurar prime_time_hora_desde', 0;
GO

PRINT '--- E-3.1.14 torneo.parametro_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.

-- E-3.1.14 Baja valida => se acepta
BEGIN TRY EXEC torneo.parametro_eliminar 'tst_elim'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.1.14', 'torneo.parametro_eliminar: Baja valida', 0;
GO

-- ============================================================
-- 3.2 torneo.pais y torneo.confederacion
-- ============================================================

PRINT '--- E-3.2.01 a E-3.2.08 torneo.pais_validar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @e VARCHAR(2000),
        @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZM'),
        @n80 VARCHAR(80) = REPLICATE('N', 80);

-- E-3.2.01 Valido => se acepta
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', 100, @e OUTPUT; EXEC #registrar 'E-3.2.01', 'torneo.pais_validar: Valido', 0, @e;
-- E-3.2.02 Valido => se acepta
SET @e = ''; EXEC torneo.pais_validar @m, 'ZZM', 'Test Modificar', 'UTC-03', 100, @e OUTPUT; EXEC #registrar 'E-3.2.02', 'torneo.pais_validar: Valido', 0, @e;
-- E-3.2.03 Valido: PBI nulo => se acepta
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', NULL, @e OUTPUT; EXEC #registrar 'E-3.2.03', 'torneo.pais_validar: Valido: PBI nulo', 0, @e;
-- E-3.2.04 Valido: PBI 0 => se acepta
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', 0, @e OUTPUT; EXEC #registrar 'E-3.2.04', 'torneo.pais_validar: Valido: PBI 0', 0, @e;
-- E-3.2.05 Valido: ISO en minusculas => se acepta
SET @e = ''; EXEC torneo.pais_validar NULL, 'zzv', 'Test Validar', 'UTC-03', 100, @e OUTPUT; EXEC #registrar 'E-3.2.05', 'torneo.pais_validar: Valido: ISO en minusculas', 0, @e;
-- E-3.2.06 Valido: nombre de 80 caracteres y huso UTC+14 (bordes) => se acepta
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', @n80, 'UTC+14', 100, @e OUTPUT; EXEC #registrar 'E-3.2.06', 'torneo.pais_validar: Valido: nombre de 80 caracteres y huso UTC+14 (bordes)', 0, @e;
-- E-3.2.07 Valido: huso UTC-12 (borde) => se acepta
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-12', 100, @e OUTPUT; EXEC #registrar 'E-3.2.07', 'torneo.pais_validar: Valido: huso UTC-12 (borde)', 0, @e;
-- E-3.2.08 Valido: huso UTC+00 => se acepta
SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC+00', 100, @e OUTPUT; EXEC #registrar 'E-3.2.08', 'torneo.pais_validar: Valido: huso UTC+00', 0, @e;
GO

PRINT '--- E-3.2.09 a E-3.2.13 torneo.pais_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT, @n80 VARCHAR(80) = REPLICATE('N', 80);

-- E-3.2.09 Valido: devuelve el id generado => se acepta
BEGIN TRY EXEC torneo.pais_insertar 'ZZA', 'Test Alta', 'UTC-03', 1500.75, @id OUTPUT; SELECT @id AS pais_id_generado; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.09', 'torneo.pais_insertar: Valido: devuelve el id generado', 0;
-- E-3.2.10 Valido: PBI 0 => se acepta
BEGIN TRY EXEC torneo.pais_insertar 'ZZD', 'Test PBI Cero', 'UTC-03', 0, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.10', 'torneo.pais_insertar: Valido: PBI 0', 0;
-- E-3.2.11 Valido: el nombre se guarda recortado => se acepta
BEGIN TRY EXEC torneo.pais_insertar 'ZZG', '  Test Espacios  ', 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.11', 'torneo.pais_insertar: Valido: el nombre se guarda recortado', 0;
-- E-3.2.12 Valido: huso UTC+14 (borde superior) => se acepta
BEGIN TRY EXEC torneo.pais_insertar 'ZZH', 'Test Huso Max', 'UTC+14', 10, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.12', 'torneo.pais_insertar: Valido: huso UTC+14 (borde superior)', 0;
-- E-3.2.13 Valido: nombre de 80 caracteres (borde) => se acepta
BEGIN TRY EXEC torneo.pais_insertar 'ZZJ', @n80, 'UTC-03', 10, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.13', 'torneo.pais_insertar: Valido: nombre de 80 caracteres (borde)', 0;
GO

PRINT '--- E-3.2.14 a E-3.2.18 torneo.pais_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX')),
        @n80 VARCHAR(80) = REPLICATE('N', 80);

-- E-3.2.14 Valido => se acepta
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificado', 'UTC-04', 2500; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.14', 'torneo.pais_modificar: Valido', 0;
-- E-3.2.15 Valido: nombre de 80 caracteres (borde) => se acepta
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', @n80, 'UTC-03', 2000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.15', 'torneo.pais_modificar: Valido: nombre de 80 caracteres (borde)', 0;
-- E-3.2.16 Valido: huso UTC+14 y PBI 0 (bordes) => se acepta
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC+14', 0; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.16', 'torneo.pais_modificar: Valido: huso UTC+14 y PBI 0 (bordes)', 0;
-- E-3.2.17 Valido: sin PBI, lo deja en NULL => se acepta
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC-03'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.17', 'torneo.pais_modificar: Valido: sin PBI, lo deja en NULL', 0;
-- E-3.2.18 Restaurar: deja ZZM como estaba => se acepta
BEGIN TRY EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC-03', 2000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.18', 'torneo.pais_modificar: Restaurar: deja ZZM como estaba', 0;
GO

PRINT '--- E-3.2.19 torneo.pais_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @e INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZE'),
        @s INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZS'),
        @l INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZL'),
        @r INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZR'),
        @c INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZC'),
        @p INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZP'),
        @t INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZT');

-- E-3.2.19 Baja valida => se acepta
BEGIN TRY EXEC torneo.pais_eliminar @e; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.19', 'torneo.pais_eliminar: Baja valida', 0;
GO

PRINT '--- E-3.2.20 a E-3.2.21 torneo.confederacion_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));

-- E-3.2.20 Valido: UEFA pasa a OFC => se acepta
BEGIN TRY EXEC torneo.confederacion_modificar @u, 'OFC'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.20', 'torneo.confederacion_modificar: Valido: UEFA pasa a OFC', 0;
-- E-3.2.21 Restaurar: deja la base como estaba => se acepta
BEGIN TRY EXEC torneo.confederacion_modificar @u, 'UEFA'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.21', 'torneo.confederacion_modificar: Restaurar: deja la base como estaba', 0;
GO

PRINT '--- E-3.2.22 a E-3.2.23 torneo.confederacion_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT;

-- E-3.2.22 Valido: devuelve el id generado => se acepta
BEGIN TRY EXEC torneo.confederacion_insertar 'OFC', @id OUTPUT; SELECT @id AS confederacion_id_generado; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.22', 'torneo.confederacion_insertar: Valido: devuelve el id generado', 0;
-- E-3.2.23 Valido: otra confederacion libre => se acepta
BEGIN TRY EXEC torneo.confederacion_insertar 'CAF', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.23', 'torneo.confederacion_insertar: Valido: otra confederacion libre', 0;
GO

PRINT '--- E-3.2.24 torneo.confederacion_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @a INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CAF'),
        @c INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CONMEBOL');

-- E-3.2.24 Baja valida (sin selecciones) => se acepta
BEGIN TRY EXEC torneo.confederacion_eliminar @a; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.2.24', 'torneo.confederacion_eliminar: Baja valida (sin selecciones)', 0;
GO

-- ============================================================
-- 3.3 torneo.sede
-- ============================================================

PRINT '--- E-3.3.01 a E-3.3.03 torneo.sede_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSB'),
        @n80 VARCHAR(80) = 'Test Sede ' + REPLICATE('N', 70);

-- E-3.3.01 Valido: mismo nombre en otra ciudad => se acepta
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede Alta', 'Ciudad Otra', @pa, 60000, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.3.01', 'torneo.sede_insertar: Valido: mismo nombre en otra ciudad', 0;
-- E-3.3.02 Valido: misma ciudad con otro nombre, otro pais => se acepta
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede Otro', 'Ciudad Alta', @pb, 60000, 'UTC-05', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.3.02', 'torneo.sede_insertar: Valido: misma ciudad con otro nombre, otro pais', 0;
-- E-3.3.03 Valido: capacidad maxima INT (borde) => se acepta
BEGIN TRY EXEC torneo.sede_insertar 'Test Sede Max', 'Ciudad Max', @pa, 2147483647, 'UTC-03', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.3.03', 'torneo.sede_insertar: Valido: capacidad maxima INT (borde)', 0;
GO

PRINT '--- E-3.3.04 a E-3.3.05 torneo.sede_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSB'),
        @pc INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSC'),
        @n80 VARCHAR(80) = 'Test Sede ' + REPLICATE('N', 70);

-- E-3.3.04 Valido => se acepta
BEGIN TRY EXEC torneo.sede_modificar @m, 'Test Sede Mod Nuevo', 'Ciudad Mod Nueva', @pb, 45000, 'UTC-05'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.3.04', 'torneo.sede_modificar: Valido', 0;
-- E-3.3.05 Valido: se guarda recortado => se acepta
BEGIN TRY EXEC torneo.sede_modificar @m, '  Test Sede Mod  ', '  Ciudad Mod  ', @pa, 40000, 'UTC-03'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.3.05', 'torneo.sede_modificar: Valido: se guarda recortado', 0;
GO

PRINT '--- E-3.3.06 torneo.sede_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @e INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Elim' AND ciudad = 'Ciudad Elim'),
        @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');

-- E-3.3.06 Baja valida (sin partidos) => se acepta
BEGIN TRY EXEC torneo.sede_eliminar @e; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.3.06', 'torneo.sede_eliminar: Baja valida (sin partidos)', 0;
GO

-- ============================================================
-- 3.4 torneo.seleccion
-- ============================================================

PRINT '--- E-3.4.01 a E-3.4.04 torneo.seleccion_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQA'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQB'),
        @pc INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQC'),
        @pd INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQD'),
        @pe INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQE'),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
DECLARE @c2 INT = ISNULL((SELECT TOP 1 confederacion_id FROM torneo.confederacion WHERE confederacion_id > @c1 ORDER BY confederacion_id), @c1);

-- E-3.4.01 Valido: grupo borde A (cada alta valida usa un pais distinto: ZQB, ZQC, ZQD, ZQE) => se acepta
BEGIN TRY EXEC torneo.seleccion_insertar @pb, @c1, 'A', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.4.01', 'torneo.seleccion_insertar: Valido: grupo borde A (cada alta valida usa un pais distinto: ZQB, ZQC, ZQD, ZQE)', 0;
-- E-3.4.02 Valido: grupo en minuscula (se guarda 'B') => se acepta
BEGIN TRY EXEC torneo.seleccion_insertar @pc, @c2, 'b', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.4.02', 'torneo.seleccion_insertar: Valido: grupo en minuscula (se guarda ''B'')', 0;
-- E-3.4.03 Valido: grupo borde L => se acepta
BEGIN TRY EXEC torneo.seleccion_insertar @pd, @c1, 'L', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.4.03', 'torneo.seleccion_insertar: Valido: grupo borde L', 0;
-- E-3.4.04 Valido: grupo borde L en minuscula (se guarda 'L') => se acepta
BEGIN TRY EXEC torneo.seleccion_insertar @pe, @c1, 'l', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.4.04', 'torneo.seleccion_insertar: Valido: grupo borde L en minuscula (se guarda ''L'')', 0;
GO

PRINT '--- E-3.4.05 torneo.seleccion_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP'),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM'),
        @pn INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQN'),
        @po INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQO'),
        @pp INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQP');
DECLARE @c2 INT = ISNULL((SELECT TOP 1 confederacion_id FROM torneo.confederacion WHERE confederacion_id > @c1 ORDER BY confederacion_id), @c1);

-- E-3.4.05 Valido: cambia pais (a uno libre), confederacion y grupo (sin partidos) => se acepta
BEGIN TRY EXEC torneo.seleccion_modificar @m, @pn, @c2, 'H'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.4.05', 'torneo.seleccion_modificar: Valido: cambia pais (a uno libre), confederacion y grupo (sin partidos)', 0;
GO

PRINT '--- E-3.4.06 torneo.seleccion_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @e INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQX'),
        @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP'),
        @cv INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQV'),
        @ct INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQT'),
        @k INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQK');

-- E-3.4.06 Baja valida => se acepta
BEGIN TRY EXEC torneo.seleccion_eliminar @e; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.4.06', 'torneo.seleccion_eliminar: Baja valida', 0;
GO

-- ============================================================
-- 3.5 torneo.partido
-- ============================================================

PRINT '--- E-3.5.01 a E-3.5.04 torneo.partido_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base'),
        @s5 INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Cinco'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');

-- E-3.5.01 Valido: UTC se deriva de la hora local (verificar con SELECT) => se acepta
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-09-10 15:00:00 -03:00', 'dieciseisavos', @a4, @b1, NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.01', 'torneo.partido_insertar: Valido: UTC se deriva de la hora local (verificar con SELECT)', 0;
-- E-3.5.02 Valido: UTC informado y consistente => se acepta
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-09-15 15:00:00 -03:00', 'octavos', @a4, @b1, '2026-09-15 18:00:00 +00:00', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.02', 'torneo.partido_insertar: Valido: UTC informado y consistente', 0;
-- E-3.5.03 Valido: sede con huso UTC-05 (UTC derivado = 20:00 +00:00) => se acepta
BEGIN TRY EXEC torneo.partido_insertar @s5, '2026-09-20 15:00:00 -05:00', 'cuartos', @a3, @b1, NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.03', 'torneo.partido_insertar: Valido: sede con huso UTC-05 (UTC derivado = 20:00 +00:00)', 0;
-- E-3.5.04 Valido: fase de grupos, mismo grupo => se acepta
BEGIN TRY EXEC torneo.partido_insertar @sl, '2026-09-25 15:00:00 -03:00', 'grupos', @a2, @a4, NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.04', 'torneo.partido_insertar: Valido: fase de grupos, mismo grupo', 0;
GO

PRINT '--- E-3.5.05 a E-3.5.09 torneo.partido_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base'),
        @sm INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Mod'),
        @s5 INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Cinco'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4)),
        @fin  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'octavos'       AND seleccion_local_id IN (@a1, @a3) AND seleccion_visitante_id IN (@a1, @a3)),
        @form INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a1, @a4) AND seleccion_visitante_id IN (@a1, @a4)),
        @all  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));

-- E-3.5.05 Valido: cambia sede y fecha => se acepta
BEGIN TRY EXEC torneo.partido_modificar @m, @sl, '2026-06-22 15:00:00 -03:00', 'grupos', @a3, @a4; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.05', 'torneo.partido_modificar: Valido: cambia sede y fecha', 0;
-- E-3.5.06 Valido: sin cambios => se acepta
BEGIN TRY EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.06', 'torneo.partido_modificar: Valido: sin cambios', 0;
-- E-3.5.07 Valido: se invierten local y visitante => se acepta
BEGIN TRY EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a4, @a3; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.07', 'torneo.partido_modificar: Valido: se invierten local y visitante', 0;
-- E-3.5.08 Valido: pasa a suspendido => se acepta
BEGIN TRY EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4, 'suspendido'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.08', 'torneo.partido_modificar: Valido: pasa a suspendido', 0;
-- E-3.5.09 Valido: se reprograma un partido con formaciones sin cambiar las selecciones => se acepta
BEGIN TRY EXEC torneo.partido_modificar @form, @sb, '2026-07-01 15:00:00 -03:00', 'cuartos', @a1, @a4; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.09', 'torneo.partido_modificar: Valido: se reprograma un partido con formaciones sin cambiar las selecciones', 0;
GO

PRINT '--- E-3.5.10 torneo.partido_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD');
DECLARE @elim INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4)),
        @fin  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'octavos'       AND seleccion_local_id IN (@a1, @a3) AND seleccion_visitante_id IN (@a1, @a3)),
        @form INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a1, @a4) AND seleccion_visitante_id IN (@a1, @a4)),
        @tarj INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a2, @a3) AND seleccion_visitante_id IN (@a2, @a3)),
        @susp INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'semifinal'     AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2)),
        @arb  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'tercer_puesto' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2)),
        @pub  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'final'         AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2)),
        @all  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));

-- E-3.5.10 Baja valida => se acepta
BEGIN TRY EXEC torneo.partido_eliminar @elim; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.5.10', 'torneo.partido_eliminar: Baja valida', 0;
GO

-- ============================================================
-- 3.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================

PRINT '--- E-3.6.01 a E-3.6.02 plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error)';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT;

-- E-3.6.01 Valido: jugador => se acepta
BEGIN TRY EXEC plantel.persona_insertar 'jugador', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.01', 'plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Valido: jugador', 0;
-- E-3.6.02 Valido => se acepta
BEGIN TRY EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.02', 'plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error): Valido', 0;
GO

PRINT '--- E-3.6.03 a E-3.6.06 plantel.persona_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @mod  INT = (SELECT persona_id FROM ##test_persona WHERE clave = 'mod'),
        @jug  INT = (SELECT persona_id FROM ##test_persona WHERE clave = 'jug'),
        @ct   INT = (SELECT persona_id FROM ##test_persona WHERE clave = 'ct'),
        @todo INT = (SELECT persona_id FROM ##test_persona WHERE clave = 'todo');

-- E-3.6.03 Valido => se acepta
BEGIN TRY EXEC plantel.persona_modificar @mod, 'cuerpo_tecnico'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.03', 'plantel.persona_modificar: Valido', 0;
-- E-3.6.04 Valido: vuelve a jugador => se acepta
BEGIN TRY EXEC plantel.persona_modificar @mod, 'jugador'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.04', 'plantel.persona_modificar: Valido: vuelve a jugador', 0;
-- E-3.6.05 Valido: sin cambios (mismo tipo) => se acepta
BEGIN TRY EXEC plantel.persona_modificar @mod, 'jugador'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.05', 'plantel.persona_modificar: Valido: sin cambios (mismo tipo)', 0;
-- E-3.6.06 Valido: jugador registrado, mismo tipo => se acepta
BEGIN TRY EXEC plantel.persona_modificar @jug, 'jugador'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.06', 'plantel.persona_modificar: Valido: jugador registrado, mismo tipo', 0;
GO

PRINT '--- E-3.6.07 a E-3.6.08 plantel.persona_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @elim    INT = (SELECT persona_id FROM ##test_persona WHERE clave = 'elim'),
        @elim_ct INT = (SELECT persona_id FROM ##test_persona WHERE clave = 'elim_ct'),
        @jug     INT = (SELECT persona_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27'),   -- jugador sin tarjetas
        @ct      INT = (SELECT persona_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Ayudante'),   -- cuerpo técnico sin tarjetas
        @tarj    INT = (SELECT persona_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 05'),   -- jugador con amarillas
        @todo    INT = (SELECT persona_id FROM ##test_persona WHERE clave = 'todo');

-- E-3.6.07 Baja valida => se acepta
BEGIN TRY EXEC plantel.persona_eliminar @elim; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.07', 'plantel.persona_eliminar: Baja valida', 0;
-- E-3.6.08 Baja valida (tipo cuerpo tecnico, sin registros) => se acepta
BEGIN TRY EXEC plantel.persona_eliminar @elim_ct; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.08', 'plantel.persona_eliminar: Baja valida (tipo cuerpo tecnico, sin registros)', 0;
GO

PRINT '--- E-3.6.09 a E-3.6.15 plantel.cuerpo_tecnico_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT, @pid INT,
        @antes INT = (SELECT COUNT(*) FROM plantel.persona),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @n100 VARCHAR(100) = 'Test CT' + REPLICATE('N', 93);

-- E-3.6.09 Valido => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Alta', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.09', 'plantel.cuerpo_tecnico_insertar: Valido', 0;
-- E-3.6.10 Valido: se guarda recortado => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, '  Test CT  ', '  Recortado  ', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.10', 'plantel.cuerpo_tecnico_insertar: Valido: se guarda recortado', 0;
-- E-3.6.11 Valido: DT en seleccion sin DT => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s3, 'Test CT', 'Alta DT', 'director_tecnico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.11', 'plantel.cuerpo_tecnico_insertar: Valido: DT en seleccion sin DT', 0;
-- E-3.6.12 Valido: misma persona con otro rol en la misma seleccion => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Alta', 'preparador_fisico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.12', 'plantel.cuerpo_tecnico_insertar: Valido: misma persona con otro rol en la misma seleccion', 0;
-- E-3.6.13 Valido: misma persona y rol en otra seleccion => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test CT', 'Alta', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.13', 'plantel.cuerpo_tecnico_insertar: Valido: misma persona y rol en otra seleccion', 0;
-- E-3.6.14 Valido: rol "otro" => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Rol Otro', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.14', 'plantel.cuerpo_tecnico_insertar: Valido: rol "otro"', 0;
-- E-3.6.15 Valido: nombre de 100 caracteres (borde; ajustar si la columna es mas corta) => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_insertar @s1, @n100, 'Largo', 'otro', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.15', 'plantel.cuerpo_tecnico_insertar: Valido: nombre de 100 caracteres (borde; ajustar si la columna es mas corta)', 0;
GO

PRINT '--- E-3.6.16 a E-3.6.17 plantel.cuerpo_tecnico_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @t  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Tarjeta', 'Tarjeta Nuevo')),
        @dt INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Director'),
        @ay INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Ayudante'),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC');

-- E-3.6.16 Valido: cambia seleccion, apellido y rol => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s2, 'Test CT', 'Mod Nuevo', 'ayudante_tecnico'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.16', 'plantel.cuerpo_tecnico_modificar: Valido: cambia seleccion, apellido y rol', 0;
-- E-3.6.17 Valido: se guarda recortado => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '  Test CT  ', '  Mod  ', 'otro'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.17', 'plantel.cuerpo_tecnico_modificar: Valido: se guarda recortado', 0;
GO

PRINT '--- E-3.6.18 plantel.cuerpo_tecnico_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @e  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim'),
        @et INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim Tran'),
        @t  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Tarjeta', 'Tarjeta Nuevo')),
        @pe INT = (SELECT persona_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim');

-- E-3.6.18 Baja valida (sin tarjetas): ambos 0 => se acepta
BEGIN TRY EXEC plantel.cuerpo_tecnico_eliminar @e; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.18', 'plantel.cuerpo_tecnico_eliminar: Baja valida (sin tarjetas): ambos 0', 0;
GO

PRINT '--- E-3.6.19 a E-3.6.31 plantel.jugador_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT, @pid INT, @antes INT,
        @f15 DATE = DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE)),
        @f50 DATE = DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE)),
        @f15_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE))),
        @f50_mas DATE = DATEADD(DAY, -1, DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE))),
        @n100 VARCHAR(100) = 'Test JU' + REPLICATE('N', 93),
        @c120 VARCHAR(120) = REPLICATE('C', 120);

-- E-3.6.19 Valido => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Alta', '1995-03-15', 'delantero', 'Club Alta', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.19', 'plantel.jugador_insertar: Valido', 0;
-- E-3.6.20 Valido: se guarda recortado => se acepta
BEGIN TRY EXEC plantel.jugador_insertar '  Test JU  ', '  Recortado  ', '1995-03-15', 'defensor', '  Club Recortado  ', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.20', 'plantel.jugador_insertar: Valido: se guarda recortado', 0;
-- E-3.6.21 Valido: club nulo => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Sin Club', '1995-03-15', 'arquero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.21', 'plantel.jugador_insertar: Valido: club nulo', 0;
-- E-3.6.22 Valido: club vacio se guarda como NULL => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Club Vacio', '1995-03-15', 'arquero', '', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.22', 'plantel.jugador_insertar: Valido: club vacio se guarda como NULL', 0;
-- E-3.6.23 Valido: club solo espacios se guarda como NULL => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Club Espacios', '1995-03-15', 'arquero', '   ', @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.23', 'plantel.jugador_insertar: Valido: club solo espacios se guarda como NULL', 0;
-- E-3.6.24 Valido: sin pasar club (valor por defecto) => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Sin Param Club', '1995-03-15', 'mediocampista', @jugador_id = @id OUTPUT, @persona_id = @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.24', 'plantel.jugador_insertar: Valido: sin pasar club (valor por defecto)', 0;
-- E-3.6.25 Valido: club de 120 caracteres (borde) => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Club Largo', '1995-03-15', 'delantero', @c120, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.25', 'plantel.jugador_insertar: Valido: club de 120 caracteres (borde)', 0;
-- E-3.6.26 Valido: nombre de 100 caracteres (borde) => se acepta
BEGIN TRY EXEC plantel.jugador_insertar @n100, 'Nombre Largo', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.26', 'plantel.jugador_insertar: Valido: nombre de 100 caracteres (borde)', 0;
-- E-3.6.27 Valido: posicion mediocampista => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Mediocampista', '1995-03-15', 'mediocampista', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.27', 'plantel.jugador_insertar: Valido: posicion mediocampista', 0;
-- E-3.6.28 Valido: justo 15 anios (borde) => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Borde 15', @f15, 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.28', 'plantel.jugador_insertar: Valido: justo 15 anios (borde)', 0;
-- E-3.6.29 Valido: justo 50 anios (borde) => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Borde 50', @f50, 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.29', 'plantel.jugador_insertar: Valido: justo 50 anios (borde)', 0;
-- E-3.6.30 Valido: mismo nombre y apellido con otra fecha => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Base', '1996-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.30', 'plantel.jugador_insertar: Valido: mismo nombre y apellido con otra fecha', 0;
-- E-3.6.31 Valido: misma fecha que otros jugadores con otro apellido => se acepta
BEGIN TRY EXEC plantel.jugador_insertar 'Test JU', 'Otra Fecha Igual', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.31', 'plantel.jugador_insertar: Valido: misma fecha que otros jugadores con otro apellido', 0;
GO

PRINT '--- E-3.6.32 a E-3.6.36 plantel.jugador_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo')),
        @base INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Base' AND fecha_nacimiento = '1995-03-15'),
        @f15 DATE = DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE)),
        @f50 DATE = DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE)),
        @f15_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE))),
        @f50_mas DATE = DATEADD(DAY, -1, DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE)));

-- E-3.6.32 Valido: cambia apellido, fecha, posicion y club => se acepta
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod Nuevo', '1996-06-20', 'delantero', 'Club Nuevo'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.32', 'plantel.jugador_modificar: Valido: cambia apellido, fecha, posicion y club', 0;
-- E-3.6.33 Valido: club vacio se guarda como NULL => se acepta
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor', ''; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.33', 'plantel.jugador_modificar: Valido: club vacio se guarda como NULL', 0;
-- E-3.6.34 Valido: club solo espacios se guarda como NULL => se acepta
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor', '   '; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.34', 'plantel.jugador_modificar: Valido: club solo espacios se guarda como NULL', 0;
-- E-3.6.35 Valido: sin pasar club (valor por defecto) => se acepta
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.35', 'plantel.jugador_modificar: Valido: sin pasar club (valor por defecto)', 0;
-- E-3.6.36 Valido: posicion mediocampista => se acepta
BEGIN TRY EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'mediocampista', 'Club Mod'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.36', 'plantel.jugador_modificar: Valido: posicion mediocampista', 0;
GO

PRINT '--- E-3.6.37 plantel.jugador_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @e INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Elim'),
        @et INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Elim Tran'),
        @conv INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Otro'),
        @form INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Convocado'),
        @tar INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Tarjeta');

-- E-3.6.37 Baja valida (sin convocatorias, formaciones ni tarjetas) => se acepta
BEGIN TRY EXEC plantel.jugador_eliminar @e; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.6.37', 'plantel.jugador_eliminar: Baja valida (sin convocatorias, formaciones ni tarjetas)', 0;
GO

-- ============================================================
-- 3.7 plantel.convocatoria
-- ============================================================

PRINT '--- E-3.7.01 a E-3.7.12 plantel.convocatoria_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @jm  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Mod'),
        @jb  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Baja'),
        @jb2 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Baja 2'),
        @jl  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre Err'),
        @l1  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 1'),
        @l2  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 2'),
        @l3  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 3'),
        @l4  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 4'),
        @l5  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 5'),
        @l6  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 6'),
        @l7  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 7'),
        @l8  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 8'),
        @l9  INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 9'),
        @l10 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Conv Libre 10');

-- E-3.7.01 Valido => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @l1, 1, '2026-06-01', 'Convocatoria inicial', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.01', 'plantel.convocatoria_insertar: Valido', 0;
-- E-3.7.02 Valido: motivo se guarda recortado => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @l2, 2, '2026-06-01', '  Motivo con espacios  ', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.02', 'plantel.convocatoria_insertar: Valido: motivo se guarda recortado', 0;
-- E-3.7.03 Valido: motivo nulo => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @l3, 3, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.03', 'plantel.convocatoria_insertar: Valido: motivo nulo', 0;
-- E-3.7.04 Valido: motivo vacio se guarda como NULL => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @l4, 4, '2026-06-01', '', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.04', 'plantel.convocatoria_insertar: Valido: motivo vacio se guarda como NULL', 0;
-- E-3.7.05 Valido: motivo solo espacios se guarda como NULL => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @l5, 5, '2026-06-01', '   ', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.05', 'plantel.convocatoria_insertar: Valido: motivo solo espacios se guarda como NULL', 0;
-- E-3.7.06 Valido: sin pasar motivo (valor por defecto) => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @l6, 6, '2026-06-01', @convocatoria_id = @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.06', 'plantel.convocatoria_insertar: Valido: sin pasar motivo (valor por defecto)', 0;
-- E-3.7.07 Valido: dorsal minimo (borde) => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s2, @l7, 1, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.07', 'plantel.convocatoria_insertar: Valido: dorsal minimo (borde)', 0;
-- E-3.7.08 Valido: dorsal maximo (borde) => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s2, @l8, 99, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.08', 'plantel.convocatoria_insertar: Valido: dorsal maximo (borde)', 0;
-- E-3.7.09 Valido: dorsal 5 usado solo por una convocatoria historica => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s1, @l9, 5, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.09', 'plantel.convocatoria_insertar: Valido: dorsal 5 usado solo por una convocatoria historica', 0;
-- E-3.7.10 Valido: mismo dorsal que usa s1, pero en otra seleccion => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s3, @l10, 7, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.10', 'plantel.convocatoria_insertar: Valido: mismo dorsal que usa s1, pero en otra seleccion', 0;
-- E-3.7.11 Valido: jugador con convocatoria historica vuelve a ser convocado en la misma seleccion => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s1, @jb, 6, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.11', 'plantel.convocatoria_insertar: Valido: jugador con convocatoria historica vuelve a ser convocado en la misma seleccion', 0;
-- E-3.7.12 Valido: jugador con convocatoria historica convocado por otra seleccion => se acepta
BEGIN TRY EXEC plantel.convocatoria_insertar @s2, @jb2, 6, '2026-06-01', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.12', 'plantel.convocatoria_insertar: Valido: jugador con convocatoria historica convocado por otra seleccion', 0;
GO

PRINT '--- E-3.7.13 a E-3.7.26 plantel.convocatoria_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @cm INT, @cbm INT, @cb INT, @cb2 INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
SET @cbm = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja Mod' AND c.seleccion_id = @s1);
SET @cb  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja'     AND c.seleccion_id = @s1 AND c.fecha_baja IS NOT NULL);
SET @cb2 = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja 2'   AND c.seleccion_id = @s1);

-- E-3.7.13 Valido: cambia dorsal, fecha y motivo de alta => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 12, '2026-06-02', 'Motivo nuevo', NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.13', 'plantel.convocatoria_modificar: Valido: cambia dorsal, fecha y motivo de alta', 0;
-- E-3.7.14 Valido: sin cambios (no choca consigo misma) => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', 'Motivo inicial', NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.14', 'plantel.convocatoria_modificar: Valido: sin cambios (no choca consigo misma)', 0;
-- E-3.7.15 Valido: motivo de alta se guarda recortado => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '  Motivo  ', NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.15', 'plantel.convocatoria_modificar: Valido: motivo de alta se guarda recortado', 0;
-- E-3.7.16 Valido: motivo de alta nulo => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.16', 'plantel.convocatoria_modificar: Valido: motivo de alta nulo', 0;
-- E-3.7.17 Valido: motivo de alta vacio se guarda como NULL => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '', NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.17', 'plantel.convocatoria_modificar: Valido: motivo de alta vacio se guarda como NULL', 0;
-- E-3.7.18 Valido: motivo de alta solo espacios se guarda como NULL => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '   ', NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.18', 'plantel.convocatoria_modificar: Valido: motivo de alta solo espacios se guarda como NULL', 0;
-- E-3.7.19 Valido: sin pasar motivo ni baja (valores por defecto) => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.19', 'plantel.convocatoria_modificar: Valido: sin pasar motivo ni baja (valores por defecto)', 0;
-- E-3.7.20 Valido: dorsal minimo (borde) => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 1, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.20', 'plantel.convocatoria_modificar: Valido: dorsal minimo (borde)', 0;
-- E-3.7.21 Valido: dorsal maximo (borde) => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 99, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.21', 'plantel.convocatoria_modificar: Valido: dorsal maximo (borde)', 0;
-- E-3.7.22 Valido: dorsal 4 usado solo por una convocatoria historica => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cm, 4, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.22', 'plantel.convocatoria_modificar: Valido: dorsal 4 usado solo por una convocatoria historica', 0;
-- E-3.7.23 Valido: registrar la baja (queda historica) => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, '2026-06-20', 'Lesion'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.23', 'plantel.convocatoria_modificar: Valido: registrar la baja (queda historica)', 0;
-- E-3.7.24 Valido: baja el mismo dia del alta (borde) => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, '2026-06-01', 'Reemplazo'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.24', 'plantel.convocatoria_modificar: Valido: baja el mismo dia del alta (borde)', 0;
-- E-3.7.25 Valido: reactivar la baja (vuelve a ser vigente; ejecutar despues de registrar la baja) => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.25', 'plantel.convocatoria_modificar: Valido: reactivar la baja (vuelve a ser vigente; ejecutar despues de registrar la baja)', 0;
-- E-3.7.26 Valido: corregir fecha y motivo de baja de una historica => se acepta
BEGIN TRY EXEC plantel.convocatoria_modificar @cb, 5, '2026-05-01', NULL, '2026-05-25', 'Reemplazo'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.26', 'plantel.convocatoria_modificar: Valido: corregir fecha y motivo de baja de una historica', 0;
GO

PRINT '--- E-3.7.27 a E-3.7.28 plantel.convocatoria_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ce INT, @ceb INT, @cf INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @ce  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Elim'      AND c.seleccion_id = @s1);
SET @ceb = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Elim Baja' AND c.seleccion_id = @s1);
SET @cf  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Formacion'     AND c.seleccion_id = @s1);

-- E-3.7.27 Baja valida: convocatoria vigente sin formaciones => se acepta
BEGIN TRY EXEC plantel.convocatoria_eliminar @ce; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.27', 'plantel.convocatoria_eliminar: Baja valida: convocatoria vigente sin formaciones', 0;
-- E-3.7.28 Baja valida: convocatoria historica (con baja) sin formaciones => se acepta
BEGIN TRY EXEC plantel.convocatoria_eliminar @ceb; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.7.28', 'plantel.convocatoria_eliminar: Baja valida: convocatoria historica (con baja) sin formaciones', 0;
GO

-- ============================================================
-- 3.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================

PRINT '--- E-3.8.01 a E-3.8.06 plantel.formacion_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @pa INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'ins_a'),
        @pb INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'ins_b'),
        @pc INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'ins_c'),
        @pm INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'mod'),
        @pf INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'fin');

-- E-3.8.01 Valido => se acepta
BEGIN TRY EXEC plantel.formacion_insertar @pa, 'local', '4-3-3', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.01', 'plantel.formacion_insertar: Valido', 0;
-- E-3.8.02 Valido: mismo partido, la otra condicion => se acepta
BEGIN TRY EXEC plantel.formacion_insertar @pa, 'visitante', '4-4-2', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.02', 'plantel.formacion_insertar: Valido: mismo partido, la otra condicion', 0;
-- E-3.8.03 Valido: otro esquema de 3 lineas => se acepta
BEGIN TRY EXEC plantel.formacion_insertar @pb, 'local', '3-5-2', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.03', 'plantel.formacion_insertar: Valido: otro esquema de 3 lineas', 0;
-- E-3.8.04 Valido: esquema de 4 lineas => se acepta
BEGIN TRY EXEC plantel.formacion_insertar @pb, 'visitante', '4-2-3-1', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.04', 'plantel.formacion_insertar: Valido: esquema de 4 lineas', 0;
-- E-3.8.05 Valido: 5 lineas y 9 caracteres (borde maximo) => se acepta
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'local', '1-1-1-1-6', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.05', 'plantel.formacion_insertar: Valido: 5 lineas y 9 caracteres (borde maximo)', 0;
-- E-3.8.06 Valido: 3 lineas (borde minimo) => se acepta
BEGIN TRY EXEC plantel.formacion_insertar @pc, 'visitante', '1-1-8', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.06', 'plantel.formacion_insertar: Valido: 3 lineas (borde minimo)', 0;
GO

PRINT '--- E-3.8.07 a E-3.8.11 plantel.formacion_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @fm INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'mod'),
        @ff INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fin');

-- E-3.8.07 Valido: cambia el esquema => se acepta
BEGIN TRY EXEC plantel.formacion_modificar @fm, '4-3-3'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.07', 'plantel.formacion_modificar: Valido: cambia el esquema', 0;
-- E-3.8.08 Valido: otro esquema de 3 lineas => se acepta
BEGIN TRY EXEC plantel.formacion_modificar @fm, '3-5-2'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.08', 'plantel.formacion_modificar: Valido: otro esquema de 3 lineas', 0;
-- E-3.8.09 Valido: 5 lineas y 9 caracteres (borde maximo) => se acepta
BEGIN TRY EXEC plantel.formacion_modificar @fm, '1-1-1-1-6'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.09', 'plantel.formacion_modificar: Valido: 5 lineas y 9 caracteres (borde maximo)', 0;
-- E-3.8.10 Valido: 3 lineas (borde minimo) => se acepta
BEGIN TRY EXEC plantel.formacion_modificar @fm, '1-1-8'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.10', 'plantel.formacion_modificar: Valido: 3 lineas (borde minimo)', 0;
-- E-3.8.11 Valido: deja la formacion como en la preparacion => se acepta
BEGIN TRY EXEC plantel.formacion_modificar @fm, '4-4-2'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.11', 'plantel.formacion_modificar: Valido: deja la formacion como en la preparacion', 0;
GO

PRINT '--- E-3.8.12 a E-3.8.13 plantel.formacion_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @fe  INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'elim'),
        @fe2 INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'elim2'),
        @ff  INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fin'),
        @fj  INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug');

-- E-3.8.12 Baja valida: formacion sin jugadores de partido no finalizado => se acepta
BEGIN TRY EXEC plantel.formacion_eliminar @fe; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.12', 'plantel.formacion_eliminar: Baja valida: formacion sin jugadores de partido no finalizado', 0;
-- E-3.8.13 Baja valida: la otra condicion del mismo partido => se acepta
BEGIN TRY EXEC plantel.formacion_eliminar @fe2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.13', 'plantel.formacion_eliminar: Baja valida: la otra condicion del mismo partido', 0;
GO

PRINT '--- E-3.8.14 a E-3.8.18 plantel.formacion_jugador_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @fj INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug'),
        @fl INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fl_tit'),
        @fs INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fl_sup'),
        @ff INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fj_fin'),
        @base INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'base'),
        @ins  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'ins'),
        @fin  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'fin'),
        @p    INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'p'),
        @sc   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sin_conv'),
        @t1   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'tit_1'),
        @tx   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'tit_extra'),
        @l1   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'lib_1'),
        @l2   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'lib_2'),
        @l3   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'lib_3'),  -- solo para casos de error: no darlo de alta
        @adia INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'alta_dia'),
        @fut  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'futuro'),
        @hist INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'hist'),
        @bdia INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'baja_dia'),
        @sx   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sup_extra'),
        @sn   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sup_nuevo'),
        @susp INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'susp');

-- E-3.8.14 Valido: titular (toma el dorsal 3 de su convocatoria) => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fj, @ins, 'Delantero', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.14', 'plantel.formacion_jugador_insertar: Valido: titular (toma el dorsal 3 de su convocatoria)', 0;
-- E-3.8.15 Valido: suplente en una formacion con los titulares completos => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @l1, 'Lateral', 0; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.15', 'plantel.formacion_jugador_insertar: Valido: suplente en una formacion con los titulares completos', 0;
-- E-3.8.16 Valido: la posicion se guarda recortada => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @l2, '  Lateral  ', 0; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.16', 'plantel.formacion_jugador_insertar: Valido: la posicion se guarda recortada', 0;
-- E-3.8.17 Valido: convocatoria con alta el mismo dia del partido (borde) => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fl, @adia, 'Lateral', 0; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.17', 'plantel.formacion_jugador_insertar: Valido: convocatoria con alta el mismo dia del partido (borde)', 0;
-- E-3.8.18 Valido: titular en una formacion con el banco de suplentes completo => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_insertar @fs, @sn, 'Delantero', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.18', 'plantel.formacion_jugador_insertar: Valido: titular en una formacion con el banco de suplentes completo', 0;
GO

PRINT '--- E-3.8.19 a E-3.8.23 plantel.formacion_jugador_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @fj INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug'),
        @fl INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fl_tit'),
        @fs INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fl_sup'),
        @ff INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fj_fin'),
        @base INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'base'),
        @s    INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 's'),
        @r    INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'r'),
        @zb   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'z_baja'),
        @fin  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'fin'),
        @sc   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sin_conv'),
        @l3   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'lib_3'),
        @t1   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'tit_1'),
        @tsup INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'tit_sup'),
        @sup1 INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sup_1'),
        @supt INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sup_tit'),
        @ssale INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sust_sale'),
        @sent  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sust_entra');

-- E-3.8.19 Valido: cambia la posicion => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, 'Extremo', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.19', 'plantel.formacion_jugador_modificar: Valido: cambia la posicion', 0;
-- E-3.8.20 Valido: sin cambios (deja al jugador como en la preparacion) => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.20', 'plantel.formacion_jugador_modificar: Valido: sin cambios (deja al jugador como en la preparacion)', 0;
-- E-3.8.21 Valido: la posicion se guarda recortada => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, '  Extremo  ', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.21', 'plantel.formacion_jugador_modificar: Valido: la posicion se guarda recortada', 0;
-- E-3.8.22 Valido: titular pasa a suplente (sin sustituciones); restaurar con el caso siguiente => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 0; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.22', 'plantel.formacion_jugador_modificar: Valido: titular pasa a suplente (sin sustituciones); restaurar con el caso siguiente', 0;
-- E-3.8.23 Valido: suplente vuelve a titular => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.23', 'plantel.formacion_jugador_modificar: Valido: suplente vuelve a titular', 0;
GO

PRINT '--- E-3.8.24 a E-3.8.25 plantel.formacion_jugador_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @fj INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug'),
        @fl INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fl_tit'),
        @ff INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fj_fin'),
        @base INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'base'),
        @elim INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'elim'),
        @zb   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'z_baja'),
        @fin  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'fin'),
        @sc   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sin_conv'),
        @l3   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'lib_3'),
        @ssale INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sust_sale'),
        @sent  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sust_entra'),
        @gol   INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'gol'),
        @asis  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'asis'),
        @tarj  INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'tarj');

-- E-3.8.24 Baja valida: jugador sin sustituciones, goles ni tarjetas => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @fj, @elim; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.24', 'plantel.formacion_jugador_eliminar: Baja valida: jugador sin sustituciones, goles ni tarjetas', 0;
-- E-3.8.25 Baja valida: jugador cuya convocatoria ya no esta vigente => se acepta
BEGIN TRY EXEC plantel.formacion_jugador_eliminar @fj, @zb; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.8.25', 'plantel.formacion_jugador_eliminar: Baja valida: jugador cuya convocatoria ya no esta vigente', 0;
GO

-- ============================================================
-- 3.9 evento.sustitucion
-- ============================================================

PRINT '--- E-3.9.01 a E-3.9.05 evento.sustitucion_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @C INT = (SELECT valor FROM torneo.parametro WHERE clave = 'cambios_max_reglamentarios'),
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @X INT = (SELECT valor FROM torneo.parametro WHERE clave = 'cambios_extra_alargue'),
        @W INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_extra_alargue'),
        @V1 INT, @V2 INT, @VW1 INT, @ul INT,
        @fo INT = (SELECT formacion_id FROM ##test_sustitucion WHERE clave = 'f_ok'),
        @fg INT = (SELECT formacion_id FROM ##test_sustitucion WHERE clave = 'f_gen'),
        @fa INT = (SELECT formacion_id FROM ##test_sustitucion WHERE clave = 'f_alg'),
        @fl INT = (SELECT formacion_id FROM ##test_sustitucion WHERE clave = 'f_lim'),
        @ff INT = (SELECT formacion_id FROM ##test_sustitucion WHERE clave = 'f_fin'),
        @fj INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug'),
        @ss INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sust_sale'),
        @se INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sust_entra'),
        @fu INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'fuera'),
        @ot1 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_t1'),
        @ot2 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_t2'),
        @ot3 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_t3'),
        @otl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_tl'),
        @os1 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_s1'),
        @os2 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_s2'),
        @os3 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_s3'),
        @os4 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_s4'),
        @osl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'ok_sl'),
        @gt1 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'gen_t1'),
        @gs1 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'gen_s1'),
        @gtl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'gen_tl'),
        @gtl2 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'gen_tl2'),
        @gsl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'gen_sl'),
        @gsl2 INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'gen_sl2'),
        @atl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'alg_tl'),
        @asl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'alg_sl'),
        @ltl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'lim_tl'),
        @lsl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'lim_sl'),
        @xtl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'fin_tl'),
        @xsl INT = (SELECT jugador_id FROM ##test_sustitucion WHERE clave = 'fin_sl');
SET @V1  = @V + 1;
SET @V2  = @V + 2;
SET @VW1 = @V + @W + 1;
SET @ul  = (SELECT MAX(numero_ventana) FROM evento.sustitucion WHERE formacion_id = @fl);   -- última ventana usada en lim (la del alargue)

-- E-3.9.01 Valido: minuto minimo de PT (borde), primera ventana => se acepta
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico',    @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.01', 'evento.sustitucion_insertar: Valido: minuto minimo de PT (borde), primera ventana', 0;
-- E-3.9.02 Valido: minuto maximo de PT (borde), misma ventana que el cambio anterior => se acepta
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion',     @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.02', 'evento.sustitucion_insertar: Valido: minuto maximo de PT (borde), misma ventana que el cambio anterior', 0;
-- E-3.9.03 Valido: reemplaza a quien ingresó antes (ejecutar despues del primero), minuto minimo de ST, ventana siguiente => se acepta
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.03', 'evento.sustitucion_insertar: Valido: reemplaza a quien ingresó antes (ejecutar despues del primero), minuto minimo de ST, ventana siguiente', 0;
-- E-3.9.04 Valido: minuto maximo de ST (borde), misma ventana => se acepta
BEGIN TRY EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico',    @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.04', 'evento.sustitucion_insertar: Valido: minuto maximo de ST (borde), misma ventana', 0;
-- E-3.9.05 Valido: primer cambio adicional del alargue, primera ventana adicional, minuto minimo de alargue_1 (borde) => se acepta
BEGIN TRY EXEC evento.sustitucion_insertar @fa, @atl, @asl, 90, 'alargue_1', @V1, 'tactico', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.05', 'evento.sustitucion_insertar: Valido: primer cambio adicional del alargue, primera ventana adicional, minuto minimo de alargue_1 (borde)', 0;
GO

PRINT '--- E-3.9.06 a E-3.9.10 evento.sustitucion_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @C INT = (SELECT valor FROM torneo.parametro WHERE clave = 'cambios_max_reglamentarios'),
        @V INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias'),
        @W INT = (SELECT valor FROM torneo.parametro WHERE clave = 'ventanas_extra_alargue'),
        @V1 INT, @VW1 INT, @ul INT, @mA INT, @mg INT,
        @fj INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug'),
        @ss INT = (SELECT jugador_id FROM ##test_fjugador WHERE clave = 'sust_sale'),
        @fl INT = (SELECT formacion_id FROM ##test_sustitucion WHERE clave = 'f_lim'),
        @m1 INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'gen_x1'),   -- PT, ventana 1
        @m2 INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'gen_x2'),   -- ST, ventana 2
        @mB INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'alg_x2'),   -- ST, ventana 2, en la formación con el máximo cargado
        @mf INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'fin_x1');   -- partido finalizado
SET @V1  = @V + 1;
SET @VW1 = @V + @W + 1;
SET @ul  = (SELECT MAX(numero_ventana) FROM evento.sustitucion WHERE formacion_id = @fl);
SET @mA  = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'lim_x' + CAST(@C + 1 AS VARCHAR(3)));   -- el cambio de alargue de lim
SET @mg  = (SELECT sustitucion_id FROM evento.sustitucion WHERE formacion_id = @fj AND jugador_sale_id = @ss);  -- NULL hasta registrar el cambio en la formación jug (ver más abajo)

-- E-3.9.06 Valido: cambia minuto y motivo => se acepta
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 25, 'PT', 1, 'lesion'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.06', 'evento.sustitucion_modificar: Valido: cambia minuto y motivo', 0;
-- E-3.9.07 Valido: minuto minimo de PT (borde) => se acepta
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 1,  'PT', 1, 'tactico'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.07', 'evento.sustitucion_modificar: Valido: minuto minimo de PT (borde)', 0;
-- E-3.9.08 Valido: minuto maximo de PT (borde) => se acepta
BEGIN TRY EXEC evento.sustitucion_modificar @m1, 60, 'PT', 1, 'precaucion'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.08', 'evento.sustitucion_modificar: Valido: minuto maximo de PT (borde)', 0;
-- E-3.9.09 Valido: minuto minimo de ST (borde) => se acepta
BEGIN TRY EXEC evento.sustitucion_modificar @m2, 45,  'ST', 2, 'tactico'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.09', 'evento.sustitucion_modificar: Valido: minuto minimo de ST (borde)', 0;
-- E-3.9.10 Valido: minuto maximo de ST (borde) => se acepta
BEGIN TRY EXEC evento.sustitucion_modificar @m2, 110, 'ST', 2, 'lesion'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.10', 'evento.sustitucion_modificar: Valido: minuto maximo de ST (borde)', 0;
GO

PRINT '--- E-3.9.11 a E-3.9.13 evento.sustitucion_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @e1 INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'eli_x1'),
        @e2 INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'eli_x2'),
        @e3 INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'eli_x3'),
        @ef INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'fin_x1'),
        @eg INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'gen_x1');

-- E-3.9.11 Baja valida: el que ingresó no fue reemplazado ni tiene goles => se acepta
BEGIN TRY EXEC evento.sustitucion_eliminar @e1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.11', 'evento.sustitucion_eliminar: Baja valida: el que ingresó no fue reemplazado ni tiene goles', 0;
-- E-3.9.12 Baja valida: cambio posterior sin consecuencias => se acepta
BEGIN TRY EXEC evento.sustitucion_eliminar @e3; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.12', 'evento.sustitucion_eliminar: Baja valida: cambio posterior sin consecuencias', 0;
-- E-3.9.13 Baja valida: ejecutar DESPUES de eliminar x3 => se acepta
BEGIN TRY EXEC evento.sustitucion_eliminar @e2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.9.13', 'evento.sustitucion_eliminar: Baja valida: ejecutar DESPUES de eliminar x3', 0;
GO

-- ============================================================
-- 3.10 evento.gol (cada operación actualiza el marcador del partido en la misma transacción)
-- ============================================================

PRINT '--- E-3.10.01 a E-3.10.30 evento.gol_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @fl INT = (SELECT formacion_id FROM ##test_gol WHERE clave = 'f_loc'),
        @fv INT = (SELECT formacion_id FROM ##test_gol WHERE clave = 'f_vis'),
        @fz INT = (SELECT formacion_id FROM ##test_gol WHERE clave = 'z_loc'),
        @fj INT = (SELECT formacion_id FROM ##test_gol WHERE clave = 'f_jug'),
        @t1 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_t1'),
        @t2 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_t2'),
        @t5 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_t5'),
        @si INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_s_in'),
        @so INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_s_out'),
        @lf INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_fuera'),
        @v1 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'vis_t1'),
        @v2 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'vis_t2'),
        @zt INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'z_t1'),
        @jg INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'jug_gol'),
        @ja INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'jug_asis');

-- E-3.10.01 Valido: con asistencia => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @t2, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.01', 'evento.gol_insertar: Valido: con asistencia', 0;
-- E-3.10.02 Valido: sin asistencia => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 16, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.02', 'evento.gol_insertar: Valido: sin asistencia', 0;
-- E-3.10.03 Valido: tipo penal => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 18, 'penal', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.03', 'evento.gol_insertar: Valido: tipo penal', 0;
-- E-3.10.04 Valido: tipo tiro_libre => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 19, 'tiro_libre', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.04', 'evento.gol_insertar: Valido: tipo tiro_libre', 0;
-- E-3.10.05 Valido: tipo cabezazo => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 20, 'cabezazo', 'PT', @t2, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.05', 'evento.gol_insertar: Valido: tipo cabezazo', 0;
-- E-3.10.06 Valido: tipo otro => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 21, 'otro', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.06', 'evento.gol_insertar: Valido: tipo otro', 0;
-- E-3.10.07 Valido: gol en contra sin asistencia (suma al rival) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 22, 'en_contra', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.07', 'evento.gol_insertar: Valido: gol en contra sin asistencia (suma al rival)', 0;
-- E-3.10.08 Valido: PT minuto minimo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 1, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.08', 'evento.gol_insertar: Valido: PT minuto minimo (borde)', 0;
-- E-3.10.09 Valido: PT minuto maximo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 45, 'jugada', 'PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.09', 'evento.gol_insertar: Valido: PT minuto maximo (borde)', 0;
-- E-3.10.10 Valido: adicional_PT minimo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 46, 'jugada', 'adicional_PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.10', 'evento.gol_insertar: Valido: adicional_PT minimo (borde)', 0;
-- E-3.10.11 Valido: adicional_PT maximo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 60, 'jugada', 'adicional_PT', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.11', 'evento.gol_insertar: Valido: adicional_PT maximo (borde)', 0;
-- E-3.10.12 Valido: ST minimo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 46, 'jugada', 'ST', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.12', 'evento.gol_insertar: Valido: ST minimo (borde)', 0;
-- E-3.10.13 Valido: ST maximo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 90, 'jugada', 'ST', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.13', 'evento.gol_insertar: Valido: ST maximo (borde)', 0;
-- E-3.10.14 Valido: adicional_ST minimo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 91, 'jugada', 'adicional_ST', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.14', 'evento.gol_insertar: Valido: adicional_ST minimo (borde)', 0;
-- E-3.10.15 Valido: adicional_ST maximo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 110, 'jugada', 'adicional_ST', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.15', 'evento.gol_insertar: Valido: adicional_ST maximo (borde)', 0;
-- E-3.10.16 Valido: alargue_1 minimo (borde; partido de fase final) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 91, 'jugada', 'alargue_1', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.16', 'evento.gol_insertar: Valido: alargue_1 minimo (borde; partido de fase final)', 0;
-- E-3.10.17 Valido: alargue_1 maximo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 105, 'jugada', 'alargue_1', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.17', 'evento.gol_insertar: Valido: alargue_1 maximo (borde)', 0;
-- E-3.10.18 Valido: alargue_2 minimo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 106, 'jugada', 'alargue_2', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.18', 'evento.gol_insertar: Valido: alargue_2 minimo (borde)', 0;
-- E-3.10.19 Valido: alargue_2 maximo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 120, 'jugada', 'alargue_2', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.19', 'evento.gol_insertar: Valido: alargue_2 maximo (borde)', 0;
-- E-3.10.20 Valido: adicional_alargue minimo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 106, 'jugada', 'adicional_alargue', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.20', 'evento.gol_insertar: Valido: adicional_alargue minimo (borde)', 0;
-- E-3.10.21 Valido: adicional_alargue maximo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 135, 'jugada', 'adicional_alargue', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.21', 'evento.gol_insertar: Valido: adicional_alargue maximo (borde)', 0;
-- E-3.10.22 Valido: tanda de penales minimo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 120, 'penal', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.22', 'evento.gol_insertar: Valido: tanda de penales minimo (borde)', 0;
-- E-3.10.23 Valido: tanda de penales maximo (borde) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 135, 'penal', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.23', 'evento.gol_insertar: Valido: tanda de penales maximo (borde)', 0;
-- E-3.10.24 Valido: gol del visitante con asistencia => se acepta
BEGIN TRY EXEC evento.gol_insertar @fv, @v1, 30, 'jugada', 'PT', @v2, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.24', 'evento.gol_insertar: Valido: gol del visitante con asistencia', 0;
-- E-3.10.25 Valido: penal del visitante en la tanda => se acepta
BEGIN TRY EXEC evento.gol_insertar @fv, @v1, 125, 'penal', 'penales', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.25', 'evento.gol_insertar: Valido: penal del visitante en la tanda', 0;
-- E-3.10.26 Valido: autor suplente que ingreso por sustitucion => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @si, 75, 'jugada', 'ST', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.26', 'evento.gol_insertar: Valido: autor suplente que ingreso por sustitucion', 0;
-- E-3.10.27 Valido: asistente suplente que ingreso => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 76, 'jugada', 'ST', @si, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.27', 'evento.gol_insertar: Valido: asistente suplente que ingreso', 0;
-- E-3.10.28 Valido: autor titular (que luego sale por sustitucion) => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t5, 12, 'jugada', 'PT', @t2, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.28', 'evento.gol_insertar: Valido: autor titular (que luego sale por sustitucion)', 0;
-- E-3.10.29 Valido: asistente titular que sale por sustitucion => se acepta
BEGIN TRY EXEC evento.gol_insertar @fl, @t1, 13, 'jugada', 'PT', @t5, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.29', 'evento.gol_insertar: Valido: asistente titular que sale por sustitucion', 0;
-- E-3.10.30 Valido: partido de fase de grupos con periodo regular => se acepta
BEGIN TRY EXEC evento.gol_insertar @fj, @jg, 40, 'jugada', 'PT', @ja, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.30', 'evento.gol_insertar: Valido: partido de fase de grupos con periodo regular', 0;
GO

PRINT '--- E-3.10.31 a E-3.10.35 evento.gol_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @gm INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_mod'),
        @gs INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_sup'),
        @gp INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_pen'),
        @gv INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_vis'),
        @ge INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_ec'),
        @gf INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_fin'),
        @gj INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_jug'),
        @t1 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_t1'),
        @t2 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_t2'),
        @t3 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_t3'),
        @t5 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_t5'),
        @si INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_s_in'),
        @so INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_s_out'),
        @lf INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'loc_fuera'),
        @v1 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'vis_t1'),
        @v2 INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'vis_t2'),
        @ja INT = (SELECT jugador_id FROM ##test_gol WHERE clave = 'jug_asis');

-- E-3.10.31 Valido: cambia minuto y tipo => se acepta
BEGIN TRY EXEC evento.gol_modificar @gm, 12, 'cabezazo', 'PT', @t2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.31', 'evento.gol_modificar: Valido: cambia minuto y tipo', 0;
-- E-3.10.32 Valido: cambia el asistente => se acepta
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @t3; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.32', 'evento.gol_modificar: Valido: cambia el asistente', 0;
-- E-3.10.33 Valido: asistente suplente que ingreso por sustitucion => se acepta
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @si; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.33', 'evento.gol_modificar: Valido: asistente suplente que ingreso por sustitucion', 0;
-- E-3.10.34 Valido: asistente titular que sale por sustitucion => se acepta
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @t5; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.34', 'evento.gol_modificar: Valido: asistente titular que sale por sustitucion', 0;
-- E-3.10.35 Valido: quita la asistencia => se acepta
BEGIN TRY EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.35', 'evento.gol_modificar: Valido: quita la asistencia', 0;
GO

PRINT '--- E-3.10.36 a E-3.10.39 evento.gol_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ge1 INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_elim'),
        @ge2 INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_elim2'),
        @ge3 INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_elim3'),
        @ge4 INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_elim4'),
        @gf  INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_fin');

-- E-3.10.36 Baja valida: gol con asistencia de un partido no finalizado (baja el marcador local) => se acepta
BEGIN TRY EXEC evento.gol_eliminar @ge1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.36', 'evento.gol_eliminar: Baja valida: gol con asistencia de un partido no finalizado (baja el marcador local)', 0;
-- E-3.10.37 Baja valida: gol sin asistencia (cabezazo) => se acepta
BEGIN TRY EXEC evento.gol_eliminar @ge2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.37', 'evento.gol_eliminar: Baja valida: gol sin asistencia (cabezazo)', 0;
-- E-3.10.38 Baja valida: gol en contra (baja el marcador del rival) => se acepta
BEGIN TRY EXEC evento.gol_eliminar @ge3; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.38', 'evento.gol_eliminar: Baja valida: gol en contra (baja el marcador del rival)', 0;
-- E-3.10.39 Baja valida: gol de la tanda de penales (baja los penales del visitante) => se acepta
BEGIN TRY EXEC evento.gol_eliminar @ge4; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.10.39', 'evento.gol_eliminar: Baja valida: gol de la tanda de penales (baja los penales del visitante)', 0;
GO

-- ============================================================
-- 3.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================

PRINT '--- E-3.11.01 a E-3.11.12 evento.tarjeta_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @pt INT = (SELECT partido_id FROM ##test_tarjeta WHERE clave = 'pt_tar'),
        @pz INT = (SELECT partido_id FROM ##test_tarjeta WHERE clave = 'pt_z'),
        @pm INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'mod'),
        @a1  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_a1'),
        @a2  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_a2'),
        @rj  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_mr'),
        @dob INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_dob'),
        @tu  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_titu'),
        @su  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_supl'),
        @vi  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_vis'),
        @cv  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_ctv'),
        @zl  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_zlim'),
        @cn  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_conv'),   -- solo para casos de error (partido de grupos)
        @gl  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_gol'),
        @np  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_np'),
        @le  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_err'),    -- solo para casos de error: no darlo de alta
        @ea  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'u_ea'),     -- solo para casos de error: ya tiene una amarilla
        @l1  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_1'),
        @l2  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_2'),
        @l3  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_3'),
        @l4  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_4'),
        @l5  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_5'),
        @l6  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_6'),
        @l7  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_7'),
        @l8  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_8'),
        @l9  INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_9'),
        @l10 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_10'),
        @l11 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_11'),
        @l12 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_12'),
        @l13 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_13'),
        @l14 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_14'),
        @l15 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_15'),
        @l16 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_16'),
        @l17 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_17'),
        @l18 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_18'),
        @l19 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_19'),
        @l20 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_20'),
        @l21 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_21'),
        @l22 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_22'),
        @l23 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_23'),
        @l24 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_24'),
        @l25 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_25'),
        @l26 INT = (SELECT persona_id FROM ##test_tarjeta WHERE clave = 'l_26');

-- E-3.11.01 Valido: amarilla con motivo => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l1, 15, 'PT', 'amarilla', 'Falta', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.01', 'evento.tarjeta_insertar: Valido: amarilla con motivo', 0;
-- E-3.11.02 Valido: motivo se guarda recortado => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l2, 16, 'PT', 'amarilla', '  Motivo con espacios  ', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.02', 'evento.tarjeta_insertar: Valido: motivo se guarda recortado', 0;
-- E-3.11.03 Valido: motivo nulo => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l3, 17, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.03', 'evento.tarjeta_insertar: Valido: motivo nulo', 0;
-- E-3.11.04 Valido: motivo vacio se guarda como NULL => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l4, 18, 'PT', 'amarilla', '', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.04', 'evento.tarjeta_insertar: Valido: motivo vacio se guarda como NULL', 0;
-- E-3.11.05 Valido: motivo solo espacios se guarda como NULL => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l5, 19, 'PT', 'amarilla', '   ', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.05', 'evento.tarjeta_insertar: Valido: motivo solo espacios se guarda como NULL', 0;
-- E-3.11.06 Valido: sin pasar motivo ni tipo de expulsion (valores por defecto) => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l6, 20, 'PT', 'amarilla', @tarjeta_id = @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.06', 'evento.tarjeta_insertar: Valido: sin pasar motivo ni tipo de expulsion (valores por defecto)', 0;
-- E-3.11.07 Valido: roja directa con motivo => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l7, 50, 'ST', 'roja', 'Agresion', 'roja_directa', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.07', 'evento.tarjeta_insertar: Valido: roja directa con motivo', 0;
-- E-3.11.08 Valido: roja directa sin motivo => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l8, 51, 'ST', 'roja', NULL, 'roja_directa', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.08', 'evento.tarjeta_insertar: Valido: roja directa sin motivo', 0;
-- E-3.11.09 Valido: segunda amarilla registrada como roja (la persona tiene una amarilla previa) => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @a1, 70, 'ST', 'roja', 'Segunda amarilla', 'doble_amarilla', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.09', 'evento.tarjeta_insertar: Valido: segunda amarilla registrada como roja (la persona tiene una amarilla previa)', 0;
-- E-3.11.10 Valido: roja directa a quien ya tenia una amarilla => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @a2, 71, 'ST', 'roja', 'Agresion', 'roja_directa', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.10', 'evento.tarjeta_insertar: Valido: roja directa a quien ya tenia una amarilla', 0;
-- E-3.11.11 Valido: PT minuto minimo (borde) => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l9, 1, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.11', 'evento.tarjeta_insertar: Valido: PT minuto minimo (borde)', 0;
-- E-3.11.12 Valido: PT minuto maximo (borde) => se acepta
BEGIN TRY EXEC evento.tarjeta_insertar @pt, @l10, 45, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.12', 'evento.tarjeta_insertar: Valido: PT minuto maximo (borde)', 0;
GO

PRINT '--- E-3.11.13 a E-3.11.16 evento.tarjeta_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @tm  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_mod'),
        @tmr INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_modr'),
        @tj  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_jug'),
        @tf  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_fin');

-- E-3.11.13 Valido: cambia minuto y motivo => se acepta
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 12, 'PT', 'Falta tactica'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.13', 'evento.tarjeta_modificar: Valido: cambia minuto y motivo', 0;
-- E-3.11.14 Valido: sin cambios (deja la tarjeta como en la preparacion) => se acepta
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 10, 'PT', 'Falta'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.14', 'evento.tarjeta_modificar: Valido: sin cambios (deja la tarjeta como en la preparacion)', 0;
-- E-3.11.15 Valido: cambia el periodo (restaurar con el caso anterior) => se acepta
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 50, 'ST', 'Falta'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.15', 'evento.tarjeta_modificar: Valido: cambia el periodo (restaurar con el caso anterior)', 0;
-- E-3.11.16 Valido: motivo se guarda recortado => se acepta
BEGIN TRY EXEC evento.tarjeta_modificar @tm, 10, 'PT', '  Motivo  '; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.16', 'evento.tarjeta_modificar: Valido: motivo se guarda recortado', 0;
GO

PRINT '--- E-3.11.17 a E-3.11.20 evento.tarjeta_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @te  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_elim'),
        @te2 INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_elim2'),
        @tda INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_dob_a'),
        @tdr INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_dob_r'),
        @tf  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_fin'),
        @ts  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_susp');

-- E-3.11.17 Baja valida: amarilla de un partido no finalizado, sin suspensiones => se acepta
BEGIN TRY EXEC evento.tarjeta_eliminar @te; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.17', 'evento.tarjeta_eliminar: Baja valida: amarilla de un partido no finalizado, sin suspensiones', 0;
-- E-3.11.18 Baja valida: roja directa sin suspensiones => se acepta
BEGIN TRY EXEC evento.tarjeta_eliminar @te2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.18', 'evento.tarjeta_eliminar: Baja valida: roja directa sin suspensiones', 0;
-- E-3.11.19 Baja valida: roja por doble amarilla => se acepta
BEGIN TRY EXEC evento.tarjeta_eliminar @tdr; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.19', 'evento.tarjeta_eliminar: Baja valida: roja por doble amarilla', 0;
-- E-3.11.20 Baja valida: la amarilla ya no tiene la roja por doble amarilla (ejecutar DESPUES de dar de baja la roja) => se acepta
BEGIN TRY EXEC evento.tarjeta_eliminar @tda; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.20', 'evento.tarjeta_eliminar: Baja valida: la amarilla ya no tiene la roja por doble amarilla (ejecutar DESPUES de dar de baja la roja)', 0;
GO

PRINT '--- E-3.11.21 a E-3.11.26 evento.criterio_suspension_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT;

-- E-3.11.21 Valido: criterio con fase y tipo de persona => se acepta
BEGIN TRY EXEC evento.criterio_suspension_insertar 92, 1, 'grupos', 'jugador', 1, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.21', 'evento.criterio_suspension_insertar: Valido: criterio con fase y tipo de persona', 0;
-- E-3.11.22 Valido: fase grupos => se acepta
BEGIN TRY EXEC evento.criterio_suspension_insertar 95, 1, 'grupos', NULL, 1, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.22', 'evento.criterio_suspension_insertar: Valido: fase grupos', 0;
-- E-3.11.23 Valido: fase dieciseisavos => se acepta
BEGIN TRY EXEC evento.criterio_suspension_insertar 95, 1, 'dieciseisavos', NULL, 1, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.23', 'evento.criterio_suspension_insertar: Valido: fase dieciseisavos', 0;
-- E-3.11.24 Valido: fase semifinal => se acepta
BEGIN TRY EXEC evento.criterio_suspension_insertar 95, 1, 'semifinal', NULL, 1, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.24', 'evento.criterio_suspension_insertar: Valido: fase semifinal', 0;
-- E-3.11.25 Valido: fase tercer_puesto => se acepta
BEGIN TRY EXEC evento.criterio_suspension_insertar 95, 1, 'tercer_puesto', NULL, 1, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.25', 'evento.criterio_suspension_insertar: Valido: fase tercer_puesto', 0;
-- E-3.11.26 Valido: fase final => se acepta
BEGIN TRY EXEC evento.criterio_suspension_insertar 95, 1, 'final', NULL, 1, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.26', 'evento.criterio_suspension_insertar: Valido: fase final', 0;
GO

PRINT '--- E-3.11.27 a E-3.11.30 evento.criterio_suspension_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @cm  INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'mod'),
        @cu  INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'usado');

-- E-3.11.27 Valido: cambia los partidos de suspension => se acepta
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 90, 3, 'grupos', 'jugador', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.27', 'evento.criterio_suspension_modificar: Valido: cambia los partidos de suspension', 0;
-- E-3.11.28 Valido: sin cambios (no choca consigo mismo; deja el criterio como en la preparacion) => se acepta
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 90, 1, 'grupos', 'jugador', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.28', 'evento.criterio_suspension_modificar: Valido: sin cambios (no choca consigo mismo; deja el criterio como en la preparacion)', 0;
-- E-3.11.29 Valido: cambia la cantidad de amarillas => se acepta
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'grupos', 'jugador', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.29', 'evento.criterio_suspension_modificar: Valido: cambia la cantidad de amarillas', 0;
-- E-3.11.30 Valido: cambia la fase => se acepta
BEGIN TRY EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'octavos', 'jugador', 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.30', 'evento.criterio_suspension_modificar: Valido: cambia la fase', 0;
GO

PRINT '--- E-3.11.31 a E-3.11.32 evento.criterio_suspension_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.16 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ce  INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'elim'),
        @ce2 INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'elim2'),
        @cu  INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'usado');

-- E-3.11.31 Baja valida: criterio activo sin suspensiones => se acepta
BEGIN TRY EXEC evento.criterio_suspension_eliminar @ce; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.31', 'evento.criterio_suspension_eliminar: Baja valida: criterio activo sin suspensiones', 0;
-- E-3.11.32 Baja valida: criterio inactivo sin suspensiones => se acepta
BEGIN TRY EXEC evento.criterio_suspension_eliminar @ce2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.32', 'evento.criterio_suspension_eliminar: Baja valida: criterio inactivo sin suspensiones', 0;
GO

PRINT '--- P-3.17 Preparación de evento.suspension_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- Requiere las preparaciones de plantel.formacion_* (partido 'jug', anterior), evento.tarjeta_* (partido pt_tar) y
-- evento.criterio_suspension_* (criterio 'usado'). Crea tres integrantes del cuerpo técnico de ZCA con tarjetas en pt_tar,
-- una selección rival (ZDA) y cuatro partidos posteriores; el partido 'fin' queda finalizado.
IF OBJECT_ID('tempdb..##test_suspension') IS NULL
    CREATE TABLE ##test_suspension (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY, id INT NOT NULL);
GO
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @pt INT = (SELECT partido_id FROM ##test_tarjeta WHERE clave = 'pt_tar'),
        @pant INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'jug'),
        @cu INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'usado'),
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
INSERT INTO ##test_suspension (clave, id) VALUES
 ('pa1', @pa1), ('pa2', @pa2), ('pb', @pb), ('pf', @pf), ('pant', @pant), ('t_roja', @tr), ('t_amar', @ta), ('t_mod', @tm);
EXEC evento.suspension_insertar @tm, 'Roja directa', NULL, @pa1, @id OUTPUT;                 INSERT INTO ##test_suspension VALUES ('mod',  @id);  -- a modificar
EXEC evento.suspension_insertar @tm, 'Roja directa (segunda fecha)', NULL, @pa2, @id OUTPUT; INSERT INTO ##test_suspension VALUES ('otra', @id);  -- destino de duplicados
EXEC evento.suspension_insertar @tr, 'Roja directa', NULL, @pa2, @id OUTPUT;                 INSERT INTO ##test_suspension VALUES ('elim', @id);  -- baja válida
EXEC evento.suspension_insertar @tm, 'Roja directa (cumplida)', NULL, @pf, @id OUTPUT;       INSERT INTO ##test_suspension VALUES ('fin',  @id);  -- partido finalizado
EXEC evento.suspension_insertar @ta, 'Acumulacion de amarillas', @cu, @pa2, @id OUTPUT;     INSERT INTO ##test_suspension VALUES ('crit', @id);  -- usa el criterio 'usado'
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pf;
GO

PRINT '--- E-3.11.33 a E-3.11.35 evento.suspension_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @tr INT = (SELECT id FROM ##test_suspension WHERE clave = 't_roja'),
        @ta INT = (SELECT id FROM ##test_suspension WHERE clave = 't_amar'),
        @tm INT = (SELECT id FROM ##test_suspension WHERE clave = 't_mod'),
        @pa1 INT = (SELECT id FROM ##test_suspension WHERE clave = 'pa1'),
        @pa2 INT = (SELECT id FROM ##test_suspension WHERE clave = 'pa2'),
        @pb INT = (SELECT id FROM ##test_suspension WHERE clave = 'pb'),
        @pant INT = (SELECT id FROM ##test_suspension WHERE clave = 'pant'),
        @cu INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'usado');

-- E-3.11.33 Valido: expulsion sin criterio, con partido afectado => se acepta
BEGIN TRY EXEC evento.suspension_insertar @tr, 'Roja directa', NULL, @pa1, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.33', 'evento.suspension_insertar: Valido: expulsion sin criterio, con partido afectado', 0;
-- E-3.11.34 Valido: amarilla con criterio y partido a definir (NULL) => se acepta
BEGIN TRY EXEC evento.suspension_insertar @ta, 'Acumulacion de amarillas', @cu, NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.34', 'evento.suspension_insertar: Valido: amarilla con criterio y partido a definir (NULL)', 0;
-- E-3.11.35 Valido: el motivo se guarda recortado => se acepta
BEGIN TRY EXEC evento.suspension_insertar @tr, '  Motivo con espacios  ', NULL, NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.35', 'evento.suspension_insertar: Valido: el motivo se guarda recortado', 0;
GO

PRINT '--- E-3.11.36 a E-3.11.38 evento.suspension_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @sm INT = (SELECT id FROM ##test_suspension WHERE clave = 'mod'),
        @pa1 INT = (SELECT id FROM ##test_suspension WHERE clave = 'pa1'),
        @pa2 INT = (SELECT id FROM ##test_suspension WHERE clave = 'pa2'),
        @pb INT = (SELECT id FROM ##test_suspension WHERE clave = 'pb'),
        @pant INT = (SELECT id FROM ##test_suspension WHERE clave = 'pant');

-- E-3.11.36 Valido: cambia el motivo (el mismo partido no choca consigo misma) => se acepta
BEGIN TRY EXEC evento.suspension_modificar @sm, 'Roja directa: sancion de oficio', @pa1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.36', 'evento.suspension_modificar: Valido: cambia el motivo (el mismo partido no choca consigo misma)', 0;
-- E-3.11.37 Valido: partido afectado a definir (NULL) => se acepta
BEGIN TRY EXEC evento.suspension_modificar @sm, 'Roja directa', NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.37', 'evento.suspension_modificar: Valido: partido afectado a definir (NULL)', 0;
-- E-3.11.38 Restaurar: vuelve a pa1 (el motivo se guarda recortado) => se acepta
BEGIN TRY EXEC evento.suspension_modificar @sm, '  Roja directa  ', @pa1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.38', 'evento.suspension_modificar: Restaurar: vuelve a pa1 (el motivo se guarda recortado)', 0;
GO

PRINT '--- E-3.11.39 evento.suspension_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.17 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @se INT = (SELECT id FROM ##test_suspension WHERE clave = 'elim'),
        @sf INT = (SELECT id FROM ##test_suspension WHERE clave = 'fin');

-- E-3.11.39 Baja valida: el partido afectado no se jugo => se acepta
BEGIN TRY EXEC evento.suspension_eliminar @se; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.11.39', 'evento.suspension_eliminar: Baja valida: el partido afectado no se jugo', 0;
GO

-- ============================================================
-- 3.12 arbitraje: arbitro, arbitro_idioma, designacion_arbitral e informe_arbitral
-- ============================================================

PRINT '--- P-3.18 Preparación de arbitraje.* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
-- No requiere otras preparaciones. Países ZAA/ZAB sin selección (árbitros) y ZAL, ZAV, ZAX, ZAY con selección;
-- partidos en 2031: pg (ZAL vs ZAV, grupos), pc (ZAX vs ZAY, 3 horas después), pfin (cuartos, se finaliza) y
-- pd (dieciseisavos). Designaciones e informes de base en pg, pc y pfin.
IF OBJECT_ID('tempdb..##test_arbitraje') IS NULL
    CREATE TABLE ##test_arbitraje (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY, id INT NOT NULL);
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
INSERT INTO ##test_arbitraje (clave, id) VALUES ('pg', @pg), ('pc', @pc), ('pfin', @pfin), ('pd', @pd);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Base',      @pa, 'FIFA', '1985-05-10', @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_base', @id);   -- designado en pg y pfin
EXEC arbitraje.arbitro_idioma_insertar @id, 'espanol';
EXEC arbitraje.arbitro_idioma_insertar @id, 'ingles';
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Mod',       @pa, 'confederacion', '1980-01-01', @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_mod', @id);
EXEC arbitraje.arbitro_idioma_insertar @id, 'aleman';
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Otro',      @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_otro', @id);    -- destino de duplicados
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Elim',      @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_elim', @id);    -- baja válida (con un idioma)
EXEC arbitraje.arbitro_idioma_insertar @id, 'italiano';
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Conflicto', @pl, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_conf', @id);    -- país de una selección de pg
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Libre',     @pb, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_libre', @id);   -- sin designaciones
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Libre Dos', @pb, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_libre2', @id);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Adv',       @px, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_adv', @id);     -- país con selección en competencia
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Inf',       @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_inf', @id);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'DMod',      @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_dmod', @id);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'DElim',     @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_delim', @id);
EXEC arbitraje.arbitro_insertar 'Test Arb', 'PC',        @pa, 'FIFA', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_pc', @id);
DECLARE @a_base INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_base'),
        @a_inf INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_inf'),
        @a_dmod INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_dmod'),
        @a_delim INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_delim'),
        @a_pc INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_pc');
EXEC arbitraje.designacion_arbitral_insertar @pg,   @a_base,  'principal',   @d OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_base', @d);
EXEC arbitraje.designacion_arbitral_insertar @pg,   @a_inf,   'asistente_1', @d OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_inf', @d);    -- con informes
EXEC arbitraje.designacion_arbitral_insertar @pg,   @a_dmod,  'cuarto',      @d OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_mod', @d);    -- a modificar
EXEC arbitraje.designacion_arbitral_insertar @pg,   @a_delim, 'var',         @d OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_elim', @d);   -- baja válida
EXEC arbitraje.designacion_arbitral_insertar @pc,   @a_pc,    'principal',   @d OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_pc', @d);
EXEC arbitraje.designacion_arbitral_insertar @pfin, @a_base,  'principal',   @d OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_fin', @d);    -- finalizado, con informe
EXEC arbitraje.informe_arbitral_insertar @d, '2031-01-30 20:00:00 +00:00', 'Informe del partido finalizado', NULL, @id OUTPUT;
EXEC arbitraje.designacion_arbitral_insertar @pfin, @a_dmod,  'var',         @d OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_fin2', @d);   -- finalizado, sin informe
SET @d = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_inf');
EXEC arbitraje.informe_arbitral_insertar @d, '2031-01-10 20:00:00 +00:00', 'Informe base', NULL, @id OUTPUT;       INSERT INTO ##test_arbitraje VALUES ('i_base', @id);
EXEC arbitraje.informe_arbitral_insertar @d, '2031-01-10 21:00:00 +00:00', 'Informe a eliminar', NULL, @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('i_elim', @id);
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pfin;
GO

PRINT '--- E-3.12.01 a E-3.12.07 arbitraje.arbitro_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAB'),
        @f18 DATE = DATEADD(YEAR, -18, CAST(SYSDATETIME() AS DATE)),
        @f70 DATE = DATEADD(YEAR, -70, CAST(SYSDATETIME() AS DATE)),
        @f18_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -18, CAST(SYSDATETIME() AS DATE))),
        @f70_mas DATE = DATEADD(DAY, -1, DATEADD(YEAR, -70, CAST(SYSDATETIME() AS DATE))),
        @n100 VARCHAR(100) = 'Test Arb' + REPLICATE('N', 92);

-- E-3.12.01 Valido => se acepta
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta', @pa, 'FIFA', '1985-01-01', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.01', 'arbitraje.arbitro_insertar: Valido', 0;
-- E-3.12.02 Valido: categoria confederacion y sin fecha de nacimiento => se acepta
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Confederacion', @pa, 'confederacion', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.02', 'arbitraje.arbitro_insertar: Valido: categoria confederacion y sin fecha de nacimiento', 0;
-- E-3.12.03 Valido: nombre y apellido se guardan recortados => se acepta
BEGIN TRY EXEC arbitraje.arbitro_insertar '  Test Arb  ', '  Recortado  ', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.03', 'arbitraje.arbitro_insertar: Valido: nombre y apellido se guardan recortados', 0;
-- E-3.12.04 Valido: justo 18 anios (borde) => se acepta
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Borde 18', @pa, 'FIFA', @f18, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.04', 'arbitraje.arbitro_insertar: Valido: justo 18 anios (borde)', 0;
-- E-3.12.05 Valido: justo 70 anios (borde) => se acepta
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Borde 70', @pa, 'FIFA', @f70, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.05', 'arbitraje.arbitro_insertar: Valido: justo 70 anios (borde)', 0;
-- E-3.12.06 Valido: mismo nombre y apellido en otro pais => se acepta
BEGIN TRY EXEC arbitraje.arbitro_insertar 'Test Arb', 'Base', @pb, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.06', 'arbitraje.arbitro_insertar: Valido: mismo nombre y apellido en otro pais', 0;
-- E-3.12.07 Valido: nombre de 100 caracteres (borde) => se acepta
BEGIN TRY EXEC arbitraje.arbitro_insertar @n100, 'Nombre Largo', @pa, 'FIFA', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.07', 'arbitraje.arbitro_insertar: Valido: nombre de 100 caracteres (borde)', 0;
GO

PRINT '--- E-3.12.08 a E-3.12.11 arbitraje.arbitro_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @m INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_mod'),
        @b INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_base'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAA'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAB'),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZAL'),
        @f18_menos DATE = DATEADD(DAY, 1, DATEADD(YEAR, -18, CAST(SYSDATETIME() AS DATE))),
        @f70_mas DATE = DATEADD(DAY, -1, DATEADD(YEAR, -70, CAST(SYSDATETIME() AS DATE)));

-- E-3.12.08 Valido: cambia apellido, pais, categoria y fecha => se acepta
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod Nuevo', @pb, 'FIFA', '1990-02-02'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.08', 'arbitraje.arbitro_modificar: Valido: cambia apellido, pais, categoria y fecha', 0;
-- E-3.12.09 Valido: pais con seleccion, sin designaciones en sus partidos => se acepta
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pl, 'confederacion', '1980-01-01'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.09', 'arbitraje.arbitro_modificar: Valido: pais con seleccion, sin designaciones en sus partidos', 0;
-- E-3.12.10 Valido: sin fecha de nacimiento => se acepta
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pa, 'confederacion', NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.10', 'arbitraje.arbitro_modificar: Valido: sin fecha de nacimiento', 0;
-- E-3.12.11 Restaurar: deja Mod como estaba => se acepta
BEGIN TRY EXEC arbitraje.arbitro_modificar @m, 'Test Arb', 'Mod', @pa, 'confederacion', '1980-01-01'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.11', 'arbitraje.arbitro_modificar: Restaurar: deja Mod como estaba', 0;
GO

PRINT '--- E-3.12.12 arbitraje.arbitro_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @e INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_elim'),
        @b INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_base');

-- E-3.12.12 Baja valida: arbitro sin designaciones (se eliminan tambien sus idiomas) => se acepta
BEGIN TRY EXEC arbitraje.arbitro_eliminar @e; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.12', 'arbitraje.arbitro_eliminar: Baja valida: arbitro sin designaciones (se eliminan tambien sus idiomas)', 0;
GO

PRINT '--- E-3.12.13 a E-3.12.15 arbitraje.arbitro_idioma_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @l INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_libre'),
        @b INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_base');

-- E-3.12.13 Valido => se acepta
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, 'aleman'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.13', 'arbitraje.arbitro_idioma_insertar: Valido', 0;
-- E-3.12.14 Valido: se guarda en minusculas => se acepta
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, 'FRANCES'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.14', 'arbitraje.arbitro_idioma_insertar: Valido: se guarda en minusculas', 0;
-- E-3.12.15 Valido: idioma de 10 letras (borde) => se acepta
BEGIN TRY EXEC arbitraje.arbitro_idioma_insertar @l, 'portuguesa'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.15', 'arbitraje.arbitro_idioma_insertar: Valido: idioma de 10 letras (borde)', 0;
GO

PRINT '--- E-3.12.16 a E-3.12.18 arbitraje.arbitro_idioma_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @b INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_base');

-- E-3.12.16 Valido: reemplaza ingles por frances => se acepta
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', 'frances'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.16', 'arbitraje.arbitro_idioma_modificar: Valido: reemplaza ingles por frances', 0;
-- E-3.12.17 Restaurar: vuelve a ingles => se acepta
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'frances', 'ingles'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.17', 'arbitraje.arbitro_idioma_modificar: Restaurar: vuelve a ingles', 0;
-- E-3.12.18 Valido: el mismo idioma (no choca consigo mismo) => se acepta
BEGIN TRY EXEC arbitraje.arbitro_idioma_modificar @b, 'ingles', 'INGLES'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.18', 'arbitraje.arbitro_idioma_modificar: Valido: el mismo idioma (no choca consigo mismo)', 0;
GO

PRINT '--- E-3.12.19 arbitraje.arbitro_idioma_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @m INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_mod'),
        @b INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_base');

-- E-3.12.19 Baja valida => se acepta
BEGIN TRY EXEC arbitraje.arbitro_idioma_eliminar @m, 'aleman'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.19', 'arbitraje.arbitro_idioma_eliminar: Baja valida', 0;
GO

PRINT '--- E-3.12.20 a E-3.12.22 arbitraje.designacion_arbitral_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT, @adv VARCHAR(500),
        @pg INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pg'),
        @pc INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pc'),
        @pd INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pd'),
        @pf INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pfin'),
        @b INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_base'),
        @l INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_libre'),
        @l2 INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_libre2'),
        @cf INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_conf'),
        @ad INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_adv');

-- E-3.12.20 Valido => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pg, @l, 'asistente_2', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.20', 'arbitraje.designacion_arbitral_insertar: Valido', 0;
-- E-3.12.21 Valido: con ADVERTENCIA (pais del arbitro con seleccion en competencia, desde dieciseisavos) => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pd, @ad, 'principal', @id OUTPUT, @adv OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.21', 'arbitraje.designacion_arbitral_insertar: Valido: con ADVERTENCIA (pais del arbitro con seleccion en competencia, desde dieciseisavos)', 0;
-- E-3.12.22 Valido: eliminacion directa sin advertencia (pais sin seleccion) => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_insertar @pd, @l2, 'var', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.22', 'arbitraje.designacion_arbitral_insertar: Valido: eliminacion directa sin advertencia (pais sin seleccion)', 0;
GO

PRINT '--- E-3.12.23 a E-3.12.27 arbitraje.designacion_arbitral_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @dm INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_mod'),
        @di INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_inf'),
        @dpc INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_pc'),
        @adm INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_dmod'),
        @apc INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_pc'),
        @b INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_base'),
        @l INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_libre'),
        @l2 INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_libre2'),
        @cf INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_conf');

-- E-3.12.23 Valido: sin cambios (no choca consigo misma) => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @adm, 'cuarto'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.23', 'arbitraje.designacion_arbitral_modificar: Valido: sin cambios (no choca consigo misma)', 0;
-- E-3.12.24 Valido: reemplaza al arbitro (la designacion no tiene informes) => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @l2, 'cuarto'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.24', 'arbitraje.designacion_arbitral_modificar: Valido: reemplaza al arbitro (la designacion no tiene informes)', 0;
-- E-3.12.25 Restaurar: vuelve el arbitro original => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dm, @adm, 'cuarto'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.25', 'arbitraje.designacion_arbitral_modificar: Restaurar: vuelve el arbitro original', 0;
-- E-3.12.26 Valido: cambia el rol => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dpc, @apc, 'cuarto'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.26', 'arbitraje.designacion_arbitral_modificar: Valido: cambia el rol', 0;
-- E-3.12.27 Restaurar: vuelve el rol original => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_modificar @dpc, @apc, 'principal'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.27', 'arbitraje.designacion_arbitral_modificar: Restaurar: vuelve el rol original', 0;
GO

PRINT '--- E-3.12.28 arbitraje.designacion_arbitral_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @de INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_elim'),
        @di INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_inf'),
        @df INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_fin'),
        @df2 INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_fin2');

-- E-3.12.28 Baja valida: sin informes y con el partido sin jugar => se acepta
BEGIN TRY EXEC arbitraje.designacion_arbitral_eliminar @de; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.28', 'arbitraje.designacion_arbitral_eliminar: Baja valida: sin informes y con el partido sin jugar', 0;
GO

PRINT '--- E-3.12.29 a E-3.12.31 arbitraje.informe_arbitral_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @id INT,
        @db INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_base'),
        @ini DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM ##test_arbitraje WHERE clave = 'pg')),
        @antes DATETIMEOFFSET = DATEADD(MINUTE, -1, (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM ##test_arbitraje WHERE clave = 'pg')));

-- E-3.12.29 Valido: con sancion => se acepta
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, '2031-01-10 20:00:00 +00:00', 'Partido sin incidentes', 'Apercibimiento', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.29', 'arbitraje.informe_arbitral_insertar: Valido: con sancion', 0;
-- E-3.12.30 Valido: sin sancion => se acepta
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, '2031-01-10 20:30:00 +00:00', 'Segundo informe', NULL, @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.30', 'arbitraje.informe_arbitral_insertar: Valido: sin sancion', 0;
-- E-3.12.31 Valido: fecha igual al inicio del partido (borde); la sancion vacia se guarda NULL => se acepta
BEGIN TRY EXEC arbitraje.informe_arbitral_insertar @db, @ini, 'Informe al inicio del partido', '', @id OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.31', 'arbitraje.informe_arbitral_insertar: Valido: fecha igual al inicio del partido (borde); la sancion vacia se guarda NULL', 0;
GO

PRINT '--- E-3.12.32 a E-3.12.34 arbitraje.informe_arbitral_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ib INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'i_base'),
        @ini DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM ##test_arbitraje WHERE clave = 'pg')),
        @antes DATETIMEOFFSET = DATEADD(MINUTE, -1, (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = (SELECT id FROM ##test_arbitraje WHERE clave = 'pg')));

-- E-3.12.32 Valido: cambia fecha, contenido y sancion => se acepta
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar @ib, '2031-01-10 22:00:00 +00:00', 'Informe corregido', 'Multa'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.32', 'arbitraje.informe_arbitral_modificar: Valido: cambia fecha, contenido y sancion', 0;
-- E-3.12.33 Valido: fecha igual al inicio (borde); la sancion en blanco se guarda NULL => se acepta
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar @ib, @ini, 'Informe base', '   '; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.33', 'arbitraje.informe_arbitral_modificar: Valido: fecha igual al inicio (borde); la sancion en blanco se guarda NULL', 0;
-- E-3.12.34 Restaurar: deja el informe como estaba => se acepta
BEGIN TRY EXEC arbitraje.informe_arbitral_modificar @ib, '2031-01-10 20:00:00 +00:00', 'Informe base', NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.34', 'arbitraje.informe_arbitral_modificar: Restaurar: deja el informe como estaba', 0;
GO

PRINT '--- E-3.12.35 arbitraje.informe_arbitral_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ie INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'i_elim');

-- E-3.12.35 Baja valida => se acepta
BEGIN TRY EXEC arbitraje.informe_arbitral_eliminar @ie; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.12.35', 'arbitraje.informe_arbitral_eliminar: Baja valida', 0;
GO

-- ============================================================
-- 3.13 publicidad: anunciante, campania, campania_pais_interes, pieza_publicitaria y espacio_publicitario
-- ============================================================

PRINT '--- E-3.13.01 a E-3.13.02 publicidad.anunciante_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @anun INT;

-- E-3.13.01 Valido => se acepta
BEGIN TRY EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventas@gmail.com', @anun OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.01', 'publicidad.anunciante_insertar: Valido', 0;
-- E-3.13.02 Valido: sin contacto (es opcional) => se acepta
BEGIN TRY EXEC publicidad.anunciante_insertar 'TEST06', 'Empresa S.A.', NULL, @anun OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.02', 'publicidad.anunciante_insertar: Valido: sin contacto (es opcional)', 0;
GO

PRINT '--- E-3.13.03 a E-3.13.04 publicidad.anunciante_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.18 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.

-- E-3.13.03 Modificacion valida => se acepta
BEGIN TRY EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas@gmail.com'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.03', 'publicidad.anunciante_modificar: Modificacion valida', 0;
-- E-3.13.04 Valido: sin contacto (es opcional) => se acepta
BEGIN TRY EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.04', 'publicidad.anunciante_modificar: Valido: sin contacto (es opcional)', 0;
GO

PRINT '--- P-3.19 Preparación de publicidad.anunciante_eliminar (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
DECLARE @a INT;
EXEC publicidad.anunciante_insertar 'ELIM_OK', NULL, NULL;
EXEC publicidad.anunciante_insertar 'ELIM_CON_CAMP', NULL, NULL, @a OUTPUT;
EXEC publicidad.campania_insertar @a, 'Camp de prueba', '2026-06-01', '2026-06-30';
GO

PRINT '--- E-3.13.05 publicidad.anunciante_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.19 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @elim_ok INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'ELIM_OK'),
        @elim_con INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'ELIM_CON_CAMP');

-- E-3.13.05 Baja valida (SI LE DAS DOS VECES TE DICE ID inexistente *ya se elimino*) => se acepta
BEGIN TRY EXEC publicidad.anunciante_eliminar @elim_ok; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.05', 'publicidad.anunciante_eliminar: Baja valida (SI LE DAS DOS VECES TE DICE ID inexistente *ya se elimino*)', 0;
GO

PRINT '--- P-3.20 Preparación de publicidad.campania_insertar (ejecutar UNA sola vez)';
-- Preparación (sin verificaciones) de los casos detallados. Ejecutar UNA sola vez.
-- Requiere: Lote 0, las Partes 1 y 2 y las preparaciones P-3.xx anteriores.
EXEC publicidad.anunciante_insertar 'CAMP_A', NULL, NULL;
EXEC publicidad.anunciante_insertar 'CAMP_B', NULL, NULL;
GO

PRINT '--- E-3.13.06 a E-3.13.09 publicidad.campania_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.20 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @b INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_B'),
        @camp INT;

-- E-3.13.06 Valido => se acepta
BEGIN TRY EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19', @camp OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.06', 'publicidad.campania_insertar: Valido', 0;
-- E-3.13.07 Valido: fecha fin = fecha inicio => se acepta
BEGIN TRY EXEC publicidad.campania_insertar @a, 'Camp Un Dia', '2026-06-10', '2026-06-10', @camp OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.07', 'publicidad.campania_insertar: Valido: fecha fin = fecha inicio', 0;
-- E-3.13.08 Valido: mismo nombre en otro anunciante => se acepta
BEGIN TRY EXEC publicidad.campania_insertar @b, 'Camp Test', '2026-06-01', '2026-07-19', @camp OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.08', 'publicidad.campania_insertar: Valido: mismo nombre en otro anunciante', 0;
-- E-3.13.09 Valido: se guarda sin espacios => se acepta
BEGIN TRY EXEC publicidad.campania_insertar @a, '  Camp Espacios  ', '2026-06-01', '2026-06-30', @camp OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.09', 'publicidad.campania_insertar: Valido: se guarda sin espacios', 0;
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

PRINT '--- E-3.13.10 a E-3.13.13 publicidad.campania_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.21 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @b INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_B'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod'),
        @c3 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'),
        @f DATE = (SELECT TOP 1 CAST(p.fecha_hora_utc AS DATE) FROM publicidad.espacio_publicitario e JOIN torneo.partido p ON p.partido_id = e.partido_id
                   JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
                   WHERE pz.campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'));
DECLARE @f_m10 DATE = DATEADD(DAY, -10, @f), @f_m1 DATE = DATEADD(DAY, -1, @f),
        @f_p1  DATE = DATEADD(DAY, 1, @f),   @f_p10 DATE = DATEADD(DAY, 10, @f);

-- E-3.13.10 Valido: cambia fechas, mismo nombre propio (no es duplicado) => se acepta
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', '2026-06-05', '2026-07-10'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.10', 'publicidad.campania_modificar: Valido: cambia fechas, mismo nombre propio (no es duplicado)', 0;
-- E-3.13.11 Valido: cambia de anunciante (despues volver a @a) => se acepta
BEGIN TRY EXEC publicidad.campania_modificar @c1, @b, 'Camp Mod', '2026-06-05', '2026-07-10'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.11', 'publicidad.campania_modificar: Valido: cambia de anunciante (despues volver a @a)', 0;
-- E-3.13.12 Valido: nombre con espacios (se guarda recortado) y fin = inicio => se acepta
BEGIN TRY EXEC publicidad.campania_modificar @c1, @a, '  Camp Mod  ', '2026-06-10', '2026-06-10'; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.12', 'publicidad.campania_modificar: Valido: nombre con espacios (se guarda recortado) y fin = inicio', 0;
-- E-3.13.13 Valido: amplia la vigencia, el partido sigue cubierto => se acepta
BEGIN TRY EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_m10, @f_p10; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.13', 'publicidad.campania_modificar: Valido: amplia la vigencia, el partido sigue cubierto', 0;
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

PRINT '--- E-3.13.14 publicidad.campania_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.22 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ok INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim OK'),
        @con INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim Con Pieza');

-- E-3.13.14 Baja valida: elimina la campaña y sus paises de interes, si se ejecuta dos veces seguidas tira error de inexistente => se acepta
BEGIN TRY EXEC publicidad.campania_eliminar @ok; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.14', 'publicidad.campania_eliminar: Baja valida: elimina la campaña y sus paises de interes, si se ejecuta dos veces seguidas tira error de inexistente', 0;
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

PRINT '--- E-3.13.15 a E-3.13.16 publicidad.campania_pais_interes_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_INS'),
        @co INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_OTRA'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);

-- E-3.13.15 Valido => se acepta
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar @ci, @p2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.15', 'publicidad.campania_pais_interes_insertar: Valido', 0;
-- E-3.13.16 Valido: el mismo pais en otra campaña => se acepta
BEGIN TRY EXEC publicidad.campania_pais_interes_insertar @co, @p1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.16', 'publicidad.campania_pais_interes_insertar: Valido: el mismo pais en otra campaña', 0;
GO

PRINT '--- E-3.13.17 a E-3.13.19 publicidad.campania_pais_interes_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @p5 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY);

-- E-3.13.17 Valido: reemplaza p2 por p4 => se acepta
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p2, @p4; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.17', 'publicidad.campania_pais_interes_modificar: Valido: reemplaza p2 por p4', 0;
-- E-3.13.18 Restaurar: volver p4 a p2 => se acepta
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p4, @p2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.18', 'publicidad.campania_pais_interes_modificar: Restaurar: volver p4 a p2', 0;
-- E-3.13.19 Valido: mismo pais => se acepta
BEGIN TRY EXEC publicidad.campania_pais_interes_modificar @cm, @p3, @p3; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.19', 'publicidad.campania_pais_interes_modificar: Valido: mismo pais', 0;
GO

PRINT '--- E-3.13.20 publicidad.campania_pais_interes_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.23 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_ELIM'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);

-- E-3.13.20 Baja valida (si se ejecuta 2 veces tira error) => se acepta
BEGIN TRY EXEC publicidad.campania_pais_interes_eliminar @ce, @p2; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.20', 'publicidad.campania_pais_interes_eliminar: Baja valida (si se ejecuta 2 veces tira error)', 0;
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

PRINT '--- E-3.13.21 a E-3.13.26 publicidad.pieza_publicitaria_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @co INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_OTRA'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;

-- E-3.13.21 Valido => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p1, 500, @pz OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.21', 'publicidad.pieza_publicitaria_insertar: Valido', 0;
-- E-3.13.22 Valido: mismo idioma, otro mercado => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'espanol', @p2, 800, @pz OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.22', 'publicidad.pieza_publicitaria_insertar: Valido: mismo idioma, otro mercado', 0;
-- E-3.13.23 Valido: tarifa 0 => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'frances', @p1, 0, @pz OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.23', 'publicidad.pieza_publicitaria_insertar: Valido: tarifa 0', 0;
-- E-3.13.24 Valido: se guarda en minusculas => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'ALEMAN', @p1, 700, @pz OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.24', 'publicidad.pieza_publicitaria_insertar: Valido: se guarda en minusculas', 0;
-- E-3.13.25 Valido: idioma de 10 letras => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @ci, 'abcdefghij', @p2, 100, @pz OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.25', 'publicidad.pieza_publicitaria_insertar: Valido: idioma de 10 letras', 0;
-- E-3.13.26 Valido: mismo idioma y mercado que la base, en otra campaña => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_insertar @co, 'espanol', @p1, 1000, @pz OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.26', 'publicidad.pieza_publicitaria_insertar: Valido: mismo idioma y mercado que la base, en otra campaña', 0;
GO

PRINT '--- E-3.13.27 a E-3.13.33 publicidad.pieza_publicitaria_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_MOD'),
        @cd INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_DEST'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @m1 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @m2 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @m3 INT = (SELECT pz.pieza_id FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                   WHERE c.nombre IN ('PZ_MOD', 'PZ_DEST') ORDER BY pz.pieza_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY);

-- E-3.13.27 Valido: cambia la tarifa (no es duplicado de si misma) => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, 1500; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.27', 'publicidad.pieza_publicitaria_modificar: Valido: cambia la tarifa (no es duplicado de si misma)', 0;
-- E-3.13.28 Valido: idioma en mayusculas, se guarda en minusculas => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'INGLES', @p1, 1000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.28', 'publicidad.pieza_publicitaria_modificar: Valido: idioma en mayusculas, se guarda en minusculas', 0;
-- E-3.13.29 Valido: cambia el idioma => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'italiano', @p1, 1000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.29', 'publicidad.pieza_publicitaria_modificar: Valido: cambia el idioma', 0;
-- E-3.13.30 Valido: cambia el mercado, sin espacios asignados => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p2, 1000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.30', 'publicidad.pieza_publicitaria_modificar: Valido: cambia el mercado, sin espacios asignados', 0;
-- E-3.13.31 Valido: cambia de campaña, sin espacios asignados => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @cd, 'ingles', @p1, 1000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.31', 'publicidad.pieza_publicitaria_modificar: Valido: cambia de campaña, sin espacios asignados', 0;
-- E-3.13.32 Valido: pieza con espacio, solo cambia la tarifa => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m3, @c1, 'aleman', @p3, 3500; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.32', 'publicidad.pieza_publicitaria_modificar: Valido: pieza con espacio, solo cambia la tarifa', 0;
-- E-3.13.33 Restaurar: deja m1 como estaba => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, 1000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.33', 'publicidad.pieza_publicitaria_modificar: Restaurar: deja m1 como estaba', 0;
GO

PRINT '--- E-3.13.34 publicidad.pieza_publicitaria_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.24 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @e1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM') AND idioma = 'espanol'),
        @e2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM') AND idioma = 'ingles'),
        @pz INT;

-- E-3.13.34 Baja valida (si se ejecuta 2 veces seguidas tira error) => se acepta
BEGIN TRY EXEC publicidad.pieza_publicitaria_eliminar @e1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.34', 'publicidad.pieza_publicitaria_eliminar: Baja valida (si se ejecuta 2 veces seguidas tira error)', 0;
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

PRINT '--- E-3.13.35 a E-3.13.37 publicidad.espacio_publicitario_insertar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG'),
        @fuera INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_FUERA');
DECLARE @z1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'espanol'),
        @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z6 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'italiano'),
        @z7 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'portugues'),
        @zf INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @fuera);
DECLARE @pa INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z1 AND numero_espacio = 1),
        @pb INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z6 AND numero_espacio = 4),
        @esp INT;

-- E-3.13.35 Valido: con pieza y prioridad 1 => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pb, 1, @z7, 1, @esp OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.35', 'publicidad.espacio_publicitario_insertar: Valido: con pieza y prioridad 1', 0;
-- E-3.13.36 Valido: pieza que ya esta en otro partido (PA), prioridad 4 (borde) => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pb, 2, @z1, 4, @esp OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.36', 'publicidad.espacio_publicitario_insertar: Valido: pieza que ya esta en otro partido (PA), prioridad 4 (borde)', 0;
-- E-3.13.37 Valido: espacio vacio (sin pieza ni prioridad) => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_insertar @pb, 3, NULL, NULL, @esp OUTPUT; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.37', 'publicidad.espacio_publicitario_insertar: Valido: espacio vacio (sin pieza ni prioridad)', 0;
GO

PRINT '--- E-3.13.38 a E-3.13.45 publicidad.espacio_publicitario_modificar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG'),
        @fuera INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_FUERA');
DECLARE @z2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'ingles'),
        @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances'),
        @z4 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'aleman'),
        @z7 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'portugues'),
        @zf INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @fuera);
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @m1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 1),
        @ef INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 2),
        @mf INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 3),
        @fx DATETIMEOFFSET = (SELECT fecha_hora_utc FROM torneo.partido WHERE partido_id = @pc);

-- E-3.13.38 Valido: cambia la prioridad y conserva la pieza => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 3; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.38', 'publicidad.espacio_publicitario_modificar: Valido: cambia la prioridad y conserva la pieza', 0;
-- E-3.13.39 Valido: cambia la pieza (despues restaurar) => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z7, 1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.39', 'publicidad.espacio_publicitario_modificar: Valido: cambia la pieza (despues restaurar)', 0;
-- E-3.13.40 Valido: deja el espacio vacio (despues restaurar) => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.40', 'publicidad.espacio_publicitario_modificar: Valido: deja el espacio vacio (despues restaurar)', 0;
-- E-3.13.41 Valido: informa fecha de exhibicion sin facturar => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 2, @fx; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.41', 'publicidad.espacio_publicitario_modificar: Valido: informa fecha de exhibicion sin facturar', 0;
-- E-3.13.42 Valido: facturado NULL se toma como 0 => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.42', 'publicidad.espacio_publicitario_modificar: Valido: facturado NULL se toma como 0', 0;
-- E-3.13.43 Valido: espacio ya facturado, misma pieza, cambia el monto => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @ef, @z3, NULL, @fx, 1, 20000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.43', 'publicidad.espacio_publicitario_modificar: Valido: espacio ya facturado, misma pieza, cambia el monto', 0;
-- E-3.13.44 Restaurar: deja m1 como estaba => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, 0, NULL; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.44', 'publicidad.espacio_publicitario_modificar: Restaurar: deja m1 como estaba', 0;
-- E-3.13.45 Valido: marca facturado. => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_modificar @mf, @z4, 1, @fx, 1, 5000; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.45', 'publicidad.espacio_publicitario_modificar: Valido: marca facturado.', 0;
GO

PRINT '--- E-3.13.46 publicidad.espacio_publicitario_eliminar';
-- Resultado esperado: cada caso se acepta y queda aplicado, en orden.
-- Requiere: Lote 0 y las preparaciones hasta P-3.25 (Partes 1 y 2 ya ejecutadas).
-- Un solo caso: seleccionar las líneas del DECLARE y las del caso, y ejecutar la selección.
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances'),
        @z5 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'japones');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @e1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 4),
        @ef INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 2),
        @esp INT;

-- E-3.13.46 Baja valida (espacio no facturado) SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR => se acepta
BEGIN TRY EXEC publicidad.espacio_publicitario_eliminar @e1; END TRY BEGIN CATCH EXEC #capturar; END CATCH; EXEC #registrar 'E-3.13.46', 'publicidad.espacio_publicitario_eliminar: Baja valida (espacio no facturado) SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR', 0;
GO

-- ============================================================
-- RESUMEN
-- ============================================================

PRINT '################ RESUMEN ################';
-- Resultado esperado: todas las pruebas en OK y ninguna en FALLO.
DECLARE @ok INT = (SELECT COUNT(*) FROM #resultado WHERE resultado = 'OK'),
        @fallo INT = (SELECT COUNT(*) FROM #resultado WHERE resultado <> 'OK');
PRINT CONCAT('TOTAL: ', @ok, ' OK, ', @fallo, ' FALLO');
SELECT resultado, COUNT(*) AS pruebas FROM #resultado GROUP BY resultado;
SELECT orden, prueba, descripcion, resultado FROM #resultado ORDER BY orden;
IF @fallo > 0
    SELECT 'PRUEBAS FALLIDAS' AS atencion, prueba, descripcion, detalle FROM #resultado WHERE resultado <> 'OK' ORDER BY orden;
ELSE
    PRINT 'Todas las pruebas finalizaron con el resultado esperado.';
GO

SET NOEXEC OFF;
GO
