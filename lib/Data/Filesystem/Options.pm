package Data::Filesystem::Options;
BEGIN {
  $Data::Filesystem::Options::VERSION = '0.01';
}
# ABSTRACT: Data::Filesystem options


use Any::Moose;


has curdir_name => (is => 'rw', default => '.');


has parentdir_name => (is => 'rw', default => '..');


has parse_volume => (is => 'rw', default => ':');


has path_separator => (is => 'rw', default => '/');


has ro => (is => 'rw', default => 0);


has volume_separator => (is => 'rw', default => ':');

__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;

__END__
=pod

=head1 NAME

Data::Filesystem::Options - Data::Filesystem options

=head1 VERSION

version 0.01

=head1 SYNOPSIS


    # getting option
    if ($dfs->options->path_separator ne '/') { ... }

    # setting option
    $validator->options->path_separator('\\');

=head1 DESCRIPTION


Options for Data::Filesystem.

=head1 ATTRIBUTES


=head2 curdir_name => STR


Default is '.'.


See also: B<parentdir_name>, B<path_separator>.


=head2 parentdir_name => STR


Default is '..'.


See also: B<curdir_name>, B<path_separator>.


=head2 parse_volume => BOOL


Default is 0.


Volume is used to allow accessing several data structures. When
B<parse_volume> is not turned on (which is the default), path is
parsed in Unix-like style of single root tree. But when
B<parse_volume> is set to true, volume is parsed, e.g.:


 foo:/a/b/c
 bar:/a/b/c


They will be parsed, consecutively, as /a/b/c for the foo volume and
/a/b/c for the bar volume.


See also: B<volume_separator>.


=head2 path_separator => STR


Default is '/'. Note that since there is no escaping mechanism in path
names, a path cannot contain the path separator name (as well as the
curdir_name and parentdir_name). This is just like in Unix filesystem
where you cannot have a filename with "/" in it, or a file/dir named
"." and "..".


See also: B<curdir_name>, B<parentdir_name>, B<volume_separator>.


=head2 ro => BOOL


Whether the filesystem should be read only. The default is 0, which
means read/write.


When 'ro' is set to true, commands like rm(), set(), and unset() will
fail. But note that since get() can retrieve reference to whole
branches of data structure, you can always modify the data directly.


=head2 volume_separator => STR


Default is ':'. The string used to separate volume and path. This is
only relevant when B<parse_volume> in true.


See also: B<curdir_name>, B<parentdir_name>, B<parse_volume>,
B<path_separator>.

=head1 AUTHOR

  Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

