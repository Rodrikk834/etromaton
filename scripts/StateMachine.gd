extends Node

@export var initialState : State

var currentState: State
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
			
	if initialState:
		initialState.Enter()
		currentState = initialState

func _process(delta: float) -> void:
	if currentState:
		currentState.Update(delta)

func _physics_process(delta: float) -> void:
	if currentState:
		currentState.Physics_Update(delta)

func on_child_transition(state, new_state_name):
	if state != currentState:
		return
	
	var new_state : State = states.get(new_state_name.to_lower())
	if !new_state:
		return
	
	if currentState:
		currentState.Exit()
		
	new_state.Enter()
	currentState = new_state
