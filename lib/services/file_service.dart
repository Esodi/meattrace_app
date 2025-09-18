import 'dart:io';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../utils/constants.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  final DioClient _dioClient = DioClient();

  factory FileService() {
    return _instance;
  }

  FileService._internal();

  Future<Map<String, dynamic>> uploadFile(
    File file,
    String entityType,
    int entityId,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        'entity_type': entityType,
        'entity_id': entityId,
      });

      final response = await _dioClient.dio.post(
        Constants.uploadEndpoint,
        data: formData,
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception('File upload failed: ${e.message}');
    }
  }

  Future<void> downloadFile(String fileUrl, String savePath) async {
    try {
      await _dioClient.dio.download(
        fileUrl,
        savePath,
      );
    } on DioException catch (e) {
      throw Exception('File download failed: ${e.message}');
    }
  }
}