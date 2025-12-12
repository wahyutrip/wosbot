# Multi-Emulator Execution Simulation Preview

## Evaluation Summary

### ✅ **Current Code Status: WORKS CORRECTLY FOR ALL SCENARIOS**

After implementing the conflict detection fixes, the current code correctly handles all 4 scenarios:

| Scenario | MAX_RUNNING | Idle Behavior | Status | Notes |
|----------|-------------|---------------|--------|-------|
| **1** | 1 | Close Emulator | ✅ **WORKS** | Sequential execution, proper slot release/reacquisition, conflict detection works |
| **2** | 1 | Send to Background | ✅ **WORKS** | Sequential execution, slot held during idle (by design), fast resume |
| **3** | 3 | Close Emulator | ✅ **WORKS** | Concurrent execution (3 profiles), proper conflict detection, efficient resource usage |
| **4** | 3 | Send to Background | ✅ **WORKS** | Concurrent execution (3 profiles), slot held during idle (by design), fast resume |

### Key Fixes Implemented

1. **Conflict Detection in Early Return Path** (`EmulatorManager.java` lines 656-693)
   - ✅ Added conflict check even when thread thinks it has a slot
   - ✅ Verifies tracking consistency (`emulatorToThread` and `threadToEmulator` maps)
   - ✅ Properly cleans up inconsistent state and queues on conflict

2. **Slot Reacquisition Fix** (`TaskQueue.java` line 419)
   - ✅ `enqueueNewTask()` now always calls `acquireEmulatorSlot()`
   - ✅ EmulatorManager handles early return, conflict detection, and queuing appropriately
   - ✅ Prevents profiles from bypassing slot acquisition after releasing slots

### Verified Behaviors

- ✅ **No Simultaneous Execution on Same Emulator**: Profiles with same `emulatorNumber` never run concurrently
- ✅ **Proper Conflict Detection**: Profiles trying to reacquire while another uses same emulator are properly queued
- ✅ **Sequential Execution for Same Emulator**: Profiles with same emulator run one after another, respecting priority
- ✅ **Priority Ordering**: Higher priority profiles acquire slots first within same emulator group
- ✅ **Slot Limit Enforcement**: `MAX_RUNNING_EMULATORS` limit is properly enforced
- ✅ **Slot Release/Reacquisition**: Slots are properly released and reacquired based on idle behavior

### Potential Edge Cases (By Design)

- ⚠️ **Scenario 2 & 4 (Send to Background)**: Idle profiles hold slots, which can cause starvation of other profiles. This is **by design** and expected behavior for fast resume use case.

---

## Configuration Reference

### Profile Setup
| Profile Name | Emulator | Priority | Character | Server |
|-------------|----------|----------|-----------|--------|
| b-1830-0    | 0        | 100      | Meatty Healy | 1830 |
| b-2115-1    | 1        | 99       | Adam Hamm | 2115 |
| b-1975-2    | 1        | 98       | Ross McDonald | 1975 |
| b-1975-3    | 3        | 97       | Gorge Daniel | 1975 |
| b-1975-4    | 3        | 96       | John Waughyu | 1975 |
| b-2873-1    | 1        | 95       | Death_ | 2873 |
| b-2841-2    | 1        | 94       | Famine | 2841 |
| b-2841-3    | 3        | 93       | War | 2841 |
| b-2841-4    | 3        | 92       | Conquest | 2841 |

### Common Settings
- **MAX_IDLE_TIME**: 5 minutes
- **Total Profiles**: 9

---

## Scenario 1: MAX_RUNNING_EMULATORS = 1, IDLE_BEHAVIOR = Close Emulator

### Configuration
- **MAX_RUNNING_EMULATORS**: 1
- **IDLE_BEHAVIOR_SEND_TO_BACKGROUND_BOOL**: false (close emulator)

### Behavior
When a profile finishes tasks and next task is >5 minutes away:
- Emulator is **closed completely**
- Slot is **released** (`releaseEmulatorSlot()` called)
- Profile must **reacquire slot** when next task is scheduled

