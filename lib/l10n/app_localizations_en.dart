// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AxisMind';

  @override
  String get startPractice => 'START PRACTICE';

  @override
  String get openPathToClarity => 'OPEN PATH TO CLARITY';

  @override
  String get continueLabel => 'Continue';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get skip => 'Skip';

  @override
  String get close => 'Close';

  @override
  String get done => 'Done';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get setup => 'Setup';

  @override
  String get create => 'Create';

  @override
  String get sendTest => 'Send Test';

  @override
  String get learnMore => 'LEARN MORE';

  @override
  String get startPracticeBtn => 'START PRACTICE';

  @override
  String get exhale => 'EXHALE';

  @override
  String get reset => 'RESET';

  @override
  String get repeat => 'Repeat';

  @override
  String get ok => 'OK!';

  @override
  String get great => 'Great!';

  @override
  String get chooseDuration => 'Choose duration';

  @override
  String get selectDurationColon => 'Choose duration:';

  @override
  String get presetQuick => 'Quick';

  @override
  String get presetQuickSub => 'Break';

  @override
  String get presetStandard => 'Standard';

  @override
  String get presetStandardSub => 'Daily';

  @override
  String get presetDeep => 'Deep';

  @override
  String get presetDeepSub => 'Evening';

  @override
  String get presetMaster => 'Master';

  @override
  String get presetMasterSub => 'Weekend';

  @override
  String min(Object minutes) {
    return '$minutes min';
  }

  @override
  String minutesLabelWithName(Object minutes, Object name) {
    return '$minutes min — $name';
  }

  @override
  String get navPractice => 'Practice';

  @override
  String get navJournal => 'Journal';

  @override
  String get navStatistics => 'Statistics';

  @override
  String get navGuide => 'Path to Clarity';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get premium => 'Premium';

  @override
  String get premiumActive => 'Premium active';

  @override
  String get authGoogle => 'Sign in with Google';

  @override
  String get authSignOut => 'Sign out';

  @override
  String get authContinueWithout => 'Continue without sign in';

  @override
  String get authTitle => 'Your path to mindfulness';

  @override
  String get authSubtitle =>
      'Sign in is only used to sync\nyour data between devices';

  @override
  String get authGoogleTitle => 'Google Authorization';

  @override
  String get authGoogleSubtitle =>
      'Available on mobile devices and web.\nOn desktop, the app works in local mode.';

  @override
  String authError(Object error) {
    return 'Sign in error: $error';
  }

  @override
  String get authCloseTooltip => 'Close';

  @override
  String get userPlaceholder => 'User';

  @override
  String get paywallTitle => 'Unlock the full\npotential of AxisMind';

  @override
  String get try7DaysFree => 'Try 7 days free';

  @override
  String thenPrice(Object price) {
    return 'then $price';
  }

  @override
  String get cancelAnytime => 'Cancel anytime';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get continueFree => 'Continue free';

  @override
  String get paywallCloseTooltip => 'Close';

  @override
  String get purchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get subscriptionRestored => 'Subscription restored!';

  @override
  String get noActivePurchases => 'No active purchases found.';

  @override
  String get paymentTerms =>
      'Payment will be charged to your Google Play account after purchase confirmation. Subscription automatically renews unless canceled 24 hours before the end of the current period. Manage your subscription in Google Play settings.';

  @override
  String get featureMotivationalNotifications => 'Motivational notifications';

  @override
  String get featureMotivationalNotificationsSub =>
      'Inspiring quotes and progress statistics';

  @override
  String get featureGoalReminders => 'Goal reminders';

  @override
  String get featureGoalRemindersSub =>
      'Daily reminder if a goal is not completed';

  @override
  String get featureMeditationGoals => 'Meditation goals';

  @override
  String get featureMeditationGoalsSub => 'Create and track your goals';

  @override
  String get featureDetailedStats => 'Detailed statistics';

  @override
  String get featureDetailedStatsSub => 'Heat map, level progress and XP';

  @override
  String get featureDeviceSync => 'Device sync';

  @override
  String get featureDeviceSyncSub => 'Your data is always with you';

  @override
  String get journalTitle => 'Meditation Journal';

  @override
  String get journalEdit => 'Edit entry';

  @override
  String get journalNew => 'Record your feelings';

  @override
  String journalSession(Object duration) {
    return 'Session: $duration';
  }

  @override
  String get journalMood => 'How do you feel?';

  @override
  String get journalNote => 'Write what came to mind...';

  @override
  String get journalTag => 'Tag (optional)';

  @override
  String get journalSearch => 'Search notes...';

  @override
  String get journalAllTags => 'All';

  @override
  String get journalEmpty => 'Nothing here yet';

  @override
  String get journalEmptySubtitle =>
      'Complete a meditation\nto see your first entry';

  @override
  String get journalUpdateFailed => 'Failed to update entry';

  @override
  String get journalDeleteConfirm => 'Delete entry?';

  @override
  String get journalDeleteConfirmSub => 'This action cannot be undone.';

  @override
  String get journalDeleted => 'Entry deleted';

  @override
  String get journalDeleteFailed => 'Failed to delete entry';

  @override
  String get tagMorning => 'Morning';

  @override
  String get tagDay => 'Day';

  @override
  String get tagEvening => 'Evening';

  @override
  String get tagStress => 'Stress';

  @override
  String get tagCalm => 'Calm';

  @override
  String get tagGratitude => 'Gratitude';

  @override
  String get goalsTitle => 'Goal Settings';

  @override
  String get goalsSubtitle =>
      'Goals help track practice regularity\nand give bonus XP for completion.';

  @override
  String get goalsCurrent => 'Current Goals';

  @override
  String get goalsMaxReached => 'Maximum 4 goals';

  @override
  String get goalsAdd => 'Add goal';

  @override
  String get goalsNoGoals => 'You have no goals yet';

  @override
  String get goalsNoGoalsSubtitle =>
      'Set a goal to track progress\nand earn bonus XP';

  @override
  String get goalsCreate => 'Create goal';

  @override
  String get goalsEdit => 'Edit goal';

  @override
  String get goalsNew => 'New goal';

  @override
  String get goalsDeleteConfirm => 'Delete goal?';

  @override
  String goalsDeleteConfirmSub(Object name) {
    return 'Are you sure you want to delete the goal \"$name\"?';
  }

  @override
  String goalsGoalLabel(Object target, Object unit, Object xp) {
    return '$target $unit · +$xp XP';
  }

  @override
  String get goalsTypeLabel => 'Goal type';

  @override
  String get goalsTargetLabel => 'Target value';

  @override
  String get goalsTargetHintDaily => 'For example: 10 minutes per day';

  @override
  String get goalsTargetHintWeeklySessions =>
      'For example: 5 sessions per week';

  @override
  String get goalsTargetHintWeeklyMinutes => 'For example: 60 minutes per week';

  @override
  String get goalsTargetHintStreak => 'For example: 7 days in a row';

  @override
  String get goalDailyMinutes => 'Daily practice';

  @override
  String get goalWeeklySessions => 'Sessions per week';

  @override
  String get goalWeeklyMinutes => 'Minutes per week';

  @override
  String get goalStreakDays => 'Days in a row';

  @override
  String get goalUnitMinPerDay => 'min/day';

  @override
  String get goalUnitSessPerWeek => 'sess./week';

  @override
  String get goalUnitMinPerWeek => 'min/week';

  @override
  String get goalUnitDays => 'days';

  @override
  String get statsTitle => 'Statistics';

  @override
  String statsLastDays(Object days) {
    return 'Last $days days';
  }

  @override
  String get statsTotalMinutes => 'Total minutes';

  @override
  String get statsSessions => 'Sessions';

  @override
  String get statsStreak => 'Streak';

  @override
  String get statsStreakUnit => 'day';

  @override
  String get statsStreakUnitPlural => 'days';

  @override
  String get statsGrowth => 'Growth';

  @override
  String statsGrowthPeriod(Object days) {
    return 'over $days d.';
  }

  @override
  String get statsAverage => 'average';

  @override
  String get statsAveragePerDay => 'per day on average';

  @override
  String get statsBest => 'best';

  @override
  String get statsRegularity => 'regularity';

  @override
  String get statsActivity30 => 'Activity over 30 days';

  @override
  String get statsDynamics => 'Dynamics';

  @override
  String statsAvgLabel(Object minutes) {
    return 'avg. $minutes';
  }

  @override
  String get statsPeriod7 => '7d';

  @override
  String get statsPeriod14 => '14d';

  @override
  String get statsPeriod30 => '30d';

  @override
  String get notifTitle => 'Notifications';

  @override
  String get notifSubtitle =>
      'Configure push notifications to never miss\na practice session and track your progress.';

  @override
  String get notifGeneral => 'General';

  @override
  String get notifEnabled => 'Notifications';

  @override
  String get notifEnabledSub => 'Enable or disable all notifications';

  @override
  String get notifDailyReminder => 'Daily Reminder';

  @override
  String get notifReminderTime => 'Reminder time';

  @override
  String get notifReminderTimeSub => 'Daily meditation notification';

  @override
  String get notifMotivation => 'Motivation';

  @override
  String get notifMotivationMessages => 'Motivational messages';

  @override
  String get notifMotivationSub => 'Inspiring quotes and progress statistics';

  @override
  String get notifMotivationTime => 'Motivation time';

  @override
  String get notifMotivationTimeSub => 'Daily motivational notification';

  @override
  String get notifGoals => 'Goals';

  @override
  String get notifGoalReminder => 'Goal reminder';

  @override
  String get notifGoalReminderSub =>
      'Evening reminder if daily goal is not completed';

  @override
  String get notifGoalReminderTime => 'Reminder time';

  @override
  String get notifGoalReminderTimeSub => 'Daily goal reminder';

  @override
  String get notifQuietHours => 'Quiet Hours';

  @override
  String notifQuietHoursSubEnabled(Object start, Object end) {
    return 'Do not disturb from $start to $end';
  }

  @override
  String get notifQuietHoursSubDisabled => 'Disable notifications at night';

  @override
  String get notifQuietHoursStart => 'Start';

  @override
  String get notifQuietHoursEnd => 'End';

  @override
  String get notifTesting => 'Testing';

  @override
  String get notifTestSent => 'Test notification sent!';

  @override
  String notifQuietHoursActive(Object start, Object end) {
    return 'Quiet hours are active ($start–$end). Notification will not be shown.';
  }

  @override
  String get notifTimePickerHelp => 'Select reminder time';

  @override
  String get notifTimePickerMotivationHelp => 'Motivational messages time';

  @override
  String get notifTimePickerGoalHelp => 'Goal reminder time';

  @override
  String get notifTimePickerQuietStartHelp => 'Quiet hours start';

  @override
  String get notifTimePickerQuietEndHelp => 'Quiet hours end';

  @override
  String get notifTimePickerCancel => 'Cancel';

  @override
  String get notifTimePickerConfirm => 'Done';

  @override
  String get notifTypeReminder => 'Reminders';

  @override
  String get notifTypeMotivation => 'Motivation';

  @override
  String get notifTypeGoals => 'Goals';

  @override
  String get notifTypeStreak => 'Streak';

  @override
  String get notifChannelReminders => 'Reminders';

  @override
  String get notifChannelRemindersDesc => 'Daily meditation reminders';

  @override
  String get notifChannelMotivation => 'Motivation';

  @override
  String get notifChannelMotivationDesc => 'Motivational messages and quotes';

  @override
  String get notifChannelGoals => 'Goals';

  @override
  String get notifChannelGoalsDesc => 'Goal progress notifications';

  @override
  String get notifChannelStreak => 'Streak';

  @override
  String get notifChannelStreakDesc => 'Streak celebration notifications';

  @override
  String get notifBodyReminder =>
      '🧘 Time to meditate!\nTake 10 minutes for inner silence and peace.';

  @override
  String get notifBodyGoalReminder =>
      '🎯 Time left to reach your goal!\nJust a few minutes of meditation and you\'ll earn bonus XP!';

  @override
  String notifBodyStreak(Object streak) {
    return '🔥 New record: $streak days in a row!\nCongratulations! You\'ve beaten your personal record!';
  }

  @override
  String get timerPause => 'PAUSE';

  @override
  String get timerResume => 'RESUME';

  @override
  String get timerStop => 'STOP';

  @override
  String get timerPosture => 'Back straight\nGaze down 45°\nFocus soft';

  @override
  String get timerEndMeditation => 'End meditation?';

  @override
  String get timerEndMeditationSub => 'Your practice is not yet complete.';

  @override
  String get timerContinue => 'Continue';

  @override
  String get timerEnd => 'End';

  @override
  String get timerSaveFailed => 'Failed to save session. Please try again.';

  @override
  String get timerRetry => 'Retry';

  @override
  String get guideHeroLabel => 'Alex Merch Foundation';

  @override
  String get guideTitle => 'AxisMind';

  @override
  String get guideSubtitle => 'The rational path to mental clarity';

  @override
  String get guideFinalEdition => 'FINAL EDITION 2026';

  @override
  String get guideTechnique => 'Technique: Susokukan (Breath Counting)';

  @override
  String get guideArithmetic => 'Arithmetic of Mindfulness';

  @override
  String get guidePosture => 'POSTURE';

  @override
  String get guidePostureDesc =>
      'Sit on the edge of a chair or in zazen. Back straight but relaxed. Shoulders relaxed, hands in mudra (oval lock).';

  @override
  String get guideGaze => 'GAZE';

  @override
  String get guideGazeDesc =>
      'Eyes half-open, gaze directed downward at ~45° to the floor 1–1.5 meters ahead. Do not close your eyes — this leads to drowsiness and daydreaming.';

  @override
  String get guideFocus => 'FOCUS';

  @override
  String get guideFocusDesc =>
      'Blur your vision — don\'t stare at the floor texture, don\'t fixate on points. Use peripheral vision. You look but don\'t see details.';

  @override
  String get guideAlgorithm =>
      'Count each exhale. When you reach 10, start counting backward to 1. If a thought interrupts the count — return to one.';

  @override
  String get guideBioEffect => 'Biological Effect';

  @override
  String get guideBioEffectDesc =>
      'Counting engages the prefrontal cortex, quieting the Default Mode Network (DMN) responsible for mind-wandering and anxiety.';

  @override
  String get guideZenRule => 'Zen Rule';

  @override
  String get guideZenRuleQuote =>
      '\"If you lose count at 9 — you\'ve lost the battle for attention. Humbly return to 1. This is the practice.\"';

  @override
  String get guideZazenGeometry => 'Zazen Geometry';

  @override
  String get guideFormContent => 'Form and Content';

  @override
  String get guideVertical => 'Vertical';

  @override
  String get guideVerticalDesc =>
      'Spine straight like a string. This is the physiological foundation for an alert consciousness.';

  @override
  String get guideGazeZazen => 'Gaze';

  @override
  String get guideGazeZazenDesc =>
      'Eyes half-open, gaze at 45° down, focus soft. You don\'t drift into dreams, you stay here and now.';

  @override
  String get guideMudra => 'Mudra';

  @override
  String get guideMudraDesc =>
      'Hands in an oval lock. This is your physical sensor of concentration depth.';

  @override
  String get guideResistance => 'Overcoming Resistance';

  @override
  String get guidePracticalGuide => 'Practical Guide';

  @override
  String get guideProblem => 'Problem';

  @override
  String get guideMindMechanism => 'Mind Mechanism';

  @override
  String get guideZenSolution => 'Zen Solution';

  @override
  String get guideProblemItch => 'Itching and restlessness';

  @override
  String get guideLogicItch =>
      'Ego\'s defensive reaction to unfamiliar silence.';

  @override
  String get guideActionItch =>
      'Musōtoku. Observe the itch as an external object. It will pass on its own.';

  @override
  String get guideProblemNoise => 'Mental noise';

  @override
  String get guideLogicNoise =>
      'The brain\'s attempt to fill the vacuum with habitual plans.';

  @override
  String get guideActionNoise =>
      'Susokukan. Gently return attention to counting \"One\". Without aggression.';

  @override
  String get guideProblemSleep => 'Drowsiness';

  @override
  String get guideLogicSleep => 'A sign of lost tone and slipping into trance.';

  @override
  String get guideActionSleep =>
      'Energy. Straighten your back. Open your eyes slightly. Breathe a little deeper.';

  @override
  String get guideWitness => 'Be the Witness.';

  @override
  String get guideQuote => 'Your mind — your greatest asset.';

  @override
  String get guideFooter => 'ALEX MERCH • AXISMIND SYSTEM • 2026';

  @override
  String levelUpTitle(Object level) {
    return 'Level $level';
  }

  @override
  String get goalCompleted => 'Goal completed!';

  @override
  String get goalCompletedClose => 'Great!';

  @override
  String get emptyDashboardTitle =>
      'Your path to peace\nbegins with the first minute';

  @override
  String get emptyDashboardSubtitle =>
      'Complete your first meditation\nto see your statistics here';

  @override
  String get errorUnknown => 'An unknown error occurred';

  @override
  String get errorDatabase => 'Database error. Please restart the app.';

  @override
  String get errorNetwork =>
      'Connection issue. Check your internet connection.';

  @override
  String get errorStats => 'Failed to load statistics.';

  @override
  String get errorStatsRetry => 'Failed to load statistics. Please try again.';

  @override
  String get errorStatsRefresh =>
      'Failed to load statistics. Please try again.';

  @override
  String get errorDataRefreshing => 'Data is updating...';

  @override
  String get rankNovice => 'Mindfulness Novice';

  @override
  String get rankSeeker => 'Peace Seeker';

  @override
  String get rankGuardian => 'Silence Guardian';

  @override
  String get rankMaster => 'Balance Master';

  @override
  String get rankWanderer => 'Depth Wanderer';

  @override
  String get rankAwakened => 'Awakened One';

  @override
  String get rankSage => 'Sage';

  @override
  String get rankEnlightened => 'Enlightened One';

  @override
  String get rankLegend => 'Legend';

  @override
  String get rankImmortal => 'Immortal';

  @override
  String get rankDivine => 'Divine';

  @override
  String get rankDescriptionNovice => 'First step on the path to mindfulness';

  @override
  String get rankDescriptionSeeker => 'Searching for inner harmony';

  @override
  String get rankDescriptionGuardian => 'Finding silence within';

  @override
  String get rankDescriptionMaster => 'Balance between effort and peace';

  @override
  String get rankDescriptionWanderer => 'Exploring the depths of consciousness';

  @override
  String get rankDescriptionAwakened => 'Awakening inner light';

  @override
  String get rankDescriptionSage => 'Wisdom born from practice';

  @override
  String get rankDescriptionEnlightened =>
      'The light of mindfulness guides you';

  @override
  String get rankDescriptionLegend => 'Your journey inspires others';

  @override
  String get rankDescriptionImmortal => 'Timeless practice';

  @override
  String get rankDescriptionDivine => 'You have reached enlightenment';

  @override
  String rankLevel(Object level) {
    return 'Level $level';
  }

  @override
  String get rankYouAreHere => 'You are here';

  @override
  String get rankContinuePractice => 'Continue practicing to unlock new ranks';

  @override
  String get rankClose => 'Close';

  @override
  String get rankTiers => 'Tiers';

  @override
  String get rankRequiredPractice => 'Practice required';

  @override
  String get rankProgressToNext => 'Progress to next rank';

  @override
  String rankRemainingMinutes(Object minutes) {
    return '~$minutes min remaining to next rank';
  }

  @override
  String rankRemainingToNext(Object minutes) {
    return '$minutes min remaining to next level';
  }

  @override
  String get rankStatusCompleted => 'Completed';

  @override
  String get rankStatusCurrent => 'Current rank';

  @override
  String get rankStatusLocked => 'Not available yet';

  @override
  String rankLevelRangeOpen(Object min) {
    return '$min+ lvl';
  }

  @override
  String rankLevelRangeSingle(Object min) {
    return '$min lvl';
  }

  @override
  String rankLevelRangeMulti(Object min, Object max) {
    return '$min–$max lvl';
  }

  @override
  String rankMinutesRequired(Object minutes) {
    return '$minutes min';
  }

  @override
  String rankMinutesRequiredThousands(Object value) {
    return '${value}K min';
  }

  @override
  String rankMinutesTotal(Object minutes) {
    return '$minutes min total';
  }

  @override
  String rankMinutesTotalThousands(Object value) {
    return '${value}K min total';
  }

  @override
  String get subscriptionGuardLoading => 'AxisMind';

  @override
  String get samadhiExitHint => 'Press Space or click to exit';

  @override
  String get neuroPreset5 =>
      'Stopping «mental noise».\nRapid return of attentional control.';

  @override
  String get neuroPreset10 =>
      'Reduction of physical tension.\nDeep ordering of mental activity.';

  @override
  String get neuroPreset15 =>
      'Deep stabilization of perception.\nTransition to mental silence and peace.';

  @override
  String get neuroPreset20 =>
      'Classic Zen training.\nReduction of sympathetic tone and absolute clarity of mind.';

  @override
  String get daySun => 'Sun';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get dayShortSun => 'Su';

  @override
  String get dayShortMon => 'Mo';

  @override
  String get dayShortTue => 'Tu';

  @override
  String get dayShortWed => 'We';

  @override
  String get dayShortThu => 'Th';

  @override
  String get dayShortFri => 'Fr';

  @override
  String get dayShortSat => 'Sa';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get month => '/month';

  @override
  String get openGuide => 'OPEN PATH TO CLARITY';

  @override
  String get journal => 'Journal';

  @override
  String get statistics => 'Statistics';

  @override
  String get notifications => 'Notifications';

  @override
  String get user => 'User';

  @override
  String get quote1 =>
      'Silence is not the absence of sound, but the presence of self.';

  @override
  String get quote2 => 'Every minute of meditation is an investment in peace.';

  @override
  String get quote3 =>
      'Breathe deeper — there is a whole ocean of calm within you.';

  @override
  String get quote4 =>
      'Don\'t try to stop your thoughts. Learn not to engage with them.';

  @override
  String get quote5 => 'Meditation is not a technique, but a way of being.';

  @override
  String get quote6 =>
      'Inner peace begins the moment you decide not to let the outer world control you.';

  @override
  String get quote7 => 'Mindfulness is the key that opens the door to harmony.';

  @override
  String get quote8 =>
      'Your practice is your island. No one can take it from you.';

  @override
  String get quote9 => 'Pause. Breathe. You are already on the right path.';

  @override
  String get quote10 => 'Every day is a new opportunity to return to yourself.';

  @override
  String get quote11 => 'Strength is not in tension, but in relaxation.';

  @override
  String get quote12 => 'Meditation is coming home to your true Self.';

  @override
  String get quote13 => 'Don\'t wait for the perfect moment. Start now.';

  @override
  String get quote14 => 'Your breath is an anchor in the present moment.';

  @override
  String get quote15 =>
      'Progress is not a straight line. Every minute of practice matters.';

  @override
  String get guideHeroSubtitle => 'A rational path to mental clarity';

  @override
  String get guideSusokukanLabel => 'Technique: Susokukan (Breath Counting)';

  @override
  String get guideSusokukanTitle => 'The Arithmetic of Mindfulness';

  @override
  String get guideStepPostureTitle => 'POSTURE';

  @override
  String get guideStepPostureDesc =>
      'Sit on the edge of a chair or in zazen. Spine straight, but without tension. Shoulders relaxed, hands in mudra (cosmic oval).';

  @override
  String get guideStepGazeTitle => 'GAZE';

  @override
  String get guideStepGazeDesc =>
      'Eyes slightly open, cast downward at a ~45° angle to the floor in front of you (1–1.5 meters). Do not close your eyes — that leads to drowsiness and daydreaming.';

  @override
  String get guideStepFocusTitle => 'FOCUS';

  @override
  String get guideStepFocusDesc =>
      'Soften your gaze — do not stare at the floor texture or fixate on spots. Use peripheral vision. You look, but do not cling to details.';

  @override
  String get guideSusokukanInstruction =>
      'Count each exhalation. Reaching 10, start counting back down to 1. If a thought interrupts the count — return to 1.';

  @override
  String get guideBioEffectTitle => 'Biological Effect';

  @override
  String get guideZenRuleTitle => 'Zen Rule';

  @override
  String get guideZenRuleDesc =>
      '“If you lose count at 9, you have lost the battle for attention. Humbly return to 1. That is the practice.”';

  @override
  String get guideZazenLabel => 'Form and Essence';

  @override
  String get guideZazenTitle => 'Geometry of Zazen';

  @override
  String get guideZazenVerticalTitle => 'Vertical';

  @override
  String get guideZazenVerticalDesc =>
      'Spine straight as a string. This is the physiological foundation for an awake consciousness.';

  @override
  String get guideZazenGazeTitle => 'Gaze';

  @override
  String get guideZazenGazeDesc =>
      'Eyes slightly open, cast down at 45°, soft focus. You do not drift into daydreaming; you remain here and now.';

  @override
  String get guideZazenMudraTitle => 'Mudra';

  @override
  String get guideZazenMudraDesc =>
      'Hands in a cosmic oval clasp. This is your physical sensor of concentration depth.';

  @override
  String get guideResistanceLabel => 'Practical Guide';

  @override
  String get guideResistanceTitle => 'Overcoming Resistance';

  @override
  String get guideHeaderProblem => 'Problem';

  @override
  String get guideHeaderLogic => 'Mind Mechanism';

  @override
  String get guideHeaderAction => 'Zen Solution';

  @override
  String get guideProblem1 => 'Itch and Restlessness';

  @override
  String get guideLogic1 =>
      'The ego\'s defensive reaction to unusual stillness.';

  @override
  String get guideAction1 =>
      'Mushotoku. Observe the itch as an external object. It will pass on its own.';

  @override
  String get guideProblem2 => 'Mental Noise';

  @override
  String get guideLogic2 =>
      'The brain attempting to fill the vacuum with familiar plans.';

  @override
  String get guideAction2 =>
      'Susokukan. Gently return attention to the count of \'One\'. Without aggression.';

  @override
  String get guideProblem3 => 'Drowsiness';

  @override
  String get guideLogic3 =>
      'A sign of decreasing tone and drifting into a trance.';

  @override
  String get guideAction3 =>
      'Energy. Straighten your spine. Open your eyes slightly. Breathe a little deeper.';

  @override
  String get guideFinalTitle => 'Be the Witness.';

  @override
  String get guideFinalQuote => 'Your mind is your greatest asset.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start Practice';

  @override
  String get onboardingTitle1 => 'Mindfulness and Peace';

  @override
  String get onboardingDesc1 =>
      'Welcome to AxisMind. Discover your inner balance through regular meditation and focus practices.';

  @override
  String get onboardingTitle2 => 'Breathing Practices';

  @override
  String get onboardingDesc2 =>
      'Use proven techniques such as Susokukan for deep concentration and relaxation.';

  @override
  String get onboardingTitle3 => 'Sync and Progress';

  @override
  String get onboardingDesc3 =>
      'Track session statistics, configure timers, and safely store your progress in the cloud.';
}
