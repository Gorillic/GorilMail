local addonName, GM = ...

GM = GM or {}
GM.DestroyUI = GM.DestroyUI or {}

local ROW_HEIGHT = 24
local VISIBLE_ROWS = 13
local FRAME_WIDTH = 420
local FRAME_HEIGHT = 452

local state = {
	frame = nil,
	listRows = {},
	dataRows = {},
	summary = nil,
	knownSpells = nil,
	currentCandidate = nil,
	selectedRowKey = nil,
	selectedIndex = 1,
	skipAdvanceCount = 0,
	destroyClickLockUntil = 0,
	destroyClickLockRowKey = nil,
}

local function GetSpellNameSafe(spellID)
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		return info and info.name or nil
	end
	if GetSpellInfo then
		return GetSpellInfo(spellID)
	end
	return nil
end

local function SetStatusText(text)
	if state.frame and state.frame.statusText then
		state.frame.statusText:SetText(tostring(text or ""))
	end
end

local function UpdateTopInfo()
	if not state.frame or not state.frame.infoText then
		return
	end
	state.frame.infoText:SetText("")
end

local function UpdateSummaryText()
	if not state.frame or not state.frame.summaryText then
		return
	end
	local summary = state.summary or {}
	local skippedCount = tonumber(state.skipAdvanceCount) or 0
	state.frame.summaryText:SetText(
		"Ready: " .. tostring(tonumber(summary.ready) or 0)
			.. " | Skipped: " .. tostring(skippedCount)
			.. " | Blocked: " .. tostring(tonumber(summary.blocked) or 0)
	)
end

local function ConfigureDestroyButton()
	if not state.frame or not state.frame.destroyNextButton then
		return
	end
	local button = state.frame.destroyNextButton
	local candidate = state.currentCandidate
	local now = (GetTime and GetTime()) or 0

	if (tonumber(state.destroyClickLockUntil) or 0) > 0 and now >= state.destroyClickLockUntil then
		state.destroyClickLockUntil = 0
		state.destroyClickLockRowKey = nil
	end

	if InCombatLockdown and InCombatLockdown() then
		button:SetEnabled(false)
		SetStatusText("Combat lockdown: action disabled")
		return
	end

	if not candidate then
		button:SetEnabled(false)
		button:SetAttribute("type", nil)
		button:SetAttribute("macrotext", nil)
		return
	end

	if (tonumber(state.destroyClickLockUntil) or 0) > now then
		button:SetEnabled(false)
		return
	end

	local spellName = GetSpellNameSafe(candidate.spellID)
	if not spellName then
		button:SetEnabled(false)
		button:SetAttribute("type", nil)
		button:SetAttribute("macrotext", nil)
		SetStatusText("Destroy spell unavailable")
		return
	end

	local macro = "/cast " .. tostring(spellName) .. "\n/use " .. tostring(candidate.bagID) .. " " .. tostring(candidate.slot)
	button:SetAttribute("type", "macro")
	button:SetAttribute("macrotext", macro)
	button:SetEnabled(true)
end

local function FindRowIndexByKey(rowKey)
	if not rowKey then
		return nil
	end
	for i = 1, #state.dataRows do
		if state.dataRows[i] and state.dataRows[i].rowKey == rowKey then
			return i
		end
	end
	return nil
end

