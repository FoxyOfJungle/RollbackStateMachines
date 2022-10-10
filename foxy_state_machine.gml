
/*-------------------------------------------------------------
	Foxy's State Machine. Copyright (C) 2022, Foxy Of Jungle
	License: MIT
-------------------------------------------------------------*/

// configs
// enable error checking
#macro FSM_CFG_ERROR_CHECKING_ENABLE true
// enable debug console messages
#macro FSM_CFG_TRACE_ENABLE true

// system
function __fsm_system(states_array, states_anim_array) constructor {
	__fsm_exception(!is_array(states_array), "Parameter is not an array of states.");
	
	current_state = undefined; // struct
	old_state = undefined; // struct
	__any_state__ = undefined; // struct
	
	// all future states created will be inside this struct (self)
	var i = 0, isize = array_length(states_array);
	repeat(isize) {
		var _state_struct = states_array[i];
		var _state_name = _state_struct.name;
		// copy state to self system
		self[$ _state_name] = _state_struct;
		
		// add anim linked states
		if is_array(states_anim_array) {
			var j = 0, jsize = array_length(states_anim_array);
			repeat(jsize) {
				var _anim_struct = states_anim_array[j];
				var _name = _anim_struct.name;
				// if same name
				if (_name == _state_name) {
					_state_struct[$ "anim_func"] = _anim_struct.anim_func;
				}
				j++;
			}
		}
		i++;
	}
}

/// @desc Create State Machine This function creates a State Machine instance, which returns an id to be used with other functions.
/// Here you will define all the states of the object, through the array of states. You can use an animation array, which are states dedicated for sprite changes and other visual stuff.
/// @param {Array} states_array Array containing all states. To create a state, use: new fsm_state().
/// @param {Array} states_anim_array Array containing all anim states. To create a state, use: new fsm_animation().
/// @returns {undefined}
function fsm_create(states_array, states_anim_array=undefined) {
	return new __fsm_system(states_array, states_anim_array);
}

/// @desc This variable checks if a State Machine exists.
/// @param {Struct} fsm_id The State Machine struct. The variable returned by fsm_create().
/// @returns {Bool}
function fsm_exists(fsm_id) {
	return (is_struct(fsm_id) && instanceof(fsm_id) == "__fsm_system");
}

/// @desc This function performs the current state functions in addition to the "Any State" and "Animations".
/// @param {Struct} fsm_id The State Machine struct. The variable returned by fsm_create().
/// @returns {undefined}
function fsm_step(fsm_id) {
	with(fsm_id) {
		if (current_state != undefined) {
			if (current_state.step_func != undefined) current_state.step_func();
		}
		if (current_state != undefined) {
			if (current_state.anim_func != undefined) current_state.anim_func();
		}
		if (__any_state__ != undefined) {
			if (__any_state__.any_state_func != undefined) __any_state__.any_state_func();
		}
	}
}

/// @desc This constructor creates a state. Use new fsm_state() to return the state containing the struct.
/// @param {String} state_name The name of the state, which will be used whenever you reference it.
/// @param {Function} [step_function] A function or method that will be executed every frame while the state is active.
/// @param {Function} [enter_function] A function or method that will be executed when entering the state.
/// @param {Function} [exit_function] A function or method that will be executed when exiting the state.
/// @returns {Struct}
function fsm_state(state_name, step_function=undefined, enter_function=undefined, exit_function=undefined) constructor {
	name = state_name;
	step_func = step_function;
	enter_func = enter_function;
	exit_func = exit_function;
	anim_func = undefined;
}

/// @desc This constructor creates an animation state. Use new fsm_animation_state() to return the state containing the struct. 
/// @param {String} state_name The name of the state that the animation function will be associated with.
/// @param {Function} [anim_function] A function or method that will be executed every frame while the state is active.
/// @returns {Struct}
function fsm_animation_state(state_name, anim_function=undefined) constructor {
	name = state_name;
	anim_func = anim_function;
}

/// @desc This constructor creates the "Any State" state. It is a state that runs always, regardless of which state you are in.
/// @param {Function} [anystate_function] A function or method that will be executed every frame while the state is active.
/// @returns {Struct}
function fsm_state_any(anystate_function=undefined) constructor {
	name = "__any_state__";
	any_state_func = anystate_function;
}

/// @desc This function defines which state to use.
/// When executing this function, the "enter" function from the new state is executed, as well as the "exit" function from the old state.
/// @param {Struct} fsm_id The State Machine struct. The variable returned by fsm_create().
/// @param {String} new_state The state name. Example: "MOVE".
/// @returns {undefined}
function fsm_set_state(fsm_id, new_state) {
	__fsm_exception(!variable_struct_exists(fsm_id, new_state), "State doesn't exists: " + string(new_state));
	var _new_state = fsm_id[$ new_state];
	if (fsm_id.current_state != undefined) {
		// if it's on current state, dont do nothing
		if (fsm_id.current_state == _new_state) return;
		// set "old state" to current state
		fsm_id.old_state = fsm_id.current_state;
		// run "exit" funtion from current state
		if (fsm_id.current_state.exit_func != undefined) fsm_id.current_state.exit_func();
	}
	// change current state
	fsm_id.current_state = _new_state;
	// run "enter" function from new state
	if (_new_state.enter_func != undefined) _new_state.enter_func();
}

/// @desc This function changes the current state to the previous state.
/// @param {Struct} fsm_id The State Machine struct. The variable returned by fsm_create().
/// @returns {undefined}
function fsm_set_state_old(fsm_id) {
	if (fsm_id.old_state != undefined) {
		var _new_state = fsm_id.old_state;
		if (fsm_id.current_state != undefined) {
			if (fsm_id.current_state == _new_state) return;
			fsm_id.old_state = fsm_id.current_state;
			if (fsm_id.current_state.exit_func != undefined) fsm_id.current_state.exit_func();
		}
		fsm_id.current_state = _new_state;
		if (_new_state.enter_func != undefined) _new_state.enter_func();
	} else {
		__fsm_trace("WARNING: There is no old state to be used.");
	}
}

/// @desc This function returns the state struct.
/// @param {Struct} fsm_id The State Machine struct. The variable returned by fsm_create().
/// @returns {Struct}
function fsm_get_state(fsm_id) {
	__fsm_exception(!fsm_exists(fsm_id), "State Machine doesn't exists.");
	return fsm_id.current_state;
}

/// @desc This function returns the name of the current state.
/// @param {Struct} fsm_id The State Machine struct. The variable returned by fsm_create().
/// @returns {String}
function fsm_get_state_name(fsm_id) {
	__fsm_exception(!fsm_exists(fsm_id), "State Machine doesn't exists.");
	return fsm_id.current_state.name;
}

/// @ignore
function __fsm_exception(condition, text) {
	gml_pragma("forceinline");
	if (FSM_CFG_ERROR_CHECKING_ENABLE && condition) {
		// the loop below doesn't always run...
		var _stack = debug_get_callstack(4), _txt = "";
		var _len = array_length(_stack);
		for (var i = _len-2; i > 0; --i) _txt += string(_stack[i]) + "\n";
		show_error("Foxy's State Machine >> " + string(text) + "\n\n\n" + _txt + "\n\n", true);
	}
}

/// @ignore
function __fsm_trace(text) {
	gml_pragma("forceinline");
	if (FSM_CFG_TRACE_ENABLE) show_debug_message("# FSM >> " + string(text));
}
