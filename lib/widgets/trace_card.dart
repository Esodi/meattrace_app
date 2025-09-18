import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meat_trace.dart';

class TraceCard extends StatelessWidget {
  final MeatTrace meatTrace;
  final VoidCallback onTap;

  const TraceCard({super.key, required this.meatTrace, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(meatTrace.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Origin: ${meatTrace.origin}'),
            Text('Batch: ${meatTrace.batchNumber}'),
            Text('Status: ${meatTrace.status}'),
            Text('Date: ${DateFormat.yMMMd().format(meatTrace.timestamp)}'),
          ],
        ),
        trailing: Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}
