import 'package:get/get.dart';
import 'package:bellezapp/models/quotation.dart';
import 'package:bellezapp/services/quotation_service.dart';

class QuotationController extends GetxController {
  late QuotationService _quotationService;
  
  final quotations = RxList<Quotation>();
  final isLoading = RxBool(false);
  final error = RxString('');

  @override
  void onInit() {
    super.onInit();
    _quotationService = QuotationService();
  }

  Future<void> fetchQuotations({
    String? storeId,
    String? customerId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final data = await _quotationService.getQuotations(
        storeId: storeId,
        customerId: customerId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      
      quotations.value = data;
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createQuotation({
    required List<Map<String, dynamic>> items,
    required String storeId,
    String? customerId,
    String? discountId,
    double discountAmount = 0.0,
    String? paymentMethod,
    String? userId,
    DateTime? expirationDate,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      final quotation = await _quotationService.createQuotation(
        items: items,
        storeId: storeId,
        customerId: customerId,
        discountId: discountId,
        discountAmount: discountAmount,
        paymentMethod: paymentMethod,
        userId: userId,
        expirationDate: expirationDate,
      );
      
      quotations.add(quotation);
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> convertQuotationToOrder(
    String quotationId, {
    String? paymentMethod,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await _quotationService.convertQuotationToOrder(
        quotationId,
        paymentMethod: paymentMethod,
      );
      
      // Actualizar el estado de la cotización en la lista
      final index = quotations.indexWhere((q) => q.id == quotationId);
      if (index != -1) {
        quotations[index] = Quotation(
          id: quotations[index].id,
          quotationDate: quotations[index].quotationDate,
          expirationDate: quotations[index].expirationDate,
          totalQuotation: quotations[index].totalQuotation,
          customerId: quotations[index].customerId,
          customerName: quotations[index].customerName,
          storeId: quotations[index].storeId,
          items: quotations[index].items,
          userId: quotations[index].userId,
          discountId: quotations[index].discountId,
          discountAmount: quotations[index].discountAmount,
          paymentMethod: quotations[index].paymentMethod,
          notes: quotations[index].notes,
          status: 'converted',
          convertedOrderId: quotations[index].convertedOrderId,
          createdAt: quotations[index].createdAt,
          updatedAt: quotations[index].updatedAt,
        );
      }
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteQuotation(String quotationId) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      await _quotationService.deleteQuotation(quotationId);
      quotations.removeWhere((q) => q.id == quotationId);
    } catch (e) {
      error.value = e.toString();
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}
