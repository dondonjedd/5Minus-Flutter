enum CardRank {
  ace(1, 'A'),
  two(2, '2'),
  three(3, '3'),
  four(4, '4'),
  five(5, '5'),
  six(6, '6'),
  seven(7, '7'),
  eight(8, '8'),
  nine(9, '9'),
  ten(10, '10'),
  jack(11, 'J'),
  queen(12, 'Q'),
  king(13, 'K');

  final int internalRepresentation;
  final String asCharacter;

  const CardRank(this.internalRepresentation, this.asCharacter);

  static CardRank? fromIr(int ir) {
    // Find the CardRank with matching internalRepresentation
    return CardRank.values.firstWhere(
      (rank) => rank.internalRepresentation == ir,
      orElse: () => throw ArgumentError('Invalid rank value: $ir'),
    );
  }

  @override
  String toString() => asCharacter;
}
