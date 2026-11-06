import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/database/database.dart';
import '../../domain/timer/timer_math.dart';
import 'session_repository.dart';

// ============================================================
// ARQUIVO: lib/features/timer/timer_controller.dart
// FUNÇÃO: Acompanha a sessão de cronômetro ativa e atualiza a tela a
//         cada segundo. O "tique" serve SÓ para redesenhar o relógio:
//         o tempo em si é sempre recalculado a partir dos horários
//         gravados no banco (lib/domain/timer/timer_math.dart).
// ============================================================

class TimerController extends ChangeNotifier {
  final SessionRepository repo;

  TimerController(this.repo) {
    _activeSub = repo.watchActive().listen(_onActive);
  }

  StudySession? active;
  List<SessionPause> pauses = [];

  StreamSubscription<StudySession?>? _activeSub;
  StreamSubscription<List<SessionPause>>? _pauseSub;
  Timer? _ticker;

  bool get hasActive => active != null;
  bool get isPaused => active?.status == 'paused';

  List<PauseInterval> get _intervals =>
      [for (final p in pauses) PauseInterval(p.startedAt, p.endedAt)];

  /// Tempo efetivamente estudado (sem pausas), em segundos.
  int get studySeconds {
    final s = active;
    if (s == null) return 0;
    return studiedSeconds(
        start: s.startedAt, pauses: _intervals, now: DateTime.now());
  }

  /// Tempo pausado, em segundos.
  int get pauseSeconds => pausedSeconds(_intervals, DateTime.now());

  /// Tempo total da sessão (estudo + pausas).
  int get totalSeconds {
    final s = active;
    if (s == null) return 0;
    return totalSessionSeconds(s.startedAt, DateTime.now());
  }

  void _onActive(StudySession? s) {
    final changedSession = s?.id != active?.id;
    active = s;
    if (changedSession) {
      _pauseSub?.cancel();
      pauses = [];
      if (s != null) {
        _pauseSub = repo.watchPauses(s.id).listen((p) {
          pauses = p;
          notifyListeners();
        });
      }
    }
    _ticker?.cancel();
    if (s != null) {
      _ticker =
          Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    }
    notifyListeners();
  }

  Future<void> start({required int subjectId, int? nodeId, int? plannedSeconds}) =>
      repo.start(
          subjectId: subjectId, nodeId: nodeId, plannedSeconds: plannedSeconds);

  Future<void> pause() async {
    final s = active;
    if (s != null) await repo.pause(s.id);
  }

  Future<void> resume() async {
    final s = active;
    if (s != null) await repo.resume(s.id);
  }

  Future<void> finish({int? adjustedStudySeconds, String notes = ''}) async {
    final s = active;
    if (s != null) {
      await repo.finish(s.id,
          adjustedStudySeconds: adjustedStudySeconds, notes: notes);
    }
  }

  Future<void> cancel() async {
    final s = active;
    if (s != null) await repo.cancel(s.id);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _activeSub?.cancel();
    _pauseSub?.cancel();
    super.dispose();
  }
}
