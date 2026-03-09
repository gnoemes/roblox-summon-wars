return table.freeze({
	CombatMath = require(script.CombatMath),
	CombatStatusEngine = require(script.CombatStatusEngine),
	CombatTargeting = require(script.CombatTargeting),
	CombatActionPlanner = require(script.CombatActionPlanner),
	CombatActionResolver = require(script.CombatActionResolver),
	EncounterRules = require(script.EncounterRules),
	EncounterPersistencePolicy = require(script.EncounterPersistencePolicy),
})
