#!/usr/bin/perl
use strict;
use warnings;
use 5.014;

package Layout;

#-------------------------------------------------
package Layout::Block;

sub print {
	my ($self) = shift;
	print $self->getValue;
}

sub getValue {
	my ($self) = shift;
	return @{$self}[0];
}

sub getTree {
	my $self = shift;
	return Tree::Simple->new($self->getValue);
}	
#-------------------------------------------------
package Layout::Stack;

sub print {
	my ($self)  = shift;
	@{$self}[0]->print;
	@{$self}[2]->print;
}

sub getValue {
	return "/";
}

sub getTree {
	my ($self) = shift;
	my $root = shift;
	my $t = Tree::Simple->new($self->getValue, $root);
	$t->addChildren( @{$self}[0]->getTree, @{$self}[2]->getTree);
	return $t;
}	

#-------------------------------------------------
package Layout::Array;

sub print {
	my ($self) = shift;
	@{$self}[0]->print;
	@{$self}[2]->print;
}

sub getValue {
	return ",";
}

sub getTree {
	my ($self) = shift;
	my $root = shift;
	my $t = Tree::Simple->new($self->getValue, $root);
	$t->addChildren( @{$self}[0]->getTree, @{$self}[2]->getTree);
	return $t;
}	

#-------------------------------------------------
package Layout::SeqArray;

sub print {
	my ($self) = shift;
	@{$self}[0]->print;
	@{$self}[2]->print;
}

sub getLimInf {
	my ($self) = shift;
	return @{$self}[0]->getValue =~ /(\d+)/;
}

sub getLimSup {
	my ($self) = shift;
	return @{$self}[2]->getValue =~ /(\d+)/;
}

sub getValue {
	return ",";
}

sub getTree {
	my ($self) = shift;
	my $root = shift;
	my $t = Tree::Simple->new($self->getValue, $root);
	my ($inf, $sup) = ($self->getLimInf, $self->getLimSup);
	my $i;
	for($i = $inf; $i <= $sup; $i++) {
		$t->addChild(Tree::Simple->new(sprintf("H%d", $i)));
	}
	return $t;
}	

#-------------------------------------------------
package main;
use Marpa::R2;
use Tree::Simple;

my $syntax = <<'SYNTAX_END';
:default ::= action => ::array
:start ::= Layout
Layout ::= 
	  ('(') Layout (')') 	action => ::first
	| Block  		bless => Block
	| Layout '..' Layout 	bless => SeqArray 
	| Layout ',' Layout 	bless => Array
	| Layout '/' Layout 	bless => Stack
Block ~ [[:alpha:]] <zero or more digits>
<zero or more digits> ~ [\d]*
:discard ~ whitespace
:discard ~ parens
parens ~ [\(\)]
whitespace ~ [\s]+
SYNTAX_END

my $grammar = Marpa::R2::Scanless::G->new({ 
	bless_package => 'Layout', 
	source => \$syntax 
});

# lenguaje [<link>;]+ <diagrama>
my @input = split(";",$ARGV[0]);
my $diagram = pop @input;

my $links = {};
my $coords;

# resolver el diagrama
my $ast = bnf2ast($diagram);
my $t = $ast->getTree(Tree::Simple->new("root"));
propUp($t);

# completar con enlaces
foreach my $link (@input) {
	if($link =~ /([HBNSR]\d+)-([HBNSR])(\d+)..[HBNSR](\d+)/) {
		for(my $i = $3; $i <= $4; $i++) {
			setlink($1, $2.$i);
		}
	} else {
		if($link =~ /([HBNSR]\d+)-([HBNSR]\d+)/) {
			setlink($1,$2);
		}
	}
}

use GD::Simple;
my $img; 
$img = draw($t);

print $img->png;


sub setlink {
	my ($n1, $n2) = @_;
	push @{$links->{$n1}}, $n2;
}
	
sub bnf2ast {
	my ($bnf) = @_;
	my $recce = Marpa::R2::Scanless::R->new( { grammar => $grammar } );
	$recce->read( \$bnf );
	my $value_ref = $recce->value();
	if ( not defined $value_ref ) {
		die "No parse for $bnf";
	}
	return ${$value_ref};
}




