///
class Settings {
  Settings({required this.iso, required this.location});

  final String iso;
  final String location;

  static Settings defaultSettings() {
    return Settings(iso: 'ISONE', location: '.H.INTERNAL_HUB, ptid:4000');
  }

  Settings copyWith({String? iso, String? location}) {
    return Settings(
      iso: iso ?? this.iso,
      location: location ?? this.location,
    );
  }

  static final List<String> allIsos = ['CAISO', 'ISONE', 'NYISO', 'PJM'];
}
