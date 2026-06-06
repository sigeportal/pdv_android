import 'package:flutter/material.dart';
import 'package:lanchonete/Constants.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Services/CaixaService.dart';

class CaixaPage extends StatefulWidget {
  final bool aberturaInicial;
  final VoidCallback? onStatusChanged;

  const CaixaPage({
    Key? key,
    this.aberturaInicial = false,
    this.onStatusChanged,
  }) : super(key: key);

  @override
  State<CaixaPage> createState() => _CaixaPageState();
}

class _CaixaPageState extends State<CaixaPage> {
  final CaixaService _service = CaixaService();
  late final TextEditingController _pdvController;
  final TextEditingController _funController = TextEditingController(text: '1');
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _pdvController = TextEditingController(
      text: ConfigController.instance.pdv.value.toString(),
    );
  }

  @override
  void dispose() {
    _pdvController.dispose();
    _funController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.aberturaInicial
          ? AppBar(
              title: const Text('Abertura de Caixa'),
              backgroundColor: Constants.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.point_of_sale, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    'Caixa PDV',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pdvController,
                    readOnly: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PDV',
                      helperText: 'Alterar em Configuracoes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _funController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Funcionario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (widget.aberturaInicial)
                    ElevatedButton.icon(
                      onPressed: _loading ? null : () => _executar(abrir: true),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Abrir Caixa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _loading ? null : () => _executar(abrir: true),
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Abrir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _loading ? null : () => _executar(abrir: false),
                            icon: const Icon(Icons.lock),
                            label: const Text('Fechar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[700],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_loading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executar({required bool abrir}) async {
    final pdv = int.tryParse(_pdvController.text);
    final fun = int.tryParse(_funController.text);

    if (pdv == null || pdv <= 0 || fun == null || fun <= 0) {
      _mostrarMensagem('Informe PDV e funcionario validos.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (abrir) {
        await _service.abrirCaixa(pdv: pdv, fun: fun);
      } else {
        await _service.fecharCaixa(pdv: pdv, fun: fun);
      }

      _mostrarMensagem(abrir ? 'Caixa aberto.' : 'Caixa fechado.');
      widget.onStatusChanged?.call();
      if (abrir && widget.aberturaInicial && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}
