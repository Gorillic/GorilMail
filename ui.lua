local addonName, GM = ...

GM = GM or {}

GM.UI = GM.UI or {}

local ROW_HEIGHT = 19
local VISIBLE_ROW_COUNT = 10
local COL_GAP = 5
local COL_SUBJECT_MONEY_GAP = 7
local COL_SENDER = 100
local COL_SUBJECT = 150
local COL_MONEY = 136
local COL_COD = 48
local COL_ITEM = 40
local COL_STATE = 38
local COL_ACTION = 40
local REFRESH_COOLDOWN_SECONDS = 10
local DETAIL_PANEL_WIDTH = 246
local DETAIL_PANEL_HEIGHT = 232
local DETAIL_FRAME_GAP = 6
local RESIZE_MIN_WIDTH = 640
local RESIZE_MIN_HEIGHT = 340
local RESIZE_MAX_WIDTH = 1600
local RESIZE_MAX_HEIGHT = 1200
local RESIZE_THROTTLE_SECONDS = 0.05
local DEFAULT_FRAME_WIDTH = 668
local DEFAULT_FRAME_HEIGHT = 350
local RenderInboxRows
local EnsureVisibleRows
local ApplyResizeLayout
local ApplyViewMode
local SetViewMode
local SetDetailPanelOpen
local ApplyMailSwapVisibility
local SetStatusText
local UpdateSendAttachmentPreview
local EnsureSendAttachmentBagHook

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

local function ReadColor(color, fallback)
	local source = type(color) == "table" and color or fallback or { 1, 1, 1, 1 }
	local r = tonumber(source[1]) or 1
	local g = tonumber(source[2]) or 1
	local b = tonumber(source[3]) or 1
	local a = tonumber(source[4])
	if not a then
		a = (type(fallback) == "table" and tonumber(fallback[4])) or 1
	end
	return r, g, b, a
end

local function TintColor(color, amount, alphaScale)
	local r, g, b, a = ReadColor(color, { 1, 1, 1, 1 })
	local t = math.max(0, math.min(1, tonumber(amount) or 0))
	local alphaMul = tonumber(alphaScale) or 1
	return {
		r + (1 - r) * t,
		g + (1 - g) * t,
		b + (1 - b) * t,
		math.max(0, math.min(1, a * alphaMul)),
	}
end

local function ShadeColor(color, amount, alphaScale)
	local r, g, b, a = ReadColor(color, { 1, 1, 1, 1 })
	local t = math.max(0, math.min(1, tonumber(amount) or 0))
	local alphaMul = tonumber(alphaScale) or 1
	return {
		r * (1 - t),
		g * (1 - t),
		b * (1 - t),
		math.max(0, math.min(1, a * alphaMul)),
	}
end

local function EnsureSurfaceLayers(frame)
	if not frame then
		return
	end
	if not frame.gmTopHighlight then
		local top = frame:CreateTexture(nil, "ARTWORK")
		top:SetTexture("Interface\\Buttons\\WHITE8x8")
		top:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
		top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
		top:SetHeight(2)
		frame.gmTopHighlight = top
	end
	if not frame.gmInnerShadow then
		local inner = frame:CreateTexture(nil, "ARTWORK")
		inner:SetTexture("Interface\\Buttons\\WHITE8x8")
		inner:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
		inner:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		frame.gmInnerShadow = inner
	end
	if not frame.gmBottomWeight then
		local bottom = frame:CreateTexture(nil, "ARTWORK")
		bottom:SetTexture("Interface\\Buttons\\WHITE8x8")
		bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 2, 2)
		bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
		bottom:SetHeight(2)
		frame.gmBottomWeight = bottom
	end
end

local function ApplySurfaceLayers(frame, borderColor, highlightColor)
	if not frame then
		return
	end
	EnsureSurfaceLayers(frame)
	local top = TintColor(highlightColor or borderColor or { 1, 1, 1, 1 }, 0.60, 0.30)
	local inner = ShadeColor(borderColor or { 0.2, 0.2, 0.2, 1 }, 0.55, 0.32)
	local bottom = ShadeColor(borderColor or { 0.2, 0.2, 0.2, 1 }, 0.45, 0.48)
	frame.gmTopHighlight:SetColorTexture(unpack(top))
	frame.gmInnerShadow:SetColorTexture(unpack(inner))
	frame.gmBottomWeight:SetColorTexture(unpack(bottom))
end

local function SoftBorderColor(color)
	return ShadeColor(color or { 0.25, 0.25, 0.25, 1 }, 0.10, 0.80)
end

local function EnsureSoftCorners(frame)
	if not frame then
		return
	end
	if not frame.gmSoftCornerTL then
		local tl = frame:CreateTexture(nil, "OVERLAY")
		tl:SetTexture("Interface\\Buttons\\WHITE8x8")
		tl:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
		tl:SetSize(3, 3)
		frame.gmSoftCornerTL = tl
	end
	if not frame.gmSoftCornerTR then
		local tr = frame:CreateTexture(nil, "OVERLAY")
		tr:SetTexture("Interface\\Buttons\\WHITE8x8")
		tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
		tr:SetSize(3, 3)
		frame.gmSoftCornerTR = tr
	end
	if not frame.gmSoftCornerBL then
		local bl = frame:CreateTexture(nil, "OVERLAY")
		bl:SetTexture("Interface\\Buttons\\WHITE8x8")
		bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
		bl:SetSize(3, 3)
		frame.gmSoftCornerBL = bl
	end
	if not frame.gmSoftCornerBR then
		local br = frame:CreateTexture(nil, "OVERLAY")
		br:SetTexture("Interface\\Buttons\\WHITE8x8")
		br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
		br:SetSize(3, 3)
		frame.gmSoftCornerBR = br
	end
end

