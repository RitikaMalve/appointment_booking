class MedicinePreset {
  final String name;
  final String category;
  final String defaultDosage;
  final String defaultDuration;
  final String defaultInstructions;

  const MedicinePreset({
    required this.name,
    required this.category,
    required this.defaultDosage,
    required this.defaultDuration,
    required this.defaultInstructions,
  });
}

const List<MedicinePreset> medicinePresets = [
  // Pain & Fever
  MedicinePreset(
    name: 'Paracetamol 650mg',
    category: 'Pain & Fever',
    defaultDosage: '1-0-1',
    defaultDuration: '3 days',
    defaultInstructions: 'After food',
  ),
  MedicinePreset(
    name: 'Ibuprofen 400mg',
    category: 'Pain & Fever',
    defaultDosage: '1-0-1',
    defaultDuration: '3 days',
    defaultInstructions: 'After food',
  ),
  MedicinePreset(
    name: 'Diclofenac 50mg',
    category: 'Pain & Fever',
    defaultDosage: '1-0-1',
    defaultDuration: '5 days',
    defaultInstructions: 'After food',
  ),
  // Antibiotics
  MedicinePreset(
    name: 'Amoxicillin 500mg',
    category: 'Antibiotics',
    defaultDosage: '1-1-1',
    defaultDuration: '5 days',
    defaultInstructions: 'After food',
  ),
  MedicinePreset(
    name: 'Azithromycin 500mg',
    category: 'Antibiotics',
    defaultDosage: '1-0-0',
    defaultDuration: '3 days',
    defaultInstructions: 'After food',
  ),
  MedicinePreset(
    name: 'Ciprofloxacin 500mg',
    category: 'Antibiotics',
    defaultDosage: '1-0-1',
    defaultDuration: '5 days',
    defaultInstructions: 'After food',
  ),
  // Acidity & Digestion
  MedicinePreset(
    name: 'Pantoprazole 40mg',
    category: 'Acidity & Digestion',
    defaultDosage: '1-0-0',
    defaultDuration: '7 days',
    defaultInstructions: '30 mins before breakfast',
  ),
  MedicinePreset(
    name: 'Omeprazole 20mg',
    category: 'Acidity & Digestion',
    defaultDosage: '1-0-0',
    defaultDuration: '14 days',
    defaultInstructions: 'Before food',
  ),
  MedicinePreset(
    name: 'Syrup Sucralfate',
    category: 'Acidity & Digestion',
    defaultDosage: '1-1-1',
    defaultDuration: '5 days',
    defaultInstructions: '2 teaspoons before food',
  ),
  // Allergies & Cold
  MedicinePreset(
    name: 'Cetirizine 10mg',
    category: 'Allergies & Cold',
    defaultDosage: '0-0-1',
    defaultDuration: '5 days',
    defaultInstructions: 'Before sleeping',
  ),
  MedicinePreset(
    name: 'Montelukast 10mg',
    category: 'Allergies & Cold',
    defaultDosage: '0-0-1',
    defaultDuration: '10 days',
    defaultInstructions: 'Before sleeping',
  ),
  MedicinePreset(
    name: 'Levocetirizine 5mg',
    category: 'Allergies & Cold',
    defaultDosage: '0-0-1',
    defaultDuration: '5 days',
    defaultInstructions: 'Before sleeping',
  ),
  // Chronic Management
  MedicinePreset(
    name: 'Metformin 500mg',
    category: 'Chronic (Diabetes)',
    defaultDosage: '1-0-1',
    defaultDuration: '30 days',
    defaultInstructions: 'With meals',
  ),
  MedicinePreset(
    name: 'Amlodipine 5mg',
    category: 'Chronic (BP)',
    defaultDosage: '1-0-0',
    defaultDuration: '30 days',
    defaultInstructions: 'Morning after food',
  ),
  MedicinePreset(
    name: 'Atorvastatin 10mg',
    category: 'Chronic (Cholesterol)',
    defaultDosage: '0-0-1',
    defaultDuration: '30 days',
    defaultInstructions: 'Evening after food',
  ),
];
