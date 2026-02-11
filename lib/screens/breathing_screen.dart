import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

enum BreathingPhase { inhale, hold, exhale, rest }

class BreathingTechnique {
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int restSeconds;
  final Color color;

  const BreathingTechnique({
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    this.restSeconds = 0,
    required this.color,
  });

  int get totalCycleSeconds => inhaleSeconds + holdSeconds + exhaleSeconds + restSeconds;
}

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  static const techniques = [
    BreathingTechnique(
      name: '4-7-8 Relaxing',
      description: 'Calming breath for anxiety & sleep',
      inhaleSeconds: 4,
      holdSeconds: 7,
      exhaleSeconds: 8,
      color: Color(0xFF6366F1), // Indigo
    ),
    BreathingTechnique(
      name: 'Box Breathing',
      description: 'Navy SEAL technique for focus',
      inhaleSeconds: 4,
      holdSeconds: 4,
      exhaleSeconds: 4,
      restSeconds: 4,
      color: Color(0xFF10B981), // Emerald
    ),
    BreathingTechnique(
      name: 'Quick Calm',
      description: 'Fast relief in stressful moments',
      inhaleSeconds: 3,
      holdSeconds: 3,
      exhaleSeconds: 6,
      color: Color(0xFF8B5CF6), // Violet
    ),
  ];

  int _selectedTechniqueIndex = 0;
  bool _isRunning = false;
  BreathingPhase _currentPhase = BreathingPhase.inhale;
  int _phaseSecondsRemaining = 0;
  int _cyclesCompleted = 0;
  Timer? _timer;
  late AnimationController _breathController;

  BreathingTechnique get _technique => techniques[_selectedTechniqueIndex];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _technique.totalCycleSeconds),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _startBreathing() {
    setState(() {
      _isRunning = true;
      _currentPhase = BreathingPhase.inhale;
      _phaseSecondsRemaining = _technique.inhaleSeconds;
      _cyclesCompleted = 0;
    });

    _breathController.repeat();
    _startTimer();
    HapticFeedback.mediumImpact();
  }

  void _stopBreathing() {
    _timer?.cancel();
    _breathController.stop();
    _breathController.reset();
    setState(() {
      _isRunning = false;
      _currentPhase = BreathingPhase.inhale;
      _phaseSecondsRemaining = 0;
    });
    HapticFeedback.lightImpact();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_phaseSecondsRemaining > 1) {
          _phaseSecondsRemaining--;
        } else {
          _advancePhase();
        }
      });
    });
  }

  void _advancePhase() {
    HapticFeedback.lightImpact();

    switch (_currentPhase) {
      case BreathingPhase.inhale:
        if (_technique.holdSeconds > 0) {
          _currentPhase = BreathingPhase.hold;
          _phaseSecondsRemaining = _technique.holdSeconds;
        } else {
          _currentPhase = BreathingPhase.exhale;
          _phaseSecondsRemaining = _technique.exhaleSeconds;
        }
        break;
      case BreathingPhase.hold:
        _currentPhase = BreathingPhase.exhale;
        _phaseSecondsRemaining = _technique.exhaleSeconds;
        break;
      case BreathingPhase.exhale:
        if (_technique.restSeconds > 0) {
          _currentPhase = BreathingPhase.rest;
          _phaseSecondsRemaining = _technique.restSeconds;
        } else {
          _currentPhase = BreathingPhase.inhale;
          _phaseSecondsRemaining = _technique.inhaleSeconds;
          _cyclesCompleted++;
        }
        break;
      case BreathingPhase.rest:
        _currentPhase = BreathingPhase.inhale;
        _phaseSecondsRemaining = _technique.inhaleSeconds;
        _cyclesCompleted++;
        break;
    }
  }

  void _selectTechnique(int index) {
    if (_isRunning) _stopBreathing();
    setState(() {
      _selectedTechniqueIndex = index;
    });
    _breathController.duration = Duration(seconds: _technique.totalCycleSeconds);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Breathing Exercise',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Technique selector
              _buildTechniqueSelector(),
              const SizedBox(height: 32),

              // Breathing circle
              Expanded(
                child: Center(
                  child: _buildBreathingCircle(),
                ),
              ),

              // Cycle counter
              if (_isRunning) ...[
                Text(
                  '$_cyclesCompleted cycles completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Start/Stop button
              _buildControlButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechniqueSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: techniques.length,
        itemBuilder: (context, index) {
          final technique = techniques[index];
          final isSelected = index == _selectedTechniqueIndex;

          return GestureDetector(
            onTap: () => _selectTechnique(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? technique.color.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? technique.color : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technique.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? technique.color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    technique.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildBreathingCircle() {
    final baseSize = MediaQuery.of(context).size.width * 0.6;

    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        double scale = 1.0;

        if (_isRunning) {
          // Calculate scale based on current phase
          switch (_currentPhase) {
            case BreathingPhase.inhale:
              // Growing from 0.6 to 1.0
              final progress = 1 - (_phaseSecondsRemaining / _technique.inhaleSeconds);
              scale = 0.6 + (0.4 * progress);
              break;
            case BreathingPhase.hold:
              // Stay at max
              scale = 1.0;
              break;
            case BreathingPhase.exhale:
              // Shrinking from 1.0 to 0.6
              final progress = 1 - (_phaseSecondsRemaining / _technique.exhaleSeconds);
              scale = 1.0 - (0.4 * progress);
              break;
            case BreathingPhase.rest:
              // Stay at min
              scale = 0.6;
              break;
          }
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Phase instruction
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isRunning ? _getPhaseInstruction() : 'Ready to begin',
                key: ValueKey(_currentPhase.toString() + _isRunning.toString()),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _technique.color,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Breathing circle with glow
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                if (_isRunning)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: baseSize * scale * 1.2,
                    height: baseSize * scale * 1.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _technique.color.withValues(alpha: 0.3),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),

                // Main circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  width: baseSize * scale,
                  height: baseSize * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _technique.color.withValues(alpha: 0.8),
                        _technique.color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _technique.color.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isRunning
                        ? Text(
                            '$_phaseSecondsRemaining',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Icon(
                            Icons.self_improvement,
                            color: Colors.white,
                            size: 64,
                          ),
                  ),
                ),

                // Rotating ring
                if (_isRunning)
                  SizedBox(
                    width: baseSize * scale + 30,
                    height: baseSize * scale + 30,
                    child: CircularProgressIndicator(
                      value: _getPhaseProgress(),
                      strokeWidth: 4,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ).animate(target: _isRunning ? 1 : 0).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      duration: 400.ms,
    );
  }

  String _getPhaseInstruction() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return 'Breathe In';
      case BreathingPhase.hold:
        return 'Hold';
      case BreathingPhase.exhale:
        return 'Breathe Out';
      case BreathingPhase.rest:
        return 'Rest';
    }
  }

  double _getPhaseProgress() {
    int totalPhaseSeconds;
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        totalPhaseSeconds = _technique.inhaleSeconds;
        break;
      case BreathingPhase.hold:
        totalPhaseSeconds = _technique.holdSeconds;
        break;
      case BreathingPhase.exhale:
        totalPhaseSeconds = _technique.exhaleSeconds;
        break;
      case BreathingPhase.rest:
        totalPhaseSeconds = _technique.restSeconds;
        break;
    }
    return 1 - (_phaseSecondsRemaining / totalPhaseSeconds);
  }

  Widget _buildControlButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isRunning ? _stopBreathing : _startBreathing,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRunning ? AppTheme.errorColor : _technique.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            const SizedBox(width: 8),
            Text(
              _isRunning ? 'Stop' : 'Start Breathing',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }
}
