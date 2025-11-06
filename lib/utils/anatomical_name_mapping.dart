/// Centralized anatomical name mapping utility
/// Provides consistent mapping from measurement keys to display names
/// for carcass measurements and anatomical parts across the application.
///
// ignore_for_file: dangling_library_doc_comments

class AnatomicalNameMapping {
  /// Private constructor for singleton pattern
  AnatomicalNameMapping._();

  /// Singleton instance
  static final AnatomicalNameMapping _instance = AnatomicalNameMapping._();

  /// Factory constructor to return the singleton instance
  factory AnatomicalNameMapping() => _instance;

  /// Comprehensive mapping from measurement keys to display names
  /// Keys are the measurement field names (e.g., 'torso_weight', 'front_legs_weight')
  /// Values are the human-readable display names (e.g., 'Torso', 'Front Legs')
  static const Map<String, String> _measurementToDisplayName = {
    // Core carcass measurements
    'head_weight': 'Head',
    'torso_weight': 'Torso',
    'front_legs_weight': 'Front Legs',
    'hind_legs_weight': 'Hind Legs',
    'feet_weight': 'Feet',
    'organs_weight': 'Organs',

    // Additional anatomical parts
    'neck': 'Neck',
    'shoulder': 'Shoulder',
    'loin': 'Loin',
    'leg': 'Leg',
    'breast': 'Breast',
    'ribs': 'Ribs',
    'flank': 'Flank',
    'belly': 'Belly',
    'back': 'Back',
    'tail': 'Tail',
    'hide': 'Hide',
    'skin': 'Skin',
    'hooves': 'Hooves',
    'wings': 'Wings',
    'thighs': 'Thighs',
    'drumsticks': 'Drumsticks',

    // Internal organs
    'liver': 'Liver',
    'heart': 'Heart',
    'kidneys': 'Kidneys',
    'lungs': 'Lungs',
    'intestines': 'Intestines',
    'stomach': 'Stomach',
    'tongue': 'Tongue',
    'brain': 'Brain',

    // Special measurements
    'total_carcass': 'Total Carcass',
    'total_weight': 'Total Weight',
    'live_weight': 'Live Weight',
  };

  /// Get the display name for a measurement key
  /// Returns the human-readable name if found, otherwise formats the key
  String getDisplayName(String measurementKey) {
    // First check if we have a direct mapping
    if (_measurementToDisplayName.containsKey(measurementKey)) {
      return _measurementToDisplayName[measurementKey]!;
    }

    // Handle keys with '_weight' suffix by removing it and checking again
    if (measurementKey.endsWith('_weight')) {
      final baseKey = measurementKey.replaceAll('_weight', '');
      if (_measurementToDisplayName.containsKey(baseKey)) {
        return _measurementToDisplayName[baseKey]!;
      }
    }

    // Fallback: format the key by replacing underscores and capitalizing
    return _formatKeyAsDisplayName(measurementKey);
  }

  /// Get all available measurement keys
  List<String> getAllMeasurementKeys() {
    return _measurementToDisplayName.keys.toList();
  }

  /// Get all display names
  List<String> getAllDisplayNames() {
    return _measurementToDisplayName.values.toList();
  }

  /// Check if a measurement key is supported
  bool isMeasurementKeySupported(String measurementKey) {
    return _measurementToDisplayName.containsKey(measurementKey) ||
           _measurementToDisplayName.containsKey(measurementKey.replaceAll('_weight', ''));
  }

  /// Get the measurement key from a display name (reverse lookup)
  /// Returns null if not found
  String? getMeasurementKeyFromDisplayName(String displayName) {
    for (final entry in _measurementToDisplayName.entries) {
      if (entry.value == displayName) {
        return entry.key;
      }
    }
    return null;
  }

  /// Format a measurement key as a display name when no mapping exists
  /// Converts snake_case to Title Case with spaces
  String _formatKeyAsDisplayName(String key) {
    // Remove '_weight' suffix if present
    var formattedKey = key.replaceAll('_weight', '');

    // Replace underscores with spaces
    formattedKey = formattedKey.replaceAll('_', ' ');

    // Capitalize each word
    formattedKey = formattedKey.split(' ')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');

    return formattedKey;
  }

  /// Get display names for a list of measurement keys
  List<String> getDisplayNames(List<String> measurementKeys) {
    return measurementKeys.map(getDisplayName).toList();
  }

  /// Get a map of measurement keys to display names for a list of keys
  Map<String, String> getDisplayNameMap(List<String> measurementKeys) {
    return Map.fromEntries(
      measurementKeys.map((key) => MapEntry(key, getDisplayName(key)))
    );
  }
}