package WWW::EGL::Request;
# ABSTRACT:

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

use Moo;
extends 'WWW::Chain';

sub set_result {
  my ( $self, @result ) = @_;
  $self->stash->{result} = [ @result ];
  return;
}

sub result {
  my ( $self ) = @_;
  return unless $self->done;
  my @results = @{$self->stash->{result}||[]};
  return scalar @results > 1 ? @results : $results[0];
}

sub run {
  my ( $self ) = @_;
  $self->request_with_lwp;
  return $self->result;
}

1;
