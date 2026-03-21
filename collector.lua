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
	preblockedCount = 0,
	skippedCODCount = 0,
	skippedEmptyCount = 0,
	skippedMissingCount = 0,
	processedStepCount = 0,
	softRecoveryCount = 0,
	failedStepCount = 0,
	abortReason = nil,
	finalState = "idle",
	closeTelemetry = nil,
}
local queueIndex = 1
local pendingAction = nil
local eventFrame = CreateFrame("Frame")
local runtimeNote = nil
local waitTimer = nil
local WAIT_TIMEOUT_SECONDS = 2.5
local ISSUE_DEFER_SECONDS = 0.15
local TRANSIENT_SETTLE_DEFER_SECONDS = 0.30
local debugEnabled = false
local AdvanceQueue
local DebugLog
local DescribeAction
local EmitFinalSummary
local BuildFingerprint
local finalSummaryEmitted = false

local function GetFreshRows()
	local rows = {}
	if GM.Mailbox and GM.Mailbox.ScanInbox then
		GM.Mailbox.ScanInbox()
	end
	if GM.Mailbox and GM.Mailbox.GetRows then
		rows = GM.Mailbox.GetRows() or {}
	end
	return rows
end

local function ScheduleSettleValidation(action, delay, reason)
	local waitSeconds = tonumber(delay) or ISSUE_DEFER_SECONDS
	sessionResult.softRecoveryCount = (sessionResult.softRecoveryCount or 0) + 1
	C_Timer.After(waitSeconds, function()
		if runtimeState ~= "waitingRefresh" then
			return
		end
		if not pendingAction or pendingAction ~= action then
			return
		end
		DebugLog("refresh", "settle-probe " .. tostring(reason or "unknown"))
		local rows = GetFreshRows()
		DebugLog("refresh", "settle rows=" .. tostring(#rows))
		GM.Collector.OnInboxUpdate(rows)
	end)
end

local function MatchUiErrorMessage(message, globalValue)
	if not message or not globalValue then
		return false
	end
	return tostring(message) == tostring(globalValue)
end

local function IsTransientMailUiError(message)
	if MatchUiErrorMessage(message, ERR_MAIL_DATABASE_ERROR) then
		return true
	end
	return false
end

local function IsCollectorStepFatalUiError(message)
	if MatchUiErrorMessage(message, ERR_INV_FULL) then
		return true
	end
	if MatchUiErrorMessage(message, ERR_ITEM_MAX_COUNT) then
		return true
	end
	return false
end

local function SkipPendingAction(reason)
	if not pendingAction then
		return
	end
	local currentEntry = preparedList[queueIndex]
	if currentEntry then
		if reason == "ui-step-fatal" then
			currentEntry.outcome = "failed"
		else
			currentEntry.outcome = "skipped"
		end
		currentEntry.skipReason = tostring(reason or "failed")
	end
	sessionResult.skippedCount = sessionResult.skippedCount + 1
	sessionResult.failedStepCount = sessionResult.failedStepCount + 1
	sessionResult.processedStepCount = sessionResult.processedStepCount + 1
	runtimeNote = nil
	DebugLog("skip", tostring(reason or "unknown") .. " " .. DescribeAction(pendingAction))
	pendingAction = nil
	queueIndex = queueIndex + 1
	AdvanceQueue(GetFreshRows())
end

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
	sessionResult.preblockedCount = 0
	sessionResult.skippedCODCount = 0
	sessionResult.skippedEmptyCount = 0
	sessionResult.skippedMissingCount = 0
	sessionResult.processedStepCount = 0
	sessionResult.softRecoveryCount = 0
	sessionResult.failedStepCount = 0
	sessionResult.abortReason = nil
	sessionResult.finalState = "idle"
	sessionResult.closeTelemetry = nil
	queueIndex = 1
	pendingAction = nil
	runtimeNote = nil
	finalSummaryEmitted = false
end

local function IsCollectActive()
	return runtimeState == "collecting" or runtimeState == "waitingRefresh"
end

local function CaptureCloseTelemetry(source)
	local mailboxOpen = nil
	if GM.Mailbox and GM.Mailbox.IsOpen then
		mailboxOpen = GM.Mailbox.IsOpen() and true or false
	end
	local mailFrameShown = nil
	if MailFrame and MailFrame.IsShown then
		mailFrameShown = MailFrame:IsShown() and true or false
	end
	sessionResult.closeTelemetry = {
		source = tostring(source or "unknown"),
		mailboxOpen = mailboxOpen,
		mailFrameShown = mailFrameShown,
		collectActive = IsCollectActive(),
	}
	DebugLog("close", "source=" .. tostring(sessionResult.closeTelemetry.source))
end

function GM.Collector.RecordCloseTelemetry(source)
	CaptureCloseTelemetry(source)
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

DebugLog = function(eventName, detail)
	if not debugEnabled then
		return
	end
	local parts = { "[CollectorDBG]", tostring(eventName or "event") }
	if detail and detail ~= "" then
		parts[#parts + 1] = tostring(detail)
	end
	PrintInfo(table.concat(parts, " "))
end

function GM.Collector.SetDebugEnabled(enabled)
	debugEnabled = enabled and true or false
end

function GM.Collector.IsDebugEnabled()
	return debugEnabled
end

function GM.Collector.DebugLog(eventName, detail)
	DebugLog(eventName, detail)
end

DescribeAction = function(action)
	if not action then
		return "none"
	end
	return tostring(action.kind or "?") .. " idx=" .. tostring(action.index or "?")
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

local function BuildFingerprintCounts(rows)
	local counts = {}
	if type(rows) ~= "table" then
		return counts
	end
	for i = 1, #rows do
		local fp = BuildFingerprint(rows[i])
		counts[fp] = (counts[fp] or 0) + 1
	end
	return counts
end

local function BuildFinalOutcomes(finalState, rows)
	local preparedCount = #preparedList
	local outcomes = {}
	local successCount = 0
	local skippedCount = 0
	local failedCount = 0
	if preparedCount == 0 then
		return outcomes, successCount, skippedCount, failedCount
	end

	local remainingFingerprintCounts = BuildFingerprintCounts(rows)
	local groupedIndices = {}
	for i = 1, preparedCount do
		local entry = preparedList[i]
		local fingerprint = entry and entry.fingerprint or ""
		if not groupedIndices[fingerprint] then
			groupedIndices[fingerprint] = {}
		end
		groupedIndices[fingerprint][#groupedIndices[fingerprint] + 1] = i
		outcomes[i] = entry and entry.outcome or nil
	end

	for fingerprint, indices in pairs(groupedIndices) do
		local groupSize = #indices
		local unresolvedTarget = math.max(0, math.min(groupSize, remainingFingerprintCounts[fingerprint] or 0))
		local successTarget = groupSize - unresolvedTarget

		local currentSuccess = 0
		for j = 1, groupSize do
			local idx = indices[j]
			if outcomes[idx] == "success" then
				currentSuccess = currentSuccess + 1
			end
		end

		if currentSuccess < successTarget then
			for j = 1, groupSize do
				if currentSuccess >= successTarget then
					break
				end
				local idx = indices[j]
				if outcomes[idx] ~= "success" then
					outcomes[idx] = "success"
					currentSuccess = currentSuccess + 1
				end
			end
		end

		local pendingToFailed = (finalState == "error")
		for j = 1, groupSize do
			local idx = indices[j]
			local outcome = outcomes[idx]
			if outcome == "success" then
				successCount = successCount + 1
			elseif outcome == "failed" then
				failedCount = failedCount + 1
			else
				if pendingToFailed and (outcome == nil or outcome == "pending") then
					outcomes[idx] = "failed"
					failedCount = failedCount + 1
				else
					outcomes[idx] = "skipped"
					skippedCount = skippedCount + 1
				end
			end
		end
	end

	for i = 1, preparedCount do
		preparedList[i].finalOutcome = outcomes[i]
	end

	return outcomes, successCount, skippedCount, failedCount
end

local function BuildSkipReasonTelemetry()
	local counts = {}
	local lastReason = nil
	for i = 1, #preparedList do
		local entry = preparedList[i]
		if entry and (entry.outcome == "skipped" or entry.outcome == "failed") then
			local reason = entry.skipReason
			if reason and reason ~= "" then
				local key = tostring(reason)
				counts[key] = (counts[key] or 0) + 1
				lastReason = key
			end
		end
	end
	return counts, lastReason
end

local function BuildSessionSnapshot(finalState, abortReason)
	local preparedCount = #preparedList
	local processedCount = tonumber(sessionResult.processedStepCount) or 0
	if preparedCount > 0 then
		local byQueue = math.max(0, math.min(preparedCount, (queueIndex or 1) - 1))
		if byQueue > processedCount then
			processedCount = byQueue
		end
	end
	sessionResult.processedStepCount = processedCount
	if finalState then
		sessionResult.finalState = finalState
	end
	if abortReason ~= nil then
		sessionResult.abortReason = abortReason
	end
	local _, finalSuccessCount, finalSkippedCount, finalFailedCount = BuildFinalOutcomes(sessionResult.finalState, GetFreshRows())
	local completedCount = finalSuccessCount + finalSkippedCount + finalFailedCount
	local skipReasonCounts, lastSkipReason = BuildSkipReasonTelemetry()
	return {
		preparedCount = preparedCount,
		processedStepCount = processedCount,
		completedCount = completedCount,
		finalSuccessCount = finalSuccessCount,
		finalSkippedCount = finalSkippedCount,
		finalFailedCount = finalFailedCount,
		collectedMailCount = sessionResult.collectedMailCount or 0,
		skippedCount = sessionResult.skippedCount or 0,
		preblockedCount = sessionResult.preblockedCount or 0,
		skipReasonCounts = skipReasonCounts,
		lastSkipReason = lastSkipReason,
		softRecoveryCount = sessionResult.softRecoveryCount or 0,
		failedStepCount = sessionResult.failedStepCount or 0,
		abortReason = sessionResult.abortReason,
		finalState = sessionResult.finalState,
		closeTelemetry = sessionResult.closeTelemetry,
	}
end

BuildFingerprint = function(row)
	return table.concat({
		tostring(row.sender or ""),
		tostring(row.subject or ""),
		tostring(row.money or 0),
		tostring(row.codAmount or 0),
		tostring(row.hasItem and 1 or 0),
	}, "|")
end

local function BuildIdentityFingerprint(row)
	return table.concat({
		tostring(row.sender or ""),
		tostring(row.subject or ""),
		tostring(row.codAmount or 0),
	}, "|")
end

local function CountIdentityMatches(rows, identityFingerprint)
	if type(rows) ~= "table" or not identityFingerprint or identityFingerprint == "" then
		return 0
	end
	local count = 0
	for i = 1, #rows do
		if BuildIdentityFingerprint(rows[i]) == identityFingerprint then
			count = count + 1
		end
	end
	return count
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
	DebugLog("finalize", "completed")
	if waitTimer then
		waitTimer:Cancel()
	end
	EmitFinalSummary("completed")
end

local function StartWaitTimeout()
	local function OnWaitTimeout()
		if runtimeState ~= "waitingRefresh" or not pendingAction then
			return
		end
		local currentEntry = preparedList[queueIndex]
		if currentEntry then
			currentEntry.outcome = "skipped"
			currentEntry.skipReason = "timeout"
		end
		sessionResult.skippedCount = sessionResult.skippedCount + 1
		sessionResult.skippedMissingCount = sessionResult.skippedMissingCount + 1
		sessionResult.failedStepCount = sessionResult.failedStepCount + 1
		sessionResult.processedStepCount = sessionResult.processedStepCount + 1
		runtimeNote = "Skipped timeout step"
		DebugLog("skip", "timeout " .. DescribeAction(pendingAction))
		pendingAction = nil
		queueIndex = queueIndex + 1
		local rows = GetFreshRows()
		AdvanceQueue(rows)
	end

	if not waitTimer then
		waitTimer = C_Timer.NewTimer(WAIT_TIMEOUT_SECONDS, OnWaitTimeout)
	else
		waitTimer:Cancel()
		waitTimer = C_Timer.NewTimer(WAIT_TIMEOUT_SECONDS, OnWaitTimeout)
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

local function IsCommandPending()
	if C_Mail and C_Mail.IsCommandPending then
		return C_Mail.IsCommandPending() and true or false
	end
	return false
end

local function TryIssuePendingAction(action)
	if not action then
		return false
	end
	if IsCommandPending() then
		runtimeNote = "Waiting command slot"
		DebugLog("wait", "command-slot " .. DescribeAction(action))
		C_Timer.After(ISSUE_DEFER_SECONDS, function()
			if runtimeState ~= "collecting" then
				return
			end
			if pendingAction ~= action then
				return
			end
			TryIssuePendingAction(action)
		end)
		return false
	end

	if not ExecutePendingAction(action) then
		DebugLog("skip", "issue-failed " .. DescribeAction(action))
		return false
	end

	DebugLog("issue", DescribeAction(action))
	runtimeState = "waitingRefresh"
	StartWaitTimeout()
	return true
end

local function FindPendingRow(rows, action)
	if type(rows) ~= "table" or not action then
		return nil, "missing"
	end

	local row = FindRowByIndex(rows, action.index)
	if row and BuildIdentityFingerprint(row) == action.identityFingerprint then
		return row, "found"
	end

	local candidates = {}
	for i = 1, #rows do
		local candidate = rows[i]
		if BuildIdentityFingerprint(candidate) == action.identityFingerprint then
			candidates[#candidates + 1] = candidate
		end
	end

	if #candidates == 0 then
		return nil, "missing"
	end

	-- Prefer an exact pre-action row fingerprint if available.
	if action.sourceFingerprint and action.sourceFingerprint ~= "" then
		local matched = nil
		for i = 1, #candidates do
			if BuildFingerprint(candidates[i]) == action.sourceFingerprint then
				if matched then
					return nil, "ambiguous"
				end
				matched = candidates[i]
			end
		end
		if matched then
			return matched, "found"
		end
	end

	local previousCount = tonumber(action.identityMatchCount) or 0
	if previousCount > 1 then
		if #candidates < previousCount then
			return nil, "countDeltaApplied"
		end
		return nil, "ambiguous"
	end

	if #candidates == 1 then
		return candidates[1], "found"
	end

	-- Fallback: narrow by action kind to reduce duplicate ambiguity.
	local kindMatched = nil
	for i = 1, #candidates do
		local candidate = candidates[i]
		local ok = false
		if action.kind == "money" then
			ok = (candidate.money or 0) > 0 and (not candidate.hasItem)
		elseif action.kind == "item" then
			ok = candidate.hasItem and ((candidate.money or 0) <= 0)
		elseif action.kind == "itemMoney" then
			ok = candidate.hasItem and ((candidate.money or 0) > 0)
		end
		if ok then
			if kindMatched then
				return nil, "ambiguous"
			end
			kindMatched = candidate
		end
	end

	if kindMatched then
		return kindMatched, "found"
	end

	return nil, "ambiguous"
end

local function IsActionApplied(rows, action)
	if not action then
		return false
	end

	local row, rowState = FindPendingRow(rows, action)
	if not row then
		if rowState == "ambiguous" then
			return false
		end
		if rowState == "countDeltaApplied" then
			return true
		end
		return true
	end

	if action.kind == "money" then
		return (row.money or 0) <= 0
	end

	if action.kind == "item" then
		return not row.hasItem
	end

	if action.kind == "itemMoney" then
		return (not row.hasItem) and ((row.money or 0) <= 0)
	end

	return false
end

function AdvanceQueue(rows)
	while queueIndex <= #preparedList do
		local entry = preparedList[queueIndex]
		local row = FindRowByIndex(rows, entry.index)
		if row and BuildFingerprint(row) ~= entry.fingerprint then
			local sameIdentity = entry.identityFingerprint
				and entry.identityFingerprint ~= ""
				and BuildIdentityFingerprint(row) == entry.identityFingerprint
			if sameIdentity then
				entry.fingerprint = BuildFingerprint(row)
			else
				row = nil
			end
		end

		if not row then
			row = FindRowByFingerprint(rows, entry.fingerprint)
			if row then
				entry.index = row.index
				entry.fingerprint = BuildFingerprint(row)
				entry.movedSettleWaits = nil
			end
			if not row and entry.identityFingerprint and entry.identityFingerprint ~= "" then
				local identityMatch = nil
				local identityCount = 0
				for i = 1, #rows do
					local candidate = rows[i]
					if BuildIdentityFingerprint(candidate) == entry.identityFingerprint then
						identityCount = identityCount + 1
						if identityCount == 1 then
							identityMatch = candidate
						end
					end
				end
				if identityCount == 1 and identityMatch then
					row = identityMatch
					entry.index = row.index
					entry.fingerprint = BuildFingerprint(row)
					entry.movedSettleWaits = nil
					DebugLog("refresh", "moved-identity idx=" .. tostring(row.index or "?"))
				end
			end
			if not row then
				if (entry.movedSettleWaits or 0) < 1 then
					entry.movedSettleWaits = (entry.movedSettleWaits or 0) + 1
					runtimeState = "collecting"
					runtimeNote = "Waiting inbox settle"
					local expectedQueueIndex = queueIndex
					local expectedEntry = entry
					local expectedWaitCount = entry.movedSettleWaits
					DebugLog("settle-wait", "moved-check idx=" .. tostring(entry.index or "?"))
					C_Timer.After(ISSUE_DEFER_SECONDS, function()
						if runtimeState ~= "collecting" then
							return
						end
						if queueIndex ~= expectedQueueIndex then
							return
						end
						local currentEntry = preparedList[queueIndex]
						if currentEntry ~= expectedEntry then
							return
						end
						if (currentEntry.movedSettleWaits or 0) ~= expectedWaitCount then
							return
						end
						DebugLog("refresh", "moved-settle idx=" .. tostring(currentEntry.index or "?"))
						AdvanceQueue(GetFreshRows())
					end)
					return
				end
				sessionResult.skippedCount = sessionResult.skippedCount + 1
				sessionResult.skippedMissingCount = sessionResult.skippedMissingCount + 1
				entry.outcome = "skipped"
				entry.skipReason = "moved"
				entry.movedSettleWaits = nil
				runtimeNote = "Skipped moved mail"
				DebugLog("skip", "moved idx=" .. tostring(entry.index or "?"))
				queueIndex = queueIndex + 1
			end
		end
		if row then
			entry.movedSettleWaits = nil
		end

		if not row then
			-- already skipped above
		elseif not row.canCollect then
			sessionResult.skippedCount = sessionResult.skippedCount + 1
			entry.outcome = "skipped"
			entry.skipReason = "blocked"
			if row.blockedReason == "COD" then
				sessionResult.skippedCODCount = sessionResult.skippedCODCount + 1
			elseif row.blockedReason == "Empty" then
				sessionResult.skippedEmptyCount = sessionResult.skippedEmptyCount + 1
			end
			runtimeNote = "Skipped blocked mail"
			DebugLog("skip", "blocked idx=" .. tostring(row.index or "?"))
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
					identityFingerprint = BuildIdentityFingerprint(row),
					identityMatchCount = CountIdentityMatches(rows, BuildIdentityFingerprint(row)),
					sourceFingerprint = BuildFingerprint(row),
				}
				TryIssuePendingAction(pendingAction)
				return
			end
			if row.money and row.money > 0 then
				pendingAction = {
					kind = "money",
					value = row.money,
					money = row.money,
					subject = row.subject,
					index = row.index,
					identityFingerprint = BuildIdentityFingerprint(row),
					identityMatchCount = CountIdentityMatches(rows, BuildIdentityFingerprint(row)),
					sourceFingerprint = BuildFingerprint(row),
				}
				TryIssuePendingAction(pendingAction)
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

function GM.Collector.GetSessionSnapshot()
	return BuildSessionSnapshot(runtimeState)
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
				identityFingerprint = BuildIdentityFingerprint(row),
				outcome = "pending",
				skipReason = nil,
			}
			preparedSummary.collectableCount = preparedSummary.collectableCount + 1
		else
			preparedSummary.blockedCount = preparedSummary.blockedCount + 1
			sessionResult.preblockedCount = sessionResult.preblockedCount + 1
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
		EmitFinalSummary("completed")
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

	DebugLog("wait-event", "MAIL_INBOX_UPDATE")
	ClearWaitTimeout()
	if pendingAction and IsActionApplied(rows or {}, pendingAction) then
		DebugLog("validate", "pass " .. DescribeAction(pendingAction))
		local currentEntry = preparedList[queueIndex]
		if currentEntry then
			currentEntry.outcome = "success"
			currentEntry.skipReason = nil
		end
		sessionResult.processedStepCount = sessionResult.processedStepCount + 1
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
	elseif pendingAction then
		DebugLog("validate", "fail " .. DescribeAction(pendingAction))
		if IsCommandPending() then
			runtimeNote = "Waiting command completion"
			DebugLog("wait", "command-completion " .. DescribeAction(pendingAction))
			StartWaitTimeout()
			return
		end

		if (pendingAction.verifyWaits or 0) < 2 then
			pendingAction.verifyWaits = (pendingAction.verifyWaits or 0) + 1
			runtimeNote = "Waiting inbox settle"
			DebugLog("settle-wait", DescribeAction(pendingAction))
			StartWaitTimeout()
			ScheduleSettleValidation(pendingAction, ISSUE_DEFER_SECONDS, "unverified")
			return
		end

		sessionResult.skippedCount = sessionResult.skippedCount + 1
		sessionResult.skippedMissingCount = sessionResult.skippedMissingCount + 1
		sessionResult.failedStepCount = sessionResult.failedStepCount + 1
		sessionResult.processedStepCount = sessionResult.processedStepCount + 1
		local currentEntry = preparedList[queueIndex]
		if currentEntry then
			currentEntry.outcome = "skipped"
			currentEntry.skipReason = "unverified"
		end
		DebugLog("skip", "unverified " .. DescribeAction(pendingAction))
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
	EmitFinalSummary("error", message or "Collector stopped")
end

EmitFinalSummary = function(finalState, abortReason)
	if finalSummaryEmitted then
		return
	end
	finalSummaryEmitted = true
	local snapshot = BuildSessionSnapshot(finalState, abortReason)
	local summary = "Collect All "
		.. (snapshot.finalState == "completed" and "done" or "stopped")
		.. ": " .. tostring(snapshot.completedCount or 0) .. "/" .. tostring(snapshot.preparedCount)
		.. " | Collected " .. tostring(snapshot.finalSuccessCount or 0)
		.. " | Skipped " .. tostring(snapshot.finalSkippedCount or 0)
	if (snapshot.finalFailedCount or 0) > 0 then
		summary = summary .. " | Failed " .. tostring(snapshot.finalFailedCount)
	end
	if (snapshot.preblockedCount or 0) > 0 then
		summary = summary .. " | Preblocked " .. tostring(snapshot.preblockedCount)
	end
	if snapshot.finalState == "error" and snapshot.abortReason and snapshot.abortReason ~= "" then
		summary = summary .. " | Reason: " .. tostring(snapshot.abortReason)
	end
	if snapshot.finalState == "completed" then
		PrintInfo(summary)
	else
		PrintError(summary)
	end
	DebugLog("summary", summary)
end

eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
eventFrame:RegisterEvent("MAIL_CLOSED")
eventFrame:RegisterEvent("MAIL_FAILED")
eventFrame:RegisterEvent("UI_ERROR_MESSAGE")
eventFrame:SetScript("OnEvent", function(_, eventName, ...)
	if eventName == "MAIL_CLOSED" then
		if runtimeState == "collecting" or runtimeState == "waitingRefresh" then
			CaptureCloseTelemetry("event_mail_closed")
		end
		return
	end

	if eventName == "MAIL_INBOX_UPDATE" and (runtimeState == "waitingRefresh") then
		local rows = {}
		DebugLog("refresh", "snapshot begin")
		rows = GetFreshRows()
		DebugLog("refresh", "snapshot rows=" .. tostring(#rows))
		GM.Collector.OnInboxUpdate(rows)
		return
	end

	if eventName == "MAIL_FAILED" and runtimeState == "waitingRefresh" and pendingAction then
		ClearWaitTimeout()
		if (pendingAction.failedSettleWaits or 0) < 1 then
			pendingAction.failedSettleWaits = (pendingAction.failedSettleWaits or 0) + 1
			runtimeNote = "Waiting inbox settle"
			DebugLog("soft-recovery", "failed-settle " .. DescribeAction(pendingAction))
			StartWaitTimeout()
			ScheduleSettleValidation(pendingAction, ISSUE_DEFER_SECONDS, "mail-failed")
			return
		end

		SkipPendingAction("failed")
		return
	end

	if eventName == "UI_ERROR_MESSAGE" and runtimeState == "waitingRefresh" and pendingAction then
		local msgType, message = ...
		local uiMessage = message
		if uiMessage == nil and type(msgType) == "string" then
			uiMessage = msgType
		end
		if not uiMessage or uiMessage == "" then
			return
		end

		if IsTransientMailUiError(uiMessage) then
			ClearWaitTimeout()
			if (pendingAction.transientSettleWaits or 0) < 2 then
				pendingAction.transientSettleWaits = (pendingAction.transientSettleWaits or 0) + 1
				runtimeNote = "Waiting inbox settle"
				DebugLog("soft-recovery", "ui-transient " .. DescribeAction(pendingAction))
				StartWaitTimeout()
				ScheduleSettleValidation(pendingAction, TRANSIENT_SETTLE_DEFER_SECONDS, "ui-transient")
				return
			end

			SkipPendingAction("transient-exhausted")
			return
		end

		if IsCollectorStepFatalUiError(uiMessage) then
			ClearWaitTimeout()
			SkipPendingAction("ui-step-fatal")
			return
		end
	end
end)
