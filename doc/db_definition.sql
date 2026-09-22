-- ============================================================
-- SISTEMA DE GESTIÓN DEL MUNDIAL - ESQUEMA DE BASE DE DATOS
-- SQL estándar (ANSI SQL): IDENTITY para autoincremento, CHECK como "enum"
-- ============================================================

-- ============================================================
-- 0. CATÁLOGOS BASE
-- ============================================================

CREATE TABLE pais (
    pais_id         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_iso      CHAR(3) NOT NULL UNIQUE,        -- ej: ARG, BRA
    nombre          VARCHAR(100) NOT NULL,
    huso_horario    VARCHAR(50) NOT NULL,            -- ej: 'America/Argentina/Buenos_Aires'
    pbi_per_capita  NUMERIC(12,2)                    -- usado para priorizar mercados publicitarios
);

CREATE TABLE confederacion (
    confederacion_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre           VARCHAR(50) NOT NULL UNIQUE     -- CONMEBOL, UEFA, CAF, AFC, CONCACAF, OFC
);

-- ============================================================
-- A. GESTIÓN DE SEDES Y PARTIDOS
-- ============================================================

CREATE TABLE sede (
    sede_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(150) NOT NULL,
    ciudad        VARCHAR(100) NOT NULL,
    pais_id       INTEGER NOT NULL REFERENCES pais(pais_id),
    capacidad     INTEGER NOT NULL CHECK (capacidad > 0),
    huso_horario  VARCHAR(50) NOT NULL              -- puede diferir del huso del país si el país es muy extenso
);

CREATE TABLE seleccion (
    seleccion_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pais_id          INTEGER NOT NULL REFERENCES pais(pais_id),
    confederacion_id INTEGER NOT NULL REFERENCES confederacion(confederacion_id),
    grupo            CHAR(1) NOT NULL,               -- 'A', 'B', 'C', ...
    UNIQUE (pais_id)                                 -- un país participa una sola vez
);

CREATE TABLE partido (
    partido_id            INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sede_id               INTEGER NOT NULL REFERENCES sede(sede_id),
    fecha_hora_local      TIMESTAMP NOT NULL,
    fecha_hora_utc        TIMESTAMP NOT NULL,
    fase                  VARCHAR(20) NOT NULL CHECK (fase IN
                              ('grupos','dieciseisavos','octavos','cuartos',
                               'semifinal','tercer_puesto','final')),
    seleccion_local_id    INTEGER NOT NULL REFERENCES seleccion(seleccion_id),
    seleccion_visitante_id INTEGER NOT NULL REFERENCES seleccion(seleccion_id),
    goles_local           INTEGER CHECK (goles_local >= 0),
    goles_visitante       INTEGER CHECK (goles_visitante >= 0),
    penales_local         INTEGER CHECK (penales_local >= 0),   -- solo si hubo definición por penales
    penales_visitante     INTEGER CHECK (penales_visitante >= 0),
    asistencia_publico    INTEGER CHECK (asistencia_publico >= 0),
    CHECK (seleccion_local_id <> seleccion_visitante_id)
);

CREATE INDEX idx_partido_fase ON partido(fase);
CREATE INDEX idx_partido_sede ON partido(sede_id);
CREATE INDEX idx_partido_fecha ON partido(fecha_hora_utc);

-- ============================================================
-- B. SELECCIONES Y CONVOCATORIA
-- ============================================================

CREATE TABLE cuerpo_tecnico (
    staff_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seleccion_id INTEGER NOT NULL REFERENCES seleccion(seleccion_id),
    nombre       VARCHAR(100) NOT NULL,
    apellido     VARCHAR(100) NOT NULL,
    rol          VARCHAR(30) NOT NULL CHECK (rol IN
                     ('director_tecnico','ayudante_tecnico','preparador_fisico','otro'))
);

