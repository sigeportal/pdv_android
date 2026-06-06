/// Ações disponíveis para transações pendentes
enum PendingTransactionActions {
  /// Confirmar a transação pendente
  CONFIRM,
  
  /// Desfazer manualmente a transação pendente
  MANUAL_UNDO,
  
  /// Nenhuma ação automática
  NONE,
}
