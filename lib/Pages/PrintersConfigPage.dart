import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Services/PrinterService.dart';
import 'package:lanchonete/Services/ZebraPrinterService.dart';

class PrinterConfigPage extends StatefulWidget {
  const PrinterConfigPage({Key? key}) : super(key: key);

  @override
  _PrinterConfigPageState createState() => _PrinterConfigPageState();
}

class _PrinterConfigPageState extends State<PrinterConfigPage> {
  // Caixa
  String _tipoCaixa = 'REDE'; // 'REDE' ou 'USB'
  final TextEditingController _ipCaixaController = TextEditingController();
  final TextEditingController _usbCaixaController = TextEditingController();

  // Secundária / Cozinha
  String _tipoCozinha = 'REDE';
  final TextEditingController _ipCozinhaController = TextEditingController();
  final TextEditingController _usbCozinhaController = TextEditingController();

  // Zebra Etiquetas
  String _tipoZebra = 'REDE';
  final TextEditingController _ipZebraController = TextEditingController();
  final TextEditingController _portaZebraController = TextEditingController(text: '9100');
  final TextEditingController _usbZebraController = TextEditingController();

  // Relatórios A4
  final TextEditingController _usbA4Controller = TextEditingController();

  // Estado geral
  bool _isLoading = true;
  List<String> _impressorasWindows = [];

  // Estados de teste
  bool _isTestingCaixa = false;
  bool _isTestingCozinha = false;
  bool _isTestingZebra = false;

  String? _testResultCaixa;
  String? _testResultCozinha;
  String? _testResultZebra;

  bool? _testSuccessCaixa;
  bool? _testSuccessCozinha;
  bool? _testSuccessZebra;

  @override
  void initState() {
    super.initState();
    _loadPrinterSettings();
    _detectarImpressorasWindows();
  }

  @override
  void dispose() {
    _ipCaixaController.dispose();
    _usbCaixaController.dispose();
    _ipCozinhaController.dispose();
    _usbCozinhaController.dispose();
    _ipZebraController.dispose();
    _portaZebraController.dispose();
    _usbZebraController.dispose();
    _usbA4Controller.dispose();
    super.dispose();
  }

