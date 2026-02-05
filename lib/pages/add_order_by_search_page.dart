import 'package:bellezapp/controllers/order_controller.dart';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/controllers/customer_controller.dart';
import 'package:bellezapp/controllers/payment_controller.dart';
import 'package:bellezapp/controllers/quotation_controller.dart';
import 'package:bellezapp/models/customer.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:bellezapp/widgets/payment_method_dialog.dart';
import 'package:bellezapp/widgets/discount_selection_dialog.dart';
import 'package:bellezapp/widgets/customer_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AddOrderBySearchPage extends StatefulWidget {
  const AddOrderBySearchPage({super.key});

  @override
  AddOrderBySearchPageState createState() => AddOrderBySearchPageState();
}

class AddOrderBySearchPageState extends State<AddOrderBySearchPage> {
  late final ProductController productController;
  late final OrderController orderController;
  late final StoreController storeController;
  late final CustomerController customerController;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, int> _selectedProducts = {}; // productId -> quantity
  Customer? selectedCustomer;

  @override
  void initState() {
    super.initState();
    try {
      productController = Get.find<ProductController>();
    } catch (e) {
      productController = Get.put(ProductController());
    }
    try {
      orderController = Get.find<OrderController>();
    } catch (e) {
      orderController = Get.put(OrderController());
    }
    try {
      storeController = Get.find<StoreController>();
    } catch (e) {
      storeController = Get.put(StoreController());
    }
    try {
      customerController = Get.find<CustomerController>();
    } catch (e) {
      customerController = Get.put(CustomerController());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return productController.products;
    }

    return productController.products.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final category = (product['category'] ?? '').toString().toLowerCase();
      final sku = (product['sku'] ?? '').toString().toLowerCase();

      return name.contains(searchText) ||
          category.contains(searchText) ||
          sku.contains(searchText);
    }).toList();
  }

  double get _totalAmount {
    double total = 0.0;
    _selectedProducts.forEach((productId, quantity) {
      final product = productController.products.firstWhereOrNull(
        (p) => p['_id'] == productId,
      );
      if (product != null) {
        // Usar el mismo parsing robusto que en _buildProductList
        double price = 0.0;
        if (product['price'] != null) {
          if (product['price'] is num) {
            price = (product['price'] as num).toDouble();
          } else {
            price = double.tryParse(product['price'].toString()) ?? 0.0;
          }
        } else if (product['basePrice'] != null) {
          if (product['basePrice'] is num) {
            price = (product['basePrice'] as num).toDouble();
          } else {
            price = double.tryParse(product['basePrice'].toString()) ?? 0.0;
          }
        } else if (product['salePrice'] != null) {
          if (product['salePrice'] is num) {
            price = (product['salePrice'] as num).toDouble();
          } else {
            price = double.tryParse(product['salePrice'].toString()) ?? 0.0;
          }
        }
        total += price * quantity;
      }
    });
    return total;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);
    return formatter.format(amount);
  }

  void _updateQuantity(String productId, int newQuantity, int maxStock) {
    setState(() {
      if (newQuantity <= 0) {
        _selectedProducts.remove(productId);
      } else if (newQuantity <= maxStock) {
        _selectedProducts[productId] = newQuantity;
      }
    });
  }

  Widget _buildProductList() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.shopping_bag_outlined
                  : Icons.search_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay productos disponibles'
                  : 'No se encontraron productos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final productId = product['_id'] ?? '';
        final name = product['name'] ?? 'Producto';
        
        // Mejorar parsing del precio - probar múltiples nombres
        double price = 0.0;
        if (product['price'] != null) {
          if (product['price'] is num) {
            price = (product['price'] as num).toDouble();
          } else {
            price = double.tryParse(product['price'].toString()) ?? 0.0;
          }
        } else if (product['basePrice'] != null) {
          // Intentar con basePrice
          if (product['basePrice'] is num) {
            price = (product['basePrice'] as num).toDouble();
          } else {
            price = double.tryParse(product['basePrice'].toString()) ?? 0.0;
          }
        } else if (product['salePrice'] != null) {
          // Intentar con salePrice
          if (product['salePrice'] is num) {
            price = (product['salePrice'] as num).toDouble();
          } else {
            price = double.tryParse(product['salePrice'].toString()) ?? 0.0;
          }
        }
        
        final stock = product['stock'] ?? 0;
        final quantity = _selectedProducts[productId] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stock: $stock | Precio: ${_formatCurrency(price)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (quantity > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Utils.colorBotones.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$quantity x',
                          style: TextStyle(
                            color: Utils.colorBotones,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Controles de cantidad
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                _updateQuantity(productId, quantity - 1, stock);
                              },
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Center(
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                _updateQuantity(productId, quantity + 1, stock);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (quantity > 0)
                      Text(
                        _formatCurrency(price * quantity),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Utils.colorBotones,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: const Text('Crear Orden por Búsqueda'),
        backgroundColor: Utils.colorGnav,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar productos por nombre, categoría o SKU...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                prefixIcon: Icon(Icons.search, color: Utils.colorBotones),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          // Lista de productos
          Expanded(
            child: Obx(() {
              if (productController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildProductList();
            }),
          ),
        ],
      ),
      bottomNavigationBar: _selectedProducts.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total (${_selectedProducts.length} productos)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatCurrency(_totalAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Utils.colorBotones,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _createOrder(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Utils.colorBotones,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text(
                            'Crear Orden',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _generateQuotation(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text(
                            'Generar Cotización',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _createOrder() async {
    // Calcular subtotal
    double subtotal = _totalAmount;

    // Si no hay cliente seleccionado, preguntar si quiere seleccionar uno
    if (selectedCustomer == null) {
      final shouldSelectCustomer = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.person_add, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Seleccionar Cliente', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('¿Deseas asociar esta venta a un cliente?'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
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
                child: const Text('Continuar sin cliente'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Seleccionar cliente'),
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
      return;
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
      final List<Map<String, dynamic>> orderItems = [];
      _selectedProducts.forEach((productId, quantity) {
        final product = productController.products.firstWhereOrNull(
          (p) => p['_id'] == productId,
        );
        if (product != null) {
          // Usar el mismo parsing robusto que en _buildProductList
          double price = 0.0;
          if (product['price'] != null) {
            if (product['price'] is num) {
              price = (product['price'] as num).toDouble();
            } else {
              price = double.tryParse(product['price'].toString()) ?? 0.0;
            }
          } else if (product['basePrice'] != null) {
            if (product['basePrice'] is num) {
              price = (product['basePrice'] as num).toDouble();
            } else {
              price = double.tryParse(product['basePrice'].toString()) ?? 0.0;
            }
          } else if (product['salePrice'] != null) {
            if (product['salePrice'] is num) {
              price = (product['salePrice'] as num).toDouble();
            } else {
              price = double.tryParse(product['salePrice'].toString()) ?? 0.0;
            }
          }
          
          orderItems.add({
            'productId': productId,
            'quantity': quantity,
            'price': price,
          });
        }
      });

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
        _selectedProducts.clear();
        selectedCustomer = null; // Limpiar cliente seleccionado
      });

      // Mostrar mensaje de éxito antes de recargar
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
        message += '\n💰 Subtotal: ${_formatCurrency(subtotal)}';
        message += '\n🎫 Descuento: -${_formatCurrency(discountAmount)}';
        if (selectedDiscount != null) {
          message += ' (${selectedDiscount['name']})';
        }
      }
      message += '\n💰 Total Final: ${_formatCurrency(totalOrder)}';

      Get.snackbar(
        'Venta Exitosa',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      // Esperar un poco para que el snackbar se muestre
      await Future.delayed(const Duration(milliseconds: 500));

      // Recargar clientes para actualizar estadísticas
      if (selectedCustomer != null) {
        await customerController.loadCustomers();
      }

      // ⭐ IMPORTANTE: Recargar productos ANTES de navegar para que estén actualizados
      await productController.loadProductsForCurrentStore();

      // Limpiar información de pago
      paymentController.resetPaymentInfo();

      // Navegar de regreso a la lista de órdenes con resultado exitoso
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      Utils.showErrorSnackbar('Error', 'Error al crear orden: $e');
    }
  }

  Future<void> _generateQuotation() async {
    final quotationController = Get.isRegistered<QuotationController>()
        ? Get.find<QuotationController>()
        : Get.put(QuotationController());
    final storeId = storeController.currentStore?['_id'];

    if (storeId == null) {
      Utils.showErrorSnackbar('Error', 'No hay tienda seleccionada');
      return;
    }

    try {
      // Calcular subtotal
      double subtotal = 0.0;
      final List<Map<String, dynamic>> quotationItems = [];
      
      _selectedProducts.forEach((productId, quantity) {
        final product = productController.products.firstWhereOrNull(
          (p) => p['_id'] == productId,
        );
        if (product != null) {
          double price = 0.0;
          if (product['price'] != null) {
            if (product['price'] is num) {
              price = (product['price'] as num).toDouble();
            } else {
              price = double.tryParse(product['price'].toString()) ?? 0.0;
            }
          } else if (product['basePrice'] != null) {
            if (product['basePrice'] is num) {
              price = (product['basePrice'] as num).toDouble();
            } else {
              price = double.tryParse(product['basePrice'].toString()) ?? 0.0;
            }
          } else if (product['salePrice'] != null) {
            if (product['salePrice'] is num) {
              price = (product['salePrice'] as num).toDouble();
            } else {
              price = double.tryParse(product['salePrice'].toString()) ?? 0.0;
            }
          }

          subtotal += price * quantity;
          quotationItems.add({
            'productId': productId,
            'quantity': quantity,
            'price': price,
          });
        }
      });

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

      // Crear cotización SIN método de pago (se pedirá al convertir)
      Get.snackbar(
        'Generando',
        'Creando cotización...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      await quotationController.createQuotation(
        items: quotationItems,
        storeId: storeId,
        customerId: selectedCustomer?.id,
        discountId: selectedDiscount?['_id'],
        discountAmount: discountAmount,
      );

      // Mostrar mensaje de éxito
      Get.snackbar(
        '✅ Cotización Generada',
        'Subtotal: ${_formatCurrency(subtotal)}, Descuento: ${_formatCurrency(discountAmount)}, Total: ${_formatCurrency(totalQuotation)}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      // Limpiar formulario y volver
      setState(() {
        _selectedProducts.clear();
        selectedCustomer = null;
        _searchController.clear();
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // Recargar productos
      await productController.loadProductsForCurrentStore();

      // Navegar de regreso
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      Utils.showErrorSnackbar('Error', 'Error al generar cotización: $e');
    }
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
}


