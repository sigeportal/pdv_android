class VendaAnaliticoResponse {
  final PeriodoRelatorio periodo;
  final TotaisVendaAnalitico totais;
  final List<VendaAnalitico> vendas;
  final List<ResumoPagamento> resumoPagamentos;
  final int? caixaAtual;
  final int? pdv;
  final bool modoTodosCaixas;

  VendaAnaliticoResponse({
    required this.periodo,
    required this.totais,
    required this.vendas,
    required this.resumoPagamentos,
    this.caixaAtual,
    this.pdv,
    this.modoTodosCaixas = false,
  });

  factory VendaAnaliticoResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final int? cai = _toIntOrNull(data['caixa_atual']) ?? _toIntOrNull(data['periodo']?['caixa']);
    final int? p = _toIntOrNull(data['pdv']) ?? _toIntOrNull(data['periodo']?['pdv']);
    final bool todos = data['modo_todos_caixas'] == true ||
        data['modo_todos_caixas']?.toString() == 'true' ||
        data['periodo']?['todos_caixas'] == true ||
        data['periodo']?['todos_caixas']?.toString() == 'true';

    return VendaAnaliticoResponse(
      periodo: PeriodoRelatorio.fromJson(data['periodo'] ?? {}),
      totais: TotaisVendaAnalitico.fromJson(data['totais'] ?? {}),
      vendas: ((data['vendas'] as List?) ?? [])
          .map((item) => VendaAnalitico.fromJson(item))
          .toList(),
      resumoPagamentos: ((data['resumo_pagamentos'] as List?) ?? [])
          .map((item) => ResumoPagamento.fromJson(item))
          .toList(),
      caixaAtual: cai,
      pdv: p,
      modoTodosCaixas: todos,
    );
  }
}

class PeriodoRelatorio {
  final String dataInicio;
  final String dataFim;
  final int cliente;
  final int grupo;
  final String tipoPedido;
  final int pdv;
  final int caixa;
  final bool todosCaixas;

  PeriodoRelatorio({
    required this.dataInicio,
    required this.dataFim,
    required this.cliente,
    required this.grupo,
    required this.tipoPedido,
    this.pdv = 0,
    this.caixa = 0,
    this.todosCaixas = false,
  });

  factory PeriodoRelatorio.fromJson(Map<String, dynamic> json) {
    return PeriodoRelatorio(
      dataInicio: json['data_inicio']?.toString() ?? '',
      dataFim: json['data_fim']?.toString() ?? '',
      cliente: _toInt(json['cliente']),
      grupo: _toInt(json['grupo']),
      tipoPedido: json['tipo_pedido']?.toString() ?? '',
      pdv: _toInt(json['pdv']),
      caixa: _toInt(json['caixa']),
      todosCaixas: json['todos_caixas'] == true || json['todos_caixas']?.toString() == 'true',
    );
  }
}

class TotaisVendaAnalitico {
  final double subtotal;
  final double adicionais;
  final double taxaEntrega;
  final double canceladas;
  final double vendaVista;
  final double vendaPrazo;
  final double lucro;
  final double total;

  TotaisVendaAnalitico({
    required this.subtotal,
    required this.adicionais,
    required this.taxaEntrega,
    required this.canceladas,
    required this.vendaVista,
    required this.vendaPrazo,
    required this.lucro,
    required this.total,
  });

  factory TotaisVendaAnalitico.fromJson(Map<String, dynamic> json) {
    return TotaisVendaAnalitico(
      subtotal: _toDouble(json['subtotal']),
      adicionais: _toDouble(json['adicionais']),
      taxaEntrega: _toDouble(json['taxa_entrega']),
      canceladas: _toDouble(json['canceladas']),
      vendaVista: _toDouble(json['venda_vista']),
      vendaPrazo: _toDouble(json['venda_prazo']),
      lucro: _toDouble(json['lucro']),
      total: _toDouble(json['total']),
    );
  }
}

class VendaAnalitico {
  final int codigo;
  final int faturamento;
  final int funcionario;
  final String data;
  final String hora;
  final String cliente;
  final double valor;
  final double taxaEntrega;
  final String condicaoPgto;
  final List<PagamentoVenda> pagamentos;
  final List<ItemVendaAnalitico> itens;

