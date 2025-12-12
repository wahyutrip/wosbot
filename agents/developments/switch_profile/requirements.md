# Character Profile Switching Feature - Requirements Document

## 1. Overview

### 1.1 Purpose
This feature enables the WoS Bot to automatically switch between character profiles within the same game account. This allows multiple characters from the same account to run sequentially on a single emulator instance, maximizing resource utilization when PC limitations restrict concurrent emulator instances.

### 1.2 Business Context
- **User Scenario**: User has 3 accounts with 9 total characters across different servers
- **Constraint**: Only 1 emulator instance can run simultaneously (PC limitation)
- **Requirement**: Automatically switch characters when initializing profiles to ensure the correct character is active before task execution

### 1.3 Game Context
- Each account can hold up to 4 characters per server
- Cannot multi-log different characters from the same account simultaneously
- Different accounts can login simultaneously (different email, different device)
- Character switching is done via: Profile Menu - Settings Button → Switch Character Button → Select Character from List

### 1.4 UI Screenshots Reference
The following UI screenshots have been provided for reference:
1. **Home Screen**: Shows profile avatar in top-left corner (tap to open profile menu)
2. **Profile Menu**: Shows character name "[FBR]Adam Hamm", character ID "302024886", server "#2115", and Settings button (gear icon)
3. **Settings Menu**: Shows "Characters" button (two person silhouettes icon) - this is the Switch Character option
4. **Character List Menu**: Shows scrollable list of characters grouped by server, each with Furnace Level icon, character name, and server number
5. **Character Switch Confirmation**: Shows confirmation dialog with character name and "Cancel"/"Confirm" buttons

---

## 2. Requirements

### 2.1 Functional Requirements

#### FR1: Character Profile Configuration
- **FR1.1**: Each profile must store character identification information:
  - Character ID (Integer/String) - Optional
  - Character Name (String) - Optional
  - Alliance Code (String, 3 characters alphanumeric) - Optional
  - Character Server Number (Integer/String) - Optional
- **FR1.2**: Character information should be configurable via GUI
- **FR1.3**: Character information should be stored as direct database columns (not as configuration)
- **FR1.4**: Character information should be optional (backward compatible with existing profiles). **If character name and ID are not set, skip character verification and character switching entirely** - use existing initialization logic without any character-related checks.
- **FR1.5**: Alliance Code field:
  - Maximum 3 characters (alphanumeric)
  - Examples: "BOT", "404", "ABC"
  - Used to identify character names that are padded with alliance code (e.g., "[BOT]Wahyu Tri P" or "[404] John Doe")
  - Automatically converted to uppercase when saved

#### FR2: Character Verification
- **FR2.1**: During initialization, verify that the currently active character matches the profile's configured character
- **FR2.2**: Character verification should occur after home screen is detected but before stamina reading
- **FR2.3**: Character verification should use the same navigation method as stamina check:
  - Tap profile avatar area (`CommonGameAreas.PROFILE_AVATAR`) to open profile menu
  - Use OCR to read character ID from the profile screen (coordinates to be provided)
  - Use OCR to read character name from the profile screen (coordinates to be provided)
  - If alliance code is configured, character name may be padded with alliance code (e.g., "[BOT]Wahyu Tri P")
  - When comparing character names, strip alliance code prefix if present before comparison
- **FR2.4**: If character matches, close profile menu and continue with normal initialization
- **FR2.5**: If character does not match, trigger character switching flow
- **FR2.6**: If character verification fails (false alarm), but character is actually correct, handle gracefully and continue (see edge case 6.5)

#### FR3: Character Switching Flow
- **FR3.1**: Open profile menu using same method as stamina check:
  - Tap profile avatar area (`CommonGameAreas.PROFILE_AVATAR`) to open profile menu
- **FR3.2**: Navigate to Settings Menu:
  - Use template search to find Settings button in profile menu
  - Tap Settings button when found
- **FR3.3**: Navigate to Switch Character Menu:
  - Use template search to find "Switch Character" button in Settings menu
  - Tap Switch Character button when found
