
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
	freeStates = []; // array of functions
	freeStatesSize = 0;
	states = []; // array of structs
	state = undefined;
	statesIds = {}; // "idle" : 0 | "walk" : 1 (used to finding state index by name)
	statesCurrentId = 0;
	previousState = state;
	__stateTracked = undefined;
	transitions = {}; // "idle" : {destinations: {"name" : function}}
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
	
	/// @ignore
	static __callEnter = function() {
		gml_pragma("forceinline");
		var _st = states[state];
		if (_st.onEnter != undefined) {
			method(instanceId, _st.onEnter)(); // (runs on the INSTANCE context)
		}
	}
	
	/// @ignore
	static __callStep = function() {
		gml_pragma("forceinline");
		var _st = states[state];
		if (_st.onStep != undefined) {
			method(instanceId, _st.onStep)(); // (runs on the INSTANCE context)
		}
	}
	
	/// @ignore
	static __callExit = function() {
		gml_pragma("forceinline");
		var _st = states[state];
		if (_st.onExit != undefined) {
			method(instanceId, _st.onExit)(); // (runs on the INSTANCE context)
		}
	}
	
	/// @ignore
	static __callTriggers = function(_type) {
		var _triggers = states[state].triggers; // array of state (ids)
		if (_triggers != undefined) {
			var _funcName;
			if (_type == 0) {
				_funcName = "onStep";
			} else
			if (_type == 1) {
				_funcName = "onEnter";
			} else
			if (_type == 2) {
				_funcName = "onExit";
			}
			var i = 0, isize = array_length(_triggers), _triggerState = undefined, _triggerFunc = undefined;
			repeat(isize) {
				_triggerState = states[_triggers[i]];
				_triggerFunc = _triggerState[$ _funcName];
				if (_triggerFunc != undefined) {
					method(instanceId, _triggerFunc)();
				}
				++i;
			}
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
		states[statesCurrentId][$ "triggers"] = undefined;
		statesIds[$ _name] = statesCurrentId;
		statesCurrentId += 1;
		return self;
	}
	
	/// @desc Add a free state (maximum one). This state runs every frame.
	/// @method AddFreeState(stateFunction)
	/// @param {Function} stateFunction The function to run.
	static AddFreeState = function(_stateFunction) {
		freeStates[freeStatesSize] = _stateFunction;
		freeStatesSize += 1;
		return self;
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
		return self;
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
		
		// run "exit" function before going to the new state
		__callExit();
		__callTriggers(2);
		
		// change current state to new state
		state = _state;
		
		// get new state struct and run "enter" function from new state
		__callEnter();
		__callTriggers(1);
		
		// save state on historic (if enabled)
		if (historyEnable) {
			__historyAdd();
		}
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
					if (_newState.onEnter != undefined) {
						method(instanceId, _newState.onEnter)();
					}
					__callTriggers(1);
				}
				if (historyEnable) {
					__historyAdd();
				}
			} else {
				__fsm_trace("Initial state is invalid", 1);
			}
			initialState = undefined;
		}
		
		// run free state functions
		var fi = 0;
		repeat(freeStatesSize) method(instanceId, freeStates[fi++])();
		
		// only execute if there are states
		if (state == undefined) exit;
		var _currentState = states[state]; // struct
		
		// call state's onStep function
		if (_currentState.onStep != undefined) {
			method(instanceId, _currentState.onStep)();
		}
		
		// execute triggers onStep()
		__callTriggers(0);
		
		// run transitions destinations conditions
		var _tr = transitions[$ _currentState.name];
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
	
	/// @desc Verify if State Machine has any states.
	/// @method HasStates()
	static HasStates = function() {
		return (array_length(states) > 0);
	}
	
	/// @desc Enable or disable states history.
	/// @method HistorySetEnable(enable)
	/// @param {Bool} enable Enable or disable.
	static HistorySetEnable = function(_enable) {
		historyEnable = _enable;
		return self;
	}
	
	/// @desc Clear states history.
	/// @method HistoryClear()
	static HistoryClear = function() {
		array_resize(history, 0);
		return self;
	}
	
	/// @desc Enable or disable states history.
	/// @method HistorySetMaxSize(size)
	/// @param {Real} size Maximum size.
	static HistorySetMaxSize = function(_size) {
		historyMaxSize = _size;
		return self;
	}
	
	/// @desc This function changes the current state to a previous state (from history).
	/// @method SetStateFromHistory()
	/// @param {Real} position The historical position with previous states.
	/// @returns {undefined}
	static SetStateFromHistory = function(_position) {
		var _end = array_length(states)-1;
		SetState(clamp(_end-_position, 0, _end));
	}
	
	/// @desc Add a State as a trigger for another. In other words, its functions will be executed according to the defined state.
	/// @method AddTrigger(state, triggerState)
	/// @param {String,Real} state The state to add the trigger to.
	/// @param {String,Real} triggerState The trigger state to be added.
	static AddTrigger = function(_state, _triggerState) {
		// get state id from string
		if (is_string(_state)) {
			_state = statesIds[$ _state];
		}
		if (is_string(_triggerState)) {
			_triggerState = statesIds[$ _triggerState];
		}
		// do not add trigger if the state is the same
		if (_triggerState == _state) {
			__fsm_trace($"Can't add child \"{_triggerState}\" to itself \"{_state}\"", 1);
			exit;
		}
		
		// get origin state struct
		var _parentState = states[_state];
		
		// create triggers array
		if (_parentState[$ "triggers"] == undefined) {
			_parentState[$ "triggers"] = [];
		}
		
		// add trigger state to parent state
		array_push(_parentState[$ "triggers"], _triggerState);
		return self;
	}
	
	/// @desc Replaces functions from one state to another, keeping the same state name.
	/// @func OverrideState(from, to, onStep, onEnter, onExit)
	/// @param {String,Real} from The state to copy from.
	/// @param {String,Real} from The state to copy to.
	/// @param {Bool} replaceOnStep If true, will replace the onStep function.
	/// @param {Bool} replaceOnEnter If true, will replace the onEnter function.
	/// @param {Bool} replaceOnExit If true, will replace the onExit function.
	static OverrideState = function(_from, _to, _replaceOnStep=true, _replaceOnEnter=true, _replaceOnExit=true) {
		// get state id from string
		if (is_string(_from)) {
			_from = statesIds[$ _from];
		}
		if (is_string(_to)) {
			_to = statesIds[$ _to];
		}
		// replace functions
		if (_replaceOnStep) states[_to][$ "onStep"] = states[_from][$ "onStep"];
		if (_replaceOnEnter) states[_to][$ "onEnter"] = states[_from][$ "onEnter"];
		if (_replaceOnExit) states[_to][$ "onExit"] = states[_from][$ "onExit"];
		return self;
	}
	
	/// @desc Replaces specific functions from a state.
	/// @func OverrideStateFunction(state, onStep, onEnter, onExit)
	/// @param {String,Real} state The state to override functions.
	/// @param {Function,Undefined} onStep If defined, replaces the onStep function with a new function/method.
	/// @param {Function,Undefined} onEnter If defined, replaces the onEnter function with a new function/method.
	/// @param {Function,Undefined} onExit If defined, replaces the onExit function with a new function/method.
	static OverrideStateFunction = function(_state, _onStep=undefined, _onEnter=undefined, _onExit=undefined) {
		// get state id from string
		if (is_string(_state)) {
			_state = statesIds[$ _state];
		}
		if (_onStep != undefined) states[_state][$ "onStep"] = _onStep;
		if (_onEnter != undefined) states[_state][$ "onEnter"] = _onEnter;
		if (_onExit != undefined) states[_state][$ "onExit"] = _onExit;
		return self;
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
