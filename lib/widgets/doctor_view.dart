import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/queue_item.dart';
import '../models/medical_record.dart';
import '../models/appointment.dart';
import '../services/clinic_store.dart';
import '../utils/medicine_presets.dart';

class DoctorView extends StatefulWidget {
  final ClinicStore store;
  final int activeIndex;
  final ValueChanged<int> onTabChanged;

  const DoctorView({
    super.key, 
    required this.store,
    required this.activeIndex,
    required this.onTabChanged,
  });

  @override
  State<DoctorView> createState() => _DoctorViewState();
}

class _DoctorViewState extends State<DoctorView> {
  final _prescriptionFormKey = GlobalKey<FormState>();
  
  // Consultation Form Controllers
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Medicine Entry Form
  final _medNameController = TextEditingController();
  final _medDosageController = TextEditingController(text: '1-0-1');
  final _medDurationController = TextEditingController(text: '5 days');
  final _medInstructionsController = TextEditingController(text: 'After food');

  // Medical Test Entry
  final _testNameController = TextEditingController();
  final List<String> _tempTests = [];
  final List<MedicineItem> _tempMedicines = [];
  bool _isFeesPaidDirect = false;

  // Selected patient for "Patients Master" view
  Patient? _selectedLookupPatient;
  String _selectedLookupSearch = '';

  // Medicine Inventory Form
  final _invMedNameController = TextEditingController();
  final _invMedCategoryController = TextEditingController(text: 'Pain & Fever');
  final _invMedDosageController = TextEditingController(text: '1-0-1');
  final _invMedDurationController = TextEditingController(text: '5 days');
  final _invMedInstructionsController = TextEditingController(text: 'After food');
  String? _editingInvMedName;

