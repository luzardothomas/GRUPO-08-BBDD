-- =======================================================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 5: Stored Procedures
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Procedimientos almacenados de la base mundial_2026. Se ejecuta después de
--   entrega5_definition.sql (que crea la base, las tablas, el tipo tabla y las vistas):
--     II.    Procedimientos almacenados de ABM de cada tabla, con validaciones y un
--            único mensaje de error agrupado por SP y operación.
--     III.   Procedimientos de lógica de negocio, transaccionales y multi-tabla.
--     IV.    Carga de los parámetros iniciales.
--   Las pruebas están en entrega5_test.sql, que se ejecuta después de este script.
-- =======================================================================================

USE mundial_2026;
GO

-- ################################
-- ## III. SPs LÓGICA DE NEGOCIO ##
-- ################################
--
-- Cada SP resuelve una operación completa del negocio. Norma común:
--   * Primero se validan todas las reglas y se informan juntas en un único THROW 50002.
--   * Después se abre la transacción: o se confirman todas las tablas afectadas o ninguna
--     (SET XACT_ABORT ON + TRY/CATCH con ROLLBACK y THROW).
--   * Si el SP es invocado dentro de una transacción ya abierta no abre otra ni hace
--     ROLLBACK por su cuenta: deja esa decisión a quien la abrió (@tran_propia).
--   * Reutilizan los SP de ABM cuando la operación es de a una fila; cuando es por conjunto
--     (formación, terna arbitral, espacios) validan e insertan por conjunto.

-- ===========================
-- III.1 PARTIDOS Y RESULTADOS
-- ===========================

/* Cierra el partido: fija el resultado, la asistencia y el estado 'finalizado', y deja
 asentadas como exhibidas las piezas publicitarias asignadas (historial para facturar).
 Si el partido tiene detalle (ambas formaciones cargadas), el resultado sale de evento.gol
 y lo informado debe coincidir; si no lo tiene (ej: resultado importado), se usa lo informado. */

CREATE OR ALTER PROCEDURE torneo.registrar_resultado
    @partido_id         INT,
    @goles_local        INT = NULL,
    @goles_visitante    INT = NULL,
    @penales_local      INT = NULL,
    @penales_visitante  INT = NULL,
    @asistencia_publico INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @estado VARCHAR(10), @fase VARCHAR(13), @capacidad INT, @fecha_utc DATETIMEOFFSET,
            @det_gl INT, @det_gv INT, @det_pl INT, @det_pv INT, @con_detalle BIT = 0,
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @estado = p.estado, @fase = p.fase, @capacidad = s.capacidad, @fecha_utc = p.fecha_hora_utc,
           @det_gl = p.goles_local, @det_gv = p.goles_visitante,
           @det_pl = p.penales_local, @det_pv = p.penales_visitante
    FROM torneo.partido p
    JOIN torneo.sede s ON s.sede_id = p.sede_id
    WHERE p.partido_id = @partido_id;

    IF (SELECT COUNT(*) FROM plantel.formacion WHERE partido_id = @partido_id) = 2
        SET @con_detalle = 1;

    IF @estado IS NULL
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @estado = 'finalizado'
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF @estado = 'suspendido'
        SET @errores += '- El partido está suspendido: debe reprogramarse antes de cargar el resultado.' + @nl;

    IF @con_detalle = 1
    BEGIN
        -- El marcador ya lo mantienen los SP de gol; sin goles cargados es 0 a 0.
        SELECT @det_gl = ISNULL(@det_gl, 0), @det_gv = ISNULL(@det_gv, 0);
        IF (@goles_local IS NOT NULL AND @goles_local <> @det_gl)
           OR (@goles_visitante IS NOT NULL AND @goles_visitante <> @det_gv)
            SET @errores += '- El resultado informado no coincide con los goles registrados ('
                          + CAST(@det_gl AS VARCHAR(3)) + ' a ' + CAST(@det_gv AS VARCHAR(3)) + ').' + @nl;
        IF @det_pl IS NOT NULL
           AND ((@penales_local IS NOT NULL AND @penales_local <> @det_pl)
             OR (@penales_visitante IS NOT NULL AND @penales_visitante <> @det_pv))
            SET @errores += '- Los penales informados no coinciden con los registrados en la tanda ('
                          + CAST(@det_pl AS VARCHAR(3)) + ' a ' + CAST(@det_pv AS VARCHAR(3)) + ').' + @nl;
        SELECT @goles_local = @det_gl, @goles_visitante = @det_gv,
               @penales_local = ISNULL(@det_pl, @penales_local),
               @penales_visitante = ISNULL(@det_pv, @penales_visitante);
    END
    ELSE IF @goles_local IS NULL OR @goles_visitante IS NULL
        SET @errores += '- El partido no tiene formaciones cargadas: debe informarse el resultado (goles de ambos equipos).' + @nl;

    IF @goles_local < 0 OR @goles_visitante < 0
        SET @errores += '- Los goles no pueden ser negativos.' + @nl;
    IF @penales_local < 0 OR @penales_visitante < 0
        SET @errores += '- Los penales no pueden ser negativos.' + @nl;

    IF @fase = 'grupos' AND (@penales_local IS NOT NULL OR @penales_visitante IS NOT NULL)
        SET @errores += '- En fase de grupos no hay definición por penales.' + @nl;
    IF @fase <> 'grupos' AND @goles_local = @goles_visitante
       AND (@penales_local IS NULL OR @penales_visitante IS NULL OR @penales_local = @penales_visitante)
        SET @errores += '- En eliminación directa un empate debe definirse por penales, con un ganador.' + @nl;
    IF @goles_local <> @goles_visitante AND (@penales_local IS NOT NULL OR @penales_visitante IS NOT NULL)
        SET @errores += '- Sólo hay definición por penales si el partido terminó empatado.' + @nl;

    IF @asistencia_publico < 0
        SET @errores += '- La asistencia de público no puede ser negativa.' + @nl;
    IF @asistencia_publico > @capacidad
        SET @errores += '- La asistencia (' + CAST(@asistencia_publico AS VARCHAR(12))
                      + ') supera la capacidad de la sede (' + CAST(@capacidad AS VARCHAR(12)) + ').' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'torneo.registrar_resultado - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        UPDATE torneo.partido
        SET goles_local = @goles_local,
            goles_visitante = @goles_visitante,
            penales_local = @penales_local,
            penales_visitante = @penales_visitante,
            asistencia_publico = @asistencia_publico,
            estado = 'finalizado'
        WHERE partido_id = @partido_id;

        UPDATE publicidad.espacio_publicitario
        SET fecha_exhibicion = @fecha_utc
        WHERE partido_id = @partido_id AND pieza_id IS NOT NULL AND fecha_exhibicion IS NULL;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ===================================================
