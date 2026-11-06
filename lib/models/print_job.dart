import 'printer_device.dart';

/// `cancelled`: removed by staff before printing; kept for the record.
enum PrintJobStatus { pending, printing, printed, failed, cancelled }

class PrintJob {
  final String id;
  final String orderId;
  final String printType; // KOT, Bill, Test, Raw
  final PrinterRole targetRole;
  final String? targetPrinterId;
  final Map<String, dynamic>? posOrderJson;
  final List<int>? rawBytes;
  final DateTime createdAt;

  /// What this job prints, e.g. `KOT:<ticket>:<printer>`. Only one active
  /// job may exist per key. Defaults to `<printType>:<orderId>`.
  final String? sourceKey;

  PrintJobStatus status;
  int retryCount;
  String? errorMessage;
  DateTime? processedAt;

  PrintJob({
    required this.id,
    required this.orderId,
    this.printType = 'Receipt',
    this.targetRole = PrinterRole.bill,
    this.targetPrinterId,
    this.posOrderJson,
    this.rawBytes,
    this.sourceKey,
    DateTime? createdAt,
    this.status = PrintJobStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    this.processedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'printType': printType,
    'targetRole': targetRole.name,
    'targetPrinterId': targetPrinterId,
    'posOrderJson': posOrderJson,
    'sourceKey': sourceKey,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'errorMessage': errorMessage,
    'processedAt': processedAt?.toIso8601String(),
  };

  factory PrintJob.fromJson(Map<String, dynamic> json) => PrintJob(
    id: json['id'] as String,
    orderId: json['orderId'] as String? ?? 'N/A',
    printType: json['printType'] as String? ?? 'Receipt',
    targetRole: PrinterRole.values.firstWhere(
      (e) => e.name == json['targetRole'],
      orElse: () => PrinterRole.bill,
    ),
    targetPrinterId: json['targetPrinterId'] as String?,
    posOrderJson: json['posOrderJson'] as Map<String, dynamic>?,
    sourceKey: json['sourceKey'] as String?,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    status: PrintJobStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => PrintJobStatus.pending,
    ),
    retryCount: json['retryCount'] as int? ?? 0,
    errorMessage: json['errorMessage'] as String?,
    processedAt: json['processedAt'] != null
        ? DateTime.tryParse(json['processedAt'] as String)
        : null,
  );
}

extension PrintJobKey on PrintJob {
  String get effectiveSourceKey =>
      sourceKey ?? '${printType.toUpperCase()}:$orderId';

  bool get isActive =>
      status == PrintJobStatus.pending || status == PrintJobStatus.printing;
}
