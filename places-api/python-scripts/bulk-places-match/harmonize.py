import os
import json
import argparse
import requests
import csv
from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import as_completed
import logging
import logging.config
import urllib3
import urllib.parse
import urllib
from flatten_json import flatten
import time
# from pandas.io.json import json_normalize

logging.config.fileConfig('logging.conf')

# create logger
logger = logging.getLogger('harmonizer')
csv.register_dialect('piper', delimiter='|',
                     quoting=csv.QUOTE_NONE, escapechar='\\')


STATUS = {"SUCCESS": 0, "FAILURE": 0}


separator_mapping = {"C": ",", "T": "\t", "P": "|", "SC": ";"}


parser = argparse.ArgumentParser(
    description='Match / Harmonize places against Foursquare API')
parser.add_argument("--input", required=True, help="Input filename")
parser.add_argument("--output", required=False,
                    help="Output filename, defaults to <input filename>-out.csv")
parser.add_argument("--separator", required=False, default="T",
                    help="Separator in the CSV file (C)omma,(T)ab,(P)ipe,(S)emi(C)olon", choices=["C", "T", "P", "SC"])
parser.add_argument("--country", required=False, help="Country")
parser.add_argument("--column_mapping", required=False, default='{"id":"id_col","name":"name_col","address":"address_column","city":"city_col","state":"state_col","postalCode":"postalcode_col","cc":"country_col","lat":"lat_col","lng":"lon_col","ll":"ll_col"}',
                    help="Field to column mapping for id, name, address, city, state, zip/postalcode, country, lat, lng, ll")

args = parser.parse_args()

# These are the parameters that need to be filled in manually (each time):
input_csv_path = args.input
output_csv_path = args.output
separator = separator_mapping[args.separator]


logger.debug(f"Column mapping: {args.column_mapping}")

MAPPING = json.loads(args.column_mapping)

# Create / Verify  mapping of needed fields
ID_COL = MAPPING["id"] if "id" in MAPPING else print(
    "Error: You need a correctly mapped 'id' column in the input file")
NAME_COL = MAPPING["name"]
ADDRESS_COL = MAPPING["address"]
CITY_COL = MAPPING["city"]
STATE_COL = MAPPING["state"] if "state" in MAPPING else None
POSTCODE_COL = MAPPING["postalCode"]
COUNTRY_COL = MAPPING["cc"] if "cc" in MAPPING else None
LAT_COL = MAPPING["lat"] if "lat" in MAPPING else None
LON_COL = MAPPING["lat"] if "lon" in MAPPING else None

if "ll" in args.column_mapping:
    LL_COL = MAPPING["ll"]
elif LAT_COL is not None and LON_COL is not None:
    LL = f"{LAT_COL},{LON_COL}"


RESULT = {'SUCCESS': 0, 'FAILURE': 0}
OUTPUT_HEADERS = ['id', 'mtype', 'status_code', 'result', 'match_score', 'categories', 'chains', 'fsq_id', 'geocodes_main_latitude', 'geocodes_main_longitude', 'geocodes_roof_latitude', 'geocodes_roof_longitude',
                  'link', 'location_address', 'location_country', 'location_formatted_address', 'location_locality', 'location_neighborhood_0', 'location_postcode', 'location_region', 'name', 'related_places']

BASE_API = "https://api.foursquare.com"
MATCH_API = f"{BASE_API}/v3/places/match"
AUTOCOMPLETE_API = f"{BASE_API}/v3/autocomplete"
AUTH_KEY = os.environ['FSQ_API_AUTH_KEY']

if 'N_THREADS' not in os.environ:
    N_THREADS = 1
else:
    N_THREADS = int(os.environ['N_THREADS'])

MY_FILE_INPUT = args.input

if args.output is None:
    MY_FILE_OUTPUT = f"{args.input}-out.csv"
else:
    MY_FILE_OUTPUT = f"{args.output}"


def jsonify(obj):
    return json.dumps(obj, default=str, indent=4, sort_keys=True)


def normalize_json(data: dict) -> dict:
    # logger.debug(f"Received: {jsonify(data)}")
    if data is None:
        return None
    else:
        r = flatten(data)

    return r


def merge_dicts(*dict_args):
    """
    Given any number of dictionaries, shallow copy and merge into a new dict,
    precedence goes to key-value pairs in latter dictionaries.
    """
    result = {}
    for dictionary in dict_args:
        result.update(dictionary)
    return result


def process_results(r):
    id = r['id']
    writethis = {}
    logger.debug(f'Result is: {jsonify(r)}')
    status_code = r["status_code"]

    if status_code != 200:
        logger.info(f"SEARCH FAILED FOR ID: {id} CODE:{status_code}")
        rn = r
        rn['result'] = 'FAILURE'

        RESULT['FAILURE'] = RESULT['FAILURE']+1
    else:
        logger.info(f"SEARCH SUCCESSFUL FOR ID: {id} CODE:{status_code}")
        rn = r

        place = normalize_json(rn['place'])
        del rn["place"]

        rn = merge_dicts(rn, place)

        rn['result'] = 'SUCCESS'

        RESULT['SUCCESS'] = RESULT['SUCCESS']+1

    for key in OUTPUT_HEADERS:
        if key in rn:
            writethis[key] = rn[key]
        else:
            writethis[key] = None
    return writethis

