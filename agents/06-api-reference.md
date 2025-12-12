# API Reference

This document provides reference documentation for key APIs and services in the WoS Bot project.

## Service APIs

### ServScheduler

**Purpose**: Main scheduler coordinating task execution

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/impl/ServScheduler.java`

**Singleton Access**:
```java
ServScheduler scheduler = ServScheduler.getServices();
```

**Key Methods**:

```java
// Get queue manager
TaskQueueManager queueManager = scheduler.getQueueManager();

// Start scheduler (called on application start)
scheduler.startScheduler(profiles, globalSettings);
```

---

### ServProfiles

**Purpose**: Profile management service

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/impl/ServProfiles.java`

**Singleton Access**:
```java
ServProfiles profiles = ServProfiles.getServices();
```

**Key Methods**:

```java
// Get all profiles
List<DTOProfiles> profiles = profiles.getProfiles();

// Get profile by ID
DTOProfiles profile = profiles.getProfileById(id);

// Add new profile
boolean success = profiles.addProfile(profileDTO);

// Save profile
boolean success = profiles.saveProfile(profileDTO);

// Delete profile
boolean success = profiles.deleteProfile(profileDTO);

// Get global settings
HashMap<EnumConfigurationKey, String> settings = profiles.getGlobalSettings();
```

---

### ServLogs

**Purpose**: Centralized logging service

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/impl/ServLogs.java`

**Singleton Access**:
```java
ServLogs logs = ServLogs.getServices();
```

**Key Methods**:

```java
// Append log message
logs.appendLog(
    EnumTpMessageSeverity.INFO,
    "TaskName",
    "ProfileName",
    "Message"
);

// Get log messages
List<DTOLogMessage> messages = logs.getLogs();
```

---

### EmulatorManager

**Purpose**: Emulator instance management

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Singleton Access**:
```java
EmulatorManager emuManager = EmulatorManager.getInstance();
```

**Key Methods**:

```java
// Get emulator instance
Emulator emulator = emuManager.getEmulator(emulatorType, consolePath);

// Check if emulator is running
boolean running = emuManager.isRunning(emulatorNumber);

// Launch emulator
emuManager.launchEmulator(emulatorType, emulatorNumber);

// Close emulator
emuManager.closeEmulator(emulatorType, emulatorNumber);

// Acquire emulator slot (for concurrent execution)
boolean acquired = emuManager.acquireEmulatorSlot(emulatorNumber);

// Release emulator slot
emuManager.releaseEmulatorSlot(emulatorNumber);
```

---

## Emulator API

### Emulator (Abstract Base Class)

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/Emulator.java`

**Key Methods**:

```java
// Screenshot capture
DTORawImage screenshot = emulator.captureScreenshot(emulatorNumber);

// Touch simulation
emulator.tap(emulatorNumber, x, y);
emulator.tapArea(emulatorNumber, point1, point2, tapCount, delayMs);

// Swipe simulation
emulator.swipe(emulatorNumber, startX, startY, endX, endY, durationMs);

// Package detection
boolean installed = emulator.isAppInstalled(emulatorNumber, packageName);
boolean running = emulator.isPackageRunning(emulatorNumber, packageName);

// Launch/Close
emulator.launchEmulator(emulatorNumber);
emulator.closeEmulator(emulatorNumber);
boolean running = emulator.isRunning(emulatorNumber);
```

**Return Types**:

- `DTORawImage`: Contains `pixelData`, `width`, `height`, `bpp`
- `boolean`: Success/failure for operations

---

## Task API

### DelayedTask (Abstract Base Class)

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/DelayedTask.java`

**Key Methods**:

```java
// Task execution (called by TaskQueue)
@Override
public void run() {
    // Implemented in base class, calls execute()
}

// Task-specific logic (implement in subclass)
@Override
protected abstract void execute();

// Reschedule task
public void reschedule(LocalDateTime newTime);

// Get delay until execution
public long getDelay(TimeUnit unit);

// Configuration access
<T> T getConfig(EnumConfigurationKey key, Class<T> type);
void setConfig(EnumConfigurationKey key, Object value);

// Logging
void logInfo(String message);
void logWarning(String message);
void logError(String message);
void logError(String message, Throwable t);
void logDebug(String message);
```

**Helper Instances** (available in subclasses):

```java
protected NavigationHelper navigationHelper;
protected StaminaHelper staminaHelper;
protected MarchHelper marchHelper;
protected TemplateSearchHelper templateSearchHelper;
protected IntelScreenHelper intelScreenHelper;
protected AllianceHelper allianceHelper;
protected EventHelper eventHelper;
protected BotTextRecognitionProvider provider;
protected TextRecognitionRetrier<Integer> integerHelper;
protected TextRecognitionRetrier<Duration> durationHelper;
protected TextRecognitionRetrier<String> stringHelper;
```

---

## Helper APIs

### NavigationHelper

**Purpose**: Navigate between game screens

**Key Methods**:

```java
// Navigate to specific screen
void navigateTo(String screenName);

