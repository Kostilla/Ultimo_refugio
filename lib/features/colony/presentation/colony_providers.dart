import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/colony_repository.dart';

final colonyRepositoryProvider = Provider<ColonyRepository>((ref) {
  return ColonyRepository();
});

final colonyLoadingProvider = StateProvider<bool>((ref) => false);
