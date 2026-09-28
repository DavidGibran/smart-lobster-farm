enum FarmEventType {
  feeding(firebaseValue: 'feeding', label: 'Pemberian Pakan'),
  waterChange(firebaseValue: 'water_change', label: 'Ganti Air'),
  waterAddition(firebaseValue: 'water_addition', label: 'Tambah Air'),
  molting(firebaseValue: 'molting', label: 'Molting Terlihat'),
  mating(firebaseValue: 'mating', label: 'Mating Terlihat'),
  maintenance(firebaseValue: 'maintenance', label: 'Maintenance');

  const FarmEventType({required this.firebaseValue, required this.label});

  final String firebaseValue;
  final String label;

  static FarmEventType? tryFromFirebaseValue(Object? value) {
    for (final type in values) {
      if (type.firebaseValue == value) return type;
    }
    return null;
  }
}
