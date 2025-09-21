import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/diagnostic_item.dart';

class ItemBankService {
  static final ItemBankService _instance = ItemBankService._internal();
  factory ItemBankService() => _instance;
  ItemBankService._internal();

  List<DiagnosticItem> _itemBank = [];

  // Load items from assets
  Future<void> initializeItemBank() async {
    if (_itemBank.isNotEmpty) {
      print(
          'DEBUG: Item bank already initialized with ${_itemBank.length} items');
      return;
    }

    print('DEBUG: Starting item bank initialization...');
    try {
      print('DEBUG: Loading CAT items...');
      // Load CAT items
      final catItemsJson =
          await rootBundle.loadString('assets/data/cat_items.json');
      print('DEBUG: CAT JSON loaded, parsing...');
      final catItems = jsonDecode(catItemsJson)['items'] as List;
      print('DEBUG: Found ${catItems.length} CAT items in JSON');
      _itemBank.addAll(catItems.map((item) {
        print('DEBUG: Processing CAT item: ${item['itemId']}');
        return DiagnosticItem.fromMap(item);
      }).toList());
      print('DEBUG: Loaded ${catItems.length} CAT items into bank');

      print('DEBUG: Loading SJT items...');
      // Load SJT items
      final sjtItemsJson =
          await rootBundle.loadString('assets/data/sjt_items.json');
      print('DEBUG: SJT JSON loaded, parsing...');
      final sjtItems = jsonDecode(sjtItemsJson)['items'] as List;
      print('DEBUG: Found ${sjtItems.length} SJT items in JSON');
      _itemBank.addAll(sjtItems.map((item) {
        print('DEBUG: Processing SJT item: ${item['itemId']}');
        return DiagnosticItem.fromMap(item);
      }).toList());
      print('DEBUG: Loaded ${sjtItems.length} SJT items into bank');

      print('DEBUG: Loading Voice items...');
      // Load voice task items
      final voiceItemsJson =
          await rootBundle.loadString('assets/data/voice_items.json');
      print('DEBUG: Voice JSON loaded, parsing...');
      final voiceItems = jsonDecode(voiceItemsJson)['items'] as List;
      print('DEBUG: Found ${voiceItems.length} Voice items in JSON');
      _itemBank.addAll(voiceItems.map((item) {
        print('DEBUG: Processing Voice item: ${item['itemId']}');
        return DiagnosticItem.fromMap(item);
      }).toList());
      print('DEBUG: Loaded ${voiceItems.length} Voice items into bank');

      print('DEBUG: Total loaded ${_itemBank.length} items into item bank');
    } catch (e) {
      print('ERROR: Item bank loading failed: $e');
      print('ERROR: Details: ${e.toString()}');
      print('ERROR: Stack trace: ${StackTrace.current}');
      // Create fallback items if loading fails
      _createFallbackItems();
      print('DEBUG: Fallback items created, total items: ${_itemBank.length}');
    }

    print('DEBUG: Item bank initialization complete');
  }

  void _createFallbackItems() {
    print('Creating fallback items due to loading error');
    // Create minimal fallback items for testing
    _itemBank.addAll([
      DiagnosticItem(
        itemId: 'fallback_cat_001',
        category: 'general',
        type: ItemType.cat,
        content: {
          'question': 'What is 2 + 2?',
          'options': ['A. 4', 'B. 3', 'C. 5', 'D. 6']
        },
        parameters: {'a': 1.0, 'b': 0.0, 'c': 0.25},
        difficulty: 0.0,
        discrimination: 1.0,
        correctResponses: ['A'],
        distractors: ['B', 'C', 'D'],
        metadata: {'topic': 'fallback'},
        active: true,
        createdAt: DateTime.now(),
        authorId: 'system',
      ),
    ]);
    print('Created ${_itemBank.length} fallback items');
  }

  // Get items by type and category
  List<DiagnosticItem> getItemsByCategory(ItemType type, String category) {
    return _itemBank
        .where((item) =>
            item.type == type && item.category == category && item.active)
        .toList();
  }

  // Get all active items of a specific type
  List<DiagnosticItem> getItemsByType(ItemType type) {
    return _itemBank.where((item) => item.type == type && item.active).toList();
  }

  // Select next item using Fisher Information (CAT adaptive selection)
  DiagnosticItem? selectNextItem(
      List<String> answeredItems, double currentTheta, ItemType type) {
    final availableItems = _itemBank
        .where((item) =>
            item.type == type &&
            !answeredItems.contains(item.itemId) &&
            item.active)
        .toList();

    print('Selecting next item for type $type:');
    print('Total items in bank: ${_itemBank.length}');
    print('Filtered items by type $type: ${availableItems.length}');
    print('Answered items: $answeredItems');

    if (availableItems.isEmpty) {
      print('No available items found for type $type');
      return null;
    }

    // Find item with maximum Fisher information at current theta
    DiagnosticItem? bestItem;
    double maxInfo = -double.infinity;

    for (var item in availableItems) {
      final info = item.fisherInformation(currentTheta);
      print('Item ${item.itemId}: Fisher info = ${info.toStringAsFixed(3)}');
      if (info > maxInfo) {
        maxInfo = info;
        bestItem = item;
      }
    }

    if (bestItem != null) {
      print(
          'Selected item: ${bestItem.itemId} with Fisher info: ${maxInfo.toStringAsFixed(3)}');
    } else {
      // Fallback: if no best item found (unlikely), select first available item
      print(
          'No best item found despite available items, using first available item as fallback');
      bestItem = availableItems.first;
    }

    return bestItem;
  }

  // Get item banks statistics
  Map<String, dynamic> getItemBankStats() {
    final stats = <String, Map<String, int>>{};
    final typeCounts = <ItemType, int>{};
    final categoryCounts = <String, int>{};

    for (var item in _itemBank) {
      // Type stats
      typeCounts[item.type] = (typeCounts[item.type] ?? 0) + 1;

      // Category stats
      categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
    }

    return {
      'totalItems': _itemBank.length,
      'types':
          typeCounts.map((k, v) => MapEntry(k.toString().split('.').last, v)),
      'categories': categoryCounts,
      'activeItems': _itemBank.where((item) => item.active).length,
    };
  }

  // Add a single item to the bank (for dynamic generation)
  void addItem(DiagnosticItem item) {
    // Check if item already exists
    final existingIndex = _itemBank.indexWhere((i) => i.itemId == item.itemId);
    if (existingIndex >= 0) {
      _itemBank[existingIndex] = item;
    } else {
      _itemBank.add(item);
    }
  }

  // Add multiple items to the bank
  void addItems(List<DiagnosticItem> items) {
    for (var item in items) {
      addItem(item);
    }
  }

  // Create sample item bank for testing
  Future<void> createSampleItems() async {
    // This will be called to generate initial item data files if they don't exist
    print('Creating sample item banks...');
  }
}
