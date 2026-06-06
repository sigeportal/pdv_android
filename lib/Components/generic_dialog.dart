import 'package:flutter/material.dart';

/// Dialog genérico para seleção de opções
Future<void> showGenericDialog<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T? selectedValue,
  required String Function(T) displayText,
  required Function(T) onSelected,
  required VoidCallback onCancel,
}) async {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              title: Text(displayText(option)),
              selected: option == selectedValue,
              onTap: () {
                onSelected(option);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onCancel();
            Navigator.pop(context);
          },
          child: Text('Cancelar', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
