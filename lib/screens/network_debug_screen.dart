import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/network_helper.dart';
import '../utils/constants.dart';
import 'dart:developer' as developer;

class NetworkDebugScreen extends StatefulWidget {
  const NetworkDebugScreen({super.key});

  @override
  State<NetworkDebugScreen> createState() => _NetworkDebugScreenState();
}

class _NetworkDebugScreenState extends State<NetworkDebugScreen> {
  Map<String, dynamic> _diagnostics = {};
  bool _isLoading = false;
  String? _currentBaseUrl;
  String? _deviceIp;

  @override
  void initState() {
    super.initState();
    _loadNetworkInfo();
  }

  Future<void> _loadNetworkInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diagnostics = await NetworkHelper.getNetworkDiagnostics();
      final deviceIp = await NetworkHelper.getLocalIpAddress();
      
      setState(() {
        _diagnostics = diagnostics;
        _currentBaseUrl = Constants.baseUrl;
        _deviceIp = deviceIp;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading network info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnectivity() async {
    setState(() {
      _isLoading = true;
    });

    await NetworkHelper.printNetworkDiagnostics();

    // Test the fixed base URL
    final isReachable = await NetworkHelper.testConnection('${Constants.baseUrl}health/');
    if (isReachable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Backend URL is reachable'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Backend URL is not reachable'),
          backgroundColor: Colors.red,
        ),
      );
    }

    await _loadNetworkInfo();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _testConnectivity,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildCurrentConfigCard(),
                  const SizedBox(height: 16),
                  _buildConnectivityTestCard(),
                  const SizedBox(height: 16),
                  _buildTroubleshootingCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Device IP', _deviceIp ?? 'Unknown'),
            _buildInfoRow('Current Base URL', _currentBaseUrl ?? 'Not set'),
            _buildInfoRow('Platform', Theme.of(context).platform.name),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildUrlRow('Base URL', Constants.baseUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connectivity Tests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_diagnostics.isEmpty)
              const Text('Run connectivity test to see results')
            else
              ..._diagnostics.entries
                  .where((entry) => entry.key != 'deviceIp')
                  .map((entry) => _buildTestResultRow(entry.key, entry.value))
                  .toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testConnectivity,
                child: const Text('Run Connectivity Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Troubleshooting Tips',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('1. Ensure Django server is running with: python manage.py runserver 0.0.0.0:8000'),
            const SizedBox(height: 4),
            const Text('2. Check that both devices are on the same WiFi network'),
            const SizedBox(height: 4),
            const Text('3. Verify firewall settings allow port 8000'),
            const SizedBox(height: 4),
            const Text('4. For emulator, use 10.0.2.2 instead of localhost'),
            const SizedBox(height: 4),
            const Text('5. For physical device, use your machine\'s WiFi IP'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyToClipboard(value),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(url),
              child: Text(
                url,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyToClipboard(url),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultRow(String url, bool isReachable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isReachable ? Icons.check_circle : Icons.error,
            color: isReachable ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          Text(
            isReachable ? 'REACHABLE' : 'UNREACHABLE',
            style: TextStyle(
              color: isReachable ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}







