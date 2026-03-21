local addonName, GM = ...

GM = GM or {}

local eventFrame = CreateFrame("Frame")
local mailFrameHooked = false
local telemetrySlashRegistered = false
local pendingOnHideCloseTimer = nil
local lastCloseHandledAt = 0

local function HandleMailClosed(source)
	local now = GetTime and GetTime() or 0
	if (now - (lastCloseHandledAt or 0)) < 0.2 then
		return
	end
	lastCloseHandledAt = now

	local mailboxWasOpen = true
	if GM.Mailbox and GM.Mailbox.IsOpen then
		mailboxWasOpen = GM.Mailbox.IsOpen()
	end
	if GM.Collector and GM.Collector.RecordCloseTelemetry then
		GM.Collector.RecordCloseTelemetry(source or "core_handle_mail_closed")
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
		HandleMailClosed("mailframe_onhide")
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

local function RegisterTelemetrySlash()
	if telemetrySlashRegistered then
		return
	end
	SLASH_GORILMAILTELEMETRY1 = "/gmtelemetry"
	SLASH_GORILMAILTELEMETRY2 = "/gmtel"
	SlashCmdList.GORILMAILTELEMETRY = function()
		if not GM or not GM.Collector or not GM.Collector.GetSessionSnapshot then
			if GM and GM.Utils and GM.Utils.PrintError then
				GM.Utils.PrintError("Telemetry unavailable")
			end
			return
		end
		local snapshot = GM.Collector.GetSessionSnapshot()
		if DevTools_Dump then
			DevTools_Dump(snapshot)
			return
		end
		local close = snapshot and snapshot.closeTelemetry or nil
		if GM and GM.Utils and GM.Utils.PrintInfo then
			GM.Utils.PrintInfo(
				"Telemetry source="
					.. tostring(close and close.source or "nil")
					.. " mailboxOpen=" .. tostring(close and close.mailboxOpen)
					.. " mailFrameShown=" .. tostring(close and close.mailFrameShown)
					.. " collectActive=" .. tostring(close and close.collectActive)
			)
		end
	end
	telemetrySlashRegistered = true
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("MAIL_SHOW")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:SetScript("OnEvent", function(_, eventName)
	if eventName == "PLAYER_LOGIN" then
		EnsureMailFrameHook()
		RegisterTelemetrySlash()
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
		HandleMailClosed("core_handle_mail_closed")
		return
	end

	if eventName == "MAIL_INBOX_UPDATE" then
		if GM.Mailbox and GM.Mailbox.OnInboxUpdate then
			GM.Mailbox.OnInboxUpdate()
		end
	end
end)
