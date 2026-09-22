-- ============================================================
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
-- ============================================================

-- ============================================================
-- VALIDACIÓN DE EXISTENCIA ANTES DE CREAR/BORRAR
-- Requisito general del TP; el mismo patrón se repite más abajo con OBJECT_ID.
-- ============================================================

-- La base todavía no existe: DROP/CREATE DATABASE no pueden ejecutarse conectado a ella.

USE master;
GO

-- Elimina la base si ya existe, para poder recrearla desde cero.

IF DB_ID('mundial_2026') IS NOT NULL
BEGIN
    ALTER DATABASE mundial_2026 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE mundial_2026;
END;
GO

-- =============================================================
-- ················· CONFIGURACIÓN PARA EL DBA ·················
-- =============================================================

-- Collation CI_AI: ignora mayúsculas/minúsculas y acentos (favorece la deduplicación en
-- importaciones, ej. 'Peru' = 'Perú'). Code page 1252: soporta acentos de Europa occidental.

CREATE DATABASE mundial_2026
    COLLATE Latin1_General_CI_AI;
GO

-- Tamaño y crecimiento fijos (no porcentuales): volumen estimado ~1GB, con picos de
-- escritura concurrente en horario de partidos.

ALTER DATABASE mundial_2026
    MODIFY FILE (NAME = 'mundial_2026', SIZE = 1024MB, FILEGROWTH = 256MB);
GO

ALTER DATABASE mundial_2026
    MODIFY FILE (NAME = 'mundial_2026_log', SIZE = 512MB, FILEGROWTH = 128MB);
GO

ALTER DATABASE mundial_2026 SET RECOVERY FULL;
GO

-- =============================================================
-- ·····························································
-- =============================================================

-- A partir de aquí todo corre en el contexto de la propia base, no de master.

USE mundial_2026;
GO

-- ============================================================
-- ESQUEMAS POR MÓDULO
-- ============================================================

IF SCHEMA_ID('torneo')     IS NULL EXEC('CREATE SCHEMA torneo');      -- A: sedes y partidos
GO
IF SCHEMA_ID('plantel')    IS NULL EXEC('CREATE SCHEMA plantel');     -- B y C: convocatoria y formaciones
GO
IF SCHEMA_ID('evento')     IS NULL EXEC('CREATE SCHEMA evento');      -- D, E y F: cambios, goles y tarjetas
GO
IF SCHEMA_ID('arbitraje')  IS NULL EXEC('CREATE SCHEMA arbitraje');   -- G: árbitros
GO
IF SCHEMA_ID('publicidad') IS NULL EXEC('CREATE SCHEMA publicidad');  -- H: publicidad
GO

-- ============================================================
-- ELIMINACIÓN DE TABLAS EXISTENTES (orden inverso a las dependencias)
-- ============================================================

IF OBJECT_ID('publicidad.espacio_publicitario', 'U')  IS NOT NULL DROP TABLE publicidad.espacio_publicitario;
IF OBJECT_ID('publicidad.pieza_publicitaria', 'U')    IS NOT NULL DROP TABLE publicidad.pieza_publicitaria;
IF OBJECT_ID('publicidad.campania_pais_interes', 'U') IS NOT NULL DROP TABLE publicidad.campania_pais_interes;
IF OBJECT_ID('publicidad.campania', 'U')              IS NOT NULL DROP TABLE publicidad.campania;
IF OBJECT_ID('publicidad.anunciante', 'U')            IS NOT NULL DROP TABLE publicidad.anunciante;

IF OBJECT_ID('arbitraje.informe_arbitral', 'U')       IS NOT NULL DROP TABLE arbitraje.informe_arbitral;
IF OBJECT_ID('arbitraje.designacion_arbitral', 'U')   IS NOT NULL DROP TABLE arbitraje.designacion_arbitral;
IF OBJECT_ID('arbitraje.arbitro_idioma', 'U')         IS NOT NULL DROP TABLE arbitraje.arbitro_idioma;
IF OBJECT_ID('arbitraje.arbitro', 'U')                IS NOT NULL DROP TABLE arbitraje.arbitro;

