import React, { createContext, useContext, useState, useEffect } from 'react';
import type { ReactNode } from 'react';
import type { User, UserRole } from '../types/blockchain';

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  login: (user: User, token: string) => void;
  logout: () => void;
  updateUser: (user: Partial<User>) => void;
  hasPermission: (permission: string) => boolean;
  isRole: (role: UserRole) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const STORAGE_KEYS = {
  USER: 'insurance_user',
  TOKEN: 'insurance_token',
};

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  // Load user from localStorage on mount
  useEffect(() => {
    const storedUser = localStorage.getItem(STORAGE_KEYS.USER);
    const storedToken = localStorage.getItem(STORAGE_KEYS.TOKEN);

    if (storedUser && storedToken) {
      try {
        const parsedUser = JSON.parse(storedUser) as User;
        setUser(parsedUser);
        setIsAuthenticated(true);
        // Ensure userOrg and userRole are set for API headers
        localStorage.setItem('userOrg', parsedUser.orgId);
        localStorage.setItem('userRole', parsedUser.role);
      } catch (error) {
        console.error('Failed to parse stored user:', error);
        // Clear invalid data
        localStorage.removeItem(STORAGE_KEYS.USER);
        localStorage.removeItem(STORAGE_KEYS.TOKEN);
        localStorage.removeItem('userOrg');
        localStorage.removeItem('userRole');
      }
    }
  }, []);

  const login = (newUser: User, token: string) => {
    setUser(newUser);
    setIsAuthenticated(true);
    localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(newUser));
    localStorage.setItem(STORAGE_KEYS.TOKEN, token);
    // Store userOrg separately for API headers
    localStorage.setItem('userOrg', newUser.orgId);
    localStorage.setItem('userRole', newUser.role);
  };

  const logout = () => {
    setUser(null);
    setIsAuthenticated(false);
    localStorage.removeItem(STORAGE_KEYS.USER);
    localStorage.removeItem(STORAGE_KEYS.TOKEN);
    localStorage.removeItem('userOrg');
    localStorage.removeItem('userRole');
  };

  const updateUser = (updates: Partial<User>) => {
    if (!user) return;

    const updatedUser = { ...user, ...updates };
    setUser(updatedUser);
    localStorage.setItem(STORAGE_KEYS.USER, JSON.stringify(updatedUser));
  };

  const hasPermission = (permission: string): boolean => {
    if (!user || !user.permissions) return false;
    return user.permissions.includes(permission);
  };

  const isRole = (role: UserRole): boolean => {
    return user?.role === role;
  };

  const value: AuthContextType = {
    user,
    isAuthenticated,
    login,
    logout,
    updateUser,
    hasPermission,
    isRole,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// Utility function to get token
export const getAuthToken = (): string | null => {
  return localStorage.getItem(STORAGE_KEYS.TOKEN);
};
