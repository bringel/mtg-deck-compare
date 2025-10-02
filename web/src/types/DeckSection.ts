import type { Card } from './Card';

export interface DeckSection {
  cards: Card[];
  quantities: Record<string, Record<string, number>> | Record<string, number>;
}
