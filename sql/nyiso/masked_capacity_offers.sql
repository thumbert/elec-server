



---============================================================================
--- https://www.nyiso.com/documents/20142/3036383/ICAP-Auctions.pdf/7dda1755-279a-f463-cd85-c39599ee066f
--- 
CREATE TABLE masked_capacity_offers (
    id SERIAL PRIMARY KEY,
    offer_date DATE NOT NULL,
    capacity NUMERIC NOT NULL,
    price NUMERIC NOT NULL
);

-- the biddata_icapbids_obligation CSV file has the monthly auction bids/offers for the 
-- remaining capability period Summer (May-Oct), Winter (Nov-Apr)
SELECT * 
FROM read_csv('/home/adrian/Downloads/Archive/Nyiso/CapacityOffers/Raw/2024/20240101biddata_icapbids_obligation.csv.gz', 
    skip = 1, 
    header = true);

-- Files *_spot.csv.gz have offers (no bids) for the spot auction.  