IF OBJECT_ID('evento.suspension', 'U')                IS NOT NULL DROP TABLE evento.suspension;
IF OBJECT_ID('evento.criterio_suspension', 'U')       IS NOT NULL DROP TABLE evento.criterio_suspension;
IF OBJECT_ID('evento.tarjeta', 'U')                   IS NOT NULL DROP TABLE evento.tarjeta;
IF OBJECT_ID('evento.gol', 'U')                       IS NOT NULL DROP TABLE evento.gol;
IF OBJECT_ID('evento.sustitucion', 'U')               IS NOT NULL DROP TABLE evento.sustitucion;

IF OBJECT_ID('plantel.formacion_jugador', 'U')        IS NOT NULL DROP TABLE plantel.formacion_jugador;
IF OBJECT_ID('plantel.formacion', 'U')                IS NOT NULL DROP TABLE plantel.formacion;
IF OBJECT_ID('plantel.convocatoria', 'U')             IS NOT NULL DROP TABLE plantel.convocatoria;
IF OBJECT_ID('plantel.cuerpo_tecnico', 'U')           IS NOT NULL DROP TABLE plantel.cuerpo_tecnico;
IF OBJECT_ID('plantel.jugador', 'U')                  IS NOT NULL DROP TABLE plantel.jugador;

IF OBJECT_ID('torneo.partido', 'U')                   IS NOT NULL DROP TABLE torneo.partido;
IF OBJECT_ID('torneo.seleccion', 'U')                 IS NOT NULL DROP TABLE torneo.seleccion;
IF OBJECT_ID('torneo.sede', 'U')                      IS NOT NULL DROP TABLE torneo.sede;
IF OBJECT_ID('torneo.confederacion', 'U')             IS NOT NULL DROP TABLE torneo.confederacion;
IF OBJECT_ID('torneo.pais', 'U')                      IS NOT NULL DROP TABLE torneo.pais;
GO

-- ============================================================
-- 0. CATÁLOGOS BASE
--
-- Texto en VARCHAR, sin NVARCHAR: las fuentes del proyecto (fifa.com, Wikipedia, datasets
-- de GitHub/Kaggle) publican los nombres ya romanizados en alfabeto latino.
--
-- Nota general de índices: PRIMARY KEY crea un índice único clusterizado por defecto y
-- UNIQUE uno único no clusterizado; los CREATE INDEX explícitos son adicionales, sobre
-- columnas de búsqueda/filtro frecuente que esas claves no cubren.
-- ============================================================

-- huso_horario: offset fijo UTC ('UTC-03'), no nombre de zona; válido porque el torneo
-- transcurre en una ventana fija de 5 semanas. Asume offset de hora entera.

CREATE TABLE torneo.pais (
    pais_id        INT IDENTITY(1, 1),
    codigo_iso     CHAR(3) NOT NULL,                -- ej: ARG, BRA
    nombre         VARCHAR(80) NOT NULL,             -- nombre común, no el oficial largo
    huso_horario   CHAR(6) NOT NULL,                -- ej: 'UTC-03'
    pbi_per_capita NUMERIC(12,2),                    -- usado para priorizar mercados publicitarios

    CONSTRAINT pk_pais PRIMARY KEY (pais_id),
    CONSTRAINT uq_pais_codigo_iso UNIQUE (codigo_iso),
    CONSTRAINT chk_pais_huso_horario CHECK (huso_horario LIKE 'UTC[-+][0-9][0-9]')
);

CREATE TABLE torneo.confederacion (
    confederacion_id INT IDENTITY(1, 1),
    nombre           VARCHAR(8) NOT NULL,              -- las 6 confederaciones FIFA (dominio fijo)

    CONSTRAINT pk_confederacion PRIMARY KEY (confederacion_id),
    CONSTRAINT uq_confederacion_nombre UNIQUE (nombre),
    CONSTRAINT chk_confederacion_nombre CHECK (nombre IN
        ('AFC', 'CAF', 'CONCACAF', 'CONMEBOL', 'OFC', 'UEFA'))
);
GO

-- ============================================================
-- A. GESTIÓN DE SEDES Y PARTIDOS
-- ============================================================

