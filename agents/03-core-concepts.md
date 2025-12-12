# Core Concepts

This document explains the fundamental concepts that drive the WoS Bot architecture.

## Profiles

### Overview
A **Profile** represents a single game account and its configuration. Multiple profiles can run simultaneously, each with its own emulator and task queue.

### Profile Structure

```java
DTOProfiles {
    Long id;                    // Unique identifier
    String name;                // Display name
    String emulatorNumber;      // Associated emulator (e.g., "0", "1")
    Boolean enabled;            // Whether profile is active
    Long priority;              // Execution priority (higher = first)
    Long reconnectionTime;     // Delay before reconnection attempts
    List<DTOConfig> configs;    // Profile-specific configurations
}
```

### Profile Lifecycle

1. **Creation**: User creates profile via GUI
2. **Configuration**: User sets up task configurations
3. **Activation**: Profile enabled, scheduler creates task queue
4. **Execution**: Tasks run according to schedule
5. **Deactivation**: Profile disabled, tasks stop

### Profile Configuration

Each profile has a set of configurations stored as key-value pairs:

```java
// Access configuration
Boolean arenaEnabled = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_BOOL, 
    Boolean.class
);

// Set configuration
profile.setConfig(
    EnumConfigurationKey.ARENA_TASK_BOOL, 
    true
);
```

### Profile Priority

Profiles are executed in priority order:
- Higher priority profiles get emulator slots first
- Lower priority profiles wait for available slots
- Default priority: 50

### Multi-Profile Support

- Each profile runs in its own thread
- Profiles share emulator pool (limited by `MAX_RUNNING_EMULATORS_INT`)
- Profiles are independent (different configs, different schedules)

---

## Tasks

### Overview
A **Task** is an automation unit that performs a specific game action. Tasks are scheduled, queued, and executed automatically.

### Task Types

Tasks are defined in `TpDailyTaskEnum`:

```java
ARENA(15, "Arena", EnumConfigurationKey.ARENA_TASK_BOOL)
GATHER_RESOURCES(102, "Gather Resources", EnumConfigurationKey.GATHER_TASK_BOOL)
TRAINING_TROOPS(60, "Training", EnumConfigurationKey.TRAIN_BOOL)
// ... 40+ task types
```

### Task Lifecycle

```
1. Registration
   └── Task type registered in DelayedTaskRegistry

2. Scheduling
   └── ServScheduler creates task instance
   └── Task added to TaskQueue

3. Waiting
   └── Task waits until scheduled time
   └── Delay calculated based on schedule

4. Execution
   └── TaskQueue calls task.run()
   └── Task refreshes profile
   └── Task verifies game state
   └── Task.execute() performs action

5. Completion/Rescheduling
   └── Task completes or reschedules itself
   └── Next execution time calculated
```

### Task Base Class: DelayedTask

All tasks extend `DelayedTask`:

```java
public abstract class DelayedTask implements Runnable, Delayed {
    protected DTOProfiles profile;
    protected String EMULATOR_NUMBER;
    protected TpDailyTaskEnum tpTask;
    protected LocalDateTime scheduledTime;
    
    // Helper instances (initialized in constructor)
    protected NavigationHelper navigationHelper;
    protected StaminaHelper staminaHelper;
    protected MarchHelper marchHelper;
    // ... more helpers
    
    // Abstract method to implement
    protected abstract void execute();
}
```

### Task Execution Flow

```java
@Override
public void run() {
    // 1. Refresh profile from database
    refreshProfileFromDatabase();
    
    // 2. Verify game is running
    if (!emuManager.isRunning(EMULATOR_NUMBER)) {
        reschedule(LocalDateTime.now().plusMinutes(5));
        return;
    }
    
    // 3. Verify screen location
    EnumStartLocation required = getRequiredStartLocation();
    if (required != EnumStartLocation.ANY) {
        navigationHelper.ensureLocation(required);
    }
    
    // 4. Validate stamina (if needed)
    if (consumesStamina()) {
        if (!staminaHelper.hasEnoughStamina()) {
            reschedule(LocalDateTime.now().plusHours(1));
            return;
        }
    }
    
    // 5. Execute task-specific logic
    execute();
    
    // 6. Save profile if config changed
    if (shouldUpdateConfig) {
        ServProfiles.getServices().saveProfile(profile);
    }
    
    // 7. Return to home (if needed)
    if (getRequiredStartLocation() == EnumStartLocation.HOME) {
        navigationHelper.goHome();
    }
}
```

### Task Scheduling

Tasks schedule themselves:

```java
// Reschedule for specific time
reschedule(LocalDateTime.now().plusHours(2));

// Reschedule with delay
reschedule(LocalDateTime.now().plusMinutes(30));

// Reschedule for next day at specific time
LocalDateTime next = LocalDateTime.now()
    .withHour(23)
    .withMinute(50)
    .plusDays(1);
reschedule(next);
```

