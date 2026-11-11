-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 8: Seguridad y respaldo - Roles y permisos
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Roles de seguridad de la base mundial_2026, implementados con SP (esquema seguridad):
--     seguridad.cargar_matriz       carga el cuadro de permisos (qué SP puede ejecutar cada rol)
--     seguridad.crear_roles         crea los roles y les aplica exactamente el cuadro
--     seguridad.crear_usuario       crea el inicio de sesión y el usuario, y lo asigna a un rol
--     seguridad.quitar_usuario      borra el usuario y su inicio de sesión
--     seguridad.comprobar_permisos  compara los permisos efectivos de un usuario con el cuadro
--   y dos vistas para documentar: seguridad.vw_cuadro_permisos (el cuadro esperado, un rol por
--   columna) y seguridad.vw_permisos_otorgados (lo que el motor tiene realmente otorgado).
--
--   Como pide el enunciado, la seguridad se aplica como modificación sobre los componentes ya
--   creados: no se tocan los scripts de las entregas anteriores.
--   Se ejecuta después de las Entregas 5, 6 y 7 y de 1_entrega8_cifrado.sql (otorga permisos sobre
--   sus SP, incluidos los de consulta de datos cifrados), con un inicio
--   de sesión sysadmin (el DBA): crear inicios de sesión y asignar roles son tareas del DBA, no
--   de rol_administrador. Es reejecutable. Si se vuelve a crear un SP de las entregas
--   anteriores, hay que volver a ejecutar este script (CREATE OR ALTER conserva los permisos,
--   pero un DROP + CREATE los pierde).
--
-- CRITERIO: PRINCIPIO DEL MÍNIMO PRIVILEGIO (Unidad 5)
--   * Los permisos se otorgan a roles, nunca a usuarios.
--   * Sólo EXECUTE sobre los SP que el usuario llama directamente, uno por uno (GRANT sobre el
--     objeto, el de menor alcance). Los SP auxiliares (_validar, utilidades de importación), las
--     funciones y las vistas los usa el SP por encadenamiento de propiedad: no reciben permiso.
--   * Ningún rol tiene permiso sobre las tablas: DENY SELECT, INSERT, UPDATE y DELETE sobre cada
--     esquema, para que quede explícito. El encadenamiento de propiedad no revisa ese DENY.
--   * Ningún rol pertenece a roles fijos (db_owner, db_datareader...) ni de servidor, y no se
--     otorga nada a public.
--   * Excepciones documentadas:
--       - plantel.cargar_formacion recibe un parámetro de tipo tabla: quien lo llama necesita
--         además EXECUTE sobre el tipo plantel.tt_formacion_jugador.
--       - Las importaciones (Entrega 6) usan BULK INSERT / OPENROWSET y la API REST: las ejecuta
--         rol_administrador, que recibe EXECUTE ANY EXTERNAL ENDPOINT en la base, y su inicio de
--         sesión, ADMINISTER BULK OPERATIONS en el servidor. Ningún otro rol los tiene.
--       - publicidad.reporte_matriz_prime_time usa SQL dinámico (corta el encadenamiento): la
--         sección 0 modifica el SP ya creado con WITH EXECUTE AS OWNER, en lugar de dar permisos
--         de lectura sobre las tablas.
--
-- SQL DINÁMICO: sólo para CREATE/GRANT/REVOKE/DENY de roles, inicios de sesión y usuarios, que
--   no aceptan el nombre del objeto ni la contraseña en una variable. Los nombres se validan
--   contra el catálogo y se escriben con QUOTENAME.
-- ============================================================

USE mundial_2026;
GO

SET QUOTED_IDENTIFIER ON;
GO

IF SCHEMA_ID('seguridad') IS NULL EXEC('CREATE SCHEMA seguridad');
GO

-- ============================================================
-- 0. MODIFICACIÓN DE COMPONENTES EXISTENTES
-- ============================================================

/* publicidad.reporte_matriz_prime_time (Entrega 7) arma la consulta con sp_executesql, porque las
 columnas del PIVOT salen de los datos. Con SQL dinámico el motor no aplica el encadenamiento de
 propiedad: revisa los permisos de quien llama sobre las tablas, que ningún rol tiene (y además
 tienen DENY). Se modifica el SP ya creado para que se ejecute como su dueño (WITH EXECUTE AS
 OWNER): alcanza con EXECUTE sobre el SP. Es seguro porque los valores viajan como parámetros de
 sp_executesql, sin concatenar datos del usuario. El cuerpo es el mismo de la Entrega 7; ALTER (y
 no CREATE OR ALTER) falla si el SP no existe: este script modifica, no crea. */

ALTER PROCEDURE publicidad.reporte_matriz_prime_time
    @partido_id               INT = NULL,
    @solo_mercados_con_piezas BIT = 1
