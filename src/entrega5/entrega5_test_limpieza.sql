-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 5: Base de Datos - LIMPIEZA DE LOS LOTES DE PRUEBA
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Se realiza la limpieza del testeo exhaustivo de los SP. Se vacian todas las tablas
--   borrando, solamente, los datos insertados en la preparacion.
--   El orden va de las tablas hijas a las tablas padre (publicidad -> eventos -> plantel
--   -> partidos/selecciones/sedes/paises -> confederaciones) para no violar las FK.
--
-- CÓMO USARLO:
--   Se ejecuta de una sola vez, luego de terminar todos los testeos.
--   La limpieza borrara todos los datos de una sola vez.
-- ============================================================

USE mundial_2026;
GO

SET NOCOUNT ON;
GO

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
IF OBJECT_ID('tempdb..#id') IS NOT NULL DROP TABLE #id;
CREATE TABLE #resultado (orden INT IDENTITY(1, 1), prueba VARCHAR(10), descripcion VARCHAR(120),
                         resultado VARCHAR(5), detalle VARCHAR(2100));
CREATE TABLE #id (clave VARCHAR(20) PRIMARY KEY, valor INT);
GO

-- =======================================================================================================
--                                          LIMPIEZA
-- =======================================================================================================

-- Limpieza de torneo.parametro
DECLARE @bk_hasta INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_hasta'),
        @bk_desde INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_desde');
EXEC torneo.parametro_modificar 'prime_time_hora_hasta', @bk_hasta;
EXEC torneo.parametro_modificar 'prime_time_hora_desde', @bk_desde;
DELETE FROM torneo.parametro WHERE clave LIKE 'tst[_]%';
GO

-- Limpieza de publicidad.* (anunciante, campania, campania_pais_interes, pieza_publicitaria, espacio_publicitario)
DROP TABLE IF EXISTS #camp;
SELECT campania_id INTO #camp FROM publicidad.campania
WHERE nombre IN ('PAIS_CAMP', 'Elim OK', 'Elim Con Pieza', 'ESP_VIG', 'ESP_FUERA')
   OR nombre LIKE 'CPI[_]%'
   OR nombre LIKE 'PZ[_]%'
   OR anunciante_id IN (SELECT anunciante_id FROM publicidad.anunciante
                        WHERE nombre IN ('PAIS_ANUN', 'CAMP_A', 'CAMP_B', 'ELIM_OK', 'ELIM_CON_CAMP', 'CMOD_A', 'CMOD_B',
                                         'CELIM', 'CPI', 'PZ', 'ESP', 'TEST01', 'TEST02', 'TEST03', 'TEST04', 'TEST05',
                                         'TEST06', 'TEST_MOD'));

-- espacios de los partidos usados por las campañas ESP_*
DELETE FROM publicidad.espacio_publicitario
WHERE partido_id IN (SELECT e2.partido_id
                     FROM publicidad.espacio_publicitario e2
                     JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e2.pieza_id
                     JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                     WHERE c.nombre IN ('ESP_VIG', 'ESP_FUERA'));
