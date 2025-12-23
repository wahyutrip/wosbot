# Configuration Reference

Complete reference for all configuration keys in the WoS Bot project.

## Configuration System Overview

Configurations are stored as key-value pairs in the database. Each configuration key:
- Has a default value
- Has a specific type (Boolean, Integer, String, etc.)
- Can be profile-specific or global (profile_id = null)

## Accessing Configuration

```java
// Get configuration
Boolean value = profile.getConfig(
    EnumConfigurationKey.KEY_NAME,
    Boolean.class
);

// Set configuration
profile.setConfig(
    EnumConfigurationKey.KEY_NAME,
    true
);
```

## Configuration Categories

### System and Emulator Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `BOOL_DEBUG` | Boolean | `false` | Enable debug mode |
| `GAME_VERSION_STRING` | String | `"GLOBAL"` | Game version (GLOBAL, etc.) |
| `MAX_RUNNING_EMULATORS_INT` | Integer | `1` | Maximum concurrent emulators |
| `MAX_IDLE_TIME_INT` | Integer | `1` | Maximum idle time (minutes) |
| `IDLE_BEHAVIOR_STRING` | String | `"CLOSE_EMULATOR"` | Idle behavior: "CLOSE_EMULATOR", "SEND_TO_BACKGROUND", or "DO_NOTHING" |
| `MUMU_PATH_STRING` | String | `""` | MuMu Player executable path |
| `MEMU_PATH_STRING` | String | `""` | MEmu executable path |
| `LDPLAYER_PATH_STRING` | String | `""` | LDPlayer executable path |
| `CURRENT_EMULATOR_STRING` | String | `""` | Currently selected emulator type |
| `DISCORD_TOKEN_STRING` | String | `""` | Discord bot token (optional) |

---

### City and Building Management

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `CITY_UPGRADE_FURNACE_BOOL` | Boolean | `false` | Enable furnace upgrades |
| `CITY_ACCEPT_NEW_SURVIVORS_BOOL` | Boolean | `false` | Accept new survivors automatically |
| `CITY_ACCEPT_NEW_SURVIVORS_OFFSET_INT` | Integer | `60` | Delay before accepting survivors (minutes) |

---

### Resource Gathering and Management

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `GATHER_SPEED_BOOL` | Boolean | `false` | Enable gather speed boost |
| `GATHER_SPEED_BOOST_TYPE_STRING` | String | `"24h (600 gems)"` | Gather speed boost type |
| `GATHER_TASK_BOOL` | Boolean | `false` | Enable resource gathering |
| `GATHER_COAL_BOOL` | Boolean | `false` | Gather coal |
| `GATHER_WOOD_BOOL` | Boolean | `false` | Gather wood |
| `GATHER_MEAT_BOOL` | Boolean | `false` | Gather meat |
| `GATHER_IRON_BOOL` | Boolean | `false` | Gather iron |
| `GATHER_COAL_LEVEL_INT` | Integer | `8` | Minimum coal level |
| `GATHER_WOOD_LEVEL_INT` | Integer | `8` | Minimum wood level |
| `GATHER_MEAT_LEVEL_INT` | Integer | `8` | Minimum meat level |
| `GATHER_IRON_LEVEL_INT` | Integer | `8` | Minimum iron level |
| `GATHER_ACTIVE_MARCH_QUEUE_INT` | Integer | `6` | Active march queue size |
| `GATHER_REMOVE_HEROS_BOOL` | Boolean | `true` | Remove heroes from gather marches |

---

