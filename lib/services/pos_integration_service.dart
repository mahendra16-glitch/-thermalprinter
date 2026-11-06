import 'dart:convert';
import '../models/pos_order.dart';
import '../queue/print_queue_manager.dart';

class PosIntegrationService {
  /// Parses JSON string or Map payload from POS system/web app and enqueues print job
  static Future<String> processIncomingPrintJob(dynamic jsonPayload) async {
    Map<String, dynamic> data;

    if (jsonPayload is String) {
      data = jsonDecode(jsonPayload) as Map<String, dynamic>;
    } else if (jsonPayload is Map<String, dynamic>) {
      data = jsonPayload;
    } else {
      throw Exception('Invalid JSON payload format for POS print job.');
    }

    final order = PosOrder.fromJson(data);
    final queueManager = await PrintQueueManager.getInstance();
    final jobId = await queueManager.addOrderToQueue(order);
    return jobId;
  }
}
