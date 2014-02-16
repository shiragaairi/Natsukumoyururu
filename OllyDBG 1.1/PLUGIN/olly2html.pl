#!/usr/bin/perl

## olly2html.pl
##
## Creates HTML pages from ASM generated by Ollydbg "Copy->File" function.
## Version: 0.1
##
## Features:
## Automatically determines ASM file column widths
## Writes separate pages for each subroutine plus master index
## Uses subroutine start comment as name if > 3 chars and no spaces
## Writes navigation header
## References to other locations/labels in same module hyperlinked
##
## Tip: If you label and comment the start of every subroutine with your
## guessed subroutine name, olly2html.pl will use the comment as the 
## subroutine name instead of the starting offset.
##
## Usage: olly2html.pl <path to ollydbg ASM dump>
##
## (c)2004 Joe Stewart <joe@joestewart.org>

use strict;

my ($analysiscol, $commandcol, $commentcol, $prev);
my (@hashes, @subs, @subnames);
my %comments;
my $file = $ARGV[0];
my $filecount = 0;
my $version = "0.1";
my $module;

die "Usage: $0 <ollydbg-dumped asm file>\n" unless $file;

my $path = $file;
$path =~ s/\..*//;
$path .= "-html";
unless (-e $path) {
  mkdir($path) or die "Couldn't create output dir $path : $!\n";
}
my $tmp = "$file\.tmp";

