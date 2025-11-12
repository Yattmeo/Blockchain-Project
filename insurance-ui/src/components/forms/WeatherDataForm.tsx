import { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Alert,
  CircularProgress,
} from '@mui/material';
import { useForm, Controller } from 'react-hook-form';
import { weatherOracleService } from '../../services';
import type { SubmitWeatherDataDto } from '../../services/weather.service';

interface WeatherDataFormProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const WeatherDataForm: React.FC<WeatherDataFormProps> = ({
  open,
  onClose,
  onSuccess,
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');

  const {
    control,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<SubmitWeatherDataDto>({
    defaultValues: {
      dataID: '',
      oracleID: '',
      farmerID: '',
      latitude: 0,
      longitude: 0,
      temperature: 0,
      rainfall: 0,
      humidity: 0,
      windSpeed: 0,
      timestamp: new Date().toISOString(),
    },
  });

  const onSubmit = async (data: SubmitWeatherDataDto) => {
    try {
      setLoading(true);
      setError('');

      const response = await weatherOracleService.submitWeatherData(data);

      if (response.success) {
        reset();
        onSuccess();
        onClose();
      } else {
        setError(response.error || 'Failed to submit weather data');
      }
    } catch (err) {
      setError('An error occurred while submitting weather data');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      reset();
      setError('');
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>Submit Weather Data</DialogTitle>
      <form onSubmit={handleSubmit(onSubmit)}>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <Alert severity="info" sx={{ mb: 2 }}>
            <strong>Note:</strong> In production, weather data can be automatically submitted via
            API endpoint integration with weather services. Manual submission is for testing and
            backup purposes.
          </Alert>

          <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
            <Controller
              name="dataID"
              control={control}
              rules={{ required: 'Data ID is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Data ID"
                  error={!!errors.dataID}
                  helperText={errors.dataID?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="oracleID"
              control={control}
              rules={{ required: 'Oracle ID is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Oracle ID"
                  error={!!errors.oracleID}
                  helperText={errors.oracleID?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="farmerID"
              control={control}
              rules={{ required: 'Farmer ID is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Farmer ID"
                  error={!!errors.farmerID}
                  helperText={errors.farmerID?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="timestamp"
              control={control}
              rules={{ required: 'Timestamp is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Timestamp"
                  type="datetime-local"
                  error={!!errors.timestamp}
                  helperText={errors.timestamp?.message}
                  fullWidth
                  InputLabelProps={{ shrink: true }}
                />
              )}
            />

            <Controller
              name="latitude"
              control={control}
              rules={{
                required: 'Latitude is required',
                min: { value: -90, message: 'Min: -90' },
                max: { value: 90, message: 'Max: 90' },
              }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Latitude"
                  type="number"
                  error={!!errors.latitude}
                  helperText={errors.latitude?.message}
                  fullWidth
                  inputProps={{ step: 0.000001 }}
                />
              )}
            />

            <Controller
              name="longitude"
              control={control}
              rules={{
                required: 'Longitude is required',
                min: { value: -180, message: 'Min: -180' },
                max: { value: 180, message: 'Max: 180' },
              }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Longitude"
                  type="number"
                  error={!!errors.longitude}
                  helperText={errors.longitude?.message}
                  fullWidth
                  inputProps={{ step: 0.000001 }}
                />
              )}
            />

            <Controller
              name="temperature"
              control={control}
              rules={{ required: 'Temperature is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Temperature (°C)"
                  type="number"
                  error={!!errors.temperature}
                  helperText={errors.temperature?.message}
                  fullWidth
                  inputProps={{ step: 0.1 }}
                />
              )}
            />

            <Controller
              name="rainfall"
              control={control}
              rules={{ required: 'Rainfall is required', min: 0 }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Rainfall (mm)"
                  type="number"
                  error={!!errors.rainfall}
                  helperText={errors.rainfall?.message}
                  fullWidth
                  inputProps={{ step: 0.1 }}
                />
              )}
            />

            <Controller
              name="humidity"
              control={control}
              rules={{
                required: 'Humidity is required',
                min: { value: 0, message: 'Min: 0%' },
                max: { value: 100, message: 'Max: 100%' },
              }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Humidity (%)"
                  type="number"
                  error={!!errors.humidity}
                  helperText={errors.humidity?.message}
                  fullWidth
                  inputProps={{ step: 0.1 }}
                />
              )}
            />

            <Controller
              name="windSpeed"
              control={control}
              rules={{ required: 'Wind speed is required', min: 0 }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Wind Speed (km/h)"
                  type="number"
                  error={!!errors.windSpeed}
                  helperText={errors.windSpeed?.message}
                  fullWidth
                  inputProps={{ step: 0.1 }}
                />
              )}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} disabled={loading}>
            Cancel
          </Button>
          <Button type="submit" variant="contained" disabled={loading}>
            {loading ? <CircularProgress size={24} /> : 'Submit Weather Data'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};
