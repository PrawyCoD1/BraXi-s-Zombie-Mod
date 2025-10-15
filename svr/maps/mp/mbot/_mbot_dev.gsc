/*
--------------------------------------------------------------------------------------------------
level.wp:
.origin  -  origin
.type    -  type sn ; <w, g, f, c, j, m, l>
.next[]  -  following sn
.stance  -  bot status ; < 0 - stand, 1 - crouch, 2 - prone>
.angles  -  angles ; defayned if . type <g, c>
.mode    -  mod < 0 - up, 1 - over>; defayned if . type <m>

spawn - chair
w - yellow and black shell (direction marker)
f - golden eagle bust
c - white toilet
j - golden eagle bust
l - hydrant

self.state:
idle     -  bot pending action
done     -  bot performed the action
move     -  move the bot
camp     -  camper bot
fall     -  bot falls down
jump     -  jumping bot
climb    -  bot climbs ladder
 
self.next - WP, type level.wp

--------------------------------------------------------------------------------------------------
*/

init()
{
    level.model = [];

    setCvar("sv_cheats", 1);
    setCvar("bot_printwps", "");
    setCvar("placewp", "");
    setCvar("movewp", "");
    setCvar("deletewp", 0);
    setCvar("bot_status", "");
    setCvar("bot_dumpwps", "");
    setCvar("bot_devmenu", "");
    setCvar("jumptonode", -1);
    setCvar("bot_startwp", ""); 
    setCvar("bot_endwp", "");
    setCvar("bot_autowp", "0");
    setCvar("wp_check", "");
    setCvar("wp_gotoerror", "");
    setCvar("sp_gotonextsp", "0");
	
    level.startwp = undefined; 
    level.endwp = undefined;
    level.monitorTime = getTime();
  
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
     
    level.plr thread Deb();
    level.plr thread Dev();
    level.plr thread devMenu();
    level.plr thread dumpMonitor();
    level.plr thread devLegend();
}

dumpMonitor()
{
    while(1)
	{
	    timePassed = level.monitorTime - getTime();
		if(timePassed >= 5000)
		{
		    tempDumpWPs();
			bFlag = true;
			level.monitorTime = getTime();
		}
		wait 1;
	}
}

