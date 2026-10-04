import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../models.dart';

const _expenseCategories = [
  'Market',
  'Ev',
  'Faturalar',
  'Ulaşım',
  'Sağlık',
  'Eğitim',
  'Sosyal',
  'Alışveriş',
  'Diğer',
];
const _incomeCategories = [
  'Maaş',
  'Ek gelir',
  'Burs',
  'Yatırım',
  'İade',
  'Diğer',
];
const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

final _currency = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 0,
);
final _currencyDetailed = NumberFormat.currency(
  locale: 'tr_TR',
  symbol: '₺',
  decimalDigits: 2,
);

String _monthLabel(DateTime date) => '${_months[date.month - 1]} ${date.year}';
String _dateLabel(DateTime date) {
  const shortMonths = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  return '${date.day} ${shortMonths[date.month - 1]} ${date.year}';
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Future<void> _showTransaction([WalletTransaction? transaction]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => TransactionForm(
        controller: widget.controller,
        transaction: transaction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Genel Bakış', 'İşlemler', 'Bütçeler', 'Ayarlar'];
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titles[_index],
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            if (_index != 3)
              Text(
                _monthLabel(widget.controller.selectedMonth),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (_index != 3) ...[
            IconButton(
              tooltip: 'Ay seç',
              onPressed: () => _showMonthPicker(context, widget.controller),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
            IconButton(
              tooltip: 'Yenile',
              onPressed: widget.controller.isBusy
                  ? null
                  : widget.controller.refresh,
              icon: widget.controller.isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.3),
                    )
                  : const Icon(Icons.sync_rounded),
            ),
          ],
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          OverviewPage(controller: widget.controller, onAdd: _showTransaction),
          TransactionsPage(
            controller: widget.controller,
            onEdit: _showTransaction,
          ),
          BudgetsPage(controller: widget.controller),
          SettingsPage(controller: widget.controller),
        ],
      ),
      floatingActionButton: _index == 0 || _index == 1
          ? FloatingActionButton.extended(
              onPressed: _showTransaction,
              icon: const Icon(Icons.add_rounded),
              label: const Text('İşlem ekle'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Özet',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'İşlemler',
          ),
          NavigationDestination(
            icon: Icon(Icons.donut_large_outlined),
            selectedIcon: Icon(Icons.donut_large_rounded),
            label: 'Bütçe',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.controller,
    required this.onAdd,
  });
  final AppController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenses = controller.selectedTransactions
        .where((item) => !item.isIncome)
        .toList();
    final categoryTotals = <String, double>{};
    for (final item in expenses) {
      categoryTotals[item.category] =
          (categoryTotals[item.category] ?? 0) + item.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
        children: [
          _ConnectionBanner(controller: controller),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, const Color(0xFF234B41)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: .2),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bu ay kalan',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white70,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currency.format(controller.selectedBalance),
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _MiniTotal(
                        label: 'Gelir',
                        value: controller.selectedIncome,
                        icon: Icons.south_west_rounded,
                        color: const Color(0xFFB8F2C8),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _MiniTotal(
                        label: 'Gider',
                        value: controller.selectedExpense,
                        icon: Icons.north_east_rounded,
                        color: const Color(0xFFFFD4B0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Harcama dağılımı',
            action: expenses.isEmpty ? null : '${expenses.length} işlem',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: expenses.isEmpty
                  ? _EmptyState(
                      icon: Icons.pie_chart_outline_rounded,
                      title: 'Henüz gider yok',
                      description:
                          'Bu ayın harcamalarını eklediğinde dağılımı burada göreceksin.',
                      buttonLabel: 'İlk işlemi ekle',
                      onPressed: onAdd,
                    )
                  : SizedBox(
                      height: 210,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 40,
                                sectionsSpace: 3,
                                startDegreeOffset: -90,
                                sections: [
                                  for (
                                    var i = 0;
                                    i < sortedCategories.take(5).length;
                                    i++
                                  )
                                    PieChartSectionData(
                                      value: sortedCategories[i].value,
                                      color: _categoryColor(i, theme),
                                      radius: 30,
                                      showTitle: false,
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (
                                  var i = 0;
                                  i < sortedCategories.take(5).length;
                                  i++
                                )
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: _categoryColor(i, theme),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            sortedCategories[i].key,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          _currency.format(
                                            sortedCategories[i].value,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Bütçe durumu',
            action: controller.selectedBudgets.isEmpty
                ? null
                : '${controller.selectedBudgets.length} kategori',
          ),
          const SizedBox(height: 12),
          if (controller.selectedBudgets.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _EmptyState(
                  icon: Icons.flag_outlined,
                  title: 'Bütçe sınırı belirle',
                  description:
                      'Kategorilere aylık sınır koyarak harcamalarını daha rahat kontrol et.',
                ),
              ),
            )
          else
            ...controller.selectedBudgets
                .take(3)
                .map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BudgetProgress(
                      budget: budget,
                      spent: controller.spentForCategory(budget.category),
                    ),
                  ),
                ),
          const SizedBox(height: 14),
          _SectionHeader(
            title: 'Son işlemler',
            action: controller.selectedTransactions.isEmpty ? null : 'Bu ay',
          ),
          const SizedBox(height: 12),
          if (controller.selectedTransactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'İşlem bulunamadı',
                  description: 'Seçili ayda henüz bir hareket yok.',
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: controller.selectedTransactions
                    .take(5)
                    .map((item) => TransactionTile(transaction: item))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({
    super.key,
    required this.controller,
    required this.onEdit,
  });
  final AppController controller;
  final ValueChanged<WalletTransaction> onEdit;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  String _filter = 'Tümü';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final items = widget.controller.selectedTransactions.where((item) {
      final matchesQuery =
          query.isEmpty ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      final matchesType =
          _filter == 'Tümü' ||
          (_filter == 'Gelir' && item.isIncome) ||
          (_filter == 'Gider' && !item.isIncome);
      return matchesQuery && matchesType;
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Açıklama veya kategori ara',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Aramayı temizle',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            children: [
              for (final filter in ['Tümü', 'Gelir', 'Gider'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? _EmptyState(
                  icon: Icons.manage_search_rounded,
                  title: query.isEmpty ? 'Bu ay işlem yok' : 'Sonuç bulunamadı',
                  description: query.isEmpty
                      ? 'Yeni bir gelir veya gider ekleyerek başla.'
                      : 'Arama kelimeni ya da filtreyi değiştirmeyi dene.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) =>
                          _confirmDelete(context, item.description),
                      onDismissed: (_) async {
                        try {
                          await widget.controller.deleteTransaction(item);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('İşlem silindi.')),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'İşlem silinemedi; liste geri yüklendi.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 22),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => widget.onEdit(item),
                          child: TransactionTile(
                            transaction: item,
                            showChevron: true,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key, required this.controller});
  final AppController controller;

  Future<void> _showBudgetForm(BuildContext context, [Budget? budget]) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => BudgetForm(controller: controller, budget: budget),
      );

  @override
  Widget build(BuildContext context) {
    final budgets = controller.selectedBudgets;
    final totalBudget = budgets.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalSpent = budgets.fold<double>(
      0,
      (sum, item) => sum + controller.spentForCategory(item.category),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 110),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aylık bütçe',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  _currency.format(totalBudget),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_currency.format(totalSpent)} harcandı',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: totalBudget == 0
                      ? 0
                      : (totalSpent / totalBudget).clamp(0, 1),
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(8),
                  color: totalSpent > totalBudget
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => _showBudgetForm(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Kategori bütçesi ekle'),
        ),
        const SizedBox(height: 22),
        if (budgets.isEmpty)
          _EmptyState(
            icon: Icons.donut_large_outlined,
            title: 'Henüz bütçe yok',
            description:
                'En çok harcadığın kategoriler için aylık hedef belirle.',
          )
        else
          ...budgets.map(
            (budget) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => _showBudgetForm(context, budget),
                child: _BudgetProgress(
                  budget: budget,
                  spent: controller.spentForCategory(budget.category),
                  showActions: true,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});
  final AppController controller;

  Future<void> _copyCsv(BuildContext context) async {
    const separator = ';';
    final rows = <String>[
      'Tarih${separator}Tür${separator}Kategori${separator}Açıklama${separator}Tutar',
    ];
    for (final item in controller.transactions) {
      rows.add(
        [
          item.date.toIso8601String().split('T').first,
          item.isIncome ? 'Gelir' : 'Gider',
          item.category,
          item.description.replaceAll(separator, ','),
          item.amount.toStringAsFixed(2),
        ].join(separator),
      );
    }
    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem dökümü panoya kopyalandı.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    controller.user!.name.trim().isEmpty
                        ? '?'
                        : controller.user!.name.trim()[0].toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.user!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        controller.user!.email,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusDot(online: controller.isOnline),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Görünüm'),
        const SizedBox(height: 10),
        Card(
          child: RadioGroup<ThemeMode>(
            groupValue: controller.themeMode,
            onChanged: (value) => controller.setThemeMode(value!),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: const Text('Cihaz ayarını kullan'),
                  secondary: const Icon(Icons.brightness_auto_outlined),
                ),
                const Divider(height: 1, indent: 64),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: const Text('Açık tema'),
                  secondary: const Icon(Icons.light_mode_outlined),
                ),
                const Divider(height: 1, indent: 64),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: const Text('Koyu tema'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Veriler'),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.copy_all_outlined),
                title: const Text('İşlem dökümünü kopyala'),
                subtitle: const Text('Excel ile açılabilen CSV biçimi'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _copyCsv(context),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('Demo verilerini yenile'),
                subtitle: const Text('Örnek işlem ve bütçeleri geri yükler'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  if (await _confirmReset(context)) {
                    await controller.resetDemoData();
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Demo verileri yenilendi.'),
                        ),
                      );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: controller.logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Oturumu kapat'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Cüzdanım · Sürüm 1.0.0',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    required this.controller,
    this.transaction,
  });
  final AppController controller;
  final WalletTransaction? transaction;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late TransactionType _type;
  late String _category;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.transaction;
    _type = item?.type ?? TransactionType.expense;
    _category = item?.category ?? _expenseCategories.first;
    _date = item?.date ?? DateTime.now();
    _amountController = TextEditingController(
      text: item == null
          ? ''
          : item.amount.toStringAsFixed(2).replaceAll('.', ','),
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    await widget.controller.saveTransaction(
      WalletTransaction(
        id: widget.transaction?.id ?? 0,
        userId: widget.controller.user!.id,
        amount: amount,
        type: _type,
        category: _category,
        description: _descriptionController.text.trim(),
        date: _date,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _type == TransactionType.income
        ? _incomeCategories
        : _expenseCategories;
    if (!categories.contains(_category)) _category = categories.first;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.transaction == null ? 'Yeni işlem' : 'İşlemi düzenle',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Gider'),
                    icon: Icon(Icons.north_east_rounded),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Gelir'),
                    icon: Icon(Icons.south_west_rounded),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) => setState(() {
                  _type = value.first;
                  _category = _type == TransactionType.income
                      ? _incomeCategories.first
                      : _expenseCategories.first;
                }),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _amountController,
                autofocus: widget.transaction == null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  prefixText: '₺ ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').replaceAll(',', '.'),
                  );
                  return amount == null || amount <= 0
                      ? 'Sıfırdan büyük bir tutar yaz.'
                      : null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Örn. Haftalık market',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Kısa bir açıklama yaz.'
                    : null,
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: _date,
                  );
                  if (date != null) setState(() => _date = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tarih',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(_dateLabel(_date)),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        widget.transaction == null
                            ? 'İşlemi kaydet'
                            : 'Değişiklikleri kaydet',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BudgetForm extends StatefulWidget {
  const BudgetForm({super.key, required this.controller, this.budget});
  final AppController controller;
  final Budget? budget;

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late String _category = widget.budget?.category ?? _expenseCategories.first;
  late final TextEditingController _amountController = TextEditingController(
    text: widget.budget == null ? '' : widget.budget!.amount.toStringAsFixed(0),
  );
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.budget == null ? 'Bütçe ekle' : 'Bütçeyi düzenle',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (widget.budget != null)
                IconButton(
                  tooltip: 'Bütçeyi sil',
                  onPressed: () async {
                    await widget.controller.deleteBudget(widget.budget!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Kategori',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: _expenseCategories
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Aylık sınır',
              prefixText: '₺ ',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            validator: (value) {
              final amount = double.tryParse(
                (value ?? '').replaceAll(',', '.'),
              );
              return amount == null || amount <= 0
                  ? 'Sıfırdan büyük bir tutar yaz.'
                  : null;
            },
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _saving = true);
                    await widget.controller.saveBudget(
                      Budget(
                        id: widget.budget?.id ?? 0,
                        userId: widget.controller.user!.id,
                        category: _category,
                        amount: double.parse(
                          _amountController.text.replaceAll(',', '.'),
                        ),
                        month: widget.controller.selectedMonth,
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text(
              widget.budget == null
                  ? 'Bütçeyi kaydet'
                  : 'Değişiklikleri kaydet',
            ),
          ),
        ],
      ),
    ),
  );
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.showChevron = false,
  });
  final WalletTransaction transaction;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome
        ? const Color(0xFF2E8B57)
        : Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _categoryIcon(transaction.category),
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${transaction.category} · ${_dateLabel(transaction.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (transaction.pendingSync) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.cloud_off_outlined, size: 13),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${transaction.isIncome ? '+' : '-'}${_currencyDetailed.format(transaction.amount)}',
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          if (showChevron)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.chevron_right_rounded, size: 20),
            ),
        ],
      ),
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({
    required this.budget,
    required this.spent,
    this.showActions = false,
  });
  final Budget budget;
  final double spent;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final ratio = budget.amount == 0 ? 0.0 : spent / budget.amount;
    final exceeded = ratio > 1;
    final color = exceeded
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _categoryIcon(budget.category),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exceeded
                            ? '${_currency.format(spent - budget.amount)} aşıldı'
                            : '${_currency.format(budget.amount - spent)} kaldı',
                        style: TextStyle(
                          fontSize: 12,
                          color: exceeded
                              ? color
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (budget.pendingSync) ...[
                        const SizedBox(width: 5),
                        const Icon(Icons.cloud_off_outlined, size: 13),
                      ],
                    ],
                  ),
                ),
                Text(
                  '${_currency.format(spent)} / ${_currency.format(budget.amount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showActions)
                  const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
            const SizedBox(height: 13),
            LinearProgressIndicator(
              value: ratio.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTotal extends StatelessWidget {
  const _MiniTotal({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              _currency.format(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    if (controller.isOnline) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 19,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Çevrimdışı mod · Değişikliklerin bu cihazda korunuyor.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.online});
  final bool online;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: online ? 'Sunucuya bağlı' : 'Çevrimdışı mod',
    child: Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: online
            ? const Color(0xFF35A266)
            : Theme.of(context).colorScheme.outline,
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final String? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      if (action != null)
        Text(
          action!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onPressed,
  });
  final IconData icon;
  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onPressed, child: Text(buttonLabel!)),
          ],
        ],
      ),
    ),
  );
}

Future<void> _showMonthPicker(
  BuildContext context,
  AppController controller,
) async {
  final now = DateTime.now();
  final months = List.generate(
    18,
    (index) => DateTime(now.year, now.month - index),
  );
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ay seç',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: months.length,
                itemBuilder: (_, index) {
                  final month = months[index];
                  final selected =
                      month.year == controller.selectedMonth.year &&
                      month.month == controller.selectedMonth.month;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Text(_monthLabel(month)),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      controller.setSelectedMonth(month);
                      Navigator.pop(sheetContext);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<bool> _confirmDelete(BuildContext context, String description) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('İşlem silinsin mi?'),
        content: Text('“$description” kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    ) ??
    false;

Future<bool> _confirmReset(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo verileri yenilensin mi?'),
        content: const Text(
          'Bu cihazdaki mevcut işlem ve bütçeler örnek verilerle değiştirilecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yenile'),
          ),
        ],
      ),
    ) ??
    false;

IconData _categoryIcon(String category) => switch (category.toLowerCase()) {
  'market' => Icons.shopping_basket_outlined,
  'ev' => Icons.home_outlined,
  'faturalar' || 'fatura' => Icons.receipt_outlined,
  'ulaşım' => Icons.directions_bus_outlined,
  'sağlık' => Icons.health_and_safety_outlined,
  'eğitim' => Icons.school_outlined,
  'sosyal' => Icons.local_cafe_outlined,
  'alışveriş' => Icons.shopping_bag_outlined,
  'maaş' => Icons.work_outline_rounded,
  'ek gelir' => Icons.add_business_outlined,
  'burs' => Icons.workspace_premium_outlined,
  'yatırım' => Icons.trending_up_rounded,
  _ => Icons.more_horiz_rounded,
};

Color _categoryColor(int index, ThemeData theme) => [
  theme.colorScheme.primary,
  const Color(0xFFF0A04B),
  const Color(0xFF6784B8),
  const Color(0xFFB8657B),
  const Color(0xFF7E6AA2),
][index % 5];
