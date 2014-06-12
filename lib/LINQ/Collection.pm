use 5.006;
use strict;
use warnings;

package LINQ::Collection;

use Role::Tiny;

requires qw( target_class to_list );

my $_throw = sub {
	require LINQ::Exception;
	my $e = shift;
	"LINQ::Exception::$e"->throw(@_);
};

my $_assert_code = sub {
	my $code = shift;
	
	if (ref($code) eq 'ARRAY') {
		@_ = @$code;
		$code = shift;
	}

	if (ref($code) eq 'Regexp') {
		$_throw->(
			"CallerError",
			message => "Regexp cannot accept curried arguments"
		) if @_;
		
		my $re = $code;
		return sub { m/$re/ };
	}

	if (ref($code) ne 'CODE') {
		require Scalar::Util;
		require overload;
		
		$_throw->(
			"CallerError",
			message => "Expected coderef; got '$code'"
		) unless Scalar::Util::blessed($code) && overload::Method($code, '&{}');
	}
	
	if (@_) {
		my @curry = @_;
		return sub { $code->(@curry, @_) };
	}
	
	return $code;
};

my $_create_linq = sub {
	my $self = shift;
	my $class = $self->target_class;
	ref($class) ? $class->(@_) : $class->new(@_);
};

my $_coerce = sub {
	my ($thing) = @_;
	
	require Scalar::Util;
	if (Scalar::Util::blessed($thing) and $thing->DOES(__PACKAGE__))
	{
		return $thing;
	}
	
	if (ref($thing) eq 'ARRAY')
	{
		require LINQ::Array;
		return LINQ::Array::->new($thing);
	}
	
	$_throw->(
		"CallerError",
		message => "Expected a LINQ collection; got '$thing'"
	);
};

sub select {
	my $self = shift;
	my $map = $_assert_code->(@_);
	$self->$_create_linq(
		[ map scalar($map->($_)), $self->to_list ],
	);
}

sub where {
	my $self = shift;
	my $filter = $_assert_code->(@_);
	$self->$_create_linq(
		[ grep $filter->($_), $self->to_list ],
	);
}

sub select_many {
	my $self = shift;
	my $map = $_assert_code->(@_);
	$self->$_create_linq(
		[ map $map->($_)->$_coerce->to_list, $self->to_list ],
	);
}

sub min {
	my $self = shift;
	return $self->select(@_)->min if @_;
	require List::Util;
	List::Util::min($self->to_list);
}

sub max {
	my $self = shift;
	return $self->select(@_)->max if @_;
	require List::Util;
	&List::Util::max($self->to_list);
}

sub sum {
	my $self = shift;
	return $self->select(@_)->sum if @_;
	require List::Util;
	&List::Util::sum($self->to_list);
}

sub average {
	my $self = shift;
	$self->sum(@_) / $self->count();	
}

sub aggregate {
	my $self = shift;
	my $code = $_assert_code->(shift);
	my $wrapper = sub { $code->($a, $b) };
	require List::Util;
	&List::Util::reduce($wrapper, @_, $self->to_list);
}

my $_prepare_join = sub
{
	my $x = shift;
	my $y = shift;
	
	my $hint   = ref($_[0]) ? -inner : shift(@_);
	my $x_keys = $_assert_code->(shift);
	my $y_keys = $_assert_code->(shift);
	my $joiner = $_assert_code->(@_);
	
	$hint =~ /\A-(inner|left|right|outer)\z/ or $_throw->(
		"CallerError",
		message => "Expected a recognized join type; got '$hint'"
	);
	
	my @x_mapped = $x->select(sub { [scalar($x_keys->($_[0])), $_[0]] })->to_list;
	my @y_mapped = $y->select(sub { [scalar($y_keys->($_[0])), $_[0]] })->to_list;
	
	return (\@x_mapped, \@y_mapped, $hint, $joiner);
};

