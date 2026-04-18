/**
 * Civic Grievance System - Correct Working Version
 * Supports admin & citizen roles with 4 new features
 */

const API = 'http://localhost:5000/api';
let currentUser = null;
let allComplaints = [];
let map = null;
let markers = [];

// ===== INITIALIZATION =====
document.addEventListener('DOMContentLoaded', () => {
    const saved = localStorage.getItem('cgs_user');
    if (saved) {
        try {
            currentUser = JSON.parse(saved);
            showUserMode();
        } catch (e) {
            localStorage.removeItem('cgs_user');
        }
    }
});

// ===== ROLE SELECTION IN LOGIN =====
function switchLoginRole(role) {
    currentRole = role;
    document.querySelectorAll('.role-toggle-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-role="${role}"]`).classList.add('active');
}

// ===== TOGGLE REGISTER FORM =====
function toggleRegisterForm() {
    const loginForm = document.getElementById('loginForm');
    const registerForm = document.getElementById('registerForm');
    loginForm.style.display = loginForm.style.display === 'none' ? 'block' : 'none';
    registerForm.style.display = registerForm.style.display === 'none' ? 'block' : 'none';
}

// ===== LOGIN =====
async function handleLogin(e) {
    e.preventDefault();
    const username = document.getElementById('loginUsername').value.trim();
    const password = document.getElementById('loginPassword').value.trim();
    
    if (!username || !password) {
        showToast('Enter username and password', 'error');
        return;
    }
    
    try {
        const response = await fetch(`${API}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            showToast(data.error || 'Login failed', 'error');
            return;
        }
        
        currentUser = data.user;
        localStorage.setItem('cgs_user', JSON.stringify(currentUser));
        showToast(`Welcome, ${currentUser.name}!`, 'success');
        showUserMode();
        
    } catch (error) {
        showToast('Connection error: ' + error.message, 'error');
    }
}

// ===== REGISTER =====
async function handleRegister(e) {
    e.preventDefault();
    
    const name = document.getElementById('regName').value.trim();
    const email = document.getElementById('regEmail').value.trim();
    const phone = document.getElementById('regPhone').value.trim();
    const username = document.getElementById('regUsername').value.trim();
    const password = document.getElementById('regPassword').value.trim();
    
    try {
        const response = await fetch(`${API}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, email, phone, username, password })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            showToast(data.error || 'Registration failed', 'error');
            return;
        }
        
        showToast('Registration successful! Please login.', 'success');
        toggleRegisterForm();
        document.getElementById('registerForm').reset();
        document.getElementById('loginUsername').value = username;
        
    } catch (error) {
        showToast('Registration error: ' + error.message, 'error');
    }
}

function logout() {
    currentUser = null;
    localStorage.removeItem('cgs_user');
    location.reload();
}

function showUserMode() {
    document.getElementById('loginView').style.display = 'none';
    document.getElementById('appHeader').style.display = 'flex';
    
    const role = currentUser.role || 'citizen';
    
    if (role === 'admin') {
        document.getElementById('adminView').style.display = 'block';
        document.getElementById('submitView').style.display = 'none';
        document.getElementById('trackView').style.display = 'none';
        loadAdminDashboard();
    } else {
        document.getElementById('adminView').style.display = 'none';
        document.getElementById('submitView').style.display = 'block';
        document.getElementById('trackView').style.display = 'block';
    }
    
    document.getElementById('userBadge').innerHTML = `👤 ${currentUser.name} <span style="font-size:0.75rem;margin-left:0.5rem;">[ ${role.toUpperCase()} ]</span>`;
}

function showToast(message, type = 'info') {
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
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3500);
}

// ===== ADMIN: LOAD DASHBOARD =====
async function loadAdminDashboard() {
    try {
        const response = await fetch(`${API}/analytics/summary`);
        const data = await response.json();
        
        const statsHTML = `
            <div class="stat-card">
                <h3>📊 Total Complaints</h3>
                <div class="stat-number">${data.total}</div>
            </div>
            <div class="stat-card">
                <h3>⏳ Pending</h3>
                <div class="stat-number">${data.pending}</div>
            </div>
            <div class="stat-card">
                <h3>✅ Resolved</h3>
                <div class="stat-number">${data.resolved}</div>
                <div class="stat-detail">${data.resolution_rate}%</div>
            </div>
            <div class="stat-card">
                <h3>🔴 High Priority</h3>
                <div class="stat-number">${data.high_priority}</div>
            </div>
        `;
        
        document.getElementById('adminStats').innerHTML = statsHTML;
        
        const complaintResponse = await fetch(`${API}/complaints`);
        allComplaints = await complaintResponse.json();
        renderAdminTable(allComplaints);
        
    } catch (error) {
        showToast('Failed to load dashboard', 'error');
    }
}

function renderAdminTable(complaints) {
    const tbody = document.getElementById('adminTableBody');
    
    if (!complaints || complaints.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center;">No complaints found</td></tr>';
        return;
    }
    
    tbody.innerHTML = complaints.map(c => `
        <tr>
            <td><strong>${c.id}</strong></td>
            <td>${c.category}</td>
            <td>${c.location}</td>
            <td>${c.department || 'N/A'}</td>
            <td><span style="background:${c.priority === 'high' ? '#ef4444' : c.priority === 'medium' ? '#f59e0b' : '#10b981'};color:white;padding:0.25rem 0.5rem;border-radius:4px;font-size:0.75rem;">${c.priority.toUpperCase()}</span></td>
            <td>${c.status}</td>
            <td>
                <button onclick="upvote('${c.id}')" style="background:transparent;border:1px solid #3b82f6;color:#3b82f6;padding:0.25rem 0.5rem;border-radius:4px;cursor:pointer;font-size:0.85rem;">👍 ${c.upvotes || 0}</button>
            </td>
            <td>
                <select onchange="updateStatus('${c.id}', this.value)" style="padding:0.25rem;border-radius:4px;background:rgba(124,58,237,0.1);border:1px solid #475569;">
                    <option value="submitted" ${c.status === 'submitted' ? 'selected' : ''}>Submitted</option>
                    <option value="assigned" ${c.status === 'assigned' ? 'selected' : ''}>Assigned</option>
                    <option value="in-progress" ${c.status === 'in-progress' ? 'selected' : ''}>In Progress</option>
                    <option value="resolved" ${c.status === 'resolved' ? 'selected' : ''}>Resolved</option>
                </select>
            </td>
        </tr>
    `).join('');
}