  VendaAnalitico({
    required this.codigo,
    required this.faturamento,
    required this.funcionario,
    required this.data,
    required this.hora,
    required this.cliente,
    required this.valor,
    required this.taxaEntrega,
    required this.condicaoPgto,
    required this.pagamentos,
    required this.itens,
  });

  factory VendaAnalitico.fromJson(Map<String, dynamic> json) {
    return VendaAnalitico(
      codigo: _toInt(json['codigo']),
      faturamento: _toInt(json['faturamento']),
      funcionario: _toInt(json['funcionario']),
      data: json['data']?.toString() ?? '',
      hora: json['hora']?.toString() ?? '',
      cliente: json['cliente']?.toString() ?? '',
      valor: _toDouble(json['valor']),
      taxaEntrega: _toDouble(json['taxa_entrega']),
      condicaoPgto: json['condicao_pgto']?.toString() ?? '',
      pagamentos: ((json['pagamentos'] as List?) ?? [])
          .map((item) => PagamentoVenda.fromJson(item))
          .toList(),
      itens: ((json['itens'] as List?) ?? [])
          .map((item) => ItemVendaAnalitico.fromJson(item))
          .toList(),
    );
  }
}

class ItemVendaAnalitico {
  final int codigo;
  final int produto;
  final String descricao;
  final String abc;
  final String tamanho;
  final double quantidade;
  final double valorUnitario;
  final double valorBase;
  final double desconto;
  final double lucro;
  final List<AdicionalVenda> adicionais;

  ItemVendaAnalitico({
    required this.codigo,
    required this.produto,
    required this.descricao,
    required this.abc,
    required this.tamanho,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorBase,
    required this.desconto,
    required this.lucro,
    required this.adicionais,
  });

  factory ItemVendaAnalitico.fromJson(Map<String, dynamic> json) {
    return ItemVendaAnalitico(
      codigo: _toInt(json['codigo']),
      produto: _toInt(json['produto']),
      descricao: json['descricao']?.toString() ?? '',
      abc: json['abc']?.toString() ?? '',
      tamanho: json['tamanho']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      valorUnitario: _toDouble(json['valor_unitario']),
      valorBase: _toDouble(json['valor_base']),
      desconto: _toDouble(json['desconto']),
      lucro: _toDouble(json['lucro']),
      adicionais: ((json['adicionais'] as List?) ?? [])
          .map((item) => AdicionalVenda.fromJson(item))
          .toList(),
    );
  }
}

class AdicionalVenda {
  final String descricao;
  final double quantidade;
  final double valorUnitario;
  final double valorTotal;

  AdicionalVenda({
    required this.descricao,
    required this.quantidade,
    required this.valorUnitario,
    required this.valorTotal,
  });

  factory AdicionalVenda.fromJson(Map<String, dynamic> json) {
    return AdicionalVenda(
      descricao: json['descricao']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      valorUnitario: _toDouble(json['valor_unitario']),
      valorTotal: _toDouble(json['valor_total']),
    );
  }
}

class PagamentoVenda {
  final String duplicata;
  final String vencimento;
  final String tipo;
  final double valor;

  PagamentoVenda({
    required this.duplicata,
    required this.vencimento,
    required this.tipo,
    required this.valor,
  });

  factory PagamentoVenda.fromJson(Map<String, dynamic> json) {
    return PagamentoVenda(
      duplicata: json['duplicata']?.toString() ?? '',
      vencimento: json['vencimento']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      valor: _toDouble(json['valor']),
    );
  }
}

class ResumoPagamento {
  final String tipo;
  final String condicao;
  final double valor;

  ResumoPagamento({
    required this.tipo,
    required this.condicao,
    required this.valor,
  });

  factory ResumoPagamento.fromJson(Map<String, dynamic> json) {
    return ResumoPagamento(
      tipo: json['tipo']?.toString() ?? '',
      condicao: json['condicao']?.toString() ?? '',
      valor: _toDouble(json['valor']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
