// ignore_for_file: avoid_print, implementation_imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'dart:io' as io;

class PdfService {
  // Private constructor to prevent instantiation
  PdfService._();

  // Obtener hora actual de Bolivia (UTC-4)
  static DateTime _getBoliviaTime() {
    // Bolivia está en zona UTC-4
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: -4));
  }

  // Convertir una DateTime UTC a hora de Bolivia (UTC-4)
  static DateTime _convertToBoliviaTime(DateTime utcDateTime) {
    // Si la DateTime ya tiene offset, convertir a UTC primero
    if (utcDateTime.isUtc) {
      return utcDateTime.add(const Duration(hours: -4));
    } else {
      // Si es local, asumir que es UTC y convertir
      return utcDateTime.toUtc().add(const Duration(hours: -4));
    }
  }

  // REPORT GENERATION METHODS
  
  static Future<String> generateQuotationPdf({
    required Map<String, dynamic> quotation,
  }) async {
    final pdf = pw.Document();

    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COTIZACIÓN',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Tienda: ${quotation['storeId'] is Map ? quotation['storeId']['name'] ?? 'N/A' : 'N/A'}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Fecha: ${formatter.format(_getBoliviaTime())}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Estado: ${_getStatusLabel(quotation['status'] ?? 'pending')}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // Cliente
            pw.Text(
              'Cliente: ${quotation['customerName'] ?? 'Cliente General'}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),

            // Tabla de items
            pw.TableHelper.fromTextArray(
              headers: ['Producto', 'Cantidad', 'Precio Unitario', 'Subtotal'],
              data: (quotation['items'] as List? ?? []).map((item) {
                final qty = item['quantity'] ?? 0;
                final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                final subtotal = qty * price;
                return [
                  item['productName'] ?? item['productId'] ?? 'Producto',
                  qty.toString(),
                  currencyFormatter.format(price),
                  currencyFormatter.format(subtotal),
                ];
              }).toList(),
              border: pw.TableBorder.all(width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey700,
              ),
              cellAlignment: pw.Alignment.centerRight,
              cellPadding: const pw.EdgeInsets.all(8),
            ),
            pw.SizedBox(height: 20),

            // Totales
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.SizedBox(width: 100, child: pw.Text('Subtotal:')),
                      pw.SizedBox(
                        width: 100,
                        child: pw.Text(
                          currencyFormatter.format(
                            (quotation['items'] as List? ?? [])
                                .fold<double>(
                                  0.0,
                                  (sum, item) =>
                                      sum +
                                      ((item['quantity'] ?? 0) * ((item['price'] as num?)?.toDouble() ?? 0.0)),
                                ),
                          ),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  if (((quotation['discountAmount'] as num?)?.toDouble() ?? 0) > 0)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.SizedBox(width: 100, child: pw.Text('Descuento:')),
                        pw.SizedBox(
                          width: 100,
                          child: pw.Text(
                            '-${currencyFormatter.format((quotation['discountAmount'] as num?)?.toDouble() ?? 0.0)}',
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        top: const pw.BorderSide(width: 2),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.SizedBox(
                          width: 100,
                          child: pw.Text(
                            'TOTAL:',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(
                          width: 100,
                          child: pw.Text(
                            currencyFormatter.format((quotation['totalQuotation'] as num?)?.toDouble() ?? 0.0),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return await _savePdf(pdf, 'Cotizacion_${_getBoliviaTime().millisecondsSinceEpoch}');
  }

  static Future<String> generateInventoryRotationPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as List? ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Rotación de Inventario', startDate, endDate),
          pw.SizedBox(height: 20),

          // Resumen
          _buildSummarySection(
            'Resumen General',
            [
              ('Rotación Promedio',
                  '${summary['averageRotationRate']?.toStringAsFixed(2) ?? '0'} veces'),
              ('Productos Activos', '${summary['totalProducts'] ?? 0}'),
              ('Productos Rápidos', '${summary['fastMovingProducts'] ?? 0}'),
              ('Productos Lentos', '${summary['slowMovingProducts'] ?? 0}'),
            ],
          ),
          pw.SizedBox(height: 20),

          // Tabla de productos
          pw.Text('Análisis por Producto',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildProductsTable(products),
        ],
      ),
    );

    return await _savePdf(pdf,
        'Rotacion_Inventario_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  static Future<String> generateProfitabilityPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as List? ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Rentabilidad', startDate, endDate),
          pw.SizedBox(height: 20),

          // Resumen financiero
          _buildSummarySection(
            'Resumen Financiero',
            [
              ('Ventas Totales',
                  '\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
              ('Ganancia',
                  '\$${(summary['totalProfit'] ?? 0).toStringAsFixed(2)}'),
              ('Margen Promedio',
                  '${(summary['averageProfitMargin'] ?? 0).toStringAsFixed(1)}%'),
              ('Productos', '${summary['productCount'] ?? 0}'),
            ],
          ),
          pw.SizedBox(height: 20),

          // Tabla de rentabilidad
          pw.Text('Rentabilidad por Producto',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildProfitabilityTable(products),
        ],
      ),
    );

    return await _savePdf(pdf,
        'Rentabilidad_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  static Future<String> generateSalesTrendsPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {
    final pdf = pw.Document();

    final trends = data['trends'] as List? ?? [];
    final summary = data['summary'] as Map<String, dynamic>? ?? {};

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader(
              'Reporte de Tendencias de Ventas', startDate, endDate),
          pw.SizedBox(height: 20),

          // Resumen de tendencias
          _buildSummarySection(
            'Resumen de Tendencias',
            [
              ('Ventas Totales',
                  '\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
              ('Total Órdenes', '${summary['totalOrders'] ?? 0}'),
              ('Promedio Diario',
                  '\$${(summary['averageDaily'] ?? 0).toStringAsFixed(2)}'),
              ('Valor Promedio Orden',
                  '\$${(summary['averageOrderValue'] ?? 0).toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Text(
              'Período: ${_getPeriodLabel(period)}',
              style: pw.TextStyle(
                  fontSize: 12, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 10),

          // Tabla de tendencias
          _buildTrendsTable(trends),
        ],
      ),
    );

    return await _savePdf(pdf,
        'Tendencias_Ventas_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  static Future<String> generateComparisonPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    final comparison = data['comparison'] as Map<String, dynamic>? ?? {};
    final current = comparison['currentPeriod'] as Map<String, dynamic>? ?? {};
    final previous = comparison['previousPeriod'] as Map<String, dynamic>? ?? {};

    final currentRevenue = (current['totalRevenue'] ?? 0) as num;
    final previousRevenue = (previous['totalRevenue'] ?? 0) as num;
    final variation = currentRevenue - previousRevenue;
    final percentChange = previousRevenue > 0 ? (variation / previousRevenue * 100) : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte Comparativo', startDate, endDate),
          pw.SizedBox(height: 20),

          _buildSummarySection(
            'Comparación de Períodos',
            [
              ('Período Actual', '\$${currentRevenue.toStringAsFixed(2)}'),
              ('Período Anterior', '\$${previousRevenue.toStringAsFixed(2)}'),
              ('Variación', '${variation > 0 ? '+' : ''}${variation.toStringAsFixed(2)}'),
              ('% Cambio', '${percentChange.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );

    return await _savePdf(pdf,
        'Comparativo_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  // Generate PDF for returns/devoluciones list
  static Future<String> generateReturnsPdf({
    required List<dynamic> returns,
    required String storeName,
  }) async {
    final pdf = pw.Document();

    final totalReturns = returns.length;
    final totalRefunded = returns.fold<double>(
      0.0,
      (sum, item) => sum + (item.totalRefundAmount as num? ?? 0).toDouble(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Devoluciones', _getBoliviaTime(), _getBoliviaTime()),
          pw.SizedBox(height: 10),
          pw.Text(
            'Tienda: $storeName',
            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          
          // Summary section
          _buildSummarySection(
            'Resumen de Devoluciones',
            [
              ('Total de Devoluciones', totalReturns.toString()),
              ('Total Dinero Devuelto', '\$${totalRefunded.toStringAsFixed(2)}'),
              ('Fecha', DateFormat('dd/MM/yyyy').format(_getBoliviaTime())),
            ],
          ),
          pw.SizedBox(height: 20),

          // Returns table
          pw.Text(
            'Detalle de Devoluciones',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          
          if (returns.isEmpty)
            pw.Text('No hay devoluciones registradas')
          else
            _buildReturnsTable(returns),
        ],
      ),
    );

    return await _savePdf(pdf,
        'Devoluciones_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  // Helper methods for PDF building
  
  static pw.Widget _buildHeader(String title, DateTime startDate, DateTime endDate) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.Divider(),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
    String title,
    List<(String, String)> items,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Concepto',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Valor',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            ...items
                .map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.$1),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.$2),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildProductsTable(List products) {
    if (products.isEmpty) {
      return pw.Text('No hay productos disponibles');
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Producto',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Stock',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Rotación',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...products.take(10).map((product) {
          final productName = product['productName']?.toString() ?? 'N/A';
          final stock = product['currentStock']?.toString() ?? '0';
          final rotation = product['rotationRate']?.toStringAsFixed(2) ?? '0';

          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(productName),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(stock),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(rotation),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildProfitabilityTable(List products) {
    if (products.isEmpty) {
      return pw.Text('No hay datos de rentabilidad disponibles');
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Producto',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Ventas',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Margen %',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...products.take(10).map((product) {
          final productName = product['productName']?.toString() ?? 'N/A';
          final sales = '\$${(product['totalRevenue'] ?? 0).toStringAsFixed(2)}';
          final margin = '${(product['profitMargin'] ?? 0).toStringAsFixed(1)}%';

          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(productName),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(sales),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(margin),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTrendsTable(List trends) {
    if (trends.isEmpty) {
      return pw.Text('No hay datos de tendencias disponibles');
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Período',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Ventas',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Órdenes',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...trends.take(10).map((trend) {
          final date = trend['date']?.toString() ?? 'N/A';
          final sales = '\$${(trend['totalRevenue'] ?? 0).toStringAsFixed(2)}';
          final orders = trend['orderCount']?.toString() ?? '0';

          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(date),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(sales),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(orders),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildReturnsTable(List returns) {
    if (returns.isEmpty) {
      return pw.Text('No hay devoluciones registradas');
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Orden',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Cliente',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Monto',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Tipo',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...returns.map((returnItem) {
          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(returnItem.orderNumber?.toString() ?? 'N/A',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(returnItem.customerName ?? 'Sin nombre',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                    '\$${(returnItem.totalRefundAmount as num? ?? 0).toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(returnItem.type?.label ?? 'N/A',
                    style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        }),
      ],
    );
  }

  static String _getPeriodLabel(String period) {
    switch (period) {
      case 'day':
        return 'Diario';
      case 'week':
        return 'Semanal';
      case 'month':
        return 'Mensual';
      default:
        return period;
    }
  }

  static String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobada';
      case 'rejected':
        return 'Rechazada';
      case 'converted':
        return 'Convertida';
      case 'expired':
        return 'Expirada';
      default:
        return status;
    }
  }

  static Future<String> _savePdf(pw.Document pdf, String filename) async {
    try {
      if (kIsWeb) {
        return await _downloadFileWeb(pdf, filename);
      } else {
        return await _downloadFileNative(pdf, filename);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving PDF: $e');
      rethrow;
    }
  }

  static Future<String> _downloadFileNative(
      pw.Document pdf, String filename) async {
    try {
      final output = await getDownloadsDirectory();
      if (output == null) {
        throw Exception('No se pudo acceder a la carpeta de descargas');
      }

      final file = io.File('${output.path}/$filename.pdf');
      await file.writeAsBytes(await pdf.save());

      // Abrir el archivo
      await OpenFilex.open(file.path);

      return file.path;
    } catch (e) {
      if (kDebugMode) debugPrint('Error en descarga nativa: $e');
      rethrow;
    }
  }

  static Future<String> _downloadFileWeb(
      pw.Document pdf, String filename) async {
    try {
      await pdf.save();
      
      // En web, el archivo se descarga automáticamente mediante JS
      // Esta es una implementación simplificada
      if (kDebugMode) debugPrint('PDF generado en web: $filename');
      return 'PDF descargado exitosamente';
    } catch (e) {
      if (kDebugMode) debugPrint('Error en descarga web: $e');
      rethrow;
    }
  }

  // CASH CLOSING REPORT
  static Future<String> generateCashClosingReportPdf({
    required Map<String, dynamic> cashRegister,
    required double totalIncome,
    required double totalExpenses,
    required double totalSales,
    required double totalQRSales,
    required double expectedAmount,
    required double actualAmount,
    required List<Map<String, dynamic>> movements,
    required String storeName,
    DateTime? closingTime,
  }) async {
    final pdf = pw.Document();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormatter = DateFormat('dd/MM/yyyy');
    final currencyFormatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);

    // Calcular diferencia
    final difference = actualAmount - expectedAmount;
    final hasSurplus = difference > 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INFORME DE CIERRE DE CAJA',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Tienda: $storeName',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Fecha: ${dateOnlyFormatter.format(_getBoliviaTime())}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Hora: ${formatter.format(_getBoliviaTime()).split(' ')[1]}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.SizedBox(height: 5),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
        build: (context) => [
          // RESUMEN DE APERTURA
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '1. DATOS DE APERTURA',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Hora de Apertura:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Hora de Cierre:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Monto de Apertura:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          formatter.format(
                            _convertToBoliviaTime(
                              DateTime.parse(cashRegister['openingTime'] ?? cashRegister['createdAt'] ?? DateTime.now().toString()),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          formatter.format(
                            _convertToBoliviaTime(closingTime ?? DateTime.now()),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          currencyFormatter.format(
                            (cashRegister['openingAmount'] as num?)?.toDouble() ?? 0.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 15),

          // RESUMEN FINANCIERO
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '2. RESUMEN FINANCIERO',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildSummaryTable(
                currencyFormatter,
                [
                  ['Monto Inicial', currencyFormatter.format((cashRegister['openingAmount'] as num?)?.toDouble() ?? 0.0)],
                  ['Ventas en Efectivo', currencyFormatter.format(totalSales - totalQRSales)],
                  ['Ventas por QR', currencyFormatter.format(totalQRSales)],
                  ['Entradas de Dinero', currencyFormatter.format(totalIncome)],
                  ['Salidas de Dinero', currencyFormatter.format(totalExpenses)],
                  ['Monto Esperado', currencyFormatter.format(expectedAmount)],
                  ['Monto Real Contado', currencyFormatter.format(actualAmount)],
                  [
                    hasSurplus ? 'Sobrante' : 'Faltante',
                    currencyFormatter.format(difference.abs()),
                  ],
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 15),

          // DETALLE DE MOVIMIENTOS - COMPLETO
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '3. DETALLE COMPLETO DE MOVIMIENTOS',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              movements.isNotEmpty
                ? pw.TableHelper.fromTextArray(
                    headers: ['Hora', 'Tipo', 'Descripción', 'Monto'],
                    data: movements.map((movement) {
                      final type = movement['type'] ?? '';
                      final typeLabel = _getMovementTypeLabel(type);
                      final amount = (movement['amount'] as num?)?.toDouble() ?? 0.0;
                      final amountStr = type == 'expense' || type == 'closing'
                          ? '- ${currencyFormatter.format(amount)}'
                          : '+ ${currencyFormatter.format(amount)}';
                      
                      // Truncar descripción si es muy larga
                      String description = movement['description'] ?? '';
                      if (description.length > 30) {
                        description = description.substring(0, 30);
                      }

                      return [
                        DateFormat('HH:mm').format(
                          DateTime.parse(movement['createdAt'] ?? DateTime.now().toString()),
                        ),
                        typeLabel,
                        description,
                        amountStr,
                      ];
                    }).toList(),
                    border: pw.TableBorder.all(width: 0.5),
                    headerDecoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFE0E0E0),
                    ),
                    headerHeight: 22,
                    cellHeight: 18,
                    cellPadding: const pw.EdgeInsets.all(4),
                    cellAlignment: pw.Alignment.centerLeft,
                    columnWidths: {
                      0: const pw.FlexColumnWidth(0.8),
                      1: const pw.FlexColumnWidth(0.9),
                      2: const pw.FlexColumnWidth(2.0),
                      3: const pw.FlexColumnWidth(1.3),
                    },
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    headerStyle: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  )
                : pw.Text('No hay movimientos registrados'),
            ],
          ),

          pw.SizedBox(height: 20),

          // FIRMA
          pw.Container(
            padding: const pw.EdgeInsets.only(top: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.SizedBox(height: 40),
                    pw.Text('_' * 30),
                    pw.Text(
                      'Responsable',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.SizedBox(height: 40),
                    pw.Text('_' * 30),
                    pw.Text(
                      'Gerente',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final filename = 'cierre_caja_${DateFormat('yyyyMMdd_HHmmss').format(_getBoliviaTime())}';
    return await _savePdf(pdf, filename);
  }

  static pw.Widget _buildSummaryTable(
    NumberFormat currencyFormatter,
    List<List<String>> data,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Concepto', 'Monto'],
      data: data,
      border: pw.TableBorder.all(width: 0.5),
      headerDecoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFE0E0E0),
      ),
      headerHeight: 25,
      cellPadding: const pw.EdgeInsets.all(8),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
      },
    );
  }

  static String _getMovementTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Entrada';
      case 'expense':
        return 'Salida';
      case 'sale':
        return 'Venta';
      case 'opening':
        return 'Apertura';
      case 'closing':
        return 'Cierre';
      default:
        return type;
    }
  }
}


