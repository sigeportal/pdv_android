import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lanchonete/Services/PrinterService.dart';

class PrinterConfigPage extends StatefulWidget {
  const PrinterConfigPage({Key? key}) : super(key: key);

  @override
  _PrinterConfigPageState createState() => _PrinterConfigPageState();
}

class _PrinterConfigPageState extends State<PrinterConfigPage> {
  final TextEditingController _ipCaixaController = TextEditingController();
  final TextEditingController _ipCozinhaController = TextEditingController();
  bool _isLoading = true;
  bool _isTestingCaixa = false;
  bool _isTestingCozinha = false;
  String? _testResultCaixa;
  String? _testResultCozinha;
  bool? _testSuccessCaixa;
  bool? _testSuccessCozinha;

  @override
  void initState() {
    super.initState();
    _loadPrinterSettings();
  }

  // Carrega as configurações salvas no dispositivo
  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Carrega ou define um valor padrão caso não exista
      _ipCaixaController.text =
          prefs.getString('printer_ip_caixa') ?? '192.168.1.100';
      _ipCozinhaController.text =
          prefs.getString('printer_ip_cozinha') ?? '192.168.1.109';
      _isLoading = false;
    });
  }

  // Salva as configurações
  Future<void> _saveSettings() async {
    if (_ipCaixaController.text.isEmpty || _ipCozinhaController.text.isEmpty) {
      Fluttertoast.showToast(msg: "Os campos de IP não podem ficar vazios.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_ip_caixa', _ipCaixaController.text.trim());
    await prefs.setString(
        'printer_ip_cozinha', _ipCozinhaController.text.trim());

    Fluttertoast.showToast(msg: "Configurações de impressora salvas!");
    Get.offAndToNamed('principal');
  }

  // Testa conexão com a impressora do caixa
  Future<void> _testPrinterCaixa() async {
    setState(() => _isTestingCaixa = true);

    try {
      final result = await PrinterService.testPrinterConnection(
        _ipCaixaController.text.trim(),
      );

      setState(() {
        _testSuccessCaixa = result['success'] as bool;
        _testResultCaixa = result['success']
            ? 'Impressora respondendo! ✓'
            : 'Erro: ${result['error']}';
      });

      if (result['success'] as bool) {
        Fluttertoast.showToast(
          msg: _testResultCaixa ?? '',
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: result['error'] ?? 'Erro desconhecido',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _testSuccessCaixa = false;
        _testResultCaixa = 'Erro: $e';
      });
      Fluttertoast.showToast(msg: 'Erro ao testar: $e');
    } finally {
      setState(() => _isTestingCaixa = false);
    }
  }

  // Testa conexão com a impressora da cozinha
  Future<void> _testPrinterCozinha() async {
    setState(() => _isTestingCozinha = true);

    try {
      final result = await PrinterService.testPrinterConnection(
        _ipCozinhaController.text.trim(),
      );

      setState(() {
        _testSuccessCozinha = result['success'] as bool;
        _testResultCozinha = result['success']
            ? 'Impressora respondendo! ✓'
            : 'Erro: ${result['error']}';
      });

      if (result['success'] as bool) {
        Fluttertoast.showToast(
          msg: _testResultCozinha ?? '',
          backgroundColor: Colors.green,
        );
      } else {
        Fluttertoast.showToast(
          msg: result['error'] ?? 'Erro desconhecido',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _testSuccessCozinha = false;
        _testResultCozinha = 'Erro: $e';
      });
      Fluttertoast.showToast(msg: 'Erro ao testar: $e');
    } finally {
      setState(() => _isTestingCozinha = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Configurar Impressoras',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Salvar Configurações',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              margin: const EdgeInsets.all(50),
              width: MediaQuery.of(context).size.width,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.print, size: 60, color: Colors.grey),
                    const SizedBox(height: 30),

                    // --- IMPRESSORA CAIXA ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Impressora do Caixa (Cupom)",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ipCaixaController,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'IP do Caixa',
                        prefixIcon: Icon(Icons.point_of_sale),
                        hintText: 'Ex: 192.168.0.100',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botão de teste para Caixa
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTestingCaixa ? null : _testPrinterCaixa,
                        icon: _isTestingCaixa
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : const Icon(Icons.print_outlined),
                        label: Text(
                          _isTestingCaixa
                              ? 'Testando...'
                              : 'Testar Impressora do Caixa',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _testSuccessCaixa == true
                              ? Colors.green
                              : _testSuccessCaixa == false
                                  ? Colors.red
                                  : null,
                          foregroundColor:
                              _testSuccessCaixa != null ? Colors.white : null,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    // Resultado do teste
                    if (_testResultCaixa != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _testResultCaixa!,
                          style: TextStyle(
                            color: _testSuccessCaixa == true
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 30),

                    // --- IMPRESSORA COZINHA ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Impressora da Cozinha (Produção)",
                          style: TextStyle(
                              fontWeight: FontWeight.w500, color: Colors.grey)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ipCozinhaController,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'IP da Cozinha',
                        prefixIcon: Icon(Icons.restaurant),
                        hintText: 'Ex: 192.168.0.101',
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botão de teste para Cozinha
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isTestingCozinha ? null : _testPrinterCozinha,
                        icon: _isTestingCozinha
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : const Icon(Icons.print_outlined),
                        label: Text(
                          _isTestingCozinha
                              ? 'Testando...'
                              : 'Testar Impressora da Cozinha',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _testSuccessCozinha == true
                              ? Colors.green
                              : _testSuccessCozinha == false
                                  ? Colors.red
                                  : null,
                          foregroundColor:
                              _testSuccessCozinha != null ? Colors.white : null,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    // Resultado do teste
                    if (_testResultCozinha != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _testResultCozinha!,
                          style: TextStyle(
                            color: _testSuccessCozinha == true
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
