
// Object variables
inputH = 0;
inputV = 0;
inputJump = 0;
inputDash = 0;
xSpeed = 0;
ySpeed = 0;
gravBase = 0.2;
grav = gravBase;
accel = 0.3;
fric = 0.2;
onGround = false;
moveSpeedBase = 3;
moveSpeed = moveSpeedBase;
moveSpeedOnDash = 20;
jumpSpeed = -5;
dashSpeed = 5;
dashTimerBase = 14;
dashTimer = dashTimerBase;
dashAngle = 0;
enableMovement = true;


// ===============================================
// Create State Machine
fsmChar = new StateMachine("Idle");
characterState = 0; // trackable state variable (for rollback netcode sync)

// Create States
// Free
fsmChar.AddFreeState(function() {
	// get input
	inputH = keyboard_check(vk_right) - keyboard_check(vk_left);
	inputV = keyboard_check(vk_down) - keyboard_check(vk_up);
	inputJump = keyboard_check_pressed(vk_up);
	inputDash = keyboard_check_pressed(vk_space);
	
	// movement
	if (enableMovement) {
		//xSpeed = (inputH != 0) ? moveSpeed * inputH : 0;
		if (inputH != 0) {
			xSpeed += accel * inputH;
		} else {
			if (xSpeed < 0) xSpeed = min(xSpeed+fric, 0); else xSpeed = max(xSpeed-fric, 0);
		}
		xSpeed = clamp(xSpeed, -moveSpeed, moveSpeed);
	}
	
	// gravity
	ySpeed += grav;
	
	// collisions
	var vx = sign(xSpeed), vy = sign(ySpeed), _col;
	_col = instance_place(x+xSpeed, y, objSolid);
	if (_col != noone) {
		repeat(abs(xSpeed) + 1) {
			if (place_meeting(x + vx, y, objSolid)) break;
			x += vx;
		}
		xSpeed = 0;
	}
	x += xSpeed;
	
	_col = instance_place(x, y+ySpeed, objSolid);
	if (_col != noone) {
		repeat(abs(ySpeed) + 1) {
			if (place_meeting(x, y + vy, objSolid)) break;
			y += vy;
		}
		ySpeed = 0;
	}
	y += ySpeed;
	
	onGround = place_meeting(x, y+1, objSolid);
	if (y > room_height) {
		x = xstart;
		y = ystart;
	}
});

// Idle
fsmChar.AddState("Idle", {
	onStep : function() {
		//show_debug_message("calling Idle onStep");
	},
	onEnter : function() {
		sprite_index = sprPlayerIdle;
		image_speed = 0.25;
		
	},
	onExit : function() {
		
	}
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
});

// Jump
fsmChar.AddState("Jump", {
	onStep : function() {
		if (ySpeed > 0) image_index = 1; else image_index = 0;
		// multiple double jumps
		//if (inputJump) ySpeed = jumpSpeed;
	},
	onEnter : function() {
		sprite_index = sprPlayerJump;
		image_speed = 0;
		ySpeed = jumpSpeed;
	},
});

// Dash
fsmChar.AddState("Dash", {
	onStep : function() {
		xSpeed = lengthdir_x(dashSpeed, dashAngle);
		ySpeed = lengthdir_y(dashSpeed, dashAngle);
		dashTimer -= 1; //|| place_meeting(x+xSpeed, y+ySpeed, objSolid)
	},
	onEnter : function() {
		sprite_index = sprPlayerJump;
		image_speed = 0;
		grav = 0;
		var _dir = point_direction(0, 0, sign(image_xscale), inputV);
		dashAngle = round(_dir * 8) / 8;
		moveSpeed = moveSpeedOnDash;
	},
	onExit : function() {
		grav = gravBase;
		dashTimer = dashTimerBase;
		moveSpeed = moveSpeedBase;
	}
});


// Create Transitions
fsmChar.AddTransition("Idle", "Walk", function() {
	return (inputH != 0);
});
fsmChar.AddTransition("Idle", "Jump", function() {
	return (onGround && inputJump);
});
fsmChar.AddTransition("Walk", "Idle", function() {
	return (inputH == 0);
});
fsmChar.AddTransition("Walk", "Jump", function() {
	return (onGround && inputJump);
});
fsmChar.AddTransition("Jump", "Idle", function() {
	return (onGround);
});
fsmChar.AddTransition("Jump", "Dash", function() {
	return (inputDash);
});
fsmChar.AddTransition("Dash", "Idle", function() {
	return (dashTimer < 0 || place_meeting(x+xSpeed, y+ySpeed, objSolid));
});


// --------------------------
// add trigger states [optional / test]
/*fsmChar.AddState("IdleTrigger1", {
	onStep : function() {
		//show_debug_message("calling IdleTrigger1 onStep");
	},
	onEnter : function() {
		show_debug_message("Idle Tg Enter");
	},
	onExit : function() {
		show_debug_message("Idle Tg Exit");
	},
});
fsmChar.AddState("IdleTrigger2", {
	onEnter : function() {
		show_debug_message("Idle Tg2 Enter");
	},
});

fsmChar.AddTrigger("Idle", "IdleTrigger1");
//fsmChar.AddTrigger("Idle", "IdleTrigger2");

//fsmChar.OverrideState("IdleTrigger1", "Walk");
//fsmChar.OverrideStateFunction("Walk", fsmChar.GetState("IdleTrigger1").onStep);
*/

