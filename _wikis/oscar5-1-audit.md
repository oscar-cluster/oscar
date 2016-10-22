---
layout: wiki
title: oscar5-1-audit
meta: 
permalink: "/wiki/oscar5-1-audit"
category: wiki
---
<!-- Name: oscar5-1-audit -->
<!-- Version: 1 -->
<!-- Author: valleegr -->


    Differences between trunk and branch 5-1
    Asterisks should be noted.
    Asterisked files should probably be reviewed again to get a closer look.
    
    scripts/create_and_populate_basic_node_info
    	Changed calls to oscar_log to normal print statements
    
    scripts/oscar_image_cleanup
    	Removed some documentation 
    
    scripts/build_opkg_rpms
    	Now runs from one level down in the OSCAR tree and sets OSCAR_HOME
    
    scripts/opd
    	Removes extra output
    
    scripts/install_prereq
    	*trunk is more up-to-date
    	Uses explicit path names instead of relative path names
    
    *scripts/wizard_prep
    	Removes special treatment of debian
    	Uses yume instead of yum
    	Calls api-pre-install instead of setup
    	Starting to deal with package sets (Erich's version)
    	Calls to opkgs_install have notion of "server" and "node"
    
    scripts/start_over
    	Uses the new OpkgDB api to get a list of packages installed
    
    scripts/install_server
    	*trunk is more up-to-date
    	trunk uses PackMan
    	branch uses OSCAR::Opkg::opkgs_install
    
    scripts/sanity_check
    	New script in branch
    
    scripts/OCA-driver.pl
    	New script in branch
    
    scripts/system-sanity.d/tftpboot-check.pl
    	Added calls to OSCAR::OS_Detect to test the distro
    
    scripts/system-sanity.d/network-check.pl
    	Calls netstat instead of ifconfig
    
    scripts/get-oscar-version.sh
    	New script in branch
    
    scripts/populate_oda_packages_table
    	New script in branch
    
    scripts/prepare_oda
    	New script in branch
    
    scripts/set_global_oscar_values
    	Moved get-oscar-vesion.sh script from dist to scripts
    
    scripts/oscar-cluster
    	New script in branch
    
    scripts/build_oscar_rpms
    	Requires yum and yume
    	Changes the way text is parsed, but doesn't change API calls
    
    scripts/oscar_wizard
    	Moved get-oscar-version.sh from dist to scripts
    	Added package_groups
    
    scripts/oda
    	Removed init command from oda
    	
    scripts/cli
    	All cli stuff is new here (or at least moved from the old place
    
    scripts/oscar-config
    	Looks for OSCAR_HOME environment variable instead of cwd
    	Removed generate-config-file, network, and bootstrap options
    	Moved lots of code around but it looks like it's all still there
    
    scripts/setup_pxe
    	Added ppc64 support?
    
    scripts/OCA-driver
    	Not in branch
    
    scripts/oscar_sanity_check
    	Not in branch
    
    scripts/oscar_api_opkgs
    	Not in branch
    
    scripts/oscar
    	Not in branch
    
    scripts/slembed
    	Not in branch
    
    scripts/config-xml-convert
    	Not in branch
    
    scripts/Makefile.PL
    	Not in branch
    
    scripts/package_config_xmls_to_database
    	Not in branch
    
    src/xoscar
    	New in branch
    
    src/ORM
    	Says there are diffs, but it doesn't show them.  May actually be no diffs
    
    src/cli
    	Removed in branch (probably moved)
    
    oscarsamples
    	Updated requirements and added new lists for new distros
    
    HOWTO
    	General updates to how to run the installer
    
    package_sets/Default
    	Created and updated package sets for all the supported distros
    
    share/supported_distros.txt
    	Removed in branch
    
    share/oscar.conf
    	Removed in branch
    
    dist/newmake.sh
    	get-oscar-version.sh moved from dist to scripts
    
    lib/Qt/SelectorManageSets.pm
    	Added renameButton
    	Removed code to check for selections in listbox
    
    lib/Qt/SelectorTable.pm
    	No major changes
    
    lib/Qt/Selector.pl
    	Added buttons for package set management
    
    lib/Qt/SelectorUtils.pm
    	Removed code for getting provides, requires, and conflict lists.
    		It would appear that this stuff is getting moved somewhere else.
    
    lib/OSCAR/Distro.pm
    	*trunk is more recent
    	Moved supported_distros.xml to supported_distros.txt
    	Has all the changes necessary to use flat files instead of XML
    
    lib/OSCAR/OpkgDB.pm
    	*trunk is more recent
    	Removed function exports
    		opkg_api_path
    		oscar_repostring
    	Changed oscar_repostring to make_repostring
    	Changed opkg_api_path to opkg_localrpm_info
    	Parses information given back from rpm or deb files now
    	Removed helper function hash_from_cmd_rpm
    
    lib/OSCAR/PackagePath.pm
    	*trunk is more recent
    	Added a bunch of functions
    		decompose_distro_id
    		get_common_pool_id
    		get_default_distro_id
    		get_default_oscar_repo
    		get_repo_type
    		get_list_setup_distros
    		mirror_repo
    		use_distro_repo
    		use_oscar_repo
    		use_default_distro_repo
    		use_default_oscar_repo
    
    lib/OSCAR/PartitionMgt.pm
    	*trunk is more recent
    	Added functions
    		deploy_partition
    		display_partition_info
    		display_partition_data
    		validate_partition_data
    	get_partition_distro, get_list_nodes_partition API change
    		OLD - $partition_name
    		NEW  - $cluster_name, $partition_name
    	get_list_partitions gets list of partitions based on cluster name
    	get_list_partitions_from_clusterid gets list of partitions based on cluster id
    	get_partition_info API change
    		OLD - $cluster_id, $group, $result_ref
    		NEW - $cluster_name, $partition_name
    	set_partition_info API change
    		OLD - $cluster_id, $group_name, $distro, $servers, $clients
    		NEW - $cluster_name, $partition_name, $distro_id, $servers, $clients
    	set_node_to_partition API change
    		OLD - $partition_id, $node_name, $node_type
    		NEW - $cluster_name, $partition_name, $node_name, $node_type
    	oda_add_node API change
    		OLD - returned nothing
    		NEW - returns 0 on success and -1 on failure
    	delete_partition_info
    		OLD - returned nothing
    		NEW - returns 0 on success and -1 on failure
    	Added ability to use db or flat files
    
    lib/OSCAR/ODA/mysql.pm & lib/OSCAR/ODA/pgsql.pm
    	*trunk is more recent
    	Moved print_hash to OSCAR::Utils
    
    lib/OSCAR/Env.pm
    	*trunk is more recent
    	profiled_files_write API change
    		OLD - $env_var, $dir
    		NEW - $dir
    		This just takes away the ability to chose the name of the environment
    			variable, it's always going to be OSCAR_HOME anyway.
    
    lib/OSCAR/Package.pm
    	Removed internal function getOdaPackageDir
    	Added internal function get_scripts_dir
    
    lib/OSCAR/msm.pm
    	*trunk is more recent
    	add_partition API change
    		OLD - $partition_name, $distro, $list_clients
    		NEW - $cluster_name, $partition_name, $distro, $list_clients
    
    lib/OSCAR/MAC.pm
    	*trunk is more recent
    	Logs to oscar_log instead of printing now
    	Added debian support
    	Updated documentation
    
    lib/OSCAR/Database_generic.pm
    	*trunk is more recent
    	Added internal function init_database_passwd
    
    lib/OSCAR/PackageSmart.pm
    	*trunk is more recent
    	Added functions
    		detect_pool_format
    		prepare_distro_pools
    		prepare_pool
    
    lib/OSCAR/Database.pm
    	*trunk is more recent
    	Removed function
    		get_group_packages
    	Added functions
    		get_packages_related_with_package
    		get_packages_related_with_name
    		get_packages_with_class
    	Added internal function pkgs_of_opkg
    	Added code to deal with db and flat files
    	Updated lots of stuff to accomidate for changes to how the DB is setup
    	get_image_package_status_with_image_package API change
    		OLD - $image, $package, $results, $options_ref, $errors_ref, $requested
    		NEW - $image, $package, $results, $options_ref, $error_strings_ref,
    			$requested, $version
    	delete_group_packages API change
    		OLD - $group, $opkg, $options_ref, $errors_ref
    		NEW - $group, $opkg, $options_ref, $error_strings_ref, $ver
    	delete_package API change
    		OLD - $options_ref, $errors_ref, %sel
    		NEW - $package_name, $options_ref, $error_strings_ref, $package_version
    	insert_packages API change
    		OLD - $passed_ref, $table, $table_fields_ref, $passed_options_ref,
    			$passed_errors_ref
    		NEW - $passed_ref, $table, $name, $path, $table_fields_ref,
    			$passed_options_ref, $passed_error_strings_ref
    	update_node_package_status API change
    		OLD - $options_ref, $node, $passed_pkg, $requested, $errors_ref,
    			$selected
    		NEW - $options_ref, $node, $passed_pkg, $requested, $error_strings_ref,
    			$selected, $passed_ver
    	update_node_package_status_has API change
    		OLD - $options_ref, $node, $passed_pkg, $field_value_hash, $errors_ref
    		NEW - $options_ref, $node, $passed_pkg, $field_value_hash,
    			$error_strings_ref, $passed_ver
    	update_image_package_status API change
    		OLD - $options_ref, $image, $passed_pkg, $requested, $errors_ref,
    			$selected
    		NEW - $options_ref, $image, $passed_pkg, $requested, $error_strings_ref,
    			$selected, $passed_ver
    	update_packages API change
    		OLD - $passed_ref, $table, $package_id, $table_field_ref, $options_ref,
    			$errors_ref
    		NEW - $passed_ref, $table, $package_id, $name, $path, $table_fields_ref,
    			$options_ref, $error_strings_ref
    
    lib/OSCAR/DelNode.pm
    	Uses the run_pkg_script command instead of running the script directly
    
    lib/OSCAR/Configbox.pm
    	Added a parent for the configbox
    
    lib/OSCAR/Logger.pm
    	*trunk is more recent
    	Added a function (vprint) to print if VERBOSE is set
    	Added an internal function print_error_strings
    
    lib/OSCAR/OCA/OS_Detect.pm
    	Removed notion of oscar_pool
    
    lib/OSCAR/OCA/Sanity_Check/Prereqs.pm
    	Removed module in branch
    
    lib/OSCAR/OCA/OS_Detect/*
    	Remove functions about oscar_pool
    
    lib/OSCAR/Network.pm
    	*trunk is more recent
    	Added sanity check for NIC
    
    lib/OSCAR/ImageMgt.pm
    	*trunk is more recent
    	Added new functions
    		create_image
    		export_image
    		image_exists
    		install_opkgs_into_image
    	do_setimage API change
    		OLD - returned nothing
    		NEW - returns 0 on success, -1 otherwise
    	Added code for dealing with flat files instead of the database
    	do_post_binary_page_install API change
    		OLD - returned nothing
    		NEW - returns 1 on success, 0 otherwise
    	When do_post_binary_package_install fails it removes the image
    	do_oda_post_install API change
    		OLD - returns nothing
    		NEW - returns 0 on succes, -1 otherwise
    	do_oda_post_install gets config info from the db and OSCAR::ConfigManager
    			instead of the old db
    
    lib/OSCAR/Opkg.pm
    	*trunk is more recent
    	Added new function
    		prepare_distro_pools
    	opkgs_install became opkgs_install_server and API change
    		OLD - $type, $opkgs AND returns nothing
    		NEW - $opkgs AND returns 0 on success, -1 otherwise
    	opkgs_install_server no longer uses pkg_pools
    	Looks for -server packages in the name instead of the db
    
    lib/OSCAR/FileUtils.pm
    	*trunk is more recent
    	Added new functions
    		get_directory_content
    		get_dirs_in_path
    	add_line_to_file_without_duplication no longer dies if it fails
    
    lib/OSCAR/Utils.pm
    	*trunk is more recent
    	Changed the way the get_oscar_version function determines the version
    	Added new functions
    		is_a_valid_string
    		print_hash
    
    lib/OSCAR/Bootstrap.pm
    	Not in branch
    
    lib/OSCAR/Prereqs.pm
    	Not in branch
    
    lib/OSCAR/PartitionConfigManager.pm
    	Not in branch
    
    lib/OSCAR/NodeMgt.pm
    	Not in branch
    
    lib/OSCAR/ConfigManager.pm
    	Not in branch
    
    lib/OSCAR/NodeConfigManager.pm
    	Not in branch
    
    lib/OSCAR/VMConfigManager.pm
    	Not in branch
    
    install_cluster
    	Moved get-oscar-version.sh from dist to scripts
    	Moved cli from src to scripts
    
    oscar-base-spec.in
    	Updated list of directories used by OSCAR for rpm
    
    Makefile
    	*trunk is more recent
    	Has get-oscar-version.sh in scripts instead of dist
    	Simplified the nightly make section
    
    testing/test_cluster
    	Doesn't look in the OSCAR::PackagePath::PKG_SOURCE_LOCATIONS anymore
    
    testing/run_unit_test
    	Not in branch
    
    testing/unit_testing
    	Not in branch