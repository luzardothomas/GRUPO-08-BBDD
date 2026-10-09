-- =======================================================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 5: Stored Procedures
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Procedimientos almacenados de la base mundial_2026. Se ejecuta después de
--   entrega5_definition.sql (que crea la base, las tablas, el tipo tabla y las vistas):
--     II.    Procedimientos almacenados de ABM de cada tabla, con validaciones y un
--            único mensaje de error agrupado por SP y operación.
--     III.   Procedimientos de lógica de negocio, transaccionales y multi-tabla.
--     IV.    Carga de los parámetros iniciales.
--   Las pruebas están en entrega5_test.sql, que se ejecuta después de este script.
-- =======================================================================================

USE mundial_2026;
GO

-- ###################
-- ##  II. SPs ABM  ##
-- ###################

-- Norma común a todos los SP-ABM:
/* * <esquema>.<tabla>_insertar / _modificar / _eliminar. Los _validar son internos: reúnen
     las condiciones compartidas por el alta y la modificación.
   * Todas las condiciones incumplidas se acumulan en @errores y se informan juntas, en un
     único THROW 50001 por SP y operación (no se corta en la primera).
   * El alta devuelve la clave generada en un parámetro OUTPUT.
   * La baja es física y se rechaza si hay filas dependientes, indicando cuáles. */

-- ===============
-- II.0 PARÁMETROS
-- ===============

