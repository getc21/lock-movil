import 'package:bellezapp/controllers/category_controller.dart';
import 'package:bellezapp/pages/edit_category_page.dart';
import 'package:bellezapp/pages/add_category_page.dart';
import 'package:bellezapp/pages/filtered_products_page.dart';
import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => CategoryListPageState();
}

class CategoryListPageState extends State<CategoryListPage> {
  final CategoryController categoryController = Get.put(CategoryController());
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    categoryController.loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCategories {
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isEmpty) {
      return categoryController.categories;
    }

    return categoryController.categories.where((category) {
      final name = (category['name'] ?? '').toString().toLowerCase();
      final description = (category['description'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(searchText) || description.contains(searchText);
    }).toList();
  }

  Future<void> _deleteCategory(String id) async {
    final confirmed = await Utils.showConfirmationDialog(
      context,
      'Confirmar eliminación',
      '¿Estás seguro de que deseas eliminar esta categoría?',
    );

    if (confirmed) {
      final success = await categoryController.deleteCategory(id);
      if (success) {
        Utils.showSuccessSnackbar('Eliminada', 'Categoría eliminada correctamente');
        categoryController.loadCategories();
      } else {
        Utils.showErrorSnackbar('Error', 'No se pudo eliminar la categoría');
      }
    }
  }

  String _getImageUrl(Map<String, dynamic> category) {
    final foto = category['foto'];
    if (foto == null || foto.toString().isEmpty) {
      return '';
    }
    return foto.toString();
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
                  offset: const Offset(0, 2),
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
                      'Categorías',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Utils.colorBotones.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_filteredCategories.length} categorías',
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
                const SizedBox(height: 8),
                // Campo de búsqueda prominente
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
                      hintText: 'Buscar categorías por nombre o descripción...',
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
                              icon: const Icon(
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de categorías
          Expanded(
            child: Obx(() {
              if (categoryController.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = _filteredCategories;

              if (categories.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: (categories.length / 2).ceil(),
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
                            child: _buildCategoryCard(categories[leftIndex]),
                          ),
                          if (rightIndex < categories.length) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCategoryCard(categories[rightIndex]),
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
          final result = await Get.to(() => const AddCategoryPage());
          if (result == true) {
            Utils.showSuccessSnackbar('Éxito', 'Categoría creada correctamente');
            categoryController.loadCategories();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
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
                  ? Icons.category_outlined
                  : Icons.search_off,
              size: 80,
              color: Utils.colorBotones.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty
                ? 'No hay categorías'
                : 'No se encontraron categorías',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Comienza agregando tu primera categoría'
                : 'Intenta con otros términos de búsqueda',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final name = category['name'] ?? 'Sin nombre';
    final description = category['description'] ?? '';
    final imageUrl = _getImageUrl(category);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Navegar a productos filtrados por esta categoría
        Get.to(
          () => FilteredProductsPage(
            filterType: 'category',
            filterId: category['_id'].toString(),
            filterName: name,
            filterImage: imageUrl,
          ),
        );
      },
      child: Container(
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
            // Imagen con overlay gradient
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
                    child: Stack(
                      children: [
                        imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => SizedBox(
                                  height: 140,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Utils.colorBotones,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => SizedBox(
                                  height: 140,
                                  child: Image.asset(
                                    'assets/img/perfume.webp',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 140,
                                child: Image.asset(
                                  'assets/img/perfume.webp',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                        // Gradient overlay
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botones de acción compactos
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactActionButton(
                          icon: Icons.edit_rounded,
                          color: Utils.edit,
                          onTap: () async {
                            final result = await Get.to(
                              () => EditCategoryPage(category: category),
                            );
                            if (result == true) {
                              Utils.showSuccessSnackbar('Éxito', 'Categoría actualizada correctamente');
                              categoryController.loadCategories();
                            }
                          },
                          tooltip: 'Editar',
                        ),
                        const SizedBox(width: 4),
                        _buildCompactActionButton(
                          icon: Icons.delete_rounded,
                          color: Utils.delete,
                          onTap: () =>
                              _deleteCategory(category['_id'].toString()),
                          tooltip: 'Eliminar',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Información con mejor diseño
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre con icono
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}
