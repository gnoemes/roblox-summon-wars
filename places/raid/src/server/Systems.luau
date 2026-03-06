local systems = {
	require(script.Parent:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("Systems"):WaitForChild("SpawnActivePetSystem")),
	require(script.Parent:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("Systems"):WaitForChild("SkillCooldownTickSystem")),
	require(script.Parent:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("Systems"):WaitForChild("AutoSkillSystem")),
	require(script.Parent:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("Systems"):WaitForChild("PetDebugSummarySystem")),
	require(script.Parent:WaitForChild("Features"):WaitForChild("Pets"):WaitForChild("Systems"):WaitForChild("DespawnMissingPetSystem")),
}

return systems
