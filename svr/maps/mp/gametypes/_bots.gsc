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
    self.inCombat = false;
    self.stuckRecoveryMode = false;
    
    // Initialize zombie-specific variables
    self.meleeRange = 35; // Reduced for closer melee combat
    self.meleeTime = 500;
    self.meleeSpeed = 1.0;
    self.isDoingMelee = false;
    self.zombiewait = false;
    
    // Reset waypoint system
    self.myWaypoint = -2;
    self.nextWp = undefined;
    self.cur_speed = 200;
    
    // Stop any current movement
    self setWalkDir("none");
    
    // Initialize camp waypoint for hunters immediately
    if (self.pers["team"] == "allies")
    {
        self.campWaypoint = self find_random_camp_waypoint();
    }
    
    self thread bot_think_loop();
    self thread bot_cleanup_watcher();
}

// Main bot thinking loop
bot_think_loop()
{
    while (isDefined(self) && isDefined(self.isbot) && self.sessionstate == "playing")
    {
        if (self.pers["team"] == "axis") // Zombie bot behavior
        {
            self meleeWeapon(false);
            self zombie_bot_logic();
        }
        else if (self.pers["team"] == "allies") // Hunter bot behavior
        {
            self hunter_bot_logic();
        }
        self setWalkDir("none");
        
        wait 0.05; // Prevent excessive CPU usage
    }
}

// Separate thread to handle bot cleanup on disconnect/death
bot_cleanup_watcher()
{
    self endon("disconnect");
    self endon("death");
    
    // Wait for disconnect or death
    self waittill("disconnect");
    
    // Cleanup when bot disconnects or dies
    self bot_cleanup();
}

// Bot cleanup function
bot_cleanup()
{
    // Stop all movement
    self setWalkDir("none");
    
    // Reset all movement and targeting variables
    self.zombiewait = false;
    self.isDoingMelee = false;
    self.stuckRecoveryMode = false;
    
    // Reset waypoint system
    self.myWaypoint = -2;
    self.nextWp = undefined;
    self.currentWaypoint = undefined;
}

// =========================
// Zombie Bot Logic
// =========================

zombie_bot_logic()
{
    // Ensure bot is properly initialized
    if (!isDefined(self.meleeRange))
    {
        self.meleeRange = 35; // Reduced from 80 to 35 for closer melee combat
        self.meleeTime = 500;
        self.meleeSpeed = 1.0;
        self.isDoingMelee = false;
        self.zombiewait = false;
        self.myWaypoint = -2;
        self.cur_speed = 200;
        
        // Force immediate waypoint initialization
        if (isDefined(level.waypoints) && level.waypoints.size > 0)
        {
            self.myWaypoint = self GetNearestStaticWaypoint(self.origin);
            if (self.myWaypoint == -1)
            {
                // If no valid waypoint found, pick a random one
                self.myWaypoint = randomInt(level.waypoints.size);
            }
        }
    }
    
    // Check if zombie is stuck
    currentDist = distance(self.origin, self.lastPosition);
    if (currentDist < 15) // Increased threshold from 10 to 15 units
    {
        if (getTime() - self.stuckTime > 3000) // Increased stuck time from 1.5 to 3 seconds
        {
            // Enter stuck recovery mode to prevent waypoint direction overrides
            self.stuckRecoveryMode = true;
            
            // Force stop current movement and reset everything
            self setWalkDir("none");
            wait 0.2; // Longer delay to ensure complete stop
            
            // Reset waypoint system completely
            self.myWaypoint = -2;
            self.nextWp = undefined;
            self.zombiewait = false;
            self.currentWaypoint = undefined;
            
            // Pick a completely new random waypoint
            self.currentWaypoint = randomInt(level.waypoints.size);
            self.stuckTime = getTime();
            
            // Force movement in completely random direction (not towards waypoint)
            randomAngle = randomInt(360);
            self setPlayerAngles((0, randomAngle, 0));
            wait 0.1; // Longer delay to ensure direction change
            
            // Force forward movement in random direction
            self setWalkDir("forward");
            
            iPrintlnBold("Bot " + self.name + " was stuck, forcing random direction " + randomAngle);
            
            // Don't continue with normal logic for a moment to let the forced movement work
            return;
        }
    }
    else
    {
        self.lastPosition = self.origin;
        self.stuckTime = getTime();
        
        // Exit stuck recovery mode if we're moving again
        if (self.stuckRecoveryMode)
        {
            self.stuckRecoveryMode = false;
            iPrintlnBold("Bot " + self.name + " unstuck, exiting recovery mode");
        }
    }
    
    // Initialize zombie-specific variables if not set
    if (!isDefined(self.meleeRange))
        self.meleeRange = 35; // Melee attack range - reduced for closer combat
    if (!isDefined(self.meleeTime))
        self.meleeTime = 500; // Time between melee attacks
    if (!isDefined(self.meleeSpeed))
        self.meleeSpeed = 1.0; // Melee attack speed multiplier
    if (!isDefined(self.isDoingMelee))
        self.isDoingMelee = false;
    if (!isDefined(self.zombiewait))
        self.zombiewait = false;
    
    // Find best target using improved logic - zombies will target hunters even without line of sight
    bestTarget = self zomGetBestTarget();

    
    // Push out of other players to prevent clustering
    self thread pushOutOfPlayers();
    
    if (isDefined(bestTarget) && isDefined(self) && isAlive(self) && isAlive(bestTarget))
    {
        // Validate target is still valid
        if (!isDefined(bestTarget.origin))
        {
            self.zombiewait = false;
            return;
        }
        
        if (distancesquared(bestTarget.origin, self.origin) < self.meleeRange && !self.isDoingMelee)
        {
            // Close enough for melee attack
            self.isDoingMelee = true;
            self thread zomMoveLockon(bestTarget, self.meleeTime, self.meleeSpeed);
        }
        else
        {
            // Check if target is too high before starting movement
            heightDiff = bestTarget.origin[2] - self.origin[2];
            if (heightDiff > 80)
            {
                // Target is too high, use script model immediately
                iPrintlnBold("Zombie " + self.name + " target too high, using script model immediately");
                self thread zombieMoveToUnreachable(bestTarget.origin);
            }
            else
            {
                // Move towards target - zombies will navigate around obstacles to reach hunters
                self.zombiewait = true;
                self thread zomMoveTowards(bestTarget.origin);
                
                // Wait while moving towards target with timeout
                timeout = 0;
                while (self.zombiewait && timeout < 100) // 2 second timeout
                {
                    wait 0.05; // Increased wait time from 0.02 to 0.05 to reduce rapid checks
                    timeout++;
                    
                    // Check if target is still valid
                    if (!isDefined(bestTarget) || !isAlive(bestTarget) || !isDefined(bestTarget.origin))
                    {
                        self.zombiewait = false;
                        break;
                    }
                    
                    if (distance(bestTarget.origin, self.origin) < self.meleeRange && !self.isDoingMelee)
                    {
                        self.zombiewait = false; // Exit movement loop to attack
                        self.isDoingMelee = true;
                        self thread zomMoveLockon(bestTarget, self.meleeTime, self.meleeSpeed);
                    }
                }
                
                // Force exit if timeout reached
                if (timeout >= 100)
                {
                    self.zombiewait = false;
                    iPrintlnBold("Zombie " + self.name + " movement timeout, resetting");
                }
            }
        }
    }
    else
    {
        // No hunters found, search randomly but keep checking for new targets
        self zomGoSearch();
        
        // Check for targets again after a short delay
        wait 0.5;
    }
}

