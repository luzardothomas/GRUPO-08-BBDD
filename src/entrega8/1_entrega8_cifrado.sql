-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 8: Seguridad y respaldo - Cifrado de datos sensibles
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Cifra los datos sensibles de la base mundial_2026 como script de MODIFICACIÓN sobre los
--   componentes ya creados (Entregas 5 a 7), sin tocar los scripts que los crean:
--     1. Claves (objetos nuevos): master key, certificado y clave simétrica AES_256.
--     2. Utilidades (esquema seguridad, ejecutadas como su dueño):
--          seguridad.cifrar_texto   SP que cifra un texto con la clave simétrica
--          seguridad.fn_descifrar   función que lo descifra
--          seguridad.cifrar_columna SP que pasa una columna existente a VARBINARY cifrado
--     3. ALTER TABLE: las seis columnas pasan a VARBINARY con los datos ya cargados cifrados.
--     4. ALTER PROCEDURE: los diez SP que escriben o leen esas columnas.
--     5. SP de consulta nuevos, para que cada rol autorizado vea el dato descifrado.
--
-- QUÉ SE CIFRA Y POR QUÉ (Ley 25.326, Unidad 6): lo sensible o no público.
--     plantel.convocatoria.motivo_alta, motivo_baja   bajas por lesión: dato de salud (sensible)
--     arbitraje.informe_arbitral.contenido, sancion   informes y sanciones del árbitro (disciplinario)
--     arbitraje.arbitro.fecha_nacimiento              dato personal que no figura en fuentes públicas
--     publicidad.anunciante.contacto                  dato de contacto de una persona
--   No se cifra lo que publica FIFA (nombres de jugadores, DT y árbitros, fecha de nacimiento de los
--   jugadores): lo usan los reportes y es la clave con la que la Entrega 6 busca a cada jugador.
--
-- CRITERIOS:
--   * Nadie descifra con permisos propios sobre la clave: ningún rol (ni rol_administrador) tiene
--     permiso sobre la clave ni el certificado. Sólo seguridad.cifrar_texto y seguridad.fn_descifrar
--     la usan, con WITH EXECUTE AS OWNER, y los SP los llaman por encadenamiento de propiedad. Quién
--     ve el dato en claro lo decide el permiso EXECUTE sobre los SP de consulta (cuadro de
--     2_entrega8_roles.sql). La administración de las claves (rotarlas, respaldarlas) es del DBA.
--   * No se usa autenticador (EncryptByKey con la clave primaria de la fila): copiar un valor
--     cifrado de una fila a otra exigiría escribir en las tablas, y ningún rol puede (DENY).
--   * ENCRYPTBYKEY cifra hasta 8000 bytes: el contenido de un informe no puede superarlos.
--   * Advertencia del enunciado: después del cifrado, las pruebas de entregas anteriores que leen
--     estas columnas directamente de las tablas dejan de comparar texto (ahora es VARBINARY).
--
-- EJECUCIÓN: una vez, como DBA (sysadmin), después de las Entregas 5, 6 y 7 y antes de
--   2_entrega8_roles.sql. Es reejecutable: las columnas ya cifradas no se vuelven a tocar.
--   La contraseña de la master key es de prueba: en producción la carga el DBA y se guarda junto
--   con el respaldo del certificado, separados de los datos (ver la política de backup).
-- ============================================================

USE mundial_2026;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- 1. CLAVES
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Mundial2026_ClaveMaestra!';
GO

IF NOT EXISTS (SELECT 1 FROM sys.certificates WHERE name = 'cert_datos_sensibles')
    CREATE CERTIFICATE cert_datos_sensibles WITH SUBJECT = 'Protege la clave de los datos sensibles de mundial_2026';
GO

IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name = 'clave_datos_sensibles')
    CREATE SYMMETRIC KEY clave_datos_sensibles WITH ALGORITHM = AES_256
        ENCRYPTION BY CERTIFICATE cert_datos_sensibles;
GO

-- ============================================================
-- 2. UTILIDADES DE CIFRADO
-- ============================================================

IF SCHEMA_ID('seguridad') IS NULL EXEC('CREATE SCHEMA seguridad');
GO

/* Cifra un texto con la clave simétrica. WITH EXECUTE AS OWNER: abre la clave como su dueño, así
 quien llama (por ejemplo, un SP de alta ejecutado por un rol operativo) no necesita permiso sobre
 la clave. NULL se guarda como NULL. */

CREATE OR ALTER PROCEDURE seguridad.cifrar_texto
    @texto   VARCHAR(MAX),
    @cifrado VARBINARY(MAX) OUTPUT
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;
    IF @texto IS NULL
    BEGIN
        SET @cifrado = NULL;
        RETURN;
    END;
    IF DATALENGTH(@texto) > 8000
        THROW 50001, 'El texto a cifrar supera los 8000 bytes que admite ENCRYPTBYKEY.', 1;

    OPEN SYMMETRIC KEY clave_datos_sensibles DECRYPTION BY CERTIFICATE cert_datos_sensibles;
    SET @cifrado = ENCRYPTBYKEY(KEY_GUID('clave_datos_sensibles'), @texto);
    CLOSE SYMMETRIC KEY clave_datos_sensibles;
END;
GO

/* Descifra un valor cifrado con seguridad.cifrar_texto. DECRYPTBYKEYAUTOCERT abre la clave con el
 certificado (no hace falta OPEN, que no se admite en funciones); WITH EXECUTE AS OWNER evita que
 quien llama necesite permiso sobre la clave o el certificado. */

CREATE OR ALTER FUNCTION seguridad.fn_descifrar (@cifrado VARBINARY(MAX))
RETURNS VARCHAR(MAX)
WITH EXECUTE AS OWNER
AS
BEGIN
    RETURN CONVERT(VARCHAR(MAX), DECRYPTBYKEYAUTOCERT(CERT_ID('cert_datos_sensibles'), NULL, @cifrado));
END;
GO

