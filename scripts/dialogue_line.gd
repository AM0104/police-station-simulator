extends Resource
class_name DialogueLine

# A single node in a very small dialogue tree.
#
# Each line can point at another DialogueLine resource. The DialogueUI walks
# this chain one press at a time. Because next_line is an exported Resource,
# conversations can be authored in the Inspector or in .tres files without
# touching any code.

## Name shown above the dialogue text. Example: "Arkady Petrovich".
@export var speaker: String = ""

## The line of dialogue itself. Multiline is enabled for longer speeches.
@export_multiline var text: String = ""

## Optional Russian localization. If empty, the English fields are used.
@export var speaker_ru: String = ""
@export_multiline var text_ru: String = ""

## The next line in the conversation, or null if this is the final line.
@export var next_line: DialogueLine

## Optional story event fired when this line is dismissed.
## Examples: "start_quest", "give_promotion", "change_scene".
@export var event_name: String = ""

## String payload for event_name. For "change_scene" this is a scene path;
## for quest events it can be a quest step id. Keep it a String so a line is
## still a simple, serialisable Resource.
@export var event_payload: String = ""
