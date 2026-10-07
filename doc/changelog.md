# Changelog

En este documento se va a documentar todos los cambios realizados al modelo a partir de las revisiones que haga el cliente.
Al principio siempre va a estar la fecha más actual, y en la misma está la observación del cliente y la solución que se utilizó para resolver el problema.

---

## [02-10-2026]

### 1. Bucles de relaciones entre entidades

#### Observación del cliente

El cliente indicó que el modelo tenía relaciones que formaban bucles: una selección juega un partido (de local o de visitante) y ese partido tiene formaciones, pero la selección también estaba relacionada directamente con la formación. Al poder llegar al mismo dato por dos caminos distintos, el modelo permitía registrar información contradictoria, como una formación de una selección que no juega ese partido. Lo mismo ocurría con los goles, las sustituciones y las tarjetas, que se relacionaban a la vez con el partido, con la selección y con el jugador.

#### Solución adoptada

Se eliminaron las relaciones redundantes, dejando un único camino para llegar a cada dato:

- **Formación**: ya no se relaciona con la selección. Se agregó el atributo **condicion**, que indica si corresponde al equipo `local` o al `visitante` del partido; la selección se obtiene a partir del partido.
- **Sustitución** y **Gol**: ya no se relacionan directamente con el partido, la selección ni el jugador. Pasan a relacionarse con el jugador dentro de la formación de ese partido (**Formación Jugador**), de donde se obtienen el partido y la selección. Un gol en contra se registra en la formación de su autor y cuenta para la selección rival.
- **Tarjeta**: ya no se relaciona con la selección, que se obtiene a partir de la persona que la recibe. Mantiene su relación con el partido porque el cuerpo técnico no forma parte de la formación.

Se eligió esta alternativa, en lugar de conservar ambas relaciones y validar su coincidencia en cada carga, para que la inconsistencia no pueda existir en el modelo. Además, queda garantizado que quien convierte, asiste, entra o sale en un partido figura en la formación de ese partido.

Los bucles restantes se conservaron porque cada camino representa un dato distinto: por ejemplo, el partido en el que se muestra una tarjeta y el partido que se pierde por la suspensión, o el país de la sede y el país de la selección.

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
