import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/config/group_categories.dart';

void main() {
  group('GroupCategories Tests', () {
    test('standard categories (Trip, Home, Couple, Other) are well-configured', () {
      expect(GroupCategories.all.length, 4);

      final trip = GroupCategories.getCategory('Trip');
      expect(trip.name, 'Trip');
      expect(trip.icon, Icons.flight_takeoff_rounded);
      expect(trip.featureHighlights.isNotEmpty, true);
      expect(trip.quickTemplates.isNotEmpty, true);

      final home = GroupCategories.getCategory('Home');
      expect(home.name, 'Home');
      expect(home.icon, Icons.cottage_rounded);
      expect(home.featureHighlights.isNotEmpty, true);
      expect(home.quickTemplates.isNotEmpty, true);

      final couple = GroupCategories.getCategory('Couple');
      expect(couple.name, 'Couple');
      expect(couple.icon, Icons.favorite_rounded);
      expect(couple.featureHighlights.isNotEmpty, true);
      expect(couple.quickTemplates.isNotEmpty, true);

      final other = GroupCategories.getCategory('Other');
      expect(other.name, 'Other');
      expect(other.icon, Icons.dashboard_customize_rounded);
      expect(other.featureHighlights.isNotEmpty, true);
      expect(other.quickTemplates.isNotEmpty, true);
    });

    test('case-insensitivity works for standard categories', () {
      final tripLower = GroupCategories.getCategory('trip');
      expect(tripLower.name, 'Trip');

      final homeUpper = GroupCategories.getCategory('HOME');
      expect(homeUpper.name, 'Home');

      final coupleMixed = GroupCategories.getCategory('CoUpLe');
      expect(coupleMixed.name, 'Couple');
    });

    test('custom category returns custom GroupCategoryInfo with fallback properties', () {
      final custom = GroupCategories.getCategory('Hackathon 2026');
      expect(custom.id, 'Hackathon 2026');
      expect(custom.name, 'Hackathon 2026');
      expect(custom.title, 'Hackathon 2026');
      expect(custom.featureHighlights.isNotEmpty, true);
      expect(custom.quickTemplates.isNotEmpty, true);
    });

    test('customCategorySuggestions contains curated presets', () {
      expect(GroupCategories.customCategorySuggestions.contains('Hackathon'), true);
      expect(GroupCategories.customCategorySuggestions.contains('Project'), true);
      expect(GroupCategories.customCategorySuggestions.contains('Festival'), true);
      expect(GroupCategories.customCategorySuggestions.contains('Party'), true);
    });
  });
}
