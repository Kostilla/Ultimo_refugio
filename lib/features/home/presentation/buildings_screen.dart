import 'package:flutter/material.dart';
import 'package:ultimo_refugio/core/services/supabase_service.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
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

    var buildings = await supabase
        .from('colony_buildings')
        .select()
        .eq('colony_id', colonyId);

    final now = DateTime.now().toUtc();

    for (final b in buildings) {
      final isUpgrading = b['is_upgrading'] == true;
      final upgradeEndsAtRaw = b['upgrade_ends_at'];

      if (isUpgrading && upgradeEndsAtRaw != null) {
        final upgradeEndsAt =
            DateTime.parse(upgradeEndsAtRaw.toString()).toUtc();

        if (!upgradeEndsAt.isAfter(now)) {
          await supabase
              .from('colony_buildings')
              .update({
                'level': (b['level'] as num).toInt() + 1,
                'is_upgrading': false,
                'upgrade_ends_at': null,
              })
              .eq('id', b['id']);
        }
      }
    }

    buildings = await supabase
        .from('colony_buildings')
        .select()
        .eq('colony_id', colonyId);

    return {
      'colony_id': colonyId,
      'resources': resources,
      'buildings': buildings,
    };
  }

  String _buildingLabel(String type) {
  switch (type) {
    case 'generator':
      return 'Generador';
    case 'farm':
      return 'Invernadero';
    case 'water':
      return 'Depuradora';
    case 'factory':
      return 'Taller';
    case 'storage':
      return 'Almacén';
    default:
      return type;
  }
}

  String _buildingDescription(String type) {
    switch (type) {
      case 'generator':
        return 'Aumenta la producción de energía';
      case 'farm':
        return 'Aumenta la producción de comida';
      case 'water':
        return 'Aumenta la producción de agua';
      case 'factory':
        return 'Aumenta la producción de metal';
      default:
        return '';
    }
  }

  Map<String, int> _upgradeCost(String type, int level) {
    final nextLevel = level + 1;

    switch (type) {
      case 'generator':
        return {
          'metal': 40 * nextLevel,
          'energy': 20 * nextLevel,
        };
      case 'farm':
        return {
          'metal': 30 * nextLevel,
          'water': 15 * nextLevel,
        };
      case 'water':
        return {
          'metal': 30 * nextLevel,
          'energy': 15 * nextLevel,
        };
      case 'factory':
        return {
          'metal': 50 * nextLevel,
          'food': 20 * nextLevel,
        };
      default:
        return {
          'metal': 50 * nextLevel,
        };
    }
  }

  int _upgradeDurationMinutes(int level) {
    return level * 2;
  }

  String _formatCost(Map<String, int> cost) {
    final parts = <String>[];

    if ((cost['food'] ?? 0) > 0) {
      parts.add('🍖 ${cost['food']}');
    }
    if ((cost['water'] ?? 0) > 0) {
      parts.add('💧 ${cost['water']}');
    }
    if ((cost['energy'] ?? 0) > 0) {
      parts.add('⚡ ${cost['energy']}');
    }
    if ((cost['metal'] ?? 0) > 0) {
      parts.add('🔩 ${cost['metal']}');
    }

    return parts.join(' | ');
  }

  bool _canAfford(Map<String, dynamic>? resources, Map<String, int> cost) {
    if (resources == null) return false;

    final food = (resources['food'] as num?)?.toInt() ?? 0;
    final water = (resources['water'] as num?)?.toInt() ?? 0;
    final energy = (resources['energy'] as num?)?.toInt() ?? 0;
    final metal = (resources['metal'] as num?)?.toInt() ?? 0;

    return food >= (cost['food'] ?? 0) &&
        water >= (cost['water'] ?? 0) &&
        energy >= (cost['energy'] ?? 0) &&
        metal >= (cost['metal'] ?? 0);
  }

  Future<void> _startUpgrade({
    required String colonyId,
    required String buildingId,
    required String type,
    required int currentLevel,
    required Map<String, dynamic>? resources,
  }) async {
    if (resources == null) {
      throw Exception('No se encontraron recursos');
    }

    final cost = _upgradeCost(type, currentLevel);

    if (!_canAfford(resources, cost)) {
      throw Exception('No tienes suficientes recursos');
    }

    final currentFood = (resources['food'] as num?)?.toInt() ?? 0;
    final currentWater = (resources['water'] as num?)?.toInt() ?? 0;
    final currentEnergy = (resources['energy'] as num?)?.toInt() ?? 0;
    final currentMetal = (resources['metal'] as num?)?.toInt() ?? 0;

    await supabase.from('colony_resources').update({
      'food': currentFood - (cost['food'] ?? 0),
      'water': currentWater - (cost['water'] ?? 0),
      'energy': currentEnergy - (cost['energy'] ?? 0),
      'metal': currentMetal - (cost['metal'] ?? 0),
    }).eq('colony_id', colonyId);

    final endsAt = DateTime.now()
        .toUtc()
        .add(Duration(minutes: _upgradeDurationMinutes(currentLevel)));

    await supabase.from('colony_buildings').update({
      'is_upgrading': true,
      'upgrade_ends_at': endsAt.toIso8601String(),
    }).eq('id', buildingId);
  }

  String _formatRemainingTime(String? endsAtRaw) {
    if (endsAtRaw == null) return 'Finalizando...';

    final endsAt = DateTime.parse(endsAtRaw).toUtc();
    final now = DateTime.now().toUtc();
    final diff = endsAt.difference(now);

    if (diff.inSeconds <= 0) return 'Finalizando...';

    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edificios'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('No se encontraron datos de colonia'),
            );
          }

          final colonyId = data['colony_id'] as String;
          final resources = data['resources'] as Map<String, dynamic>?;
          final buildings = (data['buildings'] as List<dynamic>? ?? []);

          final currentFood =
              resources == null ? 0 : (resources['food'] as num).toInt();
          final currentWater =
              resources == null ? 0 : (resources['water'] as num).toInt();
          final currentEnergy =
              resources == null ? 0 : (resources['energy'] as num).toInt();
          final currentMetal =
              resources == null ? 0 : (resources['metal'] as num).toInt();

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
                Card(
                  child: ListTile(
                    title: const Text('⚡ Energía'),
                    trailing: Text('$currentEnergy'),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: const Text('🔩 Metal'),
                    trailing: Text('$currentMetal'),
                  ),
                ),
                const SizedBox(height: 16),
                ...buildings.map((b) {
                  final type = '${b['type']}';
                  final level = (b['level'] as num).toInt();
                  final isUpgrading = b['is_upgrading'] == true;
                  final upgradeEndsAt = b['upgrade_ends_at'] as String?;
                  final cost = _upgradeCost(type, level);
                  final canAfford = _canAfford(resources, cost);
                  final duration = _upgradeDurationMinutes(level);

                  return Card(
                    child: ListTile(
                      title: Text(_buildingLabel(type)),
                      subtitle: Text(
                        isUpgrading
                            ? '${_buildingDescription(type)}\n'
                                'Nivel actual: $level\n'
                                'Mejorando... ${_formatRemainingTime(upgradeEndsAt)}'
                            : '${_buildingDescription(type)}\n'
                                'Nivel actual: $level\n'
                                'Coste mejora: ${_formatCost(cost)}\n'
                                'Tiempo: ${duration} min',
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: isUpgrading || !canAfford
                            ? null
                            : () async {
                                try {
                                  await _startUpgrade(
                                    colonyId: colonyId,
                                    buildingId: b['id'] as String,
                                    type: type,
                                    currentLevel: level,
                                    resources: resources,
                                  );

                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Mejora iniciada'),
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
                        child: Text(isUpgrading ? 'En curso' : 'Mejorar'),
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