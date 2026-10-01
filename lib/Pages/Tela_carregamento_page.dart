import 'package:flutter/material.dart';
import 'package:lanchonete/Controller/Config.Controller.dart';
import 'package:lanchonete/Pages/Principal_page.dart';

class TelaCarregamento extends StatefulWidget {
  final String messageAwait;
  final String messageSuccess;
  final String messageError;
  final bool finalization;
  final Future<dynamic> Function()? onFinalization;
  final void Function(BuildContext context)? onSuccess;

  const TelaCarregamento({
    Key? key,
    required this.messageAwait,
    required this.messageSuccess,
    required this.messageError,
    required this.finalization,
    this.onFinalization,
    this.onSuccess,
  }) : super(key: key);

  @override
  _TelaCarregamentoState createState() => _TelaCarregamentoState();
}

class _TelaCarregamentoState extends State<TelaCarregamento>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isSuccess = false;
  late AnimationController _animationController;
  bool _navigationStarted = false;

  @override
  void initState() {
    super.initState();
    isLoading = true;

    // Inicializar animação para loading
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Se for finalization, executar o callback
    if (widget.finalization && widget.onFinalization != null) {
      _executarFinalizacao();
    } else if (!widget.finalization) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _finalizarComSucesso();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _finalizarComSucesso() {
    if (!mounted) return;
    _animationController.reset();
    _animationController.forward();

    setState(() {
      isSuccess = true;
      isLoading = false;
    });

    _agendarNavegacao(sucesso: true);
  }

  void _finalizarComErro() {
    if (!mounted) return;
    _animationController.stop();

    setState(() {
      isSuccess = false;
      isLoading = false;
    });

    _agendarNavegacao(sucesso: false);
  }

  void _agendarNavegacao({required bool sucesso}) {
    if (_navigationStarted) return;
    _navigationStarted = true;

    final duration = Duration(milliseconds: sucesso ? 1500 : 2500);
    Future.delayed(duration, () {
      if (!mounted) return;
      if (sucesso && widget.onSuccess != null) {
        widget.onSuccess!(context);
      } else {
        _navegarPadrao();
      }
    });
  }

  void _navegarPadrao() {
    if (!mounted) return;
    bool usarMesas = ConfigController.instance.useTables.value;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PrincipalPage(
          paginas: usarMesas ? Paginas.mesas : Paginas.categorias,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _executarFinalizacao() async {
    try {
      await widget.onFinalization!();
      _finalizarComSucesso();
    } catch (e, stack) {
      print("Erro capturado em TelaCarregamento: $e\n$stack");
      _finalizarComErro();
    }
  }

  _aguardando() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.messageAwait,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        Container(
          margin: EdgeInsets.only(top: 30),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Círculo de background
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber.withOpacity(0.3)),
                  strokeWidth: 4,
                ),
              ),
              // Animação de ponto girando
              RotationTransition(
                turns: _animationController,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 5,
                        left: 35,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  _sucesso() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: Tween(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
              parent: _animationController,
              curve: Curves.elasticOut,
            ),
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.2),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          widget.messageSuccess,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  _erro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withOpacity(0.2),
          ),
          child: Icon(
            Icons.error,
            color: Colors.red,
            size: 60,
          ),
        ),
        SizedBox(height: 16),
        Text(
          widget.messageError,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Desabilitar voltar durante o carregamento
      child: Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 400),
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: !isLoading
                          ? (isSuccess ? _sucesso() : _erro())
                          : _aguardando(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
