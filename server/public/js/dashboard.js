// Dashboard JavaScript
const API_BASE = window.location.origin;
let refreshInterval = null;

// Format timestamp to readable date
function formatTimestamp(timestamp) {
    return new Date(timestamp * 1000).toLocaleString();
}

// Fetch and update dashboard stats
async function updateDashboard() {
    try {
        const response = await fetch(`${API_BASE}/api/admin/stats`);
        const result = await response.json();

        if (result.success) {
            const data = result.data;

            // Update server stats
            document.getElementById('uptime').textContent = data.server.uptime;
            document.getElementById('memory').textContent = `${data.server.memory_usage_mb} MB`;
            document.getElementById('cpu').textContent = `${data.server.cpu_usage_percent}%`;
            document.getElementById('db-size').textContent = `${data.database.size_mb} MB`;

            // Update user stats
            document.getElementById('total-users').textContent = data.users.total;
            document.getElementById('active-users').textContent = data.users.active_today;
            document.getElementById('new-users').textContent = data.users.new_this_week;

            // Update device stats
            document.getElementById('total-devices').textContent = data.devices.total;
            document.getElementById('active-devices').textContent = data.devices.active_today;

            // Update device types
            const deviceTypesEl = document.getElementById('device-types');
            deviceTypesEl.innerHTML = '';
            Object.entries(data.devices.by_type).forEach(([type, count]) => {
                const badge = document.createElement('div');
                badge.className = 'device-badge';
                badge.textContent = `${type}: ${count}`;
                deviceTypesEl.appendChild(badge);
            });

            // Update sync stats
            document.getElementById('total-syncs').textContent = data.syncs.total_today;
            document.getElementById('success-rate').textContent = `${data.syncs.success_rate}%`;
            document.getElementById('failed-syncs').textContent = data.syncs.failed;

            // Update database stats
            document.getElementById('total-tasks').textContent = data.database.tasks_count;
            document.getElementById('completed-tasks').textContent = `${data.database.completion_rate}%`;

            // Update last update time
            document.getElementById('last-update').textContent = new Date().toLocaleTimeString();

            // Update status indicator
            document.getElementById('status-dot').className = 'status-dot online';
            document.getElementById('status-text').textContent = 'Server Online';
        }
    } catch (error) {
        console.error('Failed to fetch dashboard stats:', error);
        document.getElementById('status-dot').className = 'status-dot offline';
        document.getElementById('status-text').textContent = 'Server Offline';
    }
}

// Initialize dashboard
function initDashboard() {
    // Initial update
    updateDashboard();

    // Auto-refresh every 30 seconds
    refreshInterval = setInterval(updateDashboard, 30000);
}

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (refreshInterval) {
        clearInterval(refreshInterval);
    }
});

// Start dashboard when page loads
document.addEventListener('DOMContentLoaded', initDashboard);
