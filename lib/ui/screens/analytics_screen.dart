import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:finance_27/providers/jar_provider.dart';
import 'package:finance_27/providers/transaction_provider.dart';
import 'package:finance_27/providers/reminder_provider.dart';
import 'package:finance_27/providers/trade_provider.dart';
import 'package:finance_27/providers/settings_provider.dart';
import 'package:finance_27/providers/goal_provider.dart';
import 'package:finance_27/providers/income_provider.dart';

import 'package:finance_27/models/jar_model.dart';
import 'package:finance_27/models/trade_model.dart';
import 'package:finance_27/models/goal_model.dart';
import 'package:finance_27/core/localization_provider.dart';

enum FilterMode { days7, month, year, lifetime }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  FilterMode _filterMode = FilterMode.month;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _touchedChartGroupIndex = -1;
  final ScreenshotController _screenshotController = ScreenshotController();

  List<String> get _monthNames => [
    AppStrings.get(ref, 'jan') ?? 'Ocak',
    AppStrings.get(ref, 'feb') ?? 'Şubat',
    AppStrings.get(ref, 'mar') ?? 'Mart',
    AppStrings.get(ref, 'apr') ?? 'Nisan',
    AppStrings.get(ref, 'may') ?? 'Mayıs',
    AppStrings.get(ref, 'jun') ?? 'Haziran',
    AppStrings.get(ref, 'jul') ?? 'Temmuz',
    AppStrings.get(ref, 'aug') ?? 'Ağustos',
    AppStrings.get(ref, 'sep') ?? 'Eylül',
    AppStrings.get(ref, 'oct') ?? 'Ekim',
    AppStrings.get(ref, 'nov') ?? 'Kasım',
    AppStrings.get(ref, 'dec') ?? 'Aralık',
  ];

  String _getFilterLabel() {
    switch (_filterMode) {
      case FilterMode.days7:
        return AppStrings.get(ref, 'filter_7_days') ?? 'Son 7 Gün';
      case FilterMode.month:
        return '${_monthNames[_selectedMonth - 1]} $_selectedYear';
      case FilterMode.year:
        return '$_selectedYear ${AppStrings.get(ref, 'year_suffix') ?? 'Yılı'}';
      case FilterMode.lifetime:
        return AppStrings.get(ref, 'all_time_lifetime') ?? 'Tümü (Ömür Boyu)';
    }
  }

  bool _isWithinFilter(DateTime date) {
    final now = DateTime.now();
    switch (_filterMode) {
      case FilterMode.days7:
        final start = now.subtract(const Duration(days: 7));
        return date.isAfter(start) || date.isAtSameMomentAs(start);
      case FilterMode.month:
        return date.year == _selectedYear && date.month == _selectedMonth;
      case FilterMode.year:
        return date.year == _selectedYear;
      case FilterMode.lifetime:
        return true;
    }
  }

  DateTime _getStartDateForChart() {
    final now = DateTime.now();
    switch (_filterMode) {
      case FilterMode.days7:
        return now.subtract(const Duration(days: 7));
      case FilterMode.month:
        return DateTime(_selectedYear, _selectedMonth, 1);
      case FilterMode.year:
        return DateTime(_selectedYear, 1, 1);
      case FilterMode.lifetime:
        return now.subtract(const Duration(days: 30));
    }
  }

  int _getDaysForChart() {
    switch (_filterMode) {
      case FilterMode.days7:
        return 7;
      case FilterMode.month:
        return DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
      case FilterMode.year:
        return DateTime(
          _selectedYear,
          12,
          31,
        ).difference(DateTime(_selectedYear, 1, 1)).inDays;
      case FilterMode.lifetime:
        return 30;
    }
  }

  Future<void> _exportScreenshot(Widget contentWidget) async {
    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.get(ref, 'export_started') ?? 'Analiz haz?rlan?yor, lutfen bekleyin...'), duration: Duration(seconds: 2)));
      
      final Uint8List? imageBytes = await _screenshotController.capture(
          delay: const Duration(milliseconds: 500),
        );
      if (imageBytes == null) return;

      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = 'Analytics_$timestamp.png';

      if (kIsWeb) {
          final blob = html.Blob([imageBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Kay?t Basar?l?! PNG Dosyas? indirildi.')), duration: const Duration(seconds: 5), backgroundColor: Colors.green));
          }
      } else {
          Directory dir;
          if (defaultTargetPlatform == TargetPlatform.android) {
              dir = Directory('/storage/emulated/0/Download');
          } else {
              dir = defaultTargetPlatform == TargetPlatform.windows ? (await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory()) : await getTemporaryDirectory();
          }
          final filePath = '${dir.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(imageBytes);
          if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.macOS) { await Gal.putImage(filePath); } else { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Windows Indirilenler Klasorune Kaydedildi: $filePath'), duration: Duration(seconds: 5), backgroundColor: Colors.green)); }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((AppStrings.get(ref, 'export_success_png') ?? 'Galeriye Kaydedildi!').replaceAll('{path}', filePath)), backgroundColor: Colors.green));
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((AppStrings.get(ref, 'export_failed') ?? 'Kay?t basar?s?z: {error}').replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(ref, 'period_filter') ?? 'Dönem Filtresi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildModalFilterChip(
                          AppStrings.get(ref, 'filter_7_days') ?? '7 Gün',
                          FilterMode.days7,
                          setModalState,
                        ),
                        const SizedBox(width: 8),
                        _buildModalFilterChip(
                          AppStrings.get(ref, 'filter_monthly') ?? 'Aylık',
                          FilterMode.month,
                          setModalState,
                        ),
                        const SizedBox(width: 8),
                        _buildModalFilterChip(
                          AppStrings.get(ref, 'filter_yearly') ?? 'Yıllık',
                          FilterMode.year,
                          setModalState,
                        ),
                        const SizedBox(width: 8),
                        _buildModalFilterChip(
                          AppStrings.get(ref, 'tab_all') ?? 'Tümü',
                          FilterMode.lifetime,
                          setModalState,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_filterMode == FilterMode.month ||
                      _filterMode == FilterMode.year)
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            setModalState(() => _selectedYear--);
                            setState(() {});
                          },
                        ),
                        Text(
                          _selectedYear.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            setModalState(() => _selectedYear++);
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                  if (_filterMode == FilterMode.month) ...[
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected = _selectedMonth == monthNum;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => _selectedMonth = monthNum);
                            setState(() {});
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white10,
                              ),
                            ),
                            child: Text(
                              _monthNames[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppStrings.get(ref, 'apply') ?? 'Uygula',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalFilterChip(
    String label,
    FilterMode mode,
    StateSetter setModalState,
  ) {
    final isSelected = _filterMode == mode;
    return GestureDetector(
      onTap: () {
        setModalState(() => _filterMode = mode);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.black12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white10,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCurrency = ref.watch(currencyProvider);
    Widget buildExportContent() {
      return Container(
                  color: const Color(0xFF0F172A),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionTitle(
                        AppStrings.get(ref, 'war_plan_ops') ??
                            'SAVAŞ PLANI (İşlemler & Görevler)',
                      ),
                      const SizedBox(height: 16),
                      _buildTradesAnalytics(),
                      const SizedBox(height: 16),
                      _buildSpotAnalytics(),
                      const SizedBox(height: 16),
                      _buildSectionTitle('MT5 ANALIZI (Forex & Emtia)'),
                      const SizedBox(height: 16),
                      _buildMT5Analytics(),
                      const SizedBox(height: 16),
                      _buildTasksAnalytics(),

                      const SizedBox(height: 32),
                      _buildSectionTitle(
                        AppStrings.get(ref, 'status_cash_jars'),
                        trailing: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            border: Border.all(color: Colors.white10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentCurrency,
                              dropdownColor: const Color(0xFF1E293B),
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'KGS',
                                  child: Text(
                                    'KGS',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'USD',
                                  child: Text(
                                    'USD',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'EUR',
                                  child: Text(
                                    'EUR',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'TRY',
                                  child: Text(
                                    'TRY',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'RUB',
                                  child: Text(
                                    'RUB',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  ref.read(currencyProvider.notifier).state =
                                      val;
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFinancialAnalytics(),
                      const SizedBox(height: 16),
                      _buildJarAnalytics(),

                      const SizedBox(height: 32),
                      _buildSectionTitle(
                        AppStrings.get(ref, 'goals_progress') ??
                            'HEDEFLER (Genel İlerleme)',
                      ),
                      const SizedBox(height: 16),
                      _buildGoalsAnalytics(),
                      const SizedBox(height: 48),
                    ],
                  ),
                );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          AppStrings.get(ref, 'analytics_stats'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showFilterModal,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _getFilterLabel(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white54,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _exportScreenshot(buildExportContent()),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Screenshot(
                controller: _screenshotController,
                child: buildExportContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing],
      ],
    );
  }

  Widget _buildTradesAnalytics() {
    final trades = ref.watch(tradeProvider).where((t) {
      final isTradeOpen = t.exitDate == null;
      return t.market == 'Futures' &&
          _isWithinFilter(isTradeOpen ? t.date : (t.exitDate ?? t.date));
    }).toList();

    int totalTrades = trades.length;
    final closedTrades = trades.where((t) => t.exitDate != null).toList();

    int winningTrades = closedTrades
        .where((t) => (t.pnlAmount ?? 0) > 0)
        .length;
    int losingTrades = closedTrades.where((t) => (t.pnlAmount ?? 0) < 0).length;
    int openTrades = trades.where((t) => t.exitDate == null).length;

    double totalWonAmount = closedTrades
        .where((t) => (t.pnlAmount ?? 0) > 0)
        .fold(0.0, (sum, t) => sum + (t.pnlAmount ?? 0));
    double totalLostAmount = closedTrades
        .where((t) => (t.pnlAmount ?? 0) < 0)
        .fold(0.0, (sum, t) => sum + (t.pnlAmount ?? 0).abs());
    double totalPnL = totalWonAmount - totalLostAmount;

    double totalFuturesInvested = trades.fold(0.0, (sum, t) => sum + t.capitalAllocated);
    double totalFuturesBudget = totalFuturesInvested + totalWonAmount - totalLostAmount;

    double winRate = totalTrades == 0
        ? 0
        : (winningTrades / (winningTrades + losingTrades)) * 100;
    if (winRate.isNaN || winRate.isInfinite) winRate = 0;

    List<FlSpot> pnlSpots = [];
    if (closedTrades.isNotEmpty) {
      closedTrades.sort(
        (a, b) => (a.exitDate ?? a.date).compareTo(b.exitDate ?? b.date),
      );
      double cumulativePnL = 0;
      for (int i = 0; i < closedTrades.length; i++) {
        cumulativePnL += (closedTrades[i].pnlAmount ?? 0);
        pnlSpots.add(FlSpot(i.toDouble(), cumulativePnL));
      }
    } else {
      pnlSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
    }

    double maxPnLY = 10;
    double minPnLY = -10;
    for (var s in pnlSpots) {
      if (s.y > maxPnLY) maxPnLY = s.y;
      if (s.y < minPnLY) minPnLY = s.y;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppStrings.get(ref, 'net_pnl') ?? 'Net PnL (Kâr/Zarar)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalPnL >= 0 ? '+' : '-'}\$${totalPnL.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: totalPnL >= 0 ? Colors.greenAccent : Colors.redAccent,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              shadows: [
                BoxShadow(
                  color: (totalPnL >= 0 ? Colors.greenAccent : Colors.redAccent)
                      .withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildCandleBarChart(closedTrades),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppStrings.get(ref, 'profit'),
                  totalWonAmount,
                  Colors.greenAccent,
                  Icons.trending_up,
                  '\$',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  AppStrings.get(ref, 'active_budget') ?? 'Aktif Bütçe',
                  totalFuturesBudget,
                  Colors.purpleAccent,
                  Icons.account_balance_wallet,
                  '\$',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  AppStrings.get(ref, 'loss'),
                  totalLostAmount,
                  Colors.redAccent,
                  Icons.trending_down,
                  '\$',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 35,
                        sections: totalTrades == 0
                            ? [
                                PieChartSectionData(
                                  color: Colors.grey.withOpacity(0.2),
                                  value: 1,
                                  radius: 10,
                                  showTitle: false,
                                ),
                              ]
                            : [
                                PieChartSectionData(
                                  color: Colors.greenAccent,
                                  value: winningTrades.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.redAccent,
                                  value: losingTrades.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.orangeAccent,
                                  value: openTrades.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                              ],
                      ),
                    ),
                    Center(
                      child: Text(
                        '%${winRate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(
                      AppStrings.get(ref, 'winning_trades') ??
                          'Kazanan İşlemler',
                      winningTrades.toString(),
                      Colors.greenAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      AppStrings.get(ref, 'losing_trades') ??
                          'Kaybeden İşlemler',
                      losingTrades.toString(),
                      Colors.redAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      AppStrings.get(ref, 'open_trades') ?? 'Açık İşlemler',
                      openTrades.toString(),
                      Colors.orangeAccent,
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.get(ref, 'total_trades') ?? 'Toplam İşlem',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        Text(
                          totalTrades.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String value, Color color) {
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildMT5Analytics() {
    final trades = ref.watch(tradeProvider).where((t) {
      final isTradeOpen = t.exitDate == null;
      return t.market == 'MT5' &&
          _isWithinFilter(isTradeOpen ? t.date : (t.exitDate ?? t.date));
    }).toList();

    int totalTrades = trades.length;
    final closedTrades = trades.where((t) => t.exitDate != null).toList();

    int winningTrades = closedTrades
        .where((t) => (t.pnlAmount ?? 0) > 0)
        .length;
    int losingTrades = closedTrades.where((t) => (t.pnlAmount ?? 0) < 0).length;
    int openTrades = trades.where((t) => t.exitDate == null).length;

    double totalWonAmount = closedTrades
        .where((t) => (t.pnlAmount ?? 0) > 0)
        .fold(0.0, (sum, t) => sum + (t.pnlAmount ?? 0));
    double totalLostAmount = closedTrades
        .where((t) => (t.pnlAmount ?? 0) < 0)
        .fold(0.0, (sum, t) => sum + (t.pnlAmount ?? 0).abs());
    double totalPnL = totalWonAmount - totalLostAmount;

    double totalMT5Invested = trades.fold(0.0, (sum, t) => sum + t.capitalAllocated);
    double totalMT5Budget = totalMT5Invested + totalWonAmount - totalLostAmount;

    double winRate = totalTrades == 0
        ? 0
        : (winningTrades / (winningTrades + losingTrades)) * 100;
    if (winRate.isNaN || winRate.isInfinite) winRate = 0;

    List<FlSpot> pnlSpots = [];
    if (closedTrades.isNotEmpty) {
      closedTrades.sort(
        (a, b) => (a.exitDate ?? a.date).compareTo(b.exitDate ?? b.date),
      );
      double cumulativePnL = 0;
      for (int i = 0; i < closedTrades.length; i++) {
        cumulativePnL += (closedTrades[i].pnlAmount ?? 0);
        pnlSpots.add(FlSpot(i.toDouble(), cumulativePnL));
      }
    } else {
      pnlSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
    }

    double maxPnLY = 10;
    double minPnLY = -10;
    for (var s in pnlSpots) {
      if (s.y > maxPnLY) maxPnLY = s.y;
      if (s.y < minPnLY) minPnLY = s.y;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppStrings.get(ref, 'net_pnl') ?? 'Net PnL (Kâr/Zarar)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalPnL >= 0 ? '+' : '-'}\$${totalPnL.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: totalPnL >= 0 ? Colors.greenAccent : Colors.redAccent,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              shadows: [
                BoxShadow(
                  color: (totalPnL >= 0 ? Colors.greenAccent : Colors.redAccent)
                      .withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildCandleBarChart(closedTrades),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppStrings.get(ref, 'profit'),
                  totalWonAmount,
                  Colors.greenAccent,
                  Icons.trending_up,
                  '\$',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  AppStrings.get(ref, 'active_budget') ?? 'Aktif Bütçe',
                  totalMT5Budget,
                  Colors.purpleAccent,
                  Icons.account_balance_wallet,
                  '\$',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  AppStrings.get(ref, 'loss'),
                  totalLostAmount,
                  Colors.redAccent,
                  Icons.trending_down,
                  '\$',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 35,
                        sections: totalTrades == 0
                            ? [
                                PieChartSectionData(
                                  color: Colors.grey.withOpacity(0.2),
                                  value: 1,
                                  radius: 10,
                                  showTitle: false,
                                ),
                              ]
                            : [
                                PieChartSectionData(
                                  color: Colors.greenAccent,
                                  value: winningTrades.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.redAccent,
                                  value: losingTrades.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.orangeAccent,
                                  value: openTrades.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                              ],
                      ),
                    ),
                    Center(
                      child: Text(
                        '%${winRate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(
                      AppStrings.get(ref, 'winning_trades') ??
                          'Kazanan İşlemler',
                      winningTrades.toString(),
                      Colors.greenAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      AppStrings.get(ref, 'losing_trades') ??
                          'Kaybeden İşlemler',
                      losingTrades.toString(),
                      Colors.redAccent,
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(
                      AppStrings.get(ref, 'open_trades') ?? 'Açık İşlemler',
                      openTrades.toString(),
                      Colors.orangeAccent,
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.get(ref, 'total_trades') ?? 'Toplam İşlem',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        Text(
                          totalTrades.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpotAnalytics() {
    final spotTrades = ref
        .watch(tradeProvider)
        .where(
          (t) => t.market == 'Spot' && _isWithinFilter(t.exitDate ?? t.date),
        )
        .toList();
    if (spotTrades.isEmpty) return const SizedBox.shrink();

    // Özel Sıralama Mantığı: Kazananlar -> Kaybedenler -> Bekleyenler
    spotTrades.sort((a, b) {
      bool aClosed = a.exitDate != null;
      bool bClosed = b.exitDate != null;

      if (aClosed && !bClosed) return -1;
      if (!aClosed && bClosed) return 1;

      if (aClosed && bClosed) {
        double aPnl = a.pnlAmount ?? 0;
        double bPnl = b.pnlAmount ?? 0;
        if (aPnl > 0 && bPnl <= 0) return -1;
        if (aPnl <= 0 && bPnl > 0) return 1;
        // İkisi de kârda veya ikisi de zarardaysa kârı/zararı en yüksek olan üstte olsun
        return bPnl.compareTo(aPnl);
      }

      // İkisi de açıksa en son eklenen en üstte dursun
      return b.date.compareTo(a.date);
    });

    double totalInvested = spotTrades.fold(0.0, (sum, t) => sum + t.capitalAllocated);
    
    double totalSpotProfit = spotTrades
        .where((t) => t.exitDate != null && (t.pnlAmount ?? 0) > 0)
        .fold(0.0, (sum, t) => sum + (t.pnlAmount ?? 0));
    
    double totalSpotLoss = spotTrades
        .where((t) => t.exitDate != null && (t.pnlAmount ?? 0) < 0)
        .fold(0.0, (sum, t) => sum + (t.pnlAmount ?? 0).abs());
        
    double totalSpotBudget = totalInvested + totalSpotProfit - totalSpotLoss;
    

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Center(
                  child: Text(
                    AppStrings.get(ref, 'spot_wallet_title') ?? 'Spot Cüzdan (Hodl & Spot)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${AppStrings.get(ref, 'active_budget') ?? 'Aktif Bütçe: '}\$${totalSpotBudget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        AppStrings.get(ref, 'total_profit') ?? 'Toplam Fayda',
                        totalSpotProfit,
                        Colors.greenAccent,
                        Icons.arrow_upward,
                        '\$',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        AppStrings.get(ref, 'total_loss') ?? 'Toplam Kayıp',
                        totalSpotLoss,
                        Colors.redAccent,
                        Icons.arrow_downward,
                        '\$',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: spotTrades.map((t) {
                bool isClosed = t.exitDate != null;
                double coinAmount =
                    t.capitalAllocated / (t.entryPrice == 0 ? 1 : t.entryPrice);
                double pnl = t.pnlAmount ?? 0;
                String pnlPrefix = pnl >= 0 ? '+' : '';
                Color pnlColor = pnl >= 0
                    ? Colors.greenAccent
                    : Colors.redAccent;
                final DateFormat df = DateFormat(
                  'd MMM yyyy',
                  AppStrings.getDateFormatLocale(
                    ref.watch(localeProvider) ?? 'tr_TR',
                  ),
                );

                return Container(
                  width:
                      260, // Kapsamayı optimize etmek için hafifçe daraltıldı
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isClosed
                          ? Colors.white10
                          : Colors.purpleAccent.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.currency_bitcoin,
                                color: Colors.orangeAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                [
                                      'belirsiz',
                                      'undefined',
                                      'не определено',
                                      'белгисиз',
                                    ].contains(t.pair.toLowerCase())
                                    ? (AppStrings.get(ref, 'undefined_text') ??
                                          'Belirsiz')
                                    : t.pair,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isClosed
                                  ? Colors.grey.withOpacity(0.2)
                                  : Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isClosed
                                  ? (AppStrings.get(ref, 'sold_upper') ??
                                        'SATILDI')
                                  : (AppStrings.get(ref, 'holding_upper') ??
                                        'ELİMDE'),
                              style: TextStyle(
                                color: isClosed
                                    ? Colors.white54
                                    : Colors.greenAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.get(ref, 'buy_colon') ?? 'Alış: ',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '\$${t.entryPrice} (${df.format(t.date)})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.get(ref, 'amount_label') ?? 'Miktar: ',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${coinAmount.toStringAsFixed(4)} (\$${t.capitalAllocated})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.get(ref, 'sell_colon') ?? 'Satış: ',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                isClosed
                                    ? '\$${t.exitPrice} (${df.format(t.exitDate!)})'
                                    : AppStrings.get(ref, 'pending') ??
                                          'Bekliyor',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isClosed) ...[
                        const Divider(color: Colors.white10, height: 16),
                        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.get(ref, 'pnl_colon') ??
                                  'Kâr / Zarar:',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '$pnlPrefix\$${pnl.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: pnlColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksAnalytics() {
    ref.watch(reminderProvider); // Observe state to trigger rebuilds
    final notifier = ref.read(reminderProvider.notifier);

    DateTime start = _getStartDateForChart();
    int days = _getDaysForChart();

    int total = 0;
    int completed = 0;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i <= days; i++) {
      DateTime d = start.add(Duration(days: i));
      DateTime dDate = DateTime(d.year, d.month, d.day);

      // Gelecekteki günleri bekleyen görev olarak saymamak için bugünden sonrasını atla
      if (dDate.isAfter(today)) continue;

      final dayTasks = notifier.getRemindersForDate(dDate);
      total += dayTasks.length;
      completed += dayTasks.where((t) => t.isCompleted).length;
    }

    int pending = total - completed;
    double progress = total == 0 ? 0 : (completed / total) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(ref, 'task_performance'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (AppStrings.get(ref, 'total_tasks') ??
                          'Toplam: {total} Görev')
                      .replaceAll('{total}', total.toString()),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 35,
                        sections: total == 0
                            ? [
                                PieChartSectionData(
                                  color: Colors.grey.withOpacity(0.2),
                                  value: 1,
                                  radius: 10,
                                  showTitle: false,
                                ),
                              ]
                            : [
                                PieChartSectionData(
                                  color: Colors.greenAccent,
                                  value: completed.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.orangeAccent,
                                  value: pending.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                              ],
                      ),
                    ),
                    Center(
                      child: Text(
                        '%${progress.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(
                      AppStrings.get(ref, 'completed') ?? 'Tamamlanan',
                      completed.toString(),
                      Colors.greenAccent,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      AppStrings.get(ref, 'pending') ?? 'Bekleyen',
                      pending.toString(),
                      Colors.orangeAccent,
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.get(ref, 'success_rate') ?? 'Başarı Oranı',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        Text(
                          '%${progress.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: progress > 70
                                ? Colors.greenAccent
                                : (progress > 40
                                      ? Colors.orangeAccent
                                      : Colors.redAccent),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialAnalytics() {
    final currentCurrency = ref.watch(currencyProvider);
    final jars = ref.watch(jarProvider).where((j) => j.isActive).toList();
    final allTransactions = ref
        .watch(transactionProvider)
        .where((t) => t.currency == currentCurrency)
        .toList();

    final incomes = ref
        .watch(incomeProvider)
        .where((i) => _isWithinFilter(i.date) && i.currency == currentCurrency)
        .toList();
    final expenses = allTransactions
        .where((t) => !t.isIncome && _isWithinFilter(t.date))
        .toList();

    double totalIncome = incomes.fold(0.0, (sum, i) => sum + i.amount);
    double totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    double net = totalIncome - totalExpense;

    DateTime start = _getStartDateForChart();
    int days = _getDaysForChart();

    double initialBalance = 0;
    for (var t in allTransactions.where((t) => t.date.isBefore(start))) {
      if (t.isIncome)
        initialBalance += t.amount;
      else
        initialBalance -= t.amount;
    }

    List<FlSpot> totalBalanceSpots = [];
    Map<JarType, List<FlSpot>> jarSpots = {for (var jar in jars) jar.type: []};

    double runningBalance = initialBalance;
    Map<JarType, double> runningJarExpenses = {
      for (var jar in jars) jar.type: 0.0,
    };

    if (allTransactions.isNotEmpty || initialBalance > 0) {
      for (int i = 0; i <= days; i++) {
        DateTime d = start.add(Duration(days: i));

        var dayTxs = allTransactions.where(
          (t) =>
              t.date.year == d.year &&
              t.date.month == d.month &&
              t.date.day == d.day,
        );

        for (var t in dayTxs) {
          if (t.isIncome) {
            runningBalance += t.amount;
          } else {
            runningBalance -= t.amount;
            runningJarExpenses[t.jarType] =
                (runningJarExpenses[t.jarType] ?? 0) + t.amount;
          }
        }

        totalBalanceSpots.add(FlSpot(i.toDouble(), runningBalance));
        for (var jar in jars) {
          jarSpots[jar.type]!.add(
            FlSpot(i.toDouble(), runningJarExpenses[jar.type]!),
          );
        }
      }
    } else {
      totalBalanceSpots = [const FlSpot(0, 0), const FlSpot(1, 0)];
      for (var jar in jars) {
        jarSpots[jar.type] = [const FlSpot(0, 0), const FlSpot(1, 0)];
      }
    }

    double maxY = 100;
    for (var s in totalBalanceSpots) {
      if (s.y > maxY) maxY = s.y;
    }
    for (var list in jarSpots.values) {
      for (var s in list) {
        if (s.y > maxY) maxY = s.y;
      }
    }

    final currencySymbol = NumberFormat.simpleCurrency(
      name: currentCurrency,
    ).currencySymbol;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: net >= 0
                  ? Colors.greenAccent.withOpacity(0.08)
                  : Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: net >= 0
                    ? Colors.greenAccent.withOpacity(0.3)
                    : Colors.redAccent.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (net >= 0 ? Colors.greenAccent : Colors.redAccent)
                      .withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppStrings.get(ref, 'net_cash_flow') ?? 'Net Nakit Akışı',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${net >= 0 ? '+' : ''}$currencySymbol${net.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: net >= 0 ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                    letterSpacing: -0.5,
                    shadows: [
                      BoxShadow(
                        color:
                            (net >= 0 ? Colors.greenAccent : Colors.redAccent)
                                .withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  AppStrings.get(ref, 'income_upper') ?? 'GELİR',
                  totalIncome,
                  Colors.greenAccent,
                  Icons.arrow_downward,
                  currencySymbol,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  AppStrings.get(ref, 'expense_upper') ?? 'GİDER',
                  totalExpense,
                  Colors.redAccent,
                  Icons.arrow_upward,
                  currencySymbol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.get(ref, 'cash_flow_trend') ?? 'Nakit Akışı Eğilimi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (group) => Colors.transparent,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label = '';
                        Color color = Colors.white;

                        if (spot.barIndex == 0) {
                          label = "Total";
                        } else {
                          int jarIndex = spot.barIndex - 1;
                          if (jarIndex >= 0 && jarIndex < jars.length) {
                            var jar = jars[jarIndex];
                            label = jar.customName ?? _getJarName(jar.type);
                            color = _getJarColor(jar.type);
                          }
                        }

                        return LineTooltipItem(
                          '$label\n$currencySymbol${spot.y.toStringAsFixed(2)}',
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        int totalDays = _getDaysForChart();
                        if (index < 0 || index > totalDays)
                          return const SizedBox.shrink();
                        if (index != 0 &&
                            index != totalDays &&
                            index != totalDays ~/ 2)
                          return const SizedBox.shrink();

                        DateTime d = start.add(Duration(days: index));
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: totalBalanceSpots,
                    isCurved: true,
                    color: Colors.white,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  ...jars.map((jar) {
                    return LineChartBarData(
                      spots: jarSpots[jar.type]!,
                      isCurved: true,
                      color: _getJarColor(jar.type),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    Color color,
    IconData icon,
    String currencySymbol,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildJarAnalytics() {
    final jars = ref.watch(jarProvider).where((j) => j.isActive).toList();
    final currentCurrency = ref.watch(currencyProvider);
    final currencySymbol = NumberFormat.simpleCurrency(
      name: currentCurrency,
    ).currencySymbol;
    final allTransactions = ref
        .watch(transactionProvider)
        .where((t) => t.currency == currentCurrency)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get(ref, 'jar_balance_distribution') ??
                'Kavanoz Bakiye Dağılımı',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: jars.map((jar) {
              DateTime? filterStart;
              final now = DateTime.now();
              switch (_filterMode) {
                case FilterMode.days7:
                  filterStart = now.subtract(const Duration(days: 7));
                  break;
                case FilterMode.month:
                  filterStart = DateTime(_selectedYear, _selectedMonth, 1);
                  break;
                case FilterMode.year:
                  filterStart = DateTime(_selectedYear, 1, 1);
                  break;
                case FilterMode.lifetime:
                  filterStart = null;
                  break;
              }

              double pastBalance = 0.0;
              double periodIncome = 0.0;
              double periodExpense = 0.0;

              for (var t in allTransactions.where(
                (t) => t.jarType == jar.type,
              )) {
                if (filterStart != null && t.date.isBefore(filterStart)) {
                  if (t.isIncome)
                    pastBalance += t.amount;
                  else
                    pastBalance -= t.amount;
                } else if (_isWithinFilter(t.date)) {
                  if (t.isIncome)
                    periodIncome += t.amount;
                  else
                    periodExpense += t.amount;
                }
              }

              double totalBudget = pastBalance + periodIncome;
              double currentBalance = totalBudget - periodExpense;

              double pct = 0;
              if (totalBudget > 0) {
                pct = (periodExpense / totalBudget) * 100;
                if (pct > 100) pct = 100;
                if (pct < 0) pct = 0;
              } else if (periodExpense > 0) {
                pct = 100;
              }

              String jarName = jar.customName ?? _getJarName(jar.type);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getJarColor(jar.type),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              jarName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '%${pct.toStringAsFixed(1)} ${AppStrings.get(ref, 'expense_upper') ?? 'Harcanan'}',
                          style: TextStyle(
                            color: pct > 90 ? Colors.redAccent : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalBudget > 0
                            ? (periodExpense / totalBudget).clamp(0.0, 1.0)
                            : (periodExpense > 0 ? 1.0 : 0.0),
                        minHeight: 8,
                        backgroundColor: Colors.white10,
                        color: pct > 90
                            ? Colors.redAccent
                            : _getJarColor(jar.type),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        _buildJarMiniStat(
                          AppStrings.get(ref, 'budget_allocated') ?? 'Bütçe',
                          totalBudget,
                          currencySymbol,
                        ),
                        _buildJarMiniStat(
                          AppStrings.get(ref, 'expense_upper') ?? 'Harcanan',
                          periodExpense,
                          currencySymbol,
                        ),
                        _buildJarMiniStat(
                          AppStrings.get(ref, 'remaining') ?? 'Kalan',
                          currentBalance,
                          currencySymbol,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJarMiniStat(String label, double amount, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          '$currencySymbol${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getJarName(JarType type) {
    return AppStrings.get(ref, type.displayName) ?? type.displayName;
  }

  Color _getJarColor(JarType type) {
    switch (type) {
      case JarType.necessities:
        return Colors.blueAccent;
      case JarType.financialFreedom:
        return Colors.amberAccent;
      case JarType.education:
        return Colors.orangeAccent;
      case JarType.longTermSavings:
        return Colors.greenAccent;
      case JarType.play:
        return Colors.purpleAccent;
      case JarType.giving:
        return Colors.pinkAccent;
    }
  }

  Widget _buildGoalsAnalytics() {
    final goals = ref.watch(goalProvider);
    int totalGoals = goals.length;
    int completedGoals = goals
        .where((g) => g.currentAmount >= g.targetAmount)
        .length;
    int pendingGoals = totalGoals - completedGoals;
    double totalTarget = goals.fold(0.0, (sum, g) => sum + g.targetAmount);
    double totalCurrent = goals.fold(0.0, (sum, g) => sum + g.currentAmount);
    double totalProgress = totalTarget == 0
        ? 0
        : (totalCurrent / totalTarget) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(ref, 'overall_goal_progress') ??
                    'Genel Hedef İlerlemesi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (AppStrings.get(ref, 'total_goals') ??
                          'Toplam: {total} Hedef')
                      .replaceAll('{total}', totalGoals.toString()),
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 35,
                        sections: totalGoals == 0
                            ? [
                                PieChartSectionData(
                                  color: Colors.grey.withOpacity(0.2),
                                  value: 1,
                                  radius: 10,
                                  showTitle: false,
                                ),
                              ]
                            : [
                                PieChartSectionData(
                                  color: Colors.greenAccent,
                                  value: completedGoals.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  color: Colors.orangeAccent,
                                  value: pendingGoals.toDouble(),
                                  radius: 15,
                                  showTitle: false,
                                ),
                              ],
                      ),
                    ),
                    Center(
                      child: Text(
                        '%${totalProgress.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendItem(
                      AppStrings.get(ref, 'completed') ?? 'Tamamlanan',
                      completedGoals.toString(),
                      Colors.greenAccent,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                      AppStrings.get(ref, 'pending') ?? 'Bekleyen',
                      pendingGoals.toString(),
                      Colors.orangeAccent,
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.get(ref, 'collected_money') ??
                              'Toplanan Para',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        Text(
                          '\$${totalCurrent.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (goals.isNotEmpty) ...[
            const SizedBox(height: 24),
            if (goals.where((g) => g.isFinancial).isNotEmpty) ...[
              Text(
                AppStrings.get(ref, 'fin_goals') ?? 'Finansal Hedefler',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: goals
                    .where((g) => g.isFinancial)
                    .map((g) => _buildGoalItem(g))
                    .toList(),
              ),
              const SizedBox(height: 24),
            ],
            if (goals.where((g) => !g.isFinancial).isNotEmpty) ...[
              Text(
                AppStrings.get(ref, 'prog_goals') ??
                    'İlerleme Hedefleri (Kişisel Gelişim)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: goals
                    .where((g) => !g.isFinancial)
                    .map((g) => _buildGoalItem(g))
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGoalItem(GoalModel goal) {
    final currencySymbol = goal.currency != null
        ? NumberFormat.simpleCurrency(name: goal.currency).currencySymbol
        : NumberFormat.simpleCurrency(
            name: ref.read(currencyProvider),
          ).currencySymbol;
    double progress = goal.targetAmount == 0
        ? 0
        : goal.currentAmount / goal.targetAmount;
    if (progress > 1.0) progress = 1.0;

    int stars = (progress * 5).round();

    final DateFormat formatter = DateFormat(
      'd MMM yyyy',
      AppStrings.getDateFormatLocale(ref.watch(localeProvider) ?? 'tr_TR'),
    );
    String createdStr = formatter.format(goal.createdAt);
    String deadlineStr = formatter.format(goal.deadline);

    // Günlük ve Aylık Gereksinim Hesaplaması
    double remainingAmount = goal.targetAmount - goal.currentAmount;
    if (remainingAmount < 0) remainingAmount = 0;

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = DateTime(
      goal.deadline.year,
      goal.deadline.month,
      goal.deadline.day,
    );
    int remainingDays = to.difference(from).inDays;

    double dailyRequired = 0;
    double monthlyRequired = 0;

    if (remainingDays > 0 && remainingAmount > 0) {
      dailyRequired = remainingAmount / remainingDays;
      monthlyRequired =
          dailyRequired * 30; // 1 Ayı ortalama 30 gün kabul ediyoruz
    }

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: index < stars ? Colors.amberAccent : Colors.white24,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(ref, 'date_colon') ?? 'Tarih: ',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$createdStr ➔ $deadlineStr',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 8, 
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(ref, 'progress_colon') ?? 'İlerleme: ',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                '%${(progress * 100).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.isFinancial
                    ? AppStrings.get(ref, 'budget_colon') ?? 'Bütçe: '
                    : AppStrings.get(ref, 'status_colon') ?? 'Durum: ',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        goal.isFinancial
                            ? '$currencySymbol${goal.currentAmount.toStringAsFixed(2)}'
                            : '${goal.currentAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        ' / ',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                      Text(
                        goal.isFinancial
                            ? '$currencySymbol${goal.targetAmount.toStringAsFixed(2)}'
                            : '${goal.targetAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.isFinancial
                    ? AppStrings.get(ref, 'daily_required_colon') ??
                          'Günlük Gereken: '
                    : AppStrings.get(ref, 'daily_target_colon') ??
                          'Günlük Hedef: ',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    remainingAmount == 0
                        ? AppStrings.get(ref, 'completed') ?? 'Tamamlandı'
                        : (remainingDays > 0
                              ? (goal.isFinancial
                                    ? '$currencySymbol${dailyRequired.toStringAsFixed(2)}'
                                    : '${dailyRequired.toStringAsFixed(1)} ${AppStrings.get(ref, 'units') ?? 'Adet'}')
                              : AppStrings.get(ref, 'time_up') ?? 'Süre Bitti'),
                    style: TextStyle(
                      color: remainingAmount == 0
                          ? Colors.greenAccent
                          : (remainingDays > 0
                                ? Colors.orangeAccent
                                : Colors.redAccent),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get(ref, 'monthly_required_colon') ??
                    'Aylık Gereken: ',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    remainingAmount == 0
                        ? AppStrings.get(ref, 'completed') ?? 'Tamamlandı'
                        : (remainingDays > 0
                              ? (goal.isFinancial
                                    ? '$currencySymbol${monthlyRequired.toStringAsFixed(2)}'
                                    : '${monthlyRequired.toStringAsFixed(1)} ${AppStrings.get(ref, 'units') ?? 'Adet'}')
                              : AppStrings.get(ref, 'time_up') ?? 'Süre Bitti'),
                    style: TextStyle(
                      color: remainingAmount == 0
                          ? Colors.greenAccent
                          : (remainingDays > 0
                                ? Colors.orangeAccent
                                : Colors.redAccent),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCandleBarChart(List<TradeModel> trades) {
    if (trades.isEmpty)
      return Center(
        child: Text(
          AppStrings.get(ref, 'no_data') ?? 'Veri Yok',
          style: const TextStyle(color: Colors.white24),
        ),
      );

    double maxAbsY = 0;
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < trades.length; i++) {
      final t = trades[i];
      final pnlAmt = t.pnlAmount ?? 0;

      if (pnlAmt.abs() > maxAbsY) maxAbsY = pnlAmt.abs();

      barGroups.add(
        BarChartGroupData(
          x: i,
          showingTooltipIndicators: [0],
          barRods: [
            BarChartRodData(
              fromY: 0,
              toY: pnlAmt,
              color: pnlAmt >= 0 ? Colors.greenAccent : Colors.redAccent,
              width: 20, // Mum genişliği
              borderRadius: BorderRadius.zero, // Mum gibi keskin kenarlar
            ),
          ],
        ),
      );
    }

    if (maxAbsY == 0) maxAbsY = 10;
    double maxY = maxAbsY * 1.3;
    double minY = -maxY;

    double chartWidth = trades.length * 80.0;
    if (chartWidth < 300) chartWidth = 300;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        height: 250, // Yüksekliği arttırdık ki mumlar ve yazılar rahat sığsın
        child: Padding(
          padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: minY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) {
                  if (val == 0)
                    return const FlLine(color: Colors.white54, strokeWidth: 2);
                  return const FlLine(color: Colors.white10, strokeWidth: 1);
                },
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30, // Coin ismi için alan
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < 0 || index >= trades.length)
                        return const SizedBox.shrink();
                      final t = trades[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          t.pair,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        barTouchResponse == null ||
                        barTouchResponse.spot == null) {
                      _touchedChartGroupIndex = -1;
                      return;
                    }
                    _touchedChartGroupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) =>
                      Colors.transparent, // Arkaplanı şeffaf yap
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 4,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final t = trades[groupIndex];
                    final pnlAmt = t.pnlAmount ?? 0;
                    final pnlPct = t.pnlPercent ?? 0;
                    final isWin = pnlAmt >= 0;
                    final color = isWin ? Colors.greenAccent : Colors.redAccent;
                    
                    final dateToUse = t.exitDate ?? t.date;
                    final dateStr = DateFormat('dd MMM, HH:mm', AppStrings.getDateFormatLocale(ref.read(localeProvider))).format(dateToUse);

                    bool isTouched = groupIndex == _touchedChartGroupIndex;

                    return BarTooltipItem(
                      isWin
                          ? '+\$${pnlAmt.toStringAsFixed(1)}\n+%${pnlPct.toStringAsFixed(1)}${isTouched ? '\n$dateStr' : ''}'
                          : '-\$${pnlAmt.abs().toStringAsFixed(1)}\n-%${pnlPct.abs().toStringAsFixed(1)}${isTouched ? '\n$dateStr' : ''}',
                      TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }
}
