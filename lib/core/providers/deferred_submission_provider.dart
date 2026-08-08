import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeferredSubmissionPhase { pending, committing }

typedef DeferredSubmissionAction = Future<void> Function();

final deferredSubmissionProvider =
    NotifierProvider<
      DeferredSubmissionController,
      Map<String, DeferredSubmissionPhase>
    >(DeferredSubmissionController.new);

class DeferredSubmissionController
    extends Notifier<Map<String, DeferredSubmissionPhase>> {
  static const undoDuration = Duration(milliseconds: 5000);

  final Map<String, Timer> _timers = {};

  @override
  Map<String, DeferredSubmissionPhase> build() {
    ref.onDispose(() {
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  void queue({
    required String id,
    required DeferredSubmissionAction action,
    required void Function() onSuccess,
    required void Function(Object error) onError,
  }) {
    if (state.containsKey(id)) return;

    state = {...state, id: DeferredSubmissionPhase.pending};
    _timers[id] = Timer(
      undoDuration,
      () => unawaited(
        _commit(id: id, action: action, onSuccess: onSuccess, onError: onError),
      ),
    );
  }

  void cancel(String id) {
    if (state[id] != DeferredSubmissionPhase.pending) return;
    _timers.remove(id)?.cancel();
    state = Map.of(state)..remove(id);
  }

  Future<void> _commit({
    required String id,
    required DeferredSubmissionAction action,
    required void Function() onSuccess,
    required void Function(Object error) onError,
  }) async {
    _timers.remove(id);
    if (state[id] != DeferredSubmissionPhase.pending) return;
    state = {...state, id: DeferredSubmissionPhase.committing};

    try {
      await action();
      onSuccess();
    } catch (error) {
      onError(error);
    } finally {
      state = Map.of(state)..remove(id);
    }
  }
}
