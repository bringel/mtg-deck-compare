// these are in display order for the UI
export const cardTypes = [
  'creature',
  'planeswalker',
  'instant',
  'sorcery',
  'artifact',
  'enchantment',
  'battle',
  'land'
] as const;

export type CardType = (typeof cardTypes)[number];

export interface Card {
  name: string;
  setCode: string;
  setNumber: number;
  manaCost: string;
  convertedManaCost: number;
  cardImageUrls: string[];
  cardArtUrls: string[];
  oracleId: string;
  multiverseIds: number[];
  scryfallUrl: string;
  rarity: string;
  cardType: CardType;
  layout: 'normal' | 'split' | 'aftermath' | 'flip' | 'battle' | 'dual';
}
