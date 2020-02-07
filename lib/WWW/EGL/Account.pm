package WWW::EGL::Account;
# ABSTRACT:

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

use Moo;
use WWW::EGL::Request;
use HTTP::Request::Common;
use JSON::MaybeXS;
use Cookie::Baker;
use Carp qw( croak );

our $LOGIN_FRONTEND = 'https://www.epicgames.com/id';
our $OAUTH_TOKEN = 'https://account-public-service-prod03.ol.epicgames.com/account/api/oauth/token';
our $ACCOUNT = 'https://account-public-service-prod03.ol.epicgames.com/account/api/public/account';
our $MARKETPLACE = 'https://www.unrealengine.com/marketplace/api';

our $EPIC_LAUNCHER_AUTHORIZATION = 'MzQ0NmNkNzI2OTRjNGE0NDg1ZDgxYjc3YWRiYjIxNDE6OTIwOWQ0YTVlMjVhNDU3ZmI5YjA3NDg5ZDMxM2I0MWE=';

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

has auth_data => (
  is => 'rw',
);

sub token_type { $_[0]->auth_data->{token_type} }
sub access_token { $_[0]->auth_data->{access_token} }
sub access_token_expires { $_[0]->auth_data->{access_token_expires} }
sub refresh_token { $_[0]->auth_data->{refresh_token} }
sub refresh_token_expires { $_[0]->auth_data->{refresh_token_expires} }
sub account_id { $_[0]->auth_data->{account_id} }

has password => (
  is => 'ro',
  required => 1,
);

sub api_request {
  my ( $self, $path, $strategyFlags ) = @_;
  return GET($LOGIN_FRONTEND.'/api/'.$path,
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
      return $self->api_request( analytics => $strategyFlags ), sub {
        $set_token->(@_);
      };
    } else {
      $set_token->(@_);
    }
  };
}

sub login {
  my ( $self, $email, $password, $twofactor, $strategyFlags, $done ) = @_;
  return POST($LOGIN_FRONTEND.'/api/login', [
    email => $email,
    password => $password,
    rememberMe => 'false',
    captcha => '',
  ], 'X-XSRF-TOKEN' => $self->token), sub {
    my $code = $_[1]->code;
    if ($code == 409) {
      return $self->login( $self, $email, $password, $twofactor, $strategyFlags );
    } elsif ($code == 431) {
      my $data = decode_json($_[1]->content);
      if (!$twofactor) {
        croak "Login error: ".$data->{metadata}->{message};
      }
      my $twofactor_method = $data->{metadata}->{twoFactorMethod};
      return POST($LOGIN_FRONTEND.'/api/login/mfa', [
        code => $twofactor,
        method => $twofactor_method,
        rememberDevice => 'false',
      ], 'X-XSRF-TOKEN' => $self->token), sub { return $done->(@_) };
    } elsif ($code == 200) {
      return $done->($_[0]);
    }
    croak "Unknown login error: ".$_[1]->content." (".$code.")";
  };
}

sub me {
  my ( $self ) = @_;
  return WWW::EGL::Request->new( GET($ACCOUNT.'/'.$self->account_id, Authorization => $self->token_type.' '.$self->access_token ), sub {
    if ($_[1]->code == 200) {
      my $data = decode_json($_[1]->content);
      return $_[0]->set_result($data);
    } else {
      croak "Unkown error while fetching me: ".$_[1]->content." (".$_[1]->code.")";
    }
  });
}

sub vault {
  my ( $self ) = @_;
  return WWW::EGL::Request->new( GET($MARKETPLACE.'/assets/vault', Authorization => $self->token_type.' '.$self->access_token ), sub {
    use DDP; p(@_);
    if ($_[1]->code == 200) {
      my $data = decode_json($_[1]->content);
      return $_[0]->set_result($data);
    } else {
      croak "Unkown error while fetching vault: ".$_[1]->content." (".$_[1]->code.")";
    }
  });
}

sub auth {
  my ( $self, $twofactor ) = @_;
  return WWW::EGL::Request->new( GET($LOGIN_FRONTEND.'/login'), sub {
    GET($LOGIN_FRONTEND.'/api/reputation', 'X-Requested-With' => 'XMLHttpRequest', Referer => $LOGIN_FRONTEND.'/login'), sub {
      GET($LOGIN_FRONTEND.'/api/location', 'X-Requested-With' => 'XMLHttpRequest', Referer => $LOGIN_FRONTEND.'/login'), sub {
        $self->api_request('authenticate'), sub {
          $self->api_request('analytics'), sub {
            my $strategyFlags = join(';',qw(
              guardianEmailVerifyEnabled=false
              guardianEmbeddedDocusignEnabled=true
              registerEmailPreVerifyEnabled=false
              unrealEngineGamingEula=true
            ));
            return $self->xsrf($strategyFlags, sub {
              return $self->login($self->email, $self->password, $twofactor, $strategyFlags, sub {
                return $self->api_request('redirect'), sub {
                  return $self->api_request('authenticate'), sub {
                    return $self->api_request('exchange'), sub {
                      if ($_[1]->code == 200) {
                        my $data = decode_json($_[1]->content);
                        my $exchange_code = $data->{code};
                        return POST($OAUTH_TOKEN, [
                          grant_type => 'exchange_code',
                          exchange_code => $exchange_code,
                          token_type => 'eg1',
                          includePerms => 'false',
                        ], Authorization => 'basic MzRhMDJjZjhmNDQxNGUyOWIxNTkyMTg3NmRhMzZmOWE6ZGFhZmJjY2M3Mzc3NDUwMzlkZmZlNTNkOTRmYzc2Y2Y='), sub {
                          if ($_[1]->code == 200) {
                            my $data = decode_json($_[1]->content);
                            $self->auth_data({
                              access_token => $data->{access_token},
                              access_token_expires => time() + $data->{expires_in},
                              refresh_token => $data->{refresh_token},
                              refresh_token_expires => time() + $data->{refresh_expires},
                              token_type => $data->{token_type},
                              account_id => $data->{account_id},
                              client_id => $data->{client_id},
                              in_app_id => $data->{in_app_id},
                              device_id => $data->{device_id},
                            });
                            return $_[0]->set_result($self->auth_data);
                          }
                          croak "Unknown oauth error: ".$_[1]->content." (".$_[1]->code.")";
                        };
                      }
                      croak "Unknown auth error: ".$_[1]->content." (".$_[1]->code.")";
                    };
                  };
                };
              });
            });
          }
        }
      }
    }
  });
}

1;