### Troop Training and Management

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TRAIN_BOOL` | Boolean | `false` | Enable troop training |
| `TRAIN_INFANTRY_BOOL` | Boolean | `false` | Train infantry |
| `TRAIN_MARKSMAN_BOOL` | Boolean | `false` | Train marksman |
| `TRAIN_LANCER_BOOL` | Boolean | `false` | Train lancers |
| `TRAIN_PRIORITIZE_PROMOTION_BOOL` | Boolean | `false` | Prioritize promotion over training |
| `TRAIN_MINISTRY_APPOINTMENT_BOOL` | Boolean | `false` | Use ministry appointment |
| `TRAIN_MINISTRY_APPOINTMENT_TIME_LONG` | Long | `0` | Ministry appointment time |
| `BOOL_TRAINING_RESOURCES` | Boolean | `false` | Check training resources |

---

### Intelligence Features

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `INTEL_BOOL` | Boolean | `false` | Enable intel collection |
| `INTEL_FIRE_BEAST_BOOL` | Boolean | `false` | Collect fire beast intel |
| `INTEL_BEASTS_BOOL` | Boolean | `false` | Collect beast intel |
| `INTEL_CAMP_BOOL` | Boolean | `false` | Collect camp intel |
| `INTEL_EXPLORATION_BOOL` | Boolean | `false` | Collect exploration intel |
| `INTEL_BEASTS_EVENT_BOOL` | Boolean | `false` | Collect beast event intel |
| `INTEL_BEASTS_FLAG_INT` | Integer | `1` | Beast intel flag |
| `INTEL_USE_FLAG_BOOL` | Boolean | `false` | Use flag for intel |
| `INTEL_FC_ERA_BOOL` | Boolean | `false` | Fire Crystal era intel |
| `INTEL_SMART_PROCESSING_BOOL` | Boolean | `false` | Smart intel processing |
| `INTEL_RECALL_GATHER_TROOPS_BOOL` | Boolean | `false` | Recall gather troops for intel |

---

### Alliance Features

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ALLIANCE_CHESTS_BOOL` | Boolean | `false` | Enable alliance chests |
| `ALLIANCE_CHESTS_OFFSET_INT` | Integer | `60` | Alliance chest delay (minutes) |
| `ALLIANCE_HONOR_CHEST_BOOL` | Boolean | `false` | Enable honor chests |
| `ALLIANCE_TECH_BOOL` | Boolean | `false` | Enable alliance tech |
| `ALLIANCE_TECH_OFFSET_INT` | Integer | `60` | Alliance tech delay (minutes) |
| `ALLIANCE_AUTOJOIN_BOOL` | Boolean | `false` | Auto-join alliance rallies |
| `ALLIANCE_AUTOJOIN_QUEUES_INT` | Integer | `1` | Auto-join queue count |
| `ALLIANCE_AUTOJOIN_USE_ALL_TROOPS_BOOL` | Boolean | `true` | Use all troops for auto-join |
| `ALLIANCE_AUTOJOIN_USE_PREDEFINED_FORMATION_BOOL` | Boolean | `false` | Use predefined formation |
| `ALLIANCE_PET_TREASURE_BOOL` | Boolean | `false` | Enable alliance pet treasure |
| `ALLIANCE_HELP_BOOL` | Boolean | `false` | Enable alliance help |
| `ALLIANCE_TRIUMPH_BOOL` | Boolean | `false` | Enable alliance triumph |
| `ALLIANCE_TRIUMPH_OFFSET_INT` | Integer | `60` | Alliance triumph delay (minutes) |
| `ALLIANCE_LIFE_ESSENCE_BOOL` | Boolean | `false` | Enable alliance life essence |
| `ALLIANCE_LIFE_ESSENCE_OFFSET_INT` | Integer | `60` | Life essence delay (minutes) |
| `ALLIANCE_MOBILIZATION_BOOL` | Boolean | `false` | Enable alliance mobilization |
| `ALLIANCE_MOBILIZATION_REWARDS_PERCENTAGE_STRING` | String | `"Any"` | Rewards percentage filter |
| `ALLIANCE_MOBILIZATION_BUILD_SPEEDUPS_BOOL` | Boolean | `false` | Use build speedups |
| `ALLIANCE_MOBILIZATION_BUY_PACKAGE_BOOL` | Boolean | `false` | Buy packages |
| `ALLIANCE_MOBILIZATION_CHIEF_GEAR_CHARM_BOOL` | Boolean | `false` | Chief gear charm |
| `ALLIANCE_MOBILIZATION_CHIEF_GEAR_SCORE_BOOL` | Boolean | `false` | Chief gear score |
| `ALLIANCE_MOBILIZATION_DEFEAT_BEASTS_BOOL` | Boolean | `false` | Defeat beasts |
| `ALLIANCE_MOBILIZATION_FIRE_CRYSTAL_BOOL` | Boolean | `false` | Fire Crystal |
| `ALLIANCE_MOBILIZATION_GATHER_RESOURCES_BOOL` | Boolean | `false` | Gather resources |
| `ALLIANCE_MOBILIZATION_HERO_GEAR_STONE_BOOL` | Boolean | `false` | Hero gear stone |
| `ALLIANCE_MOBILIZATION_MYTHIC_SHARD_BOOL` | Boolean | `false` | Mythic shard |
| `ALLIANCE_MOBILIZATION_RALLY_BOOL` | Boolean | `false` | Rally |
| `ALLIANCE_MOBILIZATION_TRAIN_TROOPS_BOOL` | Boolean | `false` | Train troops |
| `ALLIANCE_MOBILIZATION_TRAINING_SPEEDUPS_BOOL` | Boolean | `false` | Training speedups |
| `ALLIANCE_MOBILIZATION_USE_GEMS_BOOL` | Boolean | `false` | Use gems |
| `ALLIANCE_MOBILIZATION_USE_SPEEDUPS_BOOL` | Boolean | `false` | Use speedups |
| `ALLIANCE_MOBILIZATION_MINIMUM_POINTS_200_INT` | Integer | `800` | Minimum points (200%) |
| `ALLIANCE_MOBILIZATION_MINIMUM_POINTS_120_INT` | Integer | `520` | Minimum points (120%) |
| `ALLIANCE_MOBILIZATION_AUTO_ACCEPT_BOOL` | Boolean | `true` | Auto-accept mobilization |
| `ALLIANCE_MOBILIZATION_USE_GEMS_FOR_ACCEPT_BOOL` | Boolean | `false` | Use gems for accept |
| `ALLIANCE_CHAMPIONSHIP_BOOL` | Boolean | `false` | Enable alliance championship |
| `ALLIANCE_CHAMPIONSHIP_OVERRIDE_DEPLOY_BOOL` | Boolean | `false` | Override deploy |
| `ALLIANCE_CHAMPIONSHIP_INFANTRY_PERCENTAGE_INT` | Integer | `50` | Infantry percentage |
| `ALLIANCE_CHAMPIONSHIP_LANCERS_PERCENTAGE_INT` | Integer | `20` | Lancers percentage |
| `ALLIANCE_CHAMPIONSHIP_MARKSMANS_PERCENTAGE_INT` | Integer | `30` | Marksmans percentage |
| `ALLIANCE_CHAMPIONSHIP_POSITION_STRING` | String | `"CENTER"` | Deployment position |
| `ALLIANCE_SHOP_ENABLED_BOOL` | Boolean | `false` | Enable alliance shop |
| `ALLIANCE_SHOP_PRIORITIES_STRING` | String | `""` | Shop item priorities |
| `ALLIANCE_SHOP_MIN_PERCENTAGE_INT` | Integer | `50` | Minimum discount percentage |
| `ALLIANCE_SHOP_MIN_COINS_TO_ACTIVATE_INT` | Integer | `0` | Minimum coins to activate |
| `ALLIANCE_SHOP_MIN_COINS_INT` | Integer | `0` | Minimum coins required |

