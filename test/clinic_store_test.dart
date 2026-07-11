import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appointment_booking/models/patient.dart';
import 'package:appointment_booking/models/queue_item.dart';
import 'package:appointment_booking/models/medical_record.dart';
import 'package:appointment_booking/models/appointment.dart';
import 'package:appointment_booking/services/clinic_store.dart';

void main() {
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
      expect(store.appointments.isEmpty, true);
    });

    test('Register and query patient details & family members', () async {
      final store = ClinicStore();
      await store.init();

      final p1 = Patient(
        id: '9999999999_John_Doe',
        mobileNumber: '9999999999',
        name: 'John Doe',
        age: 30,
        address: '123 Test Street',
        dateOfBirth: DateTime(1996, 1, 1),
        gender: 'Male',
        emergencyContact: '8888888888',
        registeredAt: DateTime.now(),
      );

      final p2 = Patient(
        id: '9999999999_Jane_Doe',
        mobileNumber: '9999999999',
        name: 'Jane Doe',
        age: 28,
        address: '123 Test Street',
        dateOfBirth: DateTime(1998, 5, 5),
        gender: 'Female',
        emergencyContact: '8888888888',
        registeredAt: DateTime.now(),
      );

      await store.registerPatient(p1);
      await store.registerPatient(p2);

      expect(store.patients.length, 2);
      
      final queryResult = store.getPatientById('9999999999_John_Doe');
      expect(queryResult, isNotNull);
      expect(queryResult!.name, 'John Doe');

      final familyProfiles = store.getPatientsByMobile('9999999999');
      expect(familyProfiles.length, 2);
      expect(familyProfiles.any((p) => p.name == 'Jane Doe'), true);
    });

    test('Queue check-in constraints by patientId', () async {
      final store = ClinicStore();
      await store.init();

      final patient = Patient(
        id: '9999999999_John_Doe',
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

      // Unregistered ID should fail
      final qUnreg = await store.addToQueue('0000000000_Nobody');
      expect(qUnreg, false);

      // Registered ID should succeed
      final qReg = await store.addToQueue('9999999999_John_Doe');
      expect(qReg, true);
      expect(store.getActiveQueue().length, 1);

      // Double check-in should fail
      final qDouble = await store.addToQueue('9999999999_John_Doe');
      expect(qDouble, false);
    });

    test('Queue position and reordering updates', () async {
      final store = ClinicStore();
      await store.init();

      final p1 = Patient(
        id: '1111111111_P1',
        mobileNumber: '1111111111',
        name: 'P1',
        age: 20,
        address: 'Addr',
        dateOfBirth: DateTime(2006, 1, 1),
        gender: 'Female',
        emergencyContact: '999',
        registeredAt: DateTime.now(),
      );
      final p2 = p1.copyWith(id: '2222222222_P2', mobileNumber: '2222222222', name: 'P2');
      final p3 = p1.copyWith(id: '3333333333_P3', mobileNumber: '3333333333', name: 'P3');

      await store.registerPatient(p1);
      await store.registerPatient(p2);
      await store.registerPatient(p3);

      await store.addToQueue('1111111111_P1');
      await store.addToQueue('2222222222_P2');
      await store.addToQueue('3333333333_P3');

      expect(store.getActiveQueue().length, 3);

      // Verify patients ahead count
      final infoP3 = store.getPatientQueueInfo('3333333333_P3');
      expect(infoP3['patientsAhead'], 2);

      // Reorder queue (move P3 to index 0)
      await store.reorderQueue(2, 0);

      // Verify P3 is now at position 1 in active queue
      final newActive = store.getActiveQueue();
      expect(newActive.first.patientId, '3333333333_P3');
      expect(store.getPatientQueueInfo('3333333333_P3')['patientsAhead'], 0);
      expect(store.getPatientQueueInfo('1111111111_P1')['patientsAhead'], 1);
    });

    test('Add Medical Record completes consultation', () async {
      final store = ClinicStore();
      await store.init();

      final patient = Patient(
        id: '9999999999_John_Doe',
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
      await store.addToQueue('9999999999_John_Doe');

      final queueItem = store.getActiveQueue().first;
      await store.startConsultation(queueItem.id);

      final record = MedicalRecord(
        id: 'rec_test',
        patientId: '9999999999_John_Doe',
        date: DateTime.now(),
        diagnosis: 'Flu',
        notes: 'Take rest',
        medicines: [
          MedicineItem(name: 'Med A', dosage: '1-0-1', duration: '3 days', instructions: 'After food')
        ],
        tests: ['CBC'],
      );

      await store.addMedicalRecord(record);

      // Queue item status should transition to done
      expect(store.getActiveQueue().isEmpty, true);
      expect(store.getHistoricalQueue().length, 1);
      expect(store.getHistoricalQueue().first.status, QueueStatus.done);

      // Verify prescription retrieval
      final pRecords = store.getPatientRecords('9999999999_John_Doe');
      expect(pRecords.length, 1);
      expect(pRecords.first.diagnosis, 'Flu');
      expect(pRecords.first.tests.first, 'CBC');
    });

    test('Appointments and scheduling workflow', () async {
      final store = ClinicStore();
      await store.init();

      final appointment = Appointment(
        id: 'appt_1',
        patientMobile: '9999999999',
        patientName: 'John Doe',
        doctorName: 'Dr. Amit',
        dateTime: DateTime.now(),
        time: '10:00 AM',
        status: AppointmentStatus.pending,
      );

      await store.bookAppointment(appointment);
      
      expect(store.appointments.length, 1);
      expect(store.getTodayAppointments().length, 1);
      
      await store.updateAppointmentStatus('appt_1', AppointmentStatus.approved);
      expect(store.appointments.first.status, AppointmentStatus.approved);
    });
  });
}
