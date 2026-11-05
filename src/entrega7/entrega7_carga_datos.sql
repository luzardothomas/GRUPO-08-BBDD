-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 7: Carga de datos (seed) para los reportes
-- FECHA: 05/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Juego de datos de la sección IV del enunciado ("Criterios de aceptación"), para que los
--   reportes de la Entrega 7 muestren información representativa. Todo se carga a través de
--   los SP de ABM y de lógica de negocio de la Entrega 5 (ninguna sentencia toca las tablas
--   directamente), así que cada dato pasa por las mismas validaciones que una carga real.
--
--   Cantidades (mínimo exigido entre paréntesis):
--     * 8 sedes en 4 husos horarios distintos (8 sedes, 3 husos).
--     * 16 selecciones en 4 grupos, 23 convocados cada una (16 selecciones, 23 convocados).
--     * 32 partidos: 24 de grupos + 4 cuartos + 2 semifinales (jugados, con formación titular,
--       banco, cambios, goles y tarjetas) + tercer puesto y final (programados) (24 partidos).
--     * 22 árbitros, terna completa en los 32 partidos (15 árbitros).
--     * 8 anunciantes de 8 países distintos, 9 campañas, 17 mercados (anunciantes de 6 países).
--
--   Casos obligatorios de la sección IV que quedan cargados:
--     * Expulsión por doble amarilla:     partido 11 (Brasil-Alemania), dorsal 5 de Alemania.
--     * Expulsión por roja directa:       partido 15 (España-Colombia), dorsal 5 de Colombia.
--     * Suspendido por acumulación:       dorsal 5 de Argentina (amarillas en los partidos 1 y 9):
--                                         queda afuera de la formación del partido 17.
--     * Cambio por lesión antes del 20':  partido 1, Argentina, sale el 2 y entra el 13 (17').
--     * Prime time en más de 4 mercados:  los partidos de las 01:00 UTC caen en prime time en 8
--                                         mercados (ARG, BRA, URY, USA, CAN, CHL, COL, MEX), los de
--                                         las 23:00 UTC en 6 (ARG, BRA, URY, USA, CAN, CHL) y los de
--                                         las 19:00 UTC en 6 (SEN, ENG, MAR, FRA, DEU, ESP):
--                                         publicidad.asignar_espacios_partido elige sólo 4.
--                                         Los de las 16:00 UTC no caen en prime time en ningún mercado.
--     * Designación descartada por conflicto de nacionalidad: Lote 9 (árbitro argentino
--                                         propuesto para Argentina-México).
--     * (La importación con errores parciales es de la Entrega 6.)
--   Además quedan suspensiones ACTIVAS para los reportes: dorsal 5 de Francia (acumulación,
--   pierde la final) y dorsal 5 de Brasil (roja directa, pierde el tercer puesto).
--
-- CÓMO EJECUTARLO:
--   Sobre la base recién creada: entrega5_db_definition.sql, entrega5_sp_ABM.sql y
--   entrega5_sp_logica_negocio.sql (sin ejecutar los tests de la Entrega 5, o después de su bloque
--   RESET). Si la base ya tiene selecciones, el script avisa y no carga nada. Ejecutarlo completo,
--   de una vez (los lotes comparten tablas temporales #). Si falla a mitad de camino, recrear la base.
--   No usa cursores ni SQL dinámico: los recorridos son WHILE sobre tablas temporales numeradas.
--
--   Los nombres de jugadores, cuerpos técnicos, árbitros y anunciantes son ficticios. El PBI per
--   cápita es aproximado (Banco Mundial, USD corrientes); la Entrega 6 lo actualiza por API.
--   El modelo no tiene país del anunciante: se indica en la razón social.
-- ============================================================

USE mundial_2026;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
GO

IF EXISTS (SELECT 1 FROM torneo.seleccion)
BEGIN
    RAISERROR('La base ya tiene selecciones cargadas: esta carga se ejecuta sobre la base recién creada con los scripts de la Entrega 5. No se carga nada.', 16, 1);
    SET NOEXEC ON;
END;
GO

-- ============================================================
-- Lote 1: parámetros del reglamento y criterio de suspensión
-- ============================================================
PRINT '--- Lote 1: parámetros del reglamento y criterio de suspensión';

EXEC torneo.parametro_cargar_defaults;      -- sólo carga los que falten

IF NOT EXISTS (SELECT 1 FROM evento.criterio_suspension WHERE activo = 1)
    EXEC evento.criterio_suspension_insertar @cantidad_amarillas = 2, @partidos_suspension = 1;
GO

-- ============================================================
-- Lote 2: confederaciones y países (selecciones, sedes, árbitros y mercados)
-- Husos de junio/julio 2026 (horario de verano donde corresponde).
-- ============================================================
PRINT '--- Lote 2: confederaciones y países';

DECLARE @conf TABLE (n INT IDENTITY(1, 1), nombre VARCHAR(8));
INSERT INTO @conf (nombre) VALUES ('AFC'), ('CAF'), ('CONCACAF'), ('CONMEBOL'), ('OFC'), ('UEFA');

DECLARE @pais TABLE (n INT IDENTITY(1, 1), codigo CHAR(3), nombre VARCHAR(80), huso CHAR(6), pbi NUMERIC(12,2));
INSERT INTO @pais (codigo, nombre, huso, pbi) VALUES
    ('ARG', 'Argentina',      'UTC-03', 13730.00), ('MEX', 'México',         'UTC-06', 13926.00),
    ('JPN', 'Japón',          'UTC+09', 33834.00), ('MAR', 'Marruecos',      'UTC+01',  3672.00),
    ('BRA', 'Brasil',         'UTC-03', 10043.00), ('USA', 'Estados Unidos', 'UTC-04', 82769.00),
    ('DEU', 'Alemania',       'UTC+02', 52746.00), ('KOR', 'Corea del Sur',  'UTC+09', 33121.00),
    ('FRA', 'Francia',        'UTC+02', 46315.00), ('URY', 'Uruguay',        'UTC-03', 22565.00),
    ('SEN', 'Senegal',        'UTC+00',  1707.00), ('CAN', 'Canadá',         'UTC-04', 53372.00),
    ('ESP', 'España',         'UTC+02', 33509.00), ('ENG', 'Inglaterra',     'UTC+01', 48867.00),
    ('COL', 'Colombia',       'UTC-05',  6947.00), ('AUS', 'Australia',      'UTC+10', 64712.00),
    ('ITA', 'Italia',         'UTC+02', 38373.00), ('NLD', 'Países Bajos',   'UTC+02', 64572.00),
    ('POL', 'Polonia',        'UTC+02', 22112.00), ('CHL', 'Chile',          'UTC-04', 17093.00),
    ('PER', 'Perú',           'UTC-05',  7789.00), ('SAU', 'Arabia Saudita', 'UTC+03', 30448.00),
    ('QAT', 'Catar',          'UTC+03', 81400.00), ('EGY', 'Egipto',         'UTC+03',  3512.00),
    ('NZL', 'Nueva Zelanda',  'UTC+12', 48249.00), ('PRT', 'Portugal',       'UTC+01', 27275.00);

DECLARE @i INT = 1, @nombre VARCHAR(80), @codigo CHAR(3), @huso CHAR(6), @pbi NUMERIC(12,2);

WHILE @i <= (SELECT MAX(n) FROM @conf)
BEGIN
    SELECT @nombre = nombre FROM @conf WHERE n = @i;
    IF NOT EXISTS (SELECT 1 FROM torneo.confederacion WHERE nombre = @nombre)
        EXEC torneo.confederacion_insertar @nombre = @nombre;
    SET @i += 1;
END;

SET @i = 1;
WHILE @i <= (SELECT MAX(n) FROM @pais)
BEGIN
    SELECT @codigo = codigo, @nombre = nombre, @huso = huso, @pbi = pbi FROM @pais WHERE n = @i;
    IF NOT EXISTS (SELECT 1 FROM torneo.pais WHERE codigo_iso = @codigo)
        EXEC torneo.pais_insertar @codigo_iso = @codigo, @nombre = @nombre, @huso_horario = @huso,
             @pbi_per_capita = @pbi;
    SET @i += 1;
END;
GO

-- ============================================================
-- Lote 3: sedes (8 estadios, husos UTC-04, UTC-05, UTC-06 y UTC-07)
-- ============================================================
PRINT '--- Lote 3: sedes';

DROP TABLE IF EXISTS #sede;
CREATE TABLE #sede (
    n         INT PRIMARY KEY,
    nombre    VARCHAR(80) COLLATE DATABASE_DEFAULT NOT NULL,   -- las # usan la collation de tempdb
    ciudad    VARCHAR(80) COLLATE DATABASE_DEFAULT NOT NULL,
    pais      CHAR(3) COLLATE DATABASE_DEFAULT NOT NULL,
    capacidad INT NOT NULL,
    huso      CHAR(6) COLLATE DATABASE_DEFAULT NOT NULL,
    sede_id   INT NULL
);
INSERT INTO #sede (n, nombre, ciudad, pais, capacidad, huso) VALUES
    (1, 'Estadio Azteca',    'Ciudad de México', 'MEX', 83264, 'UTC-06'),
    (2, 'Estadio BBVA',      'Monterrey',        'MEX', 53500, 'UTC-06'),
    (3, 'MetLife Stadium',   'East Rutherford',  'USA', 82500, 'UTC-04'),
    (4, 'SoFi Stadium',      'Inglewood',        'USA', 70240, 'UTC-07'),
    (5, 'AT&T Stadium',      'Arlington',        'USA', 80000, 'UTC-05'),
    (6, 'Hard Rock Stadium', 'Miami Gardens',    'USA', 64767, 'UTC-04'),
    (7, 'BMO Field',         'Toronto',          'CAN', 45736, 'UTC-04'),
    (8, 'BC Place',          'Vancouver',        'CAN', 54500, 'UTC-07');

