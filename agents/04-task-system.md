# Task System Deep Dive

This document provides comprehensive information about the task system, including how to create new tasks and understand task execution.

## Task Architecture

### Task Hierarchy

```
DelayedTask (Abstract Base Class)
├── ArenaTask
├── GatherTask
├── TrainingTask
├── AllianceTechTask
├── CrystalLaboratoryTask
└── [40+ other task implementations]
```

### Task Registration

Tasks are registered in `DelayedTaskRegistry`:

```java
static {
    registry.put(
        TpDailyTaskEnum.ARENA, 
        profile -> new ArenaTask(profile, TpDailyTaskEnum.ARENA)
    );
    registry.put(
        TpDailyTaskEnum.GATHER_RESOURCES, 
        profile -> new GatherTask(profile, TpDailyTaskEnum.GATHER_RESOURCES)
    );
    // ... more registrations
}
```

### Task Creation

Tasks are created via factory pattern:

```java
DelayedTask task = DelayedTaskRegistry.create(
    TpDailyTaskEnum.ARENA, 
    profile
);
```

## Task Lifecycle

### 1. Task Initialization

```java
public MyTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
    super(profile, tpTask);  // Calls DelayedTask constructor
    
    // Constructor initializes:
    // - Profile reference
    // - Emulator number
    // - Helper classes (NavigationHelper, StaminaHelper, etc.)
    // - OCR providers
    // - Logger
}
```

### 2. Task Scheduling

```java
// Task scheduled with initial time
task.scheduledTime = LocalDateTime.now();

// Task added to queue
taskQueue.offer(task);

// Task implements Delayed interface
long delay = task.getDelay(TimeUnit.SECONDS);
```

### 3. Task Execution

```java
// TaskQueue calls run()
task.run() {
    // 1. Refresh profile
    refreshProfileFromDatabase();
    
    // 2. Verify game state
    if (!emuManager.isRunning(EMULATOR_NUMBER)) {
        reschedule(LocalDateTime.now().plusMinutes(5));
        return;
    }
    
    // 3. Verify screen location
    navigationHelper.ensureLocation(getRequiredStartLocation());
    
    // 4. Validate prerequisites (e.g., stamina)
    if (consumesStamina() && !staminaHelper.hasEnoughStamina()) {
        reschedule(LocalDateTime.now().plusHours(1));
        return;
    }
    
    // 5. Execute task logic
    execute();  // Implemented by subclass
    
    // 6. Save profile if config changed
    if (shouldUpdateConfig) {
        ServProfiles.getServices().saveProfile(profile);
    }
    
    // 7. Return to home if needed
    if (getRequiredStartLocation() == EnumStartLocation.HOME) {
        navigationHelper.goHome();
    }
}
```

### 4. Task Rescheduling

```java
// Reschedule for specific time
reschedule(LocalDateTime.now().plusHours(2));

// Reschedule for next day at specific time
LocalDateTime next = LocalDateTime.now()
    .withHour(23)
    .withMinute(50)
    .plusDays(1);
reschedule(next);

// Reschedule based on condition
if (condition) {
    reschedule(LocalDateTime.now().plusMinutes(30));
} else {
    reschedule(LocalDateTime.now().plusHours(2));
}
```

## Creating a New Task

### Step 1: Create Task Class

```java
package cl.camodev.wosbot.serv.task.impl;

import cl.camodev.wosbot.console.enumerable.TpDailyTaskEnum;
import cl.camodev.wosbot.ot.DTOProfiles;
import cl.camodev.wosbot.serv.task.DelayedTask;

public class MyNewTask extends DelayedTask {
    
    public MyNewTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
        super(profile, tpTask);
    }
    
    @Override
    protected void execute() {
        logInfo("Starting MyNewTask");
        
        // Task-specific logic here
        
        // Example: Navigate to screen
        navigationHelper.navigateTo("TargetScreen");
        
        // Example: Read text with OCR
        String text = stringHelper.ocrRegion(
            new DTOPoint(100, 200),
            new DTOPoint(300, 250),
            CommonOCRSettings.SINGLE_LINE
        );
        
        // Example: Tap button
        emuManager.getEmulator(emulatorType, consolePath)
            .tap(EMULATOR_NUMBER, 500, 600);
        
        // Reschedule task
        reschedule(LocalDateTime.now().plusHours(1));
        
        logInfo("MyNewTask completed");
    }
    
    @Override
    protected EnumStartLocation getRequiredStartLocation() {
        return EnumStartLocation.HOME;  // or WORLD, or ANY
    }
    
    @Override
    protected boolean consumesStamina() {
        return true;  // or false
    }
}
```

### Step 2: Add Task Enum

Add to `TpDailyTaskEnum`:

```java
MY_NEW_TASK(999, "My New Task", EnumConfigurationKey.MY_NEW_TASK_BOOL),
```

