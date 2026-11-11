# Entrega 9 - Dashboard en Power BI

Esta carpeta tiene el dashboard de la Entrega 9 (`dashboardmundial2026.pbix`). Se eligió **Power BI Desktop** y se conecta
directo a SQL Server (modo Importar) con el usuario `usr_bi`, que sólo puede leer el esquema `bi`: no ve las tablas ni
ejecuta procedimientos. La aplicación de ABM está en [../app/](../app/GUIA.md) y tiene su propia guía; las dos comparten
sólo la base.

| Archivo | Qué es |
|---|---|
| `../1_entrega9_sede_coordenadas.sql` | Agrega `latitud` y `longitud` a `torneo.sede` y las carga para las 16 sedes (mapa) |
| `../2_entrega9_vistas_bi.sql` | Esquema `bi` con cuatro vistas, el rol `bi_lector` y el usuario `usr_bi` |
| `../3_entrega9_test_bi.sql` | Pruebas de las vistas y de los permisos de `usr_bi` |
| `dashboardmundial2026.pbix` | Dashboard de Power BI |

## Preparar la base

Hay que tener la base `mundial_2026` con las entregas 5 a 9 cargadas. Conectarse como administrador del servidor y
ejecutar, en este orden: `entrega5` (1, 2, 3), `entrega6` (1, 2), `entrega7` (`1_entrega7_carga_datos.sql` y
`2_entrega7_reportes.sql`), `entrega8` (1, 2, 3) y `entrega9` (`1_entrega9_sede_coordenadas.sql` y
`2_entrega9_vistas_bi.sql`). El detalle está en la guía de la aplicación ([../app/GUIA.md](../app/GUIA.md)).

SQL Server tiene que aceptar **autenticación mixta** (Windows y SQL Server): en SSMS, clic derecho sobre el servidor >
*Propiedades > Seguridad > Modo de autenticación de SQL Server y Windows*, y reiniciar el servicio
*SQL Server (SQLEXPRESS)*.

## Tutorial: abrir el dashboard

**Necesita:** la base preparada (sección anterior) y Power BI Desktop (gratuito, sólo Windows).

1. Comprobar que el usuario `usr_bi` existe. Lo crea `2_entrega9_vistas_bi.sql` con la contraseña de prueba que figura en
   ese script.
2. Abrir `dashboardmundial2026.pbix` con Power BI Desktop.
3. Si aparece un aviso de que no hay credenciales, o los gráficos salen vacíos: **Inicio > Transformar datos >
   Configuración de origen de datos > Editar permisos**, elegir la pestaña **Base de datos** (no "Windows") e ingresar
   `usr_bi` y su contraseña. Si el servidor no es `.\SQLEXPRESS`, cambiarlo en **Cambiar origen**.
4. Apretar **Actualizar** (pestaña Inicio). Si pide cifrado, aceptar la conexión sin cifrar (certificado de prueba).

Los datos se leen de la base al actualizar: si se recrea la base o se importan datos nuevos, hay que volver a apretar
**Actualizar**. Para armar la conexión desde cero (archivo nuevo) ver "Detalle técnico del dashboard" más abajo: servidor,
modo Importar, las cuatro vistas del esquema `bi` y las relaciones del modelo.

**Problemas frecuentes**

| Síntoma | Causa y solución |
|---|---|
| Los gráficos salen vacíos | No se actualizó, o las credenciales son de Windows en lugar de `usr_bi` (paso 3) |
| `Login failed for user 'usr_bi'` | El servidor sólo acepta autenticación de Windows (ver "Preparar la base"), o la contraseña es incorrecta |
| No se puede conectar al servidor | Nombre de instancia distinto de `.\SQLEXPRESS`: cambiarlo en **Cambiar origen** |

---

## Detalle técnico del dashboard

El dashboard lee **directo de la base `mundial_2026`** (SQL Server), no de un archivo armado a mano. Se conecta con un
usuario de sólo lectura (`usr_bi`) que ve únicamente cuatro vistas del esquema `bi`.

### Scripts de la entrega

Sobre la base con las Entregas 5, 6, 7 y 8 cargadas, en este orden:

| Script | Qué hace |
|---|---|
| `1_entrega9_sede_coordenadas.sql` | Agrega `latitud` y `longitud` a `torneo.sede` y carga las 16 sedes |
| `2_entrega9_vistas_bi.sql` | Crea el esquema `bi` con las cuatro vistas, el rol `bi_lector` y el usuario `usr_bi` |
| `3_entrega9_test_bi.sql` | Comprueba las vistas y los permisos (5 pruebas, todas OK) |

### Las vistas y su relación con la Entrega 7

| Vista | Una fila por | Reproduce el reporte de la Entrega 7 | Se usa en |
|---|---|---|---|
| `bi.vw_goles` | gol | goleadores (`evento.reporte_goleadores`, XML) | gráfico de goles por selección |
| `bi.vw_ocupacion_publicitaria` | partido | ocupación publicitaria (`publicidad.reporte_ocupacion`) | gráfico de ingresos por sede |
| `bi.vw_partidos` | partido | resultados (`torneo.reporte_resultados`) | gráfico de asistencia por fase y tabla de resultados |
| `bi.vw_sedes` | sede | — (extensión de la Entrega 9) | mapa |