-- espacios de las piezas de las campañas de prueba
DELETE e FROM publicidad.espacio_publicitario e
JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
WHERE pz.campania_id IN (SELECT campania_id FROM #camp);
DELETE FROM publicidad.pieza_publicitaria WHERE campania_id IN (SELECT campania_id FROM #camp);
DELETE FROM publicidad.campania_pais_interes WHERE campania_id IN (SELECT campania_id FROM #camp);
DELETE FROM publicidad.campania WHERE campania_id IN (SELECT campania_id FROM #camp);
DELETE FROM publicidad.anunciante
WHERE nombre IN ('PAIS_ANUN', 'CAMP_A', 'CAMP_B', 'ELIM_OK', 'ELIM_CON_CAMP', 'CMOD_A', 'CMOD_B',
                 'CELIM', 'CPI', 'PZ', 'ESP', 'TEST01', 'TEST02', 'TEST03', 'TEST04', 'TEST05',
                 'TEST06', 'TEST_MOD');
DROP TABLE #camp;
GO

-- Limpieza de evento.gol_* (al terminar)
DELETE FROM evento.gol WHERE formacion_id IN (SELECT formacion_id FROM ##test_gol WHERE formacion_id IS NOT NULL);
DELETE FROM evento.sustitucion WHERE formacion_id IN (SELECT formacion_id FROM ##test_gol WHERE clave IN ('f_loc', 'f_vis', 'z_loc', 'z_vis'));
DELETE FROM plantel.formacion_jugador WHERE formacion_id IN (SELECT formacion_id FROM ##test_gol WHERE clave IN ('f_loc', 'f_vis', 'z_loc', 'z_vis'));
DELETE FROM plantel.formacion WHERE formacion_id IN (SELECT formacion_id FROM ##test_gol WHERE clave IN ('f_loc', 'f_vis', 'z_loc', 'z_vis'));
DELETE FROM torneo.partido WHERE partido_id IN (SELECT partido_id FROM ##test_gol WHERE clave IN ('p_gol', 'p_z'));
DECLARE @pm INT;
IF OBJECT_ID('tempdb..##test_formacion') IS NOT NULL
BEGIN
    SET @pm = (SELECT partido_id FROM ##test_formacion WHERE clave = 'mod');
    EXEC torneo.partido_actualizar_marcador @pm;   -- recalcula el marcador del partido 'mod' sin el gol g_jug
END;
DROP TABLE ##test_gol;
GO

-- Limpieza de evento.sustitucion_* (al terminar)
DECLARE @f TABLE (formacion_id INT, partido_id INT);
INSERT INTO @f SELECT v.formacion_id, v.partido_id FROM plantel.vw_formacion v WHERE v.formacion_id IN (SELECT formacion_id FROM ##test_sustitucion WHERE clave LIKE 'f[_]%');
DELETE FROM evento.sustitucion WHERE formacion_id IN (SELECT formacion_id FROM @f);
DELETE FROM evento.sustitucion WHERE formacion_id = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug');
DELETE FROM plantel.formacion_jugador WHERE formacion_id IN (SELECT formacion_id FROM @f);
DELETE FROM plantel.formacion WHERE formacion_id IN (SELECT formacion_id FROM @f);
DELETE FROM torneo.partido WHERE partido_id IN (SELECT partido_id FROM @f);
DROP TABLE ##test_sustitucion;
GO

-- Limpieza de evento.tarjeta_* (al terminar)
DELETE FROM evento.suspension WHERE tarjeta_id IN (SELECT tarjeta_id FROM evento.tarjeta
    WHERE partido_id IN (SELECT partido_id FROM ##test_tarjeta WHERE clave IN ('pt_tar', 'pt_z'))
    OR tarjeta_id IN (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_jug'));
DELETE FROM evento.tarjeta
WHERE partido_id IN (SELECT partido_id FROM ##test_tarjeta WHERE clave IN ('pt_tar', 'pt_z'))
    OR tarjeta_id IN (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_jug');
DELETE FROM plantel.formacion_jugador WHERE formacion_id IN (SELECT formacion_id FROM ##test_tarjeta WHERE clave IN ('f_loc', 'f_vis', 'z_loc'));
DELETE FROM plantel.formacion WHERE formacion_id IN (SELECT formacion_id FROM ##test_tarjeta WHERE clave IN ('f_loc', 'f_vis', 'z_loc'));
DELETE FROM torneo.partido WHERE partido_id IN (SELECT partido_id FROM ##test_tarjeta WHERE clave IN ('pt_tar', 'pt_z'));
DELETE FROM plantel.cuerpo_tecnico WHERE persona_id IN (SELECT persona_id FROM ##test_tarjeta WHERE clave LIKE 'l[_]%' OR clave IN ('u_err', 'u_ea', 'u_ctv'));
DELETE FROM plantel.persona WHERE persona_id IN (SELECT persona_id FROM ##test_tarjeta WHERE clave LIKE 'l[_]%' OR clave IN ('u_err', 'u_ea', 'u_ctv'));
DROP TABLE ##test_tarjeta;
GO

-- Limpieza de evento.criterio_suspension_* (al terminar)
DELETE FROM evento.suspension
WHERE criterio_id IN (SELECT criterio_id FROM evento.criterio_suspension WHERE cantidad_amarillas BETWEEN 70 AND 99);
DELETE FROM evento.criterio_suspension WHERE cantidad_amarillas BETWEEN 70 AND 99;
IF OBJECT_ID('tempdb..##test_criterio') IS NOT NULL DROP TABLE ##test_criterio;
GO

-- Limpieza de plantel.persona (al terminar)
DELETE FROM evento.tarjeta WHERE persona_id IN (SELECT persona_id FROM ##test_persona);
DELETE FROM plantel.formacion_jugador WHERE jugador_id IN (SELECT jugador_id FROM plantel.jugador WHERE persona_id IN (SELECT persona_id FROM ##test_persona));
DELETE FROM plantel.convocatoria WHERE jugador_id IN (SELECT jugador_id FROM plantel.jugador WHERE persona_id IN (SELECT persona_id FROM ##test_persona));
DELETE FROM plantel.jugador WHERE persona_id IN (SELECT persona_id FROM ##test_persona);
DELETE FROM plantel.cuerpo_tecnico WHERE persona_id IN (SELECT persona_id FROM ##test_persona);
DELETE FROM plantel.persona WHERE persona_id IN (SELECT persona_id FROM ##test_persona);
DROP TABLE ##test_persona;
GO

-- Limpieza de plantel.cuerpo_tecnico_* (al terminar)
-- (las selecciones y países ZCA-ZCC se borran en el bloque estructural del final)
DECLARE @p TABLE (persona_id INT);
INSERT INTO @p SELECT persona_id FROM plantel.cuerpo_tecnico WHERE nombre LIKE 'Test CT%';
DELETE FROM evento.tarjeta WHERE persona_id IN (SELECT persona_id FROM @p);
DELETE FROM plantel.cuerpo_tecnico WHERE nombre LIKE 'Test CT%';
DELETE FROM plantel.persona WHERE persona_id IN (SELECT persona_id FROM @p);
GO

-- Limpieza de plantel.jugador_* (al terminar)
DECLARE @p TABLE (persona_id INT, jugador_id INT);
INSERT INTO @p SELECT persona_id, jugador_id FROM plantel.jugador WHERE nombre LIKE 'Test JU%';
DELETE FROM evento.tarjeta WHERE persona_id IN (SELECT persona_id FROM @p);
DELETE FROM plantel.formacion_jugador WHERE jugador_id IN (SELECT jugador_id FROM @p);
DELETE FROM plantel.convocatoria WHERE jugador_id IN (SELECT jugador_id FROM @p);
DELETE FROM plantel.jugador WHERE nombre LIKE 'Test JU%';
DELETE FROM plantel.persona WHERE persona_id IN (SELECT persona_id FROM @p);
GO

-- Limpieza de plantel.convocatoria_* (al terminar)
DECLARE @p TABLE (persona_id INT, jugador_id INT);
INSERT INTO @p SELECT persona_id, jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido LIKE 'Conv %';
DELETE FROM plantel.convocatoria WHERE jugador_id IN (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU');
DELETE FROM plantel.jugador WHERE jugador_id IN (SELECT jugador_id FROM @p);
DELETE FROM plantel.persona WHERE persona_id IN (SELECT persona_id FROM @p);
GO

-- Limpieza de plantel.formacion_* (al terminar)
DELETE FROM plantel.formacion_jugador WHERE formacion_id IN (SELECT formacion_id FROM plantel.formacion WHERE partido_id IN (SELECT partido_id FROM ##test_formacion));
DELETE FROM plantel.formacion WHERE partido_id IN (SELECT partido_id FROM ##test_formacion);
DELETE FROM torneo.partido WHERE partido_id IN (SELECT partido_id FROM ##test_formacion);
DROP TABLE ##test_formacion;
GO

-- Limpieza de plantel.formacion_jugador_* (al terminar)
DELETE FROM plantel.formacion_jugador WHERE jugador_id IN (SELECT jugador_id FROM ##test_fjugador);
DECLARE @p TABLE (persona_id INT, jugador_id INT);
INSERT INTO @p SELECT persona_id, jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido LIKE 'FJ %';
DELETE FROM plantel.convocatoria WHERE jugador_id IN (SELECT jugador_id FROM @p);
DELETE FROM plantel.jugador WHERE jugador_id IN (SELECT jugador_id FROM @p);
DELETE FROM plantel.persona WHERE persona_id IN (SELECT persona_id FROM @p);
DROP TABLE ##test_fjugador;
GO

-- Limpieza de torneo.partido / seleccion / sede / pais (al terminar, siempre al final)
-- Paises de prueba: ZZ?, ZYC (confederacion), ZQ? (seleccion), ZP[A-E] (partido), ZS[A-C] (sede), ZC[A-C] (cuerpo tecnico)
DROP TABLE IF EXISTS #pp, #sl, #ps, #pt, #fm;
SELECT pais_id INTO #pp FROM torneo.pais
WHERE codigo_iso LIKE 'ZZ[A-Z]' OR codigo_iso = 'ZYC' OR codigo_iso LIKE 'ZQ_'
   OR codigo_iso LIKE 'ZP[A-E]' OR codigo_iso LIKE 'ZS[A-C]' OR codigo_iso LIKE 'ZC[A-C]';
SELECT seleccion_id INTO #sl FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM #pp);
SELECT sede_id INTO #ps FROM torneo.sede
WHERE pais_id IN (SELECT pais_id FROM #pp)
   OR nombre LIKE 'Test Sede%' OR nombre LIKE 'Test Partido%' OR nombre LIKE 'Test Sel%';
SELECT partido_id INTO #pt FROM torneo.partido
WHERE sede_id IN (SELECT sede_id FROM #ps)
   OR seleccion_local_id IN (SELECT seleccion_id FROM #sl)
   OR seleccion_visitante_id IN (SELECT seleccion_id FROM #sl);
SELECT formacion_id INTO #fm FROM plantel.formacion WHERE partido_id IN (SELECT partido_id FROM #pt);

DELETE FROM evento.suspension WHERE partido_afectado_id IN (SELECT partido_id FROM #pt)
    OR tarjeta_id IN (SELECT tarjeta_id FROM evento.tarjeta WHERE partido_id IN (SELECT partido_id FROM #pt));
DELETE FROM evento.gol WHERE formacion_id IN (SELECT formacion_id FROM #fm);
DELETE FROM evento.sustitucion WHERE formacion_id IN (SELECT formacion_id FROM #fm);
DELETE FROM plantel.formacion_jugador WHERE formacion_id IN (SELECT formacion_id FROM #fm);
DELETE FROM evento.tarjeta WHERE partido_id IN (SELECT partido_id FROM #pt);
DELETE FROM plantel.formacion WHERE partido_id IN (SELECT partido_id FROM #pt);
DELETE FROM arbitraje.designacion_arbitral WHERE partido_id IN (SELECT partido_id FROM #pt);
DELETE FROM publicidad.espacio_publicitario WHERE partido_id IN (SELECT partido_id FROM #pt);
DELETE FROM torneo.partido WHERE partido_id IN (SELECT partido_id FROM #pt);

DELETE FROM plantel.convocatoria WHERE seleccion_id IN (SELECT seleccion_id FROM #sl);
DELETE FROM evento.tarjeta WHERE persona_id IN (SELECT persona_id FROM plantel.cuerpo_tecnico WHERE seleccion_id IN (SELECT seleccion_id FROM #sl));
DELETE FROM plantel.cuerpo_tecnico WHERE seleccion_id IN (SELECT seleccion_id FROM #sl);
DELETE FROM arbitraje.arbitro WHERE pais_id IN (SELECT pais_id FROM #pp);
DELETE FROM torneo.seleccion WHERE seleccion_id IN (SELECT seleccion_id FROM #sl);
DELETE FROM torneo.sede WHERE sede_id IN (SELECT sede_id FROM #ps);
DELETE FROM publicidad.campania_pais_interes WHERE pais_id IN (SELECT pais_id FROM #pp);
DELETE FROM torneo.pais WHERE pais_id IN (SELECT pais_id FROM #pp);
DROP TABLE #fm, #pt, #ps, #sl, #pp;
GO

-- Limpieza de torneo.confederacion (al terminar): se restauran las confederaciones borradas por el testeo
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'AFC')      EXEC torneo.confederacion_insertar 'AFC';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'CAF')      EXEC torneo.confederacion_insertar 'CAF';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'CONCACAF') EXEC torneo.confederacion_insertar 'CONCACAF';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'CONMEBOL') EXEC torneo.confederacion_insertar 'CONMEBOL';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'OFC')      EXEC torneo.confederacion_insertar 'OFC';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'UEFA')     EXEC torneo.confederacion_insertar 'UEFA';
GO