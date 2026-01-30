import 'package:bellezapp/controllers/order_controller.dart';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/returns/returns_controller.dart';
import 'package:bellezapp/models/returns/return_models.dart';
import 'package:bellezapp/pages/add_order_page.dart';
import 'package:bellezapp/pages/add_order_by_search_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  OrderListPageState createState() => OrderListPageState();
}

class OrderListPageState extends State<OrderListPage> {
  late final OrderController orderController;
  late final ReturnsController returnsController;
  late final ProductController productController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Usar la misma instancia del controlador que ya existe
    try {
      orderController = Get.find<OrderController>();
    } catch (e) {
      orderController = Get.put(OrderController());
    }
    try {
      returnsController = Get.find<ReturnsController>();
    } catch (e) {
      returnsController = Get.put(ReturnsController());
    }
    try {
      productController = Get.find<ProductController>();
    } catch (e) {
      productController = Get.put(ProductController());
    }
    _loadOrders();
  }

  void _loadOrders() {
    // Cargar ventas para la tienda actual
    orderController.loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredOrders {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return orderController.orders;
    }

    return orderController.orders.where((order) {
      final total = order['totalOrden'].toString().toLowerCase();
      final paymentMethod = (order['paymentMethod'] ?? '')
          .toString()
          .toLowerCase();

      // Número de orden (últimos 6 dígitos del ID)
      final orderId = order['_id'] ?? order['id'] ?? '';
      final orderNumber = orderId.length >= 6
          ? orderId.substring(orderId.length - 6)
          : orderId;

      // Nombre del cliente
      final customer = order['customerId'] as Map<String, dynamic>?;
      final customerName = (customer?['name']?.toString() ?? '').toLowerCase();

      return total.contains(searchText) ||
          paymentMethod.contains(searchText) ||
          orderNumber.toLowerCase().contains(searchText) ||
          customerName.contains(searchText);
    }).toList();
  }

  double get _totalSum {
    return _filteredOrders.fold(
      0.0,
      (sum, order) =>
          sum + (double.tryParse(order['totalOrden'].toString()) ?? 0.0),
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return 'Sin fecha';
      final dateTime = date is DateTime
          ? date
          : DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      body: Column(
        children: [
          // Header mejorado con búsqueda prominente
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ventas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Utils.colorBotones.withValues(alpha: 0.1),
                            Utils.colorBotones.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Utils.colorBotones.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on_rounded,
                                color: Utils.colorBotones,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total ventas',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Obx(
                                    () => Text(
                                      '${_filteredOrders.length} ventas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Utils.colorBotones,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(width: 12),
                          Obx(
                            () => Text(
                              _formatCurrency(_totalSum),
                              style: TextStyle(
                                fontSize: 16,
                                color: Utils.colorBotones,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Campo de búsqueda prominente
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    style: TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar por venta, cliente, monto o método...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Utils.colorBotones,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de órdenes
          Expanded(
            child: Obx(() {
              if (orderController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final orders = _filteredOrders;

              if (orders.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildOrderCard(order);
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () => _showCreateOrderOptions(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Utils.colorBotones.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchController.text.isEmpty
                  ? Icons.receipt_long_outlined
                  : Icons.search_off,
              size: 80,
              color: Utils.colorBotones.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty
                ? 'No hay ventas'
                : 'No se encontraron ventas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Las ventas aparecerán aquí'
                : 'Intenta con otros términos de búsqueda',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final total = double.tryParse(order['totalOrden'].toString()) ?? 0.0;
    final paymentMethod = order['paymentMethod'] ?? 'efectivo';
    final orderDate = order['orderDate'] ?? order['createdAt'];
    final items = order['items'] as List<dynamic>? ?? [];

    // Obtener número de orden (últimos 6 dígitos del ID)
    final orderId = order['_id'] ?? order['id'] ?? '';
    final orderNumber = orderId.length >= 6
        ? orderId.substring(orderId.length - 6)
        : orderId;

    // Obtener información del cliente
    final customer = order['customerId'] as Map<String, dynamic>?;
    final customerName = customer?['name']?.toString() ?? 'Cliente General';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Utils.colorFondoCards,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          trailing: PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.print_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Text('Imprimir PDF'),
                  ],
                ),
                onTap: () {
                  Get.snackbar('PDF', 'Generando PDF de la orden...');
                },
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.assignment_return, size: 20),
                    const SizedBox(width: 8),
                    const Text('Crear devolución'),
                  ],
                ),
                onTap: () {
                  _showCreateReturnDialog(context, order);
                },
              ),
            ],
          ),
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Utils.colorBotones.withValues(alpha: 0.15),
                  Utils.colorBotones.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Utils.colorBotones.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Utils.colorBotones,
              size: 28,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Venta #$orderNumber',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Utils.colorBotones,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    _formatCurrency(total),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(orderDate),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getPaymentColor(
                          paymentMethod,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getPaymentColor(
                            paymentMethod,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPaymentIcon(paymentMethod),
                            size: 12,
                            color: _getPaymentColor(paymentMethod),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPaymentMethodLabel(paymentMethod),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getPaymentColor(paymentMethod),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_rounded,
                            size: 12,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${items.length}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Productos:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...items.map((item) {
                    final quantity = item['quantity'] ?? 0;
                    final price =
                        double.tryParse(item['price'].toString()) ?? 0.0;
                    final productId = item['productId'];
                    final productName = productId is Map
                        ? (productId['name'] ?? 'Producto sin nombre')
                        : 'Producto #$productId';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$quantity x $productName',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            _formatCurrency(price * quantity),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'tarjeta':
        return Colors.purple;
      case 'transferencia':
        return Colors.blue;
      case 'efectivo':
      default:
        return Colors.green;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'tarjeta':
        return Icons.credit_card;
      case 'transferencia':
        return Icons.account_balance;
      case 'efectivo':
      default:
        return Icons.payments;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      case 'efectivo':
      default:
        return 'Efectivo';
    }
  }

  void _showCreateOrderOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Crear Orden'),
          content: const Text('¿Cómo deseas crear la orden?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Get.to(() => const AddOrderPage());
                if (result == true || result == null) {
                  orderController.loadOrders();
                }
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Por QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Utils.colorBotones,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final result = await Get.to(() => const AddOrderBySearchPage());
                if (result == true || result == null) {
                  orderController.loadOrders();
                  // ⭐ También recargar productos para actualizar stock
                  productController.loadProductsForCurrentStore();
                }
              },
              icon: const Icon(Icons.search),
              label: const Text('Por Búsqueda'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateReturnDialog(BuildContext context, Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final Map<int, int> selectedQuantities = {};
    
    // Inicializar cantidades en 0
    for (int i = 0; i < items.length; i++) {
      selectedQuantities[i] = 0;
    }

    String selectedType = 'return_';
    String selectedReason = 'other';
    String selectedRefundMethod = 'efectivo';
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear Devolución'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información de la orden
                    Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Orden: #${(order["_id"] as String?)?.substring(((order["_id"] as String?)?.length ?? 0) - 6) ?? "N/A"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cliente: ${order["customerId"] is Map ? (order["customerId"] as Map)["name"] ?? "General" : "General"}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Tipo de devolución
                    const Text('Tipo de Devolución', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'return_', child: Text('Devolución')),
                        DropdownMenuItem(value: 'exchange', child: Text('Cambio')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => selectedType = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Razón de devolución
                    const Text('Razón de Devolución', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: selectedReason,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'defective', child: Text('Defectuoso')),
                        DropdownMenuItem(value: 'not_as_described', child: Text('No Como se Describe')),
                        DropdownMenuItem(value: 'customer_change_mind', child: Text('Cambió de Opinión')),
                        DropdownMenuItem(value: 'wrong_item', child: Text('Producto Incorrecto')),
                        DropdownMenuItem(value: 'damaged', child: Text('Dañado')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => selectedReason = value);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Método de reembolso
                    const Text('Método de Reembolso', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: selectedRefundMethod,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                        DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                        DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                        DropdownMenuItem(value: 'cuenta', child: Text('Cuenta')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => selectedRefundMethod = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Productos
                    const Text('Productos a Devolver', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      const Text('No hay productos en esta orden', style: TextStyle(fontSize: 11, color: Colors.grey))
                    else
                      ...[
                        ...items.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;
                        int availableQty = item['quantity'] ?? 0;
                        String productName = item['productId'] is Map
                            ? (item['productId'] as Map)['name'] ?? 'Producto'
                            : 'Producto #${item['productId']}';
                        String productId = item['productId'] is Map
                            ? ((item['productId'] as Map)['_id'] ?? '').toString()
                            : (item['productId'] ?? '').toString();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Disponible: $availableQty x ${_formatCurrency(double.tryParse(item['price'].toString()) ?? 0.0)}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Cantidad:', style: TextStyle(fontSize: 11)),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[300]!),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.remove),
                                                iconSize: 16,
                                                onPressed: () {
                                                  if ((selectedQuantities[index] ?? 0) > 0) {
                                                    setState(() => selectedQuantities[index] = (selectedQuantities[index] ?? 0) - 1);
                                                  }
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              child: Center(
                                                child: Text(
                                                  '${selectedQuantities[index] ?? 0}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 32,
                                              height: 32,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(Icons.add),
                                                iconSize: 16,
                                                onPressed: () {
                                                  if ((selectedQuantities[index] ?? 0) < availableQty) {
                                                    setState(() => selectedQuantities[index] = (selectedQuantities[index] ?? 0) + 1);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                        // Total a devolver
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Utils.colorBotones.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Utils.colorBotones.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total a devolver:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                _formatCurrency(
                                  selectedQuantities.entries.fold(0.0, (sum, entry) {
                                    int index = entry.key;
                                    int qty = entry.value;
                                    if (qty > 0 && index < items.length) {
                                      final price = double.tryParse(items[index]['price'].toString()) ?? 0.0;
                                      return sum + (price * qty);
                                    }
                                    return sum;
                                  }),
                                ),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Utils.colorBotones,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                    const SizedBox(height: 12),

                    // Notas
                    const Text('Notas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Agregar notas (opcional)',
                        hintStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    print('=== DEBUG: Botón Crear Devolución presionado ===');
                    final hasItems = selectedQuantities.values.any((qty) => qty > 0);
                    print('Has items: $hasItems');
                    if (!hasItems) {
                      Get.snackbar('Error', 'Debes seleccionar al menos un producto');
                      return;
                    }

                    try {
                      // Agregar items seleccionados al controller
                      print('DEBUG: Limpiando selectedItems');
                      returnsController.selectedItems.clear();
                      
                      print('DEBUG: Configurando selectedType');
                      returnsController.selectedType.value = selectedType == 'return_' 
                          ? ReturnType.return_ 
                          : ReturnType.exchange;
                      
                      print('DEBUG: Configurando selectedReason');
                      returnsController.selectedReason.value = 
                          selectedReason == 'defective' ? ReturnReasonCategory.defective :
                          selectedReason == 'not_as_described' ? ReturnReasonCategory.notAsDescribed :
                          selectedReason == 'customer_change_mind' ? ReturnReasonCategory.customerChangeMind :
                          selectedReason == 'wrong_item' ? ReturnReasonCategory.wrongItem :
                          selectedReason == 'damaged' ? ReturnReasonCategory.damaged :
                          ReturnReasonCategory.other;
                      
                      print('DEBUG: Configurando selectedRefundMethod');
                      returnsController.selectedRefundMethod.value =
                          selectedRefundMethod == 'efectivo' ? RefundMethod.cash :
                          selectedRefundMethod == 'tarjeta' ? RefundMethod.card :
                          selectedRefundMethod == 'transferencia' ? RefundMethod.transfer :
                          RefundMethod.account;
                      
                      print('DEBUG: Configurando notes');
                      returnsController.notes.value = notesController.text;

                      // Agregar items con las cantidades seleccionadas
                      print('DEBUG: Agregando items');
                      selectedQuantities.forEach((index, quantity) {
                        if (quantity > 0) {
                          final item = items[index];
                          String productName = item['productId'] is Map
                              ? (item['productId'] as Map)['name'] ?? 'Producto'
                              : 'Producto #${item['productId']}';
                          String productId = item['productId'] is Map
                              ? ((item['productId'] as Map)['_id'] ?? '').toString()
                              : (item['productId'] ?? '').toString();
                          int originalQty = item['quantity'] ?? 0;
                          
                          print('DEBUG: Agregando producto - ID: $productId, Name: $productName, Qty: $quantity');
                          returnsController.addItem(
                            productId: productId,
                            productName: productName,
                            originalQuantity: originalQty,
                            quantity: quantity,
                            unitPrice: double.tryParse(item['price'].toString()) ?? 0.0,
                            returnReason: notesController.text.isNotEmpty 
                                ? notesController.text 
                                : 'Producto a devolver',
                          );
                        }
                      });

                      // Crear la devolución
                      final orderId = (order['_id'] ?? '').toString();
                      final storeData = order['storeId'];
                      final storeId = storeData is Map 
                          ? (storeData['_id'] ?? '').toString()
                          : (storeData ?? '').toString();
                      
                      print('DEBUG: Creando solicitud - OrderID: $orderId, StoreID: $storeId');
                      print('DEBUG: Items count: ${returnsController.selectedItems.length}');
                      
                      final success = await returnsController.createReturnRequest(
                        orderId: orderId,
                        storeId: storeId,
                      );

                      print('DEBUG: Success: $success');
                      
                      if (success) {
                        Navigator.of(context).pop();
                        // Mostrar mensaje de éxito
                        Get.snackbar(
                          'Éxito',
                          'Devolución creada correctamente',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                        // Refrescar lista de órdenes y productos
                        Future.delayed(const Duration(milliseconds: 300), () {
                          orderController.loadOrders();
                          productController.loadProducts();
                        });
                      } else {
                        // Si falla, mostrar error pero no descartar el diálogo
                        Get.snackbar('Error', 'Error al crear la devolución');
                      }
                    } catch (e) {
                      print('DEBUG ERROR: $e');
                      print('Stack trace: ${StackTrace.current}');
                      Get.snackbar('Error', 'Error al crear devolución: $e');
                    }
                  },
                  child: const Text('Crear Devolución'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
