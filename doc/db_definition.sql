-- ============================================================
-- SISTEMA DE GESTIÓN DEL MUNDIAL - ESQUEMA DE BASE DE DATOS
-- SQL estándar (ANSI SQL): IDENTITY para autoincremento, CHECK como "enum"
-- ============================================================

-- ============================================================
-- 0. CATÁLOGOS BASE
-- ============================================================

CREATE TABLE pais (
    pais_id         INTEGER IDENTITY(1, 1),
    codigo_iso      CHAR(3) NOT NULL UNIQUE,        -- ej: ARG, BRA
    nombre          VARCHAR(100) NOT NULL,
    huso_horario    VARCHAR(50) NOT NULL,            -- ej: 'America/Argentina/Buenos_Aires'
    pbi_per_capita  NUMERIC(12,2),                    -- usado para priorizar mercados publicitarios
    CONSTRAINT pk_pais PRIMARY KEY (pais_id)
);

CREATE TABLE confederacion (
    confederacion_id INTEGER IDENTITY(1, 1),
    nombre           VARCHAR(50) NOT NULL UNIQUE,     -- CONMEBOL, UEFA, CAF, AFC, CONCACAF, OFC
    CONSTRAINT pk_confederacion PRIMARY KEY (confederacion_id)
);

-- ============================================================
-- A. GESTIÓN DE SEDES Y PARTIDOS
-- ============================================================

CREATE TABLE sede (
    sede_id       INTEGER IDENTITY(1, 1),
    nombre        VARCHAR(150) NOT NULL,
    ciudad        VARCHAR(100) NOT NULL,
    pais_id       INTEGER NOT NULL,
    capacidad     INTEGER NOT NULL,
    huso_horario  VARCHAR(50) NOT NULL,              -- puede diferir del huso del país si el país es muy extenso
    CONSTRAINT pk_sede PRIMARY KEY (sede_id),
    CONSTRAINT fk_sede_pais FOREIGN KEY (pais_id)
        REFERENCES pais(pais_id),
    CONSTRAINT chk_capacidad CHECK (capacidad > 0)
);

CREATE TABLE seleccion (
    seleccion_id     INTEGER IDENTITY(1, 1),
    pais_id          INTEGER NOT NULL,
    confederacion_id INTEGER NOT NULL,
    grupo            CHAR(1) NOT NULL,               -- 'A', 'B', 'C', ...
    UNIQUE (pais_id),                                 -- un país participa una sola vez
    CONSTRAINT pk_seleccion PRIMARY KEY (seleccion_id),
    CONSTRAINT fk_seleccion_pais FOREIGN KEY (pais_id)
        REFERENCES pais(pais_id),
    CONSTRAINT fk_seleccion_pais_confederacion FOREIGN KEY (confederacion_id)
        REFERENCES confederacion(confederacion_id)
);

CREATE TABLE partido (
    partido_id            INTEGER IDENTITY(1, 1),
    sede_id               INTEGER NOT NULL,
    fecha_hora_local      DATETIMEOFFSET NOT NULL,
    fecha_hora_utc        DATETIMEOFFSET NOT NULL,
    fase                  VARCHAR(20) NOT NULL CHECK (fase IN
                              ('grupos','dieciseisavos','octavos','cuartos',
                               'semifinal','tercer_puesto','final')),
    seleccion_local_id    INTEGER NOT NULL,
    seleccion_visitante_id INTEGER NOT NULL,
    goles_local           INTEGER CHECK (goles_local >= 0),
    goles_visitante       INTEGER CHECK (goles_visitante >= 0),
    penales_local         INTEGER CHECK (penales_local >= 0),   -- solo si hubo definición por penales
    penales_visitante     INTEGER CHECK (penales_visitante >= 0),
    asistencia_publico    INTEGER CHECK (asistencia_publico >= 0),
    
    CONSTRAINT pk_partido PRIMARY KEY (partido_id),
    CONSTRAINT fk_partido_sede FOREIGN KEY (sede_id)
        REFERENCES sede(sede_id),
    CONSTRAINT fk_partido_seleccion_local FOREIGN KEY (seleccion_local_id)
            REFERENCES seleccion(seleccion_id),
    CONSTRAINT fk_partido_seleccion_visitante FOREIGN KEY (seleccion_visitante_id)
            REFERENCES seleccion(seleccion_id),
    CONSTRAINT chk_partido CHECK (seleccion_local_id <> seleccion_visitante_id),
);