-- III.2 CONVOCATORIA: ALTAS Y BAJAS DE ÚLTIMO MOMENTO
-- ===================================================

/* Reemplazo de un convocado (ej: lesión): da de baja al saliente con fecha y motivo y da de
 alta al entrante, las dos cosas o ninguna. Si no se indica dorsal, hereda el del saliente. */

CREATE OR ALTER PROCEDURE plantel.reemplazar_convocado
    @seleccion_id     INT,
    @jugador_sale_id  INT,
    @jugador_entra_id INT,
    @fecha            DATE,
    @motivo           VARCHAR(150),
    @dorsal           INT = NULL,
    @convocatoria_id  INT = NULL OUTPUT                 -- convocatoria creada para el entrante
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @conv_sale_id INT, @dorsal_sale INT, @fecha_alta_sale DATE, @motivo_alta_sale VARCHAR(150),
            @apellido_sale VARCHAR(100), @motivo_alta VARCHAR(150),
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @conv_sale_id = c.convocatoria_id, @dorsal_sale = c.dorsal, @fecha_alta_sale = c.fecha_alta,
           @motivo_alta_sale = c.motivo_alta, @apellido_sale = j.apellido
    FROM plantel.convocatoria c
    JOIN plantel.jugador j ON j.jugador_id = c.jugador_id
    WHERE c.seleccion_id = @seleccion_id AND c.jugador_id = @jugador_sale_id AND c.fecha_baja IS NULL;

    SET @dorsal = ISNULL(@dorsal, @dorsal_sale);

    IF NOT EXISTS (SELECT 1 FROM torneo.seleccion WHERE seleccion_id = @seleccion_id)
        SET @errores += '- No existe la selección con id '
                      + ISNULL(CAST(@seleccion_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE IF @conv_sale_id IS NULL
        SET @errores += '- El jugador saliente no integra la convocatoria vigente de la selección.' + @nl;
    IF NOT EXISTS (SELECT 1 FROM plantel.jugador WHERE jugador_id = @jugador_entra_id)
        SET @errores += '- No existe el jugador entrante con id '
                      + ISNULL(CAST(@jugador_entra_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @jugador_sale_id = @jugador_entra_id
        SET @errores += '- El jugador entrante debe ser distinto del saliente.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.convocatoria WHERE jugador_id = @jugador_entra_id AND fecha_baja IS NULL)
        SET @errores += '- El jugador entrante ya integra una convocatoria vigente.' + @nl;
    IF @fecha IS NULL
        SET @errores += '- La fecha del reemplazo es obligatoria.' + @nl;
    IF @fecha < @fecha_alta_sale
        SET @errores += '- La fecha del reemplazo no puede ser anterior al alta del jugador saliente.' + @nl;
    IF NULLIF(LTRIM(RTRIM(@motivo)), '') IS NULL
        SET @errores += '- El motivo del reemplazo es obligatorio.' + @nl;
    IF @dorsal NOT BETWEEN 1 AND 99
        SET @errores += '- El dorsal debe estar entre 1 y 99.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.convocatoria
               WHERE seleccion_id = @seleccion_id AND dorsal = @dorsal AND fecha_baja IS NULL
                 AND jugador_id <> @jugador_sale_id)
        SET @errores += '- El dorsal ' + CAST(@dorsal AS VARCHAR(3)) + ' está en uso por otro convocado vigente.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.reemplazar_convocado - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    SET @motivo_alta = LEFT('Reemplaza a ' + @apellido_sale + ': ' + LTRIM(RTRIM(@motivo)), 150);

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        EXEC plantel.convocatoria_modificar
             @convocatoria_id = @conv_sale_id, @dorsal = @dorsal_sale, @fecha_alta = @fecha_alta_sale,
             @motivo_alta = @motivo_alta_sale, @fecha_baja = @fecha, @motivo_baja = @motivo;

        EXEC plantel.convocatoria_insertar
             @seleccion_id = @seleccion_id, @jugador_id = @jugador_entra_id, @dorsal = @dorsal,
             @fecha_alta = @fecha, @motivo_alta = @motivo_alta, @convocatoria_id = @convocatoria_id OUTPUT;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ===============================================
-- III.3 ALINEACIONES Y CAMBIOS DURANTE EL PARTIDO
-- ===============================================

/* Carga la formación completa de un equipo: cabecera + titulares + banco, todo o nada.
 El dorsal de cada jugador se toma de su convocatoria vigente a la fecha del partido.
 Un jugador suspendido para ese partido no puede integrar la formación. */

CREATE OR ALTER PROCEDURE plantel.cargar_formacion
    @partido_id      INT,
    @condicion       VARCHAR(15),
    @esquema_tactico VARCHAR(15),
    @jugadores       plantel.tt_formacion_jugador READONLY,
    @formacion_id    INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @seleccion_id INT, @fecha DATE, @estado VARCHAR(10), @lista VARCHAR(600),
            @titulares INT, @suplentes INT, @req_titulares INT, @max_suplentes INT, @min_convocados INT,
            @convocados INT, @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @seleccion_id = CASE @condicion WHEN 'local' THEN seleccion_local_id
                                           WHEN 'visitante' THEN seleccion_visitante_id END,
           @fecha = CAST(fecha_hora_utc AS DATE), @estado = estado
    FROM torneo.partido WHERE partido_id = @partido_id;

    SELECT @req_titulares  = valor FROM torneo.parametro WHERE clave = 'formacion_titulares';
    SELECT @max_suplentes  = valor FROM torneo.parametro WHERE clave = 'formacion_max_suplentes';
    SELECT @min_convocados = valor FROM torneo.parametro WHERE clave = 'convocatoria_min_jugadores';

    SELECT @titulares = ISNULL(SUM(CASE WHEN titular = 1 THEN 1 ELSE 0 END), 0),
           @suplentes = ISNULL(SUM(CASE WHEN titular = 0 THEN 1 ELSE 0 END), 0)
    FROM @jugadores;

    IF @estado IS NULL
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE IF @estado <> 'programado'
        SET @errores += '- El partido está ' + @estado + ': no admite carga de formaciones.' + @nl;
    IF @condicion IS NULL OR @condicion NOT IN ('local', 'visitante')
        SET @errores += '- La condición debe ser local o visitante.' + @nl;
    IF EXISTS (SELECT 1 FROM plantel.formacion WHERE partido_id = @partido_id AND condicion = @condicion)
        SET @errores += '- El equipo ' + @condicion + ' ya tiene formación cargada en ese partido.' + @nl;
    IF @esquema_tactico IS NULL OR LEN(@esquema_tactico) > 9
       OR (SELECT COUNT(*) FROM STRING_SPLIT(@esquema_tactico, '-')) NOT BETWEEN 3 AND 5
       OR EXISTS (SELECT 1 FROM STRING_SPLIT(@esquema_tactico, '-') WHERE value NOT LIKE '[1-9]')
       OR (SELECT SUM(TRY_CAST(value AS INT)) FROM STRING_SPLIT(@esquema_tactico, '-')) <> 10
        SET @errores += '- El esquema táctico debe tener entre 3 y 5 líneas que sumen 10 jugadores (ej: 4-3-3).' + @nl;

    IF @req_titulares IS NULL OR @max_suplentes IS NULL OR @min_convocados IS NULL
        SET @errores += '- Faltan configurar los parámetros de formación y convocatoria.' + @nl;
    ELSE
    BEGIN
        IF @titulares <> @req_titulares
            SET @errores += '- La formación debe tener exactamente ' + CAST(@req_titulares AS VARCHAR(3))
                          + ' titulares (se informaron ' + CAST(@titulares AS VARCHAR(3)) + ').' + @nl;
        IF @suplentes > @max_suplentes
            SET @errores += '- El banco admite hasta ' + CAST(@max_suplentes AS VARCHAR(3))
                          + ' suplentes (se informaron ' + CAST(@suplentes AS VARCHAR(3)) + ').' + @nl;
    END;

    IF EXISTS (SELECT 1 FROM @jugadores WHERE LTRIM(RTRIM(posicion)) = '')
        SET @errores += '- Todos los jugadores deben tener posición en cancha.' + @nl;

    SELECT @lista = STRING_AGG(CAST(d.jugador_id AS VARCHAR(12)), ', ')
    FROM (SELECT jugador_id FROM @jugadores GROUP BY jugador_id HAVING COUNT(*) > 1) d;
    IF @lista IS NOT NULL
        SET @errores += '- Jugadores repetidos en la lista (id): ' + @lista + '.' + @nl;

    IF @seleccion_id IS NOT NULL
    BEGIN
        SELECT @lista = STRING_AGG(CAST(l.jugador_id AS VARCHAR(12)), ', ')
        FROM (SELECT DISTINCT jugador_id FROM @jugadores) l
        WHERE NOT EXISTS (SELECT 1 FROM plantel.convocatoria c
                          WHERE c.seleccion_id = @seleccion_id AND c.jugador_id = l.jugador_id
                            AND c.fecha_alta <= @fecha AND (c.fecha_baja IS NULL OR c.fecha_baja > @fecha));
        IF @lista IS NOT NULL
            SET @errores += '- No integran la convocatoria vigente de la selección a la fecha del partido (id): '
                          + @lista + '.' + @nl;

        SELECT @lista = STRING_AGG(j.apellido + ' ' + j.nombre, ', ')
        FROM (SELECT DISTINCT jugador_id FROM @jugadores) l
        JOIN plantel.jugador j ON j.jugador_id = l.jugador_id
        WHERE EXISTS (SELECT 1 FROM evento.suspension s
                      JOIN evento.tarjeta t ON t.tarjeta_id = s.tarjeta_id
                      WHERE s.partido_afectado_id = @partido_id AND t.persona_id = j.persona_id);
        IF @lista IS NOT NULL
            SET @errores += '- Jugadores suspendidos para este partido: ' + LEFT(@lista, 400) + '.' + @nl;

        SELECT @convocados = COUNT(*) FROM plantel.convocatoria c
        WHERE c.seleccion_id = @seleccion_id
          AND c.fecha_alta <= @fecha AND (c.fecha_baja IS NULL OR c.fecha_baja > @fecha);
        IF @convocados < @min_convocados
            SET @errores += '- La selección tiene ' + CAST(@convocados AS VARCHAR(3))
                          + ' convocados vigentes: el reglamento exige al menos '
                          + CAST(@min_convocados AS VARCHAR(3)) + '.' + @nl;
    END;

    IF @errores <> ''
    BEGIN
        SET @errores = 'plantel.cargar_formacion - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        INSERT INTO plantel.formacion (partido_id, condicion, esquema_tactico)
        VALUES (@partido_id, @condicion, @esquema_tactico);

        SET @formacion_id = SCOPE_IDENTITY();

        INSERT INTO plantel.formacion_jugador (formacion_id, jugador_id, dorsal, posicion, titular)
        SELECT @formacion_id, l.jugador_id, c.dorsal, LTRIM(RTRIM(l.posicion)), l.titular
        FROM @jugadores l
        JOIN plantel.convocatoria c
          ON c.seleccion_id = @seleccion_id AND c.jugador_id = l.jugador_id
         AND c.fecha_alta <= @fecha AND (c.fecha_baja IS NULL OR c.fecha_baja > @fecha);

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* Registra un cambio identificando a los jugadores como en la planilla del partido: equipo
 (local/visitante) y dorsales. Calcula la ventana: los cambios del mismo equipo en el mismo
 minuto y período comparten ventana; si no, abre la siguiente. El reglamento (máximo de
 cambios y ventanas, quién está en cancha) lo valida evento.sustitucion_insertar. */

CREATE OR ALTER PROCEDURE evento.registrar_sustitucion
    @partido_id     INT,
    @condicion      VARCHAR(15),
    @dorsal_sale    INT,
    @dorsal_entra   INT,
    @minuto         INT,
    @periodo        VARCHAR(15),
    @motivo         VARCHAR(15),
    @sustitucion_id INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @formacion_id INT, @sale_id INT, @entra_id INT, @ventana INT,
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @formacion_id = formacion_id FROM plantel.formacion
    WHERE partido_id = @partido_id AND condicion = @condicion;

    SELECT @sale_id  = jugador_id FROM plantel.formacion_jugador
    WHERE formacion_id = @formacion_id AND dorsal = @dorsal_sale;
    SELECT @entra_id = jugador_id FROM plantel.formacion_jugador
    WHERE formacion_id = @formacion_id AND dorsal = @dorsal_entra;

    IF NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE IF @formacion_id IS NULL
        SET @errores += '- El equipo indicado (local/visitante) no tiene formación cargada en ese partido.' + @nl;
    ELSE
    BEGIN
        IF @sale_id IS NULL
            SET @errores += '- No hay un jugador con el dorsal ' + ISNULL(CAST(@dorsal_sale AS VARCHAR(5)), '(nulo)')
                          + ' en la formación (jugador que sale).' + @nl;
        IF @entra_id IS NULL
            SET @errores += '- No hay un jugador con el dorsal ' + ISNULL(CAST(@dorsal_entra AS VARCHAR(5)), '(nulo)')
                          + ' en la formación (jugador que entra).' + @nl;
    END;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.registrar_sustitucion - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        SELECT TOP (1) @ventana = numero_ventana
        FROM evento.sustitucion
        WHERE formacion_id = @formacion_id AND periodo = @periodo AND minuto = @minuto;

        IF @ventana IS NULL
            SELECT @ventana = ISNULL(MAX(numero_ventana), 0) + 1
            FROM evento.sustitucion WHERE formacion_id = @formacion_id;

        EXEC evento.sustitucion_insertar
             @formacion_id = @formacion_id, @jugador_sale_id = @sale_id, @jugador_entra_id = @entra_id,
             @minuto = @minuto, @periodo = @periodo, @numero_ventana = @ventana, @motivo = @motivo,
             @sustitucion_id = @sustitucion_id OUTPUT;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- =====================================================================
-- III.4 GOLES, AMONESTACIONES Y EXPULSIONES (CON CÁLCULO DE SUSPENSIÓN)
-- =====================================================================

/* Registra un gol por equipo y dorsal del autor (y del asistente). evento.gol_insertar graba
 el gol y actualiza el marcador del partido en la misma transacción.
 @condicion es siempre el equipo del autor: un gol en contra suma para el rival. */

CREATE OR ALTER PROCEDURE evento.registrar_gol
    @partido_id        INT,
    @condicion         VARCHAR(15),
    @dorsal_autor      INT,
    @minuto            INT,
    @tipo_gol          VARCHAR(15),
    @periodo           VARCHAR(20),
    @dorsal_asistencia INT = NULL,
    @gol_id            INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @formacion_id INT, @autor_id INT, @asistente_id INT;

    SELECT @formacion_id = formacion_id FROM plantel.formacion
    WHERE partido_id = @partido_id AND condicion = @condicion;

    SELECT @autor_id     = jugador_id FROM plantel.formacion_jugador
    WHERE formacion_id = @formacion_id AND dorsal = @dorsal_autor;
    SELECT @asistente_id = jugador_id FROM plantel.formacion_jugador
    WHERE formacion_id = @formacion_id AND dorsal = @dorsal_asistencia;

    IF NOT EXISTS (SELECT 1 FROM torneo.partido WHERE partido_id = @partido_id)
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE IF @formacion_id IS NULL
        SET @errores += '- El equipo indicado (local/visitante) no tiene formación cargada en ese partido.' + @nl;
    ELSE
    BEGIN
        IF @autor_id IS NULL
            SET @errores += '- No hay un jugador con el dorsal ' + ISNULL(CAST(@dorsal_autor AS VARCHAR(5)), '(nulo)')
                          + ' en la formación (autor).' + @nl;
        IF @dorsal_asistencia IS NOT NULL AND @asistente_id IS NULL
            SET @errores += '- No hay un jugador con el dorsal ' + CAST(@dorsal_asistencia AS VARCHAR(5))
                          + ' en la formación (asistente).' + @nl;
    END;

    IF @errores <> ''
    BEGIN
        SET @errores = 'evento.registrar_gol - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    EXEC evento.gol_insertar
         @formacion_id = @formacion_id, @jugador_id = @autor_id, @minuto = @minuto, @tipo_gol = @tipo_gol,
         @periodo = @periodo, @asistencia_jugador_id = @asistente_id, @gol_id = @gol_id OUTPUT;
END;
GO

/* Registra una tarjeta y, en la misma transacción, la suspensión que origine:
   * Roja (directa o por doble amarilla): suspensión por 'suspension_partidos_roja' partidos.
   * Amarilla: se cuenta la acumulación vigente de la persona (amarillas en partidos
     distintos, posteriores a su última suspensión por acumulación, sin contar las de
     partidos donde terminó expulsada por doble amarilla). Si alcanza la cantidad del
     criterio aplicable, se genera la suspensión. El criterio se toma de
     evento.criterio_suspension: el activo más específico para la fase y el tipo de persona.
   * La suspensión se asigna a los próximos partidos programados de su selección. Si todavía
     no están programados queda con partido NULL (se completa con evento.suspension_modificar).
 La persona se identifica por @persona_id (obligatorio para cuerpo técnico) o por equipo y dorsal.
 Si la persona ya tenía una amarilla en el partido, la segunda se convierte sola en roja
 por doble amarilla. */

CREATE OR ALTER PROCEDURE evento.registrar_tarjeta
    @partido_id             INT,
    @minuto                 INT,
    @periodo                VARCHAR(25),
    @tipo                   VARCHAR(10),
    @motivo                 VARCHAR(150) = NULL,
    @persona_id             INT = NULL,
    @condicion              VARCHAR(15) = NULL,
    @dorsal                 INT = NULL,
    @tipo_expulsion         VARCHAR(20) = NULL,
    @tarjeta_id             INT = NULL OUTPUT,
    @suspensiones_generadas INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @tipo_persona VARCHAR(14), @seleccion_id INT, @fase VARCHAR(13), @fecha_utc DATETIMEOFFSET,
            @criterio_id INT, @umbral INT, @partidos_criterio INT, @criterio_aplicado INT,
            @partidos INT = 0, @motivo_suspension VARCHAR(150), @ultima_disparadora INT, @acumuladas INT,
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SET @suspensiones_generadas = 0;

    -- Identificación por equipo y dorsal.
    IF @persona_id IS NULL AND @condicion IS NOT NULL AND @dorsal IS NOT NULL
        SELECT @persona_id = j.persona_id
        FROM plantel.formacion f
        JOIN plantel.formacion_jugador fj ON fj.formacion_id = f.formacion_id
        JOIN plantel.jugador j            ON j.jugador_id = fj.jugador_id
        WHERE f.partido_id = @partido_id AND f.condicion = @condicion AND fj.dorsal = @dorsal;

    IF @persona_id IS NULL
    BEGIN
        SET @errores = 'evento.registrar_tarjeta - operación rechazada:' + @nl
                     + '- No se pudo identificar a la persona: informar @persona_id, o equipo (local/visitante) y un dorsal de su formación.' + @nl;
        THROW 50002, @errores, 1;
    END;

    -- Segunda amarilla en el mismo partido => roja por doble amarilla.
    IF @tipo = 'amarilla'
       AND EXISTS (SELECT 1 FROM evento.tarjeta
                   WHERE partido_id = @partido_id AND persona_id = @persona_id AND tipo = 'amarilla')
        SELECT @tipo = 'roja', @tipo_expulsion = 'doble_amarilla';
    IF @tipo = 'roja' AND @tipo_expulsion IS NULL
        SET @tipo_expulsion = 'roja_directa';

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        -- 1) La tarjeta (evento.tarjeta_insertar valida todo y agrupa los errores).
        EXEC evento.tarjeta_insertar
             @partido_id = @partido_id, @persona_id = @persona_id, @minuto = @minuto, @periodo = @periodo,
             @tipo = @tipo, @motivo = @motivo, @tipo_expulsion = @tipo_expulsion, @tarjeta_id = @tarjeta_id OUTPUT;

        SELECT @fase = fase, @fecha_utc = fecha_hora_utc FROM torneo.partido WHERE partido_id = @partido_id;
        SELECT @tipo_persona = tipo_persona FROM plantel.persona WHERE persona_id = @persona_id;
        SELECT TOP (1) @seleccion_id = seleccion_id
        FROM plantel.vw_persona_partido WHERE partido_id = @partido_id AND persona_id = @persona_id;

        -- 2) ¿Corresponde suspensión?
        IF @tipo = 'roja'
        BEGIN
            SELECT @partidos = valor FROM torneo.parametro WHERE clave = 'suspension_partidos_roja';
            SET @partidos = ISNULL(@partidos, 1);
            SET @motivo_suspension = IIF(@tipo_expulsion = 'doble_amarilla',
                                         'Expulsión por doble amarilla', 'Expulsión por roja directa');
        END
        ELSE
        BEGIN
            SELECT TOP (1) @criterio_id = criterio_id, @umbral = cantidad_amarillas,
                           @partidos_criterio = partidos_suspension
            FROM evento.criterio_suspension
            WHERE activo = 1
              AND (fase_aplicable IS NULL OR fase_aplicable = @fase)
              AND (tipo_persona_aplicable IS NULL OR tipo_persona_aplicable = @tipo_persona)
            ORDER BY IIF(fase_aplicable IS NULL, 0, 1) + IIF(tipo_persona_aplicable IS NULL, 0, 1) DESC,
                     cantidad_amarillas ASC;

            IF @criterio_id IS NOT NULL
            BEGIN
                SELECT @ultima_disparadora = ISNULL(MAX(s.tarjeta_id), 0)
                FROM evento.suspension s
                JOIN evento.tarjeta t ON t.tarjeta_id = s.tarjeta_id
                WHERE t.persona_id = @persona_id AND s.criterio_id IS NOT NULL;

                SELECT @acumuladas = COUNT(*)
                FROM evento.tarjeta a
                WHERE a.persona_id = @persona_id AND a.tipo = 'amarilla' AND a.tarjeta_id > @ultima_disparadora
                  AND NOT EXISTS (SELECT 1 FROM evento.tarjeta r
                                  WHERE r.partido_id = a.partido_id AND r.persona_id = a.persona_id
                                    AND r.tipo_expulsion = 'doble_amarilla');

                IF @acumuladas >= @umbral
                    SELECT @partidos = @partidos_criterio, @criterio_aplicado = @criterio_id,
                           @motivo_suspension = 'Acumulación de ' + CAST(@acumuladas AS VARCHAR(3)) + ' amarillas';
            END;
        END;

        -- 3) La suspensión, sobre los próximos partidos programados de su selección.
        IF @partidos > 0
        BEGIN
            INSERT INTO evento.suspension (criterio_id, tarjeta_id, partido_afectado_id, motivo)
            SELECT @criterio_aplicado, @tarjeta_id, x.partido_id, @motivo_suspension
            FROM (SELECT TOP (@partidos) p.partido_id
                  FROM torneo.partido p
                  WHERE @seleccion_id IN (p.seleccion_local_id, p.seleccion_visitante_id)
                    AND p.fecha_hora_utc > @fecha_utc AND p.estado = 'programado'
                    AND NOT EXISTS (SELECT 1 FROM evento.suspension s
                                    JOIN evento.tarjeta t ON t.tarjeta_id = s.tarjeta_id
                                    WHERE t.persona_id = @persona_id AND s.partido_afectado_id = p.partido_id)
                  ORDER BY p.fecha_hora_utc) x;

            SET @suspensiones_generadas = @@ROWCOUNT;

            IF @suspensiones_generadas < @partidos
            BEGIN
                INSERT INTO evento.suspension (criterio_id, tarjeta_id, partido_afectado_id, motivo)
                VALUES (@criterio_aplicado, @tarjeta_id, NULL,
                        LEFT(@motivo_suspension + ' (partido a definir: aún no programado)', 150));
                SET @suspensiones_generadas += 1;
            END;
        END;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