DECLARE @i INT = 1, @nombre VARCHAR(80), @ciudad VARCHAR(80), @pais_id INT, @capacidad INT,
        @huso CHAR(6), @sede_id INT;

WHILE @i <= 8
BEGIN
    SELECT @nombre = s.nombre, @ciudad = s.ciudad, @pais_id = p.pais_id, @capacidad = s.capacidad, @huso = s.huso
    FROM #sede s JOIN torneo.pais p ON p.codigo_iso = s.pais
    WHERE s.n = @i;

    EXEC torneo.sede_insertar @nombre = @nombre, @ciudad = @ciudad, @pais_id = @pais_id,
         @capacidad = @capacidad, @huso_horario = @huso, @sede_id = @sede_id OUTPUT;

    UPDATE #sede SET sede_id = @sede_id WHERE n = @i;
    SET @i += 1;
END;
GO

-- ============================================================
-- Lote 4: selecciones (4 grupos de 4) y cuerpo técnico (director técnico y ayudante)
-- ============================================================
PRINT '--- Lote 4: selecciones y cuerpos técnicos';

DROP TABLE IF EXISTS #seleccion;
CREATE TABLE #seleccion (
    n             INT PRIMARY KEY,
    codigo        CHAR(3) COLLATE DATABASE_DEFAULT NOT NULL,
    grupo         CHAR(1) COLLATE DATABASE_DEFAULT NOT NULL,
    confederacion VARCHAR(8) COLLATE DATABASE_DEFAULT NOT NULL,
    region        VARCHAR(2) COLLATE DATABASE_DEFAULT NOT NULL,   -- pool de nombres (Lote 5)
    seleccion_id  INT NULL
);
INSERT INTO #seleccion (n, codigo, grupo, confederacion, region) VALUES
    ( 1, 'ARG', 'A', 'CONMEBOL', 'es'), ( 2, 'MEX', 'A', 'CONCACAF', 'es'),
    ( 3, 'JPN', 'A', 'AFC',      'ja'), ( 4, 'MAR', 'A', 'CAF',      'fr'),
    ( 5, 'BRA', 'B', 'CONMEBOL', 'pt'), ( 6, 'USA', 'B', 'CONCACAF', 'en'),
    ( 7, 'DEU', 'B', 'UEFA',     'de'), ( 8, 'KOR', 'B', 'AFC',      'ko'),
    ( 9, 'FRA', 'C', 'UEFA',     'fr'), (10, 'URY', 'C', 'CONMEBOL', 'es'),
    (11, 'SEN', 'C', 'CAF',      'fr'), (12, 'CAN', 'C', 'CONCACAF', 'en'),
    (13, 'ESP', 'D', 'UEFA',     'es'), (14, 'ENG', 'D', 'UEFA',     'en'),
    (15, 'COL', 'D', 'CONMEBOL', 'es'), (16, 'AUS', 'D', 'AFC',      'en');

-- Pools de nombres por región (10 nombres x 15 apellidos = 150 combinaciones) y de clubes (20).
-- Cada persona de una región recibe un número k (0..149) distinto, y la combinación sale de
-- (k * 37) % 150: como 37 y 150 son coprimos, es una permutación y nunca se repite un nombre
-- completo dentro de la región (la región más grande, 'es', tiene 5 x 23 jugadores + 10 del cuerpo técnico).
DROP TABLE IF EXISTS #pool;
CREATE TABLE #pool (region VARCHAR(2) COLLATE DATABASE_DEFAULT, tipo CHAR(1) COLLATE DATABASE_DEFAULT,
                    lista VARCHAR(500) COLLATE DATABASE_DEFAULT);
INSERT INTO #pool (region, tipo, lista) VALUES
    ('es', 'N', 'Lucas,Mateo,Santiago,Tomás,Joaquín,Nicolás,Agustín,Martín,Facundo,Emiliano'),
    ('es', 'A', 'González,Rodríguez,Fernández,López,Martínez,Pérez,Gómez,Díaz,Sánchez,Romero,Álvarez,Torres,Ruiz,Castro,Herrera'),
    ('pt', 'N', 'Gabriel,Rafael,Vinícius,Bruno,Lucas,Thiago,Felipe,Matheus,Danilo,Caio'),
    ('pt', 'A', 'Silva,Santos,Oliveira,Souza,Lima,Pereira,Costa,Almeida,Ribeiro,Carvalho,Gomes,Martins,Araújo,Barbosa,Rocha'),
    ('en', 'N', 'James,Jack,Ethan,Noah,Liam,Harry,Oliver,Tyler,Mason,Owen'),
    ('en', 'A', 'Smith,Johnson,Brown,Taylor,Walker,Wilson,Davies,Evans,Clarke,Wright,Hughes,Turner,Mitchell,Cooper,Bennett'),
    ('de', 'N', 'Lukas,Leon,Jonas,Finn,Felix,Niklas,Tim,Jan,Moritz,Paul'),
    ('de', 'A', 'Müller,Schmidt,Schneider,Fischer,Weber,Meyer,Wagner,Becker,Hoffmann,Schulz,Koch,Richter,Wolf,Neumann,Krüger'),
    ('fr', 'N', 'Hugo,Théo,Antoine,Kylian,Youssef,Moussa,Ibrahima,Karim,Achraf,Mamadou'),
    ('fr', 'A', 'Martin,Bernard,Dubois,Diallo,Ndiaye,Sarr,El Amrani,Benali,Mendy,Camara,Laurent,Girard,Faye,Ziani,Lambert'),
    ('ja', 'N', 'Haruto,Sota,Yuto,Ren,Kaito,Daiki,Takumi,Ryo,Kenji,Shota'),
    ('ja', 'A', 'Sato,Suzuki,Takahashi,Tanaka,Watanabe,Ito,Yamamoto,Nakamura,Kobayashi,Kato,Yoshida,Yamada,Sasaki,Inoue,Kimura'),
    ('ko', 'N', 'Min-jun,Seo-jun,Ji-ho,Do-yun,Hyun-woo,Jun-seo,Woo-jin,Ji-hoon,Tae-yang,Sung-min'),
    ('ko', 'A', 'Kim,Lee,Park,Choi,Jung,Kang,Cho,Yoon,Jang,Lim,Han,Oh,Seo,Shin,Kwon'),
    ('**', 'C', 'River Plate,Boca Juniors,Flamengo,Palmeiras,Club América,Tigres UANL,LA Galaxy,Inter Miami CF,'
              + 'Real Madrid,FC Barcelona,Atlético de Madrid,Manchester City,Liverpool FC,Arsenal FC,'
              + 'Bayern Múnich,Borussia Dortmund,Paris Saint-Germain,Juventus,Inter de Milán,SL Benfica');

