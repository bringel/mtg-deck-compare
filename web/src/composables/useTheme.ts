import { ref } from 'vue';

export const themeOptions = ['light', 'system', 'dark'] as const;
type Theme = (typeof themeOptions)[number];

const theme = ref<Theme>('system');

export function useTheme() {
  const setTheme = (newTheme: Theme) => {
    theme.value = newTheme;
    localStorage.setItem('theme', newTheme);

    document.documentElement.classList.toggle(
      'dark',
      newTheme === 'dark' ||
        (newTheme === 'system' && window.matchMedia('prefers-color-scheme: dark)').matches)
    );
  };

  const toggleTheme = () => {
    setTheme(theme.value === 'dark' ? 'light' : 'dark');
  };

  const initTheme = () => {
    const savedTheme = localStorage.getItem('theme') as Theme | null;

    setTheme(savedTheme ?? 'system');
  };

  return {
    theme,
    setTheme,
    toggleTheme,
    initTheme
  };
}
