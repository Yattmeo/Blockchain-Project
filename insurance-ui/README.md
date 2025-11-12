# Blockchain Insurance UI

React TypeScript web application for Hyperledger Fabric blockchain insurance platform with role-based dashboards.

## 🚀 Quick Start

### Prerequisites
- Node.js 20.19+ or 22.12+ (current: 21.1.0 - needs upgrade)
- npm 10+

### Installation

```bash
# Navigate to project
cd insurance-ui

# Install dependencies (already done)
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## 📁 Project Structure

```
src/
├── components/          # Reusable UI components
│   └── ProtectedRoute.tsx
├── config/              # Configuration files
│   └── api.ts          # API endpoints & settings
├── contexts/            # React contexts
│   ├── AuthContext.tsx # Authentication & user management
│   └── ThemeContext.tsx # MUI theme provider
├── layouts/             # Page layouts
│   └── DashboardLayout.tsx # Main dashboard layout
├── pages/               # Page components
│   ├── LoginPage.tsx
│   ├── DashboardPage.tsx
│   ├── FarmersPage.tsx
│   ├── PoliciesPage.tsx
│   ├── ClaimsPage.tsx
│   ├── WeatherPage.tsx
│   ├── PremiumPoolPage.tsx
│   ├── SettingsPage.tsx
│   └── UnauthorizedPage.tsx
├── services/            # API service layer
│   ├── api.service.ts  # Base Axios wrapper
│   ├── farmer.service.ts
│   ├── policy.service.ts
│   ├── weather.service.ts
│   ├── claim.service.ts
│   ├── premium-pool.service.ts
│   ├── access-control.service.ts
│   └── dashboard.service.ts
├── theme/               # MUI theme configuration
│   └── index.ts
├── types/               # TypeScript definitions
│   └── blockchain.ts
├── App.tsx              # Main app with routing
└── main.tsx             # Entry point
```

## 🎯 Features

### ✅ Implemented
- **Authentication System**: Role-based login with localStorage persistence
- **4 Role-Based Dashboards**: Insurer, Cooperative, Oracle, Admin
- **Protected Routes**: Role-based access control
- **Material-UI Components**: Professional, accessible UI
- **Dark/Light Theme**: Persistent theme preference
- **Responsive Layout**: Mobile-friendly sidebar navigation
- **Type-Safe API Layer**: 7 blockchain service modules
- **Complete Routing**: React Router v6 with nested routes

## 🔐 User Roles & Permissions

### 1. Insurance Company (Insurer)
- Create policy templates
- Set coverage thresholds
- Approve/reject claims
- View premium pool balance

### 2. Farmers Cooperative (Coop)
- Register farmers
- Update farmer profiles
- Create farmer policies
- View cooperative statistics

### 3. Weather Oracle
- Register as data provider
- Submit weather data
- Validate consensus

### 4. Platform Admin
- Register organizations
- Assign user roles
- View system-wide analytics

## 🌐 API Integration

The UI expects a REST API at `http://localhost:3001/api`. See `UI_STATUS.md` for complete endpoint documentation.

## 🛠️ Technologies

- **Build Tool**: Vite 7.2.1
- **Framework**: React 18
- **Language**: TypeScript 5
- **UI Library**: Material-UI 6
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Forms**: React Hook Form + Zod
- **Charts**: Recharts

## 📝 Documentation

- `UI_STATUS.md` - Detailed project status and API reference
- `../README.md` - Main blockchain documentation
- `../QUICKSTART.md` - Blockchain deployment guide

## 🐛 Known Issues

⚠️ **Node Version**: Current Node 21.1.0 is incompatible with Vite 7.2.1. Upgrade to Node 20.19+ or 22.12+.

## 📄 License

Part of the Hyperledger Fabric Insurance Platform project.
      tseslint.configs.stylisticTypeChecked,

      // Other configs...
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```

You can also install [eslint-plugin-react-x](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-x) and [eslint-plugin-react-dom](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-dom) for React-specific lint rules:

```js
// eslint.config.js
import reactX from 'eslint-plugin-react-x'
import reactDom from 'eslint-plugin-react-dom'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...
      // Enable lint rules for React
      reactX.configs['recommended-typescript'],
      // Enable lint rules for React DOM
      reactDom.configs.recommended,
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```