async function updateStatus(complaintId, newStatus) {
    try {
        const response = await fetch(`${API}/complaints/${complaintId}/status`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: newStatus })
        });
        
        if (!response.ok) {
            showToast('Failed to update status', 'error');
            return;
        }
        
        showToast('Status updated successfully', 'success');
        loadAdminDashboard();
    } catch (error) {
        showToast('Error updating status', 'error');
    }
}

async function upvote(complaintId) {
    try {
        const response = await fetch(`${API}/complaints/${complaintId}/upvote`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: currentUser.username })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            showToast(data.error || 'Cannot upvote', 'error');
            return;
        }
        
        showToast(`👍 Upvoted! (${data.upvotes} total)`, 'success');
        loadAdminDashboard();
    } catch (error) {
        showToast('Upvote error', 'error');
    }
}

// ===== ADMIN: SWITCH SECTIONS =====
function switchAdminSection(section) {
    // Hide all admin sections
    document.querySelectorAll('.admin-section').forEach(s => s.style.display = 'none');
    
    // Show selected section
    document.getElementById(section + 'Section').style.display = 'block';
    
    // Update nav buttons
    document.querySelectorAll('.admin-nav-btn').forEach(btn => {
        btn.classList.remove('active');
        btn.classList.add('inactive');
    });
    document.querySelector(`[data-section="${section}"]`).classList.remove('inactive');
    document.querySelector(`[data-section="${section}"]`).classList.add('active');
    
    // Load data
    if (section === 'insights') loadInsights();
    else if (section === 'predictions') loadPredictions();
    else if (section === 'map') loadMap();
}

// ===== FEATURE 1: INSIGHTS =====
async function loadInsights() {
    try {
        const response = await fetch(`${API}/analytics/insights`);
        const data = await response.json();
        
        let html = '';
        if (data.insights && data.insights.length > 0) {
            html = data.insights.map(insight => `
                <div class="insight-card ${insight.severity}">
                    <div class="insight-message">
                        ${insight.type === 'spike' ? '📈' : insight.type === 'decline' ? '📉' : '🆕'} 
                        ${insight.message}
                    </div>
                    <div style="font-size:0.9rem;color:#94a3b8;margin-top:0.5rem;">
                        <span>Last Week: ${insight.previous}</span> | 
                        <span>This Week: ${insight.current}</span> | 
                        <span>${insight.change_pct > 0 ? '+' : ''}${insight.change_pct}%</span>
                    </div>
                </div>
            `).join('');
        } else {
            html = '<p style="text-align:center;color:#94a3b8;">No trends detected yet</p>';
        }
        document.getElementById('insightsContainer').innerHTML = html;
        
        // Hotspots
        if (data.hotspots && data.hotspots.length > 0) {
            document.getElementById('hotspotsGrid').innerHTML = data.hotspots.map(h => `
                <div class="hotspot-badge">
                    <div style="font-weight:600;color:#7c3aed;margin-bottom:0.5rem;">📍 ${h.location}</div>
                    <div style="font-size:0.9rem;color:#94a3b8;">${h.count} complaints</div>
                </div>
            `).join('');
        }
        
        // Trending
        if (data.trending && data.trending.length > 0) {
            document.getElementById('trendingContainer').innerHTML = data.trending.map(t => `
                <div class="trending-card">
                    <div>
                        <div style="font-weight:600;color:#7c3aed;margin-bottom:0.3rem;">${t.category}</div>
                        <div style="font-size:0.85rem;color:#94a3b8;">${t.description}</div>
                        <div style="font-size:0.8rem;color:#94a3b8;">📍 ${t.location}</div>
                    </div>
                    <div class="trending-upvotes">👍 ${t.upvotes}</div>
                </div>
            `).join('');
        }
        
    } catch (error) {
        console.error('Insights error:', error);
        document.getElementById('insightsContainer').innerHTML = '<p style="color:red;">Failed to load insights</p>';
    }
}

// ===== FEATURE 2: PREDICTIONS =====
async function loadPredictions() {
    try {
        const response = await fetch(`${API}/analytics/predictions`);
        const data = await response.json();
        
        let html = '';
        if (data.predictions && data.predictions.length > 0) {
            html = data.predictions.map(pred => `
                <div class="prediction-card">
                    <div style="font-weight:600;margin-bottom:0.5rem;">${pred.category.toUpperCase()}</div>
                    <div style="margin-bottom:0.5rem;color:#94a3b8;">${pred.message}</div>
                    <div style="display:flex;gap:1rem;font-size:0.9rem;color:#94a3b8;">
                        <span>Avg: ${pred.avg_weekly}/week</span>
                        <span>Predicted: ${pred.predicted_next_week}/week</span>
                        <span style="background:${pred.risk_level === 'high' ? '#ef4444' : pred.risk_level === 'medium' ? '#f59e0b' : '#10b981'};color:white;padding:0.2rem 0.5rem;border-radius:4px;font-size:0.8rem;">${pred.risk_level}</span>
                    </div>
                </div>
            `).join('');
        } else {
            html = '<p style="text-align:center;color:#94a3b8;">Not enough data for predictions</p>';
        }
        document.getElementById('predictionsContainer').innerHTML = html;
        
        // Seasonal Alerts
        if (data.seasonal_alerts && data.seasonal_alerts.length > 0) {
            document.getElementById('seasonalAlertsContainer').innerHTML = data.seasonal_alerts.map(alert => `
                <div class="insight-card high">
                    <div>⚠️ ${alert.message}</div>
                </div>
            `).join('');
        }
        
    } catch (error) {
        console.error('Predictions error:', error);
        document.getElementById('predictionsContainer').innerHTML = '<p style="color:red;">Failed to load predictions</p>';
    }
}

// ===== FEATURE 3 & 4: MAP (Using Leaflet) =====
let mapInitialized = false;

