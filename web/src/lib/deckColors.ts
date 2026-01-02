export const deckColors = ['orange', 'sky', 'violet', 'pink', 'white'] as const;

export type DeckColor = (typeof deckColors)[number];
