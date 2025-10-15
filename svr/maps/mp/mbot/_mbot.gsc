//======================================================
//  Call of Duty: MeatBot v0.2 Pre-Alpha
//
//  MeatBot Author: Maks Deryabin
//  Additional Coding: Cepe7a, asdfg
//
//  Additional PeZBOT Code: Perry Hart
//
//  CoD1 Port & Additional: ATB
//======================================================

Init()
{
	setCVar("g_antilag","0");
	
	level.mbotsnumber = maps\mp\gametypes\_util::cvardef("cod_mbot_amount1", 8, 0, 32, "int");
	level.mbotsnumber2 = maps\mp\gametypes\_util::cvardef("cod_mbot_amount2", 8, 0, 32, "int");
	level.pbotsnumber = maps\mp\gametypes\_util::cvardef("cod_pbot_amount1", 8, 0, 32, "int");
	level.pbotsnumber2 = maps\mp\gametypes\_util::cvardef("cod_pbot_amount2", 8, 0, 32, "int");
	level.bot_battlechatter = maps\mp\gametypes\_util::cvardef("bot_battlechatter", 1, 0, 3, "int");
	level.bot_unlimitedammo = maps\mp\gametypes\_util::cvardef("bot_unlimitedammo", 1, 0, 1, "int");
	level.bot_headicon = maps\mp\gametypes\_util::cvardef("bot_headicon", 1, 0, 1, "int");
	level.bot_wptype = maps\mp\gametypes\_util::cvardef("bot_waypointtype", 0, 0, 1, "int");
	level.bot_camptime = maps\mp\gametypes\_util::cvardef("bot_camptime", 6, 0, 120, "int");
	level.bot_3rdpersonspec = maps\mp\gametypes\_util::cvardef("bot_3rdpersonspec", 6, 0, 120, "int");
	level.bot_astarsearch = maps\mp\gametypes\_util::cvardef("bot_astarsearch", 1, 0, 1, "int");
	level.bot_autobalance = maps\mp\gametypes\_util::cvardef("bot_autobalance", 0, 0, 1, "int");
	
	level.maxroundCount = getcvarint("cod_bot_roundCount", 2, 0, 32, "int");
	level.roundCount = getcvarint("tdm_roundCount", 0, 0, 32, "int");

	if (getCvar("bot_drawrange") == "")
	    setCvar("bot_drawrange", 1000);
	
	if(getCvar("bot_battlechatter") == "")
		setCvar("bot_battlechatter", "1");
	
	if (getCvar("bot_spawningtype") == "")
	    setCvar("bot_spawningtype", "1");

	if (level.bot_battlechatter == 1){ level.freqadda = 2;}
	if (level.bot_battlechatter == 2){ level.freqadda = 4;}
	if (level.bot_battlechatter == 3){ level.freqadda = 10;}
	
	level.botskill = 10;

	level.velsqr = [];
	addvelsqr(12, 0.17);
	addvelsqr(25, 0.25);
	addvelsqr(37, 0.31);
	addvelsqr(50, 0.36);
	addvelsqr(75, 0.44);
	addvelsqr(100, 0.51);
	addvelsqr(125, 0.56);
	addvelsqr(150, 0.62);
	addvelsqr(175, 0.67);
	addvelsqr(200, 0.71);
	addvelsqr(250, 0.8);
	addvelsqr(300, 0.88);
	addvelsqr(350, 0.94);
	addvelsqr(400, 1.01);
	addvelsqr(450, 1.07);
	addvelsqr(500, 1.13);
	addvelsqr(600, 1.21);
	addvelsqr(650, 1.29);
	addvelsqr(700, 1.34);
	addvelsqr(750, 1.38);
	addvelsqr(800, 1.43);
	addvelsqr(850, 1.5);
	addvelsqr(900, 1.51);
	addvelsqr(1000, 1.6);
	
	level.botTalking = false;
	level.dumpingpoints = false;

	level.wp = undefined;
    level.wp = [];
	level.botstart = ::botStart;
	level.spawnpoints = getentarray("mp_teamdeathmatch_spawn", "classname");

	setcvar("addbot", "");
	setcvar("removebot", "");
	setcvar("restart", "");
	setcvar("loadmap", "");
	
	map = getCvar("mapname");
	type = getCvar("g_gametype");
  
	if (getcvar("bot_debug") == "")
		setcvar("bot_debug", "0");
		
	if (getcvar("bot_viewangle") == "")
		setcvar("bot_viewangle", "120");
	
	if (getcvar("bot_maxdistance") == "")
		setcvar("bot_maxdistance", 2000);
	
	setCvar("tdm_roundCount", 0);
    bFlag = false;
	if(getCvarInt("bot_debug") == 1) 
	{
		setCvar("logfile", 1);
		setCvar("bot_autowp", "0");
		setcvar("scr_tdm_timelimit", "180");
		if(!level.bot_wptype)
		{
			bFlag = true;
			if (!waypoints\select_map::choose()) 
			{
				if (!waypoints\select_map::choose()) 
					bFlag = false;
				else 
					maps\mp\mbot\_mbot_dev::dumpWPs();
			}
		}
		else
		{
			level.viewofs[0] = (8,8,48);
			level.viewofs[1] = (-8,8,48);
			level.viewofs[2] = (8,-8,48);
			level.viewofs[3] = (-8,-8,48);
			level.viewofs[4] = (8,8,32);
			level.viewofs[5] = (-8,8,32);
			level.viewofs[6] = (8,-8,32);
			level.viewofs[7] = (-8,-8,32);
			level.viewofs[8] = (8,8,16);
			level.viewofs[9] = (-8,8,16);
			level.viewofs[10] = (8,-8,16);
			level.viewofs[11] = (-8,-8,16);
			
			waypoints\select_map::choose();
		}
	}
	else
	{
		bFlag = true;
		if(!waypoints\select_map::choose())
			bFlag = false;
		else
			bFlag = true;
	}

	if(!bFlag && getCvarInt("bot_debug") == 0)
		iprintlnbold(&"MBOT_MAPNOTSUPPORT");
	
	if(!level.bot_wptype)
	{
		game["bots"]["axis"] = getcvarint("cod_mbot_amount1");
		game["bots"]["allies"] = getcvarint("cod_mbot_amount2");
	}
	else
	{
		game["bots"]["axis"] = getcvarint("cod_pbot_amount1");
		game["bots"]["allies"] = getcvarint("cod_pbot_amount2");
	}
	
	if (getcvar("bot_forceteam") == "")
	    setcvar("bot_forceteam", 3);
	
	game["bots"]["forceteam"] = maps\mp\gametypes\_util::cvardef("bot_forceteam", 1, 0, 3, "int");
	
	if(randomInt(12) >= 7 && game["bots"]["forceteam"] == 3 || game["bots"]["forceteam"] == 1)
	    game["bots"]["teamswitch"] = true;
	else
	    game["bots"]["teamswitch"] = false;
		
	if(game["bots"]["teamswitch"])
	{
		if(!level.bot_wptype)
		{
			setcvar("cod_mbot_amount2", game["bots"]["axis"] );
			setcvar("cod_mbot_amount1", game["bots"]["allies"] );
		}
		else
		{
			setcvar("cod_pbot_amount2", game["bots"]["axis"] );
			setcvar("cod_pbot_amount1", game["bots"]["allies"] );
		}
		game["bots"]["playerteam"] = "axis";
		game["bots"]["otherteam"] = "allies";
	}
	else
	{
		if(!level.bot_wptype)
		{
			setcvar("cod_mbot_amount2", game["bots"]["allies"] );
			setcvar("cod_mbot_amount1", game["bots"]["axis"] );
		}
		else
		{
			setcvar("cod_pbot_amount2", game["bots"]["allies"] );
			setcvar("cod_pbot_amount1", game["bots"]["axis"] );
		}
		game["bots"]["playerteam"] = "allies";
		game["bots"]["otherteam"] = "axis";
	}
	
	game["bots"]["teamcount"] = game["bots"]["allies"];
	
	
	
	if(getCvar("skill") == "")
		setCvar("skill", "10");
	else if (getCvarInt("skill") > 10 || getCvarInt("skill") < 0)
		setCvar("skill", "10");
	SetSkill(getCvarInt("skill"));

	level.movespeed = 190;

	level.bots_al = 0;
	level.bots_ax = 0;
	bots_al = getCvarInt("scr_tmpbotsal");
	bots_ax = getCvarInt("scr_tmpbotsax");
	
	if(getCvarInt("g_playerCollisionEjectSpeed") != 85)
			setCvar("g_playerCollisionEjectSpeed", 85);

	level.maprotate = getCvar("sv_mapRotationCurrent");

	level thread waitPlayer();
}

getBotCount(team)
{
    teamBotPlayers = [];
	players = getentarray("player", "classname");
	if(players.size > 0)
	{
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isdefined(player) && isdefined(player.isbot) && player.pers["team"] == team)
			    teamBotPlayers[teamBotPlayers.size] = player;
		}
		return teamBotPlayers.size;
	}
	else
	    return 0;
}

getRandomPlayer(team)
{
    pickedPlayer = undefined;
	availPlayers = [];
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		if(players.size == 0)
		    return;
		else
		{
			if(isdefined(players[i]) && isdefined(players[i].isbot) && players[i].pers["team"] == team)
				availPlayers[availPlayers.size] = players[i];
		}
	}
	
	if(availPlayers.size >= 1)
		pickedPlayer = availPlayers[randomInt(availPlayers.size)];

	return pickedPlayer;
}

