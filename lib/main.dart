import 'package:flutter/material.dart';
import 'models/patient.dart';
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
  int _activeSidebarIndex = 0; // tracks clickable sidebar menu tabs

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
      _activeSidebarIndex = 0; // reset active sidebar view
    });
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _currentRole = '';
      _currentPatientMobile = '';
      _activeSidebarIndex = 0;
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
            activeIndex: _activeSidebarIndex,
            onTabChanged: (idx) {
              setState(() {
                _activeSidebarIndex = idx;
              });
            },
            child: _buildCurrentView(),
          ),
        );
      },
    );
  }

  Widget _buildCurrentView() {
    switch (_currentRole) {
      case 'receptionist':
        return ReceptionistView(
          store: _store, 
          activeIndex: _activeSidebarIndex,
          onTabChanged: (idx) {
            setState(() {
              _activeSidebarIndex = idx;
            });
          },
        );
      case 'doctor':
        return DoctorView(
          store: _store,
          activeIndex: _activeSidebarIndex,
          onTabChanged: (idx) {
            setState(() {
              _activeSidebarIndex = idx;
            });
          },
        );
      case 'patient':
        return PatientView(
          store: _store,
          activeIndex: _activeSidebarIndex,
          onTabChanged: (idx) {
            setState(() {
              _activeSidebarIndex = idx;
            });
          },
        );
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
  final int activeIndex;
  final ValueChanged<int> onTabChanged;

  const CeilaResponsiveShell({
    super.key,
    required this.role,
    required this.patientMobile,
    required this.store,
    required this.onLogout,
    required this.child,
    required this.activeIndex,
    required this.onTabChanged,
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
              children: _buildRoleSidebarMenu(context, isDrawer),
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

  List<Widget> _buildRoleSidebarMenu(BuildContext context, bool isDrawer) {
    if (role == 'receptionist') {
      return [
        const Text('MAIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildSidebarTile(Icons.calendar_month_outlined, 'Appointments Workspace', 0, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.people_outline, 'Active Queue Dashboard', 1, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.person_add_outlined, 'Patient Registration', 2, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.medical_services_outlined, 'Medicine Inventory', 3, isDrawer: isDrawer, context: context),
        const SizedBox(height: 24),
        const Text('TELEHEALTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildSidebarTile(Icons.chat_bubble_outline, 'Clinic Messages', -1, count: '3', isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.folder_shared_outlined, 'Archive Folders', -1, isDrawer: isDrawer, context: context),
      ];
    } else if (role == 'doctor') {
      return [
        const Text('CLINIC ROOM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildSidebarTile(Icons.people_alt_outlined, 'Today\'s Cabin Queue', 0, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.folder_shared_outlined, 'Patients Database', 1, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.medical_services_outlined, 'Medicines Catalog', 2, isDrawer: isDrawer, context: context),
        const SizedBox(height: 24),
        const Text('TELEHEALTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildSidebarTile(Icons.chat_bubble_outline, 'Staff Chatroom', -1, count: 'New', isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.settings_outlined, 'Cabin Preferences', -1, isDrawer: isDrawer, context: context),
      ];
    } else {
      // Patient Portal
      return [
        const Text('PATIENT PORTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        const SizedBox(height: 8),
        _buildSidebarTile(Icons.dashboard_outlined, 'Portal Dashboard', 0, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.calendar_month_outlined, 'Book Appointment', 1, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.assignment_ind_outlined, 'Queue Live Tracker', 2, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.receipt_long_outlined, 'Prescriptions History', 3, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.people_outline, 'Family Profiles', 4, isDrawer: isDrawer, context: context),
        _buildSidebarTile(Icons.favorite_border, 'Health Summary', 5, isDrawer: isDrawer, context: context),
      ];
    }
  }

  Widget _buildSidebarTile(IconData icon, String title, int tileIndex, {required bool isDrawer, required BuildContext context, String? count}) {
    final bool isActive = tileIndex == activeIndex;
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
          if (isDrawer) {
            Navigator.pop(context); // Close mobile drawer
          }
          if (tileIndex >= 0) {
            onTabChanged(tileIndex);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mock Telehealth feature coming soon!'), duration: Duration(seconds: 1)),
            );
          }
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    final loginFormPanel = Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            elevation: 8,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Secure Portal Sign-In',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 16),
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
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Clerk Desk'),
                        Tab(text: 'Doctor Cabin'),
                        Tab(text: 'Patient Portal'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
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
          const SizedBox(height: 24),
          _buildDemoAccountsPanel(),
        ],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Left branding panel
            Expanded(
              flex: 9,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0F766E),
                      Color(0xFF0D9488),
                      Color(0xFF1E3A8A),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -100,
                      left: -100,
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), shape: BoxShape.circle),
                      ),
                    ),
                    Positioned(
                      bottom: -80,
                      right: -80,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), shape: BoxShape.circle),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/logo.jpg',
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.healing,
                                      color: Color(0xFF0D9488),
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('CareFlow', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                                  Text('Clinical Management Suite', style: TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 0.5)),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 48),
                          const Text('Seamless Clinic Workflows', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          const Text('Orchestrating receptionist desks, doctor cabins, and patient portals into a unified, responsive ecosystem.', style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5)),
                          const SizedBox(height: 36),
                          _buildFeatureBullet(Icons.people_alt, 'Real-Time Queue Management', 'Track patient slots, consult status, and re-order token positions instantly.'),
                          _buildFeatureBullet(Icons.edit_note, 'Prescriptions & Medical Tests', 'Complete consultations, select medicine catalogs, and recommend lab tests.'),
                          _buildFeatureBullet(Icons.switch_account_outlined, 'Family Profiles Switchboard', 'Link multiple patient profiles to a single mobile number for fast updates.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right form panel
            Expanded(
              flex: 11,
              child: Container(
                color: const Color(0xFFF8FAFC),
                height: double.infinity,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
                    child: loginFormPanel,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile view
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F766E),
                Color(0xFF0D9488),
                Color(0xFF1E3A8A),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.healing,
                              color: Color(0xFF0D9488),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('CareFlow', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  loginFormPanel,
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFeatureBullet(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoAccountsPanel() {
    final patients = widget.store.patients;
    
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_open, color: Color(0xFF0D9488), size: 18),
                SizedBox(width: 8),
                Text(
                  'Demo Accounts & Seeded Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Select any account below to instantly connect with preloaded data.',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 12),
            
            const Text('CLINIC STAFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            _buildDemoAccountRow(
              'Front Desk Clerk',
              'Username: clerk | Pass: receptionist123',
              Icons.assignment_ind,
              Colors.blue,
              () => _quickConnect('receptionist'),
            ),
            _buildDemoAccountRow(
              'Dr. Amit Verma (Consultant)',
              'Username: doctor | Pass: doctor123',
              Icons.medical_services,
              Colors.teal,
              () => _quickConnect('doctor'),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PATIENTS / FAMILY ACCOUNTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text('${patients.length} Profiles', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                )
              ],
            ),
            const SizedBox(height: 8),
            
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: patients.isEmpty
                  ? const Center(child: Text('No patient profiles in database.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: patients.length,
                      separatorBuilder: (c, i) => const Divider(height: 8),
                      itemBuilder: (context, idx) {
                        final p = patients[idx];
                        return _buildDemoPatientRow(p);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoAccountRow(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 14,
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Login', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoPatientRow(Patient p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.withOpacity(0.1),
            radius: 14,
            child: Text(
              p.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 10, color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                    const SizedBox(width: 6),
                    Text('(${p.gender.substring(0, 1)}, ${p.age}y)', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Text('Mobile: ${p.mobileNumber}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _quickConnect('patient', mobile: p.mobileNumber),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Login', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
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
