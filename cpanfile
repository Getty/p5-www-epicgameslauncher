
requires 'Cookie::Baker', '0.11';
requires 'JSON::MaybeXS', '1.004000';
requires 'HTTP::Cookies', '6.08';
requires 'LWP', '6.43';
requires 'LWP::Protocol::https', '6.07';
requires 'Moo', '2.003006';

on test => sub {
  requires 'Test::More', '1.302171';
  requires 'Scalar::Util', '0';
  requires 'Test::LoadAllModules', '0.022';
};
