import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController({ApiService? api}) : api = api ?? ApiService();

  final ApiService api;
  SharedPreferences? _prefs;

  WalletUser? user;
  List<WalletTransaction> transactions = [];
  List<Budget> budgets = [];
  ThemeMode themeMode = ThemeMode.system;
  bool isReady = false;
  bool isBusy = false;
  bool isOnline = false;
  String? errorMessage;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final Set<int> _pendingTransactionDeletes = {};
  final Set<int> _pendingBudgetDeletes = {};

  static const _userKey = 'wallet_user';
  static const _transactionsKey = 'wallet_transactions';
  static const _budgetsKey = 'wallet_budgets';
  static const _themeKey = 'wallet_theme';
  static const _transactionDeletesKey = 'wallet_transaction_deletes';
  static const _budgetDeletesKey = 'wallet_budget_deletes';

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final storedTheme = _prefs?.getString(_themeKey);
    themeMode = storedTheme == 'dark'
        ? ThemeMode.dark
        : storedTheme == 'light'
        ? ThemeMode.light
        : ThemeMode.system;
    final rawUser = _prefs?.getString(_userKey);
    if (rawUser != null) {
      user = WalletUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      _loadLocalData();
      await refresh(silent: true);
    }
    isReady = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _runBusy(() async {
      final loggedIn = await api.login(email, password);
      await _setUser(loggedIn);
      await refresh(silent: true);
    });
  }

  Future<void> register(String name, String email, String password) async {
    await _runBusy(() async {
      final registered = await api.register(name, email, password);
      await _setUser(registered);
      await refresh(silent: true);
    });
  }

  Future<void> continueWithDemo() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    user = const WalletUser(
      id: 1,
      name: 'Demo Kullanıcı',
      email: 'demo@cuzdanim.app',
    );
    _loadLocalData();
    if (transactions.isEmpty) {
      transactions = _demoTransactions();
      budgets = _demoBudgets();
      await _saveLocalData();
    }
    await _prefs?.setString(_userKey, jsonEncode(user!.toJson()));
    await refresh(silent: true);
    isBusy = false;
    notifyListeners();
  }

  Future<void> refresh({bool silent = false}) async {
    if (user == null) return;
    if (!silent) {
      isBusy = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      isOnline = await api.healthCheck();
      if (isOnline) {
        await _syncPendingChanges();
        final results = await Future.wait<dynamic>([
          api.getTransactions(user!.id),
          api.getBudgets(user!.id),
        ]);
        final remoteTransactions = results[0] as List<WalletTransaction>;
        final remoteBudgets = results[1] as List<Budget>;
        if (remoteTransactions.isNotEmpty || transactions.isEmpty) {
          transactions = remoteTransactions;
        }
        if (remoteBudgets.isNotEmpty || budgets.isEmpty)
          budgets = remoteBudgets;
        if (transactions.isNotEmpty &&
            !transactions.any(
              (item) =>
                  item.date.year == selectedMonth.year &&
                  item.date.month == selectedMonth.month,
            )) {
          final latest = transactions
              .reduce((a, b) => a.date.isAfter(b.date) ? a : b)
              .date;
          selectedMonth = DateTime(latest.year, latest.month);
        }
        await _saveLocalData();
      }
    } catch (error) {
      isOnline = false;
      if (!silent) errorMessage = _messageOf(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> saveTransaction(WalletTransaction draft) async {
    if (user == null) return;
    final isNew = draft.id <= 0;
    final localId = isNew ? -DateTime.now().millisecondsSinceEpoch : draft.id;
    var saved = draft.copyWith(
      id: localId,
      userId: user!.id,
      pendingSync: !isOnline,
    );
    try {
      if (isOnline)
        saved = await api.saveTransaction(saved.copyWith(id: draft.id));
    } catch (_) {
      isOnline = false;
      saved = saved.copyWith(pendingSync: true);
    }
    final index = transactions.indexWhere((item) => item.id == draft.id);
    if (index >= 0) {
      transactions[index] = saved;
    } else {
      transactions.add(saved);
    }
    transactions.sort((a, b) => b.date.compareTo(a.date));
    await _saveLocalData();
    notifyListeners();
  }

  Future<void> deleteTransaction(WalletTransaction transaction) async {
    final oldIndex = transactions.indexOf(transaction);
    transactions.remove(transaction);
    await _saveLocalData();
    notifyListeners();
    try {
      if (isOnline && transaction.id > 0) {
        await api.deleteTransaction(transaction.id, transaction.userId);
      } else if (transaction.id > 0) {
        _pendingTransactionDeletes.add(transaction.id);
        await _saveLocalData();
      }
    } catch (error) {
      transactions.insert(oldIndex < 0 ? 0 : oldIndex, transaction);
      await _saveLocalData();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> saveBudget(Budget draft) async {
    if (user == null) return;
    final isNew = draft.id <= 0;
    var saved = draft.copyWith(
      id: isNew ? -DateTime.now().millisecondsSinceEpoch : draft.id,
      pendingSync: !isOnline,
    );
    try {
      if (isOnline)
        saved = await api
            .saveBudget(draft)
            .then((value) => value.copyWith(pendingSync: false));
    } catch (_) {
      isOnline = false;
      saved = saved.copyWith(pendingSync: true);
    }
    final index = budgets.indexWhere((item) => item.id == draft.id);
    if (index >= 0) {
      budgets[index] = saved;
    } else {
      budgets.add(saved);
    }
    await _saveLocalData();
    notifyListeners();
  }

  Future<void> deleteBudget(Budget budget) async {
    final oldIndex = budgets.indexOf(budget);
    budgets.removeWhere((item) => item.id == budget.id);
    await _saveLocalData();
    notifyListeners();
    try {
      if (isOnline && budget.id > 0) {
        await api.deleteBudget(budget.id, budget.userId);
      } else if (budget.id > 0) {
        _pendingBudgetDeletes.add(budget.id);
        await _saveLocalData();
      }
    } catch (_) {
      budgets.insert(oldIndex < 0 ? 0 : oldIndex, budget);
      await _saveLocalData();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    await _prefs?.setString(
      _themeKey,
      value == ThemeMode.dark
          ? 'dark'
          : value == ThemeMode.light
          ? 'light'
          : 'system',
    );
    notifyListeners();
  }

  void setSelectedMonth(DateTime month) {
    selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    _pendingTransactionDeletes.clear();
    _pendingBudgetDeletes.clear();
    transactions = _demoTransactions();
    budgets = _demoBudgets();
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    await _saveLocalData();
    notifyListeners();
  }

  Future<void> logout() async {
    user = null;
    transactions = [];
    budgets = [];
    errorMessage = null;
    isOnline = false;
    _pendingTransactionDeletes.clear();
    _pendingBudgetDeletes.clear();
    await _prefs?.remove(_userKey);
    notifyListeners();
  }

  List<WalletTransaction> get selectedTransactions => transactions
      .where(
        (item) =>
            item.date.year == selectedMonth.year &&
            item.date.month == selectedMonth.month,
      )
      .toList();

  double get selectedIncome => selectedTransactions
      .where((item) => item.isIncome)
      .fold(0, (sum, item) => sum + item.amount);

  double get selectedExpense => selectedTransactions
      .where((item) => !item.isIncome)
      .fold(0, (sum, item) => sum + item.amount);

  double get selectedBalance => selectedIncome - selectedExpense;

  double spentForCategory(String category) => selectedTransactions
      .where((item) => !item.isIncome && item.category == category)
      .fold(0, (sum, item) => sum + item.amount);

  List<Budget> get selectedBudgets => budgets
      .where(
        (item) =>
            item.month.year == selectedMonth.year &&
            item.month.month == selectedMonth.month,
      )
      .toList();

  Future<void> _setUser(WalletUser value) async {
    user = value;
    _loadLocalData();
    await _prefs?.setString(_userKey, jsonEncode(value.toJson()));
  }

  void _loadLocalData() {
    transactions = [];
    budgets = [];
    _pendingTransactionDeletes.clear();
    _pendingBudgetDeletes.clear();
    final rawTransactions = _prefs?.getString(_userKeyFor(_transactionsKey));
    final rawBudgets = _prefs?.getString(_userKeyFor(_budgetsKey));
    if (rawTransactions != null) {
      transactions = (jsonDecode(rawTransactions) as List<dynamic>)
          .map(
            (item) => WalletTransaction.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    if (rawBudgets != null) {
      budgets = (jsonDecode(rawBudgets) as List<dynamic>)
          .map((item) => Budget.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    _pendingTransactionDeletes.addAll(
      (_prefs?.getStringList(_userKeyFor(_transactionDeletesKey)) ?? const [])
          .map(int.tryParse)
          .whereType<int>(),
    );
    _pendingBudgetDeletes.addAll(
      (_prefs?.getStringList(_userKeyFor(_budgetDeletesKey)) ?? const [])
          .map(int.tryParse)
          .whereType<int>(),
    );
  }

  Future<void> _saveLocalData() async {
    await _prefs?.setString(
      _userKeyFor(_transactionsKey),
      jsonEncode(transactions.map((item) => item.toJson()).toList()),
    );
    await _prefs?.setString(
      _userKeyFor(_budgetsKey),
      jsonEncode(budgets.map((item) => item.toJson()).toList()),
    );
    await _prefs?.setStringList(
      _userKeyFor(_transactionDeletesKey),
      _pendingTransactionDeletes.map((id) => id.toString()).toList(),
    );
    await _prefs?.setStringList(
      _userKeyFor(_budgetDeletesKey),
      _pendingBudgetDeletes.map((id) => id.toString()).toList(),
    );
  }

  Future<void> _syncPendingChanges() async {
    final hadPendingDeletes =
        _pendingTransactionDeletes.isNotEmpty ||
        _pendingBudgetDeletes.isNotEmpty;
    for (final id in _pendingTransactionDeletes.toList()) {
      await api.deleteTransaction(id, user!.id);
      _pendingTransactionDeletes.remove(id);
    }
    for (final id in _pendingBudgetDeletes.toList()) {
      await api.deleteBudget(id, user!.id);
      _pendingBudgetDeletes.remove(id);
    }
    final pendingTransactions = transactions
        .where((item) => item.pendingSync)
        .toList();
    for (final item in pendingTransactions) {
      final saved = await api.saveTransaction(
        item.copyWith(id: item.id < 0 ? 0 : item.id),
      );
      final index = transactions.indexWhere(
        (candidate) => candidate.id == item.id,
      );
      if (index >= 0) transactions[index] = saved.copyWith(pendingSync: false);
    }
    final pendingBudgets = budgets.where((item) => item.pendingSync).toList();
    for (final item in pendingBudgets) {
      final saved = await api.saveBudget(
        item.copyWith(id: item.id < 0 ? 0 : item.id),
      );
      final index = budgets.indexWhere((candidate) => candidate.id == item.id);
      if (index >= 0) budgets[index] = saved.copyWith(pendingSync: false);
    }
    if (hadPendingDeletes ||
        pendingTransactions.isNotEmpty ||
        pendingBudgets.isNotEmpty) {
      await _saveLocalData();
    }
  }

  String _userKeyFor(String key) => '${key}_${user?.id ?? 0}';

  Future<void> _runBusy(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      errorMessage = _messageOf(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  String _messageOf(Object error) =>
      error is ApiException ? error.message : 'Beklenmeyen bir hata oluştu.';

  List<WalletTransaction> _demoTransactions() {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    return [
      WalletTransaction(
        id: -1,
        userId: 1,
        amount: 48500,
        type: TransactionType.income,
        category: 'Maaş',
        description: 'Aylık maaş',
        date: month.add(const Duration(days: 1)),
      ),
      WalletTransaction(
        id: -2,
        userId: 1,
        amount: 6900,
        type: TransactionType.expense,
        category: 'Ev',
        description: 'Kira ve aidat',
        date: month.add(const Duration(days: 2)),
      ),
      WalletTransaction(
        id: -3,
        userId: 1,
        amount: 1380,
        type: TransactionType.expense,
        category: 'Market',
        description: 'Haftalık alışveriş',
        date: month.add(const Duration(days: 5)),
      ),
      WalletTransaction(
        id: -4,
        userId: 1,
        amount: 750,
        type: TransactionType.expense,
        category: 'Ulaşım',
        description: 'Ulaşım kartı',
        date: month.add(const Duration(days: 7)),
      ),
      WalletTransaction(
        id: -5,
        userId: 1,
        amount: 2400,
        type: TransactionType.income,
        category: 'Ek gelir',
        description: 'Freelance çalışma',
        date: month.add(const Duration(days: 10)),
      ),
      WalletTransaction(
        id: -6,
        userId: 1,
        amount: 920,
        type: TransactionType.expense,
        category: 'Faturalar',
        description: 'Elektrik ve internet',
        date: month.add(const Duration(days: 12)),
      ),
      WalletTransaction(
        id: -7,
        userId: 1,
        amount: 560,
        type: TransactionType.expense,
        category: 'Sosyal',
        description: 'Arkadaşlarla yemek',
        date: month.add(const Duration(days: 14)),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Budget> _demoBudgets() {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    return [
      Budget(
        id: -101,
        userId: 1,
        category: 'Market',
        amount: 4500,
        month: month,
      ),
      Budget(
        id: -102,
        userId: 1,
        category: 'Ulaşım',
        amount: 1800,
        month: month,
      ),
      Budget(
        id: -103,
        userId: 1,
        category: 'Sosyal',
        amount: 2500,
        month: month,
      ),
    ];
  }
}
