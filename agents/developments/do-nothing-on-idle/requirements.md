# Do Nothing on Idle - Requirements Document

## 1. Overview

### 1.1 Purpose
This feature adds a third idle behavior option to the WoS Bot: "Do Nothing / Leave As Is". When this option is selected, the bot will leave the emulator and game running in their current state when idle time exceeds the configured threshold, but release the emulator slot so other profiles can acquire and use the emulator.

### 1.2 Business Context
- **Current Options**:
  1. Close Emulator: Closes emulator and releases slot
  2. Send Game to Background: Keeps emulator running, sends game to home screen, holds slot
- **New Option**: Do Nothing: Leaves emulator and game running, releases slot for other profiles
- **User Scenario**: User wants to keep game active for manual play or faster resume, but allow other profiles to use the same emulator for character switching

### 1.3 Relationship to Existing Features
- **Multi-Emulator Support**: Works with account-based conflict detection (same `emulatorNumber` cannot run simultaneously)
- **Switch Profile**: Compatible with character switching - emulator stays running for faster character switches
- **Idle Management**: Extends existing idle time configuration system

### 1.4 Key Assumptions
1. **Emulator Stability**: Emulator remains stable when left running with game active
2. **Game State**: Game won't timeout or disconnect when left idle with UI active
3. **Resource Usage**: Accept higher resource usage (emulator stays running)
4. **Slot Management**: Releasing slot while emulator runs is safe and doesn't cause conflicts

---

## 2. Requirements

### 2.1 Functional Requirements

#### FR1: Idle Behavior Configuration
- **FR1.1**: Add third idle behavior option: "Do Nothing / Leave As Is"
- **FR1.2**: Configuration key: `IDLE_BEHAVIOR_STRING` (String, default: "CLOSE_EMULATOR")
  - Valid values: "CLOSE_EMULATOR", "SEND_TO_BACKGROUND", "DO_NOTHING"
- **FR1.3**: UI should show three mutually exclusive options:
  - Close Emulator (default)
  - Send Game to Background
  - Do Nothing / Leave As Is
- **FR1.4**: Only one idle behavior can be active at a time
- **FR1.5**: Configuration defaults to "CLOSE_EMULATOR" if not set or invalid

#### FR2: Do Nothing Behavior Implementation
- **FR2.1**: When idle time exceeded and "Do Nothing" is selected:
  - Leave emulator running
  - Leave game in current state (active/in-game)
  - Release the emulator slot
  - Log appropriate message
- **FR2.2**: When next task approaches (within 1 minute), reacquire emulator slot
- **FR2.3**: Slot reacquisition should work even when emulator is already running
- **FR2.4**: No changes to emulator or game state during idle period

#### FR3: Slot Management Integration
- **FR3.1**: Properly release emulator slot when entering idle state
- **FR3.2**: Allow other profiles to acquire the same emulator while idle
- **FR3.3**: Handle slot reacquisition when idle period ends
- **FR3.4**: Ensure no conflicts with account-based multi-emulator logic
- **FR3.5**: Thread-safe slot management during idle transitions

#### FR4: UI Configuration
- **FR4.1**: Update idle behavior selection UI to show three options
- **FR4.2**: Radio buttons or dropdown with clear labels
- **FR4.3**: Tooltips explaining each option:
  - "Close Emulator": "Closes emulator and releases slot for other profiles"
  - "Send Game to Background": "Keeps emulator running, sends game to home screen, holds slot"
  - "Do Nothing / Leave As Is": "Leaves emulator and game running, releases slot for other profiles"

### 2.2 Non-Functional Requirements

#### NFR1: Performance
- Slot release/reacquisition should be fast (< 1 second)
- No significant performance impact on other profiles
- Memory usage acceptable (emulator stays running)

#### NFR2: Reliability
- Emulator remains stable during idle periods
- Slot management remains thread-safe
- No race conditions during idle transitions
- Proper error handling if slot operations fail

#### NFR3: Configuration Defaults
- Default behavior is "CLOSE_EMULATOR" if configuration is not set or invalid
- No breaking changes to existing APIs
- Invalid configuration values default to "CLOSE_EMULATOR"

#### NFR4: User Experience
- Clear configuration options
- Appropriate logging for idle state changes
- Intuitive option naming and descriptions

---

## 3. Technical Design

### 3.1 Configuration Changes

#### 3.1.1 EnumConfigurationKey Updates
Replace existing boolean configuration keys with a single string-based key:

