-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 9: BI, visualización y aplicación - Vistas y usuario para Power BI
-- FECHA: 10/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Deja la base lista para que Power BI se conecte directo a SQL Server, sin copiar los datos a mano:
--     1. Esquema bi con cuatro vistas de sólo lectura, una por tema del dashboard. Reproducen los reportes de la
--        Entrega 7 en forma de tabla (Power BI no lee los reportes XML ni las filas de subtotal):
--          bi.vw_goles                     una fila por gol          (reporte de goleadores)
--          bi.vw_ocupacion_publicitaria    una fila por partido      (reporte de ocupación publicitaria)
--          bi.vw_partidos                  una fila por partido      (reporte de resultados)
--          bi.vw_sedes                     una fila por sede         (mapa; necesita 1_entrega9_sede_coordenadas.sql)
--     2. Rol bi_lector y usuario usr_bi, para conectar Power BI con el mínimo privilegio (Entrega 8):
--          - SELECT sólo sobre el esquema bi;
--          - DENY de lectura y escritura sobre los esquemas de la aplicación y de escritura sobre bi;
--          - las vistas leen las tablas por encadenamiento de propiedad (dbo es dueño de ambas), igual que
--            los SP de la Entrega 8, así que el usuario no necesita permisos sobre las tablas;
--          - ninguna vista expone columnas cifradas (motivos, fechas de nacimiento, contactos, informes).
--     El rol no se llama rol_... a propósito: seguridad.crear_roles (Entrega 8) borra los rol_... que no
--     figuran en su cuadro, y este rol es de lectura (SELECT) y no de ejecución (EXECUTE).
--   Se ejecuta después de las Entregas 5, 7 y 8 y de 1_entrega9_sede_coordenadas.sql. Es reejecutable.
--
--   La contraseña es de prueba y cumple la directiva de complejidad. Power BI la guarda en su archivo de
--   credenciales: cambiarla antes de publicar el dashboard.
-- ============================================================

USE mundial_2026;
GO

-- ============================================================
-- 1. ESQUEMA
-- ============================================================

IF SCHEMA_ID('bi') IS NULL
    EXEC ('CREATE SCHEMA bi AUTHORIZATION dbo');
GO

-- ============================================================
-- 2. VISTAS
-- ============================================================

-- Una fila por gol. cuenta_para_goleador aplica el criterio del reporte de goleadores de la Entrega 7:
-- no cuentan los goles en contra ni los de la tanda de penales.
CREATE OR ALTER VIEW bi.vw_goles
AS
SELECT g.gol_id,
       vf.partido_id,
       vf.fase,
       pa.nombre                               AS seleccion,
       pa.codigo_iso,
       j.nombre + ' ' + j.apellido             AS jugador,
       g.minuto,
       g.periodo,
       g.tipo_gol,
       IIF(g.tipo_gol <> 'en_contra' AND g.periodo <> 'penales', 1, 0) AS cuenta_para_goleador
FROM evento.gol g
JOIN plantel.vw_formacion vf ON vf.formacion_id = g.formacion_id
JOIN torneo.seleccion s      ON s.seleccion_id = vf.seleccion_id
JOIN torneo.pais pa          ON pa.pais_id = s.pais_id
JOIN plantel.jugador j       ON j.jugador_id = g.jugador_id;
GO

-- Una fila por partido, con los espacios publicitarios y los ingresos. Mismo cálculo que
-- publicidad.reporte_ocupacion (Entrega 7): 4 espacios por partido; ingreso facturado = lo ya facturado;
-- ingreso estimado = lo facturado más la tarifa de las piezas asignadas todavía sin facturar.
CREATE OR ALTER VIEW bi.vw_ocupacion_publicitaria
AS
SELECT p.partido_id,
       p.sede_id,
       se.nombre                                                       AS sede,
       p.fase,
       p.estado,
       p.fecha_hora_local,
       pl.nombre + ' vs ' + pv.nombre                                  AS encuentro,
       COUNT(e.pieza_id)                                               AS espacios_ocupados,
       4                                                               AS espacios_disponibles,
       CAST(100.0 * COUNT(e.pieza_id) / 4 AS DECIMAL(5, 1))            AS ocupacion_pct,
       ISNULL(SUM(IIF(e.facturado = 1, e.monto_facturado, 0)), 0)      AS ingreso_facturado_usd,
       ISNULL(SUM(CASE WHEN e.facturado = 1 THEN e.monto_facturado
                       WHEN e.pieza_id IS NOT NULL THEN pz.costo_tarifa
                       ELSE 0 END), 0)                                 AS ingreso_estimado_usd
