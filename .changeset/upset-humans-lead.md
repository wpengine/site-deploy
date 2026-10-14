---
"@wpengine/site-deploy": patch
---

Fix rsync 3.5.0 --exclude-from failure by using a temp file instead of /dev/fd
