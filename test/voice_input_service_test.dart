import 'package:flutter_test/flutter_test.dart';
import 'package:splitsync/services/voice_input_service.dart';

void main() {
  group('VoiceInputService parseSpokenText Category Recognition Tests', () {
    test('Recognizes explicit category names', () {
      expect(VoiceInputService.parseSpokenText('Paid 500 for travel').category, 'Travel');
      expect(VoiceInputService.parseSpokenText('Paid 1000 for shopping').category, 'Shopping');
      expect(VoiceInputService.parseSpokenText('Paid 300 for entertainment').category, 'Entertainment');
      expect(VoiceInputService.parseSpokenText('Paid 450 for food').category, 'Food');
      expect(VoiceInputService.parseSpokenText('Paid 600 for groceries').category, 'Groceries');
      expect(VoiceInputService.parseSpokenText('Paid 800 for fuel').category, 'Fuel & Transport');
      expect(VoiceInputService.parseSpokenText('Paid 1500 for bills').category, 'Bills & Utilities');
      expect(VoiceInputService.parseSpokenText('Paid 200 for healthcare').category, 'Healthcare');
    });

    test('Recognizes rich synonyms for categories', () {
      // Travel
      expect(VoiceInputService.parseSpokenText('Paid 1200 for flight tickets').category, 'Travel');
      expect(VoiceInputService.parseSpokenText('Paid 250 for uber cab').category, 'Travel');
      expect(VoiceInputService.parseSpokenText('Paid 300 for train trip').category, 'Travel');

      // Shopping
      expect(VoiceInputService.parseSpokenText('Paid 2000 for clothes at Zara').category, 'Shopping');
      expect(VoiceInputService.parseSpokenText('Paid 1500 for shoes').category, 'Shopping');

      // Entertainment
      expect(VoiceInputService.parseSpokenText('Paid 400 for movie tickets').category, 'Entertainment');
      expect(VoiceInputService.parseSpokenText('Paid 600 for cinema and bowling').category, 'Entertainment');
      expect(VoiceInputService.parseSpokenText('Paid 199 for netflix').category, 'Entertainment');

      // Healthcare
      expect(VoiceInputService.parseSpokenText('Paid 350 for medicine at pharmacy').category, 'Healthcare');
      expect(VoiceInputService.parseSpokenText('Paid 500 for doctor consultation').category, 'Healthcare');

      // Fuel & Transport
      expect(VoiceInputService.parseSpokenText('Paid 500 for petrol').category, 'Fuel & Transport');
      expect(VoiceInputService.parseSpokenText('Paid 1000 for diesel at gas station').category, 'Fuel & Transport');

      // Groceries
      expect(VoiceInputService.parseSpokenText('Paid 300 for milk and vegetables').category, 'Groceries');
      expect(VoiceInputService.parseSpokenText('Paid 800 at supermarket').category, 'Groceries');

      // Bills & Utilities
      expect(VoiceInputService.parseSpokenText('Paid 900 for wifi bill').category, 'Bills & Utilities');
      expect(VoiceInputService.parseSpokenText('Paid 1200 for electricity').category, 'Bills & Utilities');
    });
  });
}