CREATE OR ALTER PROCEDURE torneo.parametro_insertar
    @clave       VARCHAR(60),
    @valor       INT,
    @descripcion VARCHAR(150)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NULLIF(LTRIM(RTRIM(@clave)), '') IS NULL
        SET @errores += '- La clave es obligatoria.' + @nl;
    ELSE IF LEN(@clave) > 40 OR @clave LIKE '%[^a-z0-9_]%'
        SET @errores += '- La clave admite hasta 40 caracteres: letras, números y guion bajo.' + @nl;
    IF @valor IS NULL OR @valor < 0
        SET @errores += '- El valor es obligatorio y no puede ser negativo.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@descripcion)), '') IS NULL
        SET @errores += '- La descripción es obligatoria.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.parametro WHERE clave = @clave)
        SET @errores += '- Ya existe un parámetro con la clave ''' + @clave + '''.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.parametro_insertar - alta rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO torneo.parametro (clave, valor, descripcion)
    VALUES (LOWER(@clave), @valor, @descripcion);
END;
GO

CREATE OR ALTER PROCEDURE torneo.parametro_modificar
    @clave       VARCHAR(60),
    @valor       INT,
    @descripcion VARCHAR(150) = NULL                 -- NULL = conserva la descripción actual
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.parametro WHERE clave = @clave)
        SET @errores += '- No existe el parámetro ''' + ISNULL(@clave, '(nulo)') + '''.' + @nl;
    IF @valor IS NULL OR @valor < 0
        SET @errores += '- El valor es obligatorio y no puede ser negativo.' + @nl;
    IF @descripcion IS NOT NULL AND LTRIM(RTRIM(@descripcion)) = ''
        SET @errores += '- La descripción no puede quedar vacía.' + @nl;
    IF @clave = 'prime_time_hora_hasta' AND @valor > 24
        SET @errores += '- La hora de fin del prime time debe estar entre 0 y 24.' + @nl;
    IF @clave = 'prime_time_hora_desde' AND @valor > 23
        SET @errores += '- La hora de inicio del prime time debe estar entre 0 y 23.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.parametro_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE torneo.parametro
    SET valor = @valor,
        descripcion = ISNULL(@descripcion, descripcion)
    WHERE clave = @clave;
END;
GO

CREATE OR ALTER PROCEDURE torneo.parametro_eliminar
    @clave VARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.parametro WHERE clave = @clave)
        SET @errores += '- No existe el parámetro ''' + ISNULL(@clave, '(nulo)') + '''.' + @nl;
    IF @clave IN ('convocatoria_min_jugadores', 'convocatoria_max_jugadores', 'formacion_titulares',
                  'formacion_max_suplentes', 'cambios_max_reglamentarios', 'ventanas_max_reglamentarias',
                  'cambios_extra_alargue', 'ventanas_extra_alargue', 'suspension_partidos_roja',
                  'prime_time_hora_desde', 'prime_time_hora_hasta')
        SET @errores += '- El parámetro es requerido por la lógica de negocio: se puede modificar, no eliminar.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.parametro_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM torneo.parametro WHERE clave = @clave;
END;
GO

-- =========================
-- II.1 PAÍS Y CONFEDERACIÓN
-- =========================

CREATE OR ALTER PROCEDURE torneo.pais_validar
    @pais_id        INT,                             -- NULL en el alta
    @codigo_iso     VARCHAR(10),
    @nombre         VARCHAR(80),
    @huso_horario   VARCHAR(10),
    @pbi_per_capita NUMERIC(12,2),
    @errores        VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF @pais_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pais_id = @pais_id)
        SET @errores += '- No existe el país con id ' + CAST(@pais_id AS VARCHAR(12)) + '.' + @nl;
    IF @codigo_iso IS NULL OR LEN(@codigo_iso) <> 3 OR @codigo_iso LIKE '%[^A-Za-z]%'
        SET @errores += '- El código ISO debe tener exactamente 3 letras.' + @nl;
    ELSE IF EXISTS (SELECT 1 FROM torneo.pais
                    WHERE codigo_iso = @codigo_iso AND (@pais_id IS NULL OR pais_id <> @pais_id))
        SET @errores += '- Ya existe un país con el código ISO ''' + UPPER(@codigo_iso) + '''.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre es obligatorio.' + @nl;
    IF @huso_horario IS NULL OR LEN(@huso_horario) <> 6 OR @huso_horario NOT LIKE 'UTC[-+][0-9][0-9]'
        SET @errores += '- El huso horario debe tener el formato UTC+hh o UTC-hh (ej: UTC-03).' + @nl;
    ELSE IF CAST(SUBSTRING(@huso_horario, 4, 3) AS INT) NOT BETWEEN -12 AND 14
        SET @errores += '- El huso horario debe estar entre UTC-12 y UTC+14.' + @nl;
    IF @pbi_per_capita < 0
        SET @errores += '- El PBI per cápita no puede ser negativo.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE torneo.pais_insertar
    @codigo_iso     VARCHAR(10),
    @nombre         VARCHAR(80),
    @huso_horario   VARCHAR(10),
    @pbi_per_capita NUMERIC(12,2) = NULL,
    @pais_id        INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC torneo.pais_validar NULL, @codigo_iso, @nombre, @huso_horario, @pbi_per_capita, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.pais_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO torneo.pais (codigo_iso, nombre, huso_horario, pbi_per_capita)
    VALUES (UPPER(@codigo_iso), LTRIM(RTRIM(@nombre)), @huso_horario, @pbi_per_capita);

    SET @pais_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE torneo.pais_modificar
    @pais_id        INT,
    @codigo_iso     VARCHAR(10),
    @nombre         VARCHAR(80),
    @huso_horario   VARCHAR(10),
    @pbi_per_capita NUMERIC(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    IF @pais_id IS NULL SET @errores = '- El id del país es obligatorio.' + CHAR(13) + CHAR(10);
    EXEC torneo.pais_validar @pais_id, @codigo_iso, @nombre, @huso_horario, @pbi_per_capita, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.pais_modificar - modificación rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE torneo.pais
    SET codigo_iso = UPPER(@codigo_iso),
        nombre = LTRIM(RTRIM(@nombre)),
        huso_horario = @huso_horario,
        pbi_per_capita = @pbi_per_capita
    WHERE pais_id = @pais_id;
END;
GO

CREATE OR ALTER PROCEDURE torneo.pais_eliminar
    @pais_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pais_id = @pais_id)
        SET @errores += '- No existe el país con id ' + ISNULL(CAST(@pais_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.sede WHERE pais_id = @pais_id)
        SET @errores += '- Tiene sedes asociadas.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.seleccion WHERE pais_id = @pais_id)
        SET @errores += '- Tiene una selección participante.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.arbitro WHERE pais_id = @pais_id)
        SET @errores += '- Tiene árbitros registrados.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.campania_pais_interes WHERE pais_id = @pais_id)
        SET @errores += '- Es país de interés de campañas publicitarias.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria WHERE pais_mercado_id = @pais_id)
        SET @errores += '- Es mercado de piezas publicitarias.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.pais_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM torneo.pais WHERE pais_id = @pais_id;
END;
GO

CREATE OR ALTER PROCEDURE torneo.confederacion_insertar
    @nombre           VARCHAR(20),
    @confederacion_id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @nombre IS NULL OR @nombre NOT IN ('AFC', 'CAF', 'CONCACAF', 'CONMEBOL', 'OFC', 'UEFA')
        SET @errores += '- La confederación debe ser AFC, CAF, CONCACAF, CONMEBOL, OFC o UEFA.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = @nombre)
        SET @errores += '- La confederación ''' + @nombre + ''' ya está registrada.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.confederacion_insertar - alta rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO torneo.confederacion (nombre) VALUES (UPPER(@nombre));
    SET @confederacion_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE torneo.confederacion_modificar
    @confederacion_id INT,
    @nombre           VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE confederacion_id = @confederacion_id)
        SET @errores += '- No existe la confederación con id '
                      + ISNULL(CAST(@confederacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @nombre IS NULL OR @nombre NOT IN ('AFC', 'CAF', 'CONCACAF', 'CONMEBOL', 'OFC', 'UEFA')
        SET @errores += '- La confederación debe ser AFC, CAF, CONCACAF, CONMEBOL, OFC o UEFA.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.confederacion
               WHERE nombre = @nombre AND confederacion_id <> @confederacion_id)
        SET @errores += '- La confederación ''' + @nombre + ''' ya está registrada.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.confederacion_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE torneo.confederacion SET nombre = UPPER(@nombre) WHERE confederacion_id = @confederacion_id;
END;
GO

CREATE OR ALTER PROCEDURE torneo.confederacion_eliminar
    @confederacion_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE confederacion_id = @confederacion_id)
        SET @errores += '- No existe la confederación con id '
                      + ISNULL(CAST(@confederacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.seleccion WHERE confederacion_id = @confederacion_id)
        SET @errores += '- Tiene selecciones afiliadas.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.confederacion_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM torneo.confederacion WHERE confederacion_id = @confederacion_id;
END;
GO

-- ==============================
-- II.2 SEDE, SELECCIÓN Y PARTIDO
-- ==============================

CREATE OR ALTER PROCEDURE torneo.sede_validar
    @sede_id      INT,                               -- NULL en el alta
    @nombre       VARCHAR(80),
    @ciudad       VARCHAR(80),
    @pais_id      INT,
    @capacidad    INT,
    @huso_horario VARCHAR(10),
    @errores      VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF @sede_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.sede WHERE sede_id = @sede_id)
        SET @errores += '- No existe la sede con id ' + CAST(@sede_id AS VARCHAR(12)) + '.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre del estadio es obligatorio.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@ciudad)), '') IS NULL
        SET @errores += '- La ciudad es obligatoria.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pais_id = @pais_id)
        SET @errores += '- No existe el país con id ' + ISNULL(CAST(@pais_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @capacidad IS NULL OR @capacidad <= 0
        SET @errores += '- La capacidad debe ser mayor a cero.' + @nl;
    IF @huso_horario IS NULL OR LEN(@huso_horario) <> 6 OR @huso_horario NOT LIKE 'UTC[-+][0-9][0-9]'
        SET @errores += '- El huso horario debe tener el formato UTC+hh o UTC-hh (ej: UTC-04).' + @nl;
    ELSE IF CAST(SUBSTRING(@huso_horario, 4, 3) AS INT) NOT BETWEEN -12 AND 14
        SET @errores += '- El huso horario debe estar entre UTC-12 y UTC+14.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.sede
               WHERE nombre = @nombre AND ciudad = @ciudad AND (@sede_id IS NULL OR sede_id <> @sede_id))
        SET @errores += '- Ya existe una sede con ese nombre en esa ciudad.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE torneo.sede_insertar
    @nombre       VARCHAR(80),
    @ciudad       VARCHAR(80),
    @pais_id      INT,
    @capacidad    INT,
    @huso_horario VARCHAR(10),
    @sede_id      INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC torneo.sede_validar NULL, @nombre, @ciudad, @pais_id, @capacidad, @huso_horario, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.sede_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO torneo.sede (nombre, ciudad, pais_id, capacidad, huso_horario)
    VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@ciudad)), @pais_id, @capacidad, @huso_horario);

    SET @sede_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE torneo.sede_modificar
    @sede_id      INT,
    @nombre       VARCHAR(80),
    @ciudad       VARCHAR(80),
    @pais_id      INT,
    @capacidad    INT,
    @huso_horario VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @sede_id IS NULL SET @errores = '- El id de la sede es obligatorio.' + @nl;
    EXEC torneo.sede_validar @sede_id, @nombre, @ciudad, @pais_id, @capacidad, @huso_horario, @errores OUTPUT;

    -- El huso de la sede fija el offset de fecha_hora_local de sus partidos.
    IF EXISTS (SELECT 1 FROM torneo.sede s
               WHERE s.sede_id = @sede_id AND s.huso_horario <> @huso_horario)
       AND EXISTS (SELECT 1 FROM torneo.partido WHERE sede_id = @sede_id)
        SET @errores += '- No se puede cambiar el huso horario: la sede ya tiene partidos programados.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido WHERE sede_id = @sede_id AND asistencia_publico > @capacidad)
        SET @errores += '- La capacidad no puede ser menor a la asistencia ya registrada en sus partidos.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.sede_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE torneo.sede
    SET nombre = LTRIM(RTRIM(@nombre)),
        ciudad = LTRIM(RTRIM(@ciudad)),
        pais_id = @pais_id,
        capacidad = @capacidad,
        huso_horario = @huso_horario
    WHERE sede_id = @sede_id;
END;
GO

CREATE OR ALTER PROCEDURE torneo.sede_eliminar
    @sede_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.sede WHERE sede_id = @sede_id)
        SET @errores += '- No existe la sede con id ' + ISNULL(CAST(@sede_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido WHERE sede_id = @sede_id)
        SET @errores += '- Tiene partidos asociados.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.sede_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM torneo.sede WHERE sede_id = @sede_id;
END;
GO

CREATE OR ALTER PROCEDURE torneo.seleccion_validar
    @seleccion_id     INT,                           -- NULL en el alta
    @pais_id          INT,
    @confederacion_id INT,
    @grupo            VARCHAR(5),
    @errores          VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF @seleccion_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id ' + CAST(@seleccion_id AS VARCHAR(12)) + '.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pais_id = @pais_id)
        SET @errores += '- No existe el país con id ' + ISNULL(CAST(@pais_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE IF EXISTS (SELECT 1 FROM torneo.seleccion
                    WHERE pais_id = @pais_id AND (@seleccion_id IS NULL OR seleccion_id <> @seleccion_id))
        SET @errores += '- El país ya tiene una selección participante.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE confederacion_id = @confederacion_id)
        SET @errores += '- No existe la confederación con id '
                      + ISNULL(CAST(@confederacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @grupo IS NULL OR LEN(@grupo) <> 1 OR @grupo NOT LIKE '[A-L]'
        SET @errores += '- El grupo debe ser una letra entre A y L.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE torneo.seleccion_insertar
    @pais_id          INT,
    @confederacion_id INT,
    @grupo            VARCHAR(5),
    @seleccion_id     INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC torneo.seleccion_validar NULL, @pais_id, @confederacion_id, @grupo, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.seleccion_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO torneo.seleccion (pais_id, confederacion_id, grupo)
    VALUES (@pais_id, @confederacion_id, UPPER(@grupo));

    SET @seleccion_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE torneo.seleccion_modificar
    @seleccion_id     INT,
    @pais_id          INT,
    @confederacion_id INT,
    @grupo            VARCHAR(5)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @seleccion_id IS NULL SET @errores = '- El id de la selección es obligatorio.' + @nl;
    EXEC torneo.seleccion_validar @seleccion_id, @pais_id, @confederacion_id, @grupo, @errores OUTPUT;

    IF EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id AND grupo <> @grupo)
       AND EXISTS (SELECT 1 FROM torneo.partido
                   WHERE fase = 'grupos' AND @seleccion_id IN (seleccion_local_id, seleccion_visitante_id))
        SET @errores += '- No se puede cambiar el grupo: la selección ya tiene partidos de fase de grupos.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.seleccion_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE torneo.seleccion
    SET pais_id = @pais_id, confederacion_id = @confederacion_id, grupo = UPPER(@grupo)
    WHERE seleccion_id = @seleccion_id;
END;
GO

CREATE OR ALTER PROCEDURE torneo.seleccion_eliminar
    @seleccion_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id '
                      + ISNULL(CAST(@seleccion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido WHERE @seleccion_id IN (seleccion_local_id, seleccion_visitante_id))
        SET @errores += '- Tiene partidos asociados.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.convocatoria WHERE seleccion_id = @seleccion_id)
        SET @errores += '- Tiene jugadores convocados.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico WHERE seleccion_id = @seleccion_id)
        SET @errores += '- Tiene cuerpo técnico registrado.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.seleccion_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM torneo.seleccion WHERE seleccion_id = @seleccion_id;
END;
GO

CREATE OR ALTER PROCEDURE torneo.partido_validar
    @partido_id             INT,                     -- NULL en el alta
    @sede_id                INT,
    @fecha_hora_local       DATETIMEOFFSET,
    @fecha_hora_utc         DATETIMEOFFSET,
    @fase                   VARCHAR(20),
    @seleccion_local_id     INT,
    @seleccion_visitante_id INT,
    @errores                VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10), @huso_sede CHAR(6);
    SET @errores = ISNULL(@errores, '');

    IF @partido_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + CAST(@partido_id AS VARCHAR(12)) + '.' + @nl;

    SELECT @huso_sede = huso_horario FROM torneo.sede WHERE sede_id = @sede_id;
    IF @huso_sede IS NULL
        SET @errores += '- No existe la sede con id ' + ISNULL(CAST(@sede_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;

    IF @fecha_hora_local IS NULL OR @fecha_hora_utc IS NULL
        SET @errores += '- La fecha y hora del partido es obligatoria.' + @nl;
    ELSE
    BEGIN
        IF @huso_sede IS NOT NULL
           AND DATEPART(TZOFFSET, @fecha_hora_local) <> CAST(SUBSTRING(@huso_sede, 4, 3) AS INT) * 60
            SET @errores += '- La hora local debe expresarse en el huso de la sede (' + @huso_sede + ').' + @nl;
        IF DATEPART(TZOFFSET, @fecha_hora_utc) <> 0
            SET @errores += '- La hora UTC debe expresarse con desplazamiento +00:00.' + @nl;
        IF @fecha_hora_utc <> @fecha_hora_local
            SET @errores += '- La hora UTC y la hora local no representan el mismo instante.' + @nl;
    END;

    IF @fase IS NULL OR @fase NOT IN
       ('grupos', 'dieciseisavos', 'octavos', 'cuartos', 'semifinal', 'tercer_puesto', 'final')
        SET @errores += '- La fase debe ser grupos, dieciseisavos, octavos, cuartos, semifinal, tercer_puesto o final.' + @nl;

    IF NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_local_id)
        SET @errores += '- No existe la selección local con id '
                      + ISNULL(CAST(@seleccion_local_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_visitante_id)
        SET @errores += '- No existe la selección visitante con id '
                      + ISNULL(CAST(@seleccion_visitante_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @seleccion_local_id = @seleccion_visitante_id
        SET @errores += '- La selección local y la visitante deben ser distintas.' + @nl;

    IF @fase = 'grupos'
       AND (SELECT COUNT(DISTINCT grupo) FROM torneo.seleccion
            WHERE seleccion_id IN (@seleccion_local_id, @seleccion_visitante_id)) > 1
        SET @errores += '- En fase de grupos ambas selecciones deben pertenecer al mismo grupo.' + @nl;

    IF EXISTS (SELECT 1 FROM torneo.partido
               WHERE fase = @fase
                 AND ((seleccion_local_id = @seleccion_local_id AND seleccion_visitante_id = @seleccion_visitante_id)
                   OR (seleccion_local_id = @seleccion_visitante_id AND seleccion_visitante_id = @seleccion_local_id))
                 AND (@partido_id IS NULL OR partido_id <> @partido_id))
        SET @errores += '- Ya existe un partido entre esas selecciones en la fase indicada.' + @nl;

    IF EXISTS (SELECT 1 FROM torneo.partido
               WHERE sede_id = @sede_id
                 AND CAST(fecha_hora_local AS DATE) = CAST(@fecha_hora_local AS DATE)
                 AND (@partido_id IS NULL OR partido_id <> @partido_id))
        SET @errores += '- La sede ya tiene otro partido programado ese día.' + @nl;

    IF EXISTS (SELECT 1 FROM torneo.partido
               WHERE (seleccion_local_id IN (@seleccion_local_id, @seleccion_visitante_id)
                   OR seleccion_visitante_id IN (@seleccion_local_id, @seleccion_visitante_id))
                 AND ABS(DATEDIFF(MINUTE, fecha_hora_utc, @fecha_hora_utc)) < 24 * 60
                 AND (@partido_id IS NULL OR partido_id <> @partido_id))
        SET @errores += '- Alguna de las selecciones ya juega otro partido a menos de 24 horas.' + @nl;
END;
GO

-- @fecha_hora_utc es opcional: si no se informa se deriva de la hora local; si se informa,
-- se valida que represente el mismo instante.

CREATE OR ALTER PROCEDURE torneo.partido_insertar
    @sede_id                INT,
    @fecha_hora_local       DATETIMEOFFSET,
    @fase                   VARCHAR(20),
    @seleccion_local_id     INT,
    @seleccion_visitante_id INT,
    @fecha_hora_utc         DATETIMEOFFSET = NULL,
    @partido_id             INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    IF @fecha_hora_utc IS NULL SET @fecha_hora_utc = SWITCHOFFSET(@fecha_hora_local, '+00:00');

    EXEC torneo.partido_validar NULL, @sede_id, @fecha_hora_local, @fecha_hora_utc, @fase,
         @seleccion_local_id, @seleccion_visitante_id, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.partido_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO torneo.partido
        (sede_id, fecha_hora_local, fecha_hora_utc, fase, seleccion_local_id, seleccion_visitante_id)
    VALUES
        (@sede_id, @fecha_hora_local, @fecha_hora_utc, @fase, @seleccion_local_id, @seleccion_visitante_id);

    SET @partido_id = SCOPE_IDENTITY();
END;
GO

/* Modifica la programación del partido. El resultado no se toca acá: lo carga
 torneo.registrar_resultado, que es además la única forma de pasar a 'finalizado'. */

CREATE OR ALTER PROCEDURE torneo.partido_modificar
    @partido_id             INT,
    @sede_id                INT,
    @fecha_hora_local       DATETIMEOFFSET,
    @fase                   VARCHAR(20),
    @seleccion_local_id     INT,
    @seleccion_visitante_id INT,
    @estado                 VARCHAR(15) = 'programado',
    @fecha_hora_utc         DATETIMEOFFSET = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @fecha_hora_utc IS NULL SET @fecha_hora_utc = SWITCHOFFSET(@fecha_hora_local, '+00:00');

    IF @partido_id IS NULL SET @errores = '- El id del partido es obligatorio.' + @nl;
    EXEC torneo.partido_validar @partido_id, @sede_id, @fecha_hora_local, @fecha_hora_utc, @fase,
         @seleccion_local_id, @seleccion_visitante_id, @errores OUTPUT;

    IF @estado IS NULL OR @estado NOT IN ('programado', 'suspendido')
        SET @errores += '- El estado debe ser programado o suspendido (finalizado lo asigna torneo.registrar_resultado).' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id AND estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado: no se puede reprogramar.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido
               WHERE partido_id = @partido_id
                 AND (seleccion_local_id <> @seleccion_local_id OR seleccion_visitante_id <> @seleccion_visitante_id))
       AND EXISTS (SELECT 1 FROM plantel.formacion WHERE partido_id = @partido_id)
        SET @errores += '- No se pueden cambiar las selecciones: el partido ya tiene formaciones cargadas.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.partido_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE torneo.partido
    SET sede_id = @sede_id,
        fecha_hora_local = @fecha_hora_local,
        fecha_hora_utc = @fecha_hora_utc,
        fase = @fase,
        seleccion_local_id = @seleccion_local_id,
        seleccion_visitante_id = @seleccion_visitante_id,
        estado = @estado
    WHERE partido_id = @partido_id;
END;
GO

CREATE OR ALTER PROCEDURE torneo.partido_eliminar
    @partido_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id AND estado = 'finalizado')
        SET @errores += '- El partido está finalizado.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.formacion WHERE partido_id = @partido_id)
        SET @errores += '- Tiene formaciones cargadas.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.tarjeta WHERE partido_id = @partido_id)
        SET @errores += '- Tiene tarjetas registradas.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.suspension WHERE partido_afectado_id = @partido_id)
        SET @errores += '- Es el partido afectado por suspensiones vigentes.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral WHERE partido_id = @partido_id)
        SET @errores += '- Tiene árbitros designados.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.espacio_publicitario WHERE partido_id = @partido_id)
        SET @errores += '- Tiene espacios publicitarios asignados.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.partido_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM torneo.partido WHERE partido_id = @partido_id;
END;
GO

-- ====================================================
-- II.3 PERSONA, CUERPO TÉCNICO, JUGADOR Y CONVOCATORIA
-- ====================================================

/* persona es el supertipo de jugador y cuerpo_tecnico. En la operatoria normal no se usa
 directamente: jugador_insertar y cuerpo_tecnico_insertar crean su persona en la misma
 transacción, y sus _eliminar la borran. */

CREATE OR ALTER PROCEDURE plantel.persona_insertar
    @tipo_persona VARCHAR(20),
    @persona_id   INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @tipo_persona IS NULL OR @tipo_persona NOT IN ('jugador', 'cuerpo_tecnico')
        SET @errores += '- El tipo de persona debe ser jugador o cuerpo_tecnico.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.persona_insertar - alta rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO plantel.persona (tipo_persona) VALUES (@tipo_persona);
    SET @persona_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE plantel.persona_modificar
    @persona_id   INT,
    @tipo_persona VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM plantel.persona WHERE persona_id = @persona_id)
        SET @errores += '- No existe la persona con id ' + ISNULL(CAST(@persona_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @tipo_persona IS NULL OR @tipo_persona NOT IN ('jugador', 'cuerpo_tecnico')
        SET @errores += '- El tipo de persona debe ser jugador o cuerpo_tecnico.' + @nl;
    IF @tipo_persona = 'cuerpo_tecnico' AND EXISTS (SELECT 1 FROM plantel.jugador WHERE persona_id = @persona_id)
        SET @errores += '- La persona está registrada como jugador: no puede pasar a cuerpo técnico.' + @nl;
    IF @tipo_persona = 'jugador' AND EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico WHERE persona_id = @persona_id)
        SET @errores += '- La persona está registrada como cuerpo técnico: no puede pasar a jugador.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.persona_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE plantel.persona SET tipo_persona = @tipo_persona WHERE persona_id = @persona_id;
END;
GO

CREATE OR ALTER PROCEDURE plantel.persona_eliminar
    @persona_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM plantel.persona WHERE persona_id = @persona_id)
        SET @errores += '- No existe la persona con id ' + ISNULL(CAST(@persona_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.jugador WHERE persona_id = @persona_id)
        SET @errores += '- Está registrada como jugador (usar plantel.jugador_eliminar).' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico WHERE persona_id = @persona_id)
        SET @errores += '- Está registrada como cuerpo técnico (usar plantel.cuerpo_tecnico_eliminar).' + @nl;
    IF EXISTS (SELECT 1 FROM evento.tarjeta WHERE persona_id = @persona_id)
        SET @errores += '- Tiene tarjetas registradas.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.persona_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM plantel.persona WHERE persona_id = @persona_id;
END;
GO

CREATE OR ALTER PROCEDURE plantel.cuerpo_tecnico_validar
    @staff_id     INT,                               -- NULL en el alta
    @seleccion_id INT,
    @nombre       VARCHAR(100),
    @apellido     VARCHAR(100),
    @rol          VARCHAR(25),
    @errores      VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF @staff_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico WHERE staff_id = @staff_id)
        SET @errores += '- No existe el integrante de cuerpo técnico con id ' + CAST(@staff_id AS VARCHAR(12)) + '.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id '
                      + ISNULL(CAST(@seleccion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre es obligatorio.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@apellido)), '') IS NULL
        SET @errores += '- El apellido es obligatorio.' + @nl;
    IF @rol IS NULL OR @rol NOT IN ('director_tecnico', 'ayudante_tecnico', 'preparador_fisico', 'otro')
        SET @errores += '- El rol debe ser director_tecnico, ayudante_tecnico, preparador_fisico u otro.' + @nl;
    IF @rol = 'director_tecnico'
       AND EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico
                   WHERE seleccion_id = @seleccion_id AND rol = 'director_tecnico'
                     AND (@staff_id IS NULL OR staff_id <> @staff_id))
        SET @errores += '- La selección ya tiene un director técnico.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico
               WHERE seleccion_id = @seleccion_id AND nombre = @nombre AND apellido = @apellido AND rol = @rol
                 AND (@staff_id IS NULL OR staff_id <> @staff_id))
        SET @errores += '- Esa persona ya figura con ese rol en el cuerpo técnico de la selección.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE plantel.cuerpo_tecnico_insertar
    @seleccion_id INT,
    @nombre       VARCHAR(100),
    @apellido     VARCHAR(100),
    @rol          VARCHAR(25),
    @staff_id     INT = NULL OUTPUT,
    @persona_id   INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    EXEC plantel.cuerpo_tecnico_validar NULL, @seleccion_id, @nombre, @apellido, @rol, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.cuerpo_tecnico_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        EXEC plantel.persona_insertar 'cuerpo_tecnico', @persona_id OUTPUT;

        INSERT INTO plantel.cuerpo_tecnico (persona_id, seleccion_id, nombre, apellido, rol)
        VALUES (@persona_id, @seleccion_id, LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@apellido)), @rol);

        SET @staff_id = SCOPE_IDENTITY();

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE plantel.cuerpo_tecnico_modificar
    @staff_id     INT,
    @seleccion_id INT,
    @nombre       VARCHAR(100),
    @apellido     VARCHAR(100),
    @rol          VARCHAR(25)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @staff_id IS NULL SET @errores = '- El id del integrante es obligatorio.' + @nl;
    EXEC plantel.cuerpo_tecnico_validar @staff_id, @seleccion_id, @nombre, @apellido, @rol, @errores OUTPUT;

    IF EXISTS (SELECT 1 FROM plantel.cuerpo_tecnico ct
               JOIN evento.tarjeta t ON t.persona_id = ct.persona_id
               WHERE ct.staff_id = @staff_id AND ct.seleccion_id <> @seleccion_id)
        SET @errores += '- No se puede cambiar de selección: tiene tarjetas recibidas con la selección actual.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.cuerpo_tecnico_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE plantel.cuerpo_tecnico
    SET seleccion_id = @seleccion_id,
        nombre = LTRIM(RTRIM(@nombre)),
        apellido = LTRIM(RTRIM(@apellido)),
        rol = @rol
    WHERE staff_id = @staff_id;
END;
GO

CREATE OR ALTER PROCEDURE plantel.cuerpo_tecnico_eliminar
    @staff_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @persona_id INT, @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @persona_id = persona_id FROM plantel.cuerpo_tecnico WHERE staff_id = @staff_id;

    IF @persona_id IS NULL
        SET @errores += '- No existe el integrante de cuerpo técnico con id '
                      + ISNULL(CAST(@staff_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.tarjeta WHERE persona_id = @persona_id)
        SET @errores += '- Tiene tarjetas registradas.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.cuerpo_tecnico_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        DELETE FROM plantel.cuerpo_tecnico WHERE staff_id = @staff_id;
        DELETE FROM plantel.persona WHERE persona_id = @persona_id;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE plantel.jugador_validar
    @jugador_id        INT,                          -- NULL en el alta
    @nombre            VARCHAR(100),
    @apellido          VARCHAR(100),
    @fecha_nacimiento  DATE,
    @posicion_habitual VARCHAR(20),
    @errores           VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10), @hoy DATE = CAST(SYSDATETIME() AS DATE);
    SET @errores = ISNULL(@errores, '');

    IF @jugador_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM plantel.jugador WHERE jugador_id = @jugador_id)
        SET @errores += '- No existe el jugador con id ' + CAST(@jugador_id AS VARCHAR(12)) + '.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre es obligatorio.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@apellido)), '') IS NULL
        SET @errores += '- El apellido es obligatorio.' + @nl;
    IF @fecha_nacimiento IS NULL
        SET @errores += '- La fecha de nacimiento es obligatoria.' + @nl;
    ELSE IF @fecha_nacimiento > DATEADD(YEAR, -15, @hoy) OR @fecha_nacimiento < DATEADD(YEAR, -50, @hoy)
        SET @errores += '- La fecha de nacimiento debe corresponder a una edad de entre 15 y 50 años.' + @nl;
    IF @posicion_habitual IS NULL
       OR @posicion_habitual NOT IN ('arquero', 'defensor', 'mediocampista', 'delantero')
        SET @errores += '- La posición habitual debe ser arquero, defensor, mediocampista o delantero.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.jugador
               WHERE nombre = @nombre AND apellido = @apellido AND fecha_nacimiento = @fecha_nacimiento
                 AND (@jugador_id IS NULL OR jugador_id <> @jugador_id))
        SET @errores += '- Ya existe un jugador con ese nombre, apellido y fecha de nacimiento.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE plantel.jugador_insertar
    @nombre            VARCHAR(100),
    @apellido          VARCHAR(100),
    @fecha_nacimiento  DATE,
    @posicion_habitual VARCHAR(20),
    @club_origen       VARCHAR(120) = NULL,
    @jugador_id        INT = NULL OUTPUT,
    @persona_id        INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    EXEC plantel.jugador_validar NULL, @nombre, @apellido, @fecha_nacimiento, @posicion_habitual, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.jugador_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        EXEC plantel.persona_insertar 'jugador', @persona_id OUTPUT;

        INSERT INTO plantel.jugador (persona_id, nombre, apellido, fecha_nacimiento, club_origen, posicion_habitual)
        VALUES (@persona_id, LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@apellido)), @fecha_nacimiento,
                NULLIF(LTRIM(RTRIM(@club_origen)), ''), @posicion_habitual);

        SET @jugador_id = SCOPE_IDENTITY();

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE plantel.jugador_modificar
    @jugador_id        INT,
    @nombre            VARCHAR(100),
    @apellido          VARCHAR(100),
    @fecha_nacimiento  DATE,
    @posicion_habitual VARCHAR(20),
    @club_origen       VARCHAR(120) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    IF @jugador_id IS NULL SET @errores = '- El id del jugador es obligatorio.' + CHAR(13) + CHAR(10);
    EXEC plantel.jugador_validar @jugador_id, @nombre, @apellido, @fecha_nacimiento, @posicion_habitual,
         @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.jugador_modificar - modificación rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE plantel.jugador
    SET nombre = LTRIM(RTRIM(@nombre)),
        apellido = LTRIM(RTRIM(@apellido)),
        fecha_nacimiento = @fecha_nacimiento,
        club_origen = NULLIF(LTRIM(RTRIM(@club_origen)), ''),
        posicion_habitual = @posicion_habitual
    WHERE jugador_id = @jugador_id;
END;
GO

CREATE OR ALTER PROCEDURE plantel.jugador_eliminar
    @jugador_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @persona_id INT, @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @persona_id = persona_id FROM plantel.jugador WHERE jugador_id = @jugador_id;

    IF @persona_id IS NULL
        SET @errores += '- No existe el jugador con id ' + ISNULL(CAST(@jugador_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.convocatoria WHERE jugador_id = @jugador_id)
        SET @errores += '- Tiene convocatorias registradas (vigentes o históricas).' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.formacion_jugador WHERE jugador_id = @jugador_id)
        SET @errores += '- Integra formaciones de partidos.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.tarjeta WHERE persona_id = @persona_id)
        SET @errores += '- Tiene tarjetas registradas.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.jugador_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        DELETE FROM plantel.jugador WHERE jugador_id = @jugador_id;
        DELETE FROM plantel.persona WHERE persona_id = @persona_id;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Valida el estado final de una fila de convocatoria. Las reglas de dorsal, de pertenencia a
 una única selección y de cupo sólo aplican si la fila queda vigente (fecha_baja NULL). */

CREATE OR ALTER PROCEDURE plantel.convocatoria_validar
    @convocatoria_id INT,                            -- NULL en el alta
    @seleccion_id    INT,
    @jugador_id      INT,
    @dorsal          INT,
    @fecha_alta      DATE,
    @fecha_baja      DATE,
    @motivo_baja     VARCHAR(150),
    @errores         VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10), @cupo_max INT, @ya_vigente BIT = 0;
    SET @errores = ISNULL(@errores, '');

    IF NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id '
                      + ISNULL(CAST(@seleccion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM plantel.jugador WHERE jugador_id = @jugador_id)
        SET @errores += '- No existe el jugador con id ' + ISNULL(CAST(@jugador_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @dorsal IS NULL OR @dorsal NOT BETWEEN 1 AND 99
        SET @errores += '- El dorsal debe estar entre 1 y 99.' + @nl;
    IF @fecha_alta IS NULL
        SET @errores += '- La fecha de alta es obligatoria.' + @nl;
    IF @fecha_baja < @fecha_alta
        SET @errores += '- La fecha de baja no puede ser anterior a la fecha de alta.' + @nl;
    IF @fecha_baja IS NULL AND @motivo_baja IS NOT NULL
        SET @errores += '- No se puede informar motivo de baja sin fecha de baja.' + @nl;
    IF @fecha_baja IS NOT NULL AND NULLIF(LTRIM(RTRIM(@motivo_baja)), '') IS NULL
        SET @errores += '- La baja debe indicar su motivo.' + @nl;

    IF @fecha_baja IS NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM plantel.convocatoria
                   WHERE seleccion_id = @seleccion_id AND dorsal = @dorsal AND fecha_baja IS NULL
                     AND (@convocatoria_id IS NULL OR convocatoria_id <> @convocatoria_id))
            SET @errores += '- El dorsal ' + CAST(@dorsal AS VARCHAR(3))
                          + ' ya está en uso en la convocatoria vigente de la selección.' + @nl;
        IF EXISTS (SELECT 1 FROM plantel.convocatoria
                   WHERE jugador_id = @jugador_id AND fecha_baja IS NULL AND seleccion_id = @seleccion_id
                     AND (@convocatoria_id IS NULL OR convocatoria_id <> @convocatoria_id))
            SET @errores += '- El jugador ya integra la convocatoria vigente de la selección.' + @nl;
        IF EXISTS (SELECT 1 FROM plantel.convocatoria
                   WHERE jugador_id = @jugador_id AND fecha_baja IS NULL AND seleccion_id <> @seleccion_id)
            SET @errores += '- El jugador está convocado por otra selección.' + @nl;

        -- Cupo máximo: sólo si esta operación suma un convocado vigente.
        IF EXISTS (SELECT 1 FROM plantel.convocatoria
                   WHERE convocatoria_id = @convocatoria_id AND fecha_baja IS NULL)
            SET @ya_vigente = 1;
        SELECT @cupo_max = valor FROM torneo.parametro WHERE clave = 'convocatoria_max_jugadores';
        IF @cupo_max IS NULL
            SET @errores += '- Falta configurar el parámetro convocatoria_max_jugadores.' + @nl;
        ELSE IF @ya_vigente = 0
             AND (SELECT COUNT(*) FROM plantel.convocatoria
                  WHERE seleccion_id = @seleccion_id AND fecha_baja IS NULL) >= @cupo_max
            SET @errores += '- La selección ya alcanzó el máximo de ' + CAST(@cupo_max AS VARCHAR(3))
                          + ' convocados vigentes.' + @nl;
    END;
END;
GO

CREATE OR ALTER PROCEDURE plantel.convocatoria_insertar
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

    INSERT INTO plantel.convocatoria (seleccion_id, jugador_id, dorsal, fecha_alta, motivo_alta)
    VALUES (@seleccion_id, @jugador_id, @dorsal, @fecha_alta, NULLIF(LTRIM(RTRIM(@motivo_alta)), ''));

    SET @convocatoria_id = SCOPE_IDENTITY();
END;
GO

/* Selección y jugador no se modifican (definen la convocatoria). Informar @fecha_baja y
 @motivo_baja registra la baja; pasarlos en NULL la deja (o la vuelve a dejar) vigente. */

CREATE OR ALTER PROCEDURE plantel.convocatoria_modificar
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

    UPDATE plantel.convocatoria
    SET dorsal = @dorsal,
        fecha_alta = @fecha_alta,
        motivo_alta = NULLIF(LTRIM(RTRIM(@motivo_alta)), ''),
        fecha_baja = @fecha_baja,
        motivo_baja = @motivo_baja
    WHERE convocatoria_id = @convocatoria_id;
END;
GO

/* Baja física: sólo para corregir errores de carga. La baja "de negocio" (lesión, reemplazo)
 conserva la fila con fecha_baja, vía convocatoria_modificar o plantel.reemplazar_convocado. */

CREATE OR ALTER PROCEDURE plantel.convocatoria_eliminar
    @convocatoria_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM plantel.convocatoria WHERE convocatoria_id = @convocatoria_id)
        SET @errores += '- No existe la convocatoria con id '
                      + ISNULL(CAST(@convocatoria_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.convocatoria c
               JOIN plantel.formacion_jugador fj ON fj.jugador_id = c.jugador_id
               JOIN plantel.vw_formacion vf      ON vf.formacion_id = fj.formacion_id
                                                AND vf.seleccion_id = c.seleccion_id
               WHERE c.convocatoria_id = @convocatoria_id)
        SET @errores += '- El jugador ya integró formaciones de esa selección: corresponde registrar la baja con fecha y motivo.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.convocatoria_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM plantel.convocatoria WHERE convocatoria_id = @convocatoria_id;
END;
GO

-- ==========================================
-- II.4 FORMACIÓN Y JUGADORES DE LA FORMACIÓN
-- ==========================================

CREATE OR ALTER PROCEDURE plantel.formacion_insertar
    @partido_id      INT,
    @condicion       VARCHAR(15),
    @esquema_tactico VARCHAR(15),
    @formacion_id    INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id AND estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF @condicion IS NULL OR @condicion NOT IN ('local', 'visitante')
        SET @errores += '- La condición debe ser local o visitante.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.formacion WHERE partido_id = @partido_id AND condicion = @condicion)
        SET @errores += '- El equipo ' + @condicion + ' ya tiene formación cargada en ese partido.' + @nl;
    -- Esquema: entre 3 y 5 líneas numéricas separadas por guion que suman los 10 jugadores de campo.
    IF @esquema_tactico IS NULL OR LEN(@esquema_tactico) > 9
       OR (SELECT COUNT(*) FROM STRING_SPLIT(@esquema_tactico, '-')) NOT BETWEEN 3 AND 5
       OR EXISTS (SELECT 1 FROM STRING_SPLIT(@esquema_tactico, '-') WHERE value NOT LIKE '[1-9]')
       OR (SELECT SUM(TRY_CAST(value AS INT)) FROM STRING_SPLIT(@esquema_tactico, '-')) <> 10
        SET @errores += '- El esquema táctico debe tener entre 3 y 5 líneas que sumen 10 jugadores (ej: 4-3-3).' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.formacion_insertar - alta rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO plantel.formacion (partido_id, condicion, esquema_tactico)
    VALUES (@partido_id, @condicion, @esquema_tactico);

    SET @formacion_id = SCOPE_IDENTITY();
END;
GO

-- Partido y condición identifican a la formación y no se modifican: sólo cambia el esquema.

CREATE OR ALTER PROCEDURE plantel.formacion_modificar
    @formacion_id    INT,
    @esquema_tactico VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM plantel.formacion WHERE formacion_id = @formacion_id)
        SET @errores += '- No existe la formación con id '
                      + ISNULL(CAST(@formacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.vw_formacion WHERE formacion_id = @formacion_id AND estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF @esquema_tactico IS NULL OR LEN(@esquema_tactico) > 9
       OR (SELECT COUNT(*) FROM STRING_SPLIT(@esquema_tactico, '-')) NOT BETWEEN 3 AND 5
       OR EXISTS (SELECT 1 FROM STRING_SPLIT(@esquema_tactico, '-') WHERE value NOT LIKE '[1-9]')
       OR (SELECT SUM(TRY_CAST(value AS INT)) FROM STRING_SPLIT(@esquema_tactico, '-')) <> 10
        SET @errores += '- El esquema táctico debe tener entre 3 y 5 líneas que sumen 10 jugadores (ej: 4-3-3).' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.formacion_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE plantel.formacion SET esquema_tactico = @esquema_tactico WHERE formacion_id = @formacion_id;
END;
GO

CREATE OR ALTER PROCEDURE plantel.formacion_eliminar
    @formacion_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM plantel.formacion WHERE formacion_id = @formacion_id)
        SET @errores += '- No existe la formación con id '
                      + ISNULL(CAST(@formacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.vw_formacion WHERE formacion_id = @formacion_id AND estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.formacion_jugador WHERE formacion_id = @formacion_id)
        SET @errores += '- Tiene jugadores cargados (titulares o suplentes).' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.formacion_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM plantel.formacion WHERE formacion_id = @formacion_id;
END;
GO

-- Reglas de un jugador dentro de una formación, compartidas por el alta y la modificación.
-- Devuelve en @dorsal el de la convocatoria vigente a la fecha del partido.

CREATE OR ALTER PROCEDURE plantel.formacion_jugador_validar
    @es_alta      BIT,
    @formacion_id INT,
    @jugador_id   INT,
    @posicion     VARCHAR(30),
    @titular      BIT,
    @dorsal       INT OUTPUT,
    @errores      VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10),
            @partido_id INT, @seleccion_id INT, @estado VARCHAR(10), @fecha DATE,
            @max_titulares INT, @max_suplentes INT, @existe BIT = 0;
    SET @errores = ISNULL(@errores, '');
    SET @dorsal = NULL;

    SELECT @partido_id = partido_id, @seleccion_id = seleccion_id, @estado = estado,
           @fecha = CAST(fecha_hora_utc AS DATE)
    FROM plantel.vw_formacion WHERE formacion_id = @formacion_id;

    IF EXISTS (SELECT 1 FROM plantel.formacion_jugador WHERE formacion_id = @formacion_id AND jugador_id = @jugador_id)
        SET @existe = 1;

    IF @partido_id IS NULL
        SET @errores += '- No existe la formación con id '
                      + ISNULL(CAST(@formacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @estado = 'finalizado'
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM plantel.jugador WHERE jugador_id = @jugador_id)
        SET @errores += '- No existe el jugador con id ' + ISNULL(CAST(@jugador_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @es_alta = 1 AND @existe = 1
        SET @errores += '- El jugador ya integra esa formación.' + @nl;
    IF @es_alta = 0 AND @existe = 0 AND @partido_id IS NOT NULL
        SET @errores += '- El jugador no integra esa formación.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@posicion)), '') IS NULL
        SET @errores += '- La posición en cancha es obligatoria.' + @nl;
    IF @titular IS NULL
        SET @errores += '- Debe indicarse si es titular (1) o suplente (0).' + @nl;

    IF @partido_id IS NOT NULL AND EXISTS (SELECT 1 FROM plantel.jugador WHERE jugador_id = @jugador_id)
    BEGIN
        SELECT @dorsal = c.dorsal
        FROM plantel.convocatoria c
        WHERE c.seleccion_id = @seleccion_id AND c.jugador_id = @jugador_id
          AND c.fecha_alta <= @fecha AND (c.fecha_baja IS NULL OR c.fecha_baja > @fecha);

        IF @dorsal IS NULL
            SET @errores += '- El jugador no integra la convocatoria vigente de la selección a la fecha del partido.' + @nl;
        ELSE IF EXISTS (SELECT 1 FROM plantel.formacion_jugador
                        WHERE formacion_id = @formacion_id AND dorsal = @dorsal AND jugador_id <> @jugador_id)
            SET @errores += '- El dorsal ' + CAST(@dorsal AS VARCHAR(3)) + ' ya está usado en esa formación.' + @nl;

        IF EXISTS (SELECT 1 FROM evento.suspension s
                   JOIN evento.tarjeta t  ON t.tarjeta_id = s.tarjeta_id
                   JOIN plantel.jugador j ON j.persona_id = t.persona_id
                   WHERE s.partido_afectado_id = @partido_id AND j.jugador_id = @jugador_id)
            SET @errores += '- El jugador está suspendido para este partido.' + @nl;

        SELECT @max_titulares = valor FROM torneo.parametro WHERE clave = 'formacion_titulares';
        SELECT @max_suplentes = valor FROM torneo.parametro WHERE clave = 'formacion_max_suplentes';
        IF @max_titulares IS NULL OR @max_suplentes IS NULL
            SET @errores += '- Faltan configurar los parámetros formacion_titulares / formacion_max_suplentes.' + @nl;
        ELSE IF @titular = 1
             AND (SELECT COUNT(*) FROM plantel.formacion_jugador
                  WHERE formacion_id = @formacion_id AND titular = 1 AND jugador_id <> @jugador_id) >= @max_titulares
            SET @errores += '- La formación ya tiene sus ' + CAST(@max_titulares AS VARCHAR(3)) + ' titulares.' + @nl;
        ELSE IF @titular = 0
             AND (SELECT COUNT(*) FROM plantel.formacion_jugador
                  WHERE formacion_id = @formacion_id AND titular = 0 AND jugador_id <> @jugador_id) >= @max_suplentes
            SET @errores += '- El banco ya tiene el máximo de ' + CAST(@max_suplentes AS VARCHAR(3)) + ' suplentes.' + @nl;
    END;
END;
GO

CREATE OR ALTER PROCEDURE plantel.formacion_jugador_insertar
    @formacion_id INT,
    @jugador_id   INT,
    @posicion     VARCHAR(30),
    @titular      BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @dorsal INT;

    EXEC plantel.formacion_jugador_validar 1, @formacion_id, @jugador_id, @posicion, @titular,
         @dorsal OUTPUT, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.formacion_jugador_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO plantel.formacion_jugador (formacion_id, jugador_id, dorsal, posicion, titular)
    VALUES (@formacion_id, @jugador_id, @dorsal, LTRIM(RTRIM(@posicion)), @titular);
END;
GO

CREATE OR ALTER PROCEDURE plantel.formacion_jugador_modificar
    @formacion_id INT,
    @jugador_id   INT,
    @posicion     VARCHAR(30),
    @titular      BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @dorsal INT;

    EXEC plantel.formacion_jugador_validar 0, @formacion_id, @jugador_id, @posicion, @titular,
         @dorsal OUTPUT, @errores OUTPUT;

    IF EXISTS (SELECT 1 FROM plantel.formacion_jugador
               WHERE formacion_id = @formacion_id AND jugador_id = @jugador_id AND titular <> @titular)
       AND EXISTS (SELECT 1 FROM evento.sustitucion
                   WHERE formacion_id = @formacion_id AND @jugador_id IN (jugador_sale_id, jugador_entra_id))
        SET @errores += '- No se puede cambiar la condición de titular/suplente: el jugador participa de sustituciones.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.formacion_jugador_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE plantel.formacion_jugador
    SET posicion = LTRIM(RTRIM(@posicion)), titular = @titular, dorsal = @dorsal
    WHERE formacion_id = @formacion_id AND jugador_id = @jugador_id;
END;
GO

CREATE OR ALTER PROCEDURE plantel.formacion_jugador_eliminar
    @formacion_id INT,
    @jugador_id   INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM plantel.formacion_jugador
                   WHERE formacion_id = @formacion_id AND jugador_id = @jugador_id)
        SET @errores += '- El jugador no integra esa formación.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.vw_formacion WHERE formacion_id = @formacion_id AND estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.sustitucion
               WHERE formacion_id = @formacion_id AND @jugador_id IN (jugador_sale_id, jugador_entra_id))
        SET @errores += '- Participa de sustituciones del partido.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.gol
               WHERE formacion_id = @formacion_id AND @jugador_id IN (jugador_id, asistencia_jugador_id))
        SET @errores += '- Tiene goles o asistencias registrados en el partido.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.tarjeta t
               JOIN plantel.jugador j      ON j.persona_id = t.persona_id
               JOIN plantel.vw_formacion vf ON vf.partido_id = t.partido_id
               WHERE vf.formacion_id = @formacion_id AND j.jugador_id = @jugador_id)
        SET @errores += '- Tiene tarjetas registradas en el partido.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.formacion_jugador_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM plantel.formacion_jugador WHERE formacion_id = @formacion_id AND jugador_id = @jugador_id;
END;
GO

-- ==================
-- II.5 SUSTITUCIONES
-- ==================

/* Concentra el reglamento de cambios, así no hay forma de registrar una sustitución que lo
 viole. En la modificación (@sustitucion_id informado) los jugadores no cambian, por lo que
 las reglas de "quién está en cancha" sólo se evalúan en el alta. */

CREATE OR ALTER PROCEDURE evento.sustitucion_validar
    @sustitucion_id   INT,                           -- NULL en el alta
    @formacion_id     INT,
    @jugador_sale_id  INT,
    @jugador_entra_id INT,
    @minuto           INT,
    @periodo          VARCHAR(15),
    @numero_ventana   INT,
    @motivo           VARCHAR(15),
    @errores          VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10),
            @partido_id INT, @estado VARCHAR(10), @fase VARCHAR(13),
            @max_cambios INT, @max_ventanas INT, @extra_cambios INT, @extra_ventanas INT,
            @cambios_reglamentarios INT, @cambios_totales INT, @ultima_ventana INT;
    SET @errores = ISNULL(@errores, '');

    SELECT @partido_id = partido_id, @estado = estado, @fase = fase
    FROM plantel.vw_formacion WHERE formacion_id = @formacion_id;

    IF @partido_id IS NULL
        SET @errores += '- No existe la formación con id '
                      + ISNULL(CAST(@formacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @estado = 'finalizado'
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF @fase = 'grupos' AND @periodo IN ('alargue_1', 'alargue_2')
        SET @errores += '- En fase de grupos no hay tiempo suplementario.' + @nl;
    IF @motivo IS NULL OR @motivo NOT IN ('tactico', 'lesion', 'precaucion')
        SET @errores += '- El motivo debe ser tactico, lesion o precaucion.' + @nl;
    IF @periodo IS NULL OR @periodo NOT IN ('PT', 'ST', 'alargue_1', 'alargue_2')
        SET @errores += '- El período debe ser PT, ST, alargue_1 o alargue_2.' + @nl;
    ELSE IF @minuto IS NULL
         OR NOT EXISTS (SELECT 1
                        FROM (VALUES ('PT', 1, 60), ('ST', 45, 110), ('alargue_1', 90, 115), ('alargue_2', 105, 135))
                             AS r (periodo, desde, hasta)
                        WHERE r.periodo = @periodo AND @minuto BETWEEN r.desde AND r.hasta)
        SET @errores += '- El minuto ' + ISNULL(CAST(@minuto AS VARCHAR(5)), '(nulo)')
                      + ' no corresponde al período ' + @periodo + '.' + @nl;
    IF @numero_ventana IS NULL OR @numero_ventana <= 0
        SET @errores += '- El número de ventana debe ser mayor a cero.' + @nl;

    -- Jugadores (sólo en el alta).
    IF @sustitucion_id IS NULL AND @partido_id IS NOT NULL
    BEGIN
        IF @jugador_sale_id = @jugador_entra_id
            SET @errores += '- El jugador que sale y el que entra deben ser distintos.' + @nl;

        IF NOT EXISTS (SELECT 1 FROM plantel.formacion_jugador
                       WHERE formacion_id = @formacion_id AND jugador_id = @jugador_sale_id)
            SET @errores += '- El jugador que sale no integra la formación.' + @nl;
        ELSE
        BEGIN
            -- En cancha = (titular o ya ingresó) y todavía no salió.
            IF EXISTS (SELECT 1 FROM evento.sustitucion
                       WHERE formacion_id = @formacion_id AND jugador_sale_id = @jugador_sale_id)
               OR NOT (EXISTS (SELECT 1 FROM plantel.formacion_jugador
                               WHERE formacion_id = @formacion_id AND jugador_id = @jugador_sale_id AND titular = 1)
                    OR EXISTS (SELECT 1 FROM evento.sustitucion
                               WHERE formacion_id = @formacion_id AND jugador_entra_id = @jugador_sale_id))
                SET @errores += '- El jugador que sale no está en cancha.' + @nl;
            IF EXISTS (SELECT 1 FROM evento.tarjeta t
                       JOIN plantel.jugador j ON j.persona_id = t.persona_id
                       WHERE t.partido_id = @partido_id AND t.tipo = 'roja' AND j.jugador_id = @jugador_sale_id)
                SET @errores += '- El jugador que sale fue expulsado: no puede ser reemplazado.' + @nl;
        END;

        IF NOT EXISTS (SELECT 1 FROM plantel.formacion_jugador
                       WHERE formacion_id = @formacion_id AND jugador_id = @jugador_entra_id)
            SET @errores += '- El jugador que entra no integra la formación.' + @nl;
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM plantel.formacion_jugador
                       WHERE formacion_id = @formacion_id AND jugador_id = @jugador_entra_id AND titular = 1)
               OR EXISTS (SELECT 1 FROM evento.sustitucion
                          WHERE formacion_id = @formacion_id
                            AND @jugador_entra_id IN (jugador_entra_id, jugador_sale_id))
                SET @errores += '- El jugador que entra no está disponible en el banco (es titular o ya participó).' + @nl;
            IF EXISTS (SELECT 1 FROM evento.tarjeta t
                       JOIN plantel.jugador j ON j.persona_id = t.persona_id
                       WHERE t.partido_id = @partido_id AND t.tipo = 'roja' AND j.jugador_id = @jugador_entra_id)
                SET @errores += '- El jugador que entra fue expulsado estando en el banco.' + @nl;
        END;
    END;

    -- Máximo de cambios y de ventanas (parametrizable), con el adicional del alargue.
    SELECT @max_cambios    = valor FROM torneo.parametro WHERE clave = 'cambios_max_reglamentarios';
    SELECT @max_ventanas   = valor FROM torneo.parametro WHERE clave = 'ventanas_max_reglamentarias';
    SELECT @extra_cambios  = valor FROM torneo.parametro WHERE clave = 'cambios_extra_alargue';
    SELECT @extra_ventanas = valor FROM torneo.parametro WHERE clave = 'ventanas_extra_alargue';

    IF @max_cambios IS NULL OR @max_ventanas IS NULL OR @extra_cambios IS NULL OR @extra_ventanas IS NULL
        SET @errores += '- Faltan configurar los parámetros de cambios y ventanas.' + @nl;
    ELSE IF @partido_id IS NOT NULL AND @periodo IN ('PT', 'ST', 'alargue_1', 'alargue_2')
    BEGIN
        SELECT @cambios_totales        = COUNT(*),
               @cambios_reglamentarios = ISNULL(SUM(CASE WHEN periodo IN ('PT', 'ST') THEN 1 ELSE 0 END), 0),
               @ultima_ventana         = ISNULL(MAX(numero_ventana), 0)
        FROM evento.sustitucion
        WHERE formacion_id = @formacion_id AND (@sustitucion_id IS NULL OR sustitucion_id <> @sustitucion_id);

        IF @periodo IN ('PT', 'ST') AND @cambios_reglamentarios + 1 > @max_cambios
            SET @errores += '- Se alcanzó el máximo de ' + CAST(@max_cambios AS VARCHAR(3))
                          + ' cambios en tiempo reglamentario.' + @nl;
        IF @periodo IN ('alargue_1', 'alargue_2') AND @cambios_totales + 1 > @max_cambios + @extra_cambios
            SET @errores += '- Se alcanzó el máximo de ' + CAST(@max_cambios + @extra_cambios AS VARCHAR(3))
                          + ' cambios incluyendo el adicional del alargue.' + @nl;
        IF @periodo IN ('PT', 'ST') AND @numero_ventana > @max_ventanas
            SET @errores += '- Se superan las ' + CAST(@max_ventanas AS VARCHAR(3))
                          + ' ventanas de cambio del tiempo reglamentario.' + @nl;
        IF @periodo IN ('alargue_1', 'alargue_2') AND @numero_ventana > @max_ventanas + @extra_ventanas
            SET @errores += '- Se superan las ' + CAST(@max_ventanas + @extra_ventanas AS VARCHAR(3))
                          + ' ventanas de cambio incluyendo la adicional del alargue.' + @nl;
        IF @sustitucion_id IS NULL
           AND (@numero_ventana < @ultima_ventana OR @numero_ventana > @ultima_ventana + 1)
            SET @errores += '- Las ventanas se numeran en orden: corresponde la '
                          + CAST(IIF(@ultima_ventana = 0, 1, @ultima_ventana) AS VARCHAR(3)) + ' o la '
                          + CAST(@ultima_ventana + 1 AS VARCHAR(3)) + '.' + @nl;
        IF EXISTS (SELECT 1 FROM evento.sustitucion
                   WHERE formacion_id = @formacion_id AND numero_ventana = @numero_ventana AND periodo <> @periodo
                     AND (@sustitucion_id IS NULL OR sustitucion_id <> @sustitucion_id))
            SET @errores += '- Esa ventana ya se usó en otro período del partido.' + @nl;
    END;
END;
GO

CREATE OR ALTER PROCEDURE evento.sustitucion_insertar
    @formacion_id     INT,
    @jugador_sale_id  INT,
    @jugador_entra_id INT,
    @minuto           INT,
    @periodo          VARCHAR(15),
    @numero_ventana   INT,
    @motivo           VARCHAR(15),
    @sustitucion_id   INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC evento.sustitucion_validar NULL, @formacion_id, @jugador_sale_id, @jugador_entra_id, @minuto,
         @periodo, @numero_ventana, @motivo, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.sustitucion_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO evento.sustitucion
        (formacion_id, jugador_sale_id, jugador_entra_id, minuto, periodo, numero_ventana, motivo)
    VALUES
        (@formacion_id, @jugador_sale_id, @jugador_entra_id, @minuto, @periodo, @numero_ventana, @motivo);

    SET @sustitucion_id = SCOPE_IDENTITY();
END;
GO

-- Corrige los datos del cambio; para cambiar los jugadores hay que eliminarlo y recargarlo.

CREATE OR ALTER PROCEDURE evento.sustitucion_modificar
    @sustitucion_id INT,
    @minuto         INT,
    @periodo        VARCHAR(15),
    @numero_ventana INT,
    @motivo         VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @formacion_id INT, @sale INT, @entra INT;

    SELECT @formacion_id = formacion_id, @sale = jugador_sale_id, @entra = jugador_entra_id
    FROM evento.sustitucion WHERE sustitucion_id = @sustitucion_id;

    IF @formacion_id IS NULL
        SET @errores = '- No existe la sustitución con id '
                     + ISNULL(CAST(@sustitucion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE
        EXEC evento.sustitucion_validar @sustitucion_id, @formacion_id, @sale, @entra, @minuto, @periodo,
             @numero_ventana, @motivo, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.sustitucion_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE evento.sustitucion
    SET minuto = @minuto, periodo = @periodo, numero_ventana = @numero_ventana, motivo = @motivo
    WHERE sustitucion_id = @sustitucion_id;
END;
GO

CREATE OR ALTER PROCEDURE evento.sustitucion_eliminar
    @sustitucion_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @formacion_id INT, @entra INT;

    SELECT @formacion_id = formacion_id, @entra = jugador_entra_id
    FROM evento.sustitucion WHERE sustitucion_id = @sustitucion_id;

    IF @formacion_id IS NULL
        SET @errores += '- No existe la sustitución con id '
                      + ISNULL(CAST(@sustitucion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.vw_formacion WHERE formacion_id = @formacion_id AND estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.sustitucion WHERE formacion_id = @formacion_id AND jugador_sale_id = @entra)
        SET @errores += '- El jugador que ingresó fue reemplazado después: eliminar primero ese cambio.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.gol
               WHERE formacion_id = @formacion_id AND @entra IN (jugador_id, asistencia_jugador_id))
        SET @errores += '- El jugador que ingresó tiene goles o asistencias en el partido.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.sustitucion_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM evento.sustitucion WHERE sustitucion_id = @sustitucion_id;
END;
GO

-- ==========
-- II.6 GOLES
-- ==========

/* partido.goles_* y penales_* son un resumen del detalle de evento.gol (desnormalización
 controlada, para no recalcular el resultado en cada consulta del fixture). Este SP interno
 es el único que lo recalcula, y los SP de gol lo invocan dentro de su misma transacción.
 El gol en contra suma al rival; los de la tanda de penales van aparte en penales_*. */

CREATE OR ALTER PROCEDURE torneo.partido_actualizar_marcador
    @partido_id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET goles_local       = m.goles_local,
        goles_visitante   = m.goles_visitante,
        penales_local     = IIF(m.penales_local + m.penales_visitante = 0, NULL, m.penales_local),
        penales_visitante = IIF(m.penales_local + m.penales_visitante = 0, NULL, m.penales_visitante)
    FROM torneo.partido p
    CROSS APPLY (
        SELECT ISNULL(SUM(CASE WHEN g.periodo <> 'penales'
                                AND ((f.condicion = 'local'     AND g.tipo_gol <> 'en_contra')
                                  OR (f.condicion = 'visitante' AND g.tipo_gol =  'en_contra')) THEN 1 ELSE 0 END), 0),
               ISNULL(SUM(CASE WHEN g.periodo <> 'penales'
                                AND ((f.condicion = 'visitante' AND g.tipo_gol <> 'en_contra')
                                  OR (f.condicion = 'local'     AND g.tipo_gol =  'en_contra')) THEN 1 ELSE 0 END), 0),
               ISNULL(SUM(CASE WHEN g.periodo = 'penales' AND f.condicion = 'local'     THEN 1 ELSE 0 END), 0),
               ISNULL(SUM(CASE WHEN g.periodo = 'penales' AND f.condicion = 'visitante' THEN 1 ELSE 0 END), 0)
        FROM plantel.formacion f
        JOIN evento.gol g ON g.formacion_id = f.formacion_id
        WHERE f.partido_id = p.partido_id
    ) AS m (goles_local, goles_visitante, penales_local, penales_visitante)
    WHERE p.partido_id = @partido_id;
END;
GO

CREATE OR ALTER PROCEDURE evento.gol_validar
    @gol_id                INT,                      -- NULL en el alta
    @formacion_id          INT,
    @jugador_id            INT,
    @asistencia_jugador_id INT,
    @minuto                INT,
    @tipo_gol              VARCHAR(15),
    @periodo               VARCHAR(20),
    @errores               VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10), @partido_id INT, @estado VARCHAR(10), @fase VARCHAR(13);
    SET @errores = ISNULL(@errores, '');

    SELECT @partido_id = partido_id, @estado = estado, @fase = fase
    FROM plantel.vw_formacion WHERE formacion_id = @formacion_id;

    IF @fase = 'grupos' AND @periodo IN ('alargue_1', 'alargue_2', 'adicional_alargue', 'penales')
        SET @errores += '- En fase de grupos no hay tiempo suplementario ni definición por penales.' + @nl;
    IF @gol_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM evento.gol WHERE gol_id = @gol_id)
        SET @errores += '- No existe el gol con id ' + CAST(@gol_id AS VARCHAR(12)) + '.' + @nl;
    ELSE IF @partido_id IS NULL
        SET @errores += '- No existe la formación con id '
                      + ISNULL(CAST(@formacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @estado = 'finalizado'
        SET @errores += '- El partido ya está finalizado.' + @nl;

    IF @tipo_gol IS NULL OR @tipo_gol NOT IN ('jugada', 'penal', 'tiro_libre', 'en_contra', 'cabezazo', 'otro')
        SET @errores += '- El tipo de gol debe ser jugada, penal, tiro_libre, en_contra, cabezazo u otro.' + @nl;
    IF @periodo IS NULL OR @periodo NOT IN ('PT', 'ST', 'adicional_PT', 'adicional_ST',
                                             'alargue_1', 'alargue_2', 'adicional_alargue', 'penales')
        SET @errores += '- El período debe ser PT, adicional_PT, ST, adicional_ST, alargue_1, alargue_2, adicional_alargue o penales.' + @nl;
    ELSE IF @minuto IS NULL
         OR NOT EXISTS (SELECT 1
                        FROM (VALUES ('PT', 1, 45), ('adicional_PT', 46, 60), ('ST', 46, 90),
                                     ('adicional_ST', 91, 110), ('alargue_1', 91, 105), ('alargue_2', 106, 120),
                                     ('adicional_alargue', 106, 135), ('penales', 120, 135))
                             AS r (periodo, desde, hasta)
                        WHERE r.periodo = @periodo AND @minuto BETWEEN r.desde AND r.hasta)
        SET @errores += '- El minuto ' + ISNULL(CAST(@minuto AS VARCHAR(5)), '(nulo)')
                      + ' no corresponde al período ' + @periodo + '.' + @nl;

    IF @partido_id IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM plantel.formacion_jugador
                       WHERE formacion_id = @formacion_id AND jugador_id = @jugador_id)
            SET @errores += '- El autor del gol no integra la formación.' + @nl;
        ELSE IF NOT EXISTS (SELECT 1 FROM plantel.formacion_jugador
                            WHERE formacion_id = @formacion_id AND jugador_id = @jugador_id AND titular = 1)
             AND NOT EXISTS (SELECT 1 FROM evento.sustitucion
                             WHERE formacion_id = @formacion_id AND jugador_entra_id = @jugador_id)
            SET @errores += '- El autor del gol no ingresó al campo (es suplente sin sustitución registrada).' + @nl;

        IF @asistencia_jugador_id IS NOT NULL
        BEGIN
            IF @asistencia_jugador_id = @jugador_id
                SET @errores += '- El asistente no puede ser el mismo autor del gol.' + @nl;
            IF NOT EXISTS (SELECT 1 FROM plantel.formacion_jugador
                           WHERE formacion_id = @formacion_id AND jugador_id = @asistencia_jugador_id)
                SET @errores += '- El asistente no integra la formación del autor.' + @nl;
            ELSE IF NOT EXISTS (SELECT 1 FROM plantel.formacion_jugador
                                WHERE formacion_id = @formacion_id AND jugador_id = @asistencia_jugador_id
                                  AND titular = 1)
                 AND NOT EXISTS (SELECT 1 FROM evento.sustitucion
                                 WHERE formacion_id = @formacion_id AND jugador_entra_id = @asistencia_jugador_id)
                SET @errores += '- El asistente no ingresó al campo.' + @nl;
            IF @tipo_gol = 'en_contra'
                SET @errores += '- Un gol en contra no lleva asistencia.' + @nl;
            IF @periodo = 'penales'
                SET @errores += '- Un gol de la tanda de penales no lleva asistencia.' + @nl;
        END;
    END;

    IF @periodo = 'penales' AND @tipo_gol <> 'penal'
        SET @errores += '- En la tanda de penales el tipo de gol debe ser penal.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE evento.gol_insertar
    @formacion_id          INT,
    @jugador_id            INT,
    @minuto                INT,
    @tipo_gol              VARCHAR(15),
    @periodo               VARCHAR(20),
    @asistencia_jugador_id INT = NULL,
    @gol_id                INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @partido_id INT, @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    EXEC evento.gol_validar NULL, @formacion_id, @jugador_id, @asistencia_jugador_id, @minuto, @tipo_gol,
         @periodo, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.gol_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    SELECT @partido_id = partido_id FROM plantel.formacion WHERE formacion_id = @formacion_id;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        INSERT INTO evento.gol (formacion_id, jugador_id, asistencia_jugador_id, minuto, tipo_gol, periodo)
        VALUES (@formacion_id, @jugador_id, @asistencia_jugador_id, @minuto, @tipo_gol, @periodo);

        SET @gol_id = SCOPE_IDENTITY();

        EXEC torneo.partido_actualizar_marcador @partido_id;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- Corrige los datos del gol; el autor y su formación no se modifican (eliminar y recargar).

CREATE OR ALTER PROCEDURE evento.gol_modificar
    @gol_id                INT,
    @minuto                INT,
    @tipo_gol              VARCHAR(15),
    @periodo               VARCHAR(20),
    @asistencia_jugador_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @formacion_id INT, @jugador_id INT, @partido_id INT,
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @formacion_id = g.formacion_id, @jugador_id = g.jugador_id, @partido_id = f.partido_id
    FROM evento.gol g
    JOIN plantel.formacion f ON f.formacion_id = g.formacion_id
    WHERE g.gol_id = @gol_id;

    IF @formacion_id IS NULL
        SET @errores = '- No existe el gol con id ' + ISNULL(CAST(@gol_id AS VARCHAR(12)), '(nulo)') + '.'
                     + CHAR(13) + CHAR(10);
    ELSE
        EXEC evento.gol_validar @gol_id, @formacion_id, @jugador_id, @asistencia_jugador_id, @minuto,
             @tipo_gol, @periodo, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.gol_modificar - modificación rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        UPDATE evento.gol
        SET asistencia_jugador_id = @asistencia_jugador_id, minuto = @minuto,
            tipo_gol = @tipo_gol, periodo = @periodo
        WHERE gol_id = @gol_id;

        EXEC torneo.partido_actualizar_marcador @partido_id;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE evento.gol_eliminar
    @gol_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @partido_id INT,
            @estado VARCHAR(10), @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @partido_id = vf.partido_id, @estado = vf.estado
    FROM evento.gol g
    JOIN plantel.vw_formacion vf ON vf.formacion_id = g.formacion_id
    WHERE g.gol_id = @gol_id;

    IF @partido_id IS NULL
        SET @errores += '- No existe el gol con id ' + ISNULL(CAST(@gol_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @estado = 'finalizado'
        SET @errores += '- El partido ya está finalizado.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.gol_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        DELETE FROM evento.gol WHERE gol_id = @gol_id;
        EXEC torneo.partido_actualizar_marcador @partido_id;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =====================================================
-- II.7 TARJETAS, CRITERIOS DE SUSPENSIÓN Y SUSPENSIONES
-- =====================================================

/* Convención de carga: la primera amarilla de una persona en un partido es una fila
 'amarilla'; la segunda se registra como una única fila 'roja' / 'doble_amarilla'.
 En la modificación (@tarjeta_id informado) sólo se revalidan minuto y período. */

CREATE OR ALTER PROCEDURE evento.tarjeta_validar
    @tarjeta_id     INT,                             -- NULL en el alta
    @partido_id     INT,
    @persona_id     INT,
    @minuto         INT,
    @periodo        VARCHAR(25),
    @tipo           VARCHAR(10),
    @tipo_expulsion VARCHAR(20),
    @errores        VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10), @amarillas_previas INT;
    SET @errores = ISNULL(@errores, '');

    IF NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id AND estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF @periodo IN ('alargue_1', 'adicional_alargue_1', 'alargue_2', 'adicional_alargue_2', 'penales')
       AND EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id AND fase = 'grupos')
        SET @errores += '- En fase de grupos no hay tiempo suplementario ni definición por penales.' + @nl;

    IF @periodo IS NULL OR @periodo NOT IN ('PT', 'adicional_PT', 'ST', 'adicional_ST', 'alargue_1',
                                             'adicional_alargue_1', 'alargue_2', 'adicional_alargue_2', 'penales')
        SET @errores += '- El período no es válido (PT, adicional_PT, ST, adicional_ST, alargue_1, adicional_alargue_1, alargue_2, adicional_alargue_2 o penales).' + @nl;
    ELSE IF @minuto IS NULL
         OR NOT EXISTS (SELECT 1
                        FROM (VALUES ('PT', 1, 45), ('adicional_PT', 46, 60), ('ST', 46, 90),
                                     ('adicional_ST', 91, 110), ('alargue_1', 91, 105),
                                     ('adicional_alargue_1', 106, 115), ('alargue_2', 106, 120),
                                     ('adicional_alargue_2', 121, 135), ('penales', 120, 135))
                             AS r (periodo, desde, hasta)
                        WHERE r.periodo = @periodo AND @minuto BETWEEN r.desde AND r.hasta)
        SET @errores += '- El minuto ' + ISNULL(CAST(@minuto AS VARCHAR(5)), '(nulo)')
                      + ' no corresponde al período ' + @periodo + '.' + @nl;

    IF @tarjeta_id IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM plantel.persona WHERE persona_id = @persona_id)
            SET @errores += '- No existe la persona con id '
                          + ISNULL(CAST(@persona_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
        ELSE IF NOT EXISTS (SELECT 1 FROM plantel.vw_persona_partido
                            WHERE partido_id = @partido_id AND persona_id = @persona_id)
            SET @errores += '- La persona no participa del partido (no integra una formación ni el cuerpo técnico de las selecciones).' + @nl;

        IF @tipo IS NULL OR @tipo NOT IN ('amarilla', 'roja')
            SET @errores += '- El tipo de tarjeta debe ser amarilla o roja.' + @nl;
        IF @tipo = 'amarilla' AND @tipo_expulsion IS NOT NULL
            SET @errores += '- Una tarjeta amarilla no lleva tipo de expulsión.' + @nl;
        IF @tipo = 'roja' AND (@tipo_expulsion IS NULL OR @tipo_expulsion NOT IN ('doble_amarilla', 'roja_directa'))
            SET @errores += '- Una tarjeta roja debe indicar si es doble_amarilla o roja_directa.' + @nl;

        IF EXISTS (SELECT 1 FROM evento.tarjeta
                   WHERE partido_id = @partido_id AND persona_id = @persona_id AND tipo = 'roja')
            SET @errores += '- La persona ya fue expulsada en este partido.' + @nl;

        SELECT @amarillas_previas = COUNT(*) FROM evento.tarjeta
        WHERE partido_id = @partido_id AND persona_id = @persona_id AND tipo = 'amarilla';

        IF @tipo = 'amarilla' AND @amarillas_previas >= 1
            SET @errores += '- La persona ya tiene una amarilla en este partido: la segunda se registra como roja por doble_amarilla.' + @nl;
        IF @tipo = 'roja' AND @tipo_expulsion = 'doble_amarilla' AND @amarillas_previas <> 1
            SET @errores += '- La expulsión por doble amarilla requiere una amarilla previa en el mismo partido.' + @nl;
    END;
END;
GO

CREATE OR ALTER PROCEDURE evento.tarjeta_insertar
    @partido_id     INT,
    @persona_id     INT,
    @minuto         INT,
    @periodo        VARCHAR(25),
    @tipo           VARCHAR(10),
    @motivo         VARCHAR(150) = NULL,
    @tipo_expulsion VARCHAR(20) = NULL,
    @tarjeta_id     INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC evento.tarjeta_validar NULL, @partido_id, @persona_id, @minuto, @periodo, @tipo, @tipo_expulsion,
         @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.tarjeta_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO evento.tarjeta (partido_id, persona_id, minuto, periodo, tipo, motivo, tipo_expulsion)
    VALUES (@partido_id, @persona_id, @minuto, @periodo, @tipo, NULLIF(LTRIM(RTRIM(@motivo)), ''), @tipo_expulsion);

    SET @tarjeta_id = SCOPE_IDENTITY();
END;
GO

-- Partido, persona y tipo no se modifican (de ellos dependen las suspensiones ya calculadas).

CREATE OR ALTER PROCEDURE evento.tarjeta_modificar
    @tarjeta_id INT,
    @minuto     INT,
    @periodo    VARCHAR(25),
    @motivo     VARCHAR(150) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @partido_id INT;

    SELECT @partido_id = partido_id FROM evento.tarjeta WHERE tarjeta_id = @tarjeta_id;

    IF @partido_id IS NULL
        SET @errores = '- No existe la tarjeta con id ' + ISNULL(CAST(@tarjeta_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE
        EXEC evento.tarjeta_validar @tarjeta_id, @partido_id, NULL, @minuto, @periodo, NULL, NULL, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.tarjeta_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE evento.tarjeta
    SET minuto = @minuto, periodo = @periodo, motivo = NULLIF(LTRIM(RTRIM(@motivo)), '')
    WHERE tarjeta_id = @tarjeta_id;
END;
GO

CREATE OR ALTER PROCEDURE evento.tarjeta_eliminar
    @tarjeta_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM evento.tarjeta WHERE tarjeta_id = @tarjeta_id)
        SET @errores += '- No existe la tarjeta con id ' + ISNULL(CAST(@tarjeta_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.tarjeta t
               JOIN torneo.partido p ON p.partido_id = t.partido_id
               WHERE t.tarjeta_id = @tarjeta_id AND p.estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.suspension WHERE tarjeta_id = @tarjeta_id)
        SET @errores += '- Originó suspensiones: eliminarlas primero.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.tarjeta a
               JOIN evento.tarjeta r ON r.partido_id = a.partido_id AND r.persona_id = a.persona_id
               WHERE a.tarjeta_id = @tarjeta_id AND a.tipo = 'amarilla' AND r.tipo_expulsion = 'doble_amarilla')
        SET @errores += '- Es la primera amarilla de una expulsión por doble amarilla: eliminar primero la roja.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.tarjeta_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM evento.tarjeta WHERE tarjeta_id = @tarjeta_id;
END;
GO

CREATE OR ALTER PROCEDURE evento.criterio_suspension_validar
    @criterio_id            INT,                     -- NULL en el alta
    @fase_aplicable         VARCHAR(20),
    @tipo_persona_aplicable VARCHAR(20),
    @cantidad_amarillas     INT,
    @partidos_suspension    INT,
    @errores                VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF @criterio_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM evento.criterio_suspension WHERE criterio_id = @criterio_id)
        SET @errores += '- No existe el criterio con id ' + CAST(@criterio_id AS VARCHAR(12)) + '.' + @nl;
    IF @fase_aplicable IS NOT NULL AND @fase_aplicable NOT IN
       ('grupos', 'dieciseisavos', 'octavos', 'cuartos', 'semifinal', 'tercer_puesto', 'final')
        SET @errores += '- La fase aplicable no es válida (NULL = todas las fases).' + @nl;
    IF @tipo_persona_aplicable IS NOT NULL AND @tipo_persona_aplicable NOT IN ('jugador', 'cuerpo_tecnico')
        SET @errores += '- El tipo de persona aplicable debe ser jugador o cuerpo_tecnico (NULL = ambos).' + @nl;
    IF @cantidad_amarillas IS NULL OR @cantidad_amarillas <= 0
        SET @errores += '- La cantidad de amarillas debe ser mayor a cero.' + @nl;
    IF @partidos_suspension IS NULL OR @partidos_suspension <= 0
        SET @errores += '- Los partidos de suspensión deben ser mayores a cero.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.criterio_suspension
               WHERE ISNULL(fase_aplicable, '') = ISNULL(@fase_aplicable, '')
                 AND ISNULL(tipo_persona_aplicable, '') = ISNULL(@tipo_persona_aplicable, '')
                 AND cantidad_amarillas = @cantidad_amarillas
                 AND (@criterio_id IS NULL OR criterio_id <> @criterio_id))
        SET @errores += '- Ya existe un criterio para esa fase, tipo de persona y cantidad de amarillas.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE evento.criterio_suspension_insertar
    @cantidad_amarillas     INT,
    @partidos_suspension    INT,
    @fase_aplicable         VARCHAR(20) = NULL,
    @tipo_persona_aplicable VARCHAR(20) = NULL,
    @activo                 BIT = 1,
    @criterio_id            INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC evento.criterio_suspension_validar NULL, @fase_aplicable, @tipo_persona_aplicable,
         @cantidad_amarillas, @partidos_suspension, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.criterio_suspension_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO evento.criterio_suspension
        (fase_aplicable, tipo_persona_aplicable, cantidad_amarillas, partidos_suspension, activo)
    VALUES
        (@fase_aplicable, @tipo_persona_aplicable, @cantidad_amarillas, @partidos_suspension, ISNULL(@activo, 1));

    SET @criterio_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE evento.criterio_suspension_modificar
    @criterio_id            INT,
    @cantidad_amarillas     INT,
    @partidos_suspension    INT,
    @fase_aplicable         VARCHAR(20) = NULL,
    @tipo_persona_aplicable VARCHAR(20) = NULL,
    @activo                 BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    IF @criterio_id IS NULL SET @errores = '- El id del criterio es obligatorio.' + CHAR(13) + CHAR(10);
    EXEC evento.criterio_suspension_validar @criterio_id, @fase_aplicable, @tipo_persona_aplicable,
         @cantidad_amarillas, @partidos_suspension, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.criterio_suspension_modificar - modificación rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE evento.criterio_suspension
    SET fase_aplicable = @fase_aplicable,
        tipo_persona_aplicable = @tipo_persona_aplicable,
        cantidad_amarillas = @cantidad_amarillas,
        partidos_suspension = @partidos_suspension,
        activo = ISNULL(@activo, 1)
    WHERE criterio_id = @criterio_id;
END;
GO

CREATE OR ALTER PROCEDURE evento.criterio_suspension_eliminar
    @criterio_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM evento.criterio_suspension WHERE criterio_id = @criterio_id)
        SET @errores += '- No existe el criterio con id '
                      + ISNULL(CAST(@criterio_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.suspension WHERE criterio_id = @criterio_id)
        SET @errores += '- Ya originó suspensiones: desactivarlo (activo = 0) en lugar de eliminarlo.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.criterio_suspension_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM evento.criterio_suspension WHERE criterio_id = @criterio_id;
END;
GO

/* Las suspensiones las genera evento.registrar_tarjeta; este ABM permite la carga manual
 (ej: sanción de oficio) y fijar el partido afectado cuando todavía no estaba programado. */

CREATE OR ALTER PROCEDURE evento.suspension_validar
    @suspension_id       INT,                        -- NULL en el alta
    @criterio_id         INT,
    @tarjeta_id          INT,
    @partido_afectado_id INT,
    @motivo              VARCHAR(150),
    @errores             VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10), @persona_id INT, @partido_origen_id INT,
            @tipo VARCHAR(8), @seleccion_id INT, @fecha_origen DATETIMEOFFSET;
    SET @errores = ISNULL(@errores, '');

    SELECT @persona_id = t.persona_id, @partido_origen_id = t.partido_id, @tipo = t.tipo,
           @fecha_origen = p.fecha_hora_utc
    FROM evento.tarjeta t
    JOIN torneo.partido p ON p.partido_id = t.partido_id
    WHERE t.tarjeta_id = @tarjeta_id;

    SELECT TOP (1) @seleccion_id = seleccion_id
    FROM plantel.vw_persona_partido
    WHERE persona_id = @persona_id AND partido_id = @partido_origen_id;

    IF @persona_id IS NULL
        SET @errores += '- No existe la tarjeta con id ' + ISNULL(CAST(@tarjeta_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @criterio_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM evento.criterio_suspension WHERE criterio_id = @criterio_id)
        SET @errores += '- No existe el criterio con id ' + CAST(@criterio_id AS VARCHAR(12)) + '.' + @nl;
    IF @criterio_id IS NULL AND @tipo = 'amarilla'
        SET @errores += '- Una suspensión originada en una amarilla debe indicar el criterio de acumulación aplicado.' + @nl;
    IF @criterio_id IS NOT NULL AND @tipo = 'roja'
        SET @errores += '- Una suspensión por expulsión no lleva criterio de acumulación.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL
        SET @errores += '- El motivo es obligatorio.' + @nl;

    IF @partido_afectado_id IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_afectado_id)
            SET @errores += '- No existe el partido afectado con id ' + CAST(@partido_afectado_id AS VARCHAR(12)) + '.' + @nl;
        ELSE IF @persona_id IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM torneo.partido
                           WHERE partido_id = @partido_afectado_id
                             AND @seleccion_id IN (seleccion_local_id, seleccion_visitante_id))
                SET @errores += '- La selección de la persona sancionada no juega el partido afectado.' + @nl;
            IF EXISTS (SELECT 1 FROM torneo.partido
                       WHERE partido_id = @partido_afectado_id AND fecha_hora_utc <= @fecha_origen)
                SET @errores += '- El partido afectado debe ser posterior al partido de la tarjeta.' + @nl;
            IF EXISTS (SELECT 1 FROM evento.suspension s
                       JOIN evento.tarjeta t ON t.tarjeta_id = s.tarjeta_id
                       WHERE t.persona_id = @persona_id AND s.partido_afectado_id = @partido_afectado_id
                         AND (@suspension_id IS NULL OR s.suspension_id <> @suspension_id))
                SET @errores += '- La persona ya tiene una suspensión para ese partido.' + @nl;
        END;
    END;
END;
GO

CREATE OR ALTER PROCEDURE evento.suspension_insertar
    @tarjeta_id          INT,
    @motivo              VARCHAR(150),
    @criterio_id         INT = NULL,
    @partido_afectado_id INT = NULL,
    @suspension_id       INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC evento.suspension_validar NULL, @criterio_id, @tarjeta_id, @partido_afectado_id, @motivo, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.suspension_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO evento.suspension (criterio_id, tarjeta_id, partido_afectado_id, motivo)
    VALUES (@criterio_id, @tarjeta_id, @partido_afectado_id, LTRIM(RTRIM(@motivo)));

    SET @suspension_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE evento.suspension_modificar
    @suspension_id       INT,
    @motivo              VARCHAR(150),
    @partido_afectado_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @tarjeta_id INT, @criterio_id INT;

    SELECT @tarjeta_id = tarjeta_id, @criterio_id = criterio_id
    FROM evento.suspension WHERE suspension_id = @suspension_id;

    IF @tarjeta_id IS NULL
        SET @errores = '- No existe la suspensión con id '
                     + ISNULL(CAST(@suspension_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE
        EXEC evento.suspension_validar @suspension_id, @criterio_id, @tarjeta_id, @partido_afectado_id, @motivo,
             @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.suspension_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE evento.suspension
    SET partido_afectado_id = @partido_afectado_id, motivo = LTRIM(RTRIM(@motivo))
    WHERE suspension_id = @suspension_id;
END;
GO

CREATE OR ALTER PROCEDURE evento.suspension_eliminar
    @suspension_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM evento.suspension WHERE suspension_id = @suspension_id)
        SET @errores += '- No existe la suspensión con id '
                      + ISNULL(CAST(@suspension_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM evento.suspension s
               JOIN torneo.partido p ON p.partido_id = s.partido_afectado_id
               WHERE s.suspension_id = @suspension_id AND p.estado = 'finalizado')
        SET @errores += '- La suspensión ya se cumplió (el partido afectado está finalizado).' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.suspension_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM evento.suspension WHERE suspension_id = @suspension_id;
END;
GO

-- ================================================
-- II.8 ÁRBITROS, IDIOMAS, DESIGNACIONES E INFORMES
-- ================================================

CREATE OR ALTER PROCEDURE arbitraje.arbitro_validar
    @arbitro_id       INT,                           -- NULL en el alta
    @nombre           VARCHAR(100),
    @apellido         VARCHAR(100),
    @fecha_nacimiento DATE,
    @pais_id          INT,
    @categoria        VARCHAR(20),
    @errores          VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10), @hoy DATE = CAST(SYSDATETIME() AS DATE);
    SET @errores = ISNULL(@errores, '');

    IF @arbitro_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM arbitraje.arbitro WHERE arbitro_id = @arbitro_id)
        SET @errores += '- No existe el árbitro con id ' + CAST(@arbitro_id AS VARCHAR(12)) + '.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre es obligatorio.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@apellido)), '') IS NULL
        SET @errores += '- El apellido es obligatorio.' + @nl;
    IF @fecha_nacimiento > DATEADD(YEAR, -18, @hoy) OR @fecha_nacimiento < DATEADD(YEAR, -70, @hoy)
        SET @errores += '- La fecha de nacimiento debe corresponder a una edad de entre 18 y 70 años.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pais_id = @pais_id)
        SET @errores += '- No existe el país con id ' + ISNULL(CAST(@pais_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @categoria IS NULL OR @categoria NOT IN ('FIFA', 'confederacion')
        SET @errores += '- La categoría debe ser FIFA o confederacion.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.arbitro
               WHERE nombre = @nombre AND apellido = @apellido AND pais_id = @pais_id
                 AND (@arbitro_id IS NULL OR arbitro_id <> @arbitro_id))
        SET @errores += '- Ya existe un árbitro con ese nombre y apellido para ese país.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.arbitro_insertar
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

    INSERT INTO arbitraje.arbitro (nombre, apellido, fecha_nacimiento, pais_id, categoria)
    VALUES (LTRIM(RTRIM(@nombre)), LTRIM(RTRIM(@apellido)), @fecha_nacimiento, @pais_id, @categoria);

    SET @arbitro_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.arbitro_modificar
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

    UPDATE arbitraje.arbitro
    SET nombre = LTRIM(RTRIM(@nombre)),
        apellido = LTRIM(RTRIM(@apellido)),
        fecha_nacimiento = @fecha_nacimiento,
        pais_id = @pais_id,
        categoria = @categoria
    WHERE arbitro_id = @arbitro_id;
END;
GO

-- Los idiomas son un detalle del árbitro: se eliminan junto con él en la misma transacción.

CREATE OR ALTER PROCEDURE arbitraje.arbitro_eliminar
    @arbitro_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    IF NOT EXISTS (SELECT 1 FROM arbitraje.arbitro WHERE arbitro_id = @arbitro_id)
        SET @errores += '- No existe el árbitro con id ' + ISNULL(CAST(@arbitro_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral WHERE arbitro_id = @arbitro_id)
        SET @errores += '- Tiene designaciones en partidos.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.arbitro_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        DELETE FROM arbitraje.arbitro_idioma WHERE arbitro_id = @arbitro_id;
        DELETE FROM arbitraje.arbitro WHERE arbitro_id = @arbitro_id;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.arbitro_idioma_insertar
    @arbitro_id INT,
    @idioma     VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM arbitraje.arbitro WHERE arbitro_id = @arbitro_id)
        SET @errores += '- No existe el árbitro con id ' + ISNULL(CAST(@arbitro_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@idioma)), '') IS NULL OR LEN(@idioma) > 10 OR @idioma LIKE '%[^A-Za-z]%'
        SET @errores += '- El idioma es obligatorio: hasta 10 letras, sin espacios ni números (ej: espanol).' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.arbitro_idioma WHERE arbitro_id = @arbitro_id AND idioma = @idioma)
        SET @errores += '- El árbitro ya tiene registrado ese idioma.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.arbitro_idioma_insertar - alta rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO arbitraje.arbitro_idioma (arbitro_id, idioma) VALUES (@arbitro_id, LOWER(@idioma));
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.arbitro_idioma_modificar
    @arbitro_id   INT,
    @idioma       VARCHAR(30),
    @idioma_nuevo VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM arbitraje.arbitro_idioma WHERE arbitro_id = @arbitro_id AND idioma = @idioma)
        SET @errores += '- El árbitro no tiene registrado el idioma a reemplazar.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@idioma_nuevo)), '') IS NULL OR LEN(@idioma_nuevo) > 10 OR @idioma_nuevo LIKE '%[^A-Za-z]%'
        SET @errores += '- El idioma nuevo es obligatorio: hasta 10 letras, sin espacios ni números.' + @nl;
    IF @idioma_nuevo <> @idioma
       AND EXISTS (SELECT 1 FROM arbitraje.arbitro_idioma WHERE arbitro_id = @arbitro_id AND idioma = @idioma_nuevo)
        SET @errores += '- El árbitro ya tiene registrado el idioma nuevo.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.arbitro_idioma_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE arbitraje.arbitro_idioma SET idioma = LOWER(@idioma_nuevo)
    WHERE arbitro_id = @arbitro_id AND idioma = @idioma;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.arbitro_idioma_eliminar
    @arbitro_id INT,
    @idioma     VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM arbitraje.arbitro_idioma WHERE arbitro_id = @arbitro_id AND idioma = @idioma)
        SET @errores += '- El árbitro no tiene registrado ese idioma.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.arbitro_idioma_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM arbitraje.arbitro_idioma WHERE arbitro_id = @arbitro_id AND idioma = @idioma;
END;
GO

/* Conflicto de nacionalidad: el país del árbitro no puede ser el de ninguna de las dos
 selecciones (bloqueo). Desde dieciseisavos, si el país del árbitro tiene una selección que
 sigue en competencia (puede cruzarse con las que juegan), no se bloquea: se devuelve una
 advertencia en @advertencia. */

CREATE OR ALTER PROCEDURE arbitraje.designacion_arbitral_validar
    @designacion_id INT,                             -- NULL en el alta
    @partido_id     INT,
    @arbitro_id     INT,
    @rol            VARCHAR(15),
    @errores        VARCHAR(2000) OUTPUT,
    @advertencia    VARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10), @pais_arbitro INT, @fase VARCHAR(13),
            @fecha_utc DATETIMEOFFSET, @arbitro VARCHAR(210);
    SET @errores = ISNULL(@errores, '');
    SET @advertencia = NULL;

    SELECT @fase = fase, @fecha_utc = fecha_hora_utc FROM torneo.partido WHERE partido_id = @partido_id;
    SELECT @pais_arbitro = pais_id, @arbitro = nombre + ' ' + apellido
    FROM arbitraje.arbitro WHERE arbitro_id = @arbitro_id;

    IF @designacion_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral WHERE designacion_id = @designacion_id)
        SET @errores += '- No existe la designación con id ' + CAST(@designacion_id AS VARCHAR(12)) + '.' + @nl;
    IF @fase IS NULL
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id AND estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF @pais_arbitro IS NULL
        SET @errores += '- No existe el árbitro con id ' + ISNULL(CAST(@arbitro_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @rol IS NULL OR @rol NOT IN ('principal', 'asistente_1', 'asistente_2', 'cuarto', 'var')
        SET @errores += '- El rol debe ser principal, asistente_1, asistente_2, cuarto o var.' + @nl;

    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral
               WHERE partido_id = @partido_id AND rol = @rol
                 AND (@designacion_id IS NULL OR designacion_id <> @designacion_id))
        SET @errores += '- El partido ya tiene designado el rol ' + @rol + '.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral
               WHERE partido_id = @partido_id AND arbitro_id = @arbitro_id
                 AND (@designacion_id IS NULL OR designacion_id <> @designacion_id))
        SET @errores += '- El árbitro ya está designado en ese partido con otro rol.' + @nl;

    IF EXISTS (SELECT 1 FROM torneo.partido p
               JOIN torneo.seleccion s ON s.seleccion_id IN (p.seleccion_local_id, p.seleccion_visitante_id)
               WHERE p.partido_id = @partido_id AND s.pais_id = @pais_arbitro)
        SET @errores += '- Conflicto de nacionalidad: el país del árbitro ' + @arbitro
                      + ' coincide con el de una de las selecciones del partido.' + @nl;

    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral d
               JOIN torneo.partido p ON p.partido_id = d.partido_id
               WHERE d.arbitro_id = @arbitro_id AND d.partido_id <> @partido_id
                 AND ABS(DATEDIFF(MINUTE, p.fecha_hora_utc, @fecha_utc)) < 24 * 60)
        SET @errores += '- El árbitro ya está designado en otro partido a menos de 24 horas.' + @nl;

    -- Advertencia (no bloquea): desde dieciseisavos, selección del país del árbitro aún en carrera,
    -- es decir, que no perdió ningún partido de eliminación directa ya finalizado.
    IF @fase <> 'grupos'
       AND EXISTS (SELECT 1 FROM torneo.seleccion s
                   WHERE s.pais_id = @pais_arbitro
                     AND NOT EXISTS (
                         SELECT 1 FROM torneo.partido e
                         WHERE e.estado = 'finalizado' AND e.fase <> 'grupos'
                           AND ((e.seleccion_local_id = s.seleccion_id
                                 AND (e.goles_local < e.goles_visitante
                                   OR (e.goles_local = e.goles_visitante AND e.penales_local < e.penales_visitante)))
                             OR (e.seleccion_visitante_id = s.seleccion_id
                                 AND (e.goles_visitante < e.goles_local
                                   OR (e.goles_local = e.goles_visitante AND e.penales_visitante < e.penales_local))))))
        SET @advertencia = 'ADVERTENCIA: el país del árbitro ' + @arbitro
                         + ' tiene una selección en competencia que puede cruzarse con las de este partido.';
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.designacion_arbitral_insertar
    @partido_id     INT,
    @arbitro_id     INT,
    @rol            VARCHAR(15),
    @designacion_id INT = NULL OUTPUT,
    @advertencia    VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC arbitraje.designacion_arbitral_validar NULL, @partido_id, @arbitro_id, @rol,
         @errores OUTPUT, @advertencia OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.designacion_arbitral_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO arbitraje.designacion_arbitral (partido_id, arbitro_id, rol)
    VALUES (@partido_id, @arbitro_id, @rol);

    SET @designacion_id = SCOPE_IDENTITY();
    IF @advertencia IS NOT NULL PRINT @advertencia;
END;
GO

-- Reemplaza al árbitro y/o el rol de una designación. El partido no se modifica.

CREATE OR ALTER PROCEDURE arbitraje.designacion_arbitral_modificar
    @designacion_id INT,
    @arbitro_id     INT,
    @rol            VARCHAR(15),
    @advertencia    VARCHAR(500) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @partido_id INT;

    SELECT @partido_id = partido_id FROM arbitraje.designacion_arbitral WHERE designacion_id = @designacion_id;

    IF @partido_id IS NULL
        SET @errores = '- No existe la designación con id '
                     + ISNULL(CAST(@designacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE
        EXEC arbitraje.designacion_arbitral_validar @designacion_id, @partido_id, @arbitro_id, @rol,
             @errores OUTPUT, @advertencia OUTPUT;

    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral
               WHERE designacion_id = @designacion_id AND arbitro_id <> @arbitro_id)
       AND EXISTS (SELECT 1 FROM arbitraje.informe_arbitral WHERE designacion_id = @designacion_id)
        SET @errores += '- No se puede cambiar el árbitro: la designación ya tiene informes cargados.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.designacion_arbitral_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE arbitraje.designacion_arbitral SET arbitro_id = @arbitro_id, rol = @rol
    WHERE designacion_id = @designacion_id;

    IF @advertencia IS NOT NULL PRINT @advertencia;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.designacion_arbitral_eliminar
    @designacion_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral WHERE designacion_id = @designacion_id)
        SET @errores += '- No existe la designación con id '
                      + ISNULL(CAST(@designacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral d
               JOIN torneo.partido p ON p.partido_id = d.partido_id
               WHERE d.designacion_id = @designacion_id AND p.estado = 'finalizado')
        SET @errores += '- El partido ya está finalizado: la designación es parte del historial arbitral.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.informe_arbitral WHERE designacion_id = @designacion_id)
        SET @errores += '- Tiene informes arbitrales cargados.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.designacion_arbitral_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM arbitraje.designacion_arbitral WHERE designacion_id = @designacion_id;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.informe_arbitral_validar
    @informe_id     INT,                             -- NULL en el alta
    @designacion_id INT,
    @fecha          DATETIMEOFFSET,
    @contenido      VARCHAR(MAX),
    @errores        VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF @informe_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM arbitraje.informe_arbitral WHERE informe_id = @informe_id)
        SET @errores += '- No existe el informe con id ' + CAST(@informe_id AS VARCHAR(12)) + '.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral WHERE designacion_id = @designacion_id)
        SET @errores += '- No existe la designación con id '
                      + ISNULL(CAST(@designacion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @fecha IS NULL
        SET @errores += '- La fecha del informe es obligatoria.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral d
               JOIN torneo.partido p ON p.partido_id = d.partido_id
               WHERE d.designacion_id = @designacion_id AND @fecha < p.fecha_hora_utc)
        SET @errores += '- El informe es post-partido: su fecha no puede ser anterior al inicio del partido.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@contenido)), '') IS NULL
        SET @errores += '- El contenido del informe es obligatorio.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.informe_arbitral_insertar
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

    INSERT INTO arbitraje.informe_arbitral (designacion_id, fecha, contenido, sancion)
    VALUES (@designacion_id, @fecha, @contenido, NULLIF(LTRIM(RTRIM(@sancion)), ''));

    SET @informe_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.informe_arbitral_modificar
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

    UPDATE arbitraje.informe_arbitral
    SET fecha = @fecha, contenido = @contenido, sancion = NULLIF(LTRIM(RTRIM(@sancion)), '')
    WHERE informe_id = @informe_id;
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.informe_arbitral_eliminar
    @informe_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM arbitraje.informe_arbitral WHERE informe_id = @informe_id)
        SET @errores += '- No existe el informe con id ' + ISNULL(CAST(@informe_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.informe_arbitral_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM arbitraje.informe_arbitral WHERE informe_id = @informe_id;
END;
GO

-- ===========================================================
-- II.9 ANUNCIANTES, CAMPAÑAS, PIEZAS Y ESPACIOS PUBLICITARIOS
-- ===========================================================

CREATE OR ALTER PROCEDURE publicidad.anunciante_insertar
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
    IF @contacto IS NOT NULL AND @contacto LIKE '%@%' AND @contacto NOT LIKE '_%@_%._%'
        SET @errores += '- El contacto parece un correo electrónico pero su formato no es válido.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.anunciante_insertar - alta rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO publicidad.anunciante (nombre, razon_social, contacto)
    VALUES (LTRIM(RTRIM(@nombre)), NULLIF(LTRIM(RTRIM(@razon_social)), ''), NULLIF(LTRIM(RTRIM(@contacto)), ''));

    SET @anunciante_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.anunciante_modificar
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
    IF EXISTS (SELECT 1 FROM publicidad.anunciante WHERE nombre = @nombre AND anunciante_id <> @anunciante_id)
        SET @errores += '- Ya existe otro anunciante con ese nombre.' + @nl;
    IF @contacto IS NOT NULL AND @contacto LIKE '%@%' AND @contacto NOT LIKE '_%@_%._%'
        SET @errores += '- El contacto parece un correo electrónico pero su formato no es válido.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.anunciante_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE publicidad.anunciante
    SET nombre = LTRIM(RTRIM(@nombre)),
        razon_social = NULLIF(LTRIM(RTRIM(@razon_social)), ''),
        contacto = NULLIF(LTRIM(RTRIM(@contacto)), '')
    WHERE anunciante_id = @anunciante_id;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.anunciante_eliminar
    @anunciante_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM publicidad.anunciante WHERE anunciante_id = @anunciante_id)
        SET @errores += '- No existe el anunciante con id '
                      + ISNULL(CAST(@anunciante_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.campania WHERE anunciante_id = @anunciante_id)
        SET @errores += '- Tiene campañas registradas.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.anunciante_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM publicidad.anunciante WHERE anunciante_id = @anunciante_id;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.campania_validar
    @campania_id   INT,                              -- NULL en el alta
    @anunciante_id INT,
    @nombre        VARCHAR(100),
    @fecha_inicio  DATE,
    @fecha_fin     DATE,
    @errores       VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF @campania_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.campania WHERE campania_id = @campania_id)
        SET @errores += '- No existe la campaña con id ' + CAST(@campania_id AS VARCHAR(12)) + '.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM publicidad.anunciante WHERE anunciante_id = @anunciante_id)
        SET @errores += '- No existe el anunciante con id '
                      + ISNULL(CAST(@anunciante_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
        SET @errores += '- El nombre de la campaña es obligatorio.' + @nl;
    IF @fecha_inicio IS NULL OR @fecha_fin IS NULL
        SET @errores += '- Las fechas de inicio y de fin son obligatorias.' + @nl;
    IF @fecha_fin < @fecha_inicio
        SET @errores += '- La fecha de fin no puede ser anterior a la fecha de inicio.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.campania
               WHERE anunciante_id = @anunciante_id AND nombre = @nombre
                 AND (@campania_id IS NULL OR campania_id <> @campania_id))
        SET @errores += '- El anunciante ya tiene una campaña con ese nombre.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.campania_insertar
    @anunciante_id INT,
    @nombre        VARCHAR(100),
    @fecha_inicio  DATE,
    @fecha_fin     DATE,
    @campania_id   INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC publicidad.campania_validar NULL, @anunciante_id, @nombre, @fecha_inicio, @fecha_fin, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.campania_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO publicidad.campania (anunciante_id, nombre, fecha_inicio, fecha_fin)
    VALUES (@anunciante_id, LTRIM(RTRIM(@nombre)), @fecha_inicio, @fecha_fin);

    SET @campania_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.campania_modificar
    @campania_id   INT,
    @anunciante_id INT,
    @nombre        VARCHAR(100),
    @fecha_inicio  DATE,
    @fecha_fin     DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @campania_id IS NULL SET @errores = '- El id de la campaña es obligatorio.' + @nl;
    EXEC publicidad.campania_validar @campania_id, @anunciante_id, @nombre, @fecha_inicio, @fecha_fin,
         @errores OUTPUT;

    -- La vigencia no puede dejar afuera partidos en los que ya se asignaron piezas de la campaña.
    IF EXISTS (SELECT 1 FROM publicidad.espacio_publicitario e
               JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
               JOIN torneo.partido p                 ON p.partido_id = e.partido_id
               WHERE pz.campania_id = @campania_id
                 AND CAST(p.fecha_hora_utc AS DATE) NOT BETWEEN @fecha_inicio AND @fecha_fin)
        SET @errores += '- La nueva vigencia deja afuera partidos donde ya hay piezas de la campaña asignadas.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.campania_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE publicidad.campania
    SET anunciante_id = @anunciante_id, nombre = LTRIM(RTRIM(@nombre)),
        fecha_inicio = @fecha_inicio, fecha_fin = @fecha_fin
    WHERE campania_id = @campania_id;
END;
GO

-- Los países de interés son un detalle de la campaña: se eliminan con ella, las piezas no.

CREATE OR ALTER PROCEDURE publicidad.campania_eliminar
    @campania_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    IF NOT EXISTS (SELECT 1 FROM publicidad.campania WHERE campania_id = @campania_id)
        SET @errores += '- No existe la campaña con id ' + ISNULL(CAST(@campania_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria WHERE campania_id = @campania_id)
        SET @errores += '- Tiene piezas publicitarias registradas.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.campania_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        DELETE FROM publicidad.campania_pais_interes WHERE campania_id = @campania_id;
        DELETE FROM publicidad.campania WHERE campania_id = @campania_id;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.campania_pais_interes_insertar
    @campania_id INT,
    @pais_id     INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM publicidad.campania WHERE campania_id = @campania_id)
        SET @errores += '- No existe la campaña con id ' + ISNULL(CAST(@campania_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pais_id = @pais_id)
        SET @errores += '- No existe el país con id ' + ISNULL(CAST(@pais_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.campania_pais_interes WHERE campania_id = @campania_id AND pais_id = @pais_id)
        SET @errores += '- El país ya figura como de interés para esa campaña.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.campania_pais_interes_insertar - alta rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO publicidad.campania_pais_interes (campania_id, pais_id) VALUES (@campania_id, @pais_id);
END;
GO

CREATE OR ALTER PROCEDURE publicidad.campania_pais_interes_modificar
    @campania_id   INT,
    @pais_id       INT,
    @pais_id_nuevo INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM publicidad.campania_pais_interes WHERE campania_id = @campania_id AND pais_id = @pais_id)
        SET @errores += '- El país a reemplazar no figura como de interés para esa campaña.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pais_id = @pais_id_nuevo)
        SET @errores += '- No existe el país nuevo con id '
                      + ISNULL(CAST(@pais_id_nuevo AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @pais_id_nuevo <> @pais_id
       AND EXISTS (SELECT 1 FROM publicidad.campania_pais_interes
                   WHERE campania_id = @campania_id AND pais_id = @pais_id_nuevo)
        SET @errores += '- El país nuevo ya figura como de interés para esa campaña.' + @nl;
    IF @pais_id_nuevo <> @pais_id
       AND EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria
                   WHERE campania_id = @campania_id AND pais_mercado_id = @pais_id)
        SET @errores += '- La campaña tiene piezas dirigidas al país a reemplazar.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.campania_pais_interes_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE publicidad.campania_pais_interes SET pais_id = @pais_id_nuevo
    WHERE campania_id = @campania_id AND pais_id = @pais_id;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.campania_pais_interes_eliminar
    @campania_id INT,
    @pais_id     INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM publicidad.campania_pais_interes WHERE campania_id = @campania_id AND pais_id = @pais_id)
        SET @errores += '- El país no figura como de interés para esa campaña.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria
               WHERE campania_id = @campania_id AND pais_mercado_id = @pais_id)
        SET @errores += '- La campaña tiene piezas dirigidas a ese país.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.campania_pais_interes_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM publicidad.campania_pais_interes WHERE campania_id = @campania_id AND pais_id = @pais_id;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.pieza_publicitaria_validar
    @pieza_id        INT,                            -- NULL en el alta
    @campania_id     INT,
    @idioma          VARCHAR(30),
    @pais_mercado_id INT,
    @costo_tarifa    NUMERIC(12,2),
    @errores         VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF @pieza_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria WHERE pieza_id = @pieza_id)
        SET @errores += '- No existe la pieza con id ' + CAST(@pieza_id AS VARCHAR(12)) + '.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM publicidad.campania WHERE campania_id = @campania_id)
        SET @errores += '- No existe la campaña con id ' + ISNULL(CAST(@campania_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@idioma)), '') IS NULL OR LEN(@idioma) > 10 OR @idioma LIKE '%[^A-Za-z]%'
        SET @errores += '- El idioma es obligatorio: hasta 10 letras, sin espacios ni números (ej: ingles).' + @nl;
    IF NOT EXISTS (SELECT 1 FROM torneo.pais WHERE pais_id = @pais_mercado_id)
        SET @errores += '- No existe el país mercado con id '
                      + ISNULL(CAST(@pais_mercado_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE IF EXISTS (SELECT 1 FROM publicidad.campania WHERE campania_id = @campania_id)
         AND NOT EXISTS (SELECT 1 FROM publicidad.campania_pais_interes
                         WHERE campania_id = @campania_id AND pais_id = @pais_mercado_id)
        SET @errores += '- El país mercado no figura entre los países de interés de la campaña.' + @nl;
    IF @costo_tarifa IS NULL OR @costo_tarifa < 0
        SET @errores += '- El costo de la tarifa es obligatorio y no puede ser negativo.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria
               WHERE campania_id = @campania_id AND idioma = @idioma AND pais_mercado_id = @pais_mercado_id
                 AND (@pieza_id IS NULL OR pieza_id <> @pieza_id))
        SET @errores += '- La campaña ya tiene una pieza para ese idioma y mercado.' + @nl;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.pieza_publicitaria_insertar
    @campania_id     INT,
    @idioma          VARCHAR(30),
    @pais_mercado_id INT,
    @costo_tarifa    NUMERIC(12,2),
    @pieza_id        INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC publicidad.pieza_publicitaria_validar NULL, @campania_id, @idioma, @pais_mercado_id, @costo_tarifa,
         @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.pieza_publicitaria_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO publicidad.pieza_publicitaria (campania_id, idioma, pais_mercado_id, costo_tarifa)
    VALUES (@campania_id, LOWER(@idioma), @pais_mercado_id, @costo_tarifa);

    SET @pieza_id = SCOPE_IDENTITY();
END;
GO

CREATE OR ALTER PROCEDURE publicidad.pieza_publicitaria_modificar
    @pieza_id        INT,
    @campania_id     INT,
    @idioma          VARCHAR(30),
    @pais_mercado_id INT,
    @costo_tarifa    NUMERIC(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @pieza_id IS NULL SET @errores = '- El id de la pieza es obligatorio.' + @nl;
    EXEC publicidad.pieza_publicitaria_validar @pieza_id, @campania_id, @idioma, @pais_mercado_id, @costo_tarifa,
         @errores OUTPUT;

    -- Lo ya facturado conserva su importe (monto_facturado), pero la pieza no puede cambiar de campaña/mercado.
    IF EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria
               WHERE pieza_id = @pieza_id AND (campania_id <> @campania_id OR pais_mercado_id <> @pais_mercado_id))
       AND EXISTS (SELECT 1 FROM publicidad.espacio_publicitario WHERE pieza_id = @pieza_id)
        SET @errores += '- La pieza ya está asignada a espacios: no puede cambiar de campaña ni de mercado.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.pieza_publicitaria_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE publicidad.pieza_publicitaria
    SET campania_id = @campania_id, idioma = LOWER(@idioma),
        pais_mercado_id = @pais_mercado_id, costo_tarifa = @costo_tarifa
    WHERE pieza_id = @pieza_id;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.pieza_publicitaria_eliminar
    @pieza_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria WHERE pieza_id = @pieza_id)
        SET @errores += '- No existe la pieza con id ' + ISNULL(CAST(@pieza_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.espacio_publicitario WHERE pieza_id = @pieza_id)
        SET @errores += '- Está asignada a espacios publicitarios de partidos.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.pieza_publicitaria_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM publicidad.pieza_publicitaria WHERE pieza_id = @pieza_id;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.espacio_publicitario_validar
    @espacio_id      INT,                            -- NULL en el alta
    @partido_id      INT,
    @numero_espacio  INT,
    @pieza_id        INT,
    @orden_prioridad INT,
    @errores         VARCHAR(2000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @nl CHAR(2) = CHAR(13) + CHAR(10);
    SET @errores = ISNULL(@errores, '');

    IF NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @numero_espacio IS NULL OR @numero_espacio NOT BETWEEN 1 AND 4
        SET @errores += '- El número de espacio debe estar entre 1 y 4.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.espacio_publicitario
               WHERE partido_id = @partido_id AND numero_espacio = @numero_espacio
                 AND (@espacio_id IS NULL OR espacio_id <> @espacio_id))
        SET @errores += '- Ese espacio ya está registrado para el partido.' + @nl;
    IF @orden_prioridad IS NOT NULL AND @orden_prioridad NOT BETWEEN 1 AND 4
        SET @errores += '- El orden de prioridad debe estar entre 1 y 4 (1 país de selección, 2 poder adquisitivo, 3 prime time, 4 tarifa).' + @nl;

    IF @pieza_id IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria WHERE pieza_id = @pieza_id)
            SET @errores += '- No existe la pieza con id ' + CAST(@pieza_id AS VARCHAR(12)) + '.' + @nl;
        ELSE IF NOT EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria pz
                            JOIN publicidad.campania c ON c.campania_id = pz.campania_id
                            JOIN torneo.partido p      ON p.partido_id = @partido_id
                            WHERE pz.pieza_id = @pieza_id
                              AND CAST(p.fecha_hora_utc AS DATE) BETWEEN c.fecha_inicio AND c.fecha_fin)
            SET @errores += '- La campaña de la pieza no está vigente en la fecha del partido.' + @nl;
        IF EXISTS (SELECT 1 FROM publicidad.espacio_publicitario
                   WHERE partido_id = @partido_id AND pieza_id = @pieza_id
                     AND (@espacio_id IS NULL OR espacio_id <> @espacio_id))
            SET @errores += '- La pieza ya ocupa otro espacio del mismo partido.' + @nl;
    END;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.espacio_publicitario_insertar
    @partido_id      INT,
    @numero_espacio  INT,
    @pieza_id        INT = NULL,
    @orden_prioridad INT = NULL,
    @espacio_id      INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '';

    EXEC publicidad.espacio_publicitario_validar NULL, @partido_id, @numero_espacio, @pieza_id,
         @orden_prioridad, @errores OUTPUT;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.espacio_publicitario_insertar - alta rechazada:' + CHAR(13) + CHAR(10) + @errores;
        THROW 50001, @errores, 1;
    END;

    INSERT INTO publicidad.espacio_publicitario (partido_id, numero_espacio, pieza_id, orden_prioridad)
    VALUES (@partido_id, @numero_espacio, @pieza_id, @orden_prioridad);

    SET @espacio_id = SCOPE_IDENTITY();
END;
GO

/* Partido y número de espacio no se modifican. fecha_exhibicion la completa
 torneo.registrar_resultado y la facturación publicidad.facturar_espacios_partido */

CREATE OR ALTER PROCEDURE publicidad.espacio_publicitario_modificar
    @espacio_id       INT,
    @pieza_id         INT = NULL,
    @orden_prioridad  INT = NULL,
    @fecha_exhibicion DATETIMEOFFSET = NULL,
    @facturado        BIT = 0,
    @monto_facturado  NUMERIC(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @partido_id INT, @numero_espacio INT, @pieza_actual INT, @facturado_actual BIT;

    SELECT @partido_id = partido_id, @numero_espacio = numero_espacio,
           @pieza_actual = pieza_id, @facturado_actual = facturado
    FROM publicidad.espacio_publicitario WHERE espacio_id = @espacio_id;

    IF @partido_id IS NULL
        SET @errores = '- No existe el espacio con id ' + ISNULL(CAST(@espacio_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE
        EXEC publicidad.espacio_publicitario_validar @espacio_id, @partido_id, @numero_espacio, @pieza_id,
             @orden_prioridad, @errores OUTPUT;

    IF @facturado_actual = 1 AND ISNULL(@pieza_id, 0) <> ISNULL(@pieza_actual, 0)
        SET @errores += '- El espacio ya fue facturado: no se puede cambiar la pieza exhibida.' + @nl;
    IF @facturado = 1 AND (@pieza_id IS NULL OR @fecha_exhibicion IS NULL OR @monto_facturado IS NULL)
        SET @errores += '- Para marcarlo como facturado debe tener pieza, fecha de exhibición y monto.' + @nl;
    IF ISNULL(@facturado, 0) = 0 AND @monto_facturado IS NOT NULL
        SET @errores += '- No se puede informar monto facturado si el espacio no está facturado.' + @nl;
    IF @monto_facturado < 0
        SET @errores += '- El monto facturado no puede ser negativo.' + @nl;
    IF @fecha_exhibicion IS NOT NULL AND @pieza_id IS NULL
        SET @errores += '- No se puede informar fecha de exhibición en un espacio sin pieza.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.espacio_publicitario_modificar - modificación rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    UPDATE publicidad.espacio_publicitario
    SET pieza_id = @pieza_id,
        orden_prioridad = @orden_prioridad,
        fecha_exhibicion = @fecha_exhibicion,
        facturado = ISNULL(@facturado, 0),
        monto_facturado = @monto_facturado
    WHERE espacio_id = @espacio_id;
END;
GO

CREATE OR ALTER PROCEDURE publicidad.espacio_publicitario_eliminar
    @espacio_id INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF NOT EXISTS (SELECT 1 FROM publicidad.espacio_publicitario WHERE espacio_id = @espacio_id)
        SET @errores += '- No existe el espacio con id ' + ISNULL(CAST(@espacio_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.espacio_publicitario WHERE espacio_id = @espacio_id AND facturado = 1)
        SET @errores += '- El espacio ya fue facturado: forma parte del historial de facturación.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.espacio_publicitario_eliminar - baja rechazada:' + @nl + @errores;
        THROW 50001, @errores, 1;
    END;

    DELETE FROM publicidad.espacio_publicitario WHERE espacio_id = @espacio_id;
END;
GO