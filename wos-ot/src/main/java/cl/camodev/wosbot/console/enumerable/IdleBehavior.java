package cl.camodev.wosbot.console.enumerable;

public enum IdleBehavior {
    CLOSE_EMULATOR("Close Emulator", BehaviorType.CLOSE_EMULATOR),
    SEND_TO_BACKGROUND("Close Game", BehaviorType.SEND_TO_BACKGROUND),
    DO_NOTHING("Do Nothing", BehaviorType.DO_NOTHING);

    /**
     * Internal enum representing the type of idle behavior.
     * This ensures type safety and eliminates the need for multiple boolean flags.
     */
    private enum BehaviorType {
        CLOSE_EMULATOR,
        SEND_TO_BACKGROUND,
        DO_NOTHING
    }

    private final String displayName;
    private final BehaviorType behaviorType;

    IdleBehavior(String displayName, BehaviorType behaviorType) {
        this.displayName = displayName;
        this.behaviorType = behaviorType;
    }

    public String getDisplayName() {
        return displayName;
    }

    public boolean shouldSendToBackground() {
        return behaviorType == BehaviorType.SEND_TO_BACKGROUND;
    }

    public boolean shouldDoNothing() {
        return behaviorType == BehaviorType.DO_NOTHING;
    }

    public boolean shouldCloseEmulator() {
        return behaviorType == BehaviorType.CLOSE_EMULATOR;
    }

    @Override
    public String toString() {
        return displayName;
    }

    /**
     * Converts from string configuration value to IdleBehavior enum.
     * Defaults to CLOSE_EMULATOR if the value is invalid or not set.
     * 
     * @param configValue The configuration string value (e.g., "CLOSE_EMULATOR", "SEND_TO_BACKGROUND", "DO_NOTHING")
     * @return The corresponding IdleBehavior enum value, or CLOSE_EMULATOR if invalid/missing
     */
    public static IdleBehavior fromString(String configValue) {
        if (configValue != null && !configValue.isEmpty()) {
            try {
                return IdleBehavior.valueOf(configValue);
            } catch (IllegalArgumentException e) {
                // Invalid enum value, default to CLOSE_EMULATOR
                // Note: Logging should be handled by the calling code if needed
            }
        }
        // Default to CLOSE_EMULATOR if not set or invalid
        return CLOSE_EMULATOR;
    }

    /**
     * Gets the enum name for configuration storage.
     * 
     * @return The enum name (e.g., "CLOSE_EMULATOR")
     */
    public String getConfigValue() {
        return this.name();
    }
}
