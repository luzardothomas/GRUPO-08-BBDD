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

-- =======================================================================================================
--                                          VALIDACION
-- =======================================================================================================

-- ============================================================
-- 1.1 torneo.parametro
-- ============================================================
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
-- EXEC torneo.parametro_insertar 'tst_ins', 1, 'Desc'; --> Clave duplicada
-- EXEC torneo.parametro_insertar 'TST_INS', 1, 'Desc'; --> Duplicada con otra capitalizacion
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
-- EXEC torneo.parametro_eliminar 'convocatoria_min_jugadores'; 
-- EXEC torneo.parametro_eliminar 'convocatoria_max_jugadores'; 
-- EXEC torneo.parametro_eliminar 'formacion_titulares';
-- EXEC torneo.parametro_eliminar 'formacion_max_suplentes';
-- EXEC torneo.parametro_eliminar 'cambios_max_reglamentarios';
-- EXEC torneo.parametro_eliminar 'ventanas_max_reglamentarias'; 
-- EXEC torneo.parametro_eliminar 'cambios_extra_alargue'; 
-- EXEC torneo.parametro_eliminar 'ventanas_extra_alargue'; 
-- EXEC torneo.parametro_eliminar 'suspension_partidos_roja';
-- EXEC torneo.parametro_eliminar 'prime_time_hora_desde'; 
-- EXEC torneo.parametro_eliminar 'prime_time_hora_hasta'; 
GO

-- ============================================================
-- 1.2 torneo.pais y torneo.confederacion
-- ============================================================
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
-- SET @e = ''; EXEC torneo.pais_validar NULL, ' ZZ', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO con espacio al inicio
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZ ', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO con espacio al final 
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'ZZI', 'Test Validar', 'UTC-03', 100, @e OUTPUT;   --> ISO duplicado 
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
-- SET @e = ''; EXEC torneo.pais_validar 999999, 'AB', '', 'UTC3', -1, @e OUTPUT;   --> 5 errores: pais inexistente, ISO, nombre, huso y PBI
-- SET @e = ''; EXEC torneo.pais_validar NULL, 'AB', '', 'UTC3', -1, @e OUTPUT;   --> 4 errores: ISO, nombre, huso y PBI
-- SET @e = ''; EXEC torneo.pais_validar NULL, NULL, NULL, NULL, NULL, @e OUTPUT;   --> 3 errores: ISO, nombre y huso 
GO

-- Verificacion torneo.pais_insertar
DECLARE @id INT, @n80 VARCHAR(80) = REPLICATE('N', 80);
EXEC torneo.pais_insertar 'ZZA', 'Test Alta', 'UTC-03', 1500.75, @id OUTPUT; SELECT @id AS pais_id_generado; --> Valido: devuelve el id generado
-- EXEC torneo.pais_insertar 'ZZD', 'Test PBI Cero', 'UTC-03', 0, @id OUTPUT; --> Valido: PBI 0
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
-- EXEC torneo.pais_insertar 'zzi', 'Test', 'UTC-03', 10, @id OUTPUT; --> ISO duplicado con otra capitalizacion
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
-- EXEC torneo.pais_insertar NULL, NULL, NULL, NULL, @id OUTPUT; --> 3 errores: ISO, nombre y huso 
-- EXEC torneo.pais_insertar 'AB', '', 'UTC3', -1, @id OUTPUT; --> 4 errores: ISO, nombre, huso y PBI
GO

-- Verificacion torneo.pais_modificar
DECLARE @m INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso IN ('ZZM', 'ZZX')),
        @n80 VARCHAR(80) = REPLICATE('N', 80);

EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificado', 'UTC-04', 2500; --> Valido
-- EXEC torneo.pais_modificar @m, 'ZZM', @n80, 'UTC-03', 2000; --> Valido: nombre de 80 caracteres (borde)
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC+14', 0; --> Valido: huso UTC+14 y PBI 0 (bordes)
-- EXEC torneo.pais_modificar @m, 'ZZM', 'Test Modificar', 'UTC-03'; --> Valido: sin PBI, lo deja en NULL
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
-- EXEC torneo.pais_modificar @m, 'zzn', 'Test', 'UTC-03', 10; --> ISO duplicado con otra capitalizacion
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
-- EXEC torneo.pais_modificar 999999, 'AB', '', 'UTC3', -1; --> 5 errores: pais inexistente, ISO, nombre, huso y PBI

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
-- EXEC torneo.pais_eliminar NULL; --> Id nulo (el mensaje dice (nulo))
-- EXEC torneo.pais_eliminar @s; --> Tiene sedes asociadas
-- EXEC torneo.pais_eliminar @l; --> Tiene una seleccion participante
-- EXEC torneo.pais_eliminar @r; --> Tiene arbitros registrados
-- EXEC torneo.pais_eliminar @c; --> Es pais de interes de campañas publicitarias
-- EXEC torneo.pais_eliminar @p; --> 2 errores: pais de interes y mercado de piezas
-- EXEC torneo.pais_eliminar @t; --> 5 errores: sedes, seleccion, arbitros, interes de campañas y mercado de piezas


-- Verificacion torneo.confederacion_insertar
DECLARE @id INT;

-- EXEC torneo.confederacion_insertar 'OFC', @id OUTPUT; SELECT @id AS confederacion_id_generado; --> Valido: devuelve el id generado
-- EXEC torneo.confederacion_insertar 'CAF', @id OUTPUT; --> Valido: otra confederacion libre
-- EXEC torneo.confederacion_insertar 'CONCACAF', @id OUTPUT; --> Valido: la mas larga de la lista 
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
-- EXEC torneo.confederacion_insertar 'afc', @id OUTPUT; --> Duplicada con otra capitalizacion 
-- EXEC torneo.confederacion_insertar 'AFC ', @id OUTPUT; --> Duplicada con espacio al final 

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
GO

-- Verificacion torneo.confederacion_eliminar
DECLARE @a INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'AFC'),
        @c INT = (SELECT confederacion_id FROM torneo.confederacion WHERE nombre = 'CONMEBOL');

EXEC torneo.confederacion_eliminar @a; --> Baja valida (sin selecciones)
-- EXEC torneo.confederacion_eliminar 999999; --> Confederacion inexistente
-- EXEC torneo.confederacion_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC torneo.confederacion_eliminar @c; --> Tiene selecciones afiliadas
GO

-- ============================================================
-- 1.3 torneo.sede
-- ============================================================
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
GO;

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
GO;
-- Verificacion torneo.sede_eliminar
DECLARE @e INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Elim' AND ciudad = 'Ciudad Elim'),
        @p INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'Test Sede Partido' AND ciudad = 'Ciudad Partido'),
        @pa INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ZSA');

EXEC torneo.sede_eliminar @e; --> Baja valida (sin partidos)
-- EXEC torneo.sede_eliminar 999999; --> Sede inexistente
-- EXEC torneo.sede_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC torneo.sede_eliminar @p; --> Tiene partidos asociados
GO


-- ============================================================
-- 1.4 torneo.seleccion
-- ============================================================
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


-- ============================================================
-- 1.5 torneo.partido
-- ============================================================

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
DECLARE @m    INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'grupos'        AND seleccion_local_id IN (@a3, @a4) AND seleccion_visitante_id IN (@a3, @a4)),
        @fin  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'octavos'       AND seleccion_local_id IN (@a1, @a3) AND seleccion_visitante_id IN (@a1, @a3)),
        @form INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'cuartos'       AND seleccion_local_id IN (@a1, @a4) AND seleccion_visitante_id IN (@a1, @a4)),
        @all  INT = (SELECT partido_id FROM torneo.partido WHERE fase = 'dieciseisavos' AND seleccion_local_id IN (@a1, @a2) AND seleccion_visitante_id IN (@a1, @a2));

EXEC torneo.partido_modificar @m, @sl, '2026-06-22 15:00:00 -03:00', 'grupos', @a3, @a4; --> Valido: cambia sede y fecha 
-- EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4; --> Valido: sin cambios
-- EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a4, @a3; --> Valido: se invierten local y visitante 
-- EXEC torneo.partido_modificar @m, @sm, '2026-06-20 15:00:00 -03:00', 'grupos', @a3, @a4, 'suspendido'; --> Valido: pasa a suspendido
-- EXEC torneo.partido_modificar @form, @sb, '2026-07-01 15:00:00 -03:00', 'cuartos', @a1, @a4; --> Valido: se reprograma un partido con formaciones sin cambiar las selecciones
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


-- ============================================================
-- 1.6 plantel.persona, plantel.cuerpo_tecnico y plantel.jugador
-- ============================================================
-- Verificacion plantel.persona_insertar (el SP solo valida el tipo: maximo 1 error)
DECLARE @id INT

EXEC plantel.persona_insertar 'jugador', @id OUTPUT; --> Valido: jugador
-- EXEC plantel.persona_insertar 'cuerpo_tecnico', @id OUTPUT; --> Valido
-- EXEC plantel.persona_insertar NULL, @id OUTPUT; --> Tipo nulo
-- EXEC plantel.persona_insertar '', @id OUTPUT; --> Tipo vacio
-- EXEC plantel.persona_insertar '   ', @id OUTPUT; --> Tipo solo espacios
-- EXEC plantel.persona_insertar 'arbitro', @id OUTPUT; --> Tipo inexistente
-- EXEC plantel.persona_insertar 'jugadores', @id OUTPUT; --> Tipo parecido pero incorrecto
-- EXEC plantel.persona_insertar 'cuerpo tecnico', @id OUTPUT; --> Tipo sin guion bajo
-- EXEC plantel.persona_insertar 'jugador_con_un_nombre_demasiado_largo', @id OUTPUT; --> Tipo demasiado largo (se trunca al pasar el parametro VARCHAR(20) y queda invalido)
GO

-- Verificacion plantel.persona_modificar
DECLARE @mod  INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'mod'),
        @jug  INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'jug'),
        @ct   INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'ct'),
        @todo INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'todo');

EXEC plantel.persona_modificar @mod, 'cuerpo_tecnico'; --> Valido
-- EXEC plantel.persona_modificar @mod, 'jugador'; --> Valido: vuelve a jugador
-- EXEC plantel.persona_modificar @mod, 'jugador'; --> Valido: sin cambios (mismo tipo)
-- EXEC plantel.persona_modificar @jug, 'jugador'; --> Valido: jugador registrado, mismo tipo
-- EXEC plantel.persona_modificar 999999, 'jugador'; --> Persona inexistente
-- EXEC plantel.persona_modificar NULL, 'jugador'; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC plantel.persona_modificar @mod, NULL; --> Tipo nulo
-- EXEC plantel.persona_modificar @mod, ''; --> Tipo vacio
-- EXEC plantel.persona_modificar @mod, '   '; --> Tipo solo espacios
-- EXEC plantel.persona_modificar @mod, 'arbitro'; --> Tipo inexistente
-- EXEC plantel.persona_modificar 999999, 'arbitro'; --> 2 errores (maximo): persona inexistente y tipo invalido
-- EXEC plantel.persona_modificar 999999, 'cuerpo_tecnico'; --> 1 error: inexistente (los controles de registros no aplican a un id que no existe)
GO

-- Verificacion plantel.persona_eliminar
DECLARE @elim    INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'elim'),
        @elim_ct INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'elim_ct'),
        @jug     INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'jug'),
        @ct      INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'ct'),
        @tarj    INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'tarj'),
        @todo    INT = (SELECT MAX(persona_id) FROM ##test_persona WHERE clave = 'todo');

EXEC plantel.persona_eliminar @elim; --> Baja valida 
-- EXEC plantel.persona_eliminar @elim_ct; --> Baja valida (tipo cuerpo tecnico, sin registros)
-- EXEC plantel.persona_eliminar @elim; --> Ejecutar de nuevo tras la baja valida: ya no existe
-- EXEC plantel.persona_eliminar 999999; --> Persona inexistente
-- EXEC plantel.persona_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC plantel.persona_eliminar @jug; --> Registrada como jugador (requiere plantel.jugador cargado)
-- EXEC plantel.persona_eliminar @ct; --> Registrada como cuerpo tecnico (requiere plantel.cuerpo_tecnico cargado)
-- EXEC plantel.persona_eliminar @tarj; --> Tiene tarjetas registradas (requiere evento.tarjeta cargado)
GO

-- Verificacion plantel.cuerpo_tecnico_insertar
DECLARE @id INT, @pid INT,
        @antes INT = (SELECT COUNT(*) FROM plantel.persona),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC'),
        @n100 VARCHAR(100) = 'Test CT' + REPLICATE('N', 93);

-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Alta', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT;   --> Valido
-- EXEC plantel.cuerpo_tecnico_insertar @s1, '  Test CT  ', '  Recortado  ', 'otro', @id OUTPUT, @pid OUTPUT;   --> Valido: se guarda recortado
-- EXEC plantel.cuerpo_tecnico_insertar @s3, 'Test CT', 'Alta DT', 'director_tecnico', @id OUTPUT, @pid OUTPUT;   --> Valido: DT en seleccion sin DT
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Alta', 'preparador_fisico', @id OUTPUT, @pid OUTPUT;   --> Valido: misma persona con otro rol en la misma seleccion
-- EXEC plantel.cuerpo_tecnico_insertar @s2, 'Test CT', 'Alta', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT;   --> Valido: misma persona y rol en otra seleccion
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Rol Otro', 'otro', @id OUTPUT, @pid OUTPUT;   --> Valido: rol "otro"
-- EXEC plantel.cuerpo_tecnico_insertar @s1, @n100, 'Largo', 'otro', @id OUTPUT, @pid OUTPUT;   --> Valido: nombre de 100 caracteres (borde; ajustar si la columna es mas corta)
-- EXEC plantel.cuerpo_tecnico_insertar 999999, 'Test CT', 'X', 'otro', @id OUTPUT, @pid OUTPUT; --> Seleccion inexistente
-- EXEC plantel.cuerpo_tecnico_insertar NULL, 'Test CT', 'X', 'otro', @id OUTPUT, @pid OUTPUT; --> Seleccion nula
-- EXEC plantel.cuerpo_tecnico_insertar @s1, NULL, 'X', 'otro', @id OUTPUT, @pid OUTPUT; --> Nombre nulo
-- EXEC plantel.cuerpo_tecnico_insertar @s1, '', 'X', 'otro', @id OUTPUT, @pid OUTPUT; --> Nombre vacio
-- EXEC plantel.cuerpo_tecnico_insertar @s1, '   ', 'X', 'otro', @id OUTPUT, @pid OUTPUT; --> Nombre solo espacios
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', NULL, 'otro', @id OUTPUT, @pid OUTPUT; --> Apellido nulo
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', '', 'otro', @id OUTPUT, @pid OUTPUT; --> Apellido vacio
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', '   ', 'otro', @id OUTPUT, @pid OUTPUT; --> Apellido solo espacios
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'X', NULL, @id OUTPUT, @pid OUTPUT; --> Rol nulo
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'X', '', @id OUTPUT, @pid OUTPUT; --> Rol vacio
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'X', 'masajista', @id OUTPUT, @pid OUTPUT; --> Rol invalido
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Otro DT', 'director_tecnico', @id OUTPUT, @pid OUTPUT; --> 2do director tecnico en la misma seleccion
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Ayudante', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT; --> Duplicado: misma seleccion, nombre, apellido y rol
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT  ', 'Ayudante  ', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT; --> Duplicado con espacios al final
EXEC plantel.cuerpo_tecnico_insertar @s1, '  Test CT', '  Ayudante', 'ayudante_tecnico', @id OUTPUT, @pid OUTPUT; --> Espacios al inicio: antes no se detectaba, se modifico el validar para que salte el error
-- EXEC plantel.cuerpo_tecnico_insertar @s1, 'Test CT', 'Director', 'director_tecnico', @id OUTPUT, @pid OUTPUT; --> 2 errores: ya tiene DT y duplicado
-- EXEC plantel.cuerpo_tecnico_insertar 999999, '', '', 'x', @id OUTPUT, @pid OUTPUT; --> 4 errores (maximo): seleccion, nombre, apellido y rol
GO

-- Verificacion plantel.cuerpo_tecnico_modificar
DECLARE @m  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Mod', 'Mod Nuevo')),
        @t  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Tarjeta', 'Tarjeta Nuevo')),
        @dt INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Director'),
        @ay INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Ayudante'),
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA'),
        @s2 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCB'),
        @s3 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCC');

-- EXEC plantel.cuerpo_tecnico_modificar @m, @s2, 'Test CT', 'Mod Nuevo', 'ayudante_tecnico'; --> Valido: cambia seleccion, apellido y rol
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '  Test CT  ', '  Mod  ', 'otro'; --> Valido: se guarda recortado
-- EXEC plantel.cuerpo_tecnico_modificar NULL, @s1, 'Test CT', 'Mod', 'otro'; --> Id nulo
-- EXEC plantel.cuerpo_tecnico_modificar 999999, @s1, 'Test CT', 'Mod', 'otro'; --> Integrante inexistente
-- EXEC plantel.cuerpo_tecnico_modificar @m, 999999, 'Test CT', 'Mod', 'otro'; --> Seleccion inexistente
-- EXEC plantel.cuerpo_tecnico_modificar @m, NULL, 'Test CT', 'Mod', 'otro'; --> Seleccion nula
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, NULL, 'Mod', 'otro'; --> Nombre nulo
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '', 'Mod', 'otro'; --> Nombre vacio
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '   ', 'Mod', 'otro'; --> Nombre solo espacios
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', NULL, 'otro'; --> Apellido nulo
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', '', 'otro'; --> Apellido vacio
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', '   ', 'otro'; --> Apellido solo espacios
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Mod', NULL; --> Rol nulo
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Mod', ''; --> Rol vacio
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Mod', 'masajista'; --> Rol invalido
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Mod', 'director_tecnico'; --> Selecciona un DT en seleccion que ya tiene otro DT
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT', 'Otra', 'preparador_fisico'; --> Duplicado: coincide con otro integrante
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'TEST CT', 'OTRA', 'preparador_fisico'; --> Duplicado con otra capitalizacion (CI)
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, 'Test CT  ', 'Otra  ', 'preparador_fisico'; --> Duplicado con espacios al final
-- EXEC plantel.cuerpo_tecnico_modificar @m, @s1, '  Test CT', '  Otra', 'preparador_fisico'; --> Espacios al inicio
-- EXEC plantel.cuerpo_tecnico_modificar 999999, @s1, 'Test CT', 'Otra', 'preparador_fisico'; --> 2 errores: integrante inexistente y duplicado
-- EXEC plantel.cuerpo_tecnico_modificar @t, @s1, 'Test CT', 'Director', 'director_tecnico'; --> 3 errores: ya tiene DT, duplicado y cambio de seleccion con tarjetas 
-- EXEC plantel.cuerpo_tecnico_modificar @t, 999999, '', '', 'x'; --> 4 errores (maximo): seleccion, nombre, apellido, rol y cambio de seleccion con tarjetas
GO

-- Verificacion plantel.cuerpo_tecnico_eliminar
DECLARE @e  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim'),
        @et INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim Tran'),
        @t  INT = (SELECT staff_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido IN ('Tarjeta', 'Tarjeta Nuevo')),
        @pe INT = (SELECT persona_id FROM plantel.cuerpo_tecnico WHERE nombre = 'Test CT' AND apellido = 'Elim');

-- EXEC plantel.cuerpo_tecnico_eliminar @e; --> Baja valida (sin tarjetas): ambos 0
-- EXEC plantel.cuerpo_tecnico_eliminar @e; --> Ya eliminado: integrante inexistente (ejecutar despues de la baja valida)
-- EXEC plantel.cuerpo_tecnico_eliminar 999999; --> Integrante inexistente
-- EXEC plantel.cuerpo_tecnico_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC plantel.cuerpo_tecnico_eliminar @t; --> Tiene tarjetas registradas --> tiene que ejecutarse junto con el test de tarjetas usando las fk
   


-- Verificacion plantel.jugador_insertar
DECLARE @id INT, @pid INT, @antes INT,
        @f15 DATE = DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE)),
        @f50 DATE = DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE)),
        @n100 VARCHAR(100) = 'Test JU' + REPLICATE('N', 93),
        @c120 VARCHAR(120) = REPLICATE('C', 120);
