import argparse
import requests
import logging

# Example:
#   python nrc_reactor_status_download.py --years=2019,2020
#
def main():
    parser = argparse.ArgumentParser(description='Download NRC reactor status in current directory')
    parser.add_argument('--years', type=str, help='Years to download, comma separated in yyyy format', required=True)
    args = parser.parse_args()
    years = args.years.split(',')

    # need to navigate to the parent website to get the correct token for the session
    session = requests.Session()
    r = session.get('https://www.nrc.gov/reading-rm/doc-collections/event-status/reactor-status/index.html')

    for year in years:
        r = session.get(f"https://www.nrc.gov/reading-rm/doc-collections/event-status/reactor-status/{year}/{year}PowerStatus.txt")
        f = open(f"{year}powerstatus.txt", 'w')
        f.write(r.text)
        f.close()

    logging.info('Done')

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception(e)



