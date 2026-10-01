import 'package:flutter/material.dart';
import 'package:lanchonete/Components/adicionais_widget.dart';
import 'package:lanchonete/Controller/Comanda.Controller.dart';
import 'package:lanchonete/Controller/complementos_controller.dart';

import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Services/ProdutosService.dart';
import 'package:provider/provider.dart';

import '../Constants.dart';

class AcoesWidget extends StatefulWidget {
  final Itens item;
  const AcoesWidget({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<AcoesWidget> createState() => _AcoesWidgetState();
}

class _AcoesWidgetState extends State<AcoesWidget> {
  String _observacao = '';

  double? _parseValor(String valor) {
    final texto = valor.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(texto);
  }

  Future<Widget?> _telaObservacao(
      ComandaController comandaController, Itens item) async {
    return await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Observação'),
          ),
          Container(
            margin: EdgeInsets.all(10),
            child: TextFormField(
              onChanged: (String obs) {
                _observacao = obs;
              },
              autofocus: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Constants.primaryColor,
            ),
            height: 50,
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.only(left: 10, right: 10),
            child: TextButton(
              onPressed: () {
                comandaController.adicionaObservacao(item.codigo, _observacao);
                Navigator.pop(context);
              },
              child: Text(
                'Salvar',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _telaDesconto(
      ComandaController comandaController, Itens item) async {
    final controller = TextEditingController(
      text: (item.desconto ?? 0).toStringAsFixed(2).replaceAll('.', ','),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconto do item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Valor do desconto',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            final desconto = _parseValor(controller.text);
            if (desconto != null && desconto >= 0) {
              comandaController.alteraDescontoItem(item.codigo, desconto);
              Navigator.pop(context);
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
              final desconto = _parseValor(controller.text);
              if (desconto != null && desconto >= 0) {
                comandaController.alteraDescontoItem(item.codigo, desconto);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  _buildAcoes(Itens item, ComandaController comandaController) {
    return Row(children: [
      IconButton(
        onPressed: () {
          _telaObservacao(comandaController, item);
        },
        color: Colors.green,
        icon: Icon(
          Icons.edit,
          size: 24,
          color: item.quantidade! > 0 ? Colors.black : Colors.grey,
        ),
      ),
      SizedBox(
        height: 20,
      ),
      IconButton(
        onPressed: () {
          _telaDesconto(comandaController, item);
        },
        color: Colors.orange,
        icon: Icon(
          Icons.discount,
          size: 24,
          color: item.quantidade! > 0 ? Colors.black : Colors.grey,
        ),
      ),
      SizedBox(
        height: 20,
      ),
      IconButton(
        onPressed: () async {
          final produtoService = ProdutosService();
          final produto = await produtoService.fetchProduto(item.produto!);
          final complementoController = ComplementosController();
          final complementos = await complementoController.buscaComplementos(
              grupo: produto.categoria);
          showDialog(
            context: context,
            builder: (context) => AdicionaisWidget(
              item: item,
              complementos: complementos,
            ),
          );
        },
        color: Colors.red,
        icon: Icon(
          Icons.add_circle,
          size: 24,
          color: item.quantidade! > 0 ? Colors.black : Colors.grey,
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final comandaController = Provider.of<ComandaController>(context);
    return _buildAcoes(widget.item, comandaController);
  }
}
