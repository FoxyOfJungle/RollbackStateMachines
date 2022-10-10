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

```gml
STATE = fsm_create([
	
	// ========= ANY STATE ==========
	new fsm_state_any(function() {
		show_debug_message("ANY STATE");
	}),

	
	// ========= IDLE STATE =========
	new fsm_state("IDLE",
	function() {
		show_debug_message("IDLE - STEP");
		
	}, function() {
		show_debug_message("IDLE - ENTER");
		
	}, function() {
		show_debug_message("IDLE - EXIT");
	}),
	
	
	// ========= MOVE STATE =========
	new fsm_state("MOVE",
	function() {
		show_debug_message("MOVE - STEP");
	}),
], [
	// --------- ANIMATIONS ---------
	new fsm_animation_state("IDLE", function() {
		show_debug_message("IDLE - ANIM");
	}),
	
	new fsm_animation_state("MOVE", function() {
		show_debug_message("MOVE - ANIM");
	}),
]);

fsm_set_state(STATE, "IDLE");
```