DROP TABLE IF EXISTS #nombre;
CREATE TABLE #nombre (region VARCHAR(2) COLLATE DATABASE_DEFAULT, tipo CHAR(1) COLLATE DATABASE_DEFAULT,
                      idx INT, valor VARCHAR(100) COLLATE DATABASE_DEFAULT,
                      PRIMARY KEY (region, tipo, idx));
INSERT INTO #nombre (region, tipo, idx, valor)
SELECT p.region, p.tipo, CAST(s.ordinal AS INT) - 1, s.value
FROM #pool p
CROSS APPLY STRING_SPLIT(p.lista, ',', 1) s;

DECLARE @s INT = 1, @pais_id INT, @conf_id INT, @grupo CHAR(1), @region VARCHAR(2), @seleccion_id INT,
        @r INT, @k INT, @nombre VARCHAR(100), @apellido VARCHAR(100);

WHILE @s <= 16
BEGIN
    SELECT @pais_id = p.pais_id, @conf_id = c.confederacion_id, @grupo = s.grupo, @region = s.region
    FROM #seleccion s
    JOIN torneo.pais p          ON p.codigo_iso = s.codigo
    JOIN torneo.confederacion c ON c.nombre = s.confederacion
    WHERE s.n = @s;

    EXEC torneo.seleccion_insertar @pais_id = @pais_id, @confederacion_id = @conf_id, @grupo = @grupo,
         @seleccion_id = @seleccion_id OUTPUT;
    UPDATE #seleccion SET seleccion_id = @seleccion_id WHERE n = @s;

    -- Cuerpo técnico: k = 140 + 2r y 141 + 2r (r = orden de la selección dentro de su región);
    -- los jugadores usan k de 0 a 114 (Lote 5).
    SET @r = (SELECT COUNT(*) FROM #seleccion WHERE region = @region AND n < @s);

    SET @k = (140 + 2 * @r) * 37 % 150;
    SELECT @nombre   = valor FROM #nombre WHERE region = @region AND tipo = 'N' AND idx = @k % 10;
    SELECT @apellido = valor FROM #nombre WHERE region = @region AND tipo = 'A' AND idx = @k / 10;
    EXEC plantel.cuerpo_tecnico_insertar @seleccion_id = @seleccion_id, @nombre = @nombre,
         @apellido = @apellido, @rol = 'director_tecnico';

    SET @k = (141 + 2 * @r) * 37 % 150;
    SELECT @nombre   = valor FROM #nombre WHERE region = @region AND tipo = 'N' AND idx = @k % 10;
    SELECT @apellido = valor FROM #nombre WHERE region = @region AND tipo = 'A' AND idx = @k / 10;
    EXEC plantel.cuerpo_tecnico_insertar @seleccion_id = @seleccion_id, @nombre = @nombre,
         @apellido = @apellido, @rol = 'ayudante_tecnico';

    SET @s += 1;
END;
GO

-- ============================================================
-- Lote 5: jugadores y convocatoria (23 por selección) + un reemplazo de último momento
--   Dorsal 1, 12 y 23: arqueros; 2-6 y 13-15: defensores; 7, 8 y 16-19: mediocampistas;
--   9-11 y 20-22: delanteros. Fechas de nacimiento distintas para cada jugador.
-- ============================================================
PRINT '--- Lote 5: jugadores y convocatorias (16 x 23)';

DECLARE @s INT = 1, @d INT, @r INT, @k INT, @region VARCHAR(2), @seleccion_id INT, @nombre VARCHAR(100),
        @apellido VARCHAR(100), @club VARCHAR(120), @posicion VARCHAR(13), @fecha_nac DATE, @jugador_id INT;

WHILE @s <= 16
BEGIN
    SELECT @region = region, @seleccion_id = seleccion_id FROM #seleccion WHERE n = @s;
    SET @r = (SELECT COUNT(*) FROM #seleccion WHERE region = @region AND n < @s);
    SET @d = 1;
    WHILE @d <= 23
    BEGIN
        SET @k = (@r * 23 + @d - 1) * 37 % 150;            -- combinación única dentro de la región
        SELECT @nombre   = valor FROM #nombre WHERE region = @region AND tipo = 'N' AND idx = @k % 10;
        SELECT @apellido = valor FROM #nombre WHERE region = @region AND tipo = 'A' AND idx = @k / 10;
        SELECT @club     = valor FROM #nombre WHERE region = '**' AND tipo = 'C' AND idx = (@d * 5 + @s * 3) % 20;
        SET @posicion = CASE WHEN @d IN (1, 12, 23)                 THEN 'arquero'
                             WHEN @d IN (2, 3, 4, 5, 6, 13, 14, 15) THEN 'defensor'
                             WHEN @d IN (7, 8, 16, 17, 18, 19)      THEN 'mediocampista'
                             ELSE 'delantero' END;
        SET @fecha_nac = DATEADD(DAY, -9 * (@s * 23 + @d), '2005-06-30');

        EXEC plantel.jugador_insertar @nombre = @nombre, @apellido = @apellido, @fecha_nacimiento = @fecha_nac,
             @posicion_habitual = @posicion, @club_origen = @club, @jugador_id = @jugador_id OUTPUT;
        EXEC plantel.convocatoria_insertar @seleccion_id = @seleccion_id, @jugador_id = @jugador_id,
             @dorsal = @d, @fecha_alta = '2026-06-01', @motivo_alta = 'Lista oficial de convocados';
        SET @d += 1;
    END;
    SET @s += 1;
END;

-- Baja de último momento: Francia reemplaza al dorsal 20 (lesionado) antes de su debut.
DECLARE @fra INT = (SELECT seleccion_id FROM #seleccion WHERE codigo = 'FRA'),
        @sale INT, @entra INT;
SELECT @sale = jugador_id FROM plantel.convocatoria
WHERE seleccion_id = @fra AND dorsal = 20 AND fecha_baja IS NULL;

EXEC plantel.jugador_insertar @nombre = 'Hugo', @apellido = 'Marchand', @fecha_nacimiento = '2001-03-14',
     @posicion_habitual = 'delantero', @club_origen = 'Olympique de Marsella', @jugador_id = @entra OUTPUT;
EXEC plantel.reemplazar_convocado @seleccion_id = @fra, @jugador_sale_id = @sale, @jugador_entra_id = @entra,
     @fecha = '2026-06-08', @motivo = 'Lesión muscular en el último entrenamiento';
GO

-- ============================================================
-- Lote 6: árbitros (22: 15 de países sin selección y 7 de países con selección) e idiomas
-- ============================================================
PRINT '--- Lote 6: árbitros';

DECLARE @arb TABLE (n INT IDENTITY(1, 1), nombre VARCHAR(100), apellido VARCHAR(100), pais CHAR(3),
                    categoria VARCHAR(13), fecha_nac DATE, idioma1 VARCHAR(10), idioma2 VARCHAR(10));
INSERT INTO @arb (nombre, apellido, pais, categoria, fecha_nac, idioma1, idioma2) VALUES
    ('Marco',    'Bellandi',     'ITA', 'FIFA',          '1984-04-11', 'italiano',   'ingles'),
    ('Davide',   'Rinaldi',      'ITA', 'FIFA',          '1987-09-02', 'italiano',   'ingles'),
    ('Pieter',   'Van Heerden',  'NLD', 'FIFA',          '1983-01-25', 'neerlandes', 'ingles'),
    ('Joost',    'Verhaegen',    'NLD', 'confederacion', '1989-06-17', 'neerlandes', 'ingles'),
    ('Tomasz',   'Kowalczyk',    'POL', 'FIFA',          '1985-11-30', 'polaco',     'ingles'),
    ('Bartosz',  'Zielinski',    'POL', 'confederacion', '1990-02-08', 'polaco',     'ingles'),
    ('Rodrigo',  'Valdivia',     'CHL', 'FIFA',          '1982-07-21', 'espanol',    'ingles'),
    ('Felipe',   'Araya',        'CHL', 'confederacion', '1988-12-05', 'espanol',    NULL),
    ('Kevin',    'Ortiz',        'PER', 'FIFA',          '1986-03-14', 'espanol',    'ingles'),
    ('Faisal',   'Al-Harbi',     'SAU', 'FIFA',          '1984-10-09', 'arabe',      'ingles'),
    ('Turki',    'Al-Qahtani',   'SAU', 'confederacion', '1991-05-27', 'arabe',      'ingles'),
    ('Abdulla',  'Al-Marri',     'QAT', 'FIFA',          '1985-08-19', 'arabe',      'ingles'),
    ('Mahmoud',  'Fathy',        'EGY', 'FIFA',          '1983-02-28', 'arabe',      'frances'),
    ('Liam',     'Cartwright',   'NZL', 'FIFA',          '1987-04-03', 'ingles',     NULL),
    ('Nuno',     'Esteves',      'PRT', 'FIFA',          '1986-01-16', 'portugues',  'espanol'),
    ('Hernán',   'Bustos',       'ARG', 'FIFA',          '1984-09-12', 'espanol',    'ingles'),
    ('Marcelo',  'Antunes',      'BRA', 'FIFA',          '1985-05-06', 'portugues',  'espanol'),
    ('Lukas',    'Hartmann',     'DEU', 'FIFA',          '1986-11-22', 'aleman',     'ingles'),
    ('Antoine',  'Lefebvre',     'FRA', 'FIFA',          '1983-07-30', 'frances',    'ingles'),
    ('Jordan',   'Kessler',      'USA', 'FIFA',          '1988-03-01', 'ingles',     'espanol'),
    ('Óscar',    'Medina',       'MEX', 'confederacion', '1987-12-12', 'espanol',    'ingles'),
    ('Kenta',    'Morimoto',     'JPN', 'FIFA',          '1986-08-08', 'japones',    'ingles');

DECLARE @i INT = 1, @nombre VARCHAR(100), @apellido VARCHAR(100), @pais_id INT, @categoria VARCHAR(13),
        @fecha_nac DATE, @idioma1 VARCHAR(10), @idioma2 VARCHAR(10), @arbitro_id INT;

WHILE @i <= (SELECT MAX(n) FROM @arb)
BEGIN
    SELECT @nombre = a.nombre, @apellido = a.apellido, @pais_id = p.pais_id, @categoria = a.categoria,
           @fecha_nac = a.fecha_nac, @idioma1 = a.idioma1, @idioma2 = a.idioma2
    FROM @arb a JOIN torneo.pais p ON p.codigo_iso = a.pais
    WHERE a.n = @i;

    EXEC arbitraje.arbitro_insertar @nombre = @nombre, @apellido = @apellido, @pais_id = @pais_id,
         @categoria = @categoria, @fecha_nacimiento = @fecha_nac, @arbitro_id = @arbitro_id OUTPUT;
    EXEC arbitraje.arbitro_idioma_insertar @arbitro_id = @arbitro_id, @idioma = @idioma1;
    IF @idioma2 IS NOT NULL
        EXEC arbitraje.arbitro_idioma_insertar @arbitro_id = @arbitro_id, @idioma = @idioma2;
    SET @i += 1;
END;
GO

-- ============================================================
-- Lote 7: publicidad: anunciantes (8 países), campañas, países de interés y piezas (USD)
-- Los países de interés de cada campaña son los mercados de sus piezas.
-- La campaña 'Fase de grupos' sólo está vigente hasta el 22/06 (no compite en eliminación).
-- ============================================================
PRINT '--- Lote 7: anunciantes, campañas y piezas';

DECLARE @anun TABLE (n INT PRIMARY KEY, nombre VARCHAR(100), razon_social VARCHAR(150), contacto VARCHAR(100),
                     anunciante_id INT NULL);
INSERT INTO @anun (n, nombre, razon_social, contacto) VALUES
    (1, 'Banco Pampa',      'Banco Pampa S.A. (Argentina)',          'comercial@bancopampa.example'),
    (2, 'Samba Bebidas',    'Samba Bebidas Ltda. (Brasil)',          'marketing@sambabebidas.example'),
    (3, 'NorthStar Motors', 'NorthStar Motors Inc. (Estados Unidos)', 'ads@northstarmotors.example'),
    (4, 'Sakura Tech',      'Sakura Tech K.K. (Japón)',              'media@sakuratech.example'),
    (5, 'Banque Lumière',   'Banque Lumière S.A. (Francia)',         'pub@banquelumiere.example'),
    (6, 'Autohaus Rhein',   'Autohaus Rhein GmbH (Alemania)',        'werbung@autohausrhein.example'),
    (7, 'Andes Energía',    'Andes Energía SpA (Chile)',             'marketing@andesenergia.example'),
    (8, 'Iberia Telecom',   'Iberia Telecom S.L. (España)',          'publicidad@iberiatelecom.example');

DECLARE @camp TABLE (n INT PRIMARY KEY, anunciante_n INT, nombre VARCHAR(100), inicio DATE, fin DATE,
                     campania_id INT NULL);
INSERT INTO @camp (n, anunciante_n, nombre, inicio, fin) VALUES
    (1, 1, 'Pasión Albiceleste',  '2026-06-01', '2026-07-31'),
    (2, 2, 'Joga Bonito',         '2026-06-01', '2026-07-31'),
    (3, 3, 'Drive the Cup',       '2026-06-01', '2026-07-31'),
    (4, 4, 'Next Goal',           '2026-06-01', '2026-07-31'),
    (5, 5, 'Allez les Bleus',     '2026-06-01', '2026-07-31'),
    (6, 6, 'Tor!',                '2026-06-01', '2026-07-31'),
    (7, 7, 'Energía que juega',   '2026-06-01', '2026-07-31'),
    (8, 8, 'Conecta el Mundial',  '2026-06-01', '2026-07-31'),
    (9, 1, 'Fase de grupos',      '2026-06-11', '2026-06-22');

DECLARE @pieza TABLE (n INT IDENTITY(1, 1), campania_n INT, pais CHAR(3), idioma VARCHAR(10), tarifa NUMERIC(12,2));
INSERT INTO @pieza (campania_n, pais, idioma, tarifa) VALUES
    (1, 'ARG', 'espanol',   90000), (1, 'URY', 'espanol',   45000),
    (2, 'BRA', 'portugues', 95000), (2, 'ARG', 'espanol',   60000), (2, 'USA', 'ingles',    70000),
    (3, 'USA', 'ingles',   150000), (3, 'CAN', 'ingles',    85000), (3, 'MEX', 'espanol',   75000),
    (4, 'JPN', 'japones',  110000), (4, 'KOR', 'coreano',   80000), (4, 'AUS', 'ingles',    70000),
    (4, 'USA', 'ingles',   120000),
    (5, 'FRA', 'frances',  100000), (5, 'SEN', 'frances',   40000), (5, 'MAR', 'frances',   45000),
    (5, 'CAN', 'frances',   50000),
    (6, 'DEU', 'aleman',   105000), (6, 'ENG', 'ingles',    95000), (6, 'ESP', 'espanol',   85000),
    (7, 'CHL', 'espanol',   50000), (7, 'COL', 'espanol',   45000), (7, 'URY', 'espanol',   40000),
    (7, 'BRA', 'portugues', 60000),
    (8, 'ESP', 'espanol',   90000), (8, 'MEX', 'espanol',   70000), (8, 'COL', 'espanol',   50000),
    (8, 'ARG', 'espanol',   55000),
    (9, 'ARG', 'espanol',   30000);

DECLARE @i INT = 1, @nombre VARCHAR(100), @razon VARCHAR(150), @contacto VARCHAR(100), @id INT,
        @anunciante_id INT, @inicio DATE, @fin DATE, @campania_id INT, @pais_id INT, @idioma VARCHAR(10),
        @tarifa NUMERIC(12,2);

WHILE @i <= 8
BEGIN
    SELECT @nombre = nombre, @razon = razon_social, @contacto = contacto FROM @anun WHERE n = @i;
    EXEC publicidad.anunciante_insertar @nombre = @nombre, @razon_social = @razon, @contacto = @contacto,
         @anunciante_id = @id OUTPUT;
    UPDATE @anun SET anunciante_id = @id WHERE n = @i;
    SET @i += 1;
END;

SET @i = 1;
WHILE @i <= 9
BEGIN
    SELECT @anunciante_id = a.anunciante_id, @nombre = c.nombre, @inicio = c.inicio, @fin = c.fin
    FROM @camp c JOIN @anun a ON a.n = c.anunciante_n
    WHERE c.n = @i;
    EXEC publicidad.campania_insertar @anunciante_id = @anunciante_id, @nombre = @nombre,
         @fecha_inicio = @inicio, @fecha_fin = @fin, @campania_id = @id OUTPUT;
    UPDATE @camp SET campania_id = @id WHERE n = @i;
    SET @i += 1;
END;

SET @i = 1;
WHILE @i <= (SELECT MAX(n) FROM @pieza)
BEGIN
    SELECT @campania_id = c.campania_id, @pais_id = p.pais_id, @idioma = pz.idioma, @tarifa = pz.tarifa
    FROM @pieza pz
    JOIN @camp c        ON c.n = pz.campania_n
    JOIN torneo.pais p  ON p.codigo_iso = pz.pais
    WHERE pz.n = @i;

    IF NOT EXISTS (SELECT 1 FROM publicidad.campania_pais_interes WHERE campania_id = @campania_id AND pais_id = @pais_id)
        EXEC publicidad.campania_pais_interes_insertar @campania_id = @campania_id, @pais_id = @pais_id;
    EXEC publicidad.pieza_publicitaria_insertar @campania_id = @campania_id, @idioma = @idioma,
         @pais_mercado_id = @pais_id, @costo_tarifa = @tarifa;
    SET @i += 1;
END;
GO

-- ============================================================
-- Lote 8: fixture (32 partidos)
--   Grupos: del 11 al 22 de junio, dos partidos por jornada (alternando 16:00/23:00 UTC y
--   19:00/01:00 UTC, para que la matriz de prime time tenga partidos con 0, 6 y 8 mercados en
--   prime time); cada selección juega cada 4 días. Cuartos: 1.º A-2.º B, 1.º C-2.º D, 1.º B-2.º A,
--   1.º D-2.º C.
--   jugar = 0: tercer puesto y final quedan programados (sin formaciones ni resultado).
--   en_contra = 'L': el primer gol del local es en contra (lo marca un defensor visitante).
-- ============================================================
PRINT '--- Lote 8: fixture';

DROP TABLE IF EXISTS #fixture;
CREATE TABLE #fixture (
    n          INT PRIMARY KEY,
    fase       VARCHAR(13) COLLATE DATABASE_DEFAULT NOT NULL,
    local      CHAR(3) COLLATE DATABASE_DEFAULT NOT NULL,
    visitante  CHAR(3) COLLATE DATABASE_DEFAULT NOT NULL,
    fecha_utc  DATETIME2(0) NOT NULL,
    sede_n     INT NOT NULL,
    gl         INT NULL,
    gv         INT NULL,
    pl         INT NULL,
    pv         INT NULL,
    jugar      BIT NOT NULL,
    en_contra  CHAR(1) COLLATE DATABASE_DEFAULT NULL,
    partido_id INT NULL
);
INSERT INTO #fixture (n, fase, local, visitante, fecha_utc, sede_n, gl, gv, pl, pv, jugar, en_contra) VALUES
    ( 1, 'grupos',        'ARG', 'MEX', '2026-06-11 16:00', 1, 2, 0, NULL, NULL, 1, NULL),
    ( 2, 'grupos',        'JPN', 'MAR', '2026-06-11 23:00', 2, 1, 1, NULL, NULL, 1, NULL),
    ( 3, 'grupos',        'BRA', 'USA', '2026-06-12 19:00', 3, 1, 1, NULL, NULL, 1, NULL),
    ( 4, 'grupos',        'DEU', 'KOR', '2026-06-13 01:00', 4, 2, 0, NULL, NULL, 1, NULL),
    ( 5, 'grupos',        'FRA', 'URY', '2026-06-13 16:00', 5, 1, 0, NULL, NULL, 1, NULL),
    ( 6, 'grupos',        'SEN', 'CAN', '2026-06-13 23:00', 6, 2, 1, NULL, NULL, 1, NULL),
    ( 7, 'grupos',        'ESP', 'ENG', '2026-06-14 19:00', 7, 1, 1, NULL, NULL, 1, NULL),
    ( 8, 'grupos',        'COL', 'AUS', '2026-06-15 01:00', 8, 2, 1, NULL, NULL, 1, NULL),
    ( 9, 'grupos',        'ARG', 'JPN', '2026-06-15 16:00', 1, 3, 1, NULL, NULL, 1, NULL),
    (10, 'grupos',        'MEX', 'MAR', '2026-06-15 23:00', 2, 1, 0, NULL, NULL, 1, NULL),
    (11, 'grupos',        'BRA', 'DEU', '2026-06-16 19:00', 3, 2, 1, NULL, NULL, 1, NULL),
    (12, 'grupos',        'USA', 'KOR', '2026-06-17 01:00', 4, 3, 1, NULL, NULL, 1, 'L'),
    (13, 'grupos',        'FRA', 'SEN', '2026-06-17 16:00', 5, 2, 2, NULL, NULL, 1, NULL),
    (14, 'grupos',        'URY', 'CAN', '2026-06-17 23:00', 6, 2, 0, NULL, NULL, 1, NULL),
    (15, 'grupos',        'ESP', 'COL', '2026-06-18 19:00', 7, 3, 0, NULL, NULL, 1, NULL),
    (16, 'grupos',        'ENG', 'AUS', '2026-06-19 01:00', 8, 2, 0, NULL, NULL, 1, NULL),
    (17, 'grupos',        'MAR', 'ARG', '2026-06-19 16:00', 1, 0, 1, NULL, NULL, 1, NULL),
    (18, 'grupos',        'MEX', 'JPN', '2026-06-19 23:00', 2, 2, 2, NULL, NULL, 1, NULL),
    (19, 'grupos',        'KOR', 'BRA', '2026-06-20 19:00', 3, 0, 2, NULL, NULL, 1, NULL),
    (20, 'grupos',        'USA', 'DEU', '2026-06-21 01:00', 4, 1, 1, NULL, NULL, 1, NULL),
    (21, 'grupos',        'CAN', 'FRA', '2026-06-21 16:00', 5, 0, 3, NULL, NULL, 1, NULL),
    (22, 'grupos',        'URY', 'SEN', '2026-06-21 23:00', 6, 1, 0, NULL, NULL, 1, NULL),
    (23, 'grupos',        'AUS', 'ESP', '2026-06-22 19:00', 7, 0, 4, NULL, NULL, 1, NULL),
    (24, 'grupos',        'ENG', 'COL', '2026-06-23 01:00', 8, 1, 1, NULL, NULL, 1, NULL),
    (25, 'cuartos',       'ARG', 'USA', '2026-06-25 19:00', 1, 2, 1, NULL, NULL, 1, NULL),
    (26, 'cuartos',       'FRA', 'ENG', '2026-06-25 23:00', 3, 2, 0, NULL, NULL, 1, NULL),
    (27, 'cuartos',       'BRA', 'MEX', '2026-06-26 16:00', 2, 1, 1,    4,    3, 1, NULL),
    (28, 'cuartos',       'ESP', 'URY', '2026-06-27 01:00', 4, 0, 0,    3,    4, 1, NULL),
    (29, 'semifinal',     'ARG', 'BRA', '2026-06-29 23:00', 3, 2, 1, NULL, NULL, 1, NULL),
    (30, 'semifinal',     'FRA', 'URY', '2026-06-30 23:00', 1, 3, 2, NULL, NULL, 1, NULL),
    (31, 'tercer_puesto', 'BRA', 'URY', '2026-07-03 23:00', 4, NULL, NULL, NULL, NULL, 0, NULL),
    (32, 'final',         'ARG', 'FRA', '2026-07-04 23:00', 3, NULL, NULL, NULL, NULL, 0, NULL);

DECLARE @n INT = 1, @sede_id INT, @local_dto DATETIMEOFFSET, @fase VARCHAR(13), @sl INT, @sv INT, @partido_id INT;

WHILE @n <= 32
BEGIN
    SELECT @sede_id = s.sede_id,
           @local_dto = SWITCHOFFSET(TODATETIMEOFFSET(f.fecha_utc, '+00:00'), SUBSTRING(s.huso, 4, 3) + ':00'),
           @fase = f.fase, @sl = l.seleccion_id, @sv = v.seleccion_id
    FROM #fixture f
    JOIN #sede s      ON s.n = f.sede_n
    JOIN #seleccion l ON l.codigo = f.local
    JOIN #seleccion v ON v.codigo = f.visitante
    WHERE f.n = @n;

    EXEC torneo.partido_insertar @sede_id = @sede_id, @fecha_hora_local = @local_dto, @fase = @fase,
         @seleccion_local_id = @sl, @seleccion_visitante_id = @sv, @partido_id = @partido_id OUTPUT;
    UPDATE #fixture SET partido_id = @partido_id WHERE n = @n;
    SET @n += 1;
END;
GO

-- ============================================================
-- Lote 9: designación descartada por conflicto de nacionalidad (caso obligatorio)
--   Se propone al árbitro argentino como principal de Argentina-México: arbitraje.designar_arbitros
--   debe rechazar la terna completa (THROW 50002). La terna válida se designa en el Lote 10.
-- ============================================================
PRINT '--- Lote 9: designación con conflicto de nacionalidad (debe rechazarse)';

DECLARE @partido_id INT = (SELECT partido_id FROM #fixture WHERE n = 1),
        @arg INT, @a1 INT, @a2 INT, @a3 INT, @a4 INT;

SELECT @arg = a.arbitro_id FROM arbitraje.arbitro a JOIN torneo.pais p ON p.pais_id = a.pais_id
WHERE p.codigo_iso = 'ARG';
SELECT @a1 = NULLIF(MAX(IIF(rn = 1, arbitro_id, 0)), 0), @a2 = NULLIF(MAX(IIF(rn = 2, arbitro_id, 0)), 0),
       @a3 = NULLIF(MAX(IIF(rn = 3, arbitro_id, 0)), 0), @a4 = NULLIF(MAX(IIF(rn = 4, arbitro_id, 0)), 0)
FROM (SELECT a.arbitro_id, ROW_NUMBER() OVER (ORDER BY a.arbitro_id) AS rn
      FROM arbitraje.arbitro a JOIN torneo.pais p ON p.pais_id = a.pais_id
      WHERE p.codigo_iso IN ('ITA', 'NLD')) x;

BEGIN TRY
    EXEC arbitraje.designar_arbitros @partido_id = @partido_id, @principal_id = @arg, @asistente_1_id = @a1,
         @asistente_2_id = @a2, @cuarto_id = @a3, @var_id = @a4;
    PRINT 'ERROR DE LA CARGA: la designación con conflicto de nacionalidad fue aceptada.';
END TRY
BEGIN CATCH
    PRINT 'Designación descartada, como se esperaba:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- Lote 10: desarrollo del torneo, partido por partido y en orden cronológico
--   a) Terna arbitral: los 5 árbitros disponibles (sin conflicto de nacionalidad y sin otro
--      partido a menos de 24 h) con menos designaciones; el principal, de categoría FIFA.
--   b) Asignación de los 4 espacios publicitarios (criterio de la Entrega 5).
--   Sólo para los partidos jugados:
--   c) Formaciones 4-3-3: titulares los dorsales 1 a 11 disponibles (un suspendido para ese
--      partido queda afuera y lo reemplaza el siguiente de campo), banco el resto.
--   d) Cambios: el de lesión del partido 1 y, por equipo, 7 (60'), 8 y 11 (75') por suplentes.
--   e) Tarjetas: las de los casos obligatorios y una amarilla por partido a un defensor
--      (dorsales 2, 3, 4 o 6, rotando). Las suspensiones las calcula evento.registrar_tarjeta.
--   f) Goles: en orden, los marcan los dorsales 9, 10, 7, 9 y 10 (con asistencia, salvo penal
--      y tiro libre); un gol en contra en el partido 12.
--   g) Resultado y asistencia (registrar_resultado, que además deja exhibidas las piezas).
--   h) Facturación de la pauta, salvo en las semifinales (quedan exhibidas, pendientes de facturar).
--   Todo el lote es una transacción: si algo falla no queda el torneo a medio cargar.
-- ============================================================
PRINT '--- Lote 10: desarrollo del torneo';