local function ApplySoftCorners(frame, bgColor)
	if not frame then
		return
	end
	EnsureSoftCorners(frame)
	local cornerColor = TintColor(bgColor or { 0.10, 0.10, 0.10, 1 }, 0.03, 0.96)
	frame.gmSoftCornerTL:SetColorTexture(unpack(cornerColor))
	frame.gmSoftCornerTR:SetColorTexture(unpack(cornerColor))
	frame.gmSoftCornerBL:SetColorTexture(unpack(cornerColor))
	frame.gmSoftCornerBR:SetColorTexture(unpack(cornerColor))
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
	if not button.gmSkinTopLight then
		local top = button:CreateTexture(nil, "ARTWORK")
		top:SetTexture("Interface\\Buttons\\WHITE8x8")
		top:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
		top:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
		top:SetHeight(2)
		button.gmSkinTopLight = top
	end
	if not button.gmSkinBottomShade then
		local bottom = button:CreateTexture(nil, "ARTWORK")
		bottom:SetTexture("Interface\\Buttons\\WHITE8x8")
		bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 2, 2)
		bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
		bottom:SetHeight(2)
		button.gmSkinBottomShade = bottom
	end
	if not button.gmSkinTopEdge then
		local topEdge = button:CreateTexture(nil, "OVERLAY")
		topEdge:SetTexture("Interface\\Buttons\\WHITE8x8")
		topEdge:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
		topEdge:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
		topEdge:SetHeight(1)
		button.gmSkinTopEdge = topEdge
	end
	if not button.gmSkinBottomEdge then
		local bottomEdge = button:CreateTexture(nil, "OVERLAY")
		bottomEdge:SetTexture("Interface\\Buttons\\WHITE8x8")
		bottomEdge:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 1, 1)
		bottomEdge:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1)
		bottomEdge:SetHeight(1)
		button.gmSkinBottomEdge = bottomEdge
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
				if state == "down" then
					fs:SetShadowOffset(0, -1)
				else
					fs:SetShadowOffset(1, -1)
				end
			else
				fs:SetTextColor(unpack(THEME_TEXT.buttonDisabled or { 0.60, 0.60, 0.60 }))
				fs:SetShadowOffset(1, -1)
			end
		end
		if not button:IsEnabled() then
			button.gmSkinBg:SetColorTexture(unpack(disabledBg))
			button.gmSkinBorder:SetColorTexture(unpack(THEME_STATUS.buttonBorderDisabled or { 0.24, 0.24, 0.24, 0.75 }))
			button.gmSkinTopLight:SetColorTexture(1, 1, 1, 0.04)
			button.gmSkinBottomShade:SetColorTexture(0, 0, 0, 0.22)
			button.gmSkinTopEdge:SetColorTexture(1, 1, 1, 0.05)
			button.gmSkinBottomEdge:SetColorTexture(0, 0, 0, 0.30)
			return
		end
		if state == "down" then
			button.gmSkinBg:SetColorTexture(unpack(downBg))
			button.gmSkinTopLight:SetColorTexture(1, 1, 1, 0.05)
			button.gmSkinBottomShade:SetColorTexture(0, 0, 0, 0.30)
		elseif state == "hover" then
			button.gmSkinBg:SetColorTexture(unpack(hoverBg))
			button.gmSkinTopLight:SetColorTexture(1, 1, 1, 0.16)
			button.gmSkinBottomShade:SetColorTexture(0, 0, 0, 0.18)
		else
			button.gmSkinBg:SetColorTexture(unpack(normalBg))
			button.gmSkinTopLight:SetColorTexture(1, 1, 1, 0.11)
			button.gmSkinBottomShade:SetColorTexture(0, 0, 0, 0.24)
		end
		button.gmSkinBorder:SetColorTexture(unpack(borderColor))
		button.gmSkinTopEdge:SetColorTexture(unpack(TintColor(borderColor, 0.55, 0.92)))
		button.gmSkinBottomEdge:SetColorTexture(unpack(ShadeColor(borderColor, 0.60, 0.92)))
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
		GM.UI.frame:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.panelBorder)))
		ApplySurfaceLayers(GM.UI.frame, THEME.panelBorder, THEME.title)
		ApplySoftCorners(GM.UI.frame, THEME.panelBg)
	end
	if GM.UI.toolbar then
		GM.UI.toolbar:SetBackdropColor(unpack(THEME.toolbarBg))
		GM.UI.toolbar:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.toolbarBorder)))
		ApplySurfaceLayers(GM.UI.toolbar, THEME.toolbarBorder, THEME.title)
		ApplySoftCorners(GM.UI.toolbar, THEME.toolbarBg)
	end
	if GM.UI.toolbarAccent then
		GM.UI.toolbarAccent:SetColorTexture(unpack(TintColor(THEME.accent, 0.15, 0.52)))
	end
	if GM.UI.title then
		GM.UI.title:SetTextColor(unpack(THEME.title))
	end
	if GM.UI.summaryBar then
		GM.UI.summaryBar:SetBackdropColor(unpack(THEME.surfaceBg))
		GM.UI.summaryBar:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.summaryBorder)))
		ApplySurfaceLayers(GM.UI.summaryBar, THEME.summaryBorder, THEME.title)
		ApplySoftCorners(GM.UI.summaryBar, THEME.surfaceBg)
	end
	if GM.UI.footer then
		GM.UI.footer:SetBackdropColor(unpack(THEME.surfaceBg))
		GM.UI.footer:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.surfaceBorder)))
		ApplySurfaceLayers(GM.UI.footer, THEME.surfaceBorder, THEME.title)
		ApplySoftCorners(GM.UI.footer, THEME.surfaceBg)
	end
	if GM.UI.listContainer then
		GM.UI.listContainer:SetBackdropColor(unpack(THEME.surfaceBg))
		GM.UI.listContainer:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.listBorder)))
		ApplySurfaceLayers(GM.UI.listContainer, THEME.listBorder, THEME.title)
		ApplySoftCorners(GM.UI.listContainer, THEME.surfaceBg)
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
		GM.UI.detailItemIconBorder:SetBackdropBorderColor(unpack(THEME.detailItemBorder))
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
		GM.UI.sendPanel:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.listBorder)))
		ApplySurfaceLayers(GM.UI.sendPanel, THEME.listBorder, THEME.title)
		ApplySoftCorners(GM.UI.sendPanel, THEME.surfaceBg)
	end
	if GM.UI.sendAttachmentGroup then
		GM.UI.sendAttachmentGroup:SetBackdropColor(unpack(THEME.detailBodyBg))
		GM.UI.sendAttachmentGroup:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
		ApplySurfaceLayers(GM.UI.sendAttachmentGroup, THEME.detailBodyBorder, THEME.title)
		ApplySoftCorners(GM.UI.sendAttachmentGroup, THEME.detailBodyBg)
	end
	if GM.UI.sendActionBar then
		GM.UI.sendActionBar:SetBackdropColor(unpack(THEME.detailBodyBg))
		GM.UI.sendActionBar:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
		ApplySurfaceLayers(GM.UI.sendActionBar, THEME.detailBodyBorder, THEME.title)
		ApplySoftCorners(GM.UI.sendActionBar, THEME.detailBodyBg)
	end
	if GM.UI.sendBodyFrame then
		GM.UI.sendBodyFrame:SetBackdropColor(unpack(THEME.detailBodyBg))
		GM.UI.sendBodyFrame:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
		ApplySoftCorners(GM.UI.sendBodyFrame, THEME.detailBodyBg)
	end
	if GM.UI.sendRecipientLabel then
		GM.UI.sendRecipientLabel:SetTextColor(unpack(THEME_TEXT.header))
	end
	if GM.UI.sendSubjectLabel then
		GM.UI.sendSubjectLabel:SetTextColor(unpack(THEME_TEXT.header))
	end
	if GM.UI.sendGoldLabel then
		GM.UI.sendGoldLabel:SetTextColor(unpack(THEME_TEXT.header))
	end
	if GM.UI.sendAttachmentLabel then
		GM.UI.sendAttachmentLabel:SetTextColor(unpack(THEME_TEXT.header))
	end
	if GM.UI.sendCODLabel then
		GM.UI.sendCODLabel:SetTextColor(unpack(THEME_TEXT.header))
	end
	if GM.UI.sendCODAmountLabel then
		GM.UI.sendCODAmountLabel:SetTextColor(unpack(THEME_TEXT.header))
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
	if GM.UI.sendGoldInput then
		GM.UI.sendGoldInput:SetTextColor(unpack(THEME_TEXT.detailBody))
	end
	if GM.UI.sendAttachmentNameText then
		GM.UI.sendAttachmentNameText:SetTextColor(unpack(THEME_TEXT.detailBody))
	end
	if GM.UI.sendCODInput then
		GM.UI.sendCODInput:SetTextColor(unpack(THEME_TEXT.detailBody))
	end
	if GM.UI.sendBodyInput then
		GM.UI.sendBodyInput:SetTextColor(unpack(THEME_TEXT.detailBody))
	end
	if GM.UI.sendAttachmentSlot then
		GM.UI.sendAttachmentSlot:SetBackdropColor(unpack(THEME.detailBodyBg))
		GM.UI.sendAttachmentSlot:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
		ApplySoftCorners(GM.UI.sendAttachmentSlot, THEME.detailBodyBg)
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
	button:SetFrameStrata("DIALOG")
	button:SetFrameLevel((MailFrame:GetFrameLevel() or 0) + 30)
	button:RegisterForClicks("AnyUp")
	button:SetHitRectInsets(-2, -2, -2, -2)
	button:SetText("GorilMail")
	button:SetScript("OnClick", function()
		GM.UI.showingDefaultUI = false
		if ApplyMailSwapVisibility then
			ApplyMailSwapVisibility()
		end
		if GM.Mailbox and GM.Mailbox.ScanInbox then
			GM.Mailbox.ScanInbox()
		end
		SetStatusText("Returned to GorilMail")
		if GM.UI and GM.UI.frame and not GM.UI.frame:IsShown() then
			GM.UI.frame:Show()
		end
		if RenderInboxRows then
			RenderInboxRows()
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

local function SetDefaultInboxInteractionEnabled(enabled)
	local canInteract = enabled and true or false

	local function SetFrameMouseState(target)
		if not target then
			return
		end
		if target.EnableMouse then
			target:EnableMouse(canInteract)
		end
		if target.SetMouseClickEnabled then
			target:SetMouseClickEnabled(canInteract)
		end
		if target.SetMouseMotionEnabled then
			target:SetMouseMotionEnabled(canInteract)
		end
	end

	local function SetFrameTreeMouseState(root, depth, visited)
		if not root or depth < 0 then
			return
		end
		visited = visited or {}
		if visited[root] then
			return
		end
		visited[root] = true
		SetFrameMouseState(root)
		if depth == 0 or not root.GetChildren then
			return
		end
		local children = { root:GetChildren() }
		for i = 1, #children do
			SetFrameTreeMouseState(children[i], depth - 1, visited)
		end
	end

	local inboxFrame = _G and _G.InboxFrame
	SetFrameTreeMouseState(inboxFrame, 3)

	for i = 1, 7 do
		local inboxRowButton = _G and _G["MailItem" .. i]
		SetFrameTreeMouseState(inboxRowButton, 3)
	end
end

local function SetDefaultMailPanelManaged(enabled)
	if not MailFrame or not MailFrame.SetAttribute then
		return
	end
	MailFrame:SetAttribute("UIPanelLayout-enabled", enabled and true or false)
	if UpdateUIPanelPositions then
		UpdateUIPanelPositions()
	end
end

local function SetDefaultMailPanelWindowRegistered(enabled)
	if not UIPanelWindows then
		return
	end

	if enabled then
		if GM.UI and GM.UI.mailFrameUIPanelWindowsStashed then
			UIPanelWindows["MailFrame"] = GM.UI.mailFrameUIPanelWindowsEntry
			GM.UI.mailFrameUIPanelWindowsEntry = nil
			GM.UI.mailFrameUIPanelWindowsStashed = false
			if UpdateUIPanelPositions then
				UpdateUIPanelPositions()
			end
		end
		return
	end

	if GM.UI and GM.UI.mailFrameUIPanelWindowsStashed then
		return
	end

	local current = UIPanelWindows["MailFrame"]
	if not current then
		return
	end

	local snapshot = {}
	for key, value in pairs(current) do
		snapshot[key] = value
	end

	if GM.UI then
		GM.UI.mailFrameUIPanelWindowsEntry = snapshot
		GM.UI.mailFrameUIPanelWindowsStashed = true
	end
	UIPanelWindows["MailFrame"] = nil

	if UpdateUIPanelPositions then
		UpdateUIPanelPositions()
	end
end

ApplyMailSwapVisibility = function()
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
		SetDefaultMailPanelWindowRegistered(true)
		SetDefaultMailPanelManaged(true)
		if GM.UI.frame then
			if GM.UI.frame:IsShown() then
				GM.UI.frame:Hide()
			end
		end
		SetDefaultInboxInteractionEnabled(true)
		MailFrame:SetAlpha(1)
		MailFrame:EnableMouse(true)
		if returnButton then
			if returnButton.SetEnabled then
				returnButton:SetEnabled(true)
			end
			returnButton:EnableMouse(true)
			returnButton:Show()
		end
	else
		local deferBookkeeping = GM.UI and GM.UI.deferFirstMailFrameBookkeeping
		if not deferBookkeeping then
			SetDefaultMailPanelWindowRegistered(false)
			SetDefaultMailPanelManaged(false)
		end
		CloseDefaultMailDetailPanels()
		SetDefaultInboxInteractionEnabled(false)
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
		if deferBookkeeping then
			GM.UI.deferFirstMailFrameBookkeeping = false
			C_Timer.After(0, function()
				if not GM.UI or GM.UI.showingDefaultUI then
					return
				end
				if not MailFrame or not MailFrame.IsShown or not MailFrame:IsShown() then
					return
				end
				ApplyMailSwapVisibility()
			end)
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

SetStatusText = function(text)
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

local function ParseCopperInput(value)
	local text = TrimText(value)
	if text == "" then
		return 0
	end
	local amount = tonumber(text)
	if not amount or amount <= 0 then
		return 0
	end
	return math.floor(amount)
end

local function UpdateSendCODInputState()
	if not GM.UI then
		return
	end

	local attachmentSlot = GM.UI.sendAttachmentSlot
	local codToggle = GM.UI.sendCODToggle
	local codInput = GM.UI.sendCODInput
	local hasAttachment = attachmentSlot and attachmentSlot.hasItem and true or false

	if codToggle then
		if codToggle.Enable then
			if hasAttachment then
				codToggle:Enable()
			else
				codToggle:Disable()
			end
		end
		if not hasAttachment then
			codToggle:SetChecked(false)
		end
	end

	local codEnabled = hasAttachment and codToggle and codToggle:GetChecked()
	if codInput then
		if codInput.Enable and codInput.Disable then
			if codEnabled then
				codInput:Enable()
			else
				codInput:Disable()
			end
		end
		if codInput.EnableMouse then
			codInput:EnableMouse(codEnabled and true or false)
		end
		if not codEnabled then
			codInput:SetText("")
		end
	end
end

local function SetSendPendingState(pending)
	if not GM.UI then
		return
	end
	local isPending = pending and true or false
	GM.UI.sendPending = isPending
	if GM.UI.sendSendButton then
		GM.UI.sendSendButton:SetEnabled(not isPending)
		GM.UI.sendSendButton:SetText(isPending and "Sending..." or "Send")
	end
	if GM.UI.sendClearButton then
		GM.UI.sendClearButton:SetEnabled(not isPending)
	end
end

local function ResetSendFormState(clearAttachmentSlot)
	if not GM.UI then
		return
	end
	if clearAttachmentSlot and ClickSendMailItemButton and GetSendMailItem then
		local attachedName = GetSendMailItem(1)
		if attachedName then
			ClickSendMailItemButton(1, true)
		end
	end
	if GM.UI.sendRecipientInput then
		GM.UI.sendRecipientInput:SetText("")
	end
	if GM.UI.sendSubjectInput then
		GM.UI.sendSubjectInput:SetText("")
	end
	if GM.UI.sendGoldInput then
		GM.UI.sendGoldInput:SetText("")
	end
	if GM.UI.sendCODToggle then
		GM.UI.sendCODToggle:SetChecked(false)
	end
	if GM.UI.sendCODInput then
		GM.UI.sendCODInput:SetText("")
	end
	if GM.UI.sendBodyInput then
		GM.UI.sendBodyInput:SetText("")
	end
	if UpdateSendAttachmentPreview then
		UpdateSendAttachmentPreview()
	end
	UpdateSendCODInputState()
end

UpdateSendAttachmentPreview = function()
	if not GM.UI or not GM.UI.sendAttachmentSlot then
		return
	end

	local slot = GM.UI.sendAttachmentSlot
	local icon = GM.UI.sendAttachmentIcon
	local countText = GM.UI.sendAttachmentCountText
	local nameText = GM.UI.sendAttachmentNameText

	local itemName, _, itemTexture, itemCount = nil, nil, nil, nil
	if GetSendMailItem then
		itemName, _, itemTexture, itemCount = GetSendMailItem(1)
	end

	if itemName then
		slot.hasItem = true
		if icon then
			icon:SetTexture(itemTexture or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
			icon:SetVertexColor(1, 1, 1, 1)
		end
		if countText then
			if (itemCount or 1) > 1 then
				countText:SetText(tostring(itemCount))
			else
				countText:SetText("")
			end
		end
		if nameText then
			nameText:SetText(tostring(itemName))
		end
	else
		slot.hasItem = false
		if icon then
			icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
			icon:SetVertexColor(0.62, 0.62, 0.62, 0.75)
		end
		if countText then
			countText:SetText("")
		end
		if nameText then
			nameText:SetText("No attachment")
		end
	end

	UpdateSendCODInputState()
end

local function QueueSendAttachmentPreviewUpdate()
	C_Timer.After(0, function()
		if UpdateSendAttachmentPreview then
			UpdateSendAttachmentPreview()
		end
	end)
end

EnsureSendAttachmentBagHook = function()
	if not GM.UI or GM.UI.sendAttachmentBagHooked then
		return
	end
	if type(hooksecurefunc) ~= "function" or type(ContainerFrameItemButton_OnClick) ~= "function" then
		return
	end

	hooksecurefunc("ContainerFrameItemButton_OnClick", function(buttonFrame, mouseButton)
		if mouseButton ~= "RightButton" then
			return
		end
		if not GM.UI or GM.UI.viewMode ~= "send" or not GM.UI.sendPanel or not GM.UI.sendPanel:IsShown() then
			return
		end
		if not ClickSendMailItemButton then
			return
		end
		if GM.UI.sendAttachmentSlot and GM.UI.sendAttachmentSlot.hasItem then
			return
		end
		if IsModifiedClick and (IsModifiedClick("CHATLINK") or IsModifiedClick("DRESSUP") or IsModifiedClick("EXPANDITEM")) then
			return
		end

		local bag = nil
		local slot = nil
		if buttonFrame and buttonFrame.GetParent and buttonFrame:GetParent() and buttonFrame:GetParent().GetID then
			bag = buttonFrame:GetParent():GetID()
		end
		if buttonFrame and buttonFrame.GetID then
			slot = buttonFrame:GetID()
		end
		if type(bag) ~= "number" or type(slot) ~= "number" then
			return
		end

		if C_Container and C_Container.UseContainerItem then
			C_Container.UseContainerItem(bag, slot)
		elseif UseContainerItem then
			UseContainerItem(bag, slot)
		else
			return
		end

		QueueSendAttachmentPreviewUpdate()
	end)

	GM.UI.sendAttachmentBagHooked = true
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

local function UpdateRowMoneyCell(row, copper)
	if not row or not row.money then
		return
	end
	local value = tonumber(copper) or 0
	if value < 0 then
		value = 0
	end

	local gold = math.floor(value / 10000)
	local silver = math.floor((value % 10000) / 100)
	local copperOnly = value % 100
	local hasMoney = value > 0

	if row.moneyGoldText then
		row.moneyGoldText:SetText(gold > 0 and tostring(gold) or "")
	end
	if row.moneySilverText then
		row.moneySilverText:SetText((gold > 0 or silver > 0) and tostring(silver) or "")
	end
	if row.moneyCopperText then
		row.moneyCopperText:SetText(tostring(copperOnly))
	end
	if row.moneyDashText then
		row.moneyDashText:SetText(hasMoney and "" or "-")
	end

	local goldAlpha = (gold > 0) and 1 or 0.30
	local silverAlpha = (gold > 0 or silver > 0) and 1 or 0.30
	local copperAlpha = hasMoney and 1 or 0.30
	if row.moneyGoldIcon then
		row.moneyGoldIcon:SetAlpha(goldAlpha)
	end
	if row.moneySilverIcon then
		row.moneySilverIcon:SetAlpha(silverAlpha)
	end
	if row.moneyCopperIcon then
		row.moneyCopperIcon:SetAlpha(copperAlpha)
	end
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
	button:SetPoint("RIGHT", GM.UI.footer, "RIGHT", -8, 0)
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
		if UpdateSendAttachmentPreview then
			UpdateSendAttachmentPreview()
		end
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
	if not GM.UI.detailPanelOpen and GM.UI.detailPanel and GM.UI.detailPanel:IsShown() then
		GM.UI.detailPanel:Hide()
	end
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
			local function BuildInvoiceItemLabel(rawName)
				local value = tostring(rawName or "")
				if value == "" then
					return "Attached Item"
				end
				local bracketName = value:match("|h%[(.-)%]|h")
				if bracketName and bracketName ~= "" then
					return bracketName
				end
				value = value:gsub("|c%x%x%x%x%x%x%x%x", "")
				value = value:gsub("|r", "")
				value = value:gsub("|H.-|h", "")
				value = value:gsub("|h", "")
				value = value:gsub("^%s+", "")
				value = value:gsub("%s+$", "")
				if value == "" or value:find("^%d+$") or value:find("^item:[%d:]+$") then
					return "Attached Item"
				end
				return value
			end
			local invoiceLines = {
				"Invoice: " .. tostring(invoiceType),
			}
			if itemName and itemName ~= "" then
				invoiceLines[#invoiceLines + 1] = "Item: " .. BuildInvoiceItemLabel(itemName)
			end
				if buyerName and buyerName ~= "" then
					invoiceLines[#invoiceLines + 1] = "Buyer: " .. tostring(buyerName)
				end
				sections[#sections + 1] = table.concat(invoiceLines, "\n")
			end
		end

	if #sections == 0 then
		return "No mail body content."
	end
	return table.concat(sections, "\n\n")
end

local function GetDetailItemDisplayName(itemName, itemLink)
	local function StripLinkCodes(text)
		local value = tostring(text or "")
		if value == "" then
			return ""
		end
		local bracket = value:match("|h%[(.-)%]|h")
		if bracket and bracket ~= "" then
			return bracket
		end
		value = value:gsub("|c%x%x%x%x%x%x%x%x", "")
		value = value:gsub("|r", "")
		value = value:gsub("|H.-|h", "")
		value = value:gsub("|h", "")
		value = value:gsub("^%s+", "")
		value = value:gsub("%s+$", "")
		return value
	end

	local function IsUsableDisplayName(text)
		local value = tostring(text or "")
		if value == "" then
			return false
		end
		if value:find("^%d+$") then
			return false
		end
		if value:find("^item:%d") then
			return false
		end
		if value:find("^item:[%d:]+$") then
			return false
		end
		return true
	end

	local nameText = StripLinkCodes(itemName)
	if IsUsableDisplayName(nameText) then
		return nameText
	end

	local resolvedLinkName = nil
	if itemLink and GetItemInfo then
		resolvedLinkName = GetItemInfo(itemLink)
		if IsUsableDisplayName(resolvedLinkName) then
			return tostring(resolvedLinkName)
		end
	end

	if itemLink then
		local linkLabel = StripLinkCodes(itemLink)
		if IsUsableDisplayName(linkLabel) then
			return linkLabel
		end
		if IsUsableDisplayName(resolvedLinkName) then
			return tostring(resolvedLinkName)
		end
	end
	return "Attached Item"
end

local function UpdateDetailPanel(rows)
	if not GM.UI or not GM.UI.detailPanel then
		return
	end
	local panel = GM.UI.detailPanel
	local selected = GM.UI.selectedMailIndex
	if not GM.UI.detailPanelOpen or not selected then
		local tooltipArea = GM.UI.detailItemTooltipArea
		if GameTooltip and tooltipArea and GameTooltip:IsOwned(tooltipArea) then
			GameTooltip:Hide()
		end
		panel:Hide()
		return
	end

	local row = FindRowByMailIndex(rows or {}, selected)
	if not row then
		local tooltipArea = GM.UI.detailItemTooltipArea
		if GameTooltip and tooltipArea and GameTooltip:IsOwned(tooltipArea) then
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
		local meta = "Money " .. FormatMoney(row.money) .. "   COD " .. FormatMoney(row.codAmount)
		if GetInboxInvoiceInfo then
			local invoiceType = GetInboxInvoiceInfo(row.index)
			if invoiceType and not row.hasItem then
				meta = "Amount received: " .. FormatMoney(row.money)
			end
		end
		GM.UI.detailMetaText:SetText(meta)
	end

	if GM.UI.detailItemText and GM.UI.detailItemIcon then
		if row.hasItem and GetInboxItem then
			local itemName, itemID, itemTexture, itemCount, itemQuality = GetInboxItem(row.index, 1)
			local itemLink = GetInboxItemLink and GetInboxItemLink(row.index, 1) or nil
			local itemLabel = GetDetailItemDisplayName(itemName, itemLink)
			GM.UI.detailItemText:SetText(itemLabel)
			GM.UI.detailItemMailIndex = row.index
			GM.UI.detailItemLink = itemLink
			if itemTexture then
				GM.UI.detailItemIcon:SetTexture(itemTexture)
				GM.UI.detailItemIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				GM.UI.detailItemIcon:SetVertexColor(1, 1, 1, 1)
			else
				GM.UI.detailItemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				GM.UI.detailItemIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				GM.UI.detailItemIcon:SetVertexColor(1, 1, 1, 1)
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
					GM.UI.detailItemIconBorder:SetBackdropBorderColor(q.r, q.g, q.b, 0.95)
				else
					GM.UI.detailItemIconBorder:SetBackdropBorderColor(unpack(THEME.detailItemBorderFallback))
				end
			end
			if GM.UI.detailItemText and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[itemQuality or -1] then
				local q = ITEM_QUALITY_COLORS[itemQuality or -1]
				GM.UI.detailItemText:SetTextColor(q.r, q.g, q.b)
			elseif GM.UI.detailItemText then
				GM.UI.detailItemText:SetTextColor(unpack(THEME_TEXT.detailItem))
			end
		else
			GM.UI.detailItemText:SetText("No item attachment")
			GM.UI.detailItemIcon:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
			GM.UI.detailItemIcon:SetTexCoord(0, 1, 0, 1)
			GM.UI.detailItemIcon:SetVertexColor(0.72, 0.72, 0.72, 0.9)
			GM.UI.detailItemText:SetTextColor(unpack(THEME_TEXT.detailItem))
			GM.UI.detailItemMailIndex = nil
			GM.UI.detailItemLink = nil
			local tooltipArea = GM.UI.detailItemTooltipArea
			if GameTooltip and tooltipArea and GameTooltip:IsOwned(tooltipArea) then
				GameTooltip:Hide()
			end
			if GM.UI.detailItemCountText then
				GM.UI.detailItemCountText:SetText("")
			end
			if GM.UI.detailItemIconBorder then
				GM.UI.detailItemIconBorder:SetBackdropBorderColor(unpack(THEME.detailItemBorder))
			end
		end
		if GM.UI.detailItemTooltipArea then
			local enableTooltip = GM.UI.detailItemMailIndex ~= nil
			GM.UI.detailItemTooltipArea:SetEnabled(enableTooltip)
			GM.UI.detailItemTooltipArea:EnableMouse(enableTooltip)
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
	local selectedExistsInData = (not GM.UI.selectedMailIndex) or (FindRowByMailIndex(dataRows, GM.UI.selectedMailIndex) ~= nil)
	for i = 1, visibleRowCount do
		local row = GM.UI.rows[i]
		local dataIndex = offset + i
		local data = dataRows[dataIndex]
		if data then
			row.mailIndex = data.index
			row.isRead = data.wasRead and true or false
			row.sender:SetText(data.sender)
			row.subject:SetText(CompactSubject(data.subject))
			UpdateRowMoneyCell(row, data.money)
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
				if data.hasItem and GetInboxItem and ITEM_QUALITY_COLORS then
					local _, _, _, _, itemQuality = GetInboxItem(data.index, 1)
					local qualityColor = ITEM_QUALITY_COLORS[itemQuality or -1]
					if qualityColor then
						row.subject:SetTextColor(qualityColor.r, qualityColor.g, qualityColor.b)
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
	if GM.UI.selectedMailIndex and not selectedExistsInData then
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
	cell:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -3)
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
	row.subject:SetPoint("LEFT", row.sender, "RIGHT", COL_GAP - 2, 0)
	row.subject:SetWidth(COL_SUBJECT)
	row.subject:SetJustifyH("LEFT")
	row.subject:SetWordWrap(false)

	row.money = CreateFrame("Frame", nil, row)
	row.money:SetPoint("LEFT", row.subject, "RIGHT", COL_SUBJECT_MONEY_GAP, 0)
	row.money:SetSize(COL_MONEY, ROW_HEIGHT)

	row.moneyCopperIcon = row.money:CreateTexture(nil, "OVERLAY")
	row.moneyCopperSegment = CreateFrame("Frame", nil, row.money)
	row.moneyCopperSegment:SetSize(26, ROW_HEIGHT)
	row.moneyCopperSegment:SetPoint("RIGHT", row.money, "RIGHT", -1, 0)

	row.moneyCopperIcon:SetSize(9, 9)
	row.moneyCopperIcon:SetPoint("RIGHT", row.moneyCopperSegment, "RIGHT", 0, 0)
	row.moneyCopperIcon:SetTexture("Interface\\MoneyFrame\\UI-CopperIcon")

	row.moneyCopperText = row.moneyCopperSegment:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.moneyCopperText:SetPoint("LEFT", row.moneyCopperSegment, "LEFT", 0, 0)
	row.moneyCopperText:SetPoint("RIGHT", row.moneyCopperIcon, "LEFT", -1, 0)
	row.moneyCopperText:SetJustifyH("RIGHT")
	row.moneyCopperText:SetWordWrap(false)

	row.moneySilverSegment = CreateFrame("Frame", nil, row.money)
	row.moneySilverSegment:SetSize(26, ROW_HEIGHT)
	row.moneySilverSegment:SetPoint("RIGHT", row.moneyCopperSegment, "LEFT", -1, 0)

	row.moneySilverIcon = row.money:CreateTexture(nil, "OVERLAY")
	row.moneySilverIcon:SetSize(9, 9)
	row.moneySilverIcon:SetPoint("RIGHT", row.moneySilverSegment, "RIGHT", 0, 0)
	row.moneySilverIcon:SetTexture("Interface\\MoneyFrame\\UI-SilverIcon")

	row.moneySilverText = row.moneySilverSegment:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.moneySilverText:SetPoint("LEFT", row.moneySilverSegment, "LEFT", 0, 0)
	row.moneySilverText:SetPoint("RIGHT", row.moneySilverIcon, "LEFT", -1, 0)
	row.moneySilverText:SetJustifyH("RIGHT")
	row.moneySilverText:SetWordWrap(false)

	row.moneyGoldIcon = row.money:CreateTexture(nil, "OVERLAY")
	row.moneyGoldIcon:SetSize(9, 9)
	row.moneyGoldIcon:SetPoint("RIGHT", row.moneySilverSegment, "LEFT", -1, 0)
	row.moneyGoldIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")

	row.moneyGoldText = row.money:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.moneyGoldText:SetPoint("LEFT", row.money, "LEFT", 0, 0)
	row.moneyGoldText:SetPoint("RIGHT", row.moneyGoldIcon, "LEFT", -1, 0)
	row.moneyGoldText:SetJustifyH("RIGHT")
	row.moneyGoldText:SetWordWrap(false)

	row.moneyDashText = row.money:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.moneyDashText:SetPoint("RIGHT", row.money, "RIGHT", -1, 0)
	row.moneyDashText:SetText("")
	row.moneyDashText:SetWordWrap(false)

	UpdateRowMoneyCell(row, 0)

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

local function GetSafeResizeMaxHeight(frame)
	local parentHeight = (UIParent and UIParent:GetHeight()) or RESIZE_MAX_HEIGHT
	local hardMax = math.min(RESIZE_MAX_HEIGHT, math.max(RESIZE_MIN_HEIGHT, parentHeight - 16))
	if not frame or not UIParent or not UIParent.GetBottom or not frame.GetTop then
		return hardMax
	end
	local uiBottom = UIParent:GetBottom() or 0
	local frameTop = frame:GetTop()
	if not frameTop then
		return hardMax
	end
	local fromTop = math.floor(frameTop - uiBottom - 8)
	if fromTop < RESIZE_MIN_HEIGHT then
		return RESIZE_MIN_HEIGHT
	end
	return math.min(hardMax, fromTop)
end

local function GetSafeResizeHeight(frame, rawHeight, preferDefaultWhenInvalid)
	local minH = RESIZE_MIN_HEIGHT
	local maxH = GetSafeResizeMaxHeight(frame)
	if maxH < minH then
		maxH = minH
	end
	local candidate = tonumber(rawHeight) or minH
	local isInvalid = candidate < minH or candidate > maxH
	if preferDefaultWhenInvalid and isInvalid then
		candidate = math.min(maxH, math.max(minH, DEFAULT_FRAME_HEIGHT))
	else
		candidate = math.min(maxH, math.max(minH, candidate))
	end
	return candidate, maxH
end

local function BuildSendPanel(frame)
	local panelPadX = 12
	local fieldTopGap = 8
	local labelToFieldGap = 3
	local sectionGap = 8

	local sendPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	sendPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", panelPadX, -58)
	sendPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -panelPadX, -58)
	sendPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", panelPadX, 8)
	sendPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -panelPadX, 8)
	sendPanel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	sendPanel:SetBackdropColor(unpack(THEME.surfaceBg))
	sendPanel:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.listBorder)))
	ApplySurfaceLayers(sendPanel, THEME.listBorder, THEME.title)
	ApplySoftCorners(sendPanel, THEME.surfaceBg)
	sendPanel:Hide()
	GM.UI.sendPanel = sendPanel

	local sendRecipientLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendRecipientLabel:SetPoint("TOPLEFT", sendPanel, "TOPLEFT", 12, -8)
	sendRecipientLabel:SetText("Recipient")
	GM.UI.sendRecipientLabel = sendRecipientLabel

	local sendRecipientInput = CreateFrame("EditBox", nil, sendPanel, "InputBoxTemplate")
	sendRecipientInput:SetAutoFocus(false)
	sendRecipientInput:SetHeight(20)
	sendRecipientInput:SetPoint("TOPLEFT", sendRecipientLabel, "BOTTOMLEFT", 0, -labelToFieldGap)
	sendRecipientInput:SetPoint("TOPRIGHT", sendPanel, "TOP", -8, -21)
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
	sendSubjectLabel:SetPoint("TOPLEFT", sendPanel, "TOP", 8, -8)
	sendSubjectLabel:SetText("Subject")
	GM.UI.sendSubjectLabel = sendSubjectLabel

	local sendSubjectInput = CreateFrame("EditBox", nil, sendPanel, "InputBoxTemplate")
	sendSubjectInput:SetAutoFocus(false)
	sendSubjectInput:SetHeight(20)
	sendSubjectInput:SetPoint("TOPLEFT", sendSubjectLabel, "BOTTOMLEFT", 0, -labelToFieldGap)
	sendSubjectInput:SetPoint("TOPRIGHT", sendPanel, "TOPRIGHT", -14, -21)
	sendSubjectInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	sendSubjectInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	GM.UI.sendSubjectInput = sendSubjectInput

	local sendGoldLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendGoldLabel:SetText("Gold")
	GM.UI.sendGoldLabel = sendGoldLabel

	local sendGoldInput = CreateFrame("EditBox", nil, sendPanel, "InputBoxTemplate")
	sendGoldInput:SetAutoFocus(false)
	sendGoldInput:SetHeight(20)
	sendGoldInput:SetNumeric(false)
	sendGoldInput:SetWidth(72)
	sendGoldInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	sendGoldInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	GM.UI.sendGoldInput = sendGoldInput

	local sendAttachmentLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendAttachmentLabel:SetText("")
	sendAttachmentLabel:Hide()
	GM.UI.sendAttachmentLabel = sendAttachmentLabel

	local sendAttachmentGroup = CreateFrame("Frame", nil, sendPanel, "BackdropTemplate")
	sendAttachmentGroup:SetPoint("TOPLEFT", sendRecipientInput, "BOTTOMLEFT", 0, -fieldTopGap)
	sendAttachmentGroup:SetPoint("TOPRIGHT", sendSubjectInput, "BOTTOMRIGHT", 0, -fieldTopGap)
	sendAttachmentGroup:SetHeight(50)
	sendAttachmentGroup:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	sendAttachmentGroup:SetBackdropColor(unpack(THEME.detailBodyBg))
	sendAttachmentGroup:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
	ApplySurfaceLayers(sendAttachmentGroup, THEME.detailBodyBorder, THEME.title)
	ApplySoftCorners(sendAttachmentGroup, THEME.detailBodyBg)
	GM.UI.sendAttachmentGroup = sendAttachmentGroup

	local sendAttachmentSlot = CreateFrame("Button", nil, sendAttachmentGroup, "BackdropTemplate")
	sendAttachmentSlot:SetSize(44, 44)
	sendAttachmentSlot:SetPoint("LEFT", sendAttachmentGroup, "LEFT", 7, 0)
	sendAttachmentSlot:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	sendAttachmentSlot:SetBackdropColor(unpack(THEME.detailBodyBg))
	sendAttachmentSlot:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
	ApplySoftCorners(sendAttachmentSlot, THEME.detailBodyBg)
	sendAttachmentSlot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	sendAttachmentSlot:SetScript("OnMouseUp", function(self, button)
		if not ClickSendMailItemButton then
			return
		end
		if button == "RightButton" then
			if self.hasItem then
				ClickSendMailItemButton(1, true)
			elseif CursorHasItem and CursorHasItem() then
				ClickSendMailItemButton(1)
			end
		else
			ClickSendMailItemButton(1)
		end
		QueueSendAttachmentPreviewUpdate()
	end)
	sendAttachmentSlot:SetScript("OnReceiveDrag", function()
		if not ClickSendMailItemButton then
			return
		end
		ClickSendMailItemButton(1)
		QueueSendAttachmentPreviewUpdate()
	end)
	GM.UI.sendAttachmentSlot = sendAttachmentSlot
	EnsureSendAttachmentBagHook()

	local sendAttachmentIcon = sendAttachmentSlot:CreateTexture(nil, "ARTWORK")
	sendAttachmentIcon:SetPoint("TOPLEFT", sendAttachmentSlot, "TOPLEFT", 4, -4)
	sendAttachmentIcon:SetPoint("BOTTOMRIGHT", sendAttachmentSlot, "BOTTOMRIGHT", -4, 4)
	sendAttachmentIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	sendAttachmentIcon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
	sendAttachmentIcon:SetVertexColor(0.62, 0.62, 0.62, 0.75)
	GM.UI.sendAttachmentIcon = sendAttachmentIcon

	local sendAttachmentCountText = sendAttachmentSlot:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	sendAttachmentCountText:SetPoint("BOTTOMRIGHT", sendAttachmentSlot, "BOTTOMRIGHT", -4, 3)
	sendAttachmentCountText:SetText("")
	GM.UI.sendAttachmentCountText = sendAttachmentCountText

	local sendAttachmentNameText = sendAttachmentGroup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sendAttachmentNameText:SetPoint("LEFT", sendAttachmentSlot, "RIGHT", 8, 0)
	sendAttachmentNameText:SetPoint("RIGHT", sendAttachmentGroup, "RIGHT", -258, 0)
	sendAttachmentNameText:SetJustifyH("LEFT")
	sendAttachmentNameText:SetWordWrap(false)
	sendAttachmentNameText:SetText("No attachment")
	GM.UI.sendAttachmentNameText = sendAttachmentNameText

	local sendAttachmentControls = CreateFrame("Frame", nil, sendAttachmentGroup)
	sendAttachmentControls:SetSize(222, 24)
	sendAttachmentControls:SetPoint("RIGHT", sendAttachmentGroup, "RIGHT", -14, 0)
	GM.UI.sendAttachmentControls = sendAttachmentControls

	sendGoldLabel:SetParent(sendAttachmentControls)
	sendGoldLabel:ClearAllPoints()
	sendGoldLabel:SetPoint("LEFT", sendAttachmentControls, "LEFT", 0, 0)
	sendGoldInput:SetParent(sendAttachmentControls)
	sendGoldInput:ClearAllPoints()
	sendGoldInput:SetWidth(56)
	sendGoldInput:SetPoint("LEFT", sendGoldLabel, "RIGHT", 4, 0)

	local sendCODToggle = CreateFrame("CheckButton", nil, sendAttachmentControls, "UICheckButtonTemplate")
	sendCODToggle:SetPoint("LEFT", sendGoldInput, "RIGHT", 5, -1)
	sendCODToggle:SetScript("OnClick", function()
		UpdateSendCODInputState()
	end)
	GM.UI.sendCODToggle = sendCODToggle

	local sendCODLabel = sendAttachmentControls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendCODLabel:SetPoint("LEFT", sendCODToggle, "RIGHT", -2, 0)
	sendCODLabel:SetText("COD")
	GM.UI.sendCODLabel = sendCODLabel

	local sendCODAmountLabel = sendAttachmentControls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendCODAmountLabel:SetPoint("LEFT", sendCODLabel, "RIGHT", 6, 0)
	sendCODAmountLabel:SetText("Amount")
	GM.UI.sendCODAmountLabel = sendCODAmountLabel

	local sendCODInput = CreateFrame("EditBox", nil, sendAttachmentControls, "InputBoxTemplate")
	sendCODInput:SetAutoFocus(false)
	sendCODInput:SetHeight(18)
	sendCODInput:SetNumeric(false)
	sendCODInput:SetWidth(48)
	sendCODInput:SetPoint("RIGHT", sendAttachmentControls, "RIGHT", 0, 0)
	sendCODInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	sendCODInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	GM.UI.sendCODInput = sendCODInput

	local sendAttachmentEventFrame = CreateFrame("Frame", nil, sendPanel)
	sendAttachmentEventFrame:RegisterEvent("MAIL_SEND_INFO_UPDATE")
	sendAttachmentEventFrame:RegisterEvent("MAIL_SEND_SUCCESS")
	sendAttachmentEventFrame:RegisterEvent("MAIL_FAILED")
	sendAttachmentEventFrame:RegisterEvent("MAIL_CLOSED")
	sendAttachmentEventFrame:SetScript("OnEvent", function(_, event)
		if event == "MAIL_CLOSED" then
			SetSendPendingState(false)
			return
		end
		if event == "MAIL_SEND_SUCCESS" then
			if GM.UI and GM.UI.sendPending then
				SetSendPendingState(false)
				ResetSendFormState(false)
				SetStatusText("Mail sent")
			end
			return
		end
		if event == "MAIL_FAILED" then
			if GM.UI and GM.UI.sendPending then
				SetSendPendingState(false)
				SetStatusText("Send failed")
			end
			return
		end
		if UpdateSendAttachmentPreview then
			UpdateSendAttachmentPreview()
		end
	end)
	GM.UI.sendAttachmentEventFrame = sendAttachmentEventFrame

	local sendBodyLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendBodyLabel:SetPoint("TOPLEFT", sendAttachmentGroup, "BOTTOMLEFT", 0, -sectionGap)
	sendBodyLabel:SetText("Message")
	GM.UI.sendBodyLabel = sendBodyLabel

	local sendActionBar = CreateFrame("Frame", nil, sendPanel, "BackdropTemplate")
	sendActionBar:SetPoint("BOTTOMLEFT", sendPanel, "BOTTOMLEFT", 10, 8)
	sendActionBar:SetPoint("BOTTOMRIGHT", sendPanel, "BOTTOMRIGHT", -10, 8)
	sendActionBar:SetHeight(24)
	sendActionBar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	sendActionBar:SetBackdropColor(unpack(THEME.detailBodyBg))
	sendActionBar:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
	ApplySurfaceLayers(sendActionBar, THEME.detailBodyBorder, THEME.title)
	ApplySoftCorners(sendActionBar, THEME.detailBodyBg)
	GM.UI.sendActionBar = sendActionBar

	local sendBodyFrame = CreateFrame("Frame", nil, sendPanel, "BackdropTemplate")
	sendBodyFrame:SetPoint("TOPLEFT", sendBodyLabel, "BOTTOMLEFT", 0, -3)
	sendBodyFrame:SetPoint("TOPRIGHT", sendPanel, "TOPRIGHT", -10, -124)
	sendBodyFrame:SetPoint("BOTTOMLEFT", sendActionBar, "TOPLEFT", 0, 4)
	sendBodyFrame:SetPoint("BOTTOMRIGHT", sendActionBar, "TOPRIGHT", 0, 4)
	sendBodyFrame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	sendBodyFrame:SetBackdropColor(unpack(THEME.detailBodyBg))
	sendBodyFrame:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
	ApplySoftCorners(sendBodyFrame, THEME.detailBodyBg)
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
	sendSendButton:SetPoint("RIGHT", sendActionBar, "RIGHT", -8, 0)
	sendSendButton:SetText("Send")
	sendSendButton:SetScript("OnClick", function()
		if GM.UI and GM.UI.sendPending then
			return
		end
		local recipient = TrimText(GM.UI.sendRecipientInput and GM.UI.sendRecipientInput:GetText() or "")
		if recipient == "" then
			SetStatusText("Recipient required")
			return
		end
		local subject = GM.UI.sendSubjectInput and GM.UI.sendSubjectInput:GetText() or ""
		local body = GM.UI.sendBodyInput and GM.UI.sendBodyInput:GetText() or ""
		local goldCopper = ParseCopperInput(GM.UI.sendGoldInput and GM.UI.sendGoldInput:GetText() or "")
		local codCopper = ParseCopperInput(GM.UI.sendCODInput and GM.UI.sendCODInput:GetText() or "")
		local hasAttachment = GM.UI.sendAttachmentSlot and GM.UI.sendAttachmentSlot.hasItem
		local codEnabled = hasAttachment and GM.UI.sendCODToggle and GM.UI.sendCODToggle:GetChecked()
		if SendMail then
			SetSendPendingState(true)
			SetStatusText("Sending...")
			if goldCopper > 0 and SetSendMailMoney then
				SetSendMailMoney(goldCopper)
			end
			if SetSendMailCOD then
				if codEnabled and codCopper > 0 then
					SetSendMailCOD(codCopper)
				else
					SetSendMailCOD(0)
				end
			end
			SendMail(recipient, subject, body)
		else
			SetStatusText("Send unavailable")
		end
	end)
	StyleButton(sendSendButton, "primary")
	GM.UI.sendSendButton = sendSendButton

	local sendClearButton = CreateFrame("Button", nil, sendPanel, "UIPanelButtonTemplate")
	sendClearButton:SetSize(90, 20)
	sendClearButton:SetPoint("RIGHT", sendSendButton, "LEFT", -6, 0)
	sendClearButton:SetText("Clear")
	sendClearButton:SetScript("OnClick", function()
		ResetSendFormState(true)
	end)
	StyleButton(sendClearButton, "normal")
	GM.UI.sendClearButton = sendClearButton
	SetSendPendingState(false)
	UpdateSendAttachmentPreview()