---

### Life Essence and Pets

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `LIFE_ESSENCE_BOOL` | Boolean | `false` | Enable life essence |
| `LIFE_ESSENCE_OFFSET_INT` | Integer | `60` | Life essence delay (minutes) |
| `LIFE_ESSENCE_BUY_WEEKLY_SCROLL_BOOL` | Boolean | `true` | Buy weekly scroll |
| `LIFE_ESSENCE_CONSECUTIVE_FAILURES_INT` | Integer | `0` | Consecutive failures count |
| `LIFE_ESSENCE_NEXT_SCROLL_TIME_STRING` | String | `""` | Next scroll time |
| `PET_SKILLS_BOOL` | Boolean | `false` | Enable pet skills |
| `PET_SKILL_STAMINA_BOOL` | Boolean | `false` | Pet skill: Stamina |
| `PET_SKILL_FOOD_BOOL` | Boolean | `false` | Pet skill: Food |
| `PET_SKILL_TREASURE_BOOL` | Boolean | `false` | Pet skill: Treasure |
| `PET_SKILL_GATHERING_BOOL` | Boolean | `false` | Pet skill: Gathering |
| `PET_PERSONAL_TREASURE_BOOL` | Boolean | `false` | Enable pet personal treasure |

---

### Daily Tasks and Missions

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `MAIL_REWARDS_BOOL` | Boolean | `false` | Enable mail rewards |
| `MAIL_REWARDS_OFFSET_INT` | Integer | `60` | Mail rewards delay (minutes) |
| `DAILY_MISSION_BOOL` | Boolean | `false` | Enable daily missions |
| `DAILY_MISSION_OFFSET_INT` | Integer | `60` | Daily mission delay (minutes) |
| `DAILY_MISSION_AUTO_SCHEDULE_BOOL` | Boolean | `false` | Auto-schedule daily missions |
| `STOREHOUSE_CHEST_BOOL` | Boolean | `false` | Enable storehouse chest |
| `STOREHOUSE_STAMINA_CLAIM_TIME_STRING` | String | `""` | Stamina claim time |
| `DAILY_LABYRINTH_BOOL` | Boolean | `false` | Enable daily labyrinth |
| `ARENA_TASK_ACTIVATION_TIME_STRING` | String | `"23:50"` | Arena activation time |
| `ARENA_TASK_BOOL` | Boolean | `false` | Enable arena task |
| `ARENA_TASK_EXTRA_ATTEMPTS_INT` | Integer | `0` | Extra arena attempts |
| `ARENA_TASK_REFRESH_WITH_GEMS_BOOL` | Boolean | `false` | Refresh with gems |
| `ARENA_TASK_PLAYER_STATE_INT` | Integer | `0` | Player state |

