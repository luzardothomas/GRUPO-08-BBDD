-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 8: Seguridad y respaldo - Test del cifrado de datos sensibles
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Pruebas de 1_entrega8_cifrado.sql:
--     1.1  las seis columnas sensibles quedaron VARBINARY
--     1.2  los datos que ya estaban cargados quedaron cifrados y se descifran
--     1.3  un alta nueva, con su SP de siempre, se guarda cifrada
--     1.4  nadie descifra por fuera de los SP, ni el administrador (no tienen permiso sobre la clave)
--     1.5  cada rol ve el dato en claro sólo con los SP de consulta que le corresponden
--   Cada prueba indica en un comentario el "Resultado esperado" y muestra la evidencia: lo que
--   quedó guardado en la tabla (binario) y lo que devuelve el descifrado.
--
-- CÓMO EJECUTARLO:
--   Como DBA (sysadmin), después de 1_entrega8_cifrado.sql, 2_entrega8_roles.sql y
--   3_entrega8_usuarios.sql (sobre la base con las Entregas 5, 6 y 7 cargadas).
--   Se puede ejecutar completo, o ejecutar primero el Lote 0 y después cada lote por separado
--   (seleccionándolo), en la misma ventana: los resultados se juntan en la tabla temporal
--   #resultado y el lote RESUMEN los muestra. Ningún lote deja cambios en la base.
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
    IIF(OBJECT_ID('seguridad.fn_descifrar', 'FN') IS NULL OR OBJECT_ID('seguridad.comprobar_permisos', 'P') IS NULL
        OR EXISTS (SELECT 1 FROM (VALUES ('usr_administrador'), ('usr_gestor_publicidad'), ('usr_comite_arbitral'),
                                         ('usr_var'), ('usr_planillero'), ('usr_consulta')) u (usuario)
                   WHERE DATABASE_PRINCIPAL_ID(u.usuario) IS NULL), 1, 0);
EXEC sp_set_session_context N'e8_faltan_scripts', @faltan_scripts;
IF @faltan_scripts = 1
    THROW 50000, 'Ejecutar antes 1_entrega8_cifrado.sql, 2_entrega8_roles.sql y 3_entrega8_usuarios.sql. No se ejecuta ninguna prueba.', 1;
GO

-- THROW termina sólo su lote: si faltan los scripts, éste evita que se ejecuten los lotes siguientes.
IF CAST(SESSION_CONTEXT(N'e8_faltan_scripts') AS BIT) = 1
    SET NOEXEC ON;
GO

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
CREATE TABLE #resultado (orden INT IDENTITY(1, 1), prueba VARCHAR(10), descripcion VARCHAR(150),
                         resultado VARCHAR(5), detalle VARCHAR(2100));
GO

PRINT '################ CIFRADO DE DATOS SENSIBLES ################';
GO

-- ============================================================
-- 1.1 Columnas cifradas
-- ============================================================

PRINT '--- 1.1 Las seis columnas sensibles son VARBINARY';
-- Resultado esperado: motivo_alta y motivo_baja (convocatoria), contenido y sancion (informe arbitral),
-- fecha_nacimiento (árbitro) y contacto (anunciante) son VARBINARY.
SELECT OBJECT_SCHEMA_NAME(c.object_id) + '.' + OBJECT_NAME(c.object_id) AS tabla, c.name AS columna, t.name AS tipo
FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE (c.object_id = OBJECT_ID('plantel.convocatoria') AND c.name IN ('motivo_alta', 'motivo_baja'))
   OR (c.object_id = OBJECT_ID('arbitraje.informe_arbitral') AND c.name IN ('contenido', 'sancion'))
   OR (c.object_id = OBJECT_ID('arbitraje.arbitro') AND c.name = 'fecha_nacimiento')
   OR (c.object_id = OBJECT_ID('publicidad.anunciante') AND c.name = 'contacto')
