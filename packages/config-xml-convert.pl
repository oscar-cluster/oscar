#!/usr/bin/env perl

use strict;

my $prefix = "oscar-config";

foreach (@ARGV) {
    convert($_);
}

exit(0);

sub replace {
    my ($content, $str) = @_;

    $$content =~ s/\<$str\>/<$prefix:$str>/g;
    $$content =~ s/\<\/$str\>/<\/$prefix:$str>/g;
}

sub convert {
    my ($file) = @_;

    print "Processing file: $file\n";

    open(IN, $file) || die "can't open file: $file";
    my $content;
    while (<IN>) {
        $content .= $_;
    }
    close IN;

    replace(\$content, "oscar");
    replace(\$content, "name");
    replace(\$content, "version");
    replace(\$content, "major");
    replace(\$content, "minor");
    replace(\$content, "release");
    replace(\$content, "subversion");
    replace(\$content, "epoch");

    replace(\$content, "class");
    replace(\$content, "summary");
    replace(\$content, "license");
    replace(\$content, "copyright");
    replace(\$content, "group");
    replace(\$content, "packager");
    replace(\$content, "maintainer");
    replace(\$content, "vendor");
    replace(\$content, "email");
    replace(\$content, "description");
    replace(\$content, "provides");
    replace(\$content, "requires");
    replace(\$content, "conflicts");
    replace(\$content, "servicelist");
    replace(\$content, "download");
    replace(\$content, "oda");

    $content =~ s/\<url\>/<uri>/g;
    $content =~ s/\<\/url\>/<\/uri>/g;
    replace(\$content, "uri");

    $content =~ s/\<rpmlist\>/<binary-package-list>/g;
    $content =~ s/\<\/rpmlist\>/<\/binary-package-list>/g;
    $content =~ s/\<rpm\>/<pkg>/g;
    $content =~ s/\<\/rpm\>/<\/pkg>/g;
    replace(\$content, "binary-package-list");
    replace(\$content, "pkg");

    $content =~ s/\<package\>/<package-specific-attributes>/g;
    $content =~ s/\<\/package\>/<\/package-specific-attributes>/g;
    replace(\$content, "package-specific-attributes");

    $content =~ s/\<\!DOCTYPE(.+?)>\n//;

    my $str = "
  xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
  xmlns:oscar-config=\"http://sf.net/oscar/2005/config.xml\"
  xsi:schemaLocation=\"http://sf.net/oscar/2005/config.xml oscar-config.xsd\"
>";

    $content =~ s/oscar-config:oscar>/oscar-config:oscar $str/;

    my $changed = 0;
    do {
        if ($content =~ m/([ \t]+)(\<filter.+?\>)/o) {
            my $indent = $1;
            my $block = $2;

            # Convert the block
            my $str = "<$prefix:filter>\n";
            if ($block =~ m/group=[\"\'](.+?)[\"\']/) {
                $str .= "$indent  <$prefix:group>$1</$prefix:group>\n";
            }
            if ($block =~ m/architecture=[\"\'](.+?)[\"\']/) {
                $str .= "$indent  <$prefix:architecture>$1</$prefix:architecture>\n";
            }
            if ($block =~ m/distribution=[\"\'](.+?)[\"\']/) {
                $str .= "$indent  <$prefix:distribution>
$indent    <$prefix:name>$1</$prefix:name>\n";
                if ($block =~ m/distribution_version=[\"\'](.+?)[\"\']/) {
                    $str .= "$indent    <$prefix:version>$1</$prefix:version>\n";
                }
                $str .= "$indent  </$prefix:distribution>\n";
            }

            $str .= "$indent</$prefix:filter>\n";

            # Now substitute the block back in
            $content =~ s/<filter.+?>/$str/o;
            $changed = 1;
        } else {
            $changed = 0;
        }
    } while ($changed);

    open(OUT, ">$file") || die("can't open output file");
    print OUT $content;
    close OUT;
}