Deb()
{
	self endon("disconnect");
	
	spawnpointname = "mp_teamdeathmatch_spawn";
	level.spawnpoints = getentarray(spawnpointname, "classname");
	for(i = 0; i < level.spawnpoints.size; i++)
	{
		model = spawn("script_model", level.spawnpoints[i].origin);
		model.angles = level.spawnpoints[i].angles + (0, 0, 0);
		model setmodel("xmodel/mp_highbackarmchair");
	}
  
	for(i = 0; i < level.wp.size; i++)
		level.wp[i].selected = false;
  
	if(level.wp.size == 0)
	{
		for(i = 0; i < level.spawnpoints.size; i++)
		{
			vec = anglesToForward(level.spawnpoints[i].angles);
			vec = maps\mp\_utility::vectorScale(vec, 26);
      
			org = level.spawnpoints[i].origin + vec;
      
			level.plr setOrigin(org);
			spawnNode("w", false);
		}
	
		dumpWPs();
		bFlag = true;
	}
  
	for(;;)
	{
		dvar = getCvar("bot_printwps");
		if(dvar != "")
		{
			min = 0;
			max = 0;
      
			parm = strtok(dvar, ",");
			if(parm.size == 2)
			{
				min = (int)parm[0];
				max = (int)parm[1];
			}
			else
				max = level.wp.size;
      
			for(i = min; i < max; i++)
			{
				if(!isdefined(level.wp[i]))
					break;
          
				if(!isdefined(level.wp[i].type))
				{
					println(i, ": undefined");
					continue;
				}
				if(level.wp[i].selected)
					print("^4Selected -> ");

				print(i, ": \"", level.wp[i].type, "\"; origin - (", (level.wp[i].origin[0]+", "+level.wp[i].origin[1]+", "+level.wp[i].origin[2]), ");");
				print(" stance - ", level.wp[i].stance, "; next[", level.wp[i].next.size, "] - ");
        
				for(k = 0; k < level.wp[i].next.size; k++)
					print(" ", level.wp[i].next[k], ",");
        
				if(isdefined(level.wp[i].mode))
					print("; mode - ", level.wp[i].mode, "; ");
          
				if(isdefined(level.wp[i].angles))
					print("; angle = (", (level.wp[i].angles[0]+", "+level.wp[i].angles[1]+", "+level.wp[i].angles[2]), ")\n");
				else
					print("\n");
			}
			wait .25;
			setCvar("bot_printwps", "");
		}
    
		dvar = getCvar("bot_status");
		if(dvar != "")
		{
			players = getentarray("player", "classname");
			for(i = 0; i < players.size; i++)
			{
				if(isDefined(players[i].isbot) && players[i].name == dvar)
				{
					println("\n", players[i].name, " status:");
					println("-------------------------------------");
					println("Team: ", players[i].pers["team"]);
					println("State: ", players[i].state);
					println("IsAlive: ", isalive(players[i]));
					println("PrimaryWeapon: ", (players[i] getweaponslotweapon("primary")));
					println("PrimaryAmmo: ", (players[i] getweaponslotammo("primary")));
					println("PrimaryClipAmmo: ", (players[i] getweaponslotclipammo("primary")));
					println("SecondWeapon: ", (players[i] getweaponslotweapon("primaryb")));
					println("SecondaryAmmo: ", (players[i] getweaponslotammo("primaryb")));
					println("SecondaryClipAmmo: ", (players[i] getweaponslotclipammo("primaryb")));
					if(isdefined(players[i].botgrenade))
						println("GrenadeType: ", players[i].botgrenade);
					else
						println("GrenadeType: undefined");
					if(isdefined(players[i].botgrenadecount))
						println("GrenadesCount: ", players[i].botgrenadecount);
					else
						println("GrenadesCount: undefined");
					println("Origin: (", players[i].origin[0], ", ", players[i].origin[1], ", ", players[i].origin[2], ")");
					if(isdefined(players[i].alert))
						println("Alert: ", players[i].alert);
					else
						println("Alert: 0");
					if(isdefined(players[i].next))
						println("NextWP: ", players[i].next.next[0]);
					else
						println("NextWP: udefined");

					println("\npClipAmmo: ", players[i].pclipammo);
					println("BotOrg: ", players[i].botorg);
					println("-------------------------------------");
					break;
				}
			}	

			wait .1;
			setCvar("bot_status", "");
		}
    
		dvar = getCvar("bot_devmenu");
		if(dvar != "")
		{
			cur = self.devMenuLine.curItem;
			switch(dvar)
			{
				case "up":
					if(cur > 0)
					{
						self.devMenuLine.curItem--;
						self.devMenuLine.y -= 10;
					}
				break;
				
				case "down":
					if(cur < 6)
					{
						self.devMenuLine.curItem++;
						self.devMenuLine.y += 10;
					}
				break;
				
				case "change":
					if(self.devMenuItem[cur].alpha != 1)
						break;
            
					switch(cur)
					{
						case 1: // type
							self.devMenuItem[1].cur++;
							if(self.devMenuItem[1].cur > 6)
								self.devMenuItem[1].cur = 0;

							switch(self.devMenuItem[1].cur)
							{
								case 0: self.devMenuItem[1] setText(&"MBOTDEV_W"); break;
								//case 1: self.devMenuItem[1] setText(&"MBOTDEV_G"); break;
								case 1: self.devMenuItem[1] setText(&"MBOTDEV_F"); break;
								case 2: self.devMenuItem[1] setText(&"MBOTDEV_C"); break;
								case 3: self.devMenuItem[1] setText(&"MBOTDEV_J"); break;
								case 4: self.devMenuItem[1] setText(&"MBOTDEV_M"); break;
								case 5: self.devMenuItem[1] setText(&"MBOTDEV_L"); break;
							}
              
							self.devMenuItem[1].color = (1.0, 1.0, .3);
						break;
						
						case 2: // origin
							self.devMenuItem[2] deleteVectorValue();
							self.devMenuItem[2].color = (1.0, 1.0, .3);
							self.devMenuItem[2] setVectorValue(self.origin, 50);
              
							self.devMenuItem[2].neworg = self.origin;
						break;
						
						case 4: // stance
							self.devMenuItem[4].cur++;
							if(self.devMenuItem[4].cur > 1)
								self.devMenuItem[4].cur = 0;

							switch(self.devMenuItem[4].cur)
							{
								case 0: self.devMenuItem[4] setText(&"MBOTDEV_STAND"); break;
								case 1: self.devMenuItem[4] setText(&"MBOTDEV_CROUCH"); break;
								//case 2: self.devMenuItem[4] setText(&"MBOTDEV_PRONE"); break;
							}
							self.devMenuItem[4].color = (1.0, 1.0, .3);
						break;
						
						case 5: // angles
							if(self.devMenuItem[5].alpha == 1)
							{
								ang = self getPlayerAngles();
								self.devMenuItem[5].newang = (ang[0], ang[1], 0.0);
                
								self.devMenuItem[5] deleteVectorValue();
								self.devMenuItem[5].color = (1.0, 1.0, .03);
								self.devMenuItem[5] setVectorValue(self.devMenuItem[5].newang, 50);
							}
						break;
						
						case 6: // mode
							self.devMenuItem[6].cur++;
							if(self.devMenuItem[6].cur > 1)
								self.devMenuItem[6].cur = 0;

							switch(self.devMenuItem[6].cur)
							{
								case 0: self.devMenuItem[6] setText(&"MBOTDEV_UP"); break;
								case 1: self.devMenuItem[6] setText(&"MBOTDEV_OVER"); break;
							}
							self.devMenuItem[6].color = (1.0, 1.0, .3);
						break;
						
						default:
							break;
					}
				break;
				
				case "confirm":
					if(self.devMenuItem[cur].color == (1.0, 1.0, 1.0))
						break;
            
					switch(cur)
					{
						case 1: // type
							switch(self.devMenuItem[1].cur)
							{
								case 0: level.wp[level.curselwp].type = "w"; break;
								//case 1: level.wp[level.curselwp].type = "g"; break;
								case 1: level.wp[level.curselwp].type = "f"; break;
								case 2: level.wp[level.curselwp].type = "c"; break;
								case 3: level.wp[level.curselwp].type = "j"; break;
								case 4: level.wp[level.curselwp].type = "m"; break;
								case 5: level.wp[level.curselwp].type = "l"; break;
							}
              
							level.wp[level.curselwp].angles = undefined;
							self.devMenuItem[5].alpha = .5;
							self.devMenuItem[5] deleteVectorValue();
              
							level.wp[level.curselwp].mode = undefined;
							self.devMenuItem[6] setText(&"MBOTDEV_EMPTY");
              
							if(self.devMenuItem[1].cur == 1 || self.devMenuItem[1].cur == 3)
							{
								ang = self getPlayerAngles();
								level.wp[level.curselwp].angles = (ang[0], ang[1], 0.0);
								self.devMenuItem[5].alpha = 1;
								self.devMenuItem[5] setVectorValue(level.wp[level.curselwp].angles, 50);
							}
              
							if(self.devMenuItem[1].cur == 5)
							{
								level.wp[level.curselwp].mode = 0;
								self.devMenuItem[6].alpha = 1;
								self.devMenuItem[6].cur = 0;
								self.devMenuItem[6] setText(&"MBOTDEV_UP");
							}

							if (isDefined(level.model[level.curselwp])) // Cepe7a
								level.model[level.curselwp] delete();
							spawnModelForNode(level.curselwp);

							self.devMenuItem[1].color = (1.0, 1.0, 1.0);
						break;
						
						case 2: // origin
							level.wp[level.curselwp].origin = self.devMenuItem[2].neworg;
							level.model[level.curselwp] moveTo(self.devMenuItem[2].neworg, 0.01, 0, 0);
							self.devMenuItem[2].color = (1.0, 1.0, 1.0);
							for(i = 0; i < 7; i++)
								self.devMenuItem[2].hud_vec[i].color = (1.0, 1.0, 1.0);
						break;
						
						case 4: // stance
							level.wp[level.curselwp].stance = self.devMenuItem[4].cur;
							self.devMenuItem[4].color = (1.0, 1.0, 1.0);
						break;
						
						case 5: // angles
							level.wp[level.curselwp].angles = self.devMenuItem[5].newang;
							level.model[level.curselwp] rotateTo((0.0, self.devMenuItem[5].newang[1], 0.0), 0.01, 0, 0);
							self.devMenuItem[5].color = (1.0, 1.0, 1.0);
							for(i = 0; i < 7; i++)
								self.devMenuItem[5].hud_vec[i].color = (1.0, 1.0, 1.0);
						break;
						
						case 6: // mode
							level.wp[level.curselwp].mode = self.devMenuItem[6].cur;
							self.devMenuItem[6].color = (1.0, 1.0, 1.0);
						break;
						
						default:
							break;
					}
				break;
			}
			setCvar("bot_devmenu", "");
		}
    
		dvar = getCvarInt("jumptonode");
		if(dvar != -1 && isdefined(level.wp[dvar]))
		{
			self setOrigin(level.wp[dvar].origin);
			if (isdefined(level.curselwp)) 
			{
				level.wp[level.curselwp].selected = false;
				level.wp[level.curselwp] notify("unselect");
				wait .1;
			}
			level.curselwp = dvar;
			level.wp[dvar].selected = true;
			level.wp[dvar] thread markSelectedWP(dvar);		

			setCvar("jumptonode", -1);
		}
    
		// Should clean restriction in 256 ent's in one snapshot and in 1024 ent's all on a map when it is a lot of waypoints on a map
		tmp = 250;
		for(j = 0; j < level.wp.size; j++)
		{
			if(!isdefined(level.wp[j]) || !isdefined(level.wp[j].type) || level.wp[j].selected)
				continue;

			dist = distance(level.plr.origin, level.wp[j].origin);
			if(dist < 450)
			{
				if(!isdefined(level.model[j]))
					spawnModelForNode(j);
			}
			else
			{
				if(isdefined(level.model[j]))
					level.model[j] delete();
			}

			if(isdefined(level.model[j]))
			{
				if(dist < 500)
					level.model[j] show();
				else
					level.model[j] hide();
			}

			if(j > tmp) // That was not potential infinite loop
			{
				wait .05;
				tmp += 250;
			}
		}
		wait .05;
	}

}

