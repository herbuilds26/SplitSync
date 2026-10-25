import 'package:flutter/material.dart';

/// 💡 Template for one-tap expense creation tailored to a group category
class QuickExpenseTemplate {
  final String title;
  final String category;
  final IconData icon;

  const QuickExpenseTemplate({
    required this.title,
    required this.category,
    required this.icon,
  });
}

/// 🏷️ Rich configuration and features for Group Categories (Trip, Home, Couple, Other)
class GroupCategoryInfo {
  final String id;
  final String name;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> featureHighlights;
  final List<QuickExpenseTemplate> quickTemplates;

  const GroupCategoryInfo({
    required this.id,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.featureHighlights,
    required this.quickTemplates,
  });
}

class GroupCategories {
  static const GroupCategoryInfo trip = GroupCategoryInfo(
    id: 'Trip',
    name: 'Trip',
    title: 'Trip & Vacation',
    subtitle: 'Flights, hotels, cabs, gas, sightseeing & group meals on getaways',
    icon: Icons.flight_takeoff_rounded,
    color: Color(0xFF29B6F6), // Sky Blue
    featureHighlights: [
      '✈️ Flights & Tickets',
      '🏨 Stays & Hotels',
      '🚗 Fuel & Cabs',
      '🍽️ Group Meals',
      '🎟️ Sightseeing & Fun',
    ],
    quickTemplates: [
      QuickExpenseTemplate(title: 'Flight / Train Tickets', category: 'Travel', icon: Icons.flight_rounded),
      QuickExpenseTemplate(title: 'Hotel / Resort Stay', category: 'Travel', icon: Icons.hotel_rounded),
      QuickExpenseTemplate(title: 'Fuel & Tolls', category: 'Fuel & Transport', icon: Icons.local_gas_station_rounded),
      QuickExpenseTemplate(title: 'Group Dinner', category: 'Food', icon: Icons.restaurant_rounded),
      QuickExpenseTemplate(title: 'Sightseeing & Activities', category: 'Entertainment', icon: Icons.confirmation_number_rounded),
      QuickExpenseTemplate(title: 'Cab & Local Transport', category: 'Fuel & Transport', icon: Icons.local_taxi_rounded),
    ],
  );

  static const GroupCategoryInfo home = GroupCategoryInfo(
    id: 'Home',
    name: 'Home',
    title: 'Home & Flatmates',
    subtitle: 'Rent, electricity, Wi-Fi, pantry groceries, water & house supplies',
    icon: Icons.cottage_rounded,
    color: Color(0xFF26A69A), // Mint Teal
    featureHighlights: [
      '🏠 Monthly Rent',
      '⚡ Power & Utilities',
      '📶 Wi-Fi & Internet',
      '🛒 Pantry & Groceries',
      '🧹 House Maintenance',
    ],
    quickTemplates: [
      QuickExpenseTemplate(title: 'House Rent', category: 'Bills & Utilities', icon: Icons.house_rounded),
      QuickExpenseTemplate(title: 'Electricity Bill', category: 'Bills & Utilities', icon: Icons.bolt_rounded),
      QuickExpenseTemplate(title: 'Wi-Fi & Internet', category: 'Bills & Utilities', icon: Icons.wifi_rounded),
      QuickExpenseTemplate(title: 'Groceries & Supplies', category: 'Groceries', icon: Icons.local_grocery_store_rounded),
      QuickExpenseTemplate(title: 'Water Bill / Tanker', category: 'Bills & Utilities', icon: Icons.water_drop_rounded),
      QuickExpenseTemplate(title: 'House Maid / Cook', category: 'Bills & Utilities', icon: Icons.cleaning_services_rounded),
    ],
  );

