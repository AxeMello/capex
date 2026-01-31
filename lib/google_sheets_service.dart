import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/auth_io.dart';

/// Public spreadsheet ID
const String spreadsheetId =
    '1ZCynptiGeYfjvmk5OIzjOAf9JFxcL249gORg-Kui_eA';

const List<String> sheetsScopes = [
  sheets.SheetsApi.spreadsheetsScope,
];

/// Public API getter
Future<sheets.SheetsApi> getSheetsApi() async {
  final jsonKey =
      await rootBundle.loadString('assets/service_account.json');

  final credentials =
      ServiceAccountCredentials.fromJson(jsonDecode(jsonKey));

  final client =
      await clientViaServiceAccount(credentials, sheetsScopes);

  return sheets.SheetsApi(client);
}