-- ==========================
-- III.5 DESIGNACIÓN ARBITRAL
-- ==========================

/* Designa la terna completa de un partido (principal, dos asistentes, cuarto y VAR): los
 cinco o ninguno. Bloquea el conflicto de nacionalidad y devuelve en @advertencia (y por
 PRINT) los casos que desde dieciseisavos sólo ameritan aviso. */

CREATE OR ALTER PROCEDURE arbitraje.designar_arbitros
    @partido_id     INT,
    @principal_id   INT,
    @asistente_1_id INT,
    @asistente_2_id INT,
    @cuarto_id      INT,
    @var_id         INT,
    @advertencia    VARCHAR(1000) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10), @lista VARCHAR(600),
            @estado VARCHAR(10), @fase VARCHAR(13), @fecha_utc DATETIMEOFFSET,
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);
    DECLARE @terna TABLE (rol VARCHAR(11) NOT NULL, arbitro_id INT NULL);

    SET @advertencia = NULL;

    INSERT INTO @terna (rol, arbitro_id)
    VALUES ('principal', @principal_id), ('asistente_1', @asistente_1_id), ('asistente_2', @asistente_2_id),
           ('cuarto', @cuarto_id), ('var', @var_id);

    SELECT @estado = estado, @fase = fase, @fecha_utc = fecha_hora_utc
    FROM torneo.partido WHERE partido_id = @partido_id;

    IF @estado IS NULL
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @estado = 'finalizado'
        SET @errores += '- El partido ya está finalizado.' + @nl;
    IF EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral WHERE partido_id = @partido_id)
        SET @errores += '- El partido ya tiene árbitros designados (modificarlos con el ABM de designación).' + @nl;

    SELECT @lista = STRING_AGG(rol, ', ') FROM @terna WHERE arbitro_id IS NULL;
    IF @lista IS NOT NULL
        SET @errores += '- La terna debe estar completa; falta: ' + @lista + '.' + @nl;

    SELECT @lista = STRING_AGG(t.rol + ' (id ' + CAST(t.arbitro_id AS VARCHAR(12)) + ')', ', ')
    FROM @terna t
    WHERE t.arbitro_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM arbitraje.arbitro a WHERE a.arbitro_id = t.arbitro_id);
    IF @lista IS NOT NULL
        SET @errores += '- Árbitros inexistentes: ' + @lista + '.' + @nl;

    SELECT @lista = STRING_AGG(a.nombre + ' ' + a.apellido, ', ')
    FROM (SELECT arbitro_id FROM @terna WHERE arbitro_id IS NOT NULL
          GROUP BY arbitro_id HAVING COUNT(*) > 1) d
    JOIN arbitraje.arbitro a ON a.arbitro_id = d.arbitro_id;
    IF @lista IS NOT NULL
        SET @errores += '- Un árbitro no puede ocupar más de un rol en el partido: ' + @lista + '.' + @nl;

    -- Conflicto de nacionalidad (bloqueo).
    SELECT @lista = STRING_AGG(a.nombre + ' ' + a.apellido + ' (' + t.rol + ', ' + ps.nombre + ')', ', ')
    FROM @terna t
    JOIN arbitraje.arbitro a ON a.arbitro_id = t.arbitro_id
    JOIN torneo.pais ps      ON ps.pais_id = a.pais_id
    WHERE EXISTS (SELECT 1 FROM torneo.partido p
                  JOIN torneo.seleccion s ON s.seleccion_id IN (p.seleccion_local_id, p.seleccion_visitante_id)
                  WHERE p.partido_id = @partido_id AND s.pais_id = a.pais_id);
    IF @lista IS NOT NULL
        SET @errores += '- Conflicto de nacionalidad con las selecciones del partido: ' + LEFT(@lista, 400) + '.' + @nl;

    SELECT @lista = STRING_AGG(a.nombre + ' ' + a.apellido, ', ')
    FROM (SELECT DISTINCT arbitro_id FROM @terna WHERE arbitro_id IS NOT NULL) t
    JOIN arbitraje.arbitro a ON a.arbitro_id = t.arbitro_id
    WHERE EXISTS (SELECT 1 FROM arbitraje.designacion_arbitral d
                  JOIN torneo.partido p ON p.partido_id = d.partido_id
                  WHERE d.arbitro_id = t.arbitro_id AND d.partido_id <> @partido_id
                    AND ABS(DATEDIFF(MINUTE, p.fecha_hora_utc, @fecha_utc)) < 24 * 60);
    IF @lista IS NOT NULL
        SET @errores += '- Ya están designados en otro partido a menos de 24 horas: ' + LEFT(@lista, 400) + '.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'arbitraje.designar_arbitros - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    -- Advertencia (no bloquea): desde dieciseisavos, árbitros de países cuya selección sigue en
    -- competencia (no perdió un partido de eliminación directa ya finalizado).
    IF @fase <> 'grupos'
    BEGIN
        SELECT @lista = STRING_AGG(a.nombre + ' ' + a.apellido + ' (' + ps.nombre + ')', ', ')
        FROM @terna t
        JOIN arbitraje.arbitro a ON a.arbitro_id = t.arbitro_id
        JOIN torneo.pais ps      ON ps.pais_id = a.pais_id
        JOIN torneo.seleccion s  ON s.pais_id = a.pais_id
        WHERE NOT EXISTS (
              SELECT 1 FROM torneo.partido e
              WHERE e.estado = 'finalizado' AND e.fase <> 'grupos'
                AND ((e.seleccion_local_id = s.seleccion_id
                      AND (e.goles_local < e.goles_visitante
                        OR (e.goles_local = e.goles_visitante AND e.penales_local < e.penales_visitante)))
                  OR (e.seleccion_visitante_id = s.seleccion_id
                      AND (e.goles_visitante < e.goles_local
                        OR (e.goles_local = e.goles_visitante AND e.penales_visitante < e.penales_local)))));
        IF @lista IS NOT NULL
            SET @advertencia = 'ADVERTENCIA: árbitros de países con selección en competencia, que pueden cruzarse con las de este partido: '
                             + LEFT(@lista, 400) + '.';
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        INSERT INTO arbitraje.designacion_arbitral (partido_id, arbitro_id, rol)
        SELECT @partido_id, arbitro_id, rol FROM @terna;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    IF @advertencia IS NOT NULL PRINT @advertencia;
