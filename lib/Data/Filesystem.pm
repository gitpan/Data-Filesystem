package Data::Filesystem;
BEGIN {
  $Data::Filesystem::VERSION = '0.02';
}
# ABSTRACT: Access and modify data structures like a filesystem


use feature 'state';
use Any::Moose;
use Data::Filesystem::Options;


has options => (is => 'rw', default => sub { Data::Filesystem::Options->new });


has active_volume => (is => 'rw');


has cwds => (is => 'rw', default => sub { {} });


has refs => (is => 'rw', default => sub { {} });


has mounts => (is => 'rw', default => sub { [] });


sub _is_hashref_or_arrayref {
    my ($self, $data) = @_;
    my $ref = ref($data);
    return unless $ref;
    $ref =~ /^(^=+=)?(HASH|ARRAY)/;
}

sub _is_hashref {
    my ($self, $data) = @_;
    my $ref = ref($data);
    return unless $ref;
    $ref =~ /^(^=+=)?HASH/;
}

sub _is_arrayref {
    my ($self, $data) = @_;
    my $ref = ref($data);
    return unless $ref;
    $ref =~ /^(^=+=)?ARRAY/;
}


sub BUILD {
    my ($self, $args) = @_;
    my $data = $args->{data};
    if (defined($data)) {
        my $vol = $args->{vol} // '';
        $self->addvol($vol, $data);
        $self->active_volume($vol);
    }
}


sub addvol {
    my ($self, $vol, $data) = @_;
    die "Please specify volume" unless defined($vol);
    die "Volume name should be a string" if ref($vol);
    die "Please specify data" unless defined($data);
    die "Volume `$vol` already defined, use rmvol() first if you want to replace it"
        if $self->refs->{$vol};
    die "Invalid data, please supply arrayref/hashref"
        unless $self->_is_hashref_or_arrayref($data);
    $self->cwds->{$vol} = [];
    $self->refs->{$vol} = [$data];
    $self->active_volume($vol) unless defined($self->active_volume);
    $self;
}


sub rmvol {
    my ($self, $vol) = @_;
    die "Please specify volume" unless defined($vol);
    die "Invalid volume `$vol`" unless $self->refs->{$vol};
    die "Cannot remove active volume `$vol`" if $self->active_volume eq $vol;

    delete $self->cwds->{$vol};
    delete $self->refs->{$vol};
    $self;
}

sub _check_ro {
    my ($self, $path) = @_;
    if ($self->options->ro) {
        my $p = ref($path) ? $self->parray_to_path($path) : $path;
        die "Filesystem is mounted read-only (path=$p)";
    }
}