dvarCheck()
{
	level endon("intermission");

	for(;;)
	{
		while(level.dumpingpoints)
		    wait 0.5;

		tmp = getCvarInt("skill");
		if(tmp != level.botskill)
			setSkill(tmp);

		if(getCvar("restart") == "map")
		{
			map = getCvar("mapname");
			type = getCvar("g_gametype");
     
			if(mapIsSupportBots(map, type))
			{
				loadMap(map, type);
				break;
			}
			else
			{
				println("Map ", map, "don't support bots in \"", type, "\"");
				setCvar("restart", "");
			}
		}
		else if(getCvar("restart") == "fast")
			map_restart(false);
		else
			setCvar("restart", "");

		if(getCvar("loadmap") != "")
		{
			map = getCvar("loadmap");
			type = getCvar("g_gametype");
			loadMap(map, type);
			setCvar("loadmap", "");
		}

		if(getCvarInt("bot_debug") != 1)
			setCvar("sv_cheats", 0);

		if(getCvar("scr_tmpmaprotation") != level.maprotate)
			setCvar("scr_tmpmaprotation", level.maprotate);
		if(getCvarInt("scr_tmpbotsal") != level.bots_al)
			setCvar("scr_tmpbotsal", level.bots_al);
		if(getCvarInt("scr_tmpbotsax") != level.bots_ax)
			setCvar("scr_tmpbotsax", level.bots_ax);
    	if(getCvarInt("g_speed") != 190)
			setCvar("g_speed", 190);
		if(getCvarInt("sv_fps") != 20)
			setCvar("sv_fps", 20);

		wait 0.25;
	}
}

waitPlayer()
{
	while(1)
	{
		players = getentarray("player", "classname");
		for(i=0; i<players.size; i++)
		{
			player = players[i];
			if ((!isDefined(level.plr) || !isPlayer(level.plr)) && !IsDefined(player.isbot))
			{
				level.plr = player;
				if(getCvarInt("bot_debug") == 1)
				{
					if(!level.bot_wptype)
					    player thread maps\mp\mbot\_mbot_dev::init();
					else
					    player thread maps\mp\mbot\_mpez_dev::init();
				}
				player waittill("disconnect");
				wait 0.5;
				level.plr = undefined;
				break;
			}
		}
		wait 0.5;
	}
}

botStart()
{
	self notify("end_botstart");
	self endon("end_botstart");
	self endon("disconnect");
  
	for(;;)
	{
		self waittill("bot_spawned");
		self waittill("killed_player");

		if(isdefined(self.botorg))
		{
			self stopMoving();
			self unlink();
			self.botorg delete();
		}
    
		if(self.pers["team"] == "spectator")
			break;
	}
}

StabKnife(dist, target)
{
	self endon("StopShooting");
	self endon("killed_player");
	self endon("disconnect");

	target.position = target.origin + vectorScale(anglesToForward(target.angles),55);

	self takeallweapons();
	self.pers["weapon"] = "bot_melee_mp";
	self giveWeapon(self.pers["weapon"]);
	self giveMaxAmmo(self.pers["weapon"]);
	self setWeaponSlotClipAmmo("primary", 0);
	self setSpawnWeapon(self.pers["weapon"]);
	self switchToWeapon(self.pers["weapon"]);
    
	switch(game[self.pers["team"]])
	{
		case "american":
			suffix = "_american";
			num = 7;
			break;
		case "british":
			suffix = "_british";
			num = 6;
			break;
		case "russian":
			suffix = "_russian";
			num = 6;
			break;
		case "german":
			suffix = "_german";
			num = 3;
			break;
		default:
			suffix = "_american";
			num = 7;
			break;
	}
	
	self playsound("generic_meleeattack_" + suffix + "_" + (randomInt(num)+1));
	wait 0.05;
	
	if(target.sessionstate == "playing")
        self thread DoDamage(target);
		
	//self ChangeWeapon(self.pweapon, "walk2");
    self notify("StopShooting");
}

DoDamage(target)
{
    wait 0.9;
	if(isAlive(self))
	    target thread [[level.callbackPlayerDamage]](self, self, 50, 0, "MOD_MELEE", "bot_melee_mp", self.origin, self.origin, "none");
}

botMainLoop()
{
	self endon("killed_player");
	self endon("disconnect");
	
	while((!isdefined(self.pers["team"])) || self.sessionstate != "playing")
	  wait 0.05;

	//self ChangeWeapon(self.pweapon, "walk2");
	
	self.bShooting = false;
	wait 1;
  
	self.state = "done";
	self.alert = false;
	self.next = undefined;
	self.enemy = undefined;
	self.skiprotate = undefined;
	self.flankSide = (randomIntRange(0,2) - 0.1) * 2.0;
    self.findSolution = false;
	self.isConfused = 0;
	self thread checkEnemy();
	self thread BotWaypointProgress();

	for(;;)
	{
		switch(self.state)
		{
			case "idle":
				if(!self.alert)
				{
					while(!isdefined(self.next))
					    wait 0.05;
					
					if(self.next.type != "w" || !isdefined(self.next.type))
						self mbot_stopLoopSound();
            
					switch(self.next.type)
					{
						case "w":
							self.state = "move";
							self.next = self getNextNode();
							if(isDefined(self.next) && isDefined(self.next.origin))
								self thread goToNode(self.next.origin);
							break;
							
						case "g":
							self.state = "move";
							self.next = self getNextNode();
							if(isDefined(self.next) && isDefined(self.next.origin))
								self thread goToNode(self.next.origin);
							break;
							
						case "f":
							self.state = "fall";
							self thread fallGravity();
							break;
							
						case "c":
							if(randomInt(3))
							{
								self.state = "camp";
								//time = randomInt(level.bot_camptime) + 2;
								self thread makeCamp(getCvar("bot_camptime"));
							}
							else
								self.state = "done";
							break;
							
						case "j":
							self.state = "jump";
							self thread jumpGravity();
							break;
							
						case "m":
							self.state = "mantle";
							self thread doMantle();
							break;
							
						case "l":
							self.state = "climb";
							self thread climbUp();
							break;
					}
				}
				else
				{
					wait 1;
					self thread checkEnemy();
				}
				break;
				
			case "move":
				if(self.alert)
				{
					self thread StopMoving();

					for(;;)
					{
						if(self.alert)
						{
							targetRange = distance(self.origin, self.enemy.origin);

					        if(targetRange < 100)
							{
								self thread StabKnife(dist, self.nearestTarget);
								self waittill("StopShooting");
							}
							
					        if(RandomInt(8) == 1)
							{
								if(randomInt(5) == 1)
								{
									if(targetRange > 800 && (randomInt(2) == 1))
									{
	                                    if(randomInt(6) == 2) teamchatter("threat_infantry_panzerfaust", "allies");
										//self setweaponslot("walk2", 0, 0);
										self thread checkEnemy();
									}
									else
									if(targetRange > 500 && targetRange < 800)
			                    	{
							        	if(level.bot_battlechatter && randomInt(2*level.freqadda) == 1 && self.sessionstate == "playing" && level.botTalking == false)
											self thread botPlaySound(self.natprefix + "_mp_grenade");
							        	//self setweaponslot("walk2", 0, 0);
							        	self thread checkEnemy();
			                    	}
									else
									{
										//self setweaponslot("close", 999, 999);
										wait 0.01;
							        	wait randomIntrange(1,2);
							        	//self setweaponslot("walk2", 0, 0);
							        	self thread checkEnemy();
									}
								}
								else
								{
									if(targetRange > 1000 && targetRange < 1400)
			                    	{
							        	if(level.bot_battlechatter && randomInt(2*level.freqadda) == 1 && self.sessionstate == "playing" && level.botTalking == false)
											self thread botPlaySound(self.natprefix + "_mp_grenade");
							        	//self setweaponslot("walk2", 0, 0);
							        	self thread checkEnemy();
									}
									else if(targetRange > 600 && targetRange < 900)
			                    	{
								    	grenadetype = self.botgrenade2;
							        	if(level.bot_battlechatter && randomInt(2*level.freqadda) == 1 && self.sessionstate == "playing" && level.botTalking == false)
											self thread botPlaySound(self.natprefix + "_mp_grenade");
							        	//self setweaponslot("walk2", 0, 0);
							        	self thread checkEnemy();
			                    	}
									else
									{
										//self setweaponslot("close", 999, 999);
							        	wait 0.01;
							        	wait randomIntrange(1,2);
							        	//self setweaponslot("walk2", 0, 0);
							        	self thread checkEnemy();
									}
								}
							}
							else
							{
								//self setweaponslot("close", 999, 999);
							    wait 0.01;
							    wait randomIntrange(1,2);
							    //self setweaponslot("walk2", 0, 0);
							    self thread checkEnemy();
							}
							break;
						}
						else
						{
							wait randomFloat(1) + 0.5;
							if(!self.alert)
							    //self setweaponslot("walk2", 0, 0);
								break;
						}
					}

					self.state = "move";
					if(isDefined(self.next) && isDefined(self.next.origin))
						self thread goToNode(self.next.origin);
					break;
				}
				wait .01;
				break;
				
				if(checkBotCollision())
				{
					self thread StopMoving();

					self.pclipammo = self getweaponslotclipammo("primary");
					//self setweaponslot("walk2", 0, 0);
          
					for(;;)
					{
						if(self.state != "camp")
							self.state = "camp";

						if(checkBotCollision())
							wait randomFloat(1) + 0.1;
						else
						{
							wait 1;
							if(!(checkBotCollision()))
								break;
						}
					}

					//self setweaponslot("walk2", 0, 0);
					self.state = "move";
					if(isDefined(self.next) && isDefined(self.next.origin))
						self thread goToNode(self.next.origin);
					break;
				}
				
			case "done":
				self.state = "move";
				self.next = self getNextNode();
				if(isDefined(self.next) && isDefined(self.next.origin))
					self thread goToNode(self.next.origin);
				break;
				
			default:
				wait .01;
				break;
		}    
	}
}

