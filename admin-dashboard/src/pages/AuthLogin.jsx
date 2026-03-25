import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Lock, Mail, ArrowRight, Loader2 } from 'lucide-react';
import './AuthLogin.css';

const AuthLogin = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError(null);
        try {
            const formData = new URLSearchParams();
            formData.append('username', email); // OAuth2 expects 'username'
            formData.append('password', password);

            const response = await fetch('http://localhost:8000/api/v1/auth/login', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: formData
            });

            // Handle cases where server might not return JSON (e.g. 500 error page)
            const contentType = response.headers.get("content-type");
            let data = {};
            if (contentType && contentType.indexOf("application/json") !== -1) {
                data = await response.json();
            }

            if (response.ok) {
                localStorage.setItem('shas_token', data.access_token);
                localStorage.setItem('shas_role', data.user.role);
                localStorage.setItem('shas_user', data.user.name);
                window.location.reload();
            } else {
                setError(data.detail || `Server Error (${response.status}): The authentication service is experiencing issues.`);
            }
        } catch (err) {
            setError("Connection Refused: Ensure the backend is running at http://localhost:8000");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-container">
            <div className="auth-bg-elements">
                <div className="glass-orb orb-1"></div>
                <div className="glass-orb orb-2"></div>
            </div>

            <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.5, ease: "easeOut" }}
                className="auth-card glass-panel"
            >
                <div className="auth-header">
                    <div className="logo-placeholder"></div>
                    <h2>SHAS Center</h2>
                    <p>Solunex Humanitarian Accountability System</p>
                </div>

                <form onSubmit={handleLogin} className="auth-form">
                    {error && <div style={{ color: 'var(--danger)', fontSize: '0.85rem', marginBottom: '1rem', textAlign: 'center', background: 'rgba(239,68,68,0.1)', padding: '0.5rem', borderRadius: '4px' }}>{error}</div>}
                    <div className="input-group">
                        <label>Provider Email</label>
                        <div className="input-with-icon">
                            <Mail className="input-icon" size={20} />
                            <input
                                type="email"
                                className="input-glass"
                                placeholder="superadmin@humanitylog.org"
                                value={email}
                                onChange={(e) => setEmail(e.target.value)}
                                required
                                disabled={loading}
                            />
                        </div>
                    </div>

                    <div className="input-group">
                        <label>Master Password</label>
                        <div className="input-with-icon">
                            <Lock className="input-icon" size={20} />
                            <input
                                type="password"
                                className="input-glass"
                                placeholder="••••••••"
                                value={password}
                                onChange={(e) => setPassword(e.target.value)}
                                required
                                disabled={loading}
                            />
                        </div>
                    </div>

                    <div className="auth-options">
                        <label className="checkbox-container">
                            <input type="checkbox" />
                            <span className="checkmark"></span>
                            Remember Device
                        </label>
                        <a href="#" className="forgot-link">Forgot Password?</a>
                    </div>

                    <button type="submit" className="btn btn-primary auth-btn" disabled={loading}>
                        {loading ? <Loader2 size={18} className="lucide-spin" /> : <><ArrowRight size={18} /> Authenticate Session</>}
                    </button>
                </form>

                <div className="auth-footer">
                    <p>Secured by Solunex Core-2 Compliance Engine</p>
                </div>
            </motion.div>
        </div>
    );
};

export default AuthLogin;
