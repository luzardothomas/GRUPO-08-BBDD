/*
 * Universidad: UNLaM
 * Materia: Bases de Datos Aplicada
 * Trabajo práctico: Sistema de registro y gestión del Mundial de Fútbol
 * Entrega: 6 - Importación de datos obtenidos por scraping
 *
 * Fuente sugerida: tabla de estadios de la Copa Mundial de Fútbol 2026 en Wikipedia.
 * https://en.wikipedia.org/wiki/2026_FIFA_World_Cup
 *
 * La descarga de la página y el parsing de HTML se realizan fuera de SQL Server.
 * El proceso de scraping debe entregar los datos extraídos en el JSON documentado
 * en el ejemplo de ejecución. El huso horario se completa mediante una fuente de
 * zonas horarias, porque no forma parte de los datos de la tabla de estadios.
 *
 * Ejecutar después de la definición de tablas y SP ABM de la Entrega 5.
 */

USE mundial_2026;
GO

IF SCHEMA_ID('scraping') IS NULL
    EXEC('CREATE SCHEMA scraping');
GO

IF OBJECT_ID('scraping.error_importacion', 'U') IS NULL
BEGIN
    CREATE TABLE scraping.error_importacion (
        error_id      INT IDENTITY(1, 1) PRIMARY KEY,
        fuente        VARCHAR(500) NOT NULL,
        registro      VARCHAR(1000) NOT NULL,
        motivo        VARCHAR(1000) NOT NULL,
        fecha_error   DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
    );
END;
GO

