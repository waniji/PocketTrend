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

my $RETRIEVE_URL = 'https://getpocket.com/v3/get';

get '/' => sub {
    my ($c) = @_;

    my $content = $c->cache->get("content");
    if( !defined $content or $content eq "" ) {
        return $c->redirect('/refresh');
    }
    $content = decode_json($content);

    # 追加数と読了数をカウント
    my %counter;
    for my $item ( values %{ $content->{list} } ) {
        my $add_date = localtime($item->{time_added})->ymd("-");
        $counter{$add_date}->{add}++;
        if( $item->{time_read} ) {
            my $read_date = localtime($item->{time_read})->ymd("-");
            $counter{$read_date}->{read}++;
        }
    }

    # カウント数が設定されていない箇所に0を設定する
    my ($first, $last) = (sort keys %counter)[0,-1];
    my $check_date = localtime->strptime($first, '%Y-%m-%d');
    while( $check_date->ymd("-") le $last ) {
        $counter{ $check_date->ymd("-") }->{add} //= 0;
        $counter{ $check_date->ymd("-") }->{read} //= 0;
        $check_date += ONE_DAY;
    }

    # 日付順にソートしたデータを作成
    my @trend;
    for (sort keys %counter) {
        push @trend, +{ date => $_, add => $counter{$_}->{add}, read => $counter{$_}->{read} };
    }

    return $c->render('index.tx', {
        trend => \@trend,
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
        count => '100',
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
