package cl.camodev.wosbot.serv.task.impl;

import java.time.Duration;
import java.time.LocalDateTime;

import cl.camodev.utiles.time.TimeConverters;
import cl.camodev.utiles.time.TimeValidators;
import cl.camodev.wosbot.console.enumerable.EnumTemplates;
import cl.camodev.wosbot.console.enumerable.TpDailyTaskEnum;
import cl.camodev.wosbot.ot.DTOArea;
import cl.camodev.wosbot.ot.DTOTesseractSettings;
import cl.camodev.wosbot.ot.DTOImageSearchResult;
import cl.camodev.wosbot.ot.DTOProfiles;
import cl.camodev.wosbot.serv.task.DelayedTask;
import cl.camodev.wosbot.serv.task.EnumStartLocation;
import cl.camodev.wosbot.serv.task.constants.SearchConfigConstants;
import cl.camodev.wosbot.serv.task.constants.CommonGameAreas;

/**
 * Task responsible for activating Chief Orders in the game with intelligent cooldown detection.
 *
 * <p>
 * Chief Orders are special time-limited buffs that provide various benefits
 * to the player's settlement. This task automates the activation of different
 * order types and uses OCR to detect precise cooldown times, ensuring optimal
 * execution timing.
 *
 * <p>
 * <b>Available Chief Orders:</b>
 * <ul>
 * <li><b>Rush Job</b>: Speeds up construction/upgrades (24-hour cooldown)</li>
 * <li><b>Urgent Mobilization</b>: Boosts troop training (8-hour cooldown)</li>
 * <li><b>Productivity Day</b>: Increases resource production (12-hour cooldown)</li>
 * </ul>
 *
 * <p>
 * <b>Execution Flow:</b>
 * <ol>
 * <li>Navigate to Chief Order menu from HOME screen</li>
 * <li>Select the specific order type (with OCR fallback for cooldown detection)</li>
 * <li>Enact the order (with OCR detection for active/cooldown status)</li>
 * <li>Reschedule based on detected cooldown period or fixed hours</li>
 * </ol>
 *
 * <p>
 * <b>Scheduling Strategy:</b>
 * <ul>
 * <li><b>Success</b>: Reschedules based on order type cooldown (8/12/24 hours)</li>
 * <li><b>OCR Detected Cooldown</b>: Reschedules based on precise OCR reading</li>
 * <li><b>OCR Detected Active</b>: Reschedules based on remaining active time</li>
 * <li><b>Failure/Error</b>: Retries after {@value ERROR_RETRY_MINUTES} minutes</li>
 * </ul>
 *
 * <p>
 * <b>OCR Capabilities:</b>
 * <ul>
 * <li>Detects cooldown times from main menu for each order type</li>
 * <li>Distinguishes between active and cooldown states in detail view</li>
 * <li>Reads remaining active time or cooldown duration precisely</li>
 * <li>Falls back to retry scheduling if OCR fails</li>
 * </ul>
 */
public class ChiefOrderTask extends DelayedTask {

	/**
	 * Enumeration of available Chief Order types with their properties.
	 *
	 * <p>
	 * Each order type has:
	 * <ul>
	 * <li>A descriptive name for logging</li>
	 * <li>A template enum for UI detection</li>
	 * <li>A cooldown period in hours before it can be activated again</li>
	 * </ul>
	 */
	public enum ChiefOrderType {
		/** Rush Job - Speeds up construction/upgrades (24-hour cooldown) */
		RUSH_JOB("Rush Job", EnumTemplates.CHIEF_ORDER_RUSH_JOB, 24),

		/** Urgent Mobilization - Boosts troop training (8-hour cooldown) */
		URGENT_MOBILIZATION("Urgent Mobilization", EnumTemplates.CHIEF_ORDER_URGENT_MOBILISATION, 8),

		/** Productivity Day - Increases resource production (12-hour cooldown) */
		PRODUCTIVITY_DAY("Productivity Day", EnumTemplates.CHIEF_ORDER_PRODUCTIVITY_DAY, 12);

