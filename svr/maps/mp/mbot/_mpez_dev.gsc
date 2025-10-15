init()
{
    setCvar("bot_dumpwps", "");
    setCvar("ChangeWaypointType", "");
    setCvar("bot_addkp", "");
	level.plr thread Deb();
	level.plr thread StartDev();
	thread DrawStaticWaypoints();
	level.plr thread devLegend();
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
			AddWaypoint(org);
		}
		bFlag = true;
	}
}

GetButtonPressed()
{
    if(isDefined(self))
    {
		if(self attackbuttonpressed())
		{
			switch(self getStance())
			{
				case "prone":
					return "none";
					
				case "crouch":
					return "DeleteWaypoint";
					
				default:
				case "stand":
					return "AddWaypoint";
			}
		}
		else
		if(self usebuttonpressed())
		{
			switch(self getStance())
			{
				case "prone":
					return "SaveWaypoints";
					
				case "crouch":
					return "UnlinkWaypoint";
					
				default:
				case "stand":
					return "LinkWaypoint";
			}
		}
    }
  
    return "none";
}

CanDebugDraw()
{
    if(getCvarInt("bot_debug") >= 1)
        return true;
    else
        return false;
}

StartDev()
{
	wait 5;
    level.wpToLink = -1;
    level.linkSpamTimer = gettime();
    level.saveSpamTimer = gettime();
	level.changeSpamTimer = gettime();
    curselwp = undefined;
    lastview = undefined; 
    startorigin = undefined;
    lastwp = undefined;
    autowp = false;
	setCvar("sp_gotonextsp", "0");

    while(1)
    {
        while(level.dumpingpoints)
		    wait 0.5;
		
		level.players = getentarray("player", "classname");
	    level.playerPos = level.players[0].origin;
	    dvar = getCvarInt("bot_autowp");
		
	    if (!autowp && dvar>32)
	    {
		    level.wpToLink = -1;
			iprintln(&"WP_AUTO_ON", dvar);
		    autowp = true;
			
		    if (isdefined(level.curselwp))
		    {
				level.wp[level.curselwp].selected = false;
			    level.wp[level.curselwp] notify("unselect");
			    wait .05;
		    }
		    
			AddautoWaypoint(level.playerPos);
		    lastwp = level.wp.size-1;
		    level.wp[lastwp].selected = true;
            level.curselwp = lastwp;
		    lastview = level.wp[lastwp].origin;
		    startorigin = lastview;
	    }
	    else
	    if (autowp && (distance(level.playerPos, lastview) > 32 || dvar<32))
	    {
			if (dvar<32) 
		    {
			    iprintln(&"WP_AUTO_OFF");
			    autowp = false;
			    startmark = undefined;
		    }

		    dist = distance(level.playerPos, startorigin);
		    view = false;
			
		    for (i=0; i<level.viewofs.size; i++)
		    {
			    view = bullettracepassed(level.playerPos+level.viewofs[i], startorigin+level.viewofs[i], false, self);
			    if (!view)
				    break;
		    }
		
		    if(!view || dist > dvar || (!autowp && dist > 32)) 
		    {
				AddAutoWaypoint(level.playerPos);
			    lastwp = dist;
			    startorigin = lastview;	
		    }
		    lastview = level.playerPos;
	    }
		
		dvar = getCvar("sp_gotonextsp");
	    if (dvar != "0") 
	    { 
            
			if(isdefined(level.players))
			{
				CurrentSpawnpoint = -1;
				CurrentSpawnpoint = GetNearestSpawnpoint(level.playerPos);
				
				size = level.spawnpoints.size;

				if(CurrentSpawnpoint >= size-1)
				    CurrentSpawnpoint = (size-1) - CurrentSpawnpoint;
				else
                    CurrentSpawnpoint = CurrentSpawnpoint+1;
            
				level.players[0] setplayerangles(level.spawnpoints[CurrentSpawnpoint].angles);
                level.players[0] setOrigin(level.spawnpoints[CurrentSpawnpoint].origin);
				iprintln("Current Spawnpoint is " + CurrentSpawnpoint);
				
				setCvar("sp_gotonextsp", "0");
			}
		}
	
		dvar = getCvar("bot_dumpwps");
		if(dvar != "")
		{
			SavevBotStaticWaypoints();
				wait .5;
			setCvar("bot_dumpwps", "");
		}
		
		dvar = getCvar("ChangeWaypointType");
		if(dvar != "")
		{
			ChangeWaypointType(level.playerPos);
				wait .5;
			setCvar("ChangeWaypointType", "");
		}
		
		dvar = getCvar("deletewp");
		if(dvar != "")
		{
			DeleteWaypoint(level.playerPos);
				level.wpToLink = -1;
				wait .5;
			setCvar("deletewp", "");
		}
		
		dvar = getCvar("bot_addkp");
        if(dvar != "")
        {
				AddKillpoint(level.playerPos);
			    wait .5;
                setCvar("bot_addkp", "");
        }
		
		switch(level.players[0] GetButtonPressed())
		{
			case "AddWaypoint":
			{
				AddWaypoint(level.playerPos);
				break;
			}
		  
			case "DeleteWaypoint":
			{
				DeleteWaypoint(level.playerPos);
				level.wpToLink = -1;
				break;
			}
		  
			case "LinkWaypoint":
			{
				LinkWaypoint(level.playerPos);
				break;
			}
		  
			case "UnlinkWaypoint":
			{
				UnLinkWaypoint(level.playerPos);
				break;
			}
		  
			case "SaveWaypoints":
			{
				SavevBotStaticWaypoints();
				break;
			}
		
			default:
				break;
		}
        wait 0.001;  
    }
}

