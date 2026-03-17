import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import '../models/data.dart';

const _platform = MethodChannel('com.flowe/storage');

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
      events: _data.events, transactions: _data.transactions, darkMode: _data.darkMode, fontSize: _data.fontSize);
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

  // ── Snowball calc (for export) ──────────────────────────────────────────
  Map<String, dynamic> _calcSnowball(List<Debt> debts, double extra) {
    if (debts.isEmpty) return {'months': 0, 'totalInterest': 0.0, 'payoffMonths': <int>[]};
    var balances = debts.map((d) => d.balance).toList();
    double total = balances.fold(0.0, (a, b) => a + b);
    if (total <= 0) return {'months': 0, 'totalInterest': 0.0, 'payoffMonths': List.filled(debts.length, 0)};
    int month = 0;
    double totalInterest = 0.0;
    final payoffMonths = List.filled(debts.length, 0);
    while (total > 0.01 && month < 600) {
      month++;
      for (var i = 0; i < debts.length; i++) {
        if (balances[i] <= 0) continue;
        final interest = balances[i] * (debts[i].apr / 100 / 12);
        totalInterest += interest;
        balances[i] = balances[i] + interest - debts[i].minPayment;
        if (balances[i] < 0) balances[i] = 0;
        if (balances[i] == 0 && payoffMonths[i] == 0) payoffMonths[i] = month;
      }
      for (var i = 0; i < debts.length; i++) {
        if (balances[i] > 0) {
          balances[i] -= extra;
          if (balances[i] < 0) { balances[i] = 0; if (payoffMonths[i] == 0) payoffMonths[i] = month; }
          break;
        }
      }
      total = balances.fold(0.0, (a, b) => a + b);
    }
    return {'months': month, 'totalInterest': totalInterest, 'payoffMonths': payoffMonths};
  }

  String _payoffDate(int months) {
    if (months == 0) return 'Unknown';
    final d = DateTime.now();
    final target = DateTime(d.year, d.month + months);
    const ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${ms[target.month-1]} ${target.year}';
  }

  String _fmtMonths(int m) {
    if (m == 0) return '--';
    if (m < 12) return '${m}mo';
    final y = m ~/ 12; final mo = m % 12;
    return mo > 0 ? '${y}y ${mo}mo' : '${y}yr';
  }

  // ── Build CSV: budget + full snowball with payoff dates ──────────────────
  String _buildCSV() {
    final b = _budget;
    final rows = ['Label,Amount,Type,Section'];
    for (final s in b.income)
      for (final r in s.rows)
        rows.add('"${r.label}",${r.amount.toStringAsFixed(2)},Income,"${s.name}"');
    for (final s in b.expense)
      for (final r in s.rows)
        rows.add('"${r.label}",${r.amount.toStringAsFixed(2)},Expense,"${s.name}"');
    rows.add('"Total Income",${b.totalIncome.toStringAsFixed(2)},,');
    rows.add('"Total Expenses",${b.totalExpense.toStringAsFixed(2)},,');
    rows.add('"Remaining",${b.remaining.toStringAsFixed(2)},,');
    final debts = _data.debts;
    if (debts.isNotEmpty) {
      final calc = _calcSnowball(debts, _data.extraPayment);
      final payoffMonths = calc['payoffMonths'] as List<int>;
      final totalMonths  = calc['months'] as int;
      final totalInterest = calc['totalInterest'] as double;
      rows.add('');
      rows.add('--- DEBT SNOWBALL ---');
      rows.add('"Debt-Free In","${_fmtMonths(totalMonths)} (${_payoffDate(totalMonths)})",,');
      rows.add('"Total Interest",${totalInterest.toStringAsFixed(2)},,');
      rows.add('"Extra Monthly Payment",${_data.extraPayment.toStringAsFixed(2)},,');
      rows.add('');
      rows.add('Debt Name,Balance,Min Payment,APR %,Type,Due Date,Payoff In,Payoff Date');
      for (int i = 0; i < debts.length; i++) {
        final d = debts[i];
        final pm = i < payoffMonths.length ? payoffMonths[i] : 0;
        rows.add('"${d.name}",${d.balance.toStringAsFixed(2)},${d.minPayment.toStringAsFixed(2)},'
          '${d.apr.toStringAsFixed(2)},"${d.type}","${d.dueDate ?? ''}",'
          '"${_fmtMonths(pm)}","${_payoffDate(pm)}"');
      }
      rows.add('"Total Debt",${debts.fold(0.0, (s, d) => s + d.balance).toStringAsFixed(2)},,,,,,');
    }
    return rows.join('\n');
  }

  // ── Build PDF with full snowball + text timeline bars ────────────────────
  Uint8List _buildPDF() {
    final b = _budget;
    final debts = _data.debts;
    final lines = <String>[];
    lines.add('Flowe Budget Report -- $_key');
    lines.add('Generated ${DateTime.now().toString().split('.')[0]}');
    lines.add('');
    lines.add('=' * 52);
    lines.add('BUDGET SUMMARY');
    lines.add('=' * 52);
    lines.add('');
    for (final s in b.income) {
      lines.add('  ${s.name}');
      for (final r in s.rows) {
        if (r.label.isNotEmpty || r.amount > 0)
          lines.add('    ${r.label.padRight(30)} \$${r.amount.toStringAsFixed(2)}');
      }
      lines.add('    ' + '-' * 38);
      lines.add('    ${'Subtotal'.padRight(30)} \$${s.total.toStringAsFixed(2)}');
      lines.add('');
    }
    for (final s in b.expense) {
      lines.add('  ${s.name}');
      for (final r in s.rows) {
        if (r.label.isNotEmpty || r.amount > 0)
          lines.add('    ${r.label.padRight(30)} \$${r.amount.toStringAsFixed(2)}');
      }
      lines.add('    ' + '-' * 38);
      lines.add('    ${'Subtotal'.padRight(30)} \$${s.total.toStringAsFixed(2)}');
      lines.add('');
    }
    lines.add('  ' + '-' * 48);
    lines.add('  ${'Total Income:'.padRight(30)} \$${b.totalIncome.toStringAsFixed(2)}');
    lines.add('  ${'Total Expenses:'.padRight(30)} \$${b.totalExpense.toStringAsFixed(2)}');
    lines.add('  ${'Remaining:'.padRight(30)} \$${b.remaining.toStringAsFixed(2)}');

    if (debts.isNotEmpty) {
      final calc        = _calcSnowball(debts, _data.extraPayment);
      final payoffMonths = calc['payoffMonths'] as List<int>;
      final totalMonths  = calc['months'] as int;
      final totalInterest = calc['totalInterest'] as double;
      final totalDebt   = debts.fold(0.0, (s, d) => s + d.balance);
      final totalCost   = totalDebt + totalInterest;

      lines.add('');
      lines.add('');
      lines.add('=' * 52);
      lines.add('DEBT SNOWBALL');
      lines.add('=' * 52);
      lines.add('');
      lines.add('  ${'Total Debt:'.padRight(30)} \$${totalDebt.toStringAsFixed(2)}');
      lines.add('  ${'Total Interest:'.padRight(30)} \$${totalInterest.toStringAsFixed(2)}');
      lines.add('  ${'Total Cost:'.padRight(30)} \$${totalCost.toStringAsFixed(2)}');
      lines.add('  ${'Extra Payment/mo:'.padRight(30)} \$${_data.extraPayment.toStringAsFixed(2)}');
      lines.add('  ${'Debt-Free In:'.padRight(30)} ${_fmtMonths(totalMonths)}');
      lines.add('  ${'Debt-Free Date:'.padRight(30)} ${_payoffDate(totalMonths)}');
      lines.add('');

      if (totalCost > 0) {
        final pBars = ((totalDebt / totalCost) * 40).round().clamp(0, 40);
        final iBars = 40 - pBars;
        lines.add('  Cost Breakdown:');
        lines.add('  [' + ('#' * pBars) + ('.' * iBars) + ']');
        lines.add('  # Principal \$${totalDebt.toStringAsFixed(0).padLeft(10)}   '
          '. Interest \$${totalInterest.toStringAsFixed(0)}');
        lines.add('');
      }

      lines.add('  PAYOFF TIMELINE');
      lines.add('  ' + '-' * 52);
      lines.add('  ${'Debt'.padRight(22)}${'Balance'.padRight(12)}${'Payoff In'.padRight(10)}Date');
      lines.add('  ' + '-' * 52);
      for (int i = 0; i < debts.length; i++) {
        final d  = debts[i];
        final pm = i < payoffMonths.length ? payoffMonths[i] : 0;
        final pct  = totalMonths > 0 ? (pm / totalMonths).clamp(0.0, 1.0) : 0.0;
        final bars = (pct * 20).round();
        final name = d.name.length > 21 ? d.name.substring(0, 21) : d.name.padRight(22);
        lines.add('  $name\$${d.balance.toStringAsFixed(0).padLeft(10)} '
          '${_fmtMonths(pm).padRight(10)} ${_payoffDate(pm)}');
        lines.add('  APR:${d.apr.toStringAsFixed(1)}%  Min:\$${d.minPayment.toStringAsFixed(0)}  '
          '[' + ('#' * bars) + ('.' * (20 - bars)) + ']');
        lines.add('');
      }
    }
    lines.add('-' * 52);
    lines.add('Generated by Flowe -- your data, your device.');
    return _makePDF(lines.join('\n'));
  }


  Uint8List _makePDF(String content) {
    final lines = content.split('\n');
    final sb = StringBuffer();
    sb.write('BT\n/F1 9 Tf\n50 780 Td\n11 TL\n');
    double y = 780;
    for (final line in lines) {
      if (y < 40) break;
      final esc = line.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
      sb.write('($esc) Tj T*\n');
      y -= 11;
    }
    sb.write('ET\n');
    final stream = sb.toString();
    final parts = <String>[];
    parts.add('%PDF-1.4\n');
    final offs = <int>[];
    int off = '%PDF-1.4\n'.length;
    void addObj(String s) { offs.add(off); parts.add(s); off += s.length; }
    addObj('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    addObj('2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n');
    addObj('3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n');
    addObj('4 0 obj\n<< /Length ${stream.length} >>\nstream\n${stream}endstream\nendobj\n');
    addObj('5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier >>\nendobj\n');
    final xref = off;
    final xLines = ['xref\n0 6', '0000000000 65535 f '];
    for (final o in offs) xLines.add(o.toString().padLeft(10,'0') + ' 00000 n ');
    xLines.add('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xref\n%%EOF');
    final pdf = (parts + [xLines.join('\n')]).join('');
    return Uint8List.fromList(pdf.codeUnits);
  }

  // ── Unified share/save ────────────────────────────────────────────────────
  // ── Mobile export picker: Save to Files OR Share sheet ──────────────────
  Future<void> _mobileExportPicker({
    required String filename,
    required String mime,
    required Future<File> Function(Directory dir) writeFile,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: surface2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2))),
            Text(filename,
              style: GoogleFonts.dmMono(color: muted, fontSize: 11),
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.save_alt, color: accent),
              title: Text('Save to Files / Downloads',
                style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
              subtitle: Text(
                Platform.isAndroid ? 'Saves to Downloads folder' : 'Saves to Files app',
                style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
              onTap: () => Navigator.pop(ctx, 'save'),
            ),
            ListTile(
              leading: Icon(Icons.share, color: accent),
              title: Text('Share…',
                style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
              subtitle: Text('AirDrop, email, messages, Drive…',
                style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
            const SizedBox(height: 4),
          ]),
        ),
      ),
    );
    if (choice == null) return;

    try {
      if (choice == 'share') {
        final dir = await getTemporaryDirectory();
        final file = await writeFile(dir);
        await Share.shareXFiles([XFile(file.path, mimeType: mime)], subject: filename);
      } else {
        // Save
        if (Platform.isAndroid) {
          final dir = await getTemporaryDirectory();
          final file = await writeFile(dir);
          final isText = mime.startsWith('text/');
          try {
            if (isText) {
              final content = await file.readAsString();
              final path = await _platform.invokeMethod('saveToDownloads', {
                'filename': filename, 'content': content, 'mimeType': mime,
              });
              _showToast('Saved to $path');
            } else {
              final bytes = await file.readAsBytes();
              final path = await _platform.invokeMethod('saveBytesToDownloads', {
                'filename': filename, 'bytes': bytes, 'mimeType': mime,
              });
              _showToast('Saved to $path');
            }
          } on PlatformException catch (e) {
            if (e.code == 'PERMISSION_DENIED') {
              _showToast('Storage permission denied — allow and try again');
            } else {
              _showToast('Export failed: ${e.message}');
            }
          }
        } else {
          // iOS: share to Files app via share sheet (same UX, user picks Files)
          final dir = await getTemporaryDirectory();
          final file = await writeFile(dir);
          await Share.shareXFiles([XFile(file.path, mimeType: mime)], subject: filename);
        }
      }
    } catch (e) { _showToast('Export failed: $e'); }
  }

  Future<void> _exportFile({
    required String filename,
    required String mime,
    required Future<File> Function(Directory dir) writeFile,
  }) async {
    try {
      if (Platform.isIOS) {
        // iOS: straight to share sheet — it already has Save to Files built in
        final dir = await getTemporaryDirectory();
        final file = await writeFile(dir);
        await Share.shareXFiles([XFile(file.path, mimeType: mime)], subject: filename);
      } else if (Platform.isAndroid) {
        // Android: show picker — save to Downloads OR share
        await _mobileExportPicker(filename: filename, mime: mime, writeFile: writeFile);
      } else {
        // Desktop: native save dialog
        final ext = filename.split('.').last;
        final loc = await getSaveLocation(suggestedName: filename,
          acceptedTypeGroups: [XTypeGroup(label: ext.toUpperCase(), extensions: [ext])]);
        if (loc == null) return;
        final p = loc.path;
        final sepIdx = p.lastIndexOf(Platform.isWindows ? '\\' : '/');
        final dir = Directory(sepIdx > 0 ? p.substring(0, sepIdx) : p);
        final file = await writeFile(dir);
        if (file.path != loc.path) await file.copy(loc.path);
        _showToast('Saved to ${loc.path}');
      }
    } catch (e) { _showToast('Export failed: $e'); }
  }

  Future<void> _exportCSV() => _exportFile(
    filename: 'flowe_budget_$_key.csv',
    mime: 'text/csv',
    writeFile: (dir) async {
      final f = File('${dir.path}/flowe_budget_$_key.csv');
      await f.writeAsString(_buildCSV());
      return f;
    },
  );

  Future<void> _exportPDF() => _exportFile(
    filename: 'flowe_budget_$_key.pdf',
    mime: 'application/pdf',
    writeFile: (dir) async {
      final f = File('${dir.path}/flowe_budget_$_key.pdf');
      await f.writeAsBytes(_buildPDF());
      return f;
    },
  );

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

  List<Map<String, dynamic>> get _chartData {
    final result = <Map<String, dynamic>>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(_month.year, _month.month - i);
      final k = '${d.year}-${d.month.toString().padLeft(2,'0')}';
      final b = _data.budgets[k];
      result.add({'label': ['J','F','M','A','M','J','J','A','S','O','N','D'][d.month - 1],
        'income': b?.totalIncome ?? 0.0, 'expense': b?.totalExpense ?? 0.0});
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
          // Chart
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
                      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Container(width: 8, height: ih, decoration: BoxDecoration(color: accent,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)))),
                        const SizedBox(width: 2),
                        Container(width: 8, height: eh, decoration: BoxDecoration(color: accent2,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)))),
                      ]),
                      const SizedBox(height: 4),
                      Text(d['label'] as String, style: GoogleFonts.dmMono(color: muted, fontSize: 9)),
                    ]));
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [_legend(accent, 'Income'), const SizedBox(width: 12), _legend(accent2, 'Expenses')]),
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
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFF2a3a1a)), borderRadius: BorderRadius.circular(4)),
                child: Text('⟵ Carry Over', style: GoogleFonts.dmMono(color: const Color(0xFF7aaa40), fontSize: 10)))),
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
            _barBtn(Platform.isIOS ? '↑ CSV' : '⬇ CSV', _exportCSV),
            const SizedBox(width: 8),
            _barBtn(Platform.isIOS ? '↑ PDF' : '⬇ PDF', _exportPDF),
            const SizedBox(width: 8),
            _barBtn('📋 Copy', _copyToClipboard),
          ]),
        )),
      if (_toast != null)
        Positioned(bottom: 60, left: 20, right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: surface2, border: Border.all(color: accent), borderRadius: BorderRadius.circular(8)),
            child: Text(_toast!, textAlign: TextAlign.center, style: GoogleFonts.dmMono(color: accent, fontSize: 13)))),
    ]);
  }

  Widget _legend(Color c, String label) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 10))]);

  Widget _barBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 13))));

  Widget _sum(String label, double amount, Color color) => Column(children: [
    Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 1.5)),
    const SizedBox(height: 4),
    Text('\$${amount.toStringAsFixed(2)}', style: GoogleFonts.dmMono(color: color, fontSize: 15, fontWeight: FontWeight.w500))]);

  Widget _addSecBtn(String label, bool isIncome, MonthBudget b) => TextButton(
    onPressed: () {
      if (isIncome) b.income.add(BudgetSection(name: 'NEW SECTION', rows: []));
      else b.expense.add(BudgetSection(name: 'NEW SECTION', rows: []));
      _save(b);
    },
    child: Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 15)));

  Widget _secCard(BudgetSection sec, int secIdx, bool isIncome, MonthBudget b) {
    return Dismissible(
      key: ValueKey('sec_${isIncome}_${secIdx}_${sec.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: accent2.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.delete, color: accent2, size: 22)),
      confirmDismiss: (_) async {
        final ok = await _confirm(context, 'Delete section "${sec.name}"?');
        if (ok) { if (isIncome) b.income.removeAt(secIdx); else b.expense.removeAt(secIdx); _save(b); }
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: surface, border: Border.all(color: border), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: surface2, borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
            child: Row(children: [
              Expanded(child: TextFormField(key: ValueKey('sn_${isIncome}_$secIdx'), initialValue: sec.name,
                style: GoogleFonts.dmMono(color: accent, fontSize: 13, letterSpacing: 2),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                onChanged: (v) { sec.name = v; _save(b); })),
              Text('\$${sec.total.toStringAsFixed(2)}', style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
            ])),
          Padding(padding: const EdgeInsets.fromLTRB(16, 6, 36, 2),
            child: Row(children: [
              Expanded(child: Text('LABEL', style: GoogleFonts.dmMono(color: muted, fontSize: 9, letterSpacing: 1.5))),
              SizedBox(width: 80, child: Text('TYPE', textAlign: TextAlign.center, style: GoogleFonts.dmMono(color: muted, fontSize: 9, letterSpacing: 1.5))),
              SizedBox(width: 90, child: Text('AMOUNT', textAlign: TextAlign.right, style: GoogleFonts.dmMono(color: muted, fontSize: 9, letterSpacing: 1.5))),
            ])),
          ...sec.rows.asMap().entries.map((e) => _rowTile(e.value, e.key, sec, b)),
          TextButton(onPressed: () { sec.rows.add(BudgetRow(label: '', amount: 0)); _save(b); },
            child: Text('+ Row', style: GoogleFonts.dmMono(color: muted, fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: surface2, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('TOTAL', style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 1.5)),
              Text('\$${sec.total.toStringAsFixed(2)}', style: GoogleFonts.dmMono(color: txt, fontSize: 15, fontWeight: FontWeight.w500)),
            ])),
        ]),
      ),
    );
  }

  Widget _rowTile(BudgetRow row, int rowIdx, BudgetSection sec, MonthBudget b) {
    final tag      = _tags.contains(row.tag) ? row.tag : '';
    final tagColor = _tagColor[tag] ?? const Color(0xFF555555);
    final nextTag  = _tags[(_tags.indexOf(tag) + 1) % _tags.length];
    final label    = _tagLabel[tag] ?? 'type';
    return Dismissible(
      key: ValueKey('row_${sec.name}_${rowIdx}_${row.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
        color: accent2.withOpacity(0.15), child: Icon(Icons.delete, color: accent2, size: 18)),
      confirmDismiss: (_) async => await _confirm(context, 'Delete row "${row.label.isEmpty ? 'this row' : row.label}"?'),
      onDismissed: (_) { sec.rows.removeAt(rowIdx); _save(b); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Row(children: [
          // Label
          Expanded(child: TextFormField(key: ValueKey('rl_${sec.name}_$rowIdx'), initialValue: row.label,
            style: GoogleFonts.dmMono(color: txt, fontSize: 14),
            decoration: InputDecoration(hintText: 'Label', hintStyle: GoogleFonts.dmMono(color: muted, fontSize: 14), border: InputBorder.none, isDense: true),
            onChanged: (v) { row.label = v; _save(b); })),
          // Tag — no box, just a small colored pill with dot
          GestureDetector(
            onTap: () { row.tag = nextTag; _save(b); },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: tag.isEmpty ? const Color(0xFF444444) : tagColor,
                    shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(tag.isEmpty ? 'type' : label.replaceAll(RegExp(r'^.\s'), ''),
                  style: GoogleFonts.dmMono(
                    color: tag.isEmpty ? const Color(0xFF555555) : tagColor,
                    fontSize: 10),
                  overflow: TextOverflow.ellipsis),
              ]),
            )),
          // Amount
          SizedBox(width: 90, child: TextFormField(key: ValueKey('ra_${sec.name}_$rowIdx'),
            initialValue: row.amount == 0 ? '' : row.amount.toStringAsFixed(2),
            style: GoogleFonts.dmMono(color: txt, fontSize: 14),
            decoration: InputDecoration(hintText: '0.00', hintStyle: GoogleFonts.dmMono(color: muted, fontSize: 14),
              border: InputBorder.none, isDense: true,
              prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: muted, fontSize: 14)),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            onChanged: (v) { row.amount = double.tryParse(v) ?? 0; _save(b); })),
          // Delete
          GestureDetector(
            onTap: () async { if (await _confirm(context, 'Delete row?')) { sec.rows.removeAt(rowIdx); _save(b); } },
            child: Padding(padding: const EdgeInsets.only(left: 6), child: Icon(Icons.close, color: muted, size: 14))),
        ]),
      ),
    );
  }
}
