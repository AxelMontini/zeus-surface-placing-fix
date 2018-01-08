/*
*	Surface Placing Fix init file - Version 1.0 unstable
*
*/

//WARNING: Unreliable with vehicles, since their placing position is not always the cursor; they get spawned where there is enough room.
_mode = param[0, "ACCURATE_EVERYWHERE"];	//Optional: Modes: AREA_DIRECT, AREA_LINE, LINE_EVERYWHERE, ACCURATE_AREA, ACCURATE_EVERYWHERE (default)

SF_AREA = param[1, objNull];		/*OPTIONAL The trigger area*/


PREVIOUS_PLACED = objNull;
PREVIOUS_PLACED_POS = objNull;

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

//Place on the object at chosen elevation (trigger pos), with fixed 2d positioning. Limited to the trigger area.
_codeAreaLine = {
	if (not (getPosASL _this select 1) inArea SF_AREA) exitWith {};
	_h = _this spawn _codeEverywhereLine;
};

//Accurate line-intersect method. Instead of using the zeus->object virtual line for surface detection, it uses the cursor pointing position.
_codeEverywhereAccurate = {
	_cur = (_this select 1);
	//If this is not the first group member, prevent overlapping
	if((group PREVIOUS_PLACED) == (group (_this select 1))) then {
		_posLead = getPosASL PREVIOUS_PLACED;
		_posOldLead = PREVIOUS_PLACED_POS;
		_oldPos = getPosASL _cur;
		//New position based on the previous one (keep formation and distance)
		_newX = (_posLead select 0) - (_posOldLead select 0) + (_oldPos select 0);
		_newY = (_posLead select 1) - (_posOldLead select 1) + (_oldPos select 1);
		_tmpZ = (_posLead select 2) - (_posOldLead select 2) + (_oldPos select 2);

		//Find actual height by checking the terrain below the object.
		_intersections = lineIntersectsSurfaces [[_newX, _newY, _tmpZ], [_newX, _newY, 0]];
		if((count _intersections) != 0) then {	//Prevent out of bounds exception
			//Get the actual pos below the player
			_placeHeight = ((_intersections select 0) select 0) select 2;
			_cur setPosASL [_newX, _newY, _placeHeight];
			hintSilent "Fixed member position (Found intersection)";
		} else { //If no intersections, set new position and hope for the best
			_cur setPosASL [_newX, _newY, _newZ];
			hintSilent "Fixed member position (No intersections found)";
		};
	} else {	//If not
		_pos = AGLtoASL screenToWorld getMousePosition;	//ASL pos of cursor into the world, getting mouse 2D coords
		_intersections = lineIntersectsSurfaces [getPosASL curatorCamera, _pos];

		//Update "PREVIOUS_PLACED" fields, to later handle group members.
		PREVIOUS_PLACED = _cur;
		PREVIOUS_PLACED_POS = getPosASL PREVIOUS_PLACED;

		if((count _intersections) != 0) then {	//Prevent out of bounds exception
			_placePos = ((_intersections select 0) select 0);
			//Get height by intersecting with the terrain again
			_intTerr = lineIntersectsSurfaces [_placePos, [_placePos select 0, _placePos select 1, 0]];
			if((count _intTerr) != 0) then {	//Prevent out of bounds exception
				//Get the actual pos below the player
				_placeHeight = ((_intTerr select 0) select 0) select 2;
				_cur setPosASL [_placePos select 0, _placePos select 1, _placeHeight];
				hintSilent "Fixed position (Found intersection)";
			} else { //If no intersections, set new position and hope for the best
				_cur setPosASL _placePos;
				hintSilent "Fixed position (Found partial intersection)";
			};
		} else {
			_cur setPosASL [_pos select 0, _pos select 1, (_pos select 2)];	//Add some elevation, the placed thing might be placed inside a surface.
			hintSilent "Fixed position (No intersections found)";
		};
	};
};

//Accurate line-intersect method. Instead of using the zeus->object virtual line for surface detection, it uses the cursor pointing position.
_codeAreaAccurate = {
	_obj = _this select 1;
	_pos = getPosASL _obj;
	if(not (_pos inArea SF_AREA)) exitWith {};	//Exit if not in area
		//If in area, spawn the code. // _this spawn function doesn't work? WTF ARMA?
	_h = [objNull, ] spawn _codeEverywhereAccurate;
};

//::::::::::::::::::
// HOOK CODE BLOCKS
//::::::::::::::::::

//Add event handler to the logic
											/*OLD-_> */
(getAssignedCuratorLogic player) addEventHandler ["CuratorObjectPlaced", switch(_mode) do {case "AREA_DIRECT":{_codeAreaDirect}; case "AREA_LINE":{_codeAreaLine}; case "LINE_EVERYWHERE":{_codeEverywhereLine}; case "ACCURATE_AREA":{_codeAreaAccurate}; default {_codeEverywhereAccurate};}];
hintSilent format["Added Surface Placing Fix event handler! Method:'%1'", _mode];
