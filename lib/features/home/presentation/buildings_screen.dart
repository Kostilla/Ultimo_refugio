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

    final buildings = await supabase
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

  int _upgradeCost(int level) {
    return level * 50;
  }

  Future<void> _upgradeBuilding({
    required String colonyId,
    required String buildingId,
    required int currentLevel,
    required int currentMetal,
  }) async {
    final cost = _upgradeCost(currentLevel);

    if (currentMetal < cost) {
      throw Exception('No tienes suficiente metal');
    }

    await supabase.from('colony_resources').update({
      'metal': currentMetal - cost,
    }).eq('colony_id', colonyId);

    await supabase.from('colony_buildings').update({
      'level': currentLevel + 1,
    }).eq('id', buildingId);
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
                    leading: const Icon(Icons.precision_manufacturing),
                    title: const Text('Metal disponible'),
                    trailing: Text('$currentMetal'),
                  ),
                ),
                const SizedBox(height: 16),
                ...buildings.map((b) {
                  final type = '${b['type']}';
                  final level = (b['level'] as num).toInt();
                  final cost = _upgradeCost(level);

                  return Card(
                    child: ListTile(
                      title: Text(_buildingLabel(type)),
                      subtitle: Text(
                        '${_buildingDescription(type)}\nNivel actual: $level\nMejora: $cost metal',
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _upgradeBuilding(
                              colonyId: colonyId,
                              buildingId: b['id'] as String,
                              currentLevel: level,
                              currentMetal: currentMetal,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Edificio mejorado'),
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
                        child: const Text('Mejorar'),
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