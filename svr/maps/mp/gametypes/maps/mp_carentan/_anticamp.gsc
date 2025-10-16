main()
{

	blocker = [];

	blocker[0] = spawnstruct();
	blocker[0].origin = (1372.58,1232.87,128.125);

	blocker[1] = spawnstruct();
	blocker[1].origin = (618.85,532.602,197.515);

	blocker[1] = spawnstruct();
	blocker[1].origin = (-678.652,2470.5,216.667);

	blocker[2] = spawnstruct();
	blocker[2].origin = (-456.5,2484.71,89.3496);



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