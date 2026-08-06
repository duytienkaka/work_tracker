import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/family_api_client.dart';
import '../model/family_model.dart';

class FamilyProvider extends ChangeNotifier {
  final FamilyApiClient api;
  FamilyProvider(this.api);

  AuthSession? session;
  List<FamilyModel> families = [];
  FamilyModel? selectedFamily;
  bool isLoading = false;
  List<SharedExpenseModel> expenses = [];
  List<FamilyMemberModel> members = [];
  FamilyDashboardModel? dashboard;
  DateTime? filterFrom;
  DateTime? filterTo;
  List<SharedIncomeModel> incomes = [];
  List<BudgetModel> budgets = [];
  List<ExpenseCategoryModel> categories = [];
  List<FamilyWorkSnapshotModel> syncedWorks = [];

  bool get isSignedIn => session != null;

  Future<void> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('family_auth_token');
    if (token == null) return;
    api.token = token;
    final userId = preferences.getString('family_user_id');
    final email = preferences.getString('family_user_email');
    final displayName = preferences.getString('family_display_name');
    if (userId != null && email != null && displayName != null) { session = AuthSession(token: token, userId: userId, email: email, displayName: displayName); await loadFamilies(); }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      session = await api.login(email: email, password: password);
      await _persistSession(session!);
      await loadFamilies();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String displayName) async {
    isLoading = true;
    notifyListeners();
    try {
      session = await api.register(email: email, password: password, displayName: displayName);
      await _persistSession(session!);
      await loadFamilies();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    session = null;
    families = [];
    selectedFamily = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('family_auth_token');
    await preferences.remove('family_user_id'); await preferences.remove('family_user_email'); await preferences.remove('family_display_name');
    notifyListeners();
  }

  Future<void> loadFamilies() async {
    families = await api.getFamilies();
    selectedFamily ??= families.isEmpty ? null : families.first;
    if (selectedFamily != null) expenses = await api.getExpenses(selectedFamily!.id);
    if (selectedFamily != null) members = await api.getMembers(selectedFamily!.id);
    if (selectedFamily != null) dashboard = await api.getDashboard(selectedFamily!.id);
    if (selectedFamily != null) { incomes = await api.getIncomes(selectedFamily!.id); budgets = await api.getBudgets(selectedFamily!.id); categories = await api.getCategories(selectedFamily!.id); }
    notifyListeners();
  }

  Future<void> selectFamily(FamilyModel family) async { selectedFamily = family; await loadFamilies(); }

  Future<void> createFamily(String name) async {
    final family = await api.createFamily(name);
    families = [...families, family];
    selectedFamily = family;
    expenses = [];
    members = await api.getMembers(family.id);
    notifyListeners();
  }

  Future<void> loadExpenses() async {
    if (selectedFamily == null) return;
    expenses = await api.getExpenses(selectedFamily!.id);
    dashboard = await api.getDashboard(selectedFamily!.id, from: filterFrom, to: filterTo);
    notifyListeners();
  }

  Future<void> setDateFilter(DateTime from, DateTime to) async {
    filterFrom = DateTime(from.year, from.month, from.day);
    filterTo = DateTime(to.year, to.month, to.day);
    if (selectedFamily != null) dashboard = await api.getDashboard(selectedFamily!.id, from: filterFrom, to: filterTo);
    notifyListeners();
  }

  Future<void> clearDateFilter() async {
    filterFrom = null; filterTo = null;
    if (selectedFamily != null) dashboard = await api.getDashboard(selectedFamily!.id);
    notifyListeners();
  }

  Future<void> addMember(String email) async {
    if (selectedFamily == null) return;
    await api.addMember(selectedFamily!.id, email);
    members = await api.getMembers(selectedFamily!.id);
    notifyListeners();
  }

  Future<void> removeMember(String memberId) async {
    if (selectedFamily == null) return;
    await api.removeMember(selectedFamily!.id, memberId);
    members = members.where((member) => member.id != memberId).toList();
    notifyListeners();
  }

  Future<void> updateMemberRole(String memberId, String role) async { if(selectedFamily==null)return; await api.updateMemberRole(selectedFamily!.id,memberId,role); members=await api.getMembers(selectedFamily!.id); notifyListeners(); }

  Future<void> createExpense({required String title, required String category, required double amount, required DateTime date, String? note}) async {
    if (selectedFamily == null) return;
    final expense = await api.createExpense(selectedFamily!.id, title: title, category: category, amount: amount, date: date, note: note);
    expenses = [expense, ...expenses];
    dashboard = await api.getDashboard(selectedFamily!.id);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    if (selectedFamily == null) return;
    await api.deleteExpense(selectedFamily!.id, id);
    expenses.removeWhere((item) => item.id == id);
    dashboard = await api.getDashboard(selectedFamily!.id);
    notifyListeners();
  }

  Future<void> updateExpense(String id, {required String title, required double amount, required DateTime date, String category = 'Other'}) async {
    if (selectedFamily == null) return;
    await api.updateExpense(selectedFamily!.id, id, title: title, category: category, amount: amount, date: date);
    await loadFamilies();
  }

  Future<void> createIncome(String title,double amount) async { if(selectedFamily==null)return; final x=await api.createIncome(selectedFamily!.id,title,amount,DateTime.now()); incomes=[x,...incomes]; notifyListeners(); }
  Future<void> saveBudget(String category,double amount) async { if(selectedFamily==null)return; final x=await api.saveBudget(selectedFamily!.id,category,DateTime.now().year,DateTime.now().month,amount); budgets=[...budgets.where((b)=>b.category!=category),x]; notifyListeners(); }
  Future<void> createCategory(String name) async { if(selectedFamily==null)return; final x=await api.createCategory(selectedFamily!.id,name); categories=[...categories,x]; notifyListeners(); }
  Future<void> syncWorks(List<Map<String,String>> works) async { if(selectedFamily==null)return; syncedWorks=await api.syncWorkSnapshots(selectedFamily!.id,works); notifyListeners(); }

  Future<void> _persistSession(AuthSession value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('family_auth_token', value.token);
    await preferences.setString('family_user_id', value.userId); await preferences.setString('family_user_email', value.email); await preferences.setString('family_display_name', value.displayName);
  }
}