// Improved target finding function - zombies will target hunters even without line of sight
zomGetBestTarget()
{
    nearest = undefined;
    minDist = 999999;
    
    // Safety check - only zombies should call this function
    if (self.pers["team"] != "axis")
    {
        return undefined;
    }
    
    players = getEntArray("player", "classname");
    for (i = 0; i < players.size; i++)
    {
        player = players[i];
        if (!isDefined(player) || !isAlive(player) || player == self || !isDefined(player.pers["team"]))
            continue;
            
        // Look for hunters (allies team) - zombies should NEVER target other zombies
        if (player.pers["team"] == "allies" && player.pers["team"] != self.pers["team"])
        {
            dist = distance(self.origin, player.origin);
            if (dist < minDist)
            {
                // No line of sight check - zombies will target hunters regardless of visibility
                minDist = dist;
                nearest = player;
            }
        }
    }
    
    return nearest;
}

// Advanced waypoint-based pathfinding system - zombies will navigate to targets even through walls
zomMoveTowards(target_position)
{
    self endon("player_killed");

    // Initialize waypoint system if not set
    if (!isDefined(self.myWaypoint))
        self.myWaypoint = -2;
    if (!isDefined(self.cur_speed))
        self.cur_speed = 200; // Default movement speed
    
    if (self.myWaypoint == -2)
    {
        self.myWaypoint = self GetNearestStaticWaypoint(self.origin);
        if (isDefined(self.myWaypoint) && self.myWaypoint != -1)
        {
            // Check if waypoint is reachable before moving to it
            if (self isWaypointReachable(level.waypoints[self.myWaypoint].origin))
            {
                self moveToPoint(level.waypoints[self.myWaypoint].origin, self.cur_speed);
            }
            else
            {
                // Waypoint is unreachable, use script model
                self thread zombieMoveToUnreachable(level.waypoints[self.myWaypoint].origin);
            }
        }
    }

    targetWp = self GetNearestStaticWaypoint(target_position);
    
    nextWp = self.nextWp;
    
    direct = false;

    // Check if we can move directly to target (no walls in the way)
    trace = bulletTrace(self.origin + (0,0,50), target_position + (0,0,50), false, self);
    if (isDefined(trace["fraction"]) && trace["fraction"] > 0.8)
    {
        direct = true;
    }
    else if (targetWp == self.myWaypoint)
    {
        direct = true;
    }
    else
    {
        // Validate waypoint indices before calling getway
        if (isDefined(self.myWaypoint) && isDefined(targetWp) && 
            self.myWaypoint >= 0 && targetWp >= 0 &&
            isDefined(level.waypoints) && level.waypoints.size > 0 &&
            self.myWaypoint < level.waypoints.size && targetWp < level.waypoints.size)
        {
            nextWp = self getway(self.myWaypoint, targetWp);
            self.nextWp = nextWp;
        }
        else
        {
            // Invalid waypoints, use script model
            nextWp = undefined;
            self thread zombieMoveToUnreachable(target_position);
        }
    }
    
    if (direct)
    {
        self thread moveToPoint(target_position, self.cur_speed);
    }
    else
    {
        if (isDefined(nextWp))
        {
            // Check if next waypoint is reachable
            if (self isWaypointReachable(level.waypoints[nextWp].origin))
            {
                self moveToPoint(level.waypoints[nextWp].origin, self.cur_speed);
                self.myWaypoint = nextWp;
            }
            else
            {
                // Waypoint is unreachable, use script model
                self thread zombieMoveToUnreachable(level.waypoints[nextWp].origin);
                self.myWaypoint = nextWp;
            }
        }
        else
        {
            // No path found, use script model to move to unreachable hunter
            self thread zombieMoveToUnreachable(target_position);
        }
    }
}