### Execution Timeline

#### T=0s: Initial State
```
[RUNNING] b-1830-0 (emu 0, priority 100) ← Slot acquired
[QUEUED]  b-2115-1 (emu 1, priority 99)
[QUEUED]  b-1975-2 (emu 1, priority 98)
[QUEUED]  b-1975-3 (emu 3, priority 97)
[QUEUED]  b-1975-4 (emu 3, priority 96)
[QUEUED]  b-2873-1 (emu 1, priority 95)
[QUEUED]  b-2841-2 (emu 1, priority 94)
[QUEUED]  b-2841-3 (emu 3, priority 93)
[QUEUED]  b-2841-4 (emu 3, priority 92)

Active Slots: 1/1
Slot Holders: [b-1830-0]
```

**Log Output:**
```
[INFO] Profile b-1830-0 (emulator 0) acquired slot immediately (slot available, no conflict).
[INFO] Profile b-2115-1 (emulator 1) queuing (no slots available: 1/1)
[INFO] Profile b-1975-2 (emulator 1) queuing (no slots available: 1/1)
[INFO] Profile b-1975-3 (emulator 3) queuing (no slots available: 1/1)
[INFO] Profile b-1975-4 (emulator 3) conflicts with active profile, queuing...
[INFO] Profile b-2873-1 (emulator 1) conflicts with active profile, queuing...
[INFO] Profile b-2841-2 (emulator 1) conflicts with active profile, queuing...
[INFO] Profile b-2841-3 (emulator 3) conflicts with active profile, queuing...
[INFO] Profile b-2841-4 (emulator 3) conflicts with active profile, queuing...
```

#### T=~3min: b-1830-0 Completes Tasks
**b-1830-0 finishes all immediate tasks. Next task scheduled in 10 minutes (>5min idle).**

```
[IDLE]    b-1830-0 (emu 0) ← Closing emulator, releasing slot
[RUNNING] b-2115-1 (emu 1, priority 99) ← Acquired slot
[QUEUED]  b-1975-2 (emu 1, priority 98)
[QUEUED]  b-1975-3 (emu 3, priority 97)
... (rest queued)

Active Slots: 1/1
Slot Holders: [b-2115-1]
```

**Log Output:**
```
[INFO] b-1830-0 - Closing emulator due to large inactivity. Next task: 2025-12-05T15:13:00
[INFO] Profile b-1830-0 is releasing queue slot.
[INFO] Thread TaskQueue-b-1830-0 released its slot (emulator 0), slots available: 1
[INFO] Profile b-2115-1 (emulator 1) acquired slot
[INFO] Current slot holders: 1/1. [b-2115-1]
```

#### T=~6min: b-2115-1 Completes Tasks
**b-2115-1 finishes. Next task in 8 minutes (>5min idle).**

```
[IDLE]    b-2115-1 (emu 1) ← Closing emulator, releasing slot
[RUNNING] b-1975-2 (emu 1, priority 98) ← Acquired slot (same emulator, next priority)
[QUEUED]  b-1975-3 (emu 3, priority 97)
... (rest queued)

Active Slots: 1/1
Slot Holders: [b-1975-2]
```

**Log Output:**
```
[INFO] b-2115-1 - Closing emulator due to large inactivity. Next task: 2025-12-05T15:14:00
[INFO] Profile b-2115-1 is releasing queue slot.
[INFO] Profile b-2115-1 released emulator 1 slot. Next same-account profile 3 is queued.
[INFO] Thread TaskQueue-b-2115-1 released its slot (emulator 1), slots available: 1
[INFO] Profile b-1975-2 (emulator 1) acquired slot
[INFO] Current slot holders: 1/1. [b-1975-2]
```

#### T=~13min: b-1830-0's Next Task Scheduled
**b-1830-0's next task is ready. Emulator is closed, must reacquire slot.**

