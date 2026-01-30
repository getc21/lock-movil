import 'package:bellezapp/controllers/indexpage_controller.dart';
import 'package:bellezapp/controllers/cash_controller.dart';
import 'package:bellezapp/controllers/payment_controller.dart';
import 'package:bellezapp/controllers/discount_controller.dart';
import 'package:bellezapp/controllers/customer_controller.dart';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/order_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/controllers/quotation_controller.dart';
import 'package:bellezapp/models/customer.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/widgets/payment_method_dialog.dart';
import 'package:bellezapp/widgets/discount_selection_dialog.dart';
import 'package:bellezapp/widgets/customer_selection_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:intl/intl.dart';

class AddOrderPage extends StatefulWidget {
  const AddOrderPage({super.key});

  @override
  AddOrderPageState createState() => AddOrderPageState();
}

class AddOrderPageState extends State<AddOrderPage> {
  final MobileScannerController scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final List<Map<String, dynamic>> _products = [];
  final ipc = Get.find<IndexPageController>();

  // Variables para cooldown del escáner
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  static const Duration _scanCooldown = Duration(seconds: 3);

  late CashController cashController;
  late DiscountController discountController;
  late CustomerController customerController;
  late ProductController productController;
  late OrderController orderController;
  late StoreController storeController;
  Customer? selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Inicializar los controladores de forma segura
    try {
      cashController = Get.find<CashController>();
    } catch (e) {
      cashController = Get.put(CashController(), permanent: true);
    }

    try {
      discountController = Get.find<DiscountController>();
    } catch (e) {
      discountController = Get.put(DiscountController(), permanent: true);
    }

    try {
      customerController = Get.find<CustomerController>();
    } catch (e) {
      customerController = Get.put(CustomerController(), permanent: true);
    }

    try {
      productController = Get.find<ProductController>();
    } catch (e) {
      productController = Get.put(ProductController(), permanent: true);
    }

    try {
      orderController = Get.find<OrderController>();
    } catch (e) {
      orderController = Get.put(OrderController(), permanent: true);
    }

