import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Imports do seu projeto
import 'package:lanchonete/Components/ProdutoItem.dart';
import 'package:lanchonete/Components/complementos_widget.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Models/produtos_model.dart';
import 'package:lanchonete/Models/categoria_model.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/niveis_model.dart';
import 'package:lanchonete/Models/comanda_model.dart';
import 'package:lanchonete/Models/mesa_model.dart';
import 'package:lanchonete/Services/ProdutosService.dart';
import 'package:lanchonete/Services/CategoriaService.dart';
import 'package:lanchonete/Services/MesaService.dart';

import 'package:lanchonete/Pages/Payment_mode_page.dart';

class CategoriaPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onVoltarMesas;
  final int? mesaId;
  final String? estadoMesa;

  const CategoriaPage(
      {Key? key,
      this.onOpenDrawer,
      this.onVoltarMesas,
      this.mesaId,
      this.estadoMesa})
      : super(key: key);

  @override
  _CategoriaPageState createState() => _CategoriaPageState();
}

class _CategoriaPageState extends State<CategoriaPage> {
  final _serviceProdutos = ProdutosService();
  final _mesaService = MesaService();
  final _formatMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<Categoria> _categorias = [];
  List<Produtos> _produtos = [];
  int? _selectedCategoriaId;

  bool _isLoadingProdutos = false;
  bool _isLoadingCategorias = true;
  bool _isEnviandoPedido = false;
  bool _isConsultandoComanda = false;
  String? _erroMensagem;

  final ScrollController _produtosScrollController = ScrollController();
  final ScrollController _comandaScrollController = ScrollController();
  final ScrollController _categoriasScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosIniciais();

