import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;
    final async = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_outlined),
              onPressed: () => _showAddDialog(context, ref),
            ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorWidget2(
            message: 'Failed to load inventory',
            onRetry: () => ref.invalidate(inventoryProvider)),
        data: (items) {
          final damaged =
              items.where((i) => i.damaged > 0 || i.missing > 0).toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(inventoryProvider.future),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (damaged.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.danger.withOpacity(0.3),
                            width: 0.5),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_outlined,
                            color: AppTheme.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${damaged.length} item(s) have damage or missing reports',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Summary cards
                  Row(children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total Items',
                        value: '${items.fold(0, (s, i) => s + i.total)}',
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Good',
                        value: '${items.fold(0, (s, i) => s + i.good)}',
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Damaged',
                        value:
                            '${items.fold(0, (s, i) => s + i.damaged)}',
                        color: AppTheme.danger,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Items list
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.border, width: 0.5),
                    ),
                    child: items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: EmptyState(
                                message: 'No inventory items yet',
                                icon: Icons.inventory_2_outlined),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const AppDivider(),
                            itemBuilder: (_, i) => _InventoryTile(
                              item: items[i],
                              isAdmin: isAdmin,
                              onEdit: () =>
                                  _showEditDialog(context, ref, items[i]),
                              onDelete: isAdmin
                                  ? () => _confirmDelete(context, ref, items[i])
                                  : null,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _AddInventoryDialog(
        // ✅ pass dialogCtx so the dialog pops itself
        dialogContext: dialogCtx,
        onSave: (data) async {
          await ApiClient().post('/inventory', data: data);
          ref.invalidate(inventoryProvider);
        },
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, InventoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _EditInventoryDialog(
        // ✅ pass dialogCtx so the dialog pops itself
        dialogContext: dialogCtx,
        item: item,
        onSave: (data) async {
          await ApiClient().put('/inventory/${item.id}', data: data);
          ref.invalidate(inventoryProvider);
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, InventoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient().delete('/inventory/${item.id}');
        ref.invalidate(inventoryProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item deleted successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
        }
      }
    }
  }
}

// ── Add Dialog ────────────────────────────────────────────────────────────────
class _AddInventoryDialog extends StatefulWidget {
  final BuildContext dialogContext; // ✅ the dialog's own context
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _AddInventoryDialog({
    required this.dialogContext,
    required this.onSave,
  });

  @override
  State<_AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<_AddInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _catCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _goodCtrl = TextEditingController();
  final _dmgCtrl = TextEditingController(text: '0');
  final _misCtrl = TextEditingController(text: '0');
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _totalCtrl.dispose();
    _goodCtrl.dispose();
    _dmgCtrl.dispose();
    _misCtrl.dispose();
    super.dispose();
  }

  void _close() {
    // ✅ Use the dialogContext passed from showDialog's builder
    Navigator.of(widget.dialogContext).pop();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    _close(); // ✅ close immediately before async
    try {
      await widget.onSave({
        'name': _nameCtrl.text.trim(),
        'category': _catCtrl.text.trim(),
        'total': int.tryParse(_totalCtrl.text) ?? 0,
        'good': int.tryParse(_goodCtrl.text) ?? 0,
        'damaged': int.tryParse(_dmgCtrl.text) ?? 0,
        'missing': int.tryParse(_misCtrl.text) ?? 0,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Inventory Item',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _Field(ctrl: _nameCtrl, label: 'Item Name',
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            _Field(ctrl: _catCtrl, label: 'Category (e.g. Furniture)',
                validator: (v) => (v ?? '').isEmpty ? 'Required' : null),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _Field(ctrl: _totalCtrl, label: 'Total',
                      keyboard: TextInputType.number,
                      validator: (v) =>
                          int.tryParse(v ?? '') == null ? 'Number' : null)),
              const SizedBox(width: 10),
              Expanded(
                  child: _Field(ctrl: _goodCtrl, label: 'Good',
                      keyboard: TextInputType.number,
                      validator: (v) =>
                          int.tryParse(v ?? '') == null ? 'Number' : null)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _Field(
                      ctrl: _dmgCtrl,
                      label: 'Damaged',
                      keyboard: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: _Field(
                      ctrl: _misCtrl,
                      label: 'Missing',
                      keyboard: TextInputType.number)),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(
          // ✅ cancel uses _close()
          onPressed: _close,
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: const Text('Add Item'),
        ),
      ],
    );
  }
}

