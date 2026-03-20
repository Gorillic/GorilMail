local addonName, GM = ...

GM = GM or {}

GM.UI = GM.UI or {}

local ROW_HEIGHT = 19
local VISIBLE_ROW_COUNT = 10
local COL_GAP = 5
local COL_SENDER = 100
local COL_SUBJECT = 150
local COL_MONEY = 100
local COL_COD = 48
local COL_ITEM = 40
local COL_STATE = 38
local COL_ACTION = 42
local REFRESH_COOLDOWN_SECONDS = 10
local DETAIL_PANEL_WIDTH = 246
local DETAIL_PANEL_HEIGHT = 232
local DETAIL_FRAME_GAP = 6
local RESIZE_MIN_WIDTH = 640
local RESIZE_MIN_HEIGHT = 340
local RESIZE_MAX_WIDTH = 1600
local RESIZE_MAX_HEIGHT = 1200
local RESIZE_THROTTLE_SECONDS = 0.05
local RenderInboxRows
local EnsureVisibleRows
local ApplyResizeLayout
local ApplyViewMode
local SetViewMode
local SetDetailPanelOpen

local THEMES = {
	Horde = {
		name = "Horde",
		colors = {
			panelBg = { 0.06, 0.04, 0.04, 0.94 },
			panelBorder = { 0.45, 0.25, 0.18, 0.95 },
			toolbarBg = { 0.10, 0.06, 0.06, 0.95 },
			toolbarBorder = { 0.52, 0.30, 0.22, 0.95 },
			surfaceBg = { 0.09, 0.06, 0.06, 0.84 },
			surfaceBorder = { 0.38, 0.24, 0.18, 0.86 },
			headerBg = { 0.24, 0.12, 0.10, 0.68 },
			rowEvenBg = { 0.22, 0.12, 0.10, 0.14 },
			rowOddBg = { 0.18, 0.09, 0.08, 0.12 },
			rowUnreadEvenBg = { 0.30, 0.16, 0.12, 0.22 },
			rowUnreadOddBg = { 0.26, 0.14, 0.11, 0.20 },
			rowHoverBg = { 0.30, 0.16, 0.13, 0.24 },
			rowSelectedBg = { 0.50, 0.24, 0.14, 0.78 },
			title = { 0.98, 0.87, 0.72 },
			label = { 0.88, 0.78, 0.67 },
			accent = { 0.72, 0.24, 0.18 },
			summaryBorder = { 0.52, 0.32, 0.22, 0.90 },
			listBorder = { 0.44, 0.27, 0.19, 0.88 },
			detailBg = { 0.11, 0.07, 0.07, 0.90 },
			detailBorder = { 0.46, 0.28, 0.20, 0.90 },
			detailHeaderBg = { 0.34, 0.16, 0.12, 0.58 },
			detailBodyBg = { 0.11, 0.08, 0.07, 0.82 },
			detailBodyBorder = { 0.50, 0.30, 0.21, 0.86 },
			detailItemBorder = { 0.38, 0.24, 0.18, 0.75 },
			detailItemBorderFallback = { 0.58, 0.36, 0.24, 0.85 },
			scrollDivider = { 0.75, 0.50, 0.34, 0.18 },
			unreadDotRead = { 0.28, 0.20, 0.18, 0.35 },
			unreadDotUnread = { 0.82, 0.34, 0.22, 0.95 },
		},
		text = {
			buttonDisabled = { 0.60, 0.60, 0.60 },
			header = { 0.95, 0.84, 0.70 },
			inboxGold = { 0.98, 0.80, 0.42 },
			inboxCount = { 0.90, 0.78, 0.64 },
			rowRead = { 0.70, 0.64, 0.60 },
			rowUnreadSender = { 0.98, 0.89, 0.80 },
			rowUnreadSubject = { 1.00, 0.78, 0.52 },
			rowItem = { 0.90, 0.84, 0.76 },
			detailFrom = { 0.97, 0.90, 0.82 },
			detailSubject = { 0.98, 0.76, 0.48 },
			detailMeta = { 0.88, 0.77, 0.68 },
			detailItem = { 0.90, 0.82, 0.74 },
			detailBody = { 0.92, 0.85, 0.78 },
		},
		status = {
			ok = { 0.58, 0.74, 0.50 },
			blocked = { 0.84, 0.42, 0.33 },
			refreshSuccess = { 0.76, 0.84, 0.66 },
			refreshError = { 0.88, 0.42, 0.33 },
			buttonBorderDisabled = { 0.24, 0.24, 0.24, 0.75 },
		},
		buttons = {
			primary = {
				text = { 0.99, 0.90, 0.74 },
				bg = { 0.34, 0.14, 0.09, 0.90 },
				hover = { 0.43, 0.18, 0.11, 0.95 },
				down = { 0.27, 0.11, 0.07, 0.98 },
				border = { 0.82, 0.48, 0.25, 0.90 },
				disabled = { 0.12, 0.09, 0.08, 0.68 },
			},
			accent = {
				text = { 0.96, 0.84, 0.74 },
				bg = { 0.24, 0.10, 0.10, 0.90 },
				hover = { 0.30, 0.13, 0.12, 0.95 },
				down = { 0.18, 0.08, 0.08, 0.98 },
				border = { 0.70, 0.28, 0.22, 0.90 },
				disabled = { 0.12, 0.09, 0.08, 0.68 },
			},
			row = {
				text = { 0.95, 0.86, 0.76 },
				bg = { 0.24, 0.12, 0.09, 0.90 },
				hover = { 0.32, 0.16, 0.11, 0.96 },
				down = { 0.18, 0.08, 0.06, 0.98 },
				border = { 0.68, 0.34, 0.24, 0.88 },
				disabled = { 0.12, 0.09, 0.08, 0.62 },
			},
			normal = {
				text = { 0.90, 0.84, 0.78 },
				bg = { 0.16, 0.10, 0.09, 0.88 },
				hover = { 0.22, 0.14, 0.12, 0.94 },
				down = { 0.12, 0.08, 0.07, 0.98 },
				border = { 0.46, 0.28, 0.22, 0.85 },
				disabled = { 0.12, 0.10, 0.09, 0.65 },
			},
		},
	},
	Alliance = {
		name = "Alliance",
		colors = {
			panelBg = { 0.05, 0.07, 0.10, 0.94 },
			panelBorder = { 0.30, 0.40, 0.55, 0.95 },
			toolbarBg = { 0.08, 0.11, 0.16, 0.95 },
			toolbarBorder = { 0.38, 0.50, 0.66, 0.95 },
			surfaceBg = { 0.07, 0.10, 0.15, 0.84 },
			surfaceBorder = { 0.28, 0.38, 0.52, 0.86 },
			headerBg = { 0.12, 0.20, 0.30, 0.68 },
			rowEvenBg = { 0.11, 0.16, 0.23, 0.16 },
			rowOddBg = { 0.09, 0.14, 0.21, 0.14 },
			rowUnreadEvenBg = { 0.15, 0.24, 0.34, 0.24 },
			rowUnreadOddBg = { 0.13, 0.21, 0.31, 0.22 },
			rowHoverBg = { 0.18, 0.28, 0.40, 0.26 },
			rowSelectedBg = { 0.24, 0.41, 0.60, 0.72 },
			title = { 0.90, 0.95, 1.00 },
			label = { 0.76, 0.84, 0.93 },
			accent = { 0.35, 0.56, 0.79 },
			summaryBorder = { 0.34, 0.45, 0.60, 0.90 },
			listBorder = { 0.30, 0.40, 0.55, 0.88 },
			detailBg = { 0.08, 0.11, 0.16, 0.90 },
			detailBorder = { 0.34, 0.45, 0.60, 0.90 },
			detailHeaderBg = { 0.16, 0.25, 0.36, 0.58 },
			detailBodyBg = { 0.08, 0.12, 0.17, 0.82 },
			detailBodyBorder = { 0.36, 0.47, 0.63, 0.86 },
			detailItemBorder = { 0.30, 0.41, 0.56, 0.75 },
			detailItemBorderFallback = { 0.40, 0.54, 0.72, 0.85 },
			scrollDivider = { 0.62, 0.76, 0.94, 0.18 },
			unreadDotRead = { 0.22, 0.30, 0.40, 0.35 },
			unreadDotUnread = { 0.46, 0.72, 1.00, 0.95 },
		},
		text = {
			buttonDisabled = { 0.60, 0.60, 0.60 },
			header = { 0.87, 0.93, 1.00 },
			inboxGold = { 0.98, 0.85, 0.50 },
			inboxCount = { 0.80, 0.88, 0.97 },
			rowRead = { 0.66, 0.74, 0.82 },
			rowUnreadSender = { 0.93, 0.97, 1.00 },
			rowUnreadSubject = { 0.86, 0.93, 1.00 },
			rowItem = { 0.84, 0.90, 0.96 },
			detailFrom = { 0.90, 0.95, 1.00 },
			detailSubject = { 0.78, 0.90, 1.00 },
			detailMeta = { 0.78, 0.86, 0.94 },
			detailItem = { 0.84, 0.90, 0.96 },
			detailBody = { 0.86, 0.92, 0.98 },
		},
		status = {
			ok = { 0.58, 0.78, 0.60 },
			blocked = { 0.92, 0.48, 0.42 },
			refreshSuccess = { 0.72, 0.88, 0.78 },
			refreshError = { 0.92, 0.50, 0.44 },
			buttonBorderDisabled = { 0.24, 0.24, 0.24, 0.75 },
		},
		buttons = {
			primary = {
				text = { 0.93, 0.97, 1.00 },
				bg = { 0.16, 0.28, 0.42, 0.90 },
				hover = { 0.22, 0.36, 0.52, 0.95 },
				down = { 0.12, 0.22, 0.34, 0.98 },
				border = { 0.54, 0.72, 0.96, 0.90 },
				disabled = { 0.10, 0.13, 0.18, 0.68 },
			},
			accent = {
				text = { 0.90, 0.95, 1.00 },
				bg = { 0.14, 0.22, 0.34, 0.90 },
				hover = { 0.19, 0.29, 0.44, 0.95 },
				down = { 0.10, 0.17, 0.27, 0.98 },
				border = { 0.48, 0.64, 0.86, 0.90 },
				disabled = { 0.10, 0.13, 0.18, 0.68 },
			},
			row = {
				text = { 0.88, 0.94, 1.00 },
				bg = { 0.14, 0.23, 0.34, 0.90 },
				hover = { 0.20, 0.31, 0.46, 0.96 },
				down = { 0.11, 0.19, 0.29, 0.98 },
				border = { 0.44, 0.60, 0.80, 0.88 },
				disabled = { 0.10, 0.13, 0.18, 0.62 },
			},
			normal = {
				text = { 0.84, 0.90, 0.98 },
				bg = { 0.11, 0.18, 0.28, 0.88 },
				hover = { 0.16, 0.24, 0.37, 0.94 },
				down = { 0.09, 0.14, 0.23, 0.98 },
				border = { 0.36, 0.50, 0.68, 0.85 },
				disabled = { 0.10, 0.14, 0.20, 0.65 },
			},
		},
	},
}