sub join {
	my ($x_mapped, $y_mapped, $hint, $joiner) = $_prepare_join->(@_);
	
	my @joined;
	my (@found_x, @found_y);
	
	for my $Xi (0 .. $#$x_mapped)
	{
		my $X = $x_mapped->[$Xi];
		
		for my $Yi (0 .. $#$y_mapped)
		{
			my $Y = $y_mapped->[$Yi];
			
			if ($X->[0] eq $Y->[0])
			{
				my $a = $X->[1];
				my $b = $Y->[1];
				$found_x[$Xi]++;
				$found_y[$Yi]++;
				
				push @joined, scalar $joiner->($a, $b);
			}
		}
	}
	
	if ($hint eq -left or $hint eq -outer)
	{
		for my $Xi (0 .. $#$x_mapped)
		{
			next if $found_x[$Xi];
			my $a = $x_mapped->[$Xi][1];
			my $b = undef;
			push @joined, scalar $joiner->($a);
		}
	}
	
	if ($hint eq -right or $hint eq -outer)
	{
		for my $Yi (0 .. $#$y_mapped)
		{
			next if $found_y[$Yi];
			my $a = undef;
			my $b = $y_mapped->[$Yi][1];
			push @joined, scalar $joiner->(undef, $b);
		}
	}
	
	$_[0]->$_create_linq(\@joined);
}

sub group_join {
	my ($x_mapped, $y_mapped, $hint, $joiner) = $_prepare_join->(@_);
	
	$hint =~ /\A-(left|inner)\z/ or $_throw->(
		"CallerError",
		message => "Join type '$hint' not supported for group_join",
	);
	
	my @joined;
	my (@found_x, @found_y);
	
	for my $Xi (0 .. $#$x_mapped)
	{
		my $X = $x_mapped->[$Xi];
		my @group = map $_->[1], grep $X->[0] eq $_->[0], @$y_mapped;
		
		if (@group or $hint eq -left)
		{
			my $a = $X->[1];
			my $b = $_[0]->$_create_linq(\@group);
			push @joined, scalar $joiner->($a, $b);
		}
	}
	
	$_[0]->$_create_linq(\@joined);
}

sub take {
	my $self = shift;
	my ($n)  = @_;
	$self->where(sub { $n-- > 0 });
}

sub take_while {
	my $self = shift;
	my $filter = $_assert_code->(@_);
	my $stopped = 0;
	$self->where(sub {
		$stopped = 1
			if !$stopped
			&& !$filter->($_);
		not $stopped;
	});
}

sub skip {
	my $self = shift;
	my ($n)  = @_;
	$self->where(sub { $n-- <= 0 });
}

sub skip_while {
	my $self = shift;
	my $filter = $_assert_code->(@_);
	my $skipping = 1;
	$self->where(sub {
		$skipping = 0
			if $skipping
			&& !$filter->($_);
		not $skipping;
	});
}

sub concat {
	my $self = shift;
	my $other = $_[0];
	return $self->$_create_linq([ $self->to_list, $other->to_list ]);
}

sub order_by {
	my $self   = shift;
	my $hint   = ref($_[0]) ? -numeric : shift(@_); 
	my $keygen = $_assert_code->(@_);
	
	if ($hint eq -string)
	{
		return $self->$_create_linq([
			map $_->[1],
			sort { $a->[0] cmp $b->[0] }
			map [$keygen->($_), $_],
			$self->to_list
		]);
	}
	
	elsif ($hint eq -numeric)
	{
		return $self->$_create_linq([
			map $_->[1],
			sort { $a->[0] <=> $b->[0] }
			map [$keygen->($_), $_],
			$self->to_list
		]);
	}
	
	$_throw->(
		"CallerError",
		message => "Expected '-numeric' or '-string'; got '$hint'"
	);
}

sub then_by {
	$_throw->("Unimplemented", method => "then_by");
}

sub order_by_descending {
	my $self = shift;
	$self->order_by(@_)->reverse;
}

sub then_by_descending {
	$_throw->("Unimplemented", method => "then_by_descending");
}

sub reverse {
	my $self = shift;
	$self->$_create_linq(
		[ reverse($self->to_list) ],
	);
}

sub group_by {
	my $self = shift;
	my $keygen = $_assert_code->(@_);
	
	my @keys;
	my %values;
	
	for ($self->to_list) {
		my $key = $keygen->($_);
		unless ($values{$key}) {
			push @keys, $key;
			$values{$key} = [];
		}
		push @{$values{$key}}, $_;
	}
	
	require LINQ::Grouping;
	$self->$_create_linq([
		map LINQ::Grouping::->new(
			key    => $_,
			values => $self->$_create_linq($values{$_}),
		), @keys
	]);
}

sub distinct {
	my $self = shift;
	my $compare = @_ ? $_assert_code->(@_) : sub { $_[0] == $_[1] };
	
	my @already;
	$self->where(sub {
		my $maybe = $_[0];
		for my $got (@already) {
			return !!0 if $compare->($maybe, $got);
		}
		push @already, $maybe;
		return !!1;
	});
}

sub union {
	my $self = shift;
	my ($other, @compare) = @_;
	$self->concat($other)->distinct(@compare);
}

sub intersect {
	my $self = shift;
	my $other = shift;
	my @compare = @_ ? $_assert_code->(@_) : sub { $_[0] == $_[1] };
	$self->where(sub { $other->contains($_, @compare) });
}

sub except {
	my $self = shift;
	my $other = shift;
	my @compare = @_ ? $_assert_code->(@_) : sub { $_[0] == $_[1] };
	$self->where(sub { not $other->contains($_, @compare) });
}

sub sequence_equal {
	my $self = shift;
	my ($other, @compare) = @_;
	
	return !!0 unless $self->count == $other->count;
	
	my @list1 = $self->to_list;
	my @list2 = $other->to_list;
	return !!0 unless @list1 == @list2;
	
	if (@compare) {
		my $compare = $_assert_code->(@_);
		for my $i (0 .. $#list1) {
			return !!0 unless $compare->($list1[$i], $list2[$i]);
		}
		return !!1;
	}

	for my $i (0 .. $#list1) {
		return !!0 unless $list1[$i] == $list2[$i];
	}
	return !!1;
}

my $_with_default = sub
{
	my $self    = shift;
	my $method  = shift;
	my @args    = @_;
	my $default = pop(@args);
	
	my $return;
	eval { $return = $self->$method(@args); 1 }
	or do {
		my $e = $@; # catch
		
		# Rethrow any non-blessed errors.
		require Scalar::Util;
		die($e) unless Scalar::Util::blessed($e);
		
		# Rethrow any errors of the wrong class.
		die($e) unless $e->isa('LINQ::Exception::NotFound') || $e->isa('LINQ::Exception::MultipleFound');
		
		# Rethrow any errors which resulted from the wrong source.
		die($e) unless $e->collection == $self;
		
		return $default;
	};
	
	return $return;
};

sub first {
	my $self = shift;
	my $found = $self->where(@_);
	return $found->element_at(0) if $found->count > 0;
	$_throw->('NotFound', collection => $self);
}

sub first_or_default {
	shift->$_with_default(first => @_);
}

sub last {
	my $self = shift;
	my $found = $self->where(@_);
	return $found->element_at(-1) if $found->count > 0;
	$_throw->('NotFound', collection => $self);
}

sub last_or_default {
	shift->$_with_default(last => @_);
}

sub single {
	my $self = shift;
	my $found = $self->where(@_);
	return $found->element_at(0) if $found->count == 1;
	$found->count == 0
		? $_throw->('NotFound', collection => $self)
		: $_throw->('MultipleFound', collection => $self, found => $found);
}

sub single_or_default {
	shift->$_with_default(single => @_);
}

sub element_at {
	my $self = shift;
	my ($i) = @_;
	($self->to_list)[$i];
}

sub any {
	my $self = shift;
	@_
		? $self->where(@_)->any
		: ($self->count > 0);
}

sub all {
	my $self = shift;
	$self->where(@_)->count == $self->count;
}

sub contains {
	my $self = shift;
	my ($x, @args) = @_;
	
	if (@args) {
		splice(@args, 1, 0, $x);
		return $self->any( $_assert_code->(@args) );
	}
	
	$self->any(sub { $_ == $x });
}

sub count {
	my $self = shift;
	return $self->where(@_)->count if @_;
	my @list = $self->to_list;
	return scalar(@list);
}

sub to_array {
	my $self = shift;
	[ $self->to_list ];
}

sub to_dictionary {
	my $self = shift;
	my ($keygen) = $_assert_code->(@_);
	+{ map +($keygen->($_), $_), $self->to_list };
}

sub to_lookup {
	my $self = shift;
	$self->to_dictionary(@_);
}

sub to_iterator {
	my $self = shift;
	my @list = $self->to_list;
	sub { @list ? shift(@list) : () };
}

sub cast {
	my $self = shift;
	my ($type) = @_;
	
	my $cast = $self->of_type(@_);
	return $cast if $self->count == $cast->count;
	
	$_throw->("Cast", collection => $self, type => $type);
}

sub of_type {
	my $self = shift;
	my ($type) = @_;
	
	require Scalar::Util;
	
	unless (Scalar::Util::blessed($type)
	and     $type->can('check')
	and     $type->can('has_coercion')) {
		$_throw->(
			"CallerError",
			message => "Expected type constraint; got '$type'",
		);
	}
	
	if ($type->isa('Type::Tiny')) {
		my $check = $type->compiled_check;
		
		if ($type->has_coercion) {
			my $coercion = $type->coercion->compiled_coercion;
			return $self->select($coercion)->where($check);
		}
		
		return $self->where($check);
	}
	
	if ($type->has_coercion) {
		return $self
			->select(sub { $type->coerce($_) })
			->where(sub { $type->check($_) });
	}
	
	return $self->where(sub { $type->check($_) });
}

sub zip {
	my $self  = shift;
	my $other = shift;
	my $map   = $_assert_code->(@_);
	
	my @self  = $self->to_list;
	my @other = $other->to_list;
	my @results;
	
	while (@self and @other) {
		push @results, scalar $map->(shift(@self), shift(@other));
	}
	
	$self->$_create_linq(\@results);
}

1;
