build:
	cpan install Test::Nginx

test:
	- pkill -9 nginx
	prove -r t
