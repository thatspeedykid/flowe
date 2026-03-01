import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/data.dart';

class SnowballScreen extends StatefulWidget {
  final FloData data;
  final ValueChanged<FloData> onChanged;
  const SnowballScreen({super.key, required this.data, required this.onChanged});
  @override
  State<SnowballScreen> createState() => _SnowballScreenState();
}

class _SnowballScreenState extends State<SnowballScreen> {
  late FloData _data;
  final _filters = {'card': true, 'loan': true, 'medical': true, 'other': true};
  String? _syncMsg;

  @override
  void initState() { super.initState(); _data = widget.data; }
  @override
  void didUpdateWidget(SnowballScreen old) { super.didUpdateWidget(old); _data = widget.data; }

  bool get dark => _data.darkMode;
  Color get accent  => dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
  Color get accent2 => dark ? const Color(0xFFf56060) : const Color(0xFFc0392b);
  Color get blue    => dark ? const Color(0xFF60c8f5) : const Color(0xFF1a6090);
  Color get surface => dark ? const Color(0xFF1a1a1a) : Colors.white;
  Color get surface2 => dark ? const Color(0xFF222222) : const Color(0xFFeeebe2);
  Color get border  => dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);
  Color get txt     => dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17);
  Color get muted   => dark ? const Color(0xFF777777) : const Color(0xFF7a7060);
  Color get green   => dark ? const Color(0xFF60f5a0) : const Color(0xFF1a7a40);
  Color get orange  => dark ? const Color(0xFFf5a060) : const Color(0xFFb05000);

  void _save(List<Debt> debts, double extra) {
    final u = FloData(budgets: _data.budgets, debts: debts, extraPayment: extra,
      assets: _data.assets, liabilities: _data.liabilities, snapshots: _data.snapshots,
      events: _data.events, darkMode: _data.darkMode);
    setState(() => _data = u);
    widget.onChanged(u);
  }

  List<Debt> get _filtered => _data.debts.where((d) {
    return _filters[d.type] ?? true;
  }).toList();

  Map<String, dynamic> _calcSnowball(List<Debt> debts, double extra) {
    if (debts.isEmpty) return {'months': 0, 'totalInterest': 0.0, 'payoffMonths': <int>[]};
    var balances = debts.map((d) => d.balance).toList();
    var total = balances.fold(0.0, (a, b) => a + b);
    if (total <= 0) return {'months': 0, 'totalInterest': 0.0, 'payoffMonths': List.filled(debts.length, 0)};
    var month = 0;
    var totalInterest = 0.0;
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
        if (balances[i] > 0) { balances[i] -= extra; if (balances[i] < 0) { balances[i] = 0; if (payoffMonths[i] == 0) payoffMonths[i] = month; } break; }
      }
      total = balances.fold(0.0, (a, b) => a + b);
    }
    return {'months': month, 'totalInterest': totalInterest, 'payoffMonths': payoffMonths};
  }

  String _fmtMonths(int m) {
    if (m == 0) return '—';
    if (m < 12) return '${m}mo';
    final y = m ~/ 12; final mo = m % 12;
    return mo > 0 ? '${y}y ${mo}mo' : '${y}yr';
  }

  String _payoffDate(int months) {
    if (months == 0) return 'Unknown';
    final d = DateTime.now();
    final target = DateTime(d.year, d.month + months);
    const ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${ms[target.month-1]} ${target.year}';
  }

  Color _dueBadgeColor(String? dueDate) {
    if (dueDate == null || dueDate.isEmpty) return Colors.transparent;
    try {
      final due = DateTime.parse(dueDate);
      final diff = due.difference(DateTime.now()).inDays;
      if (diff <= 3) return accent2;
      if (diff <= 7) return orange;
    } catch (_) {}
    return Colors.transparent;
  }

  // Auto-sync min payments from budget — tag='debt' rows get priority
  String _autoSync(List<Debt> debts, double extra) {
    final budgets = _data.budgets;
    if (budgets.isEmpty) return '⚠ No budget data to sync from';
    final allRows = <Map<String, dynamic>>[];
    // Use most recent month
    final sortedKeys = budgets.keys.toList()..sort();
    final recentKey = sortedKeys.last;
    final b = budgets[recentKey]!;
    for (final sec in [...b.income, ...b.expense]) {
      for (final r in sec.rows) {
        if (r.amount > 0) {
          allRows.add({
            'clean': r.label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
            'amount': r.amount,
            'isDebt': r.tag == 'debt',
          });
        }
      }
    }
    int synced = 0;
    for (final d in debts) {
      final dClean = d.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (dClean.isEmpty) continue;
      Map<String, dynamic>? hit;
      // 1. Exact match on debt-tagged rows first
      hit = allRows.cast<Map<String,dynamic>?>().firstWhere(
        (r) => r!['isDebt'] == true && r['clean'] == dClean, orElse: () => null);
      // 2. Exact match any row
      hit ??= allRows.cast<Map<String,dynamic>?>().firstWhere(
        (r) => r!['clean'] == dClean, orElse: () => null);
      // 3. Fuzzy prefix match
      if (hit == null) {
        for (int len = dClean.length; len >= (dClean.length < 5 ? dClean.length : 5); len--) {
          final prefix = dClean.substring(0, len);
          final candidates = allRows.where((r) =>
            (r['clean'] as String).contains(prefix)).toList();
          if (candidates.length == 1) { hit = candidates[0]; break; }
        }
      }
      if (hit != null) { d.minPayment = hit['amount'] as double; synced++; }
    }
    _save(debts, extra);
    if (synced > 0) return '✓ Synced $synced minimum${synced > 1 ? 's' : ''} from Budget';
    return '⚠ No matches — label budget rows with 💳 debt tag or match debt names';
  }

  // Import debt rows from budget as new debt entries
  String _importFromBudget() {
    final budgets = _data.budgets;
    if (budgets.isEmpty) return '⚠ No budget data found';
    final sortedKeys = budgets.keys.toList()..sort();
    final b = budgets[sortedKeys.last]!;
    final debts = List<Debt>.from(_data.debts);
    int added = 0;
    for (final sec in [...b.income, ...b.expense]) {
      for (final r in sec.rows) {
        if (r.tag == 'debt' && r.amount > 0) {
          // Only add if not already in list
          final exists = debts.any((d) =>
            d.name.toLowerCase().trim() == r.label.toLowerCase().trim());
          if (!exists) {
            debts.add(Debt(name: r.label, balance: 0, minPayment: r.amount, apr: 0, type: 'card'));
            added++;
          } else {
            // Update min payment
            final idx = debts.indexWhere((d) => d.name.toLowerCase().trim() == r.label.toLowerCase().trim());
            if (idx >= 0) debts[idx].minPayment = r.amount;
          }
        }
      }
    }
    _save(debts, _data.extraPayment);
    if (added > 0) return '✓ Added $added debt${added > 1 ? "s" : ""} from Budget — set balances & APR';
    return '✓ Updated min payments from Budget debt rows';
  }

  double get _suggestion {
    if (_data.budgets.isEmpty) return 0;
    final last = _data.budgets.values.last;
    return (last.remaining * 0.15).clamp(0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final debts = _data.debts;
    final filtered = _filtered;
    final extra = _data.extraPayment;
    final calc = _calcSnowball(filtered, extra);
    final months = calc['months'] as int;
    final interest = calc['totalInterest'] as double;
    final payoffMonths = calc['payoffMonths'] as List<int>;
    final totalDebt = debts.fold(0.0, (s, d) => s + d.balance);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Stats row
        Row(children: [
          _stat('\$${totalDebt.toStringAsFixed(0)}', 'Total Debt', accent),
          const SizedBox(width: 8),
          _stat(_fmtMonths(months), 'Debt-Free In', green),
          const SizedBox(width: 8),
          _stat('\$${interest.toStringAsFixed(0)}', 'Interest', accent2),
        ]),
        const SizedBox(height: 12),

        // Filter chips
        Row(children: [
          _chip('💳 card', 'card'),
          const SizedBox(width: 8),
          _chip('🏦 loan', 'loan'),
          const SizedBox(width: 8),
          _chip('🏥 medical', 'medical'),
          const SizedBox(width: 8),
          _chip('📦 other', 'other'),
        ]),
        const SizedBox(height: 12),

        // Import/Sync from budget buttons
        Row(children: [
          GestureDetector(
            onTap: () {
              final msg = _importFromBudget();
              setState(() => _syncMsg = msg);
              Future.delayed(const Duration(seconds: 4), () { if (mounted) setState(() => _syncMsg = null); });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: blue),
                borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Icon(Icons.download, color: blue, size: 14),
                const SizedBox(width: 5),
                Text('Import from Budget', style: GoogleFonts.dmMono(color: blue, fontSize: 11)),
              ]),
            )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final msg = _autoSync(_data.debts, _data.extraPayment);
              setState(() => _syncMsg = msg);
              Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _syncMsg = null); });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: green),
                borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                Icon(Icons.sync, color: green, size: 14),
                const SizedBox(width: 5),
                Text('Sync min payments', style: GoogleFonts.dmMono(color: green, fontSize: 11)),
              ]),
            )),
        ]),
        if (_syncMsg != null) ...[
          const SizedBox(height: 6),
          Text(_syncMsg!, style: GoogleFonts.dmMono(
            color: _syncMsg!.startsWith('✓') ? green : orange, fontSize: 11)),
        ],
        const SizedBox(height: 12),

        // 15% suggestion
        if (_suggestion > 0) ...[
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: surface, border: Border.all(color: orange),
              borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.lightbulb_outline, color: orange, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('15% of leftover = \$${_suggestion.toStringAsFixed(2)}/mo extra',
                style: GoogleFonts.dmMono(color: orange, fontSize: 12))),
              GestureDetector(
                onTap: () => _save(debts, _suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: orange), borderRadius: BorderRadius.circular(4)),
                  child: Text('Apply', style: GoogleFonts.dmMono(color: orange, fontSize: 11)))),
            ]),
          ),
        ],

        // Extra payment
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: surface, border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Text('Extra monthly payment', style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
            const Spacer(),
            SizedBox(
              width: 120,
              child: TextFormField(
                key: ValueKey('extra_$extra'),
                initialValue: extra == 0 ? '' : extra.toStringAsFixed(2),
                style: GoogleFonts.dmMono(color: accent, fontSize: 16),
                decoration: InputDecoration(hintText: '0.00', hintStyle: GoogleFonts.dmMono(color: muted),
                  border: InputBorder.none, isDense: true,
                  prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: muted)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                onChanged: (v) => _save(debts, double.tryParse(v) ?? 0),
              )),
          ]),
        ),
        const SizedBox(height: 16),

        // Debt cards
        ...filtered.asMap().entries.map((e) =>
          _debtCard(e.value, debts.indexOf(e.value), debts, extra,
            e.key < payoffMonths.length ? payoffMonths[e.key] : 0)),

        // Add debt
        OutlinedButton.icon(
          onPressed: () => _save([...debts,
            Debt(name: 'New Debt', balance: 0, minPayment: 0, apr: 0, type: 'card')], extra),
          icon: Icon(Icons.add, color: muted, size: 16),
          label: Text('Add Debt', style: GoogleFonts.dmMono(color: muted, fontSize: 15)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: border)),
        ),
        const SizedBox(height: 16),

        // Payoff Timeline
        if (filtered.isNotEmpty && months > 0) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: surface, border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PAYOFF TIMELINE', style: GoogleFonts.dmMono(color: blue, fontSize: 10, letterSpacing: 2)),
              const SizedBox(height: 12),
              ...filtered.asMap().entries.map((e) {
                final pm = e.key < payoffMonths.length ? payoffMonths[e.key] : 0;
                final pct = months > 0 ? (pm / months).clamp(0.0, 1.0) : 0.0;
                final colors = [accent, blue, orange, green, const Color(0xFFc060f5)];
                final col = colors[e.key % colors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(e.value.name,
                        style: GoogleFonts.dmMono(color: txt, fontSize: 12))),
                      Text(_payoffDate(pm),
                        style: GoogleFonts.dmMono(color: col, fontSize: 12)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(value: pct, backgroundColor: border,
                        valueColor: AlwaysStoppedAnimation(col), minHeight: 4)),
                    const SizedBox(height: 2),
                    Text('${_fmtMonths(pm)} · \$${e.value.balance.toStringAsFixed(0)} remaining',
                      style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
                  ]),
                );
              }),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _chip(String label, String key) {
    final active = _filters[key] ?? true;
    return GestureDetector(
      onTap: () => setState(() => _filters[key] = !active),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? accent.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: active ? accent : border),
          borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: GoogleFonts.dmMono(
          color: active ? accent : muted, fontSize: 11))));
  }

  Widget _stat(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: surface, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: GoogleFonts.dmMono(color: color, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 1)),
      ]),
    ),
  );

  Widget _debtCard(Debt debt, int idx, List<Debt> debts, double extra, int payoffMonth) {
    final orig = debt.origBalance > 0 ? debt.origBalance : debt.balance;
    final paid = orig > 0 ? ((orig - debt.balance) / orig).clamp(0.0, 1.0) : 0.0;
    final dueColor = _dueBadgeColor(debt.dueDate);

    return Dismissible(
      key: ValueKey('debt_$idx'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
        color: accent2.withOpacity(0.15), child: Icon(Icons.delete, color: accent2, size: 18)),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: surface,
            title: Text('Delete debt?', style: GoogleFonts.dmMono(color: txt)),
            content: Text('Delete "${debt.name}"? This cannot be undone.',
              style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false),
                child: Text('Cancel', style: GoogleFonts.dmMono(color: muted))),
              TextButton(onPressed: () => Navigator.pop(c, true),
                child: Text('Delete', style: GoogleFonts.dmMono(color: accent2))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) { final d = [...debts]..removeAt(idx); _save(d, extra); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: surface, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('dn_$idx'),
                initialValue: debt.name,
                style: GoogleFonts.dmMono(color: txt, fontSize: 14, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                onChanged: (v) { debt.name = v; _save(debts, extra); },
              ),
            ),
            if (dueColor != Colors.transparent)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: dueColor.withOpacity(0.15),
                  border: Border.all(color: dueColor), borderRadius: BorderRadius.circular(4)),
                child: Text('DUE SOON', style: GoogleFonts.dmMono(color: dueColor, fontSize: 9))),
            DropdownButton<String>(
              value: ['card','loan','medical','other'].contains(debt.type) ? debt.type : 'card',
              dropdownColor: surface2, underline: const SizedBox(), isDense: true,
              style: GoogleFonts.dmMono(color: muted, fontSize: 11),
              items: [
                DropdownMenuItem(value: 'card',    child: Text('💳 card',    style: GoogleFonts.dmMono(color: muted, fontSize: 11))),
                DropdownMenuItem(value: 'loan',    child: Text('🏦 loan',    style: GoogleFonts.dmMono(color: muted, fontSize: 11))),
                DropdownMenuItem(value: 'medical', child: Text('🏥 medical', style: GoogleFonts.dmMono(color: muted, fontSize: 11))),
                DropdownMenuItem(value: 'other',   child: Text('📱 other',   style: GoogleFonts.dmMono(color: muted, fontSize: 11))),
              ],
              onChanged: (v) { debt.type = v ?? 'card'; _save(debts, extra); },
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _field('Balance',  debt.balance,    '\$', (v) { debt.balance = v; if (debt.origBalance < v) debt.origBalance = v; _save(debts, extra); }),
            const SizedBox(width: 8),
            _field('Min Pay',  debt.minPayment, '\$', (v) { debt.minPayment = v; _save(debts, extra); }),
            const SizedBox(width: 8),
            _field('APR %',    debt.apr,        '',  (v) { debt.apr = v; _save(debts, extra); }),
          ]),
          const SizedBox(height: 8),
          // Due date with calendar picker
          Row(children: [
            Text('Due date: ', style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
            Text(
              debt.dueDate != null && debt.dueDate!.isNotEmpty ? debt.dueDate! : 'Not set',
              style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                DateTime initial = DateTime.now();
                try { if (debt.dueDate != null && debt.dueDate!.isNotEmpty) initial = DateTime.parse(debt.dueDate!); } catch(_) {}
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: const Color(0xFFc8f560),
                        onPrimary: const Color(0xFF0f0f0f),
                        surface: const Color(0xFF1a1a1a),
                        onSurface: const Color(0xFFe8e8e8))),
                    child: child!));
                if (picked != null) {
                  debt.dueDate = picked.toIso8601String().split('T')[0];
                  _save(debts, extra);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: border), borderRadius: BorderRadius.circular(4)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today, size: 11, color: muted),
                  const SizedBox(width: 4),
                  Text('Pick', style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
                ]))),
            if (debt.dueDate != null && debt.dueDate!.isNotEmpty) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () { debt.dueDate = ''; _save(debts, extra); },
                child: Icon(Icons.close, size: 12, color: muted)),
            ],
          ]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: paid, backgroundColor: border,
              valueColor: AlwaysStoppedAnimation(blue), minHeight: 6)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${(paid * 100).toStringAsFixed(0)}% paid off',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            Text('Free ${_payoffDate(payoffMonth)}',
              style: GoogleFonts.dmMono(color: blue, fontSize: 10)),
          ]),
        ]),
      ),
    );
  }

  Widget _field(String label, double val, String prefix, ValueChanged<double> onChanged, {String suffix = ''}) =>
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 1)),
      TextFormField(
        key: ValueKey('f_${label}_$val'),
        initialValue: val == 0 ? '' : val.toStringAsFixed(2),
        style: GoogleFonts.dmMono(color: txt, fontSize: 15),
        decoration: InputDecoration(hintText: '0', hintStyle: GoogleFonts.dmMono(color: muted, fontSize: 15),
          border: InputBorder.none, isDense: true,
          prefixText: prefix, prefixStyle: GoogleFonts.dmMono(color: muted, fontSize: 15),
          suffixText: suffix, suffixStyle: GoogleFonts.dmMono(color: muted, fontSize: 15)),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
      ),
    ]));
}
