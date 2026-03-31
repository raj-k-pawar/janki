import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  List<WorkerModel> _workers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    setState(() => _loading = true);
    final result = await ApiService().getWorkers();
    if (mounted) {
      if (result['success'] == true) {
        final list = result['workers'] as List<dynamic>;
        _workers = list
            .map((j) => WorkerModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
      setState(() => _loading = false);
    }
  }

  void _showWorkerForm([WorkerModel? worker]) {
    final nameCtrl = TextEditingController(text: worker?.name ?? '');
    final roleCtrl = TextEditingController(text: worker?.role ?? '');
    final mobileCtrl = TextEditingController(text: worker?.mobile ?? '');
    final salaryCtrl =
        TextEditingController(text: worker?.salary.toString() ?? '0');
    String selectedStatus = worker?.status ?? 'active';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    worker == null ? 'Add Worker' : 'Edit Worker',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _textField(nameCtrl, 'Full Name', Icons.person_outline),
                  const SizedBox(height: 10),
                  _textField(
                    roleCtrl,
                    'Role (e.g. Guard, Cook)',
                    Icons.work_outline,
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    mobileCtrl,
                    'Mobile',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _textField(
                    salaryCtrl,
                    'Monthly Salary (Rs.)',
                    Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(
                          color: AppTheme.textMedium,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 14),
                      _statusChip(
                        'Active',
                        'active',
                        selectedStatus,
                        (v) => setSheetState(() => selectedStatus = v),
                      ),
                      const SizedBox(width: 8),
                      _statusChip(
                        'Inactive',
                        'inactive',
                        selectedStatus,
                        (v) => setSheetState(() => selectedStatus = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () async {
                      final wm = WorkerModel(
                        id: worker?.id,
                        name: nameCtrl.text.trim(),
                        role: roleCtrl.text.trim(),
                        mobile: mobileCtrl.text.trim(),
                        salary:
                            double.tryParse(salaryCtrl.text) ?? 0,
                        status: selectedStatus,
                      );
                      Map<String, dynamic> result;
                      if (worker?.id != null) {
                        result = await ApiService()
                            .updateWorker(worker!.id!, wm.toJson());
                      } else {
                        result =
                            await ApiService().addWorker(wm.toJson());
                      }
                      if (result['success'] == true && ctx.mounted) {
                        Navigator.of(ctx).pop();
                        _loadWorkers();
                      }
                    },
                    child: Text(
                      worker == null ? 'Add Worker' : 'Update Worker',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FCF8),
      ),
    );
  }

  Widget _statusChip(
    String label,
    String value,
    String current,
    ValueChanged<String> onChange,
  ) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onChange(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (value == 'active' ? AppTheme.primary : AppTheme.danger)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMedium,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteWorker(WorkerModel worker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Worker?'),
        content: Text('Remove ${worker.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && worker.id != null) {
      await ApiService().deleteWorker(worker.id!);
      _loadWorkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Workers'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWorkers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showWorkerForm(),
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.add),
        label: const Text('Add Worker'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _workers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.badge_outlined,
                        size: 56,
                        color: AppTheme.textLight,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No workers added yet',
                        style: TextStyle(color: AppTheme.textMedium),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _workers.length,
                  itemBuilder: (_, index) {
                    final worker = _workers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 1.5,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primary.withOpacity(0.12),
                          child: Text(
                            worker.name.isNotEmpty
                                ? worker.name[0].toUpperCase()
                                : 'W',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              worker.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: worker.status == 'active'
                                    ? const Color(0xFFE8F5E9)
                                    : const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                worker.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: worker.status == 'active'
                                      ? AppTheme.primary
                                      : AppTheme.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.role,
                              style: const TextStyle(
                                color: AppTheme.textMedium,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${worker.mobile}  -  Rs.${worker.salary.toStringAsFixed(0)}/month',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                              onPressed: () => _showWorkerForm(worker),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.danger,
                                size: 20,
                              ),
                              onPressed: () => _deleteWorker(worker),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
