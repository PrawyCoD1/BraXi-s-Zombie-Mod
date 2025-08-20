// =========================
// Bot AI System for Zombie Mod
// =========================

// Initialize bot AI when bot spawns
init_bot_ai()
{
         // Initialize bot variables
     self.currentWaypoint = undefined;
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
}

// Main bot thinking loop
bot_think_loop()
{
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
        
        wait 0.1; // Prevent excessive CPU usage
    }
}

// =========================
// Zombie Bot Logic
// =========================

zombie_bot_logic()
{
    // Check if zombie is stuck
    currentDist = distance(self.origin, self.lastPosition);
    if (currentDist < 10) // Barely moved
    {
        if (getTime() - self.stuckTime > 1500) // Stuck for 1.5 seconds
        {
            // Force stop current movement and reset everything
            self setWalkDir("none");
            wait 0.2;
            
            // Pick a new nearest waypoint to get unstuck
            self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
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
        dist = distance(self.origin, nearestHunter.origin);
        
        if (dist < 60) // Close enough for melee attack
        {
            // Face the hunter and melee attack
            targetVector = nearestHunter.origin - self.origin;
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
        // No hunters found, just move forward in current direction
        self setWalkDir("forward");
    }
}

getway(startWp, goalWp)
{
	self endon("player_killed");

	pQOpen = [];
	pQSize = 0;
	closedList = [];
	listSize = 0;
	s = spawnstruct();
	s.g = 0; //start node
	s.h = distance(level.waypoints[startWp].origin, level.waypoints[goalWp].origin);
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
			wait 0;
			newg = n.g + distance(level.waypoints[n.wpIdx].origin, level.waypoints[level.waypoints[n.wpIdx].children[i]].origin);
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
			nc.h = distance(level.waypoints[level.waypoints[n.wpIdx].children[i]].origin, level.waypoints[goalWp].origin);
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

// Simple zombie movement to hunter using A* pathfinding
zombie_move_to_hunter(hunter)
{
    if(!isDefined(hunter) || !isAlive(hunter))
        return;
    
    // Get current waypoint and target waypoint
    currentWp = self GetNearestStaticWaypoint(self.origin);
    targetWp = self GetNearestStaticWaypoint(hunter.origin);
    
    if(currentWp == -1 || targetWp == -1)
    {
        // Fallback to direct movement
        self move_directly_to_hunter(hunter);
        return;
    }
    
    // Use A* pathfinding to get next waypoint
    nextWp = self getway(currentWp, targetWp);
    
    if(isDefined(nextWp) && nextWp != -1 && isDefined(level.waypoints[nextWp]))
    {
        // Move to the next waypoint in the A* path
        waypointPos = level.waypoints[nextWp].origin;
        self move_to_waypoint_position(waypointPos);
    }
    else
    {
        // No path found, move directly towards hunter
        self move_directly_to_hunter(hunter);
    }
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
            dist = distance(self.origin, level.waypoints[i].origin);
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
            dist = distance(targetPos, level.waypoints[i].origin);
            if(dist < nearestDist)
            {
                nearestDist = dist;
                nearestWp = i;
            }
        }
    }
    
    return nearestWp;
}

// A* pathfinding algorithm
a_star_pathfind(startWp, goalWp)
{
    if(startWp == goalWp)
        return [];
    
    openList = [];
    closedList = [];
    
    // Add start node to open list
    startNode = spawnstruct();
    startNode.waypoint = startWp;
    startNode.g = 0;
    startNode.h = distance(level.waypoints[startWp].origin, level.waypoints[goalWp].origin);
    startNode.f = startNode.g + startNode.h;
    startNode.parent = undefined;
    
    openList[openList.size] = startNode;
    
    while(openList.size > 0)
    {
        // Find node with lowest f value
        currentNode = openList[0];
        currentIndex = 0;
        
        for(i = 1; i < openList.size; i++)
        {
            if(openList[i].f < currentNode.f)
            {
                currentNode = openList[i];
                currentIndex = i;
            }
        }
        
        // Remove current node from open list by creating new array
        newOpenList = [];
        for(i = 0; i < openList.size; i++)
        {
            if(i != currentIndex)
            {
                newOpenList[newOpenList.size] = openList[i];
            }
        }
        openList = newOpenList;
        
        // Add to closed list
        closedList[closedList.size] = currentNode;
        
        // Check if we reached the goal
        if(currentNode.waypoint == goalWp)
        {
            // Reconstruct path
            path = [];
            current = currentNode;
            
            while(isDefined(current))
            {
                path[path.size] = current.waypoint;
                current = current.parent;
            }
            
            // Reverse path to get correct order
            reversedPath = [];
            for(i = path.size - 1; i >= 0; i--)
            {
                reversedPath[reversedPath.size] = path[i];
            }
            
            return reversedPath;
        }
        
        // Check neighbors
        if(isDefined(level.waypoints[currentNode.waypoint].connections))
        {
            for(i = 0; i < level.waypoints[currentNode.waypoint].connections.size; i++)
            {
                neighborWp = level.waypoints[currentNode.waypoint].connections[i];
                
                // Skip if in closed list
                inClosed = false;
                for(j = 0; j < closedList.size; j++)
                {
                    if(closedList[j].waypoint == neighborWp)
                    {
                        inClosed = true;
                        break;
                    }
                }
                
                if(inClosed)
                    continue;
                
                // Calculate g value
                g = currentNode.g + distance(level.waypoints[currentNode.waypoint].origin, level.waypoints[neighborWp].origin);
                
                // Check if neighbor is in open list
                inOpen = false;
                openIndex = -1;
                
                for(j = 0; j < openList.size; j++)
                {
                    if(openList[j].waypoint == neighborWp)
                    {
                        inOpen = true;
                        openIndex = j;
                        break;
                    }
                }
                
                if(!inOpen)
                {
                    // Add to open list
                    neighborNode = spawnstruct();
                    neighborNode.waypoint = neighborWp;
                    neighborNode.g = g;
                    neighborNode.h = distance(level.waypoints[neighborWp].origin, level.waypoints[goalWp].origin);
                    neighborNode.f = neighborNode.g + neighborNode.h;
                    neighborNode.parent = currentNode;
                    
                    openList[openList.size] = neighborNode;
                }
                else if(g < openList[openIndex].g)
                {
                    // Update existing node
                    openList[openIndex].g = g;
                    openList[openIndex].f = g + openList[openIndex].h;
                    openList[openIndex].parent = currentNode;
                }
            }
        }
    }
    
    // No path found
    return undefined;
}

// Move directly to hunter (fallback)
move_directly_to_hunter(hunter)
{
    if(!isDefined(hunter) || !isAlive(hunter))
        return;
    
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
    dist = distance(self.origin, waypointPos);
    if(dist < 30) // Very close to waypoint, recalculate path
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
    
    // Move forward
    self setWalkDir("forward");
}

// Zombie waypoint patrol (when no hunters visible) - REMOVED, simplified logic

// =========================
// Hunter Bot Logic
// =========================

hunter_bot_logic()
{
    // Find nearest visible zombie
    nearestZombie = self find_nearest_visible_zombie();
    
    if (isDefined(nearestZombie))
    {
        dist = distance(self.origin, nearestZombie.origin);
        
        if (dist < 60) // Very close - melee attack
        {
            // Set combat mode
            self.inCombat = true;
            
            // Face the zombie
            targetVector = nearestZombie.origin - self.origin;
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
                 else if (dist < 200) // Close enough to shoot (increased range)
         {
             // Set combat mode
             self.inCombat = true;
             
             // Face the zombie more precisely - aim at their actual position
             targetVector = nearestZombie.origin - self.origin;
             if (isDefined(targetVector))
             {
                 targetAngles = vectorToAngles(targetVector);
                 // Set both pitch and yaw for better aiming
                 self setPlayerAngles(targetAngles);
             }
             
                           // Tactical movement: move away from zombie while shooting
              if (dist < 80) // Very close - retreat backwards
              {
                  // Move backwards away from zombie
                  self setWalkDir("back");
                  iPrintlnBold("Hunter " + self.name + " retreating from zombie at distance " + dist);
              }
              else if (dist < 120) // Medium distance - strafe to avoid being hit
              {
                  // Strafe left or right randomly to avoid being predictable
                  if (randomInt(2) == 0)
                  {
                      self setWalkDir("left");
                      iPrintlnBold("Hunter " + self.name + " strafing left from zombie at distance " + dist);
                  }
                  else
                  {
                      self setWalkDir("right");
                      iPrintlnBold("Hunter " + self.name + " strafing right from zombie at distance " + dist);
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
                    // Recalculate target vector in case target moved (including crouching)
                    targetVector = nearestZombie.origin - self.origin;
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
                  campDist = distance(self.origin, level.waypoints[self.campWaypoint].origin);
                  if (campDist < 100) // Already close to camp spot
                  {
                      self setWalkDir("none"); // Stop and camp
                      self.waypointStartTime = getTime(); // Reset waypoint timer to prevent timeout
                      return;
                  }
              }
             
             // Move to camp spot only if not already close
             self move_to_waypoint(self.campWaypoint);
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
             campDist = distance(self.origin, level.waypoints[self.campWaypoint].origin);
             if (campDist < 100) // Close to camp spot
             {
                 self setWalkDir("none"); // Stop and camp
                 self.waypointStartTime = getTime(); // Reset waypoint timer to prevent timeout
                 return;
             }
         }
        
        // Otherwise move to camp spot
        self move_to_waypoint(self.campWaypoint);
    }
}

// =========================
// Helper Functions
// =========================

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
            dist = distance(self.origin, player.origin);
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
            dist = distance(self.origin, player.origin);
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
        
    result = self GetNearestStaticWaypoint(self.origin);
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
    dist = distance(self.origin, targetOrigin);
    
         if (dist < 50) // Close to waypoint, pick new one
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
       if (dist < 100) // Very close to waypoint
       {
           if (self.pers["team"] == "allies" && isDefined(self.inCombat) && self.inCombat)
           {
               return; // Don't move to waypoint if in tactical combat
           }
           else
           {
               self setWalkDir("forward");
               return;
           }
       }
       
       // For hunters at camp spots, be extremely lenient with path checking
       if (self.pers["team"] == "allies" && dist < 150) // Hunter close to camp spot
       {
           if (self.pers["team"] == "allies" && isDefined(self.inCombat) && self.inCombat)
           {
               return; // Don't move to waypoint if in tactical combat
           }
           else
           {
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
           if (self.pers["team"] == "allies" && dist < 150) // Hunter close to camp spot
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

// Move towards target using waypoints (zombies)
move_to_target_using_waypoints(target)
{
    if (!isDefined(target) || !isDefined(level.waypoints) || !isDefined(target.origin))
    {
        return;
    }
        
    // Find best waypoint towards target
    bestWaypoint = self find_best_waypoint_towards_target(target);
    
    if (isDefined(bestWaypoint))
    {
        self move_to_waypoint(bestWaypoint);
    }
    else
    {
        // Fallback: move directly towards target
        targetVector = target.origin - self.origin;
        if (isDefined(targetVector))
        {
            targetAngles = vectorToAngles(targetVector);
            self setPlayerAngles(targetAngles);
            self setWalkDir("forward");
        }
    }
}

// Find best waypoint towards target
find_best_waypoint_towards_target(target)
{
    if (!isDefined(level.waypoints) || level.waypoints.size == 0)
    {
        return undefined;
    }
    
    // Guard against undefined target or missing origin
    if (!isDefined(target) || !isDefined(target.origin))
    {
        return undefined;
    }
        
    bestWaypoint = undefined;
    bestScore = -999999;
    
    // Calculate direction to target
    targetDir = target.origin - self.origin;
    if (!isDefined(targetDir))
    {
        return undefined;
    }
    
    // Calculate distance to target
    targetDist = distance(self.origin, target.origin);
    
    for(i = 0; i < level.waypoints.size; i++)
    {
        if(!isDefined(level.waypoints[i]) || !isDefined(level.waypoints[i].origin))
            continue;
            
        // Calculate direction to waypoint
        wpDir = level.waypoints[i].origin - self.origin;
        if (!isDefined(wpDir))
            continue;
        
        // Calculate distance to waypoint
        wpDist = distance(self.origin, level.waypoints[i].origin);
        
        // Calculate distance from waypoint to target
        wpToTargetDist = distance(level.waypoints[i].origin, target.origin);
        
                 // Check if waypoint is reachable - more lenient
         eye = self.origin + (0, 0, 60);
         trace = bulletTrace(eye, level.waypoints[i].origin + (0,0,60), false, self);
         if (isDefined(trace) && isDefined(trace["fraction"]))
             reachable = trace["fraction"] > 0.3; // Much more lenient
         else
             reachable = true; // Assume reachable if trace fails
         
         // Only skip completely unreachable waypoints
         if (!reachable)
             continue;
        
                 // Calculate alignment with target direction (simplified dot product)
         if (isDefined(targetDir[0]) && isDefined(targetDir[1]) && isDefined(targetDir[2]) && 
             isDefined(wpDir[0]) && isDefined(wpDir[1]) && isDefined(wpDir[2]))
         {
             // Simple dot product without normalization
             alignment = (targetDir[0] * wpDir[0]) + (targetDir[1] * wpDir[1]) + (targetDir[2] * wpDir[2]);
             
             // Normalize by the product of distances to make it more meaningful
             targetDist = distance(self.origin, target.origin);
             wpDist = distance(self.origin, level.waypoints[i].origin);
             
             if (targetDist > 0 && wpDist > 0)
             {
                 alignment = alignment / (targetDist * wpDist);
             }
             else
             {
                 alignment = 0;
             }
         }
         else
         {
             alignment = 0;
         }
        
        // Score calculation:
        // 1. High alignment score (waypoint direction matches target direction)
        // 2. Bonus for waypoints that get us closer to target
        // 3. Penalty for waypoints too far from us
        
        alignmentScore = alignment * 10.0; // Weight alignment heavily
        
        // Bonus for waypoints that get us closer to target
        if (wpToTargetDist < targetDist)
            proximityBonus = 5.0;
        else
            proximityBonus = 0.0;
        
        // Penalty for waypoints too far from us (but not too harsh)
        distancePenalty = wpDist / 1000.0;
        
        // Combined score
        score = alignmentScore + proximityBonus - distancePenalty;
        
        if (!isDefined(score))
            score = 0;
            
        if(isDefined(score) && isDefined(bestScore) && isDefined(i) && score > bestScore)
        {
            bestScore = score;
            bestWaypoint = i;
        }
    }
    
    if (isDefined(bestWaypoint) && isDefined(level.waypoints) && bestWaypoint >= 0 && bestWaypoint < level.waypoints.size)
    {
        return bestWaypoint;
    }
    else
    {
        // If no good waypoint found, try to find any reachable waypoint
        for(i = 0; i < level.waypoints.size; i++)
        {
            if(!isDefined(level.waypoints[i]) || !isDefined(level.waypoints[i].origin))
                continue;
                
                         eye = self.origin + (0, 0, 60);
             trace = bulletTrace(eye, level.waypoints[i].origin + (0,0,60), false, self);
             if (isDefined(trace) && isDefined(trace["fraction"]) && trace["fraction"] > 0.2)
            {
                return i;
            }
        }
        
        // Last resort: nearest waypoint
        if (isDefined(level.waypoints) && level.waypoints.size > 0)
            return self GetNearestStaticWaypoint(self.origin);
        else
            return undefined;
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
        
    // Pick nearest waypoint if we don't have one
    if (!isDefined(self.currentWaypoint))
    {
        self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
        if (!isDefined(self.currentWaypoint) || self.currentWaypoint == -1)
            self.currentWaypoint = 0;
    }
    
    self move_to_waypoint(self.currentWaypoint);
}

 // Find the nearest waypoint to a target (for zombies to find nearest waypoint to hunter)
 find_nearest_waypoint_to_target(target)
 {
     if (!isDefined(level.waypoints) || level.waypoints.size == 0 || !isDefined(target) || !isDefined(target.origin))
     {
         return undefined;
     }
         
     nearestWaypoint = undefined;
     minDist = 999999;
     
     for(i = 0; i < level.waypoints.size; i++)
     {
         if(!isDefined(level.waypoints[i]) || !isDefined(level.waypoints[i].origin))
             continue;
             
         // Calculate distance from waypoint to target
         waypointToTargetDist = distance(level.waypoints[i].origin, target.origin);
         
         // Check if this waypoint is closer to the target
         if(waypointToTargetDist < minDist)
         {
             // Check if we can reach this waypoint from our current position
             eye = self.origin + (0, 0, 60);
             trace = bulletTrace(eye, level.waypoints[i].origin + (0,0,60), false, self);
             if (isDefined(trace) && isDefined(trace["fraction"]) && trace["fraction"] > 0.3)
             {
                 minDist = waypointToTargetDist;
                 nearestWaypoint = i;
             }
         }
     }
     
     return nearestWaypoint;
 }

 // Find alternative path when blocked
 find_alternative_path()
 {
     // Try strafing left or right
     right = anglesToRight(self getPlayerAngles());
     eye = self.origin + (0, 0, 60);
     
     if (!isDefined(right))
     {
         return;
     }
     
     traceLeft = bulletTrace(eye, eye + (right[0] * -40, right[1] * -40, right[2] * -40), false, self);
     traceRight = bulletTrace(eye, eye + (right[0] * 40, right[1] * 40, right[2] * 40), false, self);
     
     if (!isDefined(traceLeft) || !isDefined(traceRight))
     {
         return;
     }
     
     if (isDefined(traceLeft["fraction"]) && isDefined(traceRight["fraction"]))
     {
         if (traceLeft["fraction"] > traceRight["fraction"] && traceLeft["fraction"] > 0.5)
         {
             self setWalkDir("left");
         }
         else if (traceRight["fraction"] > 0.5)
         {
             self setWalkDir("right");
         }
         else
         {
             // Both sides blocked, pick new waypoint
             if (self.pers["team"] == "allies")
                 self.campWaypoint = self find_random_camp_waypoint();
             // Zombies don't use alternative path fallback - let A* pathfinding handle movement
         }
     }
     else
     {
         // Both sides blocked, pick new waypoint
         if (self.pers["team"] == "allies")
             self.campWaypoint = self find_random_camp_waypoint();
         // Zombies don't use alternative path fallback - let A* pathfinding handle movement
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
	nearestZ = 9999999999;
	nearestXY = 9999999999;
  
	for(i = 0; i < level.waypointCount; i++)
	{
		distance = Distance(pos, level.waypoints[i].origin);
		distanceX = level.waypoints[i].origin[0] - Pos[0];
		distanceY = level.waypoints[i].origin[1] - Pos[1];
		distanceZ = level.waypoints[i].origin[2] - Pos[2];

    
		if(distance < nearestDistance)
		{              
			if(nearestZ < distanceZ && (distanceX < 175 || distanceY < 175) && (distanceX < nearestXY || distanceY < nearestXY))
			{
				if(distanceX < distanceY)
				{
					nearestXY = distanceX;
				}
				else
				{
					nearestXY = distanceY;
				}
		
				trace = bullettrace(pos + (0,0,50), level.waypoints[i].origin + (0,0,50), false, self);
				if(trace["fraction"] == 1)
				{
					nearestDistance = distance;  
					nearestZ = distanceZ;    
					nearestWaypoint = i;
				}
			}     
			else
			{
				trace = bullettrace(pos + (0,0,50), level.waypoints[i].origin + (0,0,50), false, self);
				if(trace["fraction"] == 1)
				{
					nearestDistance = distance;    
					nearestWaypoint = i;
				}
			}       
		}
	}
	return nearestWaypoint;
}