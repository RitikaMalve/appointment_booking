import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/medical_record.dart';
import '../models/appointment.dart';
import '../services/clinic_store.dart';

class PatientView extends StatefulWidget {
  final ClinicStore store;
  final int activeIndex;
  final ValueChanged<int> onTabChanged;

  const PatientView({
    super.key, 
    required this.store,
    required this.activeIndex,
    required this.onTabChanged,
  });

  @override
  State<PatientView> createState() => _PatientViewState();
}

class _PatientViewState extends State<PatientView> {
  final _mobileController = TextEditingController();
  
  // Active Profile State
  Patient? _loggedInPrimaryPatient;
  Patient? _selectedProfile;
  List<Patient> _familyProfiles = [];
  bool _searched = false;

  // Appointment Form Controllers
  final _docNameController = TextEditingController(text: 'Dr. Amit Verma');
  DateTime? _apptDate;
  String _apptTime = '10:00 AM';

  // Mock Health stats that the user can update in a dialog
  String _bp = '120/80';
  int _hr = 72;
  int _sugar = 95;
  double _weight = 145;

  @override
  void dispose() {
    _mobileController.dispose();
    _docNameController.dispose();
    super.dispose();
  }

  void _searchPatient() {
    final query = _mobileController.text.trim();
    if (query.isEmpty) return;

    final profiles = widget.store.getPatientsByMobile(query);
    setState(() {
      _searched = true;
      if (profiles.isNotEmpty) {
        _familyProfiles = profiles;
        _loggedInPrimaryPatient = profiles.first;
        _selectedProfile = profiles.first;
      } else {
        _familyProfiles = [];
        _loggedInPrimaryPatient = null;
        _selectedProfile = null;
      }
    });
  }

  void _logout() {
    setState(() {
      _loggedInPrimaryPatient = null;
      _selectedProfile = null;
      _familyProfiles = [];
      _searched = false;
      _mobileController.clear();
    });
  }

  void _switchProfile(Patient newProfile) {
    setState(() {
      _selectedProfile = newProfile;
    });
  }

