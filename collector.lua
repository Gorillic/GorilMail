local addonName, GM = ...

GM = GM or {}

GM.Collector = GM.Collector or {}

local runtimeState = "idle"
local preparedList = {}
local preparedSummary = {
	collectableCount = 0,
	blockedCount = 0,
	codCount = 0,
	emptyCount = 0,
}
local sessionResult = {
	collectedMoney = 0,
	collectedMailCount = 0,
	collectedItemCount = 0,
	skippedCount = 0,
	skippedCODCount = 0,
	skippedEmptyCount = 0,
	skippedMissingCount = 0,
}
local queueIndex = 1
local pendingAction = nil
local eventFrame = CreateFrame("Frame")
local runtimeNote = nil
local waitTimer = nil
local WAIT_TIMEOUT_SECONDS = 2.5
local AdvanceQueue

local function ResetPreparedData()
	wipe(preparedList)
	preparedSummary.collectableCount = 0
	preparedSummary.blockedCount = 0
	preparedSummary.codCount = 0
	preparedSummary.emptyCount = 0
	sessionResult.collectedMoney = 0
	sessionResult.collectedMailCount = 0
	sessionResult.collectedItemCount = 0
	sessionResult.skippedCount = 0
	sessionResult.skippedCODCount = 0
	sessionResult.skippedEmptyCount = 0
	sessionResult.skippedMissingCount = 0
	queueIndex = 1
	pendingAction = nil
	runtimeNote = nil
end

local function PrintInfo(message)
	if GM.Utils and GM.Utils.PrintInfo then
		GM.Utils.PrintInfo(message)
	end
end

local function PrintSuccess(message)
	if GM.Utils and GM.Utils.PrintSuccess then
		GM.Utils.PrintSuccess(message)
	end
end

local function PrintWarn(message)
	if GM.Utils and GM.Utils.PrintWarn then
		GM.Utils.PrintWarn(message)
	end
end

local function PrintError(message)
	if GM.Utils and GM.Utils.PrintError then
		GM.Utils.PrintError(message)
	end
end

local function PrintMoney(label, copper)
	if GM.Utils and GM.Utils.PrintMoney then
		GM.Utils.PrintMoney(label, copper)
	end
end

local function FormatMoneyText(copper)
	local amount = tonumber(copper) or 0
	if amount <= 0 then
		return "0"
	end
	if GetCoinTextureString then
		return GetCoinTextureString(amount)
	end
	return tostring(amount)
end

local function Colorize(hex, text)
	local value = tostring(text or "")
	local color = tostring(hex or ""):gsub("#", "")
	if color:match("^[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$") then
		return "|cff" .. color .. value .. "|r"
	end
	return value
end

local function ParseItemContextFromSubject(subject)
	local text = tostring(subject or "")
	if text == "" then
		return nil, nil
	end

	local core = text:match(":%s*(.+)$") or text
	core = core:gsub("^%s+", ""):gsub("%s+$", "")
	if core == "" then
		return nil, nil
	end

	local count = tonumber(core:match("%((%d+)%)%s*$"))
	if count and count > 0 then
		core = core:gsub("%s*%(%d+%)%s*$", "")
		core = core:gsub("^%s+", ""):gsub("%s+$", "")
	end

	if core == "" then
		core = nil
	end

	return core, count
end

local function BuildCollectFeedback(action)
	if not action then
		return nil
	end

	local itemHex = "E8E0CF"
	local countHex = "C9D4E6"
	local moneyHex = "F0C35A"
	local moneyText = Colorize(moneyHex, FormatMoneyText(action.money or action.value))
	local itemName = tostring(action.itemName or "")
	local itemCount = tonumber(action.itemCount)
	local subjectName, subjectCount = ParseItemContextFromSubject(action.subject)

	if itemName == "" and subjectName and subjectName ~= "" then
		itemName = subjectName
	end
	if (not itemCount or itemCount < 1) and subjectCount and subjectCount > 0 then
		itemCount = subjectCount
	end

	if action.kind == "money" then
		if itemName ~= "" then
			local countText = tostring((itemCount and itemCount > 0) and itemCount or 1)
			return Colorize(itemHex, itemName) .. " " .. Colorize(countHex, "x" .. countText) .. " = " .. moneyText
		end
		if itemCount and itemCount > 0 then
			return Colorize(itemHex, "Item") .. " " .. Colorize(countHex, "x" .. tostring(itemCount)) .. " = " .. moneyText
		end
		return "Gold collected = " .. moneyText
	end

	local count = tonumber(itemCount) or 1
	if count < 1 then
		count = 1
	end
	if itemName == "" then
		itemName = "Item"
	end
	return Colorize(itemHex, itemName) .. " " .. Colorize(countHex, "x" .. tostring(count)) .. " = " .. moneyText
end

local function BuildFingerprint(row)
	return table.concat({
		tostring(row.sender or ""),
		tostring(row.subject or ""),
		tostring(row.money or 0),
		tostring(row.codAmount or 0),
		tostring(row.hasItem and 1 or 0),
	}, "|")