sub _traverse {
    my ($self, $path0, $opts) = @_;
    state $default_errmsg = sub { "No such file or directory `$_[0]`" };

    $path0 //= "";
    my $path = $self->path_to_parray($path0);
    die "Invalid path `$path0`" unless defined($path);

    my $vol0 = $path->[0];
    my $vol  = $vol0 // $self->active_volume;
    die "Invalid volume `$vol`" unless defined($self->refs->{$vol});

    my $so  = $self->options;
    my $cur = $so->curdir_name;
    my $par = $so->parentdir_name;

    my $cwd = [@{ $self->cwds->{$vol} }];
    my $ref = [@{ $self->refs->{$vol} }];
    if ($self->is_abs_path($path)) {
        $cwd = [];
        $ref = [$ref->[0]];
    }
    my $data = $ref->[-1];

    my $num_created = 0;

    for (my $i=1; $i < @$path; $i++) {
        my $is_leaf = $i == @$path-1;
        my $create = $opts->{create_intermediate} ||
            $opts->{create_leaf} && $is_leaf;
        my $p = $path->[$i];
        #use Data::Dump qw(pp); print "DEBUG: step: p=$p, vol=$vol, ref=", pp($ref), "cwd=", pp($cwd), "\n";
        if ($p eq $cur) {
            # do nothing
        } elsif ($p eq $par) {
            if (@$cwd) {
                pop @$cwd;
                pop @$ref;
                $data = $ref->[-1];
            }
        } else {
            my $err = 0;
            my $errmsg = $default_errmsg;
            if ($self->_is_arrayref($data)) {
                if ($p =~ /^-?\d+$/) {
                    if (abs($p) >= @$data && $create) {
                        $self->_check_ro($path);
                        $data->[$p] = $is_leaf ? $opts->{new_leaf_node} :
                            $so->{new_hash_sub}->();
                        $num_created++;
                    }
                    if (abs($p) < @$data) {
                        $data = $data->[$p];
                    } else {
                        $err = 2;
                    }
                } else {
                    $err = 2;
                }
            } elsif ($self->_is_hashref($data)) {
                if (!(exists $data->{$p}) && $create) {
                    $self->_check_ro($path);
                    $data->{$p} = $is_leaf ? $opts->{new_leaf_node} :
                        $so->{new_hash_sub}->();
                    $num_created++;
                }
                if (exists $data->{$p}) {
                    $data = $data->{$p};
                } else {
                    $err = 2;
                }
            } else {
                if ($create) {
                    $data = $is_leaf ? $opts->{new_leaf_node} :
                        $so->{new_hash_sub}->();
                    my $par = $ref->[-1];
                    if ($self->_is_hashref($par)) {
                        $self->_check_ro($path);
                        $par->{$p} = $data;
                        $num_created++;
                    } elsif ($self->_is_arrayref($par)) {
                        if ($p =~ /^-?\d+$/) {
                            $self->_check_ro($path);
                            $par->[$p] = $data;
                            $num_created++;
                        } else {
                            $err = 1;
                            $errmsg = sub { "Can't create `$p` under `$_[0]`"};
                        }
                    } else {
                        $err = 1;
                        $errmsg = sub { "Can't create under nondir: `$_[0]`"};
                    }
                } else {
                    $err = 1;
                }
            }

            if (!$err) {
                push @$ref, $data;
                push @$cwd, $p;
            } else {
                my $pp = [$vol0, @$cwd];
                push @$pp, $p if $err > 1;
                $pp = $self->parray_to_path($pp);
                die $errmsg->($pp);
            }
        }
    }

    my $is_dir = $self->_is_hashref_or_arrayref($data);
    if ($opts->{require_file_leaf} && $is_dir) {
        my $pp = $self->parray_to_path([$vol0, @$cwd]);
        die "Not a file: `$pp`"
    } elsif ($opts->{require_dir_leaf} && !$is_dir) {
        my $pp = $self->parray_to_path([$vol0, @$cwd]);
        die "Not a directory: `$pp`";
    }

    $opts->{after_traverse_hook}->($self, data=>$data, cwd=>$cwd, ref=>$ref,
                                   vol => $vol, num_created => $num_created)
        if $opts->{after_traverse_hook};
    #use Data::Dump qw(pp); print "DEBUG: after traverse: vol=$vol, ref=", pp($ref), "cwd=", pp($cwd), "\n";
}


sub cwd {
    my ($self, $vol) = @_;
    $vol //= $self->active_volume;
    die "Invalid volume `$vol`" unless $self->refs->{$vol};
    $self->parray_to_path([undef, @{ $self->cwds->{$vol} }]);
}


sub cd {
    my ($self, $path) = @_;
    $self->_traverse($path, {
        require_dir_leaf => 1,
        after_traverse_hook => sub {
            my ($self, %args) = @_;
            my $vol = $args{vol};
            $self->cwds->{$vol} = $args{cwd};
            $self->refs->{$vol} = $args{ref};
        },
    });
    $self;
}


sub cvol {
    my ($self, $vol) = @_;
    die "Please specify volume" unless defined($vol);
    die "Invalid volume `$vol`" unless $self->refs->{$vol};
    $self->active_volume($vol);
    $self;
}


sub get {
    my ($self, $path) = @_;
    my $data;
    $self->_traverse($path, {
        after_traverse_hook => sub {
            my ($self, %args) = @_;
            $data = $args{data};
        },
    });
    $data;
}


sub get_or_undef {
    my ($self, $path) = @_;
    my $res;
    eval { $res = $self->get($path) };
    $res;
}


