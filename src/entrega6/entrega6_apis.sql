-- =======================================================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 6: Procesos de importación - Consumo de APIs
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Consumo de APIs desde T-SQL (sp_invoke_external_rest_endpoint, habilitado en
--   entrega6_importacion.sql):
--     torneo.consultar_api_banco_mundial -> torneo.indicador_economico y torneo.pais.pbi_per_capita
--     publicidad.consultar_api_frankfurter -> publicidad.tipo_cambio
--   Se ejecuta después de entrega6_importacion.sql y sigue su misma norma.
--
-- FUENTES (APIs) Y LÍMITES DE USO:
--   * API de Indicadores del Banco Mundial (indicador NY.GDP.PCAP.CD - PBI per cápita en USD corrientes):
--     - Endpoint: https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD?format=json&per_page=20000&date=2020:2025
--     - Límites de uso: API pública y gratuita, no requiere API key ni autenticación. No tiene
--       rate limit estricto publicado para consultas estándar; las respuestas son paginadas (50 por
--       defecto, admite per_page=20000 para traer toda la serie en una sola llamada HTTP). Publica
--       por Estado soberano (Reino Unido unificado, sin separar Inglaterra y Escocia).
--   * API Frankfurter (tipos de cambio publicados por el Banco Central Europeo):
--     - Endpoint vigente:   https://api.frankfurter.dev/v1/latest?base=USD
--     - Endpoint histórico: https://api.frankfurter.dev/v1/{aaaa-mm-dd}?base=USD
--     - Límites de uso: API pública y gratuita, sin API key ni límite de peticiones (rate limit)
--       publicado. Actualiza una vez por día hábil alrededor de las 16:00 CET y cubre ~30 monedas
--       de referencia del BCE (incluye USD, EUR, MXN, BRL, GBP, CAD, JPY, KRW, AUD, CHF; no cotiza ARS).
-- =======================================================================================

USE mundial_2026;
GO

SET QUOTED_IDENTIFIER ON;
GO

/* Se consumen desde T-SQL con sp_invoke_external_rest_endpoint:
   * Banco Mundial, indicador NY.GDP.PCAP.CD (PBI per cápita, USD corrientes). Sin clave
     ni límite publicado; respuestas paginadas (per_page hasta 20000).
   * Frankfurter (cotizaciones del Banco Central Europeo). Sin clave ni límite publicado;
     sólo días hábiles y unas 30 monedas (no cotiza ARS). */

-- ==================================================================
-- 1. Banco Mundial: PBI per cápita
-- ==================================================================

/* La respuesta es [ {metadatos}, [ {country, countryiso3code, date, value}, ... ] ].
 Se importan sólo los países registrados en el modelo (el resto se omite, no es un error).
 Clave natural: país + indicador + año. Si el año es el más reciente con valor que tiene
 registrado el país, actualiza además torneo.pais.pbi_per_capita (torneo.pais_modificar);
 importar después un año anterior no pisa el valor vigente. */

