package WWW::EGL;

use Moo;
extends 'WWW::EpicGamesLauncher';

use WWW::EGL::Client;

has email => (
  is => 'ro',
  required => 1,
);

has password => (
  is => 'ro',
  required => 1,
);

has client => (
  is => 'lazy',
  builder => 1,
);

sub _build_client {
  my ( $self ) = @_;
  return WWW::EGL::Client->new(
    email => $self->email,
    password => $self->password,
  );
}

sub login {
  my ( $self, @args ) = @_;
  return $self->client->login(@args)->run;
}

1;
