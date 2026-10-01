import 'package:lanchonete/Components/Imagem_Produto_Widget.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Controller/usuario_controller.dart';
import 'package:lanchonete/Models/Itens_Grade_model.dart';
import 'package:lanchonete/Models/produtos_model.dart';
import 'package:lanchonete/Services/ProdutosService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'Grade_produto_widget.dart';

class ProdutoItem extends StatefulWidget {
  final Produtos? produto;
  final int? mesa;
  final int? categoria;

  const ProdutoItem(
      {Key? key, this.produto, this.mesa, required this.categoria})
      : super(key: key);

  @override
  _ProdutoItemState createState() => _ProdutoItemState();
}

class _ProdutoItemState extends State<ProdutoItem> {
  final f = NumberFormat("##0.00", "pt_BR");

  double? _parseValor(String valor) {
    final texto = valor.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(texto);
  }

  Future<double?> _solicitarPrecoGenerico() async {
    final controller = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Preço de venda'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor',
              prefixText: 'R\$ ',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              final valor = _parseValor(controller.text);
              if (valor != null && valor > 0) {
                Navigator.pop(context, valor);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valor = _parseValor(controller.text);
                if (valor != null && valor > 0) {
                  Navigator.pop(context, valor);
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final comandaController = Provider.of<ComandaController>(context);
    final usuarioController =
        Provider.of<UsuarioController>(context, listen: false);
    // Verifica quantos deste item já estão no carrinho para mostrar um badge
    var quantidade = comandaController.getQuantidade(widget.produto!.codigo);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 170;
        final radius = isCompact ? 10.0 : 16.0;

        return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: isCompact ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () async {
            // Lógica unificada de clique no card
            if (widget.produto!.grade > 0) {
              // Se houver grade, abrir widget de grade
              _buildGradeProduto(widget.produto!);
            } else {
              double? valorVenda;
              if (widget.produto!.codigo == 1) {
                valorVenda = await _solicitarPrecoGenerico();
                if (valorVenda == null) return;
              }

              // Senão, adicionar diretamente
              comandaController.adicionaItem(
                widget.produto!,
                '',
                valorVenda: valorVenda,
                usuario: usuarioController.usuarioLogado.codigo,
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ÁREA DA IMAGEM
              Expanded(
                flex: isCompact ? 34 : 40, // Aumentei um pouco a área da imagem
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(radius)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // A Imagem
                      ClipRRect(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(radius)),
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: ImagemProdutoWidget(
                              codProduto: widget.produto!.codigo),
                        ),
                      ),

                      // Badge de "OPÇÕES" (Se tiver grade)
                      if (widget.produto!.grade > 0)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "OPÇÕES",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                      // Badge de Quantidade (Mostra se já tem itens no carrinho)
                      if (quantidade > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                                color: Colors.amber[600],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 4)
                                ]),
                            child: Center(
                              child: Text(
                                quantidade.toStringAsFixed(0),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isCompact ? 12 : 14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. ÁREA DE INFORMAÇÕES
              Expanded(
                flex: isCompact ? 46 : 40,
                child: Padding(
                  padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produto!.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isCompact ? 13 : 15,
                          color: Colors.black87,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'R\$ ${f.format(widget.produto!.valor)}',
                        style: TextStyle(
                          fontSize: isCompact ? 15 : 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Future<void> _buildGradeProduto(Produtos produtos) async {
    final ProdutosService produtosService = ProdutosService();
    var itensList = ValueNotifier<List<ItensGrade>>([]);
    final gradeList = await produtosService.fetchGradesProduto(produtos.codigo);
    itensList.value.add(ItensGrade(
      produto: produtos.codigo,
      nome: produtos.nome,
      quantidade: 1,
      grade: gradeList,
    ));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ValueListenableBuilder<List<ItensGrade>>(
            valueListenable: itensList,
            builder: (context, itens, _) {
              return WidgetGradeProduto(
                itensList: itensList,
                categoria: widget.categoria!,
                produto: widget.produto!,
              );
            }),
      ),
    );
  }
}