CREATE TABLE torneo.sede (
    sede_id        INT IDENTITY(1, 1),
    nombre         VARCHAR(80) NOT NULL,             -- nombre del estadio
    ciudad         VARCHAR(80) NOT NULL,
    pais_id        INT NOT NULL,
    capacidad      INT NOT NULL,
    huso_horario   CHAR(6) NOT NULL,                 -- puede diferir del huso del país

    CONSTRAINT pk_sede PRIMARY KEY (sede_id),
    CONSTRAINT fk_sede_pais FOREIGN KEY (pais_id)
        REFERENCES torneo.pais (pais_id),
    CONSTRAINT chk_sede_capacidad CHECK (capacidad > 0),
    CONSTRAINT chk_sede_huso_horario CHECK (huso_horario LIKE 'UTC[-+][0-9][0-9]')
);

CREATE TABLE torneo.seleccion (
    seleccion_id     INT IDENTITY(1, 1),
    pais_id          INT NOT NULL,
    confederacion_id INT NOT NULL,
    grupo            CHAR(1) NOT NULL,                 -- 'A', 'B', 'C', ...

    CONSTRAINT pk_seleccion PRIMARY KEY (seleccion_id),
    CONSTRAINT uq_seleccion_pais UNIQUE (pais_id),      -- un país participa una sola vez
    CONSTRAINT fk_seleccion_pais FOREIGN KEY (pais_id)
        REFERENCES torneo.pais (pais_id),
    CONSTRAINT fk_seleccion_confederacion FOREIGN KEY (confederacion_id)
        REFERENCES torneo.confederacion (confederacion_id)
);

CREATE TABLE torneo.partido (
    partido_id             INT IDENTITY(1, 1),
    sede_id                INT NOT NULL,
    fecha_hora_local       DATETIMEOFFSET NOT NULL,
    fecha_hora_utc         DATETIMEOFFSET NOT NULL,
    fase                   VARCHAR(13) NOT NULL,
    seleccion_local_id     INT NOT NULL,
    seleccion_visitante_id INT NOT NULL,
    estado                 VARCHAR(10) NOT NULL DEFAULT 'programado',
    goles_local            INT,
    goles_visitante        INT,
    penales_local          INT,                        -- solo si hubo definición por penales
    penales_visitante      INT,
    asistencia_publico     INT,

    CONSTRAINT pk_partido PRIMARY KEY (partido_id),
    CONSTRAINT uq_partido_cruce UNIQUE (fase, seleccion_local_id, seleccion_visitante_id),
    CONSTRAINT fk_partido_sede FOREIGN KEY (sede_id)
        REFERENCES torneo.sede (sede_id),
    CONSTRAINT fk_partido_seleccion_local FOREIGN KEY (seleccion_local_id)
        REFERENCES torneo.seleccion (seleccion_id),
    CONSTRAINT fk_partido_seleccion_visitante FOREIGN KEY (seleccion_visitante_id)
        REFERENCES torneo.seleccion (seleccion_id),
    CONSTRAINT chk_partido_fase CHECK (fase IN
        ('grupos', 'dieciseisavos', 'octavos', 'cuartos', 'semifinal', 'tercer_puesto', 'final')),
    CONSTRAINT chk_partido_estado CHECK (estado IN ('programado', 'finalizado', 'suspendido')),
    CONSTRAINT chk_partido_rivales CHECK (seleccion_local_id <> seleccion_visitante_id),
    CONSTRAINT chk_partido_goles CHECK (goles_local >= 0 AND goles_visitante >= 0),
    CONSTRAINT chk_partido_penales CHECK (penales_local >= 0 AND penales_visitante >= 0),
    CONSTRAINT chk_partido_asistencia CHECK (asistencia_publico >= 0)
);

-- Índices no clusterizados de un solo campo: el módulo A exige poder filtrar el fixture
-- por sede, fase o fecha (idx_partido_fecha también sirve de base al cálculo de prime time).

CREATE INDEX idx_partido_fase  ON torneo.partido (fase);
CREATE INDEX idx_partido_sede  ON torneo.partido (sede_id);
CREATE INDEX idx_partido_fecha ON torneo.partido (fecha_hora_utc);
GO

-- ============================================================
-- B. SELECCIONES Y CONVOCATORIA
-- ============================================================

