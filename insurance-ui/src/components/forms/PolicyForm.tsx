import { useState, useEffect } from 'react';
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
  Typography,
  Divider,
  Stack,
  Chip,
} from '@mui/material';
import { useForm, Controller } from 'react-hook-form';
import { policyService } from '../../services';
import { policyTemplateService } from '../../services/policyTemplateService';
import type { CreatePolicyDto } from '../../services/policy.service';
import type { PolicyTemplate } from '../../types/blockchain';

interface PolicyFormProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  farmerID?: string;
}

export const PolicyForm: React.FC<PolicyFormProps> = ({
  open,
  onClose,
  onSuccess,
  farmerID,
}) => {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>('');
  const [success, setSuccess] = useState<string>('');
  const [templates, setTemplates] = useState<PolicyTemplate[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<PolicyTemplate | null>(null);

  const {
    control,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors },
  } = useForm<CreatePolicyDto>({
    defaultValues: {
      policyID: '',
      farmerID: farmerID || '',
      templateID: '',
      coverageAmount: 0,
      premiumAmount: 0,
      startDate: new Date().toISOString().split('T')[0],
      endDate: '',
    },
  });

  const watchTemplateID = watch('templateID');
  const watchCoverageAmount = watch('coverageAmount');

  useEffect(() => {
    const fetchTemplates = async () => {
      try {
        const data = await policyTemplateService.getAllTemplates();
        setTemplates(data);
      } catch (error) {
        console.error('Error fetching templates:', error);
      }
    };
    if (open) {
      fetchTemplates();
    }
  }, [open]);

  useEffect(() => {
    if (watchTemplateID) {
      const template = templates.find((t) => t.templateID === watchTemplateID);
      setSelectedTemplate(template || null);
      if (template) {
        // Calculate premium based on template base rate and coverage
        const premium = watchCoverageAmount * template.pricingModel.baseRate;
        setValue('premiumAmount', Math.round(premium * 100) / 100);

        // Set end date based on coverage period (days)
        const startDate = new Date();
        const endDate = new Date(startDate);
        endDate.setDate(endDate.getDate() + template.coveragePeriod);
        setValue('endDate', endDate.toISOString().split('T')[0]);
      }
    }
  }, [watchTemplateID, watchCoverageAmount, templates, setValue]);

  const onSubmit = async (data: CreatePolicyDto) => {
    try {
      setLoading(true);
      setError('');
      setSuccess('');

      const response = await policyService.createPolicy(data);

      if (response.success) {
        setSuccess('Policy creation request submitted successfully! Waiting for insurer approval.');
        reset();
        // Keep dialog open briefly to show success message
        setTimeout(() => {
          setSuccess('');
          onSuccess();
          onClose();
        }, 2000);
      } else {
        setError(response.error || 'Failed to create policy request');
      }
    } catch (err) {
      setError('An error occurred while creating policy request');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    if (!loading) {
      reset();
      setError('');
      setSuccess('');
      onClose();
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>Create New Policy</DialogTitle>
      <form onSubmit={handleSubmit(onSubmit)}>
        <DialogContent>
          {error && (
            <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>
              {error}
            </Alert>
          )}

          {success && (
            <Alert severity="success" sx={{ mb: 2 }}>
              {success}
            </Alert>
          )}

          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <Controller
              name="policyID"
              control={control}
              rules={{ required: 'Policy ID is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Policy ID"
                  error={!!errors.policyID}
                  helperText={errors.policyID?.message}
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
                  disabled={!!farmerID}
                />
              )}
            />

            <Controller
              name="templateID"
              control={control}
              rules={{ required: 'Policy template is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  select
                  label="Policy Template"
                  error={!!errors.templateID}
                  helperText={errors.templateID?.message}
                  fullWidth
                >
                  {templates.map((template) => (
                    <MenuItem key={template.templateID} value={template.templateID}>
                      {template.templateName} ({template.cropType} • {template.region})
                    </MenuItem>
                  ))}
                </TextField>
              )}
            />

            {selectedTemplate && (
              <Box sx={{ p: 2, bgcolor: 'background.paper', borderRadius: 1, border: 1, borderColor: 'divider' }}>
                <Typography variant="subtitle2" gutterBottom fontWeight="bold">
                  Template Details
                </Typography>
                <Stack spacing={1} sx={{ mb: 2 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Coverage Period:</Typography>
                    <Typography variant="body2" fontWeight="medium">{selectedTemplate.coveragePeriod} days</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Max Coverage:</Typography>
                    <Typography variant="body2" fontWeight="medium">${selectedTemplate.maxCoverage.toLocaleString()}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Min Premium:</Typography>
                    <Typography variant="body2" fontWeight="medium">${selectedTemplate.minPremium.toLocaleString()}</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Base Rate:</Typography>
                    <Typography variant="body2" fontWeight="medium">{(selectedTemplate.pricingModel.baseRate * 100).toFixed(1)}%</Typography>
                  </Box>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Typography variant="body2" color="text.secondary">Risk Level:</Typography>
                    <Chip 
                      label={selectedTemplate.riskLevel} 
                      size="small"
                      color={selectedTemplate.riskLevel === 'Low' ? 'success' : selectedTemplate.riskLevel === 'High' ? 'error' : 'warning'}
                    />
                  </Box>
                </Stack>

                <Divider sx={{ my: 1.5 }} />

                <Typography variant="subtitle2" gutterBottom fontWeight="bold">
                  Weather Trigger Conditions
                </Typography>
                {selectedTemplate.indexThresholds && selectedTemplate.indexThresholds.length > 0 ? (
                  <Stack spacing={1}>
                    {selectedTemplate.indexThresholds.map((threshold, index) => (
                      <Box
                        key={index}
                        sx={{
                          p: 1,
                          borderRadius: 1,
                          bgcolor: threshold.severity === 'Mild' ? 'warning.light' : threshold.severity === 'Moderate' ? 'warning.main' : 'error.light',
                          color: threshold.severity === 'Mild' ? 'warning.dark' : threshold.severity === 'Moderate' ? 'warning.contrastText' : 'error.contrastText',
                        }}
                      >
                        <Typography variant="body2" fontWeight="medium">
                          {threshold.indexType} {threshold.operator} {threshold.thresholdValue}{threshold.metric} over {threshold.measurementDays} days
                        </Typography>
                        <Typography variant="caption">
                          → {threshold.payoutPercent}% payout • {threshold.severity} severity
                        </Typography>
                      </Box>
                    ))}
                  </Stack>
                ) : (
                  <Typography variant="body2" color="text.secondary" fontStyle="italic">
                    No weather conditions defined
                  </Typography>
                )}
              </Box>
            )}

            <Controller
              name="coverageAmount"
              control={control}
              rules={{
                required: 'Coverage amount is required',
                min: { value: 0, message: 'Must be positive' },
                max: {
                  value: selectedTemplate?.maxCoverage || 999999999,
                  message: `Max coverage is $${selectedTemplate?.maxCoverage.toLocaleString()}`,
                },
              }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Coverage Amount ($)"
                  type="number"
                  error={!!errors.coverageAmount}
                  helperText={errors.coverageAmount?.message}
                  fullWidth
                />
              )}
            />

            <Controller
              name="premiumAmount"
              control={control}
              rules={{ required: 'Premium amount is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Premium Amount ($)"
                  type="number"
                  error={!!errors.premiumAmount}
                  helperText={errors.premiumAmount?.message || 'Auto-calculated based on template'}
                  fullWidth
                  disabled
                />
              )}
            />

            <Controller
              name="startDate"
              control={control}
              rules={{ required: 'Start date is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="Start Date"
                  type="date"
                  error={!!errors.startDate}
                  helperText={errors.startDate?.message}
                  fullWidth
                  InputLabelProps={{ shrink: true }}
                />
              )}
            />

            <Controller
              name="endDate"
              control={control}
              rules={{ required: 'End date is required' }}
              render={({ field }) => (
                <TextField
                  {...field}
                  label="End Date"
                  type="date"
                  error={!!errors.endDate}
                  helperText={errors.endDate?.message || 'Auto-calculated based on template duration'}
                  fullWidth
                  InputLabelProps={{ shrink: true }}
                  disabled
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
            {loading ? <CircularProgress size={24} /> : 'Submit for Approval'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};
