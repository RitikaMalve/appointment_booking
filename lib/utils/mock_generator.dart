import '../models/patient.dart';
import '../models/queue_item.dart';
import '../models/medical_record.dart';
import '../models/appointment.dart';
import '../services/clinic_store.dart';
import 'medicine_presets.dart';

class MockGenerator {
  static Future<void> seedData(ClinicStore store) async {
    final now = DateTime.now();

    // 1. Create Mock Patients (including family profiles sharing mobile numbers)
    final patients = [
      Patient(
        id: '9876543210_Rohan_Sharma',
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
        id: '9876543210_Kavita_Sharma',
        mobileNumber: '9876543210',
        name: 'Kavita Sharma',
        age: 26,
        address: '102, Green Park, New Delhi',
        dateOfBirth: DateTime(2000, 8, 20),
        gender: 'Female',
        emergencyContact: '9876543211',
        registeredAt: now.subtract(const Duration(days: 20)),
      ),
      Patient(
        id: '9988776655_Priya_Patel',
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
        id: '9988776655_Aarav_Patel',
        mobileNumber: '9988776655',
        name: 'Aarav Patel',
        age: 8,
        address: 'B-405, Shanti Nagar, Mumbai',
        dateOfBirth: DateTime(2018, 5, 12),
        gender: 'Male',
        emergencyContact: '9988776650',
        registeredAt: now.subtract(const Duration(days: 14)),
      ),
      Patient(
        id: '9123456789_Amit_Verma',
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
        id: '9345678901_Ananya_Iyer',
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
        id: '9567890123_Sanjeev_Kumar',
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

    // 2. Create Historical Medical Records (Prescriptions & Test histories)
    final records = [
      MedicalRecord(
        id: 'rec_1',
        patientId: '9876543210_Rohan_Sharma',
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
        tests: ['CBC Blood Test', 'Allergy Skin Test'],
      ),
      MedicalRecord(
        id: 'rec_2',
        patientId: '9123456789_Amit_Verma',
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
        tests: ['Blood Pressure', 'ECG Monitoring'],
      ),
      MedicalRecord(
        id: 'rec_3',
        patientId: '9988776655_Priya_Patel',
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
        tests: ['Blood Sugar', 'Abdominal Ultrasound'],
      ),
    ];

    // 3. Create Live Queue Items linked to individual patient IDs
    final queue = [
      // Completed earlier today
      QueueItem(
        id: 'q_old_1',
        patientId: '9876543210_Rohan_Sharma',
        queueNumber: 101,
        entryTime: now.subtract(const Duration(hours: 4)),
        status: QueueStatus.done,
        isFeesPaid: true,
      ),
      QueueItem(
        id: 'q_old_2',
        patientId: '9123456789_Amit_Verma',
        queueNumber: 102,
        entryTime: now.subtract(const Duration(hours: 3)),
        status: QueueStatus.done,
        isFeesPaid: true,
      ),
      
      // Active queue today
      QueueItem(
        id: 'q_act_1',
        patientId: '9988776655_Priya_Patel', // Priya Patel
        queueNumber: 103,
        entryTime: now.subtract(const Duration(minutes: 40)),
        status: QueueStatus.serving,
        isFeesPaid: true,
      ),
      QueueItem(
        id: 'q_act_2',
        patientId: '9345678901_Ananya_Iyer', // Ananya Iyer
        queueNumber: 104,
        entryTime: now.subtract(const Duration(minutes: 20)),
        status: QueueStatus.waiting,
        isFeesPaid: false,
      ),
      QueueItem(
        id: 'q_act_3',
        patientId: '9567890123_Sanjeev_Kumar', // Sanjeev Kumar
        queueNumber: 105,
        entryTime: now.subtract(const Duration(minutes: 5)),
        status: QueueStatus.waiting,
        isFeesPaid: true,
      ),
    ];

    // 4. Create Mock Appointments with statuses
    final appointments = [
      Appointment(
        id: 'app_1',
        patientMobile: '9876543210',
        patientName: 'Rohan Sharma',
        doctorName: 'Dr. Amit Verma',
        dateTime: now,
        time: '10:00 AM',
        status: AppointmentStatus.approved,
      ),
      Appointment(
        id: 'app_2',
        patientMobile: '9876543210',
        patientName: 'Kavita Sharma',
        doctorName: 'Dr. Amit Verma',
        dateTime: now,
        time: '11:30 AM',
        status: AppointmentStatus.pending,
      ),
      Appointment(
        id: 'app_3',
        patientMobile: '9988776655',
        patientName: 'Priya Patel',
        doctorName: 'Dr. Amit Verma',
        dateTime: now,
        time: '02:00 PM',
        status: AppointmentStatus.approved,
      ),
      Appointment(
        id: 'app_4',
        patientMobile: '9988776655',
        patientName: 'Aarav Patel',
        doctorName: 'Dr. Amit Verma',
        dateTime: now.add(const Duration(days: 1)),
        time: '04:15 PM',
        status: AppointmentStatus.pending,
      ),
      Appointment(
        id: 'app_5',
        patientMobile: '9345678901',
        patientName: 'Ananya Iyer',
        doctorName: 'Dr. Amit Verma',
        dateTime: now.subtract(const Duration(days: 2)),
        time: '09:30 AM',
        status: AppointmentStatus.rejected,
      ),
    ];

    // Initialize medicines master list with the defaults
    final medicinesList = List<MedicinePreset>.from(medicinePresets);

    await store.setAllData(
      newPatients: patients,
      newQueue: queue,
      newRecords: records,
      newAppointments: appointments,
      newMedicinesMaster: medicinesList,
    );
  }
}
