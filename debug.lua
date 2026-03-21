local addonName, GM = ...

GM = GM or {}
GM.DebugPanel = GM.DebugPanel or {}

local MAX_DUMPS = 40
local panelFrame = nil
local panelScroll = nil
local panelEditBox = nil
local panelCountText = nil
local dumpEntries = {}

local function ComputeEditBoxHeight(editBox, text)
	local content = tostring(text or "")
	local lineCount = 1
	local _, newLines = content:gsub("\n", "")
	lineCount = lineCount + (newLines or 0)

	local _, fontSize = editBox:GetFont()
	local size = tonumber(fontSize) or 12
	local lineHeight = math.max(12, math.floor(size + 4))
	return math.max(320, (lineCount * lineHeight) + 24)
end

local function SerializeValue(value, depth, visited)
	depth = depth or 0
	visited = visited or {}

	local valueType = type(value)
	if valueType == "nil" then
		return "nil"
	end
	if valueType == "number" or valueType == "boolean" then
		return tostring(value)
	end
	if valueType == "string" then
		return string.format("%q", value)
	end
	if valueType ~= "table" then
		return "<" .. valueType .. ">"
	end

	if visited[value] then
		return "<cycle>"
	end
	if depth >= 4 then
		return "<max-depth>"
	end

	visited[value] = true
	local parts = {}
	local index = 1
	for key, item in pairs(value) do
		local keyText = "[" .. SerializeValue(key, depth + 1, visited) .. "]"
		parts[index] = keyText .. " = " .. SerializeValue(item, depth + 1, visited)
		index = index + 1
	end
	visited[value] = nil

	table.sort(parts)
	return "{ " .. table.concat(parts, ", ") .. " }"
end

local function BuildDumpBlock(label, payload)
	local timestamp = date("%Y-%m-%d %H:%M:%S")
	local title = "[" .. tostring(timestamp) .. "] " .. tostring(label or "Debug")
	local body = ""
	if type(payload) == "string" then
		body = payload
	else
		body = SerializeValue(payload, 0, {})
	end
	return title .. "\n" .. body
end

local function RefreshPanelText()
	if not panelEditBox then
		return
	end
	local content = table.concat(dumpEntries, "\n\n")
	panelEditBox:SetText(content)
	local targetHeight = ComputeEditBoxHeight(panelEditBox, content)
	panelEditBox:SetHeight(targetHeight)
	if panelCountText then
		panelCountText:SetText("Dumps: " .. tostring(#dumpEntries))
	end
end

local function EnsurePanel()
	if panelFrame then
		return panelFrame
	end

	local frame = CreateFrame("Frame", "GorilMailDebugPanel", UIParent, "BackdropTemplate")
	frame:SetSize(760, 430)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	frame:SetBackdropBorderColor(0.65, 0.65, 0.65, 0.95)
	frame:Hide()
	panelFrame = frame

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
	title:SetText("GorilMail Debug")

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 2, 2)

	local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clearButton:SetSize(72, 20)
	clearButton:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -8, -2)
	clearButton:SetText("Clear")
	clearButton:SetScript("OnClick", function()
		wipe(dumpEntries)
		RefreshPanelText()
	end)

	local selectButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	selectButton:SetSize(90, 20)
	selectButton:SetPoint("RIGHT", clearButton, "LEFT", -6, 0)
	selectButton:SetText("Select All")
	selectButton:SetScript("OnClick", function()
		if panelEditBox then
			panelEditBox:SetFocus()
			panelEditBox:HighlightText()
		end
	end)

	local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("LEFT", selectButton, "RIGHT", 8, 0)
	hint:SetText("Ctrl+C")

	local countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	countText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 10)
	countText:SetText("Dumps: 0")
	panelCountText = countText

	local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -40)
	scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 30)
	panelScroll = scroll

	local editBox = CreateFrame("EditBox", nil, scroll)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetWidth(700)
	editBox:SetTextInsets(2, 2, 2, 2)
	editBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	editBox:SetScript("OnTextChanged", function(self)
		local newHeight = ComputeEditBoxHeight(self, self:GetText() or "")
		self:SetHeight(newHeight)
	end)
	scroll:SetScrollChild(editBox)
	panelEditBox = editBox

	RefreshPanelText()
	return frame
end

function GM.DebugPanel.AppendDump(label, payload)
	local block = BuildDumpBlock(label, payload)
	dumpEntries[#dumpEntries + 1] = block
	if #dumpEntries > MAX_DUMPS then
		table.remove(dumpEntries, 1)
	end
	RefreshPanelText()
end

function GM.DebugPanel.Toggle()
	local frame = EnsurePanel()
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
		if panelEditBox then
			panelEditBox:ClearFocus()
		end
	end
end

function GM.DebugPanel.Show()
	local frame = EnsurePanel()
	frame:Show()
end

function GM.DebugPanel.Initialize()
	EnsurePanel()
end
