main()
{
	if(level.map == "wawa_3daim")
	{
		maps\mp\gametypes\maps\wawa_3daim\_waypoints::main();
	}
	else if(level.map == "mp_railyard")
	{
		maps\mp\gametypes\maps\mp_railyard\_waypoints::main();
	}
	else if(level.map == "mp_carentan")
	{
		maps\mp\gametypes\maps\mp_carentan\_waypoints::main();
	}
	else if(level.map == "mp_harbor")
	{
		maps\mp\gametypes\maps\mp_harbor\_waypoints::main();
	}
}