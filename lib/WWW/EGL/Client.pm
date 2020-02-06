package WWW::EGL::Client;
# ABSTRACT:

=head1 SYNOPSIS

  my $epic_client = WWW::EGL::Client->new(
    email => 'your@login.email',
    password => 'iH0pEy0uKnOw1T',
  );

  my $epic_request = $epic_client->login($two_factor_code_if_necessary);
  
  my @http_requests = $epic_request->http_requests;

  # ... convert @http_requests to @http_responses

  my $result = $epic_request->http_responses(@http_responses);

  if ($result->is_success) {
    my $epic_client = $epic_request->actor;
  } else {
    die "Login failed!";
  }

=head1 DESCRIPTION



=cut

use Moo;
use WWW::EGL::Account;
use WWW::EGL::Request;

has email => (
  is => 'ro',
  required => 1,
);

has password => (
  is => 'ro',
  required => 1,
);

sub login {
  my ( $self, $twofactor ) = @_;
  return $self->account->auth($twofactor);
}

has account => (
  is => 'lazy',
  builder => 1,
);

sub _build_account {
  my ( $self ) = @_;
  return WWW::EGL::Account->new(
    client => $self,
    email => $self->email,
    password => $self->password,
  );
}

1;
