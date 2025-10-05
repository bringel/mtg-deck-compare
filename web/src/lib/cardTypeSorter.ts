import type { Card, CardType } from '../types/Card';

export function groupByCardTypes(cards: Array<Card>): { [k in CardType]: Array<Card> } {
  const cardTypes: { [k in CardType]: Array<Card> } = {
    artifact: [],
    battle: [],
    creature: [],
    enchantment: [],
    instant: [],
    land: [],
    planeswalker: [],
    sorcery: []
  };

  cards.forEach((card) => {
    cardTypes[card.card_type] = [...cardTypes[card.card_type], card];
  });

  return cardTypes;
}
