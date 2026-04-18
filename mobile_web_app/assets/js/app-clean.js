/**
 * Civic Grievance System - CLEAN VERSION
 * Simple, working login and navigation
 */

const API = 'http://localhost:5000/api';
let currentUser = null;
let allComplaints = [];

// ===== INITIALIZATION =====
document.addEventListener('DOMContentLoaded', () => {
    console.log('✅ APP LOADED');
    
    // Check if user was previously logged in
    const saved = localStorage.getItem('cgs_user');
    if (saved) {
        try {
            currentUser = JSON.parse(saved);
            console.log('✅ User session restored:', currentUser);
            showUserMode();
        } catch (e) {
            console.error('Session restore error:', e);
            localStorage.removeItem('cgs_user');
        }
    }
});

// ===== SHOW TOAST MESSAGES =====
function showToast(message, type = 'info') {
    console.log(`[${type.toUpperCase()}]`, message);
    const container = document.getElementById('toastContainer') || document.body;
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    toast.style.cssText = `
        position: fixed;
        bottom: 20px;
        right: 20px;
        background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#3b82f6'};
        color: white;
        padding: 12px 20px;
        border-radius: 6px;
        z-index: 10000;
        font-weight: 500;
    `;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 3500);
}

// ===== LOGIN =====
async function handleLogin(e) {
    e.preventDefault();
    
    const username = document.getElementById('loginUsername')?.value?.trim() || '';
    const password = document.getElementById('loginPassword')?.value?.trim() || '';
    
    if (!username || !password) {
        showToast('Please enter username and password', 'error');
        return;
    }
    
    try {
        console.log('🔐 Logging in as:', username);
        
        const response = await fetch(`${API}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        
        console.log('📥 Response status:', response.status);
        const data = await response.json();
        console.log('📥 Response:', data);
        
        if (!response.ok) {
            showToast(data.error || 'Login failed', 'error');
            return;
        }
        
        // Success!
        currentUser = data.user;
        localStorage.setItem('cgs_user', JSON.stringify(currentUser));
        console.log('✅ Login successful:', currentUser);
        
        showToast(`Welcome, ${currentUser.name}!`, 'success');
        showUserMode();
        
    } catch (error) {
        console.error('❌ Login error:', error);
        showToast('Connection error: ' + error.message, 'error');
    }
}

// ===== REGISTER =====
async function handleRegister(e) {
    e.preventDefault();
    
    const payload = {
        name: document.getElementById('regName')?.value?.trim() || '',
        email: document.getElementById('regEmail')?.value?.trim() || '',
        phone: document.getElementById('regPhone')?.value?.trim() || '',
        username: document.getElementById('regUsername')?.value?.trim() || '',
        password: document.getElementById('regPassword')?.value?.trim() || '',
    };
    
    if (!payload.username || !payload.password || !payload.email) {
        showToast('Please fill in all required fields', 'error');
        return;
    }
    
    try {
        console.log('📝 Registering new user:', payload.username);
        const res = await fetch(`${API}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        
        const data = await res.json();
        
        if (!res.ok) {
            showToast(data.error || 'Registration failed', 'error');
            return;
        }
        
        showToast('Registration successful! Please login.', 'success');
        
        // Switch back to login form
        document.getElementById('loginForm').style.display = 'block';
        document.getElementById('registerForm').style.display = 'none';
        document.getElementById('loginUsername').value = payload.username;
        
    } catch (err) {
        console.error('Register error:', err);
        showToast('Connection error', 'error');
    }
}

// ===== TOGGLE FORMS =====
function toggleRegister() {
    const loginForm = document.getElementById('loginForm');
    const registerForm = document.getElementById('registerForm');
    
    if (registerForm?.style.display === 'none' || registerForm?.style.display === '') {
        loginForm.style.display = 'none';
        registerForm.style.display = 'block';
    } else {
        loginForm.style.display = 'block';
        registerForm.style.display = 'none';
    }
}

// ===== ROLE TOGGLE =====
function switchLoginRole(role) {
    document.querySelectorAll('.role-toggle-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`[data-role="${role}"]`)?.classList.add('active');
    
    if (role === 'admin') {
        document.getElementById('registerSection').style.display = 'none';
    } else {
        document.getElementById('registerSection').style.display = 'block';
    }
}

// ===== SHOW USER MODE (After Login) =====
function showUserMode() {
    // Hide login view
    const loginView = document.getElementById('loginView');
    if (loginView) loginView.classList.remove('active');
    
    // Show header
    const header = document.getElementById('appHeader');
    if (header) header.style.display = 'flex';
    
    // Update user badge
    const badge = document.getElementById('userBadge');
    if (badge) {
        badge.innerHTML = `
            <span>${currentUser.name}</span>
            <span class="role-tag ${currentUser.role}">${currentUser.role}</span>
        `;
    }
    
    // Build navigation
    const nav = document.getElementById('appNav');
    if (nav) {
        if (currentUser.role === 'admin') {
            nav.innerHTML = `
                <button class="nav-btn active" data-view="admin" onclick="navigateTo('admin')">🖥️ Dashboard</button>
                <button class="nav-btn" data-view="analytics" onclick="navigateTo('analytics')">📈 Analytics</button>
            `;
            navigateTo('admin');
        } else {
            nav.innerHTML = `
                <button class="nav-btn active" data-view="submit" onclick="navigateTo('submit')">📝 Submit</button>
                <button class="nav-btn" data-view="track" onclick="navigateTo('track')">🔍 Track</button>
            `;
            navigateTo('submit');
        }
    }
}

// ===== NAVIGATION =====
function navigateTo(viewName) {
    console.log('🔄 Navigating to:', viewName);
    
    // Hide all views
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    
    // Deactivate nav buttons
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    
    // Show target view
    const view = document.getElementById(viewName + 'View');
    if (view) view.classList.add('active');
    
    // Activate nav button
    const navBtn = document.querySelector(`[data-view="${viewName}"]`);
    if (navBtn) navBtn.classList.add('active');
    
    // Load data if needed
    if (viewName === 'admin') loadAdminDashboard();
    if (viewName === 'analytics') loadAnalytics();
    if (viewName === 'track') loadMyComplaints();
}

// ===== LOGOUT =====
function logout() {
    currentUser = null;
    localStorage.removeItem('cgs_user');
    
    document.getElementById('appHeader').style.display = 'none';
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.getElementById('loginView').classList.add('active');
    document.getElementById('loginForm').style.display = 'block';
    document.getElementById('registerForm').style.display = 'none';
    
    showToast('Logged out successfully', 'info');
}

// ===== ADMIN: LOAD DASHBOARD =====
async function loadAdminDashboard() {
    try {
        console.log('📊 Loading admin dashboard...');
        
        const res = await fetch(`${API}/analytics/summary`);
        const stats = await res.json();
        
        console.log('✅ Stats:', stats);
        
        // Update stat cards
        document.getElementById('adminStats').innerHTML = `
            <div class="stat-card">
                <div class="stat-icon">📊</div>
                <div class="stat-value">${stats.total || 0}</div>
                <div class="stat-label">Total Complaints</div>
            </div>
            <div class="stat-card high">
                <div class="stat-icon">🔴</div>
                <div class="stat-value">${stats.high_priority || 0}</div>
                <div class="stat-label">High Priority</div>
            </div>
            <div class="stat-card pending">
                <div class="stat-icon">⏳</div>
                <div class="stat-value">${stats.pending || 0}</div>
                <div class="stat-label">Pending</div>
            </div>
            <div class="stat-card resolved">
                <div class="stat-icon">✅</div>
                <div class="stat-value">${stats.resolved || 0}</div>
                <div class="stat-label">Resolved</div>
            </div>
        `;
        
        // Load complaints table
        const compRes = await fetch(`${API}/complaints`);
        allComplaints = await compRes.json();
        console.log('✅ Complaints:', allComplaints.length);
        
        renderAdminTable(allComplaints);
        
    } catch (err) {
        console.error('❌ Dashboard error:', err);
        showToast('Failed to load dashboard', 'error');
    }
}

// ===== RENDER ADMIN TABLE =====
function renderAdminTable(complaints) {
    const tbody = document.getElementById('adminTableBody');
    if (!tbody) return;
    
    if (!complaints.length) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;padding:2rem;color:var(--text-muted);">No complaints found</td></tr>';
        return;
    }
    
    tbody.innerHTML = complaints.map(c => `
        <tr>
            <td style="font-family:monospace;color:var(--accent-primary);font-weight:600;font-size:0.75rem;">${c.id}</td>
            <td>${c.category}</td>
            <td style="font-size:0.8rem;">${c.department}</td>
            <td><span class="priority-badge ${c.priority}">${c.priority}</span></td>
            <td style="font-weight:700;color:${c.fuzzy_priority_score >= 6.5 ? '#ef4444' : c.fuzzy_priority_score >= 3.5 ? '#f59e0b' : '#10b981'};">${(c.fuzzy_priority_score || 5).toFixed(1)}</td>
            <td><span class="status-badge ${c.status}">${c.status}</span></td>
            <td style="font-size:0.8rem;">${new Date(c.created_at).toLocaleDateString()}</td>
            <td>
                <select class="status-select" onchange="updateComplaintStatus('${c.id}', this.value)" style="background: var(--bg-secondary); color: var(--text-primary); border: 1px solid var(--border-glass);">
                    <option value="submitted" ${c.status === 'submitted' ? 'selected' : ''}>Submitted</option>
                    <option value="assigned" ${c.status === 'assigned' ? 'selected' : ''}>Assigned</option>
                    <option value="in-progress" ${c.status === 'in-progress' ? 'selected' : ''}>In Progress</option>
                    <option value="resolved" ${c.status === 'resolved' ? 'selected' : ''}>Resolved</option>
                </select>
            </td>
        </tr>
    `).join('');
}

// ===== UPDATE COMPLAINT STATUS =====
async function updateComplaintStatus(id, newStatus) {
    try {
        console.log(`📝 Updating ${id} to ${newStatus}`);
        
        const res = await fetch(`${API}/complaints/${id}/status`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: newStatus, notes: `Updated to ${newStatus}` })
        });
        
        if (!res.ok) {
            showToast('Failed to update status', 'error');
            loadAdminDashboard();
            return;
        }
        
        showToast('Status updated successfully', 'success');
        loadAdminDashboard();
        
    } catch (err) {
        console.error('Update error:', err);
        showToast('Connection error', 'error');
    }
}

