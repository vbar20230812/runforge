import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progress_snapshot.dart';
import '../../data/models/personal_record.dart';
import '../../data/services/progress_service.dart';
import '../../data/services/record_service.dart';
import 'auth_provider.dart';

final progressServiceProvider = Provider<ProgressService>((ref) => ProgressService());
final recordServiceProvider = Provider<RecordService>((ref) => RecordService());

final progressSnapshotsProvider = StreamProvider<List<ProgressSnapshot>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(progressServiceProvider).streamSnapshots(userId);
});

final personalRecordsProvider = StreamProvider<List<PersonalRecord>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return Stream.value([]);
  return ref.watch(recordServiceProvider).allRecordsStream(userId);
});
