import React from 'react';
import { motion } from 'framer-motion';
import { CheckCircle, XCircle, AlertCircle } from 'lucide-react';

const Discrepancies = () => {
    const discrepancies = [
        { id: 'DSC-892', assignment: 'ASN-4091', agent: 'Alex Chen', item: 'Medical Kits', expected: 100, actual: 95, reason: 'Damaged in transit', status: 'Pending Review' },
        { id: 'DSC-893', assignment: 'ASN-4092', agent: 'John Doe', item: 'Rations', expected: 500, actual: 498, reason: 'Counting error at warehouse', status: 'Pending Review' },
    ];

    return (
        <div className="assignments-container">
            <div className="page-header">
                <div>
                    <h1>Discrepancy Approvals</h1>
                    <p className="subtitle">Review and verify field inventory variations</p>
                </div>
            </div>

            <div className="stats-grid" style={{ marginBottom: '1rem' }}>
                <div className="stat-card glass-panel" style={{ padding: '1rem 1.5rem' }}>
                    <div>
                        <h3 style={{ fontSize: '1.5rem', color: 'var(--warning)' }}>2</h3>
                        <p className="subtitle" style={{ fontSize: '0.85rem' }}>Pending Approvals</p>
                    </div>
                </div>
            </div>

            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="table-glass-container glass-panel">
                <div className="table-responsive">
                    <table className="premium-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Assignment</th>
                                <th>Agent</th>
                                <th>Item</th>
                                <th>Variance (Expected / Actual)</th>
                                <th>Stated Reason</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            {discrepancies.map((d) => (
                                <tr key={d.id}>
                                    <td className="font-medium text-primary-500">{d.id}</td>
                                    <td>{d.assignment}</td>
                                    <td>{d.agent}</td>
                                    <td>{d.item}</td>
                                    <td>
                                        <span style={{ color: 'var(--text-muted)' }}>{d.expected}</span> /
                                        <span style={{ color: 'var(--danger)', fontWeight: 600, marginLeft: '0.25rem' }}>{d.actual}</span>
                                    </td>
                                    <td>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.9rem' }}>
                                            <AlertCircle size={14} color="var(--warning)" />
                                            {d.reason}
                                        </div>
                                    </td>
                                    <td>
                                        <div style={{ display: 'flex', gap: '0.5rem' }}>
                                            <button className="btn btn-primary btn-sm" style={{ padding: '0.4rem 0.6rem' }}><CheckCircle size={16} /></button>
                                            <button className="btn btn-glass btn-sm text-danger" style={{ padding: '0.4rem 0.6rem' }}><XCircle size={16} /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </motion.div>
        </div>
    );
};

export default Discrepancies;
