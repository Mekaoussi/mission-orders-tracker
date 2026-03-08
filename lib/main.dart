import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orders_tracker/main_screen.dart';
import 'package:orders_tracker/people_provider.dart';
import 'package:orders_tracker/sortie_provider.dart';
import 'package:orders_tracker/stock_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(PersonAdapter());
  Hive.registerAdapter(SortieItemAdapter());
  Hive.registerAdapter(SortieAdapter());

  // --- FOR DEVELOPMENT: Emergency Database Reset ---
  // This list contains all Hive boxes used in the app.
  // Uncomment the loop to delete all data on app start.
  // Useful if the app crashes due to data corruption.
  // for (final boxName in hiveBoxNames) {
  //   await Hive.deleteBoxFromDisk(boxName);
  // }

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => StockProvider()..init()),
          ChangeNotifierProvider(create: (_) => PeopleProvider()..init()),
          ChangeNotifierProxyProvider2<
            StockProvider,
            PeopleProvider,
            SortieProvider
          >(
            create: (_) => SortieProvider()..init(),
            update: (_, stock, people, sortie) =>
                sortie!..updateDependencies(stock, people),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    );
    final textTheme = baseTextTheme.copyWith(
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 16),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 18),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontSize: 20),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 24),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontSize: 18),
    );

    const primaryColor = Color(0xFF005A8D);
    const secondaryColor = Color(0xFF00A99D);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Gestion de Stock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          background: const Color(0xFFF8F9FA),
          surface: Colors.white,
        ),
        useMaterial3: true,
        textTheme: textTheme,
        iconTheme: const IconThemeData(size: 28),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontSize: 26,
          ),
          iconTheme: const IconThemeData(color: Colors.white, size: 32),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: secondaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          iconSize: 32,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(fontSize: 14),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          contentTextStyle: const TextStyle(
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          labelStyle: const TextStyle(fontSize: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
        listTileTheme: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          iconColor: primaryColor,
          titleTextStyle: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          subtitleTextStyle: textTheme.bodyMedium?.copyWith(
            color: Colors.black54,
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
