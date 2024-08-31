enum CardPower {
  none(0),
  look(1),
  swap(2),
  sabotage(3);

  final int internalRepresentation;

  const CardPower(this.internalRepresentation);

  static CardPower? fromIr(int ir) {
    // Find the CardRank with matching internalRepresentation
    return CardPower.values.firstWhere(
      (rank) => rank.internalRepresentation == ir,
      orElse: () => throw ArgumentError('Invalid rank value: $ir'),
    );
  }
}
