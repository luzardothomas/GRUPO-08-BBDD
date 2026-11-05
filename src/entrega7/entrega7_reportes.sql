-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 7: Reportes
-- FECHA: 05/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Stored Procedures de los 7 reportes que pide la Entrega 7. Se ejecuta después de los
--   scripts de la Entrega 5 (y opcionalmente de la carga entrega7_carga_datos.sql):
--     1. evento.reporte_goleadores           (XML)    goleadores del torneo, por selección y por fase.
--     2. evento.reporte_tarjetas                      tarjetas por selección y persona, con suspensiones activas.
--     3. arbitraje.reporte_designaciones     (XML)    partidos de cada árbitro, con las tarjetas que señaló.
--     4. publicidad.reporte_ocupacion                 ocupación de los 4 espacios por sede y partido, e ingresos.
--     5. publicidad.reporte_matriz_prime_time (PIVOT) partido x mercado: ¿el horario cae en prime time?
--     6. plantel.reporte_plantillas          (XML)    selecciones con el vector anidado de convocados.
--     7. torneo.reporte_resultados                    resultados de los encuentros y tabla de posiciones.
--
--   Norma: nombres en snake_case con prefijo reporte_, en el esquema del módulo que consultan.
--   Todos los parámetros son filtros opcionales (NULL = sin filtrar); los inválidos se informan
--   juntos en un único THROW 50002, igual que los SP de la Entrega 5.
--   Los reportes sólo leen: no modifican datos.
--   Los reportes XML muestran el documento como resultado y además lo devuelven en el parámetro
--   OUTPUT @resultado, para poder procesarlo desde otro SP, los tests o la aplicación
--   (INSERT ... EXEC no admite un SP cuyo SELECT final tenga FOR XML).
--
--   SQL dinámico: sólo en publicidad.reporte_matriz_prime_time. PIVOT necesita la lista de
--   columnas escrita en la consulta, y los mercados (columnas) salen de los datos: escribirlos
--   fijos dejaría afuera los mercados que se agreguen después. La lista se arma con QUOTENAME
--   y los valores viajan como parámetros de sp_executesql (sin concatenar datos del usuario).
-- ============================================================

USE mundial_2026;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;     -- requerido por los métodos XML (FOR XML ... TYPE)
GO

-- Versión anterior de los reportes (nombres en PascalCase, fuera de la norma): se eliminan.
DROP PROCEDURE IF EXISTS evento.ReporteGoleadoresXML;
DROP PROCEDURE IF EXISTS plantel.ReportePlantillasXML;
DROP PROCEDURE IF EXISTS evento.ReporteTarjetasYSuspensiones;
DROP PROCEDURE IF EXISTS arbitraje.ReporteDesignacionesArbitrales;
DROP PROCEDURE IF EXISTS publicidad.ReporteOcupacionPublicitaria;
DROP PROCEDURE IF EXISTS torneo.ReporteMatrizPrimeTime;
DROP PROCEDURE IF EXISTS torneo.ReporteResultados;
GO

