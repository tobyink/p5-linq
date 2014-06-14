use 5.006;
use strict;
use warnings;

package LINQ;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Exporter::Shiny qw( LINQ );

our $FORCE_ITERATOR;

sub LINQ ($) {
	my $data = shift;
	my $ref  = ref($data);
	
	if ($ref eq 'ARRAY') {
		if ($FORCE_ITERATOR) {
			my @data = @$data;
			require LINQ::Iterator;
			return LINQ::Iterator::->new(sub { @data ? shift(@data) : () });
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