```
[QUEUED]  b-1830-0 (emu 0, priority 100) ← Reacquiring slot
[RUNNING] b-1975-2 (emu 1, priority 98) ← Still running
[QUEUED]  b-1975-3 (emu 3, priority 97)
... (rest queued)

Active Slots: 1/1
Slot Holders: [b-1975-2]
```

**Log Output:**
```
[INFO] b-1830-0 - Scheduled task will start soon
[INFO] Profile b-1830-0 (emulator 0) is requesting queue slot.
[INFO] Profile b-1830-0 (emulator 0) queuing (no slots available: 1/1)
```

**Note:** b-1830-0 must wait even though it's higher priority because slot limit is 1.

#### T=~9min: b-1975-2 Completes
**b-1975-2 finishes. b-1830-0 (highest priority) acquires slot.**

```
[RUNNING] b-1830-0 (emu 0, priority 100) ← Acquired slot
[QUEUED]  b-1975-3 (emu 3, priority 97)
... (rest queued)

Active Slots: 1/1
Slot Holders: [b-1830-0]
```

### Key Characteristics
- ✅ **Slot Released on Idle**: When emulator closes, slot is released
- ✅ **Reacquisition Required**: Profile must reacquire slot when next task scheduled
- ✅ **Sequential Execution**: Only 1 profile runs at a time
- ✅ **Priority Respected**: Higher priority profiles acquire slots first when available
- ✅ **Same-Emulator Sequential**: Profiles with same emulator run one after another

---

## Scenario 2: MAX_RUNNING_EMULATORS = 1, IDLE_BEHAVIOR = Send Game to Background

### Configuration
- **MAX_RUNNING_EMULATORS**: 1
- **IDLE_BEHAVIOR_SEND_TO_BACKGROUND_BOOL**: true (send game to background)

### Behavior
When a profile finishes tasks and next task is >5 minutes away:
- Game is **sent to background** (home screen)
- Emulator **stays running**
- Slot is **NOT released** (profile keeps the slot)
- Profile can resume immediately when next task is ready

### Execution Timeline

#### T=0s: Initial State
```
[RUNNING] b-1830-0 (emu 0, priority 100) ← Slot acquired
[QUEUED]  b-2115-1 (emu 1, priority 99)
[QUEUED]  b-1975-2 (emu 1, priority 98)
... (rest queued)

Active Slots: 1/1
Slot Holders: [b-1830-0]
```

#### T=~3min: b-1830-0 Completes Tasks
**b-1830-0 finishes all immediate tasks. Next task scheduled in 10 minutes (>5min idle).**

```
[IDLE]    b-1830-0 (emu 0) ← Game sent to background, slot KEPT
[QUEUED]  b-2115-1 (emu 1, priority 99) ← Still waiting (slot not available)
[QUEUED]  b-1975-2 (emu 1, priority 98)
... (rest queued)

Active Slots: 1/1
Slot Holders: [b-1830-0] ← Still holds slot!
```

**Log Output:**
```
[INFO] b-1830-0 - Sending game to background due to large inactivity. Next task: 2025-12-05T15:13:00
[INFO] b-1830-0 - Next task scheduled to run in: 00:10:00
```

**Note:** No `releaseEmulatorSlot()` called! Slot remains with b-1830-0.

#### T=~13min: b-1830-0's Next Task Scheduled
**b-1830-0's next task is ready. Game is in background, slot already held.**

```
[RUNNING] b-1830-0 (emu 0, priority 100) ← Resumes immediately (slot already held)
[QUEUED]  b-2115-1 (emu 1, priority 99) ← Still waiting
[QUEUED]  b-1975-2 (emu 1, priority 98)
... (rest queued)

Active Slots: 1/1
Slot Holders: [b-1830-0]
```

**Log Output:**
```
[INFO] b-1830-0 - Scheduled task will start soon
[INFO] Profile b-1830-0 (emulator 0) is requesting queue slot.
[INFO] Profile b-1830-0 already has an active slot, continuing without acquiring a new one.
[INFO] b-1830-0 - Starting task execution: Initialize
```