CREATE INDEX idx_partido_fase ON partido(fase);
CREATE INDEX idx_partido_sede ON partido(sede_id);
CREATE INDEX idx_partido_fecha ON partido(fecha_hora_utc);

-- ============================================================
-- B. SELECCIONES Y CONVOCATORIA
-- ============================================================

CREATE TABLE cuerpo_tecnico (
    staff_id     INTEGER IDENTITY(1, 1),
    seleccion_id INTEGER NOT NULL,
    nombre       VARCHAR(100) NOT NULL,
    apellido     VARCHAR(100) NOT NULL,
    rol          VARCHAR(30) NOT NULL CHECK (rol IN
                     ('director_tecnico','ayudante_tecnico','preparador_fisico','otro')),

    CONSTRAINT pk_cuerpo_tecnico PRIMARY KEY (staff_id),
    CONSTRAINT fk_cuerpo_tecnico_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES seleccion(seleccion_id),
    CONSTRAINT uq_cuerpo_tecnico UNIQUE (seleccion_id, nombre, apellido, rol)  -- no repetir el mismo staff en la misma selección
);

CREATE TABLE jugador (
    jugador_id        INTEGER IDENTITY(1, 1),
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    fecha_nacimiento  DATE NOT NULL,
    club_origen       VARCHAR(150),
    posicion_habitual VARCHAR(30) NOT NULL CHECK (posicion_habitual IN
                          ('arquero','defensor','mediocampista','delantero')),

    CONSTRAINT pk_jugador PRIMARY KEY (jugador_id),   
);

-- Convocatoria: relación jugador <-> selección, con altas/bajas de última hora
CREATE TABLE convocatoria (
    convocatoria_id INTEGER IDENTITY(1, 1),
    seleccion_id    INTEGER NOT NULL,
    jugador_id      INTEGER NOT NULL,
    dorsal          INTEGER NOT NULL CHECK (dorsal BETWEEN 1 AND 99),
    fecha_alta      DATE NOT NULL,
    motivo_alta     VARCHAR(200),                    -- ej: 'convocatoria original', 'reemplazo por lesión de #7'
    fecha_baja      DATE,                             -- NULL si sigue activo
    motivo_baja     VARCHAR(200),
    activo          BIT NOT NULL DEFAULT 1,
    UNIQUE (seleccion_id, dorsal, fecha_alta),         -- un dorsal no se repite dentro de la misma convocatoria vigente
    UNIQUE (seleccion_id, jugador_id, fecha_alta),

    CONSTRAINT pk_convocatoria PRIMARY KEY (convocatoria_id),
    CONSTRAINT fk_convocatoria_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES seleccion(seleccion_id),
    CONSTRAINT fk_convocatoria_jugador FOREIGN KEY (jugador_id)
        REFERENCES jugador(jugador_id),
    CONSTRAINT chk_convocatoria CHECK (fecha_baja IS NULL OR fecha_baja >= fecha_alta)
);

CREATE INDEX idx_convocatoria_seleccion ON convocatoria(seleccion_id);

-- ============================================================
-- C. FORMACIONES Y ALINEACIONES
-- ============================================================

CREATE TABLE formacion (
    formacion_id    INTEGER IDENTITY(1, 1),
    partido_id      INTEGER NOT NULL,
    seleccion_id    INTEGER NOT NULL,
    esquema_tactico VARCHAR(10) NOT NULL,             -- ej: '4-4-2', '4-3-3'
    UNIQUE (partido_id, seleccion_id),

    CONSTRAINT pk_formacion PRIMARY KEY (formacion_id),
    CONSTRAINT fk_formacion_partido FOREIGN KEY (partido_id)
        REFERENCES partido(partido_id),
    CONSTRAINT fk_formacion_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES seleccion(seleccion_id)
);

