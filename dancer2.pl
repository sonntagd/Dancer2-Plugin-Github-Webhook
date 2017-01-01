
use strict;
use warnings;

use lib 'lib';

use Dancer2;
use Dancer2::Plugin::Github::Webhook;

set serializer => 'JSON';

get '/' => sub {
    return { nothing => "special" };
};

post '/a' => require_github_webhook_secret sub {
    return { content => 'the a page' };
};

dance;