		private final String description;
		private final EnumTemplates template;
		private final int cooldownHours;

		ChiefOrderType(String description, EnumTemplates template, int cooldownHours) {
			this.description = description;
			this.template = template;
			this.cooldownHours = cooldownHours;
		}

		public String getDescription() {
			return description;
		}

		public EnumTemplates getTemplate() {
			return template;
		}

		public int getCooldownHours() {
			return cooldownHours;
		}
	}


	// ========================================================================
	// CONFIGURATION CONSTANTS
	// ========================================================================

	private static final int ERROR_RETRY_MINUTES = 10;
	private static final int OCR_RETRY_ATTEMPTS = 3;
	private static final long OCR_RETRY_DELAY_MS = 500L;
	private static final long MENU_LOAD_DELAY_MS = 1500L;
	private static final long MENU_OPEN_DELAY_MS = 2000L;
	private static final long ENACT_PROCESS_DELAY_MS = 1000L;
	private static final long ANIMATION_COMPLETE_DELAY_MS = 5000L;

	// ========================================================================
	// INSTANCE FIELDS
	// ========================================================================

	private final ChiefOrderType chiefOrderType;

	/**
	 * Constructs a new Chief Order task.
	 *
	 * @param profile        The profile to execute this task for
	 * @param tpTask         The task type enum
	 * @param chiefOrderType The specific chief order type to activate
	 */
	public ChiefOrderTask(DTOProfiles profile, TpDailyTaskEnum tpTask, ChiefOrderType chiefOrderType) {
		super(profile, tpTask);
		this.chiefOrderType = chiefOrderType;
	}

	/**
	 * Indicates that this task must start from the HOME screen.
	 *
	 * @return {@link EnumStartLocation#HOME}
	 */
	@Override
	public EnumStartLocation getRequiredStartLocation() {
		return EnumStartLocation.HOME;
	}

	/**
	 * Executes the Chief Order activation task with intelligent cooldown detection.
	 *
	 * <p>
	 * <b>Execution Flow:</b>
	 * <ol>
	 * <li>Open Chief Order menu</li>
	 * <li>Select specific order type (OCR fallback for cooldown detection)</li>
	 * <li>Enact the order (OCR detection for active/cooldown status)</li>
	 * <li>Schedule next execution based on detected state</li>
	 * </ol>
	 *
	 * <p>
	 * Uses OCR to detect precise cooldown times when templates are not found,
	 * ensuring optimal execution timing. Falls back to retry scheduling on errors.
	 */
	@Override
	protected void execute() {
		logInfo("Starting Chief Order task: " + chiefOrderType.getDescription() +
				" (Cooldown: " + chiefOrderType.getCooldownHours() + " hours)");

		if (!openChiefOrderMenu()) {
			logWarning("Failed to open Chief Order menu, scheduling retry");
			scheduleRetry();
			return;
		}

		if (!selectOrderType()) {
			logWarning("Failed to select Chief Order type, scheduling handled internally");
			return;
		}

		if (!enactOrder()) {
			logWarning("Failed to enact Chief Order, scheduling handled internally");
			return;
		}
	}

	/**
	 * Opens the Chief Order menu from the HOME screen.
	 *
	 * <p>
	 * <b>Navigation Steps:</b>
	 * <ol>
	 * <li>Search for Chief Order menu button</li>
	 * <li>Tap button to open menu</li>
	 * <li>Wait for menu to fully load</li>
	 * </ol>
	 *
	 * @return true if menu was successfully opened, false otherwise
	 */
	private boolean openChiefOrderMenu() {
		logInfo("Looking for Chief Order menu access button");

		DTOImageSearchResult menuButton = searchTemplateWithLogging(
				EnumTemplates.CHIEF_ORDER_MENU_BUTTON,
				"Chief Order menu button");

		if (!menuButton.isFound()) {
			logError("Chief Order menu button not found");
			return false;
		}

		logInfo("Chief Order menu button found. Tapping to open menu");
		tapPoint(menuButton.getPoint());
		sleepTask(MENU_OPEN_DELAY_MS); // Wait for menu to open

		return true;
	}

