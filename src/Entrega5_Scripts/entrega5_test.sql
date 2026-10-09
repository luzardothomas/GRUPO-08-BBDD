-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 5: Base de Datos - LOTES DE PRUEBA
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Pruebas de los procedimientos de entrega5_sp.sql.
--     PARTE 1: SP de ABM de cada tabla  (casos exitosos con evidencia + rechazos).
--     PARTE 2: SP de lógica de negocio  (casos exitosos con evidencia + rechazos).
--   Cada prueba indica en un comentario "Resultado esperado". Los rechazos muestran el
--   mensaje único que agrupa todas las condiciones incumplidas. Al final se lista un
--   resumen: todas las pruebas deben figurar con resultado OK.
--
-- CÓMO EJECUTARLO:
--   1) Ejecutar entrega5_definition.sql (recrea la base vacía) y luego entrega5_sp.sql.
--   2) Ejecutar este script completo, de una sola vez y en la misma ventana de consulta
--      (usa tablas temporales para pasar datos entre lotes).
--   Todos los datos se cargan a través de los SP: no hay INSERT/UPDATE/DELETE directos
--   sobre las tablas de la base.
-- ============================================================

USE mundial_2026;
GO

SET NOCOUNT ON;
GO

-- El script necesita la base recién creada: si ya tiene datos, no ejecuta nada.

IF EXISTS (SELECT 1 FROM torneo.pais)
BEGIN
    RAISERROR('La base ya tiene datos: ejecutar primero entrega5_definition.sql y entrega5_sp.sql para recrearla. No se ejecuta ninguna prueba.', 16, 1);
    SET NOEXEC ON;
END;
GO

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
IF OBJECT_ID('tempdb..#id') IS NOT NULL DROP TABLE #id;
CREATE TABLE #resultado (orden INT IDENTITY(1, 1), prueba VARCHAR(10), descripcion VARCHAR(120),
                         resultado VARCHAR(5), detalle VARCHAR(2100));
CREATE TABLE #id (clave VARCHAR(20) PRIMARY KEY, valor INT);   -- ids generados, para los lotes siguientes
GO

PRINT '################ PARTE 1: PROCEDIMIENTOS DE ABM ################';
GO

-- ============================================================
-- 1.1 torneo.parametro
-- ============================================================

PRINT '--- 1.1.a Alta, modificación y baja de un parámetro';
-- Resultado esperado: el parámetro de prueba se crea con valor 7, pasa a 9 y se elimina.
EXEC torneo.parametro_insertar 'parametro_de_prueba', 7, 'Parámetro creado por el test';
EXEC torneo.parametro_modificar 'parametro_de_prueba', 9;
SELECT clave, valor, descripcion FROM torneo.parametro WHERE clave = 'parametro_de_prueba';
INSERT INTO #resultado SELECT '1.1.a', 'parametro: alta y modificación', IIF(COUNT(*) = 1 AND MAX(valor) = 9, 'OK', 'FALLO'), ''
FROM torneo.parametro WHERE clave = 'parametro_de_prueba';
EXEC torneo.parametro_eliminar 'parametro_de_prueba';
INSERT INTO #resultado SELECT '1.1.a', 'parametro: baja', IIF(COUNT(*) = 0, 'OK', 'FALLO'), ''
FROM torneo.parametro WHERE clave = 'parametro_de_prueba';
GO

PRINT '--- 1.1.b Alta inválida';
-- Resultado esperado: rechazo (error 50001) con 3 condiciones: clave obligatoria, valor negativo, descripción obligatoria.
BEGIN TRY
    EXEC torneo.parametro_insertar '', -1, '';
    INSERT INTO #resultado VALUES ('1.1.b', 'parametro: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.1.b', 'parametro: alta inválida', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.1.c Baja de un parámetro requerido por la lógica de negocio';
-- Resultado esperado: rechazo; el parámetro sigue existiendo.
BEGIN TRY
    EXEC torneo.parametro_eliminar 'cambios_max_reglamentarios';
    INSERT INTO #resultado VALUES ('1.1.c', 'parametro: baja de requerido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.1.c', 'parametro: baja de requerido', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 1.2 torneo.pais y torneo.confederacion
-- ============================================================

