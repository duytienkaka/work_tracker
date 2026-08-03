import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:work_tracker/core/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test(
    'opening the database concurrently should not throw duplicate table errors',
    () async {
      final dbPath = join(await getDatabasesPath(), 'work_tracker.db');
      await deleteDatabase(dbPath);

      final futures = List.generate(5, (_) => AppDatabase.database());
      final results = await Future.wait(futures);

      expect(results, hasLength(5));
      for (final database in results) {
        expect(database.isOpen, isTrue);
      }
    },
  );
}
