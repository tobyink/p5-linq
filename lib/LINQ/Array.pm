use 5.006;
use strict;
use warnings;

if ( $] < 5.010000 ) {
	require UNIVERSAL::DOES;
}

package LINQ::Array;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_003';

use Class::Tiny qw( array );
use Role::Tiny::With ();

Role::Tiny::With::with( qw( LINQ::Collection ) );

sub new {
	my $class = shift;
	bless [ @{ $_[0] } ], $class;
}

sub count {
	my $self = shift;
	return $self->where( @_ )->count if @_;
	scalar @$self;
}

sub to_list {
	my $self = shift;
	@$self;
}

sub target_class {
	__PACKAGE__;
}

1;
