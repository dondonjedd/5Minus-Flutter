import 'dart:convert';

import 'package:five_minus/features/gameplay/enums/enum_card_rank.dart';
import 'package:five_minus/features/gameplay/enums/enum_card_suit.dart';

class CardModel {
  final CardRank? rank;
  final CardSuit? suit;

  CardModel(this.rank, this.suit);

  @override
  String toString() {
    return '$rank of $suit';
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map.addAll(rank?.toMap());
    map.addAll(
      suit?.toMap(),
    );

    return map;
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      CardRank.fromIr(map['rank']),
      CardSuit.fromIr(map['suit']),
    );
  }

  String toJson() => json.encode(toMap());

  factory CardModel.fromJson(String source) => CardModel.fromMap(json.decode(source));
}
