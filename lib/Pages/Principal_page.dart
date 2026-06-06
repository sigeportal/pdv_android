import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Pages/Caixa_page.dart';
import 'package:lanchonete/Pages/Categoria_page.dart';
import 'package:lanchonete/Pages/Config_page.dart';
import 'package:lanchonete/Pages/Consulta_Produtos_page.dart';
import 'package:lanchonete/Pages/Despesa_page.dart';
import 'package:lanchonete/Pages/PrintersConfigPage.dart';
import 'package:lanchonete/Pages/Mesas_page.dart';
import 'package:lanchonete/Pages/RelatorioVendasAnalitico_page.dart';
import 'package:lanchonete/Services/CaixaService.dart';
import 'package:flutter/material.dart';

enum Paginas {
  mesas,
  categorias,
  consultaProdutos,
  caixa,
  despesas,
  relatorios,
  configuracao,
  impressoras
}

class PrincipalPage extends StatefulWidget {
  final Paginas paginas;

  const PrincipalPage({Key? key, required this.paginas}) : super(key: key);

  @override
  _PrincipalPageState createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  final CaixaService _caixaService = CaixaService();
  late int _selectedIndex;
  int? _mesaSelecionada;
  String? _estadoMesaSelecionada;
  bool _useTables = false;
  bool _verificandoCaixa = false;
  bool _caixaAberto = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _useTables = ConfigController.instance.useTables.value;
    _selectedIndex = widget.paginas.index;

