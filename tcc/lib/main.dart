import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tcc/screens/screen_login.dart';
import 'package:tcc/screens/screen_register.dart';
import 'package:tcc/screens/screen_tabs.dart';
import 'firebase_options.dart';
import 'utils/app-routes.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('pt_BR', null);

  runApp(FinanceiroApp());
}

class FinanceiroApp extends StatefulWidget {
  const FinanceiroApp({super.key});

  @override
  State<FinanceiroApp> createState() => _FinanceiroAppState();
}

class _FinanceiroAppState extends State<FinanceiroApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('pt', 'BR')],
      theme: ThemeData(
        fontFamily: 'Rubik',
        canvasColor: Color.fromRGBO(255, 254, 229, 1),
        primarySwatch: Colors.blue,
        textTheme: ThemeData.light().textTheme.copyWith(
              titleLarge: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 20,
              ),
              titleMedium: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 18,
              ),
            ),
        colorScheme: ThemeData.light().colorScheme.copyWith(
              primary: Color.fromRGBO(78, 105, 130, 1.0),
              secondary: Color.fromRGBO(64, 86, 101, 1),
              tertiary: Color.fromRGBO(108, 143, 177, 1),
            ),
      ),
      initialRoute: AppRoutes.HOME,
      routes: {
        AppRoutes.HOME: (ctx) => ScreenLogin(),
        AppRoutes.INICIAL: (ctx) => ScreenTabs(),
        AppRoutes.LOGIN: (ctx) => ScreenLogin(),
        AppRoutes.REGISTRO: (ctx) => const ScreenRegister(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Inicial"),
      ),
    );
  }
}
