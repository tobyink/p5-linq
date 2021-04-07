use 5.006;
use strict;
use warnings;

package LINQ::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_005';

use Exporter::Shiny qw( fields assert_fields );

sub fields {
	require LINQ::FieldSet::Selection;
	'LINQ::FieldSet::Selection'->new( @_ );
}

sub assert_fields {
	require LINQ::FieldSet::Assertion;
	'LINQ::FieldSet::Assertion'->new( @_ );
}

1;