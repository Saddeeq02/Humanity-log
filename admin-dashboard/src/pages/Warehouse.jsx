import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, Plus, X, Loader2, PackageOpen, Trash2, ShieldAlert } from 'lucide-react';
import { InventoryService } from '../services/api';

const CreateItemModal = ({ isOpen, onClose, onItemCreated }) => {
    const [name, setName] = useState('');
    const [quantity, setQuantity] = useState(1);
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        if (isOpen) {
            setName('');
            setQuantity(1);
        }
    }, [isOpen]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsSubmitting(true);
        try {
            await InventoryService.create({ name, total_quantity: quantity });
            onItemCreated();
            onClose();
        } catch (error) {
            console.error("Failed to create warehouse item", error);
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
                        style={{ maxWidth: '500px' }}
                    >
                        <div className="modal-header">
                            <h2>Add Humanitarian Aid Item</h2>
                            <button className="icon-btn" onClick={onClose}><X size={20} /></button>
                        </div>

                        <form className="modal-body" onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label>Aid Name/Category</label>
                                <input type="text" className="input-glass" value={name} onChange={e => setName(e.target.value)} required placeholder="e.g. Bottled Water Cases" />
                            </div>
                            <div className="form-group">
                                <label>Initial Quantity</label>
                                <input type="number" min="1" className="input-glass" value={quantity} onChange={e => setQuantity(Number(e.target.value))} required />
                            </div>

                            <div className="modal-actions" style={{ marginTop: '2rem' }}>
                                <button type="button" className="btn btn-glass" onClick={onClose}>Cancel</button>
                                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                                    {isSubmitting ? <Loader2 size={16} className="lucide-spin" /> : <><PackageOpen size={16} style={{ marginRight: '6px' }} /> Register Aid</>}
                                </button>
                            </div>
                        </form>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
};

const Warehouse = () => {
    const [searchTerm, setSearchTerm] = useState('');
    const [items, setItems] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);

    const fetchInventory = async () => {
        setLoading(true);
        try {
            const res = await InventoryService.getAll();
            if (res.data.status === 'success') {
                setItems(res.data.data);
            }
        } catch (error) {
            console.error("Failed to fetch inventory", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchInventory();
    }, []);

    const handleSuspend = async (id) => {
        try {
            await InventoryService.suspend(id);
            fetchInventory();
        } catch (error) {
            console.error("Failed to suspend item", error);
        }
    };

    const handleDelete = async (id) => {
        if (window.confirm("Are you sure you want to permanently delete this aid resource? Physical tracking will be voided.")) {
            try {
                await InventoryService.delete(id);
                fetchInventory();
            } catch (error) {
                console.error("Failed to delete item", error);
            }
        }
    };

    const filteredItems = items.filter(itm =>
        itm.name.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="assignments-container">
            <div className="page-header">
                <div>
                    <h1>Warehouse CMS</h1>
                    <p className="subtitle">Super Admin Interface: Global Distribution Supply Registry</p>
                </div>
                <button className="btn btn-primary" onClick={() => setIsModalOpen(true)}>
                    <Plus size={18} /> Register Supply
                </button>
            </div>

            <CreateItemModal
                isOpen={isModalOpen}
                onClose={() => setIsModalOpen(false)}
                onItemCreated={() => fetchInventory()}
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
                            placeholder="Search by Supply Name..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>

                <div className="table-responsive">
                    <table className="premium-table">
                        <thead>
                            <tr>
                                <th>Aid Classification</th>
                                <th>Available Stock</th>
                                <th>Warehouse Identifier (UUID)</th>
                                <th>System Status</th>
                                <th>Override Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="5" style={{ textAlign: 'center', padding: '2rem' }}>
                                        <Loader2 size={24} className="lucide-spin" style={{ color: 'var(--primary-500)', margin: '0 auto' }} />
                                    </td>
                                </tr>
                            ) : filteredItems.length === 0 ? (
                                <tr>
                                    <td colSpan="5" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-300)' }}>
                                        No inventory found.
                                    </td>
                                </tr>
                            ) : (
                                filteredItems.map((itm) => (
                                    <tr key={itm.id}>
                                        <td className="font-medium text-primary-500">{itm.name}</td>
                                        <td style={{ fontWeight: 'bold', fontSize: '1.1rem' }}>{itm.current_stock.toLocaleString()}</td>
                                        <td style={{ fontSize: '0.8rem', color: 'var(--text-300)' }}>{itm.id.split('-')[0]}...</td>
                                        <td>
                                            <span className={`status-badge ${itm.is_active ? 'completed' : 'failed'}`}>
                                                {itm.is_active ? 'ACTIVE' : 'SUSPENDED'}
                                            </span>
                                        </td>
                                        <td>
                                            <div style={{ display: 'flex', gap: '10px' }}>
                                                <button className="action-btn" onClick={() => handleSuspend(itm.id)} title={itm.is_active ? "Suspend Item" : "Activate Item"}>
                                                    <ShieldAlert size={18} style={{ color: itm.is_active ? 'var(--warning)' : 'var(--success)' }} />
                                                </button>
                                                <button className="action-btn" onClick={() => handleDelete(itm.id)} title="Delete Data">
                                                    <Trash2 size={18} style={{ color: 'var(--danger)' }} />
                                                </button>
                                            </div>
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

export default Warehouse;
