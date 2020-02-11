#!/usr/bin/env python3
#
# resolve-orcids.py 1.2.1
#
# Copyright 2018–2019 Alan Orth.
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
#
# ---
#
# Queries the public ORCID API for names associated with a list of ORCID iDs
# read from a text file or DSpace authority Solr core. Text file should have
# one ORCID identifier per line (comments and invalid lines are skipped).
#
# This script is written for Python 3 and requires several modules that you can
# install with pip (I recommend setting up a Python virtual environment first):
#
#   $ pip install colorama requests requests-cache
#

import argparse
from colorama import Fore
from datetime import timedelta
import re
import requests
import requests_cache
import signal
import sys


# read ORCID identifiers from a text file, one per line
def read_identifiers_from_file():
    # initialize an empty list for ORCID iDs
    orcids = []

    for line in args.input_file:
        # trim any leading or trailing whitespace (including newlines)
        line = line.strip()

        # regular expression for matching exactly one ORCID identifier on a line
        pattern = re.compile(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')

        # skip the line if it doesn't match the pattern
        if not pattern.match(line):
            continue

        # iterate over results and add ORCID iDs that aren't already in the list
        if line not in orcids:
            orcids.append(line)

    # close input file before we exit
    args.input_file.close()

    resolve_orcid_identifiers(orcids)


# query DSpace's authority Solr core for ORCID identifiers
def read_identifiers_from_solr():
    # simple query from the 'authority' collection 2000 rows at a time (default is 1000)
    solr_query_params = {
        'q': 'orcid_id:*',
        'wt': 'json',
        'rows': 2000
    }

    solr_url = args.solr_url + '/authority/select'

    res = requests.get(solr_url, params=solr_query_params)

    if args.debug:
        numFound = res.json()['response']['numFound']
        sys.stderr.write(Fore.GREEN + 'Total number of Solr records with ORCID iDs: {0}\n'.format(str(numFound) + Fore.RESET))

    # initialize an empty list for ORCID iDs
    orcids = []

    docs = res.json()['response']['docs']
    # iterate over results and add ORCID iDs that aren't already in the list
    # for example, we had 1600 ORCID iDs in Solr, but only 600 are unique
    for doc in docs:
        if doc['orcid_id'] not in orcids:
            orcids.append(doc['orcid_id'])

            # if the user requested --extract-only, write the current ORCID iD to output_file
            if args.extract_only:
                line = doc['orcid_id'] + '\n'
                args.output_file.write(line)

    # exit now if the user requested --extract-only
    if args.extract_only:
        if args.debug:
            sys.stderr.write(Fore.GREEN + 'Number of unique ORCID iDs: {0}\n'.format(str(len(orcids))) + Fore.RESET)
        # close output file before we exit
        args.output_file.close()
        exit()

    resolve_orcid_identifiers(orcids)


# Query ORCID's public API for names associated with identifiers. Prefers to use
# the "credit-name" field if it is present, otherwise will default to using the
# "given-names" and "family-name" fields.
def resolve_orcid_identifiers(orcids):
    if args.debug:
        sys.stderr.write(Fore.GREEN + 'Resolving names associated with {0} unique ORCID iDs.\n\n'.format(str(len(orcids))) + Fore.RESET)

    # ORCID API endpoint, see: https://pub.orcid.org
    orcid_api_base_url = 'https://pub.orcid.org/v2.1/'
    orcid_api_endpoint = '/person'

    # iterate through our ORCID iDs and fetch their names from the ORCID API
    for orcid in orcids:
        if args.debug:
            sys.stderr.write(Fore.GREEN + 'Looking up the names associated with ORCID iD: {0}\n'.format(orcid) + Fore.RESET)

        # enable transparent request cache with 24 hour expiry
        expire_after = timedelta(hours=72)
        # cache HTTP 200 and 404 responses, because ORCID uses HTTP 404 when an identifier doesn't exist
        requests_cache.install_cache('orcid-response-cache', expire_after=expire_after, allowable_codes=(200, 404))

        # build request URL for current ORCID ID
        request_url = orcid_api_base_url + orcid.strip() + orcid_api_endpoint

        # ORCID's API defaults to some custom format, so tell it to give us JSON
        request = requests.get(request_url, headers={'Accept': 'application/json'})

        # prune old cache entries
        requests_cache.core.remove_expired_responses()

        # Check the request status
        if request.status_code == requests.codes.ok:
            # read response JSON into data
            data = request.json()

            # make sure name element is not null
            if data['name']:
                # prefer to use credit-name if present and not blank
                if data['name']['credit-name'] and data['name']['credit-name']['value'] != '':
                    line = data['name']['credit-name']['value']
                # otherwise try to use given-names and or family-name
                else:
                    # make sure given-names is present and not deactivated
                    if data['name']['given-names'] and data['name']['given-names']['value'] != 'Given Names Deactivated':
                        line = data['name']['given-names']['value']
                    else:
                        if args.debug:
                            sys.stderr.write(Fore.YELLOW + 'Warning: ignoring null or deactivated given-names element.\n' + Fore.RESET)
                    # make sure family-name is present and not deactivated
                    if data['name']['family-name'] and data['name']['family-name']['value'] != 'Family Name Deactivated':
                        line = line + ' ' + data['name']['family-name']['value']
                    else:
                        if args.debug:
                            sys.stderr.write(Fore.YELLOW + 'Warning: ignoring null or deactivated family-name element.\n' + Fore.RESET)
                # check if line has something (a credit-name, given-names, and or family-name)
                if line and line != '':
                    line = '{0}: {1}'.format(line.strip(), orcid)
                else:
                    if args.debug:
                        sys.stderr.write(Fore.RED + 'Error: skipping identifier with no valid name elements.\n' + Fore.RESET)
                    continue

                # output results to screen to show progress
                if not args.quiet:
                    print(line)

                # write formatted name and ORCID identifier to output file
                args.output_file.write(line + '\n')

                # clear line for next iteration
                line = None
            else:
                if args.debug:
                    sys.stderr.write(Fore.YELLOW + 'Warning: skipping identifier with null name element.\n\n' + Fore.RESET)
        # HTTP 404 means that the API url or identifier was not found. If the
        # API URL is correct, let's assume that the identifier was not found.
        elif request.status_code == 404:
            if args.debug:
                sys.stderr.write(Fore.YELLOW + 'Warning: skipping missing identifier (API request returned HTTP 404).\n\n' + Fore.RESET)
                continue
        # HTTP 409 means that the identifier is locked for some reason
        # See: https://members.orcid.org/api/resources/error-codes
        elif request.status_code == 409:
            if args.debug:
                sys.stderr.write(Fore.YELLOW + 'Warning: skipping locked identifier (API request returned HTTP 409).\n\n' + Fore.RESET)
                continue
        else:
            sys.stderr.write(Fore.RED + 'Error: request failed.\n' + Fore.RESET)
            # close output file before we exit
            args.output_file.close()
            exit(1)

    # close output file before we exit
    args.output_file.close()


def signal_handler(signal, frame):
    # close output file before we exit
    args.output_file.close()

    sys.exit(1)


parser = argparse.ArgumentParser(description='Query the public ORCID API for names associated with a list of ORCID identifiers, either from a text file or a DSpace authority Solr core. Optional "extract only" mode will simply fetch the ORCID identifiers from Solr and write them to the output file without resolving their names from ORCID\'s API.')
parser.add_argument('-d', '--debug', help='Print debug messages to standard error (stderr).', action='store_true')
parser.add_argument('-e', '--extract-only', help='If fetching ORCID identifiers from Solr, write them to the output file without resolving their names from the ORCID API.', action='store_true')
parser.add_argument('-o', '--output-file', help='Name of output file to write to.', required=True, type=argparse.FileType('w', encoding='UTF-8'))
parser.add_argument('-q', '--quiet', help='Do not print results to screen as we find them (results will still go to output file).', action='store_true')
# group of mutually exclusive options
group = parser.add_mutually_exclusive_group(required=True)
group.add_argument('-i', '--input-file', help='File name containing ORCID identifiers to resolve.', type=argparse.FileType('r'))
group.add_argument('-s', '--solr-url', help='URL of Solr application (for example: http://localhost:8080/solr).')
args = parser.parse_args()

# set the signal handler for SIGINT (^C) so we can exit cleanly
signal.signal(signal.SIGINT, signal_handler)

# if the user specified an input file, get the ORCID identifiers from there
if args.input_file:
    read_identifiers_from_file()
# otherwise, get the ORCID identifiers from Solr
elif args.solr_url:
    read_identifiers_from_solr()

exit()