---

### Shops and Merchants

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `BOOL_NOMADIC_MERCHANT` | Boolean | `false` | Enable nomadic merchant |
| `BOOL_NOMADIC_MERCHANT_VIP_POINTS` | Boolean | `false` | Use VIP points for merchant |
| `WAR_ACADEMY_TASK_BOOL` | Boolean | `false` | Enable War Academy shards |
| `BOOL_CRYSTAL_LAB_FC` | Boolean | `false` | Enable Crystal Lab Fire Crystals |
| `BOOL_CRYSTAL_LAB_DAILY_DISCOUNTED_RFC` | Boolean | `false` | Buy daily discounted RFC |
| `INT_WEEKLY_RFC` | Integer | `0` | Weekly RFC target |
| `BOOL_EXPLORATION_CHEST` | Boolean | `false` | Enable exploration chest |
| `INT_EXPLORATION_CHEST_OFFSET` | Integer | `60` | Exploration chest delay (minutes) |
| `BOOL_HERO_RECRUITMENT` | Boolean | `false` | Enable hero recruitment |
| `BOOL_VIP_POINTS` | Boolean | `false` | Enable VIP points |
| `VIP_MONTHLY_BUY_BOOL` | Boolean | `false` | Buy monthly VIP |
| `VIP_NEXT_MONTHLY_BUY_TIME_STRING` | String | `""` | Next monthly buy time |
| `BOOL_MYSTERY_SHOP` | Boolean | `false` | Enable mystery shop |
| `BOOL_MYSTERY_SHOP_250_HERO_WIDGET` | Boolean | `false` | 250 hero widget |

---

### Bank Features

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `BOOL_BANK` | Boolean | `false` | Enable bank |
| `INT_BANK_DELAY` | Integer | `1` | Bank delay (minutes) |

---

### Events and Special Features

#### Chief Order

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `BOOL_CHIEF_ORDER_RUSH_JOB` | Boolean | `false` | Enable rush job |
| `BOOL_CHIEF_ORDER_URGENT_MOBILISATION` | Boolean | `false` | Enable urgent mobilization |
| `BOOL_CHIEF_ORDER_PRODUCTIVITY_DAY` | Boolean | `false` | Enable productivity day |

#### Tundra Events

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `TUNDRA_TRUCK_EVENT_BOOL` | Boolean | `false` | Enable Tundra Truck event |
| `TUNDRA_TRUCK_ACTIVATION_TIME_BOOL` | Boolean | `false` | Use activation time |
| `TUNDRA_TRUCK_USE_GEMS_BOOL` | Boolean | `false` | Use gems |
| `TUNDRA_TRUCK_SSR_BOOL` | Boolean | `false` | SSR mode |
| `TUNDRA_TRUCK_ACTIVATION_TIME_STRING` | String | `"14:00"` | Activation time |
| `TUNDRA_TREK_SUPPLIES_BOOL` | Boolean | `false` | Enable Trek supplies |
| `TUNDRA_TREK_AUTOMATION_BOOL` | Boolean | `false` | Enable Trek automation |

#### Polar Terror Hunting

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `POLAR_TERROR_ENABLED_BOOL` | Boolean | `false` | Enable Polar Terror hunting |
| `POLAR_TERROR_LEVEL_INT` | Integer | `1` | Terror level |
| `POLAR_TERROR_FLAG_STRING` | String | `"No Flag"` | Flag selection |
| `POLAR_TERROR_MODE_STRING` | String | `"Limited (10)"` | Hunting mode |

