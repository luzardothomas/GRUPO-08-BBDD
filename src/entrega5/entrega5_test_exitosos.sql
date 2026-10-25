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
--   Test exhaustivo de los procedimientos de entrega5_sp.sql: se verifican todas las
--   condiciones de cada SP, tanto los casos válidos como cada uno de los errores
--   posibles (incluidos los casos que combinan varias condiciones).
--
-- CÓMO USARLO:
--   La gran mayoría de bloques tienen un apartado llamado -- Preparación de <sp> (ejecutar UNA sola vez)
--   el cual se ejecuta una vez sola al comienzo del testeo.
--   Luego, cada SP tiene un bloque "-- Verificacion <esquema>.<sp>" con una línea por caso
--   y el resultado esperado a la derecha (-->). Se ejecuta comentando y descomentando
--   la línea correspondiente al error que se quiere ver: una sola línea inválida
--   activa por vez.
--   Por ultimo, cada bloque posee un apartado de limpieza, el cual se debe de ejecutar luego de finalizar
--   el testeo, para no dejar la base llena de basura.
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
-- Preparación de torneo.parametro_* (ejecutar UNA sola vez)
DECLARE @h INT = (SELECT valor FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta'),
        @d INT = (SELECT valor FROM torneo.parametro WHERE clave = 'prime_time_hora_desde');

EXEC torneo.parametro_insertar 'tst_ins', 1, 'Base de insertar (para duplicados)';
EXEC torneo.parametro_insertar 'tst_mod', 10, 'Base de modificar';
EXEC torneo.parametro_insertar 'tst_elim', 5, 'Base de eliminar';
EXEC torneo.parametro_insertar 'tst_backup_hasta', @h, 'Respaldo de prime_time_hora_hasta';
EXEC torneo.parametro_insertar 'tst_backup_desde', @d, 'Respaldo de prime_time_hora_desde';
GO

-- Verificacion torneo.parametro_insertar
EXEC torneo.parametro_insertar 'tst_ins_ok', 10, 'Alta valida'; --> Valido
-- EXEC torneo.parametro_insertar 'tst_cero', 0, 'Valor cero'; --> Valido: valor 0 (borde)
-- EXEC torneo.parametro_insertar 'tst_valor_max', 2147483647, 'Valor maximo'; --> borde
-- EXEC torneo.parametro_insertar 'tst_abcdefghijklmnopqrstuvwxyz0123456789', 1, --> Valido: clave de 40 caracteres (borde)
-- EXEC torneo.parametro_insertar 'tst_desc_esp', 1, '  Descripcion con espacios  '; --> Valido: la descripcion se guarda tal cual, sin recortar
-- EXEC torneo.parametro_insertar 'TST_MAYUS', 1, 'Clave en mayusculas'; --> Valido: permite mayus la collation
-- EXEC torneo.parametro_insertar '', 1, 'Desc'; --> Clave vacia
-- EXEC torneo.parametro_insertar NULL, 1, 'Desc'; --> Clave nula
-- EXEC torneo.parametro_insertar '   ', 1, 'Desc'; --> Clave solo espacios
-- EXEC torneo.parametro_insertar 'tst_abcdefghijklmnopqrstuvwxyz0123456789x', 1, 'Desc'; --> Clave de 41 caracteres (mas de 40)
-- EXEC torneo.parametro_insertar 'tst bad', 1, 'Desc'; --> Clave con espacio
-- EXEC torneo.parametro_insertar ' tst_bad', 1, 'Desc'; --> Clave con espacio al inicio, tira error de tipo de caracteres
-- EXEC torneo.parametro_insertar 'tst-bad', 1, 'Desc'; --> Clave con guion medio
-- EXEC torneo.parametro_insertar 'tst.bad', 1, 'Desc'; --> Clave con punto
-- EXEC torneo.parametro_insertar 'tst_bad', NULL, 'Desc'; --> Valor nulo
-- EXEC torneo.parametro_insertar 'tst_bad', -1, 'Desc'; --> Valor negativo
-- EXEC torneo.parametro_insertar 'tst_bad', 1, ''; --> Descripcion vacia
-- EXEC torneo.parametro_insertar 'tst_bad', 1, NULL; --> Descripcion nula
-- EXEC torneo.parametro_insertar 'tst_bad', 1, '   '; --> Descripcion solo espacios
-- EXEC torneo.parametro_insertar 'tst_ins', 1, 'Desc'; --> Clave duplicada (tst_ins ya existe)
-- EXEC torneo.parametro_insertar 'TST_INS', 1, 'Desc'; --> Duplicada con otra capitalizacion: CI = duplicado, CS = error de formato (1 error en ambos casos)
-- EXEC torneo.parametro_insertar 'formacion_titulares', 1, 'Desc'; --> Duplicada con un parametro real
-- EXEC torneo.parametro_insertar '', -1, 'Desc'; --> 2 errores: clave obligatoria y valor negativo
-- EXEC torneo.parametro_insertar NULL, NULL, NULL; --> 3 errores: clave obligatoria, valor obligatorio y descripcion obligatoria
-- EXEC torneo.parametro_insertar 'tst_ins ', -1, ''; --> 4 errores: formato de clave, valor negativo, descripcion vacia y clave duplicada

-- Verificacion torneo.parametro_modificar
DECLARE @bk_hasta INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_hasta'),
        @bk_desde INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_desde');

-- EXEC torneo.parametro_modificar 'tst_mod', 20, 'Descripcion nueva'; --> Valido: cambia valor y descripcion
-- EXEC torneo.parametro_modificar 'tst_mod', 30; --> Valido: sin descripcion, conserva 'Descripcion nueva'
-- EXEC torneo.parametro_modificar 'tst_mod', 0, NULL; --> Valido: borde
-- EXEC torneo.parametro_modificar 'prime_time_hora_hasta', 24; --> Valido: hora de fin 24 (borde superior)
-- EXEC torneo.parametro_modificar 'prime_time_hora_hasta', 0; --> Valido: hora de fin 0 (borde inferior)
-- EXEC torneo.parametro_modificar 'prime_time_hora_hasta', @bk_hasta; --> Restaurar prime_time_hora_hasta
-- EXEC torneo.parametro_modificar 'prime_time_hora_desde', @bk_desde; --> Restaurar prime_time_hora_desde
-- EXEC torneo.parametro_modificar 'no_existe_xx', 1; --> Parametro inexistente
-- EXEC torneo.parametro_modificar NULL, 1; --> Clave nula 
-- EXEC torneo.parametro_modificar '', 1; --> Clave vacia
-- EXEC torneo.parametro_modificar 'tst_mod', NULL; --> Valor nulo
-- EXEC torneo.parametro_modificar 'tst_mod', -1; --> Valor negativo
-- EXEC torneo.parametro_modificar 'tst_mod', 1, ''; --> Descripcion vacia
-- EXEC torneo.parametro_modificar 'tst_mod', 1, '   '; --> Descripcion solo espacios
-- EXEC torneo.parametro_modificar 'prime_time_hora_hasta', 25; --> Hora de fin fuera de rango (mayor a 24)
-- EXEC torneo.parametro_modificar 'prime_time_hora_desde', 24; --> Hora de inicio fuera de rango (mayor a 23)
-- EXEC torneo.parametro_modificar 'no_existe_xx', 1, ''; --> 2 errores: parametro inexistente y descripcion vacia
-- EXEC torneo.parametro_modificar 'no_existe_xx', -1, ''; --> 3 errores: parametro inexistente, valor negativo y descripcion vacia

-- Verificacion torneo.parametro_eliminar
EXEC torneo.parametro_eliminar 'tst_elim'; --> Baja valida
-- EXEC torneo.parametro_eliminar 'tst_elim'; --> Parametro inexistente 
-- EXEC torneo.parametro_eliminar 'no_existe_xx'; --> Parametro inexistente
-- EXEC torneo.parametro_eliminar NULL; --> Clave nula 
-- EXEC torneo.parametro_eliminar ''; --> Clave vacia (no existe)
-- EXEC torneo.parametro_eliminar 'convocatoria_min_jugadores'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'convocatoria_max_jugadores'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'formacion_titulares'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'formacion_max_suplentes'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'cambios_max_reglamentarios'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'ventanas_max_reglamentarias'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'cambios_extra_alargue'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'ventanas_extra_alargue'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'suspension_partidos_roja'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'prime_time_hora_desde'; --> Requerido por la logica de negocio
-- EXEC torneo.parametro_eliminar 'prime_time_hora_hasta'; --> Requerido por la logica de negocio


-- Limpieza de torneo.parametro (al terminar; descomentar y ejecutar todo junto)
DECLARE @bk_hasta INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_hasta'),
        @bk_desde INT = (SELECT valor FROM torneo.parametro WHERE clave = 'tst_backup_desde');
EXEC torneo.parametro_modificar 'prime_time_hora_hasta', @bk_hasta;   -- deja prime_time_* como estaban
EXEC torneo.parametro_modificar 'prime_time_hora_desde', @bk_desde;
DELETE FROM torneo.parametro WHERE clave LIKE 'tst[_]%';
GO


-- ============================================================
-- 1.2 torneo.pais y torneo.confederacion
-- ============================================================
-- Preparación de torneo.pais_* (ejecutar UNA sola vez)
DECLARE @conf INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id);
-- SI TIRA EL SIGUIENTE  ERROR, HAY QUE EJECUTAR LA PREPARACION DE CONFEDERACIONES DE FORMA PREVIA PARA PODER CONTINUAR
IF @conf IS NULL THROW 50000, 'No hay confederaciones en torneo.confederacion: cargar al menos una con torneo.confederacion_insertar.', 1;

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

-- Verificacion torneo.pais_validar
DECLARE @e VARCHAR(2000),
        @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZM'),
        @n80 VARCHAR(80) = REPLICATE('N', 80);

SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> Valido
-- SET @e = ''; EXEC torneo.pais_validar @m, 'ZZM', 'Test Modificar', 'UTC-03', 100, @e OUTPUT;   --> Valido 
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', NULL, @e OUTPUT;   --> Valido: PBI nulo
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', 0, @e OUTPUT;   --> Valido: PBI 0 
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'zzv', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> Valido: ISO en minusculas
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', @n80, 'UTC+14', 100, @e OUTPUT;   --> Valido: nombre de 80 caracteres y huso UTC+14 (bordes)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-12', 100, @e OUTPUT;   --> Valido: huso UTC-12 (borde)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC+00', 100, @e OUTPUT;   --> Valido: huso UTC+00
-- SET @e = ''; EXEC torneo.pais_validar 999999, 'ZZV', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> Pais inexistente (1 error)
-- SET @e = ''; EXEC torneo.pais_validar NULL, NULL, 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO nulo
-- SET @e = ''; EXEC torneo.pais_validar NULL, '', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO vacio
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO de 2 letras
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO de 4 letras
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ1', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO con numero
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ-', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO con simbolo
-- SET @e = ''; EXEC torneo.pais_validar NULL, ' ZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO con espacio al inicio (3 caracteres, uno es espacio)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ ', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO con espacio al final (LEN lo ignora, pero el patron lo rechaza)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZI', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO duplicado (alta)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'zzi', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO duplicado con otra capitalizacion 
-- SET @e = ''; EXEC torneo.pais_validar @m, 'ZZN', 'Test Modificar', 'UTC-03', 100, @e OUTPUT;   --> ISO duplicado
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', NULL, 'UTC-03', 100, @e OUTPUT;   --> Nombre nulo
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', '', 'UTC-03', 100, @e OUTPUT;   --> Nombre vacio
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', '   ', 'UTC-03', 100, @e OUTPUT;   --> Nombre solo espacios
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', NULL, 100, @e OUTPUT;   --> Huso nulo
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', '', 100, @e OUTPUT;   --> Huso vacio
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-3', 100, @e OUTPUT;   --> Huso con 1 digito (longitud 5)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-003', 100, @e OUTPUT;   --> Huso con 3 digitos (longitud 7)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'GMT-03', 100, @e OUTPUT;   --> Huso con prefijo incorrecto
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC 03', 100, @e OUTPUT;   --> Huso sin signo (espacio en su lugar)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-0A', 100, @e OUTPUT;   --> Huso con letra en los digitos
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03 ', 100, @e OUTPUT;   --> Huso con espacio final (formato)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC+15', 100, @e OUTPUT;   --> Huso fuera de rango (mayor a +14)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-13', 100, @e OUTPUT;   --> Huso fuera de rango (menor a -12)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC+99', 100, @e OUTPUT;   --> Huso fuera de rango (+99)
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZV', 'Test Validar', 'UTC-03', -0.01, @e OUTPUT;   --> PBI negativo
-- SET @e = ''; EXEC torneo.pais_validar 999999, 'AB', '', 'UTC3', -1, @e OUTPUT;   --> 5 errores: pais inexistente, ISO, nombre, huso (formato) y PBI
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'AB', '', 'UTC3', -1, @e OUTPUT;   --> 4 errores: ISO, nombre, huso (formato) y PBI
-- SET @e = ''; EXEC torneo.pais_validar NULL, NULL, NULL, NULL, NULL, @e OUTPUT;   --> 3 errores: ISO, nombre y huso (el PBI nulo es valido)
-- SET @e = 'Error previo' + CHAR(13) + CHAR(10); EXEC torneo.pais_validar NULL, 'ZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> Acumula: conserva "Error previo" y agrega el del ISO
-- SET @e = NULL; EXEC torneo.pais_validar NULL, 'ZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> @errores de entrada NULL se toma como vacio: solo el error del ISO
GO


-- Verificacion torneo.pais_insertar
DECLARE @id INT, @n80 VARCHAR(80) = REPLICATE('N', 80);
EXEC torneo.pais_insertar 'ZZA', 'Test Alta', 'UTC-03', 1500.75, @id OUTPUT; SELECT @id AS pais_id_generado; --> Valido: devuelve el id generado
-- EXEC torneo.pais_insertar 'ZZB', 'Test Sin PBI', 'UTC-03', @pais_id = @id OUTPUT; --> Valido: sin PBI (queda NULL)
-- EXEC torneo.pais_insertar 'ZZD', 'Test PBI Cero', 'UTC-03', 0, @id OUTPUT; --> Valido: PBI 0 (borde)
-- EXEC torneo.pais_insertar 'ZZG', '  Test Espacios  ', 'UTC-03', 10, @id OUTPUT; --> Valido: el nombre se guarda recortado
-- EXEC torneo.pais_insertar 'ZZH', 'Test Huso Max', 'UTC+14', 10, @id OUTPUT; --> Valido: huso UTC+14 (borde superior)
-- EXEC torneo.pais_insertar 'ZZJ', @n80, 'UTC-03', 10, @id OUTPUT; --> Valido: nombre de 80 caracteres (borde)
-- EXEC torneo.pais_insertar NULL, 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO nulo
-- EXEC torneo.pais_insertar '', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO vacio
-- EXEC torneo.pais_insertar 'ZZ', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO de 2 letras
-- EXEC torneo.pais_insertar 'ZZZZ', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO de 4 letras
-- EXEC torneo.pais_insertar 'ZZ1', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO con numero
-- EXEC torneo.pais_insertar 'ZZ-', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO con simbolo
-- EXEC torneo.pais_insertar ' ZZ', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO con espacio al inicio
-- EXEC torneo.pais_insertar 'ZZ ', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO con espacio al final
-- EXEC torneo.pais_insertar 'ZZI', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO duplicado 
-- EXEC torneo.pais_insertar 'zzi', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO duplicado con otra capitalizacion (CI: rechaza; CS: lo acepta)
-- EXEC torneo.pais_insertar 'ZZW', NULL, 'UTC-03', 10, @id OUTPUT; --> Nombre nulo
-- EXEC torneo.pais_insertar 'ZZW', '', 'UTC-03', 10, @id OUTPUT; --> Nombre vacio
-- EXEC torneo.pais_insertar 'ZZW', '   ', 'UTC-03', 10, @id OUTPUT; --> Nombre solo espacios
-- EXEC torneo.pais_insertar 'ZZW', 'Test', NULL, 10, @id OUTPUT; --> Huso nulo
-- EXEC torneo.pais_insertar 'ZZW', 'Test', '', 10, @id OUTPUT; --> Huso vacio
-- EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC-3', 10, @id OUTPUT; --> Huso con 1 digito
-- EXEC torneo.pais_insertar 'ZZW', 'Test', 'GMT-03', 10, @id OUTPUT; --> Huso con prefijo incorrecto
-- EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC 03', 10, @id OUTPUT; --> Huso sin signo
-- EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC-0A', 10, @id OUTPUT; --> Huso con letra
-- EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC+15', 10, @id OUTPUT; --> Huso fuera de rango (mayor a +14)
-- EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC-13', 10, @id OUTPUT; --> Huso fuera de rango (menor a -12)
-- EXEC torneo.pais_insertar 'ZZW', 'Test', 'UTC-03', -0.01, @id OUTPUT; --> PBI negativo
-- EXEC torneo.pais_insertar 'ZZ', '', 'UTC-03', 10, @id OUTPUT; --> 2 errores: ISO y nombre
-- EXEC torneo.pais_insertar NULL, NULL, NULL, NULL, @id OUTPUT; --> 3 errores: ISO, nombre y huso (el PBI nulo es valido)
-- EXEC torneo.pais_insertar 'AB', '', 'UTC3', -1, @id OUTPUT; --> 4 errores: ISO, nombre, huso (formato) y PBI


-- Verificacion torneo.pais_modificar
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX')),
        @n80 VARCHAR(80) = REPLICATE('N', 80);

EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificado', 'UTC-04', 2500; --> Valido
-- EXEC torneo.pais_modificar @m, 'ZZM', @n80, 'UTC-03', 2000; --> Valido: nombre de 80 caracteres (borde)
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC+14', 0; --> Valido: huso UTC+14 y PBI 0 (bordes)
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC-03'; --> Valido: sin PBI, lo deja en NULL (pisa el valor anterior)
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC-03', 2000; --> Restaurar: deja ZZM como estaba 
-- EXEC torneo.pais_modificar 999999, 'ZZY', 'Test', 'UTC-03', 10; --> Pais inexistente 
-- EXEC torneo.pais_modificar NULL, 'ZZY', 'Test', 'UTC-03', 10; --> Id nulo 
-- EXEC torneo.pais_modificar NULL, 'ZZM', 'Test', 'UTC-03', 10; --> 2 errores: id obligatorio y ISO duplicado 
-- EXEC torneo.pais_modificar @m, NULL, 'Test', 'UTC-03', 10; --> ISO nulo
-- EXEC torneo.pais_modificar @m, '', 'Test', 'UTC-03', 10; --> ISO vacio
-- EXEC torneo.pais_modificar @m, 'ZZ', 'Test', 'UTC-03', 10; --> ISO de 2 letras
-- EXEC torneo.pais_modificar @m, 'ZZZZ', 'Test', 'UTC-03', 10; --> ISO de 4 letras
-- EXEC torneo.pais_modificar @m, 'ZZ1', 'Test', 'UTC-03', 10; --> ISO con numero
-- EXEC torneo.pais_modificar @m, 'ZZ ', 'Test', 'UTC-03', 10; --> ISO con espacio al final
-- EXEC torneo.pais_modificar @m, 'ZZN', 'Test', 'UTC-03', 10; --> ISO duplicado 
-- EXEC torneo.pais_modificar @m, 'zzn', 'Test', 'UTC-03', 10; --> ISO duplicado con otra capitalizacion (CI: rechaza; CS: lo acepta)
-- EXEC torneo.pais_modificar @m, 'ZZM', NULL, 'UTC-03', 10; --> Nombre nulo
-- EXEC torneo.pais_modificar @m, 'ZZM', '', 'UTC-03', 10; --> Nombre vacio
-- EXEC torneo.pais_modificar @m, 'ZZM', '   ', 'UTC-03', 10; --> Nombre solo espacios
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test', NULL, 10; --> Huso nulo
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test', '', 10; --> Huso vacio
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC-3', 10; --> Huso con 1 digito
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'GMT-03', 10; --> Huso con prefijo incorrecto
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC-0A', 10; --> Huso con letra
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC+15', 10; --> Huso fuera de rango (mayor a +14)
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC-13', 10; --> Huso fuera de rango (menor a -12)
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test', 'UTC-03', -0.01; --> PBI negativo
-- EXEC torneo.pais_modificar @m, 'ZZN', 'Test', 'UTC+15', 10; --> 2 errores: ISO duplicado y huso fuera de rango
-- EXEC torneo.pais_modificar 999999, 'ZZY', '', 'UTC-03', -1; --> 3 errores: pais inexistente, nombre y PBI
-- EXEC torneo.pais_modificar @m, 'ZZN', '', 'UTC+15', -1; --> 4 errores: ISO duplicado, nombre, huso fuera de rango y PBI
-- EXEC torneo.pais_modificar 999999, 'AB', '', 'UTC3', -1; --> 5 errores: pais inexistente, ISO, nombre, huso (formato) y PBI

-- Verificacion torneo.pais_eliminar
DECLARE @e INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZE'),
        @s INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZS'),
        @l INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZL'),
        @r INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZR'),
        @c INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZC'),
        @p INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZP'),
        @t INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZZT');

EXEC torneo.pais_eliminar @e; --> Baja valida 
-- EXEC torneo.pais_eliminar 999999; --> Pais inexistente
-- EXEC torneo.pais_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC torneo.pais_eliminar @s; --> Tiene sedes asociadas
-- EXEC torneo.pais_eliminar @l; --> Tiene una seleccion participante
-- EXEC torneo.pais_eliminar @r; --> Tiene arbitros registrados
-- EXEC torneo.pais_eliminar @c; --> Es pais de interes de campañas publicitarias
-- EXEC torneo.pais_eliminar @p; --> 2 errores: pais de interes y mercado de piezas
-- EXEC torneo.pais_eliminar @t; --> 5 errores: sedes, seleccion, arbitros, interes de campañas y mercado de piezas

-- Limpieza de torneo.pais (al terminar; descomentar y ejecutar todo junto)
DELETE pz FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre = 'PAIS_CAMP';
DELETE i FROM publicidad.campania_pais_interes i JOIN publicidad.campania c ON c.campania_id = i.campania_id WHERE c.nombre = 'PAIS_CAMP';
DELETE FROM publicidad.campania WHERE nombre = 'PAIS_CAMP';
DELETE FROM publicidad.anunciante WHERE nombre = 'PAIS_ANUN';
DELETE FROM arbitraje.arbitro WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso LIKE 'ZZ[A-Z]');
DELETE FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso LIKE 'ZZ[A-Z]');
DELETE FROM torneo.sede WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso LIKE 'ZZ[A-Z]');
DELETE FROM torneo.pais WHERE codigo_iso LIKE 'ZZ[A-Z]';
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


-- Verificacion torneo.confederacion_insertar
DECLARE @id INT;

