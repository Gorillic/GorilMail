local addonName, GM = ...

GM = GM or {}

GM.UI = GM.UI or {}

local ROW_HEIGHT = 22
local VISIBLE_ROW_COUNT = 10
local COL_GAP = 5
local COL_SUBJECT_MONEY_GAP = 7
local COL_SENDER = 100
local COL_SUBJECT = 150
local COL_MONEY = 136
local COL_COD = 48
local COL_ITEM = 40
local COL_STATE = 38
local COL_ACTION = 48
local REFRESH_COOLDOWN_SECONDS = 10
local DETAIL_PANEL_WIDTH = 246
local DETAIL_PANEL_HEIGHT = 232
local DETAIL_FRAME_GAP = 6
local SEND_WATCHDOG_SECONDS = 4
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
local QueueSendAttachmentPreviewUpdate
local SetSendAttachmentReferenceItemFromSlot
local ClearSendAttachmentReferenceItem
local RefreshSendAttachmentReferenceItemFromCurrentSlots
local HandleFillSimilarButtonClick
local HandleClearAllButtonClick
local ApplyHeaderBandStyle
local ApplyRowBackground
local ResolveRowPrimaryAction
local HideItemCompareTooltips

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
			headerBg = { 0.19, 0.12, 0.11, 0.78 },
			rowEvenBg = { 0.16, 0.11, 0.10, 0.26 },
			rowOddBg = { 0.14, 0.10, 0.09, 0.24 },
			rowUnreadEvenBg = { 0.24, 0.16, 0.13, 0.34 },
			rowUnreadOddBg = { 0.21, 0.14, 0.12, 0.32 },
			rowHoverBg = { 0.28, 0.18, 0.14, 0.46 },
			rowSelectedBg = { 0.41, 0.25, 0.18, 0.72 },
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
				bg = { 0.22, 0.13, 0.10, 0.92 },
				hover = { 0.30, 0.18, 0.13, 0.98 },
				down = { 0.17, 0.10, 0.08, 0.98 },
				border = { 0.62, 0.37, 0.25, 0.88 },
				disabled = { 0.12, 0.09, 0.08, 0.62 },
			},
			normal = {
				text = { 0.90, 0.84, 0.78 },
				bg = { 0.15, 0.10, 0.09, 0.88 },
				hover = { 0.21, 0.14, 0.12, 0.94 },
				down = { 0.11, 0.08, 0.07, 0.98 },
				border = { 0.42, 0.29, 0.23, 0.85 },
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
			headerBg = { 0.12, 0.19, 0.28, 0.78 },
			rowEvenBg = { 0.11, 0.16, 0.22, 0.24 },
			rowOddBg = { 0.10, 0.15, 0.21, 0.22 },
			rowUnreadEvenBg = { 0.15, 0.24, 0.34, 0.33 },
			rowUnreadOddBg = { 0.14, 0.22, 0.32, 0.31 },
			rowHoverBg = { 0.18, 0.29, 0.42, 0.46 },
			rowSelectedBg = { 0.22, 0.38, 0.56, 0.68 },
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
				bg = { 0.13, 0.23, 0.35, 0.92 },
				hover = { 0.19, 0.30, 0.45, 0.98 },
				down = { 0.10, 0.18, 0.28, 0.98 },
				border = { 0.45, 0.61, 0.80, 0.88 },
				disabled = { 0.10, 0.13, 0.18, 0.62 },
			},
			normal = {
				text = { 0.84, 0.90, 0.98 },
				bg = { 0.11, 0.18, 0.27, 0.88 },
				hover = { 0.16, 0.25, 0.36, 0.94 },
				down = { 0.09, 0.14, 0.22, 0.98 },
				border = { 0.35, 0.50, 0.67, 0.85 },
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
local THEME_TOKENS = (ACTIVE_THEME and ACTIVE_THEME.tokens) or {}
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

local function BuildThemeTokens(theme)
	local colors = type(theme.colors) == "table" and theme.colors or {}
	local text = type(theme.text) == "table" and theme.text or {}
	local status = type(theme.status) == "table" and theme.status or {}
	local buttons = type(theme.buttons) == "table" and theme.buttons or {}
	local primary = type(buttons.primary) == "table" and buttons.primary or {}
	local secondary = type(buttons.normal) == "table" and buttons.normal or {}
	local rowAction = type(buttons.row) == "table" and buttons.row or {}

	return {
		window = {
			bg = colors.panelBg,
			border = colors.panelBorder,
		},
		surface = {
			panelBg = colors.surfaceBg,
			panelBorder = colors.surfaceBorder,
			detailBg = colors.detailBg,
			detailBorder = colors.detailBorder,
		},
		border = {
			strong = colors.panelBorder,
			normal = colors.surfaceBorder,
			subtle = status.buttonBorderDisabled,
		},
		text = {
			title = colors.title,
			normal = text.detailBody,
			muted = text.rowRead,
			header = text.header,
		},
		accent = colors.accent,
		tabs = {
			active = {
				bg = primary.bg,
				border = primary.border,
				text = primary.text,
			},
			inactive = {
				bg = secondary.bg,
				border = secondary.border,
				text = secondary.text,
			},
		},
		buttons = {
			primary = {
				bg = primary.bg,
				border = primary.border,
				text = primary.text,
			},
			secondary = {
				bg = secondary.bg,
				border = secondary.border,
				text = secondary.text,
			},
			rowAction = {
				bg = rowAction.bg,
				border = rowAction.border,
				text = rowAction.text,
			},
		},
		rows = {
			hover = colors.rowHoverBg,
			selected = colors.rowSelectedBg,
		},
		state = {
			success = status.ok,
			warn = text.inboxGold,
			danger = status.blocked,
			info = text.inboxCount,
		},
	}
end

for _, theme in pairs(THEMES) do
	if type(theme) == "table" and type(theme.tokens) ~= "table" then
		theme.tokens = BuildThemeTokens(theme)
	end
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
	local fallbackTokens = type(fallbackTheme.tokens) == "table" and fallbackTheme.tokens or {}

	ACTIVE_THEME_NAME = selectedName
	ACTIVE_THEME = selectedTheme
	THEME = WithFallback(selectedTheme.colors, fallbackColors)
	THEME_TEXT = WithFallback(selectedTheme.text, fallbackText)
	THEME_STATUS = WithFallback(selectedTheme.status, fallbackStatus)
	ACTIVE_THEME_BUTTONS = WithFallback(selectedTheme.buttons, fallbackButtons)
	THEME_TOKENS = WithFallback(selectedTheme.tokens, fallbackTokens)
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

local function ApplyPanelSurfaceStyle(frame, bgColor, borderColor, highlightColor)
	if not frame then
		return
	end
	frame:SetBackdropColor(unpack(bgColor))
	frame:SetBackdropBorderColor(unpack(SoftBorderColor(borderColor)))
	ApplySurfaceLayers(frame, borderColor, highlightColor or (THEME_TOKENS.text and THEME_TOKENS.text.title) or THEME.title)
	ApplySoftCorners(frame, bgColor)
end

local function BuildButtonPaletteFromToken(token, fallbackVariant, tuning)
	local fallback = GetButtonPalette(fallbackVariant or "normal")
	local source = type(token) == "table" and token or {}
	local style = type(tuning) == "table" and tuning or {}
	local bg = source.bg or fallback.bg
	local border = source.border or fallback.border
	local text = source.text or fallback.text
	return {
		bg = bg,
		hover = TintColor(bg or fallback.bg, style.hoverLift or 0.12, 1.0),
		down = ShadeColor(bg or fallback.bg, style.downDepth or 0.14, 1.0),
		border = border,
		text = text,
		disabled = fallback.disabled,
		topLightNormal = style.topLightNormal or 0.06,
		topLightHover = style.topLightHover or 0.11,
		topLightDown = style.topLightDown or 0.03,
		topLightDisabled = style.topLightDisabled or 0.02,
		bottomShadeNormal = style.bottomShadeNormal or 0.16,
		bottomShadeHover = style.bottomShadeHover or 0.13,
		bottomShadeDown = style.bottomShadeDown or 0.20,
		bottomShadeDisabled = style.bottomShadeDisabled or 0.13,
		fontShadowEnabled = style.fontShadowEnabled or 0.72,
		fontShadowDisabled = style.fontShadowDisabled or 0.60,
		normalTextureAlpha = style.normalTextureAlpha or 0.03,
		pushedTextureAlpha = style.pushedTextureAlpha or 0.02,
		highlightTextureAlpha = style.highlightTextureAlpha or 0.04,
	}
end

local function StyleButton(button, variant)
	if not button then
		return
	end
	local resolvedPalette = type(variant) == "table" and variant or GetButtonPalette(variant)
	button.gmPalette = resolvedPalette

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
	local function ApplyVisual(state)
		local palette = button.gmPalette or resolvedPalette or GetButtonPalette("normal")
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
					fs:SetShadowColor(0, 0, 0, palette.fontShadowEnabled or 0.72)
					if state == "down" then
						fs:SetShadowOffset(0, -1)
					else
						fs:SetShadowOffset(1, -1)
					end
				else
					fs:SetTextColor(unpack(THEME_TEXT.buttonDisabled or { 0.60, 0.60, 0.60 }))
					fs:SetShadowColor(0, 0, 0, palette.fontShadowDisabled or 0.60)
					fs:SetShadowOffset(1, -1)
				end
			end
			if not button:IsEnabled() then
				button.gmSkinBg:SetColorTexture(unpack(disabledBg))
				button.gmSkinBorder:SetColorTexture(unpack(THEME_STATUS.buttonBorderDisabled or { 0.24, 0.24, 0.24, 0.75 }))
				button.gmSkinTopLight:SetColorTexture(1, 1, 1, palette.topLightDisabled or 0.02)
				button.gmSkinBottomShade:SetColorTexture(0, 0, 0, palette.bottomShadeDisabled or 0.13)
				return
			end
			if state == "down" then
				button.gmSkinBg:SetColorTexture(unpack(downBg))
				button.gmSkinTopLight:SetColorTexture(1, 1, 1, palette.topLightDown or 0.03)
				button.gmSkinBottomShade:SetColorTexture(0, 0, 0, palette.bottomShadeDown or 0.20)
			elseif state == "hover" then
				button.gmSkinBg:SetColorTexture(unpack(hoverBg))
				button.gmSkinTopLight:SetColorTexture(1, 1, 1, palette.topLightHover or 0.11)
				button.gmSkinBottomShade:SetColorTexture(0, 0, 0, palette.bottomShadeHover or 0.13)
			else
				button.gmSkinBg:SetColorTexture(unpack(normalBg))
				button.gmSkinTopLight:SetColorTexture(1, 1, 1, palette.topLightNormal or 0.06)
				button.gmSkinBottomShade:SetColorTexture(0, 0, 0, palette.bottomShadeNormal or 0.16)
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
		normal:SetVertexColor(1, 1, 1, resolvedPalette.normalTextureAlpha or 0.03)
	end
	if pushed then
		pushed:SetVertexColor(1, 1, 1, resolvedPalette.pushedTextureAlpha or 0.02)
	end
	if highlight then
		highlight:SetVertexColor(1, 1, 1, resolvedPalette.highlightTextureAlpha or 0.04)
	end
	ApplyVisual("normal")
end

local function StyleGeneralButton(button, role)
	if role == "primary" then
		local token = THEME_TOKENS and THEME_TOKENS.buttons and THEME_TOKENS.buttons.primary
		StyleButton(button, BuildButtonPaletteFromToken(token, "primary", {
			hoverLift = 0.16,
			downDepth = 0.16,
			topLightNormal = 0.05,
			topLightHover = 0.11,
			topLightDown = 0.02,
			bottomShadeNormal = 0.17,
			bottomShadeHover = 0.14,
			bottomShadeDown = 0.23,
			highlightTextureAlpha = 0.05,
		}))
		return
	end
	if role == "secondary" then
		local token = THEME_TOKENS and THEME_TOKENS.buttons and THEME_TOKENS.buttons.secondary
		StyleButton(button, BuildButtonPaletteFromToken(token, "normal", {
			hoverLift = 0.10,
			downDepth = 0.12,
			topLightNormal = 0.04,
			topLightHover = 0.08,
			topLightDown = 0.02,
			bottomShadeNormal = 0.15,
			bottomShadeHover = 0.12,
			bottomShadeDown = 0.19,
			highlightTextureAlpha = 0.03,
		}))
		return
	end
	if role == "rowAction" then
		local token = THEME_TOKENS and THEME_TOKENS.buttons and THEME_TOKENS.buttons.rowAction
		StyleButton(button, BuildButtonPaletteFromToken(token, "row", {
			hoverLift = 0.15,
			downDepth = 0.17,
			topLightNormal = 0.05,
			topLightHover = 0.11,
			topLightDown = 0.02,
			bottomShadeNormal = 0.18,
			bottomShadeHover = 0.15,
			bottomShadeDown = 0.24,
			highlightTextureAlpha = 0.05,
		}))
		return
	end
	if role == "accent" then
		StyleButton(button, "accent")
		return
	end
	StyleButton(button, "normal")
end

local function StyleTabButton(button, isActive)
	if not button then
		return
	end
	if isActive then
		local token = THEME_TOKENS and THEME_TOKENS.tabs and THEME_TOKENS.tabs.active
		StyleButton(button, BuildButtonPaletteFromToken(token, "primary", {
			hoverLift = 0.12,
			downDepth = 0.14,
			topLightNormal = 0.05,
			topLightHover = 0.09,
			topLightDown = 0.02,
			bottomShadeNormal = 0.16,
			bottomShadeHover = 0.14,
			bottomShadeDown = 0.21,
		}))
	else
		local token = THEME_TOKENS and THEME_TOKENS.tabs and THEME_TOKENS.tabs.inactive
		StyleButton(button, BuildButtonPaletteFromToken(token, "normal", {
			hoverLift = 0.08,
			downDepth = 0.10,
			topLightNormal = 0.03,
			topLightHover = 0.06,
			topLightDown = 0.02,
			bottomShadeNormal = 0.14,
			bottomShadeHover = 0.12,
			bottomShadeDown = 0.18,
			highlightTextureAlpha = 0.03,
		}))
	end
end

local function StyleMiniToggleButton(button, isActive)
	if not button then
		return
	end
	local token = THEME_TOKENS and THEME_TOKENS.tabs and (isActive and THEME_TOKENS.tabs.active or THEME_TOKENS.tabs.inactive)
	local fallbackVariant = isActive and "primary" or "normal"
	StyleButton(button, BuildButtonPaletteFromToken(token, fallbackVariant, {
		hoverLift = isActive and 0.10 or 0.08,
		downDepth = isActive and 0.12 or 0.10,
		topLightNormal = isActive and 0.04 or 0.03,
		topLightHover = isActive and 0.08 or 0.06,
		topLightDown = 0.02,
		bottomShadeNormal = 0.15,
		bottomShadeHover = 0.13,
		bottomShadeDown = 0.19,
		normalTextureAlpha = 0.02,
		pushedTextureAlpha = 0.02,
		highlightTextureAlpha = 0.03,
	}))
end

local function StyleRowActionButton(button)
	StyleGeneralButton(button, "rowAction")
end

local function StyleSendActionButton(button, role)
	if not button then
		return
	end
	local tokenKey = role == "primary" and "primary" or "secondary"
	local token = THEME_TOKENS and THEME_TOKENS.buttons and THEME_TOKENS.buttons[tokenKey]
	local fallbackVariant = role == "primary" and "primary" or "normal"
	StyleButton(button, BuildButtonPaletteFromToken(token, fallbackVariant, {
		hoverLift = role == "primary" and 0.14 or 0.10,
		downDepth = role == "primary" and 0.14 or 0.11,
		topLightNormal = 0.05,
		topLightHover = 0.09,
		topLightDown = 0.02,
		bottomShadeNormal = 0.14,
		bottomShadeHover = 0.12,
		bottomShadeDown = 0.18,
		normalTextureAlpha = 0.02,
		pushedTextureAlpha = 0.02,
		highlightTextureAlpha = 0.03,
	}))
	if button.gmSkinBorder then
		button.gmSkinBorder:SetAlpha(0.92)
	end
	if button.gmSkinTopLight then
		button.gmSkinTopLight:SetHeight(1)
	end
end

local function ResolveThemeTextColor(tokenKey, fallbackColor)
	local tokenText = THEME_TOKENS and THEME_TOKENS.text
	if tokenText and tokenText[tokenKey] then
		return tokenText[tokenKey]
	end
	return fallbackColor
end

local function ResolveThemeStateColor(tokenKey, fallbackColor)
	local tokenState = THEME_TOKENS and THEME_TOKENS.state
	if tokenState and tokenState[tokenKey] then
		return tokenState[tokenKey]
	end
	return fallbackColor
end

local function ApplyFontStringColor(target, color)
	if target and color then
		target:SetTextColor(unpack(color))
	end
end

local function ApplyFontColorGroup(targets, color)
	for i = 1, #targets do
		ApplyFontStringColor(targets[i], color)
	end
end

ApplyThemeToUI = function()
	if not GM.UI then
		return
	end

	if GM.UI.frame then
		ApplyPanelSurfaceStyle(GM.UI.frame, THEME.panelBg, THEME.panelBorder, THEME.title)
	end
	if GM.UI.toolbar then
		ApplyPanelSurfaceStyle(GM.UI.toolbar, THEME.toolbarBg, THEME.toolbarBorder, THEME.title)
	end
	if GM.UI.toolbarAccent then
		GM.UI.toolbarAccent:SetColorTexture(unpack(TintColor((THEME_TOKENS and THEME_TOKENS.accent) or THEME.accent, 0.15, 0.52)))
	end
	if GM.UI.title then
		ApplyFontStringColor(GM.UI.title, ResolveThemeTextColor("title", THEME.title))
	end
	if GM.UI.summaryBar then
		ApplyPanelSurfaceStyle(GM.UI.summaryBar, THEME.surfaceBg, THEME.summaryBorder, THEME.title)
	end
	if GM.UI.footer then
		ApplyPanelSurfaceStyle(GM.UI.footer, THEME.surfaceBg, THEME.surfaceBorder, THEME.title)
	end
	if GM.UI.listContainer then
		ApplyPanelSurfaceStyle(GM.UI.listContainer, THEME.surfaceBg, THEME.listBorder, THEME.title)
	end
	if GM.UI.headerBg then
		GM.UI.headerBg:SetColorTexture(unpack(THEME.headerBg))
	end
	if GM.UI.header then
		ApplyHeaderBandStyle()
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
				ApplyFontStringColor(GM.UI.refreshNoticeText, ResolveThemeStateColor("danger", THEME_STATUS.refreshError))
			else
				ApplyFontStringColor(GM.UI.refreshNoticeText, ResolveThemeStateColor("success", THEME_STATUS.refreshSuccess))
			end
		else
			ApplyFontStringColor(GM.UI.refreshNoticeText, ResolveThemeStateColor("info", THEME_STATUS.refreshSuccess))
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
		ApplyFontStringColor(GM.UI.detailFromText, THEME_TEXT.detailFrom)
	end
	if GM.UI.detailSubjectText then
		ApplyFontStringColor(GM.UI.detailSubjectText, THEME_TEXT.detailSubject)
	end
	if GM.UI.detailMetaText then
		ApplyFontStringColor(GM.UI.detailMetaText, THEME_TEXT.detailMeta)
	end
	if GM.UI.detailItemIconBorder then
		GM.UI.detailItemIconBorder:SetBackdropBorderColor(unpack(THEME.detailItemBorder))
	end
	if GM.UI.detailItemText then
		ApplyFontStringColor(GM.UI.detailItemText, THEME_TEXT.detailItem)
	end
	if GM.UI.detailBodyFrame then
		GM.UI.detailBodyFrame:SetBackdropColor(unpack(THEME.detailBodyBg))
		GM.UI.detailBodyFrame:SetBackdropBorderColor(unpack(THEME.detailBodyBorder))
	end
	if GM.UI.detailBodyText then
		ApplyFontStringColor(GM.UI.detailBodyText, THEME_TEXT.detailBody)
	end
	if GM.UI.sendPanel then
		ApplyPanelSurfaceStyle(GM.UI.sendPanel, THEME.surfaceBg, THEME.listBorder, THEME.title)
	end
	if GM.UI.sendAttachmentGroup then
		ApplyPanelSurfaceStyle(GM.UI.sendAttachmentGroup, THEME.detailBodyBg, THEME.detailBodyBorder, THEME.title)
	end
	if GM.UI.sendRecipientField then
		ApplyPanelSurfaceStyle(GM.UI.sendRecipientField, THEME.detailBodyBg, THEME.detailBodyBorder, THEME.title)
	end
	if GM.UI.sendSubjectField then
		ApplyPanelSurfaceStyle(GM.UI.sendSubjectField, THEME.detailBodyBg, THEME.detailBodyBorder, THEME.title)
	end
	if GM.UI.sendAttachmentControls then
		ApplyPanelSurfaceStyle(GM.UI.sendAttachmentControls, THEME.surfaceBg, THEME.surfaceBorder, THEME.title)
	end
	if GM.UI.sendActionBar then
		ApplyPanelSurfaceStyle(GM.UI.sendActionBar, THEME.detailBodyBg, THEME.detailBodyBorder, THEME.title)
	end
	if GM.UI.sendBodyFrame then
		GM.UI.sendBodyFrame:SetBackdropColor(unpack(THEME.detailBodyBg))
		GM.UI.sendBodyFrame:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
		ApplySoftCorners(GM.UI.sendBodyFrame, THEME.detailBodyBg)
	end
	ApplyFontColorGroup({
		GM.UI.sendRecipientLabel,
		GM.UI.sendSubjectLabel,
		GM.UI.sendAttachmentTitle,
		GM.UI.sendPaymentTitle,
		GM.UI.sendGoldLabel,
		GM.UI.sendAttachmentLabel,
		GM.UI.sendCODLabel,
		GM.UI.sendCODAmountLabel,
		GM.UI.sendBodyLabel,
	}, ResolveThemeTextColor("header", THEME_TEXT.header))
	ApplyFontColorGroup({
		GM.UI.sendAttachHintText,
	}, ResolveThemeTextColor("muted", THEME_TEXT.rowRead))
	ApplyFontColorGroup({
		GM.UI.sendRecipientInput,
		GM.UI.sendSubjectInput,
		GM.UI.sendGoldInput,
		GM.UI.sendAttachmentNameText,
		GM.UI.sendCODInput,
		GM.UI.sendBodyInput,
	}, ResolveThemeTextColor("normal", THEME_TEXT.detailBody))
	if GM.UI.sendAttachmentSlots then
		for i = 1, #GM.UI.sendAttachmentSlots do
			local slot = GM.UI.sendAttachmentSlots[i]
			if slot then
				slot:SetBackdropColor(unpack(THEME.detailBodyBg))
				slot:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
				ApplySoftCorners(slot, THEME.detailBodyBg)
			end
		end
	end
	if GM.UI.headerCells then
		local headerColor = ResolveThemeTextColor("header", THEME_TEXT.header)
		for i = 1, #GM.UI.headerCells do
			local cell = GM.UI.headerCells[i]
			if cell and cell.SetTextColor then
				cell:SetTextColor(unpack(headerColor))
			end
		end
	end

	for _, pair in ipairs({
		{ GM.UI.returnButton, "accent" },
		{ GM.UI.defaultUIButton, "secondary" },
		{ GM.UI.refreshButton, "secondary" },
		{ GM.UI.collectAllButton, "primary" },
		{ GM.UI.sendFillSimilarButton, "secondary" },
		{ GM.UI.sendAttachmentClearAllButton, "secondary" },
		{ GM.UI.detailCollectButton, "rowAction" },
	}) do
		local button = pair[1]
		local role = pair[2]
		if button then
			StyleGeneralButton(button, role)
		end
	end
	if GM.UI.sendSendButton then
		StyleSendActionButton(GM.UI.sendSendButton, "primary")
	end
	if GM.UI.sendClearButton then
		StyleSendActionButton(GM.UI.sendClearButton, "secondary")
	end
	if GM.UI.modeInboxButton then
		StyleTabButton(GM.UI.modeInboxButton, false)
	end
	if GM.UI.modeSendButton then
		StyleTabButton(GM.UI.modeSendButton, false)
	end
	if GM.UI.rows then
		for i = 1, #GM.UI.rows do
			local row = GM.UI.rows[i]
			if row and row.collectButton then
				StyleRowActionButton(row.collectButton)
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
		StyleMiniToggleButton(GM.UI.themeAllianceButton, ACTIVE_THEME_NAME == "Alliance")
	end
	if GM.UI.themeHordeButton then
		StyleMiniToggleButton(GM.UI.themeHordeButton, ACTIVE_THEME_NAME == "Horde")
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
	StyleGeneralButton(button, "accent")
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
		ApplyFontStringColor(GM.UI.refreshNoticeText, ResolveThemeStateColor("danger", THEME_STATUS.refreshError))
	else
		ApplyFontStringColor(GM.UI.refreshNoticeText, ResolveThemeStateColor("success", THEME_STATUS.refreshSuccess))
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

local function ParseGoldInput(value)
	local text = TrimText(value)
	if text == "" then
		return 0
	end
	local amount = tonumber(text)
	if not amount or amount <= 0 then
		return 0
	end
	return math.floor(amount * 10000)
end

local SEND_UI_ERROR_KEYS = {
	"ERR_MAIL_DATABASE_ERROR",
	"ERR_MAIL_BOUND_ITEM",
	"ERR_MAIL_QUEST_ITEM",
	"ERR_MAIL_TARGET_NOT_FOUND",
	"ERR_MAIL_RECIPIENT_REQUIRED",
	"ERR_MAIL_SENT",
	"ERR_NOT_ENOUGH_MONEY",
}

local function IsLikelySendUIError(text)
	if type(text) ~= "string" or text == "" then
		return false
	end
	for i = 1, #SEND_UI_ERROR_KEYS do
		local globalText = _G and _G[SEND_UI_ERROR_KEYS[i]]
		if type(globalText) == "string" and globalText ~= "" and text == globalText then
			return true
		end
	end
	return false
end

local function TryEnableMailRecipientAutoComplete(editBox)
	if not editBox then
		return
	end
	local defaultRecipientBox = _G and _G.SendMailNameEditBox
	if not defaultRecipientBox or not defaultRecipientBox.GetScript then
		return
	end

	local copiedFields = {
		"autoCompleteFormatRegex",
		"autoCompleteParams",
		"autoCompleteSource",
		"exclude",
	}
	for i = 1, #copiedFields do
		local key = copiedFields[i]
		if defaultRecipientBox[key] ~= nil then
			editBox[key] = defaultRecipientBox[key]
		end
	end

	local mirrorScriptNames = {
		"OnChar",
		"OnTextChanged",
		"OnTabPressed",
		"OnEditFocusGained",
		"OnEditFocusLost",
	}
	for i = 1, #mirrorScriptNames do
		local scriptName = mirrorScriptNames[i]
		local blizzardScript = defaultRecipientBox:GetScript(scriptName)
		if type(blizzardScript) == "function" then
			editBox:SetScript(scriptName, function(self, ...)
				blizzardScript(self, ...)
			end)
		end
	end
end

local function AppendSendDebugDump(stage, payload)
	if GM.DebugPanel and GM.DebugPanel.AppendDump then
		GM.DebugPanel.AppendDump("Send " .. tostring(stage or "event"), payload or {})
	end
end

local function GetSendAttachmentMaxSlots()
	if type(ATTACHMENTS_MAX_SEND) == "number" and ATTACHMENTS_MAX_SEND > 0 then
		return ATTACHMENTS_MAX_SEND
	end
	if type(NUM_SENDMAIL_ATTACHMENTS) == "number" and NUM_SENDMAIL_ATTACHMENTS > 0 then
		return NUM_SENDMAIL_ATTACHMENTS
	end
	return 12
end

local function GetSendAttachmentInfo(index)
	if type(index) ~= "number" or index < 1 or not GetSendMailItem then
		return nil, nil, nil, nil
	end
	return GetSendMailItem(index)
end

local function HasAnySendAttachment()
	local maxSlots = GetSendAttachmentMaxSlots()
	for i = 1, maxSlots do
		local itemName = GetSendAttachmentInfo(i)
		if itemName then
			return true
		end
	end
	return false
end

local function GetDefaultSendSubjectFromAttachments()
	local firstItemName = GetSendAttachmentInfo(1)
	if firstItemName and tostring(firstItemName or "") ~= "" then
		return tostring(firstItemName)
	end
	local maxSlots = GetSendAttachmentMaxSlots()
	for i = 2, maxSlots do
		local itemName = GetSendAttachmentInfo(i)
		if itemName and tostring(itemName or "") ~= "" then
			return tostring(itemName)
		end
	end
	return ""
end

local function IsSendSubjectEmpty()
	if not GM.UI or not GM.UI.sendSubjectInput or not GM.UI.sendSubjectInput.GetText then
		return false
	end
	local subjectText = GM.UI.sendSubjectInput:GetText() or ""
	return TrimText(subjectText) == ""
end

local function MaybeAutoFillSubjectFromItemName(itemName)
	if not GM.UI or not GM.UI.sendSubjectInput or not GM.UI.sendSubjectInput.SetText then
		return
	end
	if not IsSendSubjectEmpty() then
		return
	end
	local text = TrimText(tostring(itemName or ""))
	if text == "" then
		return
	end
	GM.UI.sendSubjectInput:SetText(text)
end

local function MaybeAutoFillSubjectFromAttachments()
	if not IsSendSubjectEmpty() then
		return
	end
	MaybeAutoFillSubjectFromItemName(GetDefaultSendSubjectFromAttachments())
end

local function ClearAllSendAttachments()
	if not ClickSendMailItemButton then
		return
	end
	local maxSlots = GetSendAttachmentMaxSlots()
	for i = 1, maxSlots do
		local itemName = GetSendAttachmentInfo(i)
		if itemName then
			ClickSendMailItemButton(i, true)
		end
	end
end

local function BuildSendAttachmentItemInfoFromSlot(slotIndex)
	local index = tonumber(slotIndex)
	if not index or index < 1 then
		return nil
	end
	local itemName = GetSendAttachmentInfo(index)
	if not itemName then
		return nil
	end
	local itemLink = GetSendMailItemLink and GetSendMailItemLink(index) or nil
	local itemID = itemLink and GetItemInfoInstant and GetItemInfoInstant(itemLink) or nil
	return {
		slotIndex = index,
		itemName = tostring(itemName),
		itemLink = itemLink,
		itemID = itemID,
	}
end

local function BuildSendAttachmentMatchKey(itemInfo)
	if type(itemInfo) ~= "table" then
		return nil
	end
	local itemID = tonumber(itemInfo.itemID)
	if itemID and itemID > 0 then
		return "itemID:" .. tostring(itemID)
	end
	local name = TrimText(tostring(itemInfo.itemName or ""))
	if name ~= "" then
		return "name:" .. name:lower()
	end
	local link = tostring(itemInfo.itemLink or "")
	if link ~= "" then
		return "itemLink:" .. link
	end
	return nil
end

local function CountRealFilledSendAttachmentSlots()
	local maxSlots = GetSendAttachmentMaxSlots()
	local count = 0
	for i = 1, maxSlots do
		if GetSendAttachmentInfo(i) then
			count = count + 1
		end
	end
	return count
end

local function BuildEmptySendAttachmentSlots(maxWanted)
	local maxSlots = GetSendAttachmentMaxSlots()
	local wanted = tonumber(maxWanted) or maxSlots
	local empty = {}
	for i = 1, maxSlots do
		if not GetSendAttachmentInfo(i) then
			empty[#empty + 1] = i
			if #empty >= wanted then
				break
			end
		end
	end
	return empty
end

local function IsSendBulkAttachContextActive()
	if not GM.UI then
		return false
	end
	if GM.UI.showingDefaultUI then
		return false
	end
	if GM.UI.viewMode ~= "send" then
		return false
	end
	if not GM.UI.sendPanel or not GM.UI.sendPanel.IsShown or not GM.UI.sendPanel:IsShown() then
		return false
	end
	local sendMailFrame = _G and _G.SendMailFrame
	local inboxFrame = _G and _G.InboxFrame
	if not sendMailFrame or not sendMailFrame.IsShown or not sendMailFrame:IsShown() then
		return false
	end
	if inboxFrame and inboxFrame.IsShown and inboxFrame:IsShown() then
		return false
	end
	return true
end

ClearSendAttachmentReferenceItem = function()
	if not GM.UI then
		return
	end
	GM.UI.sendAttachmentReferenceItem = nil
end

SetSendAttachmentReferenceItemFromSlot = function(slotIndex)
	if not GM.UI then
		return nil
	end
	local info = BuildSendAttachmentItemInfoFromSlot(slotIndex)
	local matchKey = BuildSendAttachmentMatchKey(info)
	if not info or not matchKey then
		GM.UI.sendAttachmentReferenceItem = nil
		return nil
	end
	GM.UI.sendAttachmentReferenceItem = {
		slotIndex = tonumber(slotIndex),
		itemName = info.itemName,
		itemLink = info.itemLink,
		itemID = info.itemID,
		matchKey = matchKey,
	}
	return GM.UI.sendAttachmentReferenceItem
end

RefreshSendAttachmentReferenceItemFromCurrentSlots = function()
	if not GM.UI then
		return nil
	end
	local ref = GM.UI.sendAttachmentReferenceItem
	if type(ref) == "table" then
		local current = BuildSendAttachmentItemInfoFromSlot(ref.slotIndex)
		local currentKey = BuildSendAttachmentMatchKey(current)
		if current and currentKey and currentKey == ref.matchKey then
			return ref
		end
	end
	local maxSlots = GetSendAttachmentMaxSlots()
	for i = maxSlots, 1, -1 do
		local candidate = SetSendAttachmentReferenceItemFromSlot(i)
		if candidate then
			return candidate
		end
	end
	ClearSendAttachmentReferenceItem()
	return nil
end

local function GetBagSlotItemInfoSafe(bagID, slot)
	if type(bagID) ~= "number" or type(slot) ~= "number" then
		return nil
	end
	if C_Container and C_Container.GetContainerItemInfo then
		local info = C_Container.GetContainerItemInfo(bagID, slot)
		if type(info) == "table" then
			return {
				itemID = info.itemID,
				itemLink = info.hyperlink,
				itemName = info.itemName,
				stackCount = tonumber(info.stackCount) or 0,
				isLocked = info.isLocked and true or false,
			}
		end
	end
	if GetContainerItemInfo then
		local _, itemCount, isLocked, _, _, _, itemLink = GetContainerItemInfo(bagID, slot)
		local itemID = itemLink and GetItemInfoInstant and GetItemInfoInstant(itemLink) or nil
		local itemName = itemLink and GetItemInfo and GetItemInfo(itemLink) or nil
		if itemLink or itemID then
			return {
				itemID = itemID,
				itemLink = itemLink,
				itemName = itemName,
				stackCount = tonumber(itemCount) or 0,
				isLocked = isLocked and true or false,
			}
		end
	end
	return nil
end

local function CollectMatchingBagSlots(matchKey, maxWanted)
	local wanted = tonumber(maxWanted) or 0
	local out = {}
	if wanted <= 0 or not matchKey then
		return out
	end
	local maxBagID = tonumber(NUM_TOTAL_EQUIPPED_BAG_SLOTS) or tonumber(NUM_BAG_SLOTS) or 4
	for bagID = 0, math.max(0, maxBagID) do
		local slotCount = 0
		if C_Container and C_Container.GetContainerNumSlots then
			slotCount = tonumber(C_Container.GetContainerNumSlots(bagID)) or 0
		elseif GetContainerNumSlots then
			slotCount = tonumber(GetContainerNumSlots(bagID)) or 0
		end
		for slot = 1, slotCount do
			local info = GetBagSlotItemInfoSafe(bagID, slot)
			if info and (tonumber(info.stackCount) or 0) > 0 and (not info.isLocked) then
				local key = BuildSendAttachmentMatchKey(info)
				if key == matchKey then
					out[#out + 1] = { bagID = bagID, slot = slot }
					if #out >= wanted then
						return out
					end
				end
			end
		end
	end
	return out
end

local function PickupBagItemForSendAttach(bagID, slot)
	if C_Container and C_Container.PickupContainerItem then
		C_Container.PickupContainerItem(bagID, slot)
	elseif PickupContainerItem then
		PickupContainerItem(bagID, slot)
	else
		return false
	end
	return CursorHasItem and CursorHasItem() or false
end

local function StopFillSimilarRun(reason, detail)
	if not GM.UI then
		return
	end
	local stopReason = tostring(reason or "unspecified")
	if GM.UI.sendBulkAttachInProgress and GM.UI.sendBulkAttachCriticalSection then
		GM.UI.sendBulkAttachPendingStopReason = stopReason
		GM.UI.sendBulkAttachPendingStopDetail = detail
		AppendSendDebugDump("fill_similar_stop_deferred", {
			reason = stopReason,
			inCritical = true,
		})
		return
	end
	local inProgressBefore = GM.UI.sendBulkAttachInProgress and true or false
	local cursorHadItemBefore = CursorHasItem and CursorHasItem() or false
	if cursorHadItemBefore and ClearCursor then
		ClearCursor()
	end
	GM.UI.sendBulkAttachInProgress = false
	GM.UI.sendBulkAttachSignal = nil
	GM.UI.sendBulkAttachContinue = nil
	GM.UI.sendBulkAttachAwaitingAdvance = false
	GM.UI.sendBulkAttachCriticalSection = false
	GM.UI.sendBulkAttachPendingStopReason = nil
	GM.UI.sendBulkAttachPendingStopDetail = nil
	GM.UI.sendBulkAttachToken = (tonumber(GM.UI.sendBulkAttachToken) or 0) + 1
	AppendSendDebugDump("fill_similar_stop", {
		reason = stopReason,
		detail = detail and tostring(detail) or "",
		bulkInProgressBefore = inProgressBefore,
		cursorHadItemBefore = cursorHadItemBefore and true or false,
		bulkInProgressAfter = GM.UI.sendBulkAttachInProgress and true or false,
	})
end

local function StartFillSimilarRun(matchKey, maxTotal)
	if not GM.UI then
		return
	end
	local limit = math.min(GetSendAttachmentMaxSlots(), tonumber(maxTotal) or 12)
	if limit <= 0 or not matchKey then
		return
	end
	if GM.UI.sendBulkAttachInProgress then
		return
	end
	GM.UI.sendBulkAttachInProgress = true
	GM.UI.sendBulkAttachCriticalSection = false
	GM.UI.sendBulkAttachContinue = nil
	GM.UI.sendBulkAttachAwaitingAdvance = false
	GM.UI.sendBulkAttachPendingStopReason = nil
	GM.UI.sendBulkAttachPendingStopDetail = nil
	GM.UI.sendBulkAttachToken = (tonumber(GM.UI.sendBulkAttachToken) or 0) + 1
	local token = GM.UI.sendBulkAttachToken
	local state = {
		attached = 0,
		idleRounds = 0,
		maxIdleRounds = 10,
		failedSteps = 0,
		maxFailedSteps = 6,
		seenSourceSlots = {},
		stepSeq = 0,
	}

	local function BuildSourceSlotKey(bagID, slot)
		return tostring(tonumber(bagID) or -1) .. ":" .. tostring(tonumber(slot) or -1)
	end

	local function TakeNextUnseenSource(matchKeyValue)
		local candidates = CollectMatchingBagSlots(matchKeyValue, 36)
		for i = 1, #candidates do
			local candidate = candidates[i]
			local key = BuildSourceSlotKey(candidate.bagID, candidate.slot)
			if not state.seenSourceSlots[key] then
				state.seenSourceSlots[key] = true
				return candidate, key
			end
		end
		return nil, nil
	end

	local function Finish(reason)
		if not GM.UI or token ~= GM.UI.sendBulkAttachToken then
			return
		end
		StopFillSimilarRun("fill_finalize", reason)
		AppendSendDebugDump("fill_similar_finalize", {
			reason = tostring(reason or "unknown"),
			attached = state.attached,
			idleRounds = state.idleRounds,
		})
		if state.attached > 0 then
			SetStatusText("Attached " .. tostring(state.attached) .. " similar item(s)")
		end
		QueueSendAttachmentPreviewUpdate()
	end

	local function Step()
		if not GM.UI or token ~= GM.UI.sendBulkAttachToken then
			return
		end
		state.stepSeq = state.stepSeq + 1
		local stepId = state.stepSeq
		AppendSendDebugDump("fill_similar_step_enter", {
			stepId = stepId,
			token = token,
			inProgress = GM.UI.sendBulkAttachInProgress and true or false,
		})
		if not IsSendBulkAttachContextActive() then
			Finish("context")
			return
		end
		local filled = CountRealFilledSendAttachmentSlots()
		if filled >= limit then
			Finish("limit")
			return
		end
		local targetSlot = BuildEmptySendAttachmentSlots(1)[1]
		if not targetSlot then
			Finish("no_empty")
			return
		end
		if GetSendAttachmentInfo(targetSlot) then
			Finish("no_empty")
			return
		end
		local source, sourceKey = TakeNextUnseenSource(matchKey)
		if not source then
			state.idleRounds = state.idleRounds + 1
			if state.idleRounds >= state.maxIdleRounds then
				Finish("no_candidate_timeout")
				return
			end
			C_Timer.After(0.05, Step)
			return
		end
		state.idleRounds = 0
		local cursorHadItemBeforePickup = CursorHasItem and CursorHasItem() or false
		if cursorHadItemBeforePickup and ClearCursor then
			ClearCursor()
		end
		local cursorHadItemAfterPreClear = CursorHasItem and CursorHasItem() or false
		local sourceInfo = GetBagSlotItemInfoSafe(source.bagID, source.slot)
		AppendSendDebugDump("fill_similar_step_pickup", {
			stepId = stepId,
			sourceBag = source.bagID,
			sourceSlot = source.slot,
			sourceKey = sourceKey,
			targetSlot = targetSlot,
			cursorHadItemBeforePickup = cursorHadItemBeforePickup and true or false,
			cursorHadItemAfterPreClear = cursorHadItemAfterPreClear and true or false,
		})
		local pickupOk = PickupBagItemForSendAttach(source.bagID, source.slot)
		local cursorHadItemAfterPickup = CursorHasItem and CursorHasItem() or false
		AppendSendDebugDump("fill_similar_step_pickup_result", {
			stepId = stepId,
			sourceBag = source.bagID,
			sourceSlot = source.slot,
			sourceKey = sourceKey,
			targetSlot = targetSlot,
			pickupOk = pickupOk and true or false,
			cursorHadItemAfterPickup = cursorHadItemAfterPickup and true or false,
		})
		if not pickupOk then
			state.idleRounds = state.idleRounds + 1
			AppendSendDebugDump("fill_similar_step_pickup_fail", {
				stepId = stepId,
				idleRounds = state.idleRounds,
				cursorHadItemBeforePickup = cursorHadItemBeforePickup and true or false,
				cursorHadItemAfterPreClear = cursorHadItemAfterPreClear and true or false,
				cursorHadItemAfterPickup = cursorHadItemAfterPickup and true or false,
			})
			if state.idleRounds >= state.maxIdleRounds then
				Finish("pickup_failed_timeout")
				return
			end
			C_Timer.After(0.05, Step)
			return
		end

		local beforeFilled = filled
		local waitRounds = 0
		local maxWaitRounds = 10
		local resolved = false
		GM.UI.sendBulkAttachCriticalSection = true

		local function Resolve(success, reason)
			if resolved or not GM.UI or token ~= GM.UI.sendBulkAttachToken then
				return
			end
			resolved = true
			GM.UI.sendBulkAttachSignal = nil
			GM.UI.sendBulkAttachCriticalSection = false
			local cursorHadItemAfterAttachAttempt = CursorHasItem and CursorHasItem() or false
			if success then
				local afterFilled = CountRealFilledSendAttachmentSlots()
				state.attached = state.attached + math.max(0, afterFilled - beforeFilled)
				state.failedSteps = 0
				RefreshSendAttachmentReferenceItemFromCurrentSlots()
			else
				state.failedSteps = state.failedSteps + 1
			end
			if cursorHadItemAfterAttachAttempt and ClearCursor then
				ClearCursor()
			end
			local cursorHadItemAfterResolve = CursorHasItem and CursorHasItem() or false
			AppendSendDebugDump("fill_similar_resolve", {
				stepId = stepId,
				success = success and true or false,
				reason = tostring(reason or ""),
				failedSteps = state.failedSteps,
				cursorHadItemAfterAttachAttempt = cursorHadItemAfterAttachAttempt and true or false,
				cursorHadItemAfterResolve = cursorHadItemAfterResolve and true or false,
				bulkInProgressBefore = GM.UI and GM.UI.sendBulkAttachInProgress and true or false,
			})
			if GM.UI.sendBulkAttachPendingStopReason then
				local pendingReason = GM.UI.sendBulkAttachPendingStopReason
				local pendingDetail = GM.UI.sendBulkAttachPendingStopDetail
				StopFillSimilarRun("pending_stop", pendingReason)
				AppendSendDebugDump("fill_similar_pending_stop_applied", {
					stepId = stepId,
					reason = tostring(pendingReason),
					detail = pendingDetail and tostring(pendingDetail) or "",
				})
				return
			end
			if (not success) and state.failedSteps >= state.maxFailedSteps then
				Finish("attach_failed_timeout")
				return
			end
			if success then
				GM.UI.sendBulkAttachAwaitingAdvance = true
				C_Timer.After(0.15, function()
					if not GM.UI or token ~= GM.UI.sendBulkAttachToken then
						return
					end
					if GM.UI.sendBulkAttachAwaitingAdvance then
						GM.UI.sendBulkAttachAwaitingAdvance = false
						C_Timer.After(0, Step)
					end
				end)
			elseif reason == "timeout" then
				C_Timer.After(0.05, Step)
			else
				C_Timer.After(0.05, Step)
			end
		end

		local function TryConfirm(signal, forceTimeout)
			if not GM.UI or token ~= GM.UI.sendBulkAttachToken or resolved then
				return
			end
			local afterFilled = CountRealFilledSendAttachmentSlots()
			if afterFilled > beforeFilled then
				AppendSendDebugDump("fill_similar_step", {
					stepId = stepId,
					success = true,
					signal = tostring(signal or ""),
					before = beforeFilled,
					after = afterFilled,
					target = targetSlot,
					referenceItemID = GM.UI and GM.UI.sendAttachmentReferenceItem and GM.UI.sendAttachmentReferenceItem.itemID or nil,
					candidateItemID = sourceInfo and sourceInfo.itemID or nil,
					matchMode = "itemID_primary",
				})
				Resolve(true, "filled_increase")
				return
			end
			if forceTimeout then
				AppendSendDebugDump("fill_similar_step", {
					stepId = stepId,
					success = false,
					signal = tostring(signal or ""),
					before = beforeFilled,
					after = afterFilled,
					target = targetSlot,
					referenceItemID = GM.UI and GM.UI.sendAttachmentReferenceItem and GM.UI.sendAttachmentReferenceItem.itemID or nil,
					candidateItemID = sourceInfo and sourceInfo.itemID or nil,
					matchMode = "itemID_primary",
					cursorHadItemAfterAttachAttempt = CursorHasItem and CursorHasItem() and true or false,
				})
				Resolve(false, "timeout")
			end
		end

		GM.UI.sendBulkAttachSignal = function(eventName)
			TryConfirm(eventName or "event", false)
		end

		local function PollFallback()
			if not GM.UI or token ~= GM.UI.sendBulkAttachToken or resolved then
				return
			end
			waitRounds = waitRounds + 1
			TryConfirm("poll", false)
			if resolved then
				return
			end
			if waitRounds >= maxWaitRounds then
				TryConfirm("poll_timeout", true)
				return
			end
			C_Timer.After(0.05, PollFallback)
		end

		local attachCallIssued = false
		local attachCallErr = nil
		if GetSendAttachmentInfo(targetSlot) then
			if CursorHasItem and CursorHasItem() and ClearCursor then
				ClearCursor()
			end
			Resolve(false, "target_occupied_after_pickup")
			return
		end
		if ClickSendMailItemButton then
			local ok, err = pcall(ClickSendMailItemButton, targetSlot)
			attachCallIssued = ok and true or false
			attachCallErr = err
		else
			attachCallErr = "ClickSendMailItemButton_unavailable"
		end
		local cursorHadItemAfterAttachAttempt = CursorHasItem and CursorHasItem() and true or false
		AppendSendDebugDump("fill_similar_step_attach_attempt", {
			stepId = stepId,
			sourceBag = source.bagID,
			sourceSlot = source.slot,
			sourceKey = sourceKey,
			targetSlot = targetSlot,
			attachCallIssued = attachCallIssued and true or false,
			attachCallError = attachCallErr and tostring(attachCallErr) or "",
			cursorHadItemAfterPickup = cursorHadItemAfterPickup and true or false,
			cursorHadItemAfterAttachAttempt = cursorHadItemAfterAttachAttempt,
			attachRetryIssued = false,
			cursorHadItemAfterAttachRetry = cursorHadItemAfterAttachAttempt,
		})
		if (not attachCallIssued) or cursorHadItemAfterAttachAttempt then
			if CursorHasItem and CursorHasItem() and ClearCursor then
				ClearCursor()
			end
			Resolve(false, "attach_not_consumed")
			return
		end
		C_Timer.After(0.05, PollFallback)
	end
	GM.UI.sendBulkAttachContinue = Step

	AppendSendDebugDump("fill_similar_start", {
		limit = limit,
		matchKey = tostring(matchKey),
		referenceItemID = GM.UI and GM.UI.sendAttachmentReferenceItem and GM.UI.sendAttachmentReferenceItem.itemID or nil,
		matchMode = "itemID_primary",
	})
	Step()
end

HandleFillSimilarButtonClick = function()
	if not GM.UI then
		return
	end
	if CursorHasItem and CursorHasItem() then
		SetStatusText("Clear cursor first")
		return
	end
	if GM.UI.sendBulkAttachInProgress then
		return
	end
	if not IsSendBulkAttachContextActive() then
		SetStatusText("Fill Similar unavailable")
		return
	end
	local ref = RefreshSendAttachmentReferenceItemFromCurrentSlots()
	local matchKey = ref and ref.matchKey or nil
	if not matchKey then
		SetStatusText("Fill Similar unavailable")
		return
	end
	local filled = CountRealFilledSendAttachmentSlots()
	local limit = math.min(GetSendAttachmentMaxSlots(), 12)
	if filled <= 0 or filled >= limit then
		return
	end
	StartFillSimilarRun(matchKey, limit)
end

HandleClearAllButtonClick = function()
	StopFillSimilarRun("clear_all_click")
	ClearAllSendAttachments()
	ClearSendAttachmentReferenceItem()
	QueueSendAttachmentPreviewUpdate()
end

local function UpdateSendCODInputState()
	if not GM.UI then
		return
	end

	local codToggle = GM.UI.sendCODToggle
	local codInput = GM.UI.sendCODInput
	local hasAttachment = HasAnySendAttachment()

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
	if not isPending then
		if GM.UI.sendWatchdogTimer and GM.UI.sendWatchdogTimer.Cancel then
			GM.UI.sendWatchdogTimer:Cancel()
		end
		GM.UI.sendWatchdogTimer = nil
		GM.UI.sendPendingAttemptId = nil
		GM.UI.sendPendingSince = nil
	end
	if GM.UI.sendSendButton then
		GM.UI.sendSendButton:SetEnabled(not isPending)
		GM.UI.sendSendButton:SetText(isPending and "Sending..." or "Send")
	end
	if GM.UI.sendClearButton then
		GM.UI.sendClearButton:SetEnabled(not isPending)
	end
	if GM.UI.sendFillSimilarButton then
		GM.UI.sendFillSimilarButton:SetEnabled((not isPending) and (not (GM.UI and GM.UI.sendBulkAttachInProgress)))
	end
	if GM.UI.sendAttachmentClearAllButton then
		GM.UI.sendAttachmentClearAllButton:SetEnabled(not isPending)
	end
end

local function ResetSendFormState(clearAttachmentSlot)
	if not GM.UI then
		return
	end
	if clearAttachmentSlot then
		StopFillSimilarRun("reset_send_form_clear")
		ClearAllSendAttachments()
		ClearSendAttachmentReferenceItem()
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
	if not GM.UI then
		return
	end

	local slots = GM.UI.sendAttachmentSlots
	if type(slots) ~= "table" or #slots == 0 then
		return
	end

	local maxSlots = math.min(#slots, GetSendAttachmentMaxSlots())
	local filledCount = 0
	local firstItemName = nil
	local firstItemCount = 0

	for i = 1, maxSlots do
		local slot = slots[i]
		local itemName, _, itemTexture, itemCount = GetSendAttachmentInfo(i)
		local hasItem = itemName and true or false
		slot.hasItem = hasItem
		if hasItem then
			filledCount = filledCount + 1
			if not firstItemName then
				firstItemName = tostring(itemName)
				firstItemCount = tonumber(itemCount) or 1
			end
		end

		if slot.icon then
			slot.icon:SetTexture(hasItem and (itemTexture or "Interface\\Icons\\INV_Misc_QuestionMark") or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
			if hasItem then
				slot.icon:SetVertexColor(1, 1, 1, 1)
			else
				slot.icon:SetVertexColor(0.62, 0.62, 0.62, 0.75)
			end
		end
		if slot.countText then
			if hasItem and (itemCount or 1) > 1 then
				slot.countText:SetText(tostring(itemCount))
			else
				slot.countText:SetText("")
			end
		end
	end

	local layoutRows = 1
	if GM.UI.sendAttachmentApplyUsageLayout then
		layoutRows = GM.UI.sendAttachmentApplyUsageLayout(filledCount) or 1
	else
		layoutRows = math.max(1, math.min(3, math.ceil((math.max(1, filledCount)) / 4)))
	end
	local visibleCount = math.max(1, math.min(maxSlots, layoutRows * 4))
	for i = 1, maxSlots do
		local slot = slots[i]
		if slot and slot.SetShown then
			slot:SetShown(i <= visibleCount)
		end
	end

	if GM.UI.sendAttachmentNameText then
		if filledCount <= 0 then
			GM.UI.sendAttachmentNameText:SetText("No attachment")
		elseif filledCount == 1 then
			if firstItemCount > 1 then
				GM.UI.sendAttachmentNameText:SetText(firstItemName .. " x" .. tostring(firstItemCount))
			else
				GM.UI.sendAttachmentNameText:SetText(firstItemName)
			end
		else
			GM.UI.sendAttachmentNameText:SetText(tostring(filledCount) .. " attachments selected")
		end
	end

	if GM.UI.sendAttachmentLabel then
		if filledCount > 0 then
			GM.UI.sendAttachmentLabel:SetText("Attachments " .. tostring(filledCount) .. "/" .. tostring(maxSlots))
			GM.UI.sendAttachmentLabel:Show()
		else
			GM.UI.sendAttachmentLabel:SetText("")
			GM.UI.sendAttachmentLabel:Hide()
		end
	end
	if GM.UI.sendAttachHintText then
		if filledCount > 0 then
			GM.UI.sendAttachHintText:SetText("")
		else
			GM.UI.sendAttachHintText:SetText("Pick up an item, then click empty slot")
		end
	end
	local reference = nil
	if filledCount > 0 then
		reference = RefreshSendAttachmentReferenceItemFromCurrentSlots and RefreshSendAttachmentReferenceItemFromCurrentSlots() or nil
	else
		if ClearSendAttachmentReferenceItem then
			ClearSendAttachmentReferenceItem()
		end
	end
	if GM.UI.sendFillSimilarButton then
		local limit = math.min(GetSendAttachmentMaxSlots(), 12)
		local hasReference = reference and true or false
		local canRun = hasReference and filledCount < limit and (not (GM.UI and GM.UI.sendBulkAttachInProgress)) and (not (GM.UI and GM.UI.sendPending))
		GM.UI.sendFillSimilarButton:SetShown(hasReference)
		if GM.UI.sendFillSimilarButton.SetEnabled then
			GM.UI.sendFillSimilarButton:SetEnabled(canRun and true or false)
		end
	end
	if GM.UI.sendAttachmentClearAllButton then
		local hasAttachments = filledCount > 0
		GM.UI.sendAttachmentClearAllButton:SetShown(hasAttachments)
		if GM.UI.sendAttachmentClearAllButton.SetEnabled then
			GM.UI.sendAttachmentClearAllButton:SetEnabled(hasAttachments and (not (GM.UI and GM.UI.sendBulkAttachInProgress)) and (not (GM.UI and GM.UI.sendPending)))
		end
	end
	UpdateSendCODInputState()
end

local function ClickSendAttachmentSlot(slotIndex, clearIfOccupied)
	if type(slotIndex) ~= "number" or slotIndex < 1 then
		return
	end
	if not ClickSendMailItemButton then
		return
	end
	local beforeFilled = nil
	if clearIfOccupied then
		ClickSendMailItemButton(slotIndex, true)
	else
		beforeFilled = CountRealFilledSendAttachmentSlots()
		ClickSendMailItemButton(slotIndex)
	end
	QueueSendAttachmentPreviewUpdate()
	C_Timer.After(0, function()
		if clearIfOccupied then
			if RefreshSendAttachmentReferenceItemFromCurrentSlots then
				RefreshSendAttachmentReferenceItemFromCurrentSlots()
			end
			QueueSendAttachmentPreviewUpdate()
			return
		end
		local afterFilled = CountRealFilledSendAttachmentSlots()
		if type(beforeFilled) == "number" and afterFilled > beforeFilled then
			if SetSendAttachmentReferenceItemFromSlot then
				SetSendAttachmentReferenceItemFromSlot(slotIndex)
			end
		elseif RefreshSendAttachmentReferenceItemFromCurrentSlots then
			RefreshSendAttachmentReferenceItemFromCurrentSlots()
		end
		MaybeAutoFillSubjectFromAttachments()
		QueueSendAttachmentPreviewUpdate()
	end)
end

local function HandleSendAttachmentSlotClick(slot, button)
	if not slot then
		return
	end
	local slotIndex = slot.slotIndex or 1
	if button == "RightButton" then
		if slot.hasItem then
			ClickSendAttachmentSlot(slotIndex, true)
			return
		end
		if CursorHasItem and CursorHasItem() then
			ClickSendAttachmentSlot(slotIndex, false)
		end
	else
		ClickSendAttachmentSlot(slotIndex, false)
	end
end

QueueSendAttachmentPreviewUpdate = function()
	C_Timer.After(0, function()
		if UpdateSendAttachmentPreview then
			UpdateSendAttachmentPreview()
		end
	end)
end

local function TrySetNativeMailTabState(isInbox)
	local targetTab = isInbox and 1 or 2
	if not MailFrame then
		return false
	end
	if type(MailFrameTab_OnClick) == "function" then
		local ok = pcall(MailFrameTab_OnClick, nil, targetTab)
		if ok then
			return true
		end
	end
	return false
end

local function SyncNativeMailSubFramesForViewMode(isInbox)
	if not MailFrame or not MailFrame.IsShown or not MailFrame:IsShown() then
		return
	end
	local inboxFrame = _G and _G.InboxFrame
	local sendMailFrame = _G and _G.SendMailFrame
	if not inboxFrame or not sendMailFrame then
		return
	end

	TrySetNativeMailTabState(isInbox)

	if isInbox then
		if sendMailFrame.Hide then
			sendMailFrame:Hide()
		end
		if inboxFrame.Show then
			inboxFrame:Show()
		end
	else
		if inboxFrame.Hide then
			inboxFrame:Hide()
		end
		if sendMailFrame.Show then
			sendMailFrame:Show()
		end
	end
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
		if gold > 0 then
			row.moneySilverText:SetText(string.format("%02d", silver))
		elseif silver > 0 then
			row.moneySilverText:SetText(tostring(silver))
		else
			row.moneySilverText:SetText("")
		end
	end
	if row.moneyCopperText then
		if not hasMoney then
			row.moneyCopperText:SetText("")
		elseif gold > 0 or silver > 0 then
			row.moneyCopperText:SetText(string.format("%02d", copperOnly))
		else
			row.moneyCopperText:SetText(tostring(copperOnly))
		end
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
	if row.moneyGoldText then
		row.moneyGoldText:SetAlpha(goldAlpha)
	end
	if row.moneySilverText then
		row.moneySilverText:SetAlpha(silverAlpha)
	end
	if row.moneyCopperText then
		row.moneyCopperText:SetAlpha(copperAlpha)
	end
	if row.moneyBg then
		local bgColor = hasMoney and TintColor(THEME.surfaceBg, 0.04, 0.98) or TintColor(THEME.surfaceBg, 0.01, 0.96)
		row.moneyBg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], hasMoney and 0.24 or 0.16)
	end
end

local function UpdateRowStateCell(row, stateKind)
	if not row or not row.stateBadgeBg or not row.stateBadgeBorder then
		return
	end
	local stateColor
	local bgAlpha = 0.14
	local borderAlpha = 0.34
	if stateKind == "collect" then
		stateColor = (THEME_TOKENS.state and THEME_TOKENS.state.success) or THEME_STATUS.ok
		bgAlpha = 0.16
		borderAlpha = 0.38
	elseif stateKind == "delete" then
		stateColor = (THEME_TOKENS.state and THEME_TOKENS.state.info) or THEME_TEXT.inboxCount
	else
		stateColor = (THEME_TOKENS.state and THEME_TOKENS.state.danger) or THEME_STATUS.blocked
	end
	row.stateBadgeBg:SetColorTexture(stateColor[1], stateColor[2], stateColor[3], bgAlpha)
	row.stateBadgeBorder:SetColorTexture(stateColor[1], stateColor[2], stateColor[3], borderAlpha)
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
	if not GM.UI.showingDefaultUI then
		SyncNativeMailSubFramesForViewMode(isInbox)
	end
	if not isInbox then
		SetDetailPanelOpen(false)
		if UpdateSendAttachmentPreview then
			UpdateSendAttachmentPreview()
		end
	end

	if GM.UI.modeInboxButton then
		StyleTabButton(GM.UI.modeInboxButton, isInbox)
	end
	if GM.UI.modeSendButton then
		StyleTabButton(GM.UI.modeSendButton, not isInbox)
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
		local actionKind, actionText, actionEnabled = ResolveRowPrimaryAction(row)
		if collectorBusy then
			actionEnabled = false
		end
		GM.UI.detailCollectButton:SetShown(actionKind ~= "none")
		GM.UI.detailCollectButton:SetText(actionText)
		GM.UI.detailCollectButton:SetEnabled(actionEnabled)
		GM.UI.detailCollectButton.actionKind = actionKind
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
			local actionKind, actionText, actionEnabled = ResolveRowPrimaryAction(data)
			local collectState = "OK"
			if actionKind == "delete" then
				collectState = "DEL"
			elseif actionKind ~= "collect" then
				collectState = (data.blockedReason == "COD") and "COD" or "EMP"
			end
			row.item:SetText(itemFlag)
			row.state:SetText(collectState)
			row.actionKind = actionKind
			row.collectButton:SetShown(actionKind ~= "none")
			row.collectButton:SetEnabled(actionEnabled)
			row.collectButton:SetText(actionText)
					if data.wasRead then
						row.sender:SetTextColor(unpack((THEME_TOKENS.text and THEME_TOKENS.text.muted) or THEME_TEXT.rowRead))
						row.subject:SetTextColor(unpack((THEME_TOKENS.text and THEME_TOKENS.text.muted) or THEME_TEXT.rowRead))
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
				if actionKind == "collect" then
					row.state:SetTextColor(unpack((THEME_TOKENS.state and THEME_TOKENS.state.success) or THEME_STATUS.ok))
				elseif actionKind == "delete" then
					row.state:SetTextColor(unpack((THEME_TOKENS.state and THEME_TOKENS.state.info) or THEME_TEXT.inboxCount))
				else
					row.state:SetTextColor(unpack((THEME_TOKENS.state and THEME_TOKENS.state.danger) or THEME_STATUS.blocked))
				end
				UpdateRowStateCell(row, actionKind == "none" and "blocked" or actionKind)
				ApplyRowBackground(row, data.wasRead and true or false, GM.UI.selectedMailIndex and GM.UI.selectedMailIndex == data.index, (i % 2 == 0))
				row:Show()
			visibleCount = visibleCount + 1
		else
			row.mailIndex = nil
			row.isRead = true
			row.actionKind = "none"
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
	GM.Collector.Start(rows, "single")
	RenderInboxRows()
end

local function StartDeleteForSingleMail(mailIndex)
	if not mailIndex then
		SetStatusText("Select a mail row first")
		return
	end
	if not DeleteInboxItem then
		SetStatusText("Delete unavailable")
		return
	end
	local rows = {}
	if GM.Mailbox and GM.Mailbox.GetRows then
		rows = GM.Mailbox.GetRows() or {}
	end
	local selectedRow = FindRowByMailIndex(rows, mailIndex)
	if not selectedRow then
		SetStatusText("Selected mail no longer available")
		return
	end
	if not selectedRow.canDelete then
		SetStatusText("Delete not allowed")
		return
	end
	local collectorState = GM.Collector and GM.Collector.GetState and GM.Collector.GetState() or "idle"
	if collectorState == "collecting" or collectorState == "waitingRefresh" then
		SetStatusText("Collector already running")
		return
	end
	DeleteInboxItem(mailIndex)
	SetStatusText("Deleting mail...")
	if CheckInbox then
		CheckInbox()
	end
	C_Timer.After(0, function()
		if GM.Mailbox and GM.Mailbox.ScanInbox then
			GM.Mailbox.ScanInbox()
		end
	end)
end

ResolveRowPrimaryAction = function(row)
	if not row then
		return "none", "NA", false
	end
	if row.canCollect then
		return "collect", "Get", true
	end
	if row.canDelete then
		return "delete", "Del", true
	end
	return "none", "NA", false
end

local function StartPrimaryActionForMail(mailIndex, actionKind)
	if actionKind == "collect" then
		StartCollectForSingleMail(mailIndex)
		return
	end
	if actionKind == "delete" then
		StartDeleteForSingleMail(mailIndex)
		return
	end
	SetStatusText("No action available")
end

ApplyRowBackground = function(row, isRead, isSelected, isEven, isHover)
	if not row or not row.bg then
		return
	end
	local baseColor
	local railColor
	local dividerAlpha
	local actionAlpha
	if isHover and not isSelected then
		baseColor = (THEME_TOKENS.rows and THEME_TOKENS.rows.hover) or THEME.rowHoverBg
		railColor = TintColor(baseColor, 0.16, 0.95)
		dividerAlpha = 0.26
		actionAlpha = 0.34
	elseif isSelected then
		baseColor = (THEME_TOKENS.rows and THEME_TOKENS.rows.selected) or THEME.rowSelectedBg
		railColor = TintColor(baseColor, 0.22, 0.98)
		dividerAlpha = 0.30
		actionAlpha = 0.40
	elseif not isRead then
		if isEven then
			baseColor = THEME.rowUnreadEvenBg
		else
			baseColor = THEME.rowUnreadOddBg
		end
		railColor = THEME.unreadDotUnread
		dividerAlpha = 0.22
		actionAlpha = 0.30
	else
		if isEven then
			baseColor = THEME.rowEvenBg
		else
			baseColor = THEME.rowOddBg
		end
		railColor = THEME.unreadDotRead
		dividerAlpha = 0.18
		actionAlpha = 0.22
	end
	row.bg:SetColorTexture(unpack(baseColor))
	if row.leftRail then
		row.leftRail:SetColorTexture(unpack(railColor))
	end
	if row.rowDivider then
		row.rowDivider:SetColorTexture(THEME.scrollDivider[1], THEME.scrollDivider[2], THEME.scrollDivider[3], dividerAlpha)
	end
	if row.actionCellBg then
		local actionColor = TintColor(baseColor, 0.05, 0.96)
		row.actionCellBg:SetColorTexture(actionColor[1], actionColor[2], actionColor[3], actionAlpha)
	end
	if isSelected then
		return
	end
	if not isRead then
		return
	end
end

ApplyHeaderBandStyle = function()
	if not GM.UI or not GM.UI.header then
		return
	end
	local header = GM.UI.header
	if GM.UI.headerBg then
		GM.UI.headerBg:SetColorTexture(unpack(THEME.headerBg))
	end
	if not GM.UI.headerFill then
		local fill = header:CreateTexture(nil, "ARTWORK")
		fill:SetTexture("Interface\\Buttons\\WHITE8x8")
		fill:SetPoint("TOPLEFT", header, "TOPLEFT", 1, -1)
		fill:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -1, 1)
		GM.UI.headerFill = fill
	end
	if not GM.UI.headerTopLine then
		local topLine = header:CreateTexture(nil, "ARTWORK")
		topLine:SetTexture("Interface\\Buttons\\WHITE8x8")
		topLine:SetPoint("TOPLEFT", header, "TOPLEFT", 1, -1)
		topLine:SetPoint("TOPRIGHT", header, "TOPRIGHT", -1, -1)
		topLine:SetHeight(1)
		GM.UI.headerTopLine = topLine
	end
	if not GM.UI.headerBottomLine then
		local bottomLine = header:CreateTexture(nil, "ARTWORK")
		bottomLine:SetTexture("Interface\\Buttons\\WHITE8x8")
		bottomLine:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 1, 1)
		bottomLine:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -1, 1)
		bottomLine:SetHeight(1)
			GM.UI.headerBottomLine = bottomLine
	end
	if not GM.UI.headerBottomAccent then
		local accent = header:CreateTexture(nil, "OVERLAY")
		accent:SetTexture("Interface\\Buttons\\WHITE8x8")
		accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 1, 1)
		accent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", -1, 1)
		accent:SetHeight(1)
		GM.UI.headerBottomAccent = accent
	end
	GM.UI.headerFill:SetColorTexture(unpack(TintColor(THEME.headerBg, 0.04, 0.95)))
	GM.UI.headerTopLine:SetColorTexture(unpack(TintColor(THEME.listBorder, 0.50, 0.68)))
	GM.UI.headerBottomLine:SetColorTexture(unpack(ShadeColor(THEME.listBorder, 0.30, 0.82)))
	GM.UI.headerBottomAccent:SetColorTexture(unpack(TintColor((THEME_TOKENS and THEME_TOKENS.accent) or THEME.accent, 0.08, 0.42)))
