import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:bellezapp/controllers/quotation_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/order_controller.dart';
import 'package:bellezapp/models/quotation.dart';
import 'package:bellezapp/services/pdf_service.dart';
import 'package:bellezapp/utils/utils.dart';

class QuotationsListPage extends StatefulWidget {
  const QuotationsListPage({Key? key}) : super(key: key);

  @override
  QuotationsListPageState createState() => QuotationsListPageState();
}

class QuotationsListPageState extends State<QuotationsListPage> {
  late final QuotationController quotationController;
  late final StoreController storeController;
  String? _selectedStatus;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  void initState() {
    super.initState();
    try {
      quotationController = Get.find<QuotationController>();
    } catch (e) {
      quotationController = Get.put(QuotationController());
    }
    try {
      storeController = Get.find<StoreController>();
    } catch (e) {
      storeController = Get.put(StoreController());
    }

    _loadQuotations();
  }

  void _loadQuotations() {
    final storeId = storeController.currentStore?['_id'];
    if (storeId != null) {
      quotationController.fetchQuotations(
        storeId: storeId,
        status: _selectedStatus,
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
      );
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
      _loadQuotations();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
      _loadQuotations();
    }
  }

  String _getStatusLabel(String status) {
    final labels = {
      'pending': 'Pendiente',
      'converted': 'Convertida',
      'expired': 'Expirada',
      'cancelled': 'Cancelada',
    };
    return labels[status] ?? status;
  }

  Color _getStatusColor(String status) {
    final colors = {
      'pending': Colors.orange,
      'converted': Colors.green,
      'expired': Colors.red,
      'cancelled': Colors.grey,
    };
    return colors[status] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: const Text('Cotizaciones'),
        backgroundColor: Utils.colorGnav,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Status filter
                DropdownButton<String?>(
                  value: _selectedStatus,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los estados'),
                    ),
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pendiente', style: TextStyle(color: Colors.orange)),
                    ),
                    DropdownMenuItem(
                      value: 'converted',
                      child: Text('Convertida', style: TextStyle(color: Colors.green)),
                    ),
                    DropdownMenuItem(
                      value: 'expired',
                      child: Text('Expirada', style: TextStyle(color: Colors.red)),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelada', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _loadQuotations();
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 12),
                // Date range filter
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectStartDate(context),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _selectedStartDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedStartDate!)
                              : 'Desde',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectEndDate(context),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _selectedEndDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
                              : 'Hasta',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedStartDate = null;
                          _selectedEndDate = null;
                          _selectedStatus = null;
                        });
                        _loadQuotations();
                      },
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Limpiar filtros',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Cotizaciones list
          Expanded(
            child: Obx(() {
              if (quotationController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (quotationController.quotations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay cotizaciones',
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
                itemCount: quotationController.quotations.length,
                itemBuilder: (context, index) {
                  final quotation = quotationController.quotations[index];
                  return _buildQuotationCard(quotation);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotationCard(Quotation quotation) {
    final statusColor = _getStatusColor(quotation.status);
    final statusLabel = _getStatusLabel(quotation.status);
    final isConverted = quotation.status == 'converted';
    final isPending = quotation.status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quotation.customerName ?? 'Cliente General',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(quotation.quotationDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _generateQuotationPdf(quotation),
                      icon: const Icon(Icons.file_download),
                      iconSize: 20,
                      tooltip: 'Descargar PDF',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Items
            if (quotation.items.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Productos (${quotation.items.length}):',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...quotation.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.productName ?? item.productId ?? 'Producto',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.quantity}x',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            // Total
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Utils.colorBotones.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Bs. ${quotation.totalQuotation.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Utils.colorBotones,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                if (isPending)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _convertToOrder(quotation.id!),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text(
                        'Convertir a Venta',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                if (isPending) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteQuotation(quotation.id!),
                    icon: const Icon(Icons.delete, size: 16),
                    label: Text(isPending ? 'Cancelar' : 'Eliminar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPending ? Colors.red : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _convertToOrder(String quotationId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convertir a Venta'),
        content: const Text('¿Deseas convertir esta cotización a una venta? Se descontará el stock y se registrarán los puntos del cliente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Pedir método de pago antes de convertir
              if (!mounted) return;
              
              final paymentMethod = await showDialog<String?>(
                context: context,
                builder: (BuildContext context) {
                  final methods = ['efectivo', 'tarjeta', 'transferencia', 'otro'];
                  return SimpleDialog(
                    title: const Text('Método de Pago'),
                    children: methods
                        .map((method) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, method),
                              child: Text(method.toUpperCase()),
                            ))
                        .toList(),
                  );
                },
              );
              
              // Si no seleccionó método de pago, cancelar
              if (paymentMethod == null) return;
              
              try {
                await quotationController.convertQuotationToOrder(
                  quotationId,
                  paymentMethod: paymentMethod,
                );
                
                // Recargar productos para actualizar el stock
                try {
                  final productController = Get.find<ProductController>();
                  await productController.loadProductsForCurrentStore();
                } catch (e) {
                  // Si no hay ProductController registrado, no hace nada
                }
                
                // Recargar órdenes para mostrar la nueva orden
                try {
                  final orderController = Get.find<OrderController>();
                  await orderController.loadOrders();
                } catch (e) {
                  // Si no hay OrderController registrado, no hace nada
                }
                
                Get.snackbar(
                  'Éxito',
                  'Cotización convertida a venta exitosamente',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                _loadQuotations();
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Error al convertir cotización: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Convertir'),
          ),
        ],
      ),
    );
  }

  void _deleteQuotation(String quotationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cotización'),
        content: const Text('¿Estás seguro que deseas cancelar esta cotización?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await quotationController.deleteQuotation(quotationId);
                Get.snackbar(
                  'Éxito',
                  'Cotización cancelada',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                _loadQuotations();
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Error al cancelar cotización: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateQuotationPdf(Quotation quotation) async {
    try {
      Get.snackbar(
        'Generando',
        'Por favor espera...',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );

      // Convertir la cotización a un mapa para pasar al servicio PDF
      final quotationMap = {
        'storeId': quotation.storeId,
        'quotationDate': quotation.quotationDate.toIso8601String(),
        'status': quotation.status,
        'customerName': quotation.customerName,
        'items': quotation.items.map((item) => {
          'productId': item.productId,
          'productName': item.productName,
          'quantity': item.quantity,
          'price': item.price,
        }).toList(),
        'discountAmount': quotation.discountAmount,
        'totalQuotation': quotation.totalQuotation,
      };

      await PdfService.generateQuotationPdf(
        quotation: quotationMap,
      );

      Get.snackbar(
        'Éxito',
        'PDF descargado correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al generar PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}