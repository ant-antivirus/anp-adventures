local MarkerLegendConfig = {
	QuestStart = {
		Label = "Green",
		Meaning = "Start Quest",
	},
	QuestObjective = {
		Label = "Blue",
		Meaning = "Current Objective",
	},
	QuestComplete = {
		Label = "Cyan",
		Meaning = "Complete Quest",
	},
	Discovery = {
		Label = "Yellow",
		Meaning = "Discovery",
	},
	ZoneTravel = {
		Label = "Purple",
		Meaning = "Travel",
	},
	NPCGuide = {
		Label = "Orange",
		Meaning = "Guide",
	},
}

return table.freeze(MarkerLegendConfig)
