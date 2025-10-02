import type { Card } from './Card';

export interface ComparisonDeckSection {
  cards: Card[];
  quantities: Record<string, Record<string, number>>;
}

export interface RemainingDeckSection {
  cards: Card[];
  quantities: Record<string, number>;
}