moveToPoint(origin, speed)
{
    // Start continuous movement toward target immediately - try normal movement first
    self setWalkDir("forward");
    
    // Track movement to detect if stuck
    startPos = self.origin;
    stuckTime = getTime();
    lastMoveTime = getTime();
    
    // Keep moving until we're close to the target or interrupted
    while (distance(self.origin, origin) > 30 && isDefined(self) && isAlive(self))
    {
        wait 0.1;
        
        // Check if target is too high while moving
        heightDiff = origin[2] - self.origin[2];
        if (heightDiff > 100) // Only use moveto for very high targets
        {
            if (self.pers["team"] == "axis")
            {
                iPrintlnBold("Zombie " + self.name + " detected very high target while moving, switching to script model");
                self setWalkDir("none");
                self thread zombieMoveToUnreachable(origin);
            }
            else
            {
                iPrintlnBold("Hunter " + self.name + " detected very high target while moving, switching to script model");
                self setWalkDir("none");
                self thread hunterMoveToUnreachable(origin);
            }
            return;
        }
        
        // Check if we're stuck (not moving)
        currentPos = self.origin;
        if (distance(startPos, currentPos) < 8) // Increased threshold from 5 to 8 units
        {
            if (getTime() - stuckTime > 4000) // Increased stuck time to 4 seconds - give more time for normal movement
            {
                // Only use moveto as absolute last resort after being stuck for a long time
                if (distance(self.origin, origin) > 100) // Only if target is far away
                {
                    // Switch to script model movement based on team
                    self setWalkDir("none");
                    if (self.pers["team"] == "axis")
                    {
                        self thread zombieMoveToUnreachable(origin);
                    }
                    else
                    {
                        self thread hunterMoveToUnreachable(origin);
                    }
                    return;
                }
                
                // Force random direction to break out of stuck state
                randomAngle = randomInt(360);
                self setPlayerAngles((0, randomAngle, 0));
                wait 0.5; // Force movement in random direction
                
                // Reset stuck detection
                startPos = self.origin;
                stuckTime = getTime();
                
                if (self.pers["team"] == "axis")
                {
                    iPrintlnBold("Zombie " + self.name + " was stuck, forcing random movement");
                }
                else
                {
                    iPrintlnBold("Hunter " + self.name + " was stuck, forcing random movement");
                }
            }
        }
        else
        {
            // We're moving, reset stuck detection
            startPos = currentPos;
            stuckTime = getTime();
        }
        
        // Update direction while walking (don't stop to rotate) - less frequent updates
        if (getTime() - lastMoveTime > 300) // Update direction every 300ms to reduce rapid changes
        {
            newTargetDirection = vectorToAngles(VectorNormalize(origin - self.origin));
            
            // Only change direction if the difference is significant (prevent rapid left-right movement)
            if (!isDefined(self.lastTargetDirection))
            {
                self.lastTargetDirection = newTargetDirection;
                self SetPlayerAngles(newTargetDirection);
            }
            else
            {
                // Calculate angle difference
                angleDiff = newTargetDirection[1] - self.lastTargetDirection[1];
                if (angleDiff < 0) angleDiff = 0 - angleDiff; // Manual absolute value
                if (angleDiff > 20) // Only change direction if angle difference is more than 20 degrees
                {
                    self.lastTargetDirection = newTargetDirection;
                    self SetPlayerAngles(newTargetDirection);
                }
            }
            
            lastMoveTime = getTime();
        }
    }
    
    // Stop moving when close to target
    self setWalkDir("none");
    
    // Reset wait flags based on team
    if (self.pers["team"] == "axis")
    {
        self.zombiewait = false;
    }
    else
    {
        self.hunterwait = false;
    }
}

