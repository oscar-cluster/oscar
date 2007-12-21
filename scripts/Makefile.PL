use ExtUtils::MakeMaker;
use Carp;

WriteMakefile(
		'NAME' => 'OSCAR_scripts',
		'MAN1PODS' => {
			'setup_pxe' => '$(INST_MAN1DIR)/setup_pxe.$(MAN1EXT)',
			'oscar-config' => '$(INST_MAN1DIR)/oscar-config.$(MAN1EXT)',
			'install_prereq' => '$(INST_MAN1DIR)/install_prereq.$(MAN1EXT)',
			'oscar_sanity_check' => '$(INST_MAN1DIR)/oscar_sanity_check.$(MAN1EXT)',
			'opd2' => '$(INST_MAN1DIR)/opd2.$(MAN1EXT)',
			'oscar_image_cleanup' => '$(INST_MAN1DIR)/oscar_image_cleanup.$(MAN1EXT)',
		},
		'macro' => {
			'MAN1EXT' => '1',
			'MAN3EXT' => '3pm',
		},
);
