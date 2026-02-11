import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../providers/grok_ai_provider.dart';

class AITipsCard extends StatefulWidget {
  const AITipsCard({super.key});

  @override
  State<AITipsCard> createState() => _AITipsCardState();
}

class _AITipsCardState extends State<AITipsCard> {
  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();
    // Schedule tip loading after the first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTips();
    });
  }

  Future<void> _loadTips() async {
    if (!mounted) return;
    await context.read<GrokAIProvider>().getDailyTips();
  }

  void _nextTip() {
    final tips = context.read<GrokAIProvider>().dailyTips;
    if (tips.isNotEmpty) {
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % tips.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GrokAIProvider>(
      builder: (context, grokProvider, child) {
        final tips = grokProvider.dailyTips;

        if (tips.isEmpty && !grokProvider.isLoading) {
          return const SizedBox.shrink();
        }

        // Ensure index is valid after tips list changes
        final safeIndex = tips.isEmpty ? 0 : _currentTipIndex.clamp(0, tips.length - 1);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentColor,
                AppTheme.accentColor.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Focus Tip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (tips.length > 1)
                    IconButton(
                      onPressed: _nextTip,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Next tip',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (grokProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              else if (tips.isNotEmpty)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    tips[safeIndex],
                    key: ValueKey(safeIndex),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              if (tips.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    tips.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == safeIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2);
      },
    );
  }
}
