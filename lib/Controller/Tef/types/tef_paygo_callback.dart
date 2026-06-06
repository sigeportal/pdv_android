import 'package:paygo_sdk/paygo_integrado_uri/domain/models/transacao/transacao_requisicao_resposta.dart';

/// Interface de callback para eventos do TEF PayGo
abstract class TefPayGoCallBack {
  /// Chamado quando uma transação financeira é finalizada com sucesso
  void onFinishTransaction(TransacaoRequisicaoResposta response);

  /// Chamado quando uma operação não financeira é finalizada
  void onFinishOperation(TransacaoRequisicaoResposta response);

  /// Chamado quando há uma transação pendente
  void onPendingTransaction(String transactionPendingData);

  /// Chamado para exibir mensagem de sucesso
  Future<void> onSuccessMessage(String message);

  /// Chamado para exibir mensagem de erro
  Future<void> onErrorMessage(String message);

  /// Chamado para imprimir comprovantes
  Future<void> onPrinter(TransacaoRequisicaoResposta resposta);

  /// Verifica se os requisitos para confirmar a transação foram atendidos
  bool checkRequirmentsToConfirmTransaction();
}
