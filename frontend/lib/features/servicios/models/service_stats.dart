class ServiceStats {
  final int bookingsThisMonth;
  final double trendVsLastMonth;

  const ServiceStats({
    required this.bookingsThisMonth,
    required this.trendVsLastMonth,
  });

  static const zero = ServiceStats(bookingsThisMonth: 0, trendVsLastMonth: 0);
}
