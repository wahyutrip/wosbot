# Multi-Emulator Support with Account-Based Conflict Detection - Requirements Document

## 1. Overview

### 1.1 Purpose
This feature enables the WoS Bot to support running multiple emulators simultaneously while preventing conflicts when multiple characters from the same account attempt to run concurrently. The system uses emulator number as the account identifier, ensuring that characters from the same account run sequentially on the same emulator.

### 1.2 Business Context
- **User Scenario**: User has 3 accounts with 9 total characters (3 characters per account)
- **Constraint**: Multiple emulators can run simultaneously (e.g., emulators 0, 1, 3)
- **Requirement**: Prevent multiple characters from the same account from running simultaneously
- **Requirement**: When a character finishes, the next character from the same account should acquire the same emulator slot (if available)

### 1.3 Key Assumptions
1. **1 account = 1 emulator**: One account is identified by one emulator number. All profiles with the same `emulatorNumber` belong to the same account.
2. **1 character = 1 profile**: Each character is represented by one profile.
3. **No accountId field**: Account identification is done via `emulatorNumber` - no new database field needed.
4. **Fixed emulator assignment**: Profiles must always use their configured `emulatorNumber` - cannot use any available emulator.
5. **Sequential execution**: When multiple profiles from the same account are queued, they run sequentially on the same emulator, ordered by priority (highest to lowest).

### 1.4 Example Scenario
**Setup**:
- Account 1 (emulator 0): b-1830-0 (priority 100)
- Account 2 (emulator 1): b-2115-1 (priority 99), b-1975-2 (priority 98)
- Account 3 (emulator 3): b-1975-3 (priority 97), b-1975-4 (priority 96)

**Running State**:
- b-1830-0 running on emulator 0
- b-2115-1 running on emulator 1
- b-1975-3 running on emulator 3

**When b-1975-3 finishes**:
- b-1975-4 (next from same account, emulator 3) should acquire emulator 3 slot
- If b-2115-1 finishes, b-1975-2 (next from same account, emulator 1) should acquire emulator 1 slot

---

## 2. Requirements

### 2.1 Functional Requirements

#### FR1: Account Identification
- **FR1.1**: Account identification is done via `emulatorNumber` field in Profile
- **FR1.2**: All profiles with the same `emulatorNumber` belong to the same account
- **FR1.3**: No new database fields or accountId are required
- **FR1.4**: Account grouping is implicit based on `emulatorNumber` value

#### FR2: Emulator-Based Conflict Detection
- **FR2.1**: Before acquiring an emulator slot, check if any other profile with the same `emulatorNumber` is already running
- **FR2.2**: If a conflict is detected (same `emulatorNumber` already active), the requesting profile must wait in queue
- **FR2.3**: Conflict detection must be thread-safe and atomic
- **FR2.4**: Only one profile per `emulatorNumber` can be active at any time

#### FR3: Emulator Slot Tracking
- **FR3.1**: Track which `emulatorNumber` values are currently in use
- **FR3.2**: Track which thread is using which `emulatorNumber`
- **FR3.3**: When a profile releases a slot, update the tracking to free the `emulatorNumber`
- **FR3.4**: Slot tracking must be thread-safe

#### FR4: Priority-Based Queueing
- **FR4.1**: When multiple profiles from the same account (same `emulatorNumber`) are queued, they must be ordered by priority (highest to lowest)
- **FR4.2**: If priorities are equal, use arrival time (first-come-first-served)
- **FR4.3**: The queue must maintain priority order across all profiles, not just within the same account
- **FR4.4**: Queue position updates must reflect the current position considering all queued profiles

#### FR5: Smart Slot Assignment
- **FR5.1**: When a profile finishes and releases a slot, check if there are other profiles with the same `emulatorNumber` waiting in queue
- **FR5.2**: If profiles from the same account are waiting, prioritize them for the same emulator slot
- **FR5.3**: If no profiles from the same account are waiting, allow any waiting profile to acquire the slot (based on priority)
- **FR5.4**: Slot assignment must respect `MAX_RUNNING_EMULATORS` limit

