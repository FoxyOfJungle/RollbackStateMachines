
/// Feather ignore all
/*==================================================================================
	State Machine with Rollback netcode support.
	Copyright (C) 2024, FoxyOfJungle (@foxyofjungle) | https://foxyofjungle.itch.io/
	License: MIT
==================================================================================*/

/// @desc Create State Machine
/// @method StateMachine(initialState)
/// @param {String,Real} initialState The initial state index.
function StateMachine(_initialState=undefined, _executeEnter=true) constructor {
	freeState = undefined;
	states = [];
	state = undefined;
	statesIds = {}; // "idle" : 0 | "walk" : 1 (used to finding state index by name)
	statesCurrentId = 0;
	transitions = {}; // "idle" : {destinations: {"name" : function}}
	previousState = state;
	__stateTracked = undefined;
	initialState = _initialState;
	initialStateExecuteEnter = _executeEnter;
	instanceId = other.id;
	historyEnable = true;
	history = []; // states history
	historyMaxSize = 10;
	
	#region Private Methods
	/// @ignore
	static __historyAdd = function() {
		array_push(history, state);
		if (array_length(history) > historyMaxSize) {
			array_delete(history, 0, 1);
		}
	}
	#endregion
	
	#region Public Methods
	/// @desc Adds a state to the State Machine.
	/// @method AddState(stateId, stateStruct)
	/// @param {String} name The state name (for debug purposes).
	/// @param {Struct} stateStruct A struct containing: onEnter, onStep, onExit functions.
	static AddState = function(_name, _stateStruct=undefined) {
		states[statesCurrentId] = _stateStruct;
		states[statesCurrentId][$ "name"] = _name;
		states[statesCurrentId][$ "onEnter"] ??= undefined;
		states[statesCurrentId][$ "onStep"] ??= undefined;
		states[statesCurrentId][$ "onExit"] ??= undefined;
		statesIds[$ _name] = statesCurrentId;
		statesCurrentId += 1;
	}
	
	/// @desc Add a free state (maximum one). This state runs every frame.
	/// @method AddFreeState(stateFunction)
	/// @param {Function} stateFunction The function to run.
	static AddFreeState = function(_stateFunction) {
		freeState = _stateFunction;
	}
	
	/// @desc Adds a transition to the State Machine. While it is in the state of the first parameter, it executes the condition function, if it returns true, it goes to the destination state.
	/// @method AddTransition(from, destination)
	/// @param {String} from State name.
	/// @param {String} destination State name.
	/// @param {Function} condition State name.
	static AddTransition = function(_from, _destination, _condition) {
		if (!variable_struct_exists(transitions, _from)) {
			transitions[$ _from] = {
				destinations : {},
			};
		}
		transitions[$ _from].destinations[$ _destination] = _condition;
	}
	
	/// @desc Verify if State Machine has any states.
	/// @method HasStates()
	static HasStates = function() {
		return (array_length(states) > 0);
	}
	
	/// @desc This function defines which state to run.
	/// @method SetState(_state)
	/// When executing this function, the "exit" function from the previous state is executed, as well as the "enter" function from the new state is executed.
	/// @param {Real,String} state The state index.
	/// @returns {undefined}
	static SetState = function(_state) {
		// if is string, get id from state name
		if (is_string(_state)) {
			_state = statesIds[$ _state];
		}
		
		// if it's on current state or there is not a single state, dont do nothing
		if (state == _state) exit;
		
		// set "previous state" to current state
		previousState = state;
		
		// get current state struct and run their "onExit" function
		var _curState = states[state];
		if (_curState.onExit != undefined) {
			method(instanceId, _curState.onExit)(); // (runs on the INSTANCE context)
		}
		
		// change current state to new state
		state = _state;
		
		// get new state struct and run "enter" function from new state
		var _newState = states[_state];
		if (_newState.onEnter != undefined) {
			method(instanceId, _newState.onEnter)(); // (runs on the INSTANCE context)
		}
		
		// save state on historic (if enabled)
		if (historyEnable) {
			__historyAdd();
		}
	}
	
	/// @desc Enable or disable states history.
	/// @method HistorySetEnable(enable)
	/// @param {Bool} enable Enable or disable.
	static HistorySetEnable = function(_enable) {
		historyEnable = _enable;
	}
	
	/// @desc Clear states history.
	/// @method HistoryClear()
	static HistoryClear = function() {
		array_resize(history, 0);
	}
	
	/// @desc Enable or disable states history.
	/// @method HistorySetMaxSize(size)
	/// @param {Real} size Maximum size.
	static HistorySetMaxSize = function(_size) {
		historyMaxSize = _size;
	}
	
	/// @desc This function changes the current state to a previous state (from history).
	/// @method SetStateFromHistory()
	/// @param {Real} position The historical position with previous states.
	/// @returns {undefined}
	static SetStateFromHistory = function(_position) {
		var _end = array_length(states)-1;
		SetState(clamp(_end-_position, 0, _end));
	}
	
	/// @desc This function performs the "Free State" in addition to the current state;
	/// @method Update(instanceId, trackStateVariable)
	/// @param {Id.Instance} instanceId
	/// @param {String} trackStateVariable Change state based on a variable (useful for rollback netcode) 
	/// @returns {undefined}
	static Update = function(_instanceId, _trackStateVariable="") {
		// get instance id
		instanceId = _instanceId;
		
		// set initial state
		if (initialState != undefined) {
			// if is string, convert to integer/id
			if (is_string(initialState)) {
				initialState = statesIds[$ initialState];
			}
			if (initialState >= 0) {
				state = initialState;
				previousState = state;
				if (initialStateExecuteEnter) {
					var _newState = states[state];
					if (_newState.onEnter != undefined) method(instanceId, _newState.onEnter)();
				}
				if (historyEnable) {
					__historyAdd();
				}
			} else {
				__fsm_trace("Initial state is invalid", 1);
			}
			initialState = undefined;
		}
		
		// run free state function
		if (freeState != undefined) freeState();
		
		// only execute if there are states
		if (state == undefined) exit;
		
		// run current state function (on the INSTANCE context)
		if (states[state].onStep != undefined) {
			method(instanceId, states[state].onStep)();
		}
		
		// run transitions destinations conditions
		var _tr = transitions[$ states[state].name];
		if (_tr != undefined) {
			var _destinations = _tr.destinations; // struct
			var _names = variable_struct_get_names(_destinations);
			var i = 0, isize = array_length(_names), name = "";
			repeat(isize) {
				name = _names[i];
				if (method(instanceId, _destinations[$ name])()) {
					SetState(name);
					break;
				}
				++i;
			}
		}
		
		// detect state changes (with IN and OUT variable support)
		if (_trackStateVariable != "") {
			var _variable = variable_instance_get(instanceId, _trackStateVariable);
			if (__stateTracked != state) {
				variable_instance_set(instanceId, _trackStateVariable, state);
				_variable = state;
				__stateTracked = state;
			}
			if (state != _variable) {
				SetState(_variable);
			}
		}
	}
	
	/// @desc Get state struct.
	/// @method GetState(state)
	/// @param {Real} state The state index (integer).
	static GetState = function(_state) {
		if (is_string(_state)) {
			_state = statesIds[$ _state];
		}
		return states[_state];
	}
	
	/// @desc Get current state name.
	/// @method GetStateName()
	static GetStateName = function() {
		if (state == undefined) return "N/A";
		return states[state].name;
	}
	
	/// @desc Get current state index (integer).
	/// @method GetStateIndex()
	static GetStateIndex = function() {
		return state;
	}
	#endregion
}

/// Feather ignore all
/// @ignore
/// @func __fsm_trace(text)
/// @param {String} text
function __fsm_trace(text, level=1) {
	gml_pragma("forceinline");
	if (level <= FSM_CFG_TRACE_LEVEL) show_debug_message($"# RSM >> {text}");
}