local ACTIVE_THEME_NAME = "Horde"
local ACTIVE_THEME = THEMES.Horde
local ACTIVE_THEME_BUTTONS = (ACTIVE_THEME and ACTIVE_THEME.buttons) or {}
local THEME = (ACTIVE_THEME and ACTIVE_THEME.colors) or {}
local THEME_TEXT = (ACTIVE_THEME and ACTIVE_THEME.text) or {}
local THEME_STATUS = (ACTIVE_THEME and ACTIVE_THEME.status) or {}
local ApplyThemeToUI
local UpdateThemeToggleVisual

local VALID_ANCHOR_POINTS = {
	TOPLEFT = true,
	TOP = true,
	TOPRIGHT = true,
	LEFT = true,
	CENTER = true,
	RIGHT = true,
	BOTTOMLEFT = true,
	BOTTOM = true,
	BOTTOMRIGHT = true,
}

local function WithFallback(primary, fallback)
	if type(primary) ~= "table" then
		return fallback or {}
	end
	if type(fallback) ~= "table" then
		return primary
	end
	return setmetatable(primary, { __index = fallback })
end

local function ResolveActiveTheme(themeName)
	local fallbackTheme = THEMES.Horde or {}
	local selectedName = tostring(themeName or "Horde")
	local selectedTheme = THEMES[selectedName]
	if type(selectedTheme) ~= "table" then
		selectedName = "Horde"
		selectedTheme = fallbackTheme
	end

	local fallbackColors = type(fallbackTheme.colors) == "table" and fallbackTheme.colors or {}
	local fallbackText = type(fallbackTheme.text) == "table" and fallbackTheme.text or {}
	local fallbackStatus = type(fallbackTheme.status) == "table" and fallbackTheme.status or {}
	local fallbackButtons = type(fallbackTheme.buttons) == "table" and fallbackTheme.buttons or {}

	ACTIVE_THEME_NAME = selectedName
	ACTIVE_THEME = selectedTheme
	THEME = WithFallback(selectedTheme.colors, fallbackColors)
	THEME_TEXT = WithFallback(selectedTheme.text, fallbackText)
	THEME_STATUS = WithFallback(selectedTheme.status, fallbackStatus)
	ACTIVE_THEME_BUTTONS = WithFallback(selectedTheme.buttons, fallbackButtons)
end

ResolveActiveTheme(ACTIVE_THEME_NAME)

local function SetActiveTheme(themeName)
	ResolveActiveTheme(themeName)

	ApplyThemeToUI()
	UpdateThemeToggleVisual()

	if RenderInboxRows then
		RenderInboxRows()
	end
end

local function SaveMainFramePosition(frame)
	if not frame then
		return
	end
	local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
	if not point then
		return
	end
	_G.GorilMailUIPos = _G.GorilMailUIPos or {}
	_G.GorilMailUIPos.point = point
	_G.GorilMailUIPos.relativePoint = relativePoint
	_G.GorilMailUIPos.x = xOfs
	_G.GorilMailUIPos.y = yOfs
end

local function RestoreMainFramePosition(frame)
	if not frame then
		return false
	end
	local pos = _G.GorilMailUIPos
	if type(pos) ~= "table" or not pos.point or not pos.relativePoint then
		return false
	end
	if not VALID_ANCHOR_POINTS[pos.point] or not VALID_ANCHOR_POINTS[pos.relativePoint] then
		return false
	end
	local x = tonumber(pos.x)
	local y = tonumber(pos.y)
	if not x or not y then
		return false
	end
	frame:ClearAllPoints()
	frame:SetPoint(pos.point, UIParent, pos.relativePoint, x, y)
	return true
end

local function GetButtonPalette(variant)
	local buttons = ACTIVE_THEME_BUTTONS or {}
	return buttons[variant] or buttons.normal or {}
end

local function StyleButton(button, variant)
	if not button then
		return
	end
	button.gmPalette = GetButtonPalette(variant)

	if not button.gmSkinBg then
		local bg = button:CreateTexture(nil, "BACKGROUND", nil, -2)
		bg:SetTexture("Interface\\Buttons\\WHITE8x8")
		bg:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
		bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
		button.gmSkinBg = bg
	end
	if not button.gmSkinBorder then
		local border = button:CreateTexture(nil, "BORDER")
		border:SetTexture("Interface\\Buttons\\WHITE8x8")
		border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
		border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
		button.gmSkinBorder = border
	end

	local function ApplyVisual(state)
		local palette = button.gmPalette or GetButtonPalette(variant)
		local textColor = palette.text or THEME_TEXT.buttonDisabled or { 0.60, 0.60, 0.60 }
		local disabledBg = palette.disabled or { 0.12, 0.10, 0.09, 0.65 }
		local downBg = palette.down or palette.bg or disabledBg
		local hoverBg = palette.hover or palette.bg or disabledBg
		local normalBg = palette.bg or disabledBg
		local borderColor = palette.border or THEME_STATUS.buttonBorderDisabled or { 0.24, 0.24, 0.24, 0.75 }
		local fs = button:GetFontString()
		if fs then
			if button:IsEnabled() then
				fs:SetTextColor(unpack(textColor))
			else
				fs:SetTextColor(unpack(THEME_TEXT.buttonDisabled or { 0.60, 0.60, 0.60 }))
			end
		end
		if not button:IsEnabled() then
			button.gmSkinBg:SetColorTexture(unpack(disabledBg))
			button.gmSkinBorder:SetColorTexture(unpack(THEME_STATUS.buttonBorderDisabled or { 0.24, 0.24, 0.24, 0.75 }))
			return
		end
		if state == "down" then
			button.gmSkinBg:SetColorTexture(unpack(downBg))
		elseif state == "hover" then
			button.gmSkinBg:SetColorTexture(unpack(hoverBg))
		else
			button.gmSkinBg:SetColorTexture(unpack(normalBg))
		end
		button.gmSkinBorder:SetColorTexture(unpack(borderColor))
	end

	if not button.gmSkinInit then
		button:HookScript("OnEnter", function(self)
			if self:IsEnabled() then
				ApplyVisual("hover")
			end
		end)
		button:HookScript("OnLeave", function(self)
			if self:IsEnabled() then
				ApplyVisual("normal")
			end
		end)
		button:HookScript("OnMouseDown", function(self)
			if self:IsEnabled() then
				ApplyVisual("down")
			end
		end)
		button:HookScript("OnMouseUp", function(self)
			if self:IsEnabled() then
				if self:IsMouseOver() then
					ApplyVisual("hover")
				else
					ApplyVisual("normal")
				end
			end
		end)
		button:HookScript("OnEnable", function()
			ApplyVisual("normal")
		end)
		button:HookScript("OnDisable", function()
			ApplyVisual("disabled")
		end)
		button.gmSkinInit = true
	end

	local fs = button:GetFontString()
	if fs then
		fs:SetShadowColor(0, 0, 0, 0.85)
		fs:SetShadowOffset(1, -1)
	end
	local normal = button:GetNormalTexture()
	local pushed = button:GetPushedTexture()
	local highlight = button:GetHighlightTexture()
	if normal then
		normal:SetVertexColor(1, 1, 1, 0.10)
	end
	if pushed then
		pushed:SetVertexColor(1, 1, 1, 0.05)
	end
	if highlight then
		highlight:SetVertexColor(1, 1, 1, 0.08)
	end
	ApplyVisual("normal")
end

