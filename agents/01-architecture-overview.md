# Architecture Overview

## System Architecture

The Whiteout Survival Bot follows a **layered, multi-module architecture** designed for maintainability and separation of concerns.

```
┌─────────────────────────────────────────────────────────────┐
│                    wos-hmi (Presentation)                   │
│  JavaFX GUI, Controllers, User Interface Components         │
└───────────────────────┬─────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────────────────────┐
│                    wos-serv (Service Layer)                 │
│  Task System, Emulator Management, Business Logic           │
└───────────────┬───────────────────────┬─────────────────────┘
                │                       │
    ┌───────────▼──────────┐  ┌────────▼──────────┐
    │  wos-persitence      │  │   wos-utiles      │
    │  Data Persistence    │  │   Utilities       │
    │  Hibernate + SQLite │  │   OCR, Helpers     │
    └───────────┬──────────┘  └────────┬──────────┘
                │                       │
                └───────────┬───────────┘
                            │
                ┌───────────▼──────────┐
                │      wos-ot           │
                │  Data Transfer       │
                │  Objects (DTOs)      │
                └──────────────────────┘
```

## Module Dependencies

```
wos-hmi
  ├── wos-serv
  ├── wos-utiles
  └── wos-ot

wos-serv
  ├── wos-persitence
  ├── wos-ot
  └── wos-utiles

wos-persitence
  └── wos-ot

wos-utiles
  └── wos-ot

wos-ot
  └── (no dependencies)
```

## Module Responsibilities

### wos-hmi (Human-Machine Interface)
**Purpose**: User interface layer using JavaFX

**Key Responsibilities**:
- GUI rendering and user interaction
- Profile management UI
- Task configuration UI
- Real-time status display
- Log visualization

**Key Components**:
- `Main.java` - Application entry point
- `FXApp.java` - JavaFX application initialization
- `LauncherLayoutController` - Main window controller
- Various feature controllers (Profile, Task, Alliance, etc.)

**Dependencies**:
- JavaFX Controls & FXML
- ControlsFX (UI components)
- All other modules (serv, utiles, ot)

### wos-serv (Service Layer)
**Purpose**: Core business logic and automation engine

**Key Responsibilities**:
- Task scheduling and execution
- Emulator communication and management
- Game automation logic
- OCR integration
- Service coordination

**Key Components**:
- `ServScheduler` - Main scheduler coordinating all tasks
- `TaskQueue` - Priority-based task queue
- `DelayedTask` - Base class for all automation tasks
- `EmulatorManager` - Manages emulator instances
- `Emulator` - Abstract emulator interface
- Task implementations (40+ task classes)

**Dependencies**:
- ddmlib (Android ADB)
- Tess4j (OCR)
- JDA (Discord integration)
- wos-persitence, wos-ot, wos-utiles

### wos-persitence (Persistence Layer)
**Purpose**: Data persistence using Hibernate ORM

**Key Responsibilities**:
- Database operations
- Entity management
- Configuration storage
- Profile data persistence

**Key Components**:
- `BotPersistence` - Hibernate session management
- `ProfileRepository` - Profile CRUD operations
- `ConfigRepository` - Configuration management
- Entity classes (`Profile`, `Config`, `TpConfig`, etc.)

**Database**: SQLite (embedded)

**Dependencies**:
- Hibernate ORM
- SQLite JDBC
- HikariCP (connection pooling)
- wos-ot (DTOs)

### wos-utiles (Utilities)
**Purpose**: Shared utilities and helper functions

**Key Responsibilities**:
- OCR utilities
- Image processing
- Text recognition retry logic
- Common helper functions

**Key Components**:
- `UtilOCR` - OCR helper functions
- `TextRecognitionProvider` - OCR abstraction
- `TextRecognitionRetrier` - Retry logic for OCR

**Dependencies**:
- OpenCV (image processing)
- Tess4j (OCR)
- wos-ot (DTOs)

### wos-ot (Other/Data Transfer Objects)
**Purpose**: Shared data structures and DTOs

**Key Responsibilities**:
- Data transfer objects
- Common enums
- Shared constants

**Key Components**:
- `DTOProfiles` - Profile data structure
- `DTOConfig` - Configuration data
- `DTOTaskState` - Task execution state
- `DTOPoint` - Coordinate points
- `DTORawImage` - Screenshot data
- Enums (`TpDailyTaskEnum`, `EnumConfigurationKey`, etc.)

**Dependencies**: None (base module)

## Data Flow

### Task Execution Flow

```
User Action (GUI)
    ↓
Profile Configuration Saved (wos-persitence)
    ↓
Task Scheduled (wos-serv: ServScheduler)
    ↓
Task Queued (wos-serv: TaskQueue)
    ↓
Task Executes (wos-serv: DelayedTask.execute())
    ↓
Emulator Interaction (wos-serv: Emulator)
    ↓
OCR Reading (wos-utiles: OCR)
    ↓
Game Action Performed
    ↓
Task Rescheduled/Completed
    ↓
Status Updated (wos-hmi: GUI)
```

### Profile Configuration Flow

```
User Configures Profile (wos-hmi)
    ↓
DTOProfiles Created (wos-ot)
    ↓
Saved to Database (wos-persitence: ProfileRepository)
    ↓
Loaded by Service (wos-serv: ServProfiles)
    ↓
Used by Tasks (wos-serv: DelayedTask)
```

