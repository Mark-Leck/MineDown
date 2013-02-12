#!/bin/sh
# This script was generated using Makeself 2.1.5

CRCsum="2692784182"
MD5="b504d10c013206a2f3db73ec5e14b5b4"
TMPROOT=${TMPDIR:=/tmp}

label="MineDown Installer"
script="./minedown.setup"
scriptargs=""
targetdir="minedown_installer"
filesizes="3335"
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
	echo Uncompressed size: 12 KB
	echo Compression: gzip
	echo Date of packaging: Tue Feb 12 22:08:28 GMT 2013
	echo Built with Makeself version 2.1.5 on 
	echo Build command was: "/usr/bin/makeself.sh \\
    \"--gzip\" \\
    \"/home/mark/minedown_installer/\" \\
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
	echo OLDUSIZE=12
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
	MS_Printf "About to extract 12 KB in $tmpdir ... Proceed ? [Y/n] "
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
if test $leftspace -lt 12; then
    echo
    echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (12 KB)" >&2
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
� \�Q�Z�S���������[�b1��؍a�U؄l�Mm���V�4�4�8����g4�l����J=���s�ݿ�Z[��TG��٦����z񿦕F�Qomo��[�p|���Z�핯@i"�`%����=��?������'���������F���`�F�Uk{�_��1��y�������k;/N���`0��w8fε���h,&�����c
��.Ll�]>��'��;��X�����ȷb���{�;:;�ml՛�zck`8>C�۾oxC��nx.X�&X!�:��=�1�b/C0{N�E4�ivd�*��)�'��A{�:|M��z��3�)�� ŝ�q;���W0�Q3��3�`��d��X�,��	^��L��� 8x!z��O#���"T0�%���p��'��A��E�Ly
c���7��
F]�8d	C���x���!{� ;�OM#�l�ݚ�rk{��*�*Mbi/'���+�[���nܷY4����M���64��`���M���]ɲ�d4�`�a�%�{���)�K@�M��{	�}�1��O�+tΏ`M��'8�ˈ�A����ȸCo�^�nbP� 	�e�rj��b�$�G�O+y
z����>T0�h,c*�F�"
cx�����ɤ�8�:<�\$�(DuJ�l����zw(�,R��c�%WX���}s!��
C~:�b�{����\ ��t4�!��D�� �zxO�q�0��	�?w����/O~� mۖ?��z�4�HRc���/m�mv��	޿}�������ѷ�����x��i�oFӷƱ�x<v�Zͨ�I���ۤ3<�؟��u���p� 8��ЪC�n�-��3�x���6~��fIׄF۳��
��B�eȪN�U2E.��G62��0��MBYV�/���-�����lK�;vgf�/j`ʒ�Ug�=�il�?�*��1�ŀ���\t��tv�)�0e�e���[��`&������j��Q��b���Z�.�X^2&G��vz�vkj�eE�X��B9��&E]b�S~�4��\��L�\�ڽ1���g?31�>&/i�0�V��r�*F�l�8�g�D�+�rO�'�첡���B7Jd�ȅ���q�����Y�ۆ�b���Ja��/q?��`jC;������.�]��BD�Z���ȓTM�SK}-��P���l�{p����;�<��nd��(Rʬ�v���{J������>�i0��������)!��e�G6�h�(=� ��	�k��M����4^�5��zmk�>�˖횫�L��E�����OOr�IŘǞ�B�_��k˶\4A��`R%�����Ӎ�����#�<}��Ԃ��˅@!@�Hm�'�DQ��r悔�&<�]#�*e�O��$ڈoT�!M04�z�8Z�@t�?vz�hj����r�����T%!E��	��[��e����:}j$����a����b�p�F!��L�� ���6�h�&x-��ܑy��l��Jd[��Y�ǋn�ǳ���;�e.	
b��q̒1�]bY:�̯��uN�@���"��hZ%�QV�T�C,��AL>{�n��@�%&O����!ƀ̧������A�T<��(�F�0lY��y�BH�K���
�;iL�Q-�tI;<@=:�ô�\�Ѻ"��ZWF@�!�d�,xI����M�x�,�I2�)��ɑ�F!m��򈑡�a	����<�O�5VS�/��;�����q�Q�y�xL!�F���BF��
�̾�>"��%άb��a������憤^&�υ����VH�"��ʬ����y�`�dx��tU��l�Lݕ�=8)��]��*�e��$�E�=�Z9E�._�p_c���%��9����ǝ��c�D�径�蕳�d&U�(���%tc'���<Ƚ^_!X��
�x�@&^�\滘L�F�φX��K�7R���R{d��N�	6߹Ρud�����.4\�HC�;���.N ��^ͻ4�	z?,8h���l.ɇ=�߼���;�!�z@)[��m�9�/H|o�#%�{F-ɼ|�4s�R�^��?:=�=�j)���f��06�4ZV���HȽ�2�\�	G��:�%p���;;E>.��{bm�mb�ja�,�rM�ӂ��j0����Bk�n#���_~<���s����y�b�������^�c����ǳ��{��nè.M�yV)�r>V�#�b�6K5GE/9��[_��n�sq���<�g�
,�r�0z�����B�(Ӑ�Q�\3	���;����`ϝ9Q�Rp��Y���BL,���1��!%�Ų�-��1&�5ȮJ[�;��W_ɐdX�ﴨ��#��C�\=I2��>�t_��p��Of�u�٭�c@�ɺ�,G�228�|�
�Cjt �ˊX�[�!04�ƛ�^��Z����Z�g����$��X��FJ1?c�jE[p�r�>j�Z�yX ����]���-S�ҩUA����~��Е~��^L��H�5��b�٬7�V��Uo�2���4��!
��(��To߄��yP�Hj��A��-wѬB��)�M�
��������rX�U%�,�v�/͇ކ�ﯗ�DM%��\T�=�2���Z2�1b@����p��H4b½�MF3��G��֡��m;t�oR!�x!5,�z��0чl���	�Y��,�˫��Ay��0�X� .����7�n��=-��N���d�_��c/`K���M�Jv�����zzGQ����NC&���>����ng��[��K>�o�^����Nk[=��hm7w������~����ǬMS�;�Ѕ��1J�>��6<YOt�᷶Q�\/<��%I�]��3j�d���S�C�^��XH����x��p��A?f�<u'�u٢`>SW~볧{/�i�Ҋ:��Or+�A��I�%��Q}\Ѕ%��N��/X�R����Z1{��]�c������N�Q��0 �48�A��z8�I�,(Ø׍�?gU�r�i,}��*��/��ϲ�o6vZ:���0�����W�_������SÝ�D7��t
�|d�L����eVa<k�'������������2�HI��B��D�Ė����F�������e(��{�z�{@������'�t�s�������[S����*=޷�|om���l?�M?uU���	�-�+U�@�/�gϗL�[�M�w�_�3����,��^�8��U�������D0��1/�z6�n�Ջ^�]����xz��\�V�cJ�]RI%�TRI%�TRI%�TRI%�TRI%�TRI%�TRI%�TRI%�TRI�B��22� P  