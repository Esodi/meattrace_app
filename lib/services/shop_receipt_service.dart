import 'package:dio/dio.dart';
import '../models/shop_receipt.dart';
import 'dio_client.dart';

class ShopReceiptService {
  static final ShopReceiptService _instance = ShopReceiptService._internal();
  final DioClient _dioClient = DioClient();

  factory ShopReceiptService() {
    return _instance;
  }

  ShopReceiptService._internal();

  Future<void> recordReceipt(ShopReceipt receipt) async {
    try {
      await _dioClient.dio.post(
        '/receipts/',
        data: receipt.toJson()..remove('id'),
      );
    } on DioException catch (e) {
      throw Exception('Failed to record receipt: ${e.message}');
    }
  }
}








