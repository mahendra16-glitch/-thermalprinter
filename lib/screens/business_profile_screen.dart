import 'package:flutter/material.dart';

import '../data/repositories/business_profile_repository.dart';
import '../services/storage_service.dart';

/// Edits the restaurant details stored in the local database.
class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _gstin = TextEditingController();
  final _fssai = TextEditingController();
  final _upiId = TextEditingController();
  final _footer = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  static final RegExp _gstinPattern = RegExp(
    r'^[0-9]{2}[A-Z0-9]{10}[0-9A-Z]{3}$',
  );
  static final RegExp _upiPattern = RegExp(r'^[\w.\-]{2,}@[A-Za-z][\w]{1,}$');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _address,
      _phone,
      _gstin,
      _fssai,
      _upiId,
      _footer,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final storage = await StorageService.getInstance();
      final p = await storage.businessProfile.get();
      _name.text = p.name;
      _address.text = p.address;
      _phone.text = p.phone;
      _gstin.text = p.gstin;
      _fssai.text = p.fssai;
      _upiId.text = p.upiId;
      _footer.text = p.billFooter;
    } catch (e) {
      _loadError = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final storage = await StorageService.getInstance();
      await storage.businessProfile.save(
        BusinessProfile(
          name: _name.text,
          address: _address.text,
          phone: _phone.text,
          gstin: _gstin.text,
          fssai: _fssai.text,
          upiId: _upiId.text,
          billFooter: _footer.text,
        ),
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Business profile saved')),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.sentences,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        textCapitalization: caps,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load the business profile:\n$_loadError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'These details are saved on this device. Bill and KOT '
                    'layouts will use them once billing is built (the current '
                    'test prints do not read them yet).',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  _field(
                    _name,
                    'Restaurant name *',
                    caps: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Restaurant name is required'
                        : null,
                  ),
                  _field(_address, 'Address', maxLines: 3),
                  _field(
                    _phone,
                    'Phone',
                    keyboard: TextInputType.phone,
                    validator: (v) {
                      final s = (v ?? '').replaceAll(RegExp(r'[\s\-+()]'), '');
                      if (s.isEmpty) return null;
                      return RegExp(r'^\d{6,15}$').hasMatch(s)
                          ? null
                          : 'Enter digits only (6 to 15)';
                    },
                  ),
                  _field(
                    _gstin,
                    'GSTIN (optional)',
                    hint: '15 characters, e.g. 24ABCDE1234F1Z5',
                    caps: TextCapitalization.characters,
                    validator: (v) {
                      final s = (v ?? '').trim().toUpperCase();
                      if (s.isEmpty) return null;
                      return _gstinPattern.hasMatch(s)
                          ? null
                          : 'GSTIN must be 15 letters/digits';
                    },
                  ),
                  _field(
                    _fssai,
                    'FSSAI licence no. (optional)',
                    keyboard: TextInputType.number,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      return RegExp(r'^\d{14}$').hasMatch(s)
                          ? null
                          : 'FSSAI number has 14 digits';
                    },
                  ),
                  _field(
                    _upiId,
                    'UPI ID (optional)',
                    hint: 'name@bank',
                    caps: TextCapitalization.none,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null;
                      return _upiPattern.hasMatch(s)
                          ? null
                          : 'UPI ID looks like name@bank';
                    },
                  ),
                  _field(
                    _footer,
                    'Bill footer message (optional)',
                    hint: 'e.g. Thank you, visit again',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
