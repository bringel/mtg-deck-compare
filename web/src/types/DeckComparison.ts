import type { ComparisonDeckSection, RemainingDeckSection } from './DeckSection';

interface Comparison {
  common: ComparisonDeckSection;
  multiple: ComparisonDeckSection;
  decks_remaining: { [index: number]: RemainingDeckSection };
}

export interface DeckComparison {
  main_deck: Comparison;
  sideboard: Comparison;
}
