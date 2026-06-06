import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:lanchonete/Services/ProdutosService.dart';

class ImagemProdutoWidget extends StatefulWidget {
  final int codProduto;
  final double? altura;
  final double? largura;

  ImagemProdutoWidget({
    Key? key,
    required this.codProduto,
    this.altura = 100.0,
    this.largura = 80.0,
  }) : super(key: key);

  @override
  State<ImagemProdutoWidget> createState() => _ImagemProdutoWidgetState();
}

class _ImagemProdutoWidgetState extends State<ImagemProdutoWidget> {
  final produtosService = ProdutosService();
  late Future<String?> _fotoFuture;

  @override
  void initState() {
    super.initState();
    _fotoFuture = produtosService.fetchFotoProduto(widget.codProduto);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.altura,
      width: widget.largura,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          topLeft: Radius.circular(8.0),
        ),
        child: FutureBuilder<String?>(
          future: _fotoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // Verifica se houve erro
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Sem Foto',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                );
              }

              // Verifica se tem dados e se não está vazio
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                try {
                  return Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    height: widget.altura,
                    width: widget.largura,
                  );
                } catch (e) {
                  return const Center(
                    child: Text(
                      'Sem Foto',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              } else {
                return const Center(
                  child: Text(
                    'Sem Foto',
                    textAlign: TextAlign.center,
                  ),
                );
              }
            } else {
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.amber,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
