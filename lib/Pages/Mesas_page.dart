import 'package:flutter/material.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Models/mesa_model.dart';
import 'package:lanchonete/Services/MesaService.dart';

class MesasPage extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  // --- ALTERAÇÃO: Agora retorna o ID da mesa e o ESTADO dela ---
  final Function(int, String) onMesaSelected;

  const MesasPage({Key? key, this.onOpenDrawer, required this.onMesaSelected})
      : super(key: key);

  @override
  State<MesasPage> createState() => _MesasPageState();
}

class _MesasPageState extends State<MesasPage> {
  final MesaService _mesaService = MesaService();
  List<Mesa> _mesasGrid = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarMesas();
  }

  Future<void> _carregarMesas() async {
    setState(() => _isLoading = true);

    try {
      int tableCount = ConfigController.instance.tableCount.value;
      List<Mesa> mesasDoBanco = await _mesaService.fetchMesas();
      List<Mesa> mesasTemp = [];

      for (int i = 1; i <= tableCount; i++) {
        var index = mesasDoBanco.indexWhere((m) => m.codigo == i);
        if (index != -1) {
          mesasTemp.add(mesasDoBanco[index]);
        } else {
          mesasTemp.add(Mesa(
            codigo: i,
            nome: 'Mesa ${i.toString().padLeft(2, '0')}',
            estado: 'A',
          ));
        }
      }

      setState(() {
        _mesasGrid = mesasTemp;
      });
    } catch (e) {
      print('Erro ao processar as mesas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            FocusScope.of(context).unfocus();
            if (widget.onOpenDrawer != null) {
              widget.onOpenDrawer!();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
        title: const Text("Selecione a Mesa",
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _carregarMesas,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mesasGrid.isEmpty
              ? Center(
                  child: Text(
                  'Nenhuma mesa configurada. Verifique as configurações.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ))
              : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 5 : 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _mesasGrid.length,
                  itemBuilder: (context, index) {
                    var mesa = _mesasGrid[index];
                    bool ocupada = mesa.estado == 'O';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // --- ALTERAÇÃO: Passa o estado ('A' ou 'O') ---
                          if (mesa.codigo != null) {
                            widget.onMesaSelected(
                                mesa.codigo!, mesa.estado ?? 'A');
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: ocupada ? Colors.red[50] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: ocupada ? Colors.redAccent : Colors.green,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.table_restaurant_rounded,
                                size: 45,
                                color: ocupada
                                    ? Colors.redAccent
                                    : Colors.green[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                mesa.nome ?? 'Mesa ${mesa.codigo}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ocupada ? Colors.red : Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ocupada ? "Ocupada" : "Livre",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