getWeaponRange(weapon)
{
    if(!isdefined(weapon))
	    return 1900;
		
	switch(weapon)
	{
	    case "mp40":range = 1900;break;
		case "mp44":range = 1900;break;
		case "kar98k":range = 3500;break;
		case "gewehr43":range = 2500;break;
		case "m1carbine":range = 3000;break;
		case "thompson":range = 2000;break;
		case "bar":range = 3000;break;
		case "m1garand":range = 3500;break;
		case "sten":range = 2000;break;
		case "bren":range = 3500;break;
		case "enfield":range = 3500;break;
		case "svt40":range = 3500;break;
		case "ppsh":range = 2000;break;
		case "mosin_nagant":range = 3500;break;
		default:range = 3500;break;
	}

	return range;
}

VisibleMark(player, checkallsurface)
{
	if (!isDefined(player))
		return undefined;
		
	eye = self.mark[1].origin;
	if (!isalive(player) || !isDefined(player.mark))
		return undefined;
        
	bot_maxdist = self getWeaponRange(self.pweapon);
	if (bot_maxdist < 1900)
		bot_maxdist = 1900;

	dist = distance(eye, player.mark[1].origin); 
	if (dist > bot_maxdist)
		return undefined;
	
	dist = vectornormalize(player.origin - eye);
	angles = self getplayerangles();
	vfwd = anglestoforward(angles);
	dot = vectordot(vfwd, dist);
	if (dot > 1)
		dot = 1;
		
	viewangle = acos(dot);
	bot_viewangle = getcvarint("bot_viewangle");
	if (viewangle > bot_viewangle)
		return undefined;
   
	for(j = 0; j < player.mark.size; j++)
	{
		if (sighttracepassed(eye, player.mark[j].origin, true, self)) 
		{
			trace = bullettrace(eye, player.mark[j].origin, true, self);

			if (checkallsurface && trace["surfacetype"] != "default" && trace["surfacetype"] != "none" && trace["surfacetype"] != "foliage" && trace["surfacetype"] != "asphalt" && trace["surfacetype"] != "wood" && trace["surfacetype"] != "gravel" && trace["surfacetype"] != "concrete" && trace["surfacetype"] != "paper" && trace["surfacetype"] != "sand" && trace["surfacetype"] != "mud" && trace["surfacetype"] != "plaster" && trace["surfacetype"] != "snow" && trace["surfacetype"] != "water" && trace["surfacetype"] != "dirt" && trace["surfacetype"] != "bark" && trace["surfacetype"] != "grass" && trace["surfacetype"] != "rock" && trace["surfacetype"] != "metal" && trace["surfacetype"] != "cloth" && trace["surfacetype"] != "brick" && trace["surfacetype"] != "glass")
				return undefined;
						
			return player.mark[j].origin;
		}
	}
	return undefined;
}

checkEnemy()
{
	if(!isdefined(self.isbot))
	    return;
		
	self endon("killed_player");
	self endon("disconnect");
	self.alert = false;
	self.enemy = undefined;
	target = undefined;
	waittarget = 0;
	nearestEnemy = 9999999999;

	for(;;)
	{
		while(isdefined(self.sessionstate) && self.sessionstate != "playing" || !isdefined(self.mark))
	        wait 0.5;
		
		eye = self.mark[1].origin;
		newtarget = undefined; 
		target_mark = undefined;
		friendAttacker  = undefined;
		friendDist = 99999;
		if (isDefined(target) && target.pers["team"] != self.pers["team"] && target.pers["team"] != "spectator")
			target_mark = self VisibleMark(target, true);
		if (isDefined(target_mark))
			newtarget = target;
		else
		{
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if (player.pers["team"] != self.pers["team"] && player.pers["team"] != "spectator")
				{
					self.enemyDist = Distance(self.origin, player.origin); 
					if(self.enemyDist < nearestEnemy)
					{
						nearestEnemy = self.enemyDist;
						self.nearestTarget = player;
					}
					target_mark = self VisibleMark(player, true);	
					if (isDefined(target_mark))
					{
						newtarget = player;
						self.nearestTarget = player;
						break;
					}	
				}
			}
		}
			
		target = newtarget;
		if (isDefined(target)) 
		{
			if (!isDefined(self.enemy) || self.enemy != target)
			{
				self.skiprotate = undefined;
				StopRotate();
				self DoRotateOrg(target_mark, 0.1);
			}
			self.enemy = target;
			if (!self.alert)
			{
				if (self.state == "camp")
				{
					//self setweaponslot("close", 999, 999);
					if(level.bot_wptype)	
						self thread Clamp2Ground();
						
					self.state = "move";
				}
				self.alert = true;
			}

			if (self.state == "idle" || self.state == "move" || self.state == "camp" || self.state == "jump" || self.state == "fall" || self.state == "climb")
			{
				vtarget = vectorNormalize(target_mark - eye);
				self.pclipammo = self getweaponslotclipammo("primary");
				self setPlayerAngles(vectorToAngles(vtarget));
				
			}
			waittarget = randomInt(10)+5; 
        }
		else 
		{
			if (self.alert)
			{
				if (!waittarget || (isDefined(self.enemy) && !isAlive(self.enemy)))
				{
					self.enemy = undefined;
					waittarget = 0;
				}	
				else
				{
					waittarget--;
					continue;
				}
				self.alert = false;
				self.pclipammo = self getweaponslotclipammo("primary");

				if (self.state != "camp"){}
				//else
					//self setweaponslot("walk2", 0, 0);				
			}
			else if (isDefined(friendAttacker) && (self.state == "move" || self.state == "camp"))
			{
				self notify("stoprotate");
				self notify("endrotate");
				wait 0.01;
				angles = friendAttacker getplayerangles();
				// Skill factor already poor even on max
				self thread DoRotateAng(angles, /*randomFloat(1-(level.botskill*0.1))+*/ 0.1);
				self thread BlockRotate(0.05);
			}
		}
		wait level.botwaittime;
	}
}

stopMoving()
{
	self endon("killed_player");
	self notify("stopmove");
	self.skiprotate = undefined;
	self StopRotate(); 

	self mbot_stopLoopSound();
	self.botorg moveto((self.origin + (1, 1, 0)), 0.01, 0, 0);
}

sightTracePassed(eye, mark,character, player)
{
    visTrace = bullettrace(eye, mark, character, player);
    if(visTrace["fraction"] == 1)
        return true;
    else
        return false;
}

addvelsqr(h, sqr)
{
	i = level.velsqr.size;
	level.velsqr[i] = spawnstruct();
	level.velsqr[i].h = h;
	level.velsqr[i].sqr = sqr;
}

getvelsqr(h)
{
	hprev = level.velsqr[0].h;
	for (i=1; i<level.velsqr.size; i++)
	{
		hcur = level.velsqr[i].h;
		if (h > hcur)
		{
			hprev = hcur;
			continue;
		}
		hcur = hprev + ((hcur - hprev) / 2);
		if (h < hcur)
			sqr = level.velsqr[i-1].sqr;
		else
			sqr = level.velsqr[i].sqr;
		return sqr;
	}
	
	return level.velsqr[i-1].sqr;
}

CanSee(target)
{ 
    visTrace = bullettrace(self getEye(), target GetEyePos(), false, "none");
    if(vistrace["fraction"] == 1 && visTrace["surfacetype"]=="none" && visTrace["surfacetype"] != "default" && visTrace["surfacetype"] != "none" && visTrace["surfacetype"] != "foliage" && visTrace["surfacetype"] != "asphalt" && visTrace["surfacetype"] != "wood" && visTrace["surfacetype"] != "gravel" && visTrace["surfacetype"] != "concrete" && visTrace["surfacetype"] != "paper" && visTrace["surfacetype"] != "sand" && visTrace["surfacetype"] != "mud" && visTrace["surfacetype"] != "plaster" && visTrace["surfacetype"] != "snow" && visTrace["surfacetype"] != "dirt" && visTrace["surfacetype"] != "bark" && visTrace["surfacetype"] != "rock" && visTrace["surfacetype"] != "metal" && visTrace["surfacetype"] != "cloth" && visTrace["surfacetype"] != "brick")
        return true;
    else
        return false;
}

GetEyePos()
{
    return (self getEye() + (0,0,20));
}

