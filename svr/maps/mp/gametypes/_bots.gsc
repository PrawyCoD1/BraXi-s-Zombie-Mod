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
    
    self thread bot_think_loop();
}

// Main bot thinking loop
bot_think_loop()
{
    while (isDefined(self) && isDefined(self.isbot) && self.sessionstate == "playing")
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
         if (getTime() - self.stuckTime > 1500) // Stuck for 1.5 seconds (reduced further)
         {
             // Force stop current movement and reset everything
             self setWalkDir("none");
             wait 0.2; // Longer delay to ensure complete stop
             
             // Pick a completely new random waypoint
             self.currentWaypoint = randomInt(level.waypoints.size);
             self.stuckTime = getTime();
             self.waypointStartTime = getTime(); // Reset waypoint timer too
             
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
     }
    
    // Find nearest visible hunter
    nearestHunter = self find_nearest_visible_hunter();
    
    // Reset melee timer if no hunters found
    if (!isDefined(nearestHunter))
    {
        if (isDefined(self.lastMeleeTime))
        {
            self.lastMeleeTime = 0;
        }
    }
    
    if (isDefined(nearestHunter))
    {
        dist = distance(self.origin, nearestHunter.origin);
        
                 if (dist < 60) // Close enough for melee attack (reduced from 100)
         {
             // Check if we can actually reach the hunter for melee (no wall between us)
             meleeTrace = bulletTrace(self.origin + (0,0,50), nearestHunter.origin + (0,0,50), false, self);
             if (isDefined(meleeTrace["fraction"]) && meleeTrace["fraction"] > 0.8) // Almost clear path for melee
             {
                 // Face the hunter
                 targetVector = nearestHunter.origin - self.origin;
                 if (isDefined(targetVector))
                 {
                     targetAngles = vectorToAngles(targetVector);
                     self setPlayerAngles(targetAngles);
                 }
                 
                 // Stop moving and melee attack
                 self setWalkDir("none");
                 
                 // Melee attack
                 if (!isDefined(self.lastMeleeTime))
                     self.lastMeleeTime = 0;
                     
                 currentTime = getTime();
                 if (currentTime - self.lastMeleeTime > 500) // Melee every 500ms
                 {
                     self meleeWeapon(true);
                     wait 0.1;
                     self meleeWeapon(false);
                     self.lastMeleeTime = currentTime;
                 }
             }
             else
             {
                 // Can't melee through wall, move towards hunter using waypoints
                 bestWaypoint = self find_best_waypoint_towards_target(nearestHunter);
                 if (isDefined(bestWaypoint))
                 {
                     self move_to_waypoint(bestWaypoint);
                 }
                 else
                 {
                     // If no good waypoint found, try to move around obstacles
                     self find_alternative_path();
                 }
             }
         }
            else // Too far, move towards hunter using waypoints
    {
        // Use waypoint pathfinding instead of direct movement
        bestWaypoint = self find_best_waypoint_towards_target(nearestHunter);
        if (isDefined(bestWaypoint))
        {
            self move_to_waypoint(bestWaypoint);
        }
        else
        {
            // If no good waypoint found, try to move around obstacles
            self find_alternative_path();
        }
    }
    }
    else // No hunters visible, patrol randomly
    {
        // Always ensure zombie is moving when no hunters found
        if (!isDefined(self.currentWaypoint))
        {
            self.currentWaypoint = randomInt(level.waypoints.size);
            if (!isDefined(self.currentWaypoint))
                self.currentWaypoint = 0;
        }
        
        self patrol_random_waypoints();
        
        // Force movement if not moving
        if (isDefined(self.currentWaypoint))
        {
            self move_to_waypoint(self.currentWaypoint);
        }
    }
}

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
            
            // Move to camp spot
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
        if (isDefined(self.campWaypoint) && isDefined(level.waypoints[self.campWaypoint]))
        {
            campDist = distance(self.origin, level.waypoints[self.campWaypoint].origin);
            if (campDist < 100) // Close to camp spot
            {
                self setWalkDir("none"); // Stop and camp
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
                 if(isDefined(trace["fraction"]) && trace["fraction"] > 0.7) // Hunter is visible (more strict)
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
         }
         else
         {
             // For zombies, force a completely new random waypoint and direction
             self.currentWaypoint = randomInt(level.waypoints.size);
             if (!isDefined(self.currentWaypoint))
                 self.currentWaypoint = 0;
             
             // Force random direction movement
             randomAngle = randomInt(360);
             self setPlayerAngles((0, randomAngle, 0));
             wait 0.1;
             self setWalkDir("forward");
             
             iPrintlnBold("Bot " + self.name + " waypoint timeout, forcing new direction " + randomAngle);
         }
         self.waypointStartTime = getTime();
         return;
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
    
         // Check if path is clear - more lenient checking
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
     
          if (isDefined(trace["fraction"]) && trace["fraction"] >= 0.5) // More lenient path checking
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
         
         // Reset waypoint timer when picking new waypoint
         self.waypointStartTime = getTime();
     }
}

// Move towards target using waypoints (zombies)
move_to_target_using_waypoints(target)
{
    if (!isDefined(target) || !isDefined(level.waypoints))
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