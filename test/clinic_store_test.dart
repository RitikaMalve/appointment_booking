import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appointment_booking/models/patient.dart';
import 'package:appointment_booking/models/queue_item.dart';
import 'package:appointment_booking/models/medical_record.dart';
import 'package:appointment_booking/services/clinic_store.dart';

void main() {
  // Set up mock SharedPreferences for test runs
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClinicStore Tests', () {
    test('Initialize store empty', () async {
      final store = ClinicStore();
      await store.init();

      expect(store.patients.isEmpty, true);
      expect(store.queue.isEmpty, true);
      expect(store.records.isEmpty, true);
    });

    test('Register and query patient details', () async {
      final store = ClinicStore();
      await store.init();

      final patient = Patient(
        mobileNumber: '9999999999',
        name: 'John Doe',
        age: 30,
        address: '123 Test Street',
        dateOfBirth: DateTime(1996, 1, 1),
        gender: 'Male',
        emergencyContact: '8888888888',
        registeredAt: DateTime.now(),
      );

      await store.registerPatient(patient);

      expect(store.patients.length, 1);
      final queryResult = store.getPatientByMobile('9999999999');
      expect(queryResult, isNotNull);
      expect(queryResult!.name, 'John Doe');
      expect(queryResult.age, 30);
    });

    test('Queue check-in constraints', () async {
      final store = ClinicStore();
      await store.init();

      final patient = Patient(
        mobileNumber: '9999999999',
        name: 'John Doe',
        age: 30,
        address: '123 Test Street',
        dateOfBirth: DateTime(1996, 1, 1),
        gender: 'Male',
        emergencyContact: '8888888888',
        registeredAt: DateTime.now(),
      );
      await store.registerPatient(patient);

      // Unregistered phone should fail
      final qUnreg = await store.addToQueue('0000000000');
      expect(qUnreg, false);

      // Registered phone should succeed
      final qReg = await store.addToQueue('9999999999');
      expect(qReg, true);
      expect(store.getActiveQueue().length, 1);

      // Double check-in should fail
      final qDouble = await store.addToQueue('9999999999');
      expect(qDouble, false);
    });

    test('Queue position and proximity updates', () async {
      final store = ClinicStore();
      await store.init();

      // Add three patients
      final p1 = Patient(
        mobileNumber: '1111111111',
        name: 'P1',
        age: 20,
        address: 'Addr',
        dateOfBirth: DateTime(2006, 1, 1),
        gender: 'Female',
        emergencyContact: '999',
        registeredAt: DateTime.now(),
      );
      final p2 = p1.copyWith(mobileNumber: '2222222222', name: 'P2');
      final p3 = p1.copyWith(mobileNumber: '3333333333', name: 'P3');

      await store.registerPatient(p1);
      await store.registerPatient(p2);
      await store.registerPatient(p3);

      await store.addToQueue('1111111111');
      await store.addToQueue('2222222222');
      await store.addToQueue('3333333333');

      // Check stats: 3 waiting
      expect(store.getActiveQueue().length, 3);

      // Info for patient 3: ahead count should be 2
      final infoP3 = store.getPatientQueueInfo('3333333333');
      expect(infoP3['inQueue'], true);
      expect(infoP3['patientsAhead'], 2);
      expect(infoP3['isNear'], true); // 2 patients ahead is near!

      // Info for patient 1: ahead count should be 0
      final infoP1 = store.getPatientQueueInfo('1111111111');
      expect(infoP1['patientsAhead'], 0);
      expect(infoP1['isNear'], true); // 0 ahead is near!

      // Start consultation for P1
      final p1QueueItem = store.getActiveQueue().first;
      await store.startConsultation(p1QueueItem.id);

      final activeServing = store.getActiveServingPatient();
      expect(activeServing, isNotNull);
      expect(activeServing!.patientMobile, '1111111111');
      expect(activeServing.status, QueueStatus.serving);
    });

    test('Add Medical Record completes consultation', () async {
      final store = ClinicStore();
      await store.init();

      final patient = Patient(
        mobileNumber: '9999999999',
        name: 'John Doe',
        age: 30,
        address: '123 Test Street',
        dateOfBirth: DateTime(1996, 1, 1),
        gender: 'Male',
        emergencyContact: '8888888888',
        registeredAt: DateTime.now(),
      );
      await store.registerPatient(patient);
      await store.addToQueue('9999999999');

      final queueItem = store.getActiveQueue().first;
      await store.startConsultation(queueItem.id);

      final record = MedicalRecord(
        id: 'rec_test',
        patientMobile: '9999999999',
        date: DateTime.now(),
        diagnosis: 'Flu',
        notes: 'Take rest',
        medicines: [
          MedicineItem(name: 'Med A', dosage: '1-0-1', duration: '3 days', instructions: 'After food')
        ],
      );

      await store.addMedicalRecord(record);

      // Queue item status should transition to done
      expect(store.getActiveQueue().isEmpty, true);
      expect(store.getHistoricalQueue().length, 1);
      expect(store.getHistoricalQueue().first.status, QueueStatus.done);

      // Verify prescription retrieval
      final pRecords = store.getPatientRecords('9999999999');
      expect(pRecords.length, 1);
      expect(pRecords.first.diagnosis, 'Flu');
      expect(pRecords.first.medicines.first.name, 'Med A');
    });

    test('Toggle fees paid', () async {
      final store = ClinicStore();
      await store.init();

      final patient = Patient(
        mobileNumber: '9999999999',
        name: 'John Doe',
        age: 30,
        address: '123 Test Street',
        dateOfBirth: DateTime(1996, 1, 1),
        gender: 'Male',
        emergencyContact: '8888888888',
        registeredAt: DateTime.now(),
      );
      await store.registerPatient(patient);
      await store.addToQueue('9999999999');

      final item = store.getActiveQueue().first;
      expect(item.isFeesPaid, false);

      await store.toggleFeesPaid(item.id);
      expect(store.getActiveQueue().first.isFeesPaid, true);
    });
  });
}
