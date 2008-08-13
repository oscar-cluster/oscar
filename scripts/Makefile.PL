use ExtUtils::MakeMaker;
use Carp;

WriteMakefile(
		'NAME'              => 'OSCAR_scripts',
        'INSTALLSITEBIN'    => '/usr/bin',
        'INSTALLBIN'        => '/usr/bin',
        'INSTALLSITESCRIPT' => '/usr/bin',
		'MAN1PODS' => {
			'install_prereq' => '$(INST_MAN1DIR)/install_prereq.$(MAN1EXT)',
			'install_server' => '$(INST_MAN1DIR)/install_server.$(MAN1EXT)',
			'opd2' => '$(INST_MAN1DIR)/opd2.$(MAN1EXT)',
			'oscar-config' => '$(INST_MAN1DIR)/oscar-config.$(MAN1EXT)',
			'oscar' =>  '$(INST_MAN1DIR)/oscar.$(MAN1EXT)',
			'oscar_image_cleanup' => '$(INST_MAN1DIR)/oscar_image_cleanup.$(MAN1EXT)',
			'oscar_sanity_check' => '$(INST_MAN1DIR)/oscar_sanity_check.$(MAN1EXT)',
			'oscar_wizard' => '$(INST_MAN1DIR)/oscar_wizard.$(MAN1EXT)',
			'setup_pxe' => '$(INST_MAN1DIR)/setup_pxe.$(MAN1EXT)',
			'system-sanity' => '$(INST_MAN1DIR)/system-sanity.$(MAN1EXT)',
			'build_opkg_rpms' => '$(INST_MAN1DIR)/build_opkg_rpms.$(MAN1EXT)',
		},
		'macro' => {
			'MAN1EXT' => '1',
			'MAN3EXT' => '3pm',
		},
        'EXE_FILES' => [qw(
            create_and_populate_basic_node_info
            distro-query
            get_arch
            get_num_proc
            get-oscar-version.sh
            install_prereq
            install_server
            integrate_image
            mac_collector
            macinfo2sis
            OCA-driver
            opd
            opd2
            oscar
            oscar-config
            oscar-vm
            oscar_image_cleanup
            oscar_sanity_check
            oscar_wizard
            ping_clients
            post_clients
            post_install
            post_rpm_install
            prepare_repos
            prep_oscar_repos
            repo-update
            set_node_nics
            set_oscar_interface
            setup_pxe
            ssh_install
            system-sanity
            update_live_macs
            wizard_prep
        )],
);