// A* pathfinding algorithm
getway(startWp, goalWp)
{
    self endon("player_killed");

    // Validate waypoint indices
    if (!isDefined(level.waypoints) || !isDefined(level.waypoints.size) || level.waypoints.size == 0)
    {
        return undefined;
    }
    
    if (!isDefined(startWp) || startWp < 0 || startWp >= level.waypoints.size)
    {
        return undefined;
    }
    
    if (!isDefined(goalWp) || goalWp < 0 || goalWp >= level.waypoints.size)
    {
        return undefined;
    }
    
    // Validate waypoint objects exist
    if (!isDefined(level.waypoints[startWp]) || !isDefined(level.waypoints[startWp].origin))
    {
        return undefined;
    }
    
    if (!isDefined(level.waypoints[goalWp]) || !isDefined(level.waypoints[goalWp].origin))
    {
        return undefined;
    }

    pQOpen = [];
    pQSize = 0;
    closedList = [];
    listSize = 0;
    s = spawnstruct();
    s.g = 0; //start node
    
    // Store waypoint origins locally to prevent race conditions
    startOrigin = undefined;
    goalOrigin = undefined;
    
    // Safely get waypoint origins
    if (isDefined(level.waypoints) && isDefined(level.waypoints[startWp]) && isDefined(level.waypoints[startWp].origin))
    {
        startOrigin = level.waypoints[startWp].origin;
    }
    
    if (isDefined(level.waypoints) && isDefined(level.waypoints[goalWp]) && isDefined(level.waypoints[goalWp].origin))
    {
        goalOrigin = level.waypoints[goalWp].origin;
    }
    
    // Check if we successfully got both origins
    if (!isDefined(startOrigin) || !isDefined(goalOrigin))
    {
        return undefined;
    }
    
    s.h = distance(startOrigin, goalOrigin);
    s.f = s.g + s.h;
    s.wpIdx = startWp;
    s.parent = spawnstruct();
    s.parent.wpIdx = -1;

    pQOpen[pQSize] = spawnstruct();
    pQOpen[pQSize] = s; //push s on Open
    pQSize++; 

    while (!self PQIsEmpty(pQOpen, pQSize))
    {
        n = pQOpen[0];
        highestPriority = 9999999999;
        bestNode = -1;
        for (i = 0; i < pQSize; i++)
        {
            if (pQOpen[i].f < highestPriority)
            {
                bestNode = i;
                highestPriority = pQOpen[i].f;
            }
        } 
    
        if (bestNode != -1)
        {
            n = pQOpen[bestNode];
            //remove node from queue    
            for (i = bestNode; i < pQSize-1; i++)
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
        if (n.wpIdx == goalWp)
        {
            x = n;
            for (z = 0; z < 1000; z++)
            {
                parent = x.parent;
                if (parent.parent.wpIdx == -1)
                {	
                    return x.wpIdx;
                }
                x = parent;
            }
            return;      
        }

        //for each successor nc of n
        for (i = 0; i < level.waypoints[n.wpIdx].childCount; i++)
        {
            wait 0;
            
            // Validate child waypoint exists
            if (!isDefined(level.waypoints[n.wpIdx].children) || !isDefined(level.waypoints[n.wpIdx].children[i]))
            {
                continue;
            }
            
            childWp = level.waypoints[n.wpIdx].children[i];
            if (!isDefined(level.waypoints[childWp]) || !isDefined(level.waypoints[childWp].origin))
            {
                continue;
            }
            
            // Safely get waypoint origins for distance calculation
            currentOrigin = undefined;
            childOrigin = undefined;
            
            if (isDefined(level.waypoints) && isDefined(level.waypoints[n.wpIdx]) && isDefined(level.waypoints[n.wpIdx].origin))
            {
                currentOrigin = level.waypoints[n.wpIdx].origin;
            }
            
            if (isDefined(level.waypoints) && isDefined(level.waypoints[childWp]) && isDefined(level.waypoints[childWp].origin))
            {
                childOrigin = level.waypoints[childWp].origin;
            }
            
            // Check if we successfully got both origins
            if (!isDefined(currentOrigin) || !isDefined(childOrigin))
            {
                continue;
            }
            
            newg = n.g + distance(currentOrigin, childOrigin);
            //if nc is in Open or Closed, and nc.g <= newg then skip
            if (self PQExists(pQOpen, childWp, pQSize))
            {   
                nc = spawnstruct();
                for (p = 0; p < pQSize; p++)
                {
                    if (pQOpen[p].wpIdx == childWp)
                    {
                        nc = pQOpen[p];
                        break;
                    }
                }   
                if (nc.g <= newg)
                {
                    continue;
                }
            }
            else
            {
                if (self ListExists(closedList, childWp, listSize))
                {
                    nc = spawnstruct();
                    for (p = 0; p < listSize; p++)
                    {
                        if (closedList[p].wpIdx == childWp)
                        {
                            nc = closedList[p];
                            break;
                        }
                    }
                    if (nc.g <= newg)
                    {
                        continue;
                    }
                }
            }

            nc = spawnstruct();
            nc.parent = spawnstruct();
            nc.parent = n;
            nc.g = newg;
            
            // Safely calculate heuristic distance
            goalOrigin = undefined;
            if (isDefined(level.waypoints) && isDefined(level.waypoints[goalWp]) && isDefined(level.waypoints[goalWp].origin))
            {
                goalOrigin = level.waypoints[goalWp].origin;
            }
            
            if (isDefined(goalOrigin) && isDefined(childOrigin))
            {
                nc.h = distance(childOrigin, goalOrigin);
            }
            else
            {
                nc.h = 9999999999; // Use high cost if origins are invalid
            }
            
            nc.f = nc.g + nc.h;
            nc.wpIdx = childWp;

            //if nc is in Closed,
            if (self ListExists(closedList, nc.wpIdx, listSize))
            {
                deleted = false;
                for (p = 0; p < listSize; p++)
                {
                    if (closedList[p].wpIdx == nc.wpIdx)
                    {
                        for (x = p; x < listSize-1; x++)
                        {
                            closedList[x] = closedList[x+1];
                        }
                        deleted = true;
                        break;
                    }
                    if (deleted)
                    {
                        break;
                    }
                }    
                listSize--;
            }
	    
            //if nc is not yet in Open, 
            if (!self PQExists(pQOpen, nc.wpIdx, pQSize))
            {
                pQOpen[pQSize] = spawnstruct();
                pQOpen[pQSize] = nc;  
                pQSize++;
            }
        }

        //Done with children, push n onto Closed
        if (!self ListExists(closedList, n.wpIdx, listSize))
        {
            closedList[listSize] = spawnstruct();
            closedList[listSize] = n;  
            listSize++;
        }
    }
}

// Find nearest waypoint to position with collision detection
GetNearestStaticWaypoint(pos)
{
    self endon("player_killed");

    if (!isDefined(level.waypoints) || !isDefined(level.waypoints.size) || level.waypoints.size == 0)
    {
        return -1;
    }

    nearestWaypoint = -1;
    nearestDistance = 9999999999;
    nearestZ = 9999999999;
    nearestXY = 9999999999;
  
    for (i = 0; i < level.waypoints.size; i++)
    {
        // Validate waypoint object exists
        if (!isDefined(level.waypoints[i]) || !isDefined(level.waypoints[i].origin))
        {
            continue;
        }
        
        distance = Distance(pos, level.waypoints[i].origin);
        distanceX = level.waypoints[i].origin[0] - pos[0];
        distanceY = level.waypoints[i].origin[1] - pos[1];
        distanceZ = level.waypoints[i].origin[2] - pos[2];

        if (distance < nearestDistance)
        {              
            if (nearestZ < distanceZ && (distanceX < 175 || distanceY < 175) && (distanceX < nearestXY || distanceY < nearestXY))
            {
                if (distanceX < distanceY)
                {
                    nearestXY = distanceX;
                }
                else
                {
                    nearestXY = distanceY;
                }
		
                trace = bullettrace(pos + (0,0,50), level.waypoints[i].origin + (0,0,50), false, self);
                if (trace["fraction"] == 1)
                {
                    // Additional check: ensure waypoint is not in a narrow space
                    if (self isWaypointAccessible(level.waypoints[i].origin))
                    {
                        nearestDistance = distance;  
                        nearestZ = distanceZ;    
                        nearestWaypoint = i;
                    }
                }
            }     
            else
            {
                trace = bullettrace(pos + (0,0,50), level.waypoints[i].origin + (0,0,50), false, self);
                if (trace["fraction"] == 1)
                {
                    // Additional check: ensure waypoint is not in a narrow space
                    if (self isWaypointAccessible(level.waypoints[i].origin))
                    {
                        nearestDistance = distance;    
                        nearestWaypoint = i;
                    }
                }
            }       
        }
    }
    return nearestWaypoint;
}

// Check if waypoint is accessible (not in narrow space)
isWaypointAccessible(waypointPos)
{
    // Check if there's enough space around the waypoint
    // Test multiple directions to ensure the waypoint is not in a narrow corridor
    
    testDirections = [];
    testDirections[testDirections.size] = (30, 0, 0);   // Right
    testDirections[testDirections.size] = (-30, 0, 0);  // Left
    testDirections[testDirections.size] = (0, 30, 0);   // Forward
    testDirections[testDirections.size] = (0, -30, 0);  // Back
    
    accessibleDirections = 0;
    
    for (i = 0; i < testDirections.size; i++)
    {
        testPos = waypointPos + testDirections[i];
        trace = bullettrace(waypointPos + (0,0,50), testPos + (0,0,50), false, self);
        
        if (isDefined(trace["fraction"]) && trace["fraction"] > 0.6) // More lenient threshold
        {
            accessibleDirections++;
        }
    }
    
    // Waypoint is accessible if at least 2 directions are clear (more lenient)
    return accessibleDirections >= 2;
}

// Check if waypoint is reachable by zombie (not too high, not blocked)
isWaypointReachable(waypointPos)
{
    // Check height difference - only use moveto for very high waypoints
    heightDiff = waypointPos[2] - self.origin[2];
    if (heightDiff > 120) // Much higher threshold - only use moveto for very high waypoints
    {
        return false;
    }
    
    // Check if there's a clear path to the waypoint - much more lenient
    trace = bullettrace(self.origin + (0,0,50), waypointPos + (0,0,50), false, self);
    if (!isDefined(trace["fraction"]) || trace["fraction"] < 0.1) // Much more lenient threshold
    {
        return false;
    }
    
    // Only check accessibility for very narrow spaces
    if (!self isWaypointAccessible(waypointPos))
    {
        return false;
    }
    
    return true;
}

// Helper functions for A* algorithm
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

// Zombie movement is now handled directly in moveToPoint for continuous movement

// Lock onto target for melee attack
zomMoveLockon(target, meleeTime, meleeSpeed)
{ 
    // Face the target
    dir = target.origin - self.origin;
    if (isDefined(dir))
    {
        targetAngles = vectorToAngles(dir);
        self setPlayerAngles(targetAngles);
    }
        
    currentTime = getTime();
    if (currentTime - self.lastMeleeTime > meleeTime)
    {
        self meleeWeapon(true);
        self.lastMeleeTime = currentTime;
    }
    
    // Reset melee state and allow movement to continue
    self.isDoingMelee = false;
}

// Search for targets when none are visible
zomGoSearch()
{
    // Use waypoint system for searching
    if (!isDefined(self.currentWaypoint) || !isDefined(level.waypoints) || level.waypoints.size == 0)
    {
        self.currentWaypoint = randomInt(level.waypoints.size);
        if (!isDefined(self.currentWaypoint))
            self.currentWaypoint = 0;
    }
    
    // Ensure we have a valid waypoint
    if (isDefined(level.waypoints) && level.waypoints.size > 0 && isDefined(level.waypoints[self.currentWaypoint]))
    {
        self patrol_random_waypoints();
        
        // Force movement if not moving
        if (isDefined(self.currentWaypoint))
        {
            self move_to_waypoint(self.currentWaypoint);
        }
    }
    else
    {
        // Fallback: just move in a random direction
        randomAngle = randomInt(360);
        self setPlayerAngles((0, randomAngle, 0));
        self setWalkDir("forward");
        wait 1.0;
        self setWalkDir("none");
    }
}

// Push out of other players to prevent clustering
pushOutOfPlayers()
{
    players = getEntArray("player", "classname");
    for (i = 0; i < players.size; i++)
    {
        player = players[i];
        if (!isDefined(player) || player == self || !isAlive(player))
            continue;
            
        // Only push away from other zombies, not hunters
        if (player.pers["team"] == "axis" && self.pers["team"] == "axis")
        {
            dist = distance(self.origin, player.origin);
            if (dist < 30) // Too close to another zombie
            {
                // Push away from other zombie
                pushDir = self.origin - player.origin;
                if (isDefined(pushDir))
                {
                    pushAngles = vectorToAngles(pushDir);
                    self setPlayerAngles(pushAngles);
                    self setWalkDir("forward");
                }
            }
        }
    }
}

// =========================
// Hunter Bot Logic
// =========================

hunter_bot_logic()
{
    // Ensure bot is properly initialized
    if (!isDefined(self.hunterRange))
    {
        self.hunterRange = 200; // Range to detect zombies
        self.meleeRange = 60; // Melee attack range
        self.meleeTime = 500; // Time between melee attacks
        self.shootTime = 300; // Time between shots
        self.isDoingMelee = false;
        self.isShooting = false;
        self.hunterwait = false;
        self.myWaypoint = -2;
        self.cur_speed = 250; // Hunters move faster than zombies
        
        // Force immediate waypoint initialization
        if (isDefined(level.waypoints) && level.waypoints.size > 0)
        {
            self.myWaypoint = self GetNearestStaticWaypoint(self.origin);
            if (self.myWaypoint == -1)
            {
                // If no valid waypoint found, pick a random one
                self.myWaypoint = randomInt(level.waypoints.size);
            }
        }
    }
    
    // Find nearest visible zombie
    bestTarget = self hunterGetBestTarget();
    
    if (isDefined(bestTarget))
    {
        currentDist = distance(self.origin, bestTarget.origin);
        
        if (currentDist < self.meleeRange && !self.isDoingMelee)
        {
            // Very close - melee attack
            self.inCombat = true;
            self thread hunterMeleeAttack(bestTarget, self.meleeTime);
        }
        else if (currentDist < self.hunterRange)
        {
            // Close enough to shoot - tactical combat
            self.inCombat = true;
            self thread hunterCombat(bestTarget, self.shootTime);
        }
        else
        {
            // Too far, move towards target using A* pathfinding
            self.inCombat = false;
            self thread hunterMoveTowards(bestTarget.origin, currentDist);
        }
    }
    else
    {
        // No targets found, go to camp spot
        self.inCombat = false;
        self thread hunterGoToCamp();
    }
    
    wait 0.05; // Main loop delay
}
        

// =========================
// Helper Functions
// =========================

// Find nearest visible hunter for zombie
find_nearest_visible_hunter()
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
            
        // Look for hunters (allies team)
        if(player.pers["team"] == "allies")
        {
            dist = distance(self.origin, player.origin);
            if(dist < minDist)
            {
                                 // Check line of sight - more strict to prevent seeing through walls
                 trace = bulletTrace(self.origin + (0,0,50), player.origin + (0,0,50), false, self);
                 if(isDefined(trace["fraction"]) && trace["fraction"] > 0.5) // Hunter is visible (threshold aligned with zombie visibility)
                {
                    minDist = dist;
                    nearest = player;
                }
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
        
    result = randomInt(level.waypoints.size);
    if (!isDefined(result))
        result = 0;
    return result;
}

// Move to specific waypoint
move_to_waypoint(waypointIndex)
{
    if (!isDefined(level.waypoints) || !isDefined(level.waypoints[waypointIndex]))
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
             return;
         }
         else
         {
             self.currentWaypoint = randomInt(level.waypoints.size);
             if (!isDefined(self.currentWaypoint))
                 self.currentWaypoint = 0;
         }
         return;
     }
    
                   // Calculate direction and move
      if (isDefined(dir))
      {
          // Don't override direction if bot is in stuck recovery mode
          if (!self.stuckRecoveryMode)
          {
              targetDirection = vectorToAngles(vectorNormalize(dir));
              self setPlayerAngles((0, targetDirection[1], 0));
              
              // Force a small delay to ensure direction change takes effect
              wait 0.05;
          }
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
         else
         {
             // For zombies, force a completely new random waypoint and direction
             self.currentWaypoint = randomInt(level.waypoints.size);
             if (!isDefined(self.currentWaypoint))
                 self.currentWaypoint = 0;
             
             // Force random direction movement to break out of stuck state
             randomAngle = randomInt(360);
             self setPlayerAngles((0, randomAngle, 0));
             wait 0.1;
             self setWalkDir("forward");
             
             iPrintlnBold("Bot " + self.name + " path blocked, forcing new direction " + randomAngle + " to waypoint " + self.currentWaypoint);
         }
         
         // Reset stuck recovery mode when picking new waypoint
         self.stuckRecoveryMode = false;
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
        
        // Last resort: random waypoint
        if (isDefined(level.waypoints) && level.waypoints.size > 0)
            return randomInt(level.waypoints.size);
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
        
    // Pick random waypoint if we don't have one
    if (!isDefined(self.currentWaypoint))
    {
        self.currentWaypoint = randomInt(level.waypoints.size);
        if (!isDefined(self.currentWaypoint))
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
             else
             {
                 self.currentWaypoint = randomInt(level.waypoints.size);
                 if (!isDefined(self.currentWaypoint))
                     self.currentWaypoint = 0;
             }
         }
     }
     else
     {
         // Both sides blocked, pick new waypoint
         if (self.pers["team"] == "allies")
             self.campWaypoint = self find_random_camp_waypoint();
         else
         {
             self.currentWaypoint = randomInt(level.waypoints.size);
             if (!isDefined(self.currentWaypoint))
                 self.currentWaypoint = 0;
         }
     }
       }