-- ========================================================================================
-- REPORTE 1 (XML): Goleadores por selección, fase y torneo.
--   <goleadores>
--     <torneo>          ranking general (puesto, jugador, selección, goles, asistencias)
--     <por_seleccion>   cada selección con sus goleadores
--     <por_fase>        cada fase (en orden de torneo) con sus goleadores
-- Regla: no cuentan para el goleador los goles en contra ni los de la tanda de penales.
-- Desempate del ranking: más asistencias, luego apellido.
-- ========================================================================================
CREATE OR ALTER PROCEDURE evento.reporte_goleadores
    @seleccion_id INT         = NULL,
    @fase         VARCHAR(13) = NULL,
    @resultado    XML         = NULL OUTPUT      -- el mismo XML que se muestra, para reutilizarlo
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @seleccion_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id ' + CAST(@seleccion_id AS VARCHAR(12)) + '.' + @nl;
    IF @fase IS NOT NULL AND @fase NOT IN
       ('grupos', 'dieciseisavos', 'octavos', 'cuartos', 'semifinal', 'tercer_puesto', 'final')
        SET @errores += '- La fase debe ser grupos, dieciseisavos, octavos, cuartos, semifinal, tercer_puesto o final.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.reporte_goleadores - consulta rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    -- Goles válidos para el goleador, agrupados por jugador, selección y fase.
    DECLARE @goles TABLE (
        jugador_id   INT NOT NULL,
        seleccion_id INT NOT NULL,
        fase         VARCHAR(13) NOT NULL,
        orden_fase   INT NOT NULL,
        goles        INT NOT NULL,
        PRIMARY KEY (jugador_id, seleccion_id, fase)
    );
    -- Asistencias (desempate del ranking general).
    DECLARE @asistencias TABLE (jugador_id INT PRIMARY KEY, asistencias INT NOT NULL);

    INSERT INTO @goles (jugador_id, seleccion_id, fase, orden_fase, goles)
    SELECT g.jugador_id, vf.seleccion_id, vf.fase, fo.orden, COUNT(*)
    FROM evento.gol g
    JOIN plantel.vw_formacion vf ON vf.formacion_id = g.formacion_id
    JOIN (VALUES ('grupos', 1), ('dieciseisavos', 2), ('octavos', 3), ('cuartos', 4),
                 ('semifinal', 5), ('tercer_puesto', 6), ('final', 7)) AS fo (fase, orden)
      ON fo.fase = vf.fase
    WHERE g.tipo_gol <> 'en_contra'
      AND g.periodo <> 'penales'
      AND (@seleccion_id IS NULL OR vf.seleccion_id = @seleccion_id)
      AND (@fase IS NULL OR vf.fase = @fase)
    GROUP BY g.jugador_id, vf.seleccion_id, vf.fase, fo.orden;

    INSERT INTO @asistencias (jugador_id, asistencias)
    SELECT g.asistencia_jugador_id, COUNT(*)
    FROM evento.gol g
    JOIN plantel.vw_formacion vf ON vf.formacion_id = g.formacion_id
    WHERE g.asistencia_jugador_id IS NOT NULL
      AND (@seleccion_id IS NULL OR vf.seleccion_id = @seleccion_id)
      AND (@fase IS NULL OR vf.fase = @fase)
    GROUP BY g.asistencia_jugador_id;

    SET @resultado = (
    SELECT
        -- Ranking general del torneo.
        (SELECT RANK() OVER (ORDER BY SUM(g.goles) DESC, MAX(ISNULL(a.asistencias, 0)) DESC) AS "@puesto",
                j.nombre + ' ' + j.apellido                                                  AS "@jugador",
                pa.nombre                                                                    AS "@seleccion",
                SUM(g.goles)                                                                 AS "@goles",
                MAX(ISNULL(a.asistencias, 0))                                                AS "@asistencias"
         FROM @goles g
         JOIN plantel.jugador j    ON j.jugador_id = g.jugador_id
         JOIN torneo.seleccion s   ON s.seleccion_id = g.seleccion_id
         JOIN torneo.pais pa       ON pa.pais_id = s.pais_id
         LEFT JOIN @asistencias a  ON a.jugador_id = g.jugador_id
         GROUP BY g.jugador_id, j.nombre, j.apellido, pa.nombre
         ORDER BY SUM(g.goles) DESC, MAX(ISNULL(a.asistencias, 0)) DESC, j.apellido, j.nombre
         FOR XML PATH('goleador'), TYPE) AS "torneo",

        -- Por selección: total de goles y goleadores de cada una.
        (SELECT pa.nombre     AS "@pais",
                SUM(g.goles)  AS "@goles",
                (SELECT j2.nombre + ' ' + j2.apellido AS "@jugador",
                        SUM(g2.goles)                 AS "@goles"
                 FROM @goles g2
                 JOIN plantel.jugador j2 ON j2.jugador_id = g2.jugador_id
                 WHERE g2.seleccion_id = g.seleccion_id
                 GROUP BY g2.jugador_id, j2.nombre, j2.apellido
                 ORDER BY SUM(g2.goles) DESC, j2.apellido
                 FOR XML PATH('goleador'), TYPE)
         FROM @goles g
         JOIN torneo.seleccion s ON s.seleccion_id = g.seleccion_id
         JOIN torneo.pais pa     ON pa.pais_id = s.pais_id
         GROUP BY g.seleccion_id, pa.nombre
         ORDER BY SUM(g.goles) DESC, pa.nombre
         FOR XML PATH('seleccion'), TYPE) AS "por_seleccion",

        -- Por fase, en el orden del torneo.
        (SELECT g.fase        AS "@nombre",
                SUM(g.goles)  AS "@goles",
                (SELECT j3.nombre + ' ' + j3.apellido AS "@jugador",
                        pa3.nombre                    AS "@seleccion",
                        g3.goles                      AS "@goles"
                 FROM @goles g3
                 JOIN plantel.jugador j3   ON j3.jugador_id = g3.jugador_id
                 JOIN torneo.seleccion s3  ON s3.seleccion_id = g3.seleccion_id
                 JOIN torneo.pais pa3      ON pa3.pais_id = s3.pais_id
                 WHERE g3.fase = g.fase
                 ORDER BY g3.goles DESC, j3.apellido
                 FOR XML PATH('goleador'), TYPE)
         FROM @goles g
         GROUP BY g.fase, g.orden_fase
         ORDER BY g.orden_fase
         FOR XML PATH('fase'), TYPE) AS "por_fase"
    FOR XML PATH('goleadores'), TYPE);

    SELECT @resultado AS reporte_goleadores;
END;
GO


