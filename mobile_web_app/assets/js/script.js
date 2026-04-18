// ===================================
// Civic Grievance System - Main Script
// Form Handling, API Integration, UI Logic
// ===================================

// Configuration
const API_BASE_URL = 'http://localhost:5000/api'; // Backend API URL
const STORAGE_KEY = 'civic_grievance_draft';

// ===================================
// Utility Functions
// ===================================

// Show toast notification
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <div style="flex: 1;">
            <strong>${type === 'success' ? '✅' : type === 'error' ? '❌' : 'ℹ️'}</strong>
            <span style="margin-left: 0.5rem;">${message}</span>
        </div>
    `;

    container.appendChild(toast);

    // Auto remove after 4 seconds
    setTimeout(() => {
        toast.style.animation = 'slideInRight 0.3s ease reverse';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    const options = {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    };
    return date.toLocaleDateString('en-US', options);
}

// ===================================
// Complaint Submission (index.html)
// ===================================

if (document.getElementById('complaintForm')) {
    const form = document.getElementById('complaintForm');
    const categorySelect = document.getElementById('category');
    const submitBtn = document.getElementById('submitBtn');
    const getLocationBtn = document.getElementById('getLocationBtn');
    const locationInput = document.getElementById('location');
    const locationStatus = document.getElementById('locationStatus');
    const evidenceInput = document.getElementById('evidence');
    const filePreview = document.getElementById('filePreview');

    // Load draft from localStorage
    loadDraft();

    // Save draft on input
    form.addEventListener('input', saveDraft);

    // Geolocation
    if (getLocationBtn) {
        getLocationBtn.addEventListener('click', getLocation);
    }

    // File upload preview
    if (evidenceInput) {
        evidenceInput.addEventListener('change', handleFileUpload);
    }

    // Category select styling and department display
    const departmentGroup = document.getElementById('departmentGroup');
    const departmentInput = document.getElementById('department');

    if (categorySelect) {
        // Initial check
        updateCategoryStyle();

        // On change
        categorySelect.addEventListener('change', updateCategoryStyle);
    }

    function updateCategoryStyle() {
        if (categorySelect.value) {
            categorySelect.classList.add('filled');

            // Show department and populate it
            const department = getDepartmentFromCategory(categorySelect.value);
            if (departmentInput && departmentGroup) {
                departmentInput.value = department;
                departmentGroup.style.display = 'block';

                // Add a smooth animation
                departmentGroup.style.animation = 'fadeIn 0.3s ease';
            }
        } else {
            categorySelect.classList.remove('filled');

            // Hide department field
            if (departmentGroup) {
                departmentGroup.style.display = 'none';
            }
        }
    }

    // Form submission
    form.addEventListener('submit', handleSubmit);

    // Get user location
    function getLocation() {
        if (!navigator.geolocation) {
            showToast('Geolocation is not supported by your browser', 'error');
            return;
        }

        getLocationBtn.disabled = true;
        getLocationBtn.innerHTML = '<span class="spinner"></span> Getting...';
        locationStatus.textContent = '📍 Getting your location...';

        navigator.geolocation.getCurrentPosition(
            (position) => {
                const { latitude, longitude } = position.coords;

                // Use reverse geocoding API (example with OpenStreetMap)
                fetch(`https://nominatim.openstreetmap.org/reverse?lat=${latitude}&lon=${longitude}&format=json`)
                    .then(response => response.json())
                    .then(data => {
                        const address = data.display_name || `${latitude}, ${longitude}`;
                        locationInput.value = address;
                        locationStatus.textContent = '✅ Location detected successfully';
                        showToast('Location detected successfully', 'success');
                    })
                    .catch(error => {
                        locationInput.value = `${latitude}, ${longitude}`;
                        locationStatus.textContent = '✅ Coordinates captured';
                        showToast('Location coordinates captured', 'success');
                    })
                    .finally(() => {
                        getLocationBtn.disabled = false;
                        getLocationBtn.innerHTML = '📍 GPS';
                    });
            },
            (error) => {
                let errorMessage = 'Unable to get location';
                switch (error.code) {
                    case error.PERMISSION_DENIED:
                        errorMessage = 'Location permission denied';
                        break;
                    case error.POSITION_UNAVAILABLE:
                        errorMessage = 'Location information unavailable';
                        break;
                    case error.TIMEOUT:
                        errorMessage = 'Location request timed out';
                        break;
                }
                locationStatus.textContent = `❌ ${errorMessage}`;
                showToast(errorMessage, 'error');
                getLocationBtn.disabled = false;
                getLocationBtn.innerHTML = '📍 GPS';
            }
        );
    }

    // Handle file upload
    function handleFileUpload(e) {
        const file = e.target.files[0];
        if (!file) {
            filePreview.classList.add('hidden');
            return;
        }

        // Validate file type
        if (!file.type.startsWith('image/')) {
            showToast('Please upload an image file', 'error');
            evidenceInput.value = '';
            return;
        }

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
            showToast('File size must be less than 5MB', 'error');
            evidenceInput.value = '';
            return;
        }

        // Show preview
        const reader = new FileReader();
        reader.onload = (e) => {
            filePreview.innerHTML = `<img src="${e.target.result}" alt="Evidence preview">`;
            filePreview.classList.remove('hidden');
        };
        reader.readAsDataURL(file);
    }

    // Handle form submission
    async function handleSubmit(e) {
        e.preventDefault();

        // Disable submit button
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="spinner"></span> Submitting...';

        // Prepare form data
        const formData = new FormData(form);

        try {
            const response = await fetch(`${API_BASE_URL}/complaints`, {
                method: 'POST',
                body: formData
            });

            let data = {};
            try {
                data = await response.json();
            } catch (parseError) {
                data = {};
            }

            if (!response.ok) {
                throw new Error(data.error || 'Failed to submit complaint');
            }

            const complaintId = data.complaint_id;
            if (!complaintId) {
                throw new Error('Complaint was submitted but no ID was returned by the server');
            }

            // Clear draft
            localStorage.removeItem(STORAGE_KEY);

            // Show success message
            showToast('Complaint submitted successfully!', 'success');

            // Show complaint ID and server-calculated routing details
            setTimeout(() => {
                alert(`✅ Complaint Submitted Successfully!\n\nYour Complaint ID: ${complaintId}\nPriority: ${(data.priority || 'medium').toUpperCase()}\nDepartment: ${data.department || 'General Administration'}\n\nPlease save this ID to track your complaint status.`);

                // Reset form
                form.reset();
                filePreview.classList.add('hidden');
                locationStatus.textContent = '';

                // Redirect to track page after 2 seconds
                setTimeout(() => {
                    window.location.href = `track.html?id=${encodeURIComponent(complaintId)}`;
                }, 2000);
            }, 500);

        } catch (error) {
            console.error('Error submitting complaint:', error);
            showToast(error.message || 'Failed to submit complaint. Please try again.', 'error');
        } finally {
            submitBtn.disabled = false;
            submitBtn.innerHTML = 'Submit Complaint';
        }
    }

    // Get department based on category
    function getDepartmentFromCategory(category) {
        const departmentMap = {
            'roads': 'Public Works Department',
            'water': 'Water Supply Department',
            'electricity': 'Electricity Board',
            'sanitation': 'Sanitation Department',
            'drainage': 'Drainage & Sewage Department',
            'streetlights': 'Municipal Corporation',
            'parks': 'Parks & Recreation Department',
            'noise': 'Environmental Department',
            'other': 'General Administration'
        };
        return departmentMap[category] || 'General Administration';
    }

    // Save draft to localStorage
    function saveDraft() {
        const formData = new FormData(form);
        const draft = {
            name: formData.get('name'),
            email: formData.get('email'),
            phone: formData.get('phone'),
            category: formData.get('category'),
            location: formData.get('location'),
            description: formData.get('description')
        };
        localStorage.setItem(STORAGE_KEY, JSON.stringify(draft));
    }

    // Load draft from localStorage
    function loadDraft() {
        const draft = localStorage.getItem(STORAGE_KEY);
        if (!draft) return;

        try {
            const data = JSON.parse(draft);
            Object.keys(data).forEach(key => {
                const input = form.elements[key];
                if (input && data[key]) {
                    input.value = data[key];
                }
            });
            showToast('Draft restored', 'info');
        } catch (error) {
            console.error('Error loading draft:', error);
        }
    }
}