-- Titulares + banco de suplentes de esa formación
CREATE TABLE formacion_jugador (
    formacion_id INTEGER NOT NULL,
    jugador_id   INTEGER NOT NULL,
    dorsal       INTEGER NOT NULL,
    posicion     VARCHAR(30) NOT NULL,                -- posición táctica en ese partido puntual
    titular      BIT NOT NULL,                    -- TRUE = titular, FALSE = suplente en el banco
    CONSTRAINT pk_formacion_jugador PRIMARY KEY (formacion_id, jugador_id),
    CONSTRAINT fk_formacion_jugador_formacion FOREIGN KEY (formacion_id)
        REFERENCES formacion(formacion_id),
    CONSTRAINT fk_formacion_jugador_jugador FOREIGN KEY (jugador_id)
        REFERENCES jugador(jugador_id),
    CONSTRAINT chk_formacion_jugador CHECK (dorsal BETWEEN 1 AND 99)
);

-- ============================================================
-- D. CAMBIOS (SUSTITUCIONES)
-- ============================================================

CREATE TABLE sustitucion (
    sustitucion_id  INTEGER IDENTITY(1, 1),
    partido_id      INTEGER NOT NULL,
    seleccion_id    INTEGER NOT NULL,
    jugador_sale_id INTEGER NOT NULL,
    jugador_entra_id INTEGER NOT NULL,
    minuto          INTEGER NOT NULL CHECK (minuto >= 0),
    periodo         VARCHAR(20) NOT NULL CHECK (periodo IN
                        ('PT','ST','alargue_1','alargue_2')),
    numero_ventana  INTEGER NOT NULL CHECK (numero_ventana > 0),  -- para validar máximo de ventanas permitidas
    motivo          VARCHAR(20) NOT NULL CHECK (motivo IN
                        ('tactico','lesion','precaucion')),
    CONSTRAINT chk_sustitucion CHECK (jugador_sale_id <> jugador_entra_id),
    CONSTRAINT pk_sustitucion PRIMARY KEY (sustitucion_id),
    CONSTRAINT fk_sustitucion_partido FOREIGN KEY (partido_id)
        REFERENCES partido(partido_id),
    CONSTRAINT fk_sustitucion_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES seleccion(seleccion_id),
    CONSTRAINT fk_sustitucion_jugador_sale FOREIGN KEY (jugador_sale_id)
        REFERENCES jugador(jugador_id),
    CONSTRAINT fk_sustitucion_jugador_entra FOREIGN KEY (jugador_entra_id)
        REFERENCES jugador(jugador_id)
);

CREATE INDEX idx_sustitucion_partido ON sustitucion(partido_id, seleccion_id);
-- Nota: el máximo de cambios/ventanas por partido (incluyendo el extra en alargue)
-- se valida a nivel aplicación/trigger contando filas de esta tabla por (partido_id, seleccion_id).

-- ============================================================
-- E. GOLES Y EVENTOS DE PARTIDO
-- ============================================================

CREATE TABLE gol (
    gol_id          INTEGER IDENTITY(1, 1),
    partido_id      INTEGER NOT NULL,
    seleccion_id    INTEGER NOT NULL,  -- a favor de qué selección cuenta
    jugador_id      INTEGER NOT NULL,      -- autor (si es en contra, va el autor real)
    asistencia_jugador_id INTEGER,
    minuto          INTEGER NOT NULL CHECK (minuto >= 0),
    tipo_gol        VARCHAR(20) NOT NULL CHECK (tipo_gol IN
                        ('jugada','penal','tiro_libre','en_contra','cabezazo','otro')),
    periodo         VARCHAR(20) NOT NULL CHECK (periodo IN
                        ('PT','ST','adicional_PT','adicional_ST',
                         'alargue_1','alargue_2','adicional_alargue')),

    CONSTRAINT chk_asistencia CHECK (asistencia_jugador_id IS NULL OR asistencia_jugador_id <> jugador_id),
    CONSTRAINT pk_gol PRIMARY KEY (gol_id),
    CONSTRAINT fk_gol_partido FOREIGN KEY (partido_id)
        REFERENCES partido(partido_id),
    CONSTRAINT fk_gol_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES seleccion(seleccion_id),
    CONSTRAINT fk_gol_jugador FOREIGN KEY (jugador_id)
        REFERENCES jugador(jugador_id),
    CONSTRAINT fk_gol_asistencia FOREIGN KEY (asistencia_jugador_id)
        REFERENCES jugador(jugador_id)
);

    CREATE INDEX idx_gol_partido ON gol(partido_id);
    CREATE INDEX idx_gol_jugador ON gol(jugador_id);
-- Nota: los goles en penales de la definición del partido NO se cargan acá,
-- ya que no cuentan para goleadores del torneo (se guardan en partido.penales_local/visitante).

