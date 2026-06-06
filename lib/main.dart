import 'package:get/get.dart';
import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Controller/Theme.Controller.dart';
import 'package:lanchonete/Controller/usuario_controller.dart';
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
    return GetMaterialApp(
      onDispose: () {
        debugPrint("GetMaterialApp onDispose");
        Get.delete<TefController>();
      },
      initialBinding: BindingsBuilder(() {
        Get.put(TefController(), permanent: true);
      }),
      title: 'Lanchonete',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        brightness: themeController.isDark ? Brightness.dark : Brightness.light,
        primaryColor: Constants.primaryColor,
        appBarTheme: AppBarTheme(
          color: themeController.isDark ? Colors.black : Constants.primaryColor,
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
      ],
    );
  }
}
