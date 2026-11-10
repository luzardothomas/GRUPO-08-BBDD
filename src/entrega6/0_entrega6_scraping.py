#!/usr/bin/env python3
# =======================================================================================
# UNIVERSIDAD NACIONAL DE LA MATANZA
# MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
# TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
# ENTREGA 6: Procesos de importación - Scraping de Wikipedia
#
# INTEGRANTES:
#   LUZARDO, THOMAS GASTON
#   EKSZTEIN ROLON, JEREMIAS OCTAVIO
#   REPRESAS PANOZZO, GERÓNIMO
#   LARAN, JEAN PIERRE
#
# DESCRIPCIÓN:
#   Descarga en vivo las páginas de Wikipedia del torneo, extrae sedes, selecciones y
#   planteles, y guarda el resultado en archivos JSON dentro de imports/scraping/:
#     sedes.json        -> lo importa torneo.importar_sedes        (torneo.sede)
#     selecciones.json  -> lo importa torneo.importar_selecciones  (torneo.seleccion, torneo.seleccion_estadistica)
#     planteles.json    -> lo importa plantel.importar_planteles   (plantel.jugador, plantel.convocatoria,
#                                                                   plantel.cuerpo_tecnico)
#   Los SP están en entrega6_importacion.sql (sección 6): validan cada registro y lo dan de alta o lo
#   modifican con los SP de la Entrega 5.
#   Sólo usa la biblioteca estándar de Python 3.9 o superior (no hace falta instalar nada).
#
# USO:
#   python3 src/entrega6/entrega6_scraping.py                     (las tres páginas)
#   python3 src/entrega6/entrega6_scraping.py sedes planteles     (sólo esos conjuntos)
#   python3 src/entrega6/entrega6_scraping.py --salida C:\mundial2026\imports\scraping
#   Opciones: --pagina-torneo y --pagina-planteles cambian las páginas de origen.
#   Si una página no existe o no tiene la sección esperada, informa el error, no escribe
#   ese archivo y termina con código 1.
#
# FUENTES (PÁGINAS DE ORIGEN) Y LÍMITES DE USO:
#   * Páginas de origen en Wikipedia en inglés:
#     - https://en.wikipedia.org/wiki/2026_FIFA_World_Cup        (sedes, confederaciones y tabla final)
#     - https://en.wikipedia.org/wiki/2026_FIFA_World_Cup_squads (grupos, planteles y entrenadores)
#   * Endpoint de descarga (MediaWiki Action API):
#     - https://en.wikipedia.org/w/api.php?action=parse&prop=wikitext&format=json&formatversion=2&page=<pagina>
#   * Límites de uso (Wikimedia API Etiquette):
#     - No requiere clave de autenticación (API pública gratuita).
#     - Pide peticiones secuenciales (sin concurrencia) y un encabezado User-Agent identificable.
#     - El script hace a lo sumo 2 llamadas HTTP (una por página), aunque se pidan los tres conjuntos.
#
# TÉCNICA DE SCRAPING:
#   La API de MediaWiki devuelve, dentro de un JSON, el texto fuente de la página (wikitext),
#   que es regular. Se parte en líneas, se ubica cada sección por su encabezado y de cada
#   línea se extraen los campos con expresiones regulares:
#   * Sedes (tabla "List of tournament venues" de ==Venues==): cada fila empieza con
#     "! ... {{#invoke:flag|icon|MEX}} [[Mexico City]]", seguida del estadio y su capacidad.
#     La tabla no informa el huso horario: se calcula para el 15/06/2026 con la zona horaria
#     de cada ciudad (base IANA de zoneinfo; si el sistema no la tiene, desplazamientos fijos
#     de junio de 2026).
#   * Selecciones (===Qualification=== y ===Tournament ranking=== del artículo del torneo,
#     y encabezados ==Group X== de la página de planteles): confederación, grupo y tabla final
#     ("|team_order=ESP, ARG, ...", "|pos_MAR={{=}}7", "|win_ARG=7 |draw_ARG=0 |loss_ARG=1 |gf_ARG=19|ga_ARG=8").
#   * Planteles: una plantilla por jugador
#     {{nat fs g player|no=1|pos=GK|name=[[Matěj Kovář]]|sortname=Kovar, Matej|
#     age={{birth date and age2|...|2000|5|17}}|club=[[PSV Eindhoven]]|...}} y una línea
#     "Coach: [[...]]" por selección, debajo del encabezado ===Selección===.
#   Los datos se guardan tal como figuran en la página (texto UTF-8); la validación, la
#   traducción de los nombres de país y la división en nombre y apellido las hacen los SP.
# =======================================================================================

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

