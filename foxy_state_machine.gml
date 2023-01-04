
/*-------------------------------------------------------------
	Foxy's State Machine. Copyright (C) 2023, Foxy Of Jungle
	License: MIT
-------------------------------------------------------------*/

// configs
// enable error checking
#macro FSM_CFG_ERROR_CHECKING_ENABLE true
// enable debug console messages
#macro FSM_CFG_TRACE_ENABLE true

// system
/// @desc This function creates a State Machine instance, which returns a struct to be used with other functions.
/// Here you will define all the states of the object, through the array of states. You can use an animation array, which are states dedicated for sprite changes and other visual stuff.
/// @param {Array} states_array Array containing all states. To create a state, use: new State().
/// @param {Array} states_anim_array Array containing all anim states. To create a state, use: new StateAnim().
/// @returns {undefined}
function StateMachine(states_array, states_anim_array=undefined) constructor {
	__StateMachineException(!is_array(states_array), "Parameter is not an array of states.");
	
	/// @ignore
	__current_state = undefined; // struct
	__old_state = undefined; // struct
	__any_state__ = undefined; // struct
	
	// all future states created will be inside this struct (self)
	var i = 0, isize = array_length(states_array);
	repeat(isize) {
		var _state_struct = states_array[i];
		var _state_name = _state_struct.name;
		// copy state to self system
		self[$ _state_name] = _state_struct;
		
		// add anim linked states
		if (is_array(states_anim_array)) {
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
	
	/// @desc This function performs the current state functions in addition to the "Any State" and "Animations".
	/// @func Update()
	/// @returns {undefined}
	static Update = function() {
		if (__current_state != undefined) {
			if (__current_state.step_func != undefined) __current_state.step_func();
		}
		if (__current_state != undefined) {
			if (__current_state.anim_func != undefined) __current_state.anim_func();
		}
		if (__any_state__ != undefined) {
			if (__any_state__.any_state_func != undefined) __any_state__.any_state_func();
		}
	}
	
	/// @desc This function defines which state to use.
	/// @func SetState(new_state)
	/// When executing this function, the "exit" function from the previous state is executed, as well as the "enter" function from the new state is executed.
	/// @param {String} new_state The state name. Example: "MOVE".
	/// @returns {undefined}
	static SetState = function(new_state) {
		__StateMachineException(!variable_struct_exists(self, new_state), "State doesn't exists: " + string(new_state));
		var _new_state = self[$ new_state];
		if (__current_state != undefined) {
			// if it's on current state, dont do nothing
			if (__current_state == _new_state) return;
			// set "old state" to current state
			__old_state = __current_state;
			// run "exit" function from current state
			if (__current_state.exit_func != undefined) __current_state.exit_func();
		}
		// change current state
		__current_state = _new_state;
		// run "enter" function from new state
		if (_new_state.enter_func != undefined) _new_state.enter_func();
	}
	
	/// @desc This function changes the current state to the previous state.
	/// @func SetOldState()
	/// @param {Struct} fsm_id The State Machine struct. The variable returned by fsm_create().
	/// @returns {undefined}
	static SetOldState = function() {
		if (__old_state != undefined) {
			var _new_state = __old_state;
			if (__current_state != undefined) {
				if (__current_state == _new_state) return;
				__old_state = __current_state;
				if (__current_state.exit_func != undefined) __current_state.exit_func();
			}
			__current_state = _new_state;
			if (_new_state.enter_func != undefined) _new_state.enter_func();
		} else {
			__StateMachineTrace("WARNING: There is no old state to be set.");
		}
	}
	
	/// @desc This function returns the current state struct.
	/// @func GetState()
	/// @returns {Struct} State
	static GetState = function() {
		return __current_state;
	}
	
	/// @desc This function returns the name of the current state.
	/// @func GetStateName()
	/// @returns {String}
	static GetStateName = function() {
		return __current_state != undefined ? __current_state.name : "< No State >";
	}
}

/// @desc This constructor creates a state. Use new fsm_state() to return the state containing the struct.
/// @param {String} state_name The name of the state, which will be used whenever you reference it.
/// @param {Function} [step_function] A function or method that will be executed every frame while the state is active.
/// @param {Function} [enter_function] A function or method that will be executed when entering the state.
/// @param {Function} [exit_function] A function or method that will be executed when exiting the state.
/// @returns {Struct}
function State(state_name, step_function=undefined, enter_function=undefined, exit_function=undefined) constructor {
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
function StateAnim(state_name, anim_function=undefined) constructor {
	name = state_name;
	anim_func = anim_function;
}

/// @desc This constructor creates the "Any State" state. It is a state that runs always, regardless of which state you are in.
/// @param {Function} [anystate_function] A function or method that will be executed every frame while the state is active.
/// @returns {Struct}
function StateAny(anystate_function=undefined) constructor {
	name = "__any_state__";
	any_state_func = anystate_function;
}

/// @desc This variable checks if a State Machine exists.
/// @param {Struct} state_machine The State Machine struct. The variable returned by "new StateMachine()".
/// @returns {Bool}
function StateMachineExists(state_machine) {
	return (is_struct(state_machine) && instanceof(state_machine) == "StateMachine");
}

/// @ignore
function __StateMachineException(condition, text) {
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
function __StateMachineTrace(text) {
	gml_pragma("forceinline");
	if (FSM_CFG_TRACE_ENABLE) show_debug_message("# FSM >> " + string(text));
}