end

local function CreateHeaderCell(parent, text, width, xOffset, justify)
	local cell = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	cell:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, -5)
	cell:SetWidth(width)
	cell:SetJustifyH(justify or "LEFT")
	cell:SetWordWrap(false)
	cell:SetText(text)
	cell:SetTextColor(unpack((THEME_TOKENS.text and THEME_TOKENS.text.header) or THEME_TEXT.header))
	cell:SetShadowColor(0, 0, 0, 0.75)
	cell:SetShadowOffset(1, -1)
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
	row.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
	row.bg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
	row.bg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)
	ApplyRowBackground(row, true, false, (index % 2 == 0))
	row.isRead = true

	row.leftRail = row:CreateTexture(nil, "ARTWORK")
	row.leftRail:SetTexture("Interface\\Buttons\\WHITE8x8")
	row.leftRail:SetPoint("LEFT", row, "LEFT", 0, 0)
	row.leftRail:SetWidth(2)
	row.leftRail:SetPoint("TOP", row, "TOP", 0, -2)
	row.leftRail:SetPoint("BOTTOM", row, "BOTTOM", 0, 2)

	row.rowDivider = row:CreateTexture(nil, "BORDER")
	row.rowDivider:SetTexture("Interface\\Buttons\\WHITE8x8")
	row.rowDivider:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
	row.rowDivider:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
	row.rowDivider:SetHeight(1)

	row.unreadDot = row:CreateTexture(nil, "OVERLAY")
	row.unreadDot:SetSize(5, 5)
	row.unreadDot:SetPoint("LEFT", row, "LEFT", 7, 0)
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
			ApplyRowBackground(self, self.isRead, false, (index % 2 == 0), true)
		end
	end)
	row:SetScript("OnLeave", function(self)
		if GM.UI.selectedMailIndex ~= self.mailIndex then
			ApplyRowBackground(self, self.isRead, false, (index % 2 == 0))
		end
	end)

	row.sender = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.sender:SetPoint("LEFT", row, "LEFT", 12, 0)
	row.sender:SetWidth(COL_SENDER)
	row.sender:SetJustifyH("LEFT")
	row.sender:SetWordWrap(false)
	row.sender:SetShadowColor(0, 0, 0, 0.65)
	row.sender:SetShadowOffset(1, -1)

	row.subject = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.subject:SetPoint("LEFT", row.sender, "RIGHT", COL_GAP - 2, 0)
	row.subject:SetWidth(COL_SUBJECT)
	row.subject:SetJustifyH("LEFT")
	row.subject:SetWordWrap(false)
	row.subject:SetShadowColor(0, 0, 0, 0.75)
	row.subject:SetShadowOffset(1, -1)

	row.money = CreateFrame("Frame", nil, row)
	row.money:SetPoint("LEFT", row.subject, "RIGHT", COL_SUBJECT_MONEY_GAP, 0)
	row.money:SetSize(COL_MONEY, ROW_HEIGHT)
	row.moneyBg = row.money:CreateTexture(nil, "BACKGROUND")
	row.moneyBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	row.moneyBg:SetPoint("TOPLEFT", row.money, "TOPLEFT", 0, -2)
	row.moneyBg:SetPoint("BOTTOMRIGHT", row.money, "BOTTOMRIGHT", 0, 2)

	row.moneyCopperIcon = row.money:CreateTexture(nil, "OVERLAY")
	row.moneyCopperSegment = CreateFrame("Frame", nil, row.money)
	row.moneyCopperSegment:SetSize(28, ROW_HEIGHT)
	row.moneyCopperSegment:SetPoint("RIGHT", row.money, "RIGHT", -2, 0)

	row.moneyCopperIcon:SetSize(8, 8)
	row.moneyCopperIcon:SetPoint("RIGHT", row.moneyCopperSegment, "RIGHT", 0, 0)
	row.moneyCopperIcon:SetTexture("Interface\\MoneyFrame\\UI-CopperIcon")

	row.moneyCopperText = row.moneyCopperSegment:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.moneyCopperText:SetPoint("LEFT", row.moneyCopperSegment, "LEFT", 0, 0)
	row.moneyCopperText:SetPoint("RIGHT", row.moneyCopperIcon, "LEFT", -1, 0)
	row.moneyCopperText:SetJustifyH("RIGHT")
	row.moneyCopperText:SetWordWrap(false)
	row.moneyCopperText:SetShadowColor(0, 0, 0, 0.65)
	row.moneyCopperText:SetShadowOffset(1, -1)

	row.moneySilverSegment = CreateFrame("Frame", nil, row.money)
	row.moneySilverSegment:SetSize(28, ROW_HEIGHT)
	row.moneySilverSegment:SetPoint("RIGHT", row.moneyCopperSegment, "LEFT", -2, 0)

	row.moneySilverIcon = row.money:CreateTexture(nil, "OVERLAY")
	row.moneySilverIcon:SetSize(8, 8)
	row.moneySilverIcon:SetPoint("RIGHT", row.moneySilverSegment, "RIGHT", 0, 0)
	row.moneySilverIcon:SetTexture("Interface\\MoneyFrame\\UI-SilverIcon")

	row.moneySilverText = row.moneySilverSegment:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.moneySilverText:SetPoint("LEFT", row.moneySilverSegment, "LEFT", 0, 0)
	row.moneySilverText:SetPoint("RIGHT", row.moneySilverIcon, "LEFT", -1, 0)
	row.moneySilverText:SetJustifyH("RIGHT")
	row.moneySilverText:SetWordWrap(false)
	row.moneySilverText:SetShadowColor(0, 0, 0, 0.65)
	row.moneySilverText:SetShadowOffset(1, -1)

	row.moneyGoldIcon = row.money:CreateTexture(nil, "OVERLAY")
	row.moneyGoldIcon:SetSize(8, 8)
	row.moneyGoldIcon:SetPoint("RIGHT", row.moneySilverSegment, "LEFT", -2, 0)
	row.moneyGoldIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")

	row.moneyGoldText = row.money:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.moneyGoldText:SetPoint("LEFT", row.money, "LEFT", 4, 0)
	row.moneyGoldText:SetPoint("RIGHT", row.moneyGoldIcon, "LEFT", -1, 0)
	row.moneyGoldText:SetJustifyH("RIGHT")
	row.moneyGoldText:SetWordWrap(false)
	row.moneyGoldText:SetShadowColor(0, 0, 0, 0.65)
	row.moneyGoldText:SetShadowOffset(1, -1)

	row.moneyDashText = row.money:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.moneyDashText:SetPoint("CENTER", row.money, "CENTER", 0, 0)
	row.moneyDashText:SetText("")
	row.moneyDashText:SetWordWrap(false)
	row.moneyDashText:SetShadowColor(0, 0, 0, 0.65)
	row.moneyDashText:SetShadowOffset(1, -1)

	UpdateRowMoneyCell(row, 0)

	row.cod = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.cod:SetPoint("LEFT", row.money, "RIGHT", COL_GAP, 0)
	row.cod:SetWidth(COL_COD)
	row.cod:SetJustifyH("CENTER")

	row.item = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.item:SetPoint("LEFT", row.cod, "RIGHT", COL_GAP, 0)
	row.item:SetWidth(COL_ITEM)
	row.item:SetJustifyH("CENTER")

	row.stateBadge = CreateFrame("Frame", nil, row)
	row.stateBadge:SetPoint("LEFT", row.item, "RIGHT", COL_GAP, 0)
	row.stateBadge:SetSize(COL_STATE, 16)
	row.stateBadgeBg = row.stateBadge:CreateTexture(nil, "BACKGROUND")
	row.stateBadgeBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	row.stateBadgeBg:SetPoint("TOPLEFT", row.stateBadge, "TOPLEFT", 1, -1)
	row.stateBadgeBg:SetPoint("BOTTOMRIGHT", row.stateBadge, "BOTTOMRIGHT", -1, 1)
	row.stateBadgeBorder = row.stateBadge:CreateTexture(nil, "BORDER")
	row.stateBadgeBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
	row.stateBadgeBorder:SetPoint("TOPLEFT", row.stateBadge, "TOPLEFT", 0, 0)
	row.stateBadgeBorder:SetPoint("BOTTOMRIGHT", row.stateBadge, "BOTTOMRIGHT", 0, 0)
	row.state = row.stateBadge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	row.state:SetPoint("CENTER", row.stateBadge, "CENTER", 0, 0)
	row.state:SetJustifyH("CENTER")
	row.state:SetWordWrap(false)
	row.state:SetShadowColor(0, 0, 0, 0.70)
	row.state:SetShadowOffset(1, -1)
	UpdateRowStateCell(row, "blocked")

	row.actionCell = CreateFrame("Frame", nil, row)
	row.actionCell:SetPoint("LEFT", row.stateBadge, "RIGHT", COL_GAP, 0)
	row.actionCell:SetSize(COL_ACTION, ROW_HEIGHT)
	row.actionCellBg = row.actionCell:CreateTexture(nil, "BACKGROUND")
	row.actionCellBg:SetTexture("Interface\\Buttons\\WHITE8x8")
	row.actionCellBg:SetPoint("TOPLEFT", row.actionCell, "TOPLEFT", 0, -1)
	row.actionCellBg:SetPoint("BOTTOMRIGHT", row.actionCell, "BOTTOMRIGHT", 0, 1)

	row.collectButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
	row.collectButton:SetSize(COL_ACTION - 2, 19)
	row.collectButton:SetPoint("CENTER", row.actionCell, "CENTER", 0, 0)
	row.collectButton:SetHitRectInsets(-1, -1, -1, -1)
	row.collectButton:SetText("Get")
	row.actionKind = "none"
	row.collectButton:SetScript("OnClick", function()
		StartPrimaryActionForMail(row.mailIndex, row.actionKind)
	end)
	StyleRowActionButton(row.collectButton)

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

