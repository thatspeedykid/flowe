import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import 'models/data.dart';
import 'screens/budget_screen.dart';
import 'screens/snowball_screen.dart';
import 'screens/networth_screen.dart';
import 'screens/events_screen.dart';
import 'screens/track_screen.dart';

// Platform channel for Android MediaStore Downloads access
const _platform = MethodChannel('com.flowe/storage');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }
  final data = await FloStorage.load();
  runApp(FloApp(initialData: data));
}

class FloApp extends StatefulWidget {
  final FloData initialData;
  const FloApp({super.key, required this.initialData});
  @override
  State<FloApp> createState() => _FloAppState();
}

class _FloAppState extends State<FloApp> {
  late FloData _data;
  int _tab = 0;

  @override
  void initState() { super.initState(); _data = widget.initialData; }

  void _update(FloData d) {
    setState(() => _data = d);
    FloStorage.save(d);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _data.darkMode;
    return MaterialApp(
      title: 'Flowe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: dark
            ? const ColorScheme.dark(surface: Color(0xFF1a1a1a), primary: Color(0xFFc8f560))
            : const ColorScheme.light(surface: Color(0xFFffffff), primary: Color(0xFF5a8a00)),
        scaffoldBackgroundColor: dark ? const Color(0xFF0f0f0f) : const Color(0xFFf7f5f0),
        textTheme: GoogleFonts.dmMonoTextTheme().apply(
          bodyColor:    dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17),
          displayColor: dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17),
        ),
        useMaterial3: true,
      ),
      builder: (ctx, child) {
        final scale = (_data.fontSize > 0 ? _data.fontSize : 15.0) / 15.0;
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!);
      },
      home: _FloShell(
        data: _data,
        tab: _tab,
        onTabChange: (t) => setState(() => _tab = t),
        onDataChanged: _update,
      ),
    );
  }
}

class _FloShell extends StatefulWidget {
  final FloData data;
  final int tab;
  final ValueChanged<int> onTabChange;
  final ValueChanged<FloData> onDataChanged;
  const _FloShell({required this.data, required this.tab,
    required this.onTabChange, required this.onDataChanged});
  @override
  State<_FloShell> createState() => _FloShellState();
}

class _FloShellState extends State<_FloShell> {
  late FloData _cur;

  @override
  void initState() { super.initState(); _cur = widget.data; }
  @override
  void didUpdateWidget(_FloShell old) { super.didUpdateWidget(old); _cur = widget.data; }

  void _save(FloData d) {
    setState(() => _cur = d);
    widget.onDataChanged(d);
  }

  void _openUrl(String url) {
    try {
      if (Platform.isWindows) Process.run('cmd', ['/c', 'start', '', url]);
      else if (Platform.isMacOS) Process.run('open', [url]);
      else Process.run('xdg-open', [url]);
    } catch (_) {}
  }

  static const _tabIcons = [
    Icons.account_balance_wallet_outlined,
    Icons.ac_unit,
    Icons.show_chart,
    Icons.calendar_month_outlined,
  ];
  static const _tabLabels = ['Budget', 'Snowball', 'Net Worth', 'Events'];

  @override
  Widget build(BuildContext context) {
    final dark    = _cur.darkMode;
    final bg      = dark ? const Color(0xFF0f0f0f) : const Color(0xFFf7f5f0);
    final surface2= dark ? const Color(0xFF1e1e1e) : const Color(0xFFeeebe2);
    final border  = dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);
    final accent  = dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
    final muted   = dark ? const Color(0xFF666666) : const Color(0xFF7a7060);

    final screens = [
      BudgetShell(data: _cur, onChanged: _save),
      SnowballScreen(data: _cur, onChanged: _save),
      NetWorthScreen(data: _cur, onChanged: _save),
      EventsScreen(data: _cur, onChanged: _save),
    ];

    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final topPad = (Platform.isIOS || Platform.isAndroid)
        ? MediaQuery.of(context).viewPadding.top + 8
        : 10.0;

