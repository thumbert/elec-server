part of 'retail_supply_offer.dart';

class CtSupplyOffer extends RetailSupplyOffer {
  CtSupplyOffer({
    required super.region,
    required super.state,
    required super.loadZone,
    required super.utility,
    required super.accountType,
    required super.countOfBillingCycles,
    required super.minimumRecs,
    required super.offerType,
    required super.rate,
    required super.rateUnit,
    required super.supplierName,
    required super.offerPostedOnDate,
    required super.offerId,
  });

  /// Input is the json that comes directly from the utility API
  static CtSupplyOffer fromRawData(Map<String, dynamic> data) {
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
    
    return CtSupplyOffer(
      region: 'ISONE',
      state: 'CT',
      loadZone: 'CT',
      utility: data['planTypeEdc'],  // 'Eversource' or 'United Illuminating'
      accountType: data['customerClass'],
      countOfBillingCycles: countOfBillingCycles,
      minimumRecs: minimumRecs,
      offerType: data['offerType'],
      rate: num.parse(data['rate'])*1000,
      rateUnit: '\$/MWh',
      supplierName: data['supplier'],
      offerPostedOnDate: postedOn,
      offerId: 'ct-${data['id']}',
    )..rawOfferData = data;
  }
}
