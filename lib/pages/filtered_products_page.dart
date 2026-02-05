import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../controllers/product_controller.dart';
import '../utils/utils.dart';
import 'edit_product_page.dart';

class FilteredProductsPage extends StatefulWidget {
  final String filterType; // 'category', 'supplier', 'location'
  final String filterId;
  final String filterName;
  final String? filterImage;

  const FilteredProductsPage({
    super.key,
    required this.filterType,
    required this.filterId,
    required this.filterName,
    this.filterImage,
  });

  @override
  State<FilteredProductsPage> createState() => _FilteredProductsPageState();
}

class _FilteredProductsPageState extends State<FilteredProductsPage> {
  late final ProductController productController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredProducts = [];
  final Map<String, bool> _expandedBadges = {}; // Para controlar qué badges están expandidos

  @override
  void initState() {
    super.initState();
    // Obtener o crear la instancia del ProductController
    productController = Get.isRegistered<ProductController>()
        ? Get.find<ProductController>()
        : Get.put(ProductController());
    _initializeAndLoadProducts();
  }

  Future<void> _initializeAndLoadProducts() async {
    // Asegurarse de que los productos estén cargados
    await productController.loadProducts();
    _loadFilteredProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFilteredProducts() {
    final allProducts = productController.products;
    
    switch (widget.filterType) {
      case 'category':
        _filteredProducts = allProducts.where((product) {
          final categoryId = product['categoryId'];
          String? actualCategoryId;
          
          if (categoryId is String) {
            actualCategoryId = categoryId;
          } else if (categoryId is Map<String, dynamic>) {
            actualCategoryId = categoryId['_id']?.toString();
          }
          
          final categoryObj = product['category'];
          final categoryObjId = categoryObj != null ? categoryObj['_id']?.toString() : null;
          
          bool matches = actualCategoryId == widget.filterId || categoryObjId == widget.filterId;
          
          return matches;
        }).toList();
        break;
      case 'supplier':
        _filteredProducts = allProducts.where((product) {
          final supplierId = product['supplierId'];
          String? actualSupplierId;
          
          if (supplierId is String) {
            actualSupplierId = supplierId;
          } else if (supplierId is Map<String, dynamic>) {
            actualSupplierId = supplierId['_id']?.toString();
          }
          
          final supplierObj = product['supplier'];
          final supplierObjId = supplierObj != null ? supplierObj['_id']?.toString() : null;
          
          return actualSupplierId == widget.filterId || supplierObjId == widget.filterId;
        }).toList();
        break;
      case 'location':
        _filteredProducts = allProducts.where((product) {
          final locationId = product['locationId'];
          String? actualLocationId;
          
          if (locationId is String) {
            actualLocationId = locationId;
          } else if (locationId is Map<String, dynamic>) {
            actualLocationId = locationId['_id']?.toString();
          }
          
          final locationObj = product['location'];
          final locationObjId = locationObj != null ? locationObj['_id']?.toString() : null;
          
          return actualLocationId == widget.filterId || locationObjId == widget.filterId;
        }).toList();
        break;
    }
    
    setState(() {});
  }

  List<Map<String, dynamic>> get _searchFilteredProducts {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return _filteredProducts;
    }
    
    return _filteredProducts.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final description = (product['description'] ?? '').toString().toLowerCase();
      final sku = (product['sku'] ?? '').toString().toLowerCase();
      return name.contains(searchText) || 
             description.contains(searchText) || 
             sku.contains(searchText);
    }).toList();
  }

  String _getFilterTitle() {
    switch (widget.filterType) {
      case 'category':
        return 'Productos en ${widget.filterName}';
      case 'supplier':
        return 'Productos de ${widget.filterName}';
      case 'location':
        return 'Productos en ${widget.filterName}';
      default:
        return 'Productos';
    }
  }

  IconData _getFilterIcon() {
    switch (widget.filterType) {
      case 'category':
        return Icons.category;
      case 'supplier':
        return Icons.business;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.inventory;
    }
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
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
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
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      SizedBox(height: 8),
                      
                      // Texto de ayuda
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey[500]),
                          SizedBox(width: 6),
                          Text(
                            'Ingresa la cantidad a agregar al inventario',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                      
                      // Botones con diseño moderno
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
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
                                    side: BorderSide(color: Colors.grey[300]!, width: 2),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
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
                                      color: Utils.colorBotones.withValues(alpha: 0.4),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      final stockToAdd = int.parse(stockController.text);
                                      Navigator.of(context).pop();
                                      
                                      final success = await productController.updateStock(
                                        id: productId,
                                        quantity: stockToAdd,
                                        operation: 'add',
                                      );
                                      
                                      if (success) {
                                        _loadFilteredProducts();
                                        // Mostrar snackbar de éxito
                                        Get.snackbar(
                                          'Stock Actualizado',
                                          'Se agregaron $stockToAdd unidades correctamente',
                                          snackPosition: SnackPosition.TOP,
                                          backgroundColor: Colors.green,
                                          colorText: Colors.white,
                                          icon: Icon(Icons.check_circle, color: Colors.white),
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
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Future<void> _generateAndShowPdf(BuildContext context, String productName) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, 100 * PdfPageFormat.mm),
          build: (pw.Context context) {
            return pw.GridView(
              crossAxisCount: 4,
              childAspectRatio: 1,
              children: List.generate(12, (index) {
                return pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: productName,
                        width: 40,
                        height: 40,
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        productName,
                        style: pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$productName.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Abre el archivo PDF con un visor externo
      await OpenFilex.open(filePath);
    } catch (e) {
      log('Error generating PDF: $e');
      Utils.showErrorSnackbar('Error', 'No se pudo generar el PDF');
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
        Utils.showSuccessSnackbar('Éxito', 'Producto eliminado correctamente');
        _loadFilteredProducts();
      }
    }
  }

  Widget _buildCompactActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        backgroundColor: Utils.colorBotones,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getFilterTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_searchFilteredProducts.length} productos encontrados',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Header con información del filtro
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Información del filtro
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Utils.colorBotones.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getFilterIcon(),
                        color: Utils.colorBotones,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.filterName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            widget.filterType == 'category' ? 'Categoría' :
                            widget.filterType == 'supplier' ? 'Proveedor' : 'Ubicación',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Campo de búsqueda
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
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos por nombre, descripción o SKU...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                      prefixIcon: Icon(Icons.search, color: Utils.colorBotones, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de productos
          Expanded(
            child: _searchFilteredProducts.isEmpty ? _buildEmptyState() : _buildProductsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Utils.colorBotones.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchController.text.isEmpty
                  ? Icons.inventory_2_outlined
                  : Icons.search_off,
              size: 80,
              color: Utils.colorBotones.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty
                ? 'No hay productos'
                : 'No se encontraron productos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'No hay productos asociados con este ${widget.filterType == 'category' ? 'categoría' : widget.filterType == 'supplier' ? 'proveedor' : 'ubicación'}'
                : 'Intenta con otros términos de búsqueda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final products = _searchFilteredProducts;
    
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
                  child: _buildProductCard(products[leftIndex]),
                ),
                if (rightIndex < products.length) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProductCard(products[rightIndex]),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['_id'] ?? '';
    final name = product['name'] ?? 'Sin nombre';
    final description = product['description'] ?? '';
    final stock = product['stock'] ?? 0;
    final salePrice = product['salePrice'] ?? 0.0;
    final purchasePrice = product['purchasePrice'] ?? 0.0;
    final weight = product['weight'] ?? '';
    final imageUrl = _getImageUrl(product);
    final isLowStock = stock < 10;
    
    // Extraer nombres de relaciones
    final locationName = product['locationId'] is Map 
        ? product['locationId']['name'] ?? 'Sin ubicación'
        : 'Sin ubicación';
    
    // Verificar fecha de vencimiento
    final expiryDate = DateTime.tryParse(product['expiryDate']?.toString() ?? '');
    final isNearExpiry = expiryDate != null && 
        expiryDate.difference(DateTime.now()).inDays <= 30;

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
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/img/perfume.webp',
                            fit: BoxFit.cover,
                            height: 120,
                            width: double.infinity,
                          ),
                        )
                      : Image.asset(
                          'assets/img/perfume.webp',
                          fit: BoxFit.cover,
                          height: 120,
                          width: double.infinity,
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
                    if (isLowStock)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final key = '${productId}_stock';
                            _expandedBadges[key] = !(_expandedBadges[key] ?? false);
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
                              Icon(Icons.warning, color: Colors.white, size: 10),
                              if (_expandedBadges['${productId}_stock'] ?? false) ...[
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
                    if (isLowStock && isNearExpiry) SizedBox(height: 3),
                    if (isNearExpiry)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final key = '${productId}_expiry';
                            _expandedBadges[key] = !(_expandedBadges[key] ?? false);
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
                              Icon(Icons.schedule, color: Colors.white, size: 10),
                              if (_expandedBadges['${productId}_expiry'] ?? false) ...[
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
              // Botones de acción en la parte inferior derecha (horizontal)
              Positioned(
                bottom: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactActionButton(
                      icon: Icons.edit,
                      color: Utils.edit,
                      onTap: () async {
                        final result = await Get.to(() => EditProductPage(product: product));
                        // Si result es true, significa que se actualizó el producto
                        if (result == true) {
                          _loadFilteredProducts();
                        }
                      },
                      tooltip: 'Editar',
                    ),
                    SizedBox(width: 4),
                    _buildCompactActionButton(
                      icon: Icons.add,
                      color: Utils.add,
                      onTap: () => _showAddStockDialog(productId, name),
                      tooltip: 'Añadir stock',
                    ),
                    SizedBox(width: 4),
                    _buildCompactActionButton(
                      icon: Icons.delete,
                      color: Utils.delete,
                      onTap: () => _deleteProduct(productId, name),
                      tooltip: 'Eliminar',
                    ),
                  ],
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
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
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
                          _buildInfoItem('Stock', '$stock', 
                              isLowStock ? Colors.red : Colors.green, Icons.inventory),
                          _buildInfoItem('Ubicación', locationName, Colors.blue, Icons.location_on),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildInfoItem('Vencimiento', 
                              expiryDate != null
                                  ? expiryDate.toLocal().toString().split(' ')[0]
                                  : 'Sin fecha',
                              isNearExpiry ? Colors.orange : Colors.grey, Icons.schedule),
                          _buildInfoItem('Tamaño', 
                              weight.isNotEmpty ? weight : 'Sin especificar', Colors.purple, Icons.straighten),
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
                      colors: [Utils.colorBotones.withValues(alpha: 0.1), Colors.transparent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Utils.colorBotones.withValues(alpha: 0.2)),
                  ),
                  child: Column(
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
}
