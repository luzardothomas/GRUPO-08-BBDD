-- =======================================================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 6: Procesos de importación
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Objetos comunes de importación e importación de archivos en tres formatos (CSV, JSON y XML).
--   Se ejecuta después de los scripts de creación de la Entrega 5 (usa sus SP de ABM) y antes de
--   entrega6_scraping.sql y entrega6_apis.sql:
--     0. Configuración del servidor para consumir APIs.
--     1. Tablas: lotes, errores, equivalencias de país, PBI por año, tipos de cambio y
--        estadísticas de selecciones y jugadores.
--     2. Vista y funciones de apoyo.
--     3. Datos de referencia: confederaciones y países.
--     4. Utilidades comunes de los importadores (incluyendo lectura CSV/JSON/XML y conversión de moneda).
--     5. Importación de datasets en archivos (procesados tal cual):
--          torneo.importar_estadisticas_equipos_kaggle_2026    CSV  (teams.csv de Kaggle)
--          plantel.importar_estadisticas_jugadores_kaggle_2026 CSV  (players.csv de Kaggle)
--          torneo.importar_fixture                             JSON (worldcup.json de openfootball)
--          publicidad.importar_tarifas                         XML  (tarifas_publicidad.xml, convirtiendo a USD)
--   Es reejecutable: crea sólo lo que falta y la carga de referencia es un upsert.
--   Requiere SQL Server 2025 (17.x): sp_invoke_external_rest_endpoint y STRING_SPLIT
--   con ordinal.
--
-- FUENTES DE DATOS Y LÍMITES DE USO:
--   * Kaggle - FIFA World Cup 2026 Teams & Matches (creado por swaptr, datos de FBref):
--     - https://www.kaggle.com/datasets/swaptr/fifa-wc-2026-matches (teams.csv, formato CSV)
--   * Kaggle - FIFA World Cup 2026 Players (creado por swaptr, datos de FBref):
--     - https://www.kaggle.com/datasets/swaptr/fifa-wc-2026-players (players.csv, formato CSV)
--     Límites de uso: datasets públicos estáticos de descarga libre (licencia CC0 / dominio
--     público); la descarga manual desde la web de Kaggle requiere cuenta gratuita (o API token
--     para CLI), sin rate limit en el procesamiento local con BULK INSERT. La fuente original
--     (FBref) bloquea el scraping automatizado directo con Cloudflare (HTTP 403).
--   * openfootball - World Cup JSON (dominio público, CC0-1.0):
--     - https://github.com/openfootball/worldcup.json (worldcup.json, formato JSON)
--     Límites de uso: repositorio público en GitHub sin necesidad de clave ni límite para la
--     lectura del archivo JSON local con OPENROWSET(BULK ..., SINGLE_BLOB).
--   * Tarifario comercial de pauta publicitaria (basado en Dossier Mundial / FIFA Commercial):
--     - https://dossiermundial.netlify.app/ (tarifas_publicidad.xml, formato XML)
--     Límites de uso: archivo XML local procesado con OPENROWSET(BULK ..., SINGLE_BLOB) y XQuery;
--     la conversión de las 9 monedas a USD utiliza las cotizaciones descargadas en
--     publicidad.tipo_cambio desde la API de Frankfurter.
--
-- NORMA COMÚN DE LOS IMPORTADORES:
--   * El nombre del archivo es un parámetro (@ruta_archivo, ruta vista por el servidor).
--   * Cada ejecución abre un lote (importacion.lote) y lo cierra con los contadores
--     leídos / insertados / actualizados / sin cambios / rechazados.
--   * Un archivo que no se puede leer o no tiene el formato esperado rechaza el lote:
--     THROW 50003.
--   * Cada fila se procesa en su propio TRY...CATCH y su propia transacción: si falla, se
--     deshace sólo esa fila, se registra en importacion.error con el mensaje que la
--     rechazó y se sigue con la siguiente (importación parcial). Las faltas de formato o
--     datos incompletos de la fila se informan juntas en un THROW 50004; las reglas de
--     negocio las informan los SP de la Entrega 5 (THROW 50001 / 50002).
--   * Upsert sin MERGE: se busca la fila por su clave natural; si no existe se da de alta
--     con el SP _insertar de la Entrega 5, si existe y cambió se usa el SP _modificar, y
--     si está igual no se toca (reimportar el mismo archivo no genera duplicados).
--   * SQL dinámico: sólo para BULK INSERT, que no acepta la ruta del archivo en una
--     variable.
-- =======================================================================================

-- ============================================================
-- 0. CONFIGURACIÓN DEL SERVIDOR (requiere sysadmin)
-- ============================================================

-- Habilita sp_invoke_external_rest_endpoint, con el que se consumen las APIs.

USE master;
GO

IF EXISTS (SELECT 1 FROM sys.configurations
           WHERE name = 'external rest endpoint enabled' AND value_in_use = 0)
BEGIN
    EXEC sp_configure 'external rest endpoint enabled', 1;
    RECONFIGURE WITH OVERRIDE;
END;
GO

USE mundial_2026;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- 1. TABLAS
-- ============================================================

IF SCHEMA_ID('importacion') IS NULL EXEC('CREATE SCHEMA importacion');
GO

-- Una fila por ejecución de un proceso de importación: qué se importó, desde dónde y con
-- qué resultado. Permite auditar las reimportaciones del mismo archivo.

IF OBJECT_ID('importacion.lote', 'U') IS NULL
    CREATE TABLE importacion.lote (
        lote_id      INT IDENTITY(1, 1),
        proceso      VARCHAR(60) NOT NULL,               -- SP que importó
        origen       VARCHAR(500) NOT NULL,              -- ruta del archivo o URL de la API
        fecha_inicio DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
        fecha_fin    DATETIMEOFFSET,
        leidos       INT NOT NULL DEFAULT 0,
        insertados   INT NOT NULL DEFAULT 0,
        actualizados INT NOT NULL DEFAULT 0,
        sin_cambios  INT NOT NULL DEFAULT 0,
        rechazados   INT NOT NULL DEFAULT 0,
        estado       VARCHAR(10) NOT NULL DEFAULT 'en_curso',

        CONSTRAINT pk_lote PRIMARY KEY (lote_id),
        CONSTRAINT chk_lote_estado CHECK (estado IN ('en_curso', 'completo', 'parcial', 'rechazado'))
    );
GO

-- Registros que no se pudieron importar, con el motivo (el mensaje del THROW que lo
-- impidió: de formato, de la importación o de los SP de la Entrega 5).

IF OBJECT_ID('importacion.error', 'U') IS NULL
    CREATE TABLE importacion.error (
        error_id     INT IDENTITY(1, 1),
        lote_id      INT NOT NULL,
        fila         INT,                                -- NULL si el error es del archivo entero
        registro     VARCHAR(1000),                      -- datos de la fila, para ubicarla
        numero_error INT NOT NULL,
        motivo       VARCHAR(2100) NOT NULL,
        fecha        DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),

        CONSTRAINT pk_error PRIMARY KEY (error_id),
        CONSTRAINT fk_error_lote FOREIGN KEY (lote_id) REFERENCES importacion.lote (lote_id)
    );
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_error_lote')
    CREATE INDEX idx_error_lote ON importacion.error (lote_id);
GO

-- Cada fuente nombra a los países a su manera ('Korea Republic', 'Côte d''Ivoire', o el
-- código FIFA 'GER' en lugar del ISO 'DEU'). Esta tabla traduce esos nombres al país del modelo.

IF OBJECT_ID('importacion.pais_equivalencia', 'U') IS NULL
    CREATE TABLE importacion.pais_equivalencia (
        nombre_externo VARCHAR(80) NOT NULL,
        pais_id        INT NOT NULL,

        CONSTRAINT pk_pais_equivalencia PRIMARY KEY (nombre_externo),
        CONSTRAINT fk_pais_equivalencia_pais FOREIGN KEY (pais_id) REFERENCES torneo.pais (pais_id)
    );
GO

-- PBI per cápita por país y año (API del Banco Mundial). Se conservan todos los años; el
-- más reciente se copia además a torneo.pais.pbi_per_capita.

IF OBJECT_ID('torneo.indicador_economico', 'U') IS NULL
    CREATE TABLE torneo.indicador_economico (
        pais_id          INT NOT NULL,
        codigo_indicador VARCHAR(30) NOT NULL,           -- ej: NY.GDP.PCAP.CD
        anio             SMALLINT NOT NULL,
        valor            NUMERIC(14,2) NOT NULL,
        fuente           VARCHAR(30) NOT NULL,
        importado_en     DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),

        CONSTRAINT pk_indicador_economico PRIMARY KEY (pais_id, codigo_indicador, anio),
        CONSTRAINT fk_indicador_economico_pais FOREIGN KEY (pais_id) REFERENCES torneo.pais (pais_id),
        CONSTRAINT chk_indicador_economico_valor CHECK (valor >= 0)
    );
GO

-- Cotizaciones diarias (API Frankfurter), para expresar la pauta publicitaria en otras
-- monedas. Histórica: una fila por fecha y par de monedas.

IF OBJECT_ID('publicidad.tipo_cambio', 'U') IS NULL
    CREATE TABLE publicidad.tipo_cambio (
        fecha           DATE NOT NULL,
        moneda_base     CHAR(3) NOT NULL,
        moneda_cotizada CHAR(3) NOT NULL,
        tipo_cambio     NUMERIC(18,8) NOT NULL,          -- unidades de moneda_cotizada por 1 moneda_base
        fuente          VARCHAR(30) NOT NULL,
        importado_en    DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),

        CONSTRAINT pk_tipo_cambio PRIMARY KEY (fecha, moneda_base, moneda_cotizada),
        CONSTRAINT chk_tipo_cambio_monedas CHECK (moneda_base <> moneda_cotizada),
        CONSTRAINT chk_tipo_cambio_positivo CHECK (tipo_cambio > 0)
    );
GO

-- Tabla final del torneo por selección (scraping de Wikipedia, entrega6_scraping.sql): datos que el modelo no
-- tiene como columnas. Una fila por selección, se reemplaza en cada importación.

