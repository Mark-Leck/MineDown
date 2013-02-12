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
‹ \½QíZéSãÆç³şŠ¶–âÈ[ùb1‰óØaÃUØ„l½MmÉÒØV4Š4Â8Çÿşºg4²lÌõö¨J=õ°Çsôİ¿©Z[ùâTGÚÙÙ¦ÿízñ¿¦•F³Qomoµê[¯p|§ÕÚZí•¯@i"ì`%°ãë‡æ=öû?”ªµÀ™Ë'á¶ÿö¶¶÷ÂÿF«¹³`ÿFãUk{ê_Óş1çâ¡yış¥•ÚÀk;/NĞöÑ`0…ôw8fÎµñ¢ÇŞh,&ŒşÂáåc
‹….LláŒ]>‚‰'ÆĞ;éí³XÀÇàŒÈ·bÃø¹{Ñ;:;İmlÕ›Ízck`8>C­Û¾oxCø¬nx.Xé&X!ƒ:üú=ˆ1ˆb/C0{NìE4Äivd’*ôã)¬'©ËA{ò:|M€İzÆĞ3Ô)°† ÅŒq;ÛóáW0ÔQ3†˜3æ`¾ød‰ÏX„,Ìï	^Œ‚L„Œ¹ 8x!z¡ïƒO#Ÿ‚Ë"T0%ğàpÌ'ûšA’ÆE²Ly
cû†á®7¶
F]²8d	Cæ‡x€ÏÏ!{Ó ;ÖOM#×löİšærk{€Æ*Ø*Mbi/'ıÜ+ö[²œnÜ·Y4¶Ÿ±M·ßË64—¼`¶°MøÓÈ]É²‚d4à·`æaä%¨{ÿñØ)ËK@ŸM…ç{	š}À1¨Oı+tÎ`Mô'8‡Ëˆ£A÷Ûà¡ÃÈ¸Co„^ànbP¢ 	e‡rjŸİb±$±GŒO+y
zœñÆ>T0ãh,c*®FÏ"
cxü™Áõ“É¤ª8©:<\$Ş(DuJ¡l”–å¼Úzw(ä,R¾Œc’%WXÂ®Ä}s!æ¤×
C~:ábö{Ê‘ Î\ À“t4Â!ôìD©Ğ ›zxOqÅ0úë	ª?wÃßøÿ/O~İ mÛ–?ü–zÎ4òHRcŸ‡è/mãmv¡Ñ	Ş¿}÷İÍ¬õâÑ·“ëñ·ÉÅxçÂiöoFÓ·Æ±œx<v®ZÍ¨ÓIİ÷½Û¤3<¼ØŸöŞußıÖpÓ 8¶êĞªC³nü-­3à©xÔ×æ¸6~®®fI×„FÛ³íô
¹ãBeÈªN¦U2E.¸¾G62˜Ÿ0ú¦MBYVí/—›Ë-ßıŒ’ÖlKï;vgf¿/j`Ê’“Ugæ=Úil²?Æ*æÑ1ºÅ€¡Ñó\t”¡tvœ)¼0ee‹˜¡[æû`&°áêèø˜jÏQÁ‚b ÉåZô.ÊX^2&GİËvzƒvkj»eEíXì÷B9›É&E]bÍS~Ÿ4’§\ÛÇLÎ\ôÚ½1çèßg?31ª>&/iô0­V«Îr¥*Fl¦8¸gí¸D+¦rOÈ'±ì²¡ú‚B7JdÈ…şÂùq·ÓëÂéY¿Û†ÎbîÀ”Jaï¡ô/q?üê`jC;ñ²€ŒÉı.º]øÆBDíZ’”È“TMÄSK}-šPô™§ló{p¹ÑÙÛ;»<íï®ndôÂ(RÊ¬îv©®Â{J—ŒÍŞÑ>„i0Àñóù¤ı³Ò)!É«eÛG6àhˆ(=ÿ Œ§	‹kÙäMÍûÖëµ4^¯5¡ùzmkó>ßË–íš«™L¦ÄEı³Ÿº§OOrÚIÅ˜Ç˜BŸ_³ğkË¶\4A¬ `R%ÖÁÅÙÉÓ–¹Øù˜#ú<}®ÕÔ‚äóË…@!@±Hm¬'ÉDQğ¹ræ‚”¶&<õ]#×*eáOÌ˜$ÚˆoTÌ!M04±zË8Zˆ@të?vzë”hj»“¹órø³‘—ÈT%!E¥²	Ïô[Á¥e•Ïö:}j$ª†õaêûëàbºpÇF!²…LÛ¢ ¡»£6Ôh¼&x-¯ùÜ‘y·öl†õJd[³›YïÇ‹nïÇ³ãı§;æe.	
b¼‰qÌ’1÷]bY:¥Ì¯™úuN°@ÿÒÖ"öÅhZ%ãQVúTµC,‡­AL>{ÙnÔëµ@á%&Oÿ®®À!Æ€Ì§‰±¨ÇÁ²A®T<—ü(¡Fû0lYÀy¤BH¹K–ìÕ
Š;iL£Q-tI;<@=:ÈÃ´ò\ŸÑº"×ÑZWF@º!îdî,xIÌÕÌïMÃx¿,ªI2é)ËòÉ‘œF!m’ıòˆ‘¡™a	Æõ†Ù<íOĞ5VSô/úØ;®¢·ÒßqâQÒyöxL!ñF¡ƒí¬BFËÕ
ÄÌ¾ş>"ÕÒ%Î¬b…İaŸ½¶¦•®æ†¤^&ÍÏ…Ÿ•‹VHñ—"ÕÜÊ¬šøúyº`ÎdxıĞtU„´lLİ•â=8)‹Š]Œ*•eŸÙ$ÏEõ=ÌZ9EÕ._Ëp_c˜œà%›à9èÊşıÇ’ÓcD›å¾„ùè•³µd&UÏ(­œ¥%tc'æòÏ<È½^_!X’
ôxÀ@&^ô\æ»˜L±FÏ†X‰éKİ7R‡ªšR{dËÁN˜	6ß¹Î¡ud–‚îŒİì.4\ÎHCâ;’ è.N Áï´^Í»4å	z?,8hıåÇl.É‡=©ß¼éö²;ˆ!§z@)[ïğ¦m«9/H|oÿ#%È{F-É¼|¹4sÃR¢^·ß?:=ì=±j)”Ïä¼fğÎ06¨4ZVâÄÓHÈ½–2\€	GşÁ:ƒ%p®ÑÚ;;E>.»¿{bmÊmb®jaÌ,ørMÎÓ‚±îj0×ÕÜğBkÏn#Â_~<éüò±sŒÀäãy÷b¯‹­Öşâ„Ë^÷cïıéŞÇ³·ïº{ıŞnÃ¨.MyV)ør>V³#Ïb·6K5GE/9ş˜[_²®nŠsqäŒûî<ºg•
,r¡0z¥¢±ìâ”Bû(Ó¾Q–\3	îÉÕ;şî¢ç`Ï9Q¥Rpñ¿çY—¼BL,úÙÈ1³ª!%ÌÅ²ˆ-Ÿ1&ä5È®J[õ;·ĞW_ÉdXÁï´¨˜¥#àC‚\=I2«>ît_·±pàÙOfu³Ù­‹c@£Éº¯,Gó¤228‚|Ñ
ÍCjt åËŠXì[Ø!04éÆ›ï^ñøZƒ˜»›Zó¼g¬›«Ù$¬‘X”FJ1?c´jE[p”rŞ>î”¡jæšZµyX ‡†À]óùû-S¬Ò©UAû”Íé~ÛöĞ•~ó³^LºêHÚ5ŠºbûÙ¬7êVı•UoÔ2€›Ô4¢©!
¯(œ‘Toß„†å‚yP€Hj¤ŸAõí-wÑ¬B‘ƒ)èMÛ
¡›ÍôıÀµårXƒU%ï,ğ³vñ¹/Í‡Ş†Âï¯—ÙDM%á\Tà=Ó2¥ÿ­Z2Š1b@ùşàèp¾êH4bÂ½ôMF3Œ G¤ßÖ¡ÑÄm;t˜oR!äx!5,×z¨§0Ñ‡l›êéƒ	¦YÕÇ,Ë«ÀÅAy§¼0¸XÁ .ºıİÕ7†nğë=-‰Nºª”dÂ_Á‹c/`K¨ÿ“MàJv€ÅÅÊÂzzGQªÈåÉNC&›•’>Óóÿ‹ngÿ¤[·âK>ÿoµ^İûşÇNk[=ÿÕhm7wèùÿÖÎ×~şÿúşÇ¬MS;¨Ğ…º1J>·é¡6<YOtãá·¶Q¸\/<«é%I]óó3j˜dû²÷S÷CÇ^˜ŞXHÔÓÆüxùÄp±ìA?fÈ<u'ãuÙ¢`>SW~ë³§{/óiúÒŠ:ÑËOr+ÆAêãI‚%ÿ¾Q}\Ğ…%ÂÊN˜‚/XÙRÌ×Õ–Z1{ÔÌ]„c¿¦’×ÈN²Qş®0 ¶48ÄA‰’z8ùIÚ,(Ã˜×¡?gUr§i,}ÿ§*ûÜ/üşÏ²øo6vZ:ş®´0ş›ÛôşWÿ_ùıŸ£¹ SÃ®D7¬Ùt
’|d½Lµ¹ıœeVa<ká'¬ü”¥Ÿ´ö¾ÅÙÕå2•HIâÓB£çD³Ä–¿ÖÛ›Fáú»£«¾e( å{ÏzŞ{@æòù ûô'ÎtÿsïØãòáÆü[S–©…Ë*=Ş·±|om˜óÓl?¡M?uU²¾«	½-š+Uá¢@Ş/‘gÏ—LÙ[¢MÇwá_·3ëäöú,º…^ê8ØİUîÿªÛÅëÚD0”Õ1/—z6ÖnºÕ‹^ê‚]¨ÑùËxzÍÕ\‘VcJü]RI%•TRI%•TRI%•TRI%•TRI%•TRI%•TRI%•TRI%•TRIŸBÿŒ22Î P  