#### FR6: Emulator Number Validation
- **FR6.1**: Profile must always use its configured `emulatorNumber` - cannot be reassigned
- **FR6.2**: When acquiring a slot, verify that the profile's `emulatorNumber` matches the emulator being used
- **FR6.3**: If emulator number mismatch is detected, log error and reject slot acquisition

### 2.2 Non-Functional Requirements

#### NFR1: Thread Safety
- All slot management operations must be thread-safe
- Use existing `ReentrantLock` mechanism
- Ensure atomic operations for conflict detection and slot assignment

#### NFR2: Performance
- Conflict detection should be O(1) or O(n) where n = number of active slots
- Queue operations should maintain O(log n) complexity for priority queue
- No significant performance degradation compared to current implementation

#### NFR3: Backward Compatibility
- Existing profiles without conflicts should continue to work
- No breaking changes to existing APIs
- Existing queue position callbacks must continue to work

#### NFR4: Logging
- Log when conflicts are detected
- Log when profiles from same account are queued
- Log when slots are assigned to profiles from the same account
- Include emulator number in all relevant log messages

---

## 3. Technical Design

### 3.1 Data Structure Changes

#### 3.1.1 EmulatorManager Fields
Add new tracking structures to `EmulatorManager`:

```java
// Map: emulatorNumber -> Thread (tracks which thread is using which emulator)
private final Map<String, Thread> emulatorToThread = new HashMap<>();

// Map: Thread -> emulatorNumber (reverse lookup)
private final Map<Thread, String> threadToEmulator = new HashMap<>();
```

**Rationale**: 
- Need to track which emulator number each active thread is using
- Need reverse lookup to find emulator number when thread releases slot
- Both maps maintained for O(1) lookups in both directions

#### 3.1.2 WaitingThread Enhancement
Add `emulatorNumber` field to `WaitingThread`:

```java
public class WaitingThread implements Comparable<WaitingThread> {
    final Thread thread;
    final Long priority;
    final Long arrivalTime;
    final Long profileId;
    final String emulatorNumber;  // NEW FIELD
    
    public WaitingThread(Thread thread, DTOProfiles profile) {
        this.thread = thread;
        this.priority = profile.getPriority();
        this.profileId = profile.getId();
        this.arrivalTime = System.nanoTime();
        this.emulatorNumber = profile.getEmulatorNumber();  // NEW
    }
    
    public String getEmulatorNumber() {
        return emulatorNumber;
    }
}
```

**Rationale**: 
- Need emulator number in queue entries to check for conflicts
- Enables filtering queue by emulator number for smart assignment

### 3.2 Algorithm Changes

#### 3.2.1 Slot Acquisition Algorithm
**Current Flow**:
```
1. Check if thread already has slot
2. If slot available and queue empty → acquire immediately
3. Otherwise, add to queue and wait
4. When at front of queue and slot available → acquire
```

**New Flow**:
```
1. Check if thread already has slot
2. Check if another profile with same emulatorNumber is already active
   - If yes → add to queue and wait
   - If no → continue
3. If slot available and queue empty → acquire immediately
4. Otherwise, add to queue and wait
5. When at front of queue:
   a. Check if slot available (respecting MAX_RUNNING_EMULATORS)
   b. Check if another profile with same emulatorNumber is already active
   c. If both checks pass → acquire slot
   d. Otherwise → continue waiting
```

**Key Changes**:
- Add conflict check before immediate acquisition
- Add conflict check before acquiring from queue
- Track emulator number when slot is acquired

#### 3.2.2 Slot Release Algorithm
**Current Flow**:
```
1. Remove thread from activeSlots
2. Signal all waiting threads
```

**New Flow**:
```
1. Get emulatorNumber for this thread
2. Remove thread from activeSlots
3. Remove emulatorNumber from emulatorToThread
4. Remove thread from threadToEmulator
5. Check if any profiles with same emulatorNumber are waiting in queue
   - If yes → prioritize them (they should be next to acquire)
6. Signal all waiting threads
```

**Key Changes**:
- Update emulator tracking maps
- Check for same-account profiles in queue
- Prioritize same-account profiles (handled by queue order)