-- ============================================================
-- F. AMONESTACIONES Y EXPULSIONES
-- ============================================================

CREATE TABLE tarjeta (
    tarjeta_id      INTEGER IDENTITY(1, 1),
    partido_id      INTEGER NOT NULL,
    seleccion_id    INTEGER NOT NULL,
    jugador_id      INTEGER NOT NULL,
    minuto          INTEGER NOT NULL CHECK (minuto >= 0),
    tipo            VARCHAR(10) NOT NULL CHECK (tipo IN ('amarilla','roja')),
    motivo          VARCHAR(200),
    tipo_expulsion  VARCHAR(20) CHECK (tipo_expulsion IN ('doble_amarilla','roja_directa')),
    CONSTRAINT chk_tipo_expulsion CHECK (tipo_expulsion IS NULL OR tipo = 'roja'),
    CONSTRAINT pk_tarjeta PRIMARY KEY (tarjeta_id),
    CONSTRAINT fk_tarjeta_partido FOREIGN KEY (partido_id)
        REFERENCES partido(partido_id),
    CONSTRAINT fk_tarjeta_seleccion FOREIGN KEY (seleccion_id)
        REFERENCES seleccion(seleccion_id),
    CONSTRAINT fk_tarjeta_jugador FOREIGN KEY (jugador_id)
        REFERENCES jugador(jugador_id)
);

CREATE INDEX idx_tarjeta_jugador ON tarjeta(jugador_id);

-- Criterios de suspensión: PARAMETRIZABLE (ej: 2 amarillas en fase de grupos = 1 partido de sanción)
CREATE TABLE criterio_suspension (
    criterio_id           INTEGER IDENTITY(1, 1),
    fase_aplicable        VARCHAR(20) CHECK (fase_aplicable IN
                              ('grupos','dieciseisavos','octavos','cuartos',
                               'semifinal','tercer_puesto','final')),  -- NULL = aplica a todas
    cantidad_amarillas    INTEGER CHECK (cantidad_amarillas > 0),
    partidos_suspension   INTEGER NOT NULL CHECK (partidos_suspension > 0),
    activo                BIT NOT NULL DEFAULT 1,

    CONSTRAINT uq_criterio_suspension UNIQUE (fase_aplicable, cantidad_amarillas),
    CONSTRAINT pk_criterio_suspension PRIMARY KEY (criterio_id),
    CONSTRAINT chk_criterio_suspension CHECK (cantidad_amarillas IS NOT NULL OR partidos_suspension IS NOT NULL)
);

-- Suspensión efectivamente generada para un jugador (por acumulación o roja directa)
CREATE TABLE suspension (
    suspension_id       INTEGER IDENTITY(1, 1),
    jugador_id          INTEGER NOT NULL,
    criterio_id         INTEGER,  -- NULL si viene de roja directa
    tarjeta_id          INTEGER,               -- tarjeta que dispara la sanción
    partido_afectado_id INTEGER,               -- próximo partido que se pierde
    motivo              VARCHAR(200) NOT NULL,
    fecha_generada      DATETIMEOFFSET NOT NULL DEFAULT CONVERT(DATETIMEOFFSET, GETDATE()),

    CONSTRAINT pk_suspension PRIMARY KEY (suspension_id),
    CONSTRAINT fk_suspension_jugador FOREIGN KEY (jugador_id)
        REFERENCES jugador(jugador_id),
    CONSTRAINT fk_suspension_criterio FOREIGN KEY (criterio_id)
        REFERENCES criterio_suspension(criterio_id),
    CONSTRAINT fk_suspension_tarjeta FOREIGN KEY (tarjeta_id)
        REFERENCES tarjeta(tarjeta_id),
    CONSTRAINT fk_suspension_partido FOREIGN KEY (partido_afectado_id)
        REFERENCES partido(partido_id)
);

-- ============================================================
-- G. GESTIÓN DE ÁRBITROS
-- ============================================================

CREATE TABLE arbitro (
    arbitro_id  INTEGER IDENTITY(1, 1),
    nombre      VARCHAR(100) NOT NULL,
    apellido    VARCHAR(100) NOT NULL,
    pais_id     INTEGER NOT NULL,
    categoria   VARCHAR(30) NOT NULL CHECK (categoria IN ('FIFA','confederacion')),

    CONSTRAINT uq_arbitro UNIQUE (nombre, apellido, pais_id),  -- no repetir árbitros del mismo país
    CONSTRAINT pk_arbitro PRIMARY KEY (arbitro_id),
    CONSTRAINT fk_arbitro_pais FOREIGN KEY (pais_id)
        REFERENCES pais(pais_id)
);

