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
‹ ¨QíZësÚÆ÷gıÅãÇ½ ;-½NBlâ:ñk ×Í\w2BZjI«J«`z›ÿı}	Á6ÍLgt>³:»{Şû;+êµ¿šH/wwù§ır·YşÔ´f·ìæŞÛníØ8şrÃîÚ7 <cN
°9éÍ}|=ÿ‡R½1ñè$ş{ı¿÷â…ö÷Â§½gï¼Ğşoîr>Û~±»·Íoéÿ”RvßCÏÿ¡ô¬Öqcèd¾ñìCáC†S8Åx‡âŞÏ:pŒ}6!ü/]Ã(¥1³HìÁÄa®ïÑ1LæCÿ´NHR#š‚;æ±•ÆOİ^ÿøülßn5[­¦½c¸!A£;ah#ø/¬oXù6X1&üò0ŸÄ$i³˜}7ú
†Ò<'î‘:Ò)lf¹GAò&\Ç¦@n¶1
¹K¬m'>.ç!ü†Üj&q}
æ³¯@¦‘…„$(Âüšğ.HQ‘	˜… Æ CpÀ¥y #ğH‚ö%±î].PøŒ@äÜÈò” Jƒ)ÍÁw>\õ³¢Ñ–$	ÃMâ˜¸, qî‘ókèŞ2ÀI˜5Æ]óÄs™}·¦…ŞÚ ³J¾Ê³TøËÍÓ°ˆŠ…õ–,'ØU‹%~²û„Å8»å†ZĞ0<ú©G/"[Ûğ?£%ËŠ²ñŞ‚YdQ¡íÃ‡S§”+Ïc6gAdèö!ÅœB9õSè\Ã†L‡Š„ãƒ®·Ec—pç‚1F·9‰
d|/'¬r‹iD²Ìx2Wy¤`Ä9˜ot’Hæ2¦"§Òºaôƒ(	§à£â@c ŸQœ?™LêR’ºK#!EŒc4§PÊAmI!«ãbtÇLpqã‹<æºËÃ™¸n¡ÄœöÚ`(O'BJ~ËIÆ2´™‡	 ¸a–Ç8„‘É-™Ü§nFs×¯Æ óc3CSãÿİøW:ÅÏåµ¯¡oÛbàÍ¯yàN“€kjÒã¥m¼À>ØèãÛ÷ßş®Ş“a:şnrã—õü—=·5ø<¾5Nã‰ï^íµ’ÁçNî}ìßfÑQïprÔß}ÿ«íåQt&ì4a¯	­¦ñE[gHsö`¬ÍImüT_W5×»	öîl9=C¬¸P‡g²®‹i»¢Hœßç>2H˜şM»„WY¹¾x.K>¼ Æ/Z³%ƒßÔ›-¨/Z`J²‹Ug=:hîÌU¬£>†Å`Œ0ò<”‘vädAœPÕ"%–Å:X	¸:>9ágMH3VÃÅ@—‹¹]¼b™Ïõ@­ôıÖÒ~S‡Úk°Èo¥ãl¦›Pu‰7Ïè*m„L…6Nˆ•œxµ>¥ßç¸0)š>åQÂ	˜èq^¯×K’F•‚<ÚMi´‚ƒ¯¸D‘+"kOL'¹ì‘‘“‡Œ§:nœ‰:Q(}ÃÅI·ÓïÂÙù Û†ÎbíÀ’ÊÓ>@íŸãzøÕÅÒ†~¢Cë½ëu»ğ|Æ’v£Á‹+ŠTƒ¥SK~-»PŒ™-–ædûğ¨Ñ988¿<ì¯o•tâ$gBKuîvù¹
y¹ì(1ûÇ‡çÑÇ‡$¤“6lJÂŠhäIÔX­Û!b°!E·@ÂËóX<ÏHÚPÌÛZöW6Ø¯6ZĞzµ±³½*öÔ´}s]éd
\48ÿĞ={”zBÒNÎ|šl
zCâo­ÛrÕºHµŞõÎOï4b>EôyöT¯É	Ù××B„jq]´³¥Ï²ˆy(«äekBóĞC0r#ÓPüÇë‰6â™sÇ#È3LM<½E-d HºÍ;ıM^h†r¹Ó¹ı
ø™’q‰R% E­¶OŒ[F…g¥NÎ:ŞG<Ö›£<7ÁÃrá2ŠBâ0Q¶¢àJwÇmhğñ£5Ş©+ênãÉë™(¶WyïÇ^·ÿãùÉáãó²—
b¾1?%™OC‹,‚RÔWe~}
gØ`|øÒ,¥èZ©ã±:úäi‡X[ƒ”ÇìeÛn6‘ÄKDìş}S‚CÌQO3bÑ	‚-ƒ‡Ry_Go4°Ã–¼”&2…d¸¨b/·PÔ˜8iÌÇ4ÕúˆtrF#´£‹2LkOm+:ÚêÒ	Hw!ÄÊ­j@µÁ\WqoÆÇe%P2‰¤Y–Õ“cÁÆSÚäş+2F¤¦ÂŒëŸ'Ğ5–,ú‰ŞöN¨è¥ôwd<Î@ÏMyJ¼–è`W‚ h¹Y¡DÃ”87?CÜ´üÓC•W¬¸d;ì³76ô ´ÕÜ°ËÓü÷BÙy®BµRÁ@ˆ¿©ÈæVTUµá«{øô9ÓáÕ}ìòÒº=Àº/Ô»—IeÅ¾FFµÚ²ÿX¤¨E%óİ/Z‘9eÓ.ŸËp_s˜Ás(7Ás(ĞıÆ7åA$ÂXUû2bTÎær7ÉóŒ—5gù~aÇæêÏ<È]	¯¯,'Yú4" 
/F.	=,¦xFAHFH”°ésİ7òU6¥ÎØ$*‚0ad¾sCë(,İJÜì.5\îXCâ;’¡ê2pÅï´^­»´V4K}a¹¢ÔíÂˆòJÏ‹±áuÛ0Öˆ^Òeeg#d+ºA-ã¼ä…œsÃBÖ~w08>;ê?‹j-d4²*àf[üĞ³¬ÌM§	k1<¤î\Â\ñO<ÜæZ¨ƒó3”ã²[Š¨G:Z‚ıu­‹JªâÁµY˜ôÚœUŸÇß5fa¶¹á…şÜ&íptqùé´óó§Î	¢OİŞAû<àúÒ¼w=(ŠC)$‹±†“¹uxÌ×?)»<¦ø°pµNŞ÷UWİ^ï¼W«Áâ1ej×j’.²”º@QMôÅ°šŒÎã:s"Ü†	¶Î*bjµR<™]È:±>Xh8ä ÄÌºF†0Ë
Ëâb…àb]İ }‹Ú4îô‘XJŠ	£›‹¿¨F‹ÜÿÖC„S«ZPWu0K€ŠŒS2»š!iJSCÔèq8K¿p>¡ªÂ(B•hN­ˆoÀËe%$-„ñ¶õú?ûW4½ÑHãz›gÉ¼ìJts]1™`Ùò£ú^m„ó34,¡%z¢v,|‡¸’‚¾Ä3µi‹ G	AûæÓ×[fXiS1*“2Ñ âÚõ1P~†‹óş L~‘µ<§Ê=b«i7­æ«i7
Ív4*7N%Èê·QhÂµay`¾+á92P¸B~{K=t«‚b0½h[â³™½ï¹[\=ğ€(à?ş¯C|îîÃoCéù«e>‘¬ÜfÈ‹\Á¦ŒşEâxL2c"Å€—îwÇGóˆ€&¬¤)šäzDèñ]ì.ã:±KBk˜3†Hü]sÄÉr£‡ú¸\ˆØ”¯L0Íò¨Şfq\Ü×-Š‹ß…ÁÅÃ ×ì¯¿64jÇ¯+p»‰Aº.dÂÀcÃ‘rT•ñ&M4G@¢M+O–¶ù+6¥zõ¾M´¢Ø¬Uôzÿ_@÷oşıÇ’÷ÿÍ–ır¯xÿ×švkÏŞ©Şÿó÷ÿÇò'Âœò­ü—ã¦úTì¼<…M¡ zk÷)Ó¬Ò<xÒÄ¿0ó¯LıKsWMVws§¨Ââì+H7)~ì0{¯üH°·Òı"¯â %Sù$^¹×Ó~`.çğÉÿàúÁI@ÅíæüÏ&,S+§Úvş~ÏÁó8ZxmkÎ³9aÆqÃÜ“íü]KèxX¢k°ï(µ¢åœ]0›·¢OıˆzğïÛ™w
}ÛB?w]Ävwûgm»x_“Éøzñ[ÀŠ{@ÅÕˆô2ùû 6MÈâ¯qôœ«€ùhäÅü¦¼­ÎßŠ*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ú3ô’ªcs P  