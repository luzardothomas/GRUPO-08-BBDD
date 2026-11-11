-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 9: BI, visualización y aplicación - Coordenadas de las sedes
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Script de MODIFICACIÓN sobre torneo.sede (Entrega 5), para el mapa de sedes del dashboard de Power BI:
--     1. Agrega las columnas latitud y longitud (grados decimales, WGS84), opcionales.
--     2. Carga las coordenadas de los 16 estadios del Mundial 2026.
--   No cambia ningún SP: las columnas aceptan NULL, así que sede_insertar, sede_modificar y
--   torneo.importar_sedes siguen funcionando igual (una sede nueva queda sin coordenadas hasta que se cargue).
--   Se ejecuta después de las Entregas 5 y 7 (y 6 si se importaron las sedes). Es reejecutable.
--
--   Las coordenadas son las del estadio, redondeadas a 4 decimales (unos 10 m), tomadas de su ubicación
--   pública. Las sedes se identifican por el nombre que traen la carga de la Entrega 7 y sedes.json.
-- ============================================================

USE mundial_2026;
GO

-- ============================================================
-- 1. COLUMNAS
-- ============================================================

IF COL_LENGTH('torneo.sede', 'latitud') IS NULL
    ALTER TABLE torneo.sede ADD latitud DECIMAL(9, 6) NULL,
                                longitud DECIMAL(9, 6) NULL;
GO

IF OBJECT_ID('torneo.chk_sede_coordenadas', 'C') IS NULL
    ALTER TABLE torneo.sede ADD CONSTRAINT chk_sede_coordenadas CHECK (
        (latitud IS NULL AND longitud IS NULL)
        OR (latitud BETWEEN -90 AND 90 AND longitud BETWEEN -180 AND 180));
GO

-- ============================================================
-- 2. COORDENADAS DE LOS 16 ESTADIOS
-- ============================================================

UPDATE s
SET s.latitud = c.latitud, s.longitud = c.longitud
FROM torneo.sede s
JOIN (VALUES
    (N'Estadio Azteca',           19.3029,  -99.1505),
    (N'MetLife Stadium',          40.8135,  -74.0745),
    (N'AT&T Stadium',             32.7473,  -97.0945),
    (N'SoFi Stadium',             33.9535, -118.3392),
    (N'Arrowhead Stadium',        39.0489,  -94.4839),
    (N'Levi''s Stadium',          37.4033, -121.9694),
    (N'NRG Stadium',              29.6847,  -95.4107),
    (N'Lincoln Financial Field',  39.9008,  -75.1675),
    (N'Mercedes-Benz Stadium',    33.7554,  -84.4010),
    (N'Lumen Field',              47.5952, -122.3316),
    (N'Hard Rock Stadium',        25.9580,  -80.2389),
    (N'Gillette Stadium',         42.0909,  -71.2643),
    (N'BC Place',                 49.2768, -123.1119),
    (N'Estadio BBVA',             25.6692, -100.2440),
    (N'Estadio Akron',            20.6818, -103.4626),
    (N'BMO Field',                43.6332,  -79.4186)
) AS c (nombre, latitud, longitud) ON s.nombre COLLATE DATABASE_DEFAULT = c.nombre COLLATE DATABASE_DEFAULT;

-- Sedes con y sin coordenadas.
SELECT s.sede_id, s.nombre, s.ciudad, s.latitud, s.longitud,
       IIF(s.latitud IS NULL, 'sin coordenadas', 'ok') AS estado
FROM torneo.sede s
ORDER BY s.sede_id;
GO
