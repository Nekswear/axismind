import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AxisMind'**
  String get appTitle;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'START PRACTICE'**
  String get startPractice;

  /// No description provided for @openPathToClarity.
  ///
  /// In en, this message translates to:
  /// **'OPEN PATH TO CLARITY'**
  String get openPathToClarity;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @setup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setup;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @sendTest.
  ///
  /// In en, this message translates to:
  /// **'Send Test'**
  String get sendTest;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'LEARN MORE'**
  String get learnMore;

  /// No description provided for @startPracticeBtn.
  ///
  /// In en, this message translates to:
  /// **'START PRACTICE'**
  String get startPracticeBtn;

  /// No description provided for @exhale.
  ///
  /// In en, this message translates to:
  /// **'EXHALE'**
  String get exhale;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get reset;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK!'**
  String get ok;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get great;

  /// No description provided for @chooseDuration.
  ///
  /// In en, this message translates to:
  /// **'Choose duration'**
  String get chooseDuration;

  /// No description provided for @selectDurationColon.
  ///
  /// In en, this message translates to:
  /// **'Choose duration:'**
  String get selectDurationColon;

  /// No description provided for @presetQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get presetQuick;

  /// No description provided for @presetQuickSub.
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get presetQuickSub;

  /// No description provided for @presetStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get presetStandard;

  /// No description provided for @presetStandardSub.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get presetStandardSub;

  /// No description provided for @presetDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get presetDeep;

  /// No description provided for @presetDeepSub.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get presetDeepSub;

  /// No description provided for @presetMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get presetMaster;

  /// No description provided for @presetMasterSub.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get presetMasterSub;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String min(Object minutes);

  /// No description provided for @minutesLabelWithName.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min — {name}'**
  String minutesLabelWithName(Object minutes, Object name);

  /// No description provided for @navPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get navPractice;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get navStatistics;

  /// No description provided for @navGuide.
  ///
  /// In en, this message translates to:
  /// **'Path to Clarity'**
  String get navGuide;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get premiumActive;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authGoogle;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authContinueWithout.
  ///
  /// In en, this message translates to:
  /// **'Continue without sign in'**
  String get authContinueWithout;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Your path to mindfulness'**
  String get authTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in is only used to sync\nyour data between devices'**
  String get authSubtitle;

  /// No description provided for @authGoogleTitle.
  ///
  /// In en, this message translates to:
  /// **'Google Authorization'**
  String get authGoogleTitle;

  /// No description provided for @authGoogleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available on mobile devices and web.\nOn desktop, the app works in local mode.'**
  String get authGoogleSubtitle;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Sign in error: {error}'**
  String authError(Object error);

  /// No description provided for @authCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get authCloseTooltip;

  /// No description provided for @userPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userPlaceholder;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the full\npotential of AxisMind'**
  String get paywallTitle;

  /// No description provided for @try7DaysFree.
  ///
  /// In en, this message translates to:
  /// **'Try 7 days free'**
  String get try7DaysFree;

  /// No description provided for @thenPrice.
  ///
  /// In en, this message translates to:
  /// **'then {price}'**
  String thenPrice(Object price);

  /// No description provided for @cancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get cancelAnytime;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @continueFree.
  ///
  /// In en, this message translates to:
  /// **'Continue free'**
  String get continueFree;

  /// No description provided for @paywallCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get paywallCloseTooltip;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get purchaseFailed;

  /// No description provided for @subscriptionRestored.
  ///
  /// In en, this message translates to:
  /// **'Subscription restored!'**
  String get subscriptionRestored;

  /// No description provided for @noActivePurchases.
  ///
  /// In en, this message translates to:
  /// **'No active purchases found.'**
  String get noActivePurchases;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment will be charged to your Google Play account after purchase confirmation. Subscription automatically renews unless canceled 24 hours before the end of the current period. Manage your subscription in Google Play settings.'**
  String get paymentTerms;

  /// No description provided for @featureMotivationalNotifications.
  ///
  /// In en, this message translates to:
  /// **'Motivational notifications'**
  String get featureMotivationalNotifications;

  /// No description provided for @featureMotivationalNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Inspiring quotes and progress statistics'**
  String get featureMotivationalNotificationsSub;

  /// No description provided for @featureGoalReminders.
  ///
  /// In en, this message translates to:
  /// **'Goal reminders'**
  String get featureGoalReminders;

  /// No description provided for @featureGoalRemindersSub.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder if a goal is not completed'**
  String get featureGoalRemindersSub;

  /// No description provided for @featureMeditationGoals.
  ///
  /// In en, this message translates to:
  /// **'Meditation goals'**
  String get featureMeditationGoals;

  /// No description provided for @featureMeditationGoalsSub.
  ///
  /// In en, this message translates to:
  /// **'Create and track your goals'**
  String get featureMeditationGoalsSub;

  /// No description provided for @featureDetailedStats.
  ///
  /// In en, this message translates to:
  /// **'Detailed statistics'**
  String get featureDetailedStats;

  /// No description provided for @featureDetailedStatsSub.
  ///
  /// In en, this message translates to:
  /// **'Heat map, level progress and XP'**
  String get featureDetailedStatsSub;

  /// No description provided for @featureDeviceSync.
  ///
  /// In en, this message translates to:
  /// **'Device sync'**
  String get featureDeviceSync;

  /// No description provided for @featureDeviceSyncSub.
  ///
  /// In en, this message translates to:
  /// **'Your data is always with you'**
  String get featureDeviceSyncSub;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Meditation Journal'**
  String get journalTitle;

  /// No description provided for @journalEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get journalEdit;

  /// No description provided for @journalNew.
  ///
  /// In en, this message translates to:
  /// **'Record your feelings'**
  String get journalNew;

  /// No description provided for @journalSession.
  ///
  /// In en, this message translates to:
  /// **'Session: {duration}'**
  String journalSession(Object duration);

  /// No description provided for @journalMood.
  ///
  /// In en, this message translates to:
  /// **'How do you feel?'**
  String get journalMood;

  /// No description provided for @journalNote.
  ///
  /// In en, this message translates to:
  /// **'Write what came to mind...'**
  String get journalNote;

  /// No description provided for @journalTag.
  ///
  /// In en, this message translates to:
  /// **'Tag (optional)'**
  String get journalTag;

  /// No description provided for @journalSearch.
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get journalSearch;

  /// No description provided for @journalAllTags.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get journalAllTags;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get journalEmpty;

  /// No description provided for @journalEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete a meditation\nto create your first entry'**
  String get journalEmptySubtitle;

  /// No description provided for @journalUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update entry'**
  String get journalUpdateFailed;

  /// No description provided for @journalDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get journalDeleteConfirm;

  /// No description provided for @journalDeleteConfirmSub.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get journalDeleteConfirmSub;

  /// No description provided for @journalDeleted.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get journalDeleted;

  /// No description provided for @journalDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete entry'**
  String get journalDeleteFailed;

  /// No description provided for @tagMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get tagMorning;

  /// No description provided for @tagDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get tagDay;

  /// No description provided for @tagEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get tagEvening;

  /// No description provided for @tagStress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get tagStress;

  /// No description provided for @tagCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get tagCalm;

  /// No description provided for @tagGratitude.
  ///
  /// In en, this message translates to:
  /// **'Gratitude'**
  String get tagGratitude;

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Settings'**
  String get goalsTitle;

  /// No description provided for @goalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Goals help track practice regularity\nand give bonus XP for completion.'**
  String get goalsSubtitle;

  /// No description provided for @goalsCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Goals'**
  String get goalsCurrent;

  /// No description provided for @goalsMaxReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 4 goals'**
  String get goalsMaxReached;

  /// No description provided for @goalsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get goalsAdd;

  /// No description provided for @goalsNoGoals.
  ///
  /// In en, this message translates to:
  /// **'You have no goals yet'**
  String get goalsNoGoals;

  /// No description provided for @goalsNoGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set a goal to track progress\nand earn bonus XP'**
  String get goalsNoGoalsSubtitle;

  /// No description provided for @goalsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get goalsCreate;

  /// No description provided for @goalsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalsEdit;

  /// No description provided for @goalsNew.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalsNew;

  /// No description provided for @goalsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get goalsDeleteConfirm;

  /// No description provided for @goalsDeleteConfirmSub.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the goal \"{name}\"?'**
  String goalsDeleteConfirmSub(Object name);

  /// No description provided for @goalsGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'{target} {unit} · +{xp} XP'**
  String goalsGoalLabel(Object target, Object unit, Object xp);

  /// No description provided for @goalsTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal type'**
  String get goalsTypeLabel;

  /// No description provided for @goalsTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target value'**
  String get goalsTargetLabel;

  /// No description provided for @goalsTargetHintDaily.
  ///
  /// In en, this message translates to:
  /// **'For example: 10 minutes per day'**
  String get goalsTargetHintDaily;

  /// No description provided for @goalsTargetHintWeeklySessions.
  ///
  /// In en, this message translates to:
  /// **'For example: 5 sessions per week'**
  String get goalsTargetHintWeeklySessions;

  /// No description provided for @goalsTargetHintWeeklyMinutes.
  ///
  /// In en, this message translates to:
  /// **'For example: 60 minutes per week'**
  String get goalsTargetHintWeeklyMinutes;

  /// No description provided for @goalsTargetHintStreak.
  ///
  /// In en, this message translates to:
  /// **'For example: 7 days in a row'**
  String get goalsTargetHintStreak;

  /// No description provided for @goalDailyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Daily practice'**
  String get goalDailyMinutes;

  /// No description provided for @goalWeeklySessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions per week'**
  String get goalWeeklySessions;

  /// No description provided for @goalWeeklyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes per week'**
  String get goalWeeklyMinutes;

  /// No description provided for @goalStreakDays.
  ///
  /// In en, this message translates to:
  /// **'Days in a row'**
  String get goalStreakDays;

  /// No description provided for @goalUnitMinPerDay.
  ///
  /// In en, this message translates to:
  /// **'min/day'**
  String get goalUnitMinPerDay;

  /// No description provided for @goalUnitSessPerWeek.
  ///
  /// In en, this message translates to:
  /// **'sess./week'**
  String get goalUnitSessPerWeek;

  /// No description provided for @goalUnitMinPerWeek.
  ///
  /// In en, this message translates to:
  /// **'min/week'**
  String get goalUnitMinPerWeek;

  /// No description provided for @goalUnitDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get goalUnitDays;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsLastDays.
  ///
  /// In en, this message translates to:
  /// **'Last {days} days'**
  String statsLastDays(Object days);

  /// No description provided for @statsTotalMinutes.
  ///
  /// In en, this message translates to:
  /// **'Total minutes'**
  String get statsTotalMinutes;

  /// No description provided for @statsSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get statsSessions;

  /// No description provided for @statsStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get statsStreak;

  /// No description provided for @statsStreakUnit.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get statsStreakUnit;

  /// No description provided for @statsStreakUnitPlural.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get statsStreakUnitPlural;

  /// No description provided for @statsGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get statsGrowth;

  /// No description provided for @statsGrowthPeriod.
  ///
  /// In en, this message translates to:
  /// **'over {days} d.'**
  String statsGrowthPeriod(Object days);

  /// No description provided for @statsAverage.
  ///
  /// In en, this message translates to:
  /// **'average'**
  String get statsAverage;

  /// No description provided for @statsAveragePerDay.
  ///
  /// In en, this message translates to:
  /// **'per day on average'**
  String get statsAveragePerDay;

  /// No description provided for @statsBest.
  ///
  /// In en, this message translates to:
  /// **'best'**
  String get statsBest;

  /// No description provided for @statsRegularity.
  ///
  /// In en, this message translates to:
  /// **'regularity'**
  String get statsRegularity;

  /// No description provided for @statsActivity30.
  ///
  /// In en, this message translates to:
  /// **'Activity over 30 days'**
  String get statsActivity30;

  /// No description provided for @statsDynamics.
  ///
  /// In en, this message translates to:
  /// **'Dynamics'**
  String get statsDynamics;

  /// No description provided for @statsAvgLabel.
  ///
  /// In en, this message translates to:
  /// **'avg. {minutes}'**
  String statsAvgLabel(Object minutes);

  /// No description provided for @statsPeriod7.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get statsPeriod7;

  /// No description provided for @statsPeriod14.
  ///
  /// In en, this message translates to:
  /// **'14d'**
  String get statsPeriod14;

  /// No description provided for @statsPeriod30.
  ///
  /// In en, this message translates to:
  /// **'30d'**
  String get statsPeriod30;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure push notifications to never miss\na practice session and track your progress.'**
  String get notifSubtitle;

  /// No description provided for @notifGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notifGeneral;

  /// No description provided for @notifEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifEnabled;

  /// No description provided for @notifEnabledSub.
  ///
  /// In en, this message translates to:
  /// **'Enable or disable all notifications'**
  String get notifEnabledSub;

  /// No description provided for @notifDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get notifDailyReminder;

  /// No description provided for @notifReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notifReminderTime;

  /// No description provided for @notifReminderTimeSub.
  ///
  /// In en, this message translates to:
  /// **'Daily meditation notification'**
  String get notifReminderTimeSub;

  /// No description provided for @notifMotivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get notifMotivation;

  /// No description provided for @notifMotivationMessages.
  ///
  /// In en, this message translates to:
  /// **'Motivational messages'**
  String get notifMotivationMessages;

  /// No description provided for @notifMotivationSub.
  ///
  /// In en, this message translates to:
  /// **'Inspiring quotes and progress statistics'**
  String get notifMotivationSub;

  /// No description provided for @notifMotivationTime.
  ///
  /// In en, this message translates to:
  /// **'Motivation time'**
  String get notifMotivationTime;

  /// No description provided for @notifMotivationTimeSub.
  ///
  /// In en, this message translates to:
  /// **'Daily motivational notification'**
  String get notifMotivationTimeSub;

  /// No description provided for @notifGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get notifGoals;

  /// No description provided for @notifGoalReminder.
  ///
  /// In en, this message translates to:
  /// **'Goal reminder'**
  String get notifGoalReminder;

  /// No description provided for @notifGoalReminderSub.
  ///
  /// In en, this message translates to:
  /// **'Evening reminder if daily goal is not completed'**
  String get notifGoalReminderSub;

  /// No description provided for @notifGoalReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get notifGoalReminderTime;

  /// No description provided for @notifGoalReminderTimeSub.
  ///
  /// In en, this message translates to:
  /// **'Daily goal reminder'**
  String get notifGoalReminderTimeSub;

  /// No description provided for @notifQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get notifQuietHours;

  /// No description provided for @notifQuietHoursSubEnabled.
  ///
  /// In en, this message translates to:
  /// **'Do not disturb from {start} to {end}'**
  String notifQuietHoursSubEnabled(Object start, Object end);

  /// No description provided for @notifQuietHoursSubDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disable notifications at night'**
  String get notifQuietHoursSubDisabled;

  /// No description provided for @notifQuietHoursStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get notifQuietHoursStart;

  /// No description provided for @notifQuietHoursEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get notifQuietHoursEnd;

  /// No description provided for @notifTesting.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get notifTesting;

  /// No description provided for @notifTestSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get notifTestSent;

  /// No description provided for @notifQuietHoursActive.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours are active ({start}–{end}). Notification will not be shown.'**
  String notifQuietHoursActive(Object start, Object end);

  /// No description provided for @notifTimePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Select reminder time'**
  String get notifTimePickerHelp;

  /// No description provided for @notifTimePickerMotivationHelp.
  ///
  /// In en, this message translates to:
  /// **'Motivational messages time'**
  String get notifTimePickerMotivationHelp;

  /// No description provided for @notifTimePickerGoalHelp.
  ///
  /// In en, this message translates to:
  /// **'Goal reminder time'**
  String get notifTimePickerGoalHelp;

  /// No description provided for @notifTimePickerQuietStartHelp.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours start'**
  String get notifTimePickerQuietStartHelp;

  /// No description provided for @notifTimePickerQuietEndHelp.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours end'**
  String get notifTimePickerQuietEndHelp;

  /// No description provided for @notifTimePickerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get notifTimePickerCancel;

  /// No description provided for @notifTimePickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get notifTimePickerConfirm;

  /// No description provided for @notifTypeReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifTypeReminder;

  /// No description provided for @notifTypeMotivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get notifTypeMotivation;

  /// No description provided for @notifTypeGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get notifTypeGoals;

  /// No description provided for @notifTypeStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get notifTypeStreak;

  /// No description provided for @notifChannelReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifChannelReminders;

  /// No description provided for @notifChannelRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily meditation reminders'**
  String get notifChannelRemindersDesc;

  /// No description provided for @notifChannelMotivation.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get notifChannelMotivation;

  /// No description provided for @notifChannelMotivationDesc.
  ///
  /// In en, this message translates to:
  /// **'Motivational messages and quotes'**
  String get notifChannelMotivationDesc;

  /// No description provided for @notifChannelGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get notifChannelGoals;

  /// No description provided for @notifChannelGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Goal progress notifications'**
  String get notifChannelGoalsDesc;

  /// No description provided for @notifChannelStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get notifChannelStreak;

  /// No description provided for @notifChannelStreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Streak celebration notifications'**
  String get notifChannelStreakDesc;

  /// No description provided for @notifBodyReminder.
  ///
  /// In en, this message translates to:
  /// **'🧘 Time to meditate!\nTake 10 minutes for inner silence and peace.'**
  String get notifBodyReminder;

  /// No description provided for @notifBodyGoalReminder.
  ///
  /// In en, this message translates to:
  /// **'🎯 Time left to reach your goal!\nJust a few minutes of meditation and you\'ll earn bonus XP!'**
  String get notifBodyGoalReminder;

  /// No description provided for @notifBodyStreak.
  ///
  /// In en, this message translates to:
  /// **'🔥 New record: {streak} days in a row!\nCongratulations! You\'ve beaten your personal record!'**
  String notifBodyStreak(Object streak);

  /// No description provided for @timerPause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get timerPause;

  /// No description provided for @timerResume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get timerResume;

  /// No description provided for @timerStop.
  ///
  /// In en, this message translates to:
  /// **'STOP'**
  String get timerStop;

  /// No description provided for @timerPosture.
  ///
  /// In en, this message translates to:
  /// **'Back straight\nGaze down 45°\nFocus soft'**
  String get timerPosture;

  /// No description provided for @timerEndMeditation.
  ///
  /// In en, this message translates to:
  /// **'End meditation?'**
  String get timerEndMeditation;

  /// No description provided for @timerEndMeditationSub.
  ///
  /// In en, this message translates to:
  /// **'Your practice is not yet complete.'**
  String get timerEndMeditationSub;

  /// No description provided for @timerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get timerContinue;

  /// No description provided for @timerEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get timerEnd;

  /// No description provided for @timerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save session. Please try again.'**
  String get timerSaveFailed;

  /// No description provided for @timerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get timerRetry;

  /// No description provided for @guideHeroLabel.
  ///
  /// In en, this message translates to:
  /// **'Alex Merch Foundation'**
  String get guideHeroLabel;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'AxisMind'**
  String get guideTitle;

  /// No description provided for @guideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The rational path to mental clarity'**
  String get guideSubtitle;

  /// No description provided for @guideFinalEdition.
  ///
  /// In en, this message translates to:
  /// **'FINAL EDITION 2026'**
  String get guideFinalEdition;

  /// No description provided for @guideTechnique.
  ///
  /// In en, this message translates to:
  /// **'Technique: Susokukan (Breath Counting)'**
  String get guideTechnique;

  /// No description provided for @guideArithmetic.
  ///
  /// In en, this message translates to:
  /// **'Arithmetic of Mindfulness'**
  String get guideArithmetic;

  /// No description provided for @guidePosture.
  ///
  /// In en, this message translates to:
  /// **'POSTURE'**
  String get guidePosture;

  /// No description provided for @guidePostureDesc.
  ///
  /// In en, this message translates to:
  /// **'Sit on the edge of a chair or in zazen. Back straight but relaxed. Shoulders relaxed, hands in mudra (oval lock).'**
  String get guidePostureDesc;

  /// No description provided for @guideGaze.
  ///
  /// In en, this message translates to:
  /// **'GAZE'**
  String get guideGaze;

  /// No description provided for @guideGazeDesc.
  ///
  /// In en, this message translates to:
  /// **'Eyes half-open, gaze directed downward at ~45° to the floor 1–1.5 meters ahead. Do not close your eyes — this leads to drowsiness and daydreaming.'**
  String get guideGazeDesc;

  /// No description provided for @guideFocus.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get guideFocus;

  /// No description provided for @guideFocusDesc.
  ///
  /// In en, this message translates to:
  /// **'Blur your vision — don\'t stare at the floor texture, don\'t fixate on points. Use peripheral vision. You look but don\'t see details.'**
  String get guideFocusDesc;

  /// No description provided for @guideAlgorithm.
  ///
  /// In en, this message translates to:
  /// **'Count each exhale. When you reach 10, start counting backward to 1. If a thought interrupts the count — return to one.'**
  String get guideAlgorithm;

  /// No description provided for @guideBioEffect.
  ///
  /// In en, this message translates to:
  /// **'Biological Effect'**
  String get guideBioEffect;

  /// No description provided for @guideBioEffectDesc.
  ///
  /// In en, this message translates to:
  /// **'Counting engages the prefrontal cortex, quieting the Default Mode Network (DMN) responsible for mind-wandering and anxiety.'**
  String get guideBioEffectDesc;

  /// No description provided for @guideZenRule.
  ///
  /// In en, this message translates to:
  /// **'Zen Rule'**
  String get guideZenRule;

  /// No description provided for @guideZenRuleQuote.
  ///
  /// In en, this message translates to:
  /// **'\"If you lose count at 9 — you\'ve lost the battle for attention. Humbly return to 1. This is the practice.\"'**
  String get guideZenRuleQuote;

  /// No description provided for @guideZazenGeometry.
  ///
  /// In en, this message translates to:
  /// **'Zazen Geometry'**
  String get guideZazenGeometry;

  /// No description provided for @guideFormContent.
  ///
  /// In en, this message translates to:
  /// **'Form and Content'**
  String get guideFormContent;

  /// No description provided for @guideVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get guideVertical;

  /// No description provided for @guideVerticalDesc.
  ///
  /// In en, this message translates to:
  /// **'Spine straight like a string. This is the physiological foundation for an alert consciousness.'**
  String get guideVerticalDesc;

  /// No description provided for @guideGazeZazen.
  ///
  /// In en, this message translates to:
  /// **'Gaze'**
  String get guideGazeZazen;

  /// No description provided for @guideGazeZazenDesc.
  ///
  /// In en, this message translates to:
  /// **'Eyes half-open, gaze at 45° down, focus soft. You don\'t drift into dreams, you stay here and now.'**
  String get guideGazeZazenDesc;

  /// No description provided for @guideMudra.
  ///
  /// In en, this message translates to:
  /// **'Mudra'**
  String get guideMudra;

  /// No description provided for @guideMudraDesc.
  ///
  /// In en, this message translates to:
  /// **'Hands in an oval lock. This is your physical sensor of concentration depth.'**
  String get guideMudraDesc;

  /// No description provided for @guideResistance.
  ///
  /// In en, this message translates to:
  /// **'Overcoming Resistance'**
  String get guideResistance;

  /// No description provided for @guidePracticalGuide.
  ///
  /// In en, this message translates to:
  /// **'Practical Guide'**
  String get guidePracticalGuide;

  /// No description provided for @guideProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get guideProblem;

  /// No description provided for @guideMindMechanism.
  ///
  /// In en, this message translates to:
  /// **'Mind Mechanism'**
  String get guideMindMechanism;

  /// No description provided for @guideZenSolution.
  ///
  /// In en, this message translates to:
  /// **'Zen Solution'**
  String get guideZenSolution;

  /// No description provided for @guideProblemItch.
  ///
  /// In en, this message translates to:
  /// **'Itching and restlessness'**
  String get guideProblemItch;

  /// No description provided for @guideLogicItch.
  ///
  /// In en, this message translates to:
  /// **'Ego\'s defensive reaction to unfamiliar silence.'**
  String get guideLogicItch;

  /// No description provided for @guideActionItch.
  ///
  /// In en, this message translates to:
  /// **'Mushotoku. Observe the itch as an external object. It will pass on its own.'**
  String get guideActionItch;

  /// No description provided for @guideProblemNoise.
  ///
  /// In en, this message translates to:
  /// **'Mental noise'**
  String get guideProblemNoise;

  /// No description provided for @guideLogicNoise.
  ///
  /// In en, this message translates to:
  /// **'The brain\'s attempt to fill the vacuum with habitual plans.'**
  String get guideLogicNoise;

  /// No description provided for @guideActionNoise.
  ///
  /// In en, this message translates to:
  /// **'Susokukan. Gently return attention to counting \"One\". Without aggression.'**
  String get guideActionNoise;

  /// No description provided for @guideProblemSleep.
  ///
  /// In en, this message translates to:
  /// **'Drowsiness'**
  String get guideProblemSleep;

  /// No description provided for @guideLogicSleep.
  ///
  /// In en, this message translates to:
  /// **'A sign of lost tone and slipping into trance.'**
  String get guideLogicSleep;

  /// No description provided for @guideActionSleep.
  ///
  /// In en, this message translates to:
  /// **'Energy. Straighten your back. Open your eyes slightly. Breathe a little deeper.'**
  String get guideActionSleep;

  /// No description provided for @guideWitness.
  ///
  /// In en, this message translates to:
  /// **'Be the Witness.'**
  String get guideWitness;

  /// No description provided for @guideQuote.
  ///
  /// In en, this message translates to:
  /// **'Your mind — your greatest asset.'**
  String get guideQuote;

  /// No description provided for @guideFooter.
  ///
  /// In en, this message translates to:
  /// **'ALEX MERCH • AXISMIND SYSTEM • 2026'**
  String get guideFooter;

  /// No description provided for @levelUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelUpTitle(Object level);

  /// No description provided for @goalCompleted.
  ///
  /// In en, this message translates to:
  /// **'Goal completed!'**
  String get goalCompleted;

  /// No description provided for @goalCompletedClose.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get goalCompletedClose;

  /// No description provided for @emptyDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your path to peace\nbegins with the first minute'**
  String get emptyDashboardTitle;

  /// No description provided for @emptyDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your first meditation\nto see your statistics here'**
  String get emptyDashboardSubtitle;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get errorUnknown;

  /// No description provided for @errorDatabase.
  ///
  /// In en, this message translates to:
  /// **'Database error. Please restart the app.'**
  String get errorDatabase;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Connection issue. Check your internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorStats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics.'**
  String get errorStats;

  /// No description provided for @errorStatsRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics. Please try again.'**
  String get errorStatsRetry;

  /// No description provided for @errorStatsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics. Please try again.'**
  String get errorStatsRefresh;

  /// No description provided for @errorDataRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Data is updating...'**
  String get errorDataRefreshing;

  /// No description provided for @rankNovice.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness Novice'**
  String get rankNovice;

  /// No description provided for @rankSeeker.
  ///
  /// In en, this message translates to:
  /// **'Peace Seeker'**
  String get rankSeeker;

  /// No description provided for @rankGuardian.
  ///
  /// In en, this message translates to:
  /// **'Silence Guardian'**
  String get rankGuardian;

  /// No description provided for @rankMaster.
  ///
  /// In en, this message translates to:
  /// **'Balance Master'**
  String get rankMaster;

  /// No description provided for @rankWanderer.
  ///
  /// In en, this message translates to:
  /// **'Depth Wanderer'**
  String get rankWanderer;

  /// No description provided for @rankAwakened.
  ///
  /// In en, this message translates to:
  /// **'Awakened One'**
  String get rankAwakened;

  /// No description provided for @rankSage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get rankSage;

  /// No description provided for @rankEnlightened.
  ///
  /// In en, this message translates to:
  /// **'Enlightened One'**
  String get rankEnlightened;

  /// No description provided for @rankLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get rankLegend;

  /// No description provided for @rankImmortal.
  ///
  /// In en, this message translates to:
  /// **'Immortal'**
  String get rankImmortal;

  /// No description provided for @rankDivine.
  ///
  /// In en, this message translates to:
  /// **'Divine'**
  String get rankDivine;

  /// No description provided for @rankDescriptionNovice.
  ///
  /// In en, this message translates to:
  /// **'First step on the path to mindfulness'**
  String get rankDescriptionNovice;

  /// No description provided for @rankDescriptionSeeker.
  ///
  /// In en, this message translates to:
  /// **'Searching for inner harmony'**
  String get rankDescriptionSeeker;

  /// No description provided for @rankDescriptionGuardian.
  ///
  /// In en, this message translates to:
  /// **'Finding silence within'**
  String get rankDescriptionGuardian;

  /// No description provided for @rankDescriptionMaster.
  ///
  /// In en, this message translates to:
  /// **'Balance between effort and peace'**
  String get rankDescriptionMaster;

  /// No description provided for @rankDescriptionWanderer.
  ///
  /// In en, this message translates to:
  /// **'Exploring the depths of consciousness'**
  String get rankDescriptionWanderer;

  /// No description provided for @rankDescriptionAwakened.
  ///
  /// In en, this message translates to:
  /// **'Awakening inner light'**
  String get rankDescriptionAwakened;

  /// No description provided for @rankDescriptionSage.
  ///
  /// In en, this message translates to:
  /// **'Wisdom born from practice'**
  String get rankDescriptionSage;

  /// No description provided for @rankDescriptionEnlightened.
  ///
  /// In en, this message translates to:
  /// **'The light of mindfulness guides you'**
  String get rankDescriptionEnlightened;

  /// No description provided for @rankDescriptionLegend.
  ///
  /// In en, this message translates to:
  /// **'Your journey inspires others'**
  String get rankDescriptionLegend;

  /// No description provided for @rankDescriptionImmortal.
  ///
  /// In en, this message translates to:
  /// **'Timeless practice'**
  String get rankDescriptionImmortal;

  /// No description provided for @rankDescriptionDivine.
  ///
  /// In en, this message translates to:
  /// **'You have reached enlightenment'**
  String get rankDescriptionDivine;

  /// No description provided for @rankLevel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String rankLevel(Object level);

  /// No description provided for @rankYouAreHere.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get rankYouAreHere;

  /// No description provided for @rankContinuePractice.
  ///
  /// In en, this message translates to:
  /// **'Continue practicing to unlock new ranks'**
  String get rankContinuePractice;

  /// No description provided for @rankClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get rankClose;

  /// No description provided for @rankTiers.
  ///
  /// In en, this message translates to:
  /// **'Tiers'**
  String get rankTiers;

  /// No description provided for @rankRequiredPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice required'**
  String get rankRequiredPractice;

  /// No description provided for @rankProgressToNext.
  ///
  /// In en, this message translates to:
  /// **'Progress to next rank'**
  String get rankProgressToNext;

  /// No description provided for @rankRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min remaining to next rank'**
  String rankRemainingMinutes(Object minutes);

  /// No description provided for @rankRemainingToNext.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min remaining to next level'**
  String rankRemainingToNext(Object minutes);

  /// No description provided for @rankStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get rankStatusCompleted;

  /// No description provided for @rankStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current rank'**
  String get rankStatusCurrent;

  /// No description provided for @rankStatusLocked.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get rankStatusLocked;

  /// No description provided for @rankLevelRangeOpen.
  ///
  /// In en, this message translates to:
  /// **'{min}+ lvl'**
  String rankLevelRangeOpen(Object min);

  /// No description provided for @rankLevelRangeSingle.
  ///
  /// In en, this message translates to:
  /// **'{min} lvl'**
  String rankLevelRangeSingle(Object min);

  /// No description provided for @rankLevelRangeMulti.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} lvl'**
  String rankLevelRangeMulti(Object min, Object max);

  /// No description provided for @rankMinutesRequired.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String rankMinutesRequired(Object minutes);

  /// No description provided for @rankMinutesRequiredThousands.
  ///
  /// In en, this message translates to:
  /// **'{value}K min'**
  String rankMinutesRequiredThousands(Object value);

  /// No description provided for @rankMinutesTotal.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min total'**
  String rankMinutesTotal(Object minutes);

  /// No description provided for @rankMinutesTotalThousands.
  ///
  /// In en, this message translates to:
  /// **'{value}K min total'**
  String rankMinutesTotalThousands(Object value);

  /// No description provided for @subscriptionGuardLoading.
  ///
  /// In en, this message translates to:
  /// **'AxisMind'**
  String get subscriptionGuardLoading;

  /// No description provided for @samadhiExitHint.
  ///
  /// In en, this message translates to:
  /// **'Press Space or click to exit'**
  String get samadhiExitHint;

  /// No description provided for @neuroPreset5.
  ///
  /// In en, this message translates to:
  /// **'Stopping «mental noise».\nRapid return of attentional control.'**
  String get neuroPreset5;

  /// No description provided for @neuroPreset10.
  ///
  /// In en, this message translates to:
  /// **'Reduction of physical tension.\nDeep ordering of mental activity.'**
  String get neuroPreset10;

  /// No description provided for @neuroPreset15.
  ///
  /// In en, this message translates to:
  /// **'Deep stabilization of perception.\nTransition to mental silence and peace.'**
  String get neuroPreset15;

  /// No description provided for @neuroPreset20.
  ///
  /// In en, this message translates to:
  /// **'Classic Zen training.\nReduction of sympathetic tone and absolute clarity of mind.'**
  String get neuroPreset20;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @dayShortSun.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get dayShortSun;

  /// No description provided for @dayShortMon.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get dayShortMon;

  /// No description provided for @dayShortTue.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get dayShortTue;

  /// No description provided for @dayShortWed.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get dayShortWed;

  /// No description provided for @dayShortThu.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get dayShortThu;

  /// No description provided for @dayShortFri.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get dayShortFri;

  /// No description provided for @dayShortSat.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get dayShortSat;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get month;

  /// No description provided for @openGuide.
  ///
  /// In en, this message translates to:
  /// **'OPEN PATH TO CLARITY'**
  String get openGuide;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @quote1.
  ///
  /// In en, this message translates to:
  /// **'Silence is not the absence of sound, but the presence of self.'**
  String get quote1;

  /// No description provided for @quote2.
  ///
  /// In en, this message translates to:
  /// **'Every minute of meditation is an investment in peace.'**
  String get quote2;

  /// No description provided for @quote3.
  ///
  /// In en, this message translates to:
  /// **'Breathe deeper — there is a whole ocean of calm within you.'**
  String get quote3;

  /// No description provided for @quote4.
  ///
  /// In en, this message translates to:
  /// **'Don\'t try to stop your thoughts. Learn not to engage with them.'**
  String get quote4;

  /// No description provided for @quote5.
  ///
  /// In en, this message translates to:
  /// **'Meditation is not a technique, but a way of being.'**
  String get quote5;

  /// No description provided for @quote6.
  ///
  /// In en, this message translates to:
  /// **'Inner peace begins the moment you decide not to let the outer world control you.'**
  String get quote6;

  /// No description provided for @quote7.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness is the key that opens the door to harmony.'**
  String get quote7;

  /// No description provided for @quote8.
  ///
  /// In en, this message translates to:
  /// **'Your practice is your island. No one can take it from you.'**
  String get quote8;

  /// No description provided for @quote9.
  ///
  /// In en, this message translates to:
  /// **'Pause. Breathe. You are already on the right path.'**
  String get quote9;

  /// No description provided for @quote10.
  ///
  /// In en, this message translates to:
  /// **'Every day is a new opportunity to return to yourself.'**
  String get quote10;

  /// No description provided for @quote11.
  ///
  /// In en, this message translates to:
  /// **'Strength is not in tension, but in relaxation.'**
  String get quote11;

  /// No description provided for @quote12.
  ///
  /// In en, this message translates to:
  /// **'Meditation is coming home to your true Self.'**
  String get quote12;

  /// No description provided for @quote13.
  ///
  /// In en, this message translates to:
  /// **'Don\'t wait for the perfect moment. Start now.'**
  String get quote13;

  /// No description provided for @quote14.
  ///
  /// In en, this message translates to:
  /// **'Your breath is an anchor in the present moment.'**
  String get quote14;

  /// No description provided for @quote15.
  ///
  /// In en, this message translates to:
  /// **'Progress is not a straight line. Every minute of practice matters.'**
  String get quote15;

  /// No description provided for @guideHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A rational path to mental clarity'**
  String get guideHeroSubtitle;

  /// No description provided for @guideSusokukanLabel.
  ///
  /// In en, this message translates to:
  /// **'Technique: Susokukan (Breath Counting)'**
  String get guideSusokukanLabel;

  /// No description provided for @guideSusokukanTitle.
  ///
  /// In en, this message translates to:
  /// **'The Arithmetic of Mindfulness'**
  String get guideSusokukanTitle;

  /// No description provided for @guideStepPostureTitle.
  ///
  /// In en, this message translates to:
  /// **'POSTURE'**
  String get guideStepPostureTitle;

  /// No description provided for @guideStepPostureDesc.
  ///
  /// In en, this message translates to:
  /// **'Sit on the edge of a chair or in zazen. Spine straight, but without tension. Shoulders relaxed, hands in mudra (cosmic oval).'**
  String get guideStepPostureDesc;

  /// No description provided for @guideStepGazeTitle.
  ///
  /// In en, this message translates to:
  /// **'GAZE'**
  String get guideStepGazeTitle;

  /// No description provided for @guideStepGazeDesc.
  ///
  /// In en, this message translates to:
  /// **'Eyes slightly open, cast downward at a ~45° angle to the floor in front of you (1–1.5 meters). Do not close your eyes — that leads to drowsiness and daydreaming.'**
  String get guideStepGazeDesc;

  /// No description provided for @guideStepFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get guideStepFocusTitle;

  /// No description provided for @guideStepFocusDesc.
  ///
  /// In en, this message translates to:
  /// **'Soften your gaze — do not stare at the floor texture or fixate on spots. Use peripheral vision. You look, but do not cling to details.'**
  String get guideStepFocusDesc;

  /// No description provided for @guideSusokukanInstruction.
  ///
  /// In en, this message translates to:
  /// **'Count each exhalation. Reaching 10, start counting back down to 1. If a thought interrupts the count — return to 1.'**
  String get guideSusokukanInstruction;

  /// No description provided for @guideBioEffectTitle.
  ///
  /// In en, this message translates to:
  /// **'Biological Effect'**
  String get guideBioEffectTitle;

  /// No description provided for @guideZenRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Zen Rule'**
  String get guideZenRuleTitle;

  /// No description provided for @guideZenRuleDesc.
  ///
  /// In en, this message translates to:
  /// **'“If you lose count at 9, you have lost the battle for attention. Humbly return to 1. That is the practice.”'**
  String get guideZenRuleDesc;

  /// No description provided for @guideZazenLabel.
  ///
  /// In en, this message translates to:
  /// **'Form and Essence'**
  String get guideZazenLabel;

  /// No description provided for @guideZazenTitle.
  ///
  /// In en, this message translates to:
  /// **'Geometry of Zazen'**
  String get guideZazenTitle;

  /// No description provided for @guideZazenVerticalTitle.
  ///
  /// In en, this message translates to:
  /// **'Vertical'**
  String get guideZazenVerticalTitle;

  /// No description provided for @guideZazenVerticalDesc.
  ///
  /// In en, this message translates to:
  /// **'Spine straight as a string. This is the physiological foundation for an awake consciousness.'**
  String get guideZazenVerticalDesc;

  /// No description provided for @guideZazenGazeTitle.
  ///
  /// In en, this message translates to:
  /// **'Gaze'**
  String get guideZazenGazeTitle;

  /// No description provided for @guideZazenGazeDesc.
  ///
  /// In en, this message translates to:
  /// **'Eyes slightly open, cast down at 45°, soft focus. You do not drift into daydreaming; you remain here and now.'**
  String get guideZazenGazeDesc;

  /// No description provided for @guideZazenMudraTitle.
  ///
  /// In en, this message translates to:
  /// **'Mudra'**
  String get guideZazenMudraTitle;

  /// No description provided for @guideZazenMudraDesc.
  ///
  /// In en, this message translates to:
  /// **'Hands in a cosmic oval clasp. This is your physical sensor of concentration depth.'**
  String get guideZazenMudraDesc;

  /// No description provided for @guideResistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Practical Guide'**
  String get guideResistanceLabel;

  /// No description provided for @guideResistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Overcoming Resistance'**
  String get guideResistanceTitle;

  /// No description provided for @guideHeaderProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get guideHeaderProblem;

  /// No description provided for @guideHeaderLogic.
  ///
  /// In en, this message translates to:
  /// **'Mind Mechanism'**
  String get guideHeaderLogic;

  /// No description provided for @guideHeaderAction.
  ///
  /// In en, this message translates to:
  /// **'Zen Solution'**
  String get guideHeaderAction;

  /// No description provided for @guideProblem1.
  ///
  /// In en, this message translates to:
  /// **'Itch and Restlessness'**
  String get guideProblem1;

  /// No description provided for @guideLogic1.
  ///
  /// In en, this message translates to:
  /// **'The ego\'s defensive reaction to unusual stillness.'**
  String get guideLogic1;

  /// No description provided for @guideAction1.
  ///
  /// In en, this message translates to:
  /// **'Mushotoku. Observe the itch as an external object. It will pass on its own.'**
  String get guideAction1;

  /// No description provided for @guideProblem2.
  ///
  /// In en, this message translates to:
  /// **'Mental Noise'**
  String get guideProblem2;

  /// No description provided for @guideLogic2.
  ///
  /// In en, this message translates to:
  /// **'The brain attempting to fill the vacuum with familiar plans.'**
  String get guideLogic2;

  /// No description provided for @guideAction2.
  ///
  /// In en, this message translates to:
  /// **'Susokukan. Gently return attention to the count of \'One\'. Without aggression.'**
  String get guideAction2;

  /// No description provided for @guideProblem3.
  ///
  /// In en, this message translates to:
  /// **'Drowsiness'**
  String get guideProblem3;

  /// No description provided for @guideLogic3.
  ///
  /// In en, this message translates to:
  /// **'A sign of decreasing tone and drifting into a trance.'**
  String get guideLogic3;

  /// No description provided for @guideAction3.
  ///
  /// In en, this message translates to:
  /// **'Energy. Straighten your spine. Open your eyes slightly. Breathe a little deeper.'**
  String get guideAction3;

  /// No description provided for @guideFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Be the Witness.'**
  String get guideFinalTitle;

  /// No description provided for @guideFinalQuote.
  ///
  /// In en, this message translates to:
  /// **'Your mind is your greatest asset.'**
  String get guideFinalQuote;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get onboardingStart;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Mindfulness and Peace'**
  String get onboardingTitle1;

  /// No description provided for @onboardingDesc1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AxisMind. Discover your inner balance through regular meditation and focus practices.'**
  String get onboardingDesc1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Breathing Practices'**
  String get onboardingTitle2;

  /// No description provided for @onboardingDesc2.
  ///
  /// In en, this message translates to:
  /// **'Use proven techniques such as Susokukan for deep concentration and relaxation.'**
  String get onboardingDesc2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Sync and Progress'**
  String get onboardingTitle3;

  /// No description provided for @onboardingDesc3.
  ///
  /// In en, this message translates to:
  /// **'Track session statistics, configure timers, and safely store your progress in the cloud.'**
  String get onboardingDesc3;

  /// No description provided for @goalSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Settings'**
  String get goalSettingsTitle;

  /// No description provided for @goalSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Goals help track practice regularity and give bonus XP for completion.'**
  String get goalSettingsSubtitle;

  /// No description provided for @goalsCurrentListTitle.
  ///
  /// In en, this message translates to:
  /// **'Current Goals'**
  String get goalsCurrentListTitle;

  /// No description provided for @goalsMaxLimit.
  ///
  /// In en, this message translates to:
  /// **'Maximum 4 goals'**
  String get goalsMaxLimit;

  /// No description provided for @goalsAddBtn.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get goalsAddBtn;

  /// No description provided for @goalsEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get goalsEditTooltip;

  /// No description provided for @goalsDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get goalsDeleteTooltip;

  /// No description provided for @goalsDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete goal?'**
  String get goalsDeleteDialogTitle;

  /// No description provided for @goalsDeleteDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the goal \"{name}\"?'**
  String goalsDeleteDialogContent(Object name);

  /// No description provided for @goalsDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get goalsDialogCancel;

  /// No description provided for @goalsDialogDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get goalsDialogDelete;

  /// No description provided for @goalsFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalsFormEditTitle;

  /// No description provided for @goalsFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalsFormNewTitle;

  /// No description provided for @goalsFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal type'**
  String get goalsFormTypeLabel;

  /// No description provided for @goalsFormTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target value'**
  String get goalsFormTargetLabel;

  /// No description provided for @goalsFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get goalsFormSave;

  /// No description provided for @goalsHelperDaily.
  ///
  /// In en, this message translates to:
  /// **'For example: 10 minutes per day'**
  String get goalsHelperDaily;

  /// No description provided for @goalsHelperWeeklySessions.
  ///
  /// In en, this message translates to:
  /// **'For example: 5 sessions per week'**
  String get goalsHelperWeeklySessions;

  /// No description provided for @goalsHelperWeeklyMinutes.
  ///
  /// In en, this message translates to:
  /// **'For example: 60 minutes per week'**
  String get goalsHelperWeeklyMinutes;

  /// No description provided for @goalsHelperStreak.
  ///
  /// In en, this message translates to:
  /// **'For example: 7 days in a row'**
  String get goalsHelperStreak;

  /// No description provided for @statsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsScreenTitle;

  /// No description provided for @statsSyncError.
  ///
  /// In en, this message translates to:
  /// **'SyncRepository is not initialized'**
  String get statsSyncError;

  /// No description provided for @statsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load statistics. Please try again.'**
  String get statsLoadError;

  /// No description provided for @statsDbError.
  ///
  /// In en, this message translates to:
  /// **'Database error. Please restart the app.'**
  String get statsDbError;

  /// No description provided for @goalTypeDailyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Daily practice'**
  String get goalTypeDailyMinutes;

  /// No description provided for @goalTypeWeeklySessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions per week'**
  String get goalTypeWeeklySessions;

  /// No description provided for @goalTypeWeeklyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes per week'**
  String get goalTypeWeeklyMinutes;

  /// No description provided for @goalTypeStreakDays.
  ///
  /// In en, this message translates to:
  /// **'Days in a row'**
  String get goalTypeStreakDays;

  /// No description provided for @goalDialogTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New goal'**
  String get goalDialogTitleNew;

  /// No description provided for @goalDialogTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get goalDialogTitleEdit;

  /// No description provided for @goalDialogSelectType.
  ///
  /// In en, this message translates to:
  /// **'Goal type'**
  String get goalDialogSelectType;

  /// No description provided for @goalDialogTargetValue.
  ///
  /// In en, this message translates to:
  /// **'Target value'**
  String get goalDialogTargetValue;

  /// No description provided for @goalDialogSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get goalDialogSave;

  /// No description provided for @goalDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get goalDialogCancel;

  /// No description provided for @journalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes...'**
  String get journalSearchHint;

  /// No description provided for @journalTagAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get journalTagAll;

  /// No description provided for @journalEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get journalEmptyTitle;

  /// No description provided for @journalUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update entry'**
  String get journalUpdateError;

  /// No description provided for @journalDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get journalDeleteTitle;

  /// No description provided for @journalDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get journalDeleteContent;

  /// No description provided for @journalDeleteCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get journalDeleteCancel;

  /// No description provided for @journalDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Entry deleted'**
  String get journalDeleteSuccess;

  /// No description provided for @journalDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete entry'**
  String get journalDeleteError;

  /// No description provided for @journalEditBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get journalEditBtn;

  /// No description provided for @journalDurationMinSec.
  ///
  /// In en, this message translates to:
  /// **'{min} min {sec} sec'**
  String journalDurationMinSec(Object min, Object sec);

  /// No description provided for @journalDurationSec.
  ///
  /// In en, this message translates to:
  /// **'{sec} sec'**
  String journalDurationSec(Object sec);

  /// No description provided for @journalMonthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get journalMonthJan;

  /// No description provided for @journalMonthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get journalMonthFeb;

  /// No description provided for @journalMonthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get journalMonthMar;

  /// No description provided for @journalMonthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get journalMonthApr;

  /// No description provided for @journalMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get journalMonthMay;

  /// No description provided for @journalMonthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get journalMonthJun;

  /// No description provided for @journalMonthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get journalMonthJul;

  /// No description provided for @journalMonthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get journalMonthAug;

  /// No description provided for @journalMonthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get journalMonthSep;

  /// No description provided for @journalMonthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get journalMonthOct;

  /// No description provided for @journalMonthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get journalMonthNov;

  /// No description provided for @journalMonthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get journalMonthDec;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