#### 3.2.3 Conflict Detection Method
```java
/**
 * Checks if another profile with the same emulatorNumber is already active.
 * 
 * @param emulatorNumber The emulator number to check
 * @param currentThread The current thread (to exclude from check)
 * @return true if conflict exists, false otherwise
 */
private boolean hasEmulatorConflict(String emulatorNumber, Thread currentThread) {
    Thread activeThread = emulatorToThread.get(emulatorNumber);
    if (activeThread == null) {
        return false; // No conflict
    }
    // Conflict exists if another thread (not current) is using this emulator
    return !activeThread.equals(currentThread);
}
```

#### 3.2.4 Smart Queue Filtering
When a slot is released, check for same-account profiles:

```java
/**
 * Finds the next waiting profile with the same emulatorNumber.
 * Since queue is priority-ordered, the first match is the highest priority.
 * 
 * @param emulatorNumber The emulator number to search for
 * @return The next WaitingThread with matching emulatorNumber, or null
 */
private WaitingThread findNextSameAccountProfile(String emulatorNumber) {
    return waitingQueue.stream()
        .filter(wt -> emulatorNumber.equals(wt.getEmulatorNumber()))
        .findFirst()
        .orElse(null);
}
```

### 3.3 Modified Methods

#### 3.3.1 `adquireEmulatorSlot()` Modifications
**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Changes**:
1. Add conflict check before immediate acquisition (after line 641)
2. Add conflict check in wait loop (line 657)
3. Update emulator tracking maps when slot acquired (after line 672)

**Pseudocode**:
```java
public void adquireEmulatorSlot(DTOProfiles profile, PositionCallback callback) throws InterruptedException {
    Thread currentThread = Thread.currentThread();
    String emulatorNumber = profile.getEmulatorNumber();
    lock.lock();
    try {
        // ... existing thread check ...
        
        // NEW: Check for emulator conflict
        if (hasEmulatorConflict(emulatorNumber, currentThread)) {
            logger.info("Profile {} (emulator {}) conflicts with active profile, queuing...", 
                profile.getName(), emulatorNumber);
            // Add to queue and wait
        }
        
        // If slot available and no conflict and queue empty → acquire immediately
        if (activeSlots.size() < MAX_RUNNING_EMULATORS 
            && !hasEmulatorConflict(emulatorNumber, currentThread) 
            && waitingQueue.isEmpty()) {
            // Acquire slot
            activeSlots.add(currentThread);
            emulatorToThread.put(emulatorNumber, currentThread);  // NEW
            threadToEmulator.put(currentThread, emulatorNumber);  // NEW
            return;
        }
        
        // Add to queue
        WaitingThread currentWaiting = new WaitingThread(currentThread, profile);
        waitingQueue.add(currentWaiting);
        
        // Wait loop with conflict check
        while (waitingQueue.peek() != currentWaiting 
            || activeSlots.size() >= MAX_RUNNING_EMULATORS
            || hasEmulatorConflict(emulatorNumber, currentThread)) {  // NEW
            permitsAvailable.await(1, TimeUnit.SECONDS);
            // ... position update ...
        }
        
        // Acquire slot
        waitingQueue.poll();
        activeSlots.add(currentThread);
        emulatorToThread.put(emulatorNumber, currentThread);  // NEW
        threadToEmulator.put(currentThread, emulatorNumber);  // NEW
    } finally {
        lock.unlock();
    }
}
```

#### 3.3.2 `releaseEmulatorSlot()` Modifications
**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Changes**:
1. Get emulator number from thread
2. Remove from emulator tracking maps
3. Check for same-account profiles in queue (optional optimization)

