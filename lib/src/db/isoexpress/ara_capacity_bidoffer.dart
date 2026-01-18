class AraCapacityBidOfferArchive {
  AraCapacityBidOfferArchive({required this.dir, required this.duckDbPath});

  final String dir;
  final String duckDbPath;
  final String report =
      'Forward Capacity Market Annual Reconfiguration Auction Historical Bid Report';
}
