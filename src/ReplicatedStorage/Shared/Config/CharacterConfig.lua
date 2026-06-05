local CharacterConfig = {
	Ids = {
		Atom = "character_atom",
		Neutron = "character_neutron",
		Proton = "character_proton",
	},

	Roles = {
		Atom = "AdventureLeader",
		Neutron = "ScientistInventor",
		Proton = "AICompanion",
	},
}

return table.freeze(CharacterConfig)