IF OBJECT_ID('torneo.seleccion_estadistica', 'U') IS NULL
    CREATE TABLE torneo.seleccion_estadistica (
        seleccion_id    INT NOT NULL,
        posicion_final  INT NOT NULL,
        partidos        INT NOT NULL,
        ganados         INT NOT NULL,
        empatados       INT NOT NULL,
        perdidos        INT NOT NULL,
        goles_a_favor   INT NOT NULL,
        goles_en_contra INT NOT NULL,
        puntos          INT NOT NULL,
        archivo_origen  VARCHAR(500) NOT NULL,
        importado_en    DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),

        CONSTRAINT pk_seleccion_estadistica PRIMARY KEY (seleccion_id),
        CONSTRAINT fk_seleccion_estadistica_seleccion FOREIGN KEY (seleccion_id)
            REFERENCES torneo.seleccion (seleccion_id),
        CONSTRAINT chk_seleccion_estadistica_partidos CHECK (partidos = ganados + empatados + perdidos)
    );
GO

-- Estadísticas por selección de Kaggle (swaptr, teams.csv): posesión, tiros, faltas, tarjetas,
-- atajadas... Se guardan vinculadas a la selección del modelo.

IF OBJECT_ID('torneo.seleccion_estadistica_kaggle', 'U') IS NULL
    CREATE TABLE torneo.seleccion_estadistica_kaggle (
        seleccion_id      INT NOT NULL,
        pais_equipo       VARCHAR(100) NOT NULL,
        jugadores_usados  INT,
        edad_promedio     NUMERIC(5,1),
        posesion          NUMERIC(5,1),
        partidos          INT,
        minutos           INT,
        goles             INT,
        asistencias       INT,
        goles_penal       INT,
        amarillas         INT,
        rojas             INT,
        tiros             INT,
        tiros_al_arco     INT,
        faltas            INT,
        offsides          INT,
        atajadas          INT,
        vallas_invictas   INT,
        archivo_origen    VARCHAR(500) NOT NULL,
        importado_en      DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),

        CONSTRAINT pk_seleccion_estadistica_kaggle PRIMARY KEY (seleccion_id),
        CONSTRAINT uq_seleccion_estadistica_kaggle_pais UNIQUE (pais_equipo),
        CONSTRAINT fk_seleccion_estadistica_kaggle_seleccion FOREIGN KEY (seleccion_id)
            REFERENCES torneo.seleccion (seleccion_id)
    );
GO

-- Estadísticas de jugadores de Kaggle (swaptr, datos de FBref): minutos, goles, tarjetas...
-- Se guardan tal como los publica la fuente, vinculadas a la selección y, cuando el nombre
-- coincide, al jugador del modelo.

IF OBJECT_ID('plantel.jugador_estadistica_kaggle', 'U') IS NULL
    CREATE TABLE plantel.jugador_estadistica_kaggle (
        jugador_estadistica_id INT IDENTITY(1, 1),
        jugador                VARCHAR(120) NOT NULL,
        pais_equipo            VARCHAR(100) NOT NULL,
        seleccion_id           INT NOT NULL,
        jugador_id             INT,                      -- NULL si el nombre no coincide con plantel.jugador
        posicion_fuente        VARCHAR(10),
        edad                   INT,
        anio_nacimiento        INT,
        club                   VARCHAR(120),
        partidos               INT,
        titularidades          INT,
        minutos                NUMERIC(10,1),
        goles                  NUMERIC(8,1),
        asistencias            NUMERIC(8,1),
        amarillas              NUMERIC(8,1),
        rojas                  NUMERIC(8,1),
        goles_penal            NUMERIC(8,1),
        goles_en_contra        NUMERIC(8,1),
        archivo_origen         VARCHAR(500) NOT NULL,
        importado_en           DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),

        CONSTRAINT pk_jugador_estadistica_kaggle PRIMARY KEY (jugador_estadistica_id),
        CONSTRAINT uq_jugador_estadistica_kaggle UNIQUE (pais_equipo, jugador),
        CONSTRAINT fk_jugador_estadistica_kaggle_seleccion FOREIGN KEY (seleccion_id)
            REFERENCES torneo.seleccion (seleccion_id),
        CONSTRAINT fk_jugador_estadistica_kaggle_jugador FOREIGN KEY (jugador_id)
            REFERENCES plantel.jugador (jugador_id)
    );
GO

-- ============================================================
-- 2. VISTA Y FUNCIONES DE APOYO
-- ============================================================

-- Último lote de cada proceso: el estado actual de cada importación.

CREATE OR ALTER VIEW importacion.vw_ultimo_lote
AS
SELECT l.lote_id, l.proceso, l.origen, l.fecha_inicio, l.fecha_fin, l.leidos, l.insertados,
       l.actualizados, l.sin_cambios, l.rechazados, l.estado
FROM importacion.lote l
WHERE l.lote_id = (SELECT MAX(x.lote_id) FROM importacion.lote x WHERE x.proceso = l.proceso);
GO

-- Resuelve el país a partir de cómo lo escribe la fuente: código ISO, nombre del modelo
-- (la collation CI_AI hace que 'Mexico' = 'México') o una equivalencia registrada.

CREATE OR ALTER FUNCTION importacion.fn_pais_id (@texto VARCHAR(100))
RETURNS INT
AS
BEGIN
    DECLARE @t VARCHAR(100) = LTRIM(RTRIM(@texto)), @pais_id INT;

    IF LEN(@t) = 3
        SELECT @pais_id = pais_id FROM torneo.pais WHERE codigo_iso = @t;
    IF @pais_id IS NULL
        SELECT @pais_id = pais_id FROM torneo.pais WHERE nombre = @t;
    IF @pais_id IS NULL
        SELECT @pais_id = pais_id FROM importacion.pais_equivalencia WHERE nombre_externo = @t;

    RETURN @pais_id;
END;
GO

-- Selección de un país (NULL si el país no tiene selección participante).

CREATE OR ALTER FUNCTION importacion.fn_seleccion_id (@texto VARCHAR(100))
RETURNS INT
AS
BEGIN
    RETURN (SELECT seleccion_id FROM torneo.seleccion WHERE pais_id = importacion.fn_pais_id(@texto));
END;
GO

-- ============================================================
-- 3. DATOS DE REFERENCIA
-- ============================================================

/* Confederaciones y los países de las 48 selecciones con sus equivalencias de nombre.
 Ninguna fuente pública trae juntos el código ISO, el nombre en castellano y el huso de
 un país: se cargan "por otros medios" (sección I del enunciado), con los SP de ABM de la
 Entrega 5. Alta si falta, modificación si cambió.
   * Huso del país: el de su capital durante el torneo (junio-julio de 2026, con horario
     de verano donde corresponde). El modelo admite sólo horas enteras: Irán (UTC+03:30)
     queda como UTC+03.
   * Inglaterra y Escocia juegan por separado: se usan sus códigos FIFA (ENG, SCO).
   * Equivalencias: el nombre en inglés, los alias de las fuentes y el código FIFA cuando
     difiere del ISO. */

