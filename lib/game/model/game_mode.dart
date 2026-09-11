import 'package:flutter/foundation.dart';

/// Game modes.
enum GameMode { quickPlay, dailyChallenge, practice, custom }

extension GameModeX on GameMode {
  String get label {
    switch (this) {
      case GameMode.quickPlay:
        return 'Quick Play';
      case GameMode.dailyChallenge:
        return 'Daily Challenge';
      case GameMode.practice:
        return 'Practice';
      case GameMode.custom:
        return 'Custom';
    }
  }

  String get nameValue {
    switch (this) {
      case GameMode.quickPlay:
        return 'quick_play';
      case GameMode.dailyChallenge:
        return 'daily';
      case GameMode.practice:
        return 'practice';
      case GameMode.custom:
        return 'custom';
    }
  }

  static GameMode fromName(String? name) {
    switch (name) {
      case 'quick_play':
        return GameMode.quickPlay;
      case 'daily':
        return GameMode.dailyChallenge;
      case 'practice':
        return GameMode.practice;
      case 'custom':
        return GameMode.custom;
      default:
        return GameMode.quickPlay;
    }
  }
}

/// Candidate mark kinds. Automatic marks are derived from queen placements and
/// are safely removable when the owning queen is removed; manual marks are
/// always preserved.
@immutable
class CandidateMark {
  final int row;
  final int col;
  final bool isAuto;

  const CandidateMark({required this.row, required this.col, this.isAuto = false});

  Map<String, dynamic> toJson() => {'row': row, 'col': col, 'isAuto': isAuto};

  factory CandidateMark.fromJson(Map<String, dynamic> json) => CandidateMark(
        row: json['row'] as int,
        col: json['col'] as int,
        isAuto: json['isAuto'] as bool? ?? false,
      );
}