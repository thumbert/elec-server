part of 'retail_supply_offer.dart';


class CtSupplyOffer extends RetailSupplyOffer {
  CtSupplyOffer({
    required super.region,
    required super.state,
    required super.loadZone,
    required super.utility,
    required super.accountType,
    required super.rateClass,
    required super.countOfBillingCycles,
    required super.minimumRecs,
    required super.offerType,
    required super.rate,
    required super.rateUnit,
    required super.supplierName,
    required super.planFeatures,
    required super.planFees,
    required super.offerPostedOnDate,
    required super.firstDateOnWebsite,
    required super.lastDateOnWebsite,
    required super.offerId,
  });

  /// Input is the json that comes directly from the utility API
  static Map<String,dynamic> toMongo(Map<String, dynamic> data) {
    var countOfBillingCycles =
    int.parse((data['termOfOffer'] as String).split(' ')[0]);

    num minimumRecs;
    if (data.containsKey('recs')) {
      minimumRecs = num.parse(data['recs']) / 100;
    } else {
      minimumRecs = 0.0;
    }

    // get the offer start date from the content url
    var aux = (data['contentUrl'] as String).split('/')[2].split('-')[1];
    var postedOn = Date.utc(int.parse(aux.substring(4)), int.parse(aux.substring(0,2)),
        int.parse(aux.substring(2,4)));

    var planFeatures = <String>[];
    if (data.containsKey('incentive') && data['incentive'] != null) {
      planFeatures.add(data['incentive']);
    }
    if (data.containsKey('standardNotes') && data['standardNotes'] != null) {
      planFeatures.add(data['standardNotes']);
    }

    var planFees = <String>[];
    if (data['fees'] is String) {
      planFees.add(data['fees']);
    } else {
      planFees.addAll((data['fees'] as List).cast<String>());
    }

    return {
      'region': 'ISONE',
      'state': 'CT',
      'loadZone': 'CT',
      'utility': data['planTypeEdc'], // 'Eversource' or 'United Illuminating'
      'accountType': data['customerClass'],
      'rateClass': data['rateClass'],
      'countOfBillingCycles': countOfBillingCycles,
      'minimumRecs': minimumRecs,
      'offerType': data['offerType'],
      'rate': num.parse(data['rate']) * 1000,
      'rateUnit': '\$/MWh',
      'supplierName': data['supplier'],
      'offerPostedOnDate': postedOn.toString(),
      'offerId': 'ct-${data['id']}',
      'planFees': planFees,
      'planFeatures': planFeatures,
      'asOfDate': data['asOfDate'],
    };
  }

  ///
  // static RetailSupplyOffer fromMongo(Map<String,dynamic> xs) {
  //   var offer = RetailSupplyOffer(
  //     region: xs['region'],
  //     state: xs['state'],
  //     loadZone: xs['loadZone'],
  //     utility: xs['utility'],
  //     accountType: xs['accountType'],
  //     countOfBillingCycles: xs['countOfBillingCycles'],
  //     minimumRecs: xs['minimumRecs'],
  //     offerType: xs['offerType'],
  //     rate: xs['rate'],
  //     rateUnit: xs['rateUnit'],
  //     supplierName: xs['supplierName'],
  //     offerPostedOnDate: Date.fromIsoString(xs['offerPostedOnDate'], location: UTC),
  //     offerId: xs['offerId'],
  //   );
  //   return offer;
  // }



  /// Input is the json that comes directly from the utility API
  // static CtSupplyOffer fromRawData(Map<String, dynamic> data) {
  //   var countOfBillingCycles =
  //       int.parse((data['termOfOffer'] as String).split(' ')[0]);
  //
  //   num minimumRecs;
  //   if (data.containsKey('recs')) {
  //     minimumRecs = num.parse(data['recs']) / 100;
  //   } else {
  //     minimumRecs = 0.0;
  //   }
  //
  //   // get the offer start date from the content url
  //   var aux = (data['contentUrl'] as String).split('/')[2].split('-')[1];
  //   var postedOn = Date.utc(int.parse(aux.substring(4)), int.parse(aux.substring(0,2)),
  //     int.parse(aux.substring(2,4)));
  //
  //   return CtSupplyOffer(
  //     region: 'ISONE',
  //     state: 'CT',
  //     loadZone: 'CT',
  //     utility: data['planTypeEdc'],  // 'Eversource' or 'United Illuminating'
  //     accountType: data['customerClass'],
  //     countOfBillingCycles: countOfBillingCycles,
  //     minimumRecs: minimumRecs,
  //     offerType: data['offerType'],
  //     rate: num.parse(data['rate'])*1000,
  //     rateUnit: '\$/MWh',
  //     supplierName: data['supplier'],
  //     offerPostedOnDate: postedOn,
  //     offerId: 'ct-${data['id']}',
  //   )..rawOfferData = data;
  // }
}
