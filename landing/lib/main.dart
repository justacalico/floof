import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const LandingApp());

const gitlabRepo = 'https://gitlab.com/HttpAnimations/floof';
const githubRepo = 'https://github.com/justacalico/floof';
const releasesApi =
    'https://gitlab.com/api/v4/projects/87653105/releases';
const releasesPage = '$gitlabRepo/-/releases';
const webApp = '/floof/app/';
const flatpakRepo = '/floof/flatpak';
const altstore =
    'https://gitlab.com/HttpAnimations/floof/-/raw/main/repos/altstore.json';

class LandingApp extends StatefulWidget {
  const LandingApp({super.key});

  @override
  State<LandingApp> createState() => _LandingAppState();
}

class _LandingAppState extends State<LandingApp> {
  ThemeMode _mode = ThemeMode.system;
  bool _oled = false;

  ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = _oled && dark ? Colors.black : null;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFFFB347),
        brightness: b,
      ).copyWith(surface: bg),
      scaffoldBackgroundColor: bg,
      fontFamily: 'Inter',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'floof',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: _mode,
      home: LandingPage(
        mode: _mode,
        oled: _oled,
        onMode: (m) => setState(() => _mode = m),
        onOled: (v) => setState(() => _oled = v),
      ),
    );
  }
}

class Release {
  final String tag;
  final String url;
  const Release(this.tag, this.url);
}

class LandingPage extends StatefulWidget {
  final ThemeMode mode;
  final bool oled;
  final ValueChanged<ThemeMode> onMode;
  final ValueChanged<bool> onOled;

  const LandingPage({
    super.key,
    required this.mode,
    required this.oled,
    required this.onMode,
    required this.onOled,
  });

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  List<Release>? _releases;
  bool _releasesFailed = false;

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    try {
      final res =
          await http.get(Uri.parse(releasesApi)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw StateError('${res.statusCode}');
      final list = jsonDecode(res.body) as List<dynamic>;
      setState(() {
        _releases = list
            .map((r) {
              final m = r as Map<String, dynamic>;
              final links = (m['assets']?['links'] as List?) ?? [];
              return Release(
                '${m['tag_name']}',
                links.isNotEmpty
                    ? '${links.first['url']}'
                    : '$releasesPage/${m['tag_name']}',
              );
            })
            .toList();
      });
    } catch (_) {
      setState(() => _releasesFailed = true);
    }
  }

  void _open(String url) => launchUrl(Uri.parse(url));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer,
                    scheme.surface,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Image.asset('assets/icon.png', width: 96, height: 96),
                  const SizedBox(height: 16),
                  Text('floof',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 12),
                  Text(
                    'An e926 video client with a feed that learns what you like, on your device.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Downloads'),
                        onPressed: () => _open(releasesPage),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.public),
                        label: const Text('Try it in the browser'),
                        onPressed: () => _open(webApp),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.code),
                        label: const Text('Source'),
                        onPressed: () => _open(gitlabRepo),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _shot('goldens/home.png', 'Home'),
                  _shot('goldens/search.png', 'Search'),
                  _shot('goldens/history.png', 'History'),
                  _shot('goldens/settings.png', 'Settings'),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Get floof',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    _dl(Icons.phone_android, 'Android',
                        'APK and AAB on each release', releasesPage),
                    _dl(Icons.desktop_windows, 'Linux',
                        'tar.gz, deb, rpm, AppImage and Flatpak', releasesPage),
                    _dl(Icons.luggage, 'Flatpak',
                        'Add the repo: flatpak remote-add floof https://httpanimations.gitlab.io$flatpakRepo',
                        'https://httpanimations.gitlab.io$flatpakRepo/floof.flatpakref'),
                    _dl(Icons.apple, 'iOS (AltStore/SideStore)',
                        'Add the source then install the IPA', altstore),
                    _dl(Icons.laptop_mac, 'macOS and Windows',
                        'Zips on each release', releasesPage),
                    const SizedBox(height: 24),
                    Text('Latest releases',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_releases == null && !_releasesFailed)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )
                    else if (_releasesFailed || _releases!.isEmpty)
                      TextButton(
                        onPressed: () => _open(releasesPage),
                        child: const Text('See all releases on GitLab'),
                      )
                    else
                      ..._releases!.take(5).map(
                            (r) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.new_releases),
                              title: Text(r.tag),
                              onTap: () => _open(r.url),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode)),
                      ButtonSegment(
                          value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {widget.mode},
                    onSelectionChanged: (s) => widget.onMode(s.first),
                  ),
                  const SizedBox(height: 8),
                  FilterChip(
                    label: const Text('OLED black'),
                    selected: widget.oled,
                    onSelected: widget.onOled,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    children: [
                      TextButton(
                          onPressed: () => _open(gitlabRepo),
                          child: const Text('GitLab')),
                      TextButton(
                          onPressed: () => _open(githubRepo),
                          child: const Text('GitHub mirror')),
                      TextButton(
                          onPressed: () => _open(webApp),
                          child: const Text('Web app')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('AGPL-3.0',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shot(String src, String label) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            src,
            width: 240,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => Container(
              width: 240,
              height: 150,
              color: Colors.grey.shade800,
              child: const Icon(Icons.image, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _dl(IconData icon, String title, String sub, String url) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(sub),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _open(url),
    );
  }
}
