import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ultimo_refugio/core/services/supabase_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
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

    final activeEvents = await supabase
        .from('colony_events')
        .select()
        .eq('colony_id', colonyId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    if (activeEvents.isEmpty) {
      await _maybeGenerateEvent(colonyId);
    }

    final refreshedEvents = await supabase
        .from('colony_events')
        .select()
        .eq('colony_id', colonyId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return {
      'colony_id': colonyId,
      'resources': resources,
      'events': refreshedEvents,
    };
  }

  Future<void> _maybeGenerateEvent(String colonyId) async {
    final roll = _random.nextInt(100);

    if (roll >= 35) return;

    final events = [
      {
        'type': 'storm',
        'title': 'Tormenta eléctrica',
        'description': 'Una tormenta ha dañado parte del sistema energético.',
        'effect_resource': 'energy',
        'effect_amount': -20,
      },
      {
        'type': 'supply',
        'title': 'Suministros encontrados',
        'description': 'Un grupo de exploración ha encontrado provisiones útiles.',
        'effect_resource': 'food',
        'effect_amount': 25,
      },
      {
        'type': 'leak',
        'title': 'Fuga de agua',
        'description': 'Una avería ha provocado pérdida de agua en la colonia.',
        'effect_resource': 'water',
        'effect_amount': -15,
      },
      {
        'type': 'scrap',
        'title': 'Hallazgo de chatarra',
        'description': 'Se han recuperado piezas y metal reutilizable.',
        'effect_resource': 'metal',
        'effect_amount': 20,
      },
    ];

    final event = events[_random.nextInt(events.length)];

    await supabase.from('colony_events').insert({
      'colony_id': colonyId,
      'type': event['type'],
      'title': event['title'],
      'description': event['description'],
      'effect_resource': event['effect_resource'],
      'effect_amount': event['effect_amount'],
      'status': 'active',
    });
  }

  Future<void> _resolveEvent({
    required String colonyId,
    required Map<String, dynamic> event,
    required Map<String, dynamic>? resources,
  }) async {
    if (resources == null) {
      throw Exception('No se encontraron recursos');
    }

    final resource = event['effect_resource'] as String?;
    final amount = (event['effect_amount'] as num?)?.toInt() ?? 0;

    final currentFood = (resources['food'] as num?)?.toInt() ?? 0;
    final currentWater = (resources['water'] as num?)?.toInt() ?? 0;
    final currentEnergy = (resources['energy'] as num?)?.toInt() ?? 0;
    final currentMetal = (resources['metal'] as num?)?.toInt() ?? 0;

    int capMinZero(int value) => value < 0 ? 0 : value;

    final updated = {
      'food': currentFood,
      'water': currentWater,
      'energy': currentEnergy,
      'metal': currentMetal,
    };

    switch (resource) {
      case 'food':
        updated['food'] = capMinZero(currentFood + amount);
        break;
      case 'water':
        updated['water'] = capMinZero(currentWater + amount);
        break;
      case 'energy':
        updated['energy'] = capMinZero(currentEnergy + amount);
        break;
      case 'metal':
        updated['metal'] = capMinZero(currentMetal + amount);
        break;
    }

    await supabase
        .from('colony_resources')
        .update(updated)
        .eq('colony_id', colonyId);

    await supabase.from('colony_events').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', event['id']);
  }

  String _resourceLabel(String? resource) {
    switch (resource) {
      case 'food':
        return 'Comida';
      case 'water':
        return 'Agua';
      case 'energy':
        return 'Energía';
      case 'metal':
        return 'Metal';
      default:
        return 'Recurso';
    }
  }

  String _effectText(Map<String, dynamic> event) {
    final resource = event['effect_resource'] as String?;
    final amount = (event['effect_amount'] as num?)?.toInt() ?? 0;
    final sign = amount >= 0 ? '+' : '';
    return '$sign$amount ${_resourceLabel(resource)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
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
              child: Text('No se encontraron datos'),
            );
          }

          final colonyId = data['colony_id'] as String;
          final resources = data['resources'] as Map<String, dynamic>?;
          final events = (data['events'] as List<dynamic>? ?? []);

          if (events.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 40),
                  Center(
                    child: Text('No hay eventos activos'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ...events.map((e) {
                  final event = e as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      title: Text('${event['title']}'),
                      subtitle: Text(
                        '${event['description']}\n'
                        'Efecto: ${_effectText(event)}',
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _resolveEvent(
                              colonyId: colonyId,
                              event: event,
                              resources: resources,
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Evento resuelto'),
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
                        child: const Text('Resolver'),
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