// Go to home (city view)
void goHome();

// Go to world map
void goToWorld();

// Ensure current location
void ensureLocation(EnumStartLocation location);

// Get current location
EnumStartLocation getCurrentLocation();
```

---

### StaminaHelper

**Purpose**: Stamina management

**Key Methods**:

```java
// Check if enough stamina
boolean hasEnoughStamina();
boolean hasEnoughStamina(int requiredAmount);

// Get current stamina
Integer getCurrentStamina();

// Wait for stamina
void waitForStamina(int requiredAmount);

// Consume stamina
void consumeStamina(int amount);
```

---

### MarchHelper

**Purpose**: Troop march management

**Key Methods**:

```java
// Get active marches
List<MarchInfo> getActiveMarches();

// Recall march
void recallMarch(String marchId);

// Get march queue size
int getMarchQueueSize();

// Check if march slot available
boolean isMarchSlotAvailable();
```

---

### TemplateSearchHelper

**Purpose**: Template matching for UI elements

**Key Methods**:

```java
// Search for template on screen
DTOImageSearchResult searchTemplate(
    String templateName,
    double confidenceThreshold
);

// Search in specific region
DTOImageSearchResult searchTemplateInRegion(
    String templateName,
    DTOPoint topLeft,
    DTOPoint bottomRight,
    double confidenceThreshold
);
```

**Return Type**:

```java
DTOImageSearchResult {
    boolean isFound();
    int getX();
    int getY();
    double getConfidence();
}
```

---

### IntelScreenHelper

**Purpose**: Intel screen operations

**Key Methods**:

```java
// Navigate to intel screen
void navigateToIntelScreen();

// Process intel
void processIntel();

// Check intel availability
boolean hasAvailableIntel();
```

---

### AllianceHelper

**Purpose**: Alliance operations

**Key Methods**:

```java
// Navigate to alliance screen
void navigateToAllianceScreen();

// Perform alliance operation
void performAllianceOperation(String operation);
```

---

### EventHelper

**Purpose**: Event operations

**Key Methods**:

```java
// Check if event is active
boolean isEventActive(String eventName);

// Navigate to event screen
void navigateToEvent(String eventName);
```

---

## OCR API

### TextRecognitionProvider

**Purpose**: OCR abstraction interface

**Location**: `wos-utiles/src/main/java/cl/camodev/utiles/ocr/TextRecognitionProvider.java`

**Key Methods**:

```java
// Perform OCR on region
String ocrRegion(
    DTOPoint p1,              // Top-left corner
    DTOPoint p2,              // Bottom-right corner
    DTOTesseractSettings settings  // OCR settings (can be null)
) throws IOException, TesseractException;
```

---

### TextRecognitionRetrier

**Purpose**: Retry logic wrapper for OCR

**Location**: `wos-utiles/src/main/java/cl/camodev/utiles/ocr/TextRecognitionRetrier.java`

**Key Methods**:

```java
// OCR with retry and type conversion
<T> T ocrRegion(
    DTOPoint p1,
    DTOPoint p2,
    DTOTesseractSettings settings,
    Function<String, T> converter,      // Convert string to type
    Predicate<T> validator               // Validate result
);
```

**Usage Examples**:

```java
// Read integer
Integer value = integerHelper.ocrRegion(
    point1, point2, settings,
    NumberConverters::toInteger,
    NumberValidators::isValidInteger
);

// Read duration
Duration duration = durationHelper.ocrRegion(
    point1, point2, settings,
    NumberConverters::toDuration,
    NumberValidators::isValidDuration
);

// Read string
String text = stringHelper.ocrRegion(point1, point2, settings);
```

---

## Repository APIs

### ProfileRepository

**Purpose**: Profile data access

**Location**: `wos-persitence/src/main/java/cl/camodev/wosbot/almac/repo/ProfileRepository.java`

**Singleton Access**:
```java
ProfileRepository repo = ProfileRepository.getRepository();
```

**Key Methods**:

```java
// Get all profiles with configs
List<DTOProfiles> profiles = repo.getProfiles();

// Get profile by ID with configs
DTOProfiles profile = repo.getProfileWithConfigsById(id);

// Get profile entity by ID
Profile profile = repo.getProfileById(id);

// Add profile
boolean success = repo.addProfile(profile);

// Save profile
boolean success = repo.saveProfile(profile);

// Delete profile
boolean success = repo.deleteProfile(profile);

// Get profile configs
List<Config> configs = repo.getProfileConfigs(profileId);
```

---

### ConfigRepository

**Purpose**: Configuration data access

**Location**: `wos-persitence/src/main/java/cl/camodev/wosbot/almac/repo/ConfigRepository.java`

**Singleton Access**:
```java
ConfigRepository repo = ConfigRepository.getRepository();
```

**Key Methods**:

```java
// Get profile configs
List<Config> configs = repo.getProfileConfigs(profileId);