CREATE TABLE jugador (
    jugador_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    apellido          VARCHAR(100) NOT NULL,
    fecha_nacimiento  DATE NOT NULL,
    club_origen       VARCHAR(150),
    posicion_habitual VARCHAR(30) NOT NULL CHECK (posicion_habitual IN
                          ('arquero','defensor','mediocampista','delantero'))
);

-- Convocatoria: relación jugador <-> selección, con altas/bajas de última hora
CREATE TABLE convocatoria (
    convocatoria_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seleccion_id    INTEGER NOT NULL REFERENCES seleccion(seleccion_id),
    jugador_id      INTEGER NOT NULL REFERENCES jugador(jugador_id),
    dorsal          INTEGER NOT NULL CHECK (dorsal BETWEEN 1 AND 99),
    fecha_alta      DATE NOT NULL,
    motivo_alta     VARCHAR(200),                    -- ej: 'convocatoria original', 'reemplazo por lesión de #7'
    fecha_baja      DATE,                             -- NULL si sigue activo
    motivo_baja     VARCHAR(200),
    activo          BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (seleccion_id, dorsal, fecha_alta),         -- un dorsal no se repite dentro de la misma convocatoria vigente
    UNIQUE (seleccion_id, jugador_id, fecha_alta)
);

CREATE INDEX idx_convocatoria_seleccion ON convocatoria(seleccion_id);

-- ============================================================
-- C. FORMACIONES Y ALINEACIONES
-- ============================================================

CREATE TABLE formacion (
    formacion_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_id      INTEGER NOT NULL REFERENCES partido(partido_id),
    seleccion_id    INTEGER NOT NULL REFERENCES seleccion(seleccion_id),
    esquema_tactico VARCHAR(10) NOT NULL,             -- ej: '4-4-2', '4-3-3'
    UNIQUE (partido_id, seleccion_id)
);

-- Titulares + banco de suplentes de esa formación
CREATE TABLE formacion_jugador (
    formacion_id INTEGER NOT NULL REFERENCES formacion(formacion_id),
    jugador_id   INTEGER NOT NULL REFERENCES jugador(jugador_id),
    dorsal       INTEGER NOT NULL,
    posicion     VARCHAR(30) NOT NULL,                -- posición táctica en ese partido puntual
    titular      BOOLEAN NOT NULL,                    -- TRUE = titular, FALSE = suplente en el banco
    PRIMARY KEY (formacion_id, jugador_id)
);

-- ============================================================
-- D. CAMBIOS (SUSTITUCIONES)
-- ============================================================

CREATE TABLE sustitucion (
    sustitucion_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_id      INTEGER NOT NULL REFERENCES partido(partido_id),
    seleccion_id    INTEGER NOT NULL REFERENCES seleccion(seleccion_id),
    jugador_sale_id INTEGER NOT NULL REFERENCES jugador(jugador_id),
    jugador_entra_id INTEGER NOT NULL REFERENCES jugador(jugador_id),
    minuto          INTEGER NOT NULL CHECK (minuto >= 0),
    periodo         VARCHAR(20) NOT NULL CHECK (periodo IN
                        ('PT','ST','alargue_1','alargue_2')),
    numero_ventana  INTEGER NOT NULL CHECK (numero_ventana > 0),  -- para validar máximo de ventanas permitidas
    motivo          VARCHAR(20) NOT NULL CHECK (motivo IN
                        ('tactico','lesion','precaucion')),
    CHECK (jugador_sale_id <> jugador_entra_id)
);

CREATE INDEX idx_sustitucion_partido ON sustitucion(partido_id, seleccion_id);
-- Nota: el máximo de cambios/ventanas por partido (incluyendo el extra en alargue)
-- se valida a nivel aplicación/trigger contando filas de esta tabla por (partido_id, seleccion_id).

-- ============================================================
-- E. GOLES Y EVENTOS DE PARTIDO
-- ============================================================

