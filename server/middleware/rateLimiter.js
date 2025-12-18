/**
 * Rate Limiter Middleware
 * Prevents spam and abuse of party system
 */

class RateLimiter {
    constructor() {
        this.limits = new Map(); // playerId -> { action -> { count, resetTime } }
        
        // Rate limit configurations
        this.configs = {
            party_create: { max: 3, window: 60000 }, // 3 per minute
            party_invite: { max: 10, window: 60000 }, // 10 per minute
            party_leave: { max: 5, window: 60000 }, // 5 per minute
            party_kick: { max: 5, window: 60000 }, // 5 per minute
        };
    }
    
    check(playerId, action) {
        const config = this.configs[action];
        if (!config) {
            return { allowed: true };
        }
        
        const now = Date.now();
        
        if (!this.limits.has(playerId)) {
            this.limits.set(playerId, new Map());
        }
        
        const playerLimits = this.limits.get(playerId);
        const actionLimit = playerLimits.get(action);
        
        if (!actionLimit || now > actionLimit.resetTime) {
            playerLimits.set(action, {
                count: 1,
                resetTime: now + config.window
            });
            return { allowed: true };
        }
        
        if (actionLimit.count >= config.max) {
            const remainingTime = Math.ceil((actionLimit.resetTime - now) / 1000);
            return { 
                allowed: false, 
                error: `Rate limit exceeded. Try again in ${remainingTime}s.`,
                retryAfter: remainingTime
            };
        }
        
        actionLimit.count++;
        return { allowed: true };
    }
    
    reset(playerId, action = null) {
        if (!this.limits.has(playerId)) return;
        
        if (action) {
            this.limits.get(playerId).delete(action);
        } else {
            this.limits.delete(playerId);
        }
    }
    
    cleanup() {
        const now = Date.now();
        for (const [playerId, playerLimits] of this.limits.entries()) {
            for (const [action, limit] of playerLimits.entries()) {
                if (now > limit.resetTime) {
                    playerLimits.delete(action);
                }
            }
            if (playerLimits.size === 0) {
                this.limits.delete(playerId);
            }
        }
    }
    
    startCleanup() {
        setInterval(() => this.cleanup(), 60000); // Clean up every minute
        console.log('✓ Rate limiter cleanup started');
    }
}

module.exports = new RateLimiter();