addBots()
{
	// Wait a bit for the game to fully start
	wait 2;
	
	// Get the number of bots from cvar
	botAmount = getCvarInt("scr_botamount");
	
	// Don't add bots if the cvar is 0
	if(botAmount <= 0)
		return;
	
	// Create a copy of available names to avoid duplicates
	availableNames = [];
	if(isDefined(level.botNames) && level.botNames.size > 0)
	{
		for(j = 0; j < level.botNames.size; j++)
		{
			availableNames[availableNames.size] = level.botNames[j];
		}
	}
	
	// Add the specified number of bots
	for(i = 0; i < botAmount; i++)
	{
		level.bot[i] = addtestclient();
		wait 0.3;

		if(isPlayer(level.bot[i]))
		{
			// Assign random unique name to bot
			if(availableNames.size > 0)
			{
				randomNameIndex = randomInt(availableNames.size);
				level.bot[i] renamebot(availableNames[randomNameIndex]);				// Start ping simulation thread for realistic ping fluctuations
				//level.bot[i] thread simulateLivePing();
				
				// Remove the used name from available names
				availableNames[randomNameIndex] = availableNames[availableNames.size - 1];
				availableNames[availableNames.size - 1] = undefined;
			}
			
			level.bot[i] thread bot2();
		}
	}
}

bot2()
{
	
	if(isdefined(level.wpsize))
	{
	    if(level.wpsize >= 400)
		    level.searchdistance = 1200;
		else
		if(level.wpsize > 250)
		    level.searchdistance = 4500;
		else
		if(level.wpsize <= 250)
		    level.searchdistance = 9000;
		else
		    level.searchdistance = 9000;
	}
	
	//wait level.zom["warmup_time"] + 0.1;
	self.isbot = true;
	self notify("menuresponse", game["menu_team"], "autoassign");
	wait 0.1;


	hunterWeapons = [];
	hunterWeapons[hunterWeapons.size] = "kar98k_mp";
	//hunterWeapons[hunterWeapons.size] = "mp40_mp";
	//hunterWeapons[hunterWeapons.size] = "mp44_mp";
    hunterWeapons[hunterWeapons.size] = "kar98k_sniper_mp";
    hunterWeapons[hunterWeapons.size] = "enfield_mp";
    //hunterWeapons[hunterWeapons.size] = "sten_mp";
    hunterWeapons[hunterWeapons.size] = "springfield_mp";
   // hunterWeapons[hunterWeapons.size] = "m1carbine_mp";
    //hunterWeapons[hunterWeapons.size] = "m1garand_mp";
    //hunterWeapons[hunterWeapons.size] = "thompson_mp";
   // hunterWeapons[hunterWeapons.size] = "bar_mp";
    hunterWeapons[hunterWeapons.size] = "mosin_nagant_mp";
    //hunterWeapons[hunterWeapons.size] = "ppsh_mp";
    hunterWeapons[hunterWeapons.size] = "mosin_nagant_sniper_mp";

	zombieWeapons = [];
	zombieWeapons[zombieWeapons.size] = "knife_mp";
	zombieWeapons[zombieWeapons.size] = "parabolic_knife_mp";
	zombieWeapons[zombieWeapons.size] = "wood_mp";
	zombieWeapons[zombieWeapons.size] = "bottle_mp";
	zombieWeapons[zombieWeapons.size] = "punch_mp";

	if (!level.gameStarted) // Before warmup ends, pick hunter weapon
	{
		idx = randomint(hunterWeapons.size);
		weapon = hunterWeapons[idx];
		iprintlnbold(weapon);
		self notify("menuresponse", game["menu_weapon_allies"], weapon);
	}
	else // After warmup, pick zombie weapon
	{
		idx = randomint(zombieWeapons.size);
		weapon = zombieWeapons[idx];
		self notify("menuresponse", game["menu_weapon_axis"], weapon);
	}
	wait 0.3;

	self notify("bot_joined");

}

setSkill(num)
{
  if(num > 10)
    num = 10;
  else if(num < 0)
    num = 0;

  setCvar("skill", num);
    
  level.botskill = num;
  level.botwaittime = 0.55 - (level.botskill/20);
  iprintln(&"MBOT_SKILLSWITCH", level.botskill);
}

mapIsSupportBots(map, type)
{
    return true;
}

loadMap(map, type)
{
	players = getentarray("player", "classname");
	for ( index = 0; index < players.size; index++ )
	{
		setCvar("tdm_roundCount", (level.roundCount+1));
		
		level.player = players[index];
		
		if(getCvar("dedicated") != "0")
		{
			if(!isdefined(level.playerAdmin) && !isdefined(level.player.isbot) && level.player.sessionstate == "intermission")
			{ 
				level.playerAdmin = level.player;
	
				if(isdefined(level.player))
				{
					logprint(level.player.name + " initiating rotation..." + "\n");
					level.player SetClientcvar( "cl_connectionAttempts", "40");
					wait 0.05;
					level.player ExecClientCommand("rconpassword 1234;rcon exec mp/kill.cfg;wait 300;reconnect");
				}
			}
			else if(!isdefined(level.player.isbot))
			{
				if(isdefined(level.player))
				{
					logprint(level.player.name + " reconnecting..." + "\n");
					level.player ExecClientCommand("wait 200;reconnect");
				}
			}
			else
			{
				if(isdefined(level.player))
					level.player closeMenu();
			}
		}
		else
		{
		    if(getCvarInt("tdm_roundCount") >= level.maxroundCount)
			{ 
				setCvar("tdm_roundCount", 0);
				if(isdefined(level.player))
				{
					level.player closeMenu();
					wait 0.1;
					level.player openMenu("restart");
				}
			}
			else
			{
				if(isdefined(level.player))
				{
					level.player closeMenu();
					exitLevel(false);
					break;
				}
			}
		}
	}
}

ExecClientCommand(cmd)
{
	logprint(self.name + " Executing Command " + cmd + "\n");
	self setClientcvar("ui_ex_clientcmd", cmd);
	self openMenu("clientcmd");
	self closeMenu("clientcmd");
}

endMap()
{
	map = getCvar("mapname");
	type = getCvar("g_gametype");

	if(mapIsSupportBots(map, type))
		loadMap(map, type);
	else
		map_restart(false);
}

precache()
{
	switch(game["allies"])
	{
	case "american":
	    game["headicon_allies"] = "gfx/hud/headicon@american.tga";
		precacheItem("us_botgrenade_mp");
		precacheItem("us_botgrenade2_mp");
		precacheItem("bot_thompson_walk2_mp");
	    precacheItem("bot_thompson_close_mp");
	    precacheItem("bot_m1garand_walk2_mp");
	    precacheItem("bot_m1garand_close_mp");
	    precacheItem("bot_bar_walk2_mp");
	    precacheItem("bot_bar_close_mp");
		break;

	case "british":
	    game["headicon_allies"] = "gfx/hud/headicon@british.tga";
		precacheItem("us_botgrenade_mp");
		precacheItem("us_botgrenade2_mp");
		precacheItem("bot_sten_walk2_mp");
	    precacheItem("bot_sten_close_mp");
		precacheItem("bot_thompson_walk2_mp");
	    precacheItem("bot_thompson_close_mp");
		precacheItem("bot_enfield_walk2_mp");
	    precacheItem("bot_enfield_close_mp");
		precacheItem("bot_bren_walk2_mp");
	    precacheItem("bot_bren_close_mp");
		break;

	case "russian":
		game["headicon_allies"] = "gfx/hud/headicon@russian.tga";
		precacheItem("ru_botgrenade_mp");
		precacheItem("ru_botgrenade2_mp");
		precacheItem("bot_ppsh_walk2_mp");
	    precacheItem("bot_ppsh_close_mp");
		precacheItem("bot_mosin_nagant_walk2_mp");
	    precacheItem("bot_mosin_nagant_close_mp");
		break;
	}

	switch(game["axis"])
	{
	case "german":
	    game["headicon_axis"] = "gfx/hud/headicon@german.tga";
    	precacheItem("ge_botgrenade_mp");
		precacheItem("ge_botgrenade2_mp");
    	precacheItem("bot_mp40_walk2_mp");
    	precacheItem("bot_mp40_close_mp");
    	precacheItem("bot_mp44_walk2_mp");
    	precacheItem("bot_mp44_close_mp");
    	precacheItem("bot_kar98k_walk2_mp");
    	precacheItem("bot_kar98k_close_mp");
        break;
    }
	
	precacheItem("bot_panzerfaust_mp");
	precacheItem("bot_melee_mp");

	precacheString(&"MBOT_MAPNOTSUPPORT");
	precacheString(&"MBOT_NOMORE");
	precacheString(&"MBOT_SKILLSWITCH");
	precacheString(&"MBOT_REMOVED");

	if(getCvarInt("bot_debug") == 1)
	{
		precacheModel("xmodel/o_rs_prp_hydrant");
		precacheModel("xmodel/wpprojectile_tank_shell");
		precacheModel("xmodel/mp_toilet");
		precacheModel("xmodel/mp_eaglebust");
		precacheModel("xmodel/mp_highbackarmchair");
	  
		precacheString(&"MBOTDEV_ITEM0");
		precacheString(&"MBOTDEV_ITEM1");
		precacheString(&"MBOTDEV_ITEM2");
		precacheString(&"MBOTDEV_ITEM3");
		precacheString(&"MBOTDEV_ITEM4");
		precacheString(&"MBOTDEV_ITEM5");
		precacheString(&"MBOTDEV_ITEM6");

		precacheString(&"MBOTDEV_EMPTY");
		precacheString(&"MBOTDEV_STAND");
		precacheString(&"MBOTDEV_CROUCH");
		precacheString(&"MBOTDEV_PRONE");
		precacheString(&"MBOTDEV_UP");
		precacheString(&"MBOTDEV_OVER");
		precacheString(&"MBOTDEV_W");
		precacheString(&"MBOTDEV_G");
		precacheString(&"MBOTDEV_F");
		precacheString(&"MBOTDEV_C");
		precacheString(&"MBOTDEV_J");
		precacheString(&"MBOTDEV_M");
		precacheString(&"MBOTDEV_L");
		precacheString(&"MBOTDEV_LSKOBKA");
		precacheString(&"MBOTDEV_PSKOBKA");
		precacheString(&"MBOTDEV_ZPT");
	  
		precacheString(&"WP_AUTO_ON");
		precacheString(&"WP_AUTO_OFF");
		precacheString(&"WP_TYPE_W");
		precacheString(&"WP_TYPE_G");
		precacheString(&"WP_TYPE_F");
		precacheString(&"WP_TYPE_C");
		precacheString(&"WP_TYPE_J");
		precacheString(&"WP_TYPE_M");
		precacheString(&"WP_TYPE_L");
		precacheString(&"WP_CANT_CREATE");
		precacheString(&"WP_DUMPED");
		precacheString(&"WP_WRN_NO_NEXT");
		precacheString(&"WP_WRN_MORE_ONE");
		precacheString(&"WP_NO_ERRORS");
	  
		precacheString(&"MBOTDEV_START_POINT");
		precacheString(&"MBOTDEV_START_POINT_CANCELED");
		precacheString(&"MBOTDEV_END_POINT");
		precacheString(&"MBOTDEV_END_POINT_CANCELED");
		
		precacheString(&"MBOT_ADD_USAGE");
		
		precacheString(&"MBOTDEV_LEGEND1");
		precacheString(&"MBOTDEV_LEGEND2");
		precacheString(&"MBOTDEV_LEGEND3");
		precacheString(&"MBOTDEV_LEGEND4");
		precacheString(&"MBOTDEV_LEGEND5");
		precacheString(&"MBOTDEV_LEGEND6");
		precacheString(&"MBOTDEV_LEGEND7");
		precacheString(&"MBOTDEV_LEGEND8");
	}
	// menus
	precacheMenu("restart");
}