#### Other Events

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `MERCENARY_EVENT_BOOL` | Boolean | `false` | Enable mercenary event |
| `MERCENARY_FLAG_INT` | Integer | `0` | Mercenary flag |
| `HERO_MISSION_EVENT_BOOL` | Boolean | `false` | Enable hero mission event |
| `HERO_MISSION_FLAG_INT` | Integer | `0` | Hero mission flag |
| `JOURNEY_OF_LIGHT_BOOL` | Boolean | `false` | Enable Journey of Light |
| `MYRIAD_BAZAAR_EVENT_BOOL` | Boolean | `false` | Enable Myriad Bazaar |
| `BEAR_TRAP_EVENT_BOOL` | Boolean | `false` | Enable Bear Trap event |
| `BEAR_TRAP_RALLY_FLAG_INT` | Integer | `1` | Rally flag |
| `BEAR_TRAP_SCHEDULE_DATETIME_STRING` | LocalDateTime | `""` | Schedule datetime |
| `BEAR_TRAP_PREPARATION_TIME_INT` | Integer | `5` | Preparation time (minutes) |
| `BEAR_TRAP_ACTIVE_PETS_BOOL` | Boolean | `false` | Active pets |
| `BEAR_TRAP_NUMBER_INT` | Integer | `1` | Bear trap number |
| `BEAR_TRAP_RECALL_TROOPS_BOOL` | Boolean | `false` | Recall troops |
| `BEAR_TRAP_CALL_RALLY_BOOL` | Boolean | `false` | Call rally |
| `BEAR_TRAP_JOIN_RALLY_BOOL` | Boolean | `false` | Join rally |
| `BEAR_TRAP_JOIN_FLAG_INT` | Integer | `1` | Join flag |

---

### Expert Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `EXPERT_AGNES_INTEL_BOOL` | Boolean | `false` | Enable Expert Agnes intel |
| `EXPERT_ROMULUS_TAG_BOOL` | Boolean | `false` | Enable Expert Romulus tag |
| `EXPERT_ROMULUS_TROOPS_BOOL` | Boolean | `false` | Enable Expert Romulus troops |
| `EXPERT_ROMULUS_TROOPS_TYPE_STRING` | String | `"Infantry"` | Troop type |
| `EXPERT_SKILL_TRAINING_ENABLED_BOOL` | Boolean | `false` | Enable skill training |
| `EXPERT_SKILL_TRAINING_PRIORITIES_STRING` | String | `""` | Training priorities |

---

## Configuration Usage Patterns

### Boolean Configuration

```java
Boolean enabled = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_BOOL,
    Boolean.class
);

if (enabled != null && enabled) {
    // Task is enabled
}
```

### Integer Configuration

```java
Integer attempts = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_EXTRA_ATTEMPTS_INT,
    Integer.class
);

int attemptsValue = (attempts != null) ? attempts : 0;
```

### String Configuration

```java
String time = profile.getConfig(
    EnumConfigurationKey.ARENA_TASK_ACTIVATION_TIME_STRING,
    String.class
);

if (time == null || time.isEmpty()) {
    time = "23:50";  // Use default
}
```

### LocalDateTime Configuration

```java
LocalDateTime scheduleTime = profile.getConfig(
    EnumConfigurationKey.BEAR_TRAP_SCHEDULE_DATETIME_STRING,
    LocalDateTime.class
);
```

### Prioritized List Configuration

Some configurations store prioritized lists as strings:

```java
// Format: "name:priority:enabled|name:priority:enabled|..."
String priorities = profile.getConfig(
    EnumConfigurationKey.ALLIANCE_SHOP_PRIORITIES_STRING,
    String.class
);

// Parse: "Fire Crystals:1:true|VIP Points:2:true|Hero Shards:3:false"
```

---

## Adding New Configuration Keys

1. **Add to EnumConfigurationKey**:
```java
MY_NEW_CONFIG_BOOL("false", Boolean.class),
MY_NEW_CONFIG_INT("0", Integer.class),
```

2. **Use in Code**:
```java
Boolean value = profile.getConfig(
    EnumConfigurationKey.MY_NEW_CONFIG_BOOL,
    Boolean.class
);
```

3. **Add UI** (optional): Add configuration UI in `wos-hmi` module

---

**Next**: See [09-helper-classes.md](./09-helper-classes.md) for helper class documentation.

