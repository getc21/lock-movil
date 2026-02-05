import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/store_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/store.dart';
import '../models/user.dart';
import '../utils/utils.dart';

class UserStoreAssignmentPage extends StatefulWidget {
  const UserStoreAssignmentPage({super.key});

  @override
  State<UserStoreAssignmentPage> createState() => _UserStoreAssignmentPageState();
}

class _UserStoreAssignmentPageState extends State<UserStoreAssignmentPage> {
  final authController = Get.find<AuthController>();
  final storeController = Get.find<StoreController>();
  
  List<User> users = [];
  Map<String, List<Store>> userStores = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // Cargar todos los usuarios
      final usersData = await authController.getAllUsers();
      users = usersData.map((u) => User.fromMap(u)).toList();
      
      // Cargar tiendas asignadas para cada usuario
      for (var user in users) {
        if (user.id != null) {
          final stores = await authController.getUserAssignedStores(user.id!);
          userStores[user.id!] = stores.map((s) => Store.fromMap(s)).toList();
        }
      }
    } catch (e) {
      Utils.showErrorSnackbar('Error', 'No se pudieron cargar los usuarios: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Asignación de Usuarios',
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
        child: isLoading
            ? Center(child: Utils.loadingCustom())
            : users.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(user);
                      },
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
              Icons.people_outline,
              size: 80,
              color: Utils.colorBotones,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No hay usuarios registrados',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Utils.colorTexto,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Crea usuarios para asignarlos a tiendas',
            style: TextStyle(
              fontSize: 16,
              color: Utils.colorTexto.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final assignedStores = userStores[user.id] ?? [];
    final roleColor = _getRoleColor(user.role);

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
      ),
      child: Column(
        children: [
          // Header con info del usuario
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  roleColor.withValues(alpha: 0.1),
                  roleColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: roleColor,
                  child: Text(
                    user.firstName[0].toUpperCase() + user.lastName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Utils.colorTexto,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleName(user.role),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            user.isActive ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color: user.isActive ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 4),
                          Text(
                            user.isActive ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontSize: 12,
                              color: user.isActive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
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
          
          // Tiendas asignadas
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.store, size: 18, color: Utils.colorTexto.withValues(alpha: 0.6)),
                    SizedBox(width: 8),
                    Text(
                      'Tiendas Asignadas (${assignedStores.length})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Utils.colorTexto,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                if (assignedStores.isEmpty)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sin tiendas asignadas',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assignedStores.map((store) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Utils.colorGnav.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Utils.colorGnav.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store, size: 14, color: Utils.colorGnav),
                            SizedBox(width: 6),
                            Text(
                              store.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Utils.colorGnav,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                
                if (user.role != UserRole.admin)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: ElevatedButton.icon(
                      onPressed: () => _showAssignDialog(user, assignedStores),
                      icon: Icon(Icons.edit_location_alt, size: 18),
                      label: Text('Gestionar Asignaciones'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Utils.colorBotones,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                
                if (user.role == UserRole.admin)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los administradores tienen acceso a todas las tiendas',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(User user, List<Store> currentStores) {
    final availableStores = storeController.stores.map((s) => Store.fromMap(s)).toList();
    final selectedStores = currentStores.map((s) => s.id!).toSet().obs;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(maxHeight: 600),
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
                      Icons.edit_location_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asignar Tiendas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Utils.colorTexto,
                          ),
                        ),
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Utils.colorTexto.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              Text(
                'Selecciona las tiendas a las que tendrá acceso:',
                style: TextStyle(
                  fontSize: 14,
                  color: Utils.colorTexto.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 12),
              
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableStores.length,
                  itemBuilder: (context, index) {
                    final store = availableStores[index];
                    
                    return Obx(() {
                      final isSelected = selectedStores.contains(store.id);
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Utils.colorBotones.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Utils.colorBotones
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            if (value == true) {
                              selectedStores.add(store.id!);
                            } else {
                              selectedStores.remove(store.id!);
                            }
                          },
                          title: Text(
                            store.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: store.address != null
                              ? Text(store.address!, style: TextStyle(fontSize: 12))
                              : null,
                          secondary: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Utils.colorBotones
                                  : Colors.grey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.store,
                              color: isSelected ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                          ),
                          activeColor: Utils.colorBotones,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
              
              SizedBox(height: 20),
              
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
                        await _saveAssignments(user, selectedStores.toList());
                        if (context.mounted) Navigator.pop(context);
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
                        'Guardar',
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
    );
  }

  Future<void> _saveAssignments(User user, List<String> selectedStoreIds) async {
    try {
      final currentStores = userStores[user.id] ?? [];
      final currentStoreIds = currentStores.map((s) => s.id!).toSet();

      // Eliminar asignaciones que ya no están seleccionadas
      for (var storeId in currentStoreIds) {
        if (!selectedStoreIds.contains(storeId)) {
          await storeController.unassignUserFromStore(user.id!, storeId);
        }
      }

      // Agregar nuevas asignaciones
      for (var storeId in selectedStoreIds) {
        if (!currentStoreIds.contains(storeId)) {
          await storeController.assignUserToStore(user.id!, storeId);
        }
      }

      Utils.showSuccessSnackbar('Éxito', 'Asignaciones actualizadas correctamente');

      await _loadData();
    } catch (e) {
      Utils.showErrorSnackbar('Error', 'No se pudieron guardar las asignaciones: $e');
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.employee:
        return Colors.teal;
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.manager:
        return 'Gerente';
      case UserRole.employee:
        return 'Empleado';
    }
  }
}
