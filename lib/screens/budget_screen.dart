import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/data.dart';

class BudgetScreen extends StatefulWidget {
  final FloData data;
  final ValueChanged<FloData> onChanged;
  const BudgetScreen({super.key, required this.data, required this.onChanged});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late DateTime _month;
  late FloData _data;
  String? _toast;

  @override
  void initState() { super.initState(); _data = widget.data; _month = DateTime.now(); }
  @override
  void didUpdateWidget(BudgetScreen old) { super.didUpdateWidget(old); _data = widget.data; }

  String get _key => '${_month.year}-${_month.month.toString().padLeft(2,'0')}';

  MonthBudget get _budget => _data.budgets[_key] ?? MonthBudget(
    income:  [BudgetSection(name: 'INCOME',   rows: [BudgetRow(label: '', amount: 0)])],
    expense: [BudgetSection(name: 'EXPENSES', rows: [BudgetRow(label: '', amount: 0)])],
  );

  void _save(MonthBudget b) {
    final budgets = Map<String, MonthBudget>.from(_data.budgets);
    budgets[_key] = b;
    final u = FloData(budgets: budgets, debts: _data.debts, extraPayment: _data.extraPayment,
      assets: _data.assets, liabilities: _data.liabilities, snapshots: _data.snapshots,
      events: _data.events, darkMode: _data.darkMode, fontSize: _data.fontSize);
    setState(() => _data = u);
    widget.onChanged(u);
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _toast = null); });
  }

  Future<bool> _confirm(BuildContext ctx, String msg) async =>
    await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: surface,
        title: Text('Are you sure?', style: GoogleFonts.dmMono(color: txt)),
        content: Text(msg, style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false),
            child: Text('Cancel', style: GoogleFonts.dmMono(color: muted))),
          TextButton(onPressed: () => Navigator.pop(c, true),
            child: Text('Delete', style: GoogleFonts.dmMono(color: accent2))),
        ],
      ),
    ) ?? false;

  void _carryOver() {
    final prev = DateTime(_month.year, _month.month - 1);
    final prevKey = '${prev.year}-${prev.month.toString().padLeft(2,'0')}';
    final prevBudget = _data.budgets[prevKey];
    if (prevBudget == null) { _showToast('No data for last month'); return; }
    final copied = MonthBudget(
      income:  prevBudget.income.map((s) => BudgetSection(name: s.name,
        rows: s.rows.map((r) => BudgetRow(label: r.label, amount: r.amount, tag: r.tag)).toList())).toList(),
      expense: prevBudget.expense.map((s) => BudgetSection(name: s.name,
        rows: s.rows.map((r) => BudgetRow(label: r.label, amount: r.amount, tag: r.tag)).toList())).toList(),
    );
    _save(copied);
    _showToast('Carried over from last month!');
  }

  Future<void> _exportCSV() async {
    final b = _budget;
    final rows = ['Label,Amount,Type,Section'];
    for (final s in b.income)  for (final r in s.rows) rows.add('"${r.label}",${r.amount.toStringAsFixed(2)},Income,"${s.name}"');
    for (final s in b.expense) for (final r in s.rows) rows.add('"${r.label}",${r.amount.toStringAsFixed(2)},Expense,"${s.name}"');
    rows.add('"Total Income",${b.totalIncome.toStringAsFixed(2)},,');
    rows.add('"Total Expenses",${b.totalExpense.toStringAsFixed(2)},,');
    rows.add('"Remaining",${b.remaining.toStringAsFixed(2)},,');
    final csv = rows.join('\n');
    final filename = 'flowe_budget_$_key.csv';

    try {
      // All platforms: save to Downloads, then share on mobile/macOS
      String downloadsPath;
      if (Platform.isWindows) {
        downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
      } else if (Platform.isMacOS || Platform.isLinux) {
        downloadsPath = Platform.environment['XDG_DOWNLOAD_DIR'] ??
            '${Platform.environment['HOME']}/Downloads';
      } else {
        // iOS/Android: use temp dir then share
        final tmp = await getTemporaryDirectory();
        downloadsPath = tmp.path;
      }

      final dir = Directory(downloadsPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      final file = File('$downloadsPath/$filename');
      await file.writeAsString(csv);

      if (Platform.isIOS || Platform.isAndroid) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Flowe Budget — $_key',
        );
      } else if (Platform.isMacOS) {
        _showToast('Saved to Downloads/$filename');
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Flowe Budget — $_key',
        );
      } else {
        _showToast('Saved to Downloads/$filename');
      }
    } catch (e) {
      _showToast('Export failed: $e');
    }
  }

  void _copyToClipboard() {
    final b = _budget;
    final lines = ['flo Budget — $_key\n'];
    for (final s in b.income)  { lines.add(s.name); for (final r in s.rows) lines.add('  ${r.label}: \$${r.amount.toStringAsFixed(2)}'); lines.add(''); }
    for (final s in b.expense) { lines.add(s.name); for (final r in s.rows) lines.add('  ${r.label}: \$${r.amount.toStringAsFixed(2)}'); lines.add(''); }
    lines.add('Remaining: \$${b.remaining.toStringAsFixed(2)}');
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    _showToast('Copied to clipboard');
  }

  // ── Tag cycling ───────────────────────────────────────────────────────────
  static const _tags      = ['', 'debt', 'savings', 'income', 'other'];
  static const _tagLabel  = {'': 'type', 'debt': '💳 debt', 'savings': '🏦 save', 'income': '💰 income', 'other': '📦 other'};
  static const _tagColor  = {
    '':        Color(0xFF555555),
    'debt':    Color(0xFFf56060),
    'savings': Color(0xFF60f5a0),
    'income':  Color(0xFFc8f560),
    'other':   Color(0xFF60c8f5),
  };

  // ── Colors ────────────────────────────────────────────────────────────────
  bool   get dark     => _data.darkMode;
  Color  get accent   => dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
  Color  get accent2  => dark ? const Color(0xFFf56060) : const Color(0xFFc0392b);
  Color  get surface  => dark ? const Color(0xFF1a1a1a) : Colors.white;
  Color  get surface2 => dark ? const Color(0xFF222222) : const Color(0xFFeeebe2);
  Color  get border   => dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);
  Color  get txt      => dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17);
  Color  get muted    => dark ? const Color(0xFF777777) : const Color(0xFF7a7060);
  Color  get green    => dark ? const Color(0xFF60f5a0) : const Color(0xFF1a7a40);

  static const _monthNames = ['January','February','March','April','May','June',
    'July','August','September','October','November','December'];

  // ── Chart data ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _chartData {
    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(_month.year, _month.month - i);
      final k = '${d.year}-${d.month.toString().padLeft(2,'0')}';
      final b = _data.budgets[k];
      result.add({
        'label': ['J','F','M','A','M','J','J','A','S','O','N','D'][d.month - 1],
        'income':  b?.totalIncome  ?? 0.0,
        'expense': b?.totalExpense ?? 0.0,
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final b = _budget;
    final chart = _chartData;
    final maxVal = chart.fold(0.0, (m, d) =>
      [m, d['income'] as double, d['expense'] as double].reduce((a, b) => a > b ? a : b));

    return Stack(children: [
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Month nav
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(icon: Icon(Icons.chevron_left, color: muted),
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
            Text('${_monthNames[_month.month-1]} ${_month.year}',
              style: GoogleFonts.dmMono(color: txt, fontSize: 16, fontWeight: FontWeight.w500)),
            IconButton(icon: Icon(Icons.chevron_right, color: muted),
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
          ]),
          const SizedBox(height: 8),

          // Summary
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: surface, border: Border.all(color: accent),
              borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _sum('INCOME',   b.totalIncome,  accent),
              Container(width: 1, height: 50, color: border),
              _sum('EXPENSES', b.totalExpense, accent2),
              Container(width: 1, height: 50, color: border),
              _sum('LEFT', b.remaining, b.remaining >= 0 ? green : accent2),
            ]),
          ),
          const SizedBox(height: 12),

          // 6-month chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surface, border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('6-MONTH OVERVIEW', style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end,
                  children: chart.map((d) {
                    final inc = d['income'] as double;
                    final exp = d['expense'] as double;
                    final ih = maxVal > 0 ? (inc / maxVal * 60).clamp(2.0, 60.0) : 2.0;
                    final eh = maxVal > 0 ? (exp / maxVal * 60).clamp(2.0, 60.0) : 2.0;
                    return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(width: 8, height: ih, decoration: BoxDecoration(
                          color: accent, borderRadius: const BorderRadius.vertical(top: Radius.circular(2)))),
                        const SizedBox(width: 2),
                        Container(width: 8, height: eh, decoration: BoxDecoration(
                          color: accent2, borderRadius: const BorderRadius.vertical(top: Radius.circular(2)))),
                      ]),
                      const SizedBox(height: 4),
                      Text(d['label'] as String, style: GoogleFonts.dmMono(color: muted, fontSize: 9)),
                    ]));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _legend(accent, 'Income'),
                const SizedBox(width: 12),
                _legend(accent2, 'Expenses'),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Income
          Row(children: [
            Text('INCOME', style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 2)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _carryOver,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2a3a1a)),
                  borderRadius: BorderRadius.circular(4)),
                child: Text('⟵ Carry Over',
                  style: GoogleFonts.dmMono(color: const Color(0xFF7aaa40), fontSize: 10)),
              )),
          ]),
          const SizedBox(height: 8),
          ...b.income.asMap().entries.map((e) => _secCard(e.value, e.key, true, b)),
          _addSecBtn('+ Income Section', true, b),
          const SizedBox(height: 12),

          Text('EXPENSES', style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 8),
          ...b.expense.asMap().entries.map((e) => _secCard(e.value, e.key, false, b)),
          _addSecBtn('+ Expense Section', false, b),
        ]),
      ),

      // Bottom bar
      Positioned(bottom: 0, left: 0, right: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: surface2, border: Border(top: BorderSide(color: border))),
          child: Row(children: [
            _barBtn('⬇ CSV', () => _exportCSV()),
            const SizedBox(width: 8),
            _barBtn('📋 Copy', _copyToClipboard),
          ]),
        )),

      // Toast
      if (_toast != null)
        Positioned(bottom: 60, left: 20, right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: surface2, border: Border.all(color: accent),
              borderRadius: BorderRadius.circular(8)),
            child: Text(_toast!, textAlign: TextAlign.center,
              style: GoogleFonts.dmMono(color: accent, fontSize: 13)))),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _legend(Color c, String label) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
  ]);

  Widget _barBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 13))));

  Widget _sum(String label, double amount, Color color) => Column(children: [
    Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 1.5)),
    const SizedBox(height: 4),
    Text('\$${amount.toStringAsFixed(2)}',
      style: GoogleFonts.dmMono(color: color, fontSize: 15, fontWeight: FontWeight.w500)),
  ]);

  Widget _addSecBtn(String label, bool isIncome, MonthBudget b) => TextButton(
    onPressed: () {
      if (isIncome) b.income.add(BudgetSection(name: 'NEW SECTION', rows: []));
      else b.expense.add(BudgetSection(name: 'NEW SECTION', rows: []));
      _save(b);
    },
    child: Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 15)));

  // ── Section card with swipe-to-delete ────────────────────────────────────
  Widget _secCard(BudgetSection sec, int secIdx, bool isIncome, MonthBudget b) {
    return Dismissible(
      key: ValueKey('sec_${isIncome}_${secIdx}_${sec.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: accent2.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.delete, color: accent2, size: 22)),
      confirmDismiss: (_) async {
        final ok = await _confirm(context, 'Delete section "${sec.name}"?');
        if (ok) {
          if (isIncome) b.income.removeAt(secIdx);
          else b.expense.removeAt(secIdx);
          _save(b);
        }
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: surface, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
            child: Row(children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('sn_${isIncome}_$secIdx'),
                  initialValue: sec.name,
                  style: GoogleFonts.dmMono(color: accent, fontSize: 13, letterSpacing: 2),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  onChanged: (v) { sec.name = v; _save(b); },
                )),
              Text('\$${sec.total.toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
            ]),
          ),
          // Column headers
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 50, 2),
            child: Row(children: [
              Expanded(child: Text('LABEL',
                style: GoogleFonts.dmMono(color: muted, fontSize: 9, letterSpacing: 1.5))),
              SizedBox(width: 95, child: Text('TYPE (tap)',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmMono(color: muted, fontSize: 9, letterSpacing: 1.5))),
              SizedBox(width: 85, child: Text('AMOUNT',
                textAlign: TextAlign.right,
                style: GoogleFonts.dmMono(color: muted, fontSize: 9, letterSpacing: 1.5))),
            ]),
          ),
          // Rows
          ...sec.rows.asMap().entries.map((e) => _rowTile(e.value, e.key, sec, b)),
          TextButton(
            onPressed: () { sec.rows.add(BudgetRow(label: '', amount: 0)); _save(b); },
            child: Text('+ Row', style: GoogleFonts.dmMono(color: muted, fontSize: 13))),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: surface2,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('TOTAL', style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 1.5)),
              Text('\$${sec.total.toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(color: txt, fontSize: 15, fontWeight: FontWeight.w500)),
            ])),
        ]),
      ),
    );
  }

  // ── Row tile with tap-to-cycle type pill ──────────────────────────────────
  Widget _rowTile(BudgetRow row, int rowIdx, BudgetSection sec, MonthBudget b) {
    final tag      = _tags.contains(row.tag) ? row.tag : '';
    final tagColor = _tagColor[tag] ?? const Color(0xFF555555);
    final nextTag  = _tags[(_tags.indexOf(tag) + 1) % _tags.length];
    final label    = _tagLabel[tag] ?? 'type';

    return Dismissible(
      key: ValueKey('row_${sec.name}_${rowIdx}_${row.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
        color: accent2.withOpacity(0.15),
        child: Icon(Icons.delete, color: accent2, size: 18)),
      confirmDismiss: (_) async => await _confirm(context, 'Delete row "${row.label.isEmpty ? 'this row' : row.label}"?'),
      onDismissed: (_) { sec.rows.removeAt(rowIdx); _save(b); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Row(children: [
          // Label
          Expanded(
            child: TextFormField(
              key: ValueKey('rl_${sec.name}_$rowIdx'),
              initialValue: row.label,
              style: GoogleFonts.dmMono(color: txt, fontSize: 15),
              decoration: InputDecoration(hintText: 'Label',
                hintStyle: GoogleFonts.dmMono(color: muted, fontSize: 15),
                border: InputBorder.none, isDense: true),
              onChanged: (v) { row.label = v; _save(b); },
            )),
          // Type pill — tap to cycle
          GestureDetector(
            onTap: () { row.tag = nextTag; _save(b); },
            child: Container(
              width: 95,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: tag.isEmpty ? Colors.transparent : tagColor.withOpacity(0.12),
                border: Border.all(color: tag.isEmpty ? const Color(0xFF444444) : tagColor),
                borderRadius: BorderRadius.circular(4)),
              child: Text(label, textAlign: TextAlign.center,
                style: GoogleFonts.dmMono(
                  color: tag.isEmpty ? const Color(0xFF666666) : tagColor,
                  fontSize: 11),
                overflow: TextOverflow.ellipsis),
            )),
          // Amount
          SizedBox(
            width: 85,
            child: TextFormField(
              key: ValueKey('ra_${sec.name}_$rowIdx'),
              initialValue: row.amount == 0 ? '' : row.amount.toStringAsFixed(2),
              style: GoogleFonts.dmMono(color: txt, fontSize: 15),
              decoration: InputDecoration(hintText: '0.00',
                hintStyle: GoogleFonts.dmMono(color: muted, fontSize: 15),
                border: InputBorder.none, isDense: true,
                prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: muted, fontSize: 15)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              onChanged: (v) { row.amount = double.tryParse(v) ?? 0; _save(b); },
            )),
          // Delete
          GestureDetector(
            onTap: () async { if (await _confirm(context, 'Delete row?')) { sec.rows.removeAt(rowIdx); _save(b); } },
            child: Padding(padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.close, color: muted, size: 15))),
        ]),
      ),
    );
  }
}