function initializeMap() {
    map = L.map('mapContainer').setView([28.7, 77.1], 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
    }).addTo(map);
}

async function loadMap() {
    try {
        if (!mapInitialized) {
            initializeMap();
            mapInitialized = true;
        }
        
        const response = await fetch(`${API}/complaints`);
        const complaints = await response.json();
        
        // Clear existing markers
        markers.forEach(marker => map.removeLayer(marker));
        markers = [];
        
        // Add new markers
        complaints.forEach(complaint => {
            let lat = 28.7 + (Math.random() - 0.5) * 0.5;
            let lng = 77.1 + (Math.random() - 0.5) * 0.5;
            
            const color = complaint.priority === 'high' ? '#ef4444' : complaint.priority === 'medium' ? '#f59e0b' : '#10b981';
            
            const marker = L.circleMarker([lat, lng], {
                radius: 8,
                fillColor: color,
                color: '#fff',
                weight: 2,
                opacity: 0.8,
                fillOpacity: 0.7
            }).bindPopup(`
                <strong>${complaint.category}</strong><br>
                ${complaint.location}<br>
                Priority: ${complaint.priority}<br>
                Status: ${complaint.status}
            `).addTo(map);
            
            markers.push(marker);
        });
        
    } catch (error) {
        console.error('Map error:', error);
        showToast('Failed to load map', 'error');
    }
}

// ===== CITIZEN: SUBMIT COMPLAINT =====
function suggestDepartmentCitizen() {
    const category = document.getElementById('cCategory').value;
    const deptMap = {
        'roads': 'Roads & Infrastructure Dept',
        'water': 'Water Supply Department',
        'electricity': 'Electricity Board',
        'sanitation': 'Sanitation Services',
        'garbage': 'Waste Management Dept',
        'drainage': 'Drainage & Sewage Dept',
        'streetlights': 'Electricity Board - Street Lights',
        'parks': 'Parks & Gardens Department',
        'noise': 'Environmental Protection Dept',
        'other': 'General Grievance Cell'
    };
    
    if (category && deptMap[category]) {
        document.getElementById('deptInfo').style.display = 'block';
        document.getElementById('suggestedDept').textContent = deptMap[category];
    } else {
        document.getElementById('deptInfo').style.display = 'none';
    }
}

async function handleSubmitComplaint(e) {
    e.preventDefault();
    
    const formData = {
        name: document.getElementById('cName').value,
        email: document.getElementById('cEmail').value,
        phone: document.getElementById('cPhone').value,
        category: document.getElementById('cCategory').value,
        location: document.getElementById('cLocation').value,
        description: document.getElementById('cDescription').value,
        username: currentUser.username || 'citizen'
    };
    
    try {
        const response = await fetch(`${API}/complaints`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            showToast(data.error || 'Submission failed', 'error');
            return;
        }
        
        document.getElementById('modalComplaintId').textContent = `ID: ${data.complaint_id}`;
        document.getElementById('modalPriority').textContent = `Priority: ${data.priority.toUpperCase()}`;
        document.getElementById('modalDepartment').textContent = `Department: ${data.department}`;
        document.getElementById('successModal').style.display = 'flex';
        
        document.getElementById('complaintForm').reset();
        
    } catch (error) {
        showToast('Submission error: ' + error.message, 'error');
    }
}

function closeModal() {
    document.getElementById('successModal').style.display = 'none';
}

// ===== CITIZEN: TRACK COMPLAINT =====
async function searchComplaint() {
    const query = document.getElementById('trackSearch').value.trim();
    if (!query) {
        showToast('Enter ID or phone number', 'error');
        return;
    }
    
    try {
        const response = await fetch(`${API}/complaints/search?q=${query}`);
        const data = await response.json();
        
        if (data.results && data.results.length > 0) {
            const html = data.results.map(c => `
                <div class="card">
                    <h3>${c.id}</h3>
                    <p><strong>Category:</strong> ${c.category}</p>
                    <p><strong>Location:</strong> ${c.location}</p>
                    <p><strong>Status:</strong> ${c.status}</p>
                    <p><strong>Priority:</strong> ${c.priority}</p>
                    <p><strong>Department:</strong> ${c.department}</p>
                </div>
            `).join('');
            
            document.getElementById('trackResult').innerHTML = html;
            document.getElementById('trackResult').style.display = 'block';
        } else {
            showToast('No complaints found', 'error');
            document.getElementById('trackResult').style.display = 'none';
        }
    } catch (error) {
        showToast('Search error: ' + error.message, 'error');
    }
}

console.log('✅ App loaded and ready');
        isOnline = true;
        updateOfflineBanner();
        syncOfflineQueue();
        toast('🌐 You are back online!', 'success');
    });
    window.addEventListener('offline', () => {
        isOnline = false;
        updateOfflineBanner();
        toast('📡 You are offline. Complaints will be saved locally.', 'info');
    });
    updateOfflineBanner();
});

