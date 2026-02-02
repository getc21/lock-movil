import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../providers/product_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class ProductController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();

  ProductProvider get _productProvider =>
      ProductProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _products = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get products => _products;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    // Cargar productos al inicializar
    loadProductsForCurrentStore();
  }

  // ⭐ MÉTODO PARA REFRESCAR CUANDO CAMBIE LA TIENDA
  Future<void> refreshForStore() async {
    await loadProductsForCurrentStore();
  }

  // ⭐ CARGAR PRODUCTOS DE LA TIENDA ACTUAL
  Future<void> loadProductsForCurrentStore() async {
    final currentStore = _storeController.currentStore;
    if (currentStore != null) {
      await loadProducts(storeId: currentStore['_id']);
    }
  }

  // Cargar productos
  Future<void> loadProducts({
    String? storeId,
    String? categoryId,
    String? supplierId,
    String? locationId,
    bool? lowStock,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // ⭐ ASEGURAR QUE SIEMPRE SE USE EL STORE ID ACTUAL
      final currentStoreId = storeId ?? _storeController.currentStore?['_id'];

      if (currentStoreId == null) {
        _errorMessage.value = 'No hay tienda seleccionada';
        _products.clear();
        return;
      }
      final result = await _productProvider.getProducts(
        storeId: currentStoreId,
        categoryId: categoryId,
        supplierId: supplierId,
        locationId: locationId,
        lowStock: lowStock,
      );

      if (result['success']) {
        final data = result['data'];
        if (data is List) {
          final newProducts = List<Map<String, dynamic>>.from(data);
          _products.value = newProducts;

          // Verificar que todos los productos pertenezcan a la tienda correcta
          // All products loaded belong to the correct store
        } else {
          _products.value = [];
          _errorMessage.value = 'Formato de datos inválido';
        }
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando productos';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ⭐ LIMPIAR PRODUCTOS (útil cuando no hay tienda seleccionada)
  void clearProducts() {
    _products.clear();
    _errorMessage.value = '';
  }

  // Obtener producto por ID
  Future<Map<String, dynamic>?> getProductById(String id) async {
    _isLoading.value = true;

    try {
      final result = await _productProvider.getProductById(id);

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo producto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear producto
  Future<bool> createProduct({
    required String storeId,
    required String name,
    required String categoryId,
    required String supplierId,
    required String locationId,
    required double purchasePrice,
    required double salePrice,
    required int stock,
    required DateTime expiryDate,
    String? description,
    double? weight,
    File? imageFile,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _productProvider.createProduct(
        name: name,
        categoryId: categoryId,
        supplierId: supplierId,
        locationId: locationId,
        storeId: storeId,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        stock: stock,
        description: description,
        weight: weight,
        expiryDate: expiryDate,
        imageFile: imageFile,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Producto creado correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Recargar productos de la tienda actual después de crear
        await loadProductsForCurrentStore();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error creando producto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar producto
  Future<bool> updateProduct({
    required String id,
    String? name,
    String? categoryId,
    String? supplierId,
    String? locationId,
    double? purchasePrice,
    double? salePrice,
    String? description,
    double? weight,
    DateTime? expiryDate,
    File? imageFile,
  }) async {
    _isLoading.value = true;

    try {
      // Obtener el storeId actual para actualizar ProductStore
      final currentStoreId = _storeController.currentStore?['_id'];

      final result = await _productProvider.updateProduct(
        id: id,
        name: name,
        categoryId: categoryId,
        supplierId: supplierId,
        locationId: locationId,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        description: description,
        weight: weight,
        expiryDate: expiryDate,
        imageFile: imageFile,
        storeId: currentStoreId,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Producto actualizado correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Recargar productos de la tienda actual
        await loadProductsForCurrentStore();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando producto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  } // Eliminar producto

  Future<bool> deleteProduct(String id) async {
    _isLoading.value = true;

    try {
      final result = await _productProvider.deleteProduct(id);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Producto eliminado correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _products.removeWhere((p) => p['_id'] == id);
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error eliminando producto',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar stock
  Future<bool> updateStock({
    required String id,
    required int quantity,
    required String operation, // add, remove, set
    double? purchasePrice,
  }) async {
    _isLoading.value = true;

    try {
      // Obtener el storeId actual
      final currentStoreId = _storeController.currentStore?['_id'];

      if (currentStoreId == null) {
        Get.snackbar(
          'Error',
          'No hay tienda seleccionada',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final result = await _productProvider.updateStock(
        id: id,
        quantity: quantity,
        operation: operation,
        storeId: currentStoreId,
        purchasePrice: purchasePrice,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Stock actualizado correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // Recargar productos de la tienda actual para reflejar cambios
        await loadProductsForCurrentStore();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando stock',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Buscar producto por nombre o código de barras
  Future<Map<String, dynamic>?> searchProduct(String query) async {
    try {
      // Obtener el storeId actual
      final currentStoreId = _storeController.currentStore?['_id'];

      final result = await _productProvider.searchProduct(
        query,
        storeId: currentStoreId,
      );

      if (result['success']) {
        return result['data'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Obtener stock del producto en todas las tiendas
  Future<Map<String, dynamic>?> getProductStocks(String productId) async {
    try {
      final result = await _productProvider.getProductStocks(productId);

      if (result['success']) {
        return {'success': true, 'data': result['data']};
      } else {
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage.value = '';
  }
}
