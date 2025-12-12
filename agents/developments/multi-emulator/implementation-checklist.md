# Multi-Emulator Support - Implementation Checklist

## Phase 1: Data Structure Updates

### 1.1 Update WaitingThread Class
- [ ] Add `emulatorNumber` field to `WaitingThread`
- [ ] Update constructor to accept `emulatorNumber` from profile
- [ ] Add `getEmulatorNumber()` getter method
- [ ] Update `WaitingThread.java` file

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/WaitingThread.java`

**Changes**:
```java
final String emulatorNumber;  // Add this field

public WaitingThread(Thread thread, DTOProfiles profile) {
    // ... existing code ...
    this.emulatorNumber = profile.getEmulatorNumber();  // Add this
}

public String getEmulatorNumber() {
    return emulatorNumber;
}
```

### 1.2 Add Emulator Tracking to EmulatorManager
- [ ] Add `emulatorToThread` map (Map<String, Thread>)
- [ ] Add `threadToEmulator` map (Map<Thread, String>)
- [ ] Initialize maps in constructor or initialize() method

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Changes**:
```java
private final Map<String, Thread> emulatorToThread = new HashMap<>();
private final Map<Thread, String> threadToEmulator = new HashMap<>();
```

---

## Phase 2: Conflict Detection

### 2.1 Implement Conflict Detection Method
- [ ] Create `hasEmulatorConflict()` method
- [ ] Check if emulatorNumber is already in use by another thread
- [ ] Exclude current thread from conflict check
- [ ] Add proper logging

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Method**:
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

### 2.2 Add Conflict Check to Slot Acquisition (Immediate Path)
- [ ] Add conflict check before immediate slot acquisition
- [ ] If conflict exists, force profile to queue instead of acquiring immediately
- [ ] Add logging when conflict is detected

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Location**: In `adquireEmulatorSlot()` method, around line 642

**Changes**:
```java
// Before: if (activeSlots.size() < MAX_RUNNING_EMULATORS && waitingQueue.isEmpty())
// After:
if (activeSlots.size() < MAX_RUNNING_EMULATORS 
    && !hasEmulatorConflict(emulatorNumber, currentThread) 
    && waitingQueue.isEmpty()) {
    // ... acquire slot ...
    emulatorToThread.put(emulatorNumber, currentThread);
    threadToEmulator.put(currentThread, emulatorNumber);
}
```

### 2.3 Add Conflict Check to Wait Loop
- [ ] Add conflict check condition to wait loop
- [ ] Profile must wait if conflict exists, even if at front of queue
- [ ] Update wait condition to include conflict check

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Location**: In `adquireEmulatorSlot()` method, around line 657

**Changes**:
```java
// Before: while (waitingQueue.peek() != currentWaiting || activeSlots.size() >= MAX_RUNNING_EMULATORS)
// After:
while (waitingQueue.peek() != currentWaiting 
    || activeSlots.size() >= MAX_RUNNING_EMULATORS
    || hasEmulatorConflict(emulatorNumber, currentThread)) {
    // ... wait logic ...
}
```

### 2.4 Update Emulator Tracking on Slot Acquisition
- [ ] Update `emulatorToThread` map when slot acquired (immediate path)
- [ ] Update `threadToEmulator` map when slot acquired (immediate path)
- [ ] Update both maps when slot acquired from queue

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Location**: After `activeSlots.add(currentThread)` in both acquisition paths

**Changes**:
```java
activeSlots.add(currentThread);
emulatorToThread.put(emulatorNumber, currentThread);
threadToEmulator.put(currentThread, emulatorNumber);
```

---

## Phase 3: Slot Release Updates

### 3.1 Update Slot Release to Maintain Tracking
- [ ] Get emulator number from thread before removing from active slots
- [ ] Remove from `emulatorToThread` map
- [ ] Remove from `threadToEmulator` map
- [ ] Handle null emulator number gracefully

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Location**: In `releaseEmulatorSlot()` method, around line 690

**Changes**:
```java
String emulatorNumber = threadToEmulator.get(currentThread);

