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
--   Se crea la preparacion para la ejecucion del testeo exhaustivo de los SP.
--   En el mismo, se insertan todos los datos que se utilizaran en el testeo.
-- 
-- CÓMO USARLO:
--   Se ejecuta de una sola vez, se insertan los datos y luego se pasa a test_exhaustivo.
--   Una vez terminado de testear, se ejecuta la limpieza.
-- ============================================================

USE mundial_2026;
GO

SET NOCOUNT ON;
GO


-- =======================================================================================================
--                                          PREPARACION
-- =======================================================================================================

-- Preparación de torneo.parametro_* (ejecutar UNA sola vez)
DECLARE @h INT = (SELECT valor FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta'),
        @d INT = (SELECT valor FROM torneo.parametro WHERE clave = 'prime_time_hora_desde');
EXEC torneo.parametro_insertar 'tst_ins', 1, 'Base de insertar (para duplicados)';
EXEC torneo.parametro_insertar 'tst_mod', 10, 'Base de modificar';
EXEC torneo.parametro_insertar 'tst_elim', 5, 'Base de eliminar';
EXEC torneo.parametro_insertar 'tst_backup_hasta', @h, 'Respaldo de prime_time_hora_hasta';
EXEC torneo.parametro_insertar 'tst_backup_desde', @d, 'Respaldo de prime_time_hora_desde';
GO


-- Preparación de torneo.confederacion_* (ejecutar UNA sola vez)
DECLARE @id INT, @x INT, @conmebol INT;
SET @id = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CAF');      IF @id IS NOT NULL EXEC torneo.confederacion_eliminar @id;
SET @id = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CONCACAF'); IF @id IS NOT NULL EXEC torneo.confederacion_eliminar @id;
SET @id = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'OFC');      IF @id IS NOT NULL EXEC torneo.confederacion_eliminar @id;
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

-- Preparación de torneo.pais_* (ejecutar UNA sola vez)
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

-- Preparación de torneo.sede_* (ejecutar UNA sola vez)
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

-- Preparación de torneo.seleccion_* (ejecutar UNA sola vez)
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
GO

-- Preparación de torneo.partido* (ejecutar UNA sola vez)
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
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id IN (@p_fin, @p_all);
GO

-- Preparación de plantel.cuerpo_tecnico_* (ejecutar UNA sola vez)
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

-- Preparación de plantel.jugador_* (ejecutar UNA sola vez)
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

-- Preparación de plantel.persona_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)
-- 1) Limpieza de la corrida anterior: borra las personas de prueba que no tengan registros asociados
IF OBJECT_ID('tempdb..##test_persona') IS NOT NULL
BEGIN
    DELETE p
    FROM plantel.persona p
    WHERE p.persona_id IN (SELECT persona_id FROM ##test_persona)
      AND NOT EXISTS (SELECT 1 FROM plantel.jugador        WHERE persona_id = p.persona_id)
      AND NOT EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico WHERE persona_id = p.persona_id)
      AND NOT EXISTS (SELECT 1 FROM evento.tarjeta         WHERE persona_id = p.persona_id);
END;
GO

-- 2) Tabla de claves siempre nueva, con clave UNIQUE
DROP TABLE IF EXISTS ##test_persona;
CREATE TABLE ##test_persona (
    persona_id INT         NOT NULL PRIMARY KEY,
    clave      VARCHAR(10) NOT NULL UNIQUE
);
GO

-- 3) Alta de las personas de prueba
DECLARE @id INT;
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'mod');      -- persona a modificar (sin registros asociados)
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'elim');     -- baja valida (tipo jugador, sin registros)
EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'elim_ct'); -- baja valida (tipo cuerpo_tecnico, sin registros)
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'jug');      -- registrada en plantel.jugador
EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'ct');      -- registrada en plantel.cuerpo_tecnico
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'tarj');     -- con tarjetas
EXEC plantel.persona_insertar 'jugador',        @id OUTPUT; INSERT INTO ##test_persona VALUES (@id, 'todo');     -- jugador + cuerpo tecnico + tarjetas
GO

-- Preparación de plantel.convocatoria_* (ejecutar UNA sola vez)
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


-- Preparación de plantel.formacion_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)
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

-- Preparación de plantel.formacion_jugador_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)
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

-- Preparación de evento.sustitucion_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)
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


-- Preparación de evento.gol_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)
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
-- Preparación de evento.tarjeta_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)
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
UPDATE torneo.partido SET estado = 'finalizado' WHERE partido_id = @pz;
GO

