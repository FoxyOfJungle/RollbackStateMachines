# Foxy-State-Machine
Simple yet functional and versatile state machine for GameMaker

## Setup ##

You can download the .yymps file (right side - releases) or simply copy the script from the .gml file.


## Features ##

* Create states and organize all the code in just one place;
* Handles animations separate from states logic (for better organization);
* It has an "Any State" state that is executed every frame, regardless of the current state;
* It is possible to go to the previous state;
* Get current state name.

*(This system does not have transitions, you need to do it within the states themselves).*
* This system has a very simple logic for general cases;
* The system uses strings to reference the state, which prevents using intellisense. You can manually access the current_state variable instead (or just use macros or variables).


## Usage ##

An example of usage:

Create Event:
```gml

state = new StateMachine([
	new StateAny(function() {
		if keyboard_check_pressed(ord("N")) show_debug_message("Any State");
		
		if keyboard_check_pressed(ord("J")) {
			state.SetOldState();
		}
	}),
	// --------------------------
	
	new State("IDLE",
		function() {
			// Go to "MOVE" state
			if keyboard_check_pressed(ord("G")) {
				state.SetState("MOVE");
			}
		},
		function() {
			show_debug_message("Idle: Enter");
		},
		function() {
			show_debug_message("Idle: Exit");
		}),
	// --------------------------
	
	new State("MOVE",
		function() {
			// Go to "IDLE" state
			if keyboard_check_pressed(ord("G")) {
				state.SetState("IDLE");
			}
		},
		function() {
			show_debug_message("Move: Enter");
		},
		function() {
			show_debug_message("Move: Exit");
		}),
	
], []);

state.SetState("IDLE");
```
Step Event:
```gml
state.Update();
```
