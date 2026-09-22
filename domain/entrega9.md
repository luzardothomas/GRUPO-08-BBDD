# Análisis — Entrega 9 (Cierre: BI, visualización y aplicación)

## Qué pide el enunciado

1. Repasar la sección "2. Alcance / To-Be" del TP y asegurarse de que **todas** las consultas necesarias para
   cumplirla existan (esto es, en la práctica, una auditoría final de cobertura contra los módulos A–J).
2. Incorporar una **plataforma de BI** (Power BI, Metabase u otra, local o en la nube) y presentar allí al menos
   uno de los reportes de la Entrega 7.
3. Opcional: mapa de sedes usando geolocalización (latitud/longitud).
4. Al menos **dos gráficos** representativos (barras, líneas, tortas, etc.).
5. Una **aplicación simple** en el lenguaje que elija el grupo, con ABM sobre al menos una tabla.
6. Opcional: pantalla de importación de archivos (reutilizando la lógica de la Entrega 6) + visualización de un
   reporte de la Entrega 7 (guardando como mínimo el XML).

Esta es la única entrega donde el enunciado explícitamente **no exige un motor ni lenguaje específico** para la
capa de presentación (BI, aplicación), aunque la fuente de datos sigue siendo obligatoriamente la base SQL Server
construida en las entregas anteriores. Es el punto donde más conviene remarcar que el diseño relacional de fondo
(vistas, SP, esquema) es el mismo sin importar qué herramienta de BI o lenguaje de aplicación se elija encima.

## 1. Auditoría de cobertura contra el "To-Be"

Conviene armar una tabla de trazabilidad, punto por punto de la sección 2 del TP (A. Sedes y Partidos, B.
Selecciones y Convocatoria, ..., J. Proyección y Análisis), indicando qué objeto de la base (tabla, vista, SP)
resuelve cada requisito. Esto no es solo para el informe: es la forma más directa de detectar, antes del cierre,
si quedó algún requisito del enunciado sin cubrir por ningún objeto (por ejemplo, si nunca se implementó el filtro
de fixture por fase/sede/selección/fecha pedido explícitamente en el módulo A, o si falta el SP de "reconstruir el
equipo en cancha en un minuto dado" del módulo D).

## 2. Plataforma de BI

- La condición central del enunciado es que **los datos provengan de la base SQL**, idealmente por conexión
  directa (Power BI con conector nativo de SQL Server, o Metabase apuntando directo a la instancia) y, si no es
  posible, por exportación/importación puntual — pero documentando que el origen sigue siendo la base relacional
  y no un dataset paralelo mantenido a mano.
- Conceptualmente, este paso es la demostración de que el modelo relacional diseñado en las entregas anteriores es
  **consumible** por una herramienta externa sin necesidad de rehacer la lógica: si un reporte de la Entrega 7 ya
  existe como vista o como resultado de un SP, la plataforma de BI solo tiene que apuntar a ese objeto.
- Elegir un reporte con variación suficiente para que el gráfico sea informativo (ej. goleadores por selección, o
  tarjetas acumuladas por selección) en vez de uno prácticamente plano.

## 3. Mapa de sedes (opcional)

Requiere agregar columnas de latitud/longitud a `sede` (no presentes en el esquema actual — extensión menor del
modelo). El dato puede obtenerse por geocodificación manual (nombre de ciudad/estadio → coordenadas) o vía alguna
de las APIs ya usadas en la Entrega 6, y visualizarse con el soporte de mapas nativo de la herramienta de BI
elegida (Power BI tiene visual de mapa; Metabase también soporta mapas si hay lat/long).

## 4. Gráficos

Mínimo dos, representativos de algún reporte real (no datos inventados para el gráfico). Candidatos directos
dado el modelo: goleadores del torneo (barras), evolución de asistencia de público por fase (líneas), distribución
de ingresos publicitarios por sede (torta o barras apiladas).

## 5. Aplicación simple de ABM

- El enunciado da libertad total de lenguaje/framework. La decisión debe basarse en lo que el grupo ya maneja,
  ya que el objetivo académico de este punto es demostrar que la capa de aplicación **usa los SP existentes**
  (no reimplementa la lógica de validación del lado del cliente) — es la prueba de que el diseño de "todo el ABM
  encapsulado en SP" de la Entrega 5 realmente desacopla la lógica de negocio de la interfaz.
- Elegir una tabla con ABM relativamente autocontenido y visible para la demo (ej. `anunciante` o `campania` son
  buenas candidatas: pocas dependencias, fácil de mostrar alta/baja/modificación en vivo durante el coloquio).
- La aplicación debe conectarse con un usuario mapeado a alguno de los roles de la Entrega 8 (no con una cuenta de
  administrador), para reforzar también la demostración de seguridad granular.

## 6. Pantalla de importación (opcional)

Si se implementa, debe reutilizar el mismo SP de importación de la Entrega 6 (no una reimplementación paralela en
el lenguaje de la aplicación), y como mínimo guardar/mostrar el XML de alguno de los reportes de la Entrega 7 —
cerrando el circuito completo: importación → persistencia vía SP → reporte → visualización.

## Nota de cierre

Esta entrega es, en términos de la materia, la demostración de que el diseño relacional (Entregas 3–5) sostiene
tanto la explotación analítica (BI) como la operación transaccional (aplicación ABM) sin necesidad de lógica
duplicada fuera de la base. Vale la pena que el informe lo señale explícitamente como conclusión, en lugar de
presentar BI y aplicación como entregables aislados.