EXEC torneo.confederacion_insertar 'OFC', @id OUTPUT; SELECT @id AS confederacion_id_generado; --> Valido: devuelve el id generado
-- EXEC torneo.confederacion_insertar 'CAF', @id OUTPUT; --> Valido: otra confederacion libre
-- EXEC torneo.confederacion_insertar 'CONCACAF', @id OUTPUT; --> Valido: la mas larga de la lista 
-- EXEC torneo.confederacion_insertar 'caf', @id OUTPUT; --> Depende de la collation: CI la acepta y la guarda en mayusculas (CAF); CS la rechaza por formato. Requiere CAF libre
-- EXEC torneo.confederacion_insertar NULL, @id OUTPUT; --> Nombre nulo
-- EXEC torneo.confederacion_insertar '', @id OUTPUT; --> Nombre vacio
-- EXEC torneo.confederacion_insertar '   ', @id OUTPUT; --> Nombre solo espacios
-- EXEC torneo.confederacion_insertar 'XYZ', @id OUTPUT; --> Nombre fuera de la lista
-- EXEC torneo.confederacion_insertar 'FIFA', @id OUTPUT; --> Nombre fuera de la lista (FIFA no es confederacion)
-- EXEC torneo.confederacion_insertar 'UEF', @id OUTPUT; --> Nombre incompleto
-- EXEC torneo.confederacion_insertar 'UEFAA', @id OUTPUT; --> Nombre con letra de mas
-- EXEC torneo.confederacion_insertar ' OFC', @id OUTPUT; --> Espacio al inicio: no coincide con la lista
-- EXEC torneo.confederacion_insertar 'AFC', @id OUTPUT; --> Duplicada 
-- EXEC torneo.confederacion_insertar 'CONMEBOL', @id OUTPUT; --> Duplicada (CONMEBOL ya esta registrada)
-- EXEC torneo.confederacion_insertar 'afc', @id OUTPUT; --> Duplicada con otra capitalizacion (CI: duplicada; CS: formato invalido; 1 error en ambos casos)
-- EXEC torneo.confederacion_insertar 'AFC ', @id OUTPUT; --> Duplicada con espacio al final (SQL Server ignora el espacio final en "=" e "IN"): 1 error

-- Verificacion torneo.confederacion_modificar
DECLARE @u INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre IN ('UEFA', 'OFC'));

EXEC torneo.confederacion_modificar @u, 'OFC'; --> Valido: UEFA pasa a OFC
-- EXEC torneo.confederacion_modificar @u, 'UEFA'; --> Restaurar: deja la base como estaba 
-- EXEC torneo.confederacion_modificar 999999, 'OFC'; --> Confederacion inexistente
-- EXEC torneo.confederacion_modificar NULL, 'OFC'; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC torneo.confederacion_modificar @u, NULL; --> Nombre nulo
-- EXEC torneo.confederacion_modificar @u, ''; --> Nombre vacio
-- EXEC torneo.confederacion_modificar @u, 'XYZ'; --> Nombre fuera de la lista
-- EXEC torneo.confederacion_modificar @u, ' UEFA'; --> Espacio al inicio: no coincide con la lista
-- EXEC torneo.confederacion_modificar @u, 'AFC'; --> Duplicada: AFC pertenece a otra confederacion
-- EXEC torneo.confederacion_modificar @u, 'CONMEBOL'; --> Duplicada: CONMEBOL pertenece a otra confederacion
-- EXEC torneo.confederacion_modificar @u, 'afc'; --> Duplicada con otra capitalizacion
-- EXEC torneo.confederacion_modificar 999999, 'AFC'; --> 2 errores: confederacion inexistente y nombre duplicado (AFC es de otro id)


-- Verificacion torneo.confederacion_eliminar
DECLARE @a INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'AFC'),
        @c INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CONMEBOL');

EXEC torneo.confederacion_eliminar @a; --> Baja valida (sin selecciones)
-- EXEC torneo.confederacion_eliminar 999999; --> Confederacion inexistente
-- EXEC torneo.confederacion_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC torneo.confederacion_eliminar @c; --> Tiene selecciones afiliadas


-- Limpieza de torneo.confederacion (al terminar; descomentar y ejecutar todo junto)
DELETE FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZYC');
DELETE FROM torneo.pais WHERE codigo_iso = 'ZYC';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'AFC')      EXEC torneo.confederacion_insertar 'AFC';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'CAF')      EXEC torneo.confederacion_insertar 'CAF';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'CONCACAF') EXEC torneo.confederacion_insertar 'CONCACAF';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'CONMEBOL') EXEC torneo.confederacion_insertar 'CONMEBOL';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'OFC')      EXEC torneo.confederacion_insertar 'OFC';
IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = 'UEFA')     EXEC torneo.confederacion_insertar 'UEFA';
GO

-- ============================================================
-- 1.3 torneo.sede
-- ============================================================
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

-- Verificacion torneo.sede_insertar
DECLARE @id INT,
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSB'),
        @n80 VARCHAR(80) = 'Test Sede ' + REPLICATE('N', 70);

EXEC torneo.sede_insertar 'Test Sede Alta', 'Ciudad Otra', @pa, 60000, 'UTC-03', @id OUTPUT; --> Valido: mismo nombre en otra ciudad
-- EXEC torneo.sede_insertar 'Test Sede Otro', 'Ciudad Alta', @pb, 60000, 'UTC-05', @id OUTPUT; --> Valido: misma ciudad con otro nombre, otro pais
-- EXEC torneo.sede_insertar 'Test Sede Max', 'Ciudad Max', @pa, 2147483647, 'UTC-03', @id OUTPUT; --> Valido: capacidad maxima INT (borde)
-- EXEC torneo.sede_insertar NULL, 'Ciudad X', @pa, 10, 'UTC-03', @id OUTPUT; --> Nombre nulo
-- EXEC torneo.sede_insertar '', 'Ciudad X', @pa, 10, 'UTC-03', @id OUTPUT; --> Nombre vacio
-- EXEC torneo.sede_insertar '   ', 'Ciudad X', @pa, 10, 'UTC-03', @id OUTPUT; --> Nombre solo espacios
-- EXEC torneo.sede_insertar 'Test Sede X', NULL, @pa, 10, 'UTC-03', @id OUTPUT; --> Ciudad nula
-- EXEC torneo.sede_insertar 'Test Sede X', '', @pa, 10, 'UTC-03', @id OUTPUT; --> Ciudad vacia
-- EXEC torneo.sede_insertar 'Test Sede X', '   ', @pa, 10, 'UTC-03', @id OUTPUT; --> Ciudad solo espacios
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', 999999, 10, 'UTC-03', @id OUTPUT; --> Pais inexistente
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', NULL, 10, 'UTC-03', @id OUTPUT; --> Pais nulo
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, NULL, 'UTC-03', @id OUTPUT; --> Capacidad nula
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 0, 'UTC-03', @id OUTPUT; --> Capacidad 0
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, -1, 'UTC-03', @id OUTPUT; --> Capacidad negativa
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, NULL, @id OUTPUT; --> Huso nulo
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, '', @id OUTPUT; --> Huso vacio
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC-3', @id OUTPUT; --> Huso con 1 digito
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'GMT-03', @id OUTPUT; --> Huso con prefijo incorrecto
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC 03', @id OUTPUT; --> Huso sin signo
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC-0A', @id OUTPUT; --> Huso con letra
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC+15', @id OUTPUT; --> Huso fuera de rango (mayor a +14)
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', @pa, 10, 'UTC-13', @id OUTPUT; --> Huso fuera de rango (menor a -12)
-- EXEC torneo.sede_insertar 'Test Sede Base', 'Ciudad Test', @pa, 10, 'UTC-03', @id OUTPUT; --> Duplicado: mismo nombre y ciudad que la base
-- EXEC torneo.sede_insertar '', '', @pa, 10, 'UTC-03', @id OUTPUT; --> 2 errores: nombre y ciudad
-- EXEC torneo.sede_insertar 'Test Sede X', 'Ciudad X', 999999, 0, 'UTC-03', @id OUTPUT; --> 2 errores: pais inexistente y capacidad
-- EXEC torneo.sede_insertar 'Test Sede Base', 'Ciudad Test', 999999, -1, 'UTC3', @id OUTPUT; --> 4 errores: pais, capacidad, huso (formato) y duplicado
-- EXEC torneo.sede_insertar NULL, NULL, NULL, NULL, NULL, @id OUTPUT; --> 5 errores (maximo): nombre, ciudad, pais, capacidad y huso


-- Verificacion torneo.sede_modificar
DECLARE @m INT = (SELECT sede_id FROM torneo.sede WHERE nombre IN ('Test Sede Mod', 'Test Sede Mod Nuevo') AND ciudad LIKE 'Ciudad Mod%'),
        @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSB'),
        @pc INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSC'),
        @n80 VARCHAR(80) = 'Test Sede ' + REPLICATE('N', 70);

EXEC torneo.sede_modificar @m, 'Test Sede Mod Nuevo', 'Ciudad Mod Nueva', @pb, 45000, 'UTC-05'; --> Valido
-- EXEC torneo.sede_modificar @m, '  Test Sede Mod  ', '  Ciudad Mod  ', @pa, 40000, 'UTC-03'; --> Valido: se guarda recortado
-- EXEC torneo.sede_modificar 999999, 'Test Sede Nueva', 'Ciudad Nueva', @pa, 10, 'UTC-03'; --> Sede inexistente
-- EXEC torneo.sede_modificar NULL, 'Test Sede Nueva', 'Ciudad Nueva', @pa, 10, 'UTC-03'; --> Id nulo 
-- EXEC torneo.sede_modificar @m, NULL, 'Ciudad Mod', @pa, 40000, 'UTC-03'; --> Nombre nulo
-- EXEC torneo.sede_modificar @m, '', 'Ciudad Mod', @pa, 40000, 'UTC-03'; --> Nombre vacio
-- EXEC torneo.sede_modificar @m, '   ', 'Ciudad Mod', @pa, 40000, 'UTC-03'; --> Nombre solo espacios
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', NULL, @pa, 40000, 'UTC-03'; --> Ciudad nula
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', '', @pa, 40000, 'UTC-03'; --> Ciudad vacia
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', '   ', @pa, 40000, 'UTC-03'; --> Ciudad solo espacios
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', 999999, 40000, 'UTC-03'; --> Pais inexistente
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', NULL, 40000, 'UTC-03'; --> Pais nulo
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, NULL, 'UTC-03'; --> Capacidad nula
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 0, 'UTC-03'; --> Capacidad 0
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, -1, 'UTC-03'; --> Capacidad negativa
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, NULL; --> Huso nulo
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, ''; --> Huso vacio
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'UTC-3'; --> Huso con 1 digito
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'GMT-03'; --> Huso con prefijo incorrecto
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'UTC-0A'; --> Huso con letra
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'UTC+15'; --> Huso fuera de rango (mayor a +14)
-- EXEC torneo.sede_modificar @m, 'Test Sede Mod', 'Ciudad Mod', @pa, 40000, 'UTC-13'; --> Huso fuera de rango (menor a -12)
-- EXEC torneo.sede_modificar @m, 'Test Sede Otra', 'Ciudad Mod', @pa, 40000, 'UTC-03'; --> Duplicado: nombre y ciudad de otra sede
-- EXEC torneo.sede_modificar @m, 'TEST SEDE OTRA', 'CIUDAD MOD', @pa, 40000, 'UTC-03'; --> Duplicado con otra capitalizacion 
-- EXEC torneo.sede_modificar @m, 'Test Sede Otra  ', 'Ciudad Mod  ', @pa, 40000, 'UTC-03'; --> Duplicado con espacios al final
-- EXEC torneo.sede_modificar @p, 'Test Sede Partido', 'Ciudad Partido', @pa, 40000, 'UTC-04'; --> Con partidos: no se puede cambiar el huso
-- EXEC torneo.sede_modificar @p, 'Test Sede Partido', 'Ciudad Partido', @pa, 39999, 'UTC-03'; --> Capacidad menor a la asistencia registrada
-- EXEC torneo.sede_modificar @p, 'Test Sede Partido', 'Ciudad Partido', @pa, NULL, 'UTC-03'; --> 1 error: capacidad nula (el control contra la asistencia no se dispara con NULL)
-- EXEC torneo.sede_modificar 999999, 'Test Sede Otra', 'Ciudad Mod', @pa, 10, 'UTC-03'; --> 2 errores: sede inexistente y duplicado
-- EXEC torneo.sede_modificar @m, 'Test Sede Otra', 'Ciudad Mod', @pa, 0, 'UTC+15'; --> 3 errores: duplicado, capacidad y huso fuera de rango
-- EXEC torneo.sede_modificar NULL, NULL, NULL, NULL, NULL, NULL; --> 6 errores: id obligatorio, nombre, ciudad, pais, capacidad y huso
-- EXEC torneo.sede_modificar @m, '', '', 999999, -1, 'UTC3'; --> 5 errores: nombre, ciudad, pais, capacidad y huso (formato); sin partidos no hay controles extra
-- EXEC torneo.sede_modificar @p, '', '', 999999, -1, 'UTC3'; --> 7 errores (maximo): nombre, ciudad, pais, capacidad, huso (formato), cambio de huso con partidos y capacidad menor a la asistencia

