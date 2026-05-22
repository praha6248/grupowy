import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'pomiar_model.dart';

class ApiService {
  late Dio _dio;
  final String baseUrl =
      "http://wgndjm6j2bxbluou33tnamlulusu7rrrtz2a7usho2y7s33bl6iqrayd.onion";

  ApiService() {
    _dio = Dio();

    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();

        client.findProxy = (uri) {
          return "SOCKS5 127.0.0.1:9050";
        };

        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );

    _dio.options.connectTimeout = const Duration(seconds: 20);
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
