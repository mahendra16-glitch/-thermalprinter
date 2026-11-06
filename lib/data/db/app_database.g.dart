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
  static const VerificationMeta _printableDotsMeta = const VerificationMeta(
    'printableDots',
  );
  @override
  late final GeneratedColumn<int> printableDots = GeneratedColumn<int>(
    'printable_dots',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _charsPerLineMeta = const VerificationMeta(
    'charsPerLine',
  );
  @override
  late final GeneratedColumn<int> charsPerLine = GeneratedColumn<int>(
    'chars_per_line',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rasterThresholdMeta = const VerificationMeta(
    'rasterThreshold',
  );
  @override
  late final GeneratedColumn<int> rasterThreshold = GeneratedColumn<int>(
    'raster_threshold',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feedLinesMeta = const VerificationMeta(
    'feedLines',
  );
  @override
  late final GeneratedColumn<int> feedLines = GeneratedColumn<int>(
    'feed_lines',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoCutMeta = const VerificationMeta(
    'autoCut',
  );
  @override
  late final GeneratedColumn<bool> autoCut = GeneratedColumn<bool>(
    'auto_cut',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_cut" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    printableDots,
    charsPerLine,
    rasterThreshold,
    feedLines,
    autoCut,
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
    if (data.containsKey('printable_dots')) {
      context.handle(
        _printableDotsMeta,
        printableDots.isAcceptableOrUnknown(
          data['printable_dots']!,
          _printableDotsMeta,
        ),
      );
    }
    if (data.containsKey('chars_per_line')) {
      context.handle(
        _charsPerLineMeta,
        charsPerLine.isAcceptableOrUnknown(
          data['chars_per_line']!,
          _charsPerLineMeta,
        ),
      );
    }
    if (data.containsKey('raster_threshold')) {
      context.handle(
        _rasterThresholdMeta,
        rasterThreshold.isAcceptableOrUnknown(
          data['raster_threshold']!,
          _rasterThresholdMeta,
        ),
      );
    }
    if (data.containsKey('feed_lines')) {
      context.handle(
        _feedLinesMeta,
        feedLines.isAcceptableOrUnknown(data['feed_lines']!, _feedLinesMeta),
      );
    }
    if (data.containsKey('auto_cut')) {
      context.handle(
        _autoCutMeta,
        autoCut.isAcceptableOrUnknown(data['auto_cut']!, _autoCutMeta),
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
      printableDots: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}printable_dots'],
      ),
      charsPerLine: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chars_per_line'],
      ),
      rasterThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raster_threshold'],
      ),
      feedLines: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feed_lines'],
      ),
      autoCut: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_cut'],
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

  /// Printable width in dots (often 384 for 58mm, 576 for 80mm; some
  /// 80mm printers use 512).
  final int? printableDots;

  /// Characters per line in text mode (32 / 42 / 48 …).
  final int? charsPerLine;

  /// Luminance below which a raster pixel prints black (80–220).
  final int? rasterThreshold;

  /// Blank lines fed before cutting (0–10).
  final int? feedLines;

  /// Whether to send the cut command.
  final bool autoCut;
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
    this.printableDots,
    this.charsPerLine,
    this.rasterThreshold,
    this.feedLines,
    required this.autoCut,
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
    if (!nullToAbsent || printableDots != null) {
      map['printable_dots'] = Variable<int>(printableDots);
    }
    if (!nullToAbsent || charsPerLine != null) {
      map['chars_per_line'] = Variable<int>(charsPerLine);
    }
    if (!nullToAbsent || rasterThreshold != null) {
      map['raster_threshold'] = Variable<int>(rasterThreshold);
    }
    if (!nullToAbsent || feedLines != null) {
      map['feed_lines'] = Variable<int>(feedLines);
    }
    map['auto_cut'] = Variable<bool>(autoCut);
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
      printableDots: printableDots == null && nullToAbsent
          ? const Value.absent()
          : Value(printableDots),
      charsPerLine: charsPerLine == null && nullToAbsent
          ? const Value.absent()
          : Value(charsPerLine),
      rasterThreshold: rasterThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(rasterThreshold),
      feedLines: feedLines == null && nullToAbsent
          ? const Value.absent()
          : Value(feedLines),
      autoCut: Value(autoCut),
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
      printableDots: serializer.fromJson<int?>(json['printableDots']),
      charsPerLine: serializer.fromJson<int?>(json['charsPerLine']),
      rasterThreshold: serializer.fromJson<int?>(json['rasterThreshold']),
      feedLines: serializer.fromJson<int?>(json['feedLines']),
      autoCut: serializer.fromJson<bool>(json['autoCut']),
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
      'printableDots': serializer.toJson<int?>(printableDots),
      'charsPerLine': serializer.toJson<int?>(charsPerLine),
      'rasterThreshold': serializer.toJson<int?>(rasterThreshold),
      'feedLines': serializer.toJson<int?>(feedLines),
      'autoCut': serializer.toJson<bool>(autoCut),
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
    Value<int?> printableDots = const Value.absent(),
    Value<int?> charsPerLine = const Value.absent(),
    Value<int?> rasterThreshold = const Value.absent(),
    Value<int?> feedLines = const Value.absent(),
    bool? autoCut,
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
    printableDots: printableDots.present
        ? printableDots.value
        : this.printableDots,
    charsPerLine: charsPerLine.present ? charsPerLine.value : this.charsPerLine,
    rasterThreshold: rasterThreshold.present
        ? rasterThreshold.value
        : this.rasterThreshold,
    feedLines: feedLines.present ? feedLines.value : this.feedLines,
    autoCut: autoCut ?? this.autoCut,
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
      printableDots: data.printableDots.present
          ? data.printableDots.value
          : this.printableDots,
      charsPerLine: data.charsPerLine.present
          ? data.charsPerLine.value
          : this.charsPerLine,
      rasterThreshold: data.rasterThreshold.present
          ? data.rasterThreshold.value
          : this.rasterThreshold,
      feedLines: data.feedLines.present ? data.feedLines.value : this.feedLines,
      autoCut: data.autoCut.present ? data.autoCut.value : this.autoCut,
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
          ..write('printableDots: $printableDots, ')
          ..write('charsPerLine: $charsPerLine, ')
          ..write('rasterThreshold: $rasterThreshold, ')
          ..write('feedLines: $feedLines, ')
          ..write('autoCut: $autoCut, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
    printableDots,
    charsPerLine,
    rasterThreshold,
    feedLines,
    autoCut,
    createdAt,
    updatedAt,
  ]);
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
          other.printableDots == this.printableDots &&
          other.charsPerLine == this.charsPerLine &&
          other.rasterThreshold == this.rasterThreshold &&
          other.feedLines == this.feedLines &&
          other.autoCut == this.autoCut &&
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
  final Value<int?> printableDots;
  final Value<int?> charsPerLine;
  final Value<int?> rasterThreshold;
  final Value<int?> feedLines;
  final Value<bool> autoCut;
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
    this.printableDots = const Value.absent(),
    this.charsPerLine = const Value.absent(),
    this.rasterThreshold = const Value.absent(),
    this.feedLines = const Value.absent(),
    this.autoCut = const Value.absent(),
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
    this.printableDots = const Value.absent(),
    this.charsPerLine = const Value.absent(),
    this.rasterThreshold = const Value.absent(),
    this.feedLines = const Value.absent(),
    this.autoCut = const Value.absent(),
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
    Expression<int>? printableDots,
    Expression<int>? charsPerLine,
    Expression<int>? rasterThreshold,
    Expression<int>? feedLines,
    Expression<bool>? autoCut,
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
      if (printableDots != null) 'printable_dots': printableDots,
      if (charsPerLine != null) 'chars_per_line': charsPerLine,
      if (rasterThreshold != null) 'raster_threshold': rasterThreshold,
      if (feedLines != null) 'feed_lines': feedLines,
      if (autoCut != null) 'auto_cut': autoCut,
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
    Value<int?>? printableDots,
    Value<int?>? charsPerLine,
    Value<int?>? rasterThreshold,
    Value<int?>? feedLines,
    Value<bool>? autoCut,
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
      printableDots: printableDots ?? this.printableDots,
      charsPerLine: charsPerLine ?? this.charsPerLine,
      rasterThreshold: rasterThreshold ?? this.rasterThreshold,
      feedLines: feedLines ?? this.feedLines,
      autoCut: autoCut ?? this.autoCut,
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
    if (printableDots.present) {
      map['printable_dots'] = Variable<int>(printableDots.value);
    }
    if (charsPerLine.present) {
      map['chars_per_line'] = Variable<int>(charsPerLine.value);
    }
    if (rasterThreshold.present) {
      map['raster_threshold'] = Variable<int>(rasterThreshold.value);
    }
    if (feedLines.present) {
      map['feed_lines'] = Variable<int>(feedLines.value);
    }
    if (autoCut.present) {
      map['auto_cut'] = Variable<bool>(autoCut.value);
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
          ..write('printableDots: $printableDots, ')
          ..write('charsPerLine: $charsPerLine, ')
          ..write('rasterThreshold: $rasterThreshold, ')
          ..write('feedLines: $feedLines, ')
          ..write('autoCut: $autoCut, ')
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

class $TaxProfilesTable extends TaxProfiles
    with TableInfo<$TaxProfilesTable, TaxProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaxProfilesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rateBpMeta = const VerificationMeta('rateBp');
  @override
  late final GeneratedColumn<int> rateBp = GeneratedColumn<int>(
    'rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isInclusiveMeta = const VerificationMeta(
    'isInclusive',
  );
  @override
  late final GeneratedColumn<bool> isInclusive = GeneratedColumn<bool>(
    'is_inclusive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_inclusive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _splitModeMeta = const VerificationMeta(
    'splitMode',
  );
  @override
  late final GeneratedColumn<String> splitMode = GeneratedColumn<String>(
    'split_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    rateBp,
    isInclusive,
    splitMode,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tax_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaxProfileRow> instance, {
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
    if (data.containsKey('rate_bp')) {
      context.handle(
        _rateBpMeta,
        rateBp.isAcceptableOrUnknown(data['rate_bp']!, _rateBpMeta),
      );
    } else if (isInserting) {
      context.missing(_rateBpMeta);
    }
    if (data.containsKey('is_inclusive')) {
      context.handle(
        _isInclusiveMeta,
        isInclusive.isAcceptableOrUnknown(
          data['is_inclusive']!,
          _isInclusiveMeta,
        ),
      );
    }
    if (data.containsKey('split_mode')) {
      context.handle(
        _splitModeMeta,
        splitMode.isAcceptableOrUnknown(data['split_mode']!, _splitModeMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  TaxProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaxProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      rateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rate_bp'],
      )!,
      isInclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_inclusive'],
      )!,
      splitMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_mode'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
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
  $TaxProfilesTable createAlias(String alias) {
    return $TaxProfilesTable(attachedDatabase, alias);
  }
}

class TaxProfileRow extends DataClass implements Insertable<TaxProfileRow> {
  final String id;
  final String name;

  /// Rate in basis points: 5% = 500.
  final int rateBp;

  /// True when menu prices already include this tax.
  final bool isInclusive;

  /// `TaxSplitMode.name`: none | cgstSgst | igst.
  final String splitMode;
  final bool isActive;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const TaxProfileRow({
    required this.id,
    required this.name,
    required this.rateBp,
    required this.isInclusive,
    required this.splitMode,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['rate_bp'] = Variable<int>(rateBp);
    map['is_inclusive'] = Variable<bool>(isInclusive);
    map['split_mode'] = Variable<String>(splitMode);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TaxProfilesCompanion toCompanion(bool nullToAbsent) {
    return TaxProfilesCompanion(
      id: Value(id),
      name: Value(name),
      rateBp: Value(rateBp),
      isInclusive: Value(isInclusive),
      splitMode: Value(splitMode),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TaxProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaxProfileRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      rateBp: serializer.fromJson<int>(json['rateBp']),
      isInclusive: serializer.fromJson<bool>(json['isInclusive']),
      splitMode: serializer.fromJson<String>(json['splitMode']),
      isActive: serializer.fromJson<bool>(json['isActive']),
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
      'rateBp': serializer.toJson<int>(rateBp),
      'isInclusive': serializer.toJson<bool>(isInclusive),
      'splitMode': serializer.toJson<String>(splitMode),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  TaxProfileRow copyWith({
    String? id,
    String? name,
    int? rateBp,
    bool? isInclusive,
    String? splitMode,
    bool? isActive,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => TaxProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    rateBp: rateBp ?? this.rateBp,
    isInclusive: isInclusive ?? this.isInclusive,
    splitMode: splitMode ?? this.splitMode,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TaxProfileRow copyWithCompanion(TaxProfilesCompanion data) {
    return TaxProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      rateBp: data.rateBp.present ? data.rateBp.value : this.rateBp,
      isInclusive: data.isInclusive.present
          ? data.isInclusive.value
          : this.isInclusive,
      splitMode: data.splitMode.present ? data.splitMode.value : this.splitMode,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaxProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rateBp: $rateBp, ')
          ..write('isInclusive: $isInclusive, ')
          ..write('splitMode: $splitMode, ')
          ..write('isActive: $isActive, ')
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
    rateBp,
    isInclusive,
    splitMode,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaxProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.rateBp == this.rateBp &&
          other.isInclusive == this.isInclusive &&
          other.splitMode == this.splitMode &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TaxProfilesCompanion extends UpdateCompanion<TaxProfileRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> rateBp;
  final Value<bool> isInclusive;
  final Value<String> splitMode;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TaxProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rateBp = const Value.absent(),
    this.isInclusive = const Value.absent(),
    this.splitMode = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaxProfilesCompanion.insert({
    required String id,
    required String name,
    required int rateBp,
    this.isInclusive = const Value.absent(),
    this.splitMode = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       rateBp = Value(rateBp),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaxProfileRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rateBp,
    Expression<bool>? isInclusive,
    Expression<String>? splitMode,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rateBp != null) 'rate_bp': rateBp,
      if (isInclusive != null) 'is_inclusive': isInclusive,
      if (splitMode != null) 'split_mode': splitMode,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaxProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? rateBp,
    Value<bool>? isInclusive,
    Value<String>? splitMode,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return TaxProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rateBp: rateBp ?? this.rateBp,
      isInclusive: isInclusive ?? this.isInclusive,
      splitMode: splitMode ?? this.splitMode,
      isActive: isActive ?? this.isActive,
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
    if (rateBp.present) {
      map['rate_bp'] = Variable<int>(rateBp.value);
    }
    if (isInclusive.present) {
      map['is_inclusive'] = Variable<bool>(isInclusive.value);
    }
    if (splitMode.present) {
      map['split_mode'] = Variable<String>(splitMode.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('TaxProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rateBp: $rateBp, ')
          ..write('isInclusive: $isInclusive, ')
          ..write('splitMode: $splitMode, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KitchenStationsTable extends KitchenStations
    with TableInfo<$KitchenStationsTable, KitchenStationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KitchenStationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kitchen_stations';
  @override
  VerificationContext validateIntegrity(
    Insertable<KitchenStationRow> instance, {
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
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  KitchenStationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KitchenStationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
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
  $KitchenStationsTable createAlias(String alias) {
    return $KitchenStationsTable(attachedDatabase, alias);
  }
}

class KitchenStationRow extends DataClass
    implements Insertable<KitchenStationRow> {
  final String id;
  final String name;
  final bool isActive;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const KitchenStationRow({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  KitchenStationsCompanion toCompanion(bool nullToAbsent) {
    return KitchenStationsCompanion(
      id: Value(id),
      name: Value(name),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory KitchenStationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KitchenStationRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['isActive']),
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
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  KitchenStationRow copyWith({
    String? id,
    String? name,
    bool? isActive,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => KitchenStationRow(
    id: id ?? this.id,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  KitchenStationRow copyWithCompanion(KitchenStationsCompanion data) {
    return KitchenStationRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KitchenStationRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, isActive, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KitchenStationRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class KitchenStationsCompanion extends UpdateCompanion<KitchenStationRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const KitchenStationsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KitchenStationsCompanion.insert({
    required String id,
    required String name,
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<KitchenStationRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KitchenStationsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return KitchenStationsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
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
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('KitchenStationsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuCategoriesTable extends MenuCategories
    with TableInfo<$MenuCategoriesTable, MenuCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuCategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES menu_categories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    parentId,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuCategoryRow> instance, {
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
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  MenuCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuCategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
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
  $MenuCategoriesTable createAlias(String alias) {
    return $MenuCategoriesTable(attachedDatabase, alias);
  }
}

class MenuCategoryRow extends DataClass implements Insertable<MenuCategoryRow> {
  final String id;
  final String name;

  /// Set for a subcategory. Only one level of nesting is allowed.
  final String? parentId;
  final bool isActive;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const MenuCategoryRow({
    required this.id,
    required this.name,
    this.parentId,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  MenuCategoriesCompanion toCompanion(bool nullToAbsent) {
    return MenuCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MenuCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuCategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
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
      'parentId': serializer.toJson<String?>(parentId),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  MenuCategoryRow copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    bool? isActive,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => MenuCategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MenuCategoryRow copyWithCompanion(MenuCategoriesCompanion data) {
    return MenuCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuCategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('isActive: $isActive, ')
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
    parentId,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuCategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MenuCategoriesCompanion extends UpdateCompanion<MenuCategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const MenuCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuCategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MenuCategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return MenuCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
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
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('MenuCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MenuItemsTable extends MenuItems
    with TableInfo<$MenuItemsTable, MenuItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MenuItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES menu_categories (id) ON DELETE RESTRICT',
    ),
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _basePricePaiseMeta = const VerificationMeta(
    'basePricePaise',
  );
  @override
  late final GeneratedColumn<int> basePricePaise = GeneratedColumn<int>(
    'base_price_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxProfileIdMeta = const VerificationMeta(
    'taxProfileId',
  );
  @override
  late final GeneratedColumn<String> taxProfileId = GeneratedColumn<String>(
    'tax_profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tax_profiles (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _foodTypeMeta = const VerificationMeta(
    'foodType',
  );
  @override
  late final GeneratedColumn<String> foodType = GeneratedColumn<String>(
    'food_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('veg'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _availableDineInMeta = const VerificationMeta(
    'availableDineIn',
  );
  @override
  late final GeneratedColumn<bool> availableDineIn = GeneratedColumn<bool>(
    'available_dine_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("available_dine_in" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _availableTakeawayMeta = const VerificationMeta(
    'availableTakeaway',
  );
  @override
  late final GeneratedColumn<bool> availableTakeaway = GeneratedColumn<bool>(
    'available_takeaway',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("available_takeaway" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _stationIdMeta = const VerificationMeta(
    'stationId',
  );
  @override
  late final GeneratedColumn<String> stationId = GeneratedColumn<String>(
    'station_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kitchen_stations (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _prepMinutesMeta = const VerificationMeta(
    'prepMinutes',
  );
  @override
  late final GeneratedColumn<int> prepMinutes = GeneratedColumn<int>(
    'prep_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
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
    categoryId,
    name,
    description,
    sku,
    basePricePaise,
    taxProfileId,
    foodType,
    isActive,
    availableDineIn,
    availableTakeaway,
    stationId,
    isFavorite,
    prepMinutes,
    imagePath,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'menu_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<MenuItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('base_price_paise')) {
      context.handle(
        _basePricePaiseMeta,
        basePricePaise.isAcceptableOrUnknown(
          data['base_price_paise']!,
          _basePricePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_basePricePaiseMeta);
    }
    if (data.containsKey('tax_profile_id')) {
      context.handle(
        _taxProfileIdMeta,
        taxProfileId.isAcceptableOrUnknown(
          data['tax_profile_id']!,
          _taxProfileIdMeta,
        ),
      );
    }
    if (data.containsKey('food_type')) {
      context.handle(
        _foodTypeMeta,
        foodType.isAcceptableOrUnknown(data['food_type']!, _foodTypeMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('available_dine_in')) {
      context.handle(
        _availableDineInMeta,
        availableDineIn.isAcceptableOrUnknown(
          data['available_dine_in']!,
          _availableDineInMeta,
        ),
      );
    }
    if (data.containsKey('available_takeaway')) {
      context.handle(
        _availableTakeawayMeta,
        availableTakeaway.isAcceptableOrUnknown(
          data['available_takeaway']!,
          _availableTakeawayMeta,
        ),
      );
    }
    if (data.containsKey('station_id')) {
      context.handle(
        _stationIdMeta,
        stationId.isAcceptableOrUnknown(data['station_id']!, _stationIdMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('prep_minutes')) {
      context.handle(
        _prepMinutesMeta,
        prepMinutes.isAcceptableOrUnknown(
          data['prep_minutes']!,
          _prepMinutesMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
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
  MenuItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MenuItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      basePricePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_price_paise'],
      )!,
      taxProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_profile_id'],
      ),
      foodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_type'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      availableDineIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}available_dine_in'],
      )!,
      availableTakeaway: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}available_takeaway'],
      )!,
      stationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_id'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      prepMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_minutes'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
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
  $MenuItemsTable createAlias(String alias) {
    return $MenuItemsTable(attachedDatabase, alias);
  }
}

class MenuItemRow extends DataClass implements Insertable<MenuItemRow> {
  final String id;
  final String categoryId;
  final String name;
  final String description;

  /// Short code, unique among items when set (checked in the repository).
  final String? sku;
  final int basePricePaise;

  /// Null means the item is not taxed.
  final String? taxProfileId;

  /// `FoodType.name`: veg | nonVeg | egg | other.
  final String foodType;
  final bool isActive;
  final bool availableDineIn;
  final bool availableTakeaway;
  final String? stationId;
  final bool isFavorite;
  final int? prepMinutes;
  final String? imagePath;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const MenuItemRow({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.sku,
    required this.basePricePaise,
    this.taxProfileId,
    required this.foodType,
    required this.isActive,
    required this.availableDineIn,
    required this.availableTakeaway,
    this.stationId,
    required this.isFavorite,
    this.prepMinutes,
    this.imagePath,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['base_price_paise'] = Variable<int>(basePricePaise);
    if (!nullToAbsent || taxProfileId != null) {
      map['tax_profile_id'] = Variable<String>(taxProfileId);
    }
    map['food_type'] = Variable<String>(foodType);
    map['is_active'] = Variable<bool>(isActive);
    map['available_dine_in'] = Variable<bool>(availableDineIn);
    map['available_takeaway'] = Variable<bool>(availableTakeaway);
    if (!nullToAbsent || stationId != null) {
      map['station_id'] = Variable<String>(stationId);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || prepMinutes != null) {
      map['prep_minutes'] = Variable<int>(prepMinutes);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  MenuItemsCompanion toCompanion(bool nullToAbsent) {
    return MenuItemsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      description: Value(description),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      basePricePaise: Value(basePricePaise),
      taxProfileId: taxProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(taxProfileId),
      foodType: Value(foodType),
      isActive: Value(isActive),
      availableDineIn: Value(availableDineIn),
      availableTakeaway: Value(availableTakeaway),
      stationId: stationId == null && nullToAbsent
          ? const Value.absent()
          : Value(stationId),
      isFavorite: Value(isFavorite),
      prepMinutes: prepMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(prepMinutes),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MenuItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MenuItemRow(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      sku: serializer.fromJson<String?>(json['sku']),
      basePricePaise: serializer.fromJson<int>(json['basePricePaise']),
      taxProfileId: serializer.fromJson<String?>(json['taxProfileId']),
      foodType: serializer.fromJson<String>(json['foodType']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      availableDineIn: serializer.fromJson<bool>(json['availableDineIn']),
      availableTakeaway: serializer.fromJson<bool>(json['availableTakeaway']),
      stationId: serializer.fromJson<String?>(json['stationId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      prepMinutes: serializer.fromJson<int?>(json['prepMinutes']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
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
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'sku': serializer.toJson<String?>(sku),
      'basePricePaise': serializer.toJson<int>(basePricePaise),
      'taxProfileId': serializer.toJson<String?>(taxProfileId),
      'foodType': serializer.toJson<String>(foodType),
      'isActive': serializer.toJson<bool>(isActive),
      'availableDineIn': serializer.toJson<bool>(availableDineIn),
      'availableTakeaway': serializer.toJson<bool>(availableTakeaway),
      'stationId': serializer.toJson<String?>(stationId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'prepMinutes': serializer.toJson<int?>(prepMinutes),
      'imagePath': serializer.toJson<String?>(imagePath),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  MenuItemRow copyWith({
    String? id,
    String? categoryId,
    String? name,
    String? description,
    Value<String?> sku = const Value.absent(),
    int? basePricePaise,
    Value<String?> taxProfileId = const Value.absent(),
    String? foodType,
    bool? isActive,
    bool? availableDineIn,
    bool? availableTakeaway,
    Value<String?> stationId = const Value.absent(),
    bool? isFavorite,
    Value<int?> prepMinutes = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => MenuItemRow(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description ?? this.description,
    sku: sku.present ? sku.value : this.sku,
    basePricePaise: basePricePaise ?? this.basePricePaise,
    taxProfileId: taxProfileId.present ? taxProfileId.value : this.taxProfileId,
    foodType: foodType ?? this.foodType,
    isActive: isActive ?? this.isActive,
    availableDineIn: availableDineIn ?? this.availableDineIn,
    availableTakeaway: availableTakeaway ?? this.availableTakeaway,
    stationId: stationId.present ? stationId.value : this.stationId,
    isFavorite: isFavorite ?? this.isFavorite,
    prepMinutes: prepMinutes.present ? prepMinutes.value : this.prepMinutes,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MenuItemRow copyWithCompanion(MenuItemsCompanion data) {
    return MenuItemRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      sku: data.sku.present ? data.sku.value : this.sku,
      basePricePaise: data.basePricePaise.present
          ? data.basePricePaise.value
          : this.basePricePaise,
      taxProfileId: data.taxProfileId.present
          ? data.taxProfileId.value
          : this.taxProfileId,
      foodType: data.foodType.present ? data.foodType.value : this.foodType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      availableDineIn: data.availableDineIn.present
          ? data.availableDineIn.value
          : this.availableDineIn,
      availableTakeaway: data.availableTakeaway.present
          ? data.availableTakeaway.value
          : this.availableTakeaway,
      stationId: data.stationId.present ? data.stationId.value : this.stationId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      prepMinutes: data.prepMinutes.present
          ? data.prepMinutes.value
          : this.prepMinutes,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MenuItemRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('sku: $sku, ')
          ..write('basePricePaise: $basePricePaise, ')
          ..write('taxProfileId: $taxProfileId, ')
          ..write('foodType: $foodType, ')
          ..write('isActive: $isActive, ')
          ..write('availableDineIn: $availableDineIn, ')
          ..write('availableTakeaway: $availableTakeaway, ')
          ..write('stationId: $stationId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('imagePath: $imagePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    name,
    description,
    sku,
    basePricePaise,
    taxProfileId,
    foodType,
    isActive,
    availableDineIn,
    availableTakeaway,
    stationId,
    isFavorite,
    prepMinutes,
    imagePath,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MenuItemRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.description == this.description &&
          other.sku == this.sku &&
          other.basePricePaise == this.basePricePaise &&
          other.taxProfileId == this.taxProfileId &&
          other.foodType == this.foodType &&
          other.isActive == this.isActive &&
          other.availableDineIn == this.availableDineIn &&
          other.availableTakeaway == this.availableTakeaway &&
          other.stationId == this.stationId &&
          other.isFavorite == this.isFavorite &&
          other.prepMinutes == this.prepMinutes &&
          other.imagePath == this.imagePath &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MenuItemsCompanion extends UpdateCompanion<MenuItemRow> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<String> description;
  final Value<String?> sku;
  final Value<int> basePricePaise;
  final Value<String?> taxProfileId;
  final Value<String> foodType;
  final Value<bool> isActive;
  final Value<bool> availableDineIn;
  final Value<bool> availableTakeaway;
  final Value<String?> stationId;
  final Value<bool> isFavorite;
  final Value<int?> prepMinutes;
  final Value<String?> imagePath;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const MenuItemsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.sku = const Value.absent(),
    this.basePricePaise = const Value.absent(),
    this.taxProfileId = const Value.absent(),
    this.foodType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.availableDineIn = const Value.absent(),
    this.availableTakeaway = const Value.absent(),
    this.stationId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MenuItemsCompanion.insert({
    required String id,
    required String categoryId,
    required String name,
    this.description = const Value.absent(),
    this.sku = const Value.absent(),
    required int basePricePaise,
    this.taxProfileId = const Value.absent(),
    this.foodType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.availableDineIn = const Value.absent(),
    this.availableTakeaway = const Value.absent(),
    this.stationId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       name = Value(name),
       basePricePaise = Value(basePricePaise),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<MenuItemRow> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? sku,
    Expression<int>? basePricePaise,
    Expression<String>? taxProfileId,
    Expression<String>? foodType,
    Expression<bool>? isActive,
    Expression<bool>? availableDineIn,
    Expression<bool>? availableTakeaway,
    Expression<String>? stationId,
    Expression<bool>? isFavorite,
    Expression<int>? prepMinutes,
    Expression<String>? imagePath,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (sku != null) 'sku': sku,
      if (basePricePaise != null) 'base_price_paise': basePricePaise,
      if (taxProfileId != null) 'tax_profile_id': taxProfileId,
      if (foodType != null) 'food_type': foodType,
      if (isActive != null) 'is_active': isActive,
      if (availableDineIn != null) 'available_dine_in': availableDineIn,
      if (availableTakeaway != null) 'available_takeaway': availableTakeaway,
      if (stationId != null) 'station_id': stationId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (prepMinutes != null) 'prep_minutes': prepMinutes,
      if (imagePath != null) 'image_path': imagePath,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MenuItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String>? name,
    Value<String>? description,
    Value<String?>? sku,
    Value<int>? basePricePaise,
    Value<String?>? taxProfileId,
    Value<String>? foodType,
    Value<bool>? isActive,
    Value<bool>? availableDineIn,
    Value<bool>? availableTakeaway,
    Value<String?>? stationId,
    Value<bool>? isFavorite,
    Value<int?>? prepMinutes,
    Value<String?>? imagePath,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return MenuItemsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      basePricePaise: basePricePaise ?? this.basePricePaise,
      taxProfileId: taxProfileId ?? this.taxProfileId,
      foodType: foodType ?? this.foodType,
      isActive: isActive ?? this.isActive,
      availableDineIn: availableDineIn ?? this.availableDineIn,
      availableTakeaway: availableTakeaway ?? this.availableTakeaway,
      stationId: stationId ?? this.stationId,
      isFavorite: isFavorite ?? this.isFavorite,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      imagePath: imagePath ?? this.imagePath,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (basePricePaise.present) {
      map['base_price_paise'] = Variable<int>(basePricePaise.value);
    }
    if (taxProfileId.present) {
      map['tax_profile_id'] = Variable<String>(taxProfileId.value);
    }
    if (foodType.present) {
      map['food_type'] = Variable<String>(foodType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (availableDineIn.present) {
      map['available_dine_in'] = Variable<bool>(availableDineIn.value);
    }
    if (availableTakeaway.present) {
      map['available_takeaway'] = Variable<bool>(availableTakeaway.value);
    }
    if (stationId.present) {
      map['station_id'] = Variable<String>(stationId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (prepMinutes.present) {
      map['prep_minutes'] = Variable<int>(prepMinutes.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
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
    return (StringBuffer('MenuItemsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('sku: $sku, ')
          ..write('basePricePaise: $basePricePaise, ')
          ..write('taxProfileId: $taxProfileId, ')
          ..write('foodType: $foodType, ')
          ..write('isActive: $isActive, ')
          ..write('availableDineIn: $availableDineIn, ')
          ..write('availableTakeaway: $availableTakeaway, ')
          ..write('stationId: $stationId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('imagePath: $imagePath, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OptionGroupsTable extends OptionGroups
    with TableInfo<$OptionGroupsTable, OptionGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OptionGroupsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minSelectMeta = const VerificationMeta(
    'minSelect',
  );
  @override
  late final GeneratedColumn<int> minSelect = GeneratedColumn<int>(
    'min_select',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxSelectMeta = const VerificationMeta(
    'maxSelect',
  );
  @override
  late final GeneratedColumn<int> maxSelect = GeneratedColumn<int>(
    'max_select',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    kind,
    minSelect,
    maxSelect,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'option_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<OptionGroupRow> instance, {
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('min_select')) {
      context.handle(
        _minSelectMeta,
        minSelect.isAcceptableOrUnknown(data['min_select']!, _minSelectMeta),
      );
    }
    if (data.containsKey('max_select')) {
      context.handle(
        _maxSelectMeta,
        maxSelect.isAcceptableOrUnknown(data['max_select']!, _maxSelectMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  OptionGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OptionGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      minSelect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_select'],
      )!,
      maxSelect: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_select'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
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
  $OptionGroupsTable createAlias(String alias) {
    return $OptionGroupsTable(attachedDatabase, alias);
  }
}

class OptionGroupRow extends DataClass implements Insertable<OptionGroupRow> {
  final String id;
  final String name;

  /// `OptionGroupKind.name`: variant | addon.
  final String kind;

  /// 0 = optional. 1 or more = that many choices are required.
  final int minSelect;

  /// 1 = single-select. Must be >= max(1, minSelect).
  final int maxSelect;
  final bool isActive;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const OptionGroupRow({
    required this.id,
    required this.name,
    required this.kind,
    required this.minSelect,
    required this.maxSelect,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['min_select'] = Variable<int>(minSelect);
    map['max_select'] = Variable<int>(maxSelect);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  OptionGroupsCompanion toCompanion(bool nullToAbsent) {
    return OptionGroupsCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      minSelect: Value(minSelect),
      maxSelect: Value(maxSelect),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OptionGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OptionGroupRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      minSelect: serializer.fromJson<int>(json['minSelect']),
      maxSelect: serializer.fromJson<int>(json['maxSelect']),
      isActive: serializer.fromJson<bool>(json['isActive']),
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
      'kind': serializer.toJson<String>(kind),
      'minSelect': serializer.toJson<int>(minSelect),
      'maxSelect': serializer.toJson<int>(maxSelect),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  OptionGroupRow copyWith({
    String? id,
    String? name,
    String? kind,
    int? minSelect,
    int? maxSelect,
    bool? isActive,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => OptionGroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    minSelect: minSelect ?? this.minSelect,
    maxSelect: maxSelect ?? this.maxSelect,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OptionGroupRow copyWithCompanion(OptionGroupsCompanion data) {
    return OptionGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      minSelect: data.minSelect.present ? data.minSelect.value : this.minSelect,
      maxSelect: data.maxSelect.present ? data.maxSelect.value : this.maxSelect,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OptionGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('minSelect: $minSelect, ')
          ..write('maxSelect: $maxSelect, ')
          ..write('isActive: $isActive, ')
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
    kind,
    minSelect,
    maxSelect,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OptionGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.minSelect == this.minSelect &&
          other.maxSelect == this.maxSelect &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OptionGroupsCompanion extends UpdateCompanion<OptionGroupRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<int> minSelect;
  final Value<int> maxSelect;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const OptionGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.minSelect = const Value.absent(),
    this.maxSelect = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OptionGroupsCompanion.insert({
    required String id,
    required String name,
    required String kind,
    this.minSelect = const Value.absent(),
    this.maxSelect = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OptionGroupRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<int>? minSelect,
    Expression<int>? maxSelect,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (minSelect != null) 'min_select': minSelect,
      if (maxSelect != null) 'max_select': maxSelect,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OptionGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<int>? minSelect,
    Value<int>? maxSelect,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return OptionGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      minSelect: minSelect ?? this.minSelect,
      maxSelect: maxSelect ?? this.maxSelect,
      isActive: isActive ?? this.isActive,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (minSelect.present) {
      map['min_select'] = Variable<int>(minSelect.value);
    }
    if (maxSelect.present) {
      map['max_select'] = Variable<int>(maxSelect.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('OptionGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('minSelect: $minSelect, ')
          ..write('maxSelect: $maxSelect, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OptionChoicesTable extends OptionChoices
    with TableInfo<$OptionChoicesTable, OptionChoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OptionChoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES option_groups (id) ON DELETE RESTRICT',
    ),
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
  static const VerificationMeta _priceDeltaPaiseMeta = const VerificationMeta(
    'priceDeltaPaise',
  );
  @override
  late final GeneratedColumn<int> priceDeltaPaise = GeneratedColumn<int>(
    'price_delta_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    groupId,
    name,
    priceDeltaPaise,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'option_choices';
  @override
  VerificationContext validateIntegrity(
    Insertable<OptionChoiceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_delta_paise')) {
      context.handle(
        _priceDeltaPaiseMeta,
        priceDeltaPaise.isAcceptableOrUnknown(
          data['price_delta_paise']!,
          _priceDeltaPaiseMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  OptionChoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OptionChoiceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      priceDeltaPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_delta_paise'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
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
  $OptionChoicesTable createAlias(String alias) {
    return $OptionChoicesTable(attachedDatabase, alias);
  }
}

class OptionChoiceRow extends DataClass implements Insertable<OptionChoiceRow> {
  final String id;
  final String groupId;
  final String name;

  /// Added to the item's base price when chosen (may be 0).
  final int priceDeltaPaise;
  final bool isActive;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const OptionChoiceRow({
    required this.id,
    required this.groupId,
    required this.name,
    required this.priceDeltaPaise,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    map['price_delta_paise'] = Variable<int>(priceDeltaPaise);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  OptionChoicesCompanion toCompanion(bool nullToAbsent) {
    return OptionChoicesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      priceDeltaPaise: Value(priceDeltaPaise),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OptionChoiceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OptionChoiceRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      priceDeltaPaise: serializer.fromJson<int>(json['priceDeltaPaise']),
      isActive: serializer.fromJson<bool>(json['isActive']),
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
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'priceDeltaPaise': serializer.toJson<int>(priceDeltaPaise),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  OptionChoiceRow copyWith({
    String? id,
    String? groupId,
    String? name,
    int? priceDeltaPaise,
    bool? isActive,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => OptionChoiceRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    priceDeltaPaise: priceDeltaPaise ?? this.priceDeltaPaise,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OptionChoiceRow copyWithCompanion(OptionChoicesCompanion data) {
    return OptionChoiceRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      priceDeltaPaise: data.priceDeltaPaise.present
          ? data.priceDeltaPaise.value
          : this.priceDeltaPaise,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OptionChoiceRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('priceDeltaPaise: $priceDeltaPaise, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    name,
    priceDeltaPaise,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OptionChoiceRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.priceDeltaPaise == this.priceDeltaPaise &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OptionChoicesCompanion extends UpdateCompanion<OptionChoiceRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> name;
  final Value<int> priceDeltaPaise;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const OptionChoicesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.priceDeltaPaise = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OptionChoicesCompanion.insert({
    required String id,
    required String groupId,
    required String name,
    this.priceDeltaPaise = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OptionChoiceRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<int>? priceDeltaPaise,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (priceDeltaPaise != null) 'price_delta_paise': priceDeltaPaise,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OptionChoicesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? name,
    Value<int>? priceDeltaPaise,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return OptionChoicesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      priceDeltaPaise: priceDeltaPaise ?? this.priceDeltaPaise,
      isActive: isActive ?? this.isActive,
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
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (priceDeltaPaise.present) {
      map['price_delta_paise'] = Variable<int>(priceDeltaPaise.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('OptionChoicesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('priceDeltaPaise: $priceDeltaPaise, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemOptionGroupsTable extends ItemOptionGroups
    with TableInfo<$ItemOptionGroupsTable, ItemOptionGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemOptionGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES menu_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES option_groups (id) ON DELETE RESTRICT',
    ),
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
  @override
  List<GeneratedColumn> get $columns => [itemId, groupId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_option_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemOptionGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, groupId};
  @override
  ItemOptionGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemOptionGroupRow(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ItemOptionGroupsTable createAlias(String alias) {
    return $ItemOptionGroupsTable(attachedDatabase, alias);
  }
}

class ItemOptionGroupRow extends DataClass
    implements Insertable<ItemOptionGroupRow> {
  final String itemId;
  final String groupId;
  final int sortOrder;
  const ItemOptionGroupRow({
    required this.itemId,
    required this.groupId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['group_id'] = Variable<String>(groupId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ItemOptionGroupsCompanion toCompanion(bool nullToAbsent) {
    return ItemOptionGroupsCompanion(
      itemId: Value(itemId),
      groupId: Value(groupId),
      sortOrder: Value(sortOrder),
    );
  }

  factory ItemOptionGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemOptionGroupRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'groupId': serializer.toJson<String>(groupId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ItemOptionGroupRow copyWith({
    String? itemId,
    String? groupId,
    int? sortOrder,
  }) => ItemOptionGroupRow(
    itemId: itemId ?? this.itemId,
    groupId: groupId ?? this.groupId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ItemOptionGroupRow copyWithCompanion(ItemOptionGroupsCompanion data) {
    return ItemOptionGroupRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemOptionGroupRow(')
          ..write('itemId: $itemId, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(itemId, groupId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemOptionGroupRow &&
          other.itemId == this.itemId &&
          other.groupId == this.groupId &&
          other.sortOrder == this.sortOrder);
}

class ItemOptionGroupsCompanion extends UpdateCompanion<ItemOptionGroupRow> {
  final Value<String> itemId;
  final Value<String> groupId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ItemOptionGroupsCompanion({
    this.itemId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemOptionGroupsCompanion.insert({
    required String itemId,
    required String groupId,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       groupId = Value(groupId);
  static Insertable<ItemOptionGroupRow> custom({
    Expression<String>? itemId,
    Expression<String>? groupId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (groupId != null) 'group_id': groupId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemOptionGroupsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? groupId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ItemOptionGroupsCompanion(
      itemId: itemId ?? this.itemId,
      groupId: groupId ?? this.groupId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemOptionGroupsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('groupId: $groupId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DiningAreasTable extends DiningAreas
    with TableInfo<$DiningAreasTable, DiningAreaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DiningAreasTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dining_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<DiningAreaRow> instance, {
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
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  DiningAreaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DiningAreaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
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
  $DiningAreasTable createAlias(String alias) {
    return $DiningAreasTable(attachedDatabase, alias);
  }
}

class DiningAreaRow extends DataClass implements Insertable<DiningAreaRow> {
  final String id;
  final String name;
  final bool isActive;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const DiningAreaRow({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DiningAreasCompanion toCompanion(bool nullToAbsent) {
    return DiningAreasCompanion(
      id: Value(id),
      name: Value(name),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DiningAreaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DiningAreaRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['isActive']),
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
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DiningAreaRow copyWith({
    String? id,
    String? name,
    bool? isActive,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => DiningAreaRow(
    id: id ?? this.id,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DiningAreaRow copyWithCompanion(DiningAreasCompanion data) {
    return DiningAreaRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DiningAreaRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, isActive, sortOrder, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DiningAreaRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DiningAreasCompanion extends UpdateCompanion<DiningAreaRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DiningAreasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DiningAreasCompanion.insert({
    required String id,
    required String name,
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DiningAreaRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DiningAreasCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DiningAreasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
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
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('DiningAreasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RestaurantTablesTable extends RestaurantTables
    with TableInfo<$RestaurantTablesTable, RestaurantTableRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RestaurantTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaIdMeta = const VerificationMeta('areaId');
  @override
  late final GeneratedColumn<String> areaId = GeneratedColumn<String>(
    'area_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dining_areas (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seatsMeta = const VerificationMeta('seats');
  @override
  late final GeneratedColumn<int> seats = GeneratedColumn<int>(
    'seats',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
    areaId,
    label,
    seats,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'restaurant_tables';
  @override
  VerificationContext validateIntegrity(
    Insertable<RestaurantTableRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('area_id')) {
      context.handle(
        _areaIdMeta,
        areaId.isAcceptableOrUnknown(data['area_id']!, _areaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_areaIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('seats')) {
      context.handle(
        _seatsMeta,
        seats.isAcceptableOrUnknown(data['seats']!, _seatsMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
  RestaurantTableRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RestaurantTableRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      areaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      seats: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seats'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
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
  $RestaurantTablesTable createAlias(String alias) {
    return $RestaurantTablesTable(attachedDatabase, alias);
  }
}

class RestaurantTableRow extends DataClass
    implements Insertable<RestaurantTableRow> {
  final String id;
  final String areaId;
  final String label;
  final int? seats;
  final bool isActive;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const RestaurantTableRow({
    required this.id,
    required this.areaId,
    required this.label,
    this.seats,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['area_id'] = Variable<String>(areaId);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || seats != null) {
      map['seats'] = Variable<int>(seats);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RestaurantTablesCompanion toCompanion(bool nullToAbsent) {
    return RestaurantTablesCompanion(
      id: Value(id),
      areaId: Value(areaId),
      label: Value(label),
      seats: seats == null && nullToAbsent
          ? const Value.absent()
          : Value(seats),
      isActive: Value(isActive),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RestaurantTableRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RestaurantTableRow(
      id: serializer.fromJson<String>(json['id']),
      areaId: serializer.fromJson<String>(json['areaId']),
      label: serializer.fromJson<String>(json['label']),
      seats: serializer.fromJson<int?>(json['seats']),
      isActive: serializer.fromJson<bool>(json['isActive']),
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
      'areaId': serializer.toJson<String>(areaId),
      'label': serializer.toJson<String>(label),
      'seats': serializer.toJson<int?>(seats),
      'isActive': serializer.toJson<bool>(isActive),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  RestaurantTableRow copyWith({
    String? id,
    String? areaId,
    String? label,
    Value<int?> seats = const Value.absent(),
    bool? isActive,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => RestaurantTableRow(
    id: id ?? this.id,
    areaId: areaId ?? this.areaId,
    label: label ?? this.label,
    seats: seats.present ? seats.value : this.seats,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RestaurantTableRow copyWithCompanion(RestaurantTablesCompanion data) {
    return RestaurantTableRow(
      id: data.id.present ? data.id.value : this.id,
      areaId: data.areaId.present ? data.areaId.value : this.areaId,
      label: data.label.present ? data.label.value : this.label,
      seats: data.seats.present ? data.seats.value : this.seats,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RestaurantTableRow(')
          ..write('id: $id, ')
          ..write('areaId: $areaId, ')
          ..write('label: $label, ')
          ..write('seats: $seats, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    areaId,
    label,
    seats,
    isActive,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RestaurantTableRow &&
          other.id == this.id &&
          other.areaId == this.areaId &&
          other.label == this.label &&
          other.seats == this.seats &&
          other.isActive == this.isActive &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RestaurantTablesCompanion extends UpdateCompanion<RestaurantTableRow> {
  final Value<String> id;
  final Value<String> areaId;
  final Value<String> label;
  final Value<int?> seats;
  final Value<bool> isActive;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const RestaurantTablesCompanion({
    this.id = const Value.absent(),
    this.areaId = const Value.absent(),
    this.label = const Value.absent(),
    this.seats = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RestaurantTablesCompanion.insert({
    required String id,
    required String areaId,
    required String label,
    this.seats = const Value.absent(),
    this.isActive = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       areaId = Value(areaId),
       label = Value(label),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RestaurantTableRow> custom({
    Expression<String>? id,
    Expression<String>? areaId,
    Expression<String>? label,
    Expression<int>? seats,
    Expression<bool>? isActive,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (areaId != null) 'area_id': areaId,
      if (label != null) 'label': label,
      if (seats != null) 'seats': seats,
      if (isActive != null) 'is_active': isActive,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RestaurantTablesCompanion copyWith({
    Value<String>? id,
    Value<String>? areaId,
    Value<String>? label,
    Value<int?>? seats,
    Value<bool>? isActive,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return RestaurantTablesCompanion(
      id: id ?? this.id,
      areaId: areaId ?? this.areaId,
      label: label ?? this.label,
      seats: seats ?? this.seats,
      isActive: isActive ?? this.isActive,
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
    if (areaId.present) {
      map['area_id'] = Variable<String>(areaId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (seats.present) {
      map['seats'] = Variable<int>(seats.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
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
    return (StringBuffer('RestaurantTablesCompanion(')
          ..write('id: $id, ')
          ..write('areaId: $areaId, ')
          ..write('label: $label, ')
          ..write('seats: $seats, ')
          ..write('isActive: $isActive, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrdersTable extends Orders with TableInfo<$OrdersTable, OrderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderNoMeta = const VerificationMeta(
    'orderNo',
  );
  @override
  late final GeneratedColumn<int> orderNo = GeneratedColumn<int>(
    'order_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessDateMeta = const VerificationMeta(
    'businessDate',
  );
  @override
  late final GeneratedColumn<String> businessDate = GeneratedColumn<String>(
    'business_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderTypeMeta = const VerificationMeta(
    'orderType',
  );
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
    'order_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableIdMeta = const VerificationMeta(
    'tableId',
  );
  @override
  late final GeneratedColumn<String> tableId = GeneratedColumn<String>(
    'table_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES restaurant_tables (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _customerNameMeta = const VerificationMeta(
    'customerName',
  );
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
    'customer_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _customerPhoneMeta = const VerificationMeta(
    'customerPhone',
  );
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
    'customer_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _guestsMeta = const VerificationMeta('guests');
  @override
  late final GeneratedColumn<int> guests = GeneratedColumn<int>(
    'guests',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _staffNameMeta = const VerificationMeta(
    'staffName',
  );
  @override
  late final GeneratedColumn<String> staffName = GeneratedColumn<String>(
    'staff_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _discountKindMeta = const VerificationMeta(
    'discountKind',
  );
  @override
  late final GeneratedColumn<String> discountKind = GeneratedColumn<String>(
    'discount_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<int> discountValue = GeneratedColumn<int>(
    'discount_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountReasonMeta = const VerificationMeta(
    'discountReason',
  );
  @override
  late final GeneratedColumn<String> discountReason = GeneratedColumn<String>(
    'discount_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _cancelReasonMeta = const VerificationMeta(
    'cancelReason',
  );
  @override
  late final GeneratedColumn<String> cancelReason = GeneratedColumn<String>(
    'cancel_reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _clientRequestIdMeta = const VerificationMeta(
    'clientRequestId',
  );
  @override
  late final GeneratedColumn<String> clientRequestId = GeneratedColumn<String>(
    'client_request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<int> closedAt = GeneratedColumn<int>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderNo,
    businessDate,
    orderType,
    tableId,
    customerName,
    customerPhone,
    guests,
    staffId,
    staffName,
    status,
    notes,
    discountKind,
    discountValue,
    discountReason,
    cancelReason,
    clientRequestId,
    createdAt,
    updatedAt,
    closedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('order_no')) {
      context.handle(
        _orderNoMeta,
        orderNo.isAcceptableOrUnknown(data['order_no']!, _orderNoMeta),
      );
    } else if (isInserting) {
      context.missing(_orderNoMeta);
    }
    if (data.containsKey('business_date')) {
      context.handle(
        _businessDateMeta,
        businessDate.isAcceptableOrUnknown(
          data['business_date']!,
          _businessDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_businessDateMeta);
    }
    if (data.containsKey('order_type')) {
      context.handle(
        _orderTypeMeta,
        orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_orderTypeMeta);
    }
    if (data.containsKey('table_id')) {
      context.handle(
        _tableIdMeta,
        tableId.isAcceptableOrUnknown(data['table_id']!, _tableIdMeta),
      );
    }
    if (data.containsKey('customer_name')) {
      context.handle(
        _customerNameMeta,
        customerName.isAcceptableOrUnknown(
          data['customer_name']!,
          _customerNameMeta,
        ),
      );
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
        _customerPhoneMeta,
        customerPhone.isAcceptableOrUnknown(
          data['customer_phone']!,
          _customerPhoneMeta,
        ),
      );
    }
    if (data.containsKey('guests')) {
      context.handle(
        _guestsMeta,
        guests.isAcceptableOrUnknown(data['guests']!, _guestsMeta),
      );
    }
    if (data.containsKey('staff_id')) {
      context.handle(
        _staffIdMeta,
        staffId.isAcceptableOrUnknown(data['staff_id']!, _staffIdMeta),
      );
    }
    if (data.containsKey('staff_name')) {
      context.handle(
        _staffNameMeta,
        staffName.isAcceptableOrUnknown(data['staff_name']!, _staffNameMeta),
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
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('discount_kind')) {
      context.handle(
        _discountKindMeta,
        discountKind.isAcceptableOrUnknown(
          data['discount_kind']!,
          _discountKindMeta,
        ),
      );
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    }
    if (data.containsKey('discount_reason')) {
      context.handle(
        _discountReasonMeta,
        discountReason.isAcceptableOrUnknown(
          data['discount_reason']!,
          _discountReasonMeta,
        ),
      );
    }
    if (data.containsKey('cancel_reason')) {
      context.handle(
        _cancelReasonMeta,
        cancelReason.isAcceptableOrUnknown(
          data['cancel_reason']!,
          _cancelReasonMeta,
        ),
      );
    }
    if (data.containsKey('client_request_id')) {
      context.handle(
        _clientRequestIdMeta,
        clientRequestId.isAcceptableOrUnknown(
          data['client_request_id']!,
          _clientRequestIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRequestIdMeta);
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
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_no'],
      )!,
      businessDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_date'],
      )!,
      orderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_type'],
      )!,
      tableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_id'],
      ),
      customerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_name'],
      )!,
      customerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}customer_phone'],
      )!,
      guests: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}guests'],
      ),
      staffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_id'],
      ),
      staffName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staff_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      discountKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_kind'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_value'],
      )!,
      discountReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discount_reason'],
      )!,
      cancelReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cancel_reason'],
      )!,
      clientRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_request_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closed_at'],
      ),
    );
  }

  @override
  $OrdersTable createAlias(String alias) {
    return $OrdersTable(attachedDatabase, alias);
  }
}

class OrderRow extends DataClass implements Insertable<OrderRow> {
  final String id;

  /// Human number, sequential per business day (1, 2, 3, …).
  final int orderNo;

  /// Local business date `yyyy-MM-dd` (see the business-day start setting).
  final String businessDate;

  /// `OrderType.name`: dineIn | takeaway | delivery.
  final String orderType;
  final String? tableId;
  final String customerName;
  final String customerPhone;
  final int? guests;
  final String? staffId;
  final String staffName;

  /// `OrderStatus.name`.
  final String status;
  final String notes;

  /// `DiscountKind.name`: none | percent | amount.
  final String discountKind;

  /// Basis points for percent, paise for amount.
  final int discountValue;
  final String discountReason;
  final String cancelReason;

  /// Set by the device that created the order; a repeated create with the
  /// same id returns the existing order instead of making a duplicate.
  final String clientRequestId;
  final int createdAt;
  final int updatedAt;
  final int? closedAt;
  const OrderRow({
    required this.id,
    required this.orderNo,
    required this.businessDate,
    required this.orderType,
    this.tableId,
    required this.customerName,
    required this.customerPhone,
    this.guests,
    this.staffId,
    required this.staffName,
    required this.status,
    required this.notes,
    required this.discountKind,
    required this.discountValue,
    required this.discountReason,
    required this.cancelReason,
    required this.clientRequestId,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_no'] = Variable<int>(orderNo);
    map['business_date'] = Variable<String>(businessDate);
    map['order_type'] = Variable<String>(orderType);
    if (!nullToAbsent || tableId != null) {
      map['table_id'] = Variable<String>(tableId);
    }
    map['customer_name'] = Variable<String>(customerName);
    map['customer_phone'] = Variable<String>(customerPhone);
    if (!nullToAbsent || guests != null) {
      map['guests'] = Variable<int>(guests);
    }
    if (!nullToAbsent || staffId != null) {
      map['staff_id'] = Variable<String>(staffId);
    }
    map['staff_name'] = Variable<String>(staffName);
    map['status'] = Variable<String>(status);
    map['notes'] = Variable<String>(notes);
    map['discount_kind'] = Variable<String>(discountKind);
    map['discount_value'] = Variable<int>(discountValue);
    map['discount_reason'] = Variable<String>(discountReason);
    map['cancel_reason'] = Variable<String>(cancelReason);
    map['client_request_id'] = Variable<String>(clientRequestId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<int>(closedAt);
    }
    return map;
  }

  OrdersCompanion toCompanion(bool nullToAbsent) {
    return OrdersCompanion(
      id: Value(id),
      orderNo: Value(orderNo),
      businessDate: Value(businessDate),
      orderType: Value(orderType),
      tableId: tableId == null && nullToAbsent
          ? const Value.absent()
          : Value(tableId),
      customerName: Value(customerName),
      customerPhone: Value(customerPhone),
      guests: guests == null && nullToAbsent
          ? const Value.absent()
          : Value(guests),
      staffId: staffId == null && nullToAbsent
          ? const Value.absent()
          : Value(staffId),
      staffName: Value(staffName),
      status: Value(status),
      notes: Value(notes),
      discountKind: Value(discountKind),
      discountValue: Value(discountValue),
      discountReason: Value(discountReason),
      cancelReason: Value(cancelReason),
      clientRequestId: Value(clientRequestId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
    );
  }

  factory OrderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderRow(
      id: serializer.fromJson<String>(json['id']),
      orderNo: serializer.fromJson<int>(json['orderNo']),
      businessDate: serializer.fromJson<String>(json['businessDate']),
      orderType: serializer.fromJson<String>(json['orderType']),
      tableId: serializer.fromJson<String?>(json['tableId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerPhone: serializer.fromJson<String>(json['customerPhone']),
      guests: serializer.fromJson<int?>(json['guests']),
      staffId: serializer.fromJson<String?>(json['staffId']),
      staffName: serializer.fromJson<String>(json['staffName']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String>(json['notes']),
      discountKind: serializer.fromJson<String>(json['discountKind']),
      discountValue: serializer.fromJson<int>(json['discountValue']),
      discountReason: serializer.fromJson<String>(json['discountReason']),
      cancelReason: serializer.fromJson<String>(json['cancelReason']),
      clientRequestId: serializer.fromJson<String>(json['clientRequestId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      closedAt: serializer.fromJson<int?>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderNo': serializer.toJson<int>(orderNo),
      'businessDate': serializer.toJson<String>(businessDate),
      'orderType': serializer.toJson<String>(orderType),
      'tableId': serializer.toJson<String?>(tableId),
      'customerName': serializer.toJson<String>(customerName),
      'customerPhone': serializer.toJson<String>(customerPhone),
      'guests': serializer.toJson<int?>(guests),
      'staffId': serializer.toJson<String?>(staffId),
      'staffName': serializer.toJson<String>(staffName),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String>(notes),
      'discountKind': serializer.toJson<String>(discountKind),
      'discountValue': serializer.toJson<int>(discountValue),
      'discountReason': serializer.toJson<String>(discountReason),
      'cancelReason': serializer.toJson<String>(cancelReason),
      'clientRequestId': serializer.toJson<String>(clientRequestId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'closedAt': serializer.toJson<int?>(closedAt),
    };
  }

  OrderRow copyWith({
    String? id,
    int? orderNo,
    String? businessDate,
    String? orderType,
    Value<String?> tableId = const Value.absent(),
    String? customerName,
    String? customerPhone,
    Value<int?> guests = const Value.absent(),
    Value<String?> staffId = const Value.absent(),
    String? staffName,
    String? status,
    String? notes,
    String? discountKind,
    int? discountValue,
    String? discountReason,
    String? cancelReason,
    String? clientRequestId,
    int? createdAt,
    int? updatedAt,
    Value<int?> closedAt = const Value.absent(),
  }) => OrderRow(
    id: id ?? this.id,
    orderNo: orderNo ?? this.orderNo,
    businessDate: businessDate ?? this.businessDate,
    orderType: orderType ?? this.orderType,
    tableId: tableId.present ? tableId.value : this.tableId,
    customerName: customerName ?? this.customerName,
    customerPhone: customerPhone ?? this.customerPhone,
    guests: guests.present ? guests.value : this.guests,
    staffId: staffId.present ? staffId.value : this.staffId,
    staffName: staffName ?? this.staffName,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    discountKind: discountKind ?? this.discountKind,
    discountValue: discountValue ?? this.discountValue,
    discountReason: discountReason ?? this.discountReason,
    cancelReason: cancelReason ?? this.cancelReason,
    clientRequestId: clientRequestId ?? this.clientRequestId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
  );
  OrderRow copyWithCompanion(OrdersCompanion data) {
    return OrderRow(
      id: data.id.present ? data.id.value : this.id,
      orderNo: data.orderNo.present ? data.orderNo.value : this.orderNo,
      businessDate: data.businessDate.present
          ? data.businessDate.value
          : this.businessDate,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      tableId: data.tableId.present ? data.tableId.value : this.tableId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      guests: data.guests.present ? data.guests.value : this.guests,
      staffId: data.staffId.present ? data.staffId.value : this.staffId,
      staffName: data.staffName.present ? data.staffName.value : this.staffName,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      discountKind: data.discountKind.present
          ? data.discountKind.value
          : this.discountKind,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      discountReason: data.discountReason.present
          ? data.discountReason.value
          : this.discountReason,
      cancelReason: data.cancelReason.present
          ? data.cancelReason.value
          : this.cancelReason,
      clientRequestId: data.clientRequestId.present
          ? data.clientRequestId.value
          : this.clientRequestId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderRow(')
          ..write('id: $id, ')
          ..write('orderNo: $orderNo, ')
          ..write('businessDate: $businessDate, ')
          ..write('orderType: $orderType, ')
          ..write('tableId: $tableId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('guests: $guests, ')
          ..write('staffId: $staffId, ')
          ..write('staffName: $staffName, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('discountKind: $discountKind, ')
          ..write('discountValue: $discountValue, ')
          ..write('discountReason: $discountReason, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderNo,
    businessDate,
    orderType,
    tableId,
    customerName,
    customerPhone,
    guests,
    staffId,
    staffName,
    status,
    notes,
    discountKind,
    discountValue,
    discountReason,
    cancelReason,
    clientRequestId,
    createdAt,
    updatedAt,
    closedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderRow &&
          other.id == this.id &&
          other.orderNo == this.orderNo &&
          other.businessDate == this.businessDate &&
          other.orderType == this.orderType &&
          other.tableId == this.tableId &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.guests == this.guests &&
          other.staffId == this.staffId &&
          other.staffName == this.staffName &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.discountKind == this.discountKind &&
          other.discountValue == this.discountValue &&
          other.discountReason == this.discountReason &&
          other.cancelReason == this.cancelReason &&
          other.clientRequestId == this.clientRequestId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.closedAt == this.closedAt);
}

class OrdersCompanion extends UpdateCompanion<OrderRow> {
  final Value<String> id;
  final Value<int> orderNo;
  final Value<String> businessDate;
  final Value<String> orderType;
  final Value<String?> tableId;
  final Value<String> customerName;
  final Value<String> customerPhone;
  final Value<int?> guests;
  final Value<String?> staffId;
  final Value<String> staffName;
  final Value<String> status;
  final Value<String> notes;
  final Value<String> discountKind;
  final Value<int> discountValue;
  final Value<String> discountReason;
  final Value<String> cancelReason;
  final Value<String> clientRequestId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> closedAt;
  final Value<int> rowid;
  const OrdersCompanion({
    this.id = const Value.absent(),
    this.orderNo = const Value.absent(),
    this.businessDate = const Value.absent(),
    this.orderType = const Value.absent(),
    this.tableId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.guests = const Value.absent(),
    this.staffId = const Value.absent(),
    this.staffName = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.discountKind = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.discountReason = const Value.absent(),
    this.cancelReason = const Value.absent(),
    this.clientRequestId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrdersCompanion.insert({
    required String id,
    required int orderNo,
    required String businessDate,
    required String orderType,
    this.tableId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.guests = const Value.absent(),
    this.staffId = const Value.absent(),
    this.staffName = const Value.absent(),
    required String status,
    this.notes = const Value.absent(),
    this.discountKind = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.discountReason = const Value.absent(),
    this.cancelReason = const Value.absent(),
    required String clientRequestId,
    required int createdAt,
    required int updatedAt,
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderNo = Value(orderNo),
       businessDate = Value(businessDate),
       orderType = Value(orderType),
       status = Value(status),
       clientRequestId = Value(clientRequestId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OrderRow> custom({
    Expression<String>? id,
    Expression<int>? orderNo,
    Expression<String>? businessDate,
    Expression<String>? orderType,
    Expression<String>? tableId,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<int>? guests,
    Expression<String>? staffId,
    Expression<String>? staffName,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<String>? discountKind,
    Expression<int>? discountValue,
    Expression<String>? discountReason,
    Expression<String>? cancelReason,
    Expression<String>? clientRequestId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? closedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderNo != null) 'order_no': orderNo,
      if (businessDate != null) 'business_date': businessDate,
      if (orderType != null) 'order_type': orderType,
      if (tableId != null) 'table_id': tableId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (guests != null) 'guests': guests,
      if (staffId != null) 'staff_id': staffId,
      if (staffName != null) 'staff_name': staffName,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (discountKind != null) 'discount_kind': discountKind,
      if (discountValue != null) 'discount_value': discountValue,
      if (discountReason != null) 'discount_reason': discountReason,
      if (cancelReason != null) 'cancel_reason': cancelReason,
      if (clientRequestId != null) 'client_request_id': clientRequestId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrdersCompanion copyWith({
    Value<String>? id,
    Value<int>? orderNo,
    Value<String>? businessDate,
    Value<String>? orderType,
    Value<String?>? tableId,
    Value<String>? customerName,
    Value<String>? customerPhone,
    Value<int?>? guests,
    Value<String?>? staffId,
    Value<String>? staffName,
    Value<String>? status,
    Value<String>? notes,
    Value<String>? discountKind,
    Value<int>? discountValue,
    Value<String>? discountReason,
    Value<String>? cancelReason,
    Value<String>? clientRequestId,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? closedAt,
    Value<int>? rowid,
  }) {
    return OrdersCompanion(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      businessDate: businessDate ?? this.businessDate,
      orderType: orderType ?? this.orderType,
      tableId: tableId ?? this.tableId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      guests: guests ?? this.guests,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      discountKind: discountKind ?? this.discountKind,
      discountValue: discountValue ?? this.discountValue,
      discountReason: discountReason ?? this.discountReason,
      cancelReason: cancelReason ?? this.cancelReason,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (orderNo.present) {
      map['order_no'] = Variable<int>(orderNo.value);
    }
    if (businessDate.present) {
      map['business_date'] = Variable<String>(businessDate.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (tableId.present) {
      map['table_id'] = Variable<String>(tableId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (guests.present) {
      map['guests'] = Variable<int>(guests.value);
    }
    if (staffId.present) {
      map['staff_id'] = Variable<String>(staffId.value);
    }
    if (staffName.present) {
      map['staff_name'] = Variable<String>(staffName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (discountKind.present) {
      map['discount_kind'] = Variable<String>(discountKind.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<int>(discountValue.value);
    }
    if (discountReason.present) {
      map['discount_reason'] = Variable<String>(discountReason.value);
    }
    if (cancelReason.present) {
      map['cancel_reason'] = Variable<String>(cancelReason.value);
    }
    if (clientRequestId.present) {
      map['client_request_id'] = Variable<String>(clientRequestId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<int>(closedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrdersCompanion(')
          ..write('id: $id, ')
          ..write('orderNo: $orderNo, ')
          ..write('businessDate: $businessDate, ')
          ..write('orderType: $orderType, ')
          ..write('tableId: $tableId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('guests: $guests, ')
          ..write('staffId: $staffId, ')
          ..write('staffName: $staffName, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('discountKind: $discountKind, ')
          ..write('discountValue: $discountValue, ')
          ..write('discountReason: $discountReason, ')
          ..write('cancelReason: $cancelReason, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderLinesTable extends OrderLines
    with TableInfo<$OrderLinesTable, OrderLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderLinesTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES orders (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _menuItemIdMeta = const VerificationMeta(
    'menuItemId',
  );
  @override
  late final GeneratedColumn<String> menuItemId = GeneratedColumn<String>(
    'menu_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES menu_items (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantTextMeta = const VerificationMeta(
    'variantText',
  );
  @override
  late final GeneratedColumn<String> variantText = GeneratedColumn<String>(
    'variant_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _basePricePaiseMeta = const VerificationMeta(
    'basePricePaise',
  );
  @override
  late final GeneratedColumn<int> basePricePaise = GeneratedColumn<int>(
    'base_price_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPricePaiseMeta = const VerificationMeta(
    'unitPricePaise',
  );
  @override
  late final GeneratedColumn<int> unitPricePaise = GeneratedColumn<int>(
    'unit_price_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taxProfileIdMeta = const VerificationMeta(
    'taxProfileId',
  );
  @override
  late final GeneratedColumn<String> taxProfileId = GeneratedColumn<String>(
    'tax_profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxRateBpMeta = const VerificationMeta(
    'taxRateBp',
  );
  @override
  late final GeneratedColumn<int> taxRateBp = GeneratedColumn<int>(
    'tax_rate_bp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxInclusiveMeta = const VerificationMeta(
    'taxInclusive',
  );
  @override
  late final GeneratedColumn<bool> taxInclusive = GeneratedColumn<bool>(
    'tax_inclusive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tax_inclusive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _taxSplitModeMeta = const VerificationMeta(
    'taxSplitMode',
  );
  @override
  late final GeneratedColumn<String> taxSplitMode = GeneratedColumn<String>(
    'tax_split_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _stationIdMeta = const VerificationMeta(
    'stationId',
  );
  @override
  late final GeneratedColumn<String> stationId = GeneratedColumn<String>(
    'station_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentQtyMeta = const VerificationMeta(
    'sentQty',
  );
  @override
  late final GeneratedColumn<int> sentQty = GeneratedColumn<int>(
    'sent_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _voidedQtyMeta = const VerificationMeta(
    'voidedQty',
  );
  @override
  late final GeneratedColumn<int> voidedQty = GeneratedColumn<int>(
    'voided_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    orderId,
    menuItemId,
    itemName,
    variantText,
    basePricePaise,
    unitPricePaise,
    taxProfileId,
    taxRateBp,
    taxInclusive,
    taxSplitMode,
    stationId,
    qty,
    sentQty,
    voidedQty,
    notes,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderLineRow> instance, {
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
    if (data.containsKey('menu_item_id')) {
      context.handle(
        _menuItemIdMeta,
        menuItemId.isAcceptableOrUnknown(
          data['menu_item_id']!,
          _menuItemIdMeta,
        ),
      );
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('variant_text')) {
      context.handle(
        _variantTextMeta,
        variantText.isAcceptableOrUnknown(
          data['variant_text']!,
          _variantTextMeta,
        ),
      );
    }
    if (data.containsKey('base_price_paise')) {
      context.handle(
        _basePricePaiseMeta,
        basePricePaise.isAcceptableOrUnknown(
          data['base_price_paise']!,
          _basePricePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_basePricePaiseMeta);
    }
    if (data.containsKey('unit_price_paise')) {
      context.handle(
        _unitPricePaiseMeta,
        unitPricePaise.isAcceptableOrUnknown(
          data['unit_price_paise']!,
          _unitPricePaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPricePaiseMeta);
    }
    if (data.containsKey('tax_profile_id')) {
      context.handle(
        _taxProfileIdMeta,
        taxProfileId.isAcceptableOrUnknown(
          data['tax_profile_id']!,
          _taxProfileIdMeta,
        ),
      );
    }
    if (data.containsKey('tax_rate_bp')) {
      context.handle(
        _taxRateBpMeta,
        taxRateBp.isAcceptableOrUnknown(data['tax_rate_bp']!, _taxRateBpMeta),
      );
    }
    if (data.containsKey('tax_inclusive')) {
      context.handle(
        _taxInclusiveMeta,
        taxInclusive.isAcceptableOrUnknown(
          data['tax_inclusive']!,
          _taxInclusiveMeta,
        ),
      );
    }
    if (data.containsKey('tax_split_mode')) {
      context.handle(
        _taxSplitModeMeta,
        taxSplitMode.isAcceptableOrUnknown(
          data['tax_split_mode']!,
          _taxSplitModeMeta,
        ),
      );
    }
    if (data.containsKey('station_id')) {
      context.handle(
        _stationIdMeta,
        stationId.isAcceptableOrUnknown(data['station_id']!, _stationIdMeta),
      );
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('sent_qty')) {
      context.handle(
        _sentQtyMeta,
        sentQty.isAcceptableOrUnknown(data['sent_qty']!, _sentQtyMeta),
      );
    }
    if (data.containsKey('voided_qty')) {
      context.handle(
        _voidedQtyMeta,
        voidedQty.isAcceptableOrUnknown(data['voided_qty']!, _voidedQtyMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  OrderLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      menuItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}menu_item_id'],
      ),
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      variantText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_text'],
      )!,
      basePricePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_price_paise'],
      )!,
      unitPricePaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_paise'],
      )!,
      taxProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_profile_id'],
      ),
      taxRateBp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_bp'],
      )!,
      taxInclusive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tax_inclusive'],
      )!,
      taxSplitMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_split_mode'],
      )!,
      stationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_id'],
      ),
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      sentQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sent_qty'],
      )!,
      voidedQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}voided_qty'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
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
  $OrderLinesTable createAlias(String alias) {
    return $OrderLinesTable(attachedDatabase, alias);
  }
}

class OrderLineRow extends DataClass implements Insertable<OrderLineRow> {
  final String id;
  final String orderId;

  /// Reference only; the snapshot columns below are what is billed.
  final String? menuItemId;
  final String itemName;
  final String variantText;
  final int basePricePaise;

  /// Base price plus all chosen options, for one unit.
  final int unitPricePaise;
  final String? taxProfileId;
  final int taxRateBp;
  final bool taxInclusive;
  final String taxSplitMode;
  final String? stationId;
  final int qty;

  /// Units already sent to the kitchen (KOT module). Quantity can never go
  /// below this; sent units must be voided instead.
  final int sentQty;
  final int voidedQty;
  final String notes;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
  const OrderLineRow({
    required this.id,
    required this.orderId,
    this.menuItemId,
    required this.itemName,
    required this.variantText,
    required this.basePricePaise,
    required this.unitPricePaise,
    this.taxProfileId,
    required this.taxRateBp,
    required this.taxInclusive,
    required this.taxSplitMode,
    this.stationId,
    required this.qty,
    required this.sentQty,
    required this.voidedQty,
    required this.notes,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    if (!nullToAbsent || menuItemId != null) {
      map['menu_item_id'] = Variable<String>(menuItemId);
    }
    map['item_name'] = Variable<String>(itemName);
    map['variant_text'] = Variable<String>(variantText);
    map['base_price_paise'] = Variable<int>(basePricePaise);
    map['unit_price_paise'] = Variable<int>(unitPricePaise);
    if (!nullToAbsent || taxProfileId != null) {
      map['tax_profile_id'] = Variable<String>(taxProfileId);
    }
    map['tax_rate_bp'] = Variable<int>(taxRateBp);
    map['tax_inclusive'] = Variable<bool>(taxInclusive);
    map['tax_split_mode'] = Variable<String>(taxSplitMode);
    if (!nullToAbsent || stationId != null) {
      map['station_id'] = Variable<String>(stationId);
    }
    map['qty'] = Variable<int>(qty);
    map['sent_qty'] = Variable<int>(sentQty);
    map['voided_qty'] = Variable<int>(voidedQty);
    map['notes'] = Variable<String>(notes);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  OrderLinesCompanion toCompanion(bool nullToAbsent) {
    return OrderLinesCompanion(
      id: Value(id),
      orderId: Value(orderId),
      menuItemId: menuItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(menuItemId),
      itemName: Value(itemName),
      variantText: Value(variantText),
      basePricePaise: Value(basePricePaise),
      unitPricePaise: Value(unitPricePaise),
      taxProfileId: taxProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(taxProfileId),
      taxRateBp: Value(taxRateBp),
      taxInclusive: Value(taxInclusive),
      taxSplitMode: Value(taxSplitMode),
      stationId: stationId == null && nullToAbsent
          ? const Value.absent()
          : Value(stationId),
      qty: Value(qty),
      sentQty: Value(sentQty),
      voidedQty: Value(voidedQty),
      notes: Value(notes),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory OrderLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderLineRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      menuItemId: serializer.fromJson<String?>(json['menuItemId']),
      itemName: serializer.fromJson<String>(json['itemName']),
      variantText: serializer.fromJson<String>(json['variantText']),
      basePricePaise: serializer.fromJson<int>(json['basePricePaise']),
      unitPricePaise: serializer.fromJson<int>(json['unitPricePaise']),
      taxProfileId: serializer.fromJson<String?>(json['taxProfileId']),
      taxRateBp: serializer.fromJson<int>(json['taxRateBp']),
      taxInclusive: serializer.fromJson<bool>(json['taxInclusive']),
      taxSplitMode: serializer.fromJson<String>(json['taxSplitMode']),
      stationId: serializer.fromJson<String?>(json['stationId']),
      qty: serializer.fromJson<int>(json['qty']),
      sentQty: serializer.fromJson<int>(json['sentQty']),
      voidedQty: serializer.fromJson<int>(json['voidedQty']),
      notes: serializer.fromJson<String>(json['notes']),
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
      'orderId': serializer.toJson<String>(orderId),
      'menuItemId': serializer.toJson<String?>(menuItemId),
      'itemName': serializer.toJson<String>(itemName),
      'variantText': serializer.toJson<String>(variantText),
      'basePricePaise': serializer.toJson<int>(basePricePaise),
      'unitPricePaise': serializer.toJson<int>(unitPricePaise),
      'taxProfileId': serializer.toJson<String?>(taxProfileId),
      'taxRateBp': serializer.toJson<int>(taxRateBp),
      'taxInclusive': serializer.toJson<bool>(taxInclusive),
      'taxSplitMode': serializer.toJson<String>(taxSplitMode),
      'stationId': serializer.toJson<String?>(stationId),
      'qty': serializer.toJson<int>(qty),
      'sentQty': serializer.toJson<int>(sentQty),
      'voidedQty': serializer.toJson<int>(voidedQty),
      'notes': serializer.toJson<String>(notes),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  OrderLineRow copyWith({
    String? id,
    String? orderId,
    Value<String?> menuItemId = const Value.absent(),
    String? itemName,
    String? variantText,
    int? basePricePaise,
    int? unitPricePaise,
    Value<String?> taxProfileId = const Value.absent(),
    int? taxRateBp,
    bool? taxInclusive,
    String? taxSplitMode,
    Value<String?> stationId = const Value.absent(),
    int? qty,
    int? sentQty,
    int? voidedQty,
    String? notes,
    int? sortOrder,
    int? createdAt,
    int? updatedAt,
  }) => OrderLineRow(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    menuItemId: menuItemId.present ? menuItemId.value : this.menuItemId,
    itemName: itemName ?? this.itemName,
    variantText: variantText ?? this.variantText,
    basePricePaise: basePricePaise ?? this.basePricePaise,
    unitPricePaise: unitPricePaise ?? this.unitPricePaise,
    taxProfileId: taxProfileId.present ? taxProfileId.value : this.taxProfileId,
    taxRateBp: taxRateBp ?? this.taxRateBp,
    taxInclusive: taxInclusive ?? this.taxInclusive,
    taxSplitMode: taxSplitMode ?? this.taxSplitMode,
    stationId: stationId.present ? stationId.value : this.stationId,
    qty: qty ?? this.qty,
    sentQty: sentQty ?? this.sentQty,
    voidedQty: voidedQty ?? this.voidedQty,
    notes: notes ?? this.notes,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OrderLineRow copyWithCompanion(OrderLinesCompanion data) {
    return OrderLineRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      menuItemId: data.menuItemId.present
          ? data.menuItemId.value
          : this.menuItemId,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      variantText: data.variantText.present
          ? data.variantText.value
          : this.variantText,
      basePricePaise: data.basePricePaise.present
          ? data.basePricePaise.value
          : this.basePricePaise,
      unitPricePaise: data.unitPricePaise.present
          ? data.unitPricePaise.value
          : this.unitPricePaise,
      taxProfileId: data.taxProfileId.present
          ? data.taxProfileId.value
          : this.taxProfileId,
      taxRateBp: data.taxRateBp.present ? data.taxRateBp.value : this.taxRateBp,
      taxInclusive: data.taxInclusive.present
          ? data.taxInclusive.value
          : this.taxInclusive,
      taxSplitMode: data.taxSplitMode.present
          ? data.taxSplitMode.value
          : this.taxSplitMode,
      stationId: data.stationId.present ? data.stationId.value : this.stationId,
      qty: data.qty.present ? data.qty.value : this.qty,
      sentQty: data.sentQty.present ? data.sentQty.value : this.sentQty,
      voidedQty: data.voidedQty.present ? data.voidedQty.value : this.voidedQty,
      notes: data.notes.present ? data.notes.value : this.notes,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderLineRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('menuItemId: $menuItemId, ')
          ..write('itemName: $itemName, ')
          ..write('variantText: $variantText, ')
          ..write('basePricePaise: $basePricePaise, ')
          ..write('unitPricePaise: $unitPricePaise, ')
          ..write('taxProfileId: $taxProfileId, ')
          ..write('taxRateBp: $taxRateBp, ')
          ..write('taxInclusive: $taxInclusive, ')
          ..write('taxSplitMode: $taxSplitMode, ')
          ..write('stationId: $stationId, ')
          ..write('qty: $qty, ')
          ..write('sentQty: $sentQty, ')
          ..write('voidedQty: $voidedQty, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    menuItemId,
    itemName,
    variantText,
    basePricePaise,
    unitPricePaise,
    taxProfileId,
    taxRateBp,
    taxInclusive,
    taxSplitMode,
    stationId,
    qty,
    sentQty,
    voidedQty,
    notes,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderLineRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.menuItemId == this.menuItemId &&
          other.itemName == this.itemName &&
          other.variantText == this.variantText &&
          other.basePricePaise == this.basePricePaise &&
          other.unitPricePaise == this.unitPricePaise &&
          other.taxProfileId == this.taxProfileId &&
          other.taxRateBp == this.taxRateBp &&
          other.taxInclusive == this.taxInclusive &&
          other.taxSplitMode == this.taxSplitMode &&
          other.stationId == this.stationId &&
          other.qty == this.qty &&
          other.sentQty == this.sentQty &&
          other.voidedQty == this.voidedQty &&
          other.notes == this.notes &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class OrderLinesCompanion extends UpdateCompanion<OrderLineRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String?> menuItemId;
  final Value<String> itemName;
  final Value<String> variantText;
  final Value<int> basePricePaise;
  final Value<int> unitPricePaise;
  final Value<String?> taxProfileId;
  final Value<int> taxRateBp;
  final Value<bool> taxInclusive;
  final Value<String> taxSplitMode;
  final Value<String?> stationId;
  final Value<int> qty;
  final Value<int> sentQty;
  final Value<int> voidedQty;
  final Value<String> notes;
  final Value<int> sortOrder;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const OrderLinesCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.menuItemId = const Value.absent(),
    this.itemName = const Value.absent(),
    this.variantText = const Value.absent(),
    this.basePricePaise = const Value.absent(),
    this.unitPricePaise = const Value.absent(),
    this.taxProfileId = const Value.absent(),
    this.taxRateBp = const Value.absent(),
    this.taxInclusive = const Value.absent(),
    this.taxSplitMode = const Value.absent(),
    this.stationId = const Value.absent(),
    this.qty = const Value.absent(),
    this.sentQty = const Value.absent(),
    this.voidedQty = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderLinesCompanion.insert({
    required String id,
    required String orderId,
    this.menuItemId = const Value.absent(),
    required String itemName,
    this.variantText = const Value.absent(),
    required int basePricePaise,
    required int unitPricePaise,
    this.taxProfileId = const Value.absent(),
    this.taxRateBp = const Value.absent(),
    this.taxInclusive = const Value.absent(),
    this.taxSplitMode = const Value.absent(),
    this.stationId = const Value.absent(),
    required int qty,
    this.sentQty = const Value.absent(),
    this.voidedQty = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       itemName = Value(itemName),
       basePricePaise = Value(basePricePaise),
       unitPricePaise = Value(unitPricePaise),
       qty = Value(qty),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<OrderLineRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? menuItemId,
    Expression<String>? itemName,
    Expression<String>? variantText,
    Expression<int>? basePricePaise,
    Expression<int>? unitPricePaise,
    Expression<String>? taxProfileId,
    Expression<int>? taxRateBp,
    Expression<bool>? taxInclusive,
    Expression<String>? taxSplitMode,
    Expression<String>? stationId,
    Expression<int>? qty,
    Expression<int>? sentQty,
    Expression<int>? voidedQty,
    Expression<String>? notes,
    Expression<int>? sortOrder,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (menuItemId != null) 'menu_item_id': menuItemId,
      if (itemName != null) 'item_name': itemName,
      if (variantText != null) 'variant_text': variantText,
      if (basePricePaise != null) 'base_price_paise': basePricePaise,
      if (unitPricePaise != null) 'unit_price_paise': unitPricePaise,
      if (taxProfileId != null) 'tax_profile_id': taxProfileId,
      if (taxRateBp != null) 'tax_rate_bp': taxRateBp,
      if (taxInclusive != null) 'tax_inclusive': taxInclusive,
      if (taxSplitMode != null) 'tax_split_mode': taxSplitMode,
      if (stationId != null) 'station_id': stationId,
      if (qty != null) 'qty': qty,
      if (sentQty != null) 'sent_qty': sentQty,
      if (voidedQty != null) 'voided_qty': voidedQty,
      if (notes != null) 'notes': notes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String?>? menuItemId,
    Value<String>? itemName,
    Value<String>? variantText,
    Value<int>? basePricePaise,
    Value<int>? unitPricePaise,
    Value<String?>? taxProfileId,
    Value<int>? taxRateBp,
    Value<bool>? taxInclusive,
    Value<String>? taxSplitMode,
    Value<String?>? stationId,
    Value<int>? qty,
    Value<int>? sentQty,
    Value<int>? voidedQty,
    Value<String>? notes,
    Value<int>? sortOrder,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return OrderLinesCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      menuItemId: menuItemId ?? this.menuItemId,
      itemName: itemName ?? this.itemName,
      variantText: variantText ?? this.variantText,
      basePricePaise: basePricePaise ?? this.basePricePaise,
      unitPricePaise: unitPricePaise ?? this.unitPricePaise,
      taxProfileId: taxProfileId ?? this.taxProfileId,
      taxRateBp: taxRateBp ?? this.taxRateBp,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      taxSplitMode: taxSplitMode ?? this.taxSplitMode,
      stationId: stationId ?? this.stationId,
      qty: qty ?? this.qty,
      sentQty: sentQty ?? this.sentQty,
      voidedQty: voidedQty ?? this.voidedQty,
      notes: notes ?? this.notes,
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
    if (orderId.present) {
      map['order_id'] = Variable<String>(orderId.value);
    }
    if (menuItemId.present) {
      map['menu_item_id'] = Variable<String>(menuItemId.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (variantText.present) {
      map['variant_text'] = Variable<String>(variantText.value);
    }
    if (basePricePaise.present) {
      map['base_price_paise'] = Variable<int>(basePricePaise.value);
    }
    if (unitPricePaise.present) {
      map['unit_price_paise'] = Variable<int>(unitPricePaise.value);
    }
    if (taxProfileId.present) {
      map['tax_profile_id'] = Variable<String>(taxProfileId.value);
    }
    if (taxRateBp.present) {
      map['tax_rate_bp'] = Variable<int>(taxRateBp.value);
    }
    if (taxInclusive.present) {
      map['tax_inclusive'] = Variable<bool>(taxInclusive.value);
    }
    if (taxSplitMode.present) {
      map['tax_split_mode'] = Variable<String>(taxSplitMode.value);
    }
    if (stationId.present) {
      map['station_id'] = Variable<String>(stationId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (sentQty.present) {
      map['sent_qty'] = Variable<int>(sentQty.value);
    }
    if (voidedQty.present) {
      map['voided_qty'] = Variable<int>(voidedQty.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('OrderLinesCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('menuItemId: $menuItemId, ')
          ..write('itemName: $itemName, ')
          ..write('variantText: $variantText, ')
          ..write('basePricePaise: $basePricePaise, ')
          ..write('unitPricePaise: $unitPricePaise, ')
          ..write('taxProfileId: $taxProfileId, ')
          ..write('taxRateBp: $taxRateBp, ')
          ..write('taxInclusive: $taxInclusive, ')
          ..write('taxSplitMode: $taxSplitMode, ')
          ..write('stationId: $stationId, ')
          ..write('qty: $qty, ')
          ..write('sentQty: $sentQty, ')
          ..write('voidedQty: $voidedQty, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderLineOptionsTable extends OrderLineOptions
    with TableInfo<$OrderLineOptionsTable, OrderLineOptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderLineOptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lineIdMeta = const VerificationMeta('lineId');
  @override
  late final GeneratedColumn<String> lineId = GeneratedColumn<String>(
    'line_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES order_lines (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _choiceIdMeta = const VerificationMeta(
    'choiceId',
  );
  @override
  late final GeneratedColumn<String> choiceId = GeneratedColumn<String>(
    'choice_id',
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
  static const VerificationMeta _priceDeltaPaiseMeta = const VerificationMeta(
    'priceDeltaPaise',
  );
  @override
  late final GeneratedColumn<int> priceDeltaPaise = GeneratedColumn<int>(
    'price_delta_paise',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lineId,
    groupId,
    groupName,
    kind,
    choiceId,
    name,
    priceDeltaPaise,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_line_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderLineOptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('line_id')) {
      context.handle(
        _lineIdMeta,
        lineId.isAcceptableOrUnknown(data['line_id']!, _lineIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lineIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    } else if (isInserting) {
      context.missing(_groupNameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('choice_id')) {
      context.handle(
        _choiceIdMeta,
        choiceId.isAcceptableOrUnknown(data['choice_id']!, _choiceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_choiceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_delta_paise')) {
      context.handle(
        _priceDeltaPaiseMeta,
        priceDeltaPaise.isAcceptableOrUnknown(
          data['price_delta_paise']!,
          _priceDeltaPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priceDeltaPaiseMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderLineOptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderLineOptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      choiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choice_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      priceDeltaPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_delta_paise'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $OrderLineOptionsTable createAlias(String alias) {
    return $OrderLineOptionsTable(attachedDatabase, alias);
  }
}

class OrderLineOptionRow extends DataClass
    implements Insertable<OrderLineOptionRow> {
  final String id;
  final String lineId;
  final String groupId;
  final String groupName;

  /// `OptionGroupKind.name`.
  final String kind;
  final String choiceId;
  final String name;
  final int priceDeltaPaise;
  final int sortOrder;
  const OrderLineOptionRow({
    required this.id,
    required this.lineId,
    required this.groupId,
    required this.groupName,
    required this.kind,
    required this.choiceId,
    required this.name,
    required this.priceDeltaPaise,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['line_id'] = Variable<String>(lineId);
    map['group_id'] = Variable<String>(groupId);
    map['group_name'] = Variable<String>(groupName);
    map['kind'] = Variable<String>(kind);
    map['choice_id'] = Variable<String>(choiceId);
    map['name'] = Variable<String>(name);
    map['price_delta_paise'] = Variable<int>(priceDeltaPaise);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  OrderLineOptionsCompanion toCompanion(bool nullToAbsent) {
    return OrderLineOptionsCompanion(
      id: Value(id),
      lineId: Value(lineId),
      groupId: Value(groupId),
      groupName: Value(groupName),
      kind: Value(kind),
      choiceId: Value(choiceId),
      name: Value(name),
      priceDeltaPaise: Value(priceDeltaPaise),
      sortOrder: Value(sortOrder),
    );
  }

  factory OrderLineOptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderLineOptionRow(
      id: serializer.fromJson<String>(json['id']),
      lineId: serializer.fromJson<String>(json['lineId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      groupName: serializer.fromJson<String>(json['groupName']),
      kind: serializer.fromJson<String>(json['kind']),
      choiceId: serializer.fromJson<String>(json['choiceId']),
      name: serializer.fromJson<String>(json['name']),
      priceDeltaPaise: serializer.fromJson<int>(json['priceDeltaPaise']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lineId': serializer.toJson<String>(lineId),
      'groupId': serializer.toJson<String>(groupId),
      'groupName': serializer.toJson<String>(groupName),
      'kind': serializer.toJson<String>(kind),
      'choiceId': serializer.toJson<String>(choiceId),
      'name': serializer.toJson<String>(name),
      'priceDeltaPaise': serializer.toJson<int>(priceDeltaPaise),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  OrderLineOptionRow copyWith({
    String? id,
    String? lineId,
    String? groupId,
    String? groupName,
    String? kind,
    String? choiceId,
    String? name,
    int? priceDeltaPaise,
    int? sortOrder,
  }) => OrderLineOptionRow(
    id: id ?? this.id,
    lineId: lineId ?? this.lineId,
    groupId: groupId ?? this.groupId,
    groupName: groupName ?? this.groupName,
    kind: kind ?? this.kind,
    choiceId: choiceId ?? this.choiceId,
    name: name ?? this.name,
    priceDeltaPaise: priceDeltaPaise ?? this.priceDeltaPaise,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  OrderLineOptionRow copyWithCompanion(OrderLineOptionsCompanion data) {
    return OrderLineOptionRow(
      id: data.id.present ? data.id.value : this.id,
      lineId: data.lineId.present ? data.lineId.value : this.lineId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      kind: data.kind.present ? data.kind.value : this.kind,
      choiceId: data.choiceId.present ? data.choiceId.value : this.choiceId,
      name: data.name.present ? data.name.value : this.name,
      priceDeltaPaise: data.priceDeltaPaise.present
          ? data.priceDeltaPaise.value
          : this.priceDeltaPaise,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderLineOptionRow(')
          ..write('id: $id, ')
          ..write('lineId: $lineId, ')
          ..write('groupId: $groupId, ')
          ..write('groupName: $groupName, ')
          ..write('kind: $kind, ')
          ..write('choiceId: $choiceId, ')
          ..write('name: $name, ')
          ..write('priceDeltaPaise: $priceDeltaPaise, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lineId,
    groupId,
    groupName,
    kind,
    choiceId,
    name,
    priceDeltaPaise,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderLineOptionRow &&
          other.id == this.id &&
          other.lineId == this.lineId &&
          other.groupId == this.groupId &&
          other.groupName == this.groupName &&
          other.kind == this.kind &&
          other.choiceId == this.choiceId &&
          other.name == this.name &&
          other.priceDeltaPaise == this.priceDeltaPaise &&
          other.sortOrder == this.sortOrder);
}

class OrderLineOptionsCompanion extends UpdateCompanion<OrderLineOptionRow> {
  final Value<String> id;
  final Value<String> lineId;
  final Value<String> groupId;
  final Value<String> groupName;
  final Value<String> kind;
  final Value<String> choiceId;
  final Value<String> name;
  final Value<int> priceDeltaPaise;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const OrderLineOptionsCompanion({
    this.id = const Value.absent(),
    this.lineId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupName = const Value.absent(),
    this.kind = const Value.absent(),
    this.choiceId = const Value.absent(),
    this.name = const Value.absent(),
    this.priceDeltaPaise = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderLineOptionsCompanion.insert({
    required String id,
    required String lineId,
    required String groupId,
    required String groupName,
    required String kind,
    required String choiceId,
    required String name,
    required int priceDeltaPaise,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       lineId = Value(lineId),
       groupId = Value(groupId),
       groupName = Value(groupName),
       kind = Value(kind),
       choiceId = Value(choiceId),
       name = Value(name),
       priceDeltaPaise = Value(priceDeltaPaise);
  static Insertable<OrderLineOptionRow> custom({
    Expression<String>? id,
    Expression<String>? lineId,
    Expression<String>? groupId,
    Expression<String>? groupName,
    Expression<String>? kind,
    Expression<String>? choiceId,
    Expression<String>? name,
    Expression<int>? priceDeltaPaise,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lineId != null) 'line_id': lineId,
      if (groupId != null) 'group_id': groupId,
      if (groupName != null) 'group_name': groupName,
      if (kind != null) 'kind': kind,
      if (choiceId != null) 'choice_id': choiceId,
      if (name != null) 'name': name,
      if (priceDeltaPaise != null) 'price_delta_paise': priceDeltaPaise,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderLineOptionsCompanion copyWith({
    Value<String>? id,
    Value<String>? lineId,
    Value<String>? groupId,
    Value<String>? groupName,
    Value<String>? kind,
    Value<String>? choiceId,
    Value<String>? name,
    Value<int>? priceDeltaPaise,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return OrderLineOptionsCompanion(
      id: id ?? this.id,
      lineId: lineId ?? this.lineId,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      kind: kind ?? this.kind,
      choiceId: choiceId ?? this.choiceId,
      name: name ?? this.name,
      priceDeltaPaise: priceDeltaPaise ?? this.priceDeltaPaise,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lineId.present) {
      map['line_id'] = Variable<String>(lineId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (choiceId.present) {
      map['choice_id'] = Variable<String>(choiceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (priceDeltaPaise.present) {
      map['price_delta_paise'] = Variable<int>(priceDeltaPaise.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderLineOptionsCompanion(')
          ..write('id: $id, ')
          ..write('lineId: $lineId, ')
          ..write('groupId: $groupId, ')
          ..write('groupName: $groupName, ')
          ..write('kind: $kind, ')
          ..write('choiceId: $choiceId, ')
          ..write('name: $name, ')
          ..write('priceDeltaPaise: $priceDeltaPaise, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StationPrintersTable extends StationPrinters
    with TableInfo<$StationPrintersTable, StationPrinterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StationPrintersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _stationIdMeta = const VerificationMeta(
    'stationId',
  );
  @override
  late final GeneratedColumn<String> stationId = GeneratedColumn<String>(
    'station_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _printerIdMeta = const VerificationMeta(
    'printerId',
  );
  @override
  late final GeneratedColumn<String> printerId = GeneratedColumn<String>(
    'printer_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [stationId, printerId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'station_printers';
  @override
  VerificationContext validateIntegrity(
    Insertable<StationPrinterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('station_id')) {
      context.handle(
        _stationIdMeta,
        stationId.isAcceptableOrUnknown(data['station_id']!, _stationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stationIdMeta);
    }
    if (data.containsKey('printer_id')) {
      context.handle(
        _printerIdMeta,
        printerId.isAcceptableOrUnknown(data['printer_id']!, _printerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_printerIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {stationId, printerId};
  @override
  StationPrinterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StationPrinterRow(
      stationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_id'],
      )!,
      printerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}printer_id'],
      )!,
    );
  }

  @override
  $StationPrintersTable createAlias(String alias) {
    return $StationPrintersTable(attachedDatabase, alias);
  }
}

class StationPrinterRow extends DataClass
    implements Insertable<StationPrinterRow> {
  final String stationId;
  final String printerId;
  const StationPrinterRow({required this.stationId, required this.printerId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['station_id'] = Variable<String>(stationId);
    map['printer_id'] = Variable<String>(printerId);
    return map;
  }

  StationPrintersCompanion toCompanion(bool nullToAbsent) {
    return StationPrintersCompanion(
      stationId: Value(stationId),
      printerId: Value(printerId),
    );
  }

  factory StationPrinterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StationPrinterRow(
      stationId: serializer.fromJson<String>(json['stationId']),
      printerId: serializer.fromJson<String>(json['printerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'stationId': serializer.toJson<String>(stationId),
      'printerId': serializer.toJson<String>(printerId),
    };
  }

  StationPrinterRow copyWith({String? stationId, String? printerId}) =>
      StationPrinterRow(
        stationId: stationId ?? this.stationId,
        printerId: printerId ?? this.printerId,
      );
  StationPrinterRow copyWithCompanion(StationPrintersCompanion data) {
    return StationPrinterRow(
      stationId: data.stationId.present ? data.stationId.value : this.stationId,
      printerId: data.printerId.present ? data.printerId.value : this.printerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StationPrinterRow(')
          ..write('stationId: $stationId, ')
          ..write('printerId: $printerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(stationId, printerId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StationPrinterRow &&
          other.stationId == this.stationId &&
          other.printerId == this.printerId);
}

class StationPrintersCompanion extends UpdateCompanion<StationPrinterRow> {
  final Value<String> stationId;
  final Value<String> printerId;
  final Value<int> rowid;
  const StationPrintersCompanion({
    this.stationId = const Value.absent(),
    this.printerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StationPrintersCompanion.insert({
    required String stationId,
    required String printerId,
    this.rowid = const Value.absent(),
  }) : stationId = Value(stationId),
       printerId = Value(printerId);
  static Insertable<StationPrinterRow> custom({
    Expression<String>? stationId,
    Expression<String>? printerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (stationId != null) 'station_id': stationId,
      if (printerId != null) 'printer_id': printerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StationPrintersCompanion copyWith({
    Value<String>? stationId,
    Value<String>? printerId,
    Value<int>? rowid,
  }) {
    return StationPrintersCompanion(
      stationId: stationId ?? this.stationId,
      printerId: printerId ?? this.printerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (stationId.present) {
      map['station_id'] = Variable<String>(stationId.value);
    }
    if (printerId.present) {
      map['printer_id'] = Variable<String>(printerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StationPrintersCompanion(')
          ..write('stationId: $stationId, ')
          ..write('printerId: $printerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KitchenTicketsTable extends KitchenTickets
    with TableInfo<$KitchenTicketsTable, KitchenTicketRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KitchenTicketsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES orders (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _stationIdMeta = const VerificationMeta(
    'stationId',
  );
  @override
  late final GeneratedColumn<String> stationId = GeneratedColumn<String>(
    'station_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stationNameMeta = const VerificationMeta(
    'stationName',
  );
  @override
  late final GeneratedColumn<String> stationName = GeneratedColumn<String>(
    'station_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundNoMeta = const VerificationMeta(
    'roundNo',
  );
  @override
  late final GeneratedColumn<int> roundNo = GeneratedColumn<int>(
    'round_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _clientRequestIdMeta = const VerificationMeta(
    'clientRequestId',
  );
  @override
  late final GeneratedColumn<String> clientRequestId = GeneratedColumn<String>(
    'client_request_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderId,
    stationId,
    stationName,
    roundNo,
    kind,
    reason,
    clientRequestId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kitchen_tickets';
  @override
  VerificationContext validateIntegrity(
    Insertable<KitchenTicketRow> instance, {
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
    if (data.containsKey('station_id')) {
      context.handle(
        _stationIdMeta,
        stationId.isAcceptableOrUnknown(data['station_id']!, _stationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stationIdMeta);
    }
    if (data.containsKey('station_name')) {
      context.handle(
        _stationNameMeta,
        stationName.isAcceptableOrUnknown(
          data['station_name']!,
          _stationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_stationNameMeta);
    }
    if (data.containsKey('round_no')) {
      context.handle(
        _roundNoMeta,
        roundNo.isAcceptableOrUnknown(data['round_no']!, _roundNoMeta),
      );
    } else if (isInserting) {
      context.missing(_roundNoMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('client_request_id')) {
      context.handle(
        _clientRequestIdMeta,
        clientRequestId.isAcceptableOrUnknown(
          data['client_request_id']!,
          _clientRequestIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRequestIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KitchenTicketRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KitchenTicketRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_id'],
      )!,
      stationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_id'],
      )!,
      stationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}station_name'],
      )!,
      roundNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_no'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      clientRequestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_request_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $KitchenTicketsTable createAlias(String alias) {
    return $KitchenTicketsTable(attachedDatabase, alias);
  }
}

class KitchenTicketRow extends DataClass
    implements Insertable<KitchenTicketRow> {
  final String id;
  final String orderId;

  /// Station id, or [StationPrinters.defaultStation].
  final String stationId;
  final String stationName;

  /// 1 for the first send of an order, 2 for the next, … (per order).
  final int roundNo;

  /// `KitchenTicketKind.name`: send | voided.
  final String kind;
  final String reason;

  /// Ties the ticket to the staff action that created it, so a retried
  /// action cannot create it twice.
  final String clientRequestId;
  final int createdAt;
  const KitchenTicketRow({
    required this.id,
    required this.orderId,
    required this.stationId,
    required this.stationName,
    required this.roundNo,
    required this.kind,
    required this.reason,
    required this.clientRequestId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['order_id'] = Variable<String>(orderId);
    map['station_id'] = Variable<String>(stationId);
    map['station_name'] = Variable<String>(stationName);
    map['round_no'] = Variable<int>(roundNo);
    map['kind'] = Variable<String>(kind);
    map['reason'] = Variable<String>(reason);
    map['client_request_id'] = Variable<String>(clientRequestId);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  KitchenTicketsCompanion toCompanion(bool nullToAbsent) {
    return KitchenTicketsCompanion(
      id: Value(id),
      orderId: Value(orderId),
      stationId: Value(stationId),
      stationName: Value(stationName),
      roundNo: Value(roundNo),
      kind: Value(kind),
      reason: Value(reason),
      clientRequestId: Value(clientRequestId),
      createdAt: Value(createdAt),
    );
  }

  factory KitchenTicketRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KitchenTicketRow(
      id: serializer.fromJson<String>(json['id']),
      orderId: serializer.fromJson<String>(json['orderId']),
      stationId: serializer.fromJson<String>(json['stationId']),
      stationName: serializer.fromJson<String>(json['stationName']),
      roundNo: serializer.fromJson<int>(json['roundNo']),
      kind: serializer.fromJson<String>(json['kind']),
      reason: serializer.fromJson<String>(json['reason']),
      clientRequestId: serializer.fromJson<String>(json['clientRequestId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'orderId': serializer.toJson<String>(orderId),
      'stationId': serializer.toJson<String>(stationId),
      'stationName': serializer.toJson<String>(stationName),
      'roundNo': serializer.toJson<int>(roundNo),
      'kind': serializer.toJson<String>(kind),
      'reason': serializer.toJson<String>(reason),
      'clientRequestId': serializer.toJson<String>(clientRequestId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  KitchenTicketRow copyWith({
    String? id,
    String? orderId,
    String? stationId,
    String? stationName,
    int? roundNo,
    String? kind,
    String? reason,
    String? clientRequestId,
    int? createdAt,
  }) => KitchenTicketRow(
    id: id ?? this.id,
    orderId: orderId ?? this.orderId,
    stationId: stationId ?? this.stationId,
    stationName: stationName ?? this.stationName,
    roundNo: roundNo ?? this.roundNo,
    kind: kind ?? this.kind,
    reason: reason ?? this.reason,
    clientRequestId: clientRequestId ?? this.clientRequestId,
    createdAt: createdAt ?? this.createdAt,
  );
  KitchenTicketRow copyWithCompanion(KitchenTicketsCompanion data) {
    return KitchenTicketRow(
      id: data.id.present ? data.id.value : this.id,
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      stationId: data.stationId.present ? data.stationId.value : this.stationId,
      stationName: data.stationName.present
          ? data.stationName.value
          : this.stationName,
      roundNo: data.roundNo.present ? data.roundNo.value : this.roundNo,
      kind: data.kind.present ? data.kind.value : this.kind,
      reason: data.reason.present ? data.reason.value : this.reason,
      clientRequestId: data.clientRequestId.present
          ? data.clientRequestId.value
          : this.clientRequestId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KitchenTicketRow(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('stationId: $stationId, ')
          ..write('stationName: $stationName, ')
          ..write('roundNo: $roundNo, ')
          ..write('kind: $kind, ')
          ..write('reason: $reason, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderId,
    stationId,
    stationName,
    roundNo,
    kind,
    reason,
    clientRequestId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KitchenTicketRow &&
          other.id == this.id &&
          other.orderId == this.orderId &&
          other.stationId == this.stationId &&
          other.stationName == this.stationName &&
          other.roundNo == this.roundNo &&
          other.kind == this.kind &&
          other.reason == this.reason &&
          other.clientRequestId == this.clientRequestId &&
          other.createdAt == this.createdAt);
}

class KitchenTicketsCompanion extends UpdateCompanion<KitchenTicketRow> {
  final Value<String> id;
  final Value<String> orderId;
  final Value<String> stationId;
  final Value<String> stationName;
  final Value<int> roundNo;
  final Value<String> kind;
  final Value<String> reason;
  final Value<String> clientRequestId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const KitchenTicketsCompanion({
    this.id = const Value.absent(),
    this.orderId = const Value.absent(),
    this.stationId = const Value.absent(),
    this.stationName = const Value.absent(),
    this.roundNo = const Value.absent(),
    this.kind = const Value.absent(),
    this.reason = const Value.absent(),
    this.clientRequestId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KitchenTicketsCompanion.insert({
    required String id,
    required String orderId,
    required String stationId,
    required String stationName,
    required int roundNo,
    required String kind,
    this.reason = const Value.absent(),
    required String clientRequestId,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       orderId = Value(orderId),
       stationId = Value(stationId),
       stationName = Value(stationName),
       roundNo = Value(roundNo),
       kind = Value(kind),
       clientRequestId = Value(clientRequestId),
       createdAt = Value(createdAt);
  static Insertable<KitchenTicketRow> custom({
    Expression<String>? id,
    Expression<String>? orderId,
    Expression<String>? stationId,
    Expression<String>? stationName,
    Expression<int>? roundNo,
    Expression<String>? kind,
    Expression<String>? reason,
    Expression<String>? clientRequestId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      if (stationId != null) 'station_id': stationId,
      if (stationName != null) 'station_name': stationName,
      if (roundNo != null) 'round_no': roundNo,
      if (kind != null) 'kind': kind,
      if (reason != null) 'reason': reason,
      if (clientRequestId != null) 'client_request_id': clientRequestId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KitchenTicketsCompanion copyWith({
    Value<String>? id,
    Value<String>? orderId,
    Value<String>? stationId,
    Value<String>? stationName,
    Value<int>? roundNo,
    Value<String>? kind,
    Value<String>? reason,
    Value<String>? clientRequestId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return KitchenTicketsCompanion(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      stationId: stationId ?? this.stationId,
      stationName: stationName ?? this.stationName,
      roundNo: roundNo ?? this.roundNo,
      kind: kind ?? this.kind,
      reason: reason ?? this.reason,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      createdAt: createdAt ?? this.createdAt,
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
    if (stationId.present) {
      map['station_id'] = Variable<String>(stationId.value);
    }
    if (stationName.present) {
      map['station_name'] = Variable<String>(stationName.value);
    }
    if (roundNo.present) {
      map['round_no'] = Variable<int>(roundNo.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (clientRequestId.present) {
      map['client_request_id'] = Variable<String>(clientRequestId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KitchenTicketsCompanion(')
          ..write('id: $id, ')
          ..write('orderId: $orderId, ')
          ..write('stationId: $stationId, ')
          ..write('stationName: $stationName, ')
          ..write('roundNo: $roundNo, ')
          ..write('kind: $kind, ')
          ..write('reason: $reason, ')
          ..write('clientRequestId: $clientRequestId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KitchenTicketLinesTable extends KitchenTicketLines
    with TableInfo<$KitchenTicketLinesTable, KitchenTicketLineRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KitchenTicketLinesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ticketIdMeta = const VerificationMeta(
    'ticketId',
  );
  @override
  late final GeneratedColumn<String> ticketId = GeneratedColumn<String>(
    'ticket_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES kitchen_tickets (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _orderLineIdMeta = const VerificationMeta(
    'orderLineId',
  );
  @override
  late final GeneratedColumn<String> orderLineId = GeneratedColumn<String>(
    'order_line_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES order_lines (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<int> qty = GeneratedColumn<int>(
    'qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addonsTextMeta = const VerificationMeta(
    'addonsText',
  );
  @override
  late final GeneratedColumn<String> addonsText = GeneratedColumn<String>(
    'addons_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ticketId,
    orderLineId,
    qty,
    itemName,
    addonsText,
    notes,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kitchen_ticket_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<KitchenTicketLineRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ticket_id')) {
      context.handle(
        _ticketIdMeta,
        ticketId.isAcceptableOrUnknown(data['ticket_id']!, _ticketIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ticketIdMeta);
    }
    if (data.containsKey('order_line_id')) {
      context.handle(
        _orderLineIdMeta,
        orderLineId.isAcceptableOrUnknown(
          data['order_line_id']!,
          _orderLineIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderLineIdMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('addons_text')) {
      context.handle(
        _addonsTextMeta,
        addonsText.isAcceptableOrUnknown(data['addons_text']!, _addonsTextMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KitchenTicketLineRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KitchenTicketLineRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ticketId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_id'],
      )!,
      orderLineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_line_id'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}qty'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      addonsText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}addons_text'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $KitchenTicketLinesTable createAlias(String alias) {
    return $KitchenTicketLinesTable(attachedDatabase, alias);
  }
}

class KitchenTicketLineRow extends DataClass
    implements Insertable<KitchenTicketLineRow> {
  final String id;
  final String ticketId;
  final String orderLineId;
  final int qty;

  /// Printed text, copied at send time.
  final String itemName;
  final String addonsText;
  final String notes;
  final int sortOrder;
  const KitchenTicketLineRow({
    required this.id,
    required this.ticketId,
    required this.orderLineId,
    required this.qty,
    required this.itemName,
    required this.addonsText,
    required this.notes,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ticket_id'] = Variable<String>(ticketId);
    map['order_line_id'] = Variable<String>(orderLineId);
    map['qty'] = Variable<int>(qty);
    map['item_name'] = Variable<String>(itemName);
    map['addons_text'] = Variable<String>(addonsText);
    map['notes'] = Variable<String>(notes);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  KitchenTicketLinesCompanion toCompanion(bool nullToAbsent) {
    return KitchenTicketLinesCompanion(
      id: Value(id),
      ticketId: Value(ticketId),
      orderLineId: Value(orderLineId),
      qty: Value(qty),
      itemName: Value(itemName),
      addonsText: Value(addonsText),
      notes: Value(notes),
      sortOrder: Value(sortOrder),
    );
  }

  factory KitchenTicketLineRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KitchenTicketLineRow(
      id: serializer.fromJson<String>(json['id']),
      ticketId: serializer.fromJson<String>(json['ticketId']),
      orderLineId: serializer.fromJson<String>(json['orderLineId']),
      qty: serializer.fromJson<int>(json['qty']),
      itemName: serializer.fromJson<String>(json['itemName']),
      addonsText: serializer.fromJson<String>(json['addonsText']),
      notes: serializer.fromJson<String>(json['notes']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ticketId': serializer.toJson<String>(ticketId),
      'orderLineId': serializer.toJson<String>(orderLineId),
      'qty': serializer.toJson<int>(qty),
      'itemName': serializer.toJson<String>(itemName),
      'addonsText': serializer.toJson<String>(addonsText),
      'notes': serializer.toJson<String>(notes),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  KitchenTicketLineRow copyWith({
    String? id,
    String? ticketId,
    String? orderLineId,
    int? qty,
    String? itemName,
    String? addonsText,
    String? notes,
    int? sortOrder,
  }) => KitchenTicketLineRow(
    id: id ?? this.id,
    ticketId: ticketId ?? this.ticketId,
    orderLineId: orderLineId ?? this.orderLineId,
    qty: qty ?? this.qty,
    itemName: itemName ?? this.itemName,
    addonsText: addonsText ?? this.addonsText,
    notes: notes ?? this.notes,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  KitchenTicketLineRow copyWithCompanion(KitchenTicketLinesCompanion data) {
    return KitchenTicketLineRow(
      id: data.id.present ? data.id.value : this.id,
      ticketId: data.ticketId.present ? data.ticketId.value : this.ticketId,
      orderLineId: data.orderLineId.present
          ? data.orderLineId.value
          : this.orderLineId,
      qty: data.qty.present ? data.qty.value : this.qty,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      addonsText: data.addonsText.present
          ? data.addonsText.value
          : this.addonsText,
      notes: data.notes.present ? data.notes.value : this.notes,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KitchenTicketLineRow(')
          ..write('id: $id, ')
          ..write('ticketId: $ticketId, ')
          ..write('orderLineId: $orderLineId, ')
          ..write('qty: $qty, ')
          ..write('itemName: $itemName, ')
          ..write('addonsText: $addonsText, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ticketId,
    orderLineId,
    qty,
    itemName,
    addonsText,
    notes,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KitchenTicketLineRow &&
          other.id == this.id &&
          other.ticketId == this.ticketId &&
          other.orderLineId == this.orderLineId &&
          other.qty == this.qty &&
          other.itemName == this.itemName &&
          other.addonsText == this.addonsText &&
          other.notes == this.notes &&
          other.sortOrder == this.sortOrder);
}

class KitchenTicketLinesCompanion
    extends UpdateCompanion<KitchenTicketLineRow> {
  final Value<String> id;
  final Value<String> ticketId;
  final Value<String> orderLineId;
  final Value<int> qty;
  final Value<String> itemName;
  final Value<String> addonsText;
  final Value<String> notes;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const KitchenTicketLinesCompanion({
    this.id = const Value.absent(),
    this.ticketId = const Value.absent(),
    this.orderLineId = const Value.absent(),
    this.qty = const Value.absent(),
    this.itemName = const Value.absent(),
    this.addonsText = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KitchenTicketLinesCompanion.insert({
    required String id,
    required String ticketId,
    required String orderLineId,
    required int qty,
    required String itemName,
    this.addonsText = const Value.absent(),
    this.notes = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ticketId = Value(ticketId),
       orderLineId = Value(orderLineId),
       qty = Value(qty),
       itemName = Value(itemName);
  static Insertable<KitchenTicketLineRow> custom({
    Expression<String>? id,
    Expression<String>? ticketId,
    Expression<String>? orderLineId,
    Expression<int>? qty,
    Expression<String>? itemName,
    Expression<String>? addonsText,
    Expression<String>? notes,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ticketId != null) 'ticket_id': ticketId,
      if (orderLineId != null) 'order_line_id': orderLineId,
      if (qty != null) 'qty': qty,
      if (itemName != null) 'item_name': itemName,
      if (addonsText != null) 'addons_text': addonsText,
      if (notes != null) 'notes': notes,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KitchenTicketLinesCompanion copyWith({
    Value<String>? id,
    Value<String>? ticketId,
    Value<String>? orderLineId,
    Value<int>? qty,
    Value<String>? itemName,
    Value<String>? addonsText,
    Value<String>? notes,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return KitchenTicketLinesCompanion(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      orderLineId: orderLineId ?? this.orderLineId,
      qty: qty ?? this.qty,
      itemName: itemName ?? this.itemName,
      addonsText: addonsText ?? this.addonsText,
      notes: notes ?? this.notes,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ticketId.present) {
      map['ticket_id'] = Variable<String>(ticketId.value);
    }
    if (orderLineId.present) {
      map['order_line_id'] = Variable<String>(orderLineId.value);
    }
    if (qty.present) {
      map['qty'] = Variable<int>(qty.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (addonsText.present) {
      map['addons_text'] = Variable<String>(addonsText.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KitchenTicketLinesCompanion(')
          ..write('id: $id, ')
          ..write('ticketId: $ticketId, ')
          ..write('orderLineId: $orderLineId, ')
          ..write('qty: $qty, ')
          ..write('itemName: $itemName, ')
          ..write('addonsText: $addonsText, ')
          ..write('notes: $notes, ')
          ..write('sortOrder: $sortOrder, ')
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
  late final $TaxProfilesTable taxProfiles = $TaxProfilesTable(this);
  late final $KitchenStationsTable kitchenStations = $KitchenStationsTable(
    this,
  );
  late final $MenuCategoriesTable menuCategories = $MenuCategoriesTable(this);
  late final $MenuItemsTable menuItems = $MenuItemsTable(this);
  late final $OptionGroupsTable optionGroups = $OptionGroupsTable(this);
  late final $OptionChoicesTable optionChoices = $OptionChoicesTable(this);
  late final $ItemOptionGroupsTable itemOptionGroups = $ItemOptionGroupsTable(
    this,
  );
  late final $DiningAreasTable diningAreas = $DiningAreasTable(this);
  late final $RestaurantTablesTable restaurantTables = $RestaurantTablesTable(
    this,
  );
  late final $OrdersTable orders = $OrdersTable(this);
  late final $OrderLinesTable orderLines = $OrderLinesTable(this);
  late final $OrderLineOptionsTable orderLineOptions = $OrderLineOptionsTable(
    this,
  );
  late final $StationPrintersTable stationPrinters = $StationPrintersTable(
    this,
  );
  late final $KitchenTicketsTable kitchenTickets = $KitchenTicketsTable(this);
  late final $KitchenTicketLinesTable kitchenTicketLines =
      $KitchenTicketLinesTable(this);
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
  late final Index idxMenuCategoriesParent = Index(
    'idx_menu_categories_parent',
    'CREATE INDEX idx_menu_categories_parent ON menu_categories (parent_id)',
  );
  late final Index idxMenuItemsCategory = Index(
    'idx_menu_items_category',
    'CREATE INDEX idx_menu_items_category ON menu_items (category_id)',
  );
  late final Index idxMenuItemsSku = Index(
    'idx_menu_items_sku',
    'CREATE INDEX idx_menu_items_sku ON menu_items (sku)',
  );
  late final Index idxOptionChoicesGroup = Index(
    'idx_option_choices_group',
    'CREATE INDEX idx_option_choices_group ON option_choices (group_id)',
  );
  late final Index idxRestaurantTablesArea = Index(
    'idx_restaurant_tables_area',
    'CREATE INDEX idx_restaurant_tables_area ON restaurant_tables (area_id)',
  );
  late final Index idxOrdersStatus = Index(
    'idx_orders_status',
    'CREATE INDEX idx_orders_status ON orders (status)',
  );
  late final Index idxOrdersBusinessDate = Index(
    'idx_orders_business_date',
    'CREATE INDEX idx_orders_business_date ON orders (business_date)',
  );
  late final Index idxOrdersTable = Index(
    'idx_orders_table',
    'CREATE INDEX idx_orders_table ON orders (table_id)',
  );
  late final Index idxOrdersDayNumber = Index(
    'idx_orders_day_number',
    'CREATE UNIQUE INDEX idx_orders_day_number ON orders (business_date, order_no)',
  );
  late final Index idxOrderLinesOrder = Index(
    'idx_order_lines_order',
    'CREATE INDEX idx_order_lines_order ON order_lines (order_id)',
  );
  late final Index idxOrderLineOptionsLine = Index(
    'idx_order_line_options_line',
    'CREATE INDEX idx_order_line_options_line ON order_line_options (line_id)',
  );
  late final Index idxKitchenTicketsOrder = Index(
    'idx_kitchen_tickets_order',
    'CREATE INDEX idx_kitchen_tickets_order ON kitchen_tickets (order_id)',
  );
  late final Index idxKitchenTicketLinesTicket = Index(
    'idx_kitchen_ticket_lines_ticket',
    'CREATE INDEX idx_kitchen_ticket_lines_ticket ON kitchen_ticket_lines (ticket_id)',
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
    taxProfiles,
    kitchenStations,
    menuCategories,
    menuItems,
    optionGroups,
    optionChoices,
    itemOptionGroups,
    diningAreas,
    restaurantTables,
    orders,
    orderLines,
    orderLineOptions,
    stationPrinters,
    kitchenTickets,
    kitchenTicketLines,
    idxPrintJobsStatus,
    idxPrintJobsSourceKey,
    idxPrintHistoryAt,
    idxAuditLogAt,
    idxMenuCategoriesParent,
    idxMenuItemsCategory,
    idxMenuItemsSku,
    idxOptionChoicesGroup,
    idxRestaurantTablesArea,
    idxOrdersStatus,
    idxOrdersBusinessDate,
    idxOrdersTable,
    idxOrdersDayNumber,
    idxOrderLinesOrder,
    idxOrderLineOptionsLine,
    idxKitchenTicketsOrder,
    idxKitchenTicketLinesTicket,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'menu_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('item_option_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'order_lines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('order_line_options', kind: UpdateKind.delete)],
    ),
  ]);
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
      Value<int?> printableDots,
      Value<int?> charsPerLine,
      Value<int?> rasterThreshold,
      Value<int?> feedLines,
      Value<bool> autoCut,
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
      Value<int?> printableDots,
      Value<int?> charsPerLine,
      Value<int?> rasterThreshold,
      Value<int?> feedLines,
      Value<bool> autoCut,
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

  ColumnFilters<int> get printableDots => $composableBuilder(
    column: $table.printableDots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get charsPerLine => $composableBuilder(
    column: $table.charsPerLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rasterThreshold => $composableBuilder(
    column: $table.rasterThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedLines => $composableBuilder(
    column: $table.feedLines,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoCut => $composableBuilder(
    column: $table.autoCut,
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

  ColumnOrderings<int> get printableDots => $composableBuilder(
    column: $table.printableDots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get charsPerLine => $composableBuilder(
    column: $table.charsPerLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rasterThreshold => $composableBuilder(
    column: $table.rasterThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedLines => $composableBuilder(
    column: $table.feedLines,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoCut => $composableBuilder(
    column: $table.autoCut,
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

  GeneratedColumn<int> get printableDots => $composableBuilder(
    column: $table.printableDots,
    builder: (column) => column,
  );

  GeneratedColumn<int> get charsPerLine => $composableBuilder(
    column: $table.charsPerLine,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rasterThreshold => $composableBuilder(
    column: $table.rasterThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<int> get feedLines =>
      $composableBuilder(column: $table.feedLines, builder: (column) => column);

  GeneratedColumn<bool> get autoCut =>
      $composableBuilder(column: $table.autoCut, builder: (column) => column);

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
                Value<int?> printableDots = const Value.absent(),
                Value<int?> charsPerLine = const Value.absent(),
                Value<int?> rasterThreshold = const Value.absent(),
                Value<int?> feedLines = const Value.absent(),
                Value<bool> autoCut = const Value.absent(),
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
                printableDots: printableDots,
                charsPerLine: charsPerLine,
                rasterThreshold: rasterThreshold,
                feedLines: feedLines,
                autoCut: autoCut,
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
                Value<int?> printableDots = const Value.absent(),
                Value<int?> charsPerLine = const Value.absent(),
                Value<int?> rasterThreshold = const Value.absent(),
                Value<int?> feedLines = const Value.absent(),
                Value<bool> autoCut = const Value.absent(),
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
                printableDots: printableDots,
                charsPerLine: charsPerLine,
                rasterThreshold: rasterThreshold,
                feedLines: feedLines,
                autoCut: autoCut,
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
typedef $$TaxProfilesTableCreateCompanionBuilder =
    TaxProfilesCompanion Function({
      required String id,
      required String name,
      required int rateBp,
      Value<bool> isInclusive,
      Value<String> splitMode,
      Value<bool> isActive,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$TaxProfilesTableUpdateCompanionBuilder =
    TaxProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> rateBp,
      Value<bool> isInclusive,
      Value<String> splitMode,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$TaxProfilesTableReferences
    extends BaseReferences<_$AppDatabase, $TaxProfilesTable, TaxProfileRow> {
  $$TaxProfilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MenuItemsTable, List<MenuItemRow>>
  _menuItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.menuItems,
    aliasName: 'tax_profiles__id__menu_items__tax_profile_id',
  );

  $$MenuItemsTableProcessedTableManager get menuItemsRefs {
    final manager = $$MenuItemsTableTableManager(
      $_db,
      $_db.menuItems,
    ).filter((f) => f.taxProfileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_menuItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaxProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $TaxProfilesTable> {
  $$TaxProfilesTableFilterComposer({
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

  ColumnFilters<int> get rateBp => $composableBuilder(
    column: $table.rateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInclusive => $composableBuilder(
    column: $table.isInclusive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitMode => $composableBuilder(
    column: $table.splitMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  Expression<bool> menuItemsRefs(
    Expression<bool> Function($$MenuItemsTableFilterComposer f) f,
  ) {
    final $$MenuItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.taxProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableFilterComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaxProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $TaxProfilesTable> {
  $$TaxProfilesTableOrderingComposer({
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

  ColumnOrderings<int> get rateBp => $composableBuilder(
    column: $table.rateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInclusive => $composableBuilder(
    column: $table.isInclusive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitMode => $composableBuilder(
    column: $table.splitMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

class $$TaxProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaxProfilesTable> {
  $$TaxProfilesTableAnnotationComposer({
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

  GeneratedColumn<int> get rateBp =>
      $composableBuilder(column: $table.rateBp, builder: (column) => column);

  GeneratedColumn<bool> get isInclusive => $composableBuilder(
    column: $table.isInclusive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get splitMode =>
      $composableBuilder(column: $table.splitMode, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> menuItemsRefs<T extends Object>(
    Expression<T> Function($$MenuItemsTableAnnotationComposer a) f,
  ) {
    final $$MenuItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.taxProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaxProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaxProfilesTable,
          TaxProfileRow,
          $$TaxProfilesTableFilterComposer,
          $$TaxProfilesTableOrderingComposer,
          $$TaxProfilesTableAnnotationComposer,
          $$TaxProfilesTableCreateCompanionBuilder,
          $$TaxProfilesTableUpdateCompanionBuilder,
          (TaxProfileRow, $$TaxProfilesTableReferences),
          TaxProfileRow,
          PrefetchHooks Function({bool menuItemsRefs})
        > {
  $$TaxProfilesTableTableManager(_$AppDatabase db, $TaxProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaxProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaxProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaxProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rateBp = const Value.absent(),
                Value<bool> isInclusive = const Value.absent(),
                Value<String> splitMode = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaxProfilesCompanion(
                id: id,
                name: name,
                rateBp: rateBp,
                isInclusive: isInclusive,
                splitMode: splitMode,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int rateBp,
                Value<bool> isInclusive = const Value.absent(),
                Value<String> splitMode = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TaxProfilesCompanion.insert(
                id: id,
                name: name,
                rateBp: rateBp,
                isInclusive: isInclusive,
                splitMode: splitMode,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaxProfilesTable, TaxProfileRow>(table),
                  $$TaxProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({menuItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (menuItemsRefs) db.menuItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (menuItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      TaxProfileRow,
                      $TaxProfilesTable,
                      MenuItemRow,
                      $MenuItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$TaxProfilesTableReferences
                          ._menuItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TaxProfilesTableReferences(
                            db,
                            table,
                            p0,
                          ).menuItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'tax_profile_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TaxProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaxProfilesTable,
      TaxProfileRow,
      $$TaxProfilesTableFilterComposer,
      $$TaxProfilesTableOrderingComposer,
      $$TaxProfilesTableAnnotationComposer,
      $$TaxProfilesTableCreateCompanionBuilder,
      $$TaxProfilesTableUpdateCompanionBuilder,
      (TaxProfileRow, $$TaxProfilesTableReferences),
      TaxProfileRow,
      PrefetchHooks Function({bool menuItemsRefs})
    >;
typedef $$KitchenStationsTableCreateCompanionBuilder =
    KitchenStationsCompanion Function({
      required String id,
      required String name,
      Value<bool> isActive,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$KitchenStationsTableUpdateCompanionBuilder =
    KitchenStationsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$KitchenStationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $KitchenStationsTable,
          KitchenStationRow
        > {
  $$KitchenStationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$MenuItemsTable, List<MenuItemRow>>
  _menuItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.menuItems,
    aliasName: 'kitchen_stations__id__menu_items__station_id',
  );

  $$MenuItemsTableProcessedTableManager get menuItemsRefs {
    final manager = $$MenuItemsTableTableManager(
      $_db,
      $_db.menuItems,
    ).filter((f) => f.stationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_menuItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KitchenStationsTableFilterComposer
    extends Composer<_$AppDatabase, $KitchenStationsTable> {
  $$KitchenStationsTableFilterComposer({
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

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  Expression<bool> menuItemsRefs(
    Expression<bool> Function($$MenuItemsTableFilterComposer f) f,
  ) {
    final $$MenuItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.stationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableFilterComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KitchenStationsTableOrderingComposer
    extends Composer<_$AppDatabase, $KitchenStationsTable> {
  $$KitchenStationsTableOrderingComposer({
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

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

class $$KitchenStationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KitchenStationsTable> {
  $$KitchenStationsTableAnnotationComposer({
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

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> menuItemsRefs<T extends Object>(
    Expression<T> Function($$MenuItemsTableAnnotationComposer a) f,
  ) {
    final $$MenuItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.stationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KitchenStationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KitchenStationsTable,
          KitchenStationRow,
          $$KitchenStationsTableFilterComposer,
          $$KitchenStationsTableOrderingComposer,
          $$KitchenStationsTableAnnotationComposer,
          $$KitchenStationsTableCreateCompanionBuilder,
          $$KitchenStationsTableUpdateCompanionBuilder,
          (KitchenStationRow, $$KitchenStationsTableReferences),
          KitchenStationRow,
          PrefetchHooks Function({bool menuItemsRefs})
        > {
  $$KitchenStationsTableTableManager(
    _$AppDatabase db,
    $KitchenStationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KitchenStationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KitchenStationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KitchenStationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KitchenStationsCompanion(
                id: id,
                name: name,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => KitchenStationsCompanion.insert(
                id: id,
                name: name,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KitchenStationsTable, KitchenStationRow>(table),
                  $$KitchenStationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({menuItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (menuItemsRefs) db.menuItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (menuItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      KitchenStationRow,
                      $KitchenStationsTable,
                      MenuItemRow,
                      $MenuItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$KitchenStationsTableReferences
                          ._menuItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$KitchenStationsTableReferences(
                            db,
                            table,
                            p0,
                          ).menuItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'station_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$KitchenStationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KitchenStationsTable,
      KitchenStationRow,
      $$KitchenStationsTableFilterComposer,
      $$KitchenStationsTableOrderingComposer,
      $$KitchenStationsTableAnnotationComposer,
      $$KitchenStationsTableCreateCompanionBuilder,
      $$KitchenStationsTableUpdateCompanionBuilder,
      (KitchenStationRow, $$KitchenStationsTableReferences),
      KitchenStationRow,
      PrefetchHooks Function({bool menuItemsRefs})
    >;
typedef $$MenuCategoriesTableCreateCompanionBuilder =
    MenuCategoriesCompanion Function({
      required String id,
      required String name,
      Value<String?> parentId,
      Value<bool> isActive,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$MenuCategoriesTableUpdateCompanionBuilder =
    MenuCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$MenuCategoriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $MenuCategoriesTable, MenuCategoryRow> {
  $$MenuCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MenuCategoriesTable _parentIdTable(_$AppDatabase db) => db
      .menuCategories
      .createAlias('menu_categories__parent_id__menu_categories__id');

  $$MenuCategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$MenuCategoriesTableTableManager(
      $_db,
      $_db.menuCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$MenuItemsTable, List<MenuItemRow>>
  _menuItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.menuItems,
    aliasName: 'menu_categories__id__menu_items__category_id',
  );

  $$MenuItemsTableProcessedTableManager get menuItemsRefs {
    final manager = $$MenuItemsTableTableManager(
      $_db,
      $_db.menuItems,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_menuItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MenuCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $MenuCategoriesTable> {
  $$MenuCategoriesTableFilterComposer({
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

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  $$MenuCategoriesTableFilterComposer get parentId {
    final $$MenuCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.menuCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.menuCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> menuItemsRefs(
    Expression<bool> Function($$MenuItemsTableFilterComposer f) f,
  ) {
    final $$MenuItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableFilterComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MenuCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuCategoriesTable> {
  $$MenuCategoriesTableOrderingComposer({
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

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  $$MenuCategoriesTableOrderingComposer get parentId {
    final $$MenuCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.menuCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.menuCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuCategoriesTable> {
  $$MenuCategoriesTableAnnotationComposer({
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

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MenuCategoriesTableAnnotationComposer get parentId {
    final $$MenuCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.menuCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.menuCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> menuItemsRefs<T extends Object>(
    Expression<T> Function($$MenuItemsTableAnnotationComposer a) f,
  ) {
    final $$MenuItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MenuCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuCategoriesTable,
          MenuCategoryRow,
          $$MenuCategoriesTableFilterComposer,
          $$MenuCategoriesTableOrderingComposer,
          $$MenuCategoriesTableAnnotationComposer,
          $$MenuCategoriesTableCreateCompanionBuilder,
          $$MenuCategoriesTableUpdateCompanionBuilder,
          (MenuCategoryRow, $$MenuCategoriesTableReferences),
          MenuCategoryRow,
          PrefetchHooks Function({bool parentId, bool menuItemsRefs})
        > {
  $$MenuCategoriesTableTableManager(
    _$AppDatabase db,
    $MenuCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuCategoriesCompanion(
                id: id,
                name: name,
                parentId: parentId,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MenuCategoriesCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MenuCategoriesTable, MenuCategoryRow>(table),
                  $$MenuCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false, menuItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (menuItemsRefs) db.menuItems],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parentId,
                        referencedTable: $$MenuCategoriesTableReferences
                            ._parentIdTable(db),
                        referencedColumn: $$MenuCategoriesTableReferences
                            ._parentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (menuItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      MenuCategoryRow,
                      $MenuCategoriesTable,
                      MenuItemRow,
                      $MenuItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$MenuCategoriesTableReferences
                          ._menuItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MenuCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).menuItemsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'category_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MenuCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuCategoriesTable,
      MenuCategoryRow,
      $$MenuCategoriesTableFilterComposer,
      $$MenuCategoriesTableOrderingComposer,
      $$MenuCategoriesTableAnnotationComposer,
      $$MenuCategoriesTableCreateCompanionBuilder,
      $$MenuCategoriesTableUpdateCompanionBuilder,
      (MenuCategoryRow, $$MenuCategoriesTableReferences),
      MenuCategoryRow,
      PrefetchHooks Function({bool parentId, bool menuItemsRefs})
    >;
typedef $$MenuItemsTableCreateCompanionBuilder = MenuItemsCompanion Function({
  required String id,
  required String categoryId,
  required String name,
  Value<String> description,
  Value<String?> sku,
  required int basePricePaise,
  Value<String?> taxProfileId,
  Value<String> foodType,
  Value<bool> isActive,
  Value<bool> availableDineIn,
  Value<bool> availableTakeaway,
  Value<String?> stationId,
  Value<bool> isFavorite,
  Value<int?> prepMinutes,
  Value<String?> imagePath,
  Value<int> sortOrder,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$MenuItemsTableUpdateCompanionBuilder = MenuItemsCompanion Function({
  Value<String> id,
  Value<String> categoryId,
  Value<String> name,
  Value<String> description,
  Value<String?> sku,
  Value<int> basePricePaise,
  Value<String?> taxProfileId,
  Value<String> foodType,
  Value<bool> isActive,
  Value<bool> availableDineIn,
  Value<bool> availableTakeaway,
  Value<String?> stationId,
  Value<bool> isFavorite,
  Value<int?> prepMinutes,
  Value<String?> imagePath,
  Value<int> sortOrder,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$MenuItemsTableReferences
    extends BaseReferences<_$AppDatabase, $MenuItemsTable, MenuItemRow> {
  $$MenuItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MenuCategoriesTable _categoryIdTable(_$AppDatabase db) => db
      .menuCategories
      .createAlias('menu_items__category_id__menu_categories__id');

  $$MenuCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$MenuCategoriesTableTableManager(
      $_db,
      $_db.menuCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TaxProfilesTable _taxProfileIdTable(_$AppDatabase db) => db
      .taxProfiles
      .createAlias('menu_items__tax_profile_id__tax_profiles__id');

  $$TaxProfilesTableProcessedTableManager? get taxProfileId {
    final $_column = $_itemColumn<String>('tax_profile_id');
    if ($_column == null) return null;
    final manager = $$TaxProfilesTableTableManager(
      $_db,
      $_db.taxProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taxProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $KitchenStationsTable _stationIdTable(_$AppDatabase db) => db
      .kitchenStations
      .createAlias('menu_items__station_id__kitchen_stations__id');

  $$KitchenStationsTableProcessedTableManager? get stationId {
    final $_column = $_itemColumn<String>('station_id');
    if ($_column == null) return null;
    final manager = $$KitchenStationsTableTableManager(
      $_db,
      $_db.kitchenStations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_stationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemOptionGroupsTable, List<ItemOptionGroupRow>>
  _itemOptionGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemOptionGroups,
    aliasName: 'menu_items__id__item_option_groups__item_id',
  );

  $$ItemOptionGroupsTableProcessedTableManager get itemOptionGroupsRefs {
    final manager = $$ItemOptionGroupsTableTableManager(
      $_db,
      $_db.itemOptionGroups,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itemOptionGroupsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OrderLinesTable, List<OrderLineRow>>
  _orderLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.orderLines,
    aliasName: 'menu_items__id__order_lines__menu_item_id',
  );

  $$OrderLinesTableProcessedTableManager get orderLinesRefs {
    final manager = $$OrderLinesTableTableManager(
      $_db,
      $_db.orderLines,
    ).filter((f) => f.menuItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MenuItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get basePricePaise => $composableBuilder(
    column: $table.basePricePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodType => $composableBuilder(
    column: $table.foodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get availableDineIn => $composableBuilder(
    column: $table.availableDineIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get availableTakeaway => $composableBuilder(
    column: $table.availableTakeaway,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
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

  $$MenuCategoriesTableFilterComposer get categoryId {
    final $$MenuCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.menuCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.menuCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TaxProfilesTableFilterComposer get taxProfileId {
    final $$TaxProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taxProfileId,
      referencedTable: $db.taxProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaxProfilesTableFilterComposer(
            $db: $db,
            $table: $db.taxProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KitchenStationsTableFilterComposer get stationId {
    final $$KitchenStationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stationId,
      referencedTable: $db.kitchenStations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenStationsTableFilterComposer(
            $db: $db,
            $table: $db.kitchenStations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemOptionGroupsRefs(
    Expression<bool> Function($$ItemOptionGroupsTableFilterComposer f) f,
  ) {
    final $$ItemOptionGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemOptionGroups,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemOptionGroupsTableFilterComposer(
            $db: $db,
            $table: $db.itemOptionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> orderLinesRefs(
    Expression<bool> Function($$OrderLinesTableFilterComposer f) f,
  ) {
    final $$OrderLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.menuItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableFilterComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MenuItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get basePricePaise => $composableBuilder(
    column: $table.basePricePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodType => $composableBuilder(
    column: $table.foodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get availableDineIn => $composableBuilder(
    column: $table.availableDineIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get availableTakeaway => $composableBuilder(
    column: $table.availableTakeaway,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
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

  $$MenuCategoriesTableOrderingComposer get categoryId {
    final $$MenuCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.menuCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.menuCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TaxProfilesTableOrderingComposer get taxProfileId {
    final $$TaxProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taxProfileId,
      referencedTable: $db.taxProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaxProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.taxProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KitchenStationsTableOrderingComposer get stationId {
    final $$KitchenStationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stationId,
      referencedTable: $db.kitchenStations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenStationsTableOrderingComposer(
            $db: $db,
            $table: $db.kitchenStations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MenuItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MenuItemsTable> {
  $$MenuItemsTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<int> get basePricePaise => $composableBuilder(
    column: $table.basePricePaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get foodType =>
      $composableBuilder(column: $table.foodType, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get availableDineIn => $composableBuilder(
    column: $table.availableDineIn,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get availableTakeaway => $composableBuilder(
    column: $table.availableTakeaway,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MenuCategoriesTableAnnotationComposer get categoryId {
    final $$MenuCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.menuCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.menuCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TaxProfilesTableAnnotationComposer get taxProfileId {
    final $$TaxProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taxProfileId,
      referencedTable: $db.taxProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaxProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.taxProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$KitchenStationsTableAnnotationComposer get stationId {
    final $$KitchenStationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.stationId,
      referencedTable: $db.kitchenStations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenStationsTableAnnotationComposer(
            $db: $db,
            $table: $db.kitchenStations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemOptionGroupsRefs<T extends Object>(
    Expression<T> Function($$ItemOptionGroupsTableAnnotationComposer a) f,
  ) {
    final $$ItemOptionGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemOptionGroups,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemOptionGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemOptionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> orderLinesRefs<T extends Object>(
    Expression<T> Function($$OrderLinesTableAnnotationComposer a) f,
  ) {
    final $$OrderLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.menuItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MenuItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MenuItemsTable,
          MenuItemRow,
          $$MenuItemsTableFilterComposer,
          $$MenuItemsTableOrderingComposer,
          $$MenuItemsTableAnnotationComposer,
          $$MenuItemsTableCreateCompanionBuilder,
          $$MenuItemsTableUpdateCompanionBuilder,
          (MenuItemRow, $$MenuItemsTableReferences),
          MenuItemRow,
          PrefetchHooks Function({
            bool categoryId,
            bool taxProfileId,
            bool stationId,
            bool itemOptionGroupsRefs,
            bool orderLinesRefs,
          })
        > {
  $$MenuItemsTableTableManager(_$AppDatabase db, $MenuItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MenuItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MenuItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MenuItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<int> basePricePaise = const Value.absent(),
                Value<String?> taxProfileId = const Value.absent(),
                Value<String> foodType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> availableDineIn = const Value.absent(),
                Value<bool> availableTakeaway = const Value.absent(),
                Value<String?> stationId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion(
                id: id,
                categoryId: categoryId,
                name: name,
                description: description,
                sku: sku,
                basePricePaise: basePricePaise,
                taxProfileId: taxProfileId,
                foodType: foodType,
                isActive: isActive,
                availableDineIn: availableDineIn,
                availableTakeaway: availableTakeaway,
                stationId: stationId,
                isFavorite: isFavorite,
                prepMinutes: prepMinutes,
                imagePath: imagePath,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required String name,
                Value<String> description = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                required int basePricePaise,
                Value<String?> taxProfileId = const Value.absent(),
                Value<String> foodType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> availableDineIn = const Value.absent(),
                Value<bool> availableTakeaway = const Value.absent(),
                Value<String?> stationId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MenuItemsCompanion.insert(
                id: id,
                categoryId: categoryId,
                name: name,
                description: description,
                sku: sku,
                basePricePaise: basePricePaise,
                taxProfileId: taxProfileId,
                foodType: foodType,
                isActive: isActive,
                availableDineIn: availableDineIn,
                availableTakeaway: availableTakeaway,
                stationId: stationId,
                isFavorite: isFavorite,
                prepMinutes: prepMinutes,
                imagePath: imagePath,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MenuItemsTable, MenuItemRow>(table),
                  $$MenuItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                taxProfileId = false,
                stationId = false,
                itemOptionGroupsRefs = false,
                orderLinesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemOptionGroupsRefs) db.itemOptionGroups,
                    if (orderLinesRefs) db.orderLines,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$MenuItemsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$MenuItemsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (taxProfileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.taxProfileId,
                            referencedTable: $$MenuItemsTableReferences
                                ._taxProfileIdTable(db),
                            referencedColumn: $$MenuItemsTableReferences
                                ._taxProfileIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (stationId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.stationId,
                            referencedTable: $$MenuItemsTableReferences
                                ._stationIdTable(db),
                            referencedColumn: $$MenuItemsTableReferences
                                ._stationIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemOptionGroupsRefs)
                        await $_getPrefetchedDataByColumns<
                          MenuItemRow,
                          $MenuItemsTable,
                          ItemOptionGroupRow,
                          $ItemOptionGroupsTable
                        >(
                          currentTable: table,
                          referencedTable: $$MenuItemsTableReferences
                              ._itemOptionGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MenuItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemOptionGroupsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'item_id',
                          typedResults: items,
                        ),
                      if (orderLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          MenuItemRow,
                          $MenuItemsTable,
                          OrderLineRow,
                          $OrderLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MenuItemsTableReferences
                              ._orderLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MenuItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).orderLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'menu_item_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MenuItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MenuItemsTable,
      MenuItemRow,
      $$MenuItemsTableFilterComposer,
      $$MenuItemsTableOrderingComposer,
      $$MenuItemsTableAnnotationComposer,
      $$MenuItemsTableCreateCompanionBuilder,
      $$MenuItemsTableUpdateCompanionBuilder,
      (MenuItemRow, $$MenuItemsTableReferences),
      MenuItemRow,
      PrefetchHooks Function({
        bool categoryId,
        bool taxProfileId,
        bool stationId,
        bool itemOptionGroupsRefs,
        bool orderLinesRefs,
      })
    >;
typedef $$OptionGroupsTableCreateCompanionBuilder =
    OptionGroupsCompanion Function({
      required String id,
      required String name,
      required String kind,
      Value<int> minSelect,
      Value<int> maxSelect,
      Value<bool> isActive,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$OptionGroupsTableUpdateCompanionBuilder =
    OptionGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> kind,
      Value<int> minSelect,
      Value<int> maxSelect,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$OptionGroupsTableReferences
    extends BaseReferences<_$AppDatabase, $OptionGroupsTable, OptionGroupRow> {
  $$OptionGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OptionChoicesTable, List<OptionChoiceRow>>
  _optionChoicesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.optionChoices,
    aliasName: 'option_groups__id__option_choices__group_id',
  );

  $$OptionChoicesTableProcessedTableManager get optionChoicesRefs {
    final manager = $$OptionChoicesTableTableManager(
      $_db,
      $_db.optionChoices,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_optionChoicesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemOptionGroupsTable, List<ItemOptionGroupRow>>
  _itemOptionGroupsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.itemOptionGroups,
    aliasName: 'option_groups__id__item_option_groups__group_id',
  );

  $$ItemOptionGroupsTableProcessedTableManager get itemOptionGroupsRefs {
    final manager = $$ItemOptionGroupsTableTableManager(
      $_db,
      $_db.itemOptionGroups,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _itemOptionGroupsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OptionGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $OptionGroupsTable> {
  $$OptionGroupsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minSelect => $composableBuilder(
    column: $table.minSelect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxSelect => $composableBuilder(
    column: $table.maxSelect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  Expression<bool> optionChoicesRefs(
    Expression<bool> Function($$OptionChoicesTableFilterComposer f) f,
  ) {
    final $$OptionChoicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.optionChoices,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OptionChoicesTableFilterComposer(
            $db: $db,
            $table: $db.optionChoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemOptionGroupsRefs(
    Expression<bool> Function($$ItemOptionGroupsTableFilterComposer f) f,
  ) {
    final $$ItemOptionGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemOptionGroups,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemOptionGroupsTableFilterComposer(
            $db: $db,
            $table: $db.itemOptionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OptionGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $OptionGroupsTable> {
  $$OptionGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minSelect => $composableBuilder(
    column: $table.minSelect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxSelect => $composableBuilder(
    column: $table.maxSelect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

class $$OptionGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OptionGroupsTable> {
  $$OptionGroupsTableAnnotationComposer({
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

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get minSelect =>
      $composableBuilder(column: $table.minSelect, builder: (column) => column);

  GeneratedColumn<int> get maxSelect =>
      $composableBuilder(column: $table.maxSelect, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> optionChoicesRefs<T extends Object>(
    Expression<T> Function($$OptionChoicesTableAnnotationComposer a) f,
  ) {
    final $$OptionChoicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.optionChoices,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OptionChoicesTableAnnotationComposer(
            $db: $db,
            $table: $db.optionChoices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> itemOptionGroupsRefs<T extends Object>(
    Expression<T> Function($$ItemOptionGroupsTableAnnotationComposer a) f,
  ) {
    final $$ItemOptionGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemOptionGroups,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemOptionGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemOptionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OptionGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OptionGroupsTable,
          OptionGroupRow,
          $$OptionGroupsTableFilterComposer,
          $$OptionGroupsTableOrderingComposer,
          $$OptionGroupsTableAnnotationComposer,
          $$OptionGroupsTableCreateCompanionBuilder,
          $$OptionGroupsTableUpdateCompanionBuilder,
          (OptionGroupRow, $$OptionGroupsTableReferences),
          OptionGroupRow,
          PrefetchHooks Function({
            bool optionChoicesRefs,
            bool itemOptionGroupsRefs,
          })
        > {
  $$OptionGroupsTableTableManager(_$AppDatabase db, $OptionGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OptionGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OptionGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OptionGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> minSelect = const Value.absent(),
                Value<int> maxSelect = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OptionGroupsCompanion(
                id: id,
                name: name,
                kind: kind,
                minSelect: minSelect,
                maxSelect: maxSelect,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                Value<int> minSelect = const Value.absent(),
                Value<int> maxSelect = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OptionGroupsCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                minSelect: minSelect,
                maxSelect: maxSelect,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OptionGroupsTable, OptionGroupRow>(table),
                  $$OptionGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({optionChoicesRefs = false, itemOptionGroupsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (optionChoicesRefs) db.optionChoices,
                    if (itemOptionGroupsRefs) db.itemOptionGroups,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (optionChoicesRefs)
                        await $_getPrefetchedDataByColumns<
                          OptionGroupRow,
                          $OptionGroupsTable,
                          OptionChoiceRow,
                          $OptionChoicesTable
                        >(
                          currentTable: table,
                          referencedTable: $$OptionGroupsTableReferences
                              ._optionChoicesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OptionGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).optionChoicesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (itemOptionGroupsRefs)
                        await $_getPrefetchedDataByColumns<
                          OptionGroupRow,
                          $OptionGroupsTable,
                          ItemOptionGroupRow,
                          $ItemOptionGroupsTable
                        >(
                          currentTable: table,
                          referencedTable: $$OptionGroupsTableReferences
                              ._itemOptionGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OptionGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemOptionGroupsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OptionGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OptionGroupsTable,
      OptionGroupRow,
      $$OptionGroupsTableFilterComposer,
      $$OptionGroupsTableOrderingComposer,
      $$OptionGroupsTableAnnotationComposer,
      $$OptionGroupsTableCreateCompanionBuilder,
      $$OptionGroupsTableUpdateCompanionBuilder,
      (OptionGroupRow, $$OptionGroupsTableReferences),
      OptionGroupRow,
      PrefetchHooks Function({
        bool optionChoicesRefs,
        bool itemOptionGroupsRefs,
      })
    >;
typedef $$OptionChoicesTableCreateCompanionBuilder =
    OptionChoicesCompanion Function({
      required String id,
      required String groupId,
      required String name,
      Value<int> priceDeltaPaise,
      Value<bool> isActive,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$OptionChoicesTableUpdateCompanionBuilder =
    OptionChoicesCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> name,
      Value<int> priceDeltaPaise,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$OptionChoicesTableReferences
    extends
        BaseReferences<_$AppDatabase, $OptionChoicesTable, OptionChoiceRow> {
  $$OptionChoicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OptionGroupsTable _groupIdTable(_$AppDatabase db) => db.optionGroups
      .createAlias('option_choices__group_id__option_groups__id');

  $$OptionGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$OptionGroupsTableTableManager(
      $_db,
      $_db.optionGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OptionChoicesTableFilterComposer
    extends Composer<_$AppDatabase, $OptionChoicesTable> {
  $$OptionChoicesTableFilterComposer({
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

  ColumnFilters<int> get priceDeltaPaise => $composableBuilder(
    column: $table.priceDeltaPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  $$OptionGroupsTableFilterComposer get groupId {
    final $$OptionGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.optionGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OptionGroupsTableFilterComposer(
            $db: $db,
            $table: $db.optionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OptionChoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $OptionChoicesTable> {
  $$OptionChoicesTableOrderingComposer({
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

  ColumnOrderings<int> get priceDeltaPaise => $composableBuilder(
    column: $table.priceDeltaPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  $$OptionGroupsTableOrderingComposer get groupId {
    final $$OptionGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.optionGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OptionGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.optionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OptionChoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OptionChoicesTable> {
  $$OptionChoicesTableAnnotationComposer({
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

  GeneratedColumn<int> get priceDeltaPaise => $composableBuilder(
    column: $table.priceDeltaPaise,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$OptionGroupsTableAnnotationComposer get groupId {
    final $$OptionGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.optionGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OptionGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.optionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OptionChoicesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OptionChoicesTable,
          OptionChoiceRow,
          $$OptionChoicesTableFilterComposer,
          $$OptionChoicesTableOrderingComposer,
          $$OptionChoicesTableAnnotationComposer,
          $$OptionChoicesTableCreateCompanionBuilder,
          $$OptionChoicesTableUpdateCompanionBuilder,
          (OptionChoiceRow, $$OptionChoicesTableReferences),
          OptionChoiceRow,
          PrefetchHooks Function({bool groupId})
        > {
  $$OptionChoicesTableTableManager(_$AppDatabase db, $OptionChoicesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OptionChoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OptionChoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OptionChoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> priceDeltaPaise = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OptionChoicesCompanion(
                id: id,
                groupId: groupId,
                name: name,
                priceDeltaPaise: priceDeltaPaise,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String name,
                Value<int> priceDeltaPaise = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OptionChoicesCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                priceDeltaPaise: priceDeltaPaise,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OptionChoicesTable, OptionChoiceRow>(table),
                  $$OptionChoicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$OptionChoicesTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$OptionChoicesTableReferences
                            ._groupIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OptionChoicesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OptionChoicesTable,
      OptionChoiceRow,
      $$OptionChoicesTableFilterComposer,
      $$OptionChoicesTableOrderingComposer,
      $$OptionChoicesTableAnnotationComposer,
      $$OptionChoicesTableCreateCompanionBuilder,
      $$OptionChoicesTableUpdateCompanionBuilder,
      (OptionChoiceRow, $$OptionChoicesTableReferences),
      OptionChoiceRow,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$ItemOptionGroupsTableCreateCompanionBuilder =
    ItemOptionGroupsCompanion Function({
      required String itemId,
      required String groupId,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$ItemOptionGroupsTableUpdateCompanionBuilder =
    ItemOptionGroupsCompanion Function({
      Value<String> itemId,
      Value<String> groupId,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$ItemOptionGroupsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ItemOptionGroupsTable,
          ItemOptionGroupRow
        > {
  $$ItemOptionGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MenuItemsTable _itemIdTable(_$AppDatabase db) =>
      db.menuItems.createAlias('item_option_groups__item_id__menu_items__id');

  $$MenuItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$MenuItemsTableTableManager(
      $_db,
      $_db.menuItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OptionGroupsTable _groupIdTable(_$AppDatabase db) => db.optionGroups
      .createAlias('item_option_groups__group_id__option_groups__id');

  $$OptionGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$OptionGroupsTableTableManager(
      $_db,
      $_db.optionGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemOptionGroupsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemOptionGroupsTable> {
  $$ItemOptionGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$MenuItemsTableFilterComposer get itemId {
    final $$MenuItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableFilterComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OptionGroupsTableFilterComposer get groupId {
    final $$OptionGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.optionGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OptionGroupsTableFilterComposer(
            $db: $db,
            $table: $db.optionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemOptionGroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemOptionGroupsTable> {
  $$ItemOptionGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$MenuItemsTableOrderingComposer get itemId {
    final $$MenuItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableOrderingComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OptionGroupsTableOrderingComposer get groupId {
    final $$OptionGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.optionGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OptionGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.optionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemOptionGroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemOptionGroupsTable> {
  $$ItemOptionGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$MenuItemsTableAnnotationComposer get itemId {
    final $$MenuItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OptionGroupsTableAnnotationComposer get groupId {
    final $$OptionGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.optionGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OptionGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.optionGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemOptionGroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemOptionGroupsTable,
          ItemOptionGroupRow,
          $$ItemOptionGroupsTableFilterComposer,
          $$ItemOptionGroupsTableOrderingComposer,
          $$ItemOptionGroupsTableAnnotationComposer,
          $$ItemOptionGroupsTableCreateCompanionBuilder,
          $$ItemOptionGroupsTableUpdateCompanionBuilder,
          (ItemOptionGroupRow, $$ItemOptionGroupsTableReferences),
          ItemOptionGroupRow,
          PrefetchHooks Function({bool itemId, bool groupId})
        > {
  $$ItemOptionGroupsTableTableManager(
    _$AppDatabase db,
    $ItemOptionGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemOptionGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemOptionGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemOptionGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemOptionGroupsCompanion(
                itemId: itemId,
                groupId: groupId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String groupId,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemOptionGroupsCompanion.insert(
                itemId: itemId,
                groupId: groupId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemOptionGroupsTable, ItemOptionGroupRow>(
                    table,
                  ),
                  $$ItemOptionGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ItemOptionGroupsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ItemOptionGroupsTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$ItemOptionGroupsTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$ItemOptionGroupsTableReferences
                            ._groupIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItemOptionGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemOptionGroupsTable,
      ItemOptionGroupRow,
      $$ItemOptionGroupsTableFilterComposer,
      $$ItemOptionGroupsTableOrderingComposer,
      $$ItemOptionGroupsTableAnnotationComposer,
      $$ItemOptionGroupsTableCreateCompanionBuilder,
      $$ItemOptionGroupsTableUpdateCompanionBuilder,
      (ItemOptionGroupRow, $$ItemOptionGroupsTableReferences),
      ItemOptionGroupRow,
      PrefetchHooks Function({bool itemId, bool groupId})
    >;
typedef $$DiningAreasTableCreateCompanionBuilder =
    DiningAreasCompanion Function({
      required String id,
      required String name,
      Value<bool> isActive,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DiningAreasTableUpdateCompanionBuilder =
    DiningAreasCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$DiningAreasTableReferences
    extends BaseReferences<_$AppDatabase, $DiningAreasTable, DiningAreaRow> {
  $$DiningAreasTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RestaurantTablesTable, List<RestaurantTableRow>>
  _restaurantTablesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.restaurantTables,
    aliasName: 'dining_areas__id__restaurant_tables__area_id',
  );

  $$RestaurantTablesTableProcessedTableManager get restaurantTablesRefs {
    final manager = $$RestaurantTablesTableTableManager(
      $_db,
      $_db.restaurantTables,
    ).filter((f) => f.areaId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _restaurantTablesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DiningAreasTableFilterComposer
    extends Composer<_$AppDatabase, $DiningAreasTable> {
  $$DiningAreasTableFilterComposer({
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

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  Expression<bool> restaurantTablesRefs(
    Expression<bool> Function($$RestaurantTablesTableFilterComposer f) f,
  ) {
    final $$RestaurantTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.restaurantTables,
      getReferencedColumn: (t) => t.areaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RestaurantTablesTableFilterComposer(
            $db: $db,
            $table: $db.restaurantTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiningAreasTableOrderingComposer
    extends Composer<_$AppDatabase, $DiningAreasTable> {
  $$DiningAreasTableOrderingComposer({
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

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

class $$DiningAreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $DiningAreasTable> {
  $$DiningAreasTableAnnotationComposer({
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

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> restaurantTablesRefs<T extends Object>(
    Expression<T> Function($$RestaurantTablesTableAnnotationComposer a) f,
  ) {
    final $$RestaurantTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.restaurantTables,
      getReferencedColumn: (t) => t.areaId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RestaurantTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.restaurantTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DiningAreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DiningAreasTable,
          DiningAreaRow,
          $$DiningAreasTableFilterComposer,
          $$DiningAreasTableOrderingComposer,
          $$DiningAreasTableAnnotationComposer,
          $$DiningAreasTableCreateCompanionBuilder,
          $$DiningAreasTableUpdateCompanionBuilder,
          (DiningAreaRow, $$DiningAreasTableReferences),
          DiningAreaRow,
          PrefetchHooks Function({bool restaurantTablesRefs})
        > {
  $$DiningAreasTableTableManager(_$AppDatabase db, $DiningAreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DiningAreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DiningAreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DiningAreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DiningAreasCompanion(
                id: id,
                name: name,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DiningAreasCompanion.insert(
                id: id,
                name: name,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DiningAreasTable, DiningAreaRow>(table),
                  $$DiningAreasTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({restaurantTablesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (restaurantTablesRefs) db.restaurantTables,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (restaurantTablesRefs)
                    await $_getPrefetchedDataByColumns<
                      DiningAreaRow,
                      $DiningAreasTable,
                      RestaurantTableRow,
                      $RestaurantTablesTable
                    >(
                      currentTable: table,
                      referencedTable: $$DiningAreasTableReferences
                          ._restaurantTablesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DiningAreasTableReferences(
                            db,
                            table,
                            p0,
                          ).restaurantTablesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'area_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DiningAreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DiningAreasTable,
      DiningAreaRow,
      $$DiningAreasTableFilterComposer,
      $$DiningAreasTableOrderingComposer,
      $$DiningAreasTableAnnotationComposer,
      $$DiningAreasTableCreateCompanionBuilder,
      $$DiningAreasTableUpdateCompanionBuilder,
      (DiningAreaRow, $$DiningAreasTableReferences),
      DiningAreaRow,
      PrefetchHooks Function({bool restaurantTablesRefs})
    >;
typedef $$RestaurantTablesTableCreateCompanionBuilder =
    RestaurantTablesCompanion Function({
      required String id,
      required String areaId,
      required String label,
      Value<int?> seats,
      Value<bool> isActive,
      Value<int> sortOrder,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$RestaurantTablesTableUpdateCompanionBuilder =
    RestaurantTablesCompanion Function({
      Value<String> id,
      Value<String> areaId,
      Value<String> label,
      Value<int?> seats,
      Value<bool> isActive,
      Value<int> sortOrder,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$RestaurantTablesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RestaurantTablesTable,
          RestaurantTableRow
        > {
  $$RestaurantTablesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DiningAreasTable _areaIdTable(_$AppDatabase db) => db.diningAreas
      .createAlias('restaurant_tables__area_id__dining_areas__id');

  $$DiningAreasTableProcessedTableManager get areaId {
    final $_column = $_itemColumn<String>('area_id')!;

    final manager = $$DiningAreasTableTableManager(
      $_db,
      $_db.diningAreas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_areaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$OrdersTable, List<OrderRow>> _ordersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.orders,
    aliasName: 'restaurant_tables__id__orders__table_id',
  );

  $$OrdersTableProcessedTableManager get ordersRefs {
    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.tableId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ordersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RestaurantTablesTableFilterComposer
    extends Composer<_$AppDatabase, $RestaurantTablesTable> {
  $$RestaurantTablesTableFilterComposer({
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

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seats => $composableBuilder(
    column: $table.seats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  $$DiningAreasTableFilterComposer get areaId {
    final $$DiningAreasTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.diningAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiningAreasTableFilterComposer(
            $db: $db,
            $table: $db.diningAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ordersRefs(
    Expression<bool> Function($$OrdersTableFilterComposer f) f,
  ) {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.tableId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RestaurantTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $RestaurantTablesTable> {
  $$RestaurantTablesTableOrderingComposer({
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

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seats => $composableBuilder(
    column: $table.seats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  $$DiningAreasTableOrderingComposer get areaId {
    final $$DiningAreasTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.diningAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiningAreasTableOrderingComposer(
            $db: $db,
            $table: $db.diningAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RestaurantTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RestaurantTablesTable> {
  $$RestaurantTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get seats =>
      $composableBuilder(column: $table.seats, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DiningAreasTableAnnotationComposer get areaId {
    final $$DiningAreasTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.areaId,
      referencedTable: $db.diningAreas,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DiningAreasTableAnnotationComposer(
            $db: $db,
            $table: $db.diningAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ordersRefs<T extends Object>(
    Expression<T> Function($$OrdersTableAnnotationComposer a) f,
  ) {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.tableId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RestaurantTablesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RestaurantTablesTable,
          RestaurantTableRow,
          $$RestaurantTablesTableFilterComposer,
          $$RestaurantTablesTableOrderingComposer,
          $$RestaurantTablesTableAnnotationComposer,
          $$RestaurantTablesTableCreateCompanionBuilder,
          $$RestaurantTablesTableUpdateCompanionBuilder,
          (RestaurantTableRow, $$RestaurantTablesTableReferences),
          RestaurantTableRow,
          PrefetchHooks Function({bool areaId, bool ordersRefs})
        > {
  $$RestaurantTablesTableTableManager(
    _$AppDatabase db,
    $RestaurantTablesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RestaurantTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RestaurantTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RestaurantTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> areaId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int?> seats = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RestaurantTablesCompanion(
                id: id,
                areaId: areaId,
                label: label,
                seats: seats,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String areaId,
                required String label,
                Value<int?> seats = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => RestaurantTablesCompanion.insert(
                id: id,
                areaId: areaId,
                label: label,
                seats: seats,
                isActive: isActive,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RestaurantTablesTable, RestaurantTableRow>(
                    table,
                  ),
                  $$RestaurantTablesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({areaId = false, ordersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (ordersRefs) db.orders],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (areaId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.areaId,
                        referencedTable: $$RestaurantTablesTableReferences
                            ._areaIdTable(db),
                        referencedColumn: $$RestaurantTablesTableReferences
                            ._areaIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (ordersRefs)
                    await $_getPrefetchedDataByColumns<
                      RestaurantTableRow,
                      $RestaurantTablesTable,
                      OrderRow,
                      $OrdersTable
                    >(
                      currentTable: table,
                      referencedTable: $$RestaurantTablesTableReferences
                          ._ordersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RestaurantTablesTableReferences(
                            db,
                            table,
                            p0,
                          ).ordersRefs,
                      currentColumn: 'id',
                      referencedColumn: 'table_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RestaurantTablesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RestaurantTablesTable,
      RestaurantTableRow,
      $$RestaurantTablesTableFilterComposer,
      $$RestaurantTablesTableOrderingComposer,
      $$RestaurantTablesTableAnnotationComposer,
      $$RestaurantTablesTableCreateCompanionBuilder,
      $$RestaurantTablesTableUpdateCompanionBuilder,
      (RestaurantTableRow, $$RestaurantTablesTableReferences),
      RestaurantTableRow,
      PrefetchHooks Function({bool areaId, bool ordersRefs})
    >;
typedef $$OrdersTableCreateCompanionBuilder = OrdersCompanion Function({
  required String id,
  required int orderNo,
  required String businessDate,
  required String orderType,
  Value<String?> tableId,
  Value<String> customerName,
  Value<String> customerPhone,
  Value<int?> guests,
  Value<String?> staffId,
  Value<String> staffName,
  required String status,
  Value<String> notes,
  Value<String> discountKind,
  Value<int> discountValue,
  Value<String> discountReason,
  Value<String> cancelReason,
  required String clientRequestId,
  required int createdAt,
  required int updatedAt,
  Value<int?> closedAt,
  Value<int> rowid,
});
typedef $$OrdersTableUpdateCompanionBuilder = OrdersCompanion Function({
  Value<String> id,
  Value<int> orderNo,
  Value<String> businessDate,
  Value<String> orderType,
  Value<String?> tableId,
  Value<String> customerName,
  Value<String> customerPhone,
  Value<int?> guests,
  Value<String?> staffId,
  Value<String> staffName,
  Value<String> status,
  Value<String> notes,
  Value<String> discountKind,
  Value<int> discountValue,
  Value<String> discountReason,
  Value<String> cancelReason,
  Value<String> clientRequestId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int?> closedAt,
  Value<int> rowid,
});

final class $$OrdersTableReferences
    extends BaseReferences<_$AppDatabase, $OrdersTable, OrderRow> {
  $$OrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RestaurantTablesTable _tableIdTable(_$AppDatabase db) => db
      .restaurantTables
      .createAlias('orders__table_id__restaurant_tables__id');

  $$RestaurantTablesTableProcessedTableManager? get tableId {
    final $_column = $_itemColumn<String>('table_id');
    if ($_column == null) return null;
    final manager = $$RestaurantTablesTableTableManager(
      $_db,
      $_db.restaurantTables,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tableIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$OrderLinesTable, List<OrderLineRow>>
  _orderLinesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.orderLines,
    aliasName: 'orders__id__order_lines__order_id',
  );

  $$OrderLinesTableProcessedTableManager get orderLinesRefs {
    final manager = $$OrderLinesTableTableManager(
      $_db,
      $_db.orderLines,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$KitchenTicketsTable, List<KitchenTicketRow>>
  _kitchenTicketsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.kitchenTickets,
    aliasName: 'orders__id__kitchen_tickets__order_id',
  );

  $$KitchenTicketsTableProcessedTableManager get kitchenTicketsRefs {
    final manager = $$KitchenTicketsTableTableManager(
      $_db,
      $_db.kitchenTickets,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_kitchenTicketsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OrdersTableFilterComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableFilterComposer({
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

  ColumnFilters<int> get orderNo => $composableBuilder(
    column: $table.orderNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessDate => $composableBuilder(
    column: $table.businessDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get guests => $composableBuilder(
    column: $table.guests,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staffId => $composableBuilder(
    column: $table.staffId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get staffName => $composableBuilder(
    column: $table.staffName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountKind => $composableBuilder(
    column: $table.discountKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discountReason => $composableBuilder(
    column: $table.discountReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
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

  ColumnFilters<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$RestaurantTablesTableFilterComposer get tableId {
    final $$RestaurantTablesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tableId,
      referencedTable: $db.restaurantTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RestaurantTablesTableFilterComposer(
            $db: $db,
            $table: $db.restaurantTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> orderLinesRefs(
    Expression<bool> Function($$OrderLinesTableFilterComposer f) f,
  ) {
    final $$OrderLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableFilterComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> kitchenTicketsRefs(
    Expression<bool> Function($$KitchenTicketsTableFilterComposer f) f,
  ) {
    final $$KitchenTicketsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kitchenTickets,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenTicketsTableFilterComposer(
            $db: $db,
            $table: $db.kitchenTickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableOrderingComposer({
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

  ColumnOrderings<int> get orderNo => $composableBuilder(
    column: $table.orderNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessDate => $composableBuilder(
    column: $table.businessDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get guests => $composableBuilder(
    column: $table.guests,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staffId => $composableBuilder(
    column: $table.staffId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get staffName => $composableBuilder(
    column: $table.staffName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountKind => $composableBuilder(
    column: $table.discountKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discountReason => $composableBuilder(
    column: $table.discountReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
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

  ColumnOrderings<int> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$RestaurantTablesTableOrderingComposer get tableId {
    final $$RestaurantTablesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tableId,
      referencedTable: $db.restaurantTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RestaurantTablesTableOrderingComposer(
            $db: $db,
            $table: $db.restaurantTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrdersTable> {
  $$OrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderNo =>
      $composableBuilder(column: $table.orderNo, builder: (column) => column);

  GeneratedColumn<String> get businessDate => $composableBuilder(
    column: $table.businessDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
    column: $table.customerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customerPhone => $composableBuilder(
    column: $table.customerPhone,
    builder: (column) => column,
  );

  GeneratedColumn<int> get guests =>
      $composableBuilder(column: $table.guests, builder: (column) => column);

  GeneratedColumn<String> get staffId =>
      $composableBuilder(column: $table.staffId, builder: (column) => column);

  GeneratedColumn<String> get staffName =>
      $composableBuilder(column: $table.staffName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get discountKind => $composableBuilder(
    column: $table.discountKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get discountReason => $composableBuilder(
    column: $table.discountReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cancelReason => $composableBuilder(
    column: $table.cancelReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  $$RestaurantTablesTableAnnotationComposer get tableId {
    final $$RestaurantTablesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tableId,
      referencedTable: $db.restaurantTables,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RestaurantTablesTableAnnotationComposer(
            $db: $db,
            $table: $db.restaurantTables,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> orderLinesRefs<T extends Object>(
    Expression<T> Function($$OrderLinesTableAnnotationComposer a) f,
  ) {
    final $$OrderLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> kitchenTicketsRefs<T extends Object>(
    Expression<T> Function($$KitchenTicketsTableAnnotationComposer a) f,
  ) {
    final $$KitchenTicketsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kitchenTickets,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenTicketsTableAnnotationComposer(
            $db: $db,
            $table: $db.kitchenTickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrdersTable,
          OrderRow,
          $$OrdersTableFilterComposer,
          $$OrdersTableOrderingComposer,
          $$OrdersTableAnnotationComposer,
          $$OrdersTableCreateCompanionBuilder,
          $$OrdersTableUpdateCompanionBuilder,
          (OrderRow, $$OrdersTableReferences),
          OrderRow,
          PrefetchHooks Function({
            bool tableId,
            bool orderLinesRefs,
            bool kitchenTicketsRefs,
          })
        > {
  $$OrdersTableTableManager(_$AppDatabase db, $OrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> orderNo = const Value.absent(),
                Value<String> businessDate = const Value.absent(),
                Value<String> orderType = const Value.absent(),
                Value<String?> tableId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> customerPhone = const Value.absent(),
                Value<int?> guests = const Value.absent(),
                Value<String?> staffId = const Value.absent(),
                Value<String> staffName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String> discountKind = const Value.absent(),
                Value<int> discountValue = const Value.absent(),
                Value<String> discountReason = const Value.absent(),
                Value<String> cancelReason = const Value.absent(),
                Value<String> clientRequestId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> closedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion(
                id: id,
                orderNo: orderNo,
                businessDate: businessDate,
                orderType: orderType,
                tableId: tableId,
                customerName: customerName,
                customerPhone: customerPhone,
                guests: guests,
                staffId: staffId,
                staffName: staffName,
                status: status,
                notes: notes,
                discountKind: discountKind,
                discountValue: discountValue,
                discountReason: discountReason,
                cancelReason: cancelReason,
                clientRequestId: clientRequestId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                closedAt: closedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int orderNo,
                required String businessDate,
                required String orderType,
                Value<String?> tableId = const Value.absent(),
                Value<String> customerName = const Value.absent(),
                Value<String> customerPhone = const Value.absent(),
                Value<int?> guests = const Value.absent(),
                Value<String?> staffId = const Value.absent(),
                Value<String> staffName = const Value.absent(),
                required String status,
                Value<String> notes = const Value.absent(),
                Value<String> discountKind = const Value.absent(),
                Value<int> discountValue = const Value.absent(),
                Value<String> discountReason = const Value.absent(),
                Value<String> cancelReason = const Value.absent(),
                required String clientRequestId,
                required int createdAt,
                required int updatedAt,
                Value<int?> closedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrdersCompanion.insert(
                id: id,
                orderNo: orderNo,
                businessDate: businessDate,
                orderType: orderType,
                tableId: tableId,
                customerName: customerName,
                customerPhone: customerPhone,
                guests: guests,
                staffId: staffId,
                staffName: staffName,
                status: status,
                notes: notes,
                discountKind: discountKind,
                discountValue: discountValue,
                discountReason: discountReason,
                cancelReason: cancelReason,
                clientRequestId: clientRequestId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                closedAt: closedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrdersTable, OrderRow>(table),
                  $$OrdersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tableId = false,
                orderLinesRefs = false,
                kitchenTicketsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (orderLinesRefs) db.orderLines,
                    if (kitchenTicketsRefs) db.kitchenTickets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (tableId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.tableId,
                            referencedTable: $$OrdersTableReferences
                                ._tableIdTable(db),
                            referencedColumn: $$OrdersTableReferences
                                ._tableIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (orderLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          OrderRow,
                          $OrdersTable,
                          OrderLineRow,
                          $OrderLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$OrdersTableReferences
                              ._orderLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OrdersTableReferences(
                                db,
                                table,
                                p0,
                              ).orderLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'order_id',
                          typedResults: items,
                        ),
                      if (kitchenTicketsRefs)
                        await $_getPrefetchedDataByColumns<
                          OrderRow,
                          $OrdersTable,
                          KitchenTicketRow,
                          $KitchenTicketsTable
                        >(
                          currentTable: table,
                          referencedTable: $$OrdersTableReferences
                              ._kitchenTicketsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OrdersTableReferences(
                                db,
                                table,
                                p0,
                              ).kitchenTicketsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'order_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrdersTable,
      OrderRow,
      $$OrdersTableFilterComposer,
      $$OrdersTableOrderingComposer,
      $$OrdersTableAnnotationComposer,
      $$OrdersTableCreateCompanionBuilder,
      $$OrdersTableUpdateCompanionBuilder,
      (OrderRow, $$OrdersTableReferences),
      OrderRow,
      PrefetchHooks Function({
        bool tableId,
        bool orderLinesRefs,
        bool kitchenTicketsRefs,
      })
    >;
typedef $$OrderLinesTableCreateCompanionBuilder = OrderLinesCompanion Function({
  required String id,
  required String orderId,
  Value<String?> menuItemId,
  required String itemName,
  Value<String> variantText,
  required int basePricePaise,
  required int unitPricePaise,
  Value<String?> taxProfileId,
  Value<int> taxRateBp,
  Value<bool> taxInclusive,
  Value<String> taxSplitMode,
  Value<String?> stationId,
  required int qty,
  Value<int> sentQty,
  Value<int> voidedQty,
  Value<String> notes,
  Value<int> sortOrder,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$OrderLinesTableUpdateCompanionBuilder = OrderLinesCompanion Function({
  Value<String> id,
  Value<String> orderId,
  Value<String?> menuItemId,
  Value<String> itemName,
  Value<String> variantText,
  Value<int> basePricePaise,
  Value<int> unitPricePaise,
  Value<String?> taxProfileId,
  Value<int> taxRateBp,
  Value<bool> taxInclusive,
  Value<String> taxSplitMode,
  Value<String?> stationId,
  Value<int> qty,
  Value<int> sentQty,
  Value<int> voidedQty,
  Value<String> notes,
  Value<int> sortOrder,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$OrderLinesTableReferences
    extends BaseReferences<_$AppDatabase, $OrderLinesTable, OrderLineRow> {
  $$OrderLinesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $OrdersTable _orderIdTable(_$AppDatabase db) =>
      db.orders.createAlias('order_lines__order_id__orders__id');

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MenuItemsTable _menuItemIdTable(_$AppDatabase db) =>
      db.menuItems.createAlias('order_lines__menu_item_id__menu_items__id');

  $$MenuItemsTableProcessedTableManager? get menuItemId {
    final $_column = $_itemColumn<String>('menu_item_id');
    if ($_column == null) return null;
    final manager = $$MenuItemsTableTableManager(
      $_db,
      $_db.menuItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_menuItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$OrderLineOptionsTable, List<OrderLineOptionRow>>
  _orderLineOptionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.orderLineOptions,
    aliasName: 'order_lines__id__order_line_options__line_id',
  );

  $$OrderLineOptionsTableProcessedTableManager get orderLineOptionsRefs {
    final manager = $$OrderLineOptionsTableTableManager(
      $_db,
      $_db.orderLineOptions,
    ).filter((f) => f.lineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _orderLineOptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $KitchenTicketLinesTable,
    List<KitchenTicketLineRow>
  >
  _kitchenTicketLinesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.kitchenTicketLines,
        aliasName: 'order_lines__id__kitchen_ticket_lines__order_line_id',
      );

  $$KitchenTicketLinesTableProcessedTableManager get kitchenTicketLinesRefs {
    final manager = $$KitchenTicketLinesTableTableManager(
      $_db,
      $_db.kitchenTicketLines,
    ).filter((f) => f.orderLineId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _kitchenTicketLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OrderLinesTableFilterComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableFilterComposer({
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

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantText => $composableBuilder(
    column: $table.variantText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get basePricePaise => $composableBuilder(
    column: $table.basePricePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPricePaise => $composableBuilder(
    column: $table.unitPricePaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxProfileId => $composableBuilder(
    column: $table.taxProfileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBp => $composableBuilder(
    column: $table.taxRateBp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get taxInclusive => $composableBuilder(
    column: $table.taxInclusive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxSplitMode => $composableBuilder(
    column: $table.taxSplitMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sentQty => $composableBuilder(
    column: $table.sentQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get voidedQty => $composableBuilder(
    column: $table.voidedQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MenuItemsTableFilterComposer get menuItemId {
    final $$MenuItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.menuItemId,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableFilterComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> orderLineOptionsRefs(
    Expression<bool> Function($$OrderLineOptionsTableFilterComposer f) f,
  ) {
    final $$OrderLineOptionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderLineOptions,
      getReferencedColumn: (t) => t.lineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLineOptionsTableFilterComposer(
            $db: $db,
            $table: $db.orderLineOptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> kitchenTicketLinesRefs(
    Expression<bool> Function($$KitchenTicketLinesTableFilterComposer f) f,
  ) {
    final $$KitchenTicketLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kitchenTicketLines,
      getReferencedColumn: (t) => t.orderLineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenTicketLinesTableFilterComposer(
            $db: $db,
            $table: $db.kitchenTicketLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OrderLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableOrderingComposer({
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

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantText => $composableBuilder(
    column: $table.variantText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get basePricePaise => $composableBuilder(
    column: $table.basePricePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPricePaise => $composableBuilder(
    column: $table.unitPricePaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxProfileId => $composableBuilder(
    column: $table.taxProfileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBp => $composableBuilder(
    column: $table.taxRateBp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get taxInclusive => $composableBuilder(
    column: $table.taxInclusive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxSplitMode => $composableBuilder(
    column: $table.taxSplitMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sentQty => $composableBuilder(
    column: $table.sentQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get voidedQty => $composableBuilder(
    column: $table.voidedQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
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

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableOrderingComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MenuItemsTableOrderingComposer get menuItemId {
    final $$MenuItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.menuItemId,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableOrderingComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderLinesTable> {
  $$OrderLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get variantText => $composableBuilder(
    column: $table.variantText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get basePricePaise => $composableBuilder(
    column: $table.basePricePaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPricePaise => $composableBuilder(
    column: $table.unitPricePaise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxProfileId => $composableBuilder(
    column: $table.taxProfileId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxRateBp =>
      $composableBuilder(column: $table.taxRateBp, builder: (column) => column);

  GeneratedColumn<bool> get taxInclusive => $composableBuilder(
    column: $table.taxInclusive,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taxSplitMode => $composableBuilder(
    column: $table.taxSplitMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stationId =>
      $composableBuilder(column: $table.stationId, builder: (column) => column);

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<int> get sentQty =>
      $composableBuilder(column: $table.sentQty, builder: (column) => column);

  GeneratedColumn<int> get voidedQty =>
      $composableBuilder(column: $table.voidedQty, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MenuItemsTableAnnotationComposer get menuItemId {
    final $$MenuItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.menuItemId,
      referencedTable: $db.menuItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MenuItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.menuItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> orderLineOptionsRefs<T extends Object>(
    Expression<T> Function($$OrderLineOptionsTableAnnotationComposer a) f,
  ) {
    final $$OrderLineOptionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderLineOptions,
      getReferencedColumn: (t) => t.lineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLineOptionsTableAnnotationComposer(
            $db: $db,
            $table: $db.orderLineOptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> kitchenTicketLinesRefs<T extends Object>(
    Expression<T> Function($$KitchenTicketLinesTableAnnotationComposer a) f,
  ) {
    final $$KitchenTicketLinesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.kitchenTicketLines,
          getReferencedColumn: (t) => t.orderLineId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$KitchenTicketLinesTableAnnotationComposer(
                $db: $db,
                $table: $db.kitchenTicketLines,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$OrderLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderLinesTable,
          OrderLineRow,
          $$OrderLinesTableFilterComposer,
          $$OrderLinesTableOrderingComposer,
          $$OrderLinesTableAnnotationComposer,
          $$OrderLinesTableCreateCompanionBuilder,
          $$OrderLinesTableUpdateCompanionBuilder,
          (OrderLineRow, $$OrderLinesTableReferences),
          OrderLineRow,
          PrefetchHooks Function({
            bool orderId,
            bool menuItemId,
            bool orderLineOptionsRefs,
            bool kitchenTicketLinesRefs,
          })
        > {
  $$OrderLinesTableTableManager(_$AppDatabase db, $OrderLinesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderLinesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String?> menuItemId = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String> variantText = const Value.absent(),
                Value<int> basePricePaise = const Value.absent(),
                Value<int> unitPricePaise = const Value.absent(),
                Value<String?> taxProfileId = const Value.absent(),
                Value<int> taxRateBp = const Value.absent(),
                Value<bool> taxInclusive = const Value.absent(),
                Value<String> taxSplitMode = const Value.absent(),
                Value<String?> stationId = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<int> sentQty = const Value.absent(),
                Value<int> voidedQty = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderLinesCompanion(
                id: id,
                orderId: orderId,
                menuItemId: menuItemId,
                itemName: itemName,
                variantText: variantText,
                basePricePaise: basePricePaise,
                unitPricePaise: unitPricePaise,
                taxProfileId: taxProfileId,
                taxRateBp: taxRateBp,
                taxInclusive: taxInclusive,
                taxSplitMode: taxSplitMode,
                stationId: stationId,
                qty: qty,
                sentQty: sentQty,
                voidedQty: voidedQty,
                notes: notes,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                Value<String?> menuItemId = const Value.absent(),
                required String itemName,
                Value<String> variantText = const Value.absent(),
                required int basePricePaise,
                required int unitPricePaise,
                Value<String?> taxProfileId = const Value.absent(),
                Value<int> taxRateBp = const Value.absent(),
                Value<bool> taxInclusive = const Value.absent(),
                Value<String> taxSplitMode = const Value.absent(),
                Value<String?> stationId = const Value.absent(),
                required int qty,
                Value<int> sentQty = const Value.absent(),
                Value<int> voidedQty = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => OrderLinesCompanion.insert(
                id: id,
                orderId: orderId,
                menuItemId: menuItemId,
                itemName: itemName,
                variantText: variantText,
                basePricePaise: basePricePaise,
                unitPricePaise: unitPricePaise,
                taxProfileId: taxProfileId,
                taxRateBp: taxRateBp,
                taxInclusive: taxInclusive,
                taxSplitMode: taxSplitMode,
                stationId: stationId,
                qty: qty,
                sentQty: sentQty,
                voidedQty: voidedQty,
                notes: notes,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrderLinesTable, OrderLineRow>(table),
                  $$OrderLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                orderId = false,
                menuItemId = false,
                orderLineOptionsRefs = false,
                kitchenTicketLinesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (orderLineOptionsRefs) db.orderLineOptions,
                    if (kitchenTicketLinesRefs) db.kitchenTicketLines,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (orderId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.orderId,
                            referencedTable: $$OrderLinesTableReferences
                                ._orderIdTable(db),
                            referencedColumn: $$OrderLinesTableReferences
                                ._orderIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (menuItemId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.menuItemId,
                            referencedTable: $$OrderLinesTableReferences
                                ._menuItemIdTable(db),
                            referencedColumn: $$OrderLinesTableReferences
                                ._menuItemIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (orderLineOptionsRefs)
                        await $_getPrefetchedDataByColumns<
                          OrderLineRow,
                          $OrderLinesTable,
                          OrderLineOptionRow,
                          $OrderLineOptionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$OrderLinesTableReferences
                              ._orderLineOptionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OrderLinesTableReferences(
                                db,
                                table,
                                p0,
                              ).orderLineOptionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'line_id',
                          typedResults: items,
                        ),
                      if (kitchenTicketLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          OrderLineRow,
                          $OrderLinesTable,
                          KitchenTicketLineRow,
                          $KitchenTicketLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$OrderLinesTableReferences
                              ._kitchenTicketLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$OrderLinesTableReferences(
                                db,
                                table,
                                p0,
                              ).kitchenTicketLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'order_line_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$OrderLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderLinesTable,
      OrderLineRow,
      $$OrderLinesTableFilterComposer,
      $$OrderLinesTableOrderingComposer,
      $$OrderLinesTableAnnotationComposer,
      $$OrderLinesTableCreateCompanionBuilder,
      $$OrderLinesTableUpdateCompanionBuilder,
      (OrderLineRow, $$OrderLinesTableReferences),
      OrderLineRow,
      PrefetchHooks Function({
        bool orderId,
        bool menuItemId,
        bool orderLineOptionsRefs,
        bool kitchenTicketLinesRefs,
      })
    >;
typedef $$OrderLineOptionsTableCreateCompanionBuilder =
    OrderLineOptionsCompanion Function({
      required String id,
      required String lineId,
      required String groupId,
      required String groupName,
      required String kind,
      required String choiceId,
      required String name,
      required int priceDeltaPaise,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$OrderLineOptionsTableUpdateCompanionBuilder =
    OrderLineOptionsCompanion Function({
      Value<String> id,
      Value<String> lineId,
      Value<String> groupId,
      Value<String> groupName,
      Value<String> kind,
      Value<String> choiceId,
      Value<String> name,
      Value<int> priceDeltaPaise,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$OrderLineOptionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OrderLineOptionsTable,
          OrderLineOptionRow
        > {
  $$OrderLineOptionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OrderLinesTable _lineIdTable(_$AppDatabase db) =>
      db.orderLines.createAlias('order_line_options__line_id__order_lines__id');

  $$OrderLinesTableProcessedTableManager get lineId {
    final $_column = $_itemColumn<String>('line_id')!;

    final manager = $$OrderLinesTableTableManager(
      $_db,
      $_db.orderLines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OrderLineOptionsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderLineOptionsTable> {
  $$OrderLineOptionsTableFilterComposer({
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

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choiceId => $composableBuilder(
    column: $table.choiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceDeltaPaise => $composableBuilder(
    column: $table.priceDeltaPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$OrderLinesTableFilterComposer get lineId {
    final $$OrderLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableFilterComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderLineOptionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderLineOptionsTable> {
  $$OrderLineOptionsTableOrderingComposer({
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

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choiceId => $composableBuilder(
    column: $table.choiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceDeltaPaise => $composableBuilder(
    column: $table.priceDeltaPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$OrderLinesTableOrderingComposer get lineId {
    final $$OrderLinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableOrderingComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderLineOptionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderLineOptionsTable> {
  $$OrderLineOptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get choiceId =>
      $composableBuilder(column: $table.choiceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get priceDeltaPaise => $composableBuilder(
    column: $table.priceDeltaPaise,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$OrderLinesTableAnnotationComposer get lineId {
    final $$OrderLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lineId,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderLineOptionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderLineOptionsTable,
          OrderLineOptionRow,
          $$OrderLineOptionsTableFilterComposer,
          $$OrderLineOptionsTableOrderingComposer,
          $$OrderLineOptionsTableAnnotationComposer,
          $$OrderLineOptionsTableCreateCompanionBuilder,
          $$OrderLineOptionsTableUpdateCompanionBuilder,
          (OrderLineOptionRow, $$OrderLineOptionsTableReferences),
          OrderLineOptionRow,
          PrefetchHooks Function({bool lineId})
        > {
  $$OrderLineOptionsTableTableManager(
    _$AppDatabase db,
    $OrderLineOptionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderLineOptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderLineOptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderLineOptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> lineId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> groupName = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> choiceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> priceDeltaPaise = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderLineOptionsCompanion(
                id: id,
                lineId: lineId,
                groupId: groupId,
                groupName: groupName,
                kind: kind,
                choiceId: choiceId,
                name: name,
                priceDeltaPaise: priceDeltaPaise,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String lineId,
                required String groupId,
                required String groupName,
                required String kind,
                required String choiceId,
                required String name,
                required int priceDeltaPaise,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderLineOptionsCompanion.insert(
                id: id,
                lineId: lineId,
                groupId: groupId,
                groupName: groupName,
                kind: kind,
                choiceId: choiceId,
                name: name,
                priceDeltaPaise: priceDeltaPaise,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrderLineOptionsTable, OrderLineOptionRow>(
                    table,
                  ),
                  $$OrderLineOptionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lineId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (lineId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.lineId,
                        referencedTable: $$OrderLineOptionsTableReferences
                            ._lineIdTable(db),
                        referencedColumn: $$OrderLineOptionsTableReferences
                            ._lineIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OrderLineOptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderLineOptionsTable,
      OrderLineOptionRow,
      $$OrderLineOptionsTableFilterComposer,
      $$OrderLineOptionsTableOrderingComposer,
      $$OrderLineOptionsTableAnnotationComposer,
      $$OrderLineOptionsTableCreateCompanionBuilder,
      $$OrderLineOptionsTableUpdateCompanionBuilder,
      (OrderLineOptionRow, $$OrderLineOptionsTableReferences),
      OrderLineOptionRow,
      PrefetchHooks Function({bool lineId})
    >;
typedef $$StationPrintersTableCreateCompanionBuilder =
    StationPrintersCompanion Function({
      required String stationId,
      required String printerId,
      Value<int> rowid,
    });
typedef $$StationPrintersTableUpdateCompanionBuilder =
    StationPrintersCompanion Function({
      Value<String> stationId,
      Value<String> printerId,
      Value<int> rowid,
    });

class $$StationPrintersTableFilterComposer
    extends Composer<_$AppDatabase, $StationPrintersTable> {
  $$StationPrintersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get printerId => $composableBuilder(
    column: $table.printerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StationPrintersTableOrderingComposer
    extends Composer<_$AppDatabase, $StationPrintersTable> {
  $$StationPrintersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get printerId => $composableBuilder(
    column: $table.printerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StationPrintersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StationPrintersTable> {
  $$StationPrintersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get stationId =>
      $composableBuilder(column: $table.stationId, builder: (column) => column);

  GeneratedColumn<String> get printerId =>
      $composableBuilder(column: $table.printerId, builder: (column) => column);
}

class $$StationPrintersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StationPrintersTable,
          StationPrinterRow,
          $$StationPrintersTableFilterComposer,
          $$StationPrintersTableOrderingComposer,
          $$StationPrintersTableAnnotationComposer,
          $$StationPrintersTableCreateCompanionBuilder,
          $$StationPrintersTableUpdateCompanionBuilder,
          (
            StationPrinterRow,
            BaseReferences<
              _$AppDatabase,
              $StationPrintersTable,
              StationPrinterRow
            >,
          ),
          StationPrinterRow,
          PrefetchHooks Function()
        > {
  $$StationPrintersTableTableManager(
    _$AppDatabase db,
    $StationPrintersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StationPrintersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StationPrintersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StationPrintersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> stationId = const Value.absent(),
                Value<String> printerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StationPrintersCompanion(
                stationId: stationId,
                printerId: printerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String stationId,
                required String printerId,
                Value<int> rowid = const Value.absent(),
              }) => StationPrintersCompanion.insert(
                stationId: stationId,
                printerId: printerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StationPrintersTable, StationPrinterRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StationPrintersTable,
                    StationPrinterRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StationPrintersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StationPrintersTable,
      StationPrinterRow,
      $$StationPrintersTableFilterComposer,
      $$StationPrintersTableOrderingComposer,
      $$StationPrintersTableAnnotationComposer,
      $$StationPrintersTableCreateCompanionBuilder,
      $$StationPrintersTableUpdateCompanionBuilder,
      (
        StationPrinterRow,
        BaseReferences<_$AppDatabase, $StationPrintersTable, StationPrinterRow>,
      ),
      StationPrinterRow,
      PrefetchHooks Function()
    >;
typedef $$KitchenTicketsTableCreateCompanionBuilder =
    KitchenTicketsCompanion Function({
      required String id,
      required String orderId,
      required String stationId,
      required String stationName,
      required int roundNo,
      required String kind,
      Value<String> reason,
      required String clientRequestId,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$KitchenTicketsTableUpdateCompanionBuilder =
    KitchenTicketsCompanion Function({
      Value<String> id,
      Value<String> orderId,
      Value<String> stationId,
      Value<String> stationName,
      Value<int> roundNo,
      Value<String> kind,
      Value<String> reason,
      Value<String> clientRequestId,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$KitchenTicketsTableReferences
    extends
        BaseReferences<_$AppDatabase, $KitchenTicketsTable, KitchenTicketRow> {
  $$KitchenTicketsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OrdersTable _orderIdTable(_$AppDatabase db) =>
      db.orders.createAlias('kitchen_tickets__order_id__orders__id');

  $$OrdersTableProcessedTableManager get orderId {
    final $_column = $_itemColumn<String>('order_id')!;

    final manager = $$OrdersTableTableManager(
      $_db,
      $_db.orders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $KitchenTicketLinesTable,
    List<KitchenTicketLineRow>
  >
  _kitchenTicketLinesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.kitchenTicketLines,
        aliasName: 'kitchen_tickets__id__kitchen_ticket_lines__ticket_id',
      );

  $$KitchenTicketLinesTableProcessedTableManager get kitchenTicketLinesRefs {
    final manager = $$KitchenTicketLinesTableTableManager(
      $_db,
      $_db.kitchenTicketLines,
    ).filter((f) => f.ticketId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _kitchenTicketLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$KitchenTicketsTableFilterComposer
    extends Composer<_$AppDatabase, $KitchenTicketsTable> {
  $$KitchenTicketsTableFilterComposer({
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

  ColumnFilters<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundNo => $composableBuilder(
    column: $table.roundNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$OrdersTableFilterComposer get orderId {
    final $$OrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableFilterComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> kitchenTicketLinesRefs(
    Expression<bool> Function($$KitchenTicketLinesTableFilterComposer f) f,
  ) {
    final $$KitchenTicketLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.kitchenTicketLines,
      getReferencedColumn: (t) => t.ticketId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenTicketLinesTableFilterComposer(
            $db: $db,
            $table: $db.kitchenTicketLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$KitchenTicketsTableOrderingComposer
    extends Composer<_$AppDatabase, $KitchenTicketsTable> {
  $$KitchenTicketsTableOrderingComposer({
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

  ColumnOrderings<String> get stationId => $composableBuilder(
    column: $table.stationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundNo => $composableBuilder(
    column: $table.roundNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$OrdersTableOrderingComposer get orderId {
    final $$OrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableOrderingComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KitchenTicketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $KitchenTicketsTable> {
  $$KitchenTicketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get stationId =>
      $composableBuilder(column: $table.stationId, builder: (column) => column);

  GeneratedColumn<String> get stationName => $composableBuilder(
    column: $table.stationName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get roundNo =>
      $composableBuilder(column: $table.roundNo, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get clientRequestId => $composableBuilder(
    column: $table.clientRequestId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$OrdersTableAnnotationComposer get orderId {
    final $$OrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.orders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> kitchenTicketLinesRefs<T extends Object>(
    Expression<T> Function($$KitchenTicketLinesTableAnnotationComposer a) f,
  ) {
    final $$KitchenTicketLinesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.kitchenTicketLines,
          getReferencedColumn: (t) => t.ticketId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$KitchenTicketLinesTableAnnotationComposer(
                $db: $db,
                $table: $db.kitchenTicketLines,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$KitchenTicketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KitchenTicketsTable,
          KitchenTicketRow,
          $$KitchenTicketsTableFilterComposer,
          $$KitchenTicketsTableOrderingComposer,
          $$KitchenTicketsTableAnnotationComposer,
          $$KitchenTicketsTableCreateCompanionBuilder,
          $$KitchenTicketsTableUpdateCompanionBuilder,
          (KitchenTicketRow, $$KitchenTicketsTableReferences),
          KitchenTicketRow,
          PrefetchHooks Function({bool orderId, bool kitchenTicketLinesRefs})
        > {
  $$KitchenTicketsTableTableManager(
    _$AppDatabase db,
    $KitchenTicketsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KitchenTicketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KitchenTicketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KitchenTicketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> orderId = const Value.absent(),
                Value<String> stationId = const Value.absent(),
                Value<String> stationName = const Value.absent(),
                Value<int> roundNo = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String> clientRequestId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KitchenTicketsCompanion(
                id: id,
                orderId: orderId,
                stationId: stationId,
                stationName: stationName,
                roundNo: roundNo,
                kind: kind,
                reason: reason,
                clientRequestId: clientRequestId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String orderId,
                required String stationId,
                required String stationName,
                required int roundNo,
                required String kind,
                Value<String> reason = const Value.absent(),
                required String clientRequestId,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => KitchenTicketsCompanion.insert(
                id: id,
                orderId: orderId,
                stationId: stationId,
                stationName: stationName,
                roundNo: roundNo,
                kind: kind,
                reason: reason,
                clientRequestId: clientRequestId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KitchenTicketsTable, KitchenTicketRow>(table),
                  $$KitchenTicketsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({orderId = false, kitchenTicketLinesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (kitchenTicketLinesRefs) db.kitchenTicketLines,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (orderId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.orderId,
                            referencedTable: $$KitchenTicketsTableReferences
                                ._orderIdTable(db),
                            referencedColumn: $$KitchenTicketsTableReferences
                                ._orderIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (kitchenTicketLinesRefs)
                        await $_getPrefetchedDataByColumns<
                          KitchenTicketRow,
                          $KitchenTicketsTable,
                          KitchenTicketLineRow,
                          $KitchenTicketLinesTable
                        >(
                          currentTable: table,
                          referencedTable: $$KitchenTicketsTableReferences
                              ._kitchenTicketLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$KitchenTicketsTableReferences(
                                db,
                                table,
                                p0,
                              ).kitchenTicketLinesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'ticket_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$KitchenTicketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KitchenTicketsTable,
      KitchenTicketRow,
      $$KitchenTicketsTableFilterComposer,
      $$KitchenTicketsTableOrderingComposer,
      $$KitchenTicketsTableAnnotationComposer,
      $$KitchenTicketsTableCreateCompanionBuilder,
      $$KitchenTicketsTableUpdateCompanionBuilder,
      (KitchenTicketRow, $$KitchenTicketsTableReferences),
      KitchenTicketRow,
      PrefetchHooks Function({bool orderId, bool kitchenTicketLinesRefs})
    >;
typedef $$KitchenTicketLinesTableCreateCompanionBuilder =
    KitchenTicketLinesCompanion Function({
      required String id,
      required String ticketId,
      required String orderLineId,
      required int qty,
      required String itemName,
      Value<String> addonsText,
      Value<String> notes,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$KitchenTicketLinesTableUpdateCompanionBuilder =
    KitchenTicketLinesCompanion Function({
      Value<String> id,
      Value<String> ticketId,
      Value<String> orderLineId,
      Value<int> qty,
      Value<String> itemName,
      Value<String> addonsText,
      Value<String> notes,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$KitchenTicketLinesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $KitchenTicketLinesTable,
          KitchenTicketLineRow
        > {
  $$KitchenTicketLinesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $KitchenTicketsTable _ticketIdTable(_$AppDatabase db) => db
      .kitchenTickets
      .createAlias('kitchen_ticket_lines__ticket_id__kitchen_tickets__id');

  $$KitchenTicketsTableProcessedTableManager get ticketId {
    final $_column = $_itemColumn<String>('ticket_id')!;

    final manager = $$KitchenTicketsTableTableManager(
      $_db,
      $_db.kitchenTickets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ticketIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $OrderLinesTable _orderLineIdTable(_$AppDatabase db) => db.orderLines
      .createAlias('kitchen_ticket_lines__order_line_id__order_lines__id');

  $$OrderLinesTableProcessedTableManager get orderLineId {
    final $_column = $_itemColumn<String>('order_line_id')!;

    final manager = $$OrderLinesTableTableManager(
      $_db,
      $_db.orderLines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderLineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$KitchenTicketLinesTableFilterComposer
    extends Composer<_$AppDatabase, $KitchenTicketLinesTable> {
  $$KitchenTicketLinesTableFilterComposer({
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

  ColumnFilters<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addonsText => $composableBuilder(
    column: $table.addonsText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$KitchenTicketsTableFilterComposer get ticketId {
    final $$KitchenTicketsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ticketId,
      referencedTable: $db.kitchenTickets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenTicketsTableFilterComposer(
            $db: $db,
            $table: $db.kitchenTickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OrderLinesTableFilterComposer get orderLineId {
    final $$OrderLinesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderLineId,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableFilterComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KitchenTicketLinesTableOrderingComposer
    extends Composer<_$AppDatabase, $KitchenTicketLinesTable> {
  $$KitchenTicketLinesTableOrderingComposer({
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

  ColumnOrderings<int> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addonsText => $composableBuilder(
    column: $table.addonsText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$KitchenTicketsTableOrderingComposer get ticketId {
    final $$KitchenTicketsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ticketId,
      referencedTable: $db.kitchenTickets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenTicketsTableOrderingComposer(
            $db: $db,
            $table: $db.kitchenTickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OrderLinesTableOrderingComposer get orderLineId {
    final $$OrderLinesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderLineId,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableOrderingComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KitchenTicketLinesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KitchenTicketLinesTable> {
  $$KitchenTicketLinesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<String> get addonsText => $composableBuilder(
    column: $table.addonsText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$KitchenTicketsTableAnnotationComposer get ticketId {
    final $$KitchenTicketsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ticketId,
      referencedTable: $db.kitchenTickets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$KitchenTicketsTableAnnotationComposer(
            $db: $db,
            $table: $db.kitchenTickets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$OrderLinesTableAnnotationComposer get orderLineId {
    final $$OrderLinesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderLineId,
      referencedTable: $db.orderLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderLinesTableAnnotationComposer(
            $db: $db,
            $table: $db.orderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$KitchenTicketLinesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KitchenTicketLinesTable,
          KitchenTicketLineRow,
          $$KitchenTicketLinesTableFilterComposer,
          $$KitchenTicketLinesTableOrderingComposer,
          $$KitchenTicketLinesTableAnnotationComposer,
          $$KitchenTicketLinesTableCreateCompanionBuilder,
          $$KitchenTicketLinesTableUpdateCompanionBuilder,
          (KitchenTicketLineRow, $$KitchenTicketLinesTableReferences),
          KitchenTicketLineRow,
          PrefetchHooks Function({bool ticketId, bool orderLineId})
        > {
  $$KitchenTicketLinesTableTableManager(
    _$AppDatabase db,
    $KitchenTicketLinesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KitchenTicketLinesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KitchenTicketLinesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KitchenTicketLinesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ticketId = const Value.absent(),
                Value<String> orderLineId = const Value.absent(),
                Value<int> qty = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<String> addonsText = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KitchenTicketLinesCompanion(
                id: id,
                ticketId: ticketId,
                orderLineId: orderLineId,
                qty: qty,
                itemName: itemName,
                addonsText: addonsText,
                notes: notes,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ticketId,
                required String orderLineId,
                required int qty,
                required String itemName,
                Value<String> addonsText = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KitchenTicketLinesCompanion.insert(
                id: id,
                ticketId: ticketId,
                orderLineId: orderLineId,
                qty: qty,
                itemName: itemName,
                addonsText: addonsText,
                notes: notes,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KitchenTicketLinesTable, KitchenTicketLineRow>(
                    table,
                  ),
                  $$KitchenTicketLinesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ticketId = false, orderLineId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ticketId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.ticketId,
                        referencedTable: $$KitchenTicketLinesTableReferences
                            ._ticketIdTable(db),
                        referencedColumn: $$KitchenTicketLinesTableReferences
                            ._ticketIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (orderLineId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.orderLineId,
                        referencedTable: $$KitchenTicketLinesTableReferences
                            ._orderLineIdTable(db),
                        referencedColumn: $$KitchenTicketLinesTableReferences
                            ._orderLineIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$KitchenTicketLinesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KitchenTicketLinesTable,
      KitchenTicketLineRow,
      $$KitchenTicketLinesTableFilterComposer,
      $$KitchenTicketLinesTableOrderingComposer,
      $$KitchenTicketLinesTableAnnotationComposer,
      $$KitchenTicketLinesTableCreateCompanionBuilder,
      $$KitchenTicketLinesTableUpdateCompanionBuilder,
      (KitchenTicketLineRow, $$KitchenTicketLinesTableReferences),
      KitchenTicketLineRow,
      PrefetchHooks Function({bool ticketId, bool orderLineId})
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
  $$TaxProfilesTableTableManager get taxProfiles =>
      $$TaxProfilesTableTableManager(_db, _db.taxProfiles);
  $$KitchenStationsTableTableManager get kitchenStations =>
      $$KitchenStationsTableTableManager(_db, _db.kitchenStations);
  $$MenuCategoriesTableTableManager get menuCategories =>
      $$MenuCategoriesTableTableManager(_db, _db.menuCategories);
  $$MenuItemsTableTableManager get menuItems =>
      $$MenuItemsTableTableManager(_db, _db.menuItems);
  $$OptionGroupsTableTableManager get optionGroups =>
      $$OptionGroupsTableTableManager(_db, _db.optionGroups);
  $$OptionChoicesTableTableManager get optionChoices =>
      $$OptionChoicesTableTableManager(_db, _db.optionChoices);
  $$ItemOptionGroupsTableTableManager get itemOptionGroups =>
      $$ItemOptionGroupsTableTableManager(_db, _db.itemOptionGroups);
  $$DiningAreasTableTableManager get diningAreas =>
      $$DiningAreasTableTableManager(_db, _db.diningAreas);
  $$RestaurantTablesTableTableManager get restaurantTables =>
      $$RestaurantTablesTableTableManager(_db, _db.restaurantTables);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db, _db.orders);
  $$OrderLinesTableTableManager get orderLines =>
      $$OrderLinesTableTableManager(_db, _db.orderLines);
  $$OrderLineOptionsTableTableManager get orderLineOptions =>
      $$OrderLineOptionsTableTableManager(_db, _db.orderLineOptions);
  $$StationPrintersTableTableManager get stationPrinters =>
      $$StationPrintersTableTableManager(_db, _db.stationPrinters);
  $$KitchenTicketsTableTableManager get kitchenTickets =>
      $$KitchenTicketsTableTableManager(_db, _db.kitchenTickets);
  $$KitchenTicketLinesTableTableManager get kitchenTicketLines =>
      $$KitchenTicketLinesTableTableManager(_db, _db.kitchenTicketLines);
}