EXEC plantel.jugador_insertar 'Test JU', 'Alta', '1995-03-15', 'delantero', 'Club Alta', @id OUTPUT, @pid OUTPUT; --> Valido
-- EXEC plantel.jugador_insertar '  Test JU  ', '  Recortado  ', '1995-03-15', 'defensor', '  Club Recortado  ', @id OUTPUT, @pid OUTPUT; --> Valido: se guarda recortado
-- EXEC plantel.jugador_insertar 'Test JU', 'Sin Club', '1995-03-15', 'arquero', NULL, @id OUTPUT, @pid OUTPUT; --> Valido: club nulo
-- EXEC plantel.jugador_insertar 'Test JU', 'Club Vacio', '1995-03-15', 'arquero', '', @id OUTPUT, @pid OUTPUT; --> Valido: club vacio se guarda como NULL
-- EXEC plantel.jugador_insertar 'Test JU', 'Club Espacios', '1995-03-15', 'arquero', '   ', @id OUTPUT, @pid OUTPUT; --> Valido: club solo espacios se guarda como NULL
-- EXEC plantel.jugador_insertar 'Test JU', 'Sin Param Club', '1995-03-15', 'mediocampista', @jugador_id = @id OUTPUT, @persona_id = @pid OUTPUT; --> Valido: sin pasar club (valor por defecto)
-- EXEC plantel.jugador_insertar 'Test JU', 'Club Largo', '1995-03-15', 'delantero', @c120, @id OUTPUT, @pid OUTPUT; --> Valido: club de 120 caracteres (borde)
-- EXEC plantel.jugador_insertar @n100, 'Nombre Largo', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Valido: nombre de 100 caracteres (borde)
-- EXEC plantel.jugador_insertar 'Test JU', 'Mediocampista', '1995-03-15', 'mediocampista', NULL, @id OUTPUT, @pid OUTPUT; --> Valido: posicion mediocampista
-- EXEC plantel.jugador_insertar 'Test JU', 'Borde 15', @f15, 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Valido: justo 15 anios (borde)
-- EXEC plantel.jugador_insertar 'Test JU', 'Borde 50', @f50, 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Valido: justo 50 anios (borde)
-- EXEC plantel.jugador_insertar 'Test JU', 'Base', '1996-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Valido: mismo nombre y apellido con otra fecha
-- EXEC plantel.jugador_insertar 'Test JU', 'Otra Fecha Igual', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Valido: misma fecha que otros jugadores con otro apellido
-- EXEC plantel.jugador_insertar NULL, 'Alta X', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Nombre nulo
-- EXEC plantel.jugador_insertar '', 'Alta X', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Nombre vacio
-- EXEC plantel.jugador_insertar '   ', 'Alta X', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Nombre solo espacios
-- EXEC plantel.jugador_insertar 'Test JU', NULL, '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Apellido nulo
-- EXEC plantel.jugador_insertar 'Test JU', '', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Apellido vacio
-- EXEC plantel.jugador_insertar 'Test JU', '   ', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Apellido solo espacios
-- EXEC plantel.jugador_insertar 'Test JU', 'Alta X', NULL, 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Fecha de nacimiento nula
-- EXEC plantel.jugador_insertar 'Test JU', 'Alta X', DATEADD(DAY, 1, @f15), 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Menor de 15 anios (borde: un dia menos)
-- EXEC plantel.jugador_insertar 'Test JU', 'Alta X', DATEADD(DAY, -1, @f50), 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Mayor de 50 anios (borde: un dia mas)
-- EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '2999-01-01', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Fecha futura
-- EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '1900-01-01', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Fecha muy antigua
-- EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '1995-03-15', NULL, NULL, @id OUTPUT, @pid OUTPUT; --> Posicion nula
-- EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '1995-03-15', '', NULL, @id OUTPUT, @pid OUTPUT; --> Posicion vacia
-- EXEC plantel.jugador_insertar 'Test JU', 'Alta X', '1995-03-15', 'portero', NULL, @id OUTPUT, @pid OUTPUT; --> Posicion invalida
-- EXEC plantel.jugador_insertar 'Test JU', 'Base', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Duplicado: mismo nombre, apellido y fecha que la base
-- EXEC plantel.jugador_insertar 'Test JU  ', 'Base  ', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Duplicado con espacios al final
-- EXEC plantel.jugador_insertar '  Test JU', '  Base', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> Espacios al inicio: ya se detecta
-- EXEC plantel.jugador_insertar '', '', '1995-03-15', 'delantero', NULL, @id OUTPUT, @pid OUTPUT; --> 2 errores: nombre y apellido
-- EXEC plantel.jugador_insertar NULL, NULL, NULL, NULL, NULL, @id OUTPUT, @pid OUTPUT; --> 4 errores: nombre, apellido, fecha y posicion (todos nulos)
GO

-- Verificacion plantel.jugador_modificar
DECLARE @m INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido IN ('Mod', 'Mod Nuevo')),
        @base INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Base'),
        @f15 DATE = DATEADD(YEAR, -15, CAST(SYSDATETIME() AS DATE)),
        @f50 DATE = DATEADD(YEAR, -50, CAST(SYSDATETIME() AS DATE));

EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod Nuevo', '1996-06-20', 'delantero', 'Club Nuevo'; --> Valido: cambia apellido, fecha, posicion y club
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor', ''; --> Valido: club vacio se guarda como NULL
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor', '   '; --> Valido: club solo espacios se guarda como NULL
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'defensor'; --> Valido: sin pasar club (valor por defecto)
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'mediocampista', 'Club Mod'; --> Valido: posicion mediocampista
-- EXEC plantel.jugador_modificar NULL, 'Test JU', 'Mod', '1995-03-15', 'defensor', NULL; --> Id nulo
-- EXEC plantel.jugador_modificar 999999, 'Test JU', 'Mod', '1995-03-15', 'defensor', NULL; --> Jugador inexistente
-- EXEC plantel.jugador_modificar @m, NULL, 'Mod', '1995-03-15', 'defensor', NULL; --> Nombre nulo
-- EXEC plantel.jugador_modificar @m, '', 'Mod', '1995-03-15', 'defensor', NULL; --> Nombre vacio
-- EXEC plantel.jugador_modificar @m, '   ', 'Mod', '1995-03-15', 'defensor', NULL; --> Nombre solo espacios
-- EXEC plantel.jugador_modificar @m, 'Test JU', NULL, '1995-03-15', 'defensor', NULL; --> Apellido nulo
-- EXEC plantel.jugador_modificar @m, 'Test JU', '', '1995-03-15', 'defensor', NULL; --> Apellido vacio
-- EXEC plantel.jugador_modificar @m, 'Test JU', '   ', '1995-03-15', 'defensor', NULL; --> Apellido solo espacios
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', NULL, 'defensor', NULL; --> Fecha de nacimiento nula
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', DATEADD(DAY, 1, @f15), 'defensor', NULL; --> Menor de 15 anios (borde: un dia menos)
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', DATEADD(DAY, -1, @f50), 'defensor', NULL; --> Mayor de 50 anios (borde: un dia mas)
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '2999-01-01', 'defensor', NULL; --> Fecha futura
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1900-01-01', 'defensor', NULL; --> Fecha muy antigua
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', NULL, NULL; --> Posicion nula
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', '', NULL; --> Posicion vacia
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Mod', '1995-03-15', 'portero', NULL; --> Posicion invalida
-- EXEC plantel.jugador_modificar @m, 'Test JU', 'Otro', '1995-03-15', 'defensor', NULL; --> Duplicado: coincide con otro jugador (nombre, apellido y fecha)
-- EXEC plantel.jugador_modificar @m, 'Test JU  ', 'Otro  ', '1995-03-15', 'defensor', NULL; --> Duplicado con espacios al final
-- EXEC plantel.jugador_modificar @m, '  Test JU', '  Otro', '1995-03-15', 'defensor', NULL; --> Espacios al inicio: antes no se detectaba, ahora si
-- EXEC plantel.jugador_modificar 999999, 'Test JU', 'Otro', '1995-03-15', 'defensor', NULL; --> 2 errores: jugador inexistente y duplicado
-- EXEC plantel.jugador_modificar 999999, 'Test JU', 'Otro', '1995-03-15', 'portero', NULL; --> 3 errores: jugador inexistente, posicion y duplicado
-- EXEC plantel.jugador_modificar NULL, NULL, NULL, NULL, NULL, NULL; --> 5 errores: id obligatorio, nombre, apellido, fecha y posicion
GO

-- Verificacion plantel.jugador_eliminar
DECLARE @e INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Elim'),
        @et INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Elim Tran'),
        @conv INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Convocado'),
        @form INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Formacion'),
        @tar INT = (SELECT jugador_id FROM plantel.jugador WHERE nombre = 'Test JU' AND apellido = 'Tarjeta');

EXEC plantel.jugador_eliminar @e; --> Baja valida (sin convocatorias, formaciones ni tarjetas)
-- EXEC plantel.jugador_eliminar @e; --> Ya eliminado: jugador inexistente (ejecutar despues de la baja valida)
-- EXEC plantel.jugador_eliminar 999999; --> Jugador inexistente
-- EXEC plantel.jugador_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC plantel.jugador_eliminar @conv; --> Tiene convocatorias registradas (pendiente: requiere convocatoria preparada)
-- EXEC plantel.jugador_eliminar @form; --> Integra formaciones de partidos (pendiente: requiere formacion_jugador preparada)
-- EXEC plantel.jugador_eliminar @tar; --> Tiene tarjetas registradas (pendiente: requiere tarjeta preparada)

-- ============================================================
-- 1.7 plantel.convocatoria
-- ============================================================
-- Verificacion plantel.convocatoria_insertar
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

EXEC plantel.convocatoria_insertar @s3, @l1, 1, '2026-06-01', 'Convocatoria inicial', @id OUTPUT; --> Valido
-- EXEC plantel.convocatoria_insertar @s3, @l2, 2, '2026-06-01', '  Motivo con espacios  ', @id OUTPUT; --> Valido: motivo se guarda recortado
-- EXEC plantel.convocatoria_insertar @s3, @l3, 3, '2026-06-01', NULL, @id OUTPUT; --> Valido: motivo nulo
-- EXEC plantel.convocatoria_insertar @s3, @l4, 4, '2026-06-01', '', @id OUTPUT; --> Valido: motivo vacio se guarda como NULL
-- EXEC plantel.convocatoria_insertar @s3, @l5, 5, '2026-06-01', '   ', @id OUTPUT; --> Valido: motivo solo espacios se guarda como NULL
-- EXEC plantel.convocatoria_insertar @s3, @l6, 6, '2026-06-01', @convocatoria_id = @id OUTPUT; --> Valido: sin pasar motivo (valor por defecto)
-- EXEC plantel.convocatoria_insertar @s2, @l7, 1, '2026-06-01', NULL, @id OUTPUT; --> Valido: dorsal minimo (borde)
-- EXEC plantel.convocatoria_insertar @s2, @l8, 99, '2026-06-01', NULL, @id OUTPUT; --> Valido: dorsal maximo (borde)
-- EXEC plantel.convocatoria_insertar @s1, @l9, 5, '2026-06-01', NULL, @id OUTPUT; --> Valido: dorsal 5 usado solo por una convocatoria historica
-- EXEC plantel.convocatoria_insertar @s3, @l10, 7, '2026-06-01', NULL, @id OUTPUT; --> Valido: mismo dorsal que usa s1, pero en otra seleccion
-- EXEC plantel.convocatoria_insertar @s1, @jb, 6, '2026-06-01', NULL, @id OUTPUT; --> Valido: jugador con convocatoria historica vuelve a ser convocado en la misma seleccion
-- EXEC plantel.convocatoria_insertar @s2, @jb2, 6, '2026-06-01', NULL, @id OUTPUT; --> Valido: jugador con convocatoria historica convocado por otra seleccion
-- EXEC plantel.convocatoria_insertar 999999, @jl, 60, '2026-06-01', NULL, @id OUTPUT; --> Seleccion inexistente
-- EXEC plantel.convocatoria_insertar NULL, @jl, 60, '2026-06-01', NULL, @id OUTPUT; --> Seleccion nula
-- EXEC plantel.convocatoria_insertar @s3, 999999, 60, '2026-06-01', NULL, @id OUTPUT; --> Jugador inexistente
-- EXEC plantel.convocatoria_insertar @s3, NULL, 60, '2026-06-01', NULL, @id OUTPUT; --> Jugador nulo
-- EXEC plantel.convocatoria_insertar @s3, @jl, NULL, '2026-06-01', NULL, @id OUTPUT; --> Dorsal nulo
-- EXEC plantel.convocatoria_insertar @s3, @jl, 0, '2026-06-01', NULL, @id OUTPUT; --> Dorsal 0 (borde)
-- EXEC plantel.convocatoria_insertar @s3, @jl, -1, '2026-06-01', NULL, @id OUTPUT; --> Dorsal negativo
-- EXEC plantel.convocatoria_insertar @s3, @jl, 100, '2026-06-01', NULL, @id OUTPUT; --> Dorsal 100 (borde)
-- EXEC plantel.convocatoria_insertar @s3, @jl, 60, NULL, NULL, @id OUTPUT; --> Fecha de alta nula
-- EXEC plantel.convocatoria_insertar @s1, @jl, 8, '2026-06-01', NULL, @id OUTPUT; --> Dorsal en uso por una convocatoria vigente de la seleccion
-- EXEC plantel.convocatoria_insertar @s1, @jm, 20, '2026-06-01', NULL, @id OUTPUT; --> El jugador ya integra la convocatoria vigente de la seleccion
-- EXEC plantel.convocatoria_insertar @s3, @jm, 20, '2026-06-01', NULL, @id OUTPUT; --> El jugador esta convocado por otra seleccion
-- EXEC plantel.convocatoria_insertar @s1, @jm, 7, '2026-06-01', NULL, @id OUTPUT; --> 2 errores: dorsal en uso y jugador ya integra la convocatoria
-- EXEC plantel.convocatoria_insertar NULL, NULL, NULL, NULL, NULL, @id OUTPUT; --> 4 errores: seleccion, jugador, dorsal y fecha de alta (todo nulo)
GO

