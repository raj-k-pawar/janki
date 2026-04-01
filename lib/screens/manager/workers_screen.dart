import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final _db = DatabaseService();
  List<WorkerModel> _workers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _db.getWorkers();
      if (res['success'] == true) {
        setState(() {
          _workers = (res['data'] as List)
              .map((e) => WorkerModel.fromJson(e))
              .toList();
          _loading = false;
        });
      } else {
        setState(() { _error = res['message']; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load workers'; _loading = false; });
    }
  }

  void _showAddEdit([WorkerModel? worker]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkerForm(
        worker: worker,
        onSaved: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  Future<void> _delete(WorkerModel w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Worker'),
        content: Text('Delete ${w.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _db.deleteWorker(w.id!);
      if (!mounted) return;
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Workers'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEdit(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: Text('Add Worker',
            style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!,
                        style:
                            GoogleFonts.poppins(color: AppTheme.error)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: _load, child: const Text('Retry')),
                  ],
                ))
              : _workers.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('👷', style: TextStyle(fontSize: 50)),
                        const SizedBox(height: 12),
                        Text('No workers added yet',
                            style:
                                GoogleFonts.poppins(color: AppTheme.textLight)),
                      ],
                    ))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _workers.length,
                        itemBuilder: (_, i) => _workerCard(_workers[i]),
                      ),
                    ),
    );
  }

  Widget _workerCard(WorkerModel w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange.withOpacity(0.15),
          child: Text(
            w.name.isNotEmpty ? w.name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.deepOrange),
          ),
        ),
        title: Text(w.name,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${w.role} • ${w.mobile}',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: w.status == 'active'
                        ? AppTheme.success.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    w.status == 'active' ? '● Active' : '● Inactive',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: w.status == 'active'
                          ? AppTheme.success
                          : AppTheme.textLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('₹${w.salary.toStringAsFixed(0)}/month',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.teal, size: 20),
              onPressed: () => _showAddEdit(w),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.error, size: 20),
              onPressed: () => _delete(w),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Worker Form (Bottom Sheet) ───────────────────────────────────────────────

class _WorkerForm extends StatefulWidget {
  final WorkerModel? worker;
  final VoidCallback onSaved;
  const _WorkerForm({this.worker, required this.onSaved});

  @override
  State<_WorkerForm> createState() => _WorkerFormState();
}

class _WorkerFormState extends State<_WorkerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  String _status = 'active';
  bool _saving = false;
  final _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    if (widget.worker != null) {
      final w = widget.worker!;
      _nameCtrl.text = w.name;
      _roleCtrl.text = w.role;
      _mobileCtrl.text = w.mobile;
      _salaryCtrl.text = w.salary.toString();
      _status = w.status;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _mobileCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'role': _roleCtrl.text.trim(),
      'mobile': _mobileCtrl.text.trim(),
      'salary': double.tryParse(_salaryCtrl.text) ?? 0,
      'status': _status,
    };

    try {
      Map<String, dynamic> res;
      if (widget.worker != null) {
        res = await _db.updateWorker(widget.worker!.id!, data);
      } else {
        res = await _db.addWorker(data);
      }

      setState(() => _saving = false);
      if (!mounted) return;
      if (res['success'] == true) {
        widget.onSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Failed'),
          backgroundColor: AppTheme.error,
        ));
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.worker != null ? 'Edit Worker' : 'Add Worker',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark),
                ),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Role / Designation',
                  prefixIcon: Icon(Icons.work_outline)),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Mobile No',
                  prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) =>
                  v!.length < 10 ? 'Enter valid mobile' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _salaryCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Monthly Salary (₹)',
                  prefixIcon: Icon(Icons.currency_rupee)),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.toggle_on_outlined)),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(widget.worker != null ? 'Update' : 'Add Worker'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
