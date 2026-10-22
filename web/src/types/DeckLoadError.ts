export type DeckLoadErrorCode =
  | 'unsupported_url'
  | 'deck_not_found'
  | 'source_blocked'
  | 'source_unavailable'
  | 'extraction_failed'
  | 'internal_error'
  | 'network_error';

export interface DeckLoadError {
  code: DeckLoadErrorCode;
  message: string;
  sourceType?: string | null;
  // a page the user can open themselves to copy the list from
  fallbackUrl?: string | null;
}
