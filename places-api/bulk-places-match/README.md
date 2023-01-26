# Bulk Harmonization Script

The Bulk Harmonizer Script takes a delimited input file and calls the Foursquare Place Match API for each row in an attempt to match your data with a FSQ POI. The scripts returns a csv file detailing if the match was a failure or success. For each success a fsq_id is included as well as the match score. 


## Getting Started 
To run this script you will need Python version 3+ and pip version 22+ installed on your machine.

1. First, set the required environment variables using the commands below.
```	
    export FSQ_API_AUTH_KEY=[Your Foursquare API Key]
    export N_THREADS=25 
```

You can increase or decrease the number of threads (N_THREADS) used when running the script to increase the runtime speed depending on the size of your input file. 

2. Next, install the required Python libs from requirements.txt
```
     pip3 install -r requirements.txt
```

## Running the script
The python script accepts 4 inputs which are outlined below. 

--input --> Provide the relative path to your input file (i.e path/to/inputFile.csv) 

--output --> Provide the relative path of the output file (i.e. path/to/outputFile.csv) 

--separator --> Inform the tool how each row is delimited. The acceptable values are..  
    - 'C' for commas ','  
    - 'P' for pipes '|'  
    - 'SC' for semicolons ';'  
    - 'T' for  tabs '\t' or '	' 

--column_mapping --> Provide your input columns to match with FSQ data column names. The values should be in json format. Use our list of keys to provide the value of your data column name that matches. Here is a sample.. 

```
{
    "id":"YOUR_ID_COL",
    "name":"YOUR_POI_NAME_COL",
    "address":"YOUR_ADDRESS_COL",
    "city":"YOUR_CITY_COL",
    "postalCode":"YOUR_ZIP_CODE_COL",
    "cc":"YOUR_COUNTRY_COL",
    "state":"YOUR_STATE_COL",
    "ll":"YOUR_LAT_LON_COL"
}
```

FYI. latitude and longitude by default are interpreted from a single comma separated key (i.e. "ll":"42.00,-87.87" ). They can be provided as separate keys as well by excluding the 'll' key and providing the key/value pairs below. 

```
{
    "lat":"YOUR_LAT_COL",
    "lon":"YOUR_LON_COL"
}
```


## Sample
A sample input file and command are provided in this repo. 100 Starbucks locations are provided in a csv file as an example input. Use this command to run the script and view the sample output file (100-starbucks-outputFile.csv). Be sure to have your environments variables set!

(FYI Starbucks locations were downloaded from [Kaggle](https://www.kaggle.com/datasets/starbucks/store-locations?resource=download) for testing purposes.)

```
python3 harmonize_v43.py --input 100-starbucks.csv --output 100-starbucks-outputFile.csv --separator C  --column_mapping '{"id":"Store Number","name":"Store Name","address":"Street Address","city":"City","postalCode":"Postcode","cc":"Country","state":"State/Province","lat":"Latitude","lon":"Longitude"}' 2>&1 >out.log

```


## Notice 
Please be aware of your available Foursquare API credits. Each row of the provided input file will be a individual API call. A 40k line input file will deplete an account's monthly $200 free credits. Review our [pricing model](https://location.foursquare.com/pricing/#:~:text=Contact%20Sales-,Places%20API%20pricing,-Product) to understand the financial impact of larger files. 