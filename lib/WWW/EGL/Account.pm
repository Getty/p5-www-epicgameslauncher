package WWW::EGL::Account;
# ABSTRACT:

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

use Moo;
use WWW::EGL::Request;
use HTTP::Request::Common;
use Cookie::Baker;

our $LOGIN_FRONTEND = 'https://www.epicgames.com/id';

has client => (
  is => 'ro',
  required => 1,
);

has email => (
  is => 'ro',
  required => 1,
);

has token => (
  is => 'rw',
);

has password => (
  is => 'ro',
  required => 1,
);

sub authenticate_request {
  my ( $self, $strategyFlags ) = @_;
  return GET($LOGIN_FRONTEND.'/api/authenticate',
    'X-Requested-With' => 'XMLHttpRequest',
    'X-Epic-Strategy-Flags' => $strategyFlags || '',
    Referer => $LOGIN_FRONTEND.'/login',
  );
}

sub analytics_request {
  my ( $self, $strategyFlags ) = @_;
  return GET($LOGIN_FRONTEND.'/api/analytics',
    'X-Requested-With' => 'XMLHttpRequest',
    'X-Epic-Strategy-Flags' => $strategyFlags || '',
    Referer => $LOGIN_FRONTEND.'/login',
  );
}

sub xsrf {
  my ( $self, $strategyFlags, $done ) = @_;
  my %headers = (
    'X-Requested-With' => 'XMLHttpRequest',
    'X-Epic-Strategy-Flags' => $strategyFlags || '',
    Referer => $LOGIN_FRONTEND.'/login',
    $self->token ? ( 'X-XSRF-TOKEN' => $self->token ) : (),
  );
  return GET($LOGIN_FRONTEND.'/api/csrf', %headers), sub {
    my $set_token = sub {
      my %cookie = %{crush_cookie($_[1]->request->header('Cookie'))};
      $self->token($cookie{'XSRF-TOKEN'});
      return $done->($_[0]);
    };
    if (!$self->token) {
      return $self->analytics_request($strategyFlags), sub {
        $set_token->(@_);
      };
    } else {
      $set_token->(@_);
    }
  };
}

sub auth {
  my ( $self, $twofactor ) = @_;
  my %creds = (
    email => $self->email,
    password => $self->password,
    $twofactor ? ( twoFactorCode => $twofactor ) : (),
  );
  return WWW::EGL::Request->new( GET($LOGIN_FRONTEND.'/login'), sub {
    GET($LOGIN_FRONTEND.'/api/reputation', 'X-Requested-With' => 'XMLHttpRequest', Referer => $LOGIN_FRONTEND.'/login'), sub {
      GET($LOGIN_FRONTEND.'/api/location', 'X-Requested-With' => 'XMLHttpRequest', Referer => $LOGIN_FRONTEND.'/login'), sub {
        $self->authenticate_request(), sub {
          $self->analytics_request(), sub {
            my $strategyFlags = join(';',qw(
              guardianEmailVerifyEnabled=false
              guardianEmbeddedDocusignEnabled=true
              registerEmailPreVerifyEnabled=false
              unrealEngineGamingEula=true
            ));
            return $self->xsrf($strategyFlags,sub {
              return $_[0]->stash->{token} = $self->token;
            });
          }
        }
      }
    }
  });
}

1;
