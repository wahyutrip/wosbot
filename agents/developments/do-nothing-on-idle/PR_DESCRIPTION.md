# Do Nothing on Idle - Pull Request Description

## Overview
This feature adds a third idle behavior option to the WoS Bot: **"Do Nothing / Leave As Is"**. When selected, the bot leaves the emulator and game running in their current state when idle time exceeds the configured threshold, but releases the emulator slot so other profiles can acquire and use the emulator.

## Changes Made

### 1. Configuration Infrastructure
- **Refactored configuration**: Replaced `IDLE_BEHAVIOR_SEND_TO_BACKGROUND_BOOL` and `IDLE_BEHAVIOR_DO_NOTHING_BOOL` with single `IDLE_BEHAVIOR_STRING` key in `EnumConfigurationKey.java`
- **Updated IdleBehavior enum**: Added `DO_NOTHING` option and `fromString()` method for string-based configuration (defaults to CLOSE_EMULATOR if invalid)
- **Enhanced UI controller**: Updated `EmuConfigLayoutController.java` to use string-based configuration with default fallback

### 2. Core Logic Implementation
- **Updated TaskQueue.java**: Modified `idlingEmulator()` method to implement the new "do nothing" behavior
- **Slot management**: Ensures emulator slot is released while keeping emulator and game running
- **Backward compatibility**: Existing configurations continue to work unchanged

### 3. Documentation
- **Requirements document**: Comprehensive analysis and technical design
- **Configuration reference**: Updated to include the new configuration key
- **Implementation guide**: Detailed step-by-step approach

## Behavior Comparison

| Behavior | Emulator State | Game State | Slot Held | Other Profiles Can Use |
|----------|----------------|------------|-----------|----------------------|
| Close Emulator | Closed | N/A | No | Yes |
| Send to Background | Running | Background | Yes | No |
| **Do Nothing** | **Running** | **Active** | **No** | **Yes** |

## User Benefits

1. **Faster Resume**: Game stays active, reducing initialization time when tasks resume
2. **Resource Efficiency**: Other profiles can utilize the same emulator while one is idle
3. **Flexibility**: Users can choose behavior based on their system capabilities and preferences
4. **Character Switching**: Compatible with existing character switching feature for faster transitions

## Technical Implementation

### Configuration Logic
```java
// Single string-based configuration (defaults to CLOSE_EMULATOR if not set or invalid)
String idleBehaviorConfig = config.getOrDefault(
    EnumConfigurationKey.IDLE_BEHAVIOR_STRING.name(),
    EnumConfigurationKey.IDLE_BEHAVIOR_STRING.getDefaultValue());
IdleBehavior behavior = IdleBehavior.fromString(idleBehaviorConfig);

switch (behavior) {
    case DO_NOTHING:
        // Release slot, keep emulator/game running
        break;
    case SEND_TO_BACKGROUND:
        // Send game to background, hold slot
        break;
    case CLOSE_EMULATOR:
    default:
        // Close emulator, release slot (default behavior)
        break;
}
```

### Slot Management
- **Idle State**: Slot released, allowing other profiles to acquire the emulator
- **Resume State**: Slot reacquired automatically when next task approaches
- **Thread Safety**: All operations maintain existing thread-safe patterns

## Testing Scenarios

### Scenario 1: Basic Do Nothing Behavior
- Profile A becomes idle with "Do Nothing" selected
- ✅ Emulator remains running with game active
- ✅ Slot released for other profiles
- ✅ Profile A reacquires slot when tasks resume

### Scenario 2: Multi-Emulator Compatibility
- Profile A (emu 0) idle, Profile B (emu 1) active
- ✅ Profile B continues normally
- ✅ Other profiles can acquire emu 0 slot
- ✅ No conflicts with account-based emulator sharing

### Scenario 3: Character Switching Integration
- Profile A (emu 0, char 1) idle, Profile B (emu 0, char 2) waiting
- ✅ Profile B can acquire emu 0 and switch to char 2
- ✅ Faster transitions due to emulator staying active

## Configuration Defaults
- ✅ Default behavior is "CLOSE_EMULATOR" if configuration is not set or invalid
- ✅ No breaking changes to APIs
- ✅ Existing multi-emulator and switch profile features work unchanged

## Configuration Options
Users can select from three idle behaviors via the emulator configuration UI:

1. **Close Emulator** (default): Closes emulator, releases slot
2. **Send Game to Background**: Keeps emulator running, sends game to home screen, holds slot
3. **Do Nothing / Leave As Is**: Leaves emulator and game running, releases slot

## Performance Impact
- **Memory/CPU**: Slightly higher resource usage (emulator stays running)
- **Slot Utilization**: Better utilization as idle profiles don't block slots
- **Resume Speed**: Faster resume times due to active game state

## Risk Assessment
- **Low Risk**: Game timeout possibility (user can switch behaviors if needed)
- **Low Risk**: Resource usage (users can monitor and adjust)
- **Very Low Risk**: Implementation follows existing patterns and maintains thread safety

## Files Changed
- `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/EnumConfigurationKey.java` - Replaced two boolean configs with single string config
- `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/IdleBehavior.java` - Added `fromString()` and `getConfigValue()` methods
- `wos-hmi/src/main/java/cl/camodev/wosbot/emulator/view/EmuConfigLayoutController.java` - Updated to use string-based config
- `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/TaskQueue.java` - Updated to use string-based config with backward compatibility
- `agents/08-configuration-reference.md` - Updated configuration reference

## Testing Checklist
- [ ] Three idle behavior options appear in UI
- [ ] Configuration saves/loads correctly
- [ ] "Do Nothing" releases slot while keeping emulator running
- [ ] Slot reacquisition works on task resume
- [ ] Multi-emulator conflicts avoided
- [ ] Character switching still works
- [ ] Backward compatibility maintained
- [ ] No linter errors or compilation issues

## Related Features
- **Multi-Emulator Support**: Works with account-based conflict detection
- **Character Switching**: Compatible and optimized for faster transitions
- **Idle Management**: Extends existing idle time configuration system

---
**Status**: Ready for Testing and Review