CREATE TABLE plantel.cuerpo_tecnico (
    staff_id     INT IDENTITY(1, 1),
    seleccion_id INT NOT NULL,
    nombre       VARCHAR(100) NOT NULL,
    apellido     VARCHAR(100) NOT NULL,
    rol          VARCHAR(17) NOT NULL,

    CONSTRAINT pk_cuerpo_tecnico PRIMARY KEY (staff_id),
    CONSTRAINT fk_cuerpo_tecnico_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES torneo.seleccion (seleccion_id),
    CONSTRAINT uq_cuerpo_tecnico UNIQUE (seleccion_id, nombre, apellido, rol),
    CONSTRAINT chk_cuerpo_tecnico_rol CHECK (rol IN
        ('director_tecnico', 'ayudante_tecnico', 'preparador_fisico', 'otro'))
);

CREATE TABLE plantel.jugador (
    jugador_id        INT IDENTITY(1, 1),
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    fecha_nacimiento  DATE NOT NULL,
    club_origen       VARCHAR(120),
    posicion_habitual VARCHAR(13) NOT NULL,

    CONSTRAINT pk_jugador PRIMARY KEY (jugador_id),
    CONSTRAINT chk_jugador_posicion CHECK (posicion_habitual IN
        ('arquero', 'defensor', 'mediocampista', 'delantero'))
);

-- Convocatoria: relación jugador-selección, historizando altas/bajas de última hora.

CREATE TABLE plantel.convocatoria (
    convocatoria_id INT IDENTITY(1, 1),
    seleccion_id    INT NOT NULL,
    jugador_id      INT NOT NULL,
    dorsal          INT NOT NULL,
    fecha_alta      DATE NOT NULL,
    motivo_alta     VARCHAR(150),
    fecha_baja      DATE,                              -- NULL si sigue activo
    motivo_baja     VARCHAR(150),

    CONSTRAINT pk_convocatoria PRIMARY KEY (convocatoria_id),
    CONSTRAINT fk_convocatoria_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES torneo.seleccion (seleccion_id),
    CONSTRAINT fk_convocatoria_jugador FOREIGN KEY (jugador_id)
        REFERENCES plantel.jugador (jugador_id),
    CONSTRAINT chk_convocatoria_dorsal CHECK (dorsal BETWEEN 1 AND 99),
    CONSTRAINT chk_convocatoria_fechas CHECK (fecha_baja IS NULL OR fecha_baja >= fecha_alta),
    CONSTRAINT chk_convocatoria_baja CHECK
        ((fecha_baja IS NULL AND motivo_baja IS NULL) OR fecha_baja IS NOT NULL)
);

-- Índices únicos filtrados (WHERE fecha_baja IS NULL): garantizan dorsal y jugador únicos
-- sólo dentro de la convocatoria vigente, permitiendo reutilizarlos tras una baja.

CREATE UNIQUE INDEX uq_convocatoria_dorsal_vigente
    ON plantel.convocatoria (seleccion_id, dorsal)
    WHERE fecha_baja IS NULL;

CREATE UNIQUE INDEX uq_convocatoria_jugador_vigente
    ON plantel.convocatoria (seleccion_id, jugador_id)
    WHERE fecha_baja IS NULL;

-- Índice no clusterizado: acelera listar la convocatoria de una selección, la consulta
-- más repetida sobre esta tabla (plantillas, reportes, validaciones de cupo).

CREATE INDEX idx_convocatoria_seleccion ON plantel.convocatoria (seleccion_id);
GO

-- ============================================================
-- C. FORMACIONES Y ALINEACIONES
-- ============================================================

CREATE TABLE plantel.formacion (
    formacion_id    INT IDENTITY(1, 1),
    partido_id      INT NOT NULL,
    seleccion_id    INT NOT NULL,
    esquema_tactico VARCHAR(9) NOT NULL,               -- ej: '4-3-3'; máximo '4-1-2-1-2' = 9

    CONSTRAINT pk_formacion PRIMARY KEY (formacion_id),
    CONSTRAINT uq_formacion UNIQUE (partido_id, seleccion_id),
    CONSTRAINT fk_formacion_partido FOREIGN KEY (partido_id)
        REFERENCES torneo.partido (partido_id),
    CONSTRAINT fk_formacion_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES torneo.seleccion (seleccion_id)
);

-- Titulares y banco de suplentes de esa formación.