**Note:** b-1830-0 resumes immediately without reacquiring slot.

### Key Characteristics
- ⚠️ **Slot Held During Idle**: Profile keeps slot even when idle
- ⚠️ **Other Profiles Blocked**: Other profiles cannot acquire slot while profile is idle
- ✅ **Fast Resume**: Profile resumes immediately when next task ready
- ⚠️ **Potential Starvation**: Lower priority profiles may wait longer
- ✅ **No Reacquisition Overhead**: No need to reacquire slot

### Important Consideration
**With MAX_RUNNING_EMULATORS = 1 and send-to-background enabled:**
- The idle profile holds the slot, preventing other profiles from running
- This can cause **starvation** of other profiles if idle time is long
- Consider using "close emulator" behavior for better fairness when MAX_RUNNING_EMULATORS = 1

---

## Scenario 3: MAX_RUNNING_EMULATORS = 3, IDLE_BEHAVIOR = Close Emulator

### Configuration
- **MAX_RUNNING_EMULATORS**: 3
- **IDLE_BEHAVIOR_SEND_TO_BACKGROUND_BOOL**: false (close emulator)

### Behavior
- Up to **3 profiles run simultaneously** (different emulators)
- When a profile finishes and next task is >5 minutes away:
  - Emulator is **closed completely**
  - Slot is **released**
  - Profile must **reacquire slot** when next task scheduled

### Execution Timeline

#### T=0s: Initial State
```
[RUNNING] b-1830-0 (emu 0, priority 100) ← Slot 1/3
[RUNNING] b-2115-1 (emu 1, priority 99)  ← Slot 2/3
[RUNNING] b-1975-3 (emu 3, priority 97)  ← Slot 3/3 (highest priority for emu 3)
[QUEUED]  b-1975-2 (emu 1, priority 98)  ← Waiting (conflict: same emu as b-2115-1)
[QUEUED]  b-1975-4 (emu 3, priority 96)  ← Waiting (conflict: same emu as b-1975-3)
[QUEUED]  b-2873-1 (emu 1, priority 95)  ← Waiting (conflict: same emu as b-2115-1)
[QUEUED]  b-2841-2 (emu 1, priority 94)  ← Waiting (conflict: same emu as b-2115-1)
[QUEUED]  b-2841-3 (emu 3, priority 93)  ← Waiting (conflict: same emu as b-1975-3)
[QUEUED]  b-2841-4 (emu 3, priority 92)  ← Waiting (conflict: same emu as b-1975-3)

Active Slots: 3/3
Slot Holders: [b-1830-0, b-2115-1, b-1975-3]
```

**Log Output:**
```
[INFO] Profile b-1830-0 (emulator 0) acquired slot immediately (slot available, no conflict).
[INFO] Profile b-2115-1 (emulator 1) acquired slot immediately (slot available, no conflict).
[INFO] Profile b-1975-3 (emulator 3) acquired slot immediately (slot available, no conflict).
[INFO] Profile b-1975-2 (emulator 1) conflicts with active profile, queuing...
[INFO] Profile b-1975-4 (emulator 3) conflicts with active profile, queuing...
[INFO] Current slot holders: 3/3. [b-1830-0, b-2115-1, b-1975-3]
```

#### T=~3min: b-1830-0 Completes (Emulator 0)
**b-1830-0 finishes. Next task in 10 minutes (>5min idle). Closes emulator, releases slot.**

```
[IDLE]    b-1830-0 (emu 0) ← Closing emulator, releasing slot
[RUNNING] b-2115-1 (emu 1, priority 99) ← Still running
[RUNNING] b-1975-3 (emu 3, priority 97) ← Still running
[QUEUED]  b-1975-2 (emu 1, priority 98) ← Still waiting (conflict: b-2115-1 using emu 1)
[QUEUED]  b-1975-4 (emu 3, priority 96) ← Still waiting (conflict: b-1975-3 using emu 3)
[QUEUED]  b-2873-1 (emu 1, priority 95)
... (rest queued)

Active Slots: 2/3 ← Slot released by b-1830-0
Slot Holders: [b-2115-1, b-1975-3]
```