DROP TABLE IF EXISTS #tarjeta_extra;
CREATE TABLE #tarjeta_extra (
    id             INT IDENTITY(1, 1) PRIMARY KEY,
    n              INT NOT NULL,                 -- partido del fixture
    condicion      VARCHAR(9) COLLATE DATABASE_DEFAULT NOT NULL,
    dorsal         INT NULL,                     -- NULL: director técnico
    minuto         INT NOT NULL,
    periodo        VARCHAR(19) COLLATE DATABASE_DEFAULT NOT NULL,
    tipo           VARCHAR(8) COLLATE DATABASE_DEFAULT NOT NULL,
    tipo_expulsion VARCHAR(14) COLLATE DATABASE_DEFAULT NULL,
    motivo         VARCHAR(150) COLLATE DATABASE_DEFAULT NOT NULL
);
INSERT INTO #tarjeta_extra (n, condicion, dorsal, minuto, periodo, tipo, tipo_expulsion, motivo) VALUES
    ( 1, 'local',     5,    28, 'PT', 'amarilla', NULL,           'Falta táctica'),
    ( 5, 'visitante', NULL, 55, 'ST', 'amarilla', NULL,           'Protestas reiteradas'),
    ( 9, 'local',     5,    61, 'ST', 'amarilla', NULL,           'Demora en la reanudación'),
    (11, 'visitante', 5,    38, 'PT', 'amarilla', NULL,           'Falta'),
    (11, 'visitante', 5,    71, 'ST', 'amarilla', NULL,           'Mano intencional'),     -- 2.ª amarilla: doble amarilla
    (15, 'visitante', 5,    63, 'ST', 'roja',     'roja_directa', 'Juego brusco grave'),
    (26, 'local',     5,    44, 'PT', 'amarilla', NULL,           'Falta'),
    (29, 'visitante', 5,    85, 'ST', 'roja',     'roja_directa', 'Agresión a un rival'),
    (30, 'local',     5,    52, 'ST', 'amarilla', NULL,           'Conducta antideportiva');

