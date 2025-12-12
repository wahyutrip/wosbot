# Development Guide

This guide provides step-by-step instructions for common development tasks in the WoS Bot project.

## Table of Contents

1. [Setting Up Development Environment](#setting-up-development-environment)
2. [Adding a New Task](#adding-a-new-task)
3. [Adding Configuration Keys](#adding-configuration-keys)
4. [Adding a New Emulator Type](#adding-a-new-emulator-type)
5. [Creating Helper Classes](#creating-helper-classes)
6. [Adding UI Components](#adding-ui-components)
7. [Testing Tasks](#testing-tasks)
8. [Debugging](#debugging)

## Setting Up Development Environment

### Prerequisites

1. **Java Development Kit (JDK) 21**
   ```bash
   # Verify installation
   java -version
   ```

2. **Apache Maven**
   ```bash
   # Verify installation
   mvn -version
   ```

3. **IDE** (IntelliJ IDEA, Eclipse, or VS Code)

### Project Setup

1. **Clone/Open Project**
   ```bash
   cd /path/to/wosbot
   ```

2. **Build Project**
   ```bash
   mvn clean install
   ```

3. **Run Application**
   ```bash
   cd wos-hmi/target
   java -jar wos-bot-1.5.4.jar
   ```

### IDE Configuration

1. **Import as Maven Project**
2. **Set JDK 21** as project SDK
3. **Enable Annotation Processing** (for Hibernate)
4. **Configure Code Style** (follow existing patterns)

---

## Adding a New Task

### Step 1: Create Task Class

Create file: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/impl/MyNewTask.java`

```java
package cl.camodev.wosbot.serv.task.impl;

import cl.camodev.wosbot.console.enumerable.TpDailyTaskEnum;
import cl.camodev.wosbot.ot.DTOProfiles;
import cl.camodev.wosbot.serv.task.DelayedTask;
import cl.camodev.wosbot.serv.task.EnumStartLocation;

public class MyNewTask extends DelayedTask {
    
    public MyNewTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
        super(profile, tpTask);
    }
    
    @Override
    protected void execute() {
        logInfo("MyNewTask started");
        
        // Load configuration
        Boolean enabled = profile.getConfig(
            EnumConfigurationKey.MY_NEW_TASK_BOOL,
            Boolean.class
        );
        
        if (!enabled) {
            logInfo("Task disabled, skipping");
            reschedule(LocalDateTime.now().plusHours(24));
            return;
        }
        
        // Task logic here
        navigationHelper.navigateTo("TargetScreen");
        
        // Reschedule
        reschedule(LocalDateTime.now().plusHours(1));
        
        logInfo("MyNewTask completed");
    }
    
    @Override
    protected EnumStartLocation getRequiredStartLocation() {
        return EnumStartLocation.HOME;
    }
    
    @Override
    protected boolean consumesStamina() {
        return false;  // Set to true if task consumes stamina
    }
}
```

### Step 2: Add Task Enum

Edit: `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/TpDailyTaskEnum.java`

```java
MY_NEW_TASK(999, "My New Task", EnumConfigurationKey.MY_NEW_TASK_BOOL),
```

### Step 3: Add Configuration Keys

Edit: `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/EnumConfigurationKey.java`

```java
// In appropriate section
MY_NEW_TASK_BOOL("false", Boolean.class),
MY_NEW_TASK_INTERVAL_INT("60", Integer.class),
MY_NEW_TASK_TIME_STRING("12:00", String.class),
```

### Step 4: Register Task

Edit: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/DelayedTaskRegistry.java`

```java
static {
    // ... existing registrations
    
    registry.put(
        TpDailyTaskEnum.MY_NEW_TASK,
        profile -> new MyNewTask(profile, TpDailyTaskEnum.MY_NEW_TASK)
    );
}
```

### Step 5: Build and Test

```bash
mvn clean install
```

### Step 6: Add UI (Optional)

If you want configuration UI, add to `wos-hmi` module (see [Adding UI Components](#adding-ui-components)).

---

## Adding Configuration Keys

### Step 1: Add Enum Entry

Edit: `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/EnumConfigurationKey.java`

```java
// Find appropriate section or create new one
MY_FEATURE_ENABLED_BOOL("false", Boolean.class),
MY_FEATURE_INTERVAL_INT("60", Integer.class),
MY_FEATURE_TIME_STRING("12:00", String.class),
MY_FEATURE_COUNT_LONG("0", Long.class),
```

### Step 2: Use in Code

```java
// Get configuration
Boolean enabled = profile.getConfig(
    EnumConfigurationKey.MY_FEATURE_ENABLED_BOOL,
    Boolean.class
);

// Set configuration
profile.setConfig(
    EnumConfigurationKey.MY_FEATURE_ENABLED_BOOL,
    true
);

// Save profile (if config changed)
shouldUpdateConfig = true;
```

### Step 3: Add Default Value

The default value is set in the enum:

```java
MY_FEATURE_ENABLED_BOOL("false", Boolean.class)  // Default: false
MY_FEATURE_INTERVAL_INT("60", Integer.class)     // Default: 60
```

### Configuration Types

Supported types:
- `Boolean.class` - true/false
- `Integer.class` - Integer numbers
- `Long.class` - Long numbers
- `String.class` - Text strings
- `LocalDateTime.class` - Date/time

### Type Conversion

The `castValue()` method handles conversion:

```java
// Automatic conversion based on type
Boolean value = EnumConfigurationKey.MY_FEATURE_ENABLED_BOOL
    .castValue("true");  // Returns Boolean.TRUE
```

---

## Adding a New Emulator Type

### Step 1: Create Emulator Class

Create file: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/impl/MyEmulator.java`

```java
package cl.camodev.wosbot.emulator.impl;

import cl.camodev.wosbot.emulator.Emulator;

public class MyEmulator extends Emulator {
    
    public MyEmulator(String consolePath) {
        super(consolePath);
    }
    
    @Override
    protected String getDeviceSerial(String emulatorNumber) {
        // Return ADB serial for emulator instance
        // Format: "127.0.0.1:PORT"
        int port = 5555 + Integer.parseInt(emulatorNumber);
        return "127.0.0.1:" + port;
    }
    
    @Override
    public void launchEmulator(String emulatorNumber) {
        // Launch emulator using console executable
        ProcessBuilder pb = new ProcessBuilder(
            consolePath + "/myemulator.exe",
            "launch",
            emulatorNumber
        );
        pb.start();
    }
    
    @Override
    public void closeEmulator(String emulatorNumber) {
        // Close emulator
        ProcessBuilder pb = new ProcessBuilder(
            consolePath + "/myemulator.exe",
            "close",
            emulatorNumber
        );
        pb.start();
    }
    
    @Override
    public boolean isRunning(String emulatorNumber) {
        // Check if emulator is running
        try {
            ProcessBuilder pb = new ProcessBuilder(
                consolePath + "/myemulator.exe",
                "isRunning",
                emulatorNumber
            );
            Process process = pb.start();
            int exitCode = process.waitFor();
            return exitCode == 0;
        } catch (Exception e) {
            return false;
        }
    }
}
```

### Step 2: Add Emulator Type Enum

Edit: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

Add emulator type constant:

```java
public static final String EMULATOR_TYPE_MY = "MyEmulator";
```

### Step 3: Register in Factory

Edit: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

```java
private Emulator createEmulator(String emulatorType, String consolePath) {
    switch (emulatorType) {
        case EMULATOR_TYPE_MUMU:
            return new MuMuEmulator(consolePath);
        case EMULATOR_TYPE_MEMU:
            return new MEmuEmulator(consolePath);
        case EMULATOR_TYPE_LDPLAYER:
            return new LDPlayerEmulator(consolePath);
        case EMULATOR_TYPE_MY:
            return new MyEmulator(consolePath);
        default:
            throw new IllegalArgumentException("Unknown emulator type: " + emulatorType);
    }
}
```

### Step 4: Add Configuration Key

Add to `EnumConfigurationKey`:

```java
MY_EMULATOR_PATH_STRING("", String.class),
```

### Step 5: Update UI

Add emulator selection option in launcher UI if needed.

---

## Creating Helper Classes

### Step 1: Create Helper Class

Create file: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/MyHelper.java`

```java
package cl.camodev.wosbot.serv.task.helper;

import cl.camodev.wosbot.emulator.EmulatorManager;
import cl.camodev.wosbot.ot.DTOProfiles;

public class MyHelper {
    
    private final EmulatorManager emuManager;
    private final String emulatorNumber;
    private final DTOProfiles profile;
    
    public MyHelper(
            EmulatorManager emuManager,
            String emulatorNumber,
            DTOProfiles profile) {
        this.emuManager = emuManager;
        this.emulatorNumber = emulatorNumber;
        this.profile = profile;
    }
    
    public void doSomething() {
        // Helper logic here
    }
    
    public boolean checkSomething() {
        // Return check result
        return true;
    }
}
```

### Step 2: Initialize in DelayedTask

Edit: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/DelayedTask.java`

```java
protected MyHelper myHelper;

public DelayedTask(DTOProfiles profile, TpDailyTaskEnum tpTask) {
    // ... existing initialization
    
    this.myHelper = new MyHelper(
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
    myHelper.doSomething();
    
    if (myHelper.checkSomething()) {
        // Proceed
    }
}
```

---

## Adding UI Components

### Step 1: Create FXML Layout

Create file: `wos-hmi/src/main/resources/fxml/myfeature/MyFeatureLayout.fxml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?import javafx.scene.control.*?>
<?import javafx.scene.layout.*?>

<VBox xmlns="http://javafx.com/javafx" 
      xmlns:fx="http://javafx.com/fxml">
    <Label text="My Feature"/>
    <CheckBox fx:id="enabledCheckBox" text="Enable"/>
    <TextField fx:id="intervalTextField" promptText="Interval"/>
</VBox>
```

### Step 2: Create Controller

Create file: `wos-hmi/src/main/java/cl/camodev/wosbot/myfeature/controller/MyFeatureController.java`

```java
package cl.camodev.wosbot.myfeature.controller;

import javafx.fxml.FXML;
import javafx.scene.control.CheckBox;
import javafx.scene.control.TextField;
import cl.camodev.wosbot.ot.DTOProfiles;
import cl.camodev.wosbot.console.enumerable.EnumConfigurationKey;

public class MyFeatureController {
    
    @FXML private CheckBox enabledCheckBox;
    @FXML private TextField intervalTextField;
    
    private DTOProfiles profile;
    
    public void setProfile(DTOProfiles profile) {
        this.profile = profile;
        loadConfiguration();
    }
    
    private void loadConfiguration() {
        Boolean enabled = profile.getConfig(
            EnumConfigurationKey.MY_FEATURE_ENABLED_BOOL,
            Boolean.class
        );
        enabledCheckBox.setSelected(enabled != null && enabled);
        
        Integer interval = profile.getConfig(
            EnumConfigurationKey.MY_FEATURE_INTERVAL_INT,
            Integer.class
        );
        intervalTextField.setText(interval != null ? interval.toString() : "60");
    }
    
    public void saveConfiguration() {
        profile.setConfig(
            EnumConfigurationKey.MY_FEATURE_ENABLED_BOOL,
            enabledCheckBox.isSelected()
        );
        
        try {
            Integer interval = Integer.parseInt(intervalTextField.getText());
            profile.setConfig(
                EnumConfigurationKey.MY_FEATURE_INTERVAL_INT,
                interval
            );
        } catch (NumberFormatException e) {
            // Handle error
        }
    }
}
```

### Step 3: Integrate into Main UI

Add navigation/button to load the new feature screen in `LauncherLayoutController`.

---

## Testing Tasks

### Manual Testing

1. **Build Project**
   ```bash
   mvn clean install
   ```

2. **Run Application**
   ```bash
   cd wos-hmi/target
   java -jar wos-bot-1.5.4.jar
   ```

3. **Create Test Profile**
   - Create profile with test emulator
   - Enable task in configuration
   - Monitor logs

4. **Check Logs**
   ```bash
   tail -f target/log/bot.log
   tail -f target/log/profile_*.log
   ```

### Unit Testing (Future)

Consider adding unit tests:

```java
@Test
public void testMyTask() {
    DTOProfiles profile = createTestProfile();
    MyNewTask task = new MyNewTask(profile, TpDailyTaskEnum.MY_NEW_TASK);
    
    // Test task logic
    // Mock dependencies
    // Assert results
}
```

---

## Debugging

### Enable Debug Logging

Edit `logback.xml` or set log level:

```java
logger.setLevel(Level.DEBUG);
```

### Common Debugging Techniques

1. **Add Log Statements**
   ```java
   logDebug("Current state: {}", state);
   logDebug("OCR result: {}", text);
   ```

2. **Check Screenshots**
   - Screenshots cached in emulator
   - Can save screenshots for inspection

3. **Verify Configuration**
   ```java
   Boolean enabled = profile.getConfig(
       EnumConfigurationKey.MY_TASK_BOOL,
       Boolean.class
   );
   logDebug("Configuration: enabled={}", enabled);
   ```

4. **Check Emulator State**
   ```java
   boolean running = emuManager.isRunning(EMULATOR_NUMBER);
   logDebug("Emulator running: {}", running);
   ```

5. **Verify Screen Location**
   ```java
   EnumStartLocation location = navigationHelper.getCurrentLocation();
   logDebug("Current location: {}", location);
   ```

### Common Issues

#### Task Not Executing
- Check if profile is enabled
- Check if task is enabled in configuration
- Check task schedule
- Check emulator is running
- Check logs for errors

#### OCR Failures
- Verify OCR region coordinates
- Check OCR settings (single line vs multi-line)
- Verify image quality
- Check Tesseract data files

#### Emulator Connection Issues
- Verify ADB is enabled in emulator
- Check emulator is running
- Verify ADB path is correct
- Check firewall/antivirus blocking ADB

#### Configuration Not Saving
- Verify `shouldUpdateConfig = true` is set
- Check database permissions
- Verify profile is saved after config change

---

## Code Style Guidelines

### Naming Conventions

- **Classes**: PascalCase (`MyNewTask`)
- **Methods**: camelCase (`doSomething`)
- **Constants**: UPPER_SNAKE_CASE (`MAX_RETRIES`)
- **Variables**: camelCase (`emulatorNumber`)

### Code Organization

- **One class per file**
- **Package structure**: Follow existing patterns
- **Imports**: Organize imports (IDE auto-format)

### Documentation

- **JavaDoc**: Add for public methods
- **Comments**: Explain complex logic
- **Logging**: Use appropriate log levels

### Best Practices

1. **Always handle exceptions**
2. **Always reschedule tasks** (even on failure)
3. **Use helper classes** instead of duplicating code
4. **Follow existing patterns**
5. **Test thoroughly** before committing

---

**Next**: See [06-api-reference.md](./06-api-reference.md) for API documentation.

