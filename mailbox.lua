local addonName, GM = ...

GM = GM or {}

GM.Mailbox = GM.Mailbox or {}

local rows = {}
local callbacks = {}
local mailboxOpen = false

local function NotifyDataChanged()
	for i = 1, #callbacks do
		callbacks[i]()
	end
end

local function NormalizeRow(index)
	local _, _, sender, subject, money, codAmount, _, hasItem, wasRead = GetInboxHeaderInfo(index)
	local moneyValue = money or 0
	local codValue = codAmount or 0
	local hasItemValue = hasItem and true or false
	local canCollect = false
	local canDelete = false
	local blockedReason = nil

	if codValue > 0 then
		canCollect = false
		canDelete = false
		blockedReason = "COD"
	elseif moneyValue > 0 or hasItemValue then
		canCollect = true
		canDelete = false
	else
		canCollect = false
		canDelete = true
		blockedReason = "Empty"
	end

	return {
		index = index,
		sender = sender or "-",
		subject = subject or "-",
		money = moneyValue,
		codAmount = codValue,
		hasItem = hasItemValue,
		wasRead = wasRead and true or false,
		canCollect = canCollect,
		canDelete = canDelete,
		blockedReason = blockedReason,
	}
end

function GM.Mailbox.Initialize()
	rows = rows or {}
end

function GM.Mailbox.RegisterCallback(callback)
	if type(callback) ~= "function" then
		return
	end
	callbacks[#callbacks + 1] = callback
end

function GM.Mailbox.IsOpen()
	return mailboxOpen
end

function GM.Mailbox.GetRows()
	return rows
end

function GM.Mailbox.ScanInbox()
	if not mailboxOpen then
		wipe(rows)
		NotifyDataChanged()
		return
	end

	wipe(rows)
	local count = GetInboxNumItems and GetInboxNumItems() or 0
	for index = 1, count do
		rows[#rows + 1] = NormalizeRow(index)
	end
	NotifyDataChanged()
end

function GM.Mailbox.OnMailShow()
	mailboxOpen = true
	if CheckInbox then
		CheckInbox()
	end
	GM.Mailbox.ScanInbox()
end

function GM.Mailbox.OnMailClosed()
	mailboxOpen = false
	wipe(rows)
	NotifyDataChanged()
end

function GM.Mailbox.OnInboxUpdate()
	if not mailboxOpen then
		return
	end
	GM.Mailbox.ScanInbox()
end
