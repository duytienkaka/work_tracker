class FamilyModel {
  final String id;
  final String name;
  final DateTime createdAt;

  const FamilyModel({required this.id, required this.name, required this.createdAt});

  factory FamilyModel.fromJson(Map<String, dynamic> json) => FamilyModel(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class SharedExpenseModel {
  final String id, title, category, visibility;
  final double amount;
  final DateTime expenseDate;
  final String? note;
  const SharedExpenseModel({required this.id, required this.title, required this.category, required this.amount, required this.expenseDate, this.note, required this.visibility});
  factory SharedExpenseModel.fromJson(Map<String, dynamic> json) => SharedExpenseModel(id: json['id'], title: json['title'], category: json['category'], amount: (json['amount'] as num).toDouble(), expenseDate: DateTime.parse(json['expenseDate'].toString()), note: json['note'], visibility: json['visibility']);
}

class FamilyMemberModel {
  final String id, email, displayName, role;
  const FamilyMemberModel({required this.id, required this.email, required this.displayName, required this.role});
  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) => FamilyMemberModel(id: json['id'], email: json['email'], displayName: json['displayName'], role: json['role']);
}

class FamilyDashboardModel {
  final double totalExpense;
  final int transactionCount;
  final List<Map<String, dynamic>> byCategory;
  const FamilyDashboardModel({required this.totalExpense, required this.transactionCount, required this.byCategory});
  factory FamilyDashboardModel.fromJson(Map<String, dynamic> json) => FamilyDashboardModel(totalExpense: (json['totalExpense'] as num).toDouble(), transactionCount: json['transactionCount'] as int, byCategory: (json['byCategory'] as List).cast<Map<String, dynamic>>());
}
class SharedIncomeModel { final String id, title; final double amount; final DateTime incomeDate; final String? note; const SharedIncomeModel({required this.id, required this.title, required this.amount, required this.incomeDate, this.note}); factory SharedIncomeModel.fromJson(Map<String,dynamic> j)=>SharedIncomeModel(id:j['id'],title:j['title'],amount:(j['amount'] as num).toDouble(),incomeDate:DateTime.parse(j['incomeDate'].toString()),note:j['note']); }
class BudgetModel { final String id, category; final int year, month; final double amount; const BudgetModel({required this.id,required this.category,required this.year,required this.month,required this.amount}); factory BudgetModel.fromJson(Map<String,dynamic> j)=>BudgetModel(id:j['id'],category:j['category'],year:j['year'],month:j['month'],amount:(j['amount'] as num).toDouble()); }
class ExpenseCategoryModel { final String id, name; const ExpenseCategoryModel({required this.id,required this.name}); factory ExpenseCategoryModel.fromJson(Map<String,dynamic> j)=>ExpenseCategoryModel(id:j['id'],name:j['name']); }
class FamilyWorkSnapshotModel { final String sourceWorkId, workName, workType, salaryDescription; const FamilyWorkSnapshotModel({required this.sourceWorkId,required this.workName,required this.workType,required this.salaryDescription}); factory FamilyWorkSnapshotModel.fromJson(Map<String,dynamic> j)=>FamilyWorkSnapshotModel(sourceWorkId:j['sourceWorkId'],workName:j['workName'],workType:j['workType'],salaryDescription:j['salaryDescription']); }
