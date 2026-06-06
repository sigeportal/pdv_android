import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:get/get.dart';
import 'package:lanchonete/Controller/Tef/paygo_tefcontroller.dart';
import 'package:lanchonete/Controller/Tef/types/pending_transaction_actions.dart';
import 'package:lanchonete/Controller/Tef/types/tef_provider.dart';
import 'package:lanchonete/Pages/Login_page.dart';
import 'package:paygo_sdk/paygo_integrado_uri/domain/types/transaction_status.dart';

class ConfigPage extends StatefulWidget {
  @override
  _ConfigPageState createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final TefController _tefController = Get.find<TefController>();
  String? _urlBase;
  bool _useTables = false;
  bool _useTef = true;
  int _tableCount = 0;
  int _pdv = 1;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await ConfigController.instance.getConfig();
    if (!mounted) return;
    setState(() {
      _urlBase = ConfigController.instance.baseURL.value;
      _useTables = ConfigController.instance.useTables.value;
      _useTef = ConfigController.instance.useTef.value;
      _tableCount = ConfigController.instance.tableCount.value;
      _pdv = ConfigController.instance.pdv.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Configurações',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done),
            onPressed: () {
              // Salva todas as configurações de uma vez
              ConfigController.instance.saveConfig(
                _urlBase,
                _useTables,
                _tableCount,
                _useTef,
                _pdv,
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(50),
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Campo do IP do Servidor
              TextFormField(
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                initialValue: _urlBase,
                keyboardType: TextInputType.text,
                onChanged: (String url) {
                  _urlBase = url;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'IP do Servidor',
                ),
              ),

              SizedBox(height: 30), // Espaçamento

              // Opção de usar mesas e comandas
              TextFormField(
                key: ValueKey('pdv_$_pdv'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                initialValue: _pdv.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (String value) {
                  _pdv = int.tryParse(value) ?? 1;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'PDV',
                  helperText: 'Numero do caixa usado neste terminal',
                ),
              ),

              SizedBox(height: 30),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Usar mesas e comandas',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Ative para gerenciar pedidos por mesa'),
                  value: _useTables,
                  onChanged: (bool value) {
                    setState(() {
                      _useTables = value;
                    });
                  },
                ),
              ),

              // Campo de Quantidade de Mesas (Só aparece se o switch estiver ativado)
              if (_useTables) ...[
                SizedBox(height: 30),
                TextFormField(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  initialValue: _tableCount > 0 ? _tableCount.toString() : '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (String count) {
                    _tableCount = int.tryParse(count) ?? 0;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Quantidade de Mesas',
                    helperText: 'Ex: 15',
                  ),
                ),
              ],
              SizedBox(height: 30),
              _buildTefSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTefSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'TEF PayGo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SwitchListTile(
              title: Text('Usar TEF'),
              subtitle: Text(_useTef
                  ? 'Pagamentos em cartao/PIX passam pelo PayGo'
                  : 'Pagamentos em cartao/PIX serao lancados manualmente'),
              value: _useTef,
              onChanged: (value) {
                setState(() {
                  _useTef = value;
                });
              },
            ),
            if (_useTef) ...[
            SwitchListTile(
              title: Text('Confirmacao automatica'),
              value: _tefController.configuracoes.isAutoConfirm,
              onChanged: (value) {
                setState(() {
                  _tefController.configuracoes.setIsAutoConfirm(value);
                });
              },
            ),
            SwitchListTile(
              title: Text('Imprimir via do cliente'),
              value: _tefController.configuracoes.isPrintcardholderReceipt,
              onChanged: (value) {
                setState(() {
                  _tefController.configuracoes
                      .setIsPrintcardholderReceipt(value);
                });
              },
            ),
            SwitchListTile(
              title: Text('Imprimir via do estabelecimento'),
              value: _tefController.configuracoes.isPrintMerchantReceipt,
              onChanged: (value) {
                setState(() {
                  _tefController.configuracoes
                      .setIsPrintMerchantReceipt(value);
                });
              },
            ),
            DropdownButtonFormField<TefProvider>(
              decoration: InputDecoration(labelText: 'Adquirente'),
              value: _tefController.configuracoes.provider,
              items: TefProvider.values
                  .map((provider) => DropdownMenuItem(
                        value: provider,
                        child: Text(provider.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _tefController.configuracoes.provider = value);
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<PendingTransactionActions>(
              decoration: InputDecoration(labelText: 'Transacao pendente'),
              value: _tefController.configuracoes.pendingTransactionActions
                  as PendingTransactionActions,
              items: PendingTransactionActions.values
                  .map((action) => DropdownMenuItem(
                        value: action,
                        child: Text(action.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _tefController.configuracoes
                      .setPendingTransactionActions(value);
                });
              },
            ),
            SizedBox(height: 12),
            DropdownButtonFormField<TransactionStatus>(
              decoration: InputDecoration(labelText: 'Tipo de confirmacao'),
              value:
                  _tefController.configuracoes.tipoDeConfirmacao as TransactionStatus,
              items: TransactionStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _tefController.configuracoes.setTipoDeConfirmacao(value);
                });
              },
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTefAction('Instalacao', _tefController.instalacao),
                _buildTefAction('Manutencao', _tefController.manutencao),
                _buildTefAction(
                    'Administrativo', _tefController.painelAdministrativo),
                _buildTefAction('Reimpressao', _tefController.reimpressao),
                _buildTefAction('Exibe PDC', _tefController.exibePDC),
                _buildTefAction(
                    'Rel. detalhado', _tefController.relatorioDetalhado),
                _buildTefAction(
                    'Rel. resumido', _tefController.relatorioResumido),
              ],
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTefAction(String label, Future<void> Function() action) {
    return ElevatedButton(
      onPressed: () async {
        try {
          await action();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha no TEF: $e')),
          );
        }
      },
      child: Text(label),
    );
  }
}
