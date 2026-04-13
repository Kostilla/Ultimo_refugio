import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ultimo_refugio/core/services/supabase_service.dart';

class ExpeditionsScreen extends StatefulWidget {
  const ExpeditionsScreen({super.key});

  @override
  State<ExpeditionsScreen> createState() => _ExpeditionsScreenState();
}

class _ExpeditionsScreenState extends State<ExpeditionsScreen> {
  final _random = Random();

  Future<Map<String, dynamic>?> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final membership = await supabase
        .from('colony_members')
        .select('colony_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    if (membership == null) return null;

    final colonyId = membership['colony_id'];

    final resources = await supabase
        .from('colony_resources')
        .select()
        .eq('colony_id', colonyId)
        .maybeSingle();

    var expeditions = await supabase
        .from('colony_expeditions')
        .select()
        .eq('colony_id', colonyId)
        .order('started_at', ascending: false);

    final now = DateTime.now().toUtc();

    for (final e in expeditions) {
      if (e['status'] == 'in_progress' && e['ends_at'] != null) {
        final endsAt = DateTime.parse(e['ends_at'].toString()).toUtc();
        if (!endsAt.isAfter(now)) {
          await supabase
              .from('colony_expeditions')
              .update({'status': 'ready'})
              .eq('id', e['id']);
        }
      }
    }

    expeditions = await supabase
        .from('colony_expeditions')
        .select()
        .eq('colony_id', colonyId)
        .order('started_at', ascending: false);

    final hasActiveExpedition = expeditions.any(
      (e) => e['status'] == 'in_progress',
    );

    return {
      'colony_id': colonyId,
      'resources': resources,
      'expeditions': expeditions,
      'has_active_expedition': hasActiveExpedition,
    };
  }

  List<Map<String, dynamic>> _expeditionTemplates() {
    return [
      {
        'type': 'ruins',
        'title': 'Ruinas cercanas',
        'description': 'Una exploración rápida por edificios derruidos.',
        'duration_minutes': 2,
        'cost_food': 5,
        'cost_water': 5,
      },
      {
        'type': 'depot',
        'title': 'Depósito abandonado',
        'description': 'Una zona industrial con posibles materiales útiles.',
        'duration_minutes': 5,
        'cost_food': 10,
        'cost_water': 10,
      },
      {
        'type': 'danger_zone',
        'title': 'Zona peligrosa',
        'description': 'Expedición larga con mejor recompensa potencial.',
        'duration_minutes': 10,
        'cost_food': 20,
        'cost_water': 15,
      },
    ];
  }

  Map<String, int> _generateRewards(String type) {
    switch (type) {
      case 'ruins':
        return {
          'food': _random.nextInt(11),
          'water': _random.nextInt(11),
          'energy': _random.nextInt(6),
          'metal': 10 + _random.nextInt(16),
        };
      case 'depot':
        return {
          'food': _random.nextInt(16),
          'water': _random.nextInt(16),
          'energy': 5 + _random.nextInt(11),
          'metal': 20 + _random.nextInt(21),
        };
      case 'danger_zone':
        return {
          'food': 10 + _random.nextInt(21),
          'water': 10 + _random.nextInt(21),
          'energy': 10 + _random.nextInt(16),
          'metal': 30 + _random.nextInt(31),
        };
      default:
        return {
          'food': 0,
          'water': 0,
          'energy': 0,
          'metal': 0,
        };
    }
  }

  Future<void> _startExpedition({
    required String colonyId,
    required Map<String, dynamic>? resources,
    required Map<String, dynamic> template,
    required bool hasActiveExpedition,
  }) async {
    if (resources == null) {
      throw Exception('No se encontraron recursos');
    }

    if (hasActiveExpedition) {
      throw Exception('Ya hay una expedición en curso');
    }

    final currentFood = (resources['food'] as num?)?.toInt() ?? 0;
    final currentWater = (resources['water'] as num?)?.toInt() ?? 0;

    final costFood = (template['cost_food'] as num).toInt();
    final costWater = (template['cost_water'] as num).toInt();

    if (currentFood < costFood || currentWater < costWater) {
      throw Exception('No tienes suficientes recursos');
    }

    final rewards = _generateRewards(template['type'] as String);

    final endsAt = DateTime.now().toUtc().add(
          Duration(minutes: (template['duration_minutes'] as num).toInt()),
        );

    await supabase.from('colony_resources').update({
      'food': currentFood - costFood,
      'water': currentWater - costWater,
    }).eq('colony_id', colonyId);

    await supabase.from('colony_expeditions').insert({
      'colony_id': colonyId,
      'type': template['type'],
      'status': 'in_progress',
      'ends_at': endsAt.toIso8601String(),
      'reward_food': rewards['food'],
      'reward_water': rewards['water'],
      'reward_energy': rewards['energy'],
      'reward_metal': rewards['metal'],
      'created_by': supabase.auth.currentUser?.id,
    });
  }

