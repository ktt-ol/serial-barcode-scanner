#!/bin/sh
# MIT license
# Copyright 2009-2010 Sebastian Reichel <sre@ring0.de>

# These are default values for some configurable things
if [ "x$CC" = "x" ] ; then
	CC=gcc
fi;

if [ "x$VALAC" = "x" ] ; then
	VALAC=valac
fi;

if [ "x$INSTALL" = "x" ] ; then
	INSTALL=install
fi;

if [ "x$PKGCONFIG" = "x" ] ; then
	PKGCONFIG=pkg-config
fi;

PREFIX=/usr/local
INSTALL_DATA=`echo ${INSTALL} -m 644`
INSTALL_PROGRAM=`echo ${INSTALL} -m 755 -s`
INSTALL_DIR=`echo ${INSTALL} -d`

# This awk script is derived from autotools
awk_verscmp='
  # Use only awk features that work with 7th edition Unix awk (1978).
  # My, what an old awk you have, Mr. Solaris!
  END {
    while (length(v1) && length(v2)) {
      # Set d1 to be the next thing to compare from v1, and likewise for d2.
      # Normally this is a single character, but if v1 and v2 contain digits,
      # compare them as integers and fractions as strverscmp does.
      if (v1 ~ /^[0-9]/ && v2 ~ /^[0-9]/) {
	# Split v1 and v2 into their leading digit string components d1 and d2,
	# and advance v1 and v2 past the leading digit strings.
	for (len1 = 1; substr(v1, len1 + 1) ~ /^[0-9]/; len1++) continue
	for (len2 = 1; substr(v2, len2 + 1) ~ /^[0-9]/; len2++) continue
	d1 = substr(v1, 1, len1); v1 = substr(v1, len1 + 1)
	d2 = substr(v2, 1, len2); v2 = substr(v2, len2 + 1)
	if (d1 ~ /^0/) {
	  if (d2 ~ /^0/) {
	    # Compare two fractions.
	    while (d1 ~ /^0/ && d2 ~ /^0/) {
	      d1 = substr(d1, 2); len1--
	      d2 = substr(d2, 2); len2--
	    }
	    if (len1 != len2 && ! (len1 && len2 && substr(d1, 1, 1) == substr(d2, 1, 1))) {
	      # The two components differ in length, and the common prefix
	      # contains only leading zeros.  Consider the longer to be less.
	      d1 = -len1
	      d2 = -len2
	    } else {
	      # Otherwise, compare as strings.
	      d1 = "x" d1
	      d2 = "x" d2
	    }
	  } else {
	    # A fraction is less than an integer.
	    exit 1
	  }
	} else {
	  if (d2 ~ /^0/) {
	    # An integer is greater than a fraction.
	    exit 2
	  } else {
	    # Compare two integers.
	    d1 += 0
	    d2 += 0
	  }
	}
      } else {
	# The normal case, without worrying about digits.
	d1 = substr(v1, 1, 1); v1 = substr(v1, 2)
	d2 = substr(v2, 1, 1); v2 = substr(v2, 2)
      }
      if (d1 < d2) exit 1
      if (d1 > d2) exit 2
    }
    # Beware Solaris /usr/xgp4/bin/awk (at least through Solaris 10),
    # which mishandles some comparisons of empty strings to integers.
    if (length(v2)) exit 1
    if (length(v1)) exit 2
  }
'

show_usage() {
	echo "'configure' configures $1 to adapt to many kinds of systems."
	echo "Usage: ./configure [OPTION]... [VAR=VALUE]..."
	echo
	echo "To assign environment variables (e.g. CC, CFLAGS, ...), specify them"
	echo "as VAR=VALUE. See below for descriptions of some of the useful variables."
	echo
	echo "Defaults for the options are specified in brackets."
	echo
	echo "Options:"

	echo "  -h, --help                  display this help and exit"
	echo "  -v, --version               display version information and exit"
	echo "  --prefix=PREFIX             install files in PREFIX [/usr/local]"
	echo "  --debug                     enable debug build (-g flag)"
	echo "  --colored                   enable colored build"

	for parameter in `extra_options list-all` ; do
		extra_options $parameter
		printf "  %-27s $DESC\n" $parameter
	done

	echo
	echo "Some influential environment variables:"
	echo "  CC                          C compiler command"
	echo "  VALAC                       Vala compiler"
	echo "  CFLAGS                      C compiler flags, e.g. -I<header dir>"
	echo "  LDFLAGS                     linker flags, e.g. -L<lib dir>"
	echo "  INSTALL                     install binary"
	echo "  PKGCONFIG                   pkg-config binary"
	echo
	echo "Report bugs to: $2"
	exit 0
}

show_version() {
	echo "$1 version $2"
	echo "Originally written by $3"
	exit 0
}

check_parameters() {
	while : ; do
		[ -z "$1" ] && break
		parse_options $1
		shift
	done

	if [ "$UNKNOWN_FLAG" = "1" ] ; then
		echo
	fi
}

