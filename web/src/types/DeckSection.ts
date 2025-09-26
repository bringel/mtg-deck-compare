import type { Card } from './Card';

export interface DeckSection {
  cards: Card[];
  quantities: Record<string, number>;
}