# Helper Classes Reference

This document provides detailed information about helper classes available for task development.

## Overview

Helper classes provide common functionality for tasks, reducing code duplication and ensuring consistent behavior. All helpers are initialized in the `DelayedTask` constructor and available to all task subclasses.

## NavigationHelper

**Purpose**: Navigate between game screens and verify current location

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/NavigationHelper.java`

**Initialization**:
```java
protected NavigationHelper navigationHelper;
// Initialized in DelayedTask constructor
```

### Key Methods

#### Navigation

```java
// Navigate to specific screen
void navigateTo(String screenName);

// Go to home (city view)
void goHome();

// Go to world map
void goToWorld();

// Ensure current location matches requirement
void ensureLocation(EnumStartLocation location);
```

#### Location Detection

```java
// Get current screen location
EnumStartLocation getCurrentLocation();

// Check if currently at home
boolean isAtHome();

// Check if currently at world map
boolean isAtWorld();
```

### Usage Examples

```java
// Navigate to specific screen
navigationHelper.navigateTo("AllianceScreen");

// Ensure starting from home
navigationHelper.ensureLocation(EnumStartLocation.HOME);

// Go to world map
navigationHelper.goToWorld();

// Return home after task
navigationHelper.goHome();
```

### Common Screen Names

- `"Home"` - City/home screen
- `"World"` - World map
- `"AllianceScreen"` - Alliance screen
- `"IntelScreen"` - Intel screen
- `"ArenaScreen"` - Arena screen
- (Screen names may vary by game version)

---

## StaminaHelper

**Purpose**: Manage stamina checking and consumption

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/StaminaHelper.java`

**Initialization**:
```java
protected StaminaHelper staminaHelper;
// Initialized in DelayedTask constructor
```

### Key Methods

#### Stamina Checking

```java
// Check if enough stamina (uses default threshold)
boolean hasEnoughStamina();

// Check if enough stamina for specific amount
boolean hasEnoughStamina(int requiredAmount);

// Get current stamina value
Integer getCurrentStamina();

// Get stamina regeneration time
Duration getStaminaRegenerationTime();
```

#### Stamina Management

```java
// Wait for stamina to be available
void waitForStamina(int requiredAmount);

// Consume stamina (mark as consumed)
void consumeStamina(int amount);
```

### Usage Examples

```java
// Check if enough stamina
if (!staminaHelper.hasEnoughStamina(20)) {
    logInfo("Not enough stamina, rescheduling");
    reschedule(LocalDateTime.now().plusHours(1));
    return;
}

// Get current stamina
Integer current = staminaHelper.getCurrentStamina();
logDebug("Current stamina: {}", current);

// Wait for stamina (blocks until available)
staminaHelper.waitForStamina(50);
```

### Integration with Tasks

Tasks that consume stamina should:

```java
@Override
protected boolean consumesStamina() {
    return true;  // Enables automatic stamina check in run()
}
```

---

## MarchHelper

**Purpose**: Manage troop marches and march queues

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/MarchHelper.java`

**Initialization**:
```java
protected MarchHelper marchHelper;
// Initialized in DelayedTask constructor
```

### Key Methods

#### March Information

```java
// Get active marches
List<MarchInfo> getActiveMarches();

// Get march queue size
int getMarchQueueSize();

// Check if march slot available
boolean isMarchSlotAvailable();

// Get total active marches count
int getActiveMarchCount();
```

#### March Operations

```java
// Recall specific march
void recallMarch(String marchId);

// Recall all marches
void recallAllMarches();

// Recall gather marches
void recallGatherMarches();
```

### Usage Examples

```java
// Check march queue
int queueSize = marchHelper.getMarchQueueSize();
logDebug("March queue size: {}", queueSize);

// Check if slot available
if (!marchHelper.isMarchSlotAvailable()) {
    logInfo("No march slots available");
    return;
}

// Get active marches
List<MarchInfo> marches = marchHelper.getActiveMarches();
for (MarchInfo march : marches) {
    logDebug("March: {} - Type: {}", march.getId(), march.getType());
}