end

local function BuildInboxSummaryBar(frame)
	local summaryBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	summaryBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -34)
	summaryBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -34)
	summaryBar:SetHeight(24)
	summaryBar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	summaryBar:SetBackdropColor(unpack(THEME.surfaceBg))
	summaryBar:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.summaryBorder)))
	ApplySurfaceLayers(summaryBar, THEME.summaryBorder, THEME.title)
	ApplySoftCorners(summaryBar, THEME.surfaceBg)
	GM.UI.summaryBar = summaryBar

	local inboxGoldText = summaryBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	inboxGoldText:SetPoint("LEFT", summaryBar, "LEFT", 12, 0)
	inboxGoldText:SetJustifyH("LEFT")
	inboxGoldText:SetText("Inbox Gold: 0")
	inboxGoldText:SetTextColor(unpack(THEME_TEXT.inboxGold))
	GM.UI.inboxGoldText = inboxGoldText

	local inboxCountText = summaryBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	inboxCountText:SetPoint("RIGHT", summaryBar, "RIGHT", -12, 0)
	inboxCountText:SetJustifyH("RIGHT")
	inboxCountText:SetText("Inbox Mails: 0")
	inboxCountText:SetTextColor(unpack(THEME_TEXT.inboxCount))
	GM.UI.inboxCountText = inboxCountText
