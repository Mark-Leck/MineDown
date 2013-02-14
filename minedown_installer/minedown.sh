#!/bin/sh
# This script was generated using Makeself 2.1.5

CRCsum="1325942955"
MD5="00ba2889913d11a27730f2df131aef04"
TMPROOT=${TMPDIR:=/tmp}

label="MineDown Installer"
script="./minedown.setup"
scriptargs=""
targetdir="minedown_installer"
filesizes="3360"
keep=n

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_Progress()
{
    while read a; do
	MS_Printf .
    done
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{print $4}'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.1.5
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
 
 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target NewDirectory Extract in NewDirectory
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || type digest`
    PATH="$OLD_PATH"

    MS_Printf "Verifying archive integrity..."
    offset=`head -n 402 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test `basename $MD5_PATH` = digest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test $md5 = "00000000000000000000000000000000"; then
				test x$verb = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test "$md5sum" != "$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x$verb = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test $crc = "0000000000"; then
			test x$verb = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test "$sum1" = "$crc"; then
				test x$verb = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc"
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    echo " All good."
}

UnTAR()
{
    tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
}

finish=true
xterm_loop=
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 20 KB
	echo Compression: gzip
	echo Date of packaging: Thu Feb 14 10:32:41 GMT 2013
	echo Built with Makeself version 2.1.5 on 
	echo Build command was: "/usr/bin/makeself.sh \\
    \"--gzip\" \\
    \"/home/mark/MineDown/minedown_installer/\" \\
    \"minedown.sh\" \\
    \"MineDown Installer\" \\
    \"./minedown.setup\""
	if test x$script != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"minedown_installer\"
	echo KEEP=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=20
	echo OLDSKIP=403
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 402 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 402 "$0" | wc -c | tr -d " "`
	arg1="$2"
	shift 2
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - $*
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
	shift 2
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	finish="echo Press Return to close this window...; read junk"
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test "$nox11" = "n"; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm rxvt dtterm eterm Eterm kvt konsole aterm"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test "$targetdir" = "."; then
    tmpdir="."
else
    if test "$keep" = y; then
	echo "Creating directory $targetdir" >&2
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target OtherDirectory' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x$SETUP_NOCHECK != x1; then
    MS_Check "$0"
fi
offset=`head -n 402 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 20 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

MS_Printf "Uncompressing $label"
res=3
if test "$keep" = n; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test $leftspace -lt 20; then
    echo
    echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (20 KB)" >&2
    if test "$keep" = n; then
        echo "Consider setting TMPDIR to a directory with more free space."
   fi
    eval $finish; exit 1
fi

for s in $filesizes
do
    if MS_dd "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; UnTAR x ) | MS_Progress; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
echo

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = xy; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval $script $scriptargs $*; res=$?;
		fi
    else
		eval $script $scriptargs $*; res=$?
    fi
    if test $res -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test "$keep" = n; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
