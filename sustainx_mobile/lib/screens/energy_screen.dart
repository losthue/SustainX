import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EnergyScreen extends StatefulWidget {
  const EnergyScreen({super.key});

  @override
  State<EnergyScreen> createState() => _EnergyScreenState();
}

class _EnergyScreenState extends State<EnergyScreen> {
  final _importController = TextEditingController(text: '0');
  final _exportController = TextEditingController(text: '0');
  bool _isLoading = false;
  String _message = '';
  Map<String, dynamic> _stats = {};
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _loadEnergyData();
  }

  Future<void> _loadEnergyData() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    final hResult = await ApiService.getEnergyHistory();
    final sResult = await ApiService.getEnergyStats();

    if (hResult['success'] && sResult['success']) {
      setState(() {
        _history = List.from(hResult['data'] ?? []);
        _stats = Map<String, dynamic>.from(sResult['data'] ?? {});
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
      _message = hResult['message']?.toString() ?? sResult['message']?.toString() ?? 'Failed to load energy data';
    });
  }

  Future<void> _submitRecord() async {
    final imported = double.tryParse(_importController.text) ?? 0;
    final exported = double.tryParse(_exportController.text) ?? 0;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final result = await ApiService.recordEnergy(imported, exported);

    if (result['success'] == true) {
      _importController.text = '0';
      _exportController.text = '0';
      await _loadEnergyData();
      setState(() {
        _message = 'Energy record saved.';
      });
    } else {
      setState(() {
        _message = result['message']?.toString() ?? 'Failed to save energy record';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _importController.dispose();
    _exportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryText = 'Imported: ${_stats['totalImported'] ?? '-'} kWh\n'
        'Exported: ${_stats['totalExported'] ?? '-'} kWh\n'
        'Conversion Points: ${_stats['totalEnergyPoints'] ?? '-'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Energy Management')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEnergyData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_message, style: const TextStyle(color: Colors.green)),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(summaryText),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Record Energy', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _importController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Imported kWh'),
                    ),
                    TextField(
                      controller: _exportController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Exported kWh'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: _isLoading ? null : _submitRecord, child: const Text('Save Energy')),
                    const SizedBox(height: 18),
                    const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._history.map((entry) {
                      final date = entry['createdAt'] ?? entry['timestamp'] ?? 'Unknown';
                      return Card(
                        child: ListTile(
                          title: Text('Import: ${entry['importedKWh'] ?? 0}, Export: ${entry['exportedKWh'] ?? 0}'),
                          subtitle: Text(date.toString()),
                        ),
                      );
                    }),
                    if (_history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No energy records yet.'),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
