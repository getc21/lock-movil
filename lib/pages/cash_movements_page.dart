import 'package:bellezapp/controllers/cash_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/utils/time_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CashMovementsPage extends StatefulWidget {
  const CashMovementsPage({super.key});

  @override
  CashMovementsPageState createState() => CashMovementsPageState();
}

// Constantes de estilos para consistencia
const double _defaultPadding = 16.0;
const double _defaultBorderRadius = 12.0;

final Map<String, Color> _movementTypeColors = {
  'income': Colors.green,
  'expense': Colors.red,
  'sale': Colors.blue,
  'opening': Colors.orange,
  'closing': Colors.purple,
};

final Map<String, IconData> _movementTypeIcons = {
  'income': Icons.add_circle,
  'expense': Icons.remove_circle,
  'sale': Icons.shopping_cart,
  'opening': Icons.lock_open,
  'closing': Icons.lock,
};

class CashMovementsPageState extends State<CashMovementsPage> {
  late CashController cashController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'todos'; // 'todos', 'income', 'expense', 'sale'

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador de forma segura
    try {
      cashController = Get.find<CashController>();
    } catch (e) {
      if (kDebugMode) {

      }
      cashController = Get.put(CashController(), permanent: true);
    }
    
    // Cargar movimientos del día actual
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await cashController.initialize();
      await _loadMovements();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);
    return formatter.format(amount);
  }

  Future<void> _loadMovements() async {
    await cashController.loadMovementsByDate(_selectedDate);
  }

  List<Map<String, dynamic>> _getMovementsFromCurrentOpening() {
    // Si no hay caja abierta, retornar lista vacía
    if (!cashController.isCashRegisterOpen || cashController.currentCashRegister == null) {
      return [];
    }

    // Obtener hora de apertura de la caja actual
    final currentRegister = cashController.currentCashRegister;
    final openingTime = currentRegister!['openingTime'] ?? currentRegister['createdAt'];
    
    if (openingTime == null) {
      return cashController.todayMovements;
    }

    try {
      final openingDateTime = DateTime.parse(openingTime.toString());
      
      // Filtrar movimientos posteriores a la apertura
      return cashController.todayMovements
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
      return cashController.todayMovements;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        title: Text('Movimientos de Caja'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMovements,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
            tooltip: 'Cambiar fecha',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(child: _buildMovementsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMovementDialog,
        backgroundColor: Utils.colorBotones,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Nuevo Movimiento', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(_defaultPadding),
      margin: EdgeInsets.all(_defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_defaultBorderRadius),
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
          Text(
            DateFormat('EEEE, dd MMMM yyyy', 'es').format(_selectedDate),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Utils.colorGnav,
            ),
          ),
          SizedBox(height: _defaultPadding),
          Obx(() {
            final movements = _getFilteredMovements();
            final totalIncome = movements
                .where((m) => m['type'] == 'income' || m['type'] == 'sale')
                .fold(0.0, (sum, m) => sum + ((m['amount'] ?? 0.0).toDouble()));
            final totalOutcome = movements
                .where((m) => m['type'] == 'expense')
                .fold(0.0, (sum, m) => sum + ((m['amount'] ?? 0.0).toDouble()));
            
            // Calcular monto esperado igual que en cash_register_page
            double expectedAmount = 0.0;
            if (cashController.isCashRegisterOpen && cashController.currentCashRegister != null) {
              final openingAmount = (cashController.currentCashRegister!['openingAmount'] ?? 0.0).toDouble();
              expectedAmount = openingAmount + totalIncome - totalOutcome;
            } else {
              expectedAmount = cashController.expectedAmount;
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCard('Ingresos', totalIncome, Colors.green, Icons.trending_up),
                _buildSummaryCard('Egresos', totalOutcome, Colors.red, Icons.trending_down),
                _buildSummaryCard('Monto esperado', expectedAmount, 
                  expectedAmount >= 0 ? Colors.green : Colors.red, 
                  expectedAmount >= 0 ? Icons.trending_up : Icons.trending_down),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    final formatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: _defaultPadding / 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: _defaultPadding),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Todos', 'todos'),
          SizedBox(width: _defaultPadding / 2),
          _buildFilterChip('Entradas', 'income'),
          SizedBox(width: _defaultPadding / 2),
          _buildFilterChip('Salidas', 'expense'),
          SizedBox(width: _defaultPadding / 2),
          _buildFilterChip('Ventas', 'sale'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Utils.colorGnav,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
        });
      },
      selectedColor: Utils.colorGnav,
      backgroundColor: Colors.grey[100],
      checkmarkColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: _defaultPadding / 2, vertical: _defaultPadding / 4),
    );
  }

  Widget _buildMovementsList() {
    return Obx(() {
      final movements = _getFilteredMovements();
      
      if (cashController.isLoading) {
        return Center(child: CircularProgressIndicator());
      }

      if (movements.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No hay movimientos',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Los movimientos aparecerán aquí',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: movements.length,
        itemBuilder: (context, index) {
          final movement = movements[index];
          return _buildMovementCard(movement);
        },
      );
    });
  }

  Widget _buildMovementCard(Map<String, dynamic> movement) {
    final movementType = movement['type'] ?? '';
    
    // Use color and icon from maps
    final typeColor = _movementTypeColors[movementType] ?? Colors.grey;
    final typeIcon = _movementTypeIcons[movementType] ?? Icons.help;
    
    // Define type text mapping
    final typeTextMap = {
      'income': 'Entrada',
      'expense': 'Salida',
      'sale': 'Venta',
      'opening': 'Apertura',
      'closing': 'Cierre',
    };
    final typeText = typeTextMap[movementType] ?? 'Desconocido';

    return Container(
      margin: EdgeInsets.only(bottom: _defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_defaultBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(_defaultPadding),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            typeIcon,
            color: typeColor,
            size: 24,
          ),
        ),
        title: Text(
          movement['description'] ?? 'Sin descripción',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: _defaultPadding / 4),
            Text(
              typeText,
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            SizedBox(height: _defaultPadding / 8),
            Text(
              DateFormat('HH:mm').format(TimeUtils.toBoliviaTime(DateTime.parse(movement['createdAt'] ?? DateTime.now().toIso8601String()))),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          _formatCurrency(((movement['amount'] ?? 0.0).toDouble())),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: typeColor,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredMovements() {
    final movementsFromOpening = _getMovementsFromCurrentOpening();
    
    if (_filterType == 'todos') {
      return movementsFromOpening.toList();
    }
    return movementsFromOpening
        .where((movement) => movement['type'] == _filterType)
        .toList();
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
      await _loadMovements();
    }
  }

  void _showAddMovementDialog() {
    String selectedType = 'entrada';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Nuevo Movimiento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Utils.colorGnav,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Tipo de movimiento',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: [
                        DropdownMenuItem(value: 'entrada', child: Text('Entrada de dinero')),
                        DropdownMenuItem(value: 'salida', child: Text('Salida de dinero')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    SizedBox(height: _defaultPadding),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Monto',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_defaultBorderRadius),
                        ),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'Bs. ',
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                    SizedBox(height: _defaultPadding),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_defaultBorderRadius),
                        ),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _amountController.clear();
                    _descriptionController.clear();
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => _addMovement(selectedType),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Utils.colorBotones,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addMovement(String type) async {
    if (_amountController.text.isEmpty || _descriptionController.text.isEmpty) {
      Utils.showErrorSnackbar('Error', 'Por favor complete todos los campos');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      Utils.showErrorSnackbar('Error', 'Ingrese un monto válido');
      return;
    }

    try {
      // Convertir el tipo de la UI (español) al tipo del backend (inglés)
      if (type == 'entrada') {
        await cashController.addCashIncome(amount, _descriptionController.text);
      } else if (type == 'salida') {
        await cashController.addCashOutcome(amount, _descriptionController.text);
      }

      _amountController.clear();
      _descriptionController.clear();
      if (mounted) Navigator.of(context).pop();
      
      await _loadMovements();
      
      Utils.showSuccessSnackbar('Éxito', 'Movimiento agregado correctamente');
    } catch (e) {
      Utils.showErrorSnackbar('Error', 'Error al agregar movimiento: $e');
    }
  }
}
