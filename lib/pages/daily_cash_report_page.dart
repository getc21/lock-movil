import 'package:bellezapp/controllers/cash_controller.dart';
import 'package:bellezapp/models/cash_movement.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/utils/time_utils.dart';
import 'package:bellezapp/widgets/store_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DailyCashReportPage extends StatefulWidget {
  const DailyCashReportPage({super.key});

  @override
  DailyCashReportPageState createState() => DailyCashReportPageState();
}

class DailyCashReportPageState extends State<DailyCashReportPage> {
  late CashController cashController;
  DateTime _selectedDate = DateTime.now();
  List<CashMovement> _dailyMovements = [];

  // Datos para los gráficos
  double _totalIncome = 0.0;
  double _totalOutcome = 0.0;
  double _totalSales = 0.0;
  double _netTotal = 0.0;
  int _movementsCount = 0;

  // Datos por hora para el gráfico de líneas
  final Map<int, double> _hourlyData = {};

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador de forma segura
    try {
      cashController = Get.find<CashController>();
    } catch (e) {
      cashController = Get.put(CashController(), permanent: true);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await cashController.initialize();
      await _loadDailyReport();
    });
  }

  Future<void> _loadDailyReport() async {
    await cashController.loadMovementsByDate(_selectedDate);

    // Convertir Map<String, dynamic> a CashMovement
    final rawMovements = cashController.movements;
    _dailyMovements = rawMovements
        .map((movement) => CashMovement.fromMap(movement))
        .toList();

    _calculateStatistics();
    _generateHourlyData();

    setState(() {});
  }

  void _calculateStatistics() {
    // Los tipos del backend son en inglés: income, expense, sale, opening, closing
    _totalIncome = _dailyMovements
        .where((m) => m.type == 'income')
        .fold(0.0, (sum, m) => sum + m.amount);

    _totalSales = _dailyMovements
        .where((m) => m.type == 'sale')
        .fold(0.0, (sum, m) => sum + m.amount);

    _totalOutcome = _dailyMovements
        .where((m) => m.type == 'expense')
        .fold(0.0, (sum, m) => sum + m.amount);

    _netTotal = (_totalIncome + _totalSales) - _totalOutcome;
    _movementsCount = _dailyMovements.length;
  }

  void _generateHourlyData() {
    _hourlyData.clear();

    // Inicializar todas las horas del día con 0
    for (int i = 0; i < 24; i++) {
      _hourlyData[i] = 0.0;
    }

    // Sumar movimientos por hora
    for (var movement in _dailyMovements) {
      // Convertir a hora de Bolivia
      final boliviaTime = TimeUtils.toBoliviaTime(movement.createdAt);
      final hour = boliviaTime.hour;
      final amount = movement.type == 'expense'
          ? -movement.amount
          : movement.amount;
      _hourlyData[hour] = (_hourlyData[hour] ?? 0.0) + amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: StoreAwareAppBar(
        title: 'Dashboard - Reporte Diario',
        icon: Icons.analytics_outlined,
        backgroundColor: Utils.colorGnav,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
            tooltip: 'Cambiar fecha',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDailyReport,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            _buildQuickStats(),
            SizedBox(height: 20),
            _buildRevenueChart(),
            SizedBox(height: 20),
            _buildHourlyChart(),
            SizedBox(height: 20),
            _buildMovementTypesChart(),
            SizedBox(height: 20),
            _buildDetailedAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Utils.colorGnav, Utils.colorGnav.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reporte del Día',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat(
                      'EEEE, dd MMMM yyyy',
                      'es',
                    ).format(_selectedDate),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Icon(Icons.analytics, color: Colors.white, size: 32),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderStat(
                'Total Neto',
                _netTotal,
                _netTotal >= 0 ? Icons.trending_up : Icons.trending_down,
              ),
              _buildHeaderStat(
                'Movimientos',
                _movementsCount.toDouble(),
                Icons.receipt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, double value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
        Text(
          label == 'Movimientos'
              ? value.toInt().toString()
              : '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Ingresos',
            _totalIncome,
            Colors.green,
            Icons.add_circle,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Ventas',
            _totalSales,
            Colors.blue,
            Icons.shopping_cart,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Egresos',
            _totalOutcome,
            Colors.red,
            Icons.remove_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final total = _totalIncome + _totalSales + _totalOutcome;
    if (total == 0) return _buildEmptyChart('Sin datos de ingresos');

    return _buildChartContainer(
      'Distribución de Ingresos',
      SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              if (_totalIncome > 0)
                PieChartSectionData(
                  color: Colors.green,
                  value: _totalIncome,
                  title:
                      '${((_totalIncome / total) * 100).toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (_totalSales > 0)
                PieChartSectionData(
                  color: Colors.blue,
                  value: _totalSales,
                  title: '${((_totalSales / total) * 100).toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              if (_totalOutcome > 0)
                PieChartSectionData(
                  color: Colors.red,
                  value: _totalOutcome,
                  title:
                      '${((_totalOutcome / total) * 100).toStringAsFixed(1)}%',
                  radius: 80,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
      legend: [
        if (_totalIncome > 0)
          _buildLegendItem('Ingresos', Colors.green, _totalIncome),
        if (_totalSales > 0)
          _buildLegendItem('Ventas', Colors.blue, _totalSales),
        if (_totalOutcome > 0)
          _buildLegendItem('Egresos', Colors.red, _totalOutcome),
      ],
    );
  }

  Widget _buildHourlyChart() {
    if (_hourlyData.values.every((v) => v == 0)) {
      return _buildEmptyChart('Sin actividad por horas');
    }

    return _buildChartContainer(
      'Flujo de Efectivo por Hora',
      SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '\$${value.toInt()}',
                      style: TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 4,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}h',
                      style: TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: _hourlyData.entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList(),
                isCurved: true,
                color: Utils.colorBotones,
                barWidth: 3,
                belowBarData: BarAreaData(
                  show: true,
                  color: Utils.colorBotones.withValues(alpha: 0.1),
                ),
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovementTypesChart() {
    final movements = _dailyMovements;
    if (movements.isEmpty) return _buildEmptyChart('Sin movimientos');

    final typeCount = <String, int>{};
    for (var movement in movements) {
      typeCount[movement.type] = (typeCount[movement.type] ?? 0) + 1;
    }

    return _buildChartContainer(
      'Cantidad de Movimientos por Tipo',
      SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY:
                typeCount.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final types = typeCount.keys.toList();
                    if (value.toInt() < types.length) {
                      final type = types[value.toInt()];
                      switch (type) {
                        case 'income':
                          return Text(
                            'Ingresos',
                            style: TextStyle(fontSize: 10),
                          );
                        case 'expense':
                          return Text(
                            'Egresos',
                            style: TextStyle(fontSize: 10),
                          );
                        case 'sale':
                          return Text('Ventas', style: TextStyle(fontSize: 10));
                        case 'opening':
                          return Text(
                            'Apertura',
                            style: TextStyle(fontSize: 10),
                          );
                        case 'closing':
                          return Text('Cierre', style: TextStyle(fontSize: 10));
                        default:
                          return Text(type, style: TextStyle(fontSize: 10));
                      }
                    }
                    return Text('');
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: typeCount.entries.map((entry) {
              final index = typeCount.keys.toList().indexOf(entry.key);
              Color barColor;
              switch (entry.key) {
                case 'income':
                  barColor = Colors.green;
                  break;
                case 'expense':
                  barColor = Colors.red;
                  break;
                case 'sale':
                  barColor = Colors.blue;
                  break;
                case 'opening':
                  barColor = Colors.orange;
                  break;
                case 'closing':
                  barColor = Colors.purple;
                  break;
                default:
                  barColor = Colors.grey;
              }

              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: barColor,
                    width: 30,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis Detallado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Utils.colorGnav,
            ),
          ),
          SizedBox(height: 16),
          _buildAnalysisItem(
            'Promedio por movimiento',
            _movementsCount > 0
                ? (_totalIncome + _totalSales) / _movementsCount
                : 0.0,
          ),
          _buildAnalysisItem('Margen de ganancia', _netTotal),
          _buildAnalysisItem(
            'Eficiencia operativa',
            _movementsCount > 0 ? (_netTotal / _movementsCount) : 0.0,
          ),
          SizedBox(height: 12),
          _buildPerformanceIndicator(),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem(String label, double value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: value >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    String performance;
    Color color;
    IconData icon;

    if (_netTotal > 1000) {
      performance = 'Excelente';
      color = Colors.green;
      icon = Icons.trending_up;
    } else if (_netTotal > 500) {
      performance = 'Bueno';
      color = Colors.blue;
      icon = Icons.trending_up;
    } else if (_netTotal > 0) {
      performance = 'Regular';
      color = Colors.orange;
      icon = Icons.trending_flat;
    } else {
      performance = 'Necesita atención';
      color = Colors.red;
      icon = Icons.trending_down;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            'Rendimiento del día: $performance',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer(
    String title,
    Widget chart, {
    List<Widget>? legend,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Utils.colorGnav,
            ),
          ),
          SizedBox(height: 30),
          chart,
          if (legend != null) ...[
            SizedBox(height: 30),
            Wrap(spacing: 16, runSpacing: 8, children: legend),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Text(
          '$label: \$${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: Locale('es'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadDailyReport();
    }
  }
}
