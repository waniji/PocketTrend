requires 'Amon2', '6.09';
requires 'Crypt::CBC';
requires 'Crypt::Rijndael';
requires 'HTML::FillInForm::Lite', '1.11';
requires 'HTTP::Session2', '1.03';
requires 'JSON', '2.50';
requires 'Module::Functions', '2';
requires 'Plack::Middleware::ReverseProxy', '0.09';
requires 'Router::Boom', '0.06';
requires 'Starlet', '0.20';
requires 'Test::WWW::Mechanize::PSGI';
requires 'Text::Xslate', '2.0009';
requires 'Time::Piece', '1.20';
requires 'Furl';
requires 'perl', '5.010_001';

on configure => sub {
    requires 'Module::Build', '0.38';
    requires 'Module::CPANfile', '0.9010';
};

on test => sub {
    requires 'Test::More', '0.98';
};
