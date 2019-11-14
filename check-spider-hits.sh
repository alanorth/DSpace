#!/usr/bin/env bash
#
# check-spider-hits.sh v1.0.3
#
# Copyright (C) 2019 Alan Orth
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Exit on first error
set -o errexit

# defaults
readonly DEF_SPIDERS_PATTERN_FILE=/dspace/config/spiders/agents/example
readonly DEF_SOLR_URL=http://localhost:8081/solr
readonly DEF_STATISTICS_SHARD=statistics

######

readonly PROGNAME=$(basename $0)
readonly ARGS="$@"

function usage() {
    cat <<-EOF
Usage: $PROGNAME [-d] [-f $DEF_SPIDERS_PATTERN_FILE] [-p] [-s $DEF_STATISTICS_SHARD] [-u $DEF_SOLR_URL]

Optional arguments:
    -d: print debug messages
    -f: path to file containing spider user agent patterns (default: $DEF_SPIDERS_PATTERN_FILE)
    -p: purge statistics that match spider user agents
    -s: Solr statistics shard, for example statistics or statistics-2018 (default: $DEF_STATISTICS_SHARD)
    -u: URL to Solr (default: $DEF_SOLR_URL)

Written by: Alan Orth <a.orth@cgiar.org>
EOF

    exit 0
}

function parse_options() {
    while getopts ":df:ps:u:" opt; do
        case $opt in
            d)
                DEBUG=yes
                ;;
            f)
                SPIDERS_PATTERN_FILE=$OPTARG

                if ! [[ -r "$SPIDERS_PATTERN_FILE" ]]; then
                    echo "(ERROR) Spider patterns file \"$SPIDERS_PATTERN_FILE\" doesn't exist."

                    exit 1
                fi
                ;;
            p)
                PURGE_SPIDER_HITS=yes
                ;;
            s)
                STATISTICS_SHARD=$OPTARG
                ;;
            u)
                # make sure -s is passed something like a URL
                if ! [[ "$OPTARG" =~ ^https?://.*$ ]]; then
                    usage
                fi

                SOLR_URL=$OPTARG
                ;;
            \?|:)
                usage
                ;;
        esac
    done
}

function envsetup() {
    # check to see if user specified a Solr URL
    # ... otherwise use the default
    if [[ -z $SOLR_URL ]]; then
        SOLR_URL=$DEF_SOLR_URL
    fi

    # check to see if user specified a spiders pattern file
    # ... otherwise use the default
    if [[ -z $SPIDERS_PATTERN_FILE ]]; then
        SPIDERS_PATTERN_FILE=$DEF_SPIDERS_PATTERN_FILE
    fi

    # check to see if user specified Solr statistics shards
    # ... otherwise use the default
    if [[ -z $STATISTICS_SHARD ]]; then
        STATISTICS_SHARD=$DEF_STATISTICS_SHARD
    fi
}

# pass the shell's argument array to the parsing function
parse_options $ARGS

# set up the defaults
envsetup

[[ $DEBUG ]] && echo "(DEBUG) Using spiders pattern file: $SPIDERS_PATTERN_FILE"

# Read list of spider user agents from the patterns file. For now, only read
# patterns that don't have regular expression or space characters, because we
# they are tricky to parse in bash and Solr's regular expression search uses
# a different format (patterns are anchored with ^ and $ by default and some
# meta characters like \d are not supported).
SPIDERS=$(grep -v -E '(\^|\\|\[|\]|!|\?|\.|\s)' $SPIDERS_PATTERN_FILE)

# Start a tally of bot hits so we can report the total at the end
BOT_HITS=0

for spider in $SPIDERS; do
    [[ $DEBUG ]] && echo "(DEBUG) Checking for hits from spider: $spider"

    # Check for hits from this spider in Solr and save results into a variable,
    # setting a custom curl output format so I can get the HTTP status code and
    # Solr response in one request, then tease them out later.
    solr_result=$(curl -s -w "http_code=%{http_code}" "$SOLR_URL/$STATISTICS_SHARD/select" -d "q=userAgent:*$spider*&rows=0")
    http_code=$(echo $solr_result | grep -o -E 'http_code=[0-9]+' | awk -F= '{print $2}')

    # Check the Solr HTTP response code and skip spider if not successful
    if [[ $http_code -ne 200 ]]; then
        [[ $DEBUG ]] && echo "(DEBUG) Solr query returned HTTP $http_code, skipping $spider."

        continue
    fi

    # lazy extraction of Solr numFound (relies on sed -E for extended regex)
    numFound=$(echo $solr_result | sed -E 's/\s+http_code=[0-9]+//' | xmllint --format - | grep numFound | sed -E 's/^.*numFound="([0-9]+)".*$/\1/')

    if [[ numFound -gt 0 ]]; then
        if [[ $PURGE_SPIDER_HITS ]]; then
            echo "Purging $numFound hits from $spider in $STATISTICS_SHARD"

            # Purge the hits and soft commit
            curl -s "$SOLR_URL/$STATISTICS_SHARD/update?softCommit=true" -H "Content-Type: text/xml" --data-binary "<delete><query>userAgent:*$spider*</query></delete>" > /dev/null 2>&1
        else
            echo "Found $numFound hits from $spider in $STATISTICS_SHARD"
        fi

        BOT_HITS=$((BOT_HITS+numFound))
    fi
done

if [[ $BOT_HITS -gt 0 ]]; then
    if [[ $PURGE_SPIDER_HITS ]]; then
        echo
        echo "Total number of bot hits purged: $BOT_HITS"

        # Hard commit after we're done processing all spiders
        curl -s "$SOLR_URL/$STATISTICS_SHARD/update?commit=true" > /dev/null 2>&1
    else
        echo
        echo "Total number of hits from bots: $BOT_HITS"
    fi
fi

# vim: set expandtab:ts=4:sw=4:bs=2