import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/queue_item.dart';
import '../models/medical_record.dart';
import '../models/appointment.dart';
import '../utils/medicine_presets.dart';

class ClinicStore extends ChangeNotifier {
  static const String _keyPatients = 'clinic_patients';
  static const String _keyQueue = 'clinic_queue';
  static const String _keyRecords = 'clinic_records';
  static const String _keyAppointments = 'clinic_appointments';
  static const String _keyMedicinesMaster = 'clinic_medicines_master';

  List<Patient> _patients = [];
  List<QueueItem> _queue = [];
  List<MedicalRecord> _records = [];
  List<Appointment> _appointments = [];
  List<MedicinePreset> _medicinesMaster = [];
  bool _isInitialized = false;

  List<Patient> get patients => _patients;
  List<QueueItem> get queue => _queue;
  List<MedicalRecord> get records => _records;
  List<Appointment> get appointments => _appointments;
  List<MedicinePreset> get medicinesMaster => _medicinesMaster;
  bool get isInitialized => _isInitialized;

  ClinicStore() {
    init();
  }

  // Load data from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final patientsStr = prefs.getString(_keyPatients);
      if (patientsStr != null) {
        final List<dynamic> decoded = json.decode(patientsStr);
        _patients = decoded.map((item) => Patient.fromJson(item)).toList();
      }

      final queueStr = prefs.getString(_keyQueue);
      if (queueStr != null) {
        final List<dynamic> decoded = json.decode(queueStr);
        _queue = decoded.map((item) => QueueItem.fromJson(item)).toList();
      }

      final recordsStr = prefs.getString(_keyRecords);
      if (recordsStr != null) {
        final List<dynamic> decoded = json.decode(recordsStr);
        _records = decoded.map((item) => MedicalRecord.fromJson(item)).toList();
      }

      final appointmentsStr = prefs.getString(_keyAppointments);
      if (appointmentsStr != null) {
        final List<dynamic> decoded = json.decode(appointmentsStr);
        _appointments = decoded.map((item) => Appointment.fromJson(item)).toList();
      }