-- Verificacion plantel.convocatoria_modificar
DECLARE @cm INT, @cbm INT, @cb INT, @cb2 INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @cm  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Mod'      AND c.seleccion_id = @s1);
SET @cbm = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja Mod' AND c.seleccion_id = @s1);
SET @cb  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja'     AND c.seleccion_id = @s1);
SET @cb2 = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Baja 2'   AND c.seleccion_id = @s1);

-- EXEC plantel.convocatoria_modificar @cm, 12, '2026-06-02', 'Motivo nuevo', NULL, NULL; --> Valido: cambia dorsal, fecha y motivo de alta
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', 'Motivo inicial', NULL, NULL; --> Valido: sin cambios (no choca consigo misma)
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '  Motivo  ', NULL, NULL; --> Valido: motivo de alta se guarda recortado
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, NULL, NULL; --> Valido: motivo de alta nulo
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '', NULL, NULL; --> Valido: motivo de alta vacio se guarda como NULL
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', '   ', NULL, NULL; --> Valido: motivo de alta solo espacios se guarda como NULL
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01'; --> Valido: sin pasar motivo ni baja (valores por defecto)
-- EXEC plantel.convocatoria_modificar @cm, 1, '2026-06-01', NULL, NULL, NULL; --> Valido: dorsal minimo (borde)
-- EXEC plantel.convocatoria_modificar @cm, 99, '2026-06-01', NULL, NULL, NULL; --> Valido: dorsal maximo (borde)
-- EXEC plantel.convocatoria_modificar @cm, 5, '2026-06-01', NULL, NULL, NULL; --> Valido: dorsal 5 usado solo por una convocatoria historica
-- EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, '2026-06-20', 'Lesion'; --> Valido: registrar la baja (queda historica)
-- EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, '2026-06-01', 'Reemplazo'; --> Valido: baja el mismo dia del alta (borde)
-- EXEC plantel.convocatoria_modificar @cbm, 9, '2026-06-01', NULL, NULL, NULL; --> Valido: reactivar la baja (vuelve a ser vigente; ejecutar despues de registrar la baja)
-- EXEC plantel.convocatoria_modificar @cb, 5, '2026-05-01', NULL, '2026-05-25', 'Reemplazo'; --> Valido: corregir fecha y motivo de baja de una historica
-- EXEC plantel.convocatoria_modificar NULL, 7, '2026-06-01'; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC plantel.convocatoria_modificar 999999, 7, '2026-06-01'; --> Convocatoria inexistente
-- EXEC plantel.convocatoria_modificar @cm, NULL, '2026-06-01', NULL, NULL, NULL; --> Dorsal nulo
-- EXEC plantel.convocatoria_modificar @cm, 0, '2026-06-01', NULL, NULL, NULL; --> Dorsal 0 (borde)
-- EXEC plantel.convocatoria_modificar @cm, -1, '2026-06-01', NULL, NULL, NULL; --> Dorsal negativo
-- EXEC plantel.convocatoria_modificar @cm, 100, '2026-06-01', NULL, NULL, NULL; --> Dorsal 100 (borde)
-- EXEC plantel.convocatoria_modificar @cm, 7, NULL, NULL, NULL, NULL; --> Fecha de alta nula
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, '2026-05-31', 'Lesion'; --> Baja anterior al alta (borde: un dia antes)
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, NULL, 'Lesion'; --> Motivo de baja sin fecha de baja
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, NULL, ''; --> Motivo de baja vacio sin fecha de baja (vacio no es NULL)
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, '2026-06-10', NULL; --> Baja sin motivo (nulo)
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, '2026-06-10', ''; --> Baja con motivo vacio
-- EXEC plantel.convocatoria_modificar @cm, 7, '2026-06-01', NULL, '2026-06-10', '   '; --> Baja con motivo solo espacios
-- EXEC plantel.convocatoria_modificar @cm, 8, '2026-06-01', NULL, NULL, NULL; --> Dorsal en uso: lo tiene otra convocatoria vigente de la seleccion
-- EXEC plantel.convocatoria_modificar @cb, 8, '2026-05-01', NULL, NULL, NULL; --> Reactivar una baja con un dorsal que usa otra vigente
-- EXEC plantel.convocatoria_modificar @cm, 8, '2026-06-01', NULL, NULL, 'Lesion'; --> 2 errores: motivo sin fecha de baja y dorsal en uso
-- EXEC plantel.convocatoria_modificar @cm, 0, '2026-06-01', NULL, '2026-05-01', NULL; --> 3 errores: dorsal, baja anterior al alta y baja sin motivo
GO

-- Verificacion plantel.convocatoria_eliminar
DECLARE @ce INT, @ceb INT, @cf INT,
        @s1 INT = (SELECT s.seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ZCA');
SET @ce  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Elim'      AND c.seleccion_id = @s1);
SET @ceb = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Conv Elim Baja' AND c.seleccion_id = @s1);
SET @cf  = (SELECT c.convocatoria_id FROM plantel.convocatoria c JOIN plantel.jugador j ON j.jugador_id = c.jugador_id WHERE j.nombre = 'Test JU' AND j.apellido = 'Formacion'     AND c.seleccion_id = @s1);

EXEC plantel.convocatoria_eliminar @ce; --> Baja valida: convocatoria vigente sin formaciones
-- EXEC plantel.convocatoria_eliminar @ceb; --> Baja valida: convocatoria historica (con baja) sin formaciones
-- EXEC plantel.convocatoria_eliminar 999999; --> Convocatoria inexistente
-- EXEC plantel.convocatoria_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
GO


-- ============================================================
-- 1.8 plantel.formacion y plantel.formacion_jugador (carga de a un jugador)
-- ============================================================
-- Verificacion plantel.formacion_insertar
DECLARE @id INT,
        @pa INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'ins_a'),
        @pb INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'ins_b'),
        @pc INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'ins_c'),
        @pm INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'mod'),
        @pf INT = (SELECT partido_id FROM ##test_formacion WHERE clave = 'fin');
-- EXEC plantel.formacion_insertar @pa, 'local', '4-3-3', @id OUTPUT; --> Valido
-- EXEC plantel.formacion_insertar @pa, 'visitante', '4-4-2', @id OUTPUT; --> Valido: mismo partido, la otra condicion
-- EXEC plantel.formacion_insertar @pb, 'local', '3-5-2', @id OUTPUT; --> Valido: otro esquema de 3 lineas
-- EXEC plantel.formacion_insertar @pb, 'visitante', '4-2-3-1', @id OUTPUT; --> Valido: esquema de 4 lineas
-- EXEC plantel.formacion_insertar @pc, 'local', '1-1-1-1-6', @id OUTPUT; --> Valido: 5 lineas y 9 caracteres (borde maximo)
-- EXEC plantel.formacion_insertar @pc, 'visitante', '1-1-8', @id OUTPUT; --> Valido: 3 lineas (borde minimo)
-- EXEC plantel.formacion_insertar @pc, 'visitante', '4-3-3', @formacion_id = @id OUTPUT; --> Duplicado si se ejecuto el caso anterior (visitante de @pc ya cargado)
-- EXEC plantel.formacion_insertar 999999, 'local', '4-3-3', @id OUTPUT; --> Partido inexistente
-- EXEC plantel.formacion_insertar NULL, 'local', '4-3-3', @id OUTPUT; --> Partido nulo
-- EXEC plantel.formacion_insertar @pf, 'visitante', '4-3-3', @id OUTPUT; --> Partido finalizado
-- EXEC plantel.formacion_insertar @pa, NULL, '4-3-3', @id OUTPUT; --> Condicion nula
-- EXEC plantel.formacion_insertar @pa, '', '4-3-3', @id OUTPUT; --> Condicion vacia
-- EXEC plantel.formacion_insertar @pa, 'otro', '4-3-3', @id OUTPUT; --> Condicion invalida
-- EXEC plantel.formacion_insertar @pm, 'local', '4-3-3', @id OUTPUT; --> El equipo local ya tiene formacion cargada
-- EXEC plantel.formacion_insertar @pm, 'visitante', '4-3-3', @id OUTPUT; --> El equipo visitante ya tiene formacion cargada
-- EXEC plantel.formacion_insertar @pc, 'local', NULL, @id OUTPUT; --> Esquema nulo
-- EXEC plantel.formacion_insertar @pc, 'local', '', @id OUTPUT; --> Esquema vacio
-- EXEC plantel.formacion_insertar @pc, 'local', '433', @id OUTPUT; --> Esquema sin guiones (1 linea)
-- EXEC plantel.formacion_insertar @pc, 'local', '5-5', @id OUTPUT; --> Esquema con 2 lineas (borde: una menos que el minimo)
-- EXEC plantel.formacion_insertar @pc, 'local', '1-1-1-1-1-5', @id OUTPUT; --> Esquema con 6 lineas y mas de 9 caracteres
-- EXEC plantel.formacion_insertar @pc, 'local', '4-3-2', @id OUTPUT; --> Suma 9 (borde: uno menos)
-- EXEC plantel.formacion_insertar @pc, 'local', '4-4-3', @id OUTPUT; --> Suma 11 (borde: uno mas)
-- EXEC plantel.formacion_insertar @pc, 'local', '4-0-6', @id OUTPUT; --> Linea con 0 jugadores
-- EXEC plantel.formacion_insertar @pc, 'local', '10-0-0', @id OUTPUT; --> Linea de 2 digitos
-- EXEC plantel.formacion_insertar @pc, 'local', '4-3-3-', @id OUTPUT; --> Guion final (linea vacia)
-- EXEC plantel.formacion_insertar @pc, 'local', '-4-3-3', @id OUTPUT; --> Guion inicial (linea vacia)
-- EXEC plantel.formacion_insertar @pc, 'local', '4--3-3', @id OUTPUT; --> Guiones consecutivos (linea vacia)
-- EXEC plantel.formacion_insertar @pc, 'local', '4-a-6', @id OUTPUT; --> Linea no numerica
-- EXEC plantel.formacion_insertar @pc, 'local', '4 -3-3', @id OUTPUT; --> Esquema con espacios
-- EXEC plantel.formacion_insertar @pc, 'local', '4-3-3-0', @id OUTPUT; --> 4 lineas pero una en 0
-- EXEC plantel.formacion_insertar 999999, 'otro', '433', @id OUTPUT; --> 3 errores: partido inexistente, condicion y esquema
EXEC plantel.formacion_insertar @pf, 'local', '4-4-3', @id OUTPUT; --> 3 errores: partido finalizado, formacion duplicada y esquema
GO

-- Verificacion plantel.formacion_modificar
DECLARE @fm INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'mod'),
        @ff INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fin');
EXEC plantel.formacion_modificar @fm, '4-3-3'; --> Valido: cambia el esquema
-- EXEC plantel.formacion_modificar @fm, '3-5-2'; --> Valido: otro esquema de 3 lineas
-- EXEC plantel.formacion_modificar @fm, '1-1-1-1-6'; --> Valido: 5 lineas y 9 caracteres (borde maximo)
-- EXEC plantel.formacion_modificar @fm, '1-1-8'; --> Valido: 3 lineas (borde minimo)
-- EXEC plantel.formacion_modificar @fm, '4-4-2'; --> Valido: deja la formacion como en la preparacion
-- EXEC plantel.formacion_modificar NULL, '4-3-3'; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC plantel.formacion_modificar 999999, '4-3-3'; --> Formacion inexistente
-- EXEC plantel.formacion_modificar @ff, '4-3-3'; --> Partido finalizado
-- EXEC plantel.formacion_modificar @fm, NULL; --> Esquema nulo
-- EXEC plantel.formacion_modificar @fm, ''; --> Esquema vacio
-- EXEC plantel.formacion_modificar @fm, '433'; --> Esquema sin guiones (1 linea)
-- EXEC plantel.formacion_modificar @fm, '5-5'; --> Esquema con 2 lineas (borde: una menos que el minimo)
-- EXEC plantel.formacion_modificar @fm, '1-1-1-1-1-5'; --> Esquema con 6 lineas y mas de 9 caracteres
-- EXEC plantel.formacion_modificar @fm, '4-3-2'; --> Suma 9 (borde: uno menos)
-- EXEC plantel.formacion_modificar @fm, '4-4-3'; --> Suma 11 (borde: uno mas)
-- EXEC plantel.formacion_modificar @fm, '4-0-6'; --> Linea con 0 jugadores
-- EXEC plantel.formacion_modificar @fm, '10-0-0'; --> Linea de 2 digitos
-- EXEC plantel.formacion_modificar @fm, '4-3-3-'; --> Guion final (linea vacia)
-- EXEC plantel.formacion_modificar @fm, '4-a-6'; --> Linea no numerica
-- EXEC plantel.formacion_modificar @fm, '4 -3-3'; --> Esquema con espacios
-- EXEC plantel.formacion_modificar 999999, NULL; --> 2 errores: formacion inexistente y esquema nulo
-- EXEC plantel.formacion_modificar NULL, '433'; --> 2 errores: id nulo y esquema invalido
-- EXEC plantel.formacion_modificar @ff, '4-4-3'; --> 2 errores: partido finalizado y esquema invalido
-- EXEC plantel.formacion_modificar @ff, NULL; --> 2 errores: partido finalizado y esquema nulo
GO

