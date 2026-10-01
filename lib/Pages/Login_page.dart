import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Controller/usuario_controller.dart';
import 'package:lanchonete/Pages/Config_page.dart';
import 'package:lanchonete/Pages/Principal_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lanchonete/Services/Local_storage.Service.dart';
import 'package:provider/provider.dart';

import '../Components/customDropDown.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final controllerSenha = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _usuarioSelecionado;

  // Controle para exibir/ocultar a senha
  bool _obscurePassword = true;
  bool _isLogando = false;

  // Função para transformar o Hexadecimal do ConfigController em Color
  Color _getDynamicColor(String hexString, Color fallbackColor) {
    final cleaned = hexString.trim().replaceAll('#', '').toUpperCase();
    if (cleaned.isEmpty) return fallbackColor;

    final normalized = cleaned.length == 6 ? 'FF$cleaned' : 'FFFFBB00';
    final value = int.tryParse(normalized, radix: 16);

    return value != null ? Color(value) : fallbackColor;
  }

  Widget _buildLoginLogo() {
    final logoPath = ConfigController.instance.loginLogoPath.value.trim();

    if (logoPath.isEmpty) {
      return Image.asset(
        'assets/images/icon.png',
        fit: BoxFit.contain,
      );
    }

    if (logoPath.startsWith('http://') || logoPath.startsWith('https://')) {
      return Image.network(
        logoPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/images/icon.png',
            fit: BoxFit.contain,
          );
        },
      );
    }

    if (logoPath.startsWith('assets/')) {
      return Image.asset(
        logoPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            'assets/images/icon.png',
            fit: BoxFit.contain,
          );
        },
      );
    }

    if (logoPath.startsWith('data:image')) {
      final base64Data =
          logoPath.contains(',') ? logoPath.split(',').last : logoPath;
      try {
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            );
          },
        );
      } catch (_) {
        return Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        );
      }
    }

    if (kIsWeb) {
      return Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      );
    }

    final file = File(logoPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    }

    return Image.asset(
      'assets/images/logo.png',
      fit: BoxFit.contain,
    );
  }

  Future<void> _fazerLogin() async {
    if (_isLogando) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isLogando = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logando no sistema...'),
          duration: Duration(seconds: 1),
        ),
      );
      try {
        final localStorage = LocalStorageService();
        final login = (_usuarioSelecionado ?? await localStorage.get('usuario'))
            ?.toString()
            .trim();
        final usuarioController =
            Provider.of<UsuarioController>(context, listen: false);

        if (login == null || login.isEmpty) {
          if (!mounted) return;
          setState(() => _isLogando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Selecione um usuário.'),
              backgroundColor: Colors.orange[800],
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        if (await usuarioController.logar(login, controllerSenha.text)) {
          bool usarMesas = ConfigController.instance.useTables.value;
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(
              builder: (_) => PrincipalPage(
                paginas: usarMesas ? Paginas.mesas : Paginas.categorias,
              ),
            ),
          );
        } else {
          if (!mounted) return;
          setState(() => _isLogando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Usuário ou senha incorretos...'),
              backgroundColor: Colors.orange[800],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        log(e.toString());
        if (!mounted) return;
        setState(() => _isLogando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            content: Text('Erro ao tentar logar.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Carrega as cores dinâmicas
    final primaryColor = _getDynamicColor(
        ConfigController.instance.primaryColorHex.value,
        Constants.primaryColor);
    final secondaryColor = _getDynamicColor(
        ConfigController.instance.secondaryColorHex.value,
        Constants.secondaryColor);
    final bgColor = _getDynamicColor(
        ConfigController.instance.pdvBackgroundHex.value, Colors.black87);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): _fazerLogin,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _fazerLogin,
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Fundo dinâmico com gradiente
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bgColor,
                    primaryColor.withOpacity(0.35),
                    Colors.black,
                  ],
                ),
              ),
            ),

            // Botão de configurações no canto superior direito
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                tooltip: 'Configurações',
                iconSize: 28,
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ConfigPage()),
                  );
                },
              ),
            ),

            // Centraliza o conteúdo (Cartão de Login)
            Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  margin: const EdgeInsets.all(20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo
                        Container(
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 30),
                          child: _buildLoginLogo(),
                        ),

                        Text(
                          ConfigController.instance.pdvTitle.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Faça login para acessar o PDV',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Dropdown de Usuário
                        CustomDropDown(
                          onChanged: (login) => _usuarioSelecionado = login,
                        ),

                        const SizedBox(height: 20),

                        // Campo de Senha Modernizado com suporte a ENTER
                        TextFormField(
                          controller: controllerSenha,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.go,
                          onFieldSubmitted: (_) => _fazerLogin(),
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Digite sua senha',
                            prefixIcon:
                                Icon(Icons.lock_outline, color: primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 18),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'A senha é obrigatória';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32),

                        // Botão Acessar
                        _buildButtonAcessar(context, secondaryColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonAcessar(BuildContext context, Color buttonColor) {
    final isDarkButton = buttonColor.computeLuminance() < 0.5;
    final textColor = isDarkButton ? Colors.white : Colors.black87;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0,
        ),
        onPressed: _isLogando ? null : _fazerLogin,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLogando)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else ...[
              Text(
                'Acessar',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward, color: textColor),
            ],
          ],
        ),
      ),
    );
  }
}
