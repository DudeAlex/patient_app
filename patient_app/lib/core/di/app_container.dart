typedef _Factory<T> = T Function(AppContainer container);

/// Minimal dependency container for the Patient App.
///
/// Supports singleton registrations and lazy singletons so we can replace
/// ad-hoc global factories with an explicit wiring layer.
class AppContainer {
  AppContainer._();

  static final AppContainer instance = AppContainer._();

  final Map<Type, Object?> _singletons = <Type, Object?>{};
  final Map<Type, _Factory<Object?>> _lazyFactories =
      <Type, _Factory<Object?>>{};

  /// Registers an already created singleton instance.
  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  /// Registers a lazy singleton factory that runs the first time the type is
  /// resolved.
  void registerLazySingleton<T>(T Function(AppContainer container) builder) {
    _lazyFactories[T] = builder as _Factory<Object?>;
  }

  /// Resolves a previously registered singleton or lazy singleton.
  T resolve<T>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }
    final _Factory<Object?>? builder = _lazyFactories[T];
    if (builder == null) {
      throw StateError('No registration for type $T.');
    }
    final Object? instance = builder(this);
    _singletons[T] = instance;
    _lazyFactories.remove(T);
    return instance as T;
  }

  /// Clears all registrations. Useful for tests.
  void reset() {
    _singletons.clear();
    _lazyFactories.clear();
  }
}
