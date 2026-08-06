import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/family_model.dart';

class FamilyApiClient {
  final String baseUrl;
  final http.Client client;
  String? token;

  FamilyApiClient({this.baseUrl = 'http://workfinance.somee.com', http.Client? client}) : client = client ?? http.Client();

  Future<AuthSession> register({required String email, required String password, required String displayName}) async {
    final response = await client.post(Uri.parse('$baseUrl/api/auth/register'), headers: _jsonHeaders(), body: jsonEncode({'email': email, 'password': password, 'displayName': displayName}));
    return _session(response);
  }

  Future<AuthSession> login({required String email, required String password}) async {
    final response = await client.post(Uri.parse('$baseUrl/api/auth/login'), headers: _jsonHeaders(), body: jsonEncode({'email': email, 'password': password}));
    return _session(response);
  }

  Future<List<FamilyModel>> getFamilies() async {
    final response = await client.get(Uri.parse('$baseUrl/api/families'), headers: _headers());
    _check(response);
    return (jsonDecode(response.body) as List).map((item) => FamilyModel.fromJson(item)).toList();
  }

  Future<FamilyModel> createFamily(String name) async {
    final response = await client.post(Uri.parse('$baseUrl/api/families'), headers: _headers(), body: jsonEncode({'name': name}));
    _check(response);
    return FamilyModel.fromJson(jsonDecode(response.body));
  }

  Future<void> addMember(String familyId, String email) async {
    final response = await client.post(Uri.parse('$baseUrl/api/families/$familyId/members'), headers: _headers(), body: jsonEncode({'email': email}));
    _check(response);
  }

  Future<List<FamilyMemberModel>> getMembers(String familyId) async {
    final response = await client.get(Uri.parse('$baseUrl/api/families/$familyId/members'), headers: _headers());
    _check(response);
    return (jsonDecode(response.body) as List).map((item) => FamilyMemberModel.fromJson(item)).toList();
  }

  Future<void> removeMember(String familyId, String memberId) async {
    final response = await client.delete(Uri.parse('$baseUrl/api/families/$familyId/members/$memberId'), headers: _headers());
    _check(response);
  }

  Future<void> updateMemberRole(String familyId, String memberId, String role) async { final r=await client.patch(Uri.parse('$baseUrl/api/families/$familyId/members/$memberId/role'),headers:_headers(),body:jsonEncode({'role':role})); _check(r); }

  Future<List<SharedExpenseModel>> getExpenses(String familyId) async {
    final response = await client.get(Uri.parse('$baseUrl/api/families/$familyId/expenses'), headers: _headers());
    _check(response);
    return (jsonDecode(response.body) as List).map((item) => SharedExpenseModel.fromJson(item)).toList();
  }

  Future<SharedExpenseModel> createExpense(String familyId, {required String title, required String category, required double amount, required DateTime date, String? note}) async {
    final response = await client.post(Uri.parse('$baseUrl/api/families/$familyId/expenses'), headers: _headers(), body: jsonEncode({'title': title, 'category': category, 'amount': amount, 'expenseDate': date.toIso8601String().split('T').first, 'note': note, 'visibility': 'Family'}));
    _check(response);
    return SharedExpenseModel.fromJson(jsonDecode(response.body));
  }

  Future<FamilyDashboardModel> getDashboard(String familyId, {DateTime? from, DateTime? to}) async {
    final start = from ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final end = to ?? DateTime(start.year, start.month + 1, 0);
    final uri = Uri.parse('$baseUrl/api/families/$familyId/dashboard?from=${start.toIso8601String().split('T').first}&to=${end.toIso8601String().split('T').first}');
    final response = await client.get(uri, headers: _headers()); _check(response);
    return FamilyDashboardModel.fromJson(jsonDecode(response.body));
  }