// Zombie movement to unreachable areas using script model
zombieMoveToUnreachable(target_position)
{
    self endon("player_killed");
    
    // Create script model if not exists
    if (!isDefined(self.linkObj))
    {
        self.linkObj = spawn("script_model", self.origin);
    }
    
    // Set script model position and link zombie to it
    self.linkObj.origin = self.origin;
    self linkto(self.linkObj);
    
    // Calculate landing position slightly above target to avoid getting stuck
    landingPosition = target_position + (0, 0, 30); // 30 units above target
    
    // Calculate movement time based on distance
    dist = distance(self.origin, landingPosition);
    moveTime = dist / self.cur_speed;
    if (moveTime < 1.0)
        moveTime = 1.0; // Minimum 1 second
    
    // Move script model to landing position (above target)
    self.linkObj moveto(landingPosition, moveTime);
    
    // Wait for movement to complete
    wait moveTime;
    
    // Unlink zombie from script model
    self unlink();
    
    // Small delay to ensure proper landing
    wait 0.2;
    
    // Update zombie's waypoint system
    self.myWaypoint = self GetNearestStaticWaypoint(self.origin);
    self.zombiewait = false;
    
    iPrintlnBold("Zombie " + self.name + " moved to unreachable hunter using script model (landed above target)");
}

