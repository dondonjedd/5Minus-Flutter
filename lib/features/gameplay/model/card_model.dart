import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:five_minus/features/gameplay/enums/enum_card_power.dart';
import 'package:five_minus/features/gameplay/enums/enum_card_rank.dart';
import 'package:five_minus/features/gameplay/enums/enum_card_suit.dart';

class CardModel extends Equatable {
  final CardRank? rank;
  final CardSuit? suit;
  final CardPower? cardPower;
  final int? cardValue;

  CardModel(
    this.rank,
    this.suit,
  )   : cardValue = getValue(rank, suit),
        cardPower = getPower(rank, suit);

  @override
  String toString() {
    return '$rank of $suit';
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank?.internalRepresentation,
      'suit': suit?.internalRepresentation,
      'power': cardPower?.internalRepresentation,
      'value': cardValue
    };
  }

  static CardPower getPower(CardRank? rank, CardSuit? suit) {
    if (rank == null || suit == null) return CardPower.none;
    CardPower res = CardPower.none;

    switch (rank) {
      case CardRank.jack:
        res = CardPower.swap;
        break;
      case CardRank.queen:
        res = CardPower.look;
        break;

      case CardRank.king:
        if (suit == CardSuit.diamonds || suit == CardSuit.hearts) {
          res = CardPower.none;
        } else {
          res = CardPower.sabotage;
        }
        break;
      default:
        res = CardPower.none;
        break;
    }

    return res;
  }

  static int getValue(CardRank? rank, CardSuit? suit) {
    if (rank == null || suit == null) return 0;
    int res = 0;

    switch (rank) {
      case CardRank.jack || CardRank.queen:
        res = 10;
        break;

      case CardRank.king:
        if (suit == CardSuit.diamonds || suit == CardSuit.hearts) {
          res = 0;
        } else {
          res = 10;
        }
        break;
      default:
        res = rank.internalRepresentation;
        break;
    }

    return res;
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      CardRank.fromIr(map['rank']),
      CardSuit.fromIr(map['suit']),
    );
  }

  String toJson() => json.encode(toMap());

  factory CardModel.fromJson(String source) => CardModel.fromMap(json.decode(source));

  @override
  List<Object?> get props => [rank, suit];
}
