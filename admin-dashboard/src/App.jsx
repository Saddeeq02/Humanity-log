import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Sidebar from './components/layout/Sidebar';
import DashboardOverview from './pages/DashboardOverview';
import AuthLogin from './pages/AuthLogin';
import Assignments from './pages/Assignments';
import Discrepancies from './pages/Discrepancies';
import AuditLogs from './pages/AuditLogs';
import UserManagement from './pages/UserManagement';
import Warehouse from './pages/Warehouse';
import './index.css';

// RBAC Protected Route Component
const ProtectedRoute = ({ children, allowedRoles }) => {
  const token = localStorage.getItem('shas_token');
  const role = localStorage.getItem('shas_role');

  if (!token) return <Navigate to="/login" replace />;
  if (allowedRoles && !allowedRoles.includes(role)) {
    return <Navigate to="/dashboard" replace />; // Fallback if unauthorized
  }
  return children;
};

const App = () => {
  const isAuthenticated = !!localStorage.getItem('shas_token');

  // Force redirect to login if not authenticated
  if (!isAuthenticated && window.location.pathname !== '/login') {
    window.history.pushState({}, '', '/login');
  }

  return (
    <Router>
      <div className="app-container">
        {isAuthenticated && <Sidebar />}
        <main className={isAuthenticated ? "main-content glass-panel" : "main-content-login"}>
          <Routes>
            <Route path="/login" element={!isAuthenticated ? <AuthLogin /> : <Navigate to="/dashboard" replace />} />

            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<ProtectedRoute><DashboardOverview /></ProtectedRoute>} />
            <Route path="/assignments" element={<ProtectedRoute><Assignments /></ProtectedRoute>} />
            <Route path="/discrepancies" element={<ProtectedRoute><Discrepancies /></ProtectedRoute>} />
            <Route path="/audits" element={<ProtectedRoute><AuditLogs /></ProtectedRoute>} />

            {/* Super Admin Only */}
            <Route path="/users" element={
              <ProtectedRoute allowedRoles={['superadmin']}>
                <UserManagement />
              </ProtectedRoute>
            } />
            <Route path="/warehouse" element={
              <ProtectedRoute allowedRoles={['superadmin']}>
                <Warehouse />
              </ProtectedRoute>
            } />
          </Routes>
        </main>
      </div>
    </Router>
  );
};

export default App;
