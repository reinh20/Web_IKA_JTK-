import axios from 'axios';
import { useAuthStore } from '@/stores/authStore';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use(
  (config) => {
    const token = useAuthStore.getState().token;
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Trigger session expired modal instead of redirecting immediately.
      // AdminLayout listens to this flag and shows a blocking dialog.
      useAuthStore.getState().setSessionExpired(true);
    }
    return Promise.reject(error);
  }
);

const apiHelper = {
  // --- ELECTION MANAGEMENT ---
  getElections: async (params?: any) => {
    const response = await api.get('/admin/elections', { params });
    return response.data;
  },

  getElectionById: async (id: string) => {
    const response = await api.get(`/admin/elections/${id}`);
    return response.data;
  },

  createElection: async (data: any) => {
    const response = await api.post('/admin/elections', data);
    return response.data;
  },

  updateElection: async (id: string, data: any) => {
    const response = await api.put(`/admin/elections/${id}`, data);
    return response.data;
  },

  deleteElection: async (id: string) => {
    const response = await api.delete(`/admin/elections/${id}`);
    return response.data;
  },

  // --- CANDIDATE MANAGEMENT ---
  addCandidate: async (electionId: string, data: any) => {
    const response = await api.post(`/admin/elections/${electionId}/candidates`, data);
    return response.data;
  },

  updateCandidate: async (electionId: string, candidateId: string, data: any) => {
    const response = await api.put(`/admin/elections/${electionId}/candidates/${candidateId}`, data);
    return response.data;
  },

  deleteCandidate: async (electionId: string, candidateId: string) => {
    const response = await api.delete(`/admin/elections/${electionId}/candidates/${candidateId}`);
    return response.data;
  },

  // --- ELECTION SUMMARY ---
  getElectionSummary: async (id: string) => {
    const response = await api.get(`/admin/elections/${id}/summary`);
    return response.data;
  },

  getAlumni: async (verified?: boolean) => {
    const url = verified ? '/admin/alumni?verified=true' : '/admin/alumni';
    const response = await api.get(url);
    return response.data;
  },

  // --- PORTAL CONFIG ---
  getPortalConfig: async () => {
    const response = await api.get('/admin/portal-config');
    return response.data;
  },

  getPublicPortalConfig: async () => {
    const response = await api.get('/portal/config');
    return response.data;
  },

  updatePortalConfig: async (data: any) => {
    const response = await api.put('/admin/portal-config', data);
    return response.data;
  },
};

const defaultApi = Object.assign(api, apiHelper);

export default defaultApi;