// Recall gather marches
marchHelper.recallGatherMarches();
```

---

## TemplateSearchHelper

**Purpose**: Template matching for UI element detection

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/TemplateSearchHelper.java`

**Initialization**:
```java
protected TemplateSearchHelper templateSearchHelper;
// Initialized in DelayedTask constructor
```

### Key Methods

#### Template Search

```java
// Search for template on entire screen
DTOImageSearchResult searchTemplate(
    String templateName,
    double confidenceThreshold
);

// Search for template in specific region
DTOImageSearchResult searchTemplateInRegion(
    String templateName,
    DTOPoint topLeft,
    DTOPoint bottomRight,
    double confidenceThreshold
);
```

### Return Type

```java
DTOImageSearchResult {
    boolean isFound();
    int getX();           // X coordinate of match
    int getY();           // Y coordinate of match
    double getConfidence(); // Match confidence (0.0 - 1.0)
}
```

### Usage Examples

```java
// Search for button template
DTOImageSearchResult result = templateSearchHelper.searchTemplate(
    "claim_button.png",
    0.8  // 80% confidence threshold
);

if (result.isFound()) {
    logDebug("Button found at ({}, {})", result.getX(), result.getY());
    
    // Tap at found location
    emuManager.getEmulator(emulatorType, consolePath)
        .tap(EMULATOR_NUMBER, result.getX(), result.getY());
} else {
    logWarning("Button not found");
}

// Search in specific region
DTOPoint topLeft = new DTOPoint(100, 200);
DTOPoint bottomRight = new DTOPoint(500, 400);
DTOImageSearchResult result = templateSearchHelper.searchTemplateInRegion(
    "icon.png",
    topLeft,
    bottomRight,
    0.9  // 90% confidence
);
```

### Template Files

Templates are image files stored in:
- `wos-serv/src/main/resources/templates/`

Template naming convention:
- Use descriptive names: `claim_button.png`, `close_icon.png`
- Use PNG format for transparency support

---

## IntelScreenHelper

**Purpose**: Intel screen navigation and operations

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/IntelScreenHelper.java`

**Initialization**:
```java
protected IntelScreenHelper intelScreenHelper;
// Initialized in DelayedTask constructor
```

### Key Methods

#### Navigation

```java
// Navigate to intel screen
void navigateToIntelScreen();

// Check if at intel screen
boolean isAtIntelScreen();
```

#### Intel Operations

```java
// Process available intel
void processIntel();

// Check if intel is available
boolean hasAvailableIntel();

// Get intel count
int getIntelCount();
```

### Usage Examples

```java
// Navigate to intel screen
intelScreenHelper.navigateToIntelScreen();

// Check if intel available
if (intelScreenHelper.hasAvailableIntel()) {
    logInfo("Processing intel");
    intelScreenHelper.processIntel();
} else {
    logInfo("No intel available");
}
```

---

## AllianceHelper

**Purpose**: Alliance screen navigation and operations

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/AllianceHelper.java`

**Initialization**:
```java
protected AllianceHelper allianceHelper;
// Initialized in DelayedTask constructor
```

### Key Methods

#### Navigation

```java
// Navigate to alliance screen
void navigateToAllianceScreen();

// Check if at alliance screen
boolean isAtAllianceScreen();
```

#### Alliance Operations

```java
// Perform alliance operation
void performAllianceOperation(String operation);

// Check if in alliance
boolean isInAlliance();
```

### Usage Examples

```java
// Navigate to alliance screen
allianceHelper.navigateToAllianceScreen();

// Check if in alliance
if (allianceHelper.isInAlliance()) {
    logInfo("In alliance, performing operation");
    allianceHelper.performAllianceOperation("Tech");
} else {
    logWarning("Not in alliance");
}
```

---

## EventHelper

**Purpose**: Event screen navigation and operations

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/EventHelper.java`

**Initialization**:
```java
protected EventHelper eventHelper;
// Initialized in DelayedTask constructor
```

### Key Methods

#### Event Detection

```java
// Check if event is active
boolean isEventActive(String eventName);

