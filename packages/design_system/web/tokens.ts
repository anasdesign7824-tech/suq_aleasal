export const assalColors = {
  primary: "#F39C12",
  primaryDark: "#9C5A00",
  primaryLight: "#FFA94D",
  secondary: "#8B5A2B",
  deepBrown: "#4F2E1F",
  honey: "#F39C12",
  honeyLight: "#FFF0D6",
  cream: "#F8F4EC",
  background: "#FCFAF7",
  surface: "#FFFFFF",
  surfaceVariant: "#F4EEE5",
  textPrimary: "#342118",
  textSecondary: "#6F5B4C",
  textMuted: "#9A897D",
  border: "#E8DCCB",
  success: "#4F7A45",
  warning: "#B86B1E",
  error: "#A64232",
  info: "#6B675C",
} as const;

export const assalSpacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  x2l: 32,
  x3l: 40,
  x4l: 48,
  x5l: 64,
} as const;

export const assalRadius = {
  small: 8,
  medium: 12,
  large: 18,
  extraLarge: 28,
  pill: 999,
} as const;

export const assalTypography = {
  family: "IBM Plex Sans Arabic",
  display: { size: 36, lineHeight: 48, weight: 700 },
  heading1: { size: 30, lineHeight: 40, weight: 700 },
  heading2: { size: 24, lineHeight: 34, weight: 600 },
  heading3: { size: 20, lineHeight: 30, weight: 600 },
  title: { size: 18, lineHeight: 28, weight: 600 },
  subtitle: { size: 16, lineHeight: 26, weight: 500 },
  bodyLarge: { size: 16, lineHeight: 28, weight: 400 },
  body: { size: 14, lineHeight: 24, weight: 400 },
  bodySmall: { size: 12, lineHeight: 20, weight: 400 },
  caption: { size: 11, lineHeight: 18, weight: 500 },
  button: { size: 14, lineHeight: 22, weight: 600 },
  label: { size: 12, lineHeight: 18, weight: 500 },
  navigation: { size: 13, lineHeight: 20, weight: 600 },
} as const;
