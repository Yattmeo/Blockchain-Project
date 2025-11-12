import { useState } from 'react';
import type { ReactElement } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import {
  Box,
  Drawer,
  AppBar,
  Toolbar,
  List,
  Typography,
  Divider,
  IconButton,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Avatar,
  Menu,
  MenuItem,
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  People as PeopleIcon,
  Description as PolicyIcon,
  Assessment as ClaimIcon,
  Cloud as WeatherIcon,
  AccountBalance as PoolIcon,
  Settings as SettingsIcon,
  Logout as LogoutIcon,
  Brightness4,
  Brightness7,
  ThumbsUpDown as ApprovalIcon,
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';

const drawerWidth = 260;

interface NavItem {
  text: string;
  icon: ReactElement;
  path: string;
  roles: string[];
}

const navItems: NavItem[] = [
  {
    text: 'Dashboard',
    icon: <DashboardIcon />,
    path: '/dashboard',
    roles: ['insurer', 'coop', 'oracle', 'admin'],
  },
  {
    text: 'Farmers',
    icon: <PeopleIcon />,
    path: '/farmers',
    roles: ['coop', 'admin'],
  },
  {
    text: 'Policies',
    icon: <PolicyIcon />,
    path: '/policies',
    roles: ['insurer', 'coop', 'admin'],
  },
  {
    text: 'Policy Templates',
    icon: <PolicyIcon />,
    path: '/policy-templates',
    roles: ['insurer', 'coop', 'admin'],
  },
  {
    text: 'Claims',
    icon: <ClaimIcon />,
    path: '/claims',
    roles: ['insurer', 'admin'],
  },
  {
    text: 'Approvals',
    icon: <ApprovalIcon />,
    path: '/approvals',
    roles: ['insurer', 'coop', 'admin'],
  },
  {
    text: 'Weather Data',
    icon: <WeatherIcon />,
    path: '/weather',
    roles: ['oracle', 'admin'],
  },
  {
    text: 'Premium Pool',
    icon: <PoolIcon />,
    path: '/pool',
    roles: ['insurer', 'admin'],
  },
  {
    text: 'Settings',
    icon: <SettingsIcon />,
    path: '/settings',
    roles: ['insurer', 'coop', 'oracle', 'admin'],
  },
];

export const DashboardLayout: React.FC = () => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const { user, logout } = useAuth();
  const { mode, toggleTheme } = useTheme();
  const navigate = useNavigate();

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const handleNavigation = (path: string) => {
    navigate(path);
    if (mobileOpen) {
      setMobileOpen(false);
    }
  };

  const filteredNavItems = navItems.filter((item) =>
    user ? item.roles.includes(user.role) : false
  );

  const drawer = (
    <Box>
      <Toolbar>
        <Typography variant="h6" noWrap component="div" sx={{ fontWeight: 600 }}>
          Insurance Platform
        </Typography>
      </Toolbar>
      <Divider />
      <List>
        {filteredNavItems.map((item) => (
          <ListItem key={item.text} disablePadding>
            <ListItemButton onClick={() => handleNavigation(item.path)}>
              <ListItemIcon>{item.icon}</ListItemIcon>
              <ListItemText primary={item.text} />
            </ListItemButton>
          </ListItem>
        ))}
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar
        position="fixed"
        sx={{
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          ml: { sm: `${drawerWidth}px` },
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
            {user ? `${user.role.charAt(0).toUpperCase()}${user.role.slice(1)} Dashboard` : 'Dashboard'}
          </Typography>
          <IconButton color="inherit" onClick={toggleTheme} sx={{ mr: 1 }}>
            {mode === 'dark' ? <Brightness7 /> : <Brightness4 />}
          </IconButton>
          <IconButton onClick={handleMenuOpen} sx={{ p: 0 }}>
            <Avatar sx={{ bgcolor: 'secondary.main' }}>
              {user?.name.charAt(0).toUpperCase()}
            </Avatar>
          </IconButton>
          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleMenuClose}
            anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
          >
            <MenuItem disabled>
              <Typography variant="body2">{user?.name}</Typography>
            </MenuItem>
            <MenuItem disabled>
              <Typography variant="caption" color="text.secondary">
                {user?.orgId}
              </Typography>
            </MenuItem>
            <Divider />
            <MenuItem onClick={handleLogout}>
              <ListItemIcon>
                <LogoutIcon fontSize="small" />
              </ListItemIcon>
              Logout
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>
      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
      >
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          mt: 8,
        }}
      >
        <Outlet />
      </Box>
    </Box>
  );
};
