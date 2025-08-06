main()
{

	blocker = [];

	blocker[0] = spawnstruct();
	blocker[0].origin = (-9211.13,-7901.6,226.125);

	blocker[1] = spawnstruct();
	blocker[1].origin = (-8832.88,-8106.04,248.125);

	blocker[1] = spawnstruct();
	blocker[1].origin = (-8898.98,-8809.5,225.147);

	blocker[2] = spawnstruct();
	blocker[2].origin = (-9528.88,-8941.65,208.125);



	while(1)
	{

		players = getentarray("player", "classname");
		for(i=0; i<players.size; i++)
		{
			for(n=0; n<blocker.size; n++)
			{
				if(distance(players[i].origin, blocker[n].origin) <= 40 && players[i].sessionstate != "spectator")
				{
					if(!players[i].camp_moving)
						players[i] thread movehim();
				}
			}
		}

	wait 0.01;
	}
}
movehim()
{
	self.camp_moving = true;
	wait 0.01;
	self iprintlnBold("^7Camping here is ^1not allowed^7!");
	spawns = getentarray( "mp_teamdeathmatch_spawn", "classname" );
	num = randomInt(spawns.size);
	wait 0.7;
	self setOrigin( spawns[num].origin );
	wait 0.01;
	self.camp_moving = false;
}