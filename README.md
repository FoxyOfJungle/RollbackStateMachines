# Foxy-State-Machine
Simple yet functional and versatile state machine for GameMaker

## Setup ##

You can download the .yymps file (right side - releases) or simply copy the script from the .gml file.

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
		
	}, function() {
		show_debug_message("MOVE - ENTER");
		
	}, function() {
		show_debug_message("MOVE - EXIT");
	}),
],
[
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
