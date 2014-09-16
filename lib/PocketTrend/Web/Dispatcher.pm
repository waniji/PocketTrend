package PocketTrend::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::RouterBoom;
use Furl;
use JSON;
use URI;
use Time::Piece;
use Time::Seconds;
use Encode qw/decode_utf8/;

my $RETRIEVE_URL = 'https://getpocket.com/v3/get';

get '/' => sub {
    my ($c) = @_;

    my $content = $c->cache->get("content");
    if( !defined $content or $content eq "" ) {
        return $c->redirect('/refresh');
    }
    $content = decode_json($content);

    # 追加数と読了数をカウント
    my %trend;
    my $article;
    for my $item ( values %{ $content->{list} } ) {

        # 追加数カウント
        my $added_date = localtime($item->{time_added})->ymd("-");
        $trend{$added_date}->{add}++;

        # 読了数カウント
        my $read_date;
        if( $item->{time_read} ) {
            $read_date = localtime($item->{time_read})->ymd("-");
            $trend{$read_date}->{read}++;
        }

        # 記事一覧を作成
        if( defined $read_date and $added_date eq $read_date ) {
            push @{ $article->{$added_date} }, +{
                title => decode_utf8($item->{resolved_title}),
                url => $item->{resolved_url},
                added => 1,
                read => 1,
            };
        } else {
            push @{ $article->{$added_date} }, +{
                title => decode_utf8($item->{resolved_title}),
                url => $item->{resolved_url},
                added => 1,
                read => 0,
            };
            if( defined $read_date ) {
                push @{ $article->{$read_date} }, +{
                    title => decode_utf8($item->{resolved_title}),
                    url => $item->{resolved_url},
                    added => 0,
                    read => 1,
                };
            }
        }
    }

    # カウント数が設定されていない箇所に0を設定する
    my ($first, $last) = (sort keys %trend)[0,-1];
    my $check_date = localtime->strptime($first, '%Y-%m-%d');
    while( $check_date->ymd("-") le $last ) {
        $trend{ $check_date->ymd("-") }->{add} //= 0;
        $trend{ $check_date->ymd("-") }->{read} //= 0;
        $check_date += ONE_DAY;
    }

    return $c->render('index.tx', {
        trend => \%trend,
        article => $article,
    });
};

get '/refresh' => sub {
    my ($c) = @_;

    warn "Get Pocket Rtrieve!";

    my $uri = URI->new( $RETRIEVE_URL );
    $uri->query_form(
        consumer_key => $c->pocket->{consumer_key},
        access_token => $c->pocket->{access_token},
        detailType => 'simple',
        state => 'all',
        count => '500',
    );

    # 記事を取得
    my $furl = Furl->new( timeout => 10 );
    my $res = $furl->get($uri);
    unless( $res->is_success ) {
        return $c->render('error.tx', {
            error => $res->status_line,
        });
    }

    $c->cache->set( "content", $res->content );

    return $c->redirect('/');
};

1;