Dev()
{
	self endon("disconnect");
	
    curselwp = undefined;
    lastview = undefined; 
    startorigin = undefined;
    lastwp = undefined;
    autowp = false;
  
    for(;;)
    {
		dvar = getCvar("wp_check");
		if (dvar != "") 
		{
			CheckErrors(true);
			setCvar("wp_check", "");		
		}
		
		dvar = getCvar("wp_gotoerror");
		if (dvar != "") 
		{
			i = CheckErrors(false);
			if (i >= 0) 
			{
				self setOrigin(level.wp[i].origin);
				if (isdefined(level.curselwp)) 
				{
					level.wp[level.curselwp].selected = false;
					level.wp[level.curselwp] notify("unselect");
					wait .1;
				}
				level.wp[i].selected = true;
				level.curselwp = i;
				level.wp[i] thread markSelectedWP(i);		
			}
			setCvar("wp_gotoerror", "");		
		}
		
		dvar = getCvarInt("sp_gotonextsp");
		if (dvar != "0") 
		{ 
			if(isdefined(self))
			{
				CurrentSpawnpoint = -1;
				CurrentSpawnpoint = GetNearestSpawnpoint(self.origin);
				
				size = level.spawnpoints.size;
	
				if(CurrentSpawnpoint >= size-1)
					CurrentSpawnpoint = (size-1) - CurrentSpawnpoint;
				else
					CurrentSpawnpoint = CurrentSpawnpoint+1;
			
				self setplayerangles(level.spawnpoints[CurrentSpawnpoint].angles);
				self setOrigin(level.spawnpoints[CurrentSpawnpoint].origin);
				iprintln("Current Spawnpoint is " + CurrentSpawnpoint);
				
				setCvar("sp_gotonextsp", "0");
			}
			wait .05;
		}
		
		dvar = getCvar("bot_startwp");
		if (dvar != "") 
		{
			if (isdefined(level.curselwp)) 
			{
				level.startwp = level.curselwp;
				iprintln(&"MBOTDEV_START_POINT", level.curselwp);
				players = getentarray("player", "classname");
				for(i = 0; i < players.size; i++)
				{
					player = players[i];
					if(player.pers["team"] == "spectator" || !isDefined(player.isbot) || !isDefined(player.mark))
						continue;
					if (!isDefined(player.mark) ||!isDefined(player.state))
						continue;
 					
					player notify("stoprotate"); 					
					player.gotostart = true;
					next = player.next;
					switch (player.state)
					{
						case "fall":
						case "climb":
						case "jump":
						case "matle":
							if (isDefined(next.next[0]))
								next = level.wp[player.next.next[0]];
							break;
					}
					player.botorg moveto(next.origin, 0.01, 0, 0);
					player.botorg waittill("movedone");
					break;
				}		
			}
			else if (isDefined(level.startwp))
			{
				iprintln(&"MBOTDEV_START_POINT_CANCELED");
				level.startwp = undefined;
			}
			
			setCvar("bot_startwp", "");
		}
		
		dvar = getCvar("bot_endwp");
		if (dvar != "") 
		{
			if (isdefined(level.curselwp)) 
			{
				level.endwp = level.curselwp;
				iprintln(&"MBOTDEV_END_POINT", level.curselwp);
			}
			else if (isDefined(level.endwp))
			{
				iprintln(&"MBOTDEV_END_POINT_CANCELED");
				level.endwp = undefined;
			}
			
			setCvar("bot_endwp", "");
		}
	  
		dvar = getCvarInt("bot_autowp");
		if (!autowp && dvar>32) 
		{
			iprintln(&"WP_AUTO_ON", dvar);
			autowp = true;
			if (isdefined(level.curselwp)) 
			{
				level.wp[level.curselwp].selected = false;
				level.wp[level.curselwp] notify("unselect");
				wait .1;
			}
			spawnNode("w", true);
			lastwp = level.wp.size-1;
			level.wp[lastwp].selected = true;
			level.curselwp = lastwp;
			level.wp[lastwp] thread markSelectedWP(lastwp);
			lastview = level.wp[lastwp].origin;
			startorigin = lastview;
		}
		else if (autowp && (distance(self.origin, lastview) > 32 || dvar<32))
		{
			if (dvar<32) 
			{
				iprintln(&"WP_AUTO_OFF");
				autowp = false;
				startmark = undefined;
			}

			dist = distance(self.origin, startorigin);
			view = false;
			for (i=0; i<level.viewofs.size; i++)
			{
				view = bullettracepassed(self.origin+level.viewofs[i], startorigin+level.viewofs[i], false, self);
				if (!view)
					break;
			}
			
			if(!view || dist > dvar || (!autowp && dist > 32)) 
			{
				ang = self getplayerangles();
				dist = level.wp.size;
				level.wp[dist] = spawnstruct();
				level.wp[dist].origin = lastview;
				level.wp[dist].type = "w";
				level.wp[dist].next = [];
				level.wp[dist].stance = 0;
				level.wp[dist].angles = (ang[0], ang[1], 0.0);
				level.wp[dist].selected = false;
				spawnModelForNode(dist);
				
				level.wp[lastwp] setNextNode(dist);
				lastwp = dist;
				startorigin = lastview;	
			}
			lastview = self.origin;
		}
		
		if (!autowp)
		{
			dvar = getCvar("placewp");
			if(dvar != "" && isalive(self))
			{
				spawnNode(dvar, true);
				wait .5;
				setCvar("placewp", "");
			}
		  
			dvar = getCvar("bot_dumpwps");
			if(dvar != "")
			{
				if (dvar == "1")
					dvar = level.wpfile;
				dumpWPs();
					wait .5;
				setCvar("bot_dumpwps", "");
			}
		  
			dvar = getCvar("movewp");
			if(dvar != "")
			{
				if(isdefined(level.curselwp))
				{
					n = level.curselwp;
					parm = strtok(dvar, ",");
		
					if(isdefined(parm[0]) && isdefined(parm[1]))
					{
						parm[1] = strtoflt(parm[1]);
						switch(parm[0])
						{
							case "y":
								level.wp[n].origin += (parm[1], 0, 0);
								if (isDefined(level.model[n])) // Cepe7a
								level.model[n] movex(parm[1], .01, 0, 0);
								break;
							case "x":
								level.wp[n].origin += (0, parm[1], 0);
								if (isDefined(level.model[n])) // Cepe7a
								level.model[n] movey(parm[1], .01, 0, 0);
								break;
							case "z":
								level.wp[n].origin += (0, 0, parm[1]);
								if (isDefined(level.model[n])) // Cepe7a
								level.model[n] movez(parm[1], .01, 0, 0);
								break;
						}
					}
				}
				wait .25;
				setCvar("movewp", "");
		    }
	  
		    if(getCvarInt("deletewp") != 0)
		    {
				if(isdefined(level.curselwp))
				{
					if (isdefined(level.startwp) && level.curselwp == level.startwp) 
						level.startwp = undefined;
					if (isdefined(level.endwp) && level.curselwp == level.endwp) 
						level.endwp = undefined;
					players = getentarray("player", "classname");
					for (i=0; i<players.size; i++) if (isdefined(players[i].isbot) && players[i].next == level.wp[level.curselwp])
							players[i].next = level.wp[0];
					
				    // We clean all references on deleted waypoint!
				    n = level.curselwp;
				    last = level.wp.size - 1;
				    next = undefined;
				    if(level.wp[n].next.size == 1)
				    {
					    next = level.wp[n].next[0];
					    if(next == last)
					        next = n;
				    }
				  
				    for(i = 0; i < level.wp.size; i++)
				    {
					    for(k = 0; k < level.wp[i].next.size; k++)
					    {
					        if(level.wp[i].next[k] == n)
					        {
						        temp = level.wp[i].next;
						        temp[k] = -1;
						        level.wp[i].next = undefined;
						        level.wp[i].next = [];
						  
						        for(l = 0; l < temp.size; l++)
						        {
						            if(temp[l] != -1)
							            level.wp[i].next[level.wp[i].next.size] = temp[l];
						        }
					        }
					    }
		            }
		  
		            // We delete selected waypoint!
		            level.wp[n] notify("unselect");
		            wait .05;
		            if(n != last)
			            level.wp[n] = spawnstruct();
		            else
			            level.wp[n] = undefined;
		            if (isDefined(level.model[n])) // Cepe7a
			            level.model[n] delete();
		            level.curselwp = undefined;
		  
		            // If removed waypoint not last last is transferable waypoint on a place removed
		            if(n != last)
		            {
			            level.wp[n] = level.wp[last];
			            spawnModelForNode(n);
			            level.wp[last] = undefined;
			            if(isdefined(level.model[last]))
			                level.model[last] delete();
		  
			            // We update all the references specified on last waypoint
			            for(i = 0; i < level.wp.size; i++)
			            {
			                for(k = 0; k < level.wp[i].next.size; k++)
			                {
				                if(level.wp[i].next[k] == last)
				                {
				                    level.wp[i].next[k] = n;
				                    break;
				                }
			                }
			            }
		            }
		  
		            // If at removed waypoint there was one following waypoint it is chosen it
		            if(isdefined(next))
		            {
			            level.wp[next].selected = true;
			            level.curselwp = next;
			            level.wp[next] thread markSelectedWP(next);
		            }
		            level.plr notify("update_devmenu");
		        }
		        wait .75;
		        setCvar("deletewp", 0);
	        }
	  
		    if(self usebuttonpressed() && isdefined(self.mark))
		    {
				for(i = 0; i < level.wp.size; i++)
				{
					distance = distance(level.wp[i].origin, self.origin);
			
					if(distance <= 15.0)
					{
						if(level.wp[i].selected)
						{
							level.wp[i].selected = false;
							level.wp[i] notify("unselect");
							level.curselwp = undefined;
				  
							level.plr notify("update_devmenu");
							break;
						}
						else
						{
							if(isdefined(level.curselwp))
							{
								level.wp[level.curselwp].selected = false;
								level.wp[level.curselwp] notify("unselect");
							}
		
							level.wp[i].selected = true;
							level.curselwp = i;
							level.wp[i] thread markSelectedWP(i);
							break;
						}
						
					}
					while (self usebuttonpressed()) // Cepe7a
					   wait 0.1;
				}
			    wait .1;
		    }
	  
		    if(self attackbuttonpressed() && isdefined(level.curselwp) && isdefined(self.mark))
		    {
				for(i = 0; i < level.wp.size; i++)
				{
					distance = distance(level.wp[i].origin, self.origin);
			
					if(distance <= 15.0)
					{
						if(i == level.curselwp)
						break;
		
						result = level.wp[level.curselwp] setNextNode(i);
						if(result == "linked")
						{
							wait 0.5;
							level.wp[level.curselwp].selected = false;
							level.wp[level.curselwp] notify("unselect");
							level.wp[i].selected = true;
							level.curselwp = i;
							level.wp[i] thread markSelectedWP(i);
							iprintln("Linked");
						}
						else if(result == "unlinked")
						{
							level.wp[level.curselwp] notify("unselect");
							wait .1;
							level.wp[level.curselwp] thread markSelectedWP(level.curselwp);
						}
						break;
					}
				}
				wait .5;
		    }
        }
        wait .1;
    }
}

