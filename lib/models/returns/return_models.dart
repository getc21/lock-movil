// Enums
enum ReturnStatus {
  pending('pending', 'Pendiente'),
  approved('approved', 'Aprobada'),
  completed('completed', 'Completada'),
  rejected('rejected', 'Rechazada');

  final String value;
  final String label;
  const ReturnStatus(this.value, this.label);

  factory ReturnStatus.fromValue(String value) {
    return ReturnStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReturnStatus.pending,
    );
  }
}

enum ReturnType {
  return_('return', 'Devolución'),
  exchange('exchange', 'Cambio'),
  partialRefund('partial_refund', 'Reembolso Parcial'),
  fullRefund('full_refund', 'Reembolso Total');

  final String value;
  final String label;
  const ReturnType(this.value, this.label);

  factory ReturnType.fromValue(String value) {
    return ReturnType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReturnType.return_,
    );
  }
}

enum ReturnReasonCategory {
  defective('defective', 'Producto Defectuoso'),
  notAsDescribed('not_as_described', 'No Como se Describe'),
  customerChangeMind('customer_change_mind', 'Cambió de Opinión'),
  wrongItem('wrong_item', 'Producto Incorrecto'),
  damaged('damaged', 'Dañado'),
  other('other', 'Otro');

  final String value;
  final String label;
  const ReturnReasonCategory(this.value, this.label);

  factory ReturnReasonCategory.fromValue(String value) {
    return ReturnReasonCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReturnReasonCategory.other,
    );
  }
}

enum RefundMethod {
  cash('efectivo', 'Efectivo'),
  card('tarjeta', 'Tarjeta'),
  transfer('transferencia', 'Transferencia'),
  account('cuenta', 'Cuenta');

  final String value;
  final String label;
  const RefundMethod(this.value, this.label);

  factory RefundMethod.fromValue(String value) {
    return RefundMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RefundMethod.cash,
    );
  }
}

// Models
class ReturnItem {
  final String productId;
  final String? productName;
  final int originalQuantity;
  final int returnQuantity;
  final double unitPrice;
  final String returnReason;
  final String? notes;

  ReturnItem({
    required this.productId,
    this.productName,
    required this.originalQuantity,
    required this.returnQuantity,
    required this.unitPrice,
    required this.returnReason,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'originalQuantity': originalQuantity,
        'returnQuantity': returnQuantity,
        'unitPrice': unitPrice,
        'returnReason': returnReason,
        if (notes != null) 'notes': notes,
      };

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String?,
      originalQuantity: json['originalQuantity'] as int? ?? 0,
      returnQuantity: json['returnQuantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      returnReason: json['returnReason'] as String? ?? 'Sin especificar',
      notes: json['notes'] as String?,
    );
  }
}

class ReturnRequest {
  final String? id;
  final String orderId;
  final String? orderNumber;
  final ReturnType type;
  final ReturnStatus status;
  final List<ReturnItem> items;
  final double totalRefundAmount;
  final RefundMethod refundMethod;
  final String? customerId;
  final String? customerName;
  final String storeId;
  final ReturnReasonCategory returnReasonCategory;
  final String? returnReasonDetails;
  final String? requestedBy;
  final DateTime? requestedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? processedBy;
  final DateTime? processedAt;
  final List<String>? attachmentUrls;
  final List<String>? notes;
  final String? internalNotes;

  ReturnRequest({
    this.id,
    required this.orderId,
    this.orderNumber,
    required this.type,
    required this.status,
    required this.items,
    required this.totalRefundAmount,
    required this.refundMethod,
    this.customerId,
    this.customerName,
    required this.storeId,
    required this.returnReasonCategory,
    this.returnReasonDetails,
    this.requestedBy,
    this.requestedAt,
    this.approvedBy,
    this.approvedAt,
    this.processedBy,
    this.processedAt,
    this.attachmentUrls,
    this.notes,
    this.internalNotes,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'type': type.value,
        'items': items.map((i) => i.toJson()).toList(),
        'refundMethod': refundMethod.value,
        'reasonCategory': returnReasonCategory.value,
        'reasonDetails': returnReasonDetails,
        'notes': notes?.join('; '),
        'attachmentUrls': attachmentUrls,
        'storeId': storeId,
      };

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    // Helper para extraer ID de campos que pueden ser String o Map
    String? _extractId(dynamic value) {
      if (value is String) return value;
      if (value is Map) return (value as Map)['_id']?.toString();
      return null;
    }

    // Helper para extraer nombre de campos que pueden ser String o Map
    String? _extractName(dynamic value) {
      if (value is String) return value;
      if (value is Map) return (value as Map)['name']?.toString();
      return null;
    }

    // Extraer customerName de múltiples fuentes posibles
    String? customerNameValue = _extractName(json['customerName']) ?? 
                                _extractName(json['customerId']) ??
                                json['customer']?['name']?.toString();

    return ReturnRequest(
      id: json['_id'] as String?,
      orderId: _extractId(json['orderId']) ?? '',
      orderNumber: json['orderNumber'] as String?,
      type: ReturnType.fromValue(json['type'] as String? ?? 'return'),
      status: ReturnStatus.fromValue(json['status'] as String? ?? 'pending'),
      items: (json['items'] as List?)
          ?.map((i) => ReturnItem.fromJson(i as Map<String, dynamic>))
          .toList() ?? [],
      totalRefundAmount: (json['totalRefundAmount'] as num?)?.toDouble() ?? 0.0,
      refundMethod: RefundMethod.fromValue(json['refundMethod'] as String? ?? 'efectivo'),
      customerId: _extractId(json['customerId']),
      customerName: customerNameValue,
      storeId: _extractId(json['storeId']) ?? '',
      returnReasonCategory:
          ReturnReasonCategory.fromValue(json['returnReasonCategory'] as String? ?? 'other'),
      returnReasonDetails: json['returnReasonDetails'] as String?,
      requestedBy: _extractId(json['requestedBy']),
      requestedAt:
          json['requestedAt'] != null ? DateTime.parse(json['requestedAt'] as String) : null,
      approvedBy: _extractId(json['approvedBy']),
      approvedAt:
          json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
      processedBy: _extractId(json['processedBy']),
      processedAt:
          json['processedAt'] != null ? DateTime.parse(json['processedAt'] as String) : null,
      attachmentUrls: List<String>.from(json['attachmentUrls'] as List? ?? []),
      notes: List<String>.from(json['notes'] as List? ?? []),
      internalNotes: json['internalNotes'] as String?,
    );
  }
}
