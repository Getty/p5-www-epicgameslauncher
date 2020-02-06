package WWW::EpicGamesLauncher;
# ABSTRACT: Module for accessing the Epic Games Launcher API like the Epic Games Launcher Client

use Moo;

=head1 SYNOPSIS

  my $epic = WWW::EpicGamesLauncher->new(
    email => 'your@login.email',
    password => 'iH0pEy0uKnOw1T',
  );

  if ($epic->login($two_factor_code_if_necessary)) {
    
  } else {
    die "Login failed!";
  }

=head1 DESCRIPTION



=cut

1;