END;
GO

-- =================================================================
-- III.6 PUBLICIDAD: ASIGNACIÓN DE LOS CUATRO ESPACIOS Y FACTURACIÓN
-- =================================================================

/* Propone y registra las 4 piezas de un partido. Son candidatas las piezas de campañas
 vigentes en la fecha del partido. Criterio de priorización definido por el grupo, en orden:
   1) es_pais_seleccion: el mercado de la pieza es el país de una de las dos selecciones.
   2) es_mayor_pbi: el mercado es el de mayor PBI per cápita entre los países de interés
      de su campaña (el mercado de mayor poder adquisitivo de ese anunciante).
   3) en_prime_time: la hora del partido, llevada al huso del mercado, cae dentro de la
      franja [prime_time_hora_desde, prime_time_hora_hasta) de torneo.parametro.
   Desempate: mayor PBI per cápita del mercado, mayor tarifa, menor pieza_id.

 Para repartir la pauta entra a lo sumo una pieza por campaña (la mejor ubicada).
 orden_prioridad guarda el criterio que ubicó a la pieza: 1 país de selección, 2 poder
 adquisitivo, 3 prime time, 4 sólo desempate por tarifa.
 Siempre deja registrados los 4 espacios; si no alcanzan las candidatas, los sobrantes
 quedan sin pieza y se avisa por PRINT. Con @mostrar_detalle = 1 devuelve el ranking. */

