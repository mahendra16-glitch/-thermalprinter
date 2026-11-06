import '../../models/print_job.dart';

enum KitchenTicketKind { send, voided }

class KitchenTicketLine {
  final String orderLineId;
  final int qty;
  final String itemName;
  final String addonsText;
  final String notes;

  const KitchenTicketLine({
    required this.orderLineId,
    required this.qty,
    required this.itemName,
    this.addonsText = '',
    this.notes = '',
  });
}

/// Where a ticket's print jobs stand.
enum TicketPrintState { printed, printing, failed, notQueued }

class KitchenTicket {
  final String id;
  final String orderId;
  final String stationId;
  final String stationName;
  final int roundNo;
  final KitchenTicketKind kind;
  final String reason;
  final DateTime createdAt;
  final List<KitchenTicketLine> lines;

  /// Print jobs for this ticket (originals and reprints), oldest first.
  final List<PrintJob> jobs;

  const KitchenTicket({
    required this.id,
    required this.orderId,
    required this.stationId,
    required this.stationName,
    required this.roundNo,
    required this.kind,
    this.reason = '',
    required this.createdAt,
    this.lines = const [],
    this.jobs = const [],
  });

  /// Summary of the original (non-reprint) jobs.
  TicketPrintState get printState {
    final originals = jobs
        .where((j) => !j.effectiveSourceKey.startsWith('REPRINT:'))
        .where((j) => j.status != PrintJobStatus.cancelled)
        .toList();
    if (originals.isEmpty) return TicketPrintState.notQueued;
    if (originals.any((j) => j.status == PrintJobStatus.failed)) {
      return TicketPrintState.failed;
    }
    if (originals.any((j) => j.isActive)) return TicketPrintState.printing;
    return TicketPrintState.printed;
  }

  String? get lastError => jobs
      .where((j) => j.status == PrintJobStatus.failed)
      .map((j) => j.errorMessage)
      .lastOrNull;
}

/// Result of a "send to kitchen" action.
class KitchenSendResult {
  final List<String> ticketIds;
  final int jobCount;

  /// Stations that had no printer assigned (their tickets were queued for
  /// the role-based / fallback printer instead).
  final List<String> unroutedStations;

  const KitchenSendResult(this.ticketIds, this.jobCount, this.unroutedStations);
}
