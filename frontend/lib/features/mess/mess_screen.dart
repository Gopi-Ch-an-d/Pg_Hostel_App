import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

final _messMenuProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final weekOf = '${monday.year}-${monday.month.toString().padLeft(2,'0')}-${monday.day.toString().padLeft(2,'0')}';
  try {
    final res = await ApiClient().get('/mess/menu', params: {'weekOf': weekOf});
    return res.data as List;
  } catch (_) { return []; }
});

class MessScreen extends ConsumerWidget {
  const MessScreen({super.key});

  static const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  static const sampleMenu = [
    {'day': 'Monday', 'breakfast': 'Idli, Sambar, Chutney', 'lunch': 'Rice, Dal, Sabzi', 'dinner': 'Roti, Paneer, Salad'},
    {'day': 'Tuesday', 'breakfast': 'Puri, Aloo Bhaji', 'lunch': 'Rice, Rajma, Papad', 'dinner': 'Roti, Dal Makhani'},
    {'day': 'Wednesday', 'breakfast': 'Dosa, Coconut Chutney', 'lunch': 'Roti, Paneer Curry', 'dinner': 'Rice, Sambar, Fry'},
    {'day': 'Thursday', 'breakfast': 'Upma, Tea', 'lunch': 'Biryani, Raita', 'dinner': 'Roti, Chana Masala'},
    {'day': 'Friday', 'breakfast': 'Poha, Banana', 'lunch': 'Fish Curry, Rice', 'dinner': 'Roti, Veg Curry'},
    {'day': 'Saturday', 'breakfast': 'Chole Bhature', 'lunch': 'Veg Pulao, Papad', 'dinner': 'Roti, Dal, Sabzi'},
    {'day': 'Sunday', 'breakfast': 'Special Thali', 'lunch': 'Poori, 2 Veg, Dal, Sweet', 'dinner': 'Roti, Biryani'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authProvider).user?.isAdmin ?? false;
    final today = DateTime.now().weekday - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Mess & Food'), actions: [
        if (isAdmin) IconButton(icon: const Icon(Icons.add_outlined), onPressed: () => _showAddMenuDialog(context, ref)),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Stats
          const Row(children: [
            Expanded(child: MetricCard(label: 'Mess Fee/Month', value: '₹3,000', icon: Icons.restaurant)),
            SizedBox(width: 10),
            Expanded(child: MetricCard(label: 'Subscribers', value: '48', icon: Icons.people_outline)),
          ]),
          const SizedBox(height: 16),

          // Weekly menu
          SectionCard(
            title: 'This Week\'s Menu',
            trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(10)),
              child: const Text('Live', style: TextStyle(fontSize: 10, color: AppTheme.primaryDark, fontWeight: FontWeight.w600))),
            child: Column(children: List.generate(sampleMenu.length, (i) {
              final day = sampleMenu[i];
              final isToday = i == today;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isToday ? AppTheme.primaryLight : AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isToday ? AppTheme.primary.withOpacity(0.4) : Colors.transparent),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(day['day']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isToday ? AppTheme.primaryDark : AppTheme.textPrimary)),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Today', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600))),
                    ],
                  ]),
                  const SizedBox(height: 6),
                  _MealRow(icon: '☕', label: 'Breakfast', value: day['breakfast']!),
                  _MealRow(icon: '🍱', label: 'Lunch', value: day['lunch']!),
                  _MealRow(icon: '🌙', label: 'Dinner', value: day['dinner']!),
                ]),
              );
            })),
          ),
          const SizedBox(height: 16),

          // Feedback section
          const SectionCard(
            title: 'Student Feedback',
            child: Column(children: [
              _FeedbackItem('Room 203', 'Food quality is good. Would love more variety on weekends.', '4.2'),
              _FeedbackItem('Room 112', 'Loved the biryani on Friday! Keep it up.', '4.8'),
              _FeedbackItem('Room 301', 'Hot water availability in morning needs improvement.', '3.5'),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showAddMenuDialog(BuildContext context, WidgetRef ref) {
    final bfCtrl = TextEditingController();
    final lunchCtrl = TextEditingController();
    final dinnerCtrl = TextEditingController();
    int selectedDay = 1;

    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Update Menu'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<int>(
          initialValue: selectedDay,
          items: List.generate(7, (i) => DropdownMenuItem(value: i+1, child: Text(days[i]))),
          onChanged: (v) => selectedDay = v!,
          decoration: const InputDecoration(labelText: 'Day'),
        ),
        const SizedBox(height: 10),
        TextFormField(controller: bfCtrl, decoration: const InputDecoration(labelText: 'Breakfast')),
        const SizedBox(height: 10),
        TextFormField(controller: lunchCtrl, decoration: const InputDecoration(labelText: 'Lunch')),
        const SizedBox(height: 10),
        TextFormField(controller: dinnerCtrl, decoration: const InputDecoration(labelText: 'Dinner')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(dialogContext);
          final now = DateTime.now();
          final monday = now.subtract(Duration(days: now.weekday - 1));
          await ApiClient().post('/mess/menu', data: {
            'dayOfWeek': selectedDay, 'breakfast': bfCtrl.text,
            'lunch': lunchCtrl.text, 'dinner': dinnerCtrl.text,
            'weekOf': '${monday.year}-${monday.month.toString().padLeft(2,'0')}-${monday.day.toString().padLeft(2,'0')}',
          });
          ref.invalidate(_messMenuProvider);
        }, child: const Text('Save')),
      ],
    ));
  }
}

class _MealRow extends StatelessWidget {
  final String icon, label, value;
  const _MealRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 6),
      SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
    ]),
  );
}

class _FeedbackItem extends StatelessWidget {
  final String room, text, rating;
  const _FeedbackItem(this.room, this.text, this.rating);

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.surfaceSecondary, borderRadius: BorderRadius.circular(8)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(room, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const Spacer(),
        Text('⭐ $rating', style: const TextStyle(fontSize: 12, color: AppTheme.warning)),
      ]),
      const SizedBox(height: 4),
      Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    ]),
  );
}
