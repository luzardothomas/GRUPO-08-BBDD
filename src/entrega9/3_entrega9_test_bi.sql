-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 9: BI, visualización y aplicación - Test de las vistas y del usuario de Power BI
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Comprueba que lo que Power BI va a leer es correcto y seguro:
--     1.1  usr_bi (el usuario de Power BI) lee las cuatro vistas del esquema bi
--     1.2  las vistas coinciden con los reportes de la Entrega 7 (goleadores y ocupación publicitaria)
--     1.3  todas las sedes tienen coordenadas para el mapa
--     2.1  usr_bi no puede leer ni escribir las tablas de la aplicación
--     2.2  usr_bi no puede ejecutar los SP ni escribir en las vistas
--   Cada prueba es un lote. Ningún lote deja cambios en la base.
--
-- CÓMO EJECUTARLO:
--   Como DBA (sysadmin), después de 1_entrega9_sede_coordenadas.sql y 2_entrega9_vistas_bi.sql (sobre la base
--   con las Entregas 5, 7 y 8 cargadas). Se puede ejecutar completo, o ejecutar primero el Lote 0 y después cada
--   lote por separado (seleccionándolo), en la misma ventana: los resultados se juntan en la tabla temporal
--   #resultado y el lote RESUMEN los muestra.
-- ============================================================

USE mundial_2026;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- LOTE 0: PREPARACIÓN
-- ============================================================

PRINT '--- Lote 0: preparación';
DECLARE @faltan_scripts BIT =
    IIF(OBJECT_ID('bi.vw_sedes', 'V') IS NULL OR DATABASE_PRINCIPAL_ID('usr_bi') IS NULL
        OR COL_LENGTH('torneo.sede', 'latitud') IS NULL, 1, 0);
EXEC sp_set_session_context N'e9_faltan_scripts', @faltan_scripts;
IF @faltan_scripts = 1
    THROW 50000, 'Ejecutar antes 1_entrega9_sede_coordenadas.sql y 2_entrega9_vistas_bi.sql. No se ejecuta ninguna prueba.', 1;
GO

-- THROW termina sólo su lote: si faltan los scripts, éste evita que se ejecuten los lotes siguientes.
IF CAST(SESSION_CONTEXT(N'e9_faltan_scripts') AS BIT) = 1
    SET NOEXEC ON;
GO

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
CREATE TABLE #resultado (orden INT IDENTITY(1, 1), prueba VARCHAR(10), descripcion VARCHAR(150),
                         resultado VARCHAR(5), detalle VARCHAR(2100));
GO

-- ============================================================
-- 1.1 usr_bi lee las vistas
-- ============================================================

PRINT '--- 1.1 usr_bi lee las cuatro vistas del esquema bi';
-- Se hace pasar por usr_bi (EXECUTE AS LOGIN) y cuenta las filas de cada vista.
-- Resultado esperado: las cuatro vistas devuelven filas, sin error de permisos.
DECLARE @vistas TABLE (vista VARCHAR(40), filas INT);
DECLARE @error INT = 0, @mensaje VARCHAR(300) = '';
EXECUTE AS LOGIN = 'usr_bi';
BEGIN TRY
    INSERT INTO @vistas VALUES ('bi.vw_goles', (SELECT COUNT(*) FROM bi.vw_goles)),
                               ('bi.vw_ocupacion_publicitaria', (SELECT COUNT(*) FROM bi.vw_ocupacion_publicitaria)),
                               ('bi.vw_partidos', (SELECT COUNT(*) FROM bi.vw_partidos)),
                               ('bi.vw_sedes', (SELECT COUNT(*) FROM bi.vw_sedes));
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
    SET @mensaje = LEFT(ERROR_MESSAGE(), 250);
END CATCH;
REVERT;
SELECT * FROM @vistas;
INSERT INTO #resultado
SELECT '1.1', 'usr_bi lee las cuatro vistas',
       IIF(@error = 0 AND (SELECT COUNT(*) FROM @vistas WHERE filas > 0) = 4, 'OK', 'FALLO'),
       IIF(@error <> 0, CONCAT('error ', @error, ': ', @mensaje),
           (SELECT STRING_AGG(CONCAT(vista, ' ', filas), '; ') FROM @vistas));
GO

-- ============================================================
-- 1.2 Las vistas coinciden con los reportes de la Entrega 7
-- ============================================================