DECLARE @n INT = 1, @partido_id INT, @fase VARCHAR(13), @jugar BIT, @gl INT, @gv INT, @pl INT, @pv INT,
        @en_contra CHAR(1), @fecha DATE, @fecha_utc DATETIMEOFFSET, @pais_l INT, @pais_v INT, @capacidad INT,
        @principal INT, @a1 INT, @a2 INT, @a3 INT, @a4 INT, @advertencia VARCHAR(1000),
        @lado INT, @condicion VARCHAR(9), @rival VARCHAR(9), @seleccion_id INT, @formacion_id INT,
        @k INT, @goles INT, @dorsal INT, @dorsal2 INT, @minuto INT, @periodo VARCHAR(19), @motivo VARCHAR(150),
        @tipo VARCHAR(8), @tipo_expulsion VARCHAR(14), @tipo_gol VARCHAR(15), @asist INT, @persona_id INT,
        @objetivo INT, @asistencia INT, @t INT;
DECLARE @jugadores plantel.tt_formacion_jugador;
DECLARE @disp TABLE (arbitro_id INT PRIMARY KEY, categoria VARCHAR(13), n_total INT, n_principal INT);

BEGIN TRY
    BEGIN TRANSACTION;

    WHILE @n <= 32
    BEGIN
        SELECT @partido_id = f.partido_id, @fase = f.fase, @jugar = f.jugar, @gl = f.gl, @gv = f.gv,
               @pl = f.pl, @pv = f.pv, @en_contra = f.en_contra
        FROM #fixture f WHERE f.n = @n;

        SELECT @fecha = CAST(p.fecha_hora_utc AS DATE), @fecha_utc = p.fecha_hora_utc,
               @pais_l = sl.pais_id, @pais_v = sv.pais_id, @capacidad = se.capacidad
        FROM torneo.partido p
        JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
        JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
        JOIN torneo.sede se      ON se.sede_id = p.sede_id
        WHERE p.partido_id = @partido_id;

        -- a) Terna arbitral
        DELETE FROM @disp;
        INSERT INTO @disp (arbitro_id, categoria, n_total, n_principal)
        SELECT a.arbitro_id, a.categoria,
               (SELECT COUNT(*) FROM arbitraje.designacion_arbitral d WHERE d.arbitro_id = a.arbitro_id),
               (SELECT COUNT(*) FROM arbitraje.designacion_arbitral d
                WHERE d.arbitro_id = a.arbitro_id AND d.rol = 'principal')
        FROM arbitraje.arbitro a
        WHERE a.pais_id NOT IN (@pais_l, @pais_v)
          AND NOT EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral d
                          JOIN torneo.partido p2 ON p2.partido_id = d.partido_id
                          WHERE d.arbitro_id = a.arbitro_id
                            AND ABS(DATEDIFF(MINUTE, p2.fecha_hora_utc, @fecha_utc)) < 24 * 60);

        SET @principal = NULL;
        SELECT TOP (1) @principal = arbitro_id FROM @disp
        ORDER BY IIF(categoria = 'FIFA', 0, 1), n_principal, n_total, arbitro_id;

        SELECT @a1 = NULLIF(MAX(IIF(rn = 1, arbitro_id, 0)), 0), @a2 = NULLIF(MAX(IIF(rn = 2, arbitro_id, 0)), 0),
               @a3 = NULLIF(MAX(IIF(rn = 3, arbitro_id, 0)), 0), @a4 = NULLIF(MAX(IIF(rn = 4, arbitro_id, 0)), 0)
        FROM (SELECT arbitro_id, ROW_NUMBER() OVER (ORDER BY n_total, arbitro_id) AS rn
              FROM @disp WHERE arbitro_id <> @principal) x;

        EXEC arbitraje.designar_arbitros @partido_id = @partido_id, @principal_id = @principal,
             @asistente_1_id = @a1, @asistente_2_id = @a2, @cuarto_id = @a3, @var_id = @a4,
             @advertencia = @advertencia OUTPUT;

        -- b) Espacios publicitarios
        EXEC publicidad.asignar_espacios_partido @partido_id = @partido_id, @mostrar_detalle = 0;

        IF @jugar = 1
        BEGIN
            -- c) Formaciones
            SET @lado = 1;
            WHILE @lado <= 2
            BEGIN
                SET @condicion = IIF(@lado = 1, 'local', 'visitante');
                SELECT @seleccion_id = IIF(@lado = 1, seleccion_local_id, seleccion_visitante_id)
                FROM torneo.partido WHERE partido_id = @partido_id;

                DELETE FROM @jugadores;
                WITH disponibles AS (
                    SELECT c.jugador_id, j.posicion_habitual,
                           ROW_NUMBER() OVER (ORDER BY CASE WHEN c.dorsal BETWEEN 1 AND 11 THEN c.dorsal
                                                            WHEN c.dorsal IN (12, 23)      THEN 100 + c.dorsal
                                                            ELSE 20 + c.dorsal END) AS rn
                    FROM plantel.convocatoria c
                    JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
                    WHERE c.seleccion_id = @seleccion_id
                      AND c.fecha_alta <= @fecha AND (c.fecha_baja IS NULL OR c.fecha_baja > @fecha)
                      AND NOT EXISTS (SELECT 1 FROM evento.suspension s
                                      JOIN evento.tarjeta t ON t.tarjeta_id = s.tarjeta_id
                                      WHERE s.partido_afectado_id = @partido_id AND t.persona_id = j.persona_id)
                )
                INSERT INTO @jugadores (jugador_id, posicion, titular)
                SELECT jugador_id, posicion_habitual, IIF(rn <= 11, 1, 0)
                FROM disponibles WHERE rn <= 26;

                EXEC plantel.cargar_formacion @partido_id = @partido_id, @condicion = @condicion,
                     @esquema_tactico = '4-3-3', @jugadores = @jugadores;
                SET @lado += 1;
            END;

            -- d) Cambios. Caso obligatorio: lesión antes de los 20 minutos.
            IF @n = 1
                EXEC evento.registrar_sustitucion @partido_id = @partido_id, @condicion = 'local',
                     @dorsal_sale = 2, @dorsal_entra = 13, @minuto = 17, @periodo = 'PT', @motivo = 'lesion';

            SET @lado = 1;
            WHILE @lado <= 2
            BEGIN
                SET @condicion = IIF(@lado = 1, 'local', 'visitante');
                SELECT @formacion_id = formacion_id FROM plantel.formacion
                WHERE partido_id = @partido_id AND condicion = @condicion;

                SET @k = 1;
                WHILE @k <= 3
                BEGIN
                    SELECT @dorsal = NULL, @dorsal2 = NULL,
                           @minuto = IIF(@k = 1, 60, 75), @motivo = IIF(@k = 3, 'precaucion', 'tactico');

                    SELECT TOP (1) @dorsal = fj.dorsal
                    FROM plantel.formacion_jugador fj
                    WHERE fj.formacion_id = @formacion_id AND fj.titular = 1 AND fj.dorsal IN (7, 8, 11)
                      AND NOT EXISTS (SELECT 1 FROM evento.sustitucion s
                                      WHERE s.formacion_id = fj.formacion_id AND s.jugador_sale_id = fj.jugador_id)
                    ORDER BY fj.dorsal;

                    SELECT TOP (1) @dorsal2 = fj.dorsal
                    FROM plantel.formacion_jugador fj
                    WHERE fj.formacion_id = @formacion_id AND fj.titular = 0 AND fj.dorsal NOT IN (12, 23)
                      AND NOT EXISTS (SELECT 1 FROM evento.sustitucion s
                                      WHERE s.formacion_id = fj.formacion_id
                                        AND fj.jugador_id IN (s.jugador_entra_id, s.jugador_sale_id))
                    ORDER BY fj.dorsal DESC;

                    IF @dorsal IS NOT NULL AND @dorsal2 IS NOT NULL
                        EXEC evento.registrar_sustitucion @partido_id = @partido_id, @condicion = @condicion,
                             @dorsal_sale = @dorsal, @dorsal_entra = @dorsal2, @minuto = @minuto,
                             @periodo = 'ST', @motivo = @motivo;
                    SET @k += 1;
                END;
                SET @lado += 1;
            END;

            -- e) Tarjetas de los casos obligatorios (en orden de minuto).
            SET @t = (SELECT MIN(id) FROM #tarjeta_extra WHERE n = @n);
            WHILE @t IS NOT NULL
            BEGIN
                SELECT @condicion = condicion, @dorsal = dorsal, @minuto = minuto, @periodo = periodo,
                       @tipo = tipo, @tipo_expulsion = tipo_expulsion, @motivo = motivo
                FROM #tarjeta_extra WHERE id = @t;

                SET @persona_id = NULL;
                IF @dorsal IS NULL                         -- director técnico
                    SELECT @persona_id = ct.persona_id
                    FROM plantel.cuerpo_tecnico ct
                    JOIN torneo.partido p ON p.partido_id = @partido_id
                    WHERE ct.rol = 'director_tecnico'
                      AND ct.seleccion_id = IIF(@condicion = 'local', p.seleccion_local_id, p.seleccion_visitante_id);

                EXEC evento.registrar_tarjeta @partido_id = @partido_id, @minuto = @minuto, @periodo = @periodo,
                     @tipo = @tipo, @motivo = @motivo, @persona_id = @persona_id, @condicion = @condicion,
                     @dorsal = @dorsal, @tipo_expulsion = @tipo_expulsion;

                SET @t = (SELECT MIN(id) FROM #tarjeta_extra WHERE n = @n AND id > @t);
            END;

            -- e) Una amarilla a un defensor en cancha y sin tarjeta en el partido: al local en los
            --    partidos impares y al visitante en los pares.
            SELECT @condicion = IIF(@n % 2 = 1, 'local', 'visitante'),
                   @minuto    = IIF(@n % 2 = 1, 20 + @n % 20, 55 + @n % 30),
                   @periodo   = IIF(@n % 2 = 1, 'PT', 'ST'),
                   @motivo    = IIF(@n % 4 < 2, 'Falta', 'Conducta antideportiva'),
                   @objetivo  = CHOOSE(1 + (@n / 2) % 4, 2, 3, 4, 6),
                   @dorsal    = NULL;

            SELECT TOP (1) @dorsal = fj.dorsal
            FROM plantel.formacion f
            JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id
            JOIN plantel.jugador j            ON j.jugador_id = fj.jugador_id
            WHERE f.partido_id = @partido_id AND f.condicion = @condicion
              AND fj.titular = 1 AND fj.dorsal IN (2, 3, 4, 6)
              AND NOT EXISTS (SELECT 1 FROM evento.tarjeta t
                              WHERE t.partido_id = @partido_id AND t.persona_id = j.persona_id)
              AND NOT EXISTS (SELECT 1 FROM evento.sustitucion s
                              WHERE s.formacion_id = f.formacion_id AND s.jugador_sale_id = fj.jugador_id
                                AND s.minuto <= @minuto)
            ORDER BY IIF(fj.dorsal = @objetivo, 0, 1), fj.dorsal;

            IF @dorsal IS NOT NULL
                EXEC evento.registrar_tarjeta @partido_id = @partido_id, @minuto = @minuto, @periodo = @periodo,
                     @tipo = 'amarilla', @motivo = @motivo, @condicion = @condicion, @dorsal = @dorsal;

            -- f) Goles
            SET @lado = 1;
            WHILE @lado <= 2
            BEGIN
                SELECT @condicion = IIF(@lado = 1, 'local', 'visitante'),
                       @rival     = IIF(@lado = 1, 'visitante', 'local'),
                       @goles     = IIF(@lado = 1, @gl, @gv);
                SET @k = 1;
                WHILE @k <= @goles
                BEGIN
                    SET @minuto  = IIF(@lado = 1, CHOOSE(@k, 11, 33, 52, 67, 81), CHOOSE(@k, 24, 41, 57, 74, 88));
                    SET @periodo = IIF(@minuto <= 45, 'PT', 'ST');

                    IF @k = 1 AND @en_contra = IIF(@lado = 1, 'L', 'V')
                    BEGIN
                        -- Gol en contra: lo convierte un defensor rival y suma para este equipo.
                        SELECT TOP (1) @dorsal = fj.dorsal
                        FROM plantel.formacion f
                        JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id
                        WHERE f.partido_id = @partido_id AND f.condicion = @rival
                          AND fj.titular = 1 AND fj.dorsal IN (2, 3, 4, 6)
                        ORDER BY fj.dorsal;

                        EXEC evento.registrar_gol @partido_id = @partido_id, @condicion = @rival,
                             @dorsal_autor = @dorsal, @minuto = @minuto, @tipo_gol = 'en_contra', @periodo = @periodo;
                    END
                    ELSE
                    BEGIN
                        SELECT @dorsal   = CHOOSE(@k, 9, 10, 7, 9, 10),
                               @asist    = CHOOSE(@k, 10, 7, NULL, 8, NULL),
                               @tipo_gol = CHOOSE(@k, 'jugada', 'cabezazo', 'penal', 'jugada', 'tiro_libre');

                        EXEC evento.registrar_gol @partido_id = @partido_id, @condicion = @condicion,
                             @dorsal_autor = @dorsal, @minuto = @minuto, @tipo_gol = @tipo_gol,
                             @periodo = @periodo, @dorsal_asistencia = @asist;
                    END;
                    SET @k += 1;
                END;
                SET @lado += 1;
            END;

            -- g) Resultado (el marcador sale de los goles; los penales se informan)
            SET @asistencia = @capacidad * (88 + @n % 12) / 100;
            EXEC torneo.registrar_resultado @partido_id = @partido_id, @goles_local = @gl, @goles_visitante = @gv,
                 @penales_local = @pl, @penales_visitante = @pv, @asistencia_publico = @asistencia;

            -- h) Facturación de la pauta exhibida
            IF @fase <> 'semifinal'
               AND EXISTS (SELECT 1 FROM publicidad.espacio_publicitario
                           WHERE partido_id = @partido_id AND pieza_id IS NOT NULL)
                EXEC publicidad.facturar_espacios_partido @partido_id = @partido_id;
        END;

        SET @n += 1;
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'La carga del torneo falló en el partido ' + CAST(@n AS VARCHAR(3)) + ' del fixture: no se cargó ningún partido.';
    THROW;
