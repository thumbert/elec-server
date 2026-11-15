import 'package:elec_server/client/isone/ptid_table.dart' as isone;
import 'package:elec_server/client/nyiso/ptid_table.dart' as nyiso;

/// Cache the node info by ISO.
final cache = <String, List<Map<String, dynamic>>>{};

/// Returns a list of node name + ptid for the specified ISO.
///
/// The returned list contains strings in the format "[node name], ptid: [ptid]".
///
Future<List<String>> getPtids({
  required String iso,
  required String rootUrl,
}) async {
  switch (iso.toLowerCase()) {
    case 'isone':
      if (!cache.containsKey(iso)) {
        final records = await isone.queryRecords(
          filter: isone.QueryFilter(),
          rootUrl: rootUrl,
        );
        cache[iso] = records.map((e) => e.toJson()).toList();
      }
      final result = cache[iso]!
          .map((e) => '${e['name']}, ptid: ${e['ptid']}')
          .toList();
      return result;
    case 'nyiso':
      if (!cache.containsKey(iso)) {
        final records = await nyiso.queryRecords(
          filter: nyiso.QueryFilter(),
          rootUrl: rootUrl,
        );
        cache[iso] = records.map((e) => e.toJson()).toList();
      }
      final result = cache[iso]!
          .map((e) => '${e['name']}, ptid: ${e['ptid']}')
          .toList();
      return result;
    default:
      throw ArgumentError('Unsupported ISO: $iso');
  }
}
