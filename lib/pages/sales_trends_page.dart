import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/reports_controller.dart';
import '../controllers/store_controller.dart';
import '../services/pdf_service.dart';
import '../utils/utils.dart';
import '../widgets/store_aware_app_bar.dart';

class SalesTrendsPage extends StatefulWidget {
  const SalesTrendsPage({super.key});

  @override
  State<SalesTrendsPage> createState() => _SalesTrendsPageState();
}

class _SalesTrendsPageState extends State<SalesTrendsPage> {
  late ReportsController reportsController;
  late StoreController storeController;
  
  String startDate = '';
  String endDate = '';
  String period = 'day'; // day, week, month

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores
    try {
      reportsController = Get.find<ReportsController>();
    } catch (e) {
      reportsController = Get.put(ReportsController());
    }
    
    try {
      storeController = Get.find<StoreController>();
    } catch (e) {
      storeController = Get.put(StoreController());
    }

    // Configurar fechas por defecto (últimos 30 días)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    startDate = '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';
    endDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    reportsController.loadSalesTrendsAnalysis(
      startDate: startDate,
      endDate: endDate,
      period: period,
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(startDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar fecha de inicio',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      setState(() {
        startDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
      _loadData();
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(endDate),
      firstDate: DateTime.parse(startDate),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar fecha de fin',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      setState(() {
        endDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: StoreAwareAppBar(
        title: 'Tendencias de Ventas',
        icon: Icons.trending_up,
        subtitle: 'Análisis temporal de ventas',
        showHelpButton: true,
        helpContent: 'Analiza cómo evolucionan tus ventas a lo largo del tiempo para identificar patrones y tendencias.',
      ),
      body: Column(
        children: [
          // Controles de filtros
          _buildFilterControls(),
          
          // Contenido principal
          Expanded(
            child: Obx(() {
              if (reportsController.isLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analizando tendencias...'),
                    ],
                  ),
                );
              }

              if (reportsController.errorMessage.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar datos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reportsController.errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final data = reportsController.salesTrendsData;
              if (data.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay datos de tendencias',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selecciona un período con ventas',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return _buildTrendsContent(data);
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generatePDF,
        backgroundColor: Utils.colorBotones,
        tooltip: 'Generar PDF de tendencias',
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }

  Future<void> _generatePDF() async {
    try {
      final data = reportsController.salesTrendsData;
      if (data.isEmpty) {
        Utils.showInfoSnackbar('Información', 'No hay datos para generar PDF');
        return;
      }
      await PdfService.generateSalesTrendsPdf(
        data: data,
        startDate: DateTime.parse(startDate),
        endDate: DateTime.parse(endDate),
        period: period,
      );
      Utils.showSuccessSnackbar('Éxito', 'PDF de tendencias generado correctamente');
    } catch (e) {
      Utils.showErrorSnackbar('Error', 'Error al generar PDF: $e');
    }
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildFilterControls() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros de Análisis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          // Selector de período
          Row(
            children: [
              const Text(
                'Agrupación: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: period,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Por día')),
                    DropdownMenuItem(value: 'week', child: Text('Por semana')),
                    DropdownMenuItem(value: 'month', child: Text('Por mes')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        period = value;
                      });
                      _loadData();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Selector de fechas personalizado
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha Inicio',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectStartDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, 
                                 color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _formatDateString(startDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha Final',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectEndDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, 
                                 color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _formatDateString(endDate),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Botón centrado para analizar
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.analytics_outlined, size: 20),
              label: const Text('Analizar Tendencias'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Utils.colorBotones,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsContent(Map<String, dynamic> data) {
    final summary = data['summary'] ?? {};
    final trends = List<Map<String, dynamic>>.from(data['trends'] ?? []);
    final topProducts = List<Map<String, dynamic>>.from(data['topProducts'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Resumen general
          _buildSummaryCard(summary),
          const SizedBox(height: 16),
          
          // Gráfico de tendencias (simplificado)
          _buildTrendsChart(trends),
          const SizedBox(height: 16),
          
          // Productos destacados
          _buildTopProductsCard(topProducts),
          const SizedBox(height: 16),
          
          // Lista de períodos
          _buildPeriodsList(trends),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    final totalSales = _toDouble(summary['totalSales']);
    final averageDaily = _toDouble(summary['averageDaily']);
    final growthRate = _toDouble(summary['growthRate']);
    final periodCount = summary['periodCount'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.blue[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Resumen de Tendencias',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildTrendMetric(
                  'Ventas Totales',
                  '\$${totalSales.toStringAsFixed(2)}',
                  Icons.monetization_on,
                ),
              ),
              Expanded(
                child: _buildTrendMetric(
                  'Promedio ${_getPeriodLabel()}',
                  '\$${averageDaily.toStringAsFixed(2)}',
                  Icons.bar_chart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTrendMetric(
                  'Crecimiento',
                  '${growthRate.toStringAsFixed(1)}%',
                  growthRate >= 0 ? Icons.trending_up : Icons.trending_down,
                ),
              ),
              Expanded(
                child: _buildTrendMetric(
                  'Períodos',
                  '$periodCount',
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (period) {
      case 'day':
        return 'Diario';
      case 'week':
        return 'Semanal';
      case 'month':
        return 'Mensual';
      default:
        return 'Diario';
    }
  }

  Widget _buildTrendMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();

    // Encontrar valores máximo y mínimo para escalar
    double maxValue = 0;
    for (var trend in trends) {
      final sales = _toDouble(trend['totalSales']);
      if (sales > maxValue) maxValue = sales;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.show_chart, color: Utils.colorBotones),
                const SizedBox(width: 8),
                const Text(
                  'Gráfico de Tendencias',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSimpleChart(trends, maxValue),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChart(List<Map<String, dynamic>> trends, double maxValue) {
    // Calcular altura dinámica: cada elemento necesita ~32px (24px de altura + 8px de padding)
    final itemHeight = 32.0;
    final chartHeight = trends.length * itemHeight;
    
    return SizedBox(
      height: chartHeight,
      child: Column(
        children: trends.map((trend) {
          final sales = _toDouble(trend['totalSales']);
          final width = maxValue > 0 ? (sales / maxValue) * 200 : 0.0;
          final date = trend['date'] ?? trend['period'] ?? '';
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                // Etiqueta de fecha a la izquierda
                SizedBox(
                  width: 60,
                  child: Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                // Barra horizontal
                Expanded(
                  child: Container(
                    height: 24,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: width,
                      height: 15,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Utils.colorBotones.withValues(alpha: 0.8),
                            Utils.colorBotones.withValues(alpha: 0.6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Valor de ventas a la derecha
                SizedBox(
                  width: 70,
                  child: Text(
                    '\$${sales.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
      switch (period) {
        case 'day':
          return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
        case 'week':
          return 'S${_getWeekNumber(dateTime)}';
        case 'month':
          return '${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year.toString().substring(2)}';
        default:
          return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return date;
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }

  Widget _buildTopProductsCard(List<Map<String, dynamic>> topProducts) {
    if (topProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Productos Más Vendidos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topProducts.take(5).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = topProducts[index];
              return _buildTopProductItem(product, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductItem(Map<String, dynamic> product, int rank) {
    final totalSales = _toDouble(product['totalSales']);
    final totalQuantity = product['totalQuantity'] ?? 0;

    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = Colors.amber[700]!;
        break;
      case 2:
        rankColor = Colors.grey[600]!;
        break;
      case 3:
        rankColor = Colors.brown[400]!;
        break;
      default:
        rankColor = Colors.blue[600]!;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['productName'] ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalQuantity unidades vendidas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${totalSales.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodsList(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.timeline, color: Utils.colorBotones),
                const SizedBox(width: 8),
                const Text(
                  'Detalle por Período',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trends.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final trend = trends[index];
              return _buildPeriodItem(trend);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodItem(Map<String, dynamic> trend) {
    final date = trend['date'] ?? '';
    final totalSales = _toDouble(trend['totalSales']);
    final orderCount = trend['orderCount'] ?? 0;
    final avgOrderValue = _toDouble(trend['avgOrderValue']);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateFull(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$orderCount órdenes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${totalSales.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              Text(
                'Promedio: \$${avgOrderValue.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateFull(String date) {
    try {
      final dateTime = DateTime.parse(date);
      switch (period) {
        case 'day':
          return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        case 'week':
          return 'Semana ${_getWeekNumber(dateTime)} de ${dateTime.year}';
        case 'month':
          final months = [
            '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
            'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
          ];
          return '${months[dateTime.month]} ${dateTime.year}';
        default:
          return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return date;
    }
  }

  // Helper function para convertir int/double de manera segura
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 0.0;
  }
}
