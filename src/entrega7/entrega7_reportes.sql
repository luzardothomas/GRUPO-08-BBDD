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


-- ========================================================================================
-- REPORTE 4: Designaciones arbitrales e historial disciplinario del árbitro.
-- ========================================================================================
CREATE OR ALTER PROCEDURE arbitraje.ReporteDesignacionesArbitrales
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        a.nombre + ' ' + a.apellido AS Arbitro,
        pa.nombre AS Nacionalidad,
        da.rol AS Rol_Asignado,
        COUNT(DISTINCT da.partido_id) AS Partidos_Dirigidos,
        ISNULL(SUM(CASE WHEN t.tipo = 'amarilla' THEN 1 ELSE 0 END), 0) AS Amarillas_Mostradas,
        ISNULL(SUM(CASE WHEN t.tipo = 'roja' THEN 1 ELSE 0 END), 0) AS Rojas_Mostradas
    FROM arbitraje.arbitro a
    JOIN torneo.pais pa ON a.pais_id = pa.pais_id
    JOIN arbitraje.designacion_arbitral da ON a.arbitro_id = da.arbitro_id
    -- Left join a las tarjetas del partido donde este árbitro fue el 'principal'
    LEFT JOIN evento.tarjeta t ON da.partido_id = t.partido_id AND da.rol = 'principal'
    GROUP BY a.nombre, a.apellido, pa.nombre, da.rol
    ORDER BY Partidos_Dirigidos DESC, Arbitro ASC;
END;
GO


-- ========================================================================================
-- REPORTE 5: Ocupación publicitaria e ingresos generados.
-- ========================================================================================
CREATE OR ALTER PROCEDURE publicidad.ReporteOcupacionPublicitaria
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        se.nombre AS Sede_Estadio,
        p.fase AS Fase_Partido,
        p.fecha_hora_local AS Fecha_Partido,
        ep.numero_espacio AS Numero_Cartel,
        ISNULL(an.nombre, 'ESPACIO VACÍO') AS Anunciante,
        ISNULL(cp.nombre, '-') AS Campania,
        CASE 
            WHEN ep.facturado = 1 THEN 'Facturado' 
            WHEN ep.pieza_id IS NOT NULL THEN 'Pendiente de Facturación' 
            ELSE 'No Asignado' 
        END AS Estado_Cobro,
        ISNULL(ep.monto_facturado, 0) AS Ingreso_Generado
    FROM torneo.partido p
    JOIN torneo.sede se ON p.sede_id = se.sede_id
    -- Usamos un JOIN estricto a los espacios (ya que son exactamente 4 por partido)
    JOIN publicidad.espacio_publicitario ep ON p.partido_id = ep.partido_id
    LEFT JOIN publicidad.pieza_publicitaria pz ON ep.pieza_id = pz.pieza_id
    LEFT JOIN publicidad.campania cp ON pz.campania_id = cp.campania_id
    LEFT JOIN publicidad.anunciante an ON cp.anunciante_id = an.anunciante_id
    ORDER BY p.fecha_hora_local, se.nombre, ep.numero_espacio;
END;
GO


-- ========================================================================================
-- REPORTE 6 (PIVOT): Matriz de Prime Time. 
-- ========================================================================================
CREATE OR ALTER PROCEDURE torneo.ReporteMatrizPrimeTime
AS
BEGIN
    SET NOCOUNT ON;

    -- Nota: Asumimos que los horarios están guardados en torneo.parametro (ej: 19 y 22 hs).
    -- En la práctica, calculamos dinámicamente usando el DATETIMEOFFSET del partido y el huso del país.
    
    -- Usamos CTE para preparar los datos antes de pivotear.
    WITH PrimeTimeData AS (
        SELECT 
            p.partido_id,
            CONCAT(pa_local.nombre, ' vs ', pa_visitante.nombre) AS Encuentro,
            mercado.codigo_iso AS Mercado_ISO,
            -- Cálculo ultra-simplificado para el Pivot:
            -- Toma la hora UTC del partido y le aplica el offset numérico del huso horario del mercado.
            CASE 
                WHEN DATEPART(HOUR, DATEADD(HOUR, CAST(REPLACE(mercado.huso_horario, 'UTC', '') AS INT), p.fecha_hora_utc)) BETWEEN 19 AND 23 
                THEN 'SI' 
                ELSE 'NO' 
            END AS Es_PrimeTime
        FROM torneo.partido p
        JOIN torneo.seleccion sl ON p.seleccion_local_id = sl.seleccion_id
        JOIN torneo.pais pa_local ON sl.pais_id = pa_local.pais_id
        JOIN torneo.seleccion sv ON p.seleccion_visitante_id = sv.seleccion_id
        JOIN torneo.pais pa_visitante ON sv.pais_id = pa_visitante.pais_id
        -- Cross join con los países principales para evaluar su prime time
        CROSS JOIN torneo.pais mercado 
    )
    SELECT 
        Encuentro, 
        [ARG] AS Argentina, 
        [BRA] AS Brasil, 
        [ESP] AS Espana, 
        [MEX] AS Mexico,
        [FRA] AS Francia
    FROM PrimeTimeData
    PIVOT (
        MAX(Es_PrimeTime)
        FOR Mercado_ISO IN ([ARG], [BRA], [ESP], [MEX], [FRA])
    ) AS PivotTable
    ORDER BY Encuentro;
END;
GO


-- ========================================================================================
-- REPORTE 7: Resultados de los encuentros.
-- ========================================================================================
CREATE OR ALTER PROCEDURE torneo.ReporteResultados
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        p.fase AS Fase,
        p.fecha_hora_utc AS Fecha_UTC,
        se.nombre + ' (' + se.ciudad + ')' AS Sede,
        pa_local.nombre AS Equipo_Local,
        CASE 
            WHEN p.estado = 'programado' THEN ' vs '
            WHEN p.estado = 'suspendido' THEN ' [SUSP] '
            ELSE CAST(p.goles_local AS VARCHAR) + ' - ' + CAST(p.goles_visitante AS VARCHAR)
        END AS Resultado,
        pa_visitante.nombre AS Equipo_Visitante,
        CASE 
            WHEN p.penales_local IS NOT NULL THEN 
                '(' + CAST(p.penales_local AS VARCHAR) + '-' + CAST(p.penales_visitante AS VARCHAR) + ' pen.)' 
            ELSE '' 
        END AS Penales
    FROM torneo.partido p
    JOIN torneo.seleccion sl ON p.seleccion_local_id = sl.seleccion_id
    JOIN torneo.pais pa_local ON sl.pais_id = pa_local.pais_id
    JOIN torneo.seleccion sv ON p.seleccion_visitante_id = sv.seleccion_id
    JOIN torneo.pais pa_visitante ON sv.pais_id = pa_visitante.pais_id
    JOIN torneo.sede se ON p.sede_id = se.sede_id
    ORDER BY p.fecha_hora_utc ASC;
END;
GO