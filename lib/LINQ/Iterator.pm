use 5.006;
use strict;
use warnings;

package LINQ::Iterator;

use Class::Tiny qw( _iterator _cached _exhausted );
use Role::Tiny::With ();

Role::Tiny::With::with(qw( LINQ::Collection ));

sub new {
	my $class = shift;
	if (@_ == 1 and ref($_[0]) eq 'CODE') {
		return bless { _iterator => @_, _cached => [] }, $class;
	}
	$class->SUPER::new(@_);
}

sub to_list {
	my $self = shift;
	my $iter = $self->_iterator;
	
	unless ($self->_exhausted) {
		while (1) {
			my @got = $iter->();
			if (@got) {
				push @{ $self->_cached }, @got;
			}
			else {
				$self->_exhausted(1);
				last;
			}
		}
	}
	
	return @{ $self->_cached };
}

sub target_class {
	require LINQ::Array;
	"LINQ::Array";
}

1;
