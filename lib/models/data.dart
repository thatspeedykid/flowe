import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// ── Colors ────────────────────────────────────────────────────────────────────
class FloColors {
  static const bg       = Color(0xFF0f0f0f);
  static const surface  = Color(0xFF1a1a1a);
  static const surface2 = Color(0xFF222222);
  static const border   = Color(0xFF2e2e2e);
  static const accent   = Color(0xFFc8f560);
  static const accent2  = Color(0xFFf56060);
  static const text     = Color(0xFFe8e8e8);
  static const muted    = Color(0xFF777777);
  static const green    = Color(0xFF60f5a0);
  static const blue     = Color(0xFF60c8f5);
  static const orange   = Color(0xFFf5a060);
  static const purple   = Color(0xFFc060f5);
}

// ── Data Models ───────────────────────────────────────────────────────────────

class BudgetRow {
  String label;
  double amount;
  String tag;
  BudgetRow({required this.label, required this.amount, this.tag = ''});

  Map<String, dynamic> toJson() => {'label': label, 'amount': amount, 'tag': tag};
  factory BudgetRow.fromJson(Map<String, dynamic> j) =>
      BudgetRow(label: j['label'] ?? '', amount: (j['amount'] ?? 0).toDouble(), tag: j['tag'] ?? '');
}

class BudgetSection {
  String name;
  List<BudgetRow> rows;
  BudgetSection({required this.name, required this.rows});
  double get total => rows.fold(0.0, (s, r) => s + r.amount);

  Map<String, dynamic> toJson() => {'name': name, 'rows': rows.map((r) => r.toJson()).toList()};
  factory BudgetSection.fromJson(Map<String, dynamic> j) => BudgetSection(
    name: j['name'] ?? j['title'] ?? '',
    rows: (j['rows'] as List? ?? []).map((r) => BudgetRow.fromJson(r)).toList(),
  );
}

class MonthBudget {
  List<BudgetSection> income;
  List<BudgetSection> expense;
  MonthBudget({required this.income, required this.expense});

  double get totalIncome  => income.fold(0.0, (s, sec) => s + sec.total);
  double get totalExpense => expense.fold(0.0, (s, sec) => s + sec.total);
  double get remaining    => totalIncome - totalExpense;

  Map<String, dynamic> toJson() => {
    'income':  income.map((s) => s.toJson()).toList(),
    'expense': expense.map((s) => s.toJson()).toList(),
  };

  factory MonthBudget.fromJson(dynamic raw) {
    // New Flutter format: {income: [...], expense: [...]}
    if (raw is Map && raw.containsKey('income')) {
      return MonthBudget(
        income:  (raw['income']  as List? ?? []).map((s) => BudgetSection.fromJson(s)).toList(),
        expense: (raw['expense'] as List? ?? []).map((s) => BudgetSection.fromJson(s)).toList(),
      );
    }
    // Old HTML/Windows format: flat array of sections, first = income rest = expense
    if (raw is List) {
      final sections = raw.map((s) => BudgetSection.fromJson(s as Map<String, dynamic>)).toList();
      final income  = sections.isNotEmpty ? [sections.first] : <BudgetSection>[];
      final expense = sections.length > 1  ? sections.sublist(1) : <BudgetSection>[];
      return MonthBudget(income: income, expense: expense);
    }
    return MonthBudget(income: [], expense: []);
  }
}

class Debt {
  String id;
  String name;
  String last4;
  double balance;
  double minPayment;
  double apr;
  String type;
  double origBalance;
  String dueDate;
  Debt({String? id, required this.name, this.last4 = '', required this.balance, required this.minPayment,
        required this.apr, required this.type, this.origBalance = 0, this.dueDate = ''})
    : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'last4': last4, 'balance': balance, 'origBalance': origBalance,
    'minPayment': minPayment, 'apr': apr, 'type': type, 'dueDate': dueDate,
  };
  factory Debt.fromJson(Map<String, dynamic> j) => Debt(
    id: j['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
    name: j['name'] ?? '',
    last4: j['last4'] ?? '',
    balance: (j['balance'] ?? 0).toDouble(),
    origBalance: (j['origBalance'] ?? j['balance'] ?? 0).toDouble(),
    minPayment: (j['minPayment'] ?? j['minPmt'] ?? 0).toDouble(),
    apr: (j['apr'] ?? 0).toDouble(),
    type: _mapDebtType(j['type'] ?? 'card'),
    dueDate: j['dueDate'] ?? '',
  );

  static String _mapDebtType(String t) {
    if (t == 'cc') return 'card';
    if (['card','loan','medical','other'].contains(t)) return t;
    return 'other';
  }
}

class NWItem {
  String name;
  double amount;
  NWItem({required this.name, required this.amount});
  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
  factory NWItem.fromJson(Map<String, dynamic> j) =>
      NWItem(name: j['name'] ?? j['label'] ?? '', amount: (j['amount'] ?? 0).toDouble());
}

