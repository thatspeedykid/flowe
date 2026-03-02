import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'models/data.dart';
import 'screens/budget_screen.dart';
import 'screens/snowball_screen.dart';
import 'screens/networth_screen.dart';
import 'screens/events_screen.dart';

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
    Icons.event_note_outlined,
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
      BudgetScreen(data: _cur, onChanged: _save),
      SnowballScreen(data: _cur, onChanged: _save),
      NetWorthScreen(data: _cur, onChanged: _save),
      EventsScreen(data: _cur, onChanged: _save),
    ];

    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final topPad = (Platform.isIOS || Platform.isAndroid)
        ? MediaQuery.of(context).padding.top + 8
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
                padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).padding.bottom + 12),
                child: Column(children: [
                  // Coffee — desktop only, not tablets
                  if (!Platform.isIOS && !Platform.isAndroid) ...[
                    GestureDetector(
                      onTap: () => _openUrl('https://www.paypal.me/Speeddevilx'),
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
          Expanded(child: screens[widget.tab]),
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
        Expanded(child: screens[widget.tab]),
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 6,
            bottom: (Platform.isIOS || Platform.isAndroid)
                ? MediaQuery.of(context).padding.bottom + 6 : 6),
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
                onTap: () => _openUrl('https://www.paypal.me/Speeddevilx'),
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
                events: _cur.events, darkMode: !dark, fontSize: _cur.fontSize));
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
                        events: _cur.events, darkMode: _cur.darkMode, fontSize: entry.$2));
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

          // Export — desktop: file save dialog | mobile: save to Downloads folder
          ListTile(
            leading: Icon(Icons.upload_file, color: muted),
            title: Text('Export Backup', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
            subtitle: Text(
              (Platform.isIOS || Platform.isAndroid)
                ? 'Saves flowe_backup.json to your Downloads'
                : 'Choose where to save your backup',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final json = jsonEncode(_cur.toJson());
                final filename = 'flowe_backup.json';

                if (Platform.isIOS || Platform.isAndroid) {
                  // Use app external storage — no permission needed on Android 10+
                  // Android: visible in Files app under Android/data/com.example.flowe/files
                  // iOS: visible in Files app under On My iPhone > Flowe
                  final docsDir = await getApplicationDocumentsDirectory();
                  final file = File('${docsDir.path}/$filename');
                  await file.writeAsString(json);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      Platform.isAndroid
                        ? 'Saved — open Files app > Android/data/com.example.flowe/files'
                        : 'Saved — open Files app > On My iPhone > Flowe',
                      style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                    backgroundColor: accent, duration: const Duration(seconds: 5)));
                } else {
                  // Desktop: native file save dialog
                  final location = await getSaveLocation(
                    suggestedName: filename,
                    acceptedTypeGroups: [const XTypeGroup(label: 'JSON', extensions: ['json'])],
                  );
                  if (location == null) return;
                  await File(location.path).writeAsString(json);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Saved to ${location.path}',
                      style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                    backgroundColor: accent, duration: const Duration(seconds: 3)));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')));
              }
            }),

          // Import — all platforms: file picker
          ListTile(
            leading: Icon(Icons.download, color: muted),
            title: Text('Import Backup', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
            subtitle: Text('Restore from a flowe_backup.json file',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final file = await openFile(
                  acceptedTypeGroups: [const XTypeGroup(label: 'JSON', extensions: ['json'])],
                );
                if (file == null) return;
                final content = await file.readAsString();
                final imported = FloData.fromJson(jsonDecode(content));
                _save(imported);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Backup imported successfully',
                    style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                  backgroundColor: accent));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Import failed: $e')));
              }
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
              Text('Flowe v1.5.0', style: GoogleFonts.dmMono(color: muted, fontSize: 12)),
              const SizedBox(height: 2),
              Text('Windows · Linux · Android · iOS · macOS',
                style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
              const SizedBox(height: 2),
              Text('MIT License — free & open source',
                style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            ])),
        ]),
      ),
    );
  }
}