CREATE TABLE gol (
    gol_id          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_id      INTEGER NOT NULL REFERENCES partido(partido_id),
    seleccion_id    INTEGER NOT NULL REFERENCES seleccion(seleccion_id),  -- a favor de qué selección cuenta
    jugador_id      INTEGER NOT NULL REFERENCES jugador(jugador_id),      -- autor (si es en contra, va el autor real)
    asistencia_jugador_id INTEGER REFERENCES jugador(jugador_id),
    minuto          INTEGER NOT NULL CHECK (minuto >= 0),
    tipo_gol        VARCHAR(20) NOT NULL CHECK (tipo_gol IN
                        ('jugada','penal','tiro_libre','en_contra','cabezazo','otro')),
    periodo         VARCHAR(20) NOT NULL CHECK (periodo IN
                        ('PT','ST','adicional_PT','adicional_ST',
                         'alargue_1','alargue_2','adicional_alargue')),
    CHECK (asistencia_jugador_id IS NULL OR asistencia_jugador_id <> jugador_id)
);

CREATE INDEX idx_gol_partido ON gol(partido_id);
CREATE INDEX idx_gol_jugador ON gol(jugador_id);
-- Nota: los goles en penales de la definición del partido NO se cargan acá,
-- ya que no cuentan para goleadores del torneo (se guardan en partido.penales_local/visitante).

-- ============================================================
-- F. AMONESTACIONES Y EXPULSIONES
-- ============================================================

CREATE TABLE tarjeta (
    tarjeta_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_id      INTEGER NOT NULL REFERENCES partido(partido_id),
    seleccion_id    INTEGER NOT NULL REFERENCES seleccion(seleccion_id),
    jugador_id      INTEGER NOT NULL REFERENCES jugador(jugador_id),
    minuto          INTEGER NOT NULL CHECK (minuto >= 0),
    tipo            VARCHAR(10) NOT NULL CHECK (tipo IN ('amarilla','roja')),
    motivo          VARCHAR(200),
    tipo_expulsion  VARCHAR(20) CHECK (tipo_expulsion IN ('doble_amarilla','roja_directa')),
    CHECK (tipo_expulsion IS NULL OR tipo = 'roja')
);

CREATE INDEX idx_tarjeta_jugador ON tarjeta(jugador_id);

-- Criterios de suspensión: PARAMETRIZABLE (ej: 2 amarillas en fase de grupos = 1 partido de sanción)
CREATE TABLE criterio_suspension (
    criterio_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fase_aplicable        VARCHAR(20) CHECK (fase_aplicable IN
                              ('grupos','dieciseisavos','octavos','cuartos',
                               'semifinal','tercer_puesto','final')),  -- NULL = aplica a todas
    cantidad_amarillas    INTEGER CHECK (cantidad_amarillas > 0),
    partidos_suspension   INTEGER NOT NULL CHECK (partidos_suspension > 0),
    activo                BOOLEAN NOT NULL DEFAULT TRUE
);

