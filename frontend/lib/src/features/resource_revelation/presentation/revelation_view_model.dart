import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/revelation.dart';

abstract class RevelationClipboard {
  Future<void> write(String value);
  Future<String?> read();
  Future<void> clear();
}

class RevelationViewModel extends ChangeNotifier {
  RevelationViewModel({
    required this.repository,
    required this.resource,
    required this.clipboard,
    this.onSessionLost,
    DateTime Function()? now,
    Duration Function()? elapsed,
    bool startTimers = true,
  }) : _identity = repository.sessionIdentity,
       _now = now ?? (() => DateTime.now().toUtc()),
       _externalElapsed = elapsed {
    _clock.start();
    if (startTimers) {
      _timer = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => checkDeadlines(),
      );
      _poll = Timer.periodic(
        const Duration(seconds: 2),
        (_) => refreshStatus(),
      );
    }
  }
  final ResourceRevelationRepository repository;
  final RevelationResource resource;
  final RevelationClipboard clipboard;
  final VoidCallback? onSessionLost;
  final Object? _identity;
  final DateTime Function() _now;
  final Duration Function()? _externalElapsed;
  final Stopwatch _clock = Stopwatch();
  Duration get _elapsed => _externalElapsed?.call() ?? _clock.elapsed;
  Timer? _timer, _poll;
  RevelationSession? _session;
  RevelationValue? _value;
  String? _challenge, _copied;
  Duration? _authorizationDeadline, _valueDeadline;
  DateTime? _authorizationWall, _valueWall;
  bool _busy = false,
      _checking = false,
      _disposed = false,
      _lostSession = false,
      _copyAllowed = false;
  int _epoch = 0, _lastSeconds = -1;
  String? error;
  bool get busy => _busy;
  bool get requiresMfa => _challenge != null;
  bool get hasSession => _session != null;
  bool get canRevealCredential => _session?.hasCredential ?? false;
  bool get canRevealTotp => _session?.hasTotp ?? false;
  RevelationValue? get value => _value;
  int get secondsLeft {
    final auth = _authorizationDeadline;
    final value = _value != null ? _valueDeadline : null;
    final end = value == null || (auth != null && auth < value) ? auth : value;
    if (end == null) return 0;
    final ms = (end - _elapsed).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  bool get canCopy =>
      _copyAllowed &&
      _value?.kind == 'TOTP' &&
      _value?.code != null &&
      _value!.allowsCodeCopy &&
      resource.allowsCodeCopy &&
      const {'BAIXA', 'MEDIA'}.contains(resource.criticality);
  bool get _validIdentity =>
      repository.hasValidSession &&
      identical(_identity, repository.sessionIdentity) &&
      _identity != null;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  bool _current(int epoch) {
    if (_disposed || epoch != _epoch) return false;
    if (!_validIdentity) {
      checkDeadlines();
      return false;
    }
    return true;
  }

  void _boundAuthorization(
    DateTime serverTime,
    DateTime until,
    Duration started,
  ) {
    final budget = until.difference(serverTime);
    final deadline = started + budget;
    if (_authorizationDeadline == null || deadline < _authorizationDeadline!) {
      _authorizationDeadline = deadline;
    }
    final wall = _now().add(budget - (_elapsed - started));
    if (_authorizationWall == null || wall.isBefore(_authorizationWall!)) {
      _authorizationWall = wall;
    }
  }

  Future<void> authenticate(String requestId, String password) async {
    if (_busy || _session != null || !_validIdentity) return;
    final epoch = ++_epoch;
    _busy = true;
    error = null;
    _challenge = null;
    _notify();
    try {
      final verification = await repository.reauthenticate(password);
      if (!_current(epoch)) return;
      if (verification.requiresMfa) {
        _challenge = verification.challengeToken;
        if (_challenge == null) throw const RevelationFailure();
      } else {
        final proof = verification.proof;
        if (proof == null) throw const RevelationFailure();
        await _open(requestId, proof, epoch);
      }
    } catch (_) {
      if (_current(epoch)) await _fail();
    } finally {
      if (_current(epoch)) {
        _busy = false;
        _notify();
      }
    }
  }

  Future<void> verifyMfa(String requestId, String code) async {
    final challenge = _challenge;
    if (_busy || challenge == null || !_validIdentity) return;
    final epoch = _epoch;
    _busy = true;
    _notify();
    try {
      final verification = await repository.verifyMfa(challenge, code);
      if (!_current(epoch)) return;
      final proof = verification.proof;
      if (proof == null || verification.requiresMfa) {
        throw const RevelationFailure();
      }
      _challenge = null;
      await _open(requestId, proof, epoch);
    } catch (_) {
      if (_current(epoch)) await _fail();
    } finally {
      if (_current(epoch)) {
        _busy = false;
        _notify();
      }
    }
  }

  Future<void> _open(String requestId, String proof, int epoch) async {
    final started = _elapsed;
    final session = await repository.open(resource, requestId, proof);
    if (!_current(epoch)) {
      unawaited(repository.close(resource, session).catchError((_) {}));
      return;
    }
    _session = session;
    _copyAllowed = session.allowsCodeCopy;
    _boundAuthorization(session.serverTime, session.expiresAt, started);
    checkDeadlines();
  }

  Future<void> reveal(String kind, {bool copy = false}) async {
    final session = _session;
    if (_busy || session == null || !_validIdentity) return;
    if ((kind == 'CREDENTIAL' && !canRevealCredential) ||
        (kind == 'TOTP' && !canRevealTotp)) {
      return;
    }
    if (copy && !canCopy) return;
    final epoch = _epoch;
    final started = _elapsed;
    _busy = true;
    error = null;
    _value = null;
    _notify();
    try {
      await _clearCopied();
      if (!_current(epoch)) return;
      final result = await repository.reveal(
        resource,
        session,
        kind,
        copy: copy,
      );
      if (!_current(epoch)) return;
      if (result.kind != kind || (kind == 'TOTP' && result.code == null)) {
        throw const RevelationFailure();
      }
      _boundAuthorization(result.serverTime, result.expiresAt, started);
      _valueDeadline =
          started + result.revealUntil.difference(result.serverTime);
      if (_authorizationDeadline! < _valueDeadline!) {
        _valueDeadline = _authorizationDeadline;
      }
      _valueWall = _now().add(
        result.revealUntil.difference(result.serverTime) - (_elapsed - started),
      );
      if (_authorizationWall!.isBefore(_valueWall!)) {
        _valueWall = _authorizationWall;
      }
      if (kind == 'TOTP') {
        _copyAllowed = _copyAllowed && result.allowsCodeCopy;
      }
      _value = result;
      checkDeadlines();
      if (copy && _value != null && canCopy) {
        final code = result.code!;
        await clipboard.write(code);
        if (!_current(epoch) || _value == null) {
          await _clearClipboardIf(code);
        } else {
          _copied = code;
        }
      }
    } catch (_) {
      if (_current(epoch)) await _fail();
    } finally {
      if (_current(epoch)) {
        _busy = false;
        _notify();
      }
    }
  }

  Future<void> refreshStatus() async {
    final session = _session;
    if (_checking || session == null || !_validIdentity) return;
    final epoch = _epoch;
    final started = _elapsed;
    _checking = true;
    try {
      final status = await repository.status(resource, session);
      if (!_current(epoch)) return;
      _boundAuthorization(status.serverTime, status.expiresAt, started);
      _copyAllowed = _copyAllowed && status.allowsCodeCopy;
      if (!status.allowsCodeCopy && _value?.kind == 'TOTP') {
        await _clearCopied();
      }
      checkDeadlines();
      _notify();
    } catch (_) {
      if (_current(epoch)) await _fail();
    } finally {
      if (epoch == _epoch) _checking = false;
    }
  }

  void checkDeadlines() {
    if (_disposed) return;
    if (!_validIdentity) {
      if (!_lostSession) {
        _lostSession = true;
        unawaited(hide());
        onSessionLost?.call();
      }
      return;
    }
    if (_authorizationDeadline != null &&
        (_elapsed >= _authorizationDeadline! ||
            !_now().isBefore(_authorizationWall!))) {
      unawaited(hide());
      return;
    }
    if (_valueDeadline != null &&
        (_elapsed >= _valueDeadline! || !_now().isBefore(_valueWall!))) {
      _value = null;
      _valueDeadline = null;
      _valueWall = null;
      unawaited(_clearCopied());
      _notify();
    }
    final seconds = secondsLeft;
    if (seconds != _lastSeconds) {
      _lastSeconds = seconds;
      _notify();
    }
  }

  Future<void> _fail() async {
    await hide();
    error =
        'A visualização foi encerrada. Confira a autorização ou tente novamente.';
    _notify();
  }

  Future<void> _clearClipboardIf(String value) async {
    try {
      if (await clipboard.read() == value) await clipboard.clear();
    } catch (_) {}
  }

  Future<void> _clearCopied() async {
    final value = _copied;
    _copied = null;
    if (value != null) await _clearClipboardIf(value);
  }

  Future<void> hide() async {
    ++_epoch;
    final session = _session;
    _session = null;
    _value = null;
    _challenge = null;
    _busy = false;
    _checking = false;
    _copyAllowed = false;
    _authorizationDeadline = null;
    _valueDeadline = null;
    _authorizationWall = null;
    _valueWall = null;
    _notify();
    await _clearCopied();
    if (session != null) {
      try {
        await repository.close(resource, session);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _timer?.cancel();
    _poll?.cancel();
    unawaited(hide());
    _disposed = true;
    _clock.stop();
    super.dispose();
  }
}