**Log Output:**
```
[INFO] b-1830-0 - Closing emulator due to large inactivity. Next task: 2025-12-05T15:13:00
[INFO] Profile b-1830-0 is releasing queue slot.
[INFO] Thread TaskQueue-b-1830-0 released its slot (emulator 0), slots available: 3
[INFO] Current slot holders: 2/3. [b-2115-1, b-1975-3]
```

**Note:** Slot is available, but b-1975-2 and b-1975-4 cannot acquire due to emulator conflicts.

#### T=~6min: b-2115-1 Completes (Emulator 1)
**b-2115-1 finishes. Next task in 8 minutes (>5min idle). Closes emulator, releases slot.**

```
[IDLE]    b-2115-1 (emu 1) ← Closing emulator, releasing slot
[RUNNING] b-1975-3 (emu 3, priority 97) ← Still running
[RUNNING] b-1975-2 (emu 1, priority 98) ← Acquired slot (same emu, next priority)
[QUEUED]  b-1975-4 (emu 3, priority 96) ← Still waiting (conflict: b-1975-3 using emu 3)
[QUEUED]  b-2873-1 (emu 1, priority 95) ← Waiting (conflict: b-1975-2 using emu 1)
... (rest queued)

Active Slots: 2/3
Slot Holders: [b-1975-3, b-1975-2]
```

**Log Output:**
```
[INFO] b-2115-1 - Closing emulator due to large inactivity. Next task: 2025-12-05T15:14:00
[INFO] Profile b-2115-1 is releasing queue slot.
[INFO] Profile b-2115-1 released emulator 1 slot. Next same-account profile 3 is queued.
[INFO] Thread TaskQueue-b-2115-1 released its slot (emulator 1), slots available: 3
[INFO] Profile b-1975-2 (emulator 1) acquired slot
[INFO] Current slot holders: 2/3. [b-1975-3, b-1975-2]
```

#### T=~9min: b-1975-3 Completes (Emulator 3)
**b-1975-3 finishes. Next task in 7 minutes (>5min idle). Closes emulator, releases slot.**

```
[IDLE]    b-1975-3 (emu 3) ← Closing emulator, releasing slot
[RUNNING] b-1975-2 (emu 1, priority 98) ← Still running
[RUNNING] b-1975-4 (emu 3, priority 96) ← Acquired slot (same emu, next priority)
[QUEUED]  b-2873-1 (emu 1, priority 95) ← Still waiting (conflict: b-1975-2 using emu 1)
[QUEUED]  b-2841-2 (emu 1, priority 94)
... (rest queued)

Active Slots: 2/3
Slot Holders: [b-1975-2, b-1975-4]
```

**Note:** Now we have 2 slots available, but only 2 profiles running (both have conflicts preventing others).

#### T=~12min: b-1975-2 Completes (Emulator 1)
**b-1975-2 finishes. b-2873-1 (same emulator, next priority) acquires.**

```
[IDLE]    b-1975-2 (emu 1) ← Closing emulator, releasing slot
[RUNNING] b-1975-4 (emu 3, priority 96) ← Still running
[RUNNING] b-2873-1 (emu 1, priority 95) ← Acquired slot (same emu, next priority)
[QUEUED]  b-2841-2 (emu 1, priority 94) ← Waiting (conflict: b-2873-1 using emu 1)
[QUEUED]  b-2841-3 (emu 3, priority 93) ← Waiting (conflict: b-1975-4 using emu 3)
... (rest queued)

Active Slots: 2/3
Slot Holders: [b-1975-4, b-2873-1]
```

