import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'providers/timer_provider.dart';
import 'providers/task_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/grok_ai_provider.dart';
import 'providers/update_provider.dart';
import 'providers/focus_sound_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/celebration_provider.dart';
import 'providers/location_provider.dart';
import 'providers/planner_provider.dart';
import 'providers/vosk_speech_provider.dart';
import 'screens/home_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/habits_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pet_screen.dart';
import 'screens/planner_screen.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to load environment variables (optional, for development)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env file not found, API key can be set in Settings
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TaskOrbitApp());
}

class TaskOrbitApp extends StatelessWidget {
  const TaskOrbitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => GrokAIProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
        ChangeNotifierProvider(create: (_) => FocusSoundProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => CelebrationProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => PlannerProvider()),
        ChangeNotifierProvider(create: (_) => VoskSpeechProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'TaskOrbit',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Default to Home screen
  bool _hasCheckedForUpdate = false;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> get _screens => [
    HomeScreen(onNavigateToTab: _navigateToTab),
    const TimerScreen(),
    const TasksScreen(),
    const PlannerScreen(),
    const HabitsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForUpdates();
    _initVoskModel();
  }

  Future<void> _initVoskModel() async {
    // Load Vosk speech model in background on app start
    final voskProvider = context.read<VoskSpeechProvider>();
    if (!voskProvider.isModelLoaded && !voskProvider.isLoading) {
      voskProvider.loadModel();
    }
  }

  Future<void> _checkForUpdates() async {
    if (_hasCheckedForUpdate) return;
    _hasCheckedForUpdate = true;

    // Wait a moment for the app to fully load
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final updateProvider = context.read<UpdateProvider>();
    final result = await updateProvider.checkForUpdate();

    if (!mounted) return;

    if (result is UpdateAvailable) {
      // Check if this version was skipped
      final isSkipped = await updateProvider.isVersionSkipped(result.version);
      if (!isSkipped && mounted) {
        showUpdateDialog(context, result);
      }
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  String _getScreenTitle() {
    switch (_currentIndex) {
      case 0:
        return 'TaskOrbit';
      case 1:
        return 'Focus Timer';
      case 2:
        return 'Tasks';
      case 3:
        return 'Planner';
      case 4:
        return 'Habits';
      default:
        return 'TaskOrbit';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: _openSettings,
          tooltip: 'Settings',
        ),
        title: Text(
          _getScreenTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 500),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer_outlined),
                selectedIcon: Icon(Icons.timer_rounded),
                label: 'Focus',
              ),
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle_rounded),
                label: 'Tasks',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today_rounded),
                label: 'Plan',
              ),
              NavigationDestination(
                icon: Icon(Icons.loop_outlined),
                selectedIcon: Icon(Icons.loop_rounded),
                label: 'Habits',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
