import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi/config/api_constants.dart';
import 'package:absensi/services/token_storage_service.dart';

void main() {
  group('ApiConstants Tests', () {
    test('Default baseUrl is not empty and ends with /api', () {
      expect(ApiConstants.baseUrl, isNotEmpty);
      expect(ApiConstants.baseUrl.endsWith('/api'), isTrue);
    });

    test('Environment switching works as expected', () {
      // Test Emulator
      ApiConstants.setEnvironment(ApiEnvironment.emulator);
      expect(ApiConstants.baseUrl, equals('http://10.0.2.2:3000/api'));

      // Test Localhost
      ApiConstants.setEnvironment(ApiEnvironment.localhost);
      expect(ApiConstants.baseUrl, equals('http://localhost:3000/api'));

      // Test LAN IP
      ApiConstants.lanIp = '192.168.1.50';
      ApiConstants.setEnvironment(ApiEnvironment.lan);
      expect(ApiConstants.baseUrl, equals('http://192.168.1.50:3000/api'));

      // Test Production (AWS)
      ApiConstants.productionBaseUrl = 'https://absensi.company.com/api';
      ApiConstants.setEnvironment(ApiEnvironment.production);
      expect(ApiConstants.baseUrl, equals('https://absensi.company.com/api'));
    });

    test('Custom baseUrl override works', () {
      ApiConstants.setCustomBaseUrl('http://custom-server:8080/api/');
      expect(ApiConstants.baseUrl, equals('http://custom-server:8080/api'));
    });

    test('Auth headers contain Bearer token and JSON types', () {
      const dummyToken = 'my_test_jwt_token_123';
      final headers = ApiConstants.authHeaders(dummyToken);

      expect(headers['Content-Type'], equals('application/json'));
      expect(headers['Accept'], equals('application/json'));
      expect(headers['Authorization'], equals('Bearer $dummyToken'));
    });
  });

  group('TokenStorageService Tests', () {
    late TokenStorageService tokenStorage;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      tokenStorage = TokenStorageService();
    });

    test('saveToken and getToken workflow', () async {
      expect(await tokenStorage.hasToken(), isFalse);
      expect(await tokenStorage.getToken(), isNull);

      const token = 'sample_jwt_token_value';
      final saved = await tokenStorage.saveToken(token);
      expect(saved, isTrue);

      expect(await tokenStorage.hasToken(), isTrue);
      expect(await tokenStorage.getToken(), equals(token));

      final cleared = await tokenStorage.clearToken();
      expect(cleared, isTrue);
      expect(await tokenStorage.hasToken(), isFalse);
      expect(await tokenStorage.getToken(), isNull);
    });

    test('saveUserCache and getUserCache workflow', () async {
      expect(await tokenStorage.getUserCache(), isNull);

      final dummyUser = {
        'uid': 'usr_123',
        'name': 'Budi Santoso',
        'role': 'employee',
      };

      await tokenStorage.saveUserCache(dummyUser);
      final cached = await tokenStorage.getUserCache();

      expect(cached, isNotNull);
      expect(cached!['uid'], equals('usr_123'));
      expect(cached['name'], equals('Budi Santoso'));

      await tokenStorage.clearAll();
      expect(await tokenStorage.getUserCache(), isNull);
      expect(await tokenStorage.hasToken(), isFalse);
    });
  });
}

