import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:five_minus/features/gameplay/enums/enum_card_rank.dart';

import '../enums/enum_card_suit.dart';
import 'card_model.dart';

class Deck extends Equatable {
  final List<CardModel>? cardDeck;

  Deck({
    bool generateNewRandomDeck = false,
    List<CardModel>? list,
  }) : cardDeck = generateNewRandomDeck ? createRandomDeck() : list ?? [];

  // Function to create a standard deck of cards
  static List<CardModel> createRandomDeck() {
    // Define the suits and ranks
    List<CardSuit> suits = [
      CardSuit.diamonds,
      CardSuit.clubs,
      CardSuit.hearts,
      CardSuit.spades,
    ];
    List<CardRank> ranks = [
      CardRank.ace,
      CardRank.two,
      CardRank.three,
      CardRank.four,
      CardRank.five,
      CardRank.six,
      CardRank.seven,
      CardRank.eight,
      CardRank.nine,
      CardRank.ten,
      CardRank.jack,
      CardRank.queen,
      CardRank.king,
    ];

    // Create the deck by pairing each suit with each rank
    List<CardModel> deck = [];
    for (CardSuit suit in suits) {
      for (CardRank rank in ranks) {
        deck.add(CardModel(rank, suit));
      }
    }
    deck.shuffle();

    return deck;
  }

  shuffleDeck() {
    return cardDeck?.shuffle();
  }

  getCardFromDeck() {
    return cardDeck?.removeLast();
  }

  List<Map<String, dynamic>> toMapList() {
    return cardDeck?.map((x) => x.toMap()).toList() ?? [];
  }

  factory Deck.fromMapList(final List<dynamic> responseList) {
    List<CardModel> resultList = [];
    for (final item in responseList) {
      resultList.add(CardModel.fromMap(item));
    }
    return Deck(list: resultList);
  }

  String toJson() => json.encode(toMapList());

  factory Deck.fromJson(String source) => Deck.fromMapList(json.decode(source));

  @override
  // TODO: implement props
  List<Object?> get props => [cardDeck];
}
