import 'package:shared_preferences/shared_preferences.dart';
import '../services/dio_client.dart';

class AuthUtils {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(DioClient.accessTokenKey);
  }
}
