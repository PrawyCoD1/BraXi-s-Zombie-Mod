// =========================
// Bot AI System for Zombie Mod
// =========================

// Initialize bot AI when bot spawns
init_bot_ai()
{
         // Initialize bot variables
     self.currentWaypoint = undefined;
     self.targetWaypoint = undefined;
     self.campWaypoint = undefined;
     self.lastMeleeTime = 0;
     self.lastShootTime = 0;
     self.lastPosition = self.origin;
     self.stuckTime = getTime();
     self.waypointStartTime = getTime();
     self.inCombat = false;
     // Initialize camp waypoint for hunters immediately
     if (self.pers["team"] == "allies")
     {
         self.campWaypoint = self find_random_camp_waypoint();
     }
     
     self thread bot_think_loop();
     self thread bot_unlimited_ammo_loop();
}

// Main bot thinking loop
bot_think_loop()
{
    self notify("bot_think_loop");
    self endon("bot_think_loop");

    // Only run for bots, not human players
    if (!isDefined(self.isbot) || !self.isbot)
    {
        return;
    }
    
    while (isDefined(self) && self.isbot && self.sessionstate == "playing")
    {
        if (self.pers["team"] == "axis") // Zombie bot behavior
        {
            self zombie_bot_logic();
        }
        else if (self.pers["team"] == "allies") // Hunter bot behavior
        {
            self hunter_bot_logic();
        }
        
        wait 0.05; // Prevent excessive CPU usage
    }
}

// Patrol random waypoints
patrol_random_waypoints()
{
    if (!isDefined(level.waypoints) || level.waypoints.size == 0)
    {
        // Fallback: move in random direction
        randomAngle = randomInt(360);
        self setPlayerAngles((0, randomAngle, 0));
        self setWalkDir("forward");
        return;
    }
        
    // Pick random waypoint if we don't have one
    if (!isDefined(self.currentWaypoint))
    {
        self.currentWaypoint = randomInt(level.waypoints.size);
        if (!isDefined(self.currentWaypoint))
            self.currentWaypoint = 0;
        
        // Don't apply stance change on initial spawn - wait until bot actually moves
        self.initialized = true;
        return;
    }
    
    // Pick a random target waypoint if we don't have one or if we've reached the current target
    if(!isDefined(self.patrolTargetWaypoint) || self.patrolTargetWaypoint == -1 || self.currentWaypoint == self.patrolTargetWaypoint)
    {
        self.patrolTargetWaypoint = randomInt(level.waypoints.size);
        while(self.patrolTargetWaypoint == self.currentWaypoint && level.waypoints.size > 1)
        {
            self.patrolTargetWaypoint = randomInt(level.waypoints.size);
        }
        self.patrolStartTime = getTime(); // Reset timer when picking new target
        iPrintlnBold(self.name + " PATROL: new target set to waypoint " + self.patrolTargetWaypoint);
    }
    
    // Check if we've been trying to reach this target for too long (10 seconds)
    if(!isDefined(self.patrolStartTime))
        self.patrolStartTime = getTime();
    
    if(getTime() - self.patrolStartTime > 10000) // 10 seconds timeout
    {
        iPrintlnBold(self.name + " PATROL: timeout reaching target " + self.patrolTargetWaypoint + ", picking new target");
        self.patrolTargetWaypoint = -1; // Force new target selection
        return;
    }
    
    // Use A* pathfinding to get next waypoint
    nextWp = self getway(self.currentWaypoint, self.patrolTargetWaypoint);
    
    if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
    {
        // Move to the next waypoint in the A* path
        waypointPos = level.waypoints[nextWp].origin;
        self move_to_waypoint_position(waypointPos);
        
        // Update current waypoint if we're very close to the target waypoint
        dist = distancesquared(self.origin, waypointPos);
        iPrintlnBold(self.name + " PATROL DEBUG: distance to waypoint " + nextWp + " = " + dist + " (threshold: 2500)");
        if(dist < 2500) // Very close to waypoint (increased threshold)
        {
            self.currentWaypoint = nextWp;
            iPrintlnBold(self.name + " patrol reached waypoint " + nextWp + ", updating current waypoint");
            
            // Apply waypoint type stance when actually at the waypoint (but not during initialization)
            if(!isDefined(self.initialized) || !self.initialized)
            {
                iPrintlnBold(self.name + " DEBUG: Skipping stance change during initialization");
                return;
            }
            
            // Check the type of the waypoint we're actually at (currentWaypoint), not the next waypoint
            iPrintlnBold(self.name + " DEBUG: Checking waypoint type for currentWaypoint=" + self.currentWaypoint + ", waypointCount=" + level.waypointCount);
            
            if(isDefined(self.currentWaypoint) && self.currentWaypoint >= 0 && self.currentWaypoint < level.waypointCount)
            {
                waypointType = level.waypoints[self.currentWaypoint].type;
                iPrintlnBold(self.name + " DEBUG: Current waypoint " + self.currentWaypoint + " has type: " + waypointType);
            }
            else
            {
                waypointType = undefined;
                iPrintlnBold(self.name + " DEBUG: Invalid currentWaypoint: " + self.currentWaypoint);
            }
            
            if(isDefined(waypointType))
            {
                iPrintlnBold(self.name + " at waypoint " + self.currentWaypoint + " using type: " + waypointType);
                
                // Only change stance if it's different from current stance
                currentStance = self getStance();
                targetStance = "";
                
                switch(waypointType)
                {
                    case "jump":
                        targetStance = "jump";
                        iPrintlnBold(self.name + " JUMP WAYPOINT DETECTED at waypoint " + self.currentWaypoint);
                        
                        // For jump waypoints, we need to actually make the bot jump
                        if(!isDefined(self.lastJumpTime))
                            self.lastJumpTime = 0;
                        
                        currentTime = getTime();
                        iPrintlnBold(self.name + " JUMP DEBUG: currentTime=" + currentTime + ", lastJumpTime=" + self.lastJumpTime + ", difference=" + (currentTime - self.lastJumpTime));
                        
                        if(currentTime - self.lastJumpTime > 2000) // Jump every 2 seconds
                        {
                            iPrintlnBold(self.name + " performing jump at waypoint " + nextWp);
                            self setBotStance("jump");
                            self.lastJumpTime = currentTime;
                            iPrintlnBold(self.name + " JUMP EXECUTED, new lastJumpTime=" + self.lastJumpTime);
                        }
                        else
                        {
                            iPrintlnBold(self.name + " JUMP COOLDOWN: waiting " + (2000 - (currentTime - self.lastJumpTime)) + "ms more");
                        }
                        break;
                        
                    case "crouch":
                        targetStance = "crouch";
                        break;
                        
                    case "prone":
                        targetStance = "prone";
                        break;
                        
                    case "stand":
                    default:
                        targetStance = "stand";
                        break;
                }
                
                iPrintlnBold(self.name + " DEBUG: currentStance=" + currentStance + ", targetStance=" + targetStance);
                
                                    // Only change stance if it's different from current stance
                    if(currentStance != targetStance)
                    {
                        iPrintlnBold(self.name + " attempting to change stance from " + currentStance + " to " + targetStance);
                        
                        // Stop movement before changing stance
                        self setWalkDir("none");
                        wait 0.1;
                        
                        // Try to change stance
                        self setBotStance(targetStance);
                        wait 0.2; // Longer delay to ensure stance change takes effect
                        
                        // Check if stance actually changed
                        newStance = self getStance();
                        iPrintlnBold(self.name + " stance after change: " + newStance + " (target was: " + targetStance + ")");
                        
                        if(newStance == targetStance)
                        {
                            iPrintlnBold(self.name + " successfully changed stance to " + targetStance + " at waypoint " + nextWp);
                        }
                        else
                        {
                            iPrintlnBold(self.name + " FAILED to change stance to " + targetStance + " at waypoint " + nextWp);
                            
                            // Try alternative approach - force stance change
                            iPrintlnBold(self.name + " trying alternative stance change method");
                            self setBotStance("stand");
                            wait 0.1;
                            self setBotStance(targetStance);
                            wait 0.2;
                            
                            finalStance = self getStance();
                            iPrintlnBold(self.name + " final stance after alternative method: " + finalStance);
                        }
                    }
                else
                {
                    iPrintlnBold(self.name + " DEBUG: Stance already correct, no change needed");
                }
            }
            else
            {
                iPrintlnBold(self.name + " DEBUG: No waypoint type found for waypoint " + self.currentWaypoint);
            }
        }
    }
    else
    {
        // No path found, try to move to a directly connected waypoint
        iPrintlnBold(self.name + " patrol no path found, trying direct connections");
        if(isDefined(self.currentWaypoint) && isDefined(level.waypoints[self.currentWaypoint]) && level.waypoints[self.currentWaypoint].childCount > 0)
        {
            // Pick first connected waypoint
            nextWp = level.waypoints[self.currentWaypoint].children[0];
            iPrintlnBold(self.name + " patrol using direct connection to waypoint " + nextWp);
            
            waypointPos = level.waypoints[nextWp].origin;
            self move_to_waypoint_position(waypointPos);
            
            // Update current waypoint if we're very close
            dist = distancesquared(self.origin, waypointPos);
            if(dist < 2500)
            {
                self.currentWaypoint = nextWp;
                iPrintlnBold(self.name + " patrol reached waypoint " + nextWp + " via direct connection");
                
                // Apply waypoint type stance when actually at the waypoint (but not during initialization)
                if(!isDefined(self.initialized) || !self.initialized)
                {
                    iPrintlnBold(self.name + " DEBUG: Skipping stance change during initialization (direct)");
                    return;
                }
                
                // Check the type of the waypoint we're actually at (currentWaypoint), not the next waypoint
                if(isDefined(self.currentWaypoint) && self.currentWaypoint >= 0 && self.currentWaypoint < level.waypointCount)
                {
                    waypointType = level.waypoints[self.currentWaypoint].type;
                    iPrintlnBold(self.name + " DEBUG: Current waypoint " + self.currentWaypoint + " has type: " + waypointType + " (direct)");
                }
                else
                {
                    waypointType = undefined;
                    iPrintlnBold(self.name + " DEBUG: Invalid currentWaypoint: " + self.currentWaypoint + " (direct)");
                }
                
                if(isDefined(waypointType))
                {
                    iPrintlnBold(self.name + " at waypoint " + self.currentWaypoint + " using type: " + waypointType + " (direct)");
                    
                    // Only change stance if it's different from current stance
                    currentStance = self getStance();
                    targetStance = "";
                    
                    switch(waypointType)
                    {
                        case "jump":
                            targetStance = "jump";
                            iPrintlnBold(self.name + " JUMP WAYPOINT DETECTED at waypoint " + self.currentWaypoint + " (direct)");
                            
                            // For jump waypoints, we need to actually make the bot jump
                            if(!isDefined(self.lastJumpTime))
                                self.lastJumpTime = 0;
                            
                            currentTime = getTime();
                            iPrintlnBold(self.name + " JUMP DEBUG: currentTime=" + currentTime + ", lastJumpTime=" + self.lastJumpTime + ", difference=" + (currentTime - self.lastJumpTime) + " (direct)");
                            
                            if(currentTime - self.lastJumpTime > 2000) // Jump every 2 seconds
                            {
                                iPrintlnBold(self.name + " performing jump at waypoint " + self.currentWaypoint + " (direct)");
                                self setBotStance("jump");
                                self.lastJumpTime = currentTime;
                                iPrintlnBold(self.name + " JUMP EXECUTED, new lastJumpTime=" + self.lastJumpTime + " (direct)");
                            }
                            else
                            {
                                iPrintlnBold(self.name + " JUMP COOLDOWN: waiting " + (2000 - (currentTime - self.lastJumpTime)) + "ms more (direct)");
                            }
                            break;
                            
                        case "crouch":
                            targetStance = "crouch";
                            break;
                            
                        case "prone":
                            targetStance = "prone";
                            break;
                            
                        case "stand":
                        default:
                            targetStance = "stand";
                            break;
                    }
                    
                    iPrintlnBold(self.name + " DEBUG: currentStance=" + currentStance + ", targetStance=" + targetStance + " (direct)");
                    
                    // Only change stance if it's different from current stance
                    if(currentStance != targetStance)
                    {
                        iPrintlnBold(self.name + " attempting to change stance from " + currentStance + " to " + targetStance + " (direct)");
                        
                        // Stop movement before changing stance
                        self setWalkDir("none");
                        wait 0.1;
                        
                        // Try to change stance
                        self setBotStance(targetStance);
                        wait 0.2; // Longer delay to ensure stance change takes effect
                        
                        // Check if stance actually changed
                        newStance = self getStance();
                        iPrintlnBold(self.name + " stance after change: " + newStance + " (target was: " + targetStance + ")");
                        
                        if(newStance == targetStance)
                        {
                            iPrintlnBold(self.name + " successfully changed stance to " + targetStance + " at waypoint " + nextWp + " (direct)");
                        }
                        else
                        {
                            iPrintlnBold(self.name + " FAILED to change stance to " + targetStance + " at waypoint " + nextWp + " (direct)");
                            
                            // Try alternative approach - force stance change
                            iPrintlnBold(self.name + " trying alternative stance change method (direct)");
                            self setBotStance("stand");
                            wait 0.1;
                            self setBotStance(targetStance);
                            wait 0.2;
                            
                            finalStance = self getStance();
                            iPrintlnBold(self.name + " final stance after alternative method: " + finalStance + " (direct)");
                        }
                    }
                    else
                    {
                        iPrintlnBold(self.name + " DEBUG: Stance already correct, no change needed (direct)");
                    }
                }
                else
                {
                    iPrintlnBold(self.name + " DEBUG: No waypoint type found for waypoint " + nextWp + " (direct)");
                }
            }
        }
        else
        {
            // No connections at all, pick a new random waypoint
            iPrintlnBold(self.name + " patrol no connections found, picking new random waypoint");
            self.currentWaypoint = randomInt(level.waypoints.size);
        }
    }
}

