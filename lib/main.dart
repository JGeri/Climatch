import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/weather/application/weather_controller.dart';
import 'home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherController()..init(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Use GolosText as the default font for the entire app
          fontFamily: 'GolosText',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Home(),
      ),
    );
  }
}