- **FR3.4**: Search for target character in character list:
  - Character list is scrollable and may contain multiple characters
  - Use template search to find "Furnace Level" image template
  - When Furnace Level template is found, use OCR to read character name above it
  - Check all visible Furnace Level instances (multiple characters may be visible)
  - Compare OCR'd character name with profile's configured character name
  - If character name matches, verify server number matches (if configured)
- **FR3.5**: Handle scrolling if character not found:
  - If target character not found in visible area, scroll down slightly
  - Restart search: template search for Furnace Level again
  - Repeat OCR and name comparison process
  - Continue scrolling and searching until character found or max scroll attempts reached
- **FR3.6**: Select target character:
  - When target character is found (name matches), tap on the character entry
  - Use template search to find and tap "Confirm" button in confirmation dialog
- **FR3.7**: Wait for character switch to complete:
  - Wait for game to load new character
  - Verify character switch was successful (re-check character ID/name)
- **FR3.8**: Re-initialize after successful switch:
  - Close any open menus
  - Re-check home screen
  - Read stamina and continue with normal initialization
- **FR3.9**: Handle character not found scenario:
  - If target character not found after max attempts, log error
  - Close emulator
  - Release emulator slot
  - Continue to next profile in queue (do not retry current profile)

#### FR4: Error Handling
- **FR4.1**: If character not found in list after max scroll attempts:
  - Log error with character name and server
  - Close emulator
  - Release emulator slot
  - Continue to next profile in queue (do not set recurring=true, do not retry)
- **FR4.2**: If Settings button not found or navigation fails:
  - Log error, retry navigation (max 3 attempts)
  - If still fails, set `recurring=true` to retry initialization
- **FR4.3**: If Switch Character button not found:
  - Log error, retry navigation (max 3 attempts)
  - If still fails, set `recurring=true` to retry initialization
- **FR4.4**: If character list is empty or not loaded:
  - Wait for list to load (with timeout: 10 seconds)
  - Retry if timeout reached (max 3 attempts)
  - If still fails, set `recurring=true` to retry initialization
- **FR4.5**: If Confirm button not found after selecting character:
  - Log error, retry selection (max 3 attempts)
  - If still fails, set `recurring=true` to retry initialization

#### FR5: Emulator Slot Management
- **FR5.1**: When profile completes, close emulator and release slot
- **FR5.2**: Next profile in queue acquires emulator slot
- **FR5.3**: Character switching only occurs during initialization (not during task execution)

### 2.2 Non-Functional Requirements

#### NFR1: Performance
- Character switching should complete within reasonable time (target: < 30 seconds)
- OCR operations should use retry logic with appropriate delays
- Template matching should use existing caching mechanisms

#### NFR2: Reliability
- Character switching should have retry logic (max 3 attempts recommended)
- Should handle UI variations and loading delays
- Should gracefully handle failures without breaking the queue

#### NFR3: Backward Compatibility
- Existing profiles without character configuration should continue to work
- Character switching should be opt-in (only when character info is configured)
- No breaking changes to existing APIs or data structures

#### NFR4: Maintainability
- Code should follow existing project patterns (helper classes, configuration keys)
- Should use existing OCR and navigation infrastructure
- Should be well-documented with Javadoc

#### NFR5: Code Reusability
- **Reuse existing helpers**: Leverage `StaminaHelper` navigation pattern for opening profile menu
- **Reuse existing utilities**: Use `TemplateSearchHelper` for UI element detection, `TextRecognitionRetrier` for OCR operations
- **Reuse existing functions**: Use `CommonGameAreas.PROFILE_AVATAR` for profile menu access, existing emulator operations from `EmulatorManager`
- **Follow existing patterns**: Character switching helper should follow the same structure as `NavigationHelper`, `StaminaHelper`, etc.
- **Minimize code duplication**: Reuse existing OCR settings, retry logic, and error handling patterns

---

## 3. Technical Design

### 3.1 Data Model Changes

#### 3.1.1 Profile Configuration Keys
Add new configuration keys to `EnumConfigurationKey`:

```java
// Character Profile Configuration
CHARACTER_NAME_STRING("", String.class),
CHARACTER_SERVER_STRING("", String.class),
CHARACTER_ID_STRING("", String.class),
```

