# Multi-Emulator Support with Account-Based Conflict Detection

## Problem

Users with multiple accounts and characters need to run multiple emulators simultaneously, but the current system doesn't prevent conflicts when multiple characters from the same account attempt to run concurrently. This can cause game account conflicts and automation failures.

**Use Case**: User has 3 accounts with 9 total characters (3 characters per account). Multiple emulators can run simultaneously (e.g., emulators 0, 1, 3), but multiple characters from the same account must run sequentially on the same emulator.

## Solution

Implement account-based conflict detection using emulator number as the account identifier. The system should:
- Prevent multiple profiles with the same `emulatorNumber` from running simultaneously
- Allow profiles from different accounts (different `emulatorNumber`) to run concurrently
- When a profile finishes, prioritize the next profile from the same account for the same emulator slot
- Maintain priority-based queueing across all profiles

## Requirements

- Account identification via `emulatorNumber` field (no new database fields needed)
- Thread-safe conflict detection before slot acquisition
- Emulator tracking maps to track which thread is using which emulator number
- Conflict check in both immediate acquisition path and queue wait loop
- Proper cleanup of tracking maps on slot release
- Backward compatible with existing profiles

## Acceptance Criteria

- [ ] Multiple profiles from same account (same `emulatorNumber`) cannot run simultaneously
- [ ] Profiles from different accounts can run simultaneously (if slots available)
- [ ] When profile finishes, next profile from same account acquires same emulator slot
- [ ] Priority ordering maintained within same account
- [ ] Priority ordering maintained across all profiles
- [ ] Thread-safe operations with no race conditions
- [ ] Comprehensive logging for conflict detection and slot assignment
- [ ] Backward compatible with existing profiles

## Technical Details

See `agents/developments/multi-emulator/requirements.md` and `agents/developments/multi-emulator/implementation-checklist.md` for complete technical specifications.