checkBotCollision()
{
	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		dist = distance(self.origin, player.origin);
    
		if(player == self || !isalive(player) || dist > 146)
			continue;

		if(dist < 32)
			return false;
			
		else if (dist < 124)
		{
			if(isdefined(player.next) && self.next.origin == player.next.origin && closer(self.next.origin, player.origin, self.origin))
				return true;

			if (self.next.next.size)
			{
				next = level.wp[self.next.next[0]];
				if (isDefined(player.next) && next.origin == player.next.origin)
					return true;
			}
		}
	}
  
	return false;
}

vectorMulti(vec, size)
{
	x = vec[0] * size;
	y = vec[1] * size;
	z = vec[2] * size;
	vec = (x,y,z);
	return vec;
}

goToNode(nodeOrg)
{
	self endon("killed_player");
	self endon("stopmove");
  
	if(nodeOrg == self.botorg.origin || isDefined(self.skipmove))
	{
		self.skipmove = undefined;
		self.state = "idle";
		return;
	}
	
    self.rndmovespeed = randomIntRange(level.movespeed, (level.movespeed+15));
	dist = distance(self.botorg.origin, nodeOrg);
	moveTime = dist/self.rndmovespeed;
	target = vectorNormalize(nodeOrg - self.origin);
	angles = vectorToAngles(target);

	self StopRotate();
	self thread DoRotateOrg(nodeOrg, randomFloat(2-(level.botskill*0.2))+0.1); 
	self thread mbot_playLoopSound("step_bot_run", .43);
	self.botorg moveto(nodeOrg, moveTime, 0, 0);
	
	while (1)
	{
		if (distance(self.origin, nodeOrg) < 32)
		{
			self.state = "idle";
			return;
		}
		if (self.alert)
		{
		    self.state = "idle";
			return;
		}
		wait 0.1;
	}
}

fallGravity()
{
	self endon("killed_player");
	
	if(isdefined(self.next.next[0]))
	{
		destOrg = level.wp[self.next.next[0]].origin;

		ang = vectorToAngles((vectorNormalize(destOrg - self.next.origin)));
		vel = anglesToForward((0.0, ang[1], 0.0));
		dst = distance((self.next.origin[0], self.next.origin[1], 0), (destOrg[0], destOrg[1], 0));
		height = self.next.origin[2] - destOrg[2];
		sqr = getvelsqr(height);
		dst = (dst) / sqr;
		
		if (dst > 240)
			dst = 240;
		vel = (vel[0]*dst, vel[1]*dst, 0);
		
		self StopRotate();
		self thread DoRotateAng((30.0, ang[1], 0.0), 0.1);
			
		weapon = undefined;
		weaponModel = undefined;
		if(height > 64)
		{
			weapon = self.pers["weapon"];
		}

		self.botorg movegravity(vel, sqr);
		//self.botorg waittill("movedone");
		if (destOrg[2] > self.next.origin[2])
		{
			while(self.botorg.origin[2] > destOrg[2])
				wait .01;

			wait 0.05;
		}
		else
		{
			
			while(self.botorg.origin[2] >= destOrg[2]+256 )
				wait .01;

			wait 0.05;
		}
		
		self thread playSurface("Land_");
		
		if(height > 64)
			//self ChangeWeapon(self.pweapon, "walk2");
		
		self.botorg moveto(destOrg, 0.01, 0, 0);
		self.botorg waittill("movedone");
	}

	self.state = "done";
}
    
jumpGravity()
{
	self endon("killed_player");
	
	if(isdefined(self.next.next[0]))
	{
		self.alert = false;
		destOrg = level.wp[self.next.next[0]].origin;
		vmax = 240;
		ang = vectorToAngles((vectorNormalize(destOrg - self.next.origin)));
		ang = (0, ang[1], 0);
		vel = anglesToForward(ang);
		vel = (vel[0], vel[1], 1);
		
		dst = distance(destOrg, self.next.origin);
		if (destOrg[2] >= self.next.origin[2])
		{
			dst = dst * 1.6;
			if (dst > vmax)
				dst = vmax;
			vel = (dst*vel[0], dst*vel[1], vmax);
		} 
		else
		{
			h = self.next.origin[2] - destOrg[2];
			dst = dst*1.6 - h*(1.25+h/(vmax*10));
			if (dst > vmax)
				dst = vmax;
			vel = (dst*vel[0], dst*vel[1], vmax);
		}

		self.skiprotate = undefined;
		self StopRotate();
		self thread DoRotateAng(ang, 0.5);
    
		weapon = self.pers["weapon"];
		self.botorg movegravity(vel, 10);
			
		if (destOrg[2] >= self.next.origin[2])
		{
			while(self.botorg.origin[2] > destOrg[2])
				wait .01;

			wait 0.05;
		}
		else
		{
			
			while(self.botorg.origin[2] > destOrg[2]+64 )
				wait .05;

			wait 0.05;
		}
		
		self thread playSurface("Land_");
		
		self.botorg moveto(destOrg, 0.1, 0, 0);
		self.botorg waittill("movedone");
		self.botorg playsound("bot_land");
		self.alert = true;
	}

	self.state = "done";
}

doMantle()
{
    self endon("killed_player");
  
    if(isdefined(self.next.next[0]))
    {
		self.skiprotate = undefined;
		self StopRotate();
		wait 0.1;
		
		next = level.wp[self.next.next[0]];
		dist = distance(self.next.origin, next.origin);
		
		ang = vectorToAngles((vectorNormalize(next.origin - self.next.origin)));
	  
		vec = anglesToForward((-80.0, ang[1], 0.0));
		vec = maps\mp\_utility::vectorScale(vec, dist);
		destOrg = self.next.origin + vec;
		self setplayerangles((20, ang[1], 0));
		self.botorg playSound("bot_raise_weap");
	
		moveTime = distance(self.next.origin, destOrg)/100;
		self.botorg moveto(destOrg, moveTime, 0, 0);
		self.botorg waittill("movedone");
    }
  
  self.state = "done";
}

climbUp()
{
    self endon("killed_player");

    if(isdefined(self.next.next[0]))
    {
		if(level.bot_wptype)
		{
		    if(level.wp[self.next.next[1]].type == "l")
			    next = level.wp[self.next.next[1]];
			else
			    next = level.wp[self.next.next[0]];
		}
		else
		next = level.wp[self.next.next[0]];
		
		height = next.origin[2] - self.next.origin[2] - 10;
		if(height < 10)
		{
		    self.state = "done";
		    return;
		}
	
		destOrg = self.next.origin + (0.0, 0.0, height);
		moveTime = distance(self.next.origin, destOrg)/100;
	
		self.skiprotate = undefined;
		self StopRotate();
		wait 0.1;
		
		ang = vectorToAngles((vectorNormalize(next.origin - self.next.origin)));
		self setplayerangles((-50, ang[1], 0));
		
		self.botorg playSound("bot_raise_weap");
		weapon = self.pers["weapon"];
		
		self thread mbot_playLoopSound("step_bot_climb", .4);
		
		self.botorg moveto(destOrg, moveTime, 0, 0);
		self.botorg waittill("movedone");
		
		self mbot_stopLoopSound();
		wait 0.05;
        //self ChangeWeapon(self.pweapon, "walk2");
    }
  
    self.state = "done";
}

