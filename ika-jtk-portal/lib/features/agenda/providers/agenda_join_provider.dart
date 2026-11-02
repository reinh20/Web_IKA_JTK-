import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/providers/auth_provider.dart';

class AgendaJoinController extends StateNotifier<Set<String>> {
  final Ref _ref;
  AgendaJoinController(this._ref) : super(const {}) {
    _load();
  }

  String get _key {
    final user = _ref.read(authProvider).user;
    return user != null ? 'joined_agendas_${user.id}' : 'joined_agendas_guest';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    state = list.toSet();
  }

  Future<void> join(String agendaId) async {
    if (state.contains(agendaId)) return;
    final next = {...state, agendaId};
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }

  Future<void> leave(String agendaId) async {
    if (!state.contains(agendaId)) return;
    final next = {...state}..remove(agendaId);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.toList());
  }
}

final agendaJoinProvider =
    StateNotifierProvider.autoDispose<AgendaJoinController, Set<String>>(
  (ref) {
    ref.watch(authProvider.select((a) => a.user?.id));
    return AgendaJoinController(ref);
  },
);
