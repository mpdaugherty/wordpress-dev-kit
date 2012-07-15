#!/usr/bin/python
import urllib2, re

wp_conf = open('test_wp/wp-config.php', 'r+')
wp_conf_str = wp_conf.read()
wp_salts = urllib2.urlopen('https://api.wordpress.org/secret-key/1.1/salt/')
wp_salts_str = wp_salts.read()

wp_conf_str_with_salts = re.sub("define\('AUTH_KEY.*phrase here'\);", wp_salts_str, wp_conf_str, flags=re.DOTALL)
wp_conf.seek(0) # Go back to the beginning of the file and start writing from there.
wp_conf.write(wp_conf_str_with_salts)

wp_conf.close()
wp_salts.close()
