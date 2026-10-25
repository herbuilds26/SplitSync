import 'package:flutter/material.dart';

class AppConstants {
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'icon': Icons.restaurant_rounded, 'color': Color(0xFFFF7043)},
    {'name': 'Travel', 'icon': Icons.flight_rounded, 'color': Color(0xFF42A5F5)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFFAB47BC)},
    {'name': 'Entertainment', 'icon': Icons.movie_rounded, 'color': Color(0xFFEC407A)},
    {'name': 'Bills & Utilities', 'icon': Icons.receipt_long_rounded, 'color': Color(0xFF26A69A)},
    {'name': 'Groceries', 'icon': Icons.local_grocery_store_rounded, 'color': Color(0xFF66BB6A)},
    {'name': 'Fuel & Transport', 'icon': Icons.local_gas_station_rounded, 'color': Color(0xFFFFA726)},
    {'name': 'Healthcare', 'icon': Icons.medical_services_rounded, 'color': Color(0xFFEF5350)},
    {'name': 'Other', 'icon': Icons.more_horiz_rounded, 'color': Color(0xFF78909C)},
  ];

  static const List<Map<String, String>> currencies = [
    {'code': 'INR', 'symbol': '₹', 'name': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'AED', 'symbol': 'AED ', 'name': 'UAE Dirham'},
  ];

  static Map<String, dynamic> getCategory(String categoryName) {
    return categories.firstWhere(
      (cat) => cat['name'].toString().toLowerCase() == categoryName.toLowerCase(),
      orElse: () => categories.last,
    );
  }
}