-- Preparación de evento.criterio_suspension_* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)
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

-- Preparación de campania_modificar (ejecutar UNA sola vez)
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

-- Preparación de campania_eliminar (ejecutar UNA sola vez)
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

-- Preparación de campania_pais_interes_* (ejecutar UNA sola vez)
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

-- Preparación de pieza_publicitaria* (ejecutar UNA sola vez)
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

-- Preparación de espacio_publicitario* (ejecutar UNA sola vez)
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

-- Preparación de arbitraje.* (ejecutar UNA sola vez, y usar siempre la misma ventana de consulta)
-- Crea 8 países (ZRA-ZRH), 7 selecciones, 3 sedes, 6 partidos, los árbitros, idiomas, designaciones e informes.
--   ZRA: árbitros "nacionales" (su selección NO juega ningún partido de prueba, queda "en carrera")
--   ZRB/ZRC/ZRD/ZRE/ZRF: selecciones que juegan los partidos
--   ZRG: selección eliminada en octavos (su árbitro no genera advertencia)
--   ZRH: país libre, sin selección (destino de cambio de país)
-- Partidos (todos con el mismo grupo A):
--   par_gr   grupos        15/06 15:00  ZRB vs ZRC  (designaciones, informes, 24 h)
--   par_24   grupos        16/06 09:00  ZRD vs ZRE  (a 18 h de par_gr: choque de 24 h)
--   par_fin  grupos        18/06 15:00  ZRB vs ZRD  (finalizado, con designación e informe)
--   par_mod  grupos        22/06 15:00  ZRC vs ZRD  (modificar designaciones)
--   par_oct  octavos       28/06 15:00  ZRG vs ZRF  (finalizado: ZRG eliminada)
--   par_elim dieciseisavos 01/07 15:00  ZRE vs ZRF  (advertencia de nacionalidad)
IF OBJECT_ID('tempdb..##test_arbitraje') IS NULL
    CREATE TABLE ##test_arbitraje (clave VARCHAR(12) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY, id INT NOT NULL);
