class OneDriveConfig {
  static const String clientId = '79623117-0b91-48fa-a980-d381a8b89c2c';
  static const String redirectUri =
      'msauth://com.example.haus_des_control/callback';
  static const String tenantId =
      '1644e6ef-136f-4303-a4eb-b05061884f54'; // Use 'common' for personal and work accounts
  // '22d9fb37-d78d-4262-a9ea-67e31db45f6b'; // Use 'common' for personal and work accounts

  static const List<String> scopes = [
    'Files.ReadWrite',
    'Files.ReadWrite.All',
    'offline_access',
    'User.Read',
  ];

  static const String graphApiBaseUrl = 'https://graph.microsoft.com/v1.0';
}
