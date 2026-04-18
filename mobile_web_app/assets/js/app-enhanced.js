/**
 * Civic Grievance System - ENHANCED VERSION
 * Features: Insights, Predictions, Map, Upvotes, Notifications
 */

const API = 'http://localhost:5000/api';
let currentUser = null;
let allComplaints = [];
let allInsights = [];
let allPredictions = [];
let map = null;
let markers = [];
let currentUserComplaintsCache = [];

// ========== INITIALIZATION ==========
document.addEventListener('DOMContentLoaded', () => {
    console.log('✅ ENHANCED APP LOADED');
    
    const saved = localStorage.getItem('cgs_user');
    if (saved) {
        try {
            currentUser = JSON.parse(saved);
            console.log('✅ User session restored:', currentUser);
            showUserMode();
            loadDashboard();
        } catch (e) {
            console.error('Session restore error:', e);
            localStorage.removeItem('cgs_user');
        }
    }
});

// ========== TOAST NOTIFICATIONS ==========
function showToast(message, type = 'info') {
    console.log(`[${type.toUpperCase()}] ${message}`);
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3500);
}

// ========== IN-APP NOTIFICATIONS ==========
function showNotification(message, type = 'info') {
    const panel = document.getElementById('notificationsPanel');
    const notif = document.createElement('div');
    notif.className = `notification ${type}`;
    notif.innerHTML = `
        <span>${message}</span>
        <button class="notification-close" onclick="this.parentElement.remove()">×</button>
    `;
    panel.appendChild(notif);
    setTimeout(() => notif.remove(), 5000);
}

// ========== UTILITIES ==========
function showUserMode() {
    document.getElementById('loginView').style.display = 'none';
    document.getElementById('appView').style.display = 'block';
    document.getElementById('appHeader').style.display = 'block';
    document.getElementById('userDisplay').textContent = `👋 ${currentUser.name}`;
    document.getElementById('roleDisplay').textContent = currentUser.role.toUpperCase();
    
    if (currentUser.role === 'admin') {
        document.getElementById('submit').style.display = 'none';
    } else {
        // Citizens see submit and mycomplaints
        document.querySelector('[data-section="mycomplaints"]').parentElement.style.display = 'inline';
    }
}

function logout() {
    currentUser = null;
    localStorage.removeItem('cgs_user');
    location.reload();
}

function switchRole(role) {
    document.querySelectorAll('.role-toggle button').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
}

function navigateTo(section) {
    // Hide all sections
    document.querySelectorAll('.section').forEach(s => {
        s.classList.remove('active');
    });
    
    // Remove active from all nav buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    
    // Show selected section
    const sectionEl = document.getElementById(section);
    if (sectionEl) {
        sectionEl.classList.add('active');
    }
    
    // Mark nav button as active
    event.target.classList.add('active');
    
    // Log navigation
    console.log('📍 Navigated to:', section);
    
    // Load data based on section
    switch(section) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'insights':
            loadInsights();
            break;
        case 'predictions':
            loadPredictions();
            break;
        case 'map':
            loadMap();
            break;
        case 'mycomplaints':
            loadMyComplaints();
            break;
    }
}

// ========== LOGIN ==========
async function handleLogin(e) {
    e.preventDefault();
    
    const username = document.getElementById('loginUsername').value.trim();
    const password = document.getElementById('loginPassword').value.trim();
    
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
        
        const data = await response.json();
        
        if (!response.ok) {
            showToast(data.error || 'Login failed', 'error');
            return;
        }
        
        currentUser = data.user;
        localStorage.setItem('cgs_user', JSON.stringify(currentUser));
        console.log('✅ Login successful:', currentUser);
        
        showToast(`Welcome, ${currentUser.name}!`, 'success');
        showUserMode();
        loadDashboard();
        
    } catch (error) {
        console.error('❌ Login error:', error);
        showToast('Connection error: ' + error.message, 'error');
    }
}