-- Verificacion plantel.formacion_eliminar
DECLARE @fe  INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'elim'),
        @fe2 INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'elim2'),
        @ff  INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'fin'),
        @fj  INT = (SELECT formacion_id FROM ##test_formacion WHERE clave = 'jug');
EXEC plantel.formacion_eliminar @fe; --> Baja valida: formacion sin jugadores de partido no finalizado
-- EXEC plantel.formacion_eliminar @fe2; --> Baja valida: la otra condicion del mismo partido
-- EXEC plantel.formacion_eliminar 999999; --> Formacion inexistente
-- EXEC plantel.formacion_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC plantel.formacion_eliminar @ff; --> Partido finalizado
GO

-- Verificacion plantel.formacion_jugador_insertar
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
-- EXEC plantel.formacion_jugador_insertar @fj, @ins, 'Delantero', 1; --> Valido: titular (toma el dorsal 3 de su convocatoria)
-- EXEC plantel.formacion_jugador_insertar @fl, @l1, 'Lateral', 0; --> Valido: suplente en una formacion con los titulares completos
-- EXEC plantel.formacion_jugador_insertar @fl, @l2, '  Lateral  ', 0; --> Valido: la posicion se guarda recortada
-- EXEC plantel.formacion_jugador_insertar @fl, @adia, 'Lateral', 0; --> Valido: convocatoria con alta el mismo dia del partido (borde)
-- EXEC plantel.formacion_jugador_insertar @fs, @sn, 'Delantero', 1; --> Valido: titular en una formacion con el banco de suplentes completo
-- EXEC plantel.formacion_jugador_insertar 999999, @ins, 'Delantero', 1; --> Formacion inexistente
-- EXEC plantel.formacion_jugador_insertar NULL, @ins, 'Delantero', 1; --> Formacion nula
-- EXEC plantel.formacion_jugador_insertar @ff, @ins, 'Delantero', 1; --> Partido finalizado
-- EXEC plantel.formacion_jugador_insertar @fj, 999999, 'Delantero', 1; --> Jugador inexistente
-- EXEC plantel.formacion_jugador_insertar @fj, NULL, 'Delantero', 1; --> Jugador nulo
-- EXEC plantel.formacion_jugador_insertar @fj, @base, 'Delantero', 1; --> El jugador ya integra esa formacion
-- EXEC plantel.formacion_jugador_insertar @fl, @l3, NULL, 0; --> Posicion nula
-- EXEC plantel.formacion_jugador_insertar @fl, @l3, '', 0; --> Posicion vacia
-- EXEC plantel.formacion_jugador_insertar @fl, @l3, '   ', 0; --> Posicion solo espacios
-- EXEC plantel.formacion_jugador_insertar @fl, @l3, 'Defensor', NULL; --> Titular nulo
-- EXEC plantel.formacion_jugador_insertar @fj, @sc, 'Delantero', 1; --> Jugador sin convocatoria
-- EXEC plantel.formacion_jugador_insertar @fj, @t1, 'Delantero', 1; --> Jugador convocado solo por otra seleccion (ZCB)
-- EXEC plantel.formacion_jugador_insertar @fl, @hist, 'Defensor', 0; --> Convocatoria historica: baja anterior al partido
-- EXEC plantel.formacion_jugador_insertar @fl, @fut, 'Defensor', 0; --> Convocatoria con alta un dia despues del partido (borde)
-- EXEC plantel.formacion_jugador_insertar @fj, @p, 'Delantero', 1; --> Dorsal 40 ya usado en la formacion (lo conserva q1 aunque su convocatoria ahora tiene el 50)
-- EXEC plantel.formacion_jugador_insertar @fl, @tx, 'Delantero', 1; --> La formacion ya tiene el maximo de titulares (borde)
-- EXEC plantel.formacion_jugador_insertar @fs, @sx, 'Delantero', 0; --> El banco ya tiene el maximo de suplentes (borde)
-- EXEC plantel.formacion_jugador_insertar @fj, @susp, 'Delantero', 1; --> Jugador suspendido (ejecutar DESPUES de la preparacion de evento.suspension*)
-- EXEC plantel.formacion_jugador_insertar NULL, NULL, NULL, NULL; --> 4 errores: formacion, jugador, posicion y titular (todo nulo)
-- EXEC plantel.formacion_jugador_insertar @ff, @sc, '', 1; --> 3 errores: partido finalizado, posicion vacia y sin convocatoria
-- EXEC plantel.formacion_jugador_insertar @fj, @base, NULL, NULL; --> 3 errores: ya integra, posicion y titular
-- EXEC plantel.formacion_jugador_insertar @fj, @p, '', 1; --> 2 errores: posicion vacia y dorsal en uso
GO

-- Verificacion plantel.formacion_jugador_modificar
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
EXEC plantel.formacion_jugador_modificar @fj, @base, 'Extremo', 1; --> Valido: cambia la posicion
-- EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 1; --> Valido: sin cambios (deja al jugador como en la preparacion)
-- EXEC plantel.formacion_jugador_modificar @fj, @base, '  Extremo  ', 1; --> Valido: la posicion se guarda recortada
-- EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 0; --> Valido: titular pasa a suplente (sin sustituciones); restaurar con el caso siguiente
-- EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', 1; --> Valido: suplente vuelve a titular
-- EXEC plantel.formacion_jugador_modificar NULL, @base, 'Delantero', 1; --> Formacion nula
-- EXEC plantel.formacion_jugador_modificar 999999, @base, 'Delantero', 1; --> Formacion inexistente
-- EXEC plantel.formacion_jugador_modificar @ff, @fin, 'Delantero', 1; --> Partido finalizado
-- EXEC plantel.formacion_jugador_modificar @fj, 999999, 'Delantero', 1; --> 2 errores: jugador inexistente y no integra la formacion
-- EXEC plantel.formacion_jugador_modificar @fj, NULL, 'Delantero', 1; --> 2 errores: jugador nulo y no integra la formacion
-- EXEC plantel.formacion_jugador_modificar @fl, @l3, 'Defensor', 0; --> El jugador no integra esa formacion
-- EXEC plantel.formacion_jugador_modificar @fj, @base, NULL, 1; --> Posicion nula
-- EXEC plantel.formacion_jugador_modificar @fj, @base, '', 1; --> Posicion vacia
-- EXEC plantel.formacion_jugador_modificar @fj, @base, '   ', 1; --> Posicion solo espacios
-- EXEC plantel.formacion_jugador_modificar @fj, @base, 'Delantero', NULL; --> Titular nulo
-- EXEC plantel.formacion_jugador_modificar @fj, @zb, 'Defensor', 0; --> Su convocatoria ya no esta vigente a la fecha del partido (tiene baja)
-- EXEC plantel.formacion_jugador_modificar NULL, NULL, NULL, NULL; --> 4 errores: formacion, jugador, posicion y titular (todo nulo)
-- EXEC plantel.formacion_jugador_modificar @ff, @sc, 'Delantero', 1; --> 3 errores: partido finalizado, no integra la formacion y sin convocatoria vigente
-- EXEC plantel.formacion_jugador_modificar @fj, @r, NULL, NULL; --> 3 errores: posicion, titular y dorsal en uso
GO

-- Verificacion plantel.formacion_jugador_eliminar
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
EXEC plantel.formacion_jugador_eliminar @fj, @elim; --> Baja valida: jugador sin sustituciones, goles ni tarjetas
-- EXEC plantel.formacion_jugador_eliminar @fj, @zb; --> Baja valida: jugador cuya convocatoria ya no esta vigente
-- EXEC plantel.formacion_jugador_eliminar @fl, @l3; --> El jugador no integra esa formacion
-- EXEC plantel.formacion_jugador_eliminar 999999, @base; --> Formacion inexistente 
-- EXEC plantel.formacion_jugador_eliminar NULL, @base; --> Formacion nula (idem)
-- EXEC plantel.formacion_jugador_eliminar @fj, 999999; --> Jugador inexistente 
-- EXEC plantel.formacion_jugador_eliminar @fj, NULL; --> Jugador nulo (idem)
-- EXEC plantel.formacion_jugador_eliminar @ff, @fin; --> Partido finalizado
-- EXEC plantel.formacion_jugador_eliminar @ff, @sc; --> 2 errores: no integra la formacion y partido finalizado
-- EXEC plantel.formacion_jugador_eliminar @fj, @ssale; --> Participa de sustituciones, como el que sale (ejecutar DESPUES de la preparacion de evento.sustitucion_*)
-- EXEC plantel.formacion_jugador_eliminar @fj, @sent; --> Participa de sustituciones, como el que entra (ejecutar DESPUES de la preparacion de evento.sustitucion_*)
-- EXEC plantel.formacion_jugador_eliminar @fj, @gol; --> Tiene goles registrados (ejecutar DESPUES de la preparacion de evento.gol_*)
-- EXEC plantel.formacion_jugador_eliminar @fj, @asis; --> Tiene asistencias registradas (ejecutar DESPUES de la preparacion de evento.gol_*)
-- EXEC plantel.formacion_jugador_eliminar @fj, @tarj; --> Tiene tarjetas registradas en el partido (ejecutar DESPUES de la preparacion de evento.tarjeta_*)
GO

-- ============================================================
-- 1.9 evento.sustitucion
-- ============================================================
-- Verificacion evento.sustitucion_insertar
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


-- EXEC evento.sustitucion_insertar @fo, @ot1, @os1, 1,   'PT', 1, 'tactico',    @id OUTPUT; --> Valido: minuto minimo de PT (borde), primera ventana
-- EXEC evento.sustitucion_insertar @fo, @ot2, @os2, 60,  'PT', 1, 'lesion',     @id OUTPUT; --> Valido: minuto maximo de PT (borde), misma ventana que el cambio anterior
-- EXEC evento.sustitucion_insertar @fo, @os1, @os3, 45,  'ST', 2, 'precaucion', @id OUTPUT; --> Valido: reemplaza a quien ingresó antes (ejecutar despues del primero), minuto minimo de ST, ventana siguiente
-- EXEC evento.sustitucion_insertar @fo, @ot3, @os4, 110, 'ST', 2, 'tactico',    @id OUTPUT; --> Valido: minuto maximo de ST (borde), misma ventana

-- EXEC evento.sustitucion_insertar @fo, @otl, @osl, 70, 'PT', 1, 'tactico', @id OUTPUT; --> Minuto de ST en PT
-- EXEC evento.sustitucion_insertar @fo, NULL, @osl, 30, 'PT', 1, 'tactico', @id OUTPUT; --> Jugador que sale nulo (no integra la formación)
-- EXEC evento.sustitucion_insertar @fo, @otl, NULL, 30, 'PT', 1, 'tactico', @id OUTPUT; --> Jugador que entra nulo (no integra la formación)
-- EXEC evento.sustitucion_insertar @fo, @fu, @osl, 30, 'PT', 1, 'tactico', @id OUTPUT; --> El que sale no integra la formación (convocado pero no cargado)
-- EXEC evento.sustitucion_insertar @fo, @osl, @os1, 30, 'PT', 1, 'tactico', @id OUTPUT; --> El que sale es suplente y todavía no ingresó (no está en cancha)
-- EXEC evento.sustitucion_insertar @fo, @ot1, @ot2, 30, 'PT', 1, 'tactico', @id OUTPUT; --> El que entra es titular (no está disponible en el banco)

-- f_ok errores DESPUES de los válidos
-- EXEC evento.sustitucion_insertar @fo, @ot1, @osl, 80, 'ST', 2, 'tactico', @id OUTPUT; --> El que sale ya había sido reemplazado (no está en cancha)
-- EXEC evento.sustitucion_insertar @fo, @os1, @osl, 80, 'ST', 2, 'tactico', @id OUTPUT; --> El que sale ingresó y después fue reemplazado (no está en cancha)
-- EXEC evento.sustitucion_insertar @fo, @otl, @os2, 80, 'ST', 2, 'tactico', @id OUTPUT; --> El que entra ya había ingresado (no disponible en el banco)
-- EXEC evento.sustitucion_insertar @fo, @otl, @ot1, 80, 'ST', 2, 'tactico', @id OUTPUT; --> El que entra es un titular que ya salió (no disponible en el banco)
-- EXEC evento.sustitucion_insertar @fo, @otl, @osl, 30, 'PT', 2, 'tactico', @id OUTPUT; --> Ventana 2 ya usada en otro período (ST)
-- EXEC evento.sustitucion_insertar @fo, @otl, @osl, 50, 'ST', 1, 'tactico', @id OUTPUT; --> 2 errores: ventana anterior a la última y ventana 1 ya usada en otro período (PT)

-- f_gen: ventana V = última usada, V cambios (menos que el máximo). Todos estos casos son estables (no registran nada)
-- EXEC evento.sustitucion_insertar NULL, @gtl, @gsl, 80, 'ST', @V, 'tactico', @id OUTPUT; --> Formación nula (el mensaje dice "(nulo)")
-- EXEC evento.sustitucion_insertar 999999, @gtl, @gsl, 80, 'ST', @V, 'tactico', @id OUTPUT; --> Formación inexistente
--  EXEC evento.sustitucion_insertar @ff, @xtl, @xsl, 70, 'ST', 2, 'tactico', @id OUTPUT; --> El partido ya está finalizado
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V, NULL, @id OUTPUT; --> Motivo nulo
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V, 'otro', @id OUTPUT; --> Motivo inválido
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V, '', @id OUTPUT; --> Motivo vacio
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, NULL, @V, 'tactico', @id OUTPUT; --> Período nulo
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'XX', @V, 'tactico', @id OUTPUT; --> Período inválido
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, NULL, 'ST', @V, 'tactico', @id OUTPUT; --> Minuto nulo (el mensaje dice "(nulo)")
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 44,  'ST', @V, 'tactico', @id OUTPUT; --> Minuto 44 en ST (borde)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 111, 'ST', @V, 'tactico', @id OUTPUT; --> Minuto 111 en ST (borde)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 89,  'alargue_1', @V1, 'tactico', @id OUTPUT; --> Minuto 89 en alargue_1 (borde)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 116, 'alargue_1', @V1, 'tactico', @id OUTPUT; --> Minuto 116 en alargue_1 (borde)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 104, 'alargue_2', @V1, 'tactico', @id OUTPUT; --> Minuto 104 en alargue_2 (borde)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 136, 'alargue_2', @V1, 'tactico', @id OUTPUT; --> Minuto 136 en alargue_2 (borde)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', NULL, 'tactico', @id OUTPUT; --> Ventana nula
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', 0, 'tactico', @id OUTPUT; --> 2 errores: ventana 0 y orden de ventanas (anterior a la última)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V1, 'tactico', @id OUTPUT; --> Se superan las ventanas reglamentarias (la siguiente a la última, pero fuera de las permitidas)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 80, 'ST', @V2, 'tactico', @id OUTPUT; --> 2 errores: salto de ventana y se superan las reglamentarias
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 30, 'PT', 1, 'tactico', @id OUTPUT; --> Ventana anterior a la última (el mensaje dice "corresponde la V o la V+1")
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gsl, 30, 'PT', @V, 'tactico', @id OUTPUT; --> Ventana V ya usada en otro período (ST)
-- EXEC evento.sustitucion_insertar @fg, @gt1, @gsl, 80, 'ST', @V, 'tactico', @id OUTPUT; --> El que sale ya había sido reemplazado (no está en cancha)
-- EXEC evento.sustitucion_insertar @fg, @gsl, @gsl2, 80, 'ST', @V, 'tactico', @id OUTPUT; --> El que sale es suplente y no ingresó (no está en cancha)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gtl2, 80, 'ST', @V, 'tactico', @id OUTPUT; --> El que entra es titular (no está disponible en el banco)
-- EXEC evento.sustitucion_insertar @fg, @gtl, @gs1, 80, 'ST', @V, 'tactico', @id OUTPUT; --> El que entra ya había ingresado (no disponible en el banco)
-- EXEC evento.sustitucion_insertar @fg, @gt1, @gs1, 44, 'ST', @V, 'otro', @id OUTPUT; --> 4 errores: motivo, minuto, sale ya reemplazado y entra ya ingresado

-- f_alg: máximo de cambios reglamentarios cargado, sin alargue
-- EXEC evento.sustitucion_insertar @fa, @atl, @asl, 80, 'ST', @V, 'tactico', @id OUTPUT; --> Se alcanzó el máximo de cambios en tiempo reglamentario
-- EXEC evento.sustitucion_insertar @fa, @atl, @asl, 100, 'alargue_1', @VW1, 'tactico', @id OUTPUT; --> 2 errores: se superan las ventanas con el adicional del alargue y salto de ventana
-- EXEC evento.sustitucion_insertar @fa, @atl, @asl, 90, 'alargue_1', @V1, 'tactico', @id OUTPUT; --> Valido: primer cambio adicional del alargue, primera ventana adicional, minuto minimo de alargue_1 (borde)

-- f_lim: máximo de cambios reglamentarios + todos los del alargue
-- EXEC evento.sustitucion_insertar @fl, @ltl, @lsl, 100, 'alargue_1', @ul, 'tactico', @id OUTPUT; --> Se alcanzó el máximo de cambios incluyendo el adicional del alargue
-- EXEC evento.sustitucion_insertar @fl, @ltl, @lsl, 110, 'alargue_2', @ul, 'tactico', @id OUTPUT; --> 2 errores: máximo de cambios con alargue y ventana ya usada en otro período (alargue_1)
-- EXEC evento.sustitucion_insertar @fl, @ltl, @lsl, 80, 'ST', @V, 'tactico', @id OUTPUT; --> 2 errores: máximo de cambios reglamentarios y ventana anterior a la última
GO

-- Verificacion evento.sustitucion_modificar
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

EXEC evento.sustitucion_modificar @m1, 25, 'PT', 1, 'lesion'; --> Valido: cambia minuto y motivo

-- EXEC evento.sustitucion_modificar @m1, 1,  'PT', 1, 'tactico'; --> Valido: minuto minimo de PT (borde)
-- EXEC evento.sustitucion_modificar @m1, 60, 'PT', 1, 'precaucion'; --> Valido: minuto maximo de PT (borde)
-- EXEC evento.sustitucion_modificar @m2, 45,  'ST', 2, 'tactico'; --> Valido: minuto minimo de ST (borde)
-- EXEC evento.sustitucion_modificar @m2, 110, 'ST', 2, 'lesion'; --> Valido: minuto maximo de ST (borde)
-- EXEC evento.sustitucion_modificar NULL, 30, 'PT', 1, 'tactico'; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC evento.sustitucion_modificar 999999, 30, 'PT', 1, 'tactico'; --> Sustitución inexistente
-- EXEC evento.sustitucion_modificar @mf, 30, 'PT', 1, 'tactico'; --> El partido ya está finalizado
-- EXEC evento.sustitucion_modificar @m1, 20, 'PT', 1, NULL; --> Motivo nulo
-- EXEC evento.sustitucion_modificar @m1, 20, 'PT', 1, 'otro'; --> Motivo inválido
-- EXEC evento.sustitucion_modificar @m1, 20, 'PT', 1, ''; --> Motivo vacio
-- EXEC evento.sustitucion_modificar @m1, 20, NULL, 1, 'tactico'; --> Período nulo
-- EXEC evento.sustitucion_modificar @m1, 20, 'XX', 1, 'tactico'; --> Período inválido
-- EXEC evento.sustitucion_modificar @m1, NULL, 'PT', 1, 'tactico'; --> Minuto nulo (el mensaje dice "(nulo)")
-- EXEC evento.sustitucion_modificar @m1, 0,   'PT', 1, 'tactico'; --> Minuto 0 en PT (borde)
-- EXEC evento.sustitucion_modificar @m1, 61,  'PT', 1, 'tactico'; --> Minuto 61 en PT (borde)
-- EXEC evento.sustitucion_modificar @m1, 44,  'ST', 1, 'tactico'; --> Minuto 44 en ST (borde)
-- EXEC evento.sustitucion_modificar @m1, 111, 'ST', 1, 'tactico'; --> Minuto 111 en ST (borde)
-- EXEC evento.sustitucion_modificar @m1, 89,  'alargue_1', 1, 'tactico'; --> Minuto 89 en alargue_1 (borde)
-- EXEC evento.sustitucion_modificar @m1, 116, 'alargue_1', 1, 'tactico'; --> Minuto 116 en alargue_1 (borde)
-- EXEC evento.sustitucion_modificar @m1, 104, 'alargue_2', 1, 'tactico'; --> Minuto 104 en alargue_2 (borde)
-- EXEC evento.sustitucion_modificar @m1, 136, 'alargue_2', 1, 'tactico'; --> Minuto 136 en alargue_2 (borde)
-- EXEC evento.sustitucion_modificar @m1, 20, 'PT', NULL, 'tactico'; --> Ventana nula
-- EXEC evento.sustitucion_modificar @m1, 20, 'PT', 0, 'tactico'; --> Ventana 0 (borde)
-- EXEC evento.sustitucion_modificar @m1, 20, 'PT', -1, 'tactico'; --> Ventana negativa
-- EXEC evento.sustitucion_modificar @m2, 60, 'ST', @V1, 'tactico'; --> Se superan las ventanas reglamentarias
-- EXEC evento.sustitucion_modificar @m1, 100, 'alargue_1', @VW1, 'tactico'; --> Se superan las ventanas incluyendo la adicional del alargue
-- EXEC evento.sustitucion_modificar @m1, 20, 'PT', 2, 'tactico'; --> Ventana 2 ya usada en otro período (ST)
-- EXEC evento.sustitucion_modificar @m2, 60, 'ST', 1, 'tactico'; --> Ventana 1 ya usada en otro período (PT)
-- EXEC evento.sustitucion_modificar @mA, 80, 'ST', @V, 'tactico'; --> Pasar un cambio de alargue a reglamentario cuando ya está el máximo reglamentario
-- EXEC evento.sustitucion_modificar @m1, 0, 'PT', 1, 'otro'; --> 2 errores: minuto y motivo
-- EXEC evento.sustitucion_modificar @m1, 0, 'PT', 0, 'otro'; --> 3 errores: minuto, motivo y ventana
-- Fase de grupos: primero registrar un cambio en la formación jug (queda registrado; volver a calcular @mg al ejecutar de nuevo el bloque)
-- EXEC evento.sustitucion_modificar @mg, 95, 'alargue_1', 1, 'tactico'; --> En fase de grupos no hay tiempo suplementario
GO

-- Verificacion evento.sustitucion_eliminar
DECLARE @e1 INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'eli_x1'),
        @e2 INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'eli_x2'),
        @e3 INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'eli_x3'),
        @ef INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'fin_x1'),
        @eg INT = (SELECT sustitucion_id FROM ##test_sustitucion WHERE clave = 'gen_x1');

EXEC evento.sustitucion_eliminar @e1; --> Baja valida: el que ingresó no fue reemplazado ni tiene goles
-- EXEC evento.sustitucion_eliminar @e2; --> El jugador que ingresó fue reemplazado después (x3): ejecutar ANTES de eliminar x3
-- EXEC evento.sustitucion_eliminar @e3; --> Baja valida: cambio posterior sin consecuencias
-- EXEC evento.sustitucion_eliminar @e2; --> Baja valida: ejecutar DESPUES de eliminar x3
-- EXEC evento.sustitucion_eliminar @ef; --> El partido ya está finalizado
-- EXEC evento.sustitucion_eliminar 999999; --> Sustitución inexistente
-- EXEC evento.sustitucion_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC evento.sustitucion_eliminar @eg; --> El jugador que ingresó tiene goles o asistencias en el partido



-- ============================================================
-- 1.10 evento.gol (cada operación actualiza el marcador del partido en la misma transacción)
-- ============================================================

-- Verificacion evento.gol_insertar
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
EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @t2, @id OUTPUT; --> Valido: con asistencia
-- EXEC evento.gol_insertar @fl, @t1, 16, 'jugada', 'PT', NULL, @id OUTPUT; --> Valido: sin asistencia
-- EXEC evento.gol_insertar @fl, @t1, 18, 'penal', 'PT', NULL, @id OUTPUT; --> Valido: tipo penal
-- EXEC evento.gol_insertar @fl, @t1, 19, 'tiro_libre', 'PT', NULL, @id OUTPUT; --> Valido: tipo tiro_libre
-- EXEC evento.gol_insertar @fl, @t1, 20, 'cabezazo', 'PT', @t2, @id OUTPUT; --> Valido: tipo cabezazo
-- EXEC evento.gol_insertar @fl, @t1, 21, 'otro', 'PT', NULL, @id OUTPUT; --> Valido: tipo otro
-- EXEC evento.gol_insertar @fl, @t1, 22, 'en_contra', 'PT', NULL, @id OUTPUT; --> Valido: gol en contra sin asistencia (suma al rival)
-- EXEC evento.gol_insertar @fl, @t1, 1, 'jugada', 'PT', NULL, @id OUTPUT; --> Valido: PT minuto minimo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 45, 'jugada', 'PT', NULL, @id OUTPUT; --> Valido: PT minuto maximo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 46, 'jugada', 'adicional_PT', NULL, @id OUTPUT; --> Valido: adicional_PT minimo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 60, 'jugada', 'adicional_PT', NULL, @id OUTPUT; --> Valido: adicional_PT maximo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 46, 'jugada', 'ST', NULL, @id OUTPUT; --> Valido: ST minimo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 90, 'jugada', 'ST', NULL, @id OUTPUT; --> Valido: ST maximo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 91, 'jugada', 'adicional_ST', NULL, @id OUTPUT; --> Valido: adicional_ST minimo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 110, 'jugada', 'adicional_ST', NULL, @id OUTPUT; --> Valido: adicional_ST maximo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 91, 'jugada', 'alargue_1', NULL, @id OUTPUT; --> Valido: alargue_1 minimo (borde; partido de fase final)
-- EXEC evento.gol_insertar @fl, @t1, 105, 'jugada', 'alargue_1', NULL, @id OUTPUT; --> Valido: alargue_1 maximo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 106, 'jugada', 'alargue_2', NULL, @id OUTPUT; --> Valido: alargue_2 minimo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 120, 'jugada', 'alargue_2', NULL, @id OUTPUT; --> Valido: alargue_2 maximo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 106, 'jugada', 'adicional_alargue', NULL, @id OUTPUT; --> Valido: adicional_alargue minimo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 135, 'jugada', 'adicional_alargue', NULL, @id OUTPUT; --> Valido: adicional_alargue maximo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 120, 'penal', 'penales', NULL, @id OUTPUT; --> Valido: tanda de penales minimo (borde)
-- EXEC evento.gol_insertar @fl, @t1, 135, 'penal', 'penales', NULL, @id OUTPUT; --> Valido: tanda de penales maximo (borde)
-- EXEC evento.gol_insertar @fv, @v1, 30, 'jugada', 'PT', @v2, @id OUTPUT; --> Valido: gol del visitante con asistencia
-- EXEC evento.gol_insertar @fv, @v1, 125, 'penal', 'penales', NULL, @id OUTPUT; --> Valido: penal del visitante en la tanda
-- EXEC evento.gol_insertar @fl, @si, 75, 'jugada', 'ST', NULL, @id OUTPUT; --> Valido: autor suplente que ingreso por sustitucion
-- EXEC evento.gol_insertar @fl, @t1, 76, 'jugada', 'ST', @si, @id OUTPUT; --> Valido: asistente suplente que ingreso
-- EXEC evento.gol_insertar @fl, @t5, 12, 'jugada', 'PT', @t2, @id OUTPUT; --> Valido: autor titular (que luego sale por sustitucion)
-- EXEC evento.gol_insertar @fl, @t1, 13, 'jugada', 'PT', @t5, @id OUTPUT; --> Valido: asistente titular que sale por sustitucion
-- EXEC evento.gol_insertar @fj, @jg, 40, 'jugada', 'ST', @ja, @id OUTPUT; --> Valido: partido de fase de grupos con periodo regular
-- EXEC evento.gol_insertar 999999, @t1, 15, 'jugada', 'PT', NULL, @id OUTPUT; --> Formacion inexistente
-- EXEC evento.gol_insertar NULL, @t1, 15, 'jugada', 'PT', NULL, @id OUTPUT; --> Formacion nula
-- EXEC evento.gol_insertar @fz, @zt, 15, 'jugada', 'PT', NULL, @id OUTPUT; --> Partido finalizado
-- EXEC evento.gol_insertar @fl, 999999, 15, 'jugada', 'PT', NULL, @id OUTPUT; --> Jugador inexistente (el autor no integra la formacion)
-- EXEC evento.gol_insertar @fl, NULL, 15, 'jugada', 'PT', NULL, @id OUTPUT; --> Jugador nulo (el autor no integra la formacion)
-- EXEC evento.gol_insertar @fl, @lf, 15, 'jugada', 'PT', NULL, @id OUTPUT; --> Autor convocado pero que no integra la formacion
-- EXEC evento.gol_insertar @fl, @v1, 15, 'jugada', 'PT', NULL, @id OUTPUT; --> Autor que integra la formacion del rival
-- EXEC evento.gol_insertar @fl, @so, 15, 'jugada', 'PT', NULL, @id OUTPUT; --> Autor suplente sin sustitucion registrada (no ingreso)
-- EXEC evento.gol_insertar @fl, @t1, 15, NULL, 'PT', NULL, @id OUTPUT; --> Tipo de gol nulo
-- EXEC evento.gol_insertar @fl, @t1, 15, '', 'PT', NULL, @id OUTPUT; --> Tipo de gol vacio
-- EXEC evento.gol_insertar @fl, @t1, 15, 'otro_tipo', 'PT', NULL, @id OUTPUT; --> Tipo de gol invalido
-- EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', NULL, NULL, @id OUTPUT; --> Periodo nulo
-- EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', '', NULL, @id OUTPUT; --> Periodo vacio
-- EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT2', NULL, @id OUTPUT; --> Periodo invalido (no se valida el minuto)
-- EXEC evento.gol_insertar @fl, @t1, NULL, 'jugada', 'PT', NULL, @id OUTPUT; --> Minuto nulo
-- EXEC evento.gol_insertar @fl, @t1, -1, 'jugada', 'PT', NULL, @id OUTPUT; --> Minuto negativo
-- EXEC evento.gol_insertar @fl, @t1, 0, 'jugada', 'PT', NULL, @id OUTPUT; --> PT minuto 0 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 46, 'jugada', 'PT', NULL, @id OUTPUT; --> PT minuto 46 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 45, 'jugada', 'adicional_PT', NULL, @id OUTPUT; --> adicional_PT minuto 45 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 61, 'jugada', 'adicional_PT', NULL, @id OUTPUT; --> adicional_PT minuto 61 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 45, 'jugada', 'ST', NULL, @id OUTPUT; --> ST minuto 45 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 91, 'jugada', 'ST', NULL, @id OUTPUT; --> ST minuto 91 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 90, 'jugada', 'adicional_ST', NULL, @id OUTPUT; --> adicional_ST minuto 90 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 111, 'jugada', 'adicional_ST', NULL, @id OUTPUT; --> adicional_ST minuto 111 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 90, 'jugada', 'alargue_1', NULL, @id OUTPUT; --> alargue_1 minuto 90 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 106, 'jugada', 'alargue_1', NULL, @id OUTPUT; --> alargue_1 minuto 106 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 105, 'jugada', 'alargue_2', NULL, @id OUTPUT; --> alargue_2 minuto 105 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 121, 'jugada', 'alargue_2', NULL, @id OUTPUT; --> alargue_2 minuto 121 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 105, 'jugada', 'adicional_alargue', NULL, @id OUTPUT; --> adicional_alargue minuto 105 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 136, 'jugada', 'adicional_alargue', NULL, @id OUTPUT; --> adicional_alargue minuto 136 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 119, 'penal', 'penales', NULL, @id OUTPUT; --> penales minuto 119 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 136, 'penal', 'penales', NULL, @id OUTPUT; --> penales minuto 136 (borde)
-- EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @t1, @id OUTPUT; --> El asistente es el mismo autor
-- EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', 999999, @id OUTPUT; --> Asistente inexistente (no integra la formacion)
-- EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @lf, @id OUTPUT; --> Asistente que no integra la formacion
-- EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @v1, @id OUTPUT; --> Asistente de la formacion rival
-- EXEC evento.gol_insertar @fl, @t1, 15, 'jugada', 'PT', @so, @id OUTPUT; --> Asistente suplente que no ingreso
-- EXEC evento.gol_insertar @fl, @t1, 15, 'en_contra', 'PT', @t2, @id OUTPUT; --> Gol en contra con asistencia
-- EXEC evento.gol_insertar @fl, @t1, 120, 'penal', 'penales', @t2, @id OUTPUT; --> Gol de la tanda de penales con asistencia
-- EXEC evento.gol_insertar @fl, @t1, 120, 'jugada', 'penales', NULL, @id OUTPUT; --> Tanda de penales con tipo distinto de penal
-- EXEC evento.gol_insertar @fl, @t1, 120, 'en_contra', 'penales', NULL, @id OUTPUT; --> Tanda de penales con gol en contra
-- EXEC evento.gol_insertar @fj, @jg, 120, 'penal', 'penales', NULL, @id OUTPUT; --> Fase de grupos: tanda de penales
-- EXEC evento.gol_insertar @fl, @t1, 15, 'otro_tipo', 'PT2', NULL, @id OUTPUT; --> 2 errores: tipo de gol y periodo invalidos
-- EXEC evento.gol_insertar @fj, @jg, 100, 'jugada', 'penales', NULL, @id OUTPUT; --> 3 errores: fase de grupos con penales, minuto y tipo distinto de penal
-- EXEC evento.gol_insertar @fl, @so, 20, 'en_contra', 'PT', @so, @id OUTPUT; --> 4 errores: autor sin ingresar, asistente = autor, asistente sin ingresar y gol en contra con asistencia
 EXEC evento.gol_insertar @fz, @lf, 0, 'otro_tipo', 'PT', @lf, @id OUTPUT; --> 6 errores: finalizado, tipo, minuto, autor no integra, asistente = autor y asistente no integra
GO

-- Verificacion evento.gol_modificar
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
EXEC evento.gol_modificar @gm, 12, 'cabezazo', 'PT', @t2; --> Valido: cambia minuto y tipo 
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @t3; --> Valido: cambia el asistente
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @si; --> Valido: asistente suplente que ingreso por sustitucion
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @t5; --> Valido: asistente titular que sale por sustitucion
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', NULL; --> Valido: quita la asistencia
-- EXEC evento.gol_modificar NULL, 10, 'jugada', 'PT'; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC evento.gol_modificar 999999, 10, 'jugada', 'PT'; --> Gol inexistente
-- EXEC evento.gol_modificar @gf, 12, 'jugada', 'PT'; --> Partido finalizado
-- EXEC evento.gol_modificar @gm, 10, NULL, 'PT'; --> Tipo de gol nulo
-- EXEC evento.gol_modificar @gm, 10, '', 'PT'; --> Tipo de gol vacio
-- EXEC evento.gol_modificar @gm, 10, 'otro_tipo', 'PT'; --> Tipo de gol invalido
-- EXEC evento.gol_modificar @gm, 10, 'jugada', NULL; --> Periodo nulo
-- EXEC evento.gol_modificar @gm, 10, 'jugada', ''; --> Periodo vacio
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT2'; --> Periodo invalido (no se valida el minuto)
-- EXEC evento.gol_modificar @gm, NULL, 'jugada', 'PT'; --> Minuto nulo
-- EXEC evento.gol_modificar @gm, -1, 'jugada', 'PT'; --> Minuto negativo
-- EXEC evento.gol_modificar @gm, 0, 'jugada', 'PT'; --> PT minuto 0 (borde)
-- EXEC evento.gol_modificar @gm, 46, 'jugada', 'PT'; --> PT minuto 46 (borde)
-- EXEC evento.gol_modificar @gm, 45, 'jugada', 'adicional_PT'; --> adicional_PT minuto 45 (borde)
-- EXEC evento.gol_modificar @gm, 61, 'jugada', 'adicional_PT'; --> adicional_PT minuto 61 (borde)
-- EXEC evento.gol_modificar @gm, 45, 'jugada', 'ST'; --> ST minuto 45 (borde)
-- EXEC evento.gol_modificar @gm, 91, 'jugada', 'ST'; --> ST minuto 91 (borde)
-- EXEC evento.gol_modificar @gm, 90, 'jugada', 'adicional_ST'; --> adicional_ST minuto 90 (borde)
-- EXEC evento.gol_modificar @gm, 111, 'jugada', 'adicional_ST'; --> adicional_ST minuto 111 (borde)
-- EXEC evento.gol_modificar @gm, 90, 'jugada', 'alargue_1'; --> alargue_1 minuto 90 (borde)
-- EXEC evento.gol_modificar @gm, 106, 'jugada', 'alargue_1'; --> alargue_1 minuto 106 (borde)
-- EXEC evento.gol_modificar @gm, 105, 'jugada', 'alargue_2'; --> alargue_2 minuto 105 (borde)
-- EXEC evento.gol_modificar @gm, 121, 'jugada', 'alargue_2'; --> alargue_2 minuto 121 (borde)
-- EXEC evento.gol_modificar @gm, 105, 'jugada', 'adicional_alargue'; --> adicional_alargue minuto 105 (borde)
-- EXEC evento.gol_modificar @gm, 136, 'jugada', 'adicional_alargue'; --> adicional_alargue minuto 136 (borde)
-- EXEC evento.gol_modificar @gp, 119, 'penal', 'penales'; --> penales minuto 119 (borde)
-- EXEC evento.gol_modificar @gp, 136, 'penal', 'penales'; --> penales minuto 136 (borde)
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @t1; --> El asistente es el mismo autor
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', 999999; --> Asistente inexistente (no integra la formacion)
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @lf; --> Asistente que no integra la formacion
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @v1; --> Asistente de la formacion rival
-- EXEC evento.gol_modificar @gm, 10, 'jugada', 'PT', @so; --> Asistente suplente que no ingreso
-- EXEC evento.gol_modificar @gm, 10, 'en_contra', 'PT', @t2; --> Gol en contra con asistencia
-- EXEC evento.gol_modificar @gp, 125, 'penal', 'penales', @t1; --> Gol de la tanda de penales con asistencia
-- EXEC evento.gol_modificar @gp, 125, 'jugada', 'penales'; --> Tanda de penales con tipo distinto de penal
-- EXEC evento.gol_modificar @gp, 125, 'en_contra', 'penales'; --> Tanda de penales con gol en contra
-- EXEC evento.gol_modificar @gj, 100, 'jugada', 'alargue_1'; --> Fase de grupos: alargue_1
-- EXEC evento.gol_modificar @gj, 110, 'jugada', 'alargue_2'; --> Fase de grupos: alargue_2
-- EXEC evento.gol_modificar @gj, 110, 'jugada', 'adicional_alargue'; --> Fase de grupos: adicional_alargue
-- EXEC evento.gol_modificar @gj, 120, 'penal', 'penales'; --> Fase de grupos: tanda de penales
-- EXEC evento.gol_modificar @gm, NULL, NULL, NULL; --> 2 errores: tipo de gol y periodo (el minuto no se valida sin periodo)
-- EXEC evento.gol_modificar @gm, 0, 'otro_tipo', 'PT', @t1; --> 3 errores: tipo, minuto y asistente = autor
-- EXEC evento.gol_modificar @gj, 100, 'jugada', 'penales'; --> 3 errores: fase de grupos con penales, minuto y tipo distinto de penal
-- EXEC evento.gol_modificar @gm, 50, 'en_contra', 'penales', @t1; --> 5 errores: minuto, asistente = autor, gol en contra con asistencia, penales con asistencia y tipo distinto de penal
GO

-- Verificacion evento.gol_eliminar
DECLARE @ge1 INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_elim'),
        @ge2 INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_elim2'),
        @ge3 INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_elim3'),
        @ge4 INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_elim4'),
        @gf  INT = (SELECT gol_id FROM ##test_gol WHERE clave = 'g_fin');
EXEC evento.gol_eliminar @ge1; --> Baja valida: gol con asistencia de un partido no finalizado (baja el marcador local)
-- EXEC evento.gol_eliminar @ge2; --> Baja valida: gol sin asistencia (cabezazo)
-- EXEC evento.gol_eliminar @ge3; --> Baja valida: gol en contra (baja el marcador del rival)
-- EXEC evento.gol_eliminar @ge4; --> Baja valida: gol de la tanda de penales (baja los penales del visitante)
-- EXEC evento.gol_eliminar 999999; --> Gol inexistente
-- EXEC evento.gol_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC evento.gol_eliminar @gf; --> Partido finalizado
GO


-- ============================================================
-- 1.11 evento.tarjeta, evento.criterio_suspension y evento.suspension
-- ============================================================
-- Verificacion evento.tarjeta_insertar
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
EXEC evento.tarjeta_insertar @pt, @l1, 15, 'PT', 'amarilla', 'Falta', NULL, @id OUTPUT; --> Valido: amarilla con motivo
-- EXEC evento.tarjeta_insertar @pt, @l2, 16, 'PT', 'amarilla', '  Motivo con espacios  ', NULL, @id OUTPUT; --> Valido: motivo se guarda recortado
-- EXEC evento.tarjeta_insertar @pt, @l3, 17, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Valido: motivo nulo
-- EXEC evento.tarjeta_insertar @pt, @l4, 18, 'PT', 'amarilla', '', NULL, @id OUTPUT; --> Valido: motivo vacio se guarda como NULL
-- EXEC evento.tarjeta_insertar @pt, @l5, 19, 'PT', 'amarilla', '   ', NULL, @id OUTPUT; --> Valido: motivo solo espacios se guarda como NULL
-- EXEC evento.tarjeta_insertar @pt, @l6, 20, 'PT', 'amarilla', @tarjeta_id = @id OUTPUT; --> Valido: sin pasar motivo ni tipo de expulsion (valores por defecto)
-- EXEC evento.tarjeta_insertar @pt, @l7, 50, 'ST', 'roja', 'Agresion', 'roja_directa', @id OUTPUT; --> Valido: roja directa con motivo
-- EXEC evento.tarjeta_insertar @pt, @l8, 51, 'ST', 'roja', NULL, 'roja_directa', @id OUTPUT; --> Valido: roja directa sin motivo
-- EXEC evento.tarjeta_insertar @pt, @a1, 70, 'ST', 'roja', 'Segunda amarilla', 'doble_amarilla', @id OUTPUT; --> Valido: segunda amarilla registrada como roja (la persona tiene una amarilla previa)
-- EXEC evento.tarjeta_insertar @pt, @a2, 71, 'ST', 'roja', 'Agresion', 'roja_directa', @id OUTPUT; --> Valido: roja directa a quien ya tenia una amarilla
-- EXEC evento.tarjeta_insertar @pt, @l9, 1, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Valido: PT minuto minimo (borde)
-- EXEC evento.tarjeta_insertar @pt, @l10, 45, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Valido: PT minuto maximo (borde)
-- EXEC evento.tarjeta_insertar 999999, @le, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> 2 errores: partido inexistente y la persona no participa del partido
-- EXEC evento.tarjeta_insertar NULL, @le, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> 2 errores: partido nulo y la persona no participa del partido
-- EXEC evento.tarjeta_insertar @pz, @zl, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Partido finalizado
-- EXEC evento.tarjeta_insertar @pt, 999999, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Persona inexistente
-- EXEC evento.tarjeta_insertar @pt, NULL, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Persona nula
-- EXEC evento.tarjeta_insertar @pt, @np, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Persona que existe pero no participa del partido
-- EXEC evento.tarjeta_insertar @pt, @cn, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Persona que participa de otro partido (formacion jug del partido mod) pero no de este
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', NULL, NULL, NULL, @id OUTPUT; --> Tipo nulo
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', '', NULL, NULL, @id OUTPUT; --> Tipo vacio
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'verde', NULL, NULL, @id OUTPUT; --> Tipo invalido
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'amarilla', NULL, 'roja_directa', @id OUTPUT; --> Amarilla con tipo de expulsion
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'amarilla', NULL, 'doble_amarilla', @id OUTPUT; --> Amarilla con tipo de expulsion (doble_amarilla)
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'roja', NULL, NULL, @id OUTPUT; --> Roja sin tipo de expulsion (nulo)
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'roja', NULL, '', @id OUTPUT; --> Roja con tipo de expulsion vacio
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'roja', NULL, 'otra', @id OUTPUT; --> Roja con tipo de expulsion invalido
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT', 'roja', NULL, 'doble_amarilla', @id OUTPUT; --> Doble amarilla sin amarilla previa
-- EXEC evento.tarjeta_insertar @pt, @ea, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> La persona ya tiene una amarilla en el partido
-- EXEC evento.tarjeta_insertar @pt, @rj, 15, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> La persona ya fue expulsada (roja directa)
-- EXEC evento.tarjeta_insertar @pt, @rj, 15, 'PT', 'roja', NULL, 'roja_directa', @id OUTPUT; --> La persona ya fue expulsada: nueva roja
-- EXEC evento.tarjeta_insertar @pt, @dob, 15, 'PT', 'roja', NULL, 'doble_amarilla', @id OUTPUT; --> La persona ya fue expulsada por doble amarilla (tiene la amarilla previa)
-- EXEC evento.tarjeta_insertar @pt, @dob, 15, 'PT', 'roja', NULL, 'roja_directa', @id OUTPUT; --> La persona ya fue expulsada (tenia amarilla y roja)
-- EXEC evento.tarjeta_insertar @pt, @le, 15, NULL, 'amarilla', NULL, NULL, @id OUTPUT; --> Periodo nulo
-- EXEC evento.tarjeta_insertar @pt, @le, 15, '', 'amarilla', NULL, NULL, @id OUTPUT; --> Periodo vacio
-- EXEC evento.tarjeta_insertar @pt, @le, 15, 'PT2', 'amarilla', NULL, NULL, @id OUTPUT; --> Periodo invalido (no se valida el minuto)
-- EXEC evento.tarjeta_insertar @pt, @le, NULL, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Minuto nulo
-- EXEC evento.tarjeta_insertar @pt, @le, -1, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> Minuto negativo
-- EXEC evento.tarjeta_insertar @pt, @le, 0, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> PT minuto 0 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 46, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> PT minuto 46 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 45, 'adicional_PT', 'amarilla', NULL, NULL, @id OUTPUT; --> adicional_PT minuto 45 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 61, 'adicional_PT', 'amarilla', NULL, NULL, @id OUTPUT; --> adicional_PT minuto 61 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 45, 'ST', 'amarilla', NULL, NULL, @id OUTPUT; --> ST minuto 45 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 91, 'ST', 'amarilla', NULL, NULL, @id OUTPUT; --> ST minuto 91 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 90, 'adicional_ST', 'amarilla', NULL, NULL, @id OUTPUT; --> adicional_ST minuto 90 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 111, 'adicional_ST', 'amarilla', NULL, NULL, @id OUTPUT; --> adicional_ST minuto 111 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 90, 'alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; --> alargue_1 minuto 90 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 106, 'alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; --> alargue_1 minuto 106 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 105, 'adicional_alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; --> adicional_alargue_1 minuto 105 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 116, 'adicional_alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; --> adicional_alargue_1 minuto 116 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 105, 'alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; --> alargue_2 minuto 105 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 121, 'alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; --> alargue_2 minuto 121 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 120, 'adicional_alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; --> adicional_alargue_2 minuto 120 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 136, 'adicional_alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; --> adicional_alargue_2 minuto 136 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 119, 'penales', 'amarilla', NULL, NULL, @id OUTPUT; --> penales minuto 119 (borde)
-- EXEC evento.tarjeta_insertar @pt, @le, 136, 'penales', 'amarilla', NULL, NULL, @id OUTPUT; --> penales minuto 136 (borde)
-- EXEC evento.tarjeta_insertar @pm, @cn, 100, 'alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; --> Fase de grupos: alargue_1
-- EXEC evento.tarjeta_insertar @pm, @cn, 110, 'adicional_alargue_1', 'amarilla', NULL, NULL, @id OUTPUT; --> Fase de grupos: adicional_alargue_1
-- EXEC evento.tarjeta_insertar @pm, @cn, 110, 'alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; --> Fase de grupos: alargue_2
-- EXEC evento.tarjeta_insertar @pm, @cn, 125, 'adicional_alargue_2', 'amarilla', NULL, NULL, @id OUTPUT; --> Fase de grupos: adicional_alargue_2
-- EXEC evento.tarjeta_insertar @pm, @cn, 125, 'penales', 'amarilla', NULL, NULL, @id OUTPUT; --> Fase de grupos: tanda de penales
-- EXEC evento.tarjeta_insertar NULL, NULL, NULL, NULL, NULL, NULL, NULL, @id OUTPUT; --> 4 errores: partido, periodo, persona y tipo (todo nulo)
-- EXEC evento.tarjeta_insertar @pz, @zl, 0, 'PT', 'amarilla', NULL, NULL, @id OUTPUT; --> 2 errores: partido finalizado y minuto
-- EXEC evento.tarjeta_insertar @pt, @dob, 15, 'PT', 'amarilla', NULL, 'doble_amarilla', @id OUTPUT; --> 3 errores: amarilla con tipo de expulsion, persona ya expulsada y ya tiene una amarilla
GO

-- Verificacion evento.tarjeta_modificar
DECLARE @tm  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_mod'),
        @tmr INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_modr'),
        @tj  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_jug'),
        @tf  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_fin');
EXEC evento.tarjeta_modificar @tm, 12, 'PT', 'Falta tactica'; --> Valido: cambia minuto y motivo
-- EXEC evento.tarjeta_modificar @tm, 10, 'PT', 'Falta'; --> Valido: sin cambios (deja la tarjeta como en la preparacion)
-- EXEC evento.tarjeta_modificar @tm, 50, 'ST', 'Falta'; --> Valido: cambia el periodo (restaurar con el caso anterior)
-- EXEC evento.tarjeta_modificar @tm, 10, 'PT', '  Motivo  '; --> Valido: motivo se guarda recortado
-- EXEC evento.tarjeta_modificar NULL, 10, 'PT'; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC evento.tarjeta_modificar 999999, 10, 'PT'; --> Tarjeta inexistente
-- EXEC evento.tarjeta_modificar @tf, 12, 'PT'; --> Partido finalizado
-- EXEC evento.tarjeta_modificar @tm, 10, NULL; --> Periodo nulo
-- EXEC evento.tarjeta_modificar @tm, 10, ''; --> Periodo vacio
-- EXEC evento.tarjeta_modificar @tm, 10, 'PT2'; --> Periodo invalido (no se valida el minuto)
-- EXEC evento.tarjeta_modificar @tm, NULL, 'PT'; --> Minuto nulo
-- EXEC evento.tarjeta_modificar @tm, -1, 'PT'; --> Minuto negativo
-- EXEC evento.tarjeta_modificar @tm, 0, 'PT'; --> PT minuto 0 (borde)
-- EXEC evento.tarjeta_modificar @tm, 46, 'PT'; --> PT minuto 46 (borde)
-- EXEC evento.tarjeta_modificar @tm, 45, 'adicional_PT'; --> adicional_PT minuto 45 (borde)
-- EXEC evento.tarjeta_modificar @tm, 61, 'adicional_PT'; --> adicional_PT minuto 61 (borde)
-- EXEC evento.tarjeta_modificar @tm, 45, 'ST'; --> ST minuto 45 (borde)
-- EXEC evento.tarjeta_modificar @tm, 91, 'ST'; --> ST minuto 91 (borde)
-- EXEC evento.tarjeta_modificar @tm, 90, 'adicional_ST'; --> adicional_ST minuto 90 (borde)
-- EXEC evento.tarjeta_modificar @tm, 111, 'adicional_ST'; --> adicional_ST minuto 111 (borde)
-- EXEC evento.tarjeta_modificar @tm, 90, 'alargue_1'; --> alargue_1 minuto 90 (borde)
-- EXEC evento.tarjeta_modificar @tm, 106, 'alargue_1'; --> alargue_1 minuto 106 (borde)
-- EXEC evento.tarjeta_modificar @tm, 105, 'adicional_alargue_1'; --> adicional_alargue_1 minuto 105 (borde)
-- EXEC evento.tarjeta_modificar @tm, 116, 'adicional_alargue_1'; --> adicional_alargue_1 minuto 116 (borde)
-- EXEC evento.tarjeta_modificar @tm, 105, 'alargue_2'; --> alargue_2 minuto 105 (borde)
-- EXEC evento.tarjeta_modificar @tm, 121, 'alargue_2'; --> alargue_2 minuto 121 (borde)
-- EXEC evento.tarjeta_modificar @tm, 120, 'adicional_alargue_2'; --> adicional_alargue_2 minuto 120 (borde)
-- EXEC evento.tarjeta_modificar @tm, 136, 'adicional_alargue_2'; --> adicional_alargue_2 minuto 136 (borde)
-- EXEC evento.tarjeta_modificar @tm, 119, 'penales'; --> penales minuto 119 (borde)
-- EXEC evento.tarjeta_modificar @tm, 136, 'penales'; --> penales minuto 136 (borde)
-- EXEC evento.tarjeta_modificar @tj, 100, 'alargue_1'; --> Fase de grupos: alargue_1
-- EXEC evento.tarjeta_modificar @tj, 110, 'adicional_alargue_1'; --> Fase de grupos: adicional_alargue_1
-- EXEC evento.tarjeta_modificar @tj, 110, 'alargue_2'; --> Fase de grupos: alargue_2
-- EXEC evento.tarjeta_modificar @tj, 125, 'adicional_alargue_2'; --> Fase de grupos: adicional_alargue_2
-- EXEC evento.tarjeta_modificar @tj, 125, 'penales'; --> Fase de grupos: tanda de penales
-- EXEC evento.tarjeta_modificar @tf, 0, 'PT'; --> 2 errores: partido finalizado y minuto
-- EXEC evento.tarjeta_modificar @tf, NULL, NULL; --> 2 errores: partido finalizado y periodo nulo
GO

-- Verificacion evento.tarjeta_eliminar
DECLARE @te  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_elim'),
        @te2 INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_elim2'),
        @tda INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_dob_a'),
        @tdr INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_dob_r'),
        @tf  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_fin'),
        @ts  INT = (SELECT tarjeta_id FROM ##test_tarjeta WHERE clave = 't_susp');
EXEC evento.tarjeta_eliminar @te; --> Baja valida: amarilla de un partido no finalizado, sin suspensiones
-- EXEC evento.tarjeta_eliminar @te2; --> Baja valida: roja directa sin suspensiones
-- EXEC evento.tarjeta_eliminar @tda; --> Es la primera amarilla de una expulsion por doble amarilla (ejecutar ANTES de dar de baja la roja)
-- EXEC evento.tarjeta_eliminar @tdr; --> Baja valida: roja por doble amarilla
-- EXEC evento.tarjeta_eliminar @tda; --> Baja valida: la amarilla ya no tiene la roja por doble amarilla (ejecutar DESPUES de dar de baja la roja)
-- EXEC evento.tarjeta_eliminar 999999; --> Tarjeta inexistente
-- EXEC evento.tarjeta_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC evento.tarjeta_eliminar @tf; --> Partido finalizado
GO

-- Verificacion evento.criterio_suspension_insertar
DECLARE @id INT;
EXEC evento.criterio_suspension_insertar 92, 1, 'grupos', 'jugador', 1, @id OUTPUT; --> Valido: criterio con fase y tipo de persona
-- EXEC evento.criterio_suspension_insertar 95, 1, 'grupos', NULL, 1, @id OUTPUT; --> Valido: fase grupos
-- EXEC evento.criterio_suspension_insertar 95, 1, 'dieciseisavos', NULL, 1, @id OUTPUT; --> Valido: fase dieciseisavos
-- EXEC evento.criterio_suspension_insertar 95, 1, 'semifinal', NULL, 1, @id OUTPUT; --> Valido: fase semifinal
-- EXEC evento.criterio_suspension_insertar 95, 1, 'tercer_puesto', NULL, 1, @id OUTPUT; --> Valido: fase tercer_puesto
-- EXEC evento.criterio_suspension_insertar 95, 1, 'final', NULL, 1, @id OUTPUT; --> Valido: fase final
-- EXEC evento.criterio_suspension_insertar 98, 1, 'preliminar', NULL, 1, @id OUTPUT; --> Fase invalida
-- EXEC evento.criterio_suspension_insertar 98, 1, '', NULL, 1, @id OUTPUT; --> Fase vacia (vacio no es NULL: es invalida)
-- EXEC evento.criterio_suspension_insertar 98, 1, 'grupos', 'arbitro', 1, @id OUTPUT; --> Tipo de persona invalido
-- EXEC evento.criterio_suspension_insertar 98, 1, 'grupos', 'jugadores', 1, @id OUTPUT; --> Tipo de persona invalido (plural)
-- EXEC evento.criterio_suspension_insertar NULL, 1, 'grupos', 'jugador', 1, @id OUTPUT; --> Cantidad de amarillas nula
-- EXEC evento.criterio_suspension_insertar 0, 1, 'grupos', 'jugador', 1, @id OUTPUT; --> Cantidad de amarillas 0 (borde)
-- EXEC evento.criterio_suspension_insertar -1, 1, 'grupos', 'jugador', 1, @id OUTPUT; --> Cantidad de amarillas negativa
-- EXEC evento.criterio_suspension_insertar 98, NULL, 'grupos', 'jugador', 1, @id OUTPUT; --> Partidos de suspension nulos
-- EXEC evento.criterio_suspension_insertar 98, -1, 'grupos', 'jugador', 1, @id OUTPUT; --> Partidos de suspension negativos
-- EXEC evento.criterio_suspension_insertar 90, 1, 'semifinal', 'jugador', 1, @id OUTPUT; --> Duplicado de 'dup'
-- EXEC evento.criterio_suspension_insertar 90, 1, NULL, NULL, 1, @id OUTPUT; --> Duplicado de 'base_null' (fase y tipo NULL)
-- EXEC evento.criterio_suspension_insertar 0, 0, 'preliminar', 'arbitro', 1, @id OUTPUT; --> 4 errores: fase, tipo, cantidad y partidos
-- EXEC evento.criterio_suspension_insertar 90, 0, 'semifinal', 'jugador', 1, @id OUTPUT; --> 2 errores: partidos de suspension y duplicado de 'dup'
-- EXEC evento.criterio_suspension_insertar 90, 0, '', NULL, 1, @id OUTPUT; --> 3 errores: fase invalida, partidos y duplicado de 'base_null'
-- EXEC evento.criterio_suspension_insertar 90, 0, '', '', 1, @id OUTPUT; --> 4 errores: fase, tipo, partidos y duplicado de 'base_null'
GO

-- Verificacion evento.criterio_suspension_modificar
DECLARE @cm  INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'mod'),
        @cu  INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'usado');
EXEC evento.criterio_suspension_modificar @cm, 90, 3, 'grupos', 'jugador', 1; --> Valido: cambia los partidos de suspension
-- EXEC evento.criterio_suspension_modificar @cm, 90, 1, 'grupos', 'jugador', 1; --> Valido: sin cambios (no choca consigo mismo; deja el criterio como en la preparacion)
-- EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'grupos', 'jugador', 1; --> Valido: cambia la cantidad de amarillas
-- EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'octavos', 'jugador', 1; --> Valido: cambia la fase
-- EXEC evento.criterio_suspension_modificar NULL, 85, 1, 'grupos', 'jugador', 1; --> Id nulo
-- EXEC evento.criterio_suspension_modificar 999999, 85, 1, 'grupos', 'jugador', 1; --> Criterio inexistente
-- EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'preliminar', NULL, 1; --> Fase invalida
-- EXEC evento.criterio_suspension_modificar @cm, 80, 1, '', NULL, 1; --> Fase vacia (vacio no es NULL: es invalida)
-- EXEC evento.criterio_suspension_modificar @cm, 80, 1, 'grupos', 'arbitro', 1; --> Tipo de persona invalido
-- EXEC evento.criterio_suspension_modificar @cm, NULL, 1, 'grupos', 'jugador', 1; --> Cantidad de amarillas nula
-- EXEC evento.criterio_suspension_modificar @cm, 0, 1, 'grupos', 'jugador', 1; --> Cantidad de amarillas 0 (borde)
-- EXEC evento.criterio_suspension_modificar @cm, -1, 1, 'grupos', 'jugador', 1; --> Cantidad de amarillas negativa
-- EXEC evento.criterio_suspension_modificar @cm, 80, NULL, 'grupos', 'jugador', 1; --> Partidos de suspension nulos
-- EXEC evento.criterio_suspension_modificar @cm, 80, 0, 'grupos', 'jugador', 1; --> Partidos de suspension 0 (borde)
-- EXEC evento.criterio_suspension_modificar @cm, 80, -1, 'grupos', 'jugador', 1; --> Partidos de suspension negativos
-- EXEC evento.criterio_suspension_modificar @cm, 90, 5, 'semifinal', 'jugador', 0; --> Duplicado de 'dup' (distintos partidos y activo no evitan el duplicado)
-- EXEC evento.criterio_suspension_modificar NULL, NULL, NULL, NULL, NULL, NULL; --> 3 errores: id nulo, cantidad y partidos (todo nulo)
-- EXEC evento.criterio_suspension_modificar 999999, 0, 0, 'preliminar', 'arbitro', 1; --> 5 errores: criterio inexistente, fase, tipo, cantidad y partidos
-- EXEC evento.criterio_suspension_modificar @cm, 90, 0, 'semifinal', 'jugador', 1; --> 2 errores: partidos y duplicado de 'dup'
-- EXEC evento.criterio_suspension_modificar @cm, 90, 0, '', '', 1; --> 4 errores: fase, tipo, partidos y duplicado de 'base_null'
GO

-- Verificacion evento.criterio_suspension_eliminar
DECLARE @ce  INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'elim'),
        @ce2 INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'elim2'),
        @cu  INT = (SELECT criterio_id FROM ##test_criterio WHERE clave = 'usado');
EXEC evento.criterio_suspension_eliminar @ce; --> Baja valida: criterio activo sin suspensiones
-- EXEC evento.criterio_suspension_eliminar @ce2; --> Baja valida: criterio inactivo sin suspensiones
-- EXEC evento.criterio_suspension_eliminar @ce; --> Criterio inexistente (ya dado de baja; ejecutar despues de la baja valida)
-- EXEC evento.criterio_suspension_eliminar 999999; --> Criterio inexistente
-- EXEC evento.criterio_suspension_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
GO

-- ============================================================
-- 1.12 arbitraje: arbitro, arbitro_idioma, designacion_arbitral e informe_arbitral
-- ============================================================

-- Verificacion arbitraje.arbitro_insertar
DECLARE @pa INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pais_a'),
        @pb INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pais_b'),
        @hoy DATE = CAST(SYSDATETIME() AS DATE), @x INT;
DECLARE @f18 DATE = DATEADD(YEAR, -18, @hoy),            
        @f70 DATE = DATEADD(YEAR, -70, @hoy),            
        @f17 DATE = DATEADD(DAY, 1, DATEADD(YEAR, -18, @hoy)),    -- 17 años y 364 dias
        @f71 DATE = DATEADD(DAY, -1, DATEADD(YEAR, -70, @hoy));   -- 70 años y 1 dia
EXEC arbitraje.arbitro_insertar 'Test Arb', 'Ins Uno', @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> Valido
-- EXEC arbitraje.arbitro_insertar '', 'Ins Err', @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> Nombre vacio
-- EXEC arbitraje.arbitro_insertar NULL, 'Ins Err', @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> Nombre nulo
-- EXEC arbitraje.arbitro_insertar '   ', 'Ins Err', @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> Nombre solo espacios
-- EXEC arbitraje.arbitro_insertar 'Test Arb', '', @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> Apellido vacio
-- EXEC arbitraje.arbitro_insertar 'Test Arb', NULL, @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> Apellido nulo
-- EXEC arbitraje.arbitro_insertar 'Test Arb', '   ', @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> Apellido solo espacios
-- EXEC arbitraje.arbitro_insertar 'Test Arb', 'Ins Err', @pa, 'FIFA', @f17, @x OUTPUT; --> Menor de 18 años (por un dia)
-- EXEC arbitraje.arbitro_insertar 'Test Arb', 'Ins Err', @pa, 'FIFA', @f71, @x OUTPUT; --> Mayor de 70 años (por un dia)
-- EXEC arbitraje.arbitro_insertar 'Test Arb', 'Ins Err', 999999, 'FIFA', '1985-05-10', @x OUTPUT; --> Pais inexistente
-- EXEC arbitraje.arbitro_insertar 'Test Arb', 'Ins Err', NULL, 'FIFA', '1985-05-10', @x OUTPUT; --> Pais nulo (el mensaje dice "(nulo)")
-- EXEC arbitraje.arbitro_insertar 'Test Arb', 'Ins Err', @pa, 'otra', '1985-05-10', @x OUTPUT; --> Categoria invalida
-- EXEC arbitraje.arbitro_insertar 'Test Arb', 'Ins Err', @pa, NULL, '1985-05-10', @x OUTPUT; --> Categoria nula
-- EXEC arbitraje.arbitro_insertar 'Test Arb', 'Ins Err', @pa, '', '1985-05-10', @x OUTPUT; --> Categoria vacia
-- EXEC arbitraje.arbitro_insertar 'Test Arb', 'Base', @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> Ya existe un arbitro con ese nombre y apellido para ese pais
-- EXEC arbitraje.arbitro_insertar '', '', @pa, 'FIFA', '1985-05-10', @x OUTPUT; --> 2 errores: nombre y apellido obligatorios
-- EXEC arbitraje.arbitro_insertar '', 'Ins Err', 999999, 'FIFA', @f17, @x OUTPUT; --> 3 errores: nombre obligatorio, menor de 18 años y pais inexistente
-- EXEC arbitraje.arbitro_insertar '', '', 999999, 'otra', @f71, @x OUTPUT; --> 5 errores: nombre, apellido, mayor de 70 años, pais inexistente y categoria invalida
-- EXEC arbitraje.arbitro_insertar NULL, NULL, NULL, NULL, '1985-05-10', @x OUTPUT; --> 4 errores: nombre, apellido, pais (nulo) y categoria
GO

-- Verificacion arbitraje.arbitro_modificar
DECLARE @a_mod INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_mod'),
        @a_prin INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_prin'),
        @pa INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pais_a'),
        @pb INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pais_b'),
        @ph INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'pais_h'),
        @hoy DATE = CAST(SYSDATETIME() AS DATE);