/* Pasa una columna existente a VARBINARY cifrado, conservando su nombre y sus datos:
   1) agrega una columna VARBINARY y le guarda los valores actuales cifrados;
   2) quita las restricciones CHECK que nombran la columna (se recrean igual al final);
   3) borra la columna plana y renombra la cifrada con el nombre original;
   4) si la columna era NOT NULL, la nueva también.
 Si la columna ya es VARBINARY, no hace nada (reejecutable). Una fecha se cifra como texto aaaa-mm-dd.
 SQL dinámico: ALTER TABLE y UPDATE no aceptan el nombre de la tabla o la columna en una variable;
 se validan contra el catálogo y se escriben con QUOTENAME. */

CREATE OR ALTER PROCEDURE seguridad.cifrar_columna
    @tabla   NVARCHAR(260),
    @columna SYSNAME
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @objeto INT = OBJECT_ID(@tabla, 'U'), @tipo SYSNAME, @largo SMALLINT, @nulos BIT,
            @nombre NVARCHAR(400), @temporal SYSNAME = @columna + N'_cifrado', @sql NVARCHAR(MAX),
            @checks NVARCHAR(MAX), @recrear NVARCHAR(MAX), @filas INT, @mensaje VARCHAR(500);

    SELECT @tipo = t.name, @largo = c.max_length, @nulos = c.is_nullable
    FROM sys.columns c JOIN sys.types t ON t.user_type_id = c.user_type_id
    WHERE c.object_id = @objeto AND c.name = @columna;

    IF @tipo IS NULL
    BEGIN
        SET @mensaje = 'No existe la columna ' + CAST(@tabla AS VARCHAR(260)) + '.' + CAST(@columna AS VARCHAR(128)) + '.';
        THROW 50001, @mensaje, 1;
    END;
    IF @tipo = 'varbinary'
    BEGIN
        PRINT CONCAT(@tabla, '.', @columna, ': ya está cifrada.');
        RETURN;
    END;

    SET @nombre = QUOTENAME(OBJECT_SCHEMA_NAME(@objeto)) + N'.' + QUOTENAME(OBJECT_NAME(@objeto));

    -- Restricciones CHECK que nombran la columna: se guardan para recrearlas.
    SELECT @checks = STRING_AGG(CAST(N'ALTER TABLE ' + @nombre + N' DROP CONSTRAINT ' + QUOTENAME(cc.name) + N';' AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT, N' '),
           @recrear = STRING_AGG(CAST(N'ALTER TABLE ' + @nombre + N' ADD CONSTRAINT ' + QUOTENAME(cc.name)
                                      + N' CHECK ' + cc.definition + N';' AS NVARCHAR(MAX)) COLLATE DATABASE_DEFAULT, N' ')
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id = @objeto AND cc.definition LIKE N'%' + QUOTENAME(@columna) + N'%';

    BEGIN TRANSACTION;

    SET @sql = N'ALTER TABLE ' + @nombre + N' ADD ' + QUOTENAME(@temporal)
             + N' VARBINARY(' + IIF(@largo = -1, N'MAX', N'400') + N') NULL;';
    EXEC sp_executesql @sql;

    SET @sql = N'OPEN SYMMETRIC KEY clave_datos_sensibles DECRYPTION BY CERTIFICATE cert_datos_sensibles; '
             + N'UPDATE ' + @nombre + N' SET ' + QUOTENAME(@temporal) + N' = ENCRYPTBYKEY(KEY_GUID(''clave_datos_sensibles''), '
             + N'CONVERT(VARCHAR(MAX), ' + QUOTENAME(@columna) + IIF(@tipo IN ('date', 'datetime2', 'datetimeoffset'), N', 23', N'') + N')); '
             + N'SET @filas = @@ROWCOUNT; '
             + N'CLOSE SYMMETRIC KEY clave_datos_sensibles;';
    EXEC sp_executesql @sql, N'@filas INT OUTPUT', @filas = @filas OUTPUT;

    IF @checks IS NOT NULL EXEC sp_executesql @checks;

    SET @sql = N'ALTER TABLE ' + @nombre + N' DROP COLUMN ' + QUOTENAME(@columna) + N';';
    EXEC sp_executesql @sql;

    SET @sql = CAST(OBJECT_SCHEMA_NAME(@objeto) AS NVARCHAR(128)) + N'.' + OBJECT_NAME(@objeto) + N'.' + @temporal;
    EXEC sp_rename @sql, @columna, 'COLUMN';

    IF @nulos = 0
    BEGIN
        SET @sql = N'ALTER TABLE ' + @nombre + N' ALTER COLUMN ' + QUOTENAME(@columna)
                 + N' VARBINARY(' + IIF(@largo = -1, N'MAX', N'400') + N') NOT NULL;';
        EXEC sp_executesql @sql;
    END;

    IF @recrear IS NOT NULL EXEC sp_executesql @recrear;

    COMMIT TRANSACTION;
    PRINT CONCAT(@tabla, '.', @columna, ': cifrada (', @tipo, ' -> varbinary), ', @filas, ' filas.');
END;
GO

-- ============================================================
-- 3. ALTER TABLE: COLUMNAS CIFRADAS
-- ============================================================

EXEC seguridad.cifrar_columna 'plantel.convocatoria', 'motivo_alta';
EXEC seguridad.cifrar_columna 'plantel.convocatoria', 'motivo_baja';
EXEC seguridad.cifrar_columna 'arbitraje.informe_arbitral', 'contenido';
EXEC seguridad.cifrar_columna 'arbitraje.informe_arbitral', 'sancion';
EXEC seguridad.cifrar_columna 'arbitraje.arbitro', 'fecha_nacimiento';
EXEC seguridad.cifrar_columna 'publicidad.anunciante', 'contacto';
GO

-- ============================================================
-- 4. ALTER PROCEDURE: SP QUE ESCRIBEN O LEEN LAS COLUMNAS CIFRADAS
-- ============================================================

/* Cada SP es el de su entrega, con los cambios marcados [Entrega 8: cifrado]:
   * los de alta y modificación cifran el valor con seguridad.cifrar_texto antes de guardarlo;
   * los que leen la columna la descifran con seguridad.fn_descifrar.
 Las validaciones no cambian: trabajan sobre los parámetros, que llegan en claro. */

-- plantel.convocatoria_insertar (Entrega 5): cifra el motivo de alta.
ALTER PROCEDURE plantel.convocatoria_insertar
    @seleccion_id    INT,
    @jugador_id      INT,
    @dorsal          INT,
    @fecha_alta      DATE,
    @motivo_alta     VARCHAR(150) = NULL,
    @convocatoria_id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC plantel.convocatoria_validar NULL, @seleccion_id, @jugador_id, @dorsal, @fecha_alta, NULL, NULL,
         @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.convocatoria_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    -- [Entrega 8: cifrado] el motivo se guarda cifrado.
    DECLARE @motivo_alta_cifrado VARBINARY(400);
    SET @motivo_alta = NULLIF(LTRIM(RTRIM(@motivo_alta)), '');
    EXEC seguridad.cifrar_texto @motivo_alta, @motivo_alta_cifrado OUTPUT;

    INSERT INTO plantel.convocatoria (seleccion_id, jugador_id, dorsal, fecha_alta, motivo_alta)
    VALUES (@seleccion_id, @jugador_id, @dorsal, @fecha_alta, @motivo_alta_cifrado);   -- [Entrega 8: cifrado]

    SET @convocatoria_id = SCOPE_IDENTITY();
END;
GO

-- plantel.convocatoria_modificar (Entrega 5): cifra los motivos de alta y de baja.
ALTER PROCEDURE plantel.convocatoria_modificar
    @convocatoria_id INT,
    @dorsal          INT,
    @fecha_alta      DATE,
    @motivo_alta     VARCHAR(150) = NULL,
    @fecha_baja      DATE = NULL,
    @motivo_baja     VARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @seleccion_id INT, @jugador_id INT;

    SELECT @seleccion_id = seleccion_id, @jugador_id = jugador_id
    FROM plantel.convocatoria WHERE convocatoria_id = @convocatoria_id;

    IF @seleccion_id IS NULL
        SET @errores = '- No existe la convocatoria con id '
                     + ISNULL(CAST(@convocatoria_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE
        EXEC plantel.convocatoria_validar @convocatoria_id, @seleccion_id, @jugador_id, @dorsal, @fecha_alta,
             @fecha_baja, @motivo_baja, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.convocatoria_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    -- [Entrega 8: cifrado] los motivos se guardan cifrados.
    DECLARE @motivo_alta_cifrado VARBINARY(400);
    SET @motivo_alta = NULLIF(LTRIM(RTRIM(@motivo_alta)), '');
    EXEC seguridad.cifrar_texto @motivo_alta, @motivo_alta_cifrado OUTPUT;
    DECLARE @motivo_baja_cifrado VARBINARY(400);
    EXEC seguridad.cifrar_texto @motivo_baja, @motivo_baja_cifrado OUTPUT;

    UPDATE plantel.convocatoria
    SET dorsal = @dorsal,
        fecha_alta = @fecha_alta,
        motivo_alta = @motivo_alta_cifrado,   -- [Entrega 8: cifrado]
        fecha_baja = @fecha_baja,
        motivo_baja = @motivo_baja_cifrado   -- [Entrega 8: cifrado]
    WHERE convocatoria_id = @convocatoria_id;
END;
GO

-- arbitraje.arbitro_insertar (Entrega 5): cifra la fecha de nacimiento.
ALTER PROCEDURE arbitraje.arbitro_insertar
    @nombre           VARCHAR(100),
    @apellido         VARCHAR(100),
    @pais_id          INT,
    @categoria        VARCHAR(20),
    @fecha_nacimiento DATE = NULL,
    @arbitro_id       INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC arbitraje.arbitro_validar NULL, @nombre, @apellido, @fecha_nacimiento, @pais_id, @categoria,
         @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.arbitro_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    -- [Entrega 8: cifrado] la fecha de nacimiento se guarda cifrada (como texto aaaa-mm-dd).
    DECLARE @fecha_texto VARCHAR(10) = CONVERT(VARCHAR(10), @fecha_nacimiento, 23);
    DECLARE @fecha_nacimiento_cifrada VARBINARY(400);
    EXEC seguridad.cifrar_texto @fecha_texto, @fecha_nacimiento_cifrada OUTPUT;

    INSERT INTO arbitraje.arbitro (nombre, apellido, fecha_nacimiento, pais_id, categoria)
    VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@apellido)), @fecha_nacimiento_cifrada, @pais_id, @categoria);   -- [Entrega 8: cifrado]

    SET @arbitro_id = SCOPE_IDENTITY();
