#!/usr/bin/env bash
set -euo pipefail

# Reproducible Task 6 audit. It intentionally does not invoke Git. The
# unchanged-file manifests are captured from the committed JJ revision named
# in task-6-baseline.txt and are treated as immutable audit inputs.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
SNAPSHOTS="$SCRIPT_DIR/snapshots"
cd "$ROOT"

perl - "$ROOT" "$SNAPSHOTS" <<'PERL'
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Find;

my ($root, $snapshots) = @ARGV;

sub chunks {
  my ($text) = @_;
  my @out;
  pos($text) = 0;
  while ($text =~ /(?m)^  (den\.aspects\.[^=\n]+?)\s*=/g) {
    my $path = $1;
    $path =~ s/\s+\z//;
    my $start = $-[0];
    my $i = $+[0];
    my ($brace, $paren, $bracket) = (0, 0, 0);
    my ($double, $multi, $comment) = (0, 0, 0);
    my $end;
    for (; $i < length($text); $i++) {
      my $c = substr($text, $i, 1);
      my $n = ($i + 1 < length($text)) ? substr($text, $i + 1, 1) : '';
      if ($comment) {
        $comment = 0 if $c eq "\n";
        next;
      }
      if ($multi) {
        if ($c eq "'" && $n eq "'") { $multi = 0; $i++; }
        next;
      }
      if ($double) {
        if ($c eq "\\") { $i++; next; }
        $double = 0 if $c eq '"';
        next;
      }
      if ($c eq '#') { $comment = 1; next; }
      if ($c eq "'" && $n eq "'") { $multi = 1; $i++; next; }
      if ($c eq '"') { $double = 1; next; }
      $brace++ if $c eq '{';
      $brace-- if $c eq '}';
      $paren++ if $c eq '(';
      $paren-- if $c eq ')';
      $bracket++ if $c eq '[';
      $bracket-- if $c eq ']';
      if ($c eq ';' && $brace == 0 && $paren == 0 && $bracket == 0) {
        $end = $i + 1;
        last;
      }
    }
    die "no assignment terminator for $path\n" unless defined $end;
    push @out, [$path, substr($text, $start, $end - $start)];
    pos($text) = $end;
  }
  return @out;
}

sub read_file {
  my ($path) = @_;
  open my $fh, '<', $path or die "$path: $!";
  local $/;
  return <$fh>;
}

my %current;
find({
  wanted => sub {
    return unless /\.nix\z/ && -f $_;
    my $path = $File::Find::name;
    my $text = read_file($path);
    for my $pair (chunks($text)) {
      my $display = $path;
      $display =~ s/^\Q$root\E\///;
      die "duplicate current assignment $pair->[0]\n" if exists $current{$pair->[0]};
      $current{$pair->[0]} = [$display, $pair->[1]];
    }
  },
  no_chdir => 1,
}, "$root/modules");

my ($total, $passed, $failed, $missing) = (0, 0, 0, 0);
my @snapshot_files;
find({
  wanted => sub {
    push @snapshot_files, $File::Find::name if /\.nix\z/ && -f $_;
  },
  no_chdir => 1,
}, $snapshots);
for my $path (sort @snapshot_files) {
  next unless $path =~ m{/snapshots/task-[2345]-before-[^/]+/};
  my $source = read_file($path);
  for my $pair (chunks($source)) {
    my ($name, $old) = @$pair;
    $total++;
    if (!exists $current{$name}) {
      print "MISSING $name (source $path)\n";
      $missing++;
      next;
    }
    my ($newpath, $new) = @{$current{$name}};
    my $source_display = $path;
    $source_display =~ s/^\Q$root\E\///;
    if ($old eq $new) {
      print "PASS $name $source_display $newpath\n";
      $passed++;
    } else {
      print "MISMATCH $name $source_display $newpath old=" . sha256_hex($old) .
        " new=" . sha256_hex($new) . "\n";
      $failed++;
    }
  }
}
print "SUMMARY total=$total passed=$passed failed=$failed missing=$missing\n";
die "assignment audit failed\n" if $failed || $missing;

sub verify_manifest {
  my ($label, $manifest, $is_in_scope) = @_;
  open my $fh, '<', $manifest or die "$manifest: $!";
  my %expected;
  my ($matches, $mismatches, $deleted, $new) = (0, 0, 0, 0);
  while (my $line = <$fh>) {
    chomp $line;
    next if $line eq '' || $line =~ /^#/;
    my ($path, $hash) = split /\t/, $line, 2;
    die "bad manifest line: $line\n" unless defined $hash;
    $expected{$path} = $hash;
    if (!-f $path) {
      print "DELETED $path\n";
      $deleted++;
      next;
    }
    my $current_hash = sha256_hex(read_file($path));
    if ($current_hash eq $hash) {
      $matches++;
    } else {
      print "MISMATCH $path baseline=$hash current=$current_hash\n";
      $mismatches++;
    }
  }
  close $fh;
  find({
    wanted => sub {
      return unless -f $_;
      my $path = $File::Find::name;
      $path =~ s/^\Q$root\E\///;
      return unless $is_in_scope->($path);
      if (!exists $expected{$path}) {
        print "NEW $path\n";
        $new++;
      }
    },
    no_chdir => 1,
  }, $root);
  print "SUMMARY $label" .
    "_baseline_matches=$matches mismatches=$mismatches deleted=$deleted new=$new\n";
  die "$label manifest audit failed\n" if $mismatches || $deleted || $new;
}

verify_manifest(
  'unchanged_scope',
  "$snapshots/../task-6-unchanged-scope-baseline.manifest",
  sub {
    my ($path) = @_;
    return $path =~ m{^(?:dots|secrets|scripts)/} ||
      $path =~ m{^modules/(?:desktop|disko|hosts|secrets|users)/} ||
      $path =~ m{^(?:nix|lib)/};
  },
);

verify_manifest(
  'modules_outside_migrated_categories',
  "$snapshots/../task-6-modules-outside-baseline.manifest",
  sub {
    my ($path) = @_;
    return $path =~ m{^modules/} &&
      $path !~ m{^modules/(?:apps|services|shell|system)/};
  },
);
PERL
