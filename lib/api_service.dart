import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? defaultBaseUrl;

  final String baseUrl;

  static String get defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://127.0.0.1:3000';
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<WalletUser> login(String email, String password) async {
    final data = await _request(
      'POST',
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return WalletUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<WalletUser> register(
    String name,
    String email,
    String password,
  ) async {
    final data = await _request(
      'POST',
      '/auth/register',
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return WalletUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<List<WalletTransaction>> getTransactions(int userId) async {
    final data = await _request('GET', '/transactions/$userId');
    return (data['items'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            [])
        .map((item) => WalletTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<WalletTransaction> saveTransaction(
    WalletTransaction transaction,
  ) async {
    final isNew = transaction.id <= 0;
    final data = await _request(
      isNew ? 'POST' : 'PUT',
      isNew ? '/transactions' : '/transactions/${transaction.id}',
      body: transaction.toJson(),
    );
    return WalletTransaction.fromJson(
      data['transaction'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteTransaction(int id, int userId) =>
      _request('DELETE', '/transactions/$id?userId=$userId');

  Future<List<Budget>> getBudgets(int userId) async {
    final data = await _request('GET', '/budgets/$userId');
    return (data['items'] as List<dynamic>? ?? [])
        .map((item) => Budget.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Budget> saveBudget(Budget budget) async {
    final data = await _request(
      budget.id <= 0 ? 'POST' : 'PUT',
      budget.id <= 0 ? '/budgets' : '/budgets/${budget.id}',
      body: budget.toJson(),
    );
    return Budget.fromJson(data['budget'] as Map<String, dynamic>);
  }

  Future<void> deleteBudget(int id, int userId) =>
      _request('DELETE', '/budgets/$id?userId=$userId');

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      late http.Response response;
      final headers = {'Content-Type': 'application/json'};
      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 8));
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 8));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 8));
          break;
        default:
          response = await http.get(uri).timeout(const Duration(seconds: 8));
      }
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          (decoded['error'] ??
                  decoded['hata'] ??
                  'İşlem tamamlanamadı (${response.statusCode}).')
              .toString(),
        );
      }
      return decoded;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Sunucuya ulaşılamadı. İnternet bağlantını kontrol edip tekrar dene.',
      );
    }
  }
}