parse_options() {
	flag=`echo $1 | cut -d = -f 1`
	value=`echo $1 | awk 'BEGIN{FS="=";}{print $2}'`

	case $flag in
		"-h"|"--help")
			show_usage "$NAME" "$AUTHOR"; ;;
		"-v"|"--version")
			show_version "$NAME" "$VERSION" "$AUTHOR"; ;;
		"--debug")
			DEBUG="yes"; ;;
		"--colored")
			COLOR="yes"; ;;
		"--prefix")
			PREFIX="$value"; ;;
		"CC")
			CC="$value"; ;;
		"CFLAGS")
			CFLAGS="$value"; ;;
		"LDFLAGS")
			LDFLAGS="$value"; ;;
		"INSTALL")
			INSTALL="$value"; ;;
		"PKGCONFIG")
			PKGCONFIG="$value"; ;;
		"VALAC")
			VALAC="$value"; ;;
		*)
			extra_options $flag $value
			if [ "$CMD" != "not-available" ] ; then
				eval "$CMD"
			else
				echo "WARNING: unknown flag '$1'." >&2
				UNKNOWN_FLAG=1
			fi;;
	esac
}

check_prg_version() {
	printf " %-34s" "$1..."

	if [ "$4" = "disable" ] ; then
		echo "disabled"
		return 0
	fi

	if [ "$3" = "" ] ; then
		echo "missing"
		if [ "$4" != "force" ] ; then
			return 0
		else
			exit 1
		fi
	fi

	echo "$3"

	awk "$awk_verscmp" v1="$2" v2="$3" /dev/null
	if [ "$?" = "2" ] ; then
		echo "Please install at least $2 to use this feature"
		if [ "$4" != "force" ] ; then
			return 0
		else
			exit 1
		fi
	fi

	return 1
}

check_pkg_version() {
	printf " %-34s" "$1..."

	if [ "$3" = "disable" ] ; then
		echo "disabled"
		return 0
	fi

	pkg-config --exists $1
	if [ "$?" = "1" ] ; then
		echo "missing"
		if [ "$3" != "force" ] ; then
			return 0
		else
			exit 1
		fi
	fi

	echo `pkg-config --modversion $1`

	pkg-config --atleast-version "$2" "$1"
	if [ "$?" = "1" ] ; then
		echo "Please install at least $2"
		if [ "$3" != "force" ] ; then
			return 0
		else
			exit 1
		fi
	fi

	return 1
}

check_font() {
	name="$1"

	printf " %-34s" "$1..."

	for file in /etc/fonts/conf.avail/*; do
		grep -q "$name" "$file"
		if [ $? -eq 0 ] ; then
			echo "available"
			return 1
		fi
	done

	echo "MISSING"

	if [ "$2" != "force" ] ; then
		return 0
	else
		exit 1
	fi
}

check_compiler() {
	printf "Checking compiler...               "
	echo 'main(){}' > test.c
	${CC} ${CFLAGS} ${LDFLAGS} -o a.out test.c >/dev/null 2>&1
	if [ ! $? = 0 ]; then
		echo failed
		exit 1
	else
		echo works
	fi
	rm -f a.out test.c
}

check_install() {
	printf "Checking install...                "
	if [ -x `which ${INSTALL}` ] ; then
		echo available
	else
		echo missing
		exit 1
	fi
}

check_pkgconfig() {
	printf "Checking pkg-config...             "
	if [ -x `which ${PKGCONFIG}` ] ; then
		echo `${PKGCONFIG} --version`
	else
		echo missing
		exit 1
	fi
}

create_config() {
	FILE=$1
	shift
	printf "Creating %-26s" $FILE...
	rm -f $FILE && touch $FILE

	# Some standard variables
	echo DEBUG=$DEBUG >> $FILE
	echo COLOR=$COLOR >> $FILE
	echo CC=$CC >> $FILE
	echo CFLAGS=$CFLAGS >> $FILE
	echo LDFLAGS=$LDFLAGS >> $FILE
	echo PREFIX=$PREFIX >> $FILE
	echo PKGCONFIG=$PKGCONFIG >> $FILE
	echo INSTALL=$INSTALL >> $FILE
	echo INSTALL_DATA=$INSTALL_DATA >> $FILE
	echo INSTALL_PROGRAM=$INSTALL_PROGRAM >> $FILE
	echo INSTALL_DIR=$INSTALL_DIR >> $FILE

	for option in $@ ; do
		value=`echo \\$$option`
		value=`eval echo $value`
		echo $option=$value >> $FILE
	done

	echo "done"
}

create_header() {
	FILE=$1
	shift
	printf "Creating %-26s" $FILE...
	rm -f $FILE && touch $FILE

	for option in $@ ; do
		value=`echo \\$$option`
		value=`eval echo $value`
		echo "#define $option \"$value\"" >> $FILE
	done

	echo "done"
}

final_report() {
	echo
	echo "Final Report:"
	for option in $@ ; do
		value=`echo \\$$option`
		value=`eval echo $value`
		printf "  %-10s = %s\n" $option $value
	done
}
