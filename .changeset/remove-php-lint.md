---
"@wpengine/site-deploy": major
---

Remove the `PHP_LINT` option and drop PHP from the image

The image no longer runs `php -l` before deploying, and `php-cli` is no longer installed. Setting `PHP_LINT` has no effect. To keep linting PHP files, run it as a separate step in your pipeline before the deploy.