    // ── Tablet / desktop sidebar layout ───────────────────────────────────
    if (isTablet) {
      return Scaffold(
        backgroundColor: bg,
        body: Row(children: [
          Container(
            width: 200,
            color: surface2,
            child: Column(children: [
              SizedBox(height: topPad),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: accent, width: 2),
                      borderRadius: BorderRadius.circular(9)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(dark ? 'assets/icon_dark.png' : 'assets/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.show_chart, color: accent, size: 22)))),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Flowe', style: GoogleFonts.playfairDisplay(
                      fontSize: 20, color: accent, fontWeight: FontWeight.w700, height: 1.1)),
                    Text('PERSONAL FINANCE', style: GoogleFonts.dmMono(
                      fontSize: 7, color: muted, letterSpacing: 1.5)),
                  ]),
                ]),
              ),
              Divider(color: border, height: 1),
              const SizedBox(height: 8),
              ...List.generate(_tabLabels.length, (i) {
                final sel = i == widget.tab;
                return GestureDetector(
                  onTap: () => widget.onTabChange(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? accent.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? accent.withOpacity(0.4) : Colors.transparent)),
                    child: Row(children: [
                      Icon(_tabIcons[i], size: 16, color: sel ? accent : muted),
                      const SizedBox(width: 10),
                      Text(_tabLabels[i], style: GoogleFonts.dmMono(
                        fontSize: 12, letterSpacing: 0.5,
                        color: sel ? accent : muted,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ]),
                  ),
                );
              }),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).viewPadding.bottom + 12),
                child: Column(children: [
                  // Coffee — desktop only, not tablets
                  if (!Platform.isIOS && !Platform.isAndroid) ...[
                    GestureDetector(
                      onTap: () => _openUrl('https://buymeacoffee.com/privacychase'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF1a2a0a) : const Color(0xFFe8f5c8),
                          border: Border.all(color: accent.withOpacity(0.35)),
                          borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Text('☕', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Text('Buy me a coffee',
                            style: GoogleFonts.dmMono(color: accent, fontSize: 11)),
                        ]),
                      )),
                    const SizedBox(height: 8),
                  ],
                  GestureDetector(
                    onTap: () => _showSettings(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.settings_outlined, color: muted, size: 16),
                        const SizedBox(width: 10),
                        Text('Settings', style: GoogleFonts.dmMono(color: muted, fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          Container(width: 1, color: border),
          Expanded(
            child: Column(children: [
              SizedBox(height: (Platform.isIOS || Platform.isAndroid)
                  ? MediaQuery.of(context).viewPadding.top : 0),
              Expanded(child: IndexedStack(index: widget.tab, children: screens)),
            ]),
          ),
        ]),
      );
    }

    // ── Phone layout ──────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        Container(
          color: surface2,
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPad, 16, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 2),
                    borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(dark ? 'assets/icon_dark.png' : 'assets/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.show_chart, color: accent, size: 20)))),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Flowe', style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: accent, fontWeight: FontWeight.w700, height: 1.1)),
                  Text('PERSONAL FINANCE', style: GoogleFonts.dmMono(
                    fontSize: 8, color: muted, letterSpacing: 2)),
                ]),
                const Spacer(),
                if (!Platform.isIOS && !Platform.isAndroid)
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: muted, size: 20),
                    onPressed: () => _showSettings(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: List.generate(_tabLabels.length, (i) {
              final sel = i == widget.tab;
              return Expanded(child: GestureDetector(
                onTap: () => widget.onTabChange(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(
                    color: sel ? accent : Colors.transparent, width: 2))),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_tabIcons[i], size: 16, color: sel ? accent : muted),
                    const SizedBox(height: 3),
                    Text(_tabLabels[i], style: GoogleFonts.dmMono(
                      fontSize: 9, letterSpacing: 1.2,
                      color: sel ? accent : muted,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              ));
            })),
            Divider(height: 1, color: border),
          ]),
        ),
        Expanded(child: IndexedStack(index: widget.tab, children: screens)),
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 6,
            bottom: (Platform.isIOS || Platform.isAndroid)
                ? MediaQuery.of(context).viewPadding.bottom + 8 : 6),
          decoration: BoxDecoration(
            color: surface2,
            border: Border(top: BorderSide(color: border))),
          child: Row(children: [
            const Spacer(),
            if (Platform.isIOS || Platform.isAndroid)
              GestureDetector(
                onTap: () => _showSettings(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: border),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.settings_outlined, color: muted, size: 14),
                    const SizedBox(width: 6),
                    Text('Settings', style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
                  ]),
                ))
            else
              GestureDetector(
                onTap: () => _openUrl('https://buymeacoffee.com/privacychase'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF1a2a0a) : const Color(0xFFe8f5c8),
                    border: Border.all(color: accent.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('☕', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text('Buy me a coffee',
                      style: GoogleFonts.dmMono(color: accent, fontSize: 10)),
                  ]),
                )),
          ]),
        ),
      ]),
    );
  }

  void _showSettings(BuildContext ctx) {
    final dark    = _cur.darkMode;
    final accent  = dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
    final muted   = dark ? const Color(0xFF777777) : const Color(0xFF7a7060);
    final txt     = dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17);
    final bgColor = dark ? const Color(0xFF1a1a1a) : const Color(0xFFffffff);
    final border  = dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Text('SETTINGS',
            style: GoogleFonts.dmMono(color: muted, fontSize: 11, letterSpacing: 2))),
          const SizedBox(height: 8),

          // Theme
          ListTile(
            leading: Icon(dark ? Icons.light_mode : Icons.dark_mode, color: accent),
            title: Text(dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
            onTap: () {
              Navigator.pop(ctx);
              _save(FloData(budgets: _cur.budgets, debts: _cur.debts,
                extraPayment: _cur.extraPayment, assets: _cur.assets,
                liabilities: _cur.liabilities, snapshots: _cur.snapshots,
                events: _cur.events, transactions: _cur.transactions,
                darkMode: !dark, fontSize: _cur.fontSize));
            }),
          Divider(color: border),

          // Font size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Icon(Icons.format_size, color: muted, size: 18),
              const SizedBox(width: 10),
              Text('Text Size', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
              const Spacer(),
              for (final entry in [('A', 13.0, 13.0), ('A', 15.0, 15.0), ('A', 18.0, 18.0)])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _save(FloData(budgets: _cur.budgets, debts: _cur.debts,
                        extraPayment: _cur.extraPayment, assets: _cur.assets,
                        liabilities: _cur.liabilities, snapshots: _cur.snapshots,
                        events: _cur.events, transactions: _cur.transactions,
                        darkMode: _cur.darkMode, fontSize: entry.$2));
                    },
                    child: Container(
                      width: 40, height: 36,
                      decoration: BoxDecoration(
                        color: _cur.fontSize == entry.$2 ? accent.withOpacity(0.15) : Colors.transparent,
                        border: Border.all(color: _cur.fontSize == entry.$2 ? accent : border),
                        borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: Text(entry.$1, style: TextStyle(
                        fontSize: entry.$3, fontWeight: FontWeight.bold,
                        color: _cur.fontSize == entry.$2 ? accent : muted)),
                    ),
                  ),
                ),
            ]),
          ),
          Divider(color: border),

          // Export Backup — copy a single encoded line to clipboard
          ListTile(
            leading: Icon(Icons.copy, color: muted),
            title: Text('Copy Backup', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
            subtitle: Text('Copies a single line — paste it anywhere to save',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () {
              Navigator.pop(ctx);
              try {
                final json = jsonEncode(_cur.toJson());
                final compressed = GZipCodec().encode(utf8.encode(json));
                final line = 'FLOWE2:${base64.encode(Uint8List.fromList(compressed))}';
                Clipboard.setData(ClipboardData(text: line));
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Backup copied! Paste it in Notes, email, anywhere safe.',
                    style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                  backgroundColor: accent, duration: const Duration(seconds: 4)));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backup failed: $e')));
              }
            }),

          // Import Backup — paste the line back
          ListTile(
            leading: Icon(Icons.restore, color: muted),
            title: Text('Paste & Restore', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
            subtitle: Text('Paste your backup line to restore all data',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () {
              Navigator.pop(ctx);
              final controller = TextEditingController();
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: dark ? const Color(0xFF1a1a1a) : Colors.white,
                  title: Text('Paste Backup', style: GoogleFonts.dmMono(
                    color: dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17))),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Paste your FLOWE1:... backup line below:',
                      style: GoogleFonts.dmMono(
                        color: dark ? const Color(0xFF777777) : const Color(0xFF7a7060),
                        fontSize: 12)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      style: GoogleFonts.dmMono(fontSize: 11,
                        color: dark ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17)),
                      decoration: InputDecoration(
                        hintText: 'FLOWE1:...',
                        hintStyle: GoogleFonts.dmMono(
                          color: dark ? const Color(0xFF555555) : const Color(0xFFaaaaaa),
                          fontSize: 11),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6))),
                        filled: true,
                        fillColor: dark ? const Color(0xFF222222) : const Color(0xFFf5f5f0)),
                    ),
                  ]),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text('Cancel', style: GoogleFonts.dmMono(
                        color: dark ? const Color(0xFF777777) : const Color(0xFF7a7060)))),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        try {
                          final input = controller.text.trim();
                          final inputUpper = input.toUpperCase();
                          FloData imported;
                          try {
                            if (inputUpper.startsWith('FLOWE2:')) {
                              // gzip + base64 (current format)
                              final compressed = base64.decode(input.substring(7));
                              final jsonBytes = GZipCodec().decode(compressed);
                              imported = FloData.fromJson(jsonDecode(utf8.decode(jsonBytes)));
                            } else if (inputUpper.startsWith('FLOWE1:')) {
                              // legacy XOR format
                              final xored = base64.decode(input.substring(7));
                              final key = 'flowe-backup-key-v1';
                              final keyBytes = utf8.encode(key);
                              final bytes = Uint8List(xored.length);
                              for (int i = 0; i < xored.length; i++) {
                                bytes[i] = xored[i] ^ keyBytes[i % keyBytes.length];
                              }
                              imported = FloData.fromJson(jsonDecode(utf8.decode(bytes)));
                            } else {
                              // try plain base64 or raw json as last resort
                              try {
                                final decoded = base64.decode(input);
                                imported = FloData.fromJson(jsonDecode(utf8.decode(decoded)));
                              } catch (_) {
                                imported = FloData.fromJson(jsonDecode(input));
                              }
                            }
                          } catch (decodeErr) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Restore failed: $decodeErr'),
                                duration: const Duration(seconds: 6)));
                            return;
                          }
                          _save(imported);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Restored successfully!',
                              style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                            backgroundColor: accent));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Restore failed: $e'),
                              duration: const Duration(seconds: 6)));
                        }
                      },
                      child: Text('Restore', style: GoogleFonts.dmMono(
                        color: dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00)))),
                  ],
                ),
              );
            }),
          Divider(color: border),

          // Check for update + GitHub — desktop only
          if (!Platform.isIOS && !Platform.isAndroid) ...[
            ListTile(
              leading: Icon(Icons.system_update_alt, color: muted),
              title: Text('Check for Update', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
              subtitle: Text('Opens latest release on GitHub',
                style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
              onTap: () { Navigator.pop(ctx); _openUrl('https://github.com/thatspeedykid/flowe/releases/latest'); }),
            ListTile(
              leading: Icon(Icons.code, color: muted),
              title: Text('GitHub', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
              subtitle: Text('github.com/thatspeedykid/flowe',
                style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
              onTap: () { Navigator.pop(ctx); _openUrl('https://github.com/thatspeedykid/flowe'); }),
            Divider(color: border),
          ],

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Flowe v1.7.5', style: GoogleFonts.dmMono(color: muted, fontSize: 12)),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _openUrl('https://privacychase.com'),
                child: Text('privacychase.com',
                  style: GoogleFonts.dmMono(color: muted, fontSize: 10,
                    decoration: TextDecoration.underline)),
              ),
              const SizedBox(height: 2),
              Text('MIT License — free & open source',
                style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            ])),
        ]),
      ),
    );
  }
}

