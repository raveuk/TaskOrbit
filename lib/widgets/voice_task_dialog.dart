import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';
import '../models/task.dart';
import '../providers/vosk_speech_provider.dart';

class VoiceTaskDialog extends StatefulWidget {
  final Function(Task) onTaskCreated;

  const VoiceTaskDialog({super.key, required this.onTaskCreated});

  @override
  State<VoiceTaskDialog> createState() => _VoiceTaskDialogState();
}

class _VoiceTaskDialogState extends State<VoiceTaskDialog> {
  final TextEditingController _titleController = TextEditingController();

  bool _isListening = false;
  bool _isInitializing = true;
  String _transcribedText = '';
  String _partialText = '';
  String _statusText = 'Initializing...';
  String? _errorText;
  Priority _selectedPriority = Priority.medium;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    // Check microphone permission
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        setState(() {
          _errorText = 'Microphone permission is required for voice input';
          _isInitializing = false;
        });
      }
      return;
    }

    final voskProvider = context.read<VoskSpeechProvider>();

    // Check if model is already loaded
    if (voskProvider.isModelLoaded) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusText = 'Tap the mic to start speaking';
        });
      }
      return;
    }

    // Check if model is loading
    if (voskProvider.isLoading) {
      if (mounted) {
        setState(() {
          _statusText = 'Loading speech model...';
        });
      }

      // Wait for model to load
      voskProvider.addListener(_onVoskStateChanged);
      return;
    }

    // Start loading model
    if (mounted) {
      setState(() {
        _statusText = 'Loading speech model...';
      });
    }

    voskProvider.addListener(_onVoskStateChanged);
    await voskProvider.loadModel();
  }

  void _onVoskStateChanged() {
    if (!mounted) return;

    final voskProvider = context.read<VoskSpeechProvider>();

    if (voskProvider.isModelLoaded) {
      setState(() {
        _isInitializing = false;
        _statusText = 'Tap the mic to start speaking';
      });
      voskProvider.removeListener(_onVoskStateChanged);
    } else if (voskProvider.errorMessage != null) {
      setState(() {
        _isInitializing = false;
        _errorText = voskProvider.errorMessage;
      });
      voskProvider.removeListener(_onVoskStateChanged);
    } else if (voskProvider.isLoading) {
      setState(() {
        _statusText = 'Loading speech model... ${(voskProvider.loadingProgress * 100).toInt()}%';
      });
    }
  }

  void _toggleListening() async {
    final voskProvider = context.read<VoskSpeechProvider>();

    if (!voskProvider.isModelLoaded) {
      setState(() {
        _errorText = 'Speech model not ready. Please wait...';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    if (_isListening) {
      await voskProvider.stopListening();
      setState(() {
        _isListening = false;
        if (_transcribedText.isNotEmpty) {
          _statusText = 'Got it! Edit below or tap mic again.';
          _showTranscriptionUI();
        } else {
          _statusText = 'No speech detected. Tap to try again.';
        }
      });
    } else {
      setState(() {
        _isListening = true;
        _statusText = 'Listening... (tap to stop)';
        _transcribedText = '';
        _partialText = '';
      });

      await voskProvider.startListening(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _transcribedText = result;
            });
          }
        },
        onPartialResult: (partial) {
          if (mounted) {
            setState(() {
              _partialText = partial;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _errorText = error;
              _statusText = 'Tap to try again';
            });
          }
        },
      );
    }
  }

  void _showTranscriptionUI() {
    if (_transcribedText.isNotEmpty) {
      _titleController.text = _extractTitle(_transcribedText);
    }
  }

  String _extractTitle(String text) {
    final firstSentence = text.split(RegExp(r'[.!?]')).first.trim();
    if (firstSentence.length > 80) {
      return '${firstSentence.substring(0, 77)}...';
    }
    return firstSentence;
  }

  void _createTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorText = 'Please enter a task title';
      });
      return;
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: _transcribedText != title ? _transcribedText : null,
      priority: _selectedPriority,
      createdAt: DateTime.now(),
    );

    widget.onTaskCreated(task);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    final voskProvider = context.read<VoskSpeechProvider>();
    voskProvider.stopListening();
    voskProvider.removeListener(_onVoskStateChanged);
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _partialText.isNotEmpty ? _partialText : _transcribedText;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice to Task',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Speak your task naturally (offline)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status text
            Text(
              _statusText,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Mic button
            GestureDetector(
              onTap: _isInitializing ? null : _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isListening
                      ? LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        )
                      : AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : AppTheme.primaryColor)
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _isInitializing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 36,
                      ),
              ),
            ).animate(
              onPlay: (controller) {
                if (_isListening) controller.repeat(reverse: true);
              },
            ).scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 500.ms,
            ),
            const SizedBox(height: 16),

            // Audio visualization placeholder
            if (_isListening)
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    7,
                    (index) => Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                        .animate(
                          onPlay: (controller) => controller.repeat(reverse: true),
                        )
                        .scaleY(
                          begin: 0.3,
                          end: 1.0,
                          duration: Duration(milliseconds: 300 + (index * 100)),
                        ),
                  ),
                ),
              ),

            // Live transcription (partial results)
            if (_isListening && _partialText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _partialText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Error message
            if (_errorText != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Transcription card
            if (_transcribedText.isNotEmpty && !_isListening) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Transcription',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transcribedText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
            ],

            // Task title input
            if (_transcribedText.isNotEmpty && !_isListening) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Task title',
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),

              // Priority selector
              Row(
                children: Priority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPriority = priority),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? priority.color.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? priority.color : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(priority.icon, color: priority.color, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              priority.label,
                              style: TextStyle(
                                color: priority.color,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _createTask,
                      child: const Text('Add Task'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            ],
          ],
        ),
      ),
    );
  }
}

void showVoiceTaskDialog(BuildContext context, Function(Task) onTaskCreated) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => VoiceTaskDialog(onTaskCreated: onTaskCreated),
  );
}