// =========================
// Zombie Bot Logic
// =========================

zombie_bot_logic()
{
    // Check if zombie is stuck
    currentDist = distancesquared(self.origin, self.lastPosition);
    if (currentDist < 1000) // Barely moved
    {
        if (getTime() - self.stuckTime > 1500) // Stuck for 1.5 seconds
        {
            // Force stop current movement and reset everything
            self setWalkDir("none");
            wait 0.2;
            
            // Pick a new nearest waypoint to get unstuck (with caching)
            currentTime = getTime();
            if(!isDefined(self.lastWaypointCheck) || currentTime - self.lastWaypointCheck > 500) // Check every 0.5 seconds when stuck
            {
                self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
                self.lastWaypointCheck = currentTime;
            }
            self.stuckTime = getTime();
            self.waypointStartTime = getTime();
            
            // Move towards the new waypoint
            if(isDefined(self.currentWaypoint) && self.currentWaypoint != -1 && isDefined(level.waypoints[self.currentWaypoint]))
            {
                waypointPos = level.waypoints[self.currentWaypoint].origin;
                targetVector = waypointPos - self.origin;
                if(isDefined(targetVector))
                {
                    targetAngles = vectorToAngles(targetVector);
                    self setPlayerAngles(targetAngles);
                }
                self setWalkDir("forward");
            }
            
            iPrintlnBold("Bot " + self.name + " was stuck, moving to new waypoint " + self.currentWaypoint);
            
            return;
        }
    }
    else
    {
        self.lastPosition = self.origin;
        self.stuckTime = getTime();
    }
    
    // Find nearest hunter (any hunter, not just visible ones)
    nearestHunter = self find_nearest_hunter();
    
    if (isDefined(nearestHunter))
    {
        dist = distancesquared(self.origin, nearestHunter.origin);
        
        if (dist < 3600) // Close enough for melee attack
        {
            // Face the hunter and melee attack
            targetVector = nearestHunter getRealEye() - self getRealEye();
            if (isDefined(targetVector))
            {
                targetAngles = vectorToAngles(targetVector);
                self setPlayerAngles(targetAngles);
            }
            
            // Stop moving and melee attack
            self setWalkDir("none");
            
            // Melee attack
            if (!isDefined(self.lastMeleeTime) || getTime() - self.lastMeleeTime > 1000) // 1 second cooldown
            {
                self.lastMeleeTime = getTime();
                self meleeWeapon(true);
                wait 0.1;
                self meleeWeapon(false);
            }
            return;
        }
        
        // Move directly towards hunter using A* pathfinding
        self zombie_move_to_hunter(nearestHunter);
    }
    else
    {    
        self patrol_random_waypoints();
    }
}

