import 'package:flutter/foundation.dart';
import '../models/shop_settings.dart';
import '../services/shop_settings_service.dart';

class ShopSettingsProvider with ChangeNotifier {
  final ShopSettingsService _service = ShopSettingsService();

  ShopSettings? _settings;
  bool _isLoading = false;
  String? _error;

  ShopSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load settings
  Future<void> loadSettings() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;

    // Use microtask to avoid notifying during build phase if called from initState/didChangeDependencies
    Future.microtask(() => notifyListeners());

    try {
      _settings = await _service.getMySettings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create settings
  Future<void> createSettings(ShopSettings settings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _service.createSettings(settings);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update settings
  Future<void> updateSettings(int id, ShopSettings settings) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _service.updateSettings(id, settings);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update tax rate
  Future<void> updateTaxRate(double taxRate) async {
    if (_settings == null) return;

    try {
      _settings = await _service.partialUpdate(_settings!.id!, {
        'tax_rate': taxRate,
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update payment info
  Future<void> updatePaymentInfo(String paymentInfo) async {
    if (_settings == null) return;

    try {
      _settings = await _service.partialUpdate(_settings!.id!, {
        'payment_info': paymentInfo,
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Save all settings in one PATCH call
  Future<void> saveAllSettings(int id, Map<String, dynamic> data) async {
    try {
      _settings = await _service.partialUpdate(id, data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update business profile
  Future<void> updateBusinessProfile({
    required String companyName,
    String? businessEmail,
    String? businessPhone,
    String? businessAddress,
    String? website,
  }) async {
    if (_settings == null) return;

    try {
      _settings = await _service.partialUpdate(_settings!.id!, {
        'company_name': companyName,
        'business_email': businessEmail,
        'business_phone': businessPhone,
        'business_address': businessAddress,
        'website': website,
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update Branding
  Future<void> updateBranding({
    String? logo,
    String? headerText,
    String? footerText,
  }) async {
    if (_settings == null) return;

    try {
      final data = <String, dynamic>{};
      if (logo != null) data['company_logo_url'] = logo;
      if (headerText != null) data['company_header'] = headerText;
      if (footerText != null) data['company_footer'] = footerText;

      _settings = await _service.partialUpdate(_settings!.id!, data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update Prefixes
  Future<void> updatePrefixes({
    String? invoicePrefix,
    String? receiptPrefix,
  }) async {
    if (_settings == null) return;

    try {
      final data = <String, dynamic>{};
      if (invoicePrefix != null) data['invoice_prefix'] = invoicePrefix;
      if (receiptPrefix != null) data['receipt_prefix'] = receiptPrefix;

      _settings = await _service.partialUpdate(_settings!.id!, data);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update Bank Info
  Future<void> updateBankInfo({
    String? bankName,
    String? accountName,
    String? accountNumber,
  }) async {
    if (_settings == null) return;

    try {
      _settings = await _service.partialUpdate(_settings!.id!, {
        'bank_name': bankName,
        'bank_account_name': accountName,
        'bank_account_number': accountNumber,
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update Mobile Money Info
  Future<void> updateMobileMoneyInfo({String? number, String? provider}) async {
    if (_settings == null) return;

    try {
      _settings = await _service.partialUpdate(_settings!.id!, {
        'mobile_money_number': number,
        'mobile_money_provider': provider,
      });
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
