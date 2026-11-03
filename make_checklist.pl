#!/usr/bin/perl
#
# make_checklist.pl - convert a CSV checklist file into a LaTeX document
# that uses checklist.cls (two-column checklist pages).
#
# Usage:
#   make_checklist.pl [options] [input.csv]  > out.tex
#   make_checklist.pl -o out.tex input.csv
#
# Options:
#   -o, --output FILE   write to FILE instead of stdout
#   --landscape         landscape pages
#   --a4                A4 paper (default is US letter)
#   -h, --help          show this help
#
# Input is CSV with three columns: type,text,response
# A header row is optional. Fields containing commas, quotes or newlines
# must be double-quoted ("" for a literal quote). Blank rows are ignored,
# and so are rows whose type starts with '#'.
#
#   type        text                      response
#   title       Cessna 172 Checklist      (document title)
#   subtitle    Normal procedures         (shown at right of page header)
#   revision    Rev 3                     (shown in page footer)
#   section     Preflight - Cabin         (shaded section heading)
#   item        Master switch             ON   (checkbox, dot leader, response)
#   note        Verify fuel on both tanks (indented italic note)
#   colbreak                              (start a new column)
#   pagebreak                             (start a new page)
#
# An empty type means "item"; an item with an empty response is a plain
# checkbox line. Text is escaped for LaTeX, so & % $ # _ are safe.

use strict;
use warnings;
use Getopt::Long qw(GetOptions);

my ($output, $landscape, $a4, $help);
GetOptions(
    'o|output=s' => \$output,
    'landscape'  => \$landscape,
    'a4'         => \$a4,
    'h|help'     => \$help,
) or usage(2);
usage(0) if $help;

sub usage {
    my ($status) = @_;
    open my $self, '<', $0 or exit $status;
    my $fh = $status ? *STDERR : *STDOUT;
    while (<$self>) {
        next if $. == 1;
        last unless /^#/;
        s/^# ?//;
        print {$fh} $_;
    }
    exit $status;
}

# Parse RFC 4180 CSV text into a list of [ line_number, @fields ] records.
sub parse_csv {
    my ($text) = @_;
    $text =~ s/^\x{FEFF}|^\xEF\xBB\xBF//;    # strip a UTF-8 BOM
    my (@records, @fields);
    my ($field, $in_quotes, $quoted, $line, $start) = ('', 0, 0, 1, 1);
    my @c = split //, $text;

    my $end_field = sub { push @fields, $field; $field = ''; $quoted = 0 };
    my $end_record = sub {
        $end_field->();
        push @records, [ $start, @fields ];
        @fields = ();
    };

    for (my $i = 0; $i < @c; $i++) {
        my $ch = $c[$i];
        if ($in_quotes) {
            if ($ch eq '"') {
                if (($c[$i + 1] // '') eq '"') { $field .= '"'; $i++ }
                else                           { $in_quotes = 0 }
            } else {
                $line++ if $ch eq "\n";
                $field .= $ch;
            }
        }
        elsif ($ch eq '"' && $field eq '' && !$quoted) {
            $in_quotes = $quoted = 1;
        }
        elsif ($ch eq ',') {
            $end_field->();
        }
        elsif ($ch eq "\r" || $ch eq "\n") {
            $i++ if $ch eq "\r" && ($c[$i + 1] // '') eq "\n";
            $end_record->();
            $start = ++$line;
        }
        else {
            $field .= $ch;
        }
    }
    die "Unterminated quoted field starting on line $start\n" if $in_quotes;
    $end_record->() if length $field || @fields || $quoted;
    return @records;
}

sub tex_escape {
    my ($s) = @_;
    my %map = (
        '\\' => '\textbackslash{}', '&' => '\&',  '%' => '\%',
        '$'  => '\$',               '#' => '\#',  '_' => '\_',
        '{'  => '\{',               '}' => '\}',
        '~'  => '\textasciitilde{}', '^' => '\textasciicircum{}',
    );
    $s =~ s/([\\&%\$#_{}~^])/$map{$1}/g;
    return $s;
}

sub trim { my ($s) = @_; $s //= ''; $s =~ s/^\s+|\s+$//g; return $s }

my $input = do { local $/; <> };
$input = '' unless defined $input;

my %meta = (title => 'Checklist', subtitle => '', revision => '');
my @body;
my $first = 1;

for my $rec (parse_csv($input)) {
    my ($lineno, @fields) = @$rec;
    # Short rows (missing trailing commas) get empty trailing columns.
    my ($type, $text, $response) = map { trim($fields[$_]) } 0 .. 2;
    next if $type eq '' && $text eq '' && $response eq '';   # blank row
    next if $type =~ /^#/;

    # Skip an optional header row.
    if ($first) {
        $first = 0;
        next if lc $type eq 'type';
    }

    $type = lc $type;
    $type = 'item' if $type eq '';

    if ($type =~ /^(title|subtitle|revision)$/) {
        $meta{$type} = $text;
    }
    elsif ($type eq 'section') {
        push @body, '\checksection{' . tex_escape($text) . '}';
    }
    elsif ($type eq 'item') {
        die "Line $lineno: item has no text\n" if $text eq '';
        push @body, '\checkitem{' . tex_escape($text) . '}{'
                  . tex_escape($response) . '}';
    }
    elsif ($type eq 'note') {
        push @body, '\checknote{' . tex_escape($text) . '}';
    }
    elsif ($type eq 'colbreak') {
        push @body, '\checkcolumnbreak';
    }
    elsif ($type eq 'pagebreak') {
        push @body, '\checkpagebreak';
    }
    else {
        die "Line $lineno: unknown row type '$type'\n";
    }
}

my @opts = ($a4 ? 'a4paper' : 'letterpaper');
push @opts, 'landscape' if $landscape;

my $out = \*STDOUT;
if (defined $output) {
    open $out, '>', $output or die "Cannot write $output: $!\n";
}

print {$out} '\documentclass[', join(',', @opts), "]{checklist}\n\n";
print {$out} '\title{', tex_escape($meta{title}), "}\n";
print {$out} '\checklistsubtitle{', tex_escape($meta{subtitle}), "}\n";
print {$out} '\checklistrevision{', tex_escape($meta{revision}), "}\n\n";
print {$out} "\\begin{document}\n\\begin{checklist}\n\n";
print {$out} "$_\n" for @body;
print {$out} "\n\\end{checklist}\n\\end{document}\n";

close $out if defined $output;
