-- =======================================================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 6: Procesos de importación - Scraping de Wikipedia
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Scraping hecho enteramente en T-SQL: la página se descarga en vivo con
--   sp_invoke_external_rest_endpoint (API de MediaWiki, que devuelve en JSON el texto
--   fuente de la página) y se parsea con STRING_SPLIT y REGEXP_SUBSTR (SQL Server 2025).
--   Procedimientos:
--     torneo.scrapear_sedes        -> torneo.sede
--     torneo.scrapear_selecciones  -> torneo.seleccion y torneo.seleccion_estadistica
--     plantel.scrapear_planteles   -> plantel.jugador, plantel.convocatoria y plantel.cuerpo_tecnico
--   Cada SP recibe el nombre de la página de Wikipedia a scrapear y la descarga en vivo.
--   Se ejecuta después de entrega6_importacion.sql y sigue su misma norma: lote, una
--   transacción por fila, errores registrados sin cortar la importación, upsert con los
--   SP de la Entrega 5.
--
-- FUENTES (PÁGINAS DE ORIGEN) Y LÍMITES DE USO:
--   * Páginas de origen en Wikipedia en inglés:
--     - https://en.wikipedia.org/wiki/2026_FIFA_World_Cup        (sedes, confederaciones y tabla final)
--     - https://en.wikipedia.org/wiki/2026_FIFA_World_Cup_squads (grupos, planteles y entrenadores)
--   * Endpoint de descarga (MediaWiki Action API):
--     - https://en.wikipedia.org/w/api.php?action=parse&prop=wikitext&format=json&formatversion=2&page=<pagina>
--   * Límites de uso (Wikimedia API Etiquette):
--     - No requiere clave de autenticación (API pública gratuita).
--     - Límite: hasta 200 solicitudes/segundo en lectura general, recomendando peticiones
--       secuenciales (sin concurrencia) y encabezado User-Agent identificable.
--     - Estos tres procedimientos realizan en total 4 llamadas HTTP secuenciales (1 para sedes,
--       2 para selecciones y 1 para planteles).
--
-- TÉCNICA DE SCRAPING:
--   El texto fuente de Wikipedia (wikitext) se descarga en vivo dentro de un JSON mediante
--   sys.sp_invoke_external_rest_endpoint (importacion.obtener_wikitext) y es regular:
--   * Sedes (sección ==Venues==): cada fila de la tabla de estadios empieza con
--     "! ... {{#invoke:flag|icon|MEX}} [[Mexico City]]", seguida del estadio y su capacidad.
--     Como la tabla de Wikipedia no informa el huso horario, se calcula en T-SQL con AT TIME ZONE
--     (zonas horarias de Windows en sys.time_zone_info) para el 15/06/2026 según cada ciudad.
--   * Selecciones (secciones ===Qualification=== y ===Tournament ranking=== de 2026_FIFA_World_Cup,
--     y encabezados ==Group X== de 2026_FIFA_World_Cup_squads): extrae confederación, grupo y la
--     tabla de posiciones final ("|win_ARG=7 |draw_ARG=0 |loss_ARG=1 |gf_ARG=19|ga_ARG=8").
--   * Planteles (2026_FIFA_World_Cup_squads): cada jugador es una plantilla
--     {{nat fs g player|no=1|pos=GK|name=[[Matěj Kovář]]|sortname=Kovar, Matej|
--     age={{birth date and age2|...|2000|5|17}}|club=[[PSV Eindhoven]]|...}} y cada director
--     técnico aparece en una línea "Coach: [[...]]".
--   El texto se parte en líneas con STRING_SPLIT(..., CHAR(10), 1), se ubica cada sección por su
--   encabezado y de cada línea se extraen los campos con expresiones regulares (REGEXP_SUBSTR).
--   Las selecciones se identifican con su código FIFA (GER, NED...) o su nombre en inglés,
--   que importacion.fn_pais_id traduce con importacion.pais_equivalencia.
-- =======================================================================================

USE mundial_2026;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- ============================================================
-- 1. DESCARGA
-- ============================================================

-- Texto fuente (wikitext) de una página de la Wikipedia en inglés. Página inexistente o
-- respuesta sin texto: THROW 50003.

