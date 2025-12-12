# Character Profile Switching - Implementation Checklist

## Pre-Implementation

### Requirements Review
- [ ] Review `requirements.md` document
- [ ] Review `feasibility-summary.md`
- [ ] Confirm understanding of user requirements
- [ ] Identify any missing information or clarifications needed

### Resource Gathering
- [ ] Collect screenshots of Settings menu
- [ ] Collect screenshots of Switch Character menu
- [ ] Collect screenshots of Character List screen
- [ ] Identify OCR regions for character name on profile screen
- [ ] Identify OCR regions for character server on profile screen
- [ ] Test OCR reading of character name/server (manual testing)

### Design Decisions
- [ ] Confirm configuration key names
- [ ] Confirm OCR region coordinates
- [ ] Confirm template image locations
- [ ] Confirm retry strategy (max attempts, delays)
- [ ] Confirm error handling approach

---

## Phase 1: Configuration and Data Model

### Configuration Keys
- [ ] Add `CHARACTER_NAME_STRING` to `EnumConfigurationKey`
- [ ] Add `CHARACTER_SERVER_STRING` to `EnumConfigurationKey`
- [ ] Add `CHARACTER_ID_STRING` to `EnumConfigurationKey`
- [ ] Verify default values are empty strings
- [ ] Test configuration key access via `profile.getConfig()`

### GUI Integration (Optional - Can be done later)
- [ ] Add character name field to profile creation GUI
- [ ] Add character server field to profile creation GUI
- [ ] Add character ID field to profile creation GUI (optional)
- [ ] Add character fields to profile editing GUI
- [ ] Test saving/loading character configuration

### Documentation
- [ ] Update `agents/08-configuration-reference.md` with new keys
- [ ] Document character configuration usage

---

## Phase 2: Character Verification

### CharacterSwitchHelper Class Structure
- [ ] Create `CharacterSwitchHelper.java` in `wos-serv/src/main/java/cl/camodev/wosbot/serv/task/helper/`
- [ ] Add constructor (EmulatorManager, emulatorNumber, DTOProfiles)
- [ ] Add ProfileLogger instance
- [ ] Add TemplateSearchHelper instance
- [ ] Add TextRecognitionRetrier instances (for name/server reading)

### Character Verification Method
- [ ] Implement `verifyCurrentCharacter(DTOProfiles profile)` method
- [ ] Read character name from profile screen (OCR)
- [ ] Read character server from profile screen (OCR)
- [ ] Compare with profile configuration
- [ ] Return boolean (true if matches, false if not)
- [ ] Handle case where character config is not set (return true, skip verification)
- [ ] Add logging for verification results

### OCR Regions and Settings
- [ ] Define character name OCR region (DTOPoint coordinates)
- [ ] Define character server OCR region (DTOPoint coordinates)
- [ ] Create OCR settings for character name (alphanumeric + spaces)
- [ ] Create OCR settings for character server (numbers only)
- [ ] Test OCR reading accuracy (manual testing with screenshots)

### Unit Tests
- [ ] Test `verifyCurrentCharacter()` with matching character
- [ ] Test `verifyCurrentCharacter()` with non-matching character
- [ ] Test `verifyCurrentCharacter()` without character config
- [ ] Test OCR reading methods

---

## Phase 3: Character Switching

### Navigation Methods
- [ ] Implement `navigateToSettingsMenu()` method
- [ ] Implement `navigateToSwitchCharacterMenu()` method
- [ ] Test navigation flow (Home → Settings → Switch Character)

### Character List Reading
- [ ] Implement `readCharacterList()` method
- [ ] Read character names from list (OCR)
- [ ] Read character servers from list (OCR)
- [ ] Parse character list into data structure
- [ ] Handle scrolling if character list is long
- [ ] Handle loading delays (wait for list to appear)

### Character Selection
- [ ] Implement `selectCharacterFromList(String name, String server)` method
- [ ] Search for target character in list (match by name + server)
- [ ] Scroll to character if needed
- [ ] Tap on character to select
- [ ] Wait for character switch to complete
- [ ] Verify character switch success

### Main Switching Method
- [ ] Implement `switchToCharacter(DTOProfiles profile)` method
- [ ] Call navigation methods
- [ ] Call character list reading
- [ ] Call character selection
- [ ] Add retry logic (max 3 attempts)
- [ ] Add error handling and logging
- [ ] Return boolean (true if successful, false otherwise)

### Unit Tests
- [ ] Test navigation methods
- [ ] Test character list reading
- [ ] Test character selection
- [ ] Test full switching flow
- [ ] Test error scenarios (character not found, navigation fails)

---

## Phase 4: Template Resources

### Template Images
- [ ] Create `GAME_SETTINGS_BUTTON` template image
- [ ] Create `GAME_SETTINGS_SWITCH_CHARACTER_BUTTON` template image
- [ ] Create `GAME_CHARACTER_LIST_ITEM` template image (if needed)
- [ ] Add templates to `wos-utiles/src/main/resources/templates/settings/`
- [ ] Test template matching accuracy

