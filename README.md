<div align="center">

# 🎯 Smart Cast

**Mouseover casting without a single macro.**

Hover an enemy and your attack goes there. Hover a friend and your heal goes there. Right-click a heal and it lands on you. Your target never changes.

![WoW 3.3.5a](https://img.shields.io/badge/WoW-3.3.5a%20(WotLK)-8a2be2)
![Interface 30300](https://img.shields.io/badge/Interface-30300-blue)
![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green)

[Leer en español](README.es.md)

</div>

---

Everybody ends up writing the same macro forty times: `/cast [@mouseover,harm,nodead][] Fireball`. It eats your macro slots, every spell needs its own icon, and a new rank or a new spec means doing it again.

**Smart Cast** puts that behaviour straight on your action bar buttons, and you choose which spells get it.

## ✨ What it does

| When you press a marked spell… | it is cast on |
|---|---|
| ⚔️ harmful spell, mouse over an **enemy** | the enemy under your mouse |
| 💚 helpful spell, mouse over a **friend** (also on party and raid frames, also dead: resurrections work) | the friend under your mouse |
| 🖱️ helpful spell, **right-click** on the button | you |
| ⌨️ helpful spell + **Alt** (configurable) | you |
| 🎯 any marked spell + **focus key** (off by default) | your focus |
| anything else | your target, exactly as usual |

- **Works in combat** and with keybindings, not only with mouse clicks.
- **Uses no macros** — your 18 + 36 macro slots stay free.
- **Per spec**: what you mark on your healing spec doesn't change your damage spec.
- **Automatic first choice**: every harmful spell and every helpful spell that can be cast on someone else starts marked. Self-only buffs don't. You only fix the exceptions.
- **Small dots** on marked buttons (green helpful, red harmful) so you always know which ones follow the mouse.
- Blizzard's action bars, including stance and stealth bars, and **Bartender4**. In vehicles the game's own controls are left alone.
- English and Spanish (`esES` / `esMX`).

## 🖱️ Choosing your spells

1. Type `/smartcast` (or click the minimap button). Your bars turn grey.
2. **Click** a button to mark or unmark its spell. Marked spells glow green (helpful) or red (harmful).
3. **Right-click** a button to put it back to the automatic choice.
4. Click **Done**.

The selection mode only works out of combat (the game doesn't let addons change action buttons in combat) and closes itself if a fight starts.

## ⌨️ Commands

| Command | What it does |
|---|---|
| `/smartcast` | Open / close the selection mode |
| `/smartcast on` \| `off` | Turn Smart Cast on or off |
| `/smartcast self alt\|ctrl\|shift\|off` | Key + helpful spell = cast on yourself (default **Alt**) |
| `/smartcast focus alt\|ctrl\|shift\|off` | Key + marked spell = cast on your focus (default off) |
| `/smartcast markers` | Show / hide the dots on marked buttons |
| `/smartcast reset` | Every spell of this spec back to the automatic choice |
| `/smartcast minimap` | Show / hide the minimap button |

`/scast` works too.

## 🧠 How it works

Action buttons are *secure*: in combat no addon may change what they do. Smart Cast prepares a list of marked slots out of combat and adds a small secure snippet to each button. On every press, the snippet looks at the unit under your mouse and tells the button where to cast — just for that press, inside the game's own rules. Because Blizzard's default keybindings skip the button's click handler, Smart Cast re-points the same keys to clicks on the same buttons (and hands them back to the game in vehicles).

Nothing is automated: you still press every spell yourself.

## 📦 Installation

1. Download the latest release and unzip it into `World of Warcraft/Interface/AddOns/`. The folder must be called `SmartCast` (`Interface/AddOns/SmartCast/SmartCast.toc`).
2. At the character screen, click **AddOns** and make sure Smart Cast is enabled.

Part of the [Stormrage](https://stormrage-server.com) addon family, with [Soulstone](https://github.com/pabhoz/Soulstone-WoW-Addon) and [Tactics Coach](https://github.com/pabhoz/TacticsCoach-WoW-Addon). Works on any 3.3.5a server.

## 📜 License

GPL-3.0-or-later. See [LICENSE](LICENSE).