### Step 3: Add Configuration Key

Add to `EnumConfigurationKey`:

```java
MY_NEW_TASK_BOOL("false", Boolean.class),
MY_NEW_TASK_INTERVAL_INT("60", Integer.class),
```

### Step 4: Register Task

Add to `DelayedTaskRegistry`:

```java
registry.put(
    TpDailyTaskEnum.MY_NEW_TASK, 
    profile -> new MyNewTask(profile, TpDailyTaskEnum.MY_NEW_TASK)
);
```

### Step 5: Add UI (Optional)

Add configuration UI in `wos-hmi` module if needed.

## Task Helper Methods

### Navigation

```java
// Navigate to specific screen
navigationHelper.navigateTo("ScreenName");

// Go to home (city view)
navigationHelper.goHome();

// Go to world map
navigationHelper.goToWorld();

// Ensure current location
navigationHelper.ensureLocation(EnumStartLocation.HOME);
```

### OCR Operations

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
String text = stringHelper.ocrRegion(
    point1, point2, settings
);
```

### Stamina Management

```java
// Check if enough stamina
if (staminaHelper.hasEnoughStamina()) {
    // Proceed
}

// Get current stamina
Integer stamina = staminaHelper.getCurrentStamina();

// Wait for stamina
staminaHelper.waitForStamina(requiredAmount);
```

### March Management

```java
// Get active marches
List<MarchInfo> marches = marchHelper.getActiveMarches();

// Recall march
marchHelper.recallMarch(marchId);

// Check march queue
int queueSize = marchHelper.getMarchQueueSize();
```

### Template Matching

```java
// Search for template on screen
DTOImageSearchResult result = templateSearchHelper.searchTemplate(
    "templateName.png",
    confidenceThreshold
);

if (result.isFound()) {
    // Tap at found location
    emulator.tap(EMULATOR_NUMBER, result.getX(), result.getY());
}
```

## Task Examples

### Example 1: Simple Task

```java
public class SimpleRewardTask extends DelayedTask {
    
    public SimpleRewardTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
        super(profile, tpTask);
    }
    
    @Override
    protected void execute() {
        logInfo("Claiming daily reward");
        
        // Navigate to rewards screen
        navigationHelper.navigateTo("DailyRewards");
        
        // Tap claim button
        emuManager.getEmulator(emulatorType, consolePath)
            .tap(EMULATOR_NUMBER, 500, 600);
        
        // Wait for animation
        Thread.sleep(2000);
        
        // Return home
        navigationHelper.goHome();
        
        // Reschedule for next day
        LocalDateTime next = LocalDateTime.now()
            .withHour(0)
            .withMinute(0)
            .plusDays(1);
        reschedule(next);
        
        logInfo("Reward claimed, rescheduled for tomorrow");
    }
    
    @Override
    protected EnumStartLocation getRequiredStartLocation() {
        return EnumStartLocation.HOME;
    }
}
```

### Example 2: Task with Configuration

```java
public class ConfigurableTask extends DelayedTask {
    
    private int intervalMinutes;
    
    public ConfigurableTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
        super(profile, tpTask);
    }
    
    @Override
    protected void execute() {
        // Load configuration
        intervalMinutes = profile.getConfig(
            EnumConfigurationKey.MY_TASK_INTERVAL_INT,
            Integer.class
        );
        
        Boolean enabled = profile.getConfig(
            EnumConfigurationKey.MY_TASK_BOOL,
            Boolean.class
        );
        
        if (!enabled) {
            logInfo("Task disabled, skipping");
            reschedule(LocalDateTime.now().plusHours(24));
            return;
        }
        
        logInfo("Executing task with interval: {} minutes", intervalMinutes);
        
        // Task logic here
        
        // Reschedule based on configuration
        reschedule(LocalDateTime.now().plusMinutes(intervalMinutes));
    }
}
```

### Example 3: Task with Stamina Check

```java
public class StaminaTask extends DelayedTask {
    
    public StaminaTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
        super(profile, tpTask);
    }
    
    @Override
    protected void execute() {
        int requiredStamina = 20;
        
        // Check stamina (handled in run(), but can check again)
        if (!staminaHelper.hasEnoughStamina(requiredStamina)) {
            logInfo("Not enough stamina, waiting");
            reschedule(LocalDateTime.now().plusHours(1));
            return;
        }
        
        logInfo("Executing stamina-consuming task");
        
        // Task logic that consumes stamina
        
        // Reschedule
        reschedule(LocalDateTime.now().plusHours(2));
    }
    
    @Override
    protected boolean consumesStamina() {
        return true;  // Enables stamina check in run()
    }
}
```

### Example 4: Task with OCR

```java
public class OCRTask extends DelayedTask {
    
