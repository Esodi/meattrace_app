import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/invoice.dart';
import '../utils/auth_utils.dart';
import '../utils/constants.dart';

class InvoiceService {
  static const String baseUrl = '${Constants.baseUrl}/invoices';

  // Get all invoices for the shop
  Future<List<Invoice>> getInvoices() async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Invoice.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load invoices: ${response.body}');
    }
  }

  // Get single invoice by ID
  Future<Invoice> getInvoice(int id) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Invoice.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load invoice: ${response.body}');
    }
  }

  // Create new invoice
  Future<Invoice> createInvoice(Invoice invoice) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.post(
      Uri.parse('$baseUrl/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(invoice.toJson()),
    );

    if (response.statusCode == 201) {
      return Invoice.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create invoice: ${response.body}');
    }
  }

  // Update invoice
  Future<Invoice> updateInvoice(int id, Invoice invoice) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.put(
      Uri.parse('$baseUrl/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(invoice.toJson()),
    );

    if (response.statusCode == 200) {
      return Invoice.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update invoice: ${response.body}');
    }
  }

  // Record payment against invoice
  Future<InvoicePayment> recordPayment({
    required int invoiceId,
    required double amount,
    required String paymentMethod,
    String? transactionReference,
    String? notes,
  }) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.post(
      Uri.parse('$baseUrl/$invoiceId/record_payment/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'amount': amount,
        'payment_method': paymentMethod,
        if (transactionReference != null)
          'transaction_reference': transactionReference,
        if (notes != null) 'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      return InvoicePayment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to record payment: ${response.body}');
    }
  }

  // Convert invoice to sale
  Future<Map<String, dynamic>> convertToSale({
    required int invoiceId,
    required String paymentMethod,
  }) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.post(
      Uri.parse('$baseUrl/$invoiceId/convert_to_sale/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'payment_method': paymentMethod}),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to convert to sale: ${response.body}');
    }
  }

  // Cancel invoice
  Future<Invoice> cancelInvoice(int invoiceId) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.post(
      Uri.parse('$baseUrl/$invoiceId/cancel/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Invoice.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to cancel invoice: ${response.body}');
    }
  }

  // Get invoice statistics
  Future<Map<String, dynamic>> getStats() async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/stats/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load stats: ${response.body}');
    }
  }

  // Delete invoice
  Future<void> deleteInvoice(int id) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.delete(
      Uri.parse('$baseUrl/$id/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete invoice: ${response.body}');
    }
  }

  // Download invoice PDF
  Future<Uint8List> downloadInvoicePdf(int invoiceId) async {
    final token = await AuthUtils.getToken();
    if (token == null) throw Exception('No authentication token found');

    final response = await http.get(
      Uri.parse('$baseUrl/$invoiceId/download_pdf/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download invoice PDF: ${response.body}');
    }
  }
}