  void _joinQueue() {
    if (_selectedProfile == null) return;
    widget.store.addToQueue(_selectedProfile!.id).then((success) {
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedProfile!.name} successfully joined the queue!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are already in the queue.')),
        );
      }
      setState(() {});
    });
  }

  void _bookAppointment() {
    if (_selectedProfile == null) return;
    if (_apptDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a Date for the appointment.')),
      );
      return;
    }

    final newApp = Appointment(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      patientMobile: _selectedProfile!.mobileNumber,
      patientName: _selectedProfile!.name,
      doctorName: _docNameController.text.trim(),
      dateTime: _apptDate!,
      time: _apptTime,
      status: AppointmentStatus.pending,
    );

    widget.store.bookAppointment(newApp).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment requested for ${_selectedProfile!.name}! Pending approval.')),
      );
      setState(() {
        _apptDate = null;
      });
    });
  }

  void _showEditHealthStatsDialog() {
    final bpCtrl = TextEditingController(text: _bp);
    final hrCtrl = TextEditingController(text: _hr.toString());
    final sugarCtrl = TextEditingController(text: _sugar.toString());
    final weightCtrl = TextEditingController(text: _weight.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Daily Health Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bpCtrl, decoration: const InputDecoration(labelText: 'Blood Pressure (mmHg)')),
            TextField(controller: hrCtrl, decoration: const InputDecoration(labelText: 'Heart Rate (bpm)')),
            TextField(controller: sugarCtrl, decoration: const InputDecoration(labelText: 'Blood Sugar (mg/dL)')),
            TextField(controller: weightCtrl, decoration: const InputDecoration(labelText: 'Weight (lbs)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _bp = bpCtrl.text.trim();
                _hr = int.tryParse(hrCtrl.text) ?? _hr;
                _sugar = int.tryParse(sugarCtrl.text) ?? _sugar;
                _weight = double.tryParse(weightCtrl.text) ?? _weight;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If patient details are queried from global dashboard, link local state
    if (widget.store.isInitialized && _searched && _loggedInPrimaryPatient != null) {
      // Refresh profiles list dynamically
      _familyProfiles = widget.store.getPatientsByMobile(_loggedInPrimaryPatient!.mobileNumber);
      if (!_familyProfiles.any((p) => p.id == _selectedProfile?.id)) {
        _selectedProfile = _familyProfiles.first;
      } else {
        _selectedProfile = _familyProfiles.firstWhere((p) => p.id == _selectedProfile?.id);
      }
    }

    if (_selectedProfile == null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const Icon(Icons.healing, size: 48, color: Color(0xFF0D9488)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'CareFlow Patient Portal',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your registered mobile number to check queue position, book appointments, and print prescriptions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Registered Mobile Number',
                        prefixIcon: const Icon(Icons.phone, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'e.g. 9876543210',
                      ),
                      onSubmitted: (_) => _searchPatient(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _searchPatient,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Access Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_searched && _loggedInPrimaryPatient == null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Text(
                          'No records found. Please ask the receptionist to register your mobile number first.',
                          style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final patient = _selectedProfile!;
    final queueInfo = widget.store.getPatientQueueInfo(patient.id);
    final bool inQueue = queueInfo['inQueue'] as bool;
    final int patientsAhead = queueInfo['patientsAhead'] as int;
    final int queueNumber = queueInfo['queueNumber'] as int;
    final bool isNear = queueInfo['isNear'] as bool;
    final bool isServing = queueInfo['isServing'] == true;

    final records = widget.store.getPatientRecords(patient.id);
    final appointments = widget.store.getAppointmentsByMobile(patient.mobileNumber);
    final approvedAppts = appointments.where((a) => a.status == AppointmentStatus.approved).toList();

    if (widget.activeIndex == 0) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 950;

          // Left Panel contents
          final leftSection = [
            // 1. Welcome Card
            _buildWelcomeCard(patient),
            const SizedBox(height: 20),

            // 2. Metrics Summary Cards Row
            _buildMetricsSummaryRow(approvedAppts, records, inQueue, queueNumber),
            const SizedBox(height: 24),

            // 3. Explore Departments Cards Grid
            _buildExploreDepartments(),
            const SizedBox(height: 24),

            // 4. Recent Consultations (Prescriptions) Table
            _buildRecentConsultationsTable(records),
          ];

          // Right Panel contents
          final rightSection = [
            // 1. Family Profiles Switcher Card
            _buildFamilySwitcherCard(patient),
            const SizedBox(height: 20),

            // 2. Queue Tracker Stepper Card
            _buildQueueTrackerCard(inQueue, queueNumber, patientsAhead, isServing, isNear),
            const SizedBox(height: 20),

            // 3. Health Stats Summary Cards (BP, HR, Sugar, Weight)
            _buildHealthStatsWidget(),
            const SizedBox(height: 20),

            // 4. Book New Appointment Form Card
            _buildBookAppointmentCard(),
          ];

          if (isDesktop) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 13,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: leftSection,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: rightSection,
                    ),
                  ),
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...leftSection,
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  ...rightSection,
                ],
              ),
            );
          }
        },
      );
    } else {
      Widget activeWidget;
      switch (widget.activeIndex) {
        case 1:
          activeWidget = _buildBookAppointmentCard();
          break;
        case 2:
          activeWidget = _buildQueueTrackerCard(inQueue, queueNumber, patientsAhead, isServing, isNear);
          break;
        case 3:
          activeWidget = _buildRecentConsultationsTable(records);
          break;
        case 4:
          activeWidget = _buildFamilySwitcherCard(patient);
          break;
        case 5:
          activeWidget = _buildHealthStatsWidget();
          break;
        default:
          activeWidget = const Center(child: Text("Portal Section Coming Soon!"));
      }

      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildWelcomeCard(patient),
              const SizedBox(height: 20),
              activeWidget,
            ],
          ),
        ),
      );
    }
  }

  // --- UI Components ---

  Widget _buildWelcomeCard(Patient patient) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
            child: Text(
              patient.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${patient.name}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here\'s an overview of your medical records and appointments. Portal ID: ${patient.id}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 14),
            label: const Text('Exit Portal', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSummaryRow(List<Appointment> appts, List<MedicalRecord> records, bool inQueue, int queueNumber) {
    final nextAppt = appts.isNotEmpty ? DateFormat('dd MMM').format(appts.first.dateTime) : 'None';
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool tight = width < 450;
        return GridView.count(
          crossAxisCount: tight ? 2 : 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: tight ? 1.6 : 2.2,
          children: [
            _buildMetricCard('Approved Appts', appts.length.toString().padLeft(2, '0'), 'Next: $nextAppt', Icons.calendar_month_outlined, Colors.green),
            _buildMetricCard('Total Consults', records.length.toString().padLeft(2, '0'), 'History logs', Icons.medical_services_outlined, Colors.teal),
            _buildMetricCard('Queue Ticket', inQueue ? '#$queueNumber' : 'None', inQueue ? 'Active today' : 'Inactive', Icons.assignment_ind_outlined, Colors.blue),
            _buildMetricCard('Active Presc.', records.isNotEmpty ? '01' : '00', 'Need Refills', Icons.receipt_long_outlined, Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String val, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Text(subtitle, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExploreDepartments() {
    final depts = [
      {'name': 'Cardiologist', 'icon': Icons.favorite_border, 'color': Colors.red},
      {'name': 'Dentist', 'icon': Icons.tag_faces, 'color': Colors.blue},
      {'name': 'Urologist', 'icon': Icons.opacity, 'color': Colors.orange},
      {'name': 'Neurologist', 'icon': Icons.psychology, 'color': Colors.purple},
      {'name': 'Psychologist', 'icon': Icons.chat_bubble_outline, 'color': Colors.teal},
      {'name': 'Orthopedic', 'icon': Icons.accessibility_new, 'color': Colors.amber},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Explore Departments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Color(0xFF0D9488), fontSize: 13))),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: depts.map((d) {
              final color = d['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Icon(d['icon'] as IconData, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentConsultationsTable(List<MedicalRecord> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Consultations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Color(0xFF0D9488), fontSize: 13))),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: records.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('No previous medical records found.', style: TextStyle(color: Colors.grey))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 32,
                    columns: const [
                      DataColumn(label: Text('Doctor', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Diagnosis', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: records.map((rec) {
                      return DataRow(
                        cells: [
                          const DataCell(Text('Dr. Amit Verma', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(rec.diagnosis)),
                          DataCell(Text(DateFormat('dd MMM yyyy').format(rec.date))),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                            child: Text('Completed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          )),
                          DataCell(IconButton(
                            icon: const Icon(Icons.print_outlined, color: Colors.blue, size: 20),
                            onPressed: () => _showPrescriptionDialog(context, rec),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        )
      ],
    );
  }

  Widget _buildFamilySwitcherCard(Patient activeProfile) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people_outline, color: Color(0xFF0D9488), size: 18),
                SizedBox(width: 8),
                Text('Family Member Profiles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            if (_familyProfiles.length <= 1)
              const Text(
                'Only one profile registered. The receptionist can register family members under this phone number.',
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
              )
            else
              Column(
                children: _familyProfiles.map((prof) {
                  final isSel = prof.id == activeProfile.id;
                  return InkWell(
                    onTap: () => _switchProfile(prof),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF0D9488).withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? const Color(0xFF0D9488).withOpacity(0.3) : Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: isSel ? const Color(0xFF0D9488) : Colors.grey.shade300,
                            child: Text(
                              prof.name.substring(0,1).toUpperCase(),
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              prof.name,
                              style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 13),
                            ),
                          ),
                          if (isSel)
                            const Icon(Icons.check_circle_outline, color: Color(0xFF0D9488), size: 16),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTrackerCard(bool inQueue, int queueNumber, int patientsAhead, bool isServing, bool isNear) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isServing 
              ? Colors.teal.shade300 
              : (isNear ? Colors.orange.shade300 : Colors.grey.shade100),
          width: isServing || isNear ? 2.0 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Queue Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            if (!inQueue) ...[
              const Text('You are not currently checked into the queue list for today.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _joinQueue,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Profile to Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              )
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isServing ? Colors.teal : (isNear ? Colors.orange : Colors.blue),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('#$queueNumber', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isServing 
                              ? 'Your Turn Now!' 
                              : (isNear ? 'Visit Cabin Next' : 'In Waiting Queue'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          isServing 
                              ? 'Please enter the doctor\'s consultation room.' 
                              : 'Patients ahead: $patientsAhead (${patientsAhead * 15} mins wait)',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatsWidget() {
    return Card(
      elevation: 1,
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
                const Text('Health Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0D9488)),
                  onPressed: _showEditHealthStatsDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              children: [
                _buildHealthStatCard('Blood Pressure', '$_bp mmHg', 'Normal', Colors.red, Colors.green),
                _buildHealthStatCard('Heart Rate', '$_hr bpm', 'Normal', Colors.blue, Colors.blue),
                _buildHealthStatCard('Blood Sugar', '$_sugar mg/dL', 'Normal', Colors.green, Colors.green),
                _buildHealthStatCard('Weight', '$_weight lbs', 'Normal', Colors.purple, Colors.purple),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHealthStatCard(String title, String value, String desc, Color iconColor, Color descColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Text(desc, style: TextStyle(fontSize: 9, color: descColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBookAppointmentCard() {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey.shade100)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _docNameController.text,
              decoration: InputDecoration(
                labelText: 'Choose Consultant',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: 'Dr. Amit Verma', child: Text('Dr. Amit Verma (Consultant)')),
                DropdownMenuItem(value: 'Dr. Emily Roberts', child: Text('Dr. Emily Roberts (Pediatrician)')),
                DropdownMenuItem(value: 'Dr. Samuel O\'Connor', child: Text('Dr. Samuel O\'Connor (Orthopedic)')),
              ],
              onChanged: (val) {
                if (val != null) _docNameController.text = val;
              },
            ),
            const SizedBox(height: 10),
            // Date Picker trigger
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    _apptDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _apptDate == null
                          ? 'Select Appointment Date'
                          : 'Date: ${DateFormat('dd-MM-yyyy').format(_apptDate!)}',
                      style: TextStyle(color: _apptDate == null ? Colors.grey.shade600 : Colors.black, fontSize: 14),
                    ),
                    const Icon(Icons.calendar_today, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _apptTime,
              decoration: InputDecoration(
                labelText: 'Select Preferred Slot',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: const [
                DropdownMenuItem(value: '10:00 AM', child: Text('10:00 AM - 10:15 AM')),
                DropdownMenuItem(value: '11:30 AM', child: Text('11:30 AM - 11:45 AM')),
                DropdownMenuItem(value: '02:00 PM', child: Text('02:00 PM - 02:15 PM')),
                DropdownMenuItem(value: '04:15 PM', child: Text('04:15 PM - 04:30 PM')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _apptTime = val;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Request Slot', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showPrescriptionDialog(BuildContext context, MedicalRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'assets/logo.jpg',
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                              errorBuilder: (c, o, s) => const Icon(Icons.healing, color: Color(0xFF0D9488), size: 28),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'CLINIC PRESCRIPTION',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Patient Name:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(_selectedProfile!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Date:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(DateFormat('dd-MM-yyyy').format(record.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mobile:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(record.patientId.split('_').first, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Prescription ID:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(record.id.toUpperCase(), style: const TextStyle(fontFamily: 'Courier', fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    'Rx',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    'Diagnosis: ${record.diagnosis}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(4),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(2),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black26))),
                        children: [
                          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Duration', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      ...record.medicines.map((m) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(m.instructions, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(m.dosage)),
                          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(m.duration)),
                        ],
                      )),
                    ],
                  ),
                  if (record.tests.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Prescribed Tests:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: record.tests.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.teal.shade100)),
                        child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF0F766E))),
                      )).toList(),
                    ),
                  ],
                  if (record.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Advice / Special Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text(record.notes, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Thank you for visiting. Take care!',
                      style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
