local SnapshotEnvelope = {}

function SnapshotEnvelope.create(topic, revision, payload, mode)
	assert(type(topic) == "string" and topic ~= "", "Snapshot topic must be a non-empty string")
	assert(type(revision) == "number", "Snapshot revision must be a number")

	return {
		topic = topic,
		revision = revision,
		mode = mode or "replace",
		generatedAt = os.time(),
		payload = payload,
	}
end

return SnapshotEnvelope
