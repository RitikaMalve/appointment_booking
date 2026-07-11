import '../models/patient.dart';
import '../models/queue_item.dart';
import '../models/medical_record.dart';
import '../services/clinic_store.dart';

class MockGenerator {
  static Future<void> seedData(ClinicStore store) async {
    final now = DateTime.now();

    // 1. Create Mock Patients
    final patients = [
      Patient(
        mobileNumber: '9876543210',
        name: 'Rohan Sharma',
        age: 28,
        address: '102, Green Park, New Delhi',
        dateOfBirth: DateTime(1998, 4, 15),
        gender: 'Male',
        emergencyContact: '9876543211',
        registeredAt: now.subtract(const Duration(days: 30)),
      ),
      Patient(
        mobileNumber: '9988776655',
        name: 'Priya Patel',
        age: 34,
        address: 'B-405, Shanti Nagar, Mumbai',
        dateOfBirth: DateTime(1992, 11, 23),
        gender: 'Female',
        emergencyContact: '9988776650',
        registeredAt: now.subtract(const Duration(days: 15)),
      ),
      Patient(
        mobileNumber: '9123456789',
        name: 'Amit Verma',
        age: 45,
        address: '56-C, Salt Lake, Kolkata',
        dateOfBirth: DateTime(1981, 7, 9),
        gender: 'Male',
        emergencyContact: '9123456780',
        registeredAt: now.subtract(const Duration(days: 45)),
      ),
      Patient(
        mobileNumber: '9345678901',
        name: 'Ananya Iyer',
        age: 22,
        address: '12, Indiranagar, Bengaluru',
        dateOfBirth: DateTime(2004, 1, 30),
        gender: 'Female',
        emergencyContact: '9345678900',
        registeredAt: now.subtract(const Duration(days: 5)),
      ),
      Patient(
        mobileNumber: '9567890123',
        name: 'Sanjeev Kumar',
        age: 60,
        address: 'Flat 9, Sector 15, Noida',
        dateOfBirth: DateTime(1966, 9, 12),
        gender: 'Male',
        emergencyContact: '9567890120',
        registeredAt: now.subtract(const Duration(days: 60)),
      ),
    ];

    // 2. Create Historical Medical Records (Prescriptions)
    final records = [
      MedicalRecord(
        id: 'rec_1',
        patientMobile: '9876543210',
        date: now.subtract(const Duration(days: 10)),
        diagnosis: 'Seasonal Allergy',
        notes: 'Avoid cold drinks and dust. Take medications after meals.',
        medicines: [
          MedicineItem(
            name: 'Cetirizine 10mg',
            dosage: '0-0-1',
            duration: '5 days',
            instructions: 'Before sleeping',
          ),
          MedicineItem(
            name: 'Montelukast 10mg',
            dosage: '1-0-0',
            duration: '10 days',
            instructions: 'Empty stomach',
          ),
        ],
      ),
      MedicalRecord(
        id: 'rec_2',
        patientMobile: '9123456789',
        date: now.subtract(const Duration(days: 20)),
        diagnosis: 'Hypertension Management',
        notes: 'Monitor BP twice daily. Reduce salt intake. Walk 30 mins.',
        medicines: [
          MedicineItem(
            name: 'Amlodipine 5mg',
            dosage: '1-0-0',
            duration: '30 days',
            instructions: 'Morning after food',
          ),
        ],
      ),
      MedicalRecord(
        id: 'rec_3',
        patientMobile: '9988776655',
        date: now.subtract(const Duration(days: 2)),
        diagnosis: 'Acute Gastritis',
        notes: 'Eat light, bland diet. No spicy foods.',
        medicines: [
          MedicineItem(
            name: 'Pantoprazole 40mg',
            dosage: '1-0-0',
            duration: '7 days',
            instructions: '30 mins before breakfast',
          ),
          MedicineItem(
            name: 'Syrup Sucralfate',
            dosage: '1-1-1',
            duration: '5 days',
            instructions: '2 teaspoons before food',
          ),
        ],
      ),
    ];

    // 3. Create Queue Items
    final queue = [
      // Completed yesterday/today
      QueueItem(
        id: 'q_old_1',
        patientMobile: '9876543210',
        queueNumber: 101,
        entryTime: now.subtract(const Duration(hours: 4)),
        status: QueueStatus.done,
        isFeesPaid: true,
      ),
      QueueItem(
        id: 'q_old_2',
        patientMobile: '9123456789',
        queueNumber: 102,
        entryTime: now.subtract(const Duration(hours: 3)),
        status: QueueStatus.done,
        isFeesPaid: true,
      ),
      
      // Active queue today
      QueueItem(
        id: 'q_act_1',
        patientMobile: '9988776655', // Priya Patel
        queueNumber: 103,
        entryTime: now.subtract(const Duration(minutes: 40)),
        status: QueueStatus.serving, // Under consultation
        isFeesPaid: true,
      ),
      QueueItem(
        id: 'q_act_2',
        patientMobile: '9345678901', // Ananya Iyer
        queueNumber: 104,
        entryTime: now.subtract(const Duration(minutes: 20)),
        status: QueueStatus.waiting, // Next in queue
        isFeesPaid: false,
      ),
      QueueItem(
        id: 'q_act_3',
        patientMobile: '9567890123', // Sanjeev Kumar
        queueNumber: 105,
        entryTime: now.subtract(const Duration(minutes: 5)),
        status: QueueStatus.waiting, // Third
        isFeesPaid: true,
      ),
    ];

    await store.setAllData(
      newPatients: patients,
      newQueue: queue,
      newRecords: records,
    );
  }
}
