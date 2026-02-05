import 'package:bellezapp/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/discount_controller.dart';

class AddDiscountPage extends StatefulWidget {
  final Map<String, dynamic>? discount;

  const AddDiscountPage({super.key, this.discount});

  @override
  State<AddDiscountPage> createState() => _AddDiscountPageState();
}

class _AddDiscountPageState extends State<AddDiscountPage> {
  late final DiscountController discountController;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _minimumAmountController = TextEditingController();
  final _maximumDiscountController = TextEditingController();
  
  String _selectedType = 'percentage';
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  
  bool get isEditing => widget.discount != null;

  @override
  void initState() {
    super.initState();
    // Intentar encontrar el controller, si no existe, crearlo
    try {
      discountController = Get.find<DiscountController>();
    } catch (e) {
      discountController = Get.put(DiscountController());
    }
    
    if (isEditing) {
      _loadDiscountData();
    }
  }

  void _loadDiscountData() {
    final discount = widget.discount!;
    _nameController.text = discount['name']?.toString() ?? '';
    _descriptionController.text = discount['description']?.toString() ?? '';
    _valueController.text = discount['value']?.toString() ?? '';
    _selectedType = discount['type']?.toString() ?? 'percentage';
    _isActive = discount['isActive'] ?? true;
    
    if (discount['minimumAmount'] != null) {
      _minimumAmountController.text = discount['minimumAmount'].toString();
    }
    if (discount['maximumDiscount'] != null) {
      _maximumDiscountController.text = discount['maximumDiscount'].toString();
    }
    
    if (discount['startDate'] != null) {
      _startDate = DateTime.parse(discount['startDate']);
    }
    if (discount['endDate'] != null) {
      _endDate = DateTime.parse(discount['endDate']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _minimumAmountController.dispose();
    _maximumDiscountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Descuento' : 'Nuevo Descuento'),
        backgroundColor: Utils.colorBotones,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveDiscount,
            child: const Text(
              'Guardar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              _buildSectionTitle('Información Básica'),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              
              // Tipo y valor del descuento
              _buildSectionTitle('Configuración del Descuento'),
              _buildTypeSelector(),
              const SizedBox(height: 16),
              _buildValueField(),
              const SizedBox(height: 24),
              
              // Condiciones opcionales
              _buildSectionTitle('Condiciones (Opcional)'),
              _buildMinimumAmountField(),
              const SizedBox(height: 16),
              if (_selectedType == 'percentage')
                Column(
                  children: [
                    _buildMaximumDiscountField(),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Fechas
              _buildSectionTitle('Período de Validez (Opcional)'),
              _buildDateFields(),
              const SizedBox(height: 24),
              
              // Estado activo
              _buildSectionTitle('Estado'),
              _buildActiveSwitch(),
              const SizedBox(height: 32),
              
              // Vista previa
              _buildPreviewCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nombre del descuento *',
        hintText: 'Ej: Descuento de Temporada',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.discount),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El nombre es requerido';
        }
        if (value.trim().length < 3) {
          return 'El nombre debe tener al menos 3 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Descripción *',
        hintText: 'Describe cuándo y cómo aplicar este descuento',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La descripción es requerida';
        }
        return null;
      },
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de descuento *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: _selectedType == 'percentage' ? 3 : 1,
                color: _selectedType == 'percentage' 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedType = 'percentage';
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.percent,
                          color: _selectedType == 'percentage'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Porcentaje (%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == 'percentage'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ej: 15% de descuento',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: _selectedType == 'fixed' ? 3 : 1,
                color: _selectedType == 'fixed' 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedType = 'fixed';
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: _selectedType == 'fixed'
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Monto fijo (\$)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _selectedType == 'fixed'
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ej: \$50 de descuento',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValueField() {
    return TextFormField(
      controller: _valueController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: _selectedType == 'percentage' 
            ? 'Porcentaje de descuento *' 
            : 'Monto del descuento *',
        hintText: _selectedType == 'percentage' 
            ? 'Ej: 15 (para 15%)' 
            : 'Ej: 50.00',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(_selectedType == 'percentage' 
            ? Icons.percent 
            : Icons.attach_money),
        suffixText: _selectedType == 'percentage' ? '%' : '\$',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'El valor es requerido';
        }
        
        final doubleValue = double.tryParse(value);
        if (doubleValue == null || doubleValue <= 0) {
          return 'Ingresa un valor válido mayor a 0';
        }
        
        if (_selectedType == 'percentage' && doubleValue > 100) {
          return 'El porcentaje no puede ser mayor a 100%';
        }
        
        return null;
      },
    );
  }

  Widget _buildMinimumAmountField() {
    return TextFormField(
      controller: _minimumAmountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Compra mínima',
        hintText: 'Monto mínimo para aplicar descuento',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.shopping_cart),
        suffixText: '\$',
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final doubleValue = double.tryParse(value);
          if (doubleValue == null || doubleValue <= 0) {
            return 'Ingresa un monto válido mayor a 0';
          }
        }
        return null;
      },
    );
  }

  Widget _buildMaximumDiscountField() {
    return TextFormField(
      controller: _maximumDiscountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Descuento máximo',
        hintText: 'Monto máximo de descuento',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.money_off),
        suffixText: '\$',
      ),
      validator: (value) {
        if (value != null && value.trim().isNotEmpty) {
          final doubleValue = double.tryParse(value);
          if (doubleValue == null || doubleValue <= 0) {
            return 'Ingresa un monto válido mayor a 0';
          }
        }
        return null;
      },
    );
  }

  Widget _buildDateFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de inicio',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: _startDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de fin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: _endDate != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_startDate != null)
              TextButton.icon(
                onPressed: () => setState(() => _startDate = null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar inicio'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
            const Spacer(),
            if (_endDate != null)
              TextButton.icon(
                onPressed: () => setState(() => _endDate = null),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Limpiar fin'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return SwitchListTile(
      title: const Text('Descuento activo'),
      subtitle: Text(_isActive 
          ? 'El descuento está disponible para usar'
          : 'El descuento está deshabilitado'),
      value: _isActive,
      onChanged: (value) => setState(() => _isActive = value),
    );
  }

  Widget _buildPreviewCard() {
    if (_nameController.text.isEmpty || _valueController.text.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final value = double.tryParse(_valueController.text) ?? 0;
    final minimumAmount = double.tryParse(_minimumAmountController.text);
    final maximumDiscount = double.tryParse(_maximumDiscountController.text);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Vista Previa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_isActive ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_isActive ? Colors.green : Colors.grey).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _nameController.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _descriptionController.text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                _selectedType == 'percentage'
                    ? '${value.toStringAsFixed(0)}%'
                    : '\$${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            if (minimumAmount != null || maximumDiscount != null || 
                _startDate != null || _endDate != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Condiciones:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              if (minimumAmount != null)
                Text('• Compra mínima: \$${minimumAmount.toStringAsFixed(2)}'),
              if (maximumDiscount != null)
                Text('• Descuento máximo: \$${maximumDiscount.toStringAsFixed(2)}'),
              if (_startDate != null)
                Text('• Válido desde: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
              if (_endDate != null)
                Text('• Válido hasta: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 años
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Si la fecha de fin es anterior a la de inicio, limpiarla
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          // Verificar que la fecha de fin no sea anterior a la de inicio
          if (_startDate != null && picked.isBefore(_startDate!)) {
            Utils.showErrorSnackbar('Error', 'La fecha de fin no puede ser anterior a la fecha de inicio');
            return;
          }
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveDiscount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validar fechas
    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      Utils.showErrorSnackbar('Error', 'La fecha de fin no puede ser anterior a la fecha de inicio');
      return;
    }
    
    // Mostrar loading
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Guardando descuento...'),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    
    try {
      final value = double.parse(_valueController.text);
      final minimumAmount = _minimumAmountController.text.isNotEmpty
          ? double.parse(_minimumAmountController.text)
          : null;
      final maximumDiscount = _maximumDiscountController.text.isNotEmpty
          ? double.parse(_maximumDiscountController.text)
          : null;
      
      bool success;
      
      if (isEditing) {
        success = await discountController.updateDiscount(
          id: widget.discount!['_id']!.toString(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          value: value,
          minimumAmount: minimumAmount,
          maximumDiscount: maximumDiscount,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
        );
      } else {
        success = await discountController.addDiscount(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          value: value,
          minimumAmount: minimumAmount,
          maximumDiscount: maximumDiscount,
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
        );
      }
      
      // Esperar un momento para que el snackbar del controller termine
      await Future.delayed(Duration(milliseconds: 100));
      
      // Cerrar loading dialog si está abierto
      if (Get.isDialogOpen == true) {
        if (mounted) Navigator.of(context).pop();
      }
      
      // Esperar otro momento antes de cerrar la página
      await Future.delayed(Duration(milliseconds: 100));
      
      // Si fue exitoso, cerrar la página
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {

      }
      
      // Cerrar loading dialog si está abierto
      if (Get.isDialogOpen == true) {
        if (mounted) Navigator.of(context).pop();
      }
      
      // Esperar antes de mostrar el error
      await Future.delayed(Duration(milliseconds: 100));
      
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar descuento: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
