-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 8: Seguridad y respaldo - Test de usuarios y roles
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Simula el ingreso de cada usuario de prueba (EXECUTE AS LOGIN) y muestra, primero, todo lo que
--   puede hacer y, después, lo que no puede. Los usuarios van de mayor a menor privilegio, y cada uno
--   intenta lo mismo que hizo el anterior (que tenía más permisos): así se ve la diferencia entre roles.
--     PARTE 1: usr_administrador      (rol_administrador,     109 SP)
--     PARTE 2: usr_gestor_publicidad  (rol_gestor_publicidad,  20 SP)
--     PARTE 3: usr_comite_arbitral    (rol_comite_arbitral,    16 SP)
--     PARTE 4: usr_var                (rol_var,                11 SP)
--     PARTE 5: usr_planillero         (rol_planillero,          9 SP)
--     PARTE 6: usr_consulta           (rol_consulta,            7 SP)
--     PARTE 7: comparación entre los seis usuarios (cuadro comparativo, permisos efectivos de
--              cada uno contra el cuadro y permiso de servidor para importar)
--   Cada parte tiene tres lotes:
--     n.1  inicio de sesión: con qué usuario y en qué rol queda la sesión
--     n.2  lo que puede hacer: las altas, consultas y reportes se ejecutan de verdad (lo que se da de
--          alta se borra en el mismo lote); los SP que necesitan un partido en juego se llaman con un
--          partido inexistente: se ejecutan (tienen permiso) y los rechaza su validación, sin cambios
--     n.3  lo que no puede hacer: lo que hizo el usuario anterior y el acceso directo a las tablas
--          dan el error 229 (permiso denegado)
--   Cada intento se informa en la pestaña Mensajes como PUEDE o NO PUEDE.
--
-- CÓMO EJECUTARLO:
--   Como DBA (sysadmin), después de 1_entrega8_cifrado.sql, 2_entrega8_roles.sql y
--   3_entrega8_usuarios.sql (sobre la base con las Entregas 5, 6 y 7 cargadas).
--   No usa rutas absolutas: la importación del administrador se llama con la ruta relativa del
--   repositorio (imports/scraping/sedes.json), que el servidor no resuelve; prueba el permiso, no la
--   lectura del archivo (esa la prueba 3_entrega6_test.sql).
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

PRINT '################ PARTE 1: usr_administrador (rol_administrador) ################';
GO

-- ============================================================
-- 1.1 Inicio de sesión
-- ============================================================