getway(startWp, goalWp)
{
	// Validate input parameters
	if(!isDefined(startWp) || !isDefined(goalWp) || startWp < 0 || goalWp < 0 || startWp >= level.waypointCount || goalWp >= level.waypointCount)
	{
		iPrintlnBold("GETWAY ERROR: Invalid parameters - startWp=" + startWp + ", goalWp=" + goalWp + ", waypointCount=" + level.waypointCount);
		return;
	}
	
	pQOpen = [];
	pQSize = 0;
	closedList = [];
	listSize = 0;
	s = spawnstruct();
	s.g = 0; //start node
	s.h = distancesquared(level.waypoints[startWp].origin, level.waypoints[goalWp].origin) / 1000; // Scale down for A* stability
	s.f = s.g + s.h;
	s.wpIdx = startWp;
	s.parent = spawnstruct();
	s.parent.wpIdx = -1;

	pQOpen[pQSize] = spawnstruct();
	pQOpen[pQSize] = s; //push s on Open
	pQSize++; 

	while(!PQIsEmpty(pQOpen, pQSize))
	{
		n = pQOpen[0];
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
			n = pQOpen[bestNode];
			//remove node from queue    
			for(i = bestNode; i < pQSize-1; i++)
			{
				pQOpen[i] = pQOpen[i+1];
			}
			pQSize--;
		}
		else
		{
			return;
		}  

		//if n is a goal node; construct path, return success
		if(n.wpIdx == goalWp)
		{
			x = n;
			for(z = 0; z < 1000; z++)
			{
				if(!isDefined(x) || !isDefined(x.parent))
					break;
					
				parent = x.parent;
				if(isDefined(parent) && isDefined(parent.parent) && parent.parent.wpIdx == -1)
				{	
					return x.wpIdx;
				}
				x = parent;
			}
			return;      
		}

		//for each successor nc of n
		for(i = 0; i < level.waypoints[n.wpIdx].childCount; i++)
		{
			newg = n.g + distancesquared(level.waypoints[n.wpIdx].origin, level.waypoints[level.waypoints[n.wpIdx].children[i]].origin) / 1000; // Scale down for A* stability
			//if nc is in Open or Closed, and nc.g <= newg then skip
			if(PQExists(pQOpen, level.waypoints[n.wpIdx].children[i], pQSize))
			{   
				nc = spawnstruct();
				for(p = 0; p < pQSize; p++)
				{
					if(pQOpen[p].wpIdx == level.waypoints[n.wpIdx].children[i])
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
			{
				if(ListExists(closedList, level.waypoints[n.wpIdx].children[i], listSize))
				{
					nc = spawnstruct();
					for(p = 0; p < listSize; p++)
					{
						if(closedList[p].wpIdx == level.waypoints[n.wpIdx].children[i])
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
			}

			nc = spawnstruct();
			nc.parent = spawnstruct();
			nc.parent = n;
			nc.g = newg;
			nc.h = distancesquared(level.waypoints[level.waypoints[n.wpIdx].children[i]].origin, level.waypoints[goalWp].origin) / 1000; // Scale down for A* stability
			nc.f = nc.g + nc.h;
			nc.wpIdx = level.waypoints[n.wpIdx].children[i];

			//if nc is in Closed,
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
	    
			//if nc is not yet in Open, 
			if(!PQExists(pQOpen, nc.wpIdx, pQSize))
			{
				pQOpen[pQSize] = spawnstruct();
				pQOpen[pQSize] = nc;  
				pQSize++;
			}
		}

		//Done with children, push n onto Closed
		if(!ListExists(closedList, n.wpIdx, listSize))
		{
			closedList[listSize] = spawnstruct();
			closedList[listSize] = n;  
			listSize++;
		}
	}
	
	iPrintlnBold("GETWAY DEBUG: No path found from " + startWp + " to " + goalWp);
	return -1;

}
PQIsEmpty(Q, QSize)
{
	if(QSize <= 0)
	{
		return true;
	}
	return false;
}
PQExists(Q, n, QSize)
{
	for(i = 0; i < QSize; i++)
	{
		if(Q[i].wpIdx == n)
		{
			return true;
		}
	}
	return false;
}
ListExists(list, n, listSize)
{
	for(i = 0; i < listSize; i++)
	{
		if(list[i].wpIdx == n)
		{
			return true;
		}
	}
	return false;
}

// =========================
// A* Pathfinding System
// =========================

// Zombie movement using A* pathfinding with waypoint following
zombie_move_to_hunter(hunter)
{
    iprintlnBold("zombie_move_to_hunter");
    // Initialize current waypoint if not set
    if(!isDefined(self.currentWaypoint))
    {
        self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
        iPrintlnBold(self.name + " initialized at waypoint " + self.currentWaypoint);
    }
    
    // If no hunter, just patrol between waypoints
    if(!isDefined(hunter) || !isAlive(hunter))
    {
        self zombie_patrol_waypoints();
        iprintlnBold("zombie_patrol_waypoints");
        return;
    }
    
    // Check if we need to find a new target waypoint
    currentTime = getTime();
    if(!isDefined(self.lastWaypointCheck) || currentTime - self.lastWaypointCheck > 2000) // Check every 2 seconds
    {
        self.targetWaypoint = self GetNearestStaticWaypoint(hunter.origin);
        self.lastWaypointCheck = currentTime;
        iPrintlnBold(self.name + " new target waypoint: " + self.targetWaypoint);
    }
    
    // Validate waypoints before calling getway
    if(!isDefined(self.targetWaypoint) || self.targetWaypoint < 0 || self.targetWaypoint >= level.waypointCount)
    {
        iPrintlnBold(self.name + " HUNTER DEBUG: Invalid target waypoint, trying to find new one");
        self.targetWaypoint = self GetNearestStaticWaypoint(hunter.origin);
        if(!isDefined(self.targetWaypoint) || self.targetWaypoint < 0 || self.targetWaypoint >= level.waypointCount)
        {
            iPrintlnBold(self.name + " HUNTER DEBUG: Still invalid target waypoint, moving directly to hunter");
            self move_directly_to_hunter(hunter);
            return;
        }
    }
    
    if(!isDefined(self.currentWaypoint) || self.currentWaypoint < 0 || self.currentWaypoint >= level.waypointCount)
    {
        iPrintlnBold(self.name + " HUNTER DEBUG: Invalid current waypoint, finding nearest");
        self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
        if(!isDefined(self.currentWaypoint) || self.currentWaypoint < 0 || self.currentWaypoint >= level.waypointCount)
        {
            iPrintlnBold(self.name + " HUNTER DEBUG: Still invalid current waypoint, moving directly to hunter");
            self move_directly_to_hunter(hunter);
            return;
        }
    }
    
    // Use A* pathfinding to get next waypoint
    nextWp = self getway(self.currentWaypoint, self.targetWaypoint);
    
    // Check if getway returned a valid result
    if(!isDefined(nextWp) || nextWp == -1)
    {
        iPrintlnBold(self.name + " HUNTER DEBUG: getway returned invalid result, moving directly to hunter");
        self move_directly_to_hunter(hunter);
        return;
    }
    
    // Debug waypoint connections
    if(isDefined(self.currentWaypoint) && isDefined(level.waypoints[self.currentWaypoint]))
    {
        iPrintlnBold(self.name + " DEBUG: Current waypoint " + self.currentWaypoint + " has " + level.waypoints[self.currentWaypoint].childCount + " connections");
        for(i = 0; i < level.waypoints[self.currentWaypoint].childCount; i++)
        {
            iPrintlnBold(self.name + " DEBUG: Connection " + i + " -> waypoint " + level.waypoints[self.currentWaypoint].children[i]);
        }
    }
    
    if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
    {
        // Move to the next waypoint in the A* path
        waypointPos = level.waypoints[nextWp].origin;
        iPrintlnBold(self.name + " moving to waypoint " + nextWp + " at distance: " + distancesquared(self.origin, waypointPos));
        self move_to_waypoint_position(waypointPos);
        
        // Update current waypoint if we're very close to the target waypoint (using horizontal distance only)
        horizontalDist = (self.origin[0] - waypointPos[0]) * (self.origin[0] - waypointPos[0]) + (self.origin[1] - waypointPos[1]) * (self.origin[1] - waypointPos[1]);
        iPrintlnBold(self.name + " HUNTER DEBUG: horizontal distance to waypoint " + nextWp + " = " + horizontalDist + " (threshold: 10000)");
        
        // Debug: Check if we're close enough to trigger waypoint detection
        if(horizontalDist < 10000) // Horizontal distance threshold (100 units squared - more lenient for elevation differences)
        {
            // We're close enough to the target waypoint, so update current waypoint
            self.currentWaypoint = nextWp;
            iPrintlnBold(self.name + " HUNTER: reached waypoint " + nextWp + ", updating current waypoint to " + nextWp);
    
            
            // Check the type of the waypoint we're actually at (currentWaypoint), not the next waypoint
            iPrintlnBold(self.name + " HUNTER DEBUG: Checking waypoint type for currentWaypoint=" + self.currentWaypoint + ", waypointCount=" + level.waypointCount);
            
            if(isDefined(self.currentWaypoint) && self.currentWaypoint >= 0 && self.currentWaypoint < level.waypointCount)
            {
                waypointType = level.waypoints[self.currentWaypoint].type;
                iPrintlnBold(self.name + " HUNTER DEBUG: Current waypoint " + self.currentWaypoint + " has type: " + waypointType);
            }
            else
            {
                waypointType = undefined;
                iPrintlnBold(self.name + " HUNTER DEBUG: Invalid currentWaypoint: " + self.currentWaypoint);
            }
            
            if(isDefined(waypointType))
            {
                iPrintlnBold(self.name + " at waypoint " + self.currentWaypoint + " using type: " + waypointType);
                
                // Only change stance if it's different from current stance
                currentStance = self getStance();
                targetStance = "";
                
                switch(waypointType)
                {
                    case "jump":
                        targetStance = "jump";
                        iPrintlnBold(self.name + " JUMP WAYPOINT DETECTED at waypoint " + self.currentWaypoint);
                        
                        // For jump waypoints, we need to actually make the bot jump
                        if(!isDefined(self.lastJumpTime))
                            self.lastJumpTime = 0;
                        
                        currentTime = getTime();
                        iPrintlnBold(self.name + " JUMP DEBUG: currentTime=" + currentTime + ", lastJumpTime=" + self.lastJumpTime + ", difference=" + (currentTime - self.lastJumpTime));
                        
                        if(currentTime - self.lastJumpTime > 3000) // Jump every 3 seconds (increased cooldown)
                        {
                            iPrintlnBold(self.name + " performing jump at waypoint " + self.currentWaypoint);
                            
                            // First, turn to face the target waypoint before jumping
                            if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
                            {
                                waypointPos = level.waypoints[nextWp].origin;
                                iPrintlnBold(self.name + " HUNTER turning to face waypoint " + nextWp + " before jumping");
                                
                                // Turn to face the target waypoint
                                self SetPlayerAngles(vectortoangles(waypointPos - self.origin));
                                wait 0.2; // Give time for the turn to complete
                                
                                iPrintlnBold(self.name + " HUNTER now facing waypoint " + nextWp + ", executing jump with forward movement");
                            }
                            
                            // Set forward movement and jump simultaneously
                            self setWalkDir("forward");
                            self setBotStance("jump");
                            self.lastJumpTime = currentTime;
                            iPrintlnBold(self.name + " JUMP EXECUTED with forward movement, new lastJumpTime=" + self.lastJumpTime);
                            
                            // Keep moving forward for a short time during the jump
                            wait 0.8;
                            
                            // Continue moving to the next waypoint after jumping
                            if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
                            {
                                waypointPos = level.waypoints[nextWp].origin;
                                iPrintlnBold(self.name + " HUNTER continuing movement to next waypoint " + nextWp + " after jump");
                                self move_to_waypoint_position(waypointPos);
                            }
                        }
                        else
                        {
                            iPrintlnBold(self.name + " JUMP COOLDOWN: waiting " + (3000 - (currentTime - self.lastJumpTime)) + "ms more");
                        }
                        break;
                        
                    case "crouch":
                        targetStance = "crouch";
                        break;
                        
                    case "prone":
                        targetStance = "prone";
                        break;
                        
                    case "stand":
                    default:
                        targetStance = "stand";
                        break;
                }
                
                iPrintlnBold(self.name + " DEBUG: currentStance=" + currentStance + ", targetStance=" + targetStance);
                
                // Only change stance if it's different from current stance
                if(currentStance != targetStance)
                {
                    iPrintlnBold(self.name + " attempting to change stance from " + currentStance + " to " + targetStance);
                    
                    // Stop movement before changing stance
                    self setWalkDir("none");
                    wait 0.1;
                    
                    // Try to change stance
                    self setBotStance(targetStance);
                    wait 0.2; // Longer delay to ensure stance change takes effect
                    
                    // Check if stance actually changed
                    newStance = self getStance();
                    iPrintlnBold(self.name + " stance after change: " + newStance + " (target was: " + targetStance + ")");
                    
                    if(newStance == targetStance)
                    {
                        iPrintlnBold(self.name + " successfully changed stance to " + targetStance + " at waypoint " + self.currentWaypoint);
                    }
                    else
                    {
                        iPrintlnBold(self.name + " FAILED to change stance to " + targetStance + " at waypoint " + self.currentWaypoint);
                        
                        // Try alternative approach - force stance change
                        iPrintlnBold(self.name + " trying alternative stance change method");
                        self setBotStance("stand");
                        wait 0.1;
                        self setBotStance(targetStance);
                        wait 0.2;
                        
                        finalStance = self getStance();
                        iPrintlnBold(self.name + " final stance after alternative method: " + finalStance);
                    }
                }
                else
                {
                    iPrintlnBold(self.name + " DEBUG: Stance already correct, no change needed");
                }
            }
            else
            {
                iPrintlnBold(self.name + " DEBUG: No waypoint type found for waypoint " + nextWp);
            }
        }
    }
    else
    {
        // No path found, move directly towards hunter
        iPrintlnBold(self.name + " no path found, moving directly to hunter");
        iPrintlnBold(self.name + " DEBUG: nextWp=" + nextWp + ", isDefined=" + isDefined(nextWp) + ", waypointExists=" + isDefined(level.waypoints[nextWp]));
        self move_directly_to_hunter(hunter);
    }
}

// Zombie patrol between waypoints when no hunter is present
zombie_patrol_waypoints()
{
    if(!isDefined(self.currentWaypoint) || self.currentWaypoint == -1)
    {
        self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
        iPrintlnBold(self.name + " patrol initialized at waypoint " + self.currentWaypoint);
        return;
    }
    
    // Pick a random target waypoint for patrol
    if(!isDefined(self.patrolTargetWaypoint) || self.patrolTargetWaypoint == -1)
    {
        self.patrolTargetWaypoint = randomInt(level.waypointCount);
        iPrintlnBold(self.name + " patrol target set to waypoint " + self.patrolTargetWaypoint);
    }
    
    // If we're at the patrol target, pick a new one
    if(self.currentWaypoint == self.patrolTargetWaypoint)
    {
        self.patrolTargetWaypoint = randomInt(level.waypointCount);
        iPrintlnBold(self.name + " reached patrol target, new target: " + self.patrolTargetWaypoint);
    }
    
    // Use A* pathfinding to get next waypoint
    nextWp = self getway(self.currentWaypoint, self.patrolTargetWaypoint);
    
    if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
    {
        // Move to the next waypoint in the A* path
        waypointPos = level.waypoints[nextWp].origin;
        self move_to_waypoint_position(waypointPos);
        
        // Update current waypoint if we're very close to the target waypoint
        dist = distancesquared(self.origin, waypointPos);
        if(dist < 900) // Very close to waypoint
        {
            self.currentWaypoint = nextWp;
            iPrintlnBold(self.name + " patrol reached waypoint " + nextWp + ", updating current waypoint");
            
            // Apply waypoint type stance when actually at the waypoint (but not during initialization)
            if(!isDefined(self.initialized) || !self.initialized)
            {
                iPrintlnBold(self.name + " PATROL DEBUG: Skipping stance change during initialization");
                return;
            }
            
            // Check the type of the waypoint we're actually at (currentWaypoint), not the next waypoint
            iPrintlnBold(self.name + " PATROL DEBUG: Checking waypoint type for currentWaypoint=" + self.currentWaypoint + ", waypointCount=" + level.waypointCount);
            
            if(isDefined(self.currentWaypoint) && self.currentWaypoint >= 0 && self.currentWaypoint < level.waypointCount)
            {
                waypointType = level.waypoints[self.currentWaypoint].type;
                iPrintlnBold(self.name + " PATROL DEBUG: Current waypoint " + self.currentWaypoint + " has type: " + waypointType);
            }
            else
            {
                waypointType = undefined;
                iPrintlnBold(self.name + " PATROL DEBUG: Invalid currentWaypoint: " + self.currentWaypoint);
            }
            
            if(isDefined(waypointType))
            {
                iPrintlnBold(self.name + " PATROL at waypoint " + self.currentWaypoint + " using type: " + waypointType);
                
                // Only change stance if it's different from current stance
                currentStance = self getStance();
                targetStance = "";
                
                switch(waypointType)
                {
                    case "jump":
                        targetStance = "jump";
                        iPrintlnBold(self.name + " PATROL JUMP WAYPOINT DETECTED at waypoint " + self.currentWaypoint);
                        
                        // For jump waypoints, we need to actually make the bot jump
                        if(!isDefined(self.lastJumpTime))
                            self.lastJumpTime = 0;
                        
                        currentTime = getTime();
                        iPrintlnBold(self.name + " PATROL JUMP DEBUG: currentTime=" + currentTime + ", lastJumpTime=" + self.lastJumpTime + ", difference=" + (currentTime - self.lastJumpTime));
                        
                        if(currentTime - self.lastJumpTime > 3000) // Jump every 3 seconds (increased cooldown)
                        {
                            iPrintlnBold(self.name + " PATROL performing jump at waypoint " + self.currentWaypoint);
                            
                            // First, turn to face the target waypoint before jumping
                            if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
                            {
                                waypointPos = level.waypoints[nextWp].origin;
                                iPrintlnBold(self.name + " PATROL turning to face waypoint " + nextWp + " before jumping");
                                
                                // Turn to face the target waypoint
                                self SetPlayerAngles(vectortoangles(waypointPos - self.origin));
                                wait 0.2; // Give time for the turn to complete
                                
                                iPrintlnBold(self.name + " PATROL now facing waypoint " + nextWp + ", executing jump with forward movement");
                            }
                            
                            // Set forward movement and jump simultaneously
                            self setWalkDir("forward");
                            self setBotStance("jump");
                            self.lastJumpTime = currentTime;
                            iPrintlnBold(self.name + " PATROL JUMP EXECUTED with forward movement, new lastJumpTime=" + self.lastJumpTime);
                            
                            // Keep moving forward for a short time during the jump
                            wait 0.8;
                            
                            // Continue moving to the next waypoint after jumping
                            if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
                            {
                                waypointPos = level.waypoints[nextWp].origin;
                                iPrintlnBold(self.name + " PATROL continuing movement to next waypoint " + nextWp + " after jump");
                                self move_to_waypoint_position(waypointPos);
                            }
                        }
                        else
                        {
                            iPrintlnBold(self.name + " PATROL JUMP COOLDOWN: waiting " + (3000 - (currentTime - self.lastJumpTime)) + "ms more");
                        }
                        break;
                        
                    case "crouch":
                        targetStance = "crouch";
                        break;
                        
                    case "prone":
                        targetStance = "prone";
                        break;
                        
                    case "stand":
                    default:
                        targetStance = "stand";
                        break;
                }
                
                iPrintlnBold(self.name + " PATROL DEBUG: currentStance=" + currentStance + ", targetStance=" + targetStance);
                
                // Only change stance if it's different from current stance
                if(currentStance != targetStance)
                {
                    iPrintlnBold(self.name + " PATROL attempting to change stance from " + currentStance + " to " + targetStance);
                    
                    // Stop movement before changing stance
                    self setWalkDir("none");
                    wait 0.1;
                    
                    // Try to change stance
                    self setBotStance(targetStance);
                    iPrintlnBold(self.name + " PATROL stance change attempted to " + targetStance);
                }
            }
        }
    }
    else
    {
        // No path found, pick a new patrol target
        iPrintlnBold(self.name + " patrol no path found, picking new target");
        self.patrolTargetWaypoint = randomInt(level.waypointCount);
    }
}

// Get next connected waypoint using simple waypoint connections
get_next_connected_waypoint(currentWp, targetWp)
{
    if(!isDefined(currentWp) || currentWp == -1 || !isDefined(targetWp) || targetWp == -1)
        return -1;
    
    if(!isDefined(level.waypoints) || !isDefined(level.waypoints[currentWp]))
        return -1;
    
    // If current waypoint has no connections, return -1
    if(!isDefined(level.waypoints[currentWp].childCount) || level.waypoints[currentWp].childCount == 0)
    {
        iPrintlnBold("Waypoint " + currentWp + " has no connections");
        return -1;
    }
    
    // Find the connected waypoint closest to the target
    bestWp = -1;
    bestDist = 999999;
    
    for(i = 0; i < level.waypoints[currentWp].childCount; i++)
    {
        childWp = level.waypoints[currentWp].children[i];
        if(isDefined(childWp) && isDefined(level.waypoints[childWp]))
        {
            // Calculate distance from this child waypoint to target
            dist = distancesquared(level.waypoints[childWp].origin, level.waypoints[targetWp].origin);
            if(dist < bestDist)
            {
                bestDist = dist;
                bestWp = childWp;
            }
        }
    }
    
    iPrintlnBold("From waypoint " + currentWp + " to target " + targetWp + ", best connected waypoint: " + bestWp + " (distance: " + bestDist + ")");
    return bestWp;
}

// Get nearest waypoint to current position
get_nearest_waypoint()
{
    if(!isDefined(level.waypoints) || level.waypoints.size == 0)
        return -1;
    
    nearestWp = -1;
    nearestDist = 999999;
    
    for(i = 0; i < level.waypoints.size; i++)
    {
        if(isDefined(level.waypoints[i]))
        {
                         dist = distancesquared(self.origin, level.waypoints[i].origin) / 100; // Scale down for waypoint finding
            if(dist < nearestDist)
            {
                nearestDist = dist;
                nearestWp = i;
            }
        }
    }
    
    return nearestWp;
}

// Get nearest waypoint to target position
get_nearest_waypoint_to_position(targetPos)
{
    if(!isDefined(level.waypoints) || level.waypoints.size == 0)
        return -1;
    
    nearestWp = -1;
    nearestDist = 999999;
    
    for(i = 0; i < level.waypoints.size; i++)
    {
        if(isDefined(level.waypoints[i]))
        {
                         dist = distancesquared(targetPos, level.waypoints[i].origin) / 100; // Scale down for waypoint finding
            if(dist < nearestDist)
            {
                nearestDist = dist;
                nearestWp = i;
            }
        }
    }
    
    return nearestWp;
}

// Move directly to hunter (fallback)
move_directly_to_hunter(hunter)
{
    if(!isDefined(hunter) || !isAlive(hunter))
        return;
    
    // Check if we're at a waypoint and apply stance
    if(isDefined(self.currentWaypoint) && self.currentWaypoint != -1 && isDefined(level.waypoints[self.currentWaypoint]))
    {
        waypointPos = level.waypoints[self.currentWaypoint].origin;
        dist = distancesquared(self.origin, waypointPos);
        
        if(dist < 2500) // Close to waypoint
        {
            waypointType = self get_waypoint_type_at_position(waypointPos);
            
            if(isDefined(waypointType))
            {
                iPrintlnBold(self.name + " DIRECT HUNTER: at waypoint " + self.currentWaypoint + " using type: " + waypointType);
                
                // Only change stance if it's different from current stance
                currentStance = self getStance();
                targetStance = "";
                
                switch(waypointType)
                {
                    case "jump":
                        targetStance = "jump";
                        iPrintlnBold(self.name + " DIRECT HUNTER: JUMP WAYPOINT DETECTED at waypoint " + self.currentWaypoint);
                        
                        // For jump waypoints, we need to actually make the bot jump
                        if(!isDefined(self.lastJumpTime))
                            self.lastJumpTime = 0;
                        
                        currentTime = getTime();
                        iPrintlnBold(self.name + " DIRECT HUNTER: JUMP DEBUG: currentTime=" + currentTime + ", lastJumpTime=" + self.lastJumpTime + ", difference=" + (currentTime - self.lastJumpTime));
                        
                        if(currentTime - self.lastJumpTime > 2000) // Jump every 2 seconds
                        {
                            iPrintlnBold(self.name + " DIRECT HUNTER: performing jump at waypoint " + self.currentWaypoint);
                            self setBotStance("jump");
                            self.lastJumpTime = currentTime;
                            iPrintlnBold(self.name + " DIRECT HUNTER: JUMP EXECUTED, new lastJumpTime=" + self.lastJumpTime);
                        }
                        else
                        {
                            iPrintlnBold(self.name + " DIRECT HUNTER: JUMP COOLDOWN: waiting " + (2000 - (currentTime - self.lastJumpTime)) + "ms more");
                        }
                        break;
                        
                    case "crouch":
                        targetStance = "crouch";
                        break;
                        
                    case "prone":
                        targetStance = "prone";
                        break;
                        
                    case "stand":
                    default:
                        targetStance = "stand";
                        break;
                }
                
                iPrintlnBold(self.name + " DIRECT HUNTER: currentStance=" + currentStance + ", targetStance=" + targetStance);
                
                // Only change stance if it's different from current stance
                if(currentStance != targetStance)
                {
                    iPrintlnBold(self.name + " DIRECT HUNTER: attempting to change stance from " + currentStance + " to " + targetStance);
                    
                    // Stop movement before changing stance
                    self setWalkDir("none");
                    wait 0.1;
                    
                    // Try to change stance
                    self setBotStance(targetStance);
                    wait 0.2; // Longer delay to ensure stance change takes effect
                    
                    // Check if stance actually changed
                    newStance = self getStance();
                    iPrintlnBold(self.name + " DIRECT HUNTER: stance after change: " + newStance + " (target was: " + targetStance + ")");
                    
                    if(newStance == targetStance)
                    {
                        iPrintlnBold(self.name + " DIRECT HUNTER: successfully changed stance to " + targetStance + " at waypoint " + self.currentWaypoint);
                    }
                    else
                    {
                        iPrintlnBold(self.name + " DIRECT HUNTER: FAILED to change stance to " + targetStance + " at waypoint " + self.currentWaypoint);
                        
                        // Try alternative approach - force stance change
                        iPrintlnBold(self.name + " DIRECT HUNTER: trying alternative stance change method");
                        self setBotStance("stand");
                        wait 0.1;
                        self setBotStance(targetStance);
                        wait 0.2;
                        
                        finalStance = self getStance();
                        iPrintlnBold(self.name + " DIRECT HUNTER: final stance after alternative method: " + finalStance);
                    }
                }
                else
                {
                    iPrintlnBold(self.name + " DIRECT HUNTER: Stance already correct, no change needed");
                }
            }
            else
            {
                iPrintlnBold(self.name + " DIRECT HUNTER: No waypoint type found for waypoint " + self.currentWaypoint);
            }
        }
    }
    
    // Face the hunter
    targetVector = hunter.origin - self.origin;
    if(isDefined(targetVector))
    {
        targetAngles = vectorToAngles(targetVector);
        self setPlayerAngles(targetAngles);
    }
    
    // Move forward
    self setWalkDir("forward");
}

// Move to waypoint position
move_to_waypoint_position(waypointPos)
{
    if(!isDefined(waypointPos))
        return;
    
    // Check if we're already close to the waypoint
    dist = distancesquared(self.origin, waypointPos);
    if(dist < 900) // Very close to waypoint, recalculate path
    {
        // Clear current path to force recalculation
        self.currentPathTarget = undefined;
        return;
    }
    
    // Face the waypoint
    targetVector = waypointPos - self.origin;
    if(isDefined(targetVector))
    {
        targetAngles = vectorToAngles(targetVector);
        
        // Only change direction if the difference is significant (prevents rapid direction changes)
        currentAngles = self getPlayerAngles();
        angleDiff = targetAngles[1] - currentAngles[1];
        
        // Calculate absolute value manually
        if(angleDiff < 0)
            angleDiff = 0 - angleDiff;
        
        // Normalize angle difference
        if(angleDiff > 180)
            angleDiff = 360 - angleDiff;
            
        if(angleDiff > 10) // Only change direction if difference is more than 10 degrees
        {
            self setPlayerAngles(targetAngles);
        }
    }
    

    
    // Always move forward regardless of waypoint type
    self setWalkDir("forward");
}

// Zombie waypoint patrol (when no hunters visible) - REMOVED, simplified logic

// =========================
// Hunter Bot Logic
// =========================

hunter_bot_logic()
{
    // Debug: Check if hunter bot logic is running
    if(!isDefined(self.lastHunterDebug) || getTime() - self.lastHunterDebug > 5000) // Every 5 seconds
    {
        iPrintlnBold(self.name + " DEBUG: Hunter bot logic running - campWaypoint=" + self.campWaypoint);
        self.lastHunterDebug = getTime();
    }
    
    // Find nearest visible zombie
    nearestZombie = self find_nearest_visible_zombie();
    
    if (isDefined(nearestZombie))
    {
        dist = distancesquared(self.origin, nearestZombie.origin);
        
        if (dist < 3600) // Very close - melee attack
        {
            // Set combat mode
            self.inCombat = true;
            
            // Face the zombie
            targetVector = nearestZombie getRealEye() - self getRealEye();
            if (isDefined(targetVector))
            {
                targetAngles = vectorToAngles(targetVector);
                self setPlayerAngles(targetAngles);
            }
            
            // Stop moving and melee attack
            self setWalkDir("none");
            
            // Melee attack with cooldown
            currentTime = getTime();
            if (!isDefined(self.lastMeleeTime))
                self.lastMeleeTime = 0;
                
            if (currentTime - self.lastMeleeTime > 500) // Melee every 500ms
            {
                self meleeWeapon(true);
                wait 0.1;
                self meleeWeapon(false);
                self.lastMeleeTime = currentTime;
            }
        }
                 else if (dist < 360000) // Close enough to shoot (600 units squared)
         {
             // Set combat mode
             self.inCombat = true;
             
                                     // Face the zombie more precisely - aim at their actual position
            targetVector = nearestZombie getRealEye() - self getRealEye();
            if (isDefined(targetVector))
            {
                targetAngles = vectorToAngles(targetVector);
                // Set both pitch and yaw for better aiming
                self setPlayerAngles(targetAngles);
                iPrintlnBold("Hunter " + self.name + " aiming at zombie: " + targetAngles + " stance: " + nearestZombie getStance());
            }
             
                           // Tactical movement: move away from zombie while shooting
                             if (dist < 6400) // Very close - retreat backwards (80 units squared)
              {
                  // Move backwards away from zombie
                  self setWalkDir("back");
                  iPrintlnBold("Hunter " + self.name + " retreating from zombie at distance " + dist);
              }
                             else if (dist < 90000) // Medium distance - strafe to avoid being hit (300 units squared)
              {
                  // Strafe left or right randomly to avoid being predictable
                  if (randomInt(2) == 0)
                  {
                      self setWalkDir("left");
                  }
                  else
                  {
                      self setWalkDir("right");
                  }
              }
              else // Far enough - stop to aim better
              {
                  self setWalkDir("none");
              }
            
            // Shoot with cooldown
            currentTime = getTime();
            if (!isDefined(self.lastShootTime))
                self.lastShootTime = 0;
                
            if (currentTime - self.lastShootTime > 300) // Shoot every 300ms
            {
                // Keep aiming at target continuously
                self setAim(1);
                
                // Re-aim at target before shooting to ensure accuracy
                if (isDefined(targetVector))
                {
                                    // Recalculate target vector in case target moved (including stance changes)
                targetVector = nearestZombie getRealEye() - self getRealEye();
                    targetAngles = vectorToAngles(targetVector);
                    self setPlayerAngles(targetAngles);
                }
                
                wait 0.1; // Longer delay for better aiming
                
                // Check if current weapon is a rifle that needs press/release shooting
                currentWeapon = self getCurrentWeapon();
                if (isDefined(currentWeapon))
                {
                    // List of rifles that need press/release shooting
                    rifleWeapons = [];
                    rifleWeapons[rifleWeapons.size] = "mosin_nagant_sniper_mp";
                    rifleWeapons[rifleWeapons.size] = "mosin_nagant_mp";
                    rifleWeapons[rifleWeapons.size] = "springfield_mp";
                    rifleWeapons[rifleWeapons.size] = "enfield_mp";
                    rifleWeapons[rifleWeapons.size] = "kar98k_sniper_mp";
                    rifleWeapons[rifleWeapons.size] = "kar98k_mp";
                    
                    // Check if current weapon is a rifle
                    isRifle = false;
                    for (i = 0; i < rifleWeapons.size; i++)
                    {
                        if (currentWeapon == rifleWeapons[i])
                        {
                            isRifle = true;
                            break;
                        }
                    }
                    
                    if (isRifle)
                    {
                        // Proper rifle shooting - press and release fire button
                        self fireWeapon(true);
                        wait 0.05; // Short delay to simulate trigger pull
                        self fireWeapon(false);
                    }
                    else
                    {
                        // Regular shooting for other weapons
                        self fireWeapon(1);
                    }
                }
                else
                {
                    // Fallback to regular shooting if weapon not detected
                    self fireWeapon(1);
                }
                
                self.lastShootTime = currentTime;
            }
            else
            {
                // Keep aiming even when not shooting
                self setAim(1);
            }
        }
                 else // Too far, move to camp spot
         {
             // Exit combat mode
             self.inCombat = false;
             
             // Check if we have a camp spot
             if (!isDefined(self.campWaypoint))
             {
                 self.campWaypoint = self find_random_camp_waypoint();
             }
             
                           // Check if we're already close to camp spot
              if (isDefined(self.campWaypoint) && isDefined(level.waypoints) && self.campWaypoint >= 0 && self.campWaypoint < level.waypoints.size && isDefined(level.waypoints[self.campWaypoint]))
              {
                  campDist = distancesquared(self.origin, level.waypoints[self.campWaypoint].origin);
                  iPrintlnBold(self.name + " DEBUG: Checking camp spot - campDist=" + campDist + ", campWaypoint=" + self.campWaypoint);
                  if (campDist < 10000) // Already close to camp spot
                  {
                                             // Apply waypoint type before camping
                       if(campDist < 10000) // 100 units squared (increased from 50)
                       {
                           waypointType = self get_waypoint_type_at_position(level.waypoints[self.campWaypoint].origin);
                           if(isDefined(waypointType))
                           {
                              
                              // Only change stance if it's different from current stance
                              currentStance = self getStance();
                              targetStance = "";
                              
                              switch(waypointType)
                              {
                                  case "jump":
                                      targetStance = "jump";
                                      break;
                                      
                                  case "crouch":
                                      targetStance = "crouch";
                                      break;
                                      
                                  case "prone":
                                      targetStance = "prone";
                                      break;
                                      
                                  case "stand":
                                  default:
                                      targetStance = "stand";
                                      break;
                              }
                              
                              // Only change stance if it's different from current stance
                              if(currentStance != targetStance)
                              {
                                  self setBotStance(targetStance);
                                  wait 0.1; // Small delay to ensure stance change takes effect
                              }
                          }
                      }
                      
                      self setWalkDir("none"); // Stop and camp
                      self.waypointStartTime = getTime(); // Reset waypoint timer to prevent timeout
                      return;
                  }
              }
             
             // Move to camp spot using A* pathfinding
             self hunter_move_to_camp();
         }
    }
    else // No zombies visible, stay at camp spot
    {
        // Exit combat mode
        self.inCombat = false;
        
        if (!isDefined(self.campWaypoint))
        {
            self.campWaypoint = self find_random_camp_waypoint();
        }
        
                 // If we're close to camp spot, just stay there
         if (isDefined(self.campWaypoint) && isDefined(level.waypoints) && self.campWaypoint >= 0 && self.campWaypoint < level.waypoints.size && isDefined(level.waypoints[self.campWaypoint]))
         {
             campDist = distancesquared(self.origin, level.waypoints[self.campWaypoint].origin);
             if (campDist < 10000) // Close to camp spot
             {
                 // Apply waypoint type before camping
                 if(campDist < 10000) // 100 units squared (increased from 50)
                 {
                     waypointType = self get_waypoint_type_at_position(level.waypoints[self.campWaypoint].origin);
                     if(isDefined(waypointType))
                     {
                         iPrintlnBold(self.name + " at camp waypoint using type: " + waypointType + " at distance: " + campDist);
                         
                         // Only change stance if it's different from current stance
                         currentStance = self getStance();
                         targetStance = "";
                         
                         switch(waypointType)
                         {
                             case "jump":
                                 targetStance = "jump";
                                 break;
                                 
                             case "crouch":
                                 targetStance = "crouch";
                                 break;
                                 
                             case "prone":
                                 targetStance = "prone";
                                 break;
                                 
                             case "stand":
                             default:
                                 targetStance = "stand";
                                 break;
                         }
                         
                         // Only change stance if it's different from current stance
                         if(currentStance != targetStance)
                         {
                             self setBotStance(targetStance);
                             wait 0.1; // Small delay to ensure stance change takes effect
                         }
                     }
                 }
                 
                 self setWalkDir("none"); // Stop and camp
                 self.waypointStartTime = getTime(); // Reset waypoint timer to prevent timeout
                 return;
             }
         }
        
        // Otherwise move to camp spot using A* pathfinding
        self hunter_move_to_camp();
    }
}

// Hunter movement to camp spot using A* pathfinding with caching
hunter_move_to_camp()
{
    if(!isDefined(self.campWaypoint) || self.campWaypoint == -1)
    {
        // No camp waypoint, just move forward
        self setWalkDir("forward");
        return;
    }
    
    // Cache waypoint results to prevent excessive calls
    currentTime = getTime();
    if(!isDefined(self.lastWaypointCheck) || currentTime - self.lastWaypointCheck > 1000) // Check every 1 second
    {
        self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
        self.lastWaypointCheck = currentTime;
    }
    
    if(!isDefined(self.currentWaypoint) || self.currentWaypoint == -1)
    {
        // Fallback to direct movement to camp
        if(isDefined(level.waypoints[self.campWaypoint]))
        {
            waypointPos = level.waypoints[self.campWaypoint].origin;
            targetVector = waypointPos - self.origin;
            if(isDefined(targetVector))
            {
                targetAngles = vectorToAngles(targetVector);
                self setPlayerAngles(targetAngles);
            }
            self setWalkDir("forward");
        }
        return;
    }
    
    // Use A* pathfinding to get next waypoint
    nextWp = self getway(self.currentWaypoint, self.campWaypoint);
    
    if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
    {
        // Move to the next waypoint in the A* path
        waypointPos = level.waypoints[nextWp].origin;
        self move_to_waypoint_position(waypointPos);
    }
    else
    {
        // No path found, move directly towards camp
        if(isDefined(level.waypoints[self.campWaypoint]))
        {
            waypointPos = level.waypoints[self.campWaypoint].origin;
            targetVector = waypointPos - self.origin;
            if(isDefined(targetVector))
            {
                targetAngles = vectorToAngles(targetVector);
                self setPlayerAngles(targetAngles);
            }
            self setWalkDir("forward");
        }
    }
}

// =========================
// Helper Functions
// =========================

// Get waypoint type at a specific position
get_waypoint_type_at_position(targetPos)
{
    if(!isDefined(targetPos) || !isDefined(level.waypoints) || level.waypointCount == 0)
        return undefined;
    
    // Find the waypoint closest to the target position
    nearestWaypoint = -1;
    nearestDistance = 9999999999;
    
    for(i = 0; i < level.waypointCount; i++)
    {
        if(!isDefined(level.waypoints[i]) || !isDefined(level.waypoints[i].origin))
            continue;
            
        dist = distancesquared(targetPos, level.waypoints[i].origin);
        if(dist < nearestDistance)
        {
            nearestDistance = dist;
            nearestWaypoint = i;
        }
    }
    
    // If we found a waypoint within reasonable distance (within 200 units)
    if(nearestWaypoint != -1 && nearestDistance < 40000) // 200 units squared
    {
        if(isDefined(level.waypoints[nearestWaypoint].type))
        {
            // Debug output (less frequent to avoid spam)
            if(!isDefined(self.lastTypeDebug) || getTime() - self.lastTypeDebug > 3000) // Only show every 3 seconds
            {
                iPrintlnBold("Found waypoint " + nearestWaypoint + " with type: " + level.waypoints[nearestWaypoint].type + " at distance: " + nearestDistance);
                self.lastTypeDebug = getTime();
            }
            return level.waypoints[nearestWaypoint].type;
        }
        else
        {
            // Debug: waypoint found but no type
            if(!isDefined(self.lastTypeDebug) || getTime() - self.lastTypeDebug > 3000)
            {
                iPrintlnBold("Found waypoint " + nearestWaypoint + " but no type defined at distance: " + nearestDistance);
                self.lastTypeDebug = getTime();
            }
        }
    }
    else
    {
        // Debug: no waypoint found within range
        if(!isDefined(self.lastTypeDebug) || getTime() - self.lastTypeDebug > 3000)
        {
            iPrintlnBold("No waypoint found within range. Nearest: " + nearestWaypoint + " at distance: " + nearestDistance);
            self.lastTypeDebug = getTime();
        }
    }
    
    return undefined;
}

// Find nearest hunter for zombie (any hunter, not just visible ones)
find_nearest_hunter()
{
    nearest = undefined;
    minDist = 999999;
    
    players = getEntArray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
        player = players[i];
        if(!isDefined(player) || !isAlive(player) || player == self || !isDefined(player.pers["team"]))
            continue;
            
        // Look for hunters (allies team)
        if(player.pers["team"] == "allies")
        {
            dist = distancesquared(self.origin, player.origin) / 100; // Scale down for player finding
            if(dist < minDist)
            {
                minDist = dist;
                nearest = player;
            }
        }
    }
    
    return nearest;
}

// Find nearest visible zombie for hunter
find_nearest_visible_zombie()
{
    nearest = undefined;
    minDist = 999999;
    
    if (!isDefined(level.waypoints))
    {
        return undefined;
    }
    
    players = getEntArray("player", "classname");
    for(i = 0; i < players.size; i++)
    {
        player = players[i];
        if(!isDefined(player) || !isAlive(player) || player == self || !isDefined(player.pers["team"]))
            continue;
            
        // Look for zombies (axis team)
        if(player.pers["team"] == "axis")
        {
            dist = distancesquared(self.origin, player.origin) / 100; // Scale down for player finding
            if(dist < minDist)
            {
                // Check line of sight - more lenient for hunters, account for crouching
                trace = bulletTrace(self.origin + (0,0,50), player.origin + (0,0,30), false, self);
                if(isDefined(trace["fraction"]) && trace["fraction"] > 0.5) // Zombie is visible (reduced from 0.7)
                {
                    minDist = dist;
                    nearest = player;
                }
            }
        }
    }
    
    return nearest;
}

// Find random waypoint for camping (hunters)
find_random_camp_waypoint()
{
    if (!isDefined(level.waypoints) || level.waypoints.size == 0)
    {
        return 0;
    }
        
    result = randomint(level.waypoints.size);
    if (!isDefined(result) || result == -1)
        result = 0;
    return result;
}

// Move to specific waypoint
move_to_waypoint(waypointIndex)
{
    if (!isDefined(waypointIndex) || !isDefined(level.waypoints) || !isDefined(level.waypoints[waypointIndex]))
    {
        return;
    }
        
    targetOrigin = level.waypoints[waypointIndex].origin;
    dir = targetOrigin - self.origin;
    dist = distancesquared(self.origin, targetOrigin);
    
         if (dist < 2500) // Close to waypoint, pick new one
     {
         if (self.pers["team"] == "allies")
         {
             // Hunters should stay at their camp spot, don't pick new one
             self setWalkDir("none"); // Stop moving and camp
             self.waypointStartTime = getTime(); // Reset timer to prevent timeout
             return;
         }
         else
         {
             self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
             if (!isDefined(self.currentWaypoint))
                 self.currentWaypoint = 0;
         }
         self.waypointStartTime = getTime(); // Reset timer when picking new waypoint
         return;
     }
    
         // Check if we've been trying to reach this waypoint for too long (3 seconds - reduced)
     if (getTime() - self.waypointStartTime > 3000)
     {
         // Force stop current movement to break any stuck loops
         self setWalkDir("none");
         wait 0.2; // Longer delay
         
         if (self.pers["team"] == "allies")
         {
             // Only pick new camp spot if we're really stuck and can't reach current one
             self.campWaypoint = self find_random_camp_waypoint();
             iPrintlnBold("Bot " + self.name + " camp waypoint timeout, picking new camp spot");
             self.waypointStartTime = getTime();
             return;
         }
         // Zombies don't use waypoint timeout - let A* pathfinding handle movement
     }
    
                   // Calculate direction and move
      if (isDefined(dir))
      {
          targetDirection = vectorToAngles(vectorNormalize(dir));
          self setPlayerAngles((0, targetDirection[1], 0));
          
          // Force a small delay to ensure direction change takes effect
          wait 0.05;
      }
      else
      {
          return;
      }
      
                          // If we're very close to the waypoint, just move forward without path checking
               if (dist < 100) // Very close to waypoint (100 units squared / 100)
       {
           if (self.pers["team"] == "allies" && isDefined(self.inCombat) && self.inCombat)
           {
               return; // Don't move to waypoint if in tactical combat
           }
           else
           {
               // Only apply waypoint type when very close to the waypoint (within 50 units)
               if(dist < 2500) // 50 units squared
               {
                   waypointType = self get_waypoint_type_at_position(targetOrigin);
                   if(isDefined(waypointType))
                   {
                        iPrintlnBold(self.name + " at waypoint using type: " + waypointType + " at distance: " + dist);
                       
                       // Only change stance if it's different from current stance
                       currentStance = self getStance();
                       targetStance = "";
                       
                       switch(waypointType)
                       {
                           case "jump":
                               targetStance = "jump";
                               break;
                               
                           case "crouch":
                               targetStance = "crouch";
                               break;
                               
                           case "prone":
                               targetStance = "prone";
                               break;
                               
                           case "stand":
                           default:
                               targetStance = "stand";
                               break;
                       }
                       
                       // Only change stance if it's different from current stance
                       if(currentStance != targetStance)
                       {
                           self setBotStance(targetStance);
                           wait 0.1; // Small delay to ensure stance change takes effect
                       }
                   }
               }
               
               // Always move forward regardless of waypoint type
               self setWalkDir("forward");
               return;
           }
       }
       
              // For hunters at camp spots, be extremely lenient with path checking
       if (self.pers["team"] == "allies" && dist < 225) // Hunter close to camp spot (150 units squared / 100)
       {
           if (self.pers["team"] == "allies" && isDefined(self.inCombat) && self.inCombat)
           {
               return; // Don't move to waypoint if in tactical combat
           }
           else
           {
               // Only apply waypoint type when very close to the waypoint (within 50 units)
               if(dist < 2500) // 50 units squared
               {
                   waypointType = self get_waypoint_type_at_position(targetOrigin);
                   if(isDefined(waypointType))
                   {
                        iPrintlnBold(self.name + " at waypoint using type: " + waypointType + " at distance: " + dist);
                       
                       // Only change stance if it's different from current stance
                       currentStance = self getStance();
                       targetStance = "";
                       
                       switch(waypointType)
                       {
                           case "jump":
                               targetStance = "jump";
                               break;
                               
                           case "crouch":
                               targetStance = "crouch";
                               break;
                               
                           case "prone":
                               targetStance = "prone";
                               break;
                               
                           case "stand":
                           default:
                               targetStance = "stand";
                               break;
                       }
                       
                       // Only change stance if it's different from current stance
                       if(currentStance != targetStance)
                       {
                           self setBotStance(targetStance);
                           wait 0.1; // Small delay to ensure stance change takes effect
                       }
                   }
               }
               
               // Always move forward regardless of waypoint type
               self setWalkDir("forward");
               return;
           }
       }
    
                   // Check if path is clear - much more lenient checking, especially for hunters at camp spots
      eye = self.origin + (0, 0, 60);
      forward = anglesToForward(self getPlayerAngles());
      if (isDefined(forward))
      {
          trace = bulletTrace(eye, eye + (forward[0] * 50, forward[1] * 50, forward[2] * 50), false, self);
      }
      else
      {
          return;
      }
      
             // Much more lenient path checking, especially when close to destination
       pathClear = false;
       if (isDefined(trace["fraction"]))
       {
           if (self.pers["team"] == "allies" && dist < 225) // Hunter close to camp spot (150 units squared / 100)
           {
               // Extremely lenient path checking when close to camp spot - almost always allow movement
               pathClear = trace["fraction"] >= 0.05; // Only 5% clear path needed
           }
           else
           {
               // Normal path checking for other cases
               pathClear = trace["fraction"] >= 0.5;
           }
       }
      
      if (pathClear)
      {
          // Allow movement even in combat mode for tactical positioning
          if (self.pers["team"] == "allies" && isDefined(self.inCombat) && self.inCombat)
          {
              // Hunters in combat can still move to waypoints for tactical positioning
              // But prioritize tactical movement over waypoint movement
              // (tactical movement is set in hunter_bot_logic, so don't override it here)
              return; // Don't move to waypoint if in tactical combat
          }
          else
          {
              // Only apply waypoint type when very close to the waypoint (within 50 units)
              if(dist < 2500) // 50 units squared
              {
                  waypointType = self get_waypoint_type_at_position(targetOrigin);
                  if(isDefined(waypointType))
                  {
                          iPrintlnBold(self.name + " at waypoint using type: " + waypointType + " at distance: " + dist);
                      
                      // Only change stance if it's different from current stance
                      currentStance = self getStance();
                      targetStance = "";
                      
                      switch(waypointType)
                      {
                          case "jump":
                              targetStance = "jump";
                              break;
                              
                          case "crouch":
                              targetStance = "crouch";
                              break;
                              
                          case "prone":
                              targetStance = "prone";
                              break;
                              
                          case "stand":
                          default:
                              targetStance = "stand";
                              break;
                      }
                      
                      // Only change stance if it's different from current stance
                      if(currentStance != targetStance)
                      {
                          self setBotStance(targetStance);
                          wait 0.1; // Small delay to ensure stance change takes effect
                      }
                  }
              }
              
              // Always move forward regardless of waypoint type
              self setWalkDir("forward");
          }
          //iPrintlnBold("Bot " + self.name + " moving to waypoint " + waypointIndex);
      }
         else // Path blocked, try to find alternative
     {
         // Force stop current movement to break any stuck loops
         self setWalkDir("none");
         wait 0.2; // Longer delay
         
         // If path is blocked, pick a new waypoint instead of just strafing
         if (self.pers["team"] == "allies")
         {
             // Only pick new camp spot if path is completely blocked
             self.campWaypoint = self find_random_camp_waypoint();
             iPrintlnBold("Bot " + self.name + " path to camp blocked, picking new camp spot");
         }
         // Zombies don't use path blocking fallback - let A* pathfinding handle movement
     }
}

GetNearestStaticWaypoint(pos)
{
	self endon("player_killed");
	if(!isDefined(level.waypoints) || level.waypointCount == 0)
	{
		return -1;
	}

	nearestWaypoint = -1;
	nearestDistance = 9999999999;
  
	for(i = 0; i < level.waypointCount; i++)
	{
		if(!isDefined(level.waypoints[i]) || !isDefined(level.waypoints[i].origin))
			continue;
			
		dist = distancesquared(pos, level.waypoints[i].origin) / 100; // Scale down for waypoint finding
		if(dist < nearestDistance)
		{
			nearestDistance = dist;
			nearestWaypoint = i;
		}
	}
	return nearestWaypoint;
}

getRealEye()
{
    player = self;

    if (player.pers["team"] == "spectator")
        return player.origin;

    stance = player getStance();

    offset = 0;
    switch (stance)
    {
    case "stand":
        offset = 20;
        break;

    case "crouch":
        offset = 0;
        break;

    case "prone":
        offset = -30;
        break;

    default:
        break;
    }

    return player getEye() + (0, 0, offset);
}

bot_unlimited_ammo_loop()
{
    self endon("disconnect");
    self endon("death");
    
    while (isDefined(self) && self.isbot && self.sessionstate == "playing")
    {
        // Continuously refill ammo for all weapon slots
        self setWeaponSlotAmmo("primary", 999);
        self setWeaponSlotClipAmmo("primary", 999);
        
        wait 0.05; // Check every second
    }
}