local function BuildSendRecipientSubjectRow(sendPanel, labelToFieldGap)
	local rowTopInset = 10
	local rowHeight = 42
	local fieldGap = 12
	local labelHeight = 12
	local labelToInputGap = 2
	local inputShellHeight = 20
	local contentTopInset = 0
	local topRow = CreateFrame("Frame", nil, sendPanel)
	topRow:SetPoint("TOPLEFT", sendPanel, "TOPLEFT", 12, -rowTopInset)
	topRow:SetPoint("TOPRIGHT", sendPanel, "TOPRIGHT", -12, -rowTopInset)
	topRow:SetHeight(rowHeight)
	GM.UI.sendTopFormRow = topRow
	local function BuildSendInputShell(parent, pointA, relA, relPointA, xA, yA, pointB, relB, relPointB, xB, yB)
		local shell = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		shell:SetPoint(pointA, relA, relPointA, xA, yA)
		shell:SetPoint(pointB, relB, relPointB, xB, yB)
		shell:SetHeight(inputShellHeight)
		shell:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 7,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		ApplyPanelSurfaceStyle(shell, THEME.detailBodyBg, THEME.detailBodyBorder, THEME.title)
		return shell
	end

	local sendRecipientLabel = topRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendRecipientLabel:SetPoint("TOPLEFT", topRow, "TOPLEFT", 0, -contentTopInset)
	sendRecipientLabel:SetHeight(labelHeight)
	sendRecipientLabel:SetJustifyH("LEFT")
	sendRecipientLabel:SetText("Recipient")
	GM.UI.sendRecipientLabel = sendRecipientLabel

	local sendRecipientField = BuildSendInputShell(topRow, "TOPLEFT", topRow, "TOPLEFT", 0, -(contentTopInset + labelHeight + labelToInputGap), "TOPRIGHT", topRow, "TOP", -(fieldGap / 2), -(contentTopInset + labelHeight + labelToInputGap))
	GM.UI.sendRecipientField = sendRecipientField

	local sendRecipientInput = CreateFrame("EditBox", nil, sendRecipientField, "InputBoxTemplate")
	sendRecipientInput:SetAutoFocus(false)
	sendRecipientInput:SetHeight(20)
	sendRecipientInput:SetPoint("TOPLEFT", sendRecipientField, "TOPLEFT", 6, -1)
	sendRecipientInput:SetPoint("TOPRIGHT", sendRecipientField, "TOPRIGHT", -6, -1)
	sendRecipientInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	sendRecipientInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		if GM.UI and GM.UI.sendSubjectInput then
			GM.UI.sendSubjectInput:SetFocus()
		end
	end)
	TryEnableMailRecipientAutoComplete(sendRecipientInput)
	GM.UI.sendRecipientInput = sendRecipientInput

	local sendSubjectLabel = topRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendSubjectLabel:SetPoint("TOPLEFT", topRow, "TOP", (fieldGap / 2), -contentTopInset)
	sendSubjectLabel:SetHeight(labelHeight)
	sendSubjectLabel:SetJustifyH("LEFT")
	sendSubjectLabel:SetText("Subject")
	GM.UI.sendSubjectLabel = sendSubjectLabel

	local sendSubjectField = BuildSendInputShell(topRow, "TOPLEFT", topRow, "TOP", (fieldGap / 2), -(contentTopInset + labelHeight + labelToInputGap), "TOPRIGHT", topRow, "TOPRIGHT", 0, -(contentTopInset + labelHeight + labelToInputGap))
	GM.UI.sendSubjectField = sendSubjectField

	local sendSubjectInput = CreateFrame("EditBox", nil, sendSubjectField, "InputBoxTemplate")
	sendSubjectInput:SetAutoFocus(false)
	sendSubjectInput:SetHeight(20)
	sendSubjectInput:SetPoint("TOPLEFT", sendSubjectField, "TOPLEFT", 6, -1)
	sendSubjectInput:SetPoint("TOPRIGHT", sendSubjectField, "TOPRIGHT", -6, -1)
	sendSubjectInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	sendSubjectInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	GM.UI.sendSubjectInput = sendSubjectInput

	return sendRecipientInput, sendSubjectInput