// Navigate to event screen
void navigateToEvent(String eventName);
```

#### Bear Trap Specific

```java
// Check if bear trap is running
boolean isBearRunning();
```

### Usage Examples

```java
// Check if event is active
if (eventHelper.isEventActive("TundraTruck")) {
    logInfo("Tundra Truck event is active");
    eventHelper.navigateToEvent("TundraTruck");
} else {
    logInfo("Event not active");
}

// Check bear trap status
if (eventHelper.isBearRunning()) {
    logInfo("Bear trap is running");
}
```

---

## OCR Helpers

### TextRecognitionRetrier

**Purpose**: Retry logic wrapper for OCR operations with type conversion

**Location**: `wos-utiles/src/main/java/cl/camodev/utiles/ocr/TextRecognitionRetrier.java`

**Initialization**:
```java
protected TextRecognitionRetrier<Integer> integerHelper;
protected TextRecognitionRetrier<Duration> durationHelper;
protected TextRecognitionRetrier<String> stringHelper;
// Initialized in DelayedTask constructor
```

### Key Methods

```java
// OCR with retry and type conversion
<T> T ocrRegion(
    DTOPoint p1,                    // Top-left corner
    DTOPoint p2,                    // Bottom-right corner
    DTOTesseractSettings settings,  // OCR settings
    Function<String, T> converter,  // String to type converter
    Predicate<T> validator          // Result validator
);
```

### Usage Examples

#### Reading Integers

```java
DTOPoint topLeft = new DTOPoint(100, 200);
DTOPoint bottomRight = new DTOPoint(300, 250);

Integer value = integerHelper.ocrRegion(
    topLeft,
    bottomRight,
    CommonOCRSettings.SINGLE_LINE,
    NumberConverters::toInteger,
    NumberValidators::isValidInteger
);

if (value != null) {
    logDebug("Read integer: {}", value);
} else {
    logWarning("Failed to read integer");
}
```

#### Reading Durations

```java
Duration duration = durationHelper.ocrRegion(
    point1,
    point2,
    CommonOCRSettings.SINGLE_LINE,
    NumberConverters::toDuration,
    NumberValidators::isValidDuration
);

if (duration != null) {
    logDebug("Read duration: {}", duration);
}
```

#### Reading Strings

```java
String text = stringHelper.ocrRegion(
    point1,
    point2,
    CommonOCRSettings.SINGLE_LINE
);

if (text != null && !text.isEmpty()) {
    logDebug("Read text: {}", text);
}
```

### Common OCR Settings

```java
// Single line OCR (most common)
DTOTesseractSettings singleLine = CommonOCRSettings.SINGLE_LINE;

// Multi-line OCR
DTOTesseractSettings multiLine = CommonOCRSettings.MULTI_LINE;

// Custom settings
DTOTesseractSettings custom = new DTOTesseractSettings();
custom.setPageSegMode(7);  // Single line
custom.setOcrEngineMode(3); // Default
custom.setLanguage("eng");   // English
```

---

## BotTextRecognitionProvider

**Purpose**: OCR provider implementation for bot

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/ocr/BotTextRecognitionProvider.java`

**Initialization**:
```java
protected BotTextRecognitionProvider provider;
// Initialized in DelayedTask constructor
```

### Key Methods

```java
// Perform OCR on region
String ocrRegion(
    DTOPoint p1,
    DTOPoint p2,
    DTOTesseractSettings settings
) throws IOException, TesseractException;
```

### Usage Examples

```java
// Direct OCR (without retry)
try {
    String text = provider.ocrRegion(
        new DTOPoint(100, 200),
        new DTOPoint(300, 250),
        CommonOCRSettings.SINGLE_LINE
    );
    logDebug("OCR result: {}", text);
} catch (Exception e) {
    logError("OCR failed", e);
}
```

**Note**: Prefer using `TextRecognitionRetrier` wrappers for automatic retry logic.

---

## Helper Usage Best Practices

### 1. Always Check Return Values

```java
// BAD
marchHelper.recallMarch(marchId);  // What if it fails?

// GOOD
try {
    marchHelper.recallMarch(marchId);
    logInfo("March recalled successfully");
} catch (Exception e) {
    logError("Failed to recall march", e);
}
```