DECLARE @f17 DATE = DATEADD(DAY, 1, DATEADD(YEAR, -18, @hoy)),
        @f71 DATE = DATEADD(DAY, -1, DATEADD(YEAR, -70, @hoy));
EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', 'Mod Nuevo', @pa, 'FIFA', '1982-02-02'; --> Modificacion valida
-- EXEC arbitraje.arbitro_modificar NULL, 'Test Arb', 'Mod Nuevo', @pa, 'FIFA', '1982-02-02'; --> Id nulo
-- EXEC arbitraje.arbitro_modificar 999999, 'Test Arb', 'Mod Nuevo', @pa, 'FIFA', '1982-02-02'; --> Arbitro inexistente
-- EXEC arbitraje.arbitro_modificar @a_mod, '', 'Mod Nuevo', @pa, 'FIFA', '1982-02-02'; --> Nombre vacio
-- EXEC arbitraje.arbitro_modificar @a_mod, NULL, 'Mod Nuevo', @pa, 'FIFA', '1982-02-02'; --> Nombre nulo
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', '', @pa, 'FIFA', '1982-02-02'; --> Apellido vacio
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', '   ', @pa, 'FIFA', '1982-02-02'; --> Apellido solo espacios
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', 'Mod Nuevo', @pa, 'FIFA', @f17; --> Menor de 18 años
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', 'Mod Nuevo', @pa, 'FIFA', @f71; --> Mayor de 70 años
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', 'Mod Nuevo', 999999, 'FIFA', '1982-02-02'; --> Pais inexistente
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', 'Mod Nuevo', NULL, 'FIFA', '1982-02-02'; --> Pais nulo
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', 'Mod Nuevo', @pa, 'otra', '1982-02-02'; --> Categoria invalida
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', 'Mod Nuevo', @pa, NULL, '1982-02-02'; --> Categoria nula
-- EXEC arbitraje.arbitro_modificar @a_mod, 'Test Arb', 'Base', @pa, 'FIFA', '1982-02-02'; --> Ya existe un arbitro con ese nombre y apellido para ese pais
-- EXEC arbitraje.arbitro_modificar @a_prin, 'Test Arb', 'Principal', @pb, 'FIFA', '1980-01-01'; --> El nuevo pais coincide con una seleccion de un partido en el que ya esta designado
-- EXEC arbitraje.arbitro_modificar NULL, '', 'Mod Nuevo', @pa, 'FIFA', '1982-02-02'; --> 2 errores: id obligatorio y nombre obligatorio
-- EXEC arbitraje.arbitro_modificar 999999, '', 'Mod Nuevo', 999999, 'FIFA', @f17; --> 4 errores: arbitro inexistente, nombre obligatorio, menor de 18 años y pais inexistente
-- EXEC arbitraje.arbitro_modificar 999999, '', '', 999999, 'otra', @f71; --> 6 errores: arbitro inexistente, nombre, apellido, mayor de 70 años, pais inexistente y categoria invalida
GO