� I�Q�Z�S���g��
�7�-�u/�8���`S���ddim�HZUZa���~���ʲ1��4���� �j罿��z��_NM���M�i��m��涽�ղ7�}{���6�}�R�$ ���}�z��z#�#��I�w��޲7Z����W�[ϠY��/�����'Ϗ���`0�c'��#�^�;p��b��/\�0ᑰX������#��b��8Ky�|+1����ӓ�U��j��0T��?���ʚ��1h��߂�Ȁ8�#1��&~, D[��A�E�@�C?��j�y�#��4 ؍/�6����=�혓1N����x�,	L�����`��|7��;�v���F�!���X}��dI�9��?�F0#��s�[?ALD�y 8�����˳8`���M�"�g)�;'�!�)�йb�f	C�S��عf8��m�,���E�����Q���s��2'�W�b��x�����oJ���=1�~<g���u��(�nYa:�0G�S�1xػK��Э2�~��pt{t�:g��B��'؇˘�F�[��H�C����1lP���r"ٵ�n��Y�:#FV�DA�:|�P��&�퓺a��0�0F��G���?�Lꊓ��C�E�"ԩ�AiY���EB�"F�
K���8o!Ĝ�Za�O'�B�~�X*Rԙ���`��F؄��%b�dX�C�3w\3�>��j������>����S7D۶e�w�d�;�}����:M�x�߃�;��7ﾹ���/߱A2�zr5�:=o�����h��8�����V+�_w2�}�&���'�w�w��^�`�F���jJg�x&��9���+yZ4�n��9�N��3.��XC�)���]�LQ�#�#,H=i�P"T���rr9����Qr�M���$�l�����,�0)tfޣ��!�c�b��[��=�{IY��{
?�IN�:a��<��<<:�� ੨a�7��r,z���u/��5ڭ��fɜ�ZJ�3٤�K�y��F�TH��1��^�7����b&A�'�� ���e�z��Y�T�ȣ͔�w���r�T��d!�=6t�@P���F����"8;�vz]89�w��Y��R)�}��%·�.�6� Ș���y���X���hP�E�j�dj�ǲ�(ţ �3k"�غܭ;{{�'������~gBJ��o]ڿ�=��N�f�p�,`��|҆�~�Y鍔�d�ղ�#Lp4Ĕ���Ƴ�%����}c�����v_l���{��s%��$����'�Or��Ę'��B�_��K˶\4A��`R%������-w��1n�p�T�����B�b�,�X����,�r��)mMxxF�Tʍ?%l 0_`�h�a��;B�bh��-�h!eЭ~��R�����+`^�F~*S����:<�o��U
8:���	�?V�C�׫�a�pG,;B��Q���Q�����7�ʼ�x2�z$���ͭ��y��������1��8a��,�R��\�zNk�ij����4���0���n�X!xB>{Ѷ��F�����T�c@��T�X�c�`� W*�K~���R	K��R�'{������I"j�hT�#]��Q�.�0�=�g���u�֕�nC�[�;�~�� �{�0�/K����A�˲|r(�QH�d�"bdh�XB�q=a�O�t��U�F/{�U�T�;� �g�'�:��7A]�,W+�h�0���rm$�I���;�^�ЍJWsMR/��a�{��B��HE�2�����Oo�3v��6!-�]w�x�vʣbG#�Zmٯ&)rQI}��VDNY�ˇ�2���&'x	�"xz��C�����A"��s_����X2���(���!t�&���<Ƚ^_"X���x�@&^�\x�Lq����0ӗ�n�
U��ȑ$
��0l�r�C��,�9�3�]*�ܑ�ķ*$'D�=�@��*�Z�h��|����/��$��~����� ���J�z��m�X)�|I�;�)AQ3jI��+��k�������A��UK�|��5�w��F[�e�n2���K�V�0��?���8Wh흞 ݒ�=ro*lb�ha�<�
M�ӂ�nk���\�Bi�nb���]|<����s����Y�|���������������o�u���ۨ/M�EV)�r��pb�b7K=�e/�8�,�/YWg��8��]g�����ZW��P�V�Xv�K�|�iH�J�����J��s��Ν�V+����K^G&}�䘁Yאf�bY�V@��ȏ$���N{/5��!�p�U�b��9�/	pQ`�$����8�]���?�%nP�Q�f�>,Ixb� @�*�Q?��� _ԄB�(�Z!-@9Ĳb�VM����;�<�� ���:��<�9��J��k$���{��R���m�Z�V%e�췏3娚y�Vmȡ�#p�|�|��t*[UP'e�,A��Е~���^L:�H���r��j�M���jڍ��h���
g���00�ay`�-A$���!�zz�=4k�PdczҶ�@�f3}�sl���RT�[���/͇ކ���e6Q]Ig�xG�\����bL�P�{x0��H4b�UN3��[�_7�n�4��,�����,W���0чl�����,��e��Q�b�<S^h\�� λ���׆.���D']QJ2�?`�ű�I��T�I�&p%+��`ea�.�(J��m���YE�����ng��[7⯼��z���?�f˖��[�[�ֶ��onW��_�~dIJg��r~P�h˯Y��:���w�k�����m���Kwq=$-z��c�F�z_���H�ȏ�����,����Ә�������"�ʪS�:e\�](�,��s2*~�Xɫo� W,%���*���HQBD�]p3�p��۸�ш�V��"��_��S�k�yM*�+؁��G�&Q�dƄ�C5d�(�@j�n-�Alh#5g�i�d�RK:1�Ud����KY۬���[��y��������������}����hV����u8��u��U��㐼;����r����aVi<i�'�����4������\�#q��~J�n<��Y�H��Q��ڻ�@�a�j�;�z��\����O�������#�˫��o�,S���x�A�.|d�ws��&q��S��mM��@%�c(yzI��^���m:����Y���g�-�2�����r�W�.^�j��B2ҽ�ѹ��Rc�+���c.����ߊ*����*����*����*����*����*����*����*���O��Cc� P  