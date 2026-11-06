enum ConnectionType { bluetooth, usb, network }

enum PaperWidth { mm58, mm80 }

enum PrinterRole { bill, kot, customerCopy, bar, kitchen, other }

extension PaperWidthX on PaperWidth {
  int get dots => this == PaperWidth.mm58 ? 384 : 576;
  int get charsPerLine => this == PaperWidth.mm58 ? 32 : 48;
  String get label => this == PaperWidth.mm58 ? '58mm' : '80mm';
}

extension PrinterRoleX on PrinterRole {
  String get label {
    switch (this) {
      case PrinterRole.bill:
        return 'Bill Printer';
      case PrinterRole.kot:
        return 'KOT Printer';
      case PrinterRole.customerCopy:
        return 'Customer Copy';
      case PrinterRole.bar:
        return 'Bar Printer';
      case PrinterRole.kitchen:
        return 'Kitchen Printer';
      case PrinterRole.other:
        return 'Other Printer';
    }
  }
}

class PrinterDevice {
  final String id;
  final String name;
  final ConnectionType connectionType;
  final PaperWidth paperWidth;
  final PrinterRole role;

  // Bluetooth specific
  final String? macAddress;

  // USB specific
  final int? vendorId;
  final int? productId;
  final String? deviceName;

  // Network specific
  final String? ipAddress;
  final int port;

  bool isConnected;
  DateTime? lastConnected;
  String? lastError;

  PrinterDevice({
    required this.id,
    required this.name,
    required this.connectionType,
    this.paperWidth = PaperWidth.mm80,
    this.role = PrinterRole.bill,
    this.macAddress,
    this.vendorId,
    this.productId,
    this.deviceName,
    this.ipAddress,
    this.port = 9100,
    this.isConnected = false,
    this.lastConnected,
    this.lastError,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'connectionType': connectionType.name,
      'paperWidth': paperWidth.name,
      'role': role.name,
      'macAddress': macAddress,
      'vendorId': vendorId,
      'productId': productId,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'port': port,
      'isConnected': isConnected,
      'lastConnected': lastConnected?.toIso8601String(),
      'lastError': lastError,
    };
  }

  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      connectionType: ConnectionType.values.firstWhere(
        (e) => e.name == json['connectionType'],
        orElse: () => ConnectionType.network,
      ),
      paperWidth: PaperWidth.values.firstWhere(
        (e) => e.name == json['paperWidth'],
        orElse: () => PaperWidth.mm80,
      ),
      role: PrinterRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => PrinterRole.bill,
      ),
      macAddress: json['macAddress'] as String?,
      vendorId: json['vendorId'] as int?,
      productId: json['productId'] as int?,
      deviceName: json['deviceName'] as String?,
      ipAddress: json['ipAddress'] as String?,
      port: json['port'] as int? ?? 9100,
      isConnected: json['isConnected'] as bool? ?? false,
      lastConnected: json['lastConnected'] != null
          ? DateTime.tryParse(json['lastConnected'] as String)
          : null,
      lastError: json['lastError'] as String?,
    );
  }

  PrinterDevice copyWith({
    String? id,
    String? name,
    ConnectionType? connectionType,
    PaperWidth? paperWidth,
    PrinterRole? role,
    String? macAddress,
    int? vendorId,
    int? productId,
    String? deviceName,
    String? ipAddress,
    int? port,
    bool? isConnected,
    DateTime? lastConnected,
    String? lastError,
  }) {
    return PrinterDevice(
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
      isConnected: isConnected ?? this.isConnected,
      lastConnected: lastConnected ?? this.lastConnected,
      lastError: lastError ?? this.lastError,
    );
  }
}
