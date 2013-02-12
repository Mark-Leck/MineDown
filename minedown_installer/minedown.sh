#!/bin/sh
# This script was generated using Makeself 2.1.5

CRCsum="4206828480"
MD5="d6a4756090cb975201dda7debc99bc45"
TMPROOT=${TMPDIR:=/tmp}

label="MineDown Installer"
script="./minedown.setup"
scriptargs=""
targetdir="minedown"
filesizes="3078"
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
	echo Uncompressed size: 16 KB
	echo Compression: gzip
	echo Date of packaging: Tue Feb 12 10:00:08 GMT 2013
	echo Built with Makeself version 2.1.5 on 
	echo Build command was: "/usr/bin/makeself.sh \\
    \"--gzip\" \\
    \"/home/mark/minedown/\" \\
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
	echo archdirname=\"minedown\"
	echo KEEP=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=16
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
	MS_Printf "About to extract 16 KB in $tmpdir ... Proceed ? [Y/n] "
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
if test $leftspace -lt 16; then
    echo
    echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (16 KB)" >&2
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
� �Q�Z�s���g���ǽ ;-�NBl�:�k ��\w2BZ�jI�J�`z����}	���6�Lgt>�:�{��;+ꍵ���H/ww���r�Y�Դf�����n��8�r���7�<cN
�9��}|=��R�1��$�{������§�g���o�r>�~����o���Rv�C������qc�d���C�C�S8�x����:p�}6!�/]�(�1�H���a���1L�C��NHR#��;汕�O�^���l�n5[���c�!A�;ah#�/�oX�6X1�&��0��$i��}7�
��<'�:�)lf�GA�&\Ǧ@n�1
�K�m'>.�!���j&q}
泯@����$(����.HQ�	��� � Cp��y�#�H��%���].P��@����J�)��w>\����і$�	�M☸,�q��k��2�I�5�]��s�}�������J�ʳT���Ӱ�����,'؍U�%~����8�冁Z�0<��G/"[��?�%ˊ��ނYdQ���ÇS��+�c6gAd��!ŜB9�S�\ÆL�������Ec�p玂1F���9�
d|/'�r�iD��x2Wy�`�9�ot�H�2��"�Һa�(	���@c��Q�?�L�R��K#!E�c4�P�AmI!��bt�Lpq�<��Ù�n�Ĝ��`(O'�BJ~�I�2���	 �a���8����-�ܧnFsׯ� �c3CS����W:��嵯�o�b�ͯy�N��kj��m��>؝��������ޓa:�nr�����=�5�<��5N��^���N�}��f��Q�pr��}����Qt&�4a�	���E[gHs�`��Im�T_W5��	��l9=C��P�g���i���H���>2H��M��WY��x.K>� �/Z�%�ߝԛ-��/Z`J��Ug=:h��U��>�Ő`�0�<��v�dA�P�"%��:X	�:>9�gMH3V��@���]�b���@�����~S��k��o��l��Pu�7��*m�L�6N���x�>����0)�>�Q�	��q^��K�F��<�Mi�����D�+"kOL'�쑑����:n��:Q(}��I�������ۆ�b�����>@��z���҆~�C��u��|ƒv���+�T��SK~-��P��-��d���988�<�o�t�$gBKu�v��
y��(1�Ǉ��Ǉ$��6lJh�I�X��!b�!E�@���X<�H�P��Z��W6د6Z�z����*�Դ}s]�d
\48��={�zB�N�|�l
zC�o��r��H����O�4b>E�y�T��	����B�jq]���ϲ�y(��ekB��C0r#�P����6��s�#�3LM<�E-d�H��;�M^h�r�ӹ�
���q��R% E��O�[F�g�N�:�G<���<7��r�2��B�0Q���Jw�mh���5��+�n���(�Wy��^���������
b�1?%�OC��,�R�We~}
g�`|���,��Z��:��i�X[����e�n6��KD��}S�C�QO3bю	�-��Ry_Go4�Ö��&2�d��b/��PԘ8i��4����trF#���2LkO�m+:���	Hw!ĝʭj@���\Wqo��e%P2��Y�Փc��S���+2F�������'�5�,����N���wd<�@�MyJ���`W��h�Y�DÔ87?Cܴ��C��W��d;�76����ܐ�����B�y�B�R�@�����VTU��{��9���}��Һ=��/Ի�IežFF�ڲ�X��E%��/Z�9e�.��p_s��s(7�s(��Ə7�A�$�XU�2bT��r7��5g�~a����<�]	��,'Y�4" 
/F.	=,�xFAHFH���s�7�U6���$*��0ad�s�C�(,�J��.5\�XC�;���2p��^���V4K}a������Jϋ��u�0��^�eeg#d+�A-�䅜s�B�~w08>;�?�j-d4�*�f[�г��M�	k1<��\�\�O<��Z���3��[��G�:Z��u��J����Y��ڜU���5fa������&�ptq�����	��O��A�<���Ҽw=(�C)$�����ux��?)�<���p�N���UW�^�W���1ej�j�.���@QM�Ű�����:s"��	��*bj�R<�]�:��>Xh8��̺F�0�
��b��b]� }��4���XJ�	�����F����C�S�ZPWu�0K���S2��!iJSC���q8K�p>���(B�hN��o�ˁe%$-�����?�W4��H�z�gɼ�Jts]1�`����^m��34,�%z�v,|������3�i��G	�A����[fXiS1*�2Ѡ���1P~���� L~��<��=b�i7���i7
�v4*7N%��Qhµay`�+�92P�B~{K=t��b0�h[�����[\�=��(�?��C|���oC���e>���fȋ\����E�xL2�c"ŀ��w�G���&��)��zD��]�.�:�KBk�3�H�]sĎ�r����\�ؔ�L0���fq\��-��߅�����쯿64jǯ+p��A�.�d���cÑrT��&M4G@�M+O���+6��z��M��جU�z�_@�o��ǒ��͖�r�x��ךvk�ީ�������'������T�<�M��zk�)Ӭ�<x�Ŀ0�L�KsWMVws������+�H7)~�0{��H�����"�� %S�$^���~`.��������I@�����&,S+��v�~���8Zxmkγ9a�q�ܓ��]K�xX�k��(����]0���O��z��ۙw
}�B?w]�vw��gm�x_���z�[��{@�Ո��2�� 6M��q�����h��������ߊ*����*����*����*����*����*����*����*����*����*�3���cs P  