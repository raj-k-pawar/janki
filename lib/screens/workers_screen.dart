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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await ApiService().getWorkers();
    if (r['success'] == true && mounted) {
      setState(() {
        _workers = (r['workers'] as List).map((j) => WorkerModel.fromJson(j)).toList();
        _loading = false;
      });
    } else { setState(() => _loading = false); }
  }

  void _showForm([WorkerModel? w]) {
    final nameC = TextEditingController(text: w?.name ?? '');
    final roleC = TextEditingController(text: w?.role ?? '');
    final mobC  = TextEditingController(text: w?.mobile ?? '');
    final salC  = TextEditingController(text: w?.salary.toString() ?? '0');
    String status = w?.status ?? 'active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Text(w == null ? 'Add Worker' : 'Edit Worker',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
            const SizedBox(height: 14),
            _tf(nameC, 'Full Name', Icons.person_outline),
            const SizedBox(height: 10),
            _tf(roleC, 'Role (e.g. Guard, Cook)', Icons.work_outline),
            const SizedBox(height: 10),
            _tf(mobC, 'Mobile', Icons.phone_outlined, kb: TextInputType.phone),
            const SizedBox(height: 10),
            _tf(salC, 'Monthly Salary (₹)', Icons.currency_rupee, kb: TextInputType.number),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Status:', style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
              const SizedBox(width: 14),
              _sChip(ctx, 'Active', 'active', status, (v) => setS(() => status = v)),
              const SizedBox(width: 8),
              _sChip(ctx, 'Inactive', 'inactive', status, (v) => setS(() => status = v)),
            ]),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () async {
                final wm = WorkerModel(id: w?.id, name: nameC.text.trim(),
                    role: roleC.text.trim(), mobile: mobC.text.trim(),
                    salary: double.tryParse(salC.text) ?? 0, status: status);
                final r = w?.id != null
                    ? await ApiService().updateWorker(w!.id!, wm.toJson())
                    : await ApiService().addWorker(wm.toJson());
                if (r['success'] == true && ctx.mounted) { Navigator.pop(ctx); _load(); }
              },
              child: Text(w == null ? 'Add Worker' : 'Update Worker'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String label, IconData icon, {TextInputType? kb}) => TextField(
    controller: c, keyboardType: kb,
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: AppTheme.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      filled: true, fillColor: const Color(0xFFF8FCF8),
    ),
  );

  Widget _sChip(BuildContext ctx, String label, String val, String cur, Function(String) cb) =>
      GestureDetector(
        onTap: () => cb(val),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: cur == val ? (val == 'active' ? AppTheme.primary : AppTheme.danger) : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(
              color: cur == val ? Colors.white : AppTheme.textMedium,
              fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(title: const Text('Manage Workers'), backgroundColor: AppTheme.primary,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load)]),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showForm(),
      backgroundColor: AppTheme.secondary,
      icon: const Icon(Icons.add),
      label: const Text('Add Worker'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        : _workers.isEmpty
            ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.badge_outlined, size: 56, color: AppTheme.textLight),
                SizedBox(height: 10),
                Text('No workers added yet', style: TextStyle(color: AppTheme.textMedium)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _workers.length,
                itemBuilder: (_, i) {
                  final w = _workers[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1.5,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.12),
                        child: Text(w.name.isNotEmpty ? w.name[0].toUpperCase() : 'W',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                      ),
                      title: Row(children: [
                        Text(w.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: w.status == 'active' ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(w.status.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                              color: w.status == 'active' ? AppTheme.primary : AppTheme.danger)),
                        ),
                      ]),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(w.role, style: const TextStyle(color: AppTheme.textMedium, fontSize: 12)),
                        Text('${w.mobile}  •  ₹${w.salary.toStringAsFixed(0)}/month',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                            onPressed: () => _showForm(w)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
                          onPressed: () async {
                            final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
                              title: const Text('Delete Worker?'),
                              content: Text('Remove ${w.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ));
                            if (ok == true) { await ApiService().deleteWorker(w.id!); _load(); }
                          },
                        ),
                      ]),
                    ),
                  );
                },
              ),
  );
}
