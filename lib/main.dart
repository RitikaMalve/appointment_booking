import 'package:flutter/material.dart';
import 'services/clinic_store.dart';
import 'widgets/receptionist_view.dart';
import 'widgets/doctor_view.dart';
import 'widgets/patient_view.dart';
import 'utils/mock_generator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClinicApp());
}

class ClinicApp extends StatelessWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareFlow Clinic Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488), // Medical Teal
          primary: const Color(0xFF0D9488),
          secondary: const Color(0xFF0F766E),
          surface: Colors.white,
          background: const Color(0xFFF1F5F9), // Soft slate background
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          iconTheme: IconThemeData(color: Color(0xFF1E293B)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        fontFamily: 'Roboto',
      ),
      home: const ClinicMainDashboard(),
    );
  }
}

class ClinicMainDashboard extends StatefulWidget {
  const ClinicMainDashboard({super.key});

  @override
  State<ClinicMainDashboard> createState() => _ClinicMainDashboardState();
}

class _ClinicMainDashboardState extends State<ClinicMainDashboard> {
  final ClinicStore _store = ClinicStore();
  
  // Login Gate State
  bool _isLoggedIn = false;
  String _currentRole = ''; // 'receptionist', 'doctor', 'patient'
  String _currentPatientMobile = ''; // For patient login state

  @override
  void initState() {
    super.initState();
    // Auto-seed mock data on startup if database is empty, so demo accounts are active
    _store.addListener(_onStoreInitialized);
  }

  void _onStoreInitialized() {
    if (_store.isInitialized) {
      _store.removeListener(_onStoreInitialized);
      if (_store.patients.isEmpty) {
        MockGenerator.seedData(_store);
      }
    }
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  void _login(String role, {String patientMobile = ''}) {
    setState(() {
      _isLoggedIn = true;
      _currentRole = role;
      _currentPatientMobile = patientMobile;
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _currentRole = '';
      _currentPatientMobile = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        if (!_store.isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0D9488)),
                  SizedBox(height: 16),
                  Text('Loading CareFlow database...', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
                ],
              ),
            ),
          );
        }

        if (!_isLoggedIn) {
          return Scaffold(
            body: ClinicLoginScreen(
              store: _store,
              onLoginSuccess: _login,
            ),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: _buildAppBar(),
          body: _buildCurrentView(),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    String roleTitle = '';
    IconData roleIcon = Icons.help;
    Color roleColor = Colors.grey;

    switch (_currentRole) {
      case 'receptionist':
        roleTitle = 'Reception Desk';
        roleIcon = Icons.assignment_ind;
        roleColor = Colors.blue;
        break;
      case 'doctor':
        roleTitle = 'Dr. Amit Verma (Consultant)';
        roleIcon = Icons.medical_services;
        roleColor = Colors.teal;
        break;
      case 'patient':
        final p = _store.getPatientByMobile(_currentPatientMobile);
        roleTitle = p != null ? 'Portal: ${p.name}' : 'Patient Portal';
        roleIcon = Icons.person;
        roleColor = Colors.indigo;
        break;
    }

    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(roleIcon, color: roleColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(roleTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        // Load demo data helper
        TextButton.icon(
          onPressed: () {
            MockGenerator.seedData(_store).then((_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo Clinic database loaded successfully!')),
              );
            });
          },
          icon: const Icon(Icons.rocket_launch, size: 14),
          label: const Text('Re-Load Demo Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF0D9488)),
        ),
        
        const VerticalDivider(width: 20, thickness: 1, indent: 12, endIndent: 12),

        // Log out button
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout, size: 14),
          label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade800,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_currentRole) {
      case 'receptionist':
        return ReceptionistView(store: _store);
      case 'doctor':
        return DoctorView(store: _store);
      case 'patient':
        // We override the PatientView login controller behavior inside the dashboard
        // By preloading the state with our logged-in patient number
        return PatientPortalWrapper(
          store: _store, 
          mobileNumber: _currentPatientMobile,
          onLogout: _logout,
        );
      default:
        return const Center(child: Text('Invalid View selected'));
    }
  }
}

// Wrapper to directly launch PatientView with pre-filled login state
class PatientPortalWrapper extends StatefulWidget {
  final ClinicStore store;
  final String mobileNumber;
  final VoidCallback onLogout;

  const PatientPortalWrapper({
    super.key, 
    required this.store, 
    required this.mobileNumber,
    required this.onLogout,
  });

  @override
  State<PatientPortalWrapper> createState() => _PatientPortalWrapperState();
}

class _PatientPortalWrapperState extends State<PatientPortalWrapper> {
  @override
  Widget build(BuildContext context) {
    // Return the PatientView, which will find the patient based on store querying
    // Since patient login state is managed globally, we show the view
    return PatientView(store: widget.store);
  }
}

// Spectacular visual login gate
class ClinicLoginScreen extends StatefulWidget {
  final ClinicStore store;
  final Function(String role, {String patientMobile}) onLoginSuccess;

  const ClinicLoginScreen({
    super.key, 
    required this.store,
    required this.onLoginSuccess,
  });

  @override
  State<ClinicLoginScreen> createState() => _ClinicLoginScreenState();
}

