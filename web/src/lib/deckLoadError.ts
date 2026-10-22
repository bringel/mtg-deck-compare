import { type DeckLoadError } from '../types/DeckLoadError';

const SOURCE_NAMES: Record<string, string> = {
  moxfield: 'Moxfield',
  archidekt: 'Archidekt',
  aetherhub: 'Aetherhub',
  deckstats: 'Deckstats',
  mtggoldfish: 'MTGGoldfish',
  mtg_decks: 'MTGDecks',
  manual: 'manual entry'
};

// Pulls the API's `{ error: {...} }` body out of a failed useFetch, falling back
// to a generic error when the request never got a JSON response
export function toDeckLoadError(data: unknown, error: unknown): DeckLoadError {
  const apiError = (data as { error?: DeckLoadError } | null)?.error;
  if (apiError?.code) {
    return apiError;
  }

  return {
    code: 'network_error',
    message: error instanceof Error ? error.message : String(error ?? 'Request failed')
  };
}

export function describeDeckLoadError(error: DeckLoadError | null | undefined): string {
  const site = (error?.sourceType && SOURCE_NAMES[error.sourceType]) || 'that site';

  switch (error?.code) {
    case 'unsupported_url':
      return "We don't know how to load decks from that URL yet.";
    case 'deck_not_found':
      return "We couldn't find that deck. It may be private or deleted.";
    case 'source_blocked':
      return `${site} isn't letting us load decks right now.`;
    case 'source_unavailable':
      return `We couldn't reach ${site}. It might be having trouble, so try again in a little bit.`;
    case 'extraction_failed':
      return `We loaded the page from ${site} but couldn't find the deck list on it. They may have changed their site.`;
    default:
      return "Sorry! We're having some trouble loading the deck from the URL you entered.";
  }
}
