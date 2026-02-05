import 'dart:io';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/category_controller.dart';
import 'package:bellezapp/controllers/supplier_controller.dart';
import 'package:bellezapp/controllers/location_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductPage({required this.product, super.key});

  @override
  EditProductPageState createState() => EditProductPageState();
}

class EditProductPageState extends State<EditProductPage> {
  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.put(CategoryController());
  final SupplierController supplierController = Get.put(SupplierController());
  final LocationController locationController = Get.put(LocationController());
  final StoreController storeController = Get.find<StoreController>();
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _stockController;
  late TextEditingController _weightController;
  late TextEditingController _expiryDateController;
  
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String? _selectedLocationId;
  File? _newImageFile;
  DateTime? _selectedExpiryDate;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    
    // Usar SchedulerBinding para asegurar que la carga se ejecute después del build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    
    try {
      await categoryController.loadCategories();
      await supplierController.loadSuppliers();
      
      // Cargar ubicaciones de la tienda actual
      final storeId = storeController.currentStore?['_id'];
      
      if (storeId != null) {
        await locationController.loadLocations(storeId: storeId);
      } else {
      }
    } catch (e) {
      if (kDebugMode) {

      }
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product['name']);
    _descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: widget.product['purchasePrice']?.toString() ?? '0',
    );
    _salePriceController = TextEditingController(
      text: widget.product['salePrice']?.toString() ?? '0',
    );
    _stockController = TextEditingController(
      text: widget.product['stock']?.toString() ?? '0',
    );
    _weightController = TextEditingController(
      text: widget.product['weight']?.toString() ?? '',
    );
    
    // Extraer IDs de los objetos populados o usar los _id directamente
    _selectedCategoryId = _extractId(widget.product['categoryId']);
    _selectedSupplierId = _extractId(widget.product['supplierId']);
    _selectedLocationId = _extractId(widget.product['locationId']);
    
    // Inicializar fecha de vencimiento
    final expiryDateStr = widget.product['expiryDate']?.toString();
    if (expiryDateStr != null && expiryDateStr.isNotEmpty) {
      _selectedExpiryDate = DateTime.tryParse(expiryDateStr);
      if (_selectedExpiryDate != null) {
        _expiryDateController = TextEditingController(
          text: _selectedExpiryDate!.toLocal().toString().split(' ')[0]
        );
      } else {
        _expiryDateController = TextEditingController();
      }
    } else {
      _expiryDateController = TextEditingController();
    }
  }

  String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value.containsKey('_id')) {
      return value['_id'].toString();
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    await Utils.showImageSourceDialog(
      context,
      onImageSelected: (source) => _pickImage(source),
    );
  }

  Future<void> _pickImage(String source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _newImageFile = File(image.path);
      });
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Utils.colorBotones,
            colorScheme: ColorScheme.light(
              primary: Utils.colorBotones,
              secondary: Utils.colorGnav,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Utils.colorFondo,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedExpiryDate) {
      setState(() {
        _selectedExpiryDate = pickedDate;
        _expiryDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _updateProduct() async {    
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {

      }
      return;
    }

    if (_selectedCategoryId == null) {
      Utils.showErrorSnackbar('Error', 'Selecciona una categoría');
      return;
    }

    if (_selectedSupplierId == null) {
      Utils.showErrorSnackbar('Error', 'Selecciona un proveedor');
      return;
    }

    if (_selectedLocationId == null) {
      Utils.showErrorSnackbar('Error', 'Selecciona una ubicación');
      return;
    }

    if (_selectedExpiryDate == null) {
      Utils.showErrorSnackbar('Error', 'Selecciona una fecha de vencimiento');
      return;
    }

    final productId = widget.product['_id'].toString();
    final weightValue = _weightController.text.isEmpty ? null : double.tryParse(_weightController.text);

    final success = await productController.updateProduct(
      id: productId,
      name: _nameController.text,
      categoryId: _selectedCategoryId!,
      supplierId: _selectedSupplierId!,
      locationId: _selectedLocationId!,
      purchasePrice: double.parse(_purchasePriceController.text),
      salePrice: double.parse(_salePriceController.text),
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      weight: weightValue,
      expiryDate: _selectedExpiryDate,
      imageFile: _newImageFile,
    );
    if (success) {      
      // Usar SchedulerBinding para ejecutar después del frame actual
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } else {
      if (kDebugMode) {

      }
    }
  }

  Future<void> _deleteProduct() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Confirmar eliminación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que deseas eliminar este producto?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
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
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancelar', style: TextStyle(fontSize: 15)),
          ),
          ElevatedButton.icon(
            onPressed: () => Get.back(result: true),
            icon: Icon(Icons.delete_forever, size: 20),
            label: Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final productId = widget.product['_id'].toString();
      final success = await productController.deleteProduct(productId);
      
      if (success) {
        Get.back(); // Volver a la lista de productos
      }
    }
  }

  Widget _buildImageSection() {
    final currentImageUrl = widget.product['foto'];
    final hasImage = _newImageFile != null || 
        (currentImageUrl != null && currentImageUrl.toString().isNotEmpty);
    
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Utils.colorBotones.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: hasImage
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _newImageFile != null
                        ? Image.file(
                            _newImageFile!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: currentImageUrl.toString(),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('Error cargando imagen', 
                                  style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          ),
                  ),
                  // Badge "Cambiar"
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Utils.colorBotones,
                            Utils.colorBotones.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cambiar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Utils.colorBotones.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 48,
                      color: Utils.colorBotones,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Toca para agregar imagen',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'JPG, PNG (máx. 1024x1024)',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Utils.colorBotones.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Utils.colorBotones, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
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
        title: const Text('Editar Producto', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteProduct,
            tooltip: 'Eliminar producto',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Imagen
            _buildImageSection(),
            const SizedBox(height: 32),

            // SECCIÓN: Información Básica
            _buildSectionTitle('Información Básica', Icons.info_outline),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del producto*',
                        prefixIcon: Icon(Icons.shopping_bag_outlined, color: Utils.colorBotones),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        prefixIcon: Icon(Icons.description_outlined, color: Utils.colorBotones),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        hintText: 'Describe las características del producto...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SECCIÓN: Clasificación
            _buildSectionTitle('Clasificación', Icons.category_outlined),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Categoría
                    Obx(() {
                      final categories = categoryController.categories;
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Categoría*',
                          prefixIcon: Icon(Icons.label_outline, color: Utils.colorBotones),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category['_id'].toString(),
                            child: Text(
                              category['name'] ?? 'Sin nombre',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona una categoría';
                          }
                          return null;
                        },
                      );
                    }),
                    const SizedBox(height: 16),

                    // Proveedor
                    Obx(() {
                      final suppliers = supplierController.suppliers;
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedSupplierId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Proveedor*',
                          prefixIcon: Icon(Icons.local_shipping_outlined, color: Utils.colorBotones),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        items: suppliers.map((supplier) {
                          return DropdownMenuItem(
                            value: supplier['_id'].toString(),
                            child: Text(
                              supplier['name'] ?? 'Sin nombre',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSupplierId = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Selecciona un proveedor';
                          }
                          return null;
                        },
                      );
                    }),
                    const SizedBox(height: 16),

                    // Ubicación
                    Obx(() {
                      final locations = locationController.locations;
                      
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedLocationId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Ubicación en Tienda*',
                          prefixIcon: Icon(Icons.place_outlined, color: Utils.colorBotones),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          hintText: locations.isEmpty ? 'No hay ubicaciones disponibles' : 'Selecciona una ubicación',
                        ),
                        items: locations.isEmpty
                            ? null
                            : locations.map((location) {
                                final id = location['_id'].toString();
                                final name = location['name'] ?? 'Sin nombre';
                                final description = location['description'];
                                
                                String displayName = name;
                                if (description != null && description.toString().isNotEmpty) {
                                  displayName += ' ($description)';
                                }
                                
                                return DropdownMenuItem(
                                  value: id,
                                  child: Text(
                                    displayName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                );
                              }).toList(),
                        onChanged: locations.isEmpty ? null : (value) {
                          setState(() {
                            _selectedLocationId = value;
                          });
                        },
                        validator: (value) {
                          if (locations.isEmpty) {
                            return 'Crea una ubicación primero';
                          }
                          if (value == null) {
                            return 'Selecciona una ubicación';
                          }
                          return null;
                        },
                        disabledHint: Text(
                          'No hay ubicaciones',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SECCIÓN: Precios e Inventario
            _buildSectionTitle('Precios e Inventario', Icons.attach_money),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Precio de compra y venta en fila
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceController,
                            decoration: InputDecoration(
                              labelText: 'Precio compra*',
                              prefixText: '\$ ',
                              prefixIcon: Icon(Icons.shopping_cart_outlined, color: Colors.blue),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _salePriceController,
                            decoration: InputDecoration(
                              labelText: 'Precio venta*',
                              prefixText: '\$ ',
                              prefixIcon: Icon(Icons.sell_outlined, color: Colors.green),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Requerido';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tamaño/Peso y Stock en fila
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: 'Tamaño/Peso',
                              prefixIcon: Icon(Icons.straighten, color: Utils.colorBotones),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              hintText: '500ml, 250g...',
                              hintStyle: TextStyle(fontSize: 13),
                            ),
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: InputDecoration(
                              labelText: 'Stock actual',
                              prefixIcon: Icon(Icons.inventory_2, color: Colors.orange),
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              suffixIcon: Tooltip(
                                message: 'El stock se modifica desde la lista de productos',
                                child: Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            enabled: false, // Campo de solo lectura
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fecha de vencimiento
                    TextFormField(
                      controller: _expiryDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.red[400]),
                        suffixIcon: Icon(Icons.arrow_drop_down, color: Utils.colorBotones),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        labelText: 'Fecha de vencimiento*',
                        hintText: 'Selecciona una fecha',
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'La fecha de vencimiento es requerida';
                        }
                        return null;
                      },
                      onTap: () async {
                        await _selectExpiryDate(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botón actualizar
            Obx(() {
              return Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: productController.isLoading ? [] : [
                    BoxShadow(
                      color: Utils.colorBotones.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: productController.isLoading ? null : _updateProduct,
                  icon: productController.isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.save_outlined, size: 22),
                  label: Text(
                    productController.isLoading ? 'Actualizando...' : 'Actualizar Producto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Utils.colorBotones,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Texto informativo
            Center(
              child: Text(
                '* Campos requeridos',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