-- Idiomas del árbitro (multivaluado -> tabla aparte)
CREATE TABLE arbitro_idioma (
    arbitro_id INTEGER NOT NULL,
    idioma     VARCHAR(30) NOT NULL,
    CONSTRAINT pk_arbitro_idioma PRIMARY KEY (arbitro_id, idioma),
    CONSTRAINT fk_arbitro_idioma_arbitro FOREIGN KEY (arbitro_id)
        REFERENCES arbitro(arbitro_id),
    CONSTRAINT uq_arbitro_idioma UNIQUE (arbitro_id, idioma),  -- no repetir el mismo idioma para un árbitro
);

CREATE TABLE designacion_arbitral (
    designacion_id INTEGER IDENTITY(1, 1),
    partido_id     INTEGER NOT NULL,
    arbitro_id     INTEGER NOT NULL,
    rol            VARCHAR(20) NOT NULL CHECK (rol IN
                       ('principal','asistente_1','asistente_2','cuarto','var')),
    CONSTRAINT uq_designacion_arbitral_rol UNIQUE (partido_id, rol),        -- un solo árbitro por rol en cada partido
    CONSTRAINT uq_designacion_arbitral_arbitro UNIQUE (partido_id, arbitro_id),  -- un árbitro no puede tener dos roles en el mismo partido
    CONSTRAINT chk_designacion_arbitral CHECK (rol <> 'principal' OR arbitro_id IS NOT NULL),  -- el principal no puede ser NULL
    CONSTRAINT pk_designacion_arbitral PRIMARY KEY (designacion_id),
    CONSTRAINT fk_designacion_arbitral_partido FOREIGN KEY (partido_id)
        REFERENCES partido(partido_id),
    CONSTRAINT fk_designacion_arbitral_arbitro FOREIGN KEY (arbitro_id)
        REFERENCES arbitro(arbitro_id)
);
-- Regla de negocio (a validar en trigger/aplicación, no expresable como CHECK simple):
-- impedir designar un árbitro cuyo país coincida con alguna selección que dispute el partido;
-- desde dieciseisavos, advertir si el país del árbitro puede cruzarse con las selecciones intervinientes.

CREATE TABLE informe_arbitral (
    informe_id     INTEGER IDENTITY(1, 1),
    designacion_id INTEGER NOT NULL,
    fecha          DATETIMEOFFSET NOT NULL,
    contenido      TEXT NOT NULL,
    sancion        VARCHAR(200)     -- NULL si no hubo sanción

    CONSTRAINT pk_informe_arbitral PRIMARY KEY (informe_id),
    CONSTRAINT fk_informe_arbitral_designacion FOREIGN KEY (designacion_id)
        REFERENCES designacion_arbitral(designacion_id)
);

-- ============================================================
-- H. GESTIÓN DE PUBLICIDAD
-- ============================================================

CREATE TABLE anunciante (
    anunciante_id INTEGER IDENTITY(1, 1),
    nombre        VARCHAR(150) NOT NULL,
    razon_social  VARCHAR(150),
    contacto      VARCHAR(150),

    CONSTRAINT pk_anunciante PRIMARY KEY (anunciante_id)
);

CREATE TABLE campania (
    campania_id    INTEGER IDENTITY(1, 1),
    anunciante_id  INTEGER NOT NULL,
    nombre         VARCHAR(150) NOT NULL,
    fecha_inicio   DATETIMEOFFSET NOT NULL,
    fecha_fin      DATETIMEOFFSET NOT NULL,

    CONSTRAINT chk_campania_fecha CHECK (fecha_fin >= fecha_inicio),
    CONSTRAINT uq_campania_nombre_anunciante UNIQUE (anunciante_id, nombre),  -- un anunciante no puede repetir nombre de campaña
    CONSTRAINT pk_campania PRIMARY KEY (campania_id),
    CONSTRAINT fk_campania_anunciante FOREIGN KEY (anunciante_id)
        REFERENCES anunciante(anunciante_id)
);