CREATE TABLE plantel.formacion_jugador (
    formacion_id INT NOT NULL,
    jugador_id   INT NOT NULL,
    dorsal       INT NOT NULL,
    posicion     VARCHAR(30) NOT NULL,                 -- posición táctica en ese partido puntual
    titular      BIT NOT NULL,                         -- 1 = titular, 0 = suplente en el banco

    CONSTRAINT pk_formacion_jugador PRIMARY KEY (formacion_id, jugador_id),
    CONSTRAINT fk_formacion_jugador_formacion FOREIGN KEY (formacion_id)
        REFERENCES plantel.formacion (formacion_id),
    CONSTRAINT fk_formacion_jugador_jugador FOREIGN KEY (jugador_id)
        REFERENCES plantel.jugador (jugador_id),
    CONSTRAINT chk_formacion_jugador_dorsal CHECK (dorsal BETWEEN 1 AND 99)
);
GO

-- ============================================================
-- D. CAMBIOS (SUSTITUCIONES)
-- ============================================================

CREATE TABLE evento.sustitucion (
    sustitucion_id   INT IDENTITY(1, 1),
    partido_id       INT NOT NULL,
    seleccion_id     INT NOT NULL,
    jugador_sale_id  INT NOT NULL,
    jugador_entra_id INT NOT NULL,
    minuto           INT NOT NULL,                     -- sin cota superior: el descuento puede extenderlo
    periodo          VARCHAR(9) NOT NULL,
    numero_ventana   INT NOT NULL,                     -- para validar máximo de ventanas permitidas
    motivo           VARCHAR(10) NOT NULL,

    CONSTRAINT pk_sustitucion PRIMARY KEY (sustitucion_id),
    CONSTRAINT fk_sustitucion_partido FOREIGN KEY (partido_id)
        REFERENCES torneo.partido (partido_id),
    CONSTRAINT fk_sustitucion_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES torneo.seleccion (seleccion_id),
    CONSTRAINT fk_sustitucion_jugador_sale FOREIGN KEY (jugador_sale_id)
        REFERENCES plantel.jugador (jugador_id),
    CONSTRAINT fk_sustitucion_jugador_entra FOREIGN KEY (jugador_entra_id)
        REFERENCES plantel.jugador (jugador_id),
    CONSTRAINT chk_sustitucion_jugadores CHECK (jugador_sale_id <> jugador_entra_id),
    CONSTRAINT chk_sustitucion_minuto CHECK (minuto >= 0),
    CONSTRAINT chk_sustitucion_ventana CHECK (numero_ventana > 0),
    CONSTRAINT chk_sustitucion_periodo CHECK (periodo IN ('PT', 'ST', 'alargue_1', 'alargue_2')),
    CONSTRAINT chk_sustitucion_motivo CHECK (motivo IN ('tactico', 'lesion', 'precaucion'))
);

-- Índice no clusterizado compuesto: soporta tanto reconstruir el XI en cancha en un
-- minuto dado como contar cambios/ventanas usados por partido y selección.

CREATE INDEX idx_sustitucion_partido ON evento.sustitucion (partido_id, seleccion_id);
GO

-- ============================================================
-- E. GOLES Y EVENTOS DE PARTIDO
-- ============================================================

CREATE TABLE evento.gol (
    gol_id                INT IDENTITY(1, 1),
    partido_id            INT NOT NULL,
    seleccion_id          INT NOT NULL,  -- a favor de qué selección cuenta
    jugador_id            INT NOT NULL,      -- autor (si es en contra, va el autor real)
    asistencia_jugador_id INT,
    minuto                INT NOT NULL,
    tipo_gol              VARCHAR(10) NOT NULL,
    periodo               VARCHAR(17) NOT NULL,         -- incluye 'penales'; se excluye del ranking de goleadores

    CONSTRAINT pk_gol PRIMARY KEY (gol_id),
    CONSTRAINT fk_gol_partido FOREIGN KEY (partido_id)
        REFERENCES torneo.partido (partido_id),
    CONSTRAINT fk_gol_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES torneo.seleccion (seleccion_id),
    CONSTRAINT fk_gol_jugador FOREIGN KEY (jugador_id)
        REFERENCES plantel.jugador (jugador_id),
    CONSTRAINT fk_gol_asistencia FOREIGN KEY (asistencia_jugador_id)
        REFERENCES plantel.jugador (jugador_id),
    CONSTRAINT chk_gol_minuto CHECK (minuto >= 0),
    CONSTRAINT chk_gol_asistencia CHECK
        (asistencia_jugador_id IS NULL OR asistencia_jugador_id <> jugador_id),
    CONSTRAINT chk_gol_tipo CHECK (tipo_gol IN
        ('jugada', 'penal', 'tiro_libre', 'en_contra', 'cabezazo', 'otro')),
    CONSTRAINT chk_gol_periodo CHECK (periodo IN
        ('PT', 'ST', 'adicional_PT', 'adicional_ST',
         'alargue_1', 'alargue_2', 'adicional_alargue', 'penales'))
);

