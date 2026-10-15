--!strict
-- Current UI language. Starts from the Roblox locale, then follows the saved preference from the
-- first snapshot. Toggling updates the UI immediately and asks the server to persist it.

local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared.Net)
local Locale = require(Shared.Util.Locale)
local Signal = require(Shared.Util.Signal)
local StateController = require(script.Parent.StateController)

local LocaleController = {}

LocaleController.Changed = Signal.new()

local lang = Locale.fromRobloxLocale(LocalizationService.RobloxLocaleId)
local adoptedSaved = false

function LocaleController.lang(): string
	return lang
end

function LocaleController.isRtl(): boolean
	return Locale.isRtl(lang)
end

function LocaleController.t(key: string, args: { [string]: any }?): string
	return Locale.get(lang, key, args)
end

local function set(newLang: string)
	newLang = Locale.normalize(newLang)
	if newLang ~= lang then
		lang = newLang
		LocaleController.Changed:Fire(lang)
	end
end

function LocaleController.toggle()
	local nextLang = if lang == "ar" then "en" else "ar"
	set(nextLang)
	Net.event(Net.Events.SetLanguage):FireServer(nextLang)
end

function LocaleController.start()
	StateController.Changed:Connect(function(snapshot)
		if not adoptedSaved then
			adoptedSaved = true
			if snapshot.language then
				set(snapshot.language)
			end
		end
	end)
end

return LocaleController
