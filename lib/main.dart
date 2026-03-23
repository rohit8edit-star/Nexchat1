import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const NexChatApp());
}

class NexChatApp extends StatefulWidget {
  const NexChatApp({super.key});

  static _NexChatAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_NexChatAppState>();

  @override
  State<NexChatApp> createState() => _NexChatAppState();
}

class _NexChatAppState extends State<NexChatApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('darkMode') ?? false;
    setState(() =>
        _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme(bool isDark) {
    setState(() =>
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexChat',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0084FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0084FF),
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0084FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const AppLockWrapper(),
    );
  }
}

class AppLockWrapper extends StatefulWidget {
  const AppLockWrapper({super.key});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> {
  bool _isLocked = false;
  bool _checking = true;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAppLock();
  }

  Future<void> _checkAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    final appLock = prefs.getBool('appLock') ?? false;
    setState(() {
      _isLocked = appLock;
      _checking = false;
    });
  }

  Future<void> _unlock() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('appLockPin') ?? '';
    if (_pinController.text == savedPin) {
      setState(() => _isLocked = false);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong PIN!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLocked) {
      return Scaffold(
        backgroundColor: const Color(0xFF0084FF),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 80),
                const SizedBox(height: 24),
                const Text('NexChat',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('PIN daalo unlock karne ke liye',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 32),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      letterSpacing: 16),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length == 4) _unlock();
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _unlock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0084FF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Unlock',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const SplashScreen();
  }
}