ORDER BY tabla, columna;
INSERT INTO #resultado
SELECT '1.1', 'cifrado: las seis columnas sensibles son VARBINARY', IIF(COUNT(*) = 6, 'OK', 'FALLO'), CONCAT(COUNT(*), ' de 6')
FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE t.name = 'varbinary'
  AND ((c.object_id = OBJECT_ID('plantel.convocatoria') AND c.name IN ('motivo_alta', 'motivo_baja'))
    OR (c.object_id = OBJECT_ID('arbitraje.informe_arbitral') AND c.name IN ('contenido', 'sancion'))
    OR (c.object_id = OBJECT_ID('arbitraje.arbitro') AND c.name = 'fecha_nacimiento')
    OR (c.object_id = OBJECT_ID('publicidad.anunciante') AND c.name = 'contacto'));
GO

-- ============================================================
-- 1.2 Datos que ya estaban cargados
-- ============================================================

PRINT '--- 1.2 Los datos ya cargados quedaron cifrados y se descifran';
-- Resultado esperado: en la tabla se ve un binario; seguridad.fn_descifrar devuelve el texto original.
-- Cada valor cifrado tiene que descifrarse (uno que no se descifre sería un dato corrupto).
SELECT TOP (3) convocatoria_id, motivo_alta AS guardado_en_la_tabla, seguridad.fn_descifrar(motivo_alta) AS descifrado
FROM plantel.convocatoria WHERE motivo_alta IS NOT NULL ORDER BY convocatoria_id;
DECLARE @valores INT, @fallidos INT, @detalle VARCHAR(1000);
WITH cifrados AS (
    SELECT 'convocatoria.motivo_alta' AS columna, motivo_alta AS valor FROM plantel.convocatoria
    UNION ALL SELECT 'convocatoria.motivo_baja', motivo_baja FROM plantel.convocatoria
    UNION ALL SELECT 'informe_arbitral.contenido', contenido FROM arbitraje.informe_arbitral
    UNION ALL SELECT 'informe_arbitral.sancion', sancion FROM arbitraje.informe_arbitral
    UNION ALL SELECT 'arbitro.fecha_nacimiento', fecha_nacimiento FROM arbitraje.arbitro
    UNION ALL SELECT 'anunciante.contacto', contacto FROM publicidad.anunciante
), conteo AS (
    SELECT columna, COUNT(valor) AS valores,
           SUM(IIF(valor IS NOT NULL AND seguridad.fn_descifrar(valor) IS NULL, 1, 0)) AS fallidos
    FROM cifrados GROUP BY columna
)
SELECT @valores = SUM(valores), @fallidos = SUM(fallidos),
       @detalle = STRING_AGG(CAST(CONCAT(columna, ' ', valores) AS VARCHAR(MAX)), ', ')
FROM conteo;
INSERT INTO #resultado VALUES ('1.2', 'cifrado: datos existentes cifrados y descifrables',
       IIF(@valores > 0 AND @fallidos = 0, 'OK', 'FALLO'),
       CONCAT(@valores, ' valores cifrados (', @detalle, '); no descifrables: ', @fallidos));
GO

-- ============================================================
-- 1.3 Alta nueva
-- ============================================================

PRINT '--- 1.3 Un alta nueva se guarda cifrada';
-- Se da de alta un anunciante con publicidad.anunciante_insertar (modificado por el cifrado), dentro de
-- una transacción que se deshace.
-- Resultado esperado: el contacto queda guardado en binario, sin el texto a la vista, y se descifra igual.
DECLARE @id INT, @guardado VARBINARY(400), @texto VARCHAR(100) = 'prueba.cifrado@mundial2026.com';
BEGIN TRANSACTION;
EXEC publicidad.anunciante_insertar 'Anunciante de prueba del cifrado', NULL, @texto, @id OUTPUT;
SELECT @guardado = contacto FROM publicidad.anunciante WHERE anunciante_id = @id;
SELECT nombre, contacto AS guardado_en_la_tabla, seguridad.fn_descifrar(contacto) AS descifrado
FROM publicidad.anunciante WHERE anunciante_id = @id;
ROLLBACK TRANSACTION;
INSERT INTO #resultado VALUES ('1.3', 'cifrado: un alta nueva se guarda cifrada',
       IIF(@guardado IS NOT NULL AND CHARINDEX(CAST('prueba' AS VARBINARY(10)), @guardado) = 0
           AND seguridad.fn_descifrar(@guardado) = @texto, 'OK', 'FALLO'),
       CONCAT('guardado: ', CONVERT(VARCHAR(40), @guardado, 1), '... (', DATALENGTH(@guardado), ' bytes); descifrado: ',
              seguridad.fn_descifrar(@guardado)));