end

local function BuildSendAttachmentEventFrame(sendPanel)
	local sendAttachmentEventFrame = CreateFrame("Frame", nil, sendPanel)
	sendAttachmentEventFrame:RegisterEvent("MAIL_SEND_INFO_UPDATE")
	sendAttachmentEventFrame:RegisterEvent("MAIL_SEND_SUCCESS")
	sendAttachmentEventFrame:RegisterEvent("MAIL_FAILED")
	sendAttachmentEventFrame:RegisterEvent("UI_ERROR_MESSAGE")
	sendAttachmentEventFrame:RegisterEvent("ADDON_ACTION_BLOCKED")
	sendAttachmentEventFrame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
	sendAttachmentEventFrame:RegisterEvent("MAIL_CLOSED")
	sendAttachmentEventFrame:SetScript("OnEvent", function(_, event, ...)
		local currentAttempt = GM.UI and GM.UI.sendPendingAttemptId or nil
		AppendSendDebugDump("event", {
			event = event,
			attemptId = currentAttempt,
			sendPending = GM.UI and GM.UI.sendPending or false,
		})
		if event == "MAIL_SEND_INFO_UPDATE" then
			local signal = GM.UI and GM.UI.sendBulkAttachSignal or nil
			if type(signal) == "function" then
				signal(event)
			end
			if GM.UI and GM.UI.sendBulkAttachInProgress and GM.UI.sendBulkAttachAwaitingAdvance then
				local continueStep = GM.UI.sendBulkAttachContinue
				if type(continueStep) == "function" then
					GM.UI.sendBulkAttachAwaitingAdvance = false
					C_Timer.After(0.03, continueStep)
				end
			end
			MaybeAutoFillSubjectFromAttachments()
			QueueSendAttachmentPreviewUpdate()
		end
		if event == "MAIL_CLOSED" then
			StopFillSimilarRun("mail_closed")
			SetSendPendingState(false)
			if UpdateSendAttachmentPreview then
				UpdateSendAttachmentPreview()
			end
			return
		end
		if event == "MAIL_SEND_SUCCESS" then
			StopFillSimilarRun("mail_send_success")
			if GM.UI and GM.UI.sendPending then
				SetSendPendingState(false)
				ResetSendFormState(false)
				SetStatusText("Mail sent")
			end
			if UpdateSendAttachmentPreview then
				UpdateSendAttachmentPreview()
			end
			return
		end
		if event == "MAIL_FAILED" then
			StopFillSimilarRun("mail_failed")
			if GM.UI and GM.UI.sendPending then
				SetSendPendingState(false)
				SetStatusText("Send failed")
			end
			if UpdateSendAttachmentPreview then
				UpdateSendAttachmentPreview()
			end
			return
		end
		if event == "UI_ERROR_MESSAGE" then
			if GM.UI and GM.UI.sendPending then
				local arg1, arg2 = ...
				local uiErrorText = nil
				if type(arg2) == "string" and arg2 ~= "" then
					uiErrorText = arg2
				elseif type(arg1) == "string" and arg1 ~= "" then
					uiErrorText = arg1
				end
				AppendSendDebugDump("ui_error", {
					attemptId = currentAttempt,
					message = uiErrorText or "",
				})
				if IsLikelySendUIError(uiErrorText) then
					SetSendPendingState(false)
					if uiErrorText then
						SetStatusText("Send failed: " .. uiErrorText)
					else
						SetStatusText("Send failed")
					end
				end
			end
			return
		end
		if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
			if GM.UI and GM.UI.sendPending then
				local blockedAddonName = ...
				AppendSendDebugDump("blocked", {
					attemptId = currentAttempt,
					event = event,
					addon = blockedAddonName or "",
				})
				if blockedAddonName == addonName then
					SetSendPendingState(false)
					SetStatusText("Send blocked (taint)")
				end
			end
			return
		end
		if UpdateSendAttachmentPreview then
			UpdateSendAttachmentPreview()
		end
	end)
	GM.UI.sendAttachmentEventFrame = sendAttachmentEventFrame