CREATE OR ALTER PROCEDURE torneo.importar_sedes_scraping
    @pagina_origen VARCHAR(500),
    @datos_json    VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_actual INT = 1;
    DECLARE @id_maximo INT;
    DECLARE @nombre VARCHAR(4000);
    DECLARE @ciudad VARCHAR(4000);
    DECLARE @codigo_iso VARCHAR(10);
    DECLARE @capacidad_texto VARCHAR(30);
    DECLARE @capacidad INT;
    DECLARE @huso_horario VARCHAR(20);
    DECLARE @pais_id INT;
    DECLARE @sede_id INT;
    DECLARE @datos_fila VARCHAR(1000);
    DECLARE @mensaje_error VARCHAR(1000);
    DECLARE @insertados INT = 0;
    DECLARE @actualizados INT = 0;
    DECLARE @rechazados INT = 0;
    DECLARE @es_actualizacion BIT;

    IF NULLIF(LTRIM(RTRIM(@pagina_origen)), '') IS NULL
        THROW 50050, 'Debe indicar la URL de la página utilizada como fuente.', 1;

    IF @datos_json IS NULL OR ISJSON(@datos_json) <> 1
        THROW 50051, 'Los datos obtenidos por scraping no contienen JSON válido.', 1;

    IF JSON_QUERY(@datos_json, '$.sedes') IS NULL
        THROW 50052, 'El JSON debe contener un arreglo llamado sedes.', 1;

    DROP TABLE IF EXISTS #SedesScraping;

    CREATE TABLE #SedesScraping (
        fila_origen INT IDENTITY(1, 1) PRIMARY KEY,
        nombre VARCHAR(4000) NULL,
        ciudad VARCHAR(4000) NULL,
        codigo_iso VARCHAR(10) NULL,
        capacidad_texto VARCHAR(30) NULL,
        huso_horario VARCHAR(20) NULL
    );

    INSERT INTO #SedesScraping (
        nombre,
        ciudad,
        codigo_iso,
        capacidad_texto,
        huso_horario
    )
    SELECT
        nombre,
        ciudad,
        codigo_iso,
        capacidad_texto,
        huso_horario
    FROM OPENJSON(@datos_json, '$.sedes')
    WITH (
        nombre VARCHAR(4000) '$.nombre',
        ciudad VARCHAR(4000) '$.ciudad',
        codigo_iso VARCHAR(10) '$.codigo_iso',
        capacidad_texto VARCHAR(30) '$.capacidad',
        huso_horario VARCHAR(20) '$.huso_horario'
    );

    IF NOT EXISTS (SELECT 1 FROM #SedesScraping)
        THROW 50053, 'El arreglo sedes no contiene registros para importar.', 1;

    SELECT @id_maximo = MAX(fila_origen)
    FROM #SedesScraping;

    WHILE @id_actual <= @id_maximo
    BEGIN
        SELECT
            @nombre = nombre,
            @ciudad = ciudad,
            @codigo_iso = codigo_iso,
            @capacidad_texto = capacidad_texto,
            @huso_horario = huso_horario
        FROM #SedesScraping
        WHERE fila_origen = @id_actual;

        SET @datos_fila =
            'Fila=' + CONVERT(VARCHAR(12), @id_actual) +
            '; nombre=' + ISNULL(@nombre, '') +
            '; ciudad=' + ISNULL(@ciudad, '') +
            '; codigo_iso=' + ISNULL(@codigo_iso, '') +
            '; capacidad=' + ISNULL(@capacidad_texto, '') +
            '; huso_horario=' + ISNULL(@huso_horario, '');
        SET @es_actualizacion = 0;
        SET @pais_id = NULL;
        SET @sede_id = NULL;

        BEGIN TRY
            IF NULLIF(LTRIM(RTRIM(@nombre)), '') IS NULL
                THROW 50054, 'El nombre del estadio es obligatorio.', 1;

            IF LEN(@nombre) > 80
                THROW 50055, 'El nombre del estadio supera los 80 caracteres permitidos.', 1;

            IF NULLIF(LTRIM(RTRIM(@ciudad)), '') IS NULL
                THROW 50056, 'La ciudad de la sede es obligatoria.', 1;

            IF LEN(@ciudad) > 80
                THROW 50057, 'El nombre de la ciudad supera los 80 caracteres permitidos.', 1;

            IF @codigo_iso IS NULL
               OR LEN(@codigo_iso) <> 3
               OR @codigo_iso LIKE '%[^A-Za-z]%'
                THROW 50058, 'El código ISO del país debe contener tres letras.', 1;

            SET @capacidad = TRY_CONVERT(INT, @capacidad_texto);

            IF @capacidad IS NULL OR @capacidad <= 0
                THROW 50059, 'La capacidad debe ser un número entero mayor a cero.', 1;

            IF @huso_horario IS NULL
               OR LEN(@huso_horario) <> 6
               OR @huso_horario NOT LIKE 'UTC[-+][0-9][0-9]'
                THROW 50060, 'El huso horario debe tener formato UTC+hh o UTC-hh.', 1;

            SELECT @pais_id = pais_id
            FROM torneo.pais
            WHERE codigo_iso = UPPER(@codigo_iso);

            IF @pais_id IS NULL
                THROW 50061, 'No existe en torneo.pais el país indicado por código ISO.', 1;

            BEGIN TRANSACTION;

            SELECT @sede_id = sede_id
            FROM torneo.sede
            WHERE nombre = LTRIM(RTRIM(@nombre))
              AND ciudad = LTRIM(RTRIM(@ciudad));

            IF @sede_id IS NULL
            BEGIN
                EXEC torneo.sede_insertar
                    @nombre = @nombre,
                    @ciudad = @ciudad,
                    @pais_id = @pais_id,
                    @capacidad = @capacidad,
                    @huso_horario = @huso_horario;
            END
            ELSE
            BEGIN
                EXEC torneo.sede_modificar
                    @sede_id = @sede_id,
                    @nombre = @nombre,
                    @ciudad = @ciudad,
                    @pais_id = @pais_id,
                    @capacidad = @capacidad,
                    @huso_horario = @huso_horario;

                SET @es_actualizacion = 1;
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

            INSERT INTO scraping.error_importacion (
                fuente,
                registro,
                motivo
            )
            VALUES (
                @pagina_origen,
                ISNULL(@datos_fila, ''),
                @mensaje_error
            );

            SET @rechazados += 1;
        END CATCH;

        SET @id_actual += 1;
    END;

    DROP TABLE IF EXISTS #SedesScraping;

    SELECT
        @pagina_origen AS fuente,
        @insertados AS insertados,
        @actualizados AS actualizados,
        @rechazados AS rechazados;
END;
GO

/*
 * El proceso de scraping entrega un JSON con esta estructura.
 * codigo_iso debe coincidir con torneo.pais.codigo_iso; huso_horario debe usar
 * el offset UTC vigente para la sede y fecha considerada.
 *
EXEC torneo.importar_sedes_scraping
    @pagina_origen = 'https://en.wikipedia.org/wiki/2026_FIFA_World_Cup',
    @datos_json = '{
        "sedes": [
            {
                "nombre": "Estadio de ejemplo",
                "ciudad": "Ciudad de ejemplo",
                "codigo_iso": "USA",
                "capacidad": 80000,
                "huso_horario": "UTC-04"
            }
        ]
    }';
GO

SELECT *
FROM scraping.error_importacion
ORDER BY error_id DESC;
*/