END;
GO

-- arbitraje.arbitro_modificar (Entrega 5): cifra la fecha de nacimiento.
ALTER PROCEDURE arbitraje.arbitro_modificar
    @arbitro_id       INT,
    @nombre           VARCHAR(100),
    @apellido         VARCHAR(100),
    @pais_id          INT,
    @categoria        VARCHAR(20),
    @fecha_nacimiento DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @arbitro_id IS NULL SET @errores = '- El id del árbitro es obligatorio.' + @nl;
    EXEC arbitraje.arbitro_validar @arbitro_id, @nombre, @apellido, @fecha_nacimiento, @pais_id, @categoria,
         @errores OUTPUT;

    -- Cambiar el país no puede dejar una designación ya hecha en conflicto de nacionalidad.
    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral d
               JOIN torneo.partido p   ON p.partido_id = d.partido_id
               JOIN torneo.seleccion s ON s.seleccion_id IN (p.seleccion_local_id, p.seleccion_visitante_id)
               WHERE d.arbitro_id = @arbitro_id AND s.pais_id = @pais_id)
        SET @errores += '- El nuevo país coincide con el de una selección de un partido en el que ya está designado.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.arbitro_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    -- [Entrega 8: cifrado] la fecha de nacimiento se guarda cifrada (como texto aaaa-mm-dd).
    DECLARE @fecha_texto VARCHAR(10) = CONVERT(VARCHAR(10), @fecha_nacimiento, 23);
    DECLARE @fecha_nacimiento_cifrada VARBINARY(400);
    EXEC seguridad.cifrar_texto @fecha_texto, @fecha_nacimiento_cifrada OUTPUT;

    UPDATE arbitraje.arbitro
    SET nombre = LTRIM(RTRIM(@nombre)),
        apellido = LTRIM(RTRIM(@apellido)),
        fecha_nacimiento = @fecha_nacimiento_cifrada,   -- [Entrega 8: cifrado]
        pais_id = @pais_id,
        categoria = @categoria
    WHERE arbitro_id = @arbitro_id;
