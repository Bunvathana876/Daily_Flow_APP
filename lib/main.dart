import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/rpg_colors.dart';
import 'core/utils/date_utils.dart';
import 'features/navigation/screen/main_shell.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'features/splash/screen/splash_screen.dart';

/// Global navigator key allowing headless/callback navigation from notification taps.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Handles notification tap events across terminated, background, and foreground states.
///
/// Ensures:
/// - Only valid [NotificationConstants.dailyReminderPayload] activates quest navigation.
/// - Switches [MainShell] to the "Today" / Quest Dashboard tab (index 0).
/// - Pops any modals or pushed routes (like SettingsScreen) back to root.
/// - Does not reinitialize SQLite, alter habit state, complete quests, award XP, or reset Focus timer.
void handleNotificationResponse(String? payload, ProviderContainer container) {
  if (payload == null ||
      payload != NotificationConstants.dailyReminderPayload) {
    return;
  }

  // 1. Switch bottom nav to Today tab (0)
  container.read(mainShellTabProvider.notifier).selectTab(0);

  // 2. Pop any routes pushed above MainShell (such as SettingsScreen)
  appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
}

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: RpgColors.rpgAbyss,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Initialize NotificationService safely
  try {
    final notificationService = container.read(notificationServiceProvider);
    await notificationService.initialize(
      onNotificationTap: (payload) {
        handleNotificationResponse(payload, container);
      },
    );

    // Check cold-launch payload if app was opened via notification tap
    final initialPayload = await notificationService.getInitialPayload();
    if (initialPayload != null) {
      handleNotificationResponse(initialPayload, container);
    }
  } catch (e) {
    debugPrint('DailyFlow: Notification initialization note: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: DailyFlowApp(navigatorKey: appNavigatorKey),
    ),
  );
}

class DailyFlowApp extends ConsumerStatefulWidget {
  final Widget? home;
  final GlobalKey<NavigatorState>? navigatorKey;

  const DailyFlowApp({super.key, this.home, this.navigatorKey});

  @override
  ConsumerState<DailyFlowApp> createState() => _DailyFlowAppState();
}

class _DailyFlowAppState extends ConsumerState<DailyFlowApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reconcile notification permission and schedule on resume (e.g. after time zone or OS permission changes)
      ref
          .read(settingsControllerProvider.notifier)
          .checkPermissionAndReconcile();
      // Re-evaluate current local calendar date on app resume
      ref.read(currentDateProvider.notifier).checkDateChanged();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: widget.navigatorKey ?? appNavigatorKey,
      title: 'DailyFlow',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      home: widget.home ?? const SplashScreen(),
    );
  }
}