FROM torneo.partido p
JOIN torneo.sede se                         ON se.sede_id = p.sede_id
JOIN torneo.seleccion sl                    ON sl.seleccion_id = p.seleccion_local_id
JOIN torneo.pais pl                         ON pl.pais_id = sl.pais_id
JOIN torneo.seleccion sv                    ON sv.seleccion_id = p.seleccion_visitante_id
JOIN torneo.pais pv                         ON pv.pais_id = sv.pais_id
LEFT JOIN publicidad.espacio_publicitario e ON e.partido_id = p.partido_id
LEFT JOIN publicidad.pieza_publicitaria pz  ON pz.pieza_id = e.pieza_id
GROUP BY p.partido_id, p.sede_id, se.nombre, p.fase, p.estado, p.fecha_hora_local, pl.nombre, pv.nombre;
GO

-- Una fila por partido, con el resultado y la asistencia (reporte de resultados de la Entrega 7).
CREATE OR ALTER VIEW bi.vw_partidos
AS
SELECT p.partido_id,
       p.sede_id,
       p.fase,
       IIF(p.fase = 'grupos', CAST(sl.grupo AS VARCHAR(40)), NULL)     AS grupo,
       p.fecha_hora_local,
       p.fecha_hora_utc,
       se.nombre                                                       AS sede,
       se.ciudad,
       pl.nombre                                                       AS local,
       pv.nombre                                                       AS visitante,
       p.estado,
       p.goles_local,
       p.goles_visitante,
       p.goles_local + p.goles_visitante                               AS goles_totales,
       p.penales_local,
       p.penales_visitante,
       p.asistencia_publico,
       se.capacidad,
       CAST(100.0 * p.asistencia_publico / NULLIF(se.capacidad, 0) AS DECIMAL(5, 1)) AS ocupacion_estadio_pct
FROM torneo.partido p
JOIN torneo.sede se      ON se.sede_id = p.sede_id
JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
JOIN torneo.pais pl      ON pl.pais_id = sl.pais_id
JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
JOIN torneo.pais pv      ON pv.pais_id = sv.pais_id;
GO

-- Una fila por sede, con sus coordenadas para el mapa y los totales de partidos y público.
CREATE OR ALTER VIEW bi.vw_sedes
AS
SELECT se.sede_id,
       se.nombre                                AS sede,
       se.ciudad,
       pa.nombre                                AS pais,
       se.capacidad,
       se.latitud,
       se.longitud,
       COUNT(p.partido_id)                      AS partidos,
       ISNULL(SUM(p.asistencia_publico), 0)     AS asistencia_total
FROM torneo.sede se
JOIN torneo.pais pa        ON pa.pais_id = se.pais_id
LEFT JOIN torneo.partido p ON p.sede_id = se.sede_id
GROUP BY se.sede_id, se.nombre, se.ciudad, pa.nombre, se.capacidad, se.latitud, se.longitud;
GO

-- ============================================================
-- 3. ROL Y USUARIO PARA POWER BI
-- ============================================================

IF DATABASE_PRINCIPAL_ID('bi_lector') IS NULL
    CREATE ROLE bi_lector AUTHORIZATION dbo;
GO

-- Sólo lectura del esquema bi...
GRANT SELECT ON SCHEMA::bi TO bi_lector;
DENY INSERT, UPDATE, DELETE ON SCHEMA::bi TO bi_lector;
-- ...y ningún acceso directo a las tablas ni a los SP de la aplicación (mismos esquemas que la Entrega 8).
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::torneo      TO bi_lector;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::plantel     TO bi_lector;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::evento      TO bi_lector;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::arbitraje   TO bi_lector;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::publicidad  TO bi_lector;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::importacion TO bi_lector;
DENY SELECT, INSERT, UPDATE, DELETE ON SCHEMA::seguridad   TO bi_lector;
GO

-- Inicio de sesión y usuario de Power BI (sin MUST_CHANGE: lo usa el dashboard, no una persona).
IF SUSER_ID('usr_bi') IS NULL
    CREATE LOGIN usr_bi WITH PASSWORD = N'Mundial2026_BI!', CHECK_POLICY = ON, CHECK_EXPIRATION = OFF,
                             DEFAULT_DATABASE = mundial_2026;
GO

IF DATABASE_PRINCIPAL_ID('usr_bi') IS NULL
    CREATE USER usr_bi FOR LOGIN usr_bi;
GO

IF IS_ROLEMEMBER('bi_lector', 'usr_bi') <> 1
    ALTER ROLE bi_lector ADD MEMBER usr_bi;
GO

-- Resumen: qué hay en cada vista y a quién se la dimos.
SELECT 'bi.vw_goles' AS vista, COUNT(*) AS filas FROM bi.vw_goles
UNION ALL SELECT 'bi.vw_ocupacion_publicitaria', COUNT(*) FROM bi.vw_ocupacion_publicitaria
UNION ALL SELECT 'bi.vw_partidos', COUNT(*) FROM bi.vw_partidos
UNION ALL SELECT 'bi.vw_sedes', COUNT(*) FROM bi.vw_sedes;

SELECT u.name AS usuario, r.name AS rol
FROM sys.database_role_members m
JOIN sys.database_principals r ON r.principal_id = m.role_principal_id
JOIN sys.database_principals u ON u.principal_id = m.member_principal_id
WHERE r.name = 'bi_lector';
GO