    try {
      storeController = Get.find<StoreController>();
    } catch (e) {
      storeController = Get.put(StoreController(), permanent: true);
    }
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }

  // Limpiar el cooldown del escáner
  void _clearScanCooldown() {
    _lastScannedCode = null;
    _lastScanTime = null;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);
    return formatter.format(amount);
  }

  void _handleBarcodeDetection(BarcodeCapture barcodeCapture) async {
    final List<Barcode> barcodes = barcodeCapture.barcodes;

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        // Verificar cooldown para evitar escaneos repetidos del mismo código
        final now = DateTime.now();
        if (_lastScannedCode == code &&
            _lastScanTime != null &&
            now.difference(_lastScanTime!) < _scanCooldown) {
          // Dentro del período de cooldown, ignorar completamente este escaneo
          return;
        }

        try {
          final product = await productController.searchProduct(code);

          if (product != null) {
            final productId = product['_id'] ?? product['id'];

            if (!_products.any((p) => p['id'] == productId)) {
              // Producto nuevo - agregarlo
              setState(() {
                _products.add({
                  'id': productId,
                  'name': product['name'],
                  'quantity': 1,
                  'price': product['salePrice'] ?? product['sale_price'] ?? 0.0,
                });
              });

              // Actualizar cooldown solo después de agregar exitosamente
              _lastScannedCode = code;
              _lastScanTime = now;

              // Feedback visual y sonoro
              FlutterRingtonePlayer().play(fromAsset: 'assets/img/beep.mp3');

              // Mostrar snackbar de éxito
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${product['name']} agregado al carrito'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            } else {
              // Actualizar cooldown para evitar spam de logs
              _lastScannedCode = code;
              _lastScanTime = now;
            }
          } else {
            // Actualizar cooldown para evitar spam del mensaje de error
            _lastScannedCode = code;
            _lastScanTime = now;

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Producto no encontrado: $code'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          // Actualizar cooldown para evitar spam del mensaje de error
          _lastScannedCode = code;
          _lastScanTime = now;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('💥 Error de conexión: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
  }

  void _incrementQuantity(int index) {
    setState(() {
      _products[index]['quantity']++;
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_products[index]['quantity'] > 1) {
        _products[index]['quantity']--;
      }
    });
  }

  void _registerOrder() async {
    if (_products.isEmpty) {
      // Mostrar un mensaje de advertencia si no hay productos en la lista
      Get.snackbar(
        'Advertencia',
        'No se puede registrar una orden sin productos.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Calcular total antes de descuentos
    double subtotal = 0.0;
    for (var product in _products) {
      subtotal += product['quantity'] * product['price'];
    }

    // Si no hay cliente seleccionado, preguntar si quiere seleccionar uno
    if (selectedCustomer == null) {
      final shouldSelectCustomer = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person_add, color: Colors.blue),
                SizedBox(width: 8),
                Text('Seleccionar Cliente', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Deseas asociar esta venta a un cliente?'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El cliente ganará ${Customer.calculatePointsFromPurchase(subtotal)} punto${Customer.calculatePointsFromPurchase(subtotal) != 1 ? 's' : ''} con esta compra',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Continuar sin cliente'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Seleccionar cliente'),
              ),
            ],
          );
        },
      );

      if (shouldSelectCustomer == true) {
        // Mostrar diálogo de selección de cliente
        await _showCustomerSelectionDialog(subtotal);
        // Después de seleccionar cliente, no continuar automáticamente
        return;
      }
    } else {
      // Si ya hay cliente seleccionado, continuar directamente
      await _showDiscountSelectionDialog(subtotal);
    }

    // Si se seleccionó continuar sin cliente, proceder con descuentos
    if (selectedCustomer == null) {
      await _showDiscountSelectionDialog(subtotal);
    }
  }

  Future<void> _showCustomerSelectionDialog(double subtotal) async {
    // Cargar clientes si no están cargados
    if (customerController.customers.isEmpty) {
      await customerController.loadCustomers();
    }

    // Verificar que el widget sigue montado antes de mostrar el diálogo
    if (!mounted) return;

    // Mostrar diálogo
    final selectedCustomerId = await showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return CustomerSelectionDialog(suggestedCustomer: null);
      },
    );

    if (selectedCustomerId != null) {
      // Buscar el cliente seleccionado
      final customer = customerController.customers.firstWhereOrNull(
        (c) => (c['_id'] ?? c['id']) == selectedCustomerId,
      );

      if (customer != null) {
        setState(() {
          selectedCustomer = Customer.fromMap(customer);
        });

        // Continuar automáticamente con descuentos después de seleccionar cliente
        await _showDiscountSelectionDialog(subtotal);
      }
    }
    // Si se cancela la selección, no hacer nada (el usuario puede decidir continuar sin cliente)
  }

  Future<void> _showDiscountSelectionDialog(double subtotal) async {
    // Verificar que el widget sigue montado antes de mostrar el diálogo
    if (!mounted) return;

    final selectedDiscount = await showDiscountSelectionDialog(
      context: context,
      totalAmount: subtotal,
    );

    // Calcular total final (con o sin descuento)
    final discountAmount = selectedDiscount != null
        ? _calculateDiscountAmount(selectedDiscount, subtotal)
        : 0.0;
    final totalOrder = subtotal - discountAmount;

    // Mostrar diálogo de método de pago con el total final
    await _showPaymentMethodDialog(
      totalOrder,
      subtotal,
      discountAmount,
      selectedDiscount,
    );
  }

  double _calculateDiscountAmount(
    Map<String, dynamic> discount,
    double totalAmount,
  ) {
    final type = discount['type']?.toString() ?? 'percentage';
    final value = (discount['value'] as num?)?.toDouble() ?? 0.0;
    final maxDiscount = (discount['maximumDiscount'] as num?)?.toDouble();

    if (type == 'percentage') {
      double discountAmount = totalAmount * (value / 100);
      if (maxDiscount != null && discountAmount > maxDiscount) {
        return maxDiscount;
      }
      return discountAmount;
    } else if (type == 'fixed') {
      return value;
    }
    return 0.0;
  }

  Future<void> _showPaymentMethodDialog(
    double totalOrder,
    double subtotal,
    double discountAmount,
    dynamic selectedDiscount,
  ) async {
    Get.put(PaymentController());

    // Verificar que el widget sigue montado antes de mostrar el diálogo
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return PaymentMethodDialog(
          totalAmount: totalOrder,
          onPaymentConfirmed: () => _processOrderWithNewPayment(
            totalOrder,
            subtotal,
            discountAmount,
            selectedDiscount,
          ),
        );
      },
    );
  }

  Future<void> _processOrderWithNewPayment(
    double totalOrder,
    double subtotal,
    double discountAmount,
    dynamic selectedDiscount,
  ) async {
    final paymentController = Get.find<PaymentController>();
    final paymentInfo = paymentController.getPaymentSummary();

    try {
      // Obtener tienda actual
      final currentStore = storeController.currentStore;
      if (currentStore == null) {
        throw Exception('No hay tienda seleccionada');
      }

      final storeId = currentStore['_id'] ?? currentStore['id'];
      // Preparar items para la orden
      final List<Map<String, dynamic>> orderItems = _products.map((item) {
        return {
          'productId': item['id'],
          'quantity': item['quantity'],
          'price': item['price'],
        };
      }).toList();

      // Crear orden
      final success = await orderController.createOrder(
        storeId: storeId,
        customerId: selectedCustomer?.id,
        items: orderItems,
        paymentMethod: paymentInfo['payment_method'],
        cashRegisterId: null,
        discountId: selectedDiscount?['_id'] ?? selectedDiscount?['id'],
      );

      if (!success) {
        throw Exception('Error al crear la orden');
      }

      setState(() {
        _products.clear();
        selectedCustomer = null; // Limpiar cliente seleccionado
      });

      // Recargar clientes para actualizar estadísticas
      if (selectedCustomer != null) {
        await customerController.loadCustomers();
      }

      // ⭐ Recargar productos para actualizar stock
      await productController.loadProductsForCurrentStore();

      // Mensaje de éxito con información de descuento
      String message = '✅ Venta procesada exitosamente!';
      if (selectedCustomer != null) {
        final pointsEarned = Customer.calculatePointsFromPurchase(totalOrder);
        message += '\n👤 Cliente: ${selectedCustomer!.name}';
        if (pointsEarned > 0) {
          message +=
              '\n⭐ +$pointsEarned ${pointsEarned == 1 ? 'punto' : 'puntos'} ganado${pointsEarned == 1 ? '' : 's'}!';
        }
      }
      if (discountAmount > 0) {
        message += '\n💰 Subtotal: \$${subtotal.toStringAsFixed(2)}';
        message += '\n🎫 Descuento: -\$${discountAmount.toStringAsFixed(2)}';
        if (selectedDiscount != null) {
          message += ' (${selectedDiscount['name']})';
        }
      }
      message += '\n💰 Total Final: \$${totalOrder.toStringAsFixed(2)}';

      final paymentDetails = paymentController.getPaymentDetails(totalOrder);
      message += '\n💳 $paymentDetails';

      Get.snackbar(
        'Venta Exitosa',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 5),
      );

      FlutterRingtonePlayer().play(
        android: AndroidSounds.notification,
        ios: IosSounds.glass,
        looping: false,
        volume: 0.8,
      );

      // Limpiar información de pago
      paymentController.resetPaymentInfo();

      // Navegar de regreso a la lista de órdenes con resultado exitoso
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al procesar la venta: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildOrderSummary() {
    if (_products.isEmpty) {
      return SizedBox.shrink();
    }

    // Calcular subtotal
    double subtotal = 0.0;
    for (var product in _products) {
      subtotal += product['quantity'] * product['price'];
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Spacer(),
              TextButton.icon(
                onPressed: () => _showDiscountSelectionDialog(subtotal),
                icon: Icon(Icons.local_offer, size: 14),
                label: Text('Desc.', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: TextStyle(fontSize: 13)),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          SizedBox(height: 6),
          Divider(thickness: 1, height: 1),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shopping_cart, size: 24),
            SizedBox(width: 8),
            Text('Nueva Venta'),
          ],
        ),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          if (_products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_products.length} ${_products.length == 1 ? 'producto' : 'productos'}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Sección del escáner QR con indicador visual
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: scannerController,
                  onDetect: _handleBarcodeDetection,
                  errorBuilder: (context, error, child) {
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 64,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Error de cámara',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Verifica los permisos de cámara',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Error: ${error.toString()}',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Intentar reiniciar el escáner
                                try {
                                  scannerController.start();
                                } catch (e) {
                                  if (kDebugMode) {}
                                }
                              },
                              child: Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  placeholderBuilder: (context, child) {
                    return Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'Iniciando cámara...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Overlay con guía visual
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Instrucciones en la parte superior
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Escanea el código QR del producto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_lastScannedCode != null &&
                                  _lastScanTime != null)
                                Text(
                                  'Último: $_lastScannedCode',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón de linterna
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    onPressed: () {
                      scannerController.toggleTorch();
                    },
                    child: Icon(Icons.flash_on, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos mejorada
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Encabezado de la lista
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shopping_basket,
                          color: Utils.colorBotones,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Productos en el carrito',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lista de productos
                  Expanded(
                    child: _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Escanea productos para agregarlos',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            itemCount: _products.length,
                            separatorBuilder: (context, index) =>
                                Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              final itemTotal =
                                  product['quantity'] * product['price'];
                              return Dismissible(
                                key: Key(product['id'].toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  setState(() {
                                    _products.removeAt(index);
                                    // Limpiar cooldown para permitir reescanear
                                    _clearScanCooldown();
                                  });
                                  Get.snackbar(
                                    'Producto eliminado',
                                    'Se ha quitado del carrito',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.orange,
                                    colorText: Colors.white,
                                    duration: Duration(seconds: 2),
                                  );
                                },
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  leading: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red[400],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _products.removeAt(index);
                                        // Limpiar cooldown para permitir reescanear
                                        _clearScanCooldown();
                                      });
                                      Get.snackbar(
                                        'Producto eliminado',
                                        'Se ha quitado del carrito',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.orange,
                                        colorText: Colors.white,
                                        duration: Duration(seconds: 2),
                                      );
                                    },
                                  ),
                                  title: Text(
                                    product['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '\$${product['price'].toStringAsFixed(2)} c/u',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Botón decrementar
                                      SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _decrementQuantity(index),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(),
                                            backgroundColor: Utils.colorBotones,
                                            padding: EdgeInsets.zero,
                                            elevation: 2,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      // Cantidad y total
                                      SizedBox(
                                        width: 70,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${product['quantity']}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '\$${itemTotal.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Utils.colorBotones,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Botón incrementar
                                      SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _incrementQuantity(index),
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(),
                                            backgroundColor: Utils.colorBotones,
                                            padding: EdgeInsets.zero,
                                            elevation: 2,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Widget de resumen de totales
          _buildOrderSummary(),

          // Botón de registrar orden mejorado
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _products.isEmpty
                          ? null
                          : () {
                              _registerOrder();
                            },
                      icon: Icon(Icons.check_circle, size: 24),
                      label: Text('Procesar Orden'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Utils.colorBotones,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _products.isEmpty
                          ? null
                          : () {
                              _generateQuotation();
                            },
                      icon: Icon(Icons.description, size: 24),
                      label: Text('Generar Cotización'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _generateQuotation() async {
    final quotationController = Get.isRegistered<QuotationController>()
        ? Get.find<QuotationController>()
        : Get.put(QuotationController());

    try {
      // Calcular subtotal
      double subtotal = _products.fold(
        0.0,
        (sum, product) => sum + (product['quantity'] * product['price']),
      );

      // Mostrar diálogo de cliente (igual que al crear orden)
      final showClientDialog = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Seleccionar Cliente'),
            content: Text('¿Deseas seleccionar un cliente para esta cotización?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Continuar sin cliente'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Seleccionar cliente'),
              ),
            ],
          );
        },
      );

      // Si elige seleccionar cliente
      if (showClientDialog == true) {
        // Cargar clientes si no están cargados
        if (customerController.customers.isEmpty) {
          await customerController.loadCustomers();
        }

        if (!mounted) return;

        // Mostrar diálogo de selección de cliente
        final selectedCustomerId = await showDialog<String?>(
          context: context,
          builder: (BuildContext context) {
            return CustomerSelectionDialog(suggestedCustomer: null);
          },
        );

        if (selectedCustomerId != null) {
          // Buscar el cliente seleccionado
          final customer = customerController.customers.firstWhereOrNull(
            (c) => (c['_id'] ?? c['id']) == selectedCustomerId,
          );

          if (customer != null) {
            setState(() {
              selectedCustomer = Customer.fromMap(customer);
            });
          }
        }
      }

      // Mostrar diálogo de descuento
      if (!mounted) return;

      final selectedDiscount = await showDiscountSelectionDialog(
        context: context,
        totalAmount: subtotal,
      );

      // Calcular total final con descuento
      final discountAmount = selectedDiscount != null
          ? _calculateDiscountAmount(selectedDiscount, subtotal)
          : 0.0;
      final totalQuotation = subtotal - discountAmount;

      // Preparar items para la cotización
      final List<Map<String, dynamic>> quotationItems = _products.map((product) {
        return {
          'productId': product['id'],
          'quantity': product['quantity'],
          'price': product['price'],
        };
      }).toList();

      Get.snackbar(
        'Generando',
        'Creando cotización...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Crear cotización SIN método de pago (se pedirá al convertir)
      await quotationController.createQuotation(
        items: quotationItems,
        storeId: storeController.currentStore?['_id'] ?? '',
        customerId: selectedCustomer?.id,
        discountId: selectedDiscount?['_id'],
        discountAmount: discountAmount,
      );

      Get.snackbar(
        '✅ Cotización Generada',
        'Subtotal: ${_formatCurrency(subtotal)}, Descuento: ${_formatCurrency(discountAmount)}, Total: ${_formatCurrency(totalQuotation)}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      // Limpiar formulario
      setState(() {
        _products.clear();
        selectedCustomer = null;
        _clearScanCooldown();
      });

      // Recargar productos
      await productController.loadProductsForCurrentStore();

      // Navegar de regreso
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al generar cotización: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

