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
‹ ™QQíZéwÛ6Ï×å_1b¼±İ5uùêºë¤Š­$N}=I®›·éó£HHbM,	ZV·ıßw HJ–|l¾¾å|°% çÆoF¨Ö}qª#ínoËÿHóÿåçF³Qßmn×·vvp|w·±õ¶Ÿ}JbaG Ï"ÎÅ}ózş¥jmìÌå“àÏ²³±‰6Ïìßl<«7[;gP/íÿÅéy¥Ö÷‚ZßGÆót…CtèOáÄ®á˜9×Æó{Ã‘˜0úo/`ñ@X,pabgäò!L<1‚îIlŸE<gH¾ÆíN÷èìt¿±Uo6ëÍ¾áøµnû¾áàß°²æ¹`%ë`êğów F,0 Œ¼@Àì:‘
£± Ï J°c “T¡Ma5N\Ú“Wác` ìÖĞ0qØ>ïî›“nb{>„£pœ$òMƒøôÀ`…æ|.7pš3‚^BÍe7µ A6I±újÉ‚,Ìq0Ÿ2Øg,Dîg÷„7^„:˜0sApdØ÷Á‡'¡Ï€Àe!Ú†Çb¸wO8GæccûšAœDe²Ly#û†á®7¶¶A3°(`_Ì*pŸŸCö¦aØ¡°†øÖ$tmÁ²¯Ö4Û\ñLi"´´Ëfàß«³İ1[[‡ÿ™İ-kûüÌÌÓ½eôvï‚?o ºU"<ß‹Q½}~ ŸBëü^È‘Şçp4hã~k<p)qàQÛî:ÆJÓ»ì@Ní±[ôtÇö‘U<‘EĞ²6†ïûl¬âG#éöQÕ0ºŞ8ô§0BÁÀo\?™LªŠ“ªÃÇ’‹Ø¨S)”Ò²ŒWÛA/
„œEŞ-CdÉ3+qßLˆéµÂŸV0…ˆıš°XÄ¨3ğ…q2âzP¬^*$Ãb
8£ŠaôĞWcT5~n¿ğ)ş_œŸÚc´íøş—Äs¦¡G’‡<@§Ù3^÷`­ñ‡×ïÿyóë]¾gıhøíäzômÜívœfïf8}mË‰Ç#çr§önZ‰û¡{·o;‡“·İ÷í÷¿4Üd<~&lÖa§Íºñ‡t¶VŸ'âA_›áÚø±º’æEuhlçÛérÇ¹TYk 2gWu¾«’)²|„ë»d#ƒù1£oÚ$”Õşò¹Ü\nùğ†èg”ò-½ßìÈÍ7LŸÏk`Êâ “B+÷í46ÙãóÕİ¢ÏĞèyîeYrvœ)¼ a$9åêˆ¡[fû`:°áòèø˜ŸÇ¢‚9ß@“Ëµè]¸hâÅ#rÔƒt§Wh·¦¶›‘%sök!™ç²IQXó”/“Fò”Icû˜1™‹^{0âıûìb&BÕGäå €$ÕjµÀY¦TÅÈ£Í—Ì rÉTî	ød.–]6°_P¨£â†±Ì™Ğ8?n·ºm8=ëµ÷ 5Ÿ;0¥RØ{(ıî‡_Lmh'ŞG1¹ß›N»ßÃHˆp¯V£$%²$UÑÔR_‹&£‚ Ï¬‰(aëò´nœ]œööWÖ
2zA˜)ez¾µéü‚”.[)›İ£C’qÇûÌç“=Xë˜•ŞH	IæX-Û!â¤>G³@Héù{˜c<‰YTK'¯kŞ7_¾h@ãå‹&4_¾Ø\_æ{é²}s%•É$Ë½³Ú§OrÚJÄˆG˜B_³àkË¶X4A¬ `R%Ö›ÎÙÉã–ºØùw8}ªÕÔ‚øóË…@aŒb‘,ÚX’‰¢lÌûäÊ©RÚšğÄwŒ\«0”LØ@`¾À$±†¡bîh IŒ¡‰§·Œ£¹”A·ú®Õ]¥DÓWÛÌ¼/ƒyz±LURT*ëğD¿\ZV)àøì Õ#¬ÿX5¬^¯‚‹éÂ±|h™¶SDAB·‡{P£ñšàµt¼æsGæİÚ“Ö+‘mÍnj½wv÷İÙñáãób.
b¼‰QÄâ÷]bY:¥Ì¯©úõ)#ÖFÿĞÖ"òEhZ%cËÇØM†#z`ûˆ"Yaª<Ò˜‰ÔBåª (Áˆ	åiî¶	…Ànıï„e èsó‚`|Â6 æéùš?“O(io×“Ãæ6µF}fp·N8s$ı´(9iLÕÖaXw€ñPÅ§òÅô$Q[)œkLì( 1uµ²¤¿Û‰àc4’ƒ§ÿ´òT‡Ô† ¿Ô&UFº‹Oîi‚ñâ=¬/Ò 2ãÃ¢üª&É§§,JVGrå“œ#G÷)PQH_o˜ÎÓÎJ6Õ [MÑOôk3?T^•û£ŞRÇG1H=àÅİ+A¶Ó“V×S‹ÕêGÌ¾ş®X€ÉÏª
S¨%(è~†/ô ÒÙÌÔÏÜ¤Ùï™Ğ³³2Ñ2.U=*tºíË…àHÍÓgoÎéËû¦«óLKğÀÔ})Ä½“ÒØ× «RYôéM²´VPÒı¬eqRT ^‘)˜¹B¶0bÉÔP¬§g ¥+KIôwJ.g-"â4ÆÌGßË×’™ÔÑH’qğŠÙf//Eê—ˆ»Ã¸]>ÆüF9ı“ù.æe<îÀglŠé†.A©ØUõ­=´e-Š‚`QÍ›-‚g€?²ñ{Ênàµ›3ÔèúN±eQt'àwª¸æİ4åô~xv¡õ¿f}AöëJıfõ»—¶3ÜÇôM	ZïğjÏ0V²š  ñÒRJJ•ŸRLîÑt¿~WÎLª™a)Y·İë¾í>ki”ïd<§ˆÑ0Öè´µ¬Ø‰¦¡{	<À<r&ùg}®p;8;E&.Úç{äq”Æ\Ñ’˜ifêÌÃnÎb¹F¤…Íy5ÉÁÜÁÌ©_óQ¦X2ò	Ød‰‹`ï¨A(k]ÕsñôwÌd„è¦Õ%Uí#svr|İÛó‹«“ÖOW­c„gWçíÎA<„"Å	İöU÷ÃéÁÕÙë÷íƒ^w¿aTf®lx6:.dy²ÙXÍ=‹İÚşÕp•p|˜E¦”Huº3)åŒe¡v§sÖ©T`şª€©T4ĞŸŸR¨­ebÕqÉ5“•ole»hB;ÖÖ¬T
ùc–uÉë0ÀTiaáâO‹YÕxòĞ·,bË§²˜ {À¸ë|/üRD™eB;<Ú*äˆ1ºIÂy‰1.Ä8D.ğoÕÇ–Õbs/<ûÁ,pƒ²#–÷Ä$°6Rô¢ÛÆÊt4Oj#ÅSÈ¡Ô<ğ§Ö˜^@iÑ²BùÖOmºöê_û—<ºÖ(ìãş:ùÿ,ïë:JÓI§Cq|Y"Ê¤33ò2DÁn4V Z çâN):dê¤'ö²¸@™ûæÓ÷[¤X¥S9ª‚=òé€J"t¯A}é'8?ëöÀ¤FP¼W£°+çÍz£nÕ·¬z£–"ô¸¦AZËˆÚ‰‚Nqõvì›ğÑ°\0ßPŸé¥(L}{Í]4k
ºä`zÓ=…êĞÍr}ßÓÔ]ŒÔ0Of¥~Ö.>ƒZ¤ùĞÃ÷ ğüå"›¨©¤3œ‹
\2-UºÒx'	T›÷ê2o#f­á¬|ÕSæ»êiÛ.è7Î!Aí¢KÒ-=ş<[ gÚŸœÍ
Ÿ©WÕmY¡‚<5âg(Ì—Tå„Eî¯k~DU­ê7§Uí½ÿBš}J!´øĞhI4v••Wò´£ø’¦)|w¯Úà XQhà€!A!¾9z;²H2a}C”—,3/¥r¾­ã¹9và0ßê'BàãŒë„öÆSïZvU½ö1+÷Íù,c‚Iéôoæ½úÈf-L@éSıy×è´{û+¯İÀ¯K&êuEiÍ„ß‡i¼7¢Rp‚	ƒ@72Š‹•5èN½Yß£àŸl¯Üh3vÓ#÷XëPéSÉßÃç”›cóã3Ş2ÿPşÚù—0“¢ôHá~À³’²û_vëğ¤]·âKŞÿÚÙÚZvÿ¯Qo6äı¯İÍfsWŞÿªï–÷¿¾ıÈ¢˜›úrV~Ï"½eƒ‡.ıd«~£œ>·é‰`ºuvãá·=£ğsná*FM/‰3Äš}¸ÊŞQÃ$Ú“-BuŠ{Ar[`!V÷[²×Ë;*Ó¥·¿0fp8­ÊNÁ/ù#Ój~Ÿd#›†K$p¢†eŸeor+Æê`€@„‡5õ7ªİé'2,ñ(ë Æ.úX-$˜«D´"»”äpÁlÊ¯ÃÃ©ä5´ã´(Ÿ+4æ!uÅÀI‰’º£k¢!Š’ô¥&é‰EHjÚHµÈÔÆ´w´H©³*2ôçQj4ËÔøÿ–ÿs  ÷'Üÿn6vwtşßÚinbşoîlÖËüÿÕïÿÍ¤{`î4õt÷:Nù0Ã‘i/°ÚÜ~Ê2«°´ğV~ÊÒOZ»l±¼ú8×Ø‘`W¶w
}R'ÌÏ°ZGÒ„@È»±n~¶ŠnƒşÉ¡ĞlZú®§]æ5Ïİç~äü÷?÷=.5³WŸ-S—‚º;h#RÏ]	5g§Ù>u_ÇO\u.ßÕ„^¡î„#()4ÚeÓ†4˜_^1ekm:sşq›['³×gÑ-tÕ/-w•û¿êvşÜâO992Ò³¦Ño¥zÑ†Æf8–]Æ×k.gğ˜êú”çoI%•TRI%•TRI%•TRI%•TRI%•TRI%•TRI%}Nú/RIA} P  