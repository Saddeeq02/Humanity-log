import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Activity, Search, Filter, Loader2, ShieldCheck, FileKey, ServerCrash } from 'lucide-react';
import { AuditService } from '../services/api';

const AuditLogs = () => {
    const [searchTerm, setSearchTerm] = useState('');
    const [logs, setLogs] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchLogs = async () => {
            try {
                const res = await AuditService.getAll();
                if (res.data.status === 'success') {
                    setLogs(res.data.data);
                }
            } catch (err) {
                console.error("Failed to fetch audit logs", err);
            } finally {
                setLoading(false);
            }
        };
        fetchLogs();
    }, []);

    const filteredLogs = logs.filter(log =>
        log.actor_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        log.actor_email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        log.action.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getActionIcon = (action) => {
        if (action.includes('AUTH')) return <ShieldCheck size={16} className="text-success" />;
        if (action.includes('PASSWORD')) return <FileKey size={16} className="text-warning" />;
        if (action.includes('DELETE') || action.includes('ERROR')) return <ServerCrash size={16} className="text-danger" />;
        return <Activity size={16} className="text-primary-500" />;
    };

    const getActionBadge = (action) => {
        let spanClass = 'pending';
        if (action.includes('AUTH')) spanClass = 'completed';
        else if (action.includes('DELETE')) spanClass = 'failed';
        else if (action.includes('ASSIGN')) spanClass = 'in_progress';

        return <span className={`status-badge ${spanClass}`}>{action}</span>;
    };

    return (
        <div className="assignments-container">
            <div className="page-header">
                <div>
                    <h1>System Audit Trails</h1>
                    <p className="subtitle">Immutable Global Security & Access Logging</p>
                </div>
                <button className="btn btn-primary" style={{ backgroundColor: 'var(--surface-3)', border: '1px solid var(--surface-4)', color: 'var(--text-200)' }}>
                    <Filter size={18} /> Export CSV
                </button>
            </div>

            <motion.div initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} className="table-glass-container glass-panel">
                <div className="table-actions">
                    <div className="search-bar input-with-icon">
                        <Search className="input-icon" size={18} />
                        <input type="text" className="input-glass" placeholder="Search by User, Email, or Event..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
                    </div>
                </div>

                <div className="table-responsive">
                    <table className="premium-table">
                        <thead>
                            <tr>
                                <th>Timestamp (UTC)</th>
                                <th>Actor Identification</th>
                                <th>Event Classification</th>
                                <th>Target Reference</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="4" style={{ textAlign: 'center', padding: '2rem' }}>
                                        <Loader2 size={24} className="lucide-spin" style={{ color: 'var(--primary-500)', margin: '0 auto' }} />
                                    </td>
                                </tr>
                            ) : filteredLogs.length === 0 ? (
                                <tr>
                                    <td colSpan="4" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-300)' }}>
                                        No recent systemic activity recorded.
                                    </td>
                                </tr>
                            ) : (
                                filteredLogs.map((log) => (
                                    <tr key={log.id}>
                                        <td style={{ color: 'var(--text-300)', fontSize: '0.85rem' }}>
                                            {new Date(log.timestamp).toLocaleString()}
                                        </td>
                                        <td>
                                            <div style={{ display: 'flex', flexDirection: 'column' }}>
                                                <span className="font-medium text-primary-500">{log.actor_name}</span>
                                                <span style={{ fontSize: '0.75rem', color: 'var(--text-400)' }}>{log.actor_email}</span>
                                            </div>
                                        </td>
                                        <td>
                                            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                                {getActionIcon(log.action)}
                                                {getActionBadge(log.action)}
                                            </div>
                                        </td>
                                        <td style={{ fontFamily: 'monospace', fontSize: '0.8rem', color: 'var(--text-400)' }}>
                                            {log.target_id || 'N/A'}
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </motion.div>
        </div>
    );
};

export default AuditLogs;
