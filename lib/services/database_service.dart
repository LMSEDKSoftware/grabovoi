import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grabovoi_code.dart';
import '../models/meditation.dart';
import '../models/journal_entry.dart';
import '../models/tracker_session.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // Códigos Grabovoi
  Future<List<GrabovoiCode>> getCodes({String? category, String? searchQuery}) async {
    var query = _supabase.from('grabovoi_codes').select();

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%,code.ilike.%$searchQuery%');
    }

    final response = await query.order('popularity_score', ascending: false);
    return (response as List).map((e) => GrabovoiCode.fromJson(e)).toList();
  }

  Future<GrabovoiCode?> getCodeById(String id) async {
    final response = await _supabase
        .from('grabovoi_codes')
        .select()
        .eq('id', id)
        .single();
    
    return GrabovoiCode.fromJson(response);
  }

  Future<void> incrementCodePopularity(String codeId) async {
    await _supabase.rpc('increment_code_popularity', params: {'code_id': codeId});
  }

  // Favoritos
  Future<List<String>> getFavoriteCodeIds(String userId) async {
    final response = await _supabase
        .from('favorites')
        .select('code_id')
        .eq('user_id', userId);
    
    return (response as List).map((e) => e['code_id'] as String).toList();
  }

  Future<void> addFavorite(String userId, String codeId) async {
    await _supabase.from('favorites').insert({
      'user_id': userId,
      'code_id': codeId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite(String userId, String codeId) async {
    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('code_id', codeId);
  }

  // Meditaciones
  Future<List<Meditation>> getMeditations({String? type, int? maxDuration}) async {
    var query = _supabase.from('meditations').select();

    if (type != null) {
      query = query.eq('type', type);
    }

    if (maxDuration != null) {
      query = query.lte('duration_minutes', maxDuration);
    }

    final response = await query.order('title');
    return (response as List).map((e) => Meditation.fromJson(e)).toList();
  }

  Future<Meditation?> getMeditationById(String id) async {
    final response = await _supabase
        .from('meditations')
        .select()
        .eq('id', id)
        .single();
    
    return Meditation.fromJson(response);
  }

  Future<void> saveMeditationSession(MeditationSession session, String userId) async {
    await _supabase.from('meditation_sessions').insert({
      ...session.toJson(),
      'user_id': userId,
    });
  }

  // Diario
  Future<List<JournalEntry>> getJournalEntries(String userId, {int? limit}) async {
    var query = _supabase
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((e) => JournalEntry.fromJson(e)).toList();
  }

  Future<JournalEntry?> getJournalEntryById(String id) async {
    final response = await _supabase
        .from('journal_entries')
        .select()
        .eq('id', id)
        .single();
    
    return JournalEntry.fromJson(response);
  }

  Future<void> saveJournalEntry(JournalEntry entry, String userId) async {
    await _supabase.from('journal_entries').upsert({
      ...entry.toJson(),
      'user_id': userId,
    });
  }

  Future<void> deleteJournalEntry(String id) async {
    await _supabase.from('journal_entries').delete().eq('id', id);
  }

  // Sesiones de Tracker
  Future<List<TrackerSession>> getTrackerSessions(String userId, {int? limit}) async {
    var query = _supabase
        .from('tracker_sessions')
        .select()
        .eq('user_id', userId)
        .order('start_time', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return (response as List).map((e) => TrackerSession.fromJson(e)).toList();
  }

  Future<void> saveTrackerSession(TrackerSession session, String userId) async {
    await _supabase.from('tracker_sessions').upsert({
      ...session.toJson(),
      'user_id': userId,
    });
  }

  // Social
  Future<List<Map<String, dynamic>>> getSocialPosts({int limit = 20}) async {
    final response = await _supabase
        .from('social_posts')
        .select('*, profiles(username, avatar_url)')
        .order('created_at', ascending: false)
        .limit(limit);
    
    return (response as List).cast<Map<String, dynamic>>();
  }

  Future<void> createSocialPost(String userId, String content, {String? type}) async {
    await _supabase.from('social_posts').insert({
      'user_id': userId,
      'content': content,
      'type': type ?? 'reflection',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> likeSocialPost(String postId, String userId) async {
    await _supabase.from('social_likes').insert({
      'post_id': postId,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