	/**
	 * Selects and taps the specific chief order type in the menu.
	 *
	 * <p>
	 * <b>Selection Process:</b>
	 * <ol>
	 * <li>Wait for menu UI to stabilize</li>
	 * <li>Search for the specific order type button</li>
	 * <li>Tap button to open order details</li>
	 * <li>Wait for details screen to load</li>
	 * </ol>
	 *
	 * <p>
	 * If the order button is not found, it attempts to read the cooldown time
	 * from the appropriate OCR area and reschedules the task accordingly.
	 *
	 * @return true if order type was found and selected, false if on cooldown
	 */
	private boolean selectOrderType() {
		sleepTask(MENU_LOAD_DELAY_MS); // Wait for menu UI to fully render

		logInfo("Searching for Chief Order type: " + chiefOrderType.getDescription());

		DTOImageSearchResult orderButton = searchTemplateWithLogging(
				chiefOrderType.getTemplate(),
				chiefOrderType.getDescription() + " button");

		if (!orderButton.isFound()) {
			logWarning(chiefOrderType.getDescription() +
					" button not found, attempting to read cooldown time");

			// Attempt to read cooldown time from OCR based on order type
			Duration cooldownTime = readCooldownFromMainMenu();
			if (cooldownTime != null) {
				logInfo("Cooldown time read: " + cooldownTime.toHours() + " hours");
				scheduleNextRun(cooldownTime);
			} else {
				logWarning("Could not read cooldown time, scheduling retry");
				scheduleRetry();
			}
			return false;
		}

		logInfo(chiefOrderType.getDescription() + " button found. Tapping to activate");
		tapPoint(orderButton.getPoint());
		sleepTask(MENU_LOAD_DELAY_MS); // Wait for order details to open

		return true;
	}

	/**
	 * Creates standardized OCR settings for Chief Order time reading.
	 *
	 * @return DTOTesseractSettings configured for time format recognition
	 */
	private DTOTesseractSettings createTimeOcrSettings() {
		return DTOTesseractSettings.builder()
				.setAllowedChars("0123456789:d")
				.setRemoveBackground(true)
				.build();
	}

	/**
	 * Searches for a template and returns the result with standardized logging.
	 *
	 * @param template The template to search for
	 * @param description Human-readable description for logging
	 * @return DTOImageSearchResult containing the search result
	 */
	private DTOImageSearchResult searchTemplateWithLogging(EnumTemplates template, String description) {
		logDebug("Searching for " + description);
		DTOImageSearchResult result = templateSearchHelper.searchTemplate(template, SearchConfigConstants.DEFAULT_SINGLE);

		if (result.isFound()) {
			logDebug(description + " found");
		} else {
			logDebug(description + " not found");
		}

		return result;
	}

	/**
	 * Performs OCR reading on the specified area with standardized settings.
	 *
	 * @param area The screen area to read from
	 * @param description Human-readable description for logging
	 * @return Duration representing the parsed time, or null if reading failed
	 */
	private Duration performTimeOcr(DTOArea area, String description) {
		logDebug("Performing OCR for " + description);

		try {
			Duration result = durationHelper.execute(
					area.topLeft(),
					area.bottomRight(),
					OCR_RETRY_ATTEMPTS,
					OCR_RETRY_DELAY_MS,
					createTimeOcrSettings(),
					TimeValidators::isValidTime,
					text -> TimeConverters.toDuration(text));

			if (result != null) {
				logDebug(description + " OCR successful: " + result.toHours() + " hours");
			} else {
				logWarning(description + " OCR failed: no valid time detected");
			}

			return result;
		} catch (Exception e) {
			logWarning(description + " OCR failed with exception: " + e.getMessage());
			return null;
		}
	}

