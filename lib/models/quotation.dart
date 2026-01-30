class Quotation {
  final String? id;
  final DateTime quotationDate;
  final DateTime? expirationDate;
  final double totalQuotation;
  final String? customerId;
  final String? customerName;
  final String? storeId;
  final List<QuotationItem> items;
  final String? userId;
  final String? discountId;
  final double discountAmount;
  final String? paymentMethod;
  final String? notes;
  final String status; // pending, converted, expired, cancelled
  final String? convertedOrderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quotation({
    this.id,
    required this.quotationDate,
    this.expirationDate,
    required this.totalQuotation,
    this.customerId,
    this.customerName,
    required this.storeId,
    required this.items,
    this.userId,
    this.discountId,
    this.discountAmount = 0.0,
    this.paymentMethod,
    this.notes,
    this.status = 'pending',
    this.convertedOrderId,
    this.createdAt,
    this.updatedAt,
  });

  factory Quotation.fromMap(Map<String, dynamic> json) {
    return Quotation(
      id: json['_id'] ?? json['id'],
      quotationDate: json['quotationDate'] != null
          ? DateTime.parse(json['quotationDate'].toString())
          : DateTime.now(),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'].toString())
          : null,
      totalQuotation: (json['totalQuotation'] as num?)?.toDouble() ?? 0.0,
      customerId: json['customerId'] is Map
          ? json['customerId']['_id'] ?? json['customerId']['id']
          : json['customerId'],
      customerName: json['customerId'] is Map
          ? json['customerId']['name']
          : null,
      storeId: json['storeId'] is Map
          ? json['storeId']['_id'] ?? json['storeId']['id']
          : json['storeId'],
      items: json['items'] != null
          ? List<QuotationItem>.from(
              (json['items'] as List).map((x) => QuotationItem.fromMap(x)))
          : [],
      userId: json['userId'] is Map
          ? json['userId']['_id'] ?? json['userId']['id']
          : json['userId'],
      discountId: json['discountId'] is Map
          ? json['discountId']['_id'] ?? json['discountId']['id']
          : json['discountId'],
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      convertedOrderId: json['convertedOrderId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'quotationDate': quotationDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'totalQuotation': totalQuotation,
      'customerId': customerId,
      'storeId': storeId,
      'items': items.map((x) => x.toMap()).toList(),
      'userId': userId,
      'discountId': discountId,
      'discountAmount': discountAmount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'status': status,
      'convertedOrderId': convertedOrderId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class QuotationItem {
  final String? productId;
  final String? productName;
  final int quantity;
  final double price;

  QuotationItem({
    required this.productId,
    this.productName,
    required this.quantity,
    required this.price,
  });

  factory QuotationItem.fromMap(Map<String, dynamic> json) {
    return QuotationItem(
      productId: json['productId'] is Map
          ? json['productId']['_id'] ?? json['productId']['id']
          : json['productId'],
      productName: json['productId'] is Map
          ? json['productId']['name']
          : null,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}
