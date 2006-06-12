#! /bin/csh -f
#
# $COPYRIGHT$
#

#
# This is goofy.  We have to be sure to skip running sed on this
# script itself because that will remove the +x Unix perms on this
# file, which we can't very well change in the middle of the find
# statement.
#
# Also must mv -f because the perms may very well be 444
#

# First, make all the license headers from the main copy:
# - Insert the current year
# - Put the comment marks in each file

set filelist=$1
set tempdir=/tmp/license-oscar.$$
mkdir -p $tempdir
set clicense=$tempdir/license.hdr.c
set cpplicense=$tempdir/license.hdr.cpp
set flicense=$tempdir/license.hdr.f
set shelllicense=$tempdir/license.hdr.shell
set textlicense=$tempdir/license.hdr.text
set texlicense=$tempdir/license.hdr.tex
set year=`date +%Y`

# Text comment file
set dir="`dirname $0`"
sed -e s/CURRENTYEAR/$year/ $dir/copyright-notice.txt > $textlicense

# LaTeX comment file
sed -e 's/^/% /' $textlicense > $texlicense

# C comment file
sed -e 's/^/ * /' $textlicense > $clicense

# C++ comment file
sed -e 's/^/\/\/ /' $textlicense > $cpplicense

# Fortran comment file
sed -e 's/^/c /' $textlicense > $flicense

# Shell comment file
sed -e 's/^/# /' $textlicense > $shelllicense


# Now make a sed script to substitute them in

set sedscript=$tempdir/license.sed
cat > $sedscript <<EOF
# C++ with // style comments
/\/\/.*\\\$COPYRIGHT\\\$/ {
	r $cpplicense
	d
}

# C with /* */ style comments
/\*.*\\\$COPYRIGHT\\\$/ {
	r $clicense
	d
}

# Fortran with c style comments
/c.*\\\$COPYRIGHT\\\$/ {
	r $flicense
	d
}

# Fortran with C style comments
/C.*\\\$COPYRIGHT\\\$/ {
	r $flicense
	d
}

# shell script with # style comments
/#.*\\\$COPYRIGHT\\\$/ {
	r $shelllicense
	d
}

# LaTeX script with % style comments
/%.*\\\$COPYRIGHT\\\$/ {
	r $texlicense
	d
}

# Text with no comments (i.e., everything else)
/\\\$COPYRIGHT\\\$/ {
	r $textlicense
	d
}
EOF

# Now substitue them in.  Can only do 25 files at a time due to
# limitations in csh's foreach (you can overload it with too many
# words)

set num=25
set num1="`expr $num + 1`"
set cur="`head -$num $filelist`"
tail -n +$num1 $filelist > $filelist.2
mv -f $filelist.2 $filelist

while ("$cur" != "")
    foreach arg ($cur)
	echo checking file $arg
	if (-f $arg && "$arg" != "dist/insertlic.csh" && \
	    "$arg" != "./dist/insertlic.csh" && \
	    "$arg" != "insertlic.csh") then
	    sed -f $tempdir/license.sed $arg > $arg.new 
	    diff $arg $arg.new > /dev/null
	    if ("$status" != 0) then
	    
		# Have to take a few pains to ensure that the original perms
		# are preserved, but ensure that all have read perms
	    
		set wantx=0
		set wantw=0
		if (-x $arg) then
		    set wantx=1
		endif
		if (-w $arg) then
		    set wantw=1
		endif
		
		cp -f $arg.new $arg
		rm $arg.new
		chmod a+r $arg
		
		if ("$wantx" == "1") then
		    chmod a+x $arg
		endif
		if ("$wantw" == "1") then
		    chmod u+w $arg
		endif
	    else
		rm -f $arg.new
	    endif
	endif
    end

    # Get the next $num files

    set cur="`head -$num $filelist`"
    tail -n +$num1 $filelist > $filelist.2
    mv -f $filelist.2 $filelist
end

# Now remove the temporary files

rm -rf $tempdir

exit 0
