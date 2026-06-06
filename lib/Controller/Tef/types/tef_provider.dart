/// Provedores TEF disponíveis
enum TefProvider {
  /// Modo demonstração
  DEMO,
  
  /// Nenhum provedor específico
  NENHUM,
}

extension TefProviderExtension on TefProvider {
  /// Converte o enum para o valor string usado pelo PayGo SDK
  String toValue() {
    switch (this) {
      case TefProvider.DEMO:
        return "DEMO";
      case TefProvider.NENHUM:
        return "";
    }
  }
}
