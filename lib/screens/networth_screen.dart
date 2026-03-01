import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/data.dart';

class NetWorthScreen extends StatefulWidget {
  final FloData data;
  final ValueChanged<FloData> onChanged;
  const NetWorthScreen({super.key, required this.data, required this.onChanged});
  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  late FloData _data;
  @override
  void initState() { super.initState(); _data = widget.data; }
  @override
  void didUpdateWidget(NetWorthScreen old) { super.didUpdateWidget(old); _data = widget.data; }

  bool get dark => _data.darkMode;
  Color get accent   => dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
  Color get accent2  => dark ? const Color(0xFFf56060) : const Color(0xFFc0392b);
  Color get surface  => dark ? const Color(0xFF1a1a1a) : Colors.white;
  Color get surface2 => dark ? const Color(0xFF222222) : const Color(0xFFeeebe2);
  Color get border   => dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);
  Color get txt      => dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17);
  Color get muted    => dark ? const Color(0xFF777777) : const Color(0xFF7a7060);
  Color get green    => dark ? const Color(0xFF60f5a0) : const Color(0xFF1a7a40);

  double get totalAssets      => _data.assets.fold(0.0, (s, a) => s + a.amount);
  double get totalLiabilities => _data.liabilities.fold(0.0, (s, l) => s + l.amount)
      + _data.debts.fold(0.0, (s, d) => s + d.balance);
  double get netWorth         => totalAssets - totalLiabilities;

  void _save() {
    final u = FloData(budgets: _data.budgets, debts: _data.debts,
      extraPayment: _data.extraPayment, assets: _data.assets, liabilities: _data.liabilities,
      snapshots: _data.snapshots, events: _data.events, darkMode: _data.darkMode);
    setState(() => _data = u);
    widget.onChanged(u);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Hero
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: surface, border: Border.all(color: accent),
            borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            Text('NET WORTH', style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('\$${netWorth.toStringAsFixed(2)}',
              style: GoogleFonts.playfairDisplay(
                color: netWorth >= 0 ? accent : accent2,
                fontSize: 36, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _nwStat('Assets', totalAssets, green),
              Container(width: 1, height: 40, color: border),
              _nwStat('Liabilities', totalLiabilities, accent2),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        _section('ASSETS', _data.assets, green, () { _data.assets.add(NWItem(name: '', amount: 0)); _save(); }),
        const SizedBox(height: 12),

        _section('LIABILITIES', _data.liabilities, accent2, () { _data.liabilities.add(NWItem(name: '', amount: 0)); _save(); }),
        const SizedBox(height: 12),

        // Debt from snowball (read-only link)
        if (_data.debts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
              borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.link, color: muted, size: 14),
              const SizedBox(width: 8),
              Text('Debt from Snowball', style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
              const Spacer(),
              Text('\$${_data.debts.fold(0.0, (s, d) => s + d.balance).toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(color: accent2, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // Snapshot button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              final dt = DateTime.now();
              const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
              final now = '\${months[dt.month-1]} \${dt.day}, \${dt.year}';
              _data.snapshots.add(NWSnapshot(date: now, netWorth: netWorth));
              _save();
            },
            style: OutlinedButton.styleFrom(side: BorderSide(color: accent)),
            child: Text('📸 Save Snapshot', style: GoogleFonts.dmMono(color: accent)),
          ),
        ),
        const SizedBox(height: 16),

        // Snapshot history with deltas
        if (_data.snapshots.isNotEmpty) ...[
          Text('HISTORY', style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 8),
          ..._data.snapshots.reversed.toList().asMap().entries.map((e) {
            final s = e.value;
            final origIdx = _data.snapshots.length - 1 - e.key;
            // Delta vs previous snapshot
            final prevIdx = origIdx - 1;
            final hasDelta = prevIdx >= 0;
            final delta = hasDelta ? s.netWorth - _data.snapshots[prevIdx].netWorth : 0.0;
            final deltaUp = delta >= 0;

            return Dismissible(
              key: ValueKey('snap_$origIdx'),
              direction: DismissDirection.endToStart,
              background: Container(alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: accent2.withOpacity(0.15),
                child: Icon(Icons.delete, color: accent2, size: 18)),
              confirmDismiss: (_) async => await _confirm(context, 'Delete this item?'),
      onDismissed: (_) { _data.snapshots.removeAt(origIdx); _save(); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: surface, border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.date, style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
                    if (hasDelta && delta != 0)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: deltaUp
                              ? const Color(0xFF0d1f0d)
                              : const Color(0xFF1f0d0d),
                          borderRadius: BorderRadius.circular(3)),
                        child: Text('${deltaUp ? '+' : ''}\$${delta.toStringAsFixed(2)}',
                          style: GoogleFonts.dmMono(
                            color: deltaUp ? green : accent2, fontSize: 10)),
                      ),
                  ])),
                  Text('\$${s.netWorth.toStringAsFixed(2)}',
                    style: GoogleFonts.playfairDisplay(
                      color: s.netWorth >= 0 ? green : accent2, fontSize: 15)),
                ]),
              ),
            );
          }),
        ],
      ]),
    );
  }

  Widget _nwStat(String label, double amount, Color color) => Column(children: [
    Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 1.5)),
    const SizedBox(height: 4),
    Text('\$${amount.toStringAsFixed(2)}', style: GoogleFonts.dmMono(color: color, fontSize: 15)),
  ]);

  Widget _section(String title, List<NWItem> items, Color color, VoidCallback onAdd) {
    return Container(
      decoration: BoxDecoration(color: surface, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: surface2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
          child: Row(children: [
            Text(title, style: GoogleFonts.dmMono(color: color, fontSize: 11, letterSpacing: 2)),
            const Spacer(),
            Text('\$${items.fold(0.0, (s, i) => s + i.amount).toStringAsFixed(2)}',
              style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
          ]),
        ),
        ...items.asMap().entries.map((e) => Dismissible(
          key: ValueKey('nw_${title}_${e.key}'),
          direction: DismissDirection.endToStart,
          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
            color: accent2.withOpacity(0.15), child: Icon(Icons.delete, color: accent2, size: 18)),
          confirmDismiss: (_) async => await _confirm(context, 'Delete this item?'),
      onDismissed: (_) { items.removeAt(e.key); _save(); },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('nwl_${title}_${e.key}'),
                  initialValue: e.value.name,
                  style: GoogleFonts.dmMono(color: txt, fontSize: 15),
                  decoration: InputDecoration(hintText: 'Label',
                    hintStyle: GoogleFonts.dmMono(color: muted), border: InputBorder.none, isDense: true),
                  onChanged: (v) { e.value.name = v; _save(); },
                ),
              ),
              SizedBox(
                width: 110,
                child: TextFormField(
                  key: ValueKey('nwa_${title}_${e.key}'),
                  initialValue: e.value.amount == 0 ? '' : e.value.amount.toStringAsFixed(2),
                  style: GoogleFonts.dmMono(color: txt, fontSize: 15),
                  decoration: InputDecoration(hintText: '0.00',
                    hintStyle: GoogleFonts.dmMono(color: muted), border: InputBorder.none, isDense: true,
                    prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: muted)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  onChanged: (v) { e.value.amount = double.tryParse(v) ?? 0; _save(); },
                ),
              ),
              GestureDetector(onTap: () { items.removeAt(e.key); _save(); },
                child: Padding(padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, color: muted, size: 14))),
            ]),
          ),
        )),
        TextButton(onPressed: onAdd,
          child: Text('+ Add', style: GoogleFonts.dmMono(color: muted, fontSize: 13))),
      ]),
    );
  }
}