PRINT '--- 1.2.a Alta de países y confederaciones';
-- Resultado esperado: 11 países (uno temporal) y 6 confederaciones.
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
INSERT INTO #resultado SELECT '1.2.a', 'pais: alta (el código se guarda en mayúsculas)',
       IIF(COUNT(*) = 11 AND SUM(CASE WHEN codigo_iso = 'ZZZ' COLLATE Latin1_General_CS_AS THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM torneo.pais;
INSERT INTO #resultado SELECT '1.2.a', 'confederacion: alta', IIF(COUNT(*) = 6, 'OK', 'FALLO'), '' FROM torneo.confederacion;
GO

PRINT '--- 1.2.b Modificación y baja de país; modificación y baja de confederación';
-- Resultado esperado: Argentina queda con PBI 14000; el país temporal y la confederación OFC se eliminan.
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'pais_ARG'), @zzz INT = (SELECT valor FROM #id WHERE clave = 'pais_ZZZ'),
        @ofc INT = (SELECT valor FROM #id WHERE clave = 'conf_OFC');
EXEC torneo.pais_modificar @arg, 'ARG', 'Argentina', 'UTC-03', 14000;
EXEC torneo.pais_eliminar @zzz;
EXEC torneo.confederacion_modificar @ofc, 'OFC';
EXEC torneo.confederacion_eliminar @ofc;
SELECT codigo_iso, nombre, pbi_per_capita FROM torneo.pais WHERE codigo_iso IN ('ARG', 'ZZZ');
INSERT INTO #resultado SELECT '1.2.b', 'pais: modificación y baja',
       IIF(SUM(CASE WHEN codigo_iso = 'ARG' AND pbi_per_capita = 14000 THEN 1 ELSE 0 END) = 1
           AND SUM(CASE WHEN codigo_iso = 'ZZZ' THEN 1 ELSE 0 END) = 0, 'OK', 'FALLO'), '' FROM torneo.pais;
INSERT INTO #resultado SELECT '1.2.b', 'confederacion: baja', IIF(COUNT(*) = 5, 'OK', 'FALLO'), '' FROM torneo.confederacion;
GO

PRINT '--- 1.2.c Alta de país inválida';
-- Resultado esperado: rechazo con 4 condiciones: código ISO, nombre, huso horario y PBI negativo.
BEGIN TRY
    EXEC torneo.pais_insertar 'AR1X', '   ', 'GMT-3', -5;
    INSERT INTO #resultado VALUES ('1.2.c', 'pais: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.2.c', 'pais: alta inválida (4 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 4, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.2.d País duplicado, baja de país en uso y confederación inválida';
-- Resultado esperado: tres rechazos (código ISO repetido; país con dependencias; confederación fuera del dominio).
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'pais_ARG');
BEGIN TRY
    EXEC torneo.pais_insertar 'arg', 'Argentina bis', 'UTC-03';
    INSERT INTO #resultado VALUES ('1.2.d', 'pais: código duplicado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.2.d', 'pais: código duplicado', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC torneo.confederacion_insertar 'FIFA';
    INSERT INTO #resultado VALUES ('1.2.d', 'confederacion: fuera de dominio', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.2.d', 'confederacion: fuera de dominio', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 1.3 torneo.sede
-- ============================================================

PRINT '--- 1.3.a Alta, modificación y baja de sedes';
-- Resultado esperado: quedan 3 sedes (husos UTC-04 y UTC-06); MetLife pasa a capacidad 82500; la temporal se elimina.
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
INSERT INTO #resultado SELECT '1.3.a', 'sede: alta, modificación y baja',
       IIF(COUNT(*) = 3 AND MAX(capacidad) = 83000 AND SUM(CASE WHEN capacidad = 82500 THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), '' FROM torneo.sede;
GO

PRINT '--- 1.3.b Alta de sede inválida';
-- Resultado esperado: rechazo con 5 condiciones: nombre, ciudad, país inexistente, capacidad y huso horario.
BEGIN TRY
    EXEC torneo.sede_insertar '', '', 9999, 0, 'UTC-4';
    INSERT INTO #resultado VALUES ('1.3.b', 'sede: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.3.b', 'sede: alta inválida (5 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 5, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 1.4 torneo.seleccion
-- ============================================================

PRINT '--- 1.4.a Alta, modificación y baja de selecciones';
-- Resultado esperado: 4 selecciones en el grupo A y Brasil en el B; la de España (temporal) se elimina.
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
INSERT INTO #resultado SELECT '1.4.a', 'seleccion: alta, modificación y baja',
       IIF(COUNT(*) = 5 AND SUM(CASE WHEN grupo = 'A' THEN 1 ELSE 0 END) = 4 AND SUM(CASE WHEN grupo = 'B' THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM torneo.seleccion;
GO

PRINT '--- 1.4.b Alta de selección inválida y país repetido';
-- Resultado esperado: primer rechazo con 3 condiciones (país, confederación, grupo); segundo por país ya participante.
DECLARE @pais INT = (SELECT valor FROM #id WHERE clave = 'pais_ARG'), @conf INT = (SELECT valor FROM #id WHERE clave = 'conf_UEFA');
BEGIN TRY
    EXEC torneo.seleccion_insertar 9999, 9999, 'Z';
    INSERT INTO #resultado VALUES ('1.4.b', 'seleccion: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.4.b', 'seleccion: alta inválida (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC torneo.seleccion_insertar @pais, @conf, 'D';
    INSERT INTO #resultado VALUES ('1.4.b', 'seleccion: país repetido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.4.b', 'seleccion: país repetido', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 1.5 torneo.partido
-- ============================================================

PRINT '--- 1.5.a Alta, modificación y baja de partidos';
-- Resultado esperado: 4 partidos programados, con la hora UTC derivada de la hora local
-- (P1 20:00 UTC-04 = 00:00 UTC del día siguiente). P3 se reprograma a las 16:00. El partido temporal se elimina.
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
INSERT INTO #resultado SELECT '1.5.a', 'partido: alta (UTC derivada), modificación y baja',
       IIF(COUNT(*) = 4
           AND SUM(CASE WHEN fecha_hora_utc = '2026-06-13T00:00:00+00:00' AND DATEPART(TZOFFSET, fecha_hora_utc) = 0 THEN 1 ELSE 0 END) = 1
           AND SUM(CASE WHEN fecha_hora_local = '2026-06-22T16:00:00-04:00' THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM torneo.partido;
GO

PRINT '--- 1.5.b Alta de partido inválida';
-- Resultado esperado: rechazo con 6 condiciones: sede inexistente, hora UTC sin offset +00:00, UTC distinta de la local,
-- fase inválida, selecciones iguales y selección con otro partido a menos de 24 horas.
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG');
BEGIN TRY
    EXEC torneo.partido_insertar 9999, '2026-06-13T10:00:00-04:00', 'amistoso', @arg, @arg, '2026-06-13T10:00:00-03:00';
    INSERT INTO #resultado VALUES ('1.5.b', 'partido: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.5.b', 'partido: alta inválida (6 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 6, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.5.c Reglas de fixture';
-- Resultado esperado: rechazo con 4 condiciones: hora local fuera del huso de la sede, selecciones de distinto grupo,
-- sede ocupada ese día y selección que juega a menos de 24 horas.
-- (Argentina vs Brasil en "grupos", en MetLife el mismo día que P1, con offset -03:00.)
DECLARE @ny INT = (SELECT valor FROM #id WHERE clave = 'sede_NY'), @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'),
        @bra INT = (SELECT valor FROM #id WHERE clave = 'BRA'), @fra INT = (SELECT valor FROM #id WHERE clave = 'FRA');
BEGIN TRY
    EXEC torneo.partido_insertar @ny, '2026-06-12T15:00:00-03:00', 'grupos', @arg, @bra;
    INSERT INTO #resultado VALUES ('1.5.c', 'partido: reglas de fixture', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.5.c', 'partido: reglas de fixture (4 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 4, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
-- Resultado esperado: rechazo por cruce repetido (Francia vs Argentina ya existe en grupos, con la localía invertida).
BEGIN TRY
    EXEC torneo.partido_insertar @ny, '2026-07-05T15:00:00-04:00', 'grupos', @fra, @arg;
    INSERT INTO #resultado VALUES ('1.5.c', 'partido: cruce repetido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.5.c', 'partido: cruce repetido', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 1.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================

PRINT '--- 1.6.a Alta, modificación y baja de cuerpo técnico (crea y borra su persona)';
-- Resultado esperado: 3 integrantes (DT y ayudante de Argentina, DT de Francia), cada uno con su persona 'cuerpo_tecnico'.
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
INSERT INTO #resultado SELECT '1.6.a', 'cuerpo_tecnico: alta, modificación y baja (con su persona)',
       IIF((SELECT COUNT(*) FROM plantel.cuerpo_tecnico) = 3 AND (SELECT COUNT(*) FROM plantel.persona) = 3
           AND EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico WHERE apellido = 'Aimar' AND rol = 'ayudante_tecnico'), 'OK', 'FALLO'), '';
GO

PRINT '--- 1.6.b Alta de cuerpo técnico inválida';
-- Resultado esperado: rechazo con 3 condiciones (selección inexistente, nombre obligatorio, rol inválido);
-- y rechazo de un segundo director técnico para Argentina.
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG');
BEGIN TRY
    EXEC plantel.cuerpo_tecnico_insertar 9999, '', 'Pérez', 'utilero';
    INSERT INTO #resultado VALUES ('1.6.b', 'cuerpo_tecnico: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.6.b', 'cuerpo_tecnico: alta inválida (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC plantel.cuerpo_tecnico_insertar @arg, 'Otro', 'Técnico', 'director_tecnico';
    INSERT INTO #resultado VALUES ('1.6.b', 'cuerpo_tecnico: segundo DT', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.6.b', 'cuerpo_tecnico: segundo DT', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.6.c Alta masiva de jugadores (por SP, uno por uno)';
-- Resultado esperado: 97 jugadores (27 de ARG, 23 de FRA, 23 de MEX y 24 de JPN), cada uno con su persona 'jugador'.
-- Convención de los datos de prueba: nombre = código del país, apellido = 'Jugador NN' (NN será su dorsal).
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
INSERT INTO #resultado SELECT '1.6.c', 'jugador: alta masiva (con su persona)',
       IIF((SELECT COUNT(*) FROM plantel.jugador) = 97
           AND (SELECT COUNT(*) FROM plantel.persona WHERE tipo_persona = 'jugador') = 97, 'OK', 'FALLO'), '';
GO

PRINT '--- 1.6.d Modificación y baja de jugador; ABM de persona';
-- Resultado esperado: ARG Jugador 10 cambia de club; el jugador temporal se elimina junto con su persona;
-- la persona suelta se crea, se modifica y se elimina. Quedan 97 jugadores y 100 personas.
DECLARE @id INT, @persona INT;
SELECT @id = jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 10';
EXEC plantel.jugador_modificar @id, 'ARG', 'Jugador 10', '1996-04-04', 'delantero', 'Inter Miami CF';
EXEC plantel.jugador_insertar 'Temporal', 'Temporal', '2000-01-01', 'defensor', NULL, @id OUTPUT, @persona OUTPUT;
EXEC plantel.jugador_eliminar @id;
EXEC plantel.persona_insertar 'jugador', @persona OUTPUT;
EXEC plantel.persona_modificar @persona, 'cuerpo_tecnico';
EXEC plantel.persona_eliminar @persona;
SELECT jugador_id, nombre, apellido, fecha_nacimiento, club_origen, posicion_habitual FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 10';
INSERT INTO #resultado SELECT '1.6.d', 'jugador y persona: modificación y baja',
       IIF((SELECT COUNT(*) FROM plantel.jugador) = 97 AND (SELECT COUNT(*) FROM plantel.persona) = 100
           AND EXISTS (SELECT 1 FROM plantel.jugador WHERE club_origen = 'Inter Miami CF'), 'OK', 'FALLO'), '';
GO

PRINT '--- 1.6.e Alta de jugador inválida y cambio de tipo de persona inválido';
-- Resultado esperado: rechazo con 3 condiciones (nombre, fecha de nacimiento fuera de rango, posición);
-- y rechazo al pasar a cuerpo técnico la persona de un jugador.
DECLARE @persona INT = (SELECT persona_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 10');
BEGIN TRY
    EXEC plantel.jugador_insertar '', 'Pérez', '2030-01-01', 'lateral';
    INSERT INTO #resultado VALUES ('1.6.e', 'jugador: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.6.e', 'jugador: alta inválida (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC plantel.persona_modificar @persona, 'cuerpo_tecnico';
    INSERT INTO #resultado VALUES ('1.6.e', 'persona: cambio de tipo inválido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.6.e', 'persona: cambio de tipo inválido', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 1.7 plantel.convocatoria
-- ============================================================

PRINT '--- 1.7.a Alta de convocatorias';
-- Resultado esperado: ARG 26 convocados (el máximo), FRA 23, MEX 23 y JPN 24, con dorsal = NN del apellido.
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
INSERT INTO #resultado SELECT '1.7.a', 'convocatoria: alta', IIF(COUNT(*) = 96, 'OK', 'FALLO'), '' FROM plantel.convocatoria;
GO

PRINT '--- 1.7.b Cupo máximo, dorsal repetido y jugador de otra selección';
-- Resultado esperado: rechazo con 2 condiciones al convocar al jugador 27 de ARG con el dorsal 10
-- (dorsal en uso + máximo de 26 convocados).
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'),
        @j27 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27'),
        @fra1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'FRA' AND apellido = 'Jugador 01');
BEGIN TRY
    EXEC plantel.convocatoria_insertar @arg, @j27, 10, '2026-06-02';
    INSERT INTO #resultado VALUES ('1.7.b', 'convocatoria: cupo y dorsal', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.7.b', 'convocatoria: cupo máximo y dorsal repetido (2 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
-- Resultado esperado: rechazo con 4 condiciones: dorsal fuera de rango, fecha de alta obligatoria,
-- jugador convocado por otra selección y cupo máximo.
BEGIN TRY
    EXEC plantel.convocatoria_insertar @arg, @fra1, 150, NULL;
    INSERT INTO #resultado VALUES ('1.7.b', 'convocatoria: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.7.b', 'convocatoria: alta inválida (4 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 4, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.7.c Modificación y baja física de convocatoria';
-- Resultado esperado: el convocado 26 de ARG pasa al dorsal 99; la convocatoria del jugador 24 de JPN se elimina (quedan 23).
DECLARE @conv INT;
SELECT @conv = c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE j.nombre = 'ARG' AND j.apellido = 'Jugador 26';
EXEC plantel.convocatoria_modificar @conv, 99, '2026-06-01', 'Lista inicial';
SELECT @conv = c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE j.nombre = 'JPN' AND j.apellido = 'Jugador 24';
EXEC plantel.convocatoria_eliminar @conv;
SELECT j.nombre, j.apellido, c.dorsal, c.fecha_alta, c.fecha_baja FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE j.apellido IN ('Jugador 24', 'Jugador 26') AND j.nombre IN ('ARG', 'JPN') ORDER BY j.nombre, j.apellido;
INSERT INTO #resultado SELECT '1.7.c', 'convocatoria: modificación y baja',
       IIF(COUNT(*) = 95 AND SUM(CASE WHEN dorsal = 99 THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), '' FROM plantel.convocatoria;
GO

-- ============================================================
-- 1.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================

PRINT '--- 1.8.a Alta y modificación de formación y de sus jugadores';
-- Resultado esperado: formación visitante (Japón) de P3 con esquema 3-5-2 y 2 jugadores: dorsal 1 titular
-- y dorsal 12 suplente. El dorsal lo completa el SP desde la convocatoria.
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
INSERT INTO #resultado SELECT '1.8.a', 'formacion y formacion_jugador: alta y modificación',
       IIF(COUNT(*) = 2 AND SUM(CASE WHEN dorsal = 12 AND titular = 0 THEN 1 ELSE 0 END) = 1
           AND (SELECT esquema_tactico FROM plantel.formacion WHERE formacion_id = @form) = '3-5-2', 'OK', 'FALLO'), ''
FROM plantel.formacion_jugador WHERE formacion_id = @form;
GO

PRINT '--- 1.8.b Altas inválidas de formación y de jugador en formación';
-- Resultado esperado: (1) rechazo con 3 condiciones: partido inexistente, condición inválida, esquema que no suma 10.
-- (2) rechazo: un jugador de Francia no integra la convocatoria de Japón.
-- (3) rechazo de la baja de la formación porque tiene jugadores.
DECLARE @form INT = (SELECT valor FROM #id WHERE clave = 'form_tmp'),
        @fra1 INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'FRA' AND apellido = 'Jugador 01');
BEGIN TRY
    EXEC plantel.formacion_insertar 9999, 'neutral', '4-4-3';
    INSERT INTO #resultado VALUES ('1.8.b', 'formacion: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.8.b', 'formacion: alta inválida (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC plantel.formacion_jugador_insertar @form, @fra1, '', 1;
    INSERT INTO #resultado VALUES ('1.8.b', 'formacion_jugador: no convocado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.8.b', 'formacion_jugador: no convocado y sin posición (2 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC plantel.formacion_eliminar @form;
    INSERT INTO #resultado VALUES ('1.8.b', 'formacion: baja con jugadores', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.8.b', 'formacion: baja con jugadores', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.8.c Baja de jugadores de la formación y de la formación';
-- Resultado esperado: P3 vuelve a quedar sin formaciones.
DECLARE @form INT = (SELECT valor FROM #id WHERE clave = 'form_tmp'), @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @j INT;
SELECT @j = MIN(jugador_id) FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC plantel.formacion_jugador_eliminar @form, @j;
SELECT @j = MIN(jugador_id) FROM plantel.formacion_jugador WHERE formacion_id = @form;
EXEC plantel.formacion_jugador_eliminar @form, @j;
EXEC plantel.formacion_eliminar @form;
INSERT INTO #resultado SELECT '1.8.c', 'formacion y formacion_jugador: baja', IIF(COUNT(*) = 0, 'OK', 'FALLO'), ''
FROM plantel.formacion WHERE partido_id = @p3;
GO

-- ============================================================
-- PREPARACIÓN: formaciones de P1 (Argentina vs Francia), necesarias para probar el ABM de los
-- eventos. Se cargan con plantel.cargar_formacion, cuyas pruebas propias están en 2.2.
-- Titulares: dorsales 1 a 11. Suplentes: 12 a 23.
-- ============================================================

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

PRINT '--- 1.9.a Alta, modificación y baja de sustitución';
-- Resultado esperado: queda un cambio de Argentina (sale el 9, entra el 14) en el minuto 62 del ST, ventana 1.
-- El segundo cambio (sale 8, entra 15, ventana 2) se elimina.
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
INSERT INTO #resultado SELECT '1.9.a', 'sustitucion: alta, modificación y baja',
       IIF(COUNT(*) = 1 AND MAX(minuto) = 62 AND MAX(motivo) = 'precaucion', 'OK', 'FALLO'), '' FROM evento.sustitucion;
GO

PRINT '--- 1.9.b Alta de sustitución inválida';
-- Resultado esperado: rechazo con 6 condiciones: tiempo suplementario en fase de grupos, motivo inválido,
-- ventana no positiva (y fuera de orden), el que sale (9) ya no está en cancha y el que entra (3) es titular.
DECLARE @form INT = (SELECT valor FROM #id WHERE clave = 'P1_local'), @j3 INT, @j9 INT;
SELECT @j3 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 3;
SELECT @j9 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @form AND dorsal = 9;
BEGIN TRY
    EXEC evento.sustitucion_insertar @form, @j9, @j3, 95, 'alargue_1', 0, 'cansancio';
    INSERT INTO #resultado VALUES ('1.9.b', 'sustitucion: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.9.b', 'sustitucion: alta inválida (6 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 6, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 1.10 evento.gol (cada operación actualiza el marcador del partido en la misma transacción)
-- ============================================================

PRINT '--- 1.10.a Alta, modificación y baja de gol';
-- Resultado esperado: gol del 10 de Argentina con asistencia del 11 (queda como 'cabezazo', minuto 24) => 1 a 0.
-- Un gol en contra del 2 de Francia lleva el marcador a 2 a 0; al eliminarlo vuelve a 1 a 0.
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
INSERT INTO #resultado VALUES ('1.10.a', 'gol: el gol en contra suma al rival (2-0)', IIF(@marcador = '2-0', 'OK', 'FALLO'), @marcador);
EXEC evento.gol_eliminar @tmp;
SELECT g.gol_id, g.formacion_id, g.jugador_id, g.asistencia_jugador_id, g.minuto, g.tipo_gol, g.periodo FROM evento.gol g;
SELECT partido_id, goles_local, goles_visitante, penales_local, penales_visitante, estado FROM torneo.partido WHERE partido_id = @p1;
INSERT INTO #resultado SELECT '1.10.a', 'gol: alta, modificación y baja con marcador sincronizado (1-0)',
       IIF(goles_local = 1 AND goles_visitante = 0 AND penales_local IS NULL
           AND (SELECT COUNT(*) FROM evento.gol WHERE tipo_gol = 'cabezazo' AND minuto = 24) = 1, 'OK', 'FALLO'), ''
FROM torneo.partido WHERE partido_id = @p1;
GO

PRINT '--- 1.10.b Alta de gol inválida';
-- Resultado esperado: rechazo con 5 condiciones: tipo de gol inválido, minuto que no corresponde al período,
-- autor (20) suplente que no ingresó, asistente igual al autor y asistente que no ingresó.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @local INT = (SELECT valor FROM #id WHERE clave = 'P1_local'), @j20 INT;
SELECT @j20 = jugador_id FROM plantel.formacion_jugador WHERE formacion_id = @local AND dorsal = 20;
BEGIN TRY
    EXEC evento.gol_insertar @local, @j20, 70, 'chilena', 'PT', @j20;
    INSERT INTO #resultado VALUES ('1.10.b', 'gol: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.10.b', 'gol: alta inválida (5 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 5, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
INSERT INTO #resultado SELECT '1.10.b', 'gol: el rechazo no altera el marcador', IIF(goles_local = 1 AND goles_visitante = 0, 'OK', 'FALLO'), ''
FROM torneo.partido WHERE partido_id = @p1;
GO

-- ============================================================
-- 1.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================

PRINT '--- 1.11.a Alta, modificación y baja de tarjeta';
-- Resultado esperado: queda una amarilla al 6 de Francia (minuto 31 del PT). La amarilla temporal al 7 se elimina.
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
INSERT INTO #resultado SELECT '1.11.a', 'tarjeta: alta, modificación y baja',
       IIF(COUNT(*) = 1 AND MAX(minuto) = 31, 'OK', 'FALLO'), '' FROM evento.tarjeta;
GO

PRINT '--- 1.11.b Altas de tarjeta inválidas';
-- Resultado esperado: (1) rechazo con 4 condiciones: tiempo suplementario en fase de grupos, minuto fuera del período,
-- persona que no participa del partido (un jugador de México) y roja sin tipo de expulsión.
-- (2) rechazo de una segunda fila 'amarilla' para la misma persona en el mismo partido.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @visitante INT = (SELECT valor FROM #id WHERE clave = 'P1_visitante'),
        @mex INT = (SELECT persona_id FROM plantel.jugador WHERE nombre = 'MEX' AND apellido = 'Jugador 05'), @pers6 INT;
SELECT @pers6 = j.persona_id FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
WHERE fj.formacion_id = @visitante AND fj.dorsal = 6;
BEGIN TRY
    EXEC evento.tarjeta_insertar @p1, @mex, 10, 'alargue_1', 'roja';
    INSERT INTO #resultado VALUES ('1.11.b', 'tarjeta: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.11.b', 'tarjeta: alta inválida (4 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 4, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC evento.tarjeta_insertar @p1, @pers6, 50, 'ST', 'amarilla';
    INSERT INTO #resultado VALUES ('1.11.b', 'tarjeta: segunda amarilla como fila amarilla', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.11.b', 'tarjeta: segunda amarilla como fila amarilla', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.11.c ABM de criterios de suspensión';
-- Resultado esperado: quedan 2 criterios activos: general (2 amarillas => 1 partido) y cuerpo técnico (3 amarillas => 1 partido).
-- El criterio temporal de semifinal se modifica y se elimina.
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 2, 1, NULL, NULL, 1, @id OUTPUT;             INSERT INTO #id VALUES ('criterio_general', @id);
EXEC evento.criterio_suspension_insertar 3, 1, NULL, 'cuerpo_tecnico', 1, @id OUTPUT;
EXEC evento.criterio_suspension_insertar 1, 1, 'semifinal', NULL, 1, @id OUTPUT;
EXEC evento.criterio_suspension_modificar @id, 1, 2, 'semifinal', NULL, 0;
EXEC evento.criterio_suspension_eliminar @id;
SELECT criterio_id, fase_aplicable, tipo_persona_aplicable, cantidad_amarillas, partidos_suspension, activo FROM evento.criterio_suspension;
INSERT INTO #resultado SELECT '1.11.c', 'criterio_suspension: alta, modificación y baja', IIF(COUNT(*) = 2, 'OK', 'FALLO'), '' FROM evento.criterio_suspension;
-- Resultado esperado: rechazo con 4 condiciones (fase, tipo de persona, cantidad de amarillas, partidos); y rechazo por duplicado.
BEGIN TRY
    EXEC evento.criterio_suspension_insertar 0, -1, 'amistoso', 'hincha';
    INSERT INTO #resultado VALUES ('1.11.c', 'criterio_suspension: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.11.c', 'criterio_suspension: alta inválida (4 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 4, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC evento.criterio_suspension_insertar 2, 3;
    INSERT INTO #resultado VALUES ('1.11.c', 'criterio_suspension: duplicado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.11.c', 'criterio_suspension: duplicado', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.11.d ABM de suspensión (carga manual)';
-- Resultado esperado: se carga a mano una suspensión del 6 de Francia para P4, se le corrige el motivo y se elimina.
DECLARE @tarjeta INT = (SELECT valor FROM #id WHERE clave = 'tarjeta_FRA6'), @criterio INT = (SELECT valor FROM #id WHERE clave = 'criterio_general'),
        @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'), @susp INT, @antes INT;
EXEC evento.suspension_insertar @tarjeta, 'Sanción de oficio', @criterio, @p4, @susp OUTPUT;
EXEC evento.suspension_modificar @susp, 'Sanción de oficio del comité disciplinario', @p4;
SELECT suspension_id, criterio_id, tarjeta_id, partido_afectado_id, motivo FROM evento.suspension;
SELECT @antes = COUNT(*) FROM evento.suspension WHERE motivo LIKE '%comité%';
EXEC evento.suspension_eliminar @susp;
INSERT INTO #resultado SELECT '1.11.d', 'suspension: alta, modificación y baja', IIF(@antes = 1 AND COUNT(*) = 0, 'OK', 'FALLO'), '' FROM evento.suspension;
-- Resultado esperado: rechazo con 3 condiciones: amarilla sin criterio, motivo obligatorio y partido (P2) que la selección no juega.
BEGIN TRY
    EXEC evento.suspension_insertar @tarjeta, '', NULL, @p2;
    INSERT INTO #resultado VALUES ('1.11.d', 'suspension: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.11.d', 'suspension: alta inválida (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 1.12 arbitraje: arbitro, arbitro_idioma, designacion_arbitral e informe_arbitral
-- ============================================================

PRINT '--- 1.12.a Alta, modificación y baja de árbitros e idiomas';
-- Resultado esperado: 9 árbitros de 7 países; Matonte con 2 idiomas (espanol, ingles). El árbitro temporal se elimina con sus idiomas.
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
INSERT INTO #resultado SELECT '1.12.a', 'arbitro y arbitro_idioma: alta, modificación y baja',
       IIF((SELECT COUNT(*) FROM arbitraje.arbitro) = 9 AND (SELECT COUNT(*) FROM arbitraje.arbitro_idioma) = 2
           AND EXISTS (SELECT 1 FROM arbitraje.arbitro_idioma WHERE idioma = 'ingles'), 'OK', 'FALLO'), '';
GO

PRINT '--- 1.12.b Altas inválidas de árbitro e idioma';
-- Resultado esperado: (1) rechazo con 4 condiciones: apellido, edad fuera de rango, país inexistente, categoría.
-- (2) rechazo por idioma repetido para el mismo árbitro.
DECLARE @arb INT = (SELECT valor FROM #id WHERE clave = 'arb_URY1');
BEGIN TRY
    EXEC arbitraje.arbitro_insertar 'Juan', '', 9999, 'regional', '2015-01-01';
    INSERT INTO #resultado VALUES ('1.12.b', 'arbitro: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.12.b', 'arbitro: alta inválida (4 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 4, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC arbitraje.arbitro_idioma_insertar @arb, 'ESPANOL';
    INSERT INTO #resultado VALUES ('1.12.b', 'arbitro_idioma: repetido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.12.b', 'arbitro_idioma: repetido', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.12.c ABM de designación arbitral (de a una) y de informe arbitral';
-- Resultado esperado: en P2 se designa a Matonte como principal y luego se lo reemplaza por Elfath; el informe se
-- carga, se modifica y se elimina; finalmente se elimina la designación. P2 queda sin designaciones.
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
-- Resultado esperado: rechazo del informe con 2 condiciones (fecha anterior al partido y contenido vacío).
BEGIN TRY
    EXEC arbitraje.informe_arbitral_insertar @desig, '2026-06-01T00:00:00+00:00', '  ';
    INSERT INTO #resultado VALUES ('1.12.c', 'informe_arbitral: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.12.c', 'informe_arbitral: alta inválida (2 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
-- Resultado esperado: rechazo con 3 condiciones: rol inválido, árbitro argentino en un partido de Argentina (conflicto
-- de nacionalidad) y designación con informes que no admite cambio de árbitro.
BEGIN TRY
    EXEC arbitraje.designacion_arbitral_modificar @desig, @arg, 'juez de línea';
    INSERT INTO #resultado VALUES ('1.12.c', 'designacion_arbitral: modificación inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.12.c', 'designacion_arbitral: conflicto de nacionalidad (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC arbitraje.informe_arbitral_eliminar @informe;
EXEC arbitraje.designacion_arbitral_eliminar @desig;
INSERT INTO #resultado SELECT '1.12.c', 'designacion_arbitral e informe_arbitral: alta, modificación y baja',
       IIF(@ok = 1 AND (SELECT COUNT(*) FROM arbitraje.designacion_arbitral) = 0
           AND (SELECT COUNT(*) FROM arbitraje.informe_arbitral) = 0, 'OK', 'FALLO'), '';
GO

-- ============================================================
-- 1.13 publicidad: anunciante, campania, campania_pais_interes, pieza_publicitaria y espacio_publicitario
-- ============================================================

PRINT '--- 1.13.a Alta de anunciantes, campañas, países de interés y piezas';
-- Resultado esperado: 7 anunciantes con una campaña cada uno (vigentes del 01/06 al 19/07/2026), con mercados
-- en 9 países y 12 piezas. El anunciante, la campaña, el país de interés y la pieza temporales se eliminan.
DECLARE @anun INT, @camp INT, @pieza INT, @p INT, @p2 INT, @p3 INT;
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'pais_ARG'), @bra INT = (SELECT valor FROM #id WHERE clave = 'pais_BRA'),
        @ury INT = (SELECT valor FROM #id WHERE clave = 'pais_URY'), @usa INT = (SELECT valor FROM #id WHERE clave = 'pais_USA'),
        @can INT = (SELECT valor FROM #id WHERE clave = 'pais_CAN'), @mex INT = (SELECT valor FROM #id WHERE clave = 'pais_MEX'),
        @fra INT = (SELECT valor FROM #id WHERE clave = 'pais_FRA'), @deu INT = (SELECT valor FROM #id WHERE clave = 'pais_DEU'),
        @jpn INT = (SELECT valor FROM #id WHERE clave = 'pais_JPN'), @esp INT = (SELECT valor FROM #id WHERE clave = 'pais_ESP');

EXEC publicidad.anunciante_insertar 'Mate Pampa', 'Mate Pampa S.A.', 'ventas@matepampa.example', @anun OUTPUT;
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
INSERT INTO #resultado SELECT '1.13.a', 'anunciante, campania, pais_interes y pieza: alta, modificación y baja',
       IIF((SELECT COUNT(*) FROM publicidad.anunciante) = 7 AND (SELECT COUNT(*) FROM publicidad.campania) = 7
           AND (SELECT COUNT(*) FROM publicidad.campania_pais_interes) = 14 AND (SELECT COUNT(*) FROM publicidad.pieza_publicitaria) = 12
           AND (SELECT COUNT(DISTINCT pais_id) FROM publicidad.campania_pais_interes) = 9
           AND EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria WHERE costo_tarifa = 35000 AND idioma = 'espanol'), 'OK', 'FALLO'), '';
GO

PRINT '--- 1.13.b Altas inválidas de publicidad';
-- Resultado esperado: (1) campaña: 3 condiciones (anunciante inexistente, nombre obligatorio, fin anterior al inicio).
-- (2) pieza: 3 condiciones (idioma inválido, mercado que no es país de interés de la campaña, tarifa negativa).
-- (3) anunciante: nombre repetido. (4) baja de anunciante con campañas.
DECLARE @anun INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'Maple Air'),
        @camp INT = (SELECT c.campania_id FROM publicidad.campania c JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id WHERE a.nombre = 'Maple Air'),
        @jpn INT = (SELECT valor FROM #id WHERE clave = 'pais_JPN');
BEGIN TRY
    EXEC publicidad.campania_insertar 9999, '', '2026-07-01', '2026-06-01';
    INSERT INTO #resultado VALUES ('1.13.b', 'campania: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.13.b', 'campania: alta inválida (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC publicidad.pieza_publicitaria_insertar @camp, 'japonés 2', @jpn, -100;
    INSERT INTO #resultado VALUES ('1.13.b', 'pieza_publicitaria: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.13.b', 'pieza_publicitaria: alta inválida (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC publicidad.anunciante_insertar 'MAPLE AIR';
    INSERT INTO #resultado VALUES ('1.13.b', 'anunciante: nombre repetido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.13.b', 'anunciante: nombre repetido', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC publicidad.anunciante_eliminar @anun;
    INSERT INTO #resultado VALUES ('1.13.b', 'anunciante: baja con campañas', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.13.b', 'anunciante: baja con campañas', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 1.13.c ABM de espacio publicitario (de a uno)';
-- Resultado esperado: en P3 se crea el espacio 1 vacío, se le asigna la pieza de Maple Air y se elimina.
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @pieza INT = (SELECT valor FROM #id WHERE clave = 'pieza_CAN'), @esp INT, @ok INT;
EXEC publicidad.espacio_publicitario_insertar @p3, 1, NULL, NULL, @esp OUTPUT;
EXEC publicidad.espacio_publicitario_modificar @esp, @pieza, 4;
SELECT espacio_id, partido_id, numero_espacio, pieza_id, orden_prioridad, fecha_exhibicion, facturado, monto_facturado FROM publicidad.espacio_publicitario;
SELECT @ok = COUNT(*) FROM publicidad.espacio_publicitario WHERE espacio_id = @esp AND pieza_id = @pieza AND orden_prioridad = 4;
-- Resultado esperado: rechazo con 3 condiciones: espacio 7 fuera de rango, pieza inexistente y prioridad fuera de rango.
BEGIN TRY
    EXEC publicidad.espacio_publicitario_insertar @p3, 7, 9999, 9;
    INSERT INTO #resultado VALUES ('1.13.c', 'espacio_publicitario: alta inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.13.c', 'espacio_publicitario: alta inválida (3 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
-- Resultado esperado: rechazo con 2 condiciones: el espacio 1 ya existe y la pieza ya ocupa otro espacio del partido.
BEGIN TRY
    EXEC publicidad.espacio_publicitario_insertar @p3, 1, @pieza;
    INSERT INTO #resultado VALUES ('1.13.c', 'espacio_publicitario: duplicado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('1.13.c', 'espacio_publicitario: espacio y pieza duplicados (2 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC publicidad.espacio_publicitario_eliminar @esp;
INSERT INTO #resultado SELECT '1.13.c', 'espacio_publicitario: alta, modificación y baja', IIF(@ok = 1 AND COUNT(*) = 0, 'OK', 'FALLO'), ''
FROM publicidad.espacio_publicitario;
GO

PRINT '################ PARTE 2: PROCEDIMIENTOS DE LÓGICA DE NEGOCIO ################';
GO

-- ============================================================
-- 2.1 plantel.reemplazar_convocado (baja + alta de último momento, en una transacción)
-- ============================================================

PRINT '--- 2.1.a Reemplazo por lesión';
-- Resultado esperado: el jugador 26 de ARG queda con fecha y motivo de baja; el 27 entra con el mismo dorsal (99)
-- y motivo de alta "Reemplaza a Jugador 26: ...". Argentina sigue con 26 convocados vigentes.
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'),
        @sale INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 26'),
        @entra INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 27');
EXEC plantel.reemplazar_convocado @arg, @sale, @entra, '2026-06-14', 'Lesión muscular en el entrenamiento';
SELECT j.apellido, c.dorsal, c.fecha_alta, c.motivo_alta, c.fecha_baja, c.motivo_baja
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND j.jugador_id IN (@sale, @entra) ORDER BY c.convocatoria_id;
INSERT INTO #resultado SELECT '2.1.a', 'reemplazar_convocado: baja y alta en la misma transacción',
       IIF(SUM(CASE WHEN fecha_baja IS NULL THEN 1 ELSE 0 END) = 26
           AND SUM(CASE WHEN jugador_id = @sale AND fecha_baja = '2026-06-14' AND motivo_baja IS NOT NULL THEN 1 ELSE 0 END) = 1
           AND SUM(CASE WHEN jugador_id = @entra AND fecha_baja IS NULL AND dorsal = 99 THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM plantel.convocatoria WHERE seleccion_id = @arg;
GO

PRINT '--- 2.1.b Reemplazo inválido';
-- Resultado esperado: rechazo (error 50002) con 3 condiciones: el saliente (26) ya no está vigente, el entrante
-- (un jugador de Francia) ya integra una convocatoria vigente y falta el motivo. No cambia ninguna convocatoria.
DECLARE @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'), @antes INT = (SELECT COUNT(*) FROM plantel.convocatoria),
        @sale INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'ARG' AND apellido = 'Jugador 26'),
        @entra INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'FRA' AND apellido = 'Jugador 01');
BEGIN TRY
    EXEC plantel.reemplazar_convocado @arg, @sale, @entra, '2026-06-15', '';
    INSERT INTO #resultado VALUES ('2.1.b', 'reemplazar_convocado: inválido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.1.b', 'reemplazar_convocado: inválido (3 condiciones)',
           IIF(ERROR_NUMBER() = 50002 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3
               AND (SELECT COUNT(*) FROM plantel.convocatoria) = @antes, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 2.2 plantel.cargar_formacion (cabecera + titulares + banco, todo o nada)
-- ============================================================

PRINT '--- 2.2.a Carga de las formaciones de P2 (Argentina vs México)';
-- Resultado esperado: 2 formaciones con 11 titulares y 12 suplentes cada una; el dorsal sale de la convocatoria.
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
INSERT INTO #resultado SELECT '2.2.a', 'cargar_formacion: 11 titulares y 12 suplentes por equipo',
       IIF(COUNT(*) = 46 AND SUM(CAST(fj.titular AS INT)) = 22, 'OK', 'FALLO'), ''
FROM plantel.formacion f JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.partido_id = @p2;
GO

PRINT '--- 2.2.b Carga de formación inválida';
-- Resultado esperado: rechazo (50002) con 5 condiciones: formación ya cargada, esquema inválido, 10 titulares en lugar
-- de 11, un jugador repetido y un jugador que no es de la convocatoria (de Francia). No se inserta nada (todo o nada).
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @mex INT = (SELECT valor FROM #id WHERE clave = 'MEX'),
        @antes INT = (SELECT COUNT(*) FROM plantel.formacion_jugador);
DECLARE @lista plantel.tt_formacion_jugador;
INSERT INTO @lista SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 10, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @mex AND c.fecha_baja IS NULL AND c.dorsal <= 20;
INSERT INTO @lista SELECT jugador_id, 'defensor', 0 FROM plantel.jugador WHERE nombre = 'MEX' AND apellido = 'Jugador 15';
INSERT INTO @lista SELECT jugador_id, 'defensor', 0 FROM plantel.jugador WHERE nombre = 'FRA' AND apellido = 'Jugador 15';
BEGIN TRY
    EXEC plantel.cargar_formacion @p2, 'visitante', '4-4', @lista;
    INSERT INTO #resultado VALUES ('2.2.b', 'cargar_formacion: inválida', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.2.b', 'cargar_formacion: inválida (5 condiciones, sin cambios)',
           IIF(ERROR_NUMBER() = 50002 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 5
               AND (SELECT COUNT(*) FROM plantel.formacion_jugador) = @antes, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 2.3 evento.registrar_sustitucion (por dorsales; ventana automática; reglamento de cambios)
-- ============================================================

PRINT '--- 2.3.a CASO OBLIGATORIO: cambio por lesión dentro de los primeros 20 minutos';
-- Resultado esperado: Francia (visitante de P1) cambia al 3 por el 13 en el minuto 15 del PT, motivo lesión, ventana 1.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @form INT = (SELECT valor FROM #id WHERE clave = 'P1_visitante');
EXEC evento.registrar_sustitucion @p1, 'visitante', 3, 13, 15, 'PT', 'lesion';
SELECT s.minuto, s.periodo, s.numero_ventana, s.motivo, sale.dorsal AS dorsal_sale, entra.dorsal AS dorsal_entra
FROM evento.sustitucion s
JOIN plantel.formacion_jugador sale  ON sale.formacion_id = s.formacion_id AND sale.jugador_id = s.jugador_sale_id
JOIN plantel.formacion_jugador entra ON entra.formacion_id = s.formacion_id AND entra.jugador_id = s.jugador_entra_id
WHERE s.formacion_id = @form;
INSERT INTO #resultado SELECT '2.3.a', 'OBLIGATORIO: cambio por lesión antes del minuto 20',
       IIF(COUNT(*) = 1 AND MAX(minuto) = 15 AND MAX(motivo) = 'lesion' AND MAX(numero_ventana) = 1, 'OK', 'FALLO'), ''
FROM evento.sustitucion WHERE formacion_id = @form;
GO

PRINT '--- 2.3.b Ventanas automáticas y máximo de cambios';
-- Resultado esperado: dos cambios en el minuto 46 comparten la ventana 2; el del minuto 70 abre la ventana 3.
-- Un cambio en el minuto 80 (sería la ventana 4) se rechaza; hecho en el minuto 70 comparte la ventana 3 y es el 5.º.
-- El 6.º cambio en tiempo reglamentario se rechaza. Francia termina con 5 cambios en 3 ventanas.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @form INT = (SELECT valor FROM #id WHERE clave = 'P1_visitante');
EXEC evento.registrar_sustitucion @p1, 'visitante', 7, 14, 46, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p1, 'visitante', 8, 15, 46, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p1, 'visitante', 9, 16, 70, 'ST', 'precaucion';
BEGIN TRY
    EXEC evento.registrar_sustitucion @p1, 'visitante', 10, 17, 80, 'ST', 'tactico';
    INSERT INTO #resultado VALUES ('2.3.b', 'registrar_sustitucion: cuarta ventana', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.3.b', 'registrar_sustitucion: cuarta ventana rechazada',
           IIF(ERROR_NUMBER() = 50001 AND ERROR_MESSAGE() LIKE '%ventanas%', 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC evento.registrar_sustitucion @p1, 'visitante', 10, 17, 70, 'ST', 'tactico';
BEGIN TRY
    EXEC evento.registrar_sustitucion @p1, 'visitante', 11, 18, 70, 'ST', 'tactico';
    INSERT INTO #resultado VALUES ('2.3.b', 'registrar_sustitucion: sexto cambio', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.3.b', 'registrar_sustitucion: sexto cambio reglamentario rechazado',
           IIF(ERROR_NUMBER() = 50001 AND ERROR_MESSAGE() LIKE '%máximo de 5 cambios%', 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
SELECT s.numero_ventana, s.minuto, s.periodo, s.motivo, sale.dorsal AS dorsal_sale, entra.dorsal AS dorsal_entra
FROM evento.sustitucion s
JOIN plantel.formacion_jugador sale  ON sale.formacion_id = s.formacion_id AND sale.jugador_id = s.jugador_sale_id
JOIN plantel.formacion_jugador entra ON entra.formacion_id = s.formacion_id AND entra.jugador_id = s.jugador_entra_id
WHERE s.formacion_id = @form ORDER BY s.numero_ventana, sale.dorsal;
INSERT INTO #resultado SELECT '2.3.b', 'registrar_sustitucion: 5 cambios en 3 ventanas',
       IIF(COUNT(*) = 5 AND COUNT(DISTINCT numero_ventana) = 3 AND SUM(CASE WHEN numero_ventana = 2 THEN 1 ELSE 0 END) = 2, 'OK', 'FALLO'), ''
FROM evento.sustitucion WHERE formacion_id = @form;
GO

PRINT '--- 2.3.c Sustituciones inválidas';
-- Resultado esperado: (1) rechazo (50002) con 2 condiciones: no existen los dorsales 77 ni 88 en la formación.
-- (2) rechazo (50001): el dorsal 3 ya salió y el 13 ya ingresó (2 condiciones, además del tope de cambios).
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
BEGIN TRY
    EXEC evento.registrar_sustitucion @p1, 'visitante', 77, 88, 50, 'ST', 'tactico';
    INSERT INTO #resultado VALUES ('2.3.c', 'registrar_sustitucion: dorsales inexistentes', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.3.c', 'registrar_sustitucion: dorsales inexistentes (2 condiciones)',
           IIF(ERROR_NUMBER() = 50002 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC evento.registrar_sustitucion @p1, 'visitante', 3, 13, 70, 'ST', 'tactico';
    INSERT INTO #resultado VALUES ('2.3.c', 'registrar_sustitucion: jugadores no disponibles', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.3.c', 'registrar_sustitucion: el que sale no está en cancha y el que entra ya participó',
           IIF(ERROR_NUMBER() = 50001 AND ERROR_MESSAGE() LIKE '%no está en cancha%' AND ERROR_MESSAGE() LIKE '%no está disponible en el banco%', 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 2.4 evento.registrar_gol (por dorsales; actualiza el marcador)
-- ============================================================

PRINT '--- 2.4.a Goles de P1';
-- Resultado esperado: empata Francia (gol del 9 con asistencia del 14, que ingresó en el minuto 46) y desnivela
-- Argentina de penal (el 10). Marcador de P1: 2 a 1.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
EXEC evento.registrar_gol @p1, 'visitante', 9, 55, 'jugada', 'ST', 14;
EXEC evento.registrar_gol @p1, 'local', 10, 88, 'penal', 'ST';
SELECT f.condicion, fj.dorsal AS autor, a.dorsal AS asistente, g.minuto, g.periodo, g.tipo_gol
FROM evento.gol g JOIN plantel.formacion f ON f.formacion_id = g.formacion_id
JOIN plantel.formacion_jugador fj ON fj.formacion_id = g.formacion_id AND fj.jugador_id = g.jugador_id
LEFT JOIN plantel.formacion_jugador a ON a.formacion_id = g.formacion_id AND a.jugador_id = g.asistencia_jugador_id
WHERE f.partido_id = @p1 ORDER BY g.minuto;
SELECT partido_id, goles_local, goles_visitante, estado FROM torneo.partido WHERE partido_id = @p1;
INSERT INTO #resultado SELECT '2.4.a', 'registrar_gol: marcador 2-1', IIF(goles_local = 2 AND goles_visitante = 1, 'OK', 'FALLO'), ''
FROM torneo.partido WHERE partido_id = @p1;
GO

PRINT '--- 2.4.b Goles inválidos';
-- Resultado esperado: (1) rechazo (50002): no hay dorsal 77 ni 88. (2) rechazo (50001): el dorsal 20 es un suplente
-- que no ingresó. El marcador sigue 2 a 1.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
BEGIN TRY
    EXEC evento.registrar_gol @p1, 'local', 77, 60, 'jugada', 'ST', 88;
    INSERT INTO #resultado VALUES ('2.4.b', 'registrar_gol: dorsales inexistentes', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.4.b', 'registrar_gol: dorsales inexistentes (2 condiciones)',
           IIF(ERROR_NUMBER() = 50002 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC evento.registrar_gol @p1, 'local', 20, 60, 'jugada', 'ST';
    INSERT INTO #resultado VALUES ('2.4.b', 'registrar_gol: suplente que no ingresó', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.4.b', 'registrar_gol: suplente que no ingresó',
           IIF(ERROR_NUMBER() = 50001 AND (SELECT goles_local FROM torneo.partido WHERE partido_id = @p1) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 2.5 evento.registrar_tarjeta (tarjeta + cálculo de suspensión en una transacción)
-- ============================================================

PRINT '--- 2.5.a Primera amarilla: todavía no hay suspensión';
-- Resultado esperado: amarilla al 5 de Argentina en P1; lleva 1 de las 2 del criterio general => 0 suspensiones.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 40, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Mano intencional',
     @condicion = 'local', @dorsal = 5, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT tarjeta_id, partido_id, persona_id, minuto, periodo, tipo, motivo FROM evento.tarjeta WHERE tarjeta_id = @tarjeta;
INSERT INTO #resultado VALUES ('2.5.a', 'registrar_tarjeta: primera amarilla sin suspensión',
       IIF(@susp = 0 AND NOT EXISTS (SELECT 1 FROM evento.suspension WHERE tarjeta_id = @tarjeta), 'OK', 'FALLO'), '');
GO

PRINT '--- 2.5.b CASO OBLIGATORIO: roja directa';
-- Resultado esperado: roja directa al 4 de Francia en P1 => 1 suspensión sin criterio (no es por acumulación)
-- para el próximo partido programado de Francia: P4.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 75, @periodo = 'ST', @tipo = 'roja', @motivo = 'Agresión a un rival',
     @condicion = 'visitante', @dorsal = 4, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT t.tarjeta_id, t.tipo, t.tipo_expulsion, t.minuto, s.suspension_id, s.criterio_id, s.partido_afectado_id, s.motivo
FROM evento.tarjeta t LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id WHERE t.tarjeta_id = @tarjeta;
INSERT INTO #resultado SELECT '2.5.b', 'OBLIGATORIO: roja directa con suspensión para el próximo partido',
       IIF(@susp = 1 AND COUNT(*) = 1 AND SUM(CASE WHEN partido_afectado_id = @p4 AND criterio_id IS NULL THEN 1 ELSE 0 END) = 1
           AND (SELECT tipo_expulsion FROM evento.tarjeta WHERE tarjeta_id = @tarjeta) = 'roja_directa', 'OK', 'FALLO'), ''
FROM evento.suspension WHERE tarjeta_id = @tarjeta;
GO

PRINT '--- 2.5.c Tarjeta a un integrante del cuerpo técnico';
-- Resultado esperado: amarilla al DT de Francia (identificado por persona_id). Le aplica el criterio específico de
-- cuerpo técnico (3 amarillas), no el general (2) => 0 suspensiones.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @dt INT = (SELECT valor FROM #id WHERE clave = 'persona_DT_FRA'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 76, @periodo = 'ST', @tipo = 'amarilla', @motivo = 'Protesta',
     @persona_id = @dt, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT t.tarjeta_id, pe.tipo_persona, ct.apellido, t.tipo, t.minuto
FROM evento.tarjeta t JOIN plantel.persona pe ON pe.persona_id = t.persona_id JOIN plantel.cuerpo_tecnico ct ON ct.persona_id = t.persona_id
WHERE t.tarjeta_id = @tarjeta;
INSERT INTO #resultado VALUES ('2.5.c', 'registrar_tarjeta: cuerpo técnico', IIF(@tarjeta IS NOT NULL AND @susp = 0, 'OK', 'FALLO'), '');
GO

PRINT '--- 2.5.d Tarjetas inválidas';
-- Resultado esperado: (1) rechazo (50002): no se identifica a la persona. (2) rechazo (50001) con 2 condiciones:
-- el 4 de Francia ya fue expulsado en este partido y el minuto no corresponde al período. No queda ninguna tarjeta ni suspensión nueva.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @tarjetas INT = (SELECT COUNT(*) FROM evento.tarjeta),
        @suspensiones INT = (SELECT COUNT(*) FROM evento.suspension);
BEGIN TRY
    EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 80, @periodo = 'ST', @tipo = 'amarilla', @condicion = 'local', @dorsal = 77;
    INSERT INTO #resultado VALUES ('2.5.d', 'registrar_tarjeta: persona no identificada', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.5.d', 'registrar_tarjeta: persona no identificada', IIF(ERROR_NUMBER() = 50002, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC evento.registrar_tarjeta @partido_id = @p1, @minuto = 20, @periodo = 'ST', @tipo = 'roja', @condicion = 'visitante', @dorsal = 4;
    INSERT INTO #resultado VALUES ('2.5.d', 'registrar_tarjeta: ya expulsado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.5.d', 'registrar_tarjeta: ya expulsado (2 condiciones, sin cambios)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2
               AND (SELECT COUNT(*) FROM evento.tarjeta) = @tarjetas AND (SELECT COUNT(*) FROM evento.suspension) = @suspensiones, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 2.6 publicidad.asignar_espacios_partido (los cuatro espacios según los criterios de la sección H)
-- ============================================================

PRINT '--- 2.6.a CASO OBLIGATORIO: partido en prime time en más de cuatro mercados candidatos';
-- P1 (Argentina vs Francia) se juega a las 00:00 UTC: es prime time (19 a 23 h) en 5 mercados con piezas candidatas:
-- Argentina, Brasil y Uruguay (21 h), Estados Unidos y Canadá (19 h). No lo es en México (18 h), Francia y Alemania (1 h) ni Japón (9 h).
-- Resultado esperado (ver el ranking que devuelve el SP): se eligen 4 de las 7 campañas candidatas:
--   espacio 1: Mate Pampa / Argentina        (país de una selección + prime time)                      prioridad 1
--   espacio 2: Banque Lumière / Francia      (país de una selección)                                   prioridad 1
--   espacio 3: NorthStar Motors / EE.UU.     (mercado de mayor PBI de su campaña + prime time, tarifa 120000)  prioridad 2
--   espacio 4: Sakura Tech / EE.UU.          (ídem, tarifa 100000)                                     prioridad 2
-- Quedan afuera Maple Air (Canadá), Cerveza Tropical (Brasil) y Tequila Sol (México), aun estando las dos primeras en prime time.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
EXEC publicidad.asignar_espacios_partido @p1;
SELECT e.numero_espacio, a.nombre AS anunciante, m.nombre AS mercado, e.orden_prioridad, pz.costo_tarifa, e.fecha_exhibicion, e.facturado
FROM publicidad.espacio_publicitario e
JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id JOIN publicidad.campania c ON c.campania_id = pz.campania_id
JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id JOIN torneo.pais m ON m.pais_id = pz.pais_mercado_id
WHERE e.partido_id = @p1 ORDER BY e.numero_espacio;
INSERT INTO #resultado SELECT '2.6.a', 'OBLIGATORIO: priorización de 4 piezas con más de 4 mercados en prime time',
       IIF(COUNT(*) = 4
           AND SUM(CASE WHEN (e.numero_espacio = 1 AND a.nombre = 'Mate Pampa')
                          OR (e.numero_espacio = 2 AND a.nombre = 'Banque Lumière')
                          OR (e.numero_espacio = 3 AND a.nombre = 'NorthStar Motors')
                          OR (e.numero_espacio = 4 AND a.nombre = 'Sakura Tech') THEN 1 ELSE 0 END) = 4, 'OK', 'FALLO'), ''
FROM publicidad.espacio_publicitario e
JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id JOIN publicidad.campania c ON c.campania_id = pz.campania_id
JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id
WHERE e.partido_id = @p1;
GO

PRINT '--- 2.6.b Reasignación y rechazos';
-- Resultado esperado: (1) rechazo (50002): P1 ya tiene espacios asignados. (2) con @reemplazar = 1 se recalcula y
-- siguen siendo 4 espacios. (3) rechazo: partido inexistente. (4) rechazo: no se puede facturar un partido no finalizado.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
BEGIN TRY
    EXEC publicidad.asignar_espacios_partido @p1;
    INSERT INTO #resultado VALUES ('2.6.b', 'asignar_espacios: ya asignados', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.6.b', 'asignar_espacios_partido: ya asignados', IIF(ERROR_NUMBER() = 50002, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC publicidad.asignar_espacios_partido @p1, @reemplazar = 1, @mostrar_detalle = 0;
INSERT INTO #resultado SELECT '2.6.b', 'asignar_espacios_partido: reemplazo', IIF(COUNT(*) = 4 AND COUNT(pieza_id) = 4, 'OK', 'FALLO'), ''
FROM publicidad.espacio_publicitario WHERE partido_id = @p1;
BEGIN TRY
    EXEC publicidad.asignar_espacios_partido 9999;
    INSERT INTO #resultado VALUES ('2.6.b', 'asignar_espacios: partido inexistente', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.6.b', 'asignar_espacios_partido: partido inexistente', IIF(ERROR_NUMBER() = 50002, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC publicidad.facturar_espacios_partido @p1;
    INSERT INTO #resultado VALUES ('2.6.b', 'facturar: partido no finalizado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.6.b', 'facturar_espacios_partido: partido no finalizado', IIF(ERROR_NUMBER() = 50002, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 2.7 torneo.registrar_resultado (cierre del partido + pauta exhibida) y facturación
-- ============================================================

PRINT '--- 2.7.a Resultado inválido';
-- Resultado esperado: rechazo (50002) con 4 condiciones: el 3 a 0 informado no coincide con los goles registrados (2 a 1),
-- en fase de grupos no hay penales, sólo hay penales si hubo empate, y la asistencia supera la capacidad. P1 sigue 'programado'.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1');
BEGIN TRY
    EXEC torneo.registrar_resultado @p1, 3, 0, 5, 4, 999999;
    INSERT INTO #resultado VALUES ('2.7.a', 'registrar_resultado: inválido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.7.a', 'registrar_resultado: inválido (4 condiciones, sin cambios)',
           IIF(ERROR_NUMBER() = 50002 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 4
               AND (SELECT estado FROM torneo.partido WHERE partido_id = @p1) = 'programado', 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 2.7.b Cierre de P1 y facturación de su pauta';
-- Resultado esperado: P1 queda 'finalizado' 2 a 1 (tomado del detalle de goles) con 80000 espectadores; sus 4 espacios
-- quedan con fecha de exhibición. Al facturar, cada espacio guarda la tarifa de su pieza: total 360000.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @total NUMERIC(14,2);
EXEC torneo.registrar_resultado @partido_id = @p1, @asistencia_publico = 80000;
SELECT partido_id, estado, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p1;
INSERT INTO #resultado SELECT '2.7.b', 'registrar_resultado: finalizado 2-1 y pauta exhibida',
       IIF(p.estado = 'finalizado' AND p.goles_local = 2 AND p.goles_visitante = 1 AND p.asistencia_publico = 80000
           AND (SELECT COUNT(*) FROM publicidad.espacio_publicitario e WHERE e.partido_id = p.partido_id AND e.fecha_exhibicion = p.fecha_hora_utc) = 4, 'OK', 'FALLO'), ''
FROM torneo.partido p WHERE p.partido_id = @p1;
EXEC publicidad.facturar_espacios_partido @p1, @total OUTPUT;
SELECT numero_espacio, pieza_id, orden_prioridad, fecha_exhibicion, facturado, monto_facturado FROM publicidad.espacio_publicitario WHERE partido_id = @p1 ORDER BY numero_espacio;
PRINT 'Total facturado de P1: ' + CAST(@total AS VARCHAR(20));
INSERT INTO #resultado VALUES ('2.7.b', 'facturar_espacios_partido: total 360000', IIF(@total = 360000, 'OK', 'FALLO'), CAST(@total AS VARCHAR(20)));
GO

PRINT '--- 2.7.c Operaciones sobre un partido finalizado';
-- Resultado esperado: cuatro rechazos: no se puede volver a cerrar, ni registrar goles, ni refacturar, ni eliminar un espacio facturado.
DECLARE @p1 INT = (SELECT valor FROM #id WHERE clave = 'P1'), @esp INT;
SELECT @esp = MIN(espacio_id) FROM publicidad.espacio_publicitario WHERE partido_id = @p1;
BEGIN TRY
    EXEC torneo.registrar_resultado @p1;
    INSERT INTO #resultado VALUES ('2.7.c', 'registrar_resultado: ya finalizado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.7.c', 'registrar_resultado: ya finalizado', IIF(ERROR_NUMBER() = 50002, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC evento.registrar_gol @p1, 'local', 10, 89, 'jugada', 'ST';
    INSERT INTO #resultado VALUES ('2.7.c', 'registrar_gol: partido finalizado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.7.c', 'registrar_gol: partido finalizado', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC publicidad.facturar_espacios_partido @p1;
    INSERT INTO #resultado VALUES ('2.7.c', 'facturar: ya facturado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.7.c', 'facturar_espacios_partido: ya facturado', IIF(ERROR_NUMBER() = 50002, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
BEGIN TRY
    EXEC publicidad.espacio_publicitario_eliminar @esp;
    INSERT INTO #resultado VALUES ('2.7.c', 'espacio: baja de facturado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.7.c', 'espacio_publicitario: baja de facturado', IIF(ERROR_NUMBER() = 50001, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 2.8 Acumulación de amarillas, doble amarilla y jugador suspendido fuera de la formación
-- ============================================================

PRINT '--- 2.8.a CASO OBLIGATORIO: suspensión por acumulación de amarillas';
-- Resultado esperado: el 5 de Argentina recibe en P2 su segunda amarilla en partidos distintos (P1 y P2) => 1 suspensión
-- con el criterio general, para el próximo partido de Argentina: P3.
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'),
        @criterio INT = (SELECT valor FROM #id WHERE clave = 'criterio_general'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 20, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Falta táctica',
     @condicion = 'local', @dorsal = 5, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT j.apellido, t.partido_id, t.minuto, t.tipo, s.suspension_id, s.criterio_id, s.partido_afectado_id, s.motivo
FROM evento.tarjeta t JOIN plantel.jugador j ON j.persona_id = t.persona_id LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id
WHERE j.nombre = 'ARG' AND j.apellido = 'Jugador 05' ORDER BY t.tarjeta_id;
INSERT INTO #resultado SELECT '2.8.a', 'OBLIGATORIO: suspensión por acumulación de amarillas',
       IIF(@susp = 1 AND COUNT(*) = 1 AND SUM(CASE WHEN partido_afectado_id = @p3 AND criterio_id = @criterio THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM evento.suspension WHERE tarjeta_id = @tarjeta;
GO

PRINT '--- 2.8.b CASO OBLIGATORIO: expulsión por doble amonestación';
-- Resultado esperado: el 8 de México recibe dos amarillas en P2; la segunda se registra sola como roja por doble amarilla
-- y genera 1 suspensión. México no tiene otro partido programado: queda con partido NULL ("a definir").
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2'), @tarjeta INT, @susp INT;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 30, @periodo = 'PT', @tipo = 'amarilla', @motivo = 'Juego brusco',
     @condicion = 'visitante', @dorsal = 8;
EXEC evento.registrar_tarjeta @partido_id = @p2, @minuto = 60, @periodo = 'ST', @tipo = 'amarilla', @motivo = 'Reiteración de faltas',
     @condicion = 'visitante', @dorsal = 8, @tarjeta_id = @tarjeta OUTPUT, @suspensiones_generadas = @susp OUTPUT;
SELECT j.apellido, t.minuto, t.periodo, t.tipo, t.tipo_expulsion, s.criterio_id, s.partido_afectado_id, s.motivo
FROM evento.tarjeta t JOIN plantel.jugador j ON j.persona_id = t.persona_id LEFT JOIN evento.suspension s ON s.tarjeta_id = t.tarjeta_id
WHERE j.nombre = 'MEX' AND j.apellido = 'Jugador 08' ORDER BY t.tarjeta_id;
INSERT INTO #resultado SELECT '2.8.b', 'OBLIGATORIO: expulsión por doble amarilla',
       IIF(@susp = 1 AND t.tipo = 'roja' AND t.tipo_expulsion = 'doble_amarilla'
           AND (SELECT COUNT(*) FROM evento.suspension s WHERE s.tarjeta_id = t.tarjeta_id AND s.partido_afectado_id IS NULL AND s.criterio_id IS NULL) = 1, 'OK', 'FALLO'), ''
FROM evento.tarjeta t WHERE t.tarjeta_id = @tarjeta;
GO

PRINT '--- 2.8.c Cierre de P2 sin goles (resultado tomado del detalle: 0 a 0)';
-- Resultado esperado: P2 finalizado 0 a 0 sin informar goles.
DECLARE @p2 INT = (SELECT valor FROM #id WHERE clave = 'P2');
EXEC torneo.registrar_resultado @partido_id = @p2, @asistencia_publico = 83000;
SELECT partido_id, estado, goles_local, goles_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p2;
INSERT INTO #resultado SELECT '2.8.c', 'registrar_resultado: 0-0 desde el detalle',
       IIF(estado = 'finalizado' AND goles_local = 0 AND goles_visitante = 0, 'OK', 'FALLO'), '' FROM torneo.partido WHERE partido_id = @p2;
GO

PRINT '--- 2.8.d CASO OBLIGATORIO: el suspendido queda afuera de la formación del siguiente partido';
-- Resultado esperado: (1) rechazo (50002) al cargar la formación de Argentina para P3 con el dorsal 5 de titular:
-- "Jugadores suspendidos para este partido: Jugador 05 ARG". (2) rechazo equivalente por el ABM de a un jugador.
-- (3) la misma formación con el 12 en lugar del 5 se carga bien.
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @arg INT = (SELECT valor FROM #id WHERE clave = 'ARG'), @form INT, @j5 INT;
DECLARE @con5 plantel.tt_formacion_jugador, @sin5 plantel.tt_formacion_jugador;
INSERT INTO @con5 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23;
INSERT INTO @sin5 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 12, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
WHERE c.seleccion_id = @arg AND c.fecha_baja IS NULL AND c.dorsal <= 23 AND c.dorsal <> 5;
SELECT @j5 = jugador_id FROM plantel.convocatoria WHERE seleccion_id = @arg AND dorsal = 5 AND fecha_baja IS NULL;
BEGIN TRY
    EXEC plantel.cargar_formacion @p3, 'local', '4-3-3', @con5;
    INSERT INTO #resultado VALUES ('2.8.d', 'cargar_formacion: con suspendido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.8.d', 'OBLIGATORIO: formación con el jugador suspendido rechazada',
           IIF(ERROR_NUMBER() = 50002 AND ERROR_MESSAGE() LIKE '%suspendidos para este partido: Jugador 05 ARG%'
               AND NOT EXISTS (SELECT 1 FROM plantel.formacion WHERE partido_id = @p3), 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC plantel.cargar_formacion @p3, 'local', '4-3-3', @sin5, @form OUTPUT;
BEGIN TRY
    EXEC plantel.formacion_jugador_insertar @form, @j5, 'defensor', 0;
    INSERT INTO #resultado VALUES ('2.8.d', 'formacion_jugador: suspendido', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.8.d', 'formacion_jugador_insertar: suspendido rechazado',
           IIF(ERROR_NUMBER() = 50001 AND ERROR_MESSAGE() LIKE '%suspendido para este partido%', 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
SELECT fj.dorsal, j.apellido, fj.posicion, fj.titular FROM plantel.formacion_jugador fj JOIN plantel.jugador j ON j.jugador_id = fj.jugador_id
WHERE fj.formacion_id = @form AND fj.titular = 1 ORDER BY fj.dorsal;
INSERT INTO #resultado SELECT '2.8.d', 'OBLIGATORIO: formación sin el suspendido cargada',
       IIF(COUNT(*) = 22 AND SUM(CAST(titular AS INT)) = 11 AND SUM(CASE WHEN dorsal = 5 THEN 1 ELSE 0 END) = 0, 'OK', 'FALLO'), ''
FROM plantel.formacion_jugador WHERE formacion_id = @form;
GO

-- ============================================================
-- 2.9 arbitraje.designar_arbitros (terna completa, con validación de conflicto de nacionalidad)
-- ============================================================

PRINT '--- 2.9.a CASO OBLIGATORIO: designación descartada por conflicto de nacionalidad';
-- Resultado esperado: rechazo (50002) con 3 condiciones para P3 (Argentina vs Japón): terna incompleta (falta el VAR),
-- un mismo árbitro en dos roles y conflicto de nacionalidad del árbitro argentino Facundo Tello. No se designa a nadie.
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @arg INT = (SELECT valor FROM #id WHERE clave = 'arb_ARG'),
        @ury2 INT = (SELECT valor FROM #id WHERE clave = 'arb_URY2'), @usa INT = (SELECT valor FROM #id WHERE clave = 'arb_USA');
BEGIN TRY
    EXEC arbitraje.designar_arbitros @p3, @arg, @ury2, @ury2, @usa, NULL;
    INSERT INTO #resultado VALUES ('2.9.a', 'designar_arbitros: conflicto', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.9.a', 'OBLIGATORIO: designación descartada por conflicto de nacionalidad (3 condiciones)',
           IIF(ERROR_NUMBER() = 50002 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 3
               AND ERROR_MESSAGE() LIKE '%Conflicto de nacionalidad%Facundo Tello%'
               AND NOT EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral WHERE partido_id = @p3), 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

PRINT '--- 2.9.b Designación válida en fase de grupos y con advertencia en eliminación directa';
-- Resultado esperado: P3 queda con sus 5 roles y sin advertencia (fase de grupos). P4 (dieciseisavos, Francia vs Japón)
-- queda con sus 5 roles y devuelve una ADVERTENCIA por César Ramos (México) y Wilton Sampaio (Brasil): sus países tienen
-- selección en competencia. No es un bloqueo.
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
INSERT INTO #resultado VALUES ('2.9.b', 'designar_arbitros: terna completa sin advertencia en grupos',
       IIF(@adv3 IS NULL AND (SELECT COUNT(*) FROM arbitraje.designacion_arbitral WHERE partido_id = @p3) = 5, 'OK', 'FALLO'), ISNULL(@adv3, ''));
INSERT INTO #resultado VALUES ('2.9.b', 'designar_arbitros: advertencia desde dieciseisavos (no bloquea)',
       IIF(@adv4 LIKE 'ADVERTENCIA%' AND @adv4 LIKE '%Ramos%' AND @adv4 LIKE '%Sampaio%' AND (SELECT COUNT(*) FROM arbitraje.designacion_arbitral WHERE partido_id = @p4) = 5, 'OK', 'FALLO'), ISNULL(@adv4, ''));
GO

PRINT '--- 2.9.c Designación sobre un partido que ya tiene terna';
-- Resultado esperado: rechazo (50002): el partido ya tiene árbitros designados. Sigue con sus 5 designaciones.
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @ury1 INT = (SELECT valor FROM #id WHERE clave = 'arb_URY1'),
        @ury2 INT = (SELECT valor FROM #id WHERE clave = 'arb_URY2'), @deu1 INT = (SELECT valor FROM #id WHERE clave = 'arb_DEU1'),
        @deu2 INT = (SELECT valor FROM #id WHERE clave = 'arb_DEU2'), @usa INT = (SELECT valor FROM #id WHERE clave = 'arb_USA');
BEGIN TRY
    EXEC arbitraje.designar_arbitros @p3, @ury1, @ury2, @deu2, @usa, @deu1;
    INSERT INTO #resultado VALUES ('2.9.c', 'designar_arbitros: ya designado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.9.c', 'designar_arbitros: partido con terna ya designada',
           IIF(ERROR_NUMBER() = 50002 AND (SELECT COUNT(*) FROM arbitraje.designacion_arbitral WHERE partido_id = @p3) = 5, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
GO

-- ============================================================
-- 2.10 Partido de eliminación directa completo (P4: Francia vs Japón, dieciseisavos)
-- ============================================================

PRINT '--- 2.10.a Formaciones de P4: el expulsado por roja directa en P1 no puede jugar';
-- Resultado esperado: rechazo de la formación de Francia con el dorsal 4 (suspendido por la roja directa de P1);
-- sin el 4 se carga bien. La de Japón se carga completa.
DECLARE @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'), @fra INT = (SELECT valor FROM #id WHERE clave = 'FRA'),
        @jpn INT = (SELECT valor FROM #id WHERE clave = 'JPN'), @form INT;
DECLARE @con4 plantel.tt_formacion_jugador, @sin4 plantel.tt_formacion_jugador, @japon plantel.tt_formacion_jugador;
INSERT INTO @con4 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL;
INSERT INTO @sin4 SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 12, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @fra AND c.fecha_baja IS NULL AND c.dorsal <> 4;
INSERT INTO @japon SELECT c.jugador_id, j.posicion_habitual, IIF(c.dorsal <= 11, 1, 0)
FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE c.seleccion_id = @jpn AND c.fecha_baja IS NULL;
BEGIN TRY
    EXEC plantel.cargar_formacion @p4, 'local', '4-2-3-1', @con4;
    INSERT INTO #resultado VALUES ('2.10.a', 'cargar_formacion: expulsado', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.10.a', 'cargar_formacion: suspendido por roja directa rechazado',
           IIF(ERROR_NUMBER() = 50002 AND ERROR_MESSAGE() LIKE '%Jugador 04 FRA%', 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC plantel.cargar_formacion @p4, 'local', '4-2-3-1', @sin4, @form OUTPUT;   INSERT INTO #id VALUES ('P4_local', @form);
EXEC plantel.cargar_formacion @p4, 'visitante', '3-4-3', @japon, @form OUTPUT; INSERT INTO #id VALUES ('P4_visitante', @form);
INSERT INTO #resultado SELECT '2.10.a', 'cargar_formacion: formaciones de P4', IIF(COUNT(*) = 45, 'OK', 'FALLO'), ''
FROM plantel.formacion f JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id WHERE f.partido_id = @p4;
GO

PRINT '--- 2.10.b Cambio adicional del tiempo suplementario';
-- Resultado esperado: Japón hace 5 cambios en 3 ventanas del ST. El 6.º en el ST se rechaza con 2 condiciones (máximo de
-- cambios y de ventanas). En el alargue se acepta el 6.º (cambio y ventana adicionales). El 7.º se rechaza con 2 condiciones.
DECLARE @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4'), @form INT = (SELECT valor FROM #id WHERE clave = 'P4_visitante');
EXEC evento.registrar_sustitucion @p4, 'visitante', 2, 12, 50, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 3, 13, 50, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 4, 14, 65, 'ST', 'lesion';
EXEC evento.registrar_sustitucion @p4, 'visitante', 5, 15, 65, 'ST', 'tactico';
EXEC evento.registrar_sustitucion @p4, 'visitante', 6, 16, 80, 'ST', 'precaucion';
BEGIN TRY
    EXEC evento.registrar_sustitucion @p4, 'visitante', 7, 17, 85, 'ST', 'tactico';
    INSERT INTO #resultado VALUES ('2.10.b', 'registrar_sustitucion: sexto en ST', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.10.b', 'registrar_sustitucion: sexto cambio en tiempo reglamentario (2 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC evento.registrar_sustitucion @p4, 'visitante', 7, 17, 95, 'alargue_1', 'tactico';
BEGIN TRY
    EXEC evento.registrar_sustitucion @p4, 'visitante', 8, 18, 110, 'alargue_2', 'tactico';
    INSERT INTO #resultado VALUES ('2.10.b', 'registrar_sustitucion: séptimo', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.10.b', 'registrar_sustitucion: séptimo cambio rechazado (2 condiciones)',
           IIF(ERROR_NUMBER() = 50001 AND LEN(ERROR_MESSAGE()) - LEN(REPLACE(ERROR_MESSAGE(), CHAR(10) + '-', CHAR(10))) = 2, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
SELECT numero_ventana, periodo, minuto, COUNT(*) AS cambios FROM evento.sustitucion WHERE formacion_id = @form
GROUP BY numero_ventana, periodo, minuto ORDER BY numero_ventana;
INSERT INTO #resultado SELECT '2.10.b', 'registrar_sustitucion: cambio adicional en el alargue (6 cambios, 4 ventanas)',
       IIF(COUNT(*) = 6 AND MAX(numero_ventana) = 4 AND SUM(CASE WHEN periodo = 'alargue_1' THEN 1 ELSE 0 END) = 1, 'OK', 'FALLO'), ''
FROM evento.sustitucion WHERE formacion_id = @form;
GO

PRINT '--- 2.10.c Empate, definición por penales y cierre';
-- Resultado esperado: 1 a 1 en los 120 minutos. Cerrar el partido sin penales se rechaza (eliminación directa).
-- Con la tanda registrada (Francia 2, Japón 1) se cierra: goles 1-1, penales 2-1. Los goles de la tanda no suman al marcador.
DECLARE @p4 INT = (SELECT valor FROM #id WHERE clave = 'P4');
EXEC evento.registrar_gol @p4, 'local', 9, 30, 'tiro_libre', 'PT';
EXEC evento.registrar_gol @p4, 'visitante', 10, 77, 'jugada', 'ST', 12;
BEGIN TRY
    EXEC torneo.registrar_resultado @partido_id = @p4, @asistencia_publico = 70000;
    INSERT INTO #resultado VALUES ('2.10.c', 'registrar_resultado: empate sin penales', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.10.c', 'registrar_resultado: empate sin penales en eliminación directa',
           IIF(ERROR_NUMBER() = 50002 AND ERROR_MESSAGE() LIKE '%definirse por penales%', 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC evento.registrar_gol @p4, 'local', 9, 120, 'penal', 'penales';
EXEC evento.registrar_gol @p4, 'visitante', 10, 120, 'penal', 'penales';
EXEC evento.registrar_gol @p4, 'local', 10, 120, 'penal', 'penales';
EXEC torneo.registrar_resultado @partido_id = @p4, @asistencia_publico = 70000;
SELECT partido_id, fase, estado, goles_local, goles_visitante, penales_local, penales_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p4;
INSERT INTO #resultado SELECT '2.10.c', 'registrar_resultado: 1-1 con penales 2-1',
       IIF(estado = 'finalizado' AND goles_local = 1 AND goles_visitante = 1 AND penales_local = 2 AND penales_visitante = 1, 'OK', 'FALLO'), ''
FROM torneo.partido WHERE partido_id = @p4;
GO

PRINT '--- 2.10.d Resultado sin detalle (como llegaría de una importación) y sus validaciones';
-- Resultado esperado: se programa un partido de grupos sin formaciones (México vs Japón). Cerrarlo sin informar goles se
-- rechaza; informando 2 a 0 queda finalizado.
DECLARE @mx INT = (SELECT valor FROM #id WHERE clave = 'sede_MX'), @mex INT = (SELECT valor FROM #id WHERE clave = 'MEX'),
        @jpn INT = (SELECT valor FROM #id WHERE clave = 'JPN'), @p5 INT;
EXEC torneo.partido_insertar @mx, '2026-06-25T18:00:00-06:00', 'grupos', @mex, @jpn, NULL, @p5 OUTPUT;
BEGIN TRY
    EXEC torneo.registrar_resultado @partido_id = @p5;
    INSERT INTO #resultado VALUES ('2.10.d', 'registrar_resultado: sin detalle ni goles', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    PRINT ERROR_MESSAGE();
    INSERT INTO #resultado VALUES ('2.10.d', 'registrar_resultado: sin detalle exige informar el resultado', IIF(ERROR_NUMBER() = 50002, 'OK', 'FALLO'), ERROR_MESSAGE());
END CATCH;
EXEC torneo.registrar_resultado @p5, 2, 0, NULL, NULL, 60000;
SELECT partido_id, fase, estado, goles_local, goles_visitante, asistencia_publico FROM torneo.partido WHERE partido_id = @p5;
INSERT INTO #resultado SELECT '2.10.d', 'registrar_resultado: resultado informado sin detalle',
       IIF(estado = 'finalizado' AND goles_local = 2 AND goles_visitante = 0, 'OK', 'FALLO'), '' FROM torneo.partido WHERE partido_id = @p5;
GO

-- ============================================================
-- 2.11 Transaccionalidad: todo o nada en operaciones que afectan varias tablas
-- ============================================================

PRINT '--- 2.11.a Una operación multi-tabla se deshace completa';
-- Una roja genera 1 tarjeta (evento.tarjeta) y 1 suspensión (evento.suspension). Se la ejecuta dentro de una
-- transacción abierta por quien llama y se hace ROLLBACK.
-- Resultado esperado: dentro de la transacción hay +1 tarjeta y +1 suspensión; después del ROLLBACK no queda
-- ninguna de las dos (el SP no confirma por su cuenta lo que no abrió).
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
INSERT INTO #resultado VALUES ('2.11.a', 'transacción: tarjeta + suspensión se deshacen juntas',
       IIF(@t1 = @t0 + 1 AND @s1 = @s0 + 1 AND (SELECT COUNT(*) FROM evento.tarjeta) = @t0
           AND (SELECT COUNT(*) FROM evento.suspension) = @s0, 'OK', 'FALLO'), '');
GO

PRINT '--- 2.11.b Un error a mitad de una transacción deshace también lo ya hecho';
-- En una misma transacción se registra un gol válido de Argentina en P3 (inserta en evento.gol y actualiza
-- torneo.partido) y luego uno inválido.
-- Resultado esperado: el segundo falla, la transacción se revierte y tampoco queda el primer gol: P3 sigue sin goles
-- y con el marcador sin cargar.
DECLARE @p3 INT = (SELECT valor FROM #id WHERE clave = 'P3'), @g0 INT = (SELECT COUNT(*) FROM evento.gol), @mensaje VARCHAR(2100);
BEGIN TRY
    BEGIN TRANSACTION;
        EXEC evento.registrar_gol @p3, 'local', 9, 12, 'jugada', 'PT';
        EXEC evento.registrar_gol @p3, 'local', 9, 200, 'jugada', 'PT';
    COMMIT TRANSACTION;
    INSERT INTO #resultado VALUES ('2.11.b', 'transacción: error a mitad de camino', 'FALLO', 'No se rechazó');
END TRY
BEGIN CATCH
    SET @mensaje = ERROR_MESSAGE();
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT @mensaje;
    INSERT INTO #resultado VALUES ('2.11.b', 'transacción: un error revierte también el gol válido previo',
           IIF((SELECT COUNT(*) FROM evento.gol) = @g0
               AND (SELECT goles_local FROM torneo.partido WHERE partido_id = @p3) IS NULL, 'OK', 'FALLO'), @mensaje);
END CATCH;
SELECT partido_id, estado, goles_local, goles_visitante FROM torneo.partido WHERE partido_id = @p3;
GO

-- ============================================================
-- RESUMEN
-- ============================================================

PRINT '################ RESUMEN ################';
-- Resultado esperado: todas las pruebas en OK y ninguna en FALLO.
SELECT resultado, COUNT(*) AS pruebas FROM #resultado GROUP BY resultado;
SELECT orden, prueba, descripcion, resultado FROM #resultado ORDER BY orden;
IF EXISTS (SELECT 1 FROM #resultado WHERE resultado <> 'OK')
    SELECT 'PRUEBAS FALLIDAS' AS atencion, prueba, descripcion, detalle FROM #resultado WHERE resultado <> 'OK' ORDER BY orden;
ELSE
    PRINT 'Todas las pruebas finalizaron con el resultado esperado.';
GO

SET NOEXEC OFF;
GO