WITH EXECUTE AS OWNER                 -- único cambio respecto de la Entrega 7
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @desde INT, @hasta INT, @columnas NVARCHAR(MAX), @sql NVARCHAR(MAX);

    SELECT @desde = valor FROM torneo.parametro WHERE clave = 'prime_time_hora_desde';
    SELECT @hasta = valor FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta';
    -- ISNULL: si el parámetro llega en NULL se usa el valor por defecto (1: sólo mercados con piezas).
    SET @solo_mercados_con_piezas = ISNULL(@solo_mercados_con_piezas, 1);

    IF @desde IS NULL OR @hasta IS NULL
        SET @errores += '- Faltan configurar los parámetros prime_time_hora_desde / prime_time_hora_hasta.' + @nl;
    IF @partido_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + CAST(@partido_id AS VARCHAR(12)) + '.' + @nl;

    SELECT @columnas = STRING_AGG(CAST(QUOTENAME(m.codigo_iso) AS NVARCHAR(MAX)), N', ')
                       WITHIN GROUP (ORDER BY m.codigo_iso)
    FROM torneo.pais m
    WHERE @solo_mercados_con_piezas = 0
       OR EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria pz WHERE pz.pais_mercado_id = m.pais_id);

    IF @columnas IS NULL
        SET @errores += '- No hay mercados para evaluar (no hay piezas publicitarias cargadas).' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.reporte_matriz_prime_time - consulta rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    SET @sql = N'
    WITH base AS (
        SELECT p.partido_id, p.fecha_hora_utc, p.fase,
               pl.codigo_iso + '' vs '' + pv.codigo_iso AS encuentro,
               m.codigo_iso AS mercado,
               ((DATEPART(HOUR, SWITCHOFFSET(p.fecha_hora_utc, ''+00:00''))
                 + CAST(SUBSTRING(m.huso_horario, 4, 3) AS INT)) % 24 + 24) % 24 AS hora_local
        FROM torneo.partido p
        JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
        JOIN torneo.pais pl      ON pl.pais_id = sl.pais_id
        JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
        JOIN torneo.pais pv      ON pv.pais_id = sv.pais_id
        CROSS JOIN torneo.pais m
        WHERE (@partido_id IS NULL OR p.partido_id = @partido_id)
          AND (@solo = 0 OR EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria pz
                                    WHERE pz.pais_mercado_id = m.pais_id))
    ),
    marcado AS (
        SELECT partido_id, fecha_hora_utc, fase, encuentro, mercado,
               IIF(hora_local >= @desde AND hora_local < @hasta, ''SI'', ''NO'') AS en_prime_time,
               SUM(IIF(hora_local >= @desde AND hora_local < @hasta, 1, 0))
                   OVER (PARTITION BY partido_id) AS mercados_en_prime_time
        FROM base
    )
    SELECT partido_id                                   AS Partido_id,
           CONVERT(VARCHAR(16), fecha_hora_utc, 120)    AS Fecha_UTC,
           fase                                         AS Fase,
           encuentro                                    AS Encuentro,
           mercados_en_prime_time                       AS Mercados_en_prime_time,
           ' + @columnas + N'
    FROM marcado
    PIVOT (MAX(en_prime_time) FOR mercado IN (' + @columnas + N')) AS pv
    ORDER BY fecha_hora_utc, partido_id;';

    EXEC sp_executesql @sql,
         N'@partido_id INT, @solo BIT, @desde INT, @hasta INT',
         @partido_id = @partido_id, @solo = @solo_mercados_con_piezas, @desde = @desde, @hasta = @hasta;
END;
GO

-- ============================================================
-- 1. TABLAS DEL CUADRO DE PERMISOS
-- ============================================================

-- Los roles del sistema.
IF OBJECT_ID('seguridad.rol', 'U') IS NULL
    CREATE TABLE seguridad.rol (
        rol         SYSNAME NOT NULL,
        descripcion VARCHAR(300) NOT NULL,

        CONSTRAINT pk_seguridad_rol PRIMARY KEY (rol),
        CONSTRAINT chk_seguridad_rol_nombre CHECK (rol LIKE 'rol[_]%')
    );
GO