// ── Edit Dialog ───────────────────────────────────────────────────────────────
class _EditInventoryDialog extends StatefulWidget {
  final BuildContext dialogContext; // ✅ dialog's own context
  final InventoryItem item;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _EditInventoryDialog({
    required this.dialogContext,
    required this.item,
    required this.onSave,
  });

  @override
  State<_EditInventoryDialog> createState() => _EditInventoryDialogState();
}

class _EditInventoryDialogState extends State<_EditInventoryDialog> {
  late final TextEditingController _goodCtrl;
  late final TextEditingController _dmgCtrl;
  late final TextEditingController _misCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _goodCtrl = TextEditingController(text: '${widget.item.good}');
    _dmgCtrl = TextEditingController(text: '${widget.item.damaged}');
    _misCtrl = TextEditingController(text: '${widget.item.missing}');
  }

  @override
  void dispose() {
    _goodCtrl.dispose();
    _dmgCtrl.dispose();
    _misCtrl.dispose();
    super.dispose();
  }

  void _close() {
    // ✅ Use dialogContext — guaranteed to be the dialog's own context
    Navigator.of(widget.dialogContext).pop();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    _close(); // ✅ close immediately before async
    try {
      await widget.onSave({
        'good': int.tryParse(_goodCtrl.text) ?? widget.item.good,
        'damaged': int.tryParse(_dmgCtrl.text) ?? widget.item.damaged,
        'missing': int.tryParse(_misCtrl.text) ?? widget.item.missing,
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update: ${widget.item.name}',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const Icon(Icons.inventory_2_outlined,
                size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(widget.item.category,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const Spacer(),
            Text('Total: ${widget.item.total}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: _Field(
                  ctrl: _goodCtrl,
                  label: 'Good',
                  keyboard: TextInputType.number)),
          const SizedBox(width: 10),
          Expanded(
              child: _Field(
                  ctrl: _dmgCtrl,
                  label: 'Damaged',
                  keyboard: TextInputType.number)),
        ]),
        const SizedBox(height: 10),
        _Field(
            ctrl: _misCtrl,
            label: 'Missing',
            keyboard: TextInputType.number),
      ]),
      actions: [
        TextButton(
          // ✅ cancel uses _close()
          onPressed: _close,
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: const Text('Update'),
        ),
      ],
    );
  }
}

// ── Inventory Tile ────────────────────────────────────────────────────────────
class _InventoryTile extends StatelessWidget {
  final InventoryItem item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _InventoryTile({
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    this.onDelete,
  });

  String _icon(String category) {
    switch (category.toLowerCase()) {
      case 'furniture': return '🛏';
      case 'electronics': return '📺';
      case 'appliances': return '🔌';
      default: return '📦';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDamage = item.damaged > 0 || item.missing > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(_icon(item.category),
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(item.category,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textTertiary)),
                ],
              ),
            ),
            if (isAdmin)
              Row(children: [
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: AppTheme.primaryDark),
                  ),
                ),
                if (onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline,
                          size: 16, color: AppTheme.danger),
                    ),
                  ),
                ],
              ]),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatChip(label: 'Total', value: '${item.total}',
                  color: AppTheme.textSecondary,
                  bg: AppTheme.surfaceSecondary),
              _StatChip(label: 'Good', value: '${item.good}',
                  color: AppTheme.primary, bg: AppTheme.primaryLight),
              if (item.damaged > 0)
                _StatChip(label: 'Damaged', value: '${item.damaged}',
                    color: AppTheme.danger, bg: AppTheme.dangerLight),
              if (item.missing > 0)
                _StatChip(label: 'Missing', value: '${item.missing}',
                    color: AppTheme.warning, bg: AppTheme.warningLight),
            ],
          ),
          if (hasDamage) ...[
            const SizedBox(height: 8),
            const Row(children: [
              Icon(Icons.info_outline,
                  size: 13, color: AppTheme.danger),
              SizedBox(width: 4),
              Text('Needs attention',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.danger,
                      fontWeight: FontWeight.w500)),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── Reusable text field ───────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    this.keyboard,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }
}