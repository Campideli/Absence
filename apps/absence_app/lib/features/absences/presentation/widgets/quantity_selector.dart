import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Seletor de quantidade com botões de incremento e decremento
class QuantitySelector extends StatelessWidget {
  final TextEditingController controller;
  final int? maxValue;
  final String? helperText;
  final ValueChanged<String>? onChanged;

  const QuantitySelector({
    super.key,
    required this.controller,
    this.maxValue,
    this.helperText,
    this.onChanged,
  });

  void _increment() {
    final current = int.tryParse(controller.text) ?? 0;
    if (maxValue == null || current < maxValue!) {
      controller.text = (current + 1).toString();
      onChanged?.call(controller.text);
    }
  }

  void _decrement() {
    final current = int.tryParse(controller.text) ?? 0;
    if (current > 1) {
      controller.text = (current - 1).toString();
      onChanged?.call(controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05), // Mesma cor dos campos de texto
            borderRadius: BorderRadius.circular(12), // Mesmo raio dos campos de texto
          ),
          child: Row(
            children: [
              // Botão decrementar
              IconButton(
                onPressed: _decrement,
                icon: const Icon(Icons.remove),
                tooltip: 'Diminuir',
              ),
              // Campo de texto
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    // Validar limite máximo durante digitação
                    if (maxValue != null && value.isNotEmpty) {
                      final quantity = int.tryParse(value) ?? 0;

                      if (quantity > maxValue!) {
                        controller.text = maxValue.toString();
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      }
                    }
                    onChanged?.call(value);
                  },
                ),
              ),
              // Botão incrementar
              IconButton(
                onPressed: _increment,
                icon: const Icon(Icons.add),
                tooltip: 'Aumentar',
              ),
            ],
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 8),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ],
    );
  }
}
