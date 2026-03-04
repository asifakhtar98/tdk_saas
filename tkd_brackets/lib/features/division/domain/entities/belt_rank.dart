enum BeltRank {
  white(1),
  yellow(2),
  orange(3),
  green(4),
  blue(5),
  purple(6),
  brown(7),
  red(8),
  black(9);

  const BeltRank(this.order);

  final int order;

  static BeltRank? fromString(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll(' ', '');
    return BeltRank.values.firstWhere(
      (b) =>
          b.name.toLowerCase() == normalized ||
          b.name == 'white' && normalized == 'whiteyellow' ||
          b.name == 'yellow' && normalized == 'yellow' ||
          _getGroupMapping(b).toLowerCase() == normalized,
      orElse: () => BeltRank.white,
    );
  }

  static String _getGroupMapping(BeltRank rank) {
    switch (rank) {
      case BeltRank.white:
      case BeltRank.yellow:
        return 'white-yellow';
      case BeltRank.orange:
        return 'orange';
      case BeltRank.green:
      case BeltRank.blue:
      case BeltRank.purple:
        return 'green-blue';
      case BeltRank.brown:
      case BeltRank.red:
      case BeltRank.black:
        return 'red-black';
    }
  }

  static String getGroupName(BeltRank rank) {
    if (rank.order <= 2) return 'white-yellow';
    if (rank.order == 3) return 'orange';
    if (rank.order <= 6) return 'green-blue';
    return 'red-black';
  }

  static BeltRank? fromOrder(int order) {
    return BeltRank.values.firstWhere(
      (b) => b.order == order,
      orElse: () => BeltRank.white,
    );
  }
}