END;
GO

-- arbitraje.informe_arbitral_insertar (Entrega 5): cifra el contenido y la sanción.
ALTER PROCEDURE arbitraje.informe_arbitral_insertar
    @designacion_id INT,
    @fecha          DATETIMEOFFSET,
    @contenido      VARCHAR(MAX),
    @sancion        VARCHAR(150) = NULL,
    @informe_id     INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC arbitraje.informe_arbitral_validar NULL, @designacion_id, @fecha, @contenido, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.informe_arbitral_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    -- [Entrega 8: cifrado] el contenido y la sanción se guardan cifrados.
    DECLARE @contenido_cifrado VARBINARY(MAX);
    EXEC seguridad.cifrar_texto @contenido, @contenido_cifrado OUTPUT;
    DECLARE @sancion_cifrada VARBINARY(400);
    SET @sancion = NULLIF(LTRIM(RTRIM(@sancion)), '');
    EXEC seguridad.cifrar_texto @sancion, @sancion_cifrada OUTPUT;

    INSERT INTO arbitraje.informe_arbitral (designacion_id, fecha, contenido, sancion)
    VALUES (@designacion_id, @fecha, @contenido_cifrado, @sancion_cifrada);   -- [Entrega 8: cifrado]

    SET @informe_id = SCOPE_IDENTITY();
END;
GO