end

local function BuildInboxFooterFrame(frame)
	local footer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 8)
	footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 8)
	footer:SetHeight(24)
	footer:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	footer:SetBackdropColor(unpack(THEME.surfaceBg))
	footer:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.surfaceBorder)))
	ApplySurfaceLayers(footer, THEME.surfaceBorder, THEME.title)
	ApplySoftCorners(footer, THEME.surfaceBg)
	GM.UI.footer = footer
	return footer
end

local function BuildToolbarShell(frame)
	local toolbar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	toolbar:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -4)
	toolbar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
	toolbar:SetHeight(29)
	toolbar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	toolbar:SetBackdropColor(unpack(THEME.toolbarBg))
	toolbar:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.toolbarBorder)))
	ApplySurfaceLayers(toolbar, THEME.toolbarBorder, THEME.title)
	ApplySoftCorners(toolbar, THEME.toolbarBg)
	GM.UI.toolbar = toolbar

	local toolbarAccent = toolbar:CreateTexture(nil, "BACKGROUND")
	toolbarAccent:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 1, -1)
	toolbarAccent:SetPoint("TOPRIGHT", toolbar, "TOPRIGHT", -1, -1)
	toolbarAccent:SetHeight(1)
	toolbarAccent:SetColorTexture(unpack(TintColor(THEME.accent, 0.15, 0.52)))
	GM.UI.toolbarAccent = toolbarAccent

	local title = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("LEFT", toolbar, "LEFT", 10, 1)
	title:SetText("GorilMail")
	title:SetTextColor(unpack(THEME.title))
	GM.UI.title = title

	return toolbar
