import 'package:speech_to_text/speech_to_text.dart';

class VoiceExpenseResult {
  final double amount;
  final String title;
  final String category;
  final String spokenText;
  final String payerName;
  final List<String> memberNames;
  final String splitMethod;

  VoiceExpenseResult({
    required this.amount,
    required this.title,
    required this.category,
    required this.spokenText,
    this.payerName = '',
    this.memberNames = const [],
    this.splitMethod = 'equal',
  });
}

class VoiceInputService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  Function()? _onListeningComplete;
  Function(String message)? _onError;

  Future<bool> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _onListeningComplete?.call();
          }
        },
        onError: (error) {
          _onError?.call(error.errorMsg);
          _onListeningComplete?.call();
        },
      );
    }
    return _isInitialized;
  }

  Future<bool> listen({
    required Function(String text) onResult,
    required Function() onListeningComplete,
    required Function(String message) onError,
  }) async {
    _onListeningComplete = onListeningComplete;
    _onError = onError;
    final ready = await initialize();
    if (!ready) {
      onError('Microphone or speech recognition is unavailable. Please allow microphone access and try again.');
      onListeningComplete();
      return false;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            onListeningComplete();
          }
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
        ),
      );
      return true;
    } catch (_) {
      onError('Unable to start voice input. Please try again.');
      onListeningComplete();
      return false;
    }
  }

  Future<void> stop() async {
    await _speechToText.stop();
  }

  /// Parses natural spoken sentence into Expense details.
  /// Example: "Paid 450 rupees for lunch at Pizza Hut" -> amount: 450, title: "Lunch at Pizza Hut", category: "Food"
  static VoiceExpenseResult parseSpokenText(
    String text, {
    Iterable<String> knownMemberNames = const [],
  }) {
    double amount = 0.0;
    String category = 'Other';
    String title = text.trim();
    String payerName = '';
    String splitMethod = 'equal';
    final lower = text.toLowerCase();

    // 1. Extract amount using numbers pattern
    final numberRegex = RegExp(r'(\d+(?:\.\d{1,2})?)');
    final match = numberRegex.firstMatch(text);
    if (match != null) {
      amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }

    // 2. Infer Category
    category = _inferCategoryFromSpokenText(text);

    if (lower.contains('percentage')) {
      splitMethod = 'percentage';
    } else if (lower.contains('exact split') || lower.contains('split exact')) {
      splitMethod = 'exact';
    } else if (lower.contains('custom split')) {
      splitMethod = 'custom';
    }

    final payerPatterns = [
      RegExp(r'\bpaid by\s+([a-z]+(?:\s+[a-z]+)?)', caseSensitive: false),
      RegExp(r'\bpayer(?:\s+is)?\s+([a-z]+(?:\s+[a-z]+)?)', caseSensitive: false),
      RegExp(r'\b([a-z]+(?:\s+[a-z]+)?)\s+paid\b', caseSensitive: false),
    ];
    for (final pattern in payerPatterns) {
      final payerMatch = pattern.firstMatch(text);
      if (payerMatch != null) {
        payerName = (payerMatch.group(1) ?? '').trim();
        break;
      }
    }

    final memberNames = knownMemberNames
        .where((name) => name.trim().isNotEmpty && RegExp('\\b${RegExp.escape(name.trim())}\\b', caseSensitive: false).hasMatch(text))
        .toList();

    // Clean title
    title = title
        .replaceAll(RegExp(r'\b(paid|for|rupees|rs|dollars|\d+)\b', caseSensitive: false), '')
        .trim();

    return VoiceExpenseResult(
      amount: amount,
      title: title,
      category: category,
      spokenText: text,
      payerName: payerName,
      memberNames: memberNames,
      splitMethod: splitMethod,
    );
  }

  static String _inferCategoryFromSpokenText(String text) {
    final lower = ' ${text.toLowerCase()} ';

    // 1. Direct explicit category name check & strong matches
    if (RegExp(r'\b(?:travel|travels|travelling|traveling|trip|tour)\b').hasMatch(lower)) {
      return 'Travel';
    }
    if (RegExp(r'\b(?:shopping|shop|clothes|clothing|dress|shoes|sneakers|apparel|zara|h&m|mall)\b').hasMatch(lower)) {
      return 'Shopping';
    }
    if (RegExp(r'\b(?:entertainment|entertain|movie|movies|cinema|theatre|theater|film|netflix|spotify|concert|bowling|game|gaming|party|show)\b').hasMatch(lower)) {
      return 'Entertainment';
    }
    if (RegExp(r'\b(?:food|lunch|dinner|breakfast|brunch|snack|snacks|pizza|burger|coffee|tea|cafe|café|restaurant|meal|meals|bakery|dessert|dine|swiggy|zomato|kfc|mcdonalds)\b').hasMatch(lower)) {
      return 'Food';
    }
    if (RegExp(r'\b(?:groceries|grocery|supermarket|vegetables|veggies|fruits|fruit|milk|bread|eggs|provisions|kirana|zepto|blinkit|instamart|bigbasket)\b').hasMatch(lower)) {
      return 'Groceries';
    }
    if (RegExp(r'\b(?:fuel|petrol|diesel|gas|cng|refuel|gas station|petrol pump)\b').hasMatch(lower)) {
      return 'Fuel & Transport';
    }
    if (RegExp(r'\b(?:healthcare|health|medicine|medicines|medical|pharmacy|pharma|doctor|hospital|clinic|tablets|pills|chemist|dentist|consultation)\b').hasMatch(lower)) {
      return 'Healthcare';
    }
    if (RegExp(r'\b(?:bills|bill|utilities|utility|electricity|electric|power|current|water bill|wifi|internet|broadband|recharge|rent|maintenance|dth)\b').hasMatch(lower)) {
      return 'Bills & Utilities';
    }

    // 2. Travel & Transit synonyms (flight, cab, uber, ola, train, bus, hotel, stay, metro)
    if (RegExp(r'\b(?:flight|plane|airline|airport|train|railway|irctc|bus|cab|taxi|uber|ola|auto|metro|hotel|resort|airbnb|stay|vacation|toll)\b').hasMatch(lower)) {
      return 'Travel';
    }

    // 3. Transport synonyms that fit Fuel & Transport
    if (RegExp(r'\b(?:transport|transportation|parking|ev charging)\b').hasMatch(lower)) {
      return 'Fuel & Transport';
    }

    return 'Other';
  }
}