// ===== FILTER COMPLAINTS =====
function filterComplaints(filter) {
    document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`[data-filter="${filter}"]`)?.classList.add('active');
    
    if (filter === 'all') {
        renderAdminTable(allComplaints);
    } else {
        renderAdminTable(allComplaints.filter(c => c.priority === filter));
    }
}

// ===== LOAD MY COMPLAINTS =====
async function loadMyComplaints() {
    if (!currentUser) return;
    
    try {
        const res = await fetch(`${API}/complaints/mine?phone=${currentUser.phone}&username=${currentUser.username}`);
        const complaints = await res.json() || [];
        
        const container = document.getElementById('myComplaintsContent');
        if (!container) return;
        
        if (!complaints.length) {
            container.innerHTML = '<div class="empty-state"><div class="empty-icon">📭</div><p>No complaints found. Submit one first!</p></div>';
            return;
        }
        
        container.innerHTML = complaints.map(c => `
            <div class="card" style="margin-bottom:0.75rem;">
                <div style="display:flex;justify-content:space-between;align-items:flex-start;">
                    <div>
                        <div style="font-weight:700;color:var(--accent-primary);">${c.id}</div>
                        <div style="font-size:0.85rem;color:var(--text-secondary);margin-top:0.2rem;">${c.category} — ${c.location}</div>
                    </div>
                    <span class="status-badge ${c.status}">${c.status}</span>
                </div>
            </div>
        `).join('');
        
    } catch (err) {
        console.error('Load complaints error:', err);
    }
}

// ===== LOAD ANALYTICS =====
async function loadAnalytics() {
    try {
        const res = await fetch(`${API}/analytics/summary`);
        const data = await res.json();
        
        document.getElementById('analyticsStats').innerHTML = `
            <div class="stat-card"><div class="stat-icon">📊</div><div class="stat-value">${data.total}</div><div class="stat-label">Total</div></div>
            <div class="stat-card resolved"><div class="stat-icon">✅</div><div class="stat-value">${data.resolved}</div><div class="stat-label">Resolved</div></div>
            <div class="stat-card pending"><div class="stat-icon">⏳</div><div class="stat-value">${data.pending}</div><div class="stat-label">Pending</div></div>
            <div class="stat-card"><div class="stat-icon">📈</div><div class="stat-value">${data.resolution_rate}%</div><div class="stat-label">Resolution Rate</div></div>
        `;
        
    } catch (err) {
        console.error('Analytics error:', err);
    }
}

console.log('✅ app-clean.js loaded successfully');