class _ClinicLoginScreenState extends State<ClinicLoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Login Form Controllers
  final _recepUserCtrl = TextEditingController();
  final _recepPassCtrl = TextEditingController();
  final _docUserCtrl = TextEditingController();
  final _docPassCtrl = TextEditingController();
  final _patientPhoneCtrl = TextEditingController();

  final _recepFormKey = GlobalKey<FormState>();
  final _docFormKey = GlobalKey<FormState>();
  final _patientFormKey = GlobalKey<FormState>();

  String? _recepError;
  String? _docError;
  String? _patientError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recepUserCtrl.dispose();
    _recepPassCtrl.dispose();
    _docUserCtrl.dispose();
    _docPassCtrl.dispose();
    _patientPhoneCtrl.dispose();
    super.dispose();
  }

  void _submitReceptionist() {
    setState(() {
      _recepError = null;
    });
    if (!_recepFormKey.currentState!.validate()) return;
    
    final username = _recepUserCtrl.text.trim();
    final password = _recepPassCtrl.text.trim();

    // Verify demo credentials
    if (username == 'clerk' && password == 'receptionist123') {
      widget.onLoginSuccess('receptionist');
    } else {
      setState(() {
        _recepError = 'Invalid clerk username or password.';
      });
    }
  }

  void _submitDoctor() {
    setState(() {
      _docError = null;
    });
    if (!_docFormKey.currentState!.validate()) return;

    final username = _docUserCtrl.text.trim();
    final password = _docPassCtrl.text.trim();

    // Verify demo credentials
    if (username == 'doctor' && password == 'doctor123') {
      widget.onLoginSuccess('doctor');
    } else {
      setState(() {
        _docError = 'Invalid doctor credentials.';
      });
    }
  }

  void _submitPatient() {
    setState(() {
      _patientError = null;
    });
    if (!_patientFormKey.currentState!.validate()) return;

    final phone = _patientPhoneCtrl.text.trim();
    final patient = widget.store.getPatientByMobile(phone);

    if (patient != null) {
      widget.onLoginSuccess('patient', patientMobile: phone);
    } else {
      setState(() {
        _patientError = 'Mobile number not registered. Please contact receptionist.';
      });
    }
  }

  void _quickConnect(String role, {String mobile = ''}) {
    if (role == 'receptionist') {
      _recepUserCtrl.text = 'clerk';
      _recepPassCtrl.text = 'receptionist123';
      _tabController.animateTo(0);
      _submitReceptionist();
    } else if (role == 'doctor') {
      _docUserCtrl.text = 'doctor';
      _docPassCtrl.text = 'doctor123';
      _tabController.animateTo(1);
      _submitDoctor();
    } else if (role == 'patient') {
      _patientPhoneCtrl.text = mobile;
      _tabController.animateTo(2);
      _submitPatient();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E), // Deep Teal
            Color(0xFF0D9488), // Slate Teal
            Color(0xFF1E3A8A), // Indigo Navy
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.healing, color: Color(0xFF0D9488), size: 36),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CareFlow',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                        ),
                        Text(
                          'Clinical Management Suite',
                          style: TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Main Login Card
                Card(
                  elevation: 12,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Text(
                          'Secure Portal Sign-In',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 24),
                        
                        // Tab Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            labelColor: const Color(0xFF0D9488),
                            unselectedLabelColor: Colors.grey,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Clerk'),
                              Tab(text: 'Doctor'),
                              Tab(text: 'Patient'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Switcher Area
                        SizedBox(
                          height: 220,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildReceptionistForm(),
                              _buildDoctorForm(),
                              _buildPatientForm(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Connect Seeding Area
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      const Text(
                        '⚡ DEMO QUICK CONNECT',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildQuickCard('Recep Desk', 'Clerk Portal', Icons.assignment_ind, Colors.blue, () => _quickConnect('receptionist')),
                          _buildQuickCard('Dr. Verma', 'Doctor Cabin', Icons.medical_services, Colors.teal, () => _quickConnect('doctor')),
                          _buildQuickCard('Priya (Q#103)', 'Patient view', Icons.person, Colors.orange, () => _quickConnect('patient', mobile: '9988776655')),
                          _buildQuickCard('Ananya (Q#104)', 'Patient view', Icons.person, Colors.indigo, () => _quickConnect('patient', mobile: '9345678901')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 135,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 16,
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceptionistForm() {
    return Form(
      key: _recepFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _recepUserCtrl,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'clerk',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            validator: (v) => v == null || v.isEmpty ? 'Username required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _recepPassCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'receptionist123',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
          ),
          if (_recepError != null) ...[
            const SizedBox(height: 8),
            Text(_recepError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReceptionist,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Login as Clerk', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorForm() {
    return Form(
      key: _docFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _docUserCtrl,
            decoration: InputDecoration(
              labelText: 'Username',
              hintText: 'doctor',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            validator: (v) => v == null || v.isEmpty ? 'Username required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _docPassCtrl,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'doctor123',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
          ),
          if (_docError != null) ...[
            const SizedBox(height: 8),
            Text(_docError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitDoctor,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Login as Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientForm() {
    return Form(
      key: _patientFormKey,
      child: Column(
        children: [
          const SizedBox(height: 12),
          TextFormField(
            controller: _patientPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Registered Mobile Number',
              hintText: 'e.g. 9988776655',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mobile number required';
              if (v.length < 10) return 'Valid 10-digit number required';
              return null;
            },
          ),
          if (_patientError != null) ...[
            const SizedBox(height: 8),
            Text(
              _patientError!,
              style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitPatient,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Login to Portal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