-- Verificacion torneo.sede_eliminar
DECLARE @e INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Elim' AND ciudad = 'Ciudad Elim'),
        @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');

EXEC torneo.sede_eliminar @e; --> Baja valida (sin partidos)
-- EXEC torneo.sede_eliminar 999999; --> Sede inexistente
-- EXEC torneo.sede_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC torneo.sede_eliminar @p; --> Tiene partidos asociados

-- Limpieza de torneo.sede (al terminar; descomentar y ejecutar todo junto)
DELETE FROM torneo.partido WHERE sede_id IN (SELECT sede_id FROM torneo.sede WHERE nombre LIKE 'Test Sede%');
DELETE FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZSA', 'ZSB', 'ZSC'));
DELETE FROM torneo.sede WHERE nombre LIKE 'Test Sede%';
DELETE FROM torneo.pais WHERE codigo_iso IN ('ZSA', 'ZSB', 'ZSC');
GO

-- ============================================================
-- 1.4 torneo.seleccion
-- ============================================================
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

-- Verificacion torneo.seleccion_insertar
DECLARE @id INT,
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQA'),
        @pb INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQB'),
        @pc INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQC'),
        @pd INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQD'),
        @pe INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQE'),
        @pl INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQL');
DECLARE @c2 INT = ISNULL((SELECT TOP 1 confederacion_id FROM torneo.confederacion WHERE confederacion_id > @c1 ORDER BY confederacion_id), @c1);

-- EXEC torneo.seleccion_insertar @pb, @c1, 'A', @id OUTPUT; --> Valido: grupo borde A (cada alta valida usa un pais distinto: ZQB, ZQC, ZQD, ZQE)
-- EXEC torneo.seleccion_insertar @pc, @c2, 'b', @id OUTPUT; --> Valido: grupo en minuscula (se guarda 'B')
-- EXEC torneo.seleccion_insertar @pd, @c1, 'L', @id OUTPUT; --> Valido: grupo borde L
-- EXEC torneo.seleccion_insertar @pe, @c1, 'l', @id OUTPUT; --> Valido: grupo borde L en minuscula (se guarda 'L')
-- EXEC torneo.seleccion_insertar NULL, @c1, 'A', @id OUTPUT; --> Pais nulo
-- EXEC torneo.seleccion_insertar 999999, @c1, 'A', @id OUTPUT; --> Pais inexistente
-- EXEC torneo.seleccion_insertar @pa, @c1, 'A', @id OUTPUT; --> Pais ya tiene seleccion
-- EXEC torneo.seleccion_insertar @pl, NULL, 'A', @id OUTPUT; --> Confederacion nula
-- EXEC torneo.seleccion_insertar @pl, 999999, 'A', @id OUTPUT; --> Confederacion inexistente
-- EXEC torneo.seleccion_insertar @pl, @c1, NULL, @id OUTPUT; --> Grupo nulo
-- EXEC torneo.seleccion_insertar @pl, @c1, '', @id OUTPUT; --> Grupo vacio
-- EXEC torneo.seleccion_insertar @pl, @c1, ' ', @id OUTPUT; --> Grupo solo espacio
-- EXEC torneo.seleccion_insertar @pl, @c1, 'M', @id OUTPUT; --> Grupo fuera de rango (despues de L)
-- EXEC torneo.seleccion_insertar @pl, @c1, 'm', @id OUTPUT; --> Grupo fuera de rango en minuscula
-- EXEC torneo.seleccion_insertar @pl, @c1, '@', @id OUTPUT; --> Grupo fuera de rango (antes de A)
-- EXEC torneo.seleccion_insertar @pl, @c1, '1', @id OUTPUT; --> Grupo numerico
-- EXEC torneo.seleccion_insertar @pl, @c1, 'AB', @id OUTPUT; --> Grupo con 2 letras
-- EXEC torneo.seleccion_insertar @pl, @c1, ' A', @id OUTPUT; --> Grupo con espacio al inicio
-- EXEC torneo.seleccion_insertar @pl, @c1, 'A ', @id OUTPUT; --> Grupo con espacio al final
-- EXEC torneo.seleccion_insertar @pa, 999999, NULL, @id OUTPUT; --> 3 errores: pais duplicado, confederacion y grupo
-- EXEC torneo.seleccion_insertar NULL, NULL, '', @id OUTPUT; --> 3 errores (maximo): pais, confederacion y grupo
-- EXEC torneo.seleccion_insertar 999999, 999999, 'Z', @id OUTPUT; --> 3 errores (maximo): pais inexistente, confederacion y grupo
GO

-- Verificacion torneo.seleccion_modificar
DECLARE @m INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso IN ('ZQM', 'ZQN')),
        @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP'),
        @c1 INT = (SELECT TOP 1 confederacion_id FROM torneo.confederacion ORDER BY confederacion_id),
        @pm INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQM'),
        @pn INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQN'),
        @po INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQO'),
        @pp INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZQP');
DECLARE @c2 INT = ISNULL((SELECT TOP 1 confederacion_id FROM torneo.confederacion WHERE confederacion_id > @c1 ORDER BY confederacion_id), @c1);

EXEC torneo.seleccion_modificar @m, @pn, @c2, 'H'; --> Valido: cambia pais (a uno libre), confederacion y grupo (sin partidos)
-- EXEC torneo.seleccion_modificar 999999, @pm, @c1, 'B'; --> Seleccion inexistente
-- EXEC torneo.seleccion_modificar NULL, @pm, @c1, 'B'; --> Id nulo (id obligatorio)
-- EXEC torneo.seleccion_modificar @m, NULL, @c1, 'B'; --> Pais nulo
-- EXEC torneo.seleccion_modificar @m, 999999, @c1, 'B'; --> Pais inexistente
-- EXEC torneo.seleccion_modificar @m, @po, @c1, 'B'; --> Pais ya tiene otra seleccion
-- EXEC torneo.seleccion_modificar @m, @pm, NULL, 'B'; --> Confederacion nula
-- EXEC torneo.seleccion_modificar @m, @pm, 999999, 'B'; --> Confederacion inexistente
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, NULL; --> Grupo nulo
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, ''; --> Grupo vacio
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, ' '; --> Grupo solo espacio
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, 'M'; --> Grupo fuera de rango (despues de L)
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, 'm'; --> Grupo fuera de rango en minuscula
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, '@'; --> Grupo fuera de rango (antes de A)
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, '1'; --> Grupo numerico
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, 'AB'; --> Grupo con 2 letras
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, ' A'; --> Grupo con espacio al inicio
-- EXEC torneo.seleccion_modificar @m, @pm, @c1, 'A '; --> Grupo con espacio al final
-- EXEC torneo.seleccion_modificar @p, @pp, @c1, 'E'; --> Con partidos de grupos: no se puede cambiar el grupo
-- EXEC torneo.seleccion_modificar @p, @pp, @c1, 'e'; --> Con partidos de grupos: cambio de grupo en minuscula
-- EXEC torneo.seleccion_modificar @p, @pp, @c1, NULL; --> 1 error: grupo nulo 
-- EXEC torneo.seleccion_modificar @p, @pp, @c1, 'M'; --> 2 errores: grupo invalido y cambio de grupo con partidos
-- EXEC torneo.seleccion_modificar @p, 999999, 999999, 'Z'; --> 4 errores (maximo): pais, confederacion, grupo y cambio de grupo con partidos
GO

-- Verificacion torneo.seleccion_eliminar
DECLARE @e INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQX'),
        @p INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQP'),
        @cv INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQV'),
        @ct INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQT'),
        @k INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZQK');

EXEC torneo.seleccion_eliminar @e; --> Baja valida 
-- EXEC torneo.seleccion_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC torneo.seleccion_eliminar @p; --> Tiene partidos asociados
-- EXEC torneo.seleccion_eliminar @cv; --> Tiene jugadores convocados (requiere cargar la convocatoria en la preparacion)
-- EXEC torneo.seleccion_eliminar @ct; --> Tiene cuerpo tecnico registrado (requiere cargar el cuerpo tecnico en la preparacion)
-- EXEC torneo.seleccion_eliminar @k; --> 3 errores (maximo): partidos, convocados y cuerpo tecnico (requiere los datos de plantel)
GO

-- Limpieza de torneo.seleccion (al terminar; descomentar y ejecutar todo junto)
DELETE FROM plantel.convocatoria WHERE seleccion_id IN (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso LIKE 'ZQ_'));
DELETE FROM plantel.cuerpo_tecnico WHERE seleccion_id IN (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso LIKE 'ZQ_'));
DELETE FROM torneo.partido WHERE seleccion_local_id IN (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso LIKE 'ZQ_'))
                              OR seleccion_visitante_id IN (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso LIKE 'ZQ_'));
DELETE FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso LIKE 'ZQ_');
DELETE FROM torneo.sede WHERE nombre LIKE 'Test Sel%';
DELETE FROM torneo.pais WHERE codigo_iso LIKE 'ZQ_';
GO

-- ============================================================
-- 1.5 torneo.partido
-- ============================================================

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

-- Verificacion torneo.partido_insertar
DECLARE @id INT,
        @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base'),
        @s5 INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Cinco'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');

