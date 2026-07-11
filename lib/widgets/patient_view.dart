import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../models/medical_record.dart';
import '../services/clinic_store.dart';

class PatientView extends StatefulWidget {
  final ClinicStore store;

  const PatientView({super.key, required this.store});

  @override
  State<PatientView> createState() => _PatientViewState();
}

class _PatientViewState extends State<PatientView> {
  final _mobileController = TextEditingController();
  Patient? _loggedInPatient;
  bool _searched = false;

  void _searchPatient() {
    final query = _mobileController.text.trim();
    if (query.isEmpty) return;

    final patient = widget.store.getPatientByMobile(query);
    setState(() {
      _loggedInPatient = patient;
      _searched = true;
    });
  }

  void _logout() {
    setState(() {
      _loggedInPatient = null;
      _searched = false;
      _mobileController.clear();
    });
  }

  void _joinQueue() {
    if (_loggedInPatient == null) return;
    widget.store.addToQueue(_loggedInPatient!.mobileNumber).then((success) {
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the queue!')),
        );
        setState(() {}); // refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are already in the queue.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedInPatient == null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.healing,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Patient Portal',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your registered mobile number to check your queue status and view prescriptions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Registered Mobile Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'e.g. 9988776655',
                      ),
                      onSubmitted: (_) => _searchPatient(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _searchPatient,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Access Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    if (_searched && _loggedInPatient == null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Text(
                          'No patient found with this number. Please register at the receptionist desk first.',
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

    final patient = _loggedInPatient!;
    final queueInfo = widget.store.getPatientQueueInfo(patient.mobileNumber);
    final bool inQueue = queueInfo['inQueue'] as bool;
    final int patientsAhead = queueInfo['patientsAhead'] as int;
    final int queueNumber = queueInfo['queueNumber'] as int;
    final bool isNear = queueInfo['isNear'] as bool;
    final bool isServing = queueInfo['isServing'] == true;

    final records = widget.store.getPatientRecords(patient.mobileNumber);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Patient Profile Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      patient.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${patient.gender} • ${patient.age} years • Phone: ${patient.mobileNumber}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.exit_to_app, size: 16),
                    label: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Queue Status Section
          Text('Your Queue Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildQueueStatusCard(
            context,
            inQueue: inQueue,
            queueNumber: queueNumber,
            patientsAhead: patientsAhead,
            isNear: isNear,
            isServing: isServing,
            onJoinQueue: _joinQueue,
          ),
          const SizedBox(height: 24),

          // Prescription History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Prescription History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (records.isNotEmpty)
                Text(
                  '${records.length} Record(s)',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPrescriptionsList(records),
        ],
      ),
    );
  }

  Widget _buildQueueStatusCard(
    BuildContext context, {
    required bool inQueue,
    required int queueNumber,
    required int patientsAhead,
    required bool isNear,
    required bool isServing,
    required VoidCallback onJoinQueue,
  }) {
    if (!inQueue) {
      return Card(
        color: Colors.blue.shade50.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'You are not in the queue right now.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'If you are visiting the clinic today, you can check-in to request a queue spot immediately.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onJoinQueue,
                icon: const Icon(Icons.add),
                label: const Text('Check-in / Add to Queue', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    Color cardBgColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    Widget statusIndicator;
    String statusTitle;
    String statusDesc;

    if (isServing) {
      cardBgColor = Colors.teal.shade50.withOpacity(0.3);
      borderColor = Colors.teal.shade300;
      statusTitle = "It's Your Turn!";
      statusDesc = "Please proceed to the Doctor's cabin for consultation.";
      statusIndicator = _buildPulsingIndicator(Colors.teal, 'ACTIVE');
    } else if (isNear) {
      cardBgColor = Colors.orange.shade50.withOpacity(0.3);
      borderColor = Colors.orange.shade400;
      statusTitle = "Get Ready!";
      statusDesc = "Your turn is coming up next. Please wait near the cabin.";
      statusIndicator = _buildPulsingIndicator(Colors.orange, 'NEAR VISIT');
    } else {
      statusTitle = "In Queue";
      statusDesc = "Estimated wait time is around ${patientsAhead * 15} minutes.";
      statusIndicator = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'WAITING',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 2.0),
      ),
      color: cardBgColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Queue circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isServing 
                    ? Colors.teal 
                    : (isNear ? Colors.orange : Colors.blue),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('TOKEN', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(
                      '#$queueNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 24),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),

            // Middle status info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      statusIndicator,
                      const SizedBox(width: 8),
                      Text(
                        'Position: ${patientsAhead + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusDesc,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  if (!isServing) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Patients ahead of you: $patientsAhead',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingIndicator(Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList(List<MedicalRecord> records) {
    if (records.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history_edu_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('No prescriptions found yet.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, idx) {
        final rec = records[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rec.diagnosis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy • hh:mm a').format(rec.date),
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showPrescriptionDialog(context, rec),
                      icon: const Icon(Icons.print_outlined, size: 16),
                      label: const Text('View/Print'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (rec.notes.isNotEmpty) ...[
                  const Text('Doctor\'s Advice:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                  Text(rec.notes, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 12),
                ],
                const Text('Medicines:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 6),
                ...rec.medicines.map((med) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        children: [
                          Icon(Icons.medication, color: Theme.of(context).colorScheme.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: '${med.name} ',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: '(${med.dosage}) - ${med.duration}',
                                    style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
                                  ),
                                  TextSpan(
                                    text: ' | Instructions: ${med.instructions}',
                                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
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
                  // Logo/Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.healing, color: Theme.of(context).colorScheme.primary, size: 28),
                          const SizedBox(width: 8),
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
                  
                  // Metadata
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Patient Name:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(_loggedInPatient!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                          Text(record.patientMobile, style: const TextStyle(fontWeight: FontWeight.bold)),
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

                  // Rx Symbol
                  Text(
                    'Rx',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  // Diagnosis
                  Text(
                    'Diagnosis: ${record.diagnosis}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),

                  // Table of Medicines
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
                  
                  if (record.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Advice / Special Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
