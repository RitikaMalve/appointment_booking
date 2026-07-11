# CareFlow Clinical Management Suite

CareFlow is a modern, responsive Flutter Web, Tablet, and Mobile application designed to streamline clinic workflows. It connects reception desks, doctor cabins, and patient portals into a unified, real-time ecosystem.

## 🚀 Key Features

### 1. 🏥 Real-Time Queue Management
- **Receptionist View**: Register new or lookup existing patients by mobile number. Add patients to the daily queue with a single click. Keep track of status (waiting, serving, completed, skipped) and update consultation fees status.
- **Doctor View**: Access the live patient queue. Call the next patient, view medical history, write diagnoses and clinical advice, and generate prescriptions.
- **Patient Portal**: Patients log in via their registered mobile number to view their token number, real-time queue position (number of patients ahead), estimated wait times, and view or print past prescriptions.

### 2. ⚡ Doctor's Quick Medicine Suggester
- Built-in clinical medicine database grouped by categories (e.g., Pain & Fever, Antibiotics, Digestion, Allergies, Chronic Management).
- **Interactive Suggester Grid**: View preset suggestions. Click a preset to instantly autofill the form (name, dosage, duration, instructions), or click the `+` icon to directly quick-add the medicine to the prescription with default instructions.
- Search presets in real-time.

### 3. 📱 Responsive Layouts (Mobile Web, Tablet, Desktop)
- **AppBar**: Automatically compresses text-heavy action buttons into compact icons on small viewports (`width < 600px`) to prevent rendering overflows.
- **Receptionist Screen**: 
  - *Desktop/Tablet (`width >= 850px`)*: Beautiful side-by-side split screen (Patient Registration Form | Live Queue Dashboard).
  - *Mobile (`width < 850px`)*: Clean tabbed interface ("Registration" & "Queue & Stats") to avoid nested scrolling and provide a native app feel. Auto-switches tabs to the Queue list on successful patient registration.
- **Doctor Screen**:
  - *Desktop/Tablet (`width >= 900px`)*: Side-by-side view (Queue & Details | Prescription Form).
  - *Mobile (`width < 900px`)*: Elegant tabbed layout ("Patient Queue" & "Prescription"). Selecting a patient in the queue automatically slides the view to the prescription form.
- **Patient Portal**:
  - *Desktop/Tablet (`width >= 900px`)*: Dual-column grid (Left: Profile & Queue Status Card | Right: Scrollable Prescription History list).
  - *Mobile (`width < 900px`)*: Single-column scrollable flow.

### 4. 🎨 Professional Brand Logo
- Customized CareFlow logo (`assets/logo.jpg`) integrated on the Secure Sign-In page, Main Header AppBar, and at the top of printed clinic prescriptions.

---

## 📂 Project Structure

```
lib/
├── main.dart              # Application entry, global theme, and secure login gate
├── models/
│   ├── patient.dart       # Patient profile model
│   ├── queue_item.dart    # Live queue ticket details & status
│   └── medical_record.dart# Consultation records and medicine items
├── services/
│   └── clinic_store.dart  # In-memory reactive state manager (ChangeNotifier)
├── utils/
│   ├── mock_generator.dart# Auto-seeding mock generator for demonstration
│   └── medicine_presets.dart # Predefined medicine dictionary & autofill configs
└── widgets/
    ├── receptionist_view.dart # Receptionist desktop layout & mobile tabs
    ├── doctor_view.dart       # Doctor cabin dashboard, presets, & tab transitions
    └── patient_view.dart      # Patient portal dashboard, layout grids, & print dialogues
```

---

## 🛠️ Get Started

### Prerequisites
- Flutter SDK (v3.0.0 or higher)
- Chrome / Safari / Edge (for Web target)

### Installation & Execution

1. Clone or navigate to the project directory:
   ```bash
   cd "appointment_booking-1"
   ```

2. Retrieve dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application locally in release or debug mode (for web, desktop, or mobile devices):
   ```bash
   flutter run -d chrome
   ```

### 🔑 Demo Credentials
The database automatically self-seeds with mock records on first launch. You can use the quick connect buttons at the bottom of the login screen or sign in manually with:
- **Clerk Portal**: Username `clerk`, Password `receptionist123`
- **Doctor Portal**: Username `doctor`, Password `doctor123`
- **Patient Portal**: Mobile number `9988776655` (Priya Patel) or `9345678901` (Ananya Iyer)

---

## 🌐 Deploying to GitHub (Future Use)

To stage, commit, and push your future development updates to GitHub, use the following commands in your terminal:

1. **Stage all modified and new files**:
   ```bash
   git add .
   ```

2. **Create a git commit with a descriptive message**:
   ```bash
   git commit -m "Describe your changes here"
   ```

3. **Push your changes to the remote repository on GitHub**:
   ```bash
   git push origin main
   ```

---

## 🚀 Deploying the Web App to GitHub Pages (Future Use)

To compile and deploy the latest build of the CareFlow Web App to GitHub Pages, run the following commands:

1. **Build the Flutter Web files with the correct repository base href**:
   ```bash
   flutter build web --base-href "/appointment_booking/"
   ```

2. **Push the compiled assets to the `gh-pages` branch**:
   ```bash
   cd build/web
   git init
   git checkout -b gh-pages
   git remote add origin https://github.com/RitikaMalve/appointment_booking.git
   git add .
   git commit -m "Deploy to GitHub Pages"
   git push -f origin gh-pages
   cd ../..
   ```

> [!IMPORTANT]
> **Enable GitHub Pages**: Inside your GitHub repository, navigate to **Settings > Pages**. Under **Build and deployment > Branch**, change the source branch from `main` to `gh-pages` and save. This tells GitHub to host your compiled web app rather than your source code's README!


