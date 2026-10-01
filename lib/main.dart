import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Controller/Theme.Controller.dart';
import 'package:lanchonete/Controller/usuario_controller.dart';
import 'package:lanchonete/Pages/Fluxo_Caixa_page.dart';
import 'package:lanchonete/Pages/Login_page.dart';
import 'package:flutter/material.dart';
import 'package:lanchonete/Pages/Principal_page.dart';
import 'package:lanchonete/Pages/PrintersConfigPage.dart';
import 'package:provider/provider.dart';

import 'Controller/Tef/paygo_tefcontroller.dart';
import 'Pages/Payment_mode_page.dart';

void main() {
  // Inicializa o TefController com GetX
  Get.put(TefController());

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => ComandaController(),
      ),
      ChangeNotifierProvider(
        create: (context) => UsuarioController(),
      ),
      ChangeNotifierProvider(create: (context) => ThemeController())
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final config = ConfigController.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([
        config.primaryColorHex,
        config.secondaryColorHex,
      ]),
      builder: (context, _) {
        return GetMaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('pt', 'BR'),
          onDispose: () {
            debugPrint("GetMaterialApp onDispose");
            Get.delete<TefController>();
          },
          initialBinding: BindingsBuilder(() {
            Get.put(TefController(), permanent: true);
          }),
          title: config.pdvTitle.value,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: false,
            brightness:
                themeController.isDark ? Brightness.dark : Brightness.light,
            primaryColor: Constants.primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Constants.primaryColor,
              secondary: Constants.secondaryColor,
              brightness:
                  themeController.isDark ? Brightness.dark : Brightness.light,
            ),
            appBarTheme: AppBarTheme(
              color: themeController.isDark
                  ? Colors.black
                  : Constants.primaryColor,
              titleTextStyle: TextStyle(
                color: themeController.isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              centerTitle: true,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            textTheme: TextTheme(
              displayLarge: TextStyle(
                fontSize: 20,
                color: themeController.isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              displayMedium: TextStyle(
                fontSize: 20,
                color: themeController.isDark ? Colors.white : Colors.black,
                fontStyle: FontStyle.italic,
              ),
              displaySmall: TextStyle(
                fontSize: 20,
                color: themeController.isDark ? Colors.white : Colors.black,
                fontStyle: FontStyle.italic,
              ),
              bodyLarge: TextStyle(
                  fontSize: 20,
                  color: themeController.isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold),
              bodyMedium: TextStyle(
                  fontSize: 20,
                  color: themeController.isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold),
              bodySmall: TextStyle(
                fontSize: 20,
                color: themeController.isDark ? Colors.white : Colors.black,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          initialRoute: '/login',
          getPages: [
            GetPage(
              name: '/login',
              page: () => LoginPage(),
            ),
            GetPage(
              name: '/principal',
              page: () => PrincipalPage(paginas: Paginas.categorias),
            ),
            GetPage(
              name: '/payment_mode',
              page: () {
                final args = Get.arguments as Map<String, dynamic>;
                return PaymentModePage(
                  valorPagamento: args['valorPagamento'] as double,
                );
              },
            ),
            GetPage(
              name: '/configImpressoras',
              page: () => PrinterConfigPage(),
            ),
            GetPage(
              name: '/fluxo-caixa',
              page: () => FluxoCaixaPage(),
            ),
          ],
        );
      },
    );
  }
}