GO
IF EXISTS (SELECT 1 FROM ##test_arbitraje)
    THROW 50000, 'La preparación de arbitraje.* ya fue ejecutada en esta sesión (ver ##test_arbitraje).', 1;
IF EXISTS (SELECT 1 FROM torneo.pais WHERE codigo_iso LIKE 'ZR[A-H]')
    THROW 50000, 'Ya hay países ZRA-ZRH (rango reservado para las pruebas de arbitraje): ejecutar antes la limpieza de arbitraje.*.', 1;
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
IF @conf IS NULL THROW 50000, 'No hay confederaciones en torneo.confederacion: cargar al menos una con torneo.confederacion_insertar.', 1;
DECLARE @id INT, @x INT, @d INT,
        @pa INT, @pb INT, @pc INT, @pd INT, @pe INT, @pf INT, @pg INT, @ph INT,
        @sa INT, @sb INT, @sc INT, @sd INT, @se INT, @sf INT, @sg INT,
        @s1 INT, @s2 INT, @s3 INT,
        @p_gr INT, @p_24 INT, @p_fin INT, @p_mod INT, @p_oct INT, @p_elim INT,
        @a_prin INT, @a_as1 INT, @a_as2 INT, @a_var INT, @a_m1 INT, @a_m2 INT, @a_conf INT, @a_g INT,
        @a_mod INT, @a_base INT, @a_elim INT, @a_idi INT, @a_libre INT, @a_ins INT, @a_err INT,
        @d_inf INT, @d_fin INT;

-- Países y selecciones
EXEC torneo.pais_insertar 'ZRA', 'Test Arb Pais A', 'UTC-03', 0, @pa OUTPUT; INSERT INTO ##test_arbitraje VALUES ('pais_a', @pa);
EXEC torneo.pais_insertar 'ZRB', 'Test Arb Pais B', 'UTC-03', 0, @pb OUTPUT; INSERT INTO ##test_arbitraje VALUES ('pais_b', @pb);
EXEC torneo.pais_insertar 'ZRC', 'Test Arb Pais C', 'UTC-03', 0, @pc OUTPUT; INSERT INTO ##test_arbitraje VALUES ('pais_c', @pc);
EXEC torneo.pais_insertar 'ZRD', 'Test Arb Pais D', 'UTC-03', 0, @pd OUTPUT; INSERT INTO ##test_arbitraje VALUES ('pais_d', @pd);
EXEC torneo.pais_insertar 'ZRE', 'Test Arb Pais E', 'UTC-03', 0, @pe OUTPUT; INSERT INTO ##test_arbitraje VALUES ('pais_e', @pe);
EXEC torneo.pais_insertar 'ZRF', 'Test Arb Pais F', 'UTC-03', 0, @pf OUTPUT; INSERT INTO ##test_arbitraje VALUES ('pais_f', @pf);
EXEC torneo.pais_insertar 'ZRG', 'Test Arb Pais G', 'UTC-03', 0, @pg OUTPUT; INSERT INTO ##test_arbitraje VALUES ('pais_g', @pg);
EXEC torneo.pais_insertar 'ZRH', 'Test Arb Pais H', 'UTC-03', 0, @ph OUTPUT; INSERT INTO ##test_arbitraje VALUES ('pais_h', @ph);   -- libre: sin selección

EXEC torneo.seleccion_insertar @pa, @conf, 'A', @sa OUTPUT;   -- en carrera, no juega ningún partido
EXEC torneo.seleccion_insertar @pb, @conf, 'A', @sb OUTPUT;
EXEC torneo.seleccion_insertar @pc, @conf, 'A', @sc OUTPUT;
EXEC torneo.seleccion_insertar @pd, @conf, 'A', @sd OUTPUT;
EXEC torneo.seleccion_insertar @pe, @conf, 'A', @se OUTPUT;
EXEC torneo.seleccion_insertar @pf, @conf, 'A', @sf OUTPUT;
EXEC torneo.seleccion_insertar @pg, @conf, 'A', @sg OUTPUT;   -- eliminada en octavos

-- Sedes y partidos
EXEC torneo.sede_insertar 'Test Arb Sede 1', 'Ciudad Arb', @pa, 50000, 'UTC-03', @s1 OUTPUT;
EXEC torneo.sede_insertar 'Test Arb Sede 2', 'Ciudad Arb', @pa, 50000, 'UTC-03', @s2 OUTPUT;
EXEC torneo.sede_insertar 'Test Arb Sede 3', 'Ciudad Arb', @pa, 50000, 'UTC-03', @s3 OUTPUT;

EXEC torneo.partido_insertar @s1, '2026-06-15 15:00:00 -03:00', 'grupos',        @sb, @sc, NULL, @p_gr   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('par_gr',   @p_gr);
EXEC torneo.partido_insertar @s2, '2026-06-16 09:00:00 -03:00', 'grupos',        @sd, @se, NULL, @p_24   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('par_24',   @p_24);
EXEC torneo.partido_insertar @s1, '2026-06-18 15:00:00 -03:00', 'grupos',        @sb, @sd, NULL, @p_fin  OUTPUT; INSERT INTO ##test_arbitraje VALUES ('par_fin',  @p_fin);
EXEC torneo.partido_insertar @s3, '2026-06-22 15:00:00 -03:00', 'grupos',        @sc, @sd, NULL, @p_mod  OUTPUT; INSERT INTO ##test_arbitraje VALUES ('par_mod',  @p_mod);
EXEC torneo.partido_insertar @s2, '2026-06-28 15:00:00 -03:00', 'octavos',       @sg, @sf, NULL, @p_oct  OUTPUT; INSERT INTO ##test_arbitraje VALUES ('par_oct',  @p_oct);
EXEC torneo.partido_insertar @s1, '2026-07-01 15:00:00 -03:00', 'dieciseisavos', @se, @sf, NULL, @p_elim OUTPUT; INSERT INTO ##test_arbitraje VALUES ('par_elim', @p_elim);

-- Árbitros
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Principal',    @pa, 'FIFA',          '1980-01-01', @a_prin  OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_prin',  @a_prin);   -- designado en par_gr y par_fin
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Asistente 1',  @pa, 'FIFA',          '1980-01-01', @a_as1   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_as1',   @a_as1);    -- designado en par_gr (24 h)
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Asistente 2',  @pa, 'FIFA',          '1980-01-01', @a_as2   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_as2',   @a_as2);    -- designado en par_gr (con informes)
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Var',          @pa, 'FIFA',          '1980-01-01', @a_var   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_var',   @a_var);    -- designado en par_24 (baja válida)
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Mod Uno',      @pa, 'FIFA',          '1980-01-01', @a_m1    OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_m1',    @a_m1);     -- designado en par_mod (principal)
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Mod Dos',      @pa, 'FIFA',          '1980-01-01', @a_m2    OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_m2',    @a_m2);     -- designado en par_mod (asistente_1)
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Conflicto',    @pd, 'FIFA',          '1980-01-01', @a_conf  OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_conf',  @a_conf);   -- país ZRD: su selección juega par_24, par_fin y par_mod
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Pais G',       @pg, 'FIFA',          '1980-01-01', @a_g     OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_g',     @a_g);      -- país ZRG: selección eliminada
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Mod',          @pa, 'confederacion', '1980-01-01', @a_mod   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_mod',   @a_mod);    -- a modificar (con idiomas)
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Base',         @pa, 'FIFA',          '1980-01-01', @a_base  OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_base',  @a_base);   -- destino de duplicados
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Elim',         @pa, 'FIFA',          '1980-01-01', @a_elim  OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_elim',  @a_elim);   -- baja válida (con idiomas)
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Idiomas',      @pa, 'FIFA',          '1980-01-01', @a_idi   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_idi',   @a_idi);    -- base de arbitro_idioma_*
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Libre',        @pa, 'FIFA',          '1980-01-01', @a_libre OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_libre', @a_libre);   -- reemplazo en designacion_arbitral_modificar
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Alta',         @pa, 'FIFA',          '1980-01-01', @a_ins   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_ins',   @a_ins);    -- alta válida en designacion_arbitral_insertar
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Error',        @pa, 'FIFA',          '1980-01-01', @a_err   OUTPUT; INSERT INTO ##test_arbitraje VALUES ('a_err',   @a_err);    -- NUNCA se designa en un caso válido (aísla errores)

