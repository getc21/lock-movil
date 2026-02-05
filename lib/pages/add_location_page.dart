import 'package:bellezapp/controllers/location_controller.dart';
import 'package:bellezapp/controllers/store_controller.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  AddLocationPageState createState() => AddLocationPageState();
}

class AddLocationPageState extends State<AddLocationPage> {
  late final LocationController locationController;
  late final StoreController storeController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Usar la misma instancia del controlador que ya existe
    try {
      locationController = Get.find<LocationController>();
    } catch (e) {
      locationController = Get.put(LocationController());
    }

    try {
      storeController = Get.find<StoreController>();
    } catch (e) {
      storeController = Get.put(StoreController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ⭐ Obtener el storeId actual de la tienda seleccionada
    final currentStore = storeController.currentStore;
    if (currentStore == null) {
      Utils.showErrorSnackbar('Error', 'No hay tienda seleccionada');
      return;
    }

    final storeId = currentStore['_id'] ?? currentStore['id'];
    if (storeId == null) {
      Utils.showErrorSnackbar('Error', 'ID de tienda no válido');
      return;
    }

    final success = await locationController.createLocation(
      storeId: storeId,
      name: _nameController.text,
      description: _descriptionController.text.isEmpty 
          ? null 
          : _descriptionController.text,
    );

    if (success) {      
      // Primero navegar de regreso
      if (mounted) {
        Navigator.of(context).pop();
        
        // Mostrar snackbar después de regresar
        Future.delayed(const Duration(milliseconds: 300), () {
          Utils.showSuccessSnackbar('Éxito', 'Ubicación creada correctamente');
        });
      }
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
        title: Row(
          children: const [
            Icon(Icons.location_on, size: 24),
            SizedBox(width: 8),
            Text('Nueva Ubicación'),
          ],
        ),
        backgroundColor: Utils.colorBotones,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Utils.colorBotones, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Información de la Ubicación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Utils.colorBotones
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la ubicación*',
                prefixIcon: Icon(Icons.label, color: Utils.colorBotones),
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
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Botón guardar
            Obx(() {
              return ElevatedButton(
                onPressed: locationController.isLoading ? null : _saveLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Utils.colorBotones,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: locationController.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Guardar Ubicación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
