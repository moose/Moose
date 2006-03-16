#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok('Moose');
}

=pod

This test demonstrates how simple it is to create Scala Style 
Class Mixin Composition. Below is an example taken from the 
Scala web site's example section, and trancoded to Class::MOP.

NOTE:
We require SUPER for this test to handle the issue with SUPER::
being determined at compile time. 

L<http://scala.epfl.ch/intro/mixin.html>

A class can only be used as a mixin in the definition of another 
class, if this other class extends a subclass of the superclass 
of the mixin. Since ColoredPoint3D extends Point3D and Point3D 
extends Point2D which is the superclass of ColoredPoint2D, the 
code above is well-formed.

  class Point2D(xc: Int, yc: Int) {
    val x = xc;
    val y = yc;
    override def toString() = "x = " + x + ", y = " + y;
  }
  
  class ColoredPoint2D(u: Int, v: Int, c: String) extends Point2D(u, v) {
    val color = c;
    def setColor(newCol: String): Unit = color = newCol;
    override def toString() = super.toString() + ", col = " + color;
  }
  
  class Point3D(xc: Int, yc: Int, zc: Int) extends Point2D(xc, yc) {
    val z = zc;
    override def toString() = super.toString() + ", z = " + z;
  }
  
  class ColoredPoint3D(xc: Int, yc: Int, zc: Int, col: String)
        extends Point3D(xc, yc, zc)
        with ColoredPoint2D(xc, yc, col);
        
  
  Console.println(new ColoredPoint3D(1, 2, 3, "blue").toString())
        
  "x = 1, y = 2, z = 3, col = blue"
  
=cut

{
    package Point2D;
    use metaclass;
    
    Point2D->meta->add_attribute('$x' => (
        accessor => 'x',
        init_arg => 'x',
    ));
    
    Point2D->meta->add_attribute('$y' => (
        accessor => 'y',
        init_arg => 'y',
    ));    
    
    sub new {
        my $class = shift;
        $class->meta->new_object(@_);
    }    
    
    sub toString {
        my $self = shift;
        "x = " . $self->x . ", y = " . $self->y;
    }
    
    package ColoredPoint2D;
    our @ISA = ('Point2D');
    
    ColoredPoint2D->meta->add_attribute('$color' => (
        accessor => 'color',
        init_arg => 'color',
    ));    
    
    sub toString {
        my $self = shift;
        $self->SUPER() . ', col = ' . $self->color;
    }
    
    package Point3D;
    our @ISA = ('Point2D');
    
    Point3D->meta->add_attribute('$z' => (
        accessor => 'z',
        init_arg => 'z',
    ));        

    sub toString {
        my $self = shift;
        $self->SUPER() . ', z = ' . $self->z;
    }
    
    package ColoredPoint3D;
    our @ISA = ('Point3D');    
    
    ::with('ColoredPoint2D');
    
}

my $colored_point_3d = ColoredPoint3D->new(x => 1, y => 2, z => 3, color => 'blue');
isa_ok($colored_point_3d, 'ColoredPoint3D');
isa_ok($colored_point_3d, 'Point3D');
isa_ok($colored_point_3d, 'Point2D');

is($colored_point_3d->toString(),
   'x = 1, y = 2, z = 3, col = blue',
   '... got the right toString method');

