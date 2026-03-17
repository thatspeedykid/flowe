import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/data.dart';

class TrackScreen extends StatefulWidget {
  final FloData data;
  final ValueChanged<FloData> onChanged;
  const TrackScreen({super.key, required this.data, required this.onChanged});
  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  late FloData _data;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  void didUpdateWidget(TrackScreen old) {
    super.didUpdateWidget(old);
    _data = widget.data;
  }

  bool get dark      => _data.darkMode;
  Color get accent   => dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
  Color get accent2  => dark ? const Color(0xFFf56060) : const Color(0xFFc0392b);
  Color get surface  => dark ? const Color(0xFF1a1a1a) : Colors.white;
  Color get surface2 => dark ? const Color(0xFF222222) : const Color(0xFFeeebe2);
  Color get border   => dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);
  Color get txt      => dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17);
  Color get muted    => dark ? const Color(0xFF777777) : const Color(0xFF7a7060);
  Color get green    => dark ? const Color(0xFF60f5a0) : const Color(0xFF1a7a40);

  String get _monthKey =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  void _prevMonth() => setState(() =>
      _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime(DateTime.now().year, DateTime.now().month))) {
      setState(() => _month = next);
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  String get _monthLabel {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[_month.month - 1]} ${_month.year}';
  }

  List<Transaction> get _monthTxns {
    final list = _data.transactions
        .where((t) => t.date.startsWith(_monthKey))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get _totalBudgeted {
    final mb = _data.budgets[_monthKey];
    if (mb == null) return 0;
    return mb.expense.fold(0.0, (s, sec) =>
        s + sec.rows.fold(0.0, (ss, r) => ss + r.amount));
  }

  double get _totalLogged =>
      _monthTxns.fold(0.0, (s, t) => s + t.amount);

  List<String> _categories() {
    final mb = _data.budgets[_monthKey];
    if (mb == null) return [];
    return mb.expense
        .expand((sec) => sec.rows)
        .where((r) => r.label.trim().isNotEmpty)
        .map((r) => r.label.trim())
        .toList();
  }

  Map<String, List<Transaction>> get _grouped {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final result    = <String, List<Transaction>>{};
    for (final t in _monthTxns) {
      final d   = DateTime.tryParse(t.date) ?? today;
      final day = DateTime(d.year, d.month, d.day);
      String label;
      if (day == today)          label = 'Today';
      else if (day == yesterday) label = 'Yesterday';
      else {
        const mn = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
        label = '${mn[d.month-1]} ${d.day}';
      }
      (result[label] ??= []).add(t);
    }
    return result;
  }

  void _saveWithTxns(List<Transaction> txns) {
    final u = FloData(
      budgets: _data.budgets, debts: _data.debts,
      extraPayment: _data.extraPayment, assets: _data.assets,
      liabilities: _data.liabilities, snapshots: _data.snapshots,
      events: _data.events, transactions: txns,
      darkMode: _data.darkMode, fontSize: _data.fontSize,
    );
    setState(() => _data = u);
    widget.onChanged(u);
  }

  Future<void> _showDialog([Transaction? editing]) async {
    final cats = _categories();
    final allCats = {
      ...cats,
      if (editing != null && editing.category.isNotEmpty) editing.category,
    }.toList();

    String selectedCat   = editing?.category ?? (allCats.isNotEmpty ? allCats.first : '');
    String selectedCard  = editing?.cardLast4 ?? '';
    final amtCtrl  = TextEditingController(
        text: editing != null ? editing.amount.toStringAsFixed(2) : '');
    final noteCtrl = TextEditingController(text: editing?.note ?? '');
    final cardOptions = _data.debts
        .where((d) => d.last4.isNotEmpty)
        .map((d) => (label: '${d.name} ···${d.last4}', last4: d.last4))
        .toList();
    DateTime selectedDate = editing != null
        ? DateTime.tryParse(editing.date) ?? DateTime.now()
        : DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(editing == null ? 'Log Transaction' : 'Edit Transaction',
                  style: GoogleFonts.dmMono(
                      color: txt, fontSize: 16, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (editing != null)
                GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    final txns = List<Transaction>.from(_data.transactions)
                      ..removeWhere((t) => t.id == editing.id);
                    _saveWithTxns(txns);
                  },
                  child: Icon(Icons.delete_outline, color: accent2, size: 20)),
            ]),
            const SizedBox(height: 20),

            if (allCats.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text('Add expense categories to your budget first.',
                    style: GoogleFonts.dmMono(color: muted, fontSize: 12)))
            else ...[
              Text('Category', style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
              const SizedBox(height: 6),
              _dropdown<String>(
                value: allCats.contains(selectedCat) ? selectedCat : allCats.first,
                items: allCats.map((c) =>
                    DropdownMenuItem(value: c, child: Text(c,
                        style: GoogleFonts.dmMono(color: txt, fontSize: 14)))).toList(),
                onChanged: (v) => setModal(() => selectedCat = v ?? selectedCat),
              ),
              const SizedBox(height: 14),
            ],

            Text('Amount', style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
            const SizedBox(height: 6),
            _inputField(amtCtrl,
                prefix: r'$ ',
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                fmt: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]),
            const SizedBox(height: 14),

            if (cardOptions.isNotEmpty) ...[
              Text('Card (optional)', style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
              const SizedBox(height: 6),
              _dropdown<String>(
                value: cardOptions.any((c) => c.last4 == selectedCard) ? selectedCard : '',
                items: [
                  DropdownMenuItem(value: '',
                      child: Text('— none —',
                          style: GoogleFonts.dmMono(color: muted, fontSize: 14))),
                  ...cardOptions.map((c) => DropdownMenuItem(value: c.last4,
                      child: Text(c.label,
                          style: GoogleFonts.dmMono(color: txt, fontSize: 14)))),
                ],
                onChanged: (v) => setModal(() => selectedCard = v ?? ''),
              ),
              const SizedBox(height: 14),
            ],

            Text('Note (optional)', style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
            const SizedBox(height: 6),
            _inputField(noteCtrl, hint: 'e.g. groceries run'),
            const SizedBox(height: 14),

            Text('Date', style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                      colorScheme: dark
                          ? ColorScheme.dark(primary: accent, surface: surface)
                          : ColorScheme.light(primary: accent)),
                    child: child!));
                if (picked != null) setModal(() => selectedDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                decoration: BoxDecoration(color: surface2,
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.calendar_today_outlined, color: muted, size: 15),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}',
                    style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
                onPressed: () {
                  final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
                  if (amt <= 0) return;
                  final dateStr =
                      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}';
                  final cat = selectedCat.isEmpty
                      ? (allCats.isNotEmpty ? allCats.first : '') : selectedCat;
                  final txns = List<Transaction>.from(_data.transactions);
                  if (editing != null) {
                    final idx = txns.indexWhere((t) => t.id == editing.id);
                    if (idx >= 0) txns[idx] = Transaction(
                        id: editing.id, date: dateStr, category: cat,
                        note: noteCtrl.text.trim(), amount: amt,
                        cardLast4: selectedCard);
                  } else {
                    txns.add(Transaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: dateStr, category: cat,
                      note: noteCtrl.text.trim(), amount: amt,
                      cardLast4: selectedCard));
                  }
                  _saveWithTxns(txns);
                  Navigator.pop(ctx);
                },
                child: Text(editing == null ? 'Log It' : 'Save',
                    style: GoogleFonts.dmMono(
                        color: dark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8), color: surface2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value, isExpanded: true, dropdownColor: surface,
            style: GoogleFonts.dmMono(color: txt, fontSize: 14),
            items: items, onChanged: onChanged),
        ),
      );

  Widget _inputField(TextEditingController ctrl,
      {String? hint, String? prefix,
       TextInputType? keyboard, List<TextInputFormatter>? fmt}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        inputFormatters: fmt,
        style: GoogleFonts.dmMono(color: txt, fontSize: 15),
        cursorColor: accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmMono(color: muted, fontSize: 13),
          prefixText: prefix,
          prefixStyle: GoogleFonts.dmMono(color: muted),
          filled: true, fillColor: surface2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: accent)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final grouped  = _grouped;
    final budgeted = _totalBudgeted;
    final logged   = _totalLogged;
    final pct      = budgeted > 0 ? (logged / budgeted).clamp(0.0, 1.0) : 0.0;
    final over     = budgeted > 0 && logged > budgeted;
    final remaining = budgeted - logged;

    return Column(children: [
      // Month nav
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: surface2,
            border: Border(bottom: BorderSide(color: border))),
        child: Row(children: [
          GestureDetector(onTap: _prevMonth,
              child: Icon(Icons.chevron_left, color: muted, size: 22)),
          const Spacer(),
          Text(_monthLabel, style: GoogleFonts.dmMono(
              color: txt, fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: _isCurrentMonth ? null : _nextMonth,
            child: Icon(Icons.chevron_right,
                color: _isCurrentMonth ? border : muted, size: 22)),
        ]),
      ),

      Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: surface,
                  border: Border.all(
                      color: over ? accent2.withOpacity(0.4) : border),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text('SPENDING', style: GoogleFonts.dmMono(
                      color: muted, fontSize: 10, letterSpacing: 1.5)),
                  const Spacer(),
                  if (over)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: accent2.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('OVER BUDGET', style: GoogleFonts.dmMono(
                          color: accent2, fontSize: 9, letterSpacing: 1)),
                    ),
                ]),
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('\$${logged.toStringAsFixed(2)}',
                      style: GoogleFonts.dmMono(
                          color: over ? accent2 : txt,
                          fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      budgeted > 0
                          ? 'of \$${budgeted.toStringAsFixed(2)} budgeted'
                          : 'logged this month',
                      style: GoogleFonts.dmMono(color: muted, fontSize: 12)),
                  ),
                ]),
                if (budgeted > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct, minHeight: 5,
                      backgroundColor: border,
                      valueColor: AlwaysStoppedAnimation(
                          over ? accent2 : accent)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    over
                        ? '\$${(-remaining).toStringAsFixed(2)} over budget'
                        : '\$${remaining.toStringAsFixed(2)} remaining',
                    style: GoogleFonts.dmMono(
                        color: over ? accent2 : green, fontSize: 11)),
                ],
              ]),
            ),
            const SizedBox(height: 20),

            // Header + log button
            Row(children: [
              Text('TRANSACTIONS', style: GoogleFonts.dmMono(
                  color: muted, fontSize: 10, letterSpacing: 1.5)),
              const Spacer(),
              GestureDetector(
                onTap: _showDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 14,
                        color: dark ? Colors.black : Colors.white),
                    const SizedBox(width: 4),
                    Text('Log', style: GoogleFonts.dmMono(
                        color: dark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // List
            if (grouped.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(children: [
                    Icon(Icons.receipt_long_outlined, color: border, size: 40),
                    const SizedBox(height: 12),
                    Text('No transactions in $_monthLabel',
                        style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("Tap 'Log' to record spending",
                        style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
                  ]),
                ),
              )
            else
              ...grouped.entries.expand((entry) => [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, top: 2),
                  child: Text(entry.key, style: GoogleFonts.dmMono(
                      color: muted, fontSize: 10, letterSpacing: 1)),
                ),
                ...entry.value.map((t) => _txnRow(t)),
                const SizedBox(height: 8),
              ]),
          ]),
        ),
      ),
    ]);
  }

  Widget _txnRow(Transaction t) {
    return Dismissible(
      key: ValueKey('txn_${t.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
            color: accent2.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        child: Icon(Icons.delete_outline, color: accent2, size: 20),
      ),
      onDismissed: (_) {
        final txns = List<Transaction>.from(_data.transactions)
          ..removeWhere((x) => x.id == t.id);
        _saveWithTxns(txns);
      },
      child: GestureDetector(
        onTap: () => _showDialog(t),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border)),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(5)),
              child: Text(t.category.isEmpty ? '—' : t.category,
                  style: GoogleFonts.dmMono(color: accent, fontSize: 10)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(t.note.isEmpty ? '—' : t.note,
                  style: GoogleFonts.dmMono(color: txt, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
            if (t.cardLast4.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text('···${t.cardLast4}',
                  style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
            ],
            const SizedBox(width: 10),
            Text('\$${t.amount.toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(
                    color: txt, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