END CATCH;
GO

-- ============================================================
-- Lote 11: informes arbitrales post-partido (uno con sanción)
-- ============================================================
PRINT '--- Lote 11: informes arbitrales';

DECLARE @inf TABLE (n INT IDENTITY(1, 1), partido_n INT, rol VARCHAR(11), contenido VARCHAR(500), sancion VARCHAR(150));
INSERT INTO @inf (partido_n, rol, contenido, sancion) VALUES
    (11, 'principal', 'Doble amonestación y expulsión del dorsal 5 de Alemania (minuto 71). Se consultó al VAR sin cambios en la decisión.', NULL),
    (15, 'principal', 'Expulsión por roja directa del dorsal 5 de Colombia por juego brusco grave (minuto 63). Sin otros incidentes.', NULL),
    (18, 'var',       'El VAR no recomendó revisar una jugada de posible penal en el minuto 77. La Comisión de Árbitros analizó la acción.',
                      'Apercibimiento de la Comisión de Árbitros'),
    (29, 'principal', 'Expulsión por agresión del dorsal 5 de Brasil (minuto 85). Se elevó el informe a la Comisión Disciplinaria.', NULL);

DECLARE @i INT = 1, @designacion_id INT, @fecha DATETIMEOFFSET, @contenido VARCHAR(500), @sancion VARCHAR(150);