-- ========================================================================================
-- REPORTE 2: Tarjetas (amarillas y rojas) por selección y persona, con el detalle de las
-- suspensiones activas.
--   * Una fila por persona (jugador o cuerpo técnico) y una fila 'TOTAL SELECCIÓN' por
--     selección (GROUPING SETS).
--   * Amarillas: filas 'amarilla' (incluye la primera amarilla de una doble amarilla).
--   * Suspensión activa: su partido afectado sigue 'programado', o todavía no tiene partido
--     asignado (la selección no tenía más partidos programados al momento de la tarjeta).
--   * La selección de cada persona sale de plantel.vw_persona_partido (el mismo criterio que
--     usa evento.registrar_tarjeta al calcular la suspensión).
-- ========================================================================================
CREATE OR ALTER PROCEDURE evento.reporte_tarjetas
    @seleccion_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @seleccion_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id ' + CAST(@seleccion_id AS VARCHAR(12)) + '.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.reporte_tarjetas - consulta rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    WITH tarjeta_persona AS (
        SELECT vpp.seleccion_id, t.persona_id,
               SUM(IIF(t.tipo = 'amarilla', 1, 0))                    AS amarillas,
               SUM(IIF(t.tipo_expulsion = 'doble_amarilla', 1, 0))    AS rojas_doble_amarilla,
               SUM(IIF(t.tipo_expulsion = 'roja_directa', 1, 0))      AS rojas_directas
        FROM evento.tarjeta t
        JOIN plantel.vw_persona_partido vpp
          ON vpp.persona_id = t.persona_id AND vpp.partido_id = t.partido_id
        WHERE @seleccion_id IS NULL OR vpp.seleccion_id = @seleccion_id
        GROUP BY vpp.seleccion_id, t.persona_id
    ),
    detalle AS (
        SELECT pa.nombre AS seleccion, tp.persona_id,
               COALESCE(j.nombre + ' ' + j.apellido, ct.nombre + ' ' + ct.apellido) AS persona,
               IIF(j.jugador_id IS NOT NULL, 'jugador', 'cuerpo técnico')            AS rol,
               tp.amarillas, tp.rojas_doble_amarilla, tp.rojas_directas,
               susp.suspensiones_activas
        FROM tarjeta_persona tp
        JOIN torneo.seleccion s              ON s.seleccion_id = tp.seleccion_id
        JOIN torneo.pais pa                  ON pa.pais_id = s.pais_id
        LEFT JOIN plantel.jugador j          ON j.persona_id = tp.persona_id
        LEFT JOIN plantel.cuerpo_tecnico ct  ON ct.persona_id = tp.persona_id
        OUTER APPLY (
            SELECT STRING_AGG(
                       CONCAT(sp.motivo, ' -> ',
                              IIF(pa_af.partido_id IS NULL, 'partido a definir',
                                  CONCAT('pierde el partido ', pa_af.partido_id, ' (', pa_af.fase, ' del ',
                                         CONVERT(VARCHAR(10), pa_af.fecha_hora_utc, 23), ' vs ', riv.nombre, ')'))),
                       ' | ') WITHIN GROUP (ORDER BY sp.suspension_id) AS suspensiones_activas
            FROM evento.suspension sp
            JOIN evento.tarjeta ts           ON ts.tarjeta_id = sp.tarjeta_id
            LEFT JOIN torneo.partido pa_af   ON pa_af.partido_id = sp.partido_afectado_id
            LEFT JOIN torneo.seleccion s_riv
              ON s_riv.seleccion_id = IIF(pa_af.seleccion_local_id = tp.seleccion_id,
                                          pa_af.seleccion_visitante_id, pa_af.seleccion_local_id)
            LEFT JOIN torneo.pais riv        ON riv.pais_id = s_riv.pais_id
            WHERE ts.persona_id = tp.persona_id
              AND (sp.partido_afectado_id IS NULL OR pa_af.estado = 'programado')
        ) susp
    )
    SELECT seleccion                                              AS Seleccion,
           IIF(GROUPING(persona) = 1, 'TOTAL SELECCIÓN', persona) AS Persona,
           IIF(GROUPING(persona) = 1, '', rol)                    AS Rol,
           SUM(amarillas)                                         AS Amarillas,
           SUM(rojas_doble_amarilla)                              AS Rojas_doble_amarilla,
           SUM(rojas_directas)                                    AS Rojas_directas,
           SUM(amarillas + rojas_doble_amarilla + rojas_directas) AS Total_tarjetas,
           -- ISNULL dentro del agregado: evita el aviso "Null value is eliminated by an aggregate".
           CASE WHEN GROUPING(persona) = 1
                     THEN CAST(SUM(IIF(suspensiones_activas IS NULL, 0, 1)) AS VARCHAR(5)) + ' suspendido(s)'
                WHEN MAX(ISNULL(suspensiones_activas, '')) <> '' THEN 'SÍ'
                ELSE 'NO' END                                     AS Suspension_activa,
           IIF(GROUPING(persona) = 1, NULL,
               NULLIF(MAX(ISNULL(suspensiones_activas, '')), '')) AS Detalle_suspension
    FROM detalle
    GROUP BY GROUPING SETS ((seleccion, persona_id, persona, rol), (seleccion))
    ORDER BY seleccion, GROUPING(persona),
             SUM(amarillas + rojas_doble_amarilla + rojas_directas) DESC, persona;
END;
GO


