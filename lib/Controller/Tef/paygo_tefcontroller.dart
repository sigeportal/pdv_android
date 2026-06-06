import 'dart:async';

import 'package:lanchonete/Controller/Tef/paygo_request_handler.dart';
import 'package:lanchonete/Controller/Tef/paygo_response_handler.dart';
import 'package:lanchonete/Controller/Tef/types/pending_transaction_actions.dart';
import 'package:lanchonete/Controller/Tef/types/tef_paygo_callback.dart';
import 'package:lanchonete/Models/tef_paygo_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_resposta.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_venda.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/transaction_status.dart';

/// [TefController] é a classe que implementa as regras de negócio do TEF PayGo
/// * Propriedades configuráveis:
/// * - [_configuracoes]: Instância de [TefPayGoConfiguracoes]
class TefController extends GetxController implements TefPayGoCallBack {
  final PayGoRequestHandler _payGORequestHandler = PayGoRequestHandler();
  late PayGOResponseHandler _payGOResponseHandler;
  late TefPayGoConfiguracoes _configuracoes = TefPayGoConfiguracoes();
  Completer<TransacaoRequisicaoResposta>? _vendaCompleter;
  
  static const VALOR_MINIMO_VENDA = 1.00;
  static const VALOR_MAXIMO_VENDA = 100000.00;

  // Getters e Setter
  PayGoRequestHandler get payGORequestHandler => _payGORequestHandler;

  PayGOResponseHandler get payGOResponseHandler => _payGOResponseHandler;

  TefPayGoConfiguracoes get configuracoes => _configuracoes;

  set configuracoes(TefPayGoConfiguracoes configuracoes) {
    _configuracoes = configuracoes;
  }

  Future<void> instalacao() => _payGORequestHandler.instalacao();

  Future<void> manutencao() => _payGORequestHandler.manutencao();

  Future<void> painelAdministrativo() =>
      _payGORequestHandler.painelAdministrativo();

  Future<void> reimpressao() => _payGORequestHandler.reimpressao();

  Future<void> exibePDC() => _payGORequestHandler.exibePDC();

  Future<void> relatorioDetalhado() =>
      _payGORequestHandler.relatorioDetalhado();

  Future<void> relatorioResumido() => _payGORequestHandler.relatorioResumido();

  Future<TransacaoRequisicaoResposta> vender(
      TransacaoRequisicaoVenda transacao) async {
    if (_vendaCompleter != null && !_vendaCompleter!.isCompleted) {
      throw Exception('Ja existe uma transacao TEF em andamento.');
    }

    _vendaCompleter = Completer<TransacaoRequisicaoResposta>();
    try {
      await _payGORequestHandler.venda(transacao);
    } catch (e) {
      _vendaCompleter = null;
      rethrow;
    }
    return _vendaCompleter!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _vendaCompleter = null;
        throw TimeoutException('Tempo esgotado aguardando retorno do PayGo.');
      },
    );
  }

  @override
  Future<void> onPrinter(TransacaoRequisicaoResposta resposta) async {
    // Implementação de impressão pode ser adicionada futuramente
    debugPrint("Impressão: ${resposta.operation}");
  }

  @override
  Future<void> onSuccessMessage(String message) async {
    await _showDialog("Sucesso", message, Colors.green, Icons.check_circle);
  }

  @override
  Future<void> onErrorMessage(String message) async {
    if (_vendaCompleter != null && !_vendaCompleter!.isCompleted) {
      _vendaCompleter!.completeError(Exception(message));
      _vendaCompleter = null;
    }
    await _showDialog("Erro", message, Colors.red, Icons.error);
  }

  /// [_showDialog] é um método auxiliar para mostrar diálogos de sucesso ou erro
  /// * [title] é o título do diálogo
  /// * [message] é a mensagem a ser exibida
  /// * [backgroundColor] é a cor de fundo do diálogo
  /// * [icon] é o ícone a ser exibido no diálogo
  Future<void> _showDialog(String title, String message, Color backgroundColor,
      IconData icon) async {
    await Future.wait([
      Get.defaultDialog(
        title: title,
        titleStyle: TextStyle(color: Colors.white),
        backgroundColor: backgroundColor,
        middleText: message,
        barrierDismissible: false,
        radius: 10.0,
        content: Column(
          children: [
            Icon(icon, color: Colors.white, size: 50),
            SizedBox(height: 10),
            Text(message, style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      Future.delayed(Duration(seconds: 3), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      })
    ]);
  }

  @override
  void onFinishTransaction(TransacaoRequisicaoResposta response) async {
    // Aqui você pode implementar a lógica para salvar a transação no banco de dados, notas fiscais, etc
    if (checkRequirmentsToConfirmTransaction()) {
      await _payGORequestHandler.confirmarTransacao(
          response.confirmationTransactionId, _configuracoes.tipoDeConfirmacao);
      await onSuccessMessage(response.resultMessage);
      // A impressão é opcional
      await onPrinter(response);
      
      // Redireciona para a tela inicial após sucesso
      if (_vendaCompleter != null && !_vendaCompleter!.isCompleted) {
        _vendaCompleter!.complete(response);
        _vendaCompleter = null;
      }
    } else if (_vendaCompleter != null && !_vendaCompleter!.isCompleted) {
      _vendaCompleter!.completeError(
        Exception('Transacao aprovada aguardando confirmacao manual.'),
      );
      _vendaCompleter = null;
    }
  }

  @override
  void onPendingTransaction(String transactionPendingData) async {
    if (_vendaCompleter != null && !_vendaCompleter!.isCompleted) {
      _vendaCompleter!.completeError(
        Exception('Existe transacao pendente no PayGo. Resolva a pendencia.'),
      );
      _vendaCompleter = null;
    }
    switch (_configuracoes.pendingTransactionActions) {
      case PendingTransactionActions.CONFIRM:
        await _payGORequestHandler.resolverPendencia(
            transactionPendingData, TransactionStatus.confirmadoManual);
        break;

      case PendingTransactionActions.MANUAL_UNDO:
        await _payGORequestHandler.resolverPendencia(transactionPendingData);
        break;

      case PendingTransactionActions.NONE:
      default:
        debugPrint("Nenhuma ação definida para transação pendente");
        break;
    }
  }

  @override
  void onFinishOperation(TransacaoRequisicaoResposta response) async {
    switch (response.operation) {
      case "REIMPRESSAO":
        await onPrinter(response);
        break;

      // outras operações (não financeiras) que não sejam impressão
      default:
        await _handleOutraOperacao(response);
        break;
    }
  }

  Future<void> _handleOutraOperacao(
      TransacaoRequisicaoResposta resposta) async {
    if (resposta.transactionResult == "0")
      await onSuccessMessage(resposta.resultMessage);
    else
      await onErrorMessage(resposta.resultMessage);
  }

  /// Função auxiliar que verifica se os requisitos para confirmar a transação foram atendidos
  @override
  bool checkRequirmentsToConfirmTransaction() {
    // Aqui você pode implementar a lógica para verificar se os requisitos para confirmar a transação foram atendidos
    return _configuracoes.isAutoConfirm == true;
  }

  /// Métodos de controle de estado
  @override
  void onInit() {
    super.onInit();
    _payGOResponseHandler = PayGOResponseHandler(this);
  }

  @override
  void onReady() {
    super.onReady();
    _payGOResponseHandler.inicializar();
  }

  @override
  void onClose() {
    super.onClose();
    _payGOResponseHandler.finalizar();
  }
}
