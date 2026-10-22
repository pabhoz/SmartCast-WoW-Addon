-- Smart Cast - mouseover casting without macros for WoW 3.3.5a.
-- Copyright (C) 2026 pabhoz - https://github.com/pabhoz/SmartCast-WoW-Addon
-- Licensed under the GNU General Public License v3.0 or later. See LICENSE.

SmartCast = {}

local L = setmetatable({}, { __index = function(_, k) return k end })
SmartCast.L = L

local locale = GetLocale()
if locale == "esES" or locale == "esMX" then
	L["On: marked spells follow your mouse."] = "Encendido: los hechizos marcados siguen a tu mouse."
	L["Off: your bars work as usual."] = "Apagado: tus barras funcionan como siempre."
	L["Not possible in combat."] = "No se puede en combate."
	L["Friend under the mouse; right-click on you"] = "Aliado bajo el mouse; clic derecho sobre ti"
	L["Enemy under the mouse"] = "Enemigo bajo el mouse"
	L["Not a spell with a target: can't follow the mouse"] = "No es un hechizo con objetivo: no puede seguir al mouse"
	L["%d spells marked on your bars (spec %d)"] = "%d hechizos marcados en tus barras (spec %d)"
	L["Marked: follows the mouse"] = "Marcado: sigue al mouse"
	L["Not marked: works as usual"] = "Sin marcar: funciona como siempre"
	L["Automatic choice: %s"] = "Eleccion automatica: %s"
	L["marked"] = "marcado"
	L["not marked"] = "sin marcar"
	L["Click: mark / unmark.  Right-click: back to automatic."] = "Clic: marcar / desmarcar.  Clic derecho: volver a lo automatico."
	L["Empty or not a spell"] = "Vacio o no es un hechizo"
	L["Smart Cast: choose your spells"] = "Smart Cast: elige tus hechizos"
	L["All automatic"] = "Todo automatico"
	L["None"] = "Ninguno"
	L["Done"] = "Listo"
	L["Smart Cast is off: what you mark applies when you turn it on (/smartcast on)."] = "Smart Cast esta apagado: lo que marques se aplica cuando lo enciendas (/smartcast on)."
	L["Selection mode closed: you entered combat."] = "Modo seleccion cerrado: entraste en combate."
	L["On"] = "Encendido"
	L["Off"] = "Apagado"
	L["Self cast key: %s"] = "Tecla para lanzar sobre ti: %s"
	L["Focus cast key: %s"] = "Tecla para lanzar sobre tu foco: %s"
	L["none"] = "ninguna"
	L["Left-click: choose spells\nRight-click: turn on/off"] = "Clic izquierdo: elegir hechizos\nClic derecho: encender/apagar"
	L["Mouseover casting without macros"] = "Lanzar sobre el mouse sin macros"
	L["Choose spells"] = "Elegir hechizos"
	L["Turn on/off"] = "Encender/apagar"
	L["Use: alt, ctrl, shift or off."] = "Usa: alt, ctrl, shift u off."
	L["Markers shown."] = "Marcas visibles."
	L["Markers hidden."] = "Marcas ocultas."
	L["Every spell of this spec is back to the automatic choice."] = "Todos los hechizos de este spec vuelven a la eleccion automatica."
	L["Commands:"] = "Comandos:"
	L["choose which spells follow the mouse"] = "elige que hechizos siguen al mouse"
	L["turn Smart Cast on or off"] = "enciende o apaga Smart Cast"
	L["key + spell = on you"] = "tecla + hechizo = sobre ti"
	L["key + spell = on your focus"] = "tecla + hechizo = sobre tu foco"
	L["show / hide the dots on marked buttons"] = "muestra / oculta los puntos de los botones marcados"
	L["back to the automatic choice"] = "vuelve a la eleccion automatica"
	L["show / hide the minimap button"] = "muestra / oculta el boton del minimapa"
end