-- Verificacion arbitraje.arbitro_eliminar
DECLARE @a_elim INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_elim'),
        @a_prin INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_prin');
EXEC arbitraje.arbitro_eliminar @a_elim; --> Baja valida: se elimina junto con sus idiomas. SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR (arbitro inexistente)
-- SELECT * FROM arbitraje.arbitro_idioma WHERE arbitro_id = @a_elim; --> 0 filas (los idiomas se eliminaron con el arbitro)
-- EXEC arbitraje.arbitro_eliminar 999999; --> Arbitro inexistente
-- EXEC arbitraje.arbitro_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC arbitraje.arbitro_eliminar @a_prin; --> Tiene designaciones en partidos
GO

-- Verificacion arbitraje.arbitro_idioma_insertar
DECLARE @a_idi INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_idi');
EXEC arbitraje.arbitro_idioma_insertar @a_idi, 'japones'; --> Valido
-- EXEC arbitraje.arbitro_idioma_insertar @a_idi, ''; --> Idioma vacio
-- EXEC arbitraje.arbitro_idioma_insertar @a_idi, NULL; --> Idioma nulo
-- EXEC arbitraje.arbitro_idioma_insertar @a_idi, '   '; --> Idioma solo espacios
-- EXEC arbitraje.arbitro_idioma_insertar @a_idi, 'abcdefghijk'; --> Idioma de 11 letras (mas de 10)
-- EXEC arbitraje.arbitro_idioma_insertar @a_idi, 'ruso2'; --> Idioma con numeros
-- EXEC arbitraje.arbitro_idioma_insertar @a_idi, 'ruso chino'; --> Idioma con espacio
-- EXEC arbitraje.arbitro_idioma_insertar @a_idi, 'ruso-chino'; --> Idioma con guion
-- EXEC arbitraje.arbitro_idioma_insertar 999999, 'ruso'; --> Arbitro inexistente
-- EXEC arbitraje.arbitro_idioma_insertar NULL, 'ruso'; --> Arbitro nulo (el mensaje dice "(nulo)")
-- EXEC arbitraje.arbitro_idioma_insertar @a_idi, 'ingles'; --> El arbitro ya tiene registrado ese idioma
-- EXEC arbitraje.arbitro_idioma_insertar 999999, ''; --> 2 errores: arbitro inexistente e idioma obligatorio
GO

