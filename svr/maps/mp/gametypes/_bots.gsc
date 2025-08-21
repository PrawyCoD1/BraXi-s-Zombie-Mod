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

// =========================
// Zombie Bot Logic
// =========================

zombie_bot_logic()
{
    // Check if zombie is stuck
    currentDist = distancesquared(self.origin, self.lastPosition);
    if (currentDist < 10) // Barely moved
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
	pQOpen = [];
	pQSize = 0;
	closedList = [];
	listSize = 0;
	s = spawnstruct();
	s.g = 0; //start node
	s.h = distancesquared(level.waypoints[startWp].origin, level.waypoints[goalWp].origin);
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
			newg = n.g + distancesquared(level.waypoints[n.wpIdx].origin, level.waypoints[level.waypoints[n.wpIdx].children[i]].origin);
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
			nc.h = distancesquared(level.waypoints[level.waypoints[n.wpIdx].children[i]].origin, level.waypoints[goalWp].origin);
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

// Simple zombie movement to hunter using A* pathfinding with caching
zombie_move_to_hunter(hunter)
{
    if(!isDefined(hunter) || !isAlive(hunter))
        return;
    
    // Cache waypoint results to prevent excessive calls
    currentTime = getTime();
    if(!isDefined(self.lastWaypointCheck) || currentTime - self.lastWaypointCheck > 1000) // Check every 1 second
    {
        self.currentWaypoint = self GetNearestStaticWaypoint(self.origin);
        self.targetWaypoint = self GetNearestStaticWaypoint(hunter.origin);
        self.lastWaypointCheck = currentTime;
    }
    
    if(self.currentWaypoint == -1 || self.targetWaypoint == -1)
    {
        // Fallback to direct movement
        self move_directly_to_hunter(hunter);
        return;
    }
    
    // Use A* pathfinding to get next waypoint
    nextWp = self getway(self.currentWaypoint, self.targetWaypoint);
    
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
            dist = distancesquared(self.origin, level.waypoints[i].origin);
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
            dist = distancesquared(targetPos, level.waypoints[i].origin);
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
        dist = distancesquared(self.origin, nearestZombie.origin);
        
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
                  campDist = distancesquared(self.origin, level.waypoints[self.campWaypoint].origin);
                  if (campDist < 100) // Already close to camp spot
                  {
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
             if (campDist < 100) // Close to camp spot
             {
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
    
    if(self.currentWaypoint == -1)
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
            dist = distancesquared(self.origin, player.origin);
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
            dist = distancesquared(self.origin, player.origin);
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
			
		distance = distancesquared(pos, level.waypoints[i].origin);
		if(distance < nearestDistance)
		{
			nearestDistance = distance;
			nearestWaypoint = i;
		}
	}
	return nearestWaypoint;
}