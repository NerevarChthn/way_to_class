class MultiKeyMap<K, V> {
  final Map<K, V> _map = {};

  final Map<V, Set<K>> _reverseMap = {};

  void add(V value, Iterable<K> keys) {
    for (var key in keys) {
      _map[key] = value;
      _reverseMap.putIfAbsent(value, () => {}).add(key);
    }
  }

  V? operator [](K key) => _map[key];

  Set<K>? keysForValue(V value) => _reverseMap[value];

  bool removeKey(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _reverseMap[value]?.remove(key);
      if (_reverseMap[value]?.isEmpty ?? false) {
        _reverseMap.remove(value);
      }
      return true;
    }
    return false;
  }
}
