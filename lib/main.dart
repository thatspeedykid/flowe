import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/data.dart';
import 'screens/budget_screen.dart';
import 'screens/snowball_screen.dart';
import 'screens/networth_screen.dart';
import 'screens/events_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  // Always save AND setState so font/theme changes propagate immediately
  void _update(FloData d) {
    setState(() => _data = d);
    FloStorage.save(d);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _data.darkMode;

    return MaterialApp(
      title: 'flo',
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

      home: _FloShell(
        data: _data,
        tab: _tab,
        onTabChange: (t) => setState(() => _tab = t),
        onDataChanged: _update,
      ),
    );
  }
}

// ── Shell is stateful so settings always read latest data ────────────────────
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
  // Keep local copy so settings sheet always reads current value
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
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isMacOS) {
        Process.run('open', [url]);
      } else {
        Process.run('xdg-open', [url]);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dark    = _cur.darkMode;
    final bg       = dark ? const Color(0xFF0f0f0f) : const Color(0xFFf7f5f0);
    final surface2 = dark ? const Color(0xFF222222) : const Color(0xFFeeebe2);
    final border   = dark ? const Color(0xFF2e2e2e) : const Color(0xFFd4cfc6);
    final accent   = dark ? const Color(0xFFc8f560) : const Color(0xFF5a8a00);
    final muted    = dark ? const Color(0xFF777777) : const Color(0xFF7a7060);

    final tabs = ['Budget', 'Snowball', 'Net Worth', 'Events'];
    final screens = [
      BudgetScreen(data: _cur, onChanged: _save),
      SnowballScreen(data: _cur, onChanged: _save),
      NetWorthScreen(data: _cur, onChanged: _save),
      EventsScreen(data: _cur, onChanged: _save),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // ── Top bar ──────────────────────────────────────────────────────
        Container(
          color: surface2,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(children: [
                Text('flo', style: GoogleFonts.playfairDisplay(
                  fontSize: 28, color: accent, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.settings, color: muted, size: 20),
                  onPressed: () => _showSettings(context)),
              ]),
            ),
            Row(children: tabs.asMap().entries.map((e) {
              final sel = e.key == widget.tab;
              return Expanded(child: GestureDetector(
                onTap: () => widget.onTabChange(e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(
                    color: sel ? accent : Colors.transparent, width: 2))),
                  child: Text(e.value, textAlign: TextAlign.center,
                    style: GoogleFonts.dmMono(fontSize: 11, letterSpacing: 1.5,
                      color: sel ? accent : muted, fontWeight: FontWeight.w500)),
                ),
              ));
            }).toList()),
            Divider(height: 1, color: border),
          ]),
        ),

        // ── Screen ───────────────────────────────────────────────────────
        Expanded(child: screens[widget.tab]),

        // ── Bottom bar ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: surface2, border: Border(top: BorderSide(color: border))),
          child: Row(children: [
            const Spacer(),
            GestureDetector(
              onTap: () => _openUrl('https://www.paypal.com/paypalme/speeddevilx'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1a2a0a),
                  border: Border.all(color: accent.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('☕', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text('Buy me a coffee',
                    style: GoogleFonts.dmMono(color: accent, fontSize: 11)),
                ]),
              ),
            ),
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
              style: GoogleFonts.dmMono(color: txt)),
            onTap: () {
              Navigator.pop(ctx);
              _save(FloData(budgets: _cur.budgets, debts: _cur.debts,
                extraPayment: _cur.extraPayment, assets: _cur.assets,
                liabilities: _cur.liabilities, snapshots: _cur.snapshots,
                events: _cur.events, darkMode: !dark, fontSize: _cur.fontSize));
            }),
          Divider(color: border),

          Divider(color: border),

          // Export
          ListTile(
            leading: Icon(Icons.upload_file, color: muted),
            title: Text('Export Backup', style: GoogleFonts.dmMono(color: txt)),
            subtitle: Text('Saves ~/flo_backup.json',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final path = '${Platform.environment['HOME']}/flo_backup.json';
                File(path).writeAsStringSync(jsonEncode(_cur.toJson()));
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Saved to ~/flo_backup.json',
                    style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                  backgroundColor: accent, duration: const Duration(seconds: 3)));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')));
              }
            }),

          // Import
          ListTile(
            leading: Icon(Icons.download, color: muted),
            title: Text('Import Backup', style: GoogleFonts.dmMono(color: txt)),
            subtitle: Text('Loads ~/flo_backup.json or ~/.local/share/flo/data.json',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () async {
              Navigator.pop(ctx);
              final paths = [
                '${Platform.environment['HOME']}/flo_backup.json',
                '${Platform.environment['HOME']}/.local/share/flo/data.json',
              ];
              for (final path in paths) {
                final file = File(path);
                if (await file.exists()) {
                  try {
                    final imported = FloData.fromJson(jsonDecode(await file.readAsString()));
                    _save(imported);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Imported from $path',
                        style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                      backgroundColor: accent));
                    return;
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Import failed: $e')));
                    return;
                  }
                }
              }
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('No backup found. Copy data.json to ~/flo_backup.json',
                  style: GoogleFonts.dmMono())));
            }),
          Divider(color: border),

          // Check for update
          ListTile(
            leading: Icon(Icons.system_update_alt, color: muted),
            title: Text('Check for Update', style: GoogleFonts.dmMono(color: txt)),
            subtitle: Text('Opens latest release on GitHub',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () { Navigator.pop(ctx); _openUrl('https://github.com/thatspeedykid/flo/releases/latest'); }),
          Divider(color: border),

          // GitHub
          ListTile(
            leading: Icon(Icons.code, color: muted),
            title: Text('GitHub', style: GoogleFonts.dmMono(color: txt)),
            subtitle: Text('github.com/thatspeedykid/flo',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () { Navigator.pop(ctx); _openUrl('https://github.com/thatspeedykid/flo'); }),
          Divider(color: border),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('flo v1.4.0', style: GoogleFonts.dmMono(color: muted, fontSize: 12)),
              const SizedBox(height: 2),
              Text('Linux · Windows · Android/iOS coming', style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
              const SizedBox(height: 2),
              Text('MIT License — free & open source', style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            ])),
        ]),
      ),
    );
  }
}
