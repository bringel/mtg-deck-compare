import type { ComparisonDeckSection } from './ComparisonDeckSection';
import type { DeckSection } from './DeckSection';

export interface DeckComparison {
  common: {
    main_deck: ComparisonDeckSection;
    sideboard: ComparisonDeckSection;
  };
  multiple: {
    main_deck: ComparisonDeckSection;
    sideboard: ComparisonDeckSection;
  };
  decks_remaining: { [index: number]: { main_deck: DeckSection; sideboard: DeckSection } };
}
