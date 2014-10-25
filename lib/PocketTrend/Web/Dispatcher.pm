package PocketTrend::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::RouterBoom;
use JSON;
use URI;
use URI::WithBase;
use HTTP::Body;
use Time::Piece;
use Time::Seconds;
use Encode qw/decode_utf8/;

my $RETRIEVE_URL = 'https://getpocket.com/v3/get';
my $REQUEST_TOKEN_URL = 'https://getpocket.com/v3/oauth/request';
my $USER_AUTHORIZATION_URL = 'https://getpocket.com/auth/authorize';
my $ACCESS_TOKEN_URL = 'https://getpocket.com/v3/oauth/authorize';

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
        consumer_key => $c->cache->get('consumer_key'),
        access_token => $c->cache->get('access_token'),
        detailType => 'simple',
        state => 'all',
        count => '500',
    );

    # 記事を取得
    my $res = $c->furl->get($uri);
    unless( $res->is_success ) {
        return $c->render('error.tx', {
            error => $res->status_line,
        });
    }

    $c->cache->set( "content", $res->content );

    return $c->redirect('/');
};

get '/setting' => sub {
    my ($c) = @_;
    return $c->render('setting.tx');
};

post '/setting/consumer_key' => sub {
    my ($c) = @_;

    my $consumer_key = $c->req->param("consumer_key");
    unless( $consumer_key ) {
        return $c->render('error.tx', {
            error => "consumer_keyが入力されていません"
        });
    }

    my $redirect_uri = URI::WithBase->new(
        "/setting/access_token", $c->req->base
    )->abs->as_string;

    my $response = $c->furl->post(
        $REQUEST_TOKEN_URL, [], [
            consumer_key => $consumer_key,
            redirect_uri => $redirect_uri,
        ],
    );
    unless( $response->is_success ) {
        return $c->render('error.tx', {
            error => sprintf("%s: %s", $response->status, $response->message),
       });
    }

    my $body = HTTP::Body->new(
        $response->content_type,
        $response->content_length,
    );
    $body->add($response->content);
    my $request_token = $body->param->{'code'};

    $c->cache->set('consumer_key' => $consumer_key);
    $c->cache->set('request_token' => $request_token);

    return $c->redirect( $USER_AUTHORIZATION_URL, {
        request_token => $request_token,
        redirect_uri => $redirect_uri,
    });
};

get '/setting/access_token' => sub {
    my $c = shift;

    my $consumer_key = $c->cache->get('consumer_key');
    my $request_token = $c->cache->get('request_token');

    my $response = $c->furl->post(
        $ACCESS_TOKEN_URL, [], [
            consumer_key => $consumer_key,
            code => $request_token,
        ],
    );
    unless ( $response->is_success ) {
        return $c->render('error.tx', {
            error => sprintf("%s: %s", $response->status, $response->message),
        });
    }

    my $body = HTTP::Body->new(
        $response->content_type,
        $response->content_length,
    );
    $body->add($response->content);
    $c->cache->set( "access_token", $body->param->{'access_token'} );

    return $c->redirect('/');
};

1;
