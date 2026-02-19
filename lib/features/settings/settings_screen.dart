import 'package:flutter/material.dart';
import 'donate_service.dart';

/// Settings screen with donate button
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DonateService _donateService = DonateService();
  bool _isLoading = false;
  String _price = '\$0.99';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _donateService.init();
    _donateService.onPurchaseComplete = (success) {
      setState(() => _isLoading = false);
      if (success) {
        _showThankYou();
      }
    };
    
    final price = await _donateService.getPrice();
    if (mounted) {
      setState(() => _price = price);
    }
  }

  @override
  void dispose() {
    _donateService.dispose();
    super.dispose();
  }

  void _showThankYou() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite, size: 40, color: Colors.green.shade600),
            ),
            const SizedBox(height: 24),
            const Text(
              'Thank You! ❤️',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Your support means a lot!\nIt helps keep PDFx free for everyone.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 24),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('You\'re welcome!', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _donate() async {
    setState(() => _isLoading = true);
    await _donateService.buyCoffee();
    // Result handled in onPurchaseComplete callback
  }
  Widget _buildTipButton(String price) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _donate(),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A5F),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        price,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Donate Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, size: 32, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enjoying PDFx?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Support the developer',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTipButton('\$0.99'),
                      _buildTipButton('\$2.99'),
                      _buildTipButton('\$4.99'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App Info
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  trailing: Text('1.0.0', style: TextStyle(color: Colors.grey.shade600)),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Open privacy policy URL
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}