DrawStaticWaypoints()
{
    while(1)
    {
        if(CanDebugDraw() && isDefined(level.wp) && isDefined(level.wpsize) && level.wpsize > 0)
        {
            wpDrawDistance = getCvarint("bot_drawrange");
    
            for(i = 0; i < level.wpsize; i++)
            {
                if(isdefined(level.players) && isdefined(level.players[0]))
                {
                    distance = distance(level.players[0].origin, level.wp[i].origin);
                    if(distance > wpDrawDistance)
                    {
                        continue;
                    }
                }
                color = (0,0,1);

				if(level.wp[i].nextCount == 0)
				    color = (1,0,0);

				else
				if(level.wp[i].nextCount == 1)
				    color = (1,0,1);

				else
				if(level.wp[i].type == "l")
				    color = (1,1,0);

				else
				    color = (0,1,0);
		
				if(isdefined(level.players) && isdefined(level.players[0]))
				{
				    distance = distance(level.wp[i].origin, level.players[0].origin);
				    if(distance <= 30.0)
				    {
						strobe = abs(sin(gettime()/10.0));
						color = (color[0]*strobe,color[1]*strobe,color[2]*strobe);
				    }
				}
		
				line(level.wp[i].origin, level.wp[i].origin + (0,0,80), color);
				
				for(x = 0; x < level.wp[i].nextCount; x++)
				    line(level.wp[i].origin + (0,0,5), level.wp[level.wp[i].next[x]].origin + (0,0,5), (0,0,1));
            }
			
			if(isdefined(level.kp))
			{
				for(i = 0; i < level.kpCount; i++)
				{
					if(isdefined(level.players) && isdefined(level.players[0]))
					{
						distance = distance(level.players[0].origin, level.kp[i].origin);

						if(distance > wpDrawDistance)
							continue;
					}
					
					color = (0,0,1);
	
					if(level.kp[i].nextCount == 0)
						color = (1,0,0);

					else
					if(level.kp[i].nextCount == 1)
						color = (1,0,1);

					else
						color = (1,0,0);
	
					if(isdefined(level.players) && isdefined(level.players[0]))
					{
						distance = distance(level.players[0].origin, level.kp[i].origin);
						if(distance <= 50.0)
						{
							strobe = abs(sin(gettime()/10.0));
							color = (color[0]*strobe,color[1]*strobe,color[2]*strobe);
						}
					}
	
					line(level.kp[i].origin, level.kp[i].origin + (0,0,80), color);
			
					for(x = 0; x < level.kp[i].nextCount; x++)
						line(level.kp[i].origin + (0,0,5), level.kp[level.kp[i].next[x]].origin + (0,0,5), (0,0,1));
				}
			}
        }
        wait 0.001;
    }
}