GetNearestSpawnpoint(pos)
{
    if(!isDefined(level.spawnpoints))
        return -1;

    Spawnpoint = -1;
    nearestDistance = 9999999999;
    for(i = 0; i < level.spawnpoints.size; i++)
    {
        distance = Distance(pos, level.spawnpoints[i].origin);
    
        if(distance < nearestDistance)
        {
            nearestDistance = distance;
            Spawnpoint = i;
        }
    }
  
    return Spawnpoint;
}

devLegend()
{
	self endon("disconnect");
	level endon("intermission");
  
    self.devLegendItem1 = newClientHudElem(self);
    self.devLegendItem1.alignX = "left";
    self.devLegendItem1.alignY = "top";
    self.devLegendItem1.x = 10;
    self.devLegendItem1.y = 5;
    self.devLegendItem1.fontscale = .60;
    self.devLegendItem1.archived = false;
    self.devLegendItem1.alpha = .85;
    self.devLegendItem1.color = (1, 1, 1);
    self.devLegendItem1.label = (&"MBOTDEV_LEGEND1");
	
	self.devLegendItem2 = newClientHudElem(self);
    self.devLegendItem2.alignX = "left";
    self.devLegendItem2.alignY = "top";
    self.devLegendItem2.x = 10;
    self.devLegendItem2.y = 130;
    self.devLegendItem2.fontscale = .55;
    self.devLegendItem2.archived = false;
    self.devLegendItem2.alpha = .85;
    self.devLegendItem2.color = (1, 1, 1);
    self.devLegendItem2.label = (&"MBOTDEV_LEGEND3");
	
	self.devLegendItem2 = newClientHudElem(self);
    self.devLegendItem2.alignX = "left";
    self.devLegendItem2.alignY = "top";
    self.devLegendItem2.x = 10;
    self.devLegendItem2.y = 140;
    self.devLegendItem2.fontscale = .55;
    self.devLegendItem2.archived = false;
    self.devLegendItem2.alpha = .85;
    self.devLegendItem2.color = (1, 1, 1);
    self.devLegendItem2.label = (&"MBOTDEV_LEGEND4");
	
	self.devLegendItem2 = newClientHudElem(self);
    self.devLegendItem2.alignX = "left";
    self.devLegendItem2.alignY = "top";
    self.devLegendItem2.x = 10;
    self.devLegendItem2.y = 150;
    self.devLegendItem2.fontscale = .55;
    self.devLegendItem2.archived = false;
    self.devLegendItem2.alpha = .85;
    self.devLegendItem2.color = (1, 1, 1);
    self.devLegendItem2.label = (&"MBOTDEV_LEGEND5");
	
	self.devLegendItem2 = newClientHudElem(self);
    self.devLegendItem2.alignX = "left";
    self.devLegendItem2.alignY = "top";
    self.devLegendItem2.x = 10;
    self.devLegendItem2.y = 160;
    self.devLegendItem2.fontscale = .55;
    self.devLegendItem2.archived = false;
    self.devLegendItem2.alpha = .85;
    self.devLegendItem2.color = (1, 1, 1);
    self.devLegendItem2.label = (&"MBOTDEV_LEGEND6");
	
	self.devLegendItem2 = newClientHudElem(self);
    self.devLegendItem2.alignX = "left";
    self.devLegendItem2.alignY = "top";
    self.devLegendItem2.x = 10;
    self.devLegendItem2.y = 170;
    self.devLegendItem2.fontscale = .55;
    self.devLegendItem2.archived = false;
    self.devLegendItem2.alpha = .85;
    self.devLegendItem2.color = (1, 1, 1);
    self.devLegendItem2.label = (&"MBOTDEV_LEGEND7");
	
	self.devLegendItem2 = newClientHudElem(self);
    self.devLegendItem2.alignX = "left";
    self.devLegendItem2.alignY = "top";
    self.devLegendItem2.x = 10;
    self.devLegendItem2.y = 180;
    self.devLegendItem2.fontscale = .55;
    self.devLegendItem2.archived = false;
    self.devLegendItem2.alpha = .85;
    self.devLegendItem2.color = (1, 1, 1);
    self.devLegendItem2.label = (&"MBOTDEV_LEGEND8");
}