-- ========================================================================================
-- REPORTE 3 (XML): Designaciones arbitrales.
--   <designaciones_arbitrales>
--     <arbitro nombre pais categoria partidos_dirigidos designaciones amarillas_mostradas rojas_mostradas>
--       <designacion partido_id fecha fase encuentro rol resultado>
--         <tarjetas><tarjeta .../></tarjetas>     sólo cuando dirigió como principal
--         <informes><informe .../></informes>     informes post-partido de esa designación
-- Las tarjetas las señala el árbitro principal: se le atribuyen sólo a él. Los demás roles
-- (asistentes, cuarto, VAR) figuran como designaciones sin tarjetas.
-- ========================================================================================
CREATE OR ALTER PROCEDURE arbitraje.reporte_designaciones
    @arbitro_id INT = NULL,
    @resultado  XML = NULL OUTPUT                -- el mismo XML que se muestra, para reutilizarlo
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @arbitro_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM arbitraje.arbitro WHERE arbitro_id = @arbitro_id)
        SET @errores += '- No existe el árbitro con id ' + CAST(@arbitro_id AS VARCHAR(12)) + '.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.reporte_designaciones - consulta rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    SET @resultado = (
    SELECT a.nombre + ' ' + a.apellido AS "@nombre",
           pa.nombre                   AS "@pais",
           a.categoria                 AS "@categoria",
           (SELECT COUNT(*) FROM arbitraje.designacion_arbitral d
            WHERE d.arbitro_id = a.arbitro_id AND d.rol = 'principal')       AS "@partidos_dirigidos",
           (SELECT COUNT(*) FROM arbitraje.designacion_arbitral d
            WHERE d.arbitro_id = a.arbitro_id)                               AS "@designaciones",
           (SELECT COUNT(*) FROM arbitraje.designacion_arbitral d
            JOIN evento.tarjeta t ON t.partido_id = d.partido_id
            WHERE d.arbitro_id = a.arbitro_id AND d.rol = 'principal' AND t.tipo = 'amarilla') AS "@amarillas_mostradas",
           (SELECT COUNT(*) FROM arbitraje.designacion_arbitral d
            JOIN evento.tarjeta t ON t.partido_id = d.partido_id
            WHERE d.arbitro_id = a.arbitro_id AND d.rol = 'principal' AND t.tipo = 'roja')     AS "@rojas_mostradas",
           (SELECT d.partido_id                                AS "@partido_id",
                   CONVERT(VARCHAR(16), p.fecha_hora_utc, 120) AS "@fecha_utc",
                   p.fase                                      AS "@fase",
                   pl.nombre + ' vs ' + pv.nombre              AS "@encuentro",
                   d.rol                                       AS "@rol",
                   IIF(p.estado = 'finalizado',
                       CONCAT(p.goles_local, '-', p.goles_visitante), p.estado) AS "@resultado",
                   (SELECT t.minuto                                          AS "@minuto",
                           t.periodo                                         AS "@periodo",
                           t.tipo                                            AS "@tipo",
                           t.tipo_expulsion                                  AS "@expulsion",
                           COALESCE(j.nombre + ' ' + j.apellido,
                                    ct.nombre + ' ' + ct.apellido)           AS "@persona",
                           pt.nombre                                         AS "@seleccion",
                           t.motivo                                          AS "@motivo"
                    FROM evento.tarjeta t
                    JOIN plantel.vw_persona_partido vpp
                      ON vpp.persona_id = t.persona_id AND vpp.partido_id = t.partido_id
                    JOIN torneo.seleccion st            ON st.seleccion_id = vpp.seleccion_id
                    JOIN torneo.pais pt                 ON pt.pais_id = st.pais_id
                    LEFT JOIN plantel.jugador j         ON j.persona_id = t.persona_id
                    LEFT JOIN plantel.cuerpo_tecnico ct ON ct.persona_id = t.persona_id
                    WHERE t.partido_id = d.partido_id AND d.rol = 'principal'
                    ORDER BY t.minuto, t.tarjeta_id
                    FOR XML PATH('tarjeta'), TYPE)                           AS "tarjetas",
                   (SELECT CONVERT(VARCHAR(16), i.fecha, 120) AS "@fecha",
                           i.sancion                          AS "@sancion",
                           i.contenido                        AS "text()"
                    FROM arbitraje.informe_arbitral i
                    WHERE i.designacion_id = d.designacion_id
                    ORDER BY i.fecha
                    FOR XML PATH('informe'), TYPE)                           AS "informes"
            FROM arbitraje.designacion_arbitral d
            JOIN torneo.partido p    ON p.partido_id = d.partido_id
            JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
            JOIN torneo.pais pl      ON pl.pais_id = sl.pais_id
            JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
            JOIN torneo.pais pv      ON pv.pais_id = sv.pais_id
            WHERE d.arbitro_id = a.arbitro_id
            ORDER BY p.fecha_hora_utc
            FOR XML PATH('designacion'), TYPE) AS "designaciones"
    FROM arbitraje.arbitro a
    JOIN torneo.pais pa ON pa.pais_id = a.pais_id
    WHERE @arbitro_id IS NULL OR a.arbitro_id = @arbitro_id
    ORDER BY a.apellido, a.nombre
    FOR XML PATH('arbitro'), ROOT('designaciones_arbitrales'), TYPE);

    SELECT @resultado AS reporte_designaciones;
END;
GO