local function UpdateActionState()
	if not state.frame then
		return
	end
	local selectedIndex = FindRowIndexByKey(state.selectedRowKey)
	if not selectedIndex then
		selectedIndex = tonumber(state.selectedIndex) or 1
	end
	local total = #state.dataRows
	if total <= 0 then
		selectedIndex = nil
	elseif selectedIndex < 1 or selectedIndex > total then
		selectedIndex = 1
	end

	state.selectedIndex = selectedIndex or 1
	state.currentCandidate = (selectedIndex and state.dataRows[selectedIndex]) or nil
	state.selectedRowKey = state.currentCandidate and state.currentCandidate.rowKey or nil
	if state.destroyClickLockRowKey and state.selectedRowKey ~= state.destroyClickLockRowKey then
		state.destroyClickLockUntil = 0
		state.destroyClickLockRowKey = nil
	end
	ConfigureDestroyButton()
	if state.frame.nextText then
		if state.currentCandidate then
			state.frame.nextText:SetText(
				"Next: " .. tostring(state.currentCandidate.itemName or "-") .. " (" .. tostring(state.currentCandidate.destroyType or "-") .. ")"
			)
		else
			state.frame.nextText:SetText("Next: -")
		end
	end
	if state.frame.skipButton then
		state.frame.skipButton:SetEnabled(state.currentCandidate ~= nil and #state.dataRows > 1)
	end
end

local function RenderVisibleRows()
	if not state.frame or not state.frame.scrollFrame then
		return
	end

	local total = #state.dataRows
	FauxScrollFrame_Update(state.frame.scrollFrame, total, VISIBLE_ROWS, ROW_HEIGHT)
	local offset = FauxScrollFrame_GetOffset(state.frame.scrollFrame) or 0

	for visualIndex = 1, VISIBLE_ROWS do
		local rowFrame = state.listRows[visualIndex]
		local dataIndex = offset + visualIndex
		local row = state.dataRows[dataIndex]
		if row then
			rowFrame.rowKey = row.rowKey
			rowFrame.itemLink = row.itemLink
			rowFrame.icon:SetTexture(GetItemIcon(row.itemID or 0))
			rowFrame.name:SetText(tostring(row.itemName or "-"))
			if row.rowKey and row.rowKey == state.selectedRowKey then
				rowFrame.bg:SetColorTexture(0.13, 0.20, 0.10, 0.45)
			else
				rowFrame.bg:SetColorTexture(0.08, 0.08, 0.10, (visualIndex % 2 == 0) and 0.28 or 0.16)
			end
			rowFrame:Show()
		else
			rowFrame.rowKey = nil
			rowFrame.itemLink = nil
			rowFrame:Hide()
		end
	end

	if state.frame.emptyText then
		state.frame.emptyText:SetShown(total == 0)
	end
end

local function RefreshData()
	if not GM.DestroyScan or not GM.DestroyScan.Scan then
		state.dataRows = {}
		state.summary = { ready = 0, skipped = 0, blocked = 0 }
		state.knownSpells = { knowsDisenchant = false, knowsMill = false, knowsProspect = false }
		UpdateTopInfo()
		UpdateSummaryText()
		UpdateActionState()
		RenderVisibleRows()
		SetStatusText("Destroy scan unavailable")
		return
	end

	local rows, summary, known = GM.DestroyScan.Scan()
	state.dataRows = rows or {}
	state.summary = summary or { ready = 0, skipped = 0, blocked = 0 }
	state.knownSpells = known or { knowsDisenchant = false, knowsMill = false, knowsProspect = false }

	UpdateTopInfo()
	UpdateSummaryText()
	UpdateActionState()
	RenderVisibleRows()
	SetStatusText("Ready list updated")
end

local function BuildRow(parent, index)
	local row = CreateFrame("Button", nil, parent)
	row:SetHeight(ROW_HEIGHT - 2)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -((index - 1) * ROW_HEIGHT))
	row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -((index - 1) * ROW_HEIGHT))

	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()
	row.bg:SetColorTexture(0.08, 0.08, 0.10, (index % 2 == 0) and 0.28 or 0.16)

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(16, 16)
	row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)

	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
	row.name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
	row.name:SetJustifyH("LEFT")
	row.name:SetTextColor(0.95, 0.95, 0.95)

	row:SetScript("OnEnter", function(self)
		if not self.itemLink or not GameTooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(self.itemLink)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function()
		if GameTooltip then
			GameTooltip:Hide()
		end
	end)
	row:SetScript("OnClick", function(self)
		if not self.rowKey then
			return
		end
		state.selectedRowKey = self.rowKey
		UpdateActionState()
		RenderVisibleRows()
		if state.currentCandidate then
			SetStatusText("Selected: " .. tostring(state.currentCandidate.itemName or "-"))
		end
	end)

	return row
end

