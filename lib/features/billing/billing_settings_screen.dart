import 'package:flutter/material.dart';

import '../../domain/billing/billing_settings.dart';
import '../../domain/menu/menu_models.dart';
import '../../domain/orders/order_models.dart';
import '../../services/storage_service.dart';
import '../menu/menu_widgets.dart';
import '../menu/tax_profiles_screen.dart';

/// Service charge, rounding and bill numbering. Tax rates are set per item
/// through tax profiles.
class BillingSettingsScreen extends StatefulWidget {
  const BillingSettingsScreen({super.key});

  @override
  State<BillingSettingsScreen> createState() => _BillingSettingsScreenState();
}

class _BillingSettingsScreenState extends State<BillingSettingsScreen> {
  BillingSettings? _s;
  final _sc = TextEditingController();
  final _scTax = TextEditingController();
  final _prefix = TextEditingController();
  bool _scOn = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await (await StorageService.getInstance()).bills.getSettings();
    if (!mounted) return;
    setState(() {
      _s = s;
      _scOn = s.serviceChargeBp > 0;
      _sc.text = s.serviceChargeBp > 0 ? _pct(s.serviceChargeBp) : '';
      _scTax.text = s.serviceChargeTaxBp > 0 ? _pct(s.serviceChargeTaxBp) : '';
      _prefix.text = s.billNumberPrefix;
    });
  }

  static String _pct(int bp) => formatBp(bp).replaceAll('%', '');

  @override
  void dispose() {
    _sc.dispose();
    _scTax.dispose();
    _prefix.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = _s!;
    int? sc = 0;
    int? scTax = 0;
    if (_scOn) {
      sc = parsePercentToBp(_sc.text);
      if (sc == null || sc == 0) {
        setState(() => _error = 'Enter the service charge, e.g. 5 or 7.5.');
        return;
      }
      scTax = _scTax.text.trim().isEmpty ? 0 : parsePercentToBp(_scTax.text);
      if (scTax == null) {
        setState(() => _error = 'Enter the service charge tax, e.g. 5.');
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final storage = await StorageService.getInstance();
    if (!mounted) return;
    final ok = await runMenuAction(
      context,
      () => storage.bills.saveSettings(
        s.copyWith(
          serviceChargeBp: sc,
          serviceChargeTaxBp: scTax,
          billNumberPrefix: _prefix.text,
        ),
      ),
      success: 'Billing settings saved. They apply to new bills only.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: const Text('Billing & tax')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Card(
                  color: Color(0xFFFEF3C7),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'The app calculates bills exactly as configured here and '
                      'in each item\'s tax profile. It does not decide which '
                      'taxes or charges apply to your business: confirm your '
                      'GST rates, service charge and invoice rules with your '
                      'accountant. Changes apply only to bills made after you '
                      'save; existing bills never change.',
                      style: TextStyle(color: Color(0xFF92400E)),
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.percent_rounded),
                  title: const Text('Tax rates'),
                  subtitle: const Text(
                    'GST rates, inclusive/exclusive prices and CGST+SGST/IGST '
                    'are set in tax profiles and chosen per menu item.',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TaxProfilesScreen(),
                    ),
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Service charge'),
                  subtitle: const Text(
                    'A percentage of the item value after discount, before '
                    'tax.',
                  ),
                  value: _scOn,
                  onChanged: (v) => setState(() => _scOn = v),
                ),
                if (_scOn) ...[
                  TextField(
                    controller: _sc,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Service charge %',
                      suffixText: '%',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Applies to'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final t in OrderType.values)
                        FilterChip(
                          label: Text(t.label),
                          selected: s.serviceChargeOrderTypes.contains(t),
                          onSelected: (on) => setState(
                            () => _s = s.copyWith(
                              serviceChargeOrderTypes: on
                                  ? {...s.serviceChargeOrderTypes, t}
                                  : ({...s.serviceChargeOrderTypes}..remove(t)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _scTax,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tax on service charge % (blank = none)',
                      suffixText: '%',
                    ),
                  ),
                  DropdownButtonFormField<TaxSplitMode>(
                    initialValue: s.serviceChargeTaxSplit,
                    decoration: const InputDecoration(
                      labelText: 'Service charge tax shown as',
                    ),
                    items: [
                      for (final m in TaxSplitMode.values)
                        DropdownMenuItem(value: m, child: Text(m.label)),
                    ],
                    onChanged: (m) => setState(
                      () => _s = s.copyWith(serviceChargeTaxSplit: m),
                    ),
                  ),
                ],
                const Divider(height: 32),
                const Text(
                  'Rounding of the bill total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'The difference is printed on the bill as "Round off".',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                RadioGroup<RoundingMode>(
                  groupValue: s.rounding,
                  onChanged: (m) =>
                      setState(() => _s = s.copyWith(rounding: m)),
                  child: Column(
                    children: [
                      for (final m in RoundingMode.values)
                        RadioListTile<RoundingMode>(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: m,
                          title: Text(m.label),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 32),
                TextField(
                  controller: _prefix,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'Bill number prefix (optional)',
                    helperText:
                        'e.g. FY26/ gives FY26/1, FY26/2 … Each prefix has '
                        'its own sequence starting at 1. Numbers are never '
                        'reused, including voided bills.',
                    helperMaxLines: 3,
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
    );
  }
}
