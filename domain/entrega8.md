# Análisis — Entrega 8 (Seguridad y Respaldo)

## Qué pide el enunciado

1. **Cifrado** de datos sensibles (datos personales de jugadores, cuerpos técnicos y árbitros), aplicado como
   script de **modificación** sobre los objetos existentes (tablas, SP, consultas) — no como rediseño desde cero.
   Advertencia explícita del enunciado: el testing de entregas previas puede dejar de pasar una vez aplicado el
   cifrado, y eso es esperable.
2. **Roles**: al menos 3 roles de seguridad (ej. administrador, cargador de resultados, gestor de publicidad,
   consulta) con permisos granulares, documentados en un cuadro. Con script de test por usuario/rol que demuestre
   qué puede y qué no puede hacer.
3. **Backup**: política de respaldo (RPO) documentada, considerando el pico de escritura en días de partido.
4. Cifrado y roles se implementan con **código (SP)**; el backup se documenta (no necesariamente se scriptea todo).

## Cifrado de datos sensibles

### Qué campos caen bajo "datos sensibles"

Sobre el modelo actual, los candidatos son: `jugador.nombre/apellido/fecha_nacimiento`, `cuerpo_tecnico.nombre/
apellido`, `arbitro.nombre/apellido`. El enunciado no pide cifrar datos operativos (goles, tarjetas, resultados),
solo **datos personales**, en línea con un criterio de protección de datos (equivalente académico a por qué se
cifran PII en cualquier sistema real, más allá del motor).

### Encuadre conceptual vs. implementación

El concepto de "cifrado a nivel de columna" es motor-agnóstico (columnar encryption / encryption at rest), pero el
mecanismo concreto es propio de cada RDBMS: SQL Server ofrece cifrado simétrico nativo (`CREATE SYMMETRIC KEY`,
`ENCRYPTBYKEY`/`DECRYPTBYKEY`) o `Always Encrypted`. Dado que el enunciado prohíbe herramientas externas y CLR
(restricción heredada de la Entrega 5) y pide que se implemente "como script de modificación... sobre los
componentes existentes", el camino más directo y documentable es:

1. Crear una `MASTER KEY` de base de datos y un `CERTIFICATE`/`SYMMETRIC KEY` para proteger las columnas sensibles.
2. Agregar columnas `VARBINARY` cifradas junto a (o en reemplazo de) las columnas planas actuales, migrando los
   datos existentes con un script de `UPDATE` que cifre lo ya cargado.
3. Modificar los SP de ABM de la Entrega 5 para que el `INSERT`/`UPDATE` cifren el valor de entrada
   (`ENCRYPTBYKEY(KEY_GUID(...), CONVERT(VARBINARY, @nombre))`) y los SP de consulta/reportes para que
   descifren (`DECRYPTBYKEY(...)`) solo para los roles autorizados a ver el dato en claro.
4. Actualizar los scripts de testing de la Entrega 5 que dependían de comparar el valor plano — esto es
   exactamente la advertencia que hace el enunciado, y conviene mostrarla explícitamente en el informe como
   evidencia de haber entendido el impacto (antes/después).

## Roles y permisos

### Diseño de roles sugerido

| Rol | Descripción | Permisos típicos |
|---|---|---|
| `rol_administrador` | Gestión total del sistema | `EXEC` sobre todos los SP, `SELECT` sobre todas las tablas (incluye datos cifrados si tiene la clave), DDL |
| `rol_cargador_resultados` | Carga partidos, goles, tarjetas, sustituciones | `EXEC` solo sobre los SP de los módulos A, C, D, E, F; sin acceso a SP de publicidad ni a las claves de cifrado |
| `rol_gestor_publicidad` | Administra anunciantes, campañas y asignación de espacios | `EXEC` solo sobre SP del módulo H; sin acceso a datos personales cifrados |
| `rol_consulta` | Solo lectura de reportes | `EXEC` únicamente sobre los SP de reporte de la Entrega 7, sin acceso a SP de ABM ni a las claves de descifrado |

Este diseño respeta dos principios generales de seguridad en bases de datos (no exclusivos de SQL Server): **acceso
exclusivamente vía interfaz controlada** (SP, ya impuesto desde la Entrega 5 — ningún rol tiene `GRANT` directo
sobre tablas) y **separación de funciones** (ningún rol operativo tiene alcance total).

### Implementación

En términos ANSI-SQL, la base es `CREATE ROLE`, `GRANT EXECUTE ON ... TO ...`, `REVOKE`. En SQL Server esto se
traduce a `CREATE ROLE` a nivel de base de datos + `GRANT EXECUTE ON OBJECT::<sp> TO <rol>` + asignación de
logins/usuarios a roles con `ALTER ROLE ... ADD MEMBER`. El cuadro de permisos pedido por el enunciado debe
mostrar, por cada rol, la lista completa de SP a los que tiene `EXEC` y explícitamente cuáles **no**.

### Testing de permisos

Por cada rol, crear un login/usuario de prueba, loguearse con ese usuario (`EXECUTE AS USER = '...'` en SQL
Server) e intentar tanto las operaciones permitidas (deben tener éxito) como una operación fuera de su alcance
(debe fallar con error de permisos, no con error de lógica de negocio) — esto demuestra que el control es a nivel
de motor y no delegado a la aplicación cliente.

## Política de backup (RPO)

Documento aparte (no necesariamente código), que debería cubrir:
- **RPO objetivo**: cuánta pérdida de datos es tolerable. Dado que el enunciado aclara que el volumen de escritura
  sube fuertemente en horario de partidos, conviene diferenciar la política **en días de partido** (backups de log
  más frecuentes, p. ej. cada 5–15 minutos) de la política en días sin partidos (full diario + log cada hora es
  suficiente).
- **Tipos de backup**: full periódico + diferencial + log de transacciones, con la frecuencia de cada uno
  justificada en función del RPO elegido.
- **Retención y ubicación**: dónde se guardan los backups (fuera del mismo disco que los datos, como mínimo), por
  cuánto tiempo se retienen.
- **Prueba de restore**: mencionar que una política de backup sin prueba de restauración periódica no garantiza
  nada — es un punto que suele valorarse en la corrección aunque el enunciado no lo pida palabra por palabra.

Este documento es, en esencia, independiente del motor (todo RDBMS transaccional distingue full/diferencial/log o
equivalente), aunque al citar comandos concretos (`BACKUP DATABASE`, `BACKUP LOG`) se está usando sintaxis de SQL
Server.