CREATE OR ALTER PROCEDURE publicidad.asignar_espacios_partido
    @partido_id      INT,
    @reemplazar      BIT = 0,                           -- 1 = descarta la asignación previa no facturada
    @mostrar_detalle BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @estado VARCHAR(10), @fecha_utc DATETIMEOFFSET, @hora_utc INT, @fecha DATE,
            @pais_local INT, @pais_visitante INT, @pt_desde INT, @pt_hasta INT, @asignadas INT,
            @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);
    DECLARE @candidatas TABLE (
        pieza_id           INT PRIMARY KEY,
        campania_id        INT NOT NULL,
        anunciante         VARCHAR(100) NOT NULL,
        campania           VARCHAR(100) NOT NULL,
        mercado            VARCHAR(80) NOT NULL,
        es_pais_seleccion  BIT NOT NULL,
        es_mayor_pbi       BIT NOT NULL,
        en_prime_time      BIT NOT NULL,
        hora_local_mercado INT NOT NULL,
        pbi_per_capita     NUMERIC(12,2) NULL,
        costo_tarifa       NUMERIC(12,2) NOT NULL,
        puesto_en_campania INT NULL,
        puesto             INT NULL
    );

    SELECT @estado = p.estado, @fecha_utc = p.fecha_hora_utc,
           @hora_utc = DATEPART(HOUR, SWITCHOFFSET(p.fecha_hora_utc, '+00:00')),
           @fecha = CAST(p.fecha_hora_utc AS DATE),
           @pais_local = sl.pais_id, @pais_visitante = sv.pais_id
    FROM torneo.partido p
    JOIN torneo.seleccion sl ON sl.seleccion_id = p.seleccion_local_id
    JOIN torneo.seleccion sv ON sv.seleccion_id = p.seleccion_visitante_id
    WHERE p.partido_id = @partido_id;

    SELECT @pt_desde = valor FROM torneo.parametro WHERE clave = 'prime_time_hora_desde';
    SELECT @pt_hasta = valor FROM torneo.parametro WHERE clave = 'prime_time_hora_hasta';

    IF @estado IS NULL
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    IF @estado = 'finalizado'
        SET @errores += '- El partido ya está finalizado: la pauta exhibida no se reasigna.' + @nl;
    IF @pt_desde IS NULL OR @pt_hasta IS NULL
        SET @errores += '- Faltan configurar los parámetros prime_time_hora_desde / prime_time_hora_hasta.' + @nl;
    IF EXISTS (SELECT 1 FROM publicidad.espacio_publicitario WHERE partido_id = @partido_id AND facturado = 1)
        SET @errores += '- El partido ya tiene espacios facturados.' + @nl;
    ELSE IF ISNULL(@reemplazar, 0) = 0
         AND EXISTS (SELECT 1 FROM publicidad.espacio_publicitario WHERE partido_id = @partido_id)
        SET @errores += '- El partido ya tiene espacios asignados (usar @reemplazar = 1 para recalcular).' + @nl;

    IF @errores = ''
    BEGIN
        INSERT INTO @candidatas (pieza_id, campania_id, anunciante, campania, mercado, es_pais_seleccion,
                                 es_mayor_pbi, en_prime_time, hora_local_mercado, pbi_per_capita, costo_tarifa)
        SELECT pz.pieza_id, c.campania_id, a.nombre, c.nombre, m.nombre,
               IIF(m.pais_id IN (@pais_local, @pais_visitante), 1, 0),
               IIF(m.pbi_per_capita IS NOT NULL
                   AND m.pbi_per_capita = (SELECT MAX(pi.pbi_per_capita)
                                           FROM publicidad.campania_pais_interes cpi
                                           JOIN torneo.pais pi ON pi.pais_id = cpi.pais_id
                                           WHERE cpi.campania_id = c.campania_id
                                             AND pi.pbi_per_capita IS NOT NULL), 1, 0),
               IIF(h.hora_local >= @pt_desde AND h.hora_local < @pt_hasta, 1, 0),
               h.hora_local, m.pbi_per_capita, pz.costo_tarifa
        FROM publicidad.pieza_publicitaria pz
        JOIN publicidad.campania c   ON c.campania_id = pz.campania_id
        JOIN publicidad.anunciante a ON a.anunciante_id = c.anunciante_id
        JOIN torneo.pais m           ON m.pais_id = pz.pais_mercado_id
        CROSS APPLY (SELECT ((@hora_utc + CAST(SUBSTRING(m.huso_horario, 4, 3) AS INT)) % 24 + 24) % 24
                    ) AS h (hora_local)
        WHERE @fecha BETWEEN c.fecha_inicio AND c.fecha_fin;

        IF NOT EXISTS (SELECT 1 FROM @candidatas)
            SET @errores += '- No hay piezas de campañas vigentes en la fecha del partido.' + @nl;
    END;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.asignar_espacios_partido - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    -- Mejor pieza de cada campaña, y ranking general entre esas.
    WITH r AS (
        SELECT puesto_en_campania,
               ROW_NUMBER() OVER (PARTITION BY campania_id
                                  ORDER BY es_pais_seleccion DESC, es_mayor_pbi DESC, en_prime_time DESC,
                                           ISNULL(pbi_per_capita, -1) DESC, costo_tarifa DESC, pieza_id) AS rn
        FROM @candidatas
    )
    UPDATE r SET puesto_en_campania = rn;

    WITH r AS (
        SELECT puesto,
               ROW_NUMBER() OVER (ORDER BY es_pais_seleccion DESC, es_mayor_pbi DESC, en_prime_time DESC,
                                           ISNULL(pbi_per_capita, -1) DESC, costo_tarifa DESC, pieza_id) AS rn
        FROM @candidatas
        WHERE puesto_en_campania = 1
    )
    UPDATE r SET puesto = rn;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        DELETE FROM publicidad.espacio_publicitario WHERE partido_id = @partido_id;

        INSERT INTO publicidad.espacio_publicitario (partido_id, numero_espacio, pieza_id, orden_prioridad)
        SELECT @partido_id, n.numero, c.pieza_id,
               CASE WHEN c.pieza_id IS NULL        THEN NULL
                    WHEN c.es_pais_seleccion = 1   THEN 1
                    WHEN c.es_mayor_pbi = 1        THEN 2
                    WHEN c.en_prime_time = 1       THEN 3
                    ELSE 4 END
        FROM (VALUES (1), (2), (3), (4)) AS n (numero)
        LEFT JOIN @candidatas c ON c.puesto = n.numero;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    SELECT @asignadas = COUNT(*) FROM @candidatas WHERE puesto <= 4;
    IF @asignadas < 4
        PRINT 'ADVERTENCIA: sólo hay ' + CAST(@asignadas AS VARCHAR(2))
            + ' campañas candidatas; los espacios restantes quedan sin pieza asignada.';

    IF @mostrar_detalle = 1
        SELECT IIF(puesto <= 4, 'espacio ' + CAST(puesto AS VARCHAR(2)), 'no asignada') AS resultado,
               puesto, anunciante, campania, mercado, es_pais_seleccion, es_mayor_pbi, en_prime_time,
               hora_local_mercado, pbi_per_capita, costo_tarifa, pieza_id
        FROM @candidatas
        ORDER BY IIF(puesto IS NULL, 1, 0), puesto, campania_id, puesto_en_campania;
