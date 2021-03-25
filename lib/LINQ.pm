use 5.006;
use strict;
use warnings;

package LINQ;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_001';

use Exporter::Shiny qw( LINQ Range Repeat END );

our $FORCE_ITERATOR;

my $end = do {
	package LINQ::END;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.000_001';
	my $x = 42;
	bless(\$x);
	&Internals::SvREADONLY(\$x, !!1);
	\$x;
};

BEGIN {
	*LINQ::END  = sub () { $end };
}

sub LINQ ($) {
	my $data = shift;
	my $ref  = ref($data);
	
	if ($ref eq 'ARRAY') {
		if ($FORCE_ITERATOR) {
			my @data = @$data;
			require LINQ::Iterator;
			return LINQ::Iterator::->new(
				sub { @data ? shift(@data) : LINQ::END }
			);
		}
		
		require LINQ::Array;
		return LINQ::Array::->new($data);
	}
	
	if ($ref eq 'CODE') {
		require LINQ::Iterator;
		return LINQ::Iterator::->new($data);
	}
	
	require Scalar::Util;
	if (Scalar::Util::blessed($data) and $data->DOES('LINQ::Collection')) {
		return $data;
	}
	
	require LINQ::Exception;
	'LINQ::Exception::CallerError'->throw(
		message => "Cannot create LINQ object from '$data'",
	);
}

sub Range {
	my ($min, $max) = @_;
	
	my $value = defined($min) ? $min : 0;
	
	if ( not defined $max ) {
		return LINQ sub { $value++ };
	}
	
	return LINQ sub { return LINQ::END if $value > $max; $value++ };
}

sub Repeat {
	my ($value, $count) = @_;
	
	if ( not defined $count ) {
		return LINQ sub { $value };
	}
	
	return LINQ sub { return LINQ::END if $count-- <= 0; $value };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ - an interpretation of Microsoft's Language Integrated Query

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

