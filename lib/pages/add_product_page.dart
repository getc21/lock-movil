import 'dart:io';
import 'package:bellezapp/controllers/product_controller.dart';
import 'package:bellezapp/controllers/category_controller.dart';
import 'package:bellezapp/controllers/supplier_controller.dart';
import 'package:bellezapp/controllers/location_controller.dart';
import 'package:bellezapp/controllers/auth_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/services/image_compression_service.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  AddProductPageState createState() => AddProductPageState();
}

class AddProductPageState extends State<AddProductPage> {
  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.put(CategoryController());
  final SupplierController supplierController = Get.put(SupplierController());
  final LocationController locationController = Get.put(LocationController());
  final AuthController authController = Get.find<AuthController>();
  final StoreController storeController = Get.find<StoreController>();
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _weightController = TextEditingController();
  final _expirityDateController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String? _selectedLocationId;
  File? _imageFile;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Cargar categorías
    await categoryController.loadCategories();
    
    // Cargar proveedores
    await supplierController.loadSuppliers();
    
    // Cargar ubicaciones de la tienda actual
    final storeId = storeController.currentStore?['_id'];
    if (storeId != null) {
      await locationController.loadLocations(storeId: storeId);
    } else {
      // Si no hay tienda seleccionada, cargar todas
      await locationController.loadLocations();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _purchasePriceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _expirityDateController.dispose();
    super.dispose();
  }

