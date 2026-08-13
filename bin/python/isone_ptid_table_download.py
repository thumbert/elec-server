# import argparse
# import requests
# import logging

# # Example:
# #
# def main():
#     parser = argparse.ArgumentParser(description='Download ISONE seven day solar forecast files in current directory')
#     parser.add_argument('--days', type=str, help='Days to download, comma separated in yyyymmdd format', required=True)
#     args = parser.parse_args()
#     days = args.days.split(',')

#     # need to navigate to the parent website to get the correct isox_token for the session
#     session = requests.Session()
#     r = session.get('https://www.iso-ne.com/markets-operations/settlements/pricing-node-tables')


#     logging.info('Done')

# if __name__ == "__main__":
#     try:
#         main()
#     except Exception as e:
#         logging.exception(e)



