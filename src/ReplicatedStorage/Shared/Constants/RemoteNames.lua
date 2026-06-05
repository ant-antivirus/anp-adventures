local RemoteNames = {
	Quest = {
		RequestStart = "Quest_RequestStart",
		RequestProgress = "Quest_RequestProgress",
		StateChanged = "Quest_StateChanged",
	},
	Inventory = {
		RequestSnapshot = "Inventory_RequestSnapshot",
		StateChanged = "Inventory_StateChanged",
	},
	Progression = {
		RequestSnapshot = "Progression_RequestSnapshot",
		StateChanged = "Progression_StateChanged",
	},
	Companion = {
		RequestHint = "Companion_RequestHint",
		RequestSoloAssist = "Companion_RequestSoloAssist",
		StateChanged = "Companion_StateChanged",
	},
	Journal = {
		RequestSnapshot = "Journal_RequestSnapshot",
		MarkViewed = "Journal_MarkViewed",
		StateChanged = "Journal_StateChanged",
	},
	Interaction = {
		RequestInteract = "Interaction_RequestInteract",
	},
	Zone = {
		RequestTravel = "Zone_RequestTravel",
		StateChanged = "Zone_StateChanged",
	},
	InitialState = {
		RequestSnapshot = "InitialState_RequestSnapshot",
	},
}

return table.freeze(RemoteNames)