end

local function BuildListContainerFrame(frame, footer)
	local listContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	listContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -58)
	listContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -58)
	listContainer:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 0, 8)
	listContainer:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, 8)
	listContainer:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	listContainer:SetBackdropColor(unpack(THEME.surfaceBg))
	listContainer:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.listBorder)))
	ApplySurfaceLayers(listContainer, THEME.listBorder, THEME.title)
	ApplySoftCorners(listContainer, THEME.surfaceBg)
	GM.UI.listContainer = listContainer
	return listContainer
end

function GM.UI.Initialize()
	if GM.UI.frame then
		return
	end

	local frame = CreateFrame("Frame", "GorilMailPanel", UIParent, "BackdropTemplate")
	frame:SetSize(DEFAULT_FRAME_WIDTH, DEFAULT_FRAME_HEIGHT)
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
	GM.UI.fixedResizeWidth = DEFAULT_FRAME_WIDTH
	if frame.SetResizeBounds then
		frame:SetResizeBounds(DEFAULT_FRAME_WIDTH, RESIZE_MIN_HEIGHT, DEFAULT_FRAME_WIDTH, RESIZE_MAX_HEIGHT)
	elseif frame.SetMinResize then
		frame:SetMinResize(DEFAULT_FRAME_WIDTH, RESIZE_MIN_HEIGHT)
	end
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SaveMainFramePosition(self)
		PositionDetailPanel()
		local fixedW = GM.UI and GM.UI.fixedResizeWidth or DEFAULT_FRAME_WIDTH
		local safeH = GetSafeResizeHeight(self, self:GetHeight(), true)
		if math.abs((self:GetWidth() or fixedW) - fixedW) > 0.5 or math.abs((self:GetHeight() or safeH) - safeH) > 0.5 then
			GM.UI.layoutApplying = true
			self:SetSize(fixedW, safeH)
			GM.UI.layoutApplying = false
		end
	end)
	frame:SetScript("OnSizeChanged", function(self, width, height)
		if GM.UI and GM.UI.layoutApplying then
			return
		end
		local fixedWidth = GM.UI and GM.UI.fixedResizeWidth or DEFAULT_FRAME_WIDTH
		local clampedWidth = fixedWidth
		local clampedHeight = GetSafeResizeHeight(self, height or self:GetHeight() or RESIZE_MIN_HEIGHT, false)
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
	frame:SetScript("OnShow", function(self)
		local fixedWidth = GM.UI and GM.UI.fixedResizeWidth or DEFAULT_FRAME_WIDTH
		local safeHeight = GetSafeResizeHeight(self, self:GetHeight(), true)
		if math.abs((self:GetWidth() or fixedWidth) - fixedWidth) > 0.5 or math.abs((self:GetHeight() or safeHeight) - safeHeight) > 0.5 then
			GM.UI.layoutApplying = true
			self:SetSize(fixedWidth, safeHeight)
			GM.UI.layoutApplying = false
		end
		if EnsureVisibleRows then
			EnsureVisibleRows()
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
		if GM.UI and GM.UI.closingByX then
			GM.UI.closingByX = false
			return
		end
		if MailFrame then
			SetDefaultMailPanelWindowRegistered(true)
			SetDefaultMailPanelManaged(true)
			SetDefaultInboxInteractionEnabled(true)
			MailFrame:SetAlpha(1)
			MailFrame:EnableMouse(true)
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
		edgeSize = 8,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(unpack(THEME.panelBg))
	frame:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.panelBorder)))
	ApplySurfaceLayers(frame, THEME.panelBorder, THEME.title)
	ApplySoftCorners(frame, THEME.panelBg)
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
		frame:StartSizing("BOTTOM")
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

	local toolbar = BuildToolbarShell(frame)

	local closeButton = CreateFrame("Button", nil, toolbar, "UIPanelCloseButton")
	closeButton:SetPoint("RIGHT", toolbar, "RIGHT", 2, 0)
	closeButton:SetScript("OnClick", function()
		if GM.UI then
			GM.UI.closingByX = true
		end
		if MailFrame and MailFrame.IsShown and MailFrame:IsShown() then
			MailFrame:Hide()
		end
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

	-- Final toolbar ordering: A, H, Inbox, Send, WoW UI, X
	defaultUIButton:ClearAllPoints()
	defaultUIButton:SetPoint("RIGHT", closeButton, "LEFT", -10, 0)
	modeSendButton:ClearAllPoints()
	modeSendButton:SetPoint("RIGHT", defaultUIButton, "LEFT", -4, 0)
	modeInboxButton:ClearAllPoints()
	modeInboxButton:SetPoint("RIGHT", modeSendButton, "LEFT", -2, 0)
	themeHordeButton:ClearAllPoints()
	themeHordeButton:SetPoint("RIGHT", modeInboxButton, "LEFT", -4, 0)
	themeAllianceButton:ClearAllPoints()
	themeAllianceButton:SetPoint("RIGHT", themeHordeButton, "LEFT", -2, 0)

	BuildInboxSummaryBar(frame)

	local footer = BuildInboxFooterFrame(frame)

	local refreshButton = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
	refreshButton:SetSize(86, 19)
	refreshButton:SetPoint("LEFT", footer, "LEFT", 8, 0)
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

	local listContainer = BuildListContainerFrame(frame, footer)

	BuildSendPanel(frame)

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
	detailPanel:EnableMouse(true)
	detailPanel:Hide()
	GM.UI.detailPanel = detailPanel
	GM.UI.detailPanelOpen = false
	PositionDetailPanel()

	local detailHeader = CreateFrame("Frame", nil, detailPanel)
	detailHeader:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 6, -6)
	detailHeader:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -6, -6)
	detailHeader:SetHeight(50)

	local detailCloseButton = CreateFrame("Button", nil, detailPanel, "UIPanelCloseButton")
	detailCloseButton:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", 2, 2)
	detailCloseButton:SetScript("OnClick", function()
		SetDetailPanelOpen(false)
	end)
	GM.UI.detailCloseButton = detailCloseButton

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
	detailMetaText:SetPoint("TOPLEFT", detailHeader, "BOTTOMLEFT", 2, -48)
	detailMetaText:SetPoint("TOPRIGHT", detailHeader, "BOTTOMRIGHT", -2, -48)
	detailMetaText:SetJustifyH("LEFT")
	detailMetaText:SetText("Money: -   COD: -")
	detailMetaText:SetTextColor(unpack(THEME_TEXT.detailMeta))
	GM.UI.detailMetaText = detailMetaText

	local detailItemHitArea = CreateFrame("Frame", nil, detailPanel)
	detailItemHitArea:SetPoint("TOPLEFT", detailHeader, "BOTTOMLEFT", 1, -8)
	detailItemHitArea:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", -10, -4)
	detailItemHitArea:SetHeight(38)
	GM.UI.detailItemHitArea = detailItemHitArea

	local detailItemTooltipArea = CreateFrame("Button", nil, detailItemHitArea)
	detailItemTooltipArea:SetPoint("TOPLEFT", detailItemHitArea, "TOPLEFT", 1, -4)
	detailItemTooltipArea:SetSize(30, 30)
	detailItemTooltipArea:SetHitRectInsets(0, 0, -2, -2)
	detailItemTooltipArea:EnableMouse(true)
	local function HideDetailCompareTooltips()
		if GameTooltip_HideShoppingTooltips and GameTooltip then
			GameTooltip_HideShoppingTooltips(GameTooltip)
		end
		if ShoppingTooltip1 then
			ShoppingTooltip1:Hide()
		end
		if ShoppingTooltip2 then
			ShoppingTooltip2:Hide()
		end
	end
	detailItemTooltipArea:SetScript("OnEnter", function(self)
		if not GM.UI or not GM.UI.detailItemMailIndex then
			return
		end
		local tooltipOwner = (GM.UI and GM.UI.detailItemIcon) or self
		if GameTooltip and GameTooltip.SetInboxItem then
			GameTooltip:SetOwner(tooltipOwner, "ANCHOR_NONE")
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("TOPRIGHT", tooltipOwner, "TOPLEFT", -8, 0)
			local hasTooltip = GameTooltip:SetInboxItem(GM.UI.detailItemMailIndex, 1)
			if hasTooltip then
				GameTooltip:Show()
				HideDetailCompareTooltips()
				return
			end
		end
		if GameTooltip and GM.UI.detailItemLink and GameTooltip.SetHyperlink then
			GameTooltip:SetOwner(tooltipOwner, "ANCHOR_NONE")
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("TOPRIGHT", tooltipOwner, "TOPLEFT", -8, 0)
			GameTooltip:SetHyperlink(GM.UI.detailItemLink)
			GameTooltip:Show()
			HideDetailCompareTooltips()
		end
	end)
	detailItemTooltipArea:SetScript("OnLeave", function()
		HideDetailCompareTooltips()
		if GameTooltip and GM.UI and GM.UI.detailItemIcon and GameTooltip:IsOwned(GM.UI.detailItemIcon) then
			GameTooltip:Hide()
		end
	end)
	detailItemTooltipArea:SetScript("OnUpdate", function(self)
		if not GameTooltip or not GM.UI or not GM.UI.detailItemIcon or not GameTooltip:IsOwned(GM.UI.detailItemIcon) then
			return
		end
		if not self:IsMouseOver() then
			HideDetailCompareTooltips()
			GameTooltip:Hide()
		end
	end)
	detailItemTooltipArea:SetScript("OnHide", function()
		HideDetailCompareTooltips()
		if GameTooltip and GM.UI and GM.UI.detailItemIcon and GameTooltip:IsOwned(GM.UI.detailItemIcon) then
			GameTooltip:Hide()
		end
	end)
	detailItemTooltipArea:EnableMouse(false)
	GM.UI.detailItemTooltipArea = detailItemTooltipArea

	local detailItemIcon = detailItemHitArea:CreateTexture(nil, "ARTWORK")
	detailItemIcon:SetSize(30, 30)
	detailItemIcon:SetPoint("LEFT", detailItemHitArea, "LEFT", 2, 0)
	detailItemIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	detailItemIcon:SetTexture("Interface\\Buttons\\UI-EmptySlot-Disabled")
	GM.UI.detailItemIcon = detailItemIcon

	detailItemTooltipArea:ClearAllPoints()
	detailItemTooltipArea:SetPoint("TOPLEFT", detailItemIcon, "TOPLEFT", 0, 0)
	detailItemTooltipArea:SetPoint("BOTTOMRIGHT", detailItemIcon, "BOTTOMRIGHT", 0, 0)
	detailItemTooltipArea:SetHitRectInsets(0, 0, 0, 0)

	local detailItemIconBorder = CreateFrame("Frame", nil, detailItemHitArea, "BackdropTemplate")
	detailItemIconBorder:SetPoint("TOPLEFT", detailItemIcon, "TOPLEFT", -2, 2)
	detailItemIconBorder:SetPoint("BOTTOMRIGHT", detailItemIcon, "BOTTOMRIGHT", 2, -2)
	detailItemIconBorder:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8x8",
		edgeSize = 1,
	})
	detailItemIconBorder:SetBackdropBorderColor(unpack(THEME.detailItemBorder))
	GM.UI.detailItemIconBorder = detailItemIconBorder

	local detailItemCountText = detailItemHitArea:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
	detailItemCountText:SetPoint("BOTTOMRIGHT", detailItemIcon, "BOTTOMRIGHT", -2, 2)
	detailItemCountText:SetText("")
	detailItemCountText:SetTextColor(1.0, 1.0, 1.0)
	GM.UI.detailItemCountText = detailItemCountText

	local detailItemText = detailItemHitArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detailItemText:SetPoint("LEFT", detailItemIcon, "RIGHT", 8, 0)
	detailItemText:SetPoint("RIGHT", detailItemHitArea, "RIGHT", -2, 0)
	detailItemText:SetJustifyH("LEFT")
	detailItemText:SetWordWrap(false)
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
	detailBodyFrame:SetPoint("TOPLEFT", detailMetaText, "BOTTOMLEFT", -1, -6)
	detailBodyFrame:SetPoint("TOPRIGHT", detailMetaText, "BOTTOMRIGHT", 1, -6)
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
	header:SetHeight(20)

	local headerBg = header:CreateTexture(nil, "BACKGROUND")
	headerBg:SetAllPoints()
	headerBg:SetColorTexture(unpack(THEME.headerBg))
	GM.UI.headerBg = headerBg
	GM.UI.headerCells = {}

	local x = 4
	CreateHeaderCell(header, "Sender", COL_SENDER, x, "LEFT")
	-- Row content starts 10px further right than header baseline (dot + row insets).
	-- Shift Subject and following headers to match row column starts.
	x = x + COL_SENDER + COL_GAP + 8
	CreateHeaderCell(header, "Subject", COL_SUBJECT, x, "LEFT")
	x = x + COL_SUBJECT + COL_SUBJECT_MONEY_GAP
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
		GM.UI.closingByX = false
		GM.UI.viewMode = "inbox"
		if not GM.UI.mailSwapBootstrapDone then
			GM.UI.mailSwapBootstrapDone = true
			GM.UI.deferFirstMailFrameBookkeeping = true
		end
	end
	SetSendPendingState(false)
	HideRefreshNotice()
	SetDetailPanelOpen(false)
	ApplyViewMode()
	ApplyMailSwapVisibility()
end

function GM.UI.OnMailClosed()
	if GM.UI then
		GM.UI.refreshAwaitingCompletion = false
		GM.UI.showingDefaultUI = false
		GM.UI.closingByX = false
	end
	StopRefreshCooldown()
	SetSendPendingState(false)
	HideRefreshNotice()
	SetDetailPanelOpen(false)
	CloseDefaultMailDetailPanels()
	if MailFrame then
		SetDefaultMailPanelWindowRegistered(true)
		SetDefaultMailPanelManaged(true)
		SetDefaultInboxInteractionEnabled(true)
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
