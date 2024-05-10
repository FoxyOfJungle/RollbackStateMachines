# Rollback State Machines
General-purpose State Machine system with rollback netcode sync support (optional).

![huk51iujl](https://github.com/FoxyOfJungle/RollbackStateMachines/assets/52144406/ff996a96-ceb5-4bd8-beb4-4f4b76405135)


## Setup ##

You can download the .yymps file (right side - releases) or simply copy the script from the .gml file.


## Features ##

* Create states and organize all the code in just one place;
* It has a "Free State" that is executed every frame, regardless of the current state;
* Transitions: change from one state to another using a condition;
* onStart, onStep and onExit functions/methods for each state (all optional).
* State history (useful for going back to previous states);
* Get current state name.
* Netcode rollback compatible (non-native)
* * With just one integer variable, synchronize State Machine state - which consumes less memory than structs, and better performance (no need for serialization).
* * Uses object variable to synchronize, which updates automatically.
* You can use strings or integers to reference the states.

## Usage ##

An example of usage:

Create Event:
```gml
// Create State Machine
fsmChar = new StateMachine("Idle");
characterState = 0; // trackable state variable (for rollback netcode sync)

// Free
fsmChar.AddFreeState(function() {
	// get input
	inputH = keyboard_check(vk_right) - keyboard_check(vk_left);
	inputV = keyboard_check(vk_down) - keyboard_check(vk_up);
	inputJump = keyboard_check_pressed(vk_up);
});

// Idle
fsmChar.AddState("Idle", {
	onEnter : function() {
		sprite_index = sprPlayerIdle;
		image_speed = 0.25;
	},
});

// Walk
fsmChar.AddState("Walk", {
	onStep : function() {
		if (inputH != 0) image_xscale = sign(inputH);
	},
	onEnter : function() {
		sprite_index = sprPlayerWalk;
		image_speed = 0.8;
	},
    onExit : function() {
        show_debug_message("Walk Exit...");
    }
});

// Create Transitions
fsmChar.AddTransition("Idle", "Walk", function() {
	return (inputH != 0);
});
fsmChar.AddTransition("Walk", "Idle", function() {
	return (inputH == 0);
});

```
Step Event:
```gml
fsmChar.Update(id, "characterState");
```
