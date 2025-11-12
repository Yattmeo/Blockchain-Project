import { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  CircularProgress,
  Alert,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Stack,
} from '@mui/material';
import { PolicyTemplateCard } from '../components/PolicyTemplateCard';
import { policyTemplateService } from '../services/policyTemplateService';
import type { PolicyTemplate } from '../types/blockchain';

export const PolicyTemplatesPage: React.FC = () => {
  const [templates, setTemplates] = useState<PolicyTemplate[]>([]);
  const [filteredTemplates, setFilteredTemplates] = useState<PolicyTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedTemplate, setSelectedTemplate] = useState<string | null>(null);
  
  // Filters
  const [cropFilter, setCropFilter] = useState<string>('All');
  const [regionFilter, setRegionFilter] = useState<string>('All');
  const [riskFilter, setRiskFilter] = useState<string>('All');

  useEffect(() => {
    fetchTemplates();
  }, []);

  useEffect(() => {
    applyFilters();
  }, [templates, cropFilter, regionFilter, riskFilter]);

  const fetchTemplates = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await policyTemplateService.getAllTemplates();
      setTemplates(data);
      setFilteredTemplates(data);
    } catch (err: any) {
      console.error('Error fetching templates:', err);
      setError(err.message || 'Failed to fetch policy templates');
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let filtered = [...templates];

    if (cropFilter !== 'All') {
      filtered = filtered.filter(t => t.cropType === cropFilter);
    }

    if (regionFilter !== 'All') {
      filtered = filtered.filter(t => t.region === regionFilter);
    }

    if (riskFilter !== 'All') {
      filtered = filtered.filter(t => t.riskLevel === riskFilter);
    }

    setFilteredTemplates(filtered);
  };

  const handleSelectTemplate = (template: PolicyTemplate) => {
    setSelectedTemplate(template.templateID === selectedTemplate ? null : template.templateID);
  };

  // Extract unique values for filters
  const cropTypes = ['All', ...new Set(templates.map(t => t.cropType))];
  const regions = ['All', ...new Set(templates.map(t => t.region))];
  const riskLevels = ['All', 'Low', 'Medium', 'High'];

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Policy Templates
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Browse available insurance policy templates and their weather trigger conditions
        </Typography>
      </Box>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Filters */}
      <Box sx={{ mb: 3 }}>
        <Stack direction="row" spacing={2}>
          <FormControl sx={{ minWidth: 150 }} size="small">
            <InputLabel>Crop Type</InputLabel>
            <Select
              value={cropFilter}
              label="Crop Type"
              onChange={(e) => setCropFilter(e.target.value)}
            >
              {cropTypes.map(crop => (
                <MenuItem key={crop} value={crop}>{crop}</MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl sx={{ minWidth: 150 }} size="small">
            <InputLabel>Region</InputLabel>
            <Select
              value={regionFilter}
              label="Region"
              onChange={(e) => setRegionFilter(e.target.value)}
            >
              {regions.map(region => (
                <MenuItem key={region} value={region}>{region}</MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl sx={{ minWidth: 150 }} size="small">
            <InputLabel>Risk Level</InputLabel>
            <Select
              value={riskFilter}
              label="Risk Level"
              onChange={(e) => setRiskFilter(e.target.value)}
            >
              {riskLevels.map(risk => (
                <MenuItem key={risk} value={risk}>{risk}</MenuItem>
              ))}
            </Select>
          </FormControl>
        </Stack>
      </Box>

      {/* Templates Grid */}
      {filteredTemplates.length === 0 ? (
        <Alert severity="info">
          No policy templates found matching your criteria.
        </Alert>
      ) : (
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: {
              xs: '1fr',
              md: 'repeat(2, 1fr)',
              lg: 'repeat(3, 1fr)',
            },
            gap: 3,
          }}
        >
          {filteredTemplates.map((template) => (
            <PolicyTemplateCard
              key={template.templateID}
              template={template}
              onSelect={handleSelectTemplate}
              selected={selectedTemplate === template.templateID}
            />
          ))}
        </Box>
      )}

      {/* Stats */}
      <Box sx={{ mt: 4, p: 2, bgcolor: 'background.paper', borderRadius: 1 }}>
        <Typography variant="body2" color="text.secondary">
          Showing {filteredTemplates.length} of {templates.length} policy templates
        </Typography>
      </Box>
    </Box>
  );
};
