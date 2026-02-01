import type { DeckSection } from './DeckSection';

export interface Deck {
  name: string;
  author: string;
  sourceType: string;
  sourceUrl: string;
  mainDeck?: DeckSection;
  sideboard?: DeckSection;
}