      final medicinesStr = prefs.getString(_keyMedicinesMaster);
      if (medicinesStr != null) {
        final List<dynamic> decoded = json.decode(medicinesStr);
        _medicinesMaster = decoded.map((item) => MedicinePreset.fromJson(item)).toList();
      } else {
        // Seed initial presets if master is empty
        _medicinesMaster = List.from(medicinePresets);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading data from SharedPreferences: $e");
      }
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Save data to SharedPreferences
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPatients, json.encode(_patients.map((p) => p.toJson()).toList()));
      await prefs.setString(_keyQueue, json.encode(_queue.map((q) => q.toJson()).toList()));
      await prefs.setString(_keyRecords, json.encode(_records.map((r) => r.toJson()).toList()));
      await prefs.setString(_keyAppointments, json.encode(_appointments.map((a) => a.toJson()).toList()));
      await prefs.setString(_keyMedicinesMaster, json.encode(_medicinesMaster.map((m) => m.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) {
        print("Error saving data: $e");
      }
    }
  }

  // Set all data directly (used by mock generator or clear operations)
  Future<void> setAllData({
    required List<Patient> newPatients,
    required List<QueueItem> newQueue,
    required List<MedicalRecord> newRecords,
    required List<Appointment> newAppointments,
    required List<MedicinePreset> newMedicinesMaster,
  }) async {
    _patients = List.from(newPatients);
    _queue = List.from(newQueue);
    _records = List.from(newRecords);
    _appointments = List.from(newAppointments);
    _medicinesMaster = List.from(newMedicinesMaster);
    notifyListeners();
    await _save();
  }

  // Register a patient
  Future<void> registerPatient(Patient patient) async {
    final index = _patients.indexWhere((p) => p.id == patient.id);
    if (index >= 0) {
      _patients[index] = patient; // Update if exists
    } else {
      _patients.add(patient); // Insert new
    }
    notifyListeners();
    await _save();
  }

  // Get patient by phone (returns first found, for backward compatibility)
  Patient? getPatientByMobile(String mobileNumber) {
    if (mobileNumber.trim().isEmpty) return null;
    final cleanNum = mobileNumber.trim();
    final idx = _patients.indexWhere((p) => p.mobileNumber == cleanNum);
    return idx >= 0 ? _patients[idx] : null;
  }

  // Get patient by unique ID
  Patient? getPatientById(String id) {
    if (id.trim().isEmpty) return null;
    final idx = _patients.indexWhere((p) => p.id == id);
    return idx >= 0 ? _patients[idx] : null;
  }

  // Get all patients registered under the same mobile number (family profiles)
  List<Patient> getPatientsByMobile(String mobileNumber) {
    if (mobileNumber.trim().isEmpty) return [];
    final cleanNum = mobileNumber.trim();
    return _patients.where((p) => p.mobileNumber == cleanNum).toList();
  }

  // Auto-suggest matching patients while typing name
  List<Patient> searchPatientsByName(String nameQuery) {
    if (nameQuery.trim().isEmpty) return [];
    final query = nameQuery.toLowerCase().trim();
    return _patients.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  // Get patient queue status & position info
  Map<String, dynamic> getPatientQueueInfo(String patientId) {
    final activeQ = getActiveQueue();
    final idx = activeQ.indexWhere((item) => item.patientId == patientId);

    if (idx < 0) {
      return {
        'inQueue': false,
        'queueNumber': -1,
        'position': -1,
        'patientsAhead': -1,
        'status': 'Not in queue',
        'isNear': false,
      };
    }

    final item = activeQ[idx];
    
    // Count how many patients are "waiting" ahead of this one
    int aheadCount = 0;
    for (int i = 0; i < idx; i++) {
      if (activeQ[i].status == QueueStatus.waiting || activeQ[i].status == QueueStatus.serving) {
        aheadCount++;
      }
    }

    return {
      'inQueue': true,
      'queueNumber': item.queueNumber,
      'position': idx + 1,
      'patientsAhead': aheadCount,
      'status': item.status,
      'isNear': aheadCount <= 2 && item.status == QueueStatus.waiting,
      'isServing': item.status == QueueStatus.serving,
    };
  }

  // Get active queue (waiting and serving)
  List<QueueItem> getActiveQueue() {
    return _queue.where((item) => 
      item.status == QueueStatus.waiting || 
      item.status == QueueStatus.serving
    ).toList();
  }

  // Get historical queue (done and skipped)
  List<QueueItem> getHistoricalQueue() {
    return _queue.where((item) => 
      item.status == QueueStatus.done || 
      item.status == QueueStatus.skipped
    ).toList();
  }

  // Add patient to the queue
  Future<bool> addToQueue(String patientId) async {
    // Check if patient registered
    final patient = getPatientById(patientId);
    if (patient == null) return false;

    // Check if already in active queue
    final isAlreadyInQueue = getActiveQueue().any((item) => item.patientId == patientId);
    if (isAlreadyInQueue) return false;

    // Get today's starting queue number
    int nextQueueNum = 101;
    if (_queue.isNotEmpty) {
      nextQueueNum = _queue.map((q) => q.queueNumber).reduce((a, b) => a > b ? a : b) + 1;
    }
    final newItem = QueueItem(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}_$patientId',
      patientId: patientId,
      queueNumber: nextQueueNum,
      entryTime: DateTime.now(),
      status: QueueStatus.waiting,
      isFeesPaid: false,
    );

    _queue.add(newItem);
    notifyListeners();
    await _save();
    return true;
  }

  // Rearrange patient queue position
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    final active = getActiveQueue();
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = active.removeAt(oldIndex);
    active.insert(newIndex, item);

    // Renumber active tokens sequentially starting from lowest active token number
    int lowestToken = active.isNotEmpty 
        ? active.map((q) => q.queueNumber).reduce((a, b) => a < b ? a : b)
        : 101;

    for (int i = 0; i < active.length; i++) {
      final activeItem = active[i];
      final masterIdx = _queue.indexWhere((q) => q.id == activeItem.id);
      if (masterIdx >= 0) {
        _queue[masterIdx] = _queue[masterIdx].copyWith(queueNumber: lowestToken + i);
      }
    }

    // Keep queue sorted: Serving first, then Waiting sorted by queueNumber, then historical
    _queue.sort((a, b) {
      if (a.status == QueueStatus.serving && b.status != QueueStatus.serving) return -1;
      if (b.status == QueueStatus.serving && a.status != QueueStatus.serving) return 1;

      if (a.status == QueueStatus.waiting && b.status == QueueStatus.waiting) {
        return a.queueNumber.compareTo(b.queueNumber);
      }
      final aActive = a.status == QueueStatus.waiting;
      final bActive = b.status == QueueStatus.waiting;
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;

      return a.entryTime.compareTo(b.entryTime);
    });

    notifyListeners();
    await _save();
  }

  // Remove / update status of a queue item
  Future<void> updateQueueItemStatus(String queueItemId, QueueStatus newStatus) async {
    final idx = _queue.indexWhere((item) => item.id == queueItemId);
    if (idx >= 0) {
      _queue[idx] = _queue[idx].copyWith(status: newStatus);
      notifyListeners();
      await _save();
    }
  }

  // Toggle fees paid status
  Future<void> toggleFeesPaid(String queueItemId) async {
    final idx = _queue.indexWhere((item) => item.id == queueItemId);
    if (idx >= 0) {
      _queue[idx] = _queue[idx].copyWith(isFeesPaid: !_queue[idx].isFeesPaid);
      notifyListeners();
      await _save();
    }
  }

  // Set fees paid status directly
  Future<void> setFeesPaid(String queueItemId, bool isPaid) async {
    final idx = _queue.indexWhere((item) => item.id == queueItemId);
    if (idx >= 0) {
      _queue[idx] = _queue[idx].copyWith(isFeesPaid: isPaid);
      notifyListeners();
      await _save();
    }
  }

  // Add a medical record (Prescription)
  Future<void> addMedicalRecord(MedicalRecord record) async {
    _records.add(record);
    // Find matching queue item for this patient in 'serving' status, and mark them as 'done'
    final activeQueue = getActiveQueue();
    final patientQueueIdx = activeQueue.indexWhere((item) => 
      item.patientId == record.patientId && item.status == QueueStatus.serving
    );

    if (patientQueueIdx >= 0) {
      final queueItemId = activeQueue[patientQueueIdx].id;
      final qIdx = _queue.indexWhere((item) => item.id == queueItemId);
      if (qIdx >= 0) {
        _queue[qIdx] = _queue[qIdx].copyWith(status: QueueStatus.done);
      }
    } else {
      // If none are currently serving, but they are waiting, complete the first waiting record
      final waitingIdx = activeQueue.indexWhere((item) => 
        item.patientId == record.patientId && item.status == QueueStatus.waiting
      );
      if (waitingIdx >= 0) {
        final queueItemId = activeQueue[waitingIdx].id;
        final qIdx = _queue.indexWhere((item) => item.id == queueItemId);
        if (qIdx >= 0) {
          _queue[qIdx] = _queue[qIdx].copyWith(status: QueueStatus.done);
        }
      }
    }

    notifyListeners();
    await _save();
  }

  // Get medical records/prescriptions for a specific patient
  List<MedicalRecord> getPatientRecords(String patientId) {
    return _records.where((r) => r.patientId == patientId).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  // Helper: Get active patient
  QueueItem? getActiveServingPatient() {
    final active = getActiveQueue();
    final serving = active.where((item) => item.status == QueueStatus.serving).toList();
    if (serving.isNotEmpty) {
      return serving.first;
    }
    return null;
  }

  // Start consultation for a patient
  Future<void> startConsultation(String queueItemId) async {
    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].status == QueueStatus.serving) {
        _queue[i] = _queue[i].copyWith(status: QueueStatus.waiting); // Suspend previous
      }
      if (_queue[i].id == queueItemId) {
        _queue[i] = _queue[i].copyWith(status: QueueStatus.serving);
      }
    }
    notifyListeners();
    await _save();
  }

  // --- Appointment Methods ---

  Future<void> bookAppointment(Appointment app) async {
    _appointments.add(app);
    notifyListeners();
    await _save();
  }

  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus newStatus) async {
    final idx = _appointments.indexWhere((a) => a.id == appointmentId);
    if (idx >= 0) {
      _appointments[idx] = _appointments[idx].copyWith(status: newStatus);
      notifyListeners();
      await _save();
    }
  }

  List<Appointment> getAppointmentsByMobile(String mobileNumber) {
    return _appointments.where((a) => a.patientMobile == mobileNumber).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Appointment> getTodayAppointments() {
    final now = DateTime.now();
    return _appointments.where((a) => 
      a.dateTime.year == now.year &&
      a.dateTime.month == now.month &&
      a.dateTime.day == now.day
    ).toList();
  }

  // --- Medicine Master Methods ---

  Future<void> addMasterMedicine(MedicinePreset med) async {
    final idx = _medicinesMaster.indexWhere((m) => m.name.toLowerCase() == med.name.toLowerCase());
    if (idx >= 0) {
      _medicinesMaster[idx] = med;
    } else {
      _medicinesMaster.add(med);
    }
    notifyListeners();
    await _save();
  }

  Future<void> updateMasterMedicine(String oldName, MedicinePreset newMed) async {
    final idx = _medicinesMaster.indexWhere((m) => m.name.toLowerCase() == oldName.toLowerCase());
    if (idx >= 0) {
      _medicinesMaster[idx] = newMed;
      notifyListeners();
      await _save();
    }
  }

  Future<void> deleteMasterMedicine(String name) async {
    _medicinesMaster.removeWhere((m) => m.name.toLowerCase() == name.toLowerCase());
    notifyListeners();
    await _save();
  }

  // Clear everything from the store
  Future<void> clearAll() async {
    _patients = [];
    _queue = [];
    _records = [];
    _appointments = [];
    _medicinesMaster = List.from(medicinePresets);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPatients);
    await prefs.remove(_keyQueue);
    await prefs.remove(_keyRecords);
    await prefs.remove(_keyAppointments);
    await prefs.remove(_keyMedicinesMaster);
  }
}
