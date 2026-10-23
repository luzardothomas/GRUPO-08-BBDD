/*
 * Universidad: UNLaM
 * Materia: Bases de Datos Aplicada
 * Trabajo práctico: Sistema de registro y gestión del Mundial de Fútbol
 * Entrega: 6 - Importación de datos
 *
 * Fuentes públicas de Kaggle, creadas por swaptr:
 * - https://www.kaggle.com/datasets/swaptr/fifa-wc-2026-matches
 * - https://www.kaggle.com/datasets/swaptr/fifa-wc-2026-players
 *
 * Los archivos se cargan sin modificarlos. SQL Server debe tener acceso a la ruta
 * indicada, ejecutando el servicio con permisos de lectura sobre ese archivo.
 */

USE mundial_2026;
GO

-- 1. Tablas de integración y de errores

IF SCHEMA_ID('importacion') IS NULL
    EXEC('CREATE SCHEMA importacion');
GO

IF OBJECT_ID('importacion.error_fila', 'U') IS NULL
BEGIN
    CREATE TABLE importacion.error_fila (
        error_id       INT IDENTITY(1, 1) PRIMARY KEY,
        conjunto_datos VARCHAR(40) NOT NULL,
        archivo        VARCHAR(4000) NOT NULL,
        registro       VARCHAR(1000) NOT NULL,
        motivo         VARCHAR(1000) NOT NULL,
        fecha_error    DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
    );
END;
GO

IF OBJECT_ID('torneo.partido_estadistica_kaggle', 'U') IS NULL
BEGIN
    CREATE TABLE torneo.partido_estadistica_kaggle (
        partido_fuente_id    INT IDENTITY(1, 1) PRIMARY KEY,
        fecha                DATE NOT NULL,
        hora_local           TIME NOT NULL,
        ronda                VARCHAR(40) NOT NULL,
        gameweek             INT NULL,
        equipo_local         VARCHAR(100) NOT NULL,
        equipo_visitante     VARCHAR(100) NOT NULL,
        marcador             VARCHAR(15) NULL,
        goles_local          INT NOT NULL,
        goles_visitante      INT NOT NULL,
        penales_local        INT NULL,
        penales_visitante    INT NULL,
        asistencia           INT NULL,
        sede                 VARCHAR(180) NULL,
        arbitro              VARCHAR(120) NULL,
        formacion_local      VARCHAR(30) NULL,
        formacion_visitante  VARCHAR(30) NULL,
        entrenador_local     VARCHAR(120) NULL,
        entrenador_visitante VARCHAR(120) NULL,
        capitan_local        VARCHAR(120) NULL,
        capitan_visitante    VARCHAR(120) NULL,
        posesion_local       NUMERIC(6, 2) NULL,
        posesion_visitante   NUMERIC(6, 2) NULL,
        tiros_arco_local     INT NULL,
        tiros_arco_visitante INT NULL,
        tiros_total_local    INT NULL,
        tiros_total_visitante INT NULL,
        atajadas_local       INT NULL,
        atajadas_visitante   INT NULL,
        amarillas_local      INT NULL,
        amarillas_visitante  INT NULL,
        rojas_local          INT NULL,
        rojas_visitante      INT NULL,
        faltas_local         INT NULL,
        faltas_visitante     INT NULL,
        corners_local        INT NULL,
        corners_visitante    INT NULL,
        notas                VARCHAR(500) NULL,
        archivo_origen       VARCHAR(4000) NOT NULL,
        importado_en         DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
        CONSTRAINT uq_partido_estadistica_kaggle
            UNIQUE (fecha, equipo_local, equipo_visitante),
        CONSTRAINT chk_partido_estadistica_kaggle_goles
            CHECK (goles_local >= 0 AND goles_visitante >= 0)
    );
END;
GO

IF OBJECT_ID('plantel.jugador_estadistica_kaggle', 'U') IS NULL
BEGIN
    CREATE TABLE plantel.jugador_estadistica_kaggle (
        jugador_estadistica_id INT IDENTITY(1, 1) PRIMARY KEY,
        jugador                VARCHAR(120) NOT NULL,
        equipo                 VARCHAR(100) NOT NULL,
        pais_equipo            VARCHAR(100) NOT NULL,
        posicion_fuente        VARCHAR(10) NULL,
        edad                   INT NULL,
        anio_nacimiento        INT NULL,
        club                   VARCHAR(120) NULL,
        partidos               INT NULL,
        titularidades          INT NULL,
        minutos                NUMERIC(10, 1) NULL,
        goles                  NUMERIC(8, 1) NULL,
        asistencias            NUMERIC(8, 1) NULL,
        amarillas              NUMERIC(8, 1) NULL,
        rojas                  NUMERIC(8, 1) NULL,
        goles_penal            NUMERIC(8, 1) NULL,
        penales_convertidos    NUMERIC(8, 1) NULL,
        penales_ejecutados     NUMERIC(8, 1) NULL,
        goles_en_contra        NUMERIC(8, 1) NULL,
        archivo_origen         VARCHAR(4000) NOT NULL,
        importado_en           DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),
        CONSTRAINT uq_jugador_estadistica_kaggle
            UNIQUE (pais_equipo, jugador)
    );
END;
GO

-- 2. Importación de partidos y estadísticas por equipo