GO

-- ============================================================
-- 1.4 Nadie descifra por fuera de los SP
-- ============================================================

PRINT '--- 1.4 Nadie descifra por fuera de los SP, ni el administrador';
-- Con un valor cifrado en la mano (lo cifra el DBA para la prueba), se intenta descifrarlo como el
-- administrador y como el gestor de publicidad.
-- Resultado esperado: DECRYPTBYKEYAUTOCERT devuelve NULL, OPEN SYMMETRIC KEY da el error 15151 y
-- seguridad.fn_descifrar el error 229: ningún rol tiene permiso sobre la clave ni sobre la función.
DECLARE @valor VARBINARY(MAX);
EXEC seguridad.cifrar_texto 'contacto.privado@mundial2026.com', @valor OUTPUT;
DECLARE @adm_auto VARCHAR(200), @adm_open INT = 0, @adm_fn INT = 0, @pub_auto VARCHAR(200), @pub_fn INT = 0, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_administrador';
SET @adm_auto = CONVERT(VARCHAR(200), DECRYPTBYKEYAUTOCERT(CERT_ID('cert_datos_sensibles'), NULL, @valor));
BEGIN TRY OPEN SYMMETRIC KEY clave_datos_sensibles DECRYPTION BY CERTIFICATE cert_datos_sensibles; END TRY
BEGIN CATCH SET @adm_open = ERROR_NUMBER(); PRINT CONCAT('usr_administrador, OPEN SYMMETRIC KEY: ', ERROR_MESSAGE()); END CATCH;
BEGIN TRY SET @x = seguridad.fn_descifrar(@valor); END TRY
BEGIN CATCH SET @adm_fn = ERROR_NUMBER(); PRINT CONCAT('usr_administrador, seguridad.fn_descifrar: ', ERROR_MESSAGE()); END CATCH;
REVERT;
EXECUTE AS LOGIN = 'usr_gestor_publicidad';
SET @pub_auto = CONVERT(VARCHAR(200), DECRYPTBYKEYAUTOCERT(CERT_ID('cert_datos_sensibles'), NULL, @valor));
BEGIN TRY SET @x = seguridad.fn_descifrar(@valor); END TRY
BEGIN CATCH SET @pub_fn = ERROR_NUMBER(); PRINT CONCAT('usr_gestor_publicidad, seguridad.fn_descifrar: ', ERROR_MESSAGE()); END CATCH;
REVERT;
SELECT 'usr_administrador' AS usuario, ISNULL(@adm_auto, 'NULL') AS decryptbykeyautocert, @adm_open AS error_open_symmetric_key, @adm_fn AS error_fn_descifrar
UNION ALL
SELECT 'usr_gestor_publicidad', ISNULL(@pub_auto, 'NULL'), NULL, @pub_fn;
INSERT INTO #resultado VALUES ('1.4', 'cifrado: sin permiso sobre la clave, nadie descifra directamente',
       IIF(@adm_auto IS NULL AND @adm_open = 15151 AND @adm_fn = 229 AND @pub_auto IS NULL AND @pub_fn = 229, 'OK', 'FALLO'),
       CONCAT('administrador: OPEN error ', @adm_open, ', fn_descifrar error ', @adm_fn, '; gestor de publicidad: fn_descifrar error ', @pub_fn));
GO

-- ============================================================
-- 1.5 Cada rol ve el dato en claro sólo con sus SP de consulta
-- ============================================================