-- ========================================================================================
-- REPORTE 4: Ocupación publicitaria por sede y partido, e ingresos.
--   Resultado 1 (resumen): una fila por partido con los anunciantes de sus 4 espacios, la
--   ocupación (espacios con pieza / 4) y los ingresos; subtotal por sede y total general
--   (GROUPING SETS). Los partidos sin espacios asignados cuentan con ocupación 0.
--     Ingreso_facturado_USD: lo ya facturado (monto histórico de espacio_publicitario).
--     Ingreso_estimado_USD:  facturado + tarifa vigente de los espacios asignados sin facturar.
--   Resultado 2 (sólo con @detalle = 1): una fila por espacio.
-- Montos en USD (la importación de tarifas de la Entrega 6 los convierte a USD).
-- ========================================================================================
CREATE OR ALTER PROCEDURE publicidad.reporte_ocupacion
    @sede_id INT = NULL,
    @detalle BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @sede_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.sede WHERE sede_id = @sede_id)
        SET @errores += '- No existe la sede con id ' + CAST(@sede_id AS VARCHAR(12)) + '.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.reporte_ocupacion - consulta rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    WITH por_partido AS (
        SELECT p.partido_id, p.sede_id, p.fecha_hora_local, p.fase, p.estado,
               pl.nombre + ' vs ' + pv.nombre                                     AS encuentro,
               COUNT(e.pieza_id)                                                  AS ocupados,
               STRING_AGG(CASE WHEN e.espacio_id IS NULL THEN NULL         -- partido sin espacios registrados
                               WHEN an.nombre IS NULL THEN CONCAT(e.numero_espacio, ': (vacío)')
                               ELSE CONCAT(e.numero_espacio, ': ', an.nombre) END, ' | ')
                   WITHIN GROUP (ORDER BY e.numero_espacio)                       AS anunciantes,
               ISNULL(SUM(IIF(e.facturado = 1, e.monto_facturado, 0)), 0)         AS ingreso_facturado,
               ISNULL(SUM(CASE WHEN e.facturado = 1 THEN e.monto_facturado
                               WHEN e.pieza_id IS NOT NULL THEN pz.costo_tarifa
                               ELSE 0 END), 0)                                    AS ingreso_estimado
        FROM torneo.partido p
        JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
        JOIN torneo.pais pl      ON pl.pais_id = sl.pais_id
        JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
        JOIN torneo.pais pv      ON pv.pais_id = sv.pais_id
        LEFT JOIN publicidad.espacio_publicitario e ON e.partido_id = p.partido_id
        LEFT JOIN publicidad.pieza_publicitaria pz  ON pz.pieza_id = e.pieza_id
        LEFT JOIN publicidad.campania c             ON c.campania_id = pz.campania_id
        LEFT JOIN publicidad.anunciante an          ON an.anunciante_id = c.anunciante_id
        WHERE @sede_id IS NULL OR p.sede_id = @sede_id
        GROUP BY p.partido_id, p.sede_id, p.fecha_hora_local, p.fase, p.estado, pl.nombre, pv.nombre
    )
    SELECT IIF(GROUPING(se.nombre) = 1, 'TOTAL GENERAL', se.nombre)        AS Sede,
           IIF(GROUPING(pp.partido_id) = 1,
               IIF(GROUPING(se.nombre) = 1, '', 'SUBTOTAL SEDE'),
               MAX(pp.encuentro))                                          AS Partido,
           pp.partido_id                                                   AS Partido_id,
           IIF(GROUPING(pp.partido_id) = 1, NULL,
               MAX(CONVERT(VARCHAR(16), pp.fecha_hora_local, 120)))        AS Fecha_local,
           IIF(GROUPING(pp.partido_id) = 1, NULL, MAX(pp.fase))            AS Fase,
           IIF(GROUPING(pp.partido_id) = 1, NULL, MAX(pp.estado))          AS Estado,
           IIF(GROUPING(pp.partido_id) = 1, NULL, MAX(pp.anunciantes))     AS Anunciantes_por_espacio,
           SUM(pp.ocupados)                                                AS Espacios_ocupados,
           COUNT(*) * 4                                                    AS Espacios_disponibles,
           CAST(100.0 * SUM(pp.ocupados) / (COUNT(*) * 4) AS DECIMAL(5,1)) AS Ocupacion_pct,
           SUM(pp.ingreso_facturado)                                       AS Ingreso_facturado_USD,
           SUM(pp.ingreso_estimado)                                        AS Ingreso_estimado_USD
    FROM por_partido pp
    JOIN torneo.sede se ON se.sede_id = pp.sede_id
    GROUP BY GROUPING SETS ((se.sede_id, se.nombre, pp.partido_id), (se.sede_id, se.nombre), ())
    ORDER BY GROUPING(se.nombre), se.nombre, se.sede_id, GROUPING(pp.partido_id), MAX(pp.fecha_hora_local);

    IF @detalle = 1
        SELECT se.nombre                                              AS Sede,
               p.partido_id                                           AS Partido_id,
               CONVERT(VARCHAR(16), p.fecha_hora_local, 120)          AS Fecha_local,
               e.numero_espacio                                       AS Espacio,
               ISNULL(an.nombre, '(vacío)')                           AS Anunciante,
               c.nombre                                               AS Campania,
               m.nombre                                               AS Mercado,
               pz.idioma                                              AS Idioma,
               CASE e.orden_prioridad WHEN 1 THEN 'país de una selección del partido'
                                      WHEN 2 THEN 'mayor poder adquisitivo'
                                      WHEN 3 THEN 'prime time del mercado'
                                      WHEN 4 THEN 'desempate por tarifa' END AS Criterio,
               CASE WHEN e.pieza_id IS NULL           THEN 'sin pieza'
                    WHEN e.facturado = 1              THEN 'facturado'
                    WHEN e.fecha_exhibicion IS NOT NULL THEN 'exhibido, pendiente de facturar'
                    ELSE 'asignado' END                               AS Estado,
               pz.costo_tarifa                                        AS Tarifa_USD,
               e.monto_facturado                                      AS Monto_facturado_USD
        FROM publicidad.espacio_publicitario e
        JOIN torneo.partido p                      ON p.partido_id = e.partido_id
        JOIN torneo.sede se                        ON se.sede_id = p.sede_id
        LEFT JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
        LEFT JOIN publicidad.campania c            ON c.campania_id = pz.campania_id
        LEFT JOIN publicidad.anunciante an         ON an.anunciante_id = c.anunciante_id
        LEFT JOIN torneo.pais m                    ON m.pais_id = pz.pais_mercado_id
        WHERE @sede_id IS NULL OR p.sede_id = @sede_id
        ORDER BY se.nombre, p.fecha_hora_local, e.numero_espacio;
