package OPMC3;

#$Id: OPMC3.pm,v 1.4 2001/08/16 18:51:13 mjbrim Exp $

# OSCAR Package Management Library
# (uses C3 Tool Suite version 3.0 or later)

#$COPYRIGHT$

use vars qw(@ISA @EXPORT);

require Exporter;
@ISA     = qw(Exporter);
@EXPORT  = qw(install_pkg uninstall_pkg configure_pkg);

sub process_pkg {
  my ($action, $pkg, $dir, $nodes, $server) = @_;
  if( find_files($dir, $action) ) {
    my $c3script = "/tmp/$pkg-$action.c3";
    my $c3conf = "/tmp/$pkg-$action.c3conf";
    my $c3files = "/tmp/$pkg-$action.c3files";
    write_c3_cmds($c3script, $pkg, $dir, $c3conf, $nodes, $server, $action, $c3files);
    system($c3script);
    system("/bin/rm -f $c3script $c3conf $c3files");
    return 0;
  }
  else { return 1; }
}

sub install_pkg {
  my ($pkg, $dir, $nodes, $group, $server) = @_;
  my $action = "install";
  
  # check to see if package is installed
  $pkglist = `readODR.pl  group PACKAGELIST NAME=$group | awk -F= '{print \$2}'`;
  ($pkglist, $rest) = split(/ /, $pkglist);
  $out = `readODR.pl packagelist PACKAGE NAME=$pkglist | grep $pkg`;
  if( $out ne "" ) {
    print "OPMC3::configure_pkg : package $pkg already installed, aborting install\n";
    return 1;
  }
  
  # do install
  if( process_pkg($action, $pkg, $dir, $nodes, $server) ) {
    return 1;
  } 
  else {
    # update ODR group packagelist 
    $cmd = "writeODR.pl -a packagelist NAME=$pkglist PACKAGE=$pkg ";
    if( $server ne "" ) {
      $cmd .= "SERVER=$server";
    }
    system($cmd);
    return 0; 
  }
}

sub uninstall_pkg {
  my ($pkg, $dir, $nodes, $group, $server) = @_;
  my $action = "uninstall";
  
  # check to see if package is installed
  $pkglist = `readODR.pl group PACKAGELIST NAME=$group | awk -F= '{print \$2}'`;
  ($pkglist, $rest) = split(/ /, $pkglist);
  $out = `readODR.pl packagelist PACKAGE NAME=$pkglist | grep $pkg`;
  if( $out eq "" ) {
    print "OPMC3::uninstall_pkg : package $pkg not installed, aborting uninstall\n";
    return 1;
  }

  # do uninstall
  if( process_pkg($action, $pkg, $dir, $nodes, $server) ) {
    return 1;
  } 
  else { 
    # update ODR group packagelist
    $cmd = "writeODR.pl -d packagelist NAME=$pkglist PACKAGE=$pkg";
    system($cmd);
    return 0;
  }
}

sub configure_pkg {
  my ($pkg, $dir, $nodes, $group, $server) = @_;
  my $action = "configure";
  
  # check to see if package is installed
  $pkglist = `readODR.pl group PACKAGELIST NAME=$group | awk -F= '{print \$2}'`;
  ($pkglist, $rest) = split(/ /, $pkglist);
  $out = `readODR.pl packagelist PACKAGE NAME=$pkglist | grep $pkg`;
  if( $out eq "" ) {
    print "OPMC3::configure_pkg : package $pkg not installed, aborting configure\n";
    return 1;
  }
  
  # do configure
  if( process_pkg($action, $pkg, $dir, $nodes, $server) ) {
    return 1;
  } 
  else {
    # update ODR group packagelist (only if pkg server changed) 
    $curr_server = `readODR.pl packagelist SERVER NAME=$pkglist PACKAGE=$pkg | awk -F= '{print \$2}'`;
    ($curr_server, $rest) = split(/ /, $curr_server);
    if( $curr_server ne $server ) {
      $cmd = "writeODR.pl -f NAME=$pkglist,PACKAGE=$pkg packagelist SERVER=$server";
      system($cmd); 
    }
    return 0;
  }
}

sub find_files {
    my ($dir, $action) = @_;
    my $config = "$dir/pkgconfig";
    my $file = "$dir/$action.files";
    if(! (-f $config && -x $config)) {
	print "OPMC3::find_files : $config is not executable\n";
	return 0;
    }
    elsif(! (-f $file && -r $file)) {
	print "OPMC3::find_files : $file is not readable\n";
	return 0;
    }
    return 1;
}