// ===================================
// Complaint Tracking (track.html)
// ===================================

if (document.getElementById('searchInput')) {
    const searchInput = document.getElementById('searchInput');
    const searchBtn = document.getElementById('searchBtn');
    const resultsContainer = document.getElementById('resultsContainer');
    const noResults = document.getElementById('noResults');
    const refreshBtn = document.getElementById('refreshBtn');
    const newSearchBtn = document.getElementById('newSearchBtn');

    // Check URL parameters for complaint ID
    const urlParams = new URLSearchParams(window.location.search);
    const complaintIdFromUrl = urlParams.get('id');
    if (complaintIdFromUrl) {
        searchInput.value = complaintIdFromUrl;
        searchComplaint();
    }

    // Search button click
    searchBtn.addEventListener('click', searchComplaint);

    // Enter key on search input
    searchInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            searchComplaint();
        }
    });

    // Refresh button
    if (refreshBtn) {
        refreshBtn.addEventListener('click', () => {
            searchComplaint();
            showToast('Status refreshed', 'info');
        });
    }

    // New search button
    if (newSearchBtn) {
        newSearchBtn.addEventListener('click', () => {
            resultsContainer.classList.add('hidden');
            noResults.classList.add('hidden');
            searchInput.value = '';
            searchInput.focus();
        });
    }

    // Search for complaint
    async function searchComplaint() {
        const query = searchInput.value.trim();

        if (!query) {
            showToast('Please enter a Complaint ID or Phone Number', 'error');
            return;
        }

        // Show loading
        searchBtn.disabled = true;
        searchBtn.innerHTML = '<span class="spinner"></span> Searching...';

        try {
            const response = await fetch(`${API_BASE_URL}/complaints/search?q=${query}`);
            const data = await response.json();

            if (!response.ok || !Array.isArray(data.results) || data.results.length === 0) {
                showNoResults();
                return;
            }

            const complaintId = data.results[0].id;
            const detailResponse = await fetch(`${API_BASE_URL}/complaints/${encodeURIComponent(complaintId)}`);
            if (!detailResponse.ok) {
                showNoResults();
                return;
            }

            const complaint = await detailResponse.json();
            displayComplaint(complaint);

        } catch (error) {
            console.error('Error searching complaint:', error);
            showToast('Failed to search complaint. Please try again.', 'error');
        } finally {
            searchBtn.disabled = false;
            searchBtn.innerHTML = 'Search Complaint';
        }
    }

    // Display complaint details
    function displayComplaint(complaint) {
        resultsContainer.classList.remove('hidden');
        noResults.classList.add('hidden');

        const complaintId = complaint.id || complaint.complaint_id || '-';
        const submittedAt = complaint.created_at || complaint.timestamp;

        // Basic details
        document.getElementById('complaintId').textContent = complaintId;
        document.getElementById('complaintCategory').textContent = getCategoryLabel(complaint.category);
        document.getElementById('complaintDepartment').textContent = complaint.department;
        document.getElementById('complaintLocation').textContent = complaint.location;
        document.getElementById('complaintDate').textContent = submittedAt ? formatDate(submittedAt) : '-';
        document.getElementById('complaintDescription').textContent = complaint.description;

        // Priority badge
        const priorityBadge = document.getElementById('priorityBadge');
        priorityBadge.className = `badge badge-${complaint.priority || 'medium'}`;
        priorityBadge.textContent = (complaint.priority || 'medium').toUpperCase();

        // Timeline
        updateTimeline(complaint);

        // Estimated resolution
        document.getElementById('estimatedResolution').textContent =
            complaint.estimatedResolution || '3-5 business days';

        // Scroll to results
        resultsContainer.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }

    // Update timeline based on status
    function updateTimeline(complaint) {
        const status = complaint.status || 'submitted';
        const statuses = ['submitted', 'assigned', 'in-progress', 'resolved'];
        const currentIndex = statuses.indexOf(status);
        const history = Array.isArray(complaint.history) ? complaint.history : [];
        const historyByStatus = {};
        const submittedAt = complaint.created_at || complaint.timestamp;

        history.forEach(entry => {
            if (entry && entry.status && entry.changed_at && !historyByStatus[entry.status]) {
                historyByStatus[entry.status] = entry.changed_at;
            }
        });

        // Update timeline items
        const items = ['submittedTime', 'assignedTime', 'progressTime', 'resolvedTime'];
        const itemElements = ['assignedItem', 'progressItem', 'resolvedItem'];

        // Set submitted time
        document.getElementById('submittedTime').textContent =
            historyByStatus.submitted ? formatDate(historyByStatus.submitted) :
            submittedAt ? formatDate(submittedAt) :
            'Pending';

        // Update other timeline items
        itemElements.forEach((itemId, index) => {
            const item = document.getElementById(itemId);
            const timeElement = document.getElementById(items[index + 1]);
            const timelineStatus = statuses[index + 1];
            const changedAt = historyByStatus[timelineStatus];

            if (index < currentIndex) {
                item.classList.add('active');
                timeElement.textContent = changedAt ? formatDate(changedAt) : 'Updated';
            } else if (index === currentIndex) {
                item.classList.add('active');
                timeElement.textContent = changedAt ? formatDate(changedAt) : 'In Progress';
            } else {
                item.classList.remove('active');
                timeElement.textContent = 'Pending';
            }
        });
    }

    // Show no results
    function showNoResults() {
        resultsContainer.classList.add('hidden');
        noResults.classList.remove('hidden');
    }

    // Get category label
    function getCategoryLabel(category) {
        const labels = {
            'roads': '🛣️ Roads & Infrastructure',
            'water': '💧 Water Supply',
            'electricity': '⚡ Electricity',
            'sanitation': '🧹 Sanitation & Cleanliness',
            'drainage': '🌊 Drainage & Sewage',
            'streetlights': '💡 Street Lights',
            'parks': '🌳 Parks & Gardens',
            'noise': '🔊 Noise Pollution',
            'other': '📋 Other'
        };
        return labels[category] || category;
    }
}
