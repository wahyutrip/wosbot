# WoS Bot - Complete Development Guide

Complete guide for understanding, setting up, running, and developing the Whiteout Survival Bot project.

## 🚀 Quick Setup & Running (5 minutes)

### Prerequisites

1. **Java 21 JDK** - Download from [Adoptium Temurin](https://adoptium.net/)
2. **Apache Maven** - Download from [Maven official site](https://maven.apache.org/install.html) or install via package manager
3. **Java Extension Pack** - Install in Cursor IDE (will prompt automatically)

### Step 1: Install Required Extensions

Cursor will prompt you to install recommended extensions, or manually install:
- **Extension Pack for Java** (includes Java, Maven, Debugger, Test Runner)

### Step 2: Verify PowerShell is Default Terminal

1. Open terminal in Cursor (Ctrl+` or View → Terminal)
2. Check terminal shows `PS` prompt (PowerShell)
3. If not, click dropdown next to `+` button → Select **PowerShell**

### Step 3: Build the Project

Open PowerShell terminal and run:

```powershell
mvn clean install package
```

**Note**: First build may take 2-5 minutes to download dependencies.

This will:
- ✅ Compile all modules
- ✅ Download dependencies
- ✅ Copy JavaFX modules to `wos-hmi\target\lib\`
- ✅ Copy ADB and Tesseract resources

### Step 4: Verify Setup (Optional)

Run the verification script:

```powershell
.\verify-setup.ps1
```

**Note**: If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Step 5: Verify JavaFX Modules

Check that these files exist:
```
wos-hmi\target\lib\javafx-controls-23.0.1.jar
wos-hmi\target\lib\javafx-fxml-23.0.1.jar
```

Or verify in PowerShell:
```powershell
Test-Path "wos-hmi\target\lib\javafx-controls-23.0.1.jar"
Test-Path "wos-hmi\target\lib\javafx-fxml-23.0.1.jar"
```

### Step 6: Run/Debug

1. **Press F5** or click the **Run and Debug** icon (left sidebar)
2. Select **"Debug WoS Bot"** from dropdown
3. Click the green play button or press **F5**

The application should launch! 🎉

---

## 🐛 Debugging Guide

### Setting Breakpoints

- Click in the **gutter** (left of line numbers) to set breakpoints
- Red dot appears when breakpoint is set
- Application pauses when breakpoint is hit

### Debug Controls

- **F5** - Continue execution
- **F10** - Step Over (execute current line)
- **F11** - Step Into (enter method)
- **Shift+F11** - Step Out (exit method)
- **Shift+F5** - Stop debugging
- **Ctrl+Shift+F5** - Restart debugging

### Viewing Variables

- **Hover** over variables to see values
- **Variables panel** shows all local variables
- **Watch panel** for custom expressions
- **Call Stack** panel shows execution path

### Debug Configurations

- **Debug WoS Bot** - Main debug configuration (builds before running)
- **Debug WoS Bot (External Console)** - Runs in external terminal (better for logs)
- **Debug WoS Bot (No Build)** - Skips build step (faster if already built)
- **Debug Current Java File** - Debugs the currently open Java file

### Common Debug Scenarios

#### Debug Task Execution
1. Set breakpoint in `DelayedTask.execute()` or specific task
2. Run debugger
3. Trigger task execution in GUI
4. Debugger pauses at breakpoint

#### Debug OCR Operations
1. Set breakpoint in `TextRecognitionRetrier.ocrRegion()`
2. Step through OCR processing
3. Inspect OCR results

#### Debug Emulator Operations
1. Set breakpoint in `Emulator.captureScreenshot()`
2. Inspect screenshot data
3. Step through ADB operations

### Pro Debugging Tips

1. **Use External Console** for better log visibility
2. **Set conditional breakpoints** (right-click breakpoint → Edit Breakpoint)
3. **Use Logpoints** instead of breakpoints for logging (right-click gutter)
4. **Watch expressions** for complex debugging
5. **Hot Code Replace** allows code changes during debugging (if supported)

---

## 📚 Documentation Index

### Core Documentation
- **[01-architecture-overview.md](./01-architecture-overview.md)** - High-level architecture, module structure, and system design
- **[02-module-details.md](./02-module-details.md)** - Detailed breakdown of each module (wos-hmi, wos-serv, wos-persitence, wos-utiles, wos-ot)
- **[03-core-concepts.md](./03-core-concepts.md)** - Key concepts: Profiles, Tasks, Emulators, OCR, Scheduling

### Development Guides
- **[04-task-system.md](./04-task-system.md)** - Deep dive into the task system: how tasks work, creating new tasks, task lifecycle
- **[05-development-guide.md](./05-development-guide.md)** - Step-by-step guides for common development tasks
- **[06-api-reference.md](./06-api-reference.md)** - Service APIs, interfaces, and how to use them

### Reference Documentation
- **[07-data-model.md](./07-data-model.md)** - Database entities, DTOs, and data structures
- **[08-configuration-reference.md](./08-configuration-reference.md)** - Complete list of configuration keys and their usage
- **[09-helper-classes.md](./09-helper-classes.md)** - Helper classes for common operations (navigation, OCR, stamina, etc.)

---

## 🎯 Quick Start for AI Agents

### Understanding the Project
1. Start with **[01-architecture-overview.md](./01-architecture-overview.md)** to understand the overall structure
2. Read **[03-core-concepts.md](./03-core-concepts.md)** to understand key concepts
3. Review **[04-task-system.md](./04-task-system.md)** to understand how automation works

### Adding New Features
1. Read **[05-development-guide.md](./05-development-guide.md)** for step-by-step instructions
2. Check **[09-helper-classes.md](./09-helper-classes.md)** for available utilities
3. Reference **[08-configuration-reference.md](./08-configuration-reference.md)** for configuration patterns

### Debugging and Troubleshooting
1. Check **[06-api-reference.md](./06-api-reference.md)** for service usage
2. Review **[07-data-model.md](./07-data-model.md)** for data structure understanding
3. See **[02-module-details.md](./02-module-details.md)** for module-specific details

---

## 📋 Project Summary

**Whiteout Survival Bot** is a Java-based automation bot for the mobile game "Whiteout Survival". It uses:
- **Java 21** with **Maven** for build management
- **JavaFX** for the GUI
- **Hibernate ORM** with **SQLite** for persistence
- **Tesseract OCR** (via Tess4j) for reading game UI
- **Android Debug Bridge (ADB)** for emulator control
- **Multi-module architecture** for separation of concerns

## 🔑 Key Concepts

- **Profiles**: Each user account is a profile with its own configuration
- **Tasks**: Automation tasks that perform specific game actions
- **Emulators**: Android emulators (MuMu, MEmu, LDPlayer) controlled via ADB
- **OCR**: Optical Character Recognition for reading game text
- **Scheduling**: Priority-based task queue system

---

## 📝 PowerShell-Specific Notes

### Path Separators

- **Windows paths**: Use backslash `\` (e.g., `wos-hmi\target\lib`)
- **Classpath**: Use semicolon `;` as separator
- **Line continuation**: Use backtick `` ` ``

### Useful PowerShell Commands

```powershell
# Check Java version
java -version

# Check Maven version
mvn -version

# Check if file exists
Test-Path "wos-hmi\target\lib\javafx-controls-23.0.1.jar"

# List files in directory
Get-ChildItem wos-hmi\target\lib

# Search in log files
Select-String -Path "wos-hmi\target\log\*.log" -Pattern "ERROR"

# Monitor log file (like tail -f)
Get-Content wos-hmi\target\log\bot.log -Wait -Tail 20

# View logs (last 50 lines and follow)
Get-Content wos-hmi\target\log\bot.log -Tail 50 -Wait

# View specific profile log
Get-Content wos-hmi\target\log\profile_1.log -Tail 50
```

### Environment Variables

```powershell
# Check JAVA_HOME
$env:JAVA_HOME

# Check PATH
$env:PATH -split ';'

# Find Java executable
where.exe java

# Set JAVA_HOME (temporary)
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21"

# Set JAVA_HOME (permanent)
[System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Eclipse Adoptium\jdk-21", "User")
```

---

## ⚙️ Configuration

### Update Java Path (if needed)

If Java 21 is not detected, update `.vscode\settings.json`:

**Windows (Default):**
```json
"java.configuration.runtimes": [{
    "name": "JavaSE-21",
    "path": "C:\\Program Files\\Eclipse Adoptium\\jdk-21",
    "default": true
}]
```

**Windows (Alternative locations):**
```json
// Try these paths if the above doesn't work:
"C:\\Program Files\\Java\\jdk-21"
"C:\\Program Files\\Microsoft\\jdk-21"
```

### Find Your Java Path

**PowerShell:**
```powershell
# Find Java executable
where.exe java

# Get Java home (if JAVA_HOME is set)
$env:JAVA_HOME

# Common locations to check:
# C:\Program Files\Eclipse Adoptium\jdk-21
# C:\Program Files\Java\jdk-21
# C:\Program Files\Microsoft\jdk-21
```

---

## 🔧 Troubleshooting

### PowerShell Execution Policy

If scripts are blocked, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Error: "JavaFX runtime components are missing"

**Solution:**
1. Ensure project is built: `mvn clean install package`
2. Check `wos-hmi\target\lib\` contains JavaFX JARs
3. Verify VM args in launch.json include `--module-path` and `--add-modules`

### Error: "ClassNotFoundException"

**Solution:**
1. Rebuild: `mvn clean compile`
2. Check all modules compiled successfully
3. Verify classpath includes all module target directories

### Error: "Maven not found"

**Solution:**

**Option 1: Add to PATH**
1. Download Maven from: https://maven.apache.org/download.cgi
2. Extract to `C:\Program Files\Apache\maven`
3. Add `C:\Program Files\Apache\maven\bin` to PATH environment variable
4. Restart Cursor IDE

**Option 2: Use Package Manager**

**Chocolatey:**
```powershell
choco install maven
```

**Scoop:**
```powershell
scoop install maven
```

**Winget:**
```powershell
winget install Apache.Maven
```

**Verify:**
```powershell
mvn -version
```

### Error: "Java Version Mismatch"

**Solution:**
1. Ensure Java 21 is installed (download from https://adoptium.net/)
2. Update `java.configuration.runtimes` in `.vscode\settings.json` with correct path
3. Common Windows paths:
   - `C:\Program Files\Eclipse Adoptium\jdk-21`
   - `C:\Program Files\Java\jdk-21`
   - `C:\Program Files\Microsoft\jdk-21`
4. Set Java 21 as default in Cursor/VS Code
5. Verify: `java -version` in PowerShell

### Application starts but GUI doesn't appear

**Solution:**
1. Check logs: `wos-hmi\target\log\bot.log`
2. Verify JavaFX modules are loaded
3. Try external console configuration
4. Check for JavaFX thread errors

### Breakpoints not working

**Solution:**
1. Ensure code is compiled: `mvn clean compile`
2. Check breakpoint is in executable code (not comments/whitespace)
3. Verify source code matches compiled code
4. Try rebuilding: `mvn clean install`

### Terminal Still Shows WSL/Bash

**Solution:**
1. Click dropdown next to `+` in terminal
2. Select **PowerShell**
3. Or set default: File → Preferences → Settings → Search "terminal.integrated.defaultProfile.windows"
4. Set to "PowerShell"

---

## 📝 Useful Commands

### Build Commands

```powershell
# Quick compile (skip tests)
mvn clean compile

# Full build with tests
mvn clean install package

# Run tests only
mvn test

# Clean build artifacts
mvn clean
```

### Run from Terminal

```powershell
# After building, run from terminal:
cd wos-hmi\target
java --module-path lib --add-modules javafx.controls,javafx.fxml `
     -cp "classes;..\wos-serv\target\classes;..\wos-persitence\target\classes;..\wos-utiles\target\classes;..\wos-ot\target\classes;lib\*" `
     cl.camodev.wosbot.main.Main
```

**Note**: PowerShell uses backticks (`) for line continuation and semicolons (;) for classpath separators.

### View Logs

```powershell
# View main log (last 50 lines and follow)
Get-Content wos-hmi\target\log\bot.log -Tail 50 -Wait

# View profile log
Get-Content wos-hmi\target\log\profile_*.log -Tail 50 -Wait

# Search for errors in logs
Select-String -Path "wos-hmi\target\log\*.log" -Pattern "ERROR"
```

## 🛠️ Build Tasks

Use Ctrl+Shift+P and type "Tasks: Run Task" to access:
- **build-project** - Clean compile (skips tests) - Uses PowerShell
- **build-full** - Full build with tests - Uses PowerShell
- **test** - Run tests only - Uses PowerShell
- **clean** - Clean build artifacts - Uses PowerShell

**Note**: All tasks run in PowerShell terminal by default.

## 📍 Log Files

Application logs are written to:
- `wos-hmi\target\log\bot.log` - Main application log
- `wos-hmi\target\log\profile_*.log` - Per-profile logs

---

## 📝 Usage Tips

When working with this codebase:
1. **Always check existing patterns** - The codebase follows consistent patterns
2. **Use helper classes** - Don't reinvent the wheel, use existing helpers
3. **Follow the task pattern** - New tasks should extend `DelayedTask`
4. **Update configuration enums** - Add new config keys to `EnumConfigurationKey`
5. **Register tasks** - Add new tasks to `DelayedTaskRegistry`

## 🚀 Common Development Tasks

- **Adding a new automation task**: See [05-development-guide.md](./05-development-guide.md#adding-a-new-task)
- **Adding a new configuration option**: See [05-development-guide.md](./05-development-guide.md#adding-configuration-keys)
- **Understanding OCR usage**: See [09-helper-classes.md](./09-helper-classes.md#ocr-helpers)
- **Working with emulators**: See [03-core-concepts.md](./03-core-concepts.md#emulator-management)

---

## 📖 Additional Resources

- **Main README**: `../README.md`
- **Project root**: `../`
- **Source code**: `../wos-*/src/main/java/`
- **PowerShell Documentation**: https://docs.microsoft.com/powershell/
- **Maven on Windows**: https://maven.apache.org/install.html
- **Java Installation**: https://adoptium.net/

---

**Note**: This documentation is designed to be comprehensive and self-contained. Each file can be used as context when working on specific aspects of the project.
