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

  @override
  void initState() { super.initState(); _data = widget.data; }
  @override
  void didUpdateWidget(EventsScreen old) {
    super.didUpdateWidget(old);
    // Only update data reference, never reset _sel or split people
    _data = widget.data;
  }

  bool get dark    => _data.darkMode;
  Color get accent  => dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
  Color get accent2 => dark ? const Color(0xFFf56060) : const Color(0xFFc0392b);
  Color get surface => dark ? const Color(0xFF1a1a1a) : Colors.white;
  Color get surface2=> dark ? const Color(0xFF222222) : const Color(0xFFeeebe2);
  Color get border  => dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);
  Color get txt     => dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17);
  Color get muted   => dark ? const Color(0xFF777777) : const Color(0xFF7a7060);
  Color get orange  => dark ? const Color(0xFFf5a060) : const Color(0xFFb05000);
  Color get purple  => dark ? const Color(0xFFc060f5) : const Color(0xFF7030a0);
  Color get green   => dark ? const Color(0xFF60f5a0) : const Color(0xFF1a7a40);

  void _save() {
    final u = FloData(
      budgets: _data.budgets, debts: _data.debts,
      extraPayment: _data.extraPayment, assets: _data.assets,
      liabilities: _data.liabilities, snapshots: _data.snapshots,
      events: _data.events, transactions: _data.transactions,
      darkMode: _data.darkMode, fontSize: _data.fontSize);
    setState(() => _data = u);
    widget.onChanged(u);
  }

  Future<bool> _confirm(BuildContext ctx, String msg) async {
    return await showDialog<bool>(
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
  }

  @override
  Widget build(BuildContext context) {
    final events = _data.events;
    final selIdx = _sel.clamp(0, events.isEmpty ? 0 : events.length - 1);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Event selector
        Row(children: [
          Expanded(
            child: events.isEmpty
                ? Text('No events yet', style: GoogleFonts.dmMono(color: muted, fontSize: 15))
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: surface2, border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<int>(
                      value: selIdx,
                      dropdownColor: surface2, underline: const SizedBox(), isExpanded: true,
                      style: GoogleFonts.dmMono(color: txt, fontSize: 15),
                      items: events.asMap().entries.map((e) => DropdownMenuItem(value: e.key,
                        child: Text(e.value.name.isEmpty ? 'Unnamed' : e.value.name,
                          style: GoogleFonts.dmMono(color: txt, fontSize: 15)))).toList(),
                      onChanged: (v) => setState(() { _sel = v ?? 0; }),
                    ))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              _data.events.add(Event(name: 'New Event', cap: 0, categories: []));
              setState(() { _sel = _data.events.length - 1; });
              _save();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(border: Border.all(color: accent), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.add, color: accent, size: 18))),
          if (events.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                if (!await _confirm(context, 'Delete event "${events[selIdx].name}"?')) return;
                _data.events.removeAt(selIdx);
                if (_sel >= _data.events.length && _sel > 0) _sel--;

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
            style: GoogleFonts.dmMono(color: muted, fontSize: 15))),
        ] else ...[
          const SizedBox(height: 16),
          _eventBody(events[selIdx]),
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
      // Event name — uses controller so typing doesn't jump focus
      _EventNameField(
        key: ValueKey('evname_$_sel'),
        initialValue: event.name,
        style: GoogleFonts.playfairDisplay(color: txt, fontSize: 22, fontWeight: FontWeight.w700),
        hintStyle: GoogleFonts.playfairDisplay(color: muted, fontSize: 22),
        onChanged: (v) { event.name = v; _save(); },
        suffix: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('BUDGET', style: GoogleFonts.dmMono(color: muted, fontSize: 9, letterSpacing: 1.5)),
          _EventAmountField(
            key: ValueKey('evcap_$_sel'),
            initialValue: event.cap == 0 ? '' : event.cap.toStringAsFixed(2),
            onChanged: (v) { event.cap = double.tryParse(v) ?? 0; _save(); },
            style: GoogleFonts.dmMono(color: accent, fontSize: 15),
            muted: muted,
          ),
        ]),
      ),

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

      ...event.categories.asMap().entries.map((e) => _catCard(e.value, e.key, event)),

      OutlinedButton.icon(
        onPressed: () { event.categories.add(EventCategory(name: 'New Category', items: [])); _save(); },
        icon: Icon(Icons.add, color: muted, size: 16),
        label: Text('Add Category', style: GoogleFonts.dmMono(color: muted, fontSize: 15)),
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
      key: ValueKey('evcat_${event.hashCode}_$catIdx'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: accent2.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.delete, color: accent2, size: 22)),
      confirmDismiss: (_) async {
        final ok = await _confirm(context, 'Delete category "${cat.name}"?');
        if (ok) { event.categories.removeAt(catIdx); _save(); }
        return false;
      },
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
              child: _CatNameField(
                key: ValueKey('cat_${event.hashCode}_$catIdx'),
                initialValue: cat.name,
                style: GoogleFonts.dmMono(color: orange, fontSize: 13, letterSpacing: 1.5),
                onChanged: (v) { cat.name = v; _save(); },
              ),
            ),
            Text('\$${cat.total.toStringAsFixed(2)}',
              style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                if (!await _confirm(context, 'Delete category "${cat.name}"?')) return;
                event.categories.removeAt(catIdx); _save();
              },
              child: Icon(Icons.close, color: muted, size: 14)),
          ]),
        ),
        ...cat.items.asMap().entries.map((e) => _itemRow(e.value, e.key, cat, event)),
        TextButton(
          onPressed: () { cat.items.add(EventItem(label: '', amount: 0)); _save(); },
          child: Text('+ Item', style: GoogleFonts.dmMono(color: muted, fontSize: 13))),
      ]),
    ),
    );
  }

  Widget _itemRow(EventItem item, int idx, EventCategory cat, Event event) {
    return Dismissible(
      key: ValueKey('evitem_${cat.hashCode}_$idx'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: accent2.withOpacity(0.15),
        child: Icon(Icons.delete, color: accent2, size: 18)),
      confirmDismiss: (_) async {
        final ok = await _confirm(context, 'Delete "${item.label.isEmpty ? 'this item' : item.label}"?');
        if (ok) { cat.items.removeAt(idx); _save(); }
        return false;
      },
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
          child: _ItemLabelField(
            key: ValueKey('il_${event.hashCode}_${cat.name}_$idx'),
            initialValue: item.label,
            paid: item.paid,
            txt: txt, muted: muted,
            onChanged: (v) { item.label = v; _save(); },
          ),
        ),
        _ItemAmountField(
          key: ValueKey('ia_${event.hashCode}_${cat.name}_$idx'),
          initialValue: item.amount == 0 ? '' : item.amount.toStringAsFixed(2),
          paid: item.paid,
          txt: txt, muted: muted,
          onChanged: (v) { item.amount = double.tryParse(v) ?? 0; _save(); },
        ),
        GestureDetector(
          onTap: () async {
            if (!await _confirm(context, 'Delete item "${item.label}"?')) return;
            cat.items.removeAt(idx); _save();
          },
          child: Padding(padding: const EdgeInsets.only(left: 6),
            child: Icon(Icons.close, color: muted, size: 14))),
      ]),
    ),
    );
  }

  Widget _splitCalculator(Event event) {
    // Use persisted splitTotal; 0 means "use event total"
    final splitTotal = event.splitTotal > 0 ? event.splitTotal : event.total;
    final people = event.splitPeople;
    final n = people.length;
    final even = n > 0 ? splitTotal / n : 0.0;
    final collected = people.fold(0.0,
      (s, p) => s + ((p['amount'] as double?) ?? even));
    final balance = collected - splitTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('SPLIT CALCULATOR',
            style: GoogleFonts.dmMono(color: muted, fontSize: 10, letterSpacing: 2)),
          GestureDetector(
            onTap: () { event.splitTotal = event.total; _save(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(border: Border.all(color: border),
                borderRadius: BorderRadius.circular(4)),
              child: Text('↓ From budget', style: GoogleFonts.dmMono(color: muted, fontSize: 10)))),
        ]),
        const SizedBox(height: 10),

        Row(children: [
          Text('Total  ', style: GoogleFonts.dmMono(color: muted, fontSize: 13)),
          SizedBox(
            width: 120,
            child: _SplitTotalField(
              key: ValueKey('stotal_${event.hashCode}'),
              initialValue: splitTotal.toStringAsFixed(2),
              style: GoogleFonts.dmMono(color: txt, fontSize: 15),
              muted: muted,
              onChanged: (v) { event.splitTotal = double.tryParse(v) ?? splitTotal; _save(); },
            )),
          if (n > 0) ...[
            const Spacer(),
            Text('$n ${n == 1 ? 'person' : 'people'}  ',
              style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
            Text('\$${even.toStringAsFixed(2)} each',
              style: GoogleFonts.dmMono(color: purple, fontSize: 13)),
          ],
        ]),
        const SizedBox(height: 10),

        ...people.asMap().entries.map((e) {
          final p = e.value;
          final amt = (p['amount'] as double?) ?? even;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Expanded(
                child: _PersonNameField(
                  key: ValueKey('pname_${event.hashCode}_${e.key}'),
                  initialValue: p['name'] as String? ?? '',
                  hint: 'Person ${e.key + 1}',
                  style: GoogleFonts.dmMono(color: txt, fontSize: 15),
                  muted: muted,
                  onChanged: (v) { p['name'] = v; _save(); },
                ),
              ),
              _PersonAmountField(
                key: ValueKey('pamt_${event.hashCode}_${e.key}'),
                initialValue: amt.toStringAsFixed(2),
                style: GoogleFonts.dmMono(color: accent, fontSize: 13),
                muted: muted,
                onChanged: (v) { p['amount'] = double.tryParse(v) ?? even; _save(); },
              ),
              GestureDetector(
                onTap: () { people.removeAt(e.key); _save(); },
                child: Padding(padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.close, color: muted, size: 14))),
            ]),
          );
        }),

        Row(children: [
          TextButton(
            onPressed: () { people.add({'name': '', 'amount': null}); _save(); },
            child: Text('+ Add Person', style: GoogleFonts.dmMono(color: muted, fontSize: 13))),
          const Spacer(),
          if (n > 0)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Collected: \$${collected.toStringAsFixed(2)}',
                style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
              Text(
                balance.abs() < 0.01 ? '✓ Balanced'
                    : balance > 0 ? 'Over by \$${balance.toStringAsFixed(2)}'
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

// ── Stable text field widgets — prevent focus jumping ─────────────────────────
// Each is a StatefulWidget with its own controller so parent rebuilds
// don't steal focus or reset cursor position.

class _EventNameField extends StatefulWidget {
  final String initialValue;
  final TextStyle style, hintStyle;
  final ValueChanged<String> onChanged;
  final Widget suffix;
  const _EventNameField({super.key, required this.initialValue,
    required this.style, required this.hintStyle,
    required this.onChanged, required this.suffix});
  @override State<_EventNameField> createState() => _EventNameFieldState();
}
class _EventNameFieldState extends State<_EventNameField> {
  late final TextEditingController _c;
  @override void initState() { super.initState(); _c = TextEditingController(text: widget.initialValue); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Row(children: [
    Expanded(child: TextField(controller: _c, style: widget.style,
      decoration: InputDecoration(hintText: 'Event name', hintStyle: widget.hintStyle,
        border: InputBorder.none, isDense: true),
      onChanged: widget.onChanged)),
    widget.suffix,
  ]);
}

class _EventAmountField extends StatefulWidget {
  final String initialValue; final TextStyle style; final Color muted;
  final ValueChanged<String> onChanged;
  const _EventAmountField({super.key, required this.initialValue,
    required this.style, required this.muted, required this.onChanged});
  @override State<_EventAmountField> createState() => _EventAmountFieldState();
}
class _EventAmountFieldState extends State<_EventAmountField> {
  late final TextEditingController _c;
  @override void initState() { super.initState(); _c = TextEditingController(text: widget.initialValue); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SizedBox(width: 110,
    child: TextField(controller: _c, style: widget.style, textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(hintText: '0.00',
        hintStyle: GoogleFonts.dmMono(color: widget.muted),
        border: InputBorder.none, isDense: true,
        prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: widget.muted)),
      onChanged: widget.onChanged));
}

class _CatNameField extends StatefulWidget {
  final String initialValue; final TextStyle style; final ValueChanged<String> onChanged;
  const _CatNameField({super.key, required this.initialValue, required this.style, required this.onChanged});
  @override State<_CatNameField> createState() => _CatNameFieldState();
}
class _CatNameFieldState extends State<_CatNameField> {
  late final TextEditingController _c;
  @override void initState() { super.initState(); _c = TextEditingController(text: widget.initialValue); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => TextField(controller: _c, style: widget.style,
    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
    onChanged: widget.onChanged);
}

class _ItemLabelField extends StatefulWidget {
  final String initialValue; final bool paid;
  final Color txt, muted; final ValueChanged<String> onChanged;
  const _ItemLabelField({super.key, required this.initialValue, required this.paid,
    required this.txt, required this.muted, required this.onChanged});
  @override State<_ItemLabelField> createState() => _ItemLabelFieldState();
}
class _ItemLabelFieldState extends State<_ItemLabelField> {
  late final TextEditingController _c;
  @override void initState() { super.initState(); _c = TextEditingController(text: widget.initialValue); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => TextField(controller: _c,
    style: GoogleFonts.dmMono(color: widget.paid ? widget.muted : widget.txt, fontSize: 13,
      decoration: widget.paid ? TextDecoration.lineThrough : null),
    decoration: InputDecoration(hintText: 'Item',
      hintStyle: GoogleFonts.dmMono(color: widget.muted), border: InputBorder.none, isDense: true),
    onChanged: widget.onChanged);
}

class _ItemAmountField extends StatefulWidget {
  final String initialValue; final bool paid;
  final Color txt, muted; final ValueChanged<String> onChanged;
  const _ItemAmountField({super.key, required this.initialValue, required this.paid,
    required this.txt, required this.muted, required this.onChanged});
  @override State<_ItemAmountField> createState() => _ItemAmountFieldState();
}
class _ItemAmountFieldState extends State<_ItemAmountField> {
  late final TextEditingController _c;
  @override void initState() { super.initState(); _c = TextEditingController(text: widget.initialValue); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SizedBox(width: 90,
    child: TextField(controller: _c, textAlign: TextAlign.right,
      style: GoogleFonts.dmMono(color: widget.paid ? widget.muted : widget.txt, fontSize: 13),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(hintText: '0.00',
        hintStyle: GoogleFonts.dmMono(color: widget.muted), border: InputBorder.none, isDense: true,
        prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: widget.muted)),
      onChanged: widget.onChanged));
}

class _SplitTotalField extends StatefulWidget {
  final String initialValue; final TextStyle style; final Color muted;
  final ValueChanged<String> onChanged;
  const _SplitTotalField({super.key, required this.initialValue,
    required this.style, required this.muted, required this.onChanged});
  @override State<_SplitTotalField> createState() => _SplitTotalFieldState();
}
class _SplitTotalFieldState extends State<_SplitTotalField> {
  late final TextEditingController _c;
  bool _focused = false;
  @override void initState() { super.initState(); _c = TextEditingController(text: widget.initialValue); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override void didUpdateWidget(_SplitTotalField old) {
    super.didUpdateWidget(old);
    if (!_focused && widget.initialValue != old.initialValue) {
      _c.text = widget.initialValue;
    }
  }
  @override Widget build(BuildContext context) => Focus(
    onFocusChange: (f) => setState(() => _focused = f),
    child: TextField(controller: _c, style: widget.style,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(border: InputBorder.none, isDense: true,
        prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: widget.muted)),
      onChanged: widget.onChanged));
}

class _PersonNameField extends StatefulWidget {
  final String initialValue, hint; final TextStyle style; final Color muted;
  final ValueChanged<String> onChanged;
  const _PersonNameField({super.key, required this.initialValue, required this.hint,
    required this.style, required this.muted, required this.onChanged});
  @override State<_PersonNameField> createState() => _PersonNameFieldState();
}
class _PersonNameFieldState extends State<_PersonNameField> {
  late final TextEditingController _c;
  @override void initState() { super.initState(); _c = TextEditingController(text: widget.initialValue); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => TextField(controller: _c, style: widget.style,
    decoration: InputDecoration(hintText: widget.hint,
      hintStyle: GoogleFonts.dmMono(color: widget.muted), border: InputBorder.none, isDense: true),
    onChanged: widget.onChanged);
}

class _PersonAmountField extends StatefulWidget {
  final String initialValue; final TextStyle style; final Color muted;
  final ValueChanged<String> onChanged;
  const _PersonAmountField({super.key, required this.initialValue,
    required this.style, required this.muted, required this.onChanged});
  @override State<_PersonAmountField> createState() => _PersonAmountFieldState();
}
class _PersonAmountFieldState extends State<_PersonAmountField> {
  late final TextEditingController _c;
  @override void initState() { super.initState(); _c = TextEditingController(text: widget.initialValue); }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SizedBox(width: 90,
    child: TextField(controller: _c, textAlign: TextAlign.right,
      style: widget.style,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(border: InputBorder.none, isDense: true,
        prefixText: '\$', prefixStyle: GoogleFonts.dmMono(color: widget.muted)),
      onChanged: widget.onChanged));
}
