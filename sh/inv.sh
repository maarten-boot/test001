#! /bin/sh
# =======================================
# =======================================

# NOTES:

# use CAPITALS for all global vars
# use functions to isolate and use local vars as much as possible
# use WITH_<OPTIONFLAG> style
# use guarded commands with if or [ style and explicit test for 0 or 1
# use rcs for individual file versioning
#
# further docs are at the bottom of the file
# =======================================

THIS=`basename $0 ".sh"`
HOST=`hostname`
ME=`id -un`

# <<<<<<<<<<<<<<< START OF CONFIG >>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<< START OF CONFIG >>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<< START OF CONFIG >>>>>>>>>>>>>>>>>>
# ---------------------------------
# this section is special , only change the next line not the rest
WITH_DEBUG=0

[ "$WITH_DEBUG" = 1 ] && {
        DBG="set -x"
}

$DBG

# ---------------------------------
# other options

WITH_VERBOSE=1

WITH_EMAIL=1
WITH_DOKUWIKI=1
WITH_RCS=1

# ---------------------------------

MAIL_TO_ADMINS="root"

# ---------------------------------
# dirs and files

LOGDIR="."

LOGFILE="$LOGDIR/_$THIS.log"

CHANGE_LOG="$LOGDIR/_$THIS.changelog.last"
CHANGE_HIST="$LOGDIR/_$THIS.changelog.history"

# <<<<<<<<<<<<<<< END OF CONFIG >>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<< END OF CONFIG >>>>>>>>>>>>>>>>>>
# <<<<<<<<<<<<<<< END OF CONFIG >>>>>>>>>>>>>>>>>>
# =======================================
# =======================================

test_rcs()
{
        [ ! -d RCS ] && mkdir RCS
}


# =======================================
# =======================================

report_settings()
{
        $DBG

        [ "$WITH_VERBOSE" = 1 ] && {
                echo "
THIS    = $THIS
HOST    = $HOST

VERBOSE = $WITH_VERBOSE
EMAIL   = $WITH_EMAIL
DOKUWIKI = $WITH_DOKUWIKI
RCS     = $WITH_RCS

ADMINS  = $MAIL_TO_ADMINS
"
        }
}

dw_start()
{
        $DBG

        local msg="$1"

        [ "$WITH_DOKUWIKI" = 1 ] && {

                echo "===== $msg ====="
                echo
                echo "<code>"
        }
}

dw_end()
{
        $DBG

        [ "$WITH_DOKUWIKI" = 1 ] && {
                echo "</code>"
                echo
        }
}

# =======================================
# =======================================

ps_reduced()
{
        $DBG

        dw_start "PS (reduced)"

        local ty=`
                tty |
                awk -F/ '
                {
                        printf "%s/%s\n", $3, $4
                }
                '
        `

        ps -ef |
        grep -v "]$" |
        awk -v TY=$ty '
        # skip my own processes
        $6 == TY { next }
        {
                $2 = $3 = $4 = $5 = $6 = $7 = ""
                print
        } ' |
        sort -u

        dw_end
}

listen_netstat()
{
        $DBG

        dw_start "LISTEN (netstat)"

        netstat -an |
        grep "^tcp" |
        grep LISTEN |
        awk '{ print $1, $4 }'

        dw_end
}

listen_lsof()
{
        $DBG

        [ "$ME" != "root" ] && return

        dw_start "LISTEN (lsof)"

        lsof -n -P -i TCP |
        grep LISTEN |
        awk '{ $NF = $2 = $4 = $5 =$6 =$7 = ""; print}' |
        sort -u

        lsof -n -P -i UDP |
        grep -v -- "\->" |
        awk '{ $2 = $4 = $5 =$6 =$7 = ""; print}' |
        sort -u

        dw_end

}

dmi()
{
        $DBG
        [ "$ME" != "root" ] && return

        dw_start "dmidecode"
        dmidecode
        dw_end
}

iptables_show()
{
        $DBG
        [ "$ME" != "root" ] && return

        dw_start "LocalFirewall (iptables)"
        iptables -L -n
        dw_end
}

# =======================================
# =======================================
main()
{
        $DBG

        test_rcs

        # the following scripts can run as non-root
        ps_reduced
        listen_netstat

        # the following scripts MUST run as root
        listen_lsof
        dmi >dmi
        iptables_show
}

main |
tee "$LOGFILE"

[ "$WITH_RCS" = 1 ] && {
        rcsdiff -q "$LOGFILE" |
        tee "$CHANGE_LOG" |
        tee -a "$CHANGE_HIST"

        ci -q -l -t-"INITIAL CHECKIN" -m"$HOST:$THIS:modifications at: `date`" "$LOGFILE"

        [ -s "$CHANGE_LOG" ] && {
                cat  $CHANGE_LOG | mailx -s "$HOST:$THIS:changes" $MAIL_TO_ADMINS
        }
}

[ "$WITH_EMAIL" = 1 ] && {
        cat $LOGFILE | mailx -s "$HOST:$THIS `date`" $MAIL_TO_ADMINS
}

exit 0

# =======================================
# =======================================
# DOCS:

/*
this part is never parsed by sh,
so you can use free style text editing,
preferred format: dokuwiki
*/

inv.sh

runs a series of commands and produces a output file, possibly in dokuwiki format

it also puts the output file in RCS version control and after each run it looks for differences between the last run and the current run using the RCS repository.

If the output of trhe script produces no dated info but ony show the bare running profile , you can use rcs to detect changes in critical system components