end

local function FindRowByIndex(rows, index)
	for i = 1, #rows do
		if rows[i].index == index then
			return rows[i]
		end
	end
	return nil
end

local function FindRowByFingerprint(rows, fingerprint)
	for i = 1, #rows do
		if BuildFingerprint(rows[i]) == fingerprint then
			return rows[i]
		end
	end
	return nil
end

local function FinishCompleted()
	runtimeState = "completed"
	runtimeNote = nil
	if waitTimer then
		waitTimer:Cancel()
	end
end

local function StartWaitTimeout()
	if not waitTimer then
		waitTimer = C_Timer.NewTimer(WAIT_TIMEOUT_SECONDS, function()
			if runtimeState ~= "waitingRefresh" or not pendingAction then
				return
			end
			sessionResult.skippedCount = sessionResult.skippedCount + 1
			sessionResult.skippedMissingCount = sessionResult.skippedMissingCount + 1
			runtimeNote = "Skipped timeout step"
			PrintWarn("Skipped timed out mail step")
			pendingAction = nil
			queueIndex = queueIndex + 1
			local rows = {}
			if GM.Mailbox and GM.Mailbox.GetRows then
				rows = GM.Mailbox.GetRows() or {}
			end
			AdvanceQueue(rows)
		end)
	else
		waitTimer:Cancel()
		waitTimer = C_Timer.NewTimer(WAIT_TIMEOUT_SECONDS, function()
			if runtimeState ~= "waitingRefresh" or not pendingAction then
				return
			end
			sessionResult.skippedCount = sessionResult.skippedCount + 1
			sessionResult.skippedMissingCount = sessionResult.skippedMissingCount + 1
			runtimeNote = "Skipped timeout step"
			PrintWarn("Skipped timed out mail step")
			pendingAction = nil
			queueIndex = queueIndex + 1
			local rows = {}
			if GM.Mailbox and GM.Mailbox.GetRows then
				rows = GM.Mailbox.GetRows() or {}
			end
			AdvanceQueue(rows)
		end)
	end
end

local function ClearWaitTimeout()
	if waitTimer then
		waitTimer:Cancel()
		waitTimer = nil
	end
end

local function ExecutePendingAction(action)
	if not action then
		return false
	end
	if action.kind == "itemMoney" or action.kind == "item" then
		AutoLootMailItem(action.index)
		return true
	end
	if action.kind == "money" then
		TakeInboxMoney(action.index)
		return true
	end
	return false
end

function AdvanceQueue(rows)
	while queueIndex <= #preparedList do
		local entry = preparedList[queueIndex]
		local row = FindRowByIndex(rows, entry.index)
		if row and BuildFingerprint(row) ~= entry.fingerprint then
			row = nil
		end

		if not row then
			row = FindRowByFingerprint(rows, entry.fingerprint)
			if row then
				entry.index = row.index
			else
				PrintWarn("Skipped moved mail")
				sessionResult.skippedCount = sessionResult.skippedCount + 1
				sessionResult.skippedMissingCount = sessionResult.skippedMissingCount + 1
				runtimeNote = "Skipped moved mail"
				queueIndex = queueIndex + 1
			end
		end

		if not row then
			-- already skipped above
		elseif not row.canCollect then
			sessionResult.skippedCount = sessionResult.skippedCount + 1
			if row.blockedReason == "COD" then
				sessionResult.skippedCODCount = sessionResult.skippedCODCount + 1
			elseif row.blockedReason == "Empty" then
				sessionResult.skippedEmptyCount = sessionResult.skippedEmptyCount + 1
			end
			runtimeNote = "Skipped blocked mail"
			queueIndex = queueIndex + 1
		else
			runtimeState = "collecting"
			if row.hasItem then
				local itemName, _, itemCount = nil, nil, nil
				if GetInboxItem then
					itemName, _, itemCount = GetInboxItem(row.index, 1)
				end
				pendingAction = {
					kind = (row.money and row.money > 0) and "itemMoney" or "item",
					value = row.subject or "-",
					money = row.money or 0,
					itemName = itemName,
					itemCount = itemCount,
					subject = row.subject,
					index = row.index,
					retries = 0,
				}
				ExecutePendingAction(pendingAction)
				runtimeState = "waitingRefresh"
				StartWaitTimeout()
				return
			end
			if row.money and row.money > 0 then
				pendingAction = {
					kind = "money",
					value = row.money,
					money = row.money,
					subject = row.subject,
					index = row.index,
					retries = 0,
				}
				ExecutePendingAction(pendingAction)
				runtimeState = "waitingRefresh"
				StartWaitTimeout()
				return
			end
			queueIndex = queueIndex + 1
		end
	end

	FinishCompleted()
end

function GM.Collector.GetState()
	return runtimeState
end

function GM.Collector.GetProgress()
	return queueIndex, #preparedList
end

function GM.Collector.GetPreparedList()
	return preparedList
end

function GM.Collector.GetPreparedSummary()
	return preparedSummary
end

function GM.Collector.GetStatusNote()
	return runtimeNote
