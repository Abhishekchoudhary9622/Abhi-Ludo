import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_theme.dart';
import 'core/stats/stats_repository.dart';
import 'features/home/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StatsRepository.instance.init();
  _registerFontLicenses();
  runApp(const ProviderScope(child: AbhiLudoApp()));
}

/// Registers the bundled Fredoka/Nunito OFL licenses with Flutter's LicenseRegistry.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final fredoka = await rootBundle.loadString('assets/fonts/Fredoka-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Fredoka'], fredoka);
    final nunito = await rootBundle.loadString('assets/fonts/Nunito-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], nunito);
  });
}

/// Root widget for Abhi Ludo.
class AbhiLudoApp extends StatelessWidget {
  const AbhiLudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abhi Ludo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
