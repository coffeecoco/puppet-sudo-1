#
#	contrived puppet-sudo example
#
class { 'sudo':
	envkeep => ['FOO_BAR', 'SOMETHING'],	# allow these through
}

sudo::directive { 'foo1': directive => '
james  ALL=(ALL) ALL
%bar  ALL=(foobar) NOPASSWD: /usr/bin/date
', comment => 'please replace this contrived example with your own directive'}

