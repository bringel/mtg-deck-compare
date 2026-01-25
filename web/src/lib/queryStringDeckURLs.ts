export function decodeDeckURLs(queryStringDecks: string) {
  return JSON.parse(atob(decodeURIComponent(queryStringDecks)));
}

export function encodeDeckURLs(deckURLs: string[]) {
  return encodeURIComponent(btoa(JSON.stringify(deckURLs)));
}
