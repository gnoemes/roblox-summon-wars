local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Matter = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Matter"))

return Matter.component("RaidPetHealthState")