#### 3.1.2 Database Schema
No database schema changes required - character information stored as configuration entries in existing `configs` table.

### 3.2 Component Design

#### 3.2.1 CharacterSwitchHelper (New Helper Class)
**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/CharacterSwitchHelper.java`

**Responsibilities**:
- Verify current character matches profile configuration
- Navigate to character switching menu
- Read character list using OCR
- Select target character
- Verify character switch success

**Key Methods**:
```java
public boolean verifyCurrentCharacter(DTOProfiles profile)
public boolean switchToCharacter(DTOProfiles profile)
public String readCurrentCharacterName()  // From profile menu, coordinates TBD
public String readCurrentCharacterId()      // From profile menu, coordinates TBD
public boolean navigateToSettingsMenu()    // From profile menu
public boolean navigateToSwitchCharacterMenu()  // From settings menu
public List<CharacterInfo> searchCharacterInList(String characterName, String server)
public boolean selectCharacterFromList(String characterName, String server)
public void scrollCharacterList()          // Scroll down to see more characters
```

**Reused Components**:
- Uses `CommonGameAreas.PROFILE_AVATAR` for opening profile menu (same as `StaminaHelper`)
- Uses `TemplateSearchHelper` for finding UI elements (Settings button, Switch Character button, Furnace Level template, Confirm button)
- Uses `TextRecognitionRetrier` for OCR operations (character name, character ID reading)
- Uses `EmulatorManager` for emulator operations (tap, scroll, screenshot)

#### 3.2.2 InitializeTask Modifications
**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/impl/InitializeTask.java`

**Changes**:
- Add character verification step after `waitForHomeScreen()` and before `handleInitializationSuccess()`
- Integrate `CharacterSwitchHelper` for character switching logic
- Add retry logic for character switching failures
- **Skip character verification entirely if character name and ID are not configured**

**Modified Flow**:
```
1. ensureEmulatorRunning()
2. ensureGameInstalled()
3. ensureGameRunning()
4. waitForHomeScreen()
5. verifyAndSwitchCharacter()  // NEW STEP (only if character config is set)
   - If character name/ID not set → Skip this step entirely
   - If character matches → Close profile menu, continue
   - If character doesn't match → Switch character, then continue
6. handleInitializationSuccess()  // Reads stamina (uses same profile menu navigation)
```

**Integration Point**:
- Character verification happens **before** `updateStaminaFromProfile()` in `handleInitializationSuccess()`
- Both use the same navigation method: tap `CommonGameAreas.PROFILE_AVATAR` to open profile menu
- Character verification can reuse the profile menu already open, or open it if needed

#### 3.2.3 Template Resources
**Location**: `wos-utiles/src/main/resources/templates/`

**New Templates Required**:
- Settings menu button
- Switch Character button/menu
- Character list item template (for scrolling/selection)
- Character name region template
- Character server region template
- Character ID region template (optional)

**Add to EnumTemplates**:
```java
// Settings menu templates
GAME_PROFILE_SETTINGS_BUTTON("/templates/profile/settingsButton.png"),  // Settings button in profile menu
GAME_SETTINGS_SWITCH_CHARACTER_BUTTON("/templates/settings/switchCharacterButton.png"),  // Switch Character button in settings menu

// Character list templates
GAME_CHARACTER_FURNACE_LEVEL("/templates/character/furnaceLevel.png"),  // Furnace Level icon template for finding characters
GAME_CHARACTER_CONFIRM_BUTTON("/templates/character/confirmButton.png"),  // Confirm button in character switch confirmation dialog
GAME_CHARACTER_CANCEL_BUTTON("/templates/character/cancelButton.png"),  // Cancel button in character switch confirmation dialog (optional)
```

**Note**: Character name and server will be read via OCR above the Furnace Level template, not via separate templates. OCR coordinates will be calculated relative to the Furnace Level template position.

### 3.3 OCR Regions

#### 3.3.1 Character ID Region (Profile Menu)
- **Location**: Profile menu screen (coordinates to be provided)
- **OCR Settings**: Numbers only
- **Purpose**: Read current character ID for verification
- **Access Method**: Same as stamina check - tap `CommonGameAreas.PROFILE_AVATAR` to open profile menu