CREATE OR ALTER PROCEDURE torneo.importar_partidos_kaggle_2026
    @ruta_archivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables para controlar el lote y reportar el resultado.
    DECLARE @mensaje_error VARCHAR(1000);
    DECLARE @datos_fila VARCHAR(1000);
    DECLARE @id_actual INT;
    DECLARE @id_maximo INT;
    DECLARE @insertados INT = 0;
    DECLARE @actualizados INT = 0;
    DECLARE @rechazados INT = 0;

    IF NULLIF(LTRIM(RTRIM(@ruta_archivo)), '') IS NULL
        THROW 50010, 'Debe indicar la ruta completa de matches.csv.', 1;

    -- La tabla temporal recibe las 42 columnas en el orden original del CSV.
    DROP TABLE IF EXISTS #ArchivoPartidos;

    CREATE TABLE #ArchivoPartidos (
        ronda VARCHAR(4000), gameweek VARCHAR(4000), dia_semana VARCHAR(4000),
        fecha VARCHAR(4000), hora_inicio VARCHAR(4000), equipo_local VARCHAR(4000),
        equipo_visitante VARCHAR(4000), marcador VARCHAR(4000), goles_local VARCHAR(4000),
        goles_visitante VARCHAR(4000), asistencia VARCHAR(4000), sede VARCHAR(4000),
        arbitro VARCHAR(4000), formacion_local VARCHAR(4000), formacion_visitante VARCHAR(4000),
        entrenador_local VARCHAR(4000), entrenador_visitante VARCHAR(4000),
        capitan_local VARCHAR(4000), capitan_visitante VARCHAR(4000),
        posesion_local VARCHAR(4000), posesion_visitante VARCHAR(4000),
        tiros_arco_local VARCHAR(4000), tiros_arco_visitante VARCHAR(4000),
        tiros_total_local VARCHAR(4000), tiros_total_visitante VARCHAR(4000),
        atajadas_local VARCHAR(4000), atajadas_visitante VARCHAR(4000),
        amarillas_local VARCHAR(4000), amarillas_visitante VARCHAR(4000),
        rojas_local VARCHAR(4000), rojas_visitante VARCHAR(4000),
        faltas_local VARCHAR(4000), faltas_visitante VARCHAR(4000),
        corners_local VARCHAR(4000), corners_visitante VARCHAR(4000),
        centros_local VARCHAR(4000), centros_visitante VARCHAR(4000),
        intercepciones_local VARCHAR(4000), intercepciones_visitante VARCHAR(4000),
        offsides_local VARCHAR(4000), offsides_visitante VARCHAR(4000),
        notas VARCHAR(4000)
    );

    -- La ruta forma parte del comando BULK INSERT, por eso se escapan las comillas.
    DECLARE @comando VARCHAR(MAX);

    SET @comando =
        'BULK INSERT #ArchivoPartidos FROM ''' +
        REPLACE(@ruta_archivo, '''', '''''') +
        ''' WITH (
            FORMAT = ''CSV'',
            FIRSTROW = 2,
            CODEPAGE = ''65001'',
            FIELDQUOTE = ''"'',
            ROWTERMINATOR = ''0x0a''
        );';

    BEGIN TRY
        EXEC (@comando);
    END TRY
    BEGIN CATCH
        SET @mensaje_error =
            'No se pudo leer matches.csv. Revise la ruta y los permisos del servicio SQL Server. ' +
            ERROR_MESSAGE();
        THROW 50012, @mensaje_error, 1;
    END CATCH;

    -- Se agrega un número de fila para recorrer el lote con un WHILE.
    SELECT IDENTITY(INT, 1, 1) AS fila_origen, *
    INTO #ImportacionPartidos
    FROM #ArchivoPartidos;

    DECLARE @fila VARCHAR(1000);
    DECLARE @ronda VARCHAR(40);
    DECLARE @gameweek INT;
    DECLARE @fecha DATE;
    DECLARE @hora TIME;
    DECLARE @equipo_local VARCHAR(100);
    DECLARE @equipo_visitante VARCHAR(100);
    DECLARE @marcador VARCHAR(15);
    DECLARE @goles_local_texto VARCHAR(20);
    DECLARE @goles_visitante_texto VARCHAR(20);
    DECLARE @goles_local_numero NUMERIC(10, 2);
    DECLARE @goles_visitante_numero NUMERIC(10, 2);
    DECLARE @marcador_separador INT;
    DECLARE @penal_local_cierre INT;
    DECLARE @penal_visitante_inicio INT;
    DECLARE @penal_visitante_cierre INT;
    DECLARE @goles_local INT;
    DECLARE @goles_visitante INT;
    DECLARE @penales_local INT;
    DECLARE @penales_visitante INT;
    DECLARE @asistencia INT;
    DECLARE @sede VARCHAR(180);
    DECLARE @arbitro VARCHAR(120);
    DECLARE @formacion_local VARCHAR(30);
    DECLARE @formacion_visitante VARCHAR(30);
    DECLARE @entrenador_local VARCHAR(120);
    DECLARE @entrenador_visitante VARCHAR(120);
    DECLARE @capitan_local VARCHAR(120);
    DECLARE @capitan_visitante VARCHAR(120);
    DECLARE @posesion_local NUMERIC(6, 2);
    DECLARE @posesion_visitante NUMERIC(6, 2);
    DECLARE @tiros_arco_local INT;
    DECLARE @tiros_arco_visitante INT;
    DECLARE @tiros_total_local INT;
    DECLARE @tiros_total_visitante INT;
    DECLARE @atajadas_local INT;
    DECLARE @atajadas_visitante INT;
    DECLARE @amarillas_local INT;
    DECLARE @amarillas_visitante INT;
    DECLARE @rojas_local INT;
    DECLARE @rojas_visitante INT;
    DECLARE @faltas_local INT;
    DECLARE @faltas_visitante INT;
    DECLARE @corners_local INT;
    DECLARE @corners_visitante INT;
    DECLARE @notas VARCHAR(500);
    DECLARE @partido_fuente_id INT;

    SET @id_actual = 1;
    SELECT @id_maximo = MAX(fila_origen) FROM #ImportacionPartidos;

    -- 3. Validación y upsert, fila por fila.
    WHILE @id_actual <= ISNULL(@id_maximo, 0)
    BEGIN
        BEGIN TRY
            SET @mensaje_error = NULL;
            SET @datos_fila = NULL;
            SET @marcador_separador = NULL;
            SET @penal_local_cierre = NULL;
            SET @penal_visitante_inicio = NULL;
            SET @penal_visitante_cierre = NULL;
            SET @goles_local = NULL;
            SET @goles_visitante = NULL;
            SET @goles_local_numero = NULL;
            SET @goles_visitante_numero = NULL;
            SET @penales_local = NULL;
            SET @penales_visitante = NULL;
            SET @partido_fuente_id = NULL;

            SELECT
                @ronda = NULLIF(LTRIM(RTRIM(ronda)), ''),
                @gameweek = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(gameweek)), '')),
                @fecha = TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM(fecha)), ''), 23),
                @hora = TRY_CONVERT(TIME, NULLIF(LTRIM(RTRIM(hora_inicio)), '')),
                @equipo_local = NULLIF(LTRIM(RTRIM(equipo_local)), ''),
                @equipo_visitante = NULLIF(LTRIM(RTRIM(equipo_visitante)), ''),
                @marcador = NULLIF(LTRIM(RTRIM(marcador)), ''),
                @goles_local_texto = NULLIF(LTRIM(RTRIM(goles_local)), ''),
                @goles_visitante_texto = NULLIF(LTRIM(RTRIM(goles_visitante)), ''),
                @sede = NULLIF(LTRIM(RTRIM(sede)), ''),
                @arbitro = NULLIF(LTRIM(RTRIM(arbitro)), ''),
                @formacion_local = NULLIF(LTRIM(RTRIM(formacion_local)), ''),
                @formacion_visitante = NULLIF(LTRIM(RTRIM(formacion_visitante)), ''),
                @entrenador_local = NULLIF(LTRIM(RTRIM(entrenador_local)), ''),
                @entrenador_visitante = NULLIF(LTRIM(RTRIM(entrenador_visitante)), ''),
                @capitan_local = NULLIF(LTRIM(RTRIM(capitan_local)), ''),
                @capitan_visitante = NULLIF(LTRIM(RTRIM(capitan_visitante)), ''),
                @posesion_local = TRY_CONVERT(NUMERIC(6, 2), NULLIF(LTRIM(RTRIM(posesion_local)), '')),
                @posesion_visitante = TRY_CONVERT(NUMERIC(6, 2), NULLIF(LTRIM(RTRIM(posesion_visitante)), '')),
                @tiros_arco_local = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(tiros_arco_local)), '')),
                @tiros_arco_visitante = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(tiros_arco_visitante)), '')),
                @tiros_total_local = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(tiros_total_local)), '')),
                @tiros_total_visitante = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(tiros_total_visitante)), '')),
                @atajadas_local = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(atajadas_local)), '')),
                @atajadas_visitante = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(atajadas_visitante)), '')),
                @amarillas_local = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(amarillas_local)), '')),
                @amarillas_visitante = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(amarillas_visitante)), '')),
                @rojas_local = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(rojas_local)), '')),
                @rojas_visitante = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(rojas_visitante)), '')),
                @faltas_local = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(faltas_local)), '')),
                @faltas_visitante = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(faltas_visitante)), '')),
                @corners_local = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(corners_local)), '')),
                @corners_visitante = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(corners_visitante)), '')),
                @notas = NULLIF(LTRIM(RTRIM(notas)), ''),
                @asistencia = TRY_CONVERT(INT, REPLACE(NULLIF(LTRIM(RTRIM(asistencia)), ''), ',', ''))
            FROM #ImportacionPartidos
            WHERE fila_origen = @id_actual;

            SET @datos_fila =
                'Fecha: ' + COALESCE(CONVERT(VARCHAR(10), @fecha, 23), '(vacía)') +
                ' | Local: ' + COALESCE(@equipo_local, '(vacío)') +
                ' | Visitante: ' + COALESCE(@equipo_visitante, '(vacío)') +
                ' | Marcador: ' + COALESCE(@marcador, '(vacío)');

            IF @fecha IS NULL
                THROW 50020, 'La fecha está vacía o no tiene formato válido.', 1;
            IF @hora IS NULL
                THROW 50021, 'La hora está vacía o no tiene formato válido.', 1;
            IF @ronda IS NULL
                THROW 50022, 'La ronda está vacía.', 1;
            IF @equipo_local IS NULL OR @equipo_visitante IS NULL
                THROW 50023, 'El partido debe incluir ambos equipos.', 1;

            SET @goles_local_numero = TRY_CONVERT(NUMERIC(10, 2), @goles_local_texto);
            SET @goles_visitante_numero = TRY_CONVERT(NUMERIC(10, 2), @goles_visitante_texto);

            IF (@goles_local_texto IS NOT NULL AND @goles_local_numero IS NULL)
               OR (@goles_visitante_texto IS NOT NULL AND @goles_visitante_numero IS NULL)
                THROW 50024, 'Los goles informados no tienen formato numérico válido.', 1;

            IF (@goles_local_numero IS NOT NULL
                    AND @goles_local_numero <> FLOOR(@goles_local_numero))
               OR (@goles_visitante_numero IS NOT NULL
                    AND @goles_visitante_numero <> FLOOR(@goles_visitante_numero))
                THROW 50035, 'El marcador debe expresarse en goles enteros.', 1;

            IF @goles_local_numero IS NOT NULL
                SET @goles_local = CONVERT(INT, @goles_local_numero);
            IF @goles_visitante_numero IS NOT NULL
                SET @goles_visitante = CONVERT(INT, @goles_visitante_numero);

            -- En cuatro filas los goles vienen sólo en "score", junto con los penales.
            IF @marcador IS NOT NULL
            BEGIN
                SET @marcador_separador = CHARINDEX('–', @marcador);
                IF @marcador_separador = 0
                    SET @marcador_separador = CHARINDEX('-', @marcador);

                IF LEFT(@marcador, 1) = '('
                BEGIN
                    SET @penal_local_cierre = CHARINDEX(')', @marcador);
                    SET @penal_visitante_inicio =
                        CHARINDEX('(', @marcador, @marcador_separador + 1);
                    SET @penal_visitante_cierre =
                        CHARINDEX(')', @marcador, @penal_visitante_inicio + 1);

                    IF @penal_local_cierre > 1
                        SET @penales_local =
                            TRY_CONVERT(INT, SUBSTRING(@marcador, 2, @penal_local_cierre - 2));

                    IF @penal_visitante_inicio > 0 AND @penal_visitante_cierre > @penal_visitante_inicio
                        SET @penales_visitante = TRY_CONVERT(INT,
                            SUBSTRING(@marcador, @penal_visitante_inicio + 1,
                                @penal_visitante_cierre - @penal_visitante_inicio - 1));
                END;

                IF @goles_local IS NULL AND @marcador_separador > 0
                BEGIN
                    IF @penal_local_cierre > 0
                        SET @goles_local = TRY_CONVERT(INT,
                            SUBSTRING(@marcador, @penal_local_cierre + 1,
                                @marcador_separador - @penal_local_cierre - 1));
                    ELSE
                        SET @goles_local = TRY_CONVERT(INT,
                            SUBSTRING(@marcador, 1, @marcador_separador - 1));
                END;

                IF @goles_visitante IS NULL AND @marcador_separador > 0
                BEGIN
                    IF @penal_visitante_inicio > 0
                        SET @goles_visitante = TRY_CONVERT(INT,
                            SUBSTRING(@marcador, @marcador_separador + 1,
                                @penal_visitante_inicio - @marcador_separador - 1));
                    ELSE
                        SET @goles_visitante = TRY_CONVERT(INT,
                            SUBSTRING(@marcador, @marcador_separador + 1, 10));
                END;
            END;

            IF @goles_local IS NULL OR @goles_visitante IS NULL
                THROW 50024, 'El marcador está vacío o no se pudo interpretar.', 1;
            IF @goles_local < 0 OR @goles_visitante < 0
                THROW 50025, 'Los goles no pueden ser negativos.', 1;
            IF LEFT(COALESCE(@marcador, ''), 1) = '('
               AND (@penales_local IS NULL OR @penales_visitante IS NULL)
                THROW 50026, 'No se pudo interpretar la tanda de penales.', 1;
            IF @asistencia IS NULL AND EXISTS (
                SELECT 1
                FROM #ImportacionPartidos
                WHERE fila_origen = @id_actual
                  AND NULLIF(LTRIM(RTRIM(asistencia)), '') IS NOT NULL
            )
                THROW 50027, 'La asistencia no tiene formato numérico válido.', 1;

            IF @gameweek IS NULL AND EXISTS (
                SELECT 1
                FROM #ImportacionPartidos
                WHERE fila_origen = @id_actual
                  AND NULLIF(LTRIM(RTRIM(gameweek)), '') IS NOT NULL
            )
                THROW 50028, 'La fecha de jornada no tiene formato numérico válido.', 1;

            IF (@posesion_local IS NULL OR @posesion_visitante IS NULL) AND EXISTS (
                SELECT 1
                FROM #ImportacionPartidos
                WHERE fila_origen = @id_actual
                  AND (
                       (@posesion_local IS NULL AND NULLIF(LTRIM(RTRIM(posesion_local)), '') IS NOT NULL)
                    OR (@posesion_visitante IS NULL AND NULLIF(LTRIM(RTRIM(posesion_visitante)), '') IS NOT NULL)
                  )
            )
                THROW 50029, 'La posesión de uno de los equipos no es numérica.', 1;

            IF EXISTS (
                SELECT 1
                FROM #ImportacionPartidos
                WHERE fila_origen = @id_actual
                  AND (
                       (@tiros_arco_local IS NULL AND NULLIF(LTRIM(RTRIM(tiros_arco_local)), '') IS NOT NULL)
                    OR (@tiros_arco_visitante IS NULL AND NULLIF(LTRIM(RTRIM(tiros_arco_visitante)), '') IS NOT NULL)
                    OR (@tiros_total_local IS NULL AND NULLIF(LTRIM(RTRIM(tiros_total_local)), '') IS NOT NULL)
                    OR (@tiros_total_visitante IS NULL AND NULLIF(LTRIM(RTRIM(tiros_total_visitante)), '') IS NOT NULL)
                    OR (@atajadas_local IS NULL AND NULLIF(LTRIM(RTRIM(atajadas_local)), '') IS NOT NULL)
                    OR (@atajadas_visitante IS NULL AND NULLIF(LTRIM(RTRIM(atajadas_visitante)), '') IS NOT NULL)
                    OR (@amarillas_local IS NULL AND NULLIF(LTRIM(RTRIM(amarillas_local)), '') IS NOT NULL)
                    OR (@amarillas_visitante IS NULL AND NULLIF(LTRIM(RTRIM(amarillas_visitante)), '') IS NOT NULL)
                    OR (@rojas_local IS NULL AND NULLIF(LTRIM(RTRIM(rojas_local)), '') IS NOT NULL)
                    OR (@rojas_visitante IS NULL AND NULLIF(LTRIM(RTRIM(rojas_visitante)), '') IS NOT NULL)
                    OR (@faltas_local IS NULL AND NULLIF(LTRIM(RTRIM(faltas_local)), '') IS NOT NULL)
                    OR (@faltas_visitante IS NULL AND NULLIF(LTRIM(RTRIM(faltas_visitante)), '') IS NOT NULL)
                    OR (@corners_local IS NULL AND NULLIF(LTRIM(RTRIM(corners_local)), '') IS NOT NULL)
                    OR (@corners_visitante IS NULL AND NULLIF(LTRIM(RTRIM(corners_visitante)), '') IS NOT NULL)
                  )
            )
                THROW 50034, 'Una o más estadísticas por equipo no tienen formato numérico válido.', 1;

            -- Se busca el partido por fecha y equipos; la clave evita repetirlo al recargar.
            SELECT @partido_fuente_id = partido_fuente_id
            FROM torneo.partido_estadistica_kaggle
            WHERE fecha = @fecha
              AND equipo_local = @equipo_local
              AND equipo_visitante = @equipo_visitante;

            IF @partido_fuente_id IS NULL
            BEGIN
                INSERT INTO torneo.partido_estadistica_kaggle (
                    fecha, hora_local, ronda, gameweek, equipo_local, equipo_visitante,
                    marcador, goles_local, goles_visitante, penales_local, penales_visitante,
                    asistencia, sede, arbitro, formacion_local, formacion_visitante,
                    entrenador_local, entrenador_visitante, capitan_local, capitan_visitante,
                    posesion_local, posesion_visitante, tiros_arco_local, tiros_arco_visitante,
                    tiros_total_local, tiros_total_visitante, atajadas_local, atajadas_visitante,
                    amarillas_local, amarillas_visitante, rojas_local, rojas_visitante,
                    faltas_local, faltas_visitante, corners_local, corners_visitante,
                    notas, archivo_origen
                )
                SELECT
                    @fecha, @hora, @ronda, @gameweek, @equipo_local, @equipo_visitante,
                    @marcador, @goles_local, @goles_visitante, @penales_local, @penales_visitante,
                    @asistencia, @sede, @arbitro, @formacion_local, @formacion_visitante,
                    @entrenador_local, @entrenador_visitante, @capitan_local, @capitan_visitante,
                    @posesion_local, @posesion_visitante, @tiros_arco_local, @tiros_arco_visitante,
                    @tiros_total_local, @tiros_total_visitante, @atajadas_local, @atajadas_visitante,
                    @amarillas_local, @amarillas_visitante, @rojas_local, @rojas_visitante,
                    @faltas_local, @faltas_visitante, @corners_local, @corners_visitante,
                    @notas, @ruta_archivo;

                SET @insertados += 1;
            END
            ELSE
            BEGIN
                UPDATE torneo.partido_estadistica_kaggle
                SET hora_local = @hora,
                    ronda = @ronda,
                    gameweek = @gameweek,
                    marcador = @marcador,
                    goles_local = @goles_local,
                    goles_visitante = @goles_visitante,
                    penales_local = @penales_local,
                    penales_visitante = @penales_visitante,
                    asistencia = @asistencia,
                    sede = @sede,
                    arbitro = @arbitro,
                    formacion_local = @formacion_local,
                    formacion_visitante = @formacion_visitante,
                    entrenador_local = @entrenador_local,
                    entrenador_visitante = @entrenador_visitante,
                    capitan_local = @capitan_local,
                    capitan_visitante = @capitan_visitante,
                    posesion_local = @posesion_local,
                    posesion_visitante = @posesion_visitante,
                    tiros_arco_local = @tiros_arco_local,
                    tiros_arco_visitante = @tiros_arco_visitante,
                    tiros_total_local = @tiros_total_local,
                    tiros_total_visitante = @tiros_total_visitante,
                    atajadas_local = @atajadas_local,
                    atajadas_visitante = @atajadas_visitante,
                    amarillas_local = @amarillas_local,
                    amarillas_visitante = @amarillas_visitante,
                    rojas_local = @rojas_local,
                    rojas_visitante = @rojas_visitante,
                    faltas_local = @faltas_local,
                    faltas_visitante = @faltas_visitante,
                    corners_local = @corners_local,
                    corners_visitante = @corners_visitante,
                    notas = @notas,
                    archivo_origen = @ruta_archivo,
                    importado_en = SYSDATETIMEOFFSET()
                WHERE partido_fuente_id = @partido_fuente_id;

                SET @actualizados += 1;
            END;
        END TRY
        BEGIN CATCH
            SET @mensaje_error = ERROR_MESSAGE();

            INSERT INTO importacion.error_fila (
                conjunto_datos, archivo, registro, motivo
            )
            VALUES (
                'matches.csv',
                @ruta_archivo,
                CONCAT('Fila: ', @id_actual, ' | ', COALESCE(@datos_fila, '')),
                @mensaje_error
            );

            SET @rechazados += 1;
        END CATCH;

        SET @id_actual += 1;
    END;

    DROP TABLE IF EXISTS #ImportacionPartidos;
    DROP TABLE IF EXISTS #ArchivoPartidos;

    SELECT 'matches.csv' AS conjunto_datos,
           @insertados AS insertados,
           @actualizados AS actualizados,
           @rechazados AS rechazados;
