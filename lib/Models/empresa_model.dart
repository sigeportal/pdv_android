class Empresa {
  int? id;
  String? titulo1; // Nome Fantasia
  String? titulo2; // Endereço ou Razão Social

  Empresa({this.id, this.titulo1, this.titulo2});

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      titulo1: json['titulo1'],
      titulo2: json['titulo2'],
    );
  }
}