END;
GO

/* Factura la pauta exhibida de un partido finalizado: cada espacio con pieza queda facturado
 por la tarifa de la pieza vigente en ese momento (monto_facturado guarda el importe
 histórico, aunque la tarifa cambie después). */

CREATE OR ALTER PROCEDURE publicidad.facturar_espacios_partido
    @partido_id INT,
    @total      NUMERIC(14,2) = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE @errores VARCHAR(2000) = '', @nl CHAR(2) = CHAR(13) + CHAR(10),
            @estado VARCHAR(10), @fecha_utc DATETIMEOFFSET, @tran_propia BIT = IIF(@@TRANCOUNT = 0, 1, 0);

    SELECT @estado = estado, @fecha_utc = fecha_hora_utc FROM torneo.partido WHERE partido_id = @partido_id;

    IF @estado IS NULL
        SET @errores += '- No existe el partido con id ' + ISNULL(CAST(@partido_id AS VARCHAR(12)), '(nulo)') + '.' + @nl;
    ELSE IF @estado <> 'finalizado'
        SET @errores += '- Sólo se factura la pauta de partidos finalizados (el partido está ' + @estado + ').' + @nl;
    IF NOT EXISTS (SELECT 1 FROM publicidad.espacio_publicitario
                   WHERE partido_id = @partido_id AND pieza_id IS NOT NULL)
        SET @errores += '- El partido no tiene piezas asignadas a sus espacios.' + @nl;
    ELSE IF NOT EXISTS (SELECT 1 FROM publicidad.espacio_publicitario
                        WHERE partido_id = @partido_id AND pieza_id IS NOT NULL AND facturado = 0)
        SET @errores += '- Todos los espacios del partido ya fueron facturados.' + @nl;

    IF @errores <> ''
    BEGIN
        SET @errores = 'publicidad.facturar_espacios_partido - operación rechazada:' + @nl + @errores;
        THROW 50002, @errores, 1;
    END;

    BEGIN TRY
        IF @tran_propia = 1 BEGIN TRANSACTION;

        UPDATE e
        SET facturado = 1,
            monto_facturado = pz.costo_tarifa,
            fecha_exhibicion = ISNULL(e.fecha_exhibicion, @fecha_utc)
        FROM publicidad.espacio_publicitario e
        JOIN publicidad.pieza_publicitaria pz ON pz.pieza_id = e.pieza_id
        WHERE e.partido_id = @partido_id AND e.facturado = 0;

        IF @tran_propia = 1 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @tran_propia = 1 AND @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    SELECT @total = SUM(monto_facturado)
    FROM publicidad.espacio_publicitario WHERE partido_id = @partido_id AND facturado = 1;
