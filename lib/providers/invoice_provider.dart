import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceProvider with ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();

  List<Invoice> _invoices = [];
  Invoice? _currentInvoice;
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;

  List<Invoice> get invoices => _invoices;
  Invoice? get currentInvoice => _currentInvoice;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter invoices by status
  List<Invoice> getInvoicesByStatus(String status) {
    return _invoices.where((invoice) => invoice.status == status).toList();
  }

  // Get pending invoices
  List<Invoice> get pendingInvoices => getInvoicesByStatus('pending');

  // Get paid invoices
  List<Invoice> get paidInvoices => getInvoicesByStatus('paid');

  // Get overdue invoices
  List<Invoice> get overdueInvoices => getInvoicesByStatus('overdue');

  // Load all invoices
  Future<void> loadInvoices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _invoices = await _invoiceService.getInvoices();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Load single invoice
  Future<void> loadInvoice(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentInvoice = await _invoiceService.getInvoice(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Create invoice
  Future<Invoice> createInvoice(Invoice invoice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newInvoice = await _invoiceService.createInvoice(invoice);
      _invoices.insert(0, newInvoice);
      _isLoading = false;
      notifyListeners();
      return newInvoice;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update invoice
  Future<Invoice> updateInvoice(int id, Invoice invoice) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedInvoice = await _invoiceService.updateInvoice(id, invoice);
      final index = _invoices.indexWhere((inv) => inv.id == id);
      if (index != -1) {
        _invoices[index] = updatedInvoice;
      }
      if (_currentInvoice?.id == id) {
        _currentInvoice = updatedInvoice;
      }
      _isLoading = false;
      notifyListeners();
      return updatedInvoice;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Record payment
  Future<void> recordPayment({
    required int invoiceId,
    required double amount,
    required String paymentMethod,
    String? transactionReference,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _invoiceService.recordPayment(
        invoiceId: invoiceId,
        amount: amount,
        paymentMethod: paymentMethod,
        transactionReference: transactionReference,
        notes: notes,
      );
      // Reload the invoice to get updated payment info
      await loadInvoice(invoiceId);
      // Also update in the list
      final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
      if (index != -1) {
        final updatedInvoice = await _invoiceService.getInvoice(invoiceId);
        _invoices[index] = updatedInvoice;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Convert to sale
  Future<void> convertToSale({
    required int invoiceId,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _invoiceService.convertToSale(
        invoiceId: invoiceId,
        paymentMethod: paymentMethod,
      );
      // Reload invoice to get updated status
      await loadInvoice(invoiceId);
      final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
      if (index != -1) {
        final updatedInvoice = await _invoiceService.getInvoice(invoiceId);
        _invoices[index] = updatedInvoice;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Cancel invoice
  Future<void> cancelInvoice(int invoiceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cancelledInvoice = await _invoiceService.cancelInvoice(invoiceId);
      final index = _invoices.indexWhere((inv) => inv.id == invoiceId);
      if (index != -1) {
        _invoices[index] = cancelledInvoice;
      }
      if (_currentInvoice?.id == invoiceId) {
        _currentInvoice = cancelledInvoice;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Load statistics
  Future<void> loadStats() async {
    try {
      _stats = await _invoiceService.getStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Delete invoice
  Future<void> deleteInvoice(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _invoiceService.deleteInvoice(id);
      _invoices.removeWhere((invoice) => invoice.id == id);
      if (_currentInvoice?.id == id) {
        _currentInvoice = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Download invoice PDF
  Future<Uint8List> downloadInvoicePdf(int invoiceId) async {
    try {
      return await _invoiceService.downloadInvoicePdf(invoiceId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
