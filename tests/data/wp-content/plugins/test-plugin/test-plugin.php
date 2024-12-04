<?php
/**
 * Plugin Name: Deploy WordPress to WP Engine - e2e Test - Plugin Fixture
 * Plugin URI: https://github.com/wpengine/site-deploy
 * Description: Sample code to test the wpengine/site-deploy image.
 * Version: 0.0.1
 */
 
 add_action('init', 'register_my_cpt');

 function register_my_cpt() {
    register_post_type('my-cpt', array(
        'public' => true
    ));
 }