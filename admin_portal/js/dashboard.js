document.addEventListener('DOMContentLoaded', () => {
    const API_BASE = 'http://127.0.0.1:5000/api';
    const syncStatusEl = document.getElementById('syncStatus');
    const refreshBtn = document.getElementById('refreshBtn');
    const complaintsBody = document.getElementById('complaintsTableBody');
    const activityList = document.getElementById('activity-list');

    let map = null;
    let markersLayer = null;

    if (document.getElementById('map')) {
        map = L.map('map').setView([20.5937, 78.9629], 5); // Default center (India)
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(map);
        markersLayer = L.layerGroup().addTo(map);
    }

    function setSyncStatus(message, isError = false) {
        if (!syncStatusEl) return;
        syncStatusEl.textContent = message;
        syncStatusEl.classList.toggle('error-text', isError);
    }

    function formatDate(value) {
        if (!value) return '-';
        const parsed = new Date(value);
        if (Number.isNaN(parsed.getTime())) return String(value);
        return parsed.toLocaleString();
    }

    function renderStats(summary) {
        const totalEl = document.getElementById('totalComplaints');
        const resolvedEl = document.getElementById('resolvedComplaints');
        const pendingEl = document.getElementById('pendingComplaints');

        if (totalEl) totalEl.textContent = String(summary.total ?? 0);
        if (resolvedEl) resolvedEl.textContent = String(summary.resolved ?? 0);
        if (pendingEl) pendingEl.textContent = String(summary.pending ?? 0);
    }

    function renderActivity(recentItems) {
        if (!activityList) return;

        if (!Array.isArray(recentItems) || recentItems.length === 0) {
            activityList.innerHTML = '<div class="table-empty">No recent complaint activity yet.</div>';
            return;
        }

        activityList.innerHTML = recentItems.map((item) => `
            <div class="activity-item">
                <div>
                    <strong>${item.id}</strong> - ${item.category || 'other'}
                </div>
                <div class="activity-meta">
                    <span class="badge badge-${item.status || 'submitted'}">${item.status || 'submitted'}</span>
                    <span class="badge badge-${item.priority || 'medium'}">${item.priority || 'medium'}</span>
                    <span>${formatDate(item.created_at)}</span>
                </div>
            </div>
        `).join('');
    }

    function renderComplaints(complaints) {
        if (!complaintsBody) return;

        if (!Array.isArray(complaints) || complaints.length === 0) {
            complaintsBody.innerHTML = `
                <tr>
                    <td colspan="7" class="table-empty">No complaints found.</td>
                </tr>
            `;
            return;
        }

        const sortedComplaints = [...complaints].sort((a, b) => {
            const ta = new Date(a.created_at || 0).getTime();
            const tb = new Date(b.created_at || 0).getTime();
            return tb - ta;
        });

        complaintsBody.innerHTML = sortedComplaints.map((c) => `
            <tr>
                <td class="mono-cell">${c.id}</td>
                <td>${c.category || '-'}</td>
                <td>${c.department || '-'}</td>
                <td><span class="badge badge-${c.status || 'submitted'}">${c.status || 'submitted'}</span></td>
                <td><span class="badge badge-${c.priority || 'medium'}">${c.priority || 'medium'}</span></td>
                <td>${formatDate(c.created_at)}</td>
                <td>
                    <select class="status-select" data-id="${c.id}">
                        <option value="submitted" ${c.status === 'submitted' ? 'selected' : ''}>Submitted</option>
                        <option value="assigned" ${c.status === 'assigned' ? 'selected' : ''}>Assigned</option>
                        <option value="in-progress" ${c.status === 'in-progress' ? 'selected' : ''}>In Progress</option>
                        <option value="resolved" ${c.status === 'resolved' ? 'selected' : ''}>Resolved</option>
                    </select>
                </td>
            </tr>
        `).join('');
    }

    function renderMap(complaints) {
        if (!map || !markersLayer || !Array.isArray(complaints)) return;
        markersLayer.clearLayers();

        let hasMarkers = false;
        const bounds = L.latLngBounds();

        complaints.forEach((c) => {
            if (c.latitude && c.longitude) {
                const marker = L.marker([c.latitude, c.longitude])
                    .bindPopup(`<b>ID: ${c.id}</b><br>Category: ${c.category || 'Other'}<br>Status: ${c.status || 'submitted'}`);
                markersLayer.addLayer(marker);
                bounds.extend([c.latitude, c.longitude]);
                hasMarkers = true;
            }
        });

        if (hasMarkers) {
            map.fitBounds(bounds, { padding: [50, 50], maxZoom: 15 });
        }
    }

    async function loadDashboard() {
        setSyncStatus('Refreshing data...');
        try {
            const [summaryRes, complaintsRes] = await Promise.all([
                fetch(`${API_BASE}/analytics/summary`),
                fetch(`${API_BASE}/complaints`),
            ]);

            if (!summaryRes.ok) {
                throw new Error(`Summary request failed (${summaryRes.status})`);
            }
            if (!complaintsRes.ok) {
                throw new Error(`Complaints request failed (${complaintsRes.status})`);
            }

            const summary = await summaryRes.json();
            const complaints = await complaintsRes.json();

            renderStats(summary);
            renderActivity(summary.recent || []);
            renderComplaints(complaints);
            renderMap(complaints);
            setSyncStatus(`Last updated: ${new Date().toLocaleTimeString()}`);
        } catch (err) {
            console.error('Dashboard load failed:', err);
            setSyncStatus('Backend connection failed. Start backend on port 5000.', true);
            if (complaintsBody) {
                complaintsBody.innerHTML = `
                    <tr>
                        <td colspan="7" class="table-empty">Could not load complaints. Check backend server.</td>
                    </tr>
                `;
            }
            if (activityList) {
                activityList.innerHTML = '<div class="table-empty">Could not load activity feed.</div>';
            }
        }
    }

    async function updateComplaintStatus(complaintId, newStatus) {
        setSyncStatus(`Updating ${complaintId}...`);
        try {
            const res = await fetch(`${API_BASE}/complaints/${encodeURIComponent(complaintId)}/status`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ status: newStatus }),
            });

            const payload = await res.json().catch(() => ({}));
            if (!res.ok) {
                throw new Error(payload.error || `Status update failed (${res.status})`);
            }

            await loadDashboard();
        } catch (err) {
            console.error('Status update failed:', err);
            setSyncStatus(String(err), true);
        }
    }

    if (complaintsBody) {
        complaintsBody.addEventListener('change', (event) => {
            const target = event.target;
            if (!(target instanceof HTMLSelectElement)) return;
            if (!target.classList.contains('status-select')) return;

            const complaintId = target.getAttribute('data-id');
            const newStatus = target.value;
            if (!complaintId || !newStatus) return;

            updateComplaintStatus(complaintId, newStatus);
        });
    }

    if (refreshBtn) {
        refreshBtn.addEventListener('click', () => {
            loadDashboard();
        });
    }

    loadDashboard();
    setInterval(loadDashboard, 30000);
});
