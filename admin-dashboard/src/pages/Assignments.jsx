import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, Filter, Plus, MoreVertical, X, Loader2, MapPin, PackagePlus, Trash2, CheckCircle, AlertTriangle, ShieldAlert, Play, Eye } from 'lucide-react';
import { AssignmentService, UserService, InventoryService } from '../services/api';
import './Assignments.css';

const NewAssignmentModal = ({ isOpen, onClose, onAssignmentCreated, editingAssignment = null }) => {
    const [agents, setAgents] = useState([]);
    const [inventory, setInventory] = useState([]);
    const [loadingAgents, setLoadingAgents] = useState(false);

    // Form State
    const [selectedAgent, setSelectedAgent] = useState('');
    const [address, setAddress] = useState('');
    const [latitude, setLatitude] = useState(null);
    const [longitude, setLongitude] = useState(null);
    const [isGeocoding, setIsGeocoding] = useState(false);

    const [durationDays, setDurationDays] = useState(1);
    const [radiusKm, setRadiusKm] = useState(1.0);
    const [allocatedItems, setAllocatedItems] = useState([]); // [{inventory_id, quantity}]
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        if (isOpen) {
            fetchInitialData();
            if (editingAssignment) {
                // Populate Edit Mode
                setAddress(editingAssignment.address || '');
                setLatitude(editingAssignment.latitude || null);
                setLongitude(editingAssignment.longitude || null);
                setDurationDays(editingAssignment.duration_days || 1);
                setRadiusKm(editingAssignment.radius_km || 1.0);
                setSelectedAgent(editingAssignment.user_id || '');
                // For allocated items, we might need a more complex fetch if they aren't in the base object
                // But for now let's assume summary is enough or we fetch by ID
            } else {
                // Reset for Create Mode
                setAddress('');
                setLatitude(null);
                setLongitude(null);
                setDurationDays(1);
                setRadiusKm(1.0);
                setAllocatedItems([]);
                setSelectedAgent('');
            }
        }
    }, [isOpen, editingAssignment]);

    const fetchInitialData = async () => {
        setLoadingAgents(true);
        try {
            const [agentsRes, invRes] = await Promise.all([
                UserService.getAgents(),
                InventoryService.getActive()
            ]);

            if (agentsRes.data.status === 'success') {
                setAgents(agentsRes.data.data);
                if (agentsRes.data.data.length > 0) setSelectedAgent(agentsRes.data.data[0].id);
            }
            if (invRes.data.status === 'success') {
                setInventory(invRes.data.data);
            }
        } catch (error) {
            console.error("Failed to fetch starting data", error);
        } finally {
            setLoadingAgents(false);
        }
    };

    const handleGeocode = async () => {
        if (!address.trim()) return;
        setIsGeocoding(true);
        try {
            const response = await fetch(`https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(address)}&format=json&limit=1`);
            const data = await response.json();

            if (data && data.length > 0) {
                setLatitude(parseFloat(data[0].lat));
                setLongitude(parseFloat(data[0].lon));
            } else {
                alert("Could not locate address using OpenStreetMap. Please try a different query.");
            }
        } catch (error) {
            console.error("Geocoding failed", error);
        } finally {
            setIsGeocoding(false);
        }
    };

    const handleAddItem = (e) => {
        e.preventDefault();
        // Just push an empty shell to let the user select
        setAllocatedItems([...allocatedItems, { inventory_id: '', quantity: 1 }]);
    };

    const updateItem = (index, field, value) => {
        const updated = [...allocatedItems];
        if (field === 'quantity') {
            updated[index][field] = parseInt(value) || 0;
        } else {
            updated[index][field] = value;
        }
        setAllocatedItems(updated);
    };

    const removeItem = (index) => {
        const updated = allocatedItems.filter((_, i) => i !== index);
        setAllocatedItems(updated);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!selectedAgent || latitude === null || longitude === null) {
            alert("Please accurately geocode the address before dispatching.");
            return;
        }

        // Filter out items without an ID or zero quantity securely
        const cleanItems = allocatedItems.filter(i => i.inventory_id !== '' && i.quantity > 0);

        setIsSubmitting(true);
        try {
            const payload = {
                user_id: selectedAgent,
                status: editingAssignment ? editingAssignment.status : 'pending',
                geo_fence_polygon: 'radius-based',
                address: address,
                latitude: latitude,
                longitude: longitude,
                duration_days: parseInt(durationDays),
                radius_km: parseFloat(radiusKm),
                allocated_items: cleanItems
            };

            const res = editingAssignment
                ? await AssignmentService.update(editingAssignment.id, payload)
                : await AssignmentService.create(payload);

            if (res.data.status === 'success') {
                onAssignmentCreated();
                onClose();
            }
        } catch (error) {
            console.error("Failed to process assignment", error);
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <div className="modal-backdrop">
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        exit={{ opacity: 0, scale: 0.95 }}
                        className="modal-content glass-panel"
                        style={{ maxWidth: '650px', maxHeight: '90vh', overflowY: 'auto' }}
                    >
                        <div className="modal-header">
                            <h2>{editingAssignment ? 'Edit Mission Parameters' : 'Create Smart Geo-Assignment'}</h2>
                            <button className="icon-btn" onClick={onClose}><X size={20} /></button>
                        </div>

                        <form className="modal-body" onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label>Assign to Field Agent</label>
                                {loadingAgents ? (
                                    <div className="input-glass" style={{ display: 'flex', alignItems: 'center' }}>
                                        <Loader2 size={16} className="lucide-spin" style={{ marginRight: '8px' }} /> Loading Agents...
                                    </div>
                                ) : (
                                    <select
                                        className="input-glass"
                                        value={selectedAgent}
                                        onChange={(e) => setSelectedAgent(e.target.value)}
                                        required
                                    >
                                        <option value="" disabled>Select an Agent</option>
                                        {agents.map(agent => (
                                            <option key={agent.id} value={agent.id}>{agent.name} ({agent.email})</option>
                                        ))}
                                    </select>
                                )}
                            </div>

                            <div className="form-group">
                                <label>Mission Base Address (Auto-Geocodes via OSM)</label>
                                <div style={{ display: 'flex', gap: '10px' }}>
                                    <input
                                        type="text"
                                        className="input-glass"
                                        placeholder="e.g. 15 Rue de Rivoli, Paris"
                                        value={address}
                                        onChange={(e) => {
                                            setAddress(e.target.value);
                                            setLatitude(null);
                                            setLongitude(null);
                                        }}
                                        required
                                        style={{ flex: 1 }}
                                    />
                                    <button type="button" className="btn btn-secondary" onClick={handleGeocode} disabled={isGeocoding || !address}>
                                        {isGeocoding ? <Loader2 size={16} className="lucide-spin" /> : 'Find GPS'}
                                    </button>
                                </div>
                                {latitude && (
                                    <p style={{ marginTop: '0.5rem', fontSize: '0.85rem', color: 'var(--success)', display: 'flex', alignItems: 'center' }}>
                                        <MapPin size={14} style={{ marginRight: '4px' }} /> Secured Coordinate: {latitude.toFixed(4)}, {longitude.toFixed(4)}
                                    </p>
                                )}
                            </div>

                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
                                <div className="form-group">
                                    <label>Action Radius Coverage (km)</label>
                                    <input
                                        type="number"
                                        step="0.1" min="0.1"
                                        className="input-glass"
                                        value={radiusKm}
                                        onChange={(e) => setRadiusKm(e.target.value)}
                                        required
                                    />
                                </div>

                                <div className="form-group">
                                    <label>Mission Duration (Days)</label>
                                    <input
                                        type="number"
                                        min="1"
                                        className="input-glass"
                                        value={durationDays}
                                        onChange={(e) => setDurationDays(e.target.value)}
                                        required
                                    />
                                </div>
                            </div>

                            <hr style={{ borderColor: 'var(--border-color)', margin: '1rem 0' }} />

                            <div className="form-group">
                                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                                    <label style={{ margin: 0 }}>Aid Item Dispatchment</label>
                                    <button className="btn btn-glass btn-sm" onClick={handleAddItem}>
                                        <PackagePlus size={14} style={{ marginRight: '4px' }} /> Add Unit
                                    </button>
                                </div>

                                {allocatedItems.length === 0 ? (
                                    <div style={{ padding: '1rem', textAlign: 'center', background: 'var(--glass-bg)', borderRadius: '8px', border: '1px dashed var(--border-color)', color: 'var(--text-300)', fontSize: '0.9rem' }}>
                                        No payload added. The agent will only be performing geographic field verifications.
                                    </div>
                                ) : (
                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                                        {allocatedItems.map((item, idx) => (
                                            <div key={idx} style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                                                <select
                                                    className="input-glass"
                                                    style={{ flex: 1 }}
                                                    value={item.inventory_id}
                                                    onChange={(e) => updateItem(idx, 'inventory_id', e.target.value)}
                                                    required
                                                >
                                                    <option value="" disabled>Select Inventory Resource</option>
                                                    {inventory.map(inv => (
                                                        <option key={inv.id} value={inv.id}>{inv.name} (Stock: {inv.current_stock})</option>
                                                    ))}
                                                </select>

                                                <input
                                                    type="number"
                                                    className="input-glass"
                                                    style={{ width: '80px' }}
                                                    min="1"
                                                    value={item.quantity}
                                                    onChange={(e) => updateItem(idx, 'quantity', e.target.value)}
                                                    required
                                                />

                                                <button type="button" className="icon-btn" onClick={() => removeItem(idx)} style={{ color: 'var(--warning)' }}>
                                                    <X size={18} />
                                                </button>
                                            </div>
                                        ))}
                                    </div>
                                )}
                            </div>

                            <div className="modal-actions" style={{ marginTop: '2rem' }}>
                                <button type="button" className="btn btn-glass" onClick={onClose}>Cancel</button>
                                <button type="submit" className="btn btn-primary" disabled={isSubmitting || !selectedAgent || latitude === null}>
                                    {isSubmitting ? <Loader2 size={16} className="lucide-spin" /> : (editingAssignment ? 'Update Assignment' : 'Dispatch Assignment')}
                                </button>
                            </div>
                        </form>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
};