-- arbitraje.informe_arbitral_modificar (Entrega 5): cifra el contenido y la sanción.
ALTER PROCEDURE arbitraje.informe_arbitral_modificar
    @informe_id INT,
    @fecha      DATETIMEOFFSET,
    @contenido  VARCHAR(MAX),
    @sancion    VARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @designacion_id INT;

    SELECT @designacion_id = designacion_id FROM arbitraje.informe_arbitral WHERE informe_id = @informe_id;

    IF @designacion_id IS NULL
        SET @errores = '- No existe el informe con id ' + ISNULL(CAST(@informe_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE
        EXEC arbitraje.informe_arbitral_validar @informe_id, @designacion_id, @fecha, @contenido, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.informe_arbitral_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    -- [Entrega 8: cifrado] el contenido y la sanción se guardan cifrados.
    DECLARE @contenido_cifrado VARBINARY(MAX);
    EXEC seguridad.cifrar_texto @contenido, @contenido_cifrado OUTPUT;
    DECLARE @sancion_cifrada VARBINARY(400);
    SET @sancion = NULLIF(LTRIM(RTRIM(@sancion)), '');
    EXEC seguridad.cifrar_texto @sancion, @sancion_cifrada OUTPUT;

    UPDATE arbitraje.informe_arbitral
    SET fecha = @fecha, contenido = @contenido_cifrado, sancion = @sancion_cifrada   -- [Entrega 8: cifrado]
    WHERE informe_id = @informe_id;
END;
GO

-- publicidad.anunciante_insertar (Entrega 5): cifra el contacto.
ALTER PROCEDURE publicidad.anunciante_insertar
    @nombre        VARCHAR(100),
    @razon_social  VARCHAR(150) = NULL,
    @contacto      VARCHAR(100) = NULL,
    @anunciante_id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre del anunciante es obligatorio.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.anunciante WHERE nombre = @nombre)
    SET @errores += '- Ya existe un anunciante con ese nombre.' + @nl;
    
    IF @contacto IS NOT NULL AND NULLIF(LTRIM(RTRIM(@contacto)), '') IS NOT NULL
    BEGIN
        SET @contacto = LTRIM(RTRIM(@contacto));
        IF LEN(@contacto) > 100
            OR LEN(@contacto) - LEN(REPLACE(@contacto, '@', '')) <> 1
            OR @contacto NOT LIKE '_%@_%._%'
            OR @contacto LIKE '% %'
            OR @contacto LIKE '%[^a-zA-Z0-9@._%+-]%'
            OR @contacto LIKE '%..%'
        SET @errores += '- El contacto debe ser un correo electrónico válido.' + @nl;
    END;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.anunciante_insertar - alta rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    -- [Entrega 8: cifrado] el contacto se guarda cifrado.
    DECLARE @contacto_cifrado VARBINARY(400);
    SET @contacto = NULLIF(LTRIM(RTRIM(@contacto)), '');
    EXEC seguridad.cifrar_texto @contacto, @contacto_cifrado OUTPUT;

    INSERT INTO publicidad.anunciante (nombre, razon_social, contacto)
    VALUES (LTRIM(RTRIM(@nombre)), NULLIF(LTRIM(RTRIM(@razon_social)), ''), @contacto_cifrado);   -- [Entrega 8: cifrado]

    SET @anunciante_id = SCOPE_IDENTITY();
END;
GO

-- publicidad.anunciante_modificar (Entrega 5): cifra el contacto.
ALTER PROCEDURE publicidad.anunciante_modificar
    @anunciante_id INT,
    @nombre        VARCHAR(100),
    @razon_social  VARCHAR(150) = NULL,
    @contacto      VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM publicidad.anunciante WHERE anunciante_id = @anunciante_id)
        SET @errores += '- No existe el anunciante con id '
                      + ISNULL(CAST(@anunciante_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;

    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre del anunciante es obligatorio.' + @nl;

    IF EXISTS (
        SELECT 1
        FROM publicidad.anunciante
        WHERE nombre = LTRIM(RTRIM(@nombre))
          AND anunciante_id <> @anunciante_id
    )
        SET @errores += '- Ya existe otro anunciante con ese nombre.' + @nl;

    IF @contacto IS NOT NULL
       AND NULLIF(LTRIM(RTRIM(@contacto)), '') IS NOT NULL
    BEGIN
        SET @contacto = LTRIM(RTRIM(@contacto));

        IF LEN(@contacto) - LEN(REPLACE(@contacto, '@', '')) <> 1
            OR @contacto NOT LIKE '_%@_%._%'
            OR @contacto LIKE '% %'
            OR @contacto LIKE '%[^a-zA-Z0-9@._%+-]%'
            OR @contacto LIKE '%..%'
            SET @errores += '- El contacto debe ser un correo electrónico válido.' + @nl;
    END;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.anunciante_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    -- [Entrega 8: cifrado] el contacto se guarda cifrado.
    DECLARE @contacto_cifrado VARBINARY(400);
    SET @contacto = NULLIF(LTRIM(RTRIM(@contacto)), '');
    EXEC seguridad.cifrar_texto @contacto, @contacto_cifrado OUTPUT;

    UPDATE publicidad.anunciante
    SET nombre = LTRIM(RTRIM(@nombre)),
        razon_social = NULLIF(LTRIM(RTRIM(@razon_social)), ''),
        contacto = @contacto_cifrado   -- [Entrega 8: cifrado]
    WHERE anunciante_id = @anunciante_id;
END;
GO

-- plantel.reemplazar_convocado (Entrega 5): lee el motivo de alta cifrado para volver a guardarlo al dar la baja.
ALTER PROCEDURE plantel.reemplazar_convocado
    @seleccion_id     INT,
    @jugador_sale_id  INT,
    @jugador_entra_id INT,
    @fecha            DATE,
    @motivo           VARCHAR(150),
    @dorsal           INT = NULL,
    @convocatoria_id  INT = NULL OUTPUT                 -- convocatoria creada para el entrante
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @conv_sale_id INT, @dorsal_sale INT, @fecha_alta_sale DATE, @motivo_alta_sale VARCHAR(150),
            @apellido_sale VARCHAR(100), @motivo_alta VARCHAR(150),
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @conv_sale_id = c.convocatoria_id, @dorsal_sale = c.dorsal, @fecha_alta_sale = c.fecha_alta,
           @motivo_alta_sale = seguridad.fn_descifrar(c.motivo_alta), @apellido_sale = j.apellido   -- [Entrega 8: cifrado]
    FROM plantel.convocatoria c
    JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
    WHERE c.seleccion_id = @seleccion_id AND c.jugador_id = @jugador_sale_id AND c.fecha_baja IS NULL;

    SET @dorsal = ISNULL(@dorsal, @dorsal_sale);

    IF NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id '
                      + ISNULL(CAST(@seleccion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE IF @conv_sale_id IS NULL
        SET @errores += '- El jugador saliente no integra la convocatoria vigente de la selección.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM plantel.jugador WHERE jugador_id = @jugador_entra_id)
        SET @errores += '- No existe el jugador entrante con id '
                      + ISNULL(CAST(@jugador_entra_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @jugador_sale_id = @jugador_entra_id
        SET @errores += '- El jugador entrante debe ser distinto del saliente.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.convocatoria WHERE jugador_id = @jugador_entra_id AND fecha_baja IS NULL)
        SET @errores += '- El jugador entrante ya integra una convocatoria vigente.' + @nl;
    IF @fecha IS NULL
        SET @errores += '- La fecha del reemplazo es obligatoria.' + @nl;
    IF @fecha < @fecha_alta_sale
        SET @errores += '- La fecha del reemplazo no puede ser anterior al alta del jugador saliente.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL
        SET @errores += '- El motivo del reemplazo es obligatorio.' + @nl;
    IF @dorsal NOT BETWEEN 1 AND 99
        SET @errores += '- El dorsal debe estar entre 1 y 99.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.convocatoria
               WHERE seleccion_id = @seleccion_id AND dorsal = @dorsal AND fecha_baja IS NULL
                 AND jugador_id <> @jugador_sale_id)
        SET @errores += '- El dorsal ' + CAST(@dorsal AS VARCHAR(3)) + ' está en uso por otro convocado vigente.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.reemplazar_convocado - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    SET @motivo_alta = LEFT('Reemplaza a ' + @apellido_sale + ': ' + LTRIM(RTRIM(@motivo)), 150);

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        EXEC plantel.convocatoria_modificar
             @convocatoria_id = @conv_sale_id, @dorsal = @dorsal_sale, @fecha_alta = @fecha_alta_sale,
             @motivo_alta = @motivo_alta_sale, @fecha_baja = @fecha, @motivo_baja = @motivo;

        EXEC plantel.convocatoria_insertar
             @seleccion_id = @seleccion_id, @jugador_id = @jugador_entra_id, @dorsal = @dorsal,
             @fecha_alta = @fecha, @motivo_alta = @motivo_alta, @convocatoria_id = @convocatoria_id OUTPUT;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- plantel.importar_planteles (Entrega 6): lee el motivo de alta cifrado (lo vuelve a pasar al dar de baja o cambiar el dorsal).
ALTER PROCEDURE plantel.importar_planteles
    @ruta_archivo       VARCHAR(500),
    @fecha_convocatoria DATE = '2026-06-01'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @json NVARCHAR(MAX),
            @lote_id INT, @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @bajas INT = 0, @i INT = 1, @n INT,
            @registro VARCHAR(1000), @hoy DATE = CAST(SYSDATETIME() AS DATE), @resultado VARCHAR(12),
            @seleccion_id INT, @es_dt BIT, @dorsal INT, @posicion VARCHAR(13), @nombre VARCHAR(100),
            @apellido VARCHAR(100), @fecha_nacimiento DATE, @club VARCHAR(120), @jugador_id INT,
            @posicion_actual VARCHAR(13), @club_actual VARCHAR(120), @convocatoria_id INT, @dorsal_actual INT,
            @fecha_alta DATE, @motivo_alta VARCHAR(150), @staff_id INT, @nombre_actual VARCHAR(100),
            @apellido_actual VARCHAR(100), @fecha_baja DATE;

    EXEC importacion.lote_abrir 'plantel.importar_planteles', @ruta_archivo, @lote_id OUTPUT;

    BEGIN TRY
        EXEC importacion.archivo_leer_scraping @ruta_archivo, 'planteles', @json OUTPUT;
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    -- Tablas temporales del proceso: lo leído del archivo, lo transformado (el WHILE de altas la
    -- recorre por su clave primaria) y los convocados a dar de baja.
    CREATE TABLE #leidas (
        fila           INT PRIMARY KEY,
        equipo         NVARCHAR(100) COLLATE DATABASE_DEFAULT,
        posicion_txt   NVARCHAR(10)  COLLATE DATABASE_DEFAULT,
        dorsal_txt     NVARCHAR(10)  COLLATE DATABASE_DEFAULT,
        jugador        NVARCHAR(200) COLLATE DATABASE_DEFAULT,
        apellido_orden NVARCHAR(200) COLLATE DATABASE_DEFAULT,
        fecha_txt      NVARCHAR(20)  COLLATE DATABASE_DEFAULT,
        club           NVARCHAR(200) COLLATE DATABASE_DEFAULT
    );
    CREATE TABLE #filas (
        fila             INT PRIMARY KEY,
        equipo           NVARCHAR(100) COLLATE DATABASE_DEFAULT,
        jugador          NVARCHAR(200) COLLATE DATABASE_DEFAULT,
        dorsal_txt       NVARCHAR(10)  COLLATE DATABASE_DEFAULT,
        posicion_txt     NVARCHAR(10)  COLLATE DATABASE_DEFAULT,
        fecha_txt        NVARCHAR(20)  COLLATE DATABASE_DEFAULT,
        club             NVARCHAR(200) COLLATE DATABASE_DEFAULT,
        seleccion_id     INT,
        es_dt            BIT,
        dorsal           INT,
        posicion         VARCHAR(13)  COLLATE DATABASE_DEFAULT,
        fecha_nacimiento DATE,
        nombre           VARCHAR(100) COLLATE DATABASE_DEFAULT,
        apellido         VARCHAR(100) COLLATE DATABASE_DEFAULT,
        formato_ok       BIT
    );
    CREATE TABLE #bajas (
        orden           INT IDENTITY(1, 1) PRIMARY KEY,
        convocatoria_id INT,
        dorsal          INT,
        fecha_alta      DATE,
        motivo_alta     VARCHAR(150)  COLLATE DATABASE_DEFAULT,
        registro        VARCHAR(1000) COLLATE DATABASE_DEFAULT
    );

    -- 1) Lectura: una fila por jugador o director técnico, con su selección.
    INSERT INTO #leidas (fila, equipo, posicion_txt, dorsal_txt, jugador, apellido_orden, fecha_txt, club)
    SELECT CAST(p.[key] AS INT) + 1 AS fila, d.equipo,
           IIF(d.rol = N'DT', N'DT', d.posicion) AS posicion_txt, d.dorsal AS dorsal_txt, d.jugador,
           d.apellido_orden, d.fecha_txt, d.club
    FROM OPENJSON(@json, '$.planteles') p
    CROSS APPLY OPENJSON(p.value) WITH (
        equipo         NVARCHAR(100) '$.equipo',
        rol            NVARCHAR(10)  '$.rol',
        dorsal         NVARCHAR(10)  '$.dorsal',
        posicion       NVARCHAR(10)  '$.posicion',
        jugador        NVARCHAR(200) '$.nombre_completo',
        apellido_orden NVARCHAR(200) '$.nombre_orden',
        fecha_txt      NVARCHAR(20)  '$.fecha_nacimiento',
        club           NVARCHAR(200) '$.club'
    ) d;

    SELECT @leidos = COUNT(*) FROM #leidas;

    -- 2) Transformación por conjunto: selección, dorsal, posición, fecha, nombre y apellido.
    INSERT INTO #filas (fila, equipo, jugador, dorsal_txt, posicion_txt, fecha_txt, club, seleccion_id, es_dt,
                        dorsal, posicion, fecha_nacimiento, nombre, apellido)
    SELECT l.fila, l.equipo, l.jugador, l.dorsal_txt, l.posicion_txt, l.fecha_txt, l.club,
           importacion.fn_seleccion_id(l.equipo) AS seleccion_id,
           IIF(l.posicion_txt = N'DT', 1, 0) AS es_dt,
           TRY_CONVERT(INT, l.dorsal_txt) AS dorsal,
           CASE LEFT(l.posicion_txt, 2) WHEN N'GK' THEN 'arquero' WHEN N'DF' THEN 'defensor'
                WHEN N'MF' THEN 'mediocampista' WHEN N'FW' THEN 'delantero' END AS posicion,
           TRY_CONVERT(DATE, l.fecha_txt, 23) AS fecha_nacimiento,
           CAST(n.nombre AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS nombre,
           CAST(n.apellido AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS apellido
    FROM #leidas l
    CROSS APPLY (
        SELECT CASE WHEN l.posicion_txt = N'DT' OR CHARINDEX(N',', ISNULL(l.apellido_orden, N'')) = 0 THEN 1
                    ELSE LEN(LTRIM(RTRIM(LEFT(l.apellido_orden, CHARINDEX(N',', l.apellido_orden) - 1))))
                       - LEN(REPLACE(LTRIM(RTRIM(LEFT(l.apellido_orden, CHARINDEX(N',', l.apellido_orden) - 1))), N' ', N'')) + 1
               END AS palabras_apellido
    ) c
    OUTER APPLY (
        SELECT LEFT(STRING_AGG(CASE WHEN w.parte = 'N' THEN w.value END, N' ') WITHIN GROUP (ORDER BY w.n), 100) AS nombre_pila,
               LEFT(STRING_AGG(CASE WHEN w.parte = 'A' THEN w.value END, N' ') WITHIN GROUP (ORDER BY w.n), 100) AS apellido
        FROM (SELECT x.value, x.n, IIF(x.n <= x.total - c.palabras_apellido, 'N', 'A') AS parte
              FROM (SELECT s.value, ROW_NUMBER() OVER (ORDER BY s.ordinal) AS n, COUNT(*) OVER () AS total
                    FROM STRING_SPLIT(ISNULL(l.jugador, N''), N' ', 1) s WHERE s.value <> N'') x) w
    ) a
    CROSS APPLY (SELECT ISNULL(a.nombre_pila, a.apellido) AS nombre, a.apellido) n;

    UPDATE #filas
    SET formato_ok = IIF(seleccion_id IS NOT NULL AND nombre IS NOT NULL
                         AND (es_dt = 1 OR (dorsal BETWEEN 1 AND 99 AND posicion IS NOT NULL AND fecha_nacimiento IS NOT NULL)),
                         1, 0);

    -- 3) Bajas de los convocados vigentes que la lista ya no incluye.
    INSERT INTO #bajas (convocatoria_id, dorsal, fecha_alta, motivo_alta, registro)
    SELECT c.convocatoria_id, c.dorsal, c.fecha_alta, seguridad.fn_descifrar(c.motivo_alta),   -- [Entrega 8: cifrado]
           CONCAT(j.nombre, ' ', j.apellido, ' | dorsal ', c.dorsal) AS registro
    FROM plantel.convocatoria c
    JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
    WHERE c.fecha_baja IS NULL
      AND c.seleccion_id IN (SELECT seleccion_id FROM #filas WHERE seleccion_id IS NOT NULL
                             GROUP BY seleccion_id HAVING MIN(CAST(formato_ok AS INT)) = 1)
      AND NOT EXISTS (SELECT 1 FROM #filas f
                      WHERE f.seleccion_id = c.seleccion_id AND f.es_dt = 0 AND f.nombre = j.nombre
                        AND f.apellido = j.apellido AND f.fecha_nacimiento = j.fecha_nacimiento);

    SELECT @n = COUNT(*) FROM #bajas;
    WHILE @i <= @n
    BEGIN
        SELECT @convocatoria_id = convocatoria_id, @dorsal = dorsal, @fecha_alta = fecha_alta,
               @motivo_alta = motivo_alta, @registro = registro
        FROM #bajas WHERE orden = @i;
        SET @fecha_baja = IIF(@hoy < @fecha_alta, @fecha_alta, @hoy);
        BEGIN TRY
            EXEC plantel.convocatoria_modificar @convocatoria_id, @dorsal, @fecha_alta, @motivo_alta,
                 @fecha_baja, 'Ya no figura en la lista oficial (importación de plantel)';
            SET @bajas += 1;
        END TRY
        BEGIN CATCH
            SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
            EXEC importacion.error_registrar @lote_id, NULL, @registro, @numero, @mensaje;
        END CATCH;
        SET @i += 1;
    END;
    IF @bajas > 0
        PRINT CONCAT('plantel.importar_planteles: ', @bajas, ' convocados dados de baja (siguen en el historial).');

    -- 4) Altas y modificaciones, fila por fila.
    SET @i = 1;
    WHILE @i <= @leidos
    BEGIN
        SELECT @seleccion_id = seleccion_id, @es_dt = es_dt, @dorsal = dorsal, @posicion = posicion,
               @nombre = nombre, @apellido = apellido, @fecha_nacimiento = fecha_nacimiento, @club = LEFT(club, 120),
               @registro = CONCAT(equipo, ' | ', dorsal_txt, ' | ', posicion_txt, ' | ', jugador, ' | ', fecha_txt),
               @errores = ''
        FROM #filas WHERE fila = @i;
        SELECT @jugador_id = NULL, @convocatoria_id = NULL, @staff_id = NULL, @resultado = 'sin_cambios';

        BEGIN TRY
            IF @seleccion_id IS NULL
                SET @errores += '- La selección no está registrada en el torneo.' + @nl;
            IF @nombre IS NULL
                SET @errores += '- El nombre está vacío.' + @nl;
            IF @es_dt = 0
            BEGIN
                IF @dorsal IS NULL OR @dorsal NOT BETWEEN 1 AND 99
                    SET @errores += '- El dorsal debe ser un número entre 1 y 99.' + @nl;
                IF @posicion IS NULL
                    SET @errores += '- La posición debe ser GK, DF, MF o FW.' + @nl;
                IF @fecha_nacimiento IS NULL
                    SET @errores += '- La fecha de nacimiento no es válida.' + @nl;
            END;
            IF @errores <> ''
            BEGIN
                SET @errores = 'Fila rechazada:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            BEGIN TRANSACTION;

            IF @es_dt = 1
            BEGIN
                SELECT @staff_id = staff_id, @nombre_actual = nombre, @apellido_actual = apellido
                FROM plantel.cuerpo_tecnico WHERE seleccion_id = @seleccion_id AND rol = 'director_tecnico';
                IF @staff_id IS NULL
                BEGIN
                    EXEC plantel.cuerpo_tecnico_insertar @seleccion_id, @nombre, @apellido, 'director_tecnico';
                    SET @resultado = 'insertado';
                END
                ELSE IF @nombre_actual <> @nombre OR @apellido_actual <> @apellido
                BEGIN
                    EXEC plantel.cuerpo_tecnico_modificar @staff_id, @seleccion_id, @nombre, @apellido, 'director_tecnico';
                    SET @resultado = 'actualizado';
                END;
            END
            ELSE
            BEGIN
                SELECT @jugador_id = jugador_id, @posicion_actual = posicion_habitual, @club_actual = club_origen
                FROM plantel.jugador
                WHERE nombre = @nombre AND apellido = @apellido AND fecha_nacimiento = @fecha_nacimiento;

                IF @jugador_id IS NULL
                BEGIN
                    EXEC plantel.jugador_insertar @nombre, @apellido, @fecha_nacimiento, @posicion, @club, @jugador_id OUTPUT;
                    SET @resultado = 'insertado';
                END
                ELSE IF @posicion_actual <> @posicion OR ISNULL(@club_actual, '') <> ISNULL(@club, '')
                BEGIN
                    EXEC plantel.jugador_modificar @jugador_id, @nombre, @apellido, @fecha_nacimiento, @posicion, @club;
                    SET @resultado = 'actualizado';
                END;

                SELECT @convocatoria_id = convocatoria_id, @dorsal_actual = dorsal, @fecha_alta = fecha_alta,
                       @motivo_alta = seguridad.fn_descifrar(motivo_alta)   -- [Entrega 8: cifrado]
                FROM plantel.convocatoria
                WHERE seleccion_id = @seleccion_id AND jugador_id = @jugador_id AND fecha_baja IS NULL;

                IF @convocatoria_id IS NULL
                BEGIN
                    EXEC plantel.convocatoria_insertar @seleccion_id, @jugador_id, @dorsal, @fecha_convocatoria,
                         'Lista oficial (importación de plantel)';
                    SET @resultado = 'insertado';
                END
                ELSE IF @dorsal_actual <> @dorsal
                BEGIN
                    EXEC plantel.convocatoria_modificar @convocatoria_id, @dorsal, @fecha_alta, @motivo_alta;
                    IF @resultado = 'sin_cambios' SET @resultado = 'actualizado';
                END;
            END;

            COMMIT TRANSACTION;

            IF @resultado = 'insertado' SET @insertados += 1;
            ELSE IF @resultado = 'actualizado' SET @actualizados += 1;
            ELSE SET @sin_cambios += 1;
        END TRY
        BEGIN CATCH
            SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            EXEC importacion.error_registrar @lote_id, @i, @registro, @numero, @mensaje;
            SET @rechazados += 1;
        END CATCH;

        SET @i += 1;
    END;

    DROP TABLE #leidas, #filas, #bajas;
    SET @actualizados += @bajas;
    EXEC importacion.lote_cerrar @lote_id, @leidos, @insertados, @actualizados, @sin_cambios, @rechazados;
