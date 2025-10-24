import 'package:flutter/material.dart';

/// MeatTrace Pro Design System - Custom Icons
/// Version 2.0 - Industry-specific icon set for livestock and meat traceability
class CustomIcons {
  CustomIcons._();

  // ========== APP BRANDING ICON ==========
  
  /// MeatTrace App Icon - Primary branding icon used throughout the application
  /// This icon represents the MeatTrace application identity and should be used
  /// for app logo, splash screens, login screens, and main navigation
  static const IconData MEATTRACE_ICON = Icons.qr_code_scanner;

  // ========== LIVESTOCK SPECIES ICONS ==========
  
  /// Cattle/Cow Icon (24x24)
  static const IconData cattle = Icons.pets;
  
  /// Pig Icon (24x24)
  static const IconData pig = Icons.pets;
  
  /// Chicken/Poultry Icon (24x24)
  static const IconData chicken = Icons.egg;
  
  /// Sheep Icon (24x24)
  static const IconData sheep = Icons.pets;
  
  /// Goat Icon (24x24)
  static const IconData goat = Icons.pets;
  
  // ========== MEAT PRODUCT ICONS ==========
  
  /// Steak Icon (24x24)
  static const IconData steak = Icons.restaurant;
  
  /// Ground Meat Icon (24x24)
  static const IconData groundMeat = Icons.restaurant;
  
  /// Sausage Icon (24x24)
  static const IconData sausage = Icons.restaurant;
  
  /// Ribs Icon (24x24)
  static const IconData ribs = Icons.restaurant;
  
  /// Chicken Parts Icon (24x24)
  static const IconData chickenParts = Icons.restaurant;
  
  // ========== PROCESS & FACILITY ICONS ==========
  
  /// Farm Icon (24x24)
  static const IconData farm = Icons.agriculture;
  
  /// Abattoir Icon (24x24)
  static const IconData abattoir = Icons.factory;
  
  /// Processing Unit Icon (24x24)
  static const IconData processingUnit = Icons.factory;
  
  /// Processing Plant Icon (Alias for processingUnit)
  static const IconData processingPlant = processingUnit;
  
  /// Shop/Retail Icon (24x24)
  static const IconData shop = Icons.store;
  
  /// Cold Storage Icon (24x24)
  static const IconData coldStorage = Icons.ac_unit;
  
  // ========== QUALITY & CERTIFICATION ICONS ==========
  
  /// Quality Badge Icon (24x24)
  static const IconData qualityBadge = Icons.verified;
  
  /// Certified Icon (24x24)
  static const IconData certified = Icons.verified;
  
  /// Organic Icon (24x24)
  static const IconData organic = Icons.eco;
  
  /// Halal Icon (24x24)
  static const IconData halal = Icons.food_bank;
  
  /// Grade A Icon (24x24)
  static const IconData gradeA = Icons.star;
  
  // ========== HEALTH & SAFETY ICONS ==========
  
  /// Health Check Icon (24x24)
  static const IconData healthCheck = Icons.health_and_safety;
  
  /// Vaccination Icon (24x24)
  static const IconData vaccination = Icons.medical_services;
  
  /// Temperature Control Icon (24x24)
  static const IconData temperature = Icons.thermostat;
  
  /// Hygiene Icon (24x24)
  static const IconData hygiene = Icons.clean_hands;
  
  /// Safety Seal Icon (24x24)
  static const IconData safetySeal = Icons.security;
  
  // ========== TRACEABILITY ICONS ==========
  
  /// QR Code Icon (24x24)
  static const IconData qrCode = Icons.qr_code_2;
  
  /// Barcode Icon (24x24)
  static const IconData barcode = Icons.qr_code;
  
  /// Tag Icon (24x24)
  static const IconData tag = Icons.label;
  
  /// Track Icon (24x24)
  static const IconData track = Icons.timeline;
  
  /// Timeline Icon (24x24)
  static const IconData timeline = Icons.timeline;
  
  // ========== LOGISTICS ICONS ==========
  
  /// Truck Icon (24x24)
  static const IconData truck = Icons.local_shipping;
  
  /// Transfer Icon (24x24)
  static const IconData transfer = Icons.swap_horiz;
  
  /// Package Icon (24x24)
  static const IconData package = Icons.inventory_2;
  
  /// Weight Scale Icon (24x24)
  static const IconData weightScale = Icons.scale;
  
  /// Box Icon (24x24)
  static const IconData box = Icons.inbox;
  
  // ========== ADDITIONAL ICONS (Aliases & Fallbacks) ==========
  
  /// QR Code Scan (fallback to Material Icons)
  static const IconData qrCodeScan = Icons.qr_code_scanner;
  
  /// Quality Grade (fallback)
  static const IconData qualityGrade = Icons.grade;
  
  /// Health Monitoring (fallback)
  static const IconData healthMonitoring = Icons.health_and_safety;
  
  /// Beef (alias for steak)
  static const IconData beef = steak;
  
  /// Pork (alias for pig)
  static const IconData pork = pig;
  
  /// Mutton (alias for sheep)
  static const IconData mutton = sheep;
  
