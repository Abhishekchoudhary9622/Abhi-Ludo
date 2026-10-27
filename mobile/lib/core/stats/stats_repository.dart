import 'package:shared_preferences/shared_preferences.dart';

/// Player career statistics and profile persistence.
class StatsRepository {
  StatsRepository._();
  static final StatsRepository instance = StatsRepository._();

  int matchesPlayed = 0;
  int matchesWon = 0;
  int totalKills = 0;
  String playerName = 'Rally Champion';
  int avatarIndex = 0;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    matchesPlayed = prefs.getInt('stats_matches_played') ?? 0;
    matchesWon = prefs.getInt('stats_matches_won') ?? 0;
    totalKills = prefs.getInt('stats_total_kills') ?? 0;
    playerName = prefs.getString('profile_player_name') ?? 'Rally Champion';
    avatarIndex = prefs.getInt('profile_avatar_index') ?? 0;
  }

  int get winRate => matchesPlayed == 0 ? 0 : ((matchesWon / matchesPlayed) * 100).round();

  Future<void> recordMatch({required bool won, required int killsInMatch}) async {
    matchesPlayed++;
    if (won) matchesWon++;
    totalKills += killsInMatch;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stats_matches_played', matchesPlayed);
    await prefs.setInt('stats_matches_won', matchesWon);
    await prefs.setInt('stats_total_kills', totalKills);
  }

  Future<void> updateProfile({required String name, required int avatar}) async {
    playerName = name;
    avatarIndex = avatar;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_player_name', playerName);
    await prefs.setInt('profile_avatar_index', avatarIndex);
  }
}