```java
// Idle behavior options (replaces IDLE_BEHAVIOR_SEND_TO_BACKGROUND_BOOL and IDLE_BEHAVIOR_DO_NOTHING_BOOL)
IDLE_BEHAVIOR_STRING("CLOSE_EMULATOR", String.class),
```

**Valid values**: "CLOSE_EMULATOR", "SEND_TO_BACKGROUND", "DO_NOTHING"
**Default**: "CLOSE_EMULATOR"

#### 3.1.2 UI Configuration Logic
Update `EmuConfigLayoutController.java` to handle three options:

```java
enum IdleBehavior {
    CLOSE_EMULATOR(false, false),
    SEND_TO_BACKGROUND(true, false),
    DO_NOTHING(false, true);

    private final boolean sendToBackground;
    private final boolean doNothing;

    IdleBehavior(boolean sendToBackground, boolean doNothing) {
        this.sendToBackground = sendToBackground;
        this.doNothing = doNothing;
    }

    public boolean shouldSendToBackground() { return sendToBackground; }
    public boolean shouldDoNothing() { return doNothing; }

    public static IdleBehavior fromConfig(boolean sendToBackground, boolean doNothing) {
        if (doNothing) return DO_NOTHING;
        if (sendToBackground) return SEND_TO_BACKGROUND;
        return CLOSE_EMULATOR;
    }
}
```

### 3.2 Implementation Changes

#### 3.2.1 TaskQueue.java Modifications
Update `idlingEmulator()` method to use string-based configuration with backward compatibility:

```java
private void idlingEmulator(LocalDateTime delayUntil) {
    // Get idle behavior from configuration (defaults to CLOSE_EMULATOR if not set)
    String idleBehaviorConfig = Optional
            .ofNullable(ServConfig.getServices().getGlobalConfig())
            .map(cfg -> cfg.getOrDefault(
                    EnumConfigurationKey.IDLE_BEHAVIOR_STRING.name(),
                    EnumConfigurationKey.IDLE_BEHAVIOR_STRING.getDefaultValue()))
            .orElse(EnumConfigurationKey.IDLE_BEHAVIOR_STRING.getDefaultValue());

    // Convert to IdleBehavior enum (defaults to CLOSE_EMULATOR if invalid)
    IdleBehavior behavior = IdleBehavior.fromString(idleBehaviorConfig);

    if (behavior == IdleBehavior.DO_NOTHING) {
        // Do nothing - leave emulator and game running, but release slot
        emuManager.releaseEmulatorSlot(profile);
        logInfo("Leaving emulator and game running due to idle. Next task: " + delayUntil);
    } else if (behavior == IdleBehavior.SEND_TO_BACKGROUND) {
        // Send game to background (home screen), keep emulator and game running
        emuManager.sendGameToBackground(profile.getEmulatorNumber());
        logInfo("Sending game to background due to large inactivity. Next task: " + delayUntil);
    } else {
        // Close the entire emulator (default behavior)
        emuManager.closeEmulator(profile.getEmulatorNumber());
        logInfo("Closing emulator due to large inactivity. Next task: " + delayUntil);
        emuManager.releaseEmulatorSlot(profile);
    }

    DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    updateProfileStatus("Idling till " + formatter.format(delayUntil));
}
```

#### 3.2.2 enqueueNewTask() Method
No changes needed - existing logic handles slot reacquisition properly.

### 3.3 UI Changes

#### 3.3.1 EmuConfigLayoutController.java Updates
```java
// Initialize the idle behavior combobox with three options
comboboxIdleBehavior.setItems(FXCollections.observableArrayList(IdleBehavior.values()));

// Get idle behavior from string config (defaults to CLOSE_EMULATOR if not set)
String idleBehaviorConfig = globalConfig.getOrDefault(EnumConfigurationKey.IDLE_BEHAVIOR_STRING.name(), 
        EnumConfigurationKey.IDLE_BEHAVIOR_STRING.getDefaultValue());

IdleBehavior currentBehavior = IdleBehavior.fromString(idleBehaviorConfig);
comboboxIdleBehavior.setValue(currentBehavior);

// Handle selection changes
comboboxIdleBehavior.setOnAction(event -> {
    IdleBehavior selected = comboboxIdleBehavior.getValue();
    if (selected != null) {
        // Save the new string-based configuration
        ServScheduler.getServices().saveEmulatorPath(
                EnumConfigurationKey.IDLE_BEHAVIOR_STRING.name(), 
                selected.getConfigValue());
        if (selected.shouldSendToBackground()) {
            showConcurrentInstanceWarning();
        }
    }
});
```