WHILE @i <= (SELECT MAX(n) FROM @inf)
BEGIN
    SELECT @designacion_id = d.designacion_id, @fecha = DATEADD(HOUR, 3, p.fecha_hora_utc),
           @contenido = i.contenido, @sancion = i.sancion
    FROM @inf i
    JOIN #fixture f                        ON f.n = i.partido_n
    JOIN torneo.partido p                  ON p.partido_id = f.partido_id
    JOIN arbitraje.designacion_arbitral d  ON d.partido_id = p.partido_id AND d.rol = i.rol
    WHERE i.n = @i;

    EXEC arbitraje.informe_arbitral_insertar @designacion_id = @designacion_id, @fecha = @fecha,
         @contenido = @contenido, @sancion = @sancion;
    SET @i += 1;
END;
GO

-- ============================================================
-- Lote 12: resumen de lo cargado contra los mínimos de la sección IV
-- ============================================================
PRINT '--- Lote 12: resumen';

SELECT x.requisito AS Requisito, x.minimo AS Minimo, x.cargado AS Cargado,
       IIF(x.cargado >= x.minimo, 'OK', 'FALTA') AS Estado
FROM (VALUES
    ('Sedes',                                   8, (SELECT COUNT(*) FROM torneo.sede)),
    ('Husos horarios distintos entre sedes',    3, (SELECT COUNT(DISTINCT huso_horario) FROM torneo.sede)),
    ('Selecciones',                            16, (SELECT COUNT(*) FROM torneo.seleccion)),
    ('Mínimo de convocados vigentes por selección', 23,
        (SELECT MIN(c) FROM (SELECT COUNT(cv.convocatoria_id) AS c FROM torneo.seleccion s
                             LEFT JOIN plantel.convocatoria cv ON cv.seleccion_id = s.seleccion_id AND cv.fecha_baja IS NULL
                             GROUP BY s.seleccion_id) t)),
    ('Partidos',                               24, (SELECT COUNT(*) FROM torneo.partido)),
    ('Partidos jugados con titulares y banco de ambos equipos', 24,
        (SELECT COUNT(*) FROM torneo.partido p
         WHERE (SELECT COUNT(DISTINCT f.formacion_id) FROM plantel.formacion f
                JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id AND fj.titular = 0
                WHERE f.partido_id = p.partido_id) = 2)),
    ('Árbitros',                               15, (SELECT COUNT(*) FROM arbitraje.arbitro)),
    ('Partidos con terna completa (5 roles)',  24,
        (SELECT COUNT(*) FROM (SELECT partido_id FROM arbitraje.designacion_arbitral
                               GROUP BY partido_id HAVING COUNT(*) = 5) t)),
    ('Anunciantes',                             6, (SELECT COUNT(*) FROM publicidad.anunciante)),
    ('Expulsiones por doble amarilla',          1, (SELECT COUNT(*) FROM evento.tarjeta WHERE tipo_expulsion = 'doble_amarilla')),
    ('Expulsiones por roja directa',            1, (SELECT COUNT(*) FROM evento.tarjeta WHERE tipo_expulsion = 'roja_directa')),
    ('Suspensiones por acumulación',            1, (SELECT COUNT(*) FROM evento.suspension WHERE criterio_id IS NOT NULL)),
    ('Cambios por lesión antes del minuto 20',  1, (SELECT COUNT(*) FROM evento.sustitucion WHERE motivo = 'lesion' AND minuto < 20))
) AS x (requisito, minimo, cargado);

DROP TABLE IF EXISTS #sede, #seleccion, #pool, #nombre, #fixture, #tarjeta_extra;
GO

SET NOEXEC OFF;
GO
