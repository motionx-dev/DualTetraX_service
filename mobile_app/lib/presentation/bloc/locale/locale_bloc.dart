import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => [];
}

class ChangeLocale extends LocaleEvent {
  final Locale locale;

  const ChangeLocale(this.locale);

  @override
  List<Object?> get props => [locale];
}

class LoadLocale extends LocaleEvent {}

// States
class LocaleState extends Equatable {
  final Locale? locale;

  const LocaleState(this.locale);

  @override
  List<Object?> get props => [locale];
}

// BLoC
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  static const String _localeKey = 'locale';
  final SharedPreferences sharedPreferences;

  LocaleBloc(this.sharedPreferences) : super(const LocaleState(null)) {
    on<LoadLocale>(_onLoadLocale);
    on<ChangeLocale>(_onChangeLocale);
  }

  Future<void> _onLoadLocale(
    LoadLocale event,
    Emitter<LocaleState> emit,
  ) async {
    final localeCode = sharedPreferences.getString(_localeKey);
    if (localeCode != null) {
      emit(LocaleState(Locale(localeCode)));
    } else {
      // Use system locale if not set
      emit(const LocaleState(null));
    }
  }

  Future<void> _onChangeLocale(
    ChangeLocale event,
    Emitter<LocaleState> emit,
  ) async {
    await sharedPreferences.setString(_localeKey, event.locale.languageCode);
    emit(LocaleState(event.locale));
  }
}