#### 3.3.2 Character Name Region (Profile Menu)
- **Location**: Profile menu screen (coordinates to be provided, above character ID)
- **OCR Settings**: Single line, alphanumeric + spaces + special characters (e.g., brackets, spaces)
- **Purpose**: Read current character name for verification
- **Access Method**: Same as stamina check - tap `CommonGameAreas.PROFILE_AVATAR` to open profile menu

#### 3.3.3 Character Name OCR (Character List)
- **Location**: Character selection screen, above Furnace Level template
- **OCR Method**: 
  1. Template search for `GAME_CHARACTER_FURNACE_LEVEL` template
  2. When found, calculate region above template (e.g., template Y - 50 pixels, width = screen width)
  3. Use OCR to read character name from calculated region
- **OCR Settings**: Single line, alphanumeric + spaces + special characters
- **Purpose**: Read character names from character list for matching
- **Note**: Multiple Furnace Level templates may be found (multiple characters visible), check all of them

### 3.4 Configuration Access Pattern

```java
// Get character configuration
String characterName = profile.getConfig(
    EnumConfigurationKey.CHARACTER_NAME_STRING, 
    String.class
);
String characterServer = profile.getConfig(
    EnumConfigurationKey.CHARACTER_SERVER_STRING, 
    String.class
);
String characterId = profile.getConfig(
    EnumConfigurationKey.CHARACTER_ID_STRING, 
    String.class
);

// Check if character switching is enabled
// If character name OR character ID is not set, skip character verification entirely
boolean characterSwitchingEnabled = 
    (characterName != null && !characterName.isEmpty()) || 
    (characterId != null && !characterId.isEmpty());

// If both are empty/null, skip all character-related logic and use existing initialization
```

---

## 4. Implementation Plan

### 4.1 Phase 1: Configuration and Data Model
1. Add configuration keys to `EnumConfigurationKey`
2. Update GUI to allow character configuration (optional)
3. Update profile model/DTO to support character fields (if needed)

### 4.2 Phase 2: Character Verification
1. Create `CharacterSwitchHelper` class
2. Implement `verifyCurrentCharacter()` method:
   - Use `CommonGameAreas.PROFILE_AVATAR` to open profile menu (same as `StaminaHelper`)
   - Read character ID from profile menu using OCR (coordinates TBD)
   - Read character name from profile menu using OCR (coordinates TBD)
   - Compare with profile configuration
   - Close profile menu if character matches
3. Define OCR regions for character ID/name reading (coordinates to be provided)
4. Test character verification logic

### 4.3 Phase 3: Character Switching
1. Implement navigation to Settings menu:
   - From profile menu, use template search to find Settings button
   - Tap Settings button when found
2. Implement navigation to Switch Character menu:
   - From Settings menu, use template search to find "Characters" button (Switch Character)
   - Tap Characters button when found
3. Implement character list reading:
   - Use template search to find "Furnace Level" template
   - For each Furnace Level found, calculate region above it
   - Use OCR to read character name from region above Furnace Level
   - Compare with target character name
4. Implement scrolling logic:
   - If character not found in visible area, scroll down
   - Restart Furnace Level template search
   - Repeat until character found or max scroll attempts reached
5. Implement character selection:
   - Tap on matching character entry
   - Use template search to find Confirm button
   - Tap Confirm button
6. Add retry and error handling:
   - Retry navigation steps (max 3 attempts each)
   - Handle character not found scenario (close emulator, continue to next profile)
   - Handle confirmation dialog failures

### 4.4 Phase 4: Integration
1. Integrate character switching into `InitializeTask`
2. Add template resources
3. Test end-to-end flow
4. Update documentation

### 4.5 Phase 5: Testing and Refinement
1. Test with multiple character scenarios
2. Test error cases (character not found, switching fails)
3. Test backward compatibility (profiles without character config)
4. Performance testing and optimization

---

## 5. User Workflow

### 5.1 Profile Setup
1. User creates/edits profile
2. User optionally configures:
   - Character Name: "John Doe"
   - Character Server: "1830"
   - Character ID: "1234" (optional)
3. User saves profile

