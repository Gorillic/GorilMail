local addonName, GM = ...

GM = GM or {}
GM.DestroyScan = GM.DestroyScan or {}

local SPELL_DISENCHANT = 13262
local SPELL_MILL = 51005
local MAX_BAG_ID = 4
local ROW_TYPE_DISENCHANT = "Disenchant"
local ROW_TYPE_MILL = "Mill"

local ITEM_QUALITY_UNCOMMON = (Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon) or 2
local ITEM_QUALITY_LEGENDARY = (Enum and Enum.ItemQuality and Enum.ItemQuality.Legendary) or 5
local ITEM_CLASS_ARMOR = (Enum and Enum.ItemClass and Enum.ItemClass.Armor) or 4
local ITEM_CLASS_WEAPON = (Enum and Enum.ItemClass and Enum.ItemClass.Weapon) or 2
local ITEM_CLASS_TRADEGOODS = (Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods) or 7
local ITEM_SUBCLASS_HERB = (Enum and Enum.ItemTradeGoodsSubclass and Enum.ItemTradeGoodsSubclass.Herb) or 9

local function IsSpellKnownSafe(spellID)
	if type(spellID) ~= "number" then
		return false
	end
	if IsPlayerSpell and IsPlayerSpell(spellID) then
		return true
	end
	if IsSpellKnownOrOverridesKnown then
		return IsSpellKnownOrOverridesKnown(spellID) and true or false
	end
	if IsSpellKnown then
		return IsSpellKnown(spellID) and true or false
	end
	return false
end

local function GetBagSlotInfo(bagID, slot)
	if C_Container and C_Container.GetContainerItemInfo then
		local info = C_Container.GetContainerItemInfo(bagID, slot)
		if type(info) == "table" then
			return {
				itemID = info.itemID,
				count = info.stackCount or 0,
				link = info.hyperlink,
			}
		end
	end
	if GetContainerItemInfo then
		local _, count, _, _, _, _, link, _, _, itemID = GetContainerItemInfo(bagID, slot)
		return {
			itemID = itemID,
			count = count or 0,
			link = link,
		}
	end
	return nil
end

local function GetNumSlotsInBag(bagID)
	if C_Container and C_Container.GetContainerNumSlots then
		return tonumber(C_Container.GetContainerNumSlots(bagID)) or 0
	end
	if GetContainerNumSlots then
		return tonumber(GetContainerNumSlots(bagID)) or 0
	end
	return 0
end

local function GetMaxBagID()
	local configured = tonumber(NUM_TOTAL_EQUIPPED_BAG_SLOTS) or tonumber(NUM_BAG_SLOTS) or MAX_BAG_ID
	if configured < 0 then
		return MAX_BAG_ID
	end
	return configured
end

local function GetItemClassInfo(itemRef, fallbackID)
	local itemID, _, _, equipLoc, _, classID, subClassID = GetItemInfoInstant(itemRef or fallbackID or 0)
	return {
		itemID = itemID,
		equipLoc = equipLoc,
		classID = classID,
		subClassID = subClassID,
	}
end

local function IsDisenchantableByItemData(classInfo, quality)
	if not classInfo or not quality then
		return false
	end
	if quality < ITEM_QUALITY_UNCOMMON or quality >= ITEM_QUALITY_LEGENDARY then
		return false
	end
	if classInfo.classID ~= ITEM_CLASS_ARMOR and classInfo.classID ~= ITEM_CLASS_WEAPON then
		return false
	end
	local equipLoc = classInfo.equipLoc
	if equipLoc == "INVTYPE_BODY" or equipLoc == "INVTYPE_TABARD" then
		return false
	end
	return true
end

local function IsMillableByItemData(classInfo)
	if not classInfo then
		return false
	end
	return classInfo.classID == ITEM_CLASS_TRADEGOODS and classInfo.subClassID == ITEM_SUBCLASS_HERB
end

local function GetDestroyTypeData(classInfo, quality)
	if IsDisenchantableByItemData(classInfo, quality) then
		return ROW_TYPE_DISENCHANT, SPELL_DISENCHANT, 1
	end
	if IsMillableByItemData(classInfo) then
		return ROW_TYPE_MILL, SPELL_MILL, 5
	end
	return nil, nil, nil
end

local function BuildRowKey(bagID, slot, itemID)
	return tostring(tonumber(bagID) or -1) .. ":" .. tostring(tonumber(slot) or -1) .. ":" .. tostring(tonumber(itemID) or 0)
end

local function CompareRows(a, b)
	if tostring(a.itemName) ~= tostring(b.itemName) then
		return tostring(a.itemName) < tostring(b.itemName)
	end
	if (a.bagID or -1) ~= (b.bagID or -1) then
		return (a.bagID or -1) < (b.bagID or -1)
	end
	return (a.slot or -1) < (b.slot or -1)
end

function GM.DestroyScan.Scan()
	local rows = {}
	local summary = {
		candidates = 0,
		ready = 0,
		skipped = 0,
		blocked = 0,
	}
	local knownSpells = {
		knowsDisenchant = IsSpellKnownSafe(SPELL_DISENCHANT),
		knowsMill = IsSpellKnownSafe(SPELL_MILL),
	}

	for bagID = 0, GetMaxBagID() do
		local numSlots = GetNumSlotsInBag(bagID)
		for slot = 1, numSlots do
			local slotInfo = GetBagSlotInfo(bagID, slot)
			if slotInfo and slotInfo.itemID and (slotInfo.count or 0) > 0 then
				local classInfo = GetItemClassInfo(slotInfo.link, slotInfo.itemID)
				local itemName, _, quality = GetItemInfo(slotInfo.link or ("item:" .. tostring(slotInfo.itemID)))
				local destroyType, spellID, minQuantity = GetDestroyTypeData(classInfo, quality)
				if destroyType then
					summary.candidates = summary.candidates + 1
					local knowsSpell = (spellID == SPELL_DISENCHANT and knownSpells.knowsDisenchant) or (spellID == SPELL_MILL and knownSpells.knowsMill)
					local hasQuantity = (slotInfo.count or 0) >= (minQuantity or 1)
					if knowsSpell and hasQuantity then
						local rowKey = BuildRowKey(bagID, slot, slotInfo.itemID)
						rows[#rows + 1] = {
							rowKey = rowKey,
							bagID = bagID,
							slot = slot,
							itemID = slotInfo.itemID,
							itemLink = slotInfo.link,
							itemName = itemName or ("item:" .. tostring(slotInfo.itemID)),
							destroyType = destroyType,
							spellID = spellID,
						}
						summary.ready = summary.ready + 1
					else
						summary.blocked = summary.blocked + 1
					end
				end
			end
		end
	end

	table.sort(rows, CompareRows)
	return rows, summary, knownSpells
end