API = 'https://en.wikipedia.org/w/api.php'
URL_PAGINA = 'https://en.wikipedia.org/wiki/'
USER_AGENT = 'TP-Mundial-2026/1.0 (UNLaM - Bases de Datos Aplicada; trabajo practico educativo)'
PAGINA_TORNEO = '2026_FIFA_World_Cup'
PAGINA_PLANTELES = '2026_FIFA_World_Cup_squads'
SALIDA = Path(__file__).resolve().parents[2] / 'imports' / 'scraping'

# Zona horaria de cada ciudad sede (la tabla de Wikipedia no la informa) y su desplazamiento
# en junio de 2026, por si el sistema no tiene la base de zonas horarias (Windows sin tzdata).
ZONAS = {
    'Mexico City': ('America/Mexico_City', -6), 'Guadalajara': ('America/Mexico_City', -6),
    'Monterrey': ('America/Monterrey', -6), 'Toronto': ('America/Toronto', -4),
    'Vancouver': ('America/Vancouver', -7), 'New York/New Jersey': ('America/New_York', -4),
    'Boston': ('America/New_York', -4), 'Philadelphia': ('America/New_York', -4),
    'Atlanta': ('America/New_York', -4), 'Miami': ('America/New_York', -4),
    'Dallas': ('America/Chicago', -5), 'Houston': ('America/Chicago', -5),
    'Kansas City': ('America/Chicago', -5), 'Los Angeles': ('America/Los_Angeles', -7),
    'San Francisco Bay Area': ('America/Los_Angeles', -7), 'Seattle': ('America/Los_Angeles', -7),
}

ENLACE = r'\[\[(?:[^|\]]*\|)?([^\]]+)\]\]'      # [[destino|texto]] o [[texto]] -> texto
CONFEDERACION = r'\|(AFC|CAF|CONCACAF|CONMEBOL|OFC|UEFA)\]\]'


class ErrorScraping(Exception):
    """La página no existe o no tiene la estructura esperada."""


def buscar(patron, texto, grupo=1):
    m = re.search(patron, texto or '')
    return m.group(grupo) if m else None


def obtener_wikitext(pagina):
    """Texto fuente de una página de la Wikipedia en inglés (MediaWiki Action API)."""
    parametros = urllib.parse.urlencode({'action': 'parse', 'prop': 'wikitext', 'format': 'json',
                                         'formatversion': 2, 'page': pagina.strip().replace(' ', '_')})
    pedido = urllib.request.Request(f'{API}?{parametros}', headers={'User-Agent': USER_AGENT})
    try:
        with urllib.request.urlopen(pedido, timeout=60) as respuesta:
            datos = json.load(respuesta)
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
        raise ErrorScraping(f"No se pudo descargar la página '{pagina}': {e}") from e
    if 'error' in datos:
        raise ErrorScraping(f"Wikipedia no devolvió la página '{pagina}': "
                            f"{datos['error'].get('info', '(sin detalle)')}")
    texto = datos.get('parse', {}).get('wikitext')
    if not texto:
        raise ErrorScraping(f"La respuesta de Wikipedia no trae el texto de la página '{pagina}'.")
    return texto.replace('\r', '').split('\n')


def indice(lineas, condicion, desde=0):
    return next((i for i in range(desde, len(lineas)) if condicion(lineas[i])), None)


def huso_horario(ciudad):
    """Huso 'UTC±hh' de la ciudad el 15/06/2026 (None si la ciudad no tiene zona definida)."""
    if ciudad not in ZONAS:
        return None
    zona, horas = ZONAS[ciudad]
    try:
        from zoneinfo import ZoneInfo
        horas = int(datetime(2026, 6, 15, 12, tzinfo=ZoneInfo(zona)).utcoffset() / timedelta(hours=1))
    except Exception:      # sin base de zonas horarias: desplazamiento fijo de junio de 2026
        pass
    return f"UTC{'-' if horas < 0 else '+'}{abs(horas):02d}"


# ============================================================
# SEDES
# ============================================================

