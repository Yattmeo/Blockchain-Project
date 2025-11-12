import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { ProtectedRoute } from './components/ProtectedRoute';
import { DashboardLayout } from './layouts/DashboardLayout';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { FarmersPage } from './pages/FarmersPage';
import { PoliciesPage } from './pages/PoliciesPage';
import { PolicyTemplatesPage } from './pages/PolicyTemplatesPage';
import { ClaimsPage } from './pages/ClaimsPage';
import { WeatherPage } from './pages/WeatherPage';
import { PremiumPoolPage } from './pages/PremiumPoolPage';
import { SettingsPage } from './pages/SettingsPage';
import { UnauthorizedPage } from './pages/UnauthorizedPage';
import { ApprovalsPage } from './pages/ApprovalsPage';

function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            {/* Public routes */}
            <Route path="/login" element={<LoginPage />} />
            <Route path="/unauthorized" element={<UnauthorizedPage />} />

            {/* Protected routes */}
            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <DashboardLayout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Navigate to="/dashboard" replace />} />
              <Route path="dashboard" element={<DashboardPage />} />
              
              <Route
                path="farmers"
                element={
                  <ProtectedRoute allowedRoles={['coop', 'admin']}>
                    <FarmersPage />
                  </ProtectedRoute>
                }
              />
              
              <Route
                path="policies"
                element={
                  <ProtectedRoute allowedRoles={['insurer', 'coop', 'admin']}>
                    <PoliciesPage />
                  </ProtectedRoute>
                }
              />
              
              <Route
                path="policy-templates"
                element={
                  <ProtectedRoute allowedRoles={['insurer', 'coop', 'admin']}>
                    <PolicyTemplatesPage />
                  </ProtectedRoute>
                }
              />
              
              <Route
                path="claims"
                element={
                  <ProtectedRoute allowedRoles={['insurer', 'admin']}>
                    <ClaimsPage />
                  </ProtectedRoute>
                }
              />
              
              <Route
                path="weather"
                element={
                  <ProtectedRoute allowedRoles={['oracle', 'admin']}>
                    <WeatherPage />
                  </ProtectedRoute>
                }
              />
              
              <Route
                path="pool"
                element={
                  <ProtectedRoute allowedRoles={['insurer', 'admin']}>
                    <PremiumPoolPage />
                  </ProtectedRoute>
                }
              />
              
              <Route
                path="approvals"
                element={
                  <ProtectedRoute allowedRoles={['insurer', 'coop', 'admin']}>
                    <ApprovalsPage />
                  </ProtectedRoute>
                }
              />
              
              <Route path="settings" element={<SettingsPage />} />
            </Route>

            {/* Catch all */}
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
