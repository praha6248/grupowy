import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'pomiar_model.dart';
import 'package:socks5_proxy/socks_client.dart';

class ApiService {
  late Dio _dio;
  final String baseUrl =
      "http://eyfqp7vhlaxmo7adqdwz53golzfylabwzg6xoxqfpdve5g6xv6yvoyyd.onion";

  ApiService() {
    _dio = Dio();

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        SocksTCPClient.assignToHttpClient(client, [
          ProxySettings(InternetAddress.loopbackIPv4, 9050),
        ]);
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );

    _dio.options.connectTimeout = const Duration(seconds: 50);
  }

  Future<Pomiar> getOstatniPomiar() async {
    try {
      final response = await _dio.get('$baseUrl/pomiary/ostatni');
      return Pomiar.fromJson(response.data);
    } catch (e) {
      throw Exception('Błąd ostatniego pomiaru: $e');
    }
  }

  Future<List<Pomiar>> getHistoriaPomiarow({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/pomiary/historia',
        queryParameters: {'limit': limit},
      );
      return (response.data as List).map((p) => Pomiar.fromJson(p)).toList();
    } catch (e) {
      throw Exception('Błąd historii: $e');
    }
  }

  Future<Lokalizacja> getOstatniaLokalizacja() async {
    try {
      final response = await _dio.get('$baseUrl/lokalizacja/ostatnia');
      return Lokalizacja.fromJson(response.data);
    } catch (e) {
      throw Exception('Błąd GPS: $e');
    }
  }

  Future<List<Zdarzenie>> getZdarzenia({int limit = 5}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/zdarzenia',
        queryParameters: {'limit': limit},
      );
      return (response.data as List).map((z) => Zdarzenie.fromJson(z)).toList();
    } catch (e) {
      throw Exception('Błąd zdarzeń: $e');
    }
  }
}