// =========================
// Hunter Functions with A* Pathfinding
// =========================

// Find best target for hunter (nearest visible zombie)
hunterGetBestTarget()
{
    if (!isDefined(level.waypoints))
        return undefined;
    
    players = getEntArray("player", "classname");
    for (i = 0; i < players.size; i++)
    {
        if (!isDefined(players[i]) || !isAlive(players[i]) || players[i] == self || !isDefined(players[i].pers["team"]))
            continue;
            
        // Look for zombies (axis team)
        if (players[i].pers["team"] == "axis")
        {
            dist = distance(self.origin, players[i].origin);
            if (dist < 999999)
            {
                // Check line of sight - hunters need clear line of sight
                trace = bulletTrace(self.origin + (0,0,50), players[i].origin + (0,0,50), false, self);
                if (isDefined(trace["fraction"]) && trace["fraction"] > 0.6) // Hunter can see zombie
                {
                    return players[i];
                }
            }
        }
    }
    
    return undefined;
}

// Advanced waypoint-based pathfinding system - hunters will navigate to targets even through walls
hunterMoveTowards(target_position, currentDist)
{
    self endon("player_killed");

    // Initialize waypoint system if not set
    if (!isDefined(self.myWaypoint))
        self.myWaypoint = -2;
    if (!isDefined(self.cur_speed))
        self.cur_speed = 250; // Hunter movement speed
    
    if (self.myWaypoint == -2)
    {
        self.myWaypoint = self GetNearestStaticWaypoint(self.origin);
        if (isDefined(self.myWaypoint) && self.myWaypoint != -1)
        {
            // Check if waypoint is reachable before moving to it
            if (self isWaypointReachable(level.waypoints[self.myWaypoint].origin))
            {
                self moveToPoint(level.waypoints[self.myWaypoint].origin, self.cur_speed);
            }
            else
            {
                // Waypoint is unreachable, use script model
                self thread hunterMoveToUnreachable(level.waypoints[self.myWaypoint].origin);
            }
        }
    }

    targetWp = self GetNearestStaticWaypoint(target_position);
    
    // Check if we can move directly to target (no walls in the way)
    trace = bulletTrace(self.origin + (0,0,50), target_position + (0,0,50), false, self);
    if (isDefined(trace["fraction"]) && trace["fraction"] > 0.8)
    {
        self thread moveToPoint(target_position, self.cur_speed);
        return;
    }
    
    if (targetWp == self.myWaypoint)
    {
        self thread moveToPoint(target_position, self.cur_speed);
        return;
    }
    
    // Validate waypoint indices before calling getway
    if (isDefined(self.myWaypoint) && isDefined(targetWp) && 
        self.myWaypoint >= 0 && targetWp >= 0 &&
        isDefined(level.waypoints) && level.waypoints.size > 0 &&
        self.myWaypoint < level.waypoints.size && targetWp < level.waypoints.size)
    {
        nextWp = self getway(self.myWaypoint, targetWp);
        self.nextWp = nextWp;
        
        if (isDefined(nextWp))
        {
            // Check if next waypoint is reachable
            if (self isWaypointReachable(level.waypoints[nextWp].origin))
            {
                self moveToPoint(level.waypoints[nextWp].origin, self.cur_speed);
                self.myWaypoint = nextWp;
            }
            else
            {
                // Waypoint is unreachable, use script model
                self thread hunterMoveToUnreachable(level.waypoints[nextWp].origin);
                self.myWaypoint = nextWp;
            }
        }
        else
        {
            // No path found, use script model to move to unreachable zombie
            self thread hunterMoveToUnreachable(target_position);
        }
    }
    else
    {
        // Invalid waypoints, use script model
        self thread hunterMoveToUnreachable(target_position);
    }
}