### 5.2 Bot Execution Flow
1. Bot starts profile execution
2. Bot acquires emulator slot (if available)
3. Bot launches emulator and game (if needed)
4. Bot waits for home screen
5. **Bot verifies current character**:
   - If matches → Continue
   - If doesn't match → Switch character
6. Bot reads stamina and continues with tasks
7. Bot completes tasks
8. Bot closes emulator and releases slot
9. Next profile acquires slot and repeats

---

## 6. Edge Cases and Error Scenarios

### 6.1 Character Not Found
- **Scenario**: Target character not in character list
- **Handling**: Log error, retry (max 3 attempts), then set `recurring=true` for retry

### 6.2 Character List Not Loaded
- **Scenario**: Character list screen appears but list is empty/loading
- **Handling**: Wait for list to load (with timeout), retry if needed

### 6.3 Multiple Characters with Same Name
- **Scenario**: Multiple characters with same name on different servers
- **Handling**: Match by both name AND server number

### 6.4 Profile Without Character Config
- **Scenario**: Profile doesn't have character configuration
- **Handling**: Skip character verification, continue with normal initialization

### 6.5 Character Already Active
- **Scenario**: Correct character is already active (verification matches)
- **Handling**: Skip switching, close profile menu, continue with initialization
- **Note**: This is also a valid case for false alarms - if character verification fails (false negative) but character is actually correct, the system should handle gracefully. This edge case is important because OCR may occasionally misread character ID/name, but the character might still be correct.

### 6.6 Settings Menu Not Accessible
- **Scenario**: Settings button not found or menu doesn't open
- **Handling**: Retry navigation (max 3 attempts), log error, set `recurring=true` for retry

### 6.7 Character Not Found After Max Attempts
- **Scenario**: Target character not found in character list after scrolling and searching
- **Handling**: Log error with character name and server, close emulator, release emulator slot, continue to next profile in queue (do not retry current profile, do not set recurring=true)

---

## 7. Testing Requirements

### 7.1 Unit Tests
- Test `CharacterSwitchHelper.verifyCurrentCharacter()`
- Test `CharacterSwitchHelper.switchToCharacter()`
- Test OCR reading of character name/server
- Test character list parsing

### 7.2 Integration Tests
- Test full initialization flow with character switching
- Test initialization flow without character switching (backward compatibility)
- Test error handling and retry logic

### 7.3 Manual Testing Scenarios
1. Profile with character config, correct character active
2. Profile with character config, wrong character active
3. Profile without character config (backward compatibility)
4. Character not found in list
5. Multiple characters with same name
6. Settings menu navigation failures

---

## 8. Dependencies and Prerequisites

### 8.1 Existing Components (To Be Reused)
- `EmulatorManager` - For emulator operations (tap, scroll, screenshot)
- `TemplateSearchHelper` - For UI element detection (Settings button, Switch Character button, Furnace Level template, Confirm button)
- `TextRecognitionRetrier` - For OCR operations (character name, character ID reading with retry logic)
- `CommonGameAreas.PROFILE_AVATAR` - For opening profile menu (same as `StaminaHelper` uses)
- `StaminaHelper` - Reference implementation for profile menu navigation pattern
- `NavigationHelper` - Reference implementation for menu navigation patterns
- `EnumTemplates` - For template definitions
- `EnumConfigurationKey` - For configuration keys
- `DelayedTask` base class - For helper initialization and logging patterns

### 8.2 New Components
- `CharacterSwitchHelper` - New helper class
- Template images for settings/character switching UI
- OCR region definitions for character information

### 8.3 External Dependencies
- No new external dependencies required
- Uses existing OCR (Tesseract via Tess4j)
- Uses existing ADB operations

---

## 9. Feasibility Assessment

### 9.1 Technical Feasibility: ✅ FEASIBLE

**Supporting Evidence**:
1. ✅ OCR infrastructure exists and is proven to work
2. ✅ Template matching infrastructure exists
3. ✅ Navigation helper pattern exists
4. ✅ Configuration system supports new keys
5. ✅ InitializeTask is extensible
6. ✅ Emulator slot management already handles sequential execution

**Challenges**:
1. ⚠️ OCR accuracy for character names (may need tuning)
2. ⚠️ UI variations across game versions/regions
3. ⚠️ Character list scrolling if many characters exist
4. ⚠️ Timing/loading delays for character switching