end

local function BuildSendAttachmentAndPaymentRow(sendPanel, sendRecipientInput, sendSubjectInput, fieldTopGap)
	local utilityGap = 12
	local cardHeight = 116
	local rowTopGap = 0
	local slotColumns = 4
	local slotSize = 34
	local slotGap = 4
	local attachmentPadLeft = 10
	local attachmentPadRight = 10
	local attachmentPadTop = 10
	local attachmentPadBottom = 10
	local paymentPadLeft = 12
	local paymentPadRight = 12
	local paymentPadTop = 10
	local paymentPadBottom = 10
	local paymentLabelWidth = 52
	local paymentInputStart = paymentLabelWidth + 6
	local paymentRowGap = 8

	local sendGoldLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendGoldLabel:SetText("Gold")
	GM.UI.sendGoldLabel = sendGoldLabel

	local sendGoldInput = CreateFrame("EditBox", nil, sendPanel, "InputBoxTemplate")
	sendGoldInput:SetAutoFocus(false)
	sendGoldInput:SetHeight(20)
	sendGoldInput:SetNumeric(false)
	sendGoldInput:SetWidth(74)
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

	local sendUtilityRow = CreateFrame("Frame", nil, sendPanel)
	sendUtilityRow:SetPoint("TOPLEFT", GM.UI.sendTopFormRow or GM.UI.sendRecipientField or sendRecipientInput, "BOTTOMLEFT", 0, -rowTopGap)
	sendUtilityRow:SetPoint("TOPRIGHT", GM.UI.sendTopFormRow or GM.UI.sendSubjectField or sendSubjectInput, "BOTTOMRIGHT", 0, -rowTopGap)
	sendUtilityRow:SetHeight(cardHeight)

	local sendAttachmentControls = CreateFrame("Frame", nil, sendUtilityRow, "BackdropTemplate")
	sendAttachmentControls:SetHeight(cardHeight)
	sendAttachmentControls:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 6,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	ApplyPanelSurfaceStyle(sendAttachmentControls, THEME.surfaceBg, THEME.surfaceBorder, THEME.title)
	GM.UI.sendAttachmentControls = sendAttachmentControls

	local sendAttachmentGroup = CreateFrame("Frame", nil, sendUtilityRow, "BackdropTemplate")
	sendAttachmentGroup:SetHeight(cardHeight)
	sendAttachmentGroup:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	ApplyPanelSurfaceStyle(sendAttachmentGroup, THEME.detailBodyBg, THEME.detailBodyBorder, THEME.title)
	GM.UI.sendAttachmentGroup = sendAttachmentGroup

	local function ApplyUtilityCardSplit()
		local totalWidth = sendUtilityRow:GetWidth() or 0
		if totalWidth <= utilityGap then
			return
		end
		local leftWidth = math.floor(((totalWidth - utilityGap) * 0.60) + 0.5)
		local rightWidth = (totalWidth - utilityGap) - leftWidth

		sendAttachmentGroup:ClearAllPoints()
		sendAttachmentGroup:SetPoint("TOPLEFT", sendUtilityRow, "TOPLEFT", 0, 0)
		sendAttachmentGroup:SetWidth(leftWidth)
		sendAttachmentGroup:SetHeight(cardHeight)

		sendAttachmentControls:ClearAllPoints()
		sendAttachmentControls:SetPoint("TOPLEFT", sendAttachmentGroup, "TOPRIGHT", utilityGap, 0)
		sendAttachmentControls:SetWidth(rightWidth)
		sendAttachmentControls:SetHeight(cardHeight)
	end
	sendUtilityRow:SetScript("OnSizeChanged", ApplyUtilityCardSplit)
	ApplyUtilityCardSplit()

	local sendAttachmentTitle = sendAttachmentGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendAttachmentTitle:SetPoint("TOPLEFT", sendAttachmentGroup, "TOPLEFT", attachmentPadLeft, -attachmentPadTop)
	sendAttachmentTitle:SetText("Attachments")
	GM.UI.sendAttachmentTitle = sendAttachmentTitle

	local sendFillSimilarButton = CreateFrame("Button", nil, sendAttachmentGroup, "UIPanelButtonTemplate")
	sendFillSimilarButton:SetSize(84, 18)
	sendFillSimilarButton:SetPoint("TOPRIGHT", sendAttachmentGroup, "TOPRIGHT", -attachmentPadRight, -(attachmentPadTop - 1))
	sendFillSimilarButton:SetText("Fill Similar")
	sendFillSimilarButton:SetScript("OnClick", function()
		HandleFillSimilarButtonClick()
	end)
	StyleGeneralButton(sendFillSimilarButton, "secondary")
	sendFillSimilarButton:Hide()
	GM.UI.sendFillSimilarButton = sendFillSimilarButton

	local sendAttachmentClearAllButton = CreateFrame("Button", nil, sendAttachmentGroup, "UIPanelButtonTemplate")
	sendAttachmentClearAllButton:SetSize(84, 18)
	sendAttachmentClearAllButton:SetPoint("TOPRIGHT", sendFillSimilarButton, "BOTTOMRIGHT", 0, -3)
	sendAttachmentClearAllButton:SetText("Clear All")
	sendAttachmentClearAllButton:SetScript("OnClick", function()
		HandleClearAllButtonClick()
	end)
	StyleGeneralButton(sendAttachmentClearAllButton, "secondary")
	sendAttachmentClearAllButton:Hide()
	GM.UI.sendAttachmentClearAllButton = sendAttachmentClearAllButton

	sendAttachmentLabel:SetParent(sendAttachmentGroup)
	sendAttachmentLabel:ClearAllPoints()
	sendAttachmentLabel:SetPoint("RIGHT", sendFillSimilarButton, "LEFT", -6, 0)

	local sendPaymentTitle = sendAttachmentControls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendPaymentTitle:SetPoint("TOPLEFT", sendAttachmentControls, "TOPLEFT", paymentPadLeft, -paymentPadTop)
	sendPaymentTitle:SetText("Payment")
	GM.UI.sendPaymentTitle = sendPaymentTitle

	local slotMax = GetSendAttachmentMaxSlots()
	local slotRowsVisible = math.max(1, math.ceil(slotMax / slotColumns))
	local slotRowsActive = 1

	local slotAnchor = CreateFrame("Frame", nil, sendAttachmentGroup)
	slotAnchor:SetPoint("TOPLEFT", sendAttachmentTitle, "BOTTOMLEFT", 0, -3)
	slotAnchor:SetPoint("TOPRIGHT", sendAttachmentGroup, "TOPRIGHT", -attachmentPadRight, -(attachmentPadTop + 39))
	slotAnchor:SetHeight((slotRowsVisible * slotSize) + ((slotRowsVisible - 1) * slotGap))

	local slots = {}
	local function ApplyAttachmentSlotGridLayout()
		local anchorWidth = slotAnchor:GetWidth() or 0
		if anchorWidth <= 0 then
			return
		end
		local desiredGap = 4
		local maxGap = 7
		local minSlotSize = 28
		local maxSlotSize = 40
		local resolvedGap = desiredGap
		local resolvedSize = math.floor((anchorWidth - ((slotColumns - 1) * resolvedGap)) / slotColumns)
		resolvedSize = math.max(minSlotSize, math.min(maxSlotSize, resolvedSize))
		local usedWidth = (resolvedSize * slotColumns) + ((slotColumns - 1) * resolvedGap)
		while usedWidth > anchorWidth and resolvedGap > 2 do
			resolvedGap = resolvedGap - 1
			usedWidth = (resolvedSize * slotColumns) + ((slotColumns - 1) * resolvedGap)
		end
		local remaining = anchorWidth - usedWidth
		if remaining > 0 and remaining >= (slotColumns - 1) then
			local extraGap = math.min(maxGap - resolvedGap, math.floor(remaining / (slotColumns - 1)))
			if extraGap > 0 then
				resolvedGap = resolvedGap + extraGap
				usedWidth = (resolvedSize * slotColumns) + ((slotColumns - 1) * resolvedGap)
			end
		end

		slotSize = resolvedSize
		slotGap = resolvedGap
		slotAnchor:SetHeight((slotRowsActive * slotSize) + ((slotRowsActive - 1) * slotGap))

		for i = 1, #slots do
			local slot = slots[i]
			local col = (i - 1) % slotColumns
			local row = math.floor((i - 1) / slotColumns)
			slot:ClearAllPoints()
			slot:SetSize(slotSize, slotSize)
			slot:SetPoint("TOPLEFT", slotAnchor, "TOPLEFT", (col * (slotSize + slotGap)), -(row * (slotSize + slotGap)))
		end
	end

	local function ResolveAttachmentRowsForCount(filledCount)
		local count = tonumber(filledCount) or 0
		if count > 8 then
			return math.min(slotRowsVisible, 3)
		end
		if count > 4 then
			return math.min(slotRowsVisible, 2)
		end
		return 1
	end

	local function ApplyAttachmentUsageLayout(filledCount)
		slotRowsActive = ResolveAttachmentRowsForCount(filledCount)
		local compactBodyHeight = 116
		local midBodyHeight = 144
		local fullBodyHeight = 174
		if slotRowsActive >= 3 then
			cardHeight = fullBodyHeight
		elseif slotRowsActive == 2 then
			cardHeight = midBodyHeight
		else
			cardHeight = compactBodyHeight
		end
		sendUtilityRow:SetHeight(cardHeight)
		ApplyUtilityCardSplit()
		ApplyAttachmentSlotGridLayout()
		return slotRowsActive
	end

	for i = 1, slotMax do
		local slot = CreateFrame("Button", nil, sendAttachmentGroup, "BackdropTemplate")
		local col = (i - 1) % slotColumns
		local row = math.floor((i - 1) / slotColumns)
		slot:SetSize(slotSize, slotSize)
		slot:SetPoint("TOPLEFT", slotAnchor, "TOPLEFT", (col * (slotSize + slotGap)), -(row * (slotSize + slotGap)))
		slot:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 7,
			insets = { left = 2, right = 2, top = 2, bottom = 2 },
		})
		slot:SetBackdropColor(unpack(THEME.detailBodyBg))
		slot:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
		ApplySoftCorners(slot, THEME.detailBodyBg)
		slot.slotIndex = i
		slot.hasItem = false
		slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		slot:SetHitRectInsets(-3, -3, -3, -3)
		slot:SetScript("OnMouseUp", function(self, button)
			HandleSendAttachmentSlotClick(self, button)
		end)
		slot:SetScript("OnReceiveDrag", function(self)
			ClickSendAttachmentSlot(self.slotIndex or 1, false)
		end)
		slot:SetScript("OnEnter", function(self)
			self:SetBackdropBorderColor(unpack(TintColor(THEME.detailBodyBorder, 0.22, 0.95)))
			if not self.hasItem or not GameTooltip then
				return
			end
			local tooltipOwner = self.icon or self
			GameTooltip:SetOwner(tooltipOwner, "ANCHOR_NONE")
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("TOPRIGHT", tooltipOwner, "TOPLEFT", -8, 0)
			local hasTooltip = false
			if GameTooltip.SetSendMailItem then
				hasTooltip = GameTooltip:SetSendMailItem(self.slotIndex or 1)
			end
			if (not hasTooltip) and GetSendMailItemLink and GameTooltip.SetHyperlink then
				local itemLink = GetSendMailItemLink(self.slotIndex or 1)
				if itemLink then
					GameTooltip:SetHyperlink(itemLink)
					hasTooltip = true
				end
			end
			if hasTooltip then
				GameTooltip:Show()
				HideItemCompareTooltips()
			else
				GameTooltip:Hide()
			end
		end)
		slot:SetScript("OnLeave", function(self)
			self:SetBackdropBorderColor(unpack(SoftBorderColor(THEME.detailBodyBorder)))
			HideItemCompareTooltips()
			if GameTooltip then
				if self.icon and GameTooltip:IsOwned(self.icon) then
					GameTooltip:Hide()
				elseif GameTooltip:IsOwned(self) then
					GameTooltip:Hide()
				end
			end
		end)

		local icon = slot:CreateTexture(nil, "ARTWORK")
		icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 3, -3)
		icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -3, 3)
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon:SetTexture("Interface\\PaperDoll\\UI-Backpack-EmptySlot")
		icon:SetVertexColor(0.62, 0.62, 0.62, 0.75)
		slot.icon = icon

		local countText = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
		countText:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -3, 2)
		countText:SetText("")
		slot.countText = countText

		slot:SetShown(i == 1)
		slots[#slots + 1] = slot
	end
	GM.UI.sendAttachmentSlots = slots
	slotAnchor:SetScript("OnSizeChanged", ApplyAttachmentSlotGridLayout)
	ApplyAttachmentUsageLayout(0)

	local sendAttachmentNameText = sendAttachmentGroup:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sendAttachmentNameText:SetPoint("TOPLEFT", slotAnchor, "BOTTOMLEFT", 0, -5)
	sendAttachmentNameText:SetPoint("TOPRIGHT", slotAnchor, "BOTTOMRIGHT", 0, -5)
	sendAttachmentNameText:SetJustifyH("LEFT")
	sendAttachmentNameText:SetWordWrap(false)
	sendAttachmentNameText:SetText("No attachment")
	GM.UI.sendAttachmentNameText = sendAttachmentNameText

	local sendAttachHintText = sendAttachmentGroup:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	sendAttachHintText:SetPoint("TOPLEFT", sendAttachmentNameText, "BOTTOMLEFT", 0, -2)
	sendAttachHintText:SetPoint("TOPRIGHT", sendAttachmentNameText, "BOTTOMRIGHT", 0, -2)
	sendAttachHintText:SetJustifyH("LEFT")
	sendAttachHintText:SetWordWrap(false)
	sendAttachHintText:SetText("Pick up an item, then click empty slot")
	GM.UI.sendAttachHintText = sendAttachHintText
	GM.UI.sendAttachmentApplyUsageLayout = ApplyAttachmentUsageLayout

	local sendPaymentForm = CreateFrame("Frame", nil, sendAttachmentControls)
	sendPaymentForm:SetPoint("TOPLEFT", sendAttachmentControls, "TOPLEFT", paymentPadLeft, -(paymentPadTop + 18))
	sendPaymentForm:SetPoint("TOPRIGHT", sendAttachmentControls, "TOPRIGHT", -paymentPadRight, -(paymentPadTop + 18))
	sendPaymentForm:SetPoint("BOTTOMLEFT", sendAttachmentControls, "BOTTOMLEFT", paymentPadLeft, paymentPadBottom)
	sendPaymentForm:SetPoint("BOTTOMRIGHT", sendAttachmentControls, "BOTTOMRIGHT", -paymentPadRight, paymentPadBottom)
	sendPaymentForm:SetFrameLevel(sendAttachmentControls:GetFrameLevel() + 1)

	sendGoldLabel:SetParent(sendAttachmentControls)
	sendGoldLabel:ClearAllPoints()
	sendGoldLabel:SetPoint("TOPLEFT", sendPaymentForm, "TOPLEFT", 0, 0)
	sendGoldLabel:SetWidth(paymentLabelWidth)
	sendGoldLabel:SetJustifyH("LEFT")
	sendGoldInput:SetParent(sendAttachmentControls)
	sendGoldInput:ClearAllPoints()
	sendGoldInput:SetFrameLevel(sendAttachmentControls:GetFrameLevel() + 3)
	sendGoldInput:SetWidth(74)
	sendGoldInput:SetPoint("LEFT", sendPaymentForm, "LEFT", paymentInputStart, 0)
	sendGoldInput:SetPoint("TOP", sendGoldLabel, "TOP", 0, 1)
	sendGoldInput:SetHeight(20)

	local sendGoldIcon = sendAttachmentControls:CreateTexture(nil, "ARTWORK")
	sendGoldIcon:SetSize(13, 13)
	sendGoldIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
	sendGoldIcon:SetPoint("LEFT", sendGoldInput, "RIGHT", 4, 0)
	GM.UI.sendGoldIcon = sendGoldIcon

	local sendCODToggle = CreateFrame("CheckButton", nil, sendAttachmentControls, "UICheckButtonTemplate")
	sendCODToggle:SetPoint("LEFT", sendGoldIcon, "RIGHT", 8, 0)
	sendCODToggle:SetSize(16, 16)
	sendCODToggle:SetFrameLevel(sendAttachmentControls:GetFrameLevel() + 3)
	sendCODToggle:SetHitRectInsets(-4, -10, -4, -4)
	sendCODToggle:EnableMouse(true)
	sendCODToggle:SetScript("OnClick", function()
		UpdateSendCODInputState()
	end)
	GM.UI.sendCODToggle = sendCODToggle

	local sendCODLabel = sendAttachmentControls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendCODLabel:SetPoint("LEFT", sendCODToggle, "RIGHT", 2, 0)
	sendCODLabel:SetPoint("RIGHT", sendPaymentForm, "RIGHT", 0, 0)
	sendCODLabel:SetJustifyH("LEFT")
	sendCODLabel:SetText("COD")
	GM.UI.sendCODLabel = sendCODLabel

	local sendCODAmountLabel = sendAttachmentControls:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendCODAmountLabel:SetPoint("TOPLEFT", sendGoldLabel, "BOTTOMLEFT", 0, -paymentRowGap)
	sendCODAmountLabel:SetWidth(paymentLabelWidth)
	sendCODAmountLabel:SetJustifyH("LEFT")
	sendCODAmountLabel:SetText("Amount")
	GM.UI.sendCODAmountLabel = sendCODAmountLabel

	local sendCODInput = CreateFrame("EditBox", nil, sendAttachmentControls, "InputBoxTemplate")
	sendCODInput:SetAutoFocus(false)
	sendCODInput:SetHeight(20)
	sendCODInput:SetNumeric(false)
	sendCODInput:SetFrameLevel(sendAttachmentControls:GetFrameLevel() + 3)
	sendCODInput:SetPoint("TOPLEFT", sendCODAmountLabel, "TOPLEFT", paymentInputStart, 2)
	sendCODInput:SetPoint("RIGHT", sendPaymentForm, "RIGHT", 0, 0)
	sendCODInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	sendCODInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
	GM.UI.sendCODInput = sendCODInput

	BuildSendAttachmentEventFrame(sendPanel)

	return sendUtilityRow
end

local function BuildSendMessageBodySection(sendPanel, sendAttachmentGroup, sectionGap)
	local messageTopGap = 10
	local bodyTopGap = 4

	local sendBodyLabel = sendPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	sendBodyLabel:SetPoint("TOPLEFT", sendAttachmentGroup, "BOTTOMLEFT", 0, -messageTopGap)
	sendBodyLabel:SetText("Message")
	GM.UI.sendBodyLabel = sendBodyLabel

	local sendActionBar = CreateFrame("Frame", nil, sendPanel, "BackdropTemplate")
	sendActionBar:SetPoint("BOTTOMLEFT", sendPanel, "BOTTOMLEFT", 10, 8)
	sendActionBar:SetPoint("BOTTOMRIGHT", sendPanel, "BOTTOMRIGHT", -10, 8)
	sendActionBar:SetHeight(28)
	sendActionBar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	ApplyPanelSurfaceStyle(sendActionBar, THEME.detailBodyBg, THEME.detailBodyBorder, THEME.title)
	GM.UI.sendActionBar = sendActionBar

	local sendBodyFrame = CreateFrame("Frame", nil, sendPanel, "BackdropTemplate")
	sendBodyFrame:SetPoint("TOPLEFT", sendBodyLabel, "BOTTOMLEFT", 0, -bodyTopGap)
	sendBodyFrame:SetPoint("TOPRIGHT", sendAttachmentGroup, "BOTTOMRIGHT", 0, -(messageTopGap + 12 + bodyTopGap))
	sendBodyFrame:SetPoint("BOTTOMLEFT", sendActionBar, "TOPLEFT", 0, 8)
	sendBodyFrame:SetPoint("BOTTOMRIGHT", sendActionBar, "TOPRIGHT", 0, 8)
	sendBodyFrame:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	ApplyPanelSurfaceStyle(sendBodyFrame, THEME.detailBodyBg, THEME.detailBodyBorder, THEME.title)
	GM.UI.sendBodyFrame = sendBodyFrame

	local sendBodyInput = CreateFrame("EditBox", nil, sendBodyFrame)
	sendBodyInput:SetMultiLine(true)
	sendBodyInput:SetAutoFocus(false)
	sendBodyInput:SetFontObject(ChatFontNormal)
	sendBodyInput:SetPoint("TOPLEFT", sendBodyFrame, "TOPLEFT", 7, -7)
	sendBodyInput:SetPoint("BOTTOMRIGHT", sendBodyFrame, "BOTTOMRIGHT", -7, 5)
	sendBodyInput:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	GM.UI.sendBodyInput = sendBodyInput

	return sendActionBar
end

local function BuildSendActionSection(sendPanel, sendActionBar)
	local sendSendButton = CreateFrame("Button", nil, sendPanel, "UIPanelButtonTemplate")
	sendSendButton:SetSize(92, 22)
	sendSendButton:SetPoint("RIGHT", sendActionBar, "RIGHT", -8, 0)
	sendSendButton:SetText("Send")
	sendSendButton:SetScript("OnClick", function()
		if GM.UI and GM.UI.sendPending then
			AppendSendDebugDump("click_ignored_pending", {
				attemptId = GM.UI.sendPendingAttemptId,
			})
			return
		end
		local recipient = TrimText(GM.UI.sendRecipientInput and GM.UI.sendRecipientInput:GetText() or "")
		if recipient == "" then
			SetStatusText("Recipient required")
			AppendSendDebugDump("validation_failed", {
				reason = "recipient_required",
			})
			return
		end
		local subject = GM.UI.sendSubjectInput and GM.UI.sendSubjectInput:GetText() or ""
		subject = TrimText(subject)
		if subject == "" then
			subject = GetDefaultSendSubjectFromAttachments()
			if subject ~= "" and GM.UI.sendSubjectInput then
				GM.UI.sendSubjectInput:SetText(subject)
			end
		end
		local body = GM.UI.sendBodyInput and GM.UI.sendBodyInput:GetText() or ""
		local goldCopper = ParseGoldInput(GM.UI.sendGoldInput and GM.UI.sendGoldInput:GetText() or "")
		local codCopper = ParseCopperInput(GM.UI.sendCODInput and GM.UI.sendCODInput:GetText() or "")
		local hasAttachment = HasAnySendAttachment()
		local codEnabled = hasAttachment and GM.UI.sendCODToggle and GM.UI.sendCODToggle:GetChecked()
		if SendMail then
			local attemptId = (GM.UI.sendAttemptSeq or 0) + 1
			GM.UI.sendAttemptSeq = attemptId
			GM.UI.sendPendingAttemptId = attemptId
			GM.UI.sendPendingSince = GetTime and GetTime() or nil
			AppendSendDebugDump("click_send", {
				attemptId = attemptId,
				recipientLen = string.len(recipient or ""),
				subjectLen = string.len(subject or ""),
				bodyLen = string.len(body or ""),
				goldCopper = goldCopper,
				codCopper = codCopper,
				codEnabled = codEnabled and true or false,
				hasAttachment = hasAttachment and true or false,
			})
			SetSendPendingState(true)
			SetStatusText("Sending...")
			if C_Timer and C_Timer.NewTimer then
				if GM.UI.sendWatchdogTimer and GM.UI.sendWatchdogTimer.Cancel then
					GM.UI.sendWatchdogTimer:Cancel()
				end
				GM.UI.sendWatchdogTimer = C_Timer.NewTimer(SEND_WATCHDOG_SECONDS, function()
					if not GM.UI or not GM.UI.sendPending then
						return
					end
					if GM.UI.sendPendingAttemptId ~= attemptId then
						return
					end
					AppendSendDebugDump("timeout", {
						attemptId = attemptId,
						sendPending = GM.UI.sendPending,
					})
					SetSendPendingState(false)
					SetStatusText("Send timed out")
				end)
			end
			if SetSendMailMoney then
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
			AppendSendDebugDump("sendmail_called", {
				attemptId = attemptId,
			})
		else
			SetStatusText("Send unavailable")
			AppendSendDebugDump("send_unavailable", {})
		end
	end)
	StyleSendActionButton(sendSendButton, "primary")
	GM.UI.sendSendButton = sendSendButton

	local sendClearButton = CreateFrame("Button", nil, sendPanel, "UIPanelButtonTemplate")
	sendClearButton:SetSize(78, 22)
	sendClearButton:SetPoint("RIGHT", sendSendButton, "LEFT", -8, 0)
	sendClearButton:SetText("Clear")
	sendClearButton:SetScript("OnClick", function()
		ResetSendFormState(true)
	end)
	StyleSendActionButton(sendClearButton, "secondary")
	GM.UI.sendClearButton = sendClearButton
end

local function BuildSendPanel(frame)
	local panelPadX = 12
	local fieldTopGap = 5
	local labelToFieldGap = 1
	local sectionGap = 5

	local sendPanel = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	sendPanel:SetPoint("TOPLEFT", frame, "TOPLEFT", panelPadX, -42)
	sendPanel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -panelPadX, -42)
	sendPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", panelPadX, 8)
	sendPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -panelPadX, 8)
	sendPanel:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		edgeSize = 7,
		insets = { left = 2, right = 2, top = 2, bottom = 2 },
	})
	ApplyPanelSurfaceStyle(sendPanel, THEME.surfaceBg, THEME.listBorder, THEME.title)
	sendPanel:Hide()
	GM.UI.sendPanel = sendPanel

	local sendRecipientInput, sendSubjectInput = BuildSendRecipientSubjectRow(sendPanel, labelToFieldGap)
	local sendAttachmentGroup = BuildSendAttachmentAndPaymentRow(sendPanel, sendRecipientInput, sendSubjectInput, fieldTopGap)
	local sendActionBar = BuildSendMessageBodySection(sendPanel, sendAttachmentGroup, sectionGap)
	BuildSendActionSection(sendPanel, sendActionBar)

	SetSendPendingState(false)
	UpdateSendAttachmentPreview()
