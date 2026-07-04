# Local Data Caching Feasibility Analysis (v0.9.3)

## Summary

**Current approach (session metadata cache) is optimal for v0.9.3.**
Disk caching deferred to v0.9.4+ if needed. Full database NOT recommended.

## Data Volumes

**Full historic datasets:**
- AURN: 312 sites × 53 years = **12-15 GB** compressed
- LAQN: 150 sites × 25 years = **2.8-3 GB** compressed

**Practical subset (London, 20 years):**
- 350 sites × 20 years = **5-6 GB** compressed

**Typical use case:**
- 10-20 sites × 10 years = **200-300 MB**

## Caching Options

### Option A: Session Cache (IMPLEMENTED)
- ✅ Already working (`get_openair_metadata()`)
- ✅ Zero maintenance, no stale data
- ✅ Eliminates redundant metadata API calls
- ❌ Lost between sessions
- **Effort:** 0 (done)

### Option B: Disk Cache (FEASIBLE)
- ✅ Survives R restarts
- ✅ Fast loads (disk I/O > network)
- ✅ Enables offline work
- ❌ Requires age tracking/invalidation
- ❌ Stale data risk without maintenance
- **Effort:** 1-2 hours
- **Storage:** 200-300 MB (typical subset)

### Option C: Full Database (NOT RECOMMENDED)
- ❌ 12-15 GB storage
- ❌ Daily update automation needed
- ❌ Duplicates Ricardo's infrastructure
- ❌ High stale data risk
- **Effort:** 12-16 hours
- **Avoid:** Complexity not justified

## Recommendation

**v0.9.3:** Keep session cache + fresh API downloads
**v0.9.4+:** Consider disk cache with age-based invalidation if repeated queries become bottleneck

## References
- OpenAir: No built-in persistent caching
- Ricardo: Daily updates, .RData compression (40-60%)
- bl_imperial example: 259 MB (typical scale)
