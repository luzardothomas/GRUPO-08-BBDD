-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 7: Pruebas de los reportes
-- FECHA: 05/11/2026
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Pruebas de los 7 SP de entrega7_reportes.sql, sobre los datos de entrega7_carga_datos.sql.
--   Por cada reporte:
--     Rn.1     ejecución completa: muestra el reporte (evidencia) y verifica sus totales.
--     Rn.2..   filtros opcionales.
--     Rn.V     validaciones: parámetros inválidos => THROW 50002 con un único mensaje que agrupa
--              todos los errores.
--   Cada prueba es un lote: un comentario "PRUEBA <id>" con el "Resultado esperado", un
--   PRINT '--- <id> ...' que la identifica en Mensajes y, cuando se puede verificar
--   automáticamente, un PRINT 'OK ...' o 'FALLO ...'.
--   Los reportes XML se verifican con XQuery sobre su parámetro OUTPUT @resultado; los tabulares,
--   capturando el resultado con INSERT ... EXEC.
--
-- CÓMO EJECUTARLO:
--   Con la base recién creada, ejecutar en orden: entrega5_db_definition.sql, entrega5_sp_ABM.sql,
--   entrega5_sp_logica_negocio.sql, entrega7_carga_datos.sql y entrega7_reportes.sql. Después,
--   este script completo (o una prueba sola: su lote, hasta el GO). Los valores esperados
--   suponen la base sólo con la carga de entrega7_carga_datos.sql.
-- ============================================================

USE mundial_2026;
GO

SET NOCOUNT ON;
GO

-- ============================================================
-- REPORTE 1 (XML): evento.reporte_goleadores
-- ============================================================

/* PRUEBA R1.1 - Goleadores del torneo, por selección y por fase
   Resultado esperado:
     * <torneo>: 73 goles válidos (se registraron 74; el gol en contra de Corea del Sur en el
       partido Estados Unidos-Corea del Sur no suma para ningún goleador). Puesto 1 compartido
       por 3 jugadores con 5 goles: Karim Camara (Francia), Agustín Herrera (Argentina) y
       Felipe Rocha (Brasil). Siguen, con 4: Emiliano Herrera (España), Tomás López (Argentina)
       y Youssef Ziani (Francia).
     * <por_seleccion>: Francia 11, Argentina 10, España 8 (las tres primeras).
     * <por_fase>, en orden de torneo: grupos 58, cuartos 7, semifinal 8 (sin fases vacías). */
PRINT '--- R1.1 evento.reporte_goleadores (completo)';
DECLARE @x XML;
EXEC evento.reporte_goleadores @resultado = @x OUTPUT;

IF @x.value('sum(/goleadores/torneo/goleador/@goles)', 'INT') = 73
   AND @x.value('count(/goleadores/torneo/goleador[@puesto = 1])', 'INT') = 3
   AND @x.value('(/goleadores/por_seleccion/seleccion/@pais)[1]', 'VARCHAR(80)') = 'Francia'
   AND @x.value('(/goleadores/por_seleccion/seleccion/@goles)[1]', 'INT') = 11
   AND @x.value('count(/goleadores/por_fase/fase)', 'INT') = 3
   AND @x.value('(/goleadores/por_fase/fase/@nombre)[1]', 'VARCHAR(13)') = 'grupos'
   AND @x.value('(/goleadores/por_fase/fase/@nombre)[2]', 'VARCHAR(13)') = 'cuartos'
   AND @x.value('(/goleadores/por_fase/fase/@nombre)[3]', 'VARCHAR(13)') = 'semifinal'
    PRINT 'OK - 73 goles, 3 goleadores en el puesto 1, Francia encabeza por selección, fases en orden.';
ELSE
    PRINT 'FALLO - los totales del reporte de goleadores no coinciden con lo esperado.';
GO

/* PRUEBA R1.2 - Filtro por selección (Argentina)
   Resultado esperado: sólo goleadores de Argentina, 10 goles: Agustín Herrera 5, Tomás López 4
   y un jugador con 1 (penal ante Japón). <por_seleccion> tiene una sola selección. */