**Pseudocode**:
```java
public void releaseEmulatorSlot(DTOProfiles profile) {
    Thread currentThread = Thread.currentThread();
    lock.lock();
    try {
        // Get emulator number for this thread
        String emulatorNumber = threadToEmulator.get(currentThread);
        
        // Remove from active slots
        if (activeSlots.remove(currentThread)) {
            // Remove from emulator tracking
            if (emulatorNumber != null) {
                emulatorToThread.remove(emulatorNumber);
                threadToEmulator.remove(currentThread);
                
                // Optional: Check if same-account profiles are waiting
                WaitingThread nextSameAccount = findNextSameAccountProfile(emulatorNumber);
                if (nextSameAccount != null) {
                    logger.info("Profile {} released emulator {} slot. Next same-account profile {} is queued.", 
                        profile.getName(), emulatorNumber, nextSameAccount.getProfileId());
                }
            }
        }
        
        // Signal all waiting threads
        permitsAvailable.signalAll();
    } finally {
        lock.unlock();
    }
}
```

#### 3.3.3 `resetQueueState()` Modifications
**Location**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Changes**:
1. Clear emulator tracking maps

**Pseudocode**:
```java
public void resetQueueState() {
    lock.lock();
    try {
        waitingQueue.clear();
        activeSlots.clear();
        emulatorToThread.clear();  // NEW
        threadToEmulator.clear();  // NEW
        permitsAvailable.signalAll();
    } finally {
        lock.unlock();
    }
}
```

### 3.4 Queue Ordering

The existing `PriorityQueue<WaitingThread>` with `WaitingThread.compareTo()` already handles priority ordering. The queue will naturally order profiles by:
1. Priority (highest first)
2. Arrival time (if priorities equal)

**No changes needed** - the queue already maintains correct order. Profiles from the same account will be grouped together if they have similar priorities, but global priority ordering is maintained.

---

## 4. Implementation Plan

### 4.1 Phase 1: Data Structure Updates
1. Add `emulatorNumber` field to `WaitingThread`
2. Add emulator tracking maps to `EmulatorManager`
3. Update `WaitingThread` constructor and getter

**Estimated Time**: 1-2 hours

### 4.2 Phase 2: Conflict Detection
1. Implement `hasEmulatorConflict()` method
2. Add conflict check to `adquireEmulatorSlot()` before immediate acquisition
3. Add conflict check to wait loop in `adquireEmulatorSlot()`
4. Update emulator tracking when slot acquired

**Estimated Time**: 2-3 hours

### 4.3 Phase 3: Slot Release Updates
1. Update `releaseEmulatorSlot()` to maintain emulator tracking maps
2. Implement `findNextSameAccountProfile()` helper method (optional)
3. Add logging for same-account profile detection

**Estimated Time**: 1-2 hours

### 4.4 Phase 4: Testing and Validation
1. Unit tests for conflict detection
2. Integration tests for multi-emulator scenarios
3. Test priority ordering within same account
4. Test priority ordering across different accounts
5. Test slot release and reacquisition

**Estimated Time**: 3-4 hours

**Total Estimated Time**: 7-11 hours

---

## 5. Testing Scenarios

### 5.1 Test Case 1: Basic Conflict Detection
**Setup**:
- Profile A (emulator 0, priority 100) acquires slot
- Profile B (emulator 0, priority 99) requests slot

**Expected**: Profile B is queued, cannot acquire slot until Profile A releases

### 5.2 Test Case 2: Different Emulators No Conflict
**Setup**:
- Profile A (emulator 0, priority 100) acquires slot
- Profile B (emulator 1, priority 99) requests slot
- MAX_RUNNING_EMULATORS = 3

**Expected**: Profile B acquires slot immediately (no conflict)

### 5.3 Test Case 3: Same Account Sequential Execution
**Setup**:
- Profile A (emulator 0, priority 100) running
- Profile B (emulator 0, priority 99) queued
- Profile C (emulator 0, priority 98) queued
- Profile A finishes

**Expected**: Profile B acquires slot (higher priority), then Profile C when B finishes

### 5.4 Test Case 4: Priority Ordering Across Accounts
**Setup**:
- Profile A (emulator 0, priority 100) running
- Profile B (emulator 1, priority 95) queued
- Profile C (emulator 0, priority 90) queued
- Profile D (emulator 2, priority 85) queued
- MAX_RUNNING_EMULATORS = 3

**Expected**: 
- Profile B can acquire slot (different emulator, slot available)
- Profile C must wait (same emulator as A)
- Profile D can acquire slot (different emulator, slot available)