-- Índices no clusterizados de un solo campo: base de los reportes de goleadores,
-- por partido (resultado/detalle) y por jugador (ranking del torneo).

CREATE INDEX idx_gol_partido ON evento.gol (partido_id);
CREATE INDEX idx_gol_jugador ON evento.gol (jugador_id);
GO

-- ============================================================
-- F. AMONESTACIONES Y EXPULSIONES
-- ============================================================

CREATE TABLE evento.tarjeta (
    tarjeta_id     INT IDENTITY(1, 1),
    partido_id     INT NOT NULL,
    seleccion_id   INT NOT NULL,
    jugador_id     INT NOT NULL,
    minuto         INT NOT NULL,
    tipo           VARCHAR(8) NOT NULL,
    motivo         VARCHAR(150),
    tipo_expulsion VARCHAR(14),

    CONSTRAINT pk_tarjeta PRIMARY KEY (tarjeta_id),
    CONSTRAINT fk_tarjeta_partido FOREIGN KEY (partido_id)
        REFERENCES torneo.partido (partido_id),
    CONSTRAINT fk_tarjeta_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES torneo.seleccion (seleccion_id),
    CONSTRAINT fk_tarjeta_jugador FOREIGN KEY (jugador_id)
        REFERENCES plantel.jugador (jugador_id),
    CONSTRAINT chk_tarjeta_minuto CHECK (minuto >= 0),
    CONSTRAINT chk_tarjeta_tipo CHECK (tipo IN ('amarilla', 'roja')),
    CONSTRAINT chk_tarjeta_tipo_expulsion CHECK
        ((tipo = 'amarilla' AND tipo_expulsion IS NULL) OR
         (tipo = 'roja' AND tipo_expulsion IN ('doble_amarilla', 'roja_directa')))
);

-- Índice no clusterizado: soporta el cálculo de acumulación de amarillas por jugador.

CREATE INDEX idx_tarjeta_jugador ON evento.tarjeta (jugador_id);

-- Criterios de suspensión parametrizables (ej: 2 amarillas en grupos = 1 partido de sanción).

CREATE TABLE evento.criterio_suspension (
    criterio_id         INT IDENTITY(1, 1),
    fase_aplicable      VARCHAR(13),                   -- NULL = aplica a todas las fases
    cantidad_amarillas  INT NOT NULL,
    partidos_suspension INT NOT NULL,
    activo              BIT NOT NULL DEFAULT 1,

    CONSTRAINT pk_criterio_suspension PRIMARY KEY (criterio_id),
    CONSTRAINT uq_criterio_suspension UNIQUE (fase_aplicable, cantidad_amarillas),
    CONSTRAINT chk_criterio_fase CHECK (fase_aplicable IS NULL OR fase_aplicable IN
        ('grupos', 'dieciseisavos', 'octavos', 'cuartos', 'semifinal', 'tercer_puesto', 'final')),
    CONSTRAINT chk_criterio_amarillas CHECK (cantidad_amarillas > 0),
    CONSTRAINT chk_criterio_partidos CHECK (partidos_suspension > 0)
);

-- Suspensión efectiva de un jugador, por acumulación o roja directa.

