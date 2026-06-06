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

  @override
  Widget build(BuildContext context) {
    final comandaController = Provider.of<ComandaController>(context);
    final usuarioController =
        Provider.of<UsuarioController>(context, listen: false);

    // Verifica quantos deste item já estão no carrinho para mostrar um badge
    var quantidade = comandaController.getQuantidade(widget.produto!.codigo);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Lógica unificada de clique no card
            if (widget.produto!.grade > 0) {
              // Se houver grade, abrir widget de grade
              _buildGradeProduto(widget.produto!);
            } else {
              // Senão, adicionar diretamente
              comandaController.adicionaItem(
                widget.produto!,
                '',
                usuario: usuarioController.usuarioLogado.codigo,
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. ÁREA DA IMAGEM
              Expanded(
                flex: 40, // Aumentei um pouco a área da imagem
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // A Imagem
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
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
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
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
                flex: 40,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produto!.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'R\$ ${f.format(widget.produto!.valor)}',
                        style: TextStyle(
                          fontSize: 18,
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
