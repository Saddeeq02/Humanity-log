import React, { useState, useEffect } from 'react';
import { Users, AlertTriangle, CheckCircle, MapPin, Loader2 } from 'lucide-react';
import { motion } from 'framer-motion';
import { DashboardService } from '../services/api';
import './DashboardOverview.css';

const DashboardOverview = () => {
    const [metrics, setMetrics] = useState(null);
    const [activities, setActivities] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchDashboardData = async () => {
            try {
                const [metricsRes, activityRes] = await Promise.all([
                    DashboardService.getMetrics(),
                    DashboardService.getActivity()
                ]);

                if (metricsRes.data.status === 'success') {
                    setMetrics(metricsRes.data.data);
                }
                if (activityRes.data.status === 'success') {
                    setActivities(activityRes.data.data);
                }
            } catch (error) {
                console.error("Dashboard fetch error:", error);
            } finally {
                setLoading(false);
            }
        };

        fetchDashboardData();
    }, []);

    const stats = [
        {
            title: 'Total Beneficiaries',
            value: metrics ? metrics.total_beneficiaries : 0,
            icon: Users, color: 'var(--primary-500)',
            trend: 'Registered base'
        },
        {
            title: 'Active Assignments',
            value: metrics ? metrics.active_assignments : 0,
            icon: MapPin, color: 'var(--accent-500)',
            trend: 'Pending tasks'
        },
        {
            title: 'Distributions Logged',
            value: metrics ? metrics.distributions_today : 0,
            icon: CheckCircle, color: 'var(--success)',
            trend: 'Total successful'
        },
        {
            title: 'Reported Discrepancies',
            value: metrics ? metrics.reported_discrepancies : 0,
            icon: AlertTriangle, color: 'var(--warning)',
            trend: 'Requires attention'
        },
    ];

    return (
        <div className="dashboard-container">
            <div className="dashboard-header">
                <div>
                    <h1>Operations Overview</h1>
                    <p className="subtitle">Real-time monitoring of all active field operations</p>
                </div>
                <button className="btn btn-primary">Generate Report</button>
            </div>

            {loading ? (
                <div style={{ display: 'flex', justifyContent: 'center', margin: '4rem 0' }}>
                    <Loader2 size={48} className="lucide-spin" style={{ color: 'var(--primary-500)' }} />
                </div>
            ) : (
                <>
                    <div className="stats-grid">
                        {stats.map((stat, index) => (
                            <motion.div
                                initial={{ opacity: 0, y: 20 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ delay: index * 0.1 }}
                                key={stat.title}
                                className="stat-card glass-panel"
                            >
                                <div className="stat-icon-wrapper" style={{ color: stat.color, background: `${stat.color}15` }}>
                                    <stat.icon size={24} />
                                </div>
                                <div className="stat-content">
                                    <h3>{stat.value}</h3>
                                    <p>{stat.title}</p>
                                    <span className="trend">{stat.trend}</span>
                                </div>
                            </motion.div>
                        ))}
                    </div>

                    <div className="dashboard-main-content">
                        <motion.div
                            initial={{ opacity: 0, scale: 0.98 }}
                            animate={{ opacity: 1, scale: 1 }}
                            transition={{ delay: 0.4 }}
                            className="map-widget glass-panel"
                        >
                            <div className="widget-header">
                                <h3>Live Field Map</h3>
                                <span className="live-indicator"><div className="dot"></div>Live</span>
                            </div>
                            <div className="map-placeholder">
                                <div className="map-overlay-text">
                                    <MapPin size={48} className="map-pin-icon" />
                                    <p>Geospatial Visualization Layer</p>
                                    <span>Monitoring Active Bounds...</span>
                                </div>
                            </div>
                        </motion.div>

                        <motion.div
                            initial={{ opacity: 0, x: 20 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ delay: 0.5 }}
                            className="activity-feed glass-panel"
                        >
                            <div className="widget-header">
                                <h3>Recent System Activity</h3>
                                <button className="btn btn-glass btn-sm">View Archive</button>
                            </div>
                            <div className="feed-list">
                                {activities.length === 0 ? (
                                    <p style={{ color: 'var(--text-300)', textAlign: 'center', marginTop: '2rem' }}>
                                        No recent distribution activity yet.
                                    </p>
                                ) : activities.map((item) => (
                                    <div key={item.id} className="feed-item">
                                        <div className={`feed-avatar ${item.status === 'Flagged' ? 'warning' : ''}`}>
                                            {item.agent_name.charAt(0)}
                                        </div>
                                        <div className="feed-info">
                                            <p className="feed-action">
                                                <span className="font-bold">{item.agent_name}</span>: {item.action}
                                            </p>
                                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%', marginTop: '4px' }}>
                                                <p className="feed-meta">{new Date(item.timestamp).toLocaleTimeString()}</p>
                                                <span className={`status-pill ${item.status.toLowerCase()}`}>
                                                    {item.status === 'Verified' ? <CheckCircle size={10} style={{ marginRight: '4px' }} /> : <AlertTriangle size={10} style={{ marginRight: '4px' }} />}
                                                    {item.status}
                                                </span>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </motion.div>
                    </div>
                </>
            )}
        </div>
    );
};

export default DashboardOverview;
