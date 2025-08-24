# Waypoint Type System Test Guide

## Testing Steps

### 1. Setup Test Environment
- Load a map with waypoints
- Enable dev tools
- Place 3 waypoints in a triangle formation
- Set different types for each waypoint:
  - Waypoint 0: "stand" (default)
  - Waypoint 1: "jump" 
  - Waypoint 2: "crouch"

### 2. Manual Waypoint Type Setting
```gsc
// Set waypoint types manually
level.waypoints[0].type = "stand";
level.waypoints[1].type = "jump";
level.waypoints[2].type = "crouch";
```

### 3. Expected Behavior
- Bot should move between waypoints normally
- Bot should only change stance when very close to waypoint (within 50 units)
- Bot should show debug messages when:
  - Moving to waypoints
  - Reaching waypoints
  - Using waypoint types (every 2 seconds)

### 4. Debug Messages to Look For
- "[name] moving to waypoint [X] at distance: [Y]"
- "[name] reached waypoint [X], updating current waypoint"
- "[name] at waypoint using type: [type] at distance: [Y]"

### 5. Troubleshooting
If bot is not moving between waypoints:
1. Check if waypoints are properly linked
2. Verify waypoint count is correct
3. Check if A* pathfinding is working
4. Look for debug messages to see current behavior

### 6. Common Issues
- Bot changing stance too early: Fixed - now only changes within 50 units
- Bot not moving: Check waypoint linking and pathfinding
- Debug spam: Reduced to show every 2 seconds
