import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';
import '../services/db_service.dart';
import '../services/export_service.dart';
import '../services/api_service.dart';
import '../theme_manager.dart';

class SavedDataScreen extends StatefulWidget {
  final ThemeManager themeManager;
  const SavedDataScreen({Key? key, required this.themeManager}) : super(key: key);

  @override
  State<SavedDataScreen> createState() => _SavedDataScreenState();
}

class _SavedDataScreenState extends State<SavedDataScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ScanRecord> _records = [];
  Map<String, bool> _duplicateMap = {};
  Set<DateTime> _datesWithData = {};
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadRecordsForDate(_selectedDay!);
    _loadDatesWithData();
  }

  Future<void> _loadDatesWithData() async {
    final db = await DBService().database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT DISTINCT date FROM scans');
    Set<DateTime> dates = {};
    for (var map in maps) {
      try {
        DateTime dt = DateFormat('yyyy-MM-dd').parse(map['date']);
        dates.add(DateTime(dt.year, dt.month, dt.day));
      } catch (e) {}
    }
    if (mounted) {
      setState(() {
        _datesWithData = dates;
      });
    }
  }

  Future<void> _checkDuplicates(List<ScanRecord> records) async {
    Map<String, bool> dupMap = {};
    for (var r in records) {
      if (!dupMap.containsKey(r.moduleId)) {
        dupMap[r.moduleId] = await DBService().isDuplicate(r.moduleId);
      }
    }
    if (mounted) {
      setState(() {
        _duplicateMap = dupMap;
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (_selectedDay != null) {
      _loadRecordsForDate(_selectedDay!);
    }
    await _loadDatesWithData();
  }

  void _loadRecordsForDate(DateTime date) async {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    // 1. Load from local DB first
    final records = await DBService().getScansByDate(dateStr);
    setState(() {
      _records = records;
      _isSearching = false;
    });
    _checkDuplicates(records);

    // 2. Fetch from backend and cache
    try {
      final backendRecords = await ApiService().fetchScans(date: dateStr);
      if (backendRecords.isNotEmpty) {
        final db = DBService();
        for (var brec in backendRecords) {
          final localScans = await db.searchScansByModuleId(brec.moduleId);
          final match = localScans.where((s) => s.date == brec.date).toList();
          if (match.isNotEmpty) {
            await db.updateScan(match.first.id!, brec);
          } else {
            await db.insertScan(brec);
          }
        }
        
        final updatedRecords = await db.getScansByDate(dateStr);
        if (mounted) {
          setState(() {
            _records = updatedRecords;
          });
          _checkDuplicates(updatedRecords);
        }
      }
    } catch (_) {}
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      _loadRecordsForDate(_selectedDay!);
      return;
    }
    final localRecords = await DBService().searchScansByModuleId(query);
    setState(() {
      _records = localRecords;
      _isSearching = true;
    });
    _checkDuplicates(localRecords);

    // Try fetching from backend for search query
    try {
      final backendRecords = await ApiService().fetchScans(search: query);
      if (backendRecords.isNotEmpty) {
        final db = DBService();
        for (var brec in backendRecords) {
          final localScans = await db.searchScansByModuleId(brec.moduleId);
          final match = localScans.where((s) => s.date == brec.date).toList();
          if (match.isNotEmpty) {
            await db.updateScan(match.first.id!, brec);
          } else {
            await db.insertScan(brec);
          }
        }
        final updatedRecords = await db.searchScansByModuleId(query);
        if (mounted && _searchController.text == query) {
          setState(() {
            _records = updatedRecords;
          });
          _checkDuplicates(updatedRecords);
        }
      }
    } catch (_) {}
  }

  Future<void> _exportData() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      String startDateStr = DateFormat('yyyy-MM-dd').format(picked.start);
      String endDateStr = DateFormat('yyyy-MM-dd').format(picked.end);

      final records = await DBService().getScansByDateRange(startDateStr, endDateStr);
      
      if (!mounted) return;

      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No records found for the selected date range.')),
        );
      } else {
        bool? shouldShare = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Options'),
            content: Text('Found ${records.length} records. How would you like to export?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // false means download
                child: const Text('Save to Downloads'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true), // true means share
                child: const Text('Share / Email'),
              ),
            ],
          ),
        );

        if (shouldShare == null) return; // User cancelled

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generating Excel for ${records.length} records...')),
        );
        try {
          bool savedDirectly = await ExportService.exportToExcel(records, share: shouldShare);
          if (savedDirectly && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ Successfully downloaded to Downloads folder!'), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.redAccent),
            );
          }
        }
      }
    }
  }

  void _deleteRecord(ScanRecord record) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete module ${record.moduleId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      if (record.backendId != null) {
        await ApiService().deleteScan(record.backendId!, themeManager: widget.themeManager);
      }
      await DBService().deleteScan(record.id!);
      _loadRecordsForDate(_selectedDay!);
      _loadDatesWithData();
    }
  }

  void _showRecordDetails(ScanRecord record, bool isDuplicate) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF6C63FF)),
              const SizedBox(width: 10),
              const Expanded(child: Text('Record Details', style: TextStyle(fontWeight: FontWeight.bold))),
              if (isDuplicate)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Text('DUPLICATE', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Module ID:', record.moduleId),
                _buildDetailRow('Job Card:', record.jobCard),
                _buildDetailRow('Station:', record.station),
                _buildDetailRow('Operator:', record.operatorName),
                _buildDetailRow('Date:', record.date),
                const Divider(),
                const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(record.reason, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
              ),
              padding: const EdgeInsets.all(2),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icon.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Saved Records', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: 'Export to Excel',
            onPressed: _exportData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Module ID...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _loadRecordsForDate(_selectedDay!);
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: _performSearch,
              ),
            ),
          ),
          if (!_isSearching)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.week,
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), shape: BoxShape.circle),
                  markerDecoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
                eventLoader: (day) {
                  return _datesWithData.contains(DateTime(day.year, day.month, day.day)) ? ['Data'] : [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _searchController.clear();
                  });
                  _loadRecordsForDate(selectedDay);
                },
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _records.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              const Text('No records found.', style: TextStyle(color: Colors.grey, fontSize: 18)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                      final record = _records[index];
                      final isDuplicate = _duplicateMap[record.moduleId] ?? false;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDuplicate 
                                ? Colors.redAccent.withOpacity(0.3) 
                                : Theme.of(context).colorScheme.primary.withOpacity(0.25), 
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showRecordDetails(record, isDuplicate),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Premium Icon Container (Rounded square)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(Icons.qr_code_2_rounded, color: Theme.of(context).colorScheme.primary, size: 26),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                record.moduleId,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  letterSpacing: 0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${record.date}${record.time != null && record.time!.isNotEmpty ? " • ${record.time}" : ""}',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Premium Delete Button
                                        if (widget.themeManager.userRole == 'admin')
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () => _deleteRecord(record),
                                              borderRadius: BorderRadius.circular(10),
                                              splashColor: Colors.redAccent.withOpacity(0.2),
                                              highlightColor: Colors.redAccent.withOpacity(0.1),
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.redAccent.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                                                ),
                                                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      child: Divider(color: Theme.of(context).dividerColor.withOpacity(0.15), height: 1),
                                    ),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildTag(Icons.credit_card_rounded, record.jobCard, Theme.of(context).colorScheme.secondary),
                                        _buildTag(Icons.storefront_rounded, record.station, Colors.orange),
                                        _buildTag(Icons.person_rounded, record.operatorName, Colors.blue),
                                        if (isDuplicate)
                                          _buildTag(Icons.warning_rounded, 'DUPLICATE', Colors.redAccent),
                                        if (record.reason.isNotEmpty)
                                          _buildTag(Icons.note_alt_rounded, record.reason, Colors.grey),
                                        if (!record.isSynced)
                                          _buildTag(Icons.cloud_off_rounded, 'LOCAL ONLY', Colors.orange),
                                        if (widget.themeManager.userRole == 'admin' && record.savedBy != null && record.savedBy!.isNotEmpty)
                                          _buildTag(Icons.admin_panel_settings_rounded, 'Saved by: ${record.savedBy}', Colors.purple),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
