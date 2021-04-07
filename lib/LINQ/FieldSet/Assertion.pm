use 5.006;
use strict;
use warnings;

package LINQ::FieldSet::Assertion;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_005';

use Class::Tiny;
use parent qw( LINQ::FieldSet );

sub _known_parameter_names {
	my ( $self ) = ( shift );
	
	return (
		$self->SUPER::_known_parameter_names,
		'is'   => 1,
		'in'   => 1,
		'cmp'  => 1,
	);
}

1;
