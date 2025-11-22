import 'package:flutter/material.dart';

/// Definition of a domain (e.g., 'Health', 'Finance').
/// 
/// A domain defines a specific type of information that can be stored in the system.
/// It includes metadata like display name, icon, and validation logic.
class DomainDefinition {
  /// Unique identifier (e.g., 'health', 'finance')
  final String id;
  
  /// Display name (e.g., 'Health', 'Finance')
  final String name;
  
  /// Icon to represent this domain
  final IconData icon;
  
  /// Description of what this domain covers
  final String description;

  const DomainDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });
}

/// Registry for managing supported domains.
/// 
/// This singleton registry holds all registered domains in the system.
/// It allows looking up domain definitions by ID.
class DomainRegistry {
  static final DomainRegistry _instance = DomainRegistry._internal();
  
  factory DomainRegistry() => _instance;
  
  DomainRegistry._internal();
  
  final Map<String, DomainDefinition> _domains = {};
  
  /// Registers a new domain definition.
  /// Throws if a domain with the same ID is already registered.
  void register(DomainDefinition domain) {
    if (_domains.containsKey(domain.id)) {
      throw ArgumentError('Domain with id ${domain.id} is already registered');
    }
    _domains[domain.id] = domain;
  }
  
  /// Gets a domain definition by ID.
  /// Returns null if not found.
  DomainDefinition? get(String id) => _domains[id];
  
  /// Gets all registered domains.
  List<DomainDefinition> getAll() => _domains.values.toList();
  
  /// Checks if a domain is registered.
  bool has(String id) => _domains.containsKey(id);
  
  /// Unregisters a domain (mainly for testing).
  void unregister(String id) {
    _domains.remove(id);
  }
  
  /// Clears all registered domains (mainly for testing).
  void clear() {
    _domains.clear();
  }
}
