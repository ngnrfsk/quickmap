# Code Minimalism Rules

**Avoid:**
- cat() in user scripts
- Redundant validation (env vars, parameters already checked downstream)
- Obvious comments
- Try-catch around operations that should fail
- Single-use helpers/wrappers
- Success messages

**Do:**
- Trust R's errors
- Let functions fail naturally
- Write self-evident code
