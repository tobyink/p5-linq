use 5.006;
use strict;
use warnings;

if ( $] < 5.010000 ) {
	require UNIVERSAL::DOES;
}

{
	package    # hide from PAUSE
		LINQ::Iterator::_LazyList;
		
	my $_throw_caller_error = sub {
		shift;
		require LINQ::Exception;
		'LINQ::Exception::CallerError'->throw( message => @_ );
	};
	
	sub __GENERATOR () { 0 }
	sub __EXHAUSTED () { 1 }
	sub __VALUES ()    { 2 }
	sub __NEXT_SLOT () { 3 }
	
	sub TIEARRAY {
		my $class = shift;
		bless [
			$_[0],
			!!0,
			[],
		], $class;
	}
	
	sub FETCH {
		my $self   = shift;
		my ( $ix ) = @_;
		my $cache  = $self->[__VALUES];
		
		$self->extend_to( $ix );
		
		$ix >= @$cache ? undef : $cache->[$ix];
	}
	
	sub fetch_ref {
		my $self   = shift;
		my ( $ix ) = @_;
		my $cache  = $self->[__VALUES];
		
		$self->extend_to( $ix );
		
		return if $ix > 0+ $#$cache;
		return if $ix < 0 - @$cache;
		\( $cache->[$ix] );
	} #/ sub fetch_ref
	
	sub FETCHSIZE {
		my $self = shift;
		$self->extend_to( -1 );
		scalar @{ $self->[__VALUES] };
	}
	
	sub current_extension {
		my $self = shift;
		scalar @{ $self->[__VALUES] };
	}
	
	sub is_fully_extended {
		my $self = shift;
		$self->[__EXHAUSTED];
	}
	
	sub extend_to {
		require LINQ;
		
		my $self   = shift;
		my ( $ix ) = @_;
		my $cache  = $self->[__VALUES];
		
		EXTEND: {
			return if $self->[__EXHAUSTED];
			return if $ix >= 0 && $ix < @$cache;
			
			my @got = $self->[__GENERATOR]->();
			my $got;
			
			# Crazy optimized loop to find and handle LINQ::END
			# within @got
			push( @$cache, shift @got )
				and ref( $got = $cache->[-1] )
				and $got == LINQ::END()
				and ( $self->[__EXHAUSTED] = !!1 )
				and pop( @$cache )
				and (
				@got
				? $self->$_throw_caller_error( 'Returned values after LINQ::END' )
				: return ()
				) while @got;
				
			redo EXTEND;
		} #/ EXTEND:
	} #/ sub extend_to
}

package LINQ::Iterator;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.000_004';

use Role::Tiny::With ();
use LINQ::Util::Internal ();

Role::Tiny::With::with( qw( LINQ::Collection ) );

sub new {
	my $class = shift;
	if ( @_ ) {
		tie my ( @arr ), 'LINQ::Iterator::_LazyList', LINQ::Util::Internal::assert_code( @_ );
		return bless \@arr, $class;
	}
	die "Expected to be given a CODE ref!";
}

sub _guts {
	my $self = shift;
	tied( @$self );
}

sub to_list {
	my $self = shift;
	my @list = @$self;
	
	# We must have exhausted the iterator now,
	# so remove all the magic and act like a
	# plain old arrayref.
	#
	if ( tied( $self ) ) {
		untie( @$self );
		@$self = @list;
	}
	
	@list;
} #/ sub to_list

sub element_at {
	my $self = shift;
	
	if ( my $guts = $self->_guts ) {
		my $ref = $guts->fetch_ref( @_ );
		return $$ref if $ref;
		require LINQ::Exception;
		'LINQ::Exception::NotFound'->throw( collection => $self );
	}
	
	$self->LINQ::Collection::element_at( @_ );
} #/ sub element_at

sub select {
	my $self = shift;
	
	if ( my $guts = $self->_guts ) {
		my $map = LINQ::Util::Internal::assert_code( @_ );
		my $idx = 0;
		return LINQ::Util::Internal::create_linq( sub {
			my $val = $guts->fetch_ref( $idx++ );
			if ( ! $val ) {
				require LINQ;
				return LINQ::END();
			}
			local $_ = $$val;
			scalar $map->( $_ );
		} );
	}
	
	$self->LINQ::Collection::select( @_ );
}

sub where {
	my $self = shift;
	
	if ( my $guts = $self->_guts ) {
		my $check = LINQ::Util::Internal::assert_code( @_ );
		my $idx   = 0;
		return LINQ::Util::Internal::create_linq( sub {
			GETVAL: {
				my $val = $guts->fetch_ref( $idx++ );
				if ( ! $val ) {
					require LINQ;
					return LINQ::END();
				}
				local $_ = $$val;
				redo GETVAL unless $check->( $_ );
				return $$val;
			};
		} );
	}
	
	$self->LINQ::Collection::where( @_ );
}

sub to_iterator {
	my $self = shift;
	
	if ( my $guts = $self->_guts ) {
		my $idx  = 0;
		my $done = 0;
		return sub {
			return if $done;
			my $val = $guts->fetch_ref( $idx++ );
			return $$val if $val;
			++$done;
			return;
		};
	}
	
	$self->LINQ::Collection::to_iterator( @_ );
}

1;
