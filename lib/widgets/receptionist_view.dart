import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/queue_item.dart';
import '../services/clinic_store.dart';

class ReceptionistView extends StatefulWidget {
  final ClinicStore store;

  const ReceptionistView({super.key, required this.store});

  @override
  State<ReceptionistView> createState() => _ReceptionistViewState();
}

class _ReceptionistViewState extends State<ReceptionistView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  final _mobileController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  DateTime? _selectedDob;
  String _selectedGender = 'Male';
  bool _isExistingPatient = false;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileChanged);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mobileController.removeListener(_onMobileChanged);
    _mobileController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  // Real-time lookup of mobile number to see if patient is new or existing
  void _onMobileChanged() {
    final query = _mobileController.text.trim();
    if (query.length >= 10) {
      final existing = widget.store.getPatientByMobile(query);
      if (existing != null) {
        if (!_isExistingPatient) {
          setState(() {
            _isExistingPatient = true;
            _nameController.text = existing.name;
            _ageController.text = existing.age.toString();
            _addressController.text = existing.address;
            _emergencyContactController.text = existing.emergencyContact;
            _selectedDob = existing.dateOfBirth;
            _selectedGender = existing.gender;
          });
        }
      } else {
        if (_isExistingPatient) {
          setState(() {
            _isExistingPatient = false;
            _clearRegistrationFields(keepMobile: true);
          });
        }
      }
    } else {
      if (_isExistingPatient) {
        setState(() {
          _isExistingPatient = false;
          _clearRegistrationFields(keepMobile: true);
        });
      }
    }
  }

  void _clearRegistrationFields({bool keepMobile = false}) {
    if (!keepMobile) {
      _mobileController.clear();
    }
    _nameController.clear();
    _ageController.clear();
    _addressController.clear();
    _emergencyContactController.clear();
    setState(() {
      _selectedDob = null;
      _selectedGender = 'Male';
      _isExistingPatient = false;
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
        // Auto-calculate age
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

    final patient = Patient(
      mobileNumber: mobile,
      name: name,
      age: age,
      address: address,
      dateOfBirth: _selectedDob!,
      gender: _selectedGender,
      emergencyContact: emergency,
      registeredAt: _isExistingPatient 
          ? (widget.store.getPatientByMobile(mobile)?.registeredAt ?? DateTime.now())
          : DateTime.now(),
    );

    // Save/Update in store
    widget.store.registerPatient(patient);

    if (andQueue) {
      widget.store.addToQueue(mobile).then((success) {
        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name added to the queue list!')),
          );
          _clearRegistrationFields();
          final isDesktop = MediaQuery.of(context).size.width >= 850;
          if (!isDesktop) {
            _tabController.animateTo(1);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$name is already active in the queue.')),
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

  @override
  Widget build(BuildContext context) {
    final activeQueue = widget.store.getActiveQueue();
    final historyQueue = widget.store.getHistoricalQueue();

    // Stats
    final totalWaiting = activeQueue.where((item) => item.status == QueueStatus.waiting).length;
    final currentlyServing = activeQueue.where((item) => item.status == QueueStatus.serving).length;
    final completedCount = historyQueue.where((item) => item.status == QueueStatus.done).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        
        final registrationForm = Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        Text(
                          'Patient Registration',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        // Registration status badge
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isExistingPatient 
                                ? Colors.teal.shade50 
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isExistingPatient 
                                  ? Colors.teal.shade300 
                                  : Colors.blue.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isExistingPatient ? Icons.check_circle : Icons.person_add,
                                size: 16,
                                color: _isExistingPatient ? Colors.teal.shade800 : Colors.blue.shade800,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isExistingPatient ? 'Existing Patient' : 'New Patient',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _isExistingPatient ? Colors.teal.shade800 : Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Mobile Number Field
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Enter 10-digit number',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Mobile is required';
                        if (value.length < 10) return 'Enter a valid mobile number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // Age Field
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Age',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Required';
                              if (int.tryParse(value) == null) return 'Must be number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Gender Dropdown
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: const Icon(Icons.wc),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    const SizedBox(height: 16),

                    // Date of Birth Field (with date picker)
                    InkWell(
                      onTap: () => _selectDob(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cake, color: Colors.grey),
                                const SizedBox(width: 10),
                                Text(
                                  _selectedDob == null
                                      ? 'Select Date of Birth'
                                      : 'DOB: ${DateFormat('yyyy-MM-dd').format(_selectedDob!)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDob == null ? Colors.grey.shade600 : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(Icons.home),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Address is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contact
                    TextFormField(
                      controller: _emergencyContactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Emergency Contact Number',
                        prefixIcon: const Icon(Icons.contact_phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Emergency contact is required';
                        if (value.length < 10) return 'Enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Form Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _clearRegistrationFields(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Clear'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => _registerAndOrAddToQueue(andQueue: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Register & Add to Q',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Only Register (Not Queued)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _registerAndOrAddToQueue(andQueue: false),
                        child: const Text('Just Register Patient (No Queue)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final queueDashboard = Column(
          children: [
            // Stats Row
            Row(
              children: [
                _buildStatCard(context, 'Waiting', '$totalWaiting Patients', Icons.hourglass_empty, Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard(context, 'In Consult', '$currentlyServing Patients', Icons.medical_services, Colors.teal),
                const SizedBox(width: 12),
                _buildStatCard(context, 'Completed', '$completedCount Today', Icons.check_circle, Colors.blue),
              ],
            ),
            const SizedBox(height: 16),

            // Active Queue & Completed List Tabs
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.queue),
                              SizedBox(width: 8),
                              Text('Active Queue'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history),
                              SizedBox(width: 8),
                              Text('Done & Skipped'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildActiveQueueList(activeQueue),
                          _buildHistoricalQueueList(historyQueue),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

        if (isDesktop) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(height: double.infinity, child: registrationForm),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: SizedBox(height: double.infinity, child: queueDashboard),
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
                    Tab(icon: Icon(Icons.person_add_alt_1_outlined), text: 'Registration'),
                    Tab(icon: Icon(Icons.dashboard_customize_outlined), text: 'Queue & Stats'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: registrationForm,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: queueDashboard,
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveQueueList(List<QueueItem> activeQueue) {
    if (activeQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No patients in the active queue', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: activeQueue.length,
      itemBuilder: (context, index) {
        final item = activeQueue[index];
        final patient = widget.store.getPatientByMobile(item.patientMobile);
        if (patient == null) return const SizedBox.shrink();

        final bool isServing = item.status == QueueStatus.serving;
        // The first "waiting" patient in queue is the next in line
        final waitingList = activeQueue.where((q) => q.status == QueueStatus.waiting).toList();
        final bool isNext = waitingList.isNotEmpty && waitingList.first.id == item.id;

        Color cardBorderColor = Colors.grey.shade200;
        Color cardBgColor = Colors.white;
        Widget? statusBadge;

        if (isServing) {
          cardBorderColor = Colors.teal.shade300;
          cardBgColor = Colors.teal.shade50.withOpacity(0.5);
          statusBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.medical_services, size: 12, color: Colors.teal.shade800),
                const SizedBox(width: 4),
                Text(
                  'IN VISIT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                ),
              ],
            ),
          );
        } else if (isNext) {
          cardBorderColor = Colors.orange.shade400;
          cardBgColor = Colors.orange.shade50.withOpacity(0.25);
          statusBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 12, color: Colors.orange.shade800),
                const SizedBox(width: 4),
                Text(
                  'NEXT IN LINE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                ),
              ],
            ),
          );
        }

        return Card(
          elevation: isServing || isNext ? 2 : 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cardBorderColor, width: isServing || isNext ? 2.0 : 1.0),
          ),
          color: cardBgColor,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Queue Number Circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isServing 
                        ? Colors.teal.shade500 
                        : (isNext ? Colors.orange.shade500 : Colors.blue.shade500),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${item.queueNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Patient Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              patient.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (statusBadge != null) ...[
                            const SizedBox(width: 8),
                            statusBadge,
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${patient.mobileNumber} • ${patient.gender}, ${patient.age}y',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Entry: ${DateFormat('hh:mm a').format(item.entryTime)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // Actions & Fees Paid status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Fees Paid Button
                    InkWell(
                      onTap: () => widget.store.toggleFeesPaid(item.id),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: item.isFeesPaid ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: item.isFeesPaid ? Colors.green.shade300 : Colors.red.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isFeesPaid ? Icons.check_circle_outline : Icons.highlight_off,
                              size: 14,
                              color: item.isFeesPaid ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.isFeesPaid ? 'Fees Paid' : 'Unpaid',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.isFeesPaid ? Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Action Popup
                    Row(
                      children: [
                        if (isNext || (!isServing && activeQueue.every((q) => q.status != QueueStatus.serving))) 
                          IconButton(
                            icon: const Icon(Icons.arrow_circle_right_outlined, color: Colors.teal),
                            tooltip: 'Send to Doctor',
                            onPressed: () {
                              widget.store.startConsultation(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${patient.name} sent to Doctor\'s cabin.')),
                              );
                            },
                          ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                          tooltip: 'Skip/Remove Patient',
                          onPressed: () {
                            widget.store.updateQueueItemStatus(item.id, QueueStatus.skipped);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${patient.name} skipped and removed from active queue.')),
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoricalQueueList(List<QueueItem> historyQueue) {
    if (historyQueue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No historical patients today', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: historyQueue.length,
      itemBuilder: (context, index) {
        // Show newest history first
        final item = historyQueue.reversed.toList()[index];
        final patient = widget.store.getPatientByMobile(item.patientMobile);
        if (patient == null) return const SizedBox.shrink();

        final bool isDone = item.status == QueueStatus.done;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isDone ? Colors.blue.shade100 : Colors.red.shade100,
                  child: Icon(
                    isDone ? Icons.check : Icons.close,
                    size: 18,
                    color: isDone ? Colors.blue.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '#${item.queueNumber} • ${patient.mobileNumber}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDone ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isDone ? 'Completed' : 'Skipped',
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Action: re-add to queue
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        widget.store.addToQueue(patient.mobileNumber).then((success) {
                          if (!mounted) return;
                          if (success) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('${patient.name} re-added to active queue!')),
                            );
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('${patient.name} is already in active queue.')),
                            );
                          }
                        });
                      },
                      icon: const Icon(Icons.replay, size: 12),
                      label: const Text('Re-add', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