    // --- ESCUDO DE ROTA (A MÁGICA ACONTECE AQUI) ---
    // Impede que telas de carregamento ou rotas antigas forcem a abertura
    // da CategoriaPage quando o uso de mesas está ativado e nenhuma mesa foi selecionada.
    if (_useTables &&
        _selectedIndex == Paginas.categorias.index &&
        _mesaSelecionada == null) {
      _selectedIndex = Paginas.mesas.index;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarCaixa();
    });
  }

  Future<void> _verificarCaixa() async {
    if (_verificandoCaixa) return;

    setState(() => _verificandoCaixa = true);
    try {
      await ConfigController.instance.getConfig();
      final pdv = ConfigController.instance.pdv.value;
      final response = await _caixaService.consultarStatus(pdv: pdv);
      final data = response['data'] is Map ? response['data'] as Map : response;
      final aberto = data['aberto'] == true || data['aberto'] == 'true';

      if (!mounted) return;
      setState(() => _caixaAberto = aberto);

      if (!aberto) {
        setState(() => _verificandoCaixa = false);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CaixaPage(
              aberturaInicial: true,
              onStatusChanged: _verificarCaixa,
            ),
          ),
        );
        if (mounted) {
          await _verificarCaixa();
        }
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _caixaAberto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nao foi possivel consultar o caixa: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
      setState(() => _verificandoCaixa = false);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CaixaPage(
            aberturaInicial: true,
            onStatusChanged: _verificarCaixa,
          ),
        ),
      );
      if (mounted) {
        await _verificarCaixa();
      }
    } finally {
      if (mounted) setState(() => _verificandoCaixa = false);
    }
  }

  void _openDrawer() {
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scaffoldKey.currentState != null) {
        _scaffoldKey.currentState!.openDrawer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _paginas = <Widget>[
      MesasPage(
        onOpenDrawer: _openDrawer,
        onMesaSelected: (mesaId, estado) {
          setState(() {
            _mesaSelecionada = mesaId;
            _estadoMesaSelecionada = estado;
            _selectedIndex = Paginas.categorias.index;
          });
        },
      ),
      CategoriaPage(
        onOpenDrawer: _openDrawer,
        mesaId: _mesaSelecionada,
        estadoMesa: _estadoMesaSelecionada,
        onVoltarMesas: () {
          setState(() {
            _mesaSelecionada = null;
            _estadoMesaSelecionada = null;
            _selectedIndex = Paginas.mesas.index;
          });
        },
      ),
      ConsultaProdutosPage(),
      CaixaPage(onStatusChanged: _verificarCaixa),
      const DespesaPage(),
      RelatorioVendasAnaliticoPage(),
      ConfigPage(),
      PrinterConfigPage()
    ];

    bool isCustomAppBarPage = _selectedIndex == Paginas.categorias.index ||
        _selectedIndex == Paginas.mesas.index;

    return Scaffold(
      key: _scaffoldKey,
      appBar: isCustomAppBarPage
          ? null
          : AppBar(
              title: Text(
                _titulos[_selectedIndex],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: Constants.primaryColor,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Constants.primaryColor,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child:
                    Icon(Icons.store, color: Constants.primaryColor, size: 40),
              ),
              accountName: const Text(
                "PDV Lanchonete",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text("Operador do Caixa"),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_useTables)
                    _buildDrawerItem(
                      icon: Icons.table_restaurant_rounded,
                      text: 'Gerenciar Mesas',
                      isSelected: _selectedIndex == Paginas.mesas.index,
                      onTap: () => _onItemTapped(Paginas.mesas.index),
                    ),
                  _buildDrawerItem(
                    icon: Icons.point_of_sale_rounded,
                    text: _useTables ? 'Venda Atual (Mesa)' : 'Realizar Venda',
                    isSelected: _selectedIndex == Paginas.categorias.index,
                    onTap: () {
                      if (_useTables && _mesaSelecionada == null) {
                        _onItemTapped(Paginas.mesas.index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Por favor, selecione uma mesa primeiro.')),
                        );
                      } else {
                        _onItemTapped(Paginas.categorias.index);
                      }
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.price_check_rounded,
                    text: 'Consultar Preço',
                    isSelected:
                        _selectedIndex == Paginas.consultaProdutos.index,
                    onTap: () => _onItemTapped(Paginas.consultaProdutos.index),
                  ),
                  _buildDrawerItem(
                    icon: Icons.point_of_sale,
                    text: 'Abrir/Fechar Caixa',
                    isSelected: _selectedIndex == Paginas.caixa.index,
                    onTap: () => _onItemTapped(Paginas.caixa.index),
                  ),
                  _buildDrawerItem(
                    icon: Icons.payments_outlined,
                    text: 'Lancar Despesa',
                    isSelected: _selectedIndex == Paginas.despesas.index,
                    onTap: () => _onItemTapped(Paginas.despesas.index),
                  ),
                  _buildDrawerItem(
                    icon: Icons.assessment_rounded,
                    text: 'Vendas Analitico',
                    isSelected: _selectedIndex == Paginas.relatorios.index,
                    onTap: () => _onItemTapped(Paginas.relatorios.index),
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    text: 'Configurações',
                    isSelected: _selectedIndex == Paginas.configuracao.index,
                    onTap: () => _onItemTapped(Paginas.configuracao.index),
                  ),
                  _buildDrawerItem(
                    icon: Icons.print_rounded,
                    text: 'Impressoras',
                    isSelected: _selectedIndex == Paginas.impressoras.index,
                    onTap: () => _onItemTapped(Paginas.impressoras.index),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Versão 1.0.0',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_caixaAberto) _buildCaixaStatusLabel(),
          Expanded(child: _paginas.elementAt(_selectedIndex)),
        ],
      ),
    );
  }

  Widget _buildCaixaStatusLabel() {
    final pdv = ConfigController.instance.pdv.value;
    return Container(
      width: double.infinity,
      color: Colors.green[700],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        'Caixa PDV $pdv Aberto',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  final List<String> _titulos = [
    'Mesas',
    'Vendas',
    'Consultar Preco',
    'Caixa PDV',
    'Lancar Despesa',
    'Vendas Analitico',
    'Configuracoes',
    'Impressoras'
  ];

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Constants.primaryColor : Colors.grey[600],
      ),
      title: Text(
        text,
        style: TextStyle(
          color: isSelected ? Constants.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Constants.primaryColor.withOpacity(0.1),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      onTap: onTap,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }
}
