use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request;
use JSON;

{

    package MyTestApp;
    use Dancer2;
    use Dancer2::Plugin::Github::Webhook;

    set serializer => 'JSON';

    set config => { plugin => { 'Github::Webhook' => { secret => 'super!s3cret?' } }, };

    post '/'  => require_github_webhook_secret 'super!s3cret?'           => sub { [1] };
    post '/a' => require_github_webhook_secret 'sk78fozuhv3efgv'         => sub { [1] };
    post '/b' => require_github_webhook_secret '89Av34x!jdfl<'           => sub { [1] };
    post '/c' => require_github_webhook_secret 'anotherverysecretsecret' => sub { [1] };

}

my $app = MyTestApp->to_app;

test_psgi $app, sub {
    my $cb = shift;

    {
        my $req = HTTP::Request->new( POST => '/' );
        my $res = $cb->($req);
        ok $res->code == 403, 'Forbidden if no signature is sent';
        ok JSON::from_json( $res->content )->{message} eq 'No X-Hub-Signature found', 'Got message "No X-Hub-Signature found"';
    }

    {
        my $req = HTTP::Request->new( POST => '/' => [ 'X-Hub-Signature' => 1 ] );
        my $res = $cb->($req);
        ok $res->code == 403, 'Forbidden if wrong signature is sent';
        ok JSON::from_json( $res->content )->{message} eq 'Not allowed', 'Got message "Not allowed" when using wrong signature';
    }

    {
        my $content = JSON::to_json( { some => 'content' } );
        require Digest::SHA;
        my $signature = 'sha1=' . Digest::SHA::hmac_sha1_hex( $content, 'super!s3cret?' );
        my $req = HTTP::Request->new( POST => '/' => [ 'X-Hub-Signature' => $signature ], $content );
        my $res = $cb->($req);
        ok $res->code == 200, 'Correct signature is accepted';
        ok JSON::from_json( $res->content )->[0] eq '1', 'Correct signature is accepted';
    }

    # $res = $test->request(
    #     POST '/',
    #     'X-Hub-Signature' => 1,
    #     Content           => JSON::to_json( { some => 'content' } ),
    # );
    # ok $res->code == 403, 'Forbidden if wrong is sent';
    # ok JSON::from_json( $res->content )->{message} eq 'Not allowed', 'Not allowed because of wrong signature';

    # is( $res->content, '[1]', 'Correct content' );

};

done_testing();
