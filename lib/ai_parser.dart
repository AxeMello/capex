import 'dart:convert';
import 'package:http/http.dart' as http;

const String geminiApiKey = '####################';
const String geminiUrl =
    'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';

Future<Map<String, dynamic>> parseDocumentWithAI(String ocrText) async {
  String accumulated = '';

  for (int attempt = 0; attempt < 3; attempt++) {
    final prompt = attempt == 0
        ? _initialPrompt(ocrText)
        : _continuationPrompt(accumulated);

    final response = await http.post(
      Uri.parse('$geminiUrl?key=$geminiApiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini error ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    String chunk =
        decoded['candidates'][0]['content']['parts'][0]['text'];

    chunk = stripMarkdown(chunk);
    accumulated += chunk;

    if (isJsonComplete(accumulated)) {
      final jsonStart = accumulated.indexOf('{');
      final jsonEnd = accumulated.lastIndexOf('}');
      return jsonDecode(accumulated.substring(jsonStart, jsonEnd + 1));
    }
  }

  throw Exception('AI failed to produce complete JSON after retries');
}

String _initialPrompt(String ocrText) => """
You are a strict JSON generator for multi-page document parsing.
Return ONLY raw JSON. No markdown. No explanations.

IMPORTANT: The text below may contain MULTIPLE PAGES from the same document.
Treat ALL pages as ONE CONTINUOUS DOCUMENT.
Combine data from all pages into a SINGLE structured output.

Extract structured data from the OCR text below.

Output format:
{
  "sheet_name": "Inferred Name",
  "columns": ["Column1", "Column2", "Column3"],
  "rows": [
    {"Column1": "value", "Column2": "value", "Column3": "value"},
    {"Column1": "value", "Column2": "value", "Column3": "value"}
  ]
}

Rules:
- If the document is a table spanning multiple pages, merge all rows into one table
- If the document is a form, combine all fields from all pages
- Deduplicate any repeated headers or labels
- Preserve the logical order of data across pages

OCR TEXT (may contain multiple pages):
\"\"\"$ocrText\"\"\"
""";

String _continuationPrompt(String partialJson) => """
The previous response was truncated.

Continue EXACTLY from where you stopped.
Do NOT repeat text.
Do NOT add explanations.
Output ONLY the remaining JSON characters.

Partial JSON so far:
$partialJson
""";

String stripMarkdown(String text) {
  // Remove markdown code blocks like ```json ... ``` or ``` ... ```
  return text
      .replaceAll(RegExp(r'```json\s*'), '')
      .replaceAll(RegExp(r'```\s*'), '')
      .trim();
}

bool isJsonComplete(String text) {
  int braceCount = 0;
  for (var char in text.runes) {
    if (char == '{'.codeUnitAt(0)) braceCount++;
    if (char == '}'.codeUnitAt(0)) braceCount--;
  }
  return braceCount == 0 && text.contains('{') && text.contains('}');
}