CREATE TABLE evento.suspension (
    suspension_id       INT IDENTITY(1, 1),
    jugador_id          INT NOT NULL,
    criterio_id         INT,                            -- NULL si viene de roja directa
    tarjeta_id          INT,                            -- tarjeta que dispara la sanción
    partido_afectado_id INT,                            -- próximo partido que se pierde
    motivo              VARCHAR(150) NOT NULL,
    fecha_generada      DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET(),

    CONSTRAINT pk_suspension PRIMARY KEY (suspension_id),
    CONSTRAINT fk_suspension_jugador FOREIGN KEY (jugador_id)
        REFERENCES plantel.jugador (jugador_id),
    CONSTRAINT fk_suspension_criterio FOREIGN KEY (criterio_id)
        REFERENCES evento.criterio_suspension (criterio_id),
    CONSTRAINT fk_suspension_tarjeta FOREIGN KEY (tarjeta_id)
        REFERENCES evento.tarjeta (tarjeta_id),
    CONSTRAINT fk_suspension_partido FOREIGN KEY (partido_afectado_id)
        REFERENCES torneo.partido (partido_id)
);
GO

-- ============================================================
-- G. GESTIÓN DE ÁRBITROS
-- ============================================================

CREATE TABLE arbitraje.arbitro (
    arbitro_id       INT IDENTITY(1, 1),
    nombre           VARCHAR(100) NOT NULL,
    apellido         VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE,
    pais_id          INT NOT NULL,
    categoria        VARCHAR(13) NOT NULL,

    CONSTRAINT uq_arbitro UNIQUE (nombre, apellido, pais_id),  -- clave natural para el upsert de importación
    CONSTRAINT pk_arbitro PRIMARY KEY (arbitro_id),
    CONSTRAINT fk_arbitro_pais FOREIGN KEY (pais_id)
        REFERENCES torneo.pais (pais_id),
    CONSTRAINT chk_arbitro_categoria CHECK (categoria IN ('FIFA', 'confederacion'))
);

-- Idiomas del árbitro (multivaluado -> tabla aparte).

CREATE TABLE arbitraje.arbitro_idioma (
    arbitro_id INT NOT NULL,
    idioma     VARCHAR(10) NOT NULL,

    CONSTRAINT pk_arbitro_idioma PRIMARY KEY (arbitro_id, idioma),
    CONSTRAINT fk_arbitro_idioma_arbitro FOREIGN KEY (arbitro_id)
        REFERENCES arbitraje.arbitro (arbitro_id)
);

CREATE TABLE arbitraje.designacion_arbitral (
    designacion_id INT IDENTITY(1, 1),
    partido_id     INT NOT NULL,
    arbitro_id     INT NOT NULL,
    rol            VARCHAR(11) NOT NULL,

    CONSTRAINT uq_designacion_arbitral_rol UNIQUE (partido_id, rol),
    CONSTRAINT uq_designacion_arbitral_arbitro UNIQUE (partido_id, arbitro_id),
    CONSTRAINT pk_designacion_arbitral PRIMARY KEY (designacion_id),
    CONSTRAINT fk_designacion_arbitral_partido FOREIGN KEY (partido_id)
        REFERENCES torneo.partido (partido_id),
    CONSTRAINT fk_designacion_arbitral_arbitro FOREIGN KEY (arbitro_id)
        REFERENCES arbitraje.arbitro (arbitro_id),
    CONSTRAINT chk_designacion_arbitral_rol CHECK (rol IN
        ('principal', 'asistente_1', 'asistente_2', 'cuarto', 'var'))
);

-- Conflicto de nacionalidad arbitral (bloqueo/advertencia): se valida en SP, no es un CHECK simple.

CREATE TABLE arbitraje.informe_arbitral (
    informe_id     INT IDENTITY(1, 1),
    designacion_id INT NOT NULL,
    fecha          DATETIMEOFFSET NOT NULL,
    contenido      VARCHAR(MAX) NOT NULL,
    sancion        VARCHAR(150),                        -- NULL si no hubo sanción

    CONSTRAINT pk_informe_arbitral PRIMARY KEY (informe_id),
    CONSTRAINT fk_informe_arbitral_designacion FOREIGN KEY (designacion_id)
        REFERENCES arbitraje.designacion_arbitral (designacion_id)
);
GO

-- ============================================================
-- H. GESTIÓN DE PUBLICIDAD
-- ============================================================

