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
‹ I½QíZëSÛÆÏgıÇ
 7²- u/¤8””×`Sš¹éddim«HZUZaÜÇÿ~ÏÙÕÊ²1¯›4ÎÕù Öjç½¿³«zãÙ_NM¤íÍMùiñ¿üm·ìæ¶½±Õ²7°}{»¹ù6Ÿ}ÊRá$ ÏÎÅ}ızÿ¥z#ô#æñIôwÙßŞ²7Zóö·íW›[Ï YÙÿ/§çµÆÀ'ÏÑöÑ`0…c'¹‚#æ^Ï;päÆbÂè/\Â0á‘°XäÁÄîØã#˜øb½ã8Kyîˆ|+1Œ»ç½ÃÓ“ûU³ÕjÚ†0Tº†?„ÿÀÊšï•­ƒ1hÂÏß‚³È€8ñ#1³ç&~, D[Á€A’Eà¤@©C?™Âjšy´#¯Â‡È4 Ø/À6†¾±ß=ëí˜“1NâøÄãxÜ,	LƒØôÁ`…ú|7°›;†v¡á±ëF”!›€¤X}½ÀdIæ9˜Ï?™F0#÷ósÂ[?ALDŒy 8²şà€Ë³8`À‡à±MÃ"×g)Ü;'œ!ó)ƒĞ¹bf	C™SÁØ¹f8ëµ mĞ,‰˜ÀE¢ˆ¹ÂçQîáósÈŞ2'ÖWÍbÏ¬x´¦…ØæŠoJã¡¥=1ÿ~<g²µuøİ(ìnYa:ğ0G÷S”1xØ»KîüĞ­2á~Šêpt{tı:g‡ğB¶ô'Ø‡Ë˜ Fç[ã‘ËH‰C„ÚöÖ1lPŠ”Ör"ÙµÏnĞÓYš:#FVáDAË:|°P…¶&Òí“ºaôü0¦0FÁGÀ¯‘?™LêŠ“ºËCÉEê"Ô©ÊAiYÁ«ã¢EBö"ï–¡F²
K™À‘8o!ÄœôZaÈO'šBÂ~ÍX*RÔ™‡¸`šFØ„”ª%bå‚dXŒCÁ3w\3Œ>úájŠªÆßİè>ÅÿËÓS7DÛ¶eÃw¿d¾;}’ÔØç:MÛxÓßƒ°;áû7ï¾¹şõ/ß±A2úzr5ş:=oŸ»­şõhúÆ8’ÆîåV+î_w2ï}ï&íÎ÷'½wİw¿Ø^†`ÂF¶šĞjJgëx&ôµ9®ë+yZ4Án‚½9›N3.¤ÊXC)»®ó]LQä#ß#,H=i“P"TóË÷rr9åÃ¢ŸQr˜Méÿæ$ŞlÂüı¢¦,0)tfŞ£Æ!ûc¼b¾£[úÁ=Ï{IY–œ{
?ÊIN¹:aè–Å<˜¸<<:¢í à©¨aÎ7Ğär,zšøé˜u/Ÿé5Ú­¥ífÉœıZJæ3Ù¤¨K¬yÂï’FòTHã˜1™‡^»7æıûôb&AÕ'äå €eõz½ÄY¡TÅÈ£Í”„wô —rÉTî‰ød!–=6t²@P¨£âF©Ì…Ğ"8;êvz]89íwÛĞYÌ˜R)ì}”ş%Î‡.¦6´ È˜œïíy·ßÁXˆ¸İhP’E’jˆdj©Ç²É(Å£ è3k"ÉØºÜ­;{{§'ı•µ’Œ~gBJ™ïo]Ú¿à=¥ËNÎfïp¢,`û€|Ò†µ~‰Yé”dÕ²í#Lp4Ä”¿ƒÆ³”%¼óºæ}c÷…öî‹´v_l¬ßå{ù°s%—É$ËıÓº'OrÚÉÄ˜'¾˜BŸ_±èKË¶\4A¬ `R%ÖÛóÓãÇ-w±³1nïpòT«©éç—Bˆb‘,ÚX’‰¢,äråÜ)mMxxF®TÊ?%l 0_`’hƒa¨˜;B–bhâî-ãh!eĞ­~ßé­R¢¨éçÖ+`^ÂF~*S•„µÚ:<Ño—–U
8:İëô	ê?V«C„×«àaºpG,;B¦íQĞİQÔŞ¼‘·7îÊ¼Ûx2Ãz$²­ÙÍ­÷ıy·÷ıéÑşãó¢1ŞÄ8aé˜±,Ræ×\ızNk£ij‘øˆ…4­’ñ0ßúÔn‡X!xB>{Ñ¶›ÍF¨ğ“«ÓTàc@æÓT‚XÔcŒ`Ù W*¯K~” ÇR	Kğ«Rî’'{µ„‚¢ÆÄI"jÓhTË#]ÒÉQ.ò0­=Õg´®Èu´Ö•nCˆ[™;Ï~ÚÆ ÷{Ó0Ş/Kª“ÌAºË²|r(»QH›d¿"bdhæXBq=aŞOûtƒUıF/{ËUôTú;¦ g'¯:ØÌ7A]ê,W+”h0çêÛrm$«IŠ¨¤;ø^¼ĞJWsMR/æŸaç{¢•Bü¥HE‘2«æîŞÓOo˜3vïë®6!-Û]w¤x÷vÊ£bG#£ZmÙ¯&)rQI}÷³VDNYµË‡À2Ü×Á&'x	å"xz²şCÿñ¦äô¸A"ŒÍs_ÊôÊÙX2“ÚÏ(­œ¥!t¦&æòÏ<È½^_"XÓôxÈ@&^ô\x˜Lq‚€°0Ó—ºn¤
U¥ÎÈ‘$
‚•0l¾rCëÈ,İ9»3Ø]*¸Ü‘†Ä·*$'DÑ=ì@‚ß*½Z·hÉô|¸á õ—/³¾$ö¤~‹¢ÛÏÏ †œöJÙz†×mÃX)€|Iâ;ë)AQ3jIæå+¤™k–õºışáÉAïñˆUK¡|¦à5‡w†±F[£e¥n2…œKàVæ“0áÊ?¸Ïà8Whí İ’ß=ro*lb®haÌ<ø
MÎÓ‚±nk°ĞÕ\óBiÏnbÂœ]|<îüô±s„ÀäãY÷|¯‹¥îıå½îÇŞû“½§oŞu÷ú½Û¨/M®EV)ùrÑÖpbßb7K=Çe/ˆ8¾,¬/YWg¹…8²Ç]gİóóÓóZWˆ¸P½VÓXv±K©|”iHúJ®™÷äê©J÷Ğs°æÎ¨V+¹øŸó¬K^G&}›ä˜Y×fbYÄV@ÈòÈ$·š·N{/5¾’!Ép¿U¢b–9‚/	pQ`ô$ÆÈş­8Ó]ÕÆÂ‚§?˜%nPÔQÂf§>,Ixbä @Œ*ËQ?©Œ _Ô„Bó(˜Z!-@9Ä²b–VMºöúß;—<¹Ò æÃÎ:…Ö<ï9ëæJŞÉk$–£€{¥‘RÌ÷˜m…ZÑV%eì·3å¨šy¦VmÈ¡¡#pÇ|ú|Ë«t*[UP'eó,AïöĞ•~‚³Ó^L:êHÛŠºrùÙjÚM«ùÊjÚà¦hˆÂÇ
g¤õ›00áƒay`¾-A$ÕÒÏ!‹zzÃ=4kPdczÒ¶‚@èf3}ßsl¹Öà®RTø[»øÜ/Í‡Ş†Òûİe6Q]IgØxG·\éªƒŒbL†P¾{x0¿ëH4bÂôUN3Œ [¤_7Áná4®¹,°™òßú,Wº©§0Ñ‡l›êöÁÓ,·êeÛåQàb£<S^h\ÜÁ Î»ı•×†.ğñ’ÀD']QJ2á?`‰Å±–I°¥TÿI‡&p%+Àò`ea›.Ø(JõùmÛìæYEÿˆûÿóngÿ¸[7â¯¼ÿßzõê®ï?ìfË–÷ÿ[Û[­Ö¶¼ÿonW÷ÿ_‚~dIJgØêr~PºhË¯YÑ“:¤ÊÇwèk¬¼»öñ©m”ÎóKwq=$-zñãc±Fóz_–›êHêÈ²›©ºà,–——”Ó˜å×ÿ˜”‹İ"¯ÊªS¨:e\](¾,ºés2*~¬XÉ«o³ W,%Äù•*“ÎHQBD]p3Íp‹¨Û¸ÛÑˆâVÚå"Àœ_—ÇSÉkì¤yM*ß+ØÕG±&Q¢dÆ„îC5d¡(Ù@j’n-ºAlh#5gÒiîd™RK:1æUdèßùşKYÛ¬Òöÿ[şŸyÁ¿áû¿–½½¥óÿ«­}ÿÕÚÚhVùÿ‹ÿu8—îu‚¹Uóêã¼;åÃÚæ•r½µù”aVi<ià'Œü”¡Ÿ4ö®ÁùÁø\İ#q¸¬~JÇn<ÛÃYšHöºQºÀÚ»¨@Ÿa•j±;×zÚ×\æòş OÙÿÁùÏü#ŸË«³ùoß,S—ƒúxÄA¤.|dÎws‚”&qƒÌSûòmMèê£@%¥c(yzIœİ^šòäm:¹ÿº™Y§°×gÑ-ô2×Åêş¶rÿWİ.^¤j¡B2Ò½¦Ñ¹»ôRc³+¾ÆÔc.çğ˜ºì«ößŠ*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢Š*ª¨¢O¥ÿCcé P  