class NWSnapshot {
  String date;
  double netWorth;
  NWSnapshot({required this.date, required this.netWorth});
  Map<String, dynamic> toJson() => {'date': date, 'netWorth': netWorth};
  factory NWSnapshot.fromJson(Map<String, dynamic> j) =>
      NWSnapshot(date: j['date'] ?? '', netWorth: (j['netWorth'] ?? j['net'] ?? 0).toDouble());
}

class EventItem {
  String label;
  double amount;
  bool   paid;
  EventItem({required this.label, required this.amount, this.paid = false});
  Map<String, dynamic> toJson() => {'label': label, 'amount': amount, 'paid': paid};
  factory EventItem.fromJson(Map<String, dynamic> j) =>
      EventItem(label: j['label'] ?? '', amount: (j['amount'] ?? 0).toDouble(), paid: j['paid'] ?? false);
}

class EventCategory {
  String name;
  List<EventItem> items;
  EventCategory({required this.name, required this.items});
  double get total => items.fold(0.0, (s, i) => s + i.amount);
  Map<String, dynamic> toJson() => {'name': name, 'items': items.map((i) => i.toJson()).toList()};
  factory EventCategory.fromJson(Map<String, dynamic> j) => EventCategory(
    name: j['name'] ?? '',
    items: (j['items'] as List? ?? []).map((i) => EventItem.fromJson(i)).toList(),
  );
}

class Event {
  String name;
  double cap;
  double splitTotal; // persisted split calculator total (0 = use event total)
  List<EventCategory> categories;
  List<Map<String, dynamic>> splitPeople;
  Event({required this.name, required this.cap, required this.categories,
         List<Map<String,dynamic>>? splitPeople, this.splitTotal = 0})
    : splitPeople = splitPeople ?? [];
  double get total => categories.fold(0.0, (s, c) => s + c.total);
  Map<String, dynamic> toJson() => {
    'name': name, 'cap': cap, 'splitTotal': splitTotal,
    'categories': categories.map((c) => c.toJson()).toList(),
    'splitPeople': splitPeople,
  };
  factory Event.fromJson(Map<String, dynamic> j) => Event(
    name: j['name'] ?? '',
    cap: (j['cap'] ?? 0).toDouble(),
    splitTotal: (j['splitTotal'] ?? 0).toDouble(),
    categories: (j['categories'] as List? ?? []).map((c) => EventCategory.fromJson(c)).toList(),
    splitPeople: (j['splitPeople'] as List? ?? []).map((p) => Map<String,dynamic>.from(p)).toList(),
  );
}

// ── Root Data ─────────────────────────────────────────────────────────────────
// ── Transaction (Track tab) ───────────────────────────────────────────────────
class Transaction {
  String id;
  String date;       // ISO8601 date string e.g. "2025-03-07"
  String category;   // must match a budget category name
  String note;
  double amount;
  String cardLast4;  // optional last 4 digits of card used
  Transaction({required this.id, required this.date, required this.category,
               required this.note, required this.amount, this.cardLast4 = ''});

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date, 'category': category, 'note': note, 'amount': amount,
    'cardLast4': cardLast4,
  };
  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
    id:       j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    date:     j['date'] ?? '',
    category: j['category'] ?? '',
    note:     j['note'] ?? '',
    amount:   (j['amount'] ?? 0).toDouble(),
    cardLast4: j['cardLast4'] ?? '',
  );
}

class FloData {
  Map<String, MonthBudget> budgets;
  List<Debt>        debts;
  double            extraPayment;
  List<NWItem>      assets;
  List<NWItem>      liabilities;
  List<NWSnapshot>  snapshots;
  List<Event>       events;
  List<Transaction> transactions;
  bool              darkMode;
  double            fontSize;

  FloData({required this.budgets, required this.debts, required this.extraPayment,
           required this.assets, required this.liabilities, required this.snapshots,
           required this.events, List<Transaction>? transactions,
           required this.darkMode, this.fontSize = 15.0})
    : transactions = transactions ?? [];

  factory FloData.empty() => FloData(budgets: {}, debts: [], extraPayment: 0,
    assets: [], liabilities: [], snapshots: [], events: [], transactions: [], darkMode: false);