AddWaypoint(pos)
{
    for(i = 0; i < level.wpsize; i++)
    {
        distance = distance(level.wp[i].origin, pos);
    
        if(distance <= 30.0)
            return;
    }

    level.wp[level.wpsize] = spawnstruct();
    level.wp[level.wpsize].origin = pos;
    level.wp[level.wpsize].type = "w";
    level.wp[level.wpsize].next = [];
    level.wp[level.wpsize].nextCount = 0;
    level.wpsize++;
  
    iprintln("Waypoint Added");
}

AddAutoWaypoint(pos)
{
    for(i = 0; i < level.spawnpoints.size; i++)
    {
        distance = distance(level.spawnpoints[i].origin, pos);
    
        if(distance <= 30.0)
        {
            LinkWaypoint(level.playerPos);
	        return;
        }
    }
	for(i = 0; i < level.wpsize; i++)
    {
        distance = distance(level.wp[i].origin, pos);
    
        if(distance <= 30.0)
        {
            LinkWaypoint(level.playerPos);
	        return;
        }
    }

    level.wp[level.wpsize] = spawnstruct();
    level.wp[level.wpsize].origin = pos;
    level.wp[level.wpsize].type = "w";
    level.wp[level.wpsize].next = [];
    level.wp[level.wpsize].nextCount = 0;
    level.wpsize++;

    iprintln("Waypoint Added");
    LinkWaypoint(level.playerPos);
    wait .5;
    LinkWaypoint(level.playerPos);
}

DeleteWaypoint(pos)
{
    for(i = 0; i < level.wpsize; i++)
    {
        distance = distance(level.wp[i].origin, pos);
    
		if(distance <= 30.0)
		{
			for(c = 0; c < level.wp[i].nextCount; c++)
			{
				for(c2 = 0; c2 < level.wp[level.wp[i].next[c]].nextCount; c2++)
				{
					if(level.wp[level.wp[i].next[c]].next[c2] == i)
					{
						for(c3 = c2; c3 < level.wp[level.wp[i].next[c]].nextCount-1; c3++)
							level.wp[level.wp[i].next[c]].next[c3] = level.wp[level.wp[i].next[c]].next[c3+1];

						level.wp[level.wp[i].next[c]].nextCount--;
						break;
					}
				}
			}
		  
			for(x = i; x < level.wpsize-1; x++)
				level.wp[x] = level.wp[x+1];

			level.wpsize--;
	
			for(r = 0; r < level.wpsize; r++)
			{
				for(c = 0; c < level.wp[r].nextCount; c++)
				{
					if(level.wp[r].next[c] > i)
						level.wp[r].next[c]--;
				}
			}
			iprintln("Waypoint Deleted");
		  
			return;
		}
    }
}

LinkWaypoint(pos)
{
    if((gettime()-level.linkSpamTimer) < 100)
        return;

    level.linkSpamTimer = gettime();
  
    wpToLink = -1;
  
    for(i = 0; i < level.wpsize; i++)
    {
        distance = distance(level.wp[i].origin, pos);
        if(distance <= 30.0)
        {
            wpToLink = i;
            break;
        }
    }
  
    if(wpToLink != -1)
    {
		if(level.wpToLink != -1 && level.wpToLink != wpToLink)
		{
		    level.wp[level.wpToLink].next[level.wp[level.wpToLink].nextCount] = wpToLink;
		    level.wp[level.wpToLink].nextCount++;
		  
		    level.wp[wpToLink].next[level.wp[wpToLink].nextCount] = level.wpToLink;
		    level.wp[wpToLink].nextCount++;
		  
		    iprintln("Waypoint " + wpToLink + " Linked to " + level.wpToLink);
		    level.wpToLink = -1;
		}
		else
		{
		    level.wpToLink = wpToLink;
		    iprintln("Waypoint Link Started");
		}
    }
    else
    {
        level.wpToLink = -1;
        iprintln("Waypoint Link Cancelled");
    }
}

