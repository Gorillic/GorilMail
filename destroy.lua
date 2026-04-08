local addonName, GM = ...

GM = GM or {}
GM.Destroy = GM.Destroy or {}

local destroySlashRegistered = false

local function RegisterDestroySlash()
	if destroySlashRegistered then
		return
	end
	SLASH_GORILMAILDESTROY1 = "/gm"
	SlashCmdList.GORILMAILDESTROY = function(msg)
		local raw = tostring(msg or "")
		local cmd = strtrim(strlower(raw))
		if cmd == "destroy" then
			if GM.DestroyUI and GM.DestroyUI.Toggle then
				GM.DestroyUI.Toggle()
			end
			return
		end
		if GM and GM.Utils and GM.Utils.PrintInfo then
			GM.Utils.PrintInfo("Usage: /gm destroy")
		end
	end
	destroySlashRegistered = true
end

function GM.Destroy.Initialize()
	RegisterDestroySlash()
	if GM.DestroyUI and GM.DestroyUI.Initialize then
		GM.DestroyUI.Initialize()
	end
end

function GM.Destroy.Toggle()
	if GM.DestroyUI and GM.DestroyUI.Toggle then
		GM.DestroyUI.Toggle()
	end
end
