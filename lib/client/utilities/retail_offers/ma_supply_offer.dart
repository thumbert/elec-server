part of 'retail_supply_offer.dart';

/// Constellation
/// https://www.massenergyrates.com/signups/ma/164/3036
/// https://www.massenergyrates.com/signups/ma/164/3037

/// Discount Power
/// https://www.massenergyrates.com/signups/ma/164/2276

// <!-- <option selected disabled value="">Select Your Utility</option> -->
// <option value="51" data-udc="NSTAR,CA,BE,CM">Eversource (formerly NSTAR)</option>
// <option value="52" data-udc="MECO">National Grid - (formerly Mass Electric Co)</option>
// <option value="59" data-udc="WMECO">Eversource (formerly WMECO)</option>
// <option value="60" data-udc="">Unitil</option>

// <option value="residential"> Residential</option>
// <option value="small_commercial"> Commercial (under 20,000 kWh/mo)</option>
// <option value="large_commercial"> Large Commercial (over 20,000 kWh/mo)</option>

final zipToLoadZone = {
  '01128': 'WCMA', // Springfield (Eversource)
  '01450': 'WCMA', // Groton (NGrid)
  '01462': 'WCMA', // Lunenburg (Unitil)
  '01936': 'NEMA', // Hamilton (NGrid)
  '02110': 'NEMA', // Boston (Eversource)
  '02302': 'SEMA', // Brockton (NGrid)
  '02740': 'SEMA', // New Bedford (Eversource)
};

final utilityIdToUtility = {
  '51': 'Eversource', // NStar
  '52': 'NGrid', // MECO
  '59': 'NGrid', // WMECO
  '60': 'Unitil',
};

class MaSupplyOffer extends RetailSupplyOffer {
  MaSupplyOffer({
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

  /// Input is the json that gets saved on the file
  // static MaSupplyOffer fromRawData(Map<String, dynamic> data) {
  //
  //   if (data['state'] != 'MA') {
  //     throw StateError('Offer should be for state: MA, got ${data['state']}.');
  //   }
  //
  //   num minimumRecs;
  //   if (data['planFeatures'].contains('100%')) {
  //     minimumRecs = 1.0;
  //   } else {
  //     minimumRecs = 0.0;
  //   }
  //
  //   // get the offer start date from the content url
  //   var aux = (data['contentUrl'] as String).split('/')[2].split('-')[1];
  //   var postedOn = Date.utc(int.parse(aux.substring(4)), int.parse(aux.substring(0,2)),
  //       int.parse(aux.substring(2,4)));
  //
  //   return MaSupplyOffer(
  //     region: 'ISONE',
  //     state: data['state'],
  //     loadZone: data['loadZone'],
  //     utility: data['utility'],  // 'Eversource' or 'NGrid' or 'Unitil'
  //     accountType: data['accountType'],
  //     countOfBillingCycles: data['countOfBillingCycles'],
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