      if (widget.estadoMesa == 'O') {
        _consultarComandaDaMesa();
      } else {
        Provider.of<ComandaController>(context, listen: false).clear();
      }
    });
  }

  @override
  void dispose() {
    _produtosScrollController.dispose();
    _comandaScrollController.dispose();
    _categoriasScrollController.dispose();
    super.dispose();
  }

  Future<void> _consultarComandaDaMesa() async {
    if (widget.mesaId == null) return;

    setState(() => _isConsultandoComanda = true);
    final controller = Provider.of<ComandaController>(context, listen: false);

    try {
      Comanda comandaExistente = await controller.buscaComanda(widget.mesaId!);

      if (comandaExistente.itens != null &&
          comandaExistente.itens!.isNotEmpty) {
        controller.carregarItensDaComanda(comandaExistente.itens!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Itens da comanda carregados com sucesso!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print("Erro ao consultar comanda existente: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Falha ao sincronizar a comanda.'),
            backgroundColor: Colors.orange),
      );
    } finally {
      if (mounted) setState(() => _isConsultandoComanda = false);
    }
  }

  Future<void> _carregarDadosIniciais() async {
    setState(() {
      _isLoadingCategorias = true;
      _erroMensagem = null;
    });

    try {
      final categorias = await fetchCategorias();
      if (mounted) {
        setState(() {
          _categorias = categorias;
          _isLoadingCategorias = false;
        });

        if (categorias.isNotEmpty) {
          _selecionarCategoria(categorias[0].codigo);
        } else {
          setState(() => _erroMensagem = "Nenhuma categoria encontrada.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCategorias = false;
          _erroMensagem = "Erro de conexão com o servidor.";
        });
      }
    }
  }

  void _selecionarCategoria(int? idCategoria) async {
    if (_selectedCategoriaId == idCategoria) return;

    setState(() {
      _selectedCategoriaId = idCategoria;
      _isLoadingProdutos = true;
    });

    try {
      String filtro = idCategoria != null ? '?categoria=$idCategoria' : '';
      final produtos = await _serviceProdutos.fetchProdutos(filtro);

      if (mounted) {
        setState(() {
          _produtos = produtos;
          _isLoadingProdutos = false;
        });
        if (_produtosScrollController.hasClients) {
          _produtosScrollController.jumpTo(0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _produtos = [];
          _isLoadingProdutos = false;
        });
      }
    }
  }

  Future<void> _realizarPedido(ComandaController controller) async {
    String? erroValidacao = _validarItensComValorZerado(controller.itens);
    if (erroValidacao != null) {
      await _exibirAvisoValorZerado(erroValidacao);
      return;
    }

    setState(() {
      _isEnviandoPedido = true;
    });

    try {
      bool usarMesas = ConfigController.instance.useTables.value;
      int? mesaDoPedido = usarMesas ? widget.mesaId : null;

      if (usarMesas && mesaDoPedido != null) {
        Mesa novaMesa = Mesa(
          codigo: mesaDoPedido,
          nome: "Mesa ${mesaDoPedido.toString().padLeft(2, '0')}",
          estado: 'O',
        );

        bool mesaSalva = await _mesaService.salvarMesa(novaMesa);
        if (!mesaSalva) {
          print(
              "Aviso: Falha ao garantir a criação/atualização da mesa no banco.");
        }
      }

      bool sucesso = await controller.insereComanda(mesaDoPedido);

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido enviado para a cozinha com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted && usarMesas && widget.onVoltarMesas != null) {
          widget.onVoltarMesas!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar pedido para o servidor.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao realizar pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isEnviandoPedido = false;
        });
      }
    }
  }

  Future<void> _irParaPagamento(ComandaController controller) async {
    String? erroValidacao = _validarItensComValorZerado(controller.itens);
    if (erroValidacao != null) {
      await _exibirAvisoValorZerado(erroValidacao);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentModePage(
          valorPagamento: controller.valorComanda,
          mesaId: widget.mesaId,
        ),
      ),
    );
  }

  String? _validarItensComValorZerado(List<Itens> itens) {
    for (var item in itens) {
      double valorBaseUnitario = item.valor ?? 0;
      double valorAdicionaisUnitario = 0;

      if (item.complementos != null) {
        for (var comp in item.complementos!) {
          valorAdicionaisUnitario += (comp.valor * comp.quantidade);
        }
      }

      if (item.opcoesNiveis != null) {
        for (var op in item.opcoesNiveis!) {
          valorAdicionaisUnitario += (op.valorAdicional * op.quantidade);
        }
      }

      double valorTotalUnitario = valorBaseUnitario + valorAdicionaisUnitario;

      if (valorTotalUnitario <= 0) {
        return 'O item "${item.nome}" tem valor zerado ou inválido. Verifique o preço do produto.';
      }
    }
    return null;
  }

  Future<void> _exibirAvisoValorZerado(String mensagem) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Atenção - Valor Inválido",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        content: Text(mensagem),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmarExclusao(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Remover Item",
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
                "Tem certeza que deseja remover este item do carrinho?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("CANCELAR",
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("REMOVER",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _removerItem(Itens item, ComandaController controller) async {
    controller.removeItemCarrinho(item);

    if (item.codigo != null && item.codigo! < 1000000000000) {
      try {
        await controller.deletarItemComanda(item.codigo!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item removido do sistema.'),
              backgroundColor: Colors.orange),
        );
      } catch (e) {
        print("Falha ao deletar no servidor: $e");
      }
    }
  }

  List<Map<String, dynamic>> _getExtrasOrdenados(Itens item) {
    List<Map<String, dynamic>> extras = [];

    if (item.complementos != null) {
      for (var c in item.complementos!) {
        extras.add({
          'nome': c.nome,
          'qtd': c.quantidade,
          'valor': c.valor * (c.quantidade == 0 ? 1 : c.quantidade),
          'tipo': 'complemento'
        });
      }
    }
    if (item.opcoesNiveis != null) {
      for (var op in item.opcoesNiveis!) {
        extras.add({
          'nome': op.nome,
          'qtd': op.quantidade,
          'valor': op.valorAdicional * (op.quantidade == 0 ? 1 : op.quantidade),
          'tipo': 'opcao'
        });
      }
    }
    final prioridades = [
      'TAMANHO',
      'TAM',
      'UNIDADE',
      'UN',
      'UNID',
      'PEQUENO',
      'MEDIO',
      'MÉDIO',
      'GRANDE',
      'GIGANTE',
      'FAMILIA',
      ' P ',
      ' M ',
      ' G ',
      ' GG ',
      '(P)',
      '(M)',
      '(G)',
      '(GG)',
      ' P',
      ' M',
      ' G',
      ' GG'
    ];
    bool isPrioridade(String nome) {
      String n = nome.toUpperCase();
      if (['P', 'M', 'G', 'GG'].contains(n.trim())) return true;
      for (var p in prioridades) {
        if (n.contains(p)) return true;
      }
      return false;
    }

    extras.sort((a, b) {
      bool aPri = isPrioridade(a['nome'] ?? '');
      bool bPri = isPrioridade(b['nome'] ?? '');
      if (aPri && !bPri) return -1;
      if (!aPri && bPri) return 1;
      return 0;
    });

    return extras;
  }

  Widget _buildCategoriaTab(Categoria item) {
    bool isSelected = _selectedCategoriaId == item.codigo;
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selecionarCategoria(item.codigo),
          borderRadius: BorderRadius.circular(30),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber[600] : Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: isSelected ? Colors.amber[600]! : Colors.grey[300]!,
                  width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3))
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                item.nome ?? '',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCatalogoAreaSemCategoria() {
    if (_erroMensagem != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_erroMensagem!),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _carregarDadosIniciais,
                child: const Text("Tentar Novamente"))
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F5F7),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _isLoadingProdutos
          ? Center(child: CircularProgressIndicator(color: Colors.amber[700]))
          : _produtos.isEmpty
              ? const Center(child: Text("Nenhum produto nesta categoria"))
              : Scrollbar(
                  controller: _produtosScrollController,
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  child: GridView.builder(
                    controller: _produtosScrollController,
                    padding: const EdgeInsets.only(
                        bottom: 40, top: 10, left: 4, right: 4),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 190,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _produtos.length,
                    itemBuilder: (context, index) {
                      return ProdutoItem(
                        produto: _produtos[index],
                        categoria: _selectedCategoriaId ?? 0,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildComandaItem(Itens item, ComandaController controller) {
    double valorBaseUnitario = item.valor ?? 0;
    double valorAdicionaisUnitario = 0;

    if (item.complementos != null) {
      for (var comp in item.complementos!) {
        valorAdicionaisUnitario += (comp.valor * comp.quantidade);
      }
    }
    if (item.opcoesNiveis != null) {
      for (var op in item.opcoesNiveis!) {
        valorAdicionaisUnitario += (op.valorAdicional * op.quantidade);
      }
    }

    double valorTotalLinha =
        (valorBaseUnitario + valorAdicionaisUnitario) * (item.quantidade ?? 1);

    List<Map<String, dynamic>> extrasExibicao = _getExtrasOrdenados(item);

    return Dismissible(
      key: Key("item_${item.codigo}_${DateTime.now().millisecondsSinceEpoch}"),
      direction: DismissDirection.endToStart,
      background: Container(
          color: Colors.red[100],
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 15),
          child: const Icon(Icons.delete, color: Colors.red)),
      confirmDismiss: (direction) async {
        return await _confirmarExclusao(context);
      },
      onDismissed: (_) => _removerItem(item, controller),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            List<Nivel>? niveis;
            try {
              niveis = await _serviceProdutos.getNiveis(item.produto ?? 0);
            } catch (e) {
              print('Erro ao buscar niveis: $e');
            }

            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => SelecaoOpcoesProdutoWidget(
                  item: item,
                  niveis: niveis,
                  grupo: item.codGrupo,
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.nome ?? 'Produto',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.redAccent, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        bool confirmar = await _confirmarExclusao(context);
                        if (confirmar) {
                          _removerItem(item, controller);
                        }
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "${item.quantidade}x  ${_formatMoeda.format(valorBaseUnitario)}",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                      Text(_formatMoeda.format(valorTotalLinha),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                if (extrasExibicao.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: extrasExibicao
                          .map((extra) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: Text(
                                            "+ ${extra['nome']} (${extra['qtd']}x)",
                                            style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis)),
                                    Text(
                                        "${_formatMoeda.format(extra['valor'])}",
                                        style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                if (item.obs != null && item.obs!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.note, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(item.obs!,
                            style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 12,
                                fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComandaSidebar() {
    return Consumer<ComandaController>(
      builder: (context, controller, _) {
        double totalItens = controller.itens
            .fold(0, (sum, item) => sum + (item.quantidade ?? 0));

        bool usarMesas = ConfigController.instance.useTables.value;
        bool mesaOcupada = widget.estadoMesa == 'O';

        return Container(
          width: 360,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amber[500],
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white),
                    const SizedBox(width: 10),
                    const Text("PEDIDO ATUAL",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                          totalItens % 1 == 0
                              ? totalItens.toInt().toString()
                              : totalItens.toStringAsFixed(1),
                          style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
              Expanded(
                child: controller.isEmpty
                    ? Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.shopping_basket_outlined,
                            size: 50, color: Colors.grey[300]),
                        Text("Carrinho Vazio",
                            style: TextStyle(color: Colors.grey[400]))
                      ]))
                    : Scrollbar(
                        controller: _comandaScrollController,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _comandaScrollController,
                          itemCount: controller.itens.length,
                          itemBuilder: (context, index) => _buildComandaItem(
                              controller.itens[index], controller),
                        ),
                      ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border:
                        const Border(top: BorderSide(color: Colors.black12))),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("TOTAL",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                              Text(_formatMoeda.format(controller.valorComanda),
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold))
                            ]),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            // --- ALTERAÇÃO AQUI: CONTROLE INTELIGENTE DE BOTÕES ---
                            if (usarMesas) ...[
                              // Botão FAZER PEDIDO (Aparece apenas quando está usando Mesas)
                              Expanded(
                                child: SizedBox(
                                  height: 45,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent[700],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))),
                                    onPressed: (controller.isEmpty ||
                                            _isEnviandoPedido)
                                        ? null
                                        : () => _realizarPedido(controller),
                                    icon: _isEnviandoPedido
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Icon(Icons.send_rounded,
                                            size: 18),
                                    label: const Text("FAZER PEDIDO",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                ),
                              ),
                              if (mesaOcupada) ...[
                                const SizedBox(width: 10),
                                // Botão PAGAR (Aparece se a mesa for Ocupada)
                                Expanded(
                                  child: SizedBox(
                                    height: 45,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[600],
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8))),
                                      onPressed: controller.isEmpty
                                          ? null
                                          : () => _irParaPagamento(controller),
                                      icon: const Icon(Icons.monetization_on,
                                          size: 18),
                                      label: const Text("PAGAR",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ),
                                ),
                              ]
                            ] else ...[
                              // Botão ÚNICO DE PAGAMENTO (Quando uso de Mesas estiver DESATIVADO)
                              Expanded(
                                child: SizedBox(
                                  height: 45,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green[600],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8))),
                                    onPressed: controller.isEmpty
                                        ? null
                                        : () => _irParaPagamento(controller),
                                    icon: const Icon(Icons.monetization_on,
                                        size: 18),
                                    label: const Text("IR PARA PAGAMENTO",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMesaOcupada = widget.estadoMesa == 'O';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: widget.mesaId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                tooltip: 'Voltar às Mesas',
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  if (widget.onVoltarMesas != null) {
                    widget.onVoltarMesas!();
                  }
                },
              )
            : IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                tooltip: 'Menu Principal',
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  if (widget.onOpenDrawer != null) {
                    widget.onOpenDrawer!();
                  } else {
                    try {
                      Scaffold.of(context).openDrawer();
                    } catch (_) {}
                  }
                },
              ),
        title: Text(
            widget.mesaId != null
                ? "PDV / Mesa ${widget.mesaId.toString().padLeft(2, '0')}"
                : "PDV / Vendas",
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          if (isMesaOcupada)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                icon: _isConsultandoComanda
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.receipt_long, color: Colors.blueAccent),
                label: const Text("Consultar Comanda",
                    style: TextStyle(
                        color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                onPressed:
                    _isConsultandoComanda ? null : _consultarComandaDaMesa,
              ),
            ),
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _carregarDadosIniciais),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 65,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: const Color(0xFFF5F5F7),
            child: _isLoadingCategorias
                ? const Center(child: CircularProgressIndicator())
                : ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: ListView.builder(
                      controller: _categoriasScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) =>
                          _buildCategoriaTab(_categorias[index]),
                    ),
                  ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildCatalogoAreaSemCategoria()),
                _buildComandaSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
