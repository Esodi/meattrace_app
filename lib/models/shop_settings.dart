class ShopSettings {
  final int? id;
  final int shop;

  // Tax Configuration
  final bool taxEnabled;
  final double taxRate;
  final String taxLabel;
  final String currency;

  // Branding
  final String? logo; // Image file location/url
  final String? companyLogoUrl;
  final String? companyName;
  final String? headerText;
  final String? footerText;

  // Prefixes
  final String invoicePrefix;
  final int nextInvoiceNumber;
  final String receiptPrefix;
  final int nextReceiptNumber;

  // Contact Information
  final String? businessEmail;
  final String? businessPhone;
  final String? businessAddress;
  final String? website;
  final String? taxId;

  // Payment Information
  final String? bankName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? mobileMoneyNumber;
  final String? mobileMoneyProvider;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  ShopSettings({
    this.id,
    required this.shop,
    this.taxEnabled = true,
    this.taxRate = 0.0,
    this.taxLabel = 'VAT',
    this.currency = 'TZS',
    this.logo,
    this.companyLogoUrl,
    this.companyName,
    this.headerText,
    this.footerText,
    this.invoicePrefix = 'INV',
    this.nextInvoiceNumber = 1,
    this.receiptPrefix = 'RCP',
    this.nextReceiptNumber = 1,
    this.businessEmail,
    this.businessPhone,
    this.businessAddress,
    this.website,
    this.taxId,
    this.bankName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.mobileMoneyNumber,
    this.mobileMoneyProvider,
    this.createdAt,
    this.updatedAt,
  });

  factory ShopSettings.fromJson(Map<String, dynamic> json) {
    return ShopSettings(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      shop: int.parse(json['shop'].toString()),
      taxEnabled: json['tax_enabled'] ?? true,
      taxRate: json['tax_rate'] != null
          ? (json['tax_rate'] is num
                ? (json['tax_rate'] as num).toDouble()
                : double.parse(json['tax_rate'].toString()))
          : 0.0,
      taxLabel: json['tax_label'] ?? 'VAT',
      currency: json['currency'] ?? 'TZS',
      logo: json['company_logo'] ?? json['logo'], // Try both naming conventions
      companyLogoUrl: json['company_logo_url'],
      companyName: json['company_name'],
      headerText: json['company_header'] ?? json['header_text'],
      footerText: json['company_footer'] ?? json['footer_text'],
      invoicePrefix: json['invoice_prefix'] ?? 'INV',
      nextInvoiceNumber: json['next_invoice_number'] != null
          ? int.parse(json['next_invoice_number'].toString())
          : 1,
      receiptPrefix: json['receipt_prefix'] ?? 'RCP',
      nextReceiptNumber: json['next_receipt_number'] != null
          ? int.parse(json['next_receipt_number'].toString())
          : 1,
      businessEmail: json['business_email'],
      businessPhone: json['business_phone'],
      businessAddress: json['business_address'],
      website: json['website'],
      taxId: json['tax_id'],
      bankName: json['bank_name'],
      bankAccountName: json['bank_account_name'],
      bankAccountNumber: json['bank_account_number'],
      mobileMoneyNumber: json['mobile_money_number'],
      mobileMoneyProvider: json['mobile_money_provider'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'shop': shop,
      'tax_enabled': taxEnabled,
      'tax_rate': taxRate,
      'tax_label': taxLabel,
      'currency': currency,
      'company_name': companyName,
      'company_logo': logo,
      'company_logo_url': companyLogoUrl,
      'company_header': headerText,
      'company_footer': footerText,
      'invoice_prefix': invoicePrefix,
      'next_invoice_number': nextInvoiceNumber,
      'receipt_prefix': receiptPrefix,
      'next_receipt_number': nextReceiptNumber,
      'business_email': businessEmail,
      'business_phone': businessPhone,
      'business_address': businessAddress,
      'website': website,
      'tax_id': taxId,
      'bank_name': bankName,
      'bank_account_name': bankAccountName,
      'bank_account_number': bankAccountNumber,
      'mobile_money_number': mobileMoneyNumber,
      'mobile_money_provider': mobileMoneyProvider,
    };
  }

  ShopSettings copyWith({
    int? id,
    int? shop,
    bool? taxEnabled,
    double? taxRate,
    String? taxLabel,
    String? currency,
    String? logo,
    String? companyLogoUrl,
    String? companyName,
    String? headerText,
    String? footerText,
    String? invoicePrefix,
    int? nextInvoiceNumber,
    String? receiptPrefix,
    int? nextReceiptNumber,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? website,
    String? taxId,
    String? bankName,
    String? bankAccountName,
    String? bankAccountNumber,
    String? mobileMoneyNumber,
    String? mobileMoneyProvider,
  }) {
    return ShopSettings(
      id: id ?? this.id,
      shop: shop ?? this.shop,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxRate: taxRate ?? this.taxRate,
      taxLabel: taxLabel ?? this.taxLabel,
      currency: currency ?? this.currency,
      logo: logo ?? this.logo,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      companyName: companyName ?? this.companyName,
      headerText: headerText ?? this.headerText,
      footerText: footerText ?? this.footerText,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextInvoiceNumber: nextInvoiceNumber ?? this.nextInvoiceNumber,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      nextReceiptNumber: nextReceiptNumber ?? this.nextReceiptNumber,
      businessEmail: businessEmail ?? this.businessEmail,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      bankName: bankName ?? this.bankName,
      bankAccountName: bankAccountName ?? this.bankAccountName,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      mobileMoneyNumber: mobileMoneyNumber ?? this.mobileMoneyNumber,
      mobileMoneyProvider: mobileMoneyProvider ?? this.mobileMoneyProvider,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