-- Verificacion arbitraje.arbitro_idioma_modificar
DECLARE @a_idi INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_idi');
EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'frances', 'portugues'; --> Modificacion valida (SI SE REPITE TIRA ERROR: 'frances' ya no existe)
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ingles', 'ingles'; --> Valido: mismo idioma (no es duplicado de si mismo)
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'italiano', 'Italiano'; --> Valido: se guarda en minusculas
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ruso', 'chino'; --> El arbitro no tiene registrado el idioma a reemplazar
-- EXEC arbitraje.arbitro_idioma_modificar 999999, 'ingles', 'chino'; --> Arbitro sin ese idioma (arbitro inexistente)
-- EXEC arbitraje.arbitro_idioma_modificar NULL, 'ingles', 'chino'; --> Arbitro nulo
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, NULL, 'chino'; --> Idioma a reemplazar nulo
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ingles', ''; --> Idioma nuevo vacio
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ingles', NULL; --> Idioma nuevo nulo
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ingles', '   '; --> Idioma nuevo solo espacios
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ingles', 'abcdefghijk'; --> Idioma nuevo de 11 letras
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ingles', 'chino2'; --> Idioma nuevo con numeros
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ingles', 'italiano'; --> El arbitro ya tiene registrado el idioma nuevo
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ruso', ''; --> 2 errores: idioma a reemplazar inexistente e idioma nuevo obligatorio
-- EXEC arbitraje.arbitro_idioma_modificar @a_idi, 'ruso', 'ingles'; --> 2 errores: idioma a reemplazar inexistente e idioma nuevo ya registrado
GO

