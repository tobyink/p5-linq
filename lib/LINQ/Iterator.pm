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

sub _fetch {
	my $self = shift;
	my $iter = $self->_iterator;
	
	return if $self->_exhausted;
	
	my @got = $iter->();
	if (@got) {
		my $got = shift(@got);
		if (@got) {
			require LINQ::Exception;
			'LINQ::Exception::CallerError'->throw(
				message => "Iterator coderef returned more than one value in list context",
			);
		}
		push @{ $self->_cached }, $got;
		return \$got;
	}
	
	$self->_exhausted(1);
	return;
}

sub to_list {
	my $self = shift;
	1 while $self->_fetch;
	return @{ $self->_cached };
}

sub target_class {
	require LINQ::Array;
	"LINQ::Array";
}

1;