END;
GO


-- ========================================================================================
-- REPORTE 5 (PIVOT): Matriz de prime time.
--   Filas: partidos. Columnas: mercados (código ISO del país). Celda: 'SI' si la hora del
--   partido llevada al huso del mercado cae en [prime_time_hora_desde, prime_time_hora_hasta)
--   de torneo.parametro; 'NO' si no. Mercados_en_prime_time cuenta los 'SI' de la fila.
--   El cálculo de la hora local es el mismo que usa publicidad.asignar_espacios_partido
--   (Entrega 5), para que la matriz coincida con el criterio de asignación de los espacios.
--   Mercados: por defecto, los países que tienen piezas publicitarias (mercados candidatos);
--   con @solo_mercados_con_piezas = 0, todos los países registrados.
--   Con @partido_id funciona como la simulación de prime time de un partido (módulo H).
-- Equivalente ANSI sin PIVOT (no estándar):
--   SELECT partido_id, MAX(CASE WHEN mercado = 'ARG' THEN en_prime_time END) AS ARG, ...
--   FROM base GROUP BY partido_id   -- una expresión CASE por cada mercado.
-- ========================================================================================
CREATE OR ALTER PROCEDURE publicidad.reporte_matriz_prime_time
    @partido_id               INT = NULL,
    @solo_mercados_con_piezas BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @desde INT, @hasta INT, @columnas NVARCHAR(MAX), @sql NVARCHAR(MAX);

    SELECT @desde = valor FROM torneo.parametro WHERE clave = 'prime_time_hora_desde';
    SELECT @hasta = valor FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta';
    SET @solo_mercados_con_piezas = ISNULL(@solo_mercados_con_piezas, 1);

    IF @desde IS NULL OR @hasta IS NULL
        SET @errores += '- Faltan configurar los parámetros prime_time_hora_desde / prime_time_hora_hasta.' + @nl;
    IF @partido_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + CAST(@partido_id AS VARCHAR(12)) + '.' + @nl;

    SELECT @columnas = STRING_AGG(CAST(QUOTENAME(m.codigo_iso) AS NVARCHAR(MAX)), N', ')
                       WITHIN GROUP (ORDER BY m.codigo_iso)
    FROM torneo.pais m
    WHERE @solo_mercados_con_piezas = 0
       OR EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria pz WHERE pz.pais_mercado_id = m.pais_id);

    IF @columnas IS NULL
        SET @errores += '- No hay mercados para evaluar (no hay piezas publicitarias cargadas).' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.reporte_matriz_prime_time - consulta rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    SET @sql = N'
    WITH base AS (
        SELECT p.partido_id, p.fecha_hora_utc, p.fase,
               pl.codigo_iso + '' vs '' + pv.codigo_iso AS encuentro,
               m.codigo_iso AS mercado,
               ((DATEPART(HOUR, SWITCHOFFSET(p.fecha_hora_utc, ''+00:00''))
                 + CAST(SUBSTRING(m.huso_horario, 4, 3) AS INT)) % 24 + 24) % 24 AS hora_local
        FROM torneo.partido p
        JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
        JOIN torneo.pais pl      ON pl.pais_id = sl.pais_id
        JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
        JOIN torneo.pais pv      ON pv.pais_id = sv.pais_id
        CROSS JOIN torneo.pais m
        WHERE (@partido_id IS NULL OR p.partido_id = @partido_id)
          AND (@solo = 0 OR EXISTS (SELECT 1 FROM publicidad.pieza_publicitaria pz
                                    WHERE pz.pais_mercado_id = m.pais_id))
    ),
    marcado AS (
        SELECT partido_id, fecha_hora_utc, fase, encuentro, mercado,
               IIF(hora_local >= @desde AND hora_local < @hasta, ''SI'', ''NO'') AS en_prime_time,
               SUM(IIF(hora_local >= @desde AND hora_local < @hasta, 1, 0))
                   OVER (PARTITION BY partido_id) AS mercados_en_prime_time
        FROM base
    )
    SELECT partido_id                                   AS Partido_id,
           CONVERT(VARCHAR(16), fecha_hora_utc, 120)    AS Fecha_UTC,
           fase                                         AS Fase,
           encuentro                                    AS Encuentro,
           mercados_en_prime_time                       AS Mercados_en_prime_time,
           ' + @columnas + N'
    FROM marcado
    PIVOT (MAX(en_prime_time) FOR mercado IN (' + @columnas + N')) AS pv
    ORDER BY fecha_hora_utc, partido_id;';

    EXEC sp_executesql @sql,
         N'@partido_id INT, @solo BIT, @desde INT, @hasta INT',
         @partido_id = @partido_id, @solo = @solo_mercados_con_piezas, @desde = @desde, @hasta = @hasta;
