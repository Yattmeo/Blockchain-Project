import { useState, useEffect } from 'react';
import { Box, Typography, Button, Chip, Alert, CircularProgress } from '@mui/material';
import { Add, CloudUpload } from '@mui/icons-material';
import { DataTable } from '../components/DataTable';
import type { Column } from '../components/DataTable';
import { WeatherDataForm } from '../components/forms/WeatherDataForm';
import { weatherOracleService } from '../services';
import type { WeatherData } from '../types/blockchain';

export const WeatherPage: React.FC = () => {
  const [weatherData, setWeatherData] = useState<WeatherData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [formOpen, setFormOpen] = useState(false);

  const columns: Column<WeatherData>[] = [
    { id: 'dataID', label: 'Data ID', minWidth: 120 },
    { id: 'oracleID', label: 'Oracle ID', minWidth: 120 },
    { id: 'farmerID', label: 'Farmer ID', minWidth: 120 },
    {
      id: 'location',
      label: 'Location',
      minWidth: 150,
    },
    {
      id: 'temperature',
      label: 'Temperature',
      minWidth: 100,
      align: 'right',
      format: (value) => `${value}°C`,
    },
    {
      id: 'rainfall',
      label: 'Rainfall',
      minWidth: 100,
      align: 'right',
      format: (value) => `${value} mm`,
    },
    {
      id: 'humidity',
      label: 'Humidity',
      minWidth: 100,
      align: 'right',
      format: (value) => `${value}%`,
    },
    {
      id: 'timestamp',
      label: 'Timestamp',
      minWidth: 150,
      format: (value) => new Date(value).toLocaleString(),
    },
    {
      id: 'status',
      label: 'Status',
      minWidth: 100,
      format: (value) => (
        <Chip
          label={value}
          color={value === 'Validated' ? 'success' : value === 'Rejected' ? 'error' : 'warning'}
          size="small"
        />
      ),
    },
  ];

  useEffect(() => {
    fetchWeatherData();
  }, []);

  const fetchWeatherData = async () => {
    try {
      setLoading(true);
      setError('');
      
      // Fetch weather data from multiple locations we know exist
      const locations = ['Central_Bangkok', 'North_ChiangMai', 'South_Songkhla'];
      const allData: WeatherData[] = [];
      
      for (const location of locations) {
        try {
          const response = await weatherOracleService.getWeatherDataByRegion(location);
          if (response.success && response.data) {
            const data = Array.isArray(response.data) ? response.data : [response.data];
            allData.push(...data);
          }
        } catch (err) {
          console.log(`No data found for ${location}`);
        }
      }
      
      setWeatherData(allData);
    } catch (err) {
      console.error('Failed to fetch weather data:', err);
      setError('Failed to load weather data');
    } finally {
      setLoading(false);
    }
  };

  const handleFormSuccess = () => {
    // Refresh weather data list
    fetchWeatherData();
    setFormOpen(false);
  };

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" gutterBottom fontWeight={600}>
            Weather Data Management
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Submit and validate weather oracle data
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => setFormOpen(true)}
        >
          Submit Data
        </Button>
      </Box>

      <Box sx={{ mb: 3, p: 2, bgcolor: 'info.light', borderRadius: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
          <CloudUpload />
          <Typography variant="subtitle1" fontWeight={600}>
            Automated Weather Data Integration (Future Feature)
          </Typography>
        </Box>
        <Typography variant="body2" color="text.secondary">
          Weather data can be automatically submitted through API endpoint connections with weather
          services (e.g., OpenWeatherMap, Weather.com). This feature will be implemented after
          core functionality is complete. Manual submission is available for testing and backup.
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {loading && weatherData.length === 0 ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}>
          <CircularProgress />
        </Box>
      ) : (
        <DataTable
          columns={columns}
          data={weatherData}
          loading={false}
          searchPlaceholder="Search weather data by ID, oracle, location..."
          emptyMessage="No weather data submitted yet. Click 'Submit Data' to add weather information."
        />
      )}

      <WeatherDataForm
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSuccess={handleFormSuccess}
      />
    </Box>
  );
};
