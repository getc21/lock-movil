import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../providers/cash_register_provider.dart';
import 'auth_controller.dart';

class CashController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
  CashRegisterProvider get _cashProvider => CashRegisterProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _movements = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> _currentRegister = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get movements => _movements;
  Map<String, dynamic>? get currentRegister => _currentRegister.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  
  // Getters computados para la UI
  Map<String, dynamic>? get currentCashRegister => _currentRegister.value;
  List<Map<String, dynamic>> get todayMovements => _movements;
  
  bool get isCashRegisterOpen => _currentRegister.value != null && 
      _currentRegister.value!['status'] == 'open';
  
  bool get isCashRegisterClosed => _currentRegister.value == null || 
      _currentRegister.value!['status'] == 'closed';
  
  bool get canOpenCashRegister => !isCashRegisterOpen;
  bool get canCloseCashRegister => isCashRegisterOpen;
  
  double get totalCashInHand {
    if (_currentRegister.value == null) return 0.0;
    
    final opening = _currentRegister.value!['openingAmount'] ?? 0.0;
    final movements = _movements.fold<double>(0.0, (sum, mov) {
      final amount = (mov['amount'] ?? 0.0).toDouble();
      final type = mov['type'] ?? '';
      
      // Solo contar movimientos que no sean de apertura (ya está incluida en opening)
      if (type == 'income' || type == 'sale') return sum + amount;
      if (type == 'expense') return sum - amount;
      return sum;
    });
    
    return opening + movements;
  }
  
  double get totalSalesToday {
    return _movements
        .where((mov) => mov['type'] == 'sale')
        .fold(0.0, (sum, mov) => sum + ((mov['amount'] ?? 0.0).toDouble()));
  }
  
  double get totalIncomesToday {
    // Incluir solo income (entradas manuales) + monto de apertura
    // NO incluir sales (ventas) para evitar duplicación con totalSalesToday
    final incomeMovements = _movements
        .where((mov) => mov['type'] == 'income')
        .fold(0.0, (sum, mov) => sum + ((mov['amount'] ?? 0.0).toDouble()));
    
    // Agregar el monto de apertura
    final opening = _currentRegister.value?['openingAmount'] ?? 0.0;
    
    return opening + incomeMovements;
  }
  
  double get totalOutcomesToday {
    return _movements
        .where((mov) => mov['type'] == 'expense')
        .fold(0.0, (sum, mov) => sum + ((mov['amount'] ?? 0.0).toDouble()));
  }
  
  double get expectedAmount => totalCashInHand;
  
  // Método auxiliar para formatear moneda
  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);
    return formatter.format(amount);
  }

  // Crear caja registradora
  Future<bool> createCashRegister({
    required String storeId,
    required String name,
    required double initialBalance,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.createCashRegister(
        storeId: storeId,
        name: name,
        initialBalance: initialBalance,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Caja creada correctamente', snackPosition: SnackPosition.TOP);
        // Ya no necesitamos recargar una lista de cajas
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error creando caja', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Abrir caja
  Future<bool> openCashRegister({
    required String cashRegisterId,
    required double openingBalance,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.openCashRegister(
        cashRegisterId: cashRegisterId,
        openingBalance: openingBalance,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Caja abierta correctamente', snackPosition: SnackPosition.TOP);
        _currentRegister.value = result['data'];
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error abriendo caja', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Cerrar caja
  Future<bool> closeCashRegister({
    required String cashRegisterId,
    required double closingBalance,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.closeCashRegister(
        cashRegisterId: cashRegisterId,
        closingBalance: closingBalance,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Caja cerrada correctamente', snackPosition: SnackPosition.TOP);
        _currentRegister.value = null;
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error cerrando caja', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Cargar movimientos de caja de la tienda actual
  Future<void> loadCashMovements({
    String? startDate,
    String? endDate,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.getCashMovements(
        cashRegisterId: 'store-cash-register', // Dummy - se usa storeId internamente
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        _movements.value = List<Map<String, dynamic>>.from(result['data']);
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error cargando movimientos', snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  // Agregar movimiento de caja
  Future<bool> addCashMovement({
    required String cashRegisterId,
    required String type,
    required double amount,
    required String description,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _cashProvider.addCashMovement(
        cashRegisterId: cashRegisterId,
        type: type,
        amount: amount,
        description: description,
      );

      if (result['success']) {
        Get.snackbar('Éxito', 'Movimiento registrado correctamente', snackPosition: SnackPosition.TOP);
        await loadCashMovements();
        return true;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error registrando movimiento', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _errorMessage.value = '';
  }
  
  // Inicializar (verificar estado de caja actual)
  Future<void> initialize() async {
    await checkCurrentCashRegisterStatus();
  }
  
  // Refrescar datos
  @override
  Future<void> refresh() async {
    await checkCurrentCashRegisterStatus();
  }

  // Refrescar datos para la tienda específica
  Future<void> refreshForStore() async {
    await checkCurrentCashRegisterStatus();
  }

  // Verificar estado de la caja actual de la tienda
  Future<void> checkCurrentCashRegisterStatus() async {
    try {
      final result = await _cashProvider.getCurrentCashRegisterStatus();
      
      
      if (result['success'] && result['data'] != null) {
        _currentRegister.value = result['data'];

        await loadCashMovements(); // Cargar movimientos si hay caja activa
      } else {
        _currentRegister.value = null;
      }
    } catch (e) {
      _currentRegister.value = null;
    }
  }
  
  // Cargar movimientos por fecha
  Future<void> loadMovementsByDate(DateTime date) async {
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));
    
    // Cargar movimientos independientemente del estado de la caja para reportes
    await loadCashMovements(
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
    );
  }
  
  // Agregar ingreso de efectivo
  Future<bool> addCashIncome(double amount, String description) async {
    if (_currentRegister.value == null) {
      Get.snackbar('Error', 'No hay caja abierta', snackPosition: SnackPosition.TOP);
      return false;
    }
    
    return await addCashMovement(
      cashRegisterId: _currentRegister.value!['_id'] ?? _currentRegister.value!['id'],
      type: 'income',
      amount: amount,
      description: description,
    );
  }
  
  // Agregar egreso de efectivo
  Future<bool> addCashOutcome(double amount, String description) async {
    if (_currentRegister.value == null) {
      Get.snackbar('Error', 'No hay caja abierta', snackPosition: SnackPosition.TOP);
      return false;
    }
    
    return await addCashMovement(
      cashRegisterId: _currentRegister.value!['_id'] ?? _currentRegister.value!['id'],
      type: 'expense',
      amount: amount,
      description: description,
    );
  }
  
  // Abrir caja de la tienda actual
  Future<bool> openCashRegisterSimple(double openingBalance) async {
    _isLoading.value = true;
    
    try {      
      // Para una tienda, no necesitamos cashRegisterId - el backend lo maneja automáticamente por storeId
      final result = await _cashProvider.openCashRegister(
        cashRegisterId: 'store-cash-register', // Un valor dummy ya que se usa storeId internamente
        openingBalance: openingBalance,
      );

      if (result['success']) {
        
        // El backend devuelve { data: { cashRegister: {...} } }
        final cashRegisterData = result['data']['cashRegister'] ?? result['data'];
        _currentRegister.value = cashRegisterData;
        
        Get.snackbar('Éxito', 'Caja abierta correctamente', snackPosition: SnackPosition.TOP);
        
        // Recargar movimientos después de abrir
        await loadCashMovements();
        return true;
      } else if (result['isAlreadyOpen'] == true) {
        _showCashAlreadyOpenDialog();
        return false;
      } else {
        Get.snackbar('Error', result['message'] ?? 'Error abriendo caja', snackPosition: SnackPosition.TOP);
        return false;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error de conexión: $e', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<bool> closeCashRegisterSimple(double closingBalance) async {
    if (_currentRegister.value == null) {
      Get.snackbar('Error', 'No hay caja abierta', snackPosition: SnackPosition.TOP);
      return false;
    }
    
    final cashRegisterId = _currentRegister.value!['_id'] ?? _currentRegister.value!['id'];
    
    return await closeCashRegister(
      cashRegisterId: cashRegisterId,
      closingBalance: closingBalance,
    );
  }

  // Mostrar diálogo cuando ya hay una caja abierta
  void _showCashAlreadyOpenDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Caja Ya Abierta'),
          ],
        ),
        content: const Text(
          'Ya tienes una caja abierta en esta tienda.\n\n'
          '¿Qué deseas hacer?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Cerrar diálogo
              // Cargar información de la caja actual
              _loadCurrentCashRegisterInfo();
            },
            child: const Text('Ver Caja Actual'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Cerrar diálogo
              _showCloseCashDialog();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cerrar Caja'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Solo cerrar diálogo
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  // Cargar información de la caja actual
  Future<void> _loadCurrentCashRegisterInfo() async {
    try {
      final result = await _cashProvider.getCurrentCashRegisterStatus();
      if (result['success']) {
        _currentRegister.value = result['data'];
        Get.snackbar(
          'Información',
          'Caja cargada correctamente',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Error',
          'No se pudo cargar la información de la caja',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error cargando información de caja: $e',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  // Mostrar diálogo para cerrar caja
  void _showCloseCashDialog() {
    final TextEditingController balanceController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Cerrar Caja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa el monto de cierre:'),
            const SizedBox(height: 16),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto de cierre',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final balance = double.tryParse(balanceController.text);
              if (balance != null) {
                Get.back();
                await closeCashRegisterSimple(balance);
              } else {
                Get.snackbar(
                  'Error',
                  'Ingresa un monto válido',
                  snackPosition: SnackPosition.TOP,
                );
              }
            },
            child: const Text('Cerrar Caja'),
          ),
        ],
      ),
    );
  }
}