if (activeSlots.remove(currentThread)) {
    if (emulatorNumber != null) {
        emulatorToThread.remove(emulatorNumber);
        threadToEmulator.remove(currentThread);
    }
    // ... existing logging ...
}
```

### 3.2 Add Same-Account Profile Detection (Optional)
- [ ] Implement `findNextSameAccountProfile()` helper method
- [ ] Check for same-account profiles when slot is released
- [ ] Add logging when same-account profile is found

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Method** (optional optimization):
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

**Usage in releaseEmulatorSlot()**:
```java
WaitingThread nextSameAccount = findNextSameAccountProfile(emulatorNumber);
if (nextSameAccount != null) {
    logger.info("Next same-account profile {} is queued for emulator {}", 
        nextSameAccount.getProfileId(), emulatorNumber);
}
```

### 3.3 Update resetQueueState()
- [ ] Clear `emulatorToThread` map
- [ ] Clear `threadToEmulator` map
- [ ] Ensure proper cleanup

**File**: `wos-serv/src/main/java/cl/camodev/wosbot/emulator/EmulatorManager.java`

**Location**: In `resetQueueState()` method, around line 723

**Changes**:
```java
waitingQueue.clear();
activeSlots.clear();
emulatorToThread.clear();
threadToEmulator.clear();
```

---

## Phase 4: Validation and Edge Cases

### 4.1 Handle Null/Empty Emulator Number
- [ ] Check for null or empty `emulatorNumber` in conflict detection
- [ ] Log error if emulator number is invalid
- [ ] Reject slot acquisition if emulator number is invalid

**Location**: In `adquireEmulatorSlot()` method, at the beginning

**Changes**:
```java
String emulatorNumber = profile.getEmulatorNumber();
if (emulatorNumber == null || emulatorNumber.isEmpty()) {
    logger.error("Profile {} has invalid emulator number, cannot acquire slot", profile.getName());
    throw new IllegalArgumentException("Profile emulator number is required");
}
```

### 4.2 Add Comprehensive Logging
- [ ] Log conflict detection events
- [ ] Log emulator tracking updates
- [ ] Log same-account profile detection
- [ ] Include emulator number in all relevant log messages

**Logging Points**:
- When conflict detected: `[INFO] Profile {} (emulator {}) conflicts with active profile, queuing...`
- When slot acquired: `[INFO] Profile {} acquired emulator {} slot`
- When slot released: `[INFO] Profile {} released emulator {} slot`
- When same-account profile found: `[INFO] Next same-account profile {} is queued for emulator {}`

---

## Phase 5: Testing

### 5.1 Unit Tests
- [ ] Test `hasEmulatorConflict()` with various scenarios
- [ ] Test conflict detection with null emulator number
- [ ] Test emulator tracking map updates
- [ ] Test `findNextSameAccountProfile()` method

**Test File**: `wos-serv/src/test/java/cl/camodev/wosbot/emulator/EmulatorManagerTest.java`

**Test Cases**:
1. No conflict when emulator not in use
2. Conflict detected when emulator in use by different thread
3. No conflict when emulator in use by same thread
4. Null emulator number handling
5. Empty emulator number handling

### 5.2 Integration Tests
- [ ] Test basic conflict detection (same emulator, different profiles)
- [ ] Test no conflict (different emulators)
- [ ] Test sequential execution (same account, multiple profiles)
- [ ] Test priority ordering within same account
- [ ] Test priority ordering across different accounts
- [ ] Test MAX_RUNNING_EMULATORS limit

**Test Scenarios** (see requirements.md Section 5):
1. Basic conflict detection
2. Different emulators no conflict
3. Same account sequential execution
4. Priority ordering across accounts
5. Slot release and reacquisition
6. MAX_RUNNING_EMULATORS limit

### 5.3 Manual Testing
- [ ] Test with 3 emulators running simultaneously
- [ ] Test with profiles from same account queued
- [ ] Test priority ordering
- [ ] Test slot release and reacquisition
- [ ] Monitor logs for proper conflict detection

---

## Phase 6: Documentation

### 6.1 Code Documentation
- [ ] Add Javadoc to `hasEmulatorConflict()` method
- [ ] Add Javadoc to `findNextSameAccountProfile()` method (if implemented)
- [ ] Update Javadoc for `adquireEmulatorSlot()` method
- [ ] Update Javadoc for `releaseEmulatorSlot()` method
- [ ] Document emulator tracking maps

### 6.2 Update Architecture Documentation
- [ ] Update `agents/03-core-concepts.md` with multi-emulator support
- [ ] Update `agents/01-architecture-overview.md` if needed
- [ ] Add notes about account identification via emulator number

---

## Verification Checklist

Before considering implementation complete:

- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Manual testing completed successfully
- [ ] No performance degradation observed
- [ ] Thread safety verified (no race conditions)
- [ ] Logging is comprehensive and helpful
- [ ] Code follows project patterns and conventions
- [ ] Javadoc is complete and accurate
- [ ] Backward compatibility maintained
- [ ] No breaking changes to existing APIs

---

## Rollback Plan

If issues are discovered:

1. **Immediate Rollback**: Revert changes to `EmulatorManager.java` and `WaitingThread.java`
2. **Partial Rollback**: Keep data structure changes, remove conflict detection logic
3. **Configuration Rollback**: Set `MAX_RUNNING_EMULATORS = 1` to force single-emulator mode

---

**Last Updated**: 2025-01-12  
**Status**: Ready for Implementation
