END;
GO

-- 3. Importación de estadísticas individuales de jugadores

CREATE OR ALTER PROCEDURE plantel.importar_estadisticas_jugadores_kaggle_2026
    @ruta_archivo VARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @mensaje_error VARCHAR(1000);
    DECLARE @datos_fila VARCHAR(1000);
    DECLARE @id_actual INT;
    DECLARE @id_maximo INT;
    DECLARE @insertados INT = 0;
    DECLARE @actualizados INT = 0;
    DECLARE @rechazados INT = 0;

    IF NULLIF(LTRIM(RTRIM(@ruta_archivo)), '') IS NULL
        THROW 50011, 'Debe indicar la ruta completa de players.csv.', 1;

    -- La tabla temporal recibe las 72 columnas del archivo, en el orden original.
    DROP TABLE IF EXISTS #ArchivoJugadores;

    CREATE TABLE #ArchivoJugadores (
        jugador VARCHAR(4000), equipo VARCHAR(4000), pais_equipo VARCHAR(4000),
        posicion VARCHAR(4000), edad VARCHAR(4000), anio_nacimiento VARCHAR(4000),
        club VARCHAR(4000), partidos VARCHAR(4000), titularidades VARCHAR(4000),
        minutos VARCHAR(4000), minutos_90s VARCHAR(4000), goles VARCHAR(4000),
        asistencias VARCHAR(4000), goles_asistencias VARCHAR(4000), goles_penal VARCHAR(4000),
        penales_convertidos VARCHAR(4000), penales_ejecutados VARCHAR(4000),
        amarillas VARCHAR(4000), rojas VARCHAR(4000), goles_por_90 VARCHAR(4000),
        asistencias_por_90 VARCHAR(4000), goles_asistencias_por_90 VARCHAR(4000),
        goles_penal_por_90 VARCHAR(4000), goles_asistencias_penal_por_90 VARCHAR(4000),
        tiros VARCHAR(4000), tiros_arco VARCHAR(4000), pct_tiros_arco VARCHAR(4000),
        tiros_por_90 VARCHAR(4000), tiros_arco_por_90 VARCHAR(4000),
        goles_por_tiro VARCHAR(4000), goles_por_tiro_arco VARCHAR(4000),
        minutos_por_partido VARCHAR(4000), pct_minutos VARCHAR(4000),
        minutos_por_titularidad VARCHAR(4000), partidos_completos VARCHAR(4000),
        partidos_suplente VARCHAR(4000), minutos_por_cambio VARCHAR(4000),
        suplencias_sin_ingreso VARCHAR(4000), puntos_por_partido VARCHAR(4000),
        goles_equipo_con_jugador VARCHAR(4000), goles_rival_con_jugador VARCHAR(4000),
        diferencia_goles VARCHAR(4000), diferencia_goles_por_90 VARCHAR(4000),
        diferencia_goles_wowy VARCHAR(4000), amarillas_rojas VARCHAR(4000),
        faltas VARCHAR(4000), faltas_recibidas VARCHAR(4000), offsides VARCHAR(4000),
        centros VARCHAR(4000), intercepciones VARCHAR(4000), tackles_ganados VARCHAR(4000),
        penales_recibidos VARCHAR(4000), penales_cometidos VARCHAR(4000),
        goles_en_contra VARCHAR(4000), partidos_arquero VARCHAR(4000),
        titularidades_arquero VARCHAR(4000), minutos_arquero VARCHAR(4000),
        goles_contra_arquero VARCHAR(4000), goles_contra_por_90 VARCHAR(4000),
        tiros_arco_recibidos VARCHAR(4000), atajadas VARCHAR(4000),
        pct_atajadas VARCHAR(4000), victorias_arquero VARCHAR(4000),
        empates_arquero VARCHAR(4000), derrotas_arquero VARCHAR(4000),
        vallas_invictas VARCHAR(4000), pct_vallas_invictas VARCHAR(4000),
        penales_recibidos_arquero VARCHAR(4000), penales_concedidos VARCHAR(4000),
        penales_atajados VARCHAR(4000), penales_errados VARCHAR(4000),
        pct_penales_atajados VARCHAR(4000)
    );

    DECLARE @comando VARCHAR(MAX);

    SET @comando =
        'BULK INSERT #ArchivoJugadores FROM ''' +
        REPLACE(@ruta_archivo, '''', '''''') +
        ''' WITH (
            FORMAT = ''CSV'',
            FIRSTROW = 2,
            CODEPAGE = ''65001'',
            FIELDQUOTE = ''"'',
            ROWTERMINATOR = ''0x0a''
        );';

    BEGIN TRY
        EXEC (@comando);
    END TRY
    BEGIN CATCH
        SET @mensaje_error =
            'No se pudo leer players.csv. Revise la ruta y los permisos del servicio SQL Server. ' +
            ERROR_MESSAGE();
        THROW 50013, @mensaje_error, 1;
    END CATCH;

    SELECT IDENTITY(INT, 1, 1) AS fila_origen, *
    INTO #ImportacionJugadores
    FROM #ArchivoJugadores;

    DECLARE @jugador VARCHAR(120);
    DECLARE @equipo VARCHAR(100);
    DECLARE @pais_equipo VARCHAR(100);
    DECLARE @posicion VARCHAR(10);
    DECLARE @edad INT;
    DECLARE @anio_nacimiento INT;
    DECLARE @club VARCHAR(120);
    DECLARE @partidos INT;
    DECLARE @titularidades INT;
    DECLARE @minutos NUMERIC(10, 1);
    DECLARE @goles NUMERIC(8, 1);
    DECLARE @asistencias NUMERIC(8, 1);
    DECLARE @amarillas NUMERIC(8, 1);
    DECLARE @rojas NUMERIC(8, 1);
    DECLARE @goles_penal NUMERIC(8, 1);
    DECLARE @penales_convertidos NUMERIC(8, 1);
    DECLARE @penales_ejecutados NUMERIC(8, 1);
    DECLARE @goles_en_contra NUMERIC(8, 1);
    DECLARE @jugador_estadistica_id INT;

    SET @id_actual = 1;
    SELECT @id_maximo = MAX(fila_origen) FROM #ImportacionJugadores;

    -- 4. Validación y upsert por jugador.
    WHILE @id_actual <= ISNULL(@id_maximo, 0)
    BEGIN
        BEGIN TRY
            SET @mensaje_error = NULL;
            SET @datos_fila = NULL;
            SET @jugador_estadistica_id = NULL;

            SELECT
                @jugador = NULLIF(LTRIM(RTRIM(jugador)), ''),
                @equipo = NULLIF(LTRIM(RTRIM(equipo)), ''),
                @pais_equipo = NULLIF(LTRIM(RTRIM(pais_equipo)), ''),
                @posicion = NULLIF(LTRIM(RTRIM(posicion)), ''),
                @edad = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(edad)), '')),
                @anio_nacimiento = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(anio_nacimiento)), '')),
                @club = NULLIF(LTRIM(RTRIM(club)), ''),
                @partidos = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(partidos)), '')),
                @titularidades = TRY_CONVERT(INT, NULLIF(LTRIM(RTRIM(titularidades)), '')),
                @minutos = TRY_CONVERT(NUMERIC(10, 1), NULLIF(LTRIM(RTRIM(minutos)), '')),
                @goles = TRY_CONVERT(NUMERIC(8, 1), NULLIF(LTRIM(RTRIM(goles)), '')),
                @asistencias = TRY_CONVERT(NUMERIC(8, 1), NULLIF(LTRIM(RTRIM(asistencias)), '')),
                @amarillas = TRY_CONVERT(NUMERIC(8, 1), NULLIF(LTRIM(RTRIM(amarillas)), '')),
                @rojas = TRY_CONVERT(NUMERIC(8, 1), NULLIF(LTRIM(RTRIM(rojas)), '')),
                @goles_penal = TRY_CONVERT(NUMERIC(8, 1), NULLIF(LTRIM(RTRIM(goles_penal)), '')),
                @penales_convertidos = TRY_CONVERT(NUMERIC(8, 1), NULLIF(LTRIM(RTRIM(penales_convertidos)), '')),
                @penales_ejecutados = TRY_CONVERT(NUMERIC(8, 1), NULLIF(LTRIM(RTRIM(penales_ejecutados)), '')),
                @goles_en_contra = TRY_CONVERT(NUMERIC(8, 1), NULLIF(LTRIM(RTRIM(goles_en_contra)), ''))
            FROM #ImportacionJugadores
            WHERE fila_origen = @id_actual;

            SET @datos_fila =
                'Jugador: ' + COALESCE(@jugador, '(vacío)') +
                ' | País: ' + COALESCE(@pais_equipo, '(vacío)') +
                ' | Equipo: ' + COALESCE(@equipo, '(vacío)');

            IF @jugador IS NULL
                THROW 50030, 'El nombre del jugador está vacío.', 1;
            IF @equipo IS NULL OR @pais_equipo IS NULL
                THROW 50031, 'El equipo y el país son obligatorios.', 1;

            -- Los campos vacíos son válidos; un valor no vacío que no convierta no lo es.
            IF EXISTS (
                SELECT 1
                FROM #ImportacionJugadores
                WHERE fila_origen = @id_actual
                  AND (
                       (NULLIF(LTRIM(RTRIM(edad)), '') IS NOT NULL AND @edad IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(anio_nacimiento)), '') IS NOT NULL AND @anio_nacimiento IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(partidos)), '') IS NOT NULL AND @partidos IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(titularidades)), '') IS NOT NULL AND @titularidades IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(minutos)), '') IS NOT NULL AND @minutos IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(goles)), '') IS NOT NULL AND @goles IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(asistencias)), '') IS NOT NULL AND @asistencias IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(amarillas)), '') IS NOT NULL AND @amarillas IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(rojas)), '') IS NOT NULL AND @rojas IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(goles_penal)), '') IS NOT NULL AND @goles_penal IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(penales_convertidos)), '') IS NOT NULL AND @penales_convertidos IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(penales_ejecutados)), '') IS NOT NULL AND @penales_ejecutados IS NULL)
                    OR (NULLIF(LTRIM(RTRIM(goles_en_contra)), '') IS NOT NULL AND @goles_en_contra IS NULL)
                  )
            )
                THROW 50032, 'Uno o más datos numéricos tienen formato inválido.', 1;

            IF @edad < 0 OR @partidos < 0 OR @titularidades < 0 OR @minutos < 0
                THROW 50033, 'La edad, los partidos, titularidades y minutos no pueden ser negativos.', 1;

            SELECT @jugador_estadistica_id = jugador_estadistica_id
            FROM plantel.jugador_estadistica_kaggle
            WHERE pais_equipo = @pais_equipo
              AND jugador = @jugador;

            IF @jugador_estadistica_id IS NULL
            BEGIN
                INSERT INTO plantel.jugador_estadistica_kaggle (
                    jugador, equipo, pais_equipo, posicion_fuente, edad, anio_nacimiento,
                    club, partidos, titularidades, minutos, goles, asistencias, amarillas,
                    rojas, goles_penal, penales_convertidos, penales_ejecutados,
                    goles_en_contra, archivo_origen
                )
                VALUES (
                    @jugador, @equipo, @pais_equipo, @posicion, @edad, @anio_nacimiento,
                    @club, @partidos, @titularidades, @minutos, @goles, @asistencias,
                    @amarillas, @rojas, @goles_penal, @penales_convertidos,
                    @penales_ejecutados, @goles_en_contra, @ruta_archivo
                );

                SET @insertados += 1;
            END
            ELSE
            BEGIN
                UPDATE plantel.jugador_estadistica_kaggle
                SET equipo = @equipo,
                    posicion_fuente = @posicion,
                    edad = @edad,
                    anio_nacimiento = @anio_nacimiento,
                    club = @club,
                    partidos = @partidos,
                    titularidades = @titularidades,
                    minutos = @minutos,
                    goles = @goles,
                    asistencias = @asistencias,
                    amarillas = @amarillas,
                    rojas = @rojas,
                    goles_penal = @goles_penal,
                    penales_convertidos = @penales_convertidos,
                    penales_ejecutados = @penales_ejecutados,
                    goles_en_contra = @goles_en_contra,
                    archivo_origen = @ruta_archivo,
                    importado_en = SYSDATETIMEOFFSET()
                WHERE jugador_estadistica_id = @jugador_estadistica_id;

                SET @actualizados += 1;
            END;
        END TRY
        BEGIN CATCH
            SET @mensaje_error = ERROR_MESSAGE();

            INSERT INTO importacion.error_fila (
                conjunto_datos, archivo, registro, motivo
            )
            VALUES (
                'players.csv',
                @ruta_archivo,
                CONCAT('Fila: ', @id_actual, ' | ', COALESCE(@datos_fila, '')),
                @mensaje_error
            );

            SET @rechazados += 1;
        END CATCH;

        SET @id_actual += 1;
    END;

    DROP TABLE IF EXISTS #ImportacionJugadores;
    DROP TABLE IF EXISTS #ArchivoJugadores;

    SELECT 'players.csv' AS conjunto_datos,
           @insertados AS insertados,
           @actualizados AS actualizados,
           @rechazados AS rechazados;
END;
GO

-- Ejecución de ejemplo. La cuenta del servicio SQL Server debe leer estas rutas.
/*
EXEC torneo.importar_partidos_kaggle_2026
    @ruta_archivo = 'C:\datos\matches.csv';
GO

EXEC plantel.importar_estadisticas_jugadores_kaggle_2026
    @ruta_archivo = 'C:\datos\players.csv';
GO

SELECT *
FROM importacion.error_fila
ORDER BY error_id DESC;
*/