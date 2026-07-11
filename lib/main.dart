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
          seedColor: const Color(0xFF0D9488), // Ceila Teal
          primary: const Color(0xFF0D9488),
          secondary: const Color(0xFF0F766E),
          background: const Color(0xFFF8FAFC), // Off-white/slate
          surface: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.04),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          iconTheme: IconThemeData(color: Color(0xFF1E293B)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        fontFamily: 'Outfit', // A modern clean typeface resembling the mockup font
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
  
  bool _isLoggedIn = false;
  String _currentRole = ''; // 'receptionist', 'doctor', 'patient'
  String _currentPatientMobile = ''; // for patient portal login

  @override
  void initState() {
    super.initState();
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
                  Text('Loading CareFlow Clinic Database...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
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
          backgroundColor: const Color(0xFFF8FAFC),
          body: CeilaResponsiveShell(
            role: _currentRole,
            patientMobile: _currentPatientMobile,
            store: _store,
            onLogout: _logout,
            child: _buildCurrentView(),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView() {
    switch (_currentRole) {
      case 'receptionist':
        return ReceptionistView(store: _store);
      case 'doctor':
        return DoctorView(store: _store);
      case 'patient':
        return PatientView(store: _store);
      default:
        return const Center(child: Text('Invalid View selected'));
    }
  }
}

// Responsive Ceila Sidebar Shell
class CeilaResponsiveShell extends StatelessWidget {
  final String role;
  final String patientMobile;
  final ClinicStore store;
  final VoidCallback onLogout;
  final Widget child;

  const CeilaResponsiveShell({
    super.key,
    required this.role,
    required this.patientMobile,
    required this.store,
    required this.onLogout,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return Row(
            children: [
              _buildSidebar(context),
              Expanded(
                child: Column(
                  children: [
                    _buildTopHeader(context),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          );
        } else {
          // Mobile responsive layout with Drawer
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset('assets/logo.jpg', width: 26, height: 26, fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Icon(Icons.healing, color: Color(0xFF0D9488), size: 24),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('CareFlow Clinic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: onLogout,
                )
              ],
            ),
            drawer: Drawer(
              child: _buildSidebar(context, isDrawer: true),
            ),
            body: child,
          );
        }
      },
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    String welcomeMsg = 'Welcome back';
    if (role == 'doctor') {
      welcomeMsg = 'Welcome back, Dr. Amit Verma';
    } else if (role == 'receptionist') {
      welcomeMsg = 'Welcome back, Desk Admin';
    } else {
      final p = store.getPatientsByMobile(patientMobile);
      if (p.isNotEmpty) {
        welcomeMsg = 'Welcome back, ${p.first.name}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                welcomeMsg,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const Text('Here\'s a real-time status of your clinic workflows today.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          Row(
            children: [
              // Search field placeholder
              Container(
                width: 200,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Search records...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
                child: Icon(
                  role == 'doctor' ? Icons.medical_services_outlined : (role == 'receptionist' ? Icons.desk : Icons.person_outline),
                  size: 16,
                  color: const Color(0xFF0D9488),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, {bool isDrawer = false}) {
    String profileName = 'Administrator';
    String profileSub = 'Front Desk Clerk';
    if (role == 'doctor') {
      profileName = 'Dr. Amit Verma';
      profileSub = 'Lead Consultant';
    } else if (role == 'patient') {
      final p = store.getPatientsByMobile(patientMobile);
      profileName = p.isNotEmpty ? p.first.name : 'Patient Portal';
      profileSub = 'Registered Patient';
    }

    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/logo.jpg',
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => const Icon(Icons.healing, color: Color(0xFF0D9488), size: 32),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('CareFlow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text('Clinical Platform', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                const Text('MAIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildSidebarTile(Icons.dashboard_outlined, 'Dashboard', isActive: true),
                _buildSidebarTile(Icons.calendar_month_outlined, 'Appointments', count: role == 'receptionist' ? 'New' : null),
                _buildSidebarTile(Icons.chat_bubble_outline, 'Messages', count: '3'),
                
                const SizedBox(height: 24),
                const Text('MEDICAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildSidebarTile(Icons.folder_shared_outlined, 'Medical Records'),
                _buildSidebarTile(Icons.receipt_long_outlined, 'Prescriptions'),
                _buildSidebarTile(Icons.payment_outlined, 'Billing'),
                _buildSidebarTile(Icons.search_off_outlined, 'Find Doctors'),

                const SizedBox(height: 24),
                const Text('GENERAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 8),
                _buildSidebarTile(Icons.notifications_none, 'Notifications'),
                _buildSidebarTile(Icons.settings_outlined, 'Settings'),
                _buildSidebarTile(Icons.help_outline, 'Support'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Profile item at bottom
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0D9488).withOpacity(0.1),
                  child: Text(
                    profileName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profileSub,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
                  onPressed: onLogout,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Logout',
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(IconData icon, String title, {bool isActive = false, String? count}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0D9488).withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, size: 18, color: isActive ? const Color(0xFF0D9488) : Colors.grey.shade600),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFF0D9488) : const Color(0xFF334155),
          ),
        ),
        trailing: count != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(count, style: TextStyle(fontSize: 9, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
              )
            : null,
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        onTap: () {
          // Dummy sidebar navigation actions
        },
      ),
    );
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
    setState(() => _recepError = null);
    if (!_recepFormKey.currentState!.validate()) return;
    
    final username = _recepUserCtrl.text.trim();
    final password = _recepPassCtrl.text.trim();

    if (username == 'clerk' && password == 'receptionist123') {
      widget.onLoginSuccess('receptionist');
    } else {
      setState(() => _recepError = 'Invalid clerk credentials.');
    }
  }

  void _submitDoctor() {
    setState(() => _docError = null);
    if (!_docFormKey.currentState!.validate()) return;

    final username = _docUserCtrl.text.trim();
    final password = _docPassCtrl.text.trim();

    if (username == 'doctor' && password == 'doctor123') {
      widget.onLoginSuccess('doctor');
    } else {
      setState(() => _docError = 'Invalid doctor credentials.');
    }
  }

  void _submitPatient() {
    setState(() => _patientError = null);
    if (!_patientFormKey.currentState!.validate()) return;

    final phone = _patientPhoneCtrl.text.trim();
    final patients = widget.store.getPatientsByMobile(phone);

    if (patients.isNotEmpty) {
      widget.onLoginSuccess('patient', patientMobile: phone);
    } else {
      setState(() => _patientError = 'Mobile number not found. Ask receptionist to register.');
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.healing,
                            color: Color(0xFF0D9488),
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('CareFlow', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                        Text('Clinical Management Suite', style: TextStyle(fontSize: 13, color: Colors.white70, letterSpacing: 0.5)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Login card
                Card(
                  elevation: 12,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Text('Secure Portal Sign-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 24),
                        
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            labelColor: const Color(0xFF0D9488),
                            unselectedLabelColor: Colors.grey,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Clerk Desk'),
                              Tab(text: 'Doctor Cabin'),
                              Tab(text: 'Patient Portal'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
  
                        SizedBox(
                          height: 260,
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

                // Quick connect options
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      const Text('⚡ DEMO QUICK CONNECT', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildQuickCard('Clerk Portal', 'Front Desk', Icons.assignment_ind, Colors.blue, () => _quickConnect('receptionist')),
                          _buildQuickCard('Dr. Verma', 'Doctor Cabin', Icons.medical_services, Colors.teal, () => _quickConnect('doctor')),
                          _buildQuickCard('Rohan (Family)', '9876543210', Icons.person, Colors.orange, () => _quickConnect('patient', mobile: '9876543210')),
                          _buildQuickCard('Priya (Family)', '9988776655', Icons.person, Colors.indigo, () => _quickConnect('patient', mobile: '9988776655')),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
            Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10), textAlign: TextAlign.center),
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
              child: const Text('Login to Desk', style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: const Text('Login to Cabin', style: TextStyle(fontWeight: FontWeight.bold)),
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
              hintText: 'e.g. 9876543210',
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
            Text(_patientError!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
              child: const Text('Access Portal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