---

## 4. Implementation Plan

### 4.1 Phase 1: Configuration Infrastructure
1. Replace `IDLE_BEHAVIOR_SEND_TO_BACKGROUND_BOOL` and `IDLE_BEHAVIOR_DO_NOTHING_BOOL` with `IDLE_BEHAVIOR_STRING` in `EnumConfigurationKey`
2. Update `IdleBehavior` enum to support string-based configuration (defaults to CLOSE_EMULATOR if invalid)
3. Update UI controller to handle three options using string config
4. Test configuration saving/loading with default fallback

**Estimated Time**: 1-2 hours

### 4.2 Phase 2: Core Implementation
1. Update `idlingEmulator()` method in `TaskQueue.java`
2. Implement "do nothing" logic (release slot only)
3. Add appropriate logging
4. Test idle behavior switching

**Estimated Time**: 1-2 hours

### 4.3 Phase 3: Integration Testing
1. Test all three idle behaviors
2. Test slot management during idle transitions
3. Test with multi-emulator scenarios
4. Test default behavior when config is missing or invalid

**Estimated Time**: 2-3 hours

### 4.4 Phase 4: Documentation and UI Polish
1. Update tooltips and help text
2. Update configuration reference documentation
3. Test edge cases

**Estimated Time**: 1 hour

**Total Estimated Time**: 5-8 hours

---

## 5. Testing Scenarios

### 5.1 Test Case 1: Do Nothing Behavior
**Setup**:
- Profile A running on emulator 0
- IDLE_BEHAVIOR_DO_NOTHING_BOOL = true
- Next task scheduled in 10 minutes (> 5min idle limit)

**Expected**:
- Profile A releases emulator slot
- Emulator and game remain running
- Other profiles can acquire emulator 0
- Profile A reacquires slot when next task approaches

### 5.2 Test Case 2: Multi-Emulator with Do Nothing
**Setup**:
- Profile A (emu 0) and Profile B (emu 1) running
- Profile A becomes idle, Profile B still active
- IDLE_BEHAVIOR_DO_NOTHING_BOOL = true

**Expected**:
- Profile A releases slot for emu 0
- Profile B continues using emu 1
- New profile can acquire emu 0 slot
- Profile A can reacquire emu 0 when needed

### 5.3 Test Case 3: Switch Profile Compatibility
**Setup**:
- Profile A (emu 0, character 1) running
- Profile B (emu 0, character 2) waiting
- Profile A becomes idle with "do nothing"

**Expected**:
- Profile A releases slot, emulator stays running
- Profile B acquires slot and can switch to character 2
- Faster character switching due to emulator staying active

---

## 6. Success Criteria

### 6.1 Functional Success
- ✅ Three idle behavior options available in UI
- ✅ "Do Nothing" releases slot while keeping emulator/game running
- ✅ Slot reacquisition works properly
- ✅ No conflicts with multi-emulator logic
- ✅ Compatible with character switching

### 6.2 Performance Success
- Slot release/reacquisition < 1 second
- No performance degradation for other profiles
- Acceptable resource usage

### 6.3 Reliability Success
- Thread-safe idle transitions
- No race conditions
- Proper error handling
- Backward compatible

---

## 7. Risk Assessment

### 7.1 Medium Risk: Game Timeout
**Risk**: Game may timeout/disconnect when left idle with UI active
**Mitigation**: Monitor and adjust based on real-world usage
**Fallback**: Users can switch back to other idle behaviors

### 7.2 Low Risk: Resource Usage
**Risk**: Higher CPU/memory usage with emulator staying active
**Mitigation**: Clear documentation about resource implications
**Fallback**: Users choose based on their system capabilities

### 7.3 Low Risk: Configuration Complexity
**Risk**: Three options may confuse users
**Mitigation**: Clear labels, tooltips, and documentation
**Fallback**: Default behavior unchanged

---

## 8. References

### 8.1 Related Documentation
- `agents/developments/multi-emulator/requirements.md` - Multi-emulator support
- `agents/developments/switch_profile/requirements.md` - Character switching
- `agents/08-configuration-reference.md` - Configuration keys
- `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/TaskQueue.java` - Current idle logic

### 8.2 Related Code
- `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/TaskQueue.java` - Idle behavior implementation
- `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java` - Slot management
- `wos-hmi/src/main/java/cl/camodev/wosbot/emulator/view/EmuConfigLayoutController.java` - UI configuration

---

**Document Version**: 1.0
**Last Updated**: 2025-12-18
**Status**: Ready for Implementation















