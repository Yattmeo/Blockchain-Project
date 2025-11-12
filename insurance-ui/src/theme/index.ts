import { createTheme } from '@mui/material/styles';
import type { ThemeOptions } from '@mui/material/styles';

// Custom color palette for insurance/blockchain theme
const palette = {
  primary: {
    main: '#1976d2', // Professional blue
    light: '#42a5f5',
    dark: '#1565c0',
    contrastText: '#fff',
  },
  secondary: {
    main: '#388e3c', // Green for success/approval
    light: '#66bb6a',
    dark: '#2e7d32',
    contrastText: '#fff',
  },
  error: {
    main: '#d32f2f',
    light: '#ef5350',
    dark: '#c62828',
  },
  warning: {
    main: '#f57c00',
    light: '#ff9800',
    dark: '#e65100',
  },
  info: {
    main: '#0288d1',
    light: '#03a9f4',
    dark: '#01579b',
  },
  success: {
    main: '#388e3c',
    light: '#66bb6a',
    dark: '#2e7d32',
  },
  background: {
    default: '#f5f7fa',
    paper: '#ffffff',
  },
  text: {
    primary: '#2c3e50',
    secondary: '#546e7a',
  },
};

const themeOptions: ThemeOptions = {
  palette,
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
    h1: {
      fontSize: '2.5rem',
      fontWeight: 600,
      lineHeight: 1.2,
    },
    h2: {
      fontSize: '2rem',
      fontWeight: 600,
      lineHeight: 1.3,
    },
    h3: {
      fontSize: '1.75rem',
      fontWeight: 600,
      lineHeight: 1.4,
    },
    h4: {
      fontSize: '1.5rem',
      fontWeight: 600,
      lineHeight: 1.4,
    },
    h5: {
      fontSize: '1.25rem',
      fontWeight: 600,
      lineHeight: 1.5,
    },
    h6: {
      fontSize: '1rem',
      fontWeight: 600,
      lineHeight: 1.6,
    },
    button: {
      textTransform: 'none',
      fontWeight: 500,
    },
  },
  shape: {
    borderRadius: 8,
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 8,
          padding: '8px 16px',
        },
        contained: {
          boxShadow: 'none',
          '&:hover': {
            boxShadow: '0px 2px 4px rgba(0,0,0,0.1)',
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          boxShadow: '0px 2px 8px rgba(0,0,0,0.08)',
        },
      },
    },
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 8,
        },
      },
    },
    MuiTextField: {
      defaultProps: {
        variant: 'outlined',
      },
    },
    MuiTableCell: {
      styleOverrides: {
        head: {
          fontWeight: 600,
          backgroundColor: '#f5f7fa',
        },
      },
    },
  },
};

export const theme = createTheme(themeOptions);

// Dark theme variant
export const darkTheme = createTheme({
  ...themeOptions,
  palette: {
    mode: 'dark',
    primary: palette.primary,
    secondary: palette.secondary,
    background: {
      default: '#0a1929',
      paper: '#1e2732',
    },
    text: {
      primary: '#e3f2fd',
      secondary: '#b0bec5',
    },
  },
});