CREATE OR ALTER PROCEDURE importacion.cargar_datos_referencia
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @i INT = 1, @n INT, @id INT, @codigo_iso CHAR(3), @nombre VARCHAR(80), @huso CHAR(6),
            @nombre_actual VARCHAR(80), @huso_actual CHAR(6), @pbi NUMERIC(12,2);

    DECLARE @confederaciones TABLE (orden INT IDENTITY(1, 1), nombre VARCHAR(8));
    INSERT INTO @confederaciones (nombre) VALUES ('AFC'), ('CAF'), ('CONCACAF'), ('CONMEBOL'), ('OFC'), ('UEFA');
    SELECT @n = COUNT(*) FROM @confederaciones;
    WHILE @i <= @n
    BEGIN
        SELECT @nombre = nombre FROM @confederaciones WHERE orden = @i;
        IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = @nombre)
            EXEC torneo.confederacion_insertar @nombre;
        SET @i += 1;
    END;

    DECLARE @paises TABLE (orden INT IDENTITY(1, 1), codigo_iso CHAR(3), nombre VARCHAR(80),
                           huso CHAR(6), nombre_ingles VARCHAR(80));
    INSERT INTO @paises (codigo_iso, nombre, huso, nombre_ingles) VALUES
        ('ARG', 'Argentina', 'UTC-03', 'Argentina'),      ('BRA', 'Brasil', 'UTC-03', 'Brazil'),
        ('URY', 'Uruguay', 'UTC-03', 'Uruguay'),          ('PRY', 'Paraguay', 'UTC-03', 'Paraguay'),
        ('COL', 'Colombia', 'UTC-05', 'Colombia'),        ('ECU', 'Ecuador', 'UTC-05', 'Ecuador'),
        ('USA', 'Estados Unidos', 'UTC-04', 'United States'), ('CAN', 'Canadá', 'UTC-04', 'Canada'),
        ('MEX', 'México', 'UTC-06', 'Mexico'),            ('PAN', 'Panamá', 'UTC-05', 'Panama'),
        ('HTI', 'Haití', 'UTC-04', 'Haiti'),              ('CUW', 'Curazao', 'UTC-04', 'Curaçao'),
        ('ENG', 'Inglaterra', 'UTC+01', 'England'),       ('SCO', 'Escocia', 'UTC+01', 'Scotland'),
        ('FRA', 'Francia', 'UTC+02', 'France'),           ('DEU', 'Alemania', 'UTC+02', 'Germany'),
        ('ESP', 'España', 'UTC+02', 'Spain'),             ('PRT', 'Portugal', 'UTC+01', 'Portugal'),
        ('NLD', 'Países Bajos', 'UTC+02', 'Netherlands'), ('BEL', 'Bélgica', 'UTC+02', 'Belgium'),
        ('CHE', 'Suiza', 'UTC+02', 'Switzerland'),        ('AUT', 'Austria', 'UTC+02', 'Austria'),
        ('CZE', 'Chequia', 'UTC+02', 'Czech Republic'),   ('HRV', 'Croacia', 'UTC+02', 'Croatia'),
        ('BIH', 'Bosnia y Herzegovina', 'UTC+02', 'Bosnia and Herzegovina'),
        ('NOR', 'Noruega', 'UTC+02', 'Norway'),           ('SWE', 'Suecia', 'UTC+02', 'Sweden'),
        ('TUR', 'Turquía', 'UTC+03', 'Turkey'),
        ('DZA', 'Argelia', 'UTC+01', 'Algeria'),          ('CPV', 'Cabo Verde', 'UTC-01', 'Cape Verde'),
        ('COD', 'República Democrática del Congo', 'UTC+01', 'DR Congo'),
        ('EGY', 'Egipto', 'UTC+03', 'Egypt'),             ('GHA', 'Ghana', 'UTC+00', 'Ghana'),
        ('CIV', 'Costa de Marfil', 'UTC+00', 'Ivory Coast'), ('MAR', 'Marruecos', 'UTC+01', 'Morocco'),
        ('SEN', 'Senegal', 'UTC+00', 'Senegal'),          ('ZAF', 'Sudáfrica', 'UTC+02', 'South Africa'),
        ('TUN', 'Túnez', 'UTC+01', 'Tunisia'),
        ('AUS', 'Australia', 'UTC+10', 'Australia'),      ('IRN', 'Irán', 'UTC+03', 'Iran'),
        ('IRQ', 'Irak', 'UTC+03', 'Iraq'),                ('JPN', 'Japón', 'UTC+09', 'Japan'),
        ('JOR', 'Jordania', 'UTC+03', 'Jordan'),          ('QAT', 'Catar', 'UTC+03', 'Qatar'),
        ('SAU', 'Arabia Saudita', 'UTC+03', 'Saudi Arabia'), ('KOR', 'Corea del Sur', 'UTC+09', 'South Korea'),
        ('UZB', 'Uzbekistán', 'UTC+05', 'Uzbekistan'),    ('NZL', 'Nueva Zelanda', 'UTC+12', 'New Zealand'),
        -- Países adicionales que son mercados comerciales / anunciantes en el tarifario publicitario
        ('ARE', 'Emiratos Árabes Unidos', 'UTC+04', 'United Arab Emirates'),
        ('GBR', 'Reino Unido', 'UTC+01', 'United Kingdom');

    SELECT @i = 1, @n = COUNT(*) FROM @paises;
    WHILE @i <= @n
    BEGIN
        SELECT @codigo_iso = codigo_iso, @nombre = nombre, @huso = huso FROM @paises WHERE orden = @i;
        SELECT @id = NULL, @nombre_actual = NULL, @huso_actual = NULL, @pbi = NULL;
        SELECT @id = pais_id, @nombre_actual = nombre, @huso_actual = huso_horario, @pbi = pbi_per_capita
        FROM torneo.pais WHERE codigo_iso = @codigo_iso;

        IF @id IS NULL
            EXEC torneo.pais_insertar @codigo_iso, @nombre, @huso;
        ELSE IF @nombre_actual COLLATE Latin1_General_CS_AS <> @nombre OR @huso_actual <> @huso
            EXEC torneo.pais_modificar @id, @codigo_iso, @nombre, @huso, @pbi;
        SET @i += 1;
    END;

    -- Equivalencias: el nombre en inglés de cada país más los alias que usan las fuentes.
    INSERT INTO importacion.pais_equivalencia (nombre_externo, pais_id)
    SELECT e.nombre_externo, p.pais_id
    FROM (SELECT nombre_ingles AS nombre_externo, codigo_iso FROM @paises
          UNION
          SELECT a.nombre_externo, a.codigo_iso
          FROM (VALUES ('Korea Republic', 'KOR'), ('Côte d''Ivoire', 'CIV'), ('Congo DR', 'COD'),
                       ('Czechia', 'CZE'), ('Türkiye', 'TUR'), ('Cabo Verde', 'CPV'), ('IR Iran', 'IRN'),
                       ('Bosnia & Herzegovina', 'BIH'),
                       -- códigos FIFA distintos del ISO (Wikipedia identifica así a las selecciones)
                       ('URU', 'URY'),
                       ('PAR', 'PRY'),
                       ('HAI', 'HTI'),
                       ('GER', 'DEU'),
                       ('POR', 'PRT'),
                       ('NED', 'NLD'),
                       ('SUI', 'CHE'),
                       ('CRO', 'HRV'),
                       ('ALG', 'DZA'),
                       ('RSA', 'ZAF'),
                       ('KSA', 'SAU')
                ) AS a (nombre_externo, codigo_iso)) e
    JOIN torneo.pais p ON p.codigo_iso = e.codigo_iso
    WHERE NOT EXISTS (SELECT 1 FROM importacion.pais_equivalencia x WHERE x.nombre_externo = e.nombre_externo);
END;
GO

EXEC importacion.cargar_datos_referencia;
GO

-- ============================================================
-- 4. UTILIDADES COMUNES
-- ============================================================

CREATE OR ALTER PROCEDURE importacion.lote_abrir
    @proceso VARCHAR(60),
    @origen  VARCHAR(500),
    @lote_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO importacion.lote (proceso, origen) VALUES (@proceso, ISNULL(@origen, '(sin origen)'));
    SET @lote_id = SCOPE_IDENTITY();
END;
GO

-- Cierra el lote con sus contadores y devuelve el resumen como resultado.

CREATE OR ALTER PROCEDURE importacion.lote_cerrar
    @lote_id      INT,
    @leidos       INT,
    @insertados   INT,
    @actualizados INT,
    @sin_cambios  INT,
    @rechazados   INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE importacion.lote
    SET fecha_fin = SYSDATETIMEOFFSET(),
        leidos = @leidos, insertados = @insertados, actualizados = @actualizados,
        sin_cambios = @sin_cambios, rechazados = @rechazados,
        estado = CASE WHEN @rechazados = 0 THEN 'completo'
                      WHEN @rechazados < @leidos THEN 'parcial'
                      ELSE 'rechazado' END
    WHERE lote_id = @lote_id;

    SELECT lote_id, proceso, origen, leidos, insertados, actualizados, sin_cambios, rechazados, estado
    FROM importacion.lote WHERE lote_id = @lote_id;
END;
GO

CREATE OR ALTER PROCEDURE importacion.error_registrar
    @lote_id      INT,
    @fila         INT,
    @registro     VARCHAR(1000),
    @numero_error INT,
    @motivo       VARCHAR(2100)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO importacion.error (lote_id, fila, registro, numero_error, motivo)
    VALUES (@lote_id, @fila, LEFT(@registro, 1000), ISNULL(@numero_error, 0), ISNULL(@motivo, '(sin mensaje)'));
END;
GO

-- El archivo entero no se pudo procesar: queda registrado y el lote, rechazado.

CREATE OR ALTER PROCEDURE importacion.lote_rechazar
    @lote_id      INT,
    @numero_error INT,
    @motivo       VARCHAR(2100)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC importacion.error_registrar @lote_id, NULL, NULL, @numero_error, @motivo;
    UPDATE importacion.lote SET fecha_fin = SYSDATETIMEOFFSET(), estado = 'rechazado' WHERE lote_id = @lote_id;
END;
GO

/* Carga un CSV (UTF-8, LF, con encabezado) en una tabla temporal creada por quien llama,
 visible desde acá porque la crea un ámbito superior. Con @formato_csv = 1 respeta los
 campos entre comillas; con 0 lee cada línea completa en una única columna. */

