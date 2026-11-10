-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 8: Seguridad y respaldo - Usuarios de prueba
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Crea un usuario de prueba por rol con seguridad.crear_usuario (2_entrega8_roles.sql). El
--   script 5_entrega8_test_usuarios.sql los prueba, una parte por usuario. Lo ejecuta el DBA (sysadmin).
--   Es reejecutable: si el usuario ya existe, sólo verifica su rol.
--
--   La contraseña es de prueba, igual para los seis, y cumple la directiva de complejidad.
--   Los inicios de sesión quedan con MUST_CHANGE: en el primer ingreso real deben cambiarla.
--   Los tests no la usan: se hacen pasar por el usuario con EXECUTE AS LOGIN.
-- ============================================================

USE mundial_2026;
GO

DECLARE @contrasenia NVARCHAR(128) = N'Mundial2026_Prueba!';

EXEC seguridad.crear_usuario 'usr_administrador',     @contrasenia, 'rol_administrador';
EXEC seguridad.crear_usuario 'usr_comite_arbitral',   @contrasenia, 'rol_comite_arbitral';
EXEC seguridad.crear_usuario 'usr_planillero',        @contrasenia, 'rol_planillero';
EXEC seguridad.crear_usuario 'usr_var',               @contrasenia, 'rol_var';
EXEC seguridad.crear_usuario 'usr_gestor_publicidad', @contrasenia, 'rol_gestor_publicidad';
EXEC seguridad.crear_usuario 'usr_consulta',          @contrasenia, 'rol_consulta';
GO

-- Una versión anterior tenía un rol importador con su usuario de prueba: las importaciones ahora
-- las hace el administrador. Si quedó en la base, se borra (usuario e inicio de sesión).
IF DATABASE_PRINCIPAL_ID('usr_importador') IS NOT NULL OR SUSER_ID('usr_importador') IS NOT NULL
    EXEC seguridad.quitar_usuario 'usr_importador';
GO

-- Usuarios del sistema y su rol.
SELECT u.name AS usuario, r.name AS rol
FROM sys.database_role_members m
JOIN sys.database_principals r ON r.principal_id = m.role_principal_id
JOIN sys.database_principals u ON u.principal_id = m.member_principal_id
WHERE r.name IN (SELECT rol FROM seguridad.rol)
ORDER BY r.name;
GO
