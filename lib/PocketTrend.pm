package PocketTrend;
use strict;
use warnings;
use utf8;
use File::Spec;
use Cache::FileCache;
use Cwd qw/abs_path/;
our $VERSION='0.01';
use 5.008001;

use parent qw/Amon2/;
# Enable project local mode.
__PACKAGE__->make_local_context();

sub pocket {
    my $c = shift;
    if (!exists $c->{pocket}) {
        my $fname = File::Spec->catfile($c->base_dir, "config.pl");
        my $config = do $fname;
        die("$fname: $@") if $@;
        die("$fname: $!") unless defined $config;
        die("$fname: consumer_keyが指定されていません") unless exists $config->{consumer_key};
        die("$fname: access_tokenが指定されていません") unless exists $config->{access_token};
        $c->{pocket} = $config;
    }
    $c->{pocket};
}

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

sub config { +{} }

1;
__END__

=head1 NAME

PocketTrend - PocketTrend

=head1 DESCRIPTION

This is a main context class for PocketTrend

=head1 AUTHOR

PocketTrend authors.