sub max {
	my ($x, $y) = @_;
	return $y if(!defined($x));
	return $x if(!defined($y));
	return ($x > $y) ? $x : $y;
}

use GD::Image;

my $imgmap = 0; 
sub imginit {
	$imgmap = {
		H => GD::Image->new('host-frame.gif'),
		R => GD::Image->new('router-frame.gif'),
		S => GD::Image->new('switch-frame.gif'),
	};
}

sub imgget {
	my $value = shift;
	imginit unless $imgmap;
	return $imgmap->{substr($value,0,1)};
}

sub propUp {
	my ($t) = @_;

	if($t->isLeaf) {
		$t->{img} = imgget($t->getNodeValue);
		$t->{blkwidth} = $t->{img}->width;
		$t->{blkheight} = $t->{img}->height;
	} else {
		foreach my $c ($t->getAllChildren) { 
			propUp($c); 
			if($t->getNodeValue eq '/') {
				$t->{blkheight} += $c->{blkheight};
				$t->{blkwidth} = max($t->{blkwidth}, $c->{blkwidth});
			}
			if($t->getNodeValue eq ',') {
				$t->{blkwidth} += $c->{blkwidth};
				$t->{blkheight} = max($t->{blkheight}, $c->{blkheight});
			}
		}
	}
}

sub draw {
	my ($t) = @_;

	use GD::Simple;
	$img =  GD::Simple->new($t->{blkwidth},$t->{blkheight});
	#$img->transparent($img->colorAllocate(4,130,4));
	$img->transparent($img->colorAllocate(255,255,255));
	$img->interlaced('true');
	$img->fgcolor(170,170,180);
	$img->penSize(5);
	makeCoords($t,$img,0,0);
	lines2img($t,$img);
	nodes2img($t, $img);
	$img->font("Helvetica:Bold");
	$img->fontsize(18);
	$img->fgcolor(0,0,0);
	labels2img($t,$img);
	return $img;
}

sub makeCoords {
	my ($t, $img, $x, $y) = @_;

	if($t->isLeaf) {
		my ($w, $h) = ($t->{img}->width, $t->{img}->height);
		$coords->{$t->getNodeValue} = [$x + $w/2, $y + $h/2];
	} else {
		my ($w, $h) = (0,0);
		foreach my $c ($t->getAllChildren) {
			if($t->getNodeValue eq '/') {
				$w = ($t->{blkwidth} - $c->{blkwidth})/2;
				makeCoords($c, $img, $x + $w, $y + $h);
				$h += $c->{blkheight};
			}
			if($t->getNodeValue eq ',') {
				$h = ($t->{blkheight} - $c->{blkheight})/2;
				makeCoords($c, $img, $x + $w, $y + $h);
				$w += $c->{blkwidth};
			}
		}
	}
}

sub lines2img {
	my ($t, $img) = @_;

	if($t->isLeaf) {
		my $n = $t->getNodeValue;
		my ($x, $y) = @{$coords->{$n}};
		foreach my $n1 (@{$links->{$n}}) {	
			my ($x1, $y1) = @{$coords->{$n1}};
			$img->line($x, $y, $x1, $y1);
		}
	} else {
		foreach my $c ($t->getAllChildren) {
			lines2img($c, $img);
		}
	}
}

		
sub nodes2img {
	my ($t, $img) = @_;

	if($t->isLeaf) {
		my ($x, $y) = @{$coords->{$t->getNodeValue}};
		my ($w, $h) = ($t->{img}->width,$t->{img}->height);
		$img->copy($t->{img}, $x - $w/2, $y - $h/2, 0, 0, $w, $h);
	} else {
		foreach my $c ($t->getAllChildren) {
				nodes2img($c, $img);
		}
	}
}

sub labels2img {
	my ($t, $img) = @_;
	
	if($t->isLeaf) {
		my ($x, $y) = @{$coords->{$t->getNodeValue}};
		my ($w, $h) = ($t->{img}->width,$t->{img}->height);
		$img->moveTo($x - 24, $y + 40);
		$img->string($t->getNodeValue);
	} else {
		foreach my $c ($t->getAllChildren) {
				labels2img($c, $img);
		}
	}
}
		