END;
GO

-- ============================================================
-- 5. SP DE CONSULTA DE LOS DATOS CIFRADOS (nuevos)
-- ============================================================

/* Devuelven el dato descifrado a quien tenga EXECUTE sobre el SP (cuadro de 2_entrega8_roles.sql):
   el administrador, todos; el comité arbitral, los de árbitros e informes; el gestor de
   publicidad, el de anunciantes. Los demás roles reciben el error 229. */

-- Convocatorias de una selección (o de todas), con los motivos de alta y baja.
CREATE OR ALTER PROCEDURE plantel.consultar_convocatoria
    @seleccion_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.convocatoria_id, pa.nombre AS seleccion, c.dorsal, j.nombre, j.apellido,
           c.fecha_alta, seguridad.fn_descifrar(c.motivo_alta) AS motivo_alta,
           c.fecha_baja, seguridad.fn_descifrar(c.motivo_baja) AS motivo_baja
    FROM plantel.convocatoria c
    JOIN plantel.jugador j  ON j.jugador_id = c.jugador_id
    JOIN torneo.seleccion s ON s.seleccion_id = c.seleccion_id
    JOIN torneo.pais pa     ON pa.pais_id = s.pais_id
    WHERE @seleccion_id IS NULL OR c.seleccion_id = @seleccion_id
    ORDER BY pa.nombre, c.fecha_baja, c.dorsal;