devMenu()
{
	self endon("disconnect");
	level endon("intermission");
  
    self.devMenuItem = [];
	
	offset = 200;
    for(i = 0 ; i < 7; i++)
    {
		self.devMenuItem[i] = newClientHudElem(self);
		self.devMenuItem[i].horzAlign = "left";
		self.devMenuItem[i].vertAlign = "middle";
		self.devMenuItem[i].x = 10;
		self.devMenuItem[i].y = offset;
		self.devMenuItem[i].font = "default";
		self.devMenuItem[i].fontscale = .75;
		self.devMenuItem[i].archived = false;
		self.devMenuItem[i].alpha = .5;
		self.devMenuItem[i].color = (1.0, 1.0, 1.0);
		
		offset += 10;
    }
  
    self.devMenuItem[0].label = (&"MBOTDEV_ITEM0");
    self.devMenuItem[1].label = (&"MBOTDEV_ITEM1");
    self.devMenuItem[2].label = (&"MBOTDEV_ITEM2");
    self.devMenuItem[3].label = (&"MBOTDEV_ITEM3");
    self.devMenuItem[4].label = (&"MBOTDEV_ITEM4");
    self.devMenuItem[5].label = (&"MBOTDEV_ITEM5");
    self.devMenuItem[6].label = (&"MBOTDEV_ITEM6");

    self.devMenuLine = newClientHudElem(self);
    self.devMenuLine.horzAlign = "left";
    self.devMenuLine.vertAlign = "middle";
    self.devMenuLine.x = 6;
    self.devMenuLine.y = 200;
    self.devMenuLine.alpha = 0.0;
  
    self.devMenuLine.curItem = 0;
  
    self.devMenuLine setShader("black", 200, 10);
  
    for(;;)
    {
		self waittill("update_devmenu");
		self updateDevMenu();
    }
}

updateDevMenu()
{
    if(isdefined(level.curselwp))
    {
		self.devMenuItem[2] deleteVectorValue();
		self.devMenuItem[3] deleteAllAddedValues();
		self.devMenuItem[5] deleteVectorValue();
	
		n = level.curselwp;
		for(i = 0; i < 5; i++)
		  self.devMenuItem[i].alpha = 1;
		  
		for(i = 0; i < 6; i++)
		  self.devMenuItem[i].color = (1.0, 1.0, 1.0);
	
		self.devMenuItem[0] setValue(n);
		
		switch(level.wp[n].type)
		{
		    case "w":
				self.devMenuItem[1].cur = 0;
				self.devMenuItem[1] setText(&"MBOTDEV_W");
				break;
		    case "f":
				self.devMenuItem[1].cur = 2;
				self.devMenuItem[1] setText(&"MBOTDEV_F");
				break;
		    case "c":
				self.devMenuItem[1].cur = 3;
				self.devMenuItem[1] setText(&"MBOTDEV_C");
				break;
		    case "j":
				self.devMenuItem[1].cur = 4;
				self.devMenuItem[1] setText(&"MBOTDEV_J");
				break;
		    case "m":
				self.devMenuItem[1].cur = 5;
				self.devMenuItem[1] setText(&"MBOTDEV_M");
				break;
		    case "l":
				self.devMenuItem[1].cur = 6;
				self.devMenuItem[1] setText(&"MBOTDEV_L");
				break;
		    default:
				self.devMenuItem[1] setText(&"MBOTDEV_EMPTY");
				break;
		}
		
		self.devMenuItem[2] setVectorValue(level.wp[n].origin, 50);
		
		if(isdefined(level.wp[n].next) && level.wp[n].next.size > 0)
		{
		    offset = 62;
		    for(i = 0; i < level.wp[n].next.size; i++)
			    offset = (self.devMenuItem[3] addValue(level.wp[n].next[i], offset));
		}
		
		switch(level.wp[n].stance)
		{
		    case 0:
				self.devMenuItem[4].cur = 0;
				self.devMenuItem[4] setText(&"MBOTDEV_STAND");
				break;
		    case 1:
				self.devMenuItem[4].cur = 1;
				self.devMenuItem[4] setText(&"MBOTDEV_CROUCH");
				break;
		    default:
				self.devMenuItem[4] setText(&"MBOTDEV_EMPTY");
				break;
		}
		
		if(level.wp[n].type == "g" || level.wp[n].type == "c" || level.wp[n].type == "w")
		{
		    self.devMenuItem[5].alpha = 1;
		    self.devMenuItem[5] setVectorValue(level.wp[n].angles, 50);
		}
		else
		{
		    self.devMenuItem[5].alpha = .5;
		}
	
		if(level.wp[n].type == "m")
		{
		    self.devMenuItem[6].alpha = 1;
		    switch(level.wp[n].mode)
		    {
				case 0:
				    self.devMenuItem[6].cur = 0;
				    self.devMenuItem[6] setText(&"MBOTDEV_UP");
				    break;
				case 1:
				    self.devMenuItem[6].cur = 1;
				    self.devMenuItem[6] setText(&"MBOTDEV_OVER");
				    break;
				default:
				    self.devMenuItem[6] setText(&"MBOTDEV_EMPTY");
				    break;
		    }
		}
		else
		{
		    self.devMenuItem[6].alpha = .5;
		    self.devMenuItem[6] setText(&"MBOTDEV_EMPTY");
		}
	
		self.devMenuLine.alpha = .4;
	}
	else
	{
		for(i = 0; i < 7; i++)
		{
		    self.devMenuItem[i].alpha = .5;
		    self.devMenuItem[i].color = (1.0, 1.0, 1.0);
		    self.devMenuItem[i] setText(&"MBOTDEV_EMPTY");
		}
		self.devMenuItem[2] deleteVectorValue();
		self.devMenuItem[3] deleteAllAddedValues();
		self.devMenuItem[5] deleteVectorValue();
	
		self.devMenuLine.alpha = 0.0;
		self.devMenuLine.curItem = 0;
		self.devMenuLine.y = 200;
	}
}