// Get global configs
List<Config> configs = repo.getGlobalConfigs();

// Add config
boolean success = repo.addConfig(config);

// Save config
boolean success = repo.saveConfig(config);

// Delete config
boolean success = repo.deleteConfig(config);

// Get config by ID
Config config = repo.getConfigById(id);
```

---

## Task Queue API

### TaskQueue

**Purpose**: Priority-based task queue per profile

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/TaskQueue.java`

**Key Methods**:

```java
// Add task to queue
void addTask(DelayedTask task);

// Peek at next task (without removing)
DelayedTask task = queue.peek();

// Poll next task (remove from queue)
DelayedTask task = queue.poll();

// Check if queue is empty
boolean empty = queue.isEmpty();

// Get queue size
int size = queue.size();

// Start queue processing
void start();

// Stop queue processing
void stop();

// Pause queue
void pause();

// Resume queue
void resume();
```

---

### TaskQueueManager

**Purpose**: Manages multiple task queues (one per profile)

**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/TaskQueueManager.java`

**Key Methods**:

```java
// Create queue for profile
void createQueue(DTOProfiles profile);

// Get queue for profile
TaskQueue queue = queueManager.getQueue(profileId);

// Remove queue
void removeQueue(String profileId);

// Get all queues
Map<String, TaskQueue> queues = queueManager.getAllQueues();
```

---

## DTO APIs

### DTOProfiles

**Purpose**: Profile data structure

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOProfiles.java`

**Key Methods**:

```java
// Get configuration value
<T> T getConfig(EnumConfigurationKey key, Class<T> type);

// Set configuration value
void setConfig(EnumConfigurationKey key, Object value);

// Get all configs
List<DTOConfig> getConfigs();

// Set all configs
void setConfigs(List<DTOConfig> configs);
```

**Fields**:

```java
Long id;
String name;
String emulatorNumber;
Boolean enabled;
Long priority;
Long reconnectionTime;
List<DTOConfig> configs;
```

---

### DTOConfig

**Purpose**: Configuration key-value pair

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOConfig.java`

**Fields**:

```java
Long profileId;  // null for global configs
String key;
String value;
```

---

### DTOPoint

**Purpose**: Screen coordinates

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOPoint.java`

**Fields**:

```java
int x;
int y;
```

**Methods**:

```java
DTOPoint(int x, int y);
int getX();
int getY();
```

---

### DTORawImage

**Purpose**: Screenshot data

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTORawImage.java`

**Fields**:

```java
byte[] pixelData;
int width;
int height;
int bpp;  // Bits per pixel
```

---

## Enum APIs

### TpDailyTaskEnum

**Purpose**: Task type enumeration

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/TpDailyTaskEnum.java`

**Key Methods**:

```java
// Get task by ID
TpDailyTaskEnum task = TpDailyTaskEnum.fromId(id);

// Get task properties
int id = task.getId();
String name = task.getName();
EnumConfigurationKey configKey = task.getConfigKey();
```

---

### EnumConfigurationKey

**Purpose**: Configuration key enumeration

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/EnumConfigurationKey.java`

**Key Methods**:

```java
// Get default value
String defaultValue = key.getDefaultValue();

// Get value type
Class<?> type = key.getType();

// Cast string value to type
<T> T value = key.castValue("stringValue");
```

---

## Common Patterns

### Getting Service Instance

```java
// Singleton pattern
ServScheduler scheduler = ServScheduler.getServices();
ServProfiles profiles = ServProfiles.getServices();
ServLogs logs = ServLogs.getServices();
EmulatorManager emuManager = EmulatorManager.getInstance();
```

### Accessing Configuration

```java
// Get configuration
Boolean enabled = profile.getConfig(
    EnumConfigurationKey.MY_TASK_BOOL,
    Boolean.class
);

// Set configuration
profile.setConfig(
    EnumConfigurationKey.MY_TASK_BOOL,
    true
);
```

### Using Helpers

```java
// Navigation
navigationHelper.goHome();
navigationHelper.navigateTo("ScreenName");

// OCR
Integer value = integerHelper.ocrRegion(
    point1, point2, settings,
    NumberConverters::toInteger,
    NumberValidators::isValidInteger
);

// Stamina
if (staminaHelper.hasEnoughStamina(20)) {
    // Proceed
}
```

### Emulator Operations

```java
// Get emulator
Emulator emulator = emuManager.getEmulator(emulatorType, consolePath);

// Screenshot
DTORawImage screenshot = emulator.captureScreenshot(emulatorNumber);

// Tap
emulator.tap(emulatorNumber, x, y);

// Swipe
emulator.swipe(emulatorNumber, startX, startY, endX, endY, duration);
```

---

**Next**: See [07-data-model.md](./07-data-model.md) for data structure documentation.