CREATE OR ALTER PROCEDURE importacion.archivo_cargar_csv
    @ruta_archivo  VARCHAR(500),
    @tabla_destino SYSNAME,
    @formato_csv   BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX), @mensaje VARCHAR(2100);

    IF NULLIF(LTRIM(RTRIM(@ruta_archivo)), '') IS NULL
        THROW 50003, 'Debe indicarse la ruta del archivo a importar.', 1;
    IF @tabla_destino NOT LIKE '#[A-Za-z]%' OR @tabla_destino LIKE '%[^A-Za-z0-9_#]%'
        THROW 50003, 'La tabla destino debe ser una tabla temporal.', 1;

    SET @sql = N'BULK INSERT ' + @tabla_destino + N' FROM ''' + REPLACE(@ruta_archivo, '''', '''''') + N''' WITH ('
             + IIF(@formato_csv = 1, N'FORMAT = ''CSV'', FIELDQUOTE = ''"'', FIELDTERMINATOR = '','', ',
                                     N'FIELDTERMINATOR = ''\t'', ')
             + N'FIRSTROW = 2, CODEPAGE = ''65001'', ROWTERMINATOR = ''0x0a'');';
    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        SET @mensaje = 'No se pudo leer el archivo ' + @ruta_archivo
                     + ' (revisar la ruta, los permisos del servicio de SQL Server y el formato): ' + ERROR_MESSAGE();
        THROW 50003, @mensaje, 1;
    END CATCH;
END;
GO

-- Invoca un GET y devuelve el cuerpo JSON de la respuesta. Cualquier falla (sin red,
-- endpoint deshabilitado, HTTP distinto de 2xx, respuesta sin cuerpo): THROW 50003.

CREATE OR ALTER PROCEDURE importacion.invocar_api
    @url       NVARCHAR(4000),
    @resultado NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @respuesta NVARCHAR(MAX), @codigo_retorno INT, @codigo_http VARCHAR(10), @mensaje VARCHAR(2100);

    BEGIN TRY
        EXEC @codigo_retorno = sys.sp_invoke_external_rest_endpoint
             @url = @url, @method = N'GET', @timeout = 60, @response = @respuesta OUTPUT;
    END TRY
    BEGIN CATCH
        SET @mensaje = 'No se pudo invocar ' + CAST(@url AS VARCHAR(1000)) + ': ' + ERROR_MESSAGE();
        THROW 50003, @mensaje, 1;
    END CATCH;

    SET @codigo_http = JSON_VALUE(@respuesta, '$.response.status.http.code');
    IF @codigo_retorno <> 0 OR ISNULL(@codigo_http, '') NOT LIKE '2%'
    BEGIN
        SET @mensaje = 'La API respondió con código HTTP ' + ISNULL(@codigo_http, '(desconocido)')
                     + ': ' + CAST(@url AS VARCHAR(1000));
        THROW 50003, @mensaje, 1;
    END;

    SET @resultado = JSON_QUERY(@respuesta, '$.result');
    IF @resultado IS NULL
        THROW 50003, 'La respuesta de la API no trae un cuerpo JSON.', 1;
END;
GO

/* Lee un archivo de texto UTF-8 completo (JSON). Se lee en binario y se vuelca en una
 columna con collation UTF-8, que interpreta esos bytes como UTF-8; después se pasa a
 NVARCHAR, el tipo que espera OPENJSON. */

CREATE OR ALTER PROCEDURE importacion.archivo_leer_texto
    @ruta_archivo VARCHAR(500),
    @texto        NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX), @mensaje VARCHAR(2100);

    IF NULLIF(LTRIM(RTRIM(@ruta_archivo)), '') IS NULL
        THROW 50003, 'Debe indicarse la ruta del archivo a importar.', 1;

    CREATE TABLE #contenido (texto VARCHAR(MAX) COLLATE Latin1_General_100_CI_AI_SC_UTF8);
    SET @sql = N'INSERT INTO #contenido (texto) SELECT BulkColumn FROM OPENROWSET(BULK '''
             + REPLACE(@ruta_archivo, '''', '''''') + N''', SINGLE_BLOB) AS archivo;';
    BEGIN TRY
        EXEC (@sql);
    END TRY
    BEGIN CATCH
        SET @mensaje = 'No se pudo leer el archivo ' + @ruta_archivo
                     + ' (revisar la ruta y los permisos del servicio de SQL Server): ' + ERROR_MESSAGE();
        THROW 50003, @mensaje, 1;
    END CATCH;

    SELECT @texto = CAST(texto AS NVARCHAR(MAX)) FROM #contenido;
    IF LEFT(@texto, 1) = NCHAR(65279) SET @texto = STUFF(@texto, 1, 1, N'');   -- BOM
END;
GO

-- Lee un archivo XML. El tipo XML resuelve solo la codificación declarada en el archivo.

CREATE OR ALTER PROCEDURE importacion.archivo_leer_xml
    @ruta_archivo VARCHAR(500),
    @contenido    XML OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @sql NVARCHAR(MAX), @mensaje VARCHAR(2100);

    IF NULLIF(LTRIM(RTRIM(@ruta_archivo)), '') IS NULL
        THROW 50003, 'Debe indicarse la ruta del archivo a importar.', 1;

    SET @sql = N'SELECT @x = CAST(BulkColumn AS XML) FROM OPENROWSET(BULK '''
             + REPLACE(@ruta_archivo, '''', '''''') + N''', SINGLE_BLOB) AS archivo;';
    BEGIN TRY
        EXEC sp_executesql @sql, N'@x XML OUTPUT', @x = @contenido OUTPUT;
    END TRY
    BEGIN CATCH
        SET @mensaje = 'No se pudo leer el archivo ' + @ruta_archivo
                     + ' como XML (revisar la ruta, los permisos y que sea un XML bien formado): ' + ERROR_MESSAGE();
        THROW 50003, @mensaje, 1;
    END CATCH;
END;
GO

/* Convierte un monto a dólares con la cotización de publicidad.tipo_cambio más cercana a
 la fecha indicada (la API se importa en base USD; si sólo hubiera cotizaciones en base
 EUR se hace el cruce EUR -> moneda -> USD). Sin cotización registrada: THROW 50004. */

CREATE OR ALTER PROCEDURE publicidad.convertir_moneda
    @monto     NUMERIC(14,2),
    @moneda    VARCHAR(3),
    @fecha     DATE,
    @monto_usd NUMERIC(14,2) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @tasa NUMERIC(18,8), @tasa_eur_moneda NUMERIC(18,8), @tasa_eur_usd NUMERIC(18,8),
            @mensaje VARCHAR(300);
    SET @fecha = ISNULL(@fecha, CAST(SYSDATETIME() AS DATE));
    SET @moneda = UPPER(@moneda);

    IF @moneda = 'USD'
    BEGIN
        SET @monto_usd = @monto;
        RETURN;
    END;

    SELECT TOP 1 @tasa = tipo_cambio
    FROM publicidad.tipo_cambio
    WHERE moneda_base = 'USD' AND moneda_cotizada = @moneda
    ORDER BY ABS(DATEDIFF(DAY, fecha, @fecha)), fecha DESC;

    IF @tasa IS NULL
    BEGIN
        SELECT TOP 1 @tasa_eur_moneda = m.tipo_cambio, @tasa_eur_usd = u.tipo_cambio
        FROM publicidad.tipo_cambio m
        JOIN publicidad.tipo_cambio u ON u.fecha = m.fecha AND u.moneda_base = 'EUR' AND u.moneda_cotizada = 'USD'
        WHERE m.moneda_base = 'EUR' AND m.moneda_cotizada = @moneda
        ORDER BY ABS(DATEDIFF(DAY, m.fecha, @fecha)), m.fecha DESC;
        IF @moneda = 'EUR' SELECT TOP 1 @tasa_eur_moneda = 1, @tasa_eur_usd = tipo_cambio
                           FROM publicidad.tipo_cambio
                           WHERE moneda_base = 'EUR' AND moneda_cotizada = 'USD'
                           ORDER BY ABS(DATEDIFF(DAY, fecha, @fecha)), fecha DESC;
        IF @tasa_eur_moneda IS NOT NULL SET @tasa = @tasa_eur_moneda / @tasa_eur_usd;
    END;

    IF @tasa IS NULL
    BEGIN
        SET @mensaje = '- No hay cotización registrada para la moneda ' + ISNULL(@moneda, '(nula)')
                     + ' (se importan con publicidad.consultar_api_frankfurter).';
        THROW 50004, @mensaje, 1;
    END;

    SET @monto_usd = ROUND(@monto / @tasa, 2);
END;
GO


-- ============================================================
-- 5. IMPORTACIÓN DE ARCHIVOS: CSV, JSON Y XML
-- ============================================================

/* teams.csv del dataset público de Kaggle creado por swaptr (datos de FBref):
 Fuente: https://www.kaggle.com/datasets/swaptr/fifa-wc-2026-matches
 Procesado tal cual se publica: 136 columnas con estadísticas agregadas de juego por
 selección (posesión, tiros, faltas, tarjetas, atajadas...). Clave natural: selección
 (resuelta a partir de team_country). */

CREATE OR ALTER PROCEDURE torneo.importar_estadisticas_equipos_kaggle_2026
    @ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @lote_id INT, @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @i INT = 1, @registro VARCHAR(1000),
            @pais_equipo VARCHAR(100), @seleccion_id INT;

    -- Las 136 columnas del archivo teams.csv en su orden original.
    CREATE TABLE #archivo_equipos (
        [team] VARCHAR(4000), [team_country] VARCHAR(4000), [players_used] VARCHAR(4000), [avg_age] VARCHAR(4000),
        [possession] VARCHAR(4000), [games] VARCHAR(4000), [games_starts] VARCHAR(4000), [minutes] VARCHAR(4000),
        [minutes_90s] VARCHAR(4000), [goals] VARCHAR(4000), [assists] VARCHAR(4000), [goals_assists] VARCHAR(4000),
        [goals_pens] VARCHAR(4000), [pens_made] VARCHAR(4000), [pens_att] VARCHAR(4000), [cards_yellow] VARCHAR(4000),
        [cards_red] VARCHAR(4000), [goals_per90] VARCHAR(4000), [assists_per90] VARCHAR(4000), [goals_assists_per90] VARCHAR(4000),
        [goals_pens_per90] VARCHAR(4000), [goals_assists_pens_per90] VARCHAR(4000), [players_used_against] VARCHAR(4000), [avg_age_against] VARCHAR(4000),
        [possession_against] VARCHAR(4000), [games_against] VARCHAR(4000), [games_starts_against] VARCHAR(4000), [minutes_against] VARCHAR(4000),
        [minutes_90s_against] VARCHAR(4000), [goals_against] VARCHAR(4000), [assists_against] VARCHAR(4000), [goals_assists_against] VARCHAR(4000),
        [goals_pens_against] VARCHAR(4000), [pens_made_against] VARCHAR(4000), [pens_att_against] VARCHAR(4000), [cards_yellow_against] VARCHAR(4000),
        [cards_red_against] VARCHAR(4000), [goals_per90_against] VARCHAR(4000), [assists_per90_against] VARCHAR(4000), [goals_assists_per90_against] VARCHAR(4000),
        [goals_pens_per90_against] VARCHAR(4000), [goals_assists_pens_per90_against] VARCHAR(4000), [shots] VARCHAR(4000), [shots_on_target] VARCHAR(4000),
        [shots_on_target_pct] VARCHAR(4000), [shots_per90] VARCHAR(4000), [shots_on_target_per90] VARCHAR(4000), [goals_per_shot] VARCHAR(4000),
        [goals_per_shot_on_target] VARCHAR(4000), [shots_against] VARCHAR(4000), [shots_on_target_against] VARCHAR(4000), [shots_on_target_pct_against] VARCHAR(4000),
        [shots_per90_against] VARCHAR(4000), [shots_on_target_per90_against] VARCHAR(4000), [goals_per_shot_against] VARCHAR(4000), [goals_per_shot_on_target_against] VARCHAR(4000),
        [minutes_per_game] VARCHAR(4000), [minutes_pct] VARCHAR(4000), [minutes_per_start] VARCHAR(4000), [games_complete] VARCHAR(4000),
        [games_subs] VARCHAR(4000), [minutes_per_sub] VARCHAR(4000), [unused_subs] VARCHAR(4000), [points_per_game] VARCHAR(4000),
        [on_goals_for] VARCHAR(4000), [on_goals_against] VARCHAR(4000), [plus_minus] VARCHAR(4000), [plus_minus_per90] VARCHAR(4000),
        [minutes_per_game_against] VARCHAR(4000), [minutes_pct_against] VARCHAR(4000), [minutes_per_start_against] VARCHAR(4000), [games_complete_against] VARCHAR(4000),
        [games_subs_against] VARCHAR(4000), [minutes_per_sub_against] VARCHAR(4000), [unused_subs_against] VARCHAR(4000), [points_per_game_against] VARCHAR(4000),
        [on_goals_for_against] VARCHAR(4000), [on_goals_against_against] VARCHAR(4000), [plus_minus_against] VARCHAR(4000), [plus_minus_per90_against] VARCHAR(4000),
        [cards_yellow_red] VARCHAR(4000), [fouls] VARCHAR(4000), [fouled] VARCHAR(4000), [offsides] VARCHAR(4000),
        [crosses] VARCHAR(4000), [interceptions] VARCHAR(4000), [tackles_won] VARCHAR(4000), [pens_won] VARCHAR(4000),
        [pens_conceded] VARCHAR(4000), [own_goals] VARCHAR(4000), [cards_yellow_red_against] VARCHAR(4000), [fouls_against] VARCHAR(4000),
        [fouled_against] VARCHAR(4000), [offsides_against] VARCHAR(4000), [crosses_against] VARCHAR(4000), [interceptions_against] VARCHAR(4000),
        [tackles_won_against] VARCHAR(4000), [pens_won_against] VARCHAR(4000), [pens_conceded_against] VARCHAR(4000), [own_goals_against] VARCHAR(4000),
        [gk_games] VARCHAR(4000), [gk_games_starts] VARCHAR(4000), [gk_minutes] VARCHAR(4000), [gk_goals_against] VARCHAR(4000),
        [gk_goals_against_per90] VARCHAR(4000), [gk_shots_on_target_against] VARCHAR(4000), [gk_saves] VARCHAR(4000), [gk_save_pct] VARCHAR(4000),
        [gk_wins] VARCHAR(4000), [gk_ties] VARCHAR(4000), [gk_losses] VARCHAR(4000), [gk_clean_sheets] VARCHAR(4000),
        [gk_clean_sheets_pct] VARCHAR(4000), [gk_pens_att] VARCHAR(4000), [gk_pens_allowed] VARCHAR(4000), [gk_pens_saved] VARCHAR(4000),
        [gk_pens_missed] VARCHAR(4000), [gk_pens_save_pct] VARCHAR(4000), [gk_games_against] VARCHAR(4000), [gk_games_starts_against] VARCHAR(4000),
        [gk_minutes_against] VARCHAR(4000), [gk_goals_against_against] VARCHAR(4000), [gk_goals_against_per90_against] VARCHAR(4000), [gk_shots_on_target_against_against] VARCHAR(4000),
        [gk_saves_against] VARCHAR(4000), [gk_save_pct_against] VARCHAR(4000), [gk_wins_against] VARCHAR(4000), [gk_ties_against] VARCHAR(4000),
        [gk_losses_against] VARCHAR(4000), [gk_clean_sheets_against] VARCHAR(4000), [gk_clean_sheets_pct_against] VARCHAR(4000), [gk_pens_att_against] VARCHAR(4000),
        [gk_pens_allowed_against] VARCHAR(4000), [gk_pens_saved_against] VARCHAR(4000), [gk_pens_missed_against] VARCHAR(4000), [gk_pens_save_pct_against] VARCHAR(4000)
    );

    EXEC importacion.lote_abrir 'torneo.importar_estadisticas_equipos_kaggle_2026', @ruta_archivo, @lote_id OUTPUT;
    BEGIN TRY
        EXEC importacion.archivo_cargar_csv @ruta_archivo, '#archivo_equipos';
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    SELECT IDENTITY(INT, 1, 1) AS fila,
           NULLIF(LTRIM(RTRIM(team_country)), '') AS pais_equipo,
           TRY_CONVERT(INT, NULLIF(players_used, '')) AS jugadores_usados,
           TRY_CONVERT(NUMERIC(5,1), NULLIF(avg_age, '')) AS edad_promedio,
           TRY_CONVERT(NUMERIC(5,1), NULLIF(possession, '')) AS posesion,
           TRY_CONVERT(INT, NULLIF(games, '')) AS partidos,
           TRY_CONVERT(INT, NULLIF(minutes, '')) AS minutos,
           TRY_CONVERT(INT, NULLIF(goals, '')) AS goles,
           TRY_CONVERT(INT, NULLIF(assists, '')) AS asistencias,
           TRY_CONVERT(INT, NULLIF(goals_pens, '')) AS goles_penal,
           TRY_CONVERT(INT, NULLIF(cards_yellow, '')) AS amarillas,
           TRY_CONVERT(INT, NULLIF(cards_red, '')) AS rojas,
           TRY_CONVERT(INT, NULLIF(shots, '')) AS tiros,
           TRY_CONVERT(INT, NULLIF(shots_on_target, '')) AS tiros_al_arco,
           TRY_CONVERT(INT, NULLIF(fouls, '')) AS faltas,
           TRY_CONVERT(INT, NULLIF(offsides, '')) AS offsides,
           TRY_CONVERT(INT, NULLIF(gk_saves, '')) AS atajadas,
           TRY_CONVERT(INT, NULLIF(gk_clean_sheets, '')) AS vallas_invictas,
           CASE WHEN (NULLIF(players_used, '') IS NOT NULL AND TRY_CONVERT(INT, players_used) IS NULL)
                  OR (NULLIF(avg_age, '') IS NOT NULL AND TRY_CONVERT(NUMERIC(5,1), avg_age) IS NULL)
                  OR (NULLIF(possession, '') IS NOT NULL AND TRY_CONVERT(NUMERIC(5,1), possession) IS NULL)
                  OR (NULLIF(games, '') IS NOT NULL AND TRY_CONVERT(INT, games) IS NULL)
                  OR (NULLIF(minutes, '') IS NOT NULL AND TRY_CONVERT(INT, minutes) IS NULL)
                  OR (NULLIF(goals, '') IS NOT NULL AND TRY_CONVERT(INT, goals) IS NULL)
                  OR (NULLIF(assists, '') IS NOT NULL AND TRY_CONVERT(INT, assists) IS NULL)
                  OR (NULLIF(cards_yellow, '') IS NOT NULL AND TRY_CONVERT(INT, cards_yellow) IS NULL)
                  OR (NULLIF(cards_red, '') IS NOT NULL AND TRY_CONVERT(INT, cards_red) IS NULL)
                  OR (NULLIF(shots, '') IS NOT NULL AND TRY_CONVERT(INT, shots) IS NULL)
                THEN 0 ELSE 1 END AS numeros_ok
    INTO #equipos
    FROM #archivo_equipos;

    SELECT @leidos = COUNT(*) FROM #equipos;

    WHILE @i <= @leidos
    BEGIN
        SELECT @pais_equipo = pais_equipo, @registro = CONCAT(pais_equipo, ' | PJ ', partidos, ' | Goles ', goles),
               @errores = '', @seleccion_id = NULL
        FROM #equipos WHERE fila = @i;

        BEGIN TRY
            SET @seleccion_id = importacion.fn_seleccion_id(@pais_equipo);
            IF @seleccion_id IS NULL
                SET @errores += '- El país ''' + ISNULL(@pais_equipo, '') + ''' no tiene una selección registrada.' + @nl;
            IF EXISTS (SELECT 1 FROM #equipos WHERE fila = @i AND numeros_ok = 0)
                SET @errores += '- Uno o más datos numéricos tienen formato inválido.' + @nl;
            IF EXISTS (SELECT 1 FROM #equipos WHERE fila = @i AND (partidos < 0 OR minutos < 0 OR goles < 0))
                SET @errores += '- Los partidos, minutos y goles no pueden ser negativos.' + @nl;
            IF @errores <> ''
            BEGIN
                SET @errores = 'Fila rechazada:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            IF NOT EXISTS (SELECT 1 FROM torneo.seleccion_estadistica_kaggle WHERE seleccion_id = @seleccion_id)
            BEGIN
                INSERT INTO torneo.seleccion_estadistica_kaggle (
                    seleccion_id, pais_equipo, jugadores_usados, edad_promedio, posesion, partidos, minutos,
                    goles, asistencias, goles_penal, amarillas, rojas, tiros, tiros_al_arco, faltas, offsides,
                    atajadas, vallas_invictas, archivo_origen)
                SELECT @seleccion_id, pais_equipo, jugadores_usados, edad_promedio, posesion, partidos, minutos,
                       goles, asistencias, goles_penal, amarillas, rojas, tiros, tiros_al_arco, faltas, offsides,
                       atajadas, vallas_invictas, @ruta_archivo
                FROM #equipos WHERE fila = @i;
                SET @insertados += 1;
            END
            ELSE IF EXISTS (SELECT pais_equipo COLLATE DATABASE_DEFAULT, jugadores_usados, edad_promedio, posesion,
                                   partidos, minutos, goles, asistencias, goles_penal, amarillas, rojas, tiros,
                                   tiros_al_arco, faltas, offsides, atajadas, vallas_invictas
                            FROM #equipos WHERE fila = @i
                            EXCEPT
                            SELECT pais_equipo, jugadores_usados, edad_promedio, posesion, partidos, minutos, goles,
                                   asistencias, goles_penal, amarillas, rojas, tiros, tiros_al_arco, faltas, offsides,
                                   atajadas, vallas_invictas
                            FROM torneo.seleccion_estadistica_kaggle WHERE seleccion_id = @seleccion_id)
            BEGIN
                UPDATE e
                SET pais_equipo = eq.pais_equipo, jugadores_usados = eq.jugadores_usados,
                    edad_promedio = eq.edad_promedio, posesion = eq.posesion, partidos = eq.partidos,
                    minutos = eq.minutos, goles = eq.goles, asistencias = eq.asistencias,
                    goles_penal = eq.goles_penal, amarillas = eq.amarillas, rojas = eq.rojas,
                    tiros = eq.tiros, tiros_al_arco = eq.tiros_al_arco, faltas = eq.faltas,
                    offsides = eq.offsides, atajadas = eq.atajadas, vallas_invictas = eq.vallas_invictas,
                    archivo_origen = @ruta_archivo, importado_en = SYSDATETIMEOFFSET()
                FROM torneo.seleccion_estadistica_kaggle e
                JOIN #equipos eq ON eq.fila = @i
                WHERE e.seleccion_id = @seleccion_id;
                SET @actualizados += 1;
            END
            ELSE
                SET @sin_cambios += 1;
        END TRY
        BEGIN CATCH
            SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
            EXEC importacion.error_registrar @lote_id, @i, @registro, @numero, @mensaje;
            SET @rechazados += 1;
        END CATCH;

        SET @i += 1;
    END;

    EXEC importacion.lote_cerrar @lote_id, @leidos, @insertados, @actualizados, @sin_cambios, @rechazados;
END;
GO

/* players.csv del dataset https://www.kaggle.com/datasets/swaptr/fifa-wc-2026-players
 (datos de FBref), procesado tal cual se publica: 72 columnas, campos entre comillas.
 Estadísticas por jugador que el modelo no tiene como columnas (minutos, goles, tarjetas).
 Clave natural: país + nombre del jugador. La fila se vincula a la selección del modelo
 (si el país no tiene selección, se rechaza) y, si el nombre coincide con un convocado de
 esa selección, también al jugador. Reimportar sin cambios no modifica nada. */

CREATE OR ALTER PROCEDURE plantel.importar_estadisticas_jugadores_kaggle_2026
    @ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @lote_id INT, @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @sin_jugador INT = 0, @i INT = 1,
            @registro VARCHAR(1000), @jugador VARCHAR(120), @pais_equipo VARCHAR(100), @seleccion_id INT,
            @jugador_id INT, @id INT;

    -- Las 72 columnas del archivo, en su orden original.
    CREATE TABLE #archivo (
        jugador VARCHAR(4000), equipo VARCHAR(4000), pais_equipo VARCHAR(4000), posicion VARCHAR(4000),
        edad VARCHAR(4000), anio_nacimiento VARCHAR(4000), club VARCHAR(4000), partidos VARCHAR(4000),
        titularidades VARCHAR(4000), minutos VARCHAR(4000), minutos_90s VARCHAR(4000), goles VARCHAR(4000),
        asistencias VARCHAR(4000), goles_asistencias VARCHAR(4000), goles_penal VARCHAR(4000),
        penales_convertidos VARCHAR(4000), penales_ejecutados VARCHAR(4000), amarillas VARCHAR(4000),
        rojas VARCHAR(4000), goles_por_90 VARCHAR(4000), asistencias_por_90 VARCHAR(4000),
        goles_asistencias_por_90 VARCHAR(4000), goles_penal_por_90 VARCHAR(4000),
        goles_asistencias_penal_por_90 VARCHAR(4000), tiros VARCHAR(4000), tiros_arco VARCHAR(4000),
        pct_tiros_arco VARCHAR(4000), tiros_por_90 VARCHAR(4000), tiros_arco_por_90 VARCHAR(4000),
        goles_por_tiro VARCHAR(4000), goles_por_tiro_arco VARCHAR(4000), minutos_por_partido VARCHAR(4000),
        pct_minutos VARCHAR(4000), minutos_por_titularidad VARCHAR(4000), partidos_completos VARCHAR(4000),
        partidos_suplente VARCHAR(4000), minutos_por_cambio VARCHAR(4000), suplencias_sin_ingreso VARCHAR(4000),
        puntos_por_partido VARCHAR(4000), goles_equipo_con_jugador VARCHAR(4000),
        goles_rival_con_jugador VARCHAR(4000), diferencia_goles VARCHAR(4000), diferencia_goles_por_90 VARCHAR(4000),
        diferencia_goles_wowy VARCHAR(4000), amarillas_rojas VARCHAR(4000), faltas VARCHAR(4000),
        faltas_recibidas VARCHAR(4000), offsides VARCHAR(4000), centros VARCHAR(4000), intercepciones VARCHAR(4000),
        tackles_ganados VARCHAR(4000), penales_recibidos VARCHAR(4000), penales_cometidos VARCHAR(4000),
        goles_en_contra VARCHAR(4000), partidos_arquero VARCHAR(4000), titularidades_arquero VARCHAR(4000),
        minutos_arquero VARCHAR(4000), goles_contra_arquero VARCHAR(4000), goles_contra_por_90 VARCHAR(4000),
        tiros_arco_recibidos VARCHAR(4000), atajadas VARCHAR(4000), pct_atajadas VARCHAR(4000),
        victorias_arquero VARCHAR(4000), empates_arquero VARCHAR(4000), derrotas_arquero VARCHAR(4000),
        vallas_invictas VARCHAR(4000), pct_vallas_invictas VARCHAR(4000), penales_recibidos_arquero VARCHAR(4000),
        penales_concedidos VARCHAR(4000), penales_atajados VARCHAR(4000), penales_errados VARCHAR(4000),
        pct_penales_atajados VARCHAR(4000)
    );

    EXEC importacion.lote_abrir 'plantel.importar_estadisticas_jugadores_kaggle_2026', @ruta_archivo, @lote_id OUTPUT;
    BEGIN TRY
        EXEC importacion.archivo_cargar_csv @ruta_archivo, '#archivo';
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    -- Conversión de tipos por conjunto; numeros_ok marca si los textos que venían convirtieron.
    SELECT IDENTITY(INT, 1, 1) AS fila,
           NULLIF(LTRIM(RTRIM(jugador)), '') AS jugador, NULLIF(LTRIM(RTRIM(pais_equipo)), '') AS pais_equipo,
           LEFT(NULLIF(posicion, ''), 10) AS posicion, TRY_CONVERT(INT, NULLIF(edad, '')) AS edad,
           TRY_CONVERT(INT, NULLIF(anio_nacimiento, '')) AS anio_nacimiento, LEFT(NULLIF(club, ''), 120) AS club,
           TRY_CONVERT(INT, NULLIF(partidos, '')) AS partidos, TRY_CONVERT(INT, NULLIF(titularidades, '')) AS titularidades,
           TRY_CONVERT(NUMERIC(10,1), NULLIF(minutos, '')) AS minutos, TRY_CONVERT(NUMERIC(8,1), NULLIF(goles, '')) AS goles,
           TRY_CONVERT(NUMERIC(8,1), NULLIF(asistencias, '')) AS asistencias,
           TRY_CONVERT(NUMERIC(8,1), NULLIF(amarillas, '')) AS amarillas, TRY_CONVERT(NUMERIC(8,1), NULLIF(rojas, '')) AS rojas,
           TRY_CONVERT(NUMERIC(8,1), NULLIF(goles_penal, '')) AS goles_penal,
           TRY_CONVERT(NUMERIC(8,1), NULLIF(goles_en_contra, '')) AS goles_en_contra,
           CASE WHEN (NULLIF(edad, '') IS NOT NULL AND TRY_CONVERT(INT, edad) IS NULL)
                  OR (NULLIF(anio_nacimiento, '') IS NOT NULL AND TRY_CONVERT(INT, anio_nacimiento) IS NULL)
                  OR (NULLIF(partidos, '') IS NOT NULL AND TRY_CONVERT(INT, partidos) IS NULL)
                  OR (NULLIF(titularidades, '') IS NOT NULL AND TRY_CONVERT(INT, titularidades) IS NULL)
                  OR (NULLIF(minutos, '') IS NOT NULL AND TRY_CONVERT(NUMERIC(10,1), minutos) IS NULL)
                  OR (NULLIF(goles, '') IS NOT NULL AND TRY_CONVERT(NUMERIC(8,1), goles) IS NULL)
                  OR (NULLIF(asistencias, '') IS NOT NULL AND TRY_CONVERT(NUMERIC(8,1), asistencias) IS NULL)
                  OR (NULLIF(amarillas, '') IS NOT NULL AND TRY_CONVERT(NUMERIC(8,1), amarillas) IS NULL)
                  OR (NULLIF(rojas, '') IS NOT NULL AND TRY_CONVERT(NUMERIC(8,1), rojas) IS NULL)
                THEN 0 ELSE 1 END AS numeros_ok
    INTO #jugadores
    FROM #archivo;

    SELECT @leidos = COUNT(*) FROM #jugadores;

    WHILE @i <= @leidos
    BEGIN
        SELECT @jugador = jugador, @pais_equipo = pais_equipo, @registro = CONCAT(jugador, ' | ', pais_equipo),
               @errores = '', @id = NULL, @jugador_id = NULL
        FROM #jugadores WHERE fila = @i;

        BEGIN TRY
            SET @seleccion_id = importacion.fn_seleccion_id(@pais_equipo);
            IF @jugador IS NULL SET @errores += '- El nombre del jugador está vacío.' + @nl;
            IF @seleccion_id IS NULL
                SET @errores += '- El país ''' + ISNULL(@pais_equipo, '') + ''' no tiene una selección registrada.' + @nl;
            IF EXISTS (SELECT 1 FROM #jugadores WHERE fila = @i AND numeros_ok = 0)
                SET @errores += '- Uno o más datos numéricos tienen formato inválido.' + @nl;
            IF EXISTS (SELECT 1 FROM #jugadores WHERE fila = @i AND (edad < 0 OR partidos < 0 OR minutos < 0))
                SET @errores += '- La edad, los partidos y los minutos no pueden ser negativos.' + @nl;
            IF @errores <> ''
            BEGIN
                SET @errores = 'Fila rechazada:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            -- Jugador del modelo: convocado de esa selección con el mismo nombre completo.
            SELECT TOP 1 @jugador_id = j.jugador_id
            FROM plantel.jugador j
            JOIN plantel.convocatoria c ON c.jugador_id = j.jugador_id AND c.seleccion_id = @seleccion_id
            WHERE j.nombre + ' ' + j.apellido = @jugador OR (j.nombre = j.apellido AND j.nombre = @jugador);
            IF @jugador_id IS NULL SET @sin_jugador += 1;

            SELECT @id = jugador_estadistica_id FROM plantel.jugador_estadistica_kaggle
            WHERE pais_equipo = @pais_equipo AND jugador = @jugador;

            IF @id IS NULL
            BEGIN
                INSERT INTO plantel.jugador_estadistica_kaggle (
                    jugador, pais_equipo, seleccion_id, jugador_id, posicion_fuente, edad, anio_nacimiento, club,
                    partidos, titularidades, minutos, goles, asistencias, amarillas, rojas, goles_penal,
                    goles_en_contra, archivo_origen)
                SELECT jugador, pais_equipo, @seleccion_id, @jugador_id, posicion, edad, anio_nacimiento, club,
                       partidos, titularidades, minutos, goles, asistencias, amarillas, rojas, goles_penal,
                       goles_en_contra, @ruta_archivo
                FROM #jugadores WHERE fila = @i;
                SET @insertados += 1;
            END
            ELSE IF EXISTS (SELECT @seleccion_id, @jugador_id, posicion COLLATE DATABASE_DEFAULT, edad, anio_nacimiento,
                                   club COLLATE DATABASE_DEFAULT, partidos, titularidades, minutos, goles, asistencias,
                                   amarillas, rojas, goles_penal, goles_en_contra
                            FROM #jugadores WHERE fila = @i
                            EXCEPT
                            SELECT seleccion_id, jugador_id, posicion_fuente, edad, anio_nacimiento, club, partidos,
                                   titularidades, minutos, goles, asistencias, amarillas, rojas, goles_penal, goles_en_contra
                            FROM plantel.jugador_estadistica_kaggle WHERE jugador_estadistica_id = @id)
            BEGIN
                UPDATE e
                SET seleccion_id = @seleccion_id, jugador_id = @jugador_id, posicion_fuente = j.posicion,
                    edad = j.edad, anio_nacimiento = j.anio_nacimiento, club = j.club, partidos = j.partidos,
                    titularidades = j.titularidades, minutos = j.minutos, goles = j.goles,
                    asistencias = j.asistencias, amarillas = j.amarillas, rojas = j.rojas,
                    goles_penal = j.goles_penal, goles_en_contra = j.goles_en_contra,
                    archivo_origen = @ruta_archivo, importado_en = SYSDATETIMEOFFSET()
                FROM plantel.jugador_estadistica_kaggle e
                JOIN #jugadores j ON j.fila = @i
                WHERE e.jugador_estadistica_id = @id;
                SET @actualizados += 1;
            END
            ELSE
                SET @sin_cambios += 1;
        END TRY
        BEGIN CATCH
            SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
            EXEC importacion.error_registrar @lote_id, @i, @registro, @numero, @mensaje;
            SET @rechazados += 1;
        END CATCH;

        SET @i += 1;
    END;

    PRINT CONCAT('plantel.importar_estadisticas_jugadores_kaggle_2026: ', @sin_jugador,
                 ' filas sin un jugador del modelo con el mismo nombre (quedan vinculadas sólo a la selección).');
    EXEC importacion.lote_cerrar @lote_id, @leidos, @insertados, @actualizados, @sin_cambios, @rechazados;
END;
GO

/* worldcup.json del repositorio público openfootball (JSON):
 Fuente: https://github.com/openfootball/worldcup.json
 Cada partido trae ronda, fecha, hora local con su huso ('13:00 UTC-6'), selecciones,
 sede (la ciudad, con la localidad entre paréntesis: 'Dallas (Arlington)') y el marcador
 (ft = 90 minutos, et = alargue, p = penales).
 Clave natural: fase + local + visitante.
   * Nuevo: torneo.partido_insertar y, si ya se jugó, torneo.registrar_resultado.
   * Existente programado: se reprograma (partido_modificar) si cambió sede u horario, y
     se carga el resultado si ya lo tiene.
   * Existente finalizado: el resultado registrado no se reescribe (registro histórico);
     si el archivo trae otro resultado, la fila se rechaza. */

CREATE OR ALTER PROCEDURE torneo.importar_fixture
    @ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @lote_id INT, @json NVARCHAR(MAX), @mensaje VARCHAR(2100), @numero INT,
            @nl CHAR(2) = CHAR(13) + CHAR(10), @errores VARCHAR(2000),
            @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0, @sin_cambios INT = 0,
            @rechazados INT = 0, @i INT = 1, @registro VARCHAR(1000), @cambio BIT,
            @ronda VARCHAR(40), @fecha_txt VARCHAR(20), @hora_txt VARCHAR(20), @local_txt VARCHAR(100),
            @visitante_txt VARCHAR(100), @sede_txt VARCHAR(100), @gl_90 VARCHAR(10), @gv_90 VARCHAR(10),
            @gl_120 VARCHAR(10), @gv_120 VARCHAR(10), @pl_txt VARCHAR(10), @pv_txt VARCHAR(10),
            @fecha DATE, @hora TIME(0), @offset INT, @fase VARCHAR(13), @local_id INT, @visitante_id INT,
            @sede_id INT, @fecha_hora_local DATETIMEOFFSET, @gl INT, @gv INT, @pl INT, @pv INT,
            @partido_id INT, @estado VARCHAR(10), @sede_actual INT, @fecha_actual DATETIMEOFFSET,
            @gl_actual INT, @gv_actual INT, @pl_actual INT, @pv_actual INT;

    EXEC importacion.lote_abrir 'torneo.importar_fixture', @ruta_archivo, @lote_id OUTPUT;

    BEGIN TRY
        EXEC importacion.archivo_leer_texto @ruta_archivo, @json OUTPUT;
        IF ISJSON(@json) <> 1 OR JSON_QUERY(@json, '$.matches') IS NULL
            THROW 50003, 'El archivo no es un JSON con el arreglo "matches" (formato de openfootball).', 1;
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    SELECT CAST(m.[key] AS INT) + 1 AS fila, d.*
    INTO #partidos
    FROM OPENJSON(@json, '$.matches') m
    CROSS APPLY OPENJSON(m.value) WITH (
        ronda            VARCHAR(40)  '$.round',
        fecha            VARCHAR(20)  '$.date',
        hora             VARCHAR(20)  '$.time',
        equipo_local     VARCHAR(100) '$.team1',
        equipo_visitante VARCHAR(100) '$.team2',
        sede             VARCHAR(100) '$.ground',
        gl_90            VARCHAR(10)  '$.score.ft[0]',
        gv_90            VARCHAR(10)  '$.score.ft[1]',
        gl_120           VARCHAR(10)  '$.score.et[0]',
        gv_120           VARCHAR(10)  '$.score.et[1]',
        pl               VARCHAR(10)  '$.score.p[0]',
        pv               VARCHAR(10)  '$.score.p[1]'
    ) d;

    SELECT @leidos = COUNT(*) FROM #partidos;

    WHILE @i <= @leidos
    BEGIN
        SELECT @ronda = ronda, @fecha_txt = fecha, @hora_txt = hora, @local_txt = equipo_local,
               @visitante_txt = equipo_visitante, @sede_txt = sede, @gl_90 = gl_90, @gv_90 = gv_90,
               @gl_120 = gl_120, @gv_120 = gv_120, @pl_txt = pl, @pv_txt = pv
        FROM #partidos WHERE fila = @i;

        SET @registro = CONCAT(@fecha_txt, ' ', @hora_txt, ' | ', @local_txt, ' vs ', @visitante_txt,
                               ' | ', @ronda, ' | ', @sede_txt);
        SELECT @errores = '', @partido_id = NULL, @estado = NULL, @sede_id = NULL, @cambio = 0;

        BEGIN TRY
            SET @fecha = TRY_CONVERT(DATE, @fecha_txt, 23);
            SET @hora = TRY_CONVERT(TIME(0), LEFT(@hora_txt, 5));
            SET @offset = IIF(CHARINDEX('UTC', @hora_txt) > 0,
                              TRY_CONVERT(INT, SUBSTRING(@hora_txt, CHARINDEX('UTC', @hora_txt) + 3, 3)), NULL);
            SET @fase = CASE WHEN @ronda LIKE 'Matchday%' THEN 'grupos'
                             WHEN @ronda = 'Round of 32' THEN 'dieciseisavos'
                             WHEN @ronda = 'Round of 16' THEN 'octavos'
                             WHEN @ronda = 'Quarter-final' THEN 'cuartos'
                             WHEN @ronda = 'Semi-final' THEN 'semifinal'
                             WHEN @ronda = 'Match for third place' THEN 'tercer_puesto'
                             WHEN @ronda = 'Final' THEN 'final' END;
            SET @local_id = importacion.fn_seleccion_id(@local_txt);
            SET @visitante_id = importacion.fn_seleccion_id(@visitante_txt);
            SELECT TOP 1 @sede_id = sede_id FROM torneo.sede
            WHERE @sede_txt = ciudad OR @sede_txt LIKE ciudad + ' (%';
            SET @gl = TRY_CONVERT(INT, ISNULL(@gl_120, @gl_90));
            SET @gv = TRY_CONVERT(INT, ISNULL(@gv_120, @gv_90));
            SET @pl = TRY_CONVERT(INT, @pl_txt);
            SET @pv = TRY_CONVERT(INT, @pv_txt);

            IF @fecha IS NULL
                SET @errores += '- La fecha ''' + ISNULL(@fecha_txt, '') + ''' no tiene formato aaaa-mm-dd.' + @nl;
            IF @hora IS NULL OR @offset IS NULL
                SET @errores += '- La hora ''' + ISNULL(@hora_txt, '') + ''' no tiene el formato hh:mm UTC±h.' + @nl;
            IF @fase IS NULL
                SET @errores += '- La ronda ''' + ISNULL(@ronda, '') + ''' no corresponde a ninguna fase.' + @nl;
            IF @local_id IS NULL
                SET @errores += '- La selección ''' + ISNULL(@local_txt, '') + ''' no está registrada.' + @nl;
            IF @visitante_id IS NULL
                SET @errores += '- La selección ''' + ISNULL(@visitante_txt, '') + ''' no está registrada.' + @nl;
            IF @sede_id IS NULL
                SET @errores += '- No hay una sede registrada en ''' + ISNULL(@sede_txt, '') + '''.' + @nl;
            IF (ISNULL(@gl_90, @gl_120) IS NOT NULL AND @gl IS NULL) OR (ISNULL(@gv_90, @gv_120) IS NOT NULL AND @gv IS NULL)
               OR (@pl_txt IS NOT NULL AND @pl IS NULL) OR (@pv_txt IS NOT NULL AND @pv IS NULL)
                SET @errores += '- El marcador no es numérico.' + @nl;

            IF @errores <> ''
            BEGIN
                SET @errores = 'Fila rechazada:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            SET @fecha_hora_local = TODATETIMEOFFSET(
                DATEADD(MINUTE, DATEDIFF(MINUTE, CAST('00:00' AS TIME(0)), @hora), CAST(@fecha AS DATETIME2(0))),
                @offset * 60);

            SELECT @partido_id = partido_id, @estado = estado, @sede_actual = sede_id,
                   @fecha_actual = fecha_hora_local, @gl_actual = goles_local, @gv_actual = goles_visitante,
                   @pl_actual = penales_local, @pv_actual = penales_visitante
            FROM torneo.partido
            WHERE fase = @fase AND seleccion_local_id = @local_id AND seleccion_visitante_id = @visitante_id;

            BEGIN TRANSACTION;

            IF @partido_id IS NULL
            BEGIN
                EXEC torneo.partido_insertar @sede_id, @fecha_hora_local, @fase, @local_id, @visitante_id,
                     NULL, @partido_id OUTPUT;
                IF @gl IS NOT NULL
                    EXEC torneo.registrar_resultado @partido_id, @gl, @gv, @pl, @pv;
                SET @insertados += 1;
            END
            ELSE IF @estado = 'finalizado'
            BEGIN
                IF @sede_actual <> @sede_id OR @fecha_actual <> @fecha_hora_local
                   OR ISNULL(@gl, -1) <> @gl_actual OR ISNULL(@gv, -1) <> @gv_actual
                   OR ISNULL(@pl, -1) <> ISNULL(@pl_actual, -1) OR ISNULL(@pv, -1) <> ISNULL(@pv_actual, -1)
                BEGIN
                    SET @mensaje = '- El partido ya está finalizado ('
                                 + CAST(@gl_actual AS VARCHAR(3)) + ' a ' + CAST(@gv_actual AS VARCHAR(3))
                                 + '): el resultado y la programación registrados no se modifican.';
                    THROW 50004, @mensaje, 1;
                END;
                SET @sin_cambios += 1;
            END
            ELSE
            BEGIN
                IF @sede_actual <> @sede_id OR @fecha_actual <> @fecha_hora_local
                BEGIN
                    EXEC torneo.partido_modificar @partido_id, @sede_id, @fecha_hora_local, @fase,
                         @local_id, @visitante_id, 'programado';
                    SET @cambio = 1;
                END;
                IF @gl IS NOT NULL
                BEGIN
                    EXEC torneo.registrar_resultado @partido_id, @gl, @gv, @pl, @pv;
                    SET @cambio = 1;
                END;
                IF @cambio = 1 SET @actualizados += 1; ELSE SET @sin_cambios += 1;
            END;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            EXEC importacion.error_registrar @lote_id, @i, @registro, @numero, @mensaje;
            SET @rechazados += 1;
        END CATCH;

        SET @i += 1;
    END;

    EXEC importacion.lote_cerrar @lote_id, @leidos, @insertados, @actualizados, @sin_cambios, @rechazados;
END;
GO

/* tarifas_publicidad.xml (XML, montos en distintas monedas):
     <tarifario fecha="aaaa-mm-dd">
       <anunciante nombre="..." razon_social="..." contacto="...">
         <campania nombre="..." inicio="aaaa-mm-dd" fin="aaaa-mm-dd">
           <pais_interes codigo="ARG"/> ...
           <pieza idioma="espanol" mercado="ARG" moneda="USD" tarifa="18000.00"/> ...
 Cada pieza es una fila. Anunciante, campaña y países de interés se dan de alta si faltan
 (en la misma transacción que la pieza). La tarifa se convierte a USD con la cotización
 de la fecha de inicio de la campaña (publicidad.convertir_moneda). Clave natural de la
 pieza: campaña + idioma + mercado. */

CREATE OR ALTER PROCEDURE publicidad.importar_tarifas
    @ruta_archivo VARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @lote_id INT, @xml XML, @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @i INT = 1, @j INT, @registro VARCHAR(1000),
            @anunciante VARCHAR(150), @razon_social VARCHAR(200), @contacto VARCHAR(150), @campania VARCHAR(150),
            @inicio_txt VARCHAR(20), @fin_txt VARCHAR(20), @idioma VARCHAR(30), @mercado VARCHAR(80),
            @moneda VARCHAR(10), @tarifa_txt VARCHAR(30), @inicio DATE, @fin DATE, @tarifa NUMERIC(14,2),
            @tarifa_usd NUMERIC(14,2), @anunciante_id INT, @campania_id INT, @mercado_id INT, @pieza_id INT,
            @costo_actual NUMERIC(12,2), @inicio_actual DATE, @fin_actual DATE, @codigo VARCHAR(80), @interes_id INT;

    EXEC importacion.lote_abrir 'publicidad.importar_tarifas', @ruta_archivo, @lote_id OUTPUT;
    BEGIN TRY
        EXEC importacion.archivo_leer_xml @ruta_archivo, @xml OUTPUT;
        IF @xml.exist('/tarifario/anunciante/campania/pieza') = 0
            THROW 50003, 'El XML no tiene la estructura tarifario/anunciante/campania/pieza.', 1;
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    SELECT IDENTITY(INT, 1, 1) AS fila,
           a.n.value('@nombre', 'VARCHAR(150)')       AS anunciante,
           a.n.value('@razon_social', 'VARCHAR(200)') AS razon_social,
           a.n.value('@contacto', 'VARCHAR(150)')     AS contacto,
           c.n.value('@nombre', 'VARCHAR(150)')       AS campania,
           c.n.value('@inicio', 'VARCHAR(20)')        AS inicio,
           c.n.value('@fin', 'VARCHAR(20)')           AS fin,
           p.n.value('@idioma', 'VARCHAR(30)')        AS idioma,
           p.n.value('@mercado', 'VARCHAR(80)')       AS mercado,
           p.n.value('@moneda', 'VARCHAR(10)')        AS moneda,
           p.n.value('@tarifa', 'VARCHAR(30)')        AS tarifa
    INTO #piezas
    FROM @xml.nodes('/tarifario/anunciante') a (n)
    CROSS APPLY a.n.nodes('campania') c (n)
    CROSS APPLY c.n.nodes('pieza') p (n);

    SELECT a.n.value('@nombre', 'VARCHAR(150)') AS anunciante, c.n.value('@nombre', 'VARCHAR(150)') AS campania,
           i.n.value('@codigo', 'VARCHAR(80)') AS codigo
    INTO #intereses
    FROM @xml.nodes('/tarifario/anunciante') a (n)
    CROSS APPLY a.n.nodes('campania') c (n)
    CROSS APPLY c.n.nodes('pais_interes') i (n);

    SELECT @leidos = COUNT(*) FROM #piezas;

    WHILE @i <= @leidos
    BEGIN
        SELECT @anunciante = anunciante, @razon_social = razon_social, @contacto = contacto, @campania = campania,
               @inicio_txt = inicio, @fin_txt = fin, @idioma = idioma, @mercado = mercado, @moneda = moneda,
               @tarifa_txt = tarifa
        FROM #piezas WHERE fila = @i;
        SET @registro = CONCAT(@anunciante, ' | ', @campania, ' | ', @idioma, ' / ', @mercado, ' | ',
                               @tarifa_txt, ' ', @moneda);
        SELECT @errores = '', @anunciante_id = NULL, @campania_id = NULL, @pieza_id = NULL;

        BEGIN TRY
            SET @inicio = TRY_CONVERT(DATE, @inicio_txt, 23);
            SET @fin = TRY_CONVERT(DATE, @fin_txt, 23);
            SET @tarifa = TRY_CONVERT(NUMERIC(14,2), @tarifa_txt);
            SET @mercado_id = importacion.fn_pais_id(@mercado);

            IF NULLIF(LTRIM(RTRIM(@anunciante)), '') IS NULL OR NULLIF(LTRIM(RTRIM(@campania)), '') IS NULL
                SET @errores += '- Faltan el anunciante o el nombre de la campaña.' + @nl;
            IF @inicio IS NULL OR @fin IS NULL
                SET @errores += '- Las fechas de la campaña deben tener formato aaaa-mm-dd.' + @nl;
            IF @tarifa IS NULL
                SET @errores += '- La tarifa ''' + ISNULL(@tarifa_txt, '') + ''' no es numérica.' + @nl;
            IF @moneda IS NULL OR LEN(@moneda) <> 3 OR @moneda LIKE '%[^A-Za-z]%'
                SET @errores += '- La moneda debe ser un código ISO 4217 de tres letras.' + @nl;
            IF @mercado_id IS NULL
                SET @errores += '- El mercado ''' + ISNULL(@mercado, '') + ''' no es un país registrado.' + @nl;
            IF @errores <> ''
            BEGIN
                SET @errores = 'Fila rechazada:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            -- Transformación de moneda (THROW 50004 si no hay cotización).
            EXEC publicidad.convertir_moneda @tarifa, @moneda, @inicio, @tarifa_usd OUTPUT;

            BEGIN TRANSACTION;

            SELECT @anunciante_id = anunciante_id FROM publicidad.anunciante WHERE nombre = @anunciante;
            IF @anunciante_id IS NULL
                EXEC publicidad.anunciante_insertar @anunciante, @razon_social, @contacto, @anunciante_id OUTPUT;

            SELECT @campania_id = campania_id, @inicio_actual = fecha_inicio, @fin_actual = fecha_fin
            FROM publicidad.campania WHERE anunciante_id = @anunciante_id AND nombre = @campania;
            IF @campania_id IS NULL
                EXEC publicidad.campania_insertar @anunciante_id, @campania, @inicio, @fin, @campania_id OUTPUT;
            ELSE IF @inicio_actual <> @inicio OR @fin_actual <> @fin
                EXEC publicidad.campania_modificar @campania_id, @anunciante_id, @campania, @inicio, @fin;

            -- Países de interés de la campaña que todavía no estén registrados.
            SELECT IDENTITY(INT, 1, 1) AS orden, codigo INTO #codigos
            FROM #intereses WHERE anunciante = @anunciante AND campania = @campania;
            SET @j = 1;
            WHILE @j <= (SELECT COUNT(*) FROM #codigos)
            BEGIN
                SELECT @codigo = codigo FROM #codigos WHERE orden = @j;
                SET @interes_id = importacion.fn_pais_id(@codigo);
                IF @interes_id IS NULL
                BEGIN
                    SET @mensaje = '- El país de interés ''' + ISNULL(@codigo, '') + ''' de la campaña no está registrado.';
                    THROW 50004, @mensaje, 1;
                END;
                IF NOT EXISTS (SELECT 1 FROM publicidad.campania_pais_interes
                               WHERE campania_id = @campania_id AND pais_id = @interes_id)
                    EXEC publicidad.campania_pais_interes_insertar @campania_id, @interes_id;
                SET @j += 1;
            END;
            DROP TABLE #codigos;

            SELECT @pieza_id = pieza_id, @costo_actual = costo_tarifa
            FROM publicidad.pieza_publicitaria
            WHERE campania_id = @campania_id AND idioma = @idioma AND pais_mercado_id = @mercado_id;

            IF @pieza_id IS NULL
            BEGIN
                EXEC publicidad.pieza_publicitaria_insertar @campania_id, @idioma, @mercado_id, @tarifa_usd;
                SET @insertados += 1;
            END
            ELSE IF @costo_actual <> @tarifa_usd
            BEGIN
                EXEC publicidad.pieza_publicitaria_modificar @pieza_id, @campania_id, @idioma, @mercado_id, @tarifa_usd;
                SET @actualizados += 1;
            END
            ELSE
                SET @sin_cambios += 1;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
            IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
            IF OBJECT_ID('tempdb..#codigos') IS NOT NULL DROP TABLE #codigos;
            EXEC importacion.error_registrar @lote_id, @i, @registro, @numero, @mensaje;
            SET @rechazados += 1;
        END CATCH;

        SET @i += 1;
    END;

    EXEC importacion.lote_cerrar @lote_id, @leidos, @insertados, @actualizados, @sin_cambios, @rechazados;
END;
GO