  static const GroupCategoryInfo couple = GroupCategoryInfo(
    id: 'Couple',
    name: 'Couple',
    title: 'Couple & Partners',
    subtitle: 'Date nights, romantic dinners, movies, gifts & shared subscriptions',
    icon: Icons.favorite_rounded,
    color: Color(0xFFEC407A), // Rose Berry
    featureHighlights: [
      '🍷 Date Nights',
      '🍿 Movie Tickets',
      '🎁 Gifts & Surprises',
      '🛍️ Shared Shopping',
      '☕ Weekend Brunches',
    ],
    quickTemplates: [
      QuickExpenseTemplate(title: 'Dinner Date', category: 'Food', icon: Icons.wine_bar_rounded),
      QuickExpenseTemplate(title: 'Movie Tickets', category: 'Entertainment', icon: Icons.movie_rounded),
      QuickExpenseTemplate(title: 'Coffee & Brunch', category: 'Food', icon: Icons.coffee_rounded),
      QuickExpenseTemplate(title: 'Weekend Getaway', category: 'Travel', icon: Icons.beach_access_rounded),
      QuickExpenseTemplate(title: 'Gifts & Surprises', category: 'Shopping', icon: Icons.card_giftcard_rounded),
      QuickExpenseTemplate(title: 'Shared OTT Subscription', category: 'Bills & Utilities', icon: Icons.subscriptions_rounded),
    ],
  );

  static const GroupCategoryInfo other = GroupCategoryInfo(
    id: 'Other',
    name: 'Other',
    title: 'Custom Category',
    subtitle: 'Hackathons, festivals, weddings, sports clubs, office & personal projects',
    icon: Icons.dashboard_customize_rounded,
    color: Color(0xFFAB47BC), // Vibrant Violet
    featureHighlights: [
      '🎯 Project Budget',
      '🎪 Festival & Events',
      '🍕 Hangouts & Parties',
      '🛠️ Equipment & Gear',
      '🏆 Club Activities',
    ],
    quickTemplates: [
      QuickExpenseTemplate(title: 'Project Equipment', category: 'Shopping', icon: Icons.build_rounded),
      QuickExpenseTemplate(title: 'Event Passes / Tickets', category: 'Entertainment', icon: Icons.event_rounded),
      QuickExpenseTemplate(title: 'Party Snacks & Drinks', category: 'Food', icon: Icons.fastfood_rounded),
      QuickExpenseTemplate(title: 'Supplies & Materials', category: 'Bills & Utilities', icon: Icons.inventory_2_rounded),
      QuickExpenseTemplate(title: 'Team Lunch', category: 'Food', icon: Icons.celebration_rounded),
    ],
  );

  /// Available base categories
  static const List<GroupCategoryInfo> all = [trip, home, couple, other];

  /// Common presets for custom 'Other' categories
  static const List<String> customCategorySuggestions = [
    'Festival',
    'Project',
    'Sports Club',
    'Office Team',
    'Wedding',
    'Hackathon',
    'Party',
    'College / Study',
    'Gaming',
  ];

  /// Icons available to select for custom categories
  static const List<Map<String, dynamic>> customIconOptions = [
    {'name': 'Festival', 'icon': Icons.festival_rounded},
    {'name': 'Project', 'icon': Icons.laptop_chromebook_rounded},
    {'name': 'Party', 'icon': Icons.celebration_rounded},
    {'name': 'Sports', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Fitness', 'icon': Icons.fitness_center_rounded},
    {'name': 'Art & Creative', 'icon': Icons.palette_rounded},
    {'name': 'Study', 'icon': Icons.school_rounded},
    {'name': 'Hangout', 'icon': Icons.local_cafe_rounded},
    {'name': 'Event', 'icon': Icons.event_available_rounded},
  ];

  /// Resolves any group category string into a rich GroupCategoryInfo
  static GroupCategoryInfo getCategory(String categoryName) {
    final trimmed = categoryName.trim();
    final lower = trimmed.toLowerCase();

    if (lower == 'trip') return trip;
    if (lower == 'home') return home;
    if (lower == 'couple') return couple;
    if (lower == 'other' || trimmed.isEmpty) return other;

    // Custom named category
    return GroupCategoryInfo(
      id: trimmed,
      name: trimmed,
      title: trimmed,
      subtitle: 'Custom group expenses for $trimmed',
      icon: Icons.dashboard_customize_rounded,
      color: const Color(0xFFAB47BC),
      featureHighlights: [
        '✨ $trimmed Expenses',
        '📊 Equal & Custom Splits',
        '⚡ Fast Group Sync',
      ],
      quickTemplates: other.quickTemplates,
    );
  }
}
