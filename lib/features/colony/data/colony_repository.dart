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
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Introduce un nombre de colonia');
    }

    final joinCode = _generateJoinCode();

    final colony = await supabase
        .from('colonies')
        .insert({
          'name': trimmedName,
          'join_code': joinCode,
          'created_by': user.id,
        })
        .select('id')
        .single();

    final colonyId = colony['id'];

    await supabase.from('colony_members').insert({
      'colony_id': colonyId,
      'user_id': user.id,
      'role': 'leader',
    });

    await supabase.from('colony_resources').insert({
      'colony_id': colonyId,
      'food': 100,
      'water': 100,
      'energy': 100,
      'metal': 100,
      'last_updated': DateTime.now().toUtc().toIso8601String(),
    });

    await supabase.from('colony_buildings').insert([
  {
    'colony_id': colonyId,
    'type': 'generator',
    'level': 1,
  },
  {
    'colony_id': colonyId,
    'type': 'farm',
    'level': 1,
  },
  {
    'colony_id': colonyId,
    'type': 'water',
    'level': 1,
  },
  {
    'colony_id': colonyId,
    'type': 'factory',
    'level': 1,
  },
  {
    'colony_id': colonyId,
    'type': 'storage',
    'level': 1,
  },
]);
  }

  Future<void> joinColony(String joinCode) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    final trimmedCode = joinCode.trim().toUpperCase();
    if (trimmedCode.isEmpty) {
      throw Exception('Introduce un código');
    }

    final colony = await supabase
        .from('colonies')
        .select('id')
        .eq('join_code', trimmedCode)
        .maybeSingle();

    if (colony == null) {
      throw Exception('Código no encontrado');
    }

    await supabase.from('colony_members').insert({
      'colony_id': colony['id'],
      'user_id': user.id,
      'role': 'member',
    });
  }
}