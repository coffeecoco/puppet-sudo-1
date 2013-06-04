# Sudo templating module by James
# Copyright (C) 2012-2013+ James Shubin
# Written by James Shubin <james@shubin.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class sudo(
	# TODO: add any options here that we would want to change in sudoers
	$envkeep = [],			# also keep these env variables
	$insults = false
) {

	# Adding HOME to env_keep may enable a user to run unrestricted
	# commands via sudo.
	# FIXME: if HOME is found, we should remove it from the array
	# instead, since I don't know how, we are removing everything :(
	if 'HOME' in $envkeep {
		$env_keep = []
	} else {
		$env_keep = $envkeep
	}

	package { 'sudo':
		ensure => present,
	}

	file { '/etc/sudoers':
		content => template('sudo/sudoers.erb'),
		owner => root,
		group => root,
		mode => 440,
		notify => Exec['sudo'],
		require => Package['sudo'],
	}

	file { '/etc/sudoers.d/':
		ensure => directory,		# make sure this is a directory
		recurse => true,		# recursively manage directory
		purge => true,			# purge all unmanaged files
		force => true,			# also purge subdirs and links
		owner => root,
		group => root,
		mode => 750,			# u=rwx,g=rx,o=
		notify => Exec['sudo'],
		require => Package['sudo'],
	}

	exec { '/usr/sbin/visudo -c':
		refreshonly => true,
		logoutput => on_failure,
		require => [File['/etc/sudoers'], File['/etc/sudoers.d/']],
		alias => 'sudo',
	}
}

define sudo::directive(
	$directive,
	$comment = '',
	$ensure = present
) {
	include 'sudo'

	# remove white space at beginnings or ends of each line
	$safe_directive = regsubst($directive, '(^\s+|\s+$)', '', 'G')

	# man 5 sudoers:
	# sudo will read each file in /etc/sudoers.d, skipping file names that
	# end in ~ or contain a . character to avoid causing problems with
	# package manager or editor temporary/backup files. Files are parsed in
	# sorted lexical order. That is, /etc/sudoers.d/01_first will be parsed
	# before /etc/sudoers.d/10_second. Be aware that because the sorting is
	# lexical, not numeric, /etc/sudoers.d/1_whoops would be loaded after
	# /etc/sudoers.d/10_second. Using a consistent number of leading zeroes
	# in the file names can be used to avoid such problems.
	file { "/etc/sudoers.d/${name}":
		content => template('sudo/directive.erb'),
		owner => root,
		group => root,
		mode => 440,
		notify => Exec["sudo-${name}"],
		require => File['/etc/sudoers.d/'],
		ensure => $ensure,
	}

	# check the file with visudo; thanks to a #puppet user for this tip!
	exec { "sudo-${name}":
		command => "/usr/sbin/visudo -c -f /etc/sudoers.d/${name} || (/bin/rm -f /etc/sudoers.d/${name} && exit 1)",
		refreshonly => true,
		logoutput => on_failure,
		require => File["/etc/sudoers.d/${name}"],
	}
}