CREATE OR ALTER PROCEDURE torneo.consultar_api_banco_mundial
    @anio_desde SMALLINT = 2020,
    @anio_hasta SMALLINT = 2025
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @url NVARCHAR(4000), @respuesta_json NVARCHAR(MAX), @lote_id INT,
            @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @omitidos INT, @i INT = 1, @registro VARCHAR(1000),
            @pais_id INT, @codigo_iso CHAR(3), @nombre VARCHAR(80), @huso CHAR(6), @pbi_actual NUMERIC(12,2),
            @anio_txt VARCHAR(10), @valor_txt VARCHAR(50), @anio SMALLINT, @valor NUMERIC(14,2),
            @valor_actual NUMERIC(14,2), @es_ultimo BIT, @resultado VARCHAR(12);

    SET @url = N'https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD?format=json&per_page=20000&date='
             + CAST(@anio_desde AS NVARCHAR(4)) + N':' + CAST(@anio_hasta AS NVARCHAR(4));

    EXEC importacion.lote_abrir 'torneo.consultar_api_banco_mundial', @url, @lote_id OUTPUT;
    BEGIN TRY
        EXEC importacion.invocar_api @url, @respuesta_json OUTPUT;
        IF ISJSON(@respuesta_json) <> 1 OR JSON_QUERY(@respuesta_json, '$[1]') IS NULL
            THROW 50003, 'La respuesta del Banco Mundial no tiene el formato [metadatos, [datos]].', 1;
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    CREATE TABLE #respuesta (codigo_iso VARCHAR(3) COLLATE DATABASE_DEFAULT, anio_txt VARCHAR(10),
                             valor_txt VARCHAR(50), pais_id INT);
    INSERT INTO #respuesta (codigo_iso, anio_txt, valor_txt, pais_id)
    SELECT d.codigo_iso, d.anio_txt, d.valor_txt, p.pais_id
    FROM OPENJSON(@respuesta_json, '$[1]') WITH (
        codigo_iso VARCHAR(3)  '$.countryiso3code',
        anio_txt   VARCHAR(10) '$.date',
        valor_txt  VARCHAR(50) '$.value'
    ) d
    LEFT JOIN torneo.pais p ON p.codigo_iso = d.codigo_iso COLLATE DATABASE_DEFAULT;

    SET @omitidos = (SELECT COUNT(*) FROM #respuesta WHERE pais_id IS NULL OR valor_txt IS NULL);

    -- Se marca el año más reciente con valor de cada país.
    CREATE TABLE #datos (fila INT PRIMARY KEY, codigo_iso VARCHAR(3), anio_txt VARCHAR(10), valor_txt VARCHAR(50),
                         pais_id INT, es_ultimo BIT);
    INSERT INTO #datos (fila, codigo_iso, anio_txt, valor_txt, pais_id, es_ultimo)
    SELECT ROW_NUMBER() OVER (ORDER BY codigo_iso, anio_txt), codigo_iso, anio_txt, valor_txt, pais_id,
           IIF(ROW_NUMBER() OVER (PARTITION BY pais_id ORDER BY TRY_CONVERT(SMALLINT, anio_txt) DESC) = 1, 1, 0)
    FROM #respuesta
    WHERE pais_id IS NOT NULL AND valor_txt IS NOT NULL;

    SELECT @leidos = COUNT(*) FROM #datos;

    WHILE @i <= @leidos
    BEGIN
        SELECT @pais_id = pais_id, @anio_txt = anio_txt, @valor_txt = valor_txt, @es_ultimo = es_ultimo,
               @registro = CONCAT(codigo_iso, ' | ', anio_txt, ' | ', valor_txt)
        FROM #datos WHERE fila = @i;
        SELECT @errores = '', @valor_actual = NULL, @resultado = 'sin_cambios';

        BEGIN TRY
            SET @anio = TRY_CONVERT(SMALLINT, @anio_txt);
            SET @valor = TRY_CONVERT(NUMERIC(14,2), TRY_CONVERT(FLOAT, @valor_txt));
            IF @anio IS NULL
                SET @errores += '- El año ''' + ISNULL(@anio_txt, '') + ''' no es válido.' + @nl;
            IF @valor IS NULL OR @valor < 0
                SET @errores += '- El valor ''' + ISNULL(@valor_txt, '') + ''' no es un número positivo.' + @nl;
            IF @errores <> ''
            BEGIN
                SET @errores = 'Registro rechazado:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            BEGIN TRANSACTION;

            SELECT @valor_actual = valor FROM torneo.indicador_economico
            WHERE pais_id = @pais_id AND codigo_indicador = 'NY.GDP.PCAP.CD' AND anio = @anio;

            IF @valor_actual IS NULL
            BEGIN
                INSERT INTO torneo.indicador_economico (pais_id, codigo_indicador, anio, valor, fuente)
                VALUES (@pais_id, 'NY.GDP.PCAP.CD', @anio, @valor, 'Banco Mundial');
                SET @resultado = 'insertado';
            END
            ELSE IF @valor_actual <> @valor
            BEGIN
                UPDATE torneo.indicador_economico
                SET valor = @valor, importado_en = SYSDATETIMEOFFSET()
                WHERE pais_id = @pais_id AND codigo_indicador = 'NY.GDP.PCAP.CD' AND anio = @anio;
                SET @resultado = 'actualizado';
            END;

            -- Sólo el año más reciente registrado del país pasa a ser su PBI vigente.
            IF @es_ultimo = 1
               AND NOT EXISTS (SELECT 1 FROM torneo.indicador_economico
                               WHERE pais_id = @pais_id AND codigo_indicador = 'NY.GDP.PCAP.CD' AND anio > @anio)
            BEGIN
                SELECT @codigo_iso = codigo_iso, @nombre = nombre, @huso = huso_horario, @pbi_actual = pbi_per_capita
                FROM torneo.pais WHERE pais_id = @pais_id;
                IF ISNULL(@pbi_actual, -1) <> @valor
                BEGIN
                    EXEC torneo.pais_modificar @pais_id, @codigo_iso, @nombre, @huso, @valor;
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

    PRINT CONCAT('torneo.consultar_api_banco_mundial: ', @omitidos,
                 ' registros omitidos (países que el modelo no registra o años sin dato).');
    EXEC importacion.lote_cerrar @lote_id, @leidos, @insertados, @actualizados, @sin_cambios, @rechazados;
END;
GO

-- ==================================================================
-- 2. Frankfurter: tipos de cambio
-- ==================================================================

/* La respuesta es { "amount": 1, "base": "USD", "date": "aaaa-mm-dd", "rates": { "EUR": 0.89, ... } }.
 Clave natural: fecha + moneda base + moneda cotizada (se conserva la historia de cada día).
 @fecha NULL = cotización más reciente. Para un día no hábil la API devuelve el anterior. */

CREATE OR ALTER PROCEDURE publicidad.consultar_api_frankfurter
    @fecha DATE = NULL,
    @base  CHAR(3) = 'USD'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @url NVARCHAR(4000), @respuesta_json NVARCHAR(MAX), @lote_id INT,
            @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @i INT = 1, @registro VARCHAR(1000),
            @fecha_resp DATE, @base_resp VARCHAR(10), @moneda VARCHAR(10), @tasa_txt VARCHAR(50),
            @tasa NUMERIC(18,8), @tasa_actual NUMERIC(18,8);

    SET @url = N'https://api.frankfurter.dev/v1/' + ISNULL(CONVERT(NVARCHAR(10), @fecha, 23), N'latest')
             + N'?base=' + UPPER(@base);

    EXEC importacion.lote_abrir 'publicidad.consultar_api_frankfurter', @url, @lote_id OUTPUT;
    BEGIN TRY
        EXEC importacion.invocar_api @url, @respuesta_json OUTPUT;
        IF ISJSON(@respuesta_json) <> 1
            THROW 50003, 'La respuesta de Frankfurter no es un JSON válido.', 1;
        SET @base_resp = UPPER(JSON_VALUE(@respuesta_json, '$.base'));
        SET @fecha_resp = TRY_CONVERT(DATE, JSON_VALUE(@respuesta_json, '$.date'), 23);
        IF @base_resp IS NULL OR LEN(@base_resp) <> 3 OR @base_resp LIKE '%[^A-Z]%'
            THROW 50003, 'La respuesta de Frankfurter no trae una moneda base válida.', 1;
        IF @fecha_resp IS NULL
            THROW 50003, 'La respuesta de Frankfurter no trae una fecha válida.', 1;
        IF JSON_QUERY(@respuesta_json, '$.rates') IS NULL
            THROW 50003, 'La respuesta de Frankfurter no trae el objeto "rates".', 1;
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    -- [key] y [value] de OPENJSON vienen con collation BIN2: se pasan a la de la base.
    SELECT IDENTITY(INT, 1, 1) AS fila, CAST([key] AS VARCHAR(10)) COLLATE DATABASE_DEFAULT AS moneda,
           CAST([value] AS VARCHAR(50)) COLLATE DATABASE_DEFAULT AS tasa
    INTO #cotizaciones
    FROM OPENJSON(@respuesta_json, '$.rates');
    SELECT @leidos = COUNT(*) FROM #cotizaciones;

    WHILE @i <= @leidos
    BEGIN
        SELECT @moneda = UPPER(moneda), @tasa_txt = tasa,
               @registro = CONCAT(CONVERT(VARCHAR(10), @fecha_resp, 23), ' | 1 ', @base_resp, ' = ', tasa, ' ', moneda)
        FROM #cotizaciones WHERE fila = @i;
        SELECT @errores = '', @tasa_actual = NULL;

        BEGIN TRY
            SET @tasa = TRY_CONVERT(NUMERIC(18,8), TRY_CONVERT(FLOAT, @tasa_txt));
            IF @moneda IS NULL OR LEN(@moneda) <> 3 OR @moneda LIKE '%[^A-Z]%'
                SET @errores += '- El código de moneda ''' + ISNULL(@moneda, '') + ''' debe tener tres letras.' + @nl;
            ELSE IF @moneda = @base_resp
                SET @errores += '- La moneda cotizada no puede ser la moneda base.' + @nl;
            IF @tasa IS NULL OR @tasa <= 0
                SET @errores += '- La cotización ''' + ISNULL(@tasa_txt, '') + ''' no es un número positivo.' + @nl;
            IF @errores <> ''
            BEGIN
                SET @errores = 'Registro rechazado:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            SELECT @tasa_actual = tipo_cambio FROM publicidad.tipo_cambio
            WHERE fecha = @fecha_resp AND moneda_base = @base_resp AND moneda_cotizada = @moneda;

            IF @tasa_actual IS NULL
            BEGIN
                INSERT INTO publicidad.tipo_cambio (fecha, moneda_base, moneda_cotizada, tipo_cambio, fuente)
                VALUES (@fecha_resp, @base_resp, @moneda, @tasa, 'Frankfurter');
                SET @insertados += 1;
            END
            ELSE IF @tasa_actual <> @tasa
            BEGIN
                UPDATE publicidad.tipo_cambio SET tipo_cambio = @tasa, importado_en = SYSDATETIMEOFFSET()
                WHERE fecha = @fecha_resp AND moneda_base = @base_resp AND moneda_cotizada = @moneda;
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