  Future<void> _claimExpedition({
    required String colonyId,
    required Map<String, dynamic>? resources,
    required Map<String, dynamic> expedition,
  }) async {
    if (resources == null) {
      throw Exception('No se encontraron recursos');
    }

    final currentFood = (resources['food'] as num?)?.toInt() ?? 0;
    final currentWater = (resources['water'] as num?)?.toInt() ?? 0;
    final currentEnergy = (resources['energy'] as num?)?.toInt() ?? 0;
    final currentMetal = (resources['metal'] as num?)?.toInt() ?? 0;

    final rewardFood = (expedition['reward_food'] as num?)?.toInt() ?? 0;
    final rewardWater = (expedition['reward_water'] as num?)?.toInt() ?? 0;
    final rewardEnergy = (expedition['reward_energy'] as num?)?.toInt() ?? 0;
    final rewardMetal = (expedition['reward_metal'] as num?)?.toInt() ?? 0;

    await supabase.from('colony_resources').update({
      'food': currentFood + rewardFood,
      'water': currentWater + rewardWater,
      'energy': currentEnergy + rewardEnergy,
      'metal': currentMetal + rewardMetal,
    }).eq('colony_id', colonyId);

    await supabase.from('colony_expeditions').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', expedition['id']);
  }

  String _expeditionLabel(String type) {
    switch (type) {
      case 'ruins':
        return 'Ruinas cercanas';
      case 'depot':
        return 'Depósito abandonado';
      case 'danger_zone':
        return 'Zona peligrosa';
      default:
        return type;
    }
  }

  String _remainingTime(String? endsAtRaw) {
    if (endsAtRaw == null) return 'Finalizando...';

    final endsAt = DateTime.parse(endsAtRaw).toUtc();
    final now = DateTime.now().toUtc();
    final diff = endsAt.difference(now);

    if (diff.inSeconds <= 0) return 'Lista para reclamar';

    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String _rewardText(Map<String, dynamic> e) {
    final rf = (e['reward_food'] as num?)?.toInt() ?? 0;
    final rw = (e['reward_water'] as num?)?.toInt() ?? 0;
    final re = (e['reward_energy'] as num?)?.toInt() ?? 0;
    final rm = (e['reward_metal'] as num?)?.toInt() ?? 0;

    return '🍖 $rf | 💧 $rw | ⚡ $re | 🔩 $rm';
  }

  @override
  Widget build(BuildContext context) {
    final templates = _expeditionTemplates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expediciones'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('No se encontraron datos'),
            );
          }

          final colonyId = data['colony_id'] as String;
          final resources = data['resources'] as Map<String, dynamic>?;
          final expeditions = (data['expeditions'] as List<dynamic>? ?? []);
          final hasActiveExpedition =
              data['has_active_expedition'] as bool? ?? false;

          final currentFood =
              resources == null ? 0 : (resources['food'] as num).toInt();
          final currentWater =
              resources == null ? 0 : (resources['water'] as num).toInt();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: ListTile(
                    title: const Text('🍖 Comida'),
                    trailing: Text('$currentFood'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('💧 Agua'),
                    trailing: Text('$currentWater'),
                  ),
                ),
                const SizedBox(height: 16),
                if (hasActiveExpedition)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.travel_explore),
                      title: Text('Ya hay una expedición en curso'),
                      subtitle: Text(
                        'Debes esperar a que termine antes de enviar otra.',
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Enviar expedición',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...templates.map((t) {
                  final costFood = t['cost_food'];
                  final costWater = t['cost_water'];
                  final canAfford =
                      currentFood >= costFood && currentWater >= costWater;
                  final canStart = canAfford && !hasActiveExpedition;

                  return Card(
                    child: ListTile(
                      title: Text('${t['title']}'),
                      subtitle: Text(
                        '${t['description']}\n'
                        'Coste: 🍖 $costFood | 💧 $costWater\n'
                        'Duración: ${t['duration_minutes']} min',
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: canStart
                            ? () async {
                                try {
                                  await _startExpedition(
                                    colonyId: colonyId,
                                    resources: resources,
                                    template: t,
                                    hasActiveExpedition: hasActiveExpedition,
                                  );

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Expedición iniciada'),
                                    ),
                                  );
                                  setState(() {});
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: const Text('Enviar'),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                const Text(
                  'Historial / estado',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (expeditions.isEmpty)
                  const Card(
                    child: ListTile(
                      title: Text('No hay expediciones todavía'),
                    ),
                  ),
                ...expeditions.map((e) {
                  final expedition = e as Map<String, dynamic>;
                  final status = '${expedition['status']}';
                  final isReady = status == 'ready';
                  final isResolved = status == 'resolved';

                  return Card(
                    child: ListTile(
                      title: Text(
                        _expeditionLabel('${expedition['type']}'),
                      ),
                      subtitle: Text(
                        isResolved
                            ? 'Resuelta\nRecompensa: ${_rewardText(expedition)}'
                            : isReady
                                ? 'Lista para reclamar\nRecompensa: ${_rewardText(expedition)}'
                                : 'En curso: ${_remainingTime(expedition['ends_at'] as String?)}\n'
                                    'Recompensa esperada: ${_rewardText(expedition)}',
                      ),
                      isThreeLine: true,
                      trailing: isReady
                          ? ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _claimExpedition(
                                    colonyId: colonyId,
                                    resources: resources,
                                    expedition: expedition,
                                  );

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Recompensa reclamada'),
                                    ),
                                  );
                                  setState(() {});
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Reclamar'),
                            )
                          : Text(
                              isResolved ? 'Hecha' : 'En curso',
                            ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}