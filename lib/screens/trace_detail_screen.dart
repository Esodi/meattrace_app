import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meat_trace.dart';
import '../providers/meat_trace_provider.dart';

class TraceDetailScreen extends StatefulWidget {
  final MeatTrace? meatTrace;

  const TraceDetailScreen({super.key, this.meatTrace});

  @override
  State<TraceDetailScreen> createState() => _TraceDetailScreenState();
}

class _TraceDetailScreenState extends State<TraceDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _originController;
  late TextEditingController _batchController;
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.meatTrace?.name ?? '');
    _originController = TextEditingController(
      text: widget.meatTrace?.origin ?? '',
    );
    _batchController = TextEditingController(
      text: widget.meatTrace?.batchNumber ?? '',
    );
    _status = widget.meatTrace?.status ?? 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.meatTrace != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Meat Trace' : 'Add Meat Trace'),
        actions: isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteTrace,
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _originController,
                decoration: const InputDecoration(labelText: 'Origin'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(labelText: 'Batch Number'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: ['pending', 'processed', 'shipped', 'delivered']
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTrace,
                child: Text(isEditing ? 'Update' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveTrace() {
    if (!_formKey.currentState!.validate()) return;

    final meatTrace = MeatTrace(
      id: widget.meatTrace?.id,
      name: _nameController.text,
      origin: _originController.text,
      batchNumber: _batchController.text,
      timestamp: widget.meatTrace?.timestamp ?? DateTime.now(),
      status: _status,
    );

    if (widget.meatTrace != null) {
      context.read<MeatTraceProvider>().updateMeatTrace(meatTrace);
    } else {
      context.read<MeatTraceProvider>().createMeatTrace(meatTrace);
    }

    Navigator.pop(context);
  }

  void _deleteTrace() {
    if (widget.meatTrace != null) {
      context.read<MeatTraceProvider>().deleteMeatTrace(widget.meatTrace!.id!);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _batchController.dispose();
    super.dispose();
  }
}
