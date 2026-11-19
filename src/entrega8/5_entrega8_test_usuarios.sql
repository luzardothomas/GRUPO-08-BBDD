-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 8: Seguridad y respaldo - Test de usuarios, roles y límites
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Simula el ingreso real de cada usuario de prueba (EXECUTE AS LOGIN) mostrando
--   explícitamente el cambio de sesión (ORIGINAL_LOGIN -> SUSER_SNAME -> REVERT),
--   lo que cada rol puede hacer, sus límites funcionales, de confidencialidad
--   (datos cifrados), de acceso directo a tablas y de política de respaldo/recuperación.
--
--   Los usuarios van de mayor a menor privilegio:
--     PARTE 1: usr_administrador      (rol_administrador,     109 SP)
--     PARTE 2: usr_gestor_publicidad  (rol_gestor_publicidad,  20 SP)
--     PARTE 3: usr_comite_arbitral    (rol_comite_arbitral,    16 SP)
--     PARTE 4: usr_var                (rol_var,                11 SP)
--     PARTE 5: usr_planillero         (rol_planillero,          9 SP)
--     PARTE 6: usr_consulta           (rol_consulta,            7 SP)
--     PARTE 7: comparación global entre los seis usuarios (cuadro comparativo,
--              permisos efectivos contra el cuadro, permiso de servidor para importar
--              y auditoría de límites de Política de Backup y Cifrado)
--
--   Cada parte tiene cuatro bloques:
--     n.1  momento del logueo: cambio de sesión, identidad activa y roles efectivos
--     n.2  lo que puede hacer: operaciones permitidas (con rollback / sin dejar cambios)
--     n.3  límites del usuario: operaciones denegadas por rol (229), datos cifrados (229),
--          acceso directo a tablas (229), tareas de DBA (229) y backups (262)
--     n.4  ficha resumen de alcance y límites del usuario
--
-- CÓMO EJECUTARLO:
--   Como DBA (sysadmin), después de 1_entrega8_cifrado.sql, 2_entrega8_roles.sql y
--   3_entrega8_usuarios.sql (sobre la base con las Entregas 5, 6 y 7 cargadas).
--   Compatible con ejecución completa (SSMS o recrear_db.ps1 -Pruebas) y por lotes.
-- ============================================================

USE mundial_2026;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- LOTE 0: PREPARACIÓN Y VERIFICACIÓN DE INICIOS DE SESIÓN
-- ============================================================

PRINT '================================================================================';
PRINT 'LOTE 0: PREPARACIÓN Y CONTROL PREVIO DE LOGINS Y POLÍTICA DE RECUPERACIÓN';
PRINT '================================================================================';
PRINT CONCAT('Sesión actual (DBA ejecutor): ', ORIGINAL_LOGIN(), ' | Base: ', DB_NAME(),
             ' | Modelo recuperación: ', CAST(DATABASEPROPERTYEX(DB_NAME(), 'Recovery') AS VARCHAR(20)));

DECLARE @faltan_scripts BIT =
    IIF(OBJECT_ID('seguridad.fn_descifrar', 'FN') IS NULL OR OBJECT_ID('seguridad.comprobar_permisos', 'P') IS NULL
        OR EXISTS (SELECT 1 FROM (VALUES ('usr_administrador'), ('usr_gestor_publicidad'), ('usr_comite_arbitral'),
                                         ('usr_var'), ('usr_planillero'), ('usr_consulta')) u (usuario)
                   WHERE DATABASE_PRINCIPAL_ID(u.usuario) IS NULL
                      OR SUSER_ID(u.usuario) IS NULL), 1, 0);
EXEC sp_set_session_context N'e8_faltan_scripts', @faltan_scripts;
IF @faltan_scripts = 1
    THROW 50000, 'Ejecutar antes 1_entrega8_cifrado.sql, 2_entrega8_roles.sql y 3_entrega8_usuarios.sql. No se ejecuta ninguna prueba.', 1;

-- Muestra los 6 inicios de sesión creados en el servidor antes de iniciar las impersonaciones
SELECT l.name AS login_servidor,
       u.name AS usuario_base_datos,
       r.rol AS rol_asignado,
       IIF(l.is_disabled = 0, 'HABILITADO', 'DESHABILITADO') AS estado_login,
       IIF(l.is_policy_checked = 1, 'SÍ', 'NO') AS politica_contrasenia_activa
FROM (VALUES ('usr_administrador',     'rol_administrador'),
             ('usr_gestor_publicidad', 'rol_gestor_publicidad'),
             ('usr_comite_arbitral',   'rol_comite_arbitral'),
             ('usr_var',               'rol_var'),
             ('usr_planillero',        'rol_planillero'),
             ('usr_consulta',          'rol_consulta')) r (usuario, rol)
JOIN sys.sql_logins l ON l.name = r.usuario
JOIN sys.database_principals u ON u.sid = l.sid;
GO

IF CAST(SESSION_CONTEXT(N'e8_faltan_scripts') AS BIT) = 1
    SET NOEXEC ON;
GO

IF OBJECT_ID('tempdb..#resultado') IS NOT NULL DROP TABLE #resultado;
CREATE TABLE #resultado (
    orden       INT IDENTITY(1, 1),
    prueba      VARCHAR(10),
    usuario     SYSNAME,
    descripcion VARCHAR(150),
    resultado   VARCHAR(5),
    detalle     VARCHAR(2100)
);
GO


-- ############################################################################
-- PARTE 1: usr_administrador (rol_administrador)
-- ############################################################################
PRINT '';
PRINT '################################################################################';
PRINT 'PARTE 1: usr_administrador (rol_administrador - Comité Organizador)';
PRINT '################################################################################';
GO

-- ------------------------------------------------------------
-- 1.1 Momento del logueo: usr_administrador
-- ------------------------------------------------------------
PRINT '--- 1.1 Momento del logueo: usr_administrador';
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT,
        @en_backup_op INT, @en_db_owner INT, @sp_hab INT;

PRINT CONCAT('  [PRE-LOGIN]  Sesión DBA actual: ', SUSER_SNAME());
EXECUTE AS LOGIN = 'usr_administrador';
PRINT CONCAT('  [LOGIN OK]   Sesión iniciada como: ', SUSER_SNAME(),
             ' | Usuario BD: ', USER_NAME(),
             ' | Original: ', ORIGINAL_LOGIN());

SELECT @login = SUSER_SNAME(),
       @usuario = USER_NAME(),
       @en_rol = IS_MEMBER('rol_administrador'),
       @en_backup_op = IS_MEMBER('db_backupoperator'),
       @en_db_owner = IS_MEMBER('db_owner');

-- Consulta ejecutada DENTRO de la sesión del usuario logueado
SELECT SUSER_SNAME() AS sesion_activa,
       ORIGINAL_LOGIN() AS sesion_origen_dba,
       USER_NAME() AS usuario_bd,
       'rol_administrador' AS rol_esperado,
       IS_MEMBER('rol_administrador') AS pertenece_a_su_rol,
       IS_MEMBER('db_backupoperator') AS es_backup_operator,
       IS_MEMBER('db_owner') AS es_db_owner,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP DATABASE') AS puede_hacer_backup;
REVERT;
PRINT CONCAT('  [LOGOUT]     Sesión restaurada a: ', SUSER_SNAME());

SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_administrador' AND IS_ROLEMEMBER(rol, 'usr_administrador') = 1;
SELECT @sp_hab = COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_administrador' AND p.clase = 'OBJECT';

INSERT INTO #resultado VALUES ('1.1', 'usr_administrador', 'Logueo, rol exclusivo y sin roles fijos privilegiados',
       IIF(@login = 'usr_administrador' AND @usuario = 'usr_administrador' AND @en_rol = 1
           AND @otros = 0 AND @en_backup_op = 0 AND @en_db_owner = 0, 'OK', 'FALLO'),
       CONCAT('sesión=', @login, '; rol_administrador=', @en_rol, '; otros_roles=', @otros,
              '; db_backupoperator=', @en_backup_op, '; db_owner=', @en_db_owner, '; SP_habilitados=', @sp_hab));
GO

-- ------------------------------------------------------------
-- 1.2 Lo que puede hacer usr_administrador
-- ------------------------------------------------------------
PRINT '--- 1.2 usr_administrador: operaciones permitidas (ABM, cifrados, reportes, APIs, importación)';
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @id INT;
DECLARE @sedes_json VARCHAR(500) = 'imports/scraping/sedes.json';
DECLARE @conv INT, @jug INT, @cupo INT = (SELECT valor FROM torneo.parametro WHERE clave = 'convocatoria_max_jugadores');
DECLARE @c TABLE (convocatoria_id INT, seleccion VARCHAR(200), dorsal INT, nombre VARCHAR(200), apellido VARCHAR(200),
                  fecha_alta DATE, motivo_alta VARCHAR(400), fecha_baja DATE, motivo_baja VARCHAR(400));