sub _set {
    my ($self, $path, $val, $preexist, %extra_opts) = @_;
    # preexist: 1 = must exist, 0 = must not exist, undef = doesn't matter
    $extra_opts{create_leaf} = 1 unless defined($extra_opts{create_leaf});
    $self->_traverse($path, {
        new_leaf_node => $val,
        after_traverse_hook => sub {
            my ($self, %args) = @_;
            my $cwd = $args{cwd};
            my $created = $args{num_created};
            if (defined($preexist) && !$preexist && !$created) {
                my $pp = $self->parray_to_path($cwd);
                die "Cannot create an existing file or directory `$pp`";
            }
            unless ($args{num_created}) {
                $self->_check_ro($path);
                my $ref = $args{ref};
                $ref->[-1] = $val;
                if (@$ref > 1) {
                    if ($self->_is_arrayref($ref->[-2])) {
                        $ref->[-2][$cwd->[-1]] = $ref->[-1];
                    } else {
                        $ref->[-2]{$cwd->[-1]} = $ref->[-1];
                    }
                }
            }
        },
        %extra_opts,
    });
    $val;
}

sub set {
    my ($self, $path, $val) = @_;
    $self->_set($path, $val);
}


sub set_file {
    my ($self, $path, $val, $preexist) = @_;
    die "Can't set_file with hashref/arrayref" if
        $self->_is_hashref_or_arrayref($val);
    $self->_set($path, $val, $preexist, require_file_leaf => 1);
}


sub create_file {
    my ($self, $path, $val) = @_;
    $self->set_file($path, $val, 0);
}


sub replace_file {
    my ($self, $path, $val) = @_;
    $self->set_file($path, $val, 1, create_leaf => 0);
}



sub ls {
    my ($self, $path) = @_;
    $path //= ".";
    my $res;
    $self->_traverse($path, {
        after_traverse_hook => sub {
            my ($self, %args) = @_;
            my $data = $args{data};
            if ($self->_is_arrayref($data)) {
                $res = [0 .. @$data-1];
            } elsif ($self->_is_hashref($data)) {
                $res = [keys %$data];
            } else {
                $res = [$args{cwd}[-1]];
            }
        },
    });
    $res;
}


sub readdir {
    my ($self, $path) = @_;
    my $res;
    $self->_traverse($path, {
        require_dir_leaf => 1,
        after_traverse_hook => sub {
            my ($self, %args) = @_;
            my $data = $args{data};
            if ($self->_is_arrayref($data)) {
                $res = [0 .. @$data-1];
            } else {
                $res = [keys %$data];
            }
        },
    });
    $res;
}


sub mkdir {
    my ($self, $path) = @_;
    $self->_traverse($path, {
        create_leaf => 1,
        new_leaf_node => $self->options->{new_hash_sub}->(),
        require_dir_leaf => 1,
    });
    $self;
}


sub mktree {
    my ($self, $path) = @_;
    $self->_traverse($path, {
        create_intermediate => 1,
        new_leaf_node => $self->options->{new_hash_sub}->(),
        require_dir_leaf => 1,
    });
    $self;
}


sub _unlink {
    my ($self, $path, $check_empty_dir, %extra_opts) = @_;
    $self->_traverse($path, {
        after_traverse_hook => sub {
            my ($self, %args) = @_;

            if ($check_empty_dir) {
                my $r = $args{ref}[-1];
                if ($self->_is_arrayref($r) && @$r ||
                    $self->_is_hashref($r)  && scalar(keys %$r)) {
                    my $pp = ref($path) ? $self->parray_to_path($path) : $path;
                    die "Directory not empty `$pp`";
                }
            }

            $self->_check_ro($path);
            my $vol = $args{vol};
            my $cwd = $args{cwd};
            if (@$cwd) {
                my $r = $args{ref}[-2];
                my $p = $cwd->[-1];
                if ($self->_is_arrayref($r)) {
                    splice @$r, $p, 1;
                } else {
                    delete $r->{$p};
                }
            } else {
                $self->refs->{$vol} = [{}];
            }
        },
        %extra_opts,
    });
    $self;
}

sub unlink {
    my ($self, $path) = @_;
    $self->_unlink($path, 0, require_file_leaf => 1);
}


sub rmdir {
    my ($self, $path) = @_;
    $self->_unlink($path, 1, require_dir_leaf => 1);
}


