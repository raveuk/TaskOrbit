import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundCategory {
  none(''),
  brainwave('Brainwave Entrainment'),
  noise('Noise Therapy'),
  nature('Nature Sounds'),
  environmental('Environmental');

  final String displayName;
  const SoundCategory(this.displayName);
}

enum FocusSound {
  silent('Silent', '', SoundCategory.none, 'No background sound', null),

  // Brainwave Entrainment
  alphaWaves('Alpha Waves', '🧠', SoundCategory.brainwave, 'Relaxed alertness for reading', 'sound_alpha_waves.mp3'),
  betaFocus('Beta Focus', '🎯', SoundCategory.brainwave, 'Active concentration for work', 'sound_beta_focus.mp3'),
  gammaBoost('Gamma Boost', '⚡', SoundCategory.brainwave, 'Deep focus for complex tasks', 'sound_gamma_boost.mp3'),
  thetaCalm('Theta Calm', '🧘', SoundCategory.brainwave, 'Creativity and meditation', 'sound_theta_calm.mp3'),

  // Noise Therapy
  brownNoise('Brown Noise', '🟤', SoundCategory.noise, 'Deep, soothing rumble (ADHD favorite)', 'sound_brown_noise.mp3'),
  pinkNoise('Pink Noise', '🩷', SoundCategory.noise, 'Balanced, like steady rainfall', 'sound_pink_noise.mp3'),
  whiteNoise('White Noise', '⚪', SoundCategory.noise, 'Research-proven for ADHD focus', 'sound_white_noise.mp3'),

  // Nature Sounds
  rain('Rain', '🌧️', SoundCategory.nature, 'Gentle rainfall', 'sound_rain.mp3'),
  ocean('Ocean', '🌊', SoundCategory.nature, 'Calming ocean waves', 'sound_ocean.mp3'),
  forest('Forest', '🌲', SoundCategory.nature, 'Peaceful forest ambience', 'sound_forest.mp3'),
  thunder('Thunder', '⛈️', SoundCategory.nature, 'Distant thunderstorm', 'sound_thunder.mp3'),
  wind('Wind', '💨', SoundCategory.nature, 'Soft wind sounds', 'sound_wind.mp3'),

  // Environmental
  cafe('Café', '☕', SoundCategory.environmental, 'Coffee shop ambience', 'sound_cafe.mp3'),
  library('Library', '📚', SoundCategory.environmental, 'Quiet library atmosphere', 'sound_library.mp3'),
  fire('Fireplace', '🔥', SoundCategory.environmental, 'Cozy crackling fire', 'sound_fire.mp3');

  final String displayName;
  final String icon;
  final SoundCategory category;
  final String description;
  final String? fileName;

  const FocusSound(this.displayName, this.icon, this.category, this.description, this.fileName);
}

class FocusSoundProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  FocusSound _currentSound = FocusSound.silent;
  bool _isPlaying = false;
  double _volume = 0.5;

  FocusSound get currentSound => _currentSound;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  FocusSoundProvider() {
    _loadPreferences();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.onPlayerComplete.listen((_) {
      // Loop is handled by ReleaseMode.loop
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _volume = prefs.getDouble('focus_sound_volume') ?? 0.5;
    final savedSoundIndex = prefs.getInt('focus_sound_index') ?? 0;
    if (savedSoundIndex < FocusSound.values.length) {
      _currentSound = FocusSound.values[savedSoundIndex];
    }
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('focus_sound_volume', _volume);
    await prefs.setInt('focus_sound_index', _currentSound.index);
  }

  Future<void> playSound(FocusSound sound) async {
    await stopSound();
    _currentSound = sound;

    if (sound == FocusSound.silent || sound.fileName == null) {
      _isPlaying = false;
      await _savePreferences();
      notifyListeners();
      return;
    }

    try {
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(AssetSource('sounds/${sound.fileName}'));
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing sound: $e');
      _isPlaying = false;
    }

    await _savePreferences();
    notifyListeners();
  }

  Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping sound: $e');
    }
    notifyListeners();
  }

  Future<void> pauseSound() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error pausing sound: $e');
    }
    notifyListeners();
  }

  Future<void> resumeSound() async {
    if (_currentSound != FocusSound.silent && _currentSound.fileName != null) {
      try {
        await _audioPlayer.resume();
        _isPlaying = true;
      } catch (e) {
        debugPrint('Error resuming sound: $e');
      }
      notifyListeners();
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
    await _savePreferences();
    notifyListeners();
  }

  List<FocusSound> getSoundsByCategory(SoundCategory category) {
    if (category == SoundCategory.none) {
      return [FocusSound.silent];
    }
    return FocusSound.values.where((s) => s.category == category).toList();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