PRINT '--- 1.1 Inicio de sesión de usr_administrador';
-- Se simula el ingreso del usuario: a partir de EXECUTE AS LOGIN todo se ejecuta con sus permisos.
-- Resultado esperado: la sesión queda a nombre de usr_administrador, que pertenece sólo a rol_administrador.
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT;
EXECUTE AS LOGIN = 'usr_administrador';
SELECT @login = SUSER_SNAME(), @usuario = USER_NAME(), @en_rol = IS_MEMBER('rol_administrador');
REVERT;
SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_administrador' AND IS_ROLEMEMBER(rol, 'usr_administrador') = 1;
SELECT @login AS sesion_iniciada_como, @usuario AS usuario_en_la_base, 'rol_administrador' AS rol, 'Comité Organizador' AS quien_es,
       (SELECT COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_administrador' AND p.clase = 'OBJECT') AS sp_que_puede_ejecutar;
INSERT INTO #resultado VALUES ('1.1', 'usr_administrador: inicio de sesión y rol',
       IIF(@login = 'usr_administrador' AND @usuario = 'usr_administrador' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión ', @login, '; miembro de rol_administrador = ', @en_rol, '; otros roles = ', @otros));
GO

-- ============================================================
-- 1.2 Lo que puede hacer el administrador
-- ============================================================

PRINT '--- 1.2 usr_administrador: lo que puede hacer';
-- Da de alta una sede y la borra, ve la convocatoria con los motivos descifrados, ejecuta dos reportes
-- (uno con SQL dinámico), consulta la API de cambio, llama a la importación de sedes.json y hace un ABM completo de
-- una convocatoria (alta, modificación y baja con fecha y motivo), mostrando lo que queda guardado en cada paso.
-- Resultado esperado: todo se ejecuta. La importación recibe la ruta relativa del repositorio, que el servidor
-- no resuelve: se ejecuta (tiene permiso) y la rechaza su validación (error 50003), sin cambios.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
DECLARE @sedes_json VARCHAR(500) = 'imports/scraping/sedes.json';   -- ruta relativa del repositorio
DECLARE @conv INT, @jug INT, @cupo INT = (SELECT valor FROM torneo.parametro WHERE clave = 'convocatoria_max_jugadores');
DECLARE @c TABLE (convocatoria_id INT, seleccion VARCHAR(200), dorsal INT, nombre VARCHAR(200), apellido VARCHAR(200),
                  fecha_alta DATE, motivo_alta VARCHAR(400), fecha_baja DATE, motivo_baja VARCHAR(400));
EXECUTE AS LOGIN = 'usr_administrador';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC torneo.sede_insertar 'Estadio de prueba', 'Ciudad de prueba', @pais, 50000, 'UTC-03', @id OUTPUT;
    INSERT INTO @r VALUES ('torneo.sede_insertar', 'ok', 0);
    PRINT CONCAT('  PUEDE      torneo.sede_insertar', CONCAT(' -> sede creada con id ', @id));
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.sede_insertar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.sede_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC torneo.sede_eliminar @id;
    INSERT INTO @r VALUES ('torneo.sede_eliminar', 'ok', 0);
    PRINT CONCAT('  PUEDE      torneo.sede_eliminar', ' -> sede de prueba borrada');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.sede_eliminar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.sede_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 'ok', 0);
    PRINT CONCAT('  PUEDE      plantel.consultar_convocatoria', ' -> convocatoria de Argentina con los motivos descifrados');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.consultar_convocatoria',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'final', @tabla_posiciones = 0;
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', 0);
    PRINT CONCAT('  PUEDE      torneo.reporte_resultados', ' -> resultado de la final');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.reporte_resultados',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.reporte_matriz_prime_time @partido_id = @partido;
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.reporte_matriz_prime_time', ' -> matriz de prime time de la final (SQL dinámico)');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.reporte_matriz_prime_time',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.consultar_api_frankfurter;
    INSERT INTO @r VALUES ('publicidad.consultar_api_frankfurter', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.consultar_api_frankfurter', ' -> cotizaciones del día');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_api_frankfurter', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.consultar_api_frankfurter',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC torneo.importar_sedes @sedes_json;
    INSERT INTO @r VALUES ('torneo.importar_sedes', 'validacion', 0);
    PRINT CONCAT('  PUEDE      torneo.importar_sedes', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.importar_sedes', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.importar_sedes',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
-- ABM de una convocatoria dentro de una transacción que se deshace al final (no deja cambios). La selección ya
-- tiene el cupo completo: el administrador sube el cupo en 1, da de alta un jugador y su convocatoria, la modifica
-- y la da de baja con fecha y motivo (baja lógica). Después de cada paso se consulta, con los motivos descifrados.
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @cupo_nuevo INT = @cupo + 1;
    EXEC torneo.parametro_modificar 'convocatoria_max_jugadores', @cupo_nuevo;
    EXEC plantel.jugador_insertar 'Jugador', 'De Prueba', '2000-01-01', 'delantero', 'Club de prueba', @jug OUTPUT;
    EXEC plantel.convocatoria_insertar @seleccion, @jug, 99, '2026-06-02', 'Alta de prueba', @conv OUTPUT;
    DELETE FROM @c;
    INSERT INTO @c EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    SELECT 'ALTA' AS paso, convocatoria_id, seleccion, dorsal, nombre, apellido, fecha_alta, motivo_alta, fecha_baja, motivo_baja
    FROM @c WHERE convocatoria_id = @conv;
    PRINT CONCAT('  PUEDE      plantel.convocatoria_insertar -> alta de la convocatoria ', @conv, ' (dorsal 99, sin fecha de baja)');

    EXEC plantel.convocatoria_modificar @conv, 98, '2026-06-02', 'Alta de prueba modificada', NULL, NULL;
    DELETE FROM @c;
    INSERT INTO @c EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    SELECT 'MODIFICACIÓN' AS paso, convocatoria_id, seleccion, dorsal, nombre, apellido, fecha_alta, motivo_alta, fecha_baja, motivo_baja
    FROM @c WHERE convocatoria_id = @conv;
    PRINT '  PUEDE      plantel.convocatoria_modificar -> dorsal 98 y motivo de alta modificados';

    EXEC plantel.convocatoria_modificar @conv, 98, '2026-06-02', 'Alta de prueba modificada', '2026-06-20', 'Baja de prueba';
    DELETE FROM @c;
    INSERT INTO @c EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    SELECT 'BAJA' AS paso, convocatoria_id, seleccion, dorsal, nombre, apellido, fecha_alta, motivo_alta, fecha_baja, motivo_baja
    FROM @c WHERE convocatoria_id = @conv;
    PRINT '  PUEDE      plantel.convocatoria_modificar -> baja con fecha (2026-06-20) y motivo';

    ROLLBACK TRANSACTION;
    DELETE FROM @c;
    INSERT INTO @c EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    DECLARE @sigue BIT = IIF(EXISTS (SELECT 1 FROM @c WHERE convocatoria_id = @conv), 1, 0),
            @vigentes INT = (SELECT COUNT(*) FROM @c WHERE fecha_baja IS NULL);
    PRINT CONCAT('  (transacción deshecha: la convocatoria de prueba ', IIF(@sigue = 1, 'sigue', 'ya no existe'),
                 ' y la selección vuelve a tener ', @vigentes, ' convocados)');
    INSERT INTO @r VALUES ('torneo.parametro_modificar', 'ok', 0), ('plantel.jugador_insertar', 'ok', 0),
                          ('plantel.convocatoria_insertar', 'ok', 0), ('plantel.convocatoria_modificar', 'ok', 0);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO @r VALUES ('plantel.convocatoria (alta, modificación y baja)', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.convocatoria (alta, modificación y baja)',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '1.2', 'administrador: lo que puede hacer',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ============================================================
-- 1.3 Lo que no puede hacer el administrador
-- ============================================================

PRINT '--- 1.3 usr_administrador: lo que no puede hacer';
-- El administrador administra los datos, no la seguridad ni la estructura: no crea usuarios (es del DBA),
-- no llama a los SP auxiliares y no lee ni escribe las tablas directamente.
-- Resultado esperado: error 229 en todos los intentos.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_administrador';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC seguridad.crear_usuario 'usr_nuevo', 'Clave_Prueba_2026!', 'rol_consulta';
    INSERT INTO @r VALUES ('seguridad.crear_usuario', 'denegado', 0);
    PRINT CONCAT('  PUEDE      seguridad.crear_usuario', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('seguridad.crear_usuario', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'seguridad.crear_usuario',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    DECLARE @err VARCHAR(2000); EXEC torneo.sede_validar NULL, NULL, NULL, NULL, NULL, NULL, @err OUTPUT;
    INSERT INTO @r VALUES ('torneo.sede_validar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      torneo.sede_validar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.sede_validar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.sede_validar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    SELECT TOP (1) @x = apellido FROM plantel.jugador;
    INSERT INTO @r VALUES ('SELECT plantel.jugador', 'denegado', 0);
    PRINT CONCAT('  PUEDE      SELECT plantel.jugador', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT plantel.jugador', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'SELECT plantel.jugador',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    UPDATE torneo.sede SET capacidad = capacidad WHERE sede_id = -1;
    INSERT INTO @r VALUES ('UPDATE torneo.sede', 'denegado', 0);
    PRINT CONCAT('  PUEDE      UPDATE torneo.sede', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE torneo.sede', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'UPDATE torneo.sede',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '1.3', 'administrador: lo que no puede hacer',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

PRINT '################ PARTE 2: usr_gestor_publicidad (rol_gestor_publicidad) ################';
GO

-- ============================================================
-- 2.1 Inicio de sesión
-- ============================================================

PRINT '--- 2.1 Inicio de sesión de usr_gestor_publicidad';
-- Se simula el ingreso del usuario: a partir de EXECUTE AS LOGIN todo se ejecuta con sus permisos.
-- Resultado esperado: la sesión queda a nombre de usr_gestor_publicidad, que pertenece sólo a rol_gestor_publicidad.
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT;
EXECUTE AS LOGIN = 'usr_gestor_publicidad';
SELECT @login = SUSER_SNAME(), @usuario = USER_NAME(), @en_rol = IS_MEMBER('rol_gestor_publicidad');
REVERT;
SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_gestor_publicidad' AND IS_ROLEMEMBER(rol, 'usr_gestor_publicidad') = 1;
SELECT @login AS sesion_iniciada_como, @usuario AS usuario_en_la_base, 'rol_gestor_publicidad' AS rol, 'Área comercial' AS quien_es,
       (SELECT COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_gestor_publicidad' AND p.clase = 'OBJECT') AS sp_que_puede_ejecutar;
INSERT INTO #resultado VALUES ('2.1', 'usr_gestor_publicidad: inicio de sesión y rol',
       IIF(@login = 'usr_gestor_publicidad' AND @usuario = 'usr_gestor_publicidad' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión ', @login, '; miembro de rol_gestor_publicidad = ', @en_rol, '; otros roles = ', @otros));
GO

-- ============================================================
-- 2.2 Lo que puede hacer el gestor de publicidad
-- ============================================================

PRINT '--- 2.2 usr_gestor_publicidad: lo que puede hacer';
-- ABM de un anunciante: lo da de alta con su contacto, lo modifica y lo borra, y después de cada paso lo consulta
-- (ve el contacto descifrado); ejecuta los dos reportes de publicidad; pide la asignación de espacios de un partido inexistente (validación).
-- Resultado esperado: todo se ejecuta; la asignación la rechaza su validación, sin cambios.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
DECLARE @a TABLE (anunciante_id INT, nombre VARCHAR(200), razon_social VARCHAR(200), contacto VARCHAR(400));
EXECUTE AS LOGIN = 'usr_gestor_publicidad';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC publicidad.anunciante_insertar 'Anunciante de prueba', 'Prueba S.A.', 'contacto@prueba.com', @id OUTPUT;
    INSERT INTO @r VALUES ('publicidad.anunciante_insertar', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.anunciante_insertar', CONCAT(' -> anunciante creado con id ', @id));
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_insertar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.anunciante_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    DELETE FROM @a;
    INSERT INTO @a EXEC publicidad.consultar_anunciante @anunciante_id = @id;
    SELECT 'ALTA' AS paso, * FROM @a;
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.consultar_anunciante', ' -> ve el contacto descifrado');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.consultar_anunciante',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.anunciante_modificar @id, 'Anunciante de prueba modificado', 'Prueba S.A. (modificada)', 'nuevo.contacto@prueba.com';
    DELETE FROM @a;
    INSERT INTO @a EXEC publicidad.consultar_anunciante @anunciante_id = @id;
    SELECT 'MODIFICACIÓN' AS paso, * FROM @a;
    INSERT INTO @r VALUES ('publicidad.anunciante_modificar', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.anunciante_modificar', ' -> nombre, razón social y contacto modificados');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_modificar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.anunciante_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.anunciante_eliminar @id;
    INSERT INTO @r VALUES ('publicidad.anunciante_eliminar', 'ok', 0);
    DELETE FROM @a;
    INSERT INTO @a EXEC publicidad.consultar_anunciante @anunciante_id = @id;
    SELECT 'BAJA' AS paso, COUNT(*) AS filas_del_anunciante FROM @a;
    PRINT CONCAT('  PUEDE      publicidad.anunciante_eliminar', ' -> anunciante de prueba borrado (ya no figura en la consulta)');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_eliminar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.anunciante_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.reporte_ocupacion @sede_id = @sede;
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.reporte_ocupacion', ' -> ocupación de una sede');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.reporte_ocupacion',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.reporte_matriz_prime_time @partido_id = @partido;
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.reporte_matriz_prime_time', ' -> matriz de prime time de la final');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.reporte_matriz_prime_time',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.asignar_espacios_partido @partido_id = -1;
    INSERT INTO @r VALUES ('publicidad.asignar_espacios_partido', 'validacion', 0);
    PRINT CONCAT('  PUEDE      publicidad.asignar_espacios_partido', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.asignar_espacios_partido', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.asignar_espacios_partido',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '2.2', 'gestor de publicidad: lo que puede hacer',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ============================================================
-- 2.3 El gestor de publicidad intenta lo que hizo el administrador
-- ============================================================

PRINT '--- 2.3 usr_gestor_publicidad: intenta lo que hizo el administrador';
-- Mismas operaciones que el administrador ejecutó en 1.2, fuera del área comercial, y acceso a las tablas.
-- Resultado esperado: error 229 en todos los intentos.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_gestor_publicidad';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC torneo.sede_insertar 'Estadio de prueba', 'Ciudad de prueba', @pais, 50000, 'UTC-03', @id OUTPUT;
    INSERT INTO @r VALUES ('torneo.sede_insertar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      torneo.sede_insertar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.sede_insertar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.sede_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 'denegado', 0);
    PRINT CONCAT('  PUEDE      plantel.consultar_convocatoria', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.consultar_convocatoria',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC plantel.convocatoria_insertar @seleccion, -1, 99, '2026-06-02', 'Alta de prueba';
    INSERT INTO @r VALUES ('plantel.convocatoria_insertar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      plantel.convocatoria_insertar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.convocatoria_insertar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.convocatoria_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC plantel.convocatoria_modificar -1, 98, '2026-06-02', 'Alta de prueba', '2026-06-20', 'Baja de prueba';
    INSERT INTO @r VALUES ('plantel.convocatoria_modificar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      plantel.convocatoria_modificar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.convocatoria_modificar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.convocatoria_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'final', @tabla_posiciones = 0;
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'denegado', 0);
    PRINT CONCAT('  PUEDE      torneo.reporte_resultados', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.reporte_resultados',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.consultar_api_frankfurter;
    INSERT INTO @r VALUES ('publicidad.consultar_api_frankfurter', 'denegado', 0);
    PRINT CONCAT('  PUEDE      publicidad.consultar_api_frankfurter', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_api_frankfurter', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.consultar_api_frankfurter',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    SELECT TOP (1) @x = contacto FROM publicidad.anunciante;
    INSERT INTO @r VALUES ('SELECT publicidad.anunciante', 'denegado', 0);
    PRINT CONCAT('  PUEDE      SELECT publicidad.anunciante', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT publicidad.anunciante', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'SELECT publicidad.anunciante',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    UPDATE publicidad.espacio_publicitario SET facturado = 1 WHERE espacio_id = -1;
    INSERT INTO @r VALUES ('UPDATE publicidad.espacio_publicitario', 'denegado', 0);
    PRINT CONCAT('  PUEDE      UPDATE publicidad.espacio_publicitario', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE publicidad.espacio_publicitario', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'UPDATE publicidad.espacio_publicitario',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '2.3', 'gestor de publicidad: no puede lo del administrador',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

PRINT '################ PARTE 3: usr_comite_arbitral (rol_comite_arbitral) ################';
GO

-- ============================================================
-- 3.1 Inicio de sesión
-- ============================================================

PRINT '--- 3.1 Inicio de sesión de usr_comite_arbitral';
-- Se simula el ingreso del usuario: a partir de EXECUTE AS LOGIN todo se ejecuta con sus permisos.
-- Resultado esperado: la sesión queda a nombre de usr_comite_arbitral, que pertenece sólo a rol_comite_arbitral.
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT;
EXECUTE AS LOGIN = 'usr_comite_arbitral';
SELECT @login = SUSER_SNAME(), @usuario = USER_NAME(), @en_rol = IS_MEMBER('rol_comite_arbitral');
REVERT;
SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_comite_arbitral' AND IS_ROLEMEMBER(rol, 'usr_comite_arbitral') = 1;
SELECT @login AS sesion_iniciada_como, @usuario AS usuario_en_la_base, 'rol_comite_arbitral' AS rol, 'Comité arbitral' AS quien_es,
       (SELECT COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_comite_arbitral' AND p.clase = 'OBJECT') AS sp_que_puede_ejecutar;
INSERT INTO #resultado VALUES ('3.1', 'usr_comite_arbitral: inicio de sesión y rol',
       IIF(@login = 'usr_comite_arbitral' AND @usuario = 'usr_comite_arbitral' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión ', @login, '; miembro de rol_comite_arbitral = ', @en_rol, '; otros roles = ', @otros));
GO

-- ============================================================
-- 3.2 Lo que puede hacer el comité arbitral
-- ============================================================

PRINT '--- 3.2 usr_comite_arbitral: lo que puede hacer';
-- ABM de un árbitro: lo da de alta con su fecha de nacimiento, le agrega un idioma, lo modifica y lo borra, y
-- después de cada paso consulta su ficha (ve la fecha descifrada); ejecuta el reporte de designaciones; designa los árbitros de un partido
-- inexistente (validación).
-- Resultado esperado: todo se ejecuta; la designación la rechaza su validación, sin cambios.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
DECLARE @a TABLE (arbitro_id INT, nombre VARCHAR(200), apellido VARCHAR(200), pais VARCHAR(200), categoria VARCHAR(50), fecha_nacimiento DATE);
EXECUTE AS LOGIN = 'usr_comite_arbitral';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC arbitraje.arbitro_insertar 'Árbitro', 'De Prueba', @pais, 'FIFA', '1985-03-15', @id OUTPUT;
    INSERT INTO @r VALUES ('arbitraje.arbitro_insertar', 'ok', 0);
    PRINT CONCAT('  PUEDE      arbitraje.arbitro_insertar', CONCAT(' -> árbitro creado con id ', @id));
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_insertar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.arbitro_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.arbitro_idioma_insertar @id, 'español';
    INSERT INTO @r VALUES ('arbitraje.arbitro_idioma_insertar', 'ok', 0);
    PRINT CONCAT('  PUEDE      arbitraje.arbitro_idioma_insertar', ' -> idioma agregado');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_idioma_insertar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.arbitro_idioma_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    DELETE FROM @a;
    INSERT INTO @a EXEC arbitraje.consultar_arbitro @arbitro_id = @id;
    SELECT 'ALTA' AS paso, * FROM @a;
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 'ok', 0);
    PRINT CONCAT('  PUEDE      arbitraje.consultar_arbitro', ' -> ve la fecha de nacimiento descifrada');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.consultar_arbitro',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.arbitro_modificar @id, 'Árbitro', 'De Prueba Modificado', @pais, 'FIFA', '1986-04-16';
    DELETE FROM @a;
    INSERT INTO @a EXEC arbitraje.consultar_arbitro @arbitro_id = @id;
    SELECT 'MODIFICACIÓN' AS paso, * FROM @a;
    INSERT INTO @r VALUES ('arbitraje.arbitro_modificar', 'ok', 0);
    PRINT CONCAT('  PUEDE      arbitraje.arbitro_modificar', ' -> apellido y fecha de nacimiento modificados');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_modificar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.arbitro_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.arbitro_idioma_eliminar @id, 'español';
    INSERT INTO @r VALUES ('arbitraje.arbitro_idioma_eliminar', 'ok', 0);
    PRINT CONCAT('  PUEDE      arbitraje.arbitro_idioma_eliminar', ' -> idioma quitado');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_idioma_eliminar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.arbitro_idioma_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.arbitro_eliminar @id;
    INSERT INTO @r VALUES ('arbitraje.arbitro_eliminar', 'ok', 0);
    DELETE FROM @a;
    INSERT INTO @a EXEC arbitraje.consultar_arbitro @arbitro_id = @id;
    SELECT 'BAJA' AS paso, COUNT(*) AS filas_del_arbitro FROM @a;
    PRINT CONCAT('  PUEDE      arbitraje.arbitro_eliminar', ' -> árbitro de prueba borrado (ya no figura en la consulta)');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_eliminar', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.arbitro_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.reporte_designaciones;
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', 0);
    PRINT CONCAT('  PUEDE      arbitraje.reporte_designaciones', ' -> designaciones arbitrales');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.reporte_designaciones',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.designar_arbitros -1, -1, -1, -1, -1, -1;
    INSERT INTO @r VALUES ('arbitraje.designar_arbitros', 'validacion', 0);
    PRINT CONCAT('  PUEDE      arbitraje.designar_arbitros', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.designar_arbitros', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.designar_arbitros',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '3.2', 'comité arbitral: lo que puede hacer',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ============================================================
-- 3.3 El comité arbitral intenta lo que hizo el gestor de publicidad
-- ============================================================

PRINT '--- 3.3 usr_comite_arbitral: intenta lo que hizo el gestor de publicidad';
-- Mismas operaciones que el gestor de publicidad ejecutó en 2.2, fuera del área arbitral, y acceso a las tablas.
-- Resultado esperado: error 229 en todos los intentos.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_comite_arbitral';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC publicidad.anunciante_insertar 'Anunciante de prueba', 'Prueba S.A.', 'contacto@prueba.com', @id OUTPUT;
    INSERT INTO @r VALUES ('publicidad.anunciante_insertar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      publicidad.anunciante_insertar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_insertar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.anunciante_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.anunciante_modificar -1, 'Anunciante de prueba', NULL, NULL;
    INSERT INTO @r VALUES ('publicidad.anunciante_modificar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      publicidad.anunciante_modificar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_modificar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.anunciante_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.consultar_anunciante;
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', 'denegado', 0);
    PRINT CONCAT('  PUEDE      publicidad.consultar_anunciante', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.consultar_anunciante',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.reporte_ocupacion @sede_id = @sede;
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 'denegado', 0);
    PRINT CONCAT('  PUEDE      publicidad.reporte_ocupacion', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.reporte_ocupacion',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.asignar_espacios_partido @partido_id = -1;
    INSERT INTO @r VALUES ('publicidad.asignar_espacios_partido', 'denegado', 0);
    PRINT CONCAT('  PUEDE      publicidad.asignar_espacios_partido', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.asignar_espacios_partido', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.asignar_espacios_partido',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    SELECT TOP (1) @x = apellido FROM arbitraje.arbitro;
    INSERT INTO @r VALUES ('SELECT arbitraje.arbitro', 'denegado', 0);
    PRINT CONCAT('  PUEDE      SELECT arbitraje.arbitro', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT arbitraje.arbitro', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'SELECT arbitraje.arbitro',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    UPDATE arbitraje.designacion_arbitral SET rol = rol WHERE designacion_id = -1;
    INSERT INTO @r VALUES ('UPDATE arbitraje.designacion_arbitral', 'denegado', 0);
    PRINT CONCAT('  PUEDE      UPDATE arbitraje.designacion_arbitral', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE arbitraje.designacion_arbitral', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'UPDATE arbitraje.designacion_arbitral',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '3.3', 'comité arbitral: no puede lo del gestor de publicidad',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

PRINT '################ PARTE 4: usr_var (rol_var) ################';
GO

-- ============================================================
-- 4.1 Inicio de sesión
-- ============================================================

PRINT '--- 4.1 Inicio de sesión de usr_var';
-- Se simula el ingreso del usuario: a partir de EXECUTE AS LOGIN todo se ejecuta con sus permisos.
-- Resultado esperado: la sesión queda a nombre de usr_var, que pertenece sólo a rol_var.
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT;
EXECUTE AS LOGIN = 'usr_var';
SELECT @login = SUSER_SNAME(), @usuario = USER_NAME(), @en_rol = IS_MEMBER('rol_var');
REVERT;
SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_var' AND IS_ROLEMEMBER(rol, 'usr_var') = 1;
SELECT @login AS sesion_iniciada_como, @usuario AS usuario_en_la_base, 'rol_var' AS rol, 'Árbitro de VAR' AS quien_es,
       (SELECT COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_var' AND p.clase = 'OBJECT') AS sp_que_puede_ejecutar;
INSERT INTO #resultado VALUES ('4.1', 'usr_var: inicio de sesión y rol',
       IIF(@login = 'usr_var' AND @usuario = 'usr_var' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión ', @login, '; miembro de rol_var = ', @en_rol, '; otros roles = ', @otros));
GO

-- ============================================================
-- 4.2 Lo que puede hacer el VAR
-- ============================================================

PRINT '--- 4.2 usr_var: lo que puede hacer';
-- Ejecuta sus reportes y corrige de verdad un gol y una tarjeta (corregir y anular), mostrando lo que queda
-- guardado antes y después de cada corrección. Como todos los partidos están finalizados y el motor no deja
-- corregir un partido finalizado, el DBA lo reabre dentro de una transacción que se deshace al final. Las demás
-- correcciones (tarjeta que no se vio, informe de la revisión) se piden sobre datos inexistentes: el VAR puede
-- ejecutarlas y las rechaza su validación, sin cambios.
-- Resultado esperado: los reportes se ejecutan; las correcciones, rechazadas por validación (no por permisos).
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
DECLARE @gol INT, @g_min INT, @g_tipo VARCHAR(15), @g_per VARCHAR(20), @g_asi INT, @g_partido INT,
        @tj INT, @t_min INT, @t_per VARCHAR(25), @t_partido INT;
SELECT TOP 1 @gol = g.gol_id, @g_min = g.minuto, @g_tipo = g.tipo_gol, @g_per = g.periodo,
             @g_asi = g.asistencia_jugador_id, @g_partido = vf.partido_id
FROM evento.gol g JOIN plantel.vw_formacion vf ON vf.formacion_id = g.formacion_id
WHERE g.periodo IN ('PT', 'ST') AND g.tipo_gol = 'jugada' ORDER BY g.gol_id;
SELECT TOP 1 @tj = t.tarjeta_id, @t_min = t.minuto, @t_per = t.periodo, @t_partido = t.partido_id
FROM evento.tarjeta t
WHERE NOT EXISTS (SELECT 1 FROM evento.suspension s WHERE s.tarjeta_id = t.tarjeta_id)
  AND NOT EXISTS (SELECT 1 FROM evento.tarjeta r WHERE r.partido_id = t.partido_id AND r.persona_id = t.persona_id
                  AND r.tipo_expulsion = 'doble_amarilla')
ORDER BY t.tarjeta_id;
EXECUTE AS LOGIN = 'usr_var';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC evento.reporte_tarjetas @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('evento.reporte_tarjetas', 'ok', 0);
    PRINT CONCAT('  PUEDE      evento.reporte_tarjetas', ' -> tarjetas de Argentina');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.reporte_tarjetas', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.reporte_tarjetas',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.reporte_designaciones;
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', 0);
    PRINT CONCAT('  PUEDE      arbitraje.reporte_designaciones', ' -> designaciones arbitrales');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.reporte_designaciones',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.gol_eliminar @gol_id = -1;
    INSERT INTO @r VALUES ('evento.gol_eliminar', 'validacion', 0);
    PRINT CONCAT('  PUEDE      evento.gol_eliminar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.gol_eliminar', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.gol_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.gol_modificar -1, 10, 'jugada', 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.gol_modificar', 'validacion', 0);
    PRINT CONCAT('  PUEDE      evento.gol_modificar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.gol_modificar', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.gol_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.tarjeta_modificar -1, 10, 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.tarjeta_modificar', 'validacion', 0);
    PRINT CONCAT('  PUEDE      evento.tarjeta_modificar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.tarjeta_modificar', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.tarjeta_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.tarjeta_eliminar @tarjeta_id = -1;
    INSERT INTO @r VALUES ('evento.tarjeta_eliminar', 'validacion', 0);
    PRINT CONCAT('  PUEDE      evento.tarjeta_eliminar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.tarjeta_eliminar', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.tarjeta_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.registrar_tarjeta @partido_id = -1, @minuto = 10, @periodo = 'primer_tiempo', @tipo = 'roja';
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'validacion', 0);
    PRINT CONCAT('  PUEDE      evento.registrar_tarjeta', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.registrar_tarjeta',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.informe_arbitral_insertar -1, NULL, NULL;
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_insertar', 'validacion', 0);
    PRINT CONCAT('  PUEDE      arbitraje.informe_arbitral_insertar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_insertar', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.informe_arbitral_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;
-- Corrección de un gol y de una tarjeta, dentro de una transacción que se deshace (no deja cambios).
BEGIN TRY
    IF @gol IS NULL OR @tj IS NULL
        THROW 50000, 'No hay goles o tarjetas cargados: ejecutar antes 1_entrega7_carga_datos.sql.', 1;
    BEGIN TRANSACTION;
    UPDATE torneo.partido SET estado = 'programado' WHERE partido_id IN (@g_partido, @t_partido);   -- lo hace el DBA
    SELECT 'GOL ANTES' AS paso, gol_id, minuto, tipo_gol, periodo FROM evento.gol WHERE gol_id = @gol;

    EXECUTE AS LOGIN = 'usr_var';
    EXEC evento.gol_modificar @gol, @g_min, 'cabezazo', @g_per, @g_asi;
    REVERT;
    SELECT 'GOL CORREGIDO' AS paso, gol_id, minuto, tipo_gol, periodo FROM evento.gol WHERE gol_id = @gol;
    PRINT '  PUEDE      evento.gol_modificar -> tipo de gol corregido a cabezazo';

    EXECUTE AS LOGIN = 'usr_var';
    EXEC evento.gol_eliminar @gol;
    REVERT;
    SELECT 'GOL ANULADO' AS paso, COUNT(*) AS filas_del_gol FROM evento.gol WHERE gol_id = @gol;
    PRINT '  PUEDE      evento.gol_eliminar -> gol anulado';

    SELECT 'TARJETA ANTES' AS paso, tarjeta_id, tipo, minuto, periodo, motivo FROM evento.tarjeta WHERE tarjeta_id = @tj;
    EXECUTE AS LOGIN = 'usr_var';
    EXEC evento.tarjeta_modificar @tj, @t_min, @t_per, 'Motivo corregido por el VAR';
    REVERT;
    SELECT 'TARJETA CORREGIDA' AS paso, tarjeta_id, tipo, minuto, periodo, motivo FROM evento.tarjeta WHERE tarjeta_id = @tj;
    PRINT '  PUEDE      evento.tarjeta_modificar -> motivo de la tarjeta corregido';

    EXECUTE AS LOGIN = 'usr_var';
    EXEC evento.tarjeta_eliminar @tj;
    REVERT;
    SELECT 'TARJETA ANULADA' AS paso, COUNT(*) AS filas_de_la_tarjeta FROM evento.tarjeta WHERE tarjeta_id = @tj;
    PRINT '  PUEDE      evento.tarjeta_eliminar -> tarjeta anulada';

    ROLLBACK TRANSACTION;
    DECLARE @sigue_gol INT = (SELECT COUNT(*) FROM evento.gol WHERE gol_id = @gol),
            @sigue_tarjeta INT = (SELECT COUNT(*) FROM evento.tarjeta WHERE tarjeta_id = @tj);
    PRINT CONCAT('  (transacción deshecha: el gol vuelve a existir = ', @sigue_gol, ', la tarjeta vuelve a existir = ', @sigue_tarjeta, ')');
    INSERT INTO @r VALUES ('evento.gol_modificar (real)', 'ok', 0), ('evento.gol_eliminar (real)', 'ok', 0),
                          ('evento.tarjeta_modificar (real)', 'ok', 0), ('evento.tarjeta_eliminar (real)', 'ok', 0);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;   -- primero se deshace la transacción: con ella dañada, REVERT falla
    REVERT;
    INSERT INTO @r VALUES ('corrección real de un gol y una tarjeta', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'corrección real de un gol y una tarjeta',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 200)));
END CATCH;

INSERT INTO #resultado
SELECT '4.2', 'VAR: lo que puede hacer',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ============================================================
-- 4.3 El VAR intenta lo que hizo el comité arbitral
-- ============================================================

PRINT '--- 4.3 usr_var: intenta lo que hizo el comité arbitral';
-- Mismas operaciones que el comité arbitral ejecutó en 3.2 (salvo el reporte de designaciones, que el VAR
-- también tiene), más borrar un informe, y acceso a las tablas.
-- Resultado esperado: error 229 en todos los intentos.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_var';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC arbitraje.arbitro_insertar 'Árbitro', 'De Prueba', @pais, 'FIFA', '1985-03-15', @id OUTPUT;
    INSERT INTO @r VALUES ('arbitraje.arbitro_insertar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      arbitraje.arbitro_insertar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_insertar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.arbitro_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.arbitro_modificar -1, 'Árbitro', 'De Prueba', @pais, 'FIFA', '1985-03-15';
    INSERT INTO @r VALUES ('arbitraje.arbitro_modificar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      arbitraje.arbitro_modificar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_modificar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.arbitro_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.consultar_arbitro;
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 'denegado', 0);
    PRINT CONCAT('  PUEDE      arbitraje.consultar_arbitro', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.consultar_arbitro',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.designar_arbitros -1, -1, -1, -1, -1, -1;
    INSERT INTO @r VALUES ('arbitraje.designar_arbitros', 'denegado', 0);
    PRINT CONCAT('  PUEDE      arbitraje.designar_arbitros', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.designar_arbitros', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.designar_arbitros',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.informe_arbitral_eliminar @informe_id = -1;
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_eliminar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      arbitraje.informe_arbitral_eliminar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_eliminar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.informe_arbitral_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    SELECT TOP (1) @x = tipo FROM evento.tarjeta;
    INSERT INTO @r VALUES ('SELECT evento.tarjeta', 'denegado', 0);
    PRINT CONCAT('  PUEDE      SELECT evento.tarjeta', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT evento.tarjeta', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'SELECT evento.tarjeta',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    UPDATE evento.tarjeta SET tipo = 'roja' WHERE tarjeta_id = -1;
    INSERT INTO @r VALUES ('UPDATE evento.tarjeta', 'denegado', 0);
    PRINT CONCAT('  PUEDE      UPDATE evento.tarjeta', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE evento.tarjeta', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'UPDATE evento.tarjeta',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '4.3', 'VAR: no puede lo del comité arbitral',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

PRINT '################ PARTE 5: usr_planillero (rol_planillero) ################';
GO

-- ============================================================
-- 5.1 Inicio de sesión
-- ============================================================

PRINT '--- 5.1 Inicio de sesión de usr_planillero';
-- Se simula el ingreso del usuario: a partir de EXECUTE AS LOGIN todo se ejecuta con sus permisos.
-- Resultado esperado: la sesión queda a nombre de usr_planillero, que pertenece sólo a rol_planillero.
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT;
EXECUTE AS LOGIN = 'usr_planillero';
SELECT @login = SUSER_SNAME(), @usuario = USER_NAME(), @en_rol = IS_MEMBER('rol_planillero');
REVERT;
SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_planillero' AND IS_ROLEMEMBER(rol, 'usr_planillero') = 1;
SELECT @login AS sesion_iniciada_como, @usuario AS usuario_en_la_base, 'rol_planillero' AS rol, 'Oficial de partido en la sede' AS quien_es,
       (SELECT COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_planillero' AND p.clase = 'OBJECT') AS sp_que_puede_ejecutar;
INSERT INTO #resultado VALUES ('5.1', 'usr_planillero: inicio de sesión y rol',
       IIF(@login = 'usr_planillero' AND @usuario = 'usr_planillero' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión ', @login, '; miembro de rol_planillero = ', @en_rol, '; otros roles = ', @otros));
GO

-- ============================================================
-- 5.2 Lo que puede hacer el planillero
-- ============================================================

PRINT '--- 5.2 usr_planillero: lo que puede hacer';
-- Ejecuta sus reportes; la carga del partido (formación, gol, tarjeta, cambio y resultado) se pide sobre un
-- partido inexistente: el planillero puede ejecutarla y la rechaza su validación, sin cambios.
-- cargar_formacion prueba además el permiso sobre el tipo tabla plantel.tt_formacion_jugador.
-- Resultado esperado: los reportes se ejecutan; la carga, rechazada por validación (no por permisos).
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_planillero';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'final', @tabla_posiciones = 0;
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', 0);
    PRINT CONCAT('  PUEDE      torneo.reporte_resultados', ' -> resultado de la final');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.reporte_resultados',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC plantel.reporte_plantillas @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.reporte_plantillas', 'ok', 0);
    PRINT CONCAT('  PUEDE      plantel.reporte_plantillas', ' -> plantel de Argentina');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.reporte_plantillas', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.reporte_plantillas',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    DECLARE @jugadores plantel.tt_formacion_jugador; EXEC plantel.cargar_formacion -1, 'local', '4-4-2', @jugadores;
    INSERT INTO @r VALUES ('plantel.cargar_formacion', 'validacion', 0);
    PRINT CONCAT('  PUEDE      plantel.cargar_formacion', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.cargar_formacion', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.cargar_formacion',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.registrar_gol -1, 'local', 10, 10, 'jugada', 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.registrar_gol', 'validacion', 0);
    PRINT CONCAT('  PUEDE      evento.registrar_gol', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_gol', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.registrar_gol',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.registrar_tarjeta @partido_id = -1, @minuto = 10, @periodo = 'primer_tiempo', @tipo = 'amarilla';
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'validacion', 0);
    PRINT CONCAT('  PUEDE      evento.registrar_tarjeta', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.registrar_tarjeta',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.registrar_sustitucion -1, 'local', 10, 20, 60, 'segundo_tiempo', 'tactico';
    INSERT INTO @r VALUES ('evento.registrar_sustitucion', 'validacion', 0);
    PRINT CONCAT('  PUEDE      evento.registrar_sustitucion', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_sustitucion', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.registrar_sustitucion',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC torneo.registrar_resultado @partido_id = -1, @goles_local = 1, @goles_visitante = 0;
    INSERT INTO @r VALUES ('torneo.registrar_resultado', 'validacion', 0);
    PRINT CONCAT('  PUEDE      torneo.registrar_resultado', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.registrar_resultado', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.registrar_resultado',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '5.2', 'planillero: lo que puede hacer',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ============================================================
-- 5.3 El planillero intenta lo que hizo el VAR
-- ============================================================

PRINT '--- 5.3 usr_planillero: intenta lo que hizo el VAR';
-- Mismas correcciones que el VAR pidió en 4.2 (salvo registrar una tarjeta, que el planillero también puede),
-- su reporte de designaciones, y acceso a las tablas. Quien carga el partido no puede corregir ni anular lo cargado.
-- Resultado esperado: error 229 en todos los intentos.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_planillero';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC evento.gol_eliminar @gol_id = -1;
    INSERT INTO @r VALUES ('evento.gol_eliminar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      evento.gol_eliminar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.gol_eliminar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.gol_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.gol_modificar -1, 10, 'jugada', 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.gol_modificar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      evento.gol_modificar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.gol_modificar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.gol_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.tarjeta_modificar -1, 10, 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.tarjeta_modificar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      evento.tarjeta_modificar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.tarjeta_modificar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.tarjeta_modificar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.tarjeta_eliminar @tarjeta_id = -1;
    INSERT INTO @r VALUES ('evento.tarjeta_eliminar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      evento.tarjeta_eliminar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.tarjeta_eliminar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.tarjeta_eliminar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.informe_arbitral_insertar -1, NULL, NULL;
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_insertar', 'denegado', 0);
    PRINT CONCAT('  PUEDE      arbitraje.informe_arbitral_insertar', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_insertar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.informe_arbitral_insertar',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.reporte_designaciones;
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'denegado', 0);
    PRINT CONCAT('  PUEDE      arbitraje.reporte_designaciones', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.reporte_designaciones',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    SELECT TOP (1) @x = fase FROM torneo.partido;
    INSERT INTO @r VALUES ('SELECT torneo.partido', 'denegado', 0);
    PRINT CONCAT('  PUEDE      SELECT torneo.partido', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT torneo.partido', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'SELECT torneo.partido',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    UPDATE evento.gol SET minuto = minuto WHERE gol_id = -1;
    INSERT INTO @r VALUES ('UPDATE evento.gol', 'denegado', 0);
    PRINT CONCAT('  PUEDE      UPDATE evento.gol', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE evento.gol', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'UPDATE evento.gol',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '5.3', 'planillero: no puede lo del VAR',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

PRINT '################ PARTE 6: usr_consulta (rol_consulta) ################';
GO

-- ============================================================
-- 6.1 Inicio de sesión
-- ============================================================

PRINT '--- 6.1 Inicio de sesión de usr_consulta';
-- Se simula el ingreso del usuario: a partir de EXECUTE AS LOGIN todo se ejecuta con sus permisos.
-- Resultado esperado: la sesión queda a nombre de usr_consulta, que pertenece sólo a rol_consulta.
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT;
EXECUTE AS LOGIN = 'usr_consulta';
SELECT @login = SUSER_SNAME(), @usuario = USER_NAME(), @en_rol = IS_MEMBER('rol_consulta');
REVERT;
SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_consulta' AND IS_ROLEMEMBER(rol, 'usr_consulta') = 1;
SELECT @login AS sesion_iniciada_como, @usuario AS usuario_en_la_base, 'rol_consulta' AS rol, 'Prensa o público' AS quien_es,
       (SELECT COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_consulta' AND p.clase = 'OBJECT') AS sp_que_puede_ejecutar;
INSERT INTO #resultado VALUES ('6.1', 'usr_consulta: inicio de sesión y rol',
       IIF(@login = 'usr_consulta' AND @usuario = 'usr_consulta' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión ', @login, '; miembro de rol_consulta = ', @en_rol, '; otros roles = ', @otros));
GO

-- ============================================================
-- 6.2 Lo que puede hacer el usuario de consulta
-- ============================================================

PRINT '--- 6.2 usr_consulta: lo que puede hacer';
-- Ejecuta los siete reportes de la Entrega 7 (con filtros, para acotar la salida).
-- Resultado esperado: los siete se ejecutan.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_consulta';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    EXEC evento.reporte_goleadores @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('evento.reporte_goleadores', 'ok', 0);
    PRINT CONCAT('  PUEDE      evento.reporte_goleadores', ' -> goleadores de Argentina');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.reporte_goleadores', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.reporte_goleadores',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.reporte_tarjetas @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('evento.reporte_tarjetas', 'ok', 0);
    PRINT CONCAT('  PUEDE      evento.reporte_tarjetas', ' -> tarjetas de Argentina');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.reporte_tarjetas', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.reporte_tarjetas',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC arbitraje.reporte_designaciones;
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', 0);
    PRINT CONCAT('  PUEDE      arbitraje.reporte_designaciones', ' -> designaciones arbitrales');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'arbitraje.reporte_designaciones',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.reporte_ocupacion @sede_id = @sede;
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.reporte_ocupacion', ' -> ocupación de una sede');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.reporte_ocupacion',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC publicidad.reporte_matriz_prime_time @partido_id = @partido;
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', 0);
    PRINT CONCAT('  PUEDE      publicidad.reporte_matriz_prime_time', ' -> matriz de prime time de la final');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'publicidad.reporte_matriz_prime_time',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC plantel.reporte_plantillas @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.reporte_plantillas', 'ok', 0);
    PRINT CONCAT('  PUEDE      plantel.reporte_plantillas', ' -> plantel de Argentina');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.reporte_plantillas', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.reporte_plantillas',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'final', @tabla_posiciones = 0;
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', 0);
    PRINT CONCAT('  PUEDE      torneo.reporte_resultados', ' -> resultado de la final');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.reporte_resultados',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '6.2', 'consulta: lo que puede hacer',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ============================================================
-- 6.3 El usuario de consulta intenta lo que hizo el planillero
-- ============================================================

PRINT '--- 6.3 usr_consulta: intenta lo que hizo el planillero';
-- Misma carga del partido que pidió el planillero en 5.2, y acceso a las tablas: el usuario de consulta sólo lee
-- reportes.
-- Resultado esperado: error 229 en todos los intentos.
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);
EXECUTE AS LOGIN = 'usr_consulta';
PRINT CONCAT('Sesión: ', SUSER_SNAME());
BEGIN TRY
    DECLARE @jugadores plantel.tt_formacion_jugador; EXEC plantel.cargar_formacion -1, 'local', '4-4-2', @jugadores;
    INSERT INTO @r VALUES ('plantel.cargar_formacion', 'denegado', 0);
    PRINT CONCAT('  PUEDE      plantel.cargar_formacion', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.cargar_formacion', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'plantel.cargar_formacion',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.registrar_gol -1, 'local', 10, 10, 'jugada', 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.registrar_gol', 'denegado', 0);
    PRINT CONCAT('  PUEDE      evento.registrar_gol', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_gol', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.registrar_gol',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.registrar_tarjeta @partido_id = -1, @minuto = 10, @periodo = 'primer_tiempo', @tipo = 'amarilla';
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'denegado', 0);
    PRINT CONCAT('  PUEDE      evento.registrar_tarjeta', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.registrar_tarjeta',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC evento.registrar_sustitucion -1, 'local', 10, 20, 60, 'segundo_tiempo', 'tactico';
    INSERT INTO @r VALUES ('evento.registrar_sustitucion', 'denegado', 0);
    PRINT CONCAT('  PUEDE      evento.registrar_sustitucion', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_sustitucion', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'evento.registrar_sustitucion',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    EXEC torneo.registrar_resultado @partido_id = -1, @goles_local = 1, @goles_visitante = 0;
    INSERT INTO @r VALUES ('torneo.registrar_resultado', 'denegado', 0);
    PRINT CONCAT('  PUEDE      torneo.registrar_resultado', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.registrar_resultado', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'torneo.registrar_resultado',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    SELECT TOP (1) @x = fase FROM torneo.partido;
    INSERT INTO @r VALUES ('SELECT torneo.partido', 'denegado', 0);
    PRINT CONCAT('  PUEDE      SELECT torneo.partido', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT torneo.partido', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'SELECT torneo.partido',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
BEGIN TRY
    UPDATE torneo.partido SET goles_local = 9 WHERE partido_id = -1;
    INSERT INTO @r VALUES ('UPDATE torneo.partido', 'denegado', 0);
    PRINT CONCAT('  PUEDE      UPDATE torneo.partido', '');
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE torneo.partido', 'denegado', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '  NO PUEDE   ', '  PUEDE      '), 'UPDATE torneo.partido',
                 IIF(ERROR_NUMBER() = 229, ' -> permiso denegado (error 229)',
                     ' -> se ejecutó y lo rechazó su validación, sin cambios: '
                     + LEFT(REPLACE(REPLACE(ERROR_MESSAGE(), CHAR(13), ''), CHAR(10), ' '), 140)));
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '6.3', 'consulta: no puede lo del planillero',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)
                                         OR (esperado = 'denegado' AND error <> 229)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'ejecutado' WHEN error = 229 THEN 'denegado (229)'
                                              ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

PRINT '################ PARTE 7: COMPARACIÓN ENTRE USUARIOS ################';
GO

-- ============================================================
-- 7.1 Cuadro comparativo
-- ============================================================

PRINT '--- 7.1 Qué puede hacer cada usuario: cuadro comparativo';
-- Para cada operación, se le pregunta al motor (HAS_PERMS_BY_NAME) si cada usuario puede ejecutarla, con la
-- sesión de ese usuario. Los usuarios van de mayor a menor privilegio.
-- Resultado esperado: cada SÍ coincide con el cuadro de permisos de su rol (seguridad.permiso).
DECLARE @op TABLE (orden INT, sp NVARCHAR(260), operacion VARCHAR(100));
INSERT INTO @op VALUES
       (1, 'torneo.sede_insertar', 'Alta de una sede'),
       (2, 'plantel.consultar_convocatoria', 'Ver los motivos de alta y baja (cifrados)'),
       (3, 'publicidad.consultar_api_frankfurter', 'Consultar la API de cambio (importación)'),
       (4, 'publicidad.anunciante_insertar', 'Alta de un anunciante'),
       (5, 'publicidad.consultar_anunciante', 'Ver el contacto del anunciante (cifrado)'),
       (6, 'publicidad.asignar_espacios_partido', 'Asignar los espacios publicitarios'),
       (7, 'arbitraje.arbitro_insertar', 'Alta de un árbitro'),
       (8, 'arbitraje.consultar_arbitro', 'Ver la fecha de nacimiento del árbitro (cifrada)'),
       (9, 'arbitraje.designar_arbitros', 'Designar los árbitros de un partido'),
       (10, 'arbitraje.informe_arbitral_insertar', 'Cargar un informe arbitral'),
       (11, 'evento.gol_eliminar', 'Anular un gol'),
       (12, 'evento.registrar_tarjeta', 'Registrar una tarjeta'),
       (13, 'evento.registrar_gol', 'Registrar un gol'),
       (14, 'plantel.cargar_formacion', 'Cargar la formación'),
       (15, 'arbitraje.reporte_designaciones', 'Reporte de designaciones'),
       (16, 'torneo.reporte_resultados', 'Reporte de resultados');
DECLARE @p TABLE (usuario SYSNAME, orden INT, puede INT);
EXECUTE AS LOGIN = 'usr_administrador';
INSERT INTO @p SELECT 'usr_administrador', orden, HAS_PERMS_BY_NAME(sp, 'OBJECT', 'EXECUTE') FROM @op;
REVERT;
EXECUTE AS LOGIN = 'usr_gestor_publicidad';
INSERT INTO @p SELECT 'usr_gestor_publicidad', orden, HAS_PERMS_BY_NAME(sp, 'OBJECT', 'EXECUTE') FROM @op;
REVERT;
EXECUTE AS LOGIN = 'usr_comite_arbitral';
INSERT INTO @p SELECT 'usr_comite_arbitral', orden, HAS_PERMS_BY_NAME(sp, 'OBJECT', 'EXECUTE') FROM @op;
REVERT;
EXECUTE AS LOGIN = 'usr_var';
INSERT INTO @p SELECT 'usr_var', orden, HAS_PERMS_BY_NAME(sp, 'OBJECT', 'EXECUTE') FROM @op;
REVERT;
EXECUTE AS LOGIN = 'usr_planillero';
INSERT INTO @p SELECT 'usr_planillero', orden, HAS_PERMS_BY_NAME(sp, 'OBJECT', 'EXECUTE') FROM @op;
REVERT;
EXECUTE AS LOGIN = 'usr_consulta';
INSERT INTO @p SELECT 'usr_consulta', orden, HAS_PERMS_BY_NAME(sp, 'OBJECT', 'EXECUTE') FROM @op;
REVERT;
SELECT o.operacion, o.sp,
       MAX(IIF(p.usuario = 'usr_administrador', IIF(p.puede = 1, 'SÍ', '-'), NULL)) AS [administrador],
       MAX(IIF(p.usuario = 'usr_gestor_publicidad', IIF(p.puede = 1, 'SÍ', '-'), NULL)) AS [gestor_publicidad],
       MAX(IIF(p.usuario = 'usr_comite_arbitral', IIF(p.puede = 1, 'SÍ', '-'), NULL)) AS [comite_arbitral],
       MAX(IIF(p.usuario = 'usr_var', IIF(p.puede = 1, 'SÍ', '-'), NULL)) AS [var],
       MAX(IIF(p.usuario = 'usr_planillero', IIF(p.puede = 1, 'SÍ', '-'), NULL)) AS [planillero],
       MAX(IIF(p.usuario = 'usr_consulta', IIF(p.puede = 1, 'SÍ', '-'), NULL)) AS [consulta]
FROM @op o JOIN @p p ON p.orden = o.orden
GROUP BY o.orden, o.operacion, o.sp
ORDER BY o.orden;
DECLARE @dif INT = (SELECT COUNT(*) FROM @p p JOIN @op o ON o.orden = p.orden
                    WHERE p.puede <> IIF(EXISTS (SELECT 1 FROM seguridad.permiso x
                                                 WHERE x.objeto = o.sp COLLATE DATABASE_DEFAULT
                                                   AND x.rol = CASE p.usuario
    WHEN 'usr_administrador' THEN 'rol_administrador'
    WHEN 'usr_gestor_publicidad' THEN 'rol_gestor_publicidad'
    WHEN 'usr_comite_arbitral' THEN 'rol_comite_arbitral'
    WHEN 'usr_var' THEN 'rol_var'
    WHEN 'usr_planillero' THEN 'rol_planillero'
    WHEN 'usr_consulta' THEN 'rol_consulta'
                                                   END), 1, 0));
INSERT INTO #resultado VALUES ('7.1', 'comparación: cada usuario puede exactamente lo de su rol',
       IIF(@dif = 0, 'OK', 'FALLO'), CONCAT(16, ' operaciones x 6 usuarios; diferencias con el cuadro: ', @dif));
GO

-- ============================================================
-- 7.2 Permisos efectivos de cada usuario
-- ============================================================

PRINT '--- 7.2 Permisos efectivos de cada usuario iguales al cuadro de su rol';
-- seguridad.comprobar_permisos le pregunta al motor, con la sesión de cada usuario, qué puede hacer sobre
-- TODOS los SP, tipos y tablas de la aplicación, y lo compara con el cuadro de su rol.
-- Resultado esperado: 0 diferencias y 0 tablas accesibles para los seis usuarios.
DECLARE @usuarios TABLE (orden INT, usuario SYSNAME);
INSERT INTO @usuarios VALUES (1, 'usr_administrador'), (2, 'usr_gestor_publicidad'), (3, 'usr_comite_arbitral'),
                             (4, 'usr_var'), (5, 'usr_planillero'), (6, 'usr_consulta');
DECLARE @res TABLE (usuario SYSNAME, sp_ejecutables INT, tablas_accesibles INT, diferencias_con_el_cuadro INT);
DECLARE @i INT = 1, @u SYSNAME, @sp INT, @tablas INT, @dif INT;
DECLARE @descarte TABLE (clase VARCHAR(10), objeto NVARCHAR(260), permiso VARCHAR(60), efectivo VARCHAR(20), segun_cuadro VARCHAR(20));
WHILE @i <= 6
BEGIN
    SELECT @u = usuario FROM @usuarios WHERE orden = @i;
    INSERT INTO @descarte EXEC seguridad.comprobar_permisos @u, @sp OUTPUT, @tablas OUTPUT, @dif OUTPUT;
    INSERT INTO @res VALUES (@u, @sp, @tablas, @dif);
    SET @i += 1;
END;
SELECT * FROM @res;
SELECT 'diferencia' AS atencion, * FROM @descarte;
INSERT INTO #resultado
SELECT '7.2', 'comparación: permisos efectivos iguales al cuadro (todos los SP y tablas)',
       IIF(SUM(diferencias_con_el_cuadro) = 0 AND SUM(tablas_accesibles) = 0, 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(usuario, ' ', sp_ejecutables, ' SP') AS VARCHAR(MAX)), ', ')
FROM @res;
GO

-- ============================================================
-- 7.3 Permiso de servidor para importar
-- ============================================================

PRINT '--- 7.3 Sólo el administrador tiene el permiso de servidor para importar archivos';
-- BULK INSERT y OPENROWSET(BULK) piden ADMINISTER BULK OPERATIONS, un permiso de servidor que se otorga al
-- inicio de sesión (no al rol). Se compara por SID: los nombres del servidor y de la base tienen distinta
-- intercalación.
-- Resultado esperado: entre los usuarios de los roles del sistema, sólo usr_administrador lo tiene.
DECLARE @con_bulk VARCHAR(500) = (
    SELECT STRING_AGG(u.name, ', ')
    FROM sys.server_permissions sp
    JOIN sys.server_principals l ON l.principal_id = sp.grantee_principal_id
    JOIN sys.database_principals u ON u.sid = l.sid
    WHERE sp.permission_name = 'ADMINISTER BULK OPERATIONS' AND sp.state = 'G'
      AND EXISTS (SELECT 1 FROM seguridad.rol r WHERE IS_ROLEMEMBER(r.rol, u.name) = 1));
SELECT ISNULL(@con_bulk, '(ninguno)') AS usuarios_con_administer_bulk_operations;
INSERT INTO #resultado VALUES ('7.3', 'comparación: sólo el administrador tiene ADMINISTER BULK OPERATIONS',
       IIF(@con_bulk = 'usr_administrador', 'OK', 'FALLO'), CONCAT('usuarios con el permiso: ', ISNULL(@con_bulk, '(ninguno)')));
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