END;
GO

-- #############################################################
-- ##  IV. CONFIGURACIÓN INICIAL (parámetros del reglamento)  ##
-- #############################################################

/* Valores que la lógica de negocio necesita para funcionar. Se cargan con su SP de ABM y
 sólo si faltan, así el script puede reejecutarse sin pisar valores ya ajustados.
 La "Importación de datos externos" que lista el enunciado corresponde a la Entrega 6. */

CREATE OR ALTER PROCEDURE torneo.parametro_cargar_defaults
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO torneo.parametro (clave, valor, descripcion)
    SELECT d.clave, d.valor, d.descripcion
    FROM (VALUES
        ('convocatoria_min_jugadores', 23, N'Mínimo de convocados vigentes exigido para presentar una formación'),
        ('convocatoria_max_jugadores', 26, N'Máximo de convocados vigentes por selección'),
        ('formacion_titulares',        11, N'Cantidad de titulares de una formación'),
        ('formacion_max_suplentes',    15, N'Máximo de suplentes en el banco'),
        ('cambios_max_reglamentarios',  5, N'Máximo de cambios por equipo en tiempo reglamentario'),
        ('ventanas_max_reglamentarias', 3, N'Máximo de ventanas de cambio por equipo en tiempo reglamentario'),
        ('cambios_extra_alargue',       1, N'Cambios adicionales habilitados en tiempo suplementario'),
        ('ventanas_extra_alargue',      1, N'Ventanas adicionales habilitadas en tiempo suplementario'),
        ('suspension_partidos_roja',    1, N'Partidos de suspensión por expulsión (roja directa o doble amarilla)'),
        ('prime_time_hora_desde',      19, N'Hora local de inicio del prime time (incluida)'),
        ('prime_time_hora_hasta',      23, N'Hora local de fin del prime time (excluida)')
    ) AS d (clave, valor, descripcion)
    WHERE NOT EXISTS (SELECT 1 FROM torneo.parametro p WHERE p.clave = d.clave);
END
GO

EXEC torneo.parametro_cargar_defaults;
GO