-- El cuadro: qué permiso tiene cada rol y sobre qué. clase OBJECT = un SP, TYPE = un tipo de
-- datos, DATABASE = un permiso sobre la base (objeto NULL).
IF OBJECT_ID('seguridad.permiso', 'U') IS NULL
    CREATE TABLE seguridad.permiso (
        rol     SYSNAME NOT NULL,
        clase   VARCHAR(10) NOT NULL,
        objeto  NVARCHAR(260) NOT NULL DEFAULT N'',        -- esquema.nombre ('' para DATABASE)
        permiso VARCHAR(60) NOT NULL,
        motivo  VARCHAR(200) NOT NULL,                      -- para qué lo necesita el rol

        CONSTRAINT pk_seguridad_permiso PRIMARY KEY (rol, clase, objeto, permiso),
        CONSTRAINT fk_seguridad_permiso_rol FOREIGN KEY (rol) REFERENCES seguridad.rol (rol),
        CONSTRAINT chk_seguridad_permiso_clase CHECK (clase IN ('OBJECT', 'TYPE', 'DATABASE')),
        CONSTRAINT chk_seguridad_permiso_objeto CHECK ((clase = 'DATABASE' AND objeto = N'')
                                                       OR (clase <> 'DATABASE' AND objeto <> N''))
    );
GO

-- ============================================================
-- 2. CARGA DEL CUADRO
-- ============================================================

/* Seis roles. El cuadro se arma SP por SP para los roles operativos. rol_administrador recibe
 todos los SP de alta, baja, modificación, lógica de negocio, reportes, consultas e importación
 de los cinco módulos, menos los auxiliares (_validar, convertir_moneda), y los permisos que
 necesitan las importaciones. */

