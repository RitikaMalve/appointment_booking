import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/queue_item.dart';
import '../models/appointment.dart';
import '../utils/medicine_presets.dart';
import '../services/clinic_store.dart';

class ReceptionistView extends StatefulWidget {
  final ClinicStore store;
  final int activeIndex;
  final ValueChanged<int> onTabChanged;

  const ReceptionistView({
    super.key, 
    required this.store,
    required this.activeIndex,
    required this.onTabChanged,
  });

  @override
  State<ReceptionistView> createState() => _ReceptionistViewState();
}

class _ReceptionistViewState extends State<ReceptionistView> {

  // Registration Form Keys & Controllers
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  DateTime? _selectedDob;
  String _selectedGender = 'Male';
  bool _isExistingPatient = false;
  List<Patient> _nameSuggestions = [];

  // Medicine Inventory Form Controllers
  final _medNameController = TextEditingController();
  final _medCategoryController = TextEditingController(text: 'Pain & Fever');
  final _medDosageController = TextEditingController(text: '1-0-1');
  final _medDurationController = TextEditingController(text: '5 days');
  final _medInstructionsController = TextEditingController(text: 'After food');
  String? _editingMedName;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _mobileController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _medNameController.dispose();
    _medCategoryController.dispose();
    _medDosageController.dispose();
    _medDurationController.dispose();
    _medInstructionsController.dispose();
    super.dispose();
  }

  // Type-ahead name lookup
  void _onNameChanged() {
    final query = _nameController.text.trim();
    if (query.length >= 2) {
      final matches = widget.store.searchPatientsByName(query);
      setState(() {
        _nameSuggestions = matches;
      });
    } else {
      setState(() {
        _nameSuggestions = [];
      });
    }
  }

  void _autofillPatientDetails(Patient p) {
    setState(() {
      _isExistingPatient = true;
      _mobileController.text = p.mobileNumber;
      _nameController.text = p.name;
      _ageController.text = p.age.toString();
      _addressController.text = p.address;
      _emergencyContactController.text = p.emergencyContact;
      _selectedDob = p.dateOfBirth;
      _selectedGender = p.gender;
      _nameSuggestions = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Autofilled profile for ${p.name}!')),
    );
  }

  void _clearRegistrationFields() {
    _mobileController.clear();
    _nameController.clear();
    _ageController.clear();
    _addressController.clear();
    _emergencyContactController.clear();
    setState(() {
      _selectedDob = null;
      _selectedGender = 'Male';
      _isExistingPatient = false;
      _nameSuggestions = [];
    });
  }

  Future<void> _selectDob(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        final age = DateTime.now().year - picked.year;
        _ageController.text = age.toString();
      });
    }
  }

  void _registerAndOrAddToQueue({required bool andQueue}) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Birth')),
      );
      return;
    }

    final mobile = _mobileController.text.trim();
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;
    final address = _addressController.text.trim();
    final emergency = _emergencyContactController.text.trim();

    final pId = _isExistingPatient 
        ? (widget.store.getPatientsByMobile(mobile).firstWhere((p) => p.name.toLowerCase() == name.toLowerCase()).id)
        : '${mobile}_${name.replaceAll(' ', '_')}';

    final patient = Patient(
      id: pId,
      mobileNumber: mobile,
      name: name,
      age: age,
      address: address,
      dateOfBirth: _selectedDob!,
      gender: _selectedGender,
      emergencyContact: emergency,
      registeredAt: DateTime.now(),
    );

    widget.store.registerPatient(patient);

    if (andQueue) {
      widget.store.addToQueue(patient.id).then((success) {
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name added to live queue!')),
          );
          _clearRegistrationFields();
          widget.onTabChanged(1); // switch to Queue
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name is already active in queue.')),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Patient $name registered successfully!')),
      );
      _clearRegistrationFields();
    }
  }

  // --- Medicine Manager Actions ---

  void _saveMedicineItem() {
    final name = _medNameController.text.trim();
    final category = _medCategoryController.text.trim();
    final dosage = _medDosageController.text.trim();
    final duration = _medDurationController.text.trim();
    final instructions = _medInstructionsController.text.trim();

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

    if (_editingMedName != null) {
      widget.store.updateMasterMedicine(_editingMedName!, newItem);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine updated in inventory!')));
    } else {
      widget.store.addMasterMedicine(newItem);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine added to inventory!')));
    }

    _clearMedicineForm();
  }

  void _clearMedicineForm() {
    _medNameController.clear();
    setState(() {
      _medCategoryController.text = 'Pain & Fever';
      _medDosageController.text = '1-0-1';
      _medDurationController.text = '5 days';
      _medInstructionsController.text = 'After food';
      _editingMedName = null;
    });
  }

  void _editMedicine(MedicinePreset med) {
    setState(() {
      _editingMedName = med.name;
      _medNameController.text = med.name;
      _medCategoryController.text = med.category;
      _medDosageController.text = med.defaultDosage;
      _medDurationController.text = med.defaultDuration;
      _medInstructionsController.text = med.defaultInstructions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeQueue = widget.store.getActiveQueue();
    final historyQueue = widget.store.getHistoricalQueue();
    final allAppointments = widget.store.appointments;
    final todayAppts = widget.store.getTodayAppointments();

    final pendingAppts = allAppointments.where((a) => a.status == AppointmentStatus.pending).toList();
    final approvedAppts = allAppointments.where((a) => a.status == AppointmentStatus.approved).toList();
    final waitingQueue = activeQueue.where((item) => item.status == QueueStatus.waiting).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final views = [
          _buildAppointmentsTab(pendingAppts, approvedAppts, todayAppts),
          _buildQueueManagerTab(activeQueue, historyQueue, waitingQueue, isDesktop),
          _buildRegistrationTab(isDesktop),
          _buildMedicineInventoryTab(isDesktop),
        ];

        if (widget.activeIndex < 0 || widget.activeIndex >= views.length) {
          return const Center(child: Text('Desk Section Coming Soon!'));
        }

        return views[widget.activeIndex];
      },
    );
  }

  // --- TAB 1: Appointments Workspace ---
  Widget _buildAppointmentsTab(List<Appointment> pending, List<Appointment> approved, List<Appointment> today) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMetricSummaryCard('Pending Approvals', pending.length.toString(), Colors.orange),
              const SizedBox(width: 12),
              _buildMetricSummaryCard('Approved Slots', approved.length.toString(), Colors.green),
              const SizedBox(width: 12),
              _buildMetricSummaryCard('Today\'s Schedule', today.length.toString(), Colors.teal),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Pending Appointment Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
            child: pending.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No pending appointment requests.', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pending.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final app = pending[idx];
                      return ListTile(
                        title: Text(app.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Consultant: ${app.doctorName} | Date: ${DateFormat('dd-MM-yyyy').format(app.dateTime)} | Time: ${app.time}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                widget.store.updateAppointmentStatus(app.id, AppointmentStatus.approved);
                                // Auto checkin patient to queue list
                                final p = widget.store.getPatientsByMobile(app.patientMobile).firstWhere((pat) => pat.name == app.patientName);
                                widget.store.addToQueue(p.id);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment approved & token generated for ${app.patientName}!')));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, elevation: 0),
                              child: const Text('Accept'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                widget.store.updateAppointmentStatus(app.id, AppointmentStatus.rejected);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment rejected for ${app.patientName}.')));
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Queue Reordering Manager ---
  Widget _buildQueueManagerTab(List<QueueItem> active, List<QueueItem> history, List<QueueItem> waiting, bool isDesktop) {
    final listContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manage Live Queue Positions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        const Text('Drag and drop rows or use action buttons to adjust position priorities. Tokens renumber automatically.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 12),
        Container(
          height: 450,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
          child: active.isEmpty
              ? const Center(child: Text('No active patients in clinic today.', style: TextStyle(color: Colors.grey)))
              : ReorderableListView.builder(
                  buildDefaultDragHandles: true,
                  itemCount: active.length,
                  onReorder: (oldIdx, newIdx) {
                    widget.store.reorderQueue(oldIdx, newIdx);
                  },
                  itemBuilder: (context, idx) {
                    final item = active[idx];
                    final patient = widget.store.getPatientById(item.patientId);
                    if (patient == null) return SizedBox(key: ValueKey(item.id));
                    final bool isServ = item.status == QueueStatus.serving;
                    return ListTile(
                      key: ValueKey(item.id),
                      leading: CircleAvatar(
                        backgroundColor: isServ ? Colors.teal : Colors.blue,
                        child: Text('#${item.queueNumber}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Mobile: ${patient.mobileNumber} | Status: ${item.status.name.toUpperCase()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (idx > 0)
                            IconButton(
                              icon: const Icon(Icons.arrow_upward, size: 18, color: Colors.blue),
                              onPressed: () => widget.store.reorderQueue(idx, idx - 1),
                            ),
                          if (idx < active.length - 1)
                            IconButton(
                              icon: const Icon(Icons.arrow_downward, size: 18, color: Colors.blue),
                              onPressed: () => widget.store.reorderQueue(idx, idx + 2),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                            onPressed: () {
                              widget.store.updateQueueItemStatus(item.id, QueueStatus.skipped);
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );

    final statsPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Completed / Skipped today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        Container(
          height: 450,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
          child: history.isEmpty
              ? const Center(child: Text('No history logs yet.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = history.reversed.toList()[idx];
                    final patient = widget.store.getPatientById(item.patientId);
                    if (patient == null) return const SizedBox.shrink();
                    final isDone = item.status == QueueStatus.done;
                    return ListTile(
                      title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('#${item.queueNumber} • ${isDone ? 'Completed' : 'Skipped'}'),
                      trailing: ElevatedButton.icon(
                        onPressed: () {
                          widget.store.addToQueue(patient.id);
                        },
                        icon: const Icon(Icons.replay, size: 10),
                        label: const Text('Re-add', style: TextStyle(fontSize: 10)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 12, child: listContent),
                const SizedBox(width: 24),
                Expanded(flex: 8, child: statsPanel),
              ],
            )
          : Column(
              children: [
                listContent,
                const SizedBox(height: 24),
                statsPanel,
              ],
            ),
    );
  }

  // --- TAB 3: Patient Registration with suggestions and auto-fill ---
  Widget _buildRegistrationTab(bool isDesktop) {
    final formColumn = Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Patient Registration Form', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F766E))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isExistingPatient ? Colors.teal.shade50 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_isExistingPatient ? 'Existing Family Profile' : 'New Profile', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isExistingPatient ? Colors.teal.shade800 : Colors.blue.shade800)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Name Field (Type-ahead suggestions trigger)
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                ),
                
                // Show Type-Ahead Suggestions Panel
                if (_nameSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(color: Colors.teal.shade50.withOpacity(0.3), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.shade100)),
                    child: ListView(
                      shrinkWrap: true,
                      children: _nameSuggestions.map((p) {
                        return ListTile(
                          dense: true,
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Mobile: ${p.mobileNumber} | Age: ${p.age} | ${p.gender}'),
                          trailing: const Text('Autofill', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                          onTap: () => _autofillPatientDetails(p),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Mobile Number
                TextFormField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Mobile is required' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGender = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // DOB Picker
                InkWell(
                  onTap: () => _selectDob(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDob == null
                              ? 'Select Date of Birth'
                              : 'DOB: ${DateFormat('yyyy-MM-dd').format(_selectedDob!)}',
                          style: TextStyle(color: _selectedDob == null ? Colors.grey.shade600 : Colors.black),
                        ),
                        const Icon(Icons.cake, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    prefixIcon: const Icon(Icons.home),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Address required' : null,
                ),
                const SizedBox(height: 12),

                // Emergency Contact
                TextFormField(
                  controller: _emergencyContactController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact',
                    prefixIcon: const Icon(Icons.contact_phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Emergency number required' : null,
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearRegistrationFields,
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => _registerAndOrAddToQueue(andQueue: true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Register & Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _registerAndOrAddToQueue(andQueue: false),
                    child: const Text('Just Register Patient (No Queue)'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );

    final helperColumn = Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Quick Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E))),
            SizedBox(height: 12),
            Text('1. Start typing a name in the "Full Name" input box.', style: TextStyle(fontSize: 12, height: 1.4)),
            SizedBox(height: 6),
            Text('2. If they are a registered patient or a family member, they will show up in the type-ahead suggestion window.', style: TextStyle(fontSize: 12, height: 1.4)),
            SizedBox(height: 6),
            Text('3. Tap "Autofill" to populate their fields immediately. This allows you to easily register family members under the same mobile number.', style: TextStyle(fontSize: 12, height: 1.4)),
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
                Expanded(flex: 11, child: formColumn),
                const SizedBox(width: 24),
                Expanded(flex: 9, child: helperColumn),
              ],
            )
          : Column(
              children: [
                formColumn,
                const SizedBox(height: 16),
                helperColumn,
              ],
            ),
    );
  }

  // --- TAB 4: Medicine Master Inventory Management ---
  Widget _buildMedicineInventoryTab(bool isDesktop) {
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
              _editingMedName == null ? 'Add New Medicine Preset' : 'Edit Medicine Preset',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _medNameController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _medCategoryController.text,
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
                if (val != null) setState(() => _medCategoryController.text = val);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _medDosageController,
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
                    controller: _medDurationController,
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
              controller: _medInstructionsController,
              decoration: InputDecoration(
                labelText: 'Default Instructions',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_editingMedName != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearMedicineForm,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveMedicineItem,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
                    child: Text(_editingMedName == null ? 'Add Medicine' : 'Save Changes'),
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
            Text('Medicine Inventory Master (${list.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                    subtitle: Text('Cat: ${med.category} | Dosage: ${med.defaultDosage} | Instructions: ${med.defaultInstructions}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                          onPressed: () => _editMedicine(med),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () {
                            widget.store.deleteMasterMedicine(med.name);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine deleted from master list.')));
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

  // --- Helpers ---
  Widget _buildMetricSummaryCard(String title, String value, Color color) {
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
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