PRINT '--- 1.2 Las vistas coinciden con los reportes de la Entrega 7';
-- Goles: los que cuentan para el goleador en la vista son los mismos que cuenta el reporte de goleadores
-- (sin goles en contra ni tanda de penales). Ocupación: el ingreso facturado y el estimado de la vista suman lo
-- mismo que la fila TOTAL GENERAL de publicidad.reporte_ocupacion.
-- Resultado esperado: los totales de la vista y del reporte son iguales.
DECLARE @oc TABLE (Sede VARCHAR(200), Partido VARCHAR(200), Partido_id VARCHAR(40), Fecha_local VARCHAR(40),
                   Fase VARCHAR(40), Estado VARCHAR(40), Anunciantes VARCHAR(MAX), Ocupados INT, Disponibles INT,
                   Ocupacion_pct DECIMAL(5, 1), Facturado DECIMAL(18, 2), Estimado DECIMAL(18, 2));
INSERT INTO @oc EXEC publicidad.reporte_ocupacion;
DECLARE @goles_vista INT = (SELECT SUM(cuenta_para_goleador) FROM bi.vw_goles),
        @goles_tabla INT = (SELECT COUNT(*) FROM evento.gol WHERE tipo_gol <> 'en_contra' AND periodo <> 'penales'),
        @fact_vista DECIMAL(18, 2) = (SELECT SUM(ingreso_facturado_usd) FROM bi.vw_ocupacion_publicitaria),
        @est_vista DECIMAL(18, 2) = (SELECT SUM(ingreso_estimado_usd) FROM bi.vw_ocupacion_publicitaria),
        @fact_rep DECIMAL(18, 2) = (SELECT Facturado FROM @oc WHERE Sede = 'TOTAL GENERAL'),
        @est_rep DECIMAL(18, 2) = (SELECT Estimado FROM @oc WHERE Sede = 'TOTAL GENERAL');
SELECT @goles_vista AS goles_vista, @goles_tabla AS goles_tabla,
       @fact_vista AS facturado_vista, @fact_rep AS facturado_reporte,
       @est_vista AS estimado_vista, @est_rep AS estimado_reporte;
INSERT INTO #resultado VALUES ('1.2', 'las vistas coinciden con los reportes de la Entrega 7',
       IIF(@goles_vista = @goles_tabla AND @fact_vista = @fact_rep AND @est_vista = @est_rep, 'OK', 'FALLO'),
       CONCAT('goles ', @goles_vista, ' / ', @goles_tabla, '; facturado ', @fact_vista, ' / ', @fact_rep,
              '; estimado ', @est_vista, ' / ', @est_rep));
GO

-- ============================================================
-- 1.3 Coordenadas de las sedes
-- ============================================================

PRINT '--- 1.3 Todas las sedes tienen coordenadas para el mapa';
-- Resultado esperado: ninguna sede sin latitud y longitud.
DECLARE @sin INT = (SELECT COUNT(*) FROM bi.vw_sedes WHERE latitud IS NULL OR longitud IS NULL),
        @total INT = (SELECT COUNT(*) FROM bi.vw_sedes),
        @fuera INT = (SELECT COUNT(*) FROM bi.vw_sedes WHERE latitud NOT BETWEEN 15 AND 55 OR longitud NOT BETWEEN -130 AND -65);
SELECT sede, ciudad, pais, latitud, longitud FROM bi.vw_sedes ORDER BY sede_id;
INSERT INTO #resultado VALUES ('1.3', 'todas las sedes tienen coordenadas (dentro de América del Norte)',
       IIF(@sin = 0 AND @fuera = 0 AND @total > 0, 'OK', 'FALLO'),
       CONCAT(@total, ' sedes; sin coordenadas: ', @sin, '; fuera de América del Norte: ', @fuera));
GO

-- ============================================================
-- 2.1 usr_bi no lee ni escribe las tablas
-- ============================================================

