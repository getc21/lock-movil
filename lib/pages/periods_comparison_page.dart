import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/reports_controller.dart';
import '../controllers/store_controller.dart';
import '../services/pdf_service.dart';
import '../utils/utils.dart';
import '../widgets/store_aware_app_bar.dart';

class PeriodsComparisonPage extends StatefulWidget {
  const PeriodsComparisonPage({super.key});

  @override
  State<PeriodsComparisonPage> createState() => _PeriodsComparisonPageState();
}

class _PeriodsComparisonPageState extends State<PeriodsComparisonPage> {
  late ReportsController reportsController;
  late StoreController storeController;
  
  String currentStartDate = '';
  String currentEndDate = '';
  String previousStartDate = '';
  String previousEndDate = '';

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

    // Configurar fechas por defecto (últimos 30 días para período actual, 60-30 días anteriores para período anterior)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    
    // Período actual (últimos 30 días)
    currentStartDate = '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';
    currentEndDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    // Período anterior (60-30 días atrás)
    previousStartDate = '${sixtyDaysAgo.year}-${sixtyDaysAgo.month.toString().padLeft(2, '0')}-${sixtyDaysAgo.day.toString().padLeft(2, '0')}';
    previousEndDate = '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    reportsController.loadPeriodsComparison(
      currentStartDate: currentStartDate,
      currentEndDate: currentEndDate,
      previousStartDate: previousStartDate,
      previousEndDate: previousEndDate,
    );
  }

  // Seleccionar período predefinido
  void _selectPredefinedPeriod(String period) {
    final now = DateTime.now();
    DateTime currentStart, currentEnd, previousStart, previousEnd;

    switch (period) {
      case 'thisMonth_lastMonth':
        // Este mes vs mes anterior
        currentStart = DateTime(now.year, now.month, 1);
        currentEnd = DateTime(now.year, now.month + 1, 0);
        previousStart = DateTime(now.year, now.month - 1, 1);
        previousEnd = DateTime(now.year, now.month, 0);
        break;

      case 'lastWeek_previousWeek':
        // Última semana vs semana anterior
        final daysFromMonday = now.weekday - 1;
        final lastMonday = now.subtract(Duration(days: daysFromMonday));
        currentStart = DateTime(lastMonday.year, lastMonday.month, lastMonday.day);
        currentEnd = currentStart.add(const Duration(days: 6));
        previousStart = currentStart.subtract(const Duration(days: 7));
        previousEnd = currentStart.subtract(const Duration(days: 1));
        break;

      case 'last30Days_previous30Days':
        // Últimos 30 días vs anteriores 30 días
        currentEnd = now;
        currentStart = now.subtract(const Duration(days: 30));
        previousEnd = currentStart.subtract(const Duration(days: 1));
        previousStart = previousEnd.subtract(const Duration(days: 30));
        break;

      case 'thisQuarter_lastQuarter':
        // Este trimestre vs trimestre anterior
        final currentQuarter = ((now.month - 1) ~/ 3) + 1;
        currentStart = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
        currentEnd = DateTime(now.year, currentQuarter * 3 + 1, 0);
        
        final previousQuarter = currentQuarter == 1 ? 4 : currentQuarter - 1;
        final previousYear = currentQuarter == 1 ? now.year - 1 : now.year;
        previousStart = DateTime(previousYear, (previousQuarter - 1) * 3 + 1, 1);
        previousEnd = DateTime(previousYear, previousQuarter * 3 + 1, 0);
        break;

      default:
        return;
    }

    setState(() {
      currentStartDate = _formatDate(currentStart);
      currentEndDate = _formatDate(currentEnd);
      previousStartDate = _formatDate(previousStart);
      previousEndDate = _formatDate(previousEnd);
    });

    _loadData();
  }

  // Seleccionar fecha individual
  Future<void> _selectDate(bool isCurrent, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null) {
      final formattedDate = _formatDate(picked);
      
      setState(() {
        if (isCurrent) {
          if (isStart) {
            currentStartDate = formattedDate;
          } else {
            currentEndDate = formattedDate;
          }
        } else {
          if (isStart) {
            previousStartDate = formattedDate;
          } else {
            previousEndDate = formattedDate;
          }
        }
      });
    }
  }

  // Formatear fecha para backend (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Formatear fecha para mostrar (DD/MM/YYYY)
  String _formatDisplayDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: StoreAwareAppBar(
        title: 'Comparación de Períodos',
        icon: Icons.compare_arrows,
        subtitle: 'Análisis comparativo de ventas',
      ),
      body: Column(
        children: [
          // Controles de períodos
          _buildPeriodControls(),
          
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
                      Text('Comparando períodos...'),
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

              final data = reportsController.periodsComparisonData;
              if (data.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.compare_arrows_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay datos para comparar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selecciona períodos con ventas',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return _buildComparisonContent(data);
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generatePDF,
        backgroundColor: Utils.colorBotones,
        tooltip: 'Generar PDF de comparación',
        child: const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }

  Future<void> _generatePDF() async {
    try {
      final data = reportsController.periodsComparisonData;
      if (data.isEmpty) {
        Utils.showInfoSnackbar('Información', 'No hay datos para generar PDF');
        return;
      }
      await PdfService.generateComparisonPdf(
        data: data,
        startDate: DateTime.parse(currentStartDate),
        endDate: DateTime.parse(currentEndDate),
      );
      Utils.showSuccessSnackbar('Éxito', 'PDF de comparación generado correctamente');
    } catch (e) {
      Utils.showErrorSnackbar('Error', 'Error al generar PDF: $e');
    }
  }

  Widget _buildPeriodControls() {
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
          Row(
            children: [
              Icon(Icons.date_range, color: Utils.colorBotones),
              const SizedBox(width: 8),
              const Text(
                'Períodos a Comparar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Botones de períodos predefinidos
              PopupMenuButton<String>(
                icon: const Icon(Icons.access_time),
                tooltip: 'Períodos predefinidos',
                onSelected: _selectPredefinedPeriod,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'thisMonth_lastMonth',
                    child: Text('Este mes vs Mes anterior'),
                  ),
                  const PopupMenuItem(
                    value: 'lastWeek_previousWeek',
                    child: Text('Última semana vs Anterior'),
                  ),
                  const PopupMenuItem(
                    value: 'last30Days_previous30Days',
                    child: Text('Últimos 30 días vs Anteriores 30'),
                  ),
                  const PopupMenuItem(
                    value: 'thisQuarter_lastQuarter',
                    child: Text('Este trimestre vs Anterior'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Período actual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.today, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Período Actual',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(true, true), // current start
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desde:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _formatDisplayDate(currentStartDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(true, false), // current end
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hasta:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _formatDisplayDate(currentEndDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Período anterior
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.grey[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Período Anterior',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(false, true), // previous start
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Desde:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _formatDisplayDate(previousStartDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(false, false), // previous end
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hasta:',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _formatDisplayDate(previousEndDate),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Botón Comparar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text(
                'Comparar Períodos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Utils.colorBotones,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonContent(Map<String, dynamic> data) {
    final comparison = data['comparison'] ?? {};
    final productComparisons = List<Map<String, dynamic>>.from(data['productComparisons'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Resumen de comparación
          _buildComparisonSummary(comparison),
          const SizedBox(height: 16),
          
          // Métricas principales
          _buildMainMetrics(comparison),
          const SizedBox(height: 16),
          
          // Comparación de productos
          if (productComparisons.isNotEmpty) ...[
            _buildProductComparisons(productComparisons),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildComparisonSummary(Map<String, dynamic> comparison) {
    final salesGrowth = _toDouble(comparison['salesGrowth']);

    final isPositiveGrowth = salesGrowth >= 0;
    final growthColor = isPositiveGrowth ? Colors.green : Colors.red;
    final growthIcon = isPositiveGrowth ? Icons.trending_up : Icons.trending_down;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            growthColor[600]!,
            growthColor[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: growthColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            growthIcon,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            isPositiveGrowth ? 'Crecimiento' : 'Decrecimiento',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${salesGrowth.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'en ventas totales',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMetrics(Map<String, dynamic> comparison) {
    final currentPeriod = comparison['currentPeriod'] ?? {};
    final previousPeriod = comparison['previousPeriod'] ?? {};
    
    final currentSales = _toDouble(currentPeriod['totalSales']);
    final previousSales = _toDouble(previousPeriod['totalSales']);
    final salesGrowth = _toDouble(comparison['salesGrowth']);
    
    final currentOrders = currentPeriod['totalOrders'] ?? 0;
    final previousOrders = previousPeriod['totalOrders'] ?? 0;
    final ordersGrowth = _toDouble(comparison['ordersGrowth']);
    
    final currentAvgOrder = _toDouble(currentPeriod['averageOrderValue']);
    final previousAvgOrder = _toDouble(previousPeriod['averageOrderValue']);
    final avgOrderGrowth = _toDouble(comparison['avgOrderValueGrowth']);

    return Column(
      children: [
        // Ventas totales
        _buildMetricCard(
          'Ventas Totales',
          currentSales,
          previousSales,
          salesGrowth,
          Icons.monetization_on,
          Colors.green,
          isCurrency: true,
        ),
        const SizedBox(height: 12),
        
        // Número de órdenes
        _buildMetricCard(
          'Número de Órdenes',
          currentOrders.toDouble(),
          previousOrders.toDouble(),
          ordersGrowth,
          Icons.shopping_cart,
          Colors.blue,
          isCurrency: false,
        ),
        const SizedBox(height: 12),
        
        // Valor promedio por orden
        _buildMetricCard(
          'Valor Promedio por Orden',
          currentAvgOrder,
          previousAvgOrder,
          avgOrderGrowth,
          Icons.receipt_long,
          Colors.purple,
          isCurrency: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    double currentValue,
    double previousValue,
    double growth,
    IconData icon,
    Color color,
    {required bool isCurrency}
  ) {
    final isPositive = growth >= 0;
    final growthColor = isPositive ? Colors.green : Colors.red;
    final growthIcon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    String formatValue(double value) {
      if (isCurrency) {
        return '\$${value.toStringAsFixed(2)}';
      } else {
        return value.toInt().toString();
      }
    }

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: growthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: growthColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(growthIcon, color: growthColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${growth.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: growthColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Período Actual',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatValue(currentValue),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Período Anterior',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatValue(previousValue),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
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

  Widget _buildProductComparisons(List<Map<String, dynamic>> productComparisons) {
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
                Icon(Icons.inventory_2, color: Utils.colorBotones),
                const SizedBox(width: 8),
                const Text(
                  'Comparación por Productos',
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
            itemCount: productComparisons.take(10).length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final product = productComparisons[index];
              return _buildProductComparisonItem(product);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductComparisonItem(Map<String, dynamic> product) {
    final productName = product['productName'] ?? 'Sin nombre';
    final currentSales = _toDouble(product['currentSales']);
    final previousSales = _toDouble(product['previousSales']);
    final growth = _toDouble(product['growth']);
    final currentQuantity = product['currentQuantity'] ?? 0;
    final previousQuantity = product['previousQuantity'] ?? 0;

    final isPositive = growth >= 0;
    final growthColor = isPositive ? Colors.green : Colors.red;
    final growthIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: growthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: growthColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(growthIcon, color: growthColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${growth.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: growthColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actual',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${currentSales.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Text(
                      '$currentQuantity unidades',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Anterior',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '\$${previousSales.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '$previousQuantity unidades',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
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

  // Helper function para convertir int/double de manera segura
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return 0.0;
  }
}