EXEC torneo.partido_insertar @sl, '2026-09-10 15:00:00 -03:00', 'dieciseisavos', @a4, @b1, NULL, @id OUTPUT; --> Valido: UTC se deriva de la hora local (verificar con SELECT)
-- EXEC torneo.partido_insertar @sl, '2026-09-15 15:00:00 -03:00', 'octavos', @a4, @b1, '2026-09-15 18:00:00 +00:00', @id OUTPUT; --> Valido: UTC informado y consistente
-- EXEC torneo.partido_insertar @s5, '2026-09-20 15:00:00 -05:00', 'cuartos', @a3, @b1, NULL, @id OUTPUT; --> Valido: sede con huso UTC-05 (UTC derivado = 20:00 +00:00)
-- EXEC torneo.partido_insertar @sl, '2026-09-25 15:00:00 -03:00', 'grupos', @a2, @a4, NULL, @id OUTPUT; --> Valido: fase de grupos, mismo grupo
-- EXEC torneo.partido_insertar NULL, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3, NULL, @id OUTPUT; --> Sede nula
-- EXEC torneo.partido_insertar 999999, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3, NULL, @id OUTPUT; --> Sede inexistente
-- EXEC torneo.partido_insertar @sl, NULL, 'grupos', @a1, @a3, NULL, @id OUTPUT; --> Fecha local nula (el UTC derivado tambien queda nulo, un solo error)
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -05:00', 'grupos', @a1, @a3, NULL, @id OUTPUT; --> Hora local en otro huso
-- EXEC torneo.partido_insertar @sl, '2026-08-10 18:00:00 +00:00', 'grupos', @a1, @a3, NULL, @id OUTPUT; --> Hora local expresada en UTC
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3, '2026-08-10 15:00:00 -03:00', @id OUTPUT; --> UTC informado con desplazamiento distinto de +00:00
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a3, '2026-08-10 19:00:00 +00:00', @id OUTPUT; --> UTC informado que no coincide con la hora local
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', NULL, @a1, @a3, NULL, @id OUTPUT; --> Fase nula
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', '', @a1, @a3, NULL, @id OUTPUT; --> Fase vacia
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'amistoso', @a1, @a3, NULL, @id OUTPUT; --> Fase inexistente
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', NULL, @a3, NULL, @id OUTPUT; --> Seleccion local nula
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', 999999, @a3, NULL, @id OUTPUT; --> Seleccion local inexistente
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, NULL, NULL, @id OUTPUT; --> Seleccion visitante nula
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, 999999, NULL, @id OUTPUT; --> Seleccion visitante inexistente
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a1, NULL, @id OUTPUT; --> Local y visitante iguales
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @b1, NULL, @id OUTPUT; --> Fase de grupos con selecciones de distinto grupo
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a1, @a2, NULL, @id OUTPUT; --> Duplicado: misma pareja y fase que el partido base
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a2, @a1, NULL, @id OUTPUT; --> Duplicado con local y visitante invertidos
-- EXEC torneo.partido_insertar @sb, '2026-06-15 20:00:00 -03:00', 'octavos', @a3, @b1, NULL, @id OUTPUT; --> Sede ya tiene partido ese dia
-- EXEC torneo.partido_insertar @sl, '2026-06-16 14:00:00 -03:00', 'octavos', @a1, @b1, NULL, @id OUTPUT; --> Seleccion juega a menos de 24 h
-- EXEC torneo.partido_insertar @sl, '2026-08-10 15:00:00 -03:00', 'amistoso', @a1, @a1, NULL, @id OUTPUT; --> 2 errores: fase inexistente y selecciones iguales
-- EXEC torneo.partido_insertar @sb, '2026-06-15 15:00:00 -03:00', 'grupos', @a1, @a2, NULL, @id OUTPUT; --> 3 errores: duplicado, sede ocupada y 24 h (copia exacta del partido base)
-- EXEC torneo.partido_insertar 999999, NULL, 'amistoso', 999999, @a3, NULL, @id OUTPUT; --> 4 errores: sede, fecha, fase y seleccion local
-- EXEC torneo.partido_insertar NULL, NULL, NULL, NULL, NULL, NULL, @id OUTPUT; --> 5 errores: sede, fecha, fase, local y visitante
-- EXEC torneo.partido_insertar @sb, '2026-06-15 20:00:00 -05:00', 'amistoso', 999999, 999999, '2026-06-15 17:00:00 -02:00', @id OUTPUT; --> 8 errores (maximo): huso local, UTC con desplazamiento, distinto instante, fase, local, visitante, iguales y sede ocupada
GO

-- Verificacion torneo.partido_modificar
DECLARE @a1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPA'),
        @a2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPB'),
        @a3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPC'),
        @a4 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPD'),
        @b1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZPE'),
        @sb INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Base'),
        @sm INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Mod'),
        @s5 INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Cinco'),
        @sl INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Partido Sede Libre');
-- Cada partido se busca por pareja de selecciones (sin importar el orden) + fase; los tests validos no deben cambiar pareja ni fase
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4)),
        @fin  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'octavos'       AND seleccion_local_id IN (@a1, @a3) AND seleccion_visitante_id IN (@a1, @a3)),
        @form INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a1, @a4) AND seleccion_visitante_id IN (@a1, @a4)),
        @all  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));

EXEC torneo.partido_modificar @m, @sl, '2026-06-22 15:00:00 -03:00', 'grupos', @a3, @a4; --> Valido: cambia sede y fecha (estado por defecto 'programado')
-- EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4; --> Valido: sin cambios (el propio partido no cuenta como duplicado ni sede ocupada)
-- EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a4, @a3; --> Valido: se invierten local y visitante (sin formaciones)
-- EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4, 'suspendido'; --> Valido: pasa a suspendido
-- EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4, 'programado', '2026-06-20 18:00:00 +00:00'; --> Valido: UTC informado y consistente
-- EXEC torneo.partido_modificar @m, @s5, '2026-06-20 15:00:00 -05:00', 'grupos', @a3, @a4; --> Valido: cambia a sede UTC-05
-- EXEC torneo.partido_modificar @form, @sb, '2026-07-01 15:00:00 -03:00', 'cuartos', @a1, @a4; --> Valido: se reprograma un partido con formaciones sin cambiar las selecciones
-- SELECT * FROM torneo.partido WHERE partido_id = @m; --> Ver lo modificado (UTC derivado, estado)
-- EXEC torneo.partido_modificar 999999, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4; --> Partido inexistente
-- EXEC torneo.partido_modificar NULL, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4; --> Id nulo
-- EXEC torneo.partido_modificar @m, NULL, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4; --> Sede nula
-- EXEC torneo.partido_modificar @m, 999999, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4; --> Sede inexistente
-- EXEC torneo.partido_modificar @m, @sl, NULL, 'grupos', @a3, @a4; --> Fecha local nula
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -05:00', 'grupos', @a3, @a4; --> Hora local en otro huso
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, 'programado', '2026-08-10 15:00:00 -03:00'; --> UTC informado con desplazamiento distinto de +00:00
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, 'programado', '2026-08-10 19:00:00 +00:00'; --> UTC informado que no coincide con la hora local
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', NULL, @a3, @a4; --> Fase nula
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'amistoso', @a3, @a4; --> Fase inexistente
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', NULL, @a4; --> Seleccion local nula
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', 999999, @a4; --> Seleccion local inexistente
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, NULL; --> Seleccion visitante nula
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, 999999; --> Seleccion visitante inexistente
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a3; --> Local y visitante iguales
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @b1; --> Fase de grupos con selecciones de distinto grupo
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'dieciseisavos', @a3, @a4; --> Duplicado: misma pareja y fase que el partido a eliminar
-- EXEC torneo.partido_modificar @m, @sb, '2026-06-15 20:00:00 -03:00', 'grupos', @a3, @a4; --> Sede ya tiene partido ese dia
-- EXEC torneo.partido_modificar @m, @sl, '2026-06-26 14:00:00 -03:00', 'grupos', @a3, @a4; --> Seleccion juega a menos de 24 h 
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, NULL; --> Estado nulo
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, 'finalizado'; --> Estado finalizado 
-- EXEC torneo.partido_modificar @m, @sl, '2026-08-10 15:00:00 -03:00', 'grupos', @a3, @a4, 'cancelado'; --> Estado inexistente
-- EXEC torneo.partido_modificar @fin, @sb, '2026-06-25 15:00:00 -03:00', 'octavos', @a1, @a3; --> Partido finalizado: no se puede reprogramar
-- EXEC torneo.partido_modificar @form, @sb, '2026-06-30 15:00:00 -03:00', 'cuartos', @a1, @a3; --> Con formaciones: no se puede cambiar la seleccion visitante (requiere formaciones cargadas)
-- EXEC torneo.partido_modificar @form, @sb, '2026-06-30 15:00:00 -03:00', 'cuartos', @a4, @a1; --> Con formaciones: invertir local y visitante tambien cuenta como cambio (requiere formaciones cargadas)
-- EXEC torneo.partido_modificar @all, @sb, '2026-07-25 15:00:00 -03:00', 'dieciseisavos', @a1, @a3; --> 2 errores: finalizado y formaciones (1 si no hay formaciones cargadas)
-- EXEC torneo.partido_modificar NULL, @sl, '2026-08-10 15:00:00 -03:00', 'amistoso', @a3, @a4, NULL; --> 3 errores: id obligatorio, fase y estado
-- EXEC torneo.partido_modificar NULL, NULL, NULL, NULL, NULL, NULL, NULL; --> 7 errores: id, sede, fecha, fase, local, visitante y estado
-- EXEC torneo.partido_modificar @all, @sb, '2026-06-15 20:00:00 -05:00', 'amistoso', 999999, 999999, 'cancelado', '2026-06-15 17:00:00 -02:00'; --> 11 errores (maximo): huso local, UTC con desplazamiento, distinto instante, fase, local, visitante, iguales, sede ocupada, estado, finalizado y formaciones (10 si no hay formaciones cargadas)
GO

-- Verificacion torneo.partido_eliminar
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

EXEC torneo.partido_eliminar @elim; --> Baja valida 
-- EXEC torneo.partido_eliminar 999999; --> Partido inexistente
-- EXEC torneo.partido_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC torneo.partido_eliminar @fin; --> Partido finalizado
-- EXEC torneo.partido_eliminar @form; --> Tiene formaciones cargadas (requiere formaciones en la preparacion)
-- EXEC torneo.partido_eliminar @tarj; --> Tiene tarjetas registradas (requiere tarjetas en la preparacion)
-- EXEC torneo.partido_eliminar @susp; --> Es el partido afectado por suspensiones vigentes (requiere suspensiones en la preparacion)
-- EXEC torneo.partido_eliminar @arb; --> Tiene arbitros designados (requiere designaciones en la preparacion)
-- EXEC torneo.partido_eliminar @pub; --> Tiene espacios publicitarios asignados (requiere espacios en la preparacion)
-- EXEC torneo.partido_eliminar @all; --> 6 errores (maximo): finalizado, formaciones, tarjetas, suspensiones, arbitros y publicidad (menos si falta cargar alguna dependencia)
GO

