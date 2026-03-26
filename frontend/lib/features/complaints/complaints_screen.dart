import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/complaints_provider.dart';
import '../../core/models/complaint_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;
    final filter = ref.watch(complaintsFilterProvider);
    final complaintsAsync = ref.watch(complaintsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Complaints')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddComplaintDialog(context, ref),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Complaint', style: TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        Container(
          color: AppTheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilterChips(
            options: const ['PENDING', 'IN_PROGRESS', 'RESOLVED'],
            selected: filter,
            onChanged: (v) => ref.read(complaintsFilterProvider.notifier).state = v,
          ),
        ),
        const AppDivider(),
        Expanded(child: complaintsAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorWidget2(message: 'Failed to load complaints', onRetry: () => ref.invalidate(complaintsProvider)),
          data: (complaints) => complaints.isEmpty
              ? const EmptyState(message: 'No complaints found', icon: Icons.report_problem_outlined, subtitle: 'All clear!')
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(complaintsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: complaints.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ComplaintCard(
                        complaint: complaints[i],
                        isAdmin: isAdmin,
                        onUpdate: (status, notes) => _updateComplaint(context, ref, complaints[i].id, status, notes)),
                  ),
                ),
        )),
      ]),
    );
  }

  Future<void> _updateComplaint(BuildContext context, WidgetRef ref, String id, String status, String? notes) async {
    try {
      await ApiClient().put('/complaints/$id', data: {'status': status, 'adminNotes': notes});
      ref.invalidate(complaintsProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status'), backgroundColor: AppTheme.primary));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
    }
  }

  void _showAddComplaintDialog(BuildContext context, WidgetRef ref) {
    final types = ['WATER', 'ELECTRICITY', 'WIFI', 'CLEANLINESS', 'OTHER'];
    String? selectedType;
    String? selectedStudentId;
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final studentsAsync = ref.watch(minimalStudentsProvider);

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: const Text('Raise Complaint'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Student Selection
                  studentsAsync.when(
                    data: (students) => DropdownButtonFormField<String>(
                      initialValue: selectedStudentId,
                      hint: const Text('Select Tenant'),
                      decoration: const InputDecoration(labelText: 'Tenant Name'),
                      items: students.map((s) => DropdownMenuItem(
                        value: s['id'] as String,
                        child: Text(s['name'] as String, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (v) => setState(() => selectedStudentId = v),
                      dropdownColor: Colors.white,
                    ),
                    loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const Text('Error loading students', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),

                  // Complaint Type
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    hint: const Text('Complaint Type'),
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: types.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (v) => setState(() => selectedType = v),
                    dropdownColor: Colors.white,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What is the issue?',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: (selectedStudentId == null || selectedType == null) ? null : () async {
                    final nav = Navigator.of(ctx);
                    try {
                      await ApiClient().post('/complaints', data: {
                        'studentId': selectedStudentId,
                        'type': selectedType,
                        'description': descCtrl.text,
                      });
                      ref.invalidate(complaintsProvider);
                      nav.pop();
                    } catch (_) {
                      // Error handled by ApiClient interceptor or snackbar
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isAdmin;
  final Function(String status, String? notes) onUpdate;
  const _ComplaintCard({required this.complaint, required this.isAdmin, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    switch (complaint.type) {
      case 'WATER': iconBg = const Color(0xFFE6F1FB); break;
      case 'ELECTRICITY': iconBg = AppTheme.warningLight; break;
      case 'WIFI': iconBg = AppTheme.primaryLight; break;
      default: iconBg = AppTheme.surfaceSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(children: [
        Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(complaint.typeIcon, style: const TextStyle(fontSize: 16)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${complaint.type} Issue', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${complaint.student?.name ?? 'Unknown'} • Room ${complaint.student?.room?.roomNumber ?? ''}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
          StatusBadge(status: complaint.status),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.surfaceSecondary, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            Expanded(child: Text(complaint.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
          ]),
        ),
        if (complaint.adminNotes != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.note_outlined, size: 14, color: AppTheme.textTertiary),
            const SizedBox(width: 4),
            Expanded(child: Text('Admin: ${complaint.adminNotes}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary))),
          ]),
        ],
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(DateFormat('dd MMM yyyy').format(DateTime.parse(complaint.createdAt)),
              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
          if (isAdmin && complaint.status != 'RESOLVED') Row(children: [
            if (complaint.status == 'PENDING')
              _StatusBtn('In Progress', AppTheme.warning, () => _promptUpdate(context, 'IN_PROGRESS')),
            const SizedBox(width: 8),
            _StatusBtn('Resolved', AppTheme.primary, () => _promptUpdate(context, 'RESOLVED')),
          ]),
        ]),
      ]),
    );
  }

  void _promptUpdate(BuildContext context, String status) {
    final notesCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text('Mark as ${status.replaceAll('_', ' ')}'),
      content: TextFormField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Admin Notes (optional)')),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { 
          Navigator.of(ctx).pop(); 
          onUpdate(status, notesCtrl.text.isEmpty ? null : notesCtrl.text); 
        }, child: const Text('Confirm')),
      ],
    ));
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatusBtn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ),
  );
}
