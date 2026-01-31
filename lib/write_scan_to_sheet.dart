import 'package:googleapis/sheets/v4.dart' as sheets;
import 'google_sheets_service.dart';

Future<void> writeScanResultToGoogleSheet(
  Map<String, dynamic> scanResult,
) async {
  final api = await getSheetsApi();

  final sheetName = _deduceSheetName(
    scanResult['sheet_name'] ?? 'Scan',
  );

  // 1. Create a new sheet
  await api.spreadsheets.batchUpdate(
    sheets.BatchUpdateSpreadsheetRequest(
      requests: [
        sheets.Request(
          addSheet: sheets.AddSheetRequest(
            properties: sheets.SheetProperties(
              title: sheetName,
            ),
          ),
        ),
      ],
    ),
    spreadsheetId, // This is now imported from google_sheets_service.dart
  );

  final columns = List<String>.from(scanResult['columns']);
  final rows = List<Map<String, dynamic>>.from(scanResult['rows']);

  // 2. Prepare values
  final values = <List<Object?>>[];

  values.add(columns); // header row

  for (final row in rows) {
    values.add(
      columns.map((c) => row[c] ?? '').toList(),
    );
  }

  // 3. Write values
  await api.spreadsheets.values.update(
    sheets.ValueRange(values: values),
    spreadsheetId, // This is now imported from google_sheets_service.dart
    "'$sheetName'!A1",
    valueInputOption: 'RAW',
  );
}

String _deduceSheetName(String base) {
  final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
  return '$base $ts';
}