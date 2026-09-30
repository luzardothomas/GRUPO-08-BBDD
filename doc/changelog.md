# Changelog

En este documento se va a documentar todos los cambios realizados al modelo a partir de las revisiones que haga el cliente.
Al principio siempre va a estar la fecha más actual, y en la misma está la observación del cliente y la solución que se utilizó para resolver el problema.

---

## [25-09-2026]

### 1. Sanciones al cuerpo técnico

#### Observación del cliente

El cliente indicó que los integrantes del cuerpo técnico también tienen la posibilidad de llegar a recibir algún tipo de sanción, y por lo tanto ser suspendidos.

#### Solución adoptada

Se incorporó la entidad **Persona**, que agrupa a jugadores e integrantes del cuerpo técnico bajo un mismo identificador. Las sanciones pasan a asignarse a una persona, independientemente de su rol.
Se eligió esta alternativa, en lugar de agregar a la tarjeta una segunda referencia opcional al cuerpo técnico, para que cada tarjeta tenga siempre un único destinatario obligatorio y la acumulación de amarillas se calcule de la misma forma para todos.

### 2. Tiempo del partido en que se muestra una tarjeta

#### Observación del cliente

El cliente indicó que con el minuto de la tarjeta no se podía determinar en qué tiempo del partido fue mostrada: si en el primer tiempo o su tiempo adicional, en el segundo tiempo o su tiempo adicional, o en alguno de los dos tiempos de 15 minutos del alargue o sus respectivos tiempos adicionales. También debía contemplarse que se puedan mostrar tarjetas durante la tanda de penales.

#### Solución adoptada

Se agregó a la entidad **Tarjeta** el atributo **periodo**, obligatorio, que indica en qué tiempo del partido se mostró la tarjeta. Solo admite los siguientes valores:

| Valor | Tiempo del partido |
|---|---|
| `PT` | Primer tiempo |
| `adicional_PT` | Tiempo adicional del primer tiempo |
| `ST` | Segundo tiempo |
| `adicional_ST` | Tiempo adicional del segundo tiempo |
| `alargue_1` | Primer tiempo del alargue |
| `adicional_alargue_1` | Tiempo adicional del primer tiempo del alargue |
| `alargue_2` | Segundo tiempo del alargue |
| `adicional_alargue_2` | Tiempo adicional del segundo tiempo del alargue |
| `penales` | Tanda de penales |

El minuto se conserva y se interpreta junto con el período, lo que permite distinguir por ejemplo, una tarjeta en el minuto 45 del primer tiempo de otra en el tiempo adicional de ese mismo tiempo.
