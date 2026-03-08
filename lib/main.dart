import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:orders_tracker/main_screen.dart';
import 'package:orders_tracker/people_provider.dart';
import 'package:orders_tracker/sortie_provider.dart';
import 'package:orders_tracker/stock_provider.dart';
import 'package:provider/provider.dart';

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
      enabled: !kReleaseMode,
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
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Stock Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