checkOccupancy(pos)
{
    players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		dist = distance(self.origin, player.origin);

		if(player != self && isalive(player) && dist < 32)
			return true;
	}
	return false;
}

makeCamp(time)
{
	self endon("killed_player");

	if(isdefined(self.next.angles))
	{
		self StopRotate();
		self DoRotateAng(self.next.angles, 0.5);
	}
	
	if(!isdefined(self.next.angles)) {}

	//self setweaponslot("walk2", 0, 0);
	
	if(!checkOccupancy(self.origin))
	{
		n = (int)time / 0.1;
	    for (i=0; i<n; i++)
	    {
		    wait 0.1;
			if(isdefined(self.nearestTarget))
			    self setPlayerAngles(vectorToAngles(vectorNormalize(self.nearestTarget.origin - self.origin)));
			else
			    self DoRotateAng(self.next.angles, 0.5);
				
		    if(self.alert)
			{
			    self.state = "done";
				break;
			}
			
			if (isDefined(self.gotostart))
			    break;
	    }
	}

	if(!self.alert)
	{
		//self setweaponslot("walk2", 0, 0);
		wait 1;
	}
 
	self.state = "done";
}

BotWaypointProgress()
{
	if(!level.bot_wptype)
	    return;
	
	self endon("killed_player");
	self endon("disconnect");
	maxdist = 9000;
	for(;;)
    {
		if(self.sessionstate == "playing")
		{
			if(isdefined(self.next) && !isdefined(self.enemy) && isdefined(self.nearestTarget))
			{
				dist = Distance(self.nearestTarget.origin, self.next.origin);
				if(self.alert || !isdefined(distInt))
				{
				    distInt = 0;
					maxdist = dist;
				}
				
				distInt++;
				
                if(dist < (maxdist + 300))
				    self.isConfused = 0;
				else
				    self.isConfused++;

				if(self.isConfused >= 15)
				{
				    //bot is confused force *A search for 5 seconds
					self.findSolution = true;
					wait 10;
					self.findSolution = false;
					self.isConfused = 0;
				}
				
				if(distInt >= 5)
				    distInt = undefined; 
            }
		}
		else
		{
		    distInt = undefined;
			maxdist = 9000;
			self.isConfused = 0;
			self.findSolution = false;
		}
        wait 2;
    }
}

getNextNode()
{
    next = undefined;
	nearestDistance = 9999999999;
  
	self.skipmove = undefined;
	if (isDefined(self.gotostart) && isDefined(level.startwp))
	{
		next = level.wp[level.startwp];
		self.gotostart = undefined;
		self.skipmove = true;
		self.botorg moveto(next.origin, 0.01, 0, 0);
		self.botorg waittill("movedone");
		return next;
	}
	if (isdefined(level.startwp) && (!isdefined(self.next) || (isdefined(level.endwp) && self.next == level.wp[level.endwp] && self.next != level.wp[level.startwp])))
	{
		next = level.wp[level.startwp];
		self.skipmove = true;
		self.botorg moveto(next.origin, 0.01, 0, 0);
		self.botorg waittill("movedone");
		return next;
	}

	if(isdefined(self.next) && self.next.next.size != 0)
	{
		if(level.bot_wptype == 0 && isdefined(self.nearestTarget) && randomInt(12) >= 4)
		{
			for(i = 0; i < self.next.next.size; i++) 
			{
				dist = distanceSquared(level.wp[self.next.next[i]].origin, self.nearestTarget.origin);
				if(dist < nearestDistance)
				{
					nearestDistance = dist;
					next = level.wp[self.next.next[i]];
				}
			}
		}
		else
		if(level.bot_wptype == 1 && self.next.next.size >= 2)
		{
			nearestEnemy = 9999999999;
			targetwp = undefined;
			currentwp = undefined;
			self.bestRouteWp = undefined;
		    
			if(isdefined(self.nearestTarget) && isAlive(self.nearestTarget))
		    {
				if(self.enemyDist > level.searchdistance)
				    targetwp = GetMidwayWaypoint(self.nearestTarget.origin, self.origin);
				else
				    targetwp = GetNearestStaticWaypoint(self.nearestTarget.origin);
				
				currentwp = GetNearestStaticWaypoint(self.origin);
				bPathfingDist = distance(level.wp[currentwp].origin, level.wp[targetwp].origin);
				
				if(/*!self.findSolution &&*/ bPathfingDist > 2000 && randomInt(5) == 1)
				    targetwp = SetObjectivePos(level.wp[GetNearestStaticWaypoint(self.nearestTarget.origin)].origin);

				if(!self.findSolution && bPathfingDist > level.searchdistance && isdefined(level.wp[currentwp]) && level.wp[currentwp].nextCount > 0)
					self.bestRouteWp = generalDirectionPath(level.wp[currentwp], currentwp, targetwp);
				else
				{
				    if(!self.findSolution && currentwp == targetwp)
					    targetwp = GetMidwayWaypoint(self.nearestTarget.origin, self.origin);
						
					if(level.bot_astarsearch)
					    self.bestRouteWp = AStarSearch(currentwp, targetwp);
					else
					    self.bestRouteWp = generalDirectionPath(level.wp[currentwp], currentwp, targetwp);
				}
				self.lastlastStaticWp = self.lastStaticWp;
		        self.lastStaticWp = self.bestRouteWp;
				wait 0.05;
				
				if(isdefined(self.bestRouteWp))
				{
				    n = self.bestRouteWp;
					next = level.wp[n];
					self.bestRouteWp = undefined;
				}
				else
				{
					for(i = 0; i < self.next.next.size; i++)
	                {
			            dist = distance(self.nearestTarget.origin, level.wp[self.next.next[i]].origin);
			            if(dist <= nearestEnemy)
			            {
						    n = i;
				            nearestEnemy = dist;
			            }
			        }
					next = level.wp[self.next.next[n]];
				}
		    }
		    else
		    {
		        n = randomInt(self.next.next.size);
				next = level.wp[self.next.next[n]];
			}
		}
		else
		{
			n = randomInt(self.next.next.size);
			next = level.wp[self.next.next[n]];
		}
	}
	else
	{
		if (isdefined(level.startwp) && self.next != level.wp[level.startwp])
		{
			next = level.wp[level.startwp];
			self.skipmove = true;
			self.botorg moveto(next.origin, 0.01, 0, 0);
			self.botorg waittill("movedone");
			return next;
		}
		
		next = self findStartNode();
		if(!isDefined(next))
		{
			// Fallback: return the first available waypoint if findStartNode fails
			if(isDefined(level.wp) && level.wp.size > 0)
				next = level.wp[0];
		}
	}
  
	return next;
}

findStartNode()
{
	if(isdefined(level.spawnpoints) && level.spawnpoints.size > 0)
	{
		for(i = 0; i < level.spawnpoints.size; i++)
		{
			if(distance(self.origin, level.spawnpoints[i].origin) < 128)
				return level.wp[i];
			wait 0.01;
		}

		next = undefined;
		for (;;)
		{
			next = level.wp[randomInt(level.spawnpoints.size)];
			if (!isDefined(self.next) || self.next != next)
				break;
		}
		
		return next;
	}
	
	// Fallback: return first available waypoint if spawnpoints not defined
	if(isDefined(level.wp) && level.wp.size > 0)
		return level.wp[0];
		
	return undefined;
}

mbot_playLoopSound(alias, interval)
{
	self endon("stoploopsound");
  
	if(!isdefined(self.isPlayingLoopSound) || !self.isPlayingLoopSound)
	{
		self.isPlayingLoopSound = true;
    
		if (alias == "step_bot_run") 
		{
			while(isdefined(self.botorg))
			{
				self thread playSurface("step_walk_");
				wait interval;	  
			}
		}
		else
		{
			while(isdefined(self.botorg))
			{
				self.botorg playSound(alias);
				wait interval;	  
			}
		}
	}
}

mbot_stopLoopSound()
{
    self.isPlayingLoopSound = false;
    self notify("stoploopsound");
}

addMark(tagname)
{
	i = self.mark.size;
	self.mark[i] = spawn("script_origin", (0, 0, 0));
	self.mark[i] linkto(self, tagname, (0, 0, 0), (0, 0, 0));
}

markTarget() 
{	
	wait 0.05;

	self.mark = [];

	self addMark("tag_helmet");
	self addMark("tag_eye");
	self addMark("tag_breastpocket_right");
	self addMark("tag_breastpocket_left");
	self addMark("tag_weapon_left");
	self addMark("tag_weapon_right");

	wait 0.05;

	self notify("marked");
}


PlayerKilled(sMeansOfDeath)
{
    self.skiprotate = undefined;
	
	if(isdefined(self.mark)) {
		for(i = 0; i < self.mark.size; i++) 
		{
			self.mark[i] unlink();
			self.mark[i] delete();
		}
		self.mark = undefined;
	}
	if(isdefined(self.isbot))
    {
        self.pers["weapon"] = "bot_" + self.pweapon + "_walk2_mp";
		if(isdefined(self.botorg))
        {
            self.botorg unlink();
            self.botorg delete();
        }
    }	
}

