
#
# automatically generate man pages from MANIFEST
# (if it looks like a .pm file)
#
open(MANIFEST, "< MANFIEST");
my $pods;
while (<MANIFEST>) {
    chomp;
    if (m/^lib\/(.+)\.pm$/) {
	my $mod = $1;
	$mod =~ s/\//::/g;
	$pods->{$_} = '$(INST_MAN3DIR/)' . $mod . '$(MAN3EXT)';
    }
}
close MANIFEST;

use ExtUtils::MakeMaker;

WriteMakefile(
              'VERSION' => '0.1.0',
              'NAME' => 'clamdr',
              'EXE_FILES' => [qw(
				 bin/readDR.pl
				 bin/writeDR.pl
				)],
              'MAN3PODS'       => $pods,
              'PREREQ_PM' => {
			      DBD::CSV,
                             },
              'INSTALLHTMLSITELIBDIR' => '~/public_html',
             );
