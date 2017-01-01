use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON;

{

    package MyTestApp;
    use Dancer2;
    use Dancer2::Plugin::Github::Webhook;

    set serializer => 'JSON';

    set config => {
        plugin             => { 'Github::Webhook' => { secret => 'super!s3cret?' } },
        my_special_secrets => {
            endpoint_a => 'owiejf20jf',
            endpoint_b => 'woiUehf29',
        },
    };

    post '/' => require_github_webhook_secret sub { [1] };
    post '/a' => require_github_webhook_secret config->{my_special_secrets}->{endpoint_a} => sub { [1] };
    post '/b' => require_github_webhook_secret config->{my_special_secrets}->{endpoint_a} => sub { [1] };
    post '/c' => require_github_webhook_secret 'anotherverysecretsecret'                  => sub { [1] };

}

my $test = Plack::Test->create( MyTestApp->to_app );
my $res  = $test->request( POST '/' );
ok $res->code == 403, 'Forbidden if no signature is sent';
ok JSON::from_json( $res->content )->{message} eq 'No X-Hub-Signature found', 'Got message "No X-Hub-Signature found"';

$res = $test->request( POST '/' => { 'X-Hub-Signature' => 1 } => JSON::to_json( { some => 'content' } ) );
ok $res->code == 403, 'Forbidden if wrong is sent';
ok JSON::from_json( $res->content )->{message} eq 'Not allowed', 'Not allowed because of wrong signature';

is( $res->content, '[1]', 'Correct content' );

done_testing();
