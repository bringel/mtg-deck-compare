export interface Card {
  name: string;
  set_code: string;
  set_number: number;
  mana_cost: string;
  converted_mana_cost: number;
  card_image_urls: string[];
  card_art_urls: string[];
  oracle_id: string;
  multiverse_ids: number[];
  scryfall_url: string;
  rarity: string;
  card_type: string;
}
