import 'package:lanchonete/Models/comanda_model.dart';
import 'package:lanchonete/Models/complementos_model.dart';
import 'package:lanchonete/Models/grade_produto_model.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Models/niveis_model.dart';
import 'package:lanchonete/Models/produtos_model.dart';
import 'package:lanchonete/Services/ComandaService.dart';
import 'package:lanchonete/Services/VendaService.dart';
import 'package:flutter/cupertino.dart';

class ComandaController extends ChangeNotifier {
  List<Itens> itens = [];

  double get valorComanda {
    double somaTotal = 0.0;

    for (var item in itens) {
      double valorItemBase = (item.valor ?? 0.0).toDouble();
      double valorAdicionais = 0.0;

      if (item.complementos != null && item.complementos!.isNotEmpty) {
        for (var comp in item.complementos!) {
          double valComp = (comp.valor).toDouble();
          double qtdComp = (comp.quantidade ?? 1).toDouble();
          valorAdicionais += (valComp * qtdComp);
        }
      }

      if (item.opcoesNiveis != null && item.opcoesNiveis!.isNotEmpty) {
        for (var op in item.opcoesNiveis!) {
          double valOp = (op.valorAdicional).toDouble();
          double qtdOp = (op.quantidade ?? 1).toDouble();
          valorAdicionais += (valOp * qtdOp);
        }
      }

      double quantidadeItem = (item.quantidade ?? 1.0).toDouble();
      if (quantidadeItem == 0) quantidadeItem = 1.0;

      double valorUnitarioCheio = valorItemBase + valorAdicionais;
      somaTotal += (valorUnitarioCheio * quantidadeItem);
    }

    return somaTotal;
  }

  double getQuantidade(int produto) {
    double quantidade = 0;
    for (var element in itens) {
      if (element.produto == produto) {
        quantidade += element.quantidade!;
      }
    }
    return quantidade;
  }

  int get totalItens => itens.length;
  bool get isEmpty => itens.isEmpty;

  void carregarItensDaComanda(List<Itens> itensDoBanco) {
    itens.clear();
    itens.addAll(itensDoBanco);
    notifyListeners();
  }

  void adicionaItem(Produtos produto, String idAgrupamento,
      {GradeProduto? gradeProduto,
      double quantidade = 1.0,
      required int usuario}) {
    itens.add(
      Itens(
        // Os itens locais recebem um código gigante baseado na data/hora
        codigo: DateTime.now().millisecondsSinceEpoch,
        produto: produto.codigo,
        quantidade: quantidade,
        valor: produto.valor,
        nome: produto.nome,
        grade: produto.grade,
        codGrupo: produto.grupo,
        gradeProduto: gradeProduto,
        usuario: usuario,
        idAgrupamento: (gradeProduto != null) ? idAgrupamento : '',
        complementos: [],
        opcoesNiveis: [],
        isBebida: produto.g1_nome.toLowerCase().contains('bebida'),
        isPastel: produto.g1_nome.toLowerCase().contains('past'),
      ),
    );

    notifyListeners();
  }

  void clear() {
    itens.clear();
    notifyListeners();
  }

  void removeItem(int? codProduto) {
    var index = itens.lastIndexWhere((e) => e.produto == codProduto);
    if (index != -1) {
      itens.removeAt(index);
      notifyListeners();
    }
  }

  void removeItemCarrinho(Itens item) {
    itens.remove(item);
    notifyListeners();
  }

  void diminuirQuantidade(int? codigo) {
    var index = itens.lastIndexWhere((e) => e.produto == codigo);

    if (index != -1) {
      var item = itens[index];
      if ((item.quantidade ?? 0) > 1) {
        item.quantidade = item.quantidade! - 1.0;
      } else {
        itens.removeAt(index);
      }
    }
    notifyListeners();
  }

  // --- FUNÇÃO CORRIGIDA PARA ENVIAR APENAS ITENS NOVOS ---
  Future<bool> insereComanda(int? mesa) async {
    final comandaService = ComandaService();
    var resultado = false;
    try {
      // 1. Busca como a comanda está lá no banco atualmente
      var comandaExistente = await comandaService.fetchComanda(mesa);

      var comanda = Comanda();
      comanda.mesa = mesa;
      comanda.valor = valorComanda; // Envia o valor atualizado e recalculado

      if (comandaExistente.itens == null || comandaExistente.itens!.isEmpty) {
        // Se o banco retornou vazio, é uma COMANDA NOVA, envia tudo.
        comanda.itens = [...itens];
        resultado = await comandaService.criaComanda(comanda);
      } else {
        // Se a comanda JÁ EXISTE, filtramos a lista.
        // O segredo: Se o código do item local NÃO existir na lista do banco, é porque ele é NOVO.
        List<Itens> itensNovos = itens.where((itemLocal) {
          return !comandaExistente.itens!
              .any((itemBanco) => itemBanco.codigo == itemLocal.codigo);
        }).toList();

        // Envia apenas o delta (o que for novo) para o PUT
        comanda.itens = itensNovos;

        resultado = await comandaService.atualizarComanda(comanda);
      }

      if (resultado) {
        clear(); // Limpa o carrinho após enviar para a cozinha
      }
      return resultado;
    } catch (e) {
      throw Exception(e);
    }
  }

  void adicionaObservacao(int? codItem, String obs) {
    var indice = itens.indexWhere((element) => element.codigo == codItem);
    if (indice != -1) {
      itens[indice].obs = obs;
      notifyListeners();
    }
  }

  void adicionaComplementos(int? codItem, List<Complementos> complementos) {
    var indice = itens.indexWhere((element) => element.codigo == codItem);
    if (indice != -1) {
      itens[indice].complementos = List.from(complementos);
      notifyListeners();
    }
  }

  void adicionaOpcoesNivel(int? codItem, List<OpcaoNivel> opcoes) {
    var indice = itens.indexWhere((element) => element.codigo == codItem);
    if (indice != -1) {
      itens[indice].opcoesNiveis = List.from(opcoes);
      notifyListeners();
    }
  }

  Future<bool> deletarItemComanda(int codigo) async {
    final comandaService = ComandaService();
    try {
      final result = await comandaService.deletarItemComanda(codigo);
      return result;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Comanda> buscaComanda(int codigo) async {
    final comandaService = ComandaService();
    try {
      final result = await comandaService.fetchComanda(codigo);
      return result;
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<Map<String, dynamic>> inserirVenda(
      Map<String, dynamic> vendaData) async {
    final vendaService = VendaService();
    try {
      final resultado = await vendaService.inserirVenda(vendaData);
      notifyListeners();
      return resultado;
    } catch (e) {
      throw Exception('Erro ao inserir venda: $e');
    }
  }
}