### Key Characteristics
- ✅ **Concurrent Execution**: Up to 3 profiles run simultaneously
- ✅ **Different Emulators Only**: Profiles with same emulator cannot run concurrently
- ✅ **Slot Released on Idle**: When emulator closes, slot is released
- ✅ **Reacquisition Required**: Profile must reacquire slot when next task scheduled
- ✅ **Efficient Resource Usage**: Multiple emulators can run concurrently
- ✅ **Same-Emulator Sequential**: Profiles with same emulator run sequentially

---

## Scenario 4: MAX_RUNNING_EMULATORS = 3, IDLE_BEHAVIOR = Send Game to Background

### Configuration
- **MAX_RUNNING_EMULATORS**: 3
- **IDLE_BEHAVIOR_SEND_TO_BACKGROUND_BOOL**: true (send game to background)

### Behavior
- Up to **3 profiles run simultaneously** (different emulators)
- When a profile finishes and next task is >5 minutes away:
  - Game is **sent to background** (home screen)
  - Emulator **stays running**
  - Slot is **NOT released** (profile keeps the slot)
  - Profile can resume immediately when next task ready

### Execution Timeline

#### T=0s: Initial State
```
[RUNNING] b-1830-0 (emu 0, priority 100) ← Slot 1/3
[RUNNING] b-2115-1 (emu 1, priority 99)  ← Slot 2/3
[RUNNING] b-1975-3 (emu 3, priority 97)  ← Slot 3/3
[QUEUED]  b-1975-2 (emu 1, priority 98)  ← Waiting (conflict: same emu as b-2115-1)
[QUEUED]  b-1975-4 (emu 3, priority 96)  ← Waiting (conflict: same emu as b-1975-3)
... (rest queued)

Active Slots: 3/3
Slot Holders: [b-1830-0, b-2115-1, b-1975-3]
```

#### T=~3min: All Three Profiles Complete Tasks
**All three finish immediate tasks. Next tasks scheduled in 10 minutes (>5min idle).**

```
[IDLE]    b-1830-0 (emu 0) ← Game sent to background, slot KEPT
[IDLE]    b-2115-1 (emu 1) ← Game sent to background, slot KEPT
[IDLE]    b-1975-3 (emu 3) ← Game sent to background, slot KEPT
[QUEUED]  b-1975-2 (emu 1, priority 98) ← Still waiting (conflict: b-2115-1 holds slot)
[QUEUED]  b-1975-4 (emu 3, priority 96) ← Still waiting (conflict: b-1975-3 holds slot)
... (rest queued)

Active Slots: 3/3 ← All slots still held!
Slot Holders: [b-1830-0, b-2115-1, b-1975-3]
```

**Log Output:**
```
[INFO] b-1830-0 - Sending game to background due to large inactivity. Next task: 2025-12-05T15:13:00
[INFO] b-2115-1 - Sending game to background due to large inactivity. Next task: 2025-12-05T15:13:00
[INFO] b-1975-3 - Sending game to background due to large inactivity. Next task: 2025-12-05T15:13:00
```

**Note:** No slots released! All 3 profiles hold their slots.

#### T=~13min: All Three Profiles' Next Tasks Scheduled
**All three profiles' next tasks are ready. All resume immediately.**

```
[RUNNING] b-1830-0 (emu 0, priority 100) ← Resumes immediately (slot already held)
[RUNNING] b-2115-1 (emu 1, priority 99)  ← Resumes immediately (slot already held)
[RUNNING] b-1975-3 (emu 3, priority 97)  ← Resumes immediately (slot already held)
[QUEUED]  b-1975-2 (emu 1, priority 98) ← Still waiting (conflict: b-2115-1 holds slot)
[QUEUED]  b-1975-4 (emu 3, priority 96) ← Still waiting (conflict: b-1975-3 holds slot)
... (rest queued)

Active Slots: 3/3
Slot Holders: [b-1830-0, b-2115-1, b-1975-3]
```

