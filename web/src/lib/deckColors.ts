export const deckColors = ['orange', 'cyan', 'violet', 'pink', 'white'] as const;

export type DeckColor = (typeof deckColors)[number];
