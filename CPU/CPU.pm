package Sys::CPU;

use strict;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK $VERSION);
require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# This allows declaration	use Sys::CPU ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	cpu_count
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.01';

bootstrap Sys::CPU $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Sys::CPU - Perl extension for getting CPU information. Currently only number of CPU's supported.

=head1 SYNOPSIS

  use Sys::CPU;
  
  $number_of_cpus = Sys::CPU::cpu_count();
  printf("I have %d CPU's\n",$number_of_cpus);

=head1 DESCRIPTION

In responce toa post on perlmonks.org, a module for counting the number of CPU's on a 
system. Will work to add support for CPU information. Windows support untested because
i do not have an NT server with multiple CPU's

=head2 EXPORT

None by default.
Tag all exports cpu_count currently


=head1 AUTHOR

MZSanford

=head1 SEE ALSO

perl(1), sysconf(3)

=cut
