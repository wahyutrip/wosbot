# PR Title

feat: Add character profile switching feature for multi-character account support

# PR Description

## Summary

This PR implements automatic character profile switching functionality, enabling the bot to switch between characters within the same game account during profile initialization. This feature allows multiple characters from the same account to run sequentially on a single emulator instance, maximizing resource utilization when PC limitations restrict concurrent emulator instances.

**Key Changes:**
- Added character identification fields (ID, name, alliance code, server) to Profile entity as direct database columns
- Implemented `CharacterSwitchHelper` class for character verification and switching operations
- Integrated character switching into `InitializeTask` initialization flow
- Added GUI support for character configuration in profile creation/editing
- Added template images and OCR regions for character switching UI navigation
- Implemented robust error handling and retry logic for character switching operations

**Implementation Details:**
- Character verification occurs after home screen detection but before stamina reading
- Uses OCR to read character ID and name from profile menu
- Navigates through Settings → Switch Character menu using template matching
- Searches character list using Furnace Level template and OCR for character names
- Handles scrolling, character selection, and confirmation dialog
- Supports alliance code prefix stripping for character name matching
- Fully backward compatible - profiles without character config continue to work normally

## How to Test

1. **Profile Setup:**
   - Create or edit a profile
   - Configure character fields (Character Name, Character ID, Alliance Code, Server)
   - Save the profile

2. **Character Verification (Correct Character Active):**
   - Start bot with profile that has correct character already active
   - Verify bot detects correct character and continues initialization without switching
   - Check logs show "Character verification successful"

3. **Character Switching (Wrong Character Active):**
   - Start bot with profile that has different character active
   - Verify bot detects mismatch and switches to correct character
   - Verify bot waits for game reload and re-checks home screen
   - Check logs show character switching flow

4. **Backward Compatibility:**
   - Start bot with profile without character configuration
   - Verify bot skips character verification and continues normally
   - Check logs show "No character configuration found. Skipping character verification."

5. **Error Handling:**
   - Test with character name that doesn't exist in character list
   - Verify bot closes emulator and continues to next profile (doesn't retry)
   - Check logs show appropriate error messages

6. **Multiple Characters:**
   - Test switching between multiple characters on same account
   - Verify each character switch completes successfully
   - Verify bot continues with task execution after switching

## Related Issues

- Closes #113 - Character Profile Switching Feature
- Multi-emulator switch restriction feature will be implemented in a separate PR (issue TBD)
