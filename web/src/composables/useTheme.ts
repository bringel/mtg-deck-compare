import { useColorMode } from '@vueuse/core';

export const themeOptions = ['light', 'auto', 'dark'] as const;
export type Theme = (typeof themeOptions)[number];

export function useTheme() {
  return useColorMode({ emitAuto: true });
}