  Future<void> _detectarImpressorasWindows() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      final list = await ZebraPrinterService.getInstalledWindowsPrinters();
      if (mounted) {
        setState(() {
          _impressorasWindows = list;
          if (_usbCaixaController.text.isEmpty && list.isNotEmpty) {
            _usbCaixaController.text = list.first;
          }
          if (_usbCozinhaController.text.isEmpty && list.isNotEmpty) {
            _usbCozinhaController.text = list.first;
          }
          if (_usbZebraController.text.isEmpty && list.isNotEmpty) {
            final zebraFound = list.firstWhere(
              (p) => p.toLowerCase().contains('zebra') || p.toLowerCase().contains('zdesigner'),
              orElse: () => list.first,
            );
            _usbZebraController.text = zebraFound;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPrinterSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tipoCaixa = prefs.getString('printer_tipo_caixa') ?? 'REDE';
      _ipCaixaController.text = prefs.getString('printer_ip_caixa') ?? '192.168.1.100';
      _usbCaixaController.text = prefs.getString('printer_usb_caixa') ?? '';

      _tipoCozinha = prefs.getString('printer_tipo_cozinha') ?? 'REDE';
      _ipCozinhaController.text = prefs.getString('printer_ip_cozinha') ?? '192.168.1.109';
      _usbCozinhaController.text = prefs.getString('printer_usb_cozinha') ?? '';

      _tipoZebra = prefs.getString('printer_tipo_zebra') ?? 'REDE';
      _ipZebraController.text = prefs.getString('printer_ip_zebra') ?? '192.168.1.200';
      _portaZebraController.text = prefs.getString('printer_porta_zebra') ?? '9100';
      _usbZebraController.text = prefs.getString('printer_usb_zebra') ?? '';

      _usbA4Controller.text = prefs.getString('printer_usb_a4') ?? '';

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('printer_tipo_caixa', _tipoCaixa);
    await prefs.setString('printer_ip_caixa', _ipCaixaController.text.trim());
    await prefs.setString('printer_usb_caixa', _usbCaixaController.text.trim());

    await prefs.setString('printer_tipo_cozinha', _tipoCozinha);
    await prefs.setString('printer_ip_cozinha', _ipCozinhaController.text.trim());
    await prefs.setString('printer_usb_cozinha', _usbCozinhaController.text.trim());

    await prefs.setString('printer_tipo_zebra', _tipoZebra);
    await prefs.setString('printer_ip_zebra', _ipZebraController.text.trim());
    await prefs.setString('printer_porta_zebra', _portaZebraController.text.trim());
    await prefs.setString('printer_usb_zebra', _usbZebraController.text.trim());

    await prefs.setString('printer_usb_a4', _usbA4Controller.text.trim());

    Fluttertoast.showToast(
      msg: "Configurações de impressão salvas!",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    Get.back();
  }

  Future<void> _testarCaixa() async {
    setState(() {
      _isTestingCaixa = true;
      _testResultCaixa = null;
      _testSuccessCaixa = null;
    });

    try {
      if (_tipoCaixa == 'REDE') {
        final ip = _ipCaixaController.text.trim();
        final res = await PrinterService.testPrinterConnection(ip);
        setState(() {
          _testSuccessCaixa = res['success'] == true;
          _testResultCaixa = res['message'] ?? res['error'] ?? 'Conexão estabelecida com sucesso!';
        });
      } else {
        final printerName = _usbCaixaController.text.trim();
        if (printerName.isEmpty) {
          throw Exception('Selecione uma impressora USB instalada no Windows.');
        }
        final testBytes = [0x1B, 0x40, 0x1B, 0x61, 0x01, 0x54, 0x45, 0x53, 0x54, 0x45, 0x0A, 0x1D, 0x56, 0x00];
        await ZebraPrinterService.sendToWindowsSpooler(printerName, testBytes);
        setState(() {
          _testSuccessCaixa = true;
          _testResultCaixa = 'Comando enviado para $printerName via USB! ✓';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccessCaixa = false;
        _testResultCaixa = 'Falha: $e';
      });
    } finally {
      setState(() => _isTestingCaixa = false);
    }
  }

  Future<void> _testarCozinha() async {
    setState(() {
      _isTestingCozinha = true;
      _testResultCozinha = null;
      _testSuccessCozinha = null;
    });

    try {
      if (_tipoCozinha == 'REDE') {
        final ip = _ipCozinhaController.text.trim();
        final res = await PrinterService.testPrinterConnection(ip);
        setState(() {
          _testSuccessCozinha = res['success'] == true;
          _testResultCozinha = res['message'] ?? res['error'] ?? 'Conexão estabelecida com sucesso!';
        });
      } else {
        final printerName = _usbCozinhaController.text.trim();
        if (printerName.isEmpty) {
          throw Exception('Selecione uma impressora USB instalada no Windows.');
        }
        final testBytes = [0x1B, 0x40, 0x1B, 0x61, 0x01, 0x54, 0x45, 0x53, 0x54, 0x45, 0x0A, 0x1D, 0x56, 0x00];
        await ZebraPrinterService.sendToWindowsSpooler(printerName, testBytes);
        setState(() {
          _testSuccessCozinha = true;
          _testResultCozinha = 'Comando enviado para $printerName via USB! ✓';
        });
      }
    } catch (e) {
      setState(() {
        _testSuccessCozinha = false;
        _testResultCozinha = 'Falha: $e';
      });
    } finally {
      setState(() => _isTestingCozinha = false);
    }
  }

  Future<void> _testarZebra() async {
    setState(() {
      _isTestingZebra = true;
      _testResultZebra = null;
      _testSuccessZebra = null;
    });

    final res = await ZebraPrinterService.testZebraConnection(
      tipoConexao: _tipoZebra,
      ip: _ipZebraController.text.trim(),
      port: int.tryParse(_portaZebraController.text.trim()) ?? 9100,
      nomeImpressoraUsb: _usbZebraController.text.trim(),
    );

    setState(() {
      _isTestingZebra = false;
      _testSuccessZebra = res['success'] == true;
      _testResultZebra = res['message'] ?? res['error'] ?? 'Resultado do teste';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Impressoras', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, size: 28),
            tooltip: 'Salvar',
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSecaoCaixa(),
                      const SizedBox(height: 20),
                      _buildSecaoCozinha(),
                      const SizedBox(height: 20),
                      _buildSecaoZebra(),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          'Salvar Todas as Configurações',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _saveSettings,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSecaoCaixa() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.point_of_sale, color: Constants.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Impressora Principal (Caixa / Cupons)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Text('Tipo de Conexão:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 20),
                ChoiceChip(
                  label: const Text('REDE TCP/IP'),
                  selected: _tipoCaixa == 'REDE',
                  onSelected: (val) => setState(() => _tipoCaixa = 'REDE'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('USB NATIVO'),
                  selected: _tipoCaixa == 'USB',
                  onSelected: (val) => setState(() => _tipoCaixa = 'USB'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_tipoCaixa == 'REDE')
              TextFormField(
                controller: _ipCaixaController,
                decoration: InputDecoration(
                  labelText: 'Endereço IP da Impressora do Caixa',
                  prefixIcon: const Icon(Icons.network_ping),
                  hintText: 'Ex: 192.168.1.100',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              _buildUsbSelector(
                controller: _usbCaixaController,
                labelText: 'Impressora USB do Caixa',
              ),
            const SizedBox(height: 14),
            _buildTestButton(
              isLoading: _isTestingCaixa,
              onTest: _testarCaixa,
              success: _testSuccessCaixa,
              resultMessage: _testResultCaixa,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoCozinha() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Constants.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Impressora Secundária (Cozinha / Bar)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Text('Tipo de Conexão:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 20),
                ChoiceChip(
                  label: const Text('REDE TCP/IP'),
                  selected: _tipoCozinha == 'REDE',
                  onSelected: (val) => setState(() => _tipoCozinha = 'REDE'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('USB NATIVO'),
                  selected: _tipoCozinha == 'USB',
                  onSelected: (val) => setState(() => _tipoCozinha = 'USB'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_tipoCozinha == 'REDE')
              TextFormField(
                controller: _ipCozinhaController,
                decoration: InputDecoration(
                  labelText: 'Endereço IP da Impressora da Cozinha',
                  prefixIcon: const Icon(Icons.kitchen),
                  hintText: 'Ex: 192.168.1.109',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            else
              _buildUsbSelector(
                controller: _usbCozinhaController,
                labelText: 'Impressora USB da Cozinha',
              ),
            const SizedBox(height: 14),
            _buildTestButton(
              isLoading: _isTestingCozinha,
              onTest: _testarCozinha,
              success: _testSuccessCozinha,
              resultMessage: _testResultCozinha,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecaoZebra() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: Constants.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Impressora de Etiquetas Zebra (ZPL II)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Text('Tipo de Conexão:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 20),
                ChoiceChip(
                  label: const Text('REDE TCP/IP'),
                  selected: _tipoZebra == 'REDE',
                  onSelected: (val) => setState(() => _tipoZebra = 'REDE'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('USB / SPOOLER'),
                  selected: _tipoZebra == 'USB',
                  onSelected: (val) => setState(() => _tipoZebra = 'USB'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_tipoZebra == 'REDE')
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _ipZebraController,
                      decoration: InputDecoration(
                        labelText: 'Endereço IP da Zebra',
                        prefixIcon: const Icon(Icons.lan),
                        hintText: 'Ex: 192.168.1.200',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _portaZebraController,
                      decoration: InputDecoration(
                        labelText: 'Porta',
                        hintText: '9100',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            else
              _buildUsbSelector(
                controller: _usbZebraController,
                labelText: 'Impressora Zebra USB/Windows',
              ),
            const SizedBox(height: 14),
            _buildTestButton(
              isLoading: _isTestingZebra,
              onTest: _testarZebra,
              success: _testSuccessZebra,
              resultMessage: _testResultZebra,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsbSelector({required TextEditingController controller, required String labelText}) {
    if (_impressorasWindows.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: _impressorasWindows.contains(controller.text) ? controller.text : null,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: const Icon(Icons.usb),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: _impressorasWindows.map((p) {
          return DropdownMenuItem<String>(value: p, child: Text(p, overflow: TextOverflow.ellipsis));
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => controller.text = val);
          }
        },
      );
    }

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.usb),
        hintText: 'Informe o nome exato da impressora no Windows',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildTestButton({
    required bool isLoading,
    required VoidCallback onTest,
    required bool? success,
    required String? resultMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: isLoading ? null : onTest,
          icon: isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.play_arrow),
          label: const Text('Testar Conexão'),
        ),
        if (resultMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (success == true) ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: (success == true) ? Colors.green : Colors.red),
            ),
            child: Row(
              children: [
                Icon(
                  (success == true) ? Icons.check_circle : Icons.error,
                  color: (success == true) ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resultMessage,
                    style: TextStyle(
                      color: (success == true) ? Colors.green.shade900 : Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