# Match Types "NAME", "ADDRESS", "ALL"


def match(params, mtype="ALL"):
    id = params['id']
    query = ""

    if mtype == "NAME":  # Match Name only No Address
        pval = urllib.parse.quote(params['name'])
        query = f"name={pval}&ll={pval}"
    else:
        for p in params:
            pval = urllib.parse.quote(params[p])
            if p == "name" and mtype == "ADDRESS":  # If mtype is Address, skip name otherwise match all fields
                continue
            query = query+f"&{p}={pval}"

    # Consider specifying what fields to return
    request_url = f"{MATCH_API}?{query}"

    max_retries = 10
    sleep_interval = 2

    retry_counter = 0

    while (retry_counter < max_retries):
        try:
            response = requests.get(request_url,
                                    headers={'Accept': 'application/json',
                                             'Access-Control-Allow-Origin': '*',
                                             'Authorization': f'{AUTH_KEY}'},
                                    timeout=10
                                    )
            status_code = response.status_code
            # force loop exit
            retry_counter = max_retries
        except requests.exceptions.ConnectionError as ce:
            logger.info(f"****Connection error: {ce}****")
            logger.info(f"Retrying connection (Try # {retry_counter+1})")
            time.sleep(sleep_interval)
            retry_counter = retry_counter + 1
        except Exception as e:
            logger.info(f"****Miscellaneous error: {e}****")
            logger.info(f"Retrying misc error (Try # {retry_counter+1})")
            time.sleep(sleep_interval)
            retry_counter = retry_counter + 1

    logger.debug(
        f"\nMatch Type: {mtype} Request Url:{request_url} Response Code: {status_code} Response Text:{response.text}")

    if status_code == 200:
        logger.info(f"[Match Type: {mtype}] Success: {id}")
        r = response.json()
        r['id'] = id
        r['mtype'] = mtype
        r['status_code'] = status_code
        return 200, r, mtype
    elif status_code == 204 or status_code == 404:
        logger.info(f"[Match Type: {mtype}] Failure: {id}")
        return 404, {'id': id, 'mtype': mtype, 'status_code': status_code}, mtype
    else:
        logger.info(f"[Match Type: {mtype}] Error: {id}")
        logger.info(
            f"Match Type: {mtype} Request Url:{request_url} Response Code: {status_code} Response Text:{response.text}")
        return status_code, {'id': id, 'mtype': mtype, 'status_code': status_code}, mtype


if __name__ == "__main__":
    # Hack to jump to partially processed files, note its still overwriting the files, so backup the existing set of results
    SKIP_TO = 0

    futures = []
    # ,encoding='utf-8-sig' needed sometimes with BOM characters etc.
    with open(MY_FILE_INPUT, "rt", encoding='utf-8') as csv_in:
        with open(MY_FILE_OUTPUT, "wt", encoding='utf-8') as csv_out:
            dw = csv.DictWriter(csv_out, fieldnames=OUTPUT_HEADERS)
            dw.writeheader()
            rcnt = 0
            bcount = 0
            with ThreadPoolExecutor(N_THREADS) as executor:
                # For PSV , dialect='piper'):
                for row in csv.DictReader(csv_in, delimiter=separator_mapping[args.separator], escapechar='\\'):
                    rcnt = rcnt+1
                    id = row[ID_COL]
                    logger.debug(
                        f'===================START Processing > row: {rcnt} id:{id} ===================\n')
                    if rcnt < SKIP_TO:
                        logger.debug("****Skipping row {rcnt}****")
                        continue

                    params = {}
                    logger.debug(row)

                    # Map the params to required API fields
                    for k, v in MAPPING.items():
                        params[k] = row[v].strip()

                    logger.debug(f'Args are: {jsonify(args)}')

                    # Override country settings if applicable
                    if args.country is not None:
                        params['cc'] = args.country
                    else:
                        params['cc'] = row[COUNTRY_COL]
                    params['id'] = id
                    #

                    logger.debug(f'Params are: {jsonify(params)}')

                    # break

                    # Match Types:
                    # mtypes=["NAME","ADDRESS","ALL"]
                    mtypes = ["ALL"]

                    for m in mtypes:
                        futures.append(executor.submit(match, params, m))
                        bcount = bcount+1

                    if bcount >= N_THREADS:  # collect results
                        for future in as_completed(futures):
                            status_code, r, m = future.result()
                            wt = process_results(r)

                            dw.writerow(wt)
                        # Re-init
                        futures = []
                        bcount = 0

                    logger.debug(
                        f'===================FINISHED Processing > row: {rcnt} id:{id}===================\n')

                # Process anything that did not make it to the batch of N_THREADS
                for future in as_completed(futures):
                    status_code, r, m = future.result()
                    wt = process_results(r)

                    dw.writerow(wt)

                    # print(jsonify(r,indent=2))
    s = RESULT['SUCCESS']
    f = RESULT['FAILURE']
    t = s+f
    logger.info(
        f"Results - Success: {s} ({(s/t):0.2%}) / Failure: {f} ({(f/t):0.2%})")