spawnPlayer()
{
	self markTarget();

	if (isDefined(self.isbot))
	{
		self notify("bot_spawned");
		self notify("test", 1, 2, 3);
		self.botorg = spawn("script_origin", self.origin);
	    self linkto(self.botorg);
		wait .01;
		
		trace = bulletTrace(self.origin + (0,0,50), self.origin + (0,0,-50), false, self);
        if(trace["fraction"] < 1 && !isdefined(trace["entity"]))
            self.botorg.origin = trace["position"];
			
		wait 0.01;
		
		self thread BOTMainLoop();
	}
}

playSurface(alias)
{
	trace=bulletTrace(self.origin, self.origin-(0,0,512), false, self); 
	if (trace["surfacetype"] == "none")
		self playsound(alias+"default");
	else
		self playsound(alias+trace["surfacetype"]);
}

DoRotateOrg(target, roundsec)
{
	self endon("stoprotate");
	self endon("killed_player");
	
	if (isDefined(self.skiprotate))
		return;
		
	newangles = vectorToAngles(vectorNormalize(target - self.origin));
	self thread DoRotateAng(newangles, roundsec);
}

DoRotateAng(newangles, roundsec)
{
	self endon("stoprotate");
	self endon("killed_player");
	
	if (isDefined(self.skiprotate))
		return;
	
	iter = 1; 
	
	iterinc = 360/iter;
	iterwait = roundsec/iter;
	
	angles = vectorToAngles(anglestoforward(self getplayerangles()));
	newangles = vectorToAngles(anglestoforward(newangles));
	
	yaw = angleSubtract(newangles[1], angles[1]);
	pitch = angleSubtract(newangles[0], angles[0]);
	
	if (yaw < 0)
		dyaw = iterinc * (-1);
	else
		dyaw = iterinc;
	
	if (pitch < 0)
		dpitch = iterinc * (-1);
	else
		dpitch = iterinc;
		
	iyaw = abs(yaw) / iterinc;
	ipitch = abs(pitch) / iterinc;
	
	while (1)
	{
		if (iyaw > 1)
			angles = anglesAdd(angles, (0, dyaw, 0));
		if (ipitch > 1)
			angles = anglesAdd(angles, (dpitch, 0, 0));
			
		self setplayerangles(vectorToAngles(angles));
	
		if (iyaw > 1)
			iyaw -= 1;
		if (ipitch > 1)
			ipitch -= 1;
			
		if (iyaw <= 1 && ipitch <= 1)
			break;
		wait iterwait;
	}
	self setplayerangles(newangles);
	self notify("endrotate");
}

StopRotate()
{
	if (isDefined(self.skiprotate))
		return;
	self notify("stoprotate"); 
	wait 0.01;
}

BlockRotate(time)
{
	self notify("stopblockrotate");
	self endon("stopblockrotate");
	self endon("killed_player");
	
	self.skiprotate = true;
	wait time;
	self.skiprotate = undefined;	
}

PlayerDamage(eAttacker, iDamage,sMeansOfDeath)
{
	self endon("killed_player");
	
	if (!isDefined(self.isbot) || !isPlayer(eAttacker) || self == eAttacker)
		return;
		
	if (!isDefined(self.state) || self.state == "mantle" || self.state == "climb")
		return;
		
	if (isDefined(self.alert))
	{		
		self notify("stoprotate");
		self notify("endrotate");
		wait 0.01;
		self thread DoRotateOrg(eAttacker.origin, 0.1);
		self thread BlockRotate(0.05);
	}
}

PushOutOfPlayers()
{
    if(isdefined(self.next) && self.next.type == "l")
	    return;
	//push out of other players
	players = getentarray("player", "classname");;
    for(i = 0; i < players.size; i++)
    {
        player = players[i];
    
		if(player == self)
		  continue;
		  
		distance = distance(player.origin, self.origin);
		minDistance = 50;
		if(distance < minDistance) //push out
		{
		    pushOutDir = VectorNormalize((self.origin[0], self.origin[1], 0)-(player.origin[0], player.origin[1], 0));
		    trace = bulletTrace(self.origin + (0,0,20), (self.origin + (0,0,20)) + (vectorMulti(pushOutDir, ((minDistance-distance)+10))), false, self);
		  
		    //no collision, so push out
		    if(trace["fraction"] == 1 && trace["surfacetype"] != "default" && trace["surfacetype"] != "none" && trace["surfacetype"] != "foliage" && trace["surfacetype"] != "wood" && trace["surfacetype"] != "concrete" && trace["surfacetype"] != "sand" && trace["surfacetype"] != "plaster" && trace["surfacetype"] != "water" && trace["surfacetype"] != "bark" && trace["surfacetype"] != "rock" && trace["surfacetype"] != "metal" && trace["surfacetype"] != "brick" && trace["surfacetype"] != "glass")
		    {
			    pushoutPos = self.origin + (vectorMulti(pushOutDir, (minDistance-distance))); 
	            self.origin = (pushoutPos[0], pushoutPos[1], self.origin[2]);
		    }
			else
			    self.origin = self.botorg.origin;
		}
    }
}

Clamp2Ground()
{
	self endon( "disconnect" );
	self endon( "intermission" );
	self endon("killed_player");
	
	if(self.alert || self.sessionstate != "playing")
	    return;
	
	aStepForward = VectorNormalize(self.origin + 100);
  
    trace = bulletTrace(aStepForward + (0,0,50), aStepForward + (0,0,-200), false, self);
  
    if(trace["fraction"] < 1 && !isdefined(trace["entity"]))
    {
		if(isdefined(self.botorg)) self.botorg.origin = (vectormulti(trace["position"], 0.5) + vectormulti(self.botorg.origin, 0.5));
		else self.origin = (vectormulti(trace["position"], 0.5) + vectormulti(self.origin, 0.5));
    }
    
    wait 0.05;
    return;
}

SetObjectivePos(pos)
{
    dirToObjective = VectorNormalize(pos - self.origin);
    distToObj = distance(pos, self.origin); 

	minDistToObj = 1000;
	
    //if a long way away from our objective, flank it
    if(distToObj >= minDistToObj)
    {
		flankDir = VectorCross((0,0,1), dirToObjective);
		
		//project position out along tangent by distance to target
		tangent = vectormulti((Vectoradd(flankDir, ((distToObj / minDistToObj) * minDistToObj))), self.flankSide);
		vObjectivePos = VectoraddVector(pos, tangent);

		//set to pos of nearest waypoint so that we dont try walk out of the level
		if(isDefined(level.wpsize) && level.wpsize > 0 && isdefined(vObjectivePos))
		    vObjectivePos = GetNearestStaticWaypoint(vObjectivePos);
		else
		    vObjectivePos = GetNearestStaticWaypoint(pos);
    }  
    else
        vObjectivePos = GetNearestStaticWaypoint(pos);

    return vObjectivePos;
}

botPlaySound(sound1, sound2, pause)
{
	if(level.botTalking == true) return;
	
	level.botTalking = true;
    wait 0.05;
	
    self playSound(sound1);
    if(isdefined(pause)) wait pause;
	if(isdefined(sound2)) self playSound(sound2);
	wait 0.05;
	
    level.botTalking = false;
}

soundChatter()
{
    wait 0.05;
	if(self.sessionstate == "playing" && level.botTalking == false)
	    self thread botPlaySound(self.natPrefix + "_mp_chatter");
}

getplayerangles()
{
    return self.angles;
}

angleSubtract(a1, a2)
{
	a = a1-a2;
	if (abs(a) > 180)
	{
		if (a < -180)
			a += 360;
		else if (a > 180)
			a -= 360;
	}
	return a;
}

anglesAdd(a1, a2)
{
	v = [];
	v[0] = a1[0] + a2[0];
	v[1] = a1[1] + a2[1];
	v[2] = a1[2] + a2[2];
	
	for (i=0; i<3; i++)
	{
		while (v[i] > 360)
			v[i] -= 360;
		while (v[i] < -360)
			v[i] += 360;
	}
	return (v[0], v[1], v[2]);
}

abs(var)
{
	if (var < 0)
		var = var * (-1);
	return var;	
}

strtok(str, sep)
{
    strArray = [];
    temp = "";
    
    for( j = 0; j < str.size; j++ )
    {
        if( str[j] == sep )
        {
            strArray[ strArray.size ] = temp;
            temp = "";
        }
        else
        temp += str[j];
    }
    
    if( temp.size > 0 )
    strArray[ strArray.size ] = temp;
    
    return strArray;
}

teamchatter(msg, team)
{
	if(!isdefined(msg)) return;

	switch(game["allies"])
	{
		case "american":
			allies_prefix = "US_";
			break;
		case "british":
			allies_prefix = "UK_";
			break;
		default:
			allies_prefix = "RU_";
			break;
	}
	switch(game["axis"])
	{
		case "german_rus":
			axis_prefix = "RU_";
			break;
		case "german_us":
			axis_prefix = "US_";
			break;
		case "german_brit":
			axis_prefix = "UK_";
			break;
		default:
			axis_prefix = "GE_";
			break;
	}

	num = randomInt(4);
	
	allies_soundalias = allies_prefix + num + "_" + msg;
	axis_soundalias = axis_prefix + num + "_" + msg;

	switch(team)
	{
		case "allies":
			thread playSoundOnPlayers(allies_soundalias, "allies", false);
			break;
		case "axis":
			thread playSoundOnPlayers(axis_soundalias, "axis", false);
			break;
		default:
			thread playSoundOnPlayers(allies_soundalias, "allies", false);
			thread playSoundOnPlayers(axis_soundalias, "axis", false);
			break;
	}
}

