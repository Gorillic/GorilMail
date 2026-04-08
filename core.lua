local addonName, GM = ...

GM = GM or {}

local eventFrame = CreateFrame("Frame")
local mailFrameHooked = false
local pendingOnHideCloseTimer = nil
local lastCloseHandledAt = 0

local function IsAddonMailUIStaleVisible()
	if not GM.UI or GM.UI.showingDefaultUI then
		return false
	end
	local frame = GM.UI.frame
	if not frame or not frame.IsShown then
		return false
	end
	return frame:IsShown()
end

local function HandleMailClosed()
	local now = GetTime and GetTime() or 0
	if (now - (lastCloseHandledAt or 0)) < 0.2 then
		return
	end

	local mailboxWasOpen = true
	if GM.Mailbox and GM.Mailbox.IsOpen then
		mailboxWasOpen = GM.Mailbox.IsOpen()
	end
	local forceUICleanup = IsAddonMailUIStaleVisible()
	if not mailboxWasOpen and not forceUICleanup then
		return
	end

	lastCloseHandledAt = now

	if GM.Mailbox and GM.Mailbox.OnMailClosed then
		if mailboxWasOpen then
			GM.Mailbox.OnMailClosed()
		end
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

local function ScheduleOnHideCloseConfirm()
	if pendingOnHideCloseTimer then
		pendingOnHideCloseTimer:Cancel()
		pendingOnHideCloseTimer = nil
	end
	pendingOnHideCloseTimer = C_Timer.NewTimer(0.12, function()
		pendingOnHideCloseTimer = nil
		if MailFrame and MailFrame.IsShown and MailFrame:IsShown() then
			return
		end
		HandleMailClosed()
	end)
end

local function EnsureMailFrameHook()
	if mailFrameHooked or not MailFrame then
		return
	end
	MailFrame:HookScript("OnHide", function()
		ScheduleOnHideCloseConfirm()
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
		if GM.Destroy and GM.Destroy.Initialize then
			GM.Destroy.Initialize()
		end
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
		if pendingOnHideCloseTimer then
			pendingOnHideCloseTimer:Cancel()
			pendingOnHideCloseTimer = nil
		end
		HandleMailClosed()
		return
	end

	if eventName == "MAIL_INBOX_UPDATE" then
		if GM.Mailbox and GM.Mailbox.OnInboxUpdate then
			GM.Mailbox.OnInboxUpdate()
		end
	end
end)
