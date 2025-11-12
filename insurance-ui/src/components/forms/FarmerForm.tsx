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
  MenuItem,
} from '@mui/material';
import { useForm, Controller } from 'react-hook-form';
import { farmerService } from '../../services';
import type { RegisterFarmerDto } from '../../services/farmer.service';
import { useAuth } from '../../contexts/AuthContext';

interface FarmerFormProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

const cropTypeOptions = [
  'Rice',
  'Wheat',
  'Maize',
  'Cotton',
  'Sugarcane',
  'Vegetables',
  'Fruits',
  'Pulses',
];

export const FarmerForm: React.FC<FarmerFormProps> = ({ open, onClose, onSuccess }) => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');
  const [selectedCropTypes, setSelectedCropTypes] = useState<string[]>([]);

  const {
    control,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<RegisterFarmerDto>({
    defaultValues: {
      farmerID: '',
      firstName: '',
      lastName: '',
      coopID: user?.orgId || '',
      phone: '',
      email: '',
      walletAddress: '',
      latitude: 0,
      longitude: 0,
      region: '',
      district: '',
      farmSize: 0,
      cropTypes: [],
      kycHash: '',
    },
  });

  const onSubmit = async (data: RegisterFarmerDto) => {
    try {
      setLoading(true);
      setError('');

      const formData = {
        ...data,
        cropTypes: selectedCropTypes,
        coopID: user?.orgId || data.coopID,
      };

      const response = await farmerService.registerFarmer(formData);

      if (response.success) {
        reset();
        setSelectedCropTypes([]);
        onSuccess();
        onClose();
      } else {
        setError(response.error || 'Failed to register farmer');
      }
    } catch (err) {
      setError('An error occurred while registering farmer');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      reset();
      setSelectedCropTypes([]);
      setError('');
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>Register New Farmer</DialogTitle>
      <form onSubmit={handleSubmit(onSubmit)}>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2 }}>
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
              name="firstName"
              control={control}
              rules={{ required: 'First name is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="First Name"
                  error={!!errors.firstName}
                  helperText={errors.firstName?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="lastName"
              control={control}
              rules={{ required: 'Last name is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Last Name"
                  error={!!errors.lastName}
                  helperText={errors.lastName?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="phone"
              control={control}
              rules={{ required: 'Phone is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Phone Number"
                  error={!!errors.phone}
                  helperText={errors.phone?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="email"
              control={control}
              rules={{
                required: 'Email is required',
                pattern: {
                  value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                  message: 'Invalid email address',
                },
              }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Email"
                  type="email"
                  error={!!errors.email}
                  helperText={errors.email?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="walletAddress"
              control={control}
              rules={{ required: 'Wallet address is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Wallet Address"
                  error={!!errors.walletAddress}
                  helperText={errors.walletAddress?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="region"
              control={control}
              rules={{ required: 'Region is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Region"
                  error={!!errors.region}
                  helperText={errors.region?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="district"
              control={control}
              rules={{ required: 'District is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="District"
                  error={!!errors.district}
                  helperText={errors.district?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="latitude"
              control={control}
              rules={{ required: 'Latitude is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Latitude"
                  type="number"
                  error={!!errors.latitude}
                  helperText={errors.latitude?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="longitude"
              control={control}
              rules={{ required: 'Longitude is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Longitude"
                  type="number"
                  error={!!errors.longitude}
                  helperText={errors.longitude?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="farmSize"
              control={control}
              rules={{ required: 'Farm size is required', min: 0 }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Farm Size (hectares)"
                  type="number"
                  error={!!errors.farmSize}
                  helperText={errors.farmSize?.message}
                  fullWidth
                />
              )}
            />

            <TextField
              select
              label="Crop Types"
              SelectProps={{ multiple: true }}
              value={selectedCropTypes}
              onChange={(e) => {
                const value = e.target.value;
                setSelectedCropTypes(typeof value === 'string' ? [value] : value);
              }}
              fullWidth
            >
              {cropTypeOptions.map((crop) => (
                <MenuItem key={crop} value={crop}>
                  {crop}
                </MenuItem>
              ))}
            </TextField>

            <Controller
              name="kycHash"
              control={control}
              rules={{ required: 'KYC Hash is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="KYC Document Hash"
                  error={!!errors.kycHash}
                  helperText={errors.kycHash?.message}
                  fullWidth
                  sx={{ gridColumn: '1 / -1' }}
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
            {loading ? <CircularProgress size={24} /> : 'Register Farmer'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};
