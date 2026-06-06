class Cliente {
  final int codigo;
  final String nome;
  final String endereco;
  final String bairro;
  final String cidade;
  final String cep;
  final String uf;
  final String fone;
  final String email;
  final DateTime datac;
  final DateTime datau;
  final String tipo;
  final String celular;
  final String endcorresp;
  final String obs;
  final String cnpj_cpf;
  final String situacao;
  final int plano;
  final double limite;
  final int datanasc;
  final String rg;
  final String pai;
  final String mae;
  final String fidelidade;
  final double desconto;
  final String conjuge;
  final int inadimplencia;
  final String insc_estadual;
  final String insc_municipal;
  final int cod_pais;
  final String suframa;
  final String numero;
  final String complemento;
  final int classificacao;
  final String nota;
  final int classificacao2;
  final String descontar;
  final String cadastro;
  final int data_u_a;
  final String bairroc;
  final String cidadec;
  final double limite_tit;
  final int tipo_entr;
  final String abc;
  final int ordena_abc;
  final int vencimento;
  final int cid;
  final String razao_social;
  final String indic_ie;
  final int pmr;

  Cliente({
    required this.codigo,
    required this.nome,
    required this.endereco,
    required this.bairro,
    required this.cidade,
    required this.cep,
    required this.uf,
    required this.fone,
    required this.email,
    required this.datac,
    required this.datau,
    required this.tipo,
    required this.celular,
    required this.endcorresp,
    required this.obs,
    required this.cnpj_cpf,
    required this.situacao,
    required this.plano,
    required this.limite,
    required this.datanasc,
    required this.rg,
    required this.pai,
    required this.mae,
    required this.fidelidade,
    required this.desconto,
    required this.conjuge,
    required this.inadimplencia,
    required this.insc_estadual,
    required this.insc_municipal,
    required this.cod_pais,
    required this.suframa,
    required this.numero,
    required this.complemento,
    required this.classificacao,
    required this.nota,
    required this.classificacao2,
    required this.descontar,
    required this.cadastro,
    required this.data_u_a,
    required this.bairroc,
    required this.cidadec,
    required this.limite_tit,
    required this.tipo_entr,
    required this.abc,
    required this.ordena_abc,
    required this.vencimento,
    required this.cid,
    required this.razao_social,
    required this.indic_ie,
    required this.pmr,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      codigo: json['codigo'] ?? 0,
      nome: json['nome'] ?? '',
      endereco: json['endereco'] ?? '',
      bairro: json['bairro'] ?? '',
      cidade: json['cidade'] ?? '',
      cep: json['cep'] ?? '',
      uf: json['uf'] ?? '',
      fone: json['fone'] ?? '',
      email: json['email'] ?? '',
      datac: json['datac'] != null
          ? DateTime.parse(json['datac'])
          : DateTime.now(),
      datau: json['datau'] != null
          ? DateTime.parse(json['datau'])
          : DateTime.now(),
      tipo: json['tipo'] ?? '',
      celular: json['celular'] ?? '',
      endcorresp: json['endcorresp'] ?? '',
      obs: json['obs'] ?? '',
      cnpj_cpf: json['cnpj_cpf'] ?? '',
      situacao: json['situacao'] ?? '',
      plano: json['plano'] ?? 0,
      limite: (json['limite'] ?? 0).toDouble(),
      datanasc: json['datanasc'] ?? 0,
      rg: json['rg'] ?? '',
      pai: json['pai'] ?? '',
      mae: json['mae'] ?? '',
      fidelidade: json['fidelidade'] ?? '',
      desconto: (json['desconto'] ?? 0).toDouble(),
      conjuge: json['conjuge'] ?? '',
      inadimplencia: json['inadimplencia'] ?? 0,
      insc_estadual: json['insc_estadual'] ?? '',
      insc_municipal: json['insc_municipal'] ?? '',
      cod_pais: json['cod_pais'] ?? 0,
      suframa: json['suframa'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'] ?? '',
      classificacao: json['classificacao'] ?? 0,
      nota: json['nota'] ?? '',
      classificacao2: json['classificacao2'] ?? 0,
      descontar: json['descontar'] ?? '',
      cadastro: json['cadastro'] ?? '',
      data_u_a: json['data_u_a'] ?? 0,
      bairroc: json['bairroc'] ?? '',
      cidadec: json['cidadec'] ?? '',
      limite_tit: (json['limite_tit'] ?? 0).toDouble(),
      tipo_entr: json['tipo_entr'] ?? 0,
      abc: json['abc'] ?? '',
      ordena_abc: json['ordena_abc'] ?? 0,
      vencimento: json['vencimento'] ?? 0,
      cid: json['cid'] ?? 0,
      razao_social: json['razao_social'] ?? '',
      indic_ie: json['indic_ie'] ?? '',
      pmr: json['pmr'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'nome': nome,
      'endereco': endereco,
      'bairro': bairro,
      'cidade': cidade,
      'cep': cep,
      'uf': uf,
      'fone': fone,
      'email': email,
      'datac': datac.toIso8601String(),
      'datau': datau.toIso8601String(),
      'tipo': tipo,
      'celular': celular,
      'endcorresp': endcorresp,
      'obs': obs,
      'cnpj_cpf': cnpj_cpf,
      'situacao': situacao,
      'plano': plano,
      'limite': limite,
      'datanasc': datanasc,
      'rg': rg,
      'pai': pai,
      'mae': mae,
      'fidelidade': fidelidade,
      'desconto': desconto,
      'conjuge': conjuge,
      'inadimplencia': inadimplencia,
      'insc_estadual': insc_estadual,
      'insc_municipal': insc_municipal,
      'cod_pais': cod_pais,
      'suframa': suframa,
      'numero': numero,
      'complemento': complemento,
      'classificacao': classificacao,
      'nota': nota,
      'classificacao2': classificacao2,
      'descontar': descontar,
      'cadastro': cadastro,
      'data_u_a': data_u_a,
      'bairroc': bairroc,
      'cidadec': cidadec,
      'limite_tit': limite_tit,
      'tipo_entr': tipo_entr,
      'abc': abc,
      'ordena_abc': ordena_abc,
      'vencimento': vencimento,
      'cid': cid,
      'razao_social': razao_social,
      'indic_ie': indic_ie,
      'pmr': pmr,
    };
  }
}
