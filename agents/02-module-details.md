# Module Details

This document provides detailed information about each module in the WoS Bot project.

## wos-hmi (Human-Machine Interface)

### Purpose
The presentation layer providing the JavaFX-based graphical user interface.

### Package Structure
```
cl.camodev.wosbot
├── main/                    # Application entry point
│   ├── Main.java           # Main class, launches FXApp
│   └── FXApp.java          # JavaFX Application
├── launcher/                # Main launcher window
│   └── view/
│       └── LauncherLayoutController.java
├── profile/                 # Profile management
│   ├── controller/
│   ├── model/
│   └── view/
├── taskmanager/            # Task management UI
│   └── controller/
├── alliance/                # Alliance features UI
├── city/                    # City management UI
├── gather/                 # Gathering configuration UI
├── training/                # Training configuration UI
├── events/                  # Event configuration UI
└── [other feature packages]
```

### Key Classes

#### Main.java
- **Purpose**: Application entry point
- **Responsibilities**:
  - Initialize logging
  - Suppress JavaFX warnings
  - Launch JavaFX application
  - Handle shutdown hooks

#### FXApp.java
- **Purpose**: JavaFX application initialization
- **Responsibilities**:
  - Load FXML layouts
  - Initialize controllers
  - Manage window state (position, size)
  - Handle application lifecycle

#### LauncherLayoutController
- **Purpose**: Main window controller
- **Responsibilities**:
  - Profile management UI
  - Task queue display
  - Status monitoring
  - Navigation to feature screens

### Dependencies
- **JavaFX Controls**: UI components
- **JavaFX FXML**: Layout files
- **ControlsFX**: Additional UI controls
- **wos-serv**: Service layer for business logic
- **wos-utiles**: Utility functions
- **wos-ot**: Data transfer objects

### Resources
- **FXML files**: `src/main/resources/` (layout definitions)
- **CSS files**: `src/main/resources/styles/` (styling)
- **Icons**: `src/main/resources/icons/` (application icons)

---

## wos-serv (Service Layer)

### Purpose
Core business logic, task execution, and emulator management.

### Package Structure
```
cl.camodev.wosbot
├── serv/                    # Service implementations
│   ├── impl/
│   │   ├── ServScheduler.java      # Main scheduler
│   │   ├── ServProfiles.java      # Profile service
│   │   ├── ServLogs.java          # Logging service
│   │   └── StaminaService.java    # Stamina management
│   ├── task/               # Task system
│   │   ├── DelayedTask.java       # Base task class
│   │   ├── TaskQueue.java          # Task queue implementation
│   │   ├── DelayedTaskRegistry.java # Task factory registry
│   │   ├── helper/                 # Task helper classes
│   │   │   ├── NavigationHelper.java
│   │   │   ├── StaminaHelper.java
│   │   │   ├── MarchHelper.java
│   │   │   ├── TemplateSearchHelper.java
│   │   │   ├── IntelScreenHelper.java
│   │   │   ├── AllianceHelper.java
│   │   │   └── [others]
│   │   └── impl/                   # Task implementations
│   │       ├── ArenaTask.java
│   │       ├── GatherTask.java
│   │       ├── TrainingTask.java
│   │       └── [40+ task classes]
│   ├── emulator/           # Emulator management
│   │   ├── Emulator.java            # Abstract base
│   │   ├── EmulatorManager.java     # Emulator factory/manager
│   │   └── impl/
│   │       ├── MuMuEmulator.java
│   │       ├── MEmuEmulator.java
│   │       └── LDPlayerEmulator.java
│   └── ocr/                 # OCR integration
│       └── BotTextRecognitionProvider.java
├── console/                 # Console/configuration
│   └── enumerable/
│       ├── TpDailyTaskEnum.java
│       └── EnumConfigurationKey.java
└── ex/                      # Custom exceptions
    ├── ADBConnectionException.java
    └── HomeNotFoundException.java
```

### Key Classes

#### ServScheduler
- **Purpose**: Main scheduler coordinating all task execution
- **Responsibilities**:
  - Initialize task queues for profiles
  - Load task configurations
  - Coordinate task execution
  - Manage task state persistence

#### TaskQueue
- **Purpose**: Priority-based task queue per profile
- **Responsibilities**:
  - Task scheduling and ordering
  - Task execution loop
  - Delay management
  - Task state updates

#### DelayedTask
- **Purpose**: Base class for all automation tasks
- **Key Features**:
  - Profile configuration access
  - Helper class initialization
  - Screen location verification
  - Logging utilities
  - Emulator interaction methods
  - Task rescheduling

#### EmulatorManager
- **Purpose**: Factory and manager for emulator instances
- **Responsibilities**:
  - Create emulator instances
  - Manage emulator slots (concurrency)
  - Track running emulators
  - Handle emulator lifecycle

