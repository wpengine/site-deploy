  <?php
  /**
   * Plugin Name: Object Cache Fixture (excluded by exclude-from.sh)
   * Plugin URI: https://github.com/wpengine/site-deploy
   * Version: 0.0.1
   */

   add_action('init', 'register_my_cpt');

   function register_my_cpt() {
      register_post_type('my-cpt', array(
          'public' => true
      ));
   }