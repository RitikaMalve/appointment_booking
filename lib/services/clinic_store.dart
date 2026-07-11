import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/queue_item.dart';
import '../models/medical_record.dart';

class ClinicStore extends ChangeNotifier {
  static const String _keyPatients = 'clinic_patients';
  static const String _keyQueue = 'clinic_queue';
  static const String _keyRecords = 'clinic_records';

  List<Patient> _patients = [];
  List<QueueItem> _queue = [];
  List<MedicalRecord> _records = [];
  bool _isInitialized = false;

  List<Patient> get patients => _patients;
  List<QueueItem> get queue => _queue;
  List<MedicalRecord> get records => _records;
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
  }) async {
    _patients = List.from(newPatients);
    _queue = List.from(newQueue);
    _records = List.from(newRecords);
    notifyListeners();
    await _save();
  }

  // Register a patient
  Future<void> registerPatient(Patient patient) async {
    final index = _patients.indexWhere((p) => p.mobileNumber == patient.mobileNumber);
    if (index >= 0) {
      _patients[index] = patient; // Update if exists
    } else {
      _patients.add(patient); // Insert new
    }
    notifyListeners();
    await _save();
  }

  // Get patient by phone
  Patient? getPatientByMobile(String mobileNumber) {
    if (mobileNumber.trim().isEmpty) return null;
    final cleanNum = mobileNumber.trim();
    final idx = _patients.indexWhere((p) => p.mobileNumber == cleanNum);
    return idx >= 0 ? _patients[idx] : null;
  }

  // Get patient queue status & position info
  Map<String, dynamic> getPatientQueueInfo(String mobileNumber) {
    final activeQ = getActiveQueue();
    final idx = activeQ.indexWhere((item) => item.patientMobile == mobileNumber);

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
    // Note: the one currently "serving" is ahead of everyone waiting.
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
      // If position is 1 or 2, they are near to visit the doctor
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
  Future<bool> addToQueue(String mobileNumber) async {
    // Check if patient registered
    final patient = getPatientByMobile(mobileNumber);
    if (patient == null) return false;

    // Check if already in active queue
    final isAlreadyInQueue = getActiveQueue().any((item) => item.patientMobile == mobileNumber);
    if (isAlreadyInQueue) return false;

    // Get today's starting queue number
    int nextQueueNum = 1;
    if (_queue.isNotEmpty) {
      nextQueueNum = _queue.map((q) => q.queueNumber).reduce((a, b) => a > b ? a : b) + 1;
    }

    final newItem = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientMobile: mobileNumber,
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
      item.patientMobile == record.patientMobile && item.status == QueueStatus.serving
    );

    if (patientQueueIdx >= 0) {
      final queueItemId = activeQueue[patientQueueIdx].id;
      final qIdx = _queue.indexWhere((item) => item.id == queueItemId);
      if (qIdx >= 0) {
        _queue[qIdx] = _queue[qIdx].copyWith(status: QueueStatus.done);
      }
    } else {
      // If none are currently serving, but they are waiting, let's complete the first waiting record
      final waitingIdx = activeQueue.indexWhere((item) => 
        item.patientMobile == record.patientMobile && item.status == QueueStatus.waiting
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
  List<MedicalRecord> getPatientRecords(String mobileNumber) {
    return _records.where((r) => r.patientMobile == mobileNumber).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Newest first
  }

  // Helper: Get active patient (the one status == serving, or if none, we can set the first waiting to serving)
  QueueItem? getActiveServingPatient() {
    final active = getActiveQueue();
    final serving = active.where((item) => item.status == QueueStatus.serving).toList();
    if (serving.isNotEmpty) {
      return serving.first;
    }
    return null;
  }

  // Start consultation for a patient (moves them to "serving" status, and moves any previous serving back to waiting or completes them)
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

  // Clear everything from the store
  Future<void> clearAll() async {
    _patients = [];
    _queue = [];
    _records = [];
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPatients);
    await prefs.remove(_keyQueue);
    await prefs.remove(_keyRecords);
  }
}