PRINT '--- 1.5 Cada rol ve en claro sólo lo que le corresponde';
-- Se da de alta un anunciante de prueba (dentro de una transacción que se deshace). El gestor de publicidad
-- lo consulta con publicidad.consultar_anunciante; los demás intentan los SP de consulta que no les corresponden.
-- Resultado esperado: el gestor ve el contacto en claro; el administrador y el comité arbitral ejecutan sus
-- consultas; consulta, planillero y VAR reciben el error 229.
DECLARE @anunciantes TABLE (anunciante_id INT, nombre VARCHAR(100), razon_social VARCHAR(150), contacto VARCHAR(MAX));
DECLARE @pub INT = 0, @adm INT = 0, @com INT = 0, @con INT = 0, @pla INT = 0, @var INT = 0, @id INT;
BEGIN TRANSACTION;
EXEC publicidad.anunciante_insertar 'Anunciante de prueba del cifrado', NULL, 'contacto.privado@mundial2026.com', @id OUTPUT;
EXECUTE AS LOGIN = 'usr_gestor_publicidad';
BEGIN TRY INSERT INTO @anunciantes EXEC publicidad.consultar_anunciante @anunciante_id = @id; END TRY BEGIN CATCH SET @pub = ERROR_NUMBER(); END CATCH;
REVERT;
ROLLBACK TRANSACTION;
SELECT 'usr_gestor_publicidad ve:' AS quien, nombre, contacto FROM @anunciantes;
EXECUTE AS LOGIN = 'usr_administrador';
BEGIN TRY EXEC plantel.consultar_convocatoria @seleccion_id = -1; END TRY BEGIN CATCH SET @adm = ERROR_NUMBER(); END CATCH;
REVERT;
EXECUTE AS LOGIN = 'usr_comite_arbitral';
BEGIN TRY EXEC arbitraje.consultar_informes @arbitro_id = -1; END TRY BEGIN CATCH SET @com = ERROR_NUMBER(); END CATCH;
REVERT;
EXECUTE AS LOGIN = 'usr_consulta';
BEGIN TRY EXEC publicidad.consultar_anunciante; END TRY BEGIN CATCH SET @con = ERROR_NUMBER(); PRINT CONCAT('usr_consulta: ', ERROR_MESSAGE()); END CATCH;
REVERT;
EXECUTE AS LOGIN = 'usr_planillero';
BEGIN TRY EXEC plantel.consultar_convocatoria; END TRY BEGIN CATCH SET @pla = ERROR_NUMBER(); PRINT CONCAT('usr_planillero: ', ERROR_MESSAGE()); END CATCH;
REVERT;
EXECUTE AS LOGIN = 'usr_var';
BEGIN TRY EXEC arbitraje.consultar_informes; END TRY BEGIN CATCH SET @var = ERROR_NUMBER(); PRINT CONCAT('usr_var: ', ERROR_MESSAGE()); END CATCH;
REVERT;
DECLARE @en_claro INT = (SELECT COUNT(*) FROM @anunciantes WHERE contacto = 'contacto.privado@mundial2026.com');
INSERT INTO #resultado VALUES ('1.5', 'cifrado: cada rol ve en claro sólo lo que le corresponde',
       IIF(@pub = 0 AND @en_claro = 1 AND @adm = 0 AND @com = 0 AND @con = 229 AND @pla = 229 AND @var = 229, 'OK', 'FALLO'),
       CONCAT('gestor de publicidad: consultar_anunciante ', IIF(@pub = 0, 'OK', CONCAT('error ', @pub)), ' (contacto en claro: ', IIF(@en_claro = 1, 'sí', 'no'), ')',
              '; administrador: consultar_convocatoria ', IIF(@adm = 0, 'OK', CONCAT('error ', @adm)),
              '; comité arbitral: consultar_informes ', IIF(@com = 0, 'OK', CONCAT('error ', @com)),
              '; consulta: error ', @con, '; planillero: error ', @pla, '; VAR: error ', @var));
GO

-- ============================================================
-- RESUMEN
-- ============================================================

PRINT '################ RESUMEN ################';
-- Resultado esperado: todas las pruebas en OK y ninguna en FALLO.
SELECT resultado, COUNT(*) AS pruebas FROM #resultado GROUP BY resultado;
SELECT orden, prueba, descripcion, resultado, detalle FROM #resultado ORDER BY orden;
IF EXISTS (SELECT 1 FROM #resultado WHERE resultado <> 'OK')
    SELECT 'PRUEBAS FALLIDAS' AS atencion, prueba, descripcion, detalle FROM #resultado WHERE resultado <> 'OK' ORDER BY orden;
ELSE
    PRINT 'Todas las pruebas finalizaron con el resultado esperado.';
DECLARE @total VARCHAR(100) = (SELECT CONCAT('TOTAL: ', SUM(IIF(resultado = 'OK', 1, 0)), ' OK, ',
                                             SUM(IIF(resultado = 'OK', 0, 1)), ' FALLO') FROM #resultado);
PRINT @total;
GO

SET NOEXEC OFF;
GO