sub rmtree {
    my ($self, $path) = @_;
    $self->_unlink($path, 0);
}


sub is_file {
    my ($self, $path) = @_;
    my $res;
    $self->_traverse($path, {
        after_traverse_hook => sub {
            my ($self, %args) = @_;
            my $data = $args{data};
            $res = !$self->_is_hashref_or_arrayref($data);
        },
    });
    $res;
}


sub is_dir {
    my ($self, $path) = @_;
    my $res;
    $self->_traverse($path, {
        after_traverse_hook => sub {
            my ($self, %args) = @_;
            my $data = $args{data};
            $res = $self->_is_hashref_or_arrayref($data);
        },
    });
    $res;
}


sub is_abs_path {
    my ($self, $path0) = @_;
    my $path = $self->path_to_parray($path0);
    die "Invalid path `$path0`" unless $path;

    return !(@$path > 1 && (
        $path->[1] eq $self->options->curdir_name ||
        $path->[1] eq $self->options->parentdir_name));
}


sub path_to_parray {
    my ($self, $path) = @_;
    my $vol;

    return $path if ref($path) eq 'ARRAY';
    return undef unless defined($path);

    my $vsep = $self->options->volume_separator;
    my $psep = $self->options->path_separator;
    my $cur  = $self->options->curdir_name;
    my $par  = $self->options->parentdir_name;

    if ($self->options->parse_volume && (my $i = index($path, $vsep)) >= 0) {
        $vol = substr($path, 0, $i);
        $path = substr($path, $i+length($vsep));
    } else {
        $vol = undef;
    }
    return undef unless length($path);

    my $re = quotemeta($psep);
    $re = qr/$re/;
    $path = [split /(?:$re)+/, $path];

    if (@$path) {

        # normalize #1: remove all /. and /.. at the beginning because
        # we can't get higher than root
        while (1) {
            if (@$path >= 2 && $path->[0] eq '' &&
                    ($path->[1] eq $cur || $path->[1] eq $par)) {
                splice @$path, 1, 1;
            } else {
                last;
            }
        }

        # normalize #2: remove all . (except in the beginning) because
        # they are non-op
        my $i = 1;
        while ($i < @$path) {
            if ($path->[$i] eq $cur) {
                splice @$path, $i, 1;
            } else {
                $i++;
            }
        }

        # WE DO NOT DO THIS, BECAUSE x might not be valid or
        # dir. normalize #2: remove all x/.. (unless x is . or ..)
        # because they cancel each other
        #$i = 0;
        #while ($i < @$path-1) {
        #    if ($path->[$i+1] eq $par &&
        #            $path->[$i] ne $cur && $path->[$i] ne $par) {
        #        splice @$path, $i, 2;
        #        $i-- unless $i<1;
        #    } else {
        #        $i++;
        #    }
        #}

        # normalize #3: add "." (if nonabs) or remove "." (if abs)
        if (@$path) {
            if ($path->[0] eq '') {
                shift @$path;
            } elsif ($path->[0] ne $cur && $path->[0] ne $par) {
                unshift @$path, $cur;
            }
        }

    }

    [$vol, @$path];
}


sub parray_to_path {
    my ($self, $path) = @_;
    my $vsep = $self->options->volume_separator;
    my $psep = $self->options->path_separator;

    join("",
         (defined($path->[0]) ? $path->[0] . $vsep : ""),
         ($self->is_abs_path($path) ? $psep : ""),
         join($psep, @{$path}[1..@$path-1])
    );
}


__PACKAGE__->meta->make_immutable;
no Any::Moose;
1;

__END__
=pod

=head1 NAME

