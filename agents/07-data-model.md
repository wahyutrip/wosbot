# Data Model

This document describes the data structures, entities, and DTOs used throughout the WoS Bot project.

## Database Entities

### Profile Entity

**Location**: `wos-persitence/src/main/java/cl/camodev/wosbot/almac/entity/Profile.java`

**Table**: `profiles`

**Fields**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `id` | Long | Primary key | Auto-increment, unique |
| `name` | String | Profile display name | Not null |
| `emulatorNumber` | String | Associated emulator instance | Not null |
| `enabled` | Boolean | Whether profile is active | Not null |
| `priority` | Long | Execution priority | Default: 50 |
| `reconnectionTime` | Long | Reconnection delay (ms) | Default: 0 |
| `characterId` | String | Character ID for profile switching | Nullable |
| `characterName` | String | Character name for profile switching | Nullable |
| `characterAllianceCode` | String | Alliance code (3 chars) for character name matching | Nullable, max length 3 |
| `characterServer` | String | Character server number | Nullable |
| `configs` | List<Config> | Associated configurations | One-to-many |

**Relationships**:
- One-to-Many with `Config` (cascade delete)

**Example**:
```java
Profile profile = new Profile();
profile.setName("My Profile");
profile.setEmulatorNumber("0");
profile.setEnabled(true);
profile.setPriority(50L);
profile.setReconnectionTime(0L);
```

---

### Config Entity

**Location**: `wos-persitence/src/main/java/cl/camodev/wosbot/almac/entity/Config.java`

**Table**: `configs`

**Fields**:

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `id` | Long | Primary key | Auto-increment |
| `profile` | Profile | Associated profile | Foreign key, nullable (null = global) |
| `key` | String | Configuration key | Not null |
| `value` | String | Configuration value | Not null |

**Relationships**:
- Many-to-One with `Profile` (nullable for global configs)

**Example**:
```java
Config config = new Config();
config.setProfile(profile);  // null for global config
config.setKey("ARENA_TASK_BOOL");
config.setValue("true");
```

---

### TpConfig Entity

**Location**: `wos-persitence/src/main/java/cl/camodev/wosbot/almac/entity/TpConfig.java`

**Purpose**: System-level type configurations

**Similar structure to Config but for system settings**

---

## Data Transfer Objects (DTOs)

### DTOProfiles

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOProfiles.java`

**Purpose**: Profile data structure used across modules

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

**Key Methods**:

```java
// Get configuration value
<T> T getConfig(EnumConfigurationKey key, Class<T> type);

// Set configuration value
void setConfig(EnumConfigurationKey key, Object value);

// Get configuration as specific type
Boolean getConfigAsBoolean(EnumConfigurationKey key);
Integer getConfigAsInteger(EnumConfigurationKey key);
String getConfigAsString(EnumConfigurationKey key);
Long getConfigAsLong(EnumConfigurationKey key);
LocalDateTime getConfigAsLocalDateTime(EnumConfigurationKey key);
```

**Usage**:
```java
DTOProfiles profile = new DTOProfiles();
profile.setId(1L);
profile.setName("My Profile");
profile.setEmulatorNumber("0");
profile.setEnabled(true);

// Set configuration
profile.setConfig(EnumConfigurationKey.ARENA_TASK_BOOL, true);

// Get configuration
Boolean arenaEnabled = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_BOOL,
    Boolean.class
);
```

---

### DTOConfig

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOConfig.java`

**Purpose**: Configuration key-value pair DTO

**Fields**:

```java
Long profileId;  // null for global configs
String key;
String value;
```

**Usage**:
```java
DTOConfig config = new DTOConfig();
config.setProfileId(1L);
config.setKey("ARENA_TASK_BOOL");
config.setValue("true");
```

---

### DTOTaskState

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOTaskState.java`

**Purpose**: Task execution state

**Fields**:

```java
Long profileId;
Integer taskId;  // TpDailyTaskEnum.id
LocalDateTime nextExecutionTime;
LocalDateTime lastExecutionTime;
String status;  // Task status
```

**Usage**:
```java
DTOTaskState state = new DTOTaskState();
state.setProfileId(1L);
state.setTaskId(TpDailyTaskEnum.ARENA.getId());
state.setNextExecutionTime(LocalDateTime.now().plusHours(1));
state.setLastExecutionTime(LocalDateTime.now());
```

---

### DTOPoint

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOPoint.java`

