class SubDespesa {
  final int codigo;
  final String nome;

  const SubDespesa({
    required this.codigo,
    required this.nome,
  });

  factory SubDespesa.fromJson(Map<String, dynamic> json) {
    final codigo = json['codigo'] ?? json['Codigo'] ?? 0;
    return SubDespesa(
      codigo: codigo is num ? codigo.toInt() : int.tryParse('$codigo') ?? 0,
      nome: (json['nome'] ?? json['Nome'] ?? '').toString(),
    );
  }
}

class DespesaLancamento {
  final int subDespesa;
  final String subDespesaNome;
  final double valor;
  final DateTime data;
  final String documento;
  final String historico;
  final int funcionario;
  final int pdv;
  final int conta;
  final String tipoPagamento;

  const DespesaLancamento({
    required this.subDespesa,
    required this.subDespesaNome,
    required this.valor,
    required this.data,
    required this.documento,
    required this.historico,
    required this.funcionario,
    required this.pdv,
    this.conta = 0,
    this.tipoPagamento = 'DINHEIRO',
  });

  Map<String, dynamic> toJson() {
    final dataFormatada = _toYmd(data);

    return {
      'SubDespesa': subDespesa,
      'SubDespesaNome': subDespesaNome,
      'Valor': valor,
      'Data': dataFormatada,
      'Documento': documento,
      'Historico': historico,
      'Funcionario': funcionario,
      'PDV': pdv,
      'Conta': conta,
      'TipoPagamento': tipoPagamento,
    };
  }

  static String _toYmd(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
