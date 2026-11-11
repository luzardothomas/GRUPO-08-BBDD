-- ============================================================
-- Prepara los usuarios de la aplicación (Entrega 9).
--
-- La aplicación usa dos usuarios de la Entrega 8, cada uno con su rol:
--   usr_gestor_publicidad (rol_gestor_publicidad)  ABM de anunciantes
--   usr_administrador     (rol_administrador)      importación de archivos y reportes XML
--
-- Los inicios de sesión de la Entrega 8 se crean con MUST_CHANGE: no pueden conectarse hasta que se les define la
-- contraseña. Este script se las define (sin MUST_CHANGE). Cambiar las contraseñas por las definitivas antes de
-- ejecutarlo y usar las mismas en config.local.json (ver config.ejemplo.json) o en las variables de entorno
-- DB_PASSWORD y DB_ADMIN_PASSWORD.
--
-- Requiere un inicio de sesión con permiso ALTER ANY LOGIN (por ejemplo, el administrador del servidor) y haber
-- ejecutado antes 3_entrega8_usuarios.sql. Se puede ejecutar más de una vez.
-- ============================================================
USE master;
GO

DECLARE @contrasenia_abm   NVARCHAR(128) = N'Mundial2026_Prueba!',
        @contrasenia_admin NVARCHAR(128) = N'Mundial2026_Prueba!',
        @sql NVARCHAR(MAX);

IF SUSER_ID('usr_gestor_publicidad') IS NULL OR SUSER_ID('usr_administrador') IS NULL
    PRINT 'FALLO: faltan los inicios de sesión de la Entrega 8. Ejecutar antes 3_entrega8_usuarios.sql.';
ELSE
BEGIN
    -- ALTER LOGIN no acepta la contraseña en una variable: se arma la sentencia (sólo con los dos valores de arriba).
    SET @sql = N'ALTER LOGIN usr_gestor_publicidad WITH PASSWORD = N''' + REPLACE(@contrasenia_abm, N'''', N'''''') + N''';'
             + N'ALTER LOGIN usr_administrador WITH PASSWORD = N''' + REPLACE(@contrasenia_admin, N'''', N'''''') + N''';';
    EXEC (@sql);
    PRINT 'OK: usr_gestor_publicidad y usr_administrador ya pueden conectarse con las contraseñas definidas en este script.';
END;
GO

-- Comprobación: ninguno de los dos debe quedar con MUST_CHANGE.
SELECT name AS inicio_de_sesion, IIF(LOGINPROPERTY(name, 'IsMustChange') = 1, 'debe cambiar la contraseña', 'listo') AS estado
FROM sys.sql_logins
WHERE name IN ('usr_gestor_publicidad', 'usr_administrador');
GO
