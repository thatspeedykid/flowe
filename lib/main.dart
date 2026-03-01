import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'models/data.dart';
import 'screens/budget_screen.dart';
import 'screens/snowball_screen.dart';
import 'screens/networth_screen.dart';
import 'screens/events_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fix blank window on macOS VMware/VirtualBox — disable impeller
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
        // Apply font scale — 15.0 is the baseline (scale = 1.0)
        final scale = (_data.fontSize > 0 ? _data.fontSize : 15.0) / 15.0;
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(
            textScaler: TextScaler.linear(scale)),
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

  // ── File picker (cross-platform, no dependency needed) ───────────────────
  Future<String?> _pickSavePath(BuildContext ctx, String filename) async {
    final ctrl = TextEditingController();
    // Default path
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ?? '';
    final sep = Platform.isWindows ? '\\' : '/';
    ctrl.text = '$home${sep}$filename';

    return showDialog<String>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: _cur.darkMode ? const Color(0xFF1a1a1a) : Colors.white,
        title: Text('Save as', style: GoogleFonts.dmMono(
          color: _cur.darkMode ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17))),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.dmMono(
            color: _cur.darkMode ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17),
            fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Full path to save file',
            hintStyle: GoogleFonts.dmMono(color: const Color(0xFF777777), fontSize: 13),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(
              color: _cur.darkMode ? const Color(0xFF3a3a3a) : const Color(0xFFd4cfc6))),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(
              color: _cur.darkMode ? const Color(0xFFc8f560) : const Color(0xFF5a8a00))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel',
            style: GoogleFonts.dmMono(color: const Color(0xFF777777)))),
          TextButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: Text('Save', style: GoogleFonts.dmMono(
              color: _cur.darkMode ? const Color(0xFFc8f560) : const Color(0xFF5a8a00)))),
        ],
      ),
    );
  }

  Future<String?> _pickOpenPath(BuildContext ctx, String defaultFile) async {
    final ctrl = TextEditingController();
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ?? '';
    final sep = Platform.isWindows ? '\\' : '/';
    ctrl.text = '$home${sep}$defaultFile';

    // Suggest known locations
    final suggestions = Platform.isWindows ? [
      '${Platform.environment['APPDATA'] ?? ''}\\flowe\\data.json',
      '${home}\\flowe_backup.json',
    ] : [
      '$home/.local/share/flowe/data.json',
      '${home}/flowe_backup.json',
    ];

    return showDialog<String>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: _cur.darkMode ? const Color(0xFF1a1a1a) : Colors.white,
        title: Text('Open file', style: GoogleFonts.dmMono(
          color: _cur.darkMode ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17))),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            style: GoogleFonts.dmMono(
              color: _cur.darkMode ? const Color(0xFFe8e8e8) : const Color(0xFF1c1a17),
              fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Full path to file',
              hintStyle: GoogleFonts.dmMono(color: const Color(0xFF777777), fontSize: 13),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(
                color: _cur.darkMode ? const Color(0xFF3a3a3a) : const Color(0xFFd4cfc6))),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(
                color: _cur.darkMode ? const Color(0xFFc8f560) : const Color(0xFF5a8a00))),
            ),
          ),
          const SizedBox(height: 12),
          // Quick-select known paths
          ...suggestions.map((p) => InkWell(
            onTap: () => ctrl.text = p,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Icon(Icons.folder_open, size: 14, color: const Color(0xFF777777)),
                const SizedBox(width: 6),
                Expanded(child: Text(p, style: GoogleFonts.dmMono(
                  color: const Color(0xFF777777), fontSize: 10),
                  overflow: TextOverflow.ellipsis)),
              ]),
            ),
          )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('Cancel',
            style: GoogleFonts.dmMono(color: const Color(0xFF777777)))),
          TextButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: Text('Open', style: GoogleFonts.dmMono(
              color: _cur.darkMode ? const Color(0xFFc8f560) : const Color(0xFF5a8a00)))),
        ],
      ),
    );
  }

  // ── Tab icons ─────────────────────────────────────────────────────────────
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

    // ── Tablet layout: sidebar nav + content ──────────────────────────────
    if (isTablet) {
      return Scaffold(
        backgroundColor: bg,
        body: Row(children: [
          // Left sidebar
          Container(
            width: 200,
            color: surface2,
            child: Column(children: [
              SizedBox(height: topPad),
              // Logo
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
                      child: Image.asset(dark ? 'assets/icon_dark.png' : 'assets/icon.png', fit: BoxFit.cover,
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
              // Nav items
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
                      border: Border.all(
                        color: sel ? accent.withOpacity(0.4) : Colors.transparent)),
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
              // Settings at bottom of sidebar
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8,
                  MediaQuery.of(context).padding.bottom + 12),
                child: GestureDetector(
                  onTap: () => _showSettings(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: border),
                      borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      Icon(Icons.settings_outlined, color: muted, size: 16),
                      const SizedBox(width: 10),
                      Text('Settings', style: GoogleFonts.dmMono(
                        color: muted, fontSize: 12)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          // Vertical divider
          Container(width: 1, color: border),
          // Main content
          Expanded(child: screens[widget.tab]),
        ]),
      );
    }

    // ── Phone layout: top bar + bottom nav ────────────────────────────────
    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [

        // ── Top bar ────────────────────────────────────────────────────────
        Container(
          color: surface2,
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPad, 16, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Icon + Flowe wordmark
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 2),
                    borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(dark ? 'assets/icon_dark.png' : 'assets/icon.png', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.show_chart, color: accent, size: 20)))),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Flowe', style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: accent, fontWeight: FontWeight.w700, height: 1.1)),
                  Text('PERSONAL FINANCE', style: GoogleFonts.dmMono(
                    fontSize: 8, color: muted, letterSpacing: 2)),
                ]),
                const Spacer(),
                // Settings gear — desktop only (mobile has it in bottom bar)
                if (!Platform.isIOS && !Platform.isAndroid)
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: muted, size: 20),
                    onPressed: () => _showSettings(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ]),
            ),
            const SizedBox(height: 8),
            // Tab row with icons
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
                    Text(_tabLabels[i],
                      style: GoogleFonts.dmMono(
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

        // ── Screen ────────────────────────────────────────────────────────
        Expanded(child: screens[widget.tab]),

        // ── Bottom bar — mobile only, settings button ─────────────────────
        if (Platform.isIOS || Platform.isAndroid)
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 6,
              bottom: MediaQuery.of(context).padding.bottom + 6),
            decoration: BoxDecoration(
              color: surface2,
              border: Border(top: BorderSide(color: border))),
            child: Row(children: [
              const Spacer(),
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
                    Text('Settings',
                      style: GoogleFonts.dmMono(color: muted, fontSize: 11)),
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

          // Font size — 3 icon buttons, no slider
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
                        border: Border.all(
                          color: _cur.fontSize == entry.$2 ? accent : border),
                        borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: Text(entry.$1,
                        style: TextStyle(
                          fontSize: entry.$3,
                          fontWeight: FontWeight.bold,
                          color: _cur.fontSize == entry.$2 ? accent : muted)),
                    ),
                  ),
                ),
            ]),
          ),
          Divider(color: border),

          // Export
          ListTile(
            leading: Icon(Icons.upload_file, color: muted),
            title: Text('Export Backup', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
            subtitle: Text('Saves to Downloads — or share via AirDrop, Drive, etc.',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final json = jsonEncode(_cur.toJson());
                final filename = 'flowe_backup.json';

                // All platforms: save to Downloads folder first, then share
                String downloadsPath;
                if (Platform.isWindows) {
                  downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
                } else if (Platform.isMacOS || Platform.isLinux) {
                  downloadsPath = Platform.environment['XDG_DOWNLOAD_DIR'] ??
                      '${Platform.environment['HOME']}/Downloads';
                } else {
                  // iOS/Android: use temp dir then share (no direct Downloads access)
                  final tmp = await getTemporaryDirectory();
                  downloadsPath = tmp.path;
                }

                final dir = Directory(downloadsPath);
                if (!await dir.exists()) await dir.create(recursive: true);
                final path = '$downloadsPath/$filename';
                await File(path).writeAsString(json);

                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Saved to Downloads/$filename',
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
            title: Text('Import Backup', style: GoogleFonts.dmMono(color: txt, fontSize: 14)),
            subtitle: Text('Choose a flowe_backup.json or data.json file',
              style: GoogleFonts.dmMono(color: muted, fontSize: 10)),
            onTap: () async {
              Navigator.pop(ctx);
              final path = await _pickOpenPath(context, 'flowe_backup.json');
              if (path == null || path.isEmpty) return;
              final file = File(path);
              if (!await file.exists()) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File not found: $path',
                    style: GoogleFonts.dmMono())));
                return;
              }
              try {
                final imported = FloData.fromJson(jsonDecode(await file.readAsString()));
                _save(imported);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Imported from $path',
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