async function showRegisterForm() {
    const name = prompt('Full Name:');
    if (!name) return;
    
    const email = prompt('Email:');
    if (!email) return;
    
    const password = prompt('Password (min 4 chars):');
    if (!password) return;
    
    const phone = prompt('Phone Number:');
    
    try {
        const response = await fetch(`${API}/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, email, password, phone })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            showToast(data.error || 'Registration failed', 'error');
            return;
        }
        
        showToast('Registration successful! Please login.', 'success');
        
    } catch (error) {
        showToast('Registration error: ' + error.message, 'error');
    }
}

// ========== DASHBOARD ==========
async function loadDashboard() {
    try {
        const response = await fetch(`${API}/analytics/summary`);
        const data = await response.json();
        
        document.getElementById('statTotal').textContent = data.total;
        document.getElementById('statPending').textContent = data.pending;
        document.getElementById('statResolved').textContent = data.resolved;
        document.getElementById('statHighPriority').textContent = data.high_priority;
        document.getElementById('statPendingDetail').textContent = `${data.pending} pending`;
        document.getElementById('statResolvedRate').textContent = `${data.resolution_rate}% resolved`;
        
        // Load complaints
        const complaintResponse = await fetch(`${API}/complaints`);
        allComplaints = await complaintResponse.json();
        renderAdminTable(allComplaints);
        
        showNotification('📊 Dashboard updated', 'success');
    } catch (error) {
        console.error('Dashboard error:', error);
        showToast('Failed to load dashboard', 'error');
    }
}

function renderAdminTable(complaints) {
    const tbody = document.getElementById('adminTableBody');
    
    if (!complaints || complaints.length === 0) {
        tbody.innerHTML = '<tr><td colspan="8" style="text-align: center; padding: 2rem;">No complaints found</td></tr>';
        return;
    }
    
    tbody.innerHTML = complaints.map(c => `
        <tr>
            <td><strong>${c.id}</strong></td>
            <td>${c.category}</td>
            <td>${c.location}</td>
            <td><span class="priority-badge ${c.priority}">${c.priority.toUpperCase()}</span></td>
            <td><span class="dept-badge">${c.department || 'N/A'}</span></td>
            <td>
                <select class="status-select" onchange="updateComplaintStatus('${c.id}', this.value)">
                    <option value="submitted" ${c.status === 'submitted' ? 'selected' : ''}>Submitted</option>
                    <option value="assigned" ${c.status === 'assigned' ? 'selected' : ''}>Assigned</option>
                    <option value="in-progress" ${c.status === 'in-progress' ? 'selected' : ''}>In Progress</option>
                    <option value="resolved" ${c.status === 'resolved' ? 'selected' : ''}>Resolved</option>
                </select>
            </td>
            <td>
                <button class="upvote-btn" onclick="upvoteComplaint('${c.id}', '${currentUser.username}')">
                    👍 ${c.upvotes || 0}
                </button>
            </td>
            <td>
                <button onclick="viewComplaintDetails('${c.id}')" style="background: var(--info); border: none; color: white; padding: 0.4rem 0.8rem; border-radius: 6px; cursor: pointer;">View</button>
            </td>
        </tr>
    `).join('');
}

function filterComplaints(filter) {
    let filtered = allComplaints;
    
    if (filter === 'high') {
        filtered = allComplaints.filter(c => c.priority === 'high');
    } else if (filter === 'pending') {
        filtered = allComplaints.filter(c => c.status !== 'resolved');
    }
    
    renderAdminTable(filtered);
    
    // Update button active state
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    event.target.classList.add('active');
}

async function updateComplaintStatus(complaintId, newStatus) {
    try {
        const response = await fetch(`${API}/complaints/${complaintId}/status`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ status: newStatus })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            showToast(data.error || 'Update failed', 'error');
            return;
        }
        
        showNotification(`✅ Status updated to ${newStatus}`, 'success');
        loadDashboard();
    } catch (error) {
        showToast('Update error: ' + error.message, 'error');
    }
}

async function upvoteComplaint(complaintId, username) {
    try {
        const response = await fetch(`${API}/complaints/${complaintId}/upvote`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username })
        });
        
        const data = await response.json();
        
        if (!response.ok) {
            showToast(data.error || 'Upvote failed', 'error');
            return;
        }
        
        showNotification(`👍 Upvoted! (${data.upvotes} total)`, 'success');
        loadDashboard();
    } catch (error) {
        showToast('Upvote error: ' + error.message, 'error');
    }
}

async function viewComplaintDetails(complaintId) {
    try {
        const response = await fetch(`${API}/complaints/${complaintId}`);
        const data = await response.json();
        
        const details = `
Complaint ID: ${data.id}
Category: ${data.category}
Location: ${data.location}
Status: ${data.status}
Priority: ${data.priority}
Department: ${data.department}

Description:
${data.description}

Submitted by: ${data.name} (${data.phone})
Submitted at: ${data.created_at}
        `;
        
        alert(details);
    } catch (error) {
        showToast('Failed to load details', 'error');
    }
}

// ========== INSIGHTS ==========
async function loadInsights() {
    try {
        console.log('📊 Loading insights...');
        
        const response = await fetch(`${API}/analytics/insights`);
        const data = await response.json();
        
        // Render insights
        const container = document.getElementById('insightsContainer');
        if (!data.insights || data.insights.length === 0) {
            container.innerHTML = '<p style="text-align: center; color: var(--text-secondary);">No significant trends detected yet</p>';
        } else {
            container.innerHTML = data.insights.map(insight => `
                <div class="insight-card ${insight.severity}">
                    <div class="insight-message">
                        ${insight.type === 'spike' ? '📈' : insight.type === 'decline' ? '📉' : '🆕'} 
                        ${insight.message}
                    </div>
                    <div class="insight-stats">
                        <span>Last Week: ${insight.previous}</span>
                        <span>This Week: ${insight.current}</span>
                        <span style="color: ${insight.change_pct > 0 ? '#fca5a5' : '#86efac'}">${insight.change_pct > 0 ? '+' : ''}${insight.change_pct}%</span>
                    </div>
                </div>
            `).join('');
        }
        
        // Render hotspots
        const hotspotsGrid = document.getElementById('hotspotsGrid');
        if (!data.hotspots || data.hotspots.length === 0) {
            hotspotsGrid.innerHTML = '<p style="grid-column: 1/-1; text-align: center;">No hotspots data available</p>';
        } else {
            hotspotsGrid.innerHTML = data.hotspots.map(hs => `
                <div class="hotspot-badge">
                    <div class="hotspot-location">📍 ${hs.location}</div>
                    <div class="hotspot-count">${hs.count} complaints</div>
                </div>
            `).join('');
        }
        
        // Render trending
        const trendingContainer = document.getElementById('trendingContainer');
        if (!data.trending || data.trending.length === 0) {
            trendingContainer.innerHTML = '<p style="text-align: center;">No trending complaints yet</p>';
        } else {
            trendingContainer.innerHTML = data.trending.map(tr => `
                <div class="trending-card">
                    <div class="trending-info">
                        <div class="trending-category">${tr.category.toUpperCase()}</div>
                        <div class="trending-desc">${tr.description}</div>
                        <div class="trending-location">📍 ${tr.location}</div>
                    </div>
                    <div class="trending-upvotes">👍 ${tr.upvotes}</div>
                </div>
            `).join('');
        }
        
        showNotification('📊 Insights loaded', 'success');
    } catch (error) {
        console.error('Insights error:', error);
        showToast('Failed to load insights', 'error');
    }
}

// ========== PREDICTIONS ==========
async function loadPredictions() {
    try {
        console.log('🔮 Loading predictions...');
        
        const response = await fetch(`${API}/analytics/predictions`);
        const data = await response.json();
        
        // Render predictions
        const container = document.getElementById('predictionsContainer');
        if (!data.predictions || data.predictions.length === 0) {
            container.innerHTML = '<p style="text-align: center;">Not enough data for predictions yet</p>';
        } else {
            container.innerHTML = data.predictions.map(pred => `
                <div class="prediction-card">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <div style="font-size: 1.1rem; font-weight: 600; margin-bottom: 0.5rem;">
                                ${pred.category.toUpperCase()}
                            </div>
                            <div style="color: var(--text-secondary); margin-bottom: 0.5rem;">
                                ${pred.message}
                            </div>
                            <div style="font-size: 0.9rem; color: var(--text-secondary);">
                                <span>Average: ${pred.avg_weekly}/week</span> | 
                                <span>Predicted: ~${pred.predicted_next_week} next week</span> |
                                <span class="prediction-trend ${pred.trend}">${pred.trend.toUpperCase()}</span>
                            </div>
                        </div>
                        <div style="text-align: right;">
                            <div style="font-size: 0.85rem; color: var(--text-secondary); margin-bottom: 0.5rem;">Risk Level</div>
                            <div style="
                                display: inline-block;
                                padding: 0.5rem 1rem;
                                border-radius: 6px;
                                font-weight: 600;
                                background: ${pred.risk_level === 'high' ? 'rgba(239, 68, 68, 0.2)' : pred.risk_level === 'medium' ? 'rgba(245, 158, 11, 0.2)' : 'rgba(16, 185, 129, 0.2)'};
                                color: ${pred.risk_level === 'high' ? '#fca5a5' : pred.risk_level === 'medium' ? '#fcd34d' : '#86efac'};
                            ">
                                ${pred.risk_level.toUpperCase()}
                            </div>
                        </div>
                    </div>
                </div>
            `).join('');
        }
        
        // Render seasonal alerts
        const alertsContainer = document.getElementById('seasonalAlertsContainer');
        if (!data.seasonal_alerts || data.seasonal_alerts.length === 0) {
            alertsContainer.innerHTML = '<p style="text-align: center;">No seasonal patterns detected</p>';
        } else {
            alertsContainer.innerHTML = data.seasonal_alerts.map(alert => `
                <div class="insight-card medium">
                    <div class="insight-message">⚠️ ${alert.message}</div>
                </div>
            `).join('');
        }
        
        showNotification('🔮 Predictions loaded', 'success');
    } catch (error) {
        console.error('Predictions error:', error);
        showToast('Failed to load predictions', 'error');
    }
}

// ========== MAP ==========
let mapInitialized = false;

async function loadMap() {
    try {
        if (!mapInitialized) {
            initializeMap();
            mapInitialized = true;
        }
        
        console.log('🗺️ Loading map data...');
        
        const response = await fetch(`${API}/complaints`);
        const complaints = await response.json();
        
        // Clear existing markers
        markers.forEach(marker => map.removeLayer(marker));
        markers = [];
        
        // Add new markers
        complaints.forEach(complaint => {
            // Use approximate lat/long for Indian cities
            let lat = 28.7041; // Delhi default
            let lng = 77.1025;
            
            // You can add location mapping here
            const locationMap = {
                'north': { lat: 28.7, lng: 77.1 },
                'south': { lat: 13.0, lng: 80.2 },
                'east': { lat: 22.5, lng: 88.4 },
                'west': { lat: 19.0, lng: 72.8 },
                'central': { lat: 23.2, lng: 79.9 }
            };
            
            const locKey = Object.keys(locationMap).find(key => 
                complaint.location.toLowerCase().includes(key)
            );
            
            if (locKey) {
                const coords = locationMap[locKey];
                lat = coords.lat + (Math.random() - 0.5) * 0.5;
                lng = coords.lng + (Math.random() - 0.5) * 0.5;
            }
            
            const priorityColor = complaint.priority === 'high' ? '#ef4444' : 
                                 complaint.priority === 'medium' ? '#f59e0b' : '#10b981';
            
            const popupText = `
                <strong>${complaint.category}</strong><br>
                ${complaint.location}<br>
                Priority: ${complaint.priority}<br>
                Status: ${complaint.status}<br>
                Dept: ${complaint.department || 'N/A'}
            `;
            
            const marker = L.circleMarker([lat, lng], {
                radius: 8,
                fillColor: priorityColor,
                color: '#fff',
                weight: 2,
                opacity: 0.8,
                fillOpacity: 0.7
            }).bindPopup(popupText).addTo(map);
            
            markers.push(marker);
        });
        
        showNotification(`🗺️ ${complaints.length} complaints plotted`, 'success');
    } catch (error) {
        console.error('Map error:', error);
        showToast('Failed to load map', 'error');
    }
}

function initializeMap() {
    map = L.map('mapContainer').setView([20, 78.5], 4);
    
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors',
        maxZoom: 19
    }).addTo(map);
}

// ========== SUBMIT COMPLAINT ==========
function suggestDepartment() {
    const category = document.getElementById('submitCategory').value;
    const description = document.getElementById('submitDescription').value;
    
    let dept = 'General Administration';
    
    const categoryDept = {
        'water': 'Water Supply Department',
        'electricity': 'Electricity Board',
        'roads': 'Roads & Transportation Dept',
        'garbage': 'Sanitation Department',
        'drainage': 'Drainage & Sewerage Dept',
        'streetlight': 'Electricity Board',
        'noise': 'Environmental Department',
        'other': 'General Administration'
    };
    
    if (categoryDept[category]) {
        dept = categoryDept[category];
    }
    
    const info = document.getElementById('autoDeptInfo');
    const deptName = document.getElementById('autoDeptName');
    
    if (category) {
        info.style.display = 'block';
        info.classList.add('assigned');
        deptName.textContent = dept;
    } else {
        info.style.display = 'none';
    }
}

async function handleSubmit(e) {
    e.preventDefault();
    
    const formData = {
        name: document.getElementById('submitName').value,
        email: document.getElementById('submitEmail').value,
        phone: document.getElementById('submitPhone').value,
        category: document.getElementById('submitCategory').value,
        location: document.getElementById('submitLocation').value,
        description: document.getElementById('submitDescription').value,
        username: currentUser.username
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
        
        showNotification(`✅ Complaint submitted! ID: ${data.complaint_id}`, 'success');
        showNotification(`📋 Auto-assigned to: ${data.department}`, 'info');
        showNotification(`⚡ Priority: ${data.priority.toUpperCase()}`, 'info');
        
        // Reset form
        document.getElementById('submitForm').reset();
        document.getElementById('autoDeptInfo').style.display = 'none';
        
        // Navigate to my complaints
        setTimeout(() => {
            navigateTo('mycomplaints');
        }, 1500);
        
    } catch (error) {
        showToast('Submission error: ' + error.message, 'error');
    }
}

// ========== MY COMPLAINTS ==========
async function loadMyComplaints() {
    try {
        console.log('📁 Loading my complaints...');
        
        const params = currentUser.role === 'admin' ? 
            `?username=${currentUser.username}` : 
            `?phone=${currentUser.phone || ''}`;
        
        const response = await fetch(`${API}/complaints/mine${params}`);
        const data = await response.json();
        
        const tbody = document.getElementById('myComplaintsTable');
        const complaints = data || [];
        
        if (complaints.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding: 2rem;">No complaints submitted yet</td></tr>';
            return;
        }
        
        tbody.innerHTML = complaints.map(c => `
            <tr>
                <td><strong>${c.id}</strong></td>
                <td>${c.category}</td>
                <td>${c.location}</td>
                <td><span class="status-badge ${c.status}">${c.status}</span></td>
                <td>${new Date(c.created_at).toLocaleDateString()}</td>
                <td>
                    <button class="upvote-btn" onclick="upvoteComplaint('${c.id}', '${currentUser.username}')">
                        👍 ${c.upvotes || 0}
                    </button>
                </td>
                <td>
                    <button onclick="viewComplaintDetails('${c.id}')" style="background: var(--info); border: none; color: white; padding: 0.4rem 0.8rem; border-radius: 6px; cursor: pointer;">View</button>
                </td>
            </tr>
        `).join('');
        
    } catch (error) {
        console.error('My complaints error:', error);
        showToast('Failed to load complaints', 'error');
    }
}

// ========== INITIAL STATE ==========
console.log('🚀 Enhanced App initialized and ready');