  /// Meat Cut (fallback)
  static const IconData meatCut = Icons.cut;
  
  /// Processed Meat (alias for sausage)
  static const IconData processedMeat = sausage;

  /// Slaughter Icon (fallback)
  static const IconData slaughter = Icons.cut;
}

/// Helper method to get species icon by name
IconData getSpeciesIcon(String species) {
  switch (species.toLowerCase()) {
    case 'cattle':
    case 'cow':
    case 'bull':
      return CustomIcons.cattle;
    case 'pig':
    case 'swine':
      return CustomIcons.pig;
    case 'chicken':
    case 'poultry':
      return CustomIcons.chicken;
    case 'sheep':
      return CustomIcons.sheep;
    case 'goat':
      return CustomIcons.goat;
    default:
      return CustomIcons.cattle; // Default fallback
  }
}

/// Helper method to get species display name (for UI)
String getSpeciesDisplayName(String species) {
  switch (species.toLowerCase()) {
    case 'cow':
    case 'cattle':
    case 'bull':
      return 'Cattle';
    case 'pig':
    case 'swine':
      return 'Pig';
    case 'chicken':
    case 'poultry':
      return 'Chicken';
    case 'sheep':
      return 'Sheep';
    case 'goat':
      return 'Goat';
    default:
      return species.toUpperCase(); // Capitalize unknown species
  }
}

/// Helper method to get process/facility icon by role
IconData getRoleIcon(String role) {
  switch (role.toLowerCase()) {
    case 'farmer':
    case 'farm':
      return CustomIcons.farm;
    case 'abattoir':
      return CustomIcons.abattoir;
    case 'processing_unit':
    case 'processor':
      return CustomIcons.processingUnit;
    case 'shop':
    case 'retail':
      return CustomIcons.shop;
    default:
      return CustomIcons.farm;
  }
}

/// Material Design Icons fallback (until custom icons are implemented)
/// These use standard Material Icons as placeholders
class MeatTraceIconsFallback {
  static const cattle = Icons.pets; // Placeholder
  static const pig = Icons.pets; // Placeholder
  static const chicken = Icons.pets; // Placeholder
  static const sheep = Icons.pets; // Placeholder
  static const goat = Icons.pets; // Placeholder
  
  static const steak = Icons.restaurant; // Placeholder
  static const groundMeat = Icons.restaurant; // Placeholder
  static const sausage = Icons.restaurant; // Placeholder
  static const ribs = Icons.restaurant; // Placeholder
  static const chickenParts = Icons.restaurant; // Placeholder
  
  static const farm = Icons.agriculture; // Placeholder
  static const abattoir = Icons.factory; // Placeholder
  static const processingUnit = Icons.factory; // Placeholder
  static const shop = Icons.store; // Placeholder
  static const coldStorage = Icons.ac_unit; // Placeholder
  
  static const qualityBadge = Icons.verified; // Placeholder
  static const certified = Icons.verified; // Placeholder
  static const organic = Icons.eco; // Placeholder
  static const halal = Icons.food_bank; // Placeholder
  static const gradeA = Icons.star; // Placeholder
  
  static const healthCheck = Icons.health_and_safety; // Placeholder
  static const vaccination = Icons.medical_services; // Placeholder
  static const temperature = Icons.thermostat; // Placeholder
  static const hygiene = Icons.clean_hands; // Placeholder
  static const safetySeal = Icons.security; // Placeholder
  
  static const qrCode = Icons.qr_code_2; // Placeholder
  static const barcode = Icons.qr_code; // Placeholder
  static const tag = Icons.label; // Placeholder
  static const track = Icons.timeline; // Placeholder
  static const timeline = Icons.timeline; // Placeholder
  
  static const truck = Icons.local_shipping; // Placeholder
  static const transfer = Icons.swap_horiz; // Placeholder
  static const package = Icons.inventory_2; // Placeholder
  static const weightScale = Icons.scale; // Placeholder
  static const box = Icons.inbox; // Placeholder
}

// Helper methods for fallback icons
IconData getSpeciesIconFallback(String species) {
  switch (species.toLowerCase()) {
    case 'cattle':
    case 'cow':
    case 'bull':
      return MeatTraceIconsFallback.cattle;
    case 'pig':
    case 'swine':
      return MeatTraceIconsFallback.pig;
    case 'chicken':
    case 'poultry':
      return MeatTraceIconsFallback.chicken;
    case 'sheep':
      return MeatTraceIconsFallback.sheep;
    case 'goat':
      return MeatTraceIconsFallback.goat;
    default:
      return Icons.pets;
  }
}

IconData getRoleIconFallback(String role) {
  switch (role.toLowerCase()) {
    case 'farmer':
    case 'farm':
      return MeatTraceIconsFallback.farm;
    case 'abattoir':
      return MeatTraceIconsFallback.abattoir;
    case 'processing_unit':
    case 'processor':
      return MeatTraceIconsFallback.processingUnit;
    case 'shop':
    case 'retail':
      return MeatTraceIconsFallback.shop;
    default:
      return Icons.business;
  }
}
