select * from boba_dev.core.dim_contract_abis;
select * from boba_dev.bronze.decoded_logs order by block_number desc limit 10;
select * from boba_dev.silver.decoded_logs order by block_number desc limit 10;
select * from boba_dev.core.ez_decoded_event_logs_complete order by block_number desc limit 10;

DROP TABLE BOBA_dev.nft.ez_nft_transfers;