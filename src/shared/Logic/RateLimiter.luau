--!strict
-- Token-bucket rate limiter keyed by an arbitrary key (e.g. userId .. remoteName). Pure:
-- the caller supplies the current time, which makes it deterministic under test.

export type Limiter = {
	capacity: number,
	refillPerSecond: number,
	buckets: { [any]: { tokens: number, at: number } },
}

local RateLimiter = {}

function RateLimiter.new(capacity: number, refillPerSecond: number): Limiter
	return { capacity = capacity, refillPerSecond = refillPerSecond, buckets = {} }
end

function RateLimiter.allow(limiter: Limiter, key: any, now: number): boolean
	if type(now) ~= "number" or now ~= now or now == math.huge or now == -math.huge then
		return false -- a NaN clock would refill the bucket on every call; deny instead
	end
	local b = limiter.buckets[key]
	if b == nil then
		b = { tokens = limiter.capacity, at = now }
		limiter.buckets[key] = b
	end
	local elapsed = math.max(0, now - b.at)
	b.tokens = math.min(limiter.capacity, b.tokens + elapsed * limiter.refillPerSecond)
	b.at = now
	if b.tokens >= 1 then
		b.tokens -= 1
		return true
	end
	return false
end

function RateLimiter.forget(limiter: Limiter, key: any)
	limiter.buckets[key] = nil
end

return RateLimiter
