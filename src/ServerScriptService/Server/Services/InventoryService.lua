local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemDefinitions = require(Shared.Definitions.ItemDefinitions)

local InventoryService = {}

local playerDataService = nil

local function result(success, code, message, data)
	return {
		Success = success,
		Code = code,
		Message = message,
		Data = data,
	}
end

function InventoryService.Init(dependencies)
	playerDataService = dependencies.PlayerDataService
	assert(playerDataService, "InventoryService requires PlayerDataService.")
end

function InventoryService.GetInventory(player)
	return playerDataService.GetSnapshot(player, "Inventory")
end

function InventoryService.GetItemQuantity(player, itemId)
	if not ItemDefinitions[itemId] then
		return result(false, "UnknownItemId", "Unknown item `" .. tostring(itemId) .. "`.")
	end

	local snapshotResult = playerDataService.GetSnapshot(player, "Inventory")
	if not snapshotResult.Success then
		return snapshotResult
	end

	local itemState = snapshotResult.Data.Items[itemId]
	local quantity = if itemState then itemState.Quantity else 0

	return result(true, "ItemQuantityRead", nil, {
		ItemId = itemId,
		Quantity = quantity,
	})
end

function InventoryService.HasItem(player, itemId, quantity)
	local requiredQuantity = quantity or 1

	if type(requiredQuantity) ~= "number" or requiredQuantity <= 0 then
		return false
	end

	local quantityResult = InventoryService.GetItemQuantity(player, itemId)
	if not quantityResult.Success then
		return false
	end

	return quantityResult.Data.Quantity >= requiredQuantity
end

function InventoryService.AddItem(player, itemId, quantity, sourceContext)
	local itemDefinition = ItemDefinitions[itemId]
	if not itemDefinition then
		return result(false, "UnknownItemId", "Unknown item `" .. tostring(itemId) .. "`.")
	end

	if type(quantity) ~= "number" or quantity <= 0 then
		return result(false, "InvalidItemQuantity", "Item quantity must be positive.")
	end

	if itemDefinition.Stackable == false and quantity > 1 then
		return result(false, "ItemNotStackable", "Non-stackable item grants must use quantity 1.")
	end

	return playerDataService.Mutate(player, "AddItem", sourceContext, function(playerData)
		local inventory = playerData.Inventory
		local previousQuantity = 0
		local now = os.time()
		local itemState = inventory.Items[itemId]

		if itemState then
			previousQuantity = itemState.Quantity
			if itemDefinition.Stackable == false then
				itemState.Quantity = math.max(itemState.Quantity, 1)
			else
				itemState.Quantity += quantity
			end
			itemState.LastCollectedAt = now
		else
			itemState = {
				ItemId = itemId,
				Quantity = quantity,
				FirstCollectedAt = now,
				LastCollectedAt = now,
			}
			inventory.Items[itemId] = itemState
		end

		return {
			ItemState = itemState,
			PreviousQuantity = previousQuantity,
			NewQuantity = itemState.Quantity,
		}
	end)
end

return InventoryService