// ── BudgetShell — hosts Budget + Transactions as sub-tabs ──────────────────
class BudgetShell extends StatefulWidget {
  final FloData data;
  final ValueChanged<FloData> onChanged;
  const BudgetShell({super.key, required this.data, required this.onChanged});
  @override
  State<BudgetShell> createState() => _BudgetShellState();
}

class _BudgetShellState extends State<BudgetShell> {
  int _sub = 0; // 0 = Budget, 1 = Transactions

  @override
  Widget build(BuildContext context) {
    final dark    = widget.data.darkMode;
    final accent  = dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
    final muted   = dark ? const Color(0xFF777777) : const Color(0xFF7a7060);
    final surface2= dark ? const Color(0xFF222222) : const Color(0xFFeeebe2);
    final border  = dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);

    final subScreens = [
      BudgetScreen(data: widget.data, onChanged: widget.onChanged),
      TrackScreen(data: widget.data, onChanged: widget.onChanged),
    ];
    final subLabels = ['Budget', 'Transactions'];
    final subIcons  = [Icons.account_balance_wallet_outlined, Icons.receipt_long_outlined];

    return Column(children: [
      Container(
        color: surface2,
        child: Row(children: List.generate(2, (i) {
          final sel = i == _sub;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _sub = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(
                color: sel ? accent : Colors.transparent, width: 2))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(subIcons[i], size: 14, color: sel ? accent : muted),
                const SizedBox(width: 6),
                Text(subLabels[i], style: GoogleFonts.dmMono(
                  fontSize: 11, letterSpacing: 0.8,
                  color: sel ? accent : muted,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          ));
        })),
      ),
      Container(height: 1, color: border),
      Expanded(child: subScreens[_sub]),
    ]);
  }
}
