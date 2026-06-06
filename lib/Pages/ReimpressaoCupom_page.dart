import 'package:flutter/material.dart';
import 'package:lanchonete/Models/itens_model.dart';
import 'package:lanchonete/Services/PrinterService.dart';
import 'package:fluttertoast/fluttertoast.dart';

// --- IMPORTS ADICIONADOS PARA A NAVEGAÇÃO CORRETA ---
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Pages/Principal_page.dart';

class ReimpressaoCupomPage extends StatefulWidget {
  final List<Itens> itens;
  final int numeroPedido;
  final double totalValue;

  const ReimpressaoCupomPage({
    Key? key,
    required this.itens,
    required this.numeroPedido,
    required this.totalValue,
  }) : super(key: key);

  @override
  State<ReimpressaoCupomPage> createState() => _ReimpressaoCupomPageState();
}

class _ReimpressaoCupomPageState extends State<ReimpressaoCupomPage> {
  bool _isReprinting = false;

  // --- NOVA LÓGICA DE NAVEGAÇÃO PÓS-VENDA ---
  void _voltarAoInicio() {
    bool usarMesas = ConfigController.instance.useTables.value;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PrincipalPage(
          // Se usa mesas, vai pra tela de Mesas. Se não, vai pra Categorias.
          paginas: usarMesas ? Paginas.mesas : Paginas.categorias,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _reimprimirCupom() async {
    setState(() {
      _isReprinting = true;
    });

    try {
      final success = await PrinterService.printOrder(
        itens: widget.itens,
        orderNumber: widget.numeroPedido,
        totalValue: widget.totalValue,
      );

      if (mounted) {
        setState(() {
          _isReprinting = false;
        });

        if (success) {
          Fluttertoast.showToast(
            msg: "Cupom reimpresso com sucesso!",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(
            msg: "Erro ao reimprimir cupom. Verifique a impressora.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReprinting = false;
        });

        Fluttertoast.showToast(
          msg: "Erro ao reimprimir: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.amber[600],
        elevation: 2,
        title: const Text(
          "Impressão da Venda",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          // Alterado de pop() para voltar ao início de forma segura
          onPressed: _voltarAoInicio,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, right: 24, left: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone de sucesso
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 60,
                    color: Colors.green[600],
                  ),
                ),
                // Título
                Text(
                  "Pedido Processado com Sucesso!",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Informações do pedido
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Número do Pedido:",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.numeroPedido.toString().padLeft(3, '0'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total de Itens:",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              widget.itens.length.toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Valor Total:",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "R\$ ${widget.totalValue.toStringAsFixed(2).replaceAll('.', ',')}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Mensagem informativa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Clique em 'Reimprimir' se precisar de uma cópia.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Botões de ação
                Row(
                  children: [
                    // Botão Cancelar/Voltar (Renomeado para fazer mais sentido no fim do fluxo)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isReprinting
                            ? null
                            : _voltarAoInicio, // Usando a nova rota segura
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_back, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              "Novo Pedido",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Botão Reimprimir
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isReprinting ? null : _reimprimirCupom,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _isReprinting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.print, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _isReprinting ? "Imprimindo..." : "Reimprimir",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
