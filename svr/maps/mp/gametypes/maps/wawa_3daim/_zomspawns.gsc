main()
{
	level.spawnpoints = [];

	spawns = getentarray( "mp_deathmatch_spawn", "classname" );

	for(i = 0; i < spawns.size; i++)
		level.spawnpoints[i] = spawns[i];

}