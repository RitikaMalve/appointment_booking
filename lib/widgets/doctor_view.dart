import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/queue_item.dart';
import '../models/medical_record.dart';
import '../services/clinic_store.dart';
import '../utils/medicine_presets.dart';

class DoctorView extends StatefulWidget {
  final ClinicStore store;

  const DoctorView({super.key, required this.store});

  @override
  State<DoctorView> createState() => _DoctorViewState();
}

class _DoctorViewState extends State<DoctorView> with SingleTickerProviderStateMixin {
  final _prescriptionFormKey = GlobalKey<FormState>();
  
  // Prescription Form Fields
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Single Medicine Entry Controllers
  final _medNameController = TextEditingController();
  final _medDosageController = TextEditingController();
  final _medDurationController = TextEditingController();
  final _medInstructionsController = TextEditingController();

  final List<MedicineItem> _tempMedicines = [];
  bool _isFeesPaidDirect = false;
  String? _lastServingPatientId;

  late TabController _tabController;
  String _selectedMedCategory = 'All';
  String _searchPresetQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    _medNameController.dispose();
    _medDosageController.dispose();
    _medDurationController.dispose();
    _medInstructionsController.dispose();
    super.dispose();
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
      SnackBar(
        content: Text('${preset.name} added to prescription!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addTempMedicine() {
    final name = _medNameController.text.trim();
    final dosage = _medDosageController.text.trim();
    final duration = _medDurationController.text.trim();
    final instructions = _medInstructionsController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine Name is required')),
      );
      return;
    }