### 5.5 Test Case 5: Slot Release and Reacquisition
**Setup**:
- Profile A (emulator 0, priority 100) running
- Profile B (emulator 0, priority 99) queued
- Profile A releases slot

**Expected**: Profile B acquires slot immediately (same emulator, no conflict)

### 5.6 Test Case 6: MAX_RUNNING_EMULATORS Limit
**Setup**:
- MAX_RUNNING_EMULATORS = 2
- Profile A (emulator 0) running
- Profile B (emulator 1) running
- Profile C (emulator 2, priority 100) requests slot

**Expected**: Profile C must wait (MAX_RUNNING_EMULATORS limit reached)

---

## 6. Edge Cases

### 6.1 Profile Without Emulator Number
**Scenario**: Profile has null or empty `emulatorNumber`
**Handling**: Treat as invalid, log error, reject slot acquisition

### 6.2 Thread Dies Without Releasing Slot
**Scenario**: Thread crashes or is killed while holding slot
**Handling**: Current system doesn't handle this - consider adding cleanup mechanism (future enhancement)

### 6.3 Emulator Number Mismatch
**Scenario**: Profile's `emulatorNumber` doesn't match actual emulator being used
**Handling**: Log warning, but allow (emulator number is just identifier, not enforcement)

### 6.4 Queue Reordering
**Scenario**: Profile priority changes while in queue
**Handling**: Queue doesn't reorder automatically - profile maintains position until it acquires slot (acceptable limitation)

### 6.5 Multiple Profiles Same Priority Same Account
**Scenario**: Multiple profiles with same priority and same emulatorNumber
**Handling**: Ordered by arrival time (first-come-first-served) - already handled by `WaitingThread.compareTo()`

---

## 7. Logging Requirements

### 7.1 Conflict Detection Logs
```
[INFO] Profile {name} (emulator {number}) conflicts with active profile, queuing...
```

### 7.2 Slot Acquisition Logs
```
[INFO] Profile {name} acquired emulator {number} slot
[DEBUG] Emulator {number} now active (thread: {threadName})
```

### 7.3 Slot Release Logs
```
[INFO] Profile {name} released emulator {number} slot
[INFO] Next same-account profile {profileId} is queued for emulator {number}
```

### 7.4 Queue Position Logs
```
[DEBUG] Profile {name} queue position: {position} (emulator {number})
```

---

## 8. Success Criteria

### 8.1 Functional Success
- ✅ Multiple profiles from same account cannot run simultaneously
- ✅ Profiles from different accounts can run simultaneously (if slots available)
- ✅ When profile finishes, next profile from same account acquires same emulator
- ✅ Priority ordering maintained within same account
- ✅ Priority ordering maintained across all profiles

### 8.2 Performance Success
- No significant performance degradation
- Conflict detection completes in < 1ms
- Queue operations maintain O(log n) complexity

### 8.3 Reliability Success
- Thread-safe operations
- No race conditions
- Proper cleanup on slot release
- Backward compatible with existing profiles

---

## 9. Future Enhancements (Out of Scope)

### 9.1 Dynamic Emulator Assignment
- Allow profiles to use any available emulator (not just configured one)
- Requires more complex conflict detection and assignment logic

### 9.2 Account-Level Configuration
- Add explicit account grouping configuration
- Support for multiple accounts per emulator (if game allows)

### 9.3 Dead Thread Detection
- Detect threads that die without releasing slots
- Automatic cleanup and slot recovery

### 9.4 Queue Reordering
- Support dynamic priority changes while in queue
- Reorder queue when priorities change

---

## 10. References

### 10.1 Related Documentation
- `agents/03-core-concepts.md` - Profile and emulator concepts
- `agents/developments/switch_profile/requirements.md` - Character switching feature
- `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java` - Current implementation

### 10.2 Related Code
- `WaitingThread.java` - Queue entry structure
- `TaskQueue.java` - Task queue management
- `ServScheduler.java` - Profile scheduling

---

**Document Version**: 1.0  
**Last Updated**: 2025-01-12  
**Status**: Ready for Implementation
























