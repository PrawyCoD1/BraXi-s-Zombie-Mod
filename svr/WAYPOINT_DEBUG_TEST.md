# Waypoint Type Debug Test

## Quick Test Commands

### 1. Manual Waypoint Type Setting
```gsc
// Set waypoint 0 to prone type
level.waypoints[0].type = "prone";

// Check if waypoint type is set
iPrintlnBold("Waypoint 0 type: " + level.waypoints[0].type);

// Force a hunter to camp at waypoint 0
self.campWaypoint = 0;
```

### 2. Debug Output to Look For
- `[name] DEBUG: campDist=[X], waypointType=[type], campWaypoint=[Y]`
- `[name] DEBUG: currentStance=[stance]`
- `[name] DEBUG: changing stance from [old] to [new]`
- `[name] DEBUG: stance already correct: [stance]`

### 3. Common Issues to Check
1. **Waypoint Type Not Set**: Check if `level.waypoints[X].type` is actually set
2. **Distance Too Far**: Check if `campDist` is less than 2500 (50 units squared)
3. **Stance Not Changing**: Check if current stance equals target stance
4. **Camp Waypoint Wrong**: Check if hunter is camping at the correct waypoint

### 4. Manual Stance Test
```gsc
// Test if setBotStance works manually
self setBotStance("prone");
iPrintlnBold("Manual stance test: " + self getStance());
```

### 5. Expected Debug Output
If working correctly, you should see:
```
[name] DEBUG: campDist=1000, waypointType=prone, campWaypoint=0
[name] DEBUG: currentStance=stand
[name] DEBUG: changing stance from stand to prone
[name] at camp waypoint using type: prone at distance: 1000
```