**Mitigation**:
- Use retry logic and multiple OCR attempts
- Use template matching for UI elements (more reliable than OCR)
- Implement scrolling logic for character list
- Add appropriate delays and wait conditions

### 9.2 Implementation Complexity: MEDIUM

**Estimated Effort**:
- Configuration keys: 1 hour
- CharacterSwitchHelper: 8-12 hours
- InitializeTask integration: 2-4 hours
- Template resources: 2-4 hours
- Testing and refinement: 4-8 hours
- **Total**: ~20-30 hours

### 9.3 Risk Assessment

**Low Risk**:
- Configuration changes (backward compatible)
- Helper class creation (follows existing patterns)

**Medium Risk**:
- OCR accuracy for character names
- UI navigation reliability
- Character list parsing

**Mitigation Strategies**:
- Extensive testing with real game screenshots
- Robust error handling and retry logic
- Fallback to manual verification if needed

---

## 10. Success Criteria

### 10.1 Functional Success
- ✅ Character verification works correctly
- ✅ Character switching completes successfully
- ✅ Bot continues with normal initialization after switching
- ✅ Backward compatibility maintained (profiles without config work)

### 10.2 Performance Success
- Character switching completes in < 30 seconds
- No significant impact on initialization time when character matches
- OCR operations complete reliably (> 90% success rate)

### 10.3 Reliability Success
- Character switching succeeds > 95% of the time
- Error handling prevents queue failures
- Retry logic recovers from transient failures

---

## 11. Future Enhancements (Out of Scope)

### 11.1 Potential Improvements
- Character list caching (avoid re-reading if recently accessed)
- Character switching during task execution (not just initialization)
- Support for character switching via account switching (different emails)
- Character verification during task execution (detect if character changed)

### 11.2 Advanced Features
- Automatic character discovery (scan and list all available characters)
- Character priority/rotation scheduling
- Character state persistence across sessions

---

## 12. References

### 12.1 Related Documentation
- `agents/03-core-concepts.md` - Profile and task concepts
- `agents/04-task-system.md` - Task system documentation
- `agents/09-helper-classes.md` - Helper class patterns
- `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/impl/InitializeTask.java` - Current initialization logic

### 12.2 Related Code
- `NavigationHelper` - Menu navigation patterns
- `TemplateSearchHelper` - Template matching patterns
- `TextRecognitionRetrier` - OCR retry patterns
- `EmulatorManager` - Emulator operations

---

## 13. Approval and Sign-off

### 13.1 Review Checklist
- [ ] Technical feasibility confirmed
- [ ] Requirements complete and clear
- [ ] Implementation plan reviewed
- [ ] Testing strategy defined
- [ ] Risk assessment completed
- [ ] Backward compatibility verified

### 13.2 Next Steps
1. Review and approve requirements document
2. Create implementation tasks
3. Begin Phase 1 implementation
4. Create template resources (screenshots needed)
5. Implement and test incrementally

---

**Document Version**: 1.2  
**Last Updated**: 2025-01-12  
**Status**: Updated Based on Feedback

### Change Log
**Version 1.2 (2025-01-12)**:
- Added Alliance Code field (3-character alphanumeric) to character profile configuration (FR1.5)
- Updated character field order: ID, Name, Alliance Code, Server
- Updated character verification to handle alliance code prefix in character names (FR2.3)
- Updated character switching to strip alliance code prefix when comparing names (FR3.4)
- Changed storage from configuration system to direct database columns (FR1.3)

**Version 1.1 (2025-01-12)**:
- Clarified that if character name/ID not set, skip character verification entirely (FR1.4)
- Updated character verification to use same navigation as stamina check (FR2.3)
- Detailed character switching flow with template search approach (FR3)
- Added requirement to reuse existing helpers/utils/functions (NFR5)
- Updated error handling for character not found scenario (FR4.1, 6.7)
- Added edge case for character already active with false alarm handling (6.5)
- Updated template requirements to use Furnace Level template for character detection
- Added UI screenshots reference section (1.4)
- Updated implementation plan with detailed steps