end

local function BuildInboxSummaryBar(frame)
	local summaryBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	summaryBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -34)
	summaryBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -34)
	summaryBar:SetHeight(26)
	summaryBar:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	ApplyPanelSurfaceStyle(summaryBar, THEME.surfaceBg, THEME.summaryBorder, THEME.title)
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
	footer:SetHeight(26)
	footer:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 7,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	})
	ApplyPanelSurfaceStyle(footer, THEME.surfaceBg, THEME.surfaceBorder, THEME.title)
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
	ApplyPanelSurfaceStyle(toolbar, THEME.toolbarBg, THEME.toolbarBorder, THEME.title)
	GM.UI.toolbar = toolbar

	local toolbarAccent = toolbar:CreateTexture(nil, "BACKGROUND")
	toolbarAccent:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 1, -1)
	toolbarAccent:SetPoint("TOPRIGHT", toolbar, "TOPRIGHT", -1, -1)
	toolbarAccent:SetHeight(1)
	toolbarAccent:SetColorTexture(unpack(TintColor((THEME_TOKENS and THEME_TOKENS.accent) or THEME.accent, 0.15, 0.52)))
	GM.UI.toolbarAccent = toolbarAccent

	local title = toolbar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("LEFT", toolbar, "LEFT", 10, 1)
	title:SetText("GorilMail")
	title:SetTextColor(unpack((THEME_TOKENS.text and THEME_TOKENS.text.title) or THEME.title))
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
	ApplyPanelSurfaceStyle(listContainer, THEME.surfaceBg, THEME.listBorder, THEME.title)
	GM.UI.listContainer = listContainer
	return listContainer
