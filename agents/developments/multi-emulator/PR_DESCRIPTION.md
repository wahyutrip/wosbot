# PR Title

feat: Add multi-emulator support with account-based conflict detection

# PR Description

## Summary

This PR implements multi-emulator support with account-based conflict detection, enabling the bot to run multiple emulators simultaneously while preventing conflicts when multiple characters from the same account attempt to run concurrently. The system uses emulator number as the account identifier, ensuring that characters from the same account run sequentially on the same emulator.

**Key Changes:**
- Added emulator tracking maps to `EmulatorManager` for conflict detection (`emulatorToThread`, `threadToEmulator`)
- Enhanced `WaitingThread` class with `emulatorNumber` field for queue-based conflict checking
- Implemented `hasEmulatorConflict()` method for thread-safe conflict detection
- Updated slot acquisition logic to check for emulator conflicts before acquiring slots
- Updated slot release logic to maintain emulator tracking and detect same-account profiles in queue
- Added `findNextSameAccountProfile()` helper method for smart slot assignment
- Enhanced logging with emulator numbers throughout slot management operations

**Implementation Details:**
- Account identification via `emulatorNumber` field (no new database fields required)
- Conflict detection prevents multiple profiles with same `emulatorNumber` from running simultaneously
- Profiles from different accounts (different `emulatorNumber`) can run concurrently when slots are available
- Priority-based queueing maintained across all profiles (global priority ordering)
- When a profile finishes, next profile from same account acquires same emulator slot
- Thread-safe operations using existing `ReentrantLock` mechanism
- Fully backward compatible - existing profiles without conflicts continue to work normally

## How to Test

1. **Basic Conflict Detection:**
   - Start Profile A (emulator 0, priority 100)
   - Try to start Profile B (emulator 0, priority 99)
   - Verify Profile B is queued and cannot acquire slot until Profile A releases
   - Check logs show conflict detection messages

2. **Different Emulators (No Conflict):**
   - Start Profile A (emulator 0, priority 100)
   - Start Profile B (emulator 1, priority 99) with `MAX_RUNNING_EMULATORS = 3`
   - Start Profile C (emulator 3, priority 97)
   - Verify all three profiles acquire slots immediately and run simultaneously
   - Check logs show all three emulators active

3. **Same Account Sequential Execution:**
   - Start Profile A (emulator 0, priority 100)
   - Queue Profile B (emulator 0, priority 99)
   - Queue Profile C (emulator 0, priority 98)
   - When Profile A finishes, verify Profile B acquires slot (higher priority)
   - When Profile B finishes, verify Profile C acquires slot
   - Check logs show sequential execution and same-account profile detection

4. **Priority Ordering Across Accounts:**
   - Start Profile A (emulator 0, priority 100)
   - Queue Profile B (emulator 1, priority 95)
   - Queue Profile C (emulator 0, priority 90)
   - Queue Profile D (emulator 2, priority 85)
   - With `MAX_RUNNING_EMULATORS = 3`, verify:
     - Profile B can acquire slot (different emulator, slot available)
     - Profile C must wait (same emulator as A)
     - Profile D can acquire slot (different emulator, slot available)

5. **Slot Release and Reacquisition:**
   - Start Profile A (emulator 0, priority 100)
   - Queue Profile B (emulator 0, priority 99)
   - When Profile A releases slot, verify Profile B acquires slot immediately
   - Check logs show "Next same-account profile is queued" message

6. **MAX_RUNNING_EMULATORS Limit:**
   - Set `MAX_RUNNING_EMULATORS = 2`
   - Start Profile A (emulator 0) and Profile B (emulator 1)
   - Try to start Profile C (emulator 2, priority 100)
   - Verify Profile C must wait (MAX_RUNNING_EMULATORS limit reached)

7. **Backward Compatibility:**
   - Test with existing profiles that don't have conflicts
   - Verify they continue to work normally
   - Verify no performance degradation

## Related Issues

- Closes #[issue-number] - Multi-Emulator Support with Account-Based Conflict Detection
- Related to character profile switching feature (profiles can now run on different emulators)






