    public OCRTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
        super(profile, tpTask);
    }
    
    @Override
    protected void execute() {
        logInfo("Reading game state with OCR");
        
        // Define OCR region
        DTOPoint topLeft = new DTOPoint(100, 200);
        DTOPoint bottomRight = new DTOPoint(300, 250);
        
        // Read integer value
        Integer value = integerHelper.ocrRegion(
            topLeft,
            bottomRight,
            CommonOCRSettings.SINGLE_LINE,
            NumberConverters::toInteger,
            NumberValidators::isValidInteger
        );
        
        if (value == null) {
            logWarning("Failed to read value, retrying later");
            reschedule(LocalDateTime.now().plusMinutes(5));
            return;
        }
        
        logInfo("Read value: {}", value);
        
        // Use value in task logic
        if (value > 100) {
            // Perform action
        }
        
        reschedule(LocalDateTime.now().plusHours(1));
    }
}
```

## Task Best Practices

### 1. Error Handling

```java
@Override
protected void execute() {
    try {
        // Task logic
    } catch (Exception e) {
        logError("Task failed: {}", e.getMessage(), e);
        // Reschedule with delay
        reschedule(LocalDateTime.now().plusMinutes(10));
    }
}
```

### 2. Logging

```java
// Use appropriate log levels
logInfo("Task started");           // Important events
logDebug("OCR result: {}", text);  // Detailed info
logWarning("Low stamina");         // Warnings
logError("Task failed", exception); // Errors
```

### 3. Rescheduling

```java
// Always reschedule, even on failure
try {
    // Task logic
    reschedule(LocalDateTime.now().plusHours(1));
} catch (Exception e) {
    // Reschedule with shorter delay on failure
    reschedule(LocalDateTime.now().plusMinutes(10));
}
```

### 4. Configuration

```java
// Load configuration at start of execute()
Boolean enabled = profile.getConfig(
    EnumConfigurationKey.MY_TASK_BOOL,
    Boolean.class
);

// Update configuration if needed
profile.setConfig(
    EnumConfigurationKey.MY_TASK_LAST_RUN_STRING,
    LocalDateTime.now().toString()
);
shouldUpdateConfig = true;  // Flag to save profile
```

### 5. Screen Location

```java
// Always specify required start location
@Override
protected EnumStartLocation getRequiredStartLocation() {
    return EnumStartLocation.HOME;  // or WORLD, or ANY
}

// Ensure location in execute() if needed
navigationHelper.ensureLocation(EnumStartLocation.HOME);
```

### 6. Stamina Management

```java
// Mark task as stamina-consuming
@Override
protected boolean consumesStamina() {
    return true;
}

// Check stamina in execute() if needed
if (!staminaHelper.hasEnoughStamina(requiredAmount)) {
    reschedule(LocalDateTime.now().plusHours(1));
    return;
}
```

## Task Queue Management

### Adding Tasks

```java
TaskQueue queue = queueManager.getQueue(profileId);

// Create task
DelayedTask task = DelayedTaskRegistry.create(
    TpDailyTaskEnum.MY_TASK,
    profile
);

// Schedule task
task.reschedule(LocalDateTime.now().plusHours(1));

// Add to queue
queue.addTask(task);
```

### Task Priority

Tasks are ordered by scheduled time. To prioritize:

```java
// Schedule earlier
task.reschedule(LocalDateTime.now().plusMinutes(5));

// Or use priority in task comparison (if implemented)
```

### Task State

```java
// Get task state
DTOTaskState state = ServTaskManager.getInstance()
    .getTaskState(profileId, taskId);

// Check next execution time
LocalDateTime nextExecution = state.getNextExecutionTime();

// Check last execution time
LocalDateTime lastExecution = state.getLastExecutionTime();
```

## Common Task Patterns

### Daily Task Pattern

```java
// Reschedule for next day at specific time
LocalDateTime next = LocalDateTime.now()
    .withHour(0)
    .withMinute(0)
    .plusDays(1);
reschedule(next);
```

### Hourly Task Pattern

```java
// Reschedule for next hour
LocalDateTime next = LocalDateTime.now()
    .plusHours(1)
    .withMinute(0)
    .withSecond(0);
reschedule(next);
```

### Conditional Rescheduling

```java
if (condition) {
    reschedule(LocalDateTime.now().plusMinutes(5));
} else {
    reschedule(LocalDateTime.now().plusHours(2));
}
```

### Time-Based Activation

```java
String activationTime = profile.getConfig(
    EnumConfigurationKey.MY_TASK_TIME_STRING,
    String.class
);

LocalDateTime next = parseTime(activationTime);
if (next.isBefore(LocalDateTime.now())) {
    next = next.plusDays(1);
}
reschedule(next);
```

---

**Next**: See [05-development-guide.md](./05-development-guide.md) for step-by-step development instructions.

