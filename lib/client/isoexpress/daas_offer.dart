import 'dart:convert';

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart';

Future<List<DaasOffer>> getDaasOffers(
    {required Date start,
    required Date end,
    required Iso iso,
    required String rootUrl}) async {
  final url = '$rootUrl/${iso.name.toLowerCase()}/daas_offers'
      '/start/$start/end/$end';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data as List).map<DaasOffer>((e) => DaasOffer.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load daas offers');
  }
}

class DaasOffer {
  DaasOffer(
      {required this.hourBeginning,
      required this.maskedAssetId,
      required this.maskedParticipantId,
      required this.priceTmsr,
      required this.priceTmnsr,
      required this.priceTmor,
      required this.priceEir,
      required this.quantity});

  final TZDateTime hourBeginning;
  final int maskedAssetId;
  final int maskedParticipantId;
  final num priceTmsr;
  final num priceTmnsr;
  final num priceTmor;
  final num priceEir;
  final num quantity;

  static DaasOffer fromJson(Map<String, dynamic> json) {
    return DaasOffer(
      hourBeginning:
          TZDateTime.parse(IsoNewEngland.location, json['hour_beginning']),
      maskedAssetId: json['masked_asset_id'],
      maskedParticipantId: json['masked_participant_id'],
      priceTmsr: json['tmsr_offer_price'],
      priceTmnsr: json['tmnsr_offer_price'],
      priceTmor: json['tmor_offer_price'],
      priceEir: json['eir_offer_price'],
      quantity: json['offer_mw'],
    );
  }

  @override
  String toString() {
    return toJson().toString();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'hour_beginning': hourBeginning.toIso8601String(),
      'masked_asset_id': maskedAssetId,
      'masked_participant_id': maskedParticipantId,
      'price_tmsr': priceTmsr,
      'price_tmnsr': priceTmnsr,
      'price_tmor': priceTmor,
      'price_eir': priceEir,
      'quantity': quantity,
    };
  }
}
