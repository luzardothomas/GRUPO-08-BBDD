USE mundial_2026;
GO
-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 7: Reportes
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Genera los correspondientes Stored Procedures para los 7 reportes 
--   solicitados. Los reportes 1 y 2 retornan formato XML.
-- ============================================================


-- ========================================================================================
-- ENTREGA 7: REPORTES
-- ========================================================================================

-- ========================================================================================
-- REPORTE 1 (XML): Goleadores por selección, fase y torneo.
-- Muestra la estructura anidada Torneo -> Fase -> Selección -> Jugadores -> Goles
-- ========================================================================================
CREATE OR ALTER PROCEDURE evento.ReporteGoleadoresXML
AS
BEGIN
    SET NOCOUNT ON;

    -- Usamos FOR XML PATH para generar una estructura jerárquica prolija.
    -- Omitimos los goles en contra y tanda de penales del ranking de goleadores según regla del negocio.
    SELECT 
        p.fase AS "@nombre_fase",
        (
            SELECT 
                pa.nombre AS "@pais_seleccion",
                (
                    SELECT 
                        j.nombre + ' ' + j.apellido AS "jugador/@nombre",
                        COUNT(g.gol_id) AS "jugador/@goles_anotados"
                    FROM evento.gol g
                    JOIN plantel.formacion_jugador fj ON g.formacion_id = fj.formacion_id AND g.jugador_id = fj.jugador_id
                    JOIN plantel.jugador j ON fj.jugador_id = j.jugador_id
                    JOIN plantel.vw_formacion vf ON g.formacion_id = vf.formacion_id
                    WHERE vf.seleccion_id = s.seleccion_id 
                      AND vf.fase = p.fase
                      AND g.tipo_gol <> 'en_contra' 
                      AND g.periodo <> 'penales'
                    GROUP BY j.nombre, j.apellido
                    ORDER BY COUNT(g.gol_id) DESC
                    FOR XML PATH(''), TYPE
                ) AS "jugadores"
            FROM torneo.seleccion s
            JOIN torneo.pais pa ON s.pais_id = pa.pais_id
            WHERE EXISTS ( -- Solo muestra selecciones que hicieron goles en esta fase
                SELECT 1 FROM evento.gol g2 
                JOIN plantel.vw_formacion vf2 ON g2.formacion_id = vf2.formacion_id 
                WHERE vf2.seleccion_id = s.seleccion_id AND vf2.fase = p.fase AND g2.tipo_gol <> 'en_contra' AND g2.periodo <> 'penales'
            )
            FOR XML PATH('seleccion'), TYPE
        )
    FROM (SELECT DISTINCT fase FROM torneo.partido) p
    FOR XML PATH('fase'), ROOT('torneo_goleadores');
END;
GO


-- ========================================================================================
-- REPORTE 2 (XML): Selecciones y plantillas (vector anidado de convocados).
-- ========================================================================================
CREATE OR ALTER PROCEDURE plantel.ReportePlantillasXML
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        pa.nombre AS "@pais",
        c.nombre AS "@confederacion",
        (
            SELECT 
                j.nombre + ' ' + j.apellido AS "@nombre",
                j.posicion_habitual AS "@posicion",
                ISNULL(j.club_origen, 'Agente Libre') AS "@club",
                conv.dorsal AS "@dorsal"
            FROM plantel.convocatoria conv
            JOIN plantel.jugador j ON conv.jugador_id = j.jugador_id
            WHERE conv.seleccion_id = s.seleccion_id
              AND conv.fecha_baja IS NULL -- Solo el plantel vigente
            ORDER BY conv.dorsal ASC
            FOR XML PATH('jugador'), TYPE
        ) AS "plantilla"
    FROM torneo.seleccion s
    JOIN torneo.pais pa ON s.pais_id = pa.pais_id
    JOIN torneo.confederacion c ON s.confederacion_id = c.confederacion_id
    ORDER BY pa.nombre
    FOR XML PATH('seleccion'), ROOT('selecciones_mundial');
END;
GO


-- ========================================================================================
-- REPORTE 3: Tarjetas por selección y jugador, con detalle de suspensiones activas.
-- ========================================================================================
CREATE OR ALTER PROCEDURE evento.ReporteTarjetasYSuspensiones
AS
BEGIN
    SET NOCOUNT ON;

    -- Usamos vw_persona_partido para poder rastrear tanto a jugadores como cuerpo técnico
    SELECT 
        pa.nombre AS Seleccion,
        ISNULL(j.nombre + ' ' + j.apellido, ct.nombre + ' ' + ct.apellido) AS Persona,
        per.tipo_persona AS Rol,
        SUM(CASE WHEN t.tipo = 'amarilla' THEN 1 ELSE 0 END) AS Cantidad_Amarillas,
        SUM(CASE WHEN t.tipo = 'roja' THEN 1 ELSE 0 END) AS Cantidad_Rojas,
        -- Verificamos si la persona tiene una suspensión activa apuntando al futuro
        CASE WHEN EXISTS (
            SELECT 1 FROM evento.suspension sus 
            JOIN torneo.partido part ON sus.partido_afectado_id = part.partido_id
            WHERE sus.tarjeta_id = t.tarjeta_id AND part.estado = 'programado'
        ) THEN 'SÍ' ELSE 'NO' END AS Suspension_Activa
    FROM evento.tarjeta t
    JOIN plantel.vw_persona_partido vpp ON t.persona_id = vpp.persona_id AND t.partido_id = vpp.partido_id
    JOIN torneo.seleccion s ON vpp.seleccion_id = s.seleccion_id
    JOIN torneo.pais pa ON s.pais_id = pa.pais_id
    JOIN plantel.persona per ON t.persona_id = per.persona_id
    LEFT JOIN plantel.jugador j ON per.persona_id = j.persona_id
    LEFT JOIN plantel.cuerpo_tecnico ct ON per.persona_id = ct.persona_id
    GROUP BY 
        pa.nombre, 
        per.tipo_persona, 
        ISNULL(j.nombre + ' ' + j.apellido, ct.nombre + ' ' + ct.apellido),
        t.tarjeta_id
    ORDER BY pa.nombre, Persona;
END;
GO