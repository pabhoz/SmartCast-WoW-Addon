<div align="center">

# 🎯 Smart Cast

**Lanzar sobre el mouse sin un solo macro.**

Pasa el mouse sobre un enemigo y tu ataque va ahí. Sobre un aliado, y tu curación va ahí. Clic derecho en una curación y cae sobre ti. Tu objetivo nunca cambia.

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a%20(WotLK)-8a2be2)
![Interface 30300](https://img.shields.io/badge/Interface-30300-blue)
![Licencia: GPL v3](https://img.shields.io/badge/Licencia-GPLv3-green)

[Read in English](README.md)

</div>

---

Todos terminamos escribiendo el mismo macro cuarenta veces: `/cast [@mouseover,harm,nodead][] Bola de Fuego`. Se come tus espacios de macros, cada hechizo necesita su propio icono, y un rango nuevo o un spec nuevo significa hacerlo otra vez.

**Smart Cast** pone ese comportamiento directo en los botones de tus barras, y tú eliges qué hechizos lo tienen.

## ✨ Qué hace

| Cuando pulsas un hechizo marcado… | se lanza sobre |
|---|---|
| ⚔️ hechizo de daño, mouse sobre un **enemigo** | el enemigo bajo tu mouse |
| 💚 hechizo de ayuda, mouse sobre un **aliado** (también en los marcos de grupo y de banda, y muertos: las resurrecciones funcionan) | el aliado bajo tu mouse |
| 🖱️ hechizo de ayuda, **clic derecho** en el botón | ti |
| ⌨️ hechizo de ayuda + **Alt** (configurable) | ti |
| 🎯 cualquier hechizo marcado + **tecla de foco** (apagada al empezar) | tu foco |
| cualquier otro caso | tu objetivo, como siempre |

- **Funciona en combate** y con tus teclas, no solo con clics.
- **No usa macros**: tus 18 + 36 espacios de macros quedan libres.
- **Por spec**: lo que marcas en tu spec de curación no cambia tu spec de daño.
- **Primera elección automática**: todos los hechizos de daño y los de ayuda que se pueden lanzar sobre otro empiezan marcados. Los bufos que son solo para ti, no. Tú solo corriges las excepciones.
- **Puntos pequeños** en los botones marcados (verde ayuda, rojo daño) para saber siempre cuáles siguen al mouse.
- Barras de Blizzard, incluidas las de actitud y sigilo, y **Bartender4**. En vehículos los controles del juego quedan como están.
- Inglés y español (`esES` / `esMX`).

## 🖱️ Elegir tus hechizos

1. Escribe `/smartcast` (o haz clic en el botón del minimapa). Tus barras se ponen en gris.
2. **Clic** en un botón para marcar o desmarcar su hechizo. Los marcados brillan en verde (ayuda) o en rojo (daño).
3. **Clic derecho** en un botón para devolverlo a la elección automática.
4. Pulsa **Listo**.

El modo selección solo funciona fuera de combate (el juego no deja que los addons cambien los botones en combate) y se cierra solo si empieza una pelea.

## ⌨️ Comandos

| Comando | Qué hace |
|---|---|
| `/smartcast` | Abre / cierra el modo selección |
| `/smartcast on` \| `off` | Enciende o apaga Smart Cast |
| `/smartcast self alt\|ctrl\|shift\|off` | Tecla + hechizo de ayuda = sobre ti (por defecto **Alt**) |
| `/smartcast focus alt\|ctrl\|shift\|off` | Tecla + hechizo marcado = sobre tu foco (apagada por defecto) |
| `/smartcast markers` | Muestra / oculta los puntos de los botones marcados |
| `/smartcast reset` | Todos los hechizos de este spec vuelven a lo automático |
| `/smartcast minimap` | Muestra / oculta el botón del minimapa |

También sirve `/scast`.

## 🧠 Cómo funciona

Los botones de acción son *seguros*: en combate ningún addon puede cambiar lo que hacen. Smart Cast prepara fuera de combate la lista de espacios marcados y le agrega a cada botón un pequeño fragmento seguro. En cada pulsación, ese fragmento mira la unidad bajo tu mouse y le dice al botón dónde lanzar, solo para esa pulsación y dentro de las reglas del juego. Como las teclas de Blizzard se saltan el clic del botón, Smart Cast apunta esas mismas teclas a clics sobre los mismos botones (y se las devuelve al juego en los vehículos).

Nada está automatizado: cada hechizo lo pulsas tú.

## 📦 Instalación

1. Descarga la última versión y descomprímela en `World of Warcraft/Interface/AddOns/`. La carpeta tiene que llamarse `SmartCast` (`Interface/AddOns/SmartCast/SmartCast.toc`).
2. En la pantalla de personajes, botón **AddOns**, y comprueba que Smart Cast está activado.

Parte de la familia de addons de [Stormrage](https://stormrage-server.com), con [Soulstone](https://github.com/pabhoz/Soulstone-WoW-Addon) y [Tactics Coach](https://github.com/pabhoz/TacticsCoach-WoW-Addon). Funciona en cualquier servidor 3.3.5a.

## 📜 Licencia

GPL-3.0 o posterior. Ver [LICENSE](LICENSE).
