import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:taqy/core/functions/force_app_update_ui.dart';
import 'package:taqy/core/preferences/shared_pref.dart';
import 'package:taqy/core/services/di.dart';

part 'languages_state.dart';

class LanguagesCubit extends Cubit<LanguagesState> {
  final TaQyPreferences preferences;
  LanguagesCubit(this.preferences) : super(LanguagesInitial());

  void setLanguage(BuildContext context, String langCode) async {
    emit(LanguagesUpdating());
    Future.delayed(Duration.zero, () {
      preferences.saveLang(langCode);
      context.setLocale(Locale(langCode));
      langCode = sl<TaQyPreferences>().getLang();
    });
    await forceAppUpdate();
    // Emit a new state with the updated language code
    emit(LanguagesUpdated(langCode));
  }
}
