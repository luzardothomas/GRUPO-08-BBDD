# Changelog

En este documento se va a documentar todos los cambios realizados al modelo a partir de las revisiones que haga el cliente.
Al principio siempre va a estar la fecha más actual, y en la misma está la observación del cliente y la solución que se utilizó para resolver el problema.

---

## [25-09-2026] Sanciones al cuerpo técnico

### Observación del cliente

El cliente indicó que los integrantes del cuerpo técnico también tienen la posibilidad de llegar a recibir algún tipo de sanción, y por lo tanto ser suspendidos.

### Solución adoptada

Se incorporó la entidad **Persona**, que agrupa a jugadores e integrantes del cuerpo técnico bajo un mismo identificador. Las sanciones pasan a asignarse a una persona, independientemente de su rol.
Se eligió esta alternativa, en lugar de agregar a la tarjeta una segunda referencia opcional al cuerpo técnico, para que cada tarjeta tenga siempre un único destinatario obligatorio y la acumulación de amarillas se calcule de la misma forma para todos.
