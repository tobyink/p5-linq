use 5.006;
use strict;
use warnings;

package LINQ::Array;

use Class::Tiny qw( array );
use Role::Tiny::With ();

Role::Tiny::With::with(qw( LINQ::Collection ));

sub new {
	my $class = shift;
	bless { array => @_ }, $class;
}

sub count {
	my $self = shift;
	scalar @{ $self->array };
}

sub to_list {
	my $self = shift;
	@{ $self->array };
}

sub target_class {
	__PACKAGE__;
}

1;
