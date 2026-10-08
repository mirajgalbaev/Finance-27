import 'package:flutter/material.dart';
import '../../core/mt5/mt5_symbols.dart';
import '../../core/localization_provider.dart';
import '../../providers/mt5_symbol_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MT5SymbolSelector extends ConsumerWidget {
  final TextEditingController pairCtrl;
  final Function(String) onChanged;

  const MT5SymbolSelector({
    Key? key,
    required this.pairCtrl,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customSymbols = ref.watch(customMt5SymbolProvider);
    final allSymbols = {...MT5MockSymbols.symbols.keys, ...customSymbols}.toList();
    
    return Row(
      children: [
        Expanded(
          child: Autocomplete<String>(
            initialValue: TextEditingValue(text: pairCtrl.text),
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return allSymbols;
              return allSymbols.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (selection) {
              pairCtrl.text = selection;
              onChanged(selection);
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) {
                  pairCtrl.text = val.toUpperCase();
                  onChanged(val.toUpperCase());
                },
                decoration: InputDecoration(
                  labelText: AppStrings.get(ref, 'mt5_symbol') ?? 'Sembol',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true, fillColor: Colors.black26,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  color: const Color(0xFF1E293B),
                  child: SizedBox(
                    height: 200.0,
                    width: 200.0,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        final isCustom = !MT5MockSymbols.symbols.containsKey(option);
                        return InkWell(
                          onTap: () => onSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(option, style: const TextStyle(color: Colors.white)),
                                if (isCustom)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => ref.read(customMt5SymbolProvider.notifier).removeSymbol(option),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.save, color: Colors.blueAccent),
          onPressed: () {
            if (pairCtrl.text.isNotEmpty && !MT5MockSymbols.symbols.containsKey(pairCtrl.text)) {
              ref.read(customMt5SymbolProvider.notifier).addSymbol(pairCtrl.text);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${pairCtrl.text} Kaydedildi', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
              );
            }
          },
        ),
      ],
    );
  }
}