  // Diálogo para crear categoría rápidamente
  Future<void> _showCreateCategoryDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                Utils.showErrorSnackbar('Error', 'El nombre es requerido');
                return;
              }

              final categoryController = Get.find<CategoryController>();

              final success = await categoryController.createCategory(
                name: nameController.text,
                description: descriptionController.text.isEmpty ? null : descriptionController.text,
              );

              if (success) {
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
                Utils.showSuccessSnackbar('Éxito', 'Categoría creada correctamente');
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result == true) {
      await categoryController.loadCategories();
      // Seleccionar la categoría recién creada
      if (categoryController.categories.isNotEmpty) {
        setState(() {
          _selectedCategoryId = categoryController.categories.last['_id'];
        });
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  // Diálogo para crear proveedor rápidamente
  Future<void> _showCreateSupplierDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Proveedor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                Utils.showErrorSnackbar('Error', 'El nombre es requerido');
                return;
              }

              final supplierController = Get.find<SupplierController>();

              final success = await supplierController.createSupplier(
                name: nameController.text,
                contactEmail: emailController.text.isEmpty ? null : emailController.text,
                contactPhone: phoneController.text.isEmpty ? null : phoneController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
              );

              if (success) {
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
                Utils.showSuccessSnackbar('Éxito', 'Proveedor creado correctamente');
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result == true) {
      await supplierController.loadSuppliers();
      // Seleccionar el proveedor recién creado
      if (supplierController.suppliers.isNotEmpty) {
        setState(() {
          _selectedSupplierId = supplierController.suppliers.last['_id'];
        });
      }
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
  }

  // Diálogo para crear ubicación rápidamente
  Future<void> _showCreateLocationDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Ubicación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Estante A, Bodega Principal',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                Utils.showErrorSnackbar('Error', 'El nombre es requerido');
                return;
              }

              final locationController = Get.find<LocationController>();
              final storeController = Get.find<StoreController>();
              final storeId = storeController.currentStore?['_id'];

              if (storeId == null) {
                Utils.showErrorSnackbar('Error', 'No hay tienda seleccionada');
                return;
              }

              final success = await locationController.createLocation(
                storeId: storeId,
                name: nameController.text,
                description: descriptionController.text.isEmpty ? null : descriptionController.text,
              );

              if (success) {
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
                Utils.showSuccessSnackbar('Éxito', 'Ubicación creada correctamente');
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (result == true) {
      final storeId = storeController.currentStore?['_id'];
      if (storeId != null) {
        await locationController.loadLocations(storeId: storeId);
        // Seleccionar la ubicación recién creada
        if (locationController.locations.isNotEmpty) {
          setState(() {
            _selectedLocationId = locationController.locations.last['_id'];
          });
        }
      }
    }

    nameController.dispose();
    descriptionController.dispose();
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
      // Comprimir imagen antes de guardar
      final compressed = await ImageCompressionService.compressImage(
        imageFile: File(image.path),
        quality: 85,
      );

      setState(() {
        _imageFile = compressed ?? File(image.path);
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    await Utils.showImageSourceDialog(
      context,
      onImageSelected: (source) => _pickImage(source),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _expirityDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
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

    if (_selectedDate == null) {
      Utils.showErrorSnackbar('Error', 'Selecciona una fecha de vencimiento');
      return;
    }

    // Obtener storeId de la tienda actual
    final storeId = storeController.currentStore?['_id'];
    if (storeId == null) {
      Utils.showErrorSnackbar('Error', 'No hay tienda seleccionada');
      return;
    }

    final weightValue = _weightController.text.isEmpty ? null : double.tryParse(_weightController.text);
    
    final success = await productController.createProduct(
      storeId: storeId,
      name: _nameController.text,
      categoryId: _selectedCategoryId!,
      supplierId: _selectedSupplierId!,
      locationId: _selectedLocationId!,
      purchasePrice: double.parse(_purchasePriceController.text),
      salePrice: double.parse(_salePriceController.text),
      stock: int.parse(_stockController.text),
      expiryDate: _selectedDate!,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      weight: weightValue,
      imageFile: _imageFile,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: const Text('Agregar Producto'),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sección: Información Básica
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Utils.colorBotones, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Información Básica',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones,
                    ),
                  ),
                ],
              ),
            ),
            
            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del producto*',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                prefixIcon: Icon(Icons.description, color: Utils.colorBotones),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Describe el producto brevemente...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Sección: Imagen del Producto
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.photo_camera, color: Utils.colorBotones, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Imagen del Producto',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Utils.colorBotones.withValues(alpha: 0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _imageFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _imageFile!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
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
            ),
            const SizedBox(height: 16),

            // Sección: Detalles y Stock
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.inventory, color: Utils.colorBotones, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Detalles y Stock',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.straighten, color: Utils.colorBotones),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Tamaño/Peso',
                      hintText: '500ml, 250g...',
                    ),
                    keyboardType: TextInputType.text,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.inventory_2, color: Utils.colorBotones),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Stock Inicial*',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección: Precios
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.attach_money, color: Utils.colorBotones, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Precios',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.shopping_cart, color: Colors.orange),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Precio de Compra*',
                      hintText: '\$0.00',
                      helperText: 'Costo del proveedor',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _salePriceController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.sell, color: Colors.green),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'Precio de Venta*',
                      hintText: '\$0.00',
                      helperText: 'Precio al público',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requerido';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Número inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección: Clasificación
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.category, color: Utils.colorBotones, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Clasificación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones,
                    ),
                  ),
                ],
              ),
            ),

            // Categoría con botón +
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final categories = categoryController.categories;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.category_outlined, color: Utils.colorBotones),
                        labelText: 'Categoría*',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: categories.isEmpty ? 'No hay categorías disponibles' : 'Selecciona una categoría',
                      ),
                      items: categories.isEmpty
                          ? null
                          : categories.map((category) {
                              return DropdownMenuItem(
                                value: category['_id'].toString(),
                                child: Text(category['name'] ?? 'Sin nombre'),
                              );
                            }).toList(),
                      onChanged: categories.isEmpty ? null : (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      validator: (value) {
                        if (categories.isEmpty) {
                          return 'Crea una categoría primero';
                        }
                        if (value == null) {
                          return 'Selecciona una categoría';
                        }
                        return null;
                      },
                      disabledHint: Text(
                        'No hay categorías',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    );
                  }),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Utils.colorBotones,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.white, size: 28),
                    tooltip: 'Crear nueva categoría',
                    onPressed: _showCreateCategoryDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Proveedor con botón +
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final suppliers = supplierController.suppliers;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedSupplierId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.local_shipping, color: Utils.colorBotones),
                        labelText: 'Proveedor*',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: suppliers.isEmpty ? 'No hay proveedores disponibles' : 'Selecciona un proveedor',
                      ),
                      items: suppliers.isEmpty
                          ? null
                          : suppliers.map((supplier) {
                              return DropdownMenuItem(
                                value: supplier['_id'].toString(),
                                child: Text(supplier['name'] ?? 'Sin nombre'),
                              );
                            }).toList(),
                      onChanged: suppliers.isEmpty ? null : (value) {
                        setState(() {
                          _selectedSupplierId = value;
                        });
                      },
                      validator: (value) {
                        if (suppliers.isEmpty) {
                          return 'Crea un proveedor primero';
                        }
                        if (value == null) {
                          return 'Selecciona un proveedor';
                        }
                        return null;
                      },
                      disabledHint: Text(
                        'No hay proveedores',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    );
                  }),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Utils.colorBotones,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.white, size: 28),
                    tooltip: 'Crear nuevo proveedor',
                    onPressed: _showCreateSupplierDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ubicación con botón +
            Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final locations = locationController.locations;
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedLocationId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.place, color: Utils.colorBotones),
                        labelText: 'Ubicación en Tienda*',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: locations.isEmpty ? 'No hay ubicaciones disponibles' : 'Selecciona una ubicación',
                      ),
                      items: locations.isEmpty
                          ? null
                          : locations.map((location) {
                              final id = location['_id'].toString();
                              final name = location['name'] ?? 'Sin nombre';
                              final description = location['description'];
                              
                              // Nombre más corto: solo nombre y descripción
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
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Utils.colorBotones,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.white, size: 28),
                    tooltip: 'Crear nueva ubicación',
                    onPressed: _showCreateLocationDialog,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección: Fecha de Vencimiento
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.event, color: Utils.colorBotones, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Fecha de Vencimiento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones,
                    ),
                  ),
                ],
              ),
            ),
            TextFormField(
              controller: _expirityDateController,
              readOnly: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.calendar_today, color: Utils.colorBotones),
                suffixIcon: Icon(Icons.arrow_drop_down),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                await _selectDate(context);
              },
            ),
            SizedBox(height: 24),

            // Botón guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(() {
                return ElevatedButton.icon(
                  onPressed: productController.isLoading ? null : _saveProduct,
                  icon: Icon(Icons.save, size: 24),
                  label: Text(
                    'Guardar Producto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Utils.colorBotones,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