END;
GO


-- ========================================================================================
-- REPORTE 6 (XML): Selecciones y plantillas, con el vector anidado de convocados vigentes
-- (nombre, posición, club, dorsal). Un convocado dado de baja (ej: reemplazo por lesión) no
-- figura; sí figura quien lo reemplazó. Un club desconocido se omite (no se inventa el dato).
-- ========================================================================================
CREATE OR ALTER PROCEDURE plantel.reporte_plantillas
    @seleccion_id INT = NULL,
    @resultado    XML = NULL OUTPUT              -- el mismo XML que se muestra, para reutilizarlo
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @seleccion_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id ' + CAST(@seleccion_id AS VARCHAR(12)) + '.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.reporte_plantillas - consulta rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    SET @resultado = (
    SELECT pa.nombre      AS "@pais",
           pa.codigo_iso  AS "@codigo",
           c.nombre       AS "@confederacion",
           s.grupo        AS "@grupo",
           (SELECT ct.nombre + ' ' + ct.apellido FROM plantel.cuerpo_tecnico ct
            WHERE ct.seleccion_id = s.seleccion_id AND ct.rol = 'director_tecnico') AS "@director_tecnico",
           (SELECT COUNT(*) FROM plantel.convocatoria cv
            WHERE cv.seleccion_id = s.seleccion_id AND cv.fecha_baja IS NULL)        AS "@cantidad_convocados",
           (SELECT j.nombre + ' ' + j.apellido AS "@nombre",
                   j.posicion_habitual         AS "@posicion",
                   j.club_origen               AS "@club",
                   cv.dorsal                   AS "@dorsal"
            FROM plantel.convocatoria cv
            JOIN plantel.jugador j ON j.jugador_id = cv.jugador_id
            WHERE cv.seleccion_id = s.seleccion_id
              AND cv.fecha_baja IS NULL
            ORDER BY cv.dorsal
            FOR XML PATH('convocado'), TYPE) AS "convocados"
    FROM torneo.seleccion s
    JOIN torneo.pais pa          ON pa.pais_id = s.pais_id
    JOIN torneo.confederacion c  ON c.confederacion_id = s.confederacion_id
    WHERE @seleccion_id IS NULL OR s.seleccion_id = @seleccion_id
    ORDER BY s.grupo, pa.nombre
    FOR XML PATH('seleccion'), ROOT('selecciones'), TYPE);

    SELECT @resultado AS reporte_plantillas;
END;
GO


