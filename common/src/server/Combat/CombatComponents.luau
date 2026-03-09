local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ECS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ECS"))

return table.freeze({
	Encounter = ECS.component("CombatEncounter"),
	Combatant = ECS.component("Combatant"),
	CombatantStats = ECS.component("CombatantStats"),
	CombatantRuntime = ECS.component("CombatantRuntime"),
	CombatantAbilities = ECS.component("CombatantAbilities"),
})
