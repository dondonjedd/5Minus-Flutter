import 'package:flutter/material.dart';

enum CardSuit {
  clubs(1),
  spades(2),
  hearts(3),
  diamonds(4);

  final int internalRepresentation;

  const CardSuit(this.internalRepresentation);

  String get asCharacter => switch (this) { CardSuit.spades => '♠', CardSuit.hearts => '♥', CardSuit.diamonds => '♦', CardSuit.clubs => '♣' };

  Color get color => switch (this) { CardSuit.spades || CardSuit.clubs => Colors.black, CardSuit.hearts || CardSuit.diamonds => Colors.red };

  // Converts a Map representation back to a CardRank enum value
  static CardSuit? fromIr(int ir) {
    // Find the CardRank with matching internalRepresentation
    return CardSuit.values.firstWhere(
      (rank) => rank.internalRepresentation == ir,
      orElse: () => throw ArgumentError('Invalid suit value: $ir'),
    );
  }

  @override
  String toString() => asCharacter;
}