PRINT '--- R1.2 evento.reporte_goleadores @seleccion_id = Argentina';
DECLARE @x XML, @arg INT = (SELECT s.seleccion_id FROM torneo.seleccion s
                            JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG');
EXEC evento.reporte_goleadores @seleccion_id = @arg, @resultado = @x OUTPUT;

IF @x.value('sum(/goleadores/torneo/goleador/@goles)', 'INT') = 10
   AND @x.value('count(/goleadores/por_seleccion/seleccion)', 'INT') = 1
   AND @x.value('count(/goleadores/torneo/goleador[@seleccion != "Argentina"])', 'INT') = 0
    PRINT 'OK - sólo Argentina, 10 goles.';
ELSE
    PRINT 'FALLO - el filtro por selección no devolvió sólo los 10 goles de Argentina.';
GO

/* PRUEBA R1.3 - Filtro por fase (semifinal)
   Resultado esperado: 8 goles: Argentina 2 y Brasil 1 (Argentina-Brasil 2-1), Francia 3 y
   Uruguay 2 (Francia-Uruguay 3-2). <por_fase> tiene sólo la fase semifinal. */
PRINT '--- R1.3 evento.reporte_goleadores @fase = semifinal';
DECLARE @x XML;
EXEC evento.reporte_goleadores @fase = 'semifinal', @resultado = @x OUTPUT;

IF @x.value('sum(/goleadores/torneo/goleador/@goles)', 'INT') = 8
   AND @x.value('count(/goleadores/por_fase/fase)', 'INT') = 1
    PRINT 'OK - 8 goles en semifinales.';
ELSE
    PRINT 'FALLO - el filtro por fase no devolvió los 8 goles de las semifinales.';
GO

/* PRUEBA R1.V - Validaciones
   Resultado esperado: THROW 50002 con las dos condiciones en un único mensaje:
     - No existe la selección con id -1.
     - La fase debe ser grupos, dieciseisavos, ... */
PRINT '--- R1.V evento.reporte_goleadores con parámetros inválidos';
BEGIN TRY
    EXEC evento.reporte_goleadores @seleccion_id = -1, @fase = 'octavo';
    PRINT 'FALLO - la consulta debía rechazarse.';
END TRY
BEGIN CATCH
    PRINT IIF(ERROR_NUMBER() = 50002, 'OK - rechazada: ', 'FALLO - error inesperado: ') + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- REPORTE 2: evento.reporte_tarjetas
-- ============================================================

/* PRUEBA R2.1 - Tarjetas por selección y persona, con suspensiones activas
   Resultado esperado: 27 personas de 14 selecciones (Estados Unidos y México no recibieron
   tarjetas), cada selección con su fila 'TOTAL SELECCIÓN'. En total 39 tarjetas: 36 amarillas,
   1 roja por doble amarilla y 2 rojas directas. Casos a observar:
     * Alemania, Moritz Krüger: 1 amarilla + 1 roja por doble amarilla (Brasil-Alemania).
     * Colombia, Santiago Álvarez: roja directa (España-Colombia).
     * Argentina, Facundo Herrera (dorsal 5): 2 amarillas; su suspensión por acumulación ya se
       cumplió (Marruecos-Argentina, ver R2.3), por eso figura 'NO'.
     * Uruguay, Facundo Díaz: director técnico (rol 'cuerpo técnico').
     * Exactamente 2 suspensiones activas:
         Francia, Mamadou Camara: 'Acumulación de 2 amarillas -> pierde el partido ... (final ... vs Argentina)'.
         Brasil, Danilo Rocha:    'Expulsión por roja directa -> pierde el partido ... (tercer_puesto ... vs Uruguay)'. */
PRINT '--- R2.1 evento.reporte_tarjetas (completo)';
EXEC evento.reporte_tarjetas;

DECLARE @r TABLE (seleccion VARCHAR(80), persona VARCHAR(210), rol VARCHAR(20), amarillas INT,
                  rojas_doble INT, rojas_directas INT, total INT, suspension VARCHAR(30), detalle VARCHAR(MAX));
INSERT INTO @r EXEC evento.reporte_tarjetas;

IF (SELECT COUNT(*) FROM @r WHERE persona <> 'TOTAL SELECCIÓN') = 27
   AND (SELECT COUNT(*) FROM @r WHERE persona = 'TOTAL SELECCIÓN') = 14
   AND (SELECT SUM(amarillas) FROM @r WHERE persona = 'TOTAL SELECCIÓN') = 36
   AND (SELECT SUM(rojas_doble) FROM @r WHERE persona = 'TOTAL SELECCIÓN') = 1
   AND (SELECT SUM(rojas_directas) FROM @r WHERE persona = 'TOTAL SELECCIÓN') = 2
   AND (SELECT COUNT(*) FROM @r WHERE suspension = 'SÍ') = 2
   AND EXISTS (SELECT 1 FROM @r WHERE persona = 'Mamadou Camara' AND suspension = 'SÍ' AND detalle LIKE '%(final%')
   AND EXISTS (SELECT 1 FROM @r WHERE persona = 'Danilo Rocha' AND suspension = 'SÍ' AND detalle LIKE '%(tercer_puesto%')
    PRINT 'OK - 27 personas, 39 tarjetas (36 + 1 + 2) y las 2 suspensiones activas esperadas.';
ELSE
    PRINT 'FALLO - el reporte de tarjetas no coincide con lo esperado.';
GO

/* PRUEBA R2.2 - Filtro por selección (Francia)
   Resultado esperado: 2 personas con 2 amarillas cada una (Antoine El Amrani y Mamadou Camara,
   éste con la suspensión activa para la final) y la fila 'TOTAL SELECCIÓN' con 4 amarillas y
   '1 suspendido(s)'. */
PRINT '--- R2.2 evento.reporte_tarjetas @seleccion_id = Francia';
DECLARE @fra INT = (SELECT s.seleccion_id FROM torneo.seleccion s
                    JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'FRA');
EXEC evento.reporte_tarjetas @seleccion_id = @fra;
GO

/* PRUEBA R2.3 - Evidencia: el suspendido por acumulación quedó afuera de la formación siguiente
   Resultado esperado: titulares de Argentina en Marruecos-Argentina = dorsales 1 a 4, 6 a 11 y
   13. Falta el 5 (Facundo Herrera, suspendido por 2 amarillas) y entra el 13 en su lugar. */
PRINT '--- R2.3 Titulares de Argentina en Marruecos-Argentina (suspendido por acumulación)';
SELECT fj.dorsal, j.nombre + ' ' + j.apellido AS jugador, fj.posicion
FROM torneo.partido p
JOIN torneo.seleccion sl          ON sl.seleccion_id = p.seleccion_local_id
JOIN torneo.pais pl               ON pl.pais_id = sl.pais_id
JOIN torneo.seleccion sv          ON sv.seleccion_id = p.seleccion_visitante_id
JOIN torneo.pais pv               ON pv.pais_id = sv.pais_id
JOIN plantel.formacion f          ON f.partido_id = p.partido_id AND f.condicion = 'visitante'
JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id AND fj.titular = 1
JOIN plantel.jugador j            ON j.jugador_id = fj.jugador_id
WHERE pl.codigo_iso = 'MAR' AND pv.codigo_iso = 'ARG' AND p.fase = 'grupos'
ORDER BY fj.dorsal;
GO

/* PRUEBA R2.V - Validaciones
   Resultado esperado: THROW 50002 - No existe la selección con id -1. */
PRINT '--- R2.V evento.reporte_tarjetas con parámetros inválidos';
BEGIN TRY
    EXEC evento.reporte_tarjetas @seleccion_id = -1;
    PRINT 'FALLO - la consulta debía rechazarse.';
END TRY
BEGIN CATCH
    PRINT IIF(ERROR_NUMBER() = 50002, 'OK - rechazada: ', 'FALLO - error inesperado: ') + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- REPORTE 3 (XML): arbitraje.reporte_designaciones
-- ============================================================

/* PRUEBA R3.1 - Designaciones arbitrales con las tarjetas señaladas
   Resultado esperado: 22 <arbitro> (ordenados por apellido) y 160 <designacion>
   (32 partidos x 5 roles); cada árbitro tiene 7 u 8 designaciones. Las tarjetas se le atribuyen
   al árbitro principal: entre todos, 36 amarillas y 3 rojas mostradas (39 <tarjeta>).
   4 <informe> post-partido, 1 con sanción ('Apercibimiento de la Comisión de Árbitros', al VAR
   de México-Japón). */
PRINT '--- R3.1 arbitraje.reporte_designaciones (completo)';
DECLARE @x XML;
EXEC arbitraje.reporte_designaciones @resultado = @x OUTPUT;

IF @x.value('count(/designaciones_arbitrales/arbitro)', 'INT') = 22
   AND @x.value('count(//designacion)', 'INT') = 160
   AND @x.value('sum(/designaciones_arbitrales/arbitro/@amarillas_mostradas)', 'INT') = 36
   AND @x.value('sum(/designaciones_arbitrales/arbitro/@rojas_mostradas)', 'INT') = 3
   AND @x.value('count(//tarjeta)', 'INT') = 39
   AND @x.value('count(//informe)', 'INT') = 4
   AND @x.value('count(//informe[@sancion])', 'INT') = 1
   AND @x.value('count(/designaciones_arbitrales/arbitro[@designaciones < 7 or @designaciones > 8])', 'INT') = 0
    PRINT 'OK - 22 árbitros, 160 designaciones, 36 amarillas y 3 rojas, 4 informes (1 con sanción).';
ELSE
    PRINT 'FALLO - el reporte de designaciones no coincide con lo esperado.';
GO

/* PRUEBA R3.2 - Filtro por árbitro (Hernán Bustos, Argentina)
   Resultado esperado: un único <arbitro> con 7 designaciones, 2 como principal, y ninguna en un
   partido de Argentina (bloqueo por conflicto de nacionalidad; la designación rechazada es el
   Lote 9 de la carga). */
PRINT '--- R3.2 arbitraje.reporte_designaciones @arbitro_id = Hernán Bustos';
DECLARE @x XML, @id INT = (SELECT arbitro_id FROM arbitraje.arbitro WHERE nombre = 'Hernán' AND apellido = 'Bustos');
EXEC arbitraje.reporte_designaciones @arbitro_id = @id, @resultado = @x OUTPUT;

IF @x.value('count(/designaciones_arbitrales/arbitro)', 'INT') = 1
   AND @x.value('(/designaciones_arbitrales/arbitro/@designaciones)[1]', 'INT') = 7
   AND @x.value('(/designaciones_arbitrales/arbitro/@partidos_dirigidos)[1]', 'INT') = 2
   AND @x.value('count(//designacion[contains(@encuentro, "Argentina")])', 'INT') = 0
    PRINT 'OK - 7 designaciones, 2 como principal, ninguna en partidos de Argentina.';
ELSE
    PRINT 'FALLO - el filtro por árbitro no coincide con lo esperado.';
GO

/* PRUEBA R3.V - Validaciones
   Resultado esperado: THROW 50002 - No existe el árbitro con id -1. */
PRINT '--- R3.V arbitraje.reporte_designaciones con parámetros inválidos';
BEGIN TRY
    EXEC arbitraje.reporte_designaciones @arbitro_id = -1;
    PRINT 'FALLO - la consulta debía rechazarse.';
END TRY
BEGIN CATCH
    PRINT IIF(ERROR_NUMBER() = 50002, 'OK - rechazada: ', 'FALLO - error inesperado: ') + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- REPORTE 4: publicidad.reporte_ocupacion
-- ============================================================

/* PRUEBA R4.1 - Ocupación publicitaria por sede y partido, e ingresos
   Resultado esperado: 41 filas = 32 partidos + 8 'SUBTOTAL SEDE' + 'TOTAL GENERAL'. Cada partido
   con sus 4 anunciantes (los 128 espacios ocupados: 100 %).
     TOTAL GENERAL: Ingreso_facturado_USD 9.765.000,00 / Ingreso_estimado_USD 11.000.000,00. La
     diferencia es la pauta de las semifinales (exhibida, sin facturar) y la del tercer puesto y
     la final (asignada, partidos programados).
     MetLife Stadium (6 partidos): facturado 1.555.000,00 / estimado 2.125.000,00. */
PRINT '--- R4.1 publicidad.reporte_ocupacion (completo)';
EXEC publicidad.reporte_ocupacion;

DECLARE @r TABLE (sede VARCHAR(80), partido VARCHAR(200), partido_id INT, fecha_local VARCHAR(16), fase VARCHAR(13),
                  estado VARCHAR(10), anunciantes VARCHAR(MAX), ocupados INT, disponibles INT, ocupacion DECIMAL(5,1),
                  facturado NUMERIC(14,2), estimado NUMERIC(14,2));
INSERT INTO @r EXEC publicidad.reporte_ocupacion;

IF (SELECT COUNT(*) FROM @r) = 41
   AND EXISTS (SELECT 1 FROM @r WHERE sede = 'TOTAL GENERAL' AND ocupados = 128 AND disponibles = 128
                 AND ocupacion = 100.0 AND facturado = 9765000.00 AND estimado = 11000000.00)
   AND EXISTS (SELECT 1 FROM @r WHERE sede = 'MetLife Stadium' AND partido = 'SUBTOTAL SEDE'
                 AND facturado = 1555000.00 AND estimado = 2125000.00)
    PRINT 'OK - 41 filas, 100 % de ocupación, 9.765.000 facturados y 11.000.000 estimados.';
ELSE
    PRINT 'FALLO - el reporte de ocupación no coincide con lo esperado.';
GO

/* PRUEBA R4.2 - Filtro por sede con detalle por espacio (MetLife Stadium)
   Resultado esperado:
     Resultado 1: 6 partidos + 'SUBTOTAL SEDE' + 'TOTAL GENERAL' (iguales, porque hay una sola sede).
     Resultado 2: 24 espacios (6 x 4) con anunciante, campaña, mercado, idioma, criterio que lo
     ubicó y estado: 'facturado' en grupos y cuartos, 'exhibido, pendiente de facturar' en la
     semifinal Argentina-Brasil y 'asignado' en la final. */
PRINT '--- R4.2 publicidad.reporte_ocupacion @sede_id = MetLife Stadium, @detalle = 1';
DECLARE @sede INT = (SELECT sede_id FROM torneo.sede WHERE nombre = 'MetLife Stadium');
EXEC publicidad.reporte_ocupacion @sede_id = @sede, @detalle = 1;
GO

/* PRUEBA R4.V - Validaciones
   Resultado esperado: THROW 50002 - No existe la sede con id -1. */
PRINT '--- R4.V publicidad.reporte_ocupacion con parámetros inválidos';
BEGIN TRY
    EXEC publicidad.reporte_ocupacion @sede_id = -1;
    PRINT 'FALLO - la consulta debía rechazarse.';
END TRY
BEGIN CATCH
    PRINT IIF(ERROR_NUMBER() = 50002, 'OK - rechazada: ', 'FALLO - error inesperado: ') + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- REPORTE 5 (PIVOT): publicidad.reporte_matriz_prime_time
-- ============================================================

/* PRUEBA R5.1 - Matriz de prime time (mercados con piezas)
   Resultado esperado: 32 filas (partidos) y 17 columnas de mercado: ARG, AUS, BRA, CAN, CHL, COL,
   DEU, ENG, ESP, FRA, JPN, KOR, MAR, MEX, SEN, URY, USA. Franja: [19, 23) hora local.
     16:00 UTC -> 0 mercados.
     19:00 UTC -> 6: DEU, ENG, ESP, FRA, MAR, SEN.
     23:00 UTC -> 6: ARG, BRA, CAN, CHL, URY, USA (SEN da 'NO': son las 23 h, fuera de la franja).
     01:00 UTC -> 8: ARG, BRA, CAN, CHL, COL, MEX, URY, USA.
   Los partidos con más de 4 mercados en prime time son el caso obligatorio de la sección IV:
   publicidad.asignar_espacios_partido tuvo que priorizar para elegir sólo 4 piezas. */
PRINT '--- R5.1 publicidad.reporte_matriz_prime_time (completo)';
EXEC publicidad.reporte_matriz_prime_time;
GO

/* PRUEBA R5.2 - Simulación para un partido (Alemania-Corea del Sur, 01:00 UTC)
   Resultado esperado: 1 fila con Mercados_en_prime_time = 8 y 'SI' en ARG, BRA, CAN, CHL, COL,
   MEX, URY y USA. Para comparar, se muestra cómo quedaron sus 4 espacios: el criterio 1 (país de
   una selección del partido: Alemania y Corea del Sur) y el 2 (mayor poder adquisitivo) se
   aplican antes que el de prime time. */
PRINT '--- R5.2 publicidad.reporte_matriz_prime_time @partido_id = Alemania-Corea del Sur';
DECLARE @partido INT = (SELECT p.partido_id FROM torneo.partido p
                        JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
                        JOIN torneo.pais pl      ON pl.pais_id = sl.pais_id
                        JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
                        JOIN torneo.pais pv      ON pv.pais_id = sv.pais_id
                        WHERE pl.codigo_iso = 'DEU' AND pv.codigo_iso = 'KOR');
EXEC publicidad.reporte_matriz_prime_time @partido_id = @partido;

SELECT e.numero_espacio AS Espacio, an.nombre AS Anunciante, m.nombre AS Mercado, e.orden_prioridad AS Criterio
FROM publicidad.espacio_publicitario e
JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
JOIN publicidad.campania c            ON c.campania_id = pz.campania_id
JOIN publicidad.anunciante an         ON an.anunciante_id = c.anunciante_id
JOIN torneo.pais m                    ON m.pais_id = pz.pais_mercado_id
WHERE e.partido_id = @partido
ORDER BY e.numero_espacio;
GO

/* PRUEBA R5.3 - Todos los países como mercado
   Resultado esperado: 32 filas y 26 columnas de mercado (los 26 países registrados, también los
   que no tienen piezas, como ITA, NLD o NZL). */
PRINT '--- R5.3 publicidad.reporte_matriz_prime_time @solo_mercados_con_piezas = 0';
EXEC publicidad.reporte_matriz_prime_time @solo_mercados_con_piezas = 0;
GO

/* PRUEBA R5.V - Validaciones
   Resultado esperado: THROW 50002 - No existe el partido con id -1. */
PRINT '--- R5.V publicidad.reporte_matriz_prime_time con parámetros inválidos';
BEGIN TRY
    EXEC publicidad.reporte_matriz_prime_time @partido_id = -1;
    PRINT 'FALLO - la consulta debía rechazarse.';
END TRY
BEGIN CATCH
    PRINT IIF(ERROR_NUMBER() = 50002, 'OK - rechazada: ', 'FALLO - error inesperado: ') + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- REPORTE 6 (XML): plantel.reporte_plantillas
-- ============================================================

/* PRUEBA R6.1 - Selecciones con el vector anidado de convocados
   Resultado esperado: 16 <seleccion> ordenadas por grupo (A: Argentina, Japón, Marruecos, México;
   ...), cada una con grupo, confederación, director técnico, cantidad_convocados = 23 y 23
   <convocado> (nombre, posición, club, dorsal) ordenados por dorsal: 368 en total.
   Francia: el dorsal 20 es Hugo Marchand (alta de último momento) y no figura Youssef Sarr
   (dado de baja por lesión). */
PRINT '--- R6.1 plantel.reporte_plantillas (completo)';
DECLARE @x XML;
EXEC plantel.reporte_plantillas @resultado = @x OUTPUT;

IF @x.value('count(/selecciones/seleccion)', 'INT') = 16
   AND @x.value('count(//convocado)', 'INT') = 368
   AND @x.value('count(/selecciones/seleccion[@cantidad_convocados != 23])', 'INT') = 0
   AND @x.value('(/selecciones/seleccion[@codigo = "FRA"]/convocados/convocado[@dorsal = 20]/@nombre)[1]', 'VARCHAR(100)')
       = 'Hugo Marchand'
   AND @x.value('count(//convocado[@nombre = "Youssef Sarr"])', 'INT') = 0
    PRINT 'OK - 16 selecciones con 23 convocados; Francia muestra el reemplazo de último momento.';
ELSE
    PRINT 'FALLO - el reporte de plantillas no coincide con lo esperado.';
GO

/* PRUEBA R6.2 - Filtro por selección (Francia)
   Resultado esperado: una sola <seleccion> (Francia, UEFA, grupo C, director técnico Youssef
   Martin) con sus 23 convocados. */
PRINT '--- R6.2 plantel.reporte_plantillas @seleccion_id = Francia';
DECLARE @fra INT = (SELECT s.seleccion_id FROM torneo.seleccion s
                    JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'FRA');
EXEC plantel.reporte_plantillas @seleccion_id = @fra;
GO

/* PRUEBA R6.V - Validaciones
   Resultado esperado: THROW 50002 - No existe la selección con id -1. */
PRINT '--- R6.V plantel.reporte_plantillas con parámetros inválidos';
BEGIN TRY
    EXEC plantel.reporte_plantillas @seleccion_id = -1;
    PRINT 'FALLO - la consulta debía rechazarse.';
END TRY
BEGIN CATCH
    PRINT IIF(ERROR_NUMBER() = 50002, 'OK - rechazada: ', 'FALLO - error inesperado: ') + ERROR_MESSAGE();
END CATCH;
GO

-- ============================================================
-- REPORTE 7: torneo.reporte_resultados
-- ============================================================

/* PRUEBA R7.1 - Resultados y tabla de posiciones
   Resultado esperado:
     Resultado 1: 32 partidos en orden cronológico; 30 con resultado y 2 'vs' (tercer puesto
     Brasil-Uruguay y final Argentina-Francia, programados). Penales: Brasil-México 1 - 1
     (4-3 pen.) gana Brasil; España-Uruguay 0 - 0 (3-4 pen.) gana Uruguay. En Estados
     Unidos-Corea del Sur el primer gol figura con '(e.c.)' (en contra).
     Resultado 2 (posiciones): A: Argentina 9, México 4, Japón 2, Marruecos 1;
     B: Brasil 7, Estados Unidos 5, Alemania 4, Corea del Sur 0; C: Francia 7, Uruguay 6,
     Senegal 4, Canadá 0; D: España 7, Inglaterra 5, Colombia 4, Australia 0. */
PRINT '--- R7.1 torneo.reporte_resultados (completo)';
EXEC torneo.reporte_resultados;

DECLARE @r TABLE (partido_id INT, fase VARCHAR(13), grupo CHAR(1), fecha_local VARCHAR(30), fecha_utc VARCHAR(16),
                  sede VARCHAR(170), local VARCHAR(80), resultado VARCHAR(20), visitante VARCHAR(80), penales VARCHAR(20),
                  ganador VARCHAR(80), asistencia INT, ocupacion DECIMAL(5,1), goles VARCHAR(MAX));
INSERT INTO @r EXEC torneo.reporte_resultados @tabla_posiciones = 0;

IF (SELECT COUNT(*) FROM @r) = 32
   AND (SELECT COUNT(*) FROM @r WHERE resultado = 'vs') = 2
   AND EXISTS (SELECT 1 FROM @r WHERE local = 'Brasil' AND visitante = 'México'
                 AND penales = '(4-3 pen.)' AND ganador = 'Brasil')
   AND EXISTS (SELECT 1 FROM @r WHERE local = 'España' AND visitante = 'Uruguay'
                 AND resultado = '0 - 0' AND ganador = 'Uruguay')
   AND EXISTS (SELECT 1 FROM @r WHERE local = 'Estados Unidos' AND visitante = 'Corea del Sur' AND goles LIKE '%(e.c.)%')
    PRINT 'OK - 32 partidos, 2 programados, definiciones por penales y gol en contra correctos.';
ELSE
    PRINT 'FALLO - el reporte de resultados no coincide con lo esperado.';
GO

/* PRUEBA R7.2 - Filtro por selección (Argentina)
   Resultado esperado: Resultado 1: los 6 partidos de Argentina (3 de grupos, cuartos, semifinal
   y la final programada). Resultado 2: sólo la tabla del grupo A. */
PRINT '--- R7.2 torneo.reporte_resultados @seleccion_id = Argentina';
DECLARE @arg INT = (SELECT s.seleccion_id FROM torneo.seleccion s
                    JOIN torneo.pais p ON p.pais_id = s.pais_id WHERE p.codigo_iso = 'ARG');
EXEC torneo.reporte_resultados @seleccion_id = @arg;
GO

/* PRUEBA R7.3 - Filtro por fase (cuartos), sin tabla de posiciones
   Resultado esperado: 4 partidos: Argentina 2-1 Estados Unidos, Francia 2-0 Inglaterra,
   Brasil 1-1 México (4-3 pen.) y España 0-0 Uruguay (3-4 pen.). */
PRINT '--- R7.3 torneo.reporte_resultados @fase = cuartos, @tabla_posiciones = 0';
EXEC torneo.reporte_resultados @fase = 'cuartos', @tabla_posiciones = 0;
GO

/* PRUEBA R7.V - Validaciones
   Resultado esperado: THROW 50002 con las tres condiciones en un único mensaje (fase inválida,
   selección inexistente y sede inexistente). */
PRINT '--- R7.V torneo.reporte_resultados con parámetros inválidos';
BEGIN TRY
    EXEC torneo.reporte_resultados @fase = 'octavo', @seleccion_id = -1, @sede_id = -1;
    PRINT 'FALLO - la consulta debía rechazarse.';
END TRY
BEGIN CATCH
    PRINT IIF(ERROR_NUMBER() = 50002, 'OK - rechazada: ', 'FALLO - error inesperado: ') + ERROR_MESSAGE();
END CATCH;
GO
