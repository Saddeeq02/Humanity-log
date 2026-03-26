import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Search, MapPin, CheckCircle, AlertTriangle, Loader2, RefreshCw, UserCheck } from 'lucide-react';
import { SyncService } from '../services/api';
import './DashboardOverview.css'; // Reusing established styles for consistency

const FieldActivity = () => {
    const [activities, setActivities] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');

    const fetchActivity = async () => {
        setLoading(true);
        try {
            const res = await SyncService.getActivity();
            if (res.data.status === 'success') {
                setActivities(res.data.data);
            }
        } catch (error) {
            console.error("Failed to fetch activity logs", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchActivity();
        // Setup a 30s auto-refresh for "Live" feel
        const interval = setInterval(fetchActivity, 30000);
        return () => clearInterval(interval);
    }, []);

    const filteredActivities = activities.filter(act => 
        act.agent_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        act.beneficiary_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        act.id.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="dashboard-container">
            <div className="dashboard-header">
                <div>
                    <h1 style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        Field Activity Logs
                        <span className="live-indicator"><div className="dot"></div>Live Stream</span>
                    </h1>
                    <p className="subtitle">Real-time synchronization feed of all aid distribution attempts and biometric captures</p>
                </div>
                <div style={{ display: 'flex', gap: '10px' }}>
                    <button className="btn btn-glass" onClick={fetchActivity}>
                        <RefreshCw size={18} style={{ marginRight: '8px' }} className={loading ? 'lucide-spin' : ''} />
                        Sync Data
                    </button>
                </div>
            </div>

            <div className="table-actions glass-panel" style={{ padding: '1.25rem', marginBottom: '1rem', border: '1px solid var(--border-light)' }}>
                <div className="search-bar input-with-icon" style={{ maxWidth: '100%' }}>
                    <Search className="input-icon" size={18} />
                    <input
                        type="text"
                        className="input-glass"
                        placeholder="Filter by Agent, Beneficiary, or Record ID..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
            </div>

            <div className="activity-feed glass-panel" style={{ flex: 1, padding: '1.5rem', overflowY: 'auto' }}>
                {loading && activities.length === 0 ? (
                    <div style={{ display: 'flex', justifyContent: 'center', margin: '4rem 0' }}>
                        <Loader2 size={48} className="lucide-spin" style={{ color: 'var(--primary-500)' }} />
                    </div>
                ) : filteredActivities.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: '4rem' }}>
                        <AlertTriangle size={48} style={{ color: 'var(--warning)', opacity: 0.5, margin: '0 auto 1rem' }} />
                        <p style={{ color: 'var(--text-200)' }}>No distribution records found matching your search.</p>
                    </div>
                ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                        {filteredActivities.map((item, index) => (
                            <motion.div
                                initial={{ opacity: 0, x: -10 }}
                                animate={{ opacity: 1, x: 0 }}
                                transition={{ delay: index * 0.05 }}
                                key={item.id}
                                style={{ 
                                    background: 'rgba(255, 255, 255, 0.02)', 
                                    border: '1px solid rgba(255, 255, 255, 0.05)',
                                    borderRadius: '12px',
                                    padding: '1.25rem',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '1.5rem',
                                    transition: 'background 0.2s'
                                }}
                                onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.04)'}
                                onMouseLeave={(e) => e.currentTarget.style.background = 'rgba(255, 255, 255, 0.02)'}
                            >
                                <div style={{ 
                                    width: '45px', hieght: '45px', borderRadius: '12px', 
                                    background: 'linear-gradient(135deg, var(--primary-600), var(--accent-600))',
                                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                                    flexShrink: 0
                                }}>
                                    <UserCheck size={20} color="white" />
                                </div>
                                <div style={{ flex: 1 }}>
                                    <h4 style={{ margin: '0 0 4px 0', fontSize: '1rem' }}>{item.agent_name}</h4>
                                    <p style={{ margin: 0, fontSize: '0.85rem', color: 'var(--text-300)' }}>
                                        {item.action}
                                    </p>
                                </div>
                                <div style={{ textAlign: 'center', padding: '0 1.5rem', borderLeft: '1px solid rgba(255,255,255,0.05)', borderRight: '1px solid rgba(255,255,255,0.05)' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '4px', justifyContent: 'center', marginBottom: '4px' }}>
                                        <MapPin size={12} color="var(--primary-400)" />
                                        <span style={{ fontSize: '0.75rem', fontFamily: 'monospace', color: 'var(--text-200)' }}>{item.location}</span>
                                    </div>
                                    <span style={{ fontSize: '0.65rem', color: 'var(--text-300)' }}>GPS COORDINATES</span>
                                </div>
                                <div style={{ textAlign: 'right', minWidth: '120px' }}>
                                    <span className={`status-pill ${item.status.toLowerCase()}`} style={{ marginBottom: '6px', display: 'inline-flex' }}>
                                        {item.status === 'Verified' ? <CheckCircle size={10} style={{ marginRight: '4px' }} /> : <AlertTriangle size={10} style={{ marginRight: '4px' }} />}
                                        {item.status}
                                    </span>
                                    <p style={{ margin: 0, fontSize: '0.75rem', color: 'var(--text-300)' }}>
                                        {new Date(item.timestamp).toLocaleTimeString()}
                                    </p>
                                </div>
                            </motion.div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
};

export default FieldActivity;
