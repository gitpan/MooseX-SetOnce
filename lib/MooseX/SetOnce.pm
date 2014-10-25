use strict;
use warnings;
package MooseX::SetOnce;
BEGIN {
  $MooseX::SetOnce::VERSION = '0.100473';
}
# ABSTRACT: write-once, read-many attributes for Moose


package MooseX::SetOnce::Attribute;
BEGIN {
  $MooseX::SetOnce::Attribute::VERSION = '0.100473';
}
use Moose::Role 0.90;

before set_value => sub { $_[0]->_ensure_unset($_[1]) };

around _inline_set_value => sub {
    my ( $orig, $self, @args ) = @_;
    my (@lines) = $self->$orig(@args);
    unshift @lines, sprintf q{$_[0]->meta->get_attribute("%s")->_ensure_unset($_[0]);}, quotemeta( $self->name );
    return @lines;
} if $Moose::VERSION >= 1.9900;

sub _ensure_unset {
  my ($self, $instance) = @_;
  Carp::confess("cannot change value of SetOnce attribute " . $self->name)
    if $self->has_value($instance);
}

around accessor_metaclass => sub {
  my ($orig, $self, @rest) = @_;

  return Moose::Meta::Class->create_anon_class(
    superclasses => [ $self->$orig(@_) ],
    roles => [ 'MooseX::SetOnce::Accessor' ],
    cache => 1
  )->name
} if $Moose::VERSION < 1.9900;

package MooseX::SetOnce::Accessor;
BEGIN {
  $MooseX::SetOnce::Accessor::VERSION = '0.100473';
}
use Moose::Role 0.90;

around _inline_store => sub {
  my ($orig, $self, $instance, $value) = @_;

  my $code = $self->$orig($instance, $value);
  $code = sprintf qq[%s->meta->get_attribute("%s")->_ensure_unset(%s);\n%s],
    $instance,
    quotemeta($self->associated_attribute->name),
    $instance,
    $code;

  return $code;
};

package Moose::Meta::Attribute::Custom::Trait::SetOnce;
BEGIN {
  $Moose::Meta::Attribute::Custom::Trait::SetOnce::VERSION = '0.100473';
}
sub register_implementation { 'MooseX::SetOnce::Attribute' }

1;

__END__
=pod

=head1 NAME

MooseX::SetOnce - write-once, read-many attributes for Moose

=head1 VERSION

version 0.100473

=head1 SYNOPSIS

Add the "SetOnce" trait to attributes:

  package Class;
  use Moose;
  use MooseX::SetOnce;

  has some_attr => (
    is     => 'rw',
    traits => [ qw(SetOnce) ],
  );

...and then you can only set them once:

  my $object = Class->new;

  $object->some_attr(10);  # works fine
  $object->some_attr(20);  # throws an exception: it's already set!

=head1 DESCRIPTION

The 'SetOnce' attribute lets your class have attributes that are not lazy and
not set, but that cannot be altered once set.

The logic is very simple:  if you try to alter the value of an attribute with
the SetOnce trait, either by accessor or writer, and the attribute has a value,
it will throw an exception.

If the attribute has a clearer, you may clear the attribute and set it again.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

