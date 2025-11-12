import axios from 'axios';
import type { PolicyTemplate, IndexThreshold } from '../types/blockchain';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3001/api';

export const policyTemplateService = {
  /**
   * Get all active policy templates
   */
  getAllTemplates: async (): Promise<PolicyTemplate[]> => {
    try {
      const response = await axios.get(`${API_BASE_URL}/policy-templates`);
      return response.data.data || [];
    } catch (error) {
      console.error('Error fetching policy templates:', error);
      throw error;
    }
  },

  /**
   * Get a specific policy template by ID
   */
  getTemplate: async (templateId: string): Promise<PolicyTemplate> => {
    try {
      const response = await axios.get(`${API_BASE_URL}/policy-templates/${templateId}`);
      return response.data.data;
    } catch (error) {
      console.error(`Error fetching template ${templateId}:`, error);
      throw error;
    }
  },

  /**
   * Get weather thresholds for a template
   */
  getTemplateThresholds: async (templateId: string): Promise<IndexThreshold[]> => {
    try {
      const response = await axios.get(`${API_BASE_URL}/policy-templates/${templateId}/thresholds`);
      return response.data.data || [];
    } catch (error) {
      console.error(`Error fetching thresholds for template ${templateId}:`, error);
      throw error;
    }
  },

  /**
   * Get templates by crop type
   */
  getTemplatesByCrop: async (cropType: string): Promise<PolicyTemplate[]> => {
    try {
      const response = await axios.get(`${API_BASE_URL}/policy-templates/by-crop/${cropType}`);
      return response.data.data || [];
    } catch (error) {
      console.error(`Error fetching templates for crop ${cropType}:`, error);
      throw error;
    }
  },

  /**
   * Get templates by region
   */
  getTemplatesByRegion: async (region: string): Promise<PolicyTemplate[]> => {
    try {
      const response = await axios.get(`${API_BASE_URL}/policy-templates/by-region/${region}`);
      return response.data.data || [];
    } catch (error) {
      console.error(`Error fetching templates for region ${region}:`, error);
      throw error;
    }
  },
};
