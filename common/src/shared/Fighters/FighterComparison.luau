local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GradeDefinitions = require(
	ReplicatedStorage:WaitForChild("Shared")
		:WaitForChild("Progression")
		:WaitForChild("Grades")
		:WaitForChild("GradeDefinitions")
)

local FighterComparison = {}

local function compareNumbers(leftValue, rightValue, higherIsBetter)
	if leftValue == rightValue then
		return "equal"
	end

	if higherIsBetter then
		return if leftValue > rightValue then "better" else "worse"
	end

	return if leftValue < rightValue then "better" else "worse"
end

local function getGradeSortOrder(gradeId)
	if GradeDefinitions.has(gradeId) then
		return GradeDefinitions.get(gradeId).sortOrder
	end

	return 0
end

function FighterComparison.compare(left, right)
	assert(type(left) == "table", "left fighter read model must be a table")
	assert(type(right) == "table", "right fighter read model must be a table")

	return {
		leftFighterId = left.fighterId,
		rightFighterId = right.fighterId,
		grade = compareNumbers(getGradeSortOrder(left.grade), getGradeSortOrder(right.grade), true),
		level = compareNumbers(left.level, right.level, true),
		stats = {
			hp = compareNumbers(left.stats.hp, right.stats.hp, true),
			damage = compareNumbers(left.stats.damage, right.stats.damage, true),
			defense = compareNumbers(left.stats.defense, right.stats.defense, true),
			attackIntervalSeconds = compareNumbers(
				left.stats.attackIntervalSeconds,
				right.stats.attackIntervalSeconds,
				false
			),
		},
	}
end

return FighterComparison
