enum BeltRank {
  white(1),
  yellow(2),
  orange(3),
  green(4),
  blue(5),
  red(6),
  black(7);

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
        return 'white-yellow';
      case BeltRank.yellow:
        return 'white-yellow';
      case BeltRank.orange:
        return 'orange';
      case BeltRank.green:
        return 'green-blue';
      case BeltRank.blue:
        return 'green-blue';
      case BeltRank.red:
        return 'red-black';
      case BeltRank.black:
        return 'red-black';
    }
  }

  static String getGroupName(BeltRank rank) {
    if (rank.order <= 2) return 'white-yellow';
    if (rank.order == 3) return 'orange';
    if (rank.order <= 5) return 'green-blue';
    return 'red-black';
  }

  static BeltRank? fromOrder(int order) {
    return BeltRank.values.firstWhere(
      (b) => b.order == order,
      orElse: () => BeltRank.white,
    );
  }
}