### Task Configuration

Tasks read configuration from profile:

```java
// Boolean configuration
Boolean enabled = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_BOOL, 
    Boolean.class
);

// Integer configuration
Integer attempts = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_EXTRA_ATTEMPTS_INT, 
    Integer.class
);

// String configuration
String time = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_ACTIVATION_TIME_STRING, 
    String.class
);
```

### Task Helpers

Tasks have access to helper classes:

- **NavigationHelper**: Navigate between screens
- **StaminaHelper**: Check/manage stamina
- **MarchHelper**: Manage troop marches
- **TemplateSearchHelper**: Find UI elements
- **IntelScreenHelper**: Intel operations
- **AllianceHelper**: Alliance operations
- **EventHelper**: Event operations

---

## Emulators

### Overview
**Emulators** are Android emulator instances controlled via ADB (Android Debug Bridge). The bot supports MuMu Player, MEmu, and LDPlayer 9.

### Emulator Management

#### EmulatorManager
Singleton that manages all emulator instances:

```java
EmulatorManager emuManager = EmulatorManager.getInstance();

// Get emulator instance
Emulator emulator = emuManager.getEmulator(emulatorType, consolePath);

// Check if running
boolean running = emuManager.isRunning(emulatorNumber);

// Launch emulator
emuManager.launchEmulator(emulatorType, emulatorNumber);

// Close emulator
emuManager.closeEmulator(emulatorType, emulatorNumber);
```

### Emulator Operations

#### Screenshot Capture
```java
DTORawImage screenshot = emulator.captureScreenshot(emulatorNumber);
// Returns raw image data with width, height, pixel data
```

#### Touch Simulation
```java
// Tap at specific point
emulator.tap(emulatorNumber, x, y);

// Tap in area (random point within bounds)
emulator.tapArea(emulatorNumber, point1, point2, tapCount, delayMs);
```

#### Swipe Simulation
```java
emulator.swipe(emulatorNumber, startX, startY, endX, endY, durationMs);
```

#### Package Detection
```java
// Check if app is installed
boolean installed = emulator.isAppInstalled(emulatorNumber, packageName);

// Check if app is running
boolean running = emulator.isPackageRunning(emulatorNumber, packageName);
```

### Emulator Types

#### MuMuEmulator
- **Console**: `MuMuManager.exe`
- **Default Path**: `C:\Program Files\Netease\MuMuPlayerGlobal-12.0\shell\`
- **Serial Format**: `127.0.0.1:7555` (for instance 0)

#### MEmuEmulator
- **Console**: `memuc.exe`
- **Default Path**: `C:\Program Files\Microvirt\MEmu\`
- **Serial Format**: `127.0.0.1:21503` (for instance 0)

#### LDPlayerEmulator
- **Console**: `ldconsole.exe`
- **Default Path**: `C:\LDPlayer\LDPlayer9\`
- **Serial Format**: `127.0.0.1:5555` (for instance 0)
- **Note**: Requires ADB debugging enabled in settings

### Emulator Caching

The bot caches emulator state for performance:

- **Device Cache**: ADB device instances cached (30s TTL)
- **Running Status Cache**: Running status cached (5s TTL)
- **Screenshot Cache**: Last screenshot cached per emulator

### Emulator Retry Logic

ADB operations have automatic retry:

1. **Initial Attempts**: Up to `MAX_RETRIES` attempts
2. **ADB Restart**: If failures persist, ADB restarted
3. **Emulator Restart**: Last resort, emulator restarted
4. **Exception**: If all retries fail, exception thrown

---

## OCR (Optical Character Recognition)

### Overview
**OCR** is used to read text from game screenshots. The bot uses Tesseract OCR via Tess4j.

### OCR Provider

```java
TextRecognitionProvider provider = new BotTextRecognitionProvider(
    emuManager, 
    emulatorNumber
);

// Read text from region
String text = provider.ocrRegion(point1, point2, settings);
```

### OCR Settings

```java
DTOTesseractSettings settings = new DTOTesseractSettings();
settings.setPageSegMode(7);  // Single line
settings.setOcrEngineMode(3); // Default
settings.setLanguage("eng");   // English

// Common settings available in CommonOCRSettings
DTOTesseractSettings commonSettings = CommonOCRSettings.SINGLE_LINE;
```

### OCR Retry Logic

OCR operations use retry wrapper:

```java
TextRecognitionRetrier<Integer> integerHelper = 
    new TextRecognitionRetrier<>(provider);

