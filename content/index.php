<?php
// Simple front-controller to render the custom landing page
$img_id = get_option('page_on_front');
?><!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <title>John Doe</title>
  <link rel="stylesheet" href="/wp-content/uploads/style.css" />
</head>
<body>
  <?php echo apply_filters('the_content', get_post_field('post_content', get_option('page_on_front')) ); ?>
</body>
</html>