// Hunter melee attack function
hunterMeleeAttack(target, meleeTime)
{
    self endon("player_killed");
    
    self.isDoingMelee = true;
    
    // Face the target
    dir = target.origin - self.origin;
    if (isDefined(dir))
    {
        targetAngles = vectorToAngles(dir);
        self setPlayerAngles(targetAngles);
    }
    
    // Stop moving and attack
    self setWalkDir("none");
    
    // Perform melee attack
    if (!isDefined(self.lastMeleeTime))
        self.lastMeleeTime = 0;
        
    currentTime = getTime();
    if (currentTime - self.lastMeleeTime > meleeTime)
    {
        self meleeWeapon(true);
        wait 0.1;
        self meleeWeapon(false);
        self.lastMeleeTime = currentTime;
    }
    
    // Reset melee state
    self.isDoingMelee = false;
    
    // Small delay to prevent rapid attack spam
    wait 0.2;
}

// Hunter combat function with tactical movement
hunterCombat(target, shootTime)
{
    self endon("player_killed");
    
    self.isShooting = true;
    
    // Face the target
    dir = target.origin - self.origin;
    if (isDefined(dir))
    {
        self setPlayerAngles(vectorToAngles(dir));
    }
    
    // Tactical movement based on distance
    currentDist = distance(self.origin, target.origin);
    
    if (currentDist < 80) // Very close - retreat backwards
    {
        self setWalkDir("back");
        iPrintlnBold("Hunter " + self.name + " retreating from zombie at distance " + currentDist);
    }
    else if (currentDist < 120) // Medium distance - strafe
    {
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
        
    if (currentTime - self.lastShootTime > shootTime)
    {
        // Keep aiming at target continuously
        self setAim(1);
        
        // Re-aim at target before shooting
        if (isDefined(dir))
        {
            self setPlayerAngles(vectorToAngles(target.origin - self.origin));
        }
        
        wait 0.1; // Delay for better aiming
        
        // Check weapon type and shoot appropriately
        currentWeapon = self getCurrentWeapon();
        if (isDefined(currentWeapon))
        {
            // Check if current weapon is a rifle
            if (currentWeapon == "mosin_nagant_sniper_mp" || currentWeapon == "mosin_nagant_mp" || 
                currentWeapon == "springfield_mp" || currentWeapon == "enfield_mp" || 
                currentWeapon == "kar98k_sniper_mp" || currentWeapon == "kar98k_mp")
            {
                // Proper rifle shooting - press and release fire button
                self fireWeapon(true);
                wait 0.05;
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
            // Fallback to regular shooting
            self fireWeapon(1);
        }
        
        self.lastShootTime = currentTime;
    }
    else
    {
        // Keep aiming even when not shooting
        self setAim(1);
    }
    
    // Reset shooting state
    self.isShooting = false;
}

// Hunter go to camp function using A* pathfinding
hunterGoToCamp()
{
    self endon("player_killed");
    
    // Check if we have a camp spot
    if (!isDefined(self.campWaypoint))
    {
        self.campWaypoint = self find_random_camp_waypoint();
    }
    
    // Check if we're already close to camp spot
    if (isDefined(self.campWaypoint) && isDefined(level.waypoints[self.campWaypoint]))
    {
        if (distance(self.origin, level.waypoints[self.campWaypoint].origin) < 100) // Already close to camp spot
        {
            self setWalkDir("none"); // Stop and camp
            return;
        }
    }
    
    // Move to camp spot using A* pathfinding
    if (isDefined(self.campWaypoint) && isDefined(level.waypoints[self.campWaypoint]))
    {
        // Check if camp is reachable
        if (self isWaypointReachable(level.waypoints[self.campWaypoint].origin))
        {
            self thread hunterMoveTowards(level.waypoints[self.campWaypoint].origin, distance(self.origin, level.waypoints[self.campWaypoint].origin));
        }
        else
        {
            // Camp is unreachable, use script model
            self thread hunterMoveToUnreachable(level.waypoints[self.campWaypoint].origin);
        }
    }
}

// Hunter movement to unreachable areas using script model
hunterMoveToUnreachable(target_position)
{
    self endon("player_killed");
    
    // Create script model if not exists
    if (!isDefined(self.linkObj))
    {
        self.linkObj = spawn("script_model", self.origin);
    }
    
    // Set script model position and link hunter to it
    self.linkObj.origin = self.origin;
    self linkto(self.linkObj);
    
    // Calculate landing position slightly above target
    landingPosition = target_position + (0, 0, 30); // 30 units above target
    
    // Calculate movement time based on distance
    dist = distance(self.origin, landingPosition);
    moveTime = dist / self.cur_speed;
    if (moveTime < 1.0)
        moveTime = 1.0; // Minimum 1 second
    
    // Move script model to landing position
    self.linkObj moveto(landingPosition, moveTime);
    
    // Wait for movement to complete
    wait moveTime;
    
    // Unlink hunter from script model
    self unlink();
    
    // Update hunter's waypoint system
    self.myWaypoint = self GetNearestStaticWaypoint(self.origin);
    self.hunterwait = false;
    
    iPrintlnBold("Hunter " + self.name + " moved to unreachable area using script model");
}