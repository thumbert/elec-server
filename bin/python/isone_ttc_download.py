import argparse
import requests
import logging
# import gzip
import subprocess

# Example:
#   python isone_ttc_download.py --days=20241022,20241023
#
def main():
    parser = argparse.ArgumentParser(description='Download ISONE total transfer capability file in current directory')
    parser.add_argument('--days', type=str, help='Days to download, comma separated in yyyymmdd format', required=True)
    args = parser.parse_args()
    days = args.days.split(',')

    # need to navigate to the parent website to get the correct isox_token for the session
    session = requests.Session()
    r = session.get('https://www.iso-ne.com/isoexpress/web/reports/operations/-/tree/ttc-tables')

    for day in days:
        r = session.get('https://www.iso-ne.com/transform/csv/totaltransfercapability?start=' + day)
        # with gzip.open('ttc_' + day + '.csv.gz', 'wt', encoding="utf-8") as f:
        #     f.write(r.text)
        f = open('ttc_' + day + '.csv', 'w')
        f.write(r.text)
        f.close()
        subprocess.run(['gzip', 'ttc_' + day + '.csv'], check=True)


    logging.info('Done')

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception(e)



