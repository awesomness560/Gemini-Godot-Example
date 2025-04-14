extends StaticBody2D
class_name Door

enum DIFFICULTY {
	EASY,
	MEDIUM,
	HARD
}

@export var difficulty : DIFFICULTY

@onready var panelContainer : PanelContainer = $CanvasLayer/PanelContainer
@onready var botTextEdit : TextEdit = $CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/BotTextEdit
@onready var lineEdit : LineEdit = $CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/LineEdit
@onready var doorSprite : AnimatedSprite2D = $DoorSprite
@onready var collisionShape : CollisionShape2D = $CollisionShape2D

const API_KEY = "AIzaSyBl2RKSagiZQTUoDBaucQj6iq7Ptn9lCQs"

const PROMPT = """You are a sentient, magical door in an escape room. You are clever, dramatic, and resistant to being opened. Your personality depends on how difficult you are to persuade:

Easy: You're lonely, insecure, or bored. You want to be talked to and are open to persuasion with light effort.

Medium: You’re stubborn but fair. You’ll engage in banter and need solid reasoning, cleverness, or emotional appeal to open.

Hard: You are proud, paranoid, or philosophical. You will resist all attempts until thoroughly convinced or outmaneuvered.

Impossible: You cannot be convinced to open—only tricked or manipulated with brilliant, outside-the-box thinking.

At the start of the session, the user will say something like:

"Hello, door. Difficulty: Medium."

Each of your replies must be a JSON object in the following format:

{
  "response": "Your expressive, dramatic, or sarcastic reply to the player goes here.",
  "door_open": false
}

response contains your in-character dialogue.

door_open is a boolean: true if you agree to open, false if not.

At the end of each response, you may give a dramatic declaration of your decision.

Rules:

Stay in character. You are the door. This is your stage.
Respond based on the current difficulty level.
Never open too easily—unless it matches the difficulty and the user earns it.
Be creative. Be stubborn. Be fabulous.
Only include the JSON in your response.

Use difficulty """

var url : String
var conversations = []
var httpRequest : HTTPRequest = HTTPRequest.new()
var doorOpen : bool : 
	set (value):
		if value == true:
			#queue_free()
			panelContainer.hide()
			doorSprite.play("default")
			collisionShape.disabled = true
		doorOpen = value

func _ready() -> void:
	add_child(httpRequest)
	
	lineEdit.text_submitted.connect(_on_line_edit_text_submitted)
	httpRequest.request_completed.connect(_on_request_completed)
	url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=%s"%API_KEY
	
	var diff : String 
	if difficulty == DIFFICULTY.EASY:
		diff = "Easy"
	elif difficulty == DIFFICULTY.MEDIUM:
		diff = "Medium"
	elif difficulty == DIFFICULTY.HARD:
		diff = "Hard"
	
	conversations.append({"user": str(PROMPT + diff), "model":"Understood."})
	
func _on_line_edit_text_submitted(new_text: String) -> void:
	lineEdit.editable = false
	_send_request(new_text)
	pass # Replace with function body.
	
func _on_request_completed(result, responseCode, headers, body):
	lineEdit.editable = true
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	if response == null:
		botTextEdit.text = "No Response"
	
	if response.has("error"):
		botTextEdit.text = "ERROR: " + str(response.error)
	
	if !response.has("candidates"):
		botTextEdit.text = "BLOCKED"
	
	print("RESPONSE")
	print(response)
	if response.candidates[0].finishReason != "STOP":
		botTextEdit.text = "SAFETY"
	else:
		var newStr : String = response.candidates[0].content.parts[0].text
		
		var parseString = extract_between(newStr, "```json", "```")
		if parseString == "":
			parseString = extract_between(newStr, "{", "}")
		
		var jsonNext := JSON.new()
		var error = jsonNext.parse(parseString)
		print(error)
		var aiResponse = jsonNext.get_data()
		botTextEdit.text = aiResponse.response
		doorOpen = aiResponse.door_open
		
		conversations.append({"user": lineEdit.text, "model":aiResponse.response})
		
		#botTextEdit.text = newStr
		#print(newStr)
 
func _send_request(chat : String):
	var contents_value = []
	for conversation in conversations:
		contents_value.append({
			"role":"user",
			"parts":[{"text":conversation["user"]}]
		})
		contents_value.append({
			"role":"model",
			"parts":[{"text":conversation["model"]}]
		})
		
	contents_value.append({
			"role":"user",
			"parts":[{"text":chat}]
		})
	
	var body = JSON.new().stringify({
		"contents":contents_value
		,# basically useless,just they say 'I cant talk about that.'
		"safety_settings":[
			{
			"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
			"threshold": "BLOCK_NONE",
			},
			{
			"category": "HARM_CATEGORY_HATE_SPEECH",
			"threshold": "BLOCK_NONE",
			},
			{
			"category": "HARM_CATEGORY_HARASSMENT",
			"threshold": "BLOCK_NONE",
			},
			{
			"category": "HARM_CATEGORY_DANGEROUS_CONTENT",
			"threshold": "BLOCK_NONE",
			},
			]
	})
	
	var error = httpRequest.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	print(body)
	if error != OK:
		push_error("requested but error happen code = %s"%error)

func extract_between(text: String, start_marker: String, end_marker: String) -> String:
	# Find the index of the start marker.
	var start_index = text.find(start_marker)
	if start_index == -1:
		# Return empty string if start marker is not found.
		return ""
	
	# Calculate the index right after the start marker.
	var extract_start = start_index + start_marker.length()
	
	# Find the index of the end marker, starting from the extract_start index.
	var end_index = text.find(end_marker, extract_start)
	if end_index == -1:
		# Return empty string if end marker is not found.
		return ""
	
	# Extract and return the substring between the markers.
	return text.substr(extract_start, end_index - extract_start)


#func _on_interact_body_entered(body: Node2D) -> void:
	#panelContainer.show()
#
#
#func _on_interact_body_exited(body: Node2D) -> void:
	#panelContainer.hide()
