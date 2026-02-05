import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_controller.dart';
import '../models/store.dart';
import '../utils/utils.dart';
import 'user_store_assignment_page.dart';

class StoreManagementPage extends StatelessWidget {
  const StoreManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final storeController = Get.find<StoreController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Tiendas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Utils.colorBotones, Utils.colorGnav],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.people_alt, color: Colors.white),
            onPressed: () => Get.to(() => UserStoreAssignmentPage()),
            tooltip: 'Asignar usuarios a tiendas',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Utils.colorFondo.withValues(alpha: 0.3),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Obx(() {
          if (storeController.isLoading) {
            return Center(child: Utils.loadingCustom());
          }

          if (storeController.availableStores.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => await storeController.refreshStores(),
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: storeController.availableStores.length,
              itemBuilder: (context, index) {
                final storeMap = storeController.availableStores[index];
                final store = Store.fromMap(storeMap);
                return _buildStoreCard(context, store, storeController);
              },
            ),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStoreDialog(context, null, storeController),
        backgroundColor: Utils.colorBotones,
        icon: Icon(Icons.add_business, color: Colors.white),
        label: Text(
          'Nueva Tienda',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Utils.colorBotones.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.store_outlined,
              size: 80,
              color: Utils.colorBotones,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No hay tiendas registradas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Utils.colorTexto,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Crea tu primera tienda para comenzar',
            style: TextStyle(
              fontSize: 16,
              color: Utils.colorTexto.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, Store store, StoreController controller) {
    final isActive = store.status == 'active';
    final isCurrent = controller.currentStore?['_id'] == store.id;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: isCurrent
            ? Border.all(color: Utils.colorBotones, width: 2)
            : null,
      ),
      child: Column(
        children: [
          // Header con nombre y estado
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [Utils.colorBotones.withValues(alpha: 0.1), Utils.colorGnav.withValues(alpha: 0.1)]
                    : [Colors.grey.withValues(alpha: 0.1), Colors.grey.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? Utils.colorBotones : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.store,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              store.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Utils.colorTexto,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Actual',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'Activa' : 'Inactiva',
                          style: TextStyle(
                            color: isActive ? Colors.green[700] : Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Información de la tienda
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (store.address != null && store.address!.isNotEmpty)
                  _buildInfoRow(Icons.location_on, store.address!),
                if (store.phone != null && store.phone!.isNotEmpty)
                  _buildInfoRow(Icons.phone, store.phone!),
                if (store.email != null && store.email!.isNotEmpty)
                  _buildInfoRow(Icons.email, store.email!),
                
                SizedBox(height: 16),
                
                // Botones de acción
                Row(
                  children: [
                    if (!isCurrent)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => controller.switchStore(store),
                          icon: Icon(Icons.sync_alt, size: 18),
                          label: Text('Cambiar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Utils.colorGnav,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (!isCurrent) SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showStoreDialog(context, store, controller),
                        icon: Icon(Icons.edit, size: 18),
                        label: Text('Editar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Utils.colorBotones,
                          side: BorderSide(color: Utils.colorBotones),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _confirmDelete(context, store, controller),
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Eliminar tienda',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Utils.colorTexto.withValues(alpha: 0.6)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Utils.colorTexto,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStoreDialog(BuildContext context, Store? store, StoreController controller) {
    final isEdit = store != null;
    final nameController = TextEditingController(text: store?.name ?? '');
    final addressController = TextEditingController(text: store?.address ?? '');
    final phoneController = TextEditingController(text: store?.phone ?? '');
    final emailController = TextEditingController(text: store?.email ?? '');
    final statusValue = RxString(store?.status ?? 'active');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Utils.colorBotones, Utils.colorGnav],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEdit ? Icons.edit : Icons.add_business,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        isEdit ? 'Editar Tienda' : 'Nueva Tienda',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Utils.colorTexto,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
                // Nombre
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de la tienda *',
                    prefixIcon: Icon(Icons.store, color: Utils.colorBotones),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Utils.colorBotones, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Dirección
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    prefixIcon: Icon(Icons.location_on, color: Utils.colorBotones),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Utils.colorBotones, width: 2),
                    ),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                
                // Teléfono
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    prefixIcon: Icon(Icons.phone, color: Utils.colorBotones),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Utils.colorBotones, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                
                // Email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Utils.colorBotones),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Utils.colorBotones, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                
                // Estado
                Obx(() => Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Utils.colorFondo.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado de la tienda',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Utils.colorTexto,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => statusValue.value = 'active',
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: statusValue.value == 'active' 
                                      ? Utils.colorBotones.withValues(alpha: 0.1) 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusValue.value == 'active' 
                                        ? Utils.colorBotones 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusValue.value == 'active' 
                                            ? Utils.colorBotones 
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: statusValue.value == 'active' 
                                              ? Utils.colorBotones 
                                              : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      child: statusValue.value == 'active'
                                          ? Icon(Icons.check, size: 10, color: Colors.white)
                                          : null,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Activa', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => statusValue.value = 'inactive',
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: statusValue.value == 'inactive' 
                                      ? Utils.colorBotones.withValues(alpha: 0.1) 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusValue.value == 'inactive' 
                                        ? Utils.colorBotones 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: statusValue.value == 'inactive' 
                                            ? Utils.colorBotones 
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: statusValue.value == 'inactive' 
                                              ? Utils.colorBotones 
                                              : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      child: statusValue.value == 'inactive'
                                          ? Icon(Icons.check, size: 10, color: Colors.white)
                                          : null,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Inactiva', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
                
                SizedBox(height: 24),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Utils.colorTexto,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancelar'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty) {
                            Utils.showErrorSnackbar('Error', 'El nombre de la tienda es obligatorio');
                            return;
                          }

                          bool success;
                          if (isEdit) {
                            success = await controller.updateStore(
                              id: store.id!,
                              name: nameController.text,
                              address: addressController.text.isEmpty ? null : addressController.text,
                              phone: phoneController.text.isEmpty ? null : phoneController.text,
                              email: emailController.text.isEmpty ? null : emailController.text,
                            );
                          } else {
                            success = await controller.createStore(
                              name: nameController.text,
                              address: addressController.text.isEmpty ? null : addressController.text,
                              phone: phoneController.text.isEmpty ? null : phoneController.text,
                              email: emailController.text.isEmpty ? null : emailController.text,
                            );
                          }

                          if (success && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Utils.colorBotones,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEdit ? 'Guardar' : 'Crear',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  void _confirmDelete(BuildContext context, Store store, StoreController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            SizedBox(width: 12),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar esta tienda?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (store.address != null && store.address!.isNotEmpty)
                    Text(
                      store.address!,
                      style: TextStyle(
                        color: Utils.colorTexto.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Esta acción no se puede deshacer',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await controller.deleteStore(store.id!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
