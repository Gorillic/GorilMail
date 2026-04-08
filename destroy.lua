local addonName, GM = ...

GM = GM or {}
GM.Destroy = GM.Destroy or {}

function GM.Destroy.Initialize()
	if GM.DestroyUI and GM.DestroyUI.Initialize then
		GM.DestroyUI.Initialize()
	end
end

function GM.Destroy.Toggle()
	if GM.DestroyUI and GM.DestroyUI.Toggle then
		GM.DestroyUI.Toggle()
	end
end
