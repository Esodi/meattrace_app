import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for running initialization tasks in background isolates
class InitializationHelper {
  static const String _isolateName = 'background_initializer';

  /// Runs a heavy initialization task in a background isolate
  static Future<T> runInBackground<T>(
    FutureOr<T> Function() task, {
    String? debugLabel,
  }) async {
    if (!kReleaseMode) {
      debugPrint('🔄 Running ${debugLabel ?? 'task'} in background isolate');
    }

    try {
      // Use Isolate.run for modern Flutter/Dart (simpler and supports closures)
      return await Isolate.run(task, debugName: debugLabel ?? _isolateName);
    } catch (e, stack) {
      debugPrint('❌ Error in background task ${debugLabel ?? ''}: $e');
      debugPrint(stack.toString());

      // Fallback: Try running in current isolate if Isolate.run fails
      // (e.g. if the closure captures non-sendable state)
      debugPrint('⚠️ Falling back to main isolate for ${debugLabel ?? ''}');
      return await task();
    }
  }

  /// Initializes SharedPreferences in background
  static Future<SharedPreferences> initSharedPreferences() {
    // Note: SharedPreferences.getInstance() internally uses the main isolate for
    // some operations on platform channels, but the heavy lifting is async/IO.
    return SharedPreferences.getInstance();
  }

  /// Initializes multiple SharedPreferences instances efficiently
  static Future<Map<String, SharedPreferences>> initMultipleSharedPreferences(
    List<String> keys,
  ) async {
    final prefs = <String, SharedPreferences>{};
    final instance = await SharedPreferences.getInstance();
    for (final key in keys) {
      prefs[key] = instance;
    }
    return prefs;
  }
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
