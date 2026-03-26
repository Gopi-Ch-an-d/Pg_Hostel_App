import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const MetricCard({super.key, required this.label, required this.value,
    this.subtitle, this.valueColor, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[Icon(icon, size: 16, color: AppTheme.textSecondary), const SizedBox(width: 6)],
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 1)),
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
          ],
        ]),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;
  final double? fontSize;

  const StatusBadge({super.key, required this.status, this.label, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final text = label ?? _formatStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.statusBgColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: fontSize ?? 11, fontWeight: FontWeight.w500, color: AppTheme.statusColor(status))),
    );
  }

  String _formatStatus(String s) => s.replaceAll('_', ' ');
}

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets? padding;

  const SectionCard({super.key, this.title, required this.child, this.trailing, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
              if (trailing != null) trailing!,
            ]),
          ),
        Padding(padding: padding ?? (title != null ? const EdgeInsets.all(16) : EdgeInsets.zero), child: child),
      ]),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? valueWidget;

  const InfoRow({super.key, required this.label, this.value = '', this.valueColor, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        valueWidget ?? Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? AppTheme.textPrimary)),
      ]),
    );
  }
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 0.5, color: AppTheme.border);
}

class EmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({super.key, required this.message, this.subtitle,
    this.icon = Icons.inbox_outlined, this.onAction, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: AppTheme.textTertiary),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary), textAlign: TextAlign.center),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel ?? 'Action')),
          ],
        ]),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppTheme.primary));
}

class ErrorWidget2 extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorWidget2({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: AppTheme.danger),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ]),
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  final String name;
  final double size;
  final Color? bgColor;
  final Color? textColor;

  const AvatarCircle({super.key, required this.name, this.size = 36, this.bgColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: bgColor ?? AppTheme.primaryLight, shape: BoxShape.circle),
      child: Center(child: Text(initials, style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w600, color: textColor ?? AppTheme.primaryDark))),
    );
  }
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  const SearchField({super.key, this.hint = 'Search...', required this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textTertiary),
        filled: true, fillColor: AppTheme.surfaceSecondary,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const FilterChips({super.key, required this.options, this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _Chip(label: 'All', selected: selected == null, onTap: () => onChanged(null)),
        ...options.map((o) => _Chip(label: o, selected: selected == o, onTap: () => onChanged(o))),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: 0.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppTheme.textSecondary)),
      ),
    );
  }
}
