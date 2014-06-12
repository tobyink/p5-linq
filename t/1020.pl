use v5.14;
use strict;
use warnings;
use Path::Tiny;

for my $file ( path("t")->children )
{
	next unless -f $file;
	next unless $file =~ /10array/;
	
	my $new = path($file =~ s/10array/20iter/r);
	
	my $pod_line = 0;
	
	$new->spew_utf8(map {
		if (/\A=cut/)
		{
			($_, "\n", "BEGIN { \$LINQ::FORCE_ITERATOR = 1 }\n");
		}
		elsif (!$pod_line and /\A=head1/ and not /PURPOSE/)
		{
			$pod_line++;
			(
				"This test is based on ${\ $file->basename } but runs tests against\n",
				"L<LINQ::Iterator> rather than L<LINQ::Array>.\n",
				"\n",
				$_,
			);
		}
		else
		{
			$_;
		}
	} $file->lines_utf8);
	
	say "$file -> $new";
}

