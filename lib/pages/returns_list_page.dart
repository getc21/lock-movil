import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/returns/returns_controller.dart';
import '../../controllers/store_controller.dart';
import '../../controllers/product_controller.dart';
import '../../models/returns/return_models.dart';
import '../../services/pdf_service.dart';
import '../../utils/utils.dart';

class ReturnsListPage extends StatefulWidget {
  const ReturnsListPage({Key? key}) : super(key: key);

  @override
  ReturnsListPageState createState() => ReturnsListPageState();
}

class ReturnsListPageState extends State<ReturnsListPage> {
  late final ReturnsController controller;
  late final StoreController storeController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<ReturnsController>();
    } catch (e) {
      controller = Get.put(ReturnsController());
    }
    try {
      storeController = Get.find<StoreController>();
    } catch (e) {
      storeController = Get.put(StoreController());
    }
    _loadReturns();
  }

  void _loadReturns() {
    final storeId = storeController.currentStore?['_id'];
    if (storeId != null) {
      // Ajustar fechas: inicio a 00:00 y fin a 23:59
      DateTime? adjustedStartDate = _startDate != null
          ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day, 0, 0, 0)
          : null;
      DateTime? adjustedEndDate = _endDate != null
          ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
          : null;

      controller.fetchReturns(
        storeId: storeId,
        startDate: adjustedStartDate,
        endDate: adjustedEndDate,
      );
    } else {
      Get.snackbar('Error', 'No hay tienda seleccionada');
    }
  }

  void _resetAndReload() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadReturns();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Devoluciones'),
        backgroundColor: Utils.colorGnav,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _generateAndPrintPDF(),
            tooltip: 'Imprimir PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAndReload,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de fechas
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectStartDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Desde',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : 'Seleccionar',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _selectEndDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hasta',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            _endDate != null
                                ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                : 'Seleccionar',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadReturns,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Utils.colorBotones,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Filtrar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              // Validar que hay tienda seleccionada
              if (storeController.currentStore == null) {
                return const Center(child: Text('No hay tienda seleccionada'));
              }

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error.value != null) {
                return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Error al cargar devoluciones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Error: ${controller.error.value}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadReturns,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (controller.returns.isEmpty) {
          return SizedBox(
            height: 400,
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay devoluciones registradas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Las devoluciones que crees aparecerán aquí',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Resumen simplificado
            if (controller.summary.value != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Total de Devoluciones',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              controller.summary.value!['total'].toString(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Total Dinero Devuelto',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${controller.returns.fold<double>(0.0, (sum, item) => sum + item.totalRefundAmount).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            // Lista de devoluciones
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Devoluciones Registradas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...controller.returns.map(
              (returnRequest) => ReturnRequestCard(
                returnRequest: returnRequest,
                onPrintPdf: () => _generatePDFForSingleReturn(returnRequest),
              ),
            ),
            ],
          );
            }),
          ),
        ],
      ),
    );
  }

  // Generar e imprimir PDF de una devolución específica
  Future<void> _generatePDFForSingleReturn(ReturnRequest returnRequest) async {
    try {
      Get.snackbar(
        'Procesando',
        'Generando PDF...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      final storeName = storeController.currentStore?['name'] ?? 'Tienda';
      final returns = [returnRequest];

      await PdfService.generateReturnsPdf(
        returns: returns,
        storeName: storeName,
      );

      Get.snackbar(
        'Éxito',
        'PDF generado exitosamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      String errorMessage = 'Error al generar PDF';

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('path') ||
          errorStr.contains('storage') ||
          errorStr.contains('almacenamiento')) {
        errorMessage =
            'No se pudo acceder al almacenamiento. Verifica los permisos.';
      } else if (errorStr.contains('socket') ||
          errorStr.contains('connection')) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      } else if (errorStr.contains('permission')) {
        errorMessage = 'Permiso denegado. Habilita permisos de almacenamiento.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Generar e imprimir PDF de todas las devoluciones
  Future<void> _generateAndPrintPDF() async {
    try {
      Get.snackbar(
        'Procesando',
        'Generando PDF...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      // Preparar datos para el PDF
      final returns = controller.returns;
      final storeName = storeController.currentStore?['name'] ?? 'Tienda';

      if (returns.isEmpty) {
        Get.snackbar(
          'Error',
          'No hay devoluciones para generar PDF',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Llamar al servicio PDF con los datos de devoluciones
      // Formato similar al que usa el frontend
      await PdfService.generateReturnsPdf(
        returns: returns,
        storeName: storeName,
      );

      Get.snackbar(
        'Éxito',
        'PDF generado exitosamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      String errorMessage = 'Error al generar PDF';

      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('path') ||
          errorStr.contains('storage') ||
          errorStr.contains('almacenamiento')) {
        errorMessage =
            'No se pudo acceder al almacenamiento. Verifica los permisos.';
      } else if (errorStr.contains('socket') ||
          errorStr.contains('connection')) {
        errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
      } else if (errorStr.contains('permission')) {
        errorMessage = 'Permiso denegado. Habilita permisos de almacenamiento.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class ReturnItemsList extends StatelessWidget {
  final List<ReturnItem> items;

  const ReturnItemsList({required this.items, Key? key}) : super(key: key);

  String _getProductName(String productId) {
    try {
      final productController = Get.find<ProductController>();
      final product = productController.products.firstWhereOrNull(
        (p) => p['_id'] == productId,
      );
      return product?['name'] ?? productId;
    } catch (e) {
      return productId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Items: ${items.map((item) => '${_getProductName(item.productId)} x${item.returnQuantity}').join(', ')}',
      style: const TextStyle(
        fontSize: 10,
        color: Colors.grey,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class ReturnRequestCard extends StatelessWidget {
  final ReturnRequest returnRequest;
  final VoidCallback? onPrintPdf;

  const ReturnRequestCard({
    required this.returnRequest,
    this.onPrintPdf,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: Orden + Monto + Icono imprimir
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${returnRequest.orderNumber ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        returnRequest.customerName ?? 'Cliente general',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${returnRequest.totalRefundAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.print_outlined, size: 18),
                  onPressed: onPrintPdf,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fila 2: Tipo | Razón | Método
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactInfo('Tipo', returnRequest.type.label, 10),
                _buildCompactInfo('Razón', returnRequest.returnReasonCategory.label, 10),
                _buildCompactInfo('Método', returnRequest.refundMethod.label, 10),
              ],
            ),
            const SizedBox(height: 8),
            // Fila 3: Artículos compactos
            ReturnItemsList(items: returnRequest.items),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize + 1,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}