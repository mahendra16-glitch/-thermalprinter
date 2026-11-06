// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MigrationLogTable extends MigrationLog
    with TableInfo<$MigrationLogTable, MigrationLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MigrationLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<int> appliedAt = GeneratedColumn<int>(
    'applied_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [version, appliedAt, notes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {version};
  @override
  MigrationLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationLogRow(
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}applied_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
    );
  }

  @override
  $MigrationLogTable createAlias(String alias) {
    return $MigrationLogTable(attachedDatabase, alias);
  }
}

class MigrationLogRow extends DataClass implements Insertable<MigrationLogRow> {
  final int version;
  final int appliedAt;
  final String notes;
  const MigrationLogRow({
    required this.version,
    required this.appliedAt,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['version'] = Variable<int>(version);
    map['applied_at'] = Variable<int>(appliedAt);
    map['notes'] = Variable<String>(notes);
    return map;
  }

  MigrationLogCompanion toCompanion(bool nullToAbsent) {
    return MigrationLogCompanion(
      version: Value(version),
      appliedAt: Value(appliedAt),
      notes: Value(notes),
    );
  }

  factory MigrationLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationLogRow(
      version: serializer.fromJson<int>(json['version']),
      appliedAt: serializer.fromJson<int>(json['appliedAt']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'version': serializer.toJson<int>(version),
      'appliedAt': serializer.toJson<int>(appliedAt),
      'notes': serializer.toJson<String>(notes),
    };
  }

  MigrationLogRow copyWith({int? version, int? appliedAt, String? notes}) =>
      MigrationLogRow(
        version: version ?? this.version,
        appliedAt: appliedAt ?? this.appliedAt,
        notes: notes ?? this.notes,
      );
  MigrationLogRow copyWithCompanion(MigrationLogCompanion data) {
    return MigrationLogRow(
      version: data.version.present ? data.version.value : this.version,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationLogRow(')
          ..write('version: $version, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(version, appliedAt, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationLogRow &&
          other.version == this.version &&
          other.appliedAt == this.appliedAt &&
          other.notes == this.notes);
}

class MigrationLogCompanion extends UpdateCompanion<MigrationLogRow> {
  final Value<int> version;
  final Value<int> appliedAt;
  final Value<String> notes;
  const MigrationLogCompanion({
    this.version = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.notes = const Value.absent(),
  });
  MigrationLogCompanion.insert({
    this.version = const Value.absent(),
    required int appliedAt,
    this.notes = const Value.absent(),
  }) : appliedAt = Value(appliedAt);
  static Insertable<MigrationLogRow> custom({
    Expression<int>? version,
    Expression<int>? appliedAt,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (version != null) 'version': version,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (notes != null) 'notes': notes,
    });
  }

  MigrationLogCompanion copyWith({
    Value<int>? version,
    Value<int>? appliedAt,
    Value<String>? notes,
  }) {
    return MigrationLogCompanion(
      version: version ?? this.version,
      appliedAt: appliedAt ?? this.appliedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<int>(appliedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationLogCompanion(')
          ..write('version: $version, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  final int updatedAt;
  const AppSettingRow({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AppSettingRow copyWith({String? key, String? value, int? updatedAt}) =>
      AppSettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BusinessProfilesTable extends BusinessProfiles
    with TableInfo<$BusinessProfilesTable, BusinessProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _gstinMeta = const VerificationMeta('gstin');
  @override
  late final GeneratedColumn<String> gstin = GeneratedColumn<String>(
    'gstin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fssaiMeta = const VerificationMeta('fssai');
  @override
  late final GeneratedColumn<String> fssai = GeneratedColumn<String>(
    'fssai',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _upiIdMeta = const VerificationMeta('upiId');
  @override
  late final GeneratedColumn<String> upiId = GeneratedColumn<String>(
    'upi_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _billFooterMeta = const VerificationMeta(
    'billFooter',
  );
  @override
  late final GeneratedColumn<String> billFooter = GeneratedColumn<String>(
    'bill_footer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    phone,
    gstin,
    fssai,
    upiId,
    billFooter,
    currencyCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'business_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<BusinessProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('gstin')) {
      context.handle(
        _gstinMeta,
        gstin.isAcceptableOrUnknown(data['gstin']!, _gstinMeta),
      );
    }
    if (data.containsKey('fssai')) {
      context.handle(
        _fssaiMeta,
        fssai.isAcceptableOrUnknown(data['fssai']!, _fssaiMeta),
      );
    }
    if (data.containsKey('upi_id')) {
      context.handle(
        _upiIdMeta,
        upiId.isAcceptableOrUnknown(data['upi_id']!, _upiIdMeta),
      );
    }
    if (data.containsKey('bill_footer')) {
      context.handle(
        _billFooterMeta,
        billFooter.isAcceptableOrUnknown(data['bill_footer']!, _billFooterMeta),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BusinessProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BusinessProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      gstin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gstin'],
      )!,
      fssai: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fssai'],
      )!,
      upiId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upi_id'],
      )!,
      billFooter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_footer'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BusinessProfilesTable createAlias(String alias) {
    return $BusinessProfilesTable(attachedDatabase, alias);
  }
}

class BusinessProfileRow extends DataClass
    implements Insertable<BusinessProfileRow> {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String gstin;
  final String fssai;
  final String upiId;
  final String billFooter;
  final String currencyCode;
  final int updatedAt;
  const BusinessProfileRow({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.gstin,
    required this.fssai,
    required this.upiId,
    required this.billFooter,
    required this.currencyCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['phone'] = Variable<String>(phone);
    map['gstin'] = Variable<String>(gstin);
    map['fssai'] = Variable<String>(fssai);
    map['upi_id'] = Variable<String>(upiId);
    map['bill_footer'] = Variable<String>(billFooter);
    map['currency_code'] = Variable<String>(currencyCode);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BusinessProfilesCompanion toCompanion(bool nullToAbsent) {
    return BusinessProfilesCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      phone: Value(phone),
      gstin: Value(gstin),
      fssai: Value(fssai),
      upiId: Value(upiId),
      billFooter: Value(billFooter),
      currencyCode: Value(currencyCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory BusinessProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BusinessProfileRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      phone: serializer.fromJson<String>(json['phone']),
      gstin: serializer.fromJson<String>(json['gstin']),
      fssai: serializer.fromJson<String>(json['fssai']),
      upiId: serializer.fromJson<String>(json['upiId']),
      billFooter: serializer.fromJson<String>(json['billFooter']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'phone': serializer.toJson<String>(phone),
      'gstin': serializer.toJson<String>(gstin),
      'fssai': serializer.toJson<String>(fssai),
      'upiId': serializer.toJson<String>(upiId),
      'billFooter': serializer.toJson<String>(billFooter),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  BusinessProfileRow copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    String? gstin,
    String? fssai,
    String? upiId,
    String? billFooter,
    String? currencyCode,
    int? updatedAt,
  }) => BusinessProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    gstin: gstin ?? this.gstin,
    fssai: fssai ?? this.fssai,
    upiId: upiId ?? this.upiId,
    billFooter: billFooter ?? this.billFooter,
    currencyCode: currencyCode ?? this.currencyCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BusinessProfileRow copyWithCompanion(BusinessProfilesCompanion data) {
    return BusinessProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      gstin: data.gstin.present ? data.gstin.value : this.gstin,
      fssai: data.fssai.present ? data.fssai.value : this.fssai,
      upiId: data.upiId.present ? data.upiId.value : this.upiId,
      billFooter: data.billFooter.present
          ? data.billFooter.value
          : this.billFooter,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BusinessProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('gstin: $gstin, ')
          ..write('fssai: $fssai, ')
          ..write('upiId: $upiId, ')
          ..write('billFooter: $billFooter, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    phone,
    gstin,
    fssai,
    upiId,
    billFooter,
    currencyCode,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BusinessProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.gstin == this.gstin &&
          other.fssai == this.fssai &&
          other.upiId == this.upiId &&
          other.billFooter == this.billFooter &&
          other.currencyCode == this.currencyCode &&
          other.updatedAt == this.updatedAt);
}

class BusinessProfilesCompanion extends UpdateCompanion<BusinessProfileRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> address;
  final Value<String> phone;
  final Value<String> gstin;
  final Value<String> fssai;
  final Value<String> upiId;
  final Value<String> billFooter;
  final Value<String> currencyCode;
  final Value<int> updatedAt;
  const BusinessProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.gstin = const Value.absent(),
    this.fssai = const Value.absent(),
    this.upiId = const Value.absent(),
    this.billFooter = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BusinessProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.gstin = const Value.absent(),
    this.fssai = const Value.absent(),
    this.upiId = const Value.absent(),
    this.billFooter = const Value.absent(),
    this.currencyCode = const Value.absent(),
    required int updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<BusinessProfileRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? gstin,
    Expression<String>? fssai,
    Expression<String>? upiId,
    Expression<String>? billFooter,
    Expression<String>? currencyCode,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (gstin != null) 'gstin': gstin,
      if (fssai != null) 'fssai': fssai,
      if (upiId != null) 'upi_id': upiId,
      if (billFooter != null) 'bill_footer': billFooter,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BusinessProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? address,
    Value<String>? phone,
    Value<String>? gstin,
    Value<String>? fssai,
    Value<String>? upiId,
    Value<String>? billFooter,
    Value<String>? currencyCode,
    Value<int>? updatedAt,
  }) {
    return BusinessProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      fssai: fssai ?? this.fssai,
      upiId: upiId ?? this.upiId,
      billFooter: billFooter ?? this.billFooter,
      currencyCode: currencyCode ?? this.currencyCode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (gstin.present) {
      map['gstin'] = Variable<String>(gstin.value);
    }
    if (fssai.present) {
      map['fssai'] = Variable<String>(fssai.value);
    }
    if (upiId.present) {
      map['upi_id'] = Variable<String>(upiId.value);
    }
    if (billFooter.present) {
      map['bill_footer'] = Variable<String>(billFooter.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('gstin: $gstin, ')
          ..write('fssai: $fssai, ')
          ..write('upiId: $upiId, ')
          ..write('billFooter: $billFooter, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PrinterProfilesTable extends PrinterProfiles
    with TableInfo<$PrinterProfilesTable, PrinterProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrinterProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionTypeMeta = const VerificationMeta(
    'connectionType',
  );
  @override
  late final GeneratedColumn<String> connectionType = GeneratedColumn<String>(
    'connection_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paperWidthMeta = const VerificationMeta(
    'paperWidth',
  );
  @override
  late final GeneratedColumn<String> paperWidth = GeneratedColumn<String>(
    'paper_width',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _macAddressMeta = const VerificationMeta(
    'macAddress',
  );
  @override
  late final GeneratedColumn<String> macAddress = GeneratedColumn<String>(
    'mac_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _vendorIdMeta = const VerificationMeta(
    'vendorId',
  );
  @override
  late final GeneratedColumn<int> vendorId = GeneratedColumn<int>(
    'vendor_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<int> productId = GeneratedColumn<int>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ipAddressMeta = const VerificationMeta(
    'ipAddress',
  );
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
    'ip_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(9100),
  );
  static const VerificationMeta _lastConnectedAtMeta = const VerificationMeta(
    'lastConnectedAt',
  );
  @override
  late final GeneratedColumn<int> lastConnectedAt = GeneratedColumn<int>(
    'last_connected_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    connectionType,
    paperWidth,
    role,
    macAddress,
    vendorId,
    productId,
    deviceName,
    ipAddress,
    port,
    lastConnectedAt,
    lastError,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'printer_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrinterProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('connection_type')) {
      context.handle(
        _connectionTypeMeta,
        connectionType.isAcceptableOrUnknown(
          data['connection_type']!,
          _connectionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionTypeMeta);
    }
    if (data.containsKey('paper_width')) {
      context.handle(
        _paperWidthMeta,
        paperWidth.isAcceptableOrUnknown(data['paper_width']!, _paperWidthMeta),
      );
    } else if (isInserting) {
      context.missing(_paperWidthMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('mac_address')) {
      context.handle(
        _macAddressMeta,
        macAddress.isAcceptableOrUnknown(data['mac_address']!, _macAddressMeta),
      );
    }
    if (data.containsKey('vendor_id')) {
      context.handle(
        _vendorIdMeta,
        vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    }
    if (data.containsKey('ip_address')) {
      context.handle(
        _ipAddressMeta,
        ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta),
      );
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('last_connected_at')) {
      context.handle(
        _lastConnectedAtMeta,
        lastConnectedAt.isAcceptableOrUnknown(
          data['last_connected_at']!,
          _lastConnectedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrinterProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrinterProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      connectionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_type'],
      )!,
      paperWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_width'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      macAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mac_address'],
      ),
      vendorId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vendor_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}product_id'],
      ),
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      ),
      ipAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ip_address'],
      ),
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      lastConnectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_connected_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PrinterProfilesTable createAlias(String alias) {
    return $PrinterProfilesTable(attachedDatabase, alias);
  }
}

class PrinterProfileRow extends DataClass
    implements Insertable<PrinterProfileRow> {
  final String id;
  final String name;

  /// `ConnectionType.name` (bluetooth | usb | network).
  final String connectionType;

  /// `PaperWidth.name` (mm58 | mm80).
  final String paperWidth;

  /// `PrinterRole.name`.
  final String role;
  final String? macAddress;
  final int? vendorId;
  final int? productId;
  final String? deviceName;
  final String? ipAddress;
  final int port;
  final int? lastConnectedAt;
  final String? lastError;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const PrinterProfileRow({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.paperWidth,
    required this.role,
    this.macAddress,
    this.vendorId,
    this.productId,
    this.deviceName,
    this.ipAddress,
    required this.port,
    this.lastConnectedAt,
    this.lastError,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['connection_type'] = Variable<String>(connectionType);
    map['paper_width'] = Variable<String>(paperWidth);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || macAddress != null) {
      map['mac_address'] = Variable<String>(macAddress);
    }
    if (!nullToAbsent || vendorId != null) {
      map['vendor_id'] = Variable<int>(vendorId);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<int>(productId);
    }
    if (!nullToAbsent || deviceName != null) {
      map['device_name'] = Variable<String>(deviceName);
    }
    if (!nullToAbsent || ipAddress != null) {
      map['ip_address'] = Variable<String>(ipAddress);
    }
    map['port'] = Variable<int>(port);
    if (!nullToAbsent || lastConnectedAt != null) {
      map['last_connected_at'] = Variable<int>(lastConnectedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PrinterProfilesCompanion toCompanion(bool nullToAbsent) {
    return PrinterProfilesCompanion(
      id: Value(id),
      name: Value(name),
      connectionType: Value(connectionType),
      paperWidth: Value(paperWidth),
      role: Value(role),
      macAddress: macAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(macAddress),
      vendorId: vendorId == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      deviceName: deviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceName),
      ipAddress: ipAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(ipAddress),
      port: Value(port),
      lastConnectedAt: lastConnectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConnectedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PrinterProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrinterProfileRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      connectionType: serializer.fromJson<String>(json['connectionType']),
      paperWidth: serializer.fromJson<String>(json['paperWidth']),
      role: serializer.fromJson<String>(json['role']),
      macAddress: serializer.fromJson<String?>(json['macAddress']),
      vendorId: serializer.fromJson<int?>(json['vendorId']),
      productId: serializer.fromJson<int?>(json['productId']),
      deviceName: serializer.fromJson<String?>(json['deviceName']),
      ipAddress: serializer.fromJson<String?>(json['ipAddress']),
      port: serializer.fromJson<int>(json['port']),
      lastConnectedAt: serializer.fromJson<int?>(json['lastConnectedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'connectionType': serializer.toJson<String>(connectionType),
      'paperWidth': serializer.toJson<String>(paperWidth),
      'role': serializer.toJson<String>(role),
      'macAddress': serializer.toJson<String?>(macAddress),
      'vendorId': serializer.toJson<int?>(vendorId),
      'productId': serializer.toJson<int?>(productId),
      'deviceName': serializer.toJson<String?>(deviceName),
      'ipAddress': serializer.toJson<String?>(ipAddress),
      'port': serializer.toJson<int>(port),
      'lastConnectedAt': serializer.toJson<int?>(lastConnectedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  PrinterProfileRow copyWith({
    String? id,
    String? name,
    String? connectionType,
    String? paperWidth,
    String? role,
    Value<String?> macAddress = const Value.absent(),
    Value<int?> vendorId = const Value.absent(),
    Value<int?> productId = const Value.absent(),
    Value<String?> deviceName = const Value.absent(),
    Value<String?> ipAddress = const Value.absent(),
    int? port,
    Value<int?> lastConnectedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => PrinterProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    connectionType: connectionType ?? this.connectionType,
    paperWidth: paperWidth ?? this.paperWidth,
    role: role ?? this.role,
    macAddress: macAddress.present ? macAddress.value : this.macAddress,
    vendorId: vendorId.present ? vendorId.value : this.vendorId,
    productId: productId.present ? productId.value : this.productId,
    deviceName: deviceName.present ? deviceName.value : this.deviceName,
    ipAddress: ipAddress.present ? ipAddress.value : this.ipAddress,
    port: port ?? this.port,
    lastConnectedAt: lastConnectedAt.present
        ? lastConnectedAt.value
        : this.lastConnectedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PrinterProfileRow copyWithCompanion(PrinterProfilesCompanion data) {
    return PrinterProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      connectionType: data.connectionType.present
          ? data.connectionType.value
          : this.connectionType,
      paperWidth: data.paperWidth.present
          ? data.paperWidth.value
          : this.paperWidth,
      role: data.role.present ? data.role.value : this.role,
      macAddress: data.macAddress.present
          ? data.macAddress.value
          : this.macAddress,
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      productId: data.productId.present ? data.productId.value : this.productId,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      port: data.port.present ? data.port.value : this.port,
      lastConnectedAt: data.lastConnectedAt.present
          ? data.lastConnectedAt.value
          : this.lastConnectedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrinterProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('connectionType: $connectionType, ')
          ..write('paperWidth: $paperWidth, ')
          ..write('role: $role, ')
          ..write('macAddress: $macAddress, ')
          ..write('vendorId: $vendorId, ')
          ..write('productId: $productId, ')
          ..write('deviceName: $deviceName, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('port: $port, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('lastError: $lastError, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    connectionType,
    paperWidth,
    role,
    macAddress,
    vendorId,
    productId,
    deviceName,
    ipAddress,
    port,
    lastConnectedAt,
    lastError,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrinterProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.connectionType == this.connectionType &&
          other.paperWidth == this.paperWidth &&
          other.role == this.role &&
          other.macAddress == this.macAddress &&
          other.vendorId == this.vendorId &&
          other.productId == this.productId &&
          other.deviceName == this.deviceName &&
          other.ipAddress == this.ipAddress &&
          other.port == this.port &&
          other.lastConnectedAt == this.lastConnectedAt &&
          other.lastError == this.lastError &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PrinterProfilesCompanion extends UpdateCompanion<PrinterProfileRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> connectionType;
  final Value<String> paperWidth;
  final Value<String> role;
  final Value<String?> macAddress;
  final Value<int?> vendorId;
  final Value<int?> productId;
  final Value<String?> deviceName;
  final Value<String?> ipAddress;
  final Value<int> port;
  final Value<int?> lastConnectedAt;
  final Value<String?> lastError;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const PrinterProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.connectionType = const Value.absent(),
    this.paperWidth = const Value.absent(),
    this.role = const Value.absent(),
    this.macAddress = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.productId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.port = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrinterProfilesCompanion.insert({
    required String id,
    required String name,
    required String connectionType,
    required String paperWidth,
    required String role,
    this.macAddress = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.productId = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.port = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       connectionType = Value(connectionType),
       paperWidth = Value(paperWidth),
       role = Value(role),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PrinterProfileRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? connectionType,
    Expression<String>? paperWidth,
    Expression<String>? role,
    Expression<String>? macAddress,
    Expression<int>? vendorId,
    Expression<int>? productId,
    Expression<String>? deviceName,
    Expression<String>? ipAddress,
    Expression<int>? port,
    Expression<int>? lastConnectedAt,
    Expression<String>? lastError,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (connectionType != null) 'connection_type': connectionType,
      if (paperWidth != null) 'paper_width': paperWidth,
      if (role != null) 'role': role,
      if (macAddress != null) 'mac_address': macAddress,
      if (vendorId != null) 'vendor_id': vendorId,
      if (productId != null) 'product_id': productId,
      if (deviceName != null) 'device_name': deviceName,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (port != null) 'port': port,
      if (lastConnectedAt != null) 'last_connected_at': lastConnectedAt,
      if (lastError != null) 'last_error': lastError,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrinterProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? connectionType,
    Value<String>? paperWidth,
    Value<String>? role,
    Value<String?>? macAddress,
    Value<int?>? vendorId,
    Value<int?>? productId,
    Value<String?>? deviceName,
    Value<String?>? ipAddress,
    Value<int>? port,
    Value<int?>? lastConnectedAt,
    Value<String?>? lastError,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return PrinterProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      paperWidth: paperWidth ?? this.paperWidth,
      role: role ?? this.role,
      macAddress: macAddress ?? this.macAddress,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
      deviceName: deviceName ?? this.deviceName,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastError: lastError ?? this.lastError,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (connectionType.present) {
      map['connection_type'] = Variable<String>(connectionType.value);
    }
    if (paperWidth.present) {
      map['paper_width'] = Variable<String>(paperWidth.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (macAddress.present) {
      map['mac_address'] = Variable<String>(macAddress.value);
    }
    if (vendorId.present) {
      map['vendor_id'] = Variable<int>(vendorId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<int>(productId.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (lastConnectedAt.present) {
      map['last_connected_at'] = Variable<int>(lastConnectedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrinterProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('connectionType: $connectionType, ')
          ..write('paperWidth: $paperWidth, ')
          ..write('role: $role, ')
          ..write('macAddress: $macAddress, ')
          ..write('vendorId: $vendorId, ')
          ..write('productId: $productId, ')
          ..write('deviceName: $deviceName, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('port: $port, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('lastError: $lastError, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrintJobsTable extends PrintJobs
    with TableInfo<$PrintJobsTable, PrintJobRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrintJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _printTypeMeta = const VerificationMeta(
    'printType',
  );
  @override
  late final GeneratedColumn<String> printType = GeneratedColumn<String>(
    'print_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetRoleMeta = const VerificationMeta(
    'targetRole',
  );
  @override
  late final GeneratedColumn<String> targetRole = GeneratedColumn<String>(
    'target_role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetPrinterIdMeta = const VerificationMeta(
    'targetPrinterId',
  );
  @override
  late final GeneratedColumn<String> targetPrinterId = GeneratedColumn<String>(
    'target_printer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceKeyMeta = const VerificationMeta(
    'sourceKey',
  );
  @override
  late final GeneratedColumn<String> sourceKey = GeneratedColumn<String>(
    'source_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<int> processedAt = GeneratedColumn<int>(
    'processed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    printType,
    targetRole,
    targetPrinterId,
    sourceKey,
    payloadJson,
    status,
    retryCount,
    errorMessage,
    createdAt,
    updatedAt,
    processedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'print_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrintJobRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('print_type')) {
      context.handle(
        _printTypeMeta,
        printType.isAcceptableOrUnknown(data['print_type']!, _printTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_printTypeMeta);
    }
    if (data.containsKey('target_role')) {
      context.handle(
        _targetRoleMeta,
        targetRole.isAcceptableOrUnknown(data['target_role']!, _targetRoleMeta),
      );
    } else if (isInserting) {
      context.missing(_targetRoleMeta);
    }
    if (data.containsKey('target_printer_id')) {
      context.handle(
        _targetPrinterIdMeta,
        targetPrinterId.isAcceptableOrUnknown(
          data['target_printer_id']!,
          _targetPrinterIdMeta,
        ),
      );
    }
    if (data.containsKey('source_key')) {
      context.handle(
        _sourceKeyMeta,
        sourceKey.isAcceptableOrUnknown(data['source_key']!, _sourceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrintJobRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrintJobRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      printType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}print_type'],
      )!,
      targetRole: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_role'],
      )!,
      targetPrinterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_printer_id'],
      ),
      sourceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed_at'],
      ),
    );
  }

  @override
  $PrintJobsTable createAlias(String alias) {
    return $PrintJobsTable(attachedDatabase, alias);
  }
}

class PrintJobRow extends DataClass implements Insertable<PrintJobRow> {
  final String id;
  final String orderId;
  final String printType;
  final String targetRole;
  final String? targetPrinterId;

  /// Identifies what is being printed (e.g. `KOT:1024`). Used to stop the
  /// same document being queued twice while a copy is still active.
  final String sourceKey;

  /// `PosOrder.toJson()` snapshot, so the job can be re-printed exactly.
  final String? payloadJson;

  /// `PrintJobStatus.name`.
  final String status;
  final int retryCount;
  final String? errorMessage;
  final int createdAt;
  final int updatedAt;
  final int? processedAt;
  const PrintJobRow({
    required this.id,
    required this.orderId,
    required this.printType,
    required this.targetRole,
    this.targetPrinterId,
    required this.sourceKey,
    this.payloadJson,
    required this.status,
    required this.retryCount,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.processedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['print_type'] = Variable<String>(printType);
    map['target_role'] = Variable<String>(targetRole);
    if (!nullToAbsent || targetPrinterId != null) {
      map['target_printer_id'] = Variable<String>(targetPrinterId);
    }
    map['source_key'] = Variable<String>(sourceKey);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<int>(processedAt);
    }
    return map;
  }

  PrintJobsCompanion toCompanion(bool nullToAbsent) {
    return PrintJobsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      printType: Value(printType),
      targetRole: Value(targetRole),
      targetPrinterId: targetPrinterId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPrinterId),
      sourceKey: Value(sourceKey),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      status: Value(status),
      retryCount: Value(retryCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
    );
  }

  factory PrintJobRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrintJobRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      printType: serializer.fromJson<String>(json['printType']),
      targetRole: serializer.fromJson<String>(json['targetRole']),
      targetPrinterId: serializer.fromJson<String?>(json['targetPrinterId']),
      sourceKey: serializer.fromJson<String>(json['sourceKey']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      processedAt: serializer.fromJson<int?>(json['processedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'printType': serializer.toJson<String>(printType),
      'targetRole': serializer.toJson<String>(targetRole),
      'targetPrinterId': serializer.toJson<String?>(targetPrinterId),
      'sourceKey': serializer.toJson<String>(sourceKey),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'processedAt': serializer.toJson<int?>(processedAt),
    };
  }

  PrintJobRow copyWith({
    String? id,
    String? orderId,
    String? printType,
    String? targetRole,
    Value<String?> targetPrinterId = const Value.absent(),
    String? sourceKey,
    Value<String?> payloadJson = const Value.absent(),
    String? status,
    int? retryCount,
    Value<String?> errorMessage = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> processedAt = const Value.absent(),
  }) => PrintJobRow(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    printType: printType ?? this.printType,
    targetRole: targetRole ?? this.targetRole,
    targetPrinterId: targetPrinterId.present
        ? targetPrinterId.value
        : this.targetPrinterId,
    sourceKey: sourceKey ?? this.sourceKey,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    status: status ?? this.status,
    retryCount: retryCount ?? this.retryCount,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    processedAt: processedAt.present ? processedAt.value : this.processedAt,
  );
  PrintJobRow copyWithCompanion(PrintJobsCompanion data) {
    return PrintJobRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      printType: data.printType.present ? data.printType.value : this.printType,
      targetRole: data.targetRole.present
          ? data.targetRole.value
          : this.targetRole,
      targetPrinterId: data.targetPrinterId.present
          ? data.targetPrinterId.value
          : this.targetPrinterId,
      sourceKey: data.sourceKey.present ? data.sourceKey.value : this.sourceKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrintJobRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('printType: $printType, ')
          ..write('targetRole: $targetRole, ')
          ..write('targetPrinterId: $targetPrinterId, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('processedAt: $processedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    printType,
    targetRole,
    targetPrinterId,
    sourceKey,
    payloadJson,
    status,
    retryCount,
    errorMessage,
    createdAt,
    updatedAt,
    processedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrintJobRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.printType == this.printType &&
          other.targetRole == this.targetRole &&
          other.targetPrinterId == this.targetPrinterId &&
          other.sourceKey == this.sourceKey &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.processedAt == this.processedAt);
}

class PrintJobsCompanion extends UpdateCompanion<PrintJobRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> printType;
  final Value<String> targetRole;
  final Value<String?> targetPrinterId;
  final Value<String> sourceKey;
  final Value<String?> payloadJson;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<String?> errorMessage;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> processedAt;
  final Value<int> rowid;
  const PrintJobsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.printType = const Value.absent(),
    this.targetRole = const Value.absent(),
    this.targetPrinterId = const Value.absent(),
    this.sourceKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrintJobsCompanion.insert({
    required String id,
    required String orderId,
    required String printType,
    required String targetRole,
    this.targetPrinterId = const Value.absent(),
    required String sourceKey,
    this.payloadJson = const Value.absent(),
    required String status,
    this.retryCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.processedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       printType = Value(printType),
       targetRole = Value(targetRole),
       sourceKey = Value(sourceKey),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PrintJobRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? printType,
    Expression<String>? targetRole,
    Expression<String>? targetPrinterId,
    Expression<String>? sourceKey,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<String>? errorMessage,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? processedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (printType != null) 'print_type': printType,
      if (targetRole != null) 'target_role': targetRole,
      if (targetPrinterId != null) 'target_printer_id': targetPrinterId,
      if (sourceKey != null) 'source_key': sourceKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (processedAt != null) 'processed_at': processedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrintJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? printType,
    Value<String>? targetRole,
    Value<String?>? targetPrinterId,
    Value<String>? sourceKey,
    Value<String?>? payloadJson,
    Value<String>? status,
    Value<int>? retryCount,
    Value<String?>? errorMessage,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? processedAt,
    Value<int>? rowid,
  }) {
    return PrintJobsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      printType: printType ?? this.printType,
      targetRole: targetRole ?? this.targetRole,
      targetPrinterId: targetPrinterId ?? this.targetPrinterId,
      sourceKey: sourceKey ?? this.sourceKey,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      processedAt: processedAt ?? this.processedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (printType.present) {
      map['print_type'] = Variable<String>(printType.value);
    }
    if (targetRole.present) {
      map['target_role'] = Variable<String>(targetRole.value);
    }
    if (targetPrinterId.present) {
      map['target_printer_id'] = Variable<String>(targetPrinterId.value);
    }
    if (sourceKey.present) {
      map['source_key'] = Variable<String>(sourceKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<int>(processedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrintJobsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('printType: $printType, ')
          ..write('targetRole: $targetRole, ')
          ..write('targetPrinterId: $targetPrinterId, ')
          ..write('sourceKey: $sourceKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrintHistoryTable extends PrintHistory
    with TableInfo<$PrintHistoryTable, PrintHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrintHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _printerNameMeta = const VerificationMeta(
    'printerName',
  );
  @override
  late final GeneratedColumn<String> printerName = GeneratedColumn<String>(
    'printer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _connectionTypeMeta = const VerificationMeta(
    'connectionType',
  );
  @override
  late final GeneratedColumn<String> connectionType = GeneratedColumn<String>(
    'connection_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  @override
  late final GeneratedColumn<String> orderId = GeneratedColumn<String>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _printTypeMeta = const VerificationMeta(
    'printType',
  );
  @override
  late final GeneratedColumn<String> printType = GeneratedColumn<String>(
    'print_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSuccessMeta = const VerificationMeta(
    'isSuccess',
  );
  @override
  late final GeneratedColumn<bool> isSuccess = GeneratedColumn<bool>(
    'is_success',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_success" IN (0, 1))',
    ),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    at,
    printerName,
    connectionType,
    orderId,
    printType,
    isSuccess,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'print_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrintHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('printer_name')) {
      context.handle(
        _printerNameMeta,
        printerName.isAcceptableOrUnknown(
          data['printer_name']!,
          _printerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_printerNameMeta);
    }
    if (data.containsKey('connection_type')) {
      context.handle(
        _connectionTypeMeta,
        connectionType.isAcceptableOrUnknown(
          data['connection_type']!,
          _connectionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectionTypeMeta);
    }
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('print_type')) {
      context.handle(
        _printTypeMeta,
        printType.isAcceptableOrUnknown(data['print_type']!, _printTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_printTypeMeta);
    }
    if (data.containsKey('is_success')) {
      context.handle(
        _isSuccessMeta,
        isSuccess.isAcceptableOrUnknown(data['is_success']!, _isSuccessMeta),
      );
    } else if (isInserting) {
      context.missing(_isSuccessMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrintHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrintHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
      printerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}printer_name'],
      )!,
      connectionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}connection_type'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      printType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}print_type'],
      )!,
      isSuccess: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_success'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $PrintHistoryTable createAlias(String alias) {
    return $PrintHistoryTable(attachedDatabase, alias);
  }
}

class PrintHistoryRow extends DataClass implements Insertable<PrintHistoryRow> {
  final String id;
  final String? jobId;
  final int at;
  final String printerName;
  final String connectionType;
  final String orderId;
  final String printType;
  final bool isSuccess;
  final String? errorMessage;
  const PrintHistoryRow({
    required this.id,
    this.jobId,
    required this.at,
    required this.printerName,
    required this.connectionType,
    required this.orderId,
    required this.printType,
    required this.isSuccess,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || jobId != null) {
      map['job_id'] = Variable<String>(jobId);
    }
    map['at'] = Variable<int>(at);
    map['printer_name'] = Variable<String>(printerName);
    map['connection_type'] = Variable<String>(connectionType);
    map['order_id'] = Variable<String>(orderId);
    map['print_type'] = Variable<String>(printType);
    map['is_success'] = Variable<bool>(isSuccess);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  PrintHistoryCompanion toCompanion(bool nullToAbsent) {
    return PrintHistoryCompanion(
      id: Value(id),
      jobId: jobId == null && nullToAbsent
          ? const Value.absent()
          : Value(jobId),
      at: Value(at),
      printerName: Value(printerName),
      connectionType: Value(connectionType),
      orderId: Value(orderId),
      printType: Value(printType),
      isSuccess: Value(isSuccess),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory PrintHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrintHistoryRow(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String?>(json['jobId']),
      at: serializer.fromJson<int>(json['at']),
      printerName: serializer.fromJson<String>(json['printerName']),
      connectionType: serializer.fromJson<String>(json['connectionType']),
      orderId: serializer.fromJson<String>(json['orderId']),
      printType: serializer.fromJson<String>(json['printType']),
      isSuccess: serializer.fromJson<bool>(json['isSuccess']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String?>(jobId),
      'at': serializer.toJson<int>(at),
      'printerName': serializer.toJson<String>(printerName),
      'connectionType': serializer.toJson<String>(connectionType),
      'orderId': serializer.toJson<String>(orderId),
      'printType': serializer.toJson<String>(printType),
      'isSuccess': serializer.toJson<bool>(isSuccess),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  PrintHistoryRow copyWith({
    String? id,
    Value<String?> jobId = const Value.absent(),
    int? at,
    String? printerName,
    String? connectionType,
    String? orderId,
    String? printType,
    bool? isSuccess,
    Value<String?> errorMessage = const Value.absent(),
  }) => PrintHistoryRow(
    id: id ?? this.id,
    jobId: jobId.present ? jobId.value : this.jobId,
    at: at ?? this.at,
    printerName: printerName ?? this.printerName,
    connectionType: connectionType ?? this.connectionType,
    orderId: orderId ?? this.orderId,
    printType: printType ?? this.printType,
    isSuccess: isSuccess ?? this.isSuccess,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  PrintHistoryRow copyWithCompanion(PrintHistoryCompanion data) {
    return PrintHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      at: data.at.present ? data.at.value : this.at,
      printerName: data.printerName.present
          ? data.printerName.value
          : this.printerName,
      connectionType: data.connectionType.present
          ? data.connectionType.value
          : this.connectionType,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      printType: data.printType.present ? data.printType.value : this.printType,
      isSuccess: data.isSuccess.present ? data.isSuccess.value : this.isSuccess,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrintHistoryRow(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('at: $at, ')
          ..write('printerName: $printerName, ')
          ..write('connectionType: $connectionType, ')
          ..write('orderId: $orderId, ')
          ..write('printType: $printType, ')
          ..write('isSuccess: $isSuccess, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jobId,
    at,
    printerName,
    connectionType,
    orderId,
    printType,
    isSuccess,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrintHistoryRow &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.at == this.at &&
          other.printerName == this.printerName &&
          other.connectionType == this.connectionType &&
          other.orderId == this.orderId &&
          other.printType == this.printType &&
          other.isSuccess == this.isSuccess &&
          other.errorMessage == this.errorMessage);
}

class PrintHistoryCompanion extends UpdateCompanion<PrintHistoryRow> {
  final Value<String> id;
  final Value<String?> jobId;
  final Value<int> at;
  final Value<String> printerName;
  final Value<String> connectionType;
  final Value<String> orderId;
  final Value<String> printType;
  final Value<bool> isSuccess;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const PrintHistoryCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.at = const Value.absent(),
    this.printerName = const Value.absent(),
    this.connectionType = const Value.absent(),
    this.orderId = const Value.absent(),
    this.printType = const Value.absent(),
    this.isSuccess = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrintHistoryCompanion.insert({
    required String id,
    this.jobId = const Value.absent(),
    required int at,
    required String printerName,
    required String connectionType,
    required String orderId,
    required String printType,
    required bool isSuccess,
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       at = Value(at),
       printerName = Value(printerName),
       connectionType = Value(connectionType),
       orderId = Value(orderId),
       printType = Value(printType),
       isSuccess = Value(isSuccess);
  static Insertable<PrintHistoryRow> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<int>? at,
    Expression<String>? printerName,
    Expression<String>? connectionType,
    Expression<String>? orderId,
    Expression<String>? printType,
    Expression<bool>? isSuccess,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (at != null) 'at': at,
      if (printerName != null) 'printer_name': printerName,
      if (connectionType != null) 'connection_type': connectionType,
      if (orderId != null) 'order_id': orderId,
      if (printType != null) 'print_type': printType,
      if (isSuccess != null) 'is_success': isSuccess,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrintHistoryCompanion copyWith({
    Value<String>? id,
    Value<String?>? jobId,
    Value<int>? at,
    Value<String>? printerName,
    Value<String>? connectionType,
    Value<String>? orderId,
    Value<String>? printType,
    Value<bool>? isSuccess,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return PrintHistoryCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      at: at ?? this.at,
      printerName: printerName ?? this.printerName,
      connectionType: connectionType ?? this.connectionType,
      orderId: orderId ?? this.orderId,
      printType: printType ?? this.printType,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (printerName.present) {
      map['printer_name'] = Variable<String>(printerName.value);
    }
    if (connectionType.present) {
      map['connection_type'] = Variable<String>(connectionType.value);
    }
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (printType.present) {
      map['print_type'] = Variable<String>(printType.value);
    }
    if (isSuccess.present) {
      map['is_success'] = Variable<bool>(isSuccess.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrintHistoryCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('at: $at, ')
          ..write('printerName: $printerName, ')
          ..write('connectionType: $connectionType, ')
          ..write('orderId: $orderId, ')
          ..write('printType: $printType, ')
          ..write('isSuccess: $isSuccess, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<int> at = GeneratedColumn<int>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _staffIdMeta = const VerificationMeta(
    'staffId',
  );
  @override
  late final GeneratedColumn<String> staffId = GeneratedColumn<String>(
    'staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailsJsonMeta = const VerificationMeta(
    'detailsJson',
  );
  @override
  late final GeneratedColumn<String> detailsJson = GeneratedColumn<String>(
    'details_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    at,
    staffId,
    action,
    entity,
    entityId,
    detailsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('staff_id')) {
      context.handle(
        _staffIdMeta,
        staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta),
      );
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('details_json')) {
      context.handle(
        _detailsJsonMeta,
        detailsJson.isAcceptableOrUnknown(
          data['details_json']!,
          _detailsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at'],
      )!,
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      ),
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      detailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details_json'],
      ),
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final String id;
  final int at;
  final String? staffId;
  final String action;
  final String entity;
  final String? entityId;
  final String? detailsJson;
  const AuditLogRow({
    required this.id,
    required this.at,
    this.staffId,
    required this.action,
    required this.entity,
    this.entityId,
    this.detailsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['at'] = Variable<int>(at);
    if (!nullToAbsent || staffId != null) {
      map['staff_id'] = Variable<String>(staffId);
    }
    map['action'] = Variable<String>(action);
    map['entity'] = Variable<String>(entity);
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    if (!nullToAbsent || detailsJson != null) {
      map['details_json'] = Variable<String>(detailsJson);
    }
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      at: Value(at),
      staffId: staffId == null && nullToAbsent
          ? const Value.absent()
          : Value(staffId),
      action: Value(action),
      entity: Value(entity),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      detailsJson: detailsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailsJson),
    );
  }

  factory AuditLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      id: serializer.fromJson<String>(json['id']),
      at: serializer.fromJson<int>(json['at']),
      staffId: serializer.fromJson<String?>(json['staffId']),
      action: serializer.fromJson<String>(json['action']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      detailsJson: serializer.fromJson<String?>(json['detailsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'at': serializer.toJson<int>(at),
      'staffId': serializer.toJson<String?>(staffId),
      'action': serializer.toJson<String>(action),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String?>(entityId),
      'detailsJson': serializer.toJson<String?>(detailsJson),
    };
  }

  AuditLogRow copyWith({
    String? id,
    int? at,
    Value<String?> staffId = const Value.absent(),
    String? action,
    String? entity,
    Value<String?> entityId = const Value.absent(),
    Value<String?> detailsJson = const Value.absent(),
  }) => AuditLogRow(
    id: id ?? this.id,
    at: at ?? this.at,
    staffId: staffId.present ? staffId.value : this.staffId,
    action: action ?? this.action,
    entity: entity ?? this.entity,
    entityId: entityId.present ? entityId.value : this.entityId,
    detailsJson: detailsJson.present ? detailsJson.value : this.detailsJson,
  );
  AuditLogRow copyWithCompanion(AuditLogCompanion data) {
    return AuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      at: data.at.present ? data.at.value : this.at,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      action: data.action.present ? data.action.value : this.action,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      detailsJson: data.detailsJson.present
          ? data.detailsJson.value
          : this.detailsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('staffId: $staffId, ')
          ..write('action: $action, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('detailsJson: $detailsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, at, staffId, action, entity, entityId, detailsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.id == this.id &&
          other.at == this.at &&
          other.staffId == this.staffId &&
          other.action == this.action &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.detailsJson == this.detailsJson);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<String> id;
  final Value<int> at;
  final Value<String?> staffId;
  final Value<String> action;
  final Value<String> entity;
  final Value<String?> entityId;
  final Value<String?> detailsJson;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.at = const Value.absent(),
    this.staffId = const Value.absent(),
    this.action = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    required String id,
    required int at,
    this.staffId = const Value.absent(),
    required String action,
    required String entity,
    this.entityId = const Value.absent(),
    this.detailsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       at = Value(at),
       action = Value(action),
       entity = Value(entity);
  static Insertable<AuditLogRow> custom({
    Expression<String>? id,
    Expression<int>? at,
    Expression<String>? staffId,
    Expression<String>? action,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? detailsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (at != null) 'at': at,
      if (staffId != null) 'staff_id': staffId,
      if (action != null) 'action': action,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (detailsJson != null) 'details_json': detailsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith({
    Value<String>? id,
    Value<int>? at,
    Value<String?>? staffId,
    Value<String>? action,
    Value<String>? entity,
    Value<String?>? entityId,
    Value<String?>? detailsJson,
    Value<int>? rowid,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      at: at ?? this.at,
      staffId: staffId ?? this.staffId,
      action: action ?? this.action,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      detailsJson: detailsJson ?? this.detailsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (at.present) {
      map['at'] = Variable<int>(at.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (detailsJson.present) {
      map['details_json'] = Variable<String>(detailsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('at: $at, ')
          ..write('staffId: $staffId, ')
          ..write('action: $action, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('detailsJson: $detailsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MigrationLogTable migrationLog = $MigrationLogTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $BusinessProfilesTable businessProfiles = $BusinessProfilesTable(
    this,
  );
  late final $PrinterProfilesTable printerProfiles = $PrinterProfilesTable(
    this,
  );
  late final $PrintJobsTable printJobs = $PrintJobsTable(this);
  late final $PrintHistoryTable printHistory = $PrintHistoryTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final Index idxPrintJobsStatus = Index(
    'idx_print_jobs_status',
    'CREATE INDEX idx_print_jobs_status ON print_jobs (status)',
  );
  late final Index idxPrintJobsSourceKey = Index(
    'idx_print_jobs_source_key',
    'CREATE INDEX idx_print_jobs_source_key ON print_jobs (source_key)',
  );
  late final Index idxPrintHistoryAt = Index(
    'idx_print_history_at',
    'CREATE INDEX idx_print_history_at ON print_history (at)',
  );
  late final Index idxAuditLogAt = Index(
    'idx_audit_log_at',
    'CREATE INDEX idx_audit_log_at ON audit_log (at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    migrationLog,
    appSettings,
    businessProfiles,
    printerProfiles,
    printJobs,
    printHistory,
    auditLog,
    idxPrintJobsStatus,
    idxPrintJobsSourceKey,
    idxPrintHistoryAt,
    idxAuditLogAt,
  ];
}

typedef $$MigrationLogTableCreateCompanionBuilder =
    MigrationLogCompanion Function({
      Value<int> version,
      required int appliedAt,
      Value<String> notes,
    });
typedef $$MigrationLogTableUpdateCompanionBuilder =
    MigrationLogCompanion Function({
      Value<int> version,
      Value<int> appliedAt,
      Value<String> notes,
    });

class $$MigrationLogTableFilterComposer
    extends Composer<_$AppDatabase, $MigrationLogTable> {
  $$MigrationLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MigrationLogTableOrderingComposer
    extends Composer<_$AppDatabase, $MigrationLogTable> {
  $$MigrationLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MigrationLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $MigrationLogTable> {
  $$MigrationLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$MigrationLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MigrationLogTable,
          MigrationLogRow,
          $$MigrationLogTableFilterComposer,
          $$MigrationLogTableOrderingComposer,
          $$MigrationLogTableAnnotationComposer,
          $$MigrationLogTableCreateCompanionBuilder,
          $$MigrationLogTableUpdateCompanionBuilder,
          (
            MigrationLogRow,
            BaseReferences<_$AppDatabase, $MigrationLogTable, MigrationLogRow>,
          ),
          MigrationLogRow,
          PrefetchHooks Function()
        > {
  $$MigrationLogTableTableManager(_$AppDatabase db, $MigrationLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MigrationLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MigrationLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MigrationLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                Value<int> appliedAt = const Value.absent(),
                Value<String> notes = const Value.absent(),
              }) => MigrationLogCompanion(
                version: version,
                appliedAt: appliedAt,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> version = const Value.absent(),
                required int appliedAt,
                Value<String> notes = const Value.absent(),
              }) => MigrationLogCompanion.insert(
                version: version,
                appliedAt: appliedAt,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MigrationLogTable, MigrationLogRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MigrationLogTable,
                    MigrationLogRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MigrationLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MigrationLogTable,
      MigrationLogRow,
      $$MigrationLogTableFilterComposer,
      $$MigrationLogTableOrderingComposer,
      $$MigrationLogTableAnnotationComposer,
      $$MigrationLogTableCreateCompanionBuilder,
      $$MigrationLogTableUpdateCompanionBuilder,
      (
        MigrationLogRow,
        BaseReferences<_$AppDatabase, $MigrationLogTable, MigrationLogRow>,
      ),
      MigrationLogRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $$BusinessProfilesTableCreateCompanionBuilder =
    BusinessProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> address,
      Value<String> phone,
      Value<String> gstin,
      Value<String> fssai,
      Value<String> upiId,
      Value<String> billFooter,
      Value<String> currencyCode,
      required int updatedAt,
    });
typedef $$BusinessProfilesTableUpdateCompanionBuilder =
    BusinessProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> address,
      Value<String> phone,
      Value<String> gstin,
      Value<String> fssai,
      Value<String> upiId,
      Value<String> billFooter,
      Value<String> currencyCode,
      Value<int> updatedAt,
    });

class $$BusinessProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fssai => $composableBuilder(
    column: $table.fssai,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get upiId => $composableBuilder(
    column: $table.upiId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get billFooter => $composableBuilder(
    column: $table.billFooter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BusinessProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gstin => $composableBuilder(
    column: $table.gstin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fssai => $composableBuilder(
    column: $table.fssai,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get upiId => $composableBuilder(
    column: $table.upiId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get billFooter => $composableBuilder(
    column: $table.billFooter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessProfilesTable> {
  $$BusinessProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get gstin =>
      $composableBuilder(column: $table.gstin, builder: (column) => column);

  GeneratedColumn<String> get fssai =>
      $composableBuilder(column: $table.fssai, builder: (column) => column);

  GeneratedColumn<String> get upiId =>
      $composableBuilder(column: $table.upiId, builder: (column) => column);

  GeneratedColumn<String> get billFooter => $composableBuilder(
    column: $table.billFooter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BusinessProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessProfilesTable,
          BusinessProfileRow,
          $$BusinessProfilesTableFilterComposer,
          $$BusinessProfilesTableOrderingComposer,
          $$BusinessProfilesTableAnnotationComposer,
          $$BusinessProfilesTableCreateCompanionBuilder,
          $$BusinessProfilesTableUpdateCompanionBuilder,
          (
            BusinessProfileRow,
            BaseReferences<
              _$AppDatabase,
              $BusinessProfilesTable,
              BusinessProfileRow
            >,
          ),
          BusinessProfileRow,
          PrefetchHooks Function()
        > {
  $$BusinessProfilesTableTableManager(
    _$AppDatabase db,
    $BusinessProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> gstin = const Value.absent(),
                Value<String> fssai = const Value.absent(),
                Value<String> upiId = const Value.absent(),
                Value<String> billFooter = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => BusinessProfilesCompanion(
                id: id,
                name: name,
                address: address,
                phone: phone,
                gstin: gstin,
                fssai: fssai,
                upiId: upiId,
                billFooter: billFooter,
                currencyCode: currencyCode,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> gstin = const Value.absent(),
                Value<String> fssai = const Value.absent(),
                Value<String> upiId = const Value.absent(),
                Value<String> billFooter = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                required int updatedAt,
              }) => BusinessProfilesCompanion.insert(
                id: id,
                name: name,
                address: address,
                phone: phone,
                gstin: gstin,
                fssai: fssai,
                upiId: upiId,
                billFooter: billFooter,
                currencyCode: currencyCode,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BusinessProfilesTable, BusinessProfileRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $BusinessProfilesTable,
                    BusinessProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BusinessProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessProfilesTable,
      BusinessProfileRow,
      $$BusinessProfilesTableFilterComposer,
      $$BusinessProfilesTableOrderingComposer,
      $$BusinessProfilesTableAnnotationComposer,
      $$BusinessProfilesTableCreateCompanionBuilder,
      $$BusinessProfilesTableUpdateCompanionBuilder,
      (
        BusinessProfileRow,
        BaseReferences<
          _$AppDatabase,
          $BusinessProfilesTable,
          BusinessProfileRow
        >,
      ),
      BusinessProfileRow,
      PrefetchHooks Function()
    >;
typedef $$PrinterProfilesTableCreateCompanionBuilder =
    PrinterProfilesCompanion Function({
      required String id,
      required String name,
      required String connectionType,
      required String paperWidth,
      required String role,
      Value<String?> macAddress,
      Value<int?> vendorId,
      Value<int?> productId,
      Value<String?> deviceName,
      Value<String?> ipAddress,
      Value<int> port,
      Value<int?> lastConnectedAt,
      Value<String?> lastError,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PrinterProfilesTableUpdateCompanionBuilder =
    PrinterProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> connectionType,
      Value<String> paperWidth,
      Value<String> role,
      Value<String?> macAddress,
      Value<int?> vendorId,
      Value<int?> productId,
      Value<String?> deviceName,
      Value<String?> ipAddress,
      Value<int> port,
      Value<int?> lastConnectedAt,
      Value<String?> lastError,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$PrinterProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $PrinterProfilesTable> {
  $$PrinterProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paperWidth => $composableBuilder(
    column: $table.paperWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrinterProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $PrinterProfilesTable> {
  $$PrinterProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paperWidth => $composableBuilder(
    column: $table.paperWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get vendorId => $composableBuilder(
    column: $table.vendorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipAddress => $composableBuilder(
    column: $table.ipAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrinterProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrinterProfilesTable> {
  $$PrinterProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paperWidth => $composableBuilder(
    column: $table.paperWidth,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get macAddress => $composableBuilder(
    column: $table.macAddress,
    builder: (column) => column,
  );

  GeneratedColumn<int> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<int> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ipAddress =>
      $composableBuilder(column: $table.ipAddress, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<int> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PrinterProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrinterProfilesTable,
          PrinterProfileRow,
          $$PrinterProfilesTableFilterComposer,
          $$PrinterProfilesTableOrderingComposer,
          $$PrinterProfilesTableAnnotationComposer,
          $$PrinterProfilesTableCreateCompanionBuilder,
          $$PrinterProfilesTableUpdateCompanionBuilder,
          (
            PrinterProfileRow,
            BaseReferences<
              _$AppDatabase,
              $PrinterProfilesTable,
              PrinterProfileRow
            >,
          ),
          PrinterProfileRow,
          PrefetchHooks Function()
        > {
  $$PrinterProfilesTableTableManager(
    _$AppDatabase db,
    $PrinterProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrinterProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrinterProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrinterProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> connectionType = const Value.absent(),
                Value<String> paperWidth = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> macAddress = const Value.absent(),
                Value<int?> vendorId = const Value.absent(),
                Value<int?> productId = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<String?> ipAddress = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<int?> lastConnectedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrinterProfilesCompanion(
                id: id,
                name: name,
                connectionType: connectionType,
                paperWidth: paperWidth,
                role: role,
                macAddress: macAddress,
                vendorId: vendorId,
                productId: productId,
                deviceName: deviceName,
                ipAddress: ipAddress,
                port: port,
                lastConnectedAt: lastConnectedAt,
                lastError: lastError,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String connectionType,
                required String paperWidth,
                required String role,
                Value<String?> macAddress = const Value.absent(),
                Value<int?> vendorId = const Value.absent(),
                Value<int?> productId = const Value.absent(),
                Value<String?> deviceName = const Value.absent(),
                Value<String?> ipAddress = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<int?> lastConnectedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PrinterProfilesCompanion.insert(
                id: id,
                name: name,
                connectionType: connectionType,
                paperWidth: paperWidth,
                role: role,
                macAddress: macAddress,
                vendorId: vendorId,
                productId: productId,
                deviceName: deviceName,
                ipAddress: ipAddress,
                port: port,
                lastConnectedAt: lastConnectedAt,
                lastError: lastError,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrinterProfilesTable, PrinterProfileRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PrinterProfilesTable,
                    PrinterProfileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrinterProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrinterProfilesTable,
      PrinterProfileRow,
      $$PrinterProfilesTableFilterComposer,
      $$PrinterProfilesTableOrderingComposer,
      $$PrinterProfilesTableAnnotationComposer,
      $$PrinterProfilesTableCreateCompanionBuilder,
      $$PrinterProfilesTableUpdateCompanionBuilder,
      (
        PrinterProfileRow,
        BaseReferences<_$AppDatabase, $PrinterProfilesTable, PrinterProfileRow>,
      ),
      PrinterProfileRow,
      PrefetchHooks Function()
    >;
typedef $$PrintJobsTableCreateCompanionBuilder = PrintJobsCompanion Function({
  required String id,
  required String orderId,
  required String printType,
  required String targetRole,
  Value<String?> targetPrinterId,
  required String sourceKey,
  Value<String?> payloadJson,
  required String status,
  Value<int> retryCount,
  Value<String?> errorMessage,
  required int createdAt,
  required int updatedAt,
  Value<int?> processedAt,
  Value<int> rowid,
});
typedef $$PrintJobsTableUpdateCompanionBuilder = PrintJobsCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String> printType,
  Value<String> targetRole,
  Value<String?> targetPrinterId,
  Value<String> sourceKey,
  Value<String?> payloadJson,
  Value<String> status,
  Value<int> retryCount,
  Value<String?> errorMessage,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> processedAt,
  Value<int> rowid,
});

class $$PrintJobsTableFilterComposer
    extends Composer<_$AppDatabase, $PrintJobsTable> {
  $$PrintJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get printType => $composableBuilder(
    column: $table.printType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetRole => $composableBuilder(
    column: $table.targetRole,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetPrinterId => $composableBuilder(
    column: $table.targetPrinterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrintJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrintJobsTable> {
  $$PrintJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get printType => $composableBuilder(
    column: $table.printType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetRole => $composableBuilder(
    column: $table.targetRole,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetPrinterId => $composableBuilder(
    column: $table.targetPrinterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceKey => $composableBuilder(
    column: $table.sourceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrintJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrintJobsTable> {
  $$PrintJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get printType =>
      $composableBuilder(column: $table.printType, builder: (column) => column);

  GeneratedColumn<String> get targetRole => $composableBuilder(
    column: $table.targetRole,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetPrinterId => $composableBuilder(
    column: $table.targetPrinterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceKey =>
      $composableBuilder(column: $table.sourceKey, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );
}

class $$PrintJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrintJobsTable,
          PrintJobRow,
          $$PrintJobsTableFilterComposer,
          $$PrintJobsTableOrderingComposer,
          $$PrintJobsTableAnnotationComposer,
          $$PrintJobsTableCreateCompanionBuilder,
          $$PrintJobsTableUpdateCompanionBuilder,
          (
            PrintJobRow,
            BaseReferences<_$AppDatabase, $PrintJobsTable, PrintJobRow>,
          ),
          PrintJobRow,
          PrefetchHooks Function()
        > {
  $$PrintJobsTableTableManager(_$AppDatabase db, $PrintJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrintJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrintJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrintJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> printType = const Value.absent(),
                Value<String> targetRole = const Value.absent(),
                Value<String?> targetPrinterId = const Value.absent(),
                Value<String> sourceKey = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> processedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrintJobsCompanion(
                id: id,
                orderId: orderId,
                printType: printType,
                targetRole: targetRole,
                targetPrinterId: targetPrinterId,
                sourceKey: sourceKey,
                payloadJson: payloadJson,
                status: status,
                retryCount: retryCount,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                processedAt: processedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String printType,
                required String targetRole,
                Value<String?> targetPrinterId = const Value.absent(),
                required String sourceKey,
                Value<String?> payloadJson = const Value.absent(),
                required String status,
                Value<int> retryCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int?> processedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrintJobsCompanion.insert(
                id: id,
                orderId: orderId,
                printType: printType,
                targetRole: targetRole,
                targetPrinterId: targetPrinterId,
                sourceKey: sourceKey,
                payloadJson: payloadJson,
                status: status,
                retryCount: retryCount,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                processedAt: processedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrintJobsTable, PrintJobRow>(table),
                  BaseReferences<_$AppDatabase, $PrintJobsTable, PrintJobRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrintJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrintJobsTable,
      PrintJobRow,
      $$PrintJobsTableFilterComposer,
      $$PrintJobsTableOrderingComposer,
      $$PrintJobsTableAnnotationComposer,
      $$PrintJobsTableCreateCompanionBuilder,
      $$PrintJobsTableUpdateCompanionBuilder,
      (
        PrintJobRow,
        BaseReferences<_$AppDatabase, $PrintJobsTable, PrintJobRow>,
      ),
      PrintJobRow,
      PrefetchHooks Function()
    >;
typedef $$PrintHistoryTableCreateCompanionBuilder =
    PrintHistoryCompanion Function({
      required String id,
      Value<String?> jobId,
      required int at,
      required String printerName,
      required String connectionType,
      required String orderId,
      required String printType,
      required bool isSuccess,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$PrintHistoryTableUpdateCompanionBuilder =
    PrintHistoryCompanion Function({
      Value<String> id,
      Value<String?> jobId,
      Value<int> at,
      Value<String> printerName,
      Value<String> connectionType,
      Value<String> orderId,
      Value<String> printType,
      Value<bool> isSuccess,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$PrintHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PrintHistoryTable> {
  $$PrintHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get printerName => $composableBuilder(
    column: $table.printerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get printType => $composableBuilder(
    column: $table.printType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSuccess => $composableBuilder(
    column: $table.isSuccess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrintHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PrintHistoryTable> {
  $$PrintHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get printerName => $composableBuilder(
    column: $table.printerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderId => $composableBuilder(
    column: $table.orderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get printType => $composableBuilder(
    column: $table.printType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSuccess => $composableBuilder(
    column: $table.isSuccess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrintHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrintHistoryTable> {
  $$PrintHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get printerName => $composableBuilder(
    column: $table.printerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get connectionType => $composableBuilder(
    column: $table.connectionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderId =>
      $composableBuilder(column: $table.orderId, builder: (column) => column);

  GeneratedColumn<String> get printType =>
      $composableBuilder(column: $table.printType, builder: (column) => column);

  GeneratedColumn<bool> get isSuccess =>
      $composableBuilder(column: $table.isSuccess, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$PrintHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrintHistoryTable,
          PrintHistoryRow,
          $$PrintHistoryTableFilterComposer,
          $$PrintHistoryTableOrderingComposer,
          $$PrintHistoryTableAnnotationComposer,
          $$PrintHistoryTableCreateCompanionBuilder,
          $$PrintHistoryTableUpdateCompanionBuilder,
          (
            PrintHistoryRow,
            BaseReferences<_$AppDatabase, $PrintHistoryTable, PrintHistoryRow>,
          ),
          PrintHistoryRow,
          PrefetchHooks Function()
        > {
  $$PrintHistoryTableTableManager(_$AppDatabase db, $PrintHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrintHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrintHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrintHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> jobId = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<String> printerName = const Value.absent(),
                Value<String> connectionType = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> printType = const Value.absent(),
                Value<bool> isSuccess = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrintHistoryCompanion(
                id: id,
                jobId: jobId,
                at: at,
                printerName: printerName,
                connectionType: connectionType,
                orderId: orderId,
                printType: printType,
                isSuccess: isSuccess,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> jobId = const Value.absent(),
                required int at,
                required String printerName,
                required String connectionType,
                required String orderId,
                required String printType,
                required bool isSuccess,
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrintHistoryCompanion.insert(
                id: id,
                jobId: jobId,
                at: at,
                printerName: printerName,
                connectionType: connectionType,
                orderId: orderId,
                printType: printType,
                isSuccess: isSuccess,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrintHistoryTable, PrintHistoryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PrintHistoryTable,
                    PrintHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrintHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrintHistoryTable,
      PrintHistoryRow,
      $$PrintHistoryTableFilterComposer,
      $$PrintHistoryTableOrderingComposer,
      $$PrintHistoryTableAnnotationComposer,
      $$PrintHistoryTableCreateCompanionBuilder,
      $$PrintHistoryTableUpdateCompanionBuilder,
      (
        PrintHistoryRow,
        BaseReferences<_$AppDatabase, $PrintHistoryTable, PrintHistoryRow>,
      ),
      PrintHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  required String id,
  required int at,
  Value<String?> staffId,
  required String action,
  required String entity,
  Value<String?> entityId,
  Value<String?> detailsJson,
  Value<int> rowid,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<String> id,
  Value<int> at,
  Value<String?> staffId,
  Value<String> action,
  Value<String> entity,
  Value<String?> entityId,
  Value<String?> detailsJson,
  Value<int> rowid,
});

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staffId => $composableBuilder(
    column: $table.staffId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staffId => $composableBuilder(
    column: $table.staffId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get detailsJson => $composableBuilder(
    column: $table.detailsJson,
    builder: (column) => column,
  );
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogTable,
          AuditLogRow,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (
            AuditLogRow,
            BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>,
          ),
          AuditLogRow,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> at = const Value.absent(),
                Value<String?> staffId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                at: at,
                staffId: staffId,
                action: action,
                entity: entity,
                entityId: entityId,
                detailsJson: detailsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int at,
                Value<String?> staffId = const Value.absent(),
                required String action,
                required String entity,
                Value<String?> entityId = const Value.absent(),
                Value<String?> detailsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion.insert(
                id: id,
                at: at,
                staffId: staffId,
                action: action,
                entity: entity,
                entityId: entityId,
                detailsJson: detailsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditLogTable, AuditLogRow>(table),
                  BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogTable,
      AuditLogRow,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (AuditLogRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>),
      AuditLogRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MigrationLogTableTableManager get migrationLog =>
      $$MigrationLogTableTableManager(_db, _db.migrationLog);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$BusinessProfilesTableTableManager get businessProfiles =>
      $$BusinessProfilesTableTableManager(_db, _db.businessProfiles);
  $$PrinterProfilesTableTableManager get printerProfiles =>
      $$PrinterProfilesTableTableManager(_db, _db.printerProfiles);
  $$PrintJobsTableTableManager get printJobs =>
      $$PrintJobsTableTableManager(_db, _db.printJobs);
  $$PrintHistoryTableTableManager get printHistory =>
      $$PrintHistoryTableTableManager(_db, _db.printHistory);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
}
