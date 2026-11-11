/// Sample Yaoundé landmarks with rough distances, standing in for the
/// landmark database until the backend exists. Search is a simple
/// case-insensitive substring match.
const kSampleLandmarks = <(String, String)>[
  ('Poste Centrale', '~2km'),
  ('Carrefour Warda', '~3km'),
  ('Marché Mokolo', '~4km'),
  ('Rond-point Nlongkak', '~3km'),
  ('Carrefour Bastos', '~6km'),
  ('Awae Escaliers', '~26km'),
  ("Carrefour l'amitié", '~27km'),
  ('Carrefour Mvan', '~8km'),
  ('Palais des Congrès', '~5km'),
  ('Eyang', '~18km'),
  ('Mvog-Mbi', '~5km'),
  ('Ngoa-Ekellé', '~4km'),
  ('Biyem-Assi', '~7km'),
  ('Essos', '~5km'),
];

/// Up to [limit] landmarks matching [query].
List<(String, String)> searchLandmarks(String query, {int limit = 3}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return kSampleLandmarks
      .where((l) => l.$1.toLowerCase().contains(q))
      .take(limit)
      .toList();
}
