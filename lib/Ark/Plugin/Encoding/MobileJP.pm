package Ark::Plugin::Encoding::MobileJP;
use strict;
use warnings;
use Ark::Plugin;

use Encode;
use Encode::JP::Mobile ':props';
use Encode::JP::Mobile::Character;
use HTTP::MobileAgent::Plugin::Charset;

has encoding => (
    is      => 'ro',
    isa     => 'Object',
    lazy    => 1,
    default => sub {
        my ($c) = @_;

        unless ($c->can('mobile_agent')) {
            die 'Plugin::Encoding::MobileJP is required Plugin::MobileAgent';
        }

        my $encoding = $c->mobile_agent->encoding;
        ref($encoding) && $encoding->isa('Encode::Encoding')
            ? $encoding
            : Encode::find_encoding($encoding);
    },
);

sub prepare_encoding {
    my ($c) = @_;
    my $req = $c->request;

    # for backward compatible
    delete $req->env->{'plack.request.withencoding.body'};
    delete $req->env->{'plack.request.withencoding.query'};
    delete $req->env->{'plack.request.withencoding.merged'};

    $req->env->{'plack.request.withencoding.encoding'} = $c->encoding->name;
}

my %htmlspecialchars = ( '&' => '&amp;', '<' => '&lt;', '>' => '&gt;', '"' => '&quot;' );
my $htmlspecialchars = join '', keys %htmlspecialchars;

sub finalize_encoding {
    my ($c) = @_;

    if (!$c->res->binary and $c->res->has_body) {
        my $body = $c->res->body;

        $body = encode($c->encoding, $body, sub {
            my $char = shift;
            my $out  = Encode::JP::Mobile::FB_CHARACTER()->($char);

            if ($c->res->content_type =~ /html$|xml$/) {
                $out =~ s/([$htmlspecialchars])/$htmlspecialchars{$1}/ego; # for (>３<)
            }

            $out;
        });

        $c->res->body($body);
    }
}

1;