	/**
	 * Gets the appropriate cooldown OCR area for the current order type.
	 *
	 * @return DTOArea for the order type's main menu cooldown display
	 */
	private DTOArea getMainMenuCooldownArea() {
		switch (chiefOrderType) {
			case URGENT_MOBILIZATION:
				return CommonGameAreas.CHIEF_ORDER_URGENT_MOBILIZATION_MAIN_COOLDOWN_OCR_AREA;
			case RUSH_JOB:
				return CommonGameAreas.CHIEF_ORDER_RUSH_JOB_MAIN_COOLDOWN_OCR_AREA;
			case PRODUCTIVITY_DAY:
				return CommonGameAreas.CHIEF_ORDER_PRODUCTIVITY_DAY_MAIN_COOLDOWN_OCR_AREA;
			default:
				logError("Unknown chief order type: " + chiefOrderType);
				return null;
		}
	}

	/**
	 * Reads cooldown time from the main menu OCR area based on the current order type.
	 *
	 * @return Duration representing the cooldown time, or null if reading failed
	 */
	private Duration readCooldownFromMainMenu() {
		DTOArea ocrArea = getMainMenuCooldownArea();
		if (ocrArea == null) {
			return null;
		}

		return performTimeOcr(ocrArea, chiefOrderType.getDescription() + " main menu cooldown");
	}

	/**
	 * Enacts the selected chief order by tapping the Enact button.
	 *
	 * <p>
	 * <b>Enactment Process:</b>
	 * <ol>
	 * <li>Wait for order details to fully load</li>
	 * <li>Search for Enact button</li>
	 * <li>Tap Enact button to activate order</li>
	 * <li>Wait for activation animation</li>
	 * <li>Navigate back to skip completion animation</li>
	 * </ol>
	 *
	 * <p>
	 * If the Enact button is not found, it attempts to determine if the order
	 * is active or on cooldown by checking templates and reading OCR accordingly.
	 * If neither active nor cooldown templates are found, it schedules a retry.
	 *
	 * @return true if order was successfully enacted, false otherwise
	 */
	private boolean enactOrder() {
		sleepTask(MENU_LOAD_DELAY_MS); // Wait for order details screen to fully load

		logInfo("Searching for Chief Order Enact button");

		DTOImageSearchResult enactButton = searchTemplateWithLogging(
				EnumTemplates.CHIEF_ORDER_ENACT_BUTTON,
				"Chief Order Enact button");

		if (!enactButton.isFound()) {
			logWarning("Chief Order Enact button not found, checking order status");
			return checkOrderStatus();
		}

		return performEnactment(enactButton);
	}

	/**
	 * Checks the current status of the Chief Order when enact button is not available.
	 *
	 * @return false (always reschedules based on status)
	 */
	private boolean checkOrderStatus() {
		// Check if order is currently active
		DTOImageSearchResult activeTemplate = searchTemplateWithLogging(
				EnumTemplates.CHIEF_ORDER_DETAIL_ACTIVE,
				"Chief Order active indicator");

		if (activeTemplate.isFound()) {
			return handleActiveOrder();
		}

		// Check if order is on cooldown
		DTOImageSearchResult cooldownTemplate = searchTemplateWithLogging(
				EnumTemplates.CHIEF_ORDER_DETAIL_COOLDOWN,
				"Chief Order cooldown indicator");

		if (cooldownTemplate.isFound()) {
			return handleCooldownOrder();
		}

		// Neither active nor cooldown templates found
		return handleUnknownOrderStatus();
	}

	/**
	 * Handles the case when the Chief Order is currently active.
	 *
	 * @return false (reschedules based on remaining active time)
	 */
	private boolean handleActiveOrder() {
		logInfo("Chief Order is currently active, reading remaining time");

		Duration remainingTime = performTimeOcr(
				CommonGameAreas.CHIEF_ORDER_DETAIL_ACTIVE_OCR_AREA,
				"Chief Order active time");

		if (remainingTime != null) {
			logInfo("Active time remaining: " + remainingTime.toHours() + " hours");
			scheduleNextRun(remainingTime);
		} else {
			logWarning("Could not read active time, scheduling retry");
			scheduleRetry();
		}

		return false;
	}