#### Emulator (Abstract)
- **Purpose**: Abstract interface for emulator operations
- **Key Methods**:
  - `launchEmulator()` - Start emulator
  - `closeEmulator()` - Stop emulator
  - `isRunning()` - Check if running
  - `captureScreenshot()` - Get screen image
  - `tap()` - Simulate touch
  - `swipe()` - Simulate swipe
  - `isPackageRunning()` - Check if game is running

### Task Implementations

#### Categories of Tasks

1. **Daily Tasks** (30+ tasks)
   - `ArenaTask` - Arena battles
   - `DailyMissionTask` - Daily missions
   - `MailRewardsTask` - Mail collection
   - `VipTask` - VIP points
   - `WarAcademyTask` - War Academy shards
   - `CrystalLaboratoryTask` - Fire Crystals
   - And many more...

2. **Alliance Tasks**
   - `AllianceTechTask` - Alliance technology
   - `AllianceChestTask` - Alliance chests
   - `AllianceShopTask` - Alliance shop
   - `AllianceMobilizationTask` - Alliance mobilization
   - `AllianceChampionshipTask` - Alliance championship

3. **Resource Tasks**
   - `GatherTask` - Resource gathering
   - `GatherSpeedTask` - Gather speed boost
   - `TrainingTask` - Troop training

4. **Event Tasks**
   - `TundraTruckEventTask` - Tundra Truck event
   - `PolarTerrorHuntingTask` - Polar Terror hunting
   - `JourneyofLightTask` - Journey of Light event
   - `BearTrapTask` - Bear Trap event

5. **City Management**
   - `UpgradeBuildingsTask` - Building upgrades
   - `NewSurvivorsTask` - Accept new survivors

6. **Special Tasks**
   - `InitializeTask` - Initialization and validation
   - `IntelligenceTask` - Intel collection
   - `PetSkillsTask` - Pet skill management

### Helper Classes

#### NavigationHelper
- Navigate between game screens
- Verify current screen location
- Handle navigation failures

#### StaminaHelper
- Check stamina availability
- Manage stamina consumption
- Handle stamina-related operations

#### MarchHelper
- Manage troop marches
- Handle march queues
- Recall marches

#### TemplateSearchHelper
- Template matching for UI elements
- Image search on screen
- UI element detection

#### IntelScreenHelper
- Intel screen navigation
- Intel processing
- Intel-related operations

#### AllianceHelper
- Alliance screen navigation
- Alliance operations
- Alliance-related UI interactions

### Dependencies
- **ddmlib**: Android Debug Bridge library
- **Tess4j**: OCR engine
- **JDA**: Discord API (optional)
- **wos-persitence**: Data access
- **wos-utiles**: OCR utilities
- **wos-ot**: DTOs

---

## wos-persitence (Persistence Layer)

### Purpose
Data persistence using Hibernate ORM with SQLite database.

### Package Structure
```
cl.camodev.wosbot
├── almac/                   # Storage layer
│   ├── entity/              # JPA entities
│   │   ├── Profile.java
│   │   ├── Config.java
│   │   └── TpConfig.java
│   ├── jpa/                 # JPA configuration
│   │   ├── BotPersistence.java
│   │   └── PersistenceDataInitialization.java
│   └── repo/                # Repository interfaces/implementations
│       ├── IProfileRepository.java
│       ├── ProfileRepository.java
│       ├── IConfigRepository.java
│       └── ConfigRepository.java
```

### Key Classes

#### BotPersistence
- **Purpose**: Hibernate session management
- **Responsibilities**:
  - Entity manager factory creation
  - Session management
  - Transaction handling
  - Query execution

#### ProfileRepository
- **Purpose**: Profile data access
- **Key Methods**:
  - `getProfiles()` - Get all profiles with configs
  - `getProfileWithConfigsById()` - Get profile by ID
  - `addProfile()` - Create new profile
  - `saveProfile()` - Update profile
  - `deleteProfile()` - Delete profile

#### ConfigRepository
- **Purpose**: Configuration data access
- **Key Methods**:
  - `getProfileConfigs()` - Get configs for profile
  - `getGlobalConfigs()` - Get global configs
  - `addConfig()` - Create config
  - `saveConfig()` - Update config
  - `deleteConfig()` - Delete config

### Entities

#### Profile
- **Fields**:
  - `id` (Long) - Primary key
  - `name` (String) - Profile name
  - `emulatorNumber` (String) - Associated emulator
  - `enabled` (Boolean) - Enabled status
  - `priority` (Long) - Execution priority
  - `reconnectionTime` (Long) - Reconnection delay
  - `configs` (List<Config>) - Associated configurations

#### Config
- **Fields**:
  - `id` (Long) - Primary key
  - `profile` (Profile) - Associated profile (nullable for global)
  - `key` (String) - Configuration key
  - `value` (String) - Configuration value

#### TpConfig
- **Purpose**: Type configurations (system-level)
- **Fields**: Similar to Config but for system settings

### Database Schema

#### profiles Table
```sql
CREATE TABLE profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_name TEXT NOT NULL,
    emulator_number TEXT NOT NULL,
    enabled INTEGER NOT NULL,
    priority INTEGER DEFAULT 50,
    reconnection_time INTEGER DEFAULT 0
);
```

