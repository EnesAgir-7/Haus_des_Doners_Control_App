import 'package:flutter_dotenv/flutter_dotenv.dart';

class OneDriveConfig {
  static String? clientSecretValue = dotenv.env['CLIENT_SECRET_VALUE'];
  static String? clientId = dotenv.env['CLIENT_ID'];
  static const String redirectUri =
      'msauth://com.example.haus_des_control/callback';
  static String? tenantId = dotenv.env['TENANT_ID'];
  static String? clientSecretId = dotenv.env['CLIENT_SECRET_ID'];
  static String? serviceUserId = dotenv.env['SERVICE_USER_ID'];
  static String? myUserId = dotenv.env['MY_USER_ID'];
  static const String graphApiBaseUrl = 'https://graph.microsoft.com/v1.0';
}