PRINT '--- 2.1 usr_bi no puede leer ni escribir las tablas de la aplicación';
-- Resultado esperado: error 229 (permiso denegado) en todos los intentos.
DECLARE @r TABLE (intento VARCHAR(60), error INT);
EXECUTE AS LOGIN = 'usr_bi';
BEGIN TRY SELECT TOP 1 * FROM torneo.partido; INSERT INTO @r VALUES ('SELECT torneo.partido', 0); END TRY
BEGIN CATCH INSERT INTO @r VALUES ('SELECT torneo.partido', ERROR_NUMBER()); END CATCH;
BEGIN TRY SELECT TOP 1 * FROM evento.gol; INSERT INTO @r VALUES ('SELECT evento.gol', 0); END TRY
BEGIN CATCH INSERT INTO @r VALUES ('SELECT evento.gol', ERROR_NUMBER()); END CATCH;
BEGIN TRY SELECT TOP 1 * FROM publicidad.anunciante; INSERT INTO @r VALUES ('SELECT publicidad.anunciante', 0); END TRY
BEGIN CATCH INSERT INTO @r VALUES ('SELECT publicidad.anunciante', ERROR_NUMBER()); END CATCH;
BEGIN TRY UPDATE torneo.sede SET capacidad = capacidad WHERE sede_id = -1; INSERT INTO @r VALUES ('UPDATE torneo.sede', 0); END TRY
BEGIN CATCH INSERT INTO @r VALUES ('UPDATE torneo.sede', ERROR_NUMBER()); END CATCH;
BEGIN TRY DELETE FROM torneo.partido WHERE partido_id = -1; INSERT INTO @r VALUES ('DELETE torneo.partido', 0); END TRY
BEGIN CATCH INSERT INTO @r VALUES ('DELETE torneo.partido', ERROR_NUMBER()); END CATCH;
REVERT;
SELECT intento, IIF(error = 229, 'NO PUEDE (229)', CONCAT('PUEDE / error ', error)) AS resultado FROM @r;
INSERT INTO #resultado
SELECT '2.1', 'usr_bi no lee ni escribe las tablas',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE error <> 229), 'OK', 'FALLO'),
       (SELECT STRING_AGG(CONCAT(intento, ': ', error), '; ') FROM @r);
GO

-- ============================================================
-- 2.2 usr_bi no ejecuta SP ni escribe en las vistas
-- ============================================================

PRINT '--- 2.2 usr_bi no puede ejecutar los SP ni escribir en las vistas';
-- Resultado esperado: error 229 en todos los intentos.
DECLARE @r TABLE (intento VARCHAR(60), error INT);
EXECUTE AS LOGIN = 'usr_bi';
BEGIN TRY EXEC torneo.reporte_resultados; INSERT INTO @r VALUES ('EXEC torneo.reporte_resultados', 0); END TRY
BEGIN CATCH INSERT INTO @r VALUES ('EXEC torneo.reporte_resultados', ERROR_NUMBER()); END CATCH;
BEGIN TRY EXEC torneo.sede_eliminar @sede_id = -1; INSERT INTO @r VALUES ('EXEC torneo.sede_eliminar', 0); END TRY
BEGIN CATCH INSERT INTO @r VALUES ('EXEC torneo.sede_eliminar', ERROR_NUMBER()); END CATCH;
BEGIN TRY EXEC plantel.consultar_convocatoria; INSERT INTO @r VALUES ('EXEC plantel.consultar_convocatoria', 0); END TRY
BEGIN CATCH INSERT INTO @r VALUES ('EXEC plantel.consultar_convocatoria', ERROR_NUMBER()); END CATCH;
-- Las vistas juntan varias tablas, así que el motor ni siquiera las deja modificar: se pregunta por el permiso
-- efectivo de usr_bi sobre cada una (HAS_PERMS_BY_NAME = 0: no lo tiene).
INSERT INTO @r
SELECT CONCAT(x.permiso, ' ', v.vista), IIF(HAS_PERMS_BY_NAME(v.vista, 'OBJECT', x.permiso) = 0, 229, 0)
FROM (VALUES ('bi.vw_goles'), ('bi.vw_ocupacion_publicitaria'), ('bi.vw_partidos'), ('bi.vw_sedes')) v (vista)
CROSS JOIN (VALUES ('INSERT'), ('UPDATE'), ('DELETE')) x (permiso);
REVERT;
SELECT intento, IIF(error = 229, 'NO PUEDE (229)', CONCAT('PUEDE / error ', error)) AS resultado FROM @r;
INSERT INTO #resultado
SELECT '2.2', 'usr_bi no ejecuta SP ni escribe en las vistas',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE error <> 229), 'OK', 'FALLO'),
       (SELECT STRING_AGG(CONCAT(intento, ': ', error), '; ') FROM @r);
GO

-- ============================================================
-- RESUMEN
-- ============================================================

PRINT '################ RESUMEN ################';
SELECT orden, prueba, descripcion, resultado, detalle FROM #resultado ORDER BY orden;
DECLARE @ok INT = (SELECT COUNT(*) FROM #resultado WHERE resultado = 'OK'),
        @fallo INT = (SELECT COUNT(*) FROM #resultado WHERE resultado = 'FALLO');
IF @fallo > 0
    SELECT 'PRUEBAS FALLIDAS' AS aviso, prueba, descripcion, detalle FROM #resultado WHERE resultado = 'FALLO';
PRINT IIF(@fallo = 0, 'Todas las pruebas finalizaron con el resultado esperado.', 'Hay pruebas con FALLO: revisar el detalle.');
PRINT CONCAT('TOTAL: ', @ok, ' OK, ', @fallo, ' FALLO');
GO