Power BI no lee los reportes XML ni las filas de subtotal de la Entrega 7, por eso las vistas entregan lo mismo en forma
de tabla. `3_entrega9_test_bi.sql` comprueba que los totales coinciden (73 goles y 9.370.000 USD facturados en el
reporte y en la vista).

### Seguridad: por qué `usr_bi` y no una cuenta de administrador

- El rol `bi_lector` tiene `SELECT` sólo sobre el esquema `bi` y `DENY` sobre las tablas y los SP de la aplicación.
- Las vistas leen las tablas por **encadenamiento de propiedad** (el dueño de ambas es `dbo`), como los SP de la
  Entrega 8: el usuario no necesita permisos sobre las tablas.
- Ninguna vista expone columnas cifradas.
- Se llama `bi_lector` y no `rol_...` porque `seguridad.crear_roles` (Entrega 8) borra los `rol_...` que no están en su
  cuadro, y este rol es de lectura (`SELECT`), no de ejecución (`EXECUTE`).

### Conexión desde Power BI Desktop

1. **Inicio → Obtener datos → SQL Server**.
2. Servidor: `.\SQLEXPRESS` (o el nombre de la instancia). Base de datos: `mundial_2026`. Modo: **Importar**.
3. Credenciales: pestaña **Base de datos** → usuario `usr_bi` y su contraseña (la de prueba está en
   `2_entrega9_vistas_bi.sql`; cambiarla antes de publicar). No usar la autenticación de Windows: entraría como
   administrador y se perdería el mínimo privilegio.
4. En el navegador, abrir el esquema `bi` y marcar las cuatro vistas. **Transformar datos** no hace falta.
5. Si pide cifrado, aceptar la conexión sin cifrar (instancia local con certificado de prueba).

### Modelo

Relaciones (vista de modelo), todas de uno a varios y con filtro en un solo sentido:

| Desde (uno) | Hacia (varios) |
|---|---|
| `vw_partidos[partido_id]` | `vw_goles[partido_id]` |
| `vw_partidos[partido_id]` | `vw_ocupacion_publicitaria[partido_id]` |
| `vw_sedes[sede_id]` | `vw_partidos[sede_id]` |

Columna calculada en `vw_partidos` para ordenar las fases del torneo en los ejes:

```dax
Orden fase =
SWITCH ( vw_partidos[fase],
    "grupos", 1, "dieciseisavos", 2, "octavos", 3, "cuartos", 4,
    "semifinal", 5, "tercer_puesto", 6, "final", 7 )
```

En Power BI, ordenar la columna `fase` por `Orden fase` (Herramientas de columna → Ordenar por columna).

Medidas:

```dax
Goles = CALCULATE ( COUNTROWS ( vw_goles ), vw_goles[cuenta_para_goleador] = 1 )
Partidos jugados = CALCULATE ( COUNTROWS ( vw_partidos ), vw_partidos[estado] = "finalizado" )
Asistencia total = SUM ( vw_partidos[asistencia_publico] )
Ingreso facturado (USD) = SUM ( vw_ocupacion_publicitaria[ingreso_facturado_usd] )
Ingreso estimado (USD) = SUM ( vw_ocupacion_publicitaria[ingreso_estimado_usd] )
```

`Goles` aplica el mismo criterio que el reporte de goleadores de la Entrega 7: no cuenta los goles en contra ni los
de la tanda de penales.

### Página del dashboard

| Elemento | Tipo | Campos |
|---|---|---|
| Indicadores | Tarjetas | `Goles`, `Partidos jugados`, `Asistencia total`, `Ingreso facturado (USD)` |
| **Gráfico 1**: goles por selección | Barras horizontales (las 10 primeras) | Eje: `vw_goles[seleccion]`; Valor: `Goles` |
| **Gráfico 2**: ingresos publicitarios por sede | Columnas agrupadas | Eje: `vw_sedes[sede]`; Valores: `Ingreso facturado (USD)` e `Ingreso estimado (USD)` |
| **Gráfico 3**: asistencia por fase | Líneas | Eje: `vw_partidos[fase]` (ordenada); Valor: promedio de `asistencia_publico` |
| **Mapa de sedes** | Mapa (burbujas) | Latitud: `vw_sedes[latitud]`; Longitud: `vw_sedes[longitud]`; Tamaño: `Asistencia total`; Descripción: `vw_sedes[sede]` |
| Reporte de resultados | Tabla | `vw_partidos`: `fase`, `fecha_hora_local`, `sede`, `local`, `goles_local`, `goles_visitante`, `visitante`, `estado` |
| Filtros | Segmentaciones | `vw_partidos[fase]` y `vw_sedes[pais]` |

El enunciado pide al menos dos gráficos y un reporte de la Entrega 7: acá hay tres gráficos, el mapa opcional y el
reporte de resultados.

### Actualizar los datos

Después de cargar o cambiar datos en la base: **Inicio → Actualizar**. Power BI vuelve a leer las vistas.

### Archivo del dashboard

El dashboard es `src/entrega9/power_bi/dashboardmundial2026.pbix`. El archivo no contiene la
contraseña: Power BI la pide de nuevo en otra máquina.