setVectorValue(vec, offset)
{
	if (!isDefined(vec))
		return;
		
    self.hud_vec = [];

    for(i = 0; i < 7; i++)
    {
		self.hud_vec[i] = newClientHudElem(level.plr);
		self.hud_vec[i].horzAlign = self.horzAlign;
		self.hud_vec[i].vertAlign = self.vertAlign;
		self.hud_vec[i].y = self.y;
		self.hud_vec[i].font = "default";
		self.hud_vec[i].fontscale = self.fontscale;
		self.hud_vec[i].archived = self.archived;
		self.hud_vec[i].alpha = self.alpha;
		self.hud_vec[i].color = self.color;
    }
  
    self.hud_vec[0].x = offset + 10;
    self.hud_vec[1].x = offset + 14;
    self.hud_vec[2].x = offset + 50;
    self.hud_vec[3].x = offset + 54;
    self.hud_vec[4].x = offset + 90;
    self.hud_vec[5].x = offset + 94;
    self.hud_vec[6].x = offset + 130;
  
    self.hud_vec[0] setText(&"MBOTDEV_LSKOBKA");
    self.hud_vec[1] setValue(vec[0]);
    self.hud_vec[2] setText(&"MBOTDEV_ZPT");
    self.hud_vec[3] setValue(vec[1]);
    self.hud_vec[4] setText(&"MBOTDEV_ZPT");
    self.hud_vec[5] setValue(vec[2]);
    self.hud_vec[6] setText(&"MBOTDEV_PSKOBKA");
}

deleteVectorValue()
{
    if(isdefined(self.hud_vec))
    {
        for(i = 0; i < 7; i++)
            self.hud_vec[i] destroy();
      
        self.hud_vec = undefined;
    }
}

addValue(val, offset)
{
    if(!isdefined(self.hud_add))
        self.hud_add = [];

    i = self.hud_add.size;
    self.hud_add[i] = newClientHudElem(level.plr);
    self.hud_add[i].horzAlign = self.horzAlign;
    self.hud_add[i].vertAlign = self.vertAlign;
    self.hud_add[i].x = offset;
    self.hud_add[i].y = self.y;
    self.hud_add[i].font = "default";
    self.hud_add[i].fontscale = self.fontscale;
    self.hud_add[i].archived = self.archived;
    self.hud_add[i].alpha = self.alpha;
  
    self.hud_add[i] setValue(val);
  
    newoffset = offset + 6;
    if(val >= 10000)
        newoffset += 24;
    else if(val >= 1000)
        newoffset += 18;
    else if(val >= 100)
        newoffset += 12;
    else if(val >= 10)
        newoffset += 6;
  
    return newoffset;
}

deleteAllAddedValues()
{
    if(isdefined(self.hud_add))
    {
        for(i = 0; i < self.hud_add.size; i++)
            self.hud_add[i] destroy();

        self.hud_add = undefined;
    }
}

//------------------------------------------------------------------------------------------
markSelectedWP(n)
{
    self endon("unselect");
    level.plr notify("update_devmenu");

    // Cepe7a -->
    if (!isDefined(level.model[n]))
	    spawnModelForNode(n);
    ring = 0;
    for(i=0; i<level.wp.size; i++)
	    level.wp[i].ring = undefined;
    // <-- Cepe7a
    endwp = undefined;
  
    for(;;)
    {
		ring++; // Cepe7a
		i = n;
		while(level.wp[i].next.size == 1)
		{
		    if(isDefined(level.wp[i].angles)) // Cepe7a
		    {
				vec = anglesToForward(level.wp[i].angles);
				vec = maps\mp\_utility::vectorScale(vec, 128);
				end = level.wp[i].origin + vec;
				line(level.wp[i].origin, end, (1.0, 0.0, 0.0), false);
		    }
		  
		    level.wp[i].ring = ring; // Cepe7a
		    next = level.wp[i].next[0];
		    line(level.wp[i].origin, level.wp[next].origin, (.2, .8, 1.0), false);
		    print3d((level.wp[next].origin + (0, 0, 15)), next, (.3, .8, 1.0), 1, 1);
		  
		    if (isdefined(level.wp[next].ring) && level.wp[next].ring == ring) break; // Cepe7a
		  
		    i = next;
		}
		
		print3d((level.wp[i].origin + (0, 0, 15)), i, (1.0, .7, .7), 1, 1);
		
		if(level.wp[i].next.size > 1)
		{
		    for(k = 0; k < level.wp[i].next.size; k++)
		    {
				next = level.wp[i].next[k];
				line(level.wp[i].origin, level.wp[next].origin, (1.0, 1.0, 1.0), false);
				print3d((level.wp[next].origin + (0, 0, 15)), next, (1.0, 1.0, 1.0), 1, 1);
		    }
		}
		
		print3d((self.origin + (0, 0, 15)), n, (1.0, 1.0, .2), 1, 1);
	
		wait .05;
    }
}

setNextNode(n)
{
    for(i = 0; i < self.next.size; i++)
    {
		if(self.next[i] == n)
		{
		    temp = self.next;
		    temp[i] = -1;
		    self.next = undefined;
		    self.next = [];
	
		    for(l = 0; l < temp.size; l++)
		    {
			    if(temp[l] != -1)
			        self.next[self.next.size] = temp[l];
		    }
		    return "unlinked";
		}
    }

    for(i = 0; i < level.wp[n].next.size; i++)
        if(level.wp[n].next[i] == level.curselwp)
            return "nothing";

    self.next[self.next.size] = n;
    return "linked";
}

spawnModelForNode(i)
{
	switch(level.wp[i].type)
	{
		case "w":
			level.model[i]= spawn("script_model", level.wp[i].origin);
				level.model[i].angles = (0.0, level.wp[i].angles[1], 0.0);
			level.model[i] setmodel("xmodel/wpprojectile_tank_shell");
		break;
		
		case "f":
			level.model[i]= spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/mp_eaglebust");
		break;
		
		case "c":
			level.model[i]= spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/mp_toilet");
		break;
		
		case "g":
			level.model[i]= spawn("script_model", level.wp[i].origin);
			level.model[i].angles = (0.0, level.wp[i].angles[1], 0.0);
			level.model[i] setmodel("xmodel/mp_eaglebust");
		break;
		
		case "j":
			level.model[i]= spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/mp_eaglebust");
		break;
		
		case "m":
			level.model[i]= spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/o_rs_prp_hydrant");
		break;
		
		case "l":
			level.model[i]= spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/o_rs_prp_hydrant");
		break;
		
		default:
		break;
	}
}