-- ========================================================================================
-- REPORTE 7: Resultados de los encuentros.
--   Resultado 1: fixture con resultado, penales, ganador, asistencia, ocupación del estadio y
--   la lista de goles del partido. Un partido 'finalizado' sin marcador cargado figura como
--   'sin datos' (no como NULL).
--   Resultado 2 (@tabla_posiciones = 1): tabla de posiciones de la fase de grupos, calculada
--   sobre los partidos finalizados (3 puntos por victoria, 1 por empate).
--   Filtros opcionales: fase, selección y sede (la tabla de posiciones sólo usa el de selección).
-- ========================================================================================
CREATE OR ALTER PROCEDURE torneo.reporte_resultados
    @fase             VARCHAR(13) = NULL,
    @seleccion_id     INT         = NULL,
    @sede_id          INT         = NULL,
    @tabla_posiciones BIT         = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10);

    IF @fase IS NOT NULL AND @fase NOT IN
       ('grupos', 'dieciseisavos', 'octavos', 'cuartos', 'semifinal', 'tercer_puesto', 'final')
        SET @errores += '- La fase debe ser grupos, dieciseisavos, octavos, cuartos, semifinal, tercer_puesto o final.' + @nl;
    IF @seleccion_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id ' + CAST(@seleccion_id AS VARCHAR(12)) + '.' + @nl;
    IF @sede_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM torneo.sede WHERE sede_id = @sede_id)
        SET @errores += '- No existe la sede con id ' + CAST(@sede_id AS VARCHAR(12)) + '.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.reporte_resultados - consulta rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    SELECT p.partido_id                                                    AS Partido_id,
           p.fase                                                          AS Fase,
           IIF(p.fase = 'grupos', sl.grupo, NULL)                          AS Grupo,
           CONVERT(VARCHAR(16), p.fecha_hora_local, 120) + ' (' + se.huso_horario + ')' AS Fecha_local,
           CONVERT(VARCHAR(16), p.fecha_hora_utc, 120)                     AS Fecha_UTC,
           se.nombre + ' (' + se.ciudad + ')'                              AS Sede,
           pl.nombre                                                       AS Local,
           CASE WHEN p.estado = 'programado' THEN 'vs'
                WHEN p.estado = 'suspendido' THEN 'suspendido'
                WHEN p.goles_local IS NULL OR p.goles_visitante IS NULL THEN 'sin datos'
                ELSE CONCAT(p.goles_local, ' - ', p.goles_visitante) END   AS Resultado,
           pv.nombre                                                       AS Visitante,
           IIF(p.estado = 'finalizado' AND p.penales_local IS NOT NULL,
               CONCAT('(', p.penales_local, '-', p.penales_visitante, ' pen.)'), '') AS Penales,
           CASE WHEN p.estado <> 'finalizado' OR p.goles_local IS NULL OR p.goles_visitante IS NULL THEN NULL
                WHEN p.goles_local > p.goles_visitante
                  OR (p.goles_local = p.goles_visitante AND p.penales_local > p.penales_visitante) THEN pl.nombre
                WHEN p.goles_visitante > p.goles_local
                  OR (p.goles_local = p.goles_visitante AND p.penales_visitante > p.penales_local) THEN pv.nombre
                ELSE 'empate' END                                          AS Ganador,
           p.asistencia_publico                                            AS Asistencia,
           CAST(100.0 * p.asistencia_publico / se.capacidad AS DECIMAL(5,1)) AS Ocupacion_estadio_pct,
           ISNULL(gl.goles, '')                                            AS Goles
    FROM torneo.partido p
    JOIN torneo.sede se      ON se.sede_id = p.sede_id
    JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
    JOIN torneo.pais pl      ON pl.pais_id = sl.pais_id
    JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
    JOIN torneo.pais pv      ON pv.pais_id = sv.pais_id
    OUTER APPLY (
        SELECT STRING_AGG(CONCAT(j.apellido, ' ', g.minuto, '''',
                                 CASE g.tipo_gol WHEN 'penal' THEN ' (p)' WHEN 'en_contra' THEN ' (e.c.)' ELSE '' END,
                                 ' [', pg.codigo_iso, ']'), ', ')
                   WITHIN GROUP (ORDER BY g.minuto, g.gol_id) AS goles
        FROM evento.gol g
        JOIN plantel.vw_formacion vf ON vf.formacion_id = g.formacion_id
        JOIN plantel.jugador j       ON j.jugador_id = g.jugador_id
        JOIN torneo.seleccion sg     ON sg.seleccion_id = vf.seleccion_id
        JOIN torneo.pais pg          ON pg.pais_id = sg.pais_id
        WHERE vf.partido_id = p.partido_id AND g.periodo <> 'penales'
    ) gl
    WHERE (@fase IS NULL OR p.fase = @fase)
      AND (@seleccion_id IS NULL OR @seleccion_id IN (p.seleccion_local_id, p.seleccion_visitante_id))
      AND (@sede_id IS NULL OR p.sede_id = @sede_id)
    ORDER BY p.fecha_hora_utc, p.partido_id;

    IF @tabla_posiciones = 1
    BEGIN
        WITH participacion AS (                       -- una fila por selección y partido de grupos jugado
            SELECT p.seleccion_local_id AS seleccion_id, p.goles_local AS gf, p.goles_visitante AS gc
            FROM torneo.partido p
            WHERE p.fase = 'grupos' AND p.estado = 'finalizado' AND p.goles_local IS NOT NULL
            UNION ALL
            SELECT p.seleccion_visitante_id, p.goles_visitante, p.goles_local
            FROM torneo.partido p
            WHERE p.fase = 'grupos' AND p.estado = 'finalizado' AND p.goles_local IS NOT NULL
        ),
        tabla AS (
            SELECT s.grupo, s.seleccion_id, pa.nombre AS seleccion,
                   COUNT(pt.seleccion_id)                       AS pj,
                   ISNULL(SUM(IIF(pt.gf > pt.gc, 1, 0)), 0)     AS pg,
                   ISNULL(SUM(IIF(pt.gf = pt.gc, 1, 0)), 0)     AS pe,
                   ISNULL(SUM(IIF(pt.gf < pt.gc, 1, 0)), 0)     AS pp,
                   ISNULL(SUM(pt.gf), 0)                        AS gf,
                   ISNULL(SUM(pt.gc), 0)                        AS gc
            FROM torneo.seleccion s
            JOIN torneo.pais pa         ON pa.pais_id = s.pais_id
            LEFT JOIN participacion pt  ON pt.seleccion_id = s.seleccion_id
            WHERE EXISTS (SELECT 1 FROM torneo.partido p
                          WHERE p.fase = 'grupos' AND s.seleccion_id IN (p.seleccion_local_id, p.seleccion_visitante_id))
            GROUP BY s.grupo, s.seleccion_id, pa.nombre
        )
        SELECT grupo AS Grupo,
               RANK() OVER (PARTITION BY grupo ORDER BY pg * 3 + pe DESC, gf - gc DESC, gf DESC) AS Posicion,
               seleccion AS Seleccion, pj AS PJ, pg AS PG, pe AS PE, pp AS PP,
               gf AS GF, gc AS GC, gf - gc AS DG, pg * 3 + pe AS Pts
        FROM tabla
        WHERE @seleccion_id IS NULL
           OR grupo = (SELECT grupo FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        ORDER BY grupo, Posicion, seleccion;
    END;
END;
GO
