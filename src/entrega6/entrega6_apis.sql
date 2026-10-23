/*
 * Universidad: UNLaM
 * Materia: Bases de Datos Aplicada
 * Trabajo práctico: Sistema de registro y gestión del Mundial de Fútbol
 * Entrega: 6 - Importación de datos desde APIs
 *
 * Fuentes:
 * - Banco Mundial, indicador NY.GDP.PCAP.CD:
 *   https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD?format=json&date=2020:2025&per_page=20000
 * - Frankfurter, tipos de cambio:
 *   https://api.frankfurter.dev/v1/latest?base=EUR&symbols=USD,CAD,MXN
 *
 * Las consultas HTTP y la importación se ejecutan desde los procedimientos de este archivo.
 * Requiere SQL Server 2025 (17.x) y nivel de compatibilidad de base 130 o superior.
 * Antes de ejecutar, habilitar 'external rest endpoint enabled' y conceder
 * EXECUTE ANY EXTERNAL ENDPOINT al usuario que invoque los procedimientos.
 * Configuración del servidor (ejecutar como administrador):
 *   EXEC sp_configure 'external rest endpoint enabled', 1;
 *   RECONFIGURE WITH OVERRIDE;
 *   GRANT EXECUTE ANY EXTERNAL ENDPOINT TO [usuario];
 * Ejecutar después de la definición de tablas y SP ABM de la Entrega 5.
 */

USE mundial_2026;
GO

IF SCHEMA_ID('apis') IS NULL
    EXEC('CREATE SCHEMA apis');
GO

-- Tablas de destino y registro de errores de las importaciones.

IF OBJECT_ID('apis.indicador_economico', 'U') IS NULL
BEGIN
    CREATE TABLE apis.indicador_economico (
        pais_id           INT NOT NULL,
        codigo_indicador  VARCHAR(30) NOT NULL,
        anio              SMALLINT NOT NULL,
        valor             NUMERIC(12, 2) NOT NULL,
        fuente            VARCHAR(30) NOT NULL,
        importado_en      DATETIMEOFFSET NOT NULL
            CONSTRAINT df_indicador_economico_importado_en DEFAULT SYSDATETIMEOFFSET(),

        CONSTRAINT pk_indicador_economico
            PRIMARY KEY (pais_id, codigo_indicador, anio),
        CONSTRAINT fk_indicador_economico_pais
            FOREIGN KEY (pais_id) REFERENCES torneo.pais (pais_id),
        CONSTRAINT chk_indicador_economico_valor CHECK (valor >= 0)
    );
END;
GO

IF OBJECT_ID('apis.tipo_cambio', 'U') IS NULL
BEGIN
    CREATE TABLE apis.tipo_cambio (
        fecha             DATE NOT NULL,
        moneda_base       CHAR(3) NOT NULL,
        moneda_cotizada   CHAR(3) NOT NULL,
        tipo_cambio       NUMERIC(18, 8) NOT NULL,
        fuente            VARCHAR(30) NOT NULL,
        importado_en      DATETIMEOFFSET NOT NULL
            CONSTRAINT df_tipo_cambio_importado_en DEFAULT SYSDATETIMEOFFSET(),

        CONSTRAINT pk_tipo_cambio
            PRIMARY KEY (fecha, moneda_base, moneda_cotizada),
        CONSTRAINT chk_tipo_cambio_moneda_distinta
            CHECK (moneda_base <> moneda_cotizada),
        CONSTRAINT chk_tipo_cambio_positivo CHECK (tipo_cambio > 0)
    );
END;
GO

IF OBJECT_ID('apis.error_importacion', 'U') IS NULL
BEGIN
    CREATE TABLE apis.error_importacion (
        error_id       INT IDENTITY(1, 1) PRIMARY KEY,
        fuente         VARCHAR(30) NOT NULL,
        registro       VARCHAR(1000) NOT NULL,
        motivo         VARCHAR(1000) NOT NULL,
        fecha_error    DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
    );
END;
GO