-- Verificacion arbitraje.arbitro_idioma_eliminar
DECLARE @a_idi INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_idi');
EXEC arbitraje.arbitro_idioma_eliminar @a_idi, 'aleman'; --> Baja valida (SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR)
-- EXEC arbitraje.arbitro_idioma_eliminar @a_idi, 'ruso'; --> El arbitro no tiene registrado ese idioma
-- EXEC arbitraje.arbitro_idioma_eliminar 999999, 'ingles'; --> Arbitro inexistente (no tiene registrado ese idioma)
-- EXEC arbitraje.arbitro_idioma_eliminar NULL, 'ingles'; --> Arbitro nulo
-- EXEC arbitraje.arbitro_idioma_eliminar @a_idi, NULL; --> Idioma nulo
-- EXEC arbitraje.arbitro_idioma_eliminar @a_idi, ''; --> Idioma vacio
GO

-- Verificacion arbitraje.designacion_arbitral_insertar
-- Los mensajes de ADVERTENCIA no bloquean el alta, se muestran con PRINT y por el parametro @adv.
DECLARE @p_gr   INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'par_gr'),
        @p_24   INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'par_24'),
        @p_fin  INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'par_fin'),
        @p_elim INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'par_elim'),
        @a_prin INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_prin'),
        @a_as1  INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_as1'),
        @a_ins  INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_ins'),
        @a_err  INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_err'),
        @a_conf INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_conf'),
        @a_g    INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_g'),
        @d INT, @adv VARCHAR(500);
EXEC arbitraje.designacion_arbitral_insertar @p_gr, @a_ins, 'var', @d OUTPUT, @adv OUTPUT; --> Valido: fase de grupos, sin advertencia
-- EXEC arbitraje.designacion_arbitral_insertar 999999, @a_err, 'principal', @d OUTPUT, @adv OUTPUT; --> Partido inexistente
-- EXEC arbitraje.designacion_arbitral_insertar NULL, @a_err, 'principal', @d OUTPUT, @adv OUTPUT; --> Partido nulo (el mensaje dice "(nulo)")
-- EXEC arbitraje.designacion_arbitral_insertar @p_fin, @a_err, 'var', @d OUTPUT, @adv OUTPUT; --> El partido ya esta finalizado
-- EXEC arbitraje.designacion_arbitral_insertar @p_24, 999999, 'cuarto', @d OUTPUT, @adv OUTPUT; --> Arbitro inexistente
-- EXEC arbitraje.designacion_arbitral_insertar @p_24, NULL, 'cuarto', @d OUTPUT, @adv OUTPUT; --> Arbitro nulo (el mensaje dice "(nulo)")
-- EXEC arbitraje.designacion_arbitral_insertar @p_24, @a_err, 'juez', @d OUTPUT, @adv OUTPUT; --> Rol invalido
-- EXEC arbitraje.designacion_arbitral_insertar @p_24, @a_err, NULL, @d OUTPUT, @adv OUTPUT; --> Rol nulo
-- EXEC arbitraje.designacion_arbitral_insertar @p_gr, @a_err, 'principal', @d OUTPUT, @adv OUTPUT; --> El partido ya tiene designado el rol principal
-- EXEC arbitraje.designacion_arbitral_insertar @p_gr, @a_as1, 'cuarto', @d OUTPUT, @adv OUTPUT; --> El arbitro ya esta designado en ese partido con otro rol
-- EXEC arbitraje.designacion_arbitral_insertar @p_24, @a_as1, 'principal', @d OUTPUT, @adv OUTPUT; --> El arbitro ya esta designado en otro partido a menos de 24 horas (par_gr, 18 h antes)
-- EXEC arbitraje.designacion_arbitral_insertar @p_gr, @a_as1, 'principal', @d OUTPUT, @adv OUTPUT; --> 2 errores: rol principal ya designado y arbitro ya designado con otro rol
-- EXEC arbitraje.designacion_arbitral_insertar @p_fin, @a_conf, 'juez', @d OUTPUT, @adv OUTPUT; --> 3 errores: partido finalizado, rol invalido y conflicto de nacionalidad (ZRD juega par_fin)
GO

-- Verificacion arbitraje.designacion_arbitral_modificar
DECLARE @d_m_prin INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_m_prin'),
        @d_m_as1  INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_m_as1'),
        @d_inf    INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_inf'),
        @d_fin    INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_fin'),
        @a_prin   INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_prin'),
        @a_m2     INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_m2'),
        @a_libre  INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_libre'),
        @a_conf   INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'a_conf'),
        @adv VARCHAR(500);
EXEC arbitraje.designacion_arbitral_modificar @d_m_prin, @a_libre, 'principal', @adv OUTPUT; --> Modificacion valida: cambia el arbitro (sin informes cargados)
-- EXEC arbitraje.designacion_arbitral_modificar @d_m_as1, @a_m2, 'cuarto', @adv OUTPUT; --> Valido: cambia solo el rol
-- EXEC arbitraje.designacion_arbitral_modificar 999999, @a_libre, 'principal', @adv OUTPUT; --> Designacion inexistente
-- EXEC arbitraje.designacion_arbitral_modificar NULL, @a_libre, 'principal', @adv OUTPUT; --> Designacion nula (el mensaje dice "(nulo)")
-- EXEC arbitraje.designacion_arbitral_modificar @d_fin, @a_prin, 'principal', @adv OUTPUT; --> El partido ya esta finalizado
-- EXEC arbitraje.designacion_arbitral_modificar @d_m_as1, 999999, 'asistente_1', @adv OUTPUT; --> Arbitro inexistente
-- EXEC arbitraje.designacion_arbitral_modificar @d_m_as1, NULL, 'asistente_1', @adv OUTPUT; --> Arbitro nulo
-- EXEC arbitraje.designacion_arbitral_modificar @d_m_as1, @a_m2, 'juez', @adv OUTPUT; --> Rol invalido
-- EXEC arbitraje.designacion_arbitral_modificar @d_m_as1, @a_m2, NULL, @adv OUTPUT; --> Rol nulo
-- EXEC arbitraje.designacion_arbitral_modificar @d_m_as1, @a_m2, 'principal', @adv OUTPUT; --> El partido ya tiene designado el rol principal
-- EXEC arbitraje.designacion_arbitral_modificar @d_m_prin, @a_m2, 'principal', @adv OUTPUT; --> El arbitro ya esta designado en ese partido con otro rol
-- EXEC arbitraje.designacion_arbitral_modificar @d_m_as1, @a_conf, 'asistente_1', @adv OUTPUT; --> Conflicto de nacionalidad (pais ZRD = seleccion que juega par_mod)
-- EXEC arbitraje.designacion_arbitral_modificar @d_inf, @a_libre, 'asistente_2', @adv OUTPUT; --> No se puede cambiar el arbitro: la designacion ya tiene informes cargados
-- EXEC arbitraje.designacion_arbitral_modificar @d_fin, @a_prin, 'juez', @adv OUTPUT; --> 2 errores: partido finalizado y rol invalido
-- EXEC arbitraje.designacion_arbitral_modificar @d_fin, @a_conf, 'principal', @adv OUTPUT; --> 3 errores: partido finalizado, conflicto de nacionalidad (ZRD juega par_fin) y cambio de arbitro con informes
GO

-- Verificacion arbitraje.designacion_arbitral_eliminar
DECLARE @d_elim INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_elim'),
        @d_inf  INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_inf'),
        @d_fin  INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_fin');
EXEC arbitraje.designacion_arbitral_eliminar @d_elim; --> Baja valida (SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR: designacion inexistente)
-- EXEC arbitraje.designacion_arbitral_eliminar 999999; --> Designacion inexistente
-- EXEC arbitraje.designacion_arbitral_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC arbitraje.designacion_arbitral_eliminar @d_inf; --> Tiene informes arbitrales cargados
-- EXEC arbitraje.designacion_arbitral_eliminar @d_fin; --> 2 errores: partido finalizado (historial arbitral) y tiene informes cargados
GO

-- Verificacion arbitraje.informe_arbitral_insertar
DECLARE @d_inf INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'd_inf'), @inf INT;
EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 22:00:00 -03:00', 'Informe de prueba', 'Amonestacion al DT', @inf OUTPUT; --> Valido
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 22:00:00 -03:00', 'Informe sin sancion', NULL, @inf OUTPUT; --> Valido: sin sancion
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 22:00:00 -03:00', 'Informe sancion en blanco', '   ', @inf OUTPUT; --> Valido: la sancion en blanco se guarda como NULL
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 15:00:00 -03:00', 'Informe en el inicio', NULL, @inf OUTPUT; --> Valido: fecha igual al inicio del partido (borde)
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 18:00:00 +00:00', 'Informe mismo instante en UTC', NULL, @inf OUTPUT; --> Valido: mismo instante expresado en UTC (borde)
-- EXEC arbitraje.informe_arbitral_insertar 999999, '2026-06-15 22:00:00 -03:00', 'Informe', NULL, @inf OUTPUT; --> Designacion inexistente
-- EXEC arbitraje.informe_arbitral_insertar NULL, '2026-06-15 22:00:00 -03:00', 'Informe', NULL, @inf OUTPUT; --> Designacion nula (el mensaje dice "(nulo)")
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, NULL, 'Informe', NULL, @inf OUTPUT; --> Fecha nula
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 14:59:00 -03:00', 'Informe', NULL, @inf OUTPUT; --> Fecha anterior al inicio del partido (informe post-partido)
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 22:00:00 -03:00', '', NULL, @inf OUTPUT; --> Contenido vacio
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 22:00:00 -03:00', NULL, NULL, @inf OUTPUT; --> Contenido nulo
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, '2026-06-15 22:00:00 -03:00', '   ', NULL, @inf OUTPUT; --> Contenido solo espacios
-- EXEC arbitraje.informe_arbitral_insertar @d_inf, NULL, '', NULL, @inf OUTPUT; --> 2 errores: fecha obligatoria y contenido obligatorio
-- EXEC arbitraje.informe_arbitral_insertar 999999, NULL, '', NULL, @inf OUTPUT; --> 3 errores: designacion inexistente, fecha obligatoria y contenido obligatorio
GO

-- Verificacion arbitraje.informe_arbitral_modificar
-- Con un informe inexistente solo se informa ese error (no se evaluan los demas parametros).
DECLARE @i_mod INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'i_mod');
EXEC arbitraje.informe_arbitral_modificar @i_mod, '2026-06-15 23:00:00 -03:00', 'Informe modificado', 'Suspension de un partido'; --> Modificacion valida
-- EXEC arbitraje.informe_arbitral_modificar @i_mod, '2026-06-15 23:00:00 -03:00', 'Informe modificado sin sancion', NULL; --> Valido: se quita la sancion
-- EXEC arbitraje.informe_arbitral_modificar @i_mod, '2026-06-15 15:00:00 -03:00', 'Informe en el inicio', NULL; --> Valido: fecha igual al inicio del partido (borde)
-- EXEC arbitraje.informe_arbitral_modificar 999999, '2026-06-15 23:00:00 -03:00', 'Informe', NULL; --> Informe inexistente
-- EXEC arbitraje.informe_arbitral_modificar NULL, '2026-06-15 23:00:00 -03:00', 'Informe', NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC arbitraje.informe_arbitral_modificar @i_mod, NULL, 'Informe', NULL; --> Fecha nula
-- EXEC arbitraje.informe_arbitral_modificar @i_mod, '2026-06-15 14:59:00 -03:00', 'Informe', NULL; --> Fecha anterior al inicio del partido
-- EXEC arbitraje.informe_arbitral_modificar @i_mod, '2026-06-15 23:00:00 -03:00', '', NULL; --> Contenido vacio
-- EXEC arbitraje.informe_arbitral_modificar @i_mod, '2026-06-15 23:00:00 -03:00', NULL, NULL; --> Contenido nulo
-- EXEC arbitraje.informe_arbitral_modificar @i_mod, '2026-06-15 23:00:00 -03:00', '   ', NULL; --> Contenido solo espacios
-- EXEC arbitraje.informe_arbitral_modificar @i_mod, NULL, '', NULL; --> 2 errores: fecha obligatoria y contenido obligatorio
GO

-- Verificacion arbitraje.informe_arbitral_eliminar
DECLARE @i_elim INT = (SELECT id FROM ##test_arbitraje WHERE clave = 'i_elim');
EXEC arbitraje.informe_arbitral_eliminar @i_elim; --> Baja valida (SI SE ELIMINA 2 VECES SEGUIDAS TIRA ERROR: informe inexistente)
-- EXEC arbitraje.informe_arbitral_eliminar 999999; --> Informe inexistente
-- EXEC arbitraje.informe_arbitral_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
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



-- Verificacion publicidad.campania_insertar
-- LAS DOS SIGUIENTES LINEAS SE EJECUTAN UNA SOLA VEZ: 
EXEC publicidad.anunciante_insertar 'CAMP_A', NULL, NULL;
EXEC publicidad.anunciante_insertar 'CAMP_B', NULL, NULL;
GO;


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
DECLARE @ok INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim OK'),
        @con INT = (SELECT campania_id FROM publicidad.campania WHERE nombre = 'Elim Con Pieza');

EXEC publicidad.campania_eliminar @ok; --> Baja valida: elimina la campaña y sus paises de interes, si se ejecuta dos veces seguidas tira error de inexistente
-- EXEC publicidad.campania_eliminar 999999; --> Campaña inexistente
-- EXEC publicidad.campania_eliminar NULL; --> Id nulo (el mensaje dice "(nulo)")
-- EXEC publicidad.campania_eliminar @con; --> Tiene piezas publicitarias registradas


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
GO;

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
GO;

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
GO;

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
GO;

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
GO;

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
GO;

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