# Waypoint Type System

This mod now supports different waypoint types that affect how bots move when reaching those waypoints.

## Available Waypoint Types

- **stand** (default): Normal walking movement
- **crouch**: Bot will crouch while moving
- **jump**: Bot will jump while moving
- **prone**: Bot will go prone while moving

## How to Set Waypoint Types

### Using Dev Tools (In-Game)
1. Load the dev tools in-game
2. Place waypoints as normal
3. To change a waypoint type, use the `CycleWaypointType` function
4. The waypoint will cycle through: stand → crouch → jump → prone → stand

### Manual Code Setting
You can manually set waypoint types in your waypoint files:

```gsc
level.waypoints[0].type = "jump";
level.waypoints[1].type = "crouch";
level.waypoints[2].type = "prone";
level.waypoints[3].type = "stand";
```

## Visual Indicators

Waypoints are displayed with different colors based on their type:
- **Blue**: Stand (default)
- **Yellow**: Crouch
- **Cyan**: Jump
- **Orange**: Prone
- **Red**: Unlinked waypoints (overrides type color)
- **Purple**: Dead-end waypoints (overrides type color)

## How It Works

When a bot approaches a waypoint, the system:
1. Checks the waypoint type when very close to waypoint (within 50 units)
2. Applies the appropriate bot stance using `setBotStance()`:
   - "stand" - Normal standing stance
   - "crouch" - Crouching stance
   - "jump" - Jumping stance (automatically handles jumping)
   - "prone" - Prone stance
3. Continues normal movement or camps (for hunters)

**Special Hunter Behavior:**
- Hunters will apply waypoint types even when camping at their camp spots
- Stance changes happen before setting walk direction to "none"

## Example Usage

```gsc
// Create a waypoint that requires jumping
level.waypoints[2].type = "jump";

// Create a waypoint that requires crouching
level.waypoints[5].type = "crouch";

// Create a waypoint that requires going prone
level.waypoints[8].type = "prone";
```

## Notes

- If no type is specified, waypoints default to "stand"
- The system works for both zombies and hunters
- Debug messages will show when any bot uses waypoint types (reduced frequency to avoid spam)
- Waypoint types are saved when using the dev tools save function
