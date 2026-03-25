import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { LayoutDashboard, ClipboardList, AlertTriangle, FileText, Settings, LogOut, Users, PackageOpen } from 'lucide-react';
import './Sidebar.css';

const Sidebar = () => {
    const navigate = useNavigate();
    const role = localStorage.getItem('shas_role');

    const handleLogout = () => {
        localStorage.removeItem('shas_token');
        localStorage.removeItem('shas_role');
        localStorage.removeItem('shas_user');
        window.location.reload();
    };

    const menuItems = [
        { name: 'Overview', path: '/dashboard', icon: LayoutDashboard },
        { name: 'Assignments', path: '/assignments', icon: ClipboardList },
        { name: 'Approvals', path: '/discrepancies', icon: AlertTriangle },
        { name: 'Audit Logs', path: '/audits', icon: FileText },
    ];

    if (role === 'superadmin') {
        menuItems.push({ name: 'System Users', path: '/users', icon: Users });
        menuItems.push({ name: 'Warehouse CMS', path: '/warehouse', icon: PackageOpen });
    }

    return (
        <aside className="sidebar glass-panel">
            <div className="sidebar-header">
                <div className="logo-icon"></div>
                <h2>SHAS Admin</h2>
            </div>

            <nav className="sidebar-nav">
                <ul>
                    {menuItems.map((item) => (
                        <li key={item.name}>
                            <NavLink
                                to={item.path}
                                className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
                            >
                                <item.icon size={20} className="nav-icon" />
                                <span>{item.name}</span>
                            </NavLink>
                        </li>
                    ))}
                </ul>
            </nav>

            <div className="sidebar-footer">
                <button className="nav-item btn-logout">
                    <Settings size={20} className="nav-icon" />
                    <span>Settings</span>
                </button>
                <button className="nav-item btn-logout text-danger" onClick={handleLogout}>
                    <LogOut size={20} className="nav-icon" />
                    <span>Logout</span>
                </button>
            </div>
        </aside>
    );
};

export default Sidebar;
