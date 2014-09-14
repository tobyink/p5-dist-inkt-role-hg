use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Hg;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001';

use Moose::Role;
use File::chdir;
use Types::Standard 'Bool';
use namespace::autoclean;

has source_control_is_hg => (
	is      => "ro",
	isa     => Bool,
	lazy    => 1,
	builder => "_build_source_control_is_hg",
);

sub _build_source_control_is_hg
{
	my $self = shift;
	!! $self->rootdir->child(".hg")->is_dir;
}

before BuildAll => sub
{
	my $self = shift;
	return unless $self->source_control_is_hg;
	
	local $CWD = $self->rootdir;
	my $stat = `hg status`;
	if ($stat =~ /\w/) {
		$self->log("Mercurial has uncommitted changes");
		$self->log($_) for grep /\w/, split /\r?\n/, $stat;
		die "Please commit them";
	}
};

after BUILD => sub
{
	my $self = shift;
	return unless $self->source_control_is_hg;
	return unless $self->can("setup_postrelease_action");
	
	$self->setup_postrelease_action(sub {
		my $self = shift;
		local $CWD = $self->rootdir;
		$self->log("hg tag " . $self->version);
		system("hg", "tag", $self->version);
		$self->log("hg push");
		system("hg", "push");
	});
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Inkt::Role::Hg - Mercurial-related behaviour for Dist::Inkt

=head1 DESCRIPTION

=over

=item *

Prevents a release from being built if there are uncommitted changes.

=item *

Does an << hg tag >> and C<< hg push >> after release.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Dist-Inkt-Role-Hg>.

=head1 SEE ALSO

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

