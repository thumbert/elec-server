library db.utilities.retail_supply_offer;

import 'package:date/date.dart';
import 'package:timezone/timezone.dart';

part 'ct_supply_offer.dart';

class RetailSupplyOffer {
  RetailSupplyOffer({
    required this.region,
    required this.state,
    required this.utility,
    required String accountType,
    required this.countOfBillingCycles,
    this.feeTypes = const <String>[],
    required num minimumRecs,
    this.planType,
    required offerType,
    required this.rate,
    required this.rateUnit,
    required this.supplierName,
    required this.offerPostedOnDate,
    required this.offerId,
  }) {
    this.accountType = accountType;
    this.minimumRecs = minimumRecs;
    this.offerType = offerType;

  }

  final String region;
  final String state;
  final String utility;
  late final String _accountType;
  final String? planType; // Load class
  final int countOfBillingCycles;
  late final List<String> feeTypes;

  /// Type of the offer.  One of Fixed, Fixed-Tiered, Indexed
  late final String _offerType;

  late final num _minimumRecs;

  /// Offer rate, preferred rate in $/MWh
  final num rate;

  /// Unit of the offer rate, preferred in $/MWh
  final String rateUnit;

  final String supplierName;

  /// When has the offer been made, in UTC
  final Date offerPostedOnDate;

  /// A unique string id for this offer
  final String offerId;

  /// What you get from the website.  This may or may not exist depending
  /// on the website.
  Map<String, dynamic>? rawOfferData;

  static Set<String> allowedAccountType = {'Residential', 'Business'};
  static Set<String> allowedOfferTypes = {'Fixed', 'Fixed-Tiered', 'Indexed'};

  /// Residential or Business
  set accountType(String value) {
    if (allowedAccountType.contains(value)) {
      _accountType = value;
    } else {
      throw StateError('Unsupported accountType $value');
    }
  }

  String get accountType => _accountType;

  set offerType(String value) {
    if (allowedOfferTypes.contains(value)) {
      _offerType = value;
    } else {
      throw StateError('Unsupported offerType $value');
    }
  }

  String get offerType => _offerType;

  /// Percent of Recs, a number between [0, 1]
  set minimumRecs(num value) {
    if (value > 1 || value < 0) {
      throw StateError('Minimum recs $value is not between [0, 1]');
    }
    _minimumRecs = value;
  }

  num get minimumRecs => _minimumRecs;

  /// What to insert in the database
  Map<String,dynamic> toMongo() {
    var out = {
      'offerId': offerId,
      'region': region,
      'state': state,
      'utility': utility,
      'accountType': accountType,
      'countOfBillingCycles': countOfBillingCycles,
      'minimumRecs': minimumRecs,
      'offerType': offerType,
      'rate': rate,
      'rateUnit': rateUnit,
      'supplierName': supplierName,
      'offerPostedOnDate': offerPostedOnDate.toString(),
    };
    if (rawOfferData != null) {
      out['rawOfferData'] = rawOfferData!;
    }
    return out;
  }

  ///
  static RetailSupplyOffer fromMongo(Map<String,dynamic> xs) {
    var offer = RetailSupplyOffer(
        region: xs['region'],
        state: xs['state'],
        utility: xs['utility'],
        accountType: xs['accountType'],
        countOfBillingCycles: xs['countOfBillingCycles'],
        minimumRecs: xs['minimumRecs'],
        offerType: xs['offerType'],
        rate: xs['rate'],
        rateUnit: xs['rateUnit'],
        supplierName: xs['supplierName'],
        offerPostedOnDate: Date.fromIsoString(xs['offerPostedOnDate'], location: UTC),
        offerId: xs['offerId'],
    );
    if (xs.containsKey('rawOfferData')) {
      offer.rawOfferData =  xs['rawOfferData'];
    }
    return offer;
  }


  @override
  int get hashCode => offerId.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! RetailSupplyOffer) {
      return false;
    }
    return offerId == other.offerId;
  }
}