-- 1. Importación del PBI per cápita desde el Banco Mundial

CREATE OR ALTER PROCEDURE apis.importar_pbi_banco_mundial
    @respuesta_json VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_actual INT = 1;
    DECLARE @id_maximo INT;
    DECLARE @pais_id INT;
    DECLARE @codigo_iso VARCHAR(10);
    DECLARE @nombre VARCHAR(80);
    DECLARE @huso_horario VARCHAR(10);
    DECLARE @anio SMALLINT;
    DECLARE @valor_texto VARCHAR(50);
    DECLARE @valor NUMERIC(12, 2);
    DECLARE @registro VARCHAR(1000);
    DECLARE @mensaje_error VARCHAR(1000);
    DECLARE @es_actualizacion BIT;
    DECLARE @actualiza_pais BIT;
    DECLARE @insertados INT = 0;
    DECLARE @actualizados INT = 0;
    DECLARE @rechazados INT = 0;
    DECLARE @pbi_actualizados INT = 0;

    IF @respuesta_json IS NULL OR ISJSON(@respuesta_json) <> 1
        THROW 50020, 'La respuesta del Banco Mundial no contiene JSON válido.', 1;

    IF JSON_QUERY(@respuesta_json, '$[1]') IS NULL
        THROW 50021, 'La respuesta del Banco Mundial no contiene el arreglo de datos esperado.', 1;

    DROP TABLE IF EXISTS #RespuestaBancoMundial;

    CREATE TABLE #RespuestaBancoMundial (
        fila_api INT IDENTITY(1, 1) PRIMARY KEY,
        codigo_iso VARCHAR(3) NULL,
        anio_texto VARCHAR(10) NULL,
        valor_texto VARCHAR(50) NULL
    );

    INSERT INTO #RespuestaBancoMundial (codigo_iso, anio_texto, valor_texto)
    SELECT codigo_iso, anio_texto, valor_texto
    FROM OPENJSON(@respuesta_json, '$[1]')
    WITH (
        codigo_iso VARCHAR(3) '$.countryiso3code',
        anio_texto VARCHAR(10) '$.date',
        valor_texto VARCHAR(50) '$.value'
    );

    IF NOT EXISTS (SELECT 1 FROM #RespuestaBancoMundial)
        THROW 50022, 'La respuesta del Banco Mundial no contiene registros.', 1;

    -- Se conservan todos los años recibidos para los países del torneo.
    -- La fila con el año más reciente se marca para actualizar el valor vigente de pais.
    DROP TABLE IF EXISTS #DatosBancoMundial;

    ;WITH datos_ordenados AS (
        SELECT
            r.codigo_iso,
            r.anio_texto,
            r.valor_texto,
            ROW_NUMBER() OVER (
                PARTITION BY r.codigo_iso
                ORDER BY TRY_CONVERT(SMALLINT, r.anio_texto) DESC, r.fila_api DESC
            ) AS orden_anio
        FROM #RespuestaBancoMundial r
        WHERE r.valor_texto IS NOT NULL
          AND EXISTS (
              SELECT 1
              FROM torneo.pais p
              WHERE p.codigo_iso = r.codigo_iso
          )
    )
    SELECT
        IDENTITY(INT, 1, 1) AS fila_importacion,
        codigo_iso,
        TRY_CONVERT(SMALLINT, anio_texto) AS anio,
        anio_texto,
        valor_texto,
        CAST(CASE WHEN orden_anio = 1 THEN 1 ELSE 0 END AS BIT) AS es_ultimo_anio
    INTO #DatosBancoMundial
    FROM datos_ordenados;

    IF NOT EXISTS (SELECT 1 FROM #DatosBancoMundial)
        THROW 50023, 'No hay indicadores con valor para los países registrados en el torneo.', 1;

    SELECT @id_maximo = MAX(fila_importacion)
    FROM #DatosBancoMundial;

    WHILE @id_actual <= @id_maximo
    BEGIN
        SELECT
            @codigo_iso = codigo_iso,
            @anio = anio,
            @valor_texto = valor_texto,
            @registro = 'codigo_iso=' + ISNULL(codigo_iso, '') +
                        '; anio=' + ISNULL(anio_texto, '') +
                        '; valor=' + ISNULL(valor_texto, '')
        FROM #DatosBancoMundial d
        WHERE d.fila_importacion = @id_actual;

        SET @es_actualizacion = 0;
        SET @actualiza_pais = 0;

        BEGIN TRY
            IF @anio IS NULL
                THROW 50024, 'El año del indicador no es válido.', 1;

            SET @valor = TRY_CONVERT(NUMERIC(12, 2), @valor_texto);

            IF @valor IS NULL OR @valor < 0
                THROW 50025, 'El valor del PBI per cápita no es numérico o es negativo.', 1;

            SELECT
                @pais_id = pais_id,
                @codigo_iso = codigo_iso,
                @nombre = nombre,
                @huso_horario = huso_horario
            FROM torneo.pais
            WHERE codigo_iso = @codigo_iso;

            BEGIN TRANSACTION;

            IF EXISTS (
                SELECT 1
                FROM apis.indicador_economico
                WHERE pais_id = @pais_id
                  AND codigo_indicador = 'NY.GDP.PCAP.CD'
                  AND anio = @anio
            )
            BEGIN
                UPDATE apis.indicador_economico
                SET valor = @valor,
                    fuente = 'Banco Mundial',
                    importado_en = SYSDATETIMEOFFSET()
                WHERE pais_id = @pais_id
                  AND codigo_indicador = 'NY.GDP.PCAP.CD'
                  AND anio = @anio;

                SET @es_actualizacion = 1;
            END
            ELSE
            BEGIN
                INSERT INTO apis.indicador_economico
                    (pais_id, codigo_indicador, anio, valor, fuente)
                VALUES
                    (@pais_id, 'NY.GDP.PCAP.CD', @anio, @valor, 'Banco Mundial');
            END;

            IF EXISTS (
                SELECT 1
                FROM #DatosBancoMundial
                WHERE fila_importacion = @id_actual
                  AND es_ultimo_anio = 1
            )
            BEGIN
                EXEC torneo.pais_modificar
                    @pais_id = @pais_id,
                    @codigo_iso = @codigo_iso,
                    @nombre = @nombre,
                    @huso_horario = @huso_horario,
                    @pbi_per_capita = @valor;

                SET @actualiza_pais = 1;
            END;

            COMMIT TRANSACTION;

            IF @es_actualizacion = 1
                SET @actualizados += 1;
            ELSE
                SET @insertados += 1;

            IF @actualiza_pais = 1
                SET @pbi_actualizados += 1;
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;

            SET @mensaje_error = ERROR_MESSAGE();

            INSERT INTO apis.error_importacion (fuente, registro, motivo)
            VALUES ('Banco Mundial', ISNULL(@registro, ''), @mensaje_error);

            SET @rechazados += 1;
        END CATCH;

        SET @id_actual += 1;
    END;

    SELECT
        'Banco Mundial' AS fuente,
        @insertados AS registros_insertados,
        @actualizados AS registros_actualizados,
        @pbi_actualizados AS paises_actualizados,
        @rechazados AS registros_rechazados;
END;
GO

-- 2. Importación de cotizaciones desde Frankfurter

CREATE OR ALTER PROCEDURE apis.importar_tipos_cambio_frankfurter
    @respuesta_json VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fecha DATE;
    DECLARE @moneda_base VARCHAR(10);
    DECLARE @moneda_cotizada VARCHAR(10);
    DECLARE @tipo_cambio_texto VARCHAR(50);
    DECLARE @tipo_cambio NUMERIC(18, 8);
    DECLARE @id_actual INT = 1;
    DECLARE @id_maximo INT;
    DECLARE @registro VARCHAR(1000);
    DECLARE @mensaje_error VARCHAR(1000);
    DECLARE @insertados INT = 0;
    DECLARE @actualizados INT = 0;
    DECLARE @rechazados INT = 0;
    DECLARE @es_actualizacion BIT;

    IF @respuesta_json IS NULL OR ISJSON(@respuesta_json) <> 1
        THROW 50030, 'La respuesta de Frankfurter no contiene JSON válido.', 1;

    SET @moneda_base = JSON_VALUE(@respuesta_json, '$.base');
    SET @fecha = TRY_CONVERT(DATE, JSON_VALUE(@respuesta_json, '$.date'), 23);

    IF @moneda_base IS NULL
       OR LEN(@moneda_base) <> 3
       OR @moneda_base LIKE '%[^A-Za-z]%'
        THROW 50031, 'La respuesta de Frankfurter no contiene una moneda base válida.', 1;

    IF @fecha IS NULL
        THROW 50032, 'La respuesta de Frankfurter no contiene una fecha válida.', 1;

    IF JSON_QUERY(@respuesta_json, '$.rates') IS NULL
        THROW 50033, 'La respuesta de Frankfurter no contiene el objeto de cotizaciones esperado.', 1;

    DROP TABLE IF EXISTS #DatosFrankfurter;

    CREATE TABLE #DatosFrankfurter (
        fila_importacion INT IDENTITY(1, 1) PRIMARY KEY,
        moneda_cotizada VARCHAR(10) NOT NULL,
        tipo_cambio_texto VARCHAR(50) NULL
    );

    INSERT INTO #DatosFrankfurter (moneda_cotizada, tipo_cambio_texto)
    SELECT [key], [value]
    FROM OPENJSON(@respuesta_json, '$.rates');

    IF NOT EXISTS (SELECT 1 FROM #DatosFrankfurter)
        THROW 50034, 'La respuesta de Frankfurter no contiene cotizaciones.', 1;

    SELECT @id_maximo = MAX(fila_importacion)
    FROM #DatosFrankfurter;

    WHILE @id_actual <= @id_maximo
    BEGIN
        SELECT
            @moneda_cotizada = moneda_cotizada,
            @tipo_cambio_texto = tipo_cambio_texto
        FROM #DatosFrankfurter
        WHERE fila_importacion = @id_actual;

        SET @registro = 'fecha=' + CONVERT(VARCHAR(10), @fecha, 23) +
                        '; base=' + ISNULL(@moneda_base, '') +
                        '; cotizada=' + ISNULL(@moneda_cotizada, '') +
                        '; tipo_cambio=' + ISNULL(@tipo_cambio_texto, '');
        SET @es_actualizacion = 0;

        BEGIN TRY
            IF @moneda_cotizada IS NULL
               OR LEN(@moneda_cotizada) <> 3
               OR @moneda_cotizada LIKE '%[^A-Za-z]%'
                THROW 50035, 'El código de moneda cotizada debe tener tres letras.', 1;

            IF UPPER(@moneda_cotizada) = UPPER(@moneda_base)
                THROW 50037, 'La moneda base no puede ser igual a la moneda cotizada.', 1;

            SET @tipo_cambio = TRY_CONVERT(NUMERIC(18, 8), @tipo_cambio_texto);

            IF @tipo_cambio IS NULL OR @tipo_cambio <= 0
                THROW 50038, 'La cotización no es numérica o no es positiva.', 1;

            BEGIN TRANSACTION;

            IF EXISTS (
                SELECT 1
                FROM apis.tipo_cambio
                WHERE fecha = @fecha
                  AND moneda_base = UPPER(@moneda_base)
                  AND moneda_cotizada = UPPER(@moneda_cotizada)
            )
            BEGIN
                UPDATE apis.tipo_cambio
                SET tipo_cambio = @tipo_cambio,
                    fuente = 'Frankfurter',
                    importado_en = SYSDATETIMEOFFSET()
                WHERE fecha = @fecha
                  AND moneda_base = UPPER(@moneda_base)
                  AND moneda_cotizada = UPPER(@moneda_cotizada);

                SET @es_actualizacion = 1;
            END
            ELSE
            BEGIN
                INSERT INTO apis.tipo_cambio
                    (fecha, moneda_base, moneda_cotizada, tipo_cambio, fuente)
                VALUES
                    (@fecha, UPPER(@moneda_base), UPPER(@moneda_cotizada),
                     @tipo_cambio, 'Frankfurter');
            END;

            COMMIT TRANSACTION;

            IF @es_actualizacion = 1
                SET @actualizados += 1;
            ELSE
                SET @insertados += 1;
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK TRANSACTION;

            SET @mensaje_error = ERROR_MESSAGE();

            INSERT INTO apis.error_importacion (fuente, registro, motivo)
            VALUES ('Frankfurter', ISNULL(@registro, ''), @mensaje_error);

            SET @rechazados += 1;
        END CATCH;

        SET @id_actual += 1;
    END;

    SELECT
        'Frankfurter' AS fuente,
        @insertados AS registros_insertados,
        @actualizados AS registros_actualizados,
        @rechazados AS registros_rechazados;
END;
GO

-- 3. Consulta e importación del Banco Mundial
-- Ejecución: EXEC apis.consultar_api_banco_mundial;

CREATE OR ALTER PROCEDURE apis.consultar_api_banco_mundial
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @respuesta_http NVARCHAR(MAX);
    DECLARE @respuesta_api NVARCHAR(MAX);
    DECLARE @respuesta_importacion VARCHAR(MAX);
    DECLARE @estado_http INT;
    DECLARE @mensaje_error NVARCHAR(2048);

    EXEC @estado_http = sys.sp_invoke_external_rest_endpoint
        @url = N'https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD?format=json&date=2020:2025&per_page=20000',
        @method = N'GET',
        @timeout = 60,
        @response = @respuesta_http OUTPUT;

    IF @estado_http <> 0
    BEGIN
        SET @mensaje_error =
            N'La API del Banco Mundial respondió con código HTTP ' +
            CONVERT(NVARCHAR(10), @estado_http) + N'.';
        THROW 50040, @mensaje_error, 1;
    END;

    SET @respuesta_api = JSON_QUERY(@respuesta_http, '$.result');

    IF @respuesta_api IS NULL
        THROW 50041, 'La respuesta HTTP del Banco Mundial no contiene el resultado JSON esperado.', 1;

    SET @respuesta_importacion = CONVERT(VARCHAR(MAX), @respuesta_api);

    EXEC apis.importar_pbi_banco_mundial
        @respuesta_json = @respuesta_importacion;
END;
GO

-- 4. Consulta e importación de tipos de cambio desde Frankfurter
-- Ejecución: EXEC apis.consultar_api_frankfurter;

CREATE OR ALTER PROCEDURE apis.consultar_api_frankfurter
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @respuesta_http NVARCHAR(MAX);
    DECLARE @respuesta_api NVARCHAR(MAX);
    DECLARE @respuesta_importacion VARCHAR(MAX);
    DECLARE @estado_http INT;
    DECLARE @mensaje_error NVARCHAR(2048);

    EXEC @estado_http = sys.sp_invoke_external_rest_endpoint
        @url = N'https://api.frankfurter.dev/v1/latest?base=EUR&symbols=USD,CAD,MXN',
        @method = N'GET',
        @timeout = 60,
        @response = @respuesta_http OUTPUT;

    IF @estado_http <> 0
    BEGIN
        SET @mensaje_error =
            N'La API de Frankfurter respondió con código HTTP ' +
            CONVERT(NVARCHAR(10), @estado_http) + N'.';
        THROW 50042, @mensaje_error, 1;
    END;

    SET @respuesta_api = JSON_QUERY(@respuesta_http, '$.result');

    IF @respuesta_api IS NULL
        THROW 50043, 'La respuesta HTTP de Frankfurter no contiene el resultado JSON esperado.', 1;

    SET @respuesta_importacion = CONVERT(VARCHAR(MAX), @respuesta_api);

    EXEC apis.importar_tipos_cambio_frankfurter
        @respuesta_json = @respuesta_importacion;
END;
GO