Data::Filesystem - Access and modify data structures like a filesystem

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use Data::Filesystem;
    my $data  = {a => {b => {c=>  1}, b2 => {c=> 2}}, a2 => [0,  10, {b=> 20}]};
    my $data2 = {a => {b => {c=> -1}, b2 => {c=>-2}}, a2 => [0, -10, {b=>-20}]};
    my $dfs = Data::Filesystem->new(data => $data);

    my $res;

    # getting data
    say $dfs->get("/a/b/c");     # 1
    say $dfs->get("/a2/2/1");    # 10
    $res = $dfs->get("/a/b2");   # {c => 2}
    say $dfs->get("/a3");        # dies with "No such file or directory" error

    # changing location
    $dfs->cd("/a");
    say $dfs->get("b/c");        # 1
    say $dfs->get("../b2/c");    # 2
    say $dfs->cd("b")->get("c"); # 1
    $dfs->cd("../b2/c");         # dies with "Not a directory" error
    $dfs->cd("/a3");             # dies with "No such file or directory" error

    # listing data
    $res = $dfs->ls("/a");       # ["b", "b2"]
    $res = $dfs->readdir("/a");  # ditto

    # setting data
    $dfs->set("/a/b/c", 3);
    $dfs->set("/a/b", {c =>3});
    $dfs->set_file("/a/b/c", 3);
    $dfs->set_file("/a/b", {c =>3}); # dies, set_file() can only set leaf nodes
    $dfs->set_file("/a/b/c", {});

    $dfs->create_file("/a/b/d", 1);
    $dfs->create_file("/a/b/d", 2);  # dies, create_file can only create previously nonexisting file
    $dfs->replace_file("/a/b/d", 2);
    $dfs->replace_file("/a/b/e", 2); # dies, replace_file can only replace previously existing file
    $dfs->create_or_replace_file("/a/b/e", 2);

    $dfs->mkdir("/a/b/c2");
    $dfs->mkdir("/a/b/c2/d");    # dies, can't create intermediate directory
    $dfs->mktree("/a/b/c2/d");   # like mkdir -p

    # deleting data
    $dfs->unlink("/a/b/c");
    $dfs->unlink("/a/b");        # dies, can't unlink directory
    $dfs->rmdir("/a/b");
    $dfs->rmdir("/a");           # dies, can't remove nonempty dir
    $dfs->rmtree("/a");          # like rm -r

    # volumes
    $dfs->addvol(vol2 => {a => {b2 => {c => 5}}});
    $dfs->cvol("vol2");
    say $dfs->get("/a/b4/c");    # 5
    $dfs->get(":/a/b2/c");       # 2 (from volume '', our first one)
    $dfs->get("vol2:/a/b2/c");   # 5

=head1 DESCRIPTION

This module provides a Unix-filesystem-like interface to access and
modify components of nested data structure.

Highlights of this module:

=over 4

=item * Uses Moose

=item * Volumes

=item * Read/write access

=item * Mounts (to be implemented)

=back

=head1 PROPERTIES

=head2 options

Filesystem or mount options. See L<Data::Filesystem::Options>.

=head2 active_volume => STR

Records the active volume.

=head2 cwds => {VOLUME_NAME => PARRAY, ...}

Records the cwd of each volume.

=head2 refs => {VOLUME_NAME => [REF_ROOT, REF_SUB1, ...], ...}

Records the list of active nodes of each volume. Used to traverse data
from root path to cwd. Data for each volume is stored (referred to) in
the first element (REF_ROOT).

=head2 mounts => [[PATH => $dfs], ...]

XXX For future version.

=head1 METHODS