**Purpose**: Screen coordinates

**Fields**:

```java
int x;  // X coordinate
int y;  // Y coordinate
```

**Usage**:
```java
DTOPoint topLeft = new DTOPoint(100, 200);
DTOPoint bottomRight = new DTOPoint(300, 250);
```

---

### DTORawImage

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTORawImage.java`

**Purpose**: Screenshot data

**Fields**:

```java
byte[] pixelData;  // Raw pixel data
int width;         // Image width
int height;        // Image height
int bpp;           // Bits per pixel (usually 32 for RGBA_8888)
```

**Usage**:
```java
DTORawImage screenshot = emulator.captureScreenshot(emulatorNumber);
byte[] pixels = screenshot.getPixelData();
int width = screenshot.getWidth();
int height = screenshot.getHeight();
```

---

### DTOTesseractSettings

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOTesseractSettings.java`

**Purpose**: OCR configuration settings

**Fields**:

```java
Integer pageSegMode;  // Page segmentation mode
Integer ocrEngineMode; // OCR engine mode
String language;      // Language (e.g., "eng")
```

**Common Settings**:

```java
// Single line OCR
DTOTesseractSettings singleLine = CommonOCRSettings.SINGLE_LINE;

// Multi-line OCR
DTOTesseractSettings multiLine = CommonOCRSettings.MULTI_LINE;
```

---

### DTOImageSearchResult

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOImageSearchResult.java`

**Purpose**: Template matching result

**Fields**:

```java
boolean found;      // Whether template was found
int x;              // X coordinate of match
int y;              // Y coordinate of match
double confidence;  // Match confidence (0.0 - 1.0)
```

**Usage**:
```java
DTOImageSearchResult result = templateSearchHelper.searchTemplate(
    "button.png",
    0.8  // 80% confidence threshold
);

if (result.isFound()) {
    int x = result.getX();
    int y = result.getY();
    double confidence = result.getConfidence();
}
```

---

### DTODailyTaskStatus

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTODailyTaskStatus.java`

**Purpose**: Daily task status from database

**Fields**:

```java
Integer taskId;
LocalDateTime nextExecutionTime;
LocalDateTime lastExecutionTime;
```

---

### DTOQueueState

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOQueueState.java`

**Purpose**: Task queue state information

**Fields**:

```java
String profileId;
boolean isRunning;
boolean isPaused;
LocalDateTime delayUntil;
// ... other queue state fields
```

---

### DTOLogMessage

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/ot/DTOLogMessage.java`

**Purpose**: Log message structure

**Fields**:

```java
EnumTpMessageSeverity severity;  // INFO, WARN, ERROR, DEBUG
String taskName;
String profileName;
String message;
LocalDateTime timestamp;
```

---

## Enums

### TpDailyTaskEnum

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/TpDailyTaskEnum.java`

**Purpose**: Enumeration of all task types

**Structure**:

```java
TASK_NAME(id, "Display Name", EnumConfigurationKey.CONFIG_KEY)
```

**Example Entries**:

```java
ARENA(15, "Arena", EnumConfigurationKey.ARENA_TASK_BOOL)
GATHER_RESOURCES(102, "Gather Resources", EnumConfigurationKey.GATHER_TASK_BOOL)
TRAINING_TROOPS(60, "Training", EnumConfigurationKey.TRAIN_BOOL)
```

**Methods**:

```java
int getId();
String getName();
EnumConfigurationKey getConfigKey();
static TpDailyTaskEnum fromId(int id);
```

---

### EnumConfigurationKey

**Location**: `wos-ot/src/main/java/cl/camodev/wosbot/console/enumerable/EnumConfigurationKey.java`

**Purpose**: All configuration keys

**Structure**:

```java
KEY_NAME("defaultValue", Type.class)
```

**Example Entries**:

```java
ARENA_TASK_BOOL("false", Boolean.class)
ARENA_TASK_EXTRA_ATTEMPTS_INT("0", Integer.class)
ARENA_TASK_ACTIVATION_TIME_STRING("23:50", String.class)
```

**Methods**:

```java
String getDefaultValue();
Class<?> getType();
<T> T castValue(String value);
```

**Supported Types**:
- `Boolean.class`
- `Integer.class`
- `Long.class`
- `String.class`
- `LocalDateTime.class`

---

### EnumTpMessageSeverity

**Purpose**: Log message severity levels

**Values**:
- `INFO` - Informational messages
- `WARN` - Warning messages
- `ERROR` - Error messages
- `DEBUG` - Debug messages

---

### EnumStartLocation

**Purpose**: Required starting screen location for tasks

**Values**:
- `HOME` - City/home screen
- `WORLD` - World map screen
- `ANY` - Any location (default)

---

## Data Flow

### Profile Creation Flow

```
User Input (GUI)
    ↓