### 2. Use Appropriate Log Levels

```java
// Use DEBUG for detailed info
logDebug("March queue size: {}", queueSize);

// Use INFO for important events
logInfo("Stamina check passed");

// Use WARN for recoverable issues
logWarning("Low stamina detected");

// Use ERROR for failures
logError("OCR failed", exception);
```

### 3. Handle Null Returns

```java
// OCR can return null
Integer value = integerHelper.ocrRegion(...);
if (value == null) {
    logWarning("Failed to read value, retrying later");
    reschedule(LocalDateTime.now().plusMinutes(5));
    return;
}
```

### 4. Verify State Before Operations

```java
// Verify location before navigation
if (!navigationHelper.isAtHome()) {
    navigationHelper.goHome();
}

// Verify stamina before consuming
if (!staminaHelper.hasEnoughStamina(20)) {
    reschedule(LocalDateTime.now().plusHours(1));
    return;
}
```

### 5. Use Helpers Consistently

```java
// BAD - Direct emulator access
emulator.tap(EMULATOR_NUMBER, 500, 600);

// GOOD - Use navigation helper
navigationHelper.navigateTo("TargetScreen");
```

---

## Creating Custom Helpers

### Step 1: Create Helper Class

```java
package cl.camodev.wosbot.serv.task.helper;

import cl.camodev.wosbot.emulator.EmulatorManager;
import cl.camodev.wosbot.ot.DTOProfiles;

public class MyCustomHelper {
    
    private final EmulatorManager emuManager;
    private final String emulatorNumber;
    private final DTOProfiles profile;
    
    public MyCustomHelper(
            EmulatorManager emuManager,
            String emulatorNumber,
            DTOProfiles profile) {
        this.emuManager = emuManager;
        this.emulatorNumber = emulatorNumber;
        this.profile = profile;
    }
    
    public void doSomething() {
        // Helper logic
    }
}
```

### Step 2: Initialize in DelayedTask

```java
protected MyCustomHelper myCustomHelper;

public DelayedTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
    // ... existing initialization
    
    this.myCustomHelper = new MyCustomHelper(
        emuManager,
        EMULATOR_NUMBER,
        profile
    );
}
```

### Step 3: Use in Tasks

```java
@Override
protected void execute() {
    myCustomHelper.doSomething();
}
```

---

## CharacterSwitchHelper

**Purpose**: Character profile switching operations during initialization

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/CharacterSwitchHelper.java`

**Initialization**:
```java
// Initialized in InitializeTask constructor
private CharacterSwitchHelper characterSwitchHelper;

public InitializeTask(DTOProfiles profile, TpDailyTaskEnum tpDailyTask) {
    super(profile, tpDailyTask);
    this.characterSwitchHelper = new CharacterSwitchHelper(
        emuManager, 
        EMULATOR_NUMBER, 
        profile
    );
}
```

### Key Methods

#### Character Verification

```java
// Verify current character matches profile configuration
boolean verifyCurrentCharacter(DTOProfiles profile);
```

**Behavior**:
- Opens profile menu by tapping profile avatar
- Reads character ID and name from profile menu using OCR
- Compares with profile configuration (characterId, characterName)
- Returns `true` if character matches or config not set
- Returns `false` if character doesn't match
- Closes profile menu if character matches

**Character Configuration**:
- If both `characterName` and `characterId` are empty/null, verification is skipped (returns `true`)
- Character name matching handles alliance code prefix (e.g., "[BOT]Character Name")
- Uses case-insensitive matching for robustness

#### Character Switching

```java
// Switch to target character specified in profile
boolean switchToCharacter(DTOProfiles profile);
```

**Behavior**:
- Navigates to Settings menu from profile menu
- Navigates to Switch Character menu
- Searches for target character in character list
- Selects character and confirms switch
- Waits for character switch to complete
- Returns `true` if successful, `false` if character not found

**Character Search**:
- Uses Furnace Level template to locate characters in list
- Searches both ACTIVE and INACTIVE templates
- Reads character name above Furnace Level template using OCR
- Handles scrolling if character not visible
- Verifies character name in confirmation dialog before confirming

**Error Handling**:
- If character not found after max attempts, closes emulator and returns `false`
- Navigation failures trigger retry logic (max 3 attempts)
- Character name verification prevents incorrect switches

### Usage Examples

#### In InitializeTask

```java
@Override
protected void execute() {
    ensureEmulatorRunning();
    ensureGameInstalled();
    ensureGameRunning();
    
    if (!waitForHomeScreen()) {
        return;
    }
    
    // Verify and switch character if needed
    if (!verifyAndSwitchCharacter()) {
        return; // Character switching failed
    }
    
    handleInitializationSuccess();
}