// ===================================
// AUTH
// ===================================
function switchLoginRole(role) {
    document.querySelectorAll('.role-toggle-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`.role-toggle-btn[data-role="${role}"]`).classList.add('active');
    // Hide register for admin
    const regSec = document.getElementById('registerSection');
    if (role === 'admin') {
        regSec.style.display = 'none';
    } else {
        regSec.style.display = 'block';
    }
}

function toggleRegister() {
    const form = document.getElementById('registerForm');
    const loginForm = document.getElementById('loginForm');
    if (form.style.display === 'none') {
        form.style.display = 'block';
        loginForm.style.display = 'none';
    } else {
        form.style.display = 'none';
        loginForm.style.display = 'block';
    }
}

async function handleLogin(e) {
    e.preventDefault();
    const username = document.getElementById('loginUsername').value.trim();
    const password = document.getElementById('loginPassword').value.trim();
    if (!username || !password) return toast('Enter username and password', 'error');

    try {
        console.log('🔐 Attempting login with username:', username);
        const res = await fetch(`${API}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password })
        });
        console.log('✅ Response status:', res.status);
        const data = await res.json();
        console.log('✅ Response data:', data);
        if (!res.ok) return toast(data.error || 'Login failed', 'error');

        currentUser = data.user;
        localStorage.setItem('cgs_user', JSON.stringify(currentUser));
        onLoginSuccess();
        toast(`Welcome, ${currentUser.name}!`, 'success');
    } catch (err) {
        console.error('❌ Login error:', err);
        toast('Cannot connect to server. Is the backend running?', 'error');
    }
}

async function handleRegister(e) {
    e.preventDefault();
    const payload = {
        name: document.getElementById('regName').value.trim(),
        email: document.getElementById('regEmail').value.trim(),
        phone: document.getElementById('regPhone').value.trim(),
        username: document.getElementById('regUsername').value.trim(),
        password: document.getElementById('regPassword').value.trim(),
    };

    try {
        const res = await fetch(`${API}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (!res.ok) return toast(data.error || 'Registration failed', 'error');

        toast('Registration successful! Please login.', 'success');
        toggleRegister();
        document.getElementById('loginUsername').value = payload.username;
    } catch (err) {
        toast('Cannot connect to server', 'error');
    }
}

function onLoginSuccess() {
    // Hide login, show header
    document.getElementById('loginView').classList.remove('active');
    document.getElementById('appHeader').style.display = 'flex';

    // User badge
    const badge = document.getElementById('userBadge');
    badge.innerHTML = `
        <span>${currentUser.name}</span>
        <span class="role-tag ${currentUser.role}">${currentUser.role}</span>
    `;

    // Build nav
    buildNav();

    // Navigate to first view
    if (currentUser.role === 'admin') {
        navigateTo('admin');
    } else {
        navigateTo('submit');
    }
}

function buildNav() {
    const nav = document.getElementById('appNav');
    if (currentUser.role === 'citizen') {
        nav.innerHTML = `
            <button class="nav-btn" data-view="submit" onclick="navigateTo('submit')">📝 Submit</button>
            <button class="nav-btn" data-view="track" onclick="navigateTo('track')">🔍 Track</button>
        `;
    } else {
        nav.innerHTML = `
            <button class="nav-btn" data-view="admin" onclick="navigateTo('admin')">🖥️ Dashboard</button>
            <button class="nav-btn" data-view="analytics" onclick="navigateTo('analytics')">📈 Analytics</button>
        `;
    }
}

function logout() {
    currentUser = null;
    localStorage.removeItem('cgs_user');
    document.getElementById('appHeader').style.display = 'none';
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.getElementById('loginView').classList.add('active');
    document.getElementById('loginForm').style.display = 'block';
    document.getElementById('registerForm').style.display = 'none';
    document.getElementById('loginUsername').value = '';
    document.getElementById('loginPassword').value = '';
    toast('Logged out', 'info');
}

// ===================================
// SPA ROUTING
// ===================================
function navigateTo(viewName) {
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));

    const view = document.getElementById(viewName + 'View');
    if (view) {
        view.classList.add('active');
    }
    const navBtn = document.querySelector(`.nav-btn[data-view="${viewName}"]`);
    if (navBtn) navBtn.classList.add('active');

    // Load data for view
    if (viewName === 'admin') loadAdminDashboard();
    if (viewName === 'analytics') loadAnalytics();
    if (viewName === 'track') loadMyComplaints();
    if (viewName === 'submit') prefillCitizenData();
}

function prefillCitizenData() {
    if (!currentUser) return;
    const nameEl = document.getElementById('cName');
    const emailEl = document.getElementById('cEmail');
    const phoneEl = document.getElementById('cPhone');
    if (nameEl && !nameEl.value) nameEl.value = currentUser.name || '';
    if (emailEl && !emailEl.value) emailEl.value = currentUser.email || '';
    if (phoneEl && !phoneEl.value) phoneEl.value = currentUser.phone || '';
}