-- Países de interés de la campaña (multivaluado)
CREATE TABLE campania_pais_interes (
    campania_id INTEGER NOT NULL,
    pais_id     INTEGER NOT NULL,
    CONSTRAINT pk_campania_pais_interes PRIMARY KEY (campania_id, pais_id),
    CONSTRAINT uq_campania_pais_interes UNIQUE (campania_id, pais_id),  -- no repetir el mismo país para una campaña
    CONSTRAINT fk_campania_pais_interes_campania FOREIGN KEY (campania_id)
        REFERENCES campania(campania_id),
    CONSTRAINT fk_campania_pais_interes_pais FOREIGN KEY (pais_id)
        REFERENCES pais(pais_id)
);

-- Pieza de contenido puntual, por idioma/mercado, dentro de una campaña
CREATE TABLE pieza_publicitaria (
    pieza_id        INTEGER IDENTITY(1, 1),
    campania_id     INTEGER NOT NULL,
    idioma          VARCHAR(30) NOT NULL,
    pais_mercado_id INTEGER NOT NULL,
    costo_tarifa    NUMERIC(12,2) NOT NULL CHECK (costo_tarifa >= 0),

    CONSTRAINT pk_pieza_publicitaria PRIMARY KEY (pieza_id),
    CONSTRAINT fk_pieza_publicitaria_campania FOREIGN KEY (campania_id)
        REFERENCES campania(campania_id),
    CONSTRAINT fk_pieza_publicitaria_pais FOREIGN KEY (pais_mercado_id)
        REFERENCES pais(pais_id),
    CONSTRAINT uq_pieza_publicitaria UNIQUE (campania_id, idioma, pais_mercado_id)  -- no repetir la misma pieza para un mismo idioma/mercado dentro de la
);

-- Asignación real de una pieza a uno de los 4 espacios de un partido (= historial para facturación)
CREATE TABLE espacio_publicitario (
    espacio_id        INTEGER IDENTITY(1, 1),
    partido_id        INTEGER NOT NULL,
    numero_espacio    INTEGER NOT NULL CHECK (numero_espacio BETWEEN 1 AND 4),
    pieza_id          INTEGER,  -- NULL = espacio aún no asignado
    orden_prioridad   INTEGER,           -- 1,2,3 según el criterio que lo priorizó (país selección / PBI / prime time)
    fecha_exhibicion  DATETIMEOFFSET,         -- momento real de exhibición, para el historial de facturación
    facturado         BIT NULL DEFAULT 0,
    monto_facturado   NUMERIC(12,2),
    CONSTRAINT uq_espacio_publicitario UNIQUE (partido_id, numero_espacio),  -- exactamente 4 espacios por sede/partido, sin duplicar el númeroo
    CONSTRAINT pk_espacio_publicitario PRIMARY KEY (espacio_id),
    CONSTRAINT fk_espacio_publicitario_partido FOREIGN KEY (partido_id)
        REFERENCES partido(partido_id),
    CONSTRAINT fk_espacio_publicitario_pieza FOREIGN KEY (pieza_id)
        REFERENCES pieza_publicitaria(pieza_id)
);

CREATE INDEX idx_espacio_partido ON espacio_publicitario(partido_id);
CREATE INDEX idx_pieza_campania ON pieza_publicitaria(campania_id);

-- ============================================================
-- RESUMEN DE RELACIONES CLAVE (PK -> FK)
-- ============================================================
-- pais(pais_id) <- sede, seleccion, arbitro, campania_pais_interes, pieza_publicitaria
-- seleccion(seleccion_id) <- partido (x2: local/visitante), convocatoria, cuerpo_tecnico,
--                             formacion, sustitucion, gol, tarjeta
-- partido(partido_id) <- formacion, sustitucion, gol, tarjeta, designacion_arbitral,
--                         espacio_publicitario, suspension(partido_afectado_id)
-- jugador(jugador_id) <- convocatoria, formacion_jugador, sustitucion (x2), gol (x2),
--                         tarjeta, suspension
-- arbitro(arbitro_id) <- arbitro_idioma, designacion_arbitral
-- designacion_arbitral(designacion_id) <- informe_arbitral
-- anunciante(anunciante_id) <- campania
-- campania(campania_id) <- campania_pais_interes, pieza_publicitaria
-- pieza_publicitaria(pieza_id) <- espacio_publicitario
