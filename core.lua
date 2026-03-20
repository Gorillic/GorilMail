local addonName, GM = ...

GM = GM or {}

local eventFrame = CreateFrame("Frame")
local mailFrameHooked = false

local function HandleMailClosed()
	local mailboxWasOpen = true
	if GM.Mailbox and GM.Mailbox.IsOpen then
		mailboxWasOpen = GM.Mailbox.IsOpen()
	end
	if not mailboxWasOpen then
		return
	end

	if GM.Mailbox and GM.Mailbox.OnMailClosed then
		GM.Mailbox.OnMailClosed()
	end
	if GM.UI and GM.UI.OnMailClosed then
		GM.UI.OnMailClosed()
	end
	if GM.Collector and GM.Collector.GetState and GM.Collector.StopWithError then
		local state = GM.Collector.GetState()
		if state == "collecting" or state == "waitingRefresh" then
			GM.Collector.StopWithError("Mailbox closed during collect")
		end
	end
end

local function EnsureMailFrameHook()
	if mailFrameHooked or not MailFrame then
		return
	end
	MailFrame:HookScript("OnHide", function()
		HandleMailClosed()
	end)
	mailFrameHooked = true
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:SetScript("OnEvent", function(_, eventName)
	if eventName == "PLAYER_LOGIN" then
		EnsureMailFrameHook()
		if GM.Mailbox and GM.Mailbox.Initialize then
			GM.Mailbox.Initialize()
		end
		if GM.UI and GM.UI.Initialize then
			GM.UI.Initialize()
		end
		return
	end

	if eventName == "MAIL_SHOW" then
		EnsureMailFrameHook()
		if GM.UI and GM.UI.OnMailShow then
			GM.UI.OnMailShow()
		end
		if GM.Mailbox and GM.Mailbox.OnMailShow then
			GM.Mailbox.OnMailShow()
		end
		return
	end

	if eventName == "MAIL_CLOSED" then
		HandleMailClosed()
		return
	end

	if eventName == "MAIL_INBOX_UPDATE" then
		if GM.Mailbox and GM.Mailbox.OnInboxUpdate then
			GM.Mailbox.OnInboxUpdate()
		end
	end
end)
