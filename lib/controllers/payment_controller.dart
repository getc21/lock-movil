import 'package:get/get.dart';
import '../models/payment_method.dart';

class PaymentController extends GetxController {
  
  // Método de pago seleccionado
  final Rx<PaymentMethod> selectedPaymentMethod = PaymentMethod.cash.obs;
  
  // Estados de validación
  final RxBool isValidatingPayment = false.obs;
  final RxString validationError = ''.obs;
  
  // Información de pago adicional
  final RxString qrReference = ''.obs;
  final RxDouble receivedCashAmount = 0.0.obs;
  final RxDouble changeAmount = 0.0.obs;
  
  // Resetear información de pago
  void resetPaymentInfo() {
    selectedPaymentMethod.value = PaymentMethod.cash;
    validationError.value = '';
    qrReference.value = '';
    receivedCashAmount.value = 0.0;
    changeAmount.value = 0.0;
  }
  
  // Seleccionar método de pago
  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
    validationError.value = '';
    
    // Limpiar datos de otros métodos
    if (!method.isCash) {
      receivedCashAmount.value = 0.0;
      changeAmount.value = 0.0;
    }
    if (!method.isQr) {
      qrReference.value = '';
    }
  }
  
  // Actualizar monto recibido en efectivo
  void updateReceivedCashAmount(double amount) {
    receivedCashAmount.value = amount;
  }
  
  // Calcular cambio
  void calculateChange(double totalAmount) {
    if (selectedPaymentMethod.value.isCash && receivedCashAmount.value > 0) {
      changeAmount.value = receivedCashAmount.value - totalAmount;
    } else {
      changeAmount.value = 0.0;
    }
  }
  
  // Actualizar referencia de QR/Yape
  void updateTransferReference(String reference) {
    qrReference.value = reference;
  }
  
  // Validar pago antes de procesar
  bool validatePayment(double totalAmount) {
    validationError.value = '';
    
    switch (selectedPaymentMethod.value) {
      case PaymentMethod.cash:
        if (receivedCashAmount.value <= 0) {
          validationError.value = 'Debe ingresar el monto recibido en efectivo';
          return false;
        }
        if (receivedCashAmount.value < totalAmount) {
          validationError.value = 'El monto recibido es menor al total de la venta';
          return false;
        }
        break;
        
      case PaymentMethod.qr:
        // QR no requiere validación adicional
        break;
    }
    
    return true;
  }
  
  // Validar sin modificar estado - para uso durante build
  bool isPaymentValid(double totalAmount) {
    switch (selectedPaymentMethod.value) {
      case PaymentMethod.cash:
        return receivedCashAmount.value > 0 && receivedCashAmount.value >= totalAmount;
        
      case PaymentMethod.qr:
        return qrReference.value.trim().length >= 4;
    }
  }
  
  // Obtener mensaje de error sin modificar estado
  String getValidationMessage(double totalAmount) {
    switch (selectedPaymentMethod.value) {
      case PaymentMethod.cash:
        if (receivedCashAmount.value <= 0) {
          return 'Debe ingresar el monto recibido en efectivo';
        }
        if (receivedCashAmount.value < totalAmount) {
          return 'El monto recibido es menor al total de la venta';
        }
        break;
        
      case PaymentMethod.qr:
        // QR no requiere validación adicional
        break;
    }
    
    return '';
  }
  
  // Obtener información del pago para mostrar
  Map<String, dynamic> getPaymentInfo() {
    return <String, dynamic>{
      'method': selectedPaymentMethod.value,
      'methodValue': selectedPaymentMethod.value.value,
      'methodDisplayName': selectedPaymentMethod.value.displayName,
      'qrReference': qrReference.value,
      'receivedAmount': receivedCashAmount.value,
      'changeAmount': changeAmount.value,
    };
  }
  
  // Obtener detalles del pago como texto
  String getPaymentDetails(double totalAmount) {
    final PaymentMethod method = selectedPaymentMethod.value;
    String details = '${method.icon} ${method.displayName}';
    
    switch (method) {
      case PaymentMethod.cash:
        if (receivedCashAmount.value > 0) {
          details += '\nRecibido: \$${receivedCashAmount.value.toStringAsFixed(2)}';
          if (changeAmount.value > 0) {
            details += '\nCambio: \$${changeAmount.value.toStringAsFixed(2)}';
          }
        }
        break;
        
      case PaymentMethod.qr:
        if (qrReference.value.isNotEmpty) {
          details += '\nRef: ${qrReference.value}';
        }
        break;
    }
    
    return details;
  }
  
  // Obtener resumen del pago para la orden
  Map<String, dynamic> getPaymentSummary() {
    final Map<String, dynamic> info = getPaymentInfo();
    return <String, dynamic>{
      'payment_method': info['methodValue'],
      'payment_details': <String, dynamic>{
        'method': info['methodDisplayName'],
        'qr_reference': info['qrReference'],
        'received_amount': info['receivedAmount'],
        'change_amount': info['changeAmount'],
      }
    };
  }
  
  // Verificar si se puede procesar el pago
  bool canProcessPayment(double totalAmount) {
    return isPaymentValid(totalAmount) && !isValidatingPayment.value;
  }
}
