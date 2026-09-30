# Changelog

**Bases de Datos Aplicadas · Comisión 02-5600 · Grupo 08**

Registro de los cambios aplicados al modelo de datos a partir de las revisiones del cliente.
Arriba de todo se encuentra la fecha más actual, y en la misma está la observación del cliente y la solución propuesta para adaptar el modelo.

---

## [2026-09-30] Sanciones al cuerpo técnico: incorporación de la entidad Persona

### Observación del cliente

El cliente indicó que los integrantes del cuerpo técnico también tienen la posibilidad de llegar a recibir algún tipo de sanción, y por lo tanto ser suspendidos.

### Solución adoptada

Se incorporó la entidad **Persona**, que agrupa a jugadores e integrantes del cuerpo técnico bajo un mismo identificador. Las sanciones pasan a asignarse a una persona, independientemente de su rol.
Se eligió esta alternativa, en lugar de agregar a la tarjeta una segunda referencia opcional al cuerpo técnico, para que cada tarjeta tenga siempre un único destinatario obligatorio y la acumulación de amarillas se calcule de la misma forma para todos.