  Map<String, dynamic> toJson() => {
    'budgets':      budgets.map((k, v) => MapEntry(k, v.toJson())),
    'debts':        debts.map((d) => d.toJson()).toList(),
    'extraPayment': extraPayment,
    'assets':       assets.map((a) => a.toJson()).toList(),
    'liabilities':  liabilities.map((l) => l.toJson()).toList(),
    'snapshots':    snapshots.map((s) => s.toJson()).toList(),
    'events':       events.map((e) => e.toJson()).toList(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'darkMode':     darkMode,
    'fontSize':     fontSize,
  };

  factory FloData.fromJson(Map<String, dynamic> j) {
    // Handle both Flutter format AND old HTML/Windows format
    List<Debt> debts = [];
    if (j['debts'] != null) {
      debts = (j['debts'] as List).map((d) => Debt.fromJson(d)).toList();
    } else if (j['snowball'] != null && j['snowball']['debts'] != null) {
      // Old HTML format: snowball.debts
      debts = (j['snowball']['debts'] as List).map((d) => Debt.fromJson(d)).toList();
    }

    List<NWItem> assets = [];
    List<NWItem> liabilities = [];
    List<NWSnapshot> snapshots = [];
    if (j['assets'] != null) {
      assets      = (j['assets']      as List).map((a) => NWItem.fromJson(a)).toList();
      liabilities = (j['liabilities'] as List? ?? []).map((l) => NWItem.fromJson(l)).toList();
      snapshots   = (j['snapshots']   as List? ?? []).map((s) => NWSnapshot.fromJson(s)).toList();
    } else if (j['networth'] != null) {
      // Old HTML format: networth.assets / networth.liabilities / networth.snapshots
      final nw = j['networth'] as Map<String, dynamic>;
      assets      = (nw['assets']      as List? ?? []).map((a) => NWItem.fromJson(a)).toList();
      liabilities = (nw['liabilities'] as List? ?? []).map((l) => NWItem.fromJson(l)).toList();
      snapshots   = (nw['snapshots']   as List? ?? []).map((s) => NWSnapshot.fromJson(s)).toList();
    }

    // Parse budgets — values could be old flat-array or new income/expense format
    final budgets = <String, MonthBudget>{};
    if (j['budgets'] != null) {
      (j['budgets'] as Map<String, dynamic>).forEach((k, v) {
        budgets[k] = MonthBudget.fromJson(v);
      });
    }

    return FloData(
      budgets:      budgets,
      debts:        debts,
      extraPayment: (j['extraPayment'] ?? j['extra'] ?? 0).toDouble(),
      assets:       assets,
      liabilities:  liabilities,
      snapshots:    snapshots,
      events:       (j['events'] as List? ?? []).map((e) => Event.fromJson(e)).toList(),
      transactions: (j['transactions'] as List? ?? []).map((t) => Transaction.fromJson(t)).toList(),
      darkMode:     j['darkMode'] ?? false,
      fontSize:     (j['fontSize'] ?? 15.0).toDouble(),
    );
  }
}

// ── Storage ───────────────────────────────────────────────────────────────────
class FloStorage {
  static Future<File> _getFile() async {
    final appDir = await getApplicationSupportDirectory();
    final file = File('${appDir.path}/data.json');
    if (!await file.exists()) {
      await file.parent.create(recursive: true);

      // ── Migration priority list (checked in order) ────────────────────────
      // 1. Android: old com.example.flowe package data directory
      // 2. iOS:     old com.example.flowe app support directory (same UUID-based
      //             path but accessed via known sibling container path pattern)
      // 3. Desktop: old HTML/flo app paths (legacy v1.x)
      final legacyPaths = <String>[];

      if (Platform.isAndroid) {
        // Android stores app files at /data/user/0/<packageId>/files/
        // The new package is com.privacychase.flowe — look for old com.example.flowe
        legacyPaths.addAll([
          '/data/user/0/com.example.flowe/files/data.json',
          '/data/data/com.example.flowe/files/data.json', // Android < 5 path
        ]);
      } else if (Platform.isIOS) {
        // iOS: UUIDs differ per install but we can check a shared app group
        // or the known relative sibling path. Since we can't predict the UUID,
        // the safest migration for iOS is via the FLOWE backup clipboard flow.
        // Nothing to do automatically here — handled gracefully below.
      } else {
        // Desktop: old HTML flo app (v1.x) paths
        legacyPaths.addAll([
          '${Platform.environment['HOME'] ?? ''}/.local/share/flo/data.json',
          '${Platform.environment['APPDATA'] ?? ''}/flo/data.json',
          // Also try old flutter app name if it was ever 'flo'
          '${Platform.environment['HOME'] ?? ''}/.local/share/flo/flo/data.json',
          '${Platform.environment['APPDATA'] ?? ''}/flo/flo/data.json',
        ]);
      }

      for (final p in legacyPaths) {
        if (p.isEmpty) continue;
        final legacy = File(p);
        if (await legacy.exists()) {
          try {
            await legacy.copy(file.path);
            break; // migrated — stop checking
          } catch (_) {}
        }
      }
    }
    return file;
  }

  static Future<FloData> load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        return FloData.fromJson(jsonDecode(await file.readAsString()));
      }
    } catch (_) {}
    return FloData.empty();
  }

  static Future<void> save(FloData data) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(data.toJson()));
  }
}