    setState(() {
      _tempMedicines.add(MedicineItem(
        name: name,
        dosage: dosage.isEmpty ? '1-0-1' : dosage,
        duration: duration.isEmpty ? '5 days' : duration,
        instructions: instructions.isEmpty ? 'After food' : instructions,
      ));

      // Reset individual medicine controllers
      _medNameController.clear();
      _medDosageController.clear();
      _medDurationController.clear();
      _medInstructionsController.clear();
    });
  }

  void _removeTempMedicine(int index) {
    setState(() {
      _tempMedicines.removeAt(index);
    });
  }

  void _completeConsultation(QueueItem queueItem, Patient patient) {
    if (!_prescriptionFormKey.currentState!.validate()) return;
    if (_tempMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine')),
      );
      return;
    }

    final record = MedicalRecord(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      patientMobile: patient.mobileNumber,
      date: DateTime.now(),
      diagnosis: _diagnosisController.text.trim(),
      notes: _notesController.text.trim(),
      medicines: List.from(_tempMedicines),
    );

    // Save record and update queue status to Done
    widget.store.addMedicalRecord(record);
    
    // Set fees status if updated by doctor
    widget.store.setFeesPaid(queueItem.id, _isFeesPaidDirect);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Consultation completed & prescription generated for ${patient.name}!')),
    );

    // Reset Form
    setState(() {
      _diagnosisController.clear();
      _notesController.clear();
      _tempMedicines.clear();
      _isFeesPaidDirect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeQueue = widget.store.getActiveQueue();
    final servingItem = widget.store.getActiveServingPatient();
    final Patient? activePatient = servingItem != null 
        ? widget.store.getPatientByMobile(servingItem.patientMobile) 
        : null;

    // Synchronize fees paid state when active patient changes
    if (servingItem != null && servingItem.id != _lastServingPatientId) {
      _isFeesPaidDirect = servingItem.isFeesPaid;
      _lastServingPatientId = servingItem.id;
    } else if (servingItem == null) {
      _lastServingPatientId = null;
    }

    // Other waiting patients
    final waitingQueue = activeQueue.where((item) => item.status == QueueStatus.waiting).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        // Left Panel: Queue list & selected patient details & history
        final leftPanel = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Current Queue Overview
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctor\'s Queue Dashboard',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (activeQueue.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No active patients in clinic today.', style: TextStyle(color: Colors.grey)),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: activeQueue.map((item) {
                            final p = widget.store.getPatientByMobile(item.patientMobile);
                            final bool isServ = item.status == QueueStatus.serving;
                            return ActionChip(
                              backgroundColor: isServ ? Colors.teal.shade50 : Colors.grey.shade100,
                              side: BorderSide(color: isServ ? Colors.teal.shade400 : Colors.grey.shade300),
                              avatar: CircleAvatar(
                                backgroundColor: isServ ? Colors.teal : Colors.blue.shade400,
                                radius: 10,
                                child: Text(
                                  '${item.queueNumber}',
                                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              label: Text(p?.name ?? 'Unknown'),
                              onPressed: () {
                                widget.store.startConsultation(item.id);
                                setState(() {
                                  _isFeesPaidDirect = item.isFeesPaid;
                                });
                                if (!isDesktop) {
                                  _tabController.animateTo(1);
                                }
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Active Patient Details Card
              if (activePatient != null && servingItem != null) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activePatient.name,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Queue Number: #${servingItem.queueNumber}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ACTIVE VISIT',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.phone, 'Mobile', activePatient.mobileNumber),
                        _buildDetailRow(Icons.wc, 'Gender / Age', '${activePatient.gender} • ${activePatient.age} years'),
                        _buildDetailRow(Icons.cake, 'DOB', DateFormat('dd MMM yyyy').format(activePatient.dateOfBirth)),
                        _buildDetailRow(Icons.home, 'Address', activePatient.address),
                        _buildDetailRow(Icons.emergency_share, 'Emergency Contact', activePatient.emergencyContact),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Past Medical History List
                Text(
                  'Previous Medical History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildPastRecordsList(activePatient.mobileNumber),
              ] else ...[
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No Active Patient',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select a patient from the queue chips above to start consultation.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (waitingQueue.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.store.startConsultation(waitingQueue.first.id);
                              setState(() {
                                _isFeesPaidDirect = waitingQueue.first.isFeesPaid;
                              });
                              if (!isDesktop) {
                                _tabController.animateTo(1);
                              }
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: Text('Call Next Patient (#${waitingQueue.first.queueNumber})'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

        // Right Panel: New Prescription Form
        final rightPanel = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: activePatient == null || servingItem == null
                ? const Center(
                    child: Text(
                      'Select patient to fill prescription',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : Form(
                    key: _prescriptionFormKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Prescription & Diagnosis',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 20),

                          // Diagnosis Field
                          TextFormField(
                            controller: _diagnosisController,
                            decoration: InputDecoration(
                              labelText: 'Diagnosis / Chief Complaint',
                              prefixIcon: const Icon(Icons.sick_outlined),
                              hintText: 'e.g. Cough, Cold and Viral Fever',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter diagnosis';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Advice/Notes Field
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Clinical Notes & Advice',
                              prefixIcon: const Icon(Icons.note_alt_outlined),
                              hintText: 'e.g. Bed rest, drink warm fluids, avoid oily foods',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Medicines Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Medicines Prescribed',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_tempMedicines.length} Added',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Table of Added Medicines
                          if (_tempMedicines.isNotEmpty)
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _tempMedicines.length,
                              separatorBuilder: (c, i) => const Divider(),
                              itemBuilder: (context, idx) {
                                final med = _tempMedicines[idx];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Dosage: ${med.dosage} | Duration: ${med.duration} | Instructions: ${med.instructions}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _removeTempMedicine(idx),
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                              ),
                              child: const Center(
                                child: Text('No medicines added yet', style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Quick Medicine Suggestions Box
                          Card(
                            color: Colors.teal.shade50.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.teal.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.auto_awesome, color: Color(0xFF0D9488), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Quick Medicine Suggester',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Category Selector Row
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: ['All', 'Pain & Fever', 'Antibiotics', 'Acidity & Digestion', 'Allergies & Cold', 'Chronic']
                                          .map((category) {
                                        final isSel = _selectedMedCategory == category;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 6.0),
                                          child: ChoiceChip(
                                            label: Text(category, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                                            selected: isSel,
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedMedCategory = category;
                                                });
                                              }
                                            },
                                            selectedColor: Colors.teal.shade100,
                                            labelStyle: TextStyle(color: isSel ? Colors.teal.shade800 : Colors.black87),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Search Field for presets
                                  TextFormField(
                                    decoration: InputDecoration(
                                      hintText: 'Search medicines...',
                                      prefixIcon: const Icon(Icons.search, size: 16),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      fillColor: Colors.white,
                                      filled: true,
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchPresetQuery = val.trim();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Matching suggestions list
                                  Container(
                                    constraints: const BoxConstraints(maxHeight: 180),
                                    child: ListView(
                                      shrinkWrap: true,
                                      children: medicinePresets.where((preset) {
                                        final matchesCat = _selectedMedCategory == 'All' || preset.category.contains(_selectedMedCategory.split(' ').first);
                                        final matchesSearch = _searchPresetQuery.isEmpty || preset.name.toLowerCase().contains(_searchPresetQuery.toLowerCase());
                                        return matchesCat && matchesSearch;
                                      }).map((preset) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.teal.shade100),
                                          ),
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
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Form populated with ${preset.name}!'),
                                                        duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                  },
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        preset.name,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      ),
                                                      Text(
                                                        'Dosage: ${preset.defaultDosage} | Dur: ${preset.defaultDuration} | ${preset.defaultInstructions}',
                                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add_circle, color: Colors.teal, size: 24),
                                                tooltip: 'Quick Add to prescription',
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _quickAddPreset(preset),
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
                          ),
                          const SizedBox(height: 16),

                          // Add Medicine Inputs Box
                          Card(
                            color: Colors.blue.shade50.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.blue.shade100),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Add Medicine Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _medNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Medicine Name',
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
                                            hintText: 'e.g. 1-0-1',
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
                                            hintText: 'e.g. 5 days',
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
                                      hintText: 'e.g. After food',
                                      isDense: true,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: _addTempMedicine,
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add to Prescription'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Billing Switch
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isFeesPaidDirect ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _isFeesPaidDirect ? Colors.green.shade300 : Colors.red.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isFeesPaidDirect ? Icons.check_circle : Icons.error_outline,
                                      color: _isFeesPaidDirect ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Fees / Consultation Payment Paid',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isFeesPaidDirect ? Colors.green.shade800 : Colors.red.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _isFeesPaidDirect,
                                  activeColor: Colors.green,
                                  onChanged: (val) {
                                    setState(() {
                                      _isFeesPaidDirect = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Complete Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _completeConsultation(servingItem, activePatient),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Save Prescription & Complete Visit',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );

        if (isDesktop) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(height: double.infinity, child: leftPanel),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: SizedBox(height: double.infinity, child: rightPanel),
                ),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.people_alt_outlined), text: 'Patient Queue'),
                    Tab(icon: Icon(Icons.description_outlined), text: 'Prescription'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: leftPanel,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: rightPanel,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildPastRecordsList(String mobileNumber) {
    final records = widget.store.getPatientRecords(mobileNumber);

    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No past consultation history for this patient.', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, idx) {
        final rec = records[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          color: Colors.grey.shade50,
          child: ExpansionTile(
            title: Text(
              rec.diagnosis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Date: ${DateFormat('dd MMM yyyy hh:mm a').format(rec.date)}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            childrenPadding: const EdgeInsets.all(12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rec.notes.isNotEmpty) ...[
                const Text('Advice / Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                Text(rec.notes, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
              ],
              const Text('Medicines Prescribed:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              ...rec.medicines.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${m.name} (${m.dosage}) - ${m.duration} | Instructions: ${m.instructions}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
