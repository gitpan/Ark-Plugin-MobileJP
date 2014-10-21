use strict;
use warnings;
use utf8;
use Test::Requires 'Encode::JP::Mobile', 'HTTP::MobileAgent::Plugin::Charset';
use Test::More;

use Encode;
use HTTP::Request::Common;

{
    package T;
    use Ark;

    use_plugins qw{
        +T::Encoding::Test
        MobileAgent
        Encoding::MobileJP
    };

    package T::Encoding::Test;
    use Ark::Plugin;

    sub prepare_encoding {
        my ($c) = @_;

        $c->request->parameters; # called parameters before
        Ark::Plugin::Encoding::MobileJP::prepare_encoding(@_);
    }

    package T::Controller::Root;
    use Ark 'Controller';

    has '+namespace' => default => '';

    sub test :Local {
    }
}

use Ark::Test 'T',
    components => [qw/Controller::Root/];

# DoCoMo
{
    my $request = POST '/test', [
        'word' => Encode::encode('utf8', "こんにちは"),
    ];

    $request->header('User-Agent' => 'DoCoMo/2.0 P900i(c100;TB;W24H11)');

    ok my ($response, $c) = ctx_request($request), 'DoCoMo Request';
    is $c->encoding->name, 'x-utf8-docomo', 'encoding is x-utf8-docomo';

    is Encode::is_utf8($c->req->param('word')), 1, 'utf-8 flagged';
    is $c->req->param('word'), 'こんにちは', 'encoded parameter ok';
}

# AU
{
    my $request = POST '/test', [
        'word' => Encode::encode('sjis', 'こんにちは'),
    ];

    $request->header('User-Agent' => 'KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0');

    ok my ($response, $c) = ctx_request($request), 'AU Request';
    is $c->encoding->name, 'x-sjis-kddi-auto', 'encoding is x-sjis-kddi-auto';

    is utf8::is_utf8($c->req->param('word')), 1, 'utf-8 flagged';
    is $c->req->param('word'), 'こんにちは', 'encoded parameter ok';

    is $c->req->param('word'), 'こんにちは', 'encoded parameter ok';
}

# Softbank
{
    my $request = POST '/test', [
        'word' => Encode::encode('utf8', 'こんにちは'),
    ];

    $request->header('User-Agent' => 'SoftBank/1.0/910T/TJ001/SN123456789012345');

    ok my ($response, $c) = ctx_request($request), 'Softbank Request';
    is $c->encoding->name, 'x-utf8-softbank', 'encoding is x-utf8-softbank';

    is utf8::is_utf8($c->req->param('word')), 1, 'utf-8 flagged';
    is $c->req->param('word'), 'こんにちは', 'encoded parameter ok';
}

done_testing;