CREATE OR ALTER PROCEDURE seguridad.cargar_matriz
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @roles TABLE (rol SYSNAME, descripcion VARCHAR(300));
    INSERT INTO @roles VALUES
        ('rol_administrador',     'Comité Organizador: administra todos los datos del sistema con los SP e importa (archivos y APIs). No crea usuarios ni modifica la estructura (eso es del DBA).'),
        ('rol_comite_arbitral',   'Comité arbitral: árbitros, idiomas, designaciones (incluido el VAR) e informes arbitrales.'),
        ('rol_planillero',        'Oficial de partido en la sede: carga la formación, los goles, las tarjetas, los cambios y el resultado.'),
        ('rol_var',               'Árbitro de VAR: corrige lo revisado (anula o corrige goles y tarjetas, agrega tarjetas) y deja el informe.'),
        ('rol_gestor_publicidad', 'Área comercial: anunciantes, campañas, piezas, asignación y facturación de espacios.'),
        ('rol_consulta',          'Prensa o público: sólo los reportes de la Entrega 7.');

    DECLARE @matriz TABLE (rol SYSNAME, clase VARCHAR(10), objeto NVARCHAR(260), permiso VARCHAR(60), motivo VARCHAR(200));

    -- Reportes de la Entrega 7, por área.
    INSERT INTO @matriz (rol, clase, objeto, permiso, motivo)
    SELECT r.rol, 'OBJECT', o.objeto, 'EXECUTE', o.motivo
    FROM (VALUES ('evento.reporte_goleadores',          'partido', 'Reporte de goleadores'),
                 ('evento.reporte_tarjetas',            'partido', 'Reporte de tarjetas y suspensiones'),
                 ('torneo.reporte_resultados',          'partido', 'Reporte de resultados'),
                 ('plantel.reporte_plantillas',         'partido', 'Reporte de selecciones y plantillas'),
                 ('arbitraje.reporte_designaciones',    'arbitraje', 'Reporte de designaciones arbitrales'),
                 ('publicidad.reporte_ocupacion',       'publicidad', 'Reporte de ocupación publicitaria'),
                 ('publicidad.reporte_matriz_prime_time', 'publicidad', 'Matriz de prime time')) o (objeto, area, motivo)
    JOIN (VALUES ('rol_consulta', 'partido'), ('rol_consulta', 'arbitraje'), ('rol_consulta', 'publicidad'),
                 ('rol_planillero', 'partido'),
                 ('rol_var', 'partido'), ('rol_var', 'arbitraje'),
                 ('rol_comite_arbitral', 'arbitraje'),
                 ('rol_gestor_publicidad', 'publicidad')) r (rol, area) ON r.area = o.area;

    -- Roles operativos: SP por SP.
    INSERT INTO @matriz (rol, clase, objeto, permiso, motivo) VALUES
        -- Comité arbitral (módulo G)
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.arbitro_insertar',               'EXECUTE', 'Alta de árbitros'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.arbitro_modificar',              'EXECUTE', 'Modificación de árbitros'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.arbitro_eliminar',               'EXECUTE', 'Baja de árbitros'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.arbitro_idioma_insertar',        'EXECUTE', 'Idiomas del árbitro'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.arbitro_idioma_modificar',       'EXECUTE', 'Idiomas del árbitro'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.arbitro_idioma_eliminar',        'EXECUTE', 'Idiomas del árbitro'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.designar_arbitros',              'EXECUTE', 'Designa los cinco árbitros del partido, incluido el VAR'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.designacion_arbitral_insertar',  'EXECUTE', 'Designación individual'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.designacion_arbitral_modificar', 'EXECUTE', 'Cambio de designación'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.designacion_arbitral_eliminar',  'EXECUTE', 'Baja de designación'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.informe_arbitral_insertar',      'EXECUTE', 'Informes post-partido'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.informe_arbitral_modificar',     'EXECUTE', 'Informes post-partido'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.informe_arbitral_eliminar',      'EXECUTE', 'Informes post-partido'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.consultar_arbitro',              'EXECUTE', 'Ficha del árbitro con la fecha de nacimiento descifrada'),
        ('rol_comite_arbitral', 'OBJECT', 'arbitraje.consultar_informes',             'EXECUTE', 'Informes con el contenido y la sanción descifrados'),
        -- Planillero (módulos A, C, D, E y F: sólo la carga del partido)
        ('rol_planillero', 'OBJECT', 'plantel.cargar_formacion',     'EXECUTE', 'Formación titular y suplentes del partido'),
        ('rol_planillero', 'TYPE',   'plantel.tt_formacion_jugador', 'EXECUTE', 'Parámetro de tipo tabla de cargar_formacion'),
        ('rol_planillero', 'OBJECT', 'evento.registrar_gol',         'EXECUTE', 'Registra un gol'),
        ('rol_planillero', 'OBJECT', 'evento.registrar_tarjeta',     'EXECUTE', 'Registra una tarjeta'),
        ('rol_planillero', 'OBJECT', 'evento.registrar_sustitucion', 'EXECUTE', 'Registra un cambio'),
        ('rol_planillero', 'OBJECT', 'torneo.registrar_resultado',   'EXECUTE', 'Registra el resultado final y la asistencia'),
        -- VAR (corrige lo que revisa)
        ('rol_var', 'OBJECT', 'evento.registrar_tarjeta',            'EXECUTE', 'Tarjeta que no se vio en cancha (por ejemplo, roja tras la revisión)'),
        ('rol_var', 'OBJECT', 'evento.tarjeta_modificar',            'EXECUTE', 'Corrige minuto, período o motivo de una tarjeta'),
        ('rol_var', 'OBJECT', 'evento.tarjeta_eliminar',             'EXECUTE', 'Anula una tarjeta mal aplicada'),
        ('rol_var', 'OBJECT', 'evento.gol_modificar',                'EXECUTE', 'Corrige un gol (minuto, tipo, asistencia)'),
        ('rol_var', 'OBJECT', 'evento.gol_eliminar',                 'EXECUTE', 'Anula un gol (actualiza el marcador)'),
        ('rol_var', 'OBJECT', 'arbitraje.informe_arbitral_insertar', 'EXECUTE', 'Deja asentada la revisión'),
        -- Gestor de publicidad (módulo H)
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.anunciante_insertar',             'EXECUTE', 'Anunciantes'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.anunciante_modificar',            'EXECUTE', 'Anunciantes'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.anunciante_eliminar',             'EXECUTE', 'Anunciantes'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.campania_insertar',               'EXECUTE', 'Campañas'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.campania_modificar',              'EXECUTE', 'Campañas'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.campania_eliminar',               'EXECUTE', 'Campañas'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.campania_pais_interes_insertar',  'EXECUTE', 'Países de interés de la campaña'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.campania_pais_interes_modificar', 'EXECUTE', 'Países de interés de la campaña'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.campania_pais_interes_eliminar',  'EXECUTE', 'Países de interés de la campaña'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.pieza_publicitaria_insertar',     'EXECUTE', 'Piezas por idioma y mercado'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.pieza_publicitaria_modificar',    'EXECUTE', 'Piezas por idioma y mercado'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.pieza_publicitaria_eliminar',     'EXECUTE', 'Piezas por idioma y mercado'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.espacio_publicitario_insertar',   'EXECUTE', 'Espacios del partido'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.espacio_publicitario_modificar',  'EXECUTE', 'Espacios del partido'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.espacio_publicitario_eliminar',   'EXECUTE', 'Espacios del partido'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.asignar_espacios_partido',        'EXECUTE', 'Propone las cuatro piezas del partido'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.facturar_espacios_partido',       'EXECUTE', 'Factura lo exhibido'),
        ('rol_gestor_publicidad', 'OBJECT', 'publicidad.consultar_anunciante',            'EXECUTE', 'Anunciantes con el contacto descifrado');

    -- Administrador: todos los SP de los cinco módulos salvo los auxiliares (incluye las importaciones).
    INSERT INTO @matriz (rol, clase, objeto, permiso, motivo)
    SELECT 'rol_administrador', 'OBJECT', s.name + '.' + p.name, 'EXECUTE', 'Administración de los datos del sistema'
    FROM sys.procedures p
    JOIN sys.schemas s ON s.schema_id = p.schema_id
    WHERE s.name IN ('torneo', 'plantel', 'evento', 'arbitraje', 'publicidad')
      AND p.name NOT LIKE '%[_]validar'
      AND p.name <> 'convertir_moneda';
    INSERT INTO @matriz (rol, clase, objeto, permiso, motivo) VALUES
        ('rol_administrador', 'TYPE', 'plantel.tt_formacion_jugador', 'EXECUTE', 'Parámetro de tipo tabla de cargar_formacion'),
        ('rol_administrador', 'DATABASE', '', 'EXECUTE ANY EXTERNAL ENDPOINT',
         'sp_invoke_external_rest_endpoint (APIs de la Entrega 6); el permiso de servidor ADMINISTER BULK OPERATIONS lo recibe su inicio de sesión');

    -- Todo objeto del cuadro tiene que existir: así un error de tipeo no queda como permiso inexistente.
    IF EXISTS (SELECT 1 FROM @matriz
               WHERE (clase = 'OBJECT' AND OBJECT_ID(objeto, 'P') IS NULL)
                  OR (clase = 'TYPE' AND TYPE_ID(objeto) IS NULL))
    BEGIN
        DECLARE @faltantes VARCHAR(2000) = (SELECT STRING_AGG(CAST(objeto AS VARCHAR(MAX)), ', ') FROM @matriz
                                            WHERE (clase = 'OBJECT' AND OBJECT_ID(objeto, 'P') IS NULL)
                                               OR (clase = 'TYPE' AND TYPE_ID(objeto) IS NULL));
        SET @faltantes = 'El cuadro de permisos nombra objetos que no existen (ejecutar antes las Entregas 5, 6 y 7): ' + @faltantes;
        THROW 50001, @faltantes, 1;
    END;

    BEGIN TRANSACTION;
    DELETE FROM seguridad.permiso;
    DELETE FROM seguridad.rol WHERE rol NOT IN (SELECT rol FROM @roles);
    UPDATE r SET descripcion = n.descripcion FROM seguridad.rol r JOIN @roles n ON n.rol = r.rol;
    INSERT INTO seguridad.rol (rol, descripcion)
    SELECT rol, descripcion FROM @roles n WHERE NOT EXISTS (SELECT 1 FROM seguridad.rol r WHERE r.rol = n.rol);
    INSERT INTO seguridad.permiso (rol, clase, objeto, permiso, motivo)
    SELECT rol, clase, objeto, permiso, MIN(motivo) FROM @matriz GROUP BY rol, clase, objeto, permiso;
    COMMIT TRANSACTION;
