import 'package:flutter/material.dart';
import '../../core/mt5/mt5_models.dart';
import '../../core/mt5/mt5_symbols.dart';
import '../../core/mt5/mt5_calculator_engine.dart';
import '../../core/localization_provider.dart';
import '../../providers/mt5_symbol_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MT5CalculatorWidget extends ConsumerStatefulWidget {
  final TextEditingController pairCtrl;
  final TextEditingController entryCtrl;
  final TextEditingController slCtrl;
  final TextEditingController tpCtrl;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<double> onRiskAmountCalculated;

  const MT5CalculatorWidget({
    Key? key,
    required this.pairCtrl,
    required this.entryCtrl,
    required this.slCtrl,
    required this.tpCtrl,
    required this.onTypeChanged,
    required this.onRiskAmountCalculated,
  }) : super(key: key);

  @override
  ConsumerState<MT5CalculatorWidget> createState() => _MT5CalculatorWidgetState();
}

class _MT5CalculatorWidgetState extends ConsumerState<MT5CalculatorWidget> {

  String _translateError(String err, String lang) {
    if (lang == 'tr') {
      if (err.contains("Minimum lot exceeds")) return "Seçilen risk için pozisyon boyutu çok küçük (Minimum lot hacmi belirlediğiniz riski aşıyor). Riskinizi veya bakiyenizi artırın.";
      if (err.contains("Entry Price must be > 0")) return "Giriş fiyatı 0'dan büyük olmalı.";
      if (err.contains("Stop Loss must be > 0")) return "Zarar Kes (SL) 0'dan büyük olmalı.";
      if (err.contains("Take Profit must be > 0")) return "Kâr Al (TP) 0'dan büyük olmalı.";
      if (err.contains("Risk must be > 0")) return "Risk 0'dan büyük olmalı.";
      if (err.contains("Balance must be > 0")) return "Bakiye 0'dan büyük olmalı.";
      if (err.contains("Stop Loss must be below Entry")) return "Geçersiz BUY (Alım) işlemi: Stop Loss giriş fiyatının altında olmalı.";
      if (err.contains("Take Profit must be above Entry")) return "Geçersiz BUY (Alım) işlemi: Take Profit giriş fiyatının üstünde olmalı.";
      if (err.contains("Stop Loss must be above Entry")) return "Geçersiz SELL (Satış) işlemi: Stop Loss giriş fiyatının üstünde olmalı.";
      if (err.contains("Take Profit must be below Entry")) return "Geçersiz SELL (Satış) işlemi: Take Profit giriş fiyatının altında olmalı.";
      if (err.contains("Stop Loss is too close")) return "Stop Loss giriş fiyatına çok yakın.";
      if (err.contains("Take Profit is too close")) return "Take Profit giriş fiyatına çok yakın.";
      if (err.contains("Insufficient free margin")) return "Yetersiz bakiye (Teminat yetmiyor).";
    }
    return err;
  }
  String _selectedSymbol = 'EURUSD';
  String _direction = 'Long';
  final _balanceCtrl = TextEditingController(text: '1000');
  final _riskPctCtrl = TextEditingController(text: '1.0');
  final _lotCtrl = TextEditingController();
  
  final _riskPctFocusNode = FocusNode();
  final _lotFocusNode = FocusNode();
  
  TradeCalculationResult? _result;