sub write_c3_files {
    my ($files, $tmpdir, $c3files, $config, $nodes) = @_;
    
    #generate C3 file list
    $| = 1;
    open(PKGFILES, "<$files") or 
        die "OPMC3::write_c3_files : could not read $file\n";
    open(C3FILES, ">$c3files") or 
        die "OPMC3::write_c3_files : could not write $c3files\n";

    while( <PKGFILES> ) {
        chomp;
        print C3FILES "$_ $tmpdir\n";
    }

    if( $config ) { 
        print C3FILES "$nodes $tmpdir\n";
    }

    close(PKGFILES, C3FILES);
}

sub write_c3_conf {
    my ($nodes, $conf, $server) = @_;
    my $hostname;

    #open files
    $| = 1;
    open(NODES, "<$nodes") or
        die "OPMC3::write_c3_conf : unable to read nodes file $nodes\n";
    open(CONF, ">$conf") or
        die "OPMC3::write_c3_conf : unable to write C3 config file $conf\n";

    chomp($hostname = `hostname`);
    @nodelist = <NODES>;

    print CONF "cluster oscar {\n";
    print CONF "\t$hostname:$hostname\n";
    foreach $node (@nodelist) {
        if( $node ne $server ) { print CONF "\t$node"; }
    }
    print CONF "}\n";

    close(NODES, CONF);
}

sub write_c3_cmds {
  my ($script, $pkg, $dir, $c3conf, $nodes, $server, $action, $c3files) = @_;
  my $time = `date +%H%M%S`;
  chomp($time);
  my $tmp_dir = "/tmp/$pkg-$action.$time";
  my $files = "$dir/$action-files.txt";
  my $file = "";
  my $config = 0;
  if( $action eq "configure" ) { $config = 1; }
  
  #generate C3 config file
  write_c3_conf($nodes, $c3conf, $server);

  #generate C3 file list
  write_c3_files($files, $tmp_dir, $c3files, $config, $nodes);

  #open script
  $| = 1;
  open(CMDS, ">$script") or
    die "OPMC3::write_c3_cmds : unable to open $script\n";

  #script setup
  print CMDS "#!/bin/sh\n";
  print CMDS "export PATH=\$PATH:$ENV{C3}\n";
  print CMDS "echo \"OPM : running pkgconfig to $action $pkg\"\n";
  print CMDS "cd $dir\n";  
  
  #run server pkgconfig
  if( $server eq "" ) {
    if( $config ) { $file = $nodes; }
    print CMDS "echo \"...processing package server on localhost\"\n";
    print CMDS "echo \"   -> executing opkgconfig -s $action $file\"\n";
    print CMDS "./opkgconfig -s $action $file\n";
  }
  else {
    if( $config ) { chomp($file = "$tmp_dir/" . `basename $nodes`); }
    print CMDS "echo \"...processing package server on $server\"\n";
    print CMDS "echo \"   -> creating temporary directory\"\n";
    print CMDS "rsh $server \"/bin/mkdir $tmp_dir\" > /dev/null \n";
    print CMDS "echo \"   -> transferring files\"\n";
    print CMDS "for file in `cat $c3files | awk '{print \$1}'`; do\n";
    print CMDS "  rcp \$file $server:$tmp_dir > /dev/null \n";
    print CMDS "done;\n";
    print CMDS "echo \"   -> executing opkgconfig -s $action $file\"\n";
    print CMDS "rsh $server \"$tmp_dir/opkgconfig -s $action $file\"\n";  
    print CMDS "echo \"   -> removing temporary directory\"\n";
    print CMDS "rsh $server \"/bin/rm -rf $tmp_dir\" > /dev/null \n";
  }
    
  #run client pkgconfig
  if( $config ) { chomp($file = "$tmp_dir/" . `basename $nodes`); }
  print CMDS "echo \"...processing package clients\"\n";
  print CMDS "echo \"   -> creating temporary directory\"\n";
  print CMDS "cexec -f $c3conf /bin/mkdir $tmp_dir > /dev/null \n";
  print CMDS "echo \"   -> transferring files\"\n";
  print CMDS "cpush -f $c3conf -l $c3files > /dev/null \n";
  print CMDS "echo \"   -> executing opkgconfig -c $action $file\"\n";
  print CMDS "cexec -f $c3conf $tmp_dir/opkgconfig -c $action $file\n";
  print CMDS "echo \"   -> removing temporary directory\"\n";
  print CMDS "crm -f $c3conf -r -o $tmp_dir > /dev/null \n";

  #cleanup
  close(CMDS);
  chmod 0755, $script;

  return 0;
}

1;