// ===================================
// CITIZEN: SUBMIT COMPLAINT
// ===================================
async function handleSubmitComplaint(e) {
    e.preventDefault();
    const payload = {
        name: document.getElementById('cName').value.trim(),
        email: document.getElementById('cEmail').value.trim(),
        phone: document.getElementById('cPhone').value.trim(),
        category: document.getElementById('cCategory').value,
        location: document.getElementById('cLocation').value.trim(),
        description: document.getElementById('cDescription').value.trim(),
        username: currentUser ? currentUser.username : '',
    };

    // === OFFLINE MODE: Save locally if offline ===
    if (!navigator.onLine) {
        saveToOfflineQueue(payload);
        toast('📡 Saved offline! Will auto-submit when you reconnect.', 'info');
        document.getElementById('cCategory').value = '';
        document.getElementById('cLocation').value = '';
        document.getElementById('cDescription').value = '';
        return;
    }

    try {
        const res = await fetch(`${API}/complaints`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (!res.ok) return toast(data.error || 'Submission failed', 'error');

        // Show success modal with auto-routing info
        document.getElementById('modalComplaintId').textContent = data.complaint_id;
        document.getElementById('modalPriority').innerHTML =
            `<span class="priority-badge ${data.priority}">${priorityIcon(data.priority)} ${data.priority.toUpperCase()}</span>`;
        document.getElementById('modalDepartment').textContent = `🧭 Auto-Routed to: ${data.department}`;
        document.getElementById('successModal').classList.add('active');

        // Reset form (keep personal info)
        document.getElementById('cCategory').value = '';
        document.getElementById('cLocation').value = '';
        document.getElementById('cDescription').value = '';
        document.getElementById('cEvidence').value = '';
    } catch (err) {
        // Network failed — save offline
        saveToOfflineQueue(payload);
        toast('📡 Network error. Saved offline! Will auto-submit when you reconnect.', 'info');
    }
}

function closeModal() {
    document.getElementById('successModal').classList.remove('active');
}

// ===================================
// CITIZEN: TRACK COMPLAINT
// ===================================
async function loadMyComplaints() {
    if (!currentUser) return;
    const container = document.getElementById('myComplaintsContent');

    try {
        const res = await fetch(`${API}/complaints/mine?username=${encodeURIComponent(currentUser.username)}&phone=${encodeURIComponent(currentUser.phone || '')}`);
        const data = await res.json();

        if (!Array.isArray(data) || data.length === 0) {
            container.innerHTML = '<div class="empty-state"><div class="empty-icon">📭</div><p>No complaints found. Submit one first!</p></div>';
            return;
        }

        container.innerHTML = data.map(c => `
            <div class="card" style="margin-bottom:0.75rem;cursor:pointer;" onclick="viewComplaintDetail('${c.id}')">
                <div style="display:flex;justify-content:space-between;align-items:flex-start;flex-wrap:wrap;gap:0.5rem;">
                    <div>
                        <div style="font-weight:700;font-size:0.9rem;color:var(--accent-primary);font-family:monospace;">${c.id}</div>
                        <div style="font-size:0.85rem;color:var(--text-secondary);margin-top:0.2rem;">${c.category} — ${c.location}</div>
                        <div style="font-size:0.8rem;color:var(--text-muted);margin-top:0.2rem;">${formatDate(c.created_at)}</div>
                        <div style="font-size:0.75rem;color:var(--text-muted);margin-top:0.15rem;">🧭 ${c.department}</div>
                    </div>
                    <div style="display:flex;flex-direction:column;gap:0.4rem;align-items:flex-end;">
                        <div style="display:flex;gap:0.5rem;align-items:center;">
                            <span class="priority-badge ${c.priority}">${priorityIcon(c.priority)} ${c.priority}</span>
                            <span class="status-badge ${c.status}">${c.status}</span>
                        </div>
                        <button class="upvote-btn" onclick="event.stopPropagation();upvoteComplaint('${c.id}')" title="Upvote this complaint">
                            👍 ${c.upvotes || 0}
                        </button>
                    </div>
                </div>
            </div>
        `).join('');
    } catch (err) {
        container.innerHTML = '<div class="empty-state"><div class="empty-icon">⚠️</div><p>Could not load complaints</p></div>';
    }
}

async function searchComplaint() {
    const query = document.getElementById('trackSearch').value.trim();
    if (!query) return toast('Enter a Complaint ID or Phone number', 'error');

    const resultDiv = document.getElementById('trackResult');
    resultDiv.style.display = 'block';
    resultDiv.innerHTML = '<div style="text-align:center;padding:2rem;color:var(--text-muted);">Searching...</div>';

    try {
        // Try direct ID first
        let res = await fetch(`${API}/complaints/${encodeURIComponent(query)}`);
        if (res.ok) {
            const data = await res.json();
            renderComplaintDetail(resultDiv, data);
            return;
        }

        // Try search
        res = await fetch(`${API}/complaints/search?q=${encodeURIComponent(query)}`);
        const data = await res.json();
        if (data.results && data.results.length > 0) {
            // Show first result detail
            const detailRes = await fetch(`${API}/complaints/${data.results[0].id}`);
            if (detailRes.ok) {
                renderComplaintDetail(resultDiv, await detailRes.json());
            }
        } else {
            resultDiv.innerHTML = '<div class="card"><div class="empty-state"><div class="empty-icon">🔍</div><p>No complaint found with that ID or phone number</p></div></div>';
        }
    } catch (err) {
        resultDiv.innerHTML = '<div class="card"><div class="empty-state"><div class="empty-icon">⚠️</div><p>Server error. Please try again.</p></div></div>';
    }
}

async function viewComplaintDetail(id) {
    const resultDiv = document.getElementById('trackResult');
    resultDiv.style.display = 'block';
    try {
        const res = await fetch(`${API}/complaints/${id}`);
        if (res.ok) {
            renderComplaintDetail(resultDiv, await res.json());
            resultDiv.scrollIntoView({ behavior: 'smooth' });
        }
    } catch (err) {
        toast('Failed to load complaint details', 'error');
    }
}

function renderComplaintDetail(container, c) {
    const history = c.history || [];
    container.innerHTML = `
        <div class="card">
            <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:1rem;flex-wrap:wrap;gap:0.5rem;">
                <h3 style="font-size:1.1rem;font-family:monospace;color:var(--accent-primary);">${c.id}</h3>
                <div style="display:flex;gap:0.5rem;">
                    <span class="priority-badge ${c.priority}">${priorityIcon(c.priority)} ${c.priority} (${c.fuzzy_priority_score || 'N/A'})</span>
                    <span class="status-badge ${c.status}">${c.status}</span>
                </div>
            </div>
            <div class="complaint-detail">
                <div class="detail-row"><span class="detail-label">Category</span><span class="detail-value">${c.category}</span></div>
                <div class="detail-row"><span class="detail-label">Department</span><span class="detail-value">${c.department}</span></div>
                <div class="detail-row"><span class="detail-label">Location</span><span class="detail-value">${c.location}</span></div>
                <div class="detail-row"><span class="detail-label">Description</span><span class="detail-value">${c.description}</span></div>
                <div class="detail-row"><span class="detail-label">Filed By</span><span class="detail-value">${c.name} (${c.phone})</span></div>
                <div class="detail-row"><span class="detail-label">Submitted</span><span class="detail-value">${formatDate(c.created_at)}</span></div>
                ${c.resolved_at ? `<div class="detail-row"><span class="detail-label">Resolved</span><span class="detail-value">${formatDate(c.resolved_at)}</span></div>` : ''}
                <div class="detail-row"><span class="detail-label">Fuzzy Scores</span><span class="detail-value">Urgency: ${c.urgency_score || '-'} | Frequency: ${c.frequency_score || '-'} | Impact: ${c.impact_score || '-'}</span></div>
            </div>
            <h4 style="margin-top:1.5rem;margin-bottom:0.75rem;font-size:0.9rem;">📋 Status Timeline</h4>
            <div class="timeline">
                ${history.map((h, i) => `
                    <div class="timeline-item ${i === history.length - 1 ? 'current' : ''}">
                        <div class="timeline-status">${h.status}</div>
                        <div class="timeline-date">${formatDate(h.changed_at)}</div>
                        ${h.notes ? `<div class="timeline-notes">${h.notes}</div>` : ''}
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

// ===================================
// ADMIN: DASHBOARD
// ===================================
async function loadAdminDashboard() {
    try {
        // Load stats
        const statsRes = await fetch(`${API}/analytics/summary`);
        const stats = await statsRes.json();
        renderAdminStats(stats);

        // Load complaints
        const compRes = await fetch(`${API}/complaints`);
        allComplaints = await compRes.json();
        renderAdminTable(allComplaints);
    } catch (err) {
        toast('Failed to load dashboard', 'error');
    }
}

function renderAdminStats(s) {
    document.getElementById('adminStats').innerHTML = `
        <div class="stat-card"><div class="stat-icon">📊</div><div class="stat-value">${s.total}</div><div class="stat-label">Total Complaints</div></div>
        <div class="stat-card high"><div class="stat-icon">🔴</div><div class="stat-value">${s.high_priority || 0}</div><div class="stat-label">High Priority</div></div>
        <div class="stat-card pending"><div class="stat-icon">⏳</div><div class="stat-value">${s.pending}</div><div class="stat-label">Pending</div></div>
        <div class="stat-card resolved"><div class="stat-icon">✅</div><div class="stat-value">${s.resolved}</div><div class="stat-label">Resolved</div></div>
    `;
}

function renderAdminTable(complaints) {
    const tbody = document.getElementById('adminTableBody');
    if (!complaints.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-state">No complaints found</td></tr>';
        return;
    }

    tbody.innerHTML = complaints.map(c => `
        <tr>
            <td style="font-family:monospace;color:var(--accent-primary);font-weight:600;font-size:0.75rem;">${c.id}</td>
            <td>${c.category}</td>
            <td style="font-size:0.8rem;">${c.department}</td>
            <td><span class="priority-badge ${c.priority}">${priorityIcon(c.priority)} ${c.priority}</span></td>
            <td style="font-weight:700;color:${c.fuzzy_priority_score >= 6.5 ? 'var(--priority-high)' : c.fuzzy_priority_score >= 3.5 ? 'var(--priority-medium)' : 'var(--priority-low)'};">${(c.fuzzy_priority_score || 5).toFixed(1)}</td>
            <td><span class="status-badge ${c.status}">${c.status}</span></td>
            <td style="font-size:0.8rem;">${formatDate(c.created_at)}</td>
            <td>
                <select class="status-select" onchange="updateComplaintStatus('${c.id}', this.value)">
                    <option value="submitted" ${c.status === 'submitted' ? 'selected' : ''}>Submitted</option>
                    <option value="assigned" ${c.status === 'assigned' ? 'selected' : ''}>Assigned</option>
                    <option value="in-progress" ${c.status === 'in-progress' ? 'selected' : ''}>In Progress</option>
                    <option value="resolved" ${c.status === 'resolved' ? 'selected' : ''}>Resolved</option>
                </select>
            </td>
        </tr>
    `).join('');
}

function filterComplaints(filter) {
    currentFilter = filter;
    document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`.filter-btn[data-filter="${filter}"]`).classList.add('active');

    if (filter === 'all') {
        renderAdminTable(allComplaints);
    } else {
        renderAdminTable(allComplaints.filter(c => c.priority === filter));
    }
}

async function updateComplaintStatus(id, newStatus) {
    try {
        const res = await fetch(`${API}/complaints/${id}/status`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: newStatus, notes: `Status updated to ${newStatus} by admin` })
        });
        const data = await res.json();
        if (!res.ok) return toast(data.error || 'Update failed', 'error');
        toast(`Status updated to "${newStatus}"`, 'success');
        loadAdminDashboard();
    } catch (err) {
        toast('Failed to update status', 'error');
    }
}

