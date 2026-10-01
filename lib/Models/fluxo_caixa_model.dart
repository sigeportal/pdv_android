class FluxoCaixaLancamento {
  final int codigo;
  final String data;
  final String dataHora;
  final String descricao;
  final String nome;
  final double credito;
  final double debito;
  final int pdv;

  FluxoCaixaLancamento({
    required this.codigo,
    required this.data,
    required this.dataHora,
    required this.descricao,
    required this.nome,
    required this.credito,
    required this.debito,
    required this.pdv,
  });

  factory FluxoCaixaLancamento.fromJson(Map<String, dynamic> json) {
    return FluxoCaixaLancamento(
      codigo: json['codigo'] ?? 0,
      data: json['data'] ?? '',
      dataHora: json['data_hora'] ?? '',
      descricao: json['descricao'] ?? '',
      nome: json['nome'] ?? '',
      credito: (json['credito'] ?? 0).toDouble(),
      debito: (json['debito'] ?? 0).toDouble(),
      pdv: json['pdv'] ?? 0,
    );
  }
}

class FluxoCaixaResumo {
  final double totalCredito;
  final double totalDebito;
  final double saldo;
  final List<FluxoCaixaLancamento> itens;

  FluxoCaixaResumo({
    required this.totalCredito,
    required this.totalDebito,
    required this.saldo,
    required this.itens,
  });
}

class CaixaStatus {
  final int pdv;
  final bool aberto;
  final int? caixa;
  final String? dataAbertura;
  final String? horaAbertura;

  const CaixaStatus({
    required this.pdv,
    required this.aberto,
    this.caixa,
    this.dataAbertura,
    this.horaAbertura,
  });

  factory CaixaStatus.fromJson(Map<String, dynamic> json) {
    return CaixaStatus(
      pdv: json['pdv'] ?? 1,
      aberto: json['aberto'] == true,
      caixa: json['caixa'],
      dataAbertura: json['data_abertura'],
      horaAbertura: json['hora_abertura'],
    );
  }
}
