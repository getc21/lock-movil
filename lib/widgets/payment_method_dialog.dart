import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_method.dart';
import '../utils/utils.dart';

class PaymentMethodDialog extends StatefulWidget {
  final double totalAmount;
  final VoidCallback? onPaymentConfirmed;

  const PaymentMethodDialog({
    super.key,
    required this.totalAmount,
    this.onPaymentConfirmed,
  });

  @override
  State<PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<PaymentMethodDialog> {
  late final PaymentController paymentController;

  @override
  void initState() {
    super.initState();
    paymentController = Get.put(PaymentController());
    // Resetear información de pago solo una vez al inicializar
    paymentController.resetPaymentInfo();
  }

  @override
  Widget build(BuildContext context) {
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.payment, color: Utils.colorBotones),
          const SizedBox(width: 8),
          const Text('Método de Pago'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6, // Limitar altura
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Total de la venta
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Utils.colorBotones.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Utils.colorBotones.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a Pagar:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${widget.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Utils.colorBotones,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Selección de método de pago
              _buildPaymentMethodSelection(),
              
              const SizedBox(height: 16),
              
              // Campos adicionales según el método
              Obx(() => _buildAdditionalFields()),
              
              const SizedBox(height: 16),
              
              // Mensaje de error
              Obx(() {
                final errorMessage = paymentController.getValidationMessage(widget.totalAmount);
                return errorMessage.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => _processPayment(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Utils.colorBotones,
            foregroundColor: Colors.white,
          ),
          child: const Text('Procesar Venta'),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona el método de pago:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...PaymentMethod.values.map((method) => _buildPaymentMethodTile(method)),
      ],
    ));
  }

  Widget _buildPaymentMethodTile(PaymentMethod method) {
    final isSelected = paymentController.selectedPaymentMethod.value == method;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 3 : 1,
      color: isSelected ? Utils.colorBotones.withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: GestureDetector(
          onTap: () {
            paymentController.selectPaymentMethod(method);
            paymentController.calculateChange(widget.totalAmount);
          },
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Utils.colorBotones : Colors.grey,
                width: 2,
              ),
              color: isSelected ? Utils.colorBotones : Colors.transparent,
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  )
                : null,
          ),
        ),
        title: Text(
          method.displayLabel,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: _buildPaymentMethodSubtitle(method),
        onTap: () {
          paymentController.selectPaymentMethod(method);
          paymentController.calculateChange(widget.totalAmount);
        },
      ),
    );
  }

  Widget? _buildPaymentMethodSubtitle(PaymentMethod method) {
    // Simplificado por ahora - se puede agregar lógica de caja más tarde
    return null;
  }

  Widget _buildAdditionalFields() {
    final method = paymentController.selectedPaymentMethod.value;
    
    switch (method) {
      case PaymentMethod.cash:
        return _buildCashFields();
      case PaymentMethod.qr:
        return _buildQrFields();
    }
  }

  Widget _buildCashFields() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Monto Recibido',
            prefixText: '\$ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Utils.colorBotones, width: 2),
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (value) {
            final amount = double.tryParse(value) ?? 0.0;
            paymentController.updateReceivedCashAmount(amount);
            paymentController.calculateChange(widget.totalAmount);
          },
        ),
        
        const SizedBox(height: 12),
        
        Obx(() => paymentController.changeAmount.value > 0
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cambio a entregar:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '\$${paymentController.changeAmount.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildQrFields() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Utils.colorBotones.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Utils.colorBotones.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Utils.colorBotones, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'El pago será procesado. Verifica la llegada del dinero a tu cuenta.',
              style: TextStyle(
                fontSize: 12,
                color: Utils.colorBotones,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) {
    // Usar la validación que modifica estado solo al procesar
    if (paymentController.validatePayment(widget.totalAmount)) {
      Navigator.of(context).pop();
      widget.onPaymentConfirmed?.call();
    }
    // Los errores se muestran automáticamente por el Obx
  }
}