#### configs Table
```sql
CREATE TABLE configs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);
```

### Dependencies
- **Hibernate ORM 7.0.8**: JPA implementation
- **SQLite JDBC 3.42.0.0**: Database driver
- **HikariCP 5.0.1**: Connection pooling
- **Jakarta Persistence API**: JPA standard
- **wos-ot**: DTOs

---

## wos-utiles (Utilities)

### Purpose
Shared utilities and helper functions, primarily for OCR and image processing.

### Package Structure
```
cl.camodev.utiles
├── ocr/                     # OCR utilities
│   ├── TextRecognitionProvider.java    # OCR interface
│   └── TextRecognitionRetrier.java     # Retry logic
├── number/                  # Number utilities
│   ├── NumberConverters.java
│   └── NumberValidators.java
└── [other utilities]
```

### Key Classes

#### TextRecognitionProvider
- **Purpose**: Abstraction over OCR sources
- **Interface**: Defines `ocrRegion()` method
- **Implementations**: `BotTextRecognitionProvider` (in wos-serv)

#### TextRecognitionRetrier
- **Purpose**: Retry logic for OCR operations
- **Features**:
  - Configurable retry count
  - Type conversion (Integer, Duration, String)
  - Error handling

#### UtilOCR
- **Purpose**: OCR helper functions
- **Features**:
  - Image preprocessing
  - OCR configuration
  - Text extraction utilities

### Dependencies
- **OpenCV 4.9.0**: Image processing
- **Tess4j 5.14.0**: Tesseract OCR wrapper
- **wos-ot**: DTOs (DTOPoint, DTOTesseractSettings)

---

## wos-ot (Data Transfer Objects)

### Purpose
Shared data structures, DTOs, and enums used across modules.

### Package Structure
```
cl.camodev.wosbot
├── ot/                      # Data transfer objects
│   ├── DTOProfiles.java
│   ├── DTOConfig.java
│   ├── DTOTaskState.java
│   ├── DTOPoint.java
│   ├── DTORawImage.java
│   ├── DTOTesseractSettings.java
│   └── [other DTOs]
└── console/
    └── enumerable/
        ├── TpDailyTaskEnum.java
        ├── EnumConfigurationKey.java
        └── [other enums]
```

### Key DTOs

#### DTOProfiles
- **Purpose**: Profile data structure
- **Fields**:
  - `id`, `name`, `emulatorNumber`
  - `enabled`, `priority`, `reconnectionTime`
  - `configs` (List<DTOConfig>)
  - Methods: `getConfig()`, `setConfig()`

#### DTOConfig
- **Purpose**: Configuration key-value pair
- **Fields**: `profileId`, `key`, `value`

#### DTOTaskState
- **Purpose**: Task execution state
- **Fields**: Task status, next execution time, last execution time

#### DTOPoint
- **Purpose**: Screen coordinates
- **Fields**: `x`, `y` (integers)

#### DTORawImage
- **Purpose**: Screenshot data
- **Fields**: `pixelData`, `width`, `height`, `bpp`

### Key Enums

#### TpDailyTaskEnum
- **Purpose**: Enumeration of all task types
- **Fields**: `id`, `name`, `configKey`
- **Usage**: Task type identification and registration

#### EnumConfigurationKey
- **Purpose**: All configuration keys
- **Fields**: `defaultValue`, `type` (Class)
- **Usage**: Type-safe configuration access

### Dependencies
- **None**: Base module, no dependencies

---

## Module Interaction Examples

### Example 1: Task Execution
```
wos-hmi (User clicks "Start")
    ↓
wos-serv (ServScheduler creates TaskQueue)
    ↓
wos-serv (TaskQueue loads profile from wos-persitence)
    ↓
wos-serv (DelayedTask.execute() runs)
    ↓
wos-serv (Emulator captures screenshot)
    ↓
wos-utiles (OCR reads text from screenshot)
    ↓
wos-serv (Task performs game action)
    ↓
wos-persitence (Task state saved)
    ↓
wos-hmi (Status updated in GUI)
```

### Example 2: Profile Configuration
```
wos-hmi (User edits profile)
    ↓
wos-ot (DTOProfiles created)
    ↓
wos-persitence (ProfileRepository.saveProfile())
    ↓
wos-persitence (Hibernate saves to SQLite)
    ↓
wos-serv (ServProfiles refreshes profile)
    ↓
wos-serv (Tasks use updated configuration)
```

### Example 3: OCR Operation
```
wos-serv (Task needs to read text)
    ↓
wos-serv (Emulator.captureScreenshot())
    ↓
wos-utiles (TextRecognitionProvider.ocrRegion())
    ↓
wos-utiles (Tess4j performs OCR)
    ↓
wos-serv (Task uses recognized text)
```

---

**Next**: See [03-core-concepts.md](./03-core-concepts.md) for detailed explanation of core concepts.

