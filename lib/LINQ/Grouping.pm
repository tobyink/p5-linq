use 5.006;
use strict;
use warnings;

if ($] < 5.010000) {
	require UNIVERSAL::DOES;
}

package LINQ::Grouping;

use Class::Tiny qw( key values );

1;
