import type { Card } from './Card';

export interface DeckSection {
  cards: Array<Card>;
  quantities: Record<string, number>;
}