=head2 new([%args)

Create new object. Valid %arg keys:

=over 4

=item * data => $data

Optional. Supply the data.

=item * vol => $vol

Optional. Set the name of the volume. Default is '' (empty string).

If you want to add volume, see addvol().

=back

=head2 addvol($name, $data)

Add a volume.

Return $self so you can chain method calls.

=head2 rmvol($name)

Remove volume. Cannot remove active volume.

Return $self so you can chain method calls.

=head2 cwd([VOL])

Return the current working directory for a volume (or, by default, the
active volume).

=head2 cd(PATH)

Change working directory to PATH. If PATH contains volume, change
working directory for that volume, otherwise change working directory
for active volume.

Return $self, so you can chain method calls, e.g.:

 $dfs->cd("/a")->unlink("b");

=head2 cvol(STR)

Change active volume.

Return $self, so you can chain methods like this:

 $dfs->cvol("vol2")->cd("/a/b/c");

=head2 get(PATH)

Get data at PATH.

=head2 get_or_undef(PATH)

Like B<get>, but instead of dying, return undef when nonexistant path
is encountered.

=head2 set(PATH, VALUE)

Set value at PATH.

=head2 set_file(PATH, VALUE)

Like B<set>, but PATH cannot be an existing directory and VALUE cannot
be a hashref/arrayref (dir).

=head2 create_file(PATH, VALUE)

Like B<set_file>, but PATH cannot be an existing file/dir.

=head2 replace_file(PATH, VALUE)

Like B<set_file>, but PATH must be an existing existing file.

=head2 ls([PATH])

Return all entries at PATH. If PATH is not specified, defaults to
cwd. See also: B<readdir>.

=head2 readdir(PATH)

Return all entries at PATH. Basically the same as ls() except ls
accepts non-dir and optional PATH.

=head2 mkdir(PATH)

Create a directory. See also: B<mktree>.

Return $self so you can chain method calls.

=head2 mktree(PATH)

Create a directory (and intermediate directories when needed). See
also: B<mkdir>. Similar to "mkdir -p" in Unix.

Return $self so you can chain method calls.

=head2 unlink(PATH)

Remove a file.

Return $self so you can chain method calls.

=head2 rmdir(PATH)

Remove an empty directory.

Return $self so you can chain method calls.

=head2 rmtree(PATH)

Remove a file/directory tree.

Return $self so you can chain method calls.

=head2 is_file(PATH) -> BOOL

Return true if path is a file (i.e.: a leaf node), or false if
otherwise. See also: B<is_dir>.

=head2 is_dir(PATH) -> BOOL

Return true if path is a dir (i.e. a nonleaf node), or false if
otherwise. See also: B<is_file>.

=head2 is_abs_path(PATH) -> BOOL

Return true if path is absolute, or false if otherwise.

=head2 path_to_parray(PATH) -> ARRAY

Convert path string to array of path elements along with some
normalization. This is a core routine used internally when
manipulating path.

=head2 parray_to_path(PARRAY) -> PATH

Do the opposite of path_to_parray().

=head1 FAQ

=head2 What is this module good for? Why would you want to access data like a filesystem?

Because at times it's convenient, especially the access-by-path part.

This module was actually born out of overengineering of a need to
access a data structure by path.

=head2 I thought there are already several CPAN modules to do so?

Yes, and I also give a comparison of them (see L<"SEE ALSO">). But
none of them is suitable for my need, specifically the volumes
feature.

=head2 Where is grep(), wc(), head(), tail(), et al?

Data::Filesystem does not provide methods for manipulating the content
of files. If you want to treat a scalar like a file, try
L<IO::Scalar>.

=head2 Why doesn't get("a*") or unlink("a*", "b*") work? I thought wildcards are supported?

NOTE: glob() is not yet implemented.

Like in Perl, only the glob() method interpret wildcards. If you want
shell-like behaviour, you are welcome to subclass this module. So far
I haven't had the need for something like that.

=head2 I want a case-insensitive filesystem!

Tie your hash with something like L<Hash::Case>, and set the
B<new_hash_sub> option to a sub that generate similarly tied hash.

=head2 Is there support for Lufs/Fuse?

No at the moment. You are welcome to contribute :-)

=head1 TODO

=over 4

=item * mounts

Allow chaining of DFS object to another DFS object via mounting it on
a certain path, just like in Unix.

=item * glob(), find(), lstree(), ln()

=back

=head1 SEE ALSO

Modules that also provide path access to data structure:

=over 4

=item * L<Data::DPath>

More closely resembles XPath.

=item * L<Data::FetchPath>

Uses path notation like Perl:

 {bar}[2]
 {baz}{trois}

=item * L<Data::Leaf::Walker>

=item * L<Data::Path>

Uses "/ary[1]/key" syntax instead of "/ary/1/key".

Supports retrieving data from a code reference, with "/method()"
syntax.

Allows you to supply action when a wanted key does not exist, or when
an index is tried on a hash, or a key tried on an array.

Plans to support XPath "/foo[*]/bar" syntax.

=item * L<Data::Walker>

Provides an interactive CLI ("shell") interface.

Currently does not support mentioning PATH in commands (e.g. cat
"/a/b/c" or cat "../c", which I need)

=back

Modules that also provide filesystem interface to data:

=over 4

=item * DBIx::Filesystem (for database tables)

=item * Fuse::*

=back

=head1 AUTHOR

  Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

