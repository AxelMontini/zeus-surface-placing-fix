/*
*	Surface Placing Fix init file - Version 0.0.2 - Made by Axel Montini
*
*/

//WARNING: Unreliable with vehicles, since their placing position is not always the cursor; they get spawned where there is enough room.

//behaviour, in order:
// - Sets the right height to the created object: doesn't fix the wrong XY positioning. Might result in bad things.
// - Sets the right elevation and fixes (tries to, at least) XY positioning. Works only in given area.
// - Works as the previous one, but doesn't need an AREA argument: works everywhere, not only on the ship. CHANGES DEFAULT PLACING BEHAVIOUR, RISKY BUT MIGHT BE GOOD.
_mode = param[0, "ACCURATE_EVERYWHERE"];	//Optional: Modes: AREA_DIRECT, AREA_LINE, LINE_EVERYWHERE, ACCURATE_AREA, ACCURATE_EVERYWHERE (default)

SF_AREA = param[1, nil];		/*OPTIONAL The trigger area -- Must be on the deck -
								Every object placed inside it will be moved at a certain elevation*/

//Get elevation of the trigger
SF_ELEVATION = if(isNil "SF_AREA") then {0} else {(getPosASL SF_AREA) select 2};


PREVIOUS_PLACED = objNull;

if (isDedicated) exitWith {};	//Exit if server
waitUntil {!isNull player};	//wait for the player to be spawned
//REMOVED		if ((allCurators find player) == -1) exitWith {};	//exit if the player is not a curator
//Local effect

//Note: HANDLER must NOT be added to the PLAYER, but to the CURATOR MODULE.
//wait to be sure
waitUntil {!isNull (getAssignedCuratorLogic player)};

//::::::::::::::::::
//DEFINE CODE BLOCKS
//::::::::::::::::::

//Place on the object at chosen elevation (trigger pos), with fixed 2d positioning. Limited to the trigger area.
_codeAreaLine = {
	_pos = getPosASL (_this select 1);
	
	_intersections = lineIntersectsSurfaces [getPosASL curatorCamera, _pos];
	
	{	//When the line intersects an object at given altitude
		if ((round(((_x select 0)) select 2)) == (round(SF_ELEVATION))) then {
			//If right height and position in area, then
			if((((_x select 0)) inArea SF_AREA)) exitWith {
				(_this select 1) setPosASL (_x select 0);
			};
		};
	} forEach _intersections;
	
	hintSilent "Fixed position! (Line-intersect method with height filter)";
};
//Fix the height, but the positioning will not be right if compared with the chosed position in-game)
_codeAreaDirect = {
	_pos = getPosASL (_this select 1);
	if(not (_pos inArea SF_AREA)) exitWith {};
	(_this select 1) setPosASL [_pos select 0, _pos select 1, SF_ELEVATION];
	hintSilent "Fixed position! (Direct-height method)";
};
//Executes everywhere, when the trigger is nil. Works like _codeAreaLine, but without zone limitations
_codeEverywhereLine = {
	_pos = getPosASL (_this select 1);
	_intersections = lineIntersectsSurfaces [getPosASL curatorCamera, _pos];
	
	_placePos = ((_intersections select 0) select 0);
	(_this select 1) setPosASL _placePos;
	
	hintSilent "Fixed position! (Line-intersect method)";
};

//Accurate line-intersect method. Instead of using the zeus->object virtual line for surface detection, it uses the cursor pointing position.
_codeEverywhereAccurate = {
	_pos = AGLtoASL screenToWorld getMousePosition;	//ASL pos of cursor into the world, getting mouse 2D coords
	_intersections = lineIntersectsSurfaces [getPosASL curatorCamera, _pos];
	
	//If tthis is not the first group member, prevent overlapping
	if((group PREVIOUS_PLACED) == (group (_this select 1))) then {
		_pos = getPosASL PREVIOUS_PLACED;
			//Use random positioning to prevent overlapping
		(_this select 1) setPosASL [(_pos select 0) + random [-1.5, 0, 1.5], (_pos select 1) + random [-1.5, 0, 1.5], (_pos select 2)];
		hintSilent "Fixed position! (Accurate Line-intersect method), approximating position relative to GROUP LEADER.";
	} else {	//If not 
		if((count _intersections) != 0) then {	//Prevent out of bounds exception
			_placePos = ((_intersections select 0) select 0);
			(_this select 1) setPosASL [_placePos select 0, _placePos select 1, (_placePos select 2) + 0.2];
		} else {
			(_this select 1) setPosASL [_pos select 0, _pos select 1, (_pos select 2) + 0.2];	//Add some elevation, the placed thing might be placed inside a surface.
		};
		hintSilent format["Fixed position! (Accurate Line-intersect method), %1 surfaces detected", count _intersections];
	};
	
	PREVIOUS_PLACED = (_this select 1);	//Set new "previous placed"
	
	
};

//Accurate line-intersect method. Instead of using the zeus->object virtual line for surface detection, it uses the cursor pointing position.
_codeAreaAccurate = {
	_pos = AGLtoASL screenToWorld getMousePosition;	//ASL pos of cursor into the world, getting mouse 2D coords
	
	if(not (_pos inArea SF_AREA)) exitWith {};	//Exit if not in area
	
	_intersections = lineIntersectsSurfaces [getPosASL curatorCamera, _pos];
		
	if((count _intersections) != 0) then {	//Prevent out of bounds exception
		_placePos = ((_intersections select 0) select 0);
		(_this select 1) setPosASL [_placePos select 0, _placePos select 1, (_placePos select 2) + 0.2];
	} else {
		(_this select 1) setPosASL [_pos select 0, _pos select 1, (_pos select 2) + 0.2];	//Add some elevation, the placed thing might be placed inside a surface.
	};
	
	hintSilent format["Fixed position! (Accurate Line-intersect method), %1 surfaces detected", count _intersections];
};

//::::::::::::::::::
// HOOK CODE BLOCKS
//::::::::::::::::::

//Add event handler to the logic
											/*OLD-_> */
(getAssignedCuratorLogic player) addEventHandler ["CuratorObjectPlaced", switch(_mode) do {case "AREA_DIRECT":{_codeAreaDirect}; case "AREA_LINE":{_codeAreaLine}; case "LINE_EVERYWHERE":{_codeEverywhereLine}; case "ACCURATE_AREA":{_codeAreaAccurate}; default {_codeEverywhereAccurate};}];
hintSilent format["Added Surface Placing Fix event handler! Method:'%1'", _mode];