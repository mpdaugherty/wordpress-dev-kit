import io
import os
import posixpath
from fabric.api import *
from fabric.contrib.project import rsync_project
import config

# Confirm that the local config file has been set up correctly
try:
    (config.HOSTS and
     config.USER and
     config.KEY and
     config.URL and
     config.ADMIN and
     config.ALIASES)
except Exception as e:
    print 'Your config file is missing required parameters:\n'
    print '  {}'.format(e)
    exit(1)

env.hosts = config.HOSTS
env.user = config.USER
env.key_filename = [config.KEY]

PROJECT_ROOT = posixpath.normpath(posixpath.join(__file__.replace('\\', '/'), '../')) + '/'
REMOTE_ROOT = '/var/www/{}/'.format(config.URL)

def reload_apache():
    sudo('service apache2 reload', shell=False, pty=False)

def deploy():
    _ensure_dir(REMOTE_ROOT)

    with cd(REMOTE_ROOT):
        _ensure_dir('logs')
        if not _dir_exists('wordpress'):
            _install_wordpress()
            print '\nInstalled Wordpress - you may need to edit your configuration files\n'

    sudo('chmod g+w {}/wordpress/wp-content/themes'.format(REMOTE_ROOT))
    rsync_project(remote_dir='{}/wordpress/wp-content/themes/customtheme'.format(REMOTE_ROOT),
                  local_dir=PROJECT_ROOT+'theme',
                  delete=True)
    sudo('chown {}:www-data -R {}/wordpress/wp-content/themes/customtheme'.format(config.USER, REMOTE_ROOT))

    # sync apache config and install it
    _upload_apache_conf()
    sudo('mv {}/apache.conf /etc/apache2/sites-available/{}'.format(REMOTE_ROOT, config.URL), shell=False, pty=False)
    sudo('a2ensite {}'.format(config.URL))
    reload_apache()

def _upload_apache_conf():
    # First, create a temporary version of the apache conf file which replaces all
    # the variables with their values for this wordpress install.
    conf_file = io.open('apache.conf')
    conf_file_contents = conf_file.read()
    conf_file.close()

    conf_file_contents = conf_file_contents.replace('$SERVERNAME', config.URL)
    conf_file_contents = conf_file_contents.replace('$ADMIN', config.ADMIN)
    aliases = ''.join(['\n        ServerAlias {}'.format(alias) for alias in config.ALIASES])
    conf_file_contents = conf_file_contents.replace('$ALIASES', aliases)

    temp_file = io.open('temp_apache.conf', 'w')
    temp_file.write(conf_file_contents)
    temp_file.close()

    # Next, upload the temporary conf file
    put('temp_apache.conf', '{}/apache.conf'.format(REMOTE_ROOT))

    # Finally, delete the temporary conf file
    os.remove('temp_apache.conf')

def _ensure_dir(dir):
    run('[ -d {0} ] || mkdir {0}'.format(dir))

def _dir_exists(dir):
    with settings(warn_only=True):
        exists_result = run('[ -d {0} ]'.format(dir))
        return (exists_result.return_code == 0)

def _install_wordpress():
    rsync_project(remote_dir='{}/wordpress'.format(REMOTE_ROOT),
                  local_dir=PROJECT_ROOT+'test_wp/')
    sudo('chown www-data -R {}/wordpress'.format(REMOTE_ROOT))
    sudo('a2enmod rewrite')

    # Do MySQL setup if necessary

def _install_apache():
    pass
