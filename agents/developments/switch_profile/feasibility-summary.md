# Character Profile Switching - Feasibility Summary

## Quick Assessment: ✅ FEASIBLE

This feature is **technically feasible** and can be implemented using existing infrastructure.

---

## Key Requirements Summary

### What We Need to Do
1. **Store character information** in profile configuration (name, server, ID)
2. **Verify current character** during initialization using OCR
3. **Switch character** if verification fails (Settings → Switch Character → Select)
4. **Continue initialization** after successful character switch

### User Scenario
- 3 accounts, 9 characters total
- 1 emulator instance max
- Profiles run sequentially, switching characters as needed

---

## Technical Feasibility ✅

### ✅ Existing Infrastructure Available
1. **OCR System**: Tesseract via Tess4j - proven to work
2. **Template Matching**: ImageSearchUtil - reliable UI detection
3. **Navigation**: NavigationHelper pattern exists
4. **Configuration**: EnumConfigurationKey system supports new keys
5. **Task System**: InitializeTask is extensible
6. **Emulator Management**: Slot system already handles sequential execution

### ⚠️ Challenges (Manageable)
1. **OCR Accuracy**: Character names may need tuning
   - **Solution**: Retry logic, multiple OCR attempts, character whitelist
2. **UI Variations**: Game UI may vary by version/region
   - **Solution**: Template matching (more reliable than OCR), region-specific templates
3. **Character List Scrolling**: If many characters exist
   - **Solution**: Implement scrolling logic, search by name+server
4. **Timing/Loading**: Character switching may have delays
   - **Solution**: Wait conditions, retry with delays

---

## Implementation Approach

### Phase 1: Configuration (1-2 hours)
- Add 3 new config keys: `CHARACTER_NAME_STRING`, `CHARACTER_SERVER_STRING`, `CHARACTER_ID_STRING`
- Update GUI to allow character input (optional fields)

### Phase 2: Character Verification (4-6 hours)
- Create `CharacterSwitchHelper` class
- Implement OCR reading of character name/server from profile screen
- Implement verification logic

### Phase 3: Character Switching (6-8 hours)
- Implement navigation: Home → Settings → Switch Character
- Implement character list reading (OCR)
- Implement character selection logic
- Add retry and error handling

### Phase 4: Integration (2-4 hours)
- Integrate into `InitializeTask` (add step after `waitForHomeScreen()`)
- Add template resources (need screenshots)
- Test end-to-end flow

### Phase 5: Testing (4-8 hours)
- Unit tests for helper methods
- Integration tests
- Manual testing with real scenarios

**Total Estimated Time**: ~20-30 hours

---

## Key Design Decisions

### 1. Configuration Storage
- ✅ Store as profile configuration (no DB schema changes)
- ✅ Backward compatible (optional fields)
- ✅ Uses existing `EnumConfigurationKey` pattern

### 2. Verification Timing
- ✅ After home screen detection
- ✅ Before stamina reading
- ✅ Only if character config is set

### 3. Error Handling
- ✅ Retry logic (max 3 attempts)
- ✅ Set `recurring=true` on failure (retry initialization)
- ✅ Log errors for debugging
- ✅ Continue if character config not set (backward compatible)

### 4. Helper Class Pattern
- ✅ Follow existing helper pattern (`NavigationHelper`, `StaminaHelper`)
- ✅ Uses `TemplateSearchHelper` for UI detection
- ✅ Uses `TextRecognitionRetrier` for OCR

---

## Critical Success Factors

### 1. OCR Accuracy
- **Risk**: Character names may be misread
- **Mitigation**: 
  - Use character whitelist (alphanumeric + spaces)
  - Multiple OCR attempts
  - Fuzzy matching for character names
  - Fallback to character ID if available

### 2. UI Navigation Reliability
- **Risk**: Settings menu may not be accessible
- **Mitigation**:
  - Template matching (more reliable than OCR)
  - Retry navigation with delays
  - Handle UI variations

### 3. Character List Parsing
- **Risk**: Character list may be long or not load properly
- **Mitigation**:
  - Wait for list to load
  - Implement scrolling if needed
  - Match by name + server (more reliable)

---

## Backward Compatibility ✅

### Profiles Without Character Config
- ✅ Skip character verification
- ✅ Continue with normal initialization
- ✅ No breaking changes

### Existing Functionality
- ✅ All existing tasks continue to work
- ✅ No changes to task execution flow
- ✅ Only affects initialization phase

---

## Testing Strategy

### Unit Tests
- `CharacterSwitchHelper.verifyCurrentCharacter()`
- `CharacterSwitchHelper.switchToCharacter()`
- OCR reading methods
- Character list parsing

### Integration Tests
- Full initialization with character switching
- Initialization without character config
- Error scenarios (character not found, switching fails)

### Manual Tests
- Real game scenarios with multiple characters
- Different server numbers
- Edge cases (same name, different servers)

---

## Dependencies

### Required
- ✅ All dependencies already exist
- ✅ No new external libraries needed
- ✅ Uses existing OCR, template matching, navigation infrastructure

### Template Resources Needed
- Settings button template
- Switch Character button template
- Character list UI templates
- Character name/server OCR regions (coordinates)

---

## Risk Assessment

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|------------|
| OCR accuracy for names | Medium | Medium | Retry logic, fuzzy matching, character ID fallback |
| UI navigation failures | Medium | Low | Template matching, retry with delays |
| Character list parsing | Low | Low | Wait conditions, scrolling logic |
| Performance impact | Low | Low | Only runs during initialization |

**Overall Risk Level**: **LOW-MEDIUM** (manageable with proper error handling)

---

## Recommendation

### ✅ PROCEED WITH IMPLEMENTATION

**Reasons**:
1. ✅ Technically feasible with existing infrastructure
2. ✅ Follows established patterns and conventions
3. ✅ Backward compatible
4. ✅ Clear implementation path
5. ✅ Manageable risks with proper error handling

### Next Steps
1. **Review requirements document** (`requirements.md`)
2. **Gather template resources** (screenshots of settings/character switching UI)
3. **Start Phase 1**: Add configuration keys
4. **Implement incrementally**: Test each phase before moving to next
5. **Iterate based on testing**: Refine OCR regions and templates as needed

---

## Questions to Resolve

### Before Implementation
1. **Template Resources**: Do we have screenshots of the settings menu and character switching UI?
2. **OCR Regions**: Do we know the exact coordinates for character name/server on profile screen?
3. **Character List Format**: How is the character list displayed? (scrollable list, grid, etc.)
4. **GUI Integration**: Should character fields be added to profile creation/editing GUI immediately, or can it be added later?

### During Implementation
1. **Retry Strategy**: How many retries for character switching? (Recommend: 3)
2. **Timeout Values**: How long to wait for character list to load? (Recommend: 10 seconds)
3. **Fuzzy Matching**: Should we use exact match or fuzzy match for character names? (Recommend: exact match with server number)

---

**Status**: ✅ **FEASIBLE - READY FOR IMPLEMENTATION**

**Confidence Level**: **HIGH** (85-90%)

The feature can be implemented successfully with proper planning and incremental development.