-- Idiomas
EXEC arbitraje.arbitro_idioma_insertar @a_idi,  'ingles';
EXEC arbitraje.arbitro_idioma_insertar @a_idi,  'frances';
EXEC arbitraje.arbitro_idioma_insertar @a_idi,  'italiano';
EXEC arbitraje.arbitro_idioma_insertar @a_idi,  'aleman';
EXEC arbitraje.arbitro_idioma_insertar @a_mod,  'espanol';
EXEC arbitraje.arbitro_idioma_insertar @a_mod,  'frances';
EXEC arbitraje.arbitro_idioma_insertar @a_elim, 'espanol';
EXEC arbitraje.arbitro_idioma_insertar @a_elim, 'ingles';

-- Designaciones
EXEC arbitraje.designacion_arbitral_insertar @p_gr,  @a_prin, 'principal',   @d OUTPUT;
EXEC arbitraje.designacion_arbitral_insertar @p_gr,  @a_as1,  'asistente_1', @d OUTPUT;
EXEC arbitraje.designacion_arbitral_insertar @p_gr,  @a_as2,  'asistente_2', @d_inf OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_inf',    @d_inf);   -- con informes
EXEC arbitraje.designacion_arbitral_insertar @p_24,  @a_var,  'var',         @d OUTPUT;     INSERT INTO ##test_arbitraje VALUES ('d_elim',   @d);       -- baja válida
EXEC arbitraje.designacion_arbitral_insertar @p_fin, @a_prin, 'principal',   @d_fin OUTPUT; INSERT INTO ##test_arbitraje VALUES ('d_fin',    @d_fin);   -- partido finalizado + informe
EXEC arbitraje.designacion_arbitral_insertar @p_mod, @a_m1,   'principal',   @d OUTPUT;     INSERT INTO ##test_arbitraje VALUES ('d_m_prin', @d);       -- a modificar
EXEC arbitraje.designacion_arbitral_insertar @p_mod, @a_m2,   'asistente_1', @d OUTPUT;     INSERT INTO ##test_arbitraje VALUES ('d_m_as1',  @d);       -- a modificar

-- Informes (par_gr: arranca 15:00 hora local; par_fin: 18/06 15:00)
EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 20:00:00 -03:00', 'Informe base a modificar', 'Amonestacion',  @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('i_mod',  @id);
EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 21:00:00 -03:00', 'Informe base a eliminar',  NULL,            @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('i_elim', @id);
EXEC arbitraje.informe_arbitral_insertar @d_fin, '2026-06-18 20:00:00 -03:00', 'Informe del partido finalizado', NULL,      @id OUTPUT; INSERT INTO ##test_arbitraje VALUES ('i_fin',  @id);

-- Partidos finalizados (se finalizan al final, porque una designación no se puede crear en un partido finalizado)
UPDATE torneo.partido SET estado = 'finalizado', goles_local = 1, goles_visitante = 0 WHERE partido_id = @p_fin;
UPDATE torneo.partido SET estado = 'finalizado', goles_local = 0, goles_visitante = 2 WHERE partido_id = @p_oct;   -- ZRG pierde: queda eliminada
GO