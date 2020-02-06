
requires 'Cookie::Baker', '0.11';
requires 'HTTP::Cookies', '6.08';
requires 'LWP', '6.43';
requires 'Moo', '2.003006';

on test => sub {
  requires 'Test::More', '1.302171';
  requires 'Test::LoadAllModules', '0.022';
};