-- Suspensión efectivamente generada para un jugador (por acumulación o roja directa)
CREATE TABLE suspension (
    suspension_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    jugador_id          INTEGER NOT NULL REFERENCES jugador(jugador_id),
    criterio_id         INTEGER REFERENCES criterio_suspension(criterio_id),  -- NULL si viene de roja directa
    tarjeta_id          INTEGER REFERENCES tarjeta(tarjeta_id),               -- tarjeta que dispara la sanción
    partido_afectado_id INTEGER REFERENCES partido(partido_id),               -- próximo partido que se pierde
    motivo              VARCHAR(200) NOT NULL,
    fecha_generada      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- G. GESTIÓN DE ÁRBITROS
-- ============================================================

CREATE TABLE arbitro (
    arbitro_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    apellido    VARCHAR(100) NOT NULL,
    pais_id     INTEGER NOT NULL REFERENCES pais(pais_id),
    categoria   VARCHAR(30) NOT NULL CHECK (categoria IN ('FIFA','confederacion'))
);

-- Idiomas del árbitro (multivaluado -> tabla aparte)
CREATE TABLE arbitro_idioma (
    arbitro_id INTEGER NOT NULL REFERENCES arbitro(arbitro_id),
    idioma     VARCHAR(30) NOT NULL,
    PRIMARY KEY (arbitro_id, idioma)
);

CREATE TABLE designacion_arbitral (
    designacion_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_id     INTEGER NOT NULL REFERENCES partido(partido_id),
    arbitro_id     INTEGER NOT NULL REFERENCES arbitro(arbitro_id),
    rol            VARCHAR(20) NOT NULL CHECK (rol IN
                       ('principal','asistente_1','asistente_2','cuarto','var')),
    UNIQUE (partido_id, rol),        -- un solo árbitro por rol en cada partido
    UNIQUE (partido_id, arbitro_id)  -- un árbitro no puede tener dos roles en el mismo partido
);
-- Regla de negocio (a validar en trigger/aplicación, no expresable como CHECK simple):
-- impedir designar un árbitro cuyo país coincida con alguna selección que dispute el partido;
-- desde dieciseisavos, advertir si el país del árbitro puede cruzarse con las selecciones intervinientes.

CREATE TABLE informe_arbitral (
    informe_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    designacion_id INTEGER NOT NULL REFERENCES designacion_arbitral(designacion_id),
    fecha          DATE NOT NULL,
    contenido      TEXT NOT NULL,
    sancion        VARCHAR(200)     -- NULL si no hubo sanción
);

-- ============================================================
-- H. GESTIÓN DE PUBLICIDAD
-- ============================================================

CREATE TABLE anunciante (
    anunciante_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre        VARCHAR(150) NOT NULL,
    razon_social  VARCHAR(150),
    contacto      VARCHAR(150)
);

CREATE TABLE campania (
    campania_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    anunciante_id  INTEGER NOT NULL REFERENCES anunciante(anunciante_id),
    nombre         VARCHAR(150) NOT NULL,
    fecha_inicio   DATE NOT NULL,
    fecha_fin      DATE NOT NULL,
    CHECK (fecha_fin >= fecha_inicio)
);

-- Países de interés de la campaña (multivaluado)
CREATE TABLE campania_pais_interes (
    campania_id INTEGER NOT NULL REFERENCES campania(campania_id),
    pais_id     INTEGER NOT NULL REFERENCES pais(pais_id),
    PRIMARY KEY (campania_id, pais_id)
);

-- Pieza de contenido puntual, por idioma/mercado, dentro de una campaña
CREATE TABLE pieza_publicitaria (
    pieza_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    campania_id     INTEGER NOT NULL REFERENCES campania(campania_id),
    idioma          VARCHAR(30) NOT NULL,
    pais_mercado_id INTEGER NOT NULL REFERENCES pais(pais_id),  -- mercado destino
    costo_tarifa    NUMERIC(12,2) NOT NULL CHECK (costo_tarifa >= 0)
);

-- Asignación real de una pieza a uno de los 4 espacios de un partido (= historial para facturación)
CREATE TABLE espacio_publicitario (
    espacio_id        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    partido_id        INTEGER NOT NULL REFERENCES partido(partido_id),
    numero_espacio    INTEGER NOT NULL CHECK (numero_espacio BETWEEN 1 AND 4),
    pieza_id          INTEGER REFERENCES pieza_publicitaria(pieza_id),  -- NULL = espacio aún no asignado
    orden_prioridad   INTEGER,           -- 1,2,3 según el criterio que lo priorizó (país selección / PBI / prime time)
    fecha_exhibicion  TIMESTAMP,         -- momento real de exhibición, para el historial de facturación
    facturado         BOOLEAN NOT NULL DEFAULT FALSE,
    monto_facturado   NUMERIC(12,2),
    UNIQUE (partido_id, numero_espacio)  -- exactamente 4 espacios por sede/partido, sin duplicar el número
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