end

local function BuildToolbarButtons(toolbar, frame)
	local closeButton = CreateFrame("Button", nil, toolbar, "UIPanelCloseButton")
	closeButton:SetPoint("RIGHT", toolbar, "RIGHT", 2, 0)
	closeButton:SetScript("OnClick", function()
		if GM.UI then
			GM.UI.closingByX = true
			if GM.UI.sendRecipientInput then
				GM.UI.sendRecipientInput:ClearFocus()
			end
			if GM.UI.sendSubjectInput then
				GM.UI.sendSubjectInput:ClearFocus()
			end
			if GM.UI.sendGoldInput then
				GM.UI.sendGoldInput:ClearFocus()
			end
			if GM.UI.sendCODInput then
				GM.UI.sendCODInput:ClearFocus()
			end
			if GM.UI.sendBodyInput then
				GM.UI.sendBodyInput:ClearFocus()
			end
		end
		if MailFrame and MailFrame.IsShown and MailFrame:IsShown() then
			MailFrame:Hide()
		end
		frame:Hide()
	end)

	local themeHordeButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	themeHordeButton:SetSize(24, 20)
	themeHordeButton:SetPoint("RIGHT", closeButton, "LEFT", -2, 0)
	themeHordeButton:SetHitRectInsets(-2, -2, -3, -3)
	themeHordeButton:SetText("H")
	themeHordeButton:SetScript("OnClick", function()
		SetActiveTheme("Horde")
	end)
	GM.UI.themeHordeButton = themeHordeButton

	local themeAllianceButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	themeAllianceButton:SetSize(24, 20)
	themeAllianceButton:SetPoint("RIGHT", themeHordeButton, "LEFT", -2, 0)
	themeAllianceButton:SetHitRectInsets(-2, -2, -3, -3)
	themeAllianceButton:SetText("A")
	themeAllianceButton:SetScript("OnClick", function()
		SetActiveTheme("Alliance")
	end)
	GM.UI.themeAllianceButton = themeAllianceButton

	local modeSendButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	modeSendButton:SetSize(54, 20)
	modeSendButton:SetPoint("RIGHT", themeAllianceButton, "LEFT", -4, 0)
	modeSendButton:SetText("Send")
	modeSendButton:SetScript("OnClick", function()
		SetViewMode("send")
	end)
	GM.UI.modeSendButton = modeSendButton

	local modeInboxButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	modeInboxButton:SetSize(54, 20)
	modeInboxButton:SetPoint("RIGHT", modeSendButton, "LEFT", -2, 0)
	modeInboxButton:SetText("Inbox")
	modeInboxButton:SetScript("OnClick", function()
		SetViewMode("inbox")
	end)
	GM.UI.modeInboxButton = modeInboxButton

	local defaultUIButton = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
	defaultUIButton:SetSize(96, 20)
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
	StyleGeneralButton(defaultUIButton, "secondary")
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
end

