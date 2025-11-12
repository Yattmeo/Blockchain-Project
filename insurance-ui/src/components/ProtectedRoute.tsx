import { Navigate } from 'react-router-dom';
import type { ReactNode } from 'react';
import { useAuth } from '../contexts/AuthContext';
import type { UserRole } from '../types/blockchain';

interface ProtectedRouteProps {
  children: ReactNode;
  allowedRoles?: UserRole[];
  requirePermission?: string;
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({
  children,
  allowedRoles,
  requirePermission,
}) => {
  const { isAuthenticated, user, hasPermission } = useAuth();

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && user && !allowedRoles.includes(user.role)) {
    return <Navigate to="/unauthorized" replace />;
  }

  if (requirePermission && !hasPermission(requirePermission)) {
    return <Navigate to="/unauthorized" replace />;
  }

  return <>{children}</>;
};
