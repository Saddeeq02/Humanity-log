import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, Plus, X, Loader2, UserPlus, Trash2, KeyRound } from 'lucide-react';
import { UserService } from '../services/api';

const ResetPasswordModal = ({ isOpen, onClose, targetUser }) => {
    const [password, setPassword] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        if (isOpen) setPassword('');
    }, [isOpen]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsSubmitting(true);
        try {
            const res = await UserService.resetPassword(targetUser.id, password);
            if (res.data.status === 'success') {
                alert("Password successfully overridden!");
                onClose();
            }
        } catch (error) {
            alert("Error overriding password");
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <AnimatePresence>
            {isOpen && (
                <div className="modal-backdrop">
                    <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.95 }} className="modal-content glass-panel" style={{ maxWidth: '400px' }}>
                        <div className="modal-header">
                            <h2>Reset Password</h2>
                            <button className="icon-btn" onClick={onClose}><X size={20} /></button>
                        </div>
                        <p style={{ marginBottom: '1rem', color: 'var(--text-300)', fontSize: '0.9rem' }}>Overwriting credentials for <strong>{targetUser?.name}</strong>.</p>
                        <form onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label>New Password</label>
                                <input type="password" minLength="6" className="input-glass" value={password} onChange={e => setPassword(e.target.value)} required />
                            </div>
                            <div className="modal-actions" style={{ marginTop: '1.5rem' }}>
                                <button type="button" className="btn btn-glass" onClick={onClose}>Cancel</button>
                                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                                    {isSubmitting ? <Loader2 size={16} className="lucide-spin" /> : 'Force Reset'}
                                </button>
                            </div>
                        </form>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
};

const CreateUserModal = ({ isOpen, onClose, onUserCreated }) => {
    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [role, setRole] = useState('agent');
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        if (isOpen) {
            setName('');
            setEmail('');
            setPassword('');
            setRole('agent');
        }
    }, [isOpen]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsSubmitting(true);
        try {
            const res = await UserService.create({ name, email, password, role });
            if (res.data.status === 'success') {
                onUserCreated();
                onClose();
            }
        } catch (error) {
            console.error("Failed to create user", error);
            alert("Error creating user: " + (error.response?.data?.detail || error.message));
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
                            <h2>Create System User</h2>
                            <button className="icon-btn" onClick={onClose}><X size={20} /></button>
                        </div>

                        <form className="modal-body" onSubmit={handleSubmit}>
                            <div className="form-group">
                                <label>Full Name</label>
                                <input type="text" className="input-glass" value={name} onChange={e => setName(e.target.value)} required />
                            </div>
                            <div className="form-group">
                                <label>Email Address</label>
                                <input type="email" className="input-glass" value={email} onChange={e => setEmail(e.target.value)} required />
                            </div>
                            <div className="form-group">
                                <label>Temporary Password</label>
                                <input type="password" minLength="6" className="input-glass" value={password} onChange={e => setPassword(e.target.value)} required />
                            </div>
                            <div className="form-group">
                                <label>System Role</label>
                                <select className="input-glass" value={role} onChange={e => setRole(e.target.value)} required>
                                    <option value="agent">Field Agent (Mobile App)</option>
                                    <option value="admin">Regional Admin (Dashboard)</option>
                                    <option value="superadmin">Super Admin (Global Control)</option>
                                </select>
                            </div>

                            <div className="modal-actions" style={{ marginTop: '2rem' }}>
                                <button type="button" className="btn btn-glass" onClick={onClose}>Cancel</button>
                                <button type="submit" className="btn btn-primary" disabled={isSubmitting}>
                                    {isSubmitting ? <Loader2 size={16} className="lucide-spin" /> : <><UserPlus size={16} style={{ marginRight: '6px' }} /> Register User</>}
                                </button>
                            </div>
                        </form>
                    </motion.div>
                </div>
            )}
        </AnimatePresence>
    );
};

const UserManagement = () => {
    const [searchTerm, setSearchTerm] = useState('');
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [resetTarget, setResetTarget] = useState(null);

    const fetchUsers = async () => {
        setLoading(true);
        try {
            const res = await UserService.getAll();
            if (res.data.status === 'success') {
                setUsers(res.data.data);
            }
        } catch (error) {
            console.error("Failed to fetch users", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchUsers();
    }, []);

    const handleDelete = async (id, role) => {
        if (role === 'superadmin') {
            alert("Cannot delete the master Super Admin.");
            return;
        }
        if (window.confirm("Are you sure you want to permanently revoke this user's access?")) {
            try {
                await UserService.delete(id);
                fetchUsers();
            } catch (error) {
                console.error("Failed to delete user", error);
            }
        }
    };

    const filteredUsers = users.filter(usr =>
        usr.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        usr.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        usr.role.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="assignments-container">
            <div className="page-header">
                <div>
                    <h1>Global Directory</h1>
                    <p className="subtitle">Super Admin Interface: Manage Admins and Field Agents</p>
                </div>
                <button className="btn btn-primary" onClick={() => setIsModalOpen(true)}>
                    <UserPlus size={18} /> Add User
                </button>
            </div>

            <CreateUserModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} onUserCreated={() => fetchUsers()} />
            <ResetPasswordModal isOpen={!!resetTarget} onClose={() => setResetTarget(null)} targetUser={resetTarget} />

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
                            placeholder="Search by Name, Email, or Role..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                    </div>
                </div>

                <div className="table-responsive">
                    <table className="premium-table">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Account Role</th>
                                <th>Identifier (UUID)</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan="5" style={{ textAlign: 'center', padding: '2rem' }}>
                                        <Loader2 size={24} className="lucide-spin" style={{ color: 'var(--primary-500)', margin: '0 auto' }} />
                                    </td>
                                </tr>
                            ) : filteredUsers.length === 0 ? (
                                <tr>
                                    <td colSpan="5" style={{ textAlign: 'center', padding: '2rem', color: 'var(--text-300)' }}>
                                        No users found.
                                    </td>
                                </tr>
                            ) : (
                                filteredUsers.map((usr) => (
                                    <tr key={usr.id}>
                                        <td className="font-medium text-primary-500">{usr.name}</td>
                                        <td>{usr.email}</td>
                                        <td>
                                            <span className={`status-badge ${usr.role === 'superadmin' ? 'completed' : usr.role === 'admin' ? 'in_progress' : 'pending'}`}>
                                                {usr.role.toUpperCase()}
                                            </span>
                                        </td>
                                        <td style={{ fontSize: '0.8rem', color: 'var(--text-300)' }}>{usr.id.split('-')[0]}...</td>
                                        <td>
                                            <div style={{ display: 'flex', gap: '8px' }}>
                                                <button className="action-btn" onClick={() => setResetTarget(usr)} title="Override Password">
                                                    <KeyRound size={18} style={{ color: 'var(--warning)' }} />
                                                </button>
                                                <button className="action-btn" onClick={() => handleDelete(usr.id, usr.role)} title="Delete User">
                                                    <Trash2 size={18} style={{ color: usr.role === 'superadmin' ? 'var(--text-300)' : 'var(--danger)' }} />
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

export default UserManagement;