CREATE TABLE publicidad.anunciante (
    anunciante_id INT IDENTITY(1, 1),
    nombre        VARCHAR(100) NOT NULL,
    razon_social  VARCHAR(150),                         -- más ancho: sufijos societarios largos
    contacto      VARCHAR(100),

    CONSTRAINT pk_anunciante PRIMARY KEY (anunciante_id)
);

CREATE TABLE publicidad.campania (
    campania_id   INT IDENTITY(1, 1),
    anunciante_id INT NOT NULL,
    nombre        VARCHAR(100) NOT NULL,
    fecha_inicio  DATE NOT NULL,
    fecha_fin     DATE NOT NULL,

    CONSTRAINT chk_campania_fecha CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT uq_campania_nombre_anunciante UNIQUE (anunciante_id, nombre),
    CONSTRAINT pk_campania PRIMARY KEY (campania_id),
    CONSTRAINT fk_campania_anunciante FOREIGN KEY (anunciante_id)
        REFERENCES publicidad.anunciante (anunciante_id)
);

-- Países de interés de la campaña (multivaluado): primer criterio de priorización del módulo H.

CREATE TABLE publicidad.campania_pais_interes (
    campania_id INT NOT NULL,
    pais_id     INT NOT NULL,

    CONSTRAINT pk_campania_pais_interes PRIMARY KEY (campania_id, pais_id),
    CONSTRAINT fk_campania_pais_interes_campania FOREIGN KEY (campania_id)
        REFERENCES publicidad.campania (campania_id),
    CONSTRAINT fk_campania_pais_interes_pais FOREIGN KEY (pais_id)
        REFERENCES torneo.pais (pais_id)
);

CREATE TABLE publicidad.pieza_publicitaria (
    pieza_id        INT IDENTITY(1, 1),
    campania_id     INT NOT NULL,
    idioma          VARCHAR(10) NOT NULL,
    pais_mercado_id INT NOT NULL,
    costo_tarifa    NUMERIC(12,2) NOT NULL,

    CONSTRAINT pk_pieza_publicitaria PRIMARY KEY (pieza_id),
    CONSTRAINT fk_pieza_publicitaria_campania FOREIGN KEY (campania_id)
        REFERENCES publicidad.campania (campania_id),
    CONSTRAINT fk_pieza_publicitaria_pais FOREIGN KEY (pais_mercado_id)
        REFERENCES torneo.pais (pais_id),
    CONSTRAINT uq_pieza_publicitaria UNIQUE (campania_id, idioma, pais_mercado_id),
    CONSTRAINT chk_pieza_costo CHECK (costo_tarifa >= 0)
);

-- Asignación real de una pieza a uno de los 4 espacios de un partido (historial de facturación).

CREATE TABLE publicidad.espacio_publicitario (
    espacio_id        INT IDENTITY(1, 1),
    partido_id        INT NOT NULL,
    numero_espacio    INT NOT NULL,
    pieza_id          INT,                              -- NULL = espacio aún no asignado
    orden_prioridad   INT,                               -- criterio que lo priorizó: país / PBI / prime time
    fecha_exhibicion  DATETIMEOFFSET,
    facturado         BIT NOT NULL DEFAULT 0,
    monto_facturado   NUMERIC(12,2),

    CONSTRAINT uq_espacio_publicitario UNIQUE (partido_id, numero_espacio),
    CONSTRAINT pk_espacio_publicitario PRIMARY KEY (espacio_id),
    CONSTRAINT fk_espacio_publicitario_partido FOREIGN KEY (partido_id)
        REFERENCES torneo.partido (partido_id),
    CONSTRAINT fk_espacio_publicitario_pieza FOREIGN KEY (pieza_id)
        REFERENCES publicidad.pieza_publicitaria (pieza_id),
    CONSTRAINT chk_espacio_numero CHECK (numero_espacio BETWEEN 1 AND 4),
    CONSTRAINT chk_espacio_monto CHECK (monto_facturado IS NULL OR monto_facturado >= 0)
);

-- Índices no clusterizados: ocupación publicitaria por partido, y piezas de una campaña.

CREATE INDEX idx_espacio_partido ON publicidad.espacio_publicitario (partido_id);
CREATE INDEX idx_pieza_campania ON publicidad.pieza_publicitaria (campania_id);
GO