### EnumTemplates Updates
- [ ] Add `GAME_SETTINGS_BUTTON` to `EnumTemplates`
- [ ] Add `GAME_SETTINGS_SWITCH_CHARACTER_BUTTON` to `EnumTemplates`
- [ ] Add `GAME_CHARACTER_LIST_ITEM` to `EnumTemplates` (if needed)
- [ ] Verify template paths are correct

---

## Phase 5: InitializeTask Integration

### InitializeTask Modifications
- [ ] Add `CharacterSwitchHelper` instance (in constructor or as field)
- [ ] Create `verifyAndSwitchCharacter()` method
- [ ] Integrate into `execute()` method flow:
  - After `waitForHomeScreen()`
  - Before `handleInitializationSuccess()`
- [ ] Add error handling (set `recurring=true` on failure)
- [ ] Add logging for character switching operations

### Modified Flow
```
execute() {
    ensureEmulatorRunning();
    ensureGameInstalled();
    ensureGameRunning();
    waitForHomeScreen();
    verifyAndSwitchCharacter();  // NEW
    handleInitializationSuccess();
}
```

### Error Handling
- [ ] Handle case where character config not set (skip verification)
- [ ] Handle case where character matches (skip switching)
- [ ] Handle case where character switching fails (set recurring=true)
- [ ] Handle case where character not found (set recurring=true)
- [ ] Add appropriate error messages and logging

### Integration Tests
- [ ] Test initialization with character config, matching character
- [ ] Test initialization with character config, non-matching character
- [ ] Test initialization without character config (backward compatibility)
- [ ] Test initialization with character switching failure
- [ ] Test retry logic (recurring=true behavior)

---

## Phase 6: Testing and Refinement

### Unit Testing
- [ ] All CharacterSwitchHelper methods have unit tests
- [ ] OCR reading methods tested
- [ ] Navigation methods tested
- [ ] Character selection tested
- [ ] Error handling tested

### Integration Testing
- [ ] Full initialization flow with character switching
- [ ] Full initialization flow without character config
- [ ] Error scenarios (character not found, switching fails)
- [ ] Retry logic (recurring=true)
- [ ] Multiple profiles with different characters

### Manual Testing
- [ ] Test with real game (character name: "John Doe", server: "1830")
- [ ] Test character switching when wrong character active
- [ ] Test character verification when correct character active
- [ ] Test with multiple characters on same account
- [ ] Test with characters on different servers
- [ ] Test error scenarios manually

### Performance Testing
- [ ] Measure character verification time (should be < 5 seconds)
- [ ] Measure character switching time (should be < 30 seconds)
- [ ] Measure impact on initialization time
- [ ] Verify no performance degradation

### Refinement
- [ ] Tune OCR regions if needed
- [ ] Adjust retry delays if needed
- [ ] Improve error messages
- [ ] Optimize character list reading
- [ ] Add additional logging if needed

---

## Phase 7: Documentation

### Code Documentation
- [ ] Add Javadoc to `CharacterSwitchHelper` class
- [ ] Add Javadoc to all public methods
- [ ] Document OCR regions and coordinates
- [ ] Document template requirements
- [ ] Document error handling approach

### User Documentation
- [ ] Update `agents/08-configuration-reference.md` with character config keys
- [ ] Create user guide for character configuration (if GUI added)
- [ ] Document character switching feature in relevant docs

### API Documentation
- [ ] Document CharacterSwitchHelper in `agents/09-helper-classes.md`
- [ ] Update InitializeTask documentation if needed

---

## Phase 8: Final Review

### Code Review
- [ ] Code follows project patterns and conventions
- [ ] Code is well-documented
- [ ] Error handling is comprehensive
- [ ] Logging is appropriate
- [ ] No breaking changes to existing functionality

### Testing Review
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] Manual testing completed successfully
- [ ] Performance is acceptable
- [ ] Backward compatibility verified

### Documentation Review
- [ ] Code is documented
- [ ] Configuration keys documented
- [ ] User guide updated (if applicable)
- [ ] API documentation updated

### Deployment
- [ ] Code is ready for merge
- [ ] All tests pass
- [ ] Documentation complete
- [ ] Ready for production use

---

## Notes

### Important Considerations
- **Backward Compatibility**: Always ensure profiles without character config continue to work
- **Error Handling**: Robust error handling is critical - failures should not break the queue
- **OCR Accuracy**: May need multiple iterations to get OCR regions right
- **Template Matching**: More reliable than OCR for UI elements - use templates when possible
- **Testing**: Test thoroughly with real game scenarios before considering complete

### Common Issues to Watch For
- OCR misreading character names (especially special characters)
- UI variations between game versions/regions
- Character list not loading properly
- Timing issues (UI not ready when accessed)
- Navigation failures (settings menu not accessible)

### Success Metrics
- Character switching succeeds > 95% of the time
- Character verification completes in < 5 seconds
- Character switching completes in < 30 seconds
- No impact on profiles without character config
- No breaking changes to existing functionality

---

**Last Updated**: 2025-01-12  
**Status**: Ready for Implementation