// ===================================
// ADMIN: ANALYTICS
// ===================================
async function loadAnalytics() {
    try {
        const [summaryRes, insightsRes, predictionsRes] = await Promise.all([
            fetch(`${API}/analytics/summary`),
            fetch(`${API}/analytics/insights`),
            fetch(`${API}/analytics/predictions`),
        ]);
        const data = await summaryRes.json();
        const insights = await insightsRes.json();
        const predictions = await predictionsRes.json();
        renderAnalyticsStats(data);
        renderInsightsPanel(insights);
        renderPredictionsPanel(predictions);
        renderCharts(data);
    } catch (err) {
        toast('Failed to load analytics', 'error');
    }
}

function renderAnalyticsStats(s) {
    document.getElementById('analyticsStats').innerHTML = `
        <div class="stat-card"><div class="stat-icon">📊</div><div class="stat-value">${s.total}</div><div class="stat-label">Total</div></div>
        <div class="stat-card resolved"><div class="stat-icon">✅</div><div class="stat-value">${s.resolved}</div><div class="stat-label">Resolved</div></div>
        <div class="stat-card pending"><div class="stat-icon">⏳</div><div class="stat-value">${s.pending}</div><div class="stat-label">Pending</div></div>
        <div class="stat-card"><div class="stat-icon">📈</div><div class="stat-value">${s.resolution_rate}%</div><div class="stat-label">Resolution Rate</div></div>
    `;
}

