import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Controller/Tef/paygo_tefcontroller.dart';
import 'package:lanchonete/Pages/Login_page.dart';
import 'package:lanchonete/Utils/image_picker_helper.dart';

class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TefController _tefController = Get.find<TefController>();

  String? _urlBase;
  bool _useTables = false;
  int _tableCount = 0;
  bool _useTef = true;
  int _pdv = 1;
  String _pdvBackgroundHex = 'FFBB00';
  String _primaryColorHex = 'FFBB00';
  String _secondaryColorHex = '2E8B57';
  String _pdvLogoPath = '';
  String _loginLogoPath = '';
  String _pdvTitle = 'PDV Lanchonete';

  final TextEditingController _pdvTitleController = TextEditingController();
  final TextEditingController _pdvNumeroController = TextEditingController();
  final TextEditingController _pdvBackgroundController = TextEditingController();
  final TextEditingController _urlBaseController = TextEditingController();
  final TextEditingController _primaryColorController = TextEditingController();
  final TextEditingController _secondaryColorController = TextEditingController();
  final TextEditingController _pdvLogoController = TextEditingController();
  final TextEditingController _loginLogoController = TextEditingController();
  final TextEditingController _tableCountController = TextEditingController();

  final List<Color> _presetColors = [
    const Color(0xFFFFBB00), // Amarelo Lanchonete
    const Color(0xFFC62828), // Vermelho Portal
    const Color(0xFF1E88E5), // Azul Cobalto
    const Color(0xFF2E7D32), // Verde Esmeralda
    const Color(0xFF6A1B9A), // Roxo Elegante
    const Color(0xFFFF6F00), // Laranja Intenso
    const Color(0xFF37474F), // Grafite
    const Color(0xFF00897B), // Verde Petróleo
  ];

  String _normalizarHex(String value) {
    final cleaned = value.trim().replaceAll('#', '').toUpperCase();
    if (cleaned.isEmpty) return 'FFBB00';
    if (cleaned.length > 6) return cleaned.substring(0, 6);
    return cleaned;
  }

  Color _parseHexColor(String rawHex) {
    final cleaned = _normalizarHex(rawHex);
    final normalized = cleaned.length == 6 ? 'FF$cleaned' : 'FFFFBB00';
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return const Color(0xFFFFBB00);
    return Color(value);
  }

  Widget _buildLogoPreview(String path, {IconData fallbackIcon = Icons.image}) {
    final normalizedPath = path.trim();

    if (normalizedPath.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(fallbackIcon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Clique para selecionar',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      );
    }

    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return Image.network(
        normalizedPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
      );
    }

    if (normalizedPath.startsWith('assets/')) {
      return Image.asset(
        normalizedPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
      );
    }

    if (normalizedPath.startsWith('data:image')) {
      final base64Data = normalizedPath.contains(',')
          ? normalizedPath.split(',').last
          : normalizedPath;
      try {
        return Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
        );
      } catch (_) {
        return Icon(Icons.broken_image, size: 48, color: Colors.grey[400]);
      }
    }

    if (kIsWeb) {
      return Icon(Icons.broken_image, size: 48, color: Colors.grey[400]);
    }

    final file = File(normalizedPath);
    if (!file.existsSync()) {
      return Icon(Icons.broken_image, size: 48, color: Colors.grey[400]);
    }

    return Image.file(file, fit: BoxFit.contain);
  }

  Future<void> _abrirSeletorCor({
    required String titulo,
    required String corAtual,
    required ValueChanged<String> onColorSelected,
  }) async {
    String corEscolhidaHex = _normalizarHex(corAtual);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final corPreview = _parseHexColor(corEscolhidaHex);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: corPreview,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paleta Recomendada:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _presetColors.map((cor) {
                        final hex = cor.value.toRadixString(16).substring(2).toUpperCase();
                        final selecionada = corEscolhidaHex == hex;

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              corEscolhidaHex = hex;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selecionada ? Colors.black87 : Colors.transparent,
                                width: selecionada ? 3 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: cor.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: selecionada
                                ? const Icon(Icons.check, color: Colors.white, size: 24)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Código HEX personalizado:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: corEscolhidaHex,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                        LengthLimitingTextInputFormatter(7),
                      ],
                      decoration: InputDecoration(
                        prefixText: '# ',
                        hintText: 'Ex: FFBB00',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          corEscolhidaHex = _normalizarHex(val);
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPreview,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    onColorSelected(corEscolhidaHex);
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    'Aplicar',
                    style: TextStyle(
                      color: corPreview.computeLuminance() < 0.5 ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlBaseController.dispose();
    _pdvNumeroController.dispose();
    _pdvBackgroundController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    _pdvLogoController.dispose();
    _loginLogoController.dispose();
    _pdvTitleController.dispose();
    _tableCountController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    await ConfigController.instance.getConfig();
    if (!mounted) return;

    final config = ConfigController.instance;

    setState(() {
      _urlBase = config.baseURL.value ?? '';
      _urlBaseController.text = _urlBase!;
      _pdv = config.pdv.value;
      _pdvNumeroController.text = _pdv.toString();

      _useTables = config.useTables.value;
      _tableCount = config.tableCount.value;
      _tableCountController.text = _tableCount > 0 ? _tableCount.toString() : '';

      _useTef = config.useTef.value;

      _pdvTitle = config.pdvTitle.value;
      _pdvTitleController.text = _pdvTitle;

      _pdvBackgroundHex = config.pdvBackgroundHex.value;
      _pdvBackgroundController.text = _pdvBackgroundHex;

      _primaryColorHex = config.primaryColorHex.value;
      _primaryColorController.text = _primaryColorHex;

      _secondaryColorHex = config.secondaryColorHex.value;
      _secondaryColorController.text = _secondaryColorHex;

      _pdvLogoPath = config.pdvLogoPath.value;
      _pdvLogoController.text = _pdvLogoPath;

      _loginLogoPath = config.loginLogoPath.value;
      _loginLogoController.text = _loginLogoPath;
    });
  }

  Future<void> _salvarTudo() async {
    _urlBase = _urlBaseController.text.trim();
    _pdv = int.tryParse(_pdvNumeroController.text.trim()) ?? 1;
    _tableCount = int.tryParse(_tableCountController.text.trim()) ?? 0;
    _pdvTitle = _pdvTitleController.text.trim().isEmpty ? 'PDV Lanchonete' : _pdvTitleController.text.trim();

    await ConfigController.instance.saveConfig(
      _urlBase,
      _useTables,
      _tableCount,
      _useTef,
      _pdv,
      pdvTitleValue: _pdvTitle,
      pdvBackgroundHexValue: _pdvBackgroundHex,
      primaryColorHexValue: _primaryColorHex,
      secondaryColorHexValue: _secondaryColorHex,
      pdvLogoPathValue: _pdvLogoPath,
      loginLogoPathValue: _loginLogoPath,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas com sucesso!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações do Sistema', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dns), text: 'Servidor & Terminal'),
            Tab(icon: Icon(Icons.palette), text: 'Identidade Visual'),
            Tab(icon: Icon(Icons.restaurant), text: 'Mesas & Atendimento'),
            Tab(icon: Icon(Icons.credit_card), text: 'TEF PayGo'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Salvar Configurações',
            icon: const Icon(Icons.check, size: 28),
            onPressed: _salvarTudo,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabServidor(),
          _buildTabVisual(),
          _buildTabMesas(),
          _buildTabTef(),
        ],
      ),
    );
  }

  Widget _buildCardSection({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Constants.primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTabServidor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _buildCardSection(
            title: 'Servidor Local (API REST)',
            icon: Icons.cloud_queue,
            children: [
              const Text(
                'Endereço da API REST Delphi Horse (ex: http://192.168.1.100:9000 ou http://localhost:9000)',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _urlBaseController,
                decoration: InputDecoration(
                  labelText: 'URL Base do Servidor',
                  prefixIcon: const Icon(Icons.link),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pdvNumeroController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Número deste PDV (Terminal)',
                  prefixIcon: const Icon(Icons.point_of_sale),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabVisual() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _buildCardSection(
            title: 'Identidade & Logomarca',
            icon: Icons.branding_watermark,
            children: [
              TextFormField(
                controller: _pdvTitleController,
                decoration: InputDecoration(
                  labelText: 'Título do PDV',
                  prefixIcon: const Icon(Icons.title),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Logo do Login / Abertura:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await pickImageStorageValue();
                  if (picked != null) {
                    setState(() {
                      _loginLogoPath = picked;
                      _loginLogoController.text = picked;
                    });
                  }
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: _buildLogoPreview(_loginLogoPath),
                ),
              ),
            ],
          ),
          _buildCardSection(
            title: 'Paleta de Cores Dinâmica (White Label)',
            icon: Icons.color_lens,
            children: [
              _buildColorTile(
                title: 'Cor Primária (Destaques e AppBar)',
                hexValue: _primaryColorHex,
                onSelect: (newHex) {
                  setState(() {
                    _primaryColorHex = newHex;
                    _primaryColorController.text = newHex;
                  });
                },
              ),
              const Divider(),
              _buildColorTile(
                title: 'Cor Secundária (Botões de Ação)',
                hexValue: _secondaryColorHex,
                onSelect: (newHex) {
                  setState(() {
                    _secondaryColorHex = newHex;
                    _secondaryColorController.text = newHex;
                  });
                },
              ),
              const Divider(),
              _buildColorTile(
                title: 'Fundo do Login / Tela Inicial',
                hexValue: _pdvBackgroundHex,
                onSelect: (newHex) {
                  setState(() {
                    _pdvBackgroundHex = newHex;
                    _pdvBackgroundController.text = newHex;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorTile({required String title, required String hexValue, required ValueChanged<String> onSelect}) {
    final color = _parseHexColor(hexValue);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text('#$hexValue', style: const TextStyle(color: Colors.grey)),
      trailing: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      onTap: () {
        _abrirSeletorCor(
          titulo: title,
          corAtual: hexValue,
          onColorSelected: onSelect,
        );
      },
    );
  }

  Widget _buildTabMesas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _buildCardSection(
            title: 'Modo de Operação',
            icon: Icons.table_bar,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Habilitar Modo Mesas & Comandas', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Se desativado, o PDV opera diretamente no modo Balcão / Rápido.'),
                value: _useTables,
                activeColor: Constants.primaryColor,
                onChanged: (val) {
                  setState(() => _useTables = val);
                },
              ),
              if (_useTables) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tableCountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantidade de Mesas no Salão',
                    prefixIcon: const Icon(Icons.grid_view),
                    helperText: 'Informe a quantidade de mesas para geração do mapa visual.',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabTef() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          _buildCardSection(
            title: 'TEF Integrado PayGo',
            icon: Icons.payment,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Habilitar TEF PayGo', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Processa pagamentos de cartão direto via SmartPOS ou Pinpad PayGo.'),
                value: _useTef,
                activeColor: Constants.primaryColor,
                onChanged: (val) {
                  setState(() => _useTef = val);
                },
              ),
              if (_useTef) ...[
                const SizedBox(height: 20),
                const Text('Funções Administrativas do TEF:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.download, size: 18),
                      label: const Text('Instalação'),
                      onPressed: () => _tefController.instalacao(),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.build, size: 18),
                      label: const Text('Manutenção'),
                      onPressed: () => _tefController.manutencao(),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.print, size: 18),
                      label: const Text('Reimpressão'),
                      onPressed: () => _tefController.reimpressao(),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.admin_panel_settings, size: 18),
                      label: const Text('Painel Admin'),
                      onPressed: () => _tefController.painelAdministrativo(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
