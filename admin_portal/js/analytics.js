document.addEventListener('DOMContentLoaded', () => {
    const API_BASE = 'http://127.0.0.1:5000/api';
    const categoryCanvas = document.getElementById('complaintsChart');
    const statusCanvas = document.getElementById('resolutionTimeChart');

    let categoryChart = null;
    let statusChart = null;

    function toLabel(value) {
        if (!value) return 'Unknown';
        return String(value)
            .replace(/[-_]/g, ' ')
            .replace(/\b\w/g, (m) => m.toUpperCase());
    }

    function buildSeries(items, fallbackLabel = 'No Data') {
        if (!Array.isArray(items) || items.length === 0) {
            return { labels: [fallbackLabel], values: [0] };
        }
        return {
            labels: items.map((i) => toLabel(i.category || i.status || i.priority || i.department)),
            values: items.map((i) => Number(i.count || 0)),
        };
    }

    function renderCharts(summary) {
        const byCategory = buildSeries(summary.by_category, 'No Categories');
        const byStatus = buildSeries(summary.by_status, 'No Status Data');

        if (categoryChart) categoryChart.destroy();
        if (statusChart) statusChart.destroy();

        if (categoryCanvas) {
            categoryChart = new Chart(categoryCanvas, {
                type: 'bar',
                data: {
                    labels: byCategory.labels,
                    datasets: [{
                        label: 'Complaints by Category',
                        data: byCategory.values,
                        backgroundColor: 'rgba(52, 152, 219, 0.35)',
                        borderColor: 'rgba(52, 152, 219, 1)',
                        borderWidth: 1,
                    }],
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { display: true },
                    },
                    scales: {
                        y: { beginAtZero: true },
                    },
                },
            });
        }

        if (statusCanvas) {
            statusChart = new Chart(statusCanvas, {
                type: 'doughnut',
                data: {
                    labels: byStatus.labels,
                    datasets: [{
                        label: 'Complaints by Status',
                        data: byStatus.values,
                        backgroundColor: [
                            'rgba(241, 196, 15, 0.8)',
                            'rgba(52, 152, 219, 0.8)',
                            'rgba(46, 204, 113, 0.8)',
                            'rgba(231, 76, 60, 0.8)',
                        ],
                        borderColor: 'rgba(255, 255, 255, 1)',
                        borderWidth: 1,
                    }],
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: { position: 'bottom' },
                    },
                },
            });
        }
    }

    async function loadAnalytics() {
        try {
            const res = await fetch(`${API_BASE}/analytics/summary`);
            if (!res.ok) {
                throw new Error(`Analytics request failed (${res.status})`);
            }

            const summary = await res.json();
            renderCharts(summary);
        } catch (err) {
            console.error('Failed to load analytics:', err);
        }
    }

    loadAnalytics();
});
