#!/vendor/bin/sh
IFS='
'

# This software is contributed or developed by KYOCERA Corporation.
# (C) 2016 KYOCERA Corporation
# (C) 2018 KYOCERA Corporation

error() {
	/vendor/bin/echo "$1" 1>&2
}

rewrite() {

	if [ ! -e "$1" ] ; then
		error "File does not exist"
		return 1 
	fi

	if [ "$1" = "." ]; then
		return 0
	fi

	opt=
	if [ -d "$1" -a ! -h "$1" ]; then
		# A directory, re-encrypt the filename
		temp1=`/vendor/bin/mktemp -d "$1".XXXXXXXXXX` || {
			error "Could not create tempdir"
			return 1
		}
		/vendor/bin/mv -f "$1" "$temp1" 2>/dev/null  || {
			error "Could not rename[$1] -> [$temp1]"
			/vendor/bin/rmdir "$temp1"
			return 1
		}
		/vendor/bin/mv -f "$temp1" "$1" 2>/dev/null || {
			error "Could not rename [$temp1] -> [$1]"
			return 1
		}
	else
		# A file or symlink, re-encrypt the contents
		temp1=`/vendor/bin/mktemp "$1".XXXXXXXXXX` || {
			error "Could not create tempfile"
			return 1
		}
		/vendor/bin/sync
		/vendor/bin/cp -a -p -f "$1" "$temp1" 2>/dev/null || {
			error "Could not copy [$1] -> [$temp1]"
			/vendor/bin/rm -f "$temp1"
			return 1
		}
		/vendor/bin/sync
		/vendor/bin/mv -f "$temp1" "$1" 2>/dev/null || {
			error "Could not rename [$temp1] -> [$1]"
			return 1
		}
		/vendor/bin/sync
	fi

	return 0
}

#main
if [ ! -e "$1" ] ; then
	error "Path does not exist"
	/vendor/bin/setprop vold.encrypt.result -1
	exit -1
fi

echo "$@" 1>&2

/vendor/bin/setprop vold.encrypt.result 0
ecrypt_file=0

all_file_list=`/vendor/bin/find $1 -type f`
/vendor/bin/setprop vold.filenum `echo "${all_file_list}" | wc -l`

for file in ${all_file_list}
do
	echo "$file" 1>&2
	rewrite $file
	if (( $? != 0 )); then
		error "encryption failed. exit $0"
		/vendor/bin/setprop vold.encrypt.result -1
		exit -1
	fi
	/vendor/bin/setprop vold.encrypt_num $(( ++ecrypt_file ))
done

/vendor/bin/setprop vold.encrypt.result 1