ApplyThemeToUI = function()
	if not GM.UI then
		return
	end

	if GM.UI.frame then
		GM.UI.frame:SetBackdropColor(unpack(THEME.panelBg))
		GM.UI.frame:SetBackdropBorderColor(unpack(THEME.panelBorder))
	end
	if GM.UI.toolbar then
		GM.UI.toolbar:SetBackdropColor(unpack(THEME.toolbarBg))
		GM.UI.toolbar:SetBackdropBorderColor(unpack(THEME.toolbarBorder))
	end
	if GM.UI.toolbarAccent then
		GM.UI.toolbarAccent:SetColorTexture(unpack(THEME.accent))
	end
	if GM.UI.title then
		GM.UI.title:SetTextColor(unpack(THEME.title))
	end
	if GM.UI.summaryBar then
		GM.UI.summaryBar:SetBackdropColor(unpack(THEME.surfaceBg))
		GM.UI.summaryBar:SetBackdropBorderColor(unpack(THEME.summaryBorder))
	end
	if GM.UI.footer then
		GM.UI.footer:SetBackdropColor(unpack(THEME.surfaceBg))
		GM.UI.footer:SetBackdropBorderColor(unpack(THEME.surfaceBorder))
	end
	if GM.UI.listContainer then
		GM.UI.listContainer:SetBackdropColor(unpack(THEME.surfaceBg))
		GM.UI.listContainer:SetBackdropBorderColor(unpack(THEME.listBorder))
	end
	if GM.UI.headerBg then
		GM.UI.headerBg:SetColorTexture(unpack(THEME.headerBg))
	end
	if GM.UI.scrollDivider then
		GM.UI.scrollDivider:SetColorTexture(unpack(THEME.scrollDivider))
	end
	if GM.UI.inboxGoldText then
		GM.UI.inboxGoldText:SetTextColor(unpack(THEME_TEXT.inboxGold))
	end
	if GM.UI.inboxCountText then
		GM.UI.inboxCountText:SetTextColor(unpack(THEME_TEXT.inboxCount))
	end
	if GM.UI.refreshNoticeText then
		local isError = GM.UI.refreshNoticeIsError and true or false
		local hasText = GM.UI.refreshNoticeText:GetText() and GM.UI.refreshNoticeText:GetText() ~= ""
		if hasText then
			if isError then
				GM.UI.refreshNoticeText:SetTextColor(unpack(THEME_STATUS.refreshError))
			else
				GM.UI.refreshNoticeText:SetTextColor(unpack(THEME_STATUS.refreshSuccess))
			end
		else
			GM.UI.refreshNoticeText:SetTextColor(unpack(THEME_STATUS.refreshSuccess))
		end
	end
	if GM.UI.detailPanel then
		GM.UI.detailPanel:SetBackdropColor(unpack(THEME.detailBg))
		GM.UI.detailPanel:SetBackdropBorderColor(unpack(THEME.detailBorder))
	end
	if GM.UI.detailHeaderBg then
		GM.UI.detailHeaderBg:SetColorTexture(unpack(THEME.detailHeaderBg))
	end
	if GM.UI.detailFromText then
		GM.UI.detailFromText:SetTextColor(unpack(THEME_TEXT.detailFrom))
	end
	if GM.UI.detailSubjectText then
		GM.UI.detailSubjectText:SetTextColor(unpack(THEME_TEXT.detailSubject))
	end
	if GM.UI.detailMetaText then
		GM.UI.detailMetaText:SetTextColor(unpack(THEME_TEXT.detailMeta))
	end
	if GM.UI.detailItemIconBorder then
		GM.UI.detailItemIconBorder:SetColorTexture(unpack(THEME.detailItemBorder))
	end
	if GM.UI.detailItemText then
		GM.UI.detailItemText:SetTextColor(unpack(THEME_TEXT.detailItem))
	end
	if GM.UI.detailBodyFrame then
		GM.UI.detailBodyFrame:SetBackdropColor(unpack(THEME.detailBodyBg))
		GM.UI.detailBodyFrame:SetBackdropBorderColor(unpack(THEME.detailBodyBorder))
	end
	if GM.UI.detailBodyText then
		GM.UI.detailBodyText:SetTextColor(unpack(THEME_TEXT.detailBody))
	end
	if GM.UI.sendPanel then
		GM.UI.sendPanel:SetBackdropColor(unpack(THEME.surfaceBg))
		GM.UI.sendPanel:SetBackdropBorderColor(unpack(THEME.listBorder))
	end
	if GM.UI.sendBodyFrame then
		GM.UI.sendBodyFrame:SetBackdropColor(unpack(THEME.detailBodyBg))
		GM.UI.sendBodyFrame:SetBackdropBorderColor(unpack(THEME.detailBodyBorder))
	end
	if GM.UI.sendRecipientLabel then
		GM.UI.sendRecipientLabel:SetTextColor(unpack(THEME_TEXT.header))
	end
	if GM.UI.sendSubjectLabel then
		GM.UI.sendSubjectLabel:SetTextColor(unpack(THEME_TEXT.header))
	end
	if GM.UI.sendBodyLabel then
		GM.UI.sendBodyLabel:SetTextColor(unpack(THEME_TEXT.header))
	end
	if GM.UI.sendRecipientInput then
		GM.UI.sendRecipientInput:SetTextColor(unpack(THEME_TEXT.detailBody))
	end
	if GM.UI.sendSubjectInput then
		GM.UI.sendSubjectInput:SetTextColor(unpack(THEME_TEXT.detailBody))
	end
	if GM.UI.sendBodyInput then
		GM.UI.sendBodyInput:SetTextColor(unpack(THEME_TEXT.detailBody))
	end
	if GM.UI.headerCells then
		for i = 1, #GM.UI.headerCells do
			local cell = GM.UI.headerCells[i]
			if cell and cell.SetTextColor then
				cell:SetTextColor(unpack(THEME_TEXT.header))
			end
		end
	end

	if GM.UI.returnButton then
		StyleButton(GM.UI.returnButton, "accent")
	end
	if GM.UI.defaultUIButton then
		StyleButton(GM.UI.defaultUIButton, "accent")
	end
	if GM.UI.modeInboxButton then
		StyleButton(GM.UI.modeInboxButton, "normal")
	end
	if GM.UI.modeSendButton then
		StyleButton(GM.UI.modeSendButton, "normal")
	end
	if GM.UI.refreshButton then
		StyleButton(GM.UI.refreshButton, "normal")
	end
	if GM.UI.collectAllButton then
		StyleButton(GM.UI.collectAllButton, "primary")
	end
	if GM.UI.detailCollectButton then
		StyleButton(GM.UI.detailCollectButton, "primary")
	end
	if GM.UI.sendSendButton then
		StyleButton(GM.UI.sendSendButton, "primary")
	end
	if GM.UI.sendClearButton then
		StyleButton(GM.UI.sendClearButton, "normal")
	end
	if GM.UI.rows then
		for i = 1, #GM.UI.rows do
			local row = GM.UI.rows[i]
			if row and row.collectButton then
				StyleButton(row.collectButton, "row")
			end
		end
	end
	if ApplyViewMode then
		ApplyViewMode()
	end
end

UpdateThemeToggleVisual = function()
	if not GM.UI then
		return
	end
	if GM.UI.themeAllianceButton then
		StyleButton(GM.UI.themeAllianceButton, ACTIVE_THEME_NAME == "Alliance" and "primary" or "normal")
	end
	if GM.UI.themeHordeButton then
		StyleButton(GM.UI.themeHordeButton, ACTIVE_THEME_NAME == "Horde" and "primary" or "normal")
	end
end

local function EnsureReturnToAddonButton()
	if GM.UI and GM.UI.returnButton then
		return GM.UI.returnButton
	end
	if not MailFrame then
		return nil
	end

	local button = CreateFrame("Button", "GorilMailReturnButton", MailFrame, "UIPanelButtonTemplate")
	button:SetSize(84, 20)
	button:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -36, -26)
	button:SetText("GorilMail")
	button:SetScript("OnClick", function()
		GM.UI.showingDefaultUI = false
		if GM.UI and GM.UI.frame then
			GM.UI.frame:Show()
			RenderInboxRows()
		end
		if MailFrame then
			MailFrame:SetAlpha(0)
			MailFrame:EnableMouse(false)
		end
		if GM.UI and GM.UI.returnButton then
			GM.UI.returnButton:Hide()
		end
	end)
	StyleButton(button, "accent")
	button:Hide()
	GM.UI.returnButton = button
	return button
end

local function CloseDefaultMailDetailPanels()
	local openMailFrame = _G and _G.OpenMailFrame
	if openMailFrame and openMailFrame.IsShown and openMailFrame:IsShown() then
		openMailFrame:Hide()
	end
end

local function ApplyMailSwapVisibility()
	if not MailFrame then
		if GM.UI and GM.UI.frame then
			if not GM.UI.frame:IsShown() then
				GM.UI.frame:Show()
			end
		end
		return
	end

	local returnButton = EnsureReturnToAddonButton()
	if GM.UI and GM.UI.showingDefaultUI then
		if GM.UI.frame then
			if GM.UI.frame:IsShown() then
				GM.UI.frame:Hide()
			end
		end
		MailFrame:SetAlpha(1)
		MailFrame:EnableMouse(true)
		if returnButton then
			returnButton:Show()
		end
	else
		CloseDefaultMailDetailPanels()
		MailFrame:SetAlpha(0)
		MailFrame:EnableMouse(false)
		if GM.UI.frame then
			if not GM.UI.frame:IsShown() then
				GM.UI.frame:Show()
			end
		end
		if returnButton then
			returnButton:Hide()
		end
	end
end

local function FindRowByMailIndex(rows, mailIndex)
	for i = 1, #rows do
		if rows[i].index == mailIndex then
			return rows[i]
		end
	end
	return nil
end

local function SetStatusText(text)
	if GM.UI and GM.UI.statusText then
		GM.UI.statusText:SetText("Status: " .. text)
	end
end

local function HideRefreshNotice()
	if not GM.UI then
		return
	end
	if GM.UI.refreshNoticeTimer then
		GM.UI.refreshNoticeTimer:Cancel()
		GM.UI.refreshNoticeTimer = nil
	end
	if GM.UI.refreshNoticeText then
		GM.UI.refreshNoticeText:SetText("")
	end
	GM.UI.refreshNoticeIsError = nil
end

local function ShowRefreshNotice(text, isError)
	if not GM.UI or not GM.UI.refreshNoticeText then
		return
	end
	HideRefreshNotice()
	GM.UI.refreshNoticeText:SetText(tostring(text or ""))
	GM.UI.refreshNoticeIsError = isError and true or false
	if isError then
		GM.UI.refreshNoticeText:SetTextColor(unpack(THEME_STATUS.refreshError))
	else
		GM.UI.refreshNoticeText:SetTextColor(unpack(THEME_STATUS.refreshSuccess))
	end
	GM.UI.refreshNoticeTimer = C_Timer.NewTimer(1.6, function()
		if GM.UI and GM.UI.refreshNoticeText then
			GM.UI.refreshNoticeText:SetText("")
		end
		if GM.UI then
			GM.UI.refreshNoticeTimer = nil
		end
	end)
end

local function UpdateRefreshButtonCountdown()
	if not GM.UI or not GM.UI.refreshButton then
		return
	end
	local button = GM.UI.refreshButton
	local endAt = GM.UI.refreshCooldownEndAt
	if not endAt then
		button:SetEnabled(true)
		button:SetText("Refresh")
		return
	end

	local remaining = math.ceil(endAt - GetTime())
	if remaining <= 0 then
		GM.UI.refreshCooldownEndAt = nil
		button:SetEnabled(true)
		button:SetText("Refresh")
		if GM.UI.refreshCooldownTicker then
			GM.UI.refreshCooldownTicker:Cancel()
			GM.UI.refreshCooldownTicker = nil
		end
		return
	end

	button:SetEnabled(false)
	button:SetText("Refresh (" .. tostring(remaining) .. ")")
end

local function StopRefreshCooldown()
	if not GM.UI then
		return
	end
	if GM.UI.refreshCooldownTicker then
		GM.UI.refreshCooldownTicker:Cancel()
		GM.UI.refreshCooldownTicker = nil
	end
	GM.UI.refreshCooldownEndAt = nil
	UpdateRefreshButtonCountdown()
end

local function StartRefreshCooldown()
	if not GM.UI then
		return
	end
	GM.UI.refreshCooldownEndAt = GetTime() + REFRESH_COOLDOWN_SECONDS
	UpdateRefreshButtonCountdown()

	if GM.UI.refreshCooldownTicker then
		GM.UI.refreshCooldownTicker:Cancel()
	end
	GM.UI.refreshCooldownTicker = C_Timer.NewTicker(0.1, function()
		UpdateRefreshButtonCountdown()
	end)
end

local function CompactSubject(subject)
	local text = tostring(subject or "-")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	text = text:gsub("^Auction successful:%s*", "")
	text = text:gsub("^Auction expired:%s*", "")
	text = text:gsub("^Auction cancelled:%s*", "")
	text = text:gsub("^Sale pending:%s*", "")
	return text ~= "" and text or "-"
end

local function TrimText(value)
	local text = tostring(value or "")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	return text
end

local function FormatMoney(copper)
	if not copper or copper <= 0 then
		return "-"
	end
	if GetCoinTextureString then
		return GetCoinTextureString(copper)
	end
	return tostring(copper)
end

local function UpdateInboxGoldText()
	if not GM.UI or not GM.UI.inboxGoldText then
		return
	end
	local mailbox = GM.Mailbox
	if not mailbox or not mailbox.GetRows then
		GM.UI.inboxGoldText:SetText("Inbox Gold: -")
		return
	end
	local rows = mailbox.GetRows() or {}
	local totalGold = 0
	for i = 1, #rows do
		totalGold = totalGold + (rows[i].money or 0)
	end
	GM.UI.inboxGoldText:SetText("Inbox Gold: " .. FormatMoney(totalGold))
