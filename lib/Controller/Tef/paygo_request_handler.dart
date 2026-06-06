import 'package:flutter/material.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_confirmacao.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_pendencia.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/transaction_status.dart';
import 'package:paygo_sdk/paygo_sdk.dart';

/// PayGoRequestHandler é uma classe que abstrai as requisições do PayGo SDK
class PayGoRequestHandler {
  final _repository = PayGOSdk();

  late TransacaoRequisicaoDadosAutomacao _dadosAutomacao = TransacaoRequisicaoDadosAutomacao(
    "PDV Lanchonete",
    "1.0",
    "pdvlanchonete://",
    allowCashback: true,
    allowDifferentReceipts: true,
    allowDiscount: true,
    allowDueAmount: true,
    allowShortReceipt: true,
  );

  TransacaoRequisicaoDadosAutomacao get dadosAutomacao => _dadosAutomacao;
  set dadosAutomacao(TransacaoRequisicaoDadosAutomacao dadosAutomacao) {
    _dadosAutomacao = dadosAutomacao;
  }

  /// Realiza uma venda via TEF
  Future<void> venda(TransacaoRequisicaoVenda dadosVenda) async {
    // configura dados da automacao (obrigatorio para o TefPayGo)
    await _repository.integrado.venda(
      requisicaoVenda: dadosVenda,
      dadosAutomacao: _dadosAutomacao,
    );
  }

  /// Confirma uma transação realizada
  Future<void> confirmarTransacao(String id,
      [TransactionStatus status = TransactionStatus.confirmadoAutomatico]) async {
    await _repository.integrado.confirmarTransacao(
      intentAction: IntentAction.confirmation,
      requisicao: TransacaoRequisicaoConfirmacao(
        confirmationTransactionId: id,
        status: status,
      )
    ).then((value) {
      debugPrint("Venda confirmada");
    }).catchError((error) {
      debugPrint("Erro ao confirmar venda: $error");
    });
  }

  /// Resolve uma transação pendente
  Future<void> resolverPendencia(String transacaoPendenteDados,
      [TransactionStatus status = TransactionStatus.desfeitoManual]) async {
    await _repository.integrado.resolucaoPendencia(
      intentAction: IntentAction.confirmation,
      requisicaoPendencia: transacaoPendenteDados,
      requisicaoConfirmacao: TransacaoRequisicaoPendencia(status: status),
    );
  }

  /// Reimpressão de comprovante
  Future<void> reimpressao() async {
    await _repository.integrado.generico(
      intentAction: IntentAction.payment,
      requisicao: TransacaoRequisicaoGenerica(operation: Operation.reimpressao),
      dadosAutomacao: _dadosAutomacao,
    );
  }

  Future<void> instalacao() async {
    await _repository.integrado.generico(
      intentAction: IntentAction.payment,
      requisicao: TransacaoRequisicaoGenerica(operation: Operation.instalacao),
      dadosAutomacao: _dadosAutomacao,
    );
  }

  Future<void> manutencao() async {
    await _repository.integrado.generico(
      intentAction: IntentAction.payment,
      requisicao: TransacaoRequisicaoGenerica(operation: Operation.manutencao),
      dadosAutomacao: _dadosAutomacao,
    );
  }

  /// Painel administrativo
  Future<void> painelAdministrativo() async {
    await _repository.integrado.administrativo(
      dadosAutomacao: _dadosAutomacao,
    );
  }

  Future<void> exibePDC() async {
    await _repository.integrado.generico(
      intentAction: IntentAction.payment,
      requisicao: TransacaoRequisicaoGenerica(operation: Operation.exibePdc),
      dadosAutomacao: _dadosAutomacao,
    );
  }

  Future<void> relatorioDetalhado() async {
    await _repository.integrado.generico(
      intentAction: IntentAction.payment,
      requisicao: TransacaoRequisicaoGenerica(
        operation: Operation.relatorioDetalhado,
      ),
      dadosAutomacao: _dadosAutomacao,
    );
  }

  Future<void> relatorioResumido() async {
    await _repository.integrado.generico(
      intentAction: IntentAction.payment,
      requisicao: TransacaoRequisicaoGenerica(
        operation: Operation.relatorioResumido,
      ),
      dadosAutomacao: _dadosAutomacao,
    );
  }
}