	/**
	 * Handles the case when the Chief Order is on cooldown.
	 *
	 * @return false (reschedules based on cooldown time)
	 */
	private boolean handleCooldownOrder() {
		logInfo("Chief Order is on cooldown, reading cooldown time");

		Duration cooldownTime = performTimeOcr(
				CommonGameAreas.CHIEF_ORDER_DETAIL_COOLDOWN_OCR_AREA,
				"Chief Order cooldown time");

		if (cooldownTime != null) {
			logInfo("Cooldown time: " + cooldownTime.toHours() + " hours");
			scheduleNextRun(cooldownTime);
		} else {
			logWarning("Could not read cooldown time, scheduling retry");
			scheduleRetry();
		}

		return false;
	}

	/**
	 * Handles the case when neither active nor cooldown templates are found.
	 *
	 * @return false (schedules retry)
	 */
	private boolean handleUnknownOrderStatus() {
		logWarning("Neither active nor cooldown templates found, scheduling retry");
		scheduleRetry();
		return false;
	}

	/**
	 * Performs the actual enactment process when the enact button is found.
	 *
	 * @param enactButton The search result containing the enact button location
	 * @return true if enactment was successful
	 */
	private boolean performEnactment(DTOImageSearchResult enactButton) {
		logInfo("Enact button found. Tapping to enact order");
		tapPoint(enactButton.getPoint());
		sleepTask(ENACT_PROCESS_DELAY_MS); // Wait for enact action to register

		// Navigate back to skip activation animation
		tapBackButton();
		sleepTask(ANIMATION_COMPLETE_DELAY_MS); // Wait for animation to complete

		logInfo(chiefOrderType.getDescription() + " activated successfully");
		scheduleNextRun();
		return true;
	}

	/**
	 * Schedules the next execution of this task after successful completion.
	 *
	 * <p>
	 * The task reschedules itself based on the order type's cooldown period,
	 * which varies by order:
	 * <ul>
	 * <li>Rush Job: 24 hours</li>
	 * <li>Urgent Mobilization: 8 hours</li>
	 * <li>Productivity Day: 12 hours</li>
	 * </ul>
	 */
	private void scheduleNextRun() {
		Duration cooldownDuration = Duration.ofHours(chiefOrderType.getCooldownHours());
		LocalDateTime nextExecutionTime = LocalDateTime.now().plus(cooldownDuration);

		reschedule(nextExecutionTime);

		logInfo("Chief Order activated successfully. Next execution in " +
				chiefOrderType.getCooldownHours() + " hours");
	}

	/**
	 * Schedules the next execution of this task based on the provided cooldown duration.
	 *
	 * <p>
	 * This method is used when the cooldown time is determined dynamically
	 * through OCR reading rather than using the fixed cooldown hours.
	 *
	 * @param cooldownDuration The duration to wait before next execution
	 */
	private void scheduleNextRun(Duration cooldownDuration) {
		LocalDateTime nextExecutionTime = LocalDateTime.now().plus(cooldownDuration);

		reschedule(nextExecutionTime);

		logInfo("Task rescheduled based on OCR reading. Next execution in " +
				cooldownDuration.toHours() + " hours");
	}

	/**
	 * Schedules a retry execution after an error occurs.
	 *
	 * <p>
	 * This method is used when template detection fails or OCR reading fails,
	 * scheduling a retry after {@value ERROR_RETRY_MINUTES} minutes to allow
	 * for temporary UI issues or recognition failures.
	 */
	private void scheduleRetry() {
		LocalDateTime retryTime = LocalDateTime.now().plusMinutes(ERROR_RETRY_MINUTES);
		reschedule(retryTime);

		logInfo("Task scheduled for retry in " + ERROR_RETRY_MINUTES + " minutes");
	}

}