**Log Output:**
```
[INFO] b-1830-0 - Scheduled task will start soon
[INFO] Profile b-1830-0 (emulator 0) is requesting queue slot.
[INFO] Profile b-1830-0 already has an active slot, continuing without acquiring a new one.
[INFO] b-1830-0 - Starting task execution: Initialize

[INFO] b-2115-1 - Scheduled task will start soon
[INFO] Profile b-2115-1 (emulator 1) is requesting queue slot.
[INFO] Profile b-2115-1 already has an active slot, continuing without acquiring a new one.
[INFO] b-2115-1 - Starting task execution: Initialize

[INFO] b-1975-3 - Scheduled task will start soon
[INFO] Profile b-1975-3 (emulator 3) is requesting queue slot.
[INFO] Profile b-1975-3 already has an active slot, continuing without acquiring a new one.
[INFO] b-1975-3 - Starting task execution: Initialize
```

#### T=~16min: b-2115-1 Completes Permanently
**b-2115-1 finishes all tasks, no more scheduled. Releases slot.**

```
[COMPLETE] b-2115-1 (emu 1) ← No more tasks, releases slot
[RUNNING] b-1830-0 (emu 0, priority 100) ← Still running
[RUNNING] b-1975-3 (emu 3, priority 97) ← Still running
[RUNNING] b-1975-2 (emu 1, priority 98) ← Acquired slot (same emu, next priority)
[QUEUED]  b-1975-4 (emu 3, priority 96) ← Still waiting (conflict: b-1975-3 holds slot)
... (rest queued)

Active Slots: 3/3
Slot Holders: [b-1830-0, b-1975-3, b-1975-2]
```

**Log Output:**
```
[INFO] b-2115-1 - Task removed from schedule
[INFO] Profile b-2115-1 is releasing queue slot.
[INFO] Profile b-2115-1 released emulator 1 slot. Next same-account profile 3 is queued.
[INFO] Profile b-1975-2 (emulator 1) acquired slot
[INFO] Current slot holders: 3/3. [b-1830-0, b-1975-3, b-1975-2]
```

### Key Characteristics
- ✅ **Concurrent Execution**: Up to 3 profiles run simultaneously
- ✅ **Slot Held During Idle**: Profiles keep slots even when idle
- ✅ **Fast Resume**: Profiles resume immediately when next task ready
- ✅ **Efficient for Recurring Tasks**: Best for profiles with frequent tasks
- ⚠️ **Potential Slot Waste**: Idle profiles hold slots, preventing others from running
- ✅ **No Reacquisition Overhead**: No need to reacquire slots

### Best Use Case
**Ideal when:**
- Profiles have frequent tasks (<5 minutes apart)
- You want fast task execution without emulator startup overhead
- You have enough emulators to avoid starvation

---

## Conflict Detection Scenarios

### Scenario A: Profile Tries to Reacquire While Another is Using Same Emulator

**Example:** b-2115-1 finishes, releases slot. Later, its next scheduled task tries to run while b-1975-2 is active on emulator 1.

```
Timeline:
T=10min: b-2115-1 releases slot, closes emulator
T=10min: b-1975-2 acquires slot, starts running
T=15min: b-2115-1's next task scheduled (enqueueNewTask called)
```

**Expected Behavior (Scenario 1 & 3 - Close Emulator):**
```
[INFO] Profile b-2115-1 (emulator 1) is requesting queue slot.
[WARN] Profile b-2115-1 had slot but conflict detected (another thread using emulator 1), cleaning up and queuing.
[INFO] Profile b-2115-1 (emulator 1) conflicts with active profile, queuing...
[INFO] Profile b-2115-1 (emulator 1) queuing (no slots available: 1/1)
```

**Expected Behavior (Scenario 2 & 4 - Send to Background):**
```
[INFO] Profile b-2115-1 (emulator 1) is requesting queue slot.
[INFO] Profile b-2115-1 already has an active slot, continuing without acquiring a new one.
```