def scrapear_sedes(lineas):
    desde = indice(lineas, lambda l: l.startswith('|+ List of tournament venues'))
    hasta = indice(lineas, lambda l: l.startswith('|}'), (desde or 0) + 1) if desde is not None else None
    if desde is None or hasta is None:
        raise ErrorScraping('El texto no contiene la tabla "List of tournament venues".')

    sedes = []
    for k in range(desde, hasta + 1):
        linea = lineas[k]
        if not (linea.startswith('!') and 'flag|icon|' in linea):
            continue
        siguiente = lambda n: lineas[k + n] if k + n <= hasta else ''
        ciudad = buscar(r'\}\}\s*' + ENLACE, linea)
        capacidad = buscar(r'([0-9][0-9,]*)', siguiente(3))
        sedes.append({
            'estadio': buscar(ENLACE, siguiente(1)),
            'ciudad': ciudad,
            'pais': buscar(r'flag\|icon\|([A-Z]{3})', linea),
            'capacidad': capacidad.replace(',', '') if capacidad else None,
            'huso_horario': huso_horario(ciudad),
        })
    return sedes


# ============================================================
# SELECCIONES
# ============================================================

def scrapear_selecciones(torneo, planteles):
    q_desde = indice(torneo, lambda l: l.startswith('===Qualification==='))
    q_hasta = indice(torneo, lambda l: l.startswith('==') and not l.startswith('==='), (q_desde or 0) + 1) \
        if q_desde is not None else None
    r_desde = indice(torneo, lambda l: l.startswith('===Tournament ranking==='))
    if q_desde is None or q_hasta is None:
        raise ErrorScraping('El texto del torneo no contiene la sección ===Qualification===.')
    if r_desde is None:
        raise ErrorScraping('El texto del torneo no contiene la sección ===Tournament ranking===.')
    if not any(re.match(r'==Group [A-L]==', l) for l in planteles):
        raise ErrorScraping('El texto de planteles no contiene los encabezados ==Group X==.')
    r_hasta = indice(torneo, lambda l: l.startswith('=='), r_desde + 1) or len(torneo) - 1

    # Clasificados: confederación del título anterior a cada código FIFA.
    clasificados, confederacion = [], None
    for linea in torneo[q_desde:q_hasta + 1]:
        confederacion = buscar(CONFEDERACION, linea) or confederacion
        if linea.startswith('*') and 'flag|fb|' in linea:
            clasificados.append((buscar(r'flag\|fb\|([A-Z]{3})', linea), confederacion))

    # Tabla final: posición según team_order (salvo posiciones compartidas) y resultados.
    posiciones, resultados = {}, {}
    for linea in torneo[r_desde:r_hasta + 1]:
        if linea.startswith('|team_order='):
            for n, codigo in enumerate(linea.split('=', 1)[1].split(','), 1):
                posiciones[codigo.strip()] = n
        elif linea.startswith('|win_'):
            codigo = buscar(r'win_([A-Z]{3})=', linea)
            resultados[codigo] = {campo: buscar(rf'{clave}_[A-Z]{{3}}=([0-9]+)', linea)
                                  for campo, clave in (('ganados', 'win'), ('empatados', 'draw'), ('perdidos', 'loss'),
                                                       ('goles_a_favor', 'gf'), ('goles_en_contra', 'ga'))}
    for linea in torneo[r_desde:r_hasta + 1]:
        if linea.startswith('|pos_'):
            for codigo, puesto in re.findall(r'pos_([A-Z]{3})=\{\{=\}\}([0-9]+)', linea):
                posiciones[codigo] = int(puesto)

    selecciones = [{'codigo': codigo, 'confederacion': conf, 'posicion': posiciones.get(codigo),
                    **resultados.get(codigo, dict.fromkeys(('ganados', 'empatados', 'perdidos',
                                                            'goles_a_favor', 'goles_en_contra')))}
                   for codigo, conf in clasificados]

    # Grupo de cada selección, por su nombre en la página de planteles (===Mexico=== dentro de ==Group A==).
    grupos, grupo = [], None
    for linea in planteles:
        if re.match(r'==Group [A-L]==', linea):
            grupo = linea[8]
        elif linea.startswith('===') and not linea.startswith('====') and grupo:
            grupos.append({'equipo': linea.replace('===', '').strip(), 'grupo': grupo})
    return selecciones, grupos


# ============================================================
# PLANTELES
# ============================================================

