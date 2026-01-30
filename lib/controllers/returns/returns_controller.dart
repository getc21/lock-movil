import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../models/returns/return_models.dart';
import '../../services/returns/returns_service.dart';
import 'package:flutter/material.dart';

class ReturnsController extends GetxController {
  final ReturnsService returnsService = ReturnsService(Dio());

  // State Variables
  final returns = <ReturnRequest>[].obs;
  final isLoading = false.obs;
  final error = Rxn<String>();
  final summary = Rxn<Map<String, dynamic>>();

  // Create Return Form Variables
  final selectedItems = <ReturnItem>[].obs;
  final selectedType = Rxn<ReturnType>();
  final selectedReason = Rxn<ReturnReasonCategory>();
  final selectedRefundMethod = Rxn<RefundMethod>();
  final reasonDetails = ''.obs;
  final notes = ''.obs;

  @override
  void onInit() {
    super.onInit();
    selectedType.value = ReturnType.return_;
    selectedReason.value = ReturnReasonCategory.other;
    selectedRefundMethod.value = RefundMethod.cash;
  }

  // Fetch returns with filters
  Future<void> fetchReturns({
    required String storeId,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? refundMethod,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final result = await returnsService.getReturnsWithFilters(
        storeId: storeId,
        status: status,
        type: type,
        startDate: startDate,
        endDate: endDate,
        customerId: customerId,
        refundMethod: refundMethod,
      );

      returns.value = result['returns'] as List<ReturnRequest>;
      summary.value = result['summary'];
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Error al obtener devoluciones: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Create return request
  Future<bool> createReturnRequest({
    required String orderId,
    required String storeId,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      if (selectedItems.isEmpty) {
        error.value = 'Debe agregar al menos un artículo';
        Get.snackbar('Error', 'Debe agregar al menos un artículo');
        return false;
      }

      await returnsService.createReturnRequest(
        orderId: orderId,
        type: selectedType.value ?? ReturnType.return_,
        items: selectedItems,
        refundMethod: selectedRefundMethod.value ?? RefundMethod.cash,
        reasonCategory: selectedReason.value ?? ReturnReasonCategory.other,
        returnReasonDetails: notes.value.isNotEmpty ? notes.value : 'Sin detalles adicionales',
        notes: notes.value.isNotEmpty ? notes.value : null,
        storeId: storeId,
      );

      Get.snackbar(
        'Éxito',
        'Solicitud de devolución creada exitosamente',
      );

      resetForm();
      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Error al crear solicitud: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Approve return request
  Future<bool> approveReturnRequest({
    required String returnRequestId,
    String? approvalNotes,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      await returnsService.approveReturnRequest(
        returnRequestId: returnRequestId,
        approvalNotes: approvalNotes,
      );

      Get.snackbar('Éxito', 'Devolución aprobada exitosamente');
      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Error al aprobar: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Process return and refund
  Future<bool> processReturnAndRefund({
    required String returnRequestId,
    String? processNotes,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      await returnsService.processReturnAndRefund(
        returnRequestId: returnRequestId,
        processNotes: processNotes,
      );

      Get.snackbar('Éxito', 'Reembolso procesado exitosamente');
      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Error al procesar: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Reject return request
  Future<bool> rejectReturnRequest({
    required String returnRequestId,
    required String rejectionReason,
    String? internalNotes,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      await returnsService.rejectReturnRequest(
        returnRequestId: returnRequestId,
        rejectionReason: rejectionReason,
        internalNotes: internalNotes,
      );

      Get.snackbar('Éxito', 'Devolución rechazada');
      return true;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Error al rechazar: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Add item to return
  void addItem({
    required String productId,
    required String productName,
    required int originalQuantity,
    required int quantity,
    required double unitPrice,
    required String returnReason,
    String? notes,
  }) {
    selectedItems.add(
      ReturnItem(
        productId: productId,
        productName: productName,
        originalQuantity: originalQuantity,
        returnQuantity: quantity,
        unitPrice: unitPrice,
        returnReason: returnReason,
        notes: notes,
      ),
    );
  }

  // Remove item from return
  void removeItem(int index) {
    if (index >= 0 && index < selectedItems.length) {
      selectedItems.removeAt(index);
    }
  }

  // Get total refund amount
  double getTotalRefund() {
    return selectedItems.fold(
      0.0,
      (sum, item) => sum + (item.returnQuantity * item.unitPrice),
    );
  }

  // Reset form
  void resetForm() {
    selectedItems.clear();
    selectedType.value = ReturnType.return_;
    selectedReason.value = ReturnReasonCategory.other;
    selectedRefundMethod.value = RefundMethod.cash;
    reasonDetails.value = '';
    notes.value = '';
  }

  // Get return status color
  Color getStatusColor(ReturnStatus status) {
    switch (status) {
      case ReturnStatus.pending:
        return Colors.orange;
      case ReturnStatus.approved:
        return Colors.blue;
      case ReturnStatus.completed:
        return Colors.green;
      case ReturnStatus.rejected:
        return Colors.red;
    }
  }
}