// Read integer with retry
Integer value = integerHelper.ocrRegion(
    point1, 
    point2, 
    CommonOCRSettings.SINGLE_LINE,
    NumberConverters::toInteger,
    NumberValidators::isValidInteger
);
```

### OCR Regions

Regions are defined by two points:

```java
DTOPoint topLeft = new DTOPoint(100, 200);
DTOPoint bottomRight = new DTOPoint(300, 250);

// Read text from this region
String text = provider.ocrRegion(topLeft, bottomRight, settings);
```

### OCR Best Practices

1. **Use appropriate settings**: Single line vs. multi-line
2. **Define precise regions**: Smaller regions = better accuracy
3. **Use retry logic**: OCR can be unreliable
4. **Preprocess images**: Clean images improve accuracy
5. **Cache screenshots**: Avoid repeated captures

---

## Scheduling System

### Overview
The **Scheduling System** manages when tasks execute. It uses a priority queue with delay-based execution.

### TaskQueue

Each profile has its own `TaskQueue`:

```java
TaskQueue queue = queueManager.getQueue(profileId);

// Add task
queue.addTask(task);

// Get next task
DelayedTask next = queue.peek();

// Execute task
queue.poll(); // Remove from queue
task.run();   // Execute
```

### Task Priority

Tasks are ordered by:
1. **Scheduled time** (earliest first)
2. **Task priority** (if same time)

### Delay Calculation

Tasks implement `Delayed` interface:

```java
@Override
public long getDelay(TimeUnit unit) {
    Duration delay = Duration.between(
        LocalDateTime.now(), 
        scheduledTime
    );
    return unit.convert(delay.toMillis(), TimeUnit.MILLISECONDS);
}
```

### Task Queue Loop

```java
while (running) {
    DelayedTask task = queue.peek();
    
    if (task != null && task.getDelay(TimeUnit.SECONDS) <= 0) {
        queue.poll();
        executeTask(task);
    } else {
        // Wait until next task is ready
        Thread.sleep(1000);
    }
}
```

### Task State Persistence

Task states are saved to database:

```java
DTOTaskState state = new DTOTaskState();
state.setTaskId(task.getTpTask().getId());
state.setProfileId(profile.getId());
state.setNextExecutionTime(task.getScheduled());
state.setLastExecutionTime(LocalDateTime.now());
// Save to database
```

---

## Configuration System

### Overview
The **Configuration System** stores key-value pairs per profile (or globally).

### Configuration Keys

All keys defined in `EnumConfigurationKey`:

```java
ARENA_TASK_BOOL("false", Boolean.class)
ARENA_TASK_EXTRA_ATTEMPTS_INT("0", Integer.class)
ARENA_TASK_ACTIVATION_TIME_STRING("23:50", String.class)
```

### Configuration Access

```java
// Get configuration
Boolean value = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_BOOL, 
    Boolean.class
);

// Set configuration
profile.setConfig(
    EnumConfigurationKey.ARENA_TASK_BOOL, 
    true
);

// Save profile (persists configs)
ServProfiles.getServices().saveProfile(profile);
```

### Configuration Types

Supported types:
- **Boolean**: `Boolean.class`
- **Integer**: `Integer.class`
- **Long**: `Long.class`
- **String**: `String.class`
- **LocalDateTime**: `LocalDateTime.class`

### Global vs Profile Configurations

- **Profile Configurations**: Stored with `profile_id`
- **Global Configurations**: Stored with `profile_id = NULL`

### Configuration Defaults

Each key has a default value:

```java
ARENA_TASK_BOOL("false", Boolean.class)  // Default: false
ARENA_TASK_EXTRA_ATTEMPTS_INT("0", Integer.class)  // Default: 0
```

---

## Logging System

### Overview
The **Logging System** provides structured logging with profile-specific log files.

### Log Levels

- **ERROR**: Critical failures
- **WARN**: Recoverable issues
- **INFO**: Important operations
- **DEBUG**: Detailed information

### Profile Logger

```java
ProfileLogger logger = new ProfileLogger(MyTask.class, profile);

logger.info("Task started");
logger.warn("Low stamina detected");
logger.error("Failed to execute", exception);
logger.debug("OCR result: {}", text);
```

### Log Files

- **Main Log**: `target/log/bot.log`
- **Profile Logs**: `target/log/profile_{profileId}.log`

### Log Format

```
[2024-01-15 10:30:45] [INFO] Profile1 - Task started
[2024-01-15 10:30:46] [DEBUG] Profile1 - OCR result: 1234
[2024-01-15 10:30:47] [WARN] Profile1 - Low stamina detected
```

### Centralized Logging

```java
ServLogs servLogs = ServLogs.getServices();

servLogs.appendLog(
    EnumTpMessageSeverity.INFO,
    "TaskName",
    "ProfileName",
    "Message"
);
```

---

**Next**: See [04-task-system.md](./04-task-system.md) for detailed task system documentation.

