<?php
/** UniSathi theme setup and contact handling. */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

function unisathi_setup() {
	add_theme_support( 'title-tag' );
	add_theme_support( 'html5', array( 'comment-form', 'comment-list', 'gallery', 'caption', 'style', 'script' ) );
}
add_action( 'after_setup_theme', 'unisathi_setup' );

function unisathi_enqueue_assets() {
	$version = wp_get_theme()->get( 'Version' );
	wp_enqueue_style( 'unisathi-fonts', 'https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Manrope:wght@600;700;800&display=swap', array(), null );
	wp_enqueue_style( 'unisathi-main', get_template_directory_uri() . '/assets/css/main.css', array(), $version );
	wp_enqueue_script( 'unisathi-main', get_template_directory_uri() . '/assets/js/main.js', array(), $version, true );
}
add_action( 'wp_enqueue_scripts', 'unisathi_enqueue_assets' );

function unisathi_meta_tags() {
	if ( ! is_front_page() ) {
		return;
	}
	$description = 'UniSathi connects students, parents, teachers, and colleges for a safer, smarter campus experience.';
	echo '<meta name="description" content="' . esc_attr( $description ) . '">';
	echo '<meta property="og:title" content="' . esc_attr( get_bloginfo( 'name' ) . ' | Every student. Every step. Connected.' ) . '">';
	echo '<meta property="og:description" content="' . esc_attr( $description ) . '">';
	echo '<meta property="og:type" content="website">';
}
add_action( 'wp_head', 'unisathi_meta_tags', 2 );

function unisathi_contact_submission() {
	if ( ! isset( $_POST['unisathi_contact_nonce'] ) || ! wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['unisathi_contact_nonce'] ) ), 'unisathi_contact' ) ) {
		wp_safe_redirect( add_query_arg( 'contact', 'error', wp_get_referer() ?: home_url( '/#contact' ) ) );
		exit;
	}
	$name        = isset( $_POST['full_name'] ) ? sanitize_text_field( wp_unslash( $_POST['full_name'] ) ) : '';
	$email       = isset( $_POST['email'] ) ? sanitize_email( wp_unslash( $_POST['email'] ) ) : '';
	$institution = isset( $_POST['institution'] ) ? sanitize_text_field( wp_unslash( $_POST['institution'] ) ) : '';
	$message     = isset( $_POST['message'] ) ? sanitize_textarea_field( wp_unslash( $_POST['message'] ) ) : '';

	if ( '' === $name || ! is_email( $email ) || '' === $message ) {
		wp_safe_redirect( add_query_arg( 'contact', 'invalid', wp_get_referer() ?: home_url( '/#contact' ) ) );
		exit;
	}

	$body = "Name: {$name}\nEmail: {$email}\nInstitution: {$institution}\n\nMessage:\n{$message}";
	$sent = wp_mail( get_option( 'admin_email' ), sprintf( '[UniSathi] Message from %s', $name ), $body, array( 'Reply-To: ' . $email ) );
	wp_safe_redirect( add_query_arg( 'contact', $sent ? 'success' : 'error', wp_get_referer() ?: home_url( '/#contact' ) ) );
	exit;
}
add_action( 'admin_post_nopriv_unisathi_contact', 'unisathi_contact_submission' );
add_action( 'admin_post_unisathi_contact', 'unisathi_contact_submission' );

