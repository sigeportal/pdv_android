import 'package:flutter/material.dart';

/// Widget para exibir uma opção de pagamento (Versão Compacta)
class PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const PaymentOptionTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  _listaOptions(bool isHorizontal) {
    return [
      Container(
        padding: const EdgeInsets.all(12), // Reduzido de 16 para 12
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 26, // Reduzido de 32 para 26
        ),
      ),
      isHorizontal ? const SizedBox(height: 8) : const SizedBox(width: 12),
      Text(
        title,
        style: const TextStyle(
          fontSize: 14, // Reduzido de 16 para 14
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      isHorizontal ? const SizedBox(height: 2) : const SizedBox(width: 4),
      Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11, // Reduzido de 12 para 11
          color: Colors.black54,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // Removi o ícone de seta para economizar espaço e poluição visual
    ];
  }

  _buildOptions(bool isHorizontal) {
    if (isHorizontal) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _listaOptions(isHorizontal),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: _listaOptions(isHorizontal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isHorizontal = orientation == Orientation.landscape;

    return Card(
      elevation: 1, // Sombra mais leve
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8), // Padding externo menor
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: _buildOptions(isHorizontal),
        ),
      ),
    );
  }
}
