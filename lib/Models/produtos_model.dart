class Produtos {
  final int codigo;
  final String nome;
  final double valor;
  final int categoria;
  final int grade;
  final int grupo;
  final String g1_nome;

  Produtos(
      {required this.codigo,
      required this.nome,
      required this.valor,
      required this.categoria,
      required this.grade,
      required this.grupo,
      required this.g1_nome});

  factory Produtos.fromJson(Map<String, dynamic> json) {
    return Produtos(
        codigo: json['codigo'] ?? 0,
        nome: json['nome'] ?? '',
        valor: json['valor'] * 100 / 100 ?? 0,
        categoria: json['categoria'] ?? 0,
        grade: json['grade'] ?? 0,
        grupo: json['grupo'] ?? 0,
        g1_nome: json['g1_nome'] ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['codigo'] = this.codigo;
    data['nome'] = this.nome;
    data['valor'] = this.valor;
    data['categoria'] = this.categoria;
    data['grade'] = this.grade;
    data['grupo'] = this.grupo;
    data['g1_nome'] = this.g1_nome;
    return data;
  }
}
