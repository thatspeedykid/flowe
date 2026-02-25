import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/data.dart';

class EventsScreen extends StatefulWidget {
  final FloData data;
  final ValueChanged<FloData> onChanged;
  const EventsScreen({super.key, required this.data, required this.onChanged});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late FloData _data;
  int _sel = 0;
  // Split state
  final List<Map<String, dynamic>> _people = [];
  double _splitTotal = -1;

  @override
  void initState() { super.initState(); _data = widget.data; }
  @override
  void didUpdateWidget(EventsScreen old) { super.didUpdateWidget(old); _data = widget.data; }

  bool get dark => _data.darkMode;
  Color get accent   => dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
  Color get accent2  => dark ? const Color(0xFFf56060) : const Color(0xFFc0392b);
  Color get surface  => dark ? const Color(0xFF1a1a1a) : Colors.white;
  Color get surface2 => dark ? const Color(0xFF222222) : const Color(0xFFeeebe2);
  Color get border   => dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);
  Color get txt      => dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17);
  Color get muted    => dark ? const Color(0xFF777777) : const Color(0xFF7a7060);
  Color get orange   => dark ? const Color(0xFFf5a060) : const Color(0xFFb05000);
  Color get purple   => dark ? const Color(0xFFc060f5) : const Color(0xFF7030a0);
  Color get green    => dark ? const Color(0xFF60f5a0) : const Color(0xFF1a7a40);

  void _save() {
    final u = FloData(budgets: _data.budgets, debts: _data.debts,
      extraPayment: _data.extraPayment, assets: _data.assets, liabilities: _data.liabilities,
      snapshots: _data.snapshots, events: _data.events, darkMode: _data.darkMode);
    setState(() => _data = u);
    widget.onChanged(u);
  }

  @override
  Widget build(BuildContext context) {
    final events = _data.events;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Event selector row
        Row(children: [
          Expanded(
            child: events.isEmpty
                ? Text('No events', style: GoogleFonts.dmMono(color: muted, fontSize: 13))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<int>(
                      value: _sel.clamp(0, events.length - 1),
                      dropdownColor: surface2, underline: const SizedBox(), isExpanded: true,
                      style: GoogleFonts.dmMono(color: txt, fontSize: 13),
                      items: events.asMap().entries.map((e) => DropdownMenuItem(value: e.key,
                        child: Text(e.value.name.isEmpty ? 'Unnamed' : e.value.name,
                          style: GoogleFonts.dmMono(color: txt, fontSize: 13)))).toList(),
                      onChanged: (v) => setState(() { _sel = v ?? 0; _splitTotal = -1; _people.clear(); }),
                    )),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _data.events.add(Event(name: 'New Event', cap: 0, categories: []));
              setState(() { _sel = _data.events.length - 1; _splitTotal = -1; _people.clear(); });
              _save();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: accent), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.add, color: accent, size: 18))),
          if (events.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _data.events.removeAt(_sel);
                if (_sel >= _data.events.length && _sel > 0) _sel--;
                _people.clear(); _splitTotal = -1;
                _save();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.delete_outline, color: muted, size: 18))),
          ],
        ]),

        if (events.isEmpty) ...[
          const SizedBox(height: 40),
          Center(child: Text('Tap + to create an event',
            style: GoogleFonts.dmMono(color: muted, fontSize: 13))),
        ] else ...[
          const SizedBox(height: 16),
          _eventBody(events[_sel.clamp(0, events.length - 1)]),
        ],
      ]),
    );
  }

  Widget _eventBody(Event event) {
    final pct = event.cap > 0 ? (event.total / event.cap).clamp(0.0, 1.0) : 0.0;
    final over = event.cap > 0 && event.total > event.cap;
    final paid = event.categories.fold(0.0,
      (s, c) => s + c.items.where((i) => i.paid).fold(0.0, (ss, i) => ss + i.amount));
    final unpaid = event.total - paid;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Name + budget
      Row(children: [
        Expanded(
          child: TextFormField(
            key: ValueKey('evn_${event.name}'),
            initialValue: event.name,
            style: GoogleFonts.playfairDisplay(color: txt, fontSize: 22, fontWeight: FontWeight.w700),
            decoration: InputDecoration(hintText: 'Event name',
              hintStyle: GoogleFonts.playfairDisplay(color: muted, fontSize: 22),
              border: InputBorder.none, isDense: true),
            onChanged: (v) { event.name = v; _save(); },
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('BUDGET', style: GoogleFonts.dmMono(color: muted, fontSize: 9, letterSpacing: 1.5)),
          SizedBox(
            width: 110,
            child: TextFormField(
              key: ValueKey('evc_${event.cap}'),
              initialValue: event.cap == 0 ? '' : event.cap.toStringAsFixed(2),
              style: GoogleFonts.dmMono(color: accent, fontSize: 15),
              decoration: InputDecoration(hintText: '0.00',
                hintStyle: GoogleFonts.dmMono(color: muted), border: InputBorder.none, isDense: true,
                prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: muted)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              onChanged: (v) { event.cap = double.tryParse(v) ?? 0; _save(); },
            )),
        ]),
      ]),

      if (event.cap > 0) ...[
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, backgroundColor: border,
            valueColor: AlwaysStoppedAnimation(over ? accent2 : accent), minHeight: 8)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('\$${event.total.toStringAsFixed(2)} / \$${event.cap.toStringAsFixed(2)}',
            style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
          Text(over ? '⚠ \$${(event.total - event.cap).toStringAsFixed(2)} over'
              : '\$${(event.cap - event.total).toStringAsFixed(2)} left',
            style: GoogleFonts.dmMono(color: over ? accent2 : muted, fontSize: 11)),
        ]),
      ],

      // Paid / unpaid summary
      if (event.total > 0) ...[
        const SizedBox(height: 8),
        Row(children: [
          _miniStat('Paid', paid, green),
          const SizedBox(width: 8),
          _miniStat('Unpaid', unpaid, orange),
          const SizedBox(width: 8),
          _miniStat('Total', event.total, accent),
        ]),
      ],
      const SizedBox(height: 16),

      // Categories
      ...event.categories.asMap().entries.map((e) => _catCard(e.value, e.key, event)),

      OutlinedButton.icon(
        onPressed: () { event.categories.add(EventCategory(name: 'New Category', items: [])); _save(); },
        icon: Icon(Icons.add, color: muted, size: 16),
        label: Text('Add Category', style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: border)),
      ),
      const SizedBox(height: 16),

      _splitCalculator(event),
    ]);
  }

  Widget _miniStat(String label, double val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text('\$${val.toStringAsFixed(2)}', style: GoogleFonts.dmMono(color: color, fontSize: 13)),
        Text(label, style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
      ]),
    ),
  );

  Widget _catCard(EventCategory cat, int catIdx, Event event) {
    return Dismissible(
      key: ValueKey('cat_${event.name}_$catIdx'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
        color: accent2.withOpacity(0.15), child: Icon(Icons.delete, color: accent2, size: 18)),
      onDismissed: (_) { event.categories.removeAt(catIdx); _save(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: surface, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: surface2,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11))),
            child: Row(children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('cn_${event.name}_$catIdx'),
                  initialValue: cat.name,
                  style: GoogleFonts.dmMono(color: orange, fontSize: 12, letterSpacing: 1.5),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  onChanged: (v) { cat.name = v; _save(); },
                ),
              ),
              Text('\$${cat.total.toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(color: muted, fontSize: 12)),
              const SizedBox(width: 8),
              GestureDetector(onTap: () { event.categories.removeAt(catIdx); _save(); },
                child: Icon(Icons.close, color: muted, size: 14)),
            ]),
          ),
          ...cat.items.asMap().entries.map((e) => _itemRow(e.value, e.key, cat)),
          TextButton(
            onPressed: () { cat.items.add(EventItem(label: '', amount: 0)); _save(); },
            child: Text('+ Item', style: GoogleFonts.dmMono(color: muted, fontSize: 12))),
        ]),
      ),
    );
  }

  Widget _itemRow(EventItem item, int idx, EventCategory cat) {
    return Dismissible(
      key: ValueKey('item_${cat.name}_$idx'),
      direction: DismissDirection.endToStart,
      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16),
        color: accent2.withOpacity(0.15), child: Icon(Icons.delete, color: accent2, size: 18)),
      onDismissed: (_) { cat.items.removeAt(idx); _save(); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Row(children: [
          SizedBox(
            width: 24, height: 24,
            child: Checkbox(
              value: item.paid,
              onChanged: (v) { item.paid = v ?? false; _save(); },
              activeColor: green, side: BorderSide(color: muted),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
              key: ValueKey('il_${cat.name}_$idx'),
              initialValue: item.label,
              style: GoogleFonts.dmMono(
                color: item.paid ? muted : txt, fontSize: 13,
                decoration: item.paid ? TextDecoration.lineThrough : null),
              decoration: InputDecoration(hintText: 'Item',
                hintStyle: GoogleFonts.dmMono(color: muted), border: InputBorder.none, isDense: true),
              onChanged: (v) { item.label = v; _save(); },
            ),
          ),
          SizedBox(
            width: 90,
            child: TextFormField(
              key: ValueKey('ia_${cat.name}_$idx'),
              initialValue: item.amount == 0 ? '' : item.amount.toStringAsFixed(2),
              style: GoogleFonts.dmMono(color: item.paid ? muted : txt, fontSize: 13),
              decoration: InputDecoration(hintText: '0.00',
                hintStyle: GoogleFonts.dmMono(color: muted), border: InputBorder.none, isDense: true,
                prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: muted)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              onChanged: (v) { item.amount = double.tryParse(v) ?? 0; _save(); },
            ),
          ),
          GestureDetector(onTap: () { cat.items.removeAt(idx); _save(); },
            child: Padding(padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.close, color: muted, size: 14))),
        ]),
      ),
    );
  }

  Widget _splitCalculator(Event event) {
    if (_splitTotal < 0) _splitTotal = event.total;
    final n = _people.length;
    final even = n > 0 ? _splitTotal / n : 0.0;
    final collected = _people.fold(0.0,
      (s, p) => s + ((p['amount'] as double?) ?? even));
    final balance = collected - _splitTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SPLIT CALCULATOR',
            style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 2)),
          GestureDetector(
            onTap: () => setState(() => _splitTotal = event.total),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(border: Border.all(color: border),
                borderRadius: BorderRadius.circular(4)),
              child: Text('↓ From budget', style: GoogleFonts.dmMono(color: muted, fontSize: 10)))),
        ]),
        const SizedBox(height: 10),

        // Total input
        Row(children: [
          Text('Total  ', style: GoogleFonts.dmMono(color: muted, fontSize: 12)),
          SizedBox(
            width: 120,
            child: TextFormField(
              key: ValueKey('split_total_$_splitTotal'),
              initialValue: _splitTotal.toStringAsFixed(2),
              style: GoogleFonts.dmMono(color: txt, fontSize: 15),
              decoration: InputDecoration(border: InputBorder.none, isDense: true,
                prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: muted)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => setState(() => _splitTotal = double.tryParse(v) ?? _splitTotal),
            )),
          if (n > 0) ...[
            const Spacer(),
            Text('${n} ${n == 1 ? 'person' : 'people'}  ',
              style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
            Text('\$${even.toStringAsFixed(2)} each',
              style: GoogleFonts.dmMono(color: purple, fontSize: 13)),
          ],
        ]),
        const SizedBox(height: 10),

        // People rows
        ..._people.asMap().entries.map((e) {
          final p = e.value;
          final amt = (p['amount'] as double?) ?? even;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(
                child: TextFormField(
                  key: ValueKey('pname_${e.key}'),
                  initialValue: p['name'] as String? ?? '',
                  style: GoogleFonts.dmMono(color: txt, fontSize: 13),
                  decoration: InputDecoration(hintText: 'Person ${e.key + 1}',
                    hintStyle: GoogleFonts.dmMono(color: muted), border: InputBorder.none, isDense: true),
                  onChanged: (v) => setState(() => p['name'] = v),
                ),
              ),
              SizedBox(
                width: 90,
                child: TextFormField(
                  key: ValueKey('pamt_${e.key}_${even.toStringAsFixed(0)}'),
                  initialValue: amt.toStringAsFixed(2),
                  style: GoogleFonts.dmMono(color: accent, fontSize: 13),
                  decoration: InputDecoration(border: InputBorder.none, isDense: true,
                    prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: muted)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  onChanged: (v) => setState(() => p['amount'] = double.tryParse(v) ?? even),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _people.removeAt(e.key)),
                child: Padding(padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, color: muted, size: 14))),
            ]),
          );
        }),

        // Add person + balance
        Row(children: [
          TextButton(
            onPressed: () => setState(() => _people.add({'name': '', 'amount': null})),
            child: Text('+ Add Person', style: GoogleFonts.dmMono(color: muted, fontSize: 12))),
          const Spacer(),
          if (n > 0)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Collected: \$${collected.toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
              Text(
                balance >= 0
                    ? 'Over by \$${balance.toStringAsFixed(2)}'
                    : 'Short \$${(-balance).toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(
                  color: balance.abs() < 0.01 ? green : (balance > 0 ? green : accent2),
                  fontSize: 11)),
            ]),
        ]),
      ]),
    );
  }
}