spawnNode(type, msg)
{
    i = level.wp.size;
    switch(type)
    {
        case "w":
			if (msg)
				iprintln(&"WP_TYPE_W"); // Cepe7a
			ang = self getplayerangles();
			
			level.model[i] = spawn("script_model", self.origin);
			level.model[i].angles = (0.0, ang[1], 0.0);
			level.model[i] setmodel("xmodel/wpprojectile_tank_shell");
	
			level.wp[i] = spawnstruct();
			level.wp[i].origin = self.origin;
			level.wp[i].type = "w";
			level.wp[i].next = [];
			level.wp[i].stance = 0;
			level.wp[i].angles = (ang[0], ang[1], 0.0);
	
			level.wp[i].selected = false;
			break;
			
        case "f":
			if (msg)
				iprintln(&"WP_TYPE_F"); // Cepe7a
			level.model[i] = spawn("script_model", self.origin);
			level.model[i] setmodel("xmodel/mp_eaglebust");
	
			level.wp[i] = spawnstruct();
			level.wp[i].origin = self.origin;
			level.wp[i].type = "f";
			level.wp[i].next = [];
			level.wp[i].stance = 0;
	
			level.wp[i].selected = false;
			break;
			
        case "c":
			if (msg)
				iprintln(&"WP_TYPE_C"); // Cepe7a
			level.model[i] = spawn("script_model", self.origin);
			level.model[i] setmodel("xmodel/mp_toilet");
			ang = self getplayerangles();
	
			level.wp[i] = spawnstruct();
			level.wp[i].origin = self.origin;
			level.wp[i].type = "c";
			level.wp[i].next = [];
			level.wp[i].stance = 0;
			level.wp[i].angles = (ang[0], ang[1], 0.0);
	
			level.wp[i].selected = false;
			break;
			
        case "j":
			if (msg)
				iprintln(&"WP_TYPE_J"); // Cepe7a
			level.model[i] = spawn("script_model", self.origin);
			level.model[i] setmodel("xmodel/mp_eaglebust");
	
			level.wp[i] = spawnstruct();
			level.wp[i].origin = self.origin;
			level.wp[i].type = "j";
			level.wp[i].next = [];
			level.wp[i].stance = 0;
	
			level.wp[i].selected = false;
			break;
			
        case "m":
			if (msg)
				iprintln(&"WP_TYPE_M"); // Cepe7a
			level.model[i] = spawn("script_model", self.origin);
			level.model[i] setmodel("xmodel/o_rs_prp_hydrant");
	
			level.wp[i] = spawnstruct();
			level.wp[i].origin = self.origin;
			level.wp[i].type = "m";
			level.wp[i].next = [];
			level.wp[i].stance = 0;
			level.wp[i].mode = 0;
	
			level.wp[i].selected = false;
			break;
			
        case "l":
			if (msg)
				iprintln(&"WP_TYPE_L"); // Cepe7a
			level.model[i] = spawn("script_model", self.origin);
			level.model[i] setmodel("xmodel/o_rs_prp_hydrant");
	
			level.wp[i] = spawnstruct();
			level.wp[i].origin = self.origin;
			level.wp[i].type = "l";
			level.wp[i].next = [];
			level.wp[i].stance = 0;
	
			level.wp[i].selected = false;
			break;
			
        default:
            break;
    }
}

dumpWPs()
{
    level.dumpingpoints = true;
	setCvar("logfile", 1);
	
	mapname = getCvar("mapname");
	gametype = getCvar("g_gametype");
	filename = mapname + "_" + gametype + ".gsc";

	info = [];
	info[0] = " ";
	info[1] = " ";
	info[2] = " ";
	info[3] = "// =========================================================================================";
	info[4] = "// File Name = '" + filename + "'";
	info[5] = "// Map Name  = '" + mapname + "'";
	info[6] = "// =========================================================================================";
	info[7] = "// ";
	info[8] = "// This file contains the waypoints for the map '" + mapname + "'.";	
	info[9] = "// ";
	info[10] = "// Save the info between the cut points to a file called " + filename + " and save it in your";
	info[11] = "// waypoints folder found inside this mod's own directory (overwrite if the file already exists).";
	info[12] = "// =========================================================================================";
	info[13] = " ";	
	info[14] = "/*=================< CUT HERE >=====================*/";
	
	for(i = 0; i < info.size; i++)
		println(info[i]);
	
	scriptstart = [];
	scriptstart[0] = "load_waypoints()";
	scriptstart[1] = "{";
	
	for(i = 0; i < scriptstart.size; i++)
		println(scriptstart[i]);
	
	for(j = 0; j < level.wp.size; j++)
    {
        waypointstruct = "    level.wp[" + j + "] = spawnstruct();";
		println(waypointstruct);
   
        if(isdefined(level.wp[j].type))
        {
            switch(level.wp[j].type)
            {
                case "w":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
		  
		            if (isDefined(level.wp[j].angles))	// Cepe7a
		            {
			            waypointangles = "    level.wp[" + j + "].angles = "+ "(" + level.wp[j].angles[0] + "," + level.wp[j].angles[1] + "," + " 0.0);";
		                println(waypointangles);
		            }
					if (!isDefined(level.wp[j].angles))
						{
							if (isDefined(level.wp[j].next.size))
							{
								targetPos = level.wp[level.wp[j].next[0]].origin;
								eyePos = level.wp[j].origin;
								fwdDir = vectorNormalize(targetPos-eyePos);
								moveDir = level.wp[j].next[0].origin-level.wp[j].origin;
								moveDir = VectorNormalize((moveDir[0], moveDir[1], 0));       
								level.wp[j].angles = vectorToAngles(VectorNormalize(fwdDir, moveDir, 0.5));
								waypointangles = "    level.wp[" + j + "].angles = "+ "(" + level.wp[j].angles[0] + "," + level.wp[j].angles[1] + "," + " 0.0);";
							}
							else
								waypointangles = "    level.wp[" + j + "].angles = "+ "(" + "0.0" + "," + "0.0" + "," + " 0.0);";
								
							println(waypointangles);
						}
                break;
		
                case "g":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
		
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }

		            waypointangles = "    level.wp[" + j + "].angles = "+ "(" + level.wp[j].angles[0] + "," + level.wp[j].angles[1] + "," + " 0.0);";
		            println(waypointangles);
                break;
		
                case "f":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
                break;
		
                case "c":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
                    
					if (!isDefined(level.wp[j].angles))
					    waypointangles = "    level.wp[" + j + "].angles = "+ "(" + "0.0" + "," + "0.0" + "," + " 0.0);";
					else
		                waypointangles = "    level.wp[" + j + "].angles = "+ "(" + level.wp[j].angles[0] + "," + level.wp[j].angles[1] + "," + " 0.0);";
		            println(waypointangles);
                break;
		
                case "j":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
                break;
		
                case "m":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }

		            if(!isdefined(level.wp[j].mode)) level.wp[j].mode = 0;
					waypointmode = "    level.wp[" + j + "].mode = " + level.wp[j].mode + ";";
		            println(waypointmode);
                break;
		
                case "l":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
                break;
            }
        }
		wait .01;
    }
	
	scriptend = [];
	scriptend[0] = "}";
	scriptend[1] = " ";
	scriptend[2] = "/*=================< CUT HERE >=====================*/";
	scriptend[3] = " ";
	scriptend[4] = " ";
	scriptend[5] = " ";
	scriptend[6] = " ";
	scriptend[7] = " ";
	scriptend[8] = " ";
	
	for(i = 0; i < scriptend.size; i++)
		println(scriptend[i]);

	setCvar("logfile", 0);
	
	wait 1;
	iprintlnBold("Meatbot waypoints saved");
	wait 1;
	iprintlnBold("^7Close Game & Follow Instructions In File");
	wait 0.5;
	level.dumpingpoints = false;
    return true;
}

