import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/simulation.dart';
import 'firebase_service.dart';

class AppState extends ChangeNotifier {
  AppState(this.preferences) {
    _readHistory();
    if (FirebaseService.ready) {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        _onAuth,
      );
    }
  }
  final SharedPreferences preferences;
  StreamSubscription<User?>? _authSubscription;
  User? user;
  List<LoanSimulation> history = [];
  String? syncMessage;
  bool get hasOnboarded => preferences.getBool('onboarded') ?? false;
  bool get notificationsEnabled =>
      preferences.getBool('notifications') ?? false;
  String get _historyKey => 'history_${user?.uid ?? 'guest'}';
  CollectionReference<Map<String, dynamic>> get _collection => FirebaseFirestore
      .instance
      .collection('users')
      .doc(user!.uid)
      .collection('simulations');

  void _readHistory() {
    final saved = preferences.getStringList(_historyKey) ?? [];
    history = [];
    for (final value in saved) {
      try {
        history.add(
          LoanSimulation.fromJson(jsonDecode(value) as Map<String, dynamic>),
        );
      } catch (_) {
        /* Ignore an invalid record without losing the other entries. */
      }
    }
    history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _persist() async {
    final saved = await preferences.setStringList(
      _historyKey,
      history.map((s) => jsonEncode(s.toJson())).toList(),
    );
    if (!saved) {
      throw StateError('Não foi possível salvar o histórico no dispositivo.');
    }
  }

  Future<void> _onAuth(User? next) async {
    user = next;
    syncMessage = null;
    _readHistory();
    notifyListeners();
    if (next == null) return;
    final uid = next.uid;
    try {
      final snapshot = await _collection.get().timeout(
        const Duration(seconds: 12),
      );
      if (user?.uid != uid) return;
      final merged = {for (final s in history) s.id: s};
      for (final doc in snapshot.docs) {
        final simulation = LoanSimulation.fromJson(doc.data());
        merged.putIfAbsent(simulation.id, () => simulation);
      }
      history = merged.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _persist();
    } catch (_) {
      if (user?.uid != uid) return;
      syncMessage = 'Sincronização indisponível. Seu histórico local continua disponível.';
    }
    notifyListeners();
  }

  Future<void> save(LoanSimulation simulation) async {
    if (history.any((entry) => entry.id == simulation.id)) {
      return;
    }
    history.insert(0, simulation);
    try {
      await _persist();
    } catch (_) {
      history.removeWhere((s) => s.id == simulation.id);
      rethrow;
    }
    syncMessage = null;
    notifyListeners();
    if (user != null) {
      try {
        await _collection
            .doc(simulation.id)
            .set(simulation.toJson())
            .timeout(const Duration(seconds: 12));
      } catch (_) {
        syncMessage = 'Simulação salva neste aparelho. Não foi possível copiar para a nuvem.';
      }
      notifyListeners();
    }
  }

  Future<void> remove(LoanSimulation simulation) async {
    // Delete remotely first so a failed cloud deletion cannot silently reappear.
    if (user != null) {
      await _collection
          .doc(simulation.id)
          .delete()
          .timeout(const Duration(seconds: 12));
    }
    final previous = List<LoanSimulation>.of(history);
    history.removeWhere((s) => s.id == simulation.id);
    try {
      await _persist();
    } catch (_) {
      history = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    await preferences.setBool('onboarded', true);
    notifyListeners();
  }

  Future<void> setNotifications(bool enabled) async {
    await preferences.setBool('notifications', enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
