import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for running initialization tasks in background isolates
class InitializationHelper {
  static const String _isolateName = 'background_initializer';

  /// Runs a heavy initialization task in a background isolate
  static Future<T> runInBackground<T>(
    Future<T> Function() task, {
    String? debugLabel,
  }) async {
    if (!kReleaseMode) {
      debugPrint('🔄 Running ${debugLabel ?? 'task'} in background isolate');
    }

    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _isolateEntry,
      _IsolateMessage(
        task: task,
        sendPort: receivePort.sendPort,
        debugLabel: debugLabel,
      ),
      debugName: debugLabel ?? _isolateName,
    );

    final completer = Completer<T>();
    receivePort.listen((message) {
      if (message is _IsolateResult<T>) {
        if (message.error != null) {
          completer.completeError(message.error!);
        } else {
          completer.complete(message.result);
        }
        receivePort.close();
        isolate.kill();
      }
    });

    return completer.future;
  }

  /// Entry point for background isolate
  static void _isolateEntry(_IsolateMessage message) async {
    try {
      final result = await message.task();
      message.sendPort.send(_IsolateResult(result: result));
    } catch (error) {
      message.sendPort.send(_IsolateResult(error: error));
    }
  }

  /// Initializes SharedPreferences in background
  static Future<SharedPreferences> initSharedPreferences() {
    return runInBackground(
      () => SharedPreferences.getInstance(),
      debugLabel: 'SharedPreferences initialization',
    );
  }

  /// Initializes multiple SharedPreferences instances efficiently
  static Future<Map<String, SharedPreferences>> initMultipleSharedPreferences(
    List<String> keys,
  ) {
    return runInBackground(() async {
      final prefs = <String, SharedPreferences>{};
      final instance = await SharedPreferences.getInstance();
      for (final key in keys) {
        prefs[key] = instance;
      }
      return prefs;
    }, debugLabel: 'Multiple SharedPreferences initialization');
  }
}

/// Message sent to isolate
class _IsolateMessage {
  final Future Function() task;
  final SendPort sendPort;
  final String? debugLabel;

  _IsolateMessage({
    required this.task,
    required this.sendPort,
    this.debugLabel,
  });
}

/// Result from isolate
class _IsolateResult<T> {
  final T? result;
  final Object? error;

  _IsolateResult({this.result, this.error});
}

/// Lazy initialization wrapper for providers
class LazyInitializer<T> {
  final Future<T> Function() _initializer;
  Completer<T>? _completer;
  bool _isInitialized = false;

  LazyInitializer(this._initializer);

  /// Gets the initialized value, initializing if necessary
  Future<T> get value async {
    if (_isInitialized && _completer != null) {
      return _completer!.future;
    }

    _completer ??= Completer<T>();
    if (!_isInitialized) {
      _isInitialized = true;
      try {
        final result = await _initializer();
        _completer!.complete(result);
      } catch (error) {
        _completer!.completeError(error);
        _completer = null; // Reset for retry
        _isInitialized = false;
        rethrow;
      }
    }

    return _completer!.future;
  }

  /// Checks if initialization is complete
  bool get isInitialized => _isInitialized && _completer?.isCompleted == true;

  /// Gets the current initialization progress (0.0 to 1.0)
  double get progress {
    if (!_isInitialized) return 0.0;
    if (_completer?.isCompleted == true) return 1.0;
    return 0.5; // In progress
  }

  /// Resets the initializer for re-initialization
  void reset() {
    _completer = null;
    _isInitialized = false;
  }
}