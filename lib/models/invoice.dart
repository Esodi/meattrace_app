class Invoice {
  final int? id;
  final String invoiceNumber;
  final int shop;
  final int? customer;
  final String? customerName;
  final String? customerContact;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerTin;
  final String? customerRef;
  final String status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final String? paymentTerms;
  final String? notes;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final int? createdBy;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<InvoiceItem> items;
  final List<InvoicePayment> payments;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.shop,
    this.customer,
    this.customerName,
    this.customerContact,
    this.customerEmail,
    this.customerPhone,
    this.customerAddress,
    this.customerTin,
    this.customerRef,
    this.status = 'pending',
    required this.issueDate,
    this.dueDate,
    this.paymentTerms,
    this.notes,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.totalAmount = 0.0,
    this.amountPaid = 0.0,
    this.balanceDue = 0.0,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.payments = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      invoiceNumber: json['invoice_number'] ?? '',
      shop: int.parse(json['shop'].toString()),
      customer: json['customer'] != null
          ? int.parse(json['customer'].toString())
          : null,
      customerName: json['customer_name'],
      customerContact: json['customer_contact'],
      customerEmail: json['customer_email'],
      customerPhone: json['customer_phone'],
      customerAddress: json['customer_address'],
      customerTin: json['customer_tin'],
      customerRef: json['customer_ref'],
      status: json['status'] ?? 'pending',
      issueDate: DateTime.parse(json['issue_date']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      paymentTerms: json['payment_terms'],
      notes: json['notes'],
      subtotal: json['subtotal'] != null
          ? (json['subtotal'] is num
                ? (json['subtotal'] as num).toDouble()
                : double.parse(json['subtotal'].toString()))
          : 0.0,
      taxAmount: json['tax_amount'] != null
          ? (json['tax_amount'] is num
                ? (json['tax_amount'] as num).toDouble()
                : double.parse(json['tax_amount'].toString()))
          : 0.0,
      totalAmount: json['total_amount'] != null
          ? (json['total_amount'] is num
                ? (json['total_amount'] as num).toDouble()
                : double.parse(json['total_amount'].toString()))
          : 0.0,
      amountPaid: json['amount_paid'] != null
          ? (json['amount_paid'] is num
                ? (json['amount_paid'] as num).toDouble()
                : double.parse(json['amount_paid'].toString()))
          : 0.0,
      balanceDue: json['balance_due'] != null
          ? (json['balance_due'] is num
                ? (json['balance_due'] as num).toDouble()
                : double.parse(json['balance_due'].toString()))
          : 0.0,
      createdBy: json['created_by'] != null
          ? int.parse(json['created_by'].toString())
          : null,
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => InvoiceItem.fromJson(item))
                .toList()
          : [],
      payments: json['payments'] != null
          ? (json['payments'] as List)
                .map((payment) => InvoicePayment.fromJson(payment))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'shop': shop,
      if (customer != null) 'customer': customer,
      if (customerContact != null) 'customer_contact': customerContact,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'customer_tin': customerTin,
      'customer_ref': customerRef,
      'issue_date': issueDate.toIso8601String().split('T')[0],
      if (dueDate != null) 'due_date': dueDate!.toIso8601String().split('T')[0],
      if (paymentTerms != null) 'payment_terms': paymentTerms,
      if (notes != null) 'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partially Paid';
      case 'overdue':
        return 'Overdue';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get isPaid => status == 'paid' || balanceDue <= 0;
  bool get isOverdue => status == 'overdue';
  bool get isCancelled => status == 'cancelled';
  bool get canEdit => status != 'completed' && status != 'cancelled';
}

class InvoiceItem {
  final int? id;
  final int? invoice;
  final int product;
  final String? productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;

  InvoiceItem({
    this.id,
    this.invoice,
    required this.product,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    double? subtotal,
  }) : subtotal = subtotal ?? (quantity * unitPrice);

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      invoice: json['invoice'] != null
          ? int.parse(json['invoice'].toString())
          : null,
      product: int.parse(json['product'].toString()),
      productName: json['product_name'],
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toDouble()
          : double.parse(json['quantity'].toString()),
      unitPrice: json['unit_price'] is num
          ? (json['unit_price'] as num).toDouble()
          : double.parse(json['unit_price'].toString()),
      subtotal: json['subtotal'] != null
          ? (json['subtotal'] is num
                ? (json['subtotal'] as num).toDouble()
                : double.parse(json['subtotal'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'product': product, 'quantity': quantity, 'unit_price': unitPrice};
  }
}

class InvoicePayment {
  final int? id;
  final int invoice;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? transactionReference;
  final String? notes;
  final int? recordedBy;
  final String? recordedByName;
  final DateTime? createdAt;

  InvoicePayment({
    this.id,
    required this.invoice,
    required this.amount,
    this.paymentMethod = 'cash',
    required this.paymentDate,
    this.transactionReference,
    this.notes,
    this.recordedBy,
    this.recordedByName,
    this.createdAt,
  });

  factory InvoicePayment.fromJson(Map<String, dynamic> json) {
    return InvoicePayment(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      invoice: int.parse(json['invoice'].toString()),
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'] ?? 'cash',
      paymentDate: DateTime.parse(json['payment_date']),
      transactionReference: json['transaction_reference'],
      notes: json['notes'],
      recordedBy: json['recorded_by'] != null
          ? int.parse(json['recorded_by'].toString())
          : null,
      recordedByName: json['recorded_by_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoice': invoice,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      if (transactionReference != null)
        'transaction_reference': transactionReference,
      if (notes != null) 'notes': notes,
    };
  }
}