local function CreateDestroyFrame()
	local frame = CreateFrame("Frame", "GorilMailDestroyPanel", UIParent, "BackdropTemplate")
	frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
	frame:SetPoint("CENTER", UIParent, "CENTER", 280, 0)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()

	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.04, 0.04, 0.05, 0.94)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -12)
	title:SetText("Destroy")
	frame.title = title

	local infoText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	infoText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -14)
	infoText:SetJustifyH("RIGHT")
	infoText:SetText("")
	infoText:SetTextColor(0.78, 0.86, 1.0)
	frame.infoText = infoText

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

	local listContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	listContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -40)
	listContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -40)
	listContainer:SetHeight((ROW_HEIGHT * VISIBLE_ROWS) + 8)
	listContainer:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		tile = false,
		edgeSize = 1,
	})
	listContainer:SetBackdropColor(0.03, 0.03, 0.04, 0.75)
	listContainer:SetBackdropBorderColor(0.20, 0.20, 0.24, 0.92)

	local rowsParent = CreateFrame("Frame", nil, listContainer)
	rowsParent:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 2, -2)
	rowsParent:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -24, -2)
	rowsParent:SetHeight(ROW_HEIGHT * VISIBLE_ROWS)

	local scrollFrame = CreateFrame("ScrollFrame", "GorilMailDestroyScrollFrame", listContainer, "FauxScrollFrameTemplate")
	scrollFrame:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -1, -2)
	scrollFrame:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -1, 2)
	scrollFrame:SetWidth(22)
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, RenderVisibleRows)
	end)
	frame.scrollFrame = scrollFrame

	for i = 1, VISIBLE_ROWS do
		state.listRows[i] = BuildRow(rowsParent, i)
	end

	local emptyText = listContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	emptyText:SetPoint("CENTER", listContainer, "CENTER", 0, 0)
	emptyText:SetText("No ready destroy candidates")
	emptyText:SetTextColor(0.78, 0.78, 0.80)
	emptyText:Hide()
	frame.emptyText = emptyText

	local summaryText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	summaryText:SetPoint("TOPLEFT", listContainer, "BOTTOMLEFT", 2, -8)
	summaryText:SetPoint("TOPRIGHT", listContainer, "BOTTOMRIGHT", -2, -8)
	summaryText:SetJustifyH("LEFT")
	summaryText:SetText("Ready: 0 | Skipped: 0 | Blocked: 0")
	frame.summaryText = summaryText

	local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	statusText:SetPoint("TOPLEFT", summaryText, "BOTTOMLEFT", 0, -4)
	statusText:SetPoint("TOPRIGHT", summaryText, "BOTTOMRIGHT", 0, -4)
	statusText:SetJustifyH("LEFT")
	statusText:SetText("Idle")
	frame.statusText = statusText

	local nextText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	nextText:SetPoint("TOPLEFT", statusText, "BOTTOMLEFT", 0, -4)
	nextText:SetPoint("TOPRIGHT", statusText, "BOTTOMRIGHT", 0, -4)
	nextText:SetJustifyH("LEFT")
	nextText:SetText("Next: -")
	nextText:SetTextColor(0.90, 0.92, 1.0)
	frame.nextText = nextText

	local refreshButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	refreshButton:SetSize(86, 22)
	refreshButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
	refreshButton:SetText("Refresh")
	refreshButton:SetScript("OnClick", function()
		RefreshData()
	end)
	frame.refreshButton = refreshButton

	local skipButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	skipButton:SetSize(72, 22)
	skipButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -114, 14)
	skipButton:SetText("Skip")
	skipButton:SetEnabled(false)
	skipButton:SetScript("OnClick", function()
		if not state.currentCandidate or not state.currentCandidate.rowKey then
			return
		end
		local total = #state.dataRows
		if total <= 1 then
			SetStatusText("No next candidate")
			return
		end

		local oldName = tostring(state.currentCandidate.itemName or "-")
		local currentIndex = FindRowIndexByKey(state.currentCandidate.rowKey) or state.selectedIndex or 1
		local nextIndex = currentIndex + 1
		if nextIndex > total then
			nextIndex = 1
		end
		local nextRow = state.dataRows[nextIndex]
		state.skipAdvanceCount = (tonumber(state.skipAdvanceCount) or 0) + 1
		state.selectedIndex = nextIndex
		state.selectedRowKey = nextRow and nextRow.rowKey or nil
		UpdateSummaryText()
		UpdateActionState()
		RenderVisibleRows()
		if state.currentCandidate then
			SetStatusText("Skipped: " .. oldName .. " -> Next: " .. tostring(state.currentCandidate.itemName or "-"))
		else
			SetStatusText("Skipped: " .. oldName)
		end
	end)
	frame.skipButton = skipButton

	local destroyNextButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate,SecureActionButtonTemplate")
	destroyNextButton:SetSize(96, 22)
	destroyNextButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
	destroyNextButton:SetText("Destroy Next")
	destroyNextButton:SetEnabled(false)
	destroyNextButton:RegisterForClicks("LeftButtonUp")
	destroyNextButton:SetScript("PostClick", function(self)
		local c = state.currentCandidate
		local now = (GetTime and GetTime()) or 0
		state.destroyClickLockUntil = now + 0.45
		state.destroyClickLockRowKey = c and c.rowKey or nil
		if not (InCombatLockdown and InCombatLockdown()) then
			self:SetEnabled(false)
		end
		if c then
			SetStatusText("Destroy sent: " .. tostring(c.itemName or "-") .. " (" .. tostring(c.destroyType or "-") .. ")")
		else
			SetStatusText("Destroy action sent")
		end
	end)
	frame.destroyNextButton = destroyNextButton

	frame:SetScript("OnShow", function()
		state.skipAdvanceCount = 0
		state.selectedRowKey = nil
		state.selectedIndex = 1
		RefreshData()
	end)

	if UISpecialFrames then
		local exists = false
		for i = 1, #UISpecialFrames do
			if UISpecialFrames[i] == "GorilMailDestroyPanel" then
				exists = true
				break
			end
		end
		if not exists then
			table.insert(UISpecialFrames, "GorilMailDestroyPanel")
		end
	end

	return frame
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, eventName)
	if not state.frame or not state.frame:IsShown() then
		return
	end
	if eventName == "PLAYER_REGEN_ENABLED" then
		SetStatusText("Combat ended, refreshing")
	end
	RefreshData()
end)

function GM.DestroyUI.Initialize()
	if state.frame then
		return
	end
	state.frame = CreateDestroyFrame()
end

function GM.DestroyUI.Toggle()
	if not state.frame then
		GM.DestroyUI.Initialize()
	end
	if not state.frame then
		return
	end
	if state.frame:IsShown() then
		state.frame:Hide()
	else
		state.frame:Show()
		state.frame:Raise()
	end
end

function GM.DestroyUI.Refresh()
	if state.frame and state.frame:IsShown() then
		RefreshData()
	end
end
