import 'package:bellezapp/controllers/cash_controller.dart';
import 'package:bellezapp/models/cash_movement.dart';
import 'package:bellezapp/pages/daily_cash_report_page.dart';
import 'package:bellezapp/pages/cash_movements_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/utils/time_utils.dart';
import 'package:bellezapp/widgets/store_aware_app_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CashRegisterPage extends StatefulWidget {
  const CashRegisterPage({super.key});

  @override
  CashRegisterPageState createState() => CashRegisterPageState();
}

class CashRegisterPageState extends State<CashRegisterPage> {
  late CashController cashController;
  final TextEditingController _openAmountController = TextEditingController();
  final TextEditingController _closeAmountController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();
  final TextEditingController _outcomeAmountController = TextEditingController();
  
  // Variable para controlar di�logos abiertos
  bool _isDialogOpen = false;
  DateTime? _lastDialogOpen;

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador de forma segura
    try {
      cashController = Get.find<CashController>();
    } catch (e) {
      // Si no existe, intentar crearlo
      cashController = Get.put(CashController(), permanent: true);
    }
    
    // Cargar datos cuando se abre la p�gina
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await cashController.initialize();
    });
  }

  @override
  void dispose() {
    _openAmountController.dispose();
    _closeAmountController.dispose();
    _incomeAmountController.dispose();
    _outcomeAmountController.dispose();
    super.dispose();
  }

  // M�todo helper para verificar si se puede abrir un di�logo
  bool _canOpenDialog() {
    final now = DateTime.now();
    return !_isDialogOpen && 
           (_lastDialogOpen == null || now.difference(_lastDialogOpen!).inMilliseconds >= 500);
  }

  // M�todo helper para marcar di�logo como abierto
  void _markDialogOpen() {
    _isDialogOpen = true;
    _lastDialogOpen = DateTime.now();
  }

  // M�todo helper para marcar di�logo como cerrado
  void _markDialogClosed() {
    _isDialogOpen = false;
  }

  // M�todo helper para obtener dinero disponible de forma segura
  double _getSafeAvailableCash() {
    try {
      if (!mounted || !cashController.isCashRegisterOpen) return 0.0;
      return cashController.totalCashInHand;
    } catch (e) {
      return 0.0;
    }
  }

  // M�todo helper para formatear moneda de forma segura
  String _safeFormatCurrency(double amount) {
    try {
      if (!mounted) return '\$${amount.toStringAsFixed(2)}';
      return cashController.formatCurrency(amount);
    } catch (e) {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }

  // M�todo helper para obtener monto esperado de forma segura
  double _getSafeExpectedAmount() {
    try {
      if (!mounted || !cashController.isCashRegisterOpen) return 0.0;
      return cashController.expectedAmount;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: StoreAwareAppBar(
        title: 'Sistema de Caja',
        icon: Icons.account_balance_wallet_outlined,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => cashController.refresh(),
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Get.to(() => DailyCashReportPage());
            },
            tooltip: 'Dashboard y Reportes',
          ),
        ],
      ),
      body: Obx(() {
        if (cashController.isLoading) {
          return Center(child: Utils.loadingCustom());
        }

        return RefreshIndicator(
          onRefresh: () => cashController.refresh(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado de la caja
                _buildCashStatusCard(),
                SizedBox(height: 16),
                
                // Resumen del d�a
                _buildDailySummaryCard(),
                SizedBox(height: 16),
                
                // Acciones principales
                _buildMainActionsCard(),
                SizedBox(height: 16),
                
                // Movimientos recientes
                _buildRecentMovementsCard(),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Card del estado de la caja
  Widget _buildCashStatusCard() {
    return Card(
      elevation: 4,
      color: Utils.colorFondoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Icono y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cashController.isCashRegisterOpen 
                        ? Colors.green 
                        : cashController.isCashRegisterClosed 
                            ? Colors.orange 
                            : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cashController.isCashRegisterOpen 
                        ? Icons.lock_open 
                        : Icons.lock,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de la Caja',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Utils.colorTexto,
                      ),
                    ),
                    Text(
                      cashController.isCashRegisterOpen 
                          ? 'ABIERTA' 
                          : cashController.isCashRegisterClosed 
                              ? 'CERRADA' 
                              : 'SIN ABRIR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cashController.isCashRegisterOpen 
                            ? Colors.green 
                            : cashController.isCashRegisterClosed 
                                ? Colors.orange 
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Informaci�n adicional si la caja est� abierta
            if (cashController.isCashRegisterOpen) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hora de apertura',
                        style: TextStyle(
                          fontSize: 14,
                          color: Utils.colorTexto.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        _formatOpeningTime(cashController.currentCashRegister) ?? 'N/A',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Utils.colorTexto,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Monto inicial',
                        style: TextStyle(
                          fontSize: 14,
                          color: Utils.colorTexto.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        _formatOpeningAmount(cashController.currentCashRegister) ?? '\$0.00',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Utils.colorTexto,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card del resumen del d�a
  Widget _buildDailySummaryCard() {
    // Calcular totales desde apertura de caja
    double totalSalesFromOpening = 0;
    double totalIncomeFromOpening = 0;
    double totalOutcomeFromOpening = 0;
    double totalCashFromOpening = 0;
    double expectedAmountFromOpening = 0;
    
    if (cashController.isCashRegisterOpen && cashController.currentCashRegister != null) {
      final openingTime = cashController.currentCashRegister!['openingTime'] ?? 
                         cashController.currentCashRegister!['createdAt'];
      final openingAmount = (cashController.currentCashRegister!['openingAmount'] ?? 0.0).toDouble();
      
      if (openingTime != null) {
        try {
          final openingDateTime = DateTime.parse(openingTime.toString());
          
          // Filtrar movimientos posteriores a apertura
          for (var movement in cashController.todayMovements) {
            try {
              final movementDate = DateTime.parse(
                movement['createdAt']?.toString() ?? 
                movement['date']?.toString() ?? 
                DateTime.now().toIso8601String()
              );
              
              if (movementDate.isAfter(openingDateTime)) {
                final amount = (movement['amount'] ?? 0.0).toDouble();
                final type = movement['type'] ?? '';
                
                if (type == 'sale') {
                  totalSalesFromOpening += amount;
                } else if (type == 'income') {
                  totalIncomeFromOpening += amount;
                } else if (type == 'expense') {
                  totalOutcomeFromOpening += amount;
                }
              }
            } catch (e) {
              continue;
            }
          }
          
          // Calcular dinero en caja desde apertura
          totalCashFromOpening = openingAmount + totalSalesFromOpening + totalIncomeFromOpening - totalOutcomeFromOpening;
          expectedAmountFromOpening = openingAmount + totalSalesFromOpening + totalIncomeFromOpening - totalOutcomeFromOpening;
          
        } catch (e) {
          // Si hay error, usar totales del día
          totalSalesFromOpening = cashController.totalSalesToday;
          totalIncomeFromOpening = cashController.totalIncomesToday;
          totalOutcomeFromOpening = cashController.totalOutcomesToday;
          totalCashFromOpening = cashController.totalCashInHand;
          expectedAmountFromOpening = cashController.expectedAmount;
        }
      }
    } else {
      // Si caja no está abierta, usar totales del día
      totalSalesFromOpening = cashController.totalSalesToday;
      totalIncomeFromOpening = cashController.totalIncomesToday;
      totalOutcomeFromOpening = cashController.totalOutcomesToday;
      totalCashFromOpening = cashController.totalCashInHand;
      expectedAmountFromOpening = cashController.expectedAmount;
    }
    
    return Card(
      elevation: 4,
      color: Utils.colorFondoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cashController.isCashRegisterOpen ? 'Resumen desde Apertura' : 'Resumen del Día',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Utils.colorTexto,
              ),
            ),
            SizedBox(height: 16),
            // Grid de métricas
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
                              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  'Dinero en Caja',
                  cashController.formatCurrency(totalCashFromOpening),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Ventas Efectivo',
                  cashController.formatCurrency(totalSalesFromOpening),
                  Icons.point_of_sale,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Entradas',
                  cashController.formatCurrency(totalIncomeFromOpening),
                  Icons.trending_up,
                  Colors.teal,
                ),
                _buildMetricCard(
                  'Salidas',
                  cashController.formatCurrency(totalOutcomeFromOpening),
                  Icons.trending_down,
                  Colors.red,
                ),
              ],
            ),
            
            // Monto esperado
            if (cashController.isCashRegisterOpen) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Utils.colorBotones.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Utils.colorBotones.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monto Esperado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Utils.colorTexto,
                      ),
                    ),
                    Text(
                      cashController.formatCurrency(expectedAmountFromOpening),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card de m�trica individual
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12), // Reducir padding
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // A�adir para minimizar espacio
        children: [
          Icon(icon, color: color, size: 18), // Reducir m�s el tama�o del icono
          SizedBox(height: 4), // Reducir m�s el espaciado
          Flexible( // Usar Flexible para evitar overflow
            child: Text(
              title,
              style: TextStyle(
                fontSize: 9, // Reducir m�s el tama�o de fuente
                color: Utils.colorTexto.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2, // Permitir 2 l�neas
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 1), // Reducir m�s el espaciado
          Flexible( // Usar Flexible para evitar overflow
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11, // Reducir m�s el tama�o de fuente
                fontWeight: FontWeight.bold,
                color: Utils.colorTexto,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Card de acciones principales
  Widget _buildMainActionsCard() {
    return Card(
      elevation: 4,
      color: Utils.colorFondoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Utils.colorTexto,
              ),
            ),
            SizedBox(height: 16),
            
            // Botones de acci�n - Reactivos a cambios del controlador
            Obx(() {
              if (cashController.canOpenCashRegister) {
                return _buildActionButton(
                  'Abrir Caja',
                  'Iniciar jornada con monto inicial',
                  Icons.lock_open,
                  Colors.green,
                  () => _showOpenCashDialog(),
                );
              } else if (cashController.canCloseCashRegister) {
                return Column(
                  children: [
                    _buildActionButton(
                      'Cerrar Caja',
                      'Realizar arqueo y cerrar jornada',
                      Icons.lock,
                      Colors.orange,
                      () => _showCloseCashDialog(),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSecondaryActionButton(
                            'Entrada',
                            Icons.add_circle,
                            Colors.teal,
                            () => _showAddIncomeDialog(),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildSecondaryActionButton(
                            'Salida',
                            Icons.remove_circle,
                            Colors.red,
                            () => _showAddOutcomeDialog(),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildActionButton(
                      'Ver Movimientos',
                      'Gestionar entradas y salidas',
                      Icons.receipt_long,
                      Utils.colorBotones,
                      () {
                        Get.to(() => CashMovementsPage());
                      },
                    ),
                  ],
                );
              } else {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Caja cerrada para hoy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'La jornada ya fue completada',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  // Bot�n de acci�n principal
  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Utils.colorTexto,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Utils.colorTexto.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // Bot�n de acci�n secundario
  Widget _buildSecondaryActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Utils.colorTexto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card de movimientos recientes (desde apertura de caja)
  Widget _buildRecentMovementsCard() {
    // Obtener movimientos desde la apertura de caja
    List<Map<String, dynamic>> recentMovements = [];
    
    if (cashController.isCashRegisterOpen && cashController.currentCashRegister != null) {
      // Obtener hora de apertura
      final openingTime = cashController.currentCashRegister!['openingTime'] ?? 
                         cashController.currentCashRegister!['createdAt'];
      
      if (openingTime != null) {
        try {
          final openingDateTime = DateTime.parse(openingTime.toString());
          
          // Filtrar movimientos posteriores a apertura
          recentMovements = cashController.todayMovements
              .where((movement) {
                try {
                  final movementDate = DateTime.parse(
                    movement['createdAt']?.toString() ?? 
                    movement['date']?.toString() ?? 
                    DateTime.now().toIso8601String()
                  );
                  return movementDate.isAfter(openingDateTime);
                } catch (e) {
                  return false;
                }
              })
              .toList();
        } catch (e) {
          // Si hay error parsing, mostrar últimos 5
          recentMovements = cashController.todayMovements.take(5).toList();
        }
      }
    } else {
      // Si caja no está abierta, mostrar últimos 5
      recentMovements = cashController.todayMovements.take(5).toList();
    }
    
    return Card(
      elevation: 4,
      color: Utils.colorFondoCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Movimientos Recientes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorTexto,
                  ),
                ),
                if (cashController.todayMovements.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Get.to(() => CashMovementsPage());
                    },
                    child: Text('Ver todos'),
                  ),
              ],
            ),
            SizedBox(height: 16),
            
            if (recentMovements.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, color: Colors.grey, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Sin movimientos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: recentMovements.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final movement = recentMovements[index];
                  return _buildMovementItem(movement);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Item de movimiento
  Widget _buildMovementItem(dynamic movement) {
    Color color;
    IconData icon;
    
    // Si movement es un Map, convertirlo a CashMovement para usar sus m�todos
    CashMovement movementObj;
    if (movement is Map<String, dynamic>) {
      movementObj = CashMovement.fromMap(movement);
    } else if (movement is CashMovement) {
      movementObj = movement;
    } else {
      // Fallback para casos inesperados
      return const SizedBox.shrink();
    }
    
    switch (movementObj.type) {
      case 'opening':
      case 'apertura':
        color = Colors.blue;
        icon = Icons.lock_open;
        break;
      case 'closing':
      case 'cierre':
        color = Colors.orange;
        icon = Icons.lock;
        break;
      case 'sale':
      case 'venta':
        color = Colors.green;
        icon = Icons.point_of_sale;
        break;
      case 'income':
      case 'entrada':
        color = Colors.teal;
        icon = Icons.trending_up;
        break;
      case 'expense':
      case 'salida':
        color = Colors.red;
        icon = Icons.trending_down;
        break;
      case 'adjustment':
        color = Colors.purple;
        icon = Icons.tune;
        break;
      default:
        color = Colors.grey;
        icon = Icons.receipt;
    }

    final time = movementObj.createdAt;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movementObj.typeDisplayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Utils.colorTexto,
                  ),
                ),
                Text(
                  movementObj.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Utils.colorTexto.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                movementObj.formattedAmount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: movementObj.isOutcome ? Colors.red : Colors.green,
                ),
              ),
              Text(
                Utils.formatTime12Hour(time),
                style: TextStyle(
                  fontSize: 12,
                  color: Utils.colorTexto.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Di�logo para abrir caja
  void _showOpenCashDialog() {
    _openAmountController.clear();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('Abrir Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ingrese el monto inicial en efectivo:'),
            SizedBox(height: 16),
            TextFormField(
              controller: _openAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto inicial',
                prefixText: '\Bs ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_openAmountController.text);
              if (amount != null && amount >= 0) {
                Get.back();
                cashController.openCashRegisterSimple(amount);
              } else {
                Get.snackbar('Error', 'Ingrese un monto v�lido');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Abrir Caja'),
          ),
        ],
      ),
    );
  }

  // Di�logo para cerrar caja
  void _showCloseCashDialog() {
    // Verificar que haya una caja abierta
    if (!cashController.isCashRegisterOpen) {
      Get.snackbar('Error', 'No hay caja abierta para cerrar.');
      return;
    }
    
    _closeAmountController.clear();
    
    // Capturar el valor antes de mostrar el di�logo para evitar problemas de contexto
    final expectedAmount = _getSafeExpectedAmount();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('Cerrar Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Monto esperado: ${_safeFormatCurrency(expectedAmount)}'),
            SizedBox(height: 16),
            Text('Ingrese el monto real contado:'),
            SizedBox(height: 16),
            TextFormField(
              controller: _closeAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto real',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_closeAmountController.text);
              if (amount != null && amount >= 0) {
                Get.back();
                cashController.closeCashRegisterSimple(amount);
              } else {
                Get.snackbar('Error', 'Ingrese un monto v�lido');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Cerrar Caja'),
          ),
        ],
      ),
    );
  }

  // Di�logo para entrada de dinero
  void _showAddIncomeDialog() {
    // Prevenir m�ltiples di�logos
    if (_isDialogOpen) return;
    
    // Verificar que haya una caja abierta
    if (!cashController.isCashRegisterOpen) {
      Get.snackbar('Error', 'No hay caja abierta. Abra una caja primero.');
      return;
    }
    
    _isDialogOpen = true;
    _incomeAmountController.clear();
    final descriptionController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        backgroundColor: Utils.colorFondoCards,
        title: Text('Entrada de Dinero'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _incomeAmountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripci�n',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _isDialogOpen = false;
              descriptionController.dispose();
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(_incomeAmountController.text);
              final description = descriptionController.text.trim();
              
              if (amount != null && amount > 0 && description.isNotEmpty) {
                Get.back();
                _isDialogOpen = false;
                cashController.addCashIncome(amount, description);
                descriptionController.dispose();
              } else {
                Get.snackbar('Error', 'Complete todos los campos correctamente');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // Di�logo para salida de dinero
  void _showAddOutcomeDialog() {
    // Prevenir m�ltiples di�logos y clicks r�pidos
    if (!_canOpenDialog()) return;
    
    try {
      // Verificar que haya una caja abierta
      if (!cashController.isCashRegisterOpen) {
        Get.snackbar('Error', 'No hay caja abierta. Abra una caja primero.');
        return;
      }
      
      // Verificar que el contexto est� montado
      if (!mounted) return;
      
      _markDialogOpen();
      
      // Capturar valores antes de mostrar el di�logo
      final availableCash = _getSafeAvailableCash();
      
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => _OutcomeDialog(
          availableCash: '\$${availableCash.toStringAsFixed(2)}',
          onConfirm: (String type, double amount, String description) {
            _markDialogClosed();
            cashController.addCashOutcome(amount, description);
          },
        ),
      );
    } catch (e) {
      _markDialogClosed();
      Get.snackbar('Error', 'Error al abrir el di�logo. Intente nuevamente.');
    }
  }

  // M�todos de formateo para datos de caja
  String? _formatOpeningTime(Map<String, dynamic>? cashRegister) {
    if (cashRegister == null) return null;
    
    try {
      // Intentar obtener la hora de apertura
      final openingTime = cashRegister['openingTime'] ?? cashRegister['createdAt'];
      if (openingTime != null) {
        // Convertir a DateTime y aplicar zona horaria de Bolivia
        final DateTime utcDateTime = DateTime.parse(openingTime.toString());
        final DateTime boliviaTime = TimeUtils.toBoliviaTime(utcDateTime);
        
        // Convertir a formato de 12 horas
        int hour = boliviaTime.hour;
        String period = hour >= 12 ? 'PM' : 'AM';
        
        // Convertir hora de 24h a 12h
        if (hour == 0) {
          hour = 12; // Medianoche
        } else if (hour > 12) {
          hour = hour - 12; // Tarde
        }
        
        return '${hour.toString()}:${boliviaTime.minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      if (kDebugMode) {

      }
      // Error silencioso - continúa con valor por defecto
    }
    
    return null;
  }

  String? _formatOpeningAmount(Map<String, dynamic>? cashRegister) {
    if (cashRegister == null) return null;
    
    try {
      final openingAmount = cashRegister['openingAmount'];
      if (openingAmount != null) {
        final double amount = openingAmount is double 
            ? openingAmount 
            : double.parse(openingAmount.toString());
        return '\$${amount.toStringAsFixed(2)}';
      }
    } catch (e) {
      if (kDebugMode) {

      }
      // Error silencioso - continúa con valor por defecto
    }
    
    return null;
  }
}

class _OutcomeDialog extends StatefulWidget {
  final Function(String type, double amount, String description) onConfirm;
  final String availableCash;
  
  const _OutcomeDialog({
    required this.onConfirm,
    required this.availableCash,
  });
  
  @override
  State<_OutcomeDialog> createState() => _OutcomeDialogState();
}

class _OutcomeDialogState extends State<_OutcomeDialog> {
  late TextEditingController amountController;
  late TextEditingController descriptionController;
  bool _disposed = false;
  
  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    descriptionController = TextEditingController();
  }
  
  @override
  void dispose() {
    _disposed = true;
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Salida de Dinero'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Dinero disponible: ${widget.availableCash}'),
          const SizedBox(height: 20),
          TextField(
            controller: amountController,
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripci�n',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_disposed || !mounted) return;
            
            final amount = double.tryParse(amountController.text);
            if (amount != null && amount > 0 && descriptionController.text.isNotEmpty) {
              widget.onConfirm('expense', amount, descriptionController.text);
              if (mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