END;
GO

-- Ficha de un árbitro (o de todos), con la fecha de nacimiento.
CREATE OR ALTER PROCEDURE arbitraje.consultar_arbitro
    @arbitro_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.arbitro_id, a.nombre, a.apellido, p.nombre AS pais, a.categoria,
           CONVERT(DATE, seguridad.fn_descifrar(a.fecha_nacimiento), 23) AS fecha_nacimiento
    FROM arbitraje.arbitro a
    JOIN torneo.pais p ON p.pais_id = a.pais_id
    WHERE @arbitro_id IS NULL OR a.arbitro_id = @arbitro_id
    ORDER BY a.apellido, a.nombre;
END;
GO

-- Informes post-partido de un árbitro (o de todos), con el contenido y la sanción.
CREATE OR ALTER PROCEDURE arbitraje.consultar_informes
    @arbitro_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT i.informe_id, a.nombre + ' ' + a.apellido AS arbitro, d.rol, d.partido_id, i.fecha,
           seguridad.fn_descifrar(i.contenido) AS contenido, seguridad.fn_descifrar(i.sancion) AS sancion
    FROM arbitraje.informe_arbitral i
    JOIN arbitraje.designacion_arbitral d ON d.designacion_id = i.designacion_id
    JOIN arbitraje.arbitro a              ON a.arbitro_id = d.arbitro_id
    WHERE @arbitro_id IS NULL OR a.arbitro_id = @arbitro_id
    ORDER BY i.fecha, i.informe_id;
END;
GO

-- Anunciantes, con el contacto.
CREATE OR ALTER PROCEDURE publicidad.consultar_anunciante
    @anunciante_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT a.anunciante_id, a.nombre, a.razon_social, seguridad.fn_descifrar(a.contacto) AS contacto
    FROM publicidad.anunciante a
    WHERE @anunciante_id IS NULL OR a.anunciante_id = @anunciante_id
    ORDER BY a.nombre;
END;
GO