EXECUTE AS LOGIN = 'usr_administrador';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    EXEC torneo.sede_insertar 'Estadio de prueba', 'Ciudad de prueba', @pais, 50000, 'UTC-03', @id OUTPUT;
    INSERT INTO @r VALUES ('torneo.sede_insertar', 'ok', 0);
    PRINT CONCAT('    [PERMITIDO - EJECUTADO]  torneo.sede_insertar -> sede creada con id ', @id);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.sede_insertar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       torneo.sede_insertar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC torneo.sede_eliminar @id;
    INSERT INTO @r VALUES ('torneo.sede_eliminar', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  torneo.sede_eliminar -> sede de prueba eliminada';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.sede_eliminar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       torneo.sede_eliminar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 'ok', 0);
    PRINT '    [PERMITIDO - CIFRADO]    plantel.consultar_convocatoria -> lee motivos de alta/baja descifrados';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       plantel.consultar_convocatoria -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'final', @tabla_posiciones = 0;
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  torneo.reporte_resultados -> reporte de resultados';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       torneo.reporte_resultados -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC publicidad.reporte_matriz_prime_time @partido_id = @partido;
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.reporte_matriz_prime_time -> SQL dinámico (EXECUTE AS OWNER)';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       publicidad.reporte_matriz_prime_time -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC publicidad.consultar_api_frankfurter;
    INSERT INTO @r VALUES ('publicidad.consultar_api_frankfurter', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.consultar_api_frankfurter -> acceso a endpoint externo';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_api_frankfurter', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       publicidad.consultar_api_frankfurter -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC torneo.importar_sedes @sedes_json;
    INSERT INTO @r VALUES ('torneo.importar_sedes', 'validacion', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  torneo.importar_sedes';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.importar_sedes', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '    [DENEGADO - ERROR 229]   ', '    [PERMITIDO - VALIDACIÓN] '),
                 'torneo.importar_sedes -> pasó permiso BULK/SP; validó ruta inexistente (error ', ERROR_NUMBER(), ')');
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @cupo_nuevo INT = @cupo + 1;
    EXEC torneo.parametro_modificar 'convocatoria_max_jugadores', @cupo_nuevo;
    EXEC plantel.jugador_insertar 'Jugador', 'De Prueba', '2000-01-01', 'delantero', 'Club de prueba', @jug OUTPUT;
    EXEC plantel.convocatoria_insertar @seleccion, @jug, 99, '2026-06-02', 'Alta de prueba', @conv OUTPUT;
    EXEC plantel.convocatoria_modificar @conv, 98, '2026-06-02', 'Alta de prueba modificada', NULL, NULL;
    EXEC plantel.convocatoria_modificar @conv, 98, '2026-06-02', 'Alta de prueba modificada', '2026-06-20', 'Baja de prueba';
    ROLLBACK TRANSACTION;
    PRINT '    [PERMITIDO - EJECUTADO]  ABM completo de convocatoria con cifrado (revertido con ROLLBACK)';
    INSERT INTO @r VALUES ('torneo.parametro_modificar', 'ok', 0), ('plantel.jugador_insertar', 'ok', 0),
                          ('plantel.convocatoria_insertar', 'ok', 0), ('plantel.convocatoria_modificar', 'ok', 0);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT INTO @r VALUES ('plantel.convocatoria_abm', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       ABM convocatoria -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '1.2', 'usr_administrador', 'Operaciones permitidas (ABM, cifrados, reportes, APIs, importación)',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'OK' ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 1.3 Límites de usr_administrador (seguridad, tablas directas y backup)
-- ------------------------------------------------------------
PRINT '--- 1.3 usr_administrador: límites (no es DBA, no accede a tablas, no puede hacer BACKUP)';
DECLARE @r TABLE (intento VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @x VARCHAR(200), @err VARCHAR(2000);

EXECUTE AS LOGIN = 'usr_administrador';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

-- Límite 1: Administración de seguridad (tarea exclusiva del DBA)
BEGIN TRY
    EXEC seguridad.crear_usuario 'usr_nuevo', 'Clave_Prueba_2026!', 'rol_consulta';
    INSERT INTO @r VALUES ('seguridad.crear_usuario', 'denegado', 0);
    PRINT '    [FALLO SEGURIDAD]        seguridad.crear_usuario -> PUDO EJECUTAR';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('seguridad.crear_usuario', 'denegado', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TAREA DE DBA (', ERROR_NUMBER(), ')]     seguridad.crear_usuario -> no administra usuarios/roles');
END CATCH;

-- Límite 2: SP auxiliares internos (_validar)
BEGIN TRY
    EXEC torneo.sede_validar NULL, NULL, NULL, NULL, NULL, NULL, @err OUTPUT;
    INSERT INTO @r VALUES ('torneo.sede_validar', 'denegado', 0);
    PRINT '    [FALLO SEGURIDAD]        torneo.sede_validar -> PUDO EJECUTAR';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.sede_validar', 'denegado', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - SP INTERNO (', ERROR_NUMBER(), ')]       torneo.sede_validar -> sin EXECUTE en auxiliares');
END CATCH;

-- Límite 3: Acceso directo a tablas (DENY SELECT/UPDATE)
BEGIN TRY
    SELECT TOP (1) @x = apellido FROM plantel.jugador;
    INSERT INTO @r VALUES ('SELECT plantel.jugador', 'denegado', 0);
    PRINT '    [FALLO SEGURIDAD]        SELECT plantel.jugador -> PUDO LEER TABLA';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT plantel.jugador', 'denegado', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    SELECT plantel.jugador -> lectura directa bloqueada');
END CATCH;

BEGIN TRY
    UPDATE torneo.sede SET capacidad = capacidad WHERE sede_id = -1;
    INSERT INTO @r VALUES ('UPDATE torneo.sede', 'denegado', 0);
    PRINT '    [FALLO SEGURIDAD]        UPDATE torneo.sede -> PUDO MODIFICAR TABLA';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE torneo.sede', 'denegado', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    UPDATE torneo.sede -> escritura directa bloqueada');
END CATCH;

-- Límite 4: Política de Backup (Sección 8: ni siquiera el administrador puede respaldar o restaurar)
BEGIN TRY
    IF SUSER_SNAME() = 'usr_administrador'
        BACKUP DATABASE mundial_2026 TO DISK = 'NUL';
    INSERT INTO @r VALUES ('BACKUP DATABASE mundial_2026', 'denegado', 0);
    PRINT '    [FALLO SEGURIDAD]        BACKUP DATABASE -> PUDO RESPALDAR';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('BACKUP DATABASE mundial_2026', 'denegado', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - POLÍTICA BACKUP (', ERROR_NUMBER(), ')]  BACKUP DATABASE -> reservado al Agente SQL / DBA');
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '1.3', 'usr_administrador', 'Límites: sin creación de usuarios, sin tablas directas, sin BACKUP',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (intento <> 'BACKUP DATABASE mundial_2026' AND error <> 229)
                                         OR (intento = 'BACKUP DATABASE mundial_2026' AND error NOT IN (262, 229))), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(intento, ': denegado (', error, ')') AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 1.4 Ficha resumen de límites: usr_administrador