  Future<void> updateExpense(String familyId, String expenseId, {required String title, required String category, required double amount, required DateTime date, String? note}) async {
    final response = await client.put(Uri.parse('$baseUrl/api/families/$familyId/expenses/$expenseId'), headers: _headers(), body: jsonEncode({'title': title, 'category': category, 'amount': amount, 'expenseDate': date.toIso8601String().split('T').first, 'note': note})); _check(response);
  }

  Future<void> deleteExpense(String familyId, String expenseId) async {
    final response = await client.delete(Uri.parse('$baseUrl/api/families/$familyId/expenses/$expenseId'), headers: _headers()); _check(response);
  }

  Future<List<SharedIncomeModel>> getIncomes(String familyId) async { final r=await client.get(Uri.parse('$baseUrl/api/families/$familyId/incomes'),headers:_headers()); _check(r); return (jsonDecode(r.body) as List).map((x)=>SharedIncomeModel.fromJson(x)).toList(); }
  Future<SharedIncomeModel> createIncome(String familyId,String title,double amount,DateTime date) async { final r=await client.post(Uri.parse('$baseUrl/api/families/$familyId/incomes'),headers:_headers(),body:jsonEncode({'title':title,'amount':amount,'incomeDate':date.toIso8601String().split('T').first})); _check(r); return SharedIncomeModel.fromJson(jsonDecode(r.body)); }
  Future<List<BudgetModel>> getBudgets(String familyId) async { final r=await client.get(Uri.parse('$baseUrl/api/families/$familyId/budgets'),headers:_headers()); _check(r); return (jsonDecode(r.body) as List).map((x)=>BudgetModel.fromJson(x)).toList(); }
  Future<BudgetModel> saveBudget(String familyId,String category,int year,int month,double amount) async { final r=await client.post(Uri.parse('$baseUrl/api/families/$familyId/budgets'),headers:_headers(),body:jsonEncode({'category':category,'year':year,'month':month,'amount':amount})); _check(r); return BudgetModel.fromJson(jsonDecode(r.body)); }
  Future<List<ExpenseCategoryModel>> getCategories(String familyId) async { final r=await client.get(Uri.parse('$baseUrl/api/families/$familyId/categories'),headers:_headers()); _check(r); return (jsonDecode(r.body) as List).map((x)=>ExpenseCategoryModel.fromJson(x)).toList(); }
  Future<ExpenseCategoryModel> createCategory(String familyId,String name) async { final r=await client.post(Uri.parse('$baseUrl/api/families/$familyId/categories'),headers:_headers(),body:jsonEncode({'name':name})); _check(r); return ExpenseCategoryModel.fromJson(jsonDecode(r.body)); }
  Future<List<FamilyWorkSnapshotModel>> syncWorkSnapshots(String familyId, List<Map<String,String>> works) async { final r=await client.post(Uri.parse('$baseUrl/api/families/$familyId/work-snapshots/sync'),headers:_headers(),body:jsonEncode({'works':works})); _check(r); return (jsonDecode(r.body) as List).map((x)=>FamilyWorkSnapshotModel.fromJson(x)).toList(); }

  Map<String, String> _headers() => {..._jsonHeaders(), if (token != null) 'Authorization': 'Bearer $token'};
  Map<String, String> _jsonHeaders() => {'Content-Type': 'application/json', 'Accept': 'application/json'};

  AuthSession _session(http.Response response) {
    _check(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    token = json['token'] as String;
    return AuthSession(token: token!, userId: json['userId'] as String, email: json['email'] as String, displayName: json['displayName'] as String);
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) throw Exception('Email hoặc mật khẩu không chính xác.');
      if (response.statusCode == 409) throw Exception('Email này đã được đăng ký.');
      String message = 'API request failed (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['message'] is String) message = body['message'] as String;
      } catch (_) {
        // Keep the status message when the server response is not JSON.
      }
      throw Exception(message);
    }
  }
}

class AuthSession {
  final String token;
  final String userId;
  final String email;
  final String displayName;
  const AuthSession({required this.token, required this.userId, required this.email, required this.displayName});
}