-- Limpieza de torneo.partido (al terminar; descomentar y ejecutar todo junto)
SELECT partido_id INTO #pt FROM torneo.partido
WHERE seleccion_local_id IN (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZPA', 'ZPB', 'ZPC', 'ZPD', 'ZPE')))
    OR seleccion_visitante_id IN (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZPA', 'ZPB', 'ZPC', 'ZPD', 'ZPE')));
DELETE FROM evento.suspension WHERE partido_afectado_id IN (SELECT partido_id FROM #pt);
DELETE FROM evento.tarjeta WHERE partido_id IN (SELECT partido_id FROM #pt);
DELETE FROM plantel.formacion WHERE partido_id IN (SELECT partido_id FROM #pt);
DELETE FROM arbitraje.designacion_arbitral WHERE partido_id IN (SELECT partido_id FROM #pt);
DELETE FROM publicidad.espacio_publicitario WHERE partido_id IN (SELECT partido_id FROM #pt);
DELETE FROM torneo.partido WHERE partido_id IN (SELECT partido_id FROM #pt);
DROP TABLE #pt;
DELETE FROM torneo.seleccion WHERE pais_id IN (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZPA', 'ZPB', 'ZPC', 'ZPD', 'ZPE'));
DELETE FROM torneo.sede WHERE nombre LIKE 'Test Partido%';
DELETE FROM torneo.pais WHERE codigo_iso IN ('ZPA', 'ZPB', 'ZPC', 'ZPD', 'ZPE');
GO


-- ============================================================
-- 1.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================




-- ============================================================
-- 1.7 plantel.convocatoria
-- ============================================================





-- ============================================================
-- 1.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================




-- ============================================================
-- 1.9 evento.sustitucion
-- ============================================================




-- ============================================================
-- 1.10 evento.gol (cada operación actualiza el marcador del partido en la misma transacción)
-- ============================================================





-- ============================================================
-- 1.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================




-- ============================================================
-- 1.12 arbitraje: arbitro, arbitro_idioma, designacion_arbitral e informe_arbitral
-- ============================================================





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



--Verificacion publicidad.anunciante_insertar
-- EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventas@gmail.com', @anun OUTPUT; --> Valido
-- EXEC publicidad.anunciante_insertar '', 'Empresa S.A.', 'ventas@gmail.com', @anun OUTPUT; --> Nombre vacio
-- EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventas@gmail.com', @anun OUTPUT; --> Nombre duplicado
-- EXEC publicidad.anunciante_insertar 'TEST02', 'Empresa S.A.', 'ventasgmail.com', @anun OUTPUT; --> Correo sin @
-- EXEC publicidad.anunciante_insertar 'TEST03', 'Empresa S.A.', 'ventas@@gmail.com', @anun OUTPUT; --> Dos @
-- EXEC publicidad.anunciante_insertar 'TEST01', 'Empresa S.A.', 'ventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventasventas@gmail.com', @anun OUTPUT; --> +100 caracteres
-- EXEC publicidad.anunciante_insertar 'TEST04', 'Empresa S.A.', 'ventas@gmail', @anun OUTPUT; --> Sin dominio
-- EXEC publicidad.anunciante_insertar 'TEST05', 'Empresa S.A.', 'ventas @gmail.com', @anun OUTPUT; --> Con espacios
-- EXEC publicidad.anunciante_insertar 'TEST06', 'Empresa S.A.', NULL, @anun OUTPUT; --> Sin contacto



-- Verificacion publicidad.anunciante_modificar
EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas@gmail.com'; --> Modificacion valida
-- EXEC publicidad.anunciante_modificar 1, '', 'Empresa S.A.', 'ventas@gmail.com'; --> Nombre vacio
-- EXEC publicidad.anunciante_modificar 1, 'TEST01', 'Empresa S.A.', 'ventas@gmail.com'; --> Nombre duplicado
-- EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventasgmail.com'; --> Correo sin @
-- EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas@@gmail.com'; --> Dos @
-- EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas@gmail'; --> Sin dominio
-- EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', 'ventas @gmail.com'; --> Con espacios
-- EXEC publicidad.anunciante_modificar 1, 'TEST_MOD', 'Empresa S.A.', NULL; --> Sin contacto
-- EXEC publicidad.anunciante_modificar 999999, 'TEST_MOD', 'Empresa S.A.', 'ventas@gmail.com'; --> ID inexistente y ya existe anunciante con ese nomb



-- Verificacion publicidad.anunciante_eliminar
-- LAS CUATRO SIGUIENTES LINEAS SE EJECUTAN UNA SOLA VEZ: 
EXEC publicidad.anunciante_insertar 'ELIM_OK', NULL, NULL;
EXEC publicidad.anunciante_insertar 'ELIM_CON_CAMP', NULL, NULL;
INSERT INTO publicidad.campania (anunciante_id, nombre, fecha_inicio, fecha_fin)
SELECT anunciante_id, 'Camp de prueba', '2026-06-01', '2026-06-30' FROM publicidad.anunciante WHERE nombre = 'ELIM_CON_CAMP';

DECLARE @elim_ok INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'ELIM_OK'),
        @elim_con INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'ELIM_CON_CAMP');
EXEC publicidad.anunciante_eliminar @elim_ok; --> Baja valida (SI LE DAS DOS VECES TE DICE ID inexistente *ya se elimino*)
-- EXEC publicidad.anunciante_eliminar 999999; --> ID inexistente
-- EXEC publicidad.anunciante_eliminar NULL; --> ID nulo
-- EXEC publicidad.anunciante_eliminar @elim_con; --> Tiene campañas registradas

-- Limpieza de publicidad.anunciante
DELETE FROM publicidad.anunciante
WHERE nombre IN (
    'TEST01',
    'TEST02',
    'TEST03',
    'TEST04',
    'TEST05',
    'TEST06',
    'TEST_MOD',
    'ELIM_OK',
    'ELIM_CON_CAMP'
);


-- Verificacion publicidad.campania_insertar
-- LAS DOS SIGUIENTES LINEAS SE EJECUTAN UNA SOLA VEZ: 
EXEC publicidad.anunciante_insertar 'CAMP_A', NULL, NULL;
EXEC publicidad.anunciante_insertar 'CAMP_B', NULL, NULL;

DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_A'),
        @b INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CAMP_B'),
        @camp INT;

EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Valido
-- EXEC publicidad.campania_insertar @a, 'Camp Un Dia', '2026-06-10', '2026-06-10', @camp OUTPUT; --> Valido: fecha fin = fecha inicio
-- EXEC publicidad.campania_insertar @b, 'Camp Test', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Valido: mismo nombre en otro anunciante
-- EXEC publicidad.campania_insertar @a, '  Camp Espacios  ', '2026-06-01', '2026-06-30', @camp OUTPUT; --> Valido: se guarda sin espacios
-- EXEC publicidad.campania_insertar 999999, 'X1', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Anunciante inexistente
-- EXEC publicidad.campania_insertar NULL, 'X2', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Anunciante nulo
-- EXEC publicidad.campania_insertar @a, '', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Nombre vacio
-- EXEC publicidad.campania_insertar @a, NULL, '2026-06-01', '2026-07-19', @camp OUTPUT; --> Nombre nulo
-- EXEC publicidad.campania_insertar @a, '   ', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Nombre solo espacios
-- EXEC publicidad.campania_insertar @a, 'X3', NULL, '2026-07-19', @camp OUTPUT; --> Fecha inicio nula
-- EXEC publicidad.campania_insertar @a, 'X4', '2026-06-01', NULL, @camp OUTPUT; --> Fecha fin nula
-- EXEC publicidad.campania_insertar @a, 'X5', NULL, NULL, @camp OUTPUT; --> Ambas fechas nulas (un solo mensaje)
-- EXEC publicidad.campania_insertar @a, 'X6', '2026-07-01', '2026-06-01', @camp OUTPUT; --> Fin anterior al inicio
-- EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Nombre duplicado (mismo anunciante)
-- EXEC publicidad.campania_insertar @a, 'CAMP TEST', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Nombre duplicado con otra capitalizacion
-- EXEC publicidad.campania_insertar @a, 'Camp Test   ', '2026-06-01', '2026-07-19', @camp OUTPUT; --> Nombre duplicado con espacios al final
-- EXEC publicidad.campania_insertar 999999, '', '2026-07-01', '2026-06-01', @camp OUTPUT; --> 3 errores: anunciante inexistente, nombre vacio, fin anterior al inicio
-- EXEC publicidad.campania_insertar @a, 'Camp Test', '2026-07-01', '2026-06-01', @camp OUTPUT; --> 2 errores: nombre duplicado y fin anterior al inicio
-- EXEC publicidad.campania_insertar NULL, NULL, NULL, NULL, @camp OUTPUT; --> 3 errores: anunciante, nombre y fechas



-- Verificacion publicidad.campania_modificar
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

DECLARE @a INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_A'),
        @b INT = (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre = 'CMOD_B'),
        @c1 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Mod'),
        @c3 INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'),
        @f DATE = (SELECT TOP 1 CAST(p.fecha_hora_utc AS DATE) FROM publicidad.espacio_publicitario e JOIN torneo.partido p ON p.partido_id = e.partido_id
                   JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
                   WHERE pz.campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Camp Con Espacio'));
DECLARE @f_m10 DATE = DATEADD(DAY, -10, @f), @f_m1 DATE = DATEADD(DAY, -1, @f),
        @f_p1  DATE = DATEADD(DAY, 1, @f),   @f_p10 DATE = DATEADD(DAY, 10, @f);

EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', '2026-06-05', '2026-07-10'; --> Valido: cambia fechas, mismo nombre propio (no es duplicado)
-- EXEC publicidad.campania_modificar @c1, @b, 'Camp Mod', '2026-06-05', '2026-07-10'; --> Valido: cambia de anunciante (despues volver a @a)
-- EXEC publicidad.campania_modificar @c1, @a, '  Camp Mod  ', '2026-06-10', '2026-06-10'; --> Valido: nombre con espacios (se guarda recortado) y fin = inicio
-- EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_m10, @f_p10; --> Valido: amplia la vigencia, el partido sigue cubierto
-- EXEC publicidad.campania_modificar 999999, @a, 'X1', '2026-06-01', '2026-07-19'; --> Campaña inexistente
-- EXEC publicidad.campania_modificar NULL, @a, 'X2', '2026-06-01', '2026-07-19'; --> Id nulo (1 condicion: el id es obligatorio)
-- EXEC publicidad.campania_modificar @c1, 999999, 'Camp Mod', '2026-06-01', '2026-07-19'; --> Anunciante inexistente
-- EXEC publicidad.campania_modificar @c1, NULL, 'Camp Mod', '2026-06-01', '2026-07-19'; --> Anunciante nulo
-- EXEC publicidad.campania_modificar @c1, @a, '', '2026-06-01', '2026-07-19'; --> Nombre vacio
-- EXEC publicidad.campania_modificar @c1, @a, NULL, '2026-06-01', '2026-07-19'; --> Nombre nulo
-- EXEC publicidad.campania_modificar @c1, @a, '   ', '2026-06-01', '2026-07-19'; --> Nombre solo espacios
-- EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', NULL, '2026-07-19'; --> Fecha inicio nula
-- EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', '2026-06-01', NULL; --> Fecha fin nula
-- EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', NULL, NULL; --> Ambas fechas nulas (un solo mensaje)
-- EXEC publicidad.campania_modificar @c1, @a, 'Camp Mod', '2026-07-01', '2026-06-01'; --> Fin anterior al inicio
-- EXEC publicidad.campania_modificar @c1, @a, 'Camp Otra', '2026-06-01', '2026-07-19'; --> Nombre duplicado (otra campaña del mismo anunciante)
-- EXEC publicidad.campania_modificar @c1, @a, 'CAMP OTRA', '2026-06-01', '2026-07-19'; --> Duplicado con otra capitalizacion
-- EXEC publicidad.campania_modificar @c1, @a, 'Camp Otra   ', '2026-06-01', '2026-07-19'; --> Duplicado con espacios al final
-- EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_p1, @f_p10; --> Vigencia deja afuera el partido con pieza asignada (inicio posterior al partido)
-- EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_m10, @f_m1; --> Vigencia deja afuera el partido con pieza asignada (fin anterior al partido)
-- EXEC publicidad.campania_modificar @c3, @a, 'Camp Con Espacio', @f_p1, @f_m1; --> 2 errores: fin anterior al inicio y vigencia que deja afuera el partido
-- EXEC publicidad.campania_modificar 999999, 999999, '', '2026-07-01', '2026-06-01'; --> 4 errores: campaña inexistente, anunciante inexistente, nombre vacio, fin anterior al inicio
-- EXEC publicidad.campania_modificar NULL, NULL, NULL, NULL, NULL; --> 4 errores: id obligatorio, anunciante inexistente, nombre vacio, fechas obligatorias
-- EXEC publicidad.campania_modificar @c1, @a, 'Camp Otra', '2026-07-01', '2026-06-01'; --> 2 errores: nombre duplicado y fin anterior al inicio



-- Verificacion publicidad.campania_eliminar
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

DECLARE @ok INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim OK'),
        @con INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim Con Pieza');

EXEC publicidad.campania_eliminar @ok; --> Baja valida: elimina la campaña y sus paises de interes, si se ejecuta dos veces seguidas tira error de inexistente
-- EXEC publicidad.campania_eliminar 999999; --> Campaña inexistente
-- EXEC publicidad.campania_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC publicidad.campania_eliminar @con; --> Tiene piezas publicitarias registradas

-- Limpieza de publicidad.campania
DELETE FROM publicidad.campania WHERE anunciante_id IN (SELECT anunciante_id FROM publicidad.anunciante WHERE nombre IN ('CAMP_A', 'CAMP_B', 'ELIM_CON_CAMP'));
DELETE FROM publicidad.anunciante WHERE nombre IN ('CAMP_A', 'CAMP_B', 'ELIM_OK', 'ELIM_CON_CAMP');
DELETE e FROM publicidad.espacio_publicitario e JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id JOIN publicidad.campania c ON c.campania_id = pz.campania_id JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id WHERE a.nombre IN ('CMOD_A', 'CMOD_B');
DELETE pz FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id WHERE a.nombre IN ('CMOD_A', 'CMOD_B');
DELETE i FROM publicidad.campania_pais_interes i JOIN publicidad.campania c ON c.campania_id = i.campania_id JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id WHERE a.nombre IN ('CMOD_A', 'CMOD_B');
DELETE c FROM publicidad.campania c JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id WHERE a.nombre IN ('CMOD_A', 'CMOD_B');
DELETE FROM publicidad.anunciante WHERE nombre IN ('CMOD_A', 'CMOD_B');
DELETE pz FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre = 'Elim Con Pieza';
DELETE i FROM publicidad.campania_pais_interes i JOIN publicidad.campania c ON c.campania_id = i.campania_id WHERE c.nombre = 'Elim Con Pieza';
DELETE FROM publicidad.campania WHERE nombre IN ('Elim OK', 'Elim Con Pieza');
DELETE FROM publicidad.anunciante WHERE nombre = 'CELIM';


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

-- Verificacion publicidad.campania_pais_interes_insertar
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_INS'),
        @co INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_OTRA'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY);

EXEC publicidad.campania_pais_interes_insertar @ci, @p2; --> Valido
-- EXEC publicidad.campania_pais_interes_insertar @co, @p1; --> Valido: el mismo pais en otra campaña
-- EXEC publicidad.campania_pais_interes_insertar 999999, @p2; --> Campaña inexistente
-- EXEC publicidad.campania_pais_interes_insertar NULL, @p2; --> Campaña nula
-- EXEC publicidad.campania_pais_interes_insertar @ci, 999999; --> Pais inexistente
-- EXEC publicidad.campania_pais_interes_insertar @ci, NULL; --> Pais nulo
-- EXEC publicidad.campania_pais_interes_insertar @ci, @p1; --> Ya figura 
-- EXEC publicidad.campania_pais_interes_insertar 999999, 999999; --> 2 errores: campaña inexistente y pais 
-- EXEC publicidad.campania_pais_interes_insertar NULL, NULL; --> 2 errores: campaña nula y pais nulo



-- Verificacion publicidad.campania_pais_interes_modificar
DECLARE @cm INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_MOD'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p3 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @p5 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 4 ROWS FETCH NEXT 1 ROWS ONLY);

EXEC publicidad.campania_pais_interes_modificar @cm, @p2, @p4; --> Valido: reemplaza p2 por p4 
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p4, @p2; --> Restaurar: volver p4 a p2 
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p3, @p3; --> Valido: mismo pais
-- EXEC publicidad.campania_pais_interes_modificar 999999, @p2, @p4; --> Campaña inexistente
-- EXEC publicidad.campania_pais_interes_modificar NULL, @p2, @p4; --> Campaña nula
-- EXEC publicidad.campania_pais_interes_modificar @cm, 999999, @p4; --> Pais a reemplazar inexistente (el par no figura)
-- EXEC publicidad.campania_pais_interes_modificar @cm, NULL, @p4; --> Pais a reemplazar nulo
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p4, @p5; --> El pais a reemplazar existe pero no figura en la campaña
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p2, 999999; --> Pais nuevo inexistente
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p2, NULL; --> Pais nuevo nulo
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p2, @p3; --> Pais nuevo ya figura en la campaña
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p1, @p4; --> La campaña tiene piezas dirigidas al pais a reemplazar (p1)
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p1, @p3; --> 2 errores: pais nuevo ya figura y hay piezas dirigidas a p1
-- EXEC publicidad.campania_pais_interes_modificar @cm, @p4, 999999; --> 2 errores: el par no figura y pais nuevo inexistente
-- EXEC publicidad.campania_pais_interes_modificar 999999, 999999, NULL; --> 2 errores: el par no figura y pais nuevo nulo

-- Verificacion publicidad.campania_pais_interes_eliminar
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'CPI_ELIM'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY);

EXEC publicidad.campania_pais_interes_eliminar @ce, @p2; --> Baja valida (si se ejecuta 2 veces tira error)
-- EXEC publicidad.campania_pais_interes_eliminar @ce, @p4; --> El pais no figura en la campaña
-- EXEC publicidad.campania_pais_interes_eliminar 999999, @p2; --> Campaña inexistente (el par no figura)
-- EXEC publicidad.campania_pais_interes_eliminar NULL, @p2; --> Campaña nula
-- EXEC publicidad.campania_pais_interes_eliminar @ce, 999999; --> Pais inexistente (el par no figura)
-- EXEC publicidad.campania_pais_interes_eliminar @ce, NULL; --> Pais nulo
-- EXEC publicidad.campania_pais_interes_eliminar @ce, @p1; --> La campaña tiene piezas dirigidas a ese pais
-- EXEC publicidad.campania_pais_interes_eliminar 999999, 999999; --> 1 error: el par no figura (las dos condiciones son excluyentes)


-- Limpieza de campania_pais_interes_* (al terminar)
DELETE pz FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre LIKE 'CPI[_]%';
DELETE i FROM publicidad.campania_pais_interes i JOIN publicidad.campania c ON c.campania_id = i.campania_id WHERE c.nombre LIKE 'CPI[_]%';
DELETE FROM publicidad.campania WHERE nombre LIKE 'CPI[_]%';
DELETE FROM publicidad.anunciante WHERE nombre = 'CPI';



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

-- Verificacion publicidad.pieza_publicitaria_insertar
DECLARE @ci INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_INS'),
        @co INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_OTRA'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @p2 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY),
        @p4 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 3 ROWS FETCH NEXT 1 ROWS ONLY),
        @pz INT;

EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p1, 500, @pz OUTPUT; --> Valido
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'espanol', @p2, 800, @pz OUTPUT; --> Valido: mismo idioma, otro mercado
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'frances', @p1, 0, @pz OUTPUT; --> Valido: tarifa 0 
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'ALEMAN', @p1, 700, @pz OUTPUT; --> Valido: se guarda en minusculas
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'abcdefghij', @p2, 100, @pz OUTPUT; --> Valido: idioma de 10 letras 
-- EXEC publicidad.pieza_publicitaria_insertar @co, 'espanol', @p1, 1000, @pz OUTPUT; --> Valido: mismo idioma y mercado que la base, en otra campaña
-- EXEC publicidad.pieza_publicitaria_insertar 999999, 'ingles', @p1, 500, @pz OUTPUT; --> Campaña inexistente
-- EXEC publicidad.pieza_publicitaria_insertar NULL, 'ingles', @p1, 500, @pz OUTPUT; --> Campaña nula
-- EXEC publicidad.pieza_publicitaria_insertar @ci, '', @p1, 500, @pz OUTPUT; --> Idioma vacio
-- EXEC publicidad.pieza_publicitaria_insertar @ci, NULL, @p1, 500, @pz OUTPUT; --> Idioma nulo
-- EXEC publicidad.pieza_publicitaria_insertar @ci, '   ', @p1, 500, @pz OUTPUT; --> Idioma solo espacios
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingl3s', @p1, 500, @pz OUTPUT; --> Idioma con numero
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles uk', @p1, 500, @pz OUTPUT; --> Idioma con espacio
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'abcdefghijk', @p1, 500, @pz OUTPUT; --> Idioma de 11 letras 
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', 999999, 500, @pz OUTPUT; --> Pais mercado inexistente
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', NULL, 500, @pz OUTPUT; --> Pais mercado nulo
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p4, 500, @pz OUTPUT; --> Pais mercado que no es de interes de la campaña
-- EXEC publicidad.pieza_publicitaria_insertar @co, 'ingles', @p2, 500, @pz OUTPUT; --> Pais mercado de interes de OTRA campaña, no de esta
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p2, NULL, @pz OUTPUT; --> Tarifa nula
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'ingles', @p2, -1, @pz OUTPUT; --> Tarifa negativa
-- EXEC publicidad.pieza_publicitaria_insertar @ci, 'espanol', @p1, 1000, @pz OUTPUT; --> Duplicado: la campaña ya tiene 'espanol' para ese mercado
-- EXEC publicidad.pieza_publicitaria_insertar 999999, '', @p1, -1, @pz OUTPUT; --> 3 errores: campaña inexistente, idioma vacio, tarifa negativa
-- EXEC publicidad.pieza_publicitaria_insertar NULL, NULL, NULL, NULL, @pz OUTPUT; --> 4 errores: campaña nula, idioma nulo, pais nulo, tarifa nula


-- Verificacion publicidad.pieza_publicitaria_modificar
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

EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, 1500; --> Valido: cambia la tarifa (no es duplicado de si misma)
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'INGLES', @p1, 1000; --> Valido: idioma en mayusculas, se guarda en minusculas
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'italiano', @p1, 1000; --> Valido: cambia el idioma
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p2, 1000; --> Valido: cambia el mercado, sin espacios asignados 
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @cd, 'ingles', @p1, 1000; --> Valido: cambia de campaña, sin espacios asignados
-- EXEC publicidad.pieza_publicitaria_modificar @m3, @c1, 'aleman', @p3, 3500; --> Valido: pieza con espacio, solo cambia la tarifa
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, 1000; --> Restaurar: deja m1 como estaba
-- EXEC publicidad.pieza_publicitaria_modificar 999999, @c1, 'ingles', @p1, 1000; --> Pieza inexistente
-- EXEC publicidad.pieza_publicitaria_modificar NULL, @c1, 'ingles', @p1, 1000; --> Id nulo 
-- EXEC publicidad.pieza_publicitaria_modificar @m1, 999999, 'ingles', @p1, 1000; --> Campaña inexistente
-- EXEC publicidad.pieza_publicitaria_modificar @m1, NULL, 'ingles', @p1, 1000; --> Campaña nula
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, '', @p1, 1000; --> Idioma vacio
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, NULL, @p1, 1000; --> Idioma nulo
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, '   ', @p1, 1000; --> Idioma solo espacios
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingl3s', @p1, 1000; --> Idioma con numero
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles uk', @p1, 1000; --> Idioma con espacio
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'abcdefghijk', @p1, 1000; --> Idioma de 11 letras 
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', 999999, 1000; --> Pais mercado inexistente
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', NULL, 1000; --> Pais mercado nulo
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p4, 1000; --> Pais mercado que no es de interes de la campaña
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @cd, 'ingles', @p2, 1000; --> Mercado @p2 no es de interes de la campaña destino
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, NULL; --> Tarifa nula
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingles', @p1, -1; --> Tarifa negativa
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'frances', @p2, 1000; --> Duplicado: m2 ya es 'frances' en ese mercado
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'FRANCES', @p2, 1000; --> Duplicado con otra capitalizacion 
-- EXEC publicidad.pieza_publicitaria_modificar @m3, @c1, 'aleman', @p2, 3000; --> Pieza con espacio: no puede cambiar de mercado
-- EXEC publicidad.pieza_publicitaria_modificar @m3, @cd, 'aleman', @p3, 3000; --> Pieza con espacio: no puede cambiar de campaña
-- EXEC publicidad.pieza_publicitaria_modificar @m3, @cd, 'aleman', @p3, -1; --> 2 errores: pieza con espacio cambia de campaña y tarifa negativa
-- EXEC publicidad.pieza_publicitaria_modificar @m1, @c1, 'ingl3s', @p4, -1; --> 3 errores: idioma invalido, mercado que no es de interes, tarifa negativa
-- EXEC publicidad.pieza_publicitaria_modificar 999999, 999999, '', 999999, -1; --> 5 errores: pieza, campaña, idioma, pais inexistentes y tarifa negativa

-- Verificacion publicidad.pieza_publicitaria_eliminar
DECLARE @ce INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM'),
        @p1 INT = (SELECT pais_id FROM torneo.pais ORDER BY pais_id OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY),
        @e1 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM') AND idioma = 'espanol'),
        @e2 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'PZ_ELIM') AND idioma = 'ingles'),
        @pz INT;

EXEC publicidad.pieza_publicitaria_eliminar @e1; --> Baja valida (si se ejecuta 2 veces seguidas tira error)
-- EXEC publicidad.pieza_publicitaria_eliminar 999999; --> Pieza inexistente
-- EXEC publicidad.pieza_publicitaria_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC publicidad.pieza_publicitaria_eliminar @e2; --> Esta asignada a espacios publicitarios de partidos


-- Limpieza de publicidad.pieza_publicitaria (al terminar)
DELETE e FROM publicidad.espacio_publicitario e JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre LIKE 'PZ[_]%';
DELETE pz FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre LIKE 'PZ[_]%';
DELETE i FROM publicidad.campania_pais_interes i JOIN publicidad.campania c ON c.campania_id = i.campania_id WHERE c.nombre LIKE 'PZ[_]%';
DELETE FROM publicidad.campania WHERE nombre LIKE 'PZ[_]%';
DELETE FROM publicidad.anunciante WHERE nombre = 'PZ';
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

-- Verificacion publicidad.espacio_publicitario_insertar
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

EXEC publicidad.espacio_publicitario_insertar @pb, 1, @z7, 1, @esp OUTPUT; --> Valido: con pieza y prioridad 1 
-- EXEC publicidad.espacio_publicitario_insertar @pb, 2, @z1, 4, @esp OUTPUT; --> Valido: pieza que ya esta en otro partido (PA), prioridad 4 (borde)
-- EXEC publicidad.espacio_publicitario_insertar @pb, 3, NULL, NULL, @esp OUTPUT; --> Valido: espacio vacio (sin pieza ni prioridad)
-- EXEC publicidad.espacio_publicitario_insertar 999999, 1, NULL, NULL, @esp OUTPUT; --> Partido inexistente
-- EXEC publicidad.espacio_publicitario_insertar NULL, 1, NULL, NULL, @esp OUTPUT; --> Partido nulo
-- EXEC publicidad.espacio_publicitario_insertar @pa, 0, NULL, NULL, @esp OUTPUT; --> Numero de espacio 0 (fuera de rango)
-- EXEC publicidad.espacio_publicitario_insertar @pa, 5, NULL, NULL, @esp OUTPUT; --> Numero de espacio 5 (fuera de rango)
-- EXEC publicidad.espacio_publicitario_insertar @pa, NULL, NULL, NULL, @esp OUTPUT; --> Numero de espacio nulo
-- EXEC publicidad.espacio_publicitario_insertar @pa, 1, NULL, NULL, @esp OUTPUT; --> Espacio duplicado
-- EXEC publicidad.espacio_publicitario_insertar @pa, 2, NULL, 0, @esp OUTPUT; --> Prioridad 0 (fuera de rango)
-- EXEC publicidad.espacio_publicitario_insertar @pa, 2, NULL, 5, @esp OUTPUT; --> Prioridad 5 (fuera de rango)
-- EXEC publicidad.espacio_publicitario_insertar @pa, 2, 999999, NULL, @esp OUTPUT; --> Pieza inexistente
-- EXEC publicidad.espacio_publicitario_insertar @pa, 2, @zf, NULL, @esp OUTPUT; --> Campaña de la pieza no vigente en la fecha del partido
-- EXEC publicidad.espacio_publicitario_insertar @pa, 2, @z1, NULL, @esp OUTPUT; --> La pieza ya ocupa otro espacio del mismo partido 
-- EXEC publicidad.espacio_publicitario_insertar @pa, 1, @z1, NULL, @esp OUTPUT; --> 2 errores: espacio duplicado y pieza ya ocupa otro espacio
-- EXEC publicidad.espacio_publicitario_insertar @pa, 0, 999999, 9, @esp OUTPUT; --> 3 errores: numero fuera de rango, prioridad fuera de rango y pieza inexistente
-- EXEC publicidad.espacio_publicitario_insertar 999999, 7, 999999, 9, @esp OUTPUT; --> 4 errores: partido inexistente, numero, prioridad y pieza inexistente



-- Verificacion publicidad.espacio_publicitario_modificar
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

EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 3; --> Valido: cambia la prioridad y conserva la pieza
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z7, 1; --> Valido: cambia la pieza (despues restaurar)
-- EXEC publicidad.espacio_publicitario_modificar @m1, NULL, NULL; --> Valido: deja el espacio vacio (despues restaurar)
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 2, @fx; --> Valido: informa fecha de exhibicion sin facturar
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, NULL; --> Valido: facturado NULL se toma como 0
-- EXEC publicidad.espacio_publicitario_modificar @ef, @z3, NULL, @fx, 1, 20000; --> Valido: espacio ya facturado, misma pieza, cambia el monto
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, 0, NULL; --> Restaurar: deja m1 como estaba
-- EXEC publicidad.espacio_publicitario_modificar 999999, @z2, NULL; --> Espacio inexistente
-- EXEC publicidad.espacio_publicitario_modificar NULL, @z2, NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC publicidad.espacio_publicitario_modificar @m1, 999999, NULL; --> Pieza inexistente
-- EXEC publicidad.espacio_publicitario_modificar @m1, @zf, NULL; --> Campaña de la pieza no vigente en la fecha del partido
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z3, NULL; --> La pieza ya ocupa otro espacio del partido
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 0; --> Prioridad 0 (fuera de rango)
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, 5; --> Prioridad 5 (fuera de rango)
-- EXEC publicidad.espacio_publicitario_modificar @ef, @z7, NULL, @fx, 1, 10000; --> Espacio ya facturado: no se puede cambiar la pieza
-- EXEC publicidad.espacio_publicitario_modificar @m1, NULL, NULL, NULL, 1, NULL; --> Facturado sin pieza, fecha ni monto (un solo mensaje)
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, 1, 100; --> Facturado sin fecha de exhibicion
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, @fx, 1, NULL; --> Facturado sin monto
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, @fx, 0, 100; --> Monto informado con facturado = 0
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, NULL, NULL, 100; --> Monto informado con facturado NULL
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, @fx, 1, -1; --> Monto negativo (con facturado completo)
-- EXEC publicidad.espacio_publicitario_modificar @m1, NULL, NULL, @fx; --> Fecha de exhibicion en un espacio sin pieza
-- EXEC publicidad.espacio_publicitario_modificar 999999, NULL, 9, @fx; --> 2 errores: espacio inexistente y fecha sin pieza (la prioridad no se valida si el espacio no existe)
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z3, 0; --> 2 errores: pieza ya ocupa otro espacio y prioridad fuera de rango
-- EXEC publicidad.espacio_publicitario_modificar @m1, @z2, NULL, @fx, 0, -1; --> 2 errores: monto con facturado = 0 y monto negativo
-- EXEC publicidad.espacio_publicitario_modificar @m1, 999999, 0, @fx, 1, -1; --> 3 errores: pieza inexistente, prioridad fuera de rango y monto negativo
-- EXEC publicidad.espacio_publicitario_modificar @m1, NULL, 9, @fx, 1, -1; --> 4 errores: prioridad, facturado sin pieza, monto negativo y fecha sin pieza
-- EXEC publicidad.espacio_publicitario_modificar @mf, @z4, 1, @fx, 1, 5000; --> Valido: marca facturado.



-- Verificacion publicidad.espacio_publicitario_eliminar
DECLARE @vig INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'ESP_VIG');
DECLARE @z3 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'frances'),
        @z5 INT = (SELECT pieza_id FROM publicidad.pieza_publicitaria WHERE campania_id = @vig AND idioma = 'japones');
DECLARE @pc INT = (SELECT partido_id FROM publicidad.espacio_publicitario WHERE pieza_id = @z3);
DECLARE @e1 INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 4),
        @ef INT = (SELECT espacio_id FROM publicidad.espacio_publicitario WHERE partido_id = @pc AND numero_espacio = 2),
        @esp INT;

EXEC publicidad.espacio_publicitario_eliminar @e1; --> Baja valida (espacio no facturado) SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR
-- EXEC publicidad.espacio_publicitario_eliminar 999999; --> Espacio inexistente
-- EXEC publicidad.espacio_publicitario_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC publicidad.espacio_publicitario_eliminar @ef; --> Espacio ya facturado (historial de facturacion)



-- Limpieza de publicidad.espacio_publicitario (al terminar)
DELETE e FROM publicidad.espacio_publicitario e WHERE e.partido_id IN (SELECT e2.partido_id FROM publicidad.espacio_publicitario e2 JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e2.pieza_id JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('ESP_VIG', 'ESP_FUERA'));
DELETE pz FROM publicidad.pieza_publicitaria pz JOIN publicidad.campania c ON c.campania_id = pz.campania_id WHERE c.nombre IN ('ESP_VIG', 'ESP_FUERA');
DELETE i FROM publicidad.campania_pais_interes i JOIN publicidad.campania c ON c.campania_id = i.campania_id WHERE c.nombre IN ('ESP_VIG', 'ESP_FUERA');
DELETE FROM publicidad.campania WHERE nombre IN ('ESP_VIG', 'ESP_FUERA');
DELETE FROM publicidad.anunciante WHERE nombre = 'ESP';
GO

-- ============================================================
-- 2.1 plantel.reemplazar_convocado (baja + alta de último momento, en una transacción)
-- ============================================================





-- ============================================================
-- 2.2 plantel.cargar_formacion (cabecera + titulares + banco, todo o nada)
-- ============================================================





-- ============================================================
-- 2.3 evento.registrar_sustitucion (por dorsales; ventana automática; reglamento de cambios)
-- ============================================================





-- ============================================================
-- 2.4 evento.registrar_gol (por dorsales; actualiza el marcador)
-- ============================================================





-- ============================================================
-- 2.5 evento.registrar_tarjeta (tarjeta + cálculo de suspensión en una transacción)
-- ============================================================





-- ============================================================
-- 2.6 publicidad.asignar_espacios_partido (los cuatro espacios según los criterios de la sección H)
-- ============================================================





-- ============================================================
-- 2.7 torneo.registrar_resultado (cierre del partido + pauta exhibida) y facturación
-- ============================================================





-- ============================================================
-- 2.8 Acumulación de amarillas, doble amarilla y jugador suspendido fuera de la formación
-- ============================================================




-- ============================================================
-- 2.9 arbitraje.designar_arbitros (terna completa, con validación de conflicto de nacionalidad)
-- ============================================================





-- ============================================================
-- 2.10 Partido de eliminación directa completo (P4: Francia vs Japón, dieciseisavos)
-- ============================================================





-- ============================================================
-- 2.11 Transaccionalidad: todo o nada en operaciones que afectan varias tablas
-- ============================================================