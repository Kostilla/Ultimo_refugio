import 'dart:math';

import '../../../core/services/supabase_service.dart';

class ColonyRepository {
  final _random = Random();

  String _generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  Future<void> createColony(String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final joinCode = _generateJoinCode();

    final colony = await supabase
        .from('colonies')
        .insert({
          'name': name,
          'join_code': joinCode,
          'created_by': user.id,
        })
        .select('id')
        .single();

    await supabase.from('colony_members').insert({
      'colony_id': colony['id'],
      'user_id': user.id,
      'role': 'leader',
    });
    await supabase.from('colony_resources').insert({
      'colony_id': colony['id'],
      'food': 100,
      'water': 100,
      'energy': 100,
      'metal': 100,
    });

  }

  Future<void> joinColony(String joinCode) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final colony = await supabase
        .from('colonies')
        .select('id')
        .eq('join_code', joinCode.trim().toUpperCase())
        .maybeSingle();

    if (colony == null) throw Exception('Codigo no encontrado');

    await supabase.from('colony_members').insert({
      'colony_id': colony['id'],
      'user_id': user.id,
      'role': 'member',
    });
  }
}
