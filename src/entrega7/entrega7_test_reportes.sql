-- ============================================================
-- UNIVERSIDAD NACIONAL DE LA MATANZA
-- MATERIA: 3641 - Bases de Datos Aplicada (Comisión 02-5600)
-- TRABAJO PRÁCTICO: Sistema de registro y gestión del mundial de fútbol
-- ENTREGA 7: Ejecución de Reportes (Test)
--
-- INTEGRANTES:
--   LUZARDO, THOMAS GASTON
--   EKSZTEIN ROLON, JEREMIAS OCTAVIO
--   REPRESAS PANOZZO, GERÓNIMO
--   LARAN, JEAN PIERRE
--
-- DESCRIPCIÓN:
--   Script de prueba para invocar y visualizar los resultados de 
--   los 7 procedimientos almacenados correspondientes a los reportes.
-- ============================================================

USE mundial_2026;
GO

-- ============================================================
-- REPORTE 1: Goleadores por selección, fase y torneo (XML)
-- ============================================================
EXEC evento.ReporteGoleadoresXML;
GO

-- ============================================================
-- REPORTE 2: Selecciones y plantillas (XML)
-- ============================================================
EXEC plantel.ReportePlantillasXML;
GO

-- ============================================================
-- REPORTE 3: Tarjetas por selección y jugador, con suspensiones activas
-- ============================================================
EXEC evento.ReporteTarjetasYSuspensiones;
GO

-- ============================================================
-- REPORTE 4: Designaciones arbitrales e historial disciplinario
-- ============================================================
EXEC arbitraje.ReporteDesignacionesArbitrales;
GO

-- ============================================================
-- REPORTE 5: Ocupación publicitaria e ingresos generados
-- ============================================================
EXEC publicidad.ReporteOcupacionPublicitaria;
GO

-- ============================================================
-- REPORTE 6: Matriz de Prime Time (PIVOT)
-- ============================================================
EXEC torneo.ReporteMatrizPrimeTime;
GO

-- ============================================================
-- REPORTE 7: Resultados de los encuentros
-- ============================================================
EXEC torneo.ReporteResultados;
GO