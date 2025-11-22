import 'package:flutter/material.dart';
import '../../../core/domain/entities/space.dart';
import '../../../core/domain/value_objects/space_gradient.dart';

/// Registry of default space templates
/// 
/// Provides 8 pre-configured spaces covering common life areas.
/// Each space has a unique identity with icon, gradient, and categories.
class SpaceRegistry {
  /// Map of default space templates by ID
  static final Map<String, Space> _defaultSpaces = {
    'health': Space(
      id: 'health',
      name: 'Health',
      icon: 'Heart',
      gradient: SpaceGradient(
        startColor: Color(0xFFEF4444), // red-500
        endColor: Color(0xFFEC4899),   // pink-500
      ),
      description: 'Medical records, appointments, medications, and wellness',
      categories: [
        'Checkup',
        'Dental',
        'Vision',
        'Lab',
        'Medication',
        'Vaccine',
        'Therapy',
        'Other',
      ],
      isDefault: true,
    ),
    'education': Space(
      id: 'education',
      name: 'Education',
      icon: 'GraduationCap',
      gradient: SpaceGradient(
        startColor: Color(0xFF3B82F6), // blue-500
        endColor: Color(0xFF06B6D4),   // cyan-500
      ),
      description: 'Courses, notes, assignments, research, and learning materials',
      categories: [
        'Course',
        'Assignment',
        'Research',
        'Notes',
        'Project',
        'Reading',
        'Certification',
        'Other',
      ],
      isDefault: true,
    ),
    'home': Space(
      id: 'home',
      name: 'Home & Life',
      icon: 'Home',
      gradient: SpaceGradient(
        startColor: Color(0xFF10B981), // green-500
        endColor: Color(0xFF14B8A6),   // teal-500
      ),
      description: 'Recipes, DIY projects, maintenance, hobbies, and daily life',
      categories: [
        'Recipe',
        'DIY',
        'Maintenance',
        'Hobby',
        'Garden',
        'Pet',
        'Shopping',
        'Other',
      ],
      isDefault: true,
    ),
    'business': Space(
      id: 'business',
      name: 'Business',
      icon: 'Briefcase',
      gradient: SpaceGradient(
        startColor: Color(0xFF8B5CF6), // violet-500
        endColor: Color(0xFFA855F7),   // purple-500
      ),
      description: 'Meetings, contacts, contracts, ideas, and professional projects',
      categories: [
        'Meeting',
        'Contact',
        'Contract',
        'Idea',
        'Project',
        'Goal',
        'Review',
        'Other',
      ],
      isDefault: true,
    ),
    'finance': Space(
      id: 'finance',
      name: 'Finance',
      icon: 'DollarSign',
      gradient: SpaceGradient(
        startColor: Color(0xFFF59E0B), // amber-500
        endColor: Color(0xFFEAB308),   // yellow-500
      ),
      description: 'Expenses, income, investments, receipts, and budgets',
      categories: [
        'Expense',
        'Income',
        'Investment',
        'Receipt',
        'Bill',
        'Tax',
        'Budget',
        'Other',
      ],
      isDefault: true,
    ),
    'travel': Space(
      id: 'travel',
      name: 'Travel',
      icon: 'Plane',
      gradient: SpaceGradient(
        startColor: Color(0xFF06B6D4), // cyan-500
        endColor: Color(0xFF0EA5E9),   // sky-500
      ),
      description: 'Trips, bookings, itineraries, accommodations, and memories',
      categories: [
        'Trip',
        'Booking',
        'Itinerary',
        'Accommodation',
        'Activity',
        'Transport',
        'Memory',
        'Other',
      ],
      isDefault: true,
    ),
    'family': Space(
      id: 'family',
      name: 'Family',
      icon: 'Users',
      gradient: SpaceGradient(
        startColor: Color(0xFFF43F5E), // rose-500
        endColor: Color(0xFFEC4899),   // pink-500
      ),
      description: 'Events, milestones, memories, documents, and genealogy',
      categories: [
        'Event',
        'Milestone',
        'Memory',
        'Document',
        'Photo',
        'Genealogy',
        'Contact',
        'Other',
      ],
      isDefault: true,
    ),
    'creative': Space(
      id: 'creative',
      name: 'Creative',
      icon: 'Palette',
      gradient: SpaceGradient(
        startColor: Color(0xFFEC4899), // pink-500
        endColor: Color(0xFFA855F7),   // purple-500
      ),
      description: 'Art, writing, music, photography, design, and performances',
      categories: [
        'Art',
        'Writing',
        'Music',
        'Photography',
        'Design',
        'Craft',
        'Performance',
        'Other',
      ],
      isDefault: true,
    ),
  };

  /// Cached list of default spaces for performance optimization
  /// Initialized lazily on first access to avoid recreating the list on every call
  late final List<Space> _cachedDefaultSpaces = _defaultSpaces.values.toList();

  /// Gets a default space by ID
  /// Returns null if space ID doesn't exist
  Space? getDefaultSpace(String id) => _defaultSpaces[id];

  /// Gets all default spaces as a cached list
  /// Returns a cached immutable list to avoid recreating on every call
  List<Space> getAllDefaultSpaces() => _cachedDefaultSpaces;

  /// Checks if a space ID corresponds to a default space
  bool isDefaultSpace(String id) => _defaultSpaces.containsKey(id);

  /// Gets all default space IDs
  List<String> getAllDefaultSpaceIds() => _defaultSpaces.keys.toList();
}
