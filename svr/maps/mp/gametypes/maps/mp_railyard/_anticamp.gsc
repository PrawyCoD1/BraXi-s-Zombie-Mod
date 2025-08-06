main()
{

	blocker = [];

	blocker[0] = spawnstruct();
	blocker[0].origin = (-57.67, 24.40, 231.67);

	blocker[1] = spawnstruct();
	blocker[1].origin = (-59.48, 216.49, 239.72);

	blocker[1] = spawnstruct();
	blocker[1].origin = (-1855.23, -1109.13, 274.13);



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