private boolean verifyAndSwitchCharacter() {
    // Check if character configuration is set
    String characterName = profile.getCharacterName();
    String characterId = profile.getCharacterId();
    
    // Skip if not configured
    if ((characterName == null || characterName.isEmpty()) &&
        (characterId == null || characterId.isEmpty())) {
        return true;
    }
    
    // Verify current character
    boolean characterMatches = characterSwitchHelper.verifyCurrentCharacter(profile);
    
    if (!characterMatches) {
        // Switch to correct character
        boolean switchSuccess = characterSwitchHelper.switchToCharacter(profile);
        if (!switchSuccess) {
            // Character not found - emulator closed, continue to next profile
            return false;
        }
        
        // Wait for game reload and re-check home screen
        sleepTask(CharacterSwitchHelper.CHARACTER_SWITCH_RELOAD_DELAY_MS);
        if (!waitForHomeScreen()) {
            return false;
        }
    }
    
    return true;
}
```

### Character Configuration

Character information is stored as direct database columns (not configuration keys):

```java
// Get character configuration
String characterName = profile.getCharacterName();
String characterId = profile.getCharacterId();
String characterServer = profile.getCharacterServer();
String allianceCode = profile.getCharacterAllianceCode();

// Set character configuration
profile.setCharacterName("John Doe");
profile.setCharacterId("123456789");
profile.setCharacterServer("1830");
profile.setAllianceCode("BOT"); // 3-character code, auto-uppercased
```

### OCR Regions

Character information is read from specific OCR regions defined in `CommonGameAreas`:

- **Character ID**: `CHARACTER_ID_OCR_AREA` - Profile menu, numbers only
- **Character Name**: `CHARACTER_NAME_OCR_AREA` - Profile menu, alphanumeric + special chars
- **Character Name (List)**: Calculated relative to Furnace Level template position
- **Confirmation Dialog**: `PROFILE_SETTINGS_SWITCH_CHARACTER_CONFIRM_DIALOG_NAME_OCR_AREA`

### Templates

The following templates are used for character switching:

- `GAME_PROFILE_SETTINGS_BUTTON` - Settings button in profile menu
- `GAME_PROFILE_SETTINGS_SWITCH_CHARACTER_BUTTON` - Switch Character button in settings menu
- `GAME_PROFILE_SETTINGS_CHARACTER_FURNACE_LEVEL_ACTIVE` - Active character furnace level icon
- `GAME_PROFILE_SETTINGS_CHARACTER_FURNACE_LEVEL_INACTIVE` - Inactive character furnace level icon
- `GAME_PROFILE_SETTINGS_CHARACTER_ACTIVE_CHECKMARK` - Green checkmark for active character
- `GAME_PROFILE_SETTINGS_SWITCH_CHARACTER_CONFIRM_BUTTON` - Confirm button in dialog
- `GAME_PROFILE_SETTINGS_SWITCH_CHARACTER_CANCEL_BUTTON` - Cancel button in dialog

### Backward Compatibility

- Profiles without character configuration continue to work normally
- Character verification is skipped if `characterName` and `characterId` are both empty/null
- No breaking changes to existing functionality

### Performance

- Character verification: < 5 seconds (when character matches)
- Character switching: < 30 seconds (target)
- Uses template caching and OCR retry logic for reliability

---

**Next**: Return to [README.md](./README.md) for documentation index.

