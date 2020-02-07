#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use WWW::EGL::Client;
use JSON::MaybeXS ':all';
use Scalar::Util qw( looks_like_number );

exit plan( skip_all => 'Requires EPIC_GAMES_EMAIL, EPIC_GAMES_PASSWORD' )
  unless $ENV{EPIC_GAMES_EMAIL} && $ENV{EPIC_GAMES_PASSWORD};

my $egl = new_ok('WWW::EGL::Client' => [
  email => $ENV{EPIC_GAMES_EMAIL},
  password => $ENV{EPIC_GAMES_PASSWORD},
]);

my $egl_login_request = $egl->login($ENV{EPIC_GAMES_TWOFACTOR});
isa_ok($egl_login_request, 'WWW::EGL::Request', 'Login Request');

ok($egl_login_request->run, 'Login successful');

my $egl_me_request = $egl->account->me;
isa_ok($egl_me_request, 'WWW::EGL::Request', 'Me Request');

my $data = $egl_me_request->run;
is(ref $data, 'HASH', 'Me result is hashref');

my %d = %{$data};

is(length($d{id}), 32, 'ID has 32 characters');

for (qw( displayName name email ageGroup lastName minorStatus country preferredLanguage )) {
  ok(length($d{$_}) > 0, $_.' has a length');
}

for (qw( canUpdateDisplayName headless minorExpected minorVerified tfaEnabled emailVerified )) {
  ok(is_bool($d{$_}), $_.' is bool');
}

for (qw( failedLoginAttempts numberOfDisplayNameChanges )) {
  ok(looks_like_number($d{$_}), $_.' is number');
}

for (qw( lastLogin )) {
  ok($d{$_} =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d+Z$/, $_.' is proper datetime format');
}

diag("Result of me request: ".(JSON::MaybeXS->new( utf8 => 1, pretty => 1 )->encode($data)));

# my $egl_vault_request = $egl->account->vault();
# isa_ok($egl_vault_request, 'WWW::EGL::Request', 'Vault Request');

# my $vault = $egl_vault_request->run;

# is(ref $vault, 'HASH', 'Vault result is hashref');

# use DDP; p($vault);

# diag(JSON::MaybeXS->new( utf8 => 1, pretty => 1 )->encode($vault));

done_testing;
