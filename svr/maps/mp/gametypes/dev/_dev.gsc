main()
{
	wait 5;
	level.wpToLink = -1;
	level.linkSpamTimer = gettime();
	level.saveSpamTimer = gettime();
	level.typeSpamTimer = gettime(); // Add timer for type cycling
	level.currentWaypointType = "stand"; // Default waypoint type

	thread DrawStaticWaypoints();

	players = getentarray("player", "classname");
	for(i = 0; i < players.size; i++)
		players[i] thread playerstart();
  
}
GetButtonPressed()
{
  if(isDefined(self))
  {
    if(self attackbuttonpressed())
    {
      // Check if scr_type cvar is set to 1 for waypoint type cycling
      if(getcvarint("scr_type") == 1)
      {
        return "CycleWaypointType";
      }
      else
      {
        return "AddWaypoint";
      }
    }
    else
    if(self usebuttonpressed())
    {
      return "LinkWaypoint";
    }
    else
    if(self meleebuttonpressed())
    {
      return "DeleteWaypoint";
    }
  }
  
  return "none";
}
playerstart()
{
  while(1)
  {
    level.playerPos = self.origin;
    switch(self GetButtonPressed())
    {
      case "AddWaypoint":
      {
        AddWaypoint(level.playerPos);
        break;
      }
      
      
      case "LinkWaypoint":
      {
        LinkWaypoint(level.playerPos);
        break;
      }

      case "DeleteWaypoint":
      {
	if(getcvarint("scr_saven") == 1)
		SaveStaticWaypoints();
	else
        	DeleteWaypoint(level.playerPos);
        break;
      }
      
      case "CycleWaypointType":
      {
        CycleWaypointType(level.playerPos);
        break;
      }
    
      default:
        break;
    }

    wait 0.001;  
  }
}

////////////////////////////////////////////////////////////
// Cycles through waypoint types: stand -> crouch -> jump -> prone -> stand
////////////////////////////////////////////////////////////
CycleWaypointType(pos)
{
  // Don't spam type cycling
  if((gettime()-level.typeSpamTimer) < 500)
  {
    return;
  }
  level.typeSpamTimer = gettime();
  
  // Find the nearest waypoint
  nearestWaypoint = -1;
  for(i = 0; i < level.waypointCount; i++)
  {
    distance = distance(level.waypoints[i].origin, pos);
    
    if(distance <= 30.0)
    {
      nearestWaypoint = i;
      break;
    }
  }
  
  // Only cycle type if we're near a waypoint
  if(nearestWaypoint != -1)
  {
    // Debug: Check if waypoint has a type field
    iprintln("^3Debug: Waypoint " + nearestWaypoint + " type check");
    
    // Check if waypoint has a type field, default to "stand" if not
    if(!isDefined(level.waypoints[nearestWaypoint].type))
    {
      level.waypoints[nearestWaypoint].type = "stand";
      iprintln("^3Debug: Set waypoint " + nearestWaypoint + " type to stand");
    }
    
    // Get current type with fallback
    currentType = level.waypoints[nearestWaypoint].type;
    if(currentType == "" || !isDefined(currentType))
    {
      currentType = "stand";
      level.waypoints[nearestWaypoint].type = "stand";
    }
    
    iprintln("^3Debug: Current type is: " + currentType);
    
    switch(currentType)
    {
      case "stand":
        level.waypoints[nearestWaypoint].type = "crouch";
        iprintln("^2Waypoint " + nearestWaypoint + " Type: ^7Crouch");
        break;
      case "crouch":
        level.waypoints[nearestWaypoint].type = "jump";
        iprintln("^2Waypoint " + nearestWaypoint + " Type: ^7Jump");
        break;
      case "jump":
        level.waypoints[nearestWaypoint].type = "prone";
        iprintln("^2Waypoint " + nearestWaypoint + " Type: ^7Prone");
        break;
      case "prone":
        level.waypoints[nearestWaypoint].type = "stand";
        iprintln("^2Waypoint " + nearestWaypoint + " Type: ^7Stand");
        break;
      default:
        level.waypoints[nearestWaypoint].type = "stand";
        iprintln("^2Waypoint " + nearestWaypoint + " Type: ^7Stand (default)");
        break;
    }
  }
  else
  {
    iprintln("^1No waypoint nearby to change type");
  }
}

////////////////////////////////////////////////////////////
// Adds a waypoint to the static waypoint list
////////////////////////////////////////////////////////////
AddWaypoint(pos)
{
  for(i = 0; i < level.waypointCount; i++)
  {
    distance = distance(level.waypoints[i].origin, pos);
    
    if(distance <= 30.0 && isDefined(level.waypointcount) && level.waypointcount != 0)
    {
      return;
    }
  }

  level.waypoints[level.waypointCount] = spawnstruct();
  level.waypoints[level.waypointCount].origin = pos;
  level.waypoints[level.waypointCount].type = level.currentWaypointType;
  level.waypoints[level.waypointCount].children = [];
  level.waypoints[level.waypointCount].childCount = 0;
  level.waypointCount++;

  iprintln("^3Waypoint Added ^7(Type: " + level.currentWaypointType + ")");
  
}

