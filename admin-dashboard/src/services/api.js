import axios from 'axios';

// Connect to the local FastAPI backend running on port 8000
export const API_URL = import.meta.env.VITE_API_URL || 'https://humanity-log.onrender.com/api/v1';

export const apiClient = axios.create({
    baseURL: API_URL,
    headers: {
        'Content-Type': 'application/json',
    },
    timeout: 10000,
});

// Request Interceptor to attach Auth Token later in full JWT integration phase
apiClient.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('shas_token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);

export const AssignmentService = {
    getAll: () => apiClient.get('/assignments/all'),
    getActive: () => apiClient.get('/assignments/active'),
    getById: (id) => apiClient.get(`/assignments/${id}`),
    create: (data) => apiClient.post('/assignments/', data),
    update: (id, data) => apiClient.put(`/assignments/${id}`, data),
    delete: (id) => apiClient.delete(`/assignments/${id}`),
    getReport: (id) => apiClient.get(`/assignments/${id}/report`),
    complete: (id) => apiClient.post(`/assignments/${id}/complete`),
    suspend: (id) => apiClient.put(`/assignments/${id}/suspend`),
};

export const SyncService = {
    getActivity: () => apiClient.get('/sync/activity'),
    push: (payload) => apiClient.post('/sync/push', payload),
};

export const DiscrepancyService = {
    getAll: () => apiClient.get('/discrepancies'),
    approve: (id) => apiClient.post(`/discrepancies/${id}/approve`),
};

export const DashboardService = {
    getMetrics: () => apiClient.get('/dashboard/metrics'),
    getActivity: () => SyncService.getActivity(), // Reuse SyncService
};

export const UserService = {
    getAgents: () => apiClient.get('/users/agents'),
    getAll: () => apiClient.get('/users/all'),
    create: (userData) => apiClient.post('/users/', userData),
    delete: (userId) => apiClient.delete(`/users/${userId}`),
    resetPassword: (userId, new_password) => apiClient.put(`/users/${userId}/password`, { new_password })
};

export const InventoryService = {
    getAll: () => apiClient.get('/inventory/all'),
    getActive: () => apiClient.get('/inventory/active'),
    create: (data) => apiClient.post('/inventory/', data),
    suspend: (id) => apiClient.put(`/inventory/${id}/suspend`),
    delete: (id) => apiClient.delete(`/inventory/${id}`)
};

export const AuditService = {
    getAll: () => apiClient.get('/audits/all')
};