print "Scanning to find column offsets\n";
open (IN, $file) or die "Couldn't open $file for read : $!\n";
open (OUT, ">$tmp") or die "Couldn't open $tmp for write : $!\n";
while (<IN>) {
  my $hex;
  chomp(my $line = $_);
  $line =~ s/[\x00-\x19]//g;
  $line =~ s/[\x7F-\xFF]//g;
  if ($line !~ /^[0-9A-F]+ /) { 
    $prev .= "\\n$line";
    next;
  } else {
    print OUT "$prev\n";
    $prev = $line;
  }
  my @chars = split(//, $line);
  for (0..$#chars) {
    ${$hashes[$_]}{$chars[$_]} = 1;
  }
}
$prev =~ s/\\n$//;
$prev =~ s/\\n$//;
print OUT "$prev\n";
close IN;
close OUT;

my @charsfoundincol;
for (0..256) {   
  $charsfoundincol[$_] = join("", sort keys %{$hashes[$_]});
  if ($charsfoundincol[$_] eq ";") { $commentcol = $_ }
  elsif (($charsfoundincol[$_] =~ /[A-Z]/) && 
	 ($charsfoundincol[$_] =~ /[^A-F0-9: ]/)) { $commandcol ||= $_ }
}
print "Address at column: 0\nAnalysis at column: 9\n";
print "Command at column: $commandcol\nComment at column: $commentcol\n";

print "Scanning for subroutines\n";

open (IN, "$tmp") or die "Couldn't open $tmp for read : $!\n";
my $first = 0;
while (<IN>) {
  chomp(my $line = $_);
  next unless $line =~ /[A-F0-9]{8}/;
  my $address = substr($line,0,8);
  my $analysis = substr($line,9,3);
  my $command = substr($line,$commandcol,$commentcol-$commandcol);
  my $comment = substr($line,$commentcol+3);
  if ($command =~ /([a-zA-Z-_.]*)\.[0-9A-F]{8}/) {
	$module ||= $1;
  }

  if ( (($analysis =~ /\$|>\/\./) && ($command !~ /^JMP/))
    || (!$first)) { push (@subs, $address); $first = 1; }
  if (($comment !~ / /) && ($comment =~ /[A-Za-z0-9]/) && 
     (length($comment) > 3)) { 
    $comments{$address} = $comment;
  }
}
close IN;

for (@subs) { 
  if ($comments{$_}) {
    push (@subnames, $comments{$_});
  } else {
    push (@subnames, "sub_$_");
  }
}

print "Module name: $module\n";
open (IN, "$tmp") or die "Couldn't open $tmp for read : $!\n";
while (<IN>) {
  chomp(my $line = $_);
  my $address = substr($line,0,8);
  my $analysis = substr($line,9,3);
  my $command = substr($line,$commandcol,$commentcol-$commandcol);
  my $comment = substr($line,$commentcol);
  $command =~ s/\&/\&amp\;/g;
  $command =~ s/>/\&gt\;/g;
  $command =~ s/</\&lt\;/g;
  $comment =~ s/\&/\&amp\;/g;
  $comment =~ s/>/\&gt\;/g;
  $comment =~ s/</\&lt\;/g;
  if (grep { /^$address$/ } @subs) {
    if (OUT) {
      print OUT htmlFooter();
      close OUT;
    }
    my $progress = ($filecount / scalar(@subs)) * 100;
    $filecount++;
    printf "Writing %s (%.2f%% done)\n", "$path/sub_$address\.html", $progress;
    open(OUT, ">$path/sub_$address\.html") 
      or die "Couldn't open $path/sub_$address\.html for write : $!\n";
    print OUT htmlHeader($address);
  }
  print OUT "<a class=\"name\" name=\"$address\">$address</a> $analysis ";
  if ($command =~ /$module\.([0-9A-F]{8})/) {
    my $t = $1;
    my $dest = addrToSub($t);
    my $mt = "$module\.$t";
    if ($dest) { 
      $command =~ s/$mt/<a href=\"sub_$dest\.html#$t\">$mt<\/a>/g;
    }
  } elsif ($command =~ /([0-9A-F]{8})/) {
    my $t = $1;
    my $dest = addrToSub($t);
    if ($dest) { $command =~ s/$t/<a href=\"sub_$dest\.html#$t\">$t<\/a>/g }
  }
  if ($command =~ /(CALL|PUSH) \&lt/) {
    for my $addr (keys %comments) {
      my $ca = "$module\.$comments{$addr}";
      if ($command =~ /\Q&lt;$ca&gt;\E/) {
        my $dest = addrToSub($addr);
        if ($dest) { 
          $command =~ s/$ca/<a href=\"sub_$dest\.html#$addr\">$ca<\/a>/g;
        }
      }
    }
  }
  print OUT "$command $comment\n";
}
close IN;
close OUT;
&writeIndex;
unlink $tmp;

sub addrToSub {
  my $target = hex(shift);
  my ($last, $dest);
  for (@subs) {
    if ($target < hex($_)) { $dest = $last; last; }
    $last = $_;
  }
  return $dest;
}

sub htmlHeader {
  my ($prev, $cur, $next, $aprev, $anext);
  if ($filecount > 1) {
    $prev = $subnames[$filecount - 2];
    $cur = $subnames[$filecount - 1];
    $next = $subnames[$filecount];
    $aprev = $subs[$filecount - 2];
    $anext = $subs[$filecount];
  } elsif ($filecount == 1) {
     $cur = $subnames[$filecount - 1];
     $next = $subnames[$filecount];
     $anext = $subs[$filecount];
  } else {
     $cur = "index";
     $next = $subnames[0];
     $anext = $subs[0];
  }
  my $r = qq~
<!-- Converted to HTML using olly2html.pl $version by Joe Stewart -->
<html>
<head>
<title>$module\.$cur</title>
<style>
A {
        text-decoration: none;
        font-size: 10pt;
        color: blue;
        background: transparent; }
A.name {
        text-decoration: none;
        font-size: 10pt;
        color: black;
        background: transparent; }
BODY,BR {
        font-size: 10pt; }
PRE {
        font-family: courier new, courier;
        font-size: 10pt; }
</style>
</head>
<body bgcolor="#FFFFFF">
~;
  $r .= "Back to <a href=\"index.html\">Index</a><br>\n" if $filecount != 0;
  $r .= "Previous: <a href=\"sub_$aprev\.html\">$prev</a><br>\n" if $prev;
  $r .= "Next: <a href=\"sub_$anext\.html\">$next</a><br>\n" if $next;
  $r .= "<h1>$module\.$cur</h1><pre>";
  return $r;
}

sub htmlFooter {
  return qq~
</pre>
Converted to HTML using
<a href="http://www.joestewart.org/tools/olly2html.pl">olly2html.pl 
$version</a> by <a href="http://www.joestewart.org/">Joe Stewart</a>
</body>
</html>
~;
}

sub writeIndex {
  print "Writing index\n";
  open(IDX, ">$path/index.html")
    or die "Couldn't open $path/index.html for write : $!\n";
  $filecount = 0;
  print IDX htmlHeader();
  for (0..$#subs) {
    my $a = $subs[$_];
    my $n = $subnames[$_];
    print IDX "<a href=\"sub_$a\.html\">$n</a>\n";
  }
  print IDX htmlFooter();
  close IDX;
}
