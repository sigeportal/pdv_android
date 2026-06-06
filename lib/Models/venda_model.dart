// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:lanchonete/Models/complementos_model.dart';
import 'package:lanchonete/Models/niveis_model.dart';

class Venda {
  final int codigo;
  final DateTime data;
  final double valor;
  final double hora;
  final int fun;
  final int nf;
  final double diferenca;
  final int datac;
  final int fat;
  final int dav;
  final int cli;
  final String devolucao_p;
  final String tipo_pedido;
  final double taxa_entrega;
  final int forma_pgto;
  final String nome_cliente;
  final String id_pedido;
  final List<ItemVenda> itens;
  final PedFat? pedFat;

  Venda({
    required this.codigo,
    required this.data,
    required this.valor,
    required this.hora,
    required this.fun,
    required this.nf,
    required this.diferenca,
    required this.datac,
    required this.fat,
    required this.dav,
    required this.cli,
    required this.devolucao_p,
    required this.tipo_pedido,
    required this.taxa_entrega,
    required this.forma_pgto,
    required this.nome_cliente,
    required this.id_pedido,
    required this.itens,
    this.pedFat,
  });

  factory Venda.fromJson(Map<String, dynamic> json) {
    return Venda(
      codigo: json['codigo'] ?? 0,
      data: DateTime.parse(json['data'] ?? DateTime.now().toIso8601String()),
      valor: (json['valor'] ?? 0).toDouble(),
      hora: (json['hora'] ?? 0).toDouble(),
      fun: json['fun'] ?? 0,
      nf: json['nf'] ?? 0,
      diferenca: (json['diferenca'] ?? 0).toDouble(),
      datac: json['datac'] ?? 0,
      fat: json['fat'] ?? 0,
      dav: json['dav'] ?? 0,
      cli: json['cli'] ?? 0,
      devolucao_p: json['devolucao_p'] ?? 'N',
      tipo_pedido: json['tipo_pedido'] ?? '',
      taxa_entrega: (json['taxa_entrega'] ?? 0).toDouble(),
      forma_pgto: json['forma_pgto'] ?? 0,
      nome_cliente: json['nome_cliente'] ?? '',
      id_pedido: json['id_pedido'] ?? '',
      itens: (json['itens'] as List?)
              ?.map((e) => ItemVenda.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pedFat: json['pedFat'] != null
          ? PedFat.fromJson(json['pedFat'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'data': data.toIso8601String(),
      'valor': valor,
      'hora': hora,
      'fun': fun,
      'nf': nf,
      'diferenca': diferenca,
      'datac': datac,
      'fat': fat,
      'dav': dav,
      'cli': cli,
      'devolucao_p': devolucao_p,
      'tipo_pedido': tipo_pedido,
      'taxa_entrega': taxa_entrega,
      'forma_pgto': forma_pgto,
      'nome_cliente': nome_cliente,
      'id_pedido': id_pedido,
      'itens': itens.map((e) => e.toJson()).toList(),
      'pedFat': pedFat?.toJson(),
    };
  }
}

class ItemVenda {
  final int codigo;
  final double valor;
  final int quantidade;
  final int ven;
  final int pro;
  final double lucro;
  final double valorr;
  final double valorl;
  final double valorf;
  final double diferenca;
  final int liquido;
  final double valor2;
  final double valorcm;
  final double aliquota;
  final String gtin;
  final String embalagem;
  final double valorb;
  final double desconto;
  final double valorc;
  final String obs;
  final int gra;
  final String semente_tratada;
  final double valor_partida;
  final int variacao;
  final int usu;
  List<Complementos>? complementos;
  List<OpcaoNivel>? opcoesNivel;

  ItemVenda({
    required this.codigo,
    required this.valor,
    required this.quantidade,
    required this.ven,
    required this.pro,
    required this.lucro,
    required this.valorr,
    required this.valorl,
    required this.valorf,
    required this.diferenca,
    required this.liquido,
    required this.valor2,
    required this.valorcm,
    required this.aliquota,
    required this.gtin,
    required this.embalagem,
    required this.valorb,
    required this.desconto,
    required this.valorc,
    required this.obs,
    required this.gra,
    required this.semente_tratada,
    required this.valor_partida,
    required this.variacao,
    required this.usu,
    required this.complementos,
    required this.opcoesNivel,
  });

  factory ItemVenda.fromJson(Map<String, dynamic> json) {
    return ItemVenda(
      codigo: json['codigo'] ?? 0,
      valor: (json['valor'] ?? 0).toDouble(),
      quantidade: json['quantidade'] ?? 0,
      ven: json['ven'] ?? 0,
      pro: json['pro'] ?? 0,
      lucro: (json['lucro'] ?? 0).toDouble(),
      valorr: (json['valorr'] ?? 0).toDouble(),
      valorl: (json['valorl'] ?? 0).toDouble(),
      valorf: (json['valorf'] ?? 0).toDouble(),
      diferenca: (json['diferenca'] ?? 0).toDouble(),
      liquido: json['liquido'] ?? 0,
      valor2: (json['valor2'] ?? 0).toDouble(),
      valorcm: (json['valorcm'] ?? 0).toDouble(),
      aliquota: (json['aliquota'] ?? 0).toDouble(),
      gtin: json['gtin'] ?? '',
      embalagem: json['embalagem'] ?? '',
      valorb: (json['valorb'] ?? 0).toDouble(),
      desconto: (json['desconto'] ?? 0).toDouble(),
      valorc: (json['valorc'] ?? 0).toDouble(),
      obs: json['obs'] ?? '',
      gra: json['gra'] ?? 0,
      semente_tratada: json['semente_tratada'] ?? 'N',
      valor_partida: (json['valor_partida'] ?? 0).toDouble(),
      variacao: json['variacao'] ?? 0,
      usu: json['usu'] ?? 0,
      complementos: [],
      opcoesNivel: (json['opcoesNivel'] as List?)
              ?.map((e) => OpcaoNivel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'valor': valor,
      'quantidade': quantidade,
      'ven': ven,
      'pro': pro,
      'lucro': lucro,
      'valorr': valorr,
      'valorl': valorl,
      'valorf': valorf,
      'diferenca': diferenca,
      'liquido': liquido,
      'valor2': valor2,
      'valorcm': valorcm,
      'aliquota': aliquota,
      'gtin': gtin,
      'embalagem': embalagem,
      'valorb': valorb,
      'desconto': desconto,
      'valorc': valorc,
      'obs': obs,
      'gra': gra,
      'semente_tratada': semente_tratada,
      'valor_partida': valor_partida,
      'variacao': variacao,
      'usu': usu,
      'complementos': [],
      'opcoesNivel': opcoesNivel != null
          ? opcoesNivel!.map((e) => e.toJson()).toList()
          : [],
    };
  }
}

class PedFat {
  final int codigo;
  final int ficha;
  final int cod_ped;
  final double desconto;
  final double valor;
  final DateTime datac;
  final double valorpg;
  final String cliente;
  final String tabela;
  final double valorb;
  final int fun;
  final String campo_datac;
  final int fat;
  final int parcelas;
  final String campo_fat;
  final int tipo;
  final int cod_cli;
  final String campo_ped;
  final DateTime data;
  final List<PFParcela> pFParcelas;

  PedFat({
    required this.codigo,
    required this.ficha,
    required this.cod_ped,
    required this.desconto,
    required this.valor,
    required this.datac,
    required this.valorpg,
    required this.cliente,
    required this.tabela,
    required this.valorb,
    required this.fun,
    required this.campo_datac,
    required this.fat,
    required this.parcelas,
    required this.campo_fat,
    required this.tipo,
    required this.cod_cli,
    required this.campo_ped,
    required this.data,
    required this.pFParcelas,
  });

  factory PedFat.fromJson(Map<String, dynamic> json) {
    return PedFat(
      codigo: json['codigo'] ?? 0,
      ficha: json['ficha'] ?? 0,
      cod_ped: json['cod_ped'] ?? 0,
      desconto: (json['desconto'] ?? 0).toDouble(),
      valor: (json['valor'] ?? 0).toDouble(),
      datac: DateTime.parse(json['datac'] ?? DateTime.now().toIso8601String()),
      valorpg: (json['valorpg'] ?? 0).toDouble(),
      cliente: json['cliente'] ?? '',
      tabela: json['tabela'] ?? '',
      valorb: (json['valorb'] ?? 0).toDouble(),
      fun: json['fun'] ?? 0,
      campo_datac: json['campo_datac'] ?? '',
      fat: json['fat'] ?? 0,
      parcelas: json['parcelas'] ?? 0,
      campo_fat: json['campo_fat'] ?? '',
      tipo: json['tipo'] ?? 0,
      cod_cli: json['cod_cli'] ?? 0,
      campo_ped: json['campo_ped'] ?? '',
      data: DateTime.parse(json['data'] ?? DateTime.now().toIso8601String()),
      pFParcelas: (json['pFParcelas'] as List?)
              ?.map((e) => PFParcela.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'ficha': ficha,
      'cod_ped': cod_ped,
      'desconto': desconto,
      'valor': valor,
      'datac': datac.toIso8601String(),
      'valorpg': valorpg,
      'cliente': cliente,
      'tabela': tabela,
      'valorb': valorb,
      'fun': fun,
      'campo_datac': campo_datac,
      'fat': fat,
      'parcelas': parcelas,
      'campo_fat': campo_fat,
      'tipo': tipo,
      'cod_cli': cod_cli,
      'campo_ped': campo_ped,
      'data': data.toIso8601String(),
      'pFParcelas': pFParcelas.map((e) => e.toJson()).toList(),
    };
  }
}

class PFParcela {
  final int codigo;
  final String duplicata;
  final int pf;
  final double valor;
  final double valorpg;
  final DateTime vencimento;
  final double juros;
  final int tp;
  final double descontos;
  final int estado;
  final TipoPagamento? tipoPagamento;

  PFParcela({
    required this.codigo,
    required this.duplicata,
    required this.pf,
    required this.valor,
    required this.valorpg,
    required this.vencimento,
    required this.juros,
    required this.tp,
    required this.descontos,
    required this.estado,
    this.tipoPagamento,
  });

  factory PFParcela.fromJson(Map<String, dynamic> json) {
    return PFParcela(
      codigo: json['codigo'] ?? 0,
      duplicata: json['duplicata'] ?? '',
      pf: json['pf'] ?? 0,
      valor: (json['valor'] ?? 0).toDouble(),
      valorpg: (json['valorpg'] ?? 0).toDouble(),
      vencimento: DateTime.parse(
          json['vencimento'] ?? DateTime.now().toIso8601String()),
      juros: (json['juros'] ?? 0).toDouble(),
      tp: json['tp'] ?? 0,
      descontos: (json['descontos'] ?? 0).toDouble(),
      estado: json['estado'] ?? 0,
      tipoPagamento: TipoPagamento.fromJson(
          json['tipoPagamento'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'duplicata': duplicata,
      'pf': pf,
      'valor': valor,
      'valorpg': valorpg,
      'vencimento': vencimento.toIso8601String(),
      'juros': juros,
      'tp': tp,
      'descontos': descontos,
      'estado': estado,
      'tipoPagamento': tipoPagamento?.toJson(),
    };
  }
}

class TipoPagamento {
  final String titulo;
  final double sub_des;
  final double tx_operacao;
  final String descricao;
  final int codigo;
  final int con;
  final int dias_prazo_rec;
  final String condicao;
  final String analisar;
  final String nome;
  final String tipo;
  final double tx_antecipacao;
  final int ordenacao;

  TipoPagamento({
    required this.titulo,
    required this.sub_des,
    required this.tx_operacao,
    required this.descricao,
    required this.codigo,
    required this.con,
    required this.dias_prazo_rec,
    required this.condicao,
    required this.analisar,
    required this.nome,
    required this.tipo,
    required this.tx_antecipacao,
    required this.ordenacao,
  });

  factory TipoPagamento.fromJson(Map<String, dynamic> json) {
    return TipoPagamento(
      titulo: json['titulo'] ?? '',
      sub_des: (json['sub_des'] ?? 0).toDouble(),
      tx_operacao: (json['tx_operacao'] ?? 0).toDouble(),
      descricao: json['descricao'] ?? '',
      codigo: json['codigo'] ?? 0,
      con: json['con'] ?? 0,
      dias_prazo_rec: json['dias_prazo_rec'] ?? 0,
      condicao: json['condicao'] ?? '',
      analisar: json['analisar'] ?? '',
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      tx_antecipacao: (json['tx_antecipacao'] ?? 0).toDouble(),
      ordenacao: json['ordenacao'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'sub_des': sub_des,
      'tx_operacao': tx_operacao,
      'descricao': descricao,
      'codigo': codigo,
      'con': con,
      'dias_prazo_rec': dias_prazo_rec,
      'condicao': condicao,
      'analisar': analisar,
      'nome': nome,
      'tipo': tipo,
      'tx_antecipacao': tx_antecipacao,
      'ordenacao': ordenacao,
    };
  }
}
