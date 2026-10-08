import 'package:flutter/rendering.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finance_27/models/trade_model.dart';
import 'package:finance_27/ui/widgets/mt5_symbol_selector.dart';
import 'package:finance_27/core/mt5/mt5_symbols.dart';
import 'package:finance_27/providers/trade_provider.dart';
import 'package:finance_27/providers/daily_note_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:finance_27/providers/exchange_provider.dart';
import 'package:finance_27/core/localization_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DailyTradeJournalScreen extends ConsumerStatefulWidget {
  final DateTime date;
  final bool isEmbedded;

  const DailyTradeJournalScreen({Key? key, required this.date, this.isEmbedded = false}) : super(key: key);

  @override
  ConsumerState<DailyTradeJournalScreen> createState() => _DailyTradeJournalScreenState();
}

class _DailyTradeJournalScreenState extends ConsumerState<DailyTradeJournalScreen> {
  Widget _buildTpCell(TradeModel t) {
    if (t.market == 'Spot') {
      List<String> lines = [];
      if (t.takeProfit != null) lines.add('⬇ Alım 1: ${t.takeProfit}');
      if (t.buyTargets != null && t.buyTargets!.isNotEmpty) {
        for (int i = 0; i < t.buyTargets!.length; i++) {
           lines.add('⬇ Alım ${i+2}: ${t.buyTargets![i]}');
        }
      }
      if (t.sellTargets != null && t.sellTargets!.isNotEmpty) {
        for (int i = 0; i < t.sellTargets!.length; i++) {
           lines.add('⬆ Satış ${i+1}: ${t.sellTargets![i]}');
        }
      }
      if (lines.isEmpty) return const Text('-');
      return Text(lines.join("\n"), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.amberAccent));
    } else {
      List<String> tps = [];
      if (t.takeProfit != null) tps.add('TP-1: ${t.takeProfit}');
      if (t.takeProfits != null) {
        for (int i = 0; i < t.takeProfits!.length; i++) {
          tps.add('TP-${i + 2}: ${t.takeProfits![i]}');
        }
      }
      if (tps.isEmpty) return const Text('-');
      return Text(tps.join("\n"), style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.greenAccent));
    }
  }

  final TextEditingController _noteController = TextEditingController();
  final Map<String, ScreenshotController> _screenshotControllers = {};
  String _selectedTab = 'Futures';
  String _spotFilter = 'Günlük';

  Widget _buildTabButton(String label) {
    bool isSelected = _selectedTab == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase() + ' ' + (AppStrings.get(ref, 'trades_upper') ?? 'İŞLEMLERİ'),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final noteConfig = ref.read(dailyNoteProvider.notifier).getNoteForDate(widget.date);
      if (noteConfig != null) {
        _noteController.text = noteConfig.text;
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    ref.read(dailyNoteProvider.notifier).saveNote(widget.date, _noteController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notlar kaydedildi!'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _exportScreenshot(String exchange) async {
    try {
      final trades = ref.read(tradeProvider);
      final currencySymbol = '\$';
      final locale = ref.read(localeProvider);
      
      final tabTrades = trades.where((t) => t.market == _selectedTab).toList();
      
      final exchangeTrades = tabTrades.where((t) => t.exchange == exchange).toList();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'exporting') ?? 'Dışa aktarılıyor, lütfen bekleyin...'), duration: const Duration(seconds: 2)));
      await Future.delayed(const Duration(milliseconds: 300));
      
      final widgetToCapture = ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: Localizations(
          locale: const Locale('en', 'US'),
          delegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(1080, 1920)),
              child: Theme(
                data: ThemeData.dark().copyWith(
                  scaffoldBackgroundColor: const Color(0xFF0F172A),
                ),
                child: Container(
                  width: 1080,
                  height: 1920,
                  color: const Color(0xFF0F172A),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 1080,
                      child: Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale),
                              _buildGlobalGrandTotalSummary(tabTrades, currencySymbol),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final Uint8List? imageBytes = await _captureOffScreenWidget(widgetToCapture);
      
      if (imageBytes == null) return;

      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = '${exchange}_Journal_$timestamp.png';

      if (kIsWeb) {
        final blob = html.Blob([imageBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kayıt Başarılı! PNG Dosyası indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
        }
      } else {
        Directory dir;
        if (defaultTargetPlatform == TargetPlatform.android) {
          dir = Directory('/storage/emulated/0/Download');
        } else {
          dir = await getApplicationDocumentsDirectory();
        }
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kayıt Başarılı! PNG Dosyası: {path}').replaceAll('{path}', filePath)), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_failed') ?? 'Kayıt başarısız: {error}').replaceAll('{error}', e.toString())), backgroundColor: Colors.red));
      }
    }
  }

  Future<Uint8List?> _captureOffScreenWidget(Widget widget) async {
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    
    // ignore: deprecated_member_use
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    
    final RenderView renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: const ViewConfiguration(
        logicalConstraints: BoxConstraints.tightFor(width: 1080, height: 1920),
        physicalConstraints: BoxConstraints.tightFor(width: 1080 * 2.0, height: 1920 * 2.0),
        devicePixelRatio: 2.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: widget,
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }


  


  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text((AppStrings.get(ref, 'delete_all_trades_title') ?? 'Tüm "{tab}" İşlemlerini Sil').replaceAll('{tab}', _selectedTab), style: const TextStyle(color: Colors.white)),
        content: Text((AppStrings.get(ref, 'confirm_delete_all_trades') ?? 'Emin misiniz? Geçmiş ve Gelecek TÜM {tab} işlemleri kalıcı olarak silinecektir.').replaceAll('{tab}', _selectedTab), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.get(ref, 'cancel_upper') ?? 'İPTAL', style: const TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(tradeProvider.notifier).deleteAllTradesByMarket(_selectedTab);
              Navigator.pop(ctx);
            },
            child: Text(AppStrings.get(ref, 'delete_all_upper') ?? 'TÜMÜNÜ SİL', style: const TextStyle(color: Colors.white)),
          )
        ]
      )
    );
  }

  void _showAddTradeDialog() {

    showDialog(context: context, builder: (context) => AddTradeDialog(date: widget.date, initialMarket: _selectedTab));
  }

  @override
  Widget build(BuildContext context) {
    final trades = ref.watch(tradeProvider);
    final currencySymbol = '\$';
    final locale = ref.watch(localeProvider);
    String dateStr = DateFormat('dd.MM.yyyy', AppStrings.getDateFormatLocale(locale)).format(widget.date);

    final tabTrades = trades.where((t) => t.market == _selectedTab).toList();
    final activeExchanges = tabTrades.map((t) => t.exchange).toSet().toList();



    List<Widget> actionButtons = [
      IconButton(
        icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 28),
        onPressed: () => _showResetConfirmationDialog(context, ref),
      ),
      ElevatedButton.icon(

        onPressed: _showAddTradeDialog,
        icon: const Icon(Icons.add, size: 18),
        label: Text(AppStrings.get(ref, 'new_trade') ?? 'Yeni İşlem'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      const SizedBox(width: 8),


      if (!widget.isEmbedded)
        IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
    ];

    Widget bodyContent = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTabButton('Futures'),
              const SizedBox(width: 16),
              _buildTabButton('Spot'),
              const SizedBox(width: 16),
              _buildTabButton('MT5'),
            ]
          ),
          const SizedBox(height: 16),
          
          if (_selectedTab == 'Spot')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSpotFilterButton('Günlük'),
                const SizedBox(width: 8),
                _buildSpotFilterButton('Aylık'),
                const SizedBox(width: 8),
                _buildSpotFilterButton('Yıllık'),
              ]
            ),
          const SizedBox(height: 16),
          
          if (activeExchanges.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(AppStrings.get(ref, 'no_trades_found') ?? 'Bu piyasa için işlem bulunamadı.', style: const TextStyle(color: Colors.white30, fontSize: 16)),
              ),
            ),
            
          ...activeExchanges.map((exchange) {
            final exchangeTrades = tabTrades.where((t) => t.exchange == exchange).toList();
            if (!_screenshotControllers.containsKey(exchange)) {
               _screenshotControllers[exchange] = ScreenshotController();
            }
            return _buildExchangeBlock(exchange, exchangeTrades, currencySymbol, locale);
          }).toList(),
          
          if (activeExchanges.isNotEmpty)
            _buildGlobalGrandTotalSummary(tabTrades, currencySymbol),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return Container(
        color: const Color(0xFF0F172A),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text('${AppStrings.get(ref, 'daily_trade_journal') ?? 'Günlük İşlem Kaydı'} - $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                  Row(children: actionButtons),
                ],
              ),
            ),
            Expanded(child: bodyContent),
          ],
        ),
      );
    }
  
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text('${AppStrings.get(ref, 'daily_trade_journal') ?? 'Günlük İşlem Kaydı'} - $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          ...actionButtons,
          const SizedBox(width: 16),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildSpotFilterButton(String filter) {
    bool isSelected = _spotFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _spotFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orangeAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orangeAccent)
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.orangeAccent, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

Widget _buildExchangeBlock(String exchange, List<TradeModel> exchangeTrades, String currencySymbol, String locale) {
    double totalProfit = 0;
    double totalLoss = 0;
    double totalCapital = 0;
    int winCount = 0;
    int lossCount = 0;

    for (var t in exchangeTrades) {
      totalCapital += t.capitalAllocated;
    }

    final closedTodayTrades = exchangeTrades.where((t) {
      if (t.exitDate == null || t.exitPrice == null) return false;
      if (_selectedTab == 'Spot' && _spotFilter == 'Aylık') {
        return t.exitDate!.year == widget.date.year && t.exitDate!.month == widget.date.month;
      } else if (_selectedTab == 'Spot' && _spotFilter == 'Yıllık') {
        return t.exitDate!.year == widget.date.year;
      } else {
        return t.exitDate!.year == widget.date.year &&
               t.exitDate!.month == widget.date.month &&
               t.exitDate!.day == widget.date.day;
      }
    }).toList();

    for (var t in closedTodayTrades) {
      final pnl = t.pnlAmount ?? 0;
      if (pnl > 0) {
        totalProfit += pnl;
        winCount++;
      } else if (pnl < 0) {
        totalLoss += pnl;
        lossCount++;
      }
    }

    double netPnL = totalProfit + totalLoss;
    double winRate = closedTodayTrades.isEmpty ? 0 : (winCount / closedTodayTrades.length) * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Container(
          color: const Color(0xFF0F172A), // Background for screenshot
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BLOCK HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                         const Icon(Icons.account_balance, color: Colors.amberAccent),
                         const SizedBox(width: 8),
                         Expanded(
                           child: FittedBox(
                             alignment: Alignment.centerLeft,
                             fit: BoxFit.scaleDown,
                             child: Text('$exchange - $_selectedTab ${_selectedTab == 'Spot' && _spotFilter != 'Günlük' ? (_spotFilter == 'Aylık' ? (AppStrings.get(ref, 'monthly_upper') ?? 'AYLIK') : (_spotFilter == 'Yıllık' ? (AppStrings.get(ref, 'yearly_upper') ?? 'YILLIK') : (AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK'))) + ' ' : ''}${AppStrings.get(ref, 'war_report') ?? 'SAVAŞ RAPORU'}'.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 1.5)),
                           ),
                         ),
                      ]
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      if (_selectedTab == 'Spot')
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _spotFilter,
                                dropdownColor: const Color(0xFF1E293B),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                items: ['Günlük', 'Aylık', 'Yıllık'].map((String value) {
                                  String label = value;
                                  if (value == 'Günlük') label = AppStrings.get(ref, 'daily') ?? 'Günlük';
                                  if (value == 'Aylık') label = AppStrings.get(ref, 'monthly') ?? 'Aylık';
                                  if (value == 'Yıllık') label = AppStrings.get(ref, 'yearly') ?? 'Yıllık';
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(label),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _spotFilter = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () => _exportScreenshot(exchange),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(AppStrings.get(ref, 'export_btn') ?? 'Dışarı Aktar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // TABLE SECTION (NOW WRAP/GRID)
              Builder(
                builder: (context) {
                  // Kullanıcının istediği sıralama (Tamamlanan kârlılar, zararlılar, açıklar)
                  final sortedTrades = List<TradeModel>.from(exchangeTrades);
                  sortedTrades.sort((a, b) => b.date.compareTo(a.date));

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.start,
                      children: sortedTrades.asMap().entries.map((entry) {
                         return _buildTradeCard(context, entry.key + 1, entry.value, currencySymbol, locale);
                      }).toList(),
                    ),
                  );
                }
              ),
              const SizedBox(height: 16),
              
              // DAILY SUMMARY CARD FOR THIS EXCHANGE
              LayoutBuilder(builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;
                Widget leftCard = Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${exchange.toUpperCase()} ${AppStrings.get(ref, 'summary_upper') ?? 'ÖZETİ'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const Divider(color: Colors.white12, height: 24),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSummaryStat(context, AppStrings.get(ref, 'used_margin') ?? 'KULLANILAN MALİYET', '$currencySymbol${totalCapital.toStringAsFixed(2)}', Colors.amberAccent),
                                  const SizedBox(width: 16),
                                  _buildSummaryStat(context, AppStrings.get(ref, 'total_trades') ?? 'TOPLAM İŞLEM', '${exchangeTrades.length}', Colors.white),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSummaryStat(context, AppStrings.get(ref, 'winning_trades') ?? 'KAZANAN İŞLEM', '$winCount', Colors.greenAccent),
                                  const SizedBox(width: 16),
                                  _buildSummaryStat(context, AppStrings.get(ref, 'losing_trades') ?? 'KAYBEDEN İŞLEM', '$lossCount', Colors.redAccent),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildSummaryStat(context, AppStrings.get(ref, 'won_money') ?? 'KAZANILAN PARA', '+$currencySymbol${totalProfit.toStringAsFixed(2)}', Colors.greenAccent),
                                  const SizedBox(width: 16),
                                  _buildSummaryStat(context, AppStrings.get(ref, 'lost_money') ?? 'KAYBEDİLEN PARA', '-$currencySymbol${totalLoss.abs().toStringAsFixed(2)}', Colors.redAccent),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                children: [
                                  Text(AppStrings.get(ref, 'net_profit_loss'), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    netPnL >= 0 ? '+$currencySymbol${netPnL.toStringAsFixed(2)}' : '-$currencySymbol${netPnL.abs().toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: netPnL >= 0 ? Colors.greenAccent : Colors.redAccent),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                Widget rightCard = Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(AppStrings.get(ref, 'win_rate_upper') ?? 'WIN RATE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: Stack(
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          sectionsSpace: 0,
                                          centerSpaceRadius: 40,
                                          sections: [
                                            PieChartSectionData(color: Colors.blueAccent, value: winRate, title: '', radius: 10),
                                            PieChartSectionData(color: Colors.white12, value: 100 - winRate, title: '', radius: 10),
                                          ]
                                        )
                                      ),
                                      Center(child: Text('${winRate.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Padding(
                                 padding: const EdgeInsets.only(left: 32),
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Text(AppStrings.get(ref, 'pnl_chart_upper') ?? 'PNL GRAFİĞİ', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                     const SizedBox(height: 16),
                                     SizedBox(
                                       height: 100,
                                       child: _buildLineChart(closedTodayTrades),
                                     )
                                   ],
                                 ),
                              ),
                            )
                          ],
                        ),
                      );
                if (isMobile) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [leftCard, const SizedBox(height: 16), rightCard]);
                } else {
                  return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: leftCard), const SizedBox(width: 16), Expanded(flex: 2, child: rightCard)]));
                }
              }),
            ],
          ),
        ),
    );
  }

  Widget _buildGlobalGrandTotalSummary(List<TradeModel> allTrades, String currencySymbol) {
    double grandProfit = 0;
    double grandLoss = 0;
    int winCount = 0;
    int lossCount = 0;

    final closedTrades = allTrades.where((t) {
      if (t.exitDate == null || t.exitPrice == null) return false;
      if (_selectedTab == 'Spot' && _spotFilter == 'Aylık') {
        return t.exitDate!.year == widget.date.year && t.exitDate!.month == widget.date.month;
      } else if (_selectedTab == 'Spot' && _spotFilter == 'Yıllık') {
        return t.exitDate!.year == widget.date.year;
      } else {
        return t.exitDate!.year == widget.date.year &&
               t.exitDate!.month == widget.date.month &&
               t.exitDate!.day == widget.date.day;
      }
    }).toList();

    for (var t in closedTrades) {
      final pnl = t.pnlAmount ?? 0;
      if (pnl > 0) {
        grandProfit += pnl;
        winCount++;
      } else if (pnl < 0) {
        grandLoss += pnl;
        lossCount++;
      }
    }

    double grandNet = grandProfit + grandLoss;

    return Column(
      children: [
        const Divider(color: Colors.white24, height: 40, thickness: 2),
        LayoutBuilder(builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;
                Widget leftCard = Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                       colors: [const Color(0xFF1E293B), Colors.blueAccent.withOpacity(0.1)],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(AppStrings.get(ref, 'global_grand_total') ?? 'GENEL TOPLAM ÖZETİ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 16),
                      FittedBox(
                         fit: BoxFit.scaleDown,
                         child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                               _buildSummaryStat(context, AppStrings.get(ref, 'total_profit'), '+$currencySymbol${grandProfit.toStringAsFixed(2)}', Colors.greenAccent),
                               const SizedBox(width: 16),
                               _buildSummaryStat(context, AppStrings.get(ref, 'total_loss'), '-$currencySymbol${grandLoss.abs().toStringAsFixed(2)}', Colors.redAccent),
                               const SizedBox(width: 16),
                               _buildSummaryStat(context, AppStrings.get(ref, 'total_trades') ?? 'TOPLAM İŞLEM', '${allTrades.length}', Colors.white),
                            ],
                         ),
                      ),
                      const SizedBox(height: 24),
                      Text('${AppStrings.get(ref, 'net_upper') ?? 'NET'} ${_selectedTab == 'Spot' && _spotFilter != 'Günlük' ? (_spotFilter == 'Aylık' ? (AppStrings.get(ref, 'monthly_upper') ?? 'AYLIK') : (AppStrings.get(ref, 'yearly_upper') ?? 'YILLIK')) : (AppStrings.get(ref, 'daily_upper') ?? 'GÜNLÜK')} P&L', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        grandNet >= 0 ? '+$currencySymbol${grandNet.toStringAsFixed(2)}' : '-$currencySymbol${grandNet.abs().toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: grandNet >= 0 ? Colors.greenAccent : Colors.redAccent),
                      )
                    ],
                  ),
                );
                
                Widget buildRightCard(bool mobile) {
                  return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppStrings.get(ref, 'end_of_day_notes') ?? 'GÜN SONU NOTLARI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(icon: const Icon(Icons.save, color: Colors.blueAccent), onPressed: _saveNotes)
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      mobile ? SizedBox(height: 150, child: TextField(
                          controller: _noteController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                           decoration: InputDecoration(
                            hintText: AppStrings.get(ref, 'trade_journal_hint'),
                            hintStyle: const TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                          ))) : Expanded(child: TextField(
                          controller: _noteController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                           decoration: InputDecoration(
                            hintText: AppStrings.get(ref, 'trade_journal_hint'),
                            hintStyle: const TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                          )))
                    ],
                  ),
                );
                }
                
                if (isMobile) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [leftCard, const SizedBox(height: 16), buildRightCard(true)]);
                } else {
                  return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: leftCard), const SizedBox(width: 16), Expanded(flex: 2, child: buildRightCard(false))]));
                }
        })
      ]
    );
  }

  Widget _buildTradeCard(BuildContext context, int index, TradeModel t, String currencySymbol, String locale) {
    bool isLong = t.type.toLowerCase() == 'long' || t.type.toLowerCase() == 'alış';
    double parsedPnlPct = t.pnlPercent ?? 0;
    double parsedPnlAmt = t.pnlAmount ?? 0;
    bool isWin = parsedPnlAmt > 0;
    bool isClosed = t.exitDate != null;

    String displayDate = DateFormat('dd.MM.yyyy', AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(t.date);
    if (t.exitDate != null && (t.date.year != t.exitDate!.year || t.date.month != t.exitDate!.month || t.date.day != t.exitDate!.day)) {
        displayDate = '${DateFormat('dd.MM', AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(t.date)} - ${DateFormat('dd.MM', AppStrings.getDateFormatLocale(ref.watch(localeProvider))).format(t.exitDate!)}';
    }

    String pnlPrefix = parsedPnlAmt >= 0 ? '+' : '';
    Color pnlColor = parsedPnlAmt >= 0 ? Colors.greenAccent : Colors.redAccent;
    
    String tpText = '-';
    if (t.takeProfit != null) {
      tpText = t.takeProfit.toString();
      if (t.takeProfits != null && t.takeProfits!.isNotEmpty) {
        tpText += ' (+${t.takeProfits!.length})';
      }
    }

    return Container(
      width: 260, // 5 kart yan yana sığması için optimize edildi
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
         color: const Color(0xFF0F172A),
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: isClosed ? Colors.white10 : Colors.orangeAccent.withOpacity(0.5), width: isClosed ? 1 : 2),
      ),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            // HEADER: NO, Exchange, Market
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
              alignment: WrapAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                  child: Text('#$index', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Text('${t.exchange} • ${t.market}', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
              ]
            ),
            const SizedBox(height: 8),
            // TITLE: Pair & Direction
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
               alignment: WrapAlignment.spaceBetween,
               children: [
                  Row(
                     children: [
                        const Icon(Icons.currency_bitcoin, color: Colors.orangeAccent, size: 16),
                        const SizedBox(width: 6),
                        Text((t.pair.toLowerCase() == "belirsiz" || t.pair.toLowerCase() == "undefined" || t.pair == "Не определено" || t.pair == "Белгисиз") ? (AppStrings.get(ref, 'undefined_text') ?? 'Belirsiz') : t.pair, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                     ]
                  ),
                  Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(
                       color: t.market == 'Spot' ? Colors.blue.withOpacity(0.2) : (isLong ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)), 
                       borderRadius: BorderRadius.circular(6)
                     ),
                     child: Text(t.market == 'Spot' ? 'SPOT' : t.type.toUpperCase(), style: TextStyle(color: t.market == 'Spot' ? Colors.blueAccent : (isLong ? Colors.green : Colors.redAccent), fontSize: 10, fontWeight: FontWeight.bold)),
                  )
               ]
            ),
            const Divider(color: Colors.white10, height: 16),
            
            // DATETIME & LEVERAGE
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
               alignment: WrapAlignment.spaceBetween,
               children: [
                  Text('$displayDate ${t.timeText}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  Text(t.market == 'Futures' ? '${AppStrings.get(ref, 'leverage_label')?.replaceAll(' (Leverage)', '') ?? 'Kaldıraç'}: ${t.leverage}' : 'Spot', style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
               ]
            ),
            const SizedBox(height: 8),

            // CAPITAL
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
               alignment: WrapAlignment.spaceBetween,
               children: [
                  Text(AppStrings.get(ref, 'capital_label') ?? 'Sermaye:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('$currencySymbol${t.capitalAllocated}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
               ]
            ),
            const SizedBox(height: 4),

            // ENTRY / EXIT
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
               alignment: WrapAlignment.spaceBetween,
               children: [
                  Text(AppStrings.get(ref, 'entry_label') ?? 'Giriş:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('${t.entryPrice}', style: const TextStyle(color: Colors.white, fontSize: 11)),
               ]
            ),
            const SizedBox(height: 4),
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
               alignment: WrapAlignment.spaceBetween,
               children: [
                  Text(AppStrings.get(ref, 'exit_label') ?? 'Çıkış:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text(isClosed ? '${t.exitPrice}' : AppStrings.get(ref, 'open_status') ?? 'Açık', style: TextStyle(color: isClosed ? Colors.white : Colors.orangeAccent, fontSize: 11, fontWeight: isClosed ? FontWeight.normal : FontWeight.bold)),
               ]
            ),
            const SizedBox(height: 4),

            // SL / TP
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
               alignment: WrapAlignment.spaceBetween,
               children: [
                  const Text('SL / TP:', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  Text('${t.stopLoss ?? '-'} / $tpText', style: const TextStyle(color: Colors.white70, fontSize: 11)),
               ]
            ),

            // NOTES
            if (t.notes != null && t.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(6)),
                child: Text(t.notes!, style: const TextStyle(color: Colors.white70, fontSize: 10, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
              )
            ],

            const Divider(color: Colors.white10, height: 16),
            
            // PNL & ACTIONS
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
               alignment: WrapAlignment.spaceBetween,
               children: [
                  if (isClosed)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text('$pnlPrefix${parsedPnlPct.toStringAsFixed(2)}%', style: TextStyle(color: pnlColor, fontSize: 11, fontWeight: FontWeight.bold)),
                         Text('$pnlPrefix$currencySymbol${parsedPnlAmt.abs().toStringAsFixed(2)}', style: TextStyle(color: pnlColor, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    )
                  else
                    Text(AppStrings.get(ref, 'pending_status') ?? 'Bekliyor...', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AddTradeDialog(date: widget.date, trade: t),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                        onPressed: () => ref.read(tradeProvider.notifier).deleteTrade(t.id),
                      ),
                    ]
                  )
               ]
            )
         ]
      )
    );
  }

  Widget _buildSummaryStat(BuildContext context, String title, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLineChart(List<TradeModel> trades) {
    if (trades.isEmpty) return Center(child: Text(AppStrings.get(ref, 'no_data') ?? 'Veri Yok', style: TextStyle(color: Colors.white24)));
    
    List<FlSpot> spots = [const FlSpot(0, 0)];
    double runningTotal = 0;
    
    for (int i = 0; i < trades.length; i++) {
      runningTotal += trades[i].pnlAmount ?? 0;
      spots.add(FlSpot((i + 1).toDouble(), runningTotal));
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                int index = spot.x.toInt() - 1;
                if (index < 0 || index >= trades.length) return null;
                final trade = trades[index];
                DateTime d = trade.exitDate ?? trade.date;
                return LineTooltipItem(
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${trade.timeText}\n\$${spot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: runningTotal >= 0 ? Colors.greenAccent : Colors.redAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (runningTotal >= 0 ? Colors.greenAccent : Colors.redAccent).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }


}
class AddTradeDialog extends ConsumerStatefulWidget {
  final DateTime date;
  final TradeModel? trade;
  final String? initialMarket;
  const AddTradeDialog({required this.date, this.trade, this.initialMarket});

  @override
  ConsumerState<AddTradeDialog> createState() => AddTradeDialogState();
}

class AddTradeDialogState extends ConsumerState<AddTradeDialog> {
  final _exchangeCtrl = TextEditingController();
  final _pairCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final _entryCtrl = TextEditingController();
  final _exitCtrl = TextEditingController();
  final _slCtrl = TextEditingController();
  final _tpCtrl = TextEditingController();
  final List<TextEditingController> _additionalTpCtrls = [];
  final List<TextEditingController> _buyTargetsCtrls = [];
  final List<TextEditingController> _sellTargetsCtrls = [];
  final _pnlPctCtrl = TextEditingController();
  final _pnlAmtCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _unlevPnlAmtCtrl = TextEditingController();
  final _totalSizeCtrl = TextEditingController();
  final _leverageCtrl = TextEditingController(text: '1');

  late String _selectedMarket;
  String _selectedType = 'Long';
  String _closeType = 'Manuel Çıkış'; // veya 'TP Vuruldu', 'SL Vuruldu'
  double _leverage = 1.0;
  TimeOfDay _time = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _selectedMarket = widget.initialMarket ?? 'Futures';
    if (widget.trade != null) {
      final t = widget.trade!;
      _exchangeCtrl.text = t.exchange;
      _pairCtrl.text = t.pair;
      _capCtrl.text = t.capitalAllocated.toString();
      _entryCtrl.text = t.entryPrice.toString();
      _exitCtrl.text = t.exitPrice?.toString() ?? '';
      _slCtrl.text = t.stopLoss?.toString() ?? '';
      _tpCtrl.text = t.takeProfit?.toString() ?? '';
      if (t.takeProfits != null) {
        _additionalTpCtrls.addAll(t.takeProfits!.map((v) => TextEditingController(text: v.toString())));
      }
      if (t.buyTargets != null) {
        _buyTargetsCtrls.addAll(t.buyTargets!.map((v) => TextEditingController(text: v.toString())));
      }
      if (t.sellTargets != null) {
        _sellTargetsCtrls.addAll(t.sellTargets!.map((v) => TextEditingController(text: v.toString())));
      }
      _notesCtrl.text = t.notes ?? '';
      _selectedMarket = t.market;
      _selectedType = t.type;
      
      try {
        double parsed = double.parse(t.leverage.replaceAll(RegExp(r'[^0-9.]'), ''));
        _leverage = parsed.clamp(1.0, 125.0);
      } catch (_) {}

      try {
        final raw = t.timeText.replaceAll(RegExp(r'[^\d:]'), '');
        final parts = raw.split(':');
        if (parts.length >= 2) {
          _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
      } catch (_) {}
    }

    _capCtrl.addListener(_calculatePnL);
    _entryCtrl.addListener(_calculatePnL);
    _exitCtrl.addListener(_calculatePnL);
    _tpCtrl.addListener(_calculatePnL);
    _slCtrl.addListener(_calculatePnL);
    _leverageCtrl.text = _leverage.toInt().toString();
    _leverageCtrl.addListener(_calculatePnL);
    
    if (widget.trade != null) _calculatePnL();
  }

  @override
  void dispose() {
    _capCtrl.removeListener(_calculatePnL);
    _entryCtrl.removeListener(_calculatePnL);
    _exitCtrl.removeListener(_calculatePnL);
    _tpCtrl.removeListener(_calculatePnL);
    for (var c in _additionalTpCtrls) c.dispose();
    for (var c in _buyTargetsCtrls) c.dispose();
    for (var c in _sellTargetsCtrls) c.dispose();
    _slCtrl.removeListener(_calculatePnL);
    _unlevPnlAmtCtrl.dispose();
    _totalSizeCtrl.dispose();
    _leverageCtrl.dispose();
    super.dispose();
  }

  void _calculatePnL() {
    double cap = double.tryParse(_capCtrl.text) ?? 0;
    double entry = double.tryParse(_entryCtrl.text) ?? 0;
    
    if (entry <= 0 || (_selectedMarket != 'MT5' && cap <= 0)) return;

    double lev = _selectedMarket == 'Spot' ? 1.0 : _leverage;
    double exit = 0;
    
    if (_closeType == 'TP Vuruldu' && _tpCtrl.text.isNotEmpty) {
      exit = double.tryParse(_tpCtrl.text) ?? 0;
    } else if (_closeType == 'SL Vuruldu' && _slCtrl.text.isNotEmpty) {
      exit = double.tryParse(_slCtrl.text) ?? 0;
    } else {
      exit = double.tryParse(_exitCtrl.text) ?? 0;
    }

    if (exit <= 0) {
       _pnlAmtCtrl.clear();
       _pnlPctCtrl.clear();
       _unlevPnlAmtCtrl.clear();
       _totalSizeCtrl.clear();
       return;
    }

    double qty = (cap * lev) / entry;
    double pnlAmt = 0;
    if (_selectedType == 'Long') {
      pnlAmt = (exit - entry) * qty;
    } else { 
      pnlAmt = (entry - exit) * qty;
    }

    double pnlPct = cap > 0 ? (pnlAmt / cap) * 100 : 0;

    double unleveragedQty = cap / entry;
    double unlevPnlAmt = _selectedType == 'Long' ? (exit - entry) * unleveragedQty : (entry - exit) * unleveragedQty;
    double totalSize = cap * lev;

    // Sadece eğer manuel girilmemişse veya hesaplama değiştiyse güncelle
    // Kısır döngü (infinite loop) yaratmamak için text değişimi kontrolü:
    String newAmt = pnlAmt.toStringAsFixed(2);
    String newPct = pnlPct.toStringAsFixed(2);
    String newUnlev = unlevPnlAmt.toStringAsFixed(2);
    String newSize = totalSize.toStringAsFixed(2);
    
    if (_pnlAmtCtrl.text != newAmt) {
      _pnlAmtCtrl.value = TextEditingValue(text: newAmt, selection: TextSelection.collapsed(offset: newAmt.length));
    }
    if (_pnlPctCtrl.text != newPct) {
      _pnlPctCtrl.value = TextEditingValue(text: newPct, selection: TextSelection.collapsed(offset: newPct.length));
    }
    if (_unlevPnlAmtCtrl.text != newUnlev) {
      _unlevPnlAmtCtrl.value = TextEditingValue(text: newUnlev, selection: TextSelection.collapsed(offset: newUnlev.length));
    }
    if (_totalSizeCtrl.text != newSize) {
      _totalSizeCtrl.value = TextEditingValue(text: newSize, selection: TextSelection.collapsed(offset: newSize.length));
    }
  }

  void _showAddNewExchangeDialog(BuildContext context) {
    final TextEditingController newExCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(AppStrings.get(ref, 'add_new_exchange') ?? 'Yeni Borsa Ekle', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: newExCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppStrings.get(ref, 'exchange_name_hint') ?? 'Borsa Adı (Örn: Kraken)',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get(ref, 'cancel') ?? 'İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () {
              final val = newExCtrl.text.trim();
              if (val.isNotEmpty) {
                ref.read(exchangeProvider.notifier).addExchange(val);
                setState(() {
                  _exchangeCtrl.text = val;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }



    @override
  Widget build(BuildContext context) {
    final savedExchanges = ref.watch(exchangeProvider);
    if (_exchangeCtrl.text.isEmpty && savedExchanges.isNotEmpty) {
      _exchangeCtrl.text = savedExchanges.first;
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(AppStrings.get(ref, 'add_new_trade') ?? 'Yeni İşlem Ekle', style: TextStyle(color: Colors.white)),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildField(AppStrings.get(ref, 'time') ?? 'Saat', null, onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _time);
                    if (t != null) setState(() => _time = t);
                  }, textOverride: _time.format(context), half: true),
                  
                  // Exchange Selector
                  if (_selectedMarket != 'MT5')
                  SizedBox(
                    width: 260,
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: savedExchanges.contains(_exchangeCtrl.text) ? _exchangeCtrl.text : (savedExchanges.isNotEmpty ? savedExchanges.first : null),
                            dropdownColor: const Color(0xFF1E293B),
                            decoration: InputDecoration(
                              labelText: AppStrings.get(ref, 'exchange_label') ?? 'Borsa',
                              labelStyle: const TextStyle(color: Colors.white54),
                              filled: true, fillColor: const Color(0x33000000),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            style: const TextStyle(color: Colors.white),
                            items: savedExchanges.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() { _exchangeCtrl.text = val; });
                            },
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                              tooltip: 'Yeni Ekle',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showAddNewExchangeDialog(context),
                            ),
                            const SizedBox(width: 8),
                            if (_exchangeCtrl.text.isNotEmpty && savedExchanges.contains(_exchangeCtrl.text))
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                tooltip: AppStrings.get(ref, 'delete_exchange_tooltip') ?? 'Borsayı Sil',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  final ex = _exchangeCtrl.text;
                                  if (savedExchanges.length > 1) {
                                    ref.read(exchangeProvider.notifier).removeExchange(ex);
                                    setState(() {
                                      _exchangeCtrl.text = savedExchanges.firstWhere((e) => e != ex, orElse: () => '');
                                    });
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(AppStrings.get(ref, 'min_1_exchange') ?? 'En az 1 borsa kalmalıdır.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  
                  if (_selectedMarket == 'MT5')
                    SizedBox(width: 260, child: MT5SymbolSelector(pairCtrl: _pairCtrl, onChanged: (_) {}))
                  else
                    _buildField(AppStrings.get(ref, 'pair_hint') ?? 'Parite (Örn: BTC/USDT)', _pairCtrl, half: true),
                  // Market Selector
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      value: _selectedMarket,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        labelText: AppStrings.get(ref, 'market_label') ?? 'Piyasa',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true, fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: ['Spot', 'Futures', 'MT5'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedMarket = v!;
                          if (v == 'Spot') {
                             _leverage = 1.0;
                             _selectedType = 'Long'; // Spot genelde sadece alımdır
                          }
                          _calculatePnL();
                        });
                      },
                    ),
                  ),

                  // Type Selector
                  if (_selectedMarket != 'Spot')
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        value: _selectedType,
                        dropdownColor: const Color(0xFF1E293B),
                        decoration: InputDecoration(
                          labelText: AppStrings.get(ref, 'direction') ?? 'Yön',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true, fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        style: TextStyle(color: _selectedType == 'Long' ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold),
                        items: ['Long', 'Short'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedType = v!;
                            _calculatePnL();
                          });
                        },
                      ),
                    ),

                  // Close Type Selector
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      value: _closeType,
                      dropdownColor: const Color(0xFF1E293B),
                      decoration: InputDecoration(
                        labelText: AppStrings.get(ref, 'close_type_label') ?? 'Kapanış Türü',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true, fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: ['Manuel Çıkış', 'TP Vuruldu', 'SL Vuruldu'].map((m) {
                        String label = m;
                        if (m == 'Manuel Çıkış') label = AppStrings.get(ref, 'manual_exit') ?? m;
                        if (m == 'TP Vuruldu') label = AppStrings.get(ref, 'tp_hit') ?? m;
                        if (m == 'SL Vuruldu') label = AppStrings.get(ref, 'sl_hit') ?? m;
                        return DropdownMenuItem(value: m, child: Text(label));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _closeType = v!;
                          _calculatePnL();
                        });
                      },
                    ),
                  ),

                ],
              ),
              if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[
                const SizedBox(height: 16),
                Text(_selectedMarket == 'MT5' ? (AppStrings.get(ref, 'mt5_req_lot')?.replaceAll(':','') ?? 'Lot Hacmi') : (AppStrings.get(ref, 'leverage_label') ?? 'Kaldıraç (Leverage)'), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Row(
                  children: [
                    if (_selectedMarket != 'MT5')
                      Expanded(
                        child: Slider(
                          value: _leverage,
                          min: 1,
                          max: 125,
                          divisions: 124,
                          activeColor: Colors.blueAccent,
                          label: '${_leverage.toInt()}x',
                          onChanged: (v) {
                            setState(() {
                              _leverage = v;
                              _leverageCtrl.text = v.toInt().toString();
                              _calculatePnL();
                            });
                          },
                        ),
                      ),
                    SizedBox(
                      width: _selectedMarket == 'MT5' ? 260 : 60,
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        controller: _leverageCtrl,
                        onChanged: (val) {
                          double? l = double.tryParse(val);
                          if (l != null && l > 0) {
                            setState(() {
                              _leverage = l;
                              _calculatePnL();
                            });
                          }
                        },
                        decoration: InputDecoration(
                          suffixText: _selectedMarket == 'MT5' ? 'Lot' : 'x', 
                          suffixStyle: const TextStyle(color: Colors.white54),
                          filled: _selectedMarket == 'MT5',
                          fillColor: Colors.black26,
                          border: _selectedMarket == 'MT5' ? OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none) : null,
                        ),
                      ),
                    )
                  ],
                )
              ],
              const Divider(color: Colors.white12, height: 32),

              
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                   
                     _buildField(AppStrings.get(ref, 'margin_amount') ?? 'Maliyet (Margin) \$', _capCtrl, half: true, isNum: true),
                     _buildField(AppStrings.get(ref, 'entry_price') ?? 'Giriş Fiyatı', _entryCtrl, half: true, isNum: true),
                     _buildField(AppStrings.get(ref, 'exit_price_manual') ?? 'Çıkış Fiyatı (Manuel)', _exitCtrl, half: true, isNum: true),
                     _buildField('Stop Loss (SL)', _slCtrl, half: true, isNum: true),
                   if (_selectedMarket == 'Futures' || _selectedMarket == 'MT5') ...[
                     _buildField('Take Profit (TP-1)', _tpCtrl, half: true, isNum: true),
                     for (int i = 0; i < _additionalTpCtrls.length; i++)
                       _buildField('TP-${i + 2}', _additionalTpCtrls[i], half: true, isNum: true),
                     Align(
                       alignment: Alignment.centerLeft,
                       child: TextButton.icon(
                         onPressed: () {
                           setState(() {
                             _additionalTpCtrls.add(TextEditingController());
                           });
                         },
                         icon: const Icon(Icons.add, size: 16, color: Colors.blueAccent),
                         label: Text(AppStrings.get(ref, 'add_second_tp') ?? 'İkinci TP Ekle', style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                       ),
                     ),
                   ],
                   if (_selectedMarket == 'Spot') ...[
                     _buildField(AppStrings.get(ref, 'buy_tp_1_default') ?? 'Alım TP-1 (Varsayılan)', _tpCtrl, half: true, isNum: true),
                     for (int i = 0; i < _buyTargetsCtrls.length; i++)
                       _buildField('${AppStrings.get(ref, 'buy_tp') ?? 'Alım TP'}-${i + 2}', _buyTargetsCtrls[i], half: true, isNum: true),
                     Align(
                       alignment: Alignment.centerLeft,
                       child: TextButton.icon(
                         onPressed: () {
                           setState(() {
                             _buyTargetsCtrls.add(TextEditingController());
                           });
                         },
                         icon: const Icon(Icons.add, size: 16, color: Colors.greenAccent),
                         label: Text(AppStrings.get(ref, 'add_buy_target') ?? 'Alım Hedefi Ekle', style: const TextStyle(fontSize: 12, color: Colors.greenAccent)),
                       ),
                     ),
                     for (int i = 0; i < _sellTargetsCtrls.length; i++)
                       _buildField('${AppStrings.get(ref, 'sell_tp') ?? 'Satış TP'}-${i + 1}', _sellTargetsCtrls[i], half: true, isNum: true),
                     Align(
                       alignment: Alignment.centerLeft,
                       child: TextButton.icon(
                         onPressed: () {
                           setState(() {
                             _sellTargetsCtrls.add(TextEditingController());
                           });
                         },
                         icon: const Icon(Icons.add, size: 16, color: Colors.orangeAccent),
                         label: Text(AppStrings.get(ref, 'add_sell_target') ?? 'Satış Hedefi Ekle', style: const TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                       ),
                     ),
                   ],
                ]
              ),
              const Divider(color: Colors.white12, height: 32),


              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    if (_selectedMarket != 'MT5') ...[
                      Expanded(child: _buildField(AppStrings.get(ref, 'auto_pnl_pct') ?? 'Otomatik P&L (%)', _pnlPctCtrl, isNum: true, isAutoCompute: true)),
                      const SizedBox(width: 16),
                    ],
                    Expanded(child: _buildField(AppStrings.get(ref, 'auto_pnl_amt') ?? 'Otomatik P&L (\$)', _pnlAmtCtrl, isNum: true, isAutoCompute: true)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              if (_selectedMarket == 'Futures') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Expanded(child: _buildField(AppStrings.get(ref, 'unleveraged_pnl') ?? 'Kaldıraçsız P&L (\$)', _unlevPnlAmtCtrl, isNum: true, isAutoCompute: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField(AppStrings.get(ref, 'equivalent_volume') ?? 'Eşdeğer Hacim (\$)', _totalSizeCtrl, isNum: true, isAutoCompute: true)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              _buildField(AppStrings.get(ref, 'trade_note') ?? 'İşlem Notu (Dersler)', _notesCtrl, half: false),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.trade != null)
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
            label: Text(AppStrings.get(ref, 'delete_upper') ?? 'SİL', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              ref.read(tradeProvider.notifier).deleteTrade(widget.trade!.id);
              Navigator.pop(context);
            },
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          onPressed: () {
            final container = ProviderScope.containerOf(context);
            
            String exStr = _selectedMarket == 'MT5' ? 'MT5' : (_exchangeCtrl.text.isEmpty ? 'Bilinmiyor' : _exchangeCtrl.text);
            
            if (exStr != 'Bilinmiyor') {
              container.read(exchangeProvider.notifier).addExchange(exStr);
            }

            String prStr = _pairCtrl.text.isEmpty ? AppStrings.get(ref, 'undefined_text') ?? 'Belirsiz' : _pairCtrl.text;
            double cap = double.tryParse(_capCtrl.text) ?? 0;
            double enp = double.tryParse(_entryCtrl.text) ?? 0;
            double? exp = double.tryParse(_exitCtrl.text);
            double? sl = double.tryParse(_slCtrl.text);
            double? tp = double.tryParse(_tpCtrl.text);
                List<double> addTps = _additionalTpCtrls.map((c) => double.tryParse(c.text)).where((v) => v != null).cast<double>().toList();
                List<double> buyTgts = _buyTargetsCtrls.map((c) => double.tryParse(c.text)).where((v) => v != null).cast<double>().toList();
                List<double> sellTgts = _sellTargetsCtrls.map((c) => double.tryParse(c.text)).where((v) => v != null).cast<double>().toList();

            double? pct = double.tryParse(_pnlPctCtrl.text);
            double? amt = double.tryParse(_pnlAmtCtrl.text);

            DateTime? currentExitDate;
            if (widget.trade == null) {
               currentExitDate = exp != null ? widget.date : null;
            } else {
               if (exp != null && widget.trade!.exitPrice == null) {
                  currentExitDate = widget.date; // Closing it today via edit
               } else if (exp != null && widget.trade!.exitPrice != null) {
                  currentExitDate = widget.trade!.exitDate ?? widget.date;
               } else {
                  currentExitDate = null; // exp is null, so it's open
               }
            }

            if (widget.trade == null) {
              container.read(tradeProvider.notifier).addTrade(
                date: widget.date,
                timeText: _time.format(context),
                exchange: exStr,
                market: _selectedMarket,
                pair: prStr,
                type: _selectedType,
                leverage: _selectedMarket == 'MT5' ? '${_leverage} Lot' : '${_leverage.toInt()}x',
                capitalAllocated: cap,
                entryPrice: enp,
                exitPrice: exp,
                stopLoss: sl,
                takeProfit: tp,
                        takeProfits: addTps.isNotEmpty ? addTps : null,
                        buyTargets: buyTgts.isNotEmpty ? buyTgts : null,
                        sellTargets: sellTgts.isNotEmpty ? sellTgts : null,
                pnlPercent: pct,
                pnlAmount: amt,
                notes: _notesCtrl.text,
                exitDate: currentExitDate,
              );
            } else {
              container.read(tradeProvider.notifier).editTrade(
                widget.trade!.id,
                exchange: exStr,
                market: _selectedMarket,
                pair: prStr,
                type: _selectedType,
                leverage: _selectedMarket == 'MT5' ? '${_leverage} Lot' : '${_leverage.toInt()}x',
                capitalAllocated: cap,
                entryPrice: enp,
                exitPrice: exp,
                stopLoss: sl,
                takeProfit: tp,
                        takeProfits: addTps.isNotEmpty ? addTps : null,
                        buyTargets: buyTgts.isNotEmpty ? buyTgts : null,
                        sellTargets: sellTgts.isNotEmpty ? sellTgts : null,
                pnlPercent: pct,
                pnlAmount: amt,
                notes: _notesCtrl.text,
                exitDate: currentExitDate,
              );
            }
            Navigator.pop(context);
          },
          child: Text(AppStrings.get(ref, 'save_upper') ?? 'KAYDET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildField(String label, TextEditingController? ctrl, {bool half = false, bool isNum = false, Function()? onTap, String? textOverride, bool isAutoCompute = false}) {
    return SizedBox(
      width: half ? 260 : double.infinity,
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
        style: TextStyle(color: isAutoCompute ? Colors.greenAccent : Colors.white, fontWeight: isAutoCompute ? FontWeight.bold : FontWeight.normal),
        readOnly: onTap != null,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: isAutoCompute ? Colors.black26 : const Color(0x33000000),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          hintText: textOverride,
          hintStyle: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
