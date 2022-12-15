library db.utilities.retail_supply_offer;

import 'dart:convert';
import 'dart:io';

import 'package:date/date.dart';
import 'package:http/http.dart';
import 'package:timezone/timezone.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:html/parser.dart' show parse;

part 'ct_supply_offer.dart';
part 'ma_supply_offer.dart';

// New Hampshire : https://www.energy.nh.gov/engyapps/ceps/shop.aspx
// Rohde Island: https://www.ri.gov/app/dpuc/empowerri
// Massachusetts: https://www.massenergyrates.com/compare-mass-electricity-rates
// Maine: https://www.maine.gov/meopa/electricity/electricity-supply


class RetailSupplyOffer {
  RetailSupplyOffer({
    required this.region,
    required this.state,
    required this.loadZone,
    required this.utility,
    required String accountType,
    required this.rateClass,
    required this.countOfBillingCycles,
    this.feeTypes = const <String>[],
    required num minimumRecs,
    required offerType,
    required this.rate,
    required this.rateUnit,
    required this.supplierName,
    required this.planFeatures,
    required this.planFees,
    required this.offerPostedOnDate,
    required this.firstDateOnWebsite,
    required this.lastDateOnWebsite,
    required this.offerId,
  }) {
    this.accountType = accountType;
    this.minimumRecs = minimumRecs;
    this.offerType = offerType;

  }
  final String region;
  final String state;
  final String loadZone;
  final String utility;
  late final String _accountType;
  final String rateClass;
  final List<String> planFeatures; // extra details about the plan
  final List<String> planFees; // extra details about the fees associated with the plan
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

  /// Date when the offer added to the db for the first time, in UTC
  final Date firstDateOnWebsite;

  /// Date when the offer added to the db for the last time, in UTC
  final Date lastDateOnWebsite;

  /// A unique string id for this offer
  final String offerId;

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

  ///
  static RetailSupplyOffer fromMongo(Map<String,dynamic> xs) {
    var planFeatures = <String>[];
    if (xs['planFeatures'] is List) {
      planFeatures = (xs['planFeatures'] as List).cast<String>();
    }
    var planFees = <String>[];
    if (xs['planFees'] is List) {
      planFees = (xs['planFees'] as List).cast<String>();
    }

    var offer = RetailSupplyOffer(
        region: xs['region'],
        state: xs['state'],
        loadZone: xs['loadZone'],
        utility: xs['utility'],
        accountType: xs['accountType'],
        rateClass: xs['rateClass'],
        countOfBillingCycles: xs['countOfBillingCycles'],
        minimumRecs: xs['minimumRecs'],
        offerType: xs['offerType'],
        rate: xs['rate'],
        rateUnit: xs['rateUnit'],
        supplierName: xs['supplierName'],
        planFeatures: planFeatures,
        planFees: planFees,
        offerPostedOnDate: Date.fromIsoString(xs['offerPostedOnDate'] ?? xs['firstDateOnWebsite'], location: UTC),
        firstDateOnWebsite: Date.fromIsoString(xs['firstDateOnWebsite'], location: UTC),
        lastDateOnWebsite: Date.fromIsoString(xs['lastDateOnWebsite'], location: UTC),
        offerId: xs['offerId'],
    );
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