-- ------------------------------------------------------------
SELECT 'usr_administrador' AS usuario,
       'rol_administrador (Comité Organizador)' AS rol,
       '109 SP de negocio/ABM/reportes/importación + 4 consultas descifradas + ADMINISTER BULK OPERATIONS' AS alcance_permitido,
       'Sin acceso a tablas base, sin gestión de usuarios/roles, sin acceso directo a certificados/claves y sin permisos de BACKUP/RESTORE' AS limites_comprobados,
       IIF(EXISTS (SELECT 1 FROM #resultado WHERE usuario = 'usr_administrador' AND resultado <> 'OK'), 'FALLO', 'OK') AS estado_usuario;
GO


-- ############################################################################
-- PARTE 2: usr_gestor_publicidad (rol_gestor_publicidad)
-- ############################################################################
PRINT '';
PRINT '################################################################################';
PRINT 'PARTE 2: usr_gestor_publicidad (rol_gestor_publicidad - Área comercial)';
PRINT '################################################################################';
GO

-- ------------------------------------------------------------
-- 2.1 Momento del logueo: usr_gestor_publicidad
-- ------------------------------------------------------------
PRINT '--- 2.1 Momento del logueo: usr_gestor_publicidad';
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT, @sp_hab INT;

PRINT CONCAT('  [PRE-LOGIN]  Sesión DBA actual: ', SUSER_SNAME());
EXECUTE AS LOGIN = 'usr_gestor_publicidad';
PRINT CONCAT('  [LOGIN OK]   Sesión iniciada como: ', SUSER_SNAME(),
             ' | Usuario BD: ', USER_NAME(),
             ' | Original: ', ORIGINAL_LOGIN());

SELECT @login = SUSER_SNAME(),
       @usuario = USER_NAME(),
       @en_rol = IS_MEMBER('rol_gestor_publicidad');

SELECT SUSER_SNAME() AS sesion_activa,
       ORIGINAL_LOGIN() AS sesion_origen_dba,
       USER_NAME() AS usuario_bd,
       'rol_gestor_publicidad' AS rol_esperado,
       IS_MEMBER('rol_gestor_publicidad') AS pertenece_a_su_rol,
       IS_MEMBER('rol_administrador') AS es_administrador,
       IS_MEMBER('db_backupoperator') AS es_backup_operator,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP DATABASE') AS puede_hacer_backup;
REVERT;
PRINT CONCAT('  [LOGOUT]     Sesión restaurada a: ', SUSER_SNAME());

SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_gestor_publicidad' AND IS_ROLEMEMBER(rol, 'usr_gestor_publicidad') = 1;
SELECT @sp_hab = COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_gestor_publicidad' AND p.clase = 'OBJECT';

INSERT INTO #resultado VALUES ('2.1', 'usr_gestor_publicidad', 'Logueo y pertenencia exclusiva a rol_gestor_publicidad',
       IIF(@login = 'usr_gestor_publicidad' AND @usuario = 'usr_gestor_publicidad' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión=', @login, '; rol_gestor_publicidad=', @en_rol, '; otros_roles=', @otros, '; SP_habilitados=', @sp_hab));
GO

-- ------------------------------------------------------------
-- 2.2 Lo que puede hacer usr_gestor_publicidad
-- ------------------------------------------------------------
PRINT '--- 2.2 usr_gestor_publicidad: operaciones permitidas (ABM publicidad, contacto cifrado, reportes comerciales)';
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT;
DECLARE @a TABLE (anunciante_id INT, nombre VARCHAR(200), razon_social VARCHAR(200), contacto VARCHAR(400));

EXECUTE AS LOGIN = 'usr_gestor_publicidad';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    EXEC publicidad.anunciante_insertar 'Anunciante de prueba', 'Prueba S.A.', 'contacto@prueba.com', @id OUTPUT;
    INSERT INTO @r VALUES ('publicidad.anunciante_insertar', 'ok', 0);
    PRINT CONCAT('    [PERMITIDO - EJECUTADO]  publicidad.anunciante_insertar -> id ', @id);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_insertar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       publicidad.anunciante_insertar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    DELETE FROM @a;
    INSERT INTO @a EXEC publicidad.consultar_anunciante @anunciante_id = @id;
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', 'ok', 0);
    PRINT '    [PERMITIDO - CIFRADO]    publicidad.consultar_anunciante -> lee contacto descifrado del anunciante';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       publicidad.consultar_anunciante -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC publicidad.anunciante_modificar @id, 'Anunciante de prueba modificado', 'Prueba S.A. (modificada)', 'nuevo.contacto@prueba.com';
    INSERT INTO @r VALUES ('publicidad.anunciante_modificar', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.anunciante_modificar';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_modificar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       publicidad.anunciante_modificar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC publicidad.anunciante_eliminar @id;
    INSERT INTO @r VALUES ('publicidad.anunciante_eliminar', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.anunciante_eliminar -> registro de prueba borrado';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_eliminar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       publicidad.anunciante_eliminar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC publicidad.reporte_ocupacion @sede_id = @sede;
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.reporte_ocupacion';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       publicidad.reporte_ocupacion -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC publicidad.reporte_matriz_prime_time @partido_id = @partido;
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.reporte_matriz_prime_time';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       publicidad.reporte_matriz_prime_time -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC publicidad.asignar_espacios_partido @partido_id = -1;
    INSERT INTO @r VALUES ('publicidad.asignar_espacios_partido', 'validacion', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.asignar_espacios_partido';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.asignar_espacios_partido', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '    [DENEGADO - ERROR 229]   ', '    [PERMITIDO - VALIDACIÓN] '),
                 'publicidad.asignar_espacios_partido -> pasó permiso; validó partido -1 (error ', ERROR_NUMBER(), ')');
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '2.2', 'usr_gestor_publicidad', 'Operaciones permitidas (ABM publicidad, contacto cifrado, reportes)',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'OK' ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 2.3 Límites de usr_gestor_publicidad
-- ------------------------------------------------------------
PRINT '--- 2.3 usr_gestor_publicidad: límites (fuera de publicidad, otros cifrados, APIs, tablas)';
DECLARE @r TABLE (intento VARCHAR(100), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @id INT, @x VARCHAR(200);

EXECUTE AS LOGIN = 'usr_gestor_publicidad';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    EXEC torneo.sede_insertar 'Estadio de prueba', 'Ciudad de prueba', @pais, 50000, 'UTC-03', @id OUTPUT;
    INSERT INTO @r VALUES ('torneo.sede_insertar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.sede_insertar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    torneo.sede_insertar -> exclusivo de rol_administrador');
END CATCH;

BEGIN TRY
    EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   plantel.consultar_convocatoria -> no ve cifrados de plantel');
END CATCH;

BEGIN TRY
    EXEC arbitraje.consultar_arbitro;
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   arbitraje.consultar_arbitro -> no ve cifrados de arbitraje');
END CATCH;

BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'final', @tabla_posiciones = 0;
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.reporte_resultados', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    torneo.reporte_resultados -> sólo ve reportes de publicidad');
END CATCH;

BEGIN TRY
    EXEC publicidad.consultar_api_frankfurter;
    INSERT INTO @r VALUES ('publicidad.consultar_api_frankfurter', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_api_frankfurter', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    publicidad.consultar_api_frankfurter -> importación es de admin');
END CATCH;

BEGIN TRY
    SELECT TOP (1) @x = contacto FROM publicidad.anunciante;
    INSERT INTO @r VALUES ('SELECT publicidad.anunciante', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT publicidad.anunciante', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    SELECT publicidad.anunciante -> sin lectura directa de tabla');
END CATCH;

BEGIN TRY
    UPDATE publicidad.espacio_publicitario SET facturado = 1 WHERE espacio_id = -1;
    INSERT INTO @r VALUES ('UPDATE publicidad.espacio_publicitario', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE publicidad.espacio_publicitario', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    UPDATE publicidad.espacio_publicitario -> sin escritura directa');
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '2.3', 'usr_gestor_publicidad', 'Límites: sin torneo/plantel/arbitraje, sin APIs, sin tablas directas',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE error <> 229), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(intento, ': denegado (', error, ')') AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 2.4 Ficha resumen de límites: usr_gestor_publicidad
-- ------------------------------------------------------------
SELECT 'usr_gestor_publicidad' AS usuario,
       'rol_gestor_publicidad (Área comercial)' AS rol,
       '20 SP comerciales (ABM publicidad, asignar/facturar espacios, reportes ocupación/prime time y contacto cifrado)' AS alcance_permitido,
       'Sin acceso a torneo/plantel/eventos/arbitraje, sin reportes deportivos, sin APIs/importaciones, sin tablas directas ni backups' AS limites_comprobados,
       IIF(EXISTS (SELECT 1 FROM #resultado WHERE usuario = 'usr_gestor_publicidad' AND resultado <> 'OK'), 'FALLO', 'OK') AS estado_usuario;
GO


-- ############################################################################
-- PARTE 3: usr_comite_arbitral (rol_comite_arbitral)
-- ############################################################################
PRINT '';
PRINT '################################################################################';
PRINT 'PARTE 3: usr_comite_arbitral (rol_comite_arbitral - Comité arbitral)';
PRINT '################################################################################';
GO

-- ------------------------------------------------------------
-- 3.1 Momento del logueo: usr_comite_arbitral
-- ------------------------------------------------------------
PRINT '--- 3.1 Momento del logueo: usr_comite_arbitral';
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT, @sp_hab INT;

PRINT CONCAT('  [PRE-LOGIN]  Sesión DBA actual: ', SUSER_SNAME());
EXECUTE AS LOGIN = 'usr_comite_arbitral';
PRINT CONCAT('  [LOGIN OK]   Sesión iniciada como: ', SUSER_SNAME(),
             ' | Usuario BD: ', USER_NAME(),
             ' | Original: ', ORIGINAL_LOGIN());

SELECT @login = SUSER_SNAME(),
       @usuario = USER_NAME(),
       @en_rol = IS_MEMBER('rol_comite_arbitral');

SELECT SUSER_SNAME() AS sesion_activa,
       ORIGINAL_LOGIN() AS sesion_origen_dba,
       USER_NAME() AS usuario_bd,
       'rol_comite_arbitral' AS rol_esperado,
       IS_MEMBER('rol_comite_arbitral') AS pertenece_a_su_rol,
       IS_MEMBER('rol_administrador') AS es_administrador,
       IS_MEMBER('db_backupoperator') AS es_backup_operator,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP DATABASE') AS puede_hacer_backup;
REVERT;
PRINT CONCAT('  [LOGOUT]     Sesión restaurada a: ', SUSER_SNAME());

SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_comite_arbitral' AND IS_ROLEMEMBER(rol, 'usr_comite_arbitral') = 1;
SELECT @sp_hab = COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_comite_arbitral' AND p.clase = 'OBJECT';

INSERT INTO #resultado VALUES ('3.1', 'usr_comite_arbitral', 'Logueo y pertenencia exclusiva a rol_comite_arbitral',
       IIF(@login = 'usr_comite_arbitral' AND @usuario = 'usr_comite_arbitral' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión=', @login, '; rol_comite_arbitral=', @en_rol, '; otros_roles=', @otros, '; SP_habilitados=', @sp_hab));
GO

-- ------------------------------------------------------------
-- 3.2 Lo que puede hacer usr_comite_arbitral
-- ------------------------------------------------------------
PRINT '--- 3.2 usr_comite_arbitral: operaciones permitidas (ABM árbitros/idiomas, ficha cifrada, designaciones)';
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @id INT;
DECLARE @a TABLE (arbitro_id INT, nombre VARCHAR(200), apellido VARCHAR(200), pais VARCHAR(200), categoria VARCHAR(50), fecha_nacimiento DATE);

EXECUTE AS LOGIN = 'usr_comite_arbitral';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    EXEC arbitraje.arbitro_insertar 'Árbitro', 'De Prueba', @pais, 'FIFA', '1985-03-15', @id OUTPUT;
    INSERT INTO @r VALUES ('arbitraje.arbitro_insertar', 'ok', 0);
    PRINT CONCAT('    [PERMITIDO - EJECUTADO]  arbitraje.arbitro_insertar -> id ', @id);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_insertar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       arbitraje.arbitro_insertar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC arbitraje.arbitro_idioma_insertar @id, 'español';
    INSERT INTO @r VALUES ('arbitraje.arbitro_idioma_insertar', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  arbitraje.arbitro_idioma_insertar';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_idioma_insertar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       arbitraje.arbitro_idioma_insertar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    DELETE FROM @a;
    INSERT INTO @a EXEC arbitraje.consultar_arbitro @arbitro_id = @id;
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 'ok', 0);
    PRINT '    [PERMITIDO - CIFRADO]    arbitraje.consultar_arbitro -> lee fecha de nacimiento descifrada';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       arbitraje.consultar_arbitro -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC arbitraje.arbitro_modificar @id, 'Árbitro', 'De Prueba Modificado', @pais, 'FIFA', '1986-04-16';
    INSERT INTO @r VALUES ('arbitraje.arbitro_modificar', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  arbitraje.arbitro_modificar';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_modificar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       arbitraje.arbitro_modificar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC arbitraje.arbitro_idioma_eliminar @id, 'español';
    EXEC arbitraje.arbitro_eliminar @id;
    INSERT INTO @r VALUES ('arbitraje.arbitro_eliminar', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  arbitraje.arbitro_idioma_eliminar y arbitraje.arbitro_eliminar';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_eliminar', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       arbitraje.arbitro_eliminar -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC arbitraje.reporte_designaciones;
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  arbitraje.reporte_designaciones';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       arbitraje.reporte_designaciones -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC arbitraje.designar_arbitros -1, -1, -1, -1, -1, -1;
    INSERT INTO @r VALUES ('arbitraje.designar_arbitros', 'validacion', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  arbitraje.designar_arbitros';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.designar_arbitros', 'validacion', ERROR_NUMBER());
    PRINT CONCAT(IIF(ERROR_NUMBER() = 229, '    [DENEGADO - ERROR 229]   ', '    [PERMITIDO - VALIDACIÓN] '),
                 'arbitraje.designar_arbitros -> pasó permiso; validó partido -1 (error ', ERROR_NUMBER(), ')');
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '3.2', 'usr_comite_arbitral', 'Operaciones permitidas (ABM árbitros, fecha nac. cifrada, designaciones)',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'OK' ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 3.3 Límites de usr_comite_arbitral
-- ------------------------------------------------------------
PRINT '--- 3.3 usr_comite_arbitral: límites (fuera de arbitraje, otros cifrados, tablas directas)';
DECLARE @r TABLE (intento VARCHAR(100), error INT);
DECLARE @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede),
        @id INT, @x VARCHAR(200);

EXECUTE AS LOGIN = 'usr_comite_arbitral';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    EXEC publicidad.anunciante_insertar 'Anunciante de prueba', 'Prueba S.A.', 'contacto@prueba.com', @id OUTPUT;
    INSERT INTO @r VALUES ('publicidad.anunciante_insertar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.anunciante_insertar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    publicidad.anunciante_insertar -> exclusivo de publicidad/admin');
END CATCH;

BEGIN TRY
    EXEC publicidad.consultar_anunciante;
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   publicidad.consultar_anunciante -> no ve cifrados comerciales');
END CATCH;

BEGIN TRY
    EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   plantel.consultar_convocatoria -> no ve cifrados de plantel');
END CATCH;

BEGIN TRY
    EXEC publicidad.reporte_ocupacion @sede_id = @sede;
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    publicidad.reporte_ocupacion -> sólo ve reporte_designaciones');
END CATCH;

BEGIN TRY
    SELECT TOP (1) @x = apellido FROM arbitraje.arbitro;
    INSERT INTO @r VALUES ('SELECT arbitraje.arbitro', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT arbitraje.arbitro', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    SELECT arbitraje.arbitro -> sin lectura directa de tabla');
END CATCH;

BEGIN TRY
    UPDATE arbitraje.designacion_arbitral SET rol = rol WHERE designacion_id = -1;
    INSERT INTO @r VALUES ('UPDATE arbitraje.designacion_arbitral', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE arbitraje.designacion_arbitral', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    UPDATE arbitraje.designacion_arbitral -> sin escritura directa');
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '3.3', 'usr_comite_arbitral', 'Límites: sin publicidad/plantel/torneo, sin otros cifrados, sin tablas',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE error <> 229), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(intento, ': denegado (', error, ')') AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 3.4 Ficha resumen de límites: usr_comite_arbitral
-- ------------------------------------------------------------
SELECT 'usr_comite_arbitral' AS usuario,
       'rol_comite_arbitral (Comité arbitral)' AS rol,
       '16 SP arbitrales (ABM árbitros/idiomas/designaciones/informes, designar_arbitros, reporte_designaciones y 2 consultas cifradas)' AS alcance_permitido,
       'Sin acceso a publicidad/torneo/plantel/eventos, sin datos cifrados de otras áreas, sin tablas directas ni backups' AS limites_comprobados,
       IIF(EXISTS (SELECT 1 FROM #resultado WHERE usuario = 'usr_comite_arbitral' AND resultado <> 'OK'), 'FALLO', 'OK') AS estado_usuario;
GO


-- ############################################################################
-- PARTE 4: usr_var (rol_var)
-- ############################################################################
PRINT '';
PRINT '################################################################################';
PRINT 'PARTE 4: usr_var (rol_var - Árbitro de VAR)';
PRINT '################################################################################';
GO

-- ------------------------------------------------------------
-- 4.1 Momento del logueo: usr_var
-- ------------------------------------------------------------
PRINT '--- 4.1 Momento del logueo: usr_var';
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT, @sp_hab INT;

PRINT CONCAT('  [PRE-LOGIN]  Sesión DBA actual: ', SUSER_SNAME());
EXECUTE AS LOGIN = 'usr_var';
PRINT CONCAT('  [LOGIN OK]   Sesión iniciada como: ', SUSER_SNAME(),
             ' | Usuario BD: ', USER_NAME(),
             ' | Original: ', ORIGINAL_LOGIN());

SELECT @login = SUSER_SNAME(),
       @usuario = USER_NAME(),
       @en_rol = IS_MEMBER('rol_var');

SELECT SUSER_SNAME() AS sesion_activa,
       ORIGINAL_LOGIN() AS sesion_origen_dba,
       USER_NAME() AS usuario_bd,
       'rol_var' AS rol_esperado,
       IS_MEMBER('rol_var') AS pertenece_a_su_rol,
       IS_MEMBER('rol_comite_arbitral') AS es_comite_arbitral,
       IS_MEMBER('rol_planillero') AS es_planillero,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP DATABASE') AS puede_hacer_backup;
REVERT;
PRINT CONCAT('  [LOGOUT]     Sesión restaurada a: ', SUSER_SNAME());

SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_var' AND IS_ROLEMEMBER(rol, 'usr_var') = 1;
SELECT @sp_hab = COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_var' AND p.clase = 'OBJECT';

INSERT INTO #resultado VALUES ('4.1', 'usr_var', 'Logueo y pertenencia exclusiva a rol_var',
       IIF(@login = 'usr_var' AND @usuario = 'usr_var' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión=', @login, '; rol_var=', @en_rol, '; otros_roles=', @otros, '; SP_habilitados=', @sp_hab));
GO

-- ------------------------------------------------------------
-- 4.2 Lo que puede hacer usr_var
-- ------------------------------------------------------------
PRINT '--- 4.2 usr_var: operaciones permitidas (correcciones de goles/tarjetas, informe VAR y reportes)';
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG');
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
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    EXEC evento.reporte_tarjetas @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('evento.reporte_tarjetas', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  evento.reporte_tarjetas';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.reporte_tarjetas', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       evento.reporte_tarjetas -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC arbitraje.reporte_designaciones;
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  arbitraje.reporte_designaciones';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       arbitraje.reporte_designaciones -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC evento.registrar_tarjeta @partido_id = -1, @minuto = 10, @periodo = 'primer_tiempo', @tipo = 'roja';
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'validacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'validacion', ERROR_NUMBER());
    PRINT CONCAT('    [PERMITIDO - VALIDACIÓN] evento.registrar_tarjeta -> pasó permiso; validó partido -1 (error ', ERROR_NUMBER(), ')');
END CATCH;

BEGIN TRY
    EXEC arbitraje.informe_arbitral_insertar -1, NULL, NULL;
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_insertar', 'validacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_insertar', 'validacion', ERROR_NUMBER());
    PRINT CONCAT('    [PERMITIDO - VALIDACIÓN] arbitraje.informe_arbitral_insertar -> pasó permiso; validó partido -1 (error ', ERROR_NUMBER(), ')');
END CATCH;
REVERT;

-- Prueba real de corrección y anulación de gol y tarjeta bajo transacción revertida
BEGIN TRY
    IF @gol IS NULL OR @tj IS NULL
        THROW 50000, 'No hay goles o tarjetas cargados: ejecutar antes 1_entrega7_carga_datos.sql.', 1;
    BEGIN TRANSACTION;
    UPDATE torneo.partido SET estado = 'programado' WHERE partido_id IN (@g_partido, @t_partido);

    EXECUTE AS LOGIN = 'usr_var';
    EXEC evento.gol_modificar @gol, @g_min, 'cabezazo', @g_per, @g_asi;
    EXEC evento.gol_eliminar @gol;
    EXEC evento.tarjeta_modificar @tj, @t_min, @t_per, 'Motivo corregido por el VAR';
    EXEC evento.tarjeta_eliminar @tj;
    REVERT;

    ROLLBACK TRANSACTION;
    PRINT '    [PERMITIDO - EJECUTADO]  gol_modificar, gol_eliminar, tarjeta_modificar, tarjeta_eliminar (revertidos con ROLLBACK)';
    INSERT INTO @r VALUES ('evento.gol_modificar', 'ok', 0), ('evento.gol_eliminar', 'ok', 0),
                          ('evento.tarjeta_modificar', 'ok', 0), ('evento.tarjeta_eliminar', 'ok', 0);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF SUSER_SNAME() <> ORIGINAL_LOGIN() REVERT;
    INSERT INTO @r VALUES ('correccion_real_var', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       corrección VAR -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

INSERT INTO #resultado
SELECT '4.2', 'usr_var', 'Operaciones permitidas (corregir/anular goles y tarjetas, informe VAR, reportes)',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'OK' ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 4.3 Límites de usr_var
-- ------------------------------------------------------------
PRINT '--- 4.3 usr_var: límites (no carga partidos como planillero, no gestiona árbitros, no ve cifrados)';
DECLARE @r TABLE (intento VARCHAR(100), error INT);
DECLARE @pais INT = (SELECT pais_id FROM torneo.pais WHERE codigo_iso = 'ARG'),
        @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @id INT, @x VARCHAR(200);

EXECUTE AS LOGIN = 'usr_var';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

-- Separación VAR vs Planillero: el VAR corrige goles, pero NO puede registrar goles ni resultados
BEGIN TRY
    EXEC evento.registrar_gol -1, 'local', 10, 10, 'jugada', 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.registrar_gol', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_gol', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    evento.registrar_gol -> exclusivo de rol_planillero/admin');
END CATCH;

BEGIN TRY
    EXEC torneo.registrar_resultado @partido_id = -1, @goles_local = 1, @goles_visitante = 0;
    INSERT INTO @r VALUES ('torneo.registrar_resultado', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.registrar_resultado', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    torneo.registrar_resultado -> exclusivo de rol_planillero/admin');
END CATCH;

-- Separación VAR vs Comité Arbitral
BEGIN TRY
    EXEC arbitraje.arbitro_insertar 'Árbitro', 'De Prueba', @pais, 'FIFA', '1985-03-15', @id OUTPUT;
    INSERT INTO @r VALUES ('arbitraje.arbitro_insertar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.arbitro_insertar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    arbitraje.arbitro_insertar -> exclusivo de rol_comite_arbitral');
END CATCH;

BEGIN TRY
    EXEC arbitraje.designar_arbitros -1, -1, -1, -1, -1, -1;
    INSERT INTO @r VALUES ('arbitraje.designar_arbitros', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.designar_arbitros', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    arbitraje.designar_arbitros -> exclusivo de rol_comite_arbitral');
END CATCH;

BEGIN TRY
    EXEC arbitraje.informe_arbitral_eliminar @informe_id = -1;
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_eliminar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_eliminar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    arbitraje.informe_arbitral_eliminar -> VAR sólo inserta informe');
END CATCH;

-- Cero acceso a datos cifrados
BEGIN TRY
    EXEC arbitraje.consultar_arbitro;
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   arbitraje.consultar_arbitro -> rol_var no ve datos cifrados');
END CATCH;

BEGIN TRY
    EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   plantel.consultar_convocatoria -> rol_var no ve datos cifrados');
END CATCH;

-- Cero acceso directo a tablas
BEGIN TRY
    SELECT TOP (1) @x = tipo FROM evento.tarjeta;
    INSERT INTO @r VALUES ('SELECT evento.tarjeta', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT evento.tarjeta', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    SELECT evento.tarjeta -> lectura directa bloqueada');
END CATCH;

BEGIN TRY
    UPDATE evento.tarjeta SET tipo = 'roja' WHERE tarjeta_id = -1;
    INSERT INTO @r VALUES ('UPDATE evento.tarjeta', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE evento.tarjeta', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    UPDATE evento.tarjeta -> escritura directa bloqueada');
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '4.3', 'usr_var', 'Límites: no registra goles/resultados, no designa árbitros, sin cifrados ni tablas',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE error <> 229), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(intento, ': denegado (', error, ')') AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 4.4 Ficha resumen de límites: usr_var
-- ------------------------------------------------------------
SELECT 'usr_var' AS usuario,
       'rol_var (Árbitro de VAR)' AS rol,
       '11 SP (modificar/eliminar goles y tarjetas, registrar tarjeta no vista, insertar informe VAR y 5 reportes deportivos/arbitrales)' AS alcance_permitido,
       'No carga goles/formaciones/cambios/resultados (planillero), no gestiona árbitros ni borra informes, sin datos cifrados, sin tablas ni backups' AS limites_comprobados,
       IIF(EXISTS (SELECT 1 FROM #resultado WHERE usuario = 'usr_var' AND resultado <> 'OK'), 'FALLO', 'OK') AS estado_usuario;
GO


-- ############################################################################
-- PARTE 5: usr_planillero (rol_planillero)
-- ############################################################################
PRINT '';
PRINT '################################################################################';
PRINT 'PARTE 5: usr_planillero (rol_planillero - Oficial de partido en la sede)';
PRINT '################################################################################';
GO

-- ------------------------------------------------------------
-- 5.1 Momento del logueo: usr_planillero
-- ------------------------------------------------------------
PRINT '--- 5.1 Momento del logueo: usr_planillero';
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT, @sp_hab INT;

PRINT CONCAT('  [PRE-LOGIN]  Sesión DBA actual: ', SUSER_SNAME());
EXECUTE AS LOGIN = 'usr_planillero';
PRINT CONCAT('  [LOGIN OK]   Sesión iniciada como: ', SUSER_SNAME(),
             ' | Usuario BD: ', USER_NAME(),
             ' | Original: ', ORIGINAL_LOGIN());

SELECT @login = SUSER_SNAME(),
       @usuario = USER_NAME(),
       @en_rol = IS_MEMBER('rol_planillero');

SELECT SUSER_SNAME() AS sesion_activa,
       ORIGINAL_LOGIN() AS sesion_origen_dba,
       USER_NAME() AS usuario_bd,
       'rol_planillero' AS rol_esperado,
       IS_MEMBER('rol_planillero') AS pertenece_a_su_rol,
       IS_MEMBER('rol_var') AS es_var,
       IS_MEMBER('db_backupoperator') AS es_backup_operator,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP DATABASE') AS puede_hacer_backup;
REVERT;
PRINT CONCAT('  [LOGOUT]     Sesión restaurada a: ', SUSER_SNAME());

SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_planillero' AND IS_ROLEMEMBER(rol, 'usr_planillero') = 1;
SELECT @sp_hab = COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_planillero' AND p.clase = 'OBJECT';

INSERT INTO #resultado VALUES ('5.1', 'usr_planillero', 'Logueo y pertenencia exclusiva a rol_planillero',
       IIF(@login = 'usr_planillero' AND @usuario = 'usr_planillero' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión=', @login, '; rol_planillero=', @en_rol, '; otros_roles=', @otros, '; SP_habilitados=', @sp_hab));
GO

-- ------------------------------------------------------------
-- 5.2 Lo que puede hacer usr_planillero
-- ------------------------------------------------------------
PRINT '--- 5.2 usr_planillero: operaciones permitidas (carga de partido, tipo tabla y 4 reportes)';
DECLARE @r TABLE (sp VARCHAR(100), esperado VARCHAR(12), error INT);
DECLARE @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG');

EXECUTE AS LOGIN = 'usr_planillero';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'final', @tabla_posiciones = 0;
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  torneo.reporte_resultados';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       torneo.reporte_resultados -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    EXEC plantel.reporte_plantillas @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.reporte_plantillas', 'ok', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  plantel.reporte_plantillas';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.reporte_plantillas', 'ok', ERROR_NUMBER());
    PRINT CONCAT('    [ERROR INESPERADO]       plantel.reporte_plantillas -> ', ERROR_NUMBER(), ': ', ERROR_MESSAGE());
END CATCH;

BEGIN TRY
    DECLARE @jugadores plantel.tt_formacion_jugador;
    EXEC plantel.cargar_formacion -1, 'local', '4-4-2', @jugadores;
    INSERT INTO @r VALUES ('plantel.cargar_formacion', 'validacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.cargar_formacion', 'validacion', ERROR_NUMBER());
    PRINT CONCAT('    [PERMITIDO - VALIDACIÓN] plantel.cargar_formacion (+ tipo tt_formacion_jugador) -> error negocio ', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC evento.registrar_gol -1, 'local', 10, 10, 'jugada', 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.registrar_gol', 'validacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_gol', 'validacion', ERROR_NUMBER());
    PRINT CONCAT('    [PERMITIDO - VALIDACIÓN] evento.registrar_gol -> error negocio ', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC evento.registrar_tarjeta @partido_id = -1, @minuto = 10, @periodo = 'primer_tiempo', @tipo = 'amarilla';
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'validacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_tarjeta', 'validacion', ERROR_NUMBER());
    PRINT CONCAT('    [PERMITIDO - VALIDACIÓN] evento.registrar_tarjeta -> error negocio ', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC evento.registrar_sustitucion -1, 'local', 10, 20, 60, 'segundo_tiempo', 'tactico';
    INSERT INTO @r VALUES ('evento.registrar_sustitucion', 'validacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_sustitucion', 'validacion', ERROR_NUMBER());
    PRINT CONCAT('    [PERMITIDO - VALIDACIÓN] evento.registrar_sustitucion -> error negocio ', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC torneo.registrar_resultado @partido_id = -1, @goles_local = 1, @goles_visitante = 0;
    INSERT INTO @r VALUES ('torneo.registrar_resultado', 'validacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.registrar_resultado', 'validacion', ERROR_NUMBER());
    PRINT CONCAT('    [PERMITIDO - VALIDACIÓN] torneo.registrar_resultado -> error negocio ', ERROR_NUMBER());
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '5.2', 'usr_planillero', 'Operaciones permitidas (carga de partido con TVP y 4 reportes deportivos)',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE (esperado = 'ok' AND error <> 0)
                                         OR (esperado = 'validacion' AND error NOT BETWEEN 50000 AND 50099)), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': ', CASE WHEN error = 0 THEN 'OK' ELSE CONCAT('validación (', error, ')') END) AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 5.3 Límites de usr_planillero
-- ------------------------------------------------------------
PRINT '--- 5.3 usr_planillero: límites (no anula/corrige eventos del VAR, no ve designaciones ni cifrados)';
DECLARE @r TABLE (intento VARCHAR(100), error INT);
DECLARE @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @x VARCHAR(200);

EXECUTE AS LOGIN = 'usr_planillero';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

-- Separación Planillero vs VAR: quien carga NO puede modificar ni anular
BEGIN TRY
    EXEC evento.gol_eliminar @gol_id = -1;
    INSERT INTO @r VALUES ('evento.gol_eliminar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.gol_eliminar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    evento.gol_eliminar -> exclusivo de rol_var/admin');
END CATCH;

BEGIN TRY
    EXEC evento.gol_modificar -1, 10, 'jugada', 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.gol_modificar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.gol_modificar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    evento.gol_modificar -> exclusivo de rol_var/admin');
END CATCH;

BEGIN TRY
    EXEC evento.tarjeta_modificar -1, 10, 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.tarjeta_modificar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.tarjeta_modificar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    evento.tarjeta_modificar -> exclusivo de rol_var/admin');
END CATCH;

BEGIN TRY
    EXEC evento.tarjeta_eliminar @tarjeta_id = -1;
    INSERT INTO @r VALUES ('evento.tarjeta_eliminar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.tarjeta_eliminar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    evento.tarjeta_eliminar -> exclusivo de rol_var/admin');
END CATCH;

BEGIN TRY
    EXEC arbitraje.informe_arbitral_insertar -1, NULL, NULL;
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_insertar', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.informe_arbitral_insertar', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    arbitraje.informe_arbitral_insertar -> exclusivo de VAR/arbitraje');
END CATCH;

BEGIN TRY
    EXEC arbitraje.reporte_designaciones;
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    arbitraje.reporte_designaciones -> sin acceso a reportes arbitrales');
END CATCH;

-- Cero acceso a datos cifrados
BEGIN TRY
    EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   plantel.consultar_convocatoria -> rol_planillero no ve datos cifrados');
END CATCH;

-- Cero acceso directo a tablas
BEGIN TRY
    SELECT TOP (1) @x = fase FROM torneo.partido;
    INSERT INTO @r VALUES ('SELECT torneo.partido', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT torneo.partido', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    SELECT torneo.partido -> lectura directa bloqueada');
END CATCH;

BEGIN TRY
    UPDATE evento.gol SET minuto = minuto WHERE gol_id = -1;
    INSERT INTO @r VALUES ('UPDATE evento.gol', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE evento.gol', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    UPDATE evento.gol -> escritura directa bloqueada');
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '5.3', 'usr_planillero', 'Límites: no corrige/anula eventos del VAR, sin arbitraje, sin cifrados ni tablas',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE error <> 229), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(intento, ': denegado (', error, ')') AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 5.4 Ficha resumen de límites: usr_planillero
-- ------------------------------------------------------------
SELECT 'usr_planillero' AS usuario,
       'rol_planillero (Oficial de partido en la sede)' AS rol,
       '9 SP (cargar formación, registrar gol/tarjeta/sustitución/resultado y 4 reportes deportivos) + tipo tt_formacion_jugador' AS alcance_permitido,
       'No modifica ni anula goles/tarjetas (función del VAR), sin informes/designaciones arbitrales, sin datos cifrados, sin tablas ni backups' AS limites_comprobados,
       IIF(EXISTS (SELECT 1 FROM #resultado WHERE usuario = 'usr_planillero' AND resultado <> 'OK'), 'FALLO', 'OK') AS estado_usuario;
GO


-- ############################################################################
-- PARTE 6: usr_consulta (rol_consulta)
-- ############################################################################
PRINT '';
PRINT '################################################################################';
PRINT 'PARTE 6: usr_consulta (rol_consulta - Prensa o público, sólo lectura de reportes)';
PRINT '################################################################################';
GO

-- ------------------------------------------------------------
-- 6.1 Momento del logueo: usr_consulta
-- ------------------------------------------------------------
PRINT '--- 6.1 Momento del logueo: usr_consulta';
DECLARE @login SYSNAME, @usuario SYSNAME, @en_rol INT, @otros INT, @sp_hab INT;

PRINT CONCAT('  [PRE-LOGIN]  Sesión DBA actual: ', SUSER_SNAME());
EXECUTE AS LOGIN = 'usr_consulta';
PRINT CONCAT('  [LOGIN OK]   Sesión iniciada como: ', SUSER_SNAME(),
             ' | Usuario BD: ', USER_NAME(),
             ' | Original: ', ORIGINAL_LOGIN());

SELECT @login = SUSER_SNAME(),
       @usuario = USER_NAME(),
       @en_rol = IS_MEMBER('rol_consulta');

SELECT SUSER_SNAME() AS sesion_activa,
       ORIGINAL_LOGIN() AS sesion_origen_dba,
       USER_NAME() AS usuario_bd,
       'rol_consulta' AS rol_esperado,
       IS_MEMBER('rol_consulta') AS pertenece_a_su_rol,
       IS_MEMBER('rol_planillero') AS es_planillero,
       IS_MEMBER('db_datareader') AS es_db_datareader,
       HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP DATABASE') AS puede_hacer_backup;
REVERT;
PRINT CONCAT('  [LOGOUT]     Sesión restaurada a: ', SUSER_SNAME());

SELECT @otros = COUNT(*) FROM seguridad.rol WHERE rol <> 'rol_consulta' AND IS_ROLEMEMBER(rol, 'usr_consulta') = 1;
SELECT @sp_hab = COUNT(*) FROM seguridad.permiso p WHERE p.rol = 'rol_consulta' AND p.clase = 'OBJECT';

INSERT INTO #resultado VALUES ('6.1', 'usr_consulta', 'Logueo y pertenencia exclusiva a rol_consulta (sin db_datareader)',
       IIF(@login = 'usr_consulta' AND @usuario = 'usr_consulta' AND @en_rol = 1 AND @otros = 0, 'OK', 'FALLO'),
       CONCAT('sesión=', @login, '; rol_consulta=', @en_rol, '; otros_roles=', @otros, '; SP_habilitados=', @sp_hab));
GO

-- ------------------------------------------------------------
-- 6.2 Lo que puede hacer usr_consulta
-- ------------------------------------------------------------
PRINT '--- 6.2 usr_consulta: operaciones permitidas (los 7 reportes de la Entrega 7)';
DECLARE @r TABLE (sp VARCHAR(100), error INT);
DECLARE @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @partido INT = (SELECT MIN(partido_id) FROM torneo.partido WHERE fase = 'final'),
        @sede INT = (SELECT MIN(sede_id) FROM torneo.sede);

EXECUTE AS LOGIN = 'usr_consulta';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    EXEC evento.reporte_goleadores @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('evento.reporte_goleadores', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  evento.reporte_goleadores';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.reporte_goleadores', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC evento.reporte_tarjetas @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('evento.reporte_tarjetas', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  evento.reporte_tarjetas';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.reporte_tarjetas', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC arbitraje.reporte_designaciones;
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  arbitraje.reporte_designaciones';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.reporte_designaciones', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC publicidad.reporte_ocupacion @sede_id = @sede;
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.reporte_ocupacion';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_ocupacion', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC publicidad.reporte_matriz_prime_time @partido_id = @partido;
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  publicidad.reporte_matriz_prime_time';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.reporte_matriz_prime_time', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC plantel.reporte_plantillas @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.reporte_plantillas', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  plantel.reporte_plantillas';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.reporte_plantillas', ERROR_NUMBER());
END CATCH;

BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'final', @tabla_posiciones = 0;
    INSERT INTO @r VALUES ('torneo.reporte_resultados', 0);
    PRINT '    [PERMITIDO - EJECUTADO]  torneo.reporte_resultados';
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.reporte_resultados', ERROR_NUMBER());
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '6.2', 'usr_consulta', 'Operaciones permitidas (ejecución de los 7 reportes oficiales)',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE error <> 0), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(sp, ': OK') AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 6.3 Límites de usr_consulta
-- ------------------------------------------------------------
PRINT '--- 6.3 usr_consulta: límites (cero escritura, cero datos cifrados, cero acceso directo a tablas)';
DECLARE @r TABLE (intento VARCHAR(100), error INT);
DECLARE @seleccion INT = (SELECT seleccion_id FROM torneo.seleccion s JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG'),
        @x VARCHAR(200);

EXECUTE AS LOGIN = 'usr_consulta';
PRINT CONCAT('  [ACTIVO] Sesión: ', SUSER_SNAME());

BEGIN TRY
    DECLARE @jugadores plantel.tt_formacion_jugador;
    EXEC plantel.cargar_formacion -1, 'local', '4-4-2', @jugadores;
    INSERT INTO @r VALUES ('plantel.cargar_formacion', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.cargar_formacion', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    plantel.cargar_formacion -> sin permisos de carga');
END CATCH;

BEGIN TRY
    EXEC evento.registrar_gol -1, 'local', 10, 10, 'jugada', 'primer_tiempo';
    INSERT INTO @r VALUES ('evento.registrar_gol', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('evento.registrar_gol', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    evento.registrar_gol -> sin permisos de escritura');
END CATCH;

BEGIN TRY
    EXEC torneo.registrar_resultado @partido_id = -1, @goles_local = 1, @goles_visitante = 0;
    INSERT INTO @r VALUES ('torneo.registrar_resultado', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('torneo.registrar_resultado', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - LÍMITE DE ROL (', ERROR_NUMBER(), ')]    torneo.registrar_resultado -> sin permisos de escritura');
END CATCH;

-- Bloqueo total sobre las consultas que descifran datos sensibles
BEGIN TRY
    EXEC plantel.consultar_convocatoria @seleccion_id = @seleccion;
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('plantel.consultar_convocatoria', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   plantel.consultar_convocatoria -> datos cifrados bloqueados');
END CATCH;

BEGIN TRY
    EXEC arbitraje.consultar_arbitro;
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('arbitraje.consultar_arbitro', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   arbitraje.consultar_arbitro -> datos cifrados bloqueados');
END CATCH;

BEGIN TRY
    EXEC publicidad.consultar_anunciante;
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('publicidad.consultar_anunciante', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - DATOS CIFRADOS (', ERROR_NUMBER(), ')]   publicidad.consultar_anunciante -> datos cifrados bloqueados');
END CATCH;

-- Bloqueo total sobre tablas directas
BEGIN TRY
    SELECT TOP (1) @x = fase FROM torneo.partido;
    INSERT INTO @r VALUES ('SELECT torneo.partido', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('SELECT torneo.partido', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    SELECT torneo.partido -> no es db_datareader');
END CATCH;

BEGIN TRY
    UPDATE torneo.partido SET goles_local = 9 WHERE partido_id = -1;
    INSERT INTO @r VALUES ('UPDATE torneo.partido', 0);
END TRY
BEGIN CATCH
    INSERT INTO @r VALUES ('UPDATE torneo.partido', ERROR_NUMBER());
    PRINT CONCAT('    [DENEGADO - TABLA DIRECTA (', ERROR_NUMBER(), ')]    UPDATE torneo.partido -> escritura directa bloqueada');
END CATCH;
REVERT;

INSERT INTO #resultado
SELECT '6.3', 'usr_consulta', 'Límites: sin escritura, sin consultas de datos cifrados, sin SELECT a tablas',
       IIF(NOT EXISTS (SELECT 1 FROM @r WHERE error <> 229), 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(intento, ': denegado (', error, ')') AS VARCHAR(MAX)), '; ')
FROM @r;
GO

-- ------------------------------------------------------------
-- 6.4 Ficha resumen de límites: usr_consulta
-- ------------------------------------------------------------
SELECT 'usr_consulta' AS usuario,
       'rol_consulta (Prensa o público)' AS rol,
       '7 SP de reportes públicos/estadísticos de la Entrega 7' AS alcance_permitido,
       'Sin ABM ni carga de partidos, sin consultas con datos cifrados (convocatorias/árbitros/anunciantes), sin SELECT directo a tablas ni backups' AS limites_comprobados,
       IIF(EXISTS (SELECT 1 FROM #resultado WHERE usuario = 'usr_consulta' AND resultado <> 'OK'), 'FALLO', 'OK') AS estado_usuario;
GO


-- ############################################################################
-- PARTE 7: COMPARACIÓN GLOBAL Y AUDITORÍA DE LÍMITES ENTRE LOS 6 USUARIOS
-- ############################################################################
PRINT '';
PRINT '################################################################################';
PRINT 'PARTE 7: COMPARACIÓN GLOBAL, PERMISOS EFECTIVOS Y POLÍTICA DE BACKUP';
PRINT '################################################################################';
GO

-- ------------------------------------------------------------
-- 7.1 Cuadro comparativo de operaciones entre los 6 usuarios
-- ------------------------------------------------------------
PRINT '--- 7.1 Cuadro comparativo de operaciones por usuario';
DECLARE @op TABLE (orden INT, sp NVARCHAR(260), operacion VARCHAR(100));
INSERT INTO @op VALUES
       (1,  'torneo.sede_insertar',                  'Alta de una sede'),
       (2,  'plantel.consultar_convocatoria',        'Ver motivos de convocatoria (cifrado)'),
       (3,  'publicidad.consultar_api_frankfurter',  'Consultar API de cambio (importación)'),
       (4,  'publicidad.anunciante_insertar',        'Alta de un anunciante'),
       (5,  'publicidad.consultar_anunciante',       'Ver contacto de anunciante (cifrado)'),
       (6,  'publicidad.asignar_espacios_partido',   'Asignar espacios publicitarios'),
       (7,  'arbitraje.arbitro_insertar',            'Alta de un árbitro'),
       (8,  'arbitraje.consultar_arbitro',           'Ver fecha nac. de árbitro (cifrado)'),
       (9,  'arbitraje.designar_arbitros',           'Designar árbitros de un partido'),
       (10, 'arbitraje.informe_arbitral_insertar',   'Cargar informe arbitral / revisión VAR'),
       (11, 'evento.gol_eliminar',                   'Anular un gol (VAR)'),
       (12, 'evento.registrar_tarjeta',              'Registrar una tarjeta'),
       (13, 'evento.registrar_gol',                  'Registrar un gol (planillero)'),
       (14, 'plantel.cargar_formacion',              'Cargar formación'),
       (15, 'arbitraje.reporte_designaciones',       'Reporte de designaciones'),
       (16, 'torneo.reporte_resultados',             'Reporte de resultados');

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

SELECT o.operacion,
       o.sp,
       MAX(IIF(p.usuario = 'usr_administrador',     IIF(p.puede = 1, 'SÍ', 'NO'), NULL)) AS [administrador],
       MAX(IIF(p.usuario = 'usr_gestor_publicidad', IIF(p.puede = 1, 'SÍ', 'NO'), NULL)) AS [gestor_publicidad],
       MAX(IIF(p.usuario = 'usr_comite_arbitral',   IIF(p.puede = 1, 'SÍ', 'NO'), NULL)) AS [comite_arbitral],
       MAX(IIF(p.usuario = 'usr_var',               IIF(p.puede = 1, 'SÍ', 'NO'), NULL)) AS [var],
       MAX(IIF(p.usuario = 'usr_planillero',        IIF(p.puede = 1, 'SÍ', 'NO'), NULL)) AS [planillero],
       MAX(IIF(p.usuario = 'usr_consulta',          IIF(p.puede = 1, 'SÍ', 'NO'), NULL)) AS [consulta]
FROM @op o
JOIN @p p ON p.orden = o.orden
GROUP BY o.orden, o.operacion, o.sp
ORDER BY o.orden;

DECLARE @dif INT = (
    SELECT COUNT(*)
    FROM @p p
    JOIN @op o ON o.orden = p.orden
    WHERE p.puede <> IIF(EXISTS (
        SELECT 1 FROM seguridad.permiso x
        WHERE x.objeto = o.sp COLLATE DATABASE_DEFAULT
          AND x.rol = CASE p.usuario
              WHEN 'usr_administrador'     THEN 'rol_administrador'
              WHEN 'usr_gestor_publicidad' THEN 'rol_gestor_publicidad'
              WHEN 'usr_comite_arbitral'   THEN 'rol_comite_arbitral'
              WHEN 'usr_var'               THEN 'rol_var'
              WHEN 'usr_planillero'        THEN 'rol_planillero'
              WHEN 'usr_consulta'          THEN 'rol_consulta'
          END), 1, 0)
);

INSERT INTO #resultado VALUES ('7.1', 'GLOBAL', 'Cuadro comparativo: 16 operaciones x 6 usuarios coinciden con seguridad.permiso',
       IIF(@dif = 0, 'OK', 'FALLO'), CONCAT('diferencias detectadas = ', @dif));
GO

-- ------------------------------------------------------------
-- 7.2 Permisos efectivos de cada usuario contra seguridad.comprobar_permisos
-- ------------------------------------------------------------
PRINT '--- 7.2 Permisos efectivos de cada usuario (0 diferencias y 0 tablas accesibles)';
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
IF EXISTS (SELECT 1 FROM @descarte)
    SELECT 'DIFERENCIA DETECTADA' AS atencion, * FROM @descarte;

INSERT INTO #resultado
SELECT '7.2', 'GLOBAL', 'Auditoría completa de objetos: 0 diferencias con cuadro y 0 tablas accesibles',
       IIF(SUM(diferencias_con_el_cuadro) = 0 AND SUM(tablas_accesibles) = 0, 'OK', 'FALLO'),
       STRING_AGG(CAST(CONCAT(usuario, '=', sp_ejecutables, ' SP (tablas=', tablas_accesibles, ')') AS VARCHAR(MAX)), ', ')
FROM @res;
GO

-- ------------------------------------------------------------
-- 7.3 Permiso de servidor para importar (ADMINISTER BULK OPERATIONS)
-- ------------------------------------------------------------
PRINT '--- 7.3 Permiso de servidor ADMINISTER BULK OPERATIONS (sólo usr_administrador)';
DECLARE @con_bulk VARCHAR(500) = (
    SELECT STRING_AGG(u.name, ', ')
    FROM sys.server_permissions sp
    JOIN sys.server_principals l ON l.principal_id = sp.grantee_principal_id
    JOIN sys.database_principals u ON u.sid = l.sid
    WHERE sp.permission_name = 'ADMINISTER BULK OPERATIONS' AND sp.state = 'G'
      AND EXISTS (SELECT 1 FROM seguridad.rol r WHERE IS_ROLEMEMBER(r.rol, u.name) = 1));

SELECT ISNULL(@con_bulk, '(ninguno)') AS usuarios_con_administer_bulk_operations;

INSERT INTO #resultado VALUES ('7.3', 'GLOBAL', 'Sólo usr_administrador posee ADMINISTER BULK OPERATIONS',
       IIF(@con_bulk = 'usr_administrador', 'OK', 'FALLO'),
       CONCAT('usuarios con permiso bulk: ', ISNULL(@con_bulk, '(ninguno)')));
GO

-- ------------------------------------------------------------
-- 7.4 Auditoría de Política de Backup, Roles Fijos y Cifrado (Secciones 8 y 11)
-- ------------------------------------------------------------
PRINT '--- 7.4 Auditoría de Política de Backup: ningún rol puede respaldar, restaurar ni ver claves';
DECLARE @aud TABLE (
    usuario               SYSNAME,
    backup_db             INT,
    backup_log            INT,
    es_backup_operator    INT,
    es_db_owner           INT,
    es_sysadmin           INT,
    claves_visibles       INT,
    certificados_visibles INT
);

DECLARE @u SYSNAME, @bk_db INT, @bk_log INT, @bop INT, @dbo INT, @sys INT, @keys INT, @certs INT;
DECLARE @lista TABLE (id INT IDENTITY(1,1), usuario SYSNAME);
INSERT INTO @lista VALUES ('usr_administrador'), ('usr_gestor_publicidad'), ('usr_comite_arbitral'),
                          ('usr_var'), ('usr_planillero'), ('usr_consulta');

DECLARE @idx INT = 1;
WHILE @idx <= 6
BEGIN
    SELECT @u = usuario FROM @lista WHERE id = @idx;
    EXECUTE AS LOGIN = @u;
    SELECT @bk_db  = HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP DATABASE'),
           @bk_log = HAS_PERMS_BY_NAME(DB_NAME(), 'DATABASE', 'BACKUP LOG'),
           @bop    = IS_MEMBER('db_backupoperator'),
           @dbo    = IS_MEMBER('db_owner'),
           @sys    = IS_SRVROLEMEMBER('sysadmin'),
           @keys   = (SELECT COUNT(*) FROM sys.symmetric_keys),
           @certs  = (SELECT COUNT(*) FROM sys.certificates);
    REVERT;

    INSERT INTO @aud VALUES (@u, @bk_db, @bk_log, @bop, @dbo, @sys, @keys, @certs);
    SET @idx += 1;
END;

SELECT usuario,
       IIF(backup_db = 0, 'DENEGADO', 'PERMITIDO') AS permiso_backup_db,
       IIF(backup_log = 0, 'DENEGADO', 'PERMITIDO') AS permiso_backup_log,
       IIF(es_backup_operator = 0, 'NO', 'SÍ') AS rol_db_backupoperator,
       IIF(es_db_owner = 0, 'NO', 'SÍ') AS rol_db_owner,
       IIF(es_sysadmin = 0, 'NO', 'SÍ') AS rol_sysadmin,
       claves_visibles AS acceso_directo_claves,
       certificados_visibles AS acceso_directo_certificados
FROM @aud;

DECLARE @modelo VARCHAR(20) = CAST(DATABASEPROPERTYEX(DB_NAME(), 'Recovery') AS VARCHAR(20));
DECLARE @violaciones INT = (
    SELECT COUNT(*) FROM @aud
    WHERE backup_db <> 0 OR backup_log <> 0 OR es_backup_operator <> 0
       OR es_db_owner <> 0 OR es_sysadmin <> 0
       OR claves_visibles <> 0 OR certificados_visibles <> 0
);

INSERT INTO #resultado VALUES ('7.4', 'GLOBAL', 'Política de Backup (Sec. 8 y 11): 0 permisos de backup/claves y modelo FULL',
       IIF(@violaciones = 0 AND @modelo = 'FULL', 'OK', 'FALLO'),
       CONCAT('modelo_recuperacion=', @modelo, '; violaciones_politica_backup=', @violaciones));
GO


-- ############################################################################
-- RESUMEN FINAL DE EJECUCIÓN
-- ############################################################################
PRINT '';
PRINT '================================================================================';
PRINT 'RESUMEN FINAL DE PRUEBAS DE USUARIOS, ROLES Y POLÍTICA DE RESPALDO';
PRINT '================================================================================';

SELECT resultado, COUNT(*) AS pruebas FROM #resultado GROUP BY resultado;
SELECT orden, prueba, usuario, descripcion, resultado, detalle FROM #resultado ORDER BY orden;

IF EXISTS (SELECT 1 FROM #resultado WHERE resultado <> 'OK')
    SELECT 'PRUEBAS FALLIDAS' AS atencion, prueba, usuario, descripcion, detalle
    FROM #resultado WHERE resultado <> 'OK' ORDER BY orden;
ELSE
    PRINT 'Todas las pruebas finalizaron con el resultado esperado (0 fallos).';

DECLARE @total VARCHAR(100) = (
    SELECT CONCAT('TOTAL: ', SUM(IIF(resultado = 'OK', 1, 0)), ' OK, ',
                           SUM(IIF(resultado = 'OK', 0, 1)), ' FALLO')
    FROM #resultado
);
PRINT @total;
GO

SET NOEXEC OFF;
GO