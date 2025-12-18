// Pantheos Website Configuration
// This file configures where the website connects to

// IMPORTANT: Update this with your Tailscale IP or server address
const API_CONFIG = {
    // For local testing (only works on your computer)
    // API_URL: 'http://localhost:3000/api',
    
    // For Tailscale (works over internet for users on your Tailscale network)
    API_URL: 'http://100.92.219.104:3000/api',
    
    // For production (when you deploy to a VPS with public IP)
    // API_URL: 'https://yourdomain.com:3000/api',
    
    API_KEY: 'pantheos_dev_key_12345'
};

// Export for use in other scripts
window.API_CONFIG = API_CONFIG;
