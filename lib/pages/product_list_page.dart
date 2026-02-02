import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/auth_controller.dart';
import 'package:bellezapp/pages/add_product_page.dart';
import 'package:bellezapp/pages/edit_product_page.dart';
import 'package:bellezapp/services/permissions_service.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  ProductListPageState createState() => ProductListPageState();
}

class ProductListPageState extends State<ProductListPage> {
  // Usar la misma instancia del controlador que ya existe
  late final ProductController productController;
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  String _activeFilter = 'todos';
  final Map<String, bool> _expandedBadges =
      {}; // Para controlar qué badges están expandidos

  @override
  void initState() {
    super.initState();
    // Inicializar notificaciones
    _initializeNotifications();

    // ⭐ PEDIR PERMISOS DE NOTIFICACIÓN EN ANDROID 13+
    _requestNotificationPermissions();

    // Intentar obtener una instancia existente, o crear una nueva si no existe
    try {
      productController = Get.find<ProductController>();
    } catch (e) {
      productController = Get.put(ProductController());
    }

    // Ejecutar después del primer frame para evitar setState durante build
    // Solo cargar si la lista está vacía
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (productController.products.isEmpty) {
        _loadProducts();
      }
    });
  }

  void _loadProducts() {
    // ⭐ SIEMPRE cargar productos de la tienda actual
    productController.loadProductsForCurrentStore();
  }

  /// ⭐ Pedir permisos de notificación en Android 13+ (API 33+)
  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? grantedNotificationPermission = await androidImplementation
          ?.requestNotificationsPermission();

      log(
        '[NOTIF] Permiso de notificación otorgado: $grantedNotificationPermission',
      );
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    final searchText = _searchController.text.toLowerCase();
    var products = productController.products;

    // Aplicar búsqueda
    if (searchText.isNotEmpty) {
      products = products.where((product) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '')
            .toString()
            .toLowerCase();
        final category = (product['categoryId']?['name'] ?? '')
            .toString()
            .toLowerCase();
        final supplier = (product['supplierId']?['name'] ?? '')
            .toString()
            .toLowerCase();
        final location = (product['locationId']?['name'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(searchText) ||
            description.contains(searchText) ||
            category.contains(searchText) ||
            supplier.contains(searchText) ||
            location.contains(searchText);
      }).toList();
    }

    // Aplicar filtro de stock bajo (≤3 unidades, como en web)
    if (_activeFilter == 'stock') {
      products = products.where((product) {
        final stock = product['stock'] ?? 0;
        return stock <= 3;
      }).toList();
    }

    // Aplicar filtro de próximo a vencer (<60 días, como en web)
    if (_activeFilter == 'expiry') {
      products = products.where((product) {
        final expiryDate = DateTime.tryParse(
          product['expiryDate']?.toString() ?? '',
        );
        return expiryDate != null &&
            expiryDate.difference(DateTime.now()).inDays < 60;
      }).toList();
    }

    return products;
  }

  String _getImageUrl(Map<String, dynamic> product) {
    final foto = product['foto'];
    if (foto == null || foto.toString().isEmpty) {
      return '';
    }
    // La foto ya es una URL completa de Cloudinary
    return foto.toString();
  }

  void _showAddStockDialog(String productId, String productName) {
    final stockController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Utils.colorBotones.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono animado
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Utils.colorBotones.withValues(alpha: 0.8),
                              Utils.colorBotones,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Utils.colorBotones.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24),

                      // Título
                      Text(
                        'Añadir Stock',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Nombre del producto
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Utils.colorBotones.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: Utils.colorBotones,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                productName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Utils.colorBotones,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Campo de cantidad con diseño moderno
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextFormField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          cursorColor: Utils.colorBotones,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Utils.colorBotones,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Icon(
                                Icons.add_circle_outline,
                                color: Utils.colorBotones,
                                size: 32,
                              ),
                            ),
                            suffixText: 'unidades',
                            suffixStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            hintText: '0',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 32,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa una cantidad';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Cantidad debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16),

                      // Campo de precio de compra unitario
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          cursorColor: Utils.colorBotones,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Utils.colorBotones,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Icon(
                                Icons.attach_money,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            prefixText: 'Bs. ',
                            prefixStyle: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            hintText: 'Precio unitario',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa el precio de compra';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Precio debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 8),

                      // Texto de ayuda
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Este será registrado como inversión en inventario',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),

                      // Botones con diseño moderno
                      Row(
                        children: [
                          // Botón Cancelar
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),

                          // Botón Añadir
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    Utils.colorBotones,
                                    Utils.colorBotones.withValues(alpha: 0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Utils.colorBotones.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    final stockToAdd = int.parse(
                                      stockController.text,
                                    );
                                    final purchasePrice = double.parse(
                                      priceController.text,
                                    );
                                    Navigator.of(context).pop();

                                    final success = await productController
                                        .updateStock(
                                          id: productId,
                                          quantity: stockToAdd,
                                          operation: 'add',
                                          purchasePrice: purchasePrice,
                                        );

                                    if (success) {
                                      _loadProducts();
                                      // Mostrar snackbar de éxito
                                      Get.snackbar(
                                        'Stock Actualizado',
                                        'Se agregaron $stockToAdd unidades correctamente',
                                        snackPosition: SnackPosition.TOP,
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                        icon: Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                        duration: Duration(seconds: 2),
                                      );
                                    }
                                  }
                                },
                                icon: Icon(Icons.add_shopping_cart, size: 20),
                                label: Text(
                                  'Añadir Stock',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateAndShowPdf(
    BuildContext context,
    String productName,
  ) async {
    try {
      // Crear un widget con el QR
      final qrKey = GlobalKey<State<StatefulWidget>>();

      // Mostrar diálogo con el QR mientras se genera
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Generando código QR...'),
          content: SizedBox(
            width: 250,
            height: 250,
            child: Center(
              child: _QRCodeWidget(key: qrKey, data: productName),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _saveQRAsImage(qrKey, productName);
              },
              icon: const Icon(Icons.download),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Utils.colorBotones,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      log('Error generating QR: $e');
      Get.snackbar(
        'Error',
        'No se pudo generar el código QR',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _saveQRAsImage(GlobalKey key, String productName) async {
    try {
      log('🟡 [QR] Verificando permisos de almacenamiento...');
      
      // Verificar y solicitar permisos
      final hasPermission = await PermissionsService.hasStoragePermissions();
      if (!hasPermission) {
        log('🟡 [QR] Solicitando permisos...');
        final granted = await PermissionsService.requestStoragePermissions();
        
        if (!granted) {
          log('❌ [QR] Permisos denegados');
          Get.snackbar(
            'Permisos Requeridos',
            'Se necesitan permisos de almacenamiento para guardar el QR.\nVe a Configuración > Permisos > Almacenamiento',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
            mainButton: TextButton(
              onPressed: () {
                PermissionsService.openAppSettings();
              },
              child: const Text('Abrir Configuración'),
            ),
          );
          return;
        }
        log('✅ [QR] Permisos otorgados');
      }

      log('🟡 [QR] Obteniendo RenderRepaintBoundary...');
      // Obtener el RenderRepaintBoundary
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Get.snackbar(
          'Error',
          'No se pudo obtener la imagen del QR',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      log('🟡 [QR] Renderizando imagen...');
      // Renderizar la imagen
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('No se pudo convertir a bytes');
      }

      log('🟡 [QR] Obteniendo directorio de descargas...');
      // Obtener directorio de Descargas
      Directory? downloadDir;
      
      if (Platform.isAndroid) {
        try {
          // Usar getDownloadsDirectory() para obtener el directorio de descargas
          downloadDir = await getDownloadsDirectory();
          if (downloadDir == null) {
            // Fallback a app-specific directory
            final appDocDir = await getApplicationDocumentsDirectory();
            downloadDir = Directory('${appDocDir.path}/QR_Codes');
          }
        } catch (e) {
          // Fallback: usar app-specific directory
          final appDocDir = await getApplicationDocumentsDirectory();
          downloadDir = Directory('${appDocDir.path}/QR_Codes');
        }
      } else {
        // iOS
        final appDocDir = await getApplicationDocumentsDirectory();
        downloadDir = Directory('${appDocDir.path}/QR_Codes');
      }

      // Crear carpeta si no existe
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Crear nombre de archivo con timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          '${productName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_$timestamp.png';
      final filePath = '${downloadDir.path}/$fileName';

      // Guardar archivo
      final file = File(filePath);
      String finalPath = filePath;
      try {
        await file.writeAsBytes(byteData.buffer.asUint8List());
      } on FileSystemException {
        // Fallback a app-specific directory si falla el acceso directo
        final appDocDir = await getApplicationDocumentsDirectory();
        final fallbackDir = Directory('${appDocDir.path}/QR_Codes');
        await fallbackDir.create(recursive: true);
        
        final fallbackPath = '${fallbackDir.path}/$fileName';
        final fallbackFile = File(fallbackPath);
        await fallbackFile.writeAsBytes(byteData.buffer.asUint8List());
        finalPath = fallbackPath;
      }

      // Mostrar notificación de Android con la ruta completa
      await _showQRNotification(fileName, finalPath);

      // Mostrar mensaje de éxito
      Get.snackbar(
        '✅ Éxito',
        'QR guardado en ${Platform.isAndroid ? 'Descargas' : 'Documentos'}\n$fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo guardar el QR: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _initializeNotifications() async {
    try {

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings androidInitSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        // ⭐ AGREGAR HANDLER PARA CUANDO EL USUARIO TOCA LA NOTIFICACIÓN
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // ⭐ Crear canal para Android 8.0+ (IMPORTANTE para Android 13+)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'qr_downloads',
        'Descargas de QR',
        description: 'Notificaciones cuando se guarda un QR',
        importance: Importance.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
      );

      final android = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (android != null) {
        await android.createNotificationChannel(channel);
      } else {
      }

    } catch (e, stack) {
      log('[NOTIF] ❌ Error inicializando notificaciones: $e');
      log('[NOTIF] Stack trace: $stack');
    }
  }

  Future<void> _showQRNotification(String fileName, String filePath) async {
    try {
      log('[NOTIF] Intentando mostrar notificación para: $fileName');

      // ⭐ Usar AndroidNotificationChannel (requerido para Android 8.0+)
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'qr_downloads', // Mismo ID del canal creado
            'Descargas de QR',
            channelDescription: 'Notificaciones cuando se guarda un QR',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            autoCancel: true,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        '📥 QR Descargado',
        'Archivo: $fileName',
        notificationDetails,
        payload: filePath, // Pasar la ruta completa como payload
      );
    } catch (e, stack) {
      log('[NOTIF] ❌ Error mostrando notificación: $e');
      log('[NOTIF] Stack trace: $stack');
    }
  }

  // ⭐ NUEVO: Handler para cuando el usuario toca la notificación
  void _handleNotificationTap(NotificationResponse response) async {
    try {

      final filePath = response.payload;
      if (filePath == null || filePath.isEmpty) {
        return;
      }

      // Verificar que el archivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        Get.snackbar('Error', 'El archivo QR no existe (puede haber sido eliminado)');
        return;
      }

      // ⭐ Abrir el archivo con la app de galería/visualizador de imágenes
      await OpenFilex.open(filePath);
    } catch (e, stack) {
      log('[NOTIF] ❌ Error manejando notificación: $e');
      log('[NOTIF] Stack trace: $stack');
      Get.snackbar('Error', 'Error al abrir el archivo: $e');
    }
  }

  void _deleteProduct(String productId, String productName) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar "$productName"?',
    );
    if (confirmed) {
      final result = await productController.deleteProduct(productId);
      if (result) {
        Get.snackbar(
          'Éxito',
          'Producto eliminado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadProducts();
      }
    }
  }

  Widget _buildInfoItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
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
                      'Productos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Row(
                      children: [
                        Obx(
                          () => Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Utils.colorBotones.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_filteredProducts.length} productos',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Utils.colorBotones,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),

                Row(
                  children: [
                    // Buscador expandible
                    Expanded(
                      child: Container(
                        height: 42,
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
                            hintText:
                                'Buscar productos por nombre, categoría, proveedor...',
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
                    ),
                    SizedBox(width: 10),
                    // Botón Stock crítico con Tooltip
                    Tooltip(
                      message: _activeFilter == 'stock'
                          ? 'Ver todos'
                          : 'Stock crítico (≤3)',
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeFilter = _activeFilter == 'stock'
                                ? 'todos'
                                : 'stock';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _activeFilter == 'stock'
                                ? Colors.red
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              if (_activeFilter == 'stock')
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Icon(
                            Icons.warning_amber_outlined,
                            color: _activeFilter == 'stock'
                                ? Colors.white
                                : Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Botón Vence pronto con Tooltip
                    Tooltip(
                      message: _activeFilter == 'expiry'
                          ? 'Ver todos'
                          : 'Vence pronto (<60 días)',
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeFilter = _activeFilter == 'expiry'
                                ? 'todos'
                                : 'expiry';
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _activeFilter == 'expiry'
                                ? Colors.orange
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              if (_activeFilter == 'expiry')
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Icon(
                            Icons.schedule_outlined,
                            color: _activeFilter == 'expiry'
                                ? Colors.white
                                : Colors.orange,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: Obx(() {
              if (productController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = _filteredProducts;

              if (products.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: (products.length / 2).ceil(),
                itemBuilder: (context, rowIndex) {
                  final leftIndex = rowIndex * 2;
                  final rightIndex = leftIndex + 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildProductCard(
                              products[leftIndex],
                              authController,
                            ),
                          ),
                          if (rightIndex < products.length) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildProductCard(
                                products[rightIndex],
                                authController,
                              ),
                            ),
                          ] else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Utils.colorBotones,
        onPressed: () async {
          final result = await Get.to(() => const AddProductPage());
          // Si result es true, significa que se creó un producto
          if (result == true) {
            _loadProducts();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    AuthController authController,
  ) {
    final productId = product['_id'] ?? '';
    final name = product['name'] ?? 'Sin nombre';
    final description = product['description'] ?? '';
    final stock = product['stock'] ?? 0;
    final salePrice = product['salePrice'] ?? 0.0;
    final purchasePrice = product['purchasePrice'] ?? 0.0;
    final weight = product['weight'] ?? '';
    final imageUrl = _getImageUrl(product);

    // Stock levels (matching web logic: ≤3 is critical)
    final isOutOfStock = stock <= 3;
    final isLowStock = stock > 3 && stock < 10;

    // Extraer nombres de relaciones
    final locationName = product['locationId'] is Map
        ? product['locationId']['name'] ?? 'Sin ubicación'
        : 'Sin ubicación';

    // Verificar fecha de vencimiento (matching web logic: <60 días es crítico)
    final expiryDate = DateTime.tryParse(
      product['expiryDate']?.toString() ?? '',
    );
    final daysToExpiry = expiryDate?.difference(DateTime.now()).inDays;
    final isNearExpiry = daysToExpiry != null && daysToExpiry < 60;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen con badges de estado
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                              'assets/img/perfume.webp',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/img/perfume.webp',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              // Badges de estado en la esquina superior derecha
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Badge de stock crítico (≤3)
                    if (isOutOfStock)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final key = '${productId}_stock';
                            _expandedBadges[key] =
                                !(_expandedBadges[key] ?? false);
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.white,
                                size: 10,
                              ),
                              if (_expandedBadges['${productId}_stock'] ??
                                  false) ...[
                                SizedBox(width: 3),
                                Text(
                                  'Stock crítico',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    // Badge de stock bajo (3-10)
                    if (isLowStock)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final key = '${productId}_lowstock';
                            _expandedBadges[key] =
                                !(_expandedBadges[key] ?? false);
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info, color: Colors.white, size: 10),
                              if (_expandedBadges['${productId}_lowstock'] ??
                                  false) ...[
                                SizedBox(width: 3),
                                Text(
                                  'Stock bajo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    if ((isOutOfStock || isLowStock) && isNearExpiry)
                      SizedBox(height: 3),
                    // Badge de caducidad próxima (<60 días)
                    if (isNearExpiry)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final key = '${productId}_expiry';
                            _expandedBadges[key] =
                                !(_expandedBadges[key] ?? false);
                          });
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color:
                                daysToExpiry < 60 &&
                                    daysToExpiry >= 0
                                ? (daysToExpiry < 30
                                      ? Colors.red
                                      : Colors.orange)
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.white,
                                size: 10,
                              ),
                              if (_expandedBadges['${productId}_expiry'] ??
                                  false) ...[
                                SizedBox(width: 3),
                                Text(
                                  'Vence pronto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // QR Code en la esquina superior izquierda
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: () {
                    _generateAndShowPdf(context, name);
                  },
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: BarcodeWidget(
                      backgroundColor: Colors.transparent,
                      barcode: Barcode.qrCode(),
                      data: name,
                      width: 21,
                      height: 21,
                    ),
                  ),
                ),
              ),
              // Botón de acciones en la parte inferior derecha
              Positioned(
                bottom: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Utils.edit, size: 18),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'add_stock',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, color: Utils.add, size: 18),
                          SizedBox(width: 12),
                          Text('Añadir Stock'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, color: Utils.delete, size: 18),
                          SizedBox(width: 12),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Get.to(
                        () => EditProductPage(product: product),
                      );
                      if (result == true) {
                        _loadProducts();
                      }
                    } else if (value == 'add_stock') {
                      _showAddStockDialog(productId, name);
                    } else if (value == 'delete') {
                      _deleteProduct(productId, name);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Utils.colorBotones.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Utils.colorBotones.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.more_vert, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          // Contenido de la card
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del producto
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorGnav,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                // Descripción
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 6),
                // Información principal en formato grid
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showMultiStoreStockDialog(product),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: _buildInfoItem(
                                  'Stock',
                                  '$stock',
                                  isOutOfStock
                                      ? Colors.red
                                      : isLowStock
                                      ? Colors.orange
                                      : Colors.green,
                                  Icons.inventory,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Ubicación',
                              locationName,
                              Colors.blue,
                              Icons.location_on,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Vencimiento',
                              expiryDate != null
                                  ? expiryDate.toLocal().toString().split(
                                      ' ',
                                    )[0]
                                  : 'Sin fecha',
                              _getExpirationColor(daysToExpiry),
                              Icons.schedule,
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Tamaño',
                              weight.isNotEmpty ? weight : 'Sin especificar',
                              Colors.purple,
                              Icons.straighten,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6),
                // Precios destacados
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Utils.colorBotones.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Utils.colorBotones.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      if (authController.isAdmin || authController.isManager)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Precio compra:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${purchasePrice.toStringAsFixed(2)} Bs.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Precio venta:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Utils.colorBotones,
                              ),
                            ),
                          ),
                          Text(
                            '${salePrice.toStringAsFixed(2)} Bs.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Utils.colorBotones,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String mensaje;
    IconData icono = Icons.inventory_2_outlined;

    if (_searchController.text.isNotEmpty) {
      mensaje = 'No se encontraron productos que coincidan con tu búsqueda.';
    } else if (_activeFilter == 'stock') {
      mensaje = 'No hay productos con stock bajo.';
    } else if (_activeFilter == 'expiry') {
      mensaje = 'No hay productos próximos a vencer.';
    } else {
      mensaje =
          'No hay productos registrados. Agrega tu primer producto usando el botón "+".';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Utils.colorBotones.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 80, color: Utils.colorBotones),
          ),
          const SizedBox(height: 24),
          Text(
            'Sin Productos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Utils.colorTexto,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Utils.colorTexto.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Utils.colorBotones,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo con stock en todas las tiendas
  void _showMultiStoreStockDialog(Map<String, dynamic> product) {
    final productId = product['_id'];
    bool isLoading = true;
    List<Map<String, dynamic>> stocks = [];
    String? errorMessage;

    // Verificar si el usuario es empleado (solo ve sucursal y stock)
    final userRole = authController.userRole;
    final isEmployee = userRole == 'employee' || userRole == 'empleado';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Cargar datos solo una vez
          if (isLoading && stocks.isEmpty && errorMessage == null) {
            _loadMultiStoreStocks(productId, () {}, (newStocks, error) {
              setState(() {
                isLoading = false;
                if (error != null) {
                  errorMessage = error;
                } else {
                  stocks = newStocks;
                }
              });
            });
          }

          return Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 320,
                maxWidth: 500,
                minHeight: 200,
                maxHeight: 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Utils.colorBotones,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Stock en Todas las Tiendas',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Contenido
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : stocks.isEmpty
                        ? const Center(child: Text('Sin datos de stock'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: stocks.map((stock) {
                                final storeName =
                                    stock['storeName'] ?? 'Sin tienda';
                                final stockQty = stock['stock'] ?? 0;
                                final salePrice = stock['salePrice'] ?? 0.0;
                                final purchasePrice =
                                    stock['purchasePrice'] ?? 0.0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        storeName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Stock:',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          Text(
                                            '$stockQty',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: stockQty <= 0
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Solo mostrar precios si NO es empleado
                                      if (!isEmployee) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Precio Venta:',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                            Text(
                                              '${salePrice.toStringAsFixed(2)} Bs.',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Precio Compra:',
                                              style: TextStyle(fontSize: 13),
                                            ),
                                            Text(
                                              '${purchasePrice.toStringAsFixed(2)} Bs.',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Cargar stock de múltiples tiendas
  Future<void> _loadMultiStoreStocks(
    String productId,
    VoidCallback onLoadComplete,
    Function(List<Map<String, dynamic>>, String?) callback,
  ) async {
    try {
      final result = await productController.getProductStocks(productId);

      if (result != null && result['success']) {
        final stocks = (result['data'] as List).cast<Map<String, dynamic>>();
        callback(stocks, null);
      } else {
        callback([], result?['message'] ?? 'Error cargando stock');
      }
    } catch (e) {
      callback([], 'Error de conexión: $e');
    } finally {
      onLoadComplete();
    }
  }

  /// Get expiration color based on days until expiry (matching web logic)
  /// <60 días = rojo (crítico)
  /// <90 días = naranja (atención)
  /// resto = gris
  Color _getExpirationColor(int? daysToExpiry) {
    if (daysToExpiry == null) return Colors.grey;

    if (daysToExpiry < 60) {
      return Colors.red;
    } else if (daysToExpiry < 90) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Widget para mostrar el QR con borde para facilitar el renderizado
class _QRCodeWidget extends StatefulWidget {
  final String data;

  const _QRCodeWidget({super.key, required this.data});

  @override
  State<_QRCodeWidget> createState() => _QRCodeWidgetState();
}

class _QRCodeWidgetState extends State<_QRCodeWidget> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BarcodeWidget(
              barcode: Barcode.qrCode(),
              data: widget.data,
              width: 180,
              height: 180,
              drawText: false,
            ),
            const SizedBox(height: 16),
            Text(
              widget.data,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
