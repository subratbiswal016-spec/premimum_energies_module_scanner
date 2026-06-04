import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';

class ExportService {
  static Future<bool> exportToExcel(List<ScanRecord> records, {bool share = false}) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Scans'];
    excel.setDefaultSheet('Scans');

    if (excel.sheets.keys.contains('Sheet1')) {
      excel.delete('Sheet1');
    }

    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('Date'),
      TextCellValue('Module ID'),
      TextCellValue('Job Card'),
      TextCellValue('Station'),
      TextCellValue('Operator'),
      TextCellValue('Reason'),
    ]);

    for (var record in records) {
      sheetObject.appendRow([
        TextCellValue(record.id.toString()),
        TextCellValue(record.date),
        TextCellValue(record.moduleId),
        TextCellValue(record.jobCard),
        TextCellValue(record.station),
        TextCellValue(record.operatorName),
        TextCellValue(record.reason),
      ]);
    }

    var fileBytes = excel.save();
    if (fileBytes != null) {
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = 'PremierScans_$timestamp.xlsx';
      
      File file;

      if (!share && Platform.isAndroid) {
        try {
          file = File('/storage/emulated/0/Download/$fileName');
          await file.writeAsBytes(fileBytes);
          return true; // Successfully saved to Downloads
        } catch (e) {
          // Fallback
        }
      }

      final directory = await getTemporaryDirectory();
      file = File('${directory.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Exported Scans from Premier Module Scanner',
      );
      return false; // Used Share menu
    }
    return false;
  }
}
