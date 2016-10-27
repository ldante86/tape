#!/bin/bash -
#
# SCRIPT: tape
# AUTHOR: Luciano D. Cecere
# DATE: 11/19/2015-01:43:36 PM
########################################################################
#
# tape - Convert text to 8-bit punched tape
# Copyright (C) 2015 Luciano D. Cecere <ldante86@aol.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
########################################################################

export PATH=/bin:/usr/bin
unalias -a

########################## DEFINE GLOBALS ##############################

PROGRAM="${0##*/}"
PIN="."
HOLE="o"
EDGE_LEFT="|"
EDGE_RIGHT="|"
EDGE="___________"
C_EDGE=0
SHOW=0
VERBOSE=0

CHARS=(	\! \" \# $ % \& \' \( \) + \, - . /
	: \; \< = \> ? @ \` \{ \| \} \~
	\[ \\ \] \^ _

	{0..9} {a..z} {A..Z})

# ASCII table of the above array.
DEC=(	33 34 35 36 37 38 39 40 41 43 44
	45 46 47 58 59 60 61 62 63 64
	96 123 124 125 126 91 92 93 94 95

	48 49 50 51 52 53 54 55 56 57

	97 98 99 100 101 102 103 104 105
	106 107 108 109 110 111 112 113
	114 115 116 117 118 119 120 121 122

	65 66 67 68 69 70 71 72 73 74 75
	76 77 78 79 80 81 82 83 84 85 86
	87 88 89 90)

BITS=( 0001 0002 0004 0010 0020 0040 0100 0200 )

USAGE="\
PROGRAM: $PROGRAM
DESCRIPTION: Convert text to 8-bit punched tape
AUTHOR: Luciano D. Cecere
LICENSE: GPLv2 (2015)
	
USAGE:
 $PROGRAM string
 $PROGRAM -d file
 $PROGRAM -d -v file
 $PROGRAM -h
 $PROGRAM -t string

FLAGS:
 -d --decode [-v] file    Decode from file.
			  Pair -d with -v for verbose output.
 -h --help                Show this help and exit.
 -t --show-text string    Print character next to row.

CAVEATS:
  The '*' (52) character is ignored.
  Encoding is a lot slower than decoding.\
"

########################## DEFINE FUNCTIONS ############################

# _putchar and _getchar are shell equivalents of the C language versions.
_putchar()
{
    for (( g=0; g<${#DEC[@]}; g++ ))
    do
      if [ "$1" = "${DEC[g]}" ]; then
        echo -n ${CHARS[g]}
        break
      fi
    done
}

_getchar()
{
    for (( g=0; g<${#DEC[@]}; g++ ))
    do
      if [ "$1" = "${CHARS[g]}" ]; then
        echo ${DEC[g]}
        break
      fi
    done
}

_decode_row()
{
    if [[ $1 != *[o]* ]] ||
       [[ $1 != *[\|]* ]] ||
       [[ $1 != *[.]* ]]
    then
      return
    fi

    if [ "$1" = "$EDGE_LEFT  $HOLE  $PIN   $EDGE_RIGHT" ]; then
      if [ $VERBOSE -eq 1 ]; then
        echo  "	32	$EDGE_LEFT  $HOLE  $PIN   $EDGE_RIGHT"
      else
        echo -n " "
      fi
      return
    fi

    if [ "$1" = "$EDGE_LEFT    $HOLE$PIN $HOLE $EDGE_RIGHT" ]; then
      if [ $VERBOSE -eq 0 ]; then
        echo
        return
      fi
    fi

    P=()
    for (( i=${#1}; i>=0; i-- ))
    do
      if [ "${1:i:1}" = " " ]; then
        P+=(32)
      elif [ "${1:i:1}" = "$EDGE_RIGHT" ] ||
           [ "${1:i:1}" = "$PIN" ]
      then
        true
      else
        P+=(111)
      fi
    done

    c=0
    for (( e=0; e<8; e++ ))
    do
      if [ ${P[e+1]} -ne 32 ]; then
        echo $((c |= BITS[e])) >/dev/null
      fi
    done

    [ $VERBOSE -eq 1 ] && echo -n "  "

    _putchar $c

    if [ $VERBOSE -eq 1 ]; then
      echo "	$c	$1"
    fi
}

_decode_file()
{
    if [ "x$1" = "x" ]; then
      echo "Missing filename"
      exit 1
    elif [ ! -f "$1" ]; then
      echo "Cannot read $1"
      exit 1
    fi

    if [ $VERBOSE -eq 1 ]; then
      bar=" --------------------------"
      echo "$bar"
      echo " char  decimal  row"
      echo "$bar"
    fi

    while read
    do
      _decode_row "${REPLY:0:11}"
    done < "$1"
    echo "$bar"
    exit
}

_encode_stdin()
{
    trap 'echo $EDGE && exit' INT
    C_EDGE=1

    echo $EDGE
    while read
    do
      _encode_row "$REPLY"
      echo "$EDGE_LEFT    $HOLE$PIN $HOLE $EDGE_RIGHT"
    done
}

_encode_row()
{
    STR="$@"

    [ $C_EDGE -eq 0 ] && echo $EDGE

    for (( i=0; i<${#STR}; i++ ))
    do
      if [ "${STR:i:1}" = " " ]; then
        echo "$EDGE_LEFT  $HOLE  $PIN   $EDGE_RIGHT"
        continue
      elif [[ $char = *[\*]* ]]; then
        continue
      fi
      _print_row "${STR:i:1}"
    done

    [ $C_EDGE -eq 0 ] && echo $EDGE
}

_print_row()
{
    echo -n $EDGE_LEFT

    for (( t=7; t>=0; t-- ))
    do
      if [ $t -eq 2 ]; then
        echo -n $PIN
      fi
      if [ $(( $(_getchar $1) & ( 1 << t ) )) -ne 0 ]; then
        echo -n $HOLE
      else
        echo -n " "
      fi
    done

    [ $SHOW -eq 0 ] && echo $EDGE_RIGHT || echo $EDGE_RIGHT$1
}

########################## END OF FUNCTIONS ############################

########################## PROGRAM START ###############################

case $1 in
  -[Hh]|--help)
    echo "$USAGE"
    exit
    ;;

  -[Tt]|--show-text)
    SHOW=1
    shift
    ;;

  -[Dd]|--decode)
    shift
    case $1 in
      -[Vv]|--verbose)
        VERBOSE=1
        shift
        ;;
    esac
    _decode_file "$1"
    ;;
esac

case $# in
  0)  _encode_stdin "$@" ;;
  *)  _encode_row "$@" ;;
esac

################################ EOF ###################################
