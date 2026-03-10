local function freezeEntries(entries)
	for index, entry in ipairs(entries) do
		entries[index] = table.freeze(entry)
	end

	return table.freeze(entries)
end

local RuntimeConfig = {
	Realms = table.freeze({
		Server = "Server",
		Client = "Client",
	}),
	Networking = table.freeze({
		RootFolderName = "SummonWarsRemotes",
		Namespaces = table.freeze({
			Snapshots = "Runtime/Snapshots",
			Debug = "Runtime/Debug",
			Fighters = "Runtime/Fighters",
		}),
	}),
	ECS = table.freeze({
		ServerPhases = freezeEntries({
			{ name = "Bootstrap", event = "default", priority = 100 },
			{ name = "Input", event = "default", priority = 200 },
			{ name = "Authority", event = "default", priority = 300 },
			{ name = "Simulation", event = "default", priority = 400 },
			{ name = "Replication", event = "default", priority = 500 },
			{ name = "Cleanup", event = "default", priority = 600 },
		}),
		ClientPhases = freezeEntries({
			{ name = "Bootstrap", event = "default", priority = 100 },
			{ name = "Input", event = "default", priority = 200 },
			{ name = "Simulation", event = "default", priority = 300 },
			{ name = "Presentation", event = "RenderStepped", priority = 100 },
			{ name = "Cleanup", event = "default", priority = 400 },
		}),
	}),
}

return table.freeze(RuntimeConfig)
