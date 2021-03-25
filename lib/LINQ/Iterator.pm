use 5.006;
use strict;
use warnings;

if ($] < 5.010000) {
	require UNIVERSAL::DOES;
}

{
	package # hide from PAUSE
		LINQ::Iterator::_LazyList;
	
	my $_throw_caller_error = sub {
		shift;
		require LINQ::Exception;
		'LINQ::Exception::CallerError'->throw(message => @_);
	};
	
	sub __GENERATOR () { 0 };
	sub __EXHAUSTED () { 1 };
	sub __VALUES    () { 2 };
	sub __NEXT_SLOT () { 3 };
	
	sub TIEARRAY {
		my $class = shift;
		bless [
			$_[0],
			!!0,
			[],
		], $class;
	}
	
	sub FETCH {
		my $self  = shift;
		my ($ix)  = @_;
		my $cache = $self->[ __VALUES ];
		
		$self->extend_to($ix);
		
		$ix >= @$cache ? undef : $cache->[ $ix ];
	}
	
	sub fetch_ref {
		my $self  = shift;
		my ($ix)  = @_;
		my $cache = $self->[ __VALUES ];
		
		$self->extend_to($ix);
		
		return if $ix > 0 + $#$cache;
		return if $ix < 0 - @$cache;
		\($cache->[ $ix ])
	}
	
	sub FETCHSIZE {
		my $self = shift;
		$self->extend_to(-1);
		scalar @{$self->[ __VALUES ]};
	}
	
	sub current_extension {
		my $self = shift;
		scalar @{$self->[ __VALUES ]};
	}
	
	sub is_fully_extended {
		my $self = shift;
		@{$self->[ __EXHAUSTED ]};
	}
	
	sub extend_to {
		require LINQ;
		
		my $self  = shift;
		my ($ix)  = @_;
		my $cache = $self->[ __VALUES ];
		
		EXTEND: {
			return if $self->[ __EXHAUSTED ];
			return if $ix >=0 && $ix < @$cache;
			
			my @got = $self->[ __GENERATOR ]->();
			my $got;
			
			# Crazy optimized loop to find and handle LINQ::END
			# within @got
			push(@$cache, shift @got)
				and ref( $got = $cache->[-1] )
				and $got == LINQ::END()
				and ($self->[ __EXHAUSTED ] = !!1)
				and pop(@$cache)
				and (
					@got
						? $self->$_throw_caller_error('Returned values after LINQ::END')
						: return()
				)
				while @got;
			
			redo EXTEND;
		};
	}
}


package LINQ::Iterator;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_001';

use Role::Tiny::With ();

Role::Tiny::With::with(qw( LINQ::Collection ));

sub new {
	my $class = shift;
	if (@_ == 1 and ref($_[0]) eq 'CODE') {
		tie my(@arr), 'LINQ::Iterator::_LazyList', @_;
		return bless \@arr, $class;
	}
	die "Expected to be given a CODE ref!";
}

sub target_class {
	require LINQ::Array;
	"LINQ::Array";
}

sub to_list {
	my $self = shift;
	my @list = @$self;
	
	# We must have exhausted the iterator now,
	# so remove all the magic and act like a
	# plain old arrayref.
	#
	if (tied($self)) {
		untie(@$self);
		@$self = @list;
	}
	
	@list;
}

sub element_at {
	my $self = shift;
	my ($n) = @_;
	
	if (my $guts = $self->_guts) {
		my $ref = $guts->fetch_ref(@_);
		return $$ref if $ref;
		require LINQ::Exception;
		'LINQ::Exception::NotFound'->throw(collection => $self);
	}
	
}

sub _guts {
	my $self = shift;
	tied(@$self);
}

1;
