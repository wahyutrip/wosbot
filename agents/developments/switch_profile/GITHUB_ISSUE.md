# Character Profile Switching Feature

## Problem

Users with multiple characters on the same game account need to manually switch characters when running different profiles sequentially on a single emulator instance. This is inefficient and prevents full automation when PC limitations restrict concurrent emulator instances.

**Use Case**: User has 3 accounts with 9 total characters across different servers, but only 1 emulator can run simultaneously.

## Solution

Implement automatic character profile switching during profile initialization. The bot should:
- Verify the currently active character matches the profile's configured character
- Automatically switch to the correct character if a mismatch is detected
- Support character identification via ID, name, alliance code, and server
- Be fully backward compatible (profiles without character config continue to work)

## Requirements

- Character verification occurs after home screen detection, before stamina reading
- Character switching uses OCR and template matching for UI navigation
- Character information stored as direct database columns (not configuration)
- GUI support for configuring character fields in profile creation/editing
- Robust error handling: if character not found, close emulator and continue to next profile

## Acceptance Criteria

- [ ] Bot verifies current character matches profile configuration during initialization
- [ ] Bot automatically switches to correct character if mismatch detected
- [ ] Character switching completes successfully (< 30 seconds)
- [ ] Profiles without character configuration continue to work normally
- [ ] GUI allows configuring character fields (name, ID, alliance code, server)
- [ ] Error handling: character not found closes emulator and continues to next profile






















