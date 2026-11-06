import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/print_job.dart';
import '../queue/print_queue_manager.dart';
import '../widgets/status_badge.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  PrintQueueManager? _queueManager;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final manager = await PrintQueueManager.getInstance();
    if (mounted) {
      setState(() {
        _queueManager = manager;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Queue Manager'),
        actions: [
          if (_queueManager != null)
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded),
              tooltip: 'Clear Printed / Failed',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await _queueManager!.clearCompleted();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Cleared completed & failed jobs'),
                  ),
                );
              },
            ),
        ],
      ),
      body: _queueManager == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<PrintJob>>(
              stream: _queueManager!.queueStream,
              initialData: _queueManager!.currentQueue,
              builder: (context, snapshot) {
                final queue = snapshot.data ?? [];

                if (queue.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: Color(0xFFCBD5E1),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Print queue is empty.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final DateFormat formatter = DateFormat('hh:mm:ss a');

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final job = queue[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Order #${job.orderId}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    job.printType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                StatusBadge.forJobStatus(job.status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Target Role: ${job.targetRole.name.toUpperCase()}  |  Time: ${formatter.format(job.createdAt)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (job.retryCount > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Retry Attempts: ${job.retryCount}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                            if (job.errorMessage != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                job.errorMessage!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (job.status == PrintJobStatus.failed)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _queueManager!.retryJob(job.id),
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 14,
                                    ),
                                    label: const Text('Retry Print'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _queueManager!.removeJob(job.id),
                                  tooltip: 'Remove from queue',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
