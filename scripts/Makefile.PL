use ExtUtils::MakeMaker;
use Carp;

WriteMakefile(
		'NAME' => 'OSCAR_scripts',
		'MAN1PODS' => {
			'create_oscar_database' => '$(INST_MAN1DIR)/create_oscar_database.$(MAN1EXT)',
			'install_prereq' => '$(INST_MAN1DIR)/install_prereq.$(MAN1EXT)',
			'install_server' => '$(INST_MAN1DIR)/install_server.$(MAN1EXT)',
			'make_database_password' => '$(INST_MAN1DIR)/make_database_password.$(MAN1EXT)',
			'oda' => '$(INST_MAN1DIR)/oda.$(MAN1EXT)',
			'opd2' => '$(INST_MAN1DIR)/opd2.$(MAN1EXT)',
			'oscar-config' => '$(INST_MAN1DIR)/oscar-config.$(MAN1EXT)',
			'oscar' =>  '$(INST_MAN1DIR)/oscar.$(MAN1EXT)',
			'oscar_image_cleanup' => '$(INST_MAN1DIR)/oscar_image_cleanup.$(MAN1EXT)',
			'oscar_sanity_check' => '$(INST_MAN1DIR)/oscar_sanity_check.$(MAN1EXT)',
			'oscar_wizard' => '$(INST_MAN1DIR)/oscar_wizard.$(MAN1EXT)',
			'package_config_xmls_to_database' => '$(INST_MAN1DIR)/package_config_xmls_to_database.$(MAN1EXT)',
			'setup_pxe' => '$(INST_MAN1DIR)/setup_pxe.$(MAN1EXT)',
			'system-sanity' => '$(INST_MAN1DIR)/system-sanity.$(MAN1EXT)',
		},
		'macro' => {
			'MAN1EXT' => '1',
			'MAN3EXT' => '3pm',
		},
);
