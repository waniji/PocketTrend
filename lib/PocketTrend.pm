package PocketTrend;
use strict;
use warnings;
use utf8;
use File::Spec;
use Cache::FileCache;
use Cwd qw/abs_path/;
use Furl;
our $VERSION='0.01';
use 5.008001;

use parent qw/Amon2/;
# Enable project local mode.
__PACKAGE__->make_local_context();

sub cache {
    my $c = shift;
    if (!exists $c->{cache}) {
        my $cache = Cache::FileCache->new({
            cache_root => abs_path($c->base_dir."/data"),
        });
        $c->{cache} = $cache;
    }
    $c->{cache};
}

sub furl {
    my $c = shift;
    if (!exists $c->{furl}) {
        my $furl = Furl->new( timeout => 10 );
        $c->{furl} = $furl;
    }
    $c->{furl};
}

sub config { +{} }

1;
__END__

=head1 NAME

PocketTrend - PocketTrend

=head1 DESCRIPTION

This is a main context class for PocketTrend

=head1 AUTHOR

PocketTrend authors.

