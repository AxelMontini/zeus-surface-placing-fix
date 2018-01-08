# ZEUS Surface Placing Fix
### Place what you want, *where* you want.
Yep, also on the new aircraft carrier (USS Freedom).
## How can I use it?
First, put the source code in the mission folder.
Then put `_handler = [] execVM "SurfacePlacingFix\initSurfacePlacingFix.sqf";` in the
file `init.sqf` to automatically run it for every Zeus player once the mission loads.
## How can I customize it?
You can provide arguments to the script when initializing it, for example
`... = ["ACCURATE_AREA", myTrigger] execVM ...` or `... = [LINE_EVERYWHERE"] execVM ...`,
depending on your needs. Area methods need a trigger as second parameter, which is the area
in which the script will work. Everywhere methods work everywhere, with their pros and cons.
Available methods right now are:
* AREA_DIRECT: Works in a specific area, not accurate nor reliable.
* AREA_LINE: Works in a specific area, kinda accurate but not always reliable.
* LINE_EVERYWHERE: Kinda accurate but not always reliable.
* ACCURATE_AREA: Works in a specific area, very accurate but not always reliable.
* ACCURATE_EVERYWHERE: ***[Default]*** Very accurate but not always reliable.  
In short, set up the script, choose your method, (place your trigger) and use it.
## Known issues
Vehicles get sometimes spawned higher than the terrain. This behavior isn't documented
and must be examined in order to fix this problem.
