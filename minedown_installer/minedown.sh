#!/bin/sh
# This script was generated using Makeself 2.1.5

CRCsum="665671923"
MD5="8b6fb9bc56d9d86c83f25fc91323c9ba"
TMPROOT=${TMPDIR:=/tmp}

label="MineDown Standalone Installer"
script="./minedown.setup"
scriptargs=""
targetdir="minedown_installer"
filesizes="3630"
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
	echo Uncompressed size: 24 KB
	echo Compression: gzip
	echo Date of packaging: Thu Feb 14 21:05:29 GMT 2013
	echo Built with Makeself version 2.1.5 on 
	echo Build command was: "/usr/bin/makeself.sh \\
    \"--gzip\" \\
    \"/home/mark/MineDown/minedown_installer\" \\
    \"minedown.sh\" \\
    \"MineDown Standalone Installer\" \\
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
	echo OLDUSIZE=24
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
	MS_Printf "About to extract 24 KB in $tmpdir ... Proceed ? [Y/n] "
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
if test $leftspace -lt 24; then
    echo
    echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (24 KB)" >&2
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
� �QQ�Z�w�6���_1b���5u��뤊�$N}=I�����HHbM,	ZV���w HJ�|l����|�% ��oF�֞}q�#�no��H����F�Q�mn׷vvp|w�����}JbaG �"��}�z��jm����ϲ���6���l<�7[;�gP/����y����ZߎG��t�Ct�O�Ď��9���{Ñ�0�o/�`�@X,pabg��!L<1��Il�E<gH�Ə�N���t��Uo6�;���n����߰��`%�`���w F,0 ��@��:�
���� J�c �T�Ma5N\ړW�c` ���0�q�>�nb{>��p�$�M����`��|.7p�3�^B�e7� A6I��j�ɂ,�q0�2��g,D�g��7^�:�0sApd����'�π�e!چ��b�wO8G�cc��A�De�Ly#���7���A3�(`_�*p��C��aء����$tm����4�\�Li"���f�߫��1[[����-k����ӽe�v�?o �U"<ߋQ�}�~����B��^ȑ��p4h�~k<p)q�Q��:�Jӻ�@N�[�t�����U<�Eв6���l��G#��Q�0��8��0B���o�\?�L�����ǒ���S)��Ҳ�W�A/
��E�-C�d�3�+q�L���V0�����XĨ3��q2�zP�^*$�b
�8��a��WcT5~n��)�_���c������s��G��<@��3^�`�����y��]�g�h���z�m��v�f�f8}mˉ�#�r��nZ���{�o;��������4�d<~&l�a�ͺ�t�V�'�A_��������Euhl���rǹTYk 2gWu���)�|��d#��1�o�$�����\n����g��-�����7L��k`�� �B+��46����ݢ���y�eYrv�)� a$9�ꈡ[f�`:��������Ǣ�9�@�˵�]�h��#rԃt�Wh�����%s�k!��IQX�/�F�Ic��1��^{0����b&B�G�� ���$�j��Y�T�ȣ���̠r�T�	�d.�]6�_P��↱���8?n��m8=���5�;0�R�{(��_Lmh'�G�1�ߛN���H�p�V�$%�$U��R_�&����Ϭ�(a��n�]���W�
2zA�)ez������.[)�ݣC�q����=X����H	I�X-�!�>G�@H��{�c<�YTK'�k�7_�h@��&4_��\_�{�}s%��$���ڧ�Or�JĈG��B�_��k˶X4A��`R%֛���㍖����w8}��Ԃ��˅@a�b�,�X����l���ʩRښ��w�\�0�L�@`��$���b�h I���������A����]�D�W۝̼/�yz�LURT*��D�\ZV)����#��X5�^������|h��SDAB��{P���t��sG��ړ�+�m�nj�w�v�������b.
b��Q���]bY:�̯���)#�F���"�EhZ%c���M�#z`��"Ya�<Ҙ��B� (��	�i�	��n��e �s�`|�6 ����?�O(io����6��F}fp�N8s$��(9iL��aXw��Pŧ���$Q[)�kL�(�1u����ۉ�c4������T�Ԇ ��&UF��O�i���=�/Ҡ2�â��&���,JVGr���#G�)PQH_o����J6� [M�O�k3?T^����R�G1H=���+A�ӓV�S���G̾��X��Ϫ
S�%(�~�/����̐��ܤ��г�2�2.U=*t��˅�H��go�������LK���})Ľ���� �RY��M��VP���eqRT�^�)��B�0b��P��g �+KI�wJ.�g-"�4���G��ג���H��q����f//Eꗈ�ø]>��F9���.�e<��gl��.A��U��=�e-��`Q��-�g�?��{�n����3���N�e�Qt'��w����4��~xv���f}A��J�f����3���M	Z��j�0V��� ��RJJ���RL��t�~W�L��a)Y������>ki��d<���0�贵�؉���{	<�<r&�g}�p;8;E&.��{�q��\ђ�if���n�b�F���y5������_�Q�X2�	�d��`�A(k]՞s��w�d���%U�#svr|��󋫓�OW�c�gW���A<�"�	��U���������^w�aTf�lx6:.dy���X�=�����p�p|�E��Hu�3)�e�v�s֩T`����T4П�R��eb�q�5��ol�e�hB;�֬T
�c�u��0�Tia��O��Y�x�з,b˧����{���|/�RD�eB�;<�*�1�I�y�1.�8D.�o�ǝ��bs/<��,p��#���$�6R�����t4Oj#�S���<�֘^@iѲB��Om���_��<��(���:��,��:J�I�Cq|Y"�ʤ33�2D�n4V Z ��N):d�'���@�����[�X�S9��=��J"t�A}�'8?����FP�W��+��z�nշ�z��"���AZˈډ�Nq�v��Ѱ\0�P��(L}{�]4k
��`z�=����r}���]��0Of�~�.>�Z���������"����3��
\2-U��x'	T���2o#f��|�S��i�.�7�!A�K�-=�<[ gڟ��
��W�mY���<5�g(̗T�E�k~DU��7�U��B�}J!���hI4v���W����)|w����XQh��!A!��9z;�H2a}C��,3/��r��㹍9v�0��'B������S�Z�vU��1+���,c�I��o���f-L@�S��y��{�+�ݞ��K&�uEḯ��i�7�Rp�	�@7�2���5�N�Yߣ��l��h3v�#�X�P�S���甛c��3�2�P����0���H�~�����_�v��]��K�����Zv��Qo6�����͝fsW��������Ȣ���rV~�"�e��.�d�~��>���`�uv��=��sn�*FM/�3Ě}���Q�$ړ-Bu�{Ar[`!V�[���;*Ӑ���0fp8��N�/�#�j~�d#��K$p��e�eor+��`�@��5�7����'2,�(��.�X-$���D�"���p�lʯ�é�5�㴏(�+4�!uō�I����k�!����&��EHj�H�Ȟ�ƴw�H���*2��Qj4������s�  �'��n6vwt���inb�o�l�������ͤ{�`�4�t�:�N�0Ñi/���~�2�����V~��OZ�l���8�ؑ`W�w
}R'�ϰZG҄@Ȼ�n~��n��ɡ�lZ���]�5���~���?��=.5�W�-S���;h#R�]	5g��>u_�O\u.�Մ^��#()4�eӆ4�_^1ekm:s�q�['��g�-t�/-w����v���O992ҳ��o�zц�f8�]��k.g�����oI%�TRI%�TRI%�TRI%�TRI%�TRI%�TRI%}N�/RIA} P  