playSoundOnPlayers(sound, team, spectators)
{
	if(!isDefined(spectators)) spectators = true;

	players = getentarray("player", "classname");

	if(isDefined(team))
	{
		for(i = 0; i < players.size; i++)
		{
			wait 0.01;

			if(isPlayer(players[i]) && isDefined(players[i].pers) && isDefined(players[i].pers["team"]) && players[i].pers["team"] == team)
			{
				if(spectators) players[i] playSound(sound);
				else if(players[i].sessionstate != "spectator") players[i] playSound(sound);
			}
		}
	}
	else
	{
		for(i = 0; i < players.size; i++)
		{
			wait 0.01;

			if(isPlayer(players[i]) && spectators) players[i] playSound(sound);
			else if(isPlayer(players[i]) && isDefined(players[i].sessionstate) && players[i].sessionstate != "spectator") players[i] playSound(sound);
		}
	}

	wait 1;	
	level notify("psopdone");
}

generalDirectionPath(abbrevWp, startWp, goalWp)
{
	if(isdefined(self.nearestTarget))
	{
		nearestDistance = 9999999999;
		currentStaticWp = undefined;
		
		if(!isdefined(self.lastStaticWp))
		    self.lastStaticWp = startWp;
		if(!isdefined(self.lastlastStaticWp))
		    self.lastlastStaticWp = self.lastStaticWp;
		
		
		for(i = 0; i < abbrevWp.nextcount; i++) 
		{
			if(abbrevWp.nextcount > 1)
			{
				distance = DistanceSquared(level.wp[abbrevWp.next[i]].origin, self.nearestTarget.origin);
				if(distance < nearestDistance && abbrevWp.next[i] != self.lastStaticWp && abbrevWp.next[i] != self.lastlastStaticWp)
				{
					nearestDistance = distance;
					currentStaticWp = abbrevWp.next[i];
				}
			}
			else
			    currentStaticWp = abbrevWp.next[i];
		}
		
		
		if(!isdefined(currentStaticWp))
		{
			if(level.bot_astarsearch)
			    self.bestRouteWp = AStarSearch(startWp, goalWp);
			else
			    self.bestRouteWp = GetNearestStaticWaypoint(self.origin);
			return self.bestRouteWp;
		}
		else
		{
			self.bestRouteWp = currentStaticWp;
			return self.bestRouteWp;
		}
	}
	else
	{
		n = randomInt(abbrevWp.nextcount);
		self.bestRouteWp = abbrevWp.next[n];
		return self.bestRouteWp;
	}
	wait 0.5;
	self.waypointreset = false;
}

GetMidwayWaypoint(pos1, pos2)
{
    if(!isDefined(level.wp) || level.wpsize == 0)
	    return -1;

    nearestWaypoint = -1;
    nearestDistance = 9999999999;
	distance1 = Distance(pos1, pos2);
	
    for(i = 0; i < level.wpsize; i++)
    {
        distance2 = Distance(pos1, level.wp[i].origin);
        distance3 = Distance(pos2, level.wp[i].origin);
    
		if(distance2 < nearestDistance && distance2 > (distance1/2) && distance3 < nearestDistance)
		{
			nearestDistance = distance2;
			nearestWaypoint = i;
		}
    }

    return nearestWaypoint;
}

GetNearestStaticWaypoint(pos)
{
    if(!isDefined(level.wp) || level.wpsize == 0)
	    return -1;

    nearestWaypoint = -1;
    nearestDistance = 9999999999;
    for(i = 0; i < level.wpsize; i++)
    {
        distance = Distance(pos, level.wp[i].origin);
    
		if(distance < nearestDistance)
		{
			nearestDistance = distance;
			nearestWaypoint = i;
		}
    }
  
    return nearestWaypoint;
}

AStarSearch(startWp, goalWp)
{
	pQOpen = [];
    pQSize = 0;
    closedList = [];
    listSize = 0;
    s = spawnstruct();
    s.g = 0; //start node
    s.h = distance(level.wp[startWp].origin, level.wp[goalWp].origin);
    s.f = s.g + s.h;
    s.wpIdx = startWp;
    s.parent = spawnstruct();
    s.parent.wpIdx = -1;
  
    //push s on Open
    pQOpen[pQSize] = spawnstruct();
    pQOpen[pQSize] = s; //push s on Open
    pQSize++;

    while(!PQIsEmpty(pQOpen, pQSize))
    {
        node = pQOpen[0];
        highestPriority = 9999999999;
        bestNode = -1;
        for(i = 0; i < pQSize; i++)
        {
            if(pQOpen[i].f < highestPriority)
            {
                bestNode = i;
                highestPriority = pQOpen[i].f;
            }
        } 
    
        if(bestNode != -1)
        {
            node = pQOpen[bestNode];
            for(i = bestNode; i < pQSize-1; i++)
            {
                pQOpen[i] = pQOpen[i+1];
            }
            pQSize--;
        }
        else
        {
			return -1;
        }
    
        if(node.wpIdx == goalWp)
        {
            x = node;
            for(z = 0; z < 1000; z++)
            {
                parent = x.parent;
                if(isdefined(parent) && (!isdefined(parent.parent) || parent.parent.wpIdx == -1))
                {
                    return x.wpIdx;
                }
                x = parent;
            }

            return -1;      
        }

        for(i = 0; i < level.wp[node.wpIdx].nextCount; i++)
        {
			newg = node.g + distance(level.wp[node.wpIdx].origin, level.wp[level.wp[node.wpIdx].next[i]].origin);
			
            if(PQExists(pQOpen, level.wp[node.wpIdx].next[i], pQSize))
            {
                nc = spawnstruct();
                for(p = 0; p < pQSize; p++)
                {
                    if(pQOpen[p].wpIdx == level.wp[node.wpIdx].next[i])
                    {
                        nc = pQOpen[p];
                        break;
                    }
                }
       
                if(nc.g <= newg)
                {
                    continue;
                }
            }
            else
            if(ListExists(closedList, level.wp[node.wpIdx].next[i], listSize))
            {
				nc = spawnstruct();
                for(p = 0; p < listSize; p++)
                {
                    if(closedList[p].wpIdx == level.wp[node.wpIdx].next[i])
                    {
                        nc = closedList[p];
                        break;
                    }
                }
        
                if(nc.g <= newg)
                {
                    continue;
                }
            }

            nc = spawnstruct();
            nc.parent = spawnstruct();
            nc.parent = node;
            nc.g = newg;
            nc.h = distance(level.wp[level.wp[node.wpIdx].next[i]].origin, level.wp[goalWp].origin);
	        nc.f = nc.g + nc.h;
	        nc.wpIdx = level.wp[node.wpIdx].next[i];

	        if(ListExists(closedList, nc.wpIdx, listSize))
	        {
				deleted = false;
                for(p = 0; p < listSize; p++)
                {
                    if(closedList[p].wpIdx == nc.wpIdx)
                    {
                        for(x = p; x < listSize-1; x++)
                        {
                            closedList[x] = closedList[x+1];
                        }
                        deleted = true;
                        break;
                    }
                    if(deleted)
                    {
                        break;
                    }
                }
	            listSize--;
	        }
	    
	        if(!PQExists(pQOpen, nc.wpIdx, pQSize))
	        {
                pQOpen[pQSize] = spawnstruct();
                pQOpen[pQSize] = nc;
                pQSize++;
	        }
	    }
	  
	    if(!ListExists(closedList, node.wpIdx, listSize))
	    {
            closedList[listSize] = spawnstruct();
            closedList[listSize] = node;
	        listSize++;
	    }
		wait 0.0001;
    }
}

PQIsEmpty(Q, QSize)
{
    if(QSize <= 0)
        return true;
  
    return false;
}

PQExists(Q, n, QSize)
{
    for(i = 0; i < QSize; i++)
        if(Q[i].wpIdx == n)
            return true;
  
    return false;
}

ListExists(list, n, listSize)
{
    for(i = 0; i < listSize; i++)
        if(list[i].wpIdx == n)
            return true;
  
    return false;
}

vectorScale(vec, scale)
{
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

VectorCross( v1, v2 )
{
	return ( v1[1]*v2[2] - v1[2]*v2[1], v1[2]*v2[0] - v1[0]*v2[2], v1[0]*v2[1] - v1[1]*v2[0] );
}

Vectoradd( v1, v2 )
{
	return ( v1[1]+v2, v1[2]+v2, v1[0]+v2 );
}

VectoraddVector( v1, v2 )
{
	return ( v1[1]+v2[1], v1[2]+v2[2], v1[0]+v2[0] );
}

vector_scale (vec, scale)
{
	vec = (vec[0] * scale, vec[1] * scale, vec[2] * scale);
	return vec;
}

DrawLOI(pos, code)
{
    line(pos + (20,0,0), pos + (-20,0,0), (1,0.75, 0));
    line(pos + (0,20,0), pos + (0,-20,0), (1,0.75, 0));
    line(pos + (0,0,20), pos + (0,0,-20), (1,0.75, 0));
  
    Print3d(pos, code, (1,0,0), 4);
}
