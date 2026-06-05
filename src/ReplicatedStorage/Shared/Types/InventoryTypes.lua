export type InventoryItemState = {
	ItemId: string,
	Quantity: number,
	FirstCollectedAt: number?,
	LastCollectedAt: number?,
}

export type InventoryState = {
	Items: { [string]: InventoryItemState },
}

export type ItemGrant = {
	ItemId: string,
	Quantity: number,
}

return {}
