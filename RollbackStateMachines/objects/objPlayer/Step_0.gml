
// run state machine behaviour
fsmChar.Update(id, "characterState");

// ===================================

/*
if keyboard_check_pressed(ord("N")) {
	characterState = 0;
}
if keyboard_check_pressed(ord("M")) {
	characterState = 1;
}

if keyboard_check_pressed(ord("J")) {
	fsmChar.SetState(0); // does not work here if you are using transitions!!!
}
if keyboard_check_pressed(ord("K")) {
	fsmChar.SetState(1);
}
*/

if keyboard_check_pressed(ord("P")) {
	fsmChar.SetStateFromHistory(1);
}