END;
GO

-- ============================================================
-- 3. CREACIÓN DE LOS ROLES Y APLICACIÓN DEL CUADRO
-- ============================================================

/* Crea los roles que falten y deja a cada uno exactamente con el cuadro: primero revoca todo lo
 que tenga otorgado o denegado (así es reejecutable y no quedan permisos viejos), después
 otorga lo del cuadro y por último deniega el acceso directo a las tablas de cada esquema. */

CREATE OR ALTER PROCEDURE seguridad.crear_roles
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX), @i INT = 1, @n INT;

    -- 0) Roles de una versión anterior del cuadro (rol_... que ya no figuran en seguridad.rol, por
    --    ejemplo rol_importador): se les quitan los miembros y se borran.
    SELECT @sql = STRING_AGG(CAST(N'ALTER ROLE ' + QUOTENAME(r.name) + N' DROP MEMBER ' + QUOTENAME(m.name) + N';' AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT, N' ')
    FROM sys.database_principals r
    JOIN sys.database_role_members rm ON rm.role_principal_id = r.principal_id
    JOIN sys.database_principals m ON m.principal_id = rm.member_principal_id
    WHERE r.type = 'R' AND r.is_fixed_role = 0 AND r.name LIKE 'rol[_]%'
      AND r.name COLLATE DATABASE_DEFAULT NOT IN (SELECT rol FROM seguridad.rol);
    IF @sql IS NOT NULL EXEC sp_executesql @sql;
    SELECT @sql = STRING_AGG(CAST(N'DROP ROLE ' + QUOTENAME(r.name) + N';' AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT, N' ')
    FROM sys.database_principals r
    WHERE r.type = 'R' AND r.is_fixed_role = 0 AND r.name LIKE 'rol[_]%'
      AND r.name COLLATE DATABASE_DEFAULT NOT IN (SELECT rol FROM seguridad.rol);
    IF @sql IS NOT NULL EXEC sp_executesql @sql;

    -- 1) Roles que falten.
    SELECT @sql = STRING_AGG(CAST(N'CREATE ROLE ' + QUOTENAME(r.rol) + N' AUTHORIZATION dbo;' AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT, N' ')
    FROM seguridad.rol r
    WHERE DATABASE_PRINCIPAL_ID(r.rol) IS NULL;
    IF @sql IS NOT NULL EXEC sp_executesql @sql;

    -- 2) Revocar todo lo que tengan (GRANT o DENY) sobre la base, esquemas, objetos o tipos.
    SELECT @sql = STRING_AGG(CAST(
               N'REVOKE ' + dp.permission_name
             + CASE dp.class
                   WHEN 0 THEN N''
                   WHEN 1 THEN N' ON OBJECT::' + QUOTENAME(OBJECT_SCHEMA_NAME(dp.major_id)) + N'.' + QUOTENAME(OBJECT_NAME(dp.major_id))
                   WHEN 3 THEN N' ON SCHEMA::' + QUOTENAME(SCHEMA_NAME(dp.major_id))
                   WHEN 6 THEN N' ON TYPE::' + QUOTENAME(SCHEMA_NAME(t.schema_id)) + N'.' + QUOTENAME(t.name)
               END
             + N' TO ' + QUOTENAME(pr.name) + N' CASCADE;' AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT, N' ')
    FROM sys.database_permissions dp
    JOIN sys.database_principals pr ON pr.principal_id = dp.grantee_principal_id
    LEFT JOIN sys.types t ON dp.class = 6 AND t.user_type_id = dp.major_id
    WHERE pr.name IN (SELECT rol FROM seguridad.rol) AND dp.class IN (0, 1, 3, 6);
    IF @sql IS NOT NULL EXEC sp_executesql @sql;

    -- 3) Otorgar el cuadro.
    SELECT @sql = STRING_AGG(CAST(
               N'GRANT ' + p.permiso
             + CASE p.clase
                   WHEN 'DATABASE' THEN N''
                   WHEN 'OBJECT' THEN N' ON OBJECT::' + QUOTENAME(OBJECT_SCHEMA_NAME(OBJECT_ID(p.objeto))) + N'.' + QUOTENAME(OBJECT_NAME(OBJECT_ID(p.objeto)))
                   WHEN 'TYPE' THEN N' ON TYPE::' + QUOTENAME(PARSENAME(p.objeto, 2)) + N'.' + QUOTENAME(PARSENAME(p.objeto, 1))
               END
             + N' TO ' + QUOTENAME(p.rol) + N';' AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT, N' ')
    FROM seguridad.permiso p
    WHERE p.permiso IN ('EXECUTE', 'EXECUTE ANY EXTERNAL ENDPOINT');   -- sólo los permisos previstos
    IF @sql IS NOT NULL EXEC sp_executesql @sql;

    -- 4) Denegar el acceso directo a las tablas de todos los esquemas de la aplicación.
    SELECT @sql = STRING_AGG(CAST(N'DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::' + QUOTENAME(s.name)
                                  + N' TO ' + QUOTENAME(r.rol) + N';' AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT, N' ')
    FROM seguridad.rol r
    CROSS JOIN sys.schemas s
    WHERE s.name IN ('torneo', 'plantel', 'evento', 'arbitraje', 'publicidad', 'importacion', 'seguridad');
    IF @sql IS NOT NULL EXEC sp_executesql @sql;

    SELECT r.rol, COUNT(p.objeto) AS permisos_otorgados, r.descripcion
    FROM seguridad.rol r LEFT JOIN seguridad.permiso p ON p.rol = r.rol
    GROUP BY r.rol, r.descripcion
    ORDER BY r.rol;
END;
GO

-- ============================================================
-- 4. USUARIOS
-- ============================================================

/* Crea (o actualiza) el inicio de sesión y el usuario de la base, y lo deja como miembro de un
 único rol del sistema. El inicio de sesión respeta las directivas de contraseña del servidor
 (CHECK_POLICY y CHECK_EXPIRATION) y, por defecto, obliga a cambiarla en el primer ingreso.
 Sólo el administrador recibe además ADMINISTER BULK OPERATIONS (permiso de servidor), para importar.
 Lo ejecuta el DBA. */

CREATE OR ALTER PROCEDURE seguridad.crear_usuario
    @login        SYSNAME,
    @contrasenia  NVARCHAR(128),
    @rol          SYSNAME,
    @debe_cambiar BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @sql NVARCHAR(MAX),
            @otro SYSNAME, @i INT = 1, @n INT;

    IF NULLIF(LTRIM(RTRIM(@login)), '') IS NULL OR @login LIKE '%[^A-Za-z0-9_]%'
        SET @errores += '- El inicio de sesión es obligatorio y sólo admite letras, números y guion bajo.' + @nl;
    IF NULLIF(@contrasenia, N'') IS NULL
        SET @errores += '- La contraseña es obligatoria.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM seguridad.rol WHERE rol = @rol)
        SET @errores += '- El rol ''' + ISNULL(@rol, '(nulo)') + ''' no es un rol del sistema (seguridad.rol).' + @nl;
    IF @errores <> ''
    BEGIN
        SET @errores = 'No se puede crear el usuario:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    -- Inicio de sesión (servidor).
    IF SUSER_ID(@login) IS NULL
    BEGIN
        SET @sql = N'CREATE LOGIN ' + QUOTENAME(@login) + N' WITH PASSWORD = N''' + REPLACE(@contrasenia, N'''', N'''''') + N''''
                 + IIF(@debe_cambiar = 1, N' MUST_CHANGE', N'')
                 + N', CHECK_POLICY = ON, CHECK_EXPIRATION = ON, DEFAULT_DATABASE = ' + QUOTENAME(DB_NAME()) + N';';
        EXEC sp_executesql @sql;
    END;

    -- Usuario de la base.
    IF DATABASE_PRINCIPAL_ID(@login) IS NULL
    BEGIN
        SET @sql = N'CREATE USER ' + QUOTENAME(@login) + N' FOR LOGIN ' + QUOTENAME(@login) + N';';
        EXEC sp_executesql @sql;
    END;

    -- Un único rol del sistema: se lo quita de los demás.
    DECLARE @roles TABLE (orden INT IDENTITY(1, 1) PRIMARY KEY, rol SYSNAME);
    INSERT INTO @roles (rol) SELECT rol FROM seguridad.rol WHERE rol <> @rol AND IS_ROLEMEMBER(rol, @login) = 1;
    SELECT @n = COUNT(*) FROM @roles;
    WHILE @i <= @n
    BEGIN
        SELECT @otro = rol FROM @roles WHERE orden = @i;
        SET @sql = N'ALTER ROLE ' + QUOTENAME(@otro) + N' DROP MEMBER ' + QUOTENAME(@login) + N';';
        EXEC sp_executesql @sql;
        SET @i += 1;
    END;
    IF IS_ROLEMEMBER(@rol, @login) = 0
    BEGIN
        SET @sql = N'ALTER ROLE ' + QUOTENAME(@rol) + N' ADD MEMBER ' + QUOTENAME(@login) + N';';
        EXEC sp_executesql @sql;
    END;

    -- Permiso de servidor para cargas masivas: sólo el administrador, que importa (se otorga en master).
    SET @sql = N'USE master; ' + IIF(@rol = 'rol_administrador', N'GRANT', N'REVOKE')
             + N' ADMINISTER BULK OPERATIONS TO ' + QUOTENAME(@login) + N';';
    EXEC sp_executesql @sql;

    SELECT @login AS usuario, @rol AS rol, IIF(@debe_cambiar = 1, 'debe cambiar la contraseña', '-') AS observacion;
END;
GO

CREATE OR ALTER PROCEDURE seguridad.quitar_usuario
    @login SYSNAME
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX);
    IF @login IS NULL OR @login LIKE '%[^A-Za-z0-9_]%'
        THROW 50001, 'No se puede quitar el usuario: el nombre no es válido.', 1;
    IF DATABASE_PRINCIPAL_ID(@login) IS NOT NULL
    BEGIN
        SET @sql = N'DROP USER ' + QUOTENAME(@login) + N';';
        EXEC sp_executesql @sql;
    END;
    IF SUSER_ID(@login) IS NOT NULL
    BEGIN
        SET @sql = N'DROP LOGIN ' + QUOTENAME(@login) + N';';
        EXEC sp_executesql @sql;
    END;
END;
GO

-- ============================================================
-- 5. CONTROL: PERMISOS EFECTIVOS CONTRA EL CUADRO
-- ============================================================

/* Se hace pasar por el usuario (EXECUTE AS LOGIN) y le pregunta al motor qué puede hacer
 (HAS_PERMS_BY_NAME) sobre cada SP, tipo y tabla de la aplicación; después lo compara con el
 cuadro de su rol. Devuelve las diferencias (ninguna = el usuario tiene exactamente lo que le
 corresponde) y los conteos en parámetros OUTPUT. */

CREATE OR ALTER PROCEDURE seguridad.comprobar_permisos
    @login           SYSNAME,
    @sp_permitidos   INT = NULL OUTPUT,
    @tablas_legibles INT = NULL OUTPUT,
    @diferencias     INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @efectivo TABLE (clase VARCHAR(10), objeto NVARCHAR(260), permiso VARCHAR(60), puede BIT);

    IF DATABASE_PRINCIPAL_ID(@login) IS NULL
        THROW 50001, 'El usuario no existe en la base.', 1;

    EXECUTE AS LOGIN = @login;
    INSERT INTO @efectivo
    SELECT 'OBJECT', s.name + '.' + p.name, 'EXECUTE', HAS_PERMS_BY_NAME(QUOTENAME(s.name) + '.' + QUOTENAME(p.name), 'OBJECT', 'EXECUTE')
    FROM sys.procedures p JOIN sys.schemas s ON s.schema_id = p.schema_id
    WHERE s.name IN ('torneo', 'plantel', 'evento', 'arbitraje', 'publicidad', 'importacion', 'seguridad')
    UNION ALL
    SELECT 'TYPE', s.name + '.' + t.name, 'EXECUTE', HAS_PERMS_BY_NAME(QUOTENAME(s.name) + '.' + QUOTENAME(t.name), 'TYPE', 'EXECUTE')
    FROM sys.types t JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE t.is_user_defined = 1
    UNION ALL
    SELECT 'DATABASE', '', 'EXECUTE ANY EXTERNAL ENDPOINT', HAS_PERMS_BY_NAME(NULL, 'DATABASE', 'EXECUTE ANY EXTERNAL ENDPOINT')
    UNION ALL
    SELECT 'TABLE', s.name + '.' + t.name, x.permiso, HAS_PERMS_BY_NAME(QUOTENAME(s.name) + '.' + QUOTENAME(t.name), 'OBJECT', x.permiso)
    FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
    CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')) x (permiso)
    WHERE s.name IN ('torneo', 'plantel', 'evento', 'arbitraje', 'publicidad', 'importacion', 'seguridad');
    REVERT;

    -- Esperado: el cuadro de los roles del usuario. Las tablas, nunca.
    WITH esperado AS (
        SELECT DISTINCT p.clase, p.objeto, p.permiso
        FROM seguridad.permiso p
        WHERE IS_ROLEMEMBER(p.rol, @login) = 1
    )
    SELECT e.clase, e.objeto, e.permiso,
           IIF(e.puede = 1, 'lo tiene', 'no lo tiene') AS efectivo,
           IIF(x.objeto IS NULL, 'no le corresponde', 'le corresponde') AS segun_cuadro
    INTO #diferencias
    FROM @efectivo e
    LEFT JOIN esperado x ON x.clase = e.clase AND x.objeto = e.objeto COLLATE DATABASE_DEFAULT AND x.permiso = e.permiso
    WHERE (e.puede = 1 AND x.objeto IS NULL) OR (e.puede = 0 AND x.objeto IS NOT NULL);

    SELECT @sp_permitidos = COUNT(*) FROM @efectivo WHERE clase = 'OBJECT' AND puede = 1;
    SELECT @tablas_legibles = COUNT(DISTINCT objeto) FROM @efectivo WHERE clase = 'TABLE' AND puede = 1;
    SELECT @diferencias = COUNT(*) FROM #diferencias;

    SELECT clase, objeto, permiso, efectivo, segun_cuadro FROM #diferencias ORDER BY clase, objeto;
    DROP TABLE #diferencias;
END;
GO

-- ============================================================
-- 6. VISTAS PARA DOCUMENTAR EL CUADRO
-- ============================================================

-- El cuadro esperado: una fila por SP o permiso, una columna por rol.
CREATE OR ALTER VIEW seguridad.vw_cuadro_permisos
AS
SELECT p.clase, p.objeto, p.permiso,
       MAX(IIF(p.rol = 'rol_administrador',     'X', '')) AS administrador,
       MAX(IIF(p.rol = 'rol_comite_arbitral',   'X', '')) AS comite_arbitral,
       MAX(IIF(p.rol = 'rol_planillero',        'X', '')) AS planillero,
       MAX(IIF(p.rol = 'rol_var',               'X', '')) AS var,
       MAX(IIF(p.rol = 'rol_gestor_publicidad', 'X', '')) AS gestor_publicidad,
       MAX(IIF(p.rol = 'rol_consulta',          'X', '')) AS consulta
FROM seguridad.permiso p
GROUP BY p.clase, p.objeto, p.permiso;
GO

-- Lo que el motor tiene otorgado o denegado a cada rol (sys.database_permissions).
CREATE OR ALTER VIEW seguridad.vw_permisos_otorgados
AS
SELECT pr.name AS rol, dp.state_desc AS estado, dp.permission_name AS permiso, dp.class_desc AS clase,
       CASE dp.class
           WHEN 0 THEN DB_NAME()
           WHEN 1 THEN OBJECT_SCHEMA_NAME(dp.major_id) + '.' + OBJECT_NAME(dp.major_id)
           WHEN 3 THEN SCHEMA_NAME(dp.major_id)
           WHEN 6 THEN SCHEMA_NAME(t.schema_id) + '.' + t.name
       END AS objeto
FROM sys.database_permissions dp
JOIN sys.database_principals pr ON pr.principal_id = dp.grantee_principal_id
LEFT JOIN sys.types t ON dp.class = 6 AND t.user_type_id = dp.major_id
WHERE pr.type = 'R' AND pr.name IN (SELECT rol FROM seguridad.rol);
GO

-- ============================================================
-- 7. EJECUCIÓN
-- ============================================================

EXEC seguridad.cargar_matriz;
EXEC seguridad.crear_roles;
GO