def scrapear_planteles(lineas):
    if not any(l.startswith('{{nat fs g player|') for l in lineas):
        raise ErrorScraping('El texto no contiene planteles ({{nat fs g player|...}}).')

    fecha = r'birth date and age2\|(?:[^|0-9][^|]*\|)?[0-9]+\|[0-9]+\|[0-9]+\|([0-9]+)\|([0-9]+)\|([0-9]+)'
    filas, equipo = [], None
    for linea in lineas:
        if linea.startswith('===') and not linea.startswith('===='):
            equipo = linea.replace('===', '').strip()
        elif linea.startswith('Coach:'):
            filas.append({'equipo': equipo, 'rol': 'DT', 'dorsal': None, 'posicion': None,
                          'nombre_completo': buscar(r'Coach:.*' + ENLACE, linea), 'nombre_orden': None,
                          'fecha_nacimiento': None, 'club': None})
        elif linea.startswith('{{nat fs g player|'):
            nacimiento = re.search(fecha, linea)
            filas.append({
                'equipo': equipo, 'rol': 'jugador',
                'dorsal': buscar(r'\|no=([^|}]*)', linea),
                'posicion': buscar(r'\|pos=([^|}]*)', linea),
                'nombre_completo': buscar(r'\|name=' + ENLACE, linea),
                'nombre_orden': buscar(r'\|sortname=([^|}]*)', linea),
                'fecha_nacimiento': (f'{nacimiento.group(1)}-{int(nacimiento.group(2)):02d}-{int(nacimiento.group(3)):02d}'
                                     if nacimiento else None),
                'club': buscar(r'\|club=' + ENLACE, linea),
            })
    return filas


# ============================================================
# EJECUCIÓN
# ============================================================

def guardar(carpeta, archivo, fuentes, clave, datos, extra=None):
    contenido = {'fuentes': [URL_PAGINA + p for p in fuentes],
                 'obtenido_en': datetime.now(timezone.utc).isoformat(timespec='seconds'),
                 clave: datos, **(extra or {})}
    ruta = carpeta / archivo
    ruta.write_text(json.dumps(contenido, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'{ruta}: {len(datos)} {clave}')


def main():
    parser = argparse.ArgumentParser(description='Scraping de Wikipedia del Mundial 2026 a imports/scraping/*.json')
    parser.add_argument('conjuntos', nargs='*', metavar='{sedes,selecciones,planteles}',
                        help='conjuntos a scrapear (por defecto, los tres)')
    parser.add_argument('--salida', type=Path, default=SALIDA, help=f'carpeta de salida (por defecto {SALIDA})')
    parser.add_argument('--pagina-torneo', default=PAGINA_TORNEO)
    parser.add_argument('--pagina-planteles', default=PAGINA_PLANTELES)
    args = parser.parse_args()
    conjuntos = args.conjuntos or ['sedes', 'selecciones', 'planteles']
    invalidos = set(conjuntos) - {'sedes', 'selecciones', 'planteles'}
    if invalidos:
        parser.error(f"conjunto inválido: {', '.join(sorted(invalidos))} (sedes, selecciones o planteles)")
    args.salida.mkdir(parents=True, exist_ok=True)

    paginas = {}   # cada página se descarga una sola vez

    def pagina(nombre):
        if nombre not in paginas:
            paginas[nombre] = obtener_wikitext(nombre)
        return paginas[nombre]

    errores = 0
    for conjunto in conjuntos:
        try:
            if conjunto == 'sedes':
                guardar(args.salida, 'sedes.json', [args.pagina_torneo], 'sedes',
                        scrapear_sedes(pagina(args.pagina_torneo)))
            elif conjunto == 'selecciones':
                selecciones, grupos = scrapear_selecciones(pagina(args.pagina_torneo), pagina(args.pagina_planteles))
                guardar(args.salida, 'selecciones.json', [args.pagina_torneo, args.pagina_planteles],
                        'selecciones', selecciones, {'grupos': grupos})
            else:
                guardar(args.salida, 'planteles.json', [args.pagina_planteles], 'planteles',
                        scrapear_planteles(pagina(args.pagina_planteles)))
        except ErrorScraping as e:
            print(f'{conjunto}: {e}', file=sys.stderr)
            errores += 1
    return 1 if errores else 0


if __name__ == '__main__':
    sys.exit(main())
