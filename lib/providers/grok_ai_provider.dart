import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GrokAIProvider extends ChangeNotifier {
  // Using Groq API (fast inference)
  static const String _baseUrl = 'https://api.groq.com/openai/v1';
  static const String _apiKeyPref = 'groq_api_key';

  // API key loaded from environment (.env file)
  String? _environmentApiKey;

  String? _apiKey;
  bool _isLoading = false;
  String? _lastError;
  List<String> _dailyTips = [];
  bool _isInitialized = false;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasApiKey => _activeApiKey.isNotEmpty;
  List<String> get dailyTips => _dailyTips;

  String get _activeApiKey => _apiKey ?? _environmentApiKey ?? dotenv.env['GROQ_API_KEY'] ?? '';

  GrokAIProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadEnvironmentApiKey();
    await _loadUserApiKey();
    _isInitialized = true;
    notifyListeners();
  }

  /// Load API key from environment (compile-time dart-define)
  /// Usage: flutter run --dart-define=GROQ_API_KEY=your_key_here
  Future<void> _loadEnvironmentApiKey() async {
    const envKey = String.fromEnvironment('GROQ_API_KEY');
    if (envKey.isNotEmpty) {
      _environmentApiKey = envKey;
    }
  }

  Future<void> _loadUserApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
    _apiKey = key;
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPref);
    _apiKey = null; // Falls back to environment key if available
    notifyListeners();
  }

  /// Break down a task into smaller, manageable subtasks
  Future<List<String>> chunkTask(String taskTitle, {String? taskDescription}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_activeApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an ADHD-friendly task assistant. Break down tasks into small, actionable steps that are:
- Specific and clear (no vague instructions)
- Achievable in 5-15 minutes each
- Written in simple, encouraging language
- Ordered logically

Return ONLY a JSON array of strings, no other text. Example: ["Step 1", "Step 2", "Step 3"]'''
            },
            {
              'role': 'user',
              'content': 'Break down this task into smaller steps:\n\nTask: $taskTitle${taskDescription != null ? '\nDetails: $taskDescription' : ''}'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse the JSON array from the response
        final List<dynamic> steps = jsonDecode(content);
        _isLoading = false;
        notifyListeners();
        return steps.cast<String>();
      } else {
        _lastError = 'API error: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return _getOfflineTaskChunks(taskTitle);
      }
    } catch (e) {
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
      return _getOfflineTaskChunks(taskTitle);
    }
  }

  /// Get ADHD-friendly productivity tips
  Future<List<String>> getDailyTips() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_activeApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': '''You are an ADHD coach. Provide 3 short, practical tips for staying focused today.
Each tip should be:
- Actionable and specific
- Encouraging, not preachy
- Under 20 words

Return ONLY a JSON array of 3 strings.'''
            },
            {
              'role': 'user',
              'content': 'Give me 3 focus tips for today.'
            }
          ],
          'temperature': 0.8,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final List<dynamic> tips = jsonDecode(content);
        _dailyTips = tips.cast<String>();
      } else {
        _dailyTips = _getOfflineTips();
      }
    } catch (e) {
      _dailyTips = _getOfflineTips();
    }

    _isLoading = false;
    notifyListeners();
    return _dailyTips;
  }

  /// Get motivation message for completing tasks
  Future<String> getMotivation(int tasksCompleted) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_activeApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an encouraging ADHD coach. Give a short, genuine celebration message (under 15 words) for completing tasks. Be warm but not over the top.'
            },
            {
              'role': 'user',
              'content': 'I just completed $tasksCompleted task${tasksCompleted > 1 ? 's' : ''} today!'
            }
          ],
          'temperature': 0.9,
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
    } catch (e) {
      // Fall through to offline
    }

    return _getOfflineMotivation(tasksCompleted);
  }

  // Offline fallback methods
  List<String> _getOfflineTaskChunks(String taskTitle) {
    final lowerTask = taskTitle.toLowerCase();

    if (lowerTask.contains('clean') || lowerTask.contains('organize')) {
      return [
        'Set a 10-minute timer',
        'Pick ONE area to start with',
        'Gather supplies you need',
        'Work until timer ends',
        'Take a 2-minute break',
        'Continue or move to next area',
      ];
    } else if (lowerTask.contains('write') || lowerTask.contains('document')) {
      return [
        'Open your document/app',
        'Write just the title or topic',
        'Jot down 3 main points',
        'Expand one point at a time',
        'Don\'t edit yet - just write',
        'Take a break, then review',
      ];
    } else if (lowerTask.contains('email') || lowerTask.contains('message')) {
      return [
        'Open your email/messages',
        'Scan for urgent items first',
        'Reply to quick ones (under 2 min)',
        'Flag longer ones for later',
        'Set a timer for complex replies',
      ];
    } else {
      return [
        'Gather what you need',
        'Set a 15-minute timer',
        'Start with the easiest part',
        'Keep going until timer ends',
        'Take a short break',
        'Review and continue',
      ];
    }
  }

  List<String> _getOfflineTips() {
    final tips = [
      'Start with just 5 minutes. Momentum builds naturally.',
      'Put your phone in another room while working.',
      'Break big tasks into tiny steps you can actually do.',
      'Use a timer - it makes boring tasks feel like a game.',
      'Reward yourself after completing something hard.',
      'Write tasks as actions: "Email John" not "Handle emails".',
      'Do the thing you\'re avoiding first. Then it\'s done!',
      'Background music or white noise can help you focus.',
      'Stand up and stretch every 25 minutes.',
      'Celebrate small wins - they matter!',
    ];
    tips.shuffle();
    return tips.take(3).toList();
  }

  String _getOfflineMotivation(int count) {
    final messages = [
      'Nice work! Every task completed is a win.',
      'You\'re making progress! Keep that momentum.',
      'Look at you go! $count down, you\'ve got this.',
      'That\'s $count tasks crushed! Take a moment to feel proud.',
      'You showed up and did the work. That\'s huge!',
    ];
    return messages[count % messages.length];
  }
}
