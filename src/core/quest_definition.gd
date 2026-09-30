class_name QuestDefinition
extends Resource

## Data-only Resource representing a quest.
## Loaded from res://data/quests/. State tracked separately in QuestLog.

enum QuestState { NOT_STARTED, IN_PROGRESS, COMPLETED, FAILED }

@export var quest_id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var recommended_level: int = 1
@export var xp_reward: int = 100
@export var gold_reward: int = 0

# ── Serialization ──────────────────────────────────────────────────────────────

func serialize() -> Dictionary:
	return {
		"quest_id": quest_id,
		"title": title,
		"description": description,
		"recommended_level": recommended_level,
		"xp_reward": xp_reward,
		"gold_reward": gold_reward,
	}

func deserialize(data: Dictionary) -> void:
	if data.has("quest_id"):           quest_id           = str(data["quest_id"])
	if data.has("title"):              title              = str(data["title"])
	if data.has("description"):        description        = str(data["description"])
	if data.has("recommended_level"):  recommended_level  = int(data["recommended_level"])
	if data.has("xp_reward"):          xp_reward          = int(data["xp_reward"])
	if data.has("gold_reward"):        gold_reward        = int(data["gold_reward"])
