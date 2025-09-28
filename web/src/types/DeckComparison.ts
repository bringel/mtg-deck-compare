import type { DeckSection } from './DeckSection';

interface Comparison {
  common: DeckSection;
  multiple: DeckSection;
  decks_remaining: { [index: number]: DeckSection };
}

export interface DeckComparison {
  main_deck: Comparison;
  sideboard: Comparison;
}
