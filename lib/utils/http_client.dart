import 'dart:convert';
import 'package:http/http.dart' as original_http;
export 'package:http/http.dart' hide get, post, put, patch, delete;
import 'package:http/http.dart' show Response;
import 'package:merit/services/auth_storage.dart';

Future<Map<String, String>> _injectAuth(Map<String, String>? headers) async {
  final token = await AuthStorage.getToken();
  final newHeaders = <String, String>{};
  if (headers != null) {
    newHeaders.addAll(headers);
  }
  if (token != null) {
    newHeaders['Authorization'] = 'Token $token';
  }
  return newHeaders;
}

Future<Response> get(Uri url, {Map<String, String>? headers}) async {
  final newHeaders = await _injectAuth(headers);
  return original_http.get(url, headers: newHeaders);
}

Future<Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final newHeaders = await _injectAuth(headers);
  return original_http.post(url, headers: newHeaders, body: body, encoding: encoding);
}

Future<Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final newHeaders = await _injectAuth(headers);
  return original_http.put(url, headers: newHeaders, body: body, encoding: encoding);
}

Future<Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final newHeaders = await _injectAuth(headers);
  return original_http.patch(url, headers: newHeaders, body: body, encoding: encoding);
}

Future<Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
  final newHeaders = await _injectAuth(headers);
  return original_http.delete(url, headers: newHeaders, body: body, encoding: encoding);
}