const Assignments = () => {
    const [searchTerm, setSearchTerm] = useState('');
    const [assignments, setAssignments] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingAssignment, setEditingAssignment] = useState(null);

    // New state for Review & Close
    const [reviewModalOpen, setReviewModalOpen] = useState(false);
    const [currentReport, setCurrentReport] = useState(null);
    const [isCompleting, setIsCompleting] = useState(false);

    const fetchAssignments = async () => {
        setLoading(true);
        try {
            const res = await AssignmentService.getAll();
            if (res.data.status === 'success') {
                setAssignments(res.data.data);
            }
        } catch (error) {
            console.error("Failed to fetch assignments", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAssignments();
    }, []);

    const handleDeleteAssignment = async (id) => {
        try {
            const res = await AssignmentService.delete(id);
            if (res.data.status === 'success') {
                fetchAssignments();
            }
        } catch (error) {
            console.error("Delete failed", error);
            alert("Failed to delete assignment.");
        }
    };

    const handleSuspendAssignment = async (id) => {
        try {
            const res = await AssignmentService.suspend(id);
            if (res.data.status === 'success') {
                fetchAssignments();
            }
        } catch (error) {
            console.error("Suspend failed", error);
            alert("Failed to update status.");
        }
    };

    const handleReviewMission = async (id) => {
        try {
            const res = await AssignmentService.getReport(id);
            if (res.data.status === 'success') {
                setCurrentReport(res.data.data);
                setReviewModalOpen(true);
            }
        } catch (error) {
            console.error("Fetch report failed", error);
            alert("Failed to load mission report.");
        }
    };

    const handleCompleteMission = async (id) => {
        setIsCompleting(true);
        try {
            const res = await AssignmentService.complete(id);
            if (res.data.status === 'success') {
                setReviewModalOpen(false);
                fetchAssignments();
                alert("Mission successfully completed and archived.");
            }
        } catch (error) {
            console.error("Completion failed", error);
            alert("Failed to finalize mission.");
        } finally {
            setIsCompleting(false);
        }
    };

    const filteredAssignments = assignments.filter(asn =>
        asn.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (asn.address && asn.address.toLowerCase().includes(searchTerm.toLowerCase())) ||
        asn.status.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="assignments-container">
            <div className="page-header">
                <div>
                    <h1>Assignments Management</h1>
                    <p className="subtitle">Track and assign inventory tasks to field agents with Geo-Verification</p>
                </div>
                <button className="btn btn-primary" onClick={() => { setEditingAssignment(null); setIsModalOpen(true); }}>
                    <Plus size={18} /> New Assignment
                </button>
            </div>

            <NewAssignmentModal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                editingAssignment={editingAssignment}
                onAssignmentCreated={() => fetchAssignments()}
            />

            <motion.div
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                className="table-glass-container glass-panel"
            >
                <div className="table-actions">
                    <div className="search-bar input-with-icon">
                        <Search className="input-icon" size={18} />
                        <input
                            type="text"
                            className="input-glass"
                            placeholder="Search by ID, Address, or Status..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                    <button className="btn btn-glass">
                        <Filter size={18} /> Filter
                    </button>
                </div>

                <div className="table-responsive">
                    <table className="premium-table">
                        <thead>
                            <tr>
                                <th>Assignment ID</th>
                                <th>Agent ID</th>
                                <th>Address / Base</th>
                                <th>Items Allocated</th>
                                <th>Radius (km)</th>
                                <th>Status</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="7" style={{ textAlign: 'center', padding: '2rem' }}>
                                        <Loader2 size={24} className="lucide-spin" style={{ color: 'var(--primary-500)', margin: '0 auto' }} />
                                    </td>
                                </tr>
                            ) : filteredAssignments.length === 0 ? (
                                <tr>
                                    <td colSpan="7" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-300)' }}>
                                        No assignments found matching that criteria.
                                    </td>
                                </tr>
                            ) : (
                                filteredAssignments.map((asn) => (
                                    <tr key={asn.id}>
                                        <td className="font-medium text-primary-500" style={{ fontSize: '0.85rem' }}>{asn.id.split('-')[0] + '...'}</td>
                                        <td>
                                            <div className="agent-cell" style={{ fontSize: '0.85rem' }}>
                                                <div className="agent-avatar-small">{asn.user_id.charAt(0)}</div>
                                                {asn.user_id.split('-')[0] + '...'}
                                            </div>
                                        </td>
                                        <td>{asn.address || asn.geo_fence_polygon}</td>
                                        <td style={{ fontSize: '0.85rem', color: 'var(--text-200)', maxWidth: '200px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                                            {asn.allocated_items_summary}
                                        </td>
                                        <td>{asn.radius_km || 1.0} km</td>
                                        <td>
                                            <span className={`status-badge ${asn.status.toLowerCase()}`}>
                                                {asn.status.replace('_', ' ')}
                                            </span>
                                        </td>
                                        <td>
                                            <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                                                {asn.status === 'reconciling' ? (
                                                    <button
                                                        className="btn btn-primary btn-sm"
                                                        onClick={() => handleReviewMission(asn.id)}
                                                        style={{ padding: '4px 8px', fontSize: '0.75rem' }}
                                                    >
                                                        Review & Close
                                                    </button>
                                                ) : (
                                                    <>
                                                        <button 
                                                            className="action-btn" 
                                                            onClick={() => handleReviewMission(asn.id)}
                                                            title="View Live Progress"
                                                        >
                                                            <Eye size={16} color="var(--primary-400)" />
                                                        </button>
                                                        <button 
                                                            className="action-btn" 
                                                            onClick={() => handleSuspendAssignment(asn.id)}
                                                            title={asn.status === 'suspended' ? "Reactivate Mission" : "Suspend Mission"}
                                                        >
                                                            {asn.status === 'suspended' ? 
                                                                <Play size={16} color="var(--status-success)" /> : 
                                                                <ShieldAlert size={16} color="var(--warning)" />
                                                            }
                                                        </button>
                                                        <button
                                                            className="action-btn"
                                                            onClick={() => {
                                                                if (window.confirm('Are you sure you want to delete this assignment? All track logs will be removed.')) {
                                                                    handleDeleteAssignment(asn.id);
                                                                }
                                                            }}
                                                            title="Delete Assignment"
                                                        >
                                                            <Trash2 size={16} color="var(--status-error)" />
                                                        </button>
                                                    </>
                                                )}
                                                <button 
                                                    className="action-btn" 
                                                    onClick={() => { setEditingAssignment(asn); setIsModalOpen(true); }}
                                                    title="Edit Mission Parameters"
                                                >
                                                    <MoreVertical size={18} />
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                // End of row
                                ))
                            )}
                        </tbody>
                    </table>
                </div>

                {/* Mission Review Modal */}
                {reviewModalOpen && currentReport && (
                    <div className="modal-overlay">
                        <motion.div
                            initial={{ opacity: 0, scale: 0.95 }}
                            animate={{ opacity: 1, scale: 1 }}
                            className="modal-content"
                            style={{ maxWidth: '750px', width: '90%' }}
                        >
                            <div className="modal-header">
                                <div>
                                    <h2 className="modal-title">Mission Intelligence Review</h2>
                                    <p className="modal-subtitle">Assignment ID: {currentReport.id.split('-')[0]}...</p>
                                </div>
                                <button className="close-btn" onClick={() => setReviewModalOpen(false)}><X size={24} /></button>
                            </div>

                            <div className="modal-body">
                                <div className="metrics-grid" style={{ gridTemplateColumns: 'repeat(3, 1fr)', gap: '1rem', marginBottom: '1.5rem' }}>
                                    <div className="metric-card-lite">
                                        <span className="metric-label">Beneficiaries Capture</span>
                                        <span className="metric-value-small">{currentReport.beneficiary_count}</span>
                                    </div>
                                    <div className="metric-card-lite">
                                        <span className="metric-label">GPS Discrepancies</span>
                                        <span className="metric-value-small" style={{ color: currentReport.flags > 0 ? 'var(--status-error)' : 'var(--status-success)' }}>
                                            {currentReport.flags}
                                        </span>
                                    </div>
                                    <div className="metric-card-lite">
                                        <span className="metric-label">Operations Status</span>
                                        <span className={`status-badge ${currentReport.status.toLowerCase()}`}>
                                            {currentReport.status}
                                        </span>
                                    </div>
                                </div>

                                {/* System Audit Intelligence Banner */}
                                <div className="audit-intelligence-banner" style={{ 
                                    background: 'rgba(255, 255, 255, 0.03)', 
                                    border: '1px solid var(--border-light)', 
                                    borderRadius: '16px', 
                                    padding: '1.25rem', 
                                    marginBottom: '1.5rem',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '1.25rem'
                                }}>
                                    <div className={`audit-bar ${(currentReport.flags === 0 && currentReport.inventory.every(inv => inv.distributed === currentReport.beneficiary_count && (inv.assigned - (inv.distributed + inv.returned) === 0))) ? 'good' : 'flagged'}`} style={{
                                        width: '8px',
                                        height: '60px',
                                        borderRadius: '4px',
                                        background: (currentReport.flags === 0 && currentReport.inventory.every(inv => inv.distributed === currentReport.beneficiary_count && (inv.assigned - (inv.distributed + inv.returned) === 0))) ? 'var(--status-success)' : 'var(--status-error)'
                                    }}></div>
                                    <div style={{ flex: 1 }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                                            <ShieldAlert size={18} color={(currentReport.flags === 0 && currentReport.inventory.every(inv => inv.distributed === currentReport.beneficiary_count && (inv.assigned - (inv.distributed + inv.returned) === 0))) ? 'var(--status-success)' : 'var(--status-error)'} />
                                            <h4 style={{ margin: 0, fontSize: '1rem', fontWeight: '700' }}>
                                                {(currentReport.flags === 0 && currentReport.inventory.every(inv => inv.distributed === currentReport.beneficiary_count && (inv.assigned - (inv.distributed + inv.returned) === 0))) ? 'AUDIT VERIFIED: MISSION INTEGRITY SECURE' : 'AUDIT ALERT: DISCREPANCIES DETECTED'}
                                            </h4>
                                        </div>
                                        <p style={{ fontSize: '0.8rem', color: 'var(--text-300)', margin: 0 }}>
                                            {(currentReport.flags === 0 && currentReport.inventory.every(inv => inv.distributed === currentReport.beneficiary_count && (inv.assigned - (inv.distributed + inv.returned) === 0))) 
                                                ? 'System audit confirms 100% GPS compliance and perfect physical-to-digital inventory reconciliation.' 
                                                : `Discrepancy: ${currentReport.flags > 0 ? `${currentReport.flags} Location Mismatch(es).` : ''} ${currentReport.inventory.some(inv => (inv.assigned - (inv.distributed + inv.returned)) !== 0) ? 'Physical Warehouse Variance detected.' : ''}`}
                                        </p>
                                    </div>
                                    <div style={{ textAlign: 'right' }}>
                                        <span style={{ 
                                            display: 'block', 
                                            fontSize: '1.25rem', 
                                            fontWeight: '800', 
                                            color: (currentReport.flags === 0 && currentReport.inventory.every(inv => inv.distributed === currentReport.beneficiary_count && (inv.assigned - (inv.distributed + inv.returned) === 0))) ? 'var(--status-success)' : 'var(--status-error)' 
                                        }}>
                                            {(currentReport.flags === 0 && currentReport.inventory.every(inv => inv.distributed === currentReport.beneficiary_count && (inv.assigned - (inv.distributed + inv.returned) === 0))) ? 'PASS' : 'FAIL'}
                                        </span>
                                        <span style={{ fontSize: '0.6rem', color: 'var(--text-300)', letterSpacing: '1px' }}>SYSTEM RECON SCORE</span>
                                    </div>
                                </div>

                                <h3 style={{ fontSize: '1rem', marginBottom: '0.75rem', color: 'var(--text-100)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    <PackagePlus size={18} /> Physical & Digital Reconciliation (Variance Check)
                                </h3>
                                <table className="data-table" style={{ marginBottom: '1.5rem' }}>
                                    <thead>
                                        <tr>
                                            <th>Aid Resource</th>
                                            <th title="Quantity Assigned to Mission">Assigned</th>
                                            <th title="Total Distributed (App Capture)">Distributed</th>
                                            <th title="Total Returned (Physical Log)">Returned</th>
                                            <th title="Assigned - (Distributed + Returned)">Variance</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {currentReport.inventory.map((inv, idx) => (
                                            <tr key={idx}>
                                                <td>{inv.name}</td>
                                                <td>{inv.assigned}</td>
                                                <td style={{ color: 'var(--primary-500)', fontWeight: 'bold' }}>{inv.distributed}</td>
                                                <td style={{ color: 'var(--accent-terracotta)', fontWeight: 'bold' }}>{inv.returned}</td>
                                                <td>
                                                    <span style={{ 
                                                        fontWeight: '800', 
                                                        color: (inv.assigned - (inv.distributed + inv.returned)) === 0 ? 'var(--status-success)' : 'var(--status-error)' 
                                                    }}>
                                                        {(inv.assigned - (inv.distributed + inv.returned)) === 0 ? '0 (OK)' : (inv.assigned - (inv.distributed + inv.returned))}
                                                    </span>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>

                                <h3 style={{ fontSize: '1rem', marginBottom: '0.75rem', color: 'var(--text-100)', display: 'flex', alignItems: 'center', gap: '8px' }}>
                                    <Search size={18} /> Field Evidence: Captured Data Feed
                                </h3>
                                <div style={{ maxHeight: '200px', overflowY: 'auto', background: 'rgba(0,0,0,0.2)', borderRadius: '12px', padding: '0.5rem', border: '1px solid rgba(255,255,255,0.05)' }}>
                                    {currentReport.beneficiaries.length === 0 ? (
                                        <div style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-300)' }}>
                                            <AlertTriangle size={32} style={{ marginBottom: '0.5rem', opacity: 0.5 }} />
                                            <p>No field logs synchronized for this assignment.</p>
                                        </div>
                                    ) : (
                                        currentReport.beneficiaries.map((b, idx) => (
                                            <div key={idx} style={{ 
                                                display: 'flex', 
                                                justifyContent: 'space-between', 
                                                padding: '12px 1rem', 
                                                borderBottom: '1px solid rgba(255,255,255,0.05)',
                                                background: idx % 2 === 0 ? 'rgba(255,255,255,0.02)' : 'transparent'
                                            }}>
                                                <div>
                                                    <p className="font-bold" style={{ fontSize: '0.9rem', marginBottom: '2px' }}>{b.name}</p>
                                                    <p style={{ fontSize: '0.7rem', color: 'var(--text-300)' }}>Timestamp: {new Date(b.timestamp).toLocaleString()}</p>
                                                </div>
                                                <div style={{ textAlign: 'right' }}>
                                                    <span className="status-pill verified" style={{ fontSize: '0.65rem', marginBottom: '4px', display: 'inline-block' }}>GPS SECURED</span>
                                                    <p style={{ fontSize: '0.7rem', color: 'var(--text-300)', fontFamily: 'monospace' }}>COORD: {b.location}</p>
                                                </div>
                                            </div>
                                        ))
                                    )}
                                </div>
                            </div>

                            <div className="modal-footer" style={{ justifyContent: 'flex-end', gap: '12px' }}>
                                <button className="btn btn-glass" onClick={() => setReviewModalOpen(false)}>Close View</button>
                                {currentReport.status === 'reconciling' && (
                                    <button className="btn btn-primary" onClick={() => handleCompleteMission(currentReport.id)}>
                                        Finalize Audit & Close Mission
                                    </button>
                                )}
                            </div>
                        </motion.div>
                    </div>
                )}

                {!loading && (
                    <div className="table-footer">
                        <span>Showing {filteredAssignments.length} tracks</span>
                        <div className="pagination">
                            <button className="btn btn-glass btn-sm" disabled>Previous</button>
                            <button className="btn btn-primary btn-sm">1</button>
                            <button className="btn btn-glass btn-sm" disabled>Next</button>
                        </div>
                    </div>
                )}
            </motion.div>
        </div>
    );
};

export default Assignments;