end

function GM.Collector.GetSessionResult()
	return sessionResult
end

function GM.Collector.Prepare(rows)
	ResetPreparedData()

	if type(rows) ~= "table" then
		runtimeState = "error"
		PrintError("Prepare failed: no rows")
		return preparedSummary
	end

	for i = 1, #rows do
		local row = rows[i]
		if row.canCollect then
			preparedList[#preparedList + 1] = {
				index = row.index,
				fingerprint = BuildFingerprint(row),
			}
			preparedSummary.collectableCount = preparedSummary.collectableCount + 1
		else
			preparedSummary.blockedCount = preparedSummary.blockedCount + 1
			sessionResult.skippedCount = sessionResult.skippedCount + 1
			if row.blockedReason == "COD" then
				preparedSummary.codCount = preparedSummary.codCount + 1
				sessionResult.skippedCODCount = sessionResult.skippedCODCount + 1
			elseif row.blockedReason == "Empty" then
				preparedSummary.emptyCount = preparedSummary.emptyCount + 1
				sessionResult.skippedEmptyCount = sessionResult.skippedEmptyCount + 1
			end
		end
	end

	runtimeState = "prepared"
	runtimeNote = nil
	if preparedSummary.codCount > 0 or preparedSummary.emptyCount > 0 then
		PrintWarn("Skipped COD:" .. tostring(preparedSummary.codCount) .. " Empty:" .. tostring(preparedSummary.emptyCount))
	end
	return preparedSummary
end

function GM.Collector.Start(rows)
	if runtimeState ~= "prepared" and runtimeState ~= "completed" and runtimeState ~= "idle" then
		return false
	end
	if #preparedList == 0 then
		runtimeState = "completed"
		PrintWarn("Nothing to collect")
		return false
	end
	if type(rows) ~= "table" then
		runtimeState = "error"
		PrintError("Start failed: no rows")
		return false
	end
	AdvanceQueue(rows)
	return runtimeState == "collecting" or runtimeState == "waitingRefresh" or runtimeState == "completed"
end

function GM.Collector.OnInboxUpdate(rows)
	if runtimeState ~= "waitingRefresh" then
		return
	end

	ClearWaitTimeout()
	if pendingAction then
		if pendingAction.kind == "money" then
			sessionResult.collectedMoney = sessionResult.collectedMoney + (pendingAction.value or 0)
			sessionResult.collectedMailCount = sessionResult.collectedMailCount + 1
		elseif pendingAction.kind == "itemMoney" then
			sessionResult.collectedMoney = sessionResult.collectedMoney + (pendingAction.money or 0)
			sessionResult.collectedItemCount = sessionResult.collectedItemCount + 1
			sessionResult.collectedMailCount = sessionResult.collectedMailCount + 1
		elseif pendingAction.kind == "item" then
			sessionResult.collectedItemCount = sessionResult.collectedItemCount + 1
			sessionResult.collectedMailCount = sessionResult.collectedMailCount + 1
		end
		local feedback = BuildCollectFeedback(pendingAction)
		if feedback and feedback ~= "" then
			PrintSuccess(feedback)
		end
		runtimeNote = nil
	end

	pendingAction = nil
	queueIndex = queueIndex + 1
	AdvanceQueue(rows or {})
end

function GM.Collector.StopWithError(message)
	runtimeState = "error"
	runtimeNote = message or "Collector stopped"
	ClearWaitTimeout()
	PrintError(message or "Collector stopped")
end

eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("MAIL_FAILED")
eventFrame:SetScript("OnEvent", function(_, eventName)
	if eventName == "MAIL_CLOSED" then
		if runtimeState == "collecting" or runtimeState == "waitingRefresh" then
			GM.Collector.StopWithError("Mailbox closed during collect")
		end
		return
	end

	if eventName == "MAIL_INBOX_UPDATE" and (runtimeState == "waitingRefresh") then
		local rows = {}
		if GM.Mailbox and GM.Mailbox.GetRows then
			rows = GM.Mailbox.GetRows() or {}
		end
		GM.Collector.OnInboxUpdate(rows)
		return
	end

	if eventName == "MAIL_FAILED" and runtimeState == "waitingRefresh" and pendingAction then
		ClearWaitTimeout()
		if (pendingAction.retries or 0) < 1 then
			pendingAction.retries = (pendingAction.retries or 0) + 1
			runtimeNote = "Retrying failed step"
			PrintWarn("Retrying failed mail step")
			ExecutePendingAction(pendingAction)
			StartWaitTimeout()
			return
		end

		sessionResult.skippedCount = sessionResult.skippedCount + 1
		sessionResult.skippedMissingCount = sessionResult.skippedMissingCount + 1
		runtimeNote = "Skipped failed step"
		PrintWarn("Skipped failed mail step")
		pendingAction = nil
		queueIndex = queueIndex + 1

		local rows = {}
		if GM.Mailbox and GM.Mailbox.GetRows then
			rows = GM.Mailbox.GetRows() or {}
		end
		AdvanceQueue(rows)
	end
end)
