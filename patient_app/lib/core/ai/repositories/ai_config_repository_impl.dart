import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../ai/ai_config.dart';
import 'ai_config_repository.dart';

class AiConfigRepositoryImpl implements AiConfigRepository {
  AiConfigRepositoryImpl(this._preferences);

  static const _enabledKey = 'ai_enabled';
  static const _modeKey = 'ai_mode';
  static const _remoteUrlKey = 'ai_remote_url';
  static const _defaultRemoteUrl = 'https://api.example.com';

  final SharedPreferences _preferences;
  final StreamController<AiConfig> _controller =
      StreamController<AiConfig>.broadcast();

  AiConfig _current = const AiConfig();

  @override
  AiConfig get current => _current;

  @override
  Stream<AiConfig> get stream => _controller.stream;

  @override
  Future<AiConfig> loadConfig() async {
    final enabled = _preferences.getBool(_enabledKey) ?? false;
    final modeStr = _preferences.getString(_modeKey) ?? AiMode.fake.name;
    final remoteUrl =
        _preferences.getString(_remoteUrlKey) ?? _defaultRemoteUrl;
    final mode = modeStr == AiMode.remote.name ? AiMode.remote : AiMode.fake;
    _current = AiConfig(enabled: enabled, mode: mode, remoteUrl: remoteUrl);
    _controller.add(_current);
    return _current;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _current = _current.copyWith(enabled: enabled);
    await _preferences.setBool(_enabledKey, enabled);
    _controller.add(_current);
  }

  @override
  Future<void> setMode(AiMode mode) async {
    _current = _current.copyWith(mode: mode);
    await _preferences.setString(_modeKey, mode.name);
    _controller.add(_current);
  }

  void dispose() {
    _controller.close();
  }
}