  @override
  void initState() {
    super.initState();
    widget.pairCtrl.text = _selectedSymbol;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTypeChanged(_direction);
    });
    
    widget.entryCtrl.addListener(_calculate);
    widget.slCtrl.addListener(_calculate);
    widget.tpCtrl.addListener(_calculate);
    _balanceCtrl.addListener(_calculate);
    
    _riskPctCtrl.addListener(_onRiskPctChanged);
    _lotCtrl.addListener(_onLotChanged);
  }
  
  @override
  void dispose() {
    widget.entryCtrl.removeListener(_calculate);
    widget.slCtrl.removeListener(_calculate);
    widget.tpCtrl.removeListener(_calculate);
    _balanceCtrl.removeListener(_calculate);
    _riskPctCtrl.removeListener(_onRiskPctChanged);
    _lotCtrl.removeListener(_onLotChanged);
    
    _balanceCtrl.dispose();
    _riskPctCtrl.dispose();
    _lotCtrl.dispose();
    _riskPctFocusNode.dispose();
    _lotFocusNode.dispose();
    super.dispose();
  }
  
  void _onRiskPctChanged() {
    if (_riskPctFocusNode.hasFocus) {
      _calculate();
    }
  }

  void _onLotChanged() {
    if (_lotFocusNode.hasFocus) {
      // User is typing lot size manually, so we compute the equivalent Risk %
      final entry = double.tryParse(widget.entryCtrl.text);
      final sl = double.tryParse(widget.slCtrl.text);
      final balance = double.tryParse(_balanceCtrl.text);
      final lot = double.tryParse(_lotCtrl.text);
      
      if (entry != null && sl != null && balance != null && lot != null && entry > 0 && sl > 0 && lot > 0) {
        var spec = MT5MockSymbols.symbols[_selectedSymbol] ?? _getFallbackSpec();
        double priceDistance = (entry - sl).abs();
        double numberOfTicks = priceDistance / spec.tickSize;
        double lossPer1Lot = numberOfTicks * spec.tickValueLoss;
        
        double actualRiskAmount = lot * lossPer1Lot;
        double calculatedRiskPct = (actualRiskAmount / balance) * 100;
        
        // Update risk pct silently without triggering another lot calculate
        if (_riskPctCtrl.text != calculatedRiskPct.toStringAsFixed(2)) {
           _riskPctCtrl.text = calculatedRiskPct.toStringAsFixed(2);
        }
      }
      _calculate(); // Update the rest of the results based on the new risk pct (which perfectly maps back to this lot)
    }
  }

  MT5SymbolSpecification _getFallbackSpec() {
    return MT5SymbolSpecification(
         contractSize: 100000,
         tickSize: 0.00001,
         tickValueProfit: 1.0,
         tickValueLoss: 1.0,
         volumeMin: 0.01,
         volumeMax: 100.0,
         volumeStep: 0.01,
         stopsLevel: 0,
         freezeLevel: 0,
         calcMode: MT5CalcMode.forex,
         digits: 5,
         point: 0.00001,
         currencyBase: 'EUR',
         currencyProfit: 'USD',
         currencyMargin: 'USD',
      );
  }

  void _calculate() {
    final entry = double.tryParse(widget.entryCtrl.text);
    final sl = double.tryParse(widget.slCtrl.text);
    final tp = double.tryParse(widget.tpCtrl.text);
    final balance = double.tryParse(_balanceCtrl.text);
    final riskPct = double.tryParse(_riskPctCtrl.text);
    
    if (entry == null || sl == null || balance == null || riskPct == null || entry <= 0 || sl <= 0) {
      setState(() => _result = null);
      return;
    }

    var spec = MT5MockSymbols.symbols[_selectedSymbol] ?? _getFallbackSpec();

    final request = TradeCalculationRequest(
      symbol: _selectedSymbol,
      direction: _direction == 'Long' ? MT5TradeDirection.buy : MT5TradeDirection.sell,
      entryPrice: entry,
      stopLoss: sl,
      takeProfit: tp,
      accountBalance: balance,
      accountEquity: balance,
      riskBase: MT5RiskBase.balance,
      riskPercentage: riskPct,
      symbolSpec: spec,
      leverage: 100,
    );

    final res = MT5RiskEngine.calculate(request);
    setState(() => _result = res);
    
    if (res.validationErrors.isEmpty) {
      widget.onRiskAmountCalculated(res.requiredMargin);
      
      // Update Lot Size if we are not manually typing it
      if (!_lotFocusNode.hasFocus) {
        final newLotStr = res.finalLotSize.toStringAsFixed(2);
        if (_lotCtrl.text != newLotStr) {
          _lotCtrl.text = newLotStr;
        }
      }
    }
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool half = false, FocusNode? focusNode}) {
    return SizedBox(
      width: half ? 122 : 260,
      child: TextField(
        controller: ctrl,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0x33000000),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly watch locale to force rebuild on language change
    ref.watch(localeProvider);
    
    final customSymbols = ref.watch(customMt5SymbolProvider);
    final allSymbols = {...MT5MockSymbols.symbols.keys, ...customSymbols}.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Text('MT5 Professional Calculator', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Symbol Selector with add button
            SizedBox(
              width: 260,
              child: Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue: TextEditingValue(text: _selectedSymbol),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return allSymbols;
                        }
                        return allSymbols.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        setState(() => _selectedSymbol = selection);
                        widget.pairCtrl.text = selection;
                        _calculate();
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (val) {
                            final symbol = val.toUpperCase();
                            setState(() => _selectedSymbol = symbol);
                            widget.pairCtrl.text = symbol;
                            _calculate();
                          },
                          decoration: InputDecoration(
                            labelText: AppStrings.get(ref, 'mt5_symbol') ?? 'Sembol',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true, fillColor: const Color(0x33000000),
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
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
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
                                              onPressed: () {
                                                ref.read(customMt5SymbolProvider.notifier).removeSymbol(option);
                                              },
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
                      if (_selectedSymbol.isNotEmpty && !MT5MockSymbols.symbols.containsKey(_selectedSymbol)) {
                        ref.read(customMt5SymbolProvider.notifier).addSymbol(_selectedSymbol);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('\$_selectedSymbol Kaydedildi', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Direction Selector
            SizedBox(
              width: 122,
              child: DropdownButtonFormField<String>(
                value: _direction,
                dropdownColor: const Color(0xFF1E293B),
                decoration: InputDecoration(
                  labelText: AppStrings.get(ref, 'direction') ?? 'YГ¶n',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true, fillColor: const Color(0x33000000),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                style: const TextStyle(color: Colors.white),
                items: ['Long', 'Short'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _direction = v);
                    widget.onTypeChanged(v);
                    _calculate();
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildField(AppStrings.get(ref, 'mt5_balance') ?? 'Hesap Bakiyesi (\$)', _balanceCtrl, half: true),
            _buildField(AppStrings.get(ref, 'mt5_risk_pct') ?? 'Risk (%)', _riskPctCtrl, half: true, focusNode: _riskPctFocusNode),
            _buildField(AppStrings.get(ref, 'mt5_req_lot')?.replaceAll(':', '') ?? 'Lot Hacmi', _lotCtrl, half: true, focusNode: _lotFocusNode),
          ]
        ),
        
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildField(AppStrings.get(ref, 'mt5_entry') ?? 'GiriЕџ FiyatД±', widget.entryCtrl, half: true),
            _buildField(AppStrings.get(ref, 'mt5_sl') ?? 'Zarar Kes (SL)', widget.slCtrl, half: true),
            _buildField(AppStrings.get(ref, 'mt5_tp') ?? 'KГўr Al (TP)', widget.tpCtrl, half: true),
          ],
        ),
        
        const SizedBox(height: 24),
        
        if (_result != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _result!.validationErrors.isNotEmpty ? const Color(0x1A000000) : const Color(0x1A000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _result!.validationErrors.isNotEmpty ? Colors.red : Colors.green),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_result!.validationErrors.isNotEmpty)
                  ..._result!.validationErrors.map((e) => Text('${AppStrings.get(ref, "mt5_error") ?? "Hata:"} ${_translateError(e, ref.read(localeProvider))}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ref.read(localeProvider) == 'tr' ? 'Gerekli Lot Hacmi:' : 'Required Lot Size:', style: const TextStyle(color: Colors.white70)),
                      Text(_result!.finalLotSize.toStringAsFixed(2), style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ref.read(localeProvider) == 'tr' ? 'Maksimum Zarar (SL):' : 'Max Loss (SL):', style: const TextStyle(color: Colors.white70)),
                      Text('-\$${_result!.actualRiskAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_result!.potentialProfit != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ref.read(localeProvider) == 'tr' ? 'Beklenen Kâr (TP):' : 'Potential Profit (TP):', style: const TextStyle(color: Colors.white70)),
                        Text('+\$${_result!.potentialProfit!.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get(ref, 'mt5_margin') ?? 'Gerekli Teminat (Margin):', style: const TextStyle(color: Colors.white70)),
                      Text('\$${_result!.requiredMargin.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                    ],
                  ),
                ],
              ],
            ),
          ),      ],
    );
  }
}
