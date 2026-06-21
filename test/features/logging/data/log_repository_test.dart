import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carbon_aware/features/logging/data/log_repository.dart';
import 'package:carbon_aware/features/logging/domain/daily_log.dart';
import 'package:carbon_aware/core/utils/co2_calculator.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockQueryDocumentSnapshot extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockUsersCol;
  late MockDocumentReference mockUserDoc;
  late MockCollectionReference mockLogsCol;
  late MockDocumentReference mockLogDoc;
  late LogRepository logRepository;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsersCol = MockCollectionReference();
    mockUserDoc = MockDocumentReference();
    mockLogsCol = MockCollectionReference();
    mockLogDoc = MockDocumentReference();
    logRepository = LogRepository(firestore: mockFirestore);

    // Setup base collection/document paths
    when(() => mockFirestore.collection('users')).thenReturn(mockUsersCol);
    when(() => mockUsersCol.doc(any())).thenReturn(mockUserDoc);
    when(() => mockUserDoc.collection('daily_logs')).thenReturn(mockLogsCol);
    when(() => mockLogsCol.doc(any())).thenReturn(mockLogDoc);
  });

  group('LogRepository Tests', () {
    final testLog = DailyLog(
      date: '2026-06-22',
      transportDistance: 10.0,
      isKm: false,
      vehicleType: VehicleType.car,
      dietType: DietType.average,
      electricityKwh: 5.0,
      totalCO2Kg: 8.0,
      timestamp: DateTime(2026, 6, 22),
    );

    test('saveDailyLog writes document to Firestore', () async {
      when(() => mockLogDoc.set(any())).thenAnswer((_) => Future.value());

      await logRepository.saveDailyLog('test_uid', testLog);

      verify(() => mockFirestore.collection('users')).called(1);
      verify(() => mockUsersCol.doc('test_uid')).called(1);
      verify(() => mockUserDoc.collection('daily_logs')).called(1);
      verify(() => mockLogsCol.doc('2026-06-22')).called(1);
      verify(() => mockLogDoc.set(any())).called(1);
    });

    test('getDailyLog returns DailyLog when doc exists', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockLogDoc.get()).thenAnswer((_) => Future.value(mockSnapshot));
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.id).thenReturn('2026-06-22');
      when(() => mockSnapshot.data()).thenReturn({
        'date': '2026-06-22',
        'transportDistance': 10.0,
        'isKm': false,
        'vehicleType': 'car',
        'dietType': 'average',
        'electricityKwh': 5.0,
        'totalCO2Kg': 8.0,
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 22)),
      });

      final result = await logRepository.getDailyLog('test_uid', '2026-06-22');

      expect(result, isNotNull);
      expect(result!.date, '2026-06-22');
      expect(result.totalCO2Kg, 8.0);
      verify(() => mockLogDoc.get()).called(1);
    });

    test('getDailyLog returns null when doc does not exist', () async {
      final mockSnapshot = MockDocumentSnapshot();
      when(() => mockLogDoc.get()).thenAnswer((_) => Future.value(mockSnapshot));
      when(() => mockSnapshot.exists).thenReturn(false);

      final result = await logRepository.getDailyLog('test_uid', '2026-06-22');

      expect(result, isNull);
    });

    test('deleteDailyLog deletes doc in Firestore', () async {
      when(() => mockLogDoc.delete()).thenAnswer((_) => Future.value());

      await logRepository.deleteDailyLog('test_uid', '2026-06-22');

      verify(() => mockLogDoc.delete()).called(1);
    });

    test('getRecentLogsStream streams and maps document queries', () async {
      final mockQueryOrderBy = MockQuery();
      final mockQueryLimit = MockQuery();
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockQueryDocumentSnapshot();

      when(() => mockLogsCol.orderBy('timestamp', descending: true)).thenReturn(mockQueryOrderBy);
      when(() => mockQueryOrderBy.limit(any())).thenReturn(mockQueryLimit);
      when(() => mockQueryLimit.snapshots()).thenAnswer((_) => Stream.value(mockQuerySnapshot));
      when(() => mockQuerySnapshot.docs).thenReturn([mockDocSnapshot]);

      when(() => mockDocSnapshot.id).thenReturn('2026-06-22');
      when(() => mockDocSnapshot.data()).thenReturn({
        'date': '2026-06-22',
        'transportDistance': 15.0,
        'isKm': false,
        'vehicleType': 'bus',
        'dietType': 'vegan',
        'electricityKwh': 3.0,
        'totalCO2Kg': 4.5,
        'timestamp': Timestamp.fromDate(DateTime(2026, 6, 22)),
      });

      final logsStream = logRepository.getRecentLogsStream('test_uid', days: 7);
      final logsList = await logsStream.first;

      expect(logsList.length, 1);
      expect(logsList.first.date, '2026-06-22');
      expect(logsList.first.vehicleType, VehicleType.bus);
      expect(logsList.first.dietType, DietType.vegan);
    });
  });
}