DTOProfiles created
    ↓
Profile entity created
    ↓
Saved to database (ProfileRepository)
    ↓
Loaded as DTOProfiles (ServProfiles)
    ↓
Used by tasks
```

### Configuration Flow

```
User sets config (GUI)
    ↓
DTOProfiles.setConfig(key, value)
    ↓
Config entity created/updated
    ↓
Saved to database (ConfigRepository)
    ↓
Loaded with profile (ProfileRepository)
    ↓
Accessed via DTOProfiles.getConfig()
```

### Task State Flow

```
Task executes
    ↓
DTOTaskState created
    ↓
State saved to database
    ↓
Loaded on next execution
    ↓
Used for rescheduling
```

---

## Database Schema

### profiles Table

```sql
CREATE TABLE profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_name TEXT NOT NULL,
    emulator_number TEXT NOT NULL,
    enabled INTEGER NOT NULL,
    priority INTEGER DEFAULT 50,
    reconnection_time INTEGER DEFAULT 0,
    character_id TEXT,
    character_name TEXT,
    character_alliance_code TEXT,
    character_server TEXT
);
```

### configs Table

```sql
CREATE TABLE configs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    profile_id INTEGER,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    FOREIGN KEY (profile_id) REFERENCES profiles(id)
);
```

**Indexes**:
- Index on `profile_id` for faster lookups
- Index on `key` for configuration queries

---

## Data Conversion

### Entity to DTO

```java
// Profile entity to DTOProfiles
DTOProfiles dto = new DTOProfiles(
    profile.getId(),
    profile.getName(),
    profile.getEmulatorNumber(),
    profile.getEnabled(),
    profile.getPriority(),
    profile.getReconnectionTime()
);

// Load configs
List<Config> configs = profile.getConfigs();
List<DTOConfig> dtoConfigs = configs.stream()
    .map(c -> new DTOConfig(c.getProfile().getId(), c.getKey(), c.getValue()))
    .collect(Collectors.toList());
dto.setConfigs(dtoConfigs);
```

### DTO to Entity

```java
// DTOProfiles to Profile entity
Profile entity = new Profile();
entity.setId(dto.getId());
entity.setName(dto.getName());
entity.setEmulatorNumber(dto.getEmulatorNumber());
entity.setEnabled(dto.getEnabled());
entity.setPriority(dto.getPriority());
entity.setReconnectionTime(dto.getReconnectionTime());

// Convert configs
List<Config> configs = dto.getConfigs().stream()
    .map(dtoConfig -> {
        Config config = new Config();
        config.setProfile(entity);
        config.setKey(dtoConfig.getKey());
        config.setValue(dtoConfig.getValue());
        return config;
    })
    .collect(Collectors.toList());
entity.setConfigs(configs);
```

---

## Best Practices

### Configuration Access

```java
// Always provide default value
Boolean enabled = profile.getConfig(
    EnumConfigurationKey.MY_TASK_BOOL,
    Boolean.class
);
if (enabled == null) {
    enabled = false;  // Use default
}

// Or use helper method if available
Boolean enabled = profile.getConfigAsBoolean(
    EnumConfigurationKey.MY_TASK_BOOL
);
```

### Type Safety

```java
// Use type parameter
Integer value = profile.getConfig(
    EnumConfigurationKey.MY_TASK_INT,
    Integer.class
);

// Don't cast manually
// BAD: Integer value = (Integer) profile.getConfig(...);
```

### Configuration Updates

```java
// Set configuration
profile.setConfig(EnumConfigurationKey.MY_TASK_BOOL, true);

// Mark for save
shouldUpdateConfig = true;

// Save profile (in task.run() finally block)
if (shouldUpdateConfig) {
    ServProfiles.getServices().saveProfile(profile);
}
```

---

**Next**: See [08-configuration-reference.md](./08-configuration-reference.md) for complete configuration key reference.