## Key Design Patterns

### 1. Registry Pattern
- **`DelayedTaskRegistry`**: Maps task types to task factories
- Allows dynamic task creation without hardcoding

### 2. Singleton Pattern
- **Service classes**: `ServScheduler`, `ServProfiles`, `ServLogs`, `EmulatorManager`
- Ensures single instance across the application

### 3. Template Method Pattern
- **`DelayedTask`**: Base class defines execution flow
- Subclasses implement `execute()` method

### 4. Strategy Pattern
- **Emulator implementations**: `MuMuEmulator`, `MEmuEmulator`, `LDPlayerEmulator`
- Different strategies for different emulator types

### 5. Repository Pattern
- **`ProfileRepository`**, **`ConfigRepository`**: Abstract data access
- Separates business logic from data access

## Technology Stack

### Core Technologies
- **Java 21**: Programming language
- **Maven**: Build tool and dependency management
- **JavaFX 23.0.1**: GUI framework

### Libraries and Frameworks
- **Hibernate ORM 7.0.8**: Object-relational mapping
- **SQLite JDBC 3.42.0.0**: Database driver
- **HikariCP 5.0.1**: Connection pooling
- **Tess4j 5.14.0**: Tesseract OCR wrapper
- **OpenCV 4.9.0**: Image processing
- **ddmlib 31.11.1**: Android Debug Bridge library
- **SLF4J + Logback**: Logging framework
- **JDA 5.3.0**: Discord API (optional)

### External Tools
- **ADB (Android Debug Bridge)**: Bundled in `lib/adb/`
- **Tesseract OCR**: Bundled in `lib/tesseract/`

## Build and Deployment

### Build Process
1. **Maven Compilation**: `mvn clean install package`
2. **Dependency Copying**: Dependencies copied to `target/lib/`
3. **Resource Copying**: ADB and Tesseract data copied to `target/lib/`
4. **JAR Creation**: Executable JAR created in `wos-hmi/target/`

### Output Structure
```
wos-hmi/target/
  ├── wos-bot-1.5.4.jar (executable)
  └── lib/
      ├── adb/ (ADB executables)
      ├── tesseract/ (OCR data)
      └── *.jar (dependencies)
```

## Threading Model

### Main Threads
1. **JavaFX Application Thread**: UI updates and user interaction
2. **Task Queue Threads**: One per profile, executes scheduled tasks
3. **Emulator Management Thread**: Handles emulator operations
4. **Logging Threads**: Async logging operations

### Concurrency Considerations
- **Task execution**: Each profile has its own task queue thread
- **Emulator operations**: Thread-safe with caching and retry logic
- **Database access**: Hibernate handles connection pooling
- **OCR operations**: Can be CPU-intensive, run in task threads

## Error Handling

### Exception Hierarchy
- **`ADBConnectionException`**: Emulator connection issues
- **`HomeNotFoundException`**: Game state detection failures
- **`TesseractException`**: OCR failures
- **Generic exceptions**: Caught and logged, tasks rescheduled

### Retry Mechanisms
- **ADB operations**: Automatic retry with exponential backoff
- **OCR operations**: Configurable retry count via `TextRecognitionRetrier`
- **Task execution**: Failed tasks can be rescheduled

## Logging Architecture

### Log Levels
- **ERROR**: Critical failures requiring attention
- **WARN**: Recoverable issues or unexpected states
- **INFO**: Important operations and state changes
- **DEBUG**: Detailed execution information

### Log Files
- **`target/log/bot.log`**: Main application log
- **`target/log/profile_*.log`**: Per-profile logs (one per profile)

### Logging Components
- **`ProfileLogger`**: Profile-specific logging wrapper
- **`ServLogs`**: Centralized logging service
- **Logback**: Logging implementation

## Security Considerations

### Data Storage
- **SQLite database**: Stored locally, no encryption (consider for sensitive data)
- **Profile configurations**: Stored in database, includes emulator numbers
- **Discord tokens**: Stored in global configuration (if used)

### Emulator Access
- **ADB**: Requires emulator to have ADB enabled
- **No authentication**: Relies on local network security

## Performance Considerations

### Caching
- **Screenshot cache**: Last screenshot cached per emulator
- **Device cache**: ADB device instances cached with TTL
- **Running status cache**: Emulator running status cached

### Optimization Strategies
- **Lazy initialization**: Services initialized on first use
- **Connection pooling**: Database connections pooled via HikariCP
- **Batch operations**: Database operations batched where possible

## Extension Points

### Adding New Tasks
1. Create task class extending `DelayedTask`
2. Register in `DelayedTaskRegistry`
3. Add enum entry to `TpDailyTaskEnum`
4. Add configuration keys to `EnumConfigurationKey`

### Adding New Emulators
1. Create emulator class extending `Emulator`
2. Implement abstract methods
3. Add to `EmulatorManager` factory

### Adding New Helpers
1. Create helper class in `wos-serv/src/.../helper/`
2. Initialize in `DelayedTask` constructor
3. Use in task implementations

---

**Next**: See [02-module-details.md](./02-module-details.md) for detailed module information.

