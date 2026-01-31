// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:url_launcher/url_launcher.dart';

import 'google_sheets_service.dart';

class SheetScreen extends StatefulWidget {
  final bool shouldRefresh;
  
  const SheetScreen({super.key, this.shouldRefresh = false});

  @override
  State<SheetScreen> createState() => _SheetScreenState();
}

class _SheetScreenState extends State<SheetScreen> {
  bool _loadingSheets = true;
  bool _loadingValues = false;

  List<String> _sheetTitles = const [];
  String? _selectedTitle;

  // Values as strings (header row included if present)
  List<List<String>> _values = const [];

  // For the table view (bigger + readable)
  static const double _cellMinWidth = 200;
  static const double _headerFontSize = 16;
  static const double _cellFontSize = 15;
  static const double _minRowHeight = 60;

  // Theme colors
  static const Color _primaryBlue = Color(0xFFD4F9FF);
  static const Color _accentBlue = Color(0xFF8FE3F9);
  static const Color _darkBlue = Color(0xFF2B7A8C);
  static const Color _headerBg = Color(0xFFE8FCFF);
  static const Color _rowEven = Color(0xFFF8FEFF);
  static const Color _rowOdd = Colors.white;
  static const Color _borderColor = Color(0xFFCCEFF5);

  Uri get _spreadsheetUri =>
      Uri.parse('https://docs.google.com/spreadsheets/d/$spreadsheetId/edit');

  @override
  void initState() {
    super.initState();
    _loadSheets();
  }

  @override
  void didUpdateWidget(SheetScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when shouldRefresh flag changes
    if (widget.shouldRefresh && !oldWidget.shouldRefresh) {
      _loadSheets();
    }
  }