CREATE OR ALTER PROCEDURE importacion.obtener_wikitext
    @pagina   NVARCHAR(200),
    @wikitext NVARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @url NVARCHAR(4000), @respuesta NVARCHAR(MAX), @mensaje VARCHAR(2100);

    SET @url = N'https://en.wikipedia.org/w/api.php?action=parse&prop=wikitext&format=json&formatversion=2&page='
             + REPLACE(LTRIM(RTRIM(@pagina)), N' ', N'_');
    EXEC importacion.invocar_api @url, @respuesta OUTPUT;

    IF JSON_QUERY(@respuesta, '$.error') IS NOT NULL
    BEGIN
        SET @mensaje = 'Wikipedia no devolvió la página ''' + CAST(@pagina AS VARCHAR(200)) + ''': '
                     + ISNULL(JSON_VALUE(@respuesta, '$.error.info'), '(sin detalle)');
        THROW 50003, @mensaje, 1;
    END;

    SELECT @wikitext = w FROM OPENJSON(@respuesta, '$.parse') WITH (w NVARCHAR(MAX) '$.wikitext');
    IF @wikitext IS NULL
        THROW 50003, 'La respuesta de Wikipedia no trae el texto de la página.', 1;
END;
GO

-- ============================================================
-- 2. SEDES
-- ============================================================

/* Tabla "List of tournament venues" de la sección ==Venues==. Cada fila empieza con la
 línea de la ciudad ("! ... {{#invoke:flag|icon|MEX}} [[Mexico City]]"); la siguiente es
 el estadio y la tercera siguiente, la capacidad ('''80,824'''). La tabla no informa el
 huso: se calcula con AT TIME ZONE (base de zonas horarias de Windows) para la fecha del
 torneo, según la zona de cada ciudad. Clave natural: estadio + ciudad. */

CREATE OR ALTER PROCEDURE torneo.scrapear_sedes
    @pagina NVARCHAR(200) = N'2026_FIFA_World_Cup'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @wikitext NVARCHAR(MAX), @origen VARCHAR(500) = 'https://en.wikipedia.org/wiki/' + CAST(@pagina AS VARCHAR(200)),
            @lote_id INT, @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @i INT = 1, @registro VARCHAR(1000),
            @desde INT, @hasta INT, @nombre VARCHAR(200), @ciudad VARCHAR(200), @pais_txt VARCHAR(10),
            @capacidad_txt VARCHAR(50), @huso VARCHAR(10), @pais_id INT, @capacidad INT, @sede_id INT,
            @pais_actual INT, @capacidad_actual INT, @huso_actual CHAR(6);

    EXEC importacion.lote_abrir 'torneo.scrapear_sedes', @origen, @lote_id OUTPUT;

    BEGIN TRY
        EXEC importacion.obtener_wikitext @pagina, @wikitext OUTPUT;

        SELECT ordinal, CAST(value AS NVARCHAR(4000)) AS linea INTO #lineas
        FROM STRING_SPLIT(REPLACE(ISNULL(@wikitext, N''), NCHAR(13), N''), NCHAR(10), 1);

        SELECT @desde = MIN(ordinal) FROM #lineas WHERE linea LIKE N'|+ List of tournament venues%';
        SELECT @hasta = MIN(ordinal) FROM #lineas WHERE ordinal > @desde AND linea LIKE N'|}%';

        IF @desde IS NULL OR @hasta IS NULL
            THROW 50003, 'El texto no contiene la tabla "List of tournament venues".', 1;
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    -- Zona horaria de Windows de cada ciudad sede (la tabla de Wikipedia no la informa).
    DECLARE @zonas TABLE (ciudad NVARCHAR(80) PRIMARY KEY, zona NVARCHAR(60));
    INSERT INTO @zonas VALUES
        (N'Mexico City', N'Central Standard Time (Mexico)'), (N'Guadalajara', N'Central Standard Time (Mexico)'),
        (N'Monterrey', N'Central Standard Time (Mexico)'), (N'Toronto', N'Eastern Standard Time'),
        (N'Vancouver', N'Pacific Standard Time'), (N'New York/New Jersey', N'Eastern Standard Time'),
        (N'Boston', N'Eastern Standard Time'), (N'Philadelphia', N'Eastern Standard Time'),
        (N'Atlanta', N'Eastern Standard Time'), (N'Miami', N'Eastern Standard Time'),
        (N'Dallas', N'Central Standard Time'), (N'Houston', N'Central Standard Time'),
        (N'Kansas City', N'Central Standard Time'), (N'Los Angeles', N'Pacific Standard Time'),
        (N'San Francisco Bay Area', N'Pacific Standard Time'), (N'Seattle', N'Pacific Standard Time');

    SELECT ROW_NUMBER() OVER (ORDER BY f.ordinal) AS fila, f.pais, f.ciudad, f.estadio, f.capacidad,
           'UTC' + IIF(z.minutos < 0, '-', '+') + RIGHT('0' + CAST(ABS(z.minutos) / 60 AS VARCHAR(2)), 2) AS huso_horario
    INTO #sedes
    FROM (SELECT l.ordinal,
                 REGEXP_SUBSTR(l.linea, N'flag\|icon\|([A-Z]{3})', 1, 1, 'c', 1) AS pais,
                 REGEXP_SUBSTR(l.linea, N'\}\}\s*\[\[(?:[^|\]]*\|)?([^\]]+)\]\]', 1, 1, 'c', 1) AS ciudad,
                 REGEXP_SUBSTR(l.estadio, N'\[\[(?:[^|\]]*\|)?([^\]]+)\]\]', 1, 1, 'c', 1) AS estadio,
                 REPLACE(REGEXP_SUBSTR(l.capacidad, N'([0-9][0-9,]*)', 1, 1, 'c', 1), N',', N'') AS capacidad
          FROM (SELECT ordinal, linea, LEAD(linea, 1) OVER (ORDER BY ordinal) AS estadio,
                       LEAD(linea, 3) OVER (ORDER BY ordinal) AS capacidad
                FROM #lineas WHERE ordinal BETWEEN @desde AND @hasta) l
          WHERE l.linea LIKE N'!%flag|icon|%') f
    OUTER APPLY (SELECT DATEPART(TZOFFSET, CAST('2026-06-15T12:00:00' AS DATETIME2) AT TIME ZONE zz.zona) AS minutos
                 FROM @zonas zz WHERE zz.ciudad = f.ciudad) z;

    SELECT @leidos = COUNT(*) FROM #sedes;

    WHILE @i <= @leidos
    BEGIN
        SELECT @nombre = estadio, @ciudad = ciudad, @pais_txt = pais, @capacidad_txt = capacidad, @huso = huso_horario,
               @registro = CONCAT(estadio, ' | ', ciudad, ' | ', pais, ' | ', capacidad, ' | ', huso_horario)
        FROM #sedes WHERE fila = @i;
        SELECT @errores = '', @sede_id = NULL;

        BEGIN TRY
            SET @pais_id = importacion.fn_pais_id(@pais_txt);
            SET @capacidad = TRY_CONVERT(INT, @capacidad_txt);
            IF @nombre IS NULL OR LEN(@nombre) > 80
                SET @errores += '- El nombre del estadio es obligatorio (hasta 80 caracteres).' + @nl;
            IF @ciudad IS NULL OR LEN(@ciudad) > 80
                SET @errores += '- La ciudad es obligatoria (hasta 80 caracteres).' + @nl;
            IF @pais_id IS NULL
                SET @errores += '- El país ''' + ISNULL(@pais_txt, '') + ''' no está registrado.' + @nl;
            IF @capacidad IS NULL
                SET @errores += '- La capacidad ''' + ISNULL(@capacidad_txt, '') + ''' no es un número entero.' + @nl;
            IF @huso IS NULL
                SET @errores += '- No hay zona horaria definida para la ciudad ''' + ISNULL(@ciudad, '') + '''.' + @nl;
            IF @errores <> ''
            BEGIN
                SET @errores = 'Fila rechazada:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            SELECT @sede_id = sede_id, @pais_actual = pais_id, @capacidad_actual = capacidad, @huso_actual = huso_horario
            FROM torneo.sede WHERE nombre = @nombre AND ciudad = @ciudad;

            IF @sede_id IS NULL
            BEGIN
                EXEC torneo.sede_insertar @nombre, @ciudad, @pais_id, @capacidad, @huso;
                SET @insertados += 1;
            END
            ELSE IF @pais_actual <> @pais_id OR @capacidad_actual <> @capacidad OR @huso_actual <> @huso
            BEGIN
                EXEC torneo.sede_modificar @sede_id, @nombre, @ciudad, @pais_id, @capacidad, @huso;
                SET @actualizados += 1;
            END
            ELSE
                SET @sin_cambios += 1;
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

-- ============================================================
-- 3. SELECCIONES (teams)
-- ============================================================

/* Combina dos páginas:
   * Artículo del torneo, sección ===Qualification===: un título por confederación
     ("'''[[...|AFC]]''' (9)") seguido de sus selecciones ("* {{#invoke:flag|fb|AUS}}").
   * Artículo del torneo, sección ===Tournament ranking===: el orden final
     ("|team_order=ESP, ARG, ..."), las posiciones compartidas ("|pos_MAR={{=}}7") y los
     resultados de cada selección ("|win_ARG=7 |draw_ARG=0 |loss_ARG=1 |gf_ARG=19|ga_ARG=8").
     Los puntos se calculan (3 por victoria, 1 por empate); los partidos definidos por
     penales cuentan como empate, según la convención que indica la página.
   * Página de planteles: el grupo de cada selección (===Mexico=== dentro de ==Group A==).
 Clave natural: el país. La selección se da de alta o se modifica con los SP de la
 Entrega 5; la tabla final va a torneo.seleccion_estadistica. */

CREATE OR ALTER PROCEDURE torneo.scrapear_selecciones
    @pagina_torneo    NVARCHAR(200) = N'2026_FIFA_World_Cup',
    @pagina_planteles NVARCHAR(200) = N'2026_FIFA_World_Cup_squads'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @wikitext_torneo NVARCHAR(MAX), @wikitext_planteles NVARCHAR(MAX),
            @origen VARCHAR(500) = 'https://en.wikipedia.org/wiki/' + CAST(@pagina_torneo AS VARCHAR(200))
                                 + ' + ' + CAST(@pagina_planteles AS VARCHAR(200)),
            @lote_id INT, @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @i INT = 1, @registro VARCHAR(1000),
            @q_desde INT, @q_hasta INT, @r_desde INT, @r_hasta INT, @resultado VARCHAR(12),
            @codigo VARCHAR(10), @pais_id INT, @confederacion VARCHAR(20), @grupo VARCHAR(5),
            @confederacion_id INT, @seleccion_id INT, @confederacion_actual INT, @grupo_actual CHAR(1),
            @posicion INT, @ganados INT, @empatados INT, @perdidos INT, @gf INT, @gc INT;

    EXEC importacion.lote_abrir 'torneo.scrapear_selecciones', @origen, @lote_id OUTPUT;

    BEGIN TRY
        EXEC importacion.obtener_wikitext @pagina_torneo, @wikitext_torneo OUTPUT;
        EXEC importacion.obtener_wikitext @pagina_planteles, @wikitext_planteles OUTPUT;

        SELECT ordinal, CAST(value AS NVARCHAR(4000)) AS linea INTO #torneo
        FROM STRING_SPLIT(REPLACE(ISNULL(@wikitext_torneo, N''), NCHAR(13), N''), NCHAR(10), 1);
        SELECT ordinal, CAST(value AS NVARCHAR(4000)) AS linea INTO #planteles
        FROM STRING_SPLIT(REPLACE(ISNULL(@wikitext_planteles, N''), NCHAR(13), N''), NCHAR(10), 1);

        SELECT @q_desde = MIN(ordinal) FROM #torneo WHERE linea LIKE N'===Qualification===%';
        SELECT @q_hasta = MIN(ordinal) FROM #torneo WHERE ordinal > @q_desde AND linea LIKE N'==[^=]%';
        SELECT @r_desde = MIN(ordinal) FROM #torneo WHERE linea LIKE N'===Tournament ranking===%';
        SELECT @r_hasta = ISNULL(MIN(ordinal), 2147483647) FROM #torneo WHERE ordinal > @r_desde AND linea LIKE N'==%';

        IF @q_desde IS NULL OR @q_hasta IS NULL
            THROW 50003, 'El texto del torneo no contiene la sección ===Qualification===.', 1;
        IF @r_desde IS NULL
            THROW 50003, 'El texto del torneo no contiene la sección ===Tournament ranking===.', 1;
        IF NOT EXISTS (SELECT 1 FROM #planteles WHERE linea LIKE N'==Group [A-L]==%')
            THROW 50003, 'El texto de planteles no contiene los encabezados ==Group X==.', 1;
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    -- Clasificados: confederación de cada código FIFA.
    SELECT q.codigo, c.confederacion
    INTO #clasificados
    FROM (SELECT ordinal, REGEXP_SUBSTR(linea, N'flag\|fb\|([A-Z]{3})', 1, 1, 'c', 1) AS codigo
          FROM #torneo WHERE ordinal BETWEEN @q_desde AND @q_hasta AND linea LIKE N'*%flag|fb|%') q
    OUTER APPLY (SELECT TOP 1 REGEXP_SUBSTR(t.linea, N'\|(AFC|CAF|CONCACAF|CONMEBOL|OFC|UEFA)\]\]', 1, 1, 'c', 1) AS confederacion
                 FROM #torneo t
                 WHERE t.ordinal BETWEEN @q_desde AND q.ordinal
                   AND REGEXP_LIKE(t.linea, N'\|(AFC|CAF|CONCACAF|CONMEBOL|OFC|UEFA)\]\]')
                 ORDER BY t.ordinal DESC) c;

    -- Tabla final: posición (orden de team_order, salvo posiciones compartidas) y resultados.
    SELECT LTRIM(RTRIM(s.value)) AS codigo, CAST(s.ordinal AS INT) AS posicion
    INTO #orden
    FROM #torneo t
    CROSS APPLY STRING_SPLIT(SUBSTRING(t.linea, CHARINDEX(N'=', t.linea) + 1, 4000), N',', 1) s
    WHERE t.ordinal BETWEEN @r_desde AND @r_hasta AND t.linea LIKE N'|team_order=%';

    UPDATE o SET posicion = p.posicion
    FROM #orden o
    JOIN (SELECT REGEXP_SUBSTR(t.linea, N'pos_([A-Z]{3})=', 1, n.k, 'c', 1) AS codigo,
                 TRY_CONVERT(INT, REGEXP_SUBSTR(t.linea, N'pos_[A-Z]{3}=\{\{=\}\}([0-9]+)', 1, n.k, 'c', 1)) AS posicion
          FROM #torneo t CROSS JOIN (VALUES (1), (2), (3), (4)) n (k)
          WHERE t.ordinal BETWEEN @r_desde AND @r_hasta AND t.linea LIKE N'|pos[_]%') p
      ON p.codigo = o.codigo COLLATE DATABASE_DEFAULT
    WHERE p.posicion IS NOT NULL;

    SELECT REGEXP_SUBSTR(linea, N'win_([A-Z]{3})=', 1, 1, 'c', 1) AS codigo,
           REGEXP_SUBSTR(linea, N'win_[A-Z]{3}=([0-9]+)', 1, 1, 'c', 1) AS ganados,
           REGEXP_SUBSTR(linea, N'draw_[A-Z]{3}=([0-9]+)', 1, 1, 'c', 1) AS empatados,
           REGEXP_SUBSTR(linea, N'loss_[A-Z]{3}=([0-9]+)', 1, 1, 'c', 1) AS perdidos,
           REGEXP_SUBSTR(linea, N'gf_[A-Z]{3}=([0-9]+)', 1, 1, 'c', 1) AS gf,
           REGEXP_SUBSTR(linea, N'ga_[A-Z]{3}=([0-9]+)', 1, 1, 'c', 1) AS gc
    INTO #resultados
    FROM #torneo WHERE ordinal BETWEEN @r_desde AND @r_hasta AND linea LIKE N'|win[_]%';

    -- Grupo de cada selección, por su nombre en la página de planteles.
    SELECT importacion.fn_pais_id(REPLACE(e.linea, N'===', N'')) AS pais_id, g.grupo
    INTO #grupos
    FROM #planteles e
    CROSS APPLY (SELECT TOP 1 SUBSTRING(x.linea, 9, 1) AS grupo FROM #planteles x
                 WHERE x.ordinal < e.ordinal AND x.linea LIKE N'==Group [A-L]==%' ORDER BY x.ordinal DESC) g
    WHERE e.linea LIKE N'===%===%' AND e.linea NOT LIKE N'====%';

    SELECT ROW_NUMBER() OVER (ORDER BY c.confederacion, c.codigo) AS fila, c.codigo, c.confederacion,
           importacion.fn_pais_id(c.codigo) AS pais_id, o.posicion, r.ganados, r.empatados, r.perdidos, r.gf, r.gc
    INTO #selecciones
    FROM #clasificados c
    LEFT JOIN #orden o ON o.codigo = c.codigo
    LEFT JOIN #resultados r ON r.codigo = c.codigo;

    SELECT @leidos = COUNT(*) FROM #selecciones;

    WHILE @i <= @leidos
    BEGIN
        SELECT @codigo = s.codigo, @confederacion = s.confederacion, @pais_id = s.pais_id, @grupo = g.grupo,
               @posicion = s.posicion, @ganados = TRY_CONVERT(INT, s.ganados), @empatados = TRY_CONVERT(INT, s.empatados),
               @perdidos = TRY_CONVERT(INT, s.perdidos), @gf = TRY_CONVERT(INT, s.gf), @gc = TRY_CONVERT(INT, s.gc),
               @registro = CONCAT(s.codigo, ' | ', s.confederacion, ' | grupo ', g.grupo, ' | puesto ', s.posicion)
        FROM #selecciones s
        OUTER APPLY (SELECT TOP 1 grupo FROM #grupos x WHERE x.pais_id = s.pais_id) g
        WHERE s.fila = @i;
        SELECT @errores = '', @seleccion_id = NULL, @confederacion_id = NULL, @resultado = 'sin_cambios';

        BEGIN TRY
            SELECT @confederacion_id = confederacion_id FROM torneo.confederacion WHERE nombre = @confederacion;
            IF @pais_id IS NULL
                SET @errores += '- El país de código ''' + ISNULL(@codigo, '') + ''' no está registrado.' + @nl;
            IF @confederacion_id IS NULL
                SET @errores += '- No se pudo determinar la confederación.' + @nl;
            IF @grupo IS NULL
                SET @errores += '- La selección no figura en ningún grupo de la página de planteles.' + @nl;
            IF @posicion IS NULL OR @ganados IS NULL OR @empatados IS NULL OR @perdidos IS NULL OR @gf IS NULL OR @gc IS NULL
                SET @errores += '- La selección no figura completa en la tabla final del torneo.' + @nl;
            IF @errores <> ''
            BEGIN
                SET @errores = 'Fila rechazada:' + @nl + @errores;
                THROW 50004, @errores, 1;
            END;

            BEGIN TRANSACTION;

            SELECT @seleccion_id = seleccion_id, @confederacion_actual = confederacion_id, @grupo_actual = grupo
            FROM torneo.seleccion WHERE pais_id = @pais_id;

            IF @seleccion_id IS NULL
            BEGIN
                EXEC torneo.seleccion_insertar @pais_id, @confederacion_id, @grupo, @seleccion_id OUTPUT;
                SET @resultado = 'insertado';
            END
            ELSE IF @confederacion_actual <> @confederacion_id OR @grupo_actual <> @grupo
            BEGIN
                EXEC torneo.seleccion_modificar @seleccion_id, @pais_id, @confederacion_id, @grupo;
                SET @resultado = 'actualizado';
            END;

            IF NOT EXISTS (SELECT 1 FROM torneo.seleccion_estadistica WHERE seleccion_id = @seleccion_id)
            BEGIN
                INSERT INTO torneo.seleccion_estadistica (seleccion_id, posicion_final, partidos, ganados, empatados,
                       perdidos, goles_a_favor, goles_en_contra, puntos, archivo_origen)
                VALUES (@seleccion_id, @posicion, @ganados + @empatados + @perdidos, @ganados, @empatados, @perdidos,
                        @gf, @gc, 3 * @ganados + @empatados, @origen);
                IF @resultado = 'sin_cambios' SET @resultado = 'actualizado';
            END
            ELSE IF EXISTS (SELECT @posicion, @ganados, @empatados, @perdidos, @gf, @gc
                            EXCEPT
                            SELECT posicion_final, ganados, empatados, perdidos, goles_a_favor, goles_en_contra
                            FROM torneo.seleccion_estadistica WHERE seleccion_id = @seleccion_id)
            BEGIN
                UPDATE torneo.seleccion_estadistica
                SET posicion_final = @posicion, partidos = @ganados + @empatados + @perdidos, ganados = @ganados,
                    empatados = @empatados, perdidos = @perdidos, goles_a_favor = @gf, goles_en_contra = @gc,
                    puntos = 3 * @ganados + @empatados, archivo_origen = @origen, importado_en = SYSDATETIMEOFFSET()
                WHERE seleccion_id = @seleccion_id;
                IF @resultado = 'sin_cambios' SET @resultado = 'actualizado';
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

    EXEC importacion.lote_cerrar @lote_id, @leidos, @insertados, @actualizados, @sin_cambios, @rechazados;
END;
GO

-- ============================================================
-- 4. PLANTELES
-- ============================================================

/* Página de planteles: cada selección es un encabezado ===Nombre===, seguido de la línea
 "Coach: [[...]]" y de una plantilla {{nat fs g player|...}} por jugador (número, posición
 GK/DF/MF/FW, nombre, nombre para ordenar "Apellido, Nombre", fecha de nacimiento y club).
   * Nombre y apellido: el apellido son las últimas tantas palabras del nombre completo
     como palabras tenga la parte anterior a la coma del nombre para ordenar. Sin nombre
     de pila (ej. 'Casemiro'), van iguales.
   * Jugador: clave natural nombre + apellido + fecha de nacimiento.
   * Convocatoria: alta si el jugador no está vigente en la selección; cambio de dorsal si
     ya estaba. Nunca se borra: es información histórica.
   * La página trae la lista completa de cada selección que incluye: los convocados
     vigentes que ya no figuran se dan de baja con fecha y motivo (la fila queda, con
     fecha_baja). Las bajas se procesan antes que las altas, para liberar cupo y dorsales,
     y sólo en selecciones cuyas filas pasaron todas la validación de formato (una fila mal
     leída no puede dar de baja a nadie).
   * DT: alta del director técnico, o modificación si cambió.
   * Las selecciones se importan antes, con torneo.scrapear_selecciones. */

CREATE OR ALTER PROCEDURE plantel.scrapear_planteles
    @pagina             NVARCHAR(200) = N'2026_FIFA_World_Cup_squads',
    @fecha_convocatoria DATE = '2026-06-01'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @wikitext NVARCHAR(MAX), @origen VARCHAR(500) = 'https://en.wikipedia.org/wiki/' + CAST(@pagina AS VARCHAR(200)),
            @lote_id INT, @mensaje VARCHAR(2100), @numero INT, @nl CHAR(2) = CHAR(13) + CHAR(10),
            @errores VARCHAR(2000), @leidos INT = 0, @insertados INT = 0, @actualizados INT = 0,
            @sin_cambios INT = 0, @rechazados INT = 0, @bajas INT = 0, @i INT = 1, @n INT,
            @registro VARCHAR(1000), @hoy DATE = CAST(SYSDATETIME() AS DATE), @resultado VARCHAR(12),
            @seleccion_id INT, @es_dt BIT, @dorsal INT, @posicion VARCHAR(13), @nombre VARCHAR(100),
            @apellido VARCHAR(100), @fecha_nacimiento DATE, @club VARCHAR(120), @jugador_id INT,
            @posicion_actual VARCHAR(13), @club_actual VARCHAR(120), @convocatoria_id INT, @dorsal_actual INT,
            @fecha_alta DATE, @motivo_alta VARCHAR(150), @staff_id INT, @nombre_actual VARCHAR(100),
            @apellido_actual VARCHAR(100), @fecha_baja DATE;

    EXEC importacion.lote_abrir 'plantel.scrapear_planteles', @origen, @lote_id OUTPUT;

    BEGIN TRY
        EXEC importacion.obtener_wikitext @pagina, @wikitext OUTPUT;

        SELECT ordinal, CAST(value AS NVARCHAR(4000)) AS linea INTO #lineas
        FROM STRING_SPLIT(REPLACE(ISNULL(@wikitext, N''), NCHAR(13), N''), NCHAR(10), 1);

        IF NOT EXISTS (SELECT 1 FROM #lineas WHERE linea LIKE N'{{nat fs g player|%')
            THROW 50003, 'El texto no contiene planteles ({{nat fs g player|...}}).', 1;
    END TRY
    BEGIN CATCH
        SELECT @numero = ERROR_NUMBER(), @mensaje = ERROR_MESSAGE();
        EXEC importacion.lote_rechazar @lote_id, @numero, @mensaje;
        THROW;
    END CATCH;

    -- 1) Extracción: una fila por jugador o entrenador, con la selección del encabezado anterior.
    SELECT ROW_NUMBER() OVER (ORDER BY l.ordinal) AS fila, e.equipo,
           IIF(l.linea LIKE N'Coach:%', N'DT', REGEXP_SUBSTR(l.linea, N'\|pos=([^|}]*)', 1, 1, 'c', 1)) AS posicion_txt,
           REGEXP_SUBSTR(l.linea, N'\|no=([^|}]*)', 1, 1, 'c', 1) AS dorsal_txt,
           IIF(l.linea LIKE N'Coach:%',
               REGEXP_SUBSTR(l.linea, N'Coach:.*\[\[(?:[^|\]]*\|)?([^\]]+)\]\]', 1, 1, 'c', 1),
               REGEXP_SUBSTR(l.linea, N'\|name=\[\[(?:[^|\]]*\|)?([^\]]+)\]\]', 1, 1, 'c', 1)) AS jugador,
           REGEXP_SUBSTR(l.linea, N'\|sortname=([^|}]*)', 1, 1, 'c', 1) AS apellido_orden,
           CONCAT(REGEXP_SUBSTR(l.linea, N'birth date and age2\|(?:[^|0-9][^|]*\|)?[0-9]+\|[0-9]+\|[0-9]+\|([0-9]+)\|([0-9]+)\|([0-9]+)', 1, 1, 'c', 1), '-',
                  RIGHT('0' + REGEXP_SUBSTR(l.linea, N'birth date and age2\|(?:[^|0-9][^|]*\|)?[0-9]+\|[0-9]+\|[0-9]+\|([0-9]+)\|([0-9]+)\|([0-9]+)', 1, 1, 'c', 2), 2), '-',
                  RIGHT('0' + REGEXP_SUBSTR(l.linea, N'birth date and age2\|(?:[^|0-9][^|]*\|)?[0-9]+\|[0-9]+\|[0-9]+\|([0-9]+)\|([0-9]+)\|([0-9]+)', 1, 1, 'c', 3), 2)) AS fecha_txt,
           REGEXP_SUBSTR(l.linea, N'\|club=\[\[(?:[^|\]]*\|)?([^\]]+)\]\]', 1, 1, 'c', 1) AS club
    INTO #leidas
    FROM #lineas l
    OUTER APPLY (SELECT TOP 1 LTRIM(RTRIM(REPLACE(x.linea, N'===', N''))) AS equipo FROM #lineas x
                 WHERE x.ordinal < l.ordinal AND x.linea LIKE N'===%===%' AND x.linea NOT LIKE N'====%'
                 ORDER BY x.ordinal DESC) e
    WHERE l.linea LIKE N'{{nat fs g player|%' OR l.linea LIKE N'Coach:%';

    SELECT @leidos = COUNT(*) FROM #leidas;

    -- 2) Transformación por conjunto: selección, dorsal, posición, fecha, nombre y apellido.
    SELECT l.fila, l.equipo, l.jugador, l.dorsal_txt, l.posicion_txt, l.fecha_txt, l.club,
           importacion.fn_seleccion_id(l.equipo) AS seleccion_id,
           IIF(l.posicion_txt = N'DT', 1, 0) AS es_dt,
           TRY_CONVERT(INT, l.dorsal_txt) AS dorsal,
           CASE LEFT(l.posicion_txt, 2) WHEN N'GK' THEN 'arquero' WHEN N'DF' THEN 'defensor'
                WHEN N'MF' THEN 'mediocampista' WHEN N'FW' THEN 'delantero' END AS posicion,
           TRY_CONVERT(DATE, l.fecha_txt, 23) AS fecha_nacimiento,
           CAST(n.nombre AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS nombre,
           CAST(n.apellido AS VARCHAR(100)) COLLATE DATABASE_DEFAULT AS apellido
    INTO #filas
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

    ALTER TABLE #filas ADD formato_ok BIT;
    UPDATE #filas
    SET formato_ok = IIF(seleccion_id IS NOT NULL AND nombre IS NOT NULL
                         AND (es_dt = 1 OR (dorsal BETWEEN 1 AND 99 AND posicion IS NOT NULL AND fecha_nacimiento IS NOT NULL)),
                         1, 0);

    -- 3) Bajas de los convocados vigentes que la lista ya no incluye.
    SELECT IDENTITY(INT, 1, 1) AS orden, c.convocatoria_id, c.dorsal, c.fecha_alta, c.motivo_alta,
           CONCAT(j.nombre, ' ', j.apellido, ' | dorsal ', c.dorsal) AS registro
    INTO #bajas
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
        PRINT CONCAT('plantel.scrapear_planteles: ', @bajas, ' convocados dados de baja (siguen en el historial).');

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
                       @motivo_alta = motivo_alta
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

    SET @actualizados += @bajas;
    EXEC importacion.lote_cerrar @lote_id, @leidos, @insertados, @actualizados, @sin_cambios, @rechazados;
END;
GO