  // Suggester search state
  String _medCategoryFilter = 'All';
  String _medSearchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _medNameController.dispose();
    _medDosageController.dispose();
    _medDurationController.dispose();
    _medInstructionsController.dispose();
    _testNameController.dispose();
    _invMedNameController.dispose();
    _invMedCategoryController.dispose();
    _invMedDosageController.dispose();
    _invMedDurationController.dispose();
    _invMedInstructionsController.dispose();
    super.dispose();
  }

  void _addTempMedicine() {
    final name = _medNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine Name is required')));
      return;
    }
    setState(() {
      _tempMedicines.add(MedicineItem(
        name: name,
        dosage: _medDosageController.text.trim(),
        duration: _medDurationController.text.trim(),
        instructions: _medInstructionsController.text.trim(),
      ));
      _medNameController.clear();
      _medDosageController.text = '1-0-1';
      _medDurationController.text = '5 days';
      _medInstructionsController.text = 'After food';
    });
  }

  void _quickAddPreset(MedicinePreset preset) {
    setState(() {
      _tempMedicines.add(MedicineItem(
        name: preset.name,
        dosage: preset.defaultDosage,
        duration: preset.defaultDuration,
        instructions: preset.defaultInstructions,
      ));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${preset.name} added to prescription!'), duration: const Duration(seconds: 1)),
    );
  }

  void _addMedicalTest() {
    final test = _testNameController.text.trim();
    if (test.isEmpty) return;
    setState(() {
      _tempTests.add(test);
      _testNameController.clear();
    });
  }

  void _removeMedicalTest(int index) {
    setState(() {
      _tempTests.removeAt(index);
    });
  }

  void _completeConsultation(QueueItem queueItem, Patient patient) {
    if (!_prescriptionFormKey.currentState!.validate()) return;
    if (_tempMedicines.isEmpty && _tempTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine or test to the consultation prescription.')),
      );
      return;
    }

    final record = MedicalRecord(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patient.id,
      date: DateTime.now(),
      diagnosis: _diagnosisController.text.trim(),
      notes: _notesController.text.trim(),
      medicines: List.from(_tempMedicines),
      tests: List.from(_tempTests),
    );

    widget.store.addMedicalRecord(record);
    widget.store.setFeesPaid(queueItem.id, _isFeesPaidDirect);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Consultation completed and prescription generated for ${patient.name}!')),
    );

    // Reset Form
    setState(() {
      _diagnosisController.clear();
      _notesController.clear();
      _tempMedicines.clear();
      _tempTests.clear();
      _isFeesPaidDirect = false;
    });
  }

  // --- Medicine Master Actions ---
  void _saveInventoryMedicine() {
    final name = _invMedNameController.text.trim();
    final category = _invMedCategoryController.text.trim();
    final dosage = _invMedDosageController.text.trim();
    final duration = _invMedDurationController.text.trim();
    final instructions = _invMedInstructionsController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine Name is required')));
      return;
    }

    final newItem = MedicinePreset(
      name: name,
      category: category,
      defaultDosage: dosage,
      defaultDuration: duration,
      defaultInstructions: instructions,
    );

    if (_editingInvMedName != null) {
      widget.store.updateMasterMedicine(_editingInvMedName!, newItem);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory updated successfully.')));
    } else {
      widget.store.addMasterMedicine(newItem);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New medicine added to inventory!')));
    }

    _clearInventoryForm();
  }

  void _clearInventoryForm() {
    _invMedNameController.clear();
    setState(() {
      _invMedCategoryController.text = 'Pain & Fever';
      _invMedDosageController.text = '1-0-1';
      _invMedDurationController.text = '5 days';
      _invMedInstructionsController.text = 'After food';
      _editingInvMedName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeQueue = widget.store.getActiveQueue();
    final historyQueue = widget.store.getHistoricalQueue();
    
    // Appointments metrics today
    final todayApptsCount = widget.store.getTodayAppointments().length;
    final doneCount = historyQueue.where((q) => q.status == QueueStatus.done).length;
    final pendingCount = activeQueue.where((q) => q.status == QueueStatus.waiting).length;

    // Separate active patient (serving) from waiting patients
    final servingItem = widget.store.getActiveServingPatient();
    final Patient? activePatient = servingItem != null 
        ? widget.store.getPatientById(servingItem.patientId) 
        : null;

    final waitingQueue = activeQueue.where((item) => item.status == QueueStatus.waiting).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 950;
        final views = [
          _buildCabinQueueTab(activePatient, servingItem, activeQueue, waitingQueue, todayApptsCount, doneCount, pendingCount, isDesktop),
          _buildPatientsDatabaseTab(isDesktop),
          _buildMedicinesCatalogTab(isDesktop),
        ];

        if (widget.activeIndex < 0 || widget.activeIndex >= views.length) {
          return const Center(child: Text('Cabin Section Coming Soon!'));
        }

        return views[widget.activeIndex];
      },
    );
  }

  // --- TAB 1: Cabin Queue Dashboard ---
  Widget _buildCabinQueueTab(
    Patient? activePatient, 
    QueueItem? servingItem, 
    List<QueueItem> activeQueue, 
    List<QueueItem> waitingQueue,
    int totalAppts, int completed, int pending,
    bool isDesktop,
  ) {
    // 1. Dashboard summary cards
    final statsHeader = Row(
      children: [
        _buildMetricSummaryCard('Today\'s Appointments', totalAppts.toString(), Colors.blue),
        const SizedBox(width: 12),
        _buildMetricSummaryCard('Completed Consultation', completed.toString(), Colors.green),
        const SizedBox(width: 12),
        _buildMetricSummaryCard('Pending Waiting List', pending.toString(), Colors.orange),
      ],
    );

    // 2. Queue chip overview list
    final queueChipOverview = Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Patient Live Cabin Chips', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            if (activeQueue.isEmpty)
              const Text('No patients checked in today.', style: TextStyle(color: Colors.grey, fontSize: 13))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeQueue.map((item) {
                  final p = widget.store.getPatientById(item.patientId);
                  final bool isServ = item.status == QueueStatus.serving;
                  return ActionChip(
                    backgroundColor: isServ ? Colors.teal.shade50 : Colors.grey.shade100,
                    side: BorderSide(color: isServ ? Colors.teal.shade400 : Colors.grey.shade300),
                    avatar: CircleAvatar(
                      backgroundColor: isServ ? Colors.teal : Colors.blue.shade400,
                      radius: 10,
                      child: Text(
                        '#${item.queueNumber}',
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    label: Text(p?.name ?? 'Unknown', style: TextStyle(fontSize: 12, fontWeight: isServ ? FontWeight.bold : FontWeight.normal)),
                    onPressed: () {
                      widget.store.startConsultation(item.id);
                      setState(() {
                        _isFeesPaidDirect = item.isFeesPaid;
                      });
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );

    // 3. Active Patient Profile Card (Pinned)
    final activePatientCard = Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: activePatient == null || servingItem == null
            ? _buildNoActivePatientBanner(waitingQueue)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activePatient.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const SizedBox(height: 2),
                          Text('Queue Token: #${servingItem.queueNumber}', style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.shade200)),
                        child: Text('Consultation Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade900)),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(Icons.phone, 'Mobile Number', activePatient.mobileNumber),
                  _buildDetailRow(Icons.wc, 'Gender / Age', '${activePatient.gender} • ${activePatient.age} years'),
                  _buildDetailRow(Icons.cake, 'DOB', DateFormat('dd MMM yyyy').format(activePatient.dateOfBirth)),
                  _buildDetailRow(Icons.home, 'Address', activePatient.address),
                  _buildDetailRow(Icons.emergency_share, 'Emergency Contact', activePatient.emergencyContact),
                  const Divider(height: 24),
                  const Text('Consultation History Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildHistoryAccordionList(activePatient.id),
                ],
              ),
      ),
    );

    // 4. Consultation Form (Right panel)
    final prescriptionForm = Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: activePatient == null || servingItem == null
            ? const Center(child: Text('Select an active patient to start consultation.', style: TextStyle(color: Colors.grey, fontSize: 15)))
            : Form(
                key: _prescriptionFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Write Prescription & Advices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F766E))),
                      const SizedBox(height: 16),
                      
                      // Diagnosis
                      TextFormField(
                        controller: _diagnosisController,
                        decoration: InputDecoration(
                          labelText: 'Diagnosis / Diseases / Complaints',
                          prefixIcon: const Icon(Icons.sick_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Diagnosis is required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Advices / Notes
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Doctor\'s Advice / Notes',
                          prefixIcon: const Icon(Icons.note_alt_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Suggester
                      _buildQuickMedicineSuggester(),
                      const SizedBox(height: 16),

                      // Added Medicines list
                      const Text('Prescribed Medicines:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      _buildPrescribedMedicinesTable(),
                      const SizedBox(height: 16),

                      // Medical Tests prescribing
                      _buildMedicalTestsForm(),
                      const SizedBox(height: 16),

                      // Fees paid switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isFeesPaidDirect ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isFeesPaidDirect ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(_isFeesPaidDirect ? Icons.check_circle : Icons.error_outline, color: _isFeesPaidDirect ? Colors.green.shade800 : Colors.red.shade800, size: 18),
                                const SizedBox(width: 8),
                                Text('Consultation / Visit Fees Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _isFeesPaidDirect ? Colors.green.shade800 : Colors.red.shade800)),
                              ],
                            ),
                            Switch(
                              value: _isFeesPaidDirect,
                              activeColor: Colors.green,
                              onChanged: (v) => setState(() => _isFeesPaidDirect = v),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save consultation
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _completeConsultation(servingItem, activePatient),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Complete Visit & Save Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
      ),
    );

    final leftPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        statsHeader,
        const SizedBox(height: 20),
        queueChipOverview,
        const SizedBox(height: 20),
        activePatientCard,
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 10, child: leftPanel),
                const SizedBox(width: 24),
                Expanded(flex: 11, child: prescriptionForm),
              ],
            )
          : Column(
              children: [
                leftPanel,
                const SizedBox(height: 20),
                prescriptionForm,
              ],
            ),
    );
  }

  // --- TAB 2: Patients Database & history finder ---
  Widget _buildPatientsDatabaseTab(bool isDesktop) {
    final list = widget.store.patients;

    final searchResults = list.where((p) {
      if (_selectedLookupSearch.isEmpty) return true;
      return p.name.toLowerCase().contains(_selectedLookupSearch.toLowerCase()) || 
             p.mobileNumber.contains(_selectedLookupSearch);
    }).toList();

    final patientsListPanel = Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Search Patients Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0D9488).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Text('${searchResults.length} Patients', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, ID, or phone...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _selectedLookupSearch = val.trim()),
            ),
            const SizedBox(height: 16),
            
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: Text('PATIENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('CONDITIONS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 2, child: Text('KEY VITALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(flex: 1, child: Text('AI RISK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center)),
                  ],
                ),
              ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            
            Container(
              constraints: const BoxConstraints(maxHeight: 520),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: searchResults.length,
                separatorBuilder: (c, i) => const Divider(height: 12),
                itemBuilder: (context, idx) {
                  final p = searchResults[idx];
                  final isSel = _selectedLookupPatient?.id == p.id;
                  
                  final pRecords = widget.store.getPatientRecords(p.id);
                  String latestVitals = 'BP: 120/80 • HR: 72';
                  List<String> conditions = [];
                  if (pRecords.isNotEmpty) {
                    final last = pRecords.first;
                    if (last.diagnosis.isNotEmpty) {
                      conditions.add(last.diagnosis.split(' ').first);
                    }
                  }
                  if (conditions.isEmpty) {
                    conditions.add(p.age > 45 ? 'HYP' : 'HEALTHY');
                  }
                  
                  int aiRisk = p.age > 60 ? 84 : (p.age > 45 ? 68 : 42);
                  Color riskColor = aiRisk > 80 ? Colors.red : (aiRisk > 60 ? Colors.orange : Colors.green);
                  
                  String statusStr = aiRisk > 80 ? 'CRITICAL ALERTS' : (aiRisk > 60 ? 'NEEDS REVIEW' : 'BASELINE STABLE');
                  Color statusBorderColor = aiRisk > 80 ? Colors.red : (aiRisk > 60 ? Colors.orange : Colors.green);
                  Color statusBgColor = aiRisk > 80 ? Colors.red.shade50 : (aiRisk > 60 ? Colors.orange.shade50 : Colors.green.shade50);
                  
                  return InkWell(
                    onTap: () => setState(() => _selectedLookupPatient = p),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF0D9488).withOpacity(0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? const Color(0xFF0D9488).withOpacity(0.3) : Colors.transparent),
                      ),
                      child: isDesktop
                          ? Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.teal.shade50,
                                        child: Text(p.name.substring(0,1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D9488))),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                                            Text('#${p.id.substring(0, 8)} • ${p.age}y ${p.gender.substring(0, 1)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Wrap(
                                    spacing: 4,
                                    children: conditions.map((c) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: Text(c.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                                    )).toList(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(latestVitals, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    children: [
                                      Text('$aiRisk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: riskColor)),
                                      Container(height: 2, width: 20, color: riskColor),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      border: Border.all(color: statusBorderColor),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(statusStr, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusBorderColor)),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.teal.shade50,
                                      child: Text(p.name.substring(0,1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0D9488))),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(8)),
                                      child: Text(statusStr, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusBorderColor)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('ID: #${p.id.substring(0,8)} | Vitals: $latestVitals', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    final detailsPanel = Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _selectedLookupPatient == null
            ? const Center(child: Text('Select a patient from the list on the left to view complete history details.', style: TextStyle(color: Colors.grey)))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedLookupPatient!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text('Patient ID: ${_selectedLookupPatient!.id}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const Divider(height: 24),
                    _buildDetailRow(Icons.phone, 'Mobile Phone', _selectedLookupPatient!.mobileNumber),
                    _buildDetailRow(Icons.wc, 'Gender / Age', '${_selectedLookupPatient!.gender} • ${_selectedLookupPatient!.age} years'),
                    _buildDetailRow(Icons.home, 'Home Address', _selectedLookupPatient!.address),
                    _buildDetailRow(Icons.emergency, 'Emergency contact', _selectedLookupPatient!.emergencyContact),
                    const Divider(height: 24),
                    const Text('Complete Prescriptions & Clinical History:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E))),
                    const SizedBox(height: 12),
                    _buildDetailedHistoryView(_selectedLookupPatient!.id),
                  ],
                ),
              ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: patientsListPanel),
                const SizedBox(width: 24),
                Expanded(flex: 12, child: detailsPanel),
              ],
            )
          : Column(
              children: [
                patientsListPanel,
                const SizedBox(height: 20),
                detailsPanel,
              ],
            ),
    );
  }

  // --- TAB 3: Medicines Catalog Inventory ---
  Widget _buildMedicinesCatalogTab(bool isDesktop) {
    final list = widget.store.medicinesMaster;

    final formPanel = Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingInvMedName == null ? 'Create New Medicine Master' : 'Edit Medicine Details',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _invMedNameController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _invMedCategoryController.text,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'Pain & Fever', child: Text('Pain & Fever')),
                DropdownMenuItem(value: 'Antibiotics', child: Text('Antibiotics')),
                DropdownMenuItem(value: 'Acidity & Digestion', child: Text('Acidity & Digestion')),
                DropdownMenuItem(value: 'Allergies & Cold', child: Text('Allergies & Cold')),
                DropdownMenuItem(value: 'Chronic', child: Text('Chronic (BP/Diabetes)')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _invMedCategoryController.text = val);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _invMedDosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _invMedDurationController,
                    decoration: InputDecoration(
                      labelText: 'Duration',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _invMedInstructionsController,
              decoration: InputDecoration(
                labelText: 'Instructions',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_editingInvMedName != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearInventoryForm,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveInventoryMedicine,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
                    child: Text(_editingInvMedName == null ? 'Save Medicine' : 'Save Changes'),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );

    final inventoryList = Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinical Master Inventory List (${list.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: list.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (context, idx) {
                  final med = list[idx];
                  return ListTile(
                    title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Cat: ${med.category} | Dosage: ${med.defaultDosage} | ${med.defaultInstructions}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                          onPressed: () => _editInventoryMedicine(med),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () {
                            widget.store.deleteMasterMedicine(med.name);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine deleted from Master.')));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 8, child: formPanel),
                const SizedBox(width: 24),
                Expanded(flex: 12, child: inventoryList),
              ],
            )
          : Column(
              children: [
                formPanel,
                const SizedBox(height: 16),
                inventoryList,
              ],
            ),
    );
  }

  void _editInventoryMedicine(MedicinePreset med) {
    setState(() {
      _editingInvMedName = med.name;
      _invMedNameController.text = med.name;
      _invMedCategoryController.text = med.category;
      _invMedDosageController.text = med.defaultDosage;
      _invMedDurationController.text = med.defaultDuration;
      _invMedInstructionsController.text = med.defaultInstructions;
    });
  }

  // --- Sub-widgets & helpers ---

  Widget _buildMetricSummaryCard(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActivePatientBanner(List<QueueItem> waitingQueue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Active Patient Called', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Select a patient chip from the live dashboard queue at the top to begin consultation.', style: TextStyle(color: Colors.grey, height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (waitingQueue.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                widget.store.startConsultation(waitingQueue.first.id);
                setState(() => _isFeesPaidDirect = waitingQueue.first.isFeesPaid);
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text('Call Next Patient (#${waitingQueue.first.queueNumber})'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
            )
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildHistoryAccordionList(String patientId) {
    final records = widget.store.getPatientRecords(patientId);
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10)),
        child: const Text('No previous medical records.', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length > 2 ? 2 : records.length, // show last 2 max
      itemBuilder: (context, idx) {
        final rec = records[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ExpansionTile(
            title: Text(rec.diagnosis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(DateFormat('dd MMM yyyy').format(rec.date), style: const TextStyle(fontSize: 10)),
            childrenPadding: const EdgeInsets.all(12),
            children: [
              if (rec.notes.isNotEmpty) Text('Notes: ${rec.notes}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              ...rec.medicines.map((m) => Text('• ${m.name} (${m.dosage})', style: const TextStyle(fontSize: 12))),
              if (rec.tests.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Tests: ${rec.tests.join(", ")}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedHistoryView(String patientId) {
    final records = widget.store.getPatientRecords(patientId);
    if (records.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No previous records found for this patient.', style: TextStyle(color: Colors.grey))));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, idx) {
        final rec = records[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Diagnosis: ${rec.diagnosis}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(DateFormat('dd MMM yyyy, hh:mm a').format(rec.date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                if (rec.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Advice / Clinical Notes: ${rec.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
                const Divider(height: 20),
                const Text('Medicines Prescribed:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                ...rec.medicines.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text('${m.name} (${m.dosage}) - ${m.duration} | Instructions: ${m.instructions}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )),
                if (rec.tests.isNotEmpty) ...[
                  const Divider(height: 20),
                  const Text('Prescribed Laboratory Tests:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: rec.tests.map((t) => Chip(
                      label: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickMedicineSuggester() {
    final list = widget.store.medicinesMaster;

    final filtered = list.where((med) {
      final matchesCat = _medCategoryFilter == 'All' || med.category.contains(_medCategoryFilter.split(' ').first);
      final matchesSearch = _medSearchQuery.isEmpty || med.name.toLowerCase().contains(_medSearchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Card(
      color: Colors.teal.shade50.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.teal.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF0D9488), size: 16),
                SizedBox(width: 8),
                Text('Quick Medicine Suggester', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E))),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Pain & Fever', 'Antibiotics', 'Acidity & Digestion', 'Allergies & Cold', 'Chronic'].map((cat) {
                  final isSel = _medCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(cat, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      selected: isSel,
                      onSelected: (selected) {
                        if (selected) setState(() => _medCategoryFilter = cat);
                      },
                      selectedColor: Colors.teal.shade100,
                      labelStyle: TextStyle(color: isSel ? Colors.teal.shade800 : Colors.black87),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: EdgeInsets.zero,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              decoration: InputDecoration(
                hintText: 'Search medicines inventory...',
                prefixIcon: const Icon(Icons.search, size: 14),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (v) => setState(() => _medSearchQuery = v.trim()),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView(
                shrinkWrap: true,
                children: filtered.map((preset) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.shade100)),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _medNameController.text = preset.name;
                                _medDosageController.text = preset.defaultDosage;
                                _medDurationController.text = preset.defaultDuration;
                                _medInstructionsController.text = preset.defaultInstructions;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(preset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('Dosage: ${preset.defaultDosage} | Dur: ${preset.defaultDuration}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.teal, size: 20),
                          onPressed: () => _quickAddPreset(preset),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescribedMedicinesTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          if (_tempMedicines.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tempMedicines.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final med = _tempMedicines[idx];
                return ListTile(
                  dense: true,
                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Dosage: ${med.dosage} | Dur: ${med.duration} | Instructions: ${med.instructions}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                    onPressed: () => setState(() => _tempMedicines.removeAt(idx)),
                  ),
                );
              },
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No medicines prescribed yet.', style: TextStyle(color: Colors.grey, fontSize: 12))),
            ),
          
          // Add custom medicine row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                const Divider(),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _medNameController,
                  decoration: InputDecoration(
                    labelText: 'Custom Medicine Name',
                    hintText: 'e.g. Paracetamol 650mg',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _medDosageController,
                        decoration: InputDecoration(
                          labelText: 'Dosage',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _medDurationController,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _medInstructionsController,
                  decoration: InputDecoration(
                    labelText: 'Instructions',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _addTempMedicine,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add custom medicine', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMedicalTestsForm() {
    return Card(
      color: Colors.blue.shade50.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prescribe Laboratory Tests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _testNameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. CBC Blood Test, ECG, Lipid Panel',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    onFieldSubmitted: (_) => _addMedicalTest(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addMedicalTest,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('Add Test'),
                )
              ],
            ),
            if (_tempTests.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tempTests.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final test = entry.value;
                  return Chip(
                    label: Text(test, style: const TextStyle(fontSize: 11)),
                    onDeleted: () => _removeMedicalTest(idx),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    deleteIconColor: Colors.red,
                  );
                }).toList(),
              )
            ]
          ],
        ),
      ),
    );
  }
}
