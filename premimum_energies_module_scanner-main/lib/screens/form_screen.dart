import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';
import '../services/api_service.dart';

class FormScreen extends StatefulWidget {
  final String scannedData;
  final String? initialJobCard;
  const FormScreen({Key? key, required this.scannedData, this.initialJobCard}) : super(key: key);

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _dateController;
  late TextEditingController _moduleIdController;
  late TextEditingController _jobCardController;
  final TextEditingController _stationController = TextEditingController();
  final TextEditingController _operatorController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    String dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _dateController = TextEditingController(text: dateStr);
    
    String moduleId = widget.scannedData;
    String jobCard = widget.initialJobCard ?? ''; 
    
    if (jobCard.isEmpty) {
      List<String> parts = widget.scannedData.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        moduleId = parts.firstWhere((p) => p.startsWith('NSM') || p.length > 10, orElse: () => parts[0]);
        jobCard = parts.firstWhere((p) => p.startsWith('L') || p.length < 10, orElse: () => parts.length > 1 ? parts[1] : '');
      }
    }

    _moduleIdController = TextEditingController(text: moduleId);
    _jobCardController = TextEditingController(text: jobCard);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _moduleIdController.dispose();
    _jobCardController.dispose();
    _stationController.dispose();
    _operatorController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      final record = ScanRecord(
        date: _dateController.text,
        moduleId: _moduleIdController.text,
        jobCard: _jobCardController.text,
        station: _stationController.text,
        operatorName: _operatorController.text,
        reason: _reasonController.text,
      );
      
      final result = await ApiService.createScan(record);
      
      if (!mounted) return;
      
      if (result['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Record Saved Successfully', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['data'] != null && result['data']['message'] != null
                        ? result['data']['message']
                        : 'Failed to save record',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool readOnly = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          filled: true,
          fillColor: Theme.of(context).cardTheme.color,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => value!.isEmpty ? 'This field is required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Icon(Icons.fact_check_outlined, size: 40, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  const Text(
                    'Verify Scanned Data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Review and complete the fields below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField('DATE', Icons.calendar_today_rounded, _dateController, readOnly: true),
                    _buildTextField('MODULE ID', Icons.qr_code_rounded, _moduleIdController),
                    _buildTextField('JOB CARD', Icons.credit_card_rounded, _jobCardController),
                    _buildTextField('STATION', Icons.storefront_rounded, _stationController),
                    _buildTextField('OPERATOR', Icons.person_rounded, _operatorController),
                    _buildTextField('REASON', Icons.note_alt_rounded, _reasonController),
                    
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _saveData,
                          child: const Center(
                            child: Text(
                              'SAVE RECORD',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
