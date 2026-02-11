import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vosk_flutter_service/vosk_flutter.dart';

class VoskSpeechProvider extends ChangeNotifier {
  VoskFlutterPlugin? _vosk;
  ModelLoader? _modelLoader;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  bool _isModelLoaded = false;
  bool _isLoading = false;
  bool _isListening = false;
  String _transcribedText = '';
  String _partialText = '';
  String? _errorMessage;
  double _loadingProgress = 0.0;
  String _loadingStatus = '';

  // Small English model URL
  static const String _modelUrl =
      'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip';

  // Getters
  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;
  bool get isListening => _isListening;
  String get transcribedText => _transcribedText;
  String get partialText => _partialText;
  String? get errorMessage => _errorMessage;
  double get loadingProgress => _loadingProgress;
  String get loadingStatus => _loadingStatus;

  VoskSpeechProvider() {
    _initVosk();
  }

  Future<void> _initVosk() async {
    _vosk = VoskFlutterPlugin.instance();
    _modelLoader = ModelLoader();
  }

  /// Load the Vosk model - call this on app startup
  Future<void> loadModel() async {
    if (_isModelLoaded || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    _loadingProgress = 0.0;
    _loadingStatus = 'Checking for speech model...';
    notifyListeners();

    try {
      debugPrint('VoskSpeechProvider: Starting model load...');

      _loadingStatus = 'Downloading speech model (~40MB)...';
      _loadingProgress = 0.1;
      notifyListeners();

      // Use the built-in ModelLoader to download and extract
      final modelPath = await _modelLoader!.loadFromNetwork(_modelUrl);

      debugPrint('VoskSpeechProvider: Model path: $modelPath');

      _loadingStatus = 'Loading model into memory...';
      _loadingProgress = 0.7;
      notifyListeners();

      // Create the model
      _model = await _vosk!.createModel(modelPath);
      debugPrint('VoskSpeechProvider: Model created');

      _loadingProgress = 0.85;
      notifyListeners();

      // Create recognizer with 16000 sample rate
      _recognizer = await _vosk!.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );
      debugPrint('VoskSpeechProvider: Recognizer created');

      _loadingProgress = 0.95;
      notifyListeners();

      // Initialize speech service
      _speechService = await _vosk!.initSpeechService(_recognizer!);
      debugPrint('VoskSpeechProvider: Speech service initialized');

      _loadingProgress = 1.0;
      _loadingStatus = 'Ready!';
      _isModelLoaded = true;
      _isLoading = false;
      notifyListeners();

      debugPrint('VoskSpeechProvider: Model loaded successfully!');
    } catch (e) {
      debugPrint('VoskSpeechProvider: Error loading model: $e');
      _errorMessage = 'Failed to load speech model: $e';
      _loadingStatus = 'Error loading model';
      _isLoading = false;
      _isModelLoaded = false;
      notifyListeners();
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
    Function(String)? onError,
  }) async {
    if (!_isModelLoaded) {
      _errorMessage = 'Model not loaded. Please wait...';
      notifyListeners();
      onError?.call(_errorMessage!);
      return;
    }

    if (_isListening) {
      return;
    }

    _isListening = true;
    _transcribedText = '';
    _partialText = '';
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('VoskSpeechProvider: Starting to listen...');

      // Start the speech service
      await _speechService!.start();

      // Listen to partial results
      _speechService!.onPartial().listen((partial) {
        if (_isListening) {
          final text = _parseVoskResult(partial, isPartial: true);
          if (text.isNotEmpty) {
            _partialText = text;
            notifyListeners();
            onPartialResult?.call(text);
          }
          debugPrint('VoskSpeechProvider: Partial: $partial -> $text');
        }
      });

      // Listen to final results
      _speechService!.onResult().listen((result) {
        if (_isListening) {
          final text = _parseVoskResult(result, isPartial: false);
          if (text.isNotEmpty) {
            _transcribedText = text;
            notifyListeners();
            onResult?.call(text);
          }
          debugPrint('VoskSpeechProvider: Result: $result -> $text');
        }
      });

    } catch (e) {
      debugPrint('VoskSpeechProvider: Error starting listening: $e');
      _errorMessage = 'Failed to start listening: $e';
      _isListening = false;
      notifyListeners();
      onError?.call(_errorMessage!);
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      debugPrint('VoskSpeechProvider: Stopping listening...');
      await _speechService?.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      debugPrint('VoskSpeechProvider: Error stopping: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  /// Parse Vosk JSON result to extract text
  /// Vosk returns JSON like {"partial": "hello"} or {"text": "hello world"}
  String _parseVoskResult(String jsonResult, {required bool isPartial}) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonResult);
      if (isPartial) {
        return (json['partial'] as String?) ?? '';
      } else {
        return (json['text'] as String?) ?? '';
      }
    } catch (e) {
      debugPrint('VoskSpeechProvider: Error parsing result: $e');
      return '';
    }
  }

  /// Reset the recognizer for a new session
  Future<void> reset() async {
    _transcribedText = '';
    _partialText = '';
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService?.stop();
    _speechService?.dispose();
    _recognizer?.dispose();
    _model?.dispose();
    super.dispose();
  }
}