end

local function UpdateInboxCountText()
	if not GM.UI or not GM.UI.inboxCountText then
		return
	end
	local mailbox = GM.Mailbox
	if not mailbox or not mailbox.GetRows or not mailbox.IsOpen or not mailbox.IsOpen() then
		GM.UI.inboxCountText:SetText("Inbox Mails: 0")
		return
	end
	local rows = mailbox.GetRows() or {}
	GM.UI.inboxCountText:SetText("Inbox Mails: " .. tostring(#rows))
end

local function UpdateCollectAllButtonPosition()
	if not GM.UI or not GM.UI.collectAllButton then
		return
	end
	local button = GM.UI.collectAllButton
	button:ClearAllPoints()
	button:SetPoint("RIGHT", GM.UI.footer, "RIGHT", -6, 0)
end

ApplyViewMode = function()
	if not GM.UI then
		return
	end
	local mode = GM.UI.viewMode or "inbox"
	local isInbox = mode ~= "send"

	if GM.UI.summaryBar then
		GM.UI.summaryBar:SetShown(isInbox)
	end
	if GM.UI.footer then
		GM.UI.footer:SetShown(isInbox)
	end
	if GM.UI.listContainer then
		GM.UI.listContainer:SetShown(isInbox)
	end
	if GM.UI.sendPanel then
		GM.UI.sendPanel:SetShown(not isInbox)
	end
	if not isInbox then
		SetDetailPanelOpen(false)
	end

	if GM.UI.modeInboxButton then
		StyleButton(GM.UI.modeInboxButton, isInbox and "primary" or "normal")
	end
	if GM.UI.modeSendButton then
		StyleButton(GM.UI.modeSendButton, (not isInbox) and "primary" or "normal")
	end
end

SetViewMode = function(mode)
	if mode ~= "inbox" and mode ~= "send" then
		return
	end
	if not GM.UI then
		return
	end
	if GM.UI.viewMode == mode then
		return
	end
	GM.UI.viewMode = mode
	ApplyViewMode()
	if mode == "inbox" and RenderInboxRows then
		RenderInboxRows()
	end
end

local function PositionDetailPanel()
	if not GM.UI or not GM.UI.frame or not GM.UI.detailPanel then
		return
	end
	local frame = GM.UI.frame
	local detailPanel = GM.UI.detailPanel
	local detailWidth = detailPanel:GetWidth() or DETAIL_PANEL_WIDTH
	local gap = DETAIL_FRAME_GAP
	local safetyMargin = 8

	local uiLeft = UIParent:GetLeft() or 0
	local uiRight = UIParent:GetRight() or 0
	local frameLeft = frame:GetLeft() or 0
	local frameRight = frame:GetRight() or 0

	local anchorRight = (frameRight + gap + detailWidth) <= (uiRight - safetyMargin)
	if not anchorRight and (frameLeft - gap - detailWidth) < (uiLeft + safetyMargin) then
		anchorRight = true
	end

	detailPanel:ClearAllPoints()
	if anchorRight then
		detailPanel:SetPoint("TOPLEFT", frame, "TOPRIGHT", gap, 0)
		detailPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", gap, 0)
	else
		detailPanel:SetPoint("TOPRIGHT", frame, "TOPLEFT", -gap, 0)
		detailPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", -gap, 0)
	end
end

SetDetailPanelOpen = function(openValue)
	if not GM.UI then
		return
	end
	GM.UI.detailPanelOpen = openValue and true or false
	PositionDetailPanel()
	UpdateCollectAllButtonPosition()
end

local function BuildDetailBodyText(mailIndex)
	local sections = {}
	if GetInboxText then
		local body = GetInboxText(mailIndex)
		if body and body ~= "" then
			sections[#sections + 1] = body
		end
	end

	if GetInboxInvoiceInfo then
		local invoiceType, itemName, buyerName, bid, buyout, deposit, consignment = GetInboxInvoiceInfo(mailIndex)
		if invoiceType then
			local invoiceLines = {
				"Invoice: " .. tostring(invoiceType),
			}
			if itemName and itemName ~= "" then
				invoiceLines[#invoiceLines + 1] = "Item: " .. tostring(itemName)
			end
			if buyerName and buyerName ~= "" then
				invoiceLines[#invoiceLines + 1] = "Buyer: " .. tostring(buyerName)
			end
			if bid and bid > 0 then
				invoiceLines[#invoiceLines + 1] = "Bid: " .. FormatMoney(bid)
			end
			if buyout and buyout > 0 then
				invoiceLines[#invoiceLines + 1] = "Buyout: " .. FormatMoney(buyout)
			end
			if deposit and deposit > 0 then
				invoiceLines[#invoiceLines + 1] = "Deposit: " .. FormatMoney(deposit)
			end
			if consignment and consignment > 0 then
				invoiceLines[#invoiceLines + 1] = "AH Cut: " .. FormatMoney(consignment)
			end
			sections[#sections + 1] = table.concat(invoiceLines, "\n")
		end
	end

	if #sections == 0 then
		return "No mail body content."
	end
	return table.concat(sections, "\n\n")
end

local function UpdateDetailPanel(rows)
	if not GM.UI or not GM.UI.detailPanel then
		return
	end
	local panel = GM.UI.detailPanel
	local selected = GM.UI.selectedMailIndex
	if not GM.UI.detailPanelOpen or not selected then
		if GameTooltip and GM.UI.detailItemHitArea and GameTooltip:IsOwned(GM.UI.detailItemHitArea) then
			GameTooltip:Hide()
		end
		panel:Hide()
		return
	end

	local row = FindRowByMailIndex(rows or {}, selected)
	if not row then
		if GameTooltip and GM.UI.detailItemHitArea and GameTooltip:IsOwned(GM.UI.detailItemHitArea) then
			GameTooltip:Hide()
		end
		panel:Hide()
		return
	end
	panel:Show()

	if GM.UI.detailFromText then
		GM.UI.detailFromText:SetText("From: " .. tostring(row.sender or "-"))
	end
	if GM.UI.detailSubjectText then
		GM.UI.detailSubjectText:SetText("Subject: " .. tostring(row.subject or "-"))
	end
	if GM.UI.detailMetaText then
		local meta = "Money: " .. FormatMoney(row.money) ..
			"   COD: " .. FormatMoney(row.codAmount)
		GM.UI.detailMetaText:SetText(meta)
	end

	if GM.UI.detailItemText and GM.UI.detailItemIcon then
		if row.hasItem and GetInboxItem then
			local itemName, itemTexture, itemCount, itemQuality = GetInboxItem(row.index, 1)
			local itemLink = GetInboxItemLink and GetInboxItemLink(row.index, 1) or nil
			local itemLabel = itemLink or itemName or "Attached Item"
			GM.UI.detailItemText:SetText(tostring(itemLabel))
			GM.UI.detailItemMailIndex = row.index
			GM.UI.detailItemLink = itemLink
			if itemTexture then
				GM.UI.detailItemIcon:SetTexture(itemTexture)
			else
				GM.UI.detailItemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			end
			if GM.UI.detailItemCountText then
				if itemCount and itemCount > 1 then
					GM.UI.detailItemCountText:SetText(tostring(itemCount))
				else
					GM.UI.detailItemCountText:SetText("")
				end
			end
			if GM.UI.detailItemIconBorder then
				local q = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality or -1] or nil
				if q then
					GM.UI.detailItemIconBorder:SetColorTexture(q.r, q.g, q.b, 0.95)
				else
					GM.UI.detailItemIconBorder:SetColorTexture(unpack(THEME.detailItemBorderFallback))
				end
			end
			if GM.UI.detailItemText and not itemLink and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality or -1] then
				local q = ITEM_QUALITY_COLORS[itemQuality or -1]
				GM.UI.detailItemText:SetTextColor(q.r, q.g, q.b)
			elseif GM.UI.detailItemText then
				GM.UI.detailItemText:SetTextColor(unpack(THEME_TEXT.detailItem))
			end
		else
			GM.UI.detailItemText:SetText("No item attachment")
			GM.UI.detailItemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
			GM.UI.detailItemText:SetTextColor(unpack(THEME_TEXT.detailItem))
			GM.UI.detailItemMailIndex = nil
			GM.UI.detailItemLink = nil
			if GM.UI.detailItemCountText then
				GM.UI.detailItemCountText:SetText("")
			end
			if GM.UI.detailItemIconBorder then
				GM.UI.detailItemIconBorder:SetColorTexture(unpack(THEME.detailItemBorder))
			end
		end
		if GM.UI.detailItemHitArea then
			GM.UI.detailItemHitArea:SetEnabled(GM.UI.detailItemMailIndex ~= nil)
		end
	end
	if GM.UI.detailBodyText and GM.UI.detailBodyChild and GM.UI.detailBodyScroll then
		local bodyText = BuildDetailBodyText(row.index)
		GM.UI.detailBodyText:SetText(bodyText)
		local scrollHeight = GM.UI.detailBodyScroll:GetHeight() or 1
		local contentHeight = (GM.UI.detailBodyText:GetStringHeight() or 0) + 12
		GM.UI.detailBodyChild:SetHeight(math.max(scrollHeight, contentHeight))
		GM.UI.detailBodyScroll:SetVerticalScroll(0)
	end

	if GM.UI.detailCollectButton then
		local collectorState = GM.Collector and GM.Collector.GetState and GM.Collector.GetState() or "idle"
		local collectorBusy = collectorState == "collecting" or collectorState == "waitingRefresh"
		GM.UI.detailCollectButton:SetEnabled(row.canCollect and not collectorBusy)
	end
end

function RenderInboxRows()
	if not GM.UI or not GM.UI.rows or not GM.UI.scrollFrame then
		return
	end
	if EnsureVisibleRows then
		EnsureVisibleRows()
	end
	local visibleRowCount = GM.UI.visibleRowCount or #GM.UI.rows
	UpdateInboxGoldText()
	UpdateInboxCountText()

	local mailbox = GM.Mailbox
	if not mailbox or not mailbox.IsOpen or not mailbox.IsOpen() then
		for i = 1, #GM.UI.rows do
			GM.UI.rows[i]:Hide()
		end
		FauxScrollFrame_Update(GM.UI.scrollFrame, 0, visibleRowCount, ROW_HEIGHT)
		SetDetailPanelOpen(false)
		UpdateDetailPanel({})
		SetStatusText("Idle (mailbox closed)")
		return
	end

	local dataRows = mailbox.GetRows and mailbox.GetRows() or {}
	if GM.UI and GM.UI.refreshAwaitingCompletion then
		GM.UI.refreshAwaitingCompletion = false
		ShowRefreshNotice("Inbox refreshed", false)
	end
	local totalRows = #dataRows
	local collectableCount, blockedCount = 0, 0
	for i = 1, totalRows do
		if dataRows[i].canCollect then
			collectableCount = collectableCount + 1
		else
			blockedCount = blockedCount + 1
		end
	end
	FauxScrollFrame_Update(GM.UI.scrollFrame, totalRows, visibleRowCount, ROW_HEIGHT)
	local offset = FauxScrollFrame_GetOffset(GM.UI.scrollFrame)
	local visibleCount = 0
	local selectedStillExists = false
	for i = 1, visibleRowCount do
		local row = GM.UI.rows[i]
		local dataIndex = offset + i
		local data = dataRows[dataIndex]
		if data then
			row.mailIndex = data.index
			row.isRead = data.wasRead and true or false
			row.sender:SetText(data.sender)
			row.subject:SetText(CompactSubject(data.subject))
			row.money:SetText(FormatMoney(data.money))
			row.cod:SetText(FormatMoney(data.codAmount))
			local itemFlag = data.hasItem and "Yes" or "No"
			local collectState = "OK"
			if not data.canCollect then
				collectState = (data.blockedReason == "COD") and "COD" or "EMP"
			end
			row.item:SetText(itemFlag)
			row.state:SetText(collectState)
			row.collectButton:SetShown(true)
			row.collectButton:SetEnabled(data.canCollect)
			row.collectButton:SetText(data.canCollect and "Get" or "NA")
			if data.wasRead then
				row.sender:SetTextColor(unpack(THEME_TEXT.rowRead))
				row.subject:SetTextColor(unpack(THEME_TEXT.rowRead))
				if row.unreadDot then
					row.unreadDot:SetColorTexture(unpack(THEME.unreadDotRead))
				end
			else
				row.sender:SetTextColor(unpack(THEME_TEXT.rowUnreadSender))
				row.subject:SetTextColor(unpack(THEME_TEXT.rowUnreadSubject))
				if row.unreadDot then
					row.unreadDot:SetColorTexture(unpack(THEME.unreadDotUnread))
				end
			end
			row.item:SetTextColor(unpack(THEME_TEXT.rowItem))
			if data.canCollect then
				row.state:SetTextColor(unpack(THEME_STATUS.ok))
			else
				row.state:SetTextColor(unpack(THEME_STATUS.blocked))
			end
			if GM.UI.selectedMailIndex and GM.UI.selectedMailIndex == data.index then
				row.bg:SetColorTexture(unpack(THEME.rowSelectedBg))
				selectedStillExists = true
			elseif not data.wasRead and i % 2 == 0 then
				row.bg:SetColorTexture(unpack(THEME.rowUnreadEvenBg))
			elseif not data.wasRead then
				row.bg:SetColorTexture(unpack(THEME.rowUnreadOddBg))
			elseif i % 2 == 0 then
				row.bg:SetColorTexture(unpack(THEME.rowEvenBg))
			else
				row.bg:SetColorTexture(unpack(THEME.rowOddBg))
			end
			row:Show()
			visibleCount = visibleCount + 1
		else
			row.mailIndex = nil
			row.isRead = true
			row.collectButton:SetShown(false)
			row:Hide()
		end
	end
	if GM.UI.selectedMailIndex and not selectedStillExists then
		GM.UI.selectedMailIndex = nil
		SetDetailPanelOpen(false)
	end
	UpdateDetailPanel(dataRows)

	if visibleCount == 0 then
		SetStatusText("Inbox empty")
	else
		local stateText = nil
		if GM.Collector and GM.Collector.GetState then
			local state = GM.Collector.GetState()
			local note = GM.Collector.GetStatusNote and GM.Collector.GetStatusNote() or nil
			local current, total = 0, 0
			if GM.Collector.GetProgress then
				current, total = GM.Collector.GetProgress()
			end
			if state == "prepared" then
				stateText = "Collector: prepared (" .. tostring(total) .. ")"
			elseif state == "collecting" then
				stateText = "Collector: collecting " .. tostring(current) .. "/" .. tostring(total)
			elseif state == "waitingRefresh" then
				stateText = "Collector: waiting refresh"
			elseif state == "completed" then
				stateText = "Collector: completed"
			elseif state == "error" then
				stateText = "Collector: error"
			end
			if note and note ~= "" and (state == "waitingRefresh" or state == "error") then
				stateText = stateText .. " (" .. note .. ")"
			end
		end
		if stateText then
			SetStatusText(stateText)
		else
			SetStatusText(tostring(collectableCount) .. " collectable | " .. tostring(blockedCount) .. " blocked")
		end
	end
end

local function StartCollectForSingleMail(mailIndex)
	if not mailIndex then
		SetStatusText("Select a mail row first")
		return
	end
	if not GM.Collector or not GM.Collector.Prepare or not GM.Collector.Start then
		SetStatusText("Collector unavailable")
		return
	end
	local rows = {}
	if GM.Mailbox and GM.Mailbox.GetRows then
		rows = GM.Mailbox.GetRows() or {}
	end
	local state = GM.Collector.GetState and GM.Collector.GetState() or "idle"
	if state == "collecting" or state == "waitingRefresh" then
		SetStatusText("Collector already running")
		return
	end
	local selectedRow = FindRowByMailIndex(rows, mailIndex)
	if not selectedRow then
		SetStatusText("Selected mail no longer available")
		return
	end
	GM.UI.selectedMailIndex = mailIndex
	SetDetailPanelOpen(false)
	local summary = GM.Collector.Prepare({ selectedRow })
	SetStatusText("Prepared C:" .. tostring(summary.collectableCount) .. " B:" .. tostring(summary.blockedCount))
	GM.Collector.Start(rows)
	RenderInboxRows()
end

local function CreateHeaderCell(parent, text, width, xOffset, justify)
	local cell = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	cell:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -4)
	cell:SetWidth(width)
	cell:SetJustifyH(justify or "LEFT")
	cell:SetText(text)
	cell:SetTextColor(unpack(THEME_TEXT.header))
	if GM.UI then
		GM.UI.headerCells = GM.UI.headerCells or {}
		GM.UI.headerCells[#GM.UI.headerCells + 1] = cell
	end
	return cell
end

local function CreateRow(container, index, yOffset)
	local row = CreateFrame("Frame", nil, container)
	row:SetPoint("TOPLEFT", container, "TOPLEFT", 6, yOffset)
	row:SetPoint("TOPRIGHT", container, "TOPRIGHT", -6, yOffset)
	row:SetHeight(ROW_HEIGHT)

	row.bg = row:CreateTexture(nil, "BACKGROUND")
	row.bg:SetAllPoints()
	if index % 2 == 0 then
		row.bg:SetColorTexture(unpack(THEME.rowEvenBg))
	else
		row.bg:SetColorTexture(unpack(THEME.rowOddBg))
	end
	row.isRead = true

	row.unreadDot = row:CreateTexture(nil, "OVERLAY")
	row.unreadDot:SetSize(5, 5)
	row.unreadDot:SetPoint("LEFT", row, "LEFT", 4, 0)
	row.unreadDot:SetColorTexture(unpack(THEME.unreadDotRead))

	row:EnableMouse(true)
	row:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" or not self.mailIndex then
			return
		end
		if GM.UI.selectedMailIndex == self.mailIndex and GM.UI.detailPanelOpen then
			SetDetailPanelOpen(false)
			RenderInboxRows()
			return
		end
		GM.UI.selectedMailIndex = self.mailIndex
		SetDetailPanelOpen(true)
		RenderInboxRows()
	end)
	row:SetScript("OnEnter", function(self)
		if GM.UI.selectedMailIndex ~= self.mailIndex then
			self.bg:SetColorTexture(unpack(THEME.rowHoverBg))
		end
	end)
	row:SetScript("OnLeave", function(self)
		if GM.UI.selectedMailIndex ~= self.mailIndex then
			if not self.isRead and index % 2 == 0 then
				self.bg:SetColorTexture(unpack(THEME.rowUnreadEvenBg))
			elseif not self.isRead then
				self.bg:SetColorTexture(unpack(THEME.rowUnreadOddBg))
			elseif index % 2 == 0 then
				self.bg:SetColorTexture(unpack(THEME.rowEvenBg))
			else
				self.bg:SetColorTexture(unpack(THEME.rowOddBg))
			end
		end
	end)

	row.sender = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.sender:SetPoint("LEFT", row, "LEFT", 12, 0)
	row.sender:SetWidth(COL_SENDER)
	row.sender:SetJustifyH("LEFT")

	row.subject = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.subject:SetPoint("LEFT", row.sender, "RIGHT", COL_GAP, 0)
	row.subject:SetWidth(COL_SUBJECT)
	row.subject:SetJustifyH("LEFT")
	row.subject:SetWordWrap(false)

	row.money = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.money:SetPoint("LEFT", row.subject, "RIGHT", COL_GAP, 0)
	row.money:SetWidth(COL_MONEY)
	row.money:SetJustifyH("RIGHT")
	row.money:SetWordWrap(false)

	row.cod = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.cod:SetPoint("LEFT", row.money, "RIGHT", COL_GAP, 0)
	row.cod:SetWidth(COL_COD)
	row.cod:SetJustifyH("CENTER")

	row.item = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.item:SetPoint("LEFT", row.cod, "RIGHT", COL_GAP, 0)
	row.item:SetWidth(COL_ITEM)
	row.item:SetJustifyH("CENTER")

	row.state = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.state:SetPoint("LEFT", row.item, "RIGHT", COL_GAP, 0)
	row.state:SetWidth(COL_STATE)
	row.state:SetJustifyH("CENTER")

	row.actionCell = CreateFrame("Frame", nil, row)
	row.actionCell:SetPoint("LEFT", row.state, "RIGHT", COL_GAP, 0)
	row.actionCell:SetSize(COL_ACTION, ROW_HEIGHT)

	row.collectButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	row.collectButton:SetSize(COL_ACTION - 4, 15)
	row.collectButton:SetPoint("CENTER", row.actionCell, "CENTER", 0, 0)
	row.collectButton:SetText("Get")
	row.collectButton:SetScript("OnClick", function()
		StartCollectForSingleMail(row.mailIndex)
	end)
	StyleButton(row.collectButton, "row")

	return row
end

local function GetTargetVisibleRowCount()
	if not GM.UI or not GM.UI.rowAnchor then
		return VISIBLE_ROW_COUNT
	end
	local h = GM.UI.rowAnchor:GetHeight() or 0
	local count = math.floor((h + 1) / ROW_HEIGHT)
	if count < 1 then
		count = 1
	end
	return count
end

EnsureVisibleRows = function()
	if not GM.UI or not GM.UI.rowAnchor then
		return
	end
	GM.UI.rows = GM.UI.rows or {}
	local rows = GM.UI.rows
	local targetCount = GetTargetVisibleRowCount()
	GM.UI.visibleRowCount = targetCount

	for i = #rows + 1, targetCount do
		rows[i] = CreateRow(GM.UI.rowAnchor, i, 0)
	end

	local rowTop = -2
	for i = 1, #rows do
		local row = rows[i]
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", GM.UI.rowAnchor, "TOPLEFT", 6, rowTop - ((i - 1) * ROW_HEIGHT))
		row:SetPoint("TOPRIGHT", GM.UI.rowAnchor, "TOPRIGHT", -6, rowTop - ((i - 1) * ROW_HEIGHT))
		if i > targetCount then
			row.mailIndex = nil
			row.collectButton:SetShown(false)
			row:Hide()
		end
	end
end

ApplyResizeLayout = function(forceRender)
	if not GM.UI or GM.UI.layoutApplying then
		return
	end
	GM.UI.layoutApplying = true
	if EnsureVisibleRows then
		EnsureVisibleRows()
	end
	RenderInboxRows()
	GM.UI.layoutApplying = false
end

function GM.UI.Initialize()
	if GM.UI.frame then
		return
	end

	local frame = CreateFrame("Frame", "GorilMailPanel", UIParent, "BackdropTemplate")
	frame:SetSize(668, 350)
	frame:SetPoint("CENTER", UIParent, "CENTER", 180, 0)
	if not RestoreMainFramePosition(frame) then
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", UIParent, "CENTER", 180, 0)
	end
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:SetResizable(true)
	if frame.SetResizeBounds then
		frame:SetResizeBounds(RESIZE_MIN_WIDTH, RESIZE_MIN_HEIGHT, RESIZE_MAX_WIDTH, RESIZE_MAX_HEIGHT)
	elseif frame.SetMinResize then
		frame:SetMinResize(RESIZE_MIN_WIDTH, RESIZE_MIN_HEIGHT)
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SaveMainFramePosition(self)
		PositionDetailPanel()
	end)
	frame:SetScript("OnSizeChanged", function(self, width, height)
		if GM.UI and GM.UI.layoutApplying then
			return
		end
		local clampedWidth = math.min(RESIZE_MAX_WIDTH, math.max(RESIZE_MIN_WIDTH, width or self:GetWidth() or RESIZE_MIN_WIDTH))
		local clampedHeight = math.min(RESIZE_MAX_HEIGHT, math.max(RESIZE_MIN_HEIGHT, height or self:GetHeight() or RESIZE_MIN_HEIGHT))
		if math.abs((self:GetWidth() or clampedWidth) - clampedWidth) > 0.5 or math.abs((self:GetHeight() or clampedHeight) - clampedHeight) > 0.5 then
			GM.UI.layoutApplying = true
			self:SetSize(clampedWidth, clampedHeight)
			GM.UI.layoutApplying = false
			return
		end

		local lastW = GM.UI.lastResizeWidth or 0
		local lastH = GM.UI.lastResizeHeight or 0
		if math.abs(clampedWidth - lastW) < 0.5 and math.abs(clampedHeight - lastH) < 0.5 then
			return
		end
		GM.UI.lastResizeWidth = clampedWidth
		GM.UI.lastResizeHeight = clampedHeight
		GM.UI.resizeDirty = true

		if not GM.UI.isResizing then
			PositionDetailPanel()
			ApplyResizeLayout(true)
		end
	end)
	frame:SetScript("OnHide", function()
		if GM.UI then
			GM.UI.refreshAwaitingCompletion = false
		end
		StopRefreshCooldown()
		HideRefreshNotice()
		if GM.UI and GM.UI.resizeTicker then
			GM.UI.resizeTicker:Cancel()
			GM.UI.resizeTicker = nil
		end
		if GM.UI then
			GM.UI.isResizing = false
			GM.UI.resizeDirty = false
		end
		SetDetailPanelOpen(false)
		UpdateDetailPanel({})
		if GM.UI and GM.UI.showingDefaultUI then
			return
		end
		if GM.UI and GM.UI.returnButton then
			GM.UI.returnButton:Hide()
		end
	end)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(unpack(THEME.panelBg))
	frame:SetBackdropBorderColor(unpack(THEME.panelBorder))
	frame:Hide()

	local resizeHandle = CreateFrame("Button", nil, frame)
	resizeHandle:SetSize(14, 14)
	resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
	resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	resizeHandle:SetScript("OnMouseDown", function(_, button)
		if button and button ~= "LeftButton" then
			return
		end
		GM.UI.isResizing = true
		GM.UI.resizeDirty = false
		if GM.UI.resizeTicker then
			GM.UI.resizeTicker:Cancel()
		end
		GM.UI.resizeTicker = C_Timer.NewTicker(RESIZE_THROTTLE_SECONDS, function()
			if not GM.UI or not GM.UI.isResizing then
				return
			end
			if GM.UI.resizeDirty then
				GM.UI.resizeDirty = false
				ApplyResizeLayout(false)
			end
		end)
		frame:StartSizing("BOTTOMRIGHT")
	end)
	resizeHandle:SetScript("OnMouseUp", function(_, button)
		if button and button ~= "LeftButton" then
			return
		end
		frame:StopMovingOrSizing()
		if GM.UI and GM.UI.resizeTicker then
			GM.UI.resizeTicker:Cancel()
			GM.UI.resizeTicker = nil
		end
		if GM.UI then
			GM.UI.isResizing = false
			GM.UI.resizeDirty = false
		end
		ApplyResizeLayout(true)
	end)
	GM.UI.resizeHandle = resizeHandle

	if UISpecialFrames then
		local exists = false
		for i = 1, #UISpecialFrames do
			if UISpecialFrames[i] == "GorilMailPanel" then
				exists = true
				break
			end
		end
		if not exists then
			table.insert(UISpecialFrames, "GorilMailPanel")
		end
	end

	local toolbar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	toolbar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
	toolbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	toolbar:SetHeight(28)
	toolbar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	toolbar:SetBackdropColor(unpack(THEME.toolbarBg))
	toolbar:SetBackdropBorderColor(unpack(THEME.toolbarBorder))
	GM.UI.toolbar = toolbar

	local toolbarAccent = toolbar:CreateTexture(nil, "BACKGROUND")
	toolbarAccent:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 1, -1)
	toolbarAccent:SetPoint("TOPRIGHT", toolbar, "TOPRIGHT", -1, -1)
	toolbarAccent:SetHeight(2)
	toolbarAccent:SetColorTexture(unpack(THEME.accent))
	GM.UI.toolbarAccent = toolbarAccent

	local title = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("LEFT", toolbar, "LEFT", 8, 0)
	title:SetText("GorilMail")
	title:SetTextColor(unpack(THEME.title))
	GM.UI.title = title

	local closeButton = CreateFrame("Button", nil, toolbar, "UIPanelCloseButton")
	closeButton:SetPoint("RIGHT", toolbar, "RIGHT", 2, 0)
	closeButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	local themeHordeButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	themeHordeButton:SetSize(22, 18)
	themeHordeButton:SetPoint("RIGHT", closeButton, "LEFT", -2, 0)
	themeHordeButton:SetHitRectInsets(-2, -2, -3, -3)
	themeHordeButton:SetText("H")
	themeHordeButton:SetScript("OnClick", function()
		SetActiveTheme("Horde")
	end)
	GM.UI.themeHordeButton = themeHordeButton

	local themeAllianceButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	themeAllianceButton:SetSize(22, 18)
	themeAllianceButton:SetPoint("RIGHT", themeHordeButton, "LEFT", -2, 0)
	themeAllianceButton:SetHitRectInsets(-2, -2, -3, -3)
	themeAllianceButton:SetText("A")
	themeAllianceButton:SetScript("OnClick", function()
		SetActiveTheme("Alliance")
	end)
	GM.UI.themeAllianceButton = themeAllianceButton

	local modeSendButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	modeSendButton:SetSize(50, 20)
	modeSendButton:SetPoint("RIGHT", themeAllianceButton, "LEFT", -4, 0)
	modeSendButton:SetText("Send")
	modeSendButton:SetScript("OnClick", function()
		SetViewMode("send")
	end)
	GM.UI.modeSendButton = modeSendButton

	local modeInboxButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	modeInboxButton:SetSize(50, 20)
	modeInboxButton:SetPoint("RIGHT", modeSendButton, "LEFT", -2, 0)
	modeInboxButton:SetText("Inbox")
	modeInboxButton:SetScript("OnClick", function()
		SetViewMode("inbox")
	end)
	GM.UI.modeInboxButton = modeInboxButton

	local defaultUIButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	defaultUIButton:SetSize(90, 20)
	defaultUIButton:SetPoint("RIGHT", modeInboxButton, "LEFT", -4, 0)
	defaultUIButton:SetText("WoW UI")
	defaultUIButton:SetScript("OnClick", function()
		if not MailFrame then
			SetStatusText("Default mailbox UI unavailable")
			return
		end
		GM.UI.showingDefaultUI = not GM.UI.showingDefaultUI
		ApplyMailSwapVisibility()
		if GM.UI.showingDefaultUI then
			SetStatusText("Opened default mailbox UI")
		else
			if GM.Mailbox and GM.Mailbox.ScanInbox then
				GM.Mailbox.ScanInbox()
			end
			SetStatusText("Returned to GorilMail")
			RenderInboxRows()
		end
	end)
	StyleButton(defaultUIButton, "accent")
	GM.UI.defaultUIButton = defaultUIButton

	local summaryBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	summaryBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -34)
	summaryBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -34)
	summaryBar:SetHeight(20)
	summaryBar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	summaryBar:SetBackdropColor(unpack(THEME.surfaceBg))
	summaryBar:SetBackdropBorderColor(unpack(THEME.summaryBorder))
	GM.UI.summaryBar = summaryBar

	local inboxGoldText = summaryBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	inboxGoldText:SetPoint("LEFT", summaryBar, "LEFT", 10, 0)
	inboxGoldText:SetJustifyH("LEFT")
	inboxGoldText:SetText("Inbox Gold: 0")
	inboxGoldText:SetTextColor(unpack(THEME_TEXT.inboxGold))
	GM.UI.inboxGoldText = inboxGoldText

	local inboxCountText = summaryBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	inboxCountText:SetPoint("RIGHT", summaryBar, "RIGHT", -10, 0)
	inboxCountText:SetJustifyH("RIGHT")
	inboxCountText:SetText("Inbox Mails: 0")
	inboxCountText:SetTextColor(unpack(THEME_TEXT.inboxCount))
	GM.UI.inboxCountText = inboxCountText

	local footer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)
	footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 8)
	footer:SetHeight(22)
	footer:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	footer:SetBackdropColor(unpack(THEME.surfaceBg))
	footer:SetBackdropBorderColor(unpack(THEME.surfaceBorder))
	GM.UI.footer = footer

	local refreshButton = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
	refreshButton:SetSize(86, 19)
	refreshButton:SetPoint("LEFT", footer, "LEFT", 6, 0)
	refreshButton:SetText("Refresh")
	refreshButton:SetScript("OnClick", function()
		SetDetailPanelOpen(false)
		if GM.UI and GM.UI.refreshCooldownEndAt and GetTime() < GM.UI.refreshCooldownEndAt then
			UpdateRefreshButtonCountdown()
			return
		end
		if GM.Mailbox and GM.Mailbox.ScanInbox then
			HideRefreshNotice()
			GM.UI.refreshAwaitingCompletion = true
			GM.Mailbox.ScanInbox()
			StartRefreshCooldown()
		else
			GM.UI.refreshAwaitingCompletion = false
			ShowRefreshNotice("Refresh failed", true)
		end
	end)
	StyleButton(refreshButton, "normal")
	GM.UI.refreshButton = refreshButton
	UpdateRefreshButtonCountdown()

	local refreshNoticeText = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	refreshNoticeText:SetPoint("LEFT", refreshButton, "RIGHT", 10, 0)
	refreshNoticeText:SetPoint("RIGHT", footer, "RIGHT", -108, 0)
	refreshNoticeText:SetJustifyH("LEFT")
	refreshNoticeText:SetText("")
	refreshNoticeText:SetTextColor(unpack(THEME_STATUS.refreshSuccess))
	GM.UI.refreshNoticeText = refreshNoticeText

	local collectButton = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
	collectButton:SetSize(94, 19)
	collectButton:SetText("Collect All")
	collectButton:SetScript("OnClick", function()
		SetDetailPanelOpen(false)
		if not GM.Collector or not GM.Collector.Prepare or not GM.Collector.Start then
			SetStatusText("Collector unavailable")
			return
		end
		local rows = {}
		if GM.Mailbox and GM.Mailbox.GetRows then
			rows = GM.Mailbox.GetRows() or {}
		end
		local state = GM.Collector.GetState and GM.Collector.GetState() or "idle"
		if state == "collecting" or state == "waitingRefresh" then
			SetStatusText("Collector already running")
			return
		end

		local preparedCount = 0
		if GM.Collector.GetPreparedList then
			preparedCount = #(GM.Collector.GetPreparedList() or {})
		end
		if state ~= "prepared" or preparedCount == 0 then
			local summary = GM.Collector.Prepare(rows)
			SetStatusText("Prepared C:" .. tostring(summary.collectableCount) .. " B:" .. tostring(summary.blockedCount))
		end

		GM.Collector.Start(rows)
		RenderInboxRows()
	end)
	StyleButton(collectButton, "primary")
	GM.UI.collectAllButton = collectButton

	local listContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	listContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -58)
	listContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -58)
	listContainer:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 0, 8)
	listContainer:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 8)
	listContainer:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	listContainer:SetBackdropColor(unpack(THEME.surfaceBg))
	listContainer:SetBackdropBorderColor(unpack(THEME.listBorder))
	GM.UI.listContainer = listContainer

	local sendPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	sendPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -58)
	sendPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -58)
	sendPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)
	sendPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 8)
	sendPanel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	sendPanel:SetBackdropColor(unpack(THEME.surfaceBg))
	sendPanel:SetBackdropBorderColor(unpack(THEME.listBorder))
	sendPanel:Hide()
	GM.UI.sendPanel = sendPanel

	local sendRecipientLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendRecipientLabel:SetPoint("TOPLEFT", sendPanel, "TOPLEFT", 10, -12)
	sendRecipientLabel:SetText("Recipient")
	GM.UI.sendRecipientLabel = sendRecipientLabel

	local sendRecipientInput = CreateFrame("EditBox", nil, sendPanel, "InputBoxTemplate")
	sendRecipientInput:SetAutoFocus(false)
	sendRecipientInput:SetHeight(20)
	sendRecipientInput:SetPoint("TOPLEFT", sendRecipientLabel, "BOTTOMLEFT", 0, -4)
	sendRecipientInput:SetPoint("TOPRIGHT", sendPanel, "TOPRIGHT", -12, -16)
	sendRecipientInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	sendRecipientInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		if GM.UI and GM.UI.sendSubjectInput then
			GM.UI.sendSubjectInput:SetFocus()
		end
	end)
	GM.UI.sendRecipientInput = sendRecipientInput

	local sendSubjectLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendSubjectLabel:SetPoint("TOPLEFT", sendRecipientInput, "BOTTOMLEFT", 0, -12)
	sendSubjectLabel:SetText("Subject")
	GM.UI.sendSubjectLabel = sendSubjectLabel

	local sendSubjectInput = CreateFrame("EditBox", nil, sendPanel, "InputBoxTemplate")
	sendSubjectInput:SetAutoFocus(false)
	sendSubjectInput:SetHeight(20)
	sendSubjectInput:SetPoint("TOPLEFT", sendSubjectLabel, "BOTTOMLEFT", 0, -4)
	sendSubjectInput:SetPoint("TOPRIGHT", sendPanel, "TOPRIGHT", -12, -52)
	sendSubjectInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	sendSubjectInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	GM.UI.sendSubjectInput = sendSubjectInput

	local sendBodyLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendBodyLabel:SetPoint("TOPLEFT", sendSubjectInput, "BOTTOMLEFT", 0, -12)
	sendBodyLabel:SetText("Message")
	GM.UI.sendBodyLabel = sendBodyLabel

	local sendBodyFrame = CreateFrame("Frame", nil, sendPanel, "BackdropTemplate")
	sendBodyFrame:SetPoint("TOPLEFT", sendBodyLabel, "BOTTOMLEFT", 0, -4)
	sendBodyFrame:SetPoint("TOPRIGHT", sendPanel, "TOPRIGHT", -10, -92)
	sendBodyFrame:SetPoint("BOTTOMLEFT", sendPanel, "BOTTOMLEFT", 10, 40)
	sendBodyFrame:SetPoint("BOTTOMRIGHT", sendPanel, "BOTTOMRIGHT", -10, 40)
	sendBodyFrame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	sendBodyFrame:SetBackdropColor(unpack(THEME.detailBodyBg))
	sendBodyFrame:SetBackdropBorderColor(unpack(THEME.detailBodyBorder))
	GM.UI.sendBodyFrame = sendBodyFrame

	local sendBodyInput = CreateFrame("EditBox", nil, sendBodyFrame)
	sendBodyInput:SetMultiLine(true)
	sendBodyInput:SetAutoFocus(false)
	sendBodyInput:SetFontObject(ChatFontNormal)
	sendBodyInput:SetPoint("TOPLEFT", sendBodyFrame, "TOPLEFT", 6, -6)
	sendBodyInput:SetPoint("BOTTOMRIGHT", sendBodyFrame, "BOTTOMRIGHT", -6, 6)
	sendBodyInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	GM.UI.sendBodyInput = sendBodyInput

	local sendSendButton = CreateFrame("Button", nil, sendPanel, "UIPanelButtonTemplate")
	sendSendButton:SetSize(90, 20)
	sendSendButton:SetPoint("BOTTOMRIGHT", sendPanel, "BOTTOMRIGHT", -10, 9)
	sendSendButton:SetText("Send")
	sendSendButton:SetScript("OnClick", function()
		local recipient = TrimText(GM.UI.sendRecipientInput and GM.UI.sendRecipientInput:GetText() or "")
		if recipient == "" then
			SetStatusText("Recipient required")
			return
		end
		local subject = GM.UI.sendSubjectInput and GM.UI.sendSubjectInput:GetText() or ""
		local body = GM.UI.sendBodyInput and GM.UI.sendBodyInput:GetText() or ""
		if SendMail then
			SendMail(recipient, subject, body)
			SetStatusText("Mail sent")
		else
			SetStatusText("Send unavailable")
		end
	end)
	StyleButton(sendSendButton, "primary")
	GM.UI.sendSendButton = sendSendButton

	local sendClearButton = CreateFrame("Button", nil, sendPanel, "UIPanelButtonTemplate")
	sendClearButton:SetSize(90, 20)
	sendClearButton:SetPoint("RIGHT", sendSendButton, "LEFT", -8, 0)
	sendClearButton:SetText("Clear")
	sendClearButton:SetScript("OnClick", function()
		if GM.UI.sendRecipientInput then
			GM.UI.sendRecipientInput:SetText("")
		end
		if GM.UI.sendSubjectInput then
			GM.UI.sendSubjectInput:SetText("")
		end
		if GM.UI.sendBodyInput then
			GM.UI.sendBodyInput:SetText("")
		end
	end)
	StyleButton(sendClearButton, "normal")
	GM.UI.sendClearButton = sendClearButton

	local detailPanel = CreateFrame("Frame", "GorilMailDetailPanel", UIParent, "BackdropTemplate")
	detailPanel:SetWidth(DETAIL_PANEL_WIDTH)
	detailPanel:SetFrameStrata("DIALOG")
	detailPanel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 10,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	detailPanel:SetBackdropColor(unpack(THEME.detailBg))
	detailPanel:SetBackdropBorderColor(unpack(THEME.detailBorder))
	detailPanel:Hide()
	GM.UI.detailPanel = detailPanel
	GM.UI.detailPanelOpen = false
	PositionDetailPanel()

	local detailHeader = CreateFrame("Frame", nil, detailPanel)
	detailHeader:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 6, -6)
	detailHeader:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -6, -6)
	detailHeader:SetHeight(50)

	local detailHeaderBg = detailHeader:CreateTexture(nil, "BACKGROUND")
	detailHeaderBg:SetAllPoints()
	detailHeaderBg:SetColorTexture(unpack(THEME.detailHeaderBg))
	GM.UI.detailHeaderBg = detailHeaderBg

	local detailFromText = detailHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detailFromText:SetPoint("TOPLEFT", detailHeader, "TOPLEFT", 6, -6)
	detailFromText:SetPoint("TOPRIGHT", detailHeader, "TOPRIGHT", -6, -6)
	detailFromText:SetJustifyH("LEFT")
	detailFromText:SetText("From: -")
	detailFromText:SetTextColor(unpack(THEME_TEXT.detailFrom))
	GM.UI.detailFromText = detailFromText

	local detailSubjectText = detailHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detailSubjectText:SetPoint("TOPLEFT", detailHeader, "TOPLEFT", 6, -24)
	detailSubjectText:SetPoint("TOPRIGHT", detailHeader, "TOPRIGHT", -6, -24)
	detailSubjectText:SetJustifyH("LEFT")
	detailSubjectText:SetWordWrap(false)
	detailSubjectText:SetText("Subject: -")
	detailSubjectText:SetTextColor(unpack(THEME_TEXT.detailSubject))
	GM.UI.detailSubjectText = detailSubjectText

	local detailMetaText = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detailMetaText:SetPoint("TOPLEFT", detailHeader, "BOTTOMLEFT", 2, -6)
	detailMetaText:SetPoint("TOPRIGHT", detailHeader, "BOTTOMRIGHT", -2, -6)
	detailMetaText:SetJustifyH("LEFT")
	detailMetaText:SetText("Money: -   COD: -")
	detailMetaText:SetTextColor(unpack(THEME_TEXT.detailMeta))
	GM.UI.detailMetaText = detailMetaText

	local detailItemHitArea = CreateFrame("Button", nil, detailPanel)
	detailItemHitArea:SetPoint("TOPLEFT", detailMetaText, "BOTTOMLEFT", -1, -4)
	detailItemHitArea:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -10, -4)
	detailItemHitArea:SetHeight(22)
	detailItemHitArea:SetHitRectInsets(0, 0, -2, -2)
	detailItemHitArea:EnableMouse(true)
	detailItemHitArea:SetScript("OnEnter", function(self)
		if not GM.UI or not GM.UI.detailItemMailIndex then
			return
		end
		if GameTooltip and GameTooltip.SetInboxItem then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			local hasTooltip = GameTooltip:SetInboxItem(GM.UI.detailItemMailIndex, 1)
			if hasTooltip then
				GameTooltip:Show()
				return
			end
		end
		if GameTooltip and GM.UI.detailItemLink and GameTooltip.SetHyperlink then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(GM.UI.detailItemLink)
			GameTooltip:Show()
		end
	end)
	detailItemHitArea:SetScript("OnLeave", function()
		if GameTooltip and GameTooltip:IsOwned(detailItemHitArea) then
			GameTooltip:Hide()
		end
	end)
	detailItemHitArea:SetScript("OnHide", function()
		if GameTooltip and GameTooltip:IsOwned(detailItemHitArea) then
			GameTooltip:Hide()
		end
	end)
	detailItemHitArea:EnableMouse(false)
	GM.UI.detailItemHitArea = detailItemHitArea

	local detailItemIcon = detailPanel:CreateTexture(nil, "ARTWORK")
	detailItemIcon:SetSize(20, 20)
	detailItemIcon:SetPoint("LEFT", detailItemHitArea, "LEFT", 1, 0)
	detailItemIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	detailItemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	GM.UI.detailItemIcon = detailItemIcon

	local detailItemIconBorder = detailPanel:CreateTexture(nil, "OVERLAY")
	detailItemIconBorder:SetPoint("TOPLEFT", detailItemIcon, "TOPLEFT", -1, 1)
	detailItemIconBorder:SetPoint("BOTTOMRIGHT", detailItemIcon, "BOTTOMRIGHT", 1, -1)
	detailItemIconBorder:SetColorTexture(unpack(THEME.detailItemBorder))
	GM.UI.detailItemIconBorder = detailItemIconBorder

	local detailItemCountText = detailPanel:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	detailItemCountText:SetPoint("BOTTOMRIGHT", detailItemIcon, "BOTTOMRIGHT", -1, 1)
	detailItemCountText:SetText("")
	detailItemCountText:SetTextColor(1.0, 1.0, 1.0)
	GM.UI.detailItemCountText = detailItemCountText

	local detailItemText = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detailItemText:SetPoint("LEFT", detailItemIcon, "RIGHT", 6, 0)
	detailItemText:SetPoint("RIGHT", detailItemHitArea, "RIGHT", -2, 0)
	detailItemText:SetJustifyH("LEFT")
	detailItemText:SetText("No item attachment")
	detailItemText:SetTextColor(unpack(THEME_TEXT.detailItem))
	GM.UI.detailItemText = detailItemText

	local detailCollectButton = CreateFrame("Button", nil, detailPanel, "UIPanelButtonTemplate")
	detailCollectButton:SetSize(94, 19)
	detailCollectButton:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -8, 8)
	detailCollectButton:SetText("Collect This")
	detailCollectButton:SetScript("OnClick", function()
		StartCollectForSingleMail(GM.UI.selectedMailIndex)
	end)
	StyleButton(detailCollectButton, "primary")
	GM.UI.detailCollectButton = detailCollectButton

	local detailBodyFrame = CreateFrame("Frame", nil, detailPanel, "BackdropTemplate")
	detailBodyFrame:SetPoint("TOPLEFT", detailItemText, "BOTTOMLEFT", -7, -6)
	detailBodyFrame:SetPoint("TOPRIGHT", detailItemText, "BOTTOMRIGHT", 2, -6)
	detailBodyFrame:SetPoint("BOTTOMLEFT", detailPanel, "BOTTOMLEFT", 8, 32)
	detailBodyFrame:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -8, 32)
	detailBodyFrame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 8,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	detailBodyFrame:SetBackdropColor(unpack(THEME.detailBodyBg))
	detailBodyFrame:SetBackdropBorderColor(unpack(THEME.detailBodyBorder))
	GM.UI.detailBodyFrame = detailBodyFrame

	local detailBodyScroll = CreateFrame("ScrollFrame", nil, detailBodyFrame, "UIPanelScrollFrameTemplate")
	detailBodyScroll:SetPoint("TOPLEFT", detailBodyFrame, "TOPLEFT", 4, -4)
	detailBodyScroll:SetPoint("BOTTOMRIGHT", detailBodyFrame, "BOTTOMRIGHT", -26, 4)
	GM.UI.detailBodyScroll = detailBodyScroll

	local detailBodyChild = CreateFrame("Frame", nil, detailBodyScroll)
	detailBodyChild:SetPoint("TOPLEFT", detailBodyScroll, "TOPLEFT", 0, 0)
	detailBodyChild:SetSize(1, 1)
	GM.UI.detailBodyChild = detailBodyChild
	detailBodyScroll:SetScrollChild(detailBodyChild)

	local detailBodyText = detailBodyChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detailBodyText:SetPoint("TOPLEFT", detailBodyChild, "TOPLEFT", 2, -2)
	detailBodyText:SetPoint("TOPRIGHT", detailBodyChild, "TOPRIGHT", -2, -2)
	detailBodyText:SetJustifyH("LEFT")
	detailBodyText:SetJustifyV("TOP")
	detailBodyText:SetWordWrap(true)
	detailBodyText:SetTextColor(unpack(THEME_TEXT.detailBody))
	detailBodyText:SetText("Select a mail row to read.")
	GM.UI.detailBodyText = detailBodyText

	local header = CreateFrame("Frame", nil, listContainer)
	header:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 4, -3)
	header:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -26, -3)
	header:SetHeight(18)

	local headerBg = header:CreateTexture(nil, "BACKGROUND")
	headerBg:SetAllPoints()
	headerBg:SetColorTexture(unpack(THEME.headerBg))
	GM.UI.headerBg = headerBg
	GM.UI.headerCells = {}

	local x = 4
	CreateHeaderCell(header, "Sender", COL_SENDER, x, "LEFT")
	x = x + COL_SENDER + COL_GAP
	CreateHeaderCell(header, "Subject", COL_SUBJECT, x, "LEFT")
	x = x + COL_SUBJECT + COL_GAP
	CreateHeaderCell(header, "Money", COL_MONEY, x, "RIGHT")
	x = x + COL_MONEY + COL_GAP
	CreateHeaderCell(header, "COD", COL_COD, x, "CENTER")
	x = x + COL_COD + COL_GAP
	CreateHeaderCell(header, "Item", COL_ITEM, x, "CENTER")
	x = x + COL_ITEM + COL_GAP
	CreateHeaderCell(header, "State", COL_STATE, x, "CENTER")
	x = x + COL_STATE + COL_GAP
	CreateHeaderCell(header, "Action", COL_ACTION, x, "CENTER")

	local scrollFrame = CreateFrame("ScrollFrame", "GorilMailInboxScrollFrame", listContainer, "FauxScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -19)
	scrollFrame:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -32, 4)
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, RenderInboxRows)
	end)
	GM.UI.scrollFrame = scrollFrame

	local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
	if scrollBar then
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -9, -21)
		scrollBar:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -9, 6)
	end

	local scrollDivider = listContainer:CreateTexture(nil, "BORDER")
	scrollDivider:SetColorTexture(unpack(THEME.scrollDivider))
	scrollDivider:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -32, -19)
	scrollDivider:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -32, 4)
	scrollDivider:SetWidth(1)
	GM.UI.scrollDivider = scrollDivider

	local rowAnchor = CreateFrame("Frame", nil, listContainer)
	rowAnchor:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -19)
	rowAnchor:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -36, -19)
	rowAnchor:SetPoint("BOTTOMLEFT", listContainer, "BOTTOMLEFT", 0, 4)
	rowAnchor:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -36, 4)
	GM.UI.rowAnchor = rowAnchor

	local rows = {}
	for i = 1, VISIBLE_ROW_COUNT do
		rows[i] = CreateRow(rowAnchor, i, 0)
	end
	GM.UI.rows = rows
	EnsureVisibleRows()

	GM.UI.frame = frame
	GM.UI.viewMode = "inbox"
	SetDetailPanelOpen(false)
	UpdateInboxGoldText()
	ApplyThemeToUI()
	UpdateThemeToggleVisual()

	if GM.Mailbox and GM.Mailbox.RegisterCallback then
		GM.Mailbox.RegisterCallback(RenderInboxRows)
	end
	RenderInboxRows()

	SLASH_GORILMAIL1 = "/gorilmail"
	SlashCmdList.GORILMAIL = function()
		if GM.UI.frame:IsShown() then
			GM.UI.frame:Hide()
		else
			GM.UI.frame:Show()
		end
	end
end

function GM.UI.OnMailShow()
	if not GM.UI.frame and GM.UI.Initialize then
		GM.UI.Initialize()
	end
	if GM.UI then
		GM.UI.refreshAwaitingCompletion = false
		GM.UI.showingDefaultUI = false
		GM.UI.viewMode = "inbox"
	end
	HideRefreshNotice()
	SetDetailPanelOpen(false)
	ApplyViewMode()
	ApplyMailSwapVisibility()
end

function GM.UI.OnMailClosed()
	if GM.UI then
		GM.UI.refreshAwaitingCompletion = false
		GM.UI.showingDefaultUI = false
	end
	StopRefreshCooldown()
	HideRefreshNotice()
	SetDetailPanelOpen(false)
	CloseDefaultMailDetailPanels()
	if MailFrame then
		MailFrame:SetAlpha(1)
		MailFrame:EnableMouse(true)
	end
	if GM.UI and GM.UI.returnButton then
		GM.UI.returnButton:Hide()
	end
	if GM.UI.frame and GM.UI.frame:IsShown() then
		GM.UI.frame:Hide()
	end
end
