import type { ComparisonDeckSection } from './ComparisonDeckSection';
import type { DeckSection } from './DeckSection';

export interface DeckComparison {
  common: {
    mainDeck: ComparisonDeckSection;
    sideboard: ComparisonDeckSection;
  };
  multiple: {
    mainDeck: ComparisonDeckSection;
    sideboard: ComparisonDeckSection;
  };
  decksRemaining: { [index: number]: { mainDeck: DeckSection; sideboard: DeckSection } };
}