local function BuildFooterActionButtons(footer)
	local refreshButton = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
	refreshButton:SetSize(92, 20)
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
	StyleGeneralButton(refreshButton, "secondary")
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
	collectButton:SetSize(104, 20)
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

		GM.Collector.Start(rows, "collectAll")
		RenderInboxRows()
	end)
	StyleGeneralButton(collectButton, "primary")
	GM.UI.collectAllButton = collectButton
end

local function BuildDetailPanelHeader(detailPanel)
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

	return detailHeader, detailMetaText
end

HideItemCompareTooltips = function()
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

local function BuildDetailPanelItemSection(detailPanel, detailHeader)
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
				HideItemCompareTooltips()
				return
			end
		end
		if GameTooltip and GM.UI.detailItemLink and GameTooltip.SetHyperlink then
			GameTooltip:SetOwner(tooltipOwner, "ANCHOR_NONE")
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint("TOPRIGHT", tooltipOwner, "TOPLEFT", -8, 0)
			GameTooltip:SetHyperlink(GM.UI.detailItemLink)
			GameTooltip:Show()
			HideItemCompareTooltips()
		end
	end)
	detailItemTooltipArea:SetScript("OnLeave", function()
		HideItemCompareTooltips()
		if GameTooltip and GM.UI and GM.UI.detailItemIcon and GameTooltip:IsOwned(GM.UI.detailItemIcon) then
			GameTooltip:Hide()
		end
	end)
	detailItemTooltipArea:SetScript("OnUpdate", function(self)
		if not GameTooltip or not GM.UI or not GM.UI.detailItemIcon or not GameTooltip:IsOwned(GM.UI.detailItemIcon) then
			return
		end
		if not self:IsMouseOver() then
			HideItemCompareTooltips()
			GameTooltip:Hide()
		end
	end)
	detailItemTooltipArea:SetScript("OnHide", function()
		HideItemCompareTooltips()
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
end

local function BuildDetailPanelBodySection(detailPanel, detailMetaText)
	local detailCollectButton = CreateFrame("Button", nil, detailPanel, "UIPanelButtonTemplate")
	detailCollectButton:SetSize(100, 20)
	detailCollectButton:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", -8, 8)
	detailCollectButton:SetText("Collect This")
	detailCollectButton.actionKind = "none"
	detailCollectButton:SetScript("OnClick", function()
		StartPrimaryActionForMail(GM.UI.selectedMailIndex, detailCollectButton.actionKind)
	end)
	StyleRowActionButton(detailCollectButton)
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
end

local function BuildDetailPanel()
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

	local detailHeader, detailMetaText = BuildDetailPanelHeader(detailPanel)
	BuildDetailPanelItemSection(detailPanel, detailHeader)
	BuildDetailPanelBodySection(detailPanel, detailMetaText)
end

local function BuildInboxListWidgets(listContainer)
	local header = CreateFrame("Frame", nil, listContainer)
	header:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 4, -4)
	header:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -26, -4)
	header:SetHeight(24)
	GM.UI.header = header

	local headerBg = header:CreateTexture(nil, "BACKGROUND")
	headerBg:SetAllPoints()
	headerBg:SetColorTexture(unpack(THEME.headerBg))
	GM.UI.headerBg = headerBg
	ApplyHeaderBandStyle()
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
	scrollFrame:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -24)
	scrollFrame:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -32, 4)
	scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, RenderInboxRows)
	end)
	GM.UI.scrollFrame = scrollFrame

	local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
	if scrollBar then
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -9, -26)
		scrollBar:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -9, 6)
	end

	local scrollDivider = listContainer:CreateTexture(nil, "BORDER")
	scrollDivider:SetColorTexture(unpack(THEME.scrollDivider))
	scrollDivider:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -32, -24)
	scrollDivider:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -32, 4)
	scrollDivider:SetWidth(1)
	GM.UI.scrollDivider = scrollDivider

	local rowAnchor = CreateFrame("Frame", nil, listContainer)
	rowAnchor:SetPoint("TOPLEFT", listContainer, "TOPLEFT", 0, -24)
	rowAnchor:SetPoint("TOPRIGHT", listContainer, "TOPRIGHT", -36, -24)
	rowAnchor:SetPoint("BOTTOMLEFT", listContainer, "BOTTOMLEFT", 0, 4)
	rowAnchor:SetPoint("BOTTOMRIGHT", listContainer, "BOTTOMRIGHT", -36, 4)
	GM.UI.rowAnchor = rowAnchor

	local rows = {}
	for i = 1, VISIBLE_ROW_COUNT do
		rows[i] = CreateRow(rowAnchor, i, 0)
	end
	GM.UI.rows = rows
	EnsureVisibleRows()
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
			if GM.UI.sendRecipientInput then
				GM.UI.sendRecipientInput:ClearFocus()
			end
			if GM.UI.sendSubjectInput then
				GM.UI.sendSubjectInput:ClearFocus()
			end
			if GM.UI.sendGoldInput then
				GM.UI.sendGoldInput:ClearFocus()
			end
			if GM.UI.sendCODInput then
				GM.UI.sendCODInput:ClearFocus()
			end
			if GM.UI.sendBodyInput then
				GM.UI.sendBodyInput:ClearFocus()
			end
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
	ApplyPanelSurfaceStyle(frame, THEME.panelBg, THEME.panelBorder, THEME.title)
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
	BuildToolbarButtons(toolbar, frame)

	BuildInboxSummaryBar(frame)

	local footer = BuildInboxFooterFrame(frame)
	BuildFooterActionButtons(footer)

	local listContainer = BuildListContainerFrame(frame, footer)

	BuildSendPanel(frame)
	BuildDetailPanel()
	BuildInboxListWidgets(listContainer)

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