function renderCharts(data) {
    const container = document.getElementById('chartsContainer');
    const cats = data.by_category || [];
    const statuses = data.by_status || [];
    const priorities = data.by_priority || [];
    const depts = data.by_department || [];
    const maxCat = Math.max(...cats.map(c => c.count), 1);
    const maxStatus = Math.max(...statuses.map(s => s.count), 1);
    const maxPriority = Math.max(...priorities.map(p => p.count), 1);
    const maxDept = Math.max(...depts.map(d => d.count), 1);

    container.innerHTML = `
        <div class="chart-card">
            <h3>📊 Complaints by Category</h3>
            <div class="chart-bar-container">
                ${cats.map(c => `
                    <div class="chart-bar-row">
                        <span class="chart-bar-label">${c.category}</span>
                        <div class="chart-bar-track">
                            <div class="chart-bar-fill cat-${c.category.toLowerCase()}" style="width:${(c.count / maxCat * 100)}%">${c.count}</div>
                        </div>
                    </div>
                `).join('')}
            </div>
        </div>
        <div class="chart-card">
            <h3>📋 Complaints by Status</h3>
            <div class="chart-bar-container">
                ${statuses.map(s => `
                    <div class="chart-bar-row">
                        <span class="chart-bar-label">${s.status}</span>
                        <div class="chart-bar-track">
                            <div class="chart-bar-fill default" style="width:${(s.count / maxStatus * 100)}%;background:${statusColor(s.status)}">${s.count}</div>
                        </div>
                    </div>
                `).join('')}
            </div>
        </div>
        <div class="chart-card">
            <h3>🎯 Complaints by Priority (Fuzzy Logic)</h3>
            <div class="chart-bar-container">
                ${priorities.map(p => `
                    <div class="chart-bar-row">
                        <span class="chart-bar-label">${priorityIcon(p.priority)} ${p.priority}</span>
                        <div class="chart-bar-track">
                            <div class="chart-bar-fill" style="width:${(p.count / maxPriority * 100)}%;background:${priorityColor(p.priority)}">${p.count}</div>
                        </div>
                    </div>
                `).join('')}
            </div>
        </div>
        <div class="chart-card">
            <h3>🏛️ Complaints by Department</h3>
            <div class="chart-bar-container">
                ${depts.map(d => `
                    <div class="chart-bar-row">
                        <span class="chart-bar-label" style="width:180px;font-size:0.75rem;">${d.department}</span>
                        <div class="chart-bar-track">
                            <div class="chart-bar-fill default" style="width:${(d.count / maxDept * 100)}%">${d.count}</div>
                        </div>
                    </div>
                `).join('')}
            </div>
        </div>
    `;
}

// ===================================
// VOICE INPUT (Web Speech API)
// ===================================
let activeRecognition = null;

function startVoice(btnEl, inputId) {
    if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
        toast('Voice input not supported in this browser', 'error');
        return;
    }

    // If already listening, stop
    if (btnEl.classList.contains('listening')) {
        if (activeRecognition) activeRecognition.stop();
        btnEl.classList.remove('listening');
        btnEl.textContent = '🎤';
        return;
    }

    // Stop any previous
    if (activeRecognition) {
        activeRecognition.stop();
        document.querySelectorAll('.voice-btn.listening').forEach(b => {
            b.classList.remove('listening');
            b.textContent = '🎤';
        });
    }

    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
    const recognition = new SpeechRecognition();
    recognition.lang = 'en-IN';
    recognition.interimResults = false;
    recognition.maxAlternatives = 1;

    btnEl.classList.add('listening');
    btnEl.textContent = '⏹️';
    activeRecognition = recognition;

    recognition.onresult = (event) => {
        const transcript = event.results[0][0].transcript;
        const input = document.getElementById(inputId);
        if (input) {
            if (input.tagName === 'TEXTAREA') {
                input.value += (input.value ? ' ' : '') + transcript;
            } else {
                input.value = transcript;
            }
        }
        toast('✅ Voice captured!', 'success');
    };

    recognition.onerror = (event) => {
        console.error('Speech recognition error:', event.error);
        if (event.error !== 'aborted') {
            toast('Voice error: ' + event.error, 'error');
        }
    };

    recognition.onend = () => {
        btnEl.classList.remove('listening');
        btnEl.textContent = '🎤';
        activeRecognition = null;
    };

    recognition.start();
}

