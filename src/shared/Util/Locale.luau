--!strict
-- String lookup and {placeholder} formatting. Pure apart from reading the Strings config.

local Strings = require(script.Parent.Parent.Config.Strings)

local Locale = {}

function Locale.normalize(lang: string?): string
	if lang == "ar" then
		return "ar"
	end
	return "en"
end

-- Maps a Roblox locale id (e.g. "ar-sa", "en-us") to a supported language.
function Locale.fromRobloxLocale(localeId: string): string
	if string.sub(string.lower(localeId), 1, 2) == "ar" then
		return "ar"
	end
	return "en"
end

function Locale.isRtl(lang: string): boolean
	return Strings.rtl[lang] == true
end

function Locale.get(lang: string, key: string, args: { [string]: any }?): string
	local tbl = (Strings :: any)[Locale.normalize(lang)] or Strings.en
	local s = tbl[key] or Strings.en[key] or key
	if args then
		s = string.gsub(s, "{(%w+)}", function(name)
			local v = args[name]
			return if v ~= nil then tostring(v) else "{" .. name .. "}"
		end)
	end
	return s
end

return Locale