  Future<void> _loadSheets() async {
    setState(() {
      _loadingSheets = true;
    });

    final api = await getSheetsApi();

    final spreadsheet = await api.spreadsheets.get(
      spreadsheetId,
      includeGridData: false,
    );

    final titles = (spreadsheet.sheets ?? const <sheets.Sheet>[])
        .map((s) => s.properties?.title)
        .whereType<String>()
        .toList();

    // Sort by name descending (newest first - they have timestamps)
    titles.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));

    setState(() {
      _sheetTitles = titles;
      // Always select the LAST sheet (newest)
      _selectedTitle = titles.isNotEmpty ? titles.last : null;
      _loadingSheets = false;
    });

    if (_selectedTitle != null) {
      await _loadValues(_selectedTitle!);
    }
  }

  Future<void> _loadValues(String sheetTitle) async {
    setState(() {
      _loadingValues = true;
      _values = const [];
    });

    try {
      final api = await getSheetsApi();

      final range = "'$sheetTitle'";
      final res = await api.spreadsheets.values.get(spreadsheetId, range);

      final raw = (res.values ?? const <List<Object?>>[])
          .map((row) => row.map((v) => (v ?? '').toString()).toList())
          .toList();

      final maxCols = raw.isEmpty
          ? 0
          : raw.map((r) => r.length).reduce((a, b) => a > b ? a : b);

      final normalized = raw
          .map((r) => [
                ...r,
                for (var i = r.length; i < maxCols; i++) '',
              ])
          .toList();

      setState(() {
        _values = normalized;
      });
    } finally {
      setState(() {
        _loadingValues = false;
      });
    }
  }

  Future<void> _pickSheetFromList() async {
    if (_sheetTitles.isEmpty) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.table_chart_rounded, color: _darkBlue, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Select Sheet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: _borderColor, thickness: 1, height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _sheetTitles.length,
                  separatorBuilder: (_, __) => Divider(
                    color: _borderColor,
                    thickness: 1,
                    height: 1,
                    indent: 20,
                    endIndent: 20,
                  ),
                  itemBuilder: (_, i) {
                    final t = _sheetTitles[i];
                    final selected = t == _selectedTitle;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected ? _accentBlue : _primaryBlue.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: selected ? _darkBlue : _darkBlue.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        t,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? _darkBlue : Colors.black87,
                        ),
                      ),
                      trailing: selected
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _accentBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_rounded, color: _darkBlue, size: 18),
                            )
                          : null,
                      onTap: () => Navigator.pop(ctx, t),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (picked != null && picked != _selectedTitle) {
      setState(() => _selectedTitle = picked);
      await _loadValues(picked);
    }
  }

  Future<void> _openInBrowser() async {
    final ok = await launchUrl(
      _spreadsheetUri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open browser'),
          backgroundColor: _darkBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _deleteCurrentSheet() async {
    if (_selectedTitle == null || _sheetTitles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot delete the last sheet'),
          duration: const Duration(seconds: 2),
          backgroundColor: _darkBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final titleToDelete = _selectedTitle!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 24),
              ),
              const SizedBox(width: 14),
              const Text(
                'Delete Sheet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "$titleToDelete"?\n\nThis action cannot be undone.',
            style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: _darkBlue, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final api = await getSheetsApi();

      final spreadsheet = await api.spreadsheets.get(
        spreadsheetId,
        includeGridData: false,
      );

      final matched = (spreadsheet.sheets ?? const <sheets.Sheet>[])
          .where((s) => s.properties?.title == titleToDelete)
          .toList();

      if (matched.isEmpty) {
        throw Exception('Sheet not found');
      }

      final sheetId = matched.first.properties?.sheetId;
      if (sheetId == null) {
        throw Exception('Sheet ID not found');
      }

      await api.spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest(
          requests: [
            sheets.Request(
              deleteSheet: sheets.DeleteSheetRequest(sheetId: sheetId),
            ),
          ],
        ),
        spreadsheetId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "$titleToDelete"'),
          backgroundColor: _darkBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      await _loadSheets();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting sheet: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSheets) {
      return Container(
        color: _rowEven,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(_darkBlue),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading sheets...',
                style: TextStyle(
                  fontSize: 16,
                  color: _darkBlue.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_sheetTitles.isEmpty) {
      return Container(
        color: _rowEven,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_open_rounded, size: 48, color: _darkBlue),
              ),
              const SizedBox(height: 20),
              const Text(
                'No sheets found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan a document to create your first sheet',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final title = _selectedTitle ?? _sheetTitles.last;

    return Container(
      color: _rowEven,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryBlue, _accentBlue.withValues(alpha: 0.7)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _darkBlue.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickSheetFromList,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _borderColor, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: _darkBlue.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryBlue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.table_chart_rounded,
                                  color: _darkBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _darkBlue,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _primaryBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _darkBlue,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _iconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Refresh',
                      onPressed: _loadSheets,
                    ),
                    const SizedBox(width: 6),
                    _iconButton(
                      icon: Icons.open_in_browser_rounded,
                      tooltip: 'Open in browser',
                      onPressed: _openInBrowser,
                    ),
                    const SizedBox(width: 6),
                    _iconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete sheet',
                      onPressed: _deleteCurrentSheet,
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _loadingValues
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(_darkBlue),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Loading data...',
                          style: TextStyle(
                            fontSize: 15,
                            color: _darkBlue.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _values.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.table_rows_rounded,
                                size: 40,
                                color: _darkBlue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Sheet is empty',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'No data to display',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildTable(_values),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDestructive
                    ? Colors.red.shade200
                    : _borderColor,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDestructive ? Colors.red.shade400 : _darkBlue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<List<String>> values) {
    final headers = values.first;
    final rows = values.length > 1 ? values.sublist(1) : const <List<String>>[];

    final columnCount = headers.length;

    return RefreshIndicator(
      color: _darkBlue,
      backgroundColor: Colors.white,
      onRefresh: () => _loadValues(_selectedTitle ?? _sheetTitles.last),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _darkBlue.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: _minRowHeight),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_headerBg, _primaryBlue.withValues(alpha: 0.6)],
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(columnCount, (c) {
                            final text = headers[c];
                            return _cell(
                              text.isEmpty ? ' ' : text,
                              isHeader: true,
                              isLast: c == columnCount - 1,
                            );
                          }),
                        ),
                      ),
                    ),

                    ...rows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final r = entry.value;
                      final isEven = idx % 2 == 0;

                      return IntrinsicHeight(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: _minRowHeight),
                          decoration: BoxDecoration(
                            color: isEven ? _rowEven : _rowOdd,
                            border: Border(
                              bottom: BorderSide(color: _borderColor, width: 1),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: List.generate(columnCount, (c) {
                              final text = c < r.length ? r[c] : '';
                              return _cell(text, isLast: c == columnCount - 1);
                            }),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {bool isHeader = false, bool isLast = false}) {
    return Container(
      width: _cellMinWidth,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                right: BorderSide(color: _borderColor, width: 1),
              ),
      ),
      child: Text(
        text,
        softWrap: true,
        style: TextStyle(
          fontSize: isHeader ? _headerFontSize : _cellFontSize,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? _darkBlue : Colors.black87,
          letterSpacing: isHeader ? 0.3 : 0.1,
          height: 1.4,
        ),
      ),
    );
  }
}