import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.aiEnabled = false,
    this.aiModel = AppConstants.defaultAiModel,
    this.hasAiApiKey = false,
  });

  final ThemeMode themeMode;
  final bool aiEnabled;
  final String aiModel;
  final bool hasAiApiKey;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? aiEnabled,
    String? aiModel,
    bool? hasAiApiKey,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiModel: aiModel ?? this.aiModel,
      hasAiApiKey: hasAiApiKey ?? this.hasAiApiKey,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._preferences) : super(const SettingsState());

  final SharedPreferences _preferences;

  Future<void> loadTheme() async {
    final isDarkMode =
        _preferences.getBool(AppConstants.themePreferenceKey) ?? false;
    final apiKey =
        (_preferences.getString(AppConstants.aiAdvisorApiKeyKey) ?? '').trim();
    final model = (_preferences.getString(AppConstants.aiAdvisorModelKey) ??
            AppConstants.defaultAiModel)
        .trim();
    final aiEnabledPreference =
        _preferences.getBool(AppConstants.aiAdvisorEnabledKey) ?? false;
    final hasAiApiKey = apiKey.isNotEmpty;
    emit(
      state.copyWith(
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        aiEnabled: aiEnabledPreference && hasAiApiKey,
        aiModel: model.isEmpty ? AppConstants.defaultAiModel : model,
        hasAiApiKey: hasAiApiKey,
      ),
    );
  }

  Future<void> setDarkMode(bool value) async {
    await _preferences.setBool(AppConstants.themePreferenceKey, value);
    emit(state.copyWith(themeMode: value ? ThemeMode.dark : ThemeMode.light));
  }

  Future<void> setAiEnabled(bool value) async {
    final next = value && state.hasAiApiKey;
    await _preferences.setBool(AppConstants.aiAdvisorEnabledKey, next);
    emit(state.copyWith(aiEnabled: next));
  }

  Future<void> saveAiConfiguration({
    String? apiKey,
    required String model,
    required bool enabled,
  }) async {
    final normalizedModel = model.trim().isEmpty
        ? AppConstants.defaultAiModel
        : model.trim();
    final existingKey =
        (_preferences.getString(AppConstants.aiAdvisorApiKeyKey) ?? '').trim();
    final normalizedKey = apiKey == null ? existingKey : apiKey.trim();
    final hasKey = normalizedKey.isNotEmpty;

    if (hasKey) {
      await _preferences.setString(AppConstants.aiAdvisorApiKeyKey, normalizedKey);
    } else {
      await _preferences.remove(AppConstants.aiAdvisorApiKeyKey);
    }

    await _preferences.setString(AppConstants.aiAdvisorModelKey, normalizedModel);
    final active = enabled && hasKey;
    await _preferences.setBool(AppConstants.aiAdvisorEnabledKey, active);

    emit(
      state.copyWith(
        aiModel: normalizedModel,
        hasAiApiKey: hasKey,
        aiEnabled: active,
      ),
    );
  }
}
