import apiService from './api.service';
import { ENDPOINTS } from '../config/api';
import type { WeatherData, OracleProvider, ApiResponse } from '../types/blockchain';
import { generateMockWeatherData } from '../utils/mockData';

export interface RegisterOracleDto {
  oracleID: string;
  oracleName: string;
  location: string;
  apiEndpoint: string;
  publicKey: string;
}

export interface SubmitWeatherDataDto {
  dataID: string;
  oracleID: string;
  farmerID: string;
  latitude: number;
  longitude: number;
  temperature: number;
  rainfall: number;
  humidity: number;
  windSpeed: number;
  timestamp: string;
}

export const weatherOracleService = {
  /**
   * Register a new oracle provider
   */
  async registerOracle(data: RegisterOracleDto): Promise<ApiResponse<OracleProvider>> {
    const mockOracle: OracleProvider = {
      oracleID: data.oracleID,
      providerName: data.oracleName,
      providerType: 'API',
      dataSources: [data.apiEndpoint],
      reputationScore: 100,
      status: 'Active',
      registeredDate: new Date().toISOString(),
    };
    return apiService.post<OracleProvider>(ENDPOINTS.WEATHER_ORACLE.REGISTER_PROVIDER, data, undefined, mockOracle);
  },

  /**
   * Submit weather data
   */
  async submitWeatherData(data: SubmitWeatherDataDto): Promise<ApiResponse<WeatherData>> {
    const mockWeatherData: WeatherData = {
      dataID: data.dataID,
      oracleID: data.oracleID,
      location: `${data.latitude},${data.longitude}`,
      timestamp: data.timestamp,
      temperature: data.temperature,
      rainfall: data.rainfall,
      humidity: data.humidity,
      dataHash: `0x${Math.random().toString(16).substr(2, 64)}`,
      status: 'Pending',
      submittedDate: new Date().toISOString(),
    };
    return apiService.post<WeatherData>(ENDPOINTS.WEATHER_ORACLE.SUBMIT_DATA, data, undefined, mockWeatherData);
  },

  /**
   * Get weather data by ID
   */
  async getWeatherData(dataID: string): Promise<ApiResponse<WeatherData>> {
    const mockData = generateMockWeatherData(1)[0];
    return apiService.get<WeatherData>(`${ENDPOINTS.WEATHER_ORACLE.GET_DATA}/${dataID}`, undefined, mockData);
  },

  /**
   * Get weather data by region
   */
  async getWeatherDataByRegion(region: string): Promise<ApiResponse<WeatherData[]>> {
    const mockData = generateMockWeatherData(15);
    return apiService.get<WeatherData[]>(`${ENDPOINTS.WEATHER_ORACLE.GET_BY_REGION}/${region}`, undefined, mockData);
  },

  /**
   * Validate weather data consensus
   */
  async validateConsensus(dataID: string): Promise<ApiResponse<{ validated: boolean }>> {
    const mockResult = { validated: true };
    // Backend expects POST /api/weather-oracle/:dataId/validate
    return apiService.post<{ validated: boolean }>(
      `${ENDPOINTS.WEATHER_ORACLE.VALIDATE_CONSENSUS}/${dataID}/validate`,
      undefined,
      undefined,
      mockResult
    );
  },
};
