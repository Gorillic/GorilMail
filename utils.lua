local addonName, GM = ...

GM = GM or {}

GM.Utils = GM.Utils or {}

local PREFIX = "|cff7fd3ff[GorilMail]|r "

local function EmitMessage(color, message)
	local text = PREFIX .. tostring(message or "")
	if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
		DEFAULT_CHAT_FRAME:AddMessage(text, color.r, color.g, color.b)
	else
		print(text)
	end
end

local function FormatMoney(copper)
	if not copper or copper <= 0 then
		return "0"
	end
	if GetCoinTextureString then
		return GetCoinTextureString(copper)
	end
	return tostring(copper)
end

function GM.Utils.PrintInfo(message)
	EmitMessage({ r = 0.75, g = 0.9, b = 1.0 }, message)
end

function GM.Utils.PrintSuccess(message)
	EmitMessage({ r = 0.55, g = 1.0, b = 0.55 }, message)
end

function GM.Utils.PrintWarn(message)
	EmitMessage({ r = 1.0, g = 0.85, b = 0.45 }, message)
end

function GM.Utils.PrintError(message)
	EmitMessage({ r = 1.0, g = 0.45, b = 0.45 }, message)
end

function GM.Utils.PrintMoney(label, copper)
	EmitMessage({ r = 1.0, g = 0.82, b = 0.2 }, tostring(label or "Money") .. ": " .. FormatMoney(copper))
end