////////////////////////////////////////////////////////////
//Links one waypoint to another
////////////////////////////////////////////////////////////
LinkWaypoint(pos)
{
  //dont spam linkage
  if((gettime()-level.linkSpamTimer) < 800)
  {
    return;
  }
  level.linkSpamTimer = gettime();
  
  wpToLink = -1;
  
  for(i = 0; i < level.waypointCount; i++)
  {
    distance = distance(level.waypoints[i].origin, pos);
    
    if(distance <= 30.0)
    {
      wpToLink = i;
      break;
    }
  }
  
  //if the nearest waypoint is valid
  if(wpToLink != -1)
  {
    //if we have already pressed link on another waypoint, then link them up
    if(level.wpToLink != -1 && level.wpToLink != wpToLink)
    {
      level.waypoints[level.wpToLink].children[level.waypoints[level.wpToLink].childcount] = wpToLink;
      level.waypoints[level.wpToLink].childcount++;
      
      level.waypoints[wpToLink].children[level.waypoints[wpToLink].childcount] = level.wpToLink;
      level.waypoints[wpToLink].childcount++;
      
      iprintln("Waypoint " + wpToLink + " Linked to " + level.wpToLink);
      level.wpToLink = -1;
    }
    else //otherwise store the first link point
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

////////////////////////////////////////////////////////////
//Cycles through waypoint types (stand, crouch, jump, prone)
////////////////////////////////////////////////////////////
CycleWaypointType(pos)
{
  //dont spam type changes
  if((gettime()-level.typeSpamTimer) < 500)
  {
    return;
  }
  level.typeSpamTimer = gettime();
  
  wpToChange = -1;
  
  for(i = 0; i < level.waypointCount; i++)
  {
    distance = distance(level.waypoints[i].origin, pos);
    
    if(distance <= 30.0)
    {
      wpToChange = i;
      break;
    }
  }
  
  //if the nearest waypoint is valid
  if(wpToChange != -1)
  {
    currentType = level.waypoints[wpToChange].type;
    
    // Cycle through types: stand -> crouch -> jump -> prone -> stand
    switch(currentType)
    {
      case "stand":
        level.waypoints[wpToChange].type = "crouch";
        iprintln("Waypoint " + wpToChange + " type changed to: crouch");
        break;
      case "crouch":
        level.waypoints[wpToChange].type = "jump";
        iprintln("Waypoint " + wpToChange + " type changed to: jump");
        break;
      case "jump":
        level.waypoints[wpToChange].type = "prone";
        iprintln("Waypoint " + wpToChange + " type changed to: prone");
        break;
      case "prone":
        level.waypoints[wpToChange].type = "stand";
        iprintln("Waypoint " + wpToChange + " type changed to: stand");
        break;
      default:
        level.waypoints[wpToChange].type = "stand";
        iprintln("Waypoint " + wpToChange + " type set to: stand");
        break;
    }
  }
  else
  {
    iprintln("No waypoint found to change type");
  }
}


DrawStaticWaypoints()
{
  while(1)
  {
    if(isDefined(level.waypoints) && isDefined(level.waypointCount) && level.waypointCount > 0)
    {
      for(i = 0; i < level.waypointCount; i++)
      {
        // Base color based on waypoint type
        switch(level.waypoints[i].type)
        {
          case "stand":
            color = (0,0,1); // Blue for stand
            break;
          case "crouch":
            color = (1,1,0); // Yellow for crouch
            break;
          case "jump":
            color = (0,1,1); // Cyan for jump
            break;
          case "prone":
            color = (1,0.5,0); // Orange for prone
            break;
          default:
            color = (0,0,1); // Default blue
            break;
        }

        // Override color based on connection status
        if(level.waypoints[i].childCount == 0)
        {
          color = (1,0,0); // Red for unlinked
        }
        else if(level.waypoints[i].childCount == 1)
        {
          color = (1,0,1); // Purple for dead ends
        }
        else
        {
          // Keep type-based color for well-connected waypoints
        }

        if(isdefined(level.players) && isdefined(level.players[0]))
        {
          distance = distance(level.waypoints[i].origin, level.players[0].origin);
          if(distance <= 30.0)
          {
            strobe = gettime()/10.0;
            color = (color[0]*strobe,color[1]*strobe,color[2]*strobe);
          }
        }

        line(level.waypoints[i].origin, level.waypoints[i].origin + (0,0,200), color);
        
        for(x = 0; x < level.waypoints[i].childCount; x++)
        {
          line(level.waypoints[i].origin + (0,0,5), level.waypoints[level.waypoints[i].children[x]].origin + (0,0,5), (0,0,1));
        }
      }
    }
    wait 0.01;
  }
}
save()
{
for(i = 0; i < level.waypointCount; i++)
  {
    string = i + "," + level.waypoints[i].origin[0] + " " + level.waypoints[i].origin[1] + " " + level.waypoints[i].origin[2] + ",";
    for(c = 0; c < level.waypoints[i].childCount; c++)
    {
      string = string + level.waypoints[i].children[c];
      if(c < level.waypoints[i].childCount-1)
      {
        string = string + " ";
      }
	wait 0.01;
    }
    
    string = string + "," + level.waypoints[i].type;

 }

}
DeleteWaypoint(pos)
{
  for(i = 0; i < level.waypointCount; i++)
  {
    distance = distance(level.waypoints[i].origin, pos);
    
    if(distance <= 30.0)
    {

      //remove all links in children
      //for each child c
      for(c = 0; c < level.waypoints[i].childCount; c++)
      {
        //remove links to its parent i
        for(c2 = 0; c2 < level.waypoints[level.waypoints[i].children[c]].childCount; c2++)
        {
          // child of i has a link to i as one of its children, so remove it
          if(level.waypoints[level.waypoints[i].children[c]].children[c2] == i)
          {
            //remove entry by shuffling list over top of entry
            for(c3 = c2; c3 < level.waypoints[level.waypoints[i].children[c]].childCount-1; c3++)
            {
              level.waypoints[level.waypoints[i].children[c]].children[c3] = level.waypoints[level.waypoints[i].children[c]].children[c3+1];
            }
            //removed child
            level.waypoints[level.waypoints[i].children[c]].childCount--;
            break;
          }
        }
      }
      
      //remove waypoint from list
      for(x = i; x < level.waypointCount-1; x++)
      {
        level.waypoints[x] = level.waypoints[x+1];
      }
      level.waypointCount--;
      
      //reassign all child links to their correct values
      for(r = 0; r < level.waypointCount; r++)
      {
        for(c = 0; c < level.waypoints[r].childCount; c++)
        {
          if(level.waypoints[r].children[c] > i)
          {
            level.waypoints[r].children[c]--;
          }
        }
      
      }

      iprintln("Waypoint Deleted");
      
      return;
    }

  }
}
SaveStaticWaypoints()
{
	if((gettime()-level.saveSpamTimer) < 1500)
	{
		return;
	}
	level.saveSpamTimer = gettime();
	iprintln("saving waypoints ...");
	setcvar("logfile", "1");

	
	scriptstart = [];
	scriptstart[0] = "load_waypoints()";
	scriptstart[1] = "{";
	scriptstart[2] = "    level.waypoints = [];";
	scriptstart[3] = " ";
	
	for(i = 0; i < scriptstart.size; i++)
	{
		logPrint(scriptstart[i] + "\n");
	}

	for(w = 0; w < level.waypointCount; w++)
	{
		waypointstruct = "    level.waypoints[" + w + "] = spawnstruct();";
		logPrint(waypointstruct + "\n");
	
		waypointstring = "    level.waypoints[" + w + "].origin = "+ "(" + level.waypoints[w].origin[0] + "," + level.waypoints[w].origin[1] + "," + level.waypoints[w].origin[2] + ");";
		logPrint(waypointstring + "\n");
		
		waypointchild = "    level.waypoints[" + w + "].childCount = " + level.waypoints[w].childCount + ";";
		logPrint(waypointchild + "\n");

		for(c = 0; c < level.waypoints[w].childCount; c++)
		{
			childstring = "    level.waypoints[" + w + "].children[" + c + "] = " + level.waypoints[w].children[c] + ";";
			logPrint(childstring + "\n");      
		}
		
		// Add waypoint type to saved output
		waypointtype = "    level.waypoints[" + w + "].type = \"" + level.waypoints[w].type + "\";";
		logPrint(waypointtype + "\n");
		
		iprintln("Waypoint " + (w + 1)+ " Saved.");		
	}
	
	scriptend = [];
	scriptend[0] = " ";
	scriptend[1] = "    level.waypointCount = level.waypoints.size;";
	scriptend[2] = "}\n";
	
	for(i = 0; i < scriptend.size; i++)
	{
		logPrint(scriptend[i] + "\n");
	}

	setcvar("logfile", 0);
  
	wait 1;
	iprintlnBold("^5Waypoints Outputted To Console Log In Mod Folder");
	wait 1;
	iprintlnBold("^5Close Game & Follow Instructions In File");
}