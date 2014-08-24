package PocketTrend;
use strict;
use warnings;
use utf8;
our $VERSION='0.01';
use 5.008001;

use parent qw/Amon2/;
# Enable project local mode.
__PACKAGE__->make_local_context();

sub pocket {
    my $c = shift;
    if (!exists $c->{pocket}) {
        $c->{pocket} = $c->config->{pocket}
            or die "Missing configuration about Pocket";
    }
    $c->{pocket};
}

1;
__END__

=head1 NAME

PocketTrend - PocketTrend

=head1 DESCRIPTION

This is a main context class for PocketTrend

=head1 AUTHOR

PocketTrend authors.

