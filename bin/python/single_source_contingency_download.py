import argparse
import requests
import logging

# Example:
#   python single_source_contingency_download.py --days=20241022,20241023
#
def main():
    parser = argparse.ArgumentParser(description='Download ISONE single source contingency files in current directory')
    parser.add_argument('--days', type=str, help='Days to download, comma separated in yyyymmdd format', required=True)
    args = parser.parse_args()
    days = args.days.split(',')

    # need to navigate to the parent website to get the correct isox_token for the session
    session = requests.Session()
    r = session.get('https://www.iso-ne.com/isoexpress/web/reports/operations/-/tree/single-src-cont')

    for day in days:
        r = session.get('https://www.iso-ne.com/transform/csv/ssc?start=' + day)
        f = open('ssc_' + day + '.csv', 'w')
        f.write(r.text)
        f.close()

    logging.info('Done')

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception(e)