tempDumpWPs()
{
    level.dumpingpoints = true;
	setCvar("logfile", 1);
	
	mapname = getCvar("mapname");
	gametype = getCvar("g_gametype");
	filename = mapname + "_" + gametype + ".gsc";

    iprintln("One moment, storing waypoints...");
	wait 2;
	info = [];
	info[0] = " ";
	info[1] = " ";
	info[2] = " ";
	info[3] = "// =========================================================================================";
	info[4] = "// File Name = '" + filename + "'";
	info[5] = "// Map Name  = '" + mapname + "'";
	info[6] = "// =========================================================================================";
	info[7] = "// ";
	info[8] = "// This file contains the waypoints for the map '" + mapname + "'.";	
	info[9] = "// ";
	info[10] = "// Save the info between the cut points to a file called " + filename + " and save it in your";
	info[11] = "// waypoints folder found inside this mod's own directory (overwrite if the file already exists).";
	info[12] = "// =========================================================================================";
	info[13] = " ";	
	info[14] = "/*=================< CUT HERE >=====================*/";
	
	for(i = 0; i < info.size; i++)
		println(info[i]);
	
	scriptstart = [];
	scriptstart[0] = "load_waypoints()";
	scriptstart[1] = "{";
	
	for(i = 0; i < scriptstart.size; i++)
		println(scriptstart[i]);
	
	for(j = 0; j < level.wp.size; j++)
    {
        waypointstruct = "    level.wp[" + j + "] = spawnstruct();";
		println(waypointstruct);
   
        if(isdefined(level.wp[j].type))
        {
            switch(level.wp[j].type)
            {
                case "w":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
		  
		            if (isDefined(level.wp[j].angles))	// Cepe7a
		            {
			            waypointangles = "    level.wp[" + j + "].angles = "+ "(" + level.wp[j].angles[0] + "," + level.wp[j].angles[1] + "," + " 0.0);";
		                println(waypointangles);
		            }
                break;
		
                case "g":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
		
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }

		            waypointangles = "    level.wp[" + j + "].angles = "+ "(" + level.wp[j].angles[0] + "," + level.wp[j].angles[1] + "," + " 0.0);";
		            println(waypointangles);
                break;
		
                case "f":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
                break;
		
                case "c":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }

		            waypointangles = "    level.wp[" + j + "].angles = "+ "(" + level.wp[j].angles[0] + "," + level.wp[j].angles[1] + "," + " 0.0);";
		            println(waypointangles);
                break;
		
                case "j":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
                break;
		
                case "m":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }

		            if(!isdefined(level.wp[j].mode)) level.wp[j].mode = 0;
					waypointmode = "    level.wp[" + j + "].mode = " + level.wp[j].mode + ";";
		            println(waypointmode);
                break;
		
                case "l":
		            waypointstring = "    level.wp[" + j + "].origin = "+ "(" + level.wp[j].origin[0] + "," + level.wp[j].origin[1] + "," + level.wp[j].origin[2] + ");";
		            println(waypointstring);
		            waypointtype = "    level.wp[" + j + "].type = " + "\"" + level.wp[j].type + "\"" + ";";
		            println(waypointtype);
		            waypointnext = "    level.wp[" + j + "].next = [];";
		            println(waypointnext);
		            waypointstance = "    level.wp[" + j + "].stance = " + level.wp[j].stance + ";";
		            println(waypointstance);
			
                    for(k = 0; k < level.wp[j].next.size; k++)
		            {
		                waypointnextnext = "    level.wp[" + j + "].next[" + k + "] = " + level.wp[j].next[k] + ";";
		                println(waypointnextnext);
		            }
                break;
            }
			
        }
		wait .01;
    }
	scriptend = [];
	scriptend[0] = "}";
	scriptend[1] = " ";
	scriptend[2] = "/*=================< CUT HERE >=====================*/";
	scriptend[3] = " ";
	scriptend[4] = " ";
	scriptend[5] = " ";
	scriptend[6] = " ";
	scriptend[7] = " ";
	scriptend[8] = " ";
	
	for(i = 0; i < scriptend.size; i++)
		println(scriptend[i]);

	setCvar("logfile", 0);
	
	wait 1;
	iprintln("Meatbot waypoints stored");
	wait 0.5;
	level.dumpingpoints = false;
    return true;
}

// Cepe7a -->
CheckErrors(showall, startwp)
{
	println("^2Checking for errors...");
	noerr = true;
	
	if (isDefined(startwp))
		n = startwp;
	else
		n = 0;
		
	for(i = 0; i < level.wp.size; i++)
	{
		if (n>=level.wp.size)
			n = 0;
			
		if(level.wp[n].next.size == 0) 
		{
			if (!showall)
			{
				iprintln(&"WP_WRN_NO_NEXT", n);
				return n;
			}
			println(": ^3Warning! Waypoint #" + n + " have no next waypoints");
			noerr = false;
		}
     
		if((level.wp[n].type == "f" || level.wp[n].type == "j" || level.wp[n].type == "m" || level.wp[n].type == "l") && level.wp[n].next.size > 1) 
		{
			if (!showall) 
			{
				switch(level.wp[n].type)
				{
					case "w":
						type = &"MBOTDEV_W";
						break;
					case "f":
						type = &"MBOTDEV_F";
						break;
					case "c":
						type = &"MBOTDEV_C";
						break;
					case "j":
						type = &"MBOTDEV_J";
						break;
					case "m":
						type = &"MBOTDEV_M";
						break;
					case "l":
						type = &"MBOTDEV_L";
						break;
					default:
						type = &"UNKNOWN";
						break;
				}
				iprintln(&"WP_WRN_MORE_ONE", n, type);
				return n;
			}
			println(": ^3Warning! Waypoint #" + n + " of type \"" + level.wp[n].type + "\" have more then one next waypoints");
			noerr = false;
		}
		n++;
	}
	if (noerr) 
	{
		if (showall)
			println("^2No errors");
		else 
			iprintln(&"WP_NO_ERRORS");
		return -1;
	}

}

bulletTracePassed(pointa, pointb, character, entity)
{
    visTrace = bullettrace(pointa, pointb, character, entity);
    if(visTrace["fraction"] == 1)
        return true;
    else
        return false;
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

strtoflt(str)
{
  setCvar("__tmp_f", str);
  flt = getCvarFloat("__tmp_f");
  return flt;
}

getplayerangles()
{
    return self.angles;
}