UnLinkWaypoint(pos)
{
    if((gettime()-level.linkSpamTimer) < 1000)
        return;

    level.linkSpamTimer = gettime();
  
    wpToLink = -1;
  
    for(i = 0; i < level.wpsize; i++)
    {
        distance = distance(level.wp[i].origin, pos);
		if(distance <= 30.0)
		{
		  wpToLink = i;
		  break;
		}
    }

    if(wpToLink != -1)
    {
        if(level.wpToLink != -1 && level.wpToLink != wpToLink)
        {
            for(i = 0; i < level.wp[level.wpToLink].nextCount; i++)
            {
                if(level.wp[level.wpToLink].next[i] == wpToLink)
                {
                    for(c = i; c < level.wp[level.wpToLink].nextCount-1; c++)
                        level.wp[level.wpToLink].next[c] = level.wp[level.wpToLink].next[c+1];

                    level.wp[level.wpToLink].nextCount--;
                    break;
                }
            }
      
            for(i = 0; i < level.wp[wpToLink].nextCount; i++)
            {
                if(level.wp[wpToLink].next[i] == level.wpToLink)
                {
                    for(c = i; c < level.wp[wpToLink].nextCount-1; c++)
                        level.wp[wpToLink].next[c] = level.wp[wpToLink].next[c+1];

                    level.wp[wpToLink].nextCount--;
                    break;
                }
            }
            iprintln("Waypoint " + wpToLink + " Broken to " + level.wpToLink);
            level.wpToLink = -1;
        }
		else
		{
		    level.wpToLink = wpToLink;
		    iprintln("Waypoint Link Started");
		}
    }
    else
    {
		level.wpToLink = -1;
		iprintln("Waypoint Link Cancelled");
    }
}

SavevBotStaticWaypoints()
{
	level.dumpingpoints = true;
	setCvar("logfile", 1);

	mapname = getCvar("mapname");
	filename = mapname + "_waypoints.gsc";

	info = [];
	info[0] = "// =========================================================================================";
	info[1] = "// File Name = '" + filename + "'";
	info[2] = "// Map Name  = '" + mapname + "'";
	info[3] = "// =========================================================================================";
	info[4] = "// ";
	info[5] = "// This is an auto generated script file created by the Meatbot Mod - DO NOT MODIFY!";
	info[6] = "// ";
	info[7] = "// =========================================================================================";
	info[8] = "// ";
	info[9] = "// This file contains PeZBOT waypoints for the map '" + mapname + "'.";	
	info[10] = "// ";
	info[11] = "// You need to save this file as the file name at the top of this file into";
	info[12] = "// the 'waypoints' folder of this mod. Delete the first two lines of this";
	info[13] = "// file and the 'dvar set logfile 0' at the end of the file.";
	info[14] = "// ";
	info[15] = "// You now need to edit the file 'select_map.gsc' in the waypoints folder and";
	info[16] = "// add the following code.";
	info[17] = "/*";
	info[18] = " ";
	info[19] = "    else if(mapname == '"+ mapname +"')";
	info[20] = "    {";
	info[21] = "        thread Waypoints/" + mapname + "_waypoints::load_waypoints();";
	info[22] = "    }";
	info[23] = " ";
	info[24] = "*/ ";
	info[25] = "// =========================================================================================";
	info[26] = " ";	
	
	for(i = 0; i < info.size; i++)
		println(info[i]);

	scriptstart = [];
	scriptstart[0] = "load_waypoints()";
	scriptstart[1] = "{";
	scriptstart[2] = " ";
	
	for(i = 0; i < scriptstart.size; i++)
		println(scriptstart[i]);

	for(w = 0; w < level.wpsize; w++)
	{
		waypointstruct = "    level.wp[" + w + "] = spawnstruct();";
		println(waypointstruct);
	
		waypointstring = "    level.wp[" + w + "].origin = "+ "(" + level.wp[w].origin[0] + "," + level.wp[w].origin[1] + "," + level.wp[w].origin[2] + ");";
		println(waypointstring);

		waypointtype = "    level.wp[" + w + "].type = " + "\"" + level.wp[w].type + "\"" + ";";
		println(waypointtype);
		
		waypointnext = "    level.wp[" + w + "].next = [];";
		println(waypointnext);
		
		waypointstance = "    level.wp[" + w + "].stance = " + "0" + ";";
		println(waypointstance);
		
		waypointchild = "    level.wp[" + w + "].nextCount = " + level.wp[w].nextCount + ";";
		println(waypointchild);

		for(c = 0; c < level.wp[w].nextCount; c++)
		{
			childstring = "    level.wp[" + w + "].next[" + c + "] = " + level.wp[w].next[c] + ";";
			println(childstring);
            wait 0.01;    
		}
		
		iprintln("Waypoint " + (w + 1)+ " Saved.");		
	}
	
	scriptmiddle = [];
	scriptmiddle[0] = " ";
	scriptmiddle[1] = "    level.wpsize = level.wp.size;";
	scriptmiddle[2] = " ";
	
	for(i = 0; i < scriptmiddle.size; i++)
		println(scriptmiddle[i]);
	
	if(isdefined(level.kp))
	{
		for(x = 0; x < level.kpCount; x++)
		{
			waypointstruct = "    level.kp[" + x + "] = spawnstruct();";
			println(waypointstruct);
		
			waypointstring = "    level.kp[" + x + "].origin = "+ "(" + level.kp[x].origin[0] + "," + level.kp[x].origin[1] + "," + level.kp[x].origin[2] + ");";
			println(waypointstring);
	
			waypointtype = "    level.kp[" + x + "].type = " + "\"" + level.kp[x].type + "\"" + ";";
			println(waypointtype);
			
			waypointchild = "    level.kp[" + x + "].nextCount = " + level.kp[x].nextCount + ";";
			println(waypointchild);
			
			for(d = 0; d < level.kp[x].nextCount; d++)
			{
				childstring = "    level.kp[" + x + "].next[" + d + "] = " + level.kp[x].next[d] + ";";
				println(childstring);      
			}	
		}
	}
	
	scriptend = [];
	
	if(isdefined(level.kp))
	{
	    scriptend[0] = " ";
		scriptend[1] = "    level.kpCount = level.kp.size;";
	    scriptend[2] = "}";
	}
	else
	   scriptend[0] = "}";
	
	for(i = 0; i < scriptend.size; i++)
		println(scriptend[i]);

	setCvar("logfile", 0);
    level.dumpingpoints = false;
	wait 1;
	iprintlnBold("^7PeZBOT waypoints saved");
	wait 1;
	iprintlnBold("^7Close Game & Follow Instructions In File");
	wait 0.5;
}

bulletTracePassed(pointa, pointb, character, entity)
{
    visTrace = bullettrace(pointa, pointb, character, entity);
    if(visTrace["fraction"] == 1)
        return true;
    else
        return false;
}

abs(var)
{
	if (var < 0)
		var = var * (-1);
	return var;	
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
    self.devLegendItem1.label = (&"MBOTDEV_LEGEND2");
	
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

ChangeWaypointType(pos)
{
    if((gettime()-level.changeSpamTimer) < 1000)
        return;

    level.changeSpamTimer = gettime();
  
    wpTochange = -1;
  
    for(i = 0; i < level.wpsize; i++)
    {
        distance = distance(level.wp[i].origin, pos);
    
        if(distance <= 30.0)
        {
            wpTochange = i;
            break;
        }
    }
  
	if(wpTochange != -1)
    {
        if(level.wp[wpTochange].type == "w")
        { 
            level.wp[wpTochange].type = "l";
            iprintln(&"MBOTDEV_CHANGE_CLIMB");
			angle = level.plr.angles;
			level.wp[wpTochange].angles = angle;
			return;
        }
		
		if(level.wp[wpTochange].type == "l")
        { 
            level.wp[wpTochange].type = "w";
            iprintln(&"MBOTDEV_CHANGE_NORMAL");
			angle = level.plr.angles;
			level.wp[wpTochange].angles = -1;
			return;
        }
    }
}

AddKillpoint(pos)
{
    if(!isdefined(level.kpCount)) level.kpCount = 0;
	else
	{
		for(i = 0; i < level.kpCount; i++)
		{
			distance = distance(level.kp[i].origin, pos);
		
			if(distance <= 50.0)
				return;
		}
	}

    level.kp[level.kpCount] = spawnstruct();
    level.kp[level.kpCount].origin = pos;
    level.kp[level.kpCount].type = "k";
    level.kp[level.kpCount].next = [];
    level.kp[level.kpCount].nextCount = 0;
    level.kpCount++;

    iprintln(&"MBOTDEV_KILLPOINT_ADD");
}
