import 'printer_device.dart';

class PrintHistoryItem {
  final String id;
  final DateTime timestamp;
  final String printerName;
  final ConnectionType connectionType;
  final String orderId;
  final String printType;
  final bool isSuccess;
  final String? errorMessage;

  PrintHistoryItem({
    required this.id,
    required this.timestamp,
    required this.printerName,
    required this.connectionType,
    required this.orderId,
    required this.printType,
    required this.isSuccess,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'printerName': printerName,
    'connectionType': connectionType.name,
    'orderId': orderId,
    'printType': printType,
    'isSuccess': isSuccess,
    'errorMessage': errorMessage,
  };

  factory PrintHistoryItem.fromJson(Map<String, dynamic> json) =>
      PrintHistoryItem(
        id: json['id'] as String,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        printerName: json['printerName'] as String? ?? 'Unknown Printer',
        connectionType: ConnectionType.values.firstWhere(
          (e) => e.name == json['connectionType'],
          orElse: () => ConnectionType.network,
        ),
        orderId: json['orderId'] as String? ?? 'N/A',
        printType: json['printType'] as String? ?? 'Receipt',
        isSuccess: json['isSuccess'] as bool? ?? false,
        errorMessage: json['errorMessage'] as String?,
      );
}