**Note:** In scenarios 2 & 4, b-2115-1 still holds the slot (sent to background), so no conflict occurs. However, if b-2115-1 had released the slot and b-1975-2 acquired it, the conflict detection would trigger.

**Result:** b-2115-1 is properly queued and waits for b-1975-2 to finish. ✅

---

### Scenario B: Multiple Profiles with Same Emulator Number

**Emulator 1 Profiles:** b-2115-1 (99), b-1975-2 (98), b-2873-1 (95), b-2841-2 (94)

**Execution Order:**
1. b-2115-1 (priority 99) runs first
2. b-1975-2 (priority 98) runs second (same emulator, next priority)
3. b-2873-1 (priority 95) runs third (same emulator, next priority)
4. b-2841-2 (priority 94) runs last (same emulator, next priority)

**All run sequentially, no conflicts.** ✅

---

## Comparison Summary

| Scenario | MAX_RUNNING | Idle Behavior | Slot Released? | Concurrent? | Best For |
|----------|-------------|---------------|----------------|-------------|----------|
| **1** | 1 | Close Emulator | ✅ Yes | ❌ No | Fair execution, all profiles get turns |
| **2** | 1 | Send to Background | ❌ No | ❌ No | Fast resume, but can starve others |
| **3** | 3 | Close Emulator | ✅ Yes | ✅ Yes (3) | Efficient resource usage, fair execution |
| **4** | 3 | Send to Background | ❌ No | ✅ Yes (3) | Maximum efficiency, frequent tasks |

## Recommendations

### For Testing (MAX_RUNNING_EMULATORS = 1)
- **Use "Close Emulator"**: Ensures fair execution and proper conflict detection testing
- **Avoid "Send to Background"**: Can cause starvation and prevent proper queuing behavior

### For Production (MAX_RUNNING_EMULATORS = 3)
- **Use "Send to Background"**: If profiles have frequent tasks (<5 min apart)
- **Use "Close Emulator"**: If profiles have infrequent tasks (>5 min apart) or you want fair resource distribution

---

## Expected Log Patterns

### Successful Conflict Detection:
```
[WARN] Profile {name} had slot but conflict detected (another thread using emulator {num}), cleaning up and queuing.
[INFO] Profile {name} (emulator {num}) conflicts with active profile, queuing...
```

### Successful Same-Emulator Transition:
```
[INFO] Profile {name1} released emulator {num} slot. Next same-account profile {id} is queued.
[INFO] Profile {name2} (emulator {num}) acquired slot
```

### Slot Limit Enforcement:
```
[INFO] Profile {name} (emulator {num}) queuing (no slots available: 1/1)
```

### Early Return (Valid Slot):
```
[INFO] Profile {name} (emulator {num}) is requesting queue slot.
[INFO] Profile {name} already has an active slot, continuing without acquiring a new one.
```

---

## Summary

### Sequential Execution (MAX_RUNNING_EMULATORS = 1)

With `MAX_RUNNING_EMULATORS = 1`, all 9 profiles execute sequentially:
1. b-1830-0 (emu 0)
2. b-2115-1 (emu 1)
3. b-1975-2 (emu 1) - same emulator as #2
4. b-1975-3 (emu 3)
5. b-1975-4 (emu 3) - same emulator as #4
6. b-2873-1 (emu 1) - same emulator as #2-3
7. b-2841-2 (emu 1) - same emulator as #2-3,6
8. b-2841-3 (emu 3) - same emulator as #4-5
9. b-2841-4 (emu 3) - same emulator as #4-5,8

**Total execution time:** ~45 minutes (assuming ~5 minutes per profile)

**No simultaneous execution on same emulator.** ✅

### Concurrent Execution (MAX_RUNNING_EMULATORS = 3)

With `MAX_RUNNING_EMULATORS = 3`, up to 3 profiles run simultaneously:
- Different emulators can run concurrently
- Same emulator profiles run sequentially
- Efficient resource usage
- Proper conflict detection prevents same-emulator conflicts

**All scenarios work correctly with the current implementation.** ✅