// ===================================
// GPS GEOLOCATION
// ===================================
function getGPS() {
    if (!navigator.geolocation) return toast('Geolocation not supported', 'error');

    toast('Detecting location...', 'info');
    navigator.geolocation.getCurrentPosition(
        async (pos) => {
            const { latitude, longitude } = pos.coords;
            try {
                const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`);
                const data = await res.json();
                const location = data.display_name || `${latitude}, ${longitude}`;
                document.getElementById('cLocation').value = location;
                toast('📍 Location detected!', 'success');
            } catch {
                document.getElementById('cLocation').value = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
                toast('📍 GPS coordinates captured', 'success');
            }
        },
        (err) => toast('Location access denied', 'error'),
        { enableHighAccuracy: true, timeout: 10000 }
    );
}

// ===================================
// UTILITIES
// ===================================
function toast(message, type = 'info') {
    const existing = document.querySelector('.toast');
    if (existing) existing.remove();

    const el = document.createElement('div');
    el.className = `toast ${type}`;
    el.textContent = message;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 3500);
}

function formatDate(dateStr) {
    if (!dateStr) return '-';
    try {
        const d = new Date(dateStr);
        return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
    } catch {
        return dateStr;
    }
}

function priorityIcon(priority) {
    return { high: '🔴', medium: '🟡', low: '🟢' }[priority] || '⚪';
}

function priorityColor(priority) {
    return { high: 'linear-gradient(90deg, #ef4444, #dc2626)', medium: 'linear-gradient(90deg, #f59e0b, #d97706)', low: 'linear-gradient(90deg, #10b981, #059669)' }[priority] || 'linear-gradient(90deg, #64748b, #475569)';
}

function statusColor(status) {
    return { submitted: 'linear-gradient(90deg, #3b82f6, #2563eb)', assigned: 'linear-gradient(90deg, #8b5cf6, #7c3aed)', 'in-progress': 'linear-gradient(90deg, #f59e0b, #d97706)', resolved: 'linear-gradient(90deg, #10b981, #059669)' }[status] || 'linear-gradient(90deg, #64748b, #475569)';
}

// ===================================
// OFFLINE SYNC SYSTEM
// ===================================
function saveToOfflineQueue(payload) {
    const queue = JSON.parse(localStorage.getItem(OFFLINE_QUEUE_KEY) || '[]');
    payload._offlineId = 'OFF_' + Date.now();
    payload._savedAt = new Date().toISOString();
    queue.push(payload);
    localStorage.setItem(OFFLINE_QUEUE_KEY, JSON.stringify(queue));
}

async function syncOfflineQueue() {
    const queue = JSON.parse(localStorage.getItem(OFFLINE_QUEUE_KEY) || '[]');
    if (queue.length === 0) return;

    toast(`📡 Syncing ${queue.length} offline complaint(s)...`, 'info');
    const remaining = [];

    for (const payload of queue) {
        try {
            const res = await fetch(`${API}/complaints`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (res.ok) {
                const data = await res.json();
                toast(`✅ Offline complaint synced! ID: ${data.complaint_id}`, 'success');
            } else {
                remaining.push(payload);
            }
        } catch {
            remaining.push(payload);
        }
    }

    localStorage.setItem(OFFLINE_QUEUE_KEY, JSON.stringify(remaining));
    if (remaining.length === 0) {
        toast('🎉 All offline complaints synced successfully!', 'success');
    } else {
        toast(`⚠️ ${remaining.length} complaint(s) still pending sync`, 'info');
    }
}

function updateOfflineBanner() {
    let banner = document.getElementById('offlineBanner');
    if (!navigator.onLine) {
        if (!banner) {
            banner = document.createElement('div');
            banner.id = 'offlineBanner';
            banner.style.cssText = 'position:fixed;top:0;left:0;right:0;background:linear-gradient(90deg,#f59e0b,#d97706);color:#000;text-align:center;padding:6px 12px;font-size:0.8rem;font-weight:600;z-index:9999;';
            banner.textContent = '📡 You are offline. Complaints will be saved locally and synced when online.';
            document.body.prepend(banner);
        }
    } else {
        if (banner) banner.remove();
    }
}

// ===================================
// COMMUNITY UPVOTE SYSTEM
// ===================================
async function upvoteComplaint(complaintId) {
    if (!currentUser) return toast('Please login to upvote', 'error');

    try {
        const res = await fetch(`${API}/complaints/${complaintId}/upvote`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username: currentUser.username })
        });
        const data = await res.json();
        if (res.status === 409) return toast('You already upvoted this complaint', 'info');
        if (!res.ok) return toast(data.error || 'Upvote failed', 'error');
        toast(`👍 Upvoted! Total votes: ${data.upvotes}`, 'success');
        // Refresh the view
        if (currentUser.role === 'admin') loadAdminDashboard();
        else loadMyComplaints();
    } catch (err) {
        toast('Failed to upvote', 'error');
    }
}

// ===================================
// PATTERN DETECTION & INSIGHTS PANEL
// ===================================
function renderInsightsPanel(data) {
    const container = document.getElementById('chartsContainer');
    const insights = data.insights || [];
    const hotspots = data.hotspots || [];
    const trending = data.trending || [];

    let html = `<div class="chart-card" style="grid-column:1/-1;">
        <h3>🧠 Complaint Pattern Detection</h3>`;

    if (insights.length === 0) {
        html += '<p style="color:var(--text-muted);font-size:0.85rem;padding:0.5rem 0;">No significant trends detected this week.</p>';
    } else {
        html += '<div style="display:flex;flex-direction:column;gap:0.5rem;margin-top:0.5rem;">';
        insights.forEach(i => {
            const color = i.severity === 'high' ? '#ef4444' : i.severity === 'medium' ? '#f59e0b' : '#10b981';
            const icon = i.type === 'spike' ? '📈' : i.type === 'decline' ? '📉' : '🆕';
            html += `<div style="background:${color}15;border-left:3px solid ${color};padding:0.6rem 0.8rem;border-radius:6px;font-size:0.85rem;">
                <strong>${icon} ${i.category.toUpperCase()}</strong>: ${i.message}
            </div>`;
        });
        html += '</div>';
    }

    // Hotspots
    if (hotspots.length > 0) {
        html += '<h4 style="margin-top:1rem;font-size:0.9rem;">📍 Complaint Hotspots (Last 30 days)</h4>';
        html += '<div style="display:flex;flex-wrap:wrap;gap:0.4rem;margin-top:0.4rem;">';
        hotspots.forEach(h => {
            html += `<span style="background:var(--bg-tertiary);padding:4px 10px;border-radius:12px;font-size:0.75rem;">${h.location.substring(0, 40)}... (${h.count})</span>`;
        });
        html += '</div>';
    }

    // Trending (most upvoted)
    if (trending.length > 0) {
        html += '<h4 style="margin-top:1rem;font-size:0.9rem;">🔥 Trending (Most Upvoted)</h4>';
        trending.forEach(t => {
            html += `<div style="display:flex;justify-content:space-between;padding:0.4rem 0;border-bottom:1px solid var(--border-color);font-size:0.8rem;">
                <span>${t.category} — ${t.description.substring(0, 50)}...</span>
                <span style="font-weight:700;">👍 ${t.upvotes}</span>
            </div>`;
        });
    }

    html += '</div>';
    container.insertAdjacentHTML('afterbegin', html);
}

// ===================================
// FUTURE ISSUE PREDICTION PANEL
// ===================================
function renderPredictionsPanel(data) {
    const container = document.getElementById('chartsContainer');
    const predictions = data.predictions || [];
    const seasonal = data.seasonal_alerts || [];

    let html = `<div class="chart-card" style="grid-column:1/-1;">
        <h3>🔮 Future Issue Predictions</h3>`;

    if (predictions.length === 0 && seasonal.length === 0) {
        html += '<p style="color:var(--text-muted);font-size:0.85rem;padding:0.5rem 0;">Not enough data for predictions yet.</p>';
    } else {
        html += '<div style="display:flex;flex-direction:column;gap:0.5rem;margin-top:0.5rem;">';
        predictions.forEach(p => {
            const color = p.risk_level === 'high' ? '#ef4444' : p.risk_level === 'medium' ? '#f59e0b' : '#10b981';
            const icon = p.trend === 'increasing' ? '⬆️' : p.trend === 'decreasing' ? '⬇️' : '➡️';
            html += `<div style="background:${color}15;border-left:3px solid ${color};padding:0.6rem 0.8rem;border-radius:6px;font-size:0.85rem;">
                <strong>${icon} ${p.category.toUpperCase()}</strong>: ${p.message}
                <div style="font-size:0.75rem;color:var(--text-muted);margin-top:0.2rem;">Avg: ${p.avg_weekly}/week | Confidence: ${p.confidence}</div>
            </div>`;
        });

        seasonal.forEach(s => {
            html += `<div style="background:#3b82f615;border-left:3px solid #3b82f6;padding:0.6rem 0.8rem;border-radius:6px;font-size:0.85rem;">
                <strong>📅 SEASONAL</strong>: ${s.message}
            </div>`;
        });
        html += '</div>';
    }

    html += '</div>';
    container.insertAdjacentHTML('afterbegin', html);
}
