import 'package:drift/drift.dart';

import '../../core/util/clock.dart';
import '../db/app_database.dart';
import 'audit_repository.dart';

/// Restaurant identity printed on bills (name, address, GSTIN, …).
class BusinessProfile {
  final String name;
  final String address;
  final String phone;
  final String gstin;
  final String fssai;
  final String upiId;
  final String billFooter;

  const BusinessProfile({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.gstin = '',
    this.fssai = '',
    this.upiId = '',
    this.billFooter = '',
  });

  bool get isConfigured => name.trim().isNotEmpty;

  Map<String, Object?> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
    'gstin': gstin,
    'fssai': fssai,
    'upiId': upiId,
    'billFooter': billFooter,
  };
}

class BusinessProfileRepository {
  final AppDatabase _db;
  final AuditRepository _audit;

  BusinessProfileRepository(this._db, this._audit);

  static const int _rowId = 1;

  Future<BusinessProfile> get() async {
    final row = await (_db.select(
      _db.businessProfiles,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();
    if (row == null) return const BusinessProfile();
    return BusinessProfile(
      name: row.name,
      address: row.address,
      phone: row.phone,
      gstin: row.gstin,
      fssai: row.fssai,
      upiId: row.upiId,
      billFooter: row.billFooter,
    );
  }

  Future<void> save(BusinessProfile profile) {
    return _db.transaction(() async {
      final before = await get();
      await _db
          .into(_db.businessProfiles)
          .insertOnConflictUpdate(
            BusinessProfilesCompanion.insert(
              id: const Value(_rowId),
              name: Value(profile.name.trim()),
              address: Value(profile.address.trim()),
              phone: Value(profile.phone.trim()),
              gstin: Value(profile.gstin.trim().toUpperCase()),
              fssai: Value(profile.fssai.trim()),
              upiId: Value(profile.upiId.trim()),
              billFooter: Value(profile.billFooter.trim()),
              updatedAt: Clock.nowMs(),
            ),
          );
      await _audit.record(
        action: 'business_profile.updated',
        entity: 'business_profiles',
        entityId: '$_rowId',
        details: {'from': before.toJson(), 'to': profile.toJson